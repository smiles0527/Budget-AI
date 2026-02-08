-- Seed demo data for admin account
-- This populates the admin@admin.com account with realistic sample data
-- for testing and demonstration purposes

-- First, get the admin user ID (created via API with email admin@admin.com)
DO $$
DECLARE
  admin_id uuid;
  receipt_id_1 uuid;
  receipt_id_2 uuid;
  receipt_id_3 uuid;
  receipt_id_4 uuid;
  receipt_id_5 uuid;
  txn_id uuid;
  goal_id_1 uuid;
  goal_id_2 uuid;
  goal_id_3 uuid;
  badge_id uuid;
  current_month char(7);
BEGIN
  -- Get admin user ID
  SELECT id INTO admin_id FROM users WHERE email = 'admin@admin.com';
  
  IF admin_id IS NULL THEN
    RAISE NOTICE 'Admin user not found. Skipping demo data seed.';
    RETURN;
  END IF;

  current_month := to_char(CURRENT_DATE, 'YYYY-MM');

  -- ============================================
  -- PROFILE - Update with display name
  -- ============================================
  UPDATE profiles 
  SET display_name = 'Demo Admin', 
      currency_code = 'USD',
      timezone = 'America/New_York'
  WHERE user_id = admin_id;

  -- ============================================
  -- RECEIPTS - Create 5 sample receipts
  -- ============================================
  receipt_id_1 := gen_random_uuid();
  receipt_id_2 := gen_random_uuid();
  receipt_id_3 := gen_random_uuid();
  receipt_id_4 := gen_random_uuid();
  receipt_id_5 := gen_random_uuid();

  INSERT INTO receipts (id, user_id, storage_uri, ocr_status, uploaded_at, processed_at) VALUES
    (receipt_id_1, admin_id, 's3://receipts/demo/receipt_001.jpg', 'done', now() - interval '2 days', now() - interval '2 days'),
    (receipt_id_2, admin_id, 's3://receipts/demo/receipt_002.jpg', 'done', now() - interval '5 days', now() - interval '5 days'),
    (receipt_id_3, admin_id, 's3://receipts/demo/receipt_003.jpg', 'done', now() - interval '8 days', now() - interval '8 days'),
    (receipt_id_4, admin_id, 's3://receipts/demo/receipt_004.jpg', 'done', now() - interval '12 days', now() - interval '12 days'),
    (receipt_id_5, admin_id, 's3://receipts/demo/receipt_005.jpg', 'done', now() - interval '15 days', now() - interval '15 days')
  ON CONFLICT DO NOTHING;

  -- ============================================
  -- TRANSACTIONS - Comprehensive sample data
  -- ============================================
  
  -- Groceries transactions
  INSERT INTO transactions (user_id, receipt_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, receipt_id_1, 'Whole Foods Market', CURRENT_DATE - 2, 8547, 685, 'groceries', 'receipt', now() - interval '2 days'),
    (admin_id, receipt_id_3, 'Trader Joe''s', CURRENT_DATE - 8, 6234, 499, 'groceries', 'receipt', now() - interval '8 days'),
    (admin_id, NULL, 'Costco', CURRENT_DATE - 14, 15678, 1254, 'groceries', 'manual', now() - interval '14 days'),
    (admin_id, NULL, 'Safeway', CURRENT_DATE - 21, 4523, 362, 'groceries', 'manual', now() - interval '21 days'),
    (admin_id, NULL, 'Kroger', CURRENT_DATE - 28, 7890, 631, 'groceries', 'manual', now() - interval '28 days');

  -- Dining transactions
  INSERT INTO transactions (user_id, receipt_id, merchant, txn_date, total_cents, tax_cents, tip_cents, category, source, created_at) VALUES
    (admin_id, receipt_id_2, 'Chipotle', CURRENT_DATE - 5, 1456, 116, 0, 'dining', 'receipt', now() - interval '5 days'),
    (admin_id, NULL, 'Olive Garden', CURRENT_DATE - 10, 6789, 543, 1200, 'dining', 'manual', now() - interval '10 days'),
    (admin_id, NULL, 'Starbucks', CURRENT_DATE - 3, 875, 70, 0, 'dining', 'manual', now() - interval '3 days'),
    (admin_id, NULL, 'Panera Bread', CURRENT_DATE - 7, 1234, 99, 0, 'dining', 'manual', now() - interval '7 days'),
    (admin_id, NULL, 'The Cheesecake Factory', CURRENT_DATE - 18, 8956, 717, 1500, 'dining', 'manual', now() - interval '18 days');

  -- Transport transactions
  INSERT INTO transactions (user_id, receipt_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, receipt_id_4, 'Shell Gas Station', CURRENT_DATE - 12, 5234, 0, 'transport', 'receipt', now() - interval '12 days'),
    (admin_id, NULL, 'Uber', CURRENT_DATE - 4, 2345, 0, 'transport', 'manual', now() - interval '4 days'),
    (admin_id, NULL, 'Lyft', CURRENT_DATE - 9, 1876, 0, 'transport', 'manual', now() - interval '9 days'),
    (admin_id, NULL, 'BP Gas', CURRENT_DATE - 20, 4567, 0, 'transport', 'manual', now() - interval '20 days');

  -- Shopping transactions
  INSERT INTO transactions (user_id, receipt_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, receipt_id_5, 'Target', CURRENT_DATE - 15, 12345, 988, 'shopping', 'receipt', now() - interval '15 days'),
    (admin_id, NULL, 'Amazon', CURRENT_DATE - 6, 4999, 400, 'shopping', 'manual', now() - interval '6 days'),
    (admin_id, NULL, 'Best Buy', CURRENT_DATE - 11, 29999, 2400, 'shopping', 'manual', now() - interval '11 days'),
    (admin_id, NULL, 'IKEA', CURRENT_DATE - 25, 18765, 1501, 'shopping', 'manual', now() - interval '25 days');

  -- Entertainment transactions
  INSERT INTO transactions (user_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, 'AMC Theatres', CURRENT_DATE - 13, 3456, 276, 'entertainment', 'manual', now() - interval '13 days'),
    (admin_id, 'Spotify', CURRENT_DATE - 1, 1099, 0, 'entertainment', 'manual', now() - interval '1 day'),
    (admin_id, 'Netflix', CURRENT_DATE - 1, 1599, 0, 'entertainment', 'manual', now() - interval '1 day'),
    (admin_id, 'Steam', CURRENT_DATE - 16, 5999, 0, 'entertainment', 'manual', now() - interval '16 days');

  -- Subscriptions
  INSERT INTO transactions (user_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, 'Adobe Creative Cloud', CURRENT_DATE - 1, 5499, 0, 'subscriptions', 'manual', now() - interval '1 day'),
    (admin_id, 'iCloud Storage', CURRENT_DATE - 1, 299, 0, 'subscriptions', 'manual', now() - interval '1 day'),
    (admin_id, 'Gym Membership', CURRENT_DATE - 1, 4999, 0, 'subscriptions', 'manual', now() - interval '1 day');

  -- Utilities
  INSERT INTO transactions (user_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, 'Electric Company', CURRENT_DATE - 5, 12456, 0, 'utilities', 'manual', now() - interval '5 days'),
    (admin_id, 'Water Utility', CURRENT_DATE - 5, 4523, 0, 'utilities', 'manual', now() - interval '5 days'),
    (admin_id, 'Internet Provider', CURRENT_DATE - 5, 7999, 0, 'utilities', 'manual', now() - interval '5 days');

  -- Health
  INSERT INTO transactions (user_id, merchant, txn_date, total_cents, tax_cents, category, source, created_at) VALUES
    (admin_id, 'CVS Pharmacy', CURRENT_DATE - 7, 2345, 188, 'health', 'manual', now() - interval '7 days'),
    (admin_id, 'Walgreens', CURRENT_DATE - 19, 1567, 125, 'health', 'manual', now() - interval '19 days');

  -- ============================================
  -- BUDGETS - Monthly budgets for current month
  -- ============================================
  INSERT INTO budgets (user_id, period_start, period_end, category, limit_cents) VALUES
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'groceries', 60000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'dining', 30000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'transport', 20000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'shopping', 50000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'entertainment', 15000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'subscriptions', 15000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'utilities', 30000),
    (admin_id, date_trunc('month', CURRENT_DATE)::date, (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date, 'health', 10000)
  ON CONFLICT (user_id, period_start, period_end, category) DO UPDATE SET limit_cents = EXCLUDED.limit_cents;

  -- ============================================
  -- SAVINGS GOALS - 3 active goals
  -- ============================================
  goal_id_1 := gen_random_uuid();
  goal_id_2 := gen_random_uuid();
  goal_id_3 := gen_random_uuid();

  INSERT INTO savings_goals (id, user_id, name, category, target_cents, start_date, target_date, status) VALUES
    (goal_id_1, admin_id, 'Emergency Fund', NULL, 500000, CURRENT_DATE - 60, CURRENT_DATE + 120, 'active'),
    (goal_id_2, admin_id, 'New MacBook Pro', 'shopping', 250000, CURRENT_DATE - 30, CURRENT_DATE + 90, 'active'),
    (goal_id_3, admin_id, 'Vacation to Japan', 'travel', 400000, CURRENT_DATE - 90, CURRENT_DATE + 180, 'active')
  ON CONFLICT DO NOTHING;

  -- Savings contributions
  INSERT INTO savings_contributions (goal_id, amount_cents, contributed_at, note) VALUES
    -- Emergency Fund contributions
    (goal_id_1, 50000, now() - interval '55 days', 'First deposit'),
    (goal_id_1, 25000, now() - interval '45 days', 'Bonus from work'),
    (goal_id_1, 30000, now() - interval '35 days', 'Monthly contribution'),
    (goal_id_1, 30000, now() - interval '25 days', 'Monthly contribution'),
    (goal_id_1, 35000, now() - interval '15 days', 'Extra savings'),
    (goal_id_1, 30000, now() - interval '5 days', 'Monthly contribution'),
    -- MacBook Pro contributions
    (goal_id_2, 40000, now() - interval '28 days', 'Initial savings'),
    (goal_id_2, 30000, now() - interval '18 days', 'Side gig income'),
    (goal_id_2, 25000, now() - interval '8 days', 'Sold old laptop'),
    -- Japan Vacation contributions
    (goal_id_3, 25000, now() - interval '85 days', 'Started saving!'),
    (goal_id_3, 20000, now() - interval '75 days', 'Monthly'),
    (goal_id_3, 20000, now() - interval '65 days', 'Monthly'),
    (goal_id_3, 25000, now() - interval '55 days', 'Birthday money'),
    (goal_id_3, 20000, now() - interval '45 days', 'Monthly'),
    (goal_id_3, 30000, now() - interval '35 days', 'Tax refund'),
    (goal_id_3, 20000, now() - interval '25 days', 'Monthly'),
    (goal_id_3, 20000, now() - interval '15 days', 'Monthly'),
    (goal_id_3, 25000, now() - interval '5 days', 'Extra contribution');

  -- ============================================
  -- BADGES - Award some badges to admin
  -- ============================================
  -- First Scan badge
  SELECT id INTO badge_id FROM badges WHERE code = 'FIRST_SCAN';
  IF badge_id IS NOT NULL THEN
    INSERT INTO user_badges (user_id, badge_id, awarded_at) 
    VALUES (admin_id, badge_id, now() - interval '30 days')
    ON CONFLICT DO NOTHING;
  END IF;

  -- 7-Day Streak badge
  SELECT id INTO badge_id FROM badges WHERE code = 'WEEK_STREAK_7';
  IF badge_id IS NOT NULL THEN
    INSERT INTO user_badges (user_id, badge_id, awarded_at) 
    VALUES (admin_id, badge_id, now() - interval '20 days')
    ON CONFLICT DO NOTHING;
  END IF;

  -- Century Club (100 transactions) - let's say they've been busy
  SELECT id INTO badge_id FROM badges WHERE code = 'TRACKING_100';
  IF badge_id IS NOT NULL THEN
    INSERT INTO user_badges (user_id, badge_id, awarded_at) 
    VALUES (admin_id, badge_id, now() - interval '10 days')
    ON CONFLICT DO NOTHING;
  END IF;

  -- Budget Master
  SELECT id INTO badge_id FROM badges WHERE code = 'BUDGET_MASTER';
  IF badge_id IS NOT NULL THEN
    INSERT INTO user_badges (user_id, badge_id, awarded_at) 
    VALUES (admin_id, badge_id, now() - interval '5 days')
    ON CONFLICT DO NOTHING;
  END IF;

  -- ============================================
  -- USAGE COUNTERS - Show some activity
  -- ============================================
  INSERT INTO usage_counters (user_id, month_key, scans_count) 
  VALUES (admin_id, current_month, 5)
  ON CONFLICT (user_id, month_key) DO UPDATE SET scans_count = 5;

  -- Previous month usage
  INSERT INTO usage_counters (user_id, month_key, scans_count) 
  VALUES (admin_id, to_char(CURRENT_DATE - interval '1 month', 'YYYY-MM'), 12)
  ON CONFLICT (user_id, month_key) DO UPDATE SET scans_count = 12;

  -- ============================================
  -- ANALYTICS EVENTS - Sample activity
  -- ============================================
  INSERT INTO analytics_events (user_id, event_name, occurred_at, properties) VALUES
    (admin_id, 'app_open', now() - interval '1 hour', '{"platform": "ios", "version": "1.0.0"}'),
    (admin_id, 'receipt_scanned', now() - interval '2 days', '{"category": "groceries", "amount_cents": 8547}'),
    (admin_id, 'budget_created', now() - interval '25 days', '{"category": "groceries", "limit_cents": 60000}'),
    (admin_id, 'savings_goal_created', now() - interval '60 days', '{"name": "Emergency Fund", "target_cents": 500000}'),
    (admin_id, 'badge_earned', now() - interval '30 days', '{"badge_code": "FIRST_SCAN"}'),
    (admin_id, 'transaction_added', now() - interval '5 days', '{"source": "manual", "category": "dining"}');

  RAISE NOTICE 'Demo data seeded successfully for admin user: %', admin_id;
END $$;
