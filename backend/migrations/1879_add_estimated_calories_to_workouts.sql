-- Add estimated_calories column to workouts table
-- Used by workout generation to store MET-based calorie burn estimates
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS estimated_calories INTEGER;
