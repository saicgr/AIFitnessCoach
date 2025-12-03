-- Migration: Exercise Feedback System
-- Created: 2025-12-02
-- Purpose: Allow users to rate exercises 1-5 stars with optional comments after workouts

-- ============================================
-- exercise_feedback - Per-exercise ratings and comments
-- ============================================
CREATE TABLE IF NOT EXISTS exercise_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    exercise_index INTEGER NOT NULL,  -- Position in workout
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    difficulty_felt VARCHAR(20) CHECK (difficulty_felt IN ('too_easy', 'just_right', 'too_hard')),
    would_do_again BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments for documentation
COMMENT ON TABLE exercise_feedback IS 'Stores user feedback for individual exercises after completing a workout';
COMMENT ON COLUMN exercise_feedback.rating IS 'Star rating from 1 (poor) to 5 (excellent)';
COMMENT ON COLUMN exercise_feedback.difficulty_felt IS 'How the user felt about the exercise difficulty';
COMMENT ON COLUMN exercise_feedback.would_do_again IS 'Whether user would like to do this exercise again';

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_exercise_feedback_user_id ON exercise_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_feedback_workout_id ON exercise_feedback(workout_id);
CREATE INDEX IF NOT EXISTS idx_exercise_feedback_exercise_name ON exercise_feedback(exercise_name);
CREATE INDEX IF NOT EXISTS idx_exercise_feedback_rating ON exercise_feedback(rating);

-- Enable Row Level Security
ALTER TABLE exercise_feedback ENABLE ROW LEVEL SECURITY;

-- Users can only see their own feedback
DROP POLICY IF EXISTS exercise_feedback_select_policy ON exercise_feedback;
CREATE POLICY exercise_feedback_select_policy ON exercise_feedback
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own feedback
DROP POLICY IF EXISTS exercise_feedback_insert_policy ON exercise_feedback;
CREATE POLICY exercise_feedback_insert_policy ON exercise_feedback
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own feedback
DROP POLICY IF EXISTS exercise_feedback_update_policy ON exercise_feedback;
CREATE POLICY exercise_feedback_update_policy ON exercise_feedback
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can only delete their own feedback
DROP POLICY IF EXISTS exercise_feedback_delete_policy ON exercise_feedback;
CREATE POLICY exercise_feedback_delete_policy ON exercise_feedback
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS exercise_feedback_service_policy ON exercise_feedback;
CREATE POLICY exercise_feedback_service_policy ON exercise_feedback
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- workout_feedback - Overall workout rating
-- ============================================
CREATE TABLE IF NOT EXISTS workout_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    overall_rating INTEGER NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
    energy_level VARCHAR(20) CHECK (energy_level IN ('exhausted', 'tired', 'good', 'energized', 'great')),
    overall_difficulty VARCHAR(20) CHECK (overall_difficulty IN ('too_easy', 'just_right', 'too_hard')),
    comment TEXT,
    would_recommend BOOLEAN DEFAULT true,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, workout_id)  -- One feedback per workout per user
);

-- Add comments for documentation
COMMENT ON TABLE workout_feedback IS 'Stores overall workout feedback after completion';
COMMENT ON COLUMN workout_feedback.overall_rating IS 'Overall workout rating from 1-5 stars';
COMMENT ON COLUMN workout_feedback.energy_level IS 'How the user felt after the workout';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_feedback_user_id ON workout_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_feedback_workout_id ON workout_feedback(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_feedback_completed_at ON workout_feedback(completed_at DESC);

-- Enable Row Level Security
ALTER TABLE workout_feedback ENABLE ROW LEVEL SECURITY;

-- Users can only see their own feedback
DROP POLICY IF EXISTS workout_feedback_select_policy ON workout_feedback;
CREATE POLICY workout_feedback_select_policy ON workout_feedback
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only insert their own feedback
DROP POLICY IF EXISTS workout_feedback_insert_policy ON workout_feedback;
CREATE POLICY workout_feedback_insert_policy ON workout_feedback
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own feedback
DROP POLICY IF EXISTS workout_feedback_update_policy ON workout_feedback;
CREATE POLICY workout_feedback_update_policy ON workout_feedback
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS workout_feedback_service_policy ON workout_feedback;
CREATE POLICY workout_feedback_service_policy ON workout_feedback
    FOR ALL
    USING (auth.role() = 'service_role');
