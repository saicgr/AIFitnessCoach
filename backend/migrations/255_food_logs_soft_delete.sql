-- Add soft delete column to food_logs (SCD2 pattern)
-- Follows same pattern as saved_foods.deleted_at and user_recipes.deleted_at
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Partial index for efficient queries on active (non-deleted) records
CREATE INDEX IF NOT EXISTS idx_food_logs_user_not_deleted
  ON food_logs(user_id, logged_at DESC)
  WHERE deleted_at IS NULL;
