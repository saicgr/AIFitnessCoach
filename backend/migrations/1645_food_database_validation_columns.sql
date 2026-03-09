-- Migration 1645: Add validation/quality columns to food_database
-- and drop the now-redundant verified_foods table.

-- Add validation columns
ALTER TABLE food_database
  ADD COLUMN IF NOT EXISTS atwater_valid BOOLEAN,
  ADD COLUMN IF NOT EXISTS confidence_score REAL,
  ADD COLUMN IF NOT EXISTS verification_level TEXT,
  ADD COLUMN IF NOT EXISTS validation_flags JSONB,
  ADD COLUMN IF NOT EXISTS food_group_detected TEXT,
  ADD COLUMN IF NOT EXISTS validated_at TIMESTAMPTZ;

-- Index for filtering by quality (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_food_database_confidence
  ON food_database(confidence_score DESC)
  WHERE confidence_score IS NOT NULL AND is_primary = TRUE;

CREATE INDEX IF NOT EXISTS idx_food_database_verification
  ON food_database(verification_level)
  WHERE verification_level IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_food_database_atwater
  ON food_database(atwater_valid)
  WHERE is_primary = TRUE;

-- Drop verified_foods table (replaced by in-table validation columns)
DROP TABLE IF EXISTS verified_foods;

-- Drop the search RPC for verified_foods
DROP FUNCTION IF EXISTS search_verified_foods(TEXT, INT, INT);
