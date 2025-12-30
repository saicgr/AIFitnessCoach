-- ============================================================================
-- Migration 075: Fix materialized views API access
-- ============================================================================
-- This migration fixes materialized views that are accessible over the Data APIs.
-- Materialized views should have proper access controls to prevent unauthorized access.
--
-- The linter warns about these views being selectable by anon or authenticated roles.
-- We'll revoke public access and grant only to authenticated users who need it.
--
-- Views to fix:
-- 1. leaderboard_streaks
-- 2. leaderboard_weekly_challenges
-- 3. leaderboard_challenge_masters
-- 4. leaderboard_volume_kings
-- ============================================================================

-- First, revoke all existing permissions
REVOKE ALL ON public.leaderboard_streaks FROM anon;
REVOKE ALL ON public.leaderboard_weekly_challenges FROM anon;
REVOKE ALL ON public.leaderboard_challenge_masters FROM anon;
REVOKE ALL ON public.leaderboard_volume_kings FROM anon;

-- Grant SELECT only to authenticated users (not anon)
-- This ensures only logged-in users can view leaderboards
GRANT SELECT ON public.leaderboard_streaks TO authenticated;
GRANT SELECT ON public.leaderboard_weekly_challenges TO authenticated;
GRANT SELECT ON public.leaderboard_challenge_masters TO authenticated;
GRANT SELECT ON public.leaderboard_volume_kings TO authenticated;

-- Grant full access to service_role for backend operations
GRANT ALL ON public.leaderboard_streaks TO service_role;
GRANT ALL ON public.leaderboard_weekly_challenges TO service_role;
GRANT ALL ON public.leaderboard_challenge_masters TO service_role;
GRANT ALL ON public.leaderboard_volume_kings TO service_role;

-- ============================================================================
-- NOTE: Materialized views don't support RLS, so we control access via GRANT/REVOKE.
-- The leaderboard data is intentionally public to authenticated users since it's
-- meant to be a shared competitive feature.
--
-- If stricter access is needed, consider:
-- 1. Creating a wrapper function with SECURITY DEFINER
-- 2. Using a regular view with RLS on the underlying tables
-- 3. Implementing access checks in the API layer
-- ============================================================================

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
