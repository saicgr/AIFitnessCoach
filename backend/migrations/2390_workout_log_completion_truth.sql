-- 2390 — workout_logs completion truth: default, trigger guard, and repair.
--
-- ROOT CAUSE (E2E register row #1)
-- --------------------------------
-- `workout_logs.status` DEFAULTs to 'completed'. Migration 2256 installed
-- `trg_sync_workout_completion`, which fires on status='completed' and does an
-- UNCONDITIONAL `UPDATE workouts SET is_completed = true` with no regard for
-- whether the log holds any sets.
--
-- Every client tier that creates the session row on the user's FIRST set with
-- `sets_json = '[]'` therefore marked the ENTIRE workout finished after one
-- set. The app code was patched to always send an explicit status, but the
-- CAUSE below it was untouched: any writer that omits `status` still gets
-- 'completed' from the column default (POST /sync/bulk upserted the offline
-- queue's payload verbatim), and any writer that sends status='completed' with
-- an empty set list still flips `workouts.is_completed`.
--
-- Three parts:
--   1. Flip the column DEFAULT to 'in_progress'. A session starts open.
--   2. Add an empty-sets guard to the trigger's WHEN clause. An empty set list
--      is by definition not a finished session, so it can never complete a
--      workout — no matter which writer produced the row.
--   3. Repair the rows the defect already wrote, backing them up first.
--
-- Part 3 is a REPAIR, not a deletion. Every one of the 18 corrupt logs has its
-- real sets sitting in `performance_logs` (the durable per-set store), so the
-- repair REBUILDS `sets_json` from there — the same reconstruction
-- api/v1/workouts/workout_log_finalize.py does at runtime. Only workouts with
-- NO evidence of finalization at all (no non-empty completed log, no summary,
-- no feedback, no workout_completions row) lose `is_completed`.
--
-- Safe on a live table: two ALTERs that touch catalog only (SET DEFAULT and
-- CREATE OR REPLACE TRIGGER — no table rewrite, no data scan), plus row-scoped
-- UPDATEs against a 111-row table.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Back up every row this migration touches, BEFORE touching it.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workout_logs_empty_sets_backup_2390 AS
SELECT *, now() AS backed_up_at
FROM workout_logs
WHERE status = 'completed'
  AND jsonb_typeof(sets_json) = 'array'
  AND jsonb_array_length(sets_json) = 0;

CREATE TABLE IF NOT EXISTS workouts_false_completion_backup_2390 AS
SELECT w.*, now() AS backed_up_at
FROM workouts w
WHERE w.is_completed = true
  AND EXISTS (
        SELECT 1 FROM workout_logs l
         WHERE l.workout_id = w.id
           AND l.status = 'completed'
           AND jsonb_typeof(l.sets_json) = 'array'
           AND jsonb_array_length(l.sets_json) = 0
      );

-- ---------------------------------------------------------------------------
-- 1. The column default. A session starts OPEN.
-- ---------------------------------------------------------------------------
ALTER TABLE workout_logs ALTER COLUMN status SET DEFAULT 'in_progress';

-- ---------------------------------------------------------------------------
-- 2. Empty-sets guard on the completion trigger.
-- ---------------------------------------------------------------------------
-- `jsonb_typeof` is checked first: `jsonb_array_length` errors on a non-array,
-- and a WHEN clause that raises would abort the writer's transaction.
DROP TRIGGER IF EXISTS trg_sync_workout_completion ON workout_logs;
CREATE TRIGGER trg_sync_workout_completion
    AFTER INSERT OR UPDATE OF status, sets_json ON workout_logs
    FOR EACH ROW
    WHEN (
        NEW.status::text = 'completed'
        AND NEW.workout_id IS NOT NULL
        AND jsonb_typeof(NEW.sets_json) = 'array'
        AND jsonb_array_length(NEW.sets_json) > 0
    )
    EXECUTE FUNCTION sync_workout_completion_from_log();

COMMENT ON TRIGGER trg_sync_workout_completion ON workout_logs IS
    'Mirrors a finished session onto workouts.is_completed. Guarded on a '
    'NON-EMPTY sets_json: the Easy/watch tiers create the session row on the '
    'first set with sets_json=''[]'', and without this guard that flipped the '
    'whole workout complete (E2E register #1, migration 2390). Also fires on '
    'sets_json so a server-side finalize backfill (workout_log_finalize.py) '
    'still mirrors completion once the real sets land.';

-- ---------------------------------------------------------------------------
-- 3a. REPAIR the 18 corrupt logs: restore the sets, reopen the status.
-- ---------------------------------------------------------------------------
-- These rows were NEVER finalized — `sets_json` is only ever written by the
-- finish/finalize call, so an empty array means the session was abandoned or
-- the finalize was lost. Their 'completed' status came purely from the column
-- default fixed in part 1, so it is not evidence of anything.
--
--   * sets_json is REBUILT from performance_logs (the durable per-set store)
--     using the same field mapping as build_sets_json_from_performance_logs()
--     — nothing the user logged is lost. jsonb_strip_nulls keeps absent fields
--     absent rather than inventing values.
--   * status goes to 'in_progress' — the honest state of a session that was
--     never closed.
--
-- Both in ONE statement so the row never transiently looks like a finished
-- session with real sets (which would re-fire the completion trigger).
WITH rebuilt AS (
    SELECT l.id AS log_id,
           jsonb_agg(
               jsonb_strip_nulls(
                   jsonb_build_object(
                       'exercise_name',        p.exercise_name,
                       'exercise_id',          p.exercise_id,
                       'set_number',           p.set_number,
                       'reps',                 p.reps_completed,
                       'reps_completed',       p.reps_completed,
                       'weight_kg',            p.weight_kg,
                       'is_completed',         COALESCE(p.is_completed, true),
                       'set_type',             p.set_type,
                       'rpe',                  p.rpe,
                       'rir',                  p.rir,
                       'set_duration_seconds', p.set_duration_seconds,
                       'distance_meters',      p.distance_meters,
                       'logging_mode',         p.logging_mode,
                       'completed_at',         p.recorded_at,
                       'repaired_by',          'migration_2390'
                   )
               )
               ORDER BY p.recorded_at, p.set_number
           ) AS sets
      FROM workout_logs l
      JOIN performance_logs p ON p.workout_log_id = l.id
     WHERE l.status = 'completed'
       AND jsonb_typeof(l.sets_json) = 'array'
       AND jsonb_array_length(l.sets_json) = 0
     GROUP BY l.id
)
UPDATE workout_logs l
   SET sets_json = COALESCE(r.sets, l.sets_json),
       status    = 'in_progress'
  FROM workout_logs_empty_sets_backup_2390 b
  LEFT JOIN rebuilt r ON r.log_id = b.id
 WHERE l.id = b.id;

-- ---------------------------------------------------------------------------
-- 3b. REPAIR: un-complete the workouts that only the defect ever completed.
-- ---------------------------------------------------------------------------
-- A workout is legitimately complete when SOMETHING finalized it: a session log
-- that carried its sets when it was written, a generated summary, post-workout
-- feedback, or a workout_completions row. The rows below have NONE of those —
-- their sole `is_completed = true` came from `trg_sync_workout_completion`
-- firing on a first-set log with an empty set list.
--
-- Deliberately conservative. Scoped to rows the trigger could have produced
-- (`completion_method = 'tracked'`); a manually marked-done workout is the
-- user's own assertion and is never touched. A workout that has a summary or
-- feedback row DID run the finish flow and keeps its completion even though its
-- log was one of the 18 (e.g. 290d1a60, 37 logged sets + summary + feedback).
UPDATE workouts w
   SET is_completed         = false,
       completed_at         = NULL,
       completion_method    = NULL,
       status               = CASE WHEN w.status = 'completed'
                                   THEN 'scheduled' ELSE w.status END,
       last_modified_at     = now(),
       last_modified_method = 'repair_2390_false_completion'
 WHERE w.is_completed = true
   AND w.completion_method = 'tracked'
   AND EXISTS (
         SELECT 1 FROM workout_logs_empty_sets_backup_2390 b
          WHERE b.workout_id = w.id
       )
   AND NOT EXISTS (
         SELECT 1 FROM workout_logs l
          WHERE l.workout_id = w.id
            AND l.status = 'completed'
       )
   AND NOT EXISTS (SELECT 1 FROM workout_summaries s WHERE s.workout_id = w.id)
   AND NOT EXISTS (SELECT 1 FROM workout_feedback f WHERE f.workout_id = w.id)
   AND NOT EXISTS (SELECT 1 FROM workout_completions c WHERE c.workout_id = w.id);

COMMIT;
