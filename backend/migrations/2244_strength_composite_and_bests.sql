-- Migration 2244: composite strength score support (additive, idempotent)
--
-- FEATURE 4. Two parts, both purely additive on top of migration 2237 (per-gym strength):
--   1) strength_exercise_bests — per (user, exercise, gym) carry-forward all-time best
--      1RM + a decayed "effective" 1RM, so a light week doesn't crater the score.
--   2) strength_scores gains is_establishing / score_range_low / score_range_high, and the
--      latest_strength_scores + latest_strength_scores_by_gym views are re-created to also
--      project those three columns WITHOUT removing any column or the 2237 gym dimension.
--
-- Sentinel UUID is the SAME one migration 2237 uses for the NULL-gym coalesce, so the
-- combined (NULL gym) "bests" row and per-gym rows coexist in one unique index.

-- ── 1) strength_exercise_bests ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS strength_exercise_bests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL,
    exercise_key        TEXT NOT NULL,              -- normalized exercise name
    gym_profile_id      UUID REFERENCES gym_profiles(id) ON DELETE SET NULL,  -- NULL = combined
    all_time_best_1rm_kg NUMERIC NOT NULL DEFAULT 0,
    best_achieved_at    TIMESTAMPTZ,
    last_trained_at     TIMESTAMPTZ,
    effective_1rm_kg    NUMERIC NOT NULL DEFAULT 0, -- decayed best (grace 21d, t½ 120d, floor 0.65x)
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique per (user, exercise, gym) — NULL gym collapses to the 2237 sentinel so the
-- combined row and per-gym rows never collide.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_strength_exercise_bests_user_ex_gym
    ON strength_exercise_bests (
        user_id,
        exercise_key,
        COALESCE(gym_profile_id, '00000000-0000-0000-0000-000000000000'::uuid)
    );

CREATE INDEX IF NOT EXISTS idx_strength_exercise_bests_user
    ON strength_exercise_bests (user_id, last_trained_at DESC);

GRANT SELECT, INSERT, UPDATE ON strength_exercise_bests TO authenticated;

-- ── 2) strength_scores composite columns ─────────────────────────────────────────────
ALTER TABLE strength_scores
    ADD COLUMN IF NOT EXISTS is_establishing BOOLEAN DEFAULT FALSE;
ALTER TABLE strength_scores
    ADD COLUMN IF NOT EXISTS score_range_low SMALLINT;
ALTER TABLE strength_scores
    ADD COLUMN IF NOT EXISTS score_range_high SMALLINT;

-- ── 2b) Re-create the latest views ADDITIVELY ────────────────────────────────────────
-- Preserves EVERY column from migration 2237 (including its WHERE gym filter + ORDER BY)
-- and appends the three new composite columns. The combined view stays NULL-gym scoped;
-- the per-gym view keeps the gym_profile_id dimension exactly as 2237 defined it.
CREATE OR REPLACE VIEW latest_strength_scores AS
SELECT DISTINCT ON (user_id, muscle_group)
  id,
  user_id,
  muscle_group,
  strength_score,
  strength_level,
  best_exercise_name,
  best_estimated_1rm_kg,
  bodyweight_ratio,
  weekly_sets,
  weekly_volume_kg,
  previous_score,
  score_change,
  trend,
  calculated_at,
  period_start,
  period_end,
  is_establishing,
  score_range_low,
  score_range_high
FROM strength_scores
WHERE gym_profile_id IS NULL
ORDER BY user_id, muscle_group, calculated_at DESC;

CREATE OR REPLACE VIEW latest_strength_scores_by_gym AS
SELECT DISTINCT ON (user_id, muscle_group, gym_profile_id)
  id,
  user_id,
  muscle_group,
  strength_score,
  strength_level,
  best_exercise_name,
  best_estimated_1rm_kg,
  bodyweight_ratio,
  weekly_sets,
  weekly_volume_kg,
  previous_score,
  score_change,
  trend,
  calculated_at,
  period_start,
  period_end,
  gym_profile_id,
  is_establishing,
  score_range_low,
  score_range_high
FROM strength_scores
WHERE gym_profile_id IS NOT NULL
ORDER BY user_id, muscle_group, gym_profile_id, calculated_at DESC;

GRANT SELECT ON latest_strength_scores TO authenticated;
GRANT SELECT ON latest_strength_scores_by_gym TO authenticated;
