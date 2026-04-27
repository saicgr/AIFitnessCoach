-- ============================================================================
-- Migration 1939: Week-1 cohort detection + leaderboard plumbing
-- ============================================================================
-- Purpose: Support Day-0 to Day-7 retention system.
--
-- Adds:
--   1. is_week_1_user(uuid) RPC - cohort detection
--   2. weekly_user_stats view - aggregated weekly activity
--   3. weekly_leaderboard_archive table - week-over-week snapshots
--   4. compute_user_percentile(uuid, date, text) RPC
--   5. get_near_you_leaderboard(uuid, date, text, text, int) RPC
--   6. get_rising_stars(date, text, text, int) RPC
--   7. get_next_tier_progress(uuid, date, text) RPC
--   8. snapshot_weekly_leaderboard() RPC - called by cron at week close
-- ============================================================================


-- ============================================================================
-- 1. Week-1 cohort detection
-- ============================================================================
CREATE OR REPLACE FUNCTION is_week_1_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_first_workout TIMESTAMPTZ;
  v_created TIMESTAMPTZ;
BEGIN
  SELECT first_workout_completed_at, created_at
  INTO v_first_workout, v_created
  FROM users WHERE id = p_user_id;

  -- Not a user yet
  IF v_created IS NULL THEN
    RETURN false;
  END IF;

  -- Pre-first-workout: count from signup
  IF v_first_workout IS NULL THEN
    RETURN (NOW() - v_created) < INTERVAL '7 days';
  END IF;

  -- Post-first-workout: count from first workout
  RETURN (NOW() - v_first_workout) < INTERVAL '7 days';
END;
$$;

GRANT EXECUTE ON FUNCTION is_week_1_user(UUID) TO authenticated, service_role;


-- ============================================================================
-- 2. weekly_user_stats view
-- ============================================================================
-- Aggregates per-user activity in ISO weeks: workouts, volume, xp, streak.
-- Week starts Monday 00:00 per ISO 8601 (PostgreSQL: DATE_TRUNC('week', ts)).
-- Used by percentile + leaderboard + rising stars.
--
-- NOTE: this computes on demand — acceptable at Zealova's current scale.
-- For >100k active users/week consider materializing.

CREATE OR REPLACE VIEW weekly_user_stats AS
SELECT
  wl.user_id,
  DATE_TRUNC('week', wl.completed_at)::date AS week_start,
  COUNT(wl.id) AS workouts_completed,
  COALESCE(SUM(wl.duration_minutes), 0) AS total_minutes,
  -- total_volume_kg kept as 0 for now; set derivation from sets_json is expensive
  -- and not on the critical path for percentile (we use workouts + minutes + xp).
  0::NUMERIC AS total_volume_kg
FROM workout_logs wl
WHERE wl.status = 'completed'
  AND wl.completed_at IS NOT NULL
GROUP BY wl.user_id, DATE_TRUNC('week', wl.completed_at)::date;

COMMENT ON VIEW weekly_user_stats IS
'Migration 1939: per-user weekly activity aggregation. Powers percentile + leaderboard + rising stars RPCs.';


-- ============================================================================
-- 3. weekly_leaderboard_archive table — week-close snapshots
-- ============================================================================
-- Populated by snapshot_weekly_leaderboard() RPC, called by cron Monday 00:05 UTC.
-- Previous week's rank becomes the baseline for "↑5 from last week" deltas and
-- Rising Stars computations.

CREATE TABLE IF NOT EXISTS weekly_leaderboard_archive (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  scope TEXT NOT NULL CHECK (scope IN ('global', 'country', 'friends')),
  country_code TEXT,  -- NULL for global, ISO for country scope
  rank INT NOT NULL,
  metric_value NUMERIC NOT NULL,
  total_participants INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, week_start, board_type, scope, country_code)
);

CREATE INDEX IF NOT EXISTS idx_wla_user_week ON weekly_leaderboard_archive(user_id, week_start DESC);
CREATE INDEX IF NOT EXISTS idx_wla_week_board_scope ON weekly_leaderboard_archive(week_start, board_type, scope);

ALTER TABLE weekly_leaderboard_archive ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS wla_select_public ON weekly_leaderboard_archive;
CREATE POLICY wla_select_public ON weekly_leaderboard_archive
  FOR SELECT USING (true);   -- leaderboards are public display data
DROP POLICY IF EXISTS wla_service_write ON weekly_leaderboard_archive;
CREATE POLICY wla_service_write ON weekly_leaderboard_archive
  FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT SELECT ON weekly_leaderboard_archive TO authenticated;
GRANT ALL ON weekly_leaderboard_archive TO service_role;


-- ============================================================================
-- 4. compute_user_percentile(user_id, week_start, board_type)
-- ============================================================================
-- Returns user's rank + percentile + tier among ACTIVE users this week.
-- "Active" = at least 1 workout completed this week (avoids "top 5% because
-- 95% of users are inactive" trap).

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
  -- Derive user's metric value for this board
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

  -- Build the full ranked board inline and find user's position
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


-- ============================================================================
-- 5. get_near_you_leaderboard — 5 above + you + 5 below
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
    WHERE EXISTS (
      SELECT 1 FROM workout_logs wl
      WHERE wl.user_id = u.id
        AND wl.status = 'completed'
        AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start
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


-- ============================================================================
-- 6. get_rising_stars — top N week-over-week rank improvers
-- ============================================================================
CREATE OR REPLACE FUNCTION get_rising_stars(
  p_week_start DATE DEFAULT DATE_TRUNC('week', NOW())::DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global',
  p_limit INT DEFAULT 3,
  p_exclude_user UUID DEFAULT NULL
) RETURNS TABLE (
  user_id UUID,
  username TEXT,
  display_name TEXT,
  current_rank INT,
  previous_rank INT,
  rank_delta INT,
  metric_value NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prev_week DATE := (p_week_start - INTERVAL '7 days')::DATE;
BEGIN
  RETURN QUERY
  WITH current_week AS (
    SELECT
      wla.user_id AS uid,
      wla.rank AS curr_r,
      wla.metric_value AS metric
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
    u.username,
    u.name,
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


-- ============================================================================
-- 7. get_next_tier_progress — how much further until next tier boundary
-- ============================================================================
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
  v_ratio NUMERIC;
  v_metric NUMERIC;
  v_next_target_rank INT;
  v_next_target_metric NUMERIC;
BEGIN
  SELECT rank, total, metric_value
  INTO v_rank, v_total, v_metric
  FROM compute_user_percentile(p_user_id, p_week_start, p_board_type);

  IF v_rank IS NULL OR v_rank = 0 OR v_total = 0 THEN
    RETURN QUERY SELECT 'starter'::TEXT, 'active'::TEXT, 0::INT, p_board_type::TEXT;
    RETURN;
  END IF;

  v_ratio := v_rank::NUMERIC / GREATEST(v_total, 1)::NUMERIC;

  -- Determine next-tier target rank (rank at tier boundary)
  IF v_ratio > 0.50 THEN
    current_tier := 'starter';
    next_tier := 'active';
    v_next_target_rank := CEIL(v_total * 0.50)::INT;
  ELSIF v_ratio > 0.25 THEN
    current_tier := 'active';
    next_tier := 'rising';
    v_next_target_rank := CEIL(v_total * 0.25)::INT;
  ELSIF v_ratio > 0.10 THEN
    current_tier := 'rising';
    next_tier := 'elite';
    v_next_target_rank := CEIL(v_total * 0.10)::INT;
  ELSIF v_ratio > 0.05 THEN
    current_tier := 'elite';
    next_tier := 'top';
    v_next_target_rank := CEIL(v_total * 0.05)::INT;
  ELSIF v_ratio > 0.01 THEN
    current_tier := 'top';
    next_tier := 'legendary';
    v_next_target_rank := CEIL(v_total * 0.01)::INT;
  ELSE
    current_tier := 'legendary';
    next_tier := NULL;
    v_next_target_rank := 1;
  END IF;

  -- Get the metric value at the target rank (approximate gap)
  IF next_tier IS NULL THEN
    units_to_next := 0;
  ELSE
    IF p_board_type = 'xp' THEN
      SELECT COALESCE(SUM(xp_amount), 0) INTO v_next_target_metric
      FROM (
        SELECT xt.user_id, SUM(xt.xp_amount) AS total_xp
        FROM xp_transactions xt
        WHERE DATE_TRUNC('week', xt.created_at)::DATE = p_week_start
        GROUP BY xt.user_id
        ORDER BY total_xp DESC
        LIMIT 1 OFFSET GREATEST(v_next_target_rank - 1, 0)
      ) q;
    ELSE
      v_next_target_metric := v_metric;  -- fallback
    END IF;

    units_to_next := GREATEST((v_next_target_metric - v_metric)::INT + 1, 1);
  END IF;

  metric_label := CASE p_board_type
    WHEN 'xp' THEN 'XP'
    WHEN 'volume' THEN 'min'
    WHEN 'streaks' THEN 'days'
    ELSE ''
  END;

  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION get_next_tier_progress(UUID, DATE, TEXT) TO authenticated, service_role;


-- ============================================================================
-- 8. snapshot_weekly_leaderboard — called by cron at week close
-- ============================================================================
CREATE OR REPLACE FUNCTION snapshot_weekly_leaderboard(
  p_week_start DATE DEFAULT (DATE_TRUNC('week', NOW() - INTERVAL '1 day'))::DATE
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT := 0;
  v_rows INT := 0;
  v_board_type TEXT;
  v_scope TEXT;
BEGIN
  FOR v_board_type IN SELECT UNNEST(ARRAY['xp', 'volume', 'streaks']) LOOP
    FOR v_scope IN SELECT UNNEST(ARRAY['global']) LOOP
      -- Global scope snapshot — country + friends can be added later
      INSERT INTO weekly_leaderboard_archive
        (user_id, week_start, board_type, scope, rank, metric_value, total_participants)
      SELECT
        q.user_id,
        p_week_start,
        v_board_type,
        v_scope,
        q.rank,
        q.metric,
        q.total
      FROM (
        SELECT
          u.id AS user_id,
          CASE v_board_type
            WHEN 'xp' THEN COALESCE((
              SELECT SUM(xp_amount) FROM xp_transactions
              WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start
            ), 0)
            WHEN 'volume' THEN COALESCE((
              SELECT SUM(duration_minutes) FROM workout_logs
              WHERE user_id = u.id AND status = 'completed'
                AND DATE_TRUNC('week', completed_at)::DATE = p_week_start
            ), 0)
            WHEN 'streaks' THEN COALESCE((
              SELECT current_streak FROM user_login_streaks WHERE user_id = u.id
            ), 0)
            ELSE 0
          END::NUMERIC AS metric,
          RANK() OVER (ORDER BY
            CASE v_board_type
              WHEN 'xp' THEN COALESCE((
                SELECT SUM(xp_amount) FROM xp_transactions
                WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start
              ), 0)
              WHEN 'volume' THEN COALESCE((
                SELECT SUM(duration_minutes) FROM workout_logs
                WHERE user_id = u.id AND status = 'completed'
                  AND DATE_TRUNC('week', completed_at)::DATE = p_week_start
              ), 0)
              WHEN 'streaks' THEN COALESCE((
                SELECT current_streak FROM user_login_streaks WHERE user_id = u.id
              ), 0)
              ELSE 0
            END DESC
          )::INT AS rank,
          COUNT(*) OVER () AS total
        FROM users u
        WHERE EXISTS (
          SELECT 1 FROM workout_logs wl
          WHERE wl.user_id = u.id
            AND wl.status = 'completed'
            AND DATE_TRUNC('week', wl.completed_at)::DATE = p_week_start
        )
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

COMMENT ON FUNCTION snapshot_weekly_leaderboard IS
'Migration 1939: Archive the just-closed ISO week''s global leaderboard. Invoke from cron Monday 00:05 UTC (or 00:05 local per-timezone for better accuracy).';
