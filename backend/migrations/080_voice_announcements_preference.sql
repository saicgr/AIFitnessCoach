-- Voice Announcements Preference Migration
-- Adds voice_announcements_enabled to the notification_preferences JSONB column in users table
-- This preference controls TTS announcements during workouts

-- The voice_announcements_enabled preference is stored within the notification_preferences JSONB column
-- which already exists in the users table. No schema change is needed.

-- This migration serves as documentation that voice_announcements_enabled is now a valid key
-- within notification_preferences JSONB with the following structure:
-- {
--   "voice_announcements_enabled": true/false,
--   ... other notification preferences ...
-- }

-- Default value for new users is false (voice announcements disabled by default)

-- Update existing users to have voice_announcements_enabled set to false if notification_preferences exists
UPDATE users
SET notification_preferences =
    CASE
        WHEN notification_preferences IS NULL THEN '{"voice_announcements_enabled": false}'::jsonb
        WHEN notification_preferences ? 'voice_announcements_enabled' THEN notification_preferences
        ELSE notification_preferences || '{"voice_announcements_enabled": false}'::jsonb
    END
WHERE notification_preferences IS NULL
   OR NOT (notification_preferences ? 'voice_announcements_enabled');

-- Add a comment to the column documenting the new field
COMMENT ON COLUMN users.notification_preferences IS 'JSONB containing notification preferences including: voice_announcements_enabled (bool) - controls TTS during workouts';
