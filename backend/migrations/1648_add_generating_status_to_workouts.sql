-- Add 'generating' to workouts status check constraint
-- The code uses status='generating' for placeholder rows during workout generation
-- to prevent concurrent generation, but the constraint didn't include it.

ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS workouts_status_check;

ALTER TABLE workouts
ADD CONSTRAINT workouts_status_check
CHECK (status IN ('scheduled', 'completed', 'missed', 'skipped', 'rescheduled', 'generating'));
