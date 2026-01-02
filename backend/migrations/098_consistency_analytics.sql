-- Migration 098: Consistency Analytics System
-- Track streak history and workout time patterns for consistency insights

-- ============================================================================
-- Streak History Table
-- Tracks when streaks start and end for historical analysis
-- ============================================================================
CREATE TABLE IF NOT EXISTS streak_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    streak_length INTEGER NOT NULL CHECK (streak_length >= 0),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    end_reason TEXT DEFAULT 'missed_workout',  -- missed_workout, manual_reset, program_change
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient user queries
CREATE INDEX IF NOT EXISTS idx_streak_history_user_id ON streak_history(user_id);
CREATE INDEX IF NOT EXISTS idx_streak_history_ended_at ON streak_history(ended_at DESC);
CREATE INDEX IF NOT EXISTS idx_streak_history_streak_length ON streak_history(streak_length DESC);

-- ============================================================================
-- Workout Time Patterns Table
-- Tracks completion/skip patterns by day of week and hour
-- ============================================================================
CREATE TABLE IF NOT EXISTS workout_time_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sunday, 6=Saturday
    hour_of_day INTEGER NOT NULL CHECK (hour_of_day BETWEEN 0 AND 23),
    completion_count INTEGER DEFAULT 0 CHECK (completion_count >= 0),
    skip_count INTEGER DEFAULT 0 CHECK (skip_count >= 0),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Unique constraint: one record per user per day/hour combination
    CONSTRAINT unique_user_day_hour UNIQUE (user_id, day_of_week, hour_of_day)
);

-- Index for efficient user queries
CREATE INDEX IF NOT EXISTS idx_workout_time_patterns_user_id ON workout_time_patterns(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_time_patterns_day ON workout_time_patterns(day_of_week);

-- ============================================================================
-- Streak Recovery Attempts Table
-- Tracks when users return after breaking a streak
-- ============================================================================
CREATE TABLE IF NOT EXISTS streak_recovery_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    previous_streak_length INTEGER NOT NULL DEFAULT 0,
    days_since_last_workout INTEGER NOT NULL DEFAULT 1,
    recovery_workout_id UUID,  -- The workout they did to start recovering
    recovery_type TEXT DEFAULT 'standard',  -- standard, quick_recovery, custom
    motivation_message TEXT,  -- AI-generated encouragement message
    was_successful BOOLEAN DEFAULT NULL,  -- Did they complete the recovery workout?
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Index for efficient user queries
CREATE INDEX IF NOT EXISTS idx_streak_recovery_user_id ON streak_recovery_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_streak_recovery_created_at ON streak_recovery_attempts(created_at DESC);

-- ============================================================================
-- Daily Consistency Metrics (Materialized View Pattern)
-- Pre-aggregated daily stats for fast queries
-- ============================================================================
CREATE TABLE IF NOT EXISTS daily_consistency_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    metric_date DATE NOT NULL,
    workouts_scheduled INTEGER DEFAULT 0,
    workouts_completed INTEGER DEFAULT 0,
    workouts_skipped INTEGER DEFAULT 0,
    total_workout_minutes INTEGER DEFAULT 0,
    streak_day INTEGER DEFAULT 0,  -- Which day of streak this was (0 if no streak)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Unique constraint: one record per user per day
    CONSTRAINT unique_user_date UNIQUE (user_id, metric_date)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_daily_consistency_user_date ON daily_consistency_metrics(user_id, metric_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_consistency_metric_date ON daily_consistency_metrics(metric_date);

-- ============================================================================
-- Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE streak_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_time_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_recovery_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_consistency_metrics ENABLE ROW LEVEL SECURITY;

-- Streak History: Users can only see/modify their own records
CREATE POLICY "Users own their streak history"
    ON streak_history FOR ALL
    USING (auth.uid() = user_id);

-- Workout Time Patterns: Users can only see/modify their own records
CREATE POLICY "Users own their workout time patterns"
    ON workout_time_patterns FOR ALL
    USING (auth.uid() = user_id);

-- Streak Recovery Attempts: Users can only see/modify their own records
CREATE POLICY "Users own their streak recovery attempts"
    ON streak_recovery_attempts FOR ALL
    USING (auth.uid() = user_id);

-- Daily Consistency Metrics: Users can only see/modify their own records
CREATE POLICY "Users own their daily consistency metrics"
    ON daily_consistency_metrics FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================================
-- Helper Function: Update Workout Time Patterns
-- Called when a workout is completed or skipped
-- ============================================================================
CREATE OR REPLACE FUNCTION update_workout_time_pattern(
    p_user_id UUID,
    p_completed_at TIMESTAMPTZ,
    p_is_completed BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_day_of_week INTEGER;
    v_hour_of_day INTEGER;
BEGIN
    -- Extract day of week (0=Sunday) and hour from the timestamp
    v_day_of_week := EXTRACT(DOW FROM p_completed_at);
    v_hour_of_day := EXTRACT(HOUR FROM p_completed_at);

    -- Upsert the pattern record
    INSERT INTO workout_time_patterns (user_id, day_of_week, hour_of_day, completion_count, skip_count, updated_at)
    VALUES (
        p_user_id,
        v_day_of_week,
        v_hour_of_day,
        CASE WHEN p_is_completed THEN 1 ELSE 0 END,
        CASE WHEN p_is_completed THEN 0 ELSE 1 END,
        NOW()
    )
    ON CONFLICT (user_id, day_of_week, hour_of_day)
    DO UPDATE SET
        completion_count = workout_time_patterns.completion_count + CASE WHEN p_is_completed THEN 1 ELSE 0 END,
        skip_count = workout_time_patterns.skip_count + CASE WHEN p_is_completed THEN 0 ELSE 1 END,
        updated_at = NOW();
END;
$$;

-- ============================================================================
-- Helper Function: Record Streak End
-- Called when a streak is broken
-- ============================================================================
CREATE OR REPLACE FUNCTION record_streak_end(
    p_user_id UUID,
    p_streak_length INTEGER,
    p_started_at TIMESTAMPTZ,
    p_ended_at TIMESTAMPTZ,
    p_end_reason TEXT DEFAULT 'missed_workout'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_streak_id UUID;
BEGIN
    -- Only record if streak was at least 1 day
    IF p_streak_length > 0 THEN
        INSERT INTO streak_history (user_id, streak_length, started_at, ended_at, end_reason)
        VALUES (p_user_id, p_streak_length, p_started_at, p_ended_at, p_end_reason)
        RETURNING id INTO v_streak_id;

        RETURN v_streak_id;
    END IF;

    RETURN NULL;
END;
$$;

-- ============================================================================
-- Helper Function: Get Longest Streak
-- Returns the longest streak ever for a user
-- ============================================================================
CREATE OR REPLACE FUNCTION get_longest_streak(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_max_historical INTEGER;
    v_current_streak INTEGER;
BEGIN
    -- Get max from history
    SELECT COALESCE(MAX(streak_length), 0)
    INTO v_max_historical
    FROM streak_history
    WHERE user_id = p_user_id;

    -- Get current streak from users table
    SELECT COALESCE(current_streak, 0)
    INTO v_current_streak
    FROM users
    WHERE id = p_user_id;

    -- Return the greater of the two
    RETURN GREATEST(v_max_historical, v_current_streak);
END;
$$;

-- ============================================================================
-- Grant permissions for API access
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON streak_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON workout_time_patterns TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON streak_recovery_attempts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_consistency_metrics TO authenticated;

GRANT EXECUTE ON FUNCTION update_workout_time_pattern TO authenticated;
GRANT EXECUTE ON FUNCTION record_streak_end TO authenticated;
GRANT EXECUTE ON FUNCTION get_longest_streak TO authenticated;
