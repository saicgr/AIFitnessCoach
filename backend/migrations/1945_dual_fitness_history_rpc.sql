-- Migration 1945: dual-series fitness history RPC for peek-sheet scrubber.
-- Applied to prod Supabase 2026-04-18 via MCP.
--
-- Returns both target + viewer snapshots merged by date so the Flutter UI
-- can animate the radar as the user drags a time slider.
--
-- Privacy:
--   * show_on_leaderboard=FALSE → empty set
--   * profile_stats_visible=FALSE → target_* columns NULL (viewer still gets own)
--   * Self-view bypasses stats gate

CREATE OR REPLACE FUNCTION get_dual_fitness_shape_history(
  p_target_user_id UUID,
  p_viewer_user_id UUID,
  p_days_back INT DEFAULT 90
) RETURNS TABLE (
  snapshot_date DATE,
  target_strength NUMERIC, target_muscle NUMERIC, target_recovery NUMERIC,
  target_consistency NUMERIC, target_endurance NUMERIC, target_nutrition NUMERIC,
  viewer_strength NUMERIC, viewer_muscle NUMERIC, viewer_recovery NUMERIC,
  viewer_consistency NUMERIC, viewer_endurance NUMERIC, viewer_nutrition NUMERIC
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_target_show BOOLEAN;
  v_target_stats BOOLEAN;
BEGIN
  SELECT u.show_on_leaderboard, u.profile_stats_visible
    INTO v_target_show, v_target_stats
  FROM users u WHERE u.id = p_target_user_id;

  IF v_target_show IS NULL OR v_target_show = FALSE THEN
    RETURN;
  END IF;

  IF p_viewer_user_id = p_target_user_id THEN
    v_target_stats := TRUE;
  END IF;

  RETURN QUERY
  WITH all_dates AS (
    SELECT fps.snapshot_date AS d
    FROM fitness_profile_snapshots fps
    WHERE (fps.user_id = p_target_user_id OR fps.user_id = p_viewer_user_id)
      AND fps.snapshot_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
    GROUP BY fps.snapshot_date
    ORDER BY fps.snapshot_date
  ),
  t AS (
    SELECT fps.snapshot_date AS d, fps.strength, fps.muscle, fps.recovery,
           fps.consistency, fps.endurance, fps.nutrition
    FROM fitness_profile_snapshots fps
    WHERE fps.user_id = p_target_user_id
      AND fps.snapshot_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
  ),
  v AS (
    SELECT fps.snapshot_date AS d, fps.strength, fps.muscle, fps.recovery,
           fps.consistency, fps.endurance, fps.nutrition
    FROM fitness_profile_snapshots fps
    WHERE fps.user_id = p_viewer_user_id
      AND fps.snapshot_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
  )
  SELECT
    ad.d,
    CASE WHEN v_target_stats THEN t.strength    ELSE NULL END,
    CASE WHEN v_target_stats THEN t.muscle      ELSE NULL END,
    CASE WHEN v_target_stats THEN t.recovery    ELSE NULL END,
    CASE WHEN v_target_stats THEN t.consistency ELSE NULL END,
    CASE WHEN v_target_stats THEN t.endurance   ELSE NULL END,
    CASE WHEN v_target_stats THEN t.nutrition   ELSE NULL END,
    v.strength, v.muscle, v.recovery,
    v.consistency, v.endurance, v.nutrition
  FROM all_dates ad
  LEFT JOIN t ON t.d = ad.d
  LEFT JOIN v ON v.d = ad.d
  ORDER BY ad.d;
END;
$$;

GRANT EXECUTE ON FUNCTION get_dual_fitness_shape_history(UUID, UUID, INT)
  TO authenticated, service_role;

-- Seed today's snapshots so the scrubber has at least one data point.
SELECT snapshot_all_active_fitness_profiles(CURRENT_DATE);
