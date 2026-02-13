-- Migration: 242_staple_cardio_user_overrides.sql
-- Created: 2026-02-12
-- Purpose: Add user-provided cardio override columns to staple_exercises table
--          so users can customize duration, speed, incline, etc. for their stapled cardio exercises.
--          User overrides take priority over library defaults at workout generation time.

-- ============================================
-- 1. Add user override columns to staple_exercises
-- ============================================

ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_duration_seconds INTEGER;
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_speed_mph DOUBLE PRECISION;
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_incline_percent DOUBLE PRECISION;
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_rpm INTEGER;
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_resistance_level INTEGER;
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_stroke_rate_spm INTEGER;

-- ============================================
-- 2. Recreate user_staples_with_details view
--    Now includes user override columns
-- ============================================

DROP VIEW IF EXISTS user_staples_with_details;
CREATE VIEW user_staples_with_details AS
SELECT
    se.id,
    se.user_id,
    se.exercise_name,
    se.library_id,
    se.muscle_group,
    se.reason,
    se.section,
    se.created_at,
    se.gym_profile_id,
    gp.name AS gym_profile_name,
    gp.color AS gym_profile_color,
    gp.icon AS gym_profile_icon,
    el.body_part,
    el.equipment,
    el.gif_url,
    el.category,
    -- Cardio metadata (library defaults)
    el.default_incline_percent,
    el.default_speed_mph,
    el.default_rpm,
    el.default_resistance_level,
    el.stroke_rate_spm,
    el.default_duration_seconds,
    -- User overrides (take priority over library defaults)
    se.user_duration_seconds,
    se.user_speed_mph,
    se.user_incline_percent,
    se.user_rpm,
    se.user_resistance_level,
    se.user_stroke_rate_spm,
    -- Movement classification
    el.movement_pattern,
    el.energy_system,
    el.impact_level
FROM staple_exercises se
LEFT JOIN exercise_library el ON se.library_id = el.id
LEFT JOIN gym_profiles gp ON se.gym_profile_id = gp.id;

-- Grant permissions
GRANT SELECT ON user_staples_with_details TO authenticated;
GRANT SELECT ON user_staples_with_details TO anon;

COMMENT ON COLUMN staple_exercises.user_duration_seconds IS 'User-specified duration in seconds for cardio staples. Overrides library default_duration_seconds.';
COMMENT ON COLUMN staple_exercises.user_speed_mph IS 'User-specified speed in mph. Overrides library default_speed_mph.';
COMMENT ON COLUMN staple_exercises.user_incline_percent IS 'User-specified incline percent. Overrides library default_incline_percent.';
COMMENT ON COLUMN staple_exercises.user_rpm IS 'User-specified RPM for cycling. Overrides library default_rpm.';
COMMENT ON COLUMN staple_exercises.user_resistance_level IS 'User-specified resistance level. Overrides library default_resistance_level.';
COMMENT ON COLUMN staple_exercises.user_stroke_rate_spm IS 'User-specified stroke rate (strokes per minute) for rowing. Overrides library stroke_rate_spm.';
