-- Migration: Leaderboard System
-- Created: 2025-12-24
-- Description: Global and country-based leaderboards with multiple ranking types

-- ============================================================
-- ADD COUNTRY CODE TO USERS
-- ============================================================

-- Add country_code column for region-based leaderboards
ALTER TABLE users
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2);

-- Index for country filtering
CREATE INDEX IF NOT EXISTS idx_users_country_code ON users(country_code);

COMMENT ON COLUMN users.country_code IS 'ISO 3166-1 alpha-2 country code (e.g., US, GB, CA)';

-- ============================================================
-- LEADERBOARD: CHALLENGE MASTERS
-- ============================================================

-- Primary leaderboard: Most challenge victories (first-attempt only, retries excluded)
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard_challenge_masters AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.avatar_url,
    u.country_code,

    -- First-attempt wins only (retries don't count)
    COUNT(*) FILTER (
        WHERE c.did_beat = true
        AND c.is_retry = false
        AND c.status = 'completed'
    ) AS first_wins,

    -- Total challenges completed
    COUNT(*) FILTER (
        WHERE c.status = 'completed'
    ) AS total_completed,

    -- Win rate (percentage)
    ROUND(
        COUNT(*) FILTER (WHERE c.did_beat = true AND c.is_retry = false)::DECIMAL /
        NULLIF(COUNT(*) FILTER (WHERE c.status = 'completed'), 0) * 100,
        1
    ) AS win_rate,

    -- Total challenges received
    COUNT(*) AS total_received,

    -- Timestamp for freshness
    NOW() AS last_updated

FROM users u
LEFT JOIN workout_challenges c ON c.to_user_id = u.id
GROUP BY u.id, u.name, u.avatar_url, u.country_code
HAVING COUNT(*) FILTER (WHERE c.status = 'completed') > 0  -- Only users with completed challenges
ORDER BY first_wins DESC, win_rate DESC, u.created_at ASC;

-- Index for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_masters_user ON leaderboard_challenge_masters(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_masters_country ON leaderboard_challenge_masters(country_code);
CREATE INDEX IF NOT EXISTS idx_leaderboard_masters_rank ON leaderboard_challenge_masters(first_wins DESC, win_rate DESC);

COMMENT ON MATERIALIZED VIEW leaderboard_challenge_masters IS 'Primary leaderboard: Most challenge victories (first-attempt only)';

-- ============================================================
-- LEADERBOARD: VOLUME KINGS
-- ============================================================

-- Secondary leaderboard: Total weight lifted across all workouts
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard_volume_kings AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.avatar_url,
    u.country_code,

    -- Total volume lifted (sum of all workout_logs total_volume)
    COALESCE(SUM((wl.performance_data->>'total_volume')::DECIMAL), 0) AS total_volume_lbs,

    -- Total workouts completed
    COUNT(wl.id) AS total_workouts,

    -- Average volume per workout
    ROUND(
        COALESCE(AVG((wl.performance_data->>'total_volume')::DECIMAL), 0),
        0
    ) AS avg_volume_per_workout,

    -- Timestamp
    NOW() AS last_updated

FROM users u
LEFT JOIN workout_logs wl ON wl.user_id = u.id
WHERE wl.performance_data->>'total_volume' IS NOT NULL
GROUP BY u.id, u.name, u.avatar_url, u.country_code
HAVING COUNT(wl.id) > 0  -- Only users with completed workouts
ORDER BY total_volume_lbs DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_volume_user ON leaderboard_volume_kings(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_volume_country ON leaderboard_volume_kings(country_code);
CREATE INDEX IF NOT EXISTS idx_leaderboard_volume_rank ON leaderboard_volume_kings(total_volume_lbs DESC);

COMMENT ON MATERIALIZED VIEW leaderboard_volume_kings IS 'Leaderboard: Total weight lifted across all workouts';

-- ============================================================
-- LEADERBOARD: WORKOUT STREAKS
-- ============================================================

-- Tertiary leaderboard: Longest workout streaks (consistency)
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard_streaks AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.avatar_url,
    u.country_code,

    -- Current streak (from user_stats or calculate)
    COALESCE((u.stats_data->>'current_streak')::INTEGER, 0) AS current_streak,

    -- Best streak ever
    COALESCE((u.stats_data->>'best_streak')::INTEGER, 0) AS best_streak,

    -- Total workouts
    COUNT(wl.id) AS total_workouts,

    -- Last workout date
    MAX(wl.completed_at) AS last_workout_date,

    -- Timestamp
    NOW() AS last_updated

FROM users u
LEFT JOIN workout_logs wl ON wl.user_id = u.id
GROUP BY u.id, u.name, u.avatar_url, u.country_code, u.stats_data
HAVING COUNT(wl.id) > 0  -- Only users with workouts
ORDER BY best_streak DESC, current_streak DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_streaks_user ON leaderboard_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_streaks_country ON leaderboard_streaks(country_code);
CREATE INDEX IF NOT EXISTS idx_leaderboard_streaks_rank ON leaderboard_streaks(best_streak DESC, current_streak DESC);

COMMENT ON MATERIALIZED VIEW leaderboard_streaks IS 'Leaderboard: Longest workout streaks (consistency)';

-- ============================================================
-- WEEKLY LEADERBOARD (Challenge Masters)
-- ============================================================

-- Weekly reset leaderboard: Challenges won this week
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard_weekly_challenges AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.avatar_url,
    u.country_code,

    -- Wins this week (first-attempt only)
    COUNT(*) FILTER (
        WHERE c.did_beat = true
        AND c.is_retry = false
        AND c.completed_at >= DATE_TRUNC('week', NOW())
        AND c.status = 'completed'
    ) AS weekly_wins,

    -- Total challenges this week
    COUNT(*) FILTER (
        WHERE c.completed_at >= DATE_TRUNC('week', NOW())
        AND c.status = 'completed'
    ) AS weekly_completed,

    -- Weekly win rate
    ROUND(
        COUNT(*) FILTER (WHERE c.did_beat = true AND c.is_retry = false AND c.completed_at >= DATE_TRUNC('week', NOW()))::DECIMAL /
        NULLIF(COUNT(*) FILTER (WHERE c.completed_at >= DATE_TRUNC('week', NOW()) AND c.status = 'completed'), 0) * 100,
        1
    ) AS weekly_win_rate,

    -- Timestamp
    NOW() AS last_updated

FROM users u
LEFT JOIN workout_challenges c ON c.to_user_id = u.id
WHERE c.completed_at >= DATE_TRUNC('week', NOW()) OR c.completed_at IS NULL
GROUP BY u.id, u.name, u.avatar_url, u.country_code
HAVING COUNT(*) FILTER (WHERE c.completed_at >= DATE_TRUNC('week', NOW()) AND c.status = 'completed') > 0
ORDER BY weekly_wins DESC, weekly_win_rate DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_weekly_user ON leaderboard_weekly_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_weekly_country ON leaderboard_weekly_challenges(country_code);
CREATE INDEX IF NOT EXISTS idx_leaderboard_weekly_rank ON leaderboard_weekly_challenges(weekly_wins DESC, weekly_win_rate DESC);

COMMENT ON MATERIALIZED VIEW leaderboard_weekly_challenges IS 'Weekly leaderboard: Challenges won this week (resets Monday)';

-- ============================================================
-- FUNCTION: GET USER RANK
-- ============================================================

-- Get user's rank in a specific leaderboard
CREATE OR REPLACE FUNCTION get_user_leaderboard_rank(
    p_user_id UUID,
    p_leaderboard_type VARCHAR DEFAULT 'challenge_masters',
    p_country_filter VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    rank BIGINT,
    total_users BIGINT,
    percentile DECIMAL
) AS $$
DECLARE
    user_rank BIGINT;
    total_count BIGINT;
BEGIN
    -- Challenge Masters leaderboard
    IF p_leaderboard_type = 'challenge_masters' THEN
        WITH ranked_users AS (
            SELECT
                user_id,
                ROW_NUMBER() OVER (ORDER BY first_wins DESC, win_rate DESC, last_updated ASC) AS row_rank
            FROM leaderboard_challenge_masters
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT
            ru.row_rank,
            COUNT(*) OVER () AS total
        INTO user_rank, total_count
        FROM ranked_users ru
        WHERE ru.user_id = p_user_id;

    -- Volume Kings leaderboard
    ELSIF p_leaderboard_type = 'volume_kings' THEN
        WITH ranked_users AS (
            SELECT
                user_id,
                ROW_NUMBER() OVER (ORDER BY total_volume_lbs DESC) AS row_rank
            FROM leaderboard_volume_kings
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT
            ru.row_rank,
            COUNT(*) OVER () AS total
        INTO user_rank, total_count
        FROM ranked_users ru
        WHERE ru.user_id = p_user_id;

    -- Streaks leaderboard
    ELSIF p_leaderboard_type = 'streaks' THEN
        WITH ranked_users AS (
            SELECT
                user_id,
                ROW_NUMBER() OVER (ORDER BY best_streak DESC, current_streak DESC) AS row_rank
            FROM leaderboard_streaks
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT
            ru.row_rank,
            COUNT(*) OVER () AS total
        INTO user_rank, total_count
        FROM ranked_users ru
        WHERE ru.user_id = p_user_id;

    -- Weekly challenges leaderboard
    ELSIF p_leaderboard_type = 'weekly_challenges' THEN
        WITH ranked_users AS (
            SELECT
                user_id,
                ROW_NUMBER() OVER (ORDER BY weekly_wins DESC, weekly_win_rate DESC) AS row_rank
            FROM leaderboard_weekly_challenges
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT
            ru.row_rank,
            COUNT(*) OVER () AS total
        INTO user_rank, total_count
        FROM ranked_users ru
        WHERE ru.user_id = p_user_id;
    END IF;

    -- Return results
    RETURN QUERY SELECT
        COALESCE(user_rank, 0) AS rank,
        COALESCE(total_count, 0) AS total_users,
        CASE
            WHEN total_count > 0 THEN ROUND((user_rank::DECIMAL / total_count * 100), 1)
            ELSE 0
        END AS percentile;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_leaderboard_rank IS 'Get user rank in specified leaderboard with optional country filter';

-- ============================================================
-- FUNCTION: CHECK LEADERBOARD UNLOCK
-- ============================================================

-- Check if user has unlocked global leaderboard (10 workouts minimum)
CREATE OR REPLACE FUNCTION check_leaderboard_unlock(p_user_id UUID)
RETURNS TABLE(
    is_unlocked BOOLEAN,
    workouts_completed INT,
    workouts_needed INT,
    days_active INT
) AS $$
DECLARE
    workout_count INT;
    days_count INT;
    unlocked BOOLEAN;
BEGIN
    -- Count completed workouts
    SELECT COUNT(*) INTO workout_count
    FROM workout_logs
    WHERE user_id = p_user_id;

    -- Count days since account creation
    SELECT EXTRACT(DAY FROM (NOW() - created_at))::INT INTO days_count
    FROM users
    WHERE id = p_user_id;

    -- Check unlock criteria: 10 workouts OR 7 days active
    unlocked := (workout_count >= 10 OR days_count >= 7);

    RETURN QUERY SELECT
        unlocked,
        workout_count,
        GREATEST(10 - workout_count, 0) AS workouts_needed,
        COALESCE(days_count, 0);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_leaderboard_unlock IS 'Check if user has unlocked global leaderboard (10 workouts or 7 days)';

-- ============================================================
-- SCHEDULED REFRESH (Run hourly via cron or pg_cron)
-- ============================================================

-- Note: In production, set up pg_cron or external scheduler to run:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_challenge_masters;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_volume_kings;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_streaks;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_weekly_challenges;

-- For now, create a helper function
CREATE OR REPLACE FUNCTION refresh_all_leaderboards()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_challenge_masters;
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_volume_kings;
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_streaks;
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_weekly_challenges;

    RAISE NOTICE 'All leaderboards refreshed successfully';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_all_leaderboards IS 'Refresh all materialized views for leaderboards';

-- ============================================================
-- INITIAL DATA REFRESH
-- ============================================================

-- Refresh views with initial data
REFRESH MATERIALIZED VIEW leaderboard_challenge_masters;
REFRESH MATERIALIZED VIEW leaderboard_volume_kings;
REFRESH MATERIALIZED VIEW leaderboard_streaks;
REFRESH MATERIALIZED VIEW leaderboard_weekly_challenges;
