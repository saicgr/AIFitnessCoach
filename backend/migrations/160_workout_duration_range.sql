-- Migration: Add duration range columns to workouts table
-- This allows users to specify a duration range (e.g., 45-60 min) instead of a fixed duration

-- Add duration range columns (nullable for backward compatibility)
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS duration_minutes_min INTEGER,
ADD COLUMN IF NOT EXISTS duration_minutes_max INTEGER;

-- Add check constraint: min must be <= max if both are set
ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS check_duration_range;

ALTER TABLE workouts
ADD CONSTRAINT check_duration_range
CHECK (
    duration_minutes_min IS NULL
    OR duration_minutes_max IS NULL
    OR duration_minutes_min <= duration_minutes_max
);

-- Add check constraint: values must be positive and reasonable (1-480 minutes)
ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS check_duration_min_valid;

ALTER TABLE workouts
ADD CONSTRAINT check_duration_min_valid
CHECK (duration_minutes_min IS NULL OR (duration_minutes_min >= 1 AND duration_minutes_min <= 480));

ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS check_duration_max_valid;

ALTER TABLE workouts
ADD CONSTRAINT check_duration_max_valid
CHECK (duration_minutes_max IS NULL OR (duration_minutes_max >= 1 AND duration_minutes_max <= 480));

-- Add comments for documentation
COMMENT ON COLUMN workouts.duration_minutes_min IS 'Minimum target duration in minutes for flexible workouts';
COMMENT ON COLUMN workouts.duration_minutes_max IS 'Maximum target duration in minutes for flexible workouts';

-- Note: user_preferences table doesn't exist in this schema
-- Duration range preferences are stored in users.preferences JSON column instead
