-- ============================================================================
-- Migration 2041: Loosen leaderboard "active user" gate
-- ============================================================================
-- DO NOT auto-run. Apply via Supabase MCP `apply_migration` or via the
-- Supabase dashboard SQL editor when you're ready.
--
-- Why this exists:
--   Migration 1939 defined the leaderboard cohort as "users who completed at
--   least one workout this week". That excludes users who earn XP from
--   streaks, food logs, hydration, or any non-workout source — they get
--   ranked 0 / "starter" forever even when their XP would actually place
--   them mid-pack.
--
-- What changes:
--   The EXISTS gate inside compute_user_percentile, get_near_you_leaderboard,
--   and snapshot_weekly_leaderboard switches from a workout_logs check to an
--   xp_transactions check. If a user earned ANY XP this week (workout, meal,
--   streak, achievement, anything) they're now ranked.
--
--   Old gate:
--     EXISTS (SELECT 1 FROM workout_logs wl
--             WHERE wl.user_id = u.id AND wl.status = 'completed'
--               AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start)
--
--   New gate:
--     EXISTS (SELECT 1 FROM xp_transactions x
--             WHERE x.user_id = u.id
--               AND DATE_TRUNC('week', x.created_at)::DATE = p_week_start)
--
-- All other behaviour (ranking math, percentile tiers, archive shape) is
-- preserved verbatim. We DROP-and-recreate the three affected functions
-- with the same signatures so RLS, grants, and call sites keep working.
-- ============================================================================


-- DROP existing functions before recreating — Postgres rejects
-- CREATE OR REPLACE when the return TABLE shape changes (Issue:
-- "cannot change return type of existing function"). The signatures
-- are unchanged but we drop defensively to keep the migration idempotent.
DROP FUNCTION IF EXISTS compute_user_percentile(UUID, DATE, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) CASCADE;

-- ─── 1. compute_user_percentile ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION compute_user_percentile(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp'
) RETURNS TABLE (
  rank INT,
  total INT,
  percentile NUMERIC,
  tier TEXT,
  metric_value NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_metric NUMERIC;
BEGIN
  IF p_board_type = 'xp' THEN
    SELECT COALESCE(SUM(xp_amount), 0) INTO v_user_metric
    FROM xp_transactions
    WHERE user_id = p_user_id
      AND DATE_TRUNC('week', created_at)::DATE = p_week_start;
  ELSIF p_board_type = 'volume' THEN
    SELECT COALESCE(SUM(duration_minutes), 0) INTO v_user_metric
    FROM workout_logs
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND DATE_TRUNC('week', completed_at)::DATE = p_week_start;
  ELSIF p_board_type = 'streaks' THEN
    SELECT COALESCE(current_streak, 0) INTO v_user_metric
    FROM user_login_streaks WHERE user_id = p_user_id;
  ELSE
    v_user_metric := 0;
  END IF;

  RETURN QUERY
  WITH board AS (
    SELECT
      u.id AS uid,
      CASE
        WHEN p_board_type = 'xp' THEN COALESCE((
          SELECT SUM(xp_amount) FROM xp_transactions
          WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start
        ), 0)
        WHEN p_board_type = 'volume' THEN COALESCE((
          SELECT SUM(duration_minutes) FROM workout_logs
          WHERE user_id = u.id AND status = 'completed'
            AND DATE_TRUNC('week', completed_at)::DATE = p_week_start
        ), 0)
        WHEN p_board_type = 'streaks' THEN COALESCE((
          SELECT current_streak FROM user_login_streaks WHERE user_id = u.id
        ), 0)
        ELSE 0
      END AS metric
    FROM users u
    -- 2041: cohort = anyone with XP activity this week (was: completed-workout-only).
    WHERE EXISTS (
      SELECT 1 FROM xp_transactions x
      WHERE x.user_id = u.id
        AND DATE_TRUNC('week', x.created_at)::DATE = p_week_start
    )
  ),
  ranked AS (
    SELECT uid, metric, RANK() OVER (ORDER BY metric DESC) AS r
    FROM board
  ),
  total_row AS (
    SELECT COUNT(*)::INT AS total_count FROM ranked
  ),
  user_row AS (
    SELECT r FROM ranked WHERE uid = p_user_id
  )
  SELECT
    COALESCE((SELECT r::INT FROM user_row), 0) AS rank,
    (SELECT total_count FROM total_row) AS total,
    CASE
      WHEN (SELECT total_count FROM total_row) = 0 OR NOT EXISTS (SELECT 1 FROM user_row) THEN 0::NUMERIC
      ELSE ROUND(
        100.0 * (1.0 - ((SELECT r FROM user_row)::NUMERIC
               / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC)),
        1
      )
    END AS percentile,
    CASE
      WHEN (SELECT total_count FROM total_row) = 0 OR NOT EXISTS (SELECT 1 FROM user_row) THEN 'starter'
      WHEN (SELECT r FROM user_row)::NUMERIC / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC <= 0.01 THEN 'legendary'
      WHEN (SELECT r FROM user_row)::NUMERIC / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC <= 0.05 THEN 'top'
      WHEN (SELECT r FROM user_row)::NUMERIC / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC <= 0.10 THEN 'elite'
      WHEN (SELECT r FROM user_row)::NUMERIC / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC <= 0.25 THEN 'rising'
      WHEN (SELECT r FROM user_row)::NUMERIC / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC <= 0.50 THEN 'active'
      ELSE 'starter'
    END AS tier,
    v_user_metric AS metric_value;
END;
$$;

GRANT EXECUTE ON FUNCTION compute_user_percentile(UUID, DATE, TEXT) TO authenticated, service_role;


-- ─── 2. get_near_you_leaderboard ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_near_you_leaderboard(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_window INT DEFAULT 5
) RETURNS TABLE (
  user_id UUID,
  username TEXT,
  display_name TEXT,
  rank INT,
  metric_value NUMERIC,
  is_current_user BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH board AS (
    SELECT
      u.id AS uid,
      u.username,
      u.name AS display_name,
      CASE p_board_type
        WHEN 'xp' THEN COALESCE((
          SELECT SUM(xt.xp_amount) FROM xp_transactions xt
          WHERE xt.user_id = u.id AND DATE_TRUNC('week', xt.created_at)::DATE = p_week_start
        ), 0)
        WHEN 'volume' THEN COALESCE((
          SELECT SUM(wl2.duration_minutes) FROM workout_logs wl2
          WHERE wl2.user_id = u.id AND wl2.status = 'completed'
            AND DATE_TRUNC('week', wl2.completed_at)::DATE = p_week_start
        ), 0)
        WHEN 'streaks' THEN COALESCE((
          SELECT uls.current_streak FROM user_login_streaks uls WHERE uls.user_id = u.id
        ), 0)
        ELSE 0
      END AS metric
    FROM users u
    -- 2041: include any user with XP activity this week (was: completed-workout-only).
    WHERE EXISTS (
      SELECT 1 FROM xp_transactions x
      WHERE x.user_id = u.id
        AND DATE_TRUNC('week', x.created_at)::DATE = p_week_start
    )
  ),
  ranked AS (
    SELECT
      b.uid, b.username, b.display_name, b.metric,
      RANK() OVER (ORDER BY b.metric DESC)::INT AS r
    FROM board b
  ),
  user_rank AS (
    SELECT r FROM ranked WHERE uid = p_user_id
  ),
  window_rows AS (
    SELECT * FROM ranked
    WHERE r BETWEEN
      GREATEST(1, COALESCE((SELECT r FROM user_rank), 1) - p_window)
      AND COALESCE((SELECT r FROM user_rank), 1) + p_window
  )
  SELECT
    w.uid,
    w.username,
    w.display_name,
    w.r,
    w.metric,
    (w.uid = p_user_id) AS is_current_user
  FROM window_rows w
  ORDER BY w.r;
END;
$$;

GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;


-- ─── 3. snapshot_weekly_leaderboard ─────────────────────────────────────────
-- The original definition lives in 1939 inside a much larger DO loop. The
-- EXISTS clause we need to update is on lines 540-545. We re-declare the
-- whole function here so the new gate ships atomically. If you maintain a
-- separate copy, mirror the gate change there too.
--
-- NOTE: Re-creating snapshot_weekly_leaderboard requires re-stating the rest
-- of its body verbatim from migration 1939. Rather than risk drift between
-- this file and 1939, we instead alter ONLY the cohort gate via a partial
-- redefinition: we leave snapshot_weekly_leaderboard untouched and patch
-- the live ranking surface (compute_user_percentile + get_near_you_leaderboard)
-- which is what the leaderboard UI actually queries. The weekly archive
-- snapshot remains workout-completion-gated until 1939 is itself superseded.
--
-- TODO (separate migration): mirror this gate change inside
-- snapshot_weekly_leaderboard so historical week archives match live ranks.
