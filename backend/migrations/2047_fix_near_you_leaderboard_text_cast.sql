-- ============================================================================
-- Migration 2047: Fix get_near_you_leaderboard column-type mismatch (42804)
-- ============================================================================
-- Background:
--   Migration 2044 recreated get_near_you_leaderboard with a RETURNS TABLE
--   declaring `username TEXT, display_name TEXT`. But the underlying columns
--   `users.username` and `users.name` are `character varying` (varchar). At
--   runtime Postgres throws:
--
--     42804: structure of query does not match function result type
--     details: Returned type character varying does not match expected type
--              text in column 2.
--
--   This bubbles up from /api/v1/leaderboard/discover as a 500 every call.
--
-- Fix:
--   Cast both columns to TEXT inside the function body. We pick the cast
--   approach over widening the source columns because:
--     * `users.username` and `users.name` participate in many other RPCs and
--       indexes — broadening to TEXT is high-blast-radius.
--     * Changing the function signature to varchar would force every caller
--       (Flutter parses these as String) to be re-validated.
--     * A localized CAST in this one function is the smallest, safest change.
--
--   We use CREATE OR REPLACE because the RETURNS TABLE shape is unchanged —
--   only the body is updated. No DROP needed, GRANTs and dependencies are
--   preserved.
-- ============================================================================

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
      u.username::TEXT AS username,        -- 2047: cast varchar → text to match RETURNS TABLE
      (u.name)::TEXT   AS display_name,    -- 2047: cast varchar → text to match RETURNS TABLE
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
    -- 2041 cohort gate (preserved from 2044): any XP activity this week.
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
    w.metric::NUMERIC,                  -- 2047: cast bigint (SUM of int xp_amount) → numeric to match RETURNS TABLE
    (w.uid = p_user_id) AS is_current_user
  FROM window_rows w
  ORDER BY w.r;
END;
$$;

GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;
