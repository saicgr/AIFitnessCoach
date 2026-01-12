-- Migration: Add timestamp columns for tracking onboarding and workout completion times
-- Created: 2026-01-11

-- Add onboarding completion timestamp to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- Backfill existing users: use created_at as fallback for users who completed onboarding
UPDATE users
SET onboarding_completed_at = created_at
WHERE onboarding_completed = true AND onboarding_completed_at IS NULL;

-- Add workout completion timestamp directly on workouts table (for quick access without joining workout_logs)
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Backfill from workout_logs for existing completed workouts
UPDATE workouts w
SET completed_at = (
    SELECT wl.completed_at
    FROM workout_logs wl
    WHERE wl.workout_id = w.id
    ORDER BY wl.completed_at DESC
    LIMIT 1
)
WHERE w.is_completed = true AND w.completed_at IS NULL;

-- Add indexes for efficient queries on timestamp columns
CREATE INDEX IF NOT EXISTS idx_workouts_completed_at ON workouts(completed_at);
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed_at ON users(onboarding_completed_at);

-- Add comments for documentation
COMMENT ON COLUMN users.onboarding_completed_at IS 'Timestamp when user completed onboarding flow';
COMMENT ON COLUMN workouts.completed_at IS 'Timestamp when workout was marked as completed';
