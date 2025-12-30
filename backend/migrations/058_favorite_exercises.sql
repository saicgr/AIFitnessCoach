-- Migration 058: Favorite Exercises System
-- Allows users to mark exercises as favorites for AI prioritization
-- Addresses competitor feedback: "favoriting exercises didn't help"

-- Create favorite_exercises table
CREATE TABLE IF NOT EXISTS favorite_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    -- Optional reference to exercise library (can be null for custom exercises)
    exercise_id TEXT,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure a user can only favorite an exercise once
    UNIQUE(user_id, exercise_name)
);

-- Create index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_favorite_exercises_user_id
ON favorite_exercises(user_id);

-- Create index for looking up by exercise name (for boosting in RAG)
CREATE INDEX IF NOT EXISTS idx_favorite_exercises_name
ON favorite_exercises(user_id, exercise_name);

-- Enable Row Level Security
ALTER TABLE favorite_exercises ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own favorites
CREATE POLICY favorite_exercises_select_policy ON favorite_exercises
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own favorites
CREATE POLICY favorite_exercises_insert_policy ON favorite_exercises
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only delete their own favorites
CREATE POLICY favorite_exercises_delete_policy ON favorite_exercises
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON favorite_exercises TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE favorite_exercises IS 'Stores user favorite exercises for AI prioritization during workout generation';
COMMENT ON COLUMN favorite_exercises.exercise_name IS 'Exercise name (used for matching in RAG selection)';
COMMENT ON COLUMN favorite_exercises.exercise_id IS 'Optional reference to exercise library ID';
