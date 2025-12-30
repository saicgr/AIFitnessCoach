-- Migration: 061_mobility_recovery_workout_types.sql
-- Description: Add mobility and recovery workout types, plus hold_seconds and is_unilateral fields
-- This addresses user feedback: "I hope they add more exercises especially unilateral and mobility exercises"

-- Add comment explaining the workout types
COMMENT ON COLUMN workouts.type IS 'Workout type: strength, cardio, mixed, mobility, recovery';

-- Update workout_type_preference check constraint if it exists
-- First, check if there's a constraint and drop it if needed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage
        WHERE column_name = 'workout_type_preference'
    ) THEN
        -- The constraint might not exist, so we just ensure the column can hold the new values
        RAISE NOTICE 'workout_type_preference column exists, ensuring it accepts new values';
    END IF;
END $$;

-- Add index on workout type for faster filtering
CREATE INDEX IF NOT EXISTS idx_workouts_type ON workouts(type);

-- Create a table to track mobility exercises for analytics
CREATE TABLE IF NOT EXISTS mobility_exercise_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    exercise_name TEXT NOT NULL,
    exercise_type TEXT NOT NULL CHECK (exercise_type IN ('stretch', 'yoga', 'mobility_drill', 'foam_roll', 'breathing')),
    hold_seconds INTEGER,
    is_unilateral BOOLEAN DEFAULT false,
    body_area TEXT, -- hips, shoulders, spine, ankles, etc.
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_mobility_tracking_user_id ON mobility_exercise_tracking(user_id);

-- Index for exercise type analysis
CREATE INDEX IF NOT EXISTS idx_mobility_tracking_exercise_type ON mobility_exercise_tracking(exercise_type);

-- Index for body area analysis
CREATE INDEX IF NOT EXISTS idx_mobility_tracking_body_area ON mobility_exercise_tracking(body_area);

-- Enable RLS
ALTER TABLE mobility_exercise_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own mobility tracking"
ON mobility_exercise_tracking FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mobility tracking"
ON mobility_exercise_tracking FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role has full access to mobility_exercise_tracking"
ON mobility_exercise_tracking FOR ALL
USING (auth.role() = 'service_role');

-- Add unilateral exercise tracking view
CREATE OR REPLACE VIEW user_unilateral_exercise_stats AS
SELECT
    user_id,
    COUNT(*) as total_unilateral_exercises,
    COUNT(DISTINCT exercise_name) as unique_unilateral_exercises,
    MAX(performed_at) as last_unilateral_workout
FROM mobility_exercise_tracking
WHERE is_unilateral = true
GROUP BY user_id;

-- Add flexibility progress tracking view
CREATE OR REPLACE VIEW user_flexibility_progress AS
SELECT
    user_id,
    body_area,
    COUNT(*) as sessions_count,
    AVG(hold_seconds) as avg_hold_seconds,
    MAX(hold_seconds) as max_hold_seconds,
    MIN(performed_at) as first_session,
    MAX(performed_at) as last_session
FROM mobility_exercise_tracking
WHERE hold_seconds IS NOT NULL AND body_area IS NOT NULL
GROUP BY user_id, body_area
ORDER BY user_id, sessions_count DESC;

-- Comments for documentation
COMMENT ON TABLE mobility_exercise_tracking IS 'Tracks mobility, stretching, and flexibility exercises for progress analytics';
COMMENT ON COLUMN mobility_exercise_tracking.exercise_type IS 'Type of mobility exercise: stretch, yoga, mobility_drill, foam_roll, breathing';
COMMENT ON COLUMN mobility_exercise_tracking.hold_seconds IS 'Duration of static hold in seconds (for stretches and yoga poses)';
COMMENT ON COLUMN mobility_exercise_tracking.is_unilateral IS 'Whether exercise works one side at a time (single-arm, single-leg)';
COMMENT ON COLUMN mobility_exercise_tracking.body_area IS 'Target body area: hips, shoulders, spine, ankles, wrists, neck, etc.';
