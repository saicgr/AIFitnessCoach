-- Migration: 093_sound_preferences.sql
-- Add customizable sound preferences for countdown timers and workout completion
-- This addresses user feedback: "countdown timer sux plus cheesy applause smh. sounds should be customizable"

-- Add sound preferences columns to user_preferences table (or create sound_preferences table)
-- Check if user_preferences exists, otherwise create sound_preferences table

DO $$
BEGIN
    -- Try to add columns to user_preferences if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        -- Countdown sound settings
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS countdown_sound_enabled BOOLEAN DEFAULT true;
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS countdown_sound_type TEXT DEFAULT 'beep';

        -- Completion sound settings (NO applause - user hates it)
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS completion_sound_enabled BOOLEAN DEFAULT true;
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS completion_sound_type TEXT DEFAULT 'chime';

        -- Volume control
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS sound_effects_volume DECIMAL(3,2) DEFAULT 0.8;

        -- Rest timer sound
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS rest_timer_sound_enabled BOOLEAN DEFAULT true;
        ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS rest_timer_sound_type TEXT DEFAULT 'beep';

        RAISE NOTICE 'Added sound preference columns to user_preferences table';
    ELSE
        -- Create dedicated sound_preferences table
        CREATE TABLE IF NOT EXISTS sound_preferences (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

            -- Countdown sounds (3, 2, 1 before exercise/rest ends)
            countdown_sound_enabled BOOLEAN DEFAULT true,
            countdown_sound_type TEXT DEFAULT 'beep', -- beep, chime, voice, tick, none

            -- Completion sounds (workout done) - NO APPLAUSE options
            completion_sound_enabled BOOLEAN DEFAULT true,
            completion_sound_type TEXT DEFAULT 'chime', -- chime, bell, success, fanfare, none

            -- Rest timer sounds
            rest_timer_sound_enabled BOOLEAN DEFAULT true,
            rest_timer_sound_type TEXT DEFAULT 'beep',

            -- Volume control (0.0 to 1.0)
            sound_effects_volume DECIMAL(3,2) DEFAULT 0.8,

            -- Timestamps
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),

            UNIQUE(user_id)
        );

        RAISE NOTICE 'Created sound_preferences table';
    END IF;
END $$;

-- Create sound_preferences table if user_preferences approach didn't work
CREATE TABLE IF NOT EXISTS sound_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Countdown sounds
    countdown_sound_enabled BOOLEAN DEFAULT true,
    countdown_sound_type TEXT DEFAULT 'beep',

    -- Completion sounds (explicitly NO applause)
    completion_sound_enabled BOOLEAN DEFAULT true,
    completion_sound_type TEXT DEFAULT 'chime',

    -- Rest timer sounds
    rest_timer_sound_enabled BOOLEAN DEFAULT true,
    rest_timer_sound_type TEXT DEFAULT 'beep',

    -- Volume
    sound_effects_volume DECIMAL(3,2) DEFAULT 0.8,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id)
);

-- Add constraints for valid sound types
ALTER TABLE sound_preferences DROP CONSTRAINT IF EXISTS sound_preferences_countdown_type_check;
ALTER TABLE sound_preferences ADD CONSTRAINT sound_preferences_countdown_type_check
    CHECK (countdown_sound_type IN ('beep', 'chime', 'voice', 'tick', 'none'));

ALTER TABLE sound_preferences DROP CONSTRAINT IF EXISTS sound_preferences_completion_type_check;
ALTER TABLE sound_preferences ADD CONSTRAINT sound_preferences_completion_type_check
    CHECK (completion_sound_type IN ('chime', 'bell', 'success', 'fanfare', 'none'));
    -- NOTE: No 'applause' option - user specifically hates it

ALTER TABLE sound_preferences DROP CONSTRAINT IF EXISTS sound_preferences_rest_type_check;
ALTER TABLE sound_preferences ADD CONSTRAINT sound_preferences_rest_type_check
    CHECK (rest_timer_sound_type IN ('beep', 'chime', 'voice', 'tick', 'none'));

-- Volume must be between 0 and 1
ALTER TABLE sound_preferences DROP CONSTRAINT IF EXISTS sound_preferences_volume_check;
ALTER TABLE sound_preferences ADD CONSTRAINT sound_preferences_volume_check
    CHECK (sound_effects_volume >= 0.0 AND sound_effects_volume <= 1.0);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_sound_preferences_user_id ON sound_preferences(user_id);

-- Enable RLS
ALTER TABLE sound_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own sound preferences" ON sound_preferences;
CREATE POLICY "Users can view their own sound preferences" ON sound_preferences
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own sound preferences" ON sound_preferences;
CREATE POLICY "Users can insert their own sound preferences" ON sound_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own sound preferences" ON sound_preferences;
CREATE POLICY "Users can update their own sound preferences" ON sound_preferences
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own sound preferences" ON sound_preferences;
CREATE POLICY "Users can delete their own sound preferences" ON sound_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_sound_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS sound_preferences_updated_at ON sound_preferences;
CREATE TRIGGER sound_preferences_updated_at
    BEFORE UPDATE ON sound_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_sound_preferences_updated_at();

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '093_sound_preferences',
    NOW(),
    'Added customizable sound preferences for countdown and completion (no applause option)'
) ON CONFLICT DO NOTHING;

COMMENT ON TABLE sound_preferences IS 'User preferences for workout sounds - countdown beeps, completion chimes (no applause)';
