-- Migration: Add SCD2 versioning to workouts table
-- This enables historical tracking and revert functionality

-- Add versioning columns to workouts table
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS version_number INTEGER DEFAULT 1;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT TRUE;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS valid_from TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS valid_to TIMESTAMPTZ;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS parent_workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS superseded_by UUID REFERENCES workouts(id) ON DELETE SET NULL;

-- Create index for faster version queries
CREATE INDEX IF NOT EXISTS idx_workouts_is_current ON workouts(is_current);
CREATE INDEX IF NOT EXISTS idx_workouts_parent_workout_id ON workouts(parent_workout_id);
CREATE INDEX IF NOT EXISTS idx_workouts_user_scheduled_current ON workouts(user_id, scheduled_date, is_current);

-- Update existing workouts to have proper versioning values
UPDATE workouts
SET version_number = 1,
    is_current = TRUE,
    valid_from = COALESCE(created_at, NOW())
WHERE version_number IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN workouts.version_number IS 'SCD2: Version number of this workout record';
COMMENT ON COLUMN workouts.is_current IS 'SCD2: Whether this is the current active version';
COMMENT ON COLUMN workouts.valid_from IS 'SCD2: When this version became active';
COMMENT ON COLUMN workouts.valid_to IS 'SCD2: When this version was superseded (NULL if current)';
COMMENT ON COLUMN workouts.parent_workout_id IS 'SCD2: Reference to the original workout ID (first version)';
COMMENT ON COLUMN workouts.superseded_by IS 'SCD2: Reference to the newer version that replaced this one';
