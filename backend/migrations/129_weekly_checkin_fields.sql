-- Migration 129: Add weekly check-in fields to nutrition_preferences
-- These fields enable the weekly check-in prompt feature that reminds users
-- to review and adjust their nutrition targets on a weekly basis.

-- Add weekly_checkin_enabled column (defaults to true for new users)
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS weekly_checkin_enabled BOOLEAN DEFAULT true;

-- Add last_weekly_checkin_at column to track when user last completed a check-in
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS last_weekly_checkin_at TIMESTAMPTZ;

-- Add a comment explaining these fields
COMMENT ON COLUMN nutrition_preferences.weekly_checkin_enabled IS
    'Whether the weekly check-in reminder is enabled for this user. When true, the app will prompt the user to review their nutrition targets after 7 days.';

COMMENT ON COLUMN nutrition_preferences.last_weekly_checkin_at IS
    'Timestamp of when the user last completed a weekly check-in (accepted or declined the recommendation). Used to determine when to show the next check-in prompt.';

-- Update existing rows to have weekly check-in enabled by default
UPDATE nutrition_preferences
SET weekly_checkin_enabled = true
WHERE weekly_checkin_enabled IS NULL;

-- Create index for efficient querying of users due for weekly check-in
-- This is useful if we ever want to send push notifications or emails
CREATE INDEX IF NOT EXISTS idx_nutrition_prefs_weekly_checkin
ON nutrition_preferences (weekly_checkin_enabled, last_weekly_checkin_at)
WHERE weekly_checkin_enabled = true;
