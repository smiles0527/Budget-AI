-- Sponsors, affiliates, licensing, privacy deletion, monthly aggregates

-- Sponsors and deals (Smart Savings Spots)
CREATE TABLE sponsors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  website text,
  logo_uri text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sponsor_id uuid NOT NULL REFERENCES sponsors(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  category category,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  redemption_url text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_deals_active_time ON deals(active, starts_at, ends_at);

-- Affiliate referrals
CREATE TABLE affiliates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  program text NOT NULL, -- e.g. bank, card, fintech
  referral_fee_cents integer,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  affiliate_id uuid NOT NULL REFERENCES affiliates(id) ON DELETE CASCADE,
  offer_code text,
  status text NOT NULL DEFAULT 'clicked', -- clicked, applied, approved, paid
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_referrals_user_status ON referrals(user_id, status);

-- Educational licensing
CREATE TABLE institutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL DEFAULT 'school',
  website text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE institution_licenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id uuid NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
  seats integer NOT NULL CHECK (seats > 0),
  starts_at date NOT NULL,
  ends_at date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE institution_users (
  institution_id uuid NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (institution_id, user_id)
);

-- Privacy deletion job (GDPR/CCPA)
CREATE TYPE deletion_status AS ENUM ('scheduled','processing','done','failed');

CREATE TABLE deletion_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status deletion_status NOT NULL DEFAULT 'scheduled',
  requested_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  error text
);

-- Monthly aggregated insights (materialized view)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_user_category AS
SELECT
  user_id,
  to_char(txn_date, 'YYYY-MM') AS month_key,
  category,
  SUM(total_cents) AS total_cents,
  COUNT(*) AS txn_count
FROM transactions
GROUP BY user_id, to_char(txn_date, 'YYYY-MM'), category;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_muc_unique ON mv_monthly_user_category(user_id, month_key, category);

CREATE OR REPLACE FUNCTION refresh_monthly_insights(p_user_id uuid, p_month char(7)) RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_user_category;
END;
$$ LANGUAGE plpgsql;


