yes-- Rules, webhooks, and job tracking tables

-- Enums
CREATE TYPE rule_scope AS ENUM ('merchant', 'line_item', 'both');
CREATE TYPE webhook_status AS ENUM ('pending','processed','failed');
CREATE TYPE job_status AS ENUM ('pending','processing','done','failed');
CREATE TYPE export_status AS ENUM ('pending','processing','done','failed');

-- Categorization rules
CREATE TABLE merchant_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_pattern text NOT NULL, -- simple substring or regex (app logic decides)
  category category NOT NULL,
  confidence numeric(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE keyword_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  keyword text NOT NULL,
  scope rule_scope NOT NULL DEFAULT 'both',
  category category NOT NULL,
  confidence numeric(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_merchant_rules_active ON merchant_rules(active);
CREATE INDEX IF NOT EXISTS idx_keyword_rules_active ON keyword_rules(active);

-- Webhook events (Stripe etc.)
CREATE TABLE webhook_events (
  id bigserial PRIMARY KEY,
  provider text NOT NULL DEFAULT 'stripe',
  event_id text UNIQUE NOT NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  status webhook_status NOT NULL DEFAULT 'pending',
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  error text
);

-- Subscription history
CREATE TABLE subscription_history (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  previous_plan plan_type,
  new_plan plan_type NOT NULL,
  source text,
  changed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscription_history_user ON subscription_history(user_id, changed_at DESC);

-- Export jobs for CSV
CREATE TABLE export_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_date date NOT NULL,
  to_date date NOT NULL,
  status export_status NOT NULL DEFAULT 'pending',
  storage_uri text,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  failure_reason text
);

CREATE INDEX IF NOT EXISTS idx_export_jobs_user_status ON export_jobs(user_id, status);

-- Receipt processing jobs (OCR pipeline bookkeeping)
CREATE TABLE receipt_processing_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id uuid NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  status job_status NOT NULL DEFAULT 'pending',
  attempts integer NOT NULL DEFAULT 0,
  started_at timestamptz,
  completed_at timestamptz,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_receipt_jobs_receipt_status ON receipt_processing_jobs(receipt_id, status);


