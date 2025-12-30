-- ============================================================================
-- Migration 073: Fix remaining SECURITY DEFINER views
-- ============================================================================
-- This migration fixes views flagged by Supabase linter with SECURITY DEFINER.
-- Views should use SECURITY INVOKER to respect the caller's RLS policies.
--
-- Views to fix (from linter):
-- 1. today_mood_checkin
-- 2. user_activity_time_patterns
-- 3. mood_workout_correlation
-- 4. active_fasts
-- 5. user_daily_activity_summary
-- 6. today_readiness
-- 7. latest_strength_scores
-- 8. recent_mood_patterns
-- 9. fasting_stats
-- ============================================================================

-- Fix today_mood_checkin view
-- mood_checkins table uses: check_in_time (not checkin_date)
DROP VIEW IF EXISTS today_mood_checkin;
CREATE VIEW today_mood_checkin
WITH (security_invoker = true)
AS
SELECT DISTINCT ON (user_id)
    id,
    user_id,
    mood,
    check_in_time,
    workout_generated,
    workout_id,
    workout_completed
FROM mood_checkins
WHERE check_in_time::date = CURRENT_DATE
ORDER BY user_id, check_in_time DESC;

COMMENT ON VIEW today_mood_checkin IS 'Today mood checkin - uses SECURITY INVOKER';

-- Fix user_activity_time_patterns view
-- user_activity_log table uses: action (not activity_type)
DROP VIEW IF EXISTS user_activity_time_patterns;
CREATE VIEW user_activity_time_patterns
WITH (security_invoker = true)
AS
SELECT
    user_id,
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    EXTRACT(DOW FROM created_at) as day_of_week,
    COUNT(*) as activity_count,
    action as activity_type
FROM user_activity_log
GROUP BY user_id, EXTRACT(HOUR FROM created_at), EXTRACT(DOW FROM created_at), action;

COMMENT ON VIEW user_activity_time_patterns IS 'User activity time patterns - uses SECURITY INVOKER';

-- Fix mood_workout_correlation view
-- mood_checkins uses: check_in_time, mood (not mood_score/energy_level/stress_level)
DROP VIEW IF EXISTS mood_workout_correlation;
CREATE VIEW mood_workout_correlation
WITH (security_invoker = true)
AS
SELECT
    mc.user_id,
    mc.check_in_time,
    mc.mood,
    mc.workout_generated,
    w.id as workout_id,
    w.is_completed,
    w.scheduled_date
FROM mood_checkins mc
LEFT JOIN workouts w ON mc.user_id = w.user_id
    AND mc.check_in_time::date = w.scheduled_date;

COMMENT ON VIEW mood_workout_correlation IS 'Mood workout correlation - uses SECURITY INVOKER';

-- Fix active_fasts view
-- fasting_records uses: status = 'active' (not end_time IS NULL and is_active = true)
DROP VIEW IF EXISTS active_fasts;
CREATE VIEW active_fasts
WITH (security_invoker = true)
AS
SELECT *
FROM fasting_records
WHERE status = 'active';

COMMENT ON VIEW active_fasts IS 'Active fasting sessions - uses SECURITY INVOKER';

-- Fix user_daily_activity_summary view
-- user_activity_log uses: action (not activity_type)
DROP VIEW IF EXISTS user_daily_activity_summary;
CREATE VIEW user_daily_activity_summary
WITH (security_invoker = true)
AS
SELECT
    user_id,
    DATE(created_at) as activity_date,
    COUNT(*) as total_activities,
    COUNT(DISTINCT action) as unique_activity_types
FROM user_activity_log
GROUP BY user_id, DATE(created_at);

COMMENT ON VIEW user_daily_activity_summary IS 'User daily activity summary - uses SECURITY INVOKER';

-- Fix today_readiness view
DROP VIEW IF EXISTS today_readiness;
CREATE VIEW today_readiness
WITH (security_invoker = true)
AS
SELECT *
FROM readiness_scores
WHERE score_date = CURRENT_DATE;

COMMENT ON VIEW today_readiness IS 'Today readiness scores - uses SECURITY INVOKER';

-- Fix latest_strength_scores view
DROP VIEW IF EXISTS latest_strength_scores;
CREATE VIEW latest_strength_scores
WITH (security_invoker = true)
AS
SELECT DISTINCT ON (user_id, muscle_group)
    id,
    user_id,
    muscle_group,
    strength_score,
    strength_level,
    best_exercise_name,
    best_estimated_1rm_kg,
    bodyweight_ratio,
    weekly_sets,
    weekly_volume_kg,
    previous_score,
    score_change,
    trend,
    calculated_at,
    period_start,
    period_end
FROM strength_scores
ORDER BY user_id, muscle_group, calculated_at DESC;

COMMENT ON VIEW latest_strength_scores IS 'Latest strength scores per muscle group - uses SECURITY INVOKER';

-- Fix recent_mood_patterns view
-- mood_checkins uses: check_in_time, mood (not mood_score/energy_level/stress_level)
DROP VIEW IF EXISTS recent_mood_patterns;
CREATE VIEW recent_mood_patterns
WITH (security_invoker = true)
AS
SELECT
    user_id,
    mood,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE workout_completed) as completed_count,
    ROUND(COUNT(*) FILTER (WHERE workout_completed)::numeric / NULLIF(COUNT(*), 0) * 100, 1) as completion_rate
FROM mood_checkins
WHERE check_in_time >= NOW() - INTERVAL '7 days'
GROUP BY user_id, mood;

COMMENT ON VIEW recent_mood_patterns IS 'Recent mood patterns (7 days) - uses SECURITY INVOKER';

-- Fix fasting_stats view
-- fasting_records uses: status = 'completed' (not is_completed), actual_duration_minutes
DROP VIEW IF EXISTS fasting_stats;
CREATE VIEW fasting_stats
WITH (security_invoker = true)
AS
SELECT
    user_id,
    COUNT(*) as total_fasts,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_fasts,
    AVG(actual_duration_minutes) / 60.0 as avg_fast_hours,
    MAX(actual_duration_minutes) / 60.0 as longest_fast_hours,
    ROUND(COUNT(*) FILTER (WHERE status = 'completed')::numeric / NULLIF(COUNT(*), 0) * 100, 1) as completion_rate
FROM fasting_records
GROUP BY user_id;

COMMENT ON VIEW fasting_stats IS 'Fasting statistics per user - uses SECURITY INVOKER';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT SELECT ON today_mood_checkin TO authenticated;
GRANT SELECT ON user_activity_time_patterns TO authenticated;
GRANT SELECT ON mood_workout_correlation TO authenticated;
GRANT SELECT ON active_fasts TO authenticated;
GRANT SELECT ON user_daily_activity_summary TO authenticated;
GRANT SELECT ON today_readiness TO authenticated;
GRANT SELECT ON latest_strength_scores TO authenticated;
GRANT SELECT ON recent_mood_patterns TO authenticated;
GRANT SELECT ON fasting_stats TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
