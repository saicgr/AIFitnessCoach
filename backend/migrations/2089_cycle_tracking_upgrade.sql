-- Migration 2089: Cycle-tracking upgrade — fertility prediction foundation
--
-- Turns the existing (non-predictive) hormonal-health feature into a real
-- menstrual + fertility tracker. Three parts:
--
--   Part 1 — cycle_periods: the canonical period-history table. One row per
--     observed period (start + optional end). Every prediction (next period,
--     ovulation, fertile window) derives from a history of these rows.
--     Replaces the ad-hoc single `hormonal_profiles.last_period_start_date`
--     and the redundant `menstrual_cycle_logs` table as the source of truth.
--
--   Part 2 — hormone_logs: columns for the fertility signals the logging UI
--     will start capturing (LH ovulation-test result, intercourse flag,
--     pregnancy-test result, a confirmed-ovulation flag). `period_flow`,
--     `cervical_mucus` and `basal_body_temperature` already exist (migration 121).
--
--   Part 3 — hormonal_profiles: tracking mode (tracking/ttc/pregnancy), BBT
--     display unit, a learned luteal-phase length, and `has_menstrual_periods`
--     (false for IUD / post-menopausal users who want symptom tracking without
--     period prediction).
--
--   Part 4 — backfill cycle_periods from the legacy menstrual_cycle_logs rows
--     and the single hormonal_profiles.last_period_start_date, so existing
--     users keep their data. menstrual_cycle_logs is left in place but is no
--     longer written (the reminder filter is repointed at cycle_periods in
--     application code).
--
-- Idempotent: IF NOT EXISTS / ADD COLUMN IF NOT EXISTS / DROP POLICY IF EXISTS
-- everywhere, ON CONFLICT DO NOTHING on the backfill. Safe to re-run.

BEGIN;

-- ---------------------------------------------------------------------------
-- Part 1: cycle_periods — canonical period-history table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cycle_periods (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    start_date  date NOT NULL,
    end_date    date,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    -- end_date, when present, cannot precede start_date
    CONSTRAINT cycle_periods_end_after_start
        CHECK (end_date IS NULL OR end_date >= start_date),
    -- one period row per user per start date (upsert key)
    CONSTRAINT cycle_periods_unique_start UNIQUE (user_id, start_date)
);

CREATE INDEX IF NOT EXISTS idx_cycle_periods_user_date
    ON public.cycle_periods (user_id, start_date DESC);

COMMENT ON TABLE public.cycle_periods IS
    'Canonical menstrual-period history. One row per observed period; the cycle prediction engine derives everything from these.';
COMMENT ON COLUMN public.cycle_periods.end_date IS
    'Last day of bleeding; NULL while the period is ongoing or the user only logged a start.';

-- Row Level Security — mirrors migration 1974 (menstrual_cycle_logs):
-- cycle_periods.user_id is the app-internal users.id, and auth.uid() equals
-- users.auth_id, so the self-policies join through users. Backend writes use
-- the service-role client, which bypasses RLS; these policies only constrain
-- the anon key and keep the table out of the Supabase RLS-disabled advisory.
ALTER TABLE public.cycle_periods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own cycle_periods" ON public.cycle_periods;
CREATE POLICY "Users view own cycle_periods"
    ON public.cycle_periods FOR SELECT
    USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users insert own cycle_periods" ON public.cycle_periods;
CREATE POLICY "Users insert own cycle_periods"
    ON public.cycle_periods FOR INSERT
    WITH CHECK (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users update own cycle_periods" ON public.cycle_periods;
CREATE POLICY "Users update own cycle_periods"
    ON public.cycle_periods FOR UPDATE
    USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users delete own cycle_periods" ON public.cycle_periods;
CREATE POLICY "Users delete own cycle_periods"
    ON public.cycle_periods FOR DELETE
    USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Service role full access cycle_periods" ON public.cycle_periods;
CREATE POLICY "Service role full access cycle_periods"
    ON public.cycle_periods FOR ALL
    USING (auth.role() = 'service_role');

-- updated_at trigger — reuse update_hormonal_updated_at() from migration 121.
DROP TRIGGER IF EXISTS trigger_cycle_periods_updated_at ON public.cycle_periods;
CREATE TRIGGER trigger_cycle_periods_updated_at
    BEFORE UPDATE ON public.cycle_periods
    FOR EACH ROW
    EXECUTE FUNCTION update_hormonal_updated_at();

-- ---------------------------------------------------------------------------
-- Part 2: hormone_logs — fertility-signal columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.hormone_logs
    ADD COLUMN IF NOT EXISTS lh_test_result text
        CHECK (lh_test_result IS NULL OR lh_test_result IN ('untested', 'negative', 'positive', 'peak'));
ALTER TABLE public.hormone_logs
    ADD COLUMN IF NOT EXISTS ovulation_test_taken boolean;
ALTER TABLE public.hormone_logs
    ADD COLUMN IF NOT EXISTS sexual_activity boolean;
ALTER TABLE public.hormone_logs
    ADD COLUMN IF NOT EXISTS pregnancy_test_result text
        CHECK (pregnancy_test_result IS NULL OR pregnancy_test_result IN ('not_taken', 'negative', 'positive'));
ALTER TABLE public.hormone_logs
    ADD COLUMN IF NOT EXISTS ovulation_confirmed boolean;

COMMENT ON COLUMN public.hormone_logs.lh_test_result IS
    'LH ovulation-test-strip reading. The surge (positive/peak) precedes ovulation by 24-36h.';
COMMENT ON COLUMN public.hormone_logs.sexual_activity IS
    'Whether intercourse occurred on this day — used by TTC mode, never shared with third parties.';
COMMENT ON COLUMN public.hormone_logs.ovulation_confirmed IS
    'Set by the prediction engine when a sympto-thermal shift confirms ovulation on this day.';

-- ---------------------------------------------------------------------------
-- Part 3: hormonal_profiles — tracking mode + prediction tuning columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.hormonal_profiles
    ADD COLUMN IF NOT EXISTS tracking_mode text DEFAULT 'tracking'
        CHECK (tracking_mode IN ('tracking', 'ttc', 'pregnancy'));
ALTER TABLE public.hormonal_profiles
    ADD COLUMN IF NOT EXISTS bbt_unit text DEFAULT 'fahrenheit'
        CHECK (bbt_unit IN ('fahrenheit', 'celsius'));
ALTER TABLE public.hormonal_profiles
    ADD COLUMN IF NOT EXISTS luteal_length_days integer
        CHECK (luteal_length_days IS NULL OR (luteal_length_days BETWEEN 9 AND 17));
ALTER TABLE public.hormonal_profiles
    ADD COLUMN IF NOT EXISTS has_menstrual_periods boolean DEFAULT true;

COMMENT ON COLUMN public.hormonal_profiles.tracking_mode IS
    'tracking = general cycle awareness; ttc = trying to conceive; pregnancy = predictions paused.';
COMMENT ON COLUMN public.hormonal_profiles.luteal_length_days IS
    'Luteal-phase length. NULL = use the 14-day default; set once learned from this user''s BBT/LH data.';
COMMENT ON COLUMN public.hormonal_profiles.has_menstrual_periods IS
    'False for IUD / post-menopausal users: symptom + BBT tracking without period/fertility prediction.';

-- ---------------------------------------------------------------------------
-- Part 4: backfill cycle_periods from legacy data
-- ---------------------------------------------------------------------------
-- 4a. From menstrual_cycle_logs (one row per logged cycle start).
INSERT INTO public.cycle_periods (user_id, start_date)
SELECT mcl.user_id, mcl.cycle_start_date
FROM public.menstrual_cycle_logs mcl
WHERE mcl.cycle_start_date IS NOT NULL
ON CONFLICT (user_id, start_date) DO NOTHING;

-- 4b. From the single hormonal_profiles.last_period_start_date.
INSERT INTO public.cycle_periods (user_id, start_date)
SELECT hp.user_id, hp.last_period_start_date
FROM public.hormonal_profiles hp
WHERE hp.last_period_start_date IS NOT NULL
ON CONFLICT (user_id, start_date) DO NOTHING;

COMMIT;
