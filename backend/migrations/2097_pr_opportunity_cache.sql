-- Migration 2097: PR opportunity cache.
--
-- Caches the "PR opportunity for today" computation so the home workout
-- card doesn't re-derive it on every render. Key = (user_id, workout_id,
-- local_date). local_date is the USER-LOCAL date the opportunity applies
-- to (per feedback_user_local_time_only.md — NEVER UTC).
--
-- Plan reference: §1b.5, §1b.8.
--
-- Idempotent: safe to re-run.

BEGIN;

CREATE TABLE IF NOT EXISTS public.pr_opportunity_today (
  user_id        uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  workout_id     uuid NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  local_date     date NOT NULL,
  exercise_name  text NOT NULL,
  current_top    text NOT NULL,
  target         text NOT NULL,
  confidence     text NOT NULL CHECK (confidence IN ('low', 'medium', 'high')),
  generated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, workout_id, local_date)
);

CREATE INDEX IF NOT EXISTS idx_pr_opportunity_today_user_date
  ON public.pr_opportunity_today (user_id, local_date DESC);

ALTER TABLE public.pr_opportunity_today ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own pr_opportunity_today" ON public.pr_opportunity_today;
CREATE POLICY "Users view own pr_opportunity_today"
  ON public.pr_opportunity_today FOR SELECT
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users insert own pr_opportunity_today" ON public.pr_opportunity_today;
CREATE POLICY "Users insert own pr_opportunity_today"
  ON public.pr_opportunity_today FOR INSERT
  WITH CHECK (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Service role full access pr_opportunity_today" ON public.pr_opportunity_today;
CREATE POLICY "Service role full access pr_opportunity_today"
  ON public.pr_opportunity_today FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.pr_opportunity_today IS
  'Cache of the PR opportunity (current top + target) computed for a (user, workout, local_date). Avoids re-running personal_records aggregation on every home-card render.';
COMMENT ON COLUMN public.pr_opportunity_today.local_date IS
  'The user-local calendar date the opportunity is for. NOT UTC. See feedback_user_local_time_only.md.';

COMMIT;
