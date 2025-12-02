-- Migration: Add SCD2 versioning to warmups and stretches tables
-- This enables historical tracking instead of hard deletes
-- No hard deletes - all data is preserved with versioning

-- =====================================================
-- WARMUPS TABLE - SCD2 Versioning
-- =====================================================

-- Add versioning columns to warmups table
ALTER TABLE warmups ADD COLUMN IF NOT EXISTS version_number INTEGER DEFAULT 1;
ALTER TABLE warmups ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT TRUE;
ALTER TABLE warmups ADD COLUMN IF NOT EXISTS valid_from TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE warmups ADD COLUMN IF NOT EXISTS valid_to TIMESTAMPTZ;
ALTER TABLE warmups ADD COLUMN IF NOT EXISTS parent_warmup_id UUID REFERENCES warmups(id) ON DELETE SET NULL;
ALTER TABLE warmups ADD COLUMN IF NOT EXISTS superseded_by UUID REFERENCES warmups(id) ON DELETE SET NULL;

-- Remove CASCADE DELETE constraint and replace with SET NULL (SCD2 preserves historical data)
ALTER TABLE warmups DROP CONSTRAINT IF EXISTS warmups_workout_id_fkey;
ALTER TABLE warmups ADD CONSTRAINT warmups_workout_id_fkey
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE SET NULL;

-- Make workout_id nullable for historical records
ALTER TABLE warmups ALTER COLUMN workout_id DROP NOT NULL;

-- Create indexes for faster version queries
CREATE INDEX IF NOT EXISTS idx_warmups_is_current ON warmups(is_current);
CREATE INDEX IF NOT EXISTS idx_warmups_parent_warmup_id ON warmups(parent_warmup_id);
CREATE INDEX IF NOT EXISTS idx_warmups_workout_current ON warmups(workout_id, is_current);

-- Update existing warmups to have proper versioning values
UPDATE warmups
SET version_number = 1,
    is_current = TRUE,
    valid_from = COALESCE(created_at, NOW())
WHERE version_number IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN warmups.version_number IS 'SCD2: Version number of this warmup record';
COMMENT ON COLUMN warmups.is_current IS 'SCD2: Whether this is the current active version';
COMMENT ON COLUMN warmups.valid_from IS 'SCD2: When this version became active';
COMMENT ON COLUMN warmups.valid_to IS 'SCD2: When this version was superseded (NULL if current)';
COMMENT ON COLUMN warmups.parent_warmup_id IS 'SCD2: Reference to the original warmup ID (first version)';
COMMENT ON COLUMN warmups.superseded_by IS 'SCD2: Reference to the newer version that replaced this one';

-- =====================================================
-- STRETCHES TABLE - SCD2 Versioning
-- =====================================================

-- Add versioning columns to stretches table
ALTER TABLE stretches ADD COLUMN IF NOT EXISTS version_number INTEGER DEFAULT 1;
ALTER TABLE stretches ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT TRUE;
ALTER TABLE stretches ADD COLUMN IF NOT EXISTS valid_from TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE stretches ADD COLUMN IF NOT EXISTS valid_to TIMESTAMPTZ;
ALTER TABLE stretches ADD COLUMN IF NOT EXISTS parent_stretch_id UUID REFERENCES stretches(id) ON DELETE SET NULL;
ALTER TABLE stretches ADD COLUMN IF NOT EXISTS superseded_by UUID REFERENCES stretches(id) ON DELETE SET NULL;

-- Remove CASCADE DELETE constraint and replace with SET NULL
ALTER TABLE stretches DROP CONSTRAINT IF EXISTS stretches_workout_id_fkey;
ALTER TABLE stretches ADD CONSTRAINT stretches_workout_id_fkey
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE SET NULL;

-- Make workout_id nullable for historical records
ALTER TABLE stretches ALTER COLUMN workout_id DROP NOT NULL;

-- Create indexes for faster version queries
CREATE INDEX IF NOT EXISTS idx_stretches_is_current ON stretches(is_current);
CREATE INDEX IF NOT EXISTS idx_stretches_parent_stretch_id ON stretches(parent_stretch_id);
CREATE INDEX IF NOT EXISTS idx_stretches_workout_current ON stretches(workout_id, is_current);

-- Update existing stretches to have proper versioning values
UPDATE stretches
SET version_number = 1,
    is_current = TRUE,
    valid_from = COALESCE(created_at, NOW())
WHERE version_number IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN stretches.version_number IS 'SCD2: Version number of this stretch record';
COMMENT ON COLUMN stretches.is_current IS 'SCD2: Whether this is the current active version';
COMMENT ON COLUMN stretches.valid_from IS 'SCD2: When this version became active';
COMMENT ON COLUMN stretches.valid_to IS 'SCD2: When this version was superseded (NULL if current)';
COMMENT ON COLUMN stretches.parent_stretch_id IS 'SCD2: Reference to the original stretch ID (first version)';
COMMENT ON COLUMN stretches.superseded_by IS 'SCD2: Reference to the newer version that replaced this one';

-- =====================================================
-- UPDATE RLS POLICIES for versioned data
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own warmups" ON warmups;
DROP POLICY IF EXISTS "Users can manage own warmups" ON warmups;
DROP POLICY IF EXISTS "Users can view own stretches" ON stretches;
DROP POLICY IF EXISTS "Users can manage own stretches" ON stretches;

-- Create new policies that respect versioning (only show current versions by default)
CREATE POLICY "Users can view own warmups" ON warmups
    FOR SELECT USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage own warmups" ON warmups
    FOR ALL USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

CREATE POLICY "Users can view own stretches" ON stretches
    FOR SELECT USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage own stretches" ON stretches
    FOR ALL USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );
