-- Add notification settings to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS notification_budget_alerts boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS notification_goal_achieved boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS notification_streak_reminders boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS notification_weekly_summary boolean NOT NULL DEFAULT false;

