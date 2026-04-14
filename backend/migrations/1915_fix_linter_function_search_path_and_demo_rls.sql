-- Migration 1915: Address Supabase linter warnings
--
-- Part A — function_search_path_mutable (3 functions)
-- Lock search_path to prevent search-path based privilege escalation on
-- SECURITY DEFINER functions. `award_xp` is SECURITY DEFINER so this matters
-- most there; the two trigger functions are non-SECURITY-DEFINER but the
-- linter still flags them. Pinning to (public, pg_temp) keeps existing
-- unqualified references working (they all resolve within public).
--
-- Part B — rls_policy_always_true (3 policies on demo_sessions /
-- demo_interactions)
-- Verified via grep: the Flutter app never writes to these tables; backend
-- demo.py always writes via the service_role-pinned Supabase client. The
-- *_service_role_all policies cover all legitimate writes. The anon INSERT/
-- UPDATE policies are dead code left as intentional placeholders by
-- migration 1895. Drop them — attack surface with zero functional value.

BEGIN;

-- ============================================================================
-- A. Pin search_path on flagged functions
-- ============================================================================
ALTER FUNCTION public.award_xp(uuid, integer, text, text, text, boolean, boolean)
    SET search_path = public, pg_temp;

ALTER FUNCTION public.default_workout_is_current()
    SET search_path = public, pg_temp;

ALTER FUNCTION public.ensure_single_current_workout()
    SET search_path = public, pg_temp;

-- ============================================================================
-- B. Drop permissive anon write policies on demo tables
-- ============================================================================
DROP POLICY IF EXISTS "demo_interactions_insert_policy" ON public.demo_interactions;
DROP POLICY IF EXISTS "demo_sessions_insert_policy"    ON public.demo_sessions;
DROP POLICY IF EXISTS "demo_sessions_update_policy"    ON public.demo_sessions;

COMMIT;
