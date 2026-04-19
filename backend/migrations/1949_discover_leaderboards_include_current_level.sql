-- Migration 1949: surface current_level on leaderboard rows so the Discover tab
-- can render a "Lvl N" badge next to every user. Joins user_xp (LEFT — default
-- to level 1 for users who have no XP row yet).
-- Applied to prod Supabase 2026-04-18 via MCP.
--
-- Returned column lists change, so RPC signatures require DROP + CREATE
-- (Postgres refuses in-place RETURNS TABLE edits). No data migration needed.

-- ─── get_near_you_leaderboard ──────────────────────────────────────────────
DROP FUNCTION IF EXISTS get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT);
CREATE FUNCTION get_near_you_leaderboard(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_window INT DEFAULT 5
) RETURNS TABLE (
  user_id UUID, username TEXT, display_name TEXT, avatar_url TEXT,
  rank INT, metric_value NUMERIC, is_current_user BOOLEAN, is_anonymous BOOLEAN,
  current_level INT
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH board AS (
    SELECT u.id AS uid, u.leaderboard_anonymous AS anon,
      CASE WHEN u.leaderboard_anonymous THEN NULL ELSE u.username::TEXT END AS username,
      CASE WHEN u.leaderboard_anonymous THEN 'Anonymous athlete' ELSE u.name::TEXT END AS display_name,
      CASE WHEN u.leaderboard_anonymous THEN NULL ELSE COALESCE(u.avatar_url, u.photo_url)::TEXT END AS avatar_url,
      COALESCE(ux.current_level, 1)::INT AS level,
      (CASE p_board_type
        WHEN 'xp' THEN COALESCE((SELECT SUM(xt.xp_amount) FROM xp_transactions xt WHERE xt.user_id = u.id AND DATE_TRUNC('week', xt.created_at)::DATE = p_week_start), 0)
        WHEN 'volume' THEN COALESCE((SELECT SUM(COALESCE(wl2.duration_minutes, (wl2.total_time_seconds/60)::INT)) FROM workout_logs wl2 WHERE wl2.user_id = u.id AND wl2.status = 'completed' AND DATE_TRUNC('week', wl2.completed_at)::DATE = p_week_start), 0)
        WHEN 'streaks' THEN COALESCE((SELECT uls.current_streak FROM user_login_streaks uls WHERE uls.user_id = u.id), 0)
        ELSE 0
      END)::NUMERIC AS metric
    FROM users u
    LEFT JOIN user_xp ux ON ux.user_id = u.id
    WHERE u.show_on_leaderboard = TRUE
      AND EXISTS (
        SELECT 1 FROM workout_logs wl
        WHERE wl.user_id = u.id
          AND wl.status = 'completed'
          AND wl.completed_at > NOW() - INTERVAL '30 days'
      )
  ),
  ranked AS (
    SELECT b.uid, b.anon, b.username, b.display_name, b.avatar_url, b.level, b.metric,
           RANK() OVER (ORDER BY b.metric DESC)::INT AS r
    FROM board b
  ),
  user_rank AS (SELECT r FROM ranked WHERE uid = p_user_id),
  window_rows AS (
    SELECT * FROM ranked
    WHERE r BETWEEN
      GREATEST(1, COALESCE((SELECT r FROM user_rank), 1) - p_window)
      AND COALESCE((SELECT r FROM user_rank), 1) + p_window
  )
  SELECT w.uid, w.username, w.display_name, w.avatar_url, w.r, w.metric,
         (w.uid = p_user_id) AS is_current_user, w.anon AS is_anonymous, w.level
  FROM window_rows w
  ORDER BY w.r;
END;
$$;
GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;


-- ─── get_rising_stars ──────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS get_rising_stars(DATE, TEXT, TEXT, INT, UUID);
CREATE FUNCTION get_rising_stars(
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_limit INT DEFAULT 3,
  p_exclude_user UUID DEFAULT NULL
) RETURNS TABLE (
  user_id UUID, username TEXT, display_name TEXT, avatar_url TEXT,
  current_rank INT, previous_rank INT, rank_delta INT,
  metric_value NUMERIC, is_anonymous BOOLEAN, current_level INT
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_prev_week DATE := p_week_start - INTERVAL '1 week';
BEGIN
  RETURN QUERY
  WITH current_week AS (
    SELECT wla.user_id AS uid, wla.rank AS curr_r, wla.metric_value AS metric
    FROM weekly_leaderboard_archive wla
    WHERE wla.week_start = p_week_start
      AND wla.board_type = p_board_type
      AND wla.scope = p_scope
  ),
  previous_week AS (
    SELECT wla.user_id AS uid, wla.rank AS prev_r
    FROM weekly_leaderboard_archive wla
    WHERE wla.week_start = v_prev_week
      AND wla.board_type = p_board_type
      AND wla.scope = p_scope
  )
  SELECT cw.uid,
    CASE WHEN u.leaderboard_anonymous THEN NULL ELSE u.username::TEXT END,
    CASE WHEN u.leaderboard_anonymous THEN 'Anonymous athlete' ELSE u.name::TEXT END,
    CASE WHEN u.leaderboard_anonymous THEN NULL ELSE COALESCE(u.avatar_url, u.photo_url)::TEXT END,
    cw.curr_r, pw.prev_r, (pw.prev_r - cw.curr_r)::INT AS delta,
    cw.metric, u.leaderboard_anonymous,
    COALESCE(ux.current_level, 1)::INT
  FROM current_week cw
  JOIN previous_week pw ON pw.uid = cw.uid
  JOIN users u ON u.id = cw.uid
  LEFT JOIN user_xp ux ON ux.user_id = cw.uid
  WHERE u.show_on_leaderboard = TRUE
    AND (p_exclude_user IS NULL OR cw.uid <> p_exclude_user)
    AND (pw.prev_r - cw.curr_r) > 0
  ORDER BY delta DESC
  LIMIT p_limit;
END;
$$;
GRANT EXECUTE ON FUNCTION get_rising_stars(DATE, TEXT, TEXT, INT, UUID) TO authenticated, service_role;
