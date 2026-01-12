-- Migration: 139_fix_workout_logs_rls_combined.sql
-- Purpose: Fix RLS policy for workout_logs to properly allow service role access
-- Issue: The existing RLS policy "Users can manage own workout_logs" queries the users table
--        with a subquery that fails when service_role is used (auth.uid() returns NULL)
--        Migration 138 added a separate service_role policy but both policies are evaluated

-- ============================================================================
-- Fix: Combine service_role bypass INTO the main policy with OR short-circuit
-- ============================================================================

-- Drop the old problematic policy that has the users table subquery
DROP POLICY IF EXISTS "Users can manage own workout_logs" ON workout_logs;

-- Recreate with service_role check FIRST (short-circuit evaluation)
-- When auth.role() = 'service_role', the OR short-circuits and never evaluates the subquery
CREATE POLICY "Users can manage own workout_logs" ON workout_logs
    FOR ALL USING (
        (SELECT auth.role()) = 'service_role'
        OR
        user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    );

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
