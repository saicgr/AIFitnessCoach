-- Resolve Supabase security advisor lint 0010_security_definer_view for the
-- three anonymous-readable share views: public_workouts_v, public_users_v,
-- public_plans_v.
--
-- These views were originally created with `security_invoker = false`
-- (the Postgres default for a SECURITY DEFINER view) so anon could read
-- public share data without any RLS policy on the underlying tables. The
-- advisor correctly flags that as a footgun: any future column added to
-- the base table is implicitly readable through the view, regardless of
-- RLS intent.
--
-- This migration flips each view to invoker mode and adds the precise
-- anon-SELECT policies that match each view's WHERE clause, so:
--   1. The lint clears (advisor inspects the view's options bit).
--   2. Public share pages keep working for anon visitors.
--   3. Non-public rows on the base tables stay invisible to anon (anon
--      can't read a workout without a share_token, can't read a plan
--      that's been revoked, etc.).

BEGIN;

-- ────────────────────────────────────────────────────────────────────────
-- 1) Anon SELECT on workouts limited to the share-eligible subset.
--    Mirrors public_workouts_v's WHERE clause exactly. Restricted to the
--    `anon` role so authenticated users still pass through their own
--    owner policy (`Users can view own workouts`).
-- ────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS workouts_anon_share_read ON public.workouts;
CREATE POLICY workouts_anon_share_read
  ON public.workouts
  FOR SELECT
  TO anon
  USING (share_token IS NOT NULL AND is_completed = true);

-- ────────────────────────────────────────────────────────────────────────
-- 2) Anon SELECT on shared_plans limited to non-revoked rows.
--    Mirrors public_plans_v's WHERE clause.
-- ────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS shared_plans_anon_share_read ON public.shared_plans;
CREATE POLICY shared_plans_anon_share_read
  ON public.shared_plans
  FOR SELECT
  TO anon
  USING (revoked_at IS NULL);

-- ────────────────────────────────────────────────────────────────────────
-- 3) `users` already permits anon SELECT via the long-standing
--    `users_full_access` policy (auth.uid() IS NULL branch). The view's
--    select-list explicitly limits the columns exposed to public-safe
--    fields (username, name, avatar_url, bio, joined_at, public counts),
--    so we don't need a tighter policy here — invoker mode is enough.
-- ────────────────────────────────────────────────────────────────────────

-- ────────────────────────────────────────────────────────────────────────
-- 4) Flip the views to invoker mode. ALTER VIEW SET preserves the existing
--    definition + grants, so no need to drop/recreate.
-- ────────────────────────────────────────────────────────────────────────
ALTER VIEW public.public_workouts_v SET (security_invoker = true);
ALTER VIEW public.public_plans_v    SET (security_invoker = true);
ALTER VIEW public.public_users_v    SET (security_invoker = true);

-- Re-assert grants in case they were dropped by any earlier maintenance.
GRANT SELECT ON public.public_workouts_v TO anon, authenticated;
GRANT SELECT ON public.public_plans_v    TO anon, authenticated;
GRANT SELECT ON public.public_users_v    TO anon, authenticated;

COMMIT;
