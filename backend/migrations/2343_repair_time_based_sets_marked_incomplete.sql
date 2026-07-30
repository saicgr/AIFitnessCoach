-- 2343_repair_time_based_sets_marked_incomplete.sql
--
-- E2E register #75 — "time-based sets persist with is_completed = false while
-- rep-based sets persist true", and #73 — "summary says 9 sets, sets_json says
-- 13".
--
-- Root cause (client): both set writers classify a set as an unlogged
-- placeholder with
--     reps <= 0 && weight <= 0 && distance <= 0 && extraMetrics.isEmpty
-- (mobile/flutter/lib/screens/workout/easy/easy_persistence_helpers.dart and
-- .../mixins/set_logging_mixin.dart). Hold time is missing from that test, so a
-- plank / wall sit / dead hang — reps 0, load 0, but a real 30 s hold — is
-- persisted `is_completed: false` in BOTH stores. The summary then drops it
-- from the set, rep and volume totals: 13 logged sets rendered as "9".
--
-- The server write chokepoints now resolve completion themselves
-- (services/workout_summary_metrics.resolve_set_completed — recorded work,
-- including hold time or distance, means the set was performed; a client
-- `true` is never downgraded), so new writes are correct regardless of which
-- client wrote them. This migration repairs the rows already stored.
--
-- Scope in production at authoring time: 4 `performance_logs` rows and 4
-- `workout_logs.sets_json` entries. Original values are backed up first.

BEGIN;

-- ── performance_logs ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS performance_logs_completion_repair_2343 (
    performance_log_id uuid PRIMARY KEY,
    workout_log_id     uuid,
    exercise_name      text,
    set_number         integer,
    old_is_completed   boolean,
    repaired_at        timestamptz NOT NULL DEFAULT now()
);

INSERT INTO performance_logs_completion_repair_2343
    (performance_log_id, workout_log_id, exercise_name, set_number, old_is_completed)
SELECT id, workout_log_id, exercise_name, set_number, is_completed
FROM performance_logs
WHERE is_completed IS DISTINCT FROM TRUE
  AND (
        COALESCE(reps_completed, 0) > 0
     OR COALESCE(weight_kg, 0) > 0
     OR COALESCE(set_duration_seconds, 0) > 0
     OR COALESCE(distance_meters, 0) > 0
     OR (metrics IS NOT NULL AND metrics <> '{}'::jsonb)
  )
ON CONFLICT (performance_log_id) DO NOTHING;

UPDATE performance_logs
SET is_completed = TRUE
WHERE is_completed IS DISTINCT FROM TRUE
  AND (
        COALESCE(reps_completed, 0) > 0
     OR COALESCE(weight_kg, 0) > 0
     OR COALESCE(set_duration_seconds, 0) > 0
     OR COALESCE(distance_meters, 0) > 0
     OR (metrics IS NOT NULL AND metrics <> '{}'::jsonb)
  );

-- ── workout_logs.sets_json ──────────────────────────────────────────────────
-- The summary screen aggregates this blob directly (summary_hero_stats.dart
-- `_aggregateSetsJson`), so repairing performance_logs alone would leave the
-- headline "Sets · Reps" wrong.
CREATE TABLE IF NOT EXISTS workout_logs_sets_json_repair_2343 (
    workout_log_id uuid PRIMARY KEY,
    old_sets_json  jsonb,
    repaired_at    timestamptz NOT NULL DEFAULT now()
);

WITH affected AS (
    SELECT DISTINCT wl.id
    FROM workout_logs wl,
         jsonb_array_elements(
             CASE WHEN jsonb_typeof(wl.sets_json) = 'array'
                  THEN wl.sets_json ELSE '[]'::jsonb END
         ) s
    WHERE (s->>'is_completed') = 'false'
      AND (
            COALESCE((s->>'set_duration_seconds')::numeric, 0) > 0
         OR COALESCE((s->>'distance_meters')::numeric, 0) > 0
      )
)
INSERT INTO workout_logs_sets_json_repair_2343 (workout_log_id, old_sets_json)
SELECT wl.id, wl.sets_json
FROM workout_logs wl
JOIN affected a ON a.id = wl.id
ON CONFLICT (workout_log_id) DO NOTHING;

UPDATE workout_logs wl
SET sets_json = repaired.sets_json
FROM (
    SELECT wl2.id,
           jsonb_agg(
               CASE
                   WHEN (s->>'is_completed') = 'false'
                    AND (
                          COALESCE((s->>'set_duration_seconds')::numeric, 0) > 0
                       OR COALESCE((s->>'distance_meters')::numeric, 0) > 0
                        )
                   THEN s || '{"is_completed": true}'::jsonb
                   ELSE s
               END
               ORDER BY ord
           ) AS sets_json
    FROM workout_logs wl2,
         LATERAL jsonb_array_elements(
             CASE WHEN jsonb_typeof(wl2.sets_json) = 'array'
                  THEN wl2.sets_json ELSE '[]'::jsonb END
         ) WITH ORDINALITY AS t(s, ord)
    WHERE wl2.id IN (SELECT workout_log_id FROM workout_logs_sets_json_repair_2343)
    GROUP BY wl2.id
) repaired
WHERE wl.id = repaired.id;

COMMIT;
