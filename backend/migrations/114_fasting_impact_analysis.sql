-- ============================================================================
-- Migration 114: Fasting Impact Analysis
-- ============================================================================
-- This migration adds support for:
-- 1. fasting_weight_correlation - Track weight relative to fasting days
-- 2. fasting_goal_impact - Analyze how fasting affects goal achievement
-- 3. Extended fasting_user_context columns for AI coaching
-- 4. Views for weight trends and performance summaries
-- ============================================================================

-- ============================================================================
-- PART 1: FASTING WEIGHT CORRELATION TABLE
-- ============================================================================
-- Tracks daily weight entries correlated with fasting activity

CREATE TABLE IF NOT EXISTS fasting_weight_correlation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,

  -- Weight data
  weight_kg DECIMAL(5,2) NOT NULL,
  weight_logged_at TIMESTAMP WITH TIME ZONE NOT NULL,

  -- Fasting context
  is_fasting_day BOOLEAN NOT NULL DEFAULT false,
  fasting_record_id UUID REFERENCES fasting_records(id) ON DELETE SET NULL,
  fasting_protocol TEXT,
  fasting_duration_minutes INTEGER DEFAULT 0,
  fasting_completed_goal BOOLEAN DEFAULT false,
  days_since_last_fast INTEGER DEFAULT 0,

  -- Workout context
  workout_completed_that_day BOOLEAN DEFAULT false,
  workout_type TEXT,

  -- Notes
  notes TEXT,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Ensure one entry per user per day
  UNIQUE(user_id, date)
);

-- RLS for fasting_weight_correlation
ALTER TABLE fasting_weight_correlation ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fasting_weight_correlation_select_policy ON fasting_weight_correlation;
CREATE POLICY fasting_weight_correlation_select_policy ON fasting_weight_correlation
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_weight_correlation_insert_policy ON fasting_weight_correlation;
CREATE POLICY fasting_weight_correlation_insert_policy ON fasting_weight_correlation
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_weight_correlation_update_policy ON fasting_weight_correlation;
CREATE POLICY fasting_weight_correlation_update_policy ON fasting_weight_correlation
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_weight_correlation_delete_policy ON fasting_weight_correlation;
CREATE POLICY fasting_weight_correlation_delete_policy ON fasting_weight_correlation
  FOR DELETE USING (auth.uid() = user_id);

-- Service role policy for backend access
DROP POLICY IF EXISTS fasting_weight_correlation_service_all ON fasting_weight_correlation;
CREATE POLICY fasting_weight_correlation_service_all ON fasting_weight_correlation
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_fasting_weight_correlation_user ON fasting_weight_correlation(user_id);
CREATE INDEX IF NOT EXISTS idx_fasting_weight_correlation_user_date ON fasting_weight_correlation(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_fasting_weight_correlation_fasting_day ON fasting_weight_correlation(user_id, is_fasting_day);
CREATE INDEX IF NOT EXISTS idx_fasting_weight_correlation_fasting_record ON fasting_weight_correlation(fasting_record_id);

-- Comments
COMMENT ON TABLE fasting_weight_correlation IS 'Tracks daily weight entries correlated with fasting activity for trend analysis';
COMMENT ON COLUMN fasting_weight_correlation.is_fasting_day IS 'Whether the user completed a fast on this day';
COMMENT ON COLUMN fasting_weight_correlation.days_since_last_fast IS 'Number of days since the user last completed a fast';
COMMENT ON COLUMN fasting_weight_correlation.fasting_completed_goal IS 'Whether the fasting goal was achieved on this day';

-- ============================================================================
-- PART 2: FASTING GOAL IMPACT TABLE
-- ============================================================================
-- Stores periodic analysis of how fasting affects goal achievement

CREATE TABLE IF NOT EXISTS fasting_goal_impact (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,

  -- Analysis period
  analysis_period_start DATE NOT NULL,
  analysis_period_end DATE NOT NULL,

  -- Fasting metrics
  total_fasting_days INTEGER NOT NULL DEFAULT 0,
  total_non_fasting_days INTEGER NOT NULL DEFAULT 0,

  -- Weight metrics
  avg_weight_on_fasting_days DECIMAL(5,2),
  avg_weight_on_non_fasting_days DECIMAL(5,2),
  weight_change_during_period DECIMAL(5,2),

  -- Workout performance metrics
  avg_workout_performance_fasting DECIMAL(5,2), -- percentage of goal reps completed
  avg_workout_performance_non_fasting DECIMAL(5,2),

  -- Goal achievement metrics
  goals_achieved_on_fasting_days INTEGER DEFAULT 0,
  goals_achieved_on_non_fasting_days INTEGER DEFAULT 0,
  weekly_goal_achievement_rate_fasting DECIMAL(5,2),
  weekly_goal_achievement_rate_non_fasting DECIMAL(5,2),

  -- Correlation analysis
  correlation_score DECIMAL(3,2), -- -1 to 1, positive = fasting helps goals

  -- AI-generated insight
  insight_generated TEXT,
  insight_type TEXT CHECK (insight_type IN ('positive', 'neutral', 'negative', 'needs_more_data')),

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for fasting_goal_impact
ALTER TABLE fasting_goal_impact ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fasting_goal_impact_select_policy ON fasting_goal_impact;
CREATE POLICY fasting_goal_impact_select_policy ON fasting_goal_impact
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_goal_impact_insert_policy ON fasting_goal_impact;
CREATE POLICY fasting_goal_impact_insert_policy ON fasting_goal_impact
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_goal_impact_update_policy ON fasting_goal_impact;
CREATE POLICY fasting_goal_impact_update_policy ON fasting_goal_impact
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_goal_impact_delete_policy ON fasting_goal_impact;
CREATE POLICY fasting_goal_impact_delete_policy ON fasting_goal_impact
  FOR DELETE USING (auth.uid() = user_id);

-- Service role policy for backend access
DROP POLICY IF EXISTS fasting_goal_impact_service_all ON fasting_goal_impact;
CREATE POLICY fasting_goal_impact_service_all ON fasting_goal_impact
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_fasting_goal_impact_user ON fasting_goal_impact(user_id);
CREATE INDEX IF NOT EXISTS idx_fasting_goal_impact_user_period ON fasting_goal_impact(user_id, analysis_period_end DESC);
CREATE INDEX IF NOT EXISTS idx_fasting_goal_impact_insight_type ON fasting_goal_impact(user_id, insight_type);

-- Comments
COMMENT ON TABLE fasting_goal_impact IS 'Stores periodic analysis of how fasting affects fitness goal achievement';
COMMENT ON COLUMN fasting_goal_impact.correlation_score IS 'Statistical correlation between fasting and goal progress (-1 to 1, positive means fasting helps)';
COMMENT ON COLUMN fasting_goal_impact.insight_type IS 'Classification of the impact: positive, neutral, negative, or needs_more_data';
COMMENT ON COLUMN fasting_goal_impact.avg_workout_performance_fasting IS 'Average percentage of workout goals completed on fasting days';

-- ============================================================================
-- PART 3: EXTEND FASTING USER CONTEXT TABLE
-- ============================================================================
-- Add additional columns to existing fasting_user_context table for AI coaching

-- Add weight_kg column for weight-related context events
ALTER TABLE fasting_user_context
ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2);

-- Add impact_insight column for storing impact analysis context
ALTER TABLE fasting_user_context
ADD COLUMN IF NOT EXISTS impact_insight TEXT;

-- Update context_type comment to include new event types
COMMENT ON COLUMN fasting_user_context.context_type IS 'Event type: fast_started, zone_entered, fast_ended, fast_cancelled, note_added, mood_logged, weight_logged, goal_progress, impact_analyzed';
COMMENT ON COLUMN fasting_user_context.weight_kg IS 'Weight in kg when context_type is weight_logged';
COMMENT ON COLUMN fasting_user_context.impact_insight IS 'AI-generated insight when context_type is impact_analyzed';

-- ============================================================================
-- PART 4: VIEWS FOR TREND ANALYSIS
-- ============================================================================

-- View: fasting_weight_trend
-- Shows weight trend correlated with fasting days for each user
CREATE OR REPLACE VIEW fasting_weight_trend AS
SELECT
  fwc.user_id,
  fwc.date,
  fwc.weight_kg,
  fwc.is_fasting_day,
  fwc.fasting_protocol,
  fwc.fasting_duration_minutes,
  fwc.fasting_completed_goal,
  fwc.days_since_last_fast,
  fwc.workout_completed_that_day,
  fwc.workout_type,
  -- Calculate 7-day moving average
  AVG(fwc.weight_kg) OVER (
    PARTITION BY fwc.user_id
    ORDER BY fwc.date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS weight_7day_avg,
  -- Calculate weight change from previous day
  fwc.weight_kg - LAG(fwc.weight_kg) OVER (
    PARTITION BY fwc.user_id
    ORDER BY fwc.date
  ) AS weight_change_from_previous,
  -- Calculate cumulative average on fasting days only
  AVG(CASE WHEN fwc.is_fasting_day THEN fwc.weight_kg END) OVER (
    PARTITION BY fwc.user_id
    ORDER BY fwc.date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_fasting_day_avg,
  -- Calculate cumulative average on non-fasting days only
  AVG(CASE WHEN NOT fwc.is_fasting_day THEN fwc.weight_kg END) OVER (
    PARTITION BY fwc.user_id
    ORDER BY fwc.date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_non_fasting_day_avg
FROM fasting_weight_correlation fwc
ORDER BY fwc.user_id, fwc.date DESC;

-- Grant access to the view
GRANT SELECT ON fasting_weight_trend TO authenticated;

-- View: fasting_performance_summary
-- Weekly and monthly performance comparison between fasting and non-fasting days
CREATE OR REPLACE VIEW fasting_performance_summary AS
WITH weekly_data AS (
  SELECT
    fwc.user_id,
    DATE_TRUNC('week', fwc.date)::DATE AS week_start,
    COUNT(*) FILTER (WHERE fwc.is_fasting_day) AS fasting_days_count,
    COUNT(*) FILTER (WHERE NOT fwc.is_fasting_day) AS non_fasting_days_count,
    AVG(fwc.weight_kg) FILTER (WHERE fwc.is_fasting_day) AS avg_weight_fasting,
    AVG(fwc.weight_kg) FILTER (WHERE NOT fwc.is_fasting_day) AS avg_weight_non_fasting,
    COUNT(*) FILTER (WHERE fwc.workout_completed_that_day AND fwc.is_fasting_day) AS workouts_on_fasting_days,
    COUNT(*) FILTER (WHERE fwc.workout_completed_that_day AND NOT fwc.is_fasting_day) AS workouts_on_non_fasting_days,
    COUNT(*) FILTER (WHERE fwc.fasting_completed_goal) AS fasting_goals_achieved
  FROM fasting_weight_correlation fwc
  GROUP BY fwc.user_id, DATE_TRUNC('week', fwc.date)
),
monthly_data AS (
  SELECT
    fwc.user_id,
    DATE_TRUNC('month', fwc.date)::DATE AS month_start,
    COUNT(*) FILTER (WHERE fwc.is_fasting_day) AS fasting_days_count,
    COUNT(*) FILTER (WHERE NOT fwc.is_fasting_day) AS non_fasting_days_count,
    AVG(fwc.weight_kg) FILTER (WHERE fwc.is_fasting_day) AS avg_weight_fasting,
    AVG(fwc.weight_kg) FILTER (WHERE NOT fwc.is_fasting_day) AS avg_weight_non_fasting,
    MIN(fwc.weight_kg) AS min_weight,
    MAX(fwc.weight_kg) AS max_weight,
    COUNT(*) FILTER (WHERE fwc.fasting_completed_goal) AS fasting_goals_achieved
  FROM fasting_weight_correlation fwc
  GROUP BY fwc.user_id, DATE_TRUNC('month', fwc.date)
)
SELECT
  w.user_id,
  'weekly' AS period_type,
  w.week_start AS period_start,
  w.fasting_days_count,
  w.non_fasting_days_count,
  ROUND(w.avg_weight_fasting::NUMERIC, 2) AS avg_weight_fasting,
  ROUND(w.avg_weight_non_fasting::NUMERIC, 2) AS avg_weight_non_fasting,
  ROUND((w.avg_weight_fasting - w.avg_weight_non_fasting)::NUMERIC, 2) AS weight_difference,
  w.workouts_on_fasting_days,
  w.workouts_on_non_fasting_days,
  w.fasting_goals_achieved,
  CASE
    WHEN w.fasting_days_count > 0 THEN ROUND((w.fasting_goals_achieved::NUMERIC / w.fasting_days_count * 100), 1)
    ELSE 0
  END AS goal_achievement_rate
FROM weekly_data w
UNION ALL
SELECT
  m.user_id,
  'monthly' AS period_type,
  m.month_start AS period_start,
  m.fasting_days_count,
  m.non_fasting_days_count,
  ROUND(m.avg_weight_fasting::NUMERIC, 2) AS avg_weight_fasting,
  ROUND(m.avg_weight_non_fasting::NUMERIC, 2) AS avg_weight_non_fasting,
  ROUND((m.avg_weight_fasting - m.avg_weight_non_fasting)::NUMERIC, 2) AS weight_difference,
  NULL AS workouts_on_fasting_days,
  NULL AS workouts_on_non_fasting_days,
  m.fasting_goals_achieved,
  CASE
    WHEN m.fasting_days_count > 0 THEN ROUND((m.fasting_goals_achieved::NUMERIC / m.fasting_days_count * 100), 1)
    ELSE 0
  END AS goal_achievement_rate
FROM monthly_data m
ORDER BY user_id, period_type, period_start DESC;

-- Grant access to the view
GRANT SELECT ON fasting_performance_summary TO authenticated;

-- ============================================================================
-- PART 5: HELPER FUNCTION FOR IMPACT CALCULATION
-- ============================================================================

-- Function to calculate correlation between fasting and weight change
CREATE OR REPLACE FUNCTION calculate_fasting_weight_correlation(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS DECIMAL(3,2) AS $$
DECLARE
  v_correlation DECIMAL(3,2);
  v_n INTEGER;
  v_sum_x DECIMAL;
  v_sum_y DECIMAL;
  v_sum_xy DECIMAL;
  v_sum_x2 DECIMAL;
  v_sum_y2 DECIMAL;
BEGIN
  -- Get count of records
  SELECT COUNT(*) INTO v_n
  FROM fasting_weight_correlation
  WHERE user_id = p_user_id
    AND date BETWEEN p_start_date AND p_end_date;

  -- Need at least 7 data points for meaningful correlation
  IF v_n < 7 THEN
    RETURN NULL;
  END IF;

  -- Calculate Pearson correlation coefficient
  -- x = is_fasting_day (0 or 1), y = weight change from 7-day avg
  SELECT
    SUM(CASE WHEN is_fasting_day THEN 1 ELSE 0 END),
    SUM(weight_kg - weight_7day_avg),
    SUM(CASE WHEN is_fasting_day THEN 1 ELSE 0 END * (weight_kg - weight_7day_avg)),
    SUM(CASE WHEN is_fasting_day THEN 1 ELSE 0 END),
    SUM(POWER(weight_kg - weight_7day_avg, 2))
  INTO v_sum_x, v_sum_y, v_sum_xy, v_sum_x2, v_sum_y2
  FROM (
    SELECT
      is_fasting_day,
      weight_kg,
      AVG(weight_kg) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ) AS weight_7day_avg
    FROM fasting_weight_correlation
    WHERE user_id = p_user_id
      AND date BETWEEN p_start_date AND p_end_date
  ) subq;

  -- Avoid division by zero
  IF v_sum_x2 = 0 OR v_sum_y2 = 0 THEN
    RETURN 0;
  END IF;

  -- Pearson correlation formula
  v_correlation := (v_n * v_sum_xy - v_sum_x * v_sum_y) /
                   SQRT((v_n * v_sum_x2 - POWER(v_sum_x, 2)) * (v_n * v_sum_y2 - POWER(v_sum_y, 2)));

  -- Clamp to -1 to 1 range
  v_correlation := GREATEST(-1, LEAST(1, v_correlation));

  RETURN v_correlation;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Comment on function
COMMENT ON FUNCTION calculate_fasting_weight_correlation IS 'Calculates Pearson correlation between fasting days and weight deviation from 7-day average';

-- ============================================================================
-- PART 6: TRIGGER FOR AUTOMATIC WEIGHT CORRELATION UPDATES
-- ============================================================================

-- Function to update fasting_weight_correlation when weight is logged
CREATE OR REPLACE FUNCTION update_fasting_weight_correlation()
RETURNS TRIGGER AS $$
DECLARE
  v_fasting_record fasting_records%ROWTYPE;
  v_is_fasting_day BOOLEAN;
  v_days_since_last_fast INTEGER;
  v_workout_completed BOOLEAN;
  v_workout_type TEXT;
BEGIN
  -- Check if user fasted on this day
  SELECT * INTO v_fasting_record
  FROM fasting_records
  WHERE user_id = NEW.user_id
    AND DATE(start_time) = DATE(NEW.logged_at)
    AND status = 'completed'
  ORDER BY start_time DESC
  LIMIT 1;

  v_is_fasting_day := v_fasting_record.id IS NOT NULL;

  -- Calculate days since last fast
  SELECT COALESCE(DATE(NEW.logged_at) - MAX(DATE(start_time)), 999) INTO v_days_since_last_fast
  FROM fasting_records
  WHERE user_id = NEW.user_id
    AND status = 'completed'
    AND DATE(start_time) < DATE(NEW.logged_at);

  -- Check if workout was completed on this day
  -- Note: Column is is_completed, not completed
  SELECT
    COUNT(*) > 0,
    MAX(workout_type)
  INTO v_workout_completed, v_workout_type
  FROM workouts
  WHERE user_id = NEW.user_id
    AND DATE(created_at) = DATE(NEW.logged_at)
    AND is_completed = true;

  -- Upsert into fasting_weight_correlation
  INSERT INTO fasting_weight_correlation (
    user_id,
    date,
    weight_kg,
    weight_logged_at,
    is_fasting_day,
    fasting_record_id,
    fasting_protocol,
    fasting_duration_minutes,
    fasting_completed_goal,
    days_since_last_fast,
    workout_completed_that_day,
    workout_type
  )
  VALUES (
    NEW.user_id,
    DATE(NEW.logged_at),
    NEW.weight_kg,
    NEW.logged_at,
    v_is_fasting_day,
    v_fasting_record.id,
    v_fasting_record.protocol,
    COALESCE(v_fasting_record.actual_duration_minutes, 0),
    COALESCE(v_fasting_record.completed_goal, false),
    COALESCE(v_days_since_last_fast, 999),
    COALESCE(v_workout_completed, false),
    v_workout_type
  )
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    weight_kg = EXCLUDED.weight_kg,
    weight_logged_at = EXCLUDED.weight_logged_at,
    is_fasting_day = EXCLUDED.is_fasting_day,
    fasting_record_id = EXCLUDED.fasting_record_id,
    fasting_protocol = EXCLUDED.fasting_protocol,
    fasting_duration_minutes = EXCLUDED.fasting_duration_minutes,
    fasting_completed_goal = EXCLUDED.fasting_completed_goal,
    days_since_last_fast = EXCLUDED.days_since_last_fast,
    workout_completed_that_day = EXCLUDED.workout_completed_that_day,
    workout_type = EXCLUDED.workout_type;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on weight_logs table
DROP TRIGGER IF EXISTS trigger_update_fasting_weight_correlation ON weight_logs;
CREATE TRIGGER trigger_update_fasting_weight_correlation
  AFTER INSERT ON weight_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_fasting_weight_correlation();

-- Comment on trigger
COMMENT ON FUNCTION update_fasting_weight_correlation IS 'Automatically updates fasting_weight_correlation table when new weight is logged';

-- ============================================================================
-- PART 7: ADDITIONAL INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for fasting records lookup by user and status
-- Note: Cannot use DATE() function in index as it's not immutable
-- Using start_time directly for ordering
CREATE INDEX IF NOT EXISTS idx_fasting_records_user_status_completed
  ON fasting_records(user_id, status, start_time DESC)
  WHERE status = 'completed';

-- Index for workouts lookup by user and completion status
-- Note: Cannot use DATE() function in index as it's not immutable
-- Using created_at directly for ordering
-- Note: The column is is_completed, not completed
CREATE INDEX IF NOT EXISTS idx_workouts_user_completed_date
  ON workouts(user_id, created_at DESC)
  WHERE is_completed = true;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
