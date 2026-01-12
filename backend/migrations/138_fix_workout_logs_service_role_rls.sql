-- Migration: 138_fix_workout_logs_service_role_rls.sql
-- Purpose: Fix RLS policy for workout_logs to allow service role access
-- Issue: The existing RLS policy queries the users table which may be blocked
--        when the backend uses service_role key, causing "permission denied for table users"

-- ============================================================================
-- Add service role bypass policy for workout_logs
-- ============================================================================

-- Drop existing service role policy if it exists
DROP POLICY IF EXISTS "Service role can manage all workout_logs" ON public.workout_logs;

-- Create service role bypass policy
-- This allows the backend (using service_role key) to manage workout_logs
CREATE POLICY "Service role can manage all workout_logs"
ON public.workout_logs
FOR ALL
USING ((SELECT auth.role()) = 'service_role');

-- ============================================================================
-- Also ensure the users table allows service_role to query it
-- (for cases where other policies still need to check users table)
-- ============================================================================

DROP POLICY IF EXISTS "Service role can read all users" ON public.users;

CREATE POLICY "Service role can read all users"
ON public.users
FOR SELECT
USING ((SELECT auth.role()) = 'service_role');

-- ============================================================================
-- Grant statements (may already exist but safe to re-run)
-- ============================================================================

GRANT ALL ON workout_logs TO service_role;
GRANT SELECT ON users TO service_role;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
