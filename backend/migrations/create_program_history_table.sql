-- Create program_history table to store snapshots of user workout programs
-- This allows users to view and restore previous program configurations

CREATE TABLE IF NOT EXISTS program_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Program configuration snapshot
    preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    equipment TEXT[] DEFAULT ARRAY[]::TEXT[],
    injuries TEXT[] DEFAULT ARRAY[]::TEXT[],
    focus_areas TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Program metadata
    program_name TEXT,  -- Optional user-defined name like "Summer Training"
    description TEXT,   -- Optional description

    -- Status tracking
    is_current BOOLEAN DEFAULT false,  -- Whether this is the active program
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    applied_at TIMESTAMP WITH TIME ZONE,  -- When user last activated this program

    -- Analytics
    total_workouts_completed INTEGER DEFAULT 0,  -- Track success of this program
    last_workout_date DATE,  -- When user last worked out with this program

    CONSTRAINT valid_preferences CHECK (jsonb_typeof(preferences) = 'object')
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_program_history_user_id ON program_history(user_id);
CREATE INDEX IF NOT EXISTS idx_program_history_current ON program_history(user_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_program_history_created ON program_history(user_id, created_at DESC);

-- Ensure only one current program per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_current_program_per_user
ON program_history(user_id)
WHERE is_current = true;

-- Add helpful comments
COMMENT ON TABLE program_history IS 'Stores historical snapshots of user workout programs for viewing and restoration';
COMMENT ON COLUMN program_history.preferences IS 'JSONB containing intensity_preference, workout_duration, selected_days, training_split, etc.';
COMMENT ON COLUMN program_history.is_current IS 'Only one program can be current per user (enforced by unique index)';
COMMENT ON COLUMN program_history.applied_at IS 'Timestamp when user activated/restored this program';
COMMENT ON COLUMN program_history.total_workouts_completed IS 'Number of workouts completed while this program was active';
