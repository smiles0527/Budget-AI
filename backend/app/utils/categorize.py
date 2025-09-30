from __future__ import annotations

import re
from typing import Optional, Tuple

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def _match_merchant_category(db: AsyncSession, merchant: Optional[str]) -> Optional[Tuple[str, float]]:
    if not merchant:
        return None
    res = await db.execute(
        text(
            """
            SELECT merchant_pattern, category, confidence
            FROM merchant_rules
            WHERE active = true
            """
        )
    )
    best: Optional[Tuple[str, float]] = None
    lower_name = merchant.lower()
    for row in res.mappings().all():
        pattern = row["merchant_pattern"] or ""
        cat = row["category"]
        conf = float(row["confidence"]) if row["confidence"] is not None else 0.0
        matched = False
        try:
            if pattern:
                if re.search(pattern, merchant, flags=re.IGNORECASE):
                    matched = True
        except Exception:
            if pattern and pattern.lower() in lower_name:
                matched = True
        if matched:
            if best is None or conf > best[1]:
                best = (cat, conf)
    return best


async def _match_keyword_category(db: AsyncSession, text_blob: Optional[str], scope: str = "both") -> Optional[Tuple[str, float]]:
    if not text_blob:
        return None
    res = await db.execute(
        text(
            """
            SELECT keyword, scope, category, confidence
            FROM keyword_rules
            WHERE active = true
            """
        )
    )
    best: Optional[Tuple[str, float]] = None
    lower_blob = text_blob.lower()
    for row in res.mappings().all():
        kw = (row["keyword"] or "").lower()
        rule_scope = row["scope"] or "both"
        if rule_scope not in ("both", scope):
            continue
        if kw and kw in lower_blob:
            cat = row["category"]
            conf = float(row["confidence"]) if row["confidence"] is not None else 0.0
            if best is None or conf > best[1]:
                best = (cat, conf)
    return best


async def determine_category(
    db: AsyncSession,
    merchant: Optional[str] = None,
    raw_text: Optional[str] = None,
) -> str:
    """Return category using rules; default to 'other'."""
    best_cat: Optional[str] = None
    best_conf: float = -1.0

    m = await _match_merchant_category(db, merchant)
    if m and m[1] > best_conf:
        best_cat, best_conf = m

    k = await _match_keyword_category(db, raw_text, scope="both")
    if k and k[1] > best_conf:
        best_cat, best_conf = k

    return best_cat or "other"


