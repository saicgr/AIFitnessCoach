-- Migration 1940: Fix four bugs in the Discover tab RPCs from migration 1939.
-- All four were applied directly to prod via Supabase MCP on 2026-04-18 — this
-- file exists so the repo stays in sync and fresh environments get the fixes.
--
-- Bug A (compute_user_percentile):
--   Old formula `100 * (1 - rank/total)` outputs 0 for rank=1 of 1 (should be 100).
--   Old tier check `rank/total <= 0.01` can never match small-N boards → everyone
--   stuck at 'starter' even when top.
-- Fix A:
--   percentile = 100 * (total - rank + 1) / total
--   tier check = rank <= GREATEST(1, CEIL(total * threshold))
--
-- Bug B (get_near_you_leaderboard):
--   `users.username` / `users.name` are VARCHAR in prod but RPC declares TEXT
--   return cols → 500 "Returned type character varying does not match TEXT".
-- Fix B: explicit ::TEXT casts.
--
-- Bug C (get_near_you_leaderboard):
--   CASE WHEN SUM(xp_amount) returns BIGINT but metric column declared NUMERIC.
-- Fix C: ::NUMERIC cast on the whole CASE.
--
-- Bug D (get_next_tier_progress):
--   Inner subquery aliased as `total_xp` but outer tried to `SUM(xp_amount)` on
--   it → column does not exist. Also tier boundaries didn't match fix A.
-- Fix D: read `total_xp` directly, align ceil-based tier thresholds with A.
--
-- Bug E (get_rising_stars): same varchar/text mismatch as B.


-- ─── A + fix compute_user_percentile ────────────────────────────────────────
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
    WHERE EXISTS (
      SELECT 1 FROM workout_logs wl
      WHERE wl.user_id = u.id
        AND wl.status = 'completed'
        AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start
    )
  ),
  ranked AS (
    SELECT uid, metric, RANK() OVER (ORDER BY metric DESC) AS r
    FROM board
  ),
  total_row AS (SELECT COUNT(*)::INT AS total_count FROM ranked),
  user_row AS (SELECT r FROM ranked WHERE uid = p_user_id)
  SELECT
    COALESCE((SELECT r::INT FROM user_row), 0) AS rank,
    (SELECT total_count FROM total_row) AS total,
    CASE
      WHEN (SELECT total_count FROM total_row) = 0
        OR NOT EXISTS (SELECT 1 FROM user_row) THEN 0::NUMERIC
      ELSE ROUND(
        100.0 * ((SELECT total_count FROM total_row) - (SELECT r FROM user_row) + 1)::NUMERIC
              / GREATEST((SELECT total_count FROM total_row), 1)::NUMERIC,
        1
      )
    END AS percentile,
    CASE
      WHEN (SELECT total_count FROM total_row) = 0
        OR NOT EXISTS (SELECT 1 FROM user_row) THEN 'starter'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.01)) THEN 'legendary'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.05)) THEN 'top'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.10)) THEN 'elite'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.25)) THEN 'rising'
      WHEN (SELECT r FROM user_row) <= GREATEST(1, CEIL((SELECT total_count FROM total_row)::NUMERIC * 0.50)) THEN 'active'
      ELSE 'starter'
    END AS tier,
    v_user_metric AS metric_value;
END;
$$;

GRANT EXECUTE ON FUNCTION compute_user_percentile(UUID, DATE, TEXT) TO authenticated, service_role;


-- ─── B + C fix get_near_you_leaderboard ─────────────────────────────────────
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
      u.username::TEXT AS username,
      u.name::TEXT AS display_name,
      (CASE p_board_type
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
      END)::NUMERIC AS metric
    FROM users u
    WHERE EXISTS (
      SELECT 1 FROM workout_logs wl
      WHERE wl.user_id = u.id
        AND wl.status = 'completed'
        AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start
    )
  ),
  ranked AS (
    SELECT b.uid, b.username, b.display_name, b.metric,
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
  SELECT w.uid, w.username, w.display_name, w.r, w.metric,
         (w.uid = p_user_id) AS is_current_user
  FROM window_rows w
  ORDER BY w.r;
END;
$$;

GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;


-- ─── D fix get_next_tier_progress ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_next_tier_progress(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp'
) RETURNS TABLE (
  current_tier TEXT,
  next_tier TEXT,
  units_to_next INT,
  metric_label TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rank INT;
  v_total INT;
  v_metric NUMERIC;
  v_next_target_rank INT;
  v_next_target_metric NUMERIC;
BEGIN
  SELECT rank, total, metric_value
  INTO v_rank, v_total, v_metric
  FROM compute_user_percentile(p_user_id, p_week_start, p_board_type);

  IF v_rank IS NULL OR v_rank = 0 OR v_total = 0 THEN
    RETURN QUERY SELECT 'starter'::TEXT, 'active'::TEXT, 0::INT,
      (CASE p_board_type WHEN 'xp' THEN 'XP' WHEN 'volume' THEN 'min' WHEN 'streaks' THEN 'days' ELSE '' END)::TEXT;
    RETURN;
  END IF;

  IF v_rank <= GREATEST(1, CEIL(v_total * 0.01)) THEN
    current_tier := 'legendary'; next_tier := NULL; v_next_target_rank := 1;
  ELSIF v_rank <= GREATEST(1, CEIL(v_total * 0.05)) THEN
    current_tier := 'top'; next_tier := 'legendary';
    v_next_target_rank := GREATEST(1, CEIL(v_total * 0.01))::INT;
  ELSIF v_rank <= GREATEST(1, CEIL(v_total * 0.10)) THEN
    current_tier := 'elite'; next_tier := 'top';
    v_next_target_rank := GREATEST(1, CEIL(v_total * 0.05))::INT;
  ELSIF v_rank <= GREATEST(1, CEIL(v_total * 0.25)) THEN
    current_tier := 'rising'; next_tier := 'elite';
    v_next_target_rank := GREATEST(1, CEIL(v_total * 0.10))::INT;
  ELSIF v_rank <= GREATEST(1, CEIL(v_total * 0.50)) THEN
    current_tier := 'active'; next_tier := 'rising';
    v_next_target_rank := GREATEST(1, CEIL(v_total * 0.25))::INT;
  ELSE
    current_tier := 'starter'; next_tier := 'active';
    v_next_target_rank := GREATEST(1, CEIL(v_total * 0.50))::INT;
  END IF;

  IF next_tier IS NULL THEN
    units_to_next := 0;
  ELSE
    IF p_board_type = 'xp' THEN
      SELECT q.total_xp INTO v_next_target_metric FROM (
        SELECT SUM(xt.xp_amount)::NUMERIC AS total_xp
        FROM xp_transactions xt
        WHERE DATE_TRUNC('week', xt.created_at)::DATE = p_week_start
        GROUP BY xt.user_id ORDER BY total_xp DESC
        LIMIT 1 OFFSET GREATEST(v_next_target_rank - 1, 0)
      ) q;
    ELSIF p_board_type = 'volume' THEN
      SELECT q.total_min INTO v_next_target_metric FROM (
        SELECT SUM(wl.duration_minutes)::NUMERIC AS total_min
        FROM workout_logs wl
        WHERE wl.status = 'completed'
          AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start
        GROUP BY wl.user_id ORDER BY total_min DESC
        LIMIT 1 OFFSET GREATEST(v_next_target_rank - 1, 0)
      ) q;
    ELSIF p_board_type = 'streaks' THEN
      SELECT q.streak INTO v_next_target_metric FROM (
        SELECT uls.current_streak::NUMERIC AS streak
        FROM user_login_streaks uls
        ORDER BY uls.current_streak DESC NULLS LAST
        LIMIT 1 OFFSET GREATEST(v_next_target_rank - 1, 0)
      ) q;
    ELSE
      v_next_target_metric := v_metric;
    END IF;

    units_to_next := GREATEST(COALESCE((v_next_target_metric - v_metric), 0)::INT + 1, 1);
  END IF;

  metric_label := CASE p_board_type
    WHEN 'xp' THEN 'XP' WHEN 'volume' THEN 'min' WHEN 'streaks' THEN 'days' ELSE ''
  END;

  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION get_next_tier_progress(UUID, DATE, TEXT) TO authenticated, service_role;


-- ─── F + G: return avatar_url from both leaderboard RPCs ───────────────────
-- Changing a RETURNS TABLE column list requires DROP + CREATE (Postgres won't
-- allow in-place type change).

DROP FUNCTION IF EXISTS get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT);

CREATE FUNCTION get_near_you_leaderboard(
  p_user_id UUID,
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_window INT DEFAULT 5
) RETURNS TABLE (
  user_id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  rank INT,
  metric_value NUMERIC,
  is_current_user BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH board AS (
    SELECT
      u.id AS uid,
      u.username::TEXT AS username,
      u.name::TEXT AS display_name,
      COALESCE(u.avatar_url, u.photo_url)::TEXT AS avatar_url,
      (CASE p_board_type
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
      END)::NUMERIC AS metric
    FROM users u
    WHERE EXISTS (
      SELECT 1 FROM workout_logs wl
      WHERE wl.user_id = u.id
        AND wl.status = 'completed'
        AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start
    )
  ),
  ranked AS (
    SELECT b.uid, b.username, b.display_name, b.avatar_url, b.metric,
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
         (w.uid = p_user_id) AS is_current_user
  FROM window_rows w
  ORDER BY w.r;
END;
$$;
GRANT EXECUTE ON FUNCTION get_near_you_leaderboard(UUID, DATE, TEXT, TEXT, INT) TO authenticated, service_role;


DROP FUNCTION IF EXISTS get_rising_stars(DATE, TEXT, TEXT, INT, UUID);

-- ─── E fix get_rising_stars ─────────────────────────────────────────────────
CREATE FUNCTION get_rising_stars(
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_limit INT DEFAULT 3,
  p_exclude_user UUID DEFAULT NULL
) RETURNS TABLE (
  user_id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  current_rank INT,
  previous_rank INT,
  rank_delta INT,
  metric_value NUMERIC
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
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
  SELECT
    cw.uid,
    u.username::TEXT,
    u.name::TEXT,
    COALESCE(u.avatar_url, u.photo_url)::TEXT,
    cw.curr_r,
    pw.prev_r,
    (pw.prev_r - cw.curr_r)::INT AS delta,
    cw.metric
  FROM current_week cw
  JOIN previous_week pw ON pw.uid = cw.uid
  JOIN users u ON u.id = cw.uid
  WHERE (p_exclude_user IS NULL OR cw.uid <> p_exclude_user)
    AND (pw.prev_r - cw.curr_r) > 0
  ORDER BY delta DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION get_rising_stars(DATE, TEXT, TEXT, INT, UUID) TO authenticated, service_role;
