-- Additional checks, functions, triggers, and indexes

-- Ensure budget period is valid
ALTER TABLE budgets
  ADD CONSTRAINT chk_budget_period
  CHECK (period_end >= period_start);

-- Month key helper (YYYY-MM)
CREATE OR REPLACE FUNCTION derive_month_key(ts timestamptz)
RETURNS char(7)
LANGUAGE sql IMMUTABLE AS $$
  to_char(ts AT TIME ZONE 'UTC', 'YYYY-MM')
$$;

-- Increment usage counter when a receipt is uploaded
CREATE OR REPLACE FUNCTION increment_scans_count() RETURNS trigger AS $$
BEGIN
  INSERT INTO usage_counters(user_id, month_key, scans_count, last_reset_at)
  VALUES (NEW.user_id, derive_month_key(NEW.uploaded_at), 1, now())
  ON CONFLICT (user_id, month_key) DO UPDATE
    SET scans_count = usage_counters.scans_count + 1,
        last_reset_at = GREATEST(usage_counters.last_reset_at, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_receipts_increment_scans ON receipts;
CREATE TRIGGER tr_receipts_increment_scans
AFTER INSERT ON receipts
FOR EACH ROW EXECUTE FUNCTION increment_scans_count();

-- Dashboard helpers
-- Summary over a date range
CREATE OR REPLACE FUNCTION get_dashboard_summary(
  p_user_id uuid,
  p_start date,
  p_end date
) RETURNS TABLE (
  total_spend_cents bigint,
  txn_count bigint,
  avg_txn_cents numeric,
  start_date date,
  end_date date
) AS $$
  SELECT
    COALESCE(SUM(t.total_cents), 0) AS total_spend_cents,
    COUNT(*) AS txn_count,
    CASE WHEN COUNT(*) > 0 THEN ROUND(AVG(t.total_cents)::numeric, 2) ELSE 0 END AS avg_txn_cents,
    p_start AS start_date,
    p_end AS end_date
  FROM transactions t
  WHERE t.user_id = p_user_id
    AND t.txn_date BETWEEN p_start AND p_end;
$$ LANGUAGE sql STABLE;

-- Category breakdown over a date range
CREATE OR REPLACE FUNCTION get_dashboard_categories(
  p_user_id uuid,
  p_start date,
  p_end date
) RETURNS TABLE (
  category category,
  total_spend_cents bigint,
  txn_count bigint
) AS $$
  SELECT
    t.category,
    COALESCE(SUM(t.total_cents), 0) AS total_spend_cents,
    COUNT(*) AS txn_count
  FROM transactions t
  WHERE t.user_id = p_user_id
    AND t.txn_date BETWEEN p_start AND p_end
  GROUP BY t.category
  ORDER BY total_spend_cents DESC;
$$ LANGUAGE sql STABLE;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_transactions_receipt_id ON transactions(receipt_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_created_at ON transactions(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_raw_text_gin ON transactions USING gin(raw_text);
CREATE INDEX IF NOT EXISTS idx_audit_logs_metadata_gin ON audit_logs USING gin(metadata);


