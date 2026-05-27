-- Migration 2200: composite partial index for invalidate_workouts_after_schedule_change
-- Created: 2026-05-27
--
-- Purpose: the schedule-change cascade in api/v1/workouts/utils.py:173 runs:
--   SELECT id, scheduled_date, status
--   FROM workouts
--   WHERE user_id = ?
--     AND scheduled_date > today
--     AND is_completed = false
--
-- Pre-fix this query was unbounded and exceeded Dio's 25-second client
-- timeout for users with months of pre-scheduled rows. The fix has two
-- halves: (a) bound the query to 180 days + LIMIT 500 in code, (b) add
-- this partial index so the planner uses Index Scan instead of Seq Scan.
--
-- Partial index on (user_id, scheduled_date) WHERE is_completed = false:
--   - covers the equality predicate (user_id) + range predicate (scheduled_date)
--   - the WHERE clause keeps the index small — only incomplete rows are indexed
--   - Postgres planner picks this for the exact predicate above
--
-- Safe to re-run (IF NOT EXISTS). CONCURRENTLY avoids locking writes during
-- creation — required on a live workouts table.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_workouts_user_active_scheduled
ON workouts (user_id, scheduled_date)
WHERE is_completed = false;

COMMENT ON INDEX idx_workouts_user_active_scheduled IS
'Schedule-change cascade — used by invalidate_workouts_after_schedule_change (api/v1/workouts/utils.py). Partial: only incomplete rows. 2200.';
