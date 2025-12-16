-- Update exercise_library_cleaned view to ONLY include exercises with videos AND images
-- This ensures all workout generation always uses exercises with complete media content

DROP VIEW IF EXISTS exercise_library_cleaned;

CREATE VIEW exercise_library_cleaned AS
WITH cleaned_exercises AS (
    SELECT
        exercise_library.id,
        initcap(TRIM(BOTH FROM regexp_replace(regexp_replace(exercise_library.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'), '_', ' ', 'g'))) AS name,
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
        row_number() OVER (
            PARTITION BY lower(TRIM(BOTH FROM regexp_replace(regexp_replace(exercise_library.exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'), '_', ' ', 'g')))
            ORDER BY
                CASE
                    WHEN exercise_library.exercise_name !~* '(female|male)$' THEN 0
                    WHEN exercise_library.exercise_name ~* 'male$' AND exercise_library.exercise_name !~* 'female$' THEN 1
                    ELSE 2
                END,
                exercise_library.exercise_name
        ) AS rn
    FROM exercise_library
    WHERE exercise_library.video_s3_path IS NOT NULL  -- ONLY include exercises with videos
      AND exercise_library.image_s3_path IS NOT NULL  -- ONLY include exercises with images
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
    avoid_if
FROM cleaned_exercises
WHERE rn = 1;
