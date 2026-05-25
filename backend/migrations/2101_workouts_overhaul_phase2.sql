-- 2101_workouts_overhaul_phase2.sql
-- Phase 2 of the workouts overhaul: per-set RPE/RIR/tempo capture,
-- weekly-plan stability lock, unified ProgressionStyle enum, mesocycle state.
--
-- The audit found three competing ProgressionStyle systems
-- (Python enum CONSERVATIVE/MODERATE/AGGRESSIVE, mig 089 leverage_first/etc,
--  Flutter RepProgressionType 8-value). This migration aligns the DB on the
-- 8-value Flutter enum since it matches generation primitives.
--
-- Adds the dead-code mesocycle_planner.dart state into a real table so the
-- backend can read it and pass deload_week flags into Gemini + the validator.

-- 1. RPE / RIR / tempo on set_rep_accuracy ------------------------------------
ALTER TABLE set_rep_accuracy
  ADD COLUMN IF NOT EXISTS rpe   numeric,        -- 5.0–10.0, half-step
  ADD COLUMN IF NOT EXISTS rir   smallint,       -- reps in reserve, 0–5+
  ADD COLUMN IF NOT EXISTS tempo text;           -- e.g. "3-1-1-0" eccentric-pause-concentric-pause

COMMENT ON COLUMN set_rep_accuracy.rpe   IS 'User-reported Rate of Perceived Exertion at set completion (5.0-10.0). Drives auto-regulation.';
COMMENT ON COLUMN set_rep_accuracy.rir   IS 'Reps in Reserve (0=failure, 5+=very easy). Inverse of RPE.';
COMMENT ON COLUMN set_rep_accuracy.tempo IS 'Logged or prescribed rep cadence string (eccentric-pause-concentric-pause), e.g. "3-1-1-0".';


-- 2. Weekly-plan stability lock ----------------------------------------------
-- Today, /workouts/today can re-trigger generation on each open. The lock
-- makes a given week deterministic: re-gen happens only on explicit user
-- intent or red-flag autoregulation, not on every screen refresh.
ALTER TABLE weekly_plans
  ADD COLUMN IF NOT EXISTS plan_version       int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS plan_locked        boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS regen_requested_at timestamptz;

COMMENT ON COLUMN weekly_plans.plan_version       IS 'Monotonically increments each regeneration. Clients pass this when caching.';
COMMENT ON COLUMN weekly_plans.plan_locked        IS 'When true, /workouts/today returns the existing plan verbatim. Set false to allow next regen.';
COMMENT ON COLUMN weekly_plans.regen_requested_at IS 'When the most recent regen was requested. Used by red-flag autoregulation to throttle.';


-- 3. Unified ProgressionStyle enum -------------------------------------------
-- Align user_rep_range_preferences with the Flutter RepProgressionType.
-- Existing rows are mapped: leverage_first/load_first/balanced/technique_first
-- all collapse to 'straight' (which is what they effectively were anyway).
ALTER TABLE user_rep_range_preferences
  ADD COLUMN IF NOT EXISTS progression_style text NOT NULL DEFAULT 'straight';

ALTER TABLE user_rep_range_preferences
  DROP CONSTRAINT IF EXISTS user_rep_range_preferences_progression_style_check;

ALTER TABLE user_rep_range_preferences
  ADD CONSTRAINT user_rep_range_preferences_progression_style_check
  CHECK (progression_style IN (
    'straight',          -- 3x10 @ same weight
    'pyramid',           -- ascending weight, descending reps
    'reverse_pyramid',   -- top set first, descending
    'double_progression',-- add reps until top, then add weight
    'rpt',               -- rest-pause top set + back-off
    'wave',              -- 3-week wave loading
    'cluster',           -- intra-set rest blocks
    'amrap'              -- as many reps as possible
  ));

COMMENT ON COLUMN user_rep_range_preferences.progression_style IS
  'Canonical 8-value enum (Phase 2.F): matches Flutter RepProgressionType. Was mismatched across Python enum + mig 089 string set.';


-- 4. Mesocycle state ---------------------------------------------------------
-- Wire the dead Flutter mesocycle_planner.dart into a real persisted state
-- so the backend can read the week-of-mesocycle and pass deload_week=true
-- into Gemini + the validator.
CREATE TABLE IF NOT EXISTS mesocycle_state (
  user_id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_start_date  date    NOT NULL DEFAULT current_date,
  weeks_per_cycle   int     NOT NULL DEFAULT 4 CHECK (weeks_per_cycle BETWEEN 3 AND 8),
  current_week      int     NOT NULL DEFAULT 1 CHECK (current_week BETWEEN 1 AND 8),
  scheme            text    NOT NULL DEFAULT 'linear' CHECK (scheme IN ('linear','dup','block','conjugate')),
  is_deload_week    boolean NOT NULL DEFAULT false,
  last_forced_deload_at timestamptz,
  -- Red-flag autoregulation trigger reasons (audit trail)
  last_trigger      jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE mesocycle_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mesocycle_state_user_isolated ON mesocycle_state;
CREATE POLICY mesocycle_state_user_isolated ON mesocycle_state
  FOR ALL
  USING      (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.set_mesocycle_state_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_mesocycle_state_updated_at ON mesocycle_state;
CREATE TRIGGER trg_mesocycle_state_updated_at
  BEFORE UPDATE ON mesocycle_state
  FOR EACH ROW
  EXECUTE FUNCTION public.set_mesocycle_state_updated_at();

COMMENT ON TABLE mesocycle_state IS
  'Per-user periodization state — week within current mesocycle, scheme (linear/DUP/block/conjugate), deload flag. Read by holistic_plan_service before Gemini generation. Phase 2.E.';


-- 5. Daily soreness reuse — readiness_scores already covers this via Hooper
--    index. No new table needed; user_state_assembler reads from there.

-- 6. user_exercise_state (rolling avg RPE + e1RM + SFR per user × exercise)
--    used by 2.D auto-regulation. JSONB-shaped for forward-compat.
CREATE TABLE IF NOT EXISTS user_exercise_state (
  user_id            uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id        text NOT NULL,
  rolling_rpe_7d     numeric,
  rolling_rir_7d     numeric,
  e1rm_kg            numeric,
  e1rm_calculated_at timestamptz,
  last_set_at        timestamptz,
  sfr_score          numeric,          -- Stimulus-to-Fatigue Ratio learned per user
  plateau_flag       boolean NOT NULL DEFAULT false,
  plateau_since      date,
  notes              text,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, exercise_id)
);

ALTER TABLE user_exercise_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_exercise_state_isolated ON user_exercise_state;
CREATE POLICY user_exercise_state_isolated ON user_exercise_state
  FOR ALL
  USING      (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_exercise_state_plateau
  ON user_exercise_state(user_id, plateau_flag) WHERE plateau_flag = true;

COMMENT ON TABLE user_exercise_state IS
  'Per-(user,exercise) rolling stats: 7-day avg RPE/RIR, e1RM, learned SFR, plateau flag. Read by validator + adaptive_workout_service. Phase 2.D/2.I.';
