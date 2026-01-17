-- Migration: 156_user_superset_logs.sql
-- Description: Create table for tracking user-created superset pairings for analytics
-- Date: 2025-01-17

-- =====================================================
-- USER SUPERSET LOGS TABLE
-- Tracks which exercises users pair together as supersets
-- =====================================================

CREATE TABLE IF NOT EXISTS user_superset_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL,
    exercise_1_name TEXT NOT NULL,
    exercise_2_name TEXT NOT NULL,
    exercise_1_muscle TEXT,
    exercise_2_muscle TEXT,
    superset_group INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for user-based queries
CREATE INDEX IF NOT EXISTS idx_superset_logs_user ON user_superset_logs(user_id);

-- Create index for exercise pair analytics
CREATE INDEX IF NOT EXISTS idx_superset_logs_exercises ON user_superset_logs(exercise_1_name, exercise_2_name);

-- Create index for time-based queries
CREATE INDEX IF NOT EXISTS idx_superset_logs_created ON user_superset_logs(created_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE user_superset_logs ENABLE ROW LEVEL SECURITY;

-- Users can insert their own superset logs
CREATE POLICY "Users can insert own superset logs"
    ON user_superset_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can read their own superset logs
CREATE POLICY "Users can read own superset logs"
    ON user_superset_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- =====================================================
-- USEFUL ANALYTICS QUERIES (for reference)
-- =====================================================

-- Most popular superset pairs across all users:
-- SELECT exercise_1_name, exercise_2_name, COUNT(*) as times_used
-- FROM user_superset_logs
-- GROUP BY exercise_1_name, exercise_2_name
-- ORDER BY times_used DESC
-- LIMIT 20;

-- Most common muscle group pairings:
-- SELECT exercise_1_muscle, exercise_2_muscle, COUNT(*) as times_used
-- FROM user_superset_logs
-- GROUP BY exercise_1_muscle, exercise_2_muscle
-- ORDER BY times_used DESC;

-- User's personal superset history:
-- SELECT * FROM user_superset_logs
-- WHERE user_id = 'xxx'
-- ORDER BY created_at DESC;
