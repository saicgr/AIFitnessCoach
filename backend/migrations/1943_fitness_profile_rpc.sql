-- Migration 1943: get_user_fitness_profile + 6 per-axis scorer helpers.
-- Applied to prod Supabase 2026-04-18 via MCP.
--
-- Returns both target + viewer scores for the dual-overlay radar in the
-- Discover peek sheet. Each axis scored 0.0-1.0 via raw/ceiling clamp.
--
-- Ceilings anchored to published research (see plan file for sources):
--   Strength     → 6 PRs / 30 days  (intermediate→advanced threshold)
--   Muscle       → 5 workout types / 14 days  (coverage variety)
--   Recovery     → 4 rest days / 14 days  (ACSM 2 rest/week)
--   Consistency  → 66 streak days  (Lally habit-formation median)
--   Endurance    → 500 min / 14 days  (~3.5h/wk, above WHO minimum)
--   Nutrition    → 10 food-log days / 14 days  (~71% adherence)
--
-- Privacy: when target has profile_stats_visible=FALSE, all target_* axes
-- and bio return NULL + target_stats_hidden=TRUE. Viewer always sees self.
-- Self-view (viewer == target) bypasses the hidden gate.


-- ─── per-axis scorer helpers ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION _score_strength(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0, COUNT(*)::NUMERIC / 6)
  FROM personal_records
  WHERE user_id = p_user_id
    AND created_at > NOW() - INTERVAL '30 days';
$$;

CREATE OR REPLACE FUNCTION _score_muscle(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0, COUNT(DISTINCT LOWER(w.type))::NUMERIC / 5)
  FROM workout_logs wl
  JOIN workouts w ON w.id = wl.workout_id
  WHERE wl.user_id = p_user_id
    AND wl.status = 'completed'
    AND wl.completed_at > NOW() - INTERVAL '14 days'
    AND w.type IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION _score_recovery(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0,
    GREATEST(0, 14 - COUNT(DISTINCT DATE(wl.completed_at)))::NUMERIC / 4
  )
  FROM workout_logs wl
  WHERE wl.user_id = p_user_id
    AND wl.status = 'completed'
    AND wl.completed_at > NOW() - INTERVAL '14 days';
$$;

CREATE OR REPLACE FUNCTION _score_consistency(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0, COALESCE(current_streak, 0)::NUMERIC / 66)
  FROM user_login_streaks WHERE user_id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION _score_endurance(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0, COALESCE(SUM(duration_minutes), 0)::NUMERIC / 500)
  FROM workout_logs
  WHERE user_id = p_user_id
    AND status = 'completed'
    AND completed_at > NOW() - INTERVAL '14 days';
$$;

CREATE OR REPLACE FUNCTION _score_nutrition(p_user_id UUID) RETURNS NUMERIC
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT LEAST(1.0, COUNT(DISTINCT DATE(logged_at))::NUMERIC / 10)
  FROM food_logs
  WHERE user_id = p_user_id
    AND deleted_at IS NULL
    AND logged_at > NOW() - INTERVAL '14 days';
$$;


-- ─── public composite RPC ───────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_user_fitness_profile(
  p_target_user_id UUID,
  p_viewer_user_id UUID DEFAULT NULL
) RETURNS TABLE (
  target_strength NUMERIC, target_muscle NUMERIC, target_recovery NUMERIC,
  target_consistency NUMERIC, target_endurance NUMERIC, target_nutrition NUMERIC,
  viewer_strength NUMERIC, viewer_muscle NUMERIC, viewer_recovery NUMERIC,
  viewer_consistency NUMERIC, viewer_endurance NUMERIC, viewer_nutrition NUMERIC,
  target_bio TEXT, target_stats_hidden BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_target_hidden BOOLEAN;
BEGIN
  SELECT NOT COALESCE(profile_stats_visible, TRUE) INTO v_target_hidden
  FROM users WHERE id = p_target_user_id;

  -- Self-view bypasses privacy gate
  IF p_viewer_user_id IS NOT NULL AND p_viewer_user_id = p_target_user_id THEN
    v_target_hidden := FALSE;
  END IF;

  RETURN QUERY
  SELECT
    CASE WHEN v_target_hidden THEN NULL ELSE _score_strength(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_muscle(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_recovery(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_consistency(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_endurance(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_nutrition(p_target_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_strength(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_muscle(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_recovery(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_consistency(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_endurance(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_nutrition(p_viewer_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE (SELECT bio::TEXT FROM users WHERE id = p_target_user_id) END,
    v_target_hidden;
END;
$$;

GRANT EXECUTE ON FUNCTION _score_strength(UUID)    TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION _score_muscle(UUID)      TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION _score_recovery(UUID)    TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION _score_consistency(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION _score_endurance(UUID)   TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION _score_nutrition(UUID)   TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_user_fitness_profile(UUID, UUID) TO authenticated, service_role;
