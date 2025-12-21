-- Migration: Improve single_dumbbell_friendly logic
-- Created: 2025-12-20
-- Purpose: Expand the single_dumbbell_friendly criteria to include more exercises
--
-- Philosophy: Most dumbbell exercises CAN be done with 1 dumbbell by working one side at a time
-- We should EXCLUDE exercises that REQUIRE 2 dumbbells (bilateral movements), not include only specific patterns
--
-- EXCLUDE (require 2 dumbbells):
--   - Bench press variants (need both for stability)
--   - Chest press, chest fly (bilateral chest movements)
--   - Both-arm curls, both-arm extensions
--   - Exercises explicitly stating "both" or "two"
--
-- INCLUDE (can be done with 1 dumbbell):
--   - Single-arm, unilateral, alternating movements (explicitly one side)
--   - Rows, raises, curls, presses that can be done one arm at a time
--   - Overhead movements (can alternate)
--   - Most shoulder, arm, back exercises

DROP VIEW IF EXISTS exercise_library_cleaned;

CREATE VIEW exercise_library_cleaned AS
WITH cleaned_exercises AS (
    SELECT
        exercise_library.id,
        -- Clean name: Remove gender suffixes and convert to Title Case
        INITCAP(
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(exercise_library.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
                    '_', ' ', 'g'
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
        -- Single dumbbell friendly: INCLUDE exercises that make sense with 1 dumbbell
        CASE
            WHEN exercise_library.equipment ILIKE '%dumbbell%'
                 AND (
                     -- Explicitly single-arm/unilateral movements
                     exercise_library.exercise_name ~* '(single|one|unilateral|alternating|alt )'
                     -- Common single-dumbbell exercise patterns
                     OR exercise_library.exercise_name ~* 'dumbbell.*(curl|press|raise|extension|kickback|row|shrug|swing|snatch|clean|fly|pullover|upright)'
                     -- Position-based exercises (can be done one arm at a time)
                     OR exercise_library.exercise_name ~* '(seated|standing|lying|kneeling|bent over|leaning|incline|decline).*(dumbbell|db).*(curl|press|raise|extension|kickback|row|fly|pullover)'
                     -- Specific single-dumbbell friendly exercises
                     OR exercise_library.exercise_name ~* '(lateral raise|front raise|rear raise|overhead|arnold|concentration|hammer|tricep|bicep|shoulder|deltoid)'
                 )
                 -- EXCLUDE: Exercises that explicitly require 2 dumbbells
                 AND exercise_library.exercise_name !~* '(bench press|chest press|both|two hands|dual|double)'
            THEN TRUE
            ELSE FALSE
        END AS single_dumbbell_friendly,
        -- Single kettlebell friendly: Similar logic for kettlebells
        CASE
            WHEN exercise_library.equipment ILIKE '%kettlebell%'
                 AND (
                     exercise_library.exercise_name ~* '(single|one|unilateral|alternating|alt |swing|snatch|clean|press|row|goblet|halo|windmill)'
                     OR exercise_library.exercise_name ~* '^kettlebell (swing|snatch|clean|press|row|goblet|halo|windmill)'
                 )
            THEN TRUE
            ELSE FALSE
        END AS single_kettlebell_friendly,
        -- Row number for deduplication - PRIORITIZE having video/image first!
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(exercise_library.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
                        '_', ' ', 'g'
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
    -- Add alternating_hands instruction for single-dumbbell exercises
    single_dumbbell_friendly AS alternating_hands
FROM cleaned_exercises
WHERE rn = 1;

-- Grant SELECT to authenticated and anon roles
GRANT SELECT ON exercise_library_cleaned TO authenticated;
GRANT SELECT ON exercise_library_cleaned TO anon;

COMMENT ON VIEW exercise_library_cleaned IS 'Deduplicated exercise library - prioritizes entries with video+image, one per exercise with clean Title Case names. single_dumbbell_friendly uses exclusion logic (excludes bilateral movements that require 2 dumbbells).';
