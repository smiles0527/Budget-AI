from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from ..config import settings
from ..db import get_db


router = APIRouter(prefix="/v1/rules")


def _check_admin(secret: str | None):
    if settings.env != "dev" and (not settings.admin_secret or secret != settings.admin_secret):
        raise HTTPException(status_code=403, detail="Forbidden")


class MerchantRule(BaseModel):
    merchant_pattern: str
    category: str
    confidence: float
    active: bool = True


@router.get("/merchant")
async def list_merchant_rules(db: AsyncSession = Depends(get_db)):
    res = await db.execute(text("SELECT id, merchant_pattern, category, confidence, active, created_at FROM merchant_rules ORDER BY created_at DESC"))
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.post("/merchant")
async def create_merchant_rule(body: MerchantRule, x_admin_secret: str | None = Header(default=None), db: AsyncSession = Depends(get_db)):
    _check_admin(x_admin_secret)
    await db.execute(
        text(
            "INSERT INTO merchant_rules(merchant_pattern, category, confidence, active) VALUES (:p, :c, :conf, :a)"
        ),
        {"p": body.merchant_pattern, "c": body.category, "conf": body.confidence, "a": body.active},
    )
    await db.commit()
    return {"ok": True}


class KeywordRule(BaseModel):
    keyword: str
    scope: str = "both"
    category: str
    confidence: float
    active: bool = True


@router.get("/keyword")
async def list_keyword_rules(db: AsyncSession = Depends(get_db)):
    res = await db.execute(text("SELECT id, keyword, scope, category, confidence, active, created_at FROM keyword_rules ORDER BY created_at DESC"))
    return {"items": [dict(r) for r in res.mappings().all()]}


@router.post("/keyword")
async def create_keyword_rule(body: KeywordRule, x_admin_secret: str | None = Header(default=None), db: AsyncSession = Depends(get_db)):
    _check_admin(x_admin_secret)
    await db.execute(
        text(
            "INSERT INTO keyword_rules(keyword, scope, category, confidence, active) VALUES (:k, :s, :c, :conf, :a)"
        ),
        {"k": body.keyword, "s": body.scope, "c": body.category, "conf": body.confidence, "a": body.active},
    )
    await db.commit()
    return {"ok": True}



