-- Migration 084: Warmup and Stretch Duration Preferences
-- Adds warmup_duration_minutes and stretch_duration_minutes to the preferences JSONB column
-- These preferences control how long warmup and cooldown stretches should last (1-15 minutes)

-- ============================================================
-- DOCUMENTATION
-- ============================================================
-- The warmup and stretch duration preferences are stored within the preferences JSONB column
-- which already exists in the users table. No schema change is needed.
--
-- This migration serves as documentation that warmup_duration_minutes and stretch_duration_minutes
-- are now valid keys within the preferences JSONB with the following structure:
-- {
--   "warmup_duration_minutes": 5,    // 1-15 minutes, default 5
--   "stretch_duration_minutes": 5,   // 1-15 minutes, default 5
--   ... other preferences ...
-- }
--
-- Default values for new users:
-- - warmup_duration_minutes: 5 (5 minute warmup)
-- - stretch_duration_minutes: 5 (5 minute cooldown stretch)

-- ============================================================
-- UPDATE EXISTING USERS WITH DEFAULTS
-- ============================================================
-- Update existing users to have warmup_duration_minutes and stretch_duration_minutes
-- if they don't already have them set in their preferences

UPDATE users
SET preferences =
    CASE
        WHEN preferences IS NULL THEN '{"warmup_duration_minutes": 5, "stretch_duration_minutes": 5}'::jsonb
        WHEN NOT (preferences ? 'warmup_duration_minutes') AND NOT (preferences ? 'stretch_duration_minutes')
            THEN preferences || '{"warmup_duration_minutes": 5, "stretch_duration_minutes": 5}'::jsonb
        WHEN NOT (preferences ? 'warmup_duration_minutes')
            THEN preferences || '{"warmup_duration_minutes": 5}'::jsonb
        WHEN NOT (preferences ? 'stretch_duration_minutes')
            THEN preferences || '{"stretch_duration_minutes": 5}'::jsonb
        ELSE preferences
    END
WHERE preferences IS NULL
   OR NOT (preferences ? 'warmup_duration_minutes')
   OR NOT (preferences ? 'stretch_duration_minutes');

-- ============================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON COLUMN users.preferences IS 'JSONB containing user preferences including: warmup_duration_minutes (int 1-15) - warmup duration in minutes, stretch_duration_minutes (int 1-15) - cooldown stretch duration in minutes, and other workout preferences';
