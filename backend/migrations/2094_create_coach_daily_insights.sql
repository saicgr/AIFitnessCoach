-- Migration 2094: Coach daily insights cache.
--
-- Backs the home-screen "today's coach insight" card and the Ask-Coach
-- context-aware pillar-stat insight (plan §4 + §6c). One row per
-- (user, local_date) — local_date is computed in the user's IANA tz on
-- the API side (per feedback_user_local_time_only.md), NEVER UTC.
--
-- Mirrors the shape of audio_coach_briefs (migration 1976):
--   - same RLS shape (user SELECT/UPDATE through users.auth_id join,
--     plus a service-role full-access policy for backend writes)
--   - same idempotency style (CREATE TABLE IF NOT EXISTS,
--     DROP POLICY IF EXISTS + CREATE POLICY, indexed on
--     (user_id, local_date DESC) for the latest-row lookup).
--
-- Idempotent: safe to re-run.

BEGIN;

CREATE TABLE IF NOT EXISTS public.coach_daily_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  local_date date NOT NULL,
  headline text NOT NULL,
  body text NOT NULL,
  cta_primary jsonb,
  cta_secondary jsonb,
  leading_pillar text CHECK (leading_pillar IN ('train','nourish','move','sleep','all_done')),
  source text NOT NULL DEFAULT 'home',
  stat_context text,
  generated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, local_date, source, stat_context)
);

CREATE INDEX IF NOT EXISTS idx_coach_daily_insights_user_date
  ON public.coach_daily_insights (user_id, local_date DESC);

ALTER TABLE public.coach_daily_insights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own coach_daily_insights" ON public.coach_daily_insights;
CREATE POLICY "Users view own coach_daily_insights"
  ON public.coach_daily_insights FOR SELECT
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users update own coach_daily_insights" ON public.coach_daily_insights;
CREATE POLICY "Users update own coach_daily_insights"
  ON public.coach_daily_insights FOR UPDATE
  USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Service role full access coach_daily_insights" ON public.coach_daily_insights;
CREATE POLICY "Service role full access coach_daily_insights"
  ON public.coach_daily_insights FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.coach_daily_insights IS
  'Daily Gemini-generated coach insight for the home-screen daily-score card and the Ask-Coach pillar-stat surface. One row per (user, local_date, source, stat_context); local_date is computed in the user IANA timezone.';
COMMENT ON COLUMN public.coach_daily_insights.local_date IS
  'The user-local calendar date (NOT UTC) the insight was generated for. See feedback_user_local_time_only.md — all notification/insight logic reasons in user-local time.';
COMMENT ON COLUMN public.coach_daily_insights.source IS
  'home = daily-score card insight. pillar_stat = Ask-Coach context-aware insight keyed off the tapped stat (stat_context column).';

COMMIT;
