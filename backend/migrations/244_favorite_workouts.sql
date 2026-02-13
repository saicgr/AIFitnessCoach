-- Add is_favorite column to workouts table for favorite workout sessions
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;

-- Partial index for efficient lookups - only indexes favorited workouts
CREATE INDEX IF NOT EXISTS idx_workouts_user_favorite
  ON workouts(user_id, is_favorite) WHERE is_favorite = TRUE;
