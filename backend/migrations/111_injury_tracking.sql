-- Migration 111: Injury Tracking System
-- Comprehensive injury management with recovery tracking, rehab exercises, and check-ins.
-- Integrates with avoided_exercises and avoided_muscles for automatic workout modifications.

-- ============================================================
-- USER INJURIES TABLE
-- ============================================================
-- Persistent tracking of user injuries with recovery phases

CREATE TABLE IF NOT EXISTS user_injuries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Injury details
    body_part TEXT NOT NULL,
    injury_type TEXT CHECK (injury_type IS NULL OR injury_type IN ('strain', 'sprain', 'overuse', 'acute', 'chronic')),
    severity TEXT NOT NULL DEFAULT 'mild' CHECK (severity IN ('mild', 'moderate', 'severe')),
    -- Timeline
    reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    occurred_at DATE,
    expected_recovery_date DATE,
    actual_recovery_date DATE,
    -- Recovery tracking
    recovery_phase TEXT DEFAULT 'acute' CHECK (recovery_phase IN ('acute', 'subacute', 'recovery', 'healed')),
    pain_level INTEGER CHECK (pain_level IS NULL OR (pain_level BETWEEN 0 AND 10)),
    -- Workout modifications
    affects_exercises TEXT[], -- List of exercise names to avoid
    affects_muscles TEXT[], -- List of muscle groups to reduce/avoid
    -- Additional info
    notes TEXT,
    activity_when_occurred TEXT, -- What they were doing when injured
    reported_via TEXT DEFAULT 'app' CHECK (reported_via IN ('app', 'chat', 'onboarding')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'recovering', 'healed', 'chronic')),
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for user_injuries
CREATE INDEX IF NOT EXISTS idx_user_injuries_user ON user_injuries(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_injuries_body_part ON user_injuries(user_id, body_part);
CREATE INDEX IF NOT EXISTS idx_user_injuries_active ON user_injuries(user_id) WHERE status IN ('active', 'recovering');

-- Enable Row Level Security
ALTER TABLE user_injuries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_injuries
CREATE POLICY user_injuries_select_policy ON user_injuries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_injuries_insert_policy ON user_injuries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_injuries_update_policy ON user_injuries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY user_injuries_delete_policy ON user_injuries
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON user_injuries TO authenticated;


-- ============================================================
-- INJURY UPDATES TABLE
-- ============================================================
-- Check-ins and updates for tracking injury recovery progress

CREATE TABLE IF NOT EXISTS injury_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    injury_id UUID NOT NULL REFERENCES user_injuries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Progress metrics
    pain_level INTEGER CHECK (pain_level IS NULL OR (pain_level BETWEEN 0 AND 10)),
    mobility_rating INTEGER CHECK (mobility_rating IS NULL OR (mobility_rating BETWEEN 1 AND 5)), -- 1=very limited, 5=full mobility
    recovery_phase TEXT CHECK (recovery_phase IS NULL OR recovery_phase IN ('acute', 'subacute', 'recovery', 'healed')),
    -- Workout capability
    can_workout BOOLEAN DEFAULT TRUE,
    workout_modifications TEXT, -- Description of any modifications needed
    -- Notes
    notes TEXT,
    -- Timestamp
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for injury_updates
CREATE INDEX IF NOT EXISTS idx_injury_updates_injury ON injury_updates(injury_id, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_injury_updates_user ON injury_updates(user_id, checked_at DESC);

-- Enable Row Level Security
ALTER TABLE injury_updates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for injury_updates
CREATE POLICY injury_updates_select_policy ON injury_updates
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY injury_updates_insert_policy ON injury_updates
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY injury_updates_update_policy ON injury_updates
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY injury_updates_delete_policy ON injury_updates
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON injury_updates TO authenticated;


-- ============================================================
-- INJURY REHAB EXERCISES TABLE
-- ============================================================
-- Rehabilitation exercises assigned for each injury

CREATE TABLE IF NOT EXISTS injury_rehab_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    injury_id UUID NOT NULL REFERENCES user_injuries(id) ON DELETE CASCADE,
    -- Exercise details
    exercise_name TEXT NOT NULL,
    exercise_type TEXT CHECK (exercise_type IS NULL OR exercise_type IN ('mobility', 'stretching', 'strengthening', 'isometric')),
    -- Prescription
    sets INTEGER,
    reps INTEGER,
    hold_seconds INTEGER,
    frequency_per_day INTEGER DEFAULT 1,
    -- Instructions
    notes TEXT,
    -- Timestamps
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_count INTEGER DEFAULT 0, -- Track how often user has done this
    last_completed_at TIMESTAMPTZ
);

-- Indexes for injury_rehab_exercises
CREATE INDEX IF NOT EXISTS idx_injury_rehab_exercises_injury ON injury_rehab_exercises(injury_id);

-- Enable Row Level Security
ALTER TABLE injury_rehab_exercises ENABLE ROW LEVEL SECURITY;

-- RLS Policy for injury_rehab_exercises (via injury ownership)
CREATE POLICY injury_rehab_select_policy ON injury_rehab_exercises
    FOR SELECT USING (
        injury_id IN (SELECT id FROM user_injuries WHERE user_id = auth.uid())
    );

CREATE POLICY injury_rehab_insert_policy ON injury_rehab_exercises
    FOR INSERT WITH CHECK (
        injury_id IN (SELECT id FROM user_injuries WHERE user_id = auth.uid())
    );

CREATE POLICY injury_rehab_update_policy ON injury_rehab_exercises
    FOR UPDATE USING (
        injury_id IN (SELECT id FROM user_injuries WHERE user_id = auth.uid())
    );

CREATE POLICY injury_rehab_delete_policy ON injury_rehab_exercises
    FOR DELETE USING (
        injury_id IN (SELECT id FROM user_injuries WHERE user_id = auth.uid())
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON injury_rehab_exercises TO authenticated;


-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to get muscle injury status (for workout generation)
CREATE OR REPLACE FUNCTION get_muscle_injury_status(p_user_id UUID, p_muscle TEXT)
RETURNS TABLE(has_injury BOOLEAN, severity TEXT, recovery_phase TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        TRUE as has_injury,
        ui.severity,
        ui.recovery_phase
    FROM user_injuries ui
    WHERE ui.user_id = p_user_id
    AND ui.status IN ('active', 'recovering')
    AND (ui.body_part = p_muscle OR p_muscle = ANY(ui.affects_muscles))
    ORDER BY
        CASE ui.severity
            WHEN 'severe' THEN 1
            WHEN 'moderate' THEN 2
            WHEN 'mild' THEN 3
        END
    LIMIT 1;

    -- Return false if no injury found
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::TEXT, NULL::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all active injuries for a user
CREATE OR REPLACE FUNCTION get_active_injuries(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    body_part TEXT,
    injury_type TEXT,
    severity TEXT,
    recovery_phase TEXT,
    pain_level INTEGER,
    affects_exercises TEXT[],
    affects_muscles TEXT[],
    expected_recovery_date DATE,
    reported_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ui.id,
        ui.body_part,
        ui.injury_type,
        ui.severity,
        ui.recovery_phase,
        ui.pain_level,
        ui.affects_exercises,
        ui.affects_muscles,
        ui.expected_recovery_date,
        ui.reported_at
    FROM user_injuries ui
    WHERE ui.user_id = p_user_id
    AND ui.status IN ('active', 'recovering')
    ORDER BY ui.reported_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all exercises to avoid due to injuries
CREATE OR REPLACE FUNCTION get_injury_avoided_exercises(p_user_id UUID)
RETURNS TEXT[] AS $$
DECLARE
    result TEXT[] := '{}';
BEGIN
    SELECT array_agg(DISTINCT ex)
    INTO result
    FROM user_injuries ui, unnest(ui.affects_exercises) AS ex
    WHERE ui.user_id = p_user_id
    AND ui.status IN ('active', 'recovering');

    RETURN COALESCE(result, '{}');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_injury_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_injuries
DROP TRIGGER IF EXISTS trigger_user_injuries_updated_at ON user_injuries;
CREATE TRIGGER trigger_user_injuries_updated_at
    BEFORE UPDATE ON user_injuries
    FOR EACH ROW
    EXECUTE FUNCTION update_injury_updated_at();


-- ============================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE user_injuries IS 'Tracks user injuries with recovery phases and workout modifications';
COMMENT ON COLUMN user_injuries.body_part IS 'Body part affected (calf, lower_back, knee, shoulder, etc.)';
COMMENT ON COLUMN user_injuries.injury_type IS 'Type: strain, sprain, overuse, acute, or chronic';
COMMENT ON COLUMN user_injuries.severity IS 'Severity: mild (7 days), moderate (14 days), severe (35 days)';
COMMENT ON COLUMN user_injuries.recovery_phase IS 'Current phase: acute, subacute, recovery, or healed';
COMMENT ON COLUMN user_injuries.affects_exercises IS 'Array of exercise names to avoid';
COMMENT ON COLUMN user_injuries.affects_muscles IS 'Array of muscle groups affected';
COMMENT ON COLUMN user_injuries.status IS 'Status: active, recovering, healed, or chronic';

COMMENT ON TABLE injury_updates IS 'Check-ins for tracking injury recovery progress';
COMMENT ON COLUMN injury_updates.mobility_rating IS '1=very limited mobility, 5=full mobility';
COMMENT ON COLUMN injury_updates.can_workout IS 'Whether user can workout with modifications';

COMMENT ON TABLE injury_rehab_exercises IS 'Rehabilitation exercises prescribed for injuries';
COMMENT ON COLUMN injury_rehab_exercises.exercise_type IS 'Type: mobility, stretching, strengthening, or isometric';
COMMENT ON COLUMN injury_rehab_exercises.frequency_per_day IS 'How many times per day to perform';
