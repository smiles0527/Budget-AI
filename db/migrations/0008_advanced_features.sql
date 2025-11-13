-- Advanced features: transaction tags, budget alerts, search improvements

-- Transaction tags for custom organization
CREATE TABLE transaction_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  color text, -- hex color code
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

CREATE TABLE transaction_tag_assignments (
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES transaction_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (transaction_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_transaction_tags_user ON transaction_tags(user_id);
CREATE INDEX IF NOT EXISTS idx_tag_assignments_tag ON transaction_tag_assignments(tag_id);
CREATE INDEX IF NOT EXISTS idx_tag_assignments_txn ON transaction_tag_assignments(transaction_id);

-- Budget alerts
CREATE TYPE alert_type AS ENUM ('budget_warning', 'budget_exceeded', 'spending_spike', 'recurring_detected');
CREATE TYPE alert_status AS ENUM ('active', 'dismissed', 'resolved');

CREATE TABLE budget_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  alert_type alert_type NOT NULL,
  budget_id uuid REFERENCES budgets(id) ON DELETE CASCADE,
  category category,
  message text NOT NULL,
  status alert_status NOT NULL DEFAULT 'active',
  threshold_cents integer,
  current_cents integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  dismissed_at timestamptz,
  resolved_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_budget_alerts_user_status ON budget_alerts(user_id, status, created_at DESC);

-- Full-text search index for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_merchant_text ON transactions USING gin(to_tsvector('english', COALESCE(merchant, '')));
CREATE INDEX IF NOT EXISTS idx_transactions_search ON transactions USING gin(
  to_tsvector('english', 
    COALESCE(merchant, '') || ' ' || 
    COALESCE(subcategory, '') || ' ' ||
    COALESCE(category::text, '')
  )
);

-- Recurring transaction tracking
CREATE TABLE recurring_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  merchant text NOT NULL,
  category category,
  amount_cents integer NOT NULL,
  estimated_interval_days integer,
  last_seen_date date NOT NULL,
  occurrence_count integer NOT NULL DEFAULT 1,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recurring_user_active ON recurring_transactions(user_id, is_active);

-- Spending insights cache (optional, for performance)
CREATE TABLE spending_insights_cache (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  insights_json jsonb NOT NULL,
  generated_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_insights_cache_expires ON spending_insights_cache(expires_at);

