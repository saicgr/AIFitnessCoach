-- Migration 096: Progress Analytics Views and Functions
-- Creates views and functions for tracking user progress over time
-- Supports strength progression, volume tracking, and summary statistics

-- ============================================================================
-- Weekly Progress Summary View
-- Aggregates workout data by week for trend analysis
-- ============================================================================
CREATE OR REPLACE VIEW weekly_progress_summary AS
SELECT
  user_id,
  DATE_TRUNC('week', completed_at)::date as week_start,
  EXTRACT(WEEK FROM completed_at)::int as week_number,
  EXTRACT(YEAR FROM completed_at)::int as year,
  COUNT(*)::int as workouts_completed,
  COALESCE(SUM(duration_minutes), 0)::int as total_minutes,
  COALESCE(AVG(duration_minutes), 0)::numeric(10,2) as avg_duration_minutes,
  COALESCE(SUM(
    (SELECT COALESCE(SUM((set_data->>'weight_kg')::numeric * (set_data->>'reps')::numeric), 0)
     FROM jsonb_array_elements(exercises_performance) as exercise,
          jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::numeric(10,2) as total_volume_kg,
  COALESCE(SUM(
    (SELECT COUNT(*)
     FROM jsonb_array_elements(exercises_performance) as exercise,
          jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_sets,
  COALESCE(SUM(
    (SELECT COALESCE(SUM((set_data->>'reps')::int), 0)
     FROM jsonb_array_elements(exercises_performance) as exercise,
          jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_reps
FROM workout_logs
WHERE completed_at IS NOT NULL
  AND exercises_performance IS NOT NULL
GROUP BY user_id, DATE_TRUNC('week', completed_at), EXTRACT(WEEK FROM completed_at), EXTRACT(YEAR FROM completed_at)
ORDER BY week_start DESC;

-- Grant access to the view
GRANT SELECT ON weekly_progress_summary TO authenticated, anon, service_role;

-- ============================================================================
-- Muscle Group Weekly Volume View
-- Tracks volume per muscle group over time
-- ============================================================================
-- Drop existing view first (in case it exists from a previous run)
DROP VIEW IF EXISTS muscle_group_weekly_volume CASCADE;
-- Then try to drop as table (in case it was created as a table in an older migration)
-- This will silently do nothing if it doesn't exist or is not a table
DO $$
BEGIN
    EXECUTE 'DROP TABLE IF EXISTS muscle_group_weekly_volume CASCADE';
EXCEPTION WHEN wrong_object_type THEN
    -- Already dropped as a view, or doesn't exist - ignore
    NULL;
END $$;
CREATE VIEW muscle_group_weekly_volume AS
SELECT
  wl.user_id,
  DATE_TRUNC('week', wl.completed_at)::date as week_start,
  LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other')) as muscle_group,
  COUNT(DISTINCT wl.id)::int as workout_count,
  COALESCE(SUM(
    (SELECT COUNT(*)
     FROM jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_sets,
  COALESCE(SUM(
    (SELECT COALESCE(SUM((set_data->>'reps')::int), 0)
     FROM jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::int as total_reps,
  COALESCE(SUM(
    (SELECT COALESCE(SUM((set_data->>'weight_kg')::numeric * (set_data->>'reps')::numeric), 0)
     FROM jsonb_array_elements(exercise->'sets') as set_data)
  ), 0)::numeric(10,2) as total_volume_kg,
  COALESCE(MAX(
    (SELECT MAX((set_data->>'weight_kg')::numeric)
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE (set_data->>'weight_kg') IS NOT NULL)
  ), 0)::numeric(10,2) as max_weight_kg
FROM workout_logs wl,
     jsonb_array_elements(wl.exercises_performance) as exercise
WHERE wl.completed_at IS NOT NULL
  AND wl.exercises_performance IS NOT NULL
GROUP BY wl.user_id, DATE_TRUNC('week', wl.completed_at), LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other'))
ORDER BY week_start DESC, muscle_group;

-- Grant access to the view
GRANT SELECT ON muscle_group_weekly_volume TO authenticated, anon, service_role;

-- ============================================================================
-- Exercise Strength Progress View
-- Tracks max weight and estimated 1RM per exercise over time
-- ============================================================================
CREATE OR REPLACE VIEW exercise_strength_progress AS
SELECT
  wl.user_id,
  DATE_TRUNC('week', wl.completed_at)::date as week_start,
  LOWER(COALESCE(exercise->>'name', exercise->>'exercise_name', 'unknown')) as exercise_name,
  LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other')) as muscle_group,
  COUNT(*)::int as times_performed,
  COALESCE(MAX(
    (SELECT MAX((set_data->>'weight_kg')::numeric)
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE (set_data->>'weight_kg') IS NOT NULL)
  ), 0)::numeric(10,2) as max_weight_kg,
  -- Estimated 1RM using Epley formula: weight * (1 + reps/30)
  COALESCE(MAX(
    (SELECT MAX(
      (set_data->>'weight_kg')::numeric * (1 + (set_data->>'reps')::numeric / 30)
    )
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE (set_data->>'weight_kg') IS NOT NULL
       AND (set_data->>'reps') IS NOT NULL
       AND (set_data->>'reps')::int BETWEEN 1 AND 12)
  ), 0)::numeric(10,2) as estimated_1rm_kg
FROM workout_logs wl,
     jsonb_array_elements(wl.exercises_performance) as exercise
WHERE wl.completed_at IS NOT NULL
  AND wl.exercises_performance IS NOT NULL
GROUP BY wl.user_id, DATE_TRUNC('week', wl.completed_at),
         LOWER(COALESCE(exercise->>'name', exercise->>'exercise_name', 'unknown')),
         LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other'))
ORDER BY week_start DESC, exercise_name;

-- Grant access to the view
GRANT SELECT ON exercise_strength_progress TO authenticated, anon, service_role;

-- ============================================================================
-- Progress Charts Analytics Log Table
-- Tracks when users view progress charts for analytics
-- ============================================================================
CREATE TABLE IF NOT EXISTS progress_charts_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chart_type TEXT NOT NULL, -- 'strength', 'volume', 'summary', 'muscle_group'
  time_range TEXT NOT NULL, -- '4_weeks', '8_weeks', '12_weeks', 'all_time'
  muscle_group TEXT, -- Optional filter
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  session_duration_seconds INT, -- How long they viewed the charts

  CONSTRAINT valid_chart_type CHECK (chart_type IN ('strength', 'volume', 'summary', 'muscle_group', 'all'))
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_progress_charts_views_user ON progress_charts_views(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_charts_views_date ON progress_charts_views(viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_progress_charts_views_type ON progress_charts_views(chart_type);

-- Enable RLS
ALTER TABLE progress_charts_views ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can insert own progress chart views"
  ON progress_charts_views
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own progress chart views"
  ON progress_charts_views
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Service role can access all
CREATE POLICY "Service role has full access to progress chart views"
  ON progress_charts_views
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT ON progress_charts_views TO authenticated;
GRANT ALL ON progress_charts_views TO service_role;

-- ============================================================================
-- Helper function: Get user progress summary statistics
-- ============================================================================
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
    MIN(completed_at)::date,
    MAX(completed_at)::date
  INTO v_first_workout, v_last_workout
  FROM workout_logs
  WHERE user_id = p_user_id AND completed_at IS NOT NULL;

  -- Calculate weeks active
  IF v_first_workout IS NOT NULL AND v_last_workout IS NOT NULL THEN
    v_weeks_active := GREATEST(1, EXTRACT(WEEK FROM AGE(v_last_workout, v_first_workout))::int + 1);
  ELSE
    v_weeks_active := 1;
  END IF;

  -- Get recent 4 weeks volume
  SELECT COALESCE(SUM(total_volume_kg), 0)
  INTO v_recent_volume
  FROM weekly_progress_summary
  WHERE user_id = p_user_id
    AND week_start >= CURRENT_DATE - INTERVAL '4 weeks';

  -- Get previous 4 weeks volume (4-8 weeks ago)
  SELECT COALESCE(SUM(total_volume_kg), 0)
  INTO v_older_volume
  FROM weekly_progress_summary
  WHERE user_id = p_user_id
    AND week_start >= CURRENT_DATE - INTERVAL '8 weeks'
    AND week_start < CURRENT_DATE - INTERVAL '4 weeks';

  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM workout_logs WHERE user_id = p_user_id AND completed_at IS NOT NULL)::BIGINT,
    (SELECT COALESCE(SUM(total_volume_kg), 0) FROM weekly_progress_summary WHERE user_id = p_user_id),
    (SELECT COUNT(*)::INT FROM personal_records WHERE user_id = p_user_id),
    v_first_workout,
    v_last_workout,
    CASE
      WHEN v_older_volume > 0 THEN
        ROUND(((v_recent_volume - v_older_volume) / v_older_volume) * 100, 1)
      ELSE 0
    END,
    ROUND((SELECT COUNT(*) FROM workout_logs WHERE user_id = p_user_id AND completed_at IS NOT NULL)::NUMERIC / GREATEST(v_weeks_active, 1), 2),
    COALESCE((SELECT current_streak FROM user_streaks WHERE user_id = p_user_id AND streak_type = 'workout'), 0)::INT;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_progress_summary(UUID) TO authenticated, service_role;

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON VIEW weekly_progress_summary IS 'Aggregated weekly workout statistics for progress tracking';
COMMENT ON VIEW muscle_group_weekly_volume IS 'Weekly volume breakdown by muscle group for targeted progress analysis';
COMMENT ON VIEW exercise_strength_progress IS 'Weekly strength progression per exercise with estimated 1RM';
COMMENT ON TABLE progress_charts_views IS 'Tracks user engagement with progress charts for analytics';
COMMENT ON FUNCTION get_user_progress_summary IS 'Returns comprehensive progress summary for a user';
