-- Migration 2088: sleep-window columns on daily_activity + health_goals table
--
-- Phase A1 of the sleep-tracking expansion.
--
-- Part 1 — daily_activity sleep-window columns
--   Migration 019 + 2086 only stored sleep DURATION buckets
--   (sleep_minutes / deep / light / rem / awake). The sleep UI also needs the
--   actual nightly window (when sleep started/ended) plus the two derived
--   quality metrics so it can render a bedtime/wake timeline and a sleep-score.
--   These are NULLABLE with no default => safe, non-blocking, no backfill;
--   older app builds that don't send them keep writing NULL (Pydantic ignores
--   the absent keys and the upsert just omits the columns).
--
--   Source metrics:
--     sleep_start / sleep_end  - HealthKit HKCategoryValueSleepAnalysis asleep
--                                interval bounds / Health Connect SleepSessionRecord
--     sleep_latency_minutes    - minutes in bed before falling asleep
--     sleep_efficiency         - asleep_time / time_in_bed, a 0.0-1.0 fraction
--
-- Part 2 — health_goals table
--   One row per user holding their personal step / active-minute / sleep-
--   duration / bedtime targets. Previously the app hard-coded 10000 steps etc.
--   keyed by users(id) (the app-internal id), exactly like daily_activity.

-- ---------------------------------------------------------------------------
-- Part 1: daily_activity sleep-window columns
-- ---------------------------------------------------------------------------
ALTER TABLE daily_activity
  ADD COLUMN IF NOT EXISTS sleep_start TIMESTAMPTZ;
ALTER TABLE daily_activity
  ADD COLUMN IF NOT EXISTS sleep_end TIMESTAMPTZ;
ALTER TABLE daily_activity
  ADD COLUMN IF NOT EXISTS sleep_latency_minutes INTEGER;
ALTER TABLE daily_activity
  ADD COLUMN IF NOT EXISTS sleep_efficiency REAL;

COMMENT ON COLUMN daily_activity.sleep_start IS 'Nightly sleep onset timestamp (HealthKit asleep interval start / Health Connect SleepSessionRecord start)';
COMMENT ON COLUMN daily_activity.sleep_end IS 'Nightly wake timestamp (HealthKit asleep interval end / Health Connect SleepSessionRecord end)';
COMMENT ON COLUMN daily_activity.sleep_latency_minutes IS 'Minutes spent in bed before falling asleep';
COMMENT ON COLUMN daily_activity.sleep_efficiency IS 'asleep_time / time_in_bed, a 0.0-1.0 fraction';

-- ---------------------------------------------------------------------------
-- Part 2: health_goals — one row per user, personal activity/sleep targets
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.health_goals (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    step_goal INTEGER DEFAULT 10000,
    active_minutes_goal INTEGER DEFAULT 30,
    sleep_duration_goal_minutes INTEGER DEFAULT 480,
    bedtime_goal TIME,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Mirrors migration 2033 (user_known_devices): health_goals.user_id is the
-- app-internal users.id, NOT auth.uid() — auth.uid() equals users.auth_id —
-- so the self-select policy joins through users. Writes go through the
-- backend's service-role Supabase client, which bypasses RLS; the policy
-- below only constrains the anon key. Enabling RLS keeps the table out of the
-- Supabase security advisor's "RLS disabled" findings.
ALTER TABLE public.health_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS health_goals_self_select ON public.health_goals;
CREATE POLICY health_goals_self_select ON public.health_goals
    FOR SELECT USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = health_goals.user_id));

-- ---------------------------------------------------------------------------
-- updated_at trigger — reuse the existing daily_activity timestamp function
-- (migration 019 defines update_daily_activity_updated_at()).
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trigger_health_goals_updated_at ON public.health_goals;
CREATE TRIGGER trigger_health_goals_updated_at
    BEFORE UPDATE ON public.health_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_activity_updated_at();

COMMENT ON TABLE public.health_goals IS 'Per-user activity/sleep targets (steps, active minutes, sleep duration, bedtime)';
COMMENT ON COLUMN public.health_goals.step_goal IS 'Daily step target; default 10000';
COMMENT ON COLUMN public.health_goals.active_minutes_goal IS 'Daily active/exercise minute target; default 30';
COMMENT ON COLUMN public.health_goals.sleep_duration_goal_minutes IS 'Nightly sleep duration target in minutes; default 480 (8h)';
COMMENT ON COLUMN public.health_goals.bedtime_goal IS 'Target bedtime, user-local time of day; nullable';
