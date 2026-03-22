-- Migration 1676: Fix ambiguous column reference in get_user_progress_summary
-- The return table column "total_volume_kg" conflicts with the view column of
-- the same name, causing PostgreSQL error 42702 on every call.

CREATE OR REPLACE FUNCTION get_user_progress_summary(p_user_id UUID)
RETURNS TABLE (
  total_workouts BIGINT,
  total_volume_kg NUMERIC,
  total_prs INT,
  first_workout_date DATE,
  last_workout_date DATE,
  volume_increase_percent NUMERIC,
  avg_weekly_workouts NUMERIC,
  current_streak INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_recent_volume NUMERIC;
  v_older_volume NUMERIC;
  v_first_workout DATE;
  v_last_workout DATE;
  v_weeks_active INT;
BEGIN
  -- Get workout date range
  SELECT
    MIN(wl.completed_at)::date,
    MAX(wl.completed_at)::date
  INTO v_first_workout, v_last_workout
  FROM workout_logs wl
  WHERE wl.user_id = p_user_id AND wl.completed_at IS NOT NULL;

  -- Calculate weeks active
  IF v_first_workout IS NOT NULL AND v_last_workout IS NOT NULL THEN
    v_weeks_active := GREATEST(1, EXTRACT(WEEK FROM AGE(v_last_workout, v_first_workout))::int + 1);
  ELSE
    v_weeks_active := 1;
  END IF;

  -- Get recent 4 weeks volume
  SELECT COALESCE(SUM(wps.total_volume_kg), 0)
  INTO v_recent_volume
  FROM weekly_progress_summary wps
  WHERE wps.user_id = p_user_id
    AND wps.week_start >= CURRENT_DATE - INTERVAL '4 weeks';

  -- Get previous 4 weeks volume (4-8 weeks ago)
  SELECT COALESCE(SUM(wps.total_volume_kg), 0)
  INTO v_older_volume
  FROM weekly_progress_summary wps
  WHERE wps.user_id = p_user_id
    AND wps.week_start >= CURRENT_DATE - INTERVAL '8 weeks'
    AND wps.week_start < CURRENT_DATE - INTERVAL '4 weeks';

  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM workout_logs wl2 WHERE wl2.user_id = p_user_id AND wl2.completed_at IS NOT NULL)::BIGINT,
    (SELECT COALESCE(SUM(wps2.total_volume_kg), 0) FROM weekly_progress_summary wps2 WHERE wps2.user_id = p_user_id),
    (SELECT COUNT(*)::INT FROM personal_records pr WHERE pr.user_id = p_user_id),
    v_first_workout,
    v_last_workout,
    CASE
      WHEN v_older_volume > 0 THEN
        ROUND(((v_recent_volume - v_older_volume) / v_older_volume) * 100, 1)
      ELSE 0::NUMERIC
    END,
    ROUND((SELECT COUNT(*) FROM workout_logs wl3 WHERE wl3.user_id = p_user_id AND wl3.completed_at IS NOT NULL)::NUMERIC / GREATEST(v_weeks_active, 1), 2),
    COALESCE((SELECT us.current_streak FROM user_streaks us WHERE us.user_id = p_user_id AND us.streak_type = 'workout'), 0)::INT;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_progress_summary(UUID) TO authenticated, service_role;
