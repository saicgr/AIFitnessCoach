-- Migration 089: Cardio Sessions
-- Store user cardio workout sessions with detailed metrics
-- Supports running, cycling, swimming, and other cardio activities

-- ===================================
-- Table: cardio_sessions
-- ===================================
-- Stores individual cardio workout sessions with location, distance, pace, and heart rate data
CREATE TABLE IF NOT EXISTS cardio_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,  -- Optional link to workout

    -- Session type and location
    cardio_type VARCHAR(50) NOT NULL CHECK (cardio_type IN (
        'running', 'cycling', 'swimming', 'rowing', 'elliptical',
        'walking', 'hiking', 'stair_climbing', 'jump_rope', 'other'
    )),
    location VARCHAR(50) NOT NULL CHECK (location IN (
        'indoor', 'outdoor', 'treadmill', 'track', 'trail', 'pool', 'gym'
    )),

    -- Distance and duration
    distance_km DECIMAL(8,3) CHECK (distance_km IS NULL OR distance_km >= 0),
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0 AND duration_minutes <= 1440),  -- Max 24 hours

    -- Pace and speed
    avg_pace_per_km VARCHAR(10),  -- Format: "MM:SS" e.g., "5:30"
    avg_speed_kmh DECIMAL(5,2) CHECK (avg_speed_kmh IS NULL OR avg_speed_kmh >= 0),

    -- Elevation (for running, cycling, hiking)
    elevation_gain_m INT CHECK (elevation_gain_m IS NULL OR elevation_gain_m >= 0),

    -- Heart rate data
    avg_heart_rate INT CHECK (avg_heart_rate IS NULL OR (avg_heart_rate >= 40 AND avg_heart_rate <= 250)),
    max_heart_rate INT CHECK (max_heart_rate IS NULL OR (max_heart_rate >= 40 AND max_heart_rate <= 250)),

    -- Energy
    calories_burned INT CHECK (calories_burned IS NULL OR calories_burned >= 0),

    -- Additional info
    notes TEXT,
    weather_conditions VARCHAR(100),  -- e.g., "sunny, 22C, light wind"

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===================================
-- Indexes for performance
-- ===================================
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_user ON cardio_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_created ON cardio_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_user_created ON cardio_sessions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_type ON cardio_sessions(cardio_type);
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_workout ON cardio_sessions(workout_id) WHERE workout_id IS NOT NULL;

-- ===================================
-- Trigger: Auto-update updated_at
-- ===================================
CREATE OR REPLACE FUNCTION update_cardio_sessions_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cardio_sessions_updated_at ON cardio_sessions;
CREATE TRIGGER trigger_cardio_sessions_updated_at
    BEFORE UPDATE ON cardio_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_cardio_sessions_updated_at();

-- ===================================
-- Row Level Security (RLS)
-- ===================================
ALTER TABLE cardio_sessions ENABLE ROW LEVEL SECURITY;

-- Users can view their own cardio sessions
DROP POLICY IF EXISTS "Users can view own cardio sessions" ON cardio_sessions;
CREATE POLICY "Users can view own cardio sessions"
    ON cardio_sessions FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own cardio sessions
DROP POLICY IF EXISTS "Users can insert own cardio sessions" ON cardio_sessions;
CREATE POLICY "Users can insert own cardio sessions"
    ON cardio_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own cardio sessions
DROP POLICY IF EXISTS "Users can update own cardio sessions" ON cardio_sessions;
CREATE POLICY "Users can update own cardio sessions"
    ON cardio_sessions FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own cardio sessions
DROP POLICY IF EXISTS "Users can delete own cardio sessions" ON cardio_sessions;
CREATE POLICY "Users can delete own cardio sessions"
    ON cardio_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- Service role has full access (for backend operations)
DROP POLICY IF EXISTS "Service role has full access to cardio sessions" ON cardio_sessions;
CREATE POLICY "Service role has full access to cardio sessions"
    ON cardio_sessions FOR ALL
    USING (auth.role() = 'service_role');

-- ===================================
-- View: Latest cardio sessions per user
-- ===================================
-- Useful for quick lookups of recent cardio activity
-- Drop existing view first to allow column changes
DROP VIEW IF EXISTS recent_cardio_sessions;
CREATE VIEW recent_cardio_sessions AS
SELECT
    id,
    user_id,
    workout_id,
    cardio_type,
    location,
    distance_km,
    duration_minutes,
    avg_pace_per_km,
    avg_speed_kmh,
    elevation_gain_m,
    avg_heart_rate,
    max_heart_rate,
    calories_burned,
    notes,
    weather_conditions,
    created_at,
    updated_at
FROM cardio_sessions
ORDER BY created_at DESC;

-- Grant access to authenticated users
GRANT SELECT ON recent_cardio_sessions TO authenticated;

-- ===================================
-- View: Cardio session stats aggregated by user and type
-- ===================================
-- Drop existing view first to allow column changes
DROP VIEW IF EXISTS cardio_session_stats;
CREATE VIEW cardio_session_stats AS
SELECT
    user_id,
    cardio_type,
    COUNT(*) as total_sessions,
    COALESCE(SUM(distance_km), 0) as total_distance_km,
    SUM(duration_minutes) as total_duration_minutes,
    COALESCE(AVG(distance_km), 0) as avg_distance_km,
    AVG(duration_minutes) as avg_duration_minutes,
    COALESCE(AVG(avg_speed_kmh), 0) as avg_speed_kmh,
    COALESCE(AVG(avg_heart_rate), 0) as avg_heart_rate,
    COALESCE(SUM(calories_burned), 0) as total_calories_burned,
    COALESCE(SUM(elevation_gain_m), 0) as total_elevation_gain_m,
    MIN(created_at) as first_session,
    MAX(created_at) as last_session
FROM cardio_sessions
GROUP BY user_id, cardio_type;

-- Grant access to authenticated users
GRANT SELECT ON cardio_session_stats TO authenticated;

-- ===================================
-- Function: Get cardio session summary for a user
-- ===================================
CREATE OR REPLACE FUNCTION get_cardio_session_summary(
    p_user_id UUID,
    p_days INT DEFAULT 30
)
RETURNS TABLE (
    cardio_type VARCHAR(50),
    session_count BIGINT,
    total_distance_km NUMERIC,
    total_duration_minutes BIGINT,
    avg_pace VARCHAR(10),
    total_calories BIGINT,
    avg_heart_rate NUMERIC
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        cs.cardio_type,
        COUNT(*)::BIGINT as session_count,
        COALESCE(SUM(cs.distance_km), 0)::NUMERIC as total_distance_km,
        COALESCE(SUM(cs.duration_minutes), 0)::BIGINT as total_duration_minutes,
        CASE
            WHEN SUM(cs.distance_km) > 0 THEN
                CONCAT(
                    FLOOR(SUM(cs.duration_minutes)::NUMERIC / SUM(cs.distance_km))::TEXT,
                    ':',
                    LPAD(
                        (((SUM(cs.duration_minutes)::NUMERIC / SUM(cs.distance_km)) - FLOOR(SUM(cs.duration_minutes)::NUMERIC / SUM(cs.distance_km))) * 60)::INT::TEXT,
                        2,
                        '0'
                    )
                )
            ELSE NULL
        END::VARCHAR(10) as avg_pace,
        COALESCE(SUM(cs.calories_burned), 0)::BIGINT as total_calories,
        COALESCE(AVG(cs.avg_heart_rate), 0)::NUMERIC as avg_heart_rate
    FROM cardio_sessions cs
    WHERE cs.user_id = p_user_id
      AND cs.created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY cs.cardio_type
    ORDER BY session_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute on function
GRANT EXECUTE ON FUNCTION get_cardio_session_summary TO authenticated;

-- ===================================
-- Comments for documentation
-- ===================================
COMMENT ON TABLE cardio_sessions IS 'Stores individual cardio workout sessions with detailed metrics including distance, pace, heart rate, and location';
COMMENT ON COLUMN cardio_sessions.cardio_type IS 'Type of cardio activity: running, cycling, swimming, rowing, elliptical, walking, hiking, stair_climbing, jump_rope, other';
COMMENT ON COLUMN cardio_sessions.location IS 'Where the session took place: indoor, outdoor, treadmill, track, trail, pool, gym';
COMMENT ON COLUMN cardio_sessions.distance_km IS 'Distance covered in kilometers';
COMMENT ON COLUMN cardio_sessions.duration_minutes IS 'Total duration of the session in minutes';
COMMENT ON COLUMN cardio_sessions.avg_pace_per_km IS 'Average pace per kilometer in MM:SS format';
COMMENT ON COLUMN cardio_sessions.avg_speed_kmh IS 'Average speed in kilometers per hour';
COMMENT ON COLUMN cardio_sessions.elevation_gain_m IS 'Total elevation gain in meters';
COMMENT ON COLUMN cardio_sessions.avg_heart_rate IS 'Average heart rate during the session in BPM';
COMMENT ON COLUMN cardio_sessions.max_heart_rate IS 'Maximum heart rate reached during the session in BPM';
COMMENT ON COLUMN cardio_sessions.calories_burned IS 'Estimated calories burned during the session';
COMMENT ON COLUMN cardio_sessions.weather_conditions IS 'Weather conditions during outdoor sessions';
COMMENT ON VIEW recent_cardio_sessions IS 'Recent cardio sessions ordered by date for easy viewing';
COMMENT ON VIEW cardio_session_stats IS 'Aggregated cardio session statistics by user and activity type';
COMMENT ON FUNCTION get_cardio_session_summary IS 'Returns a summary of cardio sessions for a user over the specified number of days';
