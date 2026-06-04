-- Migration 2237: Per-gym strength scores (additive)
--
-- Context: the strength score is a per-muscle bodyweight-ratio metric recalculated from the last
-- 90 days of workout_logs.sets_json, pooling every gym. We add an OPTIONAL gym dimension so the
-- score can be viewed per gym, WITHOUT changing existing behavior: the recalc keeps writing a
-- combined row (gym_profile_id = NULL) exactly as today, and additionally writes per-gym rows.
-- latest_strength_scores is scoped to the combined (NULL) rows so per-gym rows can never corrupt
-- the overall score; latest_strength_scores_by_gym exposes the per-gym rows.

ALTER TABLE strength_scores
    ADD COLUMN IF NOT EXISTS gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

-- Replace the (user_id, muscle_group, period_end) uniqueness with one that also keys on gym,
-- treating NULL (combined) as a concrete sentinel so a combined row and per-gym rows coexist.
DO $$
DECLARE
    c_name text;
BEGIN
    SELECT con.conname INTO c_name
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    WHERE rel.relname = 'strength_scores'
      AND con.contype = 'u'
      AND (
        SELECT array_agg(att.attname::text ORDER BY att.attname::text)
        FROM unnest(con.conkey) AS k(attnum)
        JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = k.attnum
      ) = ARRAY['muscle_group','period_end','user_id']
    LIMIT 1;

    IF c_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE strength_scores DROP CONSTRAINT %I', c_name);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_strength_scores_user_muscle_period_gym
    ON strength_scores(
        user_id,
        muscle_group,
        period_end,
        COALESCE(gym_profile_id, '00000000-0000-0000-0000-000000000000'::uuid)
    );

CREATE INDEX IF NOT EXISTS idx_strength_scores_user_muscle_gym
    ON strength_scores(user_id, muscle_group, gym_profile_id, calculated_at DESC);

-- Combined / overall latest score: scoped to NULL-gym rows so per-gym rows can't win the
-- DISTINCT ON. Pre-migration rows are all NULL-gym, so existing behavior is preserved exactly.
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
  period_end
FROM strength_scores
WHERE gym_profile_id IS NULL
ORDER BY user_id, muscle_group, calculated_at DESC;

-- Per-gym latest score (gym_profile_id appended last).
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
  gym_profile_id
FROM strength_scores
WHERE gym_profile_id IS NOT NULL
ORDER BY user_id, muscle_group, gym_profile_id, calculated_at DESC;

GRANT SELECT ON latest_strength_scores TO authenticated;
GRANT SELECT ON latest_strength_scores_by_gym TO authenticated;
