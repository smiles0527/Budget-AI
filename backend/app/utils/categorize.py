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


# ML fallback: keyword-based category mapping
ML_CATEGORY_KEYWORDS = {
    "groceries": ["grocery", "supermarket", "walmart", "target", "kroger", "safeway", "whole foods", "trader joe", "food", "produce", "meat", "dairy"],
    "dining": ["restaurant", "cafe", "coffee", "starbucks", "mcdonald", "burger", "pizza", "dining", "food", "eat", "meal", "lunch", "dinner", "breakfast", "bar", "grill"],
    "transport": ["gas", "fuel", "uber", "lyft", "taxi", "metro", "subway", "bus", "train", "airline", "airport", "parking", "toll", "car", "vehicle"],
    "shopping": ["store", "shop", "retail", "amazon", "mall", "clothing", "apparel", "shoes", "electronics", "home", "furniture"],
    "entertainment": ["movie", "cinema", "theater", "netflix", "spotify", "music", "concert", "game", "sports", "ticket", "entertainment"],
    "subscriptions": ["subscription", "monthly", "annual", "premium", "membership", "recurring"],
    "utilities": ["electric", "water", "gas", "utility", "power", "internet", "phone", "cable", "internet service"],
    "health": ["pharmacy", "drug", "medical", "doctor", "hospital", "clinic", "health", "dental", "vision", "insurance"],
    "education": ["school", "university", "college", "tuition", "book", "course", "education", "learning"],
    "travel": ["hotel", "airbnb", "travel", "vacation", "trip", "booking", "resort"],
}


def _ml_categorize_fallback(merchant: Optional[str], raw_text: Optional[str]) -> Optional[str]:
    """Simple ML fallback using keyword matching when rules don't match."""
    search_text = ""
    if merchant:
        search_text += merchant.lower() + " "
    if raw_text:
        search_text += raw_text.lower()
    
    if not search_text:
        return None
    
    # Score categories based on keyword matches
    scores = {}
    for category, keywords in ML_CATEGORY_KEYWORDS.items():
        score = 0
        for keyword in keywords:
            if keyword in search_text:
                score += 1
        if score > 0:
            scores[category] = score
    
    if scores:
        # Return category with highest score
        return max(scores.items(), key=lambda x: x[1])[0]
    
    return None


async def determine_category(
    db: AsyncSession,
    merchant: Optional[str] = None,
    raw_text: Optional[str] = None,
) -> str:
    """
    Return category using rules first, then ML fallback, default to 'other'.
    
    Priority:
    1. Merchant rules (confidence >= 0.8)
    2. Keyword rules (confidence >= 0.8)
    3. ML keyword matching fallback
    4. 'other'
    """
    best_cat: Optional[str] = None
    best_conf: float = -1.0

    # Try merchant rules
    m = await _match_merchant_category(db, merchant)
    if m and m[1] > best_conf:
        best_cat, best_conf = m

    # Try keyword rules
    k = await _match_keyword_category(db, raw_text, scope="both")
    if k and k[1] > best_conf:
        best_cat, best_conf = k

    # If we have a high-confidence rule match, use it
    if best_conf >= 0.8:
        return best_cat or "other"
    
    # Otherwise, try ML fallback
    ml_cat = _ml_categorize_fallback(merchant, raw_text)
    if ml_cat:
        return ml_cat

    return best_cat or "other"


