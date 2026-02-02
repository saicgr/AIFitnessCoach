-- Migration: 207_is_timed_exercises.sql
-- Description: Add is_timed column to exercise_library for time-based exercises (planks, wall sits, holds)
-- This enables proper UI display (timer vs reps) and per-set hold time progression

-- Add is_timed column to exercise_library
ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS is_timed BOOLEAN DEFAULT FALSE;

-- Create partial index for filtering timed exercises (only indexes TRUE values)
CREATE INDEX IF NOT EXISTS idx_exercise_library_is_timed ON exercise_library(is_timed) WHERE is_timed = TRUE;

-- Populate based on exercise name patterns (same keywords as warmup_stretch_service.py STATIC_EXERCISE_KEYWORDS)
UPDATE exercise_library SET is_timed = TRUE WHERE
    exercise_name ILIKE '%plank%' OR
    exercise_name ILIKE '%wall sit%' OR
    exercise_name ILIKE '%dead hang%' OR
    exercise_name ILIKE '%isometric%' OR
    exercise_name ILIKE '%l-sit%' OR
    exercise_name ILIKE '%hollow hold%' OR
    exercise_name ILIKE '%hollow body%' OR
    exercise_name ILIKE '%bridge hold%' OR
    exercise_name ILIKE '%superman hold%' OR
    exercise_name ILIKE '%static hold%' OR
    exercise_name ILIKE '%horse stance%' OR
    exercise_name ILIKE '%wall squat%';

-- Also mark exercises that already have default_hold_seconds set (from migration 062)
UPDATE exercise_library SET is_timed = TRUE
WHERE default_hold_seconds > 0 AND is_timed = FALSE;

-- Set default hold times for timed exercises that don't have one yet
UPDATE exercise_library SET default_hold_seconds = 30
WHERE is_timed = TRUE AND default_hold_seconds IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN exercise_library.is_timed IS 'True for exercises measured by time (planks, wall sits, holds) rather than reps. UI shows timer instead of rep counter.';
