-- Add user_weight_lbs column to staple_exercises table
-- Allows users to specify their preferred weight for strength exercises

ALTER TABLE staple_exercises
ADD COLUMN IF NOT EXISTS user_weight_lbs DOUBLE PRECISION DEFAULT NULL;

COMMENT ON COLUMN staple_exercises.user_weight_lbs IS 'User-specified weight in lbs for strength exercises';
