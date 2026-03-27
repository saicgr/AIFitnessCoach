-- Add target weight, target reps, and progression model tracking to performance_logs.
-- This allows us to compare planned vs actual performance and track which
-- progression model the user selected for each exercise.

ALTER TABLE performance_logs
  ADD COLUMN IF NOT EXISTS target_weight_kg FLOAT,
  ADD COLUMN IF NOT EXISTS target_reps INT,
  ADD COLUMN IF NOT EXISTS progression_model TEXT;

-- Add comment for documentation
COMMENT ON COLUMN performance_logs.target_weight_kg IS 'Planned target weight for this set (from AI or progression pattern)';
COMMENT ON COLUMN performance_logs.target_reps IS 'Planned target reps for this set (0 = AMRAP)';
COMMENT ON COLUMN performance_logs.progression_model IS 'Progression pattern used: pyramidUp, straightSets, reversePyramid, dropSets, topSetBackOff, restPause, myoReps';

-- Also add progression_model to workout_logs metadata for workout-level tracking
ALTER TABLE workout_logs
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN workout_logs.metadata IS 'Additional workout metadata: progression patterns, increment settings, etc.';
