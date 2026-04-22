-- Migration 1961 — Backfill missing `workout_complete` XP transactions.
--
-- Context
-- =======
-- The workout-complete XP award (100 XP/day, source='daily_goal_workout_complete')
-- was previously driven by the Flutter client calling POST /xp/award-goal-xp
-- after a successful POST /workouts/{id}/complete. If the client crashed,
-- lost network between the two calls, or the user force-quit the app, the
-- workout was marked completed but the XP transaction was never inserted.
--
-- Visible symptom (Apr 2026): the Discover weekly leaderboard showed users
-- like `okok` on the board at rank N with 0 weekly XP — the board gate is
-- "1 completed workout this week", but the XP accrual never fired.
--
-- Server-side fix (see backend/api/v1/workouts/crud_completion.py — the
-- `/complete` endpoint now calls `award_xp` inline + idempotent) prevents
-- new occurrences. This migration backfills past damage.
--
-- Idempotency
-- ===========
-- Safe to run multiple times. The INSERT WHERE NOT EXISTS clause ensures
-- a workout_log day that already has a workout_complete xp_transactions
-- row is never double-counted. Running twice is a no-op on the second run.
--
-- Scope
-- =====
-- Grants 100 XP per day per user that had at least one completed workout
-- that day and no matching xp_transactions row (matches the "once per day"
-- policy in goal_xp_amounts["workout_complete"] at api/v1/xp.py:517). The
-- trust_level multiplier is NOT retroactively applied — backfills are
-- flat 100 XP to keep the migration deterministic.

BEGIN;

-- 1. Diagnostic: count the affected user/day tuples BEFORE inserting.
--    Useful in a `psql` session — the result is discarded in a migration.
DO $$
DECLARE
  v_affected int;
BEGIN
  SELECT COUNT(*) INTO v_affected FROM (
    SELECT DISTINCT wl.user_id, DATE(wl.completed_at)
    FROM workout_logs wl
    WHERE wl.status = 'completed'
      AND wl.completed_at IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM xp_transactions xt
        WHERE xt.user_id = wl.user_id
          AND xt.source = 'daily_goal_workout_complete'
          AND DATE(xt.created_at) = DATE(wl.completed_at)
      )
  ) AS affected_days;
  RAISE NOTICE 'backfill_workout_xp: % user-day tuples to backfill', v_affected;
END$$;

-- 2. Ensure every affected user has a user_xp seed row (award_xp prereq).
INSERT INTO user_xp (user_id, total_xp, current_level, title, trust_level)
SELECT DISTINCT wl.user_id, 0, 1, 'Novice', 1
FROM workout_logs wl
WHERE wl.status = 'completed'
  AND wl.completed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM user_xp ux WHERE ux.user_id = wl.user_id
  )
ON CONFLICT (user_id) DO NOTHING;

-- 3. Insert the missing XP transactions. Backdate `created_at` to the
--    workout's completion time so weekly leaderboard aggregations that
--    bucket by `DATE_TRUNC('week', xt.created_at)` place the XP in the
--    correct week — critical for rebuilding historical leaderboards.
--    The `source_id` is the first workout_log.id of the day so the row
--    remains traceable to the event that earned it.
INSERT INTO xp_transactions (user_id, xp_amount, source, source_id, description, is_verified, created_at)
SELECT
  first_log.user_id,
  100 AS xp_amount,
  'daily_goal_workout_complete' AS source,
  first_log.workout_log_id AS source_id,
  'Daily goal: workout complete (backfilled)' AS description,
  TRUE AS is_verified,
  first_log.completed_at AS created_at
FROM (
  -- One row per (user_id, completion-day) — the earliest workout_log of
  -- the day carries the source_id and completed_at timestamp.
  SELECT DISTINCT ON (wl.user_id, DATE(wl.completed_at))
    wl.user_id,
    wl.id AS workout_log_id,
    wl.completed_at,
    DATE(wl.completed_at) AS day
  FROM workout_logs wl
  WHERE wl.status = 'completed'
    AND wl.completed_at IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM xp_transactions xt
      WHERE xt.user_id = wl.user_id
        AND xt.source = 'daily_goal_workout_complete'
        AND DATE(xt.created_at) = DATE(wl.completed_at)
    )
  ORDER BY wl.user_id, DATE(wl.completed_at), wl.completed_at
) AS first_log;

-- 4. Recompute total_xp for affected users from the ground truth
--    (sum of xp_transactions). Avoids drift from partial updates.
UPDATE user_xp ux
SET
  total_xp = sub.total_xp,
  updated_at = NOW()
FROM (
  SELECT user_id, COALESCE(SUM(xp_amount), 0)::int AS total_xp
  FROM xp_transactions
  WHERE user_id IN (
    SELECT DISTINCT wl.user_id
    FROM workout_logs wl
    WHERE wl.status = 'completed'
      AND wl.completed_at IS NOT NULL
  )
  GROUP BY user_id
) AS sub
WHERE ux.user_id = sub.user_id;

-- 5. Recompute current_level + title for affected users so the Discover
--    hero card, XP ring, and profile badge reflect the backfilled XP.
UPDATE user_xp ux
SET
  current_level = (lvl).level,
  title = (lvl).title,
  xp_to_next_level = (lvl).xp_for_next,
  xp_in_current_level = (lvl).xp_in_level,
  updated_at = NOW()
FROM (
  SELECT user_id, calculate_level_from_xp(total_xp) AS lvl
  FROM user_xp
  WHERE user_id IN (
    SELECT DISTINCT wl.user_id
    FROM workout_logs wl
    WHERE wl.status = 'completed'
  )
) AS recompute
WHERE ux.user_id = recompute.user_id;

-- 6. Diagnostic: verify 0 affected tuples remain.
DO $$
DECLARE
  v_remaining int;
BEGIN
  SELECT COUNT(*) INTO v_remaining FROM (
    SELECT DISTINCT wl.user_id, DATE(wl.completed_at)
    FROM workout_logs wl
    WHERE wl.status = 'completed'
      AND wl.completed_at IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM xp_transactions xt
        WHERE xt.user_id = wl.user_id
          AND xt.source = 'daily_goal_workout_complete'
          AND DATE(xt.created_at) = DATE(wl.completed_at)
      )
  ) AS remaining_days;
  RAISE NOTICE 'backfill_workout_xp: % user-day tuples remain (expect 0)', v_remaining;
  IF v_remaining <> 0 THEN
    RAISE WARNING 'backfill_workout_xp: non-zero remaining tuples — review logs';
  END IF;
END$$;

COMMIT;
