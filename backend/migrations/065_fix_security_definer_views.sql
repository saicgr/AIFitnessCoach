-- ============================================================================
-- Migration 065: Fix SECURITY DEFINER views
-- ============================================================================
-- This migration fixes views that were flagged with SECURITY DEFINER property.
-- Views should use SECURITY INVOKER to respect the caller's RLS policies.
-- ============================================================================

-- Fix active_fasts view
ALTER VIEW IF EXISTS active_fasts SET (security_invoker = true);

-- Fix fasting_stats view
ALTER VIEW IF EXISTS fasting_stats SET (security_invoker = true);

-- Fix latest_progress_photos view
ALTER VIEW IF EXISTS latest_progress_photos SET (security_invoker = true);

-- Fix progress_photo_stats view
ALTER VIEW IF EXISTS progress_photo_stats SET (security_invoker = true);

-- Fix user_unilateral_exercise_stats view
ALTER VIEW IF EXISTS user_unilateral_exercise_stats SET (security_invoker = true);

-- Fix user_flexibility_progress view
ALTER VIEW IF EXISTS user_flexibility_progress SET (security_invoker = true);

-- Fix user_staples_with_details view
ALTER VIEW IF EXISTS user_staples_with_details SET (security_invoker = true);

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
