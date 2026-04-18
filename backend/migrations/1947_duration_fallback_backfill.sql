-- Migration 1947: volume/endurance robustness — derive minutes from seconds.
-- Applied to prod Supabase 2026-04-18 via MCP.
--
-- Context: the completion endpoint was saving total_time_seconds but not
-- duration_minutes, which broke the Volume leaderboard and the Endurance
-- axis on the fitness radar. Two-part fix:
--   1. Backfill historical rows where only seconds was set.
--   2. Update the three SQL consumers (volume board + endurance scorer) to
--      COALESCE(duration_minutes, (total_time_seconds / 60)::INT) so a
--      similar regression can't silently zero out metrics again.
-- The backend insert path is also patched (performance_db.py:create_workout_log)
-- so new rows populate duration_minutes directly.


-- ─── Backfill ───────────────────────────────────────────────────────────────
UPDATE workout_logs
   SET duration_minutes = GREATEST(ROUND(total_time_seconds / 60.0)::INT, 1)
 WHERE status = 'completed'
   AND duration_minutes IS NULL
   AND total_time_seconds IS NOT NULL
   AND total_time_seconds > 0;


-- ─── _score_endurance: coalesce minutes from seconds ────────────────────────
CREATE OR REPLACE FUNCTION _score_endurance(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(
    1.0,
    COALESCE(SUM(COALESCE(duration_minutes, (total_time_seconds / 60)::INT)), 0)::NUMERIC / 500
  )
  FROM workout_logs
  WHERE user_id = p_user_id
    AND status = 'completed'
    AND completed_at > NOW() - INTERVAL '14 days';
$$;
GRANT EXECUTE ON FUNCTION _score_endurance(UUID) TO authenticated, service_role;


-- ─── compute_user_percentile volume branch ──────────────────────────────────
CREATE OR REPLACE FUNCTION compute_user_percentile(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp'
) RETURNS TABLE (
  rank INT, total INT, percentile NUMERIC, tier TEXT, metric_value NUMERIC
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_metric NUMERIC;
BEGIN
  IF p_board_type = 'xp' THEN
    SELECT COALESCE(SUM(xp_amount), 0) INTO v_user_metric
    FROM xp_transactions
    WHERE user_id = p_user_id AND DATE_TRUNC('week', created_at)::DATE = p_week_start;
  ELSIF p_board_type = 'volume' THEN
    SELECT COALESCE(SUM(COALESCE(duration_minutes, (total_time_seconds / 60)::INT)), 0)
      INTO v_user_metric
    FROM workout_logs
    WHERE user_id = p_user_id AND status = 'completed'
      AND DATE_TRUNC('week', completed_at)::DATE = p_week_start;
  ELSIF p_board_type = 'streaks' THEN
    SELECT COALESCE(current_streak, 0) INTO v_user_metric
    FROM user_login_streaks WHERE user_id = p_user_id;
  ELSE
    v_user_metric := 0;
  END IF;

  RETURN QUERY
  WITH board AS (
    SELECT u.id AS uid,
      CASE
        WHEN p_board_type = 'xp' THEN COALESCE((SELECT SUM(xp_amount) FROM xp_transactions WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start), 0)
        WHEN p_board_type = 'volume' THEN COALESCE((SELECT SUM(COALESCE(duration_minutes, (total_time_seconds/60)::INT)) FROM workout_logs WHERE user_id = u.id AND status = 'completed' AND DATE_TRUNC('week', completed_at)::DATE = p_week_start), 0)
        WHEN p_board_type = 'streaks' THEN COALESCE((SELECT current_streak FROM user_login_streaks WHERE user_id = u.id), 0)
        ELSE 0
      END AS metric
    FROM users u
    WHERE u.show_on_leaderboard = TRUE
      AND EXISTS (SELECT 1 FROM workout_logs wl WHERE wl.user_id = u.id AND wl.status = 'completed' AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start)
  ),
  ranked AS (SELECT uid, metric, RANK() OVER (ORDER BY metric DESC) AS r FROM board),
  total_row AS (SELECT COUNT(*)::INT AS total_count FROM ranked),
  user_row AS (SELECT r FROM ranked WHERE uid = p_user_id)
  SELECT
    COALESCE((SELECT r::INT FROM user_row), 0),
    (SELECT total_count FROM total_row),
    CASE WHEN (SELECT total_count FROM total_row) = 0 OR NOT EXISTS (SELECT 1 FROM user_row) THEN 0::NUMERIC
         ELSE ROUND(100.0 * ((SELECT total_count FROM total_row) - (SELECT r FROM user_row) + 1)::NUMERIC / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC, 1) END,
    CASE
      WHEN (SELECT total_count FROM total_row) = 0 OR NOT EXISTS (SELECT 1 FROM user_row) THEN 'starter'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.01)) THEN 'legendary'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.05)) THEN 'top'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.10)) THEN 'elite'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.25)) THEN 'rising'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.50)) THEN 'active'
      ELSE 'starter'
    END,
    v_user_metric;
END;
$$;
GRANT EXECUTE ON FUNCTION compute_user_percentile(UUID, DATE, TEXT) TO authenticated, service_role;


-- ─── get_near_you_leaderboard volume branch ────────────────────────────────
DROP FUNCTION IF EXISTS get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT);
CREATE FUNCTION get_near_you_leaderboard(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_window INT DEFAULT 5
) RETURNS TABLE (
  user_id UUID, username TEXT, display_name TEXT, avatar_url TEXT,
  rank INT, metric_value NUMERIC, is_current_user BOOLEAN, is_anonymous BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH board AS (
    SELECT u.id AS uid, u.leaderboard_anonymous AS anon,
      CASE WHEN u.leaderboard_anonymous THEN NULL ELSE u.username::TEXT END AS username,
      CASE WHEN u.leaderboard_anonymous THEN 'Anonymous athlete' ELSE u.name::TEXT END AS display_name,
      CASE WHEN u.leaderboard_anonymous THEN NULL ELSE COALESCE(u.avatar_url, u.photo_url)::TEXT END AS avatar_url,
      (CASE p_board_type
        WHEN 'xp' THEN COALESCE((SELECT SUM(xt.xp_amount) FROM xp_transactions xt WHERE xt.user_id = u.id AND DATE_TRUNC('week', xt.created_at)::DATE = p_week_start), 0)
        WHEN 'volume' THEN COALESCE((SELECT SUM(COALESCE(wl2.duration_minutes, (wl2.total_time_seconds/60)::INT)) FROM workout_logs wl2 WHERE wl2.user_id = u.id AND wl2.status = 'completed' AND DATE_TRUNC('week', wl2.completed_at)::DATE = p_week_start), 0)
        WHEN 'streaks' THEN COALESCE((SELECT uls.current_streak FROM user_login_streaks uls WHERE uls.user_id = u.id), 0)
        ELSE 0
      END)::NUMERIC AS metric
    FROM users u
    WHERE u.show_on_leaderboard = TRUE
      AND EXISTS (SELECT 1 FROM workout_logs wl WHERE wl.user_id = u.id AND wl.status = 'completed' AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start)
  ),
  ranked AS (SELECT b.uid, b.anon, b.username, b.display_name, b.avatar_url, b.metric, RANK() OVER (ORDER BY b.metric DESC)::INT AS r FROM board b),
  user_rank AS (SELECT r FROM ranked WHERE uid = p_user_id),
  window_rows AS (SELECT * FROM ranked WHERE r BETWEEN GREATEST(1, COALESCE((SELECT r FROM user_rank), 1) - p_window) AND COALESCE((SELECT r FROM user_rank), 1) + p_window)
  SELECT w.uid, w.username, w.display_name, w.avatar_url, w.r, w.metric,
         (w.uid = p_user_id) AS is_current_user, w.anon AS is_anonymous
  FROM window_rows w ORDER BY w.r;
END;
$$;
GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;
