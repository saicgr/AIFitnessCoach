-- 2043_fix_weekly_progress_volume_units.sql
--
-- Issue 9: Progress Charts > Volume tab renders as a blank gray box for
-- users who report 76 workouts but 0 kg of volume.
--
-- Root cause: `weekly_progress_summary` (096_progress_analytics.sql) reads
-- `set_data->>'weight_kg'` from `workout_logs.exercises_performance`. Some
-- clients have shipped sets where weight is keyed under `weight` or
-- `weight_lb` instead, so the COALESCE'd `weight_kg` lookup returns NULL
-- and the row's volume aggregates to 0 even though the workout count is
-- non-zero.
--
-- Fix: rebuild the view to fall back across the legacy keys and convert
-- pounds to kilograms (× 0.45359237) when only the lb value is present.
-- Same change applied to `muscle_group_weekly_volume` so the strength
-- chart benefits from the same coverage.

CREATE OR REPLACE VIEW weekly_progress_summary AS
SELECT
  user_id,
  DATE_TRUNC('week', completed_at)::date as week_start,
  EXTRACT(WEEK FROM completed_at)::int as week_number,
  EXTRACT(YEAR FROM completed_at)::int as year,
  COUNT(DISTINCT workout_log_id) as workouts_completed,
  COALESCE(SUM(duration_minutes), 0)::int as total_minutes,
  COALESCE(AVG(duration_minutes), 0)::numeric(10,2) as avg_duration_minutes,
  COALESCE(SUM(
    (SELECT COALESCE(SUM(
        COALESCE(
          (set_data->>'weight_kg')::numeric,
          (set_data->>'weight')::numeric,
          ((set_data->>'weight_lb')::numeric * 0.45359237),
          0
        ) * COALESCE(
          (set_data->>'reps')::numeric,
          (set_data->>'reps_completed')::numeric,
          0
        )
     ), 0)
     FROM jsonb_array_elements(exercises_performance) as exercise,
          jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::numeric(10,2) as total_volume_kg,
  COALESCE(SUM(
    (SELECT COUNT(*)
     FROM jsonb_array_elements(exercises_performance) as exercise,
          jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_sets,
  COALESCE(SUM(
    (SELECT COALESCE(SUM(
        COALESCE(
          (set_data->>'reps')::numeric,
          (set_data->>'reps_completed')::numeric,
          0
        )
      ), 0)
     FROM jsonb_array_elements(exercises_performance) as exercise,
          jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_reps
FROM workout_logs
WHERE completed_at IS NOT NULL
  AND exercises_performance IS NOT NULL
GROUP BY user_id, DATE_TRUNC('week', completed_at), EXTRACT(WEEK FROM completed_at), EXTRACT(YEAR FROM completed_at);

GRANT SELECT ON weekly_progress_summary TO authenticated;

-- Same fix applied to the muscle-group breakdown so the Strength tab and
-- volume-by-muscle chart pick up legacy lb-keyed sets too.
CREATE OR REPLACE VIEW muscle_group_weekly_volume AS
SELECT
  wl.user_id,
  DATE_TRUNC('week', wl.completed_at)::date as week_start,
  LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other')) as muscle_group,
  COUNT(DISTINCT wl.id) as workouts,
  COALESCE(SUM(
    (SELECT COUNT(*)
     FROM jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_sets,
  COALESCE(SUM(
    (SELECT COALESCE(SUM(
        COALESCE(
          (set_data->>'reps')::numeric,
          (set_data->>'reps_completed')::numeric,
          0
        )
      ), 0)
     FROM jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_reps,
  COALESCE(SUM(
    (SELECT COALESCE(SUM(
        COALESCE(
          (set_data->>'weight_kg')::numeric,
          (set_data->>'weight')::numeric,
          ((set_data->>'weight_lb')::numeric * 0.45359237),
          0
        ) * COALESCE(
          (set_data->>'reps')::numeric,
          (set_data->>'reps_completed')::numeric,
          0
        )
     ), 0)
     FROM jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::numeric(10,2) as total_volume_kg,
  COALESCE(MAX(
    (SELECT MAX(
        COALESCE(
          (set_data->>'weight_kg')::numeric,
          (set_data->>'weight')::numeric,
          ((set_data->>'weight_lb')::numeric * 0.45359237)
        )
      )
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE COALESCE(
       set_data->>'weight_kg',
       set_data->>'weight',
       set_data->>'weight_lb'
     ) IS NOT NULL)
  ), 0)::numeric(10,2) as max_weight_kg
FROM workout_logs wl,
     jsonb_array_elements(wl.exercises_performance) as exercise
WHERE wl.completed_at IS NOT NULL
  AND wl.exercises_performance IS NOT NULL
GROUP BY wl.user_id, DATE_TRUNC('week', wl.completed_at), LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other'))
ORDER BY week_start DESC, muscle_group;

GRANT SELECT ON muscle_group_weekly_volume TO authenticated;
