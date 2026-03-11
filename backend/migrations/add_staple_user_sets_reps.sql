-- Migration: Add user_sets, user_reps, user_rest_seconds, target_days to staple_exercises
-- Purpose: Allow users to customize sets/reps/rest and day-of-week targeting for staple exercises
-- Date: 2026-03-11

ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_sets INTEGER;
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_reps VARCHAR(10);  -- "10" or "8-12" format
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS user_rest_seconds INTEGER;

-- target_days: array of day-of-week integers (0=Monday, 6=Sunday)
-- NULL means "all days" (existing behavior), empty array means "no days"
-- e.g., {0,2,4} means Monday, Wednesday, Friday
ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS target_days INTEGER[];

-- Drop and recreate the view to include the new columns (column order changed)
DROP VIEW IF EXISTS user_staples_with_details;
CREATE VIEW user_staples_with_details AS
SELECT
    s.id,
    s.user_id,
    s.exercise_name,
    s.library_id,
    s.muscle_group,
    s.reason,
    s.created_at,
    s.gym_profile_id,
    s.section,
    s.user_duration_seconds,
    s.user_speed_mph,
    s.user_incline_percent,
    s.user_rpm,
    s.user_resistance_level,
    s.user_stroke_rate_spm,
    s.user_sets,
    s.user_reps,
    s.user_rest_seconds,
    s.target_days,
    el.body_part,
    el.equipment,
    el.gif_url,
    el.target_muscle,
    el.secondary_muscles,
    el.default_incline_percent,
    el.default_speed_mph,
    el.default_rpm,
    el.default_resistance_level,
    el.stroke_rate_spm,
    el.default_duration_seconds,
    el.movement_pattern,
    el.energy_system,
    el.impact_level,
    el.category,
    gp.name AS gym_profile_name,
    gp.color AS gym_profile_color
FROM staple_exercises s
LEFT JOIN exercise_library el ON s.library_id = el.id
LEFT JOIN gym_profiles gp ON s.gym_profile_id = gp.id;
