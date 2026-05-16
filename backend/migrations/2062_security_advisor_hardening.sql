-- 2062_security_advisor_hardening.sql
-- Address Supabase Security Advisor warnings (snapshot 2026-05-13).
--
-- Scope:
--   1. Revoke EXECUTE on every SECURITY DEFINER public function from `anon`.
--      Rationale: every flagged SECURITY DEFINER RPC takes a p_user_id /
--      acts on behalf of a signed-in user. The backend uses `service_role`,
--      the mobile client uses `authenticated`. `anon` should never reach
--      these. EXECUTE remains for `authenticated` and `service_role`.
--   2. Pin search_path on the 14 plpgsql functions flagged
--      (function_search_path_mutable).
--   3. Revoke API role access on materialized views exposed via PostgREST
--      (`exercise_safety_index_mat`, `exercise_library_cleaned`). Backend
--      reads via service_role; clients should hit the wrapping RPCs.
--
-- NOT in this migration (require manual action — see checklist below):
--   - Enable HaveIBeenPwned leaked-password protection (Auth dashboard).
--   - Move `unaccent` extension out of public schema (touches dependent
--     indexes / generated columns — needs a dedicated migration).
--   - waitlist anon INSERT policy stays — intentional public signup form.

BEGIN;

-- =========================================================================
-- 1. Revoke EXECUTE from anon on every SECURITY DEFINER function in public.
-- =========================================================================
DO $$
DECLARE
    fn record;
    revoke_count int := 0;
BEGIN
    FOR fn IN
        SELECT n.nspname AS schema_name,
               p.proname AS func_name,
               pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.prosecdef = true
    LOOP
        -- Revoke from both `anon` (explicit grant) and PUBLIC (inherited
        -- grant). authenticated and service_role have their own explicit
        -- grants so they are unaffected.
        EXECUTE format(
            'REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM anon, PUBLIC',
            fn.schema_name, fn.func_name, fn.args
        );
        revoke_count := revoke_count + 1;
    END LOOP;
    RAISE NOTICE 'Revoked EXECUTE from anon+PUBLIC on % SECURITY DEFINER functions', revoke_count;
END $$;

-- Make this the default for future SECURITY DEFINER functions too.
-- (Default privileges only apply to functions created AFTER this statement
-- by the role that owns them, so this is best-effort but worth setting.)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE EXECUTE ON FUNCTIONS FROM anon;

-- =========================================================================
-- 2. Pin search_path on the 14 flagged functions.
-- =========================================================================
ALTER FUNCTION public.merch_claims_touch_updated_at()                                                                                            SET search_path = public, pg_temp;
ALTER FUNCTION public.merch_type_for_level(p_level integer)                                                                                      SET search_path = public, pg_temp;
ALTER FUNCTION public.get_food_patterns(p_user_id uuid, p_days integer, p_min_logs integer, p_include_inferred boolean, p_food_names text[])    SET search_path = public, pg_temp;
ALTER FUNCTION public.get_top_foods_by_metric(p_user_id uuid, p_metric text, p_start_ts timestamptz, p_end_ts timestamptz, p_limit integer)     SET search_path = public, pg_temp;
ALTER FUNCTION public.update_cardio_logs_updated_at()                                                                                            SET search_path = public, pg_temp;
ALTER FUNCTION public.recalculate_recipe_nutrition()                                                                                             SET search_path = public, pg_temp;
ALTER FUNCTION public.update_workout_program_templates_updated_at()                                                                              SET search_path = public, pg_temp;
ALTER FUNCTION public.update_oauth_sync_accounts_updated_at()                                                                                    SET search_path = public, pg_temp;
ALTER FUNCTION public.claim_founder_seat()                                                                                                       SET search_path = public, pg_temp;
ALTER FUNCTION public.release_founder_seat(p_seat_number integer)                                                                                SET search_path = public, pg_temp;
ALTER FUNCTION public.link_web_lifetime_to_user(p_user_id uuid, p_email text)                                                                    SET search_path = public, pg_temp;
ALTER FUNCTION public.prevent_orphaned_workouts()                                                                                                SET search_path = public, pg_temp;
ALTER FUNCTION public.lemmatize_food_word(w text)                                                                                                SET search_path = public, pg_temp;
ALTER FUNCTION public.normalize_food_name_sql(name text)                                                                                         SET search_path = public, pg_temp;

-- =========================================================================
-- 3. Revoke API access on materialized views.
-- =========================================================================
REVOKE SELECT ON public.exercise_safety_index_mat FROM anon, authenticated;
REVOKE SELECT ON public.exercise_library_cleaned  FROM anon, authenticated;

COMMIT;
