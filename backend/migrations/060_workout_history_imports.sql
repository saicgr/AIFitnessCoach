-- Migration: 060_workout_history_imports.sql
-- Description: Add table for manual workout history imports to seed strength data
-- This allows users to input past workout data so the AI can learn their strength levels
-- without requiring them to complete workouts through the active workout flow.

-- Table for imported workout history (manual entry of past workouts)
CREATE TABLE IF NOT EXISTS workout_history_imports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    weight_kg DECIMAL(6,2) NOT NULL CHECK (weight_kg >= 0),
    reps INTEGER NOT NULL CHECK (reps > 0),
    sets INTEGER NOT NULL DEFAULT 1 CHECK (sets > 0),
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'import', 'spreadsheet')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookups by user
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_user_id
ON workout_history_imports(user_id);

-- Index for looking up by exercise name (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_exercise_name
ON workout_history_imports(LOWER(exercise_name));

-- Composite index for user + exercise lookups
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_user_exercise
ON workout_history_imports(user_id, LOWER(exercise_name));

-- Index for date-based queries
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_performed_at
ON workout_history_imports(user_id, performed_at DESC);

-- Enable RLS
ALTER TABLE workout_history_imports ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own imported workout history"
ON workout_history_imports FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own imported workout history"
ON workout_history_imports FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own imported workout history"
ON workout_history_imports FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own imported workout history"
ON workout_history_imports FOR DELETE
USING (auth.uid() = user_id);

-- Service role bypass for API access
CREATE POLICY "Service role has full access to workout_history_imports"
ON workout_history_imports FOR ALL
USING (auth.role() = 'service_role');

-- Add preference_impact_log table to track how preferences affected workout generation
CREATE TABLE IF NOT EXISTS preference_impact_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID,
    generation_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- What preferences were active
    consistency_mode TEXT,
    favorites_count INTEGER DEFAULT 0,
    queued_count INTEGER DEFAULT 0,
    strength_history_count INTEGER DEFAULT 0,

    -- Impact tracking
    favorites_included INTEGER DEFAULT 0,
    favorites_boosted INTEGER DEFAULT 0,
    queued_included INTEGER DEFAULT 0,
    queued_excluded_reasons JSONB DEFAULT '[]'::jsonb,
    historical_weights_used INTEGER DEFAULT 0,
    generic_weights_used INTEGER DEFAULT 0,
    recently_used_avoided INTEGER DEFAULT 0,
    recently_used_preferred INTEGER DEFAULT 0,

    -- Summary for UI display
    impact_summary TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_preference_impact_log_user_id
ON preference_impact_log(user_id);

-- Index for recent logs
CREATE INDEX IF NOT EXISTS idx_preference_impact_log_timestamp
ON preference_impact_log(user_id, generation_timestamp DESC);

-- Enable RLS
ALTER TABLE preference_impact_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own preference impact logs"
ON preference_impact_log FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to preference_impact_log"
ON preference_impact_log FOR ALL
USING (auth.role() = 'service_role');

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_workout_history_imports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS trigger_update_workout_history_imports_updated_at ON workout_history_imports;
CREATE TRIGGER trigger_update_workout_history_imports_updated_at
    BEFORE UPDATE ON workout_history_imports
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_history_imports_updated_at();

-- Comments for documentation
COMMENT ON TABLE workout_history_imports IS 'Stores manually imported workout history for AI strength learning';
COMMENT ON COLUMN workout_history_imports.source IS 'How the data was entered: manual (UI), import (bulk), spreadsheet (CSV)';
COMMENT ON TABLE preference_impact_log IS 'Tracks how user preferences affected workout generation for transparency';
