-- Migration: Add FCM token for push notifications
-- This adds the Firebase Cloud Messaging token column to the users table

-- Add fcm_token column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add notification preferences column (JSONB for flexibility)
-- Includes both toggle settings and scheduled notification times
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
  "workout_reminders": true,
  "nutrition_reminders": true,
  "hydration_reminders": true,
  "ai_coach_messages": true,
  "streak_alerts": true,
  "weekly_summary": true,
  "quiet_hours_start": "22:00",
  "quiet_hours_end": "08:00",
  "workout_reminder_time": "08:00",
  "nutrition_breakfast_time": "08:00",
  "nutrition_lunch_time": "12:00",
  "nutrition_dinner_time": "18:00",
  "hydration_start_time": "08:00",
  "hydration_end_time": "20:00",
  "hydration_interval_minutes": 120,
  "streak_alert_time": "18:00",
  "weekly_summary_day": 0,
  "weekly_summary_time": "09:00"
}';

-- Add device platform column (android/ios)
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_platform VARCHAR;

-- Create index on fcm_token for efficient lookups when sending bulk notifications
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token) WHERE fcm_token IS NOT NULL;

COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging token for push notifications';
COMMENT ON COLUMN users.notification_preferences IS 'User notification preferences including toggle settings and scheduled notification times';
COMMENT ON COLUMN users.device_platform IS 'Device platform (android or ios)';
