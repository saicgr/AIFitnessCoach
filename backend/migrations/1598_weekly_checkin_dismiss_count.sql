-- Migration 1598: Add weekly_checkin_dismiss_count to nutrition_preferences
-- Tracks how many times a user has dismissed the weekly check-in without completing.
-- After 3 dismissals, the app stops auto-showing the prompt.

ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS weekly_checkin_dismiss_count INTEGER DEFAULT 0;

COMMENT ON COLUMN nutrition_preferences.weekly_checkin_dismiss_count IS
    'Counter for how many times user has dismissed weekly check-in without completing. Resets on successful check-in. App stops auto-showing after 3 dismissals.';
