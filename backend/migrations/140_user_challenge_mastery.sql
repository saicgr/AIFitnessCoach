-- Migration: User Challenge Mastery Table
-- Purpose: Track beginner users' progress with challenge exercises
-- When they complete challenges successfully 2+ times, they're ready to include
-- those exercises in their main workout

-- Create the user_challenge_mastery table
CREATE TABLE IF NOT EXISTS user_challenge_mastery (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,

    -- Tracking stats
    total_attempts INTEGER DEFAULT 0,
    successful_completions INTEGER DEFAULT 0,
    consecutive_successes INTEGER DEFAULT 0,

    -- Latest feedback
    last_difficulty_felt TEXT CHECK (last_difficulty_felt IN ('too_easy', 'just_right', 'too_hard')),

    -- Progression flag - when true, this exercise can move to main workout
    ready_for_main_workout BOOLEAN DEFAULT FALSE,

    -- Timestamps
    first_attempted_at TIMESTAMPTZ,
    last_attempted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: one mastery record per user per exercise
    UNIQUE(user_id, exercise_name)
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_user_challenge_mastery_user_id
    ON user_challenge_mastery(user_id);

CREATE INDEX IF NOT EXISTS idx_user_challenge_mastery_ready
    ON user_challenge_mastery(user_id, ready_for_main_workout)
    WHERE ready_for_main_workout = TRUE;

CREATE INDEX IF NOT EXISTS idx_user_challenge_mastery_exercise
    ON user_challenge_mastery(exercise_name);

-- Enable RLS
ALTER TABLE user_challenge_mastery ENABLE ROW LEVEL SECURITY;

-- RLS policies: users can only access their own data
CREATE POLICY "Users can view own challenge mastery"
    ON user_challenge_mastery FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own challenge mastery"
    ON user_challenge_mastery FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own challenge mastery"
    ON user_challenge_mastery FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own challenge mastery"
    ON user_challenge_mastery FOR DELETE
    USING (auth.uid() = user_id);

-- Service role policy for backend access
CREATE POLICY "Service role full access to challenge mastery"
    ON user_challenge_mastery FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Add comment explaining the table
COMMENT ON TABLE user_challenge_mastery IS
    'Tracks beginner users progress with challenge exercises. When consecutive_successes >= 2, the exercise is ready for main workout.';

COMMENT ON COLUMN user_challenge_mastery.consecutive_successes IS
    'Number of consecutive successful completions with "just_right" or "too_easy" feedback. Resets on skip/fail or "too_hard".';

COMMENT ON COLUMN user_challenge_mastery.ready_for_main_workout IS
    'When TRUE, this challenge exercise has been mastered and can be included in regular workouts.';
