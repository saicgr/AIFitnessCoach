-- ============================================================================
-- Migration 115: Exercise History Analytics
-- ============================================================================
-- This migration adds comprehensive per-exercise workout history tracking:
-- 1. exercise_workout_history view - Every session where an exercise was performed
-- 2. exercise_personal_records table - Dedicated table for exercise PRs
-- 3. exercise_progression_analysis function - Analyzes progression over time
-- ============================================================================

-- ============================================================================
-- PART 1: EXERCISE WORKOUT HISTORY VIEW
-- ============================================================================
-- Shows every session where an exercise was performed with all relevant metrics

CREATE OR REPLACE VIEW exercise_workout_history AS
SELECT
    wl.user_id,
    LOWER(COALESCE(exercise->>'name', exercise->>'exercise_name', 'unknown')) as exercise_name,
    LOWER(COALESCE(exercise->>'primary_muscle', exercise->>'muscle_group', 'other')) as muscle_group,
    wl.id AS workout_log_id,
    wl.workout_id,
    DATE(wl.completed_at) AS workout_date,
    wl.completed_at,

    -- Set and rep metrics
    (SELECT COUNT(*)
     FROM jsonb_array_elements(exercise->'sets') as set_data)::int AS sets_completed,

    (SELECT COALESCE(SUM((set_data->>'reps')::int), 0)
     FROM jsonb_array_elements(exercise->'sets') as set_data)::int AS total_reps,

    -- Volume metrics (weight * reps for each set)
    (SELECT COALESCE(SUM((set_data->>'weight_kg')::numeric * (set_data->>'reps')::numeric), 0)
     FROM jsonb_array_elements(exercise->'sets') as set_data)::numeric(10,2) AS total_volume_kg,

    -- Weight metrics
    (SELECT MAX((set_data->>'weight_kg')::numeric)
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE (set_data->>'weight_kg') IS NOT NULL)::numeric(10,2) AS max_weight_kg,

    -- Estimated 1RM using Epley formula: weight * (1 + reps/30)
    (SELECT MAX(
        (set_data->>'weight_kg')::numeric * (1 + (set_data->>'reps')::numeric / 30)
    )
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE (set_data->>'weight_kg') IS NOT NULL
       AND (set_data->>'reps') IS NOT NULL
       AND (set_data->>'reps')::int BETWEEN 1 AND 12)::numeric(10,2) AS estimated_1rm_kg,

    -- RPE metrics
    (SELECT AVG((set_data->>'rpe')::numeric)
     FROM jsonb_array_elements(exercise->'sets') as set_data
     WHERE (set_data->>'rpe') IS NOT NULL)::numeric(3,1) AS avg_rpe

FROM workout_logs wl,
     jsonb_array_elements(wl.exercises_performance) as exercise
WHERE wl.completed_at IS NOT NULL
  AND wl.exercises_performance IS NOT NULL
ORDER BY wl.user_id, exercise_name, wl.completed_at DESC;

-- Grant access to the view
GRANT SELECT ON exercise_workout_history TO authenticated, anon, service_role;

-- Comment on the view
COMMENT ON VIEW exercise_workout_history IS 'Aggregated exercise performance for each workout session';

-- ============================================================================
-- PART 2: EXERCISE PERSONAL RECORDS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_personal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Exercise identification
    exercise_name TEXT NOT NULL,
    muscle_group TEXT,

    -- Record type
    record_type TEXT NOT NULL CHECK (record_type IN (
        'max_weight',
        'max_reps',
        'max_volume',
        'best_1rm'
    )),

    -- Record value
    record_value DECIMAL(10,2) NOT NULL,
    record_unit TEXT NOT NULL DEFAULT 'kg',

    -- Previous record for comparison
    previous_value DECIMAL(10,2),
    improvement_percent DECIMAL(6,2),

    -- When achieved
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,

    -- Is current record
    is_current_record BOOLEAN DEFAULT TRUE,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_epr_user ON exercise_personal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_epr_user_exercise ON exercise_personal_records(user_id, exercise_name);
CREATE INDEX IF NOT EXISTS idx_epr_user_exercise_type ON exercise_personal_records(user_id, exercise_name, record_type);
CREATE INDEX IF NOT EXISTS idx_epr_current ON exercise_personal_records(user_id, exercise_name, record_type) WHERE is_current_record = TRUE;

-- Enable RLS
ALTER TABLE exercise_personal_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY exercise_personal_records_select ON exercise_personal_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY exercise_personal_records_insert ON exercise_personal_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY exercise_personal_records_update ON exercise_personal_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY exercise_personal_records_delete ON exercise_personal_records
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY exercise_personal_records_service ON exercise_personal_records
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON exercise_personal_records TO authenticated;
GRANT ALL ON exercise_personal_records TO service_role;

COMMENT ON TABLE exercise_personal_records IS 'Tracks personal records for each exercise';

-- ============================================================================
-- PART 3: EXERCISE PROGRESSION ANALYSIS FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION analyze_exercise_progression(
    p_user_id UUID,
    p_exercise_name TEXT,
    p_days_back INTEGER DEFAULT 90
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
    v_first_perf RECORD;
    v_last_perf RECORD;
    v_total_sessions INTEGER;
    v_improvement_1rm DECIMAL;
BEGIN
    -- Get first performance
    SELECT workout_date, max_weight_kg, estimated_1rm_kg, total_volume_kg
    INTO v_first_perf
    FROM exercise_workout_history
    WHERE user_id = p_user_id
      AND LOWER(exercise_name) = LOWER(p_exercise_name)
      AND workout_date >= CURRENT_DATE - p_days_back
    ORDER BY workout_date ASC
    LIMIT 1;

    -- Get last performance
    SELECT workout_date, max_weight_kg, estimated_1rm_kg, total_volume_kg
    INTO v_last_perf
    FROM exercise_workout_history
    WHERE user_id = p_user_id
      AND LOWER(exercise_name) = LOWER(p_exercise_name)
      AND workout_date >= CURRENT_DATE - p_days_back
    ORDER BY workout_date DESC
    LIMIT 1;

    -- Count sessions
    SELECT COUNT(DISTINCT workout_date)
    INTO v_total_sessions
    FROM exercise_workout_history
    WHERE user_id = p_user_id
      AND LOWER(exercise_name) = LOWER(p_exercise_name)
      AND workout_date >= CURRENT_DATE - p_days_back;

    -- Calculate improvement
    IF v_first_perf.estimated_1rm_kg > 0 AND v_last_perf.estimated_1rm_kg IS NOT NULL THEN
        v_improvement_1rm := ROUND(((v_last_perf.estimated_1rm_kg - v_first_perf.estimated_1rm_kg) / v_first_perf.estimated_1rm_kg * 100)::NUMERIC, 1);
    END IF;

    v_result := jsonb_build_object(
        'exercise_name', p_exercise_name,
        'period_days', p_days_back,
        'total_sessions', v_total_sessions,
        'first_performance', CASE WHEN v_first_perf.workout_date IS NOT NULL THEN
            jsonb_build_object(
                'date', v_first_perf.workout_date,
                'max_weight_kg', v_first_perf.max_weight_kg,
                'estimated_1rm_kg', v_first_perf.estimated_1rm_kg
            )
        ELSE NULL END,
        'last_performance', CASE WHEN v_last_perf.workout_date IS NOT NULL THEN
            jsonb_build_object(
                'date', v_last_perf.workout_date,
                'max_weight_kg', v_last_perf.max_weight_kg,
                'estimated_1rm_kg', v_last_perf.estimated_1rm_kg
            )
        ELSE NULL END,
        'improvement_1rm_percent', v_improvement_1rm
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION analyze_exercise_progression TO authenticated, service_role;

COMMENT ON FUNCTION analyze_exercise_progression IS 'Analyzes progression for a specific exercise over time';
