-- Seed some example badges
INSERT INTO badges (id, code, name, description) VALUES
  (gen_random_uuid(), 'FIRST_SCAN', 'First Scan', 'Uploaded your first receipt'),
  (gen_random_uuid(), 'WEEK_STREAK_7', '7-Day Streak', 'Tracked spending for 7 consecutive days'),
  (gen_random_uuid(), 'MONTH_STREAK_30', '30-Day Streak', 'Tracked spending for 30 consecutive days'),
  (gen_random_uuid(), 'SAVINGS_GOAL_100', 'Saved $100', 'Hit your first $100 savings goal'),
  (gen_random_uuid(), 'SAVINGS_GOAL_500', 'Saved $500', 'Hit your $500 savings goal'),
  (gen_random_uuid(), 'SAVINGS_GOAL_1000', 'Saved $1000', 'Hit your $1000 savings goal'),
  (gen_random_uuid(), 'BUDGET_MASTER', 'Budget Master', 'Stayed within all budgets for a month'),
  (gen_random_uuid(), 'TRACKING_100', 'Century Club', 'Tracked 100 transactions'),
  (gen_random_uuid(), 'TRACKING_500', 'Half Grand', 'Tracked 500 transactions'),
  (gen_random_uuid(), 'TRACKING_1000', 'Grand Master', 'Tracked 1000 transactions')
ON CONFLICT (code) DO NOTHING;


