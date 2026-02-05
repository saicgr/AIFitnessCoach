-- Migration 233: Fix Hormonal Health Tables RLS Policies
-- Description: Allow backend server-side access to hormonal health tables
-- Following the same pattern as migration 112 (users table fix)
-- Date: 2026-02-05

BEGIN;

-- ============================================================================
-- HORMONAL_PROFILES
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own hormonal profile" ON public.hormonal_profiles;
DROP POLICY IF EXISTS "Users can insert own hormonal profile" ON public.hormonal_profiles;
DROP POLICY IF EXISTS "Users can update own hormonal profile" ON public.hormonal_profiles;
DROP POLICY IF EXISTS "Users can delete own hormonal profile" ON public.hormonal_profiles;

CREATE POLICY "hormonal_profiles_select_policy" ON public.hormonal_profiles FOR SELECT
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "hormonal_profiles_insert_policy" ON public.hormonal_profiles FOR INSERT
WITH CHECK (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "hormonal_profiles_update_policy" ON public.hormonal_profiles FOR UPDATE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "hormonal_profiles_delete_policy" ON public.hormonal_profiles FOR DELETE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

-- ============================================================================
-- HORMONE_LOGS
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own hormone logs" ON public.hormone_logs;
DROP POLICY IF EXISTS "Users can insert own hormone logs" ON public.hormone_logs;
DROP POLICY IF EXISTS "Users can update own hormone logs" ON public.hormone_logs;
DROP POLICY IF EXISTS "Users can delete own hormone logs" ON public.hormone_logs;

CREATE POLICY "hormone_logs_select_policy" ON public.hormone_logs FOR SELECT
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "hormone_logs_insert_policy" ON public.hormone_logs FOR INSERT
WITH CHECK (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "hormone_logs_update_policy" ON public.hormone_logs FOR UPDATE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "hormone_logs_delete_policy" ON public.hormone_logs FOR DELETE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

-- ============================================================================
-- KEGEL_PREFERENCES
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own kegel preferences" ON public.kegel_preferences;
DROP POLICY IF EXISTS "Users can insert own kegel preferences" ON public.kegel_preferences;
DROP POLICY IF EXISTS "Users can update own kegel preferences" ON public.kegel_preferences;
DROP POLICY IF EXISTS "Users can delete own kegel preferences" ON public.kegel_preferences;

CREATE POLICY "kegel_preferences_select_policy" ON public.kegel_preferences FOR SELECT
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "kegel_preferences_insert_policy" ON public.kegel_preferences FOR INSERT
WITH CHECK (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "kegel_preferences_update_policy" ON public.kegel_preferences FOR UPDATE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "kegel_preferences_delete_policy" ON public.kegel_preferences FOR DELETE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

-- ============================================================================
-- KEGEL_SESSIONS
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own kegel sessions" ON public.kegel_sessions;
DROP POLICY IF EXISTS "Users can insert own kegel sessions" ON public.kegel_sessions;
DROP POLICY IF EXISTS "Users can update own kegel sessions" ON public.kegel_sessions;
DROP POLICY IF EXISTS "Users can delete own kegel sessions" ON public.kegel_sessions;

CREATE POLICY "kegel_sessions_select_policy" ON public.kegel_sessions FOR SELECT
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "kegel_sessions_insert_policy" ON public.kegel_sessions FOR INSERT
WITH CHECK (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "kegel_sessions_update_policy" ON public.kegel_sessions FOR UPDATE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

CREATE POLICY "kegel_sessions_delete_policy" ON public.kegel_sessions FOR DELETE
USING (
    ((select auth.uid()) = user_id)
    OR ((select auth.uid()) IS NULL)
    OR ((select auth.role()) = 'service_role')
);

COMMIT;
