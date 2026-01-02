-- Migration: 112_progression_pace_settings
-- Description: User progression preferences for controlling workout intensity progression pace
-- Created: 2024-12-31

-- User progression preferences
CREATE TABLE IF NOT EXISTS user_progression_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    -- Overall progression pace
    overall_pace TEXT NOT NULL DEFAULT 'moderate', -- 'very_slow', 'slow', 'moderate', 'fast'

    -- Category-specific paces
    strength_pace TEXT DEFAULT 'moderate',
    cardio_pace TEXT DEFAULT 'slow', -- Default slower for cardio (injury prevention)
    flexibility_pace TEXT DEFAULT 'moderate',

    -- Advanced settings
    weight_increment_kg DECIMAL(3,1) DEFAULT 2.5,
    min_sessions_before_progression INTEGER DEFAULT 2, -- Sessions at same level before increasing
    require_completion_percent INTEGER DEFAULT 80, -- Must complete X% of prescribed before progressing

    -- Auto-adjust settings
    auto_deload_enabled BOOLEAN DEFAULT TRUE,
    deload_frequency_weeks INTEGER DEFAULT 4,
    fatigue_based_adjustment BOOLEAN DEFAULT TRUE,

    -- Safety limits
    max_weekly_volume_increase_percent INTEGER DEFAULT 10, -- The 10% rule
    max_weight_increase_percent INTEGER DEFAULT 10,

    -- Learning from feedback
    adjust_from_feedback BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Progression pace descriptions for UI
CREATE TABLE IF NOT EXISTS progression_pace_definitions (
    pace TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    description TEXT NOT NULL,
    sessions_before_increase INTEGER NOT NULL,
    weight_increase_percent DECIMAL(4,2) NOT NULL,
    recommended_for TEXT[], -- ['beginners', 'seniors', 'injury_recovery', 'advanced']
    icon TEXT
);

-- Insert pace definitions
INSERT INTO progression_pace_definitions (pace, display_name, description, sessions_before_increase, weight_increase_percent, recommended_for, icon) VALUES
('very_slow', 'Extra Cautious', 'Progress only after 4+ successful sessions. Ideal for injury recovery or seniors.', 4, 2.5, ARRAY['seniors', 'injury_recovery', 'beginners'], 'turtle'),
('slow', 'Gradual', 'Progress after 3 successful sessions. Safe for most beginners.', 3, 5.0, ARRAY['beginners', 'general'], 'walk'),
('moderate', 'Balanced', 'Progress after 2 successful sessions. Standard progression.', 2, 7.5, ARRAY['intermediate', 'general'], 'run'),
('fast', 'Aggressive', 'Progress as soon as ready. For experienced athletes.', 1, 10.0, ARRAY['advanced', 'athletes'], 'rocket')
ON CONFLICT (pace) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    sessions_before_increase = EXCLUDED.sessions_before_increase,
    weight_increase_percent = EXCLUDED.weight_increase_percent,
    recommended_for = EXCLUDED.recommended_for,
    icon = EXCLUDED.icon;

-- Create index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_progression_prefs_user ON user_progression_preferences(user_id);

-- Enable Row Level Security
ALTER TABLE user_progression_preferences ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON user_progression_preferences TO authenticated;
GRANT SELECT ON progression_pace_definitions TO authenticated;
GRANT SELECT ON progression_pace_definitions TO anon;
