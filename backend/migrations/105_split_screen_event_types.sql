-- ============================================================================
-- Migration 105: Split Screen Usage Event Types
-- ============================================================================
-- This migration documents the new split screen event types added to
-- user_context_logs and creates a view for analyzing split screen usage.
--
-- New Event Types (logged to user_context_logs):
--   - split_screen_entered: User entered split screen mode
--   - split_screen_exited: User exited split screen mode
--
-- Event Data Structure for split_screen_entered:
--   {
--     "device_type": "phone" | "tablet" | "foldable" | "desktop",
--     "screen_width": 1080,
--     "screen_height": 2400,
--     "app_width": 540,
--     "app_height": 2400,
--     "split_ratio": 0.5,
--     "partner_app": "YouTube" | null,
--     "current_screen": "active_workout",
--     "entered_at": "2024-12-30T10:00:00Z"
--   }
--
-- Event Data Structure for split_screen_exited:
--   {
--     "duration_seconds": 300,
--     "duration_minutes": 5.0,
--     "device_type": "tablet",
--     "screens_viewed": ["home", "active_workout", "workout_complete"],
--     "screens_count": 3,
--     "features_used": ["workout_timer", "exercise_video"],
--     "features_count": 2,
--     "workout_active_during_split": true,
--     "partner_app": "YouTube" | null,
--     "exit_reason": "user_action" | "app_closed" | "partner_closed",
--     "exited_at": "2024-12-30T10:05:00Z"
--   }
-- ============================================================================

-- ============================================================================
-- Create view for split screen analytics
-- ============================================================================

CREATE OR REPLACE VIEW public.split_screen_usage_analytics
WITH (security_invoker = true)
AS
WITH entered_events AS (
    SELECT
        user_id,
        event_data->>'device_type' AS device_type,
        (event_data->>'screen_width')::int AS screen_width,
        (event_data->>'screen_height')::int AS screen_height,
        (event_data->>'app_width')::int AS app_width,
        (event_data->>'app_height')::int AS app_height,
        (event_data->>'split_ratio')::float AS split_ratio,
        event_data->>'partner_app' AS partner_app,
        event_data->>'current_screen' AS entry_screen,
        created_at AS entered_at
    FROM user_context_logs
    WHERE event_type = 'split_screen_entered'
),
exited_events AS (
    SELECT
        user_id,
        (event_data->>'duration_seconds')::int AS duration_seconds,
        event_data->>'device_type' AS device_type,
        event_data->'screens_viewed' AS screens_viewed,
        (event_data->>'screens_count')::int AS screens_count,
        event_data->'features_used' AS features_used,
        (event_data->>'features_count')::int AS features_count,
        (event_data->>'workout_active_during_split')::boolean AS workout_active,
        event_data->>'partner_app' AS partner_app,
        event_data->>'exit_reason' AS exit_reason,
        created_at AS exited_at
    FROM user_context_logs
    WHERE event_type = 'split_screen_exited'
)
SELECT
    e.user_id,
    DATE_TRUNC('day', e.entered_at) AS usage_date,
    e.device_type,
    e.split_ratio,
    e.entry_screen,
    x.duration_seconds,
    x.screens_count,
    x.features_count,
    x.workout_active,
    x.exit_reason,
    e.entered_at,
    x.exited_at
FROM entered_events e
LEFT JOIN exited_events x ON e.user_id = x.user_id
    AND x.exited_at > e.entered_at
    AND x.exited_at < e.entered_at + INTERVAL '4 hours';

COMMENT ON VIEW public.split_screen_usage_analytics IS 'Split screen usage analytics combining enter and exit events';

-- ============================================================================
-- Create summary view for aggregate split screen statistics
-- ============================================================================

CREATE OR REPLACE VIEW public.split_screen_summary
WITH (security_invoker = true)
AS
SELECT
    user_id,
    COUNT(*) FILTER (WHERE event_type = 'split_screen_entered') AS total_sessions,
    COALESCE(SUM((event_data->>'duration_seconds')::int) FILTER (WHERE event_type = 'split_screen_exited'), 0) AS total_duration_seconds,
    ROUND(AVG((event_data->>'duration_seconds')::int) FILTER (WHERE event_type = 'split_screen_exited'), 1) AS avg_duration_seconds,
    COUNT(DISTINCT event_data->>'device_type') AS unique_device_types,
    MODE() WITHIN GROUP (ORDER BY event_data->>'device_type') AS primary_device_type,
    COUNT(*) FILTER (WHERE event_type = 'split_screen_exited' AND (event_data->>'workout_active_during_split')::boolean = true) AS sessions_with_workout,
    MAX(created_at) AS last_split_screen_usage
FROM user_context_logs
WHERE event_type IN ('split_screen_entered', 'split_screen_exited')
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY user_id;

COMMENT ON VIEW public.split_screen_summary IS 'Aggregated split screen usage summary per user (last 30 days)';

-- ============================================================================
-- Grant permissions
-- ============================================================================

GRANT SELECT ON public.split_screen_usage_analytics TO authenticated;
GRANT SELECT ON public.split_screen_summary TO authenticated;

-- ============================================================================
-- Update comments on user_context_logs for documentation
-- ============================================================================

COMMENT ON TABLE public.user_context_logs IS 'General-purpose event logging for user interactions and AI personalization. Includes split_screen_entered and split_screen_exited event types.';

-- ============================================================================
-- Migration complete
-- ============================================================================
