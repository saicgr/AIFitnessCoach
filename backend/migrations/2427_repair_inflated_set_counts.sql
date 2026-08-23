-- 2427_repair_inflated_set_counts.sql
--
-- E2E register #137 — the completed-workout summary read "SETS · REPS 29 · 90"
-- for a session where the user actually logged 10 sets (5 x Cable Pulldown +
-- 5 x Cable Underhand Pulldown Wide Grips, 9 reps each = 90 reps, matching the
-- rep total exactly). `performance_logs` for this workout_log_id holds exactly
-- those 10 rows and zero rows with 0 reps — the persisted per-set log is
-- clean. Only `workout_performance_summary.total_sets` (and the underlying
-- `exercise_performance_summary` per-exercise rows) are inflated.
--
-- Root cause: `workout_logs.sets_json` also carries the zero-stamped
-- placeholder sets the "Complete workout now" safety net pads onto every
-- UNTOUCHED exercise (is_completed: false, 0 reps, 0 weight — see
-- workout_flow_mixin.dart's `completeWorkoutNow`). At the time this row was
-- written, the aggregator counted every sets_json entry toward `total_sets`
-- (a raw length) while `total_reps` was a SUM that naturally zeroes out a
-- placeholder's 0 reps — the same quantity computed two different ways for
-- the same set. `services/workout_summary_metrics.aggregate_sets` (used via
-- `resolve_set_completed`) already fixes this going forward: replaying this
-- exact session's `sets_json` through the CURRENT code recomputes 10 sets /
-- 90 reps, not 29 / 90 (verified directly against production data at
-- authoring time). This migration repairs the historical rows the old code
-- already wrote and never revisited.
--
-- Scope: rows where `total_sets` recomputed from `sets_json` (using the same
-- evidence test resolve_set_completed applies: declared complete OR real
-- reps/duration/distance) is LOWER than the stored value while `total_reps`
-- is unchanged and positive — i.e. exactly the "reps already correct, sets
-- inflated by uncounted placeholders" pattern this register describes. Two
-- rows matched in production at authoring time. Deliberately NOT touching the
-- separate rows found where `total_sets`/`total_reps` disagree in other ways
-- (undercounted or both zero) — those are a different defect and out of
-- scope here. Original values are backed up first.

BEGIN;

CREATE TABLE IF NOT EXISTS workout_performance_summary_repair_2427 (
    workout_log_id  uuid PRIMARY KEY,
    old_total_sets  integer,
    old_total_reps  integer,
    repaired_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS exercise_performance_summary_repair_2427 (
    workout_log_id  uuid,
    exercise_name   text,
    old_total_sets  integer,
    old_total_reps  integer,
    repaired_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (workout_log_id, exercise_name)
);

-- Per-(workout_log_id, exercise_name) recomputed set/rep counts, using the
-- same evidence test as services/workout_summary_metrics.resolve_set_completed.
WITH per_set AS (
    SELECT
        wl.id AS workout_log_id,
        s->>'exercise_name' AS exercise_name,
        (
            COALESCE((s->>'is_completed')::boolean, false)
            OR COALESCE((s->>'reps')::numeric, 0) > 0
            OR COALESCE((s->>'reps_completed')::numeric, 0) > 0
            OR COALESCE((s->>'set_duration_seconds')::numeric, 0) > 0
            OR COALESCE((s->>'duration_seconds')::numeric, 0) > 0
            OR COALESCE((s->>'distance_meters')::numeric, 0) > 0
        ) AS is_real,
        COALESCE((s->>'reps')::numeric, (s->>'reps_completed')::numeric, 0) AS reps
    FROM workout_logs wl
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(wl.sets_json) = 'array' THEN wl.sets_json ELSE '[]'::jsonb END
    ) AS s
),
per_exercise AS (
    SELECT
        workout_log_id,
        exercise_name,
        COUNT(*) FILTER (WHERE is_real) AS real_sets,
        SUM(reps) FILTER (WHERE is_real) AS real_reps
    FROM per_set
    WHERE exercise_name IS NOT NULL AND exercise_name <> ''
    GROUP BY workout_log_id, exercise_name
),
per_workout AS (
    SELECT workout_log_id, SUM(real_sets) AS real_sets, SUM(real_reps) AS real_reps
    FROM per_exercise
    GROUP BY workout_log_id
),
-- Scope: reps already match (nothing to fix there) and positive, sets
-- overcounted — the exact pattern register #137 describes.
in_scope AS (
    SELECT wps.workout_log_id
    FROM workout_performance_summary wps
    JOIN per_workout pw ON pw.workout_log_id = wps.workout_log_id
    WHERE wps.total_reps > 0
      AND wps.total_reps = pw.real_reps
      AND wps.total_sets > pw.real_sets
)
INSERT INTO workout_performance_summary_repair_2427 (workout_log_id, old_total_sets, old_total_reps)
SELECT wps.workout_log_id, wps.total_sets, wps.total_reps
FROM workout_performance_summary wps
JOIN in_scope i ON i.workout_log_id = wps.workout_log_id
ON CONFLICT (workout_log_id) DO NOTHING;

WITH per_set AS (
    SELECT
        wl.id AS workout_log_id,
        s->>'exercise_name' AS exercise_name,
        (
            COALESCE((s->>'is_completed')::boolean, false)
            OR COALESCE((s->>'reps')::numeric, 0) > 0
            OR COALESCE((s->>'reps_completed')::numeric, 0) > 0
            OR COALESCE((s->>'set_duration_seconds')::numeric, 0) > 0
            OR COALESCE((s->>'duration_seconds')::numeric, 0) > 0
            OR COALESCE((s->>'distance_meters')::numeric, 0) > 0
        ) AS is_real,
        COALESCE((s->>'reps')::numeric, (s->>'reps_completed')::numeric, 0) AS reps
    FROM workout_logs wl
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(wl.sets_json) = 'array' THEN wl.sets_json ELSE '[]'::jsonb END
    ) AS s
),
per_exercise AS (
    SELECT
        workout_log_id,
        exercise_name,
        COUNT(*) FILTER (WHERE is_real) AS real_sets,
        SUM(reps) FILTER (WHERE is_real) AS real_reps
    FROM per_set
    WHERE exercise_name IS NOT NULL AND exercise_name <> ''
    GROUP BY workout_log_id, exercise_name
),
per_workout AS (
    SELECT workout_log_id, SUM(real_sets) AS real_sets, SUM(real_reps) AS real_reps
    FROM per_exercise
    GROUP BY workout_log_id
),
in_scope AS (
    SELECT wps.workout_log_id
    FROM workout_performance_summary wps
    JOIN per_workout pw ON pw.workout_log_id = wps.workout_log_id
    WHERE wps.total_reps > 0
      AND wps.total_reps = pw.real_reps
      AND wps.total_sets > pw.real_sets
)
INSERT INTO exercise_performance_summary_repair_2427 (workout_log_id, exercise_name, old_total_sets, old_total_reps)
SELECT eps.workout_log_id, eps.exercise_name, eps.total_sets, eps.total_reps
FROM exercise_performance_summary eps
JOIN in_scope i ON i.workout_log_id = eps.workout_log_id
ON CONFLICT (workout_log_id, exercise_name) DO NOTHING;

-- ── exercise_performance_summary ────────────────────────────────────────────
WITH per_set AS (
    SELECT
        wl.id AS workout_log_id,
        s->>'exercise_name' AS exercise_name,
        (
            COALESCE((s->>'is_completed')::boolean, false)
            OR COALESCE((s->>'reps')::numeric, 0) > 0
            OR COALESCE((s->>'reps_completed')::numeric, 0) > 0
            OR COALESCE((s->>'set_duration_seconds')::numeric, 0) > 0
            OR COALESCE((s->>'duration_seconds')::numeric, 0) > 0
            OR COALESCE((s->>'distance_meters')::numeric, 0) > 0
        ) AS is_real,
        COALESCE((s->>'reps')::numeric, (s->>'reps_completed')::numeric, 0) AS reps
    FROM workout_logs wl
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(wl.sets_json) = 'array' THEN wl.sets_json ELSE '[]'::jsonb END
    ) AS s
),
per_exercise AS (
    SELECT
        workout_log_id,
        exercise_name,
        COUNT(*) FILTER (WHERE is_real) AS real_sets
    FROM per_set
    WHERE exercise_name IS NOT NULL AND exercise_name <> ''
    GROUP BY workout_log_id, exercise_name
)
UPDATE exercise_performance_summary eps
SET total_sets = pe.real_sets
FROM per_exercise pe
JOIN exercise_performance_summary_repair_2427 r
  ON r.workout_log_id = pe.workout_log_id AND r.exercise_name = pe.exercise_name
WHERE eps.workout_log_id = pe.workout_log_id
  AND eps.exercise_name = pe.exercise_name
  AND eps.workout_log_id = r.workout_log_id
  AND eps.exercise_name = r.exercise_name;

-- ── workout_performance_summary ─────────────────────────────────────────────
UPDATE workout_performance_summary wps
SET total_sets = agg.real_sets
FROM (
    SELECT workout_log_id, SUM(total_sets) AS real_sets
    FROM exercise_performance_summary
    WHERE workout_log_id IN (SELECT workout_log_id FROM workout_performance_summary_repair_2427)
    GROUP BY workout_log_id
) agg
WHERE wps.workout_log_id = agg.workout_log_id;

COMMIT;

-- VERIFY: select workout_log_id, total_sets, total_reps from workout_performance_summary where workout_log_id in (select workout_log_id from workout_performance_summary_repair_2427); -- expect total_sets = 10 for 5130c008-b405-4705-ae98-d0282e0f4afb (total_reps unchanged at 90)
