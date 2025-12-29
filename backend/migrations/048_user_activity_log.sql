-- =============================================
-- Migration: User Activity Log for Debugging
-- =============================================
--
-- Purpose: Track user activity and errors for debugging specific users.
-- When a user reports an issue, we can query their recent activity.
--
-- Usage:
--   SELECT * FROM user_activity_log WHERE user_id = 'abc123' ORDER BY created_at DESC LIMIT 50;
--   SELECT * FROM user_activity_log WHERE level = 'ERROR' AND created_at > NOW() - INTERVAL '1 hour';
--
-- Auto-cleanup: Logs older than 7 days are automatically deleted.
-- =============================================

-- Create user_activity_log table
CREATE TABLE IF NOT EXISTS user_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    request_id TEXT,
    level TEXT NOT NULL DEFAULT 'INFO',  -- INFO, WARNING, ERROR
    action TEXT NOT NULL,                 -- e.g., 'workout_generation', 'chat_message', 'onboarding'
    endpoint TEXT,                        -- e.g., '/api/v1/chat/send'
    message TEXT,                         -- Human-readable description
    metadata JSONB DEFAULT '{}',          -- Additional context (request params, error details)
    duration_ms INTEGER,                  -- Request duration in milliseconds
    status_code INTEGER,                  -- HTTP status code
    error_type TEXT,                      -- Exception class name if error
    error_message TEXT,                   -- Error message if error
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for querying by user
CREATE INDEX IF NOT EXISTS idx_user_activity_log_user_id ON user_activity_log(user_id);

-- Index for querying by time (for cleanup and recent activity)
CREATE INDEX IF NOT EXISTS idx_user_activity_log_created_at ON user_activity_log(created_at DESC);

-- Index for finding errors
CREATE INDEX IF NOT EXISTS idx_user_activity_log_level ON user_activity_log(level) WHERE level = 'ERROR';

-- Index for querying by request_id (to trace a single request)
CREATE INDEX IF NOT EXISTS idx_user_activity_log_request_id ON user_activity_log(request_id);

-- Composite index for common query: user's recent errors
CREATE INDEX IF NOT EXISTS idx_user_activity_log_user_errors
    ON user_activity_log(user_id, created_at DESC)
    WHERE level = 'ERROR';

-- Enable RLS
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can do everything
CREATE POLICY "service_role_all_user_activity_log"
    ON user_activity_log
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Users can only view their own activity logs
CREATE POLICY "users_view_own_activity_log"
    ON user_activity_log
    FOR SELECT
    TO authenticated
    USING (auth.uid()::TEXT = user_id);

-- Function to auto-cleanup old logs (keep 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_activity_logs()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM user_activity_log
    WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$;

-- Create a cron job to cleanup old logs daily (requires pg_cron extension)
-- This will silently fail if pg_cron is not available
DO $$
BEGIN
    PERFORM cron.schedule(
        'cleanup-activity-logs',
        '0 3 * * *',  -- Run at 3 AM daily
        'SELECT cleanup_old_activity_logs()'
    );
EXCEPTION
    WHEN undefined_function THEN
        -- pg_cron not available, skip
        RAISE NOTICE 'pg_cron not available, skipping cron job creation';
END;
$$;

-- =============================================
-- Helper Views for Debugging
-- =============================================

-- View: Recent errors (last 24 hours)
CREATE OR REPLACE VIEW recent_errors AS
SELECT
    user_id,
    request_id,
    action,
    endpoint,
    error_type,
    error_message,
    metadata,
    created_at
FROM user_activity_log
WHERE level = 'ERROR'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- View: User activity summary (for quick overview)
CREATE OR REPLACE VIEW user_activity_summary AS
SELECT
    user_id,
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE level = 'ERROR') as error_count,
    COUNT(DISTINCT action) as unique_actions,
    MIN(created_at) as first_activity,
    MAX(created_at) as last_activity,
    AVG(duration_ms) as avg_duration_ms
FROM user_activity_log
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY user_id
ORDER BY error_count DESC, total_requests DESC;

-- Grant access to views
GRANT SELECT ON recent_errors TO service_role;
GRANT SELECT ON user_activity_summary TO service_role;

-- =============================================
-- Comments
-- =============================================

COMMENT ON TABLE user_activity_log IS 'Tracks user activity and errors for debugging. Auto-cleaned after 7 days.';
COMMENT ON COLUMN user_activity_log.request_id IS 'Unique ID to trace a single request through logs';
COMMENT ON COLUMN user_activity_log.action IS 'High-level action category (e.g., workout_generation, chat)';
COMMENT ON COLUMN user_activity_log.metadata IS 'Additional context as JSON (request params, error stack, etc.)';
