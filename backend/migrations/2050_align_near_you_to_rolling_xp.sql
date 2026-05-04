-- Mirror migration 2049's cohort gate inside get_near_you_leaderboard so the
-- "Near You" rank list isn't empty on Mondays / first day of a new ISO week.
--
-- Bug: 2049 widened compute_user_percentile to "any xp_transactions in last
-- 7 rolling days" (so a user sees "#1 of 5 active users" right after week
-- rollover). get_near_you_leaderboard was missed — it still gates on
--     EXISTS(... DATE_TRUNC('week', xt.created_at)::DATE = p_week_start)
-- which empties the cohort to just the current user when nobody else has
-- earned XP in the new calendar week yet. Result: hero says "#1 of 5",
-- list under XP/Volume/Streaks shows ONLY the current user.
--
-- Fix: rolling-7d cohort gate. The METRIC stays calendar-week aligned (XP
-- earned this week so far) — only the cohort definition changes.

CREATE OR REPLACE FUNCTION public.get_near_you_leaderboard(
  p_user_id uuid,
  p_week_start date DEFAULT (date_trunc('week'::text, now()))::date,
  p_board_type text DEFAULT 'xp'::text,
  p_scope text DEFAULT 'global'::text,
  p_window integer DEFAULT 5
)
RETURNS TABLE(
  user_id uuid,
  username text,
  display_name text,
  rank integer,
  metric_value numeric,
  is_current_user boolean
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  WITH board AS (
    SELECT
      u.id AS uid,
      u.username::TEXT AS username,
      (u.name)::TEXT   AS display_name,
      CASE p_board_type
        WHEN 'xp' THEN COALESCE((
          SELECT SUM(xt.xp_amount) FROM xp_transactions xt
          WHERE xt.user_id = u.id
            AND DATE_TRUNC('week', xt.created_at)::DATE = p_week_start
        ), 0)
        WHEN 'volume' THEN COALESCE((
          SELECT SUM(wl2.duration_minutes) FROM workout_logs wl2
          WHERE wl2.user_id = u.id AND wl2.status = 'completed'
            AND DATE_TRUNC('week', wl2.completed_at)::DATE = p_week_start
        ), 0)
        WHEN 'streaks' THEN COALESCE((
          SELECT uls.current_streak FROM user_login_streaks uls
          WHERE uls.user_id = u.id
        ), 0)
        ELSE 0
      END AS metric
    FROM users u
    -- 2050: cohort = anyone with XP activity in the last 7 days (rolling).
    -- Mirrors compute_user_percentile() and snapshot_weekly_leaderboard()
    -- after migration 2049 so the hero, the rank list, and the weekly
    -- archive all agree on "active users".
    WHERE EXISTS (
      SELECT 1 FROM xp_transactions x
      WHERE x.user_id = u.id
        AND x.created_at >= NOW() - INTERVAL '7 days'
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
    w.metric::NUMERIC,
    (w.uid = p_user_id) AS is_current_user
  FROM window_rows w
  ORDER BY w.r;
END;
$function$;

COMMENT ON FUNCTION public.get_near_you_leaderboard IS
  'Rolling-7d cohort gate matches migration 2049 (compute_user_percentile). '
  'Hero banner, near-you list, and weekly archive participant counts now '
  'agree on "active users".';
