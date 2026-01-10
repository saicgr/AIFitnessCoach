-- Migration: Optimize performance_logs for efficient exercise history queries
-- This migration adds composite indexes and updates the table for better query performance
-- when fetching exercise history for AI weight suggestions.

-- Add composite index for efficient exercise history lookups
-- This allows fast queries like: "Get last 5 sessions of Bench Press for user X"
CREATE INDEX IF NOT EXISTS idx_performance_logs_user_exercise_date
ON performance_logs(user_id, exercise_name, recorded_at DESC);

-- Add index for exercise_id lookups (some queries use ID instead of name)
CREATE INDEX IF NOT EXISTS idx_performance_logs_user_exercise_id_date
ON performance_logs(user_id, exercise_id, recorded_at DESC);

-- Add index for workout_log_id lookups (to find all sets in a workout)
CREATE INDEX IF NOT EXISTS idx_performance_logs_workout_log_id
ON performance_logs(workout_log_id);

-- Create a function to get exercise history efficiently
-- This replaces the inefficient JSON parsing approach
CREATE OR REPLACE FUNCTION get_exercise_history(
    p_user_id UUID,
    p_exercise_name TEXT,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    workout_date TIMESTAMPTZ,
    weight_kg DOUBLE PRECISION,
    reps INTEGER,
    sets_count INTEGER,
    rpe DOUBLE PRECISION,
    rir INTEGER,
    workout_log_id UUID
) AS $$
BEGIN
    RETURN QUERY
    WITH ranked_sets AS (
        SELECT
            pl.workout_log_id,
            pl.recorded_at,
            pl.weight_kg,
            pl.reps_completed,
            pl.rpe,
            pl.rir,
            ROW_NUMBER() OVER (
                PARTITION BY pl.workout_log_id
                ORDER BY pl.weight_kg DESC, pl.reps_completed DESC
            ) as rn,
            COUNT(*) OVER (PARTITION BY pl.workout_log_id) as total_sets
        FROM performance_logs pl
        WHERE pl.user_id = p_user_id
          AND LOWER(pl.exercise_name) = LOWER(p_exercise_name)
          AND pl.is_completed = true
    ),
    best_sets AS (
        SELECT DISTINCT ON (workout_log_id)
            workout_log_id,
            recorded_at,
            weight_kg,
            reps_completed,
            rpe,
            rir,
            total_sets
        FROM ranked_sets
        WHERE rn = 1
        ORDER BY workout_log_id, recorded_at DESC
    )
    SELECT
        bs.recorded_at as workout_date,
        bs.weight_kg,
        bs.reps_completed as reps,
        bs.total_sets::INTEGER as sets_count,
        bs.rpe,
        bs.rir,
        bs.workout_log_id
    FROM best_sets bs
    ORDER BY bs.recorded_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_exercise_history(UUID, TEXT, INTEGER) TO authenticated;

-- Add comment explaining the function
COMMENT ON FUNCTION get_exercise_history IS
'Efficiently retrieves exercise history for a user. Returns the best set from each workout session where this exercise was performed, ordered by most recent first. Used by AI weight suggestion system.';
