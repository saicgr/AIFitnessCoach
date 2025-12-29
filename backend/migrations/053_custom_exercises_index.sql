-- Migration 053: Add index for custom exercises lookup
-- Purpose: Enable efficient querying of user's custom exercises
-- The exercises table already has is_custom and created_by_user_id columns

-- Index for finding all custom exercises by a specific user
CREATE INDEX IF NOT EXISTS idx_exercises_custom_user
ON exercises(created_by_user_id)
WHERE is_custom = TRUE;

-- Index for finding all custom exercises (for admin/analytics)
CREATE INDEX IF NOT EXISTS idx_exercises_is_custom
ON exercises(is_custom)
WHERE is_custom = TRUE;
