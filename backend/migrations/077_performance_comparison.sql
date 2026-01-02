-- Migration: 077_performance_comparison.sql
-- Purpose: Add performance comparison functionality to show improvements/setbacks vs previous sessions
-- Addresses user review: "It used to show the reductions or increases in time, both for each exercise and the workout"

-- ============================================================================
-- 1. Exercise Performance Summary Table
-- Stores aggregated performance per exercise per workout for fast comparison
-- ============================================================================
CREATE TABLE IF NOT EXISTS exercise_performance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    exercise_name TEXT NOT NULL,
    exercise_id TEXT,

    -- Performance metrics
    total_sets INTEGER NOT NULL DEFAULT 0,
    total_reps INTEGER NOT NULL DEFAULT 0,
    total_volume_kg DECIMAL(10,2) NOT NULL DEFAULT 0,
    max_weight_kg DECIMAL(8,2),
    avg_weight_kg DECIMAL(8,2),
    best_set_reps INTEGER,
    best_set_weight_kg DECIMAL(8,2),
    estimated_1rm_kg DECIMAL(8,2),

    -- Time-based metrics (for timed exercises like planks, cardio)
    total_time_seconds INTEGER,
    best_time_seconds INTEGER,
    avg_time_seconds INTEGER,

    -- Average RPE/RIR across all sets
    avg_rpe DECIMAL(3,1),
    avg_rir DECIMAL(3,1),

    -- Timestamps
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraint to ensure one summary per exercise per workout log
    UNIQUE(workout_log_id, exercise_name)
);

-- Indexes for fast querying
CREATE INDEX IF NOT EXISTS idx_eps_user_exercise ON exercise_performance_summary(user_id, exercise_name);
CREATE INDEX IF NOT EXISTS idx_eps_user_date ON exercise_performance_summary(user_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_eps_workout_log ON exercise_performance_summary(workout_log_id);

-- Enable RLS
ALTER TABLE exercise_performance_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own exercise performance" ON exercise_performance_summary;
CREATE POLICY "Users can view own exercise performance" ON exercise_performance_summary
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own exercise performance" ON exercise_performance_summary;
CREATE POLICY "Users can insert own exercise performance" ON exercise_performance_summary
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage all exercise performance" ON exercise_performance_summary;
CREATE POLICY "Service role can manage all exercise performance" ON exercise_performance_summary
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- 2. Workout Performance Summary Table
-- Stores aggregated workout-level performance for workout-to-workout comparison
-- ============================================================================
CREATE TABLE IF NOT EXISTS workout_performance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    workout_name TEXT,
    workout_type TEXT,

    -- Overall performance metrics
    total_exercises INTEGER NOT NULL DEFAULT 0,
    total_sets INTEGER NOT NULL DEFAULT 0,
    total_reps INTEGER NOT NULL DEFAULT 0,
    total_volume_kg DECIMAL(12,2) NOT NULL DEFAULT 0,

    -- Time metrics
    duration_seconds INTEGER NOT NULL,
    active_time_seconds INTEGER, -- time actually exercising (excluding rest)
    total_rest_seconds INTEGER,
    avg_rest_seconds DECIMAL(6,2),

    -- Intensity metrics
    avg_rpe DECIMAL(3,1),
    avg_rir DECIMAL(3,1),

    -- Calories
    estimated_calories INTEGER,

    -- PR count in this workout
    new_prs_count INTEGER DEFAULT 0,

    -- Timestamps
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(workout_log_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wps_user_date ON workout_performance_summary(user_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_wps_user_type ON workout_performance_summary(user_id, workout_type);
CREATE INDEX IF NOT EXISTS idx_wps_workout_log ON workout_performance_summary(workout_log_id);

-- Enable RLS
ALTER TABLE workout_performance_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own workout performance" ON workout_performance_summary;
CREATE POLICY "Users can view own workout performance" ON workout_performance_summary
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own workout performance" ON workout_performance_summary;
CREATE POLICY "Users can insert own workout performance" ON workout_performance_summary
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can manage all workout performance" ON workout_performance_summary;
CREATE POLICY "Service role can manage all workout performance" ON workout_performance_summary
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- 3. Function to get previous exercise performance for comparison
-- ============================================================================
CREATE OR REPLACE FUNCTION get_previous_exercise_performance(
    p_user_id UUID,
    p_exercise_name TEXT,
    p_current_workout_log_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    workout_log_id UUID,
    performed_at TIMESTAMPTZ,
    total_sets INTEGER,
    total_reps INTEGER,
    total_volume_kg DECIMAL,
    max_weight_kg DECIMAL,
    estimated_1rm_kg DECIMAL,
    total_time_seconds INTEGER,
    avg_rpe DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        eps.workout_log_id,
        eps.performed_at,
        eps.total_sets,
        eps.total_reps,
        eps.total_volume_kg,
        eps.max_weight_kg,
        eps.estimated_1rm_kg,
        eps.total_time_seconds,
        eps.avg_rpe
    FROM exercise_performance_summary eps
    WHERE eps.user_id = p_user_id
      AND LOWER(eps.exercise_name) = LOWER(p_exercise_name)
      AND (p_current_workout_log_id IS NULL OR eps.workout_log_id != p_current_workout_log_id)
    ORDER BY eps.performed_at DESC
    LIMIT p_limit;
END;
$$;

-- ============================================================================
-- 4. Function to get workout comparison data
-- Returns current workout stats alongside previous similar workout stats
-- ============================================================================
CREATE OR REPLACE FUNCTION get_workout_comparison(
    p_user_id UUID,
    p_current_workout_log_id UUID
)
RETURNS TABLE (
    -- Current workout
    current_duration_seconds INTEGER,
    current_total_volume_kg DECIMAL,
    current_total_sets INTEGER,
    current_total_reps INTEGER,
    current_exercises INTEGER,
    current_calories INTEGER,
    current_new_prs INTEGER,
    current_performed_at TIMESTAMPTZ,

    -- Previous workout (same type)
    previous_workout_log_id UUID,
    previous_duration_seconds INTEGER,
    previous_total_volume_kg DECIMAL,
    previous_total_sets INTEGER,
    previous_total_reps INTEGER,
    previous_exercises INTEGER,
    previous_calories INTEGER,
    previous_performed_at TIMESTAMPTZ,

    -- Differences
    duration_diff_seconds INTEGER,
    volume_diff_kg DECIMAL,
    sets_diff INTEGER,
    reps_diff INTEGER,
    duration_diff_percent DECIMAL,
    volume_diff_percent DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current RECORD;
    v_previous RECORD;
BEGIN
    -- Get current workout stats
    SELECT * INTO v_current
    FROM workout_performance_summary
    WHERE workout_log_id = p_current_workout_log_id
      AND user_id = p_user_id;

    IF v_current IS NULL THEN
        RETURN;
    END IF;

    -- Get previous similar workout (same type, or any if type is null)
    SELECT * INTO v_previous
    FROM workout_performance_summary
    WHERE user_id = p_user_id
      AND workout_log_id != p_current_workout_log_id
      AND (v_current.workout_type IS NULL OR workout_type = v_current.workout_type)
      AND performed_at < v_current.performed_at
    ORDER BY performed_at DESC
    LIMIT 1;

    RETURN QUERY SELECT
        v_current.duration_seconds,
        v_current.total_volume_kg,
        v_current.total_sets,
        v_current.total_reps,
        v_current.total_exercises,
        v_current.estimated_calories,
        v_current.new_prs_count,
        v_current.performed_at,

        v_previous.workout_log_id,
        v_previous.duration_seconds,
        v_previous.total_volume_kg,
        v_previous.total_sets,
        v_previous.total_reps,
        v_previous.total_exercises,
        v_previous.estimated_calories,
        v_previous.performed_at,

        CASE WHEN v_previous IS NOT NULL THEN v_current.duration_seconds - v_previous.duration_seconds ELSE NULL END,
        CASE WHEN v_previous IS NOT NULL THEN v_current.total_volume_kg - v_previous.total_volume_kg ELSE NULL END,
        CASE WHEN v_previous IS NOT NULL THEN v_current.total_sets - v_previous.total_sets ELSE NULL END,
        CASE WHEN v_previous IS NOT NULL THEN v_current.total_reps - v_previous.total_reps ELSE NULL END,
        CASE WHEN v_previous IS NOT NULL AND v_previous.duration_seconds > 0
            THEN ROUND(((v_current.duration_seconds - v_previous.duration_seconds)::DECIMAL / v_previous.duration_seconds) * 100, 1)
            ELSE NULL END,
        CASE WHEN v_previous IS NOT NULL AND v_previous.total_volume_kg > 0
            THEN ROUND(((v_current.total_volume_kg - v_previous.total_volume_kg) / v_previous.total_volume_kg) * 100, 1)
            ELSE NULL END;
END;
$$;

-- ============================================================================
-- 5. Function to get exercise-level comparisons for a workout
-- ============================================================================
CREATE OR REPLACE FUNCTION get_exercise_comparisons(
    p_user_id UUID,
    p_current_workout_log_id UUID
)
RETURNS TABLE (
    exercise_name TEXT,

    -- Current session
    current_sets INTEGER,
    current_reps INTEGER,
    current_volume_kg DECIMAL,
    current_max_weight_kg DECIMAL,
    current_1rm_kg DECIMAL,
    current_time_seconds INTEGER,

    -- Previous session
    previous_sets INTEGER,
    previous_reps INTEGER,
    previous_volume_kg DECIMAL,
    previous_max_weight_kg DECIMAL,
    previous_1rm_kg DECIMAL,
    previous_time_seconds INTEGER,
    previous_date TIMESTAMPTZ,

    -- Differences
    volume_diff_kg DECIMAL,
    volume_diff_percent DECIMAL,
    weight_diff_kg DECIMAL,
    weight_diff_percent DECIMAL,
    rm_diff_kg DECIMAL,
    rm_diff_percent DECIMAL,
    time_diff_seconds INTEGER,
    time_diff_percent DECIMAL,

    -- Status: 'improved', 'maintained', 'declined', 'first_time'
    status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH current_exercises AS (
        SELECT *
        FROM exercise_performance_summary
        WHERE workout_log_id = p_current_workout_log_id
          AND user_id = p_user_id
    ),
    previous_exercises AS (
        SELECT DISTINCT ON (LOWER(exercise_name))
            *
        FROM exercise_performance_summary eps
        WHERE user_id = p_user_id
          AND workout_log_id != p_current_workout_log_id
          AND LOWER(exercise_name) IN (SELECT LOWER(exercise_name) FROM current_exercises)
        ORDER BY LOWER(exercise_name), performed_at DESC
    )
    SELECT
        ce.exercise_name,

        -- Current
        ce.total_sets,
        ce.total_reps,
        ce.total_volume_kg,
        ce.max_weight_kg,
        ce.estimated_1rm_kg,
        ce.total_time_seconds,

        -- Previous
        pe.total_sets,
        pe.total_reps,
        pe.total_volume_kg,
        pe.max_weight_kg,
        pe.estimated_1rm_kg,
        pe.total_time_seconds,
        pe.performed_at,

        -- Differences
        CASE WHEN pe.id IS NOT NULL THEN ce.total_volume_kg - pe.total_volume_kg ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL AND pe.total_volume_kg > 0
            THEN ROUND(((ce.total_volume_kg - pe.total_volume_kg) / pe.total_volume_kg) * 100, 1)
            ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL THEN ce.max_weight_kg - pe.max_weight_kg ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL AND pe.max_weight_kg > 0
            THEN ROUND(((ce.max_weight_kg - pe.max_weight_kg) / pe.max_weight_kg) * 100, 1)
            ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL THEN ce.estimated_1rm_kg - pe.estimated_1rm_kg ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL AND pe.estimated_1rm_kg > 0
            THEN ROUND(((ce.estimated_1rm_kg - pe.estimated_1rm_kg) / pe.estimated_1rm_kg) * 100, 1)
            ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL THEN ce.total_time_seconds - pe.total_time_seconds ELSE NULL END,
        CASE WHEN pe.id IS NOT NULL AND pe.total_time_seconds > 0
            THEN ROUND(((ce.total_time_seconds - pe.total_time_seconds)::DECIMAL / pe.total_time_seconds) * 100, 1)
            ELSE NULL END,

        -- Status determination
        CASE
            WHEN pe.id IS NULL THEN 'first_time'
            -- For weight-based exercises, check 1RM improvement
            WHEN ce.estimated_1rm_kg IS NOT NULL AND pe.estimated_1rm_kg IS NOT NULL THEN
                CASE
                    WHEN ce.estimated_1rm_kg > pe.estimated_1rm_kg * 1.01 THEN 'improved'
                    WHEN ce.estimated_1rm_kg < pe.estimated_1rm_kg * 0.99 THEN 'declined'
                    ELSE 'maintained'
                END
            -- For time-based exercises (lower time = better for some, higher for others like planks)
            WHEN ce.total_time_seconds IS NOT NULL AND pe.total_time_seconds IS NOT NULL THEN
                CASE
                    WHEN ce.total_time_seconds > pe.total_time_seconds * 1.05 THEN 'improved'
                    WHEN ce.total_time_seconds < pe.total_time_seconds * 0.95 THEN 'declined'
                    ELSE 'maintained'
                END
            -- Fallback to volume comparison
            WHEN ce.total_volume_kg > pe.total_volume_kg * 1.01 THEN 'improved'
            WHEN ce.total_volume_kg < pe.total_volume_kg * 0.99 THEN 'declined'
            ELSE 'maintained'
        END
    FROM current_exercises ce
    LEFT JOIN previous_exercises pe ON LOWER(ce.exercise_name) = LOWER(pe.exercise_name);
END;
$$;

-- ============================================================================
-- 6. User Context Logging for Performance Comparisons
-- ============================================================================
-- Note: The user_context_log_types table may not exist in all deployments.
-- These context types can be added manually if the table exists:
-- INSERT INTO user_context_log_types (type_name, description, category)
-- VALUES
--     ('performance_comparison_viewed', 'User viewed performance comparison on workout completion', 'workout'),
--     ('exercise_improvement_viewed', 'User viewed exercise improvement details', 'workout'),
--     ('exercise_decline_viewed', 'User viewed exercise decline/setback details', 'workout')
-- ON CONFLICT (type_name) DO NOTHING;

-- ============================================================================
-- 7. Grant permissions
-- ============================================================================
GRANT SELECT, INSERT ON exercise_performance_summary TO authenticated;
GRANT SELECT, INSERT ON workout_performance_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_previous_exercise_performance TO authenticated;
GRANT EXECUTE ON FUNCTION get_workout_comparison TO authenticated;
GRANT EXECUTE ON FUNCTION get_exercise_comparisons TO authenticated;

-- ============================================================================
-- 8. Comments
-- ============================================================================
COMMENT ON TABLE exercise_performance_summary IS 'Aggregated exercise performance per workout for comparison';
COMMENT ON TABLE workout_performance_summary IS 'Aggregated workout-level performance for comparison';
COMMENT ON FUNCTION get_exercise_comparisons IS 'Returns exercise-by-exercise comparison with previous session';
COMMENT ON FUNCTION get_workout_comparison IS 'Returns workout-level comparison with previous similar workout';
