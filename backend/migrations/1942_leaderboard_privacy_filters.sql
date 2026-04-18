-- Migration 1942: apply privacy filters to leaderboard RPCs.
-- Applied to prod Supabase 2026-04-18 via MCP.
--
-- Three semantic changes across all 4 leaderboard RPCs:
--   1. AND u.show_on_leaderboard = TRUE in the active-user filter.
--   2. username/display_name/avatar_url wrapped with anonymization CASE
--      so leaderboard_anonymous=TRUE users appear as "Anonymous athlete".
--   3. is_anonymous BOOLEAN column added to Near You / Rising Stars returns
--      so the client can style anonymous rows differently if desired.

-- ─── compute_user_percentile ────────────────────────────────────────────────
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
    SELECT COALESCE(SUM(duration_minutes), 0) INTO v_user_metric
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
        WHEN p_board_type = 'volume' THEN COALESCE((SELECT SUM(duration_minutes) FROM workout_logs WHERE user_id = u.id AND status = 'completed' AND DATE_TRUNC('week', completed_at)::DATE = p_week_start), 0)
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
        WHEN 'volume' THEN COALESCE((SELECT SUM(wl2.duration_minutes) FROM workout_logs wl2 WHERE wl2.user_id = u.id AND wl2.status = 'completed' AND DATE_TRUNC('week', wl2.completed_at)::DATE = p_week_start), 0)
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
  metric_value NUMERIC, is_anonymous BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_prev_week DATE := p_week_start - INTERVAL '1 week';
BEGIN
  RETURN QUERY
  WITH current_week AS (SELECT wla.user_id AS uid, wla.rank AS curr_r, wla.metric_value AS metric FROM weekly_leaderboard_archive wla WHERE wla.week_start = p_week_start AND wla.board_type = p_board_type AND wla.scope = p_scope),
       previous_week AS (SELECT wla.user_id AS uid, wla.rank AS prev_r FROM weekly_leaderboard_archive wla WHERE wla.week_start = v_prev_week AND wla.board_type = p_board_type AND wla.scope = p_scope)
  SELECT cw.uid,
    CASE WHEN u.leaderboard_anonymous THEN NULL ELSE u.username::TEXT END,
    CASE WHEN u.leaderboard_anonymous THEN 'Anonymous athlete' ELSE u.name::TEXT END,
    CASE WHEN u.leaderboard_anonymous THEN NULL ELSE COALESCE(u.avatar_url, u.photo_url)::TEXT END,
    cw.curr_r, pw.prev_r, (pw.prev_r - cw.curr_r)::INT AS delta, cw.metric, u.leaderboard_anonymous
  FROM current_week cw
  JOIN previous_week pw ON pw.uid = cw.uid
  JOIN users u ON u.id = cw.uid
  WHERE u.show_on_leaderboard = TRUE
    AND (p_exclude_user IS NULL OR cw.uid <> p_exclude_user)
    AND (pw.prev_r - cw.curr_r) > 0
  ORDER BY delta DESC LIMIT p_limit;
END;
$$;
GRANT EXECUTE ON FUNCTION get_rising_stars(DATE, TEXT, TEXT, INT, UUID) TO authenticated, service_role;


-- ─── snapshot_weekly_leaderboard ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION snapshot_weekly_leaderboard(
  p_week_start DATE DEFAULT (DATE_TRUNC('week', (NOW() - INTERVAL '1 day')))::DATE
) RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_count INT := 0; v_rows INT := 0; v_board_type TEXT; v_scope TEXT;
BEGIN
  FOR v_board_type IN SELECT UNNEST(ARRAY['xp', 'volume', 'streaks']) LOOP
    FOR v_scope IN SELECT UNNEST(ARRAY['global']) LOOP
      INSERT INTO weekly_leaderboard_archive (user_id, week_start, board_type, scope, rank, metric_value, total_participants)
      SELECT q.user_id, p_week_start, v_board_type, v_scope, q.rank, q.metric, q.total
      FROM (
        SELECT u.id AS user_id,
          CASE v_board_type
            WHEN 'xp' THEN COALESCE((SELECT SUM(xp_amount) FROM xp_transactions WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start), 0)
            WHEN 'volume' THEN COALESCE((SELECT SUM(duration_minutes) FROM workout_logs WHERE user_id = u.id AND status = 'completed' AND DATE_TRUNC('week', completed_at)::DATE = p_week_start), 0)
            WHEN 'streaks' THEN COALESCE((SELECT current_streak FROM user_login_streaks WHERE user_id = u.id), 0)
            ELSE 0
          END::NUMERIC AS metric,
          RANK() OVER (ORDER BY
            CASE v_board_type
              WHEN 'xp' THEN COALESCE((SELECT SUM(xp_amount) FROM xp_transactions WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start), 0)
              WHEN 'volume' THEN COALESCE((SELECT SUM(duration_minutes) FROM workout_logs WHERE user_id = u.id AND status = 'completed' AND DATE_TRUNC('week', completed_at)::DATE = p_week_start), 0)
              WHEN 'streaks' THEN COALESCE((SELECT current_streak FROM user_login_streaks WHERE user_id = u.id), 0)
              ELSE 0
            END DESC
          )::INT AS rank,
          COUNT(*) OVER () AS total
        FROM users u
        WHERE u.show_on_leaderboard = TRUE
          AND EXISTS (SELECT 1 FROM workout_logs wl WHERE wl.user_id = u.id AND wl.status = 'completed' AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start)
      ) q
      ON CONFLICT (user_id, week_start, board_type, scope, country_code) DO UPDATE
        SET rank = EXCLUDED.rank,
            metric_value = EXCLUDED.metric_value,
            total_participants = EXCLUDED.total_participants;
      GET DIAGNOSTICS v_rows = ROW_COUNT;
      v_count := v_count + v_rows;
    END LOOP;
  END LOOP;
  RETURN v_count;
END;
$$;
GRANT EXECUTE ON FUNCTION snapshot_weekly_leaderboard(DATE) TO service_role;
