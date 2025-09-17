import asyncio
import io
import os
import re
from datetime import datetime, timezone

import pytesseract
from PIL import Image
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from prometheus_client import Counter, Histogram, start_http_server

from app.config import settings
from app.utils.storage import download_bytes, upload_bytes


engine = create_async_engine(settings.database_url, echo=False, pool_pre_ping=True)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


TOTAL_REGEXES = [
    re.compile(r"total\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"amount due\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
]

JOBS_PROCESSED = Counter("worker_jobs_total", "Total jobs processed", ["kind", "status"]) 
JOB_LATENCY = Histogram("worker_job_latency_seconds", "Job processing latency", ["kind"]) 


async def fetch_pending_job(db: AsyncSession):
    # Try receipt job first
    res = await db.execute(
        text(
            """
            SELECT 'receipt' as kind, j.id, r.id as receipt_id, r.user_id, r.storage_uri
            FROM receipt_processing_jobs j
            JOIN receipts r ON r.id = j.receipt_id
            WHERE j.status = 'pending'
            ORDER BY j.created_at ASC
            LIMIT 1
            """
        )
    )
    row = res.mappings().first()
    if row:
        return dict(row)
    # Then export job
    res = await db.execute(
        text(
            """
            SELECT 'export' as kind, e.id, e.user_id, e.from_date, e.to_date
            FROM export_jobs e
            WHERE e.status = 'pending'
            ORDER BY e.created_at ASC
            LIMIT 1
            """
        )
    )
    row = res.mappings().first()
    if row:
        return dict(row)
    # Then deletion job
    res = await db.execute(
        text(
            """
            SELECT 'deletion' as kind, d.id, d.user_id
            FROM deletion_jobs d
            WHERE d.status = 'scheduled'
            ORDER BY d.requested_at ASC
            LIMIT 1
            """
        )
    )
    row = res.mappings().first()
    return dict(row) if row else None


def parse_total_cents(text_blob: str) -> int | None:
    for rx in TOTAL_REGEXES:
        m = rx.search(text_blob)
        if m:
            amt = m.group(1).replace(",", "")
            try:
                return int(round(float(amt) * 100))
            except Exception:
                continue
    return None


async def process_receipt_job(db: AsyncSession, job: dict):
    import time
    start = time.time()
    await db.execute(text("UPDATE receipt_processing_jobs SET status='processing', started_at=now() WHERE id=:id"), {"id": job["id"]})
    await db.commit()
    try:
        data = download_bytes(job["storage_uri"])  # object_key
        img = Image.open(io.BytesIO(data))
        text_blob = pytesseract.image_to_string(img)
        total_cents = parse_total_cents(text_blob) or 0

        await db.execute(
            text("UPDATE receipts SET ocr_status='done', processed_at=now() WHERE id=:rid"),
            {"rid": job["receipt_id"]},
        )

        if total_cents > 0:
            await db.execute(
                text(
                    """
                    INSERT INTO transactions(user_id, receipt_id, merchant, txn_date, total_cents, currency_code, category, source, raw_text)
                    VALUES (:uid, :rid, NULL, CURRENT_DATE, :total, 'USD', 'other', 'receipt', :raw)
                    """
                ),
                {"uid": job["user_id"], "rid": job["receipt_id"], "total": total_cents, "raw": {"ocr": text_blob}},
            )

        await db.execute(
            text("UPDATE receipt_processing_jobs SET status='done', completed_at=now() WHERE id=:id"),
            {"id": job["id"]},
        )
        await db.commit()
        JOBS_PROCESSED.labels(kind="receipt", status="done").inc()
    except Exception as e:
        await db.execute(
            text("UPDATE receipt_processing_jobs SET status='failed', last_error=:err, attempts=attempts+1 WHERE id=:id"),
            {"id": job["id"], "err": str(e)},
        )
        await db.commit()
        JOBS_PROCESSED.labels(kind="receipt", status="failed").inc()
    finally:
        JOB_LATENCY.labels(kind="receipt").observe(time.time() - start)


async def process_export_job(db: AsyncSession, job: dict):
    import time
    start = time.time()
    await db.execute(text("UPDATE export_jobs SET status='processing' WHERE id=:id"), {"id": job["id"]})
    await db.commit()
    try:
        rows = await db.execute(
            text(
                """
                SELECT txn_date, merchant, total_cents, tax_cents, tip_cents, currency_code, category, subcategory
                FROM transactions
                WHERE user_id = :uid AND txn_date BETWEEN :fd AND :td
                ORDER BY txn_date
                """
            ),
            {"uid": job["user_id"], "fd": job["from_date"], "td": job["to_date"]},
        )
        items = rows.mappings().all()
        # Build CSV
        import csv

        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["date", "merchant", "total_cents", "tax_cents", "tip_cents", "currency_code", "category", "subcategory"])
        for r in items:
            writer.writerow([
                r["txn_date"], r["merchant"], r["total_cents"], r["tax_cents"], r["tip_cents"], r["currency_code"], r["category"], r["subcategory"],
            ])
        data = output.getvalue().encode("utf-8")
        object_key = f"exports/{job['user_id']}/{job['id']}.csv"
        upload_bytes(object_key, data, content_type="text/csv")
        await db.execute(text("UPDATE export_jobs SET status='done', storage_uri=:uri, completed_at=now() WHERE id=:id"), {"id": job["id"], "uri": object_key})
        await db.commit()
        JOBS_PROCESSED.labels(kind="export", status="done").inc()
    except Exception as e:
        await db.execute(text("UPDATE export_jobs SET status='failed', failure_reason=:err WHERE id=:id"), {"id": job["id"], "err": str(e)})
        await db.commit()
        JOBS_PROCESSED.labels(kind="export", status="failed").inc()
    finally:
        JOB_LATENCY.labels(kind="export").observe(time.time() - start)


async def process_deletion_job(db: AsyncSession, job: dict):
    import time
    start = time.time()
    await db.execute(text("UPDATE deletion_jobs SET status='processing' WHERE id=:id"), {"id": job["id"]})
    await db.commit()
    try:
        uid = job["user_id"]
        # Minimal cascade; rely on FK ON DELETE CASCADE where present
        await db.execute(text("DELETE FROM sessions WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM identities WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM profiles WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM subscriptions WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM receipts WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM transactions WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM budgets WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM user_badges WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM usage_counters WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM export_jobs WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM linked_accounts WHERE user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM account_balances USING linked_accounts la WHERE account_balances.linked_account_id = la.id AND la.user_id=:uid"), {"uid": uid})
        await db.execute(text("DELETE FROM deletion_jobs WHERE id=:id"), {"id": job["id"]})
        await db.execute(text("UPDATE users SET deleted_at=now() WHERE id=:uid"), {"uid": uid})
        await db.commit()
    except Exception as e:
        await db.execute(text("UPDATE deletion_jobs SET status='failed', error=:err WHERE id=:id"), {"id": job["id"], "err": str(e)})
        await db.commit()
        JOBS_PROCESSED.labels(kind="deletion", status="failed").inc()
    finally:
        JOB_LATENCY.labels(kind="deletion").observe(time.time() - start)


async def worker_loop():
    async with SessionLocal() as db:
        while True:
            job = await fetch_pending_job(db)
            if not job:
                await asyncio.sleep(2)
                continue
            if job["kind"] == "receipt":
                await process_receipt_job(db, job)
            elif job["kind"] == "export":
                await process_export_job(db, job)
            elif job["kind"] == "deletion":
                await process_deletion_job(db, job)


def main():
    # Expose Prometheus metrics on :9100
    start_http_server(9100)
    asyncio.run(worker_loop())


if __name__ == "__main__":
    main()


