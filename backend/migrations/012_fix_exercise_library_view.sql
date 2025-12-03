-- Migration: Fix exercise_library_cleaned view to properly deduplicate
-- Created: 2025-12-02
-- Purpose: Remove duplicate exercises - keep only ONE version per exercise

-- Drop and recreate the view with proper deduplication
DROP VIEW IF EXISTS exercise_library_cleaned;

CREATE VIEW exercise_library_cleaned AS
WITH cleaned_exercises AS (
    SELECT
        id,
        -- Remove gender suffixes and convert to Title Case
        INITCAP(
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
                    '_', ' ', 'g'
                )
            )
        ) AS name,
        exercise_name AS original_name,
        body_part,
        equipment,
        target_muscle,
        secondary_muscles,
        instructions,
        difficulty_level,
        category,
        gif_url,
        video_s3_path AS video_url,
        -- Row number for deduplication - keep just ONE per exercise
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
                        '_', ' ', 'g'
                    )
                )
            )
            ORDER BY
                -- Prefer: non-gendered first, then male, then female
                CASE
                    WHEN exercise_name !~* '(female|male)$' THEN 0
                    WHEN exercise_name ~* 'male$' AND exercise_name !~* 'female$' THEN 1
                    ELSE 2
                END,
                exercise_name
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
    video_url
FROM cleaned_exercises
WHERE rn = 1;

-- Grant SELECT to authenticated and anon roles
GRANT SELECT ON exercise_library_cleaned TO authenticated;
GRANT SELECT ON exercise_library_cleaned TO anon;

COMMENT ON VIEW exercise_library_cleaned IS 'Deduplicated exercise library - one entry per exercise with clean Title Case names';
