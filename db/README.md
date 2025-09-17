# Database Setup (PostgreSQL)

This directory contains the PostgreSQL schema and migrations for the app.

## Prerequisites
- Docker Desktop (Windows)

## 1) Start Postgres
```powershell
# From repo root
docker compose up -d db
```

Defaults (override with environment variables when starting compose):
- POSTGRES_USER=app
- POSTGRES_PASSWORD=password
- POSTGRES_DB=appdb
- POSTGRES_PORT=5432

## 2) Apply migrations
Option A: Use the helper script
```powershell
# From repo root
./db/apply-migrations.ps1
```

Option B: Manual inside the container
```powershell
# Copy migrations into the container, then apply in order
Get-ChildItem -Path "db/migrations" -Filter *.sql | Sort-Object Name | ForEach-Object {
  docker cp $_.FullName snapbudget-postgres:/migrations/$($_.Name)
  docker exec -i snapbudget-postgres psql -U app -d appdb -v ON_ERROR_STOP=1 -f "/migrations/$($_.Name)"
}
```

## 3) Verify
```powershell
docker exec -it snapbudget-postgres psql -U app -d appdb -c "\\dt"
```

## Teardown
```powershell
docker compose down -v
```

## Notes
- Extensions: pgcrypto (UUIDs), pg_trgm (fuzzy search)
- Core tables: users, profiles, subscriptions (+Stripe fields), receipts, transactions, transaction_items, budgets, badges, user_badges, usage_counters, audit_logs
- Auth: identities, sessions
- Savings: savings_goals, savings_contributions
- Growth/monetization: sponsors, deals, impressions/clicks/redemptions, affiliates, referrals
- Education: institutions, institution_licenses, institution_users
- Integrations: webhook_events, subscription_history, export_jobs, receipt_processing_jobs, bank_import_runs
- Linked accounts: linked_accounts, account_balances (Plaid/TrueLayer/etc.)
- Push notifications: push_devices (APNs/FCM)
- Analytics: analytics_events (JSONB), materialized views `mv_monthly_user_category`, `mv_global_monthly_category`
- Functions: derive_month_key, increment_scans_count (trigger), get_dashboard_summary, get_dashboard_categories, refresh_monthly_insights, refresh_global_insights, get_remaining_scans
- Indexes: JSONB GIN, trigram on transactions.merchant, and composite indexes for common queries
