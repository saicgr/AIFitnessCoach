-- Migration: 086_ui_onboarding_flags
-- Description: Track UI onboarding/tooltip states for users
-- Date: 2025-12-30

-- Add JSONB column to track UI onboarding state
-- This stores flags for tooltips, tours, and first-time hints the user has seen
ALTER TABLE users
ADD COLUMN IF NOT EXISTS ui_onboarding_state JSONB DEFAULT '{}'::jsonb;

-- Create GIN index for efficient JSONB queries
-- Allows fast lookups like: WHERE ui_onboarding_state @> '{"home_edit_tooltip_shown": true}'
CREATE INDEX IF NOT EXISTS idx_users_ui_onboarding_state ON users USING GIN (ui_onboarding_state);

-- Column documentation
COMMENT ON COLUMN users.ui_onboarding_state IS 'Tracks which UI tooltips/tours user has seen. Example: {"home_edit_tooltip_shown": true, "feedback_explanation_shown": true, "settings_tour_completed": false}';

-- Example expected structure:
-- {
--   "home_edit_tooltip_shown": true,        -- Edit mode tooltip on home screen
--   "feedback_explanation_shown": true,     -- Explanation of workout feedback system
--   "settings_tour_completed": false,       -- Full settings walkthrough
--   "first_workout_tips_shown": true,       -- Tips shown before first workout
--   "swap_exercise_hint_shown": false,      -- Hint about swapping exercises
--   "progress_chart_explained": true        -- Progress chart explanation
-- }
