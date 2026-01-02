-- Migration: 091_audio_preferences.sql
-- Description: Audio preferences table for managing audio playback settings during workouts
-- This allows users to control background music integration, TTS volume, and audio ducking behavior

-- ============================================
-- AUDIO PREFERENCES TABLE
-- ============================================

-- Create the audio preferences table
CREATE TABLE IF NOT EXISTS audio_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,

    -- Background music settings
    allow_background_music BOOLEAN DEFAULT true,        -- Allow Spotify/Apple Music to continue playing

    -- TTS (Text-to-Speech) voice announcement settings
    tts_volume DECIMAL(3,2) DEFAULT 0.80 CHECK (tts_volume >= 0 AND tts_volume <= 1),  -- Voice announcement volume (0-1)

    -- Audio ducking settings (lowering music volume during announcements)
    audio_ducking BOOLEAN DEFAULT true,                 -- Enable lowering music volume during TTS announcements
    duck_volume_level DECIMAL(3,2) DEFAULT 0.30 CHECK (duck_volume_level >= 0 AND duck_volume_level <= 1),  -- How much to reduce music volume (0-1)

    -- Video playback settings
    mute_during_video BOOLEAN DEFAULT false,            -- Mute TTS during exercise video playback

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Create index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_audio_preferences_user_id
    ON audio_preferences(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS
ALTER TABLE audio_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own audio preferences
CREATE POLICY "Users can view own audio preferences"
    ON audio_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own audio preferences
CREATE POLICY "Users can insert own audio preferences"
    ON audio_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own audio preferences
CREATE POLICY "Users can update own audio preferences"
    ON audio_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own audio preferences
CREATE POLICY "Users can delete own audio preferences"
    ON audio_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- Policy: Service role has full access (for backend operations)
CREATE POLICY "Service role has full access to audio preferences"
    ON audio_preferences FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- TRIGGER FOR UPDATED_AT
-- ============================================

-- Create or replace trigger function for updated_at
CREATE OR REPLACE FUNCTION update_audio_preferences_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_audio_preferences_updated_at ON audio_preferences;
CREATE TRIGGER trigger_audio_preferences_updated_at
    BEFORE UPDATE ON audio_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_audio_preferences_updated_at();

-- ============================================
-- FUNCTION: UPSERT AUDIO PREFERENCES
-- ============================================

-- Create function to upsert audio preferences (create or update)
CREATE OR REPLACE FUNCTION upsert_audio_preferences(
    p_user_id UUID,
    p_allow_background_music BOOLEAN DEFAULT NULL,
    p_tts_volume DECIMAL DEFAULT NULL,
    p_audio_ducking BOOLEAN DEFAULT NULL,
    p_duck_volume_level DECIMAL DEFAULT NULL,
    p_mute_during_video BOOLEAN DEFAULT NULL
)
RETURNS audio_preferences
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result audio_preferences;
BEGIN
    INSERT INTO audio_preferences (
        user_id,
        allow_background_music,
        tts_volume,
        audio_ducking,
        duck_volume_level,
        mute_during_video
    )
    VALUES (
        p_user_id,
        COALESCE(p_allow_background_music, true),
        COALESCE(p_tts_volume, 0.80),
        COALESCE(p_audio_ducking, true),
        COALESCE(p_duck_volume_level, 0.30),
        COALESCE(p_mute_during_video, false)
    )
    ON CONFLICT (user_id) DO UPDATE SET
        allow_background_music = COALESCE(p_allow_background_music, audio_preferences.allow_background_music),
        tts_volume = COALESCE(p_tts_volume, audio_preferences.tts_volume),
        audio_ducking = COALESCE(p_audio_ducking, audio_preferences.audio_ducking),
        duck_volume_level = COALESCE(p_duck_volume_level, audio_preferences.duck_volume_level),
        mute_during_video = COALESCE(p_mute_during_video, audio_preferences.mute_during_video),
        updated_at = NOW()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: GET AUDIO PREFERENCES WITH DEFAULTS
-- ============================================

-- Function to get audio preferences, returning defaults if none exist
CREATE OR REPLACE FUNCTION get_audio_preferences(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    user_id UUID,
    allow_background_music BOOLEAN,
    tts_volume DECIMAL,
    audio_ducking BOOLEAN,
    duck_volume_level DECIMAL,
    mute_during_video BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(ap.id, gen_random_uuid()),
        p_user_id,
        COALESCE(ap.allow_background_music, true),
        COALESCE(ap.tts_volume, 0.80),
        COALESCE(ap.audio_ducking, true),
        COALESCE(ap.duck_volume_level, 0.30),
        COALESCE(ap.mute_during_video, false),
        COALESCE(ap.created_at, NOW()),
        COALESCE(ap.updated_at, NOW())
    FROM (SELECT 1) AS dummy
    LEFT JOIN audio_preferences ap ON ap.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant usage on functions
GRANT EXECUTE ON FUNCTION upsert_audio_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION get_audio_preferences TO authenticated;

-- ============================================
-- DOCUMENTATION
-- ============================================

-- Add comments for documentation
COMMENT ON TABLE audio_preferences IS 'User audio preferences for controlling playback behavior during workouts including background music, TTS volume, and audio ducking.';
COMMENT ON COLUMN audio_preferences.allow_background_music IS 'When true, allows external music apps (Spotify, Apple Music) to continue playing during workout';
COMMENT ON COLUMN audio_preferences.tts_volume IS 'Volume level for voice announcements (0.0 to 1.0, default 0.8)';
COMMENT ON COLUMN audio_preferences.audio_ducking IS 'When true, lowers background music volume during voice announcements';
COMMENT ON COLUMN audio_preferences.duck_volume_level IS 'How much to reduce background music during announcements (0.0 to 1.0, default 0.3 = 30% of original volume)';
COMMENT ON COLUMN audio_preferences.mute_during_video IS 'When true, mutes voice announcements while exercise demonstration videos are playing';
COMMENT ON FUNCTION upsert_audio_preferences IS 'Creates or updates audio preferences for a user. Pass NULL for any parameter to keep existing value.';
COMMENT ON FUNCTION get_audio_preferences IS 'Returns audio preferences for a user, with sensible defaults if no preferences exist yet.';

-- ============================================
-- Migration complete
-- ============================================
