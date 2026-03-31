-- Add mood/wellness tracking columns to food_logs
-- These are populated post-logging via the review sheet

ALTER TABLE food_logs
  ADD COLUMN IF NOT EXISTS mood_before TEXT,
  ADD COLUMN IF NOT EXISTS mood_after TEXT,
  ADD COLUMN IF NOT EXISTS energy_level INTEGER;

-- Index for mood pattern analysis queries
CREATE INDEX IF NOT EXISTS idx_food_logs_mood
  ON food_logs (user_id, mood_before, mood_after)
  WHERE mood_before IS NOT NULL OR mood_after IS NOT NULL;

COMMENT ON COLUMN food_logs.mood_before IS 'User mood before eating: great, good, neutral, tired, stressed, hungry, satisfied, bloated';
COMMENT ON COLUMN food_logs.mood_after IS 'User mood after eating: great, good, neutral, tired, stressed, hungry, satisfied, bloated';
COMMENT ON COLUMN food_logs.energy_level IS 'Energy level 1-5 (1=very low, 5=high)';
