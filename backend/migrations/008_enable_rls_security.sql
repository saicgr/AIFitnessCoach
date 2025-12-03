-- Migration: Enable RLS on tables flagged by Security Advisor
-- Created: 2025-12-02
-- Purpose: Address security warnings for tables without Row Level Security

-- ============================================
-- s3_video_paths - Video URL mappings
-- ============================================
ALTER TABLE s3_video_paths ENABLE ROW LEVEL SECURITY;

-- Public read access (videos are public assets)
DROP POLICY IF EXISTS s3_video_paths_select_policy ON s3_video_paths;
CREATE POLICY s3_video_paths_select_policy ON s3_video_paths
    FOR SELECT
    USING (true);

-- Only service role can insert/update/delete
DROP POLICY IF EXISTS s3_video_paths_service_policy ON s3_video_paths;
CREATE POLICY s3_video_paths_service_policy ON s3_video_paths
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- exercise_library - Exercise definitions
-- ============================================
ALTER TABLE exercise_library ENABLE ROW LEVEL SECURITY;

-- Public read access (exercises are public)
DROP POLICY IF EXISTS exercise_library_select_policy ON exercise_library;
CREATE POLICY exercise_library_select_policy ON exercise_library
    FOR SELECT
    USING (true);

-- Only service role can modify
DROP POLICY IF EXISTS exercise_library_service_policy ON exercise_library;
CREATE POLICY exercise_library_service_policy ON exercise_library
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- programs - Workout programs
-- ============================================
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

-- Public read access (programs are public)
DROP POLICY IF EXISTS programs_select_policy ON programs;
CREATE POLICY programs_select_policy ON programs
    FOR SELECT
    USING (true);

-- Only service role can modify
DROP POLICY IF EXISTS programs_service_policy ON programs;
CREATE POLICY programs_service_policy ON programs
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- program_variants - Program variations
-- ============================================
ALTER TABLE program_variants ENABLE ROW LEVEL SECURITY;

-- Public read access
DROP POLICY IF EXISTS program_variants_select_policy ON program_variants;
CREATE POLICY program_variants_select_policy ON program_variants
    FOR SELECT
    USING (true);

-- Only service role can modify
DROP POLICY IF EXISTS program_variants_service_policy ON program_variants;
CREATE POLICY program_variants_service_policy ON program_variants
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- food_logs - User nutrition tracking
-- ============================================
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own food logs
DROP POLICY IF EXISTS food_logs_select_policy ON food_logs;
CREATE POLICY food_logs_select_policy ON food_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own food logs
DROP POLICY IF EXISTS food_logs_insert_policy ON food_logs;
CREATE POLICY food_logs_insert_policy ON food_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own food logs
DROP POLICY IF EXISTS food_logs_update_policy ON food_logs;
CREATE POLICY food_logs_update_policy ON food_logs
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can only delete their own food logs
DROP POLICY IF EXISTS food_logs_delete_policy ON food_logs;
CREATE POLICY food_logs_delete_policy ON food_logs
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS food_logs_service_policy ON food_logs;
CREATE POLICY food_logs_service_policy ON food_logs
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- hydration_logs - User hydration tracking
-- ============================================
ALTER TABLE hydration_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own hydration logs
DROP POLICY IF EXISTS hydration_logs_select_policy ON hydration_logs;
CREATE POLICY hydration_logs_select_policy ON hydration_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own hydration logs
DROP POLICY IF EXISTS hydration_logs_insert_policy ON hydration_logs;
CREATE POLICY hydration_logs_insert_policy ON hydration_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own hydration logs
DROP POLICY IF EXISTS hydration_logs_update_policy ON hydration_logs;
CREATE POLICY hydration_logs_update_policy ON hydration_logs
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can only delete their own hydration logs
DROP POLICY IF EXISTS hydration_logs_delete_policy ON hydration_logs;
CREATE POLICY hydration_logs_delete_policy ON hydration_logs
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS hydration_logs_service_policy ON hydration_logs;
CREATE POLICY hydration_logs_service_policy ON hydration_logs
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- user_settings - User preferences
-- ============================================
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Users can only see their own settings
DROP POLICY IF EXISTS user_settings_select_policy ON user_settings;
CREATE POLICY user_settings_select_policy ON user_settings
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own settings
DROP POLICY IF EXISTS user_settings_insert_policy ON user_settings;
CREATE POLICY user_settings_insert_policy ON user_settings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own settings
DROP POLICY IF EXISTS user_settings_update_policy ON user_settings;
CREATE POLICY user_settings_update_policy ON user_settings
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS user_settings_service_policy ON user_settings;
CREATE POLICY user_settings_service_policy ON user_settings
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- Fix Security Definer Views
-- These views bypass RLS which is a security concern.
-- Recreate them with SECURITY INVOKER (default) instead.
-- ============================================

-- Recreate exercise_library_cleaned view without SECURITY DEFINER
DROP VIEW IF EXISTS exercise_library_cleaned;
CREATE VIEW exercise_library_cleaned AS
SELECT
    id,
    -- Remove gender suffix from name for cleaner display
    CASE
        WHEN exercise_name LIKE '% (male)' THEN REPLACE(exercise_name, ' (male)', '')
        WHEN exercise_name LIKE '% (female)' THEN REPLACE(exercise_name, ' (female)', '')
        ELSE exercise_name
    END AS name,
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
    CASE
        WHEN exercise_name LIKE '% (male)' THEN 'male'
        WHEN exercise_name LIKE '% (female)' THEN 'female'
        ELSE NULL
    END AS gender
FROM exercise_library;

-- Grant SELECT to authenticated and anon roles
GRANT SELECT ON exercise_library_cleaned TO authenticated;
GRANT SELECT ON exercise_library_cleaned TO anon;

-- Recreate exercise_detail_vw view without SECURITY DEFINER
DROP VIEW IF EXISTS exercise_detail_vw;
CREATE VIEW exercise_detail_vw AS
SELECT
    el.id,
    el.exercise_name AS name,
    el.body_part,
    el.equipment,
    el.target_muscle,
    el.secondary_muscles,
    el.instructions,
    el.difficulty_level,
    el.category,
    el.gif_url,
    el.video_s3_path AS video_url,
    CASE
        WHEN el.exercise_name LIKE '% (male)' THEN 'male'
        WHEN el.exercise_name LIKE '% (female)' THEN 'female'
        ELSE NULL
    END AS gender
FROM exercise_library el;

-- Grant SELECT to authenticated and anon roles
GRANT SELECT ON exercise_detail_vw TO authenticated;
GRANT SELECT ON exercise_detail_vw TO anon;
