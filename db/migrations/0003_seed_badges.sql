-- Seed some example badges
INSERT INTO badges (id, code, name, description) VALUES
  (gen_random_uuid(), 'FIRST_SCAN', 'First Scan', 'Uploaded your first receipt'),
  (gen_random_uuid(), 'WEEK_STREAK_7', '7-Day Streak', 'Tracked spending for 7 consecutive days'),
  (gen_random_uuid(), 'SAVINGS_GOAL_100', 'Saved $100', 'Hit your first savings goal');


