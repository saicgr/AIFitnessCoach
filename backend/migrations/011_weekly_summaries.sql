-- Migration: Weekly Summary Notifications
-- Created: 2025-12-02
-- Purpose: Store AI-generated weekly summaries and notification preferences

-- ============================================
-- weekly_summaries - AI-generated workout summaries
-- ============================================
CREATE TABLE IF NOT EXISTS weekly_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,

    -- Stats for the week
    workouts_completed INTEGER DEFAULT 0,
    workouts_scheduled INTEGER DEFAULT 0,
    total_exercises INTEGER DEFAULT 0,
    total_sets INTEGER DEFAULT 0,
    total_time_minutes INTEGER DEFAULT 0,
    calories_burned_estimate INTEGER DEFAULT 0,

    -- Streak info
    current_streak INTEGER DEFAULT 0,
    streak_status VARCHAR(20),  -- 'growing', 'maintained', 'broken'

    -- PRs achieved this week
    prs_achieved INTEGER DEFAULT 0,
    pr_details JSONB,  -- Array of {exercise_name, old_value, new_value, unit}

    -- AI-generated content
    ai_summary TEXT,  -- Main summary paragraph
    ai_highlights JSONB,  -- Array of highlight strings
    ai_encouragement TEXT,  -- Motivational message
    ai_next_week_tips JSONB,  -- Array of tip strings for next week
    ai_generated_at TIMESTAMP WITH TIME ZONE,

    -- Notification status
    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMP WITH TIME ZONE,
    push_sent BOOLEAN DEFAULT false,
    push_sent_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, week_start)
);

COMMENT ON TABLE weekly_summaries IS 'Stores AI-generated weekly workout summaries';
COMMENT ON COLUMN weekly_summaries.ai_summary IS 'AI-generated summary paragraph for the week';
COMMENT ON COLUMN weekly_summaries.ai_encouragement IS 'Personalized motivational message from AI';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_weekly_summaries_user_id ON weekly_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_summaries_week_start ON weekly_summaries(week_start DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_summaries_email_sent ON weekly_summaries(email_sent);

-- Enable Row Level Security
ALTER TABLE weekly_summaries ENABLE ROW LEVEL SECURITY;

-- Users can only see their own summaries
DROP POLICY IF EXISTS weekly_summaries_select_policy ON weekly_summaries;
CREATE POLICY weekly_summaries_select_policy ON weekly_summaries
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS weekly_summaries_service_policy ON weekly_summaries;
CREATE POLICY weekly_summaries_service_policy ON weekly_summaries
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- notification_preferences - User notification settings
-- ============================================
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    -- Weekly summary settings
    weekly_summary_enabled BOOLEAN DEFAULT true,
    weekly_summary_day VARCHAR(10) DEFAULT 'sunday',  -- Day to send summary
    weekly_summary_time TIME DEFAULT '09:00',  -- Time to send (user's local time)

    -- Email notifications
    email_notifications_enabled BOOLEAN DEFAULT true,
    email_workout_reminders BOOLEAN DEFAULT true,
    email_achievement_alerts BOOLEAN DEFAULT true,
    email_weekly_summary BOOLEAN DEFAULT true,
    email_motivation_messages BOOLEAN DEFAULT false,

    -- Push notifications
    push_notifications_enabled BOOLEAN DEFAULT false,
    push_workout_reminders BOOLEAN DEFAULT true,
    push_achievement_alerts BOOLEAN DEFAULT true,
    push_weekly_summary BOOLEAN DEFAULT false,
    push_hydration_reminders BOOLEAN DEFAULT false,

    -- Timing preferences
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '07:00',
    timezone VARCHAR(50) DEFAULT 'America/New_York',

    -- Push tokens (for mobile)
    push_token TEXT,
    push_token_updated_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE notification_preferences IS 'User preferences for notifications';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- Enable Row Level Security
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only see their own preferences
DROP POLICY IF EXISTS notification_preferences_select_policy ON notification_preferences;
CREATE POLICY notification_preferences_select_policy ON notification_preferences
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own preferences
DROP POLICY IF EXISTS notification_preferences_update_policy ON notification_preferences;
CREATE POLICY notification_preferences_update_policy ON notification_preferences
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can insert their own preferences
DROP POLICY IF EXISTS notification_preferences_insert_policy ON notification_preferences;
CREATE POLICY notification_preferences_insert_policy ON notification_preferences
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS notification_preferences_service_policy ON notification_preferences;
CREATE POLICY notification_preferences_service_policy ON notification_preferences
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- notification_queue - Queue for pending notifications
-- ============================================
CREATE TABLE IF NOT EXISTS notification_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,  -- 'weekly_summary', 'achievement', 'reminder', 'motivation'
    channel VARCHAR(20) NOT NULL,  -- 'email', 'push'
    priority INTEGER DEFAULT 5,  -- 1-10, lower is higher priority

    -- Content
    subject TEXT,
    body TEXT NOT NULL,
    data JSONB,  -- Additional data for the notification

    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Status
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'sent', 'failed', 'cancelled'
    attempts INTEGER DEFAULT 0,
    last_attempt_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE notification_queue IS 'Queue for pending notifications to be sent';

-- Indexes for efficient queue processing
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled ON notification_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_notification_queue_user_id ON notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_queue_pending ON notification_queue(status, scheduled_for)
    WHERE status = 'pending';

-- Enable Row Level Security
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;

-- Only service role can manage queue
DROP POLICY IF EXISTS notification_queue_service_policy ON notification_queue;
CREATE POLICY notification_queue_service_policy ON notification_queue
    FOR ALL
    USING (auth.role() = 'service_role');
