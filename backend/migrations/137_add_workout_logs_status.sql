-- Migration: Add status column to workout_logs table
-- This column is referenced by triggers in migrations 100_milestones.sql,
-- 029_saved_scheduled_workouts.sql, and 074_fix_function_search_paths.sql
-- but was never added to the table.

-- Add status column with default 'completed' (since existing rows are completed workouts)
ALTER TABLE workout_logs
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'completed';

-- Add index for status queries
CREATE INDEX IF NOT EXISTS idx_workout_logs_status ON workout_logs(status);

-- Update any existing rows that might have NULL status
UPDATE workout_logs SET status = 'completed' WHERE status IS NULL;

-- Add check constraint for valid statuses
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'workout_logs_status_check'
    ) THEN
        ALTER TABLE workout_logs
        ADD CONSTRAINT workout_logs_status_check
        CHECK (status IN ('completed', 'in_progress', 'abandoned', 'paused'));
    END IF;
END;
$$;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON workout_logs TO authenticated;
GRANT ALL ON workout_logs TO service_role;
