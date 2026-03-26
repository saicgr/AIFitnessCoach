-- Add exercises_completed column to workout_logs table
-- Used by wrapped_service to count completed exercises per session
ALTER TABLE workout_logs ADD COLUMN IF NOT EXISTS exercises_completed INTEGER DEFAULT 0;
