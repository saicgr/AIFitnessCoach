-- Migration 2093: TDEE hold snapshots (cycle-aware 7-day pre-period hold)
--
-- Phase E of the cycle screen overhaul (MacroFactor request 1.3). When a
-- menstrual-tracking user enters their pre-period / period / post-period
-- window, the adaptive TDEE service freezes the daily calorie target to
-- the value it held at window entry so transient luteal water weight
-- never gets read as fat gain and trigger a wrong calorie cut.
--
-- One row per (user, hold window). The PK contract is
-- (user_id, hold_window_start_date) — NOT (user_id, cycle_start_date) —
-- because on short (21-day) cycles the post-period window of cycle N can
-- overlap the pre-period window of cycle N+1, and both need their own
-- snapshot row.
--
-- Snapshot at entry stores BOTH the calorie target AND whatever luteal
-- cycle_calorie_delta was already baked into that target, so when the
-- caller honours the hold it returns the frozen pair and never
-- double-applies a fresh luteal bump on top.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS + CREATE POLICY guards. Safe to
-- re-run.

BEGIN;

CREATE TABLE IF NOT EXISTS public.tdee_hold_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    hold_window_start_date DATE NOT NULL,
    hold_window_end_date DATE NOT NULL,
    hold_reason TEXT NOT NULL CHECK (hold_reason IN ('pre_period', 'menstrual', 'post_period')),
    calorie_target_at_entry INTEGER NOT NULL,
    cycle_calorie_delta_at_entry INTEGER NOT NULL DEFAULT 0,
    snapshot_phase TEXT,
    snapshot_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, hold_window_start_date)
);

CREATE INDEX IF NOT EXISTS idx_tdee_hold_user_today
    ON public.tdee_hold_snapshots (user_id, hold_window_start_date DESC);

COMMENT ON TABLE public.tdee_hold_snapshots IS
    'Frozen calorie-target snapshots taken at the entry of each cycle-aware TDEE hold window (pre-period -7d → end of period + 3d). One row per (user, hold_window_start_date); keyed on the window start, not the cycle start, so overlapping windows on short 21-day cycles each get their own row.';
COMMENT ON COLUMN public.tdee_hold_snapshots.calorie_target_at_entry IS
    'The daily calorie target the user was on the moment the hold window opened. Returned verbatim for every day inside the window so transient luteal water weight cannot drive a cut.';
COMMENT ON COLUMN public.tdee_hold_snapshots.cycle_calorie_delta_at_entry IS
    'Whatever luteal/menstrual bump was baked into calorie_target_at_entry. Returned verbatim during the hold so the caller never applies a second live bump on top of the snapshot (double-bump suppression).';

ALTER TABLE public.tdee_hold_snapshots ENABLE ROW LEVEL SECURITY;

-- RLS mirrors cycle_periods (migration 2089 lines 58-88): user_id is the
-- app-internal users.id; auth.uid() equals users.auth_id, so policies
-- join through users. Backend writes use the service-role client which
-- bypasses RLS — these policies constrain the anon key only and keep the
-- table out of the Supabase RLS-disabled advisory.

DROP POLICY IF EXISTS "Users view own tdee_hold_snapshots" ON public.tdee_hold_snapshots;
CREATE POLICY "Users view own tdee_hold_snapshots"
    ON public.tdee_hold_snapshots FOR SELECT
    USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users insert own tdee_hold_snapshots" ON public.tdee_hold_snapshots;
CREATE POLICY "Users insert own tdee_hold_snapshots"
    ON public.tdee_hold_snapshots FOR INSERT
    WITH CHECK (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users update own tdee_hold_snapshots" ON public.tdee_hold_snapshots;
CREATE POLICY "Users update own tdee_hold_snapshots"
    ON public.tdee_hold_snapshots FOR UPDATE
    USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Users delete own tdee_hold_snapshots" ON public.tdee_hold_snapshots;
CREATE POLICY "Users delete own tdee_hold_snapshots"
    ON public.tdee_hold_snapshots FOR DELETE
    USING (auth.uid() = (SELECT auth_id FROM public.users WHERE id = user_id));

DROP POLICY IF EXISTS "Service role full access tdee_hold_snapshots" ON public.tdee_hold_snapshots;
CREATE POLICY "Service role full access tdee_hold_snapshots"
    ON public.tdee_hold_snapshots FOR ALL
    USING (auth.role() = 'service_role');

COMMIT;
