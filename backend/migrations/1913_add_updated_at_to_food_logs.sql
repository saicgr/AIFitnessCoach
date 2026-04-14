-- The update_food_log helper writes an updated_at column that was never added
-- to the food_logs table, so every partial update (portion edits, notes,
-- mood, and the new per-field nutrition edits) was returning PGRST204.
-- Add it now; backfill existing rows from created_at.

ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

UPDATE food_logs SET updated_at = created_at WHERE updated_at IS NULL;

COMMENT ON COLUMN food_logs.updated_at IS
  'Touched by update_food_log() on every partial update; maintained explicitly by the helper.';
