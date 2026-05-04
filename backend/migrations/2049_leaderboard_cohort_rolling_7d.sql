-- Widen the leaderboard cohort gate from "this calendar week" to a rolling
-- 7-day window so mid-week / Monday-morning visitors see all recently-active
-- users, not "#1 of 1".
--
-- Bug:
--   * compute_user_percentile() uses
--       DATE_TRUNC('week', x.created_at)::DATE = p_week_start
--     which empties on the first day of a new ISO week even when 5+ users
--     were active 24 hours ago.
--   * snapshot_weekly_leaderboard() uses workout_logs in last 30 days, which
--     misses users whose only XP source was meal logs / login streaks /
--     check-ins (the exact cohort migration 2044 was meant to include).
--   * Net effect: home banner shows "#2 of 6 active users", leaderboard
--     shows "#1 of 1" — same user, same day, two different cohort answers.
--
-- This migration aligns both functions on the same cohort definition:
-- "any xp_transaction in the last 7 days, rolling".

CREATE OR REPLACE FUNCTION public.compute_user_percentile(
  p_user_id uuid,
  p_week_start date DEFAULT (date_trunc('week'::text, now()))::date,
  p_board_type text DEFAULT 'xp'::text
)
RETURNS TABLE(rank integer, total integer, percentile numeric, tier text, metric_value numeric)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
    -- 2049: cohort = anyone with XP activity in the last 7 days (rolling).
    -- Replaces 2041's calendar-week gate which collapsed to "#1 of 1" on
    -- Mondays. Keeps the broader scope of 2044 while making it rolling.
    WHERE EXISTS (
      SELECT 1 FROM xp_transactions x
      WHERE x.user_id = u.id
        AND x.created_at >= NOW() - INTERVAL '7 days'
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
$function$;


-- Mirror the cohort gate change to snapshot_weekly_leaderboard so the weekly
-- archive matches live ranks (resolves the TODO at 2044:239-240).
CREATE OR REPLACE FUNCTION public.snapshot_weekly_leaderboard(
  p_week_start date DEFAULT (date_trunc('week'::text, (now() - '1 day'::interval)))::date
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
            WHEN 'volume' THEN COALESCE((SELECT SUM(COALESCE(duration_minutes,(total_time_seconds/60)::INT)) FROM workout_logs WHERE user_id = u.id AND status = 'completed' AND DATE_TRUNC('week', completed_at)::DATE = p_week_start), 0)
            WHEN 'streaks' THEN COALESCE((SELECT current_streak FROM user_login_streaks WHERE user_id = u.id), 0)
            ELSE 0
          END::NUMERIC AS metric,
          RANK() OVER (ORDER BY
            CASE v_board_type
              WHEN 'xp' THEN COALESCE((SELECT SUM(xp_amount) FROM xp_transactions WHERE user_id = u.id AND DATE_TRUNC('week', created_at)::DATE = p_week_start), 0)
              WHEN 'volume' THEN COALESCE((SELECT SUM(COALESCE(duration_minutes,(total_time_seconds/60)::INT)) FROM workout_logs WHERE user_id = u.id AND status = 'completed' AND DATE_TRUNC('week', completed_at)::DATE = p_week_start), 0)
              WHEN 'streaks' THEN COALESCE((SELECT current_streak FROM user_login_streaks WHERE user_id = u.id), 0)
              ELSE 0
            END DESC
          )::INT AS rank,
          COUNT(*) OVER () AS total
        FROM users u
        WHERE u.show_on_leaderboard = TRUE
          -- 2049: same rolling-7d xp gate as compute_user_percentile so
          -- weekly archive participant counts match the live board.
          AND EXISTS (
            SELECT 1 FROM xp_transactions x
            WHERE x.user_id = u.id
              AND x.created_at >= NOW() - INTERVAL '7 days'
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
$function$;
