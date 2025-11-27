from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Header, Request, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import text
import stripe
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date, timedelta

from ..db import get_db
from ..config import settings
from ..utils.security import hash_password, verify_password, generate_session_token, session_expiry
from ..utils.storage import presign_put, presign_get, head_object
from ..utils.cursor import encode_cursor, decode_cursor
from ..utils.auth import get_current_user
from ..errors import AppError
from ..utils.oauth import verify_google, verify_apple
from ..utils.categorize import determine_category
from ..utils.badges import check_and_award_badges
from ..utils.analytics import (
    get_spending_trends,
    detect_recurring_transactions,
    get_spending_forecast,
    get_spending_insights,
    get_category_comparison,
)
from ..utils.budget_alerts import check_and_create_budget_alerts


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
    
    # Get profile
    profile_res = await db.execute(
        text("SELECT * FROM profiles WHERE user_id = :uid"),
        {"uid": user["id"]},
    )
    profile = profile_res.mappings().first()
    
    return {
        "user": user,
        "subscription": dict(s) if s else None,
        "profile": dict(profile) if profile else None,
    }


class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    currency_code: Optional[str] = None
    timezone: Optional[str] = None
    marketing_opt_in: Optional[bool] = None
    notification_budget_alerts: Optional[bool] = None
    notification_goal_achieved: Optional[bool] = None
    notification_streak_reminders: Optional[bool] = None
    notification_weekly_summary: Optional[bool] = None


@router.patch("/profile")
async def profile_update(body: ProfileUpdate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    updates = []
    params = {"uid": user["id"]}
    
    if body.display_name is not None:
        updates.append("display_name = :display_name")
        params["display_name"] = body.display_name
    if body.currency_code is not None:
        updates.append("currency_code = :currency_code")
        params["currency_code"] = body.currency_code
    if body.timezone is not None:
        updates.append("timezone = :timezone")
        params["timezone"] = body.timezone
    if body.marketing_opt_in is not None:
        updates.append("marketing_opt_in = :marketing_opt_in")
        params["marketing_opt_in"] = body.marketing_opt_in
    if body.notification_budget_alerts is not None:
        updates.append("notification_budget_alerts = :notification_budget_alerts")
        params["notification_budget_alerts"] = body.notification_budget_alerts
    if body.notification_goal_achieved is not None:
        updates.append("notification_goal_achieved = :notification_goal_achieved")
        params["notification_goal_achieved"] = body.notification_goal_achieved
    if body.notification_streak_reminders is not None:
        updates.append("notification_streak_reminders = :notification_streak_reminders")
        params["notification_streak_reminders"] = body.notification_streak_reminders
    if body.notification_weekly_summary is not None:
        updates.append("notification_weekly_summary = :notification_weekly_summary")
        params["notification_weekly_summary"] = body.notification_weekly_summary
    
    if not updates:
        return {"updated": False}
    
    await db.execute(
        text(f"UPDATE profiles SET {', '.join(updates)} WHERE user_id = :uid"),
        params,
    )
    await db.commit()
    return {"updated": True}


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
    
    # Check for badge awards (will be re-checked after OCR completes, but check here too)
    await check_and_award_badges(db, user["id"], "receipt_uploaded")
    
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
    data = dict(rec)
    # Add presigned URL for viewing the receipt image if storage_uri exists and is not 'pending'
    if data.get("storage_uri") and data.get("storage_uri") != "pending":
        from ..utils.storage import presign_get
        data["image_url"] = presign_get(data["storage_uri"])
    return data


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
    txn = dict(row)
    
    # Include transaction items
    items_res = await db.execute(
        text("SELECT * FROM transaction_items WHERE transaction_id = :txn_id ORDER BY line_index"),
        {"txn_id": txn_id},
    )
    txn["items"] = [dict(r) for r in items_res.mappings().all()]
    
    return txn


@router.get("/transactions/{txn_id}/items")
async def transactions_items_get(txn_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Verify transaction ownership
    txn_res = await db.execute(
        text("SELECT id FROM transactions WHERE id = :id AND user_id = :uid"),
        {"id": txn_id, "uid": user["id"]},
    )
    if not txn_res.first():
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    res = await db.execute(
        text("SELECT * FROM transaction_items WHERE transaction_id = :txn_id ORDER BY line_index"),
        {"txn_id": txn_id},
    )
    return {"items": [dict(r) for r in res.mappings().all()]}


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
    
    # Check budgets and create alerts
    await check_and_create_budget_alerts(db, user["id"])
    
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
    
    # Check for alerts and badges after budget update
    await check_and_create_budget_alerts(db, user["id"])
    await check_and_award_badges(db, user["id"], "budget_checked")
    
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


# ===================
# Savings Goals API
# ===================

class SavingsGoalCreate(BaseModel):
    name: str
    category: Optional[str] = None
    target_cents: int
    start_date: Optional[str] = None  # YYYY-MM-DD, defaults to today
    target_date: Optional[str] = None  # YYYY-MM-DD


@router.post("/savings/goals")
async def savings_goals_create(body: SavingsGoalCreate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    start = body.start_date or date.today().isoformat()
    res = await db.execute(
        text(
            """
            INSERT INTO savings_goals(user_id, name, category, target_cents, start_date, target_date, status)
            VALUES (:uid, :name, :cat, :target, :start, :target_date, 'active')
            RETURNING id
            """
        ),
        {
            "uid": user["id"],
            "name": body.name,
            "cat": body.category,
            "target": body.target_cents,
            "start": start,
            "target_date": body.target_date,
        },
    )
    goal_id = res.scalar_one()
    await db.commit()
    return {"id": str(goal_id)}


@router.get("/savings/goals")
async def savings_goals_list(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), status: Optional[str] = None):
    if status:
        res = await db.execute(
            text("SELECT * FROM savings_goals WHERE user_id = :uid AND status = :status ORDER BY created_at DESC"),
            {"uid": user["id"], "status": status},
        )
    else:
        res = await db.execute(
            text("SELECT * FROM savings_goals WHERE user_id = :uid ORDER BY created_at DESC"),
            {"uid": user["id"]},
        )
    goals = []
    for row in res.mappings().all():
        goal = dict(row)
        # Calculate progress
        contrib_res = await db.execute(
            text("SELECT COALESCE(SUM(amount_cents), 0) as total FROM savings_contributions WHERE goal_id = :gid"),
            {"gid": goal["id"]},
        )
        contributed = contrib_res.scalar_one() or 0
        goal["contributed_cents"] = contributed
        goal["progress_percent"] = min(100, int((contributed / goal["target_cents"]) * 100)) if goal["target_cents"] > 0 else 0
        goals.append(goal)
    return {"items": goals}


@router.get("/savings/goals/{goal_id}")
async def savings_goals_get(goal_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text("SELECT * FROM savings_goals WHERE id = :gid AND user_id = :uid"),
        {"gid": goal_id, "uid": user["id"]},
    )
    goal = res.mappings().first()
    if not goal:
        raise HTTPException(status_code=404, detail="Not found")
    goal_dict = dict(goal)
    
    # Get contributions
    contrib_res = await db.execute(
        text("SELECT * FROM savings_contributions WHERE goal_id = :gid ORDER BY contributed_at DESC"),
        {"gid": goal_id},
    )
    contributions = [dict(r) for r in contrib_res.mappings().all()]
    contributed_total = sum(c["amount_cents"] for c in contributions)
    
    goal_dict["contributions"] = contributions
    goal_dict["contributed_cents"] = contributed_total
    goal_dict["progress_percent"] = min(100, int((contributed_total / goal_dict["target_cents"]) * 100)) if goal_dict["target_cents"] > 0 else 0
    return goal_dict


class SavingsContributionCreate(BaseModel):
    amount_cents: int
    note: Optional[str] = None


@router.post("/savings/goals/{goal_id}/contributions")
async def savings_contributions_create(goal_id: str, body: SavingsContributionCreate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Verify goal ownership
    goal_res = await db.execute(
        text("SELECT id, target_cents, status FROM savings_goals WHERE id = :gid AND user_id = :uid"),
        {"gid": goal_id, "uid": user["id"]},
    )
    goal = goal_res.mappings().first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if goal["status"] != "active":
        raise HTTPException(status_code=400, detail="Goal is not active")
    
    # Create contribution
    contrib_res = await db.execute(
        text(
            """
            INSERT INTO savings_contributions(goal_id, amount_cents, note)
            VALUES (:gid, :amount, :note)
            RETURNING id
            """
        ),
        {"gid": goal_id, "amount": body.amount_cents, "note": body.note},
    )
    contrib_id = contrib_res.scalar_one()
    
    # Check if goal is achieved
    total_res = await db.execute(
        text("SELECT COALESCE(SUM(amount_cents), 0) as total FROM savings_contributions WHERE goal_id = :gid"),
        {"gid": goal_id},
    )
    total_contributed = total_res.scalar_one() or 0
    
    if total_contributed >= goal["target_cents"]:
        await db.execute(
            text("UPDATE savings_goals SET status = 'achieved' WHERE id = :gid"),
            {"gid": goal_id},
        )
        # Award badge
        await check_and_award_badges(db, user["id"], "savings_goal_achieved", amount_cents=total_contributed)
    
    await db.commit()
    return {"id": str(contrib_id)}


@router.patch("/savings/goals/{goal_id}")
async def savings_goals_update(goal_id: str, body: dict, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Verify ownership
    goal_res = await db.execute(
        text("SELECT id FROM savings_goals WHERE id = :gid AND user_id = :uid"),
        {"gid": goal_id, "uid": user["id"]},
    )
    if not goal_res.first():
        raise HTTPException(status_code=404, detail="Goal not found")
    
    allowed_fields = ["name", "target_cents", "target_date", "status"]
    updates = []
    params = {"gid": goal_id}
    
    for field in allowed_fields:
        if field in body:
            updates.append(f"{field} = :{field}")
            params[field] = body[field]
    
    if not updates:
        return {"id": goal_id, "updated": False}
    
    await db.execute(
        text(f"UPDATE savings_goals SET {', '.join(updates)} WHERE id = :gid"),
        params,
    )
    await db.commit()
    return {"id": goal_id, "updated": True}


@router.delete("/savings/goals/{goal_id}")
async def savings_goals_delete(goal_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Cancel goal (soft delete by setting status)
    await db.execute(
        text("UPDATE savings_goals SET status = 'cancelled' WHERE id = :gid AND user_id = :uid"),
        {"gid": goal_id, "uid": user["id"]},
    )
    await db.commit()
    return {"id": goal_id, "deleted": True}


# ===================
# Linked Accounts API
# ===================

class LinkedAccountCreate(BaseModel):
    provider: str  # 'plaid', 'truelayer', etc.
    provider_account_id: str
    institution_name: Optional[str] = None
    account_mask: Optional[str] = None
    account_name: Optional[str] = None
    account_type: Optional[str] = None
    account_subtype: Optional[str] = None


@router.post("/linked-accounts")
async def linked_accounts_create(body: LinkedAccountCreate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text(
            """
            INSERT INTO linked_accounts(user_id, provider, provider_account_id, institution_name, account_mask, account_name, account_type, account_subtype, status)
            VALUES (:uid, :provider, :provider_account_id, :institution_name, :account_mask, :account_name, :account_type, :account_subtype, 'active')
            ON CONFLICT (provider, provider_account_id) DO UPDATE
            SET user_id = EXCLUDED.user_id,
                institution_name = EXCLUDED.institution_name,
                account_mask = EXCLUDED.account_mask,
                account_name = EXCLUDED.account_name,
                account_type = EXCLUDED.account_type,
                account_subtype = EXCLUDED.account_subtype,
                status = 'active',
                last_synced_at = now()
            RETURNING id
            """
        ),
        {
            "uid": user["id"],
            "provider": body.provider,
            "provider_account_id": body.provider_account_id,
            "institution_name": body.institution_name,
            "account_mask": body.account_mask,
            "account_name": body.account_name,
            "account_type": body.account_type,
            "account_subtype": body.account_subtype,
        },
    )
    account_id = res.scalar_one()
    await db.commit()
    return {"id": str(account_id)}


@router.get("/linked-accounts")
async def linked_accounts_list(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), status: Optional[str] = None):
    if status:
        res = await db.execute(
            text("SELECT * FROM linked_accounts WHERE user_id = :uid AND status = :status ORDER BY created_at DESC"),
            {"uid": user["id"], "status": status},
        )
    else:
        res = await db.execute(
            text("SELECT * FROM linked_accounts WHERE user_id = :uid ORDER BY created_at DESC"),
            {"uid": user["id"]},
        )
    accounts = []
    for row in res.mappings().all():
        account = dict(row)
        # Get latest balance
        balance_res = await db.execute(
            text(
                """
                SELECT current_cents, available_cents, currency_code, as_of
                FROM account_balances
                WHERE linked_account_id = :aid
                ORDER BY as_of DESC
                LIMIT 1
                """
            ),
            {"aid": account["id"]},
        )
        balance = balance_res.mappings().first()
        if balance:
            account["balance"] = dict(balance)
        accounts.append(account)
    return {"items": accounts}


@router.get("/linked-accounts/{account_id}")
async def linked_accounts_get(account_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text("SELECT * FROM linked_accounts WHERE id = :aid AND user_id = :uid"),
        {"aid": account_id, "uid": user["id"]},
    )
    account = res.mappings().first()
    if not account:
        raise HTTPException(status_code=404, detail="Not found")
    account_dict = dict(account)
    
    # Get balance history
    balance_res = await db.execute(
        text(
            """
            SELECT current_cents, available_cents, currency_code, as_of
            FROM account_balances
            WHERE linked_account_id = :aid
            ORDER BY as_of DESC
            LIMIT 30
            """
        ),
        {"aid": account_id},
    )
    balances = [dict(r) for r in balance_res.mappings().all()]
    account_dict["balances"] = balances
    
    # Get import runs
    import_res = await db.execute(
        text(
            """
            SELECT * FROM bank_import_runs
            WHERE linked_account_id = :aid
            ORDER BY created_at DESC
            LIMIT 10
            """
        ),
        {"aid": account_id},
    )
    imports = [dict(r) for r in import_res.mappings().all()]
    account_dict["import_runs"] = imports
    
    return account_dict


class AccountBalanceCreate(BaseModel):
    current_cents: Optional[int] = None
    available_cents: Optional[int] = None
    currency_code: str = "USD"


@router.post("/linked-accounts/{account_id}/balances")
async def linked_accounts_balance_create(account_id: str, body: AccountBalanceCreate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Verify ownership
    account_res = await db.execute(
        text("SELECT id FROM linked_accounts WHERE id = :aid AND user_id = :uid"),
        {"aid": account_id, "uid": user["id"]},
    )
    if not account_res.first():
        raise HTTPException(status_code=404, detail="Account not found")
    
    await db.execute(
        text(
            """
            INSERT INTO account_balances(linked_account_id, current_cents, available_cents, currency_code)
            VALUES (:aid, :current, :available, :currency)
            """
        ),
        {
            "aid": account_id,
            "current": body.current_cents,
            "available": body.available_cents,
            "currency": body.currency_code,
        },
    )
    await db.commit()
    return {"ok": True}


@router.delete("/linked-accounts/{account_id}")
async def linked_accounts_delete(account_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Revoke account (soft delete)
    await db.execute(
        text("UPDATE linked_accounts SET status = 'revoked' WHERE id = :aid AND user_id = :uid"),
        {"aid": account_id, "uid": user["id"]},
    )
    await db.commit()
    return {"id": account_id, "deleted": True}


# ===================
# Push Notifications API
# ===================

class PushDeviceRegister(BaseModel):
    platform: str  # 'apns' or 'fcm'
    token: str


@router.post("/push/devices")
async def push_devices_register(body: PushDeviceRegister, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if body.platform not in ("apns", "fcm"):
        raise HTTPException(status_code=400, detail="Platform must be 'apns' or 'fcm'")
    
    await db.execute(
        text(
            """
            INSERT INTO push_devices(user_id, platform, token, is_active, last_seen_at)
            VALUES (:uid, :platform, :token, true, now())
            ON CONFLICT (user_id, platform, token) DO UPDATE
            SET is_active = true, last_seen_at = now()
            """
        ),
        {
            "uid": user["id"],
            "platform": body.platform,
            "token": body.token,
        },
    )
    await db.commit()
    return {"ok": True}


@router.get("/push/devices")
async def push_devices_list(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text("SELECT id, platform, token, is_active, created_at, last_seen_at FROM push_devices WHERE user_id = :uid ORDER BY created_at DESC"),
        {"uid": user["id"]},
    )
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.delete("/push/devices/{device_id}")
async def push_devices_delete(device_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(
        text("UPDATE push_devices SET is_active = false WHERE id = :did AND user_id = :uid"),
        {"did": device_id, "uid": user["id"]},
    )
    await db.commit()
    return {"id": device_id, "deleted": True}


# ===================
# Advanced Analytics & Insights
# ===================

@router.get("/analytics/trends")
async def analytics_trends(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), months: int = 6):
    """Get month-over-month spending trends."""
    if months < 1 or months > 24:
        raise HTTPException(status_code=400, detail="Months must be between 1 and 24")
    return await get_spending_trends(db, user["id"], months)


@router.get("/analytics/forecast")
async def analytics_forecast(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), months_ahead: int = 1):
    """Forecast spending for next N months."""
    if months_ahead < 1 or months_ahead > 12:
        raise HTTPException(status_code=400, detail="Months ahead must be between 1 and 12")
    return await get_spending_forecast(db, user["id"], months_ahead)


@router.get("/analytics/insights")
async def analytics_insights(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Get actionable spending insights and recommendations."""
    return await get_spending_insights(db, user["id"])


@router.get("/analytics/recurring")
async def analytics_recurring(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Detect recurring transactions."""
    return {"recurring": await detect_recurring_transactions(db, user["id"])}


@router.get("/analytics/compare")
async def analytics_compare(
    user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    period1_start: Optional[str] = None,
    period1_end: Optional[str] = None,
    period2_start: Optional[str] = None,
    period2_end: Optional[str] = None,
):
    """Compare spending between two periods."""
    if not all([period1_start, period1_end, period2_start, period2_end]):
        # Default: compare last month vs this month
        today = date.today()
        this_month_start = today.replace(day=1)
        last_month_end = this_month_start - timedelta(days=1)
        last_month_start = last_month_end.replace(day=1)
        
        p1_start = last_month_start
        p1_end = last_month_end
        p2_start = this_month_start
        p2_end = today
    else:
        p1_start = date.fromisoformat(period1_start or "")
        p1_end = date.fromisoformat(period1_end or "")
        p2_start = date.fromisoformat(period2_start or "")
        p2_end = date.fromisoformat(period2_end or "")
    
    return await get_category_comparison(db, user["id"], p1_start, p1_end, p2_start, p2_end)


# ===================
# Search
# ===================

@router.get("/transactions/search")
async def transactions_search(
    user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    q: Optional[str] = None,
    limit: int = 50,
    cursor: Optional[str] = None,
):
    """Full-text search transactions by merchant, category, or subcategory."""
    if not q or len(q.strip()) < 2:
        raise HTTPException(status_code=400, detail="Query must be at least 2 characters")
    
    limit = max(1, min(limit, 200))
    cur = decode_cursor(cursor)
    
    if cur:
        sql = """
            SELECT * FROM transactions
            WHERE user_id = :uid
              AND to_tsvector('english', COALESCE(merchant, '') || ' ' || COALESCE(subcategory, '') || ' ' || COALESCE(category::text, '')) @@ plainto_tsquery('english', :query)
              AND (txn_date, created_at, id) < (:cd, :cc, :cid)
            ORDER BY txn_date DESC, created_at DESC, id DESC
            LIMIT :lim
        """
        params = {
            "uid": user["id"],
            "query": q,
            "cd": cur.get("txn_date"),
            "cc": cur.get("created_at"),
            "cid": cur.get("id"),
            "lim": limit + 1,
        }
    else:
        sql = """
            SELECT * FROM transactions
            WHERE user_id = :uid
              AND to_tsvector('english', COALESCE(merchant, '') || ' ' || COALESCE(subcategory, '') || ' ' || COALESCE(category::text, '')) @@ plainto_tsquery('english', :query)
            ORDER BY txn_date DESC, created_at DESC, id DESC
            LIMIT :lim
        """
        params = {"uid": user["id"], "query": q, "lim": limit + 1}
    
    res = await db.execute(text(sql), params)
    rows = [dict(r) for r in res.mappings().all()]
    
    next_cursor = None
    if len(rows) > limit:
        last = rows[limit - 1]
        next_cursor = encode_cursor(
            {"txn_date": last["txn_date"], "created_at": last["created_at"], "id": last["id"]}
        )
        rows = rows[:limit]
    
    return {"items": rows, "next_cursor": next_cursor, "query": q}


# ===================
# Transaction Tags
# ===================

class TagCreate(BaseModel):
    name: str
    color: Optional[str] = None


@router.post("/tags")
async def tags_create(body: TagCreate, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text(
            """
            INSERT INTO transaction_tags(user_id, name, color)
            VALUES (:uid, :name, :color)
            ON CONFLICT (user_id, name) DO UPDATE SET color = EXCLUDED.color
            RETURNING id
            """
        ),
        {"uid": user["id"], "name": body.name, "color": body.color},
    )
    tag_id = res.scalar_one()
    await db.commit()
    return {"id": str(tag_id)}


@router.get("/tags")
async def tags_list(user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    res = await db.execute(
        text("SELECT * FROM transaction_tags WHERE user_id = :uid ORDER BY name"),
        {"uid": user["id"]},
    )
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.post("/transactions/{txn_id}/tags/{tag_id}")
async def transactions_tag_add(txn_id: str, tag_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Verify ownership
    txn_res = await db.execute(
        text("SELECT id FROM transactions WHERE id = :id AND user_id = :uid"),
        {"id": txn_id, "uid": user["id"]},
    )
    if not txn_res.first():
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    tag_res = await db.execute(
        text("SELECT id FROM transaction_tags WHERE id = :tid AND user_id = :uid"),
        {"tid": tag_id, "uid": user["id"]},
    )
    if not tag_res.first():
        raise HTTPException(status_code=404, detail="Tag not found")
    
    await db.execute(
        text(
            """
            INSERT INTO transaction_tag_assignments(transaction_id, tag_id)
            VALUES (:txn_id, :tag_id)
            ON CONFLICT DO NOTHING
            """
        ),
        {"txn_id": txn_id, "tag_id": tag_id},
    )
    await db.commit()
    return {"ok": True}


@router.delete("/transactions/{txn_id}/tags/{tag_id}")
async def transactions_tag_remove(txn_id: str, tag_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(
        text(
            """
            DELETE FROM transaction_tag_assignments
            WHERE transaction_id = :txn_id AND tag_id = :tag_id
              AND EXISTS (SELECT 1 FROM transactions WHERE id = :txn_id AND user_id = :uid)
            """
        ),
        {"txn_id": txn_id, "tag_id": tag_id, "uid": user["id"]},
    )
    await db.commit()
    return {"ok": True}


@router.delete("/tags/{tag_id}")
async def tags_delete(tag_id: str, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(
        text("DELETE FROM transaction_tags WHERE id = :tid AND user_id = :uid"),
        {"tid": tag_id, "uid": user["id"]},
    )
    await db.commit()
    return {"id": tag_id, "deleted": True}


# ===================
# Budget Alerts
# ===================

@router.get("/alerts")
async def alerts_list(user=Depends(get_current_user), db: AsyncSession = Depends(get_db), status: Optional[str] = None):
    if status:
        res = await db.execute(
            text("SELECT * FROM budget_alerts WHERE user_id = :uid AND status = :status ORDER BY created_at DESC"),
            {"uid": user["id"], "status": status},
        )
    else:
        res = await db.execute(
            text("SELECT * FROM budget_alerts WHERE user_id = :uid ORDER BY created_at DESC LIMIT 50"),
            {"uid": user["id"]},
        )
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.patch("/alerts/{alert_id}")
async def alerts_update(alert_id: str, body: dict, user=Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    allowed_fields = ["status"]
    updates = []
    params = {"aid": alert_id, "uid": user["id"]}
    
    if "status" in body:
        updates.append("status = :status")
        params["status"] = body["status"]
        if body["status"] == "dismissed":
            updates.append("dismissed_at = now()")
        elif body["status"] == "resolved":
            updates.append("resolved_at = now()")
    
    if not updates:
        return {"id": alert_id, "updated": False}
    
    await db.execute(
        text(f"UPDATE budget_alerts SET {', '.join(updates)} WHERE id = :aid AND user_id = :uid"),
        params,
    )
    await db.commit()
    return {"id": alert_id, "updated": True}


