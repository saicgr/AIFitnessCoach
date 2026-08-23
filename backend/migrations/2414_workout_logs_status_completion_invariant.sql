-- 2414 — workout_logs status/completed_at invariant (E2E register row #89).
--
-- ROOT CAUSE
-- ----------
-- `workout_logs` had no constraint tying `status` to `completed_at`. A row
-- could carry `status='in_progress'` (or 'paused'/'abandoned') while
-- `completed_at` stayed populated from an earlier completion — an
-- application-level contradiction (a session that is simultaneously "not
-- done" and "finished at time X"). Live example: id 5130c008…, status
-- in_progress with completed_at set, while the parent `workouts` row still
-- read status='scheduled'/is_completed=false.
--
-- `PATCH /performance/workout-logs/{id}` (performance_db.py) is fixed
-- separately to clear `completed_at` whenever a PATCH moves status away from
-- 'completed'. This migration is the DB-level backstop the finding also asked
-- for, plus a REPAIR of the rows the defect already produced.
--
-- NOTE: `workout_logs` has no `started_at` column (verified against
-- information_schema — it is not in this table's schema at all, live or in
-- migrations). The finding's "started_at: null" appears to be an artifact of
-- whatever tool rendered the row rather than a real column on this table, so
-- this migration does not add one — inventing a column with no writer would
-- just create another permanently-null field.
--
-- NOT YET APPLIED to the live database as part of this fix — running a
-- backfill + constraint against production is a deploy step, not a local
-- code edit. Verified against a live read-only connection that 27 existing
-- rows currently violate the invariant this constraint will enforce, so the
-- repair step below (3) must run before/with part (4) or those 27 rows would
-- block the ALTER.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Back up every row this migration will touch, BEFORE touching it.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workout_logs_status_completion_backup_2414 AS
SELECT *, now() AS backed_up_at
FROM workout_logs
WHERE status <> 'completed' AND completed_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. REPAIR: a non-'completed' row must not carry a completion timestamp.
-- ---------------------------------------------------------------------------
-- These rows were never re-validated as truly finished after status moved
-- away from 'completed' (or drifted via a writer that set completed_at
-- without also setting status) — the honest state is "not completed", so the
-- stale completed_at is cleared rather than forcing status back to
-- 'completed' for a session we have no independent evidence actually ended.
UPDATE workout_logs
   SET completed_at = NULL
 WHERE status <> 'completed'
   AND completed_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. The invariant, enforced going forward.
-- ---------------------------------------------------------------------------
ALTER TABLE workout_logs
  ADD CONSTRAINT workout_logs_status_completion_check
  CHECK (
    (status = 'completed' AND completed_at IS NOT NULL)
    OR (status <> 'completed' AND completed_at IS NULL)
  );

COMMENT ON CONSTRAINT workout_logs_status_completion_check ON workout_logs IS
    'status and completed_at must agree: completed rows always carry a '
    'completion time, and no other status may (E2E register row #89 — a '
    'session was simultaneously in_progress and completed_at-populated).';

COMMIT;
