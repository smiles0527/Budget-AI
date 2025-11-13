"""
Badge awarding logic for gamification features.
"""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date, timedelta


async def check_and_award_badges(db: AsyncSession, user_id: str, event_type: str, **kwargs):
    """
    Check if user qualifies for any badges and award them.
    
    Args:
        db: Database session
        user_id: User UUID
        event_type: Type of event ('receipt_uploaded', 'transaction_created', 'savings_goal_achieved', 'budget_checked', etc.)
        **kwargs: Additional context (e.g., receipt_id, transaction_id, amount_cents)
    """
    if event_type == "receipt_uploaded":
        await _check_first_scan(db, user_id)
        await _check_streak_badges(db, user_id)
        await check_spending_milestone_badges(db, user_id)
    elif event_type == "savings_goal_achieved":
        await _check_savings_badges(db, user_id, kwargs.get("amount_cents", 0))
    elif event_type == "transaction_created":
        await _check_streak_badges(db, user_id)
        await check_spending_milestone_badges(db, user_id)
    elif event_type == "budget_checked":
        await check_budget_badges(db, user_id)


async def _award_badge(db: AsyncSession, user_id: str, badge_code: str):
    """Award a badge to a user if they don't already have it."""
    try:
        await db.execute(
            text(
                """
                INSERT INTO user_badges(user_id, badge_id)
                SELECT :uid, b.id
                FROM badges b
                WHERE b.code = :code
                  AND NOT EXISTS (
                    SELECT 1 FROM user_badges ub
                    WHERE ub.user_id = :uid AND ub.badge_id = b.id
                  )
                RETURNING badge_id
                """
            ),
            {"uid": user_id, "code": badge_code},
        )
        await db.commit()
    except Exception:
        # Badge already awarded or doesn't exist - ignore
        await db.rollback()
        pass


async def _check_first_scan(db: AsyncSession, user_id: str):
    """Check if this is the user's first receipt scan."""
    res = await db.execute(
        text(
            """
            SELECT COUNT(*) as count
            FROM receipts
            WHERE user_id = :uid AND ocr_status = 'done'
            """
        ),
        {"uid": user_id},
    )
    count = res.scalar_one()
    if count == 1:
        await _award_badge(db, user_id, "FIRST_SCAN")


async def _check_streak_badges(db: AsyncSession, user_id: str):
    """Check for consecutive day streaks."""
    # Get all transaction dates for user
    res = await db.execute(
        text(
            """
            SELECT DISTINCT txn_date
            FROM transactions
            WHERE user_id = :uid
            ORDER BY txn_date DESC
            LIMIT 30
            """
        ),
        {"uid": user_id},
    )
    dates = [row[0] for row in res.fetchall()]
    
    if not dates:
        return
    
    # Calculate current streak
    streak = 0
    current_date = date.today()
    
    for i, txn_date in enumerate(dates):
        expected_date = current_date - timedelta(days=i)
        if txn_date == expected_date:
            streak += 1
        else:
            break
    
    # Award streak badges
    if streak >= 7:
        await _award_badge(db, user_id, "WEEK_STREAK_7")
    if streak >= 30:
        await _award_badge(db, user_id, "MONTH_STREAK_30")


async def _check_savings_badges(db: AsyncSession, user_id: str, amount_cents: int):
    """Check for savings goal achievements."""
    if amount_cents >= 10000:  # $100
        await _award_badge(db, user_id, "SAVINGS_GOAL_100")
    if amount_cents >= 50000:  # $500
        await _award_badge(db, user_id, "SAVINGS_GOAL_500")
    if amount_cents >= 100000:  # $1000
        await _award_badge(db, user_id, "SAVINGS_GOAL_1000")


async def check_budget_badges(db: AsyncSession, user_id: str):
    """Check for budget-related badges."""
    # Check if user has stayed within all budgets for a month
    res = await db.execute(
        text(
            """
            SELECT COUNT(*) as budget_count
            FROM budgets b
            WHERE b.user_id = :uid
              AND b.period_start <= CURRENT_DATE
              AND b.period_end >= CURRENT_DATE
            """
        ),
        {"uid": user_id},
    )
    budget_count = res.scalar_one() or 0
    
    if budget_count > 0:
        # Check if all budgets are within limits
        res = await db.execute(
            text(
                """
                SELECT 
                    b.category,
                    b.limit_cents,
                    COALESCE(SUM(t.total_cents), 0) as spent_cents
                FROM budgets b
                LEFT JOIN transactions t ON t.user_id = b.user_id 
                  AND t.category = b.category
                  AND t.txn_date BETWEEN b.period_start AND b.period_end
                WHERE b.user_id = :uid
                  AND b.period_start <= CURRENT_DATE
                  AND b.period_end >= CURRENT_DATE
                GROUP BY b.category, b.limit_cents
                HAVING COALESCE(SUM(t.total_cents), 0) <= b.limit_cents
                """
            ),
            {"uid": user_id},
        )
        within_budget_count = len(res.fetchall())
        
        if within_budget_count == budget_count and budget_count > 0:
            await _award_badge(db, user_id, "BUDGET_MASTER")


async def check_spending_milestone_badges(db: AsyncSession, user_id: str):
    """Check for spending milestone badges."""
    # Total transactions milestone
    res = await db.execute(
        text("SELECT COUNT(*) as count FROM transactions WHERE user_id = :uid"),
        {"uid": user_id},
    )
    txn_count = res.scalar_one() or 0
    
    if txn_count >= 100:
        await _award_badge(db, user_id, "TRACKING_100")
    if txn_count >= 500:
        await _award_badge(db, user_id, "TRACKING_500")
    if txn_count >= 1000:
        await _award_badge(db, user_id, "TRACKING_1000")

