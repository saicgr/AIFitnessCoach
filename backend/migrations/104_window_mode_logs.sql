-- ============================================================================
-- Migration 104: Window Mode Logging
-- ============================================================================
-- This migration creates tables for tracking window mode changes on mobile devices.
-- Used to understand how users interact with split screen, PiP, and freeform modes.
--
-- Tables:
--   - window_mode_logs: Records each window mode change with dimensions
--
-- Features:
--   - Tracks split screen, full screen, PiP, and freeform modes
--   - Records window dimensions for UI optimization analytics
--   - Supports session duration tracking for split screen usage
--   - RLS enabled for user data privacy
-- ============================================================================

-- ============================================================================
-- Create window_mode_logs table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.window_mode_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mode TEXT NOT NULL CHECK (mode IN ('split_screen', 'full_screen', 'pip', 'freeform', 'split_screen_session')),
    window_width INT CHECK (window_width >= 0 AND window_width <= 10000),
    window_height INT CHECK (window_height >= 0 AND window_height <= 10000),
    duration_seconds INT CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    device_info JSONB,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comments for documentation
COMMENT ON TABLE public.window_mode_logs IS 'Tracks window mode changes for mobile app analytics (split screen, PiP, etc.)';
COMMENT ON COLUMN public.window_mode_logs.mode IS 'Window mode: split_screen, full_screen, pip, freeform, or split_screen_session';
COMMENT ON COLUMN public.window_mode_logs.window_width IS 'Window width in logical pixels';
COMMENT ON COLUMN public.window_mode_logs.window_height IS 'Window height in logical pixels';
COMMENT ON COLUMN public.window_mode_logs.duration_seconds IS 'Duration in seconds (for session summary logs)';
COMMENT ON COLUMN public.window_mode_logs.device_info IS 'Optional device information JSON (model, OS version, etc.)';
COMMENT ON COLUMN public.window_mode_logs.logged_at IS 'Timestamp when the mode change was logged';


-- ============================================================================
-- Create indexes for efficient queries
-- ============================================================================

-- Index for user lookups (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_window_mode_logs_user
    ON public.window_mode_logs(user_id);

-- Index for mode-based analytics
CREATE INDEX IF NOT EXISTS idx_window_mode_logs_mode
    ON public.window_mode_logs(mode);

-- Index for time-based queries
CREATE INDEX IF NOT EXISTS idx_window_mode_logs_logged_at
    ON public.window_mode_logs(logged_at DESC);

-- Composite index for user + time queries (common for stats)
CREATE INDEX IF NOT EXISTS idx_window_mode_logs_user_time
    ON public.window_mode_logs(user_id, logged_at DESC);


-- ============================================================================
-- Enable Row Level Security (RLS)
-- ============================================================================

ALTER TABLE public.window_mode_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own window mode logs
CREATE POLICY "Users can view own window mode logs"
    ON public.window_mode_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own window mode logs
CREATE POLICY "Users can insert own window mode logs"
    ON public.window_mode_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Service role can manage all logs
CREATE POLICY "Service role can manage all window mode logs"
    ON public.window_mode_logs
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role')
    WITH CHECK (auth.jwt() ->> 'role' = 'service_role');


-- ============================================================================
-- Grant permissions
-- ============================================================================

-- Grant authenticated users access to the table
GRANT SELECT, INSERT ON public.window_mode_logs TO authenticated;

-- Grant service role full access
GRANT ALL ON public.window_mode_logs TO service_role;


-- ============================================================================
-- Create helper function for window mode statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_window_mode_stats(p_user_id UUID)
RETURNS TABLE (
    total_logs BIGINT,
    split_screen_count BIGINT,
    full_screen_count BIGINT,
    pip_count BIGINT,
    freeform_count BIGINT,
    total_split_screen_seconds BIGINT,
    avg_split_screen_seconds NUMERIC,
    most_common_mode TEXT,
    last_mode_change TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH mode_counts AS (
        SELECT
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE mode = 'split_screen') AS split_screen,
            COUNT(*) FILTER (WHERE mode = 'full_screen') AS full_screen,
            COUNT(*) FILTER (WHERE mode = 'pip') AS pip,
            COUNT(*) FILTER (WHERE mode = 'freeform') AS freeform,
            COALESCE(SUM(duration_seconds) FILTER (WHERE mode = 'split_screen_session'), 0) AS total_split_seconds,
            COALESCE(AVG(duration_seconds) FILTER (WHERE mode = 'split_screen_session'), 0) AS avg_split_seconds,
            MAX(logged_at) AS last_change
        FROM window_mode_logs
        WHERE user_id = p_user_id
    ),
    most_common AS (
        SELECT mode
        FROM window_mode_logs
        WHERE user_id = p_user_id
          AND mode NOT IN ('split_screen_session')
        GROUP BY mode
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )
    SELECT
        mc.total,
        mc.split_screen,
        mc.full_screen,
        mc.pip,
        mc.freeform,
        mc.total_split_seconds,
        ROUND(mc.avg_split_seconds, 1),
        mcm.mode,
        mc.last_change
    FROM mode_counts mc
    LEFT JOIN most_common mcm ON TRUE;
END;
$$;

COMMENT ON FUNCTION public.get_window_mode_stats IS 'Returns window mode usage statistics for a user';


-- ============================================================================
-- Create view for window mode analytics (admin/reporting)
-- ============================================================================

CREATE OR REPLACE VIEW public.window_mode_analytics AS
SELECT
    mode,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS unique_users,
    AVG(window_width) AS avg_width,
    AVG(window_height) AS avg_height,
    AVG(duration_seconds) FILTER (WHERE mode = 'split_screen_session') AS avg_session_duration,
    DATE_TRUNC('day', logged_at) AS log_date
FROM public.window_mode_logs
GROUP BY mode, DATE_TRUNC('day', logged_at)
ORDER BY log_date DESC, mode;

COMMENT ON VIEW public.window_mode_analytics IS 'Aggregated window mode statistics for analytics dashboards';

-- Grant service role access to analytics view
GRANT SELECT ON public.window_mode_analytics TO service_role;


-- ============================================================================
-- Migration complete
-- ============================================================================
