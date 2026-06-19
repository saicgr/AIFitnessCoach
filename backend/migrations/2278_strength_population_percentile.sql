-- 2278: Strength-Score population percentile (2026-06)
--
-- Adds an additive, nullable `population_percentile` ("stronger than X% of comparable
-- lifters") to strength_scores, computed by strength_population_standards.py and
-- persisted by strength_recalc.py. NULL where the muscle's best lift has no real
-- population standard or is machine-derived (honest — no fabricated percentile).
--
-- Also rebuilds latest_strength_scores + latest_strength_scores_by_gym to expose the
-- new column AND to switch them to security_invoker (clears the Supabase
-- security-advisor SECURITY DEFINER VIEW errors for these two views). Replay-safe.

-- 1. Additive nullable column.
ALTER TABLE public.strength_scores
    ADD COLUMN IF NOT EXISTS population_percentile NUMERIC;

-- 1b. Expand the muscle_group CHECK from 12 → 16 groups (rear_delts, obliques,
-- adductors, lower_back). Without this the recompute INSERT for the new groups
-- fails the old CHECK constraint. Applied via Supabase MCP migration
-- strength_scores_muscle_group_16.
ALTER TABLE public.strength_scores DROP CONSTRAINT IF EXISTS strength_scores_muscle_group_check;
ALTER TABLE public.strength_scores ADD CONSTRAINT strength_scores_muscle_group_check
  CHECK (muscle_group = ANY (ARRAY[
    'chest','back','shoulders','rear_delts','biceps','triceps','forearms',
    'quads','hamstrings','glutes','adductors','calves','core','obliques',
    'lower_back','traps'
  ]::text[]));

-- 2. Rebuild combined (NULL-gym) latest view with the new column + security_invoker.
DROP VIEW IF EXISTS public.latest_strength_scores;
CREATE VIEW public.latest_strength_scores
WITH (security_invoker = on) AS
 SELECT DISTINCT ON (user_id, muscle_group) id,
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
    score_range_high,
    population_percentile
   FROM strength_scores
  WHERE gym_profile_id IS NULL
  ORDER BY user_id, muscle_group, calculated_at DESC;

-- 3. Rebuild per-gym latest view with the new column + security_invoker.
DROP VIEW IF EXISTS public.latest_strength_scores_by_gym;
CREATE VIEW public.latest_strength_scores_by_gym
WITH (security_invoker = on) AS
 SELECT DISTINCT ON (user_id, muscle_group, gym_profile_id) id,
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
    score_range_high,
    population_percentile
   FROM strength_scores
  WHERE gym_profile_id IS NOT NULL
  ORDER BY user_id, muscle_group, gym_profile_id, calculated_at DESC;
