"""
Budget alert generation utilities.
"""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date


async def check_and_create_budget_alerts(db: AsyncSession, user_id: str):
    """Check budgets and create alerts if thresholds are exceeded."""
    # Get active budgets for current period
    res = await db.execute(
        text(
            """
            SELECT 
                b.id,
                b.category,
                b.limit_cents,
                b.period_start,
                b.period_end,
                COALESCE(SUM(t.total_cents), 0) as spent_cents
            FROM budgets b
            LEFT JOIN transactions t ON t.user_id = b.user_id 
              AND t.category = b.category
              AND t.txn_date BETWEEN b.period_start AND b.period_end
            WHERE b.user_id = :uid
              AND b.period_start <= CURRENT_DATE
              AND b.period_end >= CURRENT_DATE
            GROUP BY b.id, b.category, b.limit_cents, b.period_start, b.period_end
            """
        ),
        {"uid": user_id},
    )
    
    for row in res.mappings().all():
        budget_id = row["id"]
        category = row["category"]
        limit_cents = row["limit_cents"]
        spent_cents = row["spent_cents"] or 0
        pct_used = (spent_cents / limit_cents * 100) if limit_cents > 0 else 0
        
        # Check if alert already exists
        existing_res = await db.execute(
            text(
                """
                SELECT id FROM budget_alerts
                WHERE user_id = :uid
                  AND budget_id = :bid
                  AND status = 'active'
                  AND alert_type IN ('budget_warning', 'budget_exceeded')
                """
            ),
            {"uid": user_id, "bid": budget_id},
        )
        existing = existing_res.first()
        
        # Create warning alert at 90%
        if pct_used >= 90 and pct_used < 100 and not existing:
            await db.execute(
                text(
                    """
                    INSERT INTO budget_alerts(user_id, alert_type, budget_id, category, message, threshold_cents, current_cents, status)
                    VALUES (:uid, 'budget_warning', :bid, :cat, :msg, :threshold, :current, 'active')
                    """
                ),
                {
                    "uid": user_id,
                    "bid": budget_id,
                    "cat": category,
                    "msg": f"You've used {pct_used:.1f}% of your {category} budget",
                    "threshold": int(limit_cents * 0.9),
                    "current": spent_cents,
                },
            )
        
        # Create exceeded alert at 100%
        elif pct_used >= 100 and not existing:
            await db.execute(
                text(
                    """
                    INSERT INTO budget_alerts(user_id, alert_type, budget_id, category, message, threshold_cents, current_cents, status)
                    VALUES (:uid, 'budget_exceeded', :bid, :cat, :msg, :threshold, :current, 'active')
                    """
                ),
                {
                    "uid": user_id,
                    "bid": budget_id,
                    "cat": category,
                    "msg": f"You've exceeded your {category} budget by ${(spent_cents - limit_cents)/100:.2f}",
                    "threshold": limit_cents,
                    "current": spent_cents,
                },
            )
    
    await db.commit()

