-- Migration 101: Quick Workouts Feature
-- Adds support for tracking quick workout preferences and history
-- Addresses user feedback for "fuss-free" quick workout experience

-- ============================================================
-- Quick Workout Preferences Table
-- ============================================================
-- Tracks user preferences for quick workouts (5-15 minute sessions)

CREATE TABLE IF NOT EXISTS quick_workout_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    preferred_duration INTEGER DEFAULT 10 CHECK (preferred_duration >= 5 AND preferred_duration <= 15),
    preferred_focus TEXT CHECK (preferred_focus IN ('cardio', 'strength', 'stretch', 'full_body', NULL)),
    quick_workout_count INTEGER DEFAULT 0,
    last_quick_workout_at TIMESTAMPTZ,
    -- Track source of quick workout requests for analytics
    -- 'button' = user clicked quick workout button in UI
    -- 'chat' = user requested quick workout via chat/AI coach
    source VARCHAR(50) DEFAULT 'button' CHECK (source IN ('button', 'chat')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Index for efficient user lookups
CREATE INDEX IF NOT EXISTS idx_quick_workout_preferences_user_id
    ON quick_workout_preferences(user_id);

-- Index for analytics on source (button vs chat usage patterns)
CREATE INDEX IF NOT EXISTS idx_quick_workout_preferences_source
    ON quick_workout_preferences(source);

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE quick_workout_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only view their own preferences
CREATE POLICY "Users can view own quick workout preferences"
    ON quick_workout_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own quick workout preferences"
    ON quick_workout_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own quick workout preferences"
    ON quick_workout_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "Users can delete own quick workout preferences"
    ON quick_workout_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================
-- Trigger for updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_quick_workout_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_quick_workout_preferences_updated_at ON quick_workout_preferences;
CREATE TRIGGER trigger_quick_workout_preferences_updated_at
    BEFORE UPDATE ON quick_workout_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_quick_workout_preferences_updated_at();

-- ============================================================
-- Function to increment quick workout count
-- ============================================================

CREATE OR REPLACE FUNCTION increment_quick_workout_count(uid UUID, workout_source VARCHAR DEFAULT 'button')
RETURNS INTEGER AS $$
DECLARE
    new_count INTEGER;
BEGIN
    UPDATE quick_workout_preferences
    SET quick_workout_count = quick_workout_count + 1,
        last_quick_workout_at = NOW(),
        source = workout_source
    WHERE user_id = uid
    RETURNING quick_workout_count INTO new_count;

    IF new_count IS NULL THEN
        INSERT INTO quick_workout_preferences (user_id, quick_workout_count, last_quick_workout_at, source)
        VALUES (uid, 1, NOW(), workout_source)
        RETURNING quick_workout_count INTO new_count;
    END IF;

    RETURN new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Analytics View for Quick Workout Usage
-- ============================================================

CREATE OR REPLACE VIEW quick_workout_analytics AS
SELECT
    preferred_duration,
    preferred_focus,
    source,
    COUNT(*) as user_count,
    AVG(quick_workout_count) as avg_usage,
    MAX(quick_workout_count) as max_usage
FROM quick_workout_preferences
WHERE quick_workout_count > 0
GROUP BY preferred_duration, preferred_focus, source
ORDER BY user_count DESC;

-- Grant access to the analytics view
GRANT SELECT ON quick_workout_analytics TO authenticated;

-- ============================================================
-- Source Analytics View
-- ============================================================
-- Provides insights into button vs chat quick workout usage

CREATE OR REPLACE VIEW quick_workout_source_analytics AS
SELECT
    source,
    COUNT(*) as total_users,
    SUM(quick_workout_count) as total_workouts,
    AVG(quick_workout_count) as avg_workouts_per_user,
    MIN(last_quick_workout_at) as earliest_workout,
    MAX(last_quick_workout_at) as latest_workout
FROM quick_workout_preferences
WHERE quick_workout_count > 0
GROUP BY source
ORDER BY total_workouts DESC;

-- Grant access to the source analytics view
GRANT SELECT ON quick_workout_source_analytics TO authenticated;

-- ============================================================
-- Comment Documentation
-- ============================================================

COMMENT ON TABLE quick_workout_preferences IS
    'Stores user preferences for quick workouts (5-15 minute sessions). Part of the Quick Start feature addressing "fuss-free" user experience feedback.';

COMMENT ON COLUMN quick_workout_preferences.preferred_duration IS
    'User''s preferred quick workout duration in minutes (5, 10, or 15)';

COMMENT ON COLUMN quick_workout_preferences.preferred_focus IS
    'User''s preferred workout focus: cardio, strength, stretch, or full_body';

COMMENT ON COLUMN quick_workout_preferences.quick_workout_count IS
    'Total number of quick workouts completed by this user';

COMMENT ON COLUMN quick_workout_preferences.source IS
    'Source of the quick workout request: button (UI button) or chat (AI coach conversation)';

-- ============================================================
-- Migration for existing tables (if table already exists)
-- ============================================================
-- This section safely adds the source column to existing tables

DO $$
BEGIN
    -- Add source column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'quick_workout_preferences'
        AND column_name = 'source'
    ) THEN
        ALTER TABLE quick_workout_preferences
        ADD COLUMN source VARCHAR(50) DEFAULT 'button'
        CHECK (source IN ('button', 'chat'));

        -- Create index for the new column
        CREATE INDEX IF NOT EXISTS idx_quick_workout_preferences_source
            ON quick_workout_preferences(source);
    END IF;
END $$;
