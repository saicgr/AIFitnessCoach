-- Migration: Workout AI Summaries
-- Created: 2025-12-04
-- Purpose: Store AI-generated summaries for individual workouts (post-completion)

-- ============================================
-- workout_summaries - Per-workout AI summaries
-- ============================================
CREATE TABLE IF NOT EXISTS workout_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Summary content
    summary TEXT NOT NULL,  -- AI-generated summary text

    -- Workout context at time of generation
    workout_name VARCHAR(255),
    workout_type VARCHAR(50),
    exercise_count INTEGER,
    duration_minutes INTEGER,
    calories_estimate INTEGER,

    -- AI metadata
    model_used VARCHAR(50) DEFAULT 'gpt-4',
    tokens_used INTEGER,
    generation_time_ms INTEGER,

    -- Timestamps
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(workout_id, user_id)  -- One summary per workout per user
);

COMMENT ON TABLE workout_summaries IS 'Stores AI-generated summaries for completed workouts';
COMMENT ON COLUMN workout_summaries.summary IS 'AI-generated motivational summary explaining workout benefits';

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_workout_summaries_workout_id ON workout_summaries(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_summaries_user_id ON workout_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_summaries_generated_at ON workout_summaries(generated_at DESC);

-- Enable Row Level Security
ALTER TABLE workout_summaries ENABLE ROW LEVEL SECURITY;

-- Users can only see their own summaries
DROP POLICY IF EXISTS workout_summaries_select_policy ON workout_summaries;
CREATE POLICY workout_summaries_select_policy ON workout_summaries
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS workout_summaries_service_policy ON workout_summaries;
CREATE POLICY workout_summaries_service_policy ON workout_summaries
    FOR ALL
    USING (auth.role() = 'service_role');
