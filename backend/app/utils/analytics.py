"""
Advanced analytics and insights utilities.
"""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date, timedelta
from typing import Dict, List, Optional
import statistics


async def get_spending_trends(db: AsyncSession, user_id: str, months: int = 6) -> Dict:
    """Get month-over-month spending trends."""
    end_date = date.today()
    start_date = end_date - timedelta(days=months * 30)
    
    res = await db.execute(
        text(
            """
            SELECT 
                to_char(txn_date, 'YYYY-MM') as month_key,
                SUM(total_cents) as total_cents,
                COUNT(*) as txn_count,
                AVG(total_cents) as avg_txn_cents
            FROM transactions
            WHERE user_id = :uid AND txn_date >= :start
            GROUP BY to_char(txn_date, 'YYYY-MM')
            ORDER BY month_key
            """
        ),
        {"uid": user_id, "start": start_date},
    )
    
    months_data = {}
    for row in res.mappings().all():
        months_data[row["month_key"]] = {
            "total_cents": row["total_cents"] or 0,
            "txn_count": row["txn_count"] or 0,
            "avg_txn_cents": float(row["avg_txn_cents"] or 0),
        }
    
    # Calculate trend
    values = [m["total_cents"] for m in months_data.values()]
    trend = "stable"
    if len(values) >= 2:
        recent_avg = statistics.mean(values[-3:]) if len(values) >= 3 else values[-1]
        older_avg = statistics.mean(values[:-3]) if len(values) > 3 else values[0]
        if recent_avg > older_avg * 1.1:
            trend = "increasing"
        elif recent_avg < older_avg * 0.9:
            trend = "decreasing"
    
    return {
        "months": months_data,
        "trend": trend,
        "period_months": months,
    }


async def detect_recurring_transactions(db: AsyncSession, user_id: str) -> List[Dict]:
    """Detect potentially recurring transactions based on merchant and amount patterns."""
    res = await db.execute(
        text(
            """
            SELECT 
                merchant,
                category,
                total_cents,
                COUNT(*) as occurrence_count,
                MIN(txn_date) as first_seen,
                MAX(txn_date) as last_seen,
                AVG(EXTRACT(EPOCH FROM (txn_date - LAG(txn_date) OVER (PARTITION BY merchant, total_cents ORDER BY txn_date)))) / 86400 as avg_days_between
            FROM transactions
            WHERE user_id = :uid 
              AND merchant IS NOT NULL
              AND txn_date >= CURRENT_DATE - INTERVAL '6 months'
            GROUP BY merchant, category, total_cents
            HAVING COUNT(*) >= 3
            ORDER BY occurrence_count DESC
            LIMIT 20
            """
        ),
        {"uid": user_id},
    )
    
    recurring = []
    for row in res.mappings().all():
        if row["occurrence_count"] >= 3:
            recurring.append({
                "merchant": row["merchant"],
                "category": row["category"],
                "amount_cents": row["total_cents"],
                "frequency": row["occurrence_count"],
                "first_seen": row["first_seen"].isoformat() if row["first_seen"] else None,
                "last_seen": row["last_seen"].isoformat() if row["last_seen"] else None,
                "estimated_interval_days": int(row["avg_days_between"] or 30) if row["avg_days_between"] else None,
            })
    
    return recurring


async def get_spending_forecast(db: AsyncSession, user_id: str, months_ahead: int = 1) -> Dict:
    """Forecast spending for next N months based on historical data."""
    # Get last 6 months of data
    end_date = date.today()
    start_date = end_date - timedelta(days=180)
    
    res = await db.execute(
        text(
            """
            SELECT 
                to_char(txn_date, 'YYYY-MM') as month_key,
                SUM(total_cents) as total_cents
            FROM transactions
            WHERE user_id = :uid AND txn_date >= :start
            GROUP BY to_char(txn_date, 'YYYY-MM')
            ORDER BY month_key
            """
        ),
        {"uid": user_id, "start": start_date},
    )
    
    monthly_totals = [row["total_cents"] or 0 for row in res.mappings().all()]
    
    if not monthly_totals:
        return {"forecast_cents": 0, "confidence": "low", "method": "insufficient_data"}
    
    # Simple moving average forecast
    if len(monthly_totals) >= 3:
        avg = statistics.mean(monthly_totals[-3:])
        confidence = "high" if len(monthly_totals) >= 6 else "medium"
    else:
        avg = statistics.mean(monthly_totals) if monthly_totals else 0
        confidence = "low"
    
    forecast = int(avg * months_ahead)
    
    return {
        "forecast_cents": forecast,
        "forecast_per_month_cents": int(avg),
        "confidence": confidence,
        "method": "moving_average",
        "months_ahead": months_ahead,
        "based_on_months": len(monthly_totals),
    }


async def get_spending_insights(db: AsyncSession, user_id: str) -> Dict:
    """Generate actionable spending insights and recommendations."""
    insights = []
    
    # Get current month spending
    current_month_start = date.today().replace(day=1)
    current_month_res = await db.execute(
        text(
            """
            SELECT 
                category,
                SUM(total_cents) as total_cents,
                COUNT(*) as txn_count
            FROM transactions
            WHERE user_id = :uid 
              AND txn_date >= :start
            GROUP BY category
            ORDER BY total_cents DESC
            """
        ),
        {"uid": user_id, "start": current_month_start},
    )
    
    current_month_by_category = {row["category"]: row["total_cents"] or 0 for row in current_month_res.mappings().all()}
    current_month_total = sum(current_month_by_category.values())
    
    # Get last month for comparison
    last_month_start = (current_month_start - timedelta(days=1)).replace(day=1)
    last_month_end = current_month_start - timedelta(days=1)
    last_month_res = await db.execute(
        text(
            """
            SELECT SUM(total_cents) as total_cents
            FROM transactions
            WHERE user_id = :uid 
              AND txn_date >= :start AND txn_date <= :end
            """
        ),
        {"uid": user_id, "start": last_month_start, "end": last_month_end},
    )
    last_month_total = last_month_res.scalar_one() or 0
    
    # Insight 1: Spending increase/decrease
    if last_month_total > 0:
        change_pct = ((current_month_total - last_month_total) / last_month_total) * 100
        if change_pct > 20:
            insights.append({
                "type": "spending_increase",
                "severity": "warning",
                "message": f"Your spending is {change_pct:.1f}% higher than last month",
                "recommendation": "Review your recent transactions and consider setting stricter budgets",
            })
        elif change_pct < -20:
            insights.append({
                "type": "spending_decrease",
                "severity": "positive",
                "message": f"Great job! Your spending is {abs(change_pct):.1f}% lower than last month",
                "recommendation": "Keep up the good work! Consider allocating the savings to a goal",
            })
    
    # Insight 2: Top spending category
    if current_month_by_category:
        top_category = max(current_month_by_category.items(), key=lambda x: x[1])
        top_pct = (top_category[1] / current_month_total * 100) if current_month_total > 0 else 0
        if top_pct > 40:
            insights.append({
                "type": "category_concentration",
                "severity": "info",
                "message": f"{top_category[0].title()} accounts for {top_pct:.1f}% of your spending this month",
                "recommendation": f"Consider diversifying your spending or setting a budget for {top_category[0]}",
            })
    
    # Insight 3: Check budgets
    budget_res = await db.execute(
        text(
            """
            SELECT category, limit_cents, period_start, period_end
            FROM budgets
            WHERE user_id = :uid
              AND period_start <= CURRENT_DATE
              AND period_end >= CURRENT_DATE
            """
        ),
        {"uid": user_id},
    )
    
    for budget_row in budget_res.mappings().all():
        category = budget_row["category"]
        limit_cents = budget_row["limit_cents"]
        spent = current_month_by_category.get(category, 0)
        pct_used = (spent / limit_cents * 100) if limit_cents > 0 else 0
        
        if pct_used >= 90:
            insights.append({
                "type": "budget_warning",
                "severity": "warning",
                "message": f"You've used {pct_used:.1f}% of your {category} budget",
                "recommendation": "Consider reducing spending in this category or adjusting your budget",
            })
        elif pct_used >= 100:
            insights.append({
                "type": "budget_exceeded",
                "severity": "critical",
                "message": f"You've exceeded your {category} budget by {((spent - limit_cents) / limit_cents * 100):.1f}%",
                "recommendation": "Immediately reduce spending in this category",
            })
    
    # Insight 4: Recurring subscriptions
    recurring = await detect_recurring_transactions(db, user_id)
    subscription_recurring = [r for r in recurring if r["category"] == "subscriptions"]
    if subscription_recurring:
        total_sub = sum(r["amount_cents"] for r in subscription_recurring)
        insights.append({
            "type": "subscription_insight",
            "severity": "info",
            "message": f"You have {len(subscription_recurring)} recurring subscriptions totaling ${total_sub/100:.2f}/month",
            "recommendation": "Review your subscriptions regularly and cancel unused ones",
        })
    
    return {
        "insights": insights,
        "current_month_total_cents": current_month_total,
        "last_month_total_cents": last_month_total,
        "generated_at": date.today().isoformat(),
    }


async def get_category_comparison(db: AsyncSession, user_id: str, period1_start: date, period1_end: date, period2_start: date, period2_end: date) -> Dict:
    """Compare spending between two periods by category."""
    # Period 1
    p1_res = await db.execute(
        text(
            """
            SELECT category, SUM(total_cents) as total_cents, COUNT(*) as txn_count
            FROM transactions
            WHERE user_id = :uid AND txn_date BETWEEN :start AND :end
            GROUP BY category
            """
        ),
        {"uid": user_id, "start": period1_start, "end": period1_end},
    )
    p1_data = {row["category"]: {"total_cents": row["total_cents"] or 0, "txn_count": row["txn_count"] or 0} for row in p1_res.mappings().all()}
    
    # Period 2
    p2_res = await db.execute(
        text(
            """
            SELECT category, SUM(total_cents) as total_cents, COUNT(*) as txn_count
            FROM transactions
            WHERE user_id = :uid AND txn_date BETWEEN :start AND :end
            GROUP BY category
            """
        ),
        {"uid": user_id, "start": period2_start, "end": period2_end},
    )
    p2_data = {row["category"]: {"total_cents": row["total_cents"] or 0, "txn_count": row["txn_count"] or 0} for row in p2_res.mappings().all()}
    
    # Compare
    all_categories = set(p1_data.keys()) | set(p2_data.keys())
    comparison = []
    
    for cat in all_categories:
        p1 = p1_data.get(cat, {"total_cents": 0, "txn_count": 0})
        p2 = p2_data.get(cat, {"total_cents": 0, "txn_count": 0})
        
        change_cents = p2["total_cents"] - p1["total_cents"]
        change_pct = (change_cents / p1["total_cents"] * 100) if p1["total_cents"] > 0 else (100 if p2["total_cents"] > 0 else 0)
        
        comparison.append({
            "category": cat,
            "period1_cents": p1["total_cents"],
            "period2_cents": p2["total_cents"],
            "change_cents": change_cents,
            "change_percent": change_pct,
            "period1_txn_count": p1["txn_count"],
            "period2_txn_count": p2["txn_count"],
        })
    
    return {
        "period1": {"start": period1_start.isoformat(), "end": period1_end.isoformat()},
        "period2": {"start": period2_start.isoformat(), "end": period2_end.isoformat()},
        "comparison": sorted(comparison, key=lambda x: abs(x["change_cents"]), reverse=True),
    }

