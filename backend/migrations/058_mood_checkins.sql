-- Migration: 058_mood_checkins.sql
-- Description: Add mood check-ins table for quick mood-based workout generation
-- Created: 2024-12-30

-- ============================================================================
-- MOOD CHECK-INS TABLE
-- ============================================================================
-- Tracks user mood selections for quick workout generation
-- Used to personalize workout recommendations based on how user feels

CREATE TABLE IF NOT EXISTS mood_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Mood selection (4 options)
    mood VARCHAR(20) NOT NULL CHECK (mood IN ('great', 'good', 'tired', 'stressed')),

    -- Timestamp when user checked in
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Whether a workout was generated from this mood
    workout_generated BOOLEAN DEFAULT FALSE,

    -- Reference to the generated workout (if any)
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,

    -- Whether the user completed the generated workout
    workout_completed BOOLEAN DEFAULT FALSE,

    -- Additional context (stored as JSON)
    context JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_mood_checkins_user ON mood_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_checkins_user_date ON mood_checkins(user_id, check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_mood_checkins_mood ON mood_checkins(mood);
CREATE INDEX IF NOT EXISTS idx_mood_checkins_workout ON mood_checkins(workout_id) WHERE workout_id IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE mood_checkins ENABLE ROW LEVEL SECURITY;

-- Users can only see their own mood check-ins
DROP POLICY IF EXISTS mood_checkins_select_policy ON mood_checkins;
CREATE POLICY mood_checkins_select_policy ON mood_checkins
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own mood check-ins
DROP POLICY IF EXISTS mood_checkins_insert_policy ON mood_checkins;
CREATE POLICY mood_checkins_insert_policy ON mood_checkins
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own mood check-ins
DROP POLICY IF EXISTS mood_checkins_update_policy ON mood_checkins;
CREATE POLICY mood_checkins_update_policy ON mood_checkins
    FOR UPDATE USING (auth.uid() = user_id);

-- Service role can do everything
DROP POLICY IF EXISTS mood_checkins_service_policy ON mood_checkins;
CREATE POLICY mood_checkins_service_policy ON mood_checkins
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- Today's mood check-in for each user
CREATE OR REPLACE VIEW today_mood_checkin AS
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

-- Recent mood patterns (last 7 days)
CREATE OR REPLACE VIEW recent_mood_patterns AS
SELECT
    user_id,
    mood,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE workout_completed) as completed_count,
    ROUND(COUNT(*) FILTER (WHERE workout_completed)::numeric / NULLIF(COUNT(*), 0) * 100, 1) as completion_rate
FROM mood_checkins
WHERE check_in_time >= NOW() - INTERVAL '7 days'
GROUP BY user_id, mood;

-- Grant permissions on views
GRANT SELECT ON today_mood_checkin TO authenticated;
GRANT SELECT ON recent_mood_patterns TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE mood_checkins IS 'Tracks user mood selections for quick workout generation';
COMMENT ON COLUMN mood_checkins.mood IS 'User mood: great (high energy), good (balanced), tired (low energy), stressed (need relief)';
COMMENT ON COLUMN mood_checkins.workout_generated IS 'Whether a workout was generated from this mood selection';
COMMENT ON COLUMN mood_checkins.workout_completed IS 'Whether the user completed the generated workout';
COMMENT ON COLUMN mood_checkins.context IS 'Additional context like time_of_day, day_of_week, device, app_version';
COMMENT ON VIEW today_mood_checkin IS 'Most recent mood check-in for today per user';
COMMENT ON VIEW recent_mood_patterns IS 'Mood frequency and completion rates over last 7 days per user';
