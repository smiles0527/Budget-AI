-- Auth identities/sessions, savings goals, deal tracking, analytics, plan limits, pg_trgm

-- Extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Auth identities
CREATE TYPE auth_provider AS ENUM ('email','google','apple');

CREATE TABLE identities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider auth_provider NOT NULL,
  provider_user_id text NOT NULL,
  email_verified boolean NOT NULL DEFAULT false,
  password_hash text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_user_id)
);

-- Sessions (refresh-token style)
CREATE TABLE sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash text,
  user_agent text,
  ip inet,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_expires ON sessions(user_id, expires_at DESC);

-- Savings
CREATE TYPE savings_status AS ENUM ('active','paused','achieved','cancelled');

CREATE TABLE savings_goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  category category,
  target_cents integer NOT NULL CHECK (target_cents > 0),
  start_date date NOT NULL DEFAULT CURRENT_DATE,
  target_date date,
  status savings_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE savings_contributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
  amount_cents integer NOT NULL CHECK (amount_cents > 0),
  contributed_at timestamptz NOT NULL DEFAULT now(),
  note text
);

CREATE INDEX IF NOT EXISTS idx_savings_contrib_goal_time ON savings_contributions(goal_id, contributed_at DESC);

-- Deal tracking
CREATE TABLE deal_impressions (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  deal_id uuid NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb
);

CREATE TABLE deal_clicks (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  deal_id uuid NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb
);

CREATE TABLE deal_redemptions (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  deal_id uuid NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb
);

CREATE INDEX IF NOT EXISTS idx_deal_impressions_deal_time ON deal_impressions(deal_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_deal_clicks_deal_time ON deal_clicks(deal_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_deal_redemptions_deal_time ON deal_redemptions(deal_id, occurred_at DESC);

-- Analytics events
CREATE TABLE analytics_events (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  event_name text NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  properties jsonb
);

CREATE INDEX IF NOT EXISTS idx_analytics_user_time ON analytics_events(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_props_gin ON analytics_events USING gin(properties);

-- Merchant trigram index for fuzzy search/matching
CREATE INDEX IF NOT EXISTS idx_transactions_merchant_trgm ON transactions USING gin (merchant gin_trgm_ops);

-- Plan limits (freemium caps)
CREATE TABLE plan_limits (
  plan plan_type PRIMARY KEY,
  monthly_scan_cap integer -- NULL means unlimited
);

INSERT INTO plan_limits(plan, monthly_scan_cap) VALUES
  ('free', 20)
ON CONFLICT (plan) DO NOTHING;

INSERT INTO plan_limits(plan, monthly_scan_cap) VALUES
  ('premium', NULL)
ON CONFLICT (plan) DO NOTHING;

-- Remaining scans helper
CREATE OR REPLACE FUNCTION get_remaining_scans(p_user_id uuid, p_month char(7))
RETURNS integer AS $$
DECLARE
  v_plan plan_type;
  v_cap integer;
  v_used integer := 0;
BEGIN
  SELECT s.plan INTO v_plan FROM subscriptions s WHERE s.user_id = p_user_id;
  IF v_plan IS NULL THEN
    v_plan := 'free';
  END IF;

  SELECT monthly_scan_cap INTO v_cap FROM plan_limits WHERE plan = v_plan;
  IF v_cap IS NULL THEN
    RETURN NULL; -- unlimited
  END IF;

  SELECT scans_count INTO v_used FROM usage_counters
  WHERE user_id = p_user_id AND month_key = p_month;
  IF v_used IS NULL THEN
    v_used := 0;
  END IF;

  RETURN GREATEST(v_cap - v_used, 0);
END;
$$ LANGUAGE plpgsql STABLE;


