-- Migration: 094_exercise_swap_tracking.sql
-- Track exercise swaps during workouts for analytics and AI improvement
-- This addresses user feedback: "Please let me change exercises in a workout at my discretion"

-- Create exercise_swaps table to track all swap events
CREATE TABLE IF NOT EXISTS exercise_swaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,

    -- Original and replacement exercise info
    original_exercise TEXT NOT NULL,
    new_exercise TEXT NOT NULL,

    -- Reason for swap (helps AI learn user preferences)
    swap_reason TEXT, -- 'too_difficult', 'too_easy', 'equipment_unavailable', 'injury_concern', 'personal_preference', 'other'
    swap_reason_detail TEXT, -- Optional free-text explanation

    -- Workout context
    workout_phase TEXT DEFAULT 'main', -- 'warmup', 'main', 'cooldown'
    exercise_index INTEGER, -- Position in workout

    -- Timing
    swapped_at TIMESTAMPTZ DEFAULT NOW(),

    -- For analytics: was the swap AI-suggested or user-searched?
    swap_source TEXT DEFAULT 'ai_suggestion', -- 'ai_suggestion', 'library_search', 'recent_exercise'

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_exercise_swaps_user_id ON exercise_swaps(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_swaps_workout_id ON exercise_swaps(workout_id);
CREATE INDEX IF NOT EXISTS idx_exercise_swaps_original ON exercise_swaps(original_exercise);
CREATE INDEX IF NOT EXISTS idx_exercise_swaps_new ON exercise_swaps(new_exercise);
CREATE INDEX IF NOT EXISTS idx_exercise_swaps_reason ON exercise_swaps(swap_reason);
CREATE INDEX IF NOT EXISTS idx_exercise_swaps_swapped_at ON exercise_swaps(swapped_at);

-- Enable RLS
ALTER TABLE exercise_swaps ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own exercise swaps" ON exercise_swaps;
CREATE POLICY "Users can view their own exercise swaps" ON exercise_swaps
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own exercise swaps" ON exercise_swaps;
CREATE POLICY "Users can insert their own exercise swaps" ON exercise_swaps
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create a view for user swap patterns (for AI context)
CREATE OR REPLACE VIEW user_swap_patterns AS
SELECT
    user_id,
    original_exercise,
    new_exercise,
    swap_reason,
    COUNT(*) as swap_count,
    MAX(swapped_at) as last_swapped
FROM exercise_swaps
GROUP BY user_id, original_exercise, new_exercise, swap_reason
ORDER BY swap_count DESC;

-- Create a view for frequently swapped exercises (exercises users often replace)
CREATE OR REPLACE VIEW frequently_swapped_exercises AS
SELECT
    user_id,
    original_exercise,
    COUNT(*) as times_swapped,
    ARRAY_AGG(DISTINCT new_exercise) as replacement_exercises,
    ARRAY_AGG(DISTINCT swap_reason) as reasons
FROM exercise_swaps
GROUP BY user_id, original_exercise
HAVING COUNT(*) >= 2
ORDER BY times_swapped DESC;

-- Function to check if user frequently swaps a specific exercise
CREATE OR REPLACE FUNCTION user_frequently_swaps(p_user_id UUID, p_exercise TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM exercise_swaps
        WHERE user_id = p_user_id
        AND LOWER(original_exercise) = LOWER(p_exercise)
        GROUP BY original_exercise
        HAVING COUNT(*) >= 3
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '094_exercise_swap_tracking',
    NOW(),
    'Added exercise_swaps table to track user swap patterns for AI improvement'
) ON CONFLICT DO NOTHING;

COMMENT ON TABLE exercise_swaps IS 'Tracks exercise swaps during workouts for AI learning and user preference detection';
