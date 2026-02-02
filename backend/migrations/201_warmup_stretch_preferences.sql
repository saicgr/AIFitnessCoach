-- Migration: 201_warmup_stretch_preferences.sql
-- Created: 2025-02-01
-- Purpose: Add custom warmup/stretch preferences table for user-defined routines
-- Features:
--   - Pre-workout routines (e.g., "10min inclined treadmill walk")
--   - Post-exercise routines (e.g., "5min cooldown walk before stretches")
--   - Preferred/avoided warmups and stretches

-- ============================================
-- TABLE: warmup_stretch_preferences
-- ============================================

CREATE TABLE IF NOT EXISTS warmup_stretch_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Pre-workout routine (before dynamic warmups)
    -- Example: [{"name": "Inclined Treadmill Walk", "duration_minutes": 10, "settings": {"incline": 3.0, "speed_mph": 3.0}}]
    pre_workout_routine JSONB DEFAULT '[]'::jsonb,

    -- Post-exercise routine (after main workout, before stretches)
    -- Example: [{"name": "Cooldown Walk", "duration_minutes": 5}]
    post_exercise_routine JSONB DEFAULT '[]'::jsonb,

    -- Preferred warmups (always include if possible)
    -- Example: ["Jumping Jacks", "Arm Circles"]
    preferred_warmups JSONB DEFAULT '[]'::jsonb,

    -- Avoided warmups (never include)
    -- Example: ["High Knees"]
    avoided_warmups JSONB DEFAULT '[]'::jsonb,

    -- Preferred stretches (always include if possible)
    preferred_stretches JSONB DEFAULT '[]'::jsonb,

    -- Avoided stretches (never include)
    avoided_stretches JSONB DEFAULT '[]'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_warmup_stretch_preferences_user_id
    ON warmup_stretch_preferences(user_id);

-- Enable RLS
ALTER TABLE warmup_stretch_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Users can view their own preferences
CREATE POLICY "Users can view own warmup_stretch_preferences"
    ON warmup_stretch_preferences FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can insert their own preferences
CREATE POLICY "Users can insert own warmup_stretch_preferences"
    ON warmup_stretch_preferences FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can update their own preferences
CREATE POLICY "Users can update own warmup_stretch_preferences"
    ON warmup_stretch_preferences FOR UPDATE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can delete their own preferences
CREATE POLICY "Users can delete own warmup_stretch_preferences"
    ON warmup_stretch_preferences FOR DELETE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Service role has full access
CREATE POLICY "Service role full access warmup_stretch_preferences"
    ON warmup_stretch_preferences FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- TRIGGER: Update updated_at on modification
-- ============================================

CREATE OR REPLACE FUNCTION update_warmup_stretch_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_warmup_stretch_preferences_updated_at ON warmup_stretch_preferences;
CREATE TRIGGER trigger_warmup_stretch_preferences_updated_at
    BEFORE UPDATE ON warmup_stretch_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_warmup_stretch_preferences_updated_at();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE warmup_stretch_preferences IS 'User preferences for custom warmup and stretch routines';
COMMENT ON COLUMN warmup_stretch_preferences.pre_workout_routine IS 'Custom exercises to perform before dynamic warmups (e.g., treadmill walk)';
COMMENT ON COLUMN warmup_stretch_preferences.post_exercise_routine IS 'Custom exercises to perform after main workout, before stretches';
COMMENT ON COLUMN warmup_stretch_preferences.preferred_warmups IS 'Warmup exercise names to always include when possible';
COMMENT ON COLUMN warmup_stretch_preferences.avoided_warmups IS 'Warmup exercise names to never include';
COMMENT ON COLUMN warmup_stretch_preferences.preferred_stretches IS 'Stretch exercise names to always include when possible';
COMMENT ON COLUMN warmup_stretch_preferences.avoided_stretches IS 'Stretch exercise names to never include';
