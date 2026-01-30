-- Migration: Add estimated_duration_minutes column to workouts table
-- This stores the AI-calculated actual workout duration based on exercises generated
-- Allows displaying "~38 min" instead of "30-45 min" to users

-- Add estimated_duration_minutes column (nullable for backward compatibility)
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS estimated_duration_minutes INTEGER;

-- Add check constraint: must be positive and reasonable (1-480 minutes)
ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS check_estimated_duration_valid;

ALTER TABLE workouts
ADD CONSTRAINT check_estimated_duration_valid
CHECK (estimated_duration_minutes IS NULL OR (estimated_duration_minutes >= 1 AND estimated_duration_minutes <= 480));

-- Add comment for documentation
COMMENT ON COLUMN workouts.estimated_duration_minutes IS 'AI-calculated estimated workout duration in minutes (includes exercises + rest + transitions). Set by Gemini when generating workouts.';

-- Note: This field is populated by the Gemini API when generating workouts
-- It represents the actual calculated time based on:
-- - Sum of all exercise durations (sets × (reps × 3 seconds + rest_seconds))
-- - Transition time between exercises (~30 seconds per exercise)
-- - Should be within duration_minutes_min and duration_minutes_max range if specified
