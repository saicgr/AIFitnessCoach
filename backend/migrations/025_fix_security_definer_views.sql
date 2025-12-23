-- Migration: 025_fix_security_definer_views.sql
-- Description: Remove SECURITY DEFINER from views and enable RLS on tables
-- Date: 2025-12-23
--
-- This migration fixes security lint errors from Supabase:
-- 1. Removes SECURITY DEFINER from views (they should use INVOKER)
-- 2. Enables RLS on achievement_types and feature_gates tables

-- ============================================
-- Fix SECURITY DEFINER views by recreating them with SECURITY INVOKER
-- ============================================

-- 1. stretch_exercises_cleaned view (based on exercise_library)
DROP VIEW IF EXISTS warmup_stretch_exercises CASCADE;
DROP VIEW IF EXISTS stretch_exercises_cleaned CASCADE;

CREATE VIEW stretch_exercises_cleaned
WITH (security_invoker = true)
AS
WITH base_stretches AS (
    SELECT
        id,
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
    WHERE lower(exercise_name) LIKE '%stretch%'
      AND video_s3_path IS NOT NULL
),
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
    'stretch' as exercise_type
FROM deduplicated;

-- 2. warmup_exercises_cleaned view (based on exercise_library)
DROP VIEW IF EXISTS warmup_exercises_cleaned CASCADE;

CREATE VIEW warmup_exercises_cleaned
WITH (security_invoker = true)
AS
WITH base_warmups AS (
    SELECT
        id,
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
          lower(exercise_name) SIMILAR TO '%(circle|swing|rotation|dynamic|march|jog|skip|hop|arm |leg |hip |shoulder |ankle |wrist |neck |torso |twist|raise|reach|windmill|inchworm|lunge walk|high knee|butt kick)%'
          OR lower(exercise_name) SIMILAR TO '%(glute bridge|fire hydrant|bird dog|cat cow|dead bug|mountain climber|jumping jack)%'
      )
      AND lower(exercise_name) NOT SIMILAR TO '%(press|curl|row|squat|deadlift|bench|pull up|chin up|dip|fly|pullover|shrug|barbell|dumbbell|cable|machine|weighted)%'
      AND lower(exercise_name) NOT LIKE '%stretch%'
      AND (lower(body_part) IN ('bodyweight', '') OR body_part IS NULL OR lower(equipment) IN ('none', 'yoga mat', ''))
),
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

-- 3. warmup_stretch_exercises (combined view)
CREATE VIEW warmup_stretch_exercises
WITH (security_invoker = true)
AS
SELECT * FROM stretch_exercises_cleaned
UNION ALL
SELECT * FROM warmup_exercises_cleaned;

-- 4. regeneration_analytics view (uses workout_regenerations table)
DROP VIEW IF EXISTS regeneration_analytics CASCADE;
CREATE VIEW regeneration_analytics
WITH (security_invoker = true)
AS
SELECT
    date_trunc('day', created_at) as day,
    COUNT(*) as total_regenerations,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(*) as success_count
FROM workout_regenerations
GROUP BY date_trunc('day', created_at)
ORDER BY day DESC;

-- 5. exercise_library_cleaned view (matches migration 021 structure)
DROP VIEW IF EXISTS exercise_library_cleaned CASCADE;
CREATE VIEW exercise_library_cleaned
WITH (security_invoker = true)
AS
WITH cleaned_exercises AS (
    SELECT
        exercise_library.id,
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
                CASE
                    WHEN exercise_library.video_s3_path IS NOT NULL
                         AND exercise_library.image_s3_path IS NOT NULL THEN 0
                    WHEN exercise_library.video_s3_path IS NOT NULL THEN 1
                    WHEN exercise_library.image_s3_path IS NOT NULL THEN 2
                    ELSE 3
                END,
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
    single_kettlebell_friendly
FROM cleaned_exercises
WHERE rn = 1;

-- 6. ai_settings_change_trends view (matches migration 018 structure)
DROP VIEW IF EXISTS ai_settings_change_trends CASCADE;
CREATE VIEW ai_settings_change_trends
WITH (security_invoker = true)
AS
SELECT
    DATE(changed_at) as change_date,
    setting_name,
    new_value,
    COUNT(*) as change_count,
    COUNT(DISTINCT user_id) as unique_users
FROM ai_settings_history
WHERE changed_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(changed_at), setting_name, new_value
ORDER BY change_date DESC, change_count DESC;

-- 7. popular_equipment_combinations view (uses equipment_usage_analytics table)
DROP VIEW IF EXISTS popular_equipment_combinations CASCADE;
CREATE VIEW popular_equipment_combinations
WITH (security_invoker = true)
AS
SELECT
    equipment_combination,
    SUM(usage_count) as total_uses,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(avg_workout_rating) as avg_rating
FROM equipment_usage_analytics
GROUP BY equipment_combination
ORDER BY total_uses DESC;

-- 8. popular_custom_inputs view (uses custom_workout_inputs table)
DROP VIEW IF EXISTS popular_custom_inputs CASCADE;
CREATE VIEW popular_custom_inputs
WITH (security_invoker = true)
AS
SELECT
    input_type,
    input_value,
    normalized_value,
    COUNT(DISTINCT user_id) as unique_users,
    SUM(usage_count) as total_uses,
    MIN(first_used_at) as first_seen,
    MAX(last_used_at) as last_seen
FROM custom_workout_inputs
GROUP BY input_type, input_value, normalized_value
HAVING COUNT(DISTINCT user_id) >= 2
ORDER BY total_uses DESC;

-- 9. user_engagement_by_ai_style view (matches migration 018 structure)
DROP VIEW IF EXISTS user_engagement_by_ai_style CASCADE;
CREATE VIEW user_engagement_by_ai_style
WITH (security_invoker = true)
AS
SELECT
    s.coaching_style,
    s.communication_tone,
    COUNT(DISTINCT s.user_id) as total_users,
    COUNT(c.id) as total_messages,
    AVG(c.ai_response_length) as avg_response_length,
    AVG(c.response_time_ms) as avg_response_time
FROM user_ai_settings s
LEFT JOIN chat_interaction_analytics c ON s.user_id = c.user_id
GROUP BY s.coaching_style, s.communication_tone
ORDER BY total_messages DESC;

-- 10. exercise_detail_vw view
DROP VIEW IF EXISTS exercise_detail_vw CASCADE;
CREATE VIEW exercise_detail_vw
WITH (security_invoker = true)
AS
SELECT
    id,
    exercise_name as name,
    body_part,
    equipment,
    target_muscle,
    secondary_muscles,
    instructions,
    gif_url,
    CASE
        WHEN video_s3_path IS NOT NULL
        THEN 'https://aifitnesscoach-videos.s3.us-west-1.amazonaws.com/' || video_s3_path
        ELSE NULL
    END as video_url
FROM exercise_library
WHERE exercise_name IS NOT NULL;

-- 11. ai_settings_popularity view (matches migration 018 structure)
DROP VIEW IF EXISTS ai_settings_popularity CASCADE;
CREATE VIEW ai_settings_popularity
WITH (security_invoker = true)
AS
SELECT
    coaching_style,
    communication_tone,
    response_length,
    COUNT(*) as user_count,
    AVG(encouragement_level) as avg_encouragement,
    SUM(CASE WHEN use_emojis THEN 1 ELSE 0 END) as emoji_users,
    SUM(CASE WHEN include_tips THEN 1 ELSE 0 END) as tips_users
FROM user_ai_settings
GROUP BY coaching_style, communication_tone, response_length
ORDER BY user_count DESC;

-- ============================================
-- Enable RLS on tables that are missing it
-- ============================================

-- Enable RLS on achievement_types (read-only reference table)
ALTER TABLE achievement_types ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read achievement types (it's reference data)
DROP POLICY IF EXISTS "Anyone can read achievement_types" ON achievement_types;
CREATE POLICY "Anyone can read achievement_types" ON achievement_types
    FOR SELECT
    USING (true);

-- Enable RLS on feature_gates
ALTER TABLE feature_gates ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read feature gates
DROP POLICY IF EXISTS "Anyone can read feature_gates" ON feature_gates;
CREATE POLICY "Anyone can read feature_gates" ON feature_gates
    FOR SELECT
    USING (true);

-- Grant necessary permissions
GRANT SELECT ON achievement_types TO authenticated;
GRANT SELECT ON feature_gates TO authenticated;
GRANT SELECT ON stretch_exercises_cleaned TO authenticated;
GRANT SELECT ON warmup_stretch_exercises TO authenticated;
GRANT SELECT ON regeneration_analytics TO authenticated;
GRANT SELECT ON exercise_library_cleaned TO authenticated;
GRANT SELECT ON ai_settings_change_trends TO authenticated;
GRANT SELECT ON popular_equipment_combinations TO authenticated;
GRANT SELECT ON popular_custom_inputs TO authenticated;
GRANT SELECT ON user_engagement_by_ai_style TO authenticated;
GRANT SELECT ON exercise_detail_vw TO authenticated;
GRANT SELECT ON ai_settings_popularity TO authenticated;
GRANT SELECT ON warmup_exercises_cleaned TO authenticated;

-- Also grant to anon for public data
GRANT SELECT ON achievement_types TO anon;
GRANT SELECT ON feature_gates TO anon;
GRANT SELECT ON exercise_library_cleaned TO anon;
GRANT SELECT ON exercise_detail_vw TO anon;
GRANT SELECT ON stretch_exercises_cleaned TO anon;
GRANT SELECT ON warmup_exercises_cleaned TO anon;
GRANT SELECT ON warmup_stretch_exercises TO anon;
