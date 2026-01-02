-- Migration: 122_fix_duplicate_policies_indexes.sql
-- Purpose: Fix Supabase linter warnings for multiple permissive policies and duplicate indexes
-- Date: 2026-01-01
-- Status: APPLIED

-- ============================================================================
-- PART 1: CONSOLIDATE DUPLICATE SELECT POLICIES ON REFERENCE TABLES
-- These tables are publicly readable - only need one SELECT policy
-- The service_policy was redundant since select_policy already uses USING (true)
-- ============================================================================

-- 1. exercise_library: Drop redundant service policy
DROP POLICY IF EXISTS "exercise_library_service_policy" ON public.exercise_library;
-- Kept: exercise_library_select_policy (SELECT with USING true)

-- 2. neat_achievements: Drop redundant service policy
DROP POLICY IF EXISTS "neat_achievements_service_policy" ON public.neat_achievements;
-- Kept: neat_achievements_select_policy (SELECT with USING true)

-- 3. nutrient_rdas: Drop redundant service policy
DROP POLICY IF EXISTS "Service role can manage nutrient RDAs" ON public.nutrient_rdas;
-- Kept: "Anyone can view nutrient RDAs" (SELECT with USING true)

-- 4. program_variants: Drop redundant service policy
DROP POLICY IF EXISTS "program_variants_service_policy" ON public.program_variants;
-- Kept: program_variants_select_policy (SELECT with USING true)

-- 5. programs: Drop redundant service policy
DROP POLICY IF EXISTS "programs_service_policy" ON public.programs;
-- Kept: programs_select_policy (SELECT with USING true)

-- 6. s3_video_paths: Drop redundant service policy
DROP POLICY IF EXISTS "s3_video_paths_service_policy" ON public.s3_video_paths;
-- Kept: s3_video_paths_select_policy (SELECT with USING true)

-- ============================================================================
-- PART 2: USER-OWNED TABLES WITH ALL POLICY
-- Tables with an ALL policy don't need a separate SELECT policy
-- ALL already covers SELECT, INSERT, UPDATE, DELETE
-- ============================================================================

-- 7. stretches: Has "Users can manage own stretches" (ALL) via workout_id join
-- No separate SELECT policy needed - ALL covers it

-- 8. warmups: Has "Users can manage own warmups" (ALL) via workout_id join
-- No separate SELECT policy needed - ALL covers it

-- 9. user_privacy_settings: Drop redundant SELECT policy
DROP POLICY IF EXISTS "Users can view their own privacy settings" ON public.user_privacy_settings;
-- Kept: "Users can manage their own privacy settings" (ALL)

-- 10. user_roi_metrics: Drop redundant SELECT policy
DROP POLICY IF EXISTS "Users can view own ROI metrics" ON public.user_roi_metrics;
-- Kept: "Users can manage own ROI metrics" (ALL)

-- 11. user_scheduling_preferences: Drop redundant SELECT policy
DROP POLICY IF EXISTS "Users can view own scheduling preferences" ON public.user_scheduling_preferences;
-- Kept: "Users can manage own scheduling preferences" (ALL)

-- ============================================================================
-- PART 3: DROP DUPLICATE INDEXES
-- ============================================================================

-- personal_records: Keep idx_personal_records_user_id, drop idx_personal_records_user
-- Both indexed user_id column, only one needed
DROP INDEX IF EXISTS public.idx_personal_records_user;

-- strength_baselines: Keep idx_strength_baselines_calibration_id, drop idx_strength_baselines_calibration
-- Both indexed calibration_workout_id column, only one needed
DROP INDEX IF EXISTS public.idx_strength_baselines_calibration;

-- ============================================================================
-- VERIFICATION (results after migration)
-- ============================================================================
--
-- Reference tables now have single SELECT policy:
--   exercise_library: exercise_library_select_policy (SELECT)
--   neat_achievements: neat_achievements_select_policy (SELECT)
--   nutrient_rdas: "Anyone can view nutrient RDAs" (SELECT)
--   program_variants: program_variants_select_policy (SELECT)
--   programs: programs_select_policy (SELECT)
--   s3_video_paths: s3_video_paths_select_policy (SELECT)
--
-- User-owned tables have single ALL policy:
--   stretches: "Users can manage own stretches" (ALL)
--   warmups: "Users can manage own warmups" (ALL)
--   user_privacy_settings: "Users can manage their own privacy settings" (ALL)
--   user_roi_metrics: "Users can manage own ROI metrics" (ALL)
--   user_scheduling_preferences: "Users can manage own scheduling preferences" (ALL)
--
-- Duplicate indexes removed:
--   personal_records: idx_personal_records_user (dropped, kept idx_personal_records_user_id)
--   strength_baselines: idx_strength_baselines_calibration (dropped, kept idx_strength_baselines_calibration_id)
