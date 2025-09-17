-- Push device tokens, linked bank accounts, global insights, Stripe fields

-- Push devices
CREATE TYPE push_platform AS ENUM ('apns','fcm');

CREATE TABLE push_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform push_platform NOT NULL,
  token text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_push_devices_user_platform_token
  ON push_devices(user_id, platform, token);

-- Linked financial accounts (Plaid/TrueLayer/etc.)
CREATE TYPE link_provider AS ENUM ('plaid','truelayer','mx','finicity','stripe_financial_connections','custom');
CREATE TYPE link_status AS ENUM ('active','revoked','error');

CREATE TABLE linked_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider link_provider NOT NULL,
  provider_account_id text NOT NULL,
  institution_name text,
  account_mask text,
  account_name text,
  account_type text,
  account_subtype text,
  status link_status NOT NULL DEFAULT 'active',
  last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_account_id)
);

CREATE TABLE account_balances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  linked_account_id uuid NOT NULL REFERENCES linked_accounts(id) ON DELETE CASCADE,
  current_cents integer,
  available_cents integer,
  currency_code char(3) NOT NULL DEFAULT 'USD',
  as_of timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_account_balances_account_time
  ON account_balances(linked_account_id, as_of DESC);

-- Import runs for bank syncs
CREATE TABLE bank_import_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  linked_account_id uuid NOT NULL REFERENCES linked_accounts(id) ON DELETE CASCADE,
  from_date date,
  to_date date,
  status job_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  completed_at timestamptz,
  error text
);

CREATE INDEX IF NOT EXISTS idx_bank_import_runs_status ON bank_import_runs(status, created_at DESC);

-- Extend subscriptions with Stripe fields
ALTER TABLE subscriptions
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text,
  ADD COLUMN IF NOT EXISTS stripe_price_id text,
  ADD COLUMN IF NOT EXISTS cancel_at_period_end boolean NOT NULL DEFAULT false;

-- Global anonymized monthly insights
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_global_monthly_category AS
SELECT
  to_char(txn_date, 'YYYY-MM') AS month_key,
  category,
  SUM(total_cents) AS total_cents,
  COUNT(*) AS txn_count,
  ROUND(AVG(total_cents)::numeric, 2) AS avg_txn_cents,
  COUNT(DISTINCT user_id) AS users_count
FROM transactions
GROUP BY to_char(txn_date, 'YYYY-MM'), category;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_global_month_cat
  ON mv_global_monthly_category(month_key, category);

CREATE OR REPLACE FUNCTION refresh_global_insights() RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_global_monthly_category;
END;
$$ LANGUAGE plpgsql;


