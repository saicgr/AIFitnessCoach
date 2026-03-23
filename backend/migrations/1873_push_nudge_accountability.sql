-- Migration 1873: Push Nudge Accountability System
-- Date: 2026-03-22
-- Purpose: Creates push_nudge_log table for deduplication of daily accountability
--          push notifications, and extends notification_preferences JSONB with
--          new accountability coach fields.
--
-- Tables created:
--   push_nudge_log — Tracks which nudge types were sent to which users on which day.
--                    The UNIQUE index on (user_id, nudge_type, nudge_date) provides
--                    atomic dedup: INSERT ... ON CONFLICT DO NOTHING guarantees each
--                    nudge fires at most once per user per local calendar day.
--
-- Tables modified:
--   users — notification_preferences JSONB extended with new accountability fields

-- ============================================================================
-- 1. Create push_nudge_log table
-- ============================================================================

CREATE TABLE IF NOT EXISTS push_nudge_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nudge_type VARCHAR(50) NOT NULL,       -- e.g. 'morning_workout', 'meal_breakfast', 'guilt_day3'
    nudge_date DATE NOT NULL,              -- User's LOCAL date (for same-day dedup)
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    chat_message_id UUID,                  -- Links to the chat_messages entry (if saved)
    metadata JSONB DEFAULT '{}'            -- Extra context: workout_name, streak, etc.
);

-- EDGE CASE: Atomic dedup — INSERT ... ON CONFLICT DO NOTHING prevents duplicate nudges
-- within the same user + type + local date. This handles cron retries, double-fires, etc.
CREATE UNIQUE INDEX IF NOT EXISTS idx_push_nudge_dedup
    ON push_nudge_log(user_id, nudge_type, nudge_date);

-- For querying a user's recent nudge history (daily cap check, analytics)
CREATE INDEX IF NOT EXISTS idx_push_nudge_user
    ON push_nudge_log(user_id, sent_at DESC);

-- For cleanup/archival queries by date
CREATE INDEX IF NOT EXISTS idx_push_nudge_date
    ON push_nudge_log(nudge_date);

-- ============================================================================
-- 2. RLS policies for push_nudge_log
-- ============================================================================

ALTER TABLE push_nudge_log ENABLE ROW LEVEL SECURITY;

-- Service role can do everything (used by backend cron)
CREATE POLICY push_nudge_log_service_all ON push_nudge_log
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Users can read their own nudge history (for settings UI / analytics)
CREATE POLICY push_nudge_log_user_select ON push_nudge_log
    FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================================================
-- 3. Extend notification_preferences JSONB with accountability fields
-- ============================================================================
-- EDGE CASE: Only update users who don't already have these fields
-- (idempotent — safe to run multiple times)

UPDATE users SET notification_preferences = notification_preferences || '{
  "missed_workout_nudge": true,
  "missed_workout_time": "19:00",
  "post_workout_meal_reminder": true,
  "post_workout_meal_delay_minutes": 30,
  "habit_reminders": true,
  "habit_reminder_time": "20:00",
  "weekly_checkin_reminder": true,
  "weekly_checkin_day": 0,
  "weekly_checkin_time": "09:00",
  "streak_celebration": true,
  "milestone_celebration": true,
  "daily_nudge_limit": 4,
  "accountability_intensity": "balanced",
  "ai_personalized_nudges": true,
  "guilt_notifications": true
}'::jsonb
WHERE notification_preferences IS NOT NULL
  AND notification_preferences->>'missed_workout_nudge' IS NULL;

-- EDGE CASE: Users with NULL notification_preferences get the full default set
UPDATE users SET notification_preferences = '{
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
  "weekly_summary_time": "09:00",
  "missed_workout_nudge": true,
  "missed_workout_time": "19:00",
  "post_workout_meal_reminder": true,
  "post_workout_meal_delay_minutes": 30,
  "habit_reminders": true,
  "habit_reminder_time": "20:00",
  "weekly_checkin_reminder": true,
  "weekly_checkin_day": 0,
  "weekly_checkin_time": "09:00",
  "streak_celebration": true,
  "milestone_celebration": true,
  "daily_nudge_limit": 4,
  "accountability_intensity": "balanced",
  "ai_personalized_nudges": true,
  "guilt_notifications": true
}'::jsonb
WHERE notification_preferences IS NULL;
