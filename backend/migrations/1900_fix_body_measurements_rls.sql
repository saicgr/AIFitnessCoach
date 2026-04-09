-- Migration 1900: Fix body_measurements RLS policies
-- Created: 2026-04-08
-- Purpose: body_measurements.user_id stores users.id (internal UUID),
--          but auth.uid() returns auth.users.id (Supabase Auth UUID).
--          These are different UUIDs, so the old policy auth.uid() = user_id
--          always evaluates to FALSE, blocking all direct Supabase reads.
--
-- Fix: Resolve auth.uid() → users.auth_id → users.id via subquery.

-- Drop the existing combined service_role policy (from migration 110)
DROP POLICY IF EXISTS "body_measurements_service_policy" ON body_measurements;

-- Drop and recreate all four CRUD policies
DROP POLICY IF EXISTS "body_measurements_select_policy" ON body_measurements;
CREATE POLICY "body_measurements_select_policy" ON body_measurements
  FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid()))
    OR (SELECT auth.role()) = 'service_role'::text
  );

DROP POLICY IF EXISTS "body_measurements_insert_policy" ON body_measurements;
CREATE POLICY "body_measurements_insert_policy" ON body_measurements
  FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid()))
    OR (SELECT auth.role()) = 'service_role'::text
  );

DROP POLICY IF EXISTS "body_measurements_update_policy" ON body_measurements;
CREATE POLICY "body_measurements_update_policy" ON body_measurements
  FOR UPDATE USING (
    user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid()))
    OR (SELECT auth.role()) = 'service_role'::text
  );

DROP POLICY IF EXISTS "body_measurements_delete_policy" ON body_measurements;
CREATE POLICY "body_measurements_delete_policy" ON body_measurements
  FOR DELETE USING (
    user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid()))
    OR (SELECT auth.role()) = 'service_role'::text
  );

-- Also drop the separate service_role_all policy from migration 1892 if it exists
-- (consolidated into the policies above)
DROP POLICY IF EXISTS "body_measurements_service_role_all" ON body_measurements;
