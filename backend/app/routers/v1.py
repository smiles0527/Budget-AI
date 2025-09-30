from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Header, Request, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import text
import stripe
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..config import settings
from ..utils.security import hash_password, verify_password, generate_session_token, session_expiry
from ..utils.storage import presign_put, presign_get, head_object
from ..utils.cursor import encode_cursor, decode_cursor
from ..utils.auth import get_current_user
from ..errors import AppError
from ..utils.oauth import verify_google, verify_apple
from ..utils.categorize import determine_category


router = APIRouter(prefix="/v1")


class SignupRequest(BaseModel):
    email: EmailStr
    password: str


@router.post("/auth/signup")
async def signup(payload: SignupRequest, db: AsyncSession = Depends(get_db)):
    # Create user
    try:
        user_res = await db.execute(
            text(
                """
                INSERT INTO users(email, auth_provider)
                VALUES (:email, 'email')
                RETURNING id
                """
            ),
            {"email": payload.email},
        )
        user_id = user_res.scalar_one()
    except Exception as e:  # unique violation or others
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")

    await db.execute(
        text(
            """
            INSERT INTO identities(user_id, provider, provider_user_id, email_verified, password_hash)
            VALUES (:uid, 'email', :email, false, :ph)
            """
        ),
        {"uid": user_id, "email": payload.email, "ph": hash_password(payload.password)},
    )

    await db.execute(
        text(
            "INSERT INTO profiles(user_id) VALUES (:uid) ON CONFLICT (user_id) DO NOTHING"
        ),
        {"uid": user_id},
    )

    await db.execute(
        text(
            "INSERT INTO subscriptions(user_id) VALUES (:uid) ON CONFLICT (user_id) DO NOTHING"
        ),
        {"uid": user_id},
    )
    await db.commit()
    return {"id": str(user_id)}


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
class GoogleLogin(BaseModel):
    id_token: str


@router.post("/auth/google")
async def auth_google(payload: GoogleLogin, request: Request, db: AsyncSession = Depends(get_db)):
    info = verify_google(payload.id_token)
    if not info:
        raise HTTPException(status_code=401, detail="Invalid Google token")
    email = info.get("email")
    sub = info.get("sub")
    if not email or not sub:
        raise HTTPException(status_code=400, detail="Missing Google claims")

    # Upsert user and identity
    res = await db.execute(text("SELECT id FROM users WHERE email=:email"), {"email": email})
    row = res.first()
    if row:
        user_id = row[0]
    else:
        user_id = (await db.execute(text("INSERT INTO users(email, auth_provider) VALUES (:email, 'google') RETURNING id"), {"email": email})).scalar_one()
        await db.execute(text("INSERT INTO profiles(user_id) VALUES (:uid)"), {"uid": user_id})
        await db.execute(text("INSERT INTO subscriptions(user_id) VALUES (:uid)"), {"uid": user_id})

    await db.execute(
        text(
            """
            INSERT INTO identities(user_id, provider, provider_user_id, email_verified)
            VALUES (:uid, 'google', :pid, true)
            ON CONFLICT (provider, provider_user_id) DO UPDATE SET user_id = EXCLUDED.user_id
            """
        ),
        {"uid": user_id, "pid": sub},
    )

    secret, hashed = generate_session_token()
    sess = await db.execute(
        text(
            "INSERT INTO sessions(user_id, refresh_token_hash, user_agent, ip, expires_at) VALUES (:uid, :hash, :ua, :ip, :exp) RETURNING id"
        ),
        {"uid": user_id, "hash": hashed, "ua": request.headers.get("user-agent"), "ip": request.client.host if request.client else None, "exp": session_expiry()},
    )
    await db.commit()
    return {"token": f"{sess.scalar_one()}.{secret}"}


class AppleLogin(BaseModel):
    identity_token: str


@router.post("/auth/apple")
async def auth_apple(payload: AppleLogin, request: Request, db: AsyncSession = Depends(get_db)):
    info = verify_apple(payload.identity_token)
    if not info:
        raise HTTPException(status_code=401, detail="Invalid Apple token")
    sub = info.get("sub")
    email = info.get("email")  # Apple may omit email post-first consent
    if not sub:
        raise HTTPException(status_code=400, detail="Missing Apple claims")

    user_id = None
    if email:
        row = await db.execute(text("SELECT id FROM users WHERE email=:email"), {"email": email})
        r = row.first()
        if r:
            user_id = r[0]
    if not user_id:
        # Create placeholder email if not provided
        placeholder = email or f"apple_{sub}@placeholder.apple"
        user_id = (await db.execute(text("INSERT INTO users(email, auth_provider) VALUES (:email, 'apple') RETURNING id"), {"email": placeholder})).scalar_one()
        await db.execute(text("INSERT INTO profiles(user_id) VALUES (:uid)"), {"uid": user_id})
        await db.execute(text("INSERT INTO subscriptions(user_id) VALUES (:uid)"), {"uid": user_id})

    await db.execute(
        text(
            """
            INSERT INTO identities(user_id, provider, provider_user_id, email_verified)
            VALUES (:uid, 'apple', :pid, true)
            ON CONFLICT (provider, provider_user_id) DO UPDATE SET user_id = EXCLUDED.user_id
            """
        ),
        {"uid": user_id, "pid": sub},
    )

    secret, hashed = generate_session_token()
    sess = await db.execute(
        text(
            "INSERT INTO sessions(user_id, refresh_token_hash, user_agent, ip, expires_at) VALUES (:uid, :hash, :ua, :ip, :exp) RETURNING id"
        ),
        {"uid": user_id, "hash": hashed, "ua": request.headers.get("user-agent"), "ip": request.client.host if request.client else None, "exp": session_expiry()},
    )
    await db.commit()
    return {"token": f"{sess.scalar_one()}.{secret}"}


@router.post("/auth/login")
async def login(payload: LoginRequest, request: Request, db: AsyncSession = Depends(get_db)):
    row = await db.execute(
        text(
            """
            SELECT u.id as user_id, i.password_hash
            FROM users u
            JOIN identities i ON i.user_id = u.id AND i.provider = 'email'
            WHERE u.email = :email AND u.deleted_at IS NULL
            """
        ),
        {"email": payload.email},
    )
    rec = row.mappings().first()
    if not rec or not verify_password(payload.password, rec["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    secret, hashed = generate_session_token()
    res = await db.execute(
        text(
            """
            INSERT INTO sessions(user_id, refresh_token_hash, user_agent, ip, expires_at)
            VALUES (:uid, :hash, :ua, :ip, :exp)
            RETURNING id
            """
        ),
        {
            "uid": rec["user_id"],
            "hash": hashed,
            "ua": request.headers.get("user-agent"),
            "ip": request.client.host if request.client else None,
            "exp": session_expiry(),
        },
    )
    session_id = res.scalar_one()
    await db.commit()
    token = f"{session_id}.{secret}"
    return {"token": token}


@router.post("/auth/logout")
async def logout(authorization: Optional[str] = Header(default=None), db: AsyncSession = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = authorization[7:]
    if "." not in token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    session_id = token.split(".", 1)[0]
    await db.execute(text("UPDATE sessions SET revoked_at = now() WHERE id = :sid"), {"sid": session_id})
    await db.commit()
    return {"ok": True}


@router.post("/auth/logout_all")
async def logout_all(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(text("UPDATE sessions SET revoked_at = now() WHERE user_id = :uid AND revoked_at IS NULL"), {"uid": user["id"]})
    await db.commit()
    return {"ok": True}


class RotateRequest(BaseModel):
    # No body needed; token taken from Authorization header, but keep a placeholder for future use
    pass


@router.post("/auth/rotate")
async def rotate_session(
    _ : Optional[RotateRequest] = None,
    authorization: Optional[str] = Header(default=None),
    request: Request = None,
    db: AsyncSession = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = authorization[7:]
    if "." not in token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    session_id, secret = token.split(".", 1)

    # Validate existing session
    row = await db.execute(
        text("SELECT user_id, refresh_token_hash FROM sessions WHERE id=:sid AND revoked_at IS NULL AND expires_at > now()"),
        {"sid": session_id},
    )
    rec = row.mappings().first()
    if not rec or not verify_password(secret, rec["refresh_token_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    # Create new session and revoke old
    new_secret, new_hashed = generate_session_token()
    new_row = await db.execute(
        text(
            """
            INSERT INTO sessions(user_id, refresh_token_hash, user_agent, ip, expires_at)
            VALUES (:uid, :hash, :ua, :ip, :exp)
            RETURNING id
            """
        ),
        {
            "uid": rec["user_id"],
            "hash": new_hashed,
            "ua": request.headers.get("user-agent") if request else None,
            "ip": request.client.host if (request and request.client) else None,
            "exp": session_expiry(),
        },
    )
    new_session_id = new_row.scalar_one()
    await db.execute(text("UPDATE sessions SET revoked_at = now() WHERE id = :sid"), {"sid": session_id})
    await db.commit()
    return {"token": f"{new_session_id}.{new_secret}"}


@router.get("/auth/me")
async def me(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    sub = await db.execute(
        text("SELECT plan, status FROM subscriptions WHERE user_id = :uid"),
        {"uid": user["id"]},
    )
    s = sub.mappings().first()
    return {"user": user, "subscription": dict(s) if s else None}


class ReceiptCreate(BaseModel):
    mime: Optional[str] = None
    size: Optional[int] = None


@router.post("/receipts/upload")
async def receipts_upload(body: ReceiptCreate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Enforce monthly scan cap for non-premium plans
    mk = (await db.execute(text("SELECT to_char(now(), 'YYYY-MM')"))).scalar_one()
    remaining_row = await db.execute(text("SELECT get_remaining_scans(:uid, :mk)"), {"uid": user["id"], "mk": mk})
    remaining = remaining_row.scalar_one()
    if remaining is not None and remaining <= 0:
        raise AppError(code="SCAN_CAP_EXCEEDED", message="Monthly scan cap reached", details={"month_key": mk}, status_code=402)

    rec = await db.execute(
        text("INSERT INTO receipts(user_id, storage_uri) VALUES (:uid, 'pending') RETURNING id"),
        {"uid": user["id"]},
    )
    rid = rec.scalar_one()
    object_key = f"receipts/{user['id']}/{rid}.jpg"
    if body.mime and body.mime.lower() == 'application/pdf':
        object_key = f"receipts/{user['id']}/{rid}.pdf"
    url = presign_put(object_key, content_type=body.mime)
    await db.commit()
    return {"receipt_id": str(rid), "upload_url": url, "object_key": object_key}


class ReceiptConfirm(BaseModel):
    receipt_id: str
    object_key: str
    mime: Optional[str] = None
    size: Optional[int] = None


@router.post("/receipts/confirm")
async def receipts_confirm(body: ReceiptConfirm, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Validate object exists and matches constraints
    meta = head_object(body.object_key)
    size = meta.get('ContentLength') or 0
    if size > settings.upload_max_bytes:
        raise AppError(code="FILE_TOO_LARGE", message="Uploaded file too large", details={"max_bytes": settings.upload_max_bytes}, status_code=413)
    mime = (meta.get('ContentType') or '').lower()
    if settings.allowed_mime_list and mime not in settings.allowed_mime_list:
        raise AppError(code="UNSUPPORTED_MEDIA_TYPE", message="Invalid content type", details={"allowed": settings.allowed_mime_list}, status_code=415)

    await db.execute(
        text(
            "UPDATE receipts SET storage_uri = :uri, ocr_status = 'pending' WHERE id = :rid AND user_id = :uid"
        ),
        {"uri": body.object_key, "rid": body.receipt_id, "uid": user["id"]},
    )
    # Enqueue OCR job bookkeeping
    await db.execute(
        text(
            "INSERT INTO receipt_processing_jobs(receipt_id, status) VALUES (:rid, 'pending')"
        ),
        {"rid": body.receipt_id},
    )
    await db.commit()
    return {"ok": True}


@router.get("/receipts/{receipt_id}")
async def receipts_get(receipt_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    row = await db.execute(
        text("SELECT * FROM receipts WHERE id = :rid AND user_id = :uid"),
        {"rid": receipt_id, "uid": user["id"]},
    )
    rec = row.mappings().first()
    if not rec:
        raise HTTPException(status_code=404, detail="Not found")
    return dict(rec)


@router.get("/transactions")
async def transactions_list(
    user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    limit: int = 50,
    cursor: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    category: Optional[str] = None,
):
    limit = max(1, min(limit, 200))
    cur = decode_cursor(cursor)
    if cur:
        base = "SELECT * FROM transactions WHERE user_id = :uid"
        filters = []
        if from_date:
            filters.append("txn_date >= :from_date")
        if to_date:
            filters.append("txn_date <= :to_date")
        if category:
            filters.append("category = :category")
        filters.append("(txn_date, created_at, id) < (:cd, :cc, :cid)")
        where = " AND ".join(filters)
        sql = f"{base} AND {where} ORDER BY txn_date DESC, created_at DESC, id DESC LIMIT :lim"
        q = text(sql)
        params = {"uid": user["id"], "cd": cur.get("txn_date"), "cc": cur.get("created_at"), "cid": cur.get("id"), "lim": limit + 1}
        if from_date:
            params["from_date"] = from_date
        if to_date:
            params["to_date"] = to_date
        if category:
            params["category"] = category
    else:
        base = "SELECT * FROM transactions WHERE user_id = :uid"
        filters = []
        if from_date:
            filters.append("txn_date >= :from_date")
        if to_date:
            filters.append("txn_date <= :to_date")
        if category:
            filters.append("category = :category")
        where = (" AND ".join(filters))
        if where:
            base = f"{base} AND {where}"
        sql = f"{base} ORDER BY txn_date DESC, created_at DESC, id DESC LIMIT :lim"
        q = text(sql)
        params = {"uid": user["id"], "lim": limit + 1}
        if from_date:
            params["from_date"] = from_date
        if to_date:
            params["to_date"] = to_date
        if category:
            params["category"] = category

    res = await db.execute(q, params)
    rows = [dict(r) for r in res.mappings().all()]
    next_cursor = None
    if len(rows) > limit:
        last = rows[limit - 1]
        next_cursor = encode_cursor(
            {"txn_date": last["txn_date"], "created_at": last["created_at"], "id": last["id"]}
        )
        rows = rows[:limit]
    return {"items": rows, "next_cursor": next_cursor}


@router.get("/transactions/{txn_id}")
async def transactions_get(txn_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text("SELECT * FROM transactions WHERE id = :id AND user_id = :uid"),
        {"id": txn_id, "uid": user["id"]},
    )
    row = res.mappings().first()
    if not row:
        raise HTTPException(status_code=404, detail="Not found")
    return dict(row)


class TransactionManual(BaseModel):
    merchant: Optional[str] = None
    txn_date: str
    total_cents: int
    tax_cents: Optional[int] = 0
    tip_cents: Optional[int] = 0
    currency_code: Optional[str] = "USD"
    category: Optional[str] = "other"
    subcategory: Optional[str] = None


@router.post("/transactions/manual")
async def transactions_manual(body: TransactionManual, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Premium gating example: require active premium to create manual transactions
    sub = await db.execute(text("SELECT plan, status FROM subscriptions WHERE user_id=:uid"), {"uid": user["id"]})
    s = sub.mappings().first()
    if not s or s.get("plan") != "premium" or s.get("status") != "active":
        raise HTTPException(status_code=402, detail="Premium required")
    # Premium gating: allow manual transactions for premium users only (bypass in dev)
    if settings.env != "dev":
        subrow = await db.execute(text("SELECT plan, status FROM subscriptions WHERE user_id = :uid"), {"uid": user["id"]})
        sub = subrow.mappings().first()
        if not sub or sub.get("plan") != "premium" or sub.get("status") != "active":
            raise HTTPException(status_code=402, detail="Premium required for manual transactions")
    # Determine category using rules if not provided
    auto_category = await determine_category(db, merchant=body.merchant, raw_text=None)

    res = await db.execute(
        text(
            """
            INSERT INTO transactions(user_id, merchant, txn_date, total_cents, tax_cents, tip_cents, currency_code, category, subcategory, source)
            VALUES (:uid, :m, :d, :t, :tax, :tip, :cur, :cat, :sub, 'manual')
            RETURNING id
            """
        ),
        {
            "uid": user["id"],
            "m": body.merchant,
            "d": body.txn_date,
            "t": body.total_cents,
            "tax": body.tax_cents or 0,
            "tip": body.tip_cents or 0,
            "cur": body.currency_code,
            "cat": body.category or auto_category,
            "sub": body.subcategory,
        },
    )
    tid = res.scalar_one()
    await db.commit()
    return {"id": str(tid)}


class TransactionPatch(BaseModel):
    merchant: Optional[str] = None
    txn_date: Optional[str] = None
    total_cents: Optional[int] = None
    tax_cents: Optional[int] = None
    tip_cents: Optional[int] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None


# -----------------
# Rules management
# -----------------

class MerchantRuleCreate(BaseModel):
    merchant_pattern: str
    category: str
    confidence: float = 0.9
    active: bool = True


class KeywordRuleCreate(BaseModel):
    keyword: str
    scope: str = "both"  # 'merchant' | 'line_item' | 'both'
    category: str
    confidence: float = 0.8
    active: bool = True


def _assert_admin(request: Request):
    # Allow writes in dev env without secret; otherwise require X-Admin-Secret header matching config
    if settings.env == "dev":
        return
    secret = request.headers.get("x-admin-secret")
    if not settings.admin_secret or secret != settings.admin_secret:
        raise HTTPException(status_code=401, detail="Admin authentication required")


@router.get("/rules/merchant")
async def list_merchant_rules(db: AsyncSession = Depends(get_db)):
    res = await db.execute(text("SELECT id, merchant_pattern, category, confidence, active, created_at FROM merchant_rules ORDER BY created_at DESC"))
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.post("/rules/merchant")
async def create_merchant_rule(payload: MerchantRuleCreate, request: Request, db: AsyncSession = Depends(get_db)):
    _assert_admin(request)
    row = await db.execute(
        text(
            """
            INSERT INTO merchant_rules(merchant_pattern, category, confidence, active)
            VALUES (:p, :c, :conf, :a)
            RETURNING id
            """
        ),
        {"p": payload.merchant_pattern, "c": payload.category, "conf": payload.confidence, "a": payload.active},
    )
    rid = row.scalar_one()
    await db.commit()
    return {"id": str(rid)}


@router.get("/rules/keyword")
async def list_keyword_rules(db: AsyncSession = Depends(get_db)):
    res = await db.execute(text("SELECT id, keyword, scope, category, confidence, active, created_at FROM keyword_rules ORDER BY created_at DESC"))
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.post("/rules/keyword")
async def create_keyword_rule(payload: KeywordRuleCreate, request: Request, db: AsyncSession = Depends(get_db)):
    _assert_admin(request)
    row = await db.execute(
        text(
            """
            INSERT INTO keyword_rules(keyword, scope, category, confidence, active)
            VALUES (:k, :s, :c, :conf, :a)
            RETURNING id
            """
        ),
        {"k": payload.keyword, "s": payload.scope, "c": payload.category, "conf": payload.confidence, "a": payload.active},
    )
    rid = row.scalar_one()
    await db.commit()
    return {"id": str(rid)}


@router.patch("/transactions/{txn_id}")
async def transactions_update(txn_id: str, body: TransactionPatch, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    sets = []
    params = {"id": txn_id, "uid": user["id"]}
    for field in ["merchant", "txn_date", "total_cents", "tax_cents", "tip_cents", "category", "subcategory"]:
        val = getattr(body, field)
        if val is not None:
            sets.append(f"{field} = :{field}")
            params[field] = val
    if not sets:
        return {"id": txn_id, "updated": False}
    q = text(f"UPDATE transactions SET {', '.join(sets)} WHERE id = :id AND user_id = :uid")
    await db.execute(q, params)
    await db.commit()
    return {"id": txn_id, "updated": True}


@router.delete("/transactions/{txn_id}")
async def transactions_delete(txn_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(text("DELETE FROM transactions WHERE id = :id AND user_id = :uid"), {"id": txn_id, "uid": user["id"]})
    await db.commit()
    return {"id": txn_id, "deleted": True}


class BudgetUpsert(BaseModel):
    period_start: str
    period_end: str
    category: str
    limit_cents: int


@router.put("/budgets")
async def budgets_put(body: BudgetUpsert, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(
        text(
            """
            INSERT INTO budgets(user_id, period_start, period_end, category, limit_cents)
            VALUES (:uid, :ps, :pe, :cat, :lim)
            ON CONFLICT (user_id, period_start, period_end, category)
            DO UPDATE SET limit_cents = EXCLUDED.limit_cents
            """
        ),
        {"uid": user["id"], "ps": body.period_start, "pe": body.period_end, "cat": body.category, "lim": body.limit_cents},
    )
    await db.commit()
    return {"ok": True}


@router.get("/budgets")
async def budgets_get(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), period_start: Optional[str] = None, period_end: Optional[str] = None):
    if period_start and period_end:
        q = text("SELECT * FROM budgets WHERE user_id = :uid AND period_start >= :ps AND period_end <= :pe")
        res = await db.execute(q, {"uid": user["id"], "ps": period_start, "pe": period_end})
    else:
        res = await db.execute(text("SELECT * FROM budgets WHERE user_id = :uid"), {"uid": user["id"]})
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.get("/dashboard/summary")
async def dashboard_summary(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), period: str = "month", anchor: Optional[str] = None):
    # Default anchor is today
    if not anchor:
        row = await db.execute(text("SELECT CURRENT_DATE::text as d"))
        anchor = row.scalar_one()
    # Compute month range in SQL
    res = await db.execute(
        text(
            """
            SELECT * FROM get_dashboard_summary(:uid, date_trunc(:period, :anchor::date)::date, (date_trunc(:period, :anchor::date) + INTERVAL '1 ' || :period - INTERVAL '1 day')::date)
            """
        ),
        {"uid": user["id"], "period": period, "anchor": anchor},
    )
    row = res.mappings().first()
    return dict(row) if row else {"total_spend_cents": 0, "txn_count": 0, "avg_txn_cents": 0}


@router.get("/dashboard/categories")
async def dashboard_categories(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), period: str = "month", anchor: Optional[str] = None):
    if not anchor:
        row = await db.execute(text("SELECT CURRENT_DATE::text as d"))
        anchor = row.scalar_one()
    res = await db.execute(
        text(
            """
            SELECT * FROM get_dashboard_categories(:uid, date_trunc(:period, :anchor::date)::date, (date_trunc(:period, :anchor::date) + INTERVAL '1 ' || :period - INTERVAL '1 day')::date)
            """
        ),
        {"uid": user["id"], "period": period, "anchor": anchor},
    )
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.get("/badges")
async def badges_list(db: AsyncSession = Depends(get_db)):
    res = await db.execute(text("SELECT code, name, description FROM badges ORDER BY name"))
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.get("/user/badges")
async def user_badges(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text(
            """
            SELECT b.code, b.name, b.description, ub.awarded_at
            FROM user_badges ub JOIN badges b ON b.id = ub.badge_id
            WHERE ub.user_id = :uid ORDER BY ub.awarded_at DESC
            """
        ),
        {"uid": user["id"]},
    )
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.get("/usage")
async def usage_get(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    mk = (await db.execute(text("SELECT to_char(now(), 'YYYY-MM')"))).scalar_one()
    used_row = await db.execute(
        text("SELECT scans_count FROM usage_counters WHERE user_id = :uid AND month_key = :mk"),
        {"uid": user["id"], "mk": mk},
    )
    used = used_row.scalar_one_or_none() or 0
    remaining_row = await db.execute(text("SELECT get_remaining_scans(:uid, :mk)"), {"uid": user["id"], "mk": mk})
    remaining = remaining_row.scalar_one()
    return {"month_key": mk, "scans_used": used, "scans_remaining": remaining}


class ExportCSV(BaseModel):
    from_date: str
    to_date: str
    wait: Optional[bool] = False
    timeout_seconds: Optional[int] = 20


@router.post("/export/csv")
async def export_csv(body: ExportCSV, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    sub = await db.execute(text("SELECT plan, status FROM subscriptions WHERE user_id=:uid"), {"uid": user["id"]})
    s = sub.mappings().first()
    if not s or s.get("plan") != "premium" or s.get("status") != "active":
        raise HTTPException(status_code=402, detail="Premium required")
    # Premium gating: CSV exports require premium (bypass in dev)
    if settings.env != "dev":
        subrow = await db.execute(text("SELECT plan, status FROM subscriptions WHERE user_id = :uid"), {"uid": user["id"]})
        sub = subrow.mappings().first()
        if not sub or sub.get("plan") != "premium" or sub.get("status") != "active":
            raise HTTPException(status_code=402, detail="Premium required for CSV export")
    res = await db.execute(
        text(
            "INSERT INTO export_jobs(user_id, from_date, to_date) VALUES (:uid, :fd, :td) RETURNING id"
        ),
        {"uid": user["id"], "fd": body.from_date, "td": body.to_date},
    )
    jid = res.scalar_one()
    await db.commit()
    if body.wait:
        # Poll until ready or timeout
        import asyncio
        import time
        deadline = time.time() + max(1, int(body.timeout_seconds or 20))
        while time.time() < deadline:
            row = await db.execute(text("SELECT status, storage_uri FROM export_jobs WHERE id=:id AND user_id=:uid"), {"id": jid, "uid": user["id"]})
            rec = row.mappings().first()
            if rec and rec.get("status") == "done" and rec.get("storage_uri"):
                from ..utils.storage import presign_get
                return {"job_id": str(jid), "download_url": presign_get(rec.get("storage_uri"))}
            await asyncio.sleep(1)
    return {"job_id": str(jid)}


@router.get("/export/csv/{job_id}")
async def export_csv_status(job_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    row = await db.execute(text("SELECT status, storage_uri FROM export_jobs WHERE id=:id AND user_id=:uid"), {"id": job_id, "uid": user["id"]})
    rec = row.mappings().first()
    if not rec:
        raise HTTPException(status_code=404, detail="Not found")
    data = dict(rec)
    if data.get("status") == "done" and data.get("storage_uri"):
        data["download_url"] = presign_get(data["storage_uri"])  # temporary signed GET
    return data


@router.get("/subscription")
async def subscription_get(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(text("SELECT plan, status, cancel_at_period_end FROM subscriptions WHERE user_id = :uid"), {"uid": user["id"]})
    r = res.mappings().first()
    return dict(r) if r else {"plan": "free", "status": "active"}


@router.post("/subscription/checkout")
async def subscription_checkout(user=Depends(get_current_user)):
    if not settings.stripe_secret_key or not settings.stripe_price_id:
        raise HTTPException(status_code=501, detail="Stripe not configured")
    stripe.api_key = settings.stripe_secret_key
    session = stripe.checkout.Session.create(
        mode="subscription",
        line_items=[{"price": settings.stripe_price_id, "quantity": 1}],
        metadata={"user_id": str(user["id"] )},
        success_url="https://example.com/billing/success",
        cancel_url="https://example.com/billing/cancel",
    )
    return {"checkout_url": session.url}


@router.post("/subscription/webhook")
async def subscription_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    payload = await request.body()
    sig = request.headers.get("stripe-signature")
    if not settings.stripe_webhook_secret:
        raise HTTPException(status_code=501, detail="Stripe webhook not configured")
    try:
        event = stripe.Webhook.construct_event(payload, sig, settings.stripe_webhook_secret)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Persist event (idempotency protection at DB level)
    try:
        import json
        await db.execute(
            text(
                "INSERT INTO webhook_events(event_id, event_type, payload, status) VALUES (:id, :type, :payload, 'pending') ON CONFLICT (event_id) DO NOTHING"
            ),
            {"id": event["id"], "type": event["type"], "payload": json.loads(payload.decode("utf-8"))},
        )
        await db.commit()
    except Exception:
        pass

    et = event["type"]
    obj = event["data"]["object"]
    # Handle checkout completion
    if et == "checkout.session.completed":
        uid = obj.get("metadata", {}).get("user_id")
        customer_id = obj.get("customer")
        subscription_id = obj.get("subscription")
        if uid and subscription_id:
            await db.execute(
                text(
                    """
                    UPDATE subscriptions
                    SET plan='premium', status='active', stripe_customer_id=:cust, stripe_subscription_id=:sub
                    WHERE user_id = :uid
                    """
                ),
                {"uid": uid, "cust": customer_id, "sub": subscription_id},
            )
            await db.commit()
    # Handle subscription updates and billing events
    if et in ("customer.subscription.updated", "customer.subscription.deleted", "customer.subscription.created"):
        sub_id = obj.get("id")
        status_val = obj.get("status") or "canceled"
        cpe = obj.get("current_period_end")
        cancel_at_period_end = bool(obj.get("cancel_at_period_end"))
        await db.execute(
            text(
                """
                UPDATE subscriptions
                SET status=:status, current_period_end = to_timestamp(:cpe), cancel_at_period_end=:cpef
                WHERE stripe_subscription_id=:sub
                """
            ),
            {"status": status_val, "cpe": cpe or 0, "cpef": cancel_at_period_end, "sub": sub_id},
        )
        await db.commit()

    if et == "invoice.payment_succeeded":
        # ensure user stays active; find user via customer
        cust = obj.get("customer")
        if cust:
            await db.execute(
                text("UPDATE subscriptions SET status='active' WHERE stripe_customer_id=:cust"),
                {"cust": cust},
            )
            await db.commit()

    if et in ("invoice.payment_failed", "customer.subscription.paused"):
        cust = obj.get("customer")
        if cust:
            await db.execute(
                text("UPDATE subscriptions SET status='past_due' WHERE stripe_customer_id=:cust"),
                {"cust": cust},
            )
            await db.commit()

    return {"ok": True}


@router.delete("/account")
async def account_delete(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Best-effort S3 cleanup scheduled along with deletion job
    await db.execute(text("INSERT INTO deletion_jobs(user_id) VALUES (:uid)"), {"uid": user["id"]})
    await db.commit()
    return {"scheduled": True}


