-- Migration: 063_staple_exercises.sql
-- Description: Add staple exercises system - exercises that should NEVER be rotated out during weekly variation
-- This addresses user feedback: "same muscle group different exercise" while allowing users to lock core lifts

-- Create staple_exercises table
CREATE TABLE IF NOT EXISTS staple_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    library_id UUID REFERENCES exercise_library(id) ON DELETE SET NULL,
    muscle_group TEXT,
    reason TEXT, -- Optional: why this is a staple (e.g., "core compound", "favorite", "rehab")
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, exercise_name)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_staple_exercises_user_id ON staple_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_staple_exercises_muscle_group ON staple_exercises(muscle_group);

-- Enable RLS
ALTER TABLE staple_exercises ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own staple exercises"
ON staple_exercises FOR SELECT
USING (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Users can insert their own staple exercises"
ON staple_exercises FOR INSERT
WITH CHECK (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete their own staple exercises"
ON staple_exercises FOR DELETE
USING (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Service role has full access to staple_exercises"
ON staple_exercises FOR ALL
USING (auth.role() = 'service_role');

-- Add variation_percentage to users table (default 30% - moderate variety)
ALTER TABLE users ADD COLUMN IF NOT EXISTS variation_percentage INTEGER DEFAULT 30 CHECK (variation_percentage >= 0 AND variation_percentage <= 100);

-- Add comment
COMMENT ON TABLE staple_exercises IS 'Exercises that should never be rotated out during weekly workout variation';
COMMENT ON COLUMN staple_exercises.reason IS 'Optional reason: core_compound, favorite, rehab, strength_focus, etc.';
COMMENT ON COLUMN users.variation_percentage IS 'How much exercise variety user wants week-to-week (0=same, 100=all new, default 30)';

-- Create view for user staples with exercise details
CREATE OR REPLACE VIEW user_staples_with_details AS
SELECT
    s.id,
    s.user_id,
    s.exercise_name,
    s.library_id,
    s.muscle_group,
    s.reason,
    s.created_at,
    el.body_part,
    el.equipment,
    el.target_muscle,
    el.gif_url,
    el.difficulty_level
FROM staple_exercises s
LEFT JOIN exercise_library el ON s.library_id = el.id;

-- Create exercise_rotations table to track what changed week-over-week
CREATE TABLE IF NOT EXISTS exercise_rotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    week_start_date DATE NOT NULL,
    exercise_added TEXT NOT NULL,
    exercise_removed TEXT,
    muscle_group TEXT,
    rotation_reason TEXT, -- 'variety', 'user_preference', 'equipment_change', etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for rotation tracking
CREATE INDEX IF NOT EXISTS idx_exercise_rotations_user_week ON exercise_rotations(user_id, week_start_date);
CREATE INDEX IF NOT EXISTS idx_exercise_rotations_workout ON exercise_rotations(workout_id);

-- Enable RLS
ALTER TABLE exercise_rotations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for exercise_rotations
CREATE POLICY "Users can view their own exercise rotations"
ON exercise_rotations FOR SELECT
USING (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Service role has full access to exercise_rotations"
ON exercise_rotations FOR ALL
USING (auth.role() = 'service_role');

COMMENT ON TABLE exercise_rotations IS 'Tracks which exercises were swapped week-over-week for transparency';
