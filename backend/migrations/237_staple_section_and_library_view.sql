-- Migration: 237_staple_section_and_library_view.sql
-- Created: 2026-02-09
-- Purpose: Add section column to staple_exercises for warmup/stretch staples,
--          update views to include section + exercise metadata columns.

-- ============================================
-- 1. Add `section` column to staple_exercises
-- ============================================

ALTER TABLE staple_exercises ADD COLUMN IF NOT EXISTS section VARCHAR(20) DEFAULT 'main';

-- Add CHECK constraint for valid section values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'check_staple_section'
    ) THEN
        ALTER TABLE staple_exercises ADD CONSTRAINT check_staple_section
            CHECK (section IN ('main', 'warmup', 'stretches'));
    END IF;
END$$;

-- ============================================
-- 2. Update unique index to include section
--    Same exercise can be a warmup staple AND a main staple
-- ============================================

DROP INDEX IF EXISTS idx_staple_exercises_unique;
CREATE UNIQUE INDEX idx_staple_exercises_unique
    ON staple_exercises(user_id, exercise_name, section, COALESCE(gym_profile_id, '00000000-0000-0000-0000-000000000000'));

-- ============================================
-- 3. Recreate user_staples_with_details view
--    Now includes: section + exercise metadata from exercise_library
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
    -- Cardio metadata
    el.default_incline_percent,
    el.default_speed_mph,
    el.default_rpm,
    el.default_resistance_level,
    el.stroke_rate_spm,
    el.default_duration_seconds,
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

-- ============================================
-- 4. Recreate exercise_library_cleaned view
--    Adding 22 metadata columns from migration 235
--    Preserving exact same dedup/ROW_NUMBER/cleaning logic from migration 177
-- ============================================

DROP VIEW IF EXISTS exercise_library_cleaned;

CREATE VIEW exercise_library_cleaned AS
WITH cleaned_exercises AS (
    SELECT
        exercise_library.id,
        -- Clean name: Remove gender suffixes, "360 degrees", trailing numbers, and convert to Title Case
        INITCAP(
            TRIM(
                -- Remove trailing standalone numbers (e.g., " 360" but not "360-Degree")
                REGEXP_REPLACE(
                    -- Remove "360 degrees" video metadata (with or without parentheses)
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(exercise_library.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
                            '_', ' ', 'g'
                        ),
                        '\s*\(?\s*360\s*degrees?\s*\)?\s*$', '', 'i'
                    ),
                    '\s+\d+$', '', 'g'
                )
            )
        ) AS name,
        exercise_library.exercise_name AS original_name,
        exercise_library.body_part,
        exercise_library.equipment,
        exercise_library.target_muscle,
        exercise_library.secondary_muscles,
        exercise_library.instructions,
        exercise_library.difficulty_level,
        exercise_library.category,
        exercise_library.gif_url,
        exercise_library.video_s3_path AS video_url,
        exercise_library.image_s3_path AS image_url,
        exercise_library.goals,
        exercise_library.suitable_for,
        exercise_library.avoid_if,
        -- Equipment-friendly flags
        CASE
            WHEN exercise_library.equipment ILIKE '%dumbbell%'
                 OR exercise_library.exercise_name ILIKE '%dumbbell%'
                 OR exercise_library.exercise_name ILIKE '%db %'
            THEN TRUE
            ELSE FALSE
        END AS single_dumbbell_friendly,
        CASE
            WHEN exercise_library.equipment ILIKE '%kettlebell%'
                 OR exercise_library.exercise_name ILIKE '%kettlebell%'
                 OR exercise_library.exercise_name ILIKE '%kb %'
            THEN TRUE
            ELSE FALSE
        END AS single_kettlebell_friendly,
        -- =============================================
        -- NEW: 22 metadata columns from migration 235
        -- =============================================
        exercise_library.movement_pattern,
        exercise_library.mechanic_type,
        exercise_library.force_type,
        exercise_library.plane_of_motion,
        exercise_library.energy_system,
        exercise_library.default_duration_seconds,
        exercise_library.default_rep_range_min,
        exercise_library.default_rep_range_max,
        exercise_library.default_rest_seconds,
        exercise_library.default_tempo,
        exercise_library.default_incline_percent,
        exercise_library.default_speed_mph,
        exercise_library.default_resistance_level,
        exercise_library.default_rpm,
        exercise_library.stroke_rate_spm,
        exercise_library.contraindicated_conditions,
        exercise_library.impact_level,
        exercise_library.form_complexity,
        exercise_library.stability_requirement,
        exercise_library.is_dynamic_stretch,
        exercise_library.hold_seconds_min,
        exercise_library.hold_seconds_max,
        -- Row number for deduplication - PRIORITIZE having video/image first!
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(
                TRIM(
                    -- Match the cleaning logic exactly for deduplication
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(exercise_library.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
                                '_', ' ', 'g'
                            ),
                            '\s*\(?\s*360\s*degrees?\s*\)?\s*$', '', 'i'
                        ),
                        '\s+\d+$', '', 'g'
                    )
                )
            )
            ORDER BY
                -- First priority: Has both video AND image
                CASE
                    WHEN exercise_library.video_s3_path IS NOT NULL
                         AND exercise_library.image_s3_path IS NOT NULL THEN 0
                    WHEN exercise_library.video_s3_path IS NOT NULL THEN 1
                    WHEN exercise_library.image_s3_path IS NOT NULL THEN 2
                    ELSE 3
                END,
                -- Second priority: Prefer non-gendered, then male, then female
                CASE
                    WHEN exercise_library.exercise_name !~* '(female|male)$' THEN 0
                    WHEN exercise_library.exercise_name ~* 'male$' AND exercise_library.exercise_name !~* 'female$' THEN 1
                    ELSE 2
                END,
                exercise_library.exercise_name
        ) AS rn
    FROM exercise_library
)
SELECT
    id,
    name,
    original_name,
    body_part,
    equipment,
    target_muscle,
    secondary_muscles,
    instructions,
    difficulty_level,
    category,
    gif_url,
    video_url,
    image_url,
    goals,
    suitable_for,
    avoid_if,
    single_dumbbell_friendly,
    single_kettlebell_friendly,
    -- 22 metadata columns
    movement_pattern,
    mechanic_type,
    force_type,
    plane_of_motion,
    energy_system,
    default_duration_seconds,
    default_rep_range_min,
    default_rep_range_max,
    default_rest_seconds,
    default_tempo,
    default_incline_percent,
    default_speed_mph,
    default_resistance_level,
    default_rpm,
    stroke_rate_spm,
    contraindicated_conditions,
    impact_level,
    form_complexity,
    stability_requirement,
    is_dynamic_stretch,
    hold_seconds_min,
    hold_seconds_max
FROM cleaned_exercises
WHERE rn = 1;

-- Grant SELECT to authenticated and anon roles
GRANT SELECT ON exercise_library_cleaned TO authenticated;
GRANT SELECT ON exercise_library_cleaned TO anon;

COMMENT ON VIEW exercise_library_cleaned IS 'Deduplicated exercise library with video_url, image_url, and 22 metadata columns. Removes trailing numbers, gender suffixes. Prioritizes entries with video+image.';
