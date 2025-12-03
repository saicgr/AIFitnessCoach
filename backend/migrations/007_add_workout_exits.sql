-- Migration: Add workout_exits table for tracking workout quit/exit events
-- Created: 2025-12-02

-- Create workout_exits table
CREATE TABLE IF NOT EXISTS workout_exits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exit_reason VARCHAR(50) NOT NULL,
    exit_notes TEXT,
    exercises_completed INTEGER DEFAULT 0,
    total_exercises INTEGER DEFAULT 0,
    sets_completed INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    progress_percentage FLOAT DEFAULT 0.0,
    exited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comment for table documentation
COMMENT ON TABLE workout_exits IS 'Tracks when users exit/quit workouts, including the reason and progress at time of exit';

-- Column comments
COMMENT ON COLUMN workout_exits.exit_reason IS 'Reason for exiting: completed, too_tired, out_of_time, not_feeling_well, equipment_unavailable, injury, other';
COMMENT ON COLUMN workout_exits.exit_notes IS 'Optional user-provided notes explaining the exit';
COMMENT ON COLUMN workout_exits.exercises_completed IS 'Number of exercises completed before exit';
COMMENT ON COLUMN workout_exits.total_exercises IS 'Total number of exercises in the workout';
COMMENT ON COLUMN workout_exits.sets_completed IS 'Total sets completed before exit';
COMMENT ON COLUMN workout_exits.time_spent_seconds IS 'Total time spent in workout in seconds';
COMMENT ON COLUMN workout_exits.progress_percentage IS 'Percentage of workout completed (0-100)';

-- Add indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_workout_exits_user_id ON workout_exits(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_exits_workout_id ON workout_exits(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_exits_exit_reason ON workout_exits(exit_reason);
CREATE INDEX IF NOT EXISTS idx_workout_exits_exited_at ON workout_exits(exited_at DESC);

-- Enable Row Level Security
ALTER TABLE workout_exits ENABLE ROW LEVEL SECURITY;

-- Policy for users to see their own exit records
DROP POLICY IF EXISTS workout_exits_select_policy ON workout_exits;
CREATE POLICY workout_exits_select_policy ON workout_exits
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for users to insert their own exit records
DROP POLICY IF EXISTS workout_exits_insert_policy ON workout_exits;
CREATE POLICY workout_exits_insert_policy ON workout_exits
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for service role to manage all records
DROP POLICY IF EXISTS workout_exits_service_policy ON workout_exits;
CREATE POLICY workout_exits_service_policy ON workout_exits
    FOR ALL
    USING (auth.role() = 'service_role');
