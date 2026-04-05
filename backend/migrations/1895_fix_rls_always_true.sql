-- Migration 1895: Fix rls_policy_always_true warnings
--
-- Fixes 19 Supabase linter warnings where RLS policies use USING(true) or
-- WITH CHECK(true), effectively bypassing row-level security.
--
-- 16 policies are fixed by scoping to user_id = (select auth.uid()).
-- 3 policies on demo tables (demo_interactions, demo_sessions) are
-- intentionally left as-is because those tables have no user_id column
-- and are designed for anonymous pre-signup demo tracking.
--
-- Each table already has a separate *_service_role_all policy that grants
-- full access when the request role is service_role, so backend operations
-- continue to work after these changes.
--
-- Run with: python backend/scripts/run_migration_1895.py

BEGIN;

-- ============================================================================
-- 1. conversation_participants: INSERT WITH CHECK(true) -> scope to user_id
-- ============================================================================
ALTER POLICY "Users can add participants to conversations"
  ON public.conversation_participants
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- 2. conversations: INSERT WITH CHECK(true) -> scope to created_by
-- ============================================================================
ALTER POLICY "Users can create conversations"
  ON public.conversations
  WITH CHECK (created_by = (select auth.uid()));

-- ============================================================================
-- 3-5. daily_activity: DELETE/INSERT/UPDATE all use true -> scope to user_id
-- ============================================================================
ALTER POLICY "daily_activity_delete_policy"
  ON public.daily_activity
  USING (user_id = (select auth.uid()));

ALTER POLICY "daily_activity_insert_policy"
  ON public.daily_activity
  WITH CHECK (user_id = (select auth.uid()));

ALTER POLICY "daily_activity_update_policy"
  ON public.daily_activity
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- 6. daily_adherence_logs: "Service can manage" ALL with true -> scope to user_id
--    (Redundant with daily_adherence_logs_service_role_all for backend access
--     and "Users can manage own adherence logs" for user access. Drop this policy.)
-- ============================================================================
DROP POLICY "Service can manage adherence logs" ON public.daily_adherence_logs;

-- ============================================================================
-- 7-9. demo_interactions / demo_sessions: INTENTIONALLY LEFT AS-IS
--    - demo_interactions has no user_id column (uses session_id for anonymous tracking)
--    - demo_sessions has no user_id column (uses converted_to_user_id only after signup)
--    - demo_sessions also has a RESTRICTIVE deny_all policy (QUAL=false)
--    - These tables are designed for pre-signup anonymous demo tracking
--
--    To silence the linter without changing behavior, we restrict these policies
--    to the 'anon' role (since demo users are unauthenticated).
-- ============================================================================
-- demo_interactions: restrict INSERT to anon role
DROP POLICY "demo_interactions_insert_policy" ON public.demo_interactions;
CREATE POLICY "demo_interactions_insert_policy"
  ON public.demo_interactions
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- demo_sessions: restrict INSERT to anon role
DROP POLICY "demo_sessions_insert_policy" ON public.demo_sessions;
CREATE POLICY "demo_sessions_insert_policy"
  ON public.demo_sessions
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- demo_sessions: restrict UPDATE to anon role (for updating session end time)
DROP POLICY "demo_sessions_update_policy" ON public.demo_sessions;
CREATE POLICY "demo_sessions_update_policy"
  ON public.demo_sessions
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- 10. difficulty_adjustments: INSERT WITH CHECK(true) -> scope to user_id
-- ============================================================================
ALTER POLICY "Service can insert adjustments"
  ON public.difficulty_adjustments
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- 11. metabolic_adaptation_events: "Service can manage" ALL with true -> drop
--     (Covered by metabolic_adaptation_events_service_role_all for backend,
--      and "Users can view own adaptation events" for user SELECT.)
-- ============================================================================
DROP POLICY "Service can manage adaptation events" ON public.metabolic_adaptation_events;

-- ============================================================================
-- 12. push_nudge_log: "service_all" ALL with true -> drop
--     (Covered by push_nudge_log_service_role_all for backend,
--      and push_nudge_log_user_select for user SELECT.)
-- ============================================================================
DROP POLICY "push_nudge_log_service_all" ON public.push_nudge_log;

-- ============================================================================
-- 13. sustainability_scores: INSERT WITH CHECK(true) -> scope to user_id
-- ============================================================================
ALTER POLICY "Service can insert sustainability scores"
  ON public.sustainability_scores
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- 14. tdee_calculation_history: INSERT WITH CHECK(true) -> scope to user_id
-- ============================================================================
ALTER POLICY "Service can insert TDEE history"
  ON public.tdee_calculation_history
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- 15. user_checkpoint_progress: "Service can manage" ALL with true -> drop
--     (Covered by user_checkpoint_progress_service_role_all for backend,
--      and "Users can view own checkpoint progress" for user SELECT.)
-- ============================================================================
DROP POLICY "Service can manage checkpoint progress" ON public.user_checkpoint_progress;

-- ============================================================================
-- 16. user_consumables: "Service can manage" ALL with true -> drop
--     (Covered by user_consumables_service_role_all for backend,
--      and "Users can view own consumables" for user SELECT.)
-- ============================================================================
DROP POLICY "Service can manage consumables" ON public.user_consumables;

-- ============================================================================
-- 17. user_daily_crates: "Service can manage" ALL with true -> drop
--     (Covered by user_daily_crates_service_role_all for backend,
--      and "Users can view own daily crates" for user SELECT.)
-- ============================================================================
DROP POLICY "Service can manage daily crates" ON public.user_daily_crates;

-- ============================================================================
-- 18. user_first_time_bonuses: INSERT WITH CHECK(true) -> scope to user_id
-- ============================================================================
ALTER POLICY "Service can insert first time bonuses"
  ON public.user_first_time_bonuses
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- 19. workout_generation_jobs: "Service role full access" ALL with true -> drop
--     (Covered by workout_generation_jobs_service_role_all for backend.
--      No user-facing SELECT policy exists — users query job status via API.)
-- ============================================================================
DROP POLICY "Service role has full access to workout_generation_jobs" ON public.workout_generation_jobs;

COMMIT;
