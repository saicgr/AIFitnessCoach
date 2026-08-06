-- 2403_repoint_weekly_progress_summary_at_sets_json.sql
--
-- UI_E2E 2026-08-05 row 46 (HIGH) / row 70 (MED, same class): Home ->
-- metrics carousel -> TRAINING VOLUME page reports 0 kg / 0 sets / 0 reps
-- for every week regardless of what was logged, which then also suppresses
-- the week-over-week delta entirely ("no comparison yet").
--
-- ROOT CAUSE: `weekly_progress_summary` (096_progress_analytics.sql, last
-- rewritten by 2043_fix_weekly_progress_volume_units.sql) reads
-- `workout_logs.exercises_performance`, which is NULL on every current
-- workout_logs row — the app has written sets exclusively to
-- `workout_logs.sets_json` for months (see project note "sets_json format
-- drift"). Migration 2238 (`2238_fix_sets_json_view_parsing.sql`) already
-- re-pointed the SIBLING views (`exercise_workout_history`,
-- `muscle_group_weekly_volume`, `muscle_group_weekly_volume_by_gym`) at
-- `sets_json` with a format-robust parse across the historical key drift
-- (exercise|exercise_name|name, weight_kg|weight_lbs) — but
-- `weekly_progress_summary` was never included in that migration and was
-- left pointed at the dead `exercises_performance` column.
--
-- Verified live (QA account 1aa02a24-...): `weekly_progress_summary` returns
-- total_volume_kg=0 / total_sets=0 / total_reps=0 for both of the user's
-- logged weeks, while `muscle_group_weekly_volume` (already fixed by 2238)
-- shows 225.0 kg / 9 reps of quadriceps volume in the same week from the
-- same `workout_logs` rows — proof the two views disagree only because one
-- still reads the dead column.
--
-- FIX: rebuild `weekly_progress_summary` with the EXACT same sets_json
-- parsing CTE as `muscle_group_weekly_volume` (migration 2238) — exercise
-- name from exercise|exercise_name|name (unused here, kept only for the
-- is_completed filter's row shape), weight from weight_kg else
-- weight_lbs/2.20462, skipping is_completed=false placeholder rows — grouped
-- by user_id + week instead of muscle_group. Column list/types/grants are
-- UNCHANGED so every reader (api/v1/progress.py, get_user_progress_summary())
-- keeps working without a code change.

CREATE OR REPLACE VIEW weekly_progress_summary AS
WITH exercise_sets AS (
    SELECT
        wl.user_id,
        date_trunc('week', wl.completed_at)::date AS week_start,
        EXTRACT(WEEK FROM wl.completed_at)::int AS week_number,
        EXTRACT(YEAR FROM wl.completed_at)::int AS year,
        wl.id AS workout_log_id,
        wl.duration_minutes,
        NULLIF(set_data.value ->> 'reps', '')::numeric AS reps,
        COALESCE(
            NULLIF(set_data.value ->> 'weight_kg', '')::numeric,
            NULLIF(set_data.value ->> 'weight_lbs', '')::numeric / 2.20462
        ) AS weight_kg
    FROM workout_logs wl,
    LATERAL jsonb_array_elements(wl.sets_json) set_data(value)
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
      AND COALESCE(set_data.value ->> 'is_completed', 'true') <> 'false'
),
-- duration/workout-count must be computed per DISTINCT workout_log, not
-- fanned out by the per-set join above (that would over-count minutes by
-- the set count on every log).
per_log AS (
    SELECT DISTINCT
        wl.id AS workout_log_id,
        wl.user_id,
        date_trunc('week', wl.completed_at)::date AS week_start,
        EXTRACT(WEEK FROM wl.completed_at)::int AS week_number,
        EXTRACT(YEAR FROM wl.completed_at)::int AS year,
        wl.duration_minutes
    FROM workout_logs wl
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
)
SELECT
    pl.user_id,
    pl.week_start,
    pl.week_number,
    pl.year,
    COUNT(DISTINCT pl.workout_log_id)::int AS workouts_completed,
    COALESCE(SUM(pl.duration_minutes), 0)::int AS total_minutes,
    COALESCE(AVG(pl.duration_minutes), 0)::numeric(10,2) AS avg_duration_minutes,
    COALESCE((
        SELECT SUM(COALESCE(es.weight_kg, 0) * COALESCE(es.reps, 0))
        FROM exercise_sets es
        WHERE es.user_id = pl.user_id AND es.week_start = pl.week_start
    ), 0)::numeric(10,2) AS total_volume_kg,
    COALESCE((
        SELECT COUNT(*)
        FROM exercise_sets es
        WHERE es.user_id = pl.user_id AND es.week_start = pl.week_start
    ), 0)::int AS total_sets,
    COALESCE((
        SELECT SUM(COALESCE(es.reps, 0))
        FROM exercise_sets es
        WHERE es.user_id = pl.user_id AND es.week_start = pl.week_start
    ), 0)::int AS total_reps
FROM per_log pl
GROUP BY pl.user_id, pl.week_start, pl.week_number, pl.year;

ALTER VIEW public.weekly_progress_summary SET (security_invoker = true);

GRANT SELECT ON weekly_progress_summary TO authenticated;
