-- Migration: Fix two Supabase security-linter ERRORs flagged in prod
-- (2026-04-23 snapshot).
--
--   1. `public.exercise_library_cleaned` view had SECURITY DEFINER — flagged
--      by lint 0010. SECURITY DEFINER on a view enforces the *creator's*
--      permissions instead of the querying user's, effectively bypassing
--      RLS for anyone with SELECT on the view. Flip it to SECURITY INVOKER
--      via `ALTER VIEW … SET (security_invoker = true)` so the view runs
--      under the caller's identity. We deliberately do NOT `DROP + CREATE`
--      the view — migrations 103/177 + RPC 241 own its shape, and any
--      DROP CASCADE would force us to recreate every dependent function.
--
--   2. `public.tier_persistence_xp` is exposed to PostgREST but had RLS
--      disabled — flagged by lint 0013. The table is a static lookup
--      (board × tier × weeks → xp, badge_id), never per-user, so the
--      correct policy is "anyone can SELECT, nobody can write via REST".
--      Enable RLS and add a single permissive SELECT policy. Writes
--      continue to work from the service role (which bypasses RLS).
--
-- Both changes are safe to apply at any time — no data is moved.
-- ---------------------------------------------------------------------------

BEGIN;

-- 1) Flip exercise_library_cleaned from DEFINER → INVOKER without
--    recreating the view (shape is owned by migration 103 + 177).
ALTER VIEW public.exercise_library_cleaned
  SET (security_invoker = true);

COMMENT ON VIEW public.exercise_library_cleaned IS
  'Deduplicated exercise library. SECURITY INVOKER — RLS on exercise_library is enforced per caller.';


-- 2) tier_persistence_xp: enable RLS + public-readable policy
ALTER TABLE public.tier_persistence_xp ENABLE ROW LEVEL SECURITY;

-- Idempotent re-run: drop the policy if it already exists so the migration
-- can be re-applied safely in local dev.
DROP POLICY IF EXISTS "tier_persistence_xp is publicly readable"
  ON public.tier_persistence_xp;

-- Static reference data — every authenticated or anonymous caller needs it
-- to render tier-reward previews in the leaderboard UI. Writes are
-- intentionally not permitted via REST; seed + future changes go through
-- service_role migrations (which bypass RLS).
CREATE POLICY "tier_persistence_xp is publicly readable"
  ON public.tier_persistence_xp
  FOR SELECT
  TO authenticated, anon
  USING (true);

COMMENT ON TABLE public.tier_persistence_xp IS
  'Static lookup (board, tier, weeks) → (xp, badge_id). RLS enabled; SELECT-only for authenticated/anon roles.';

COMMIT;
