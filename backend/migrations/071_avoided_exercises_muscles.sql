-- Migration 071: Avoided Exercises and Muscles System
-- Allows users to specify exercises and muscle groups they want to avoid
-- Useful for injuries, limitations, or personal preferences

-- ============================================================
-- AVOIDED EXERCISES TABLE
-- ============================================================
-- Stores exercises the user wants to exclude from workout generation

CREATE TABLE IF NOT EXISTS avoided_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    -- Optional reference to exercise library
    exercise_id TEXT,
    -- Reason for avoiding (injury, dislike, equipment, etc.)
    reason TEXT,
    -- Whether this is temporary (e.g., injury recovery)
    is_temporary BOOLEAN DEFAULT FALSE,
    -- Optional end date for temporary avoidance
    end_date DATE,
    -- Tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure a user can only avoid an exercise once
    UNIQUE(user_id, exercise_name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_avoided_exercises_user_id
ON avoided_exercises(user_id);

CREATE INDEX IF NOT EXISTS idx_avoided_exercises_name
ON avoided_exercises(user_id, exercise_name);

CREATE INDEX IF NOT EXISTS idx_avoided_exercises_active
ON avoided_exercises(user_id) WHERE (is_temporary = FALSE OR end_date IS NULL OR end_date > CURRENT_DATE);

-- Enable Row Level Security
ALTER TABLE avoided_exercises ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY avoided_exercises_select_policy ON avoided_exercises
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY avoided_exercises_insert_policy ON avoided_exercises
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY avoided_exercises_update_policy ON avoided_exercises
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY avoided_exercises_delete_policy ON avoided_exercises
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON avoided_exercises TO authenticated;

-- ============================================================
-- AVOIDED MUSCLES TABLE
-- ============================================================
-- Stores muscle groups the user wants to avoid targeting

CREATE TABLE IF NOT EXISTS avoided_muscles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    muscle_group TEXT NOT NULL,
    -- Reason for avoiding (injury, recovery, etc.)
    reason TEXT,
    -- Whether this is temporary (e.g., injury recovery)
    is_temporary BOOLEAN DEFAULT FALSE,
    -- Optional end date for temporary avoidance
    end_date DATE,
    -- Severity: 'avoid' (completely skip) or 'reduce' (limit exposure)
    severity TEXT DEFAULT 'avoid' CHECK (severity IN ('avoid', 'reduce')),
    -- Tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure a user can only avoid a muscle once
    UNIQUE(user_id, muscle_group)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_avoided_muscles_user_id
ON avoided_muscles(user_id);

CREATE INDEX IF NOT EXISTS idx_avoided_muscles_active
ON avoided_muscles(user_id) WHERE (is_temporary = FALSE OR end_date IS NULL OR end_date > CURRENT_DATE);

-- Enable Row Level Security
ALTER TABLE avoided_muscles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY avoided_muscles_select_policy ON avoided_muscles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY avoided_muscles_insert_policy ON avoided_muscles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY avoided_muscles_update_policy ON avoided_muscles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY avoided_muscles_delete_policy ON avoided_muscles
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON avoided_muscles TO authenticated;

-- ============================================================
-- USER CONTEXT LOGGING
-- ============================================================
-- Log context updates for AI training and debugging

-- Add columns to user_context_logs if not exists (from migration 059)
DO $$
BEGIN
    -- Add avoided_exercises column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_context_logs'
        AND column_name = 'avoided_exercises'
    ) THEN
        ALTER TABLE user_context_logs ADD COLUMN avoided_exercises JSONB;
    END IF;

    -- Add avoided_muscles column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_context_logs'
        AND column_name = 'avoided_muscles'
    ) THEN
        ALTER TABLE user_context_logs ADD COLUMN avoided_muscles JSONB;
    END IF;
END $$;

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to get active avoided exercises for a user
CREATE OR REPLACE FUNCTION get_active_avoided_exercises(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    exercise_name TEXT,
    exercise_id TEXT,
    reason TEXT,
    is_temporary BOOLEAN,
    end_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ae.id,
        ae.exercise_name,
        ae.exercise_id,
        ae.reason,
        ae.is_temporary,
        ae.end_date
    FROM avoided_exercises ae
    WHERE ae.user_id = p_user_id
    AND (ae.is_temporary = FALSE OR ae.end_date IS NULL OR ae.end_date > CURRENT_DATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get active avoided muscles for a user
CREATE OR REPLACE FUNCTION get_active_avoided_muscles(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    muscle_group TEXT,
    reason TEXT,
    is_temporary BOOLEAN,
    end_date DATE,
    severity TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        am.id,
        am.muscle_group,
        am.reason,
        am.is_temporary,
        am.end_date,
        am.severity
    FROM avoided_muscles am
    WHERE am.user_id = p_user_id
    AND (am.is_temporary = FALSE OR am.end_date IS NULL OR am.end_date > CURRENT_DATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE avoided_exercises IS 'Stores exercises users want to exclude from AI-generated workouts';
COMMENT ON COLUMN avoided_exercises.exercise_name IS 'Name of exercise to avoid (used in Gemini prompt filtering)';
COMMENT ON COLUMN avoided_exercises.reason IS 'User-provided reason (injury, dislike, etc.)';
COMMENT ON COLUMN avoided_exercises.is_temporary IS 'Whether this avoidance is temporary (e.g., injury recovery)';
COMMENT ON COLUMN avoided_exercises.end_date IS 'Date when temporary avoidance ends';

COMMENT ON TABLE avoided_muscles IS 'Stores muscle groups users want to avoid in workouts';
COMMENT ON COLUMN avoided_muscles.muscle_group IS 'Name of muscle group to avoid (chest, shoulders, lower_back, etc.)';
COMMENT ON COLUMN avoided_muscles.severity IS 'avoid = completely skip, reduce = limit exercises targeting this muscle';

-- ============================================================
-- SEED DATA: Common Muscle Groups
-- ============================================================
-- This is just for reference - users select from this list

-- Common muscle groups that can be avoided:
-- Primary: chest, back, shoulders, biceps, triceps, core, quadriceps, hamstrings, glutes, calves
-- Specific: lower_back, upper_back, lats, traps, forearms, hip_flexors, adductors, abductors
