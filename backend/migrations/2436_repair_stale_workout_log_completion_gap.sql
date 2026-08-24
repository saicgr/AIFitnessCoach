-- 2436 — repair stale workout_logs.completed_at / exercises_completed for
-- ALREADY-CLOSED workouts (E2E register rows #140 + #141, audit follow-up).
--
-- ROOT CAUSE
-- ----------
-- `finalize_open_logs_for_workout` / `finalize_workout_log_row`
-- (api/v1/workouts/workout_log_finalize.py) are the ONLY place that
-- reconciles a workout_logs session row's `completed_at` against its
-- parent `workouts` row and (re)derives `exercises_completed` from the
-- durable `sets_json` set list. Both were reachable ONLY from
-- `POST /workouts/{id}/complete` (crud_completion.py) — so any workout that
-- closed before this reconciliation existed, or whose /complete call raced
-- the Easy tier's fire-and-forget finalize PATCH, stays wrong forever:
-- nothing ever re-ran the repair for an already-completed workout.
--
-- `api/v1/workouts/crud_completion.py::get_workout_completion_summary` (the
-- read path, GET /{workout_id}/completion-summary) is fixed alongside this
-- migration to call `finalize_open_logs_for_workout` itself on every fetch,
-- so newly-stale rows self-heal going forward without waiting on this
-- backfill. This migration repairs the rows that are ALREADY wrong in the
-- live table right now, which the read-path fix cannot touch until someone
-- happens to re-open that workout's summary screen.
--
-- LIVE PROOF (still reproducing at HEAD, read-only connection):
--   workout_logs.id = 5130c008-b405-4705-ae98-d0282e0f4afb
--   workout_logs.completed_at = 2026-08-17 04:27:43.746077+00
--   workouts.completed_at     = 2026-08-17 05:34:12.957444+00   (66 min later)
--   workout_logs.exercises_completed = 0
--   jsonb_array_length(sets_json) = 29, spanning 2 distinct exercises with
--   10 sets explicitly not marked is_completed=false.
-- A broader read-only sweep found 23 completed-workout rows (real app data,
-- see shape guard below) still disagreeing on completed_at and/or
-- exercises_completed.
--
-- SHAPE GUARD ON exercises_completed
-- -----------------------------------
-- exercises_completed is only recomputed for rows whose sets_json actually
-- carries the real app shape (an `exercise_name` or `exercise_id` key per
-- set) — the same fields `_count_completed_exercises` in
-- workout_log_finalize.py reads. A handful of much older seed/demo rows
-- carry a different, planned-template shape (`{"name": ..., "sets": <int>}`)
-- that function also cannot read; forcing those to 0 would not be a repair,
-- it would silently invent a wrong number for rows this migration has no
-- real signal about. `completed_at` is synced for every disagreeing row
-- regardless of shape — both sides of that column are always real
-- timestamps, so there is no shape ambiguity there.
--
-- NOT YET APPLIED to the live database as part of this fix — running a
-- backfill against production is a deploy step, not a local code edit (same
-- posture as migration 2414).

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Back up every row this migration will touch, BEFORE touching it.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workout_logs_completion_reconcile_backup_2436 AS
SELECT wl.*, now() AS backed_up_at
FROM workout_logs wl
JOIN workouts w ON wl.workout_id = w.id
WHERE wl.status = 'completed'
  AND w.completed_at IS NOT NULL
  AND (
    wl.completed_at IS DISTINCT FROM w.completed_at
    OR (
      EXISTS (
        SELECT 1 FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) e
        WHERE (e ? 'exercise_name') OR (e ? 'exercise_id')
      )
      AND wl.exercises_completed IS DISTINCT FROM (
        SELECT count(DISTINCT COALESCE(elem->>'exercise_id', elem->>'exercise_name'))
        FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) elem
        WHERE COALESCE((elem->>'is_completed')::boolean, true) IS DISTINCT FROM false
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 1. REPAIR: sync completed_at to the parent workout's true completion time,
--    and recompute exercises_completed from the durable set list — but only
--    where sets_json carries the real app shape (see shape guard above).
-- ---------------------------------------------------------------------------
UPDATE workout_logs wl
SET completed_at = w.completed_at,
    exercises_completed = CASE
      WHEN EXISTS (
        SELECT 1 FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) e
        WHERE (e ? 'exercise_name') OR (e ? 'exercise_id')
      )
      THEN (
        SELECT count(DISTINCT COALESCE(elem->>'exercise_id', elem->>'exercise_name'))
        FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) elem
        WHERE COALESCE((elem->>'is_completed')::boolean, true) IS DISTINCT FROM false
      )
      ELSE wl.exercises_completed
    END
FROM workouts w
WHERE wl.workout_id = w.id
  AND wl.status = 'completed'
  AND w.completed_at IS NOT NULL
  AND (
    wl.completed_at IS DISTINCT FROM w.completed_at
    OR (
      EXISTS (
        SELECT 1 FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) e
        WHERE (e ? 'exercise_name') OR (e ? 'exercise_id')
      )
      AND wl.exercises_completed IS DISTINCT FROM (
        SELECT count(DISTINCT COALESCE(elem->>'exercise_id', elem->>'exercise_name'))
        FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) elem
        WHERE COALESCE((elem->>'is_completed')::boolean, true) IS DISTINCT FROM false
      )
    )
  );

COMMIT;

-- VERIFY (expect 0 rows — excluding the shape-ambiguous seed rows, which are
-- deliberately left untouched by the EXISTS guard above so this re-check
-- must repeat the same guard):
--   SELECT wl.id
--   FROM workout_logs wl
--   JOIN workouts w ON wl.workout_id = w.id
--   WHERE wl.status = 'completed'
--     AND w.completed_at IS NOT NULL
--     AND (
--       wl.completed_at IS DISTINCT FROM w.completed_at
--       OR (
--         EXISTS (
--           SELECT 1 FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) e
--           WHERE (e ? 'exercise_name') OR (e ? 'exercise_id')
--         )
--         AND wl.exercises_completed IS DISTINCT FROM (
--           SELECT count(DISTINCT COALESCE(elem->>'exercise_id', elem->>'exercise_name'))
--           FROM jsonb_array_elements(COALESCE(wl.sets_json, '[]'::jsonb)) elem
--           WHERE COALESCE((elem->>'is_completed')::boolean, true) IS DISTINCT FROM false
--         )
--       )
--     );
