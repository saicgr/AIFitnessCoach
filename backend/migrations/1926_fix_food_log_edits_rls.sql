-- Fix food_log_edits service-role RLS policy.
-- Migration 1912 used bare `auth.role() = 'service_role'` which doesn't match
-- in all PostgREST connection modes. Align with the triple-check pattern from
-- migration 1892 that other tables (food_logs, food_nutrition_overrides, etc.)
-- already use so the backend service-role client can read/write this table.

DROP POLICY IF EXISTS "Service role manages food log edits" ON food_log_edits;
CREATE POLICY "Service role manages food log edits" ON food_log_edits
    FOR ALL
    USING (
        (select current_setting('role'::text)) = 'service_role'::text
        OR (select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text
        OR (select auth.role()) = 'service_role'::text
    )
    WITH CHECK (
        (select current_setting('role'::text)) = 'service_role'::text
        OR (select current_setting('request.jwt.claim.role'::text, true)) = 'service_role'::text
        OR (select auth.role()) = 'service_role'::text
    );
