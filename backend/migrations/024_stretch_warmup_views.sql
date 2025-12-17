-- Migration: Create cleaned views for stretch and warmup exercises
-- These views extract exercises suitable for warm-ups and cool-down stretches
-- from the main exercise_library, with video support

-- ========================================
-- STRETCH EXERCISES VIEW
-- ========================================
-- Extracts exercises with "stretch" in the name that are suitable for cool-down routines
-- Cleans up naming (removes _female/_male suffixes) and deduplicates

DROP VIEW IF EXISTS stretch_exercises_cleaned CASCADE;

CREATE VIEW stretch_exercises_cleaned AS
WITH base_stretches AS (
    SELECT
        id,
        -- Clean exercise name: remove _female/_male/_Female/_Male suffixes and normalize
        TRIM(
            regexp_replace(
                regexp_replace(exercise_name, '(_female|_male|_Female|_Male)$', '', 'i'),
                '\s+', ' ', 'g'
            )
        ) as name,
        -- Normalize body_part
        CASE
            WHEN lower(body_part) IN ('bodyweight', 'resistance') THEN body_part
            ELSE 'Bodyweight'
        END as body_part,
        COALESCE(target_muscle, '') as target_muscle,
        COALESCE(equipment, 'none') as equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM exercise_library
    WHERE lower(exercise_name) LIKE '%stretch%'
      AND video_s3_path IS NOT NULL  -- Only exercises with videos
),
-- Deduplicate by keeping one version of each exercise name
deduplicated AS (
    SELECT DISTINCT ON (lower(name))
        id,
        name,
        body_part,
        target_muscle,
        equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM base_stretches
    ORDER BY lower(name),
             -- Prefer entries with target_muscle filled in
             CASE WHEN target_muscle != '' THEN 0 ELSE 1 END,
             -- Prefer entries with instructions
             CASE WHEN instructions IS NOT NULL THEN 0 ELSE 1 END
)
SELECT
    id,
    name,
    body_part,
    target_muscle,
    equipment,
    instructions,
    -- Construct full video URL
    CASE
        WHEN video_s3_path IS NOT NULL
        THEN 'https://aifitnesscoach-videos.s3.us-west-1.amazonaws.com/' || video_s3_path
        ELSE NULL
    END as video_url,
    gif_url,
    CASE
        WHEN image_s3_path IS NOT NULL
        THEN 'https://aifitnesscoach-videos.s3.us-west-1.amazonaws.com/' || image_s3_path
        ELSE NULL
    END as image_url,
    'stretch' as exercise_type
FROM deduplicated;

-- ========================================
-- WARMUP EXERCISES VIEW
-- ========================================
-- Extracts exercises suitable for dynamic warm-ups
-- Includes: arm circles, leg swings, dynamic stretches, marches, rotations, etc.
-- Excludes: heavy compound movements, exercises requiring significant load

DROP VIEW IF EXISTS warmup_exercises_cleaned CASCADE;

CREATE VIEW warmup_exercises_cleaned AS
WITH base_warmups AS (
    SELECT
        id,
        -- Clean exercise name: remove _female/_male suffixes and normalize
        TRIM(
            regexp_replace(
                regexp_replace(exercise_name, '(_female|_male|_Female|_Male)$', '', 'i'),
                '\s+', ' ', 'g'
            )
        ) as name,
        CASE
            WHEN lower(body_part) IN ('bodyweight', 'resistance') THEN body_part
            ELSE 'Bodyweight'
        END as body_part,
        COALESCE(target_muscle, '') as target_muscle,
        COALESCE(equipment, 'none') as equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM exercise_library
    WHERE video_s3_path IS NOT NULL
      AND (
          -- Dynamic warmup patterns
          lower(exercise_name) SIMILAR TO '%(circle|swing|rotation|dynamic|march|jog|skip|hop|arm |leg |hip |shoulder |ankle |wrist |neck |torso |twist|raise|reach|windmill|inchworm|lunge walk|high knee|butt kick)%'
          -- Also include some bodyweight activation exercises
          OR lower(exercise_name) SIMILAR TO '%(glute bridge|fire hydrant|bird dog|cat cow|dead bug|mountain climber|jumping jack)%'
      )
      -- Exclude heavy strength exercises
      AND lower(exercise_name) NOT SIMILAR TO '%(press|curl|row|squat|deadlift|bench|pull up|chin up|dip|fly|pullover|shrug|barbell|dumbbell|cable|machine|weighted)%'
      -- Exclude stretches (those go in the stretch view)
      AND lower(exercise_name) NOT LIKE '%stretch%'
      -- Prefer bodyweight exercises
      AND (lower(body_part) IN ('bodyweight', '') OR body_part IS NULL OR lower(equipment) IN ('none', 'yoga mat', ''))
),
-- Deduplicate by keeping one version of each exercise name
deduplicated AS (
    SELECT DISTINCT ON (lower(name))
        id,
        name,
        body_part,
        target_muscle,
        equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM base_warmups
    ORDER BY lower(name),
             CASE WHEN target_muscle != '' THEN 0 ELSE 1 END,
             CASE WHEN instructions IS NOT NULL THEN 0 ELSE 1 END
)
SELECT
    id,
    name,
    body_part,
    target_muscle,
    equipment,
    instructions,
    CASE
        WHEN video_s3_path IS NOT NULL
        THEN 'https://aifitnesscoach-videos.s3.us-west-1.amazonaws.com/' || video_s3_path
        ELSE NULL
    END as video_url,
    gif_url,
    CASE
        WHEN image_s3_path IS NOT NULL
        THEN 'https://aifitnesscoach-videos.s3.us-west-1.amazonaws.com/' || image_s3_path
        ELSE NULL
    END as image_url,
    'warmup' as exercise_type
FROM deduplicated;

-- ========================================
-- COMBINED VIEW (optional, for convenience)
-- ========================================
DROP VIEW IF EXISTS warmup_stretch_exercises CASCADE;

CREATE VIEW warmup_stretch_exercises AS
SELECT * FROM stretch_exercises_cleaned
UNION ALL
SELECT * FROM warmup_exercises_cleaned;

-- Grant permissions
GRANT SELECT ON stretch_exercises_cleaned TO authenticated;
GRANT SELECT ON stretch_exercises_cleaned TO anon;
GRANT SELECT ON warmup_exercises_cleaned TO authenticated;
GRANT SELECT ON warmup_exercises_cleaned TO anon;
GRANT SELECT ON warmup_stretch_exercises TO authenticated;
GRANT SELECT ON warmup_stretch_exercises TO anon;
