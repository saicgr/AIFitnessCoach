-- ============================================================================
-- Migration 2428: get_near_you_leaderboard must return current_level
-- (finding #450)
-- ============================================================================
-- Background:
--   The Ranks board (Discover tab `near_you` + `top_10`, both backed by
--   `get_near_you_leaderboard` — see backend/api/v1/leaderboard.py) renders
--   every competitor as "Lvl 1" regardless of their real level (a Level-3
--   account with 547 XP showed "Lvl 1" next to a Level-1-looking account on
--   100 XP). Root cause: the live function's RETURNS TABLE never included
--   current_level at all:
--
--     select pg_get_function_result(oid) from pg_proc
--       where proname = 'get_near_you_leaderboard';
--     -> TABLE(user_id uuid, username text, display_name text, rank integer,
--              metric_value numeric, is_current_user boolean)
--
--   backend/api/v1/leaderboard.py reads `r.get("current_level") or 1` for
--   every row — since the column was never selected, every row is None and
--   every badge silently defaults to 1.
--
-- Fix:
--   Add `current_level INT` to the RETURNS TABLE, left-joined from
--   `user_xp.current_level` (defaulting to 1 only for a user with no
--   `user_xp` row yet, which is a genuine "hasn't started" case rather than
--   a query bug). No other columns changed — CREATE OR REPLACE preserves the
--   function's other callers/grants.
-- ============================================================================

DROP FUNCTION IF EXISTS get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT);

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
  is_current_user BOOLEAN,
  current_level INT
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
      u.username::TEXT AS username,
      (u.name)::TEXT   AS display_name,
      COALESCE(ux.current_level, 1) AS current_level,  -- 2428: was never selected
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
    LEFT JOIN user_xp ux ON ux.user_id = u.id
    -- 2041 cohort gate (preserved from 2044): any XP activity this week.
    WHERE EXISTS (
      SELECT 1 FROM xp_transactions x
      WHERE x.user_id = u.id
        AND DATE_TRUNC('week', x.created_at)::DATE = p_week_start
    )
  ),
  ranked AS (
    SELECT
      b.uid, b.username, b.display_name, b.current_level, b.metric,
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
    w.metric::NUMERIC,
    (w.uid = p_user_id) AS is_current_user,
    w.current_level
  FROM window_rows w
  ORDER BY w.r;
END;
$$;

GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;

-- VERIFY: select current_level from get_near_you_leaderboard('<a real user_id>'::uuid) limit 5; -- expect real levels, not all 1
