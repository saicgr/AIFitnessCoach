-- Migration: 059_user_context_logs.sql
-- Description: Add user context logging table for tracking interactions and AI personalization
-- Created: 2024-12-30

-- ============================================================================
-- USER CONTEXT LOGS TABLE
-- ============================================================================
-- General-purpose event logging for user interactions
-- Used for analytics, AI personalization, and improving recommendations

CREATE TABLE IF NOT EXISTS user_context_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Event classification
    event_type VARCHAR(50) NOT NULL,
    -- Types: mood_checkin, workout_start, workout_complete, score_view,
    --        nutrition_log, feature_interaction, screen_view, error

    -- Event-specific data (structure varies by event_type)
    event_data JSONB NOT NULL DEFAULT '{}',

    -- Contextual information about when/how the event occurred
    context JSONB DEFAULT '{}',
    -- Common context fields:
    --   time_of_day: morning/afternoon/evening/night
    --   day_of_week: monday/tuesday/...
    --   device: ios/android
    --   app_version: "1.2.0"
    --   screen_name: current screen
    --   session_id: unique session identifier

    -- Timestamp when event occurred
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_context_logs_user ON user_context_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_context_logs_user_date ON user_context_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_context_logs_type ON user_context_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_user_context_logs_type_date ON user_context_logs(event_type, created_at DESC);

-- GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_user_context_logs_event_data ON user_context_logs USING GIN (event_data);
CREATE INDEX IF NOT EXISTS idx_user_context_logs_context ON user_context_logs USING GIN (context);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE user_context_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own logs
DROP POLICY IF EXISTS user_context_logs_select_policy ON user_context_logs;
CREATE POLICY user_context_logs_select_policy ON user_context_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own logs
DROP POLICY IF EXISTS user_context_logs_insert_policy ON user_context_logs;
CREATE POLICY user_context_logs_insert_policy ON user_context_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Service role can do everything
DROP POLICY IF EXISTS user_context_logs_service_policy ON user_context_logs;
CREATE POLICY user_context_logs_service_policy ON user_context_logs
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- Daily event summary per user (for dashboards)
CREATE OR REPLACE VIEW user_daily_activity_summary AS
SELECT
    user_id,
    created_at::date as activity_date,
    COUNT(*) as total_events,
    COUNT(*) FILTER (WHERE event_type = 'mood_checkin') as mood_checkins,
    COUNT(*) FILTER (WHERE event_type = 'workout_start') as workouts_started,
    COUNT(*) FILTER (WHERE event_type = 'workout_complete') as workouts_completed,
    COUNT(*) FILTER (WHERE event_type = 'nutrition_log') as nutrition_logs,
    COUNT(*) FILTER (WHERE event_type = 'score_view') as score_views
FROM user_context_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY user_id, created_at::date;

-- Mood patterns analysis
CREATE OR REPLACE VIEW mood_workout_correlation AS
SELECT
    user_id,
    event_data->>'mood' as mood,
    COUNT(*) as total_checkins,
    COUNT(*) FILTER (WHERE event_data->>'workout_generated' = 'true') as workouts_generated,
    COUNT(*) FILTER (WHERE event_data->>'workout_completed' = 'true') as workouts_completed,
    ROUND(
        COUNT(*) FILTER (WHERE event_data->>'workout_completed' = 'true')::numeric /
        NULLIF(COUNT(*) FILTER (WHERE event_data->>'workout_generated' = 'true'), 0) * 100,
        1
    ) as completion_rate
FROM user_context_logs
WHERE event_type = 'mood_checkin'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY user_id, event_data->>'mood';

-- Time-of-day activity patterns
CREATE OR REPLACE VIEW user_activity_time_patterns AS
SELECT
    user_id,
    context->>'time_of_day' as time_of_day,
    event_type,
    COUNT(*) as event_count
FROM user_context_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
  AND context->>'time_of_day' IS NOT NULL
GROUP BY user_id, context->>'time_of_day', event_type;

-- Grant permissions on views
GRANT SELECT ON user_daily_activity_summary TO authenticated;
GRANT SELECT ON mood_workout_correlation TO authenticated;
GRANT SELECT ON user_activity_time_patterns TO authenticated;

-- ============================================================================
-- CLEANUP FUNCTION (optional - for data retention)
-- ============================================================================

-- Function to clean up old logs (keep last 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_context_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_context_logs
    WHERE created_at < NOW() - INTERVAL '90 days';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE user_context_logs IS 'General-purpose event logging for user interactions and AI personalization';
COMMENT ON COLUMN user_context_logs.event_type IS 'Type of event: mood_checkin, workout_start, workout_complete, score_view, nutrition_log, feature_interaction, screen_view, error';
COMMENT ON COLUMN user_context_logs.event_data IS 'Event-specific data as JSON (structure varies by event_type)';
COMMENT ON COLUMN user_context_logs.context IS 'Contextual information: time_of_day, day_of_week, device, app_version, session_id';
COMMENT ON VIEW user_daily_activity_summary IS 'Daily aggregated activity counts per user';
COMMENT ON VIEW mood_workout_correlation IS 'Correlation between mood selections and workout completion rates';
COMMENT ON VIEW user_activity_time_patterns IS 'User activity patterns by time of day';
COMMENT ON FUNCTION cleanup_old_context_logs IS 'Removes context logs older than 90 days for data retention';
