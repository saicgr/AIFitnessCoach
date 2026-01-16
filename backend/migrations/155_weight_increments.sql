-- Migration: 155_weight_increments.sql
-- Description: Weight increment preferences per user per equipment type
-- Author: Claude
-- Date: 2026-01-15

-- Weight increment preferences per user per equipment type
CREATE TABLE IF NOT EXISTS weight_increments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Equipment-specific increments (stored in user's preferred unit)
    dumbbell DECIMAL(4,2) DEFAULT 2.5,
    barbell DECIMAL(4,2) DEFAULT 2.5,
    machine DECIMAL(4,2) DEFAULT 5.0,
    kettlebell DECIMAL(4,2) DEFAULT 4.0,
    cable DECIMAL(4,2) DEFAULT 2.5,

    -- Unit preference for increments (kg or lbs)
    unit VARCHAR(3) DEFAULT 'kg' CHECK (unit IN ('kg', 'lbs')),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_weight_increments_user_id ON weight_increments(user_id);

-- Enable RLS
ALTER TABLE weight_increments ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own weight increments"
    ON weight_increments FOR SELECT
    USING (auth.uid() = user_id OR user_id::text = current_setting('app.current_user_id', true));

CREATE POLICY "Users can insert own weight increments"
    ON weight_increments FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id::text = current_setting('app.current_user_id', true));

CREATE POLICY "Users can update own weight increments"
    ON weight_increments FOR UPDATE
    USING (auth.uid() = user_id OR user_id::text = current_setting('app.current_user_id', true));

CREATE POLICY "Users can delete own weight increments"
    ON weight_increments FOR DELETE
    USING (auth.uid() = user_id OR user_id::text = current_setting('app.current_user_id', true));

-- Comment on table
COMMENT ON TABLE weight_increments IS 'User-customizable weight increment settings per equipment type';
COMMENT ON COLUMN weight_increments.dumbbell IS 'Weight increment for dumbbell exercises (default 2.5 kg)';
COMMENT ON COLUMN weight_increments.barbell IS 'Weight increment for barbell exercises (default 2.5 kg)';
COMMENT ON COLUMN weight_increments.machine IS 'Weight increment for machine exercises (default 5.0 kg)';
COMMENT ON COLUMN weight_increments.kettlebell IS 'Weight increment for kettlebell exercises (default 4.0 kg)';
COMMENT ON COLUMN weight_increments.cable IS 'Weight increment for cable exercises (default 2.5 kg)';
COMMENT ON COLUMN weight_increments.unit IS 'Unit preference for displaying increments (kg or lbs)';
