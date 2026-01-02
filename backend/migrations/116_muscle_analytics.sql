-- ============================================================================
-- Migration 116: Muscle Analytics
-- ============================================================================
-- This migration adds comprehensive muscle-level analytics:
-- 1. muscle_training_frequency view - How often each muscle is trained
-- 2. muscle_balance_analysis view - Push/pull and muscle balance
-- 3. muscle_heatmap_data function - Returns data for body diagram visualization
-- 4. muscle_analytics_logs table - Track analytics views
-- ============================================================================

-- ============================================================================
-- PART 1: MUSCLE TRAINING FREQUENCY VIEW
-- ============================================================================

-- Drop existing view first to allow column changes
DROP VIEW IF EXISTS muscle_training_frequency;
CREATE VIEW muscle_training_frequency AS
SELECT
    user_id,
    muscle_group,
    -- Note: muscle_group_weekly_volume uses week_start, not workout_date
    COUNT(DISTINCT week_start) FILTER (WHERE week_start >= CURRENT_DATE - 7) AS workout_count_last_7_days,
    COUNT(DISTINCT week_start) FILTER (WHERE week_start >= CURRENT_DATE - 30) AS workout_count_last_30_days,
    COALESCE(SUM(total_volume_kg) FILTER (WHERE week_start >= CURRENT_DATE - 7), 0)::numeric(10,2) AS total_volume_last_7_days,
    COALESCE(SUM(total_volume_kg) FILTER (WHERE week_start >= CURRENT_DATE - 30), 0)::numeric(10,2) AS total_volume_last_30_days,
    MAX(week_start) AS last_trained_date,
    CURRENT_DATE - MAX(week_start) AS days_since_trained
FROM muscle_group_weekly_volume
GROUP BY user_id, muscle_group
ORDER BY user_id, muscle_group;

GRANT SELECT ON muscle_training_frequency TO authenticated, anon, service_role;

COMMENT ON VIEW muscle_training_frequency IS 'Training frequency and volume per muscle group';

-- ============================================================================
-- PART 2: MUSCLE BALANCE ANALYSIS VIEW
-- ============================================================================

-- Drop existing view first to allow column changes
DROP VIEW IF EXISTS muscle_balance_analysis;
CREATE VIEW muscle_balance_analysis AS
WITH muscle_volumes AS (
    SELECT
        user_id,
        muscle_group,
        COALESCE(SUM(total_volume_kg), 0)::numeric(10,2) AS total_volume
    FROM muscle_group_weekly_volume
    WHERE week_start >= CURRENT_DATE - 30
    GROUP BY user_id, muscle_group
),
categorized AS (
    SELECT
        user_id,
        -- Push muscles: chest, shoulders, triceps
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group IN ('chest', 'shoulders', 'triceps')), 0) AS push_volume,
        -- Pull muscles: back, biceps
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group IN ('back', 'biceps', 'lats')), 0) AS pull_volume,
        -- Upper body
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group IN ('chest', 'shoulders', 'triceps', 'back', 'biceps', 'lats')), 0) AS upper_volume,
        -- Lower body
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group IN ('quadriceps', 'quads', 'hamstrings', 'glutes', 'calves', 'legs')), 0) AS lower_volume,
        -- Specific comparisons
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group = 'chest'), 0) AS chest_volume,
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group IN ('back', 'lats')), 0) AS back_volume,
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group IN ('quadriceps', 'quads')), 0) AS quad_volume,
        COALESCE(SUM(total_volume) FILTER (WHERE muscle_group = 'hamstrings'), 0) AS hamstring_volume
    FROM muscle_volumes
    GROUP BY user_id
)
SELECT
    user_id,
    push_volume,
    pull_volume,
    CASE WHEN pull_volume > 0 THEN ROUND((push_volume / pull_volume)::numeric, 2) ELSE 0 END AS push_pull_ratio,
    upper_volume,
    lower_volume,
    CASE WHEN lower_volume > 0 THEN ROUND((upper_volume / lower_volume)::numeric, 2) ELSE 0 END AS upper_lower_ratio,
    chest_volume,
    back_volume,
    CASE WHEN back_volume > 0 THEN ROUND((chest_volume / back_volume)::numeric, 2) ELSE 0 END AS chest_back_ratio,
    quad_volume,
    hamstring_volume,
    CASE WHEN hamstring_volume > 0 THEN ROUND((quad_volume / hamstring_volume)::numeric, 2) ELSE 0 END AS quad_hamstring_ratio
FROM categorized;

GRANT SELECT ON muscle_balance_analysis TO authenticated, anon, service_role;

COMMENT ON VIEW muscle_balance_analysis IS 'Analyzes muscle balance including push/pull and upper/lower ratios';

-- ============================================================================
-- PART 3: MUSCLE HEATMAP DATA FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION get_muscle_heatmap_data(
    p_user_id UUID,
    p_days_back INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
    v_max_volume DECIMAL;
    v_muscles JSONB;
BEGIN
    -- Get max volume for normalization
    SELECT MAX(total_volume)
    INTO v_max_volume
    FROM (
        SELECT muscle_group, SUM(total_volume_kg) AS total_volume
        FROM muscle_group_weekly_volume
        WHERE user_id = p_user_id
          AND week_start >= CURRENT_DATE - p_days_back
        GROUP BY muscle_group
    ) sub;

    -- Get muscle data with intensity scores
    SELECT jsonb_agg(
        jsonb_build_object(
            'muscle_group', muscle_group,
            'total_volume_kg', ROUND(total_volume::numeric, 2),
            'intensity_score', CASE WHEN v_max_volume > 0
                THEN ROUND((total_volume / v_max_volume * 100)::numeric, 0)
                ELSE 0 END,
            'workout_count', workout_count,
            'color', CASE
                WHEN v_max_volume > 0 AND (total_volume / v_max_volume) > 0.75 THEN 'high'
                WHEN v_max_volume > 0 AND (total_volume / v_max_volume) > 0.5 THEN 'medium-high'
                WHEN v_max_volume > 0 AND (total_volume / v_max_volume) > 0.25 THEN 'medium'
                WHEN v_max_volume > 0 AND (total_volume / v_max_volume) > 0 THEN 'low'
                ELSE 'none'
            END
        )
    )
    INTO v_muscles
    FROM (
        SELECT
            muscle_group,
            SUM(total_volume_kg) AS total_volume,
            COUNT(DISTINCT week_start) AS workout_count
        FROM muscle_group_weekly_volume
        WHERE user_id = p_user_id
          AND week_start >= CURRENT_DATE - p_days_back
        GROUP BY muscle_group
        ORDER BY total_volume DESC
    ) sub;

    v_result := jsonb_build_object(
        'user_id', p_user_id,
        'period_days', p_days_back,
        'max_volume_kg', ROUND(v_max_volume::numeric, 2),
        'muscles', COALESCE(v_muscles, '[]'::JSONB),
        'generated_at', NOW()
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_muscle_heatmap_data TO authenticated, service_role;

COMMENT ON FUNCTION get_muscle_heatmap_data IS 'Returns muscle intensity data for body diagram/heatmap visualization';

-- ============================================================================
-- PART 4: MUSCLE ANALYTICS LOGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS muscle_analytics_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    view_type TEXT NOT NULL, -- 'heatmap', 'frequency', 'balance', 'exercise_history'
    muscle_group_filter TEXT, -- Optional filter
    exercise_name_filter TEXT, -- Optional filter
    time_range_days INTEGER DEFAULT 30,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_duration_seconds INTEGER
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_mal_user ON muscle_analytics_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_mal_date ON muscle_analytics_logs(viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_mal_type ON muscle_analytics_logs(view_type);

-- Enable RLS
ALTER TABLE muscle_analytics_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY muscle_analytics_logs_insert ON muscle_analytics_logs
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY muscle_analytics_logs_select ON muscle_analytics_logs
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY muscle_analytics_logs_service ON muscle_analytics_logs
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT ON muscle_analytics_logs TO authenticated;
GRANT ALL ON muscle_analytics_logs TO service_role;

COMMENT ON TABLE muscle_analytics_logs IS 'Tracks user engagement with muscle analytics features';

-- ============================================================================
-- PART 5: HELPER FUNCTION - GET EXERCISES FOR MUSCLE
-- ============================================================================

CREATE OR REPLACE FUNCTION get_exercises_for_muscle(
    p_user_id UUID,
    p_muscle_group TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'exercise_name', exercise_name,
            'times_performed', times_performed,
            'total_volume_kg', ROUND(total_volume::numeric, 2),
            'max_weight_kg', max_weight,
            'last_performed', last_performed
        )
    )
    INTO v_result
    FROM (
        SELECT
            exercise_name,
            COUNT(DISTINCT workout_date) AS times_performed,
            SUM(total_volume_kg) AS total_volume,
            MAX(max_weight_kg) AS max_weight,
            MAX(workout_date) AS last_performed
        FROM exercise_workout_history
        WHERE user_id = p_user_id
          AND LOWER(muscle_group) = LOWER(p_muscle_group)
        GROUP BY exercise_name
        ORDER BY times_performed DESC
        LIMIT p_limit
    ) sub;

    RETURN jsonb_build_object(
        'muscle_group', p_muscle_group,
        'exercises', COALESCE(v_result, '[]'::JSONB),
        'total_exercises', jsonb_array_length(COALESCE(v_result, '[]'::JSONB))
    );
END;
$$;

GRANT EXECUTE ON FUNCTION get_exercises_for_muscle TO authenticated, service_role;

COMMENT ON FUNCTION get_exercises_for_muscle IS 'Returns exercises performed for a specific muscle group';
