-- PostgreSQL schema for SnapBudget
-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()
-- Enums
CREATE TYPE plan_type AS ENUM ('free', 'premium');
CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'past_due');
CREATE TYPE ocr_status AS ENUM ('pending', 'processing', 'done', 'failed');
CREATE TYPE txn_source AS ENUM ('receipt', 'manual', 'import');
CREATE TYPE actor_type AS ENUM ('user', 'system');
CREATE TYPE category AS ENUM (
  'groceries','dining','transport','shopping','entertainment','subscriptions','utilities','health','education','travel','income_adjustment','other'
);

-- Core tables
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  auth_provider text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE profiles (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name text,
  currency_code char(3) NOT NULL DEFAULT 'USD',
  timezone text NOT NULL DEFAULT 'UTC',
  marketing_opt_in boolean NOT NULL DEFAULT false
);

CREATE TABLE subscriptions (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  plan plan_type NOT NULL DEFAULT 'free',
  status subscription_status NOT NULL DEFAULT 'active',
  stripe_customer_id text,
  current_period_end timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  storage_uri text NOT NULL,
  ocr_status ocr_status NOT NULL DEFAULT 'pending',
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  failure_reason text
);

CREATE TABLE transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receipt_id uuid REFERENCES receipts(id) ON DELETE SET NULL,
  merchant text,
  txn_date date NOT NULL,
  total_cents integer NOT NULL CHECK (total_cents >= 0),
  tax_cents integer NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
  tip_cents integer NOT NULL DEFAULT 0 CHECK (tip_cents >= 0),
  currency_code char(3) NOT NULL DEFAULT 'USD',
  category category NOT NULL DEFAULT 'other',
  subcategory text,
  raw_text jsonb,
  source txn_source NOT NULL DEFAULT 'receipt',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE transaction_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  line_index integer NOT NULL,
  description text,
  quantity numeric,
  unit_price_cents integer,
  total_cents integer,
  category category
);

CREATE TABLE budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_start date NOT NULL,
  period_end date NOT NULL,
  category category NOT NULL,
  limit_cents integer NOT NULL CHECK (limit_cents >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, period_start, period_end, category)
);

CREATE TABLE badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  description text
);

CREATE TABLE user_badges (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_id uuid NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  awarded_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);

CREATE TABLE usage_counters (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  month_key char(7) NOT NULL,
  scans_count integer NOT NULL DEFAULT 0,
  last_reset_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, month_key)
);

CREATE TABLE audit_logs (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  actor_type actor_type NOT NULL,
  action text NOT NULL,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_transactions_user_date ON transactions(user_id, txn_date);
CREATE INDEX idx_transactions_user_category_date ON transactions(user_id, category, txn_date);
CREATE INDEX idx_receipts_user_status ON receipts(user_id, ocr_status);
CREATE INDEX idx_budgets_user_period_category ON budgets(user_id, period_start, period_end, category);
CREATE INDEX idx_usage_counters_user_month ON usage_counters(user_id, month_key);


