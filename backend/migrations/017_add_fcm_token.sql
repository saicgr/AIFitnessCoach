-- Migration: Add FCM token for push notifications
-- This adds the Firebase Cloud Messaging token column to the users table

-- Add fcm_token column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add notification preferences column (JSONB for flexibility)
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
  "workout_reminders": true,
  "nutrition_reminders": true,
  "hydration_reminders": true,
  "ai_coach_messages": true,
  "streak_alerts": true,
  "weekly_summary": true,
  "quiet_hours_start": "22:00",
  "quiet_hours_end": "08:00"
}';

-- Add device platform column (android/ios)
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_platform VARCHAR;

-- Create index on fcm_token for efficient lookups when sending bulk notifications
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token) WHERE fcm_token IS NOT NULL;

COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging token for push notifications';
COMMENT ON COLUMN users.notification_preferences IS 'User notification preferences (workout reminders, nutrition, hydration, etc.)';
COMMENT ON COLUMN users.device_platform IS 'Device platform (android or ios)';
