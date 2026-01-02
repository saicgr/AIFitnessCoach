-- Migration: 090_enhanced_sets_reps_control.sql
-- Description: Enhanced sets/reps control and muscle mapping for compound exercises
-- Created: 2025-12-30

-- ============================================================================
-- PART 1: Add max/min sets preferences to user_rep_range_preferences table
-- ============================================================================

-- Add max sets per exercise preference (1-8 sets allowed)
ALTER TABLE user_rep_range_preferences
ADD COLUMN IF NOT EXISTS max_sets_per_exercise INTEGER DEFAULT 4 CHECK (max_sets_per_exercise BETWEEN 1 AND 8);

-- Add min sets per exercise preference (1-6 sets allowed)
ALTER TABLE user_rep_range_preferences
ADD COLUMN IF NOT EXISTS min_sets_per_exercise INTEGER DEFAULT 2 CHECK (min_sets_per_exercise BETWEEN 1 AND 6);

-- Add absolute reps ceiling override (user can enforce lower than system default)
ALTER TABLE user_rep_range_preferences
ADD COLUMN IF NOT EXISTS enforce_rep_ceiling BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- PART 2: Create user_workout_patterns table for tracking historical patterns
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_workout_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    avg_sets_completed DECIMAL(3,1),
    avg_reps_completed DECIMAL(4,1),
    avg_weight_used DECIMAL(6,1),
    total_sessions INTEGER DEFAULT 0,
    last_performed_at TIMESTAMPTZ,
    typical_adjustment VARCHAR(50), -- 'none', 'reduces_sets', 'reduces_reps', 'increases_weight'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, exercise_name)
);

-- Index for fast user lookups
CREATE INDEX IF NOT EXISTS idx_user_workout_patterns_user_id ON user_workout_patterns(user_id);

-- Index for exercise name searches
CREATE INDEX IF NOT EXISTS idx_user_workout_patterns_exercise ON user_workout_patterns(exercise_name);

-- Index for finding recently performed exercises
CREATE INDEX IF NOT EXISTS idx_user_workout_patterns_last_performed ON user_workout_patterns(user_id, last_performed_at DESC);

-- ============================================================================
-- PART 3: Create exercise_muscle_mappings table for compound exercise tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_muscle_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id UUID REFERENCES exercises(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    muscle_group VARCHAR(100) NOT NULL,
    involvement_percentage INTEGER CHECK (involvement_percentage BETWEEN 1 AND 100),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(exercise_name, muscle_group)
);

-- Index for fast muscle lookups
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_mappings_muscle ON exercise_muscle_mappings(muscle_group);

-- Index for exercise name lookups
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_mappings_exercise ON exercise_muscle_mappings(exercise_name);

-- Index for finding primary muscles
CREATE INDEX IF NOT EXISTS idx_exercise_muscle_mappings_primary ON exercise_muscle_mappings(is_primary) WHERE is_primary = TRUE;

-- ============================================================================
-- PART 4: Enable RLS and create policies for user_workout_patterns
-- ============================================================================

ALTER TABLE user_workout_patterns ENABLE ROW LEVEL SECURITY;

-- Users can only view their own workout patterns
CREATE POLICY "Users can view own workout patterns" ON user_workout_patterns
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own workout patterns
CREATE POLICY "Users can insert own workout patterns" ON user_workout_patterns
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own workout patterns
CREATE POLICY "Users can update own workout patterns" ON user_workout_patterns
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own workout patterns
CREATE POLICY "Users can delete own workout patterns" ON user_workout_patterns
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- PART 5: Seed common compound exercise muscle mappings
-- ============================================================================

-- Insert muscle mappings for common compound exercises
INSERT INTO exercise_muscle_mappings (exercise_name, muscle_group, involvement_percentage, is_primary) VALUES
-- Dumbbell Squat Thruster
('Dumbbell Squat Thruster', 'Quadriceps', 35, true),
('Dumbbell Squat Thruster', 'Glutes', 25, false),
('Dumbbell Squat Thruster', 'Shoulders', 20, false),
('Dumbbell Squat Thruster', 'Triceps', 10, false),
('Dumbbell Squat Thruster', 'Core', 10, false),

-- Barbell Squat
('Barbell Squat', 'Quadriceps', 45, true),
('Barbell Squat', 'Glutes', 30, false),
('Barbell Squat', 'Hamstrings', 15, false),
('Barbell Squat', 'Core', 10, false),

-- Barbell Deadlift
('Barbell Deadlift', 'Hamstrings', 30, true),
('Barbell Deadlift', 'Glutes', 25, true),
('Barbell Deadlift', 'Lower Back', 20, false),
('Barbell Deadlift', 'Quadriceps', 15, false),
('Barbell Deadlift', 'Core', 10, false),

-- Barbell Bench Press
('Barbell Bench Press', 'Chest', 50, true),
('Barbell Bench Press', 'Triceps', 30, false),
('Barbell Bench Press', 'Shoulders', 20, false),

-- Barbell Clean and Press
('Barbell Clean and Press', 'Shoulders', 25, true),
('Barbell Clean and Press', 'Quadriceps', 20, false),
('Barbell Clean and Press', 'Glutes', 15, false),
('Barbell Clean and Press', 'Triceps', 15, false),
('Barbell Clean and Press', 'Upper Back', 15, false),
('Barbell Clean and Press', 'Core', 10, false),

-- Burpees
('Burpees', 'Full Body', 100, true),
('Burpees', 'Chest', 25, false),
('Burpees', 'Quadriceps', 25, false),
('Burpees', 'Core', 25, false),
('Burpees', 'Shoulders', 25, false),

-- Additional common compound exercises
-- Pull-ups
('Pull-ups', 'Latissimus Dorsi', 40, true),
('Pull-ups', 'Biceps', 30, false),
('Pull-ups', 'Upper Back', 20, false),
('Pull-ups', 'Core', 10, false),

-- Dumbbell Lunges
('Dumbbell Lunges', 'Quadriceps', 40, true),
('Dumbbell Lunges', 'Glutes', 35, false),
('Dumbbell Lunges', 'Hamstrings', 15, false),
('Dumbbell Lunges', 'Core', 10, false),

-- Barbell Row
('Barbell Row', 'Upper Back', 40, true),
('Barbell Row', 'Latissimus Dorsi', 30, false),
('Barbell Row', 'Biceps', 20, false),
('Barbell Row', 'Core', 10, false),

-- Dumbbell Shoulder Press
('Dumbbell Shoulder Press', 'Shoulders', 60, true),
('Dumbbell Shoulder Press', 'Triceps', 30, false),
('Dumbbell Shoulder Press', 'Core', 10, false),

-- Romanian Deadlift
('Romanian Deadlift', 'Hamstrings', 45, true),
('Romanian Deadlift', 'Glutes', 30, false),
('Romanian Deadlift', 'Lower Back', 15, false),
('Romanian Deadlift', 'Core', 10, false),

-- Dumbbell Bench Press
('Dumbbell Bench Press', 'Chest', 50, true),
('Dumbbell Bench Press', 'Triceps', 30, false),
('Dumbbell Bench Press', 'Shoulders', 20, false),

-- Push-ups
('Push-ups', 'Chest', 45, true),
('Push-ups', 'Triceps', 30, false),
('Push-ups', 'Shoulders', 15, false),
('Push-ups', 'Core', 10, false),

-- Kettlebell Swing
('Kettlebell Swing', 'Glutes', 35, true),
('Kettlebell Swing', 'Hamstrings', 30, false),
('Kettlebell Swing', 'Core', 20, false),
('Kettlebell Swing', 'Shoulders', 15, false)

ON CONFLICT (exercise_name, muscle_group) DO NOTHING;

-- ============================================================================
-- PART 6: Function to get all muscles for an exercise
-- ============================================================================

CREATE OR REPLACE FUNCTION get_exercise_muscles(p_exercise_name VARCHAR)
RETURNS TABLE(muscle_group VARCHAR, involvement_percentage INTEGER, is_primary BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    SELECT emm.muscle_group::VARCHAR, emm.involvement_percentage, emm.is_primary
    FROM exercise_muscle_mappings emm
    WHERE LOWER(emm.exercise_name) = LOWER(p_exercise_name)
    ORDER BY emm.involvement_percentage DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 7: Function to check if exercise involves a specific muscle
-- ============================================================================

CREATE OR REPLACE FUNCTION exercise_involves_muscle(
    p_exercise_name VARCHAR,
    p_muscle VARCHAR,
    p_min_involvement INTEGER DEFAULT 10
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM exercise_muscle_mappings emm
        WHERE LOWER(emm.exercise_name) = LOWER(p_exercise_name)
        AND LOWER(emm.muscle_group) = LOWER(p_muscle)
        AND emm.involvement_percentage >= p_min_involvement
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 8: Additional helper functions
-- ============================================================================

-- Function to get all exercises that target a specific muscle
-- Drop existing function if it exists with any signature to avoid conflicts
DROP FUNCTION IF EXISTS get_exercises_for_muscle(VARCHAR, INTEGER, BOOLEAN);
DROP FUNCTION IF EXISTS get_exercises_for_muscle(VARCHAR);
DROP FUNCTION IF EXISTS get_exercises_for_muscle(UUID, TEXT, INTEGER);

CREATE FUNCTION get_exercises_for_muscle(
    p_muscle VARCHAR,
    p_min_involvement INTEGER DEFAULT 20,
    p_primary_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(exercise_name VARCHAR, involvement_percentage INTEGER, is_primary BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    SELECT emm.exercise_name::VARCHAR, emm.involvement_percentage, emm.is_primary
    FROM exercise_muscle_mappings emm
    WHERE LOWER(emm.muscle_group) = LOWER(p_muscle)
    AND emm.involvement_percentage >= p_min_involvement
    AND (NOT p_primary_only OR emm.is_primary = TRUE)
    ORDER BY emm.involvement_percentage DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to update user workout pattern after completing a workout
CREATE OR REPLACE FUNCTION update_user_workout_pattern(
    p_user_id UUID,
    p_exercise_name VARCHAR,
    p_sets_completed INTEGER,
    p_reps_completed INTEGER,
    p_weight_used DECIMAL,
    p_adjustment_type VARCHAR DEFAULT 'none'
)
RETURNS VOID AS $$
DECLARE
    v_existing_sessions INTEGER;
    v_existing_avg_sets DECIMAL;
    v_existing_avg_reps DECIMAL;
    v_existing_avg_weight DECIMAL;
BEGIN
    -- Get existing values
    SELECT total_sessions, avg_sets_completed, avg_reps_completed, avg_weight_used
    INTO v_existing_sessions, v_existing_avg_sets, v_existing_avg_reps, v_existing_avg_weight
    FROM user_workout_patterns
    WHERE user_id = p_user_id AND exercise_name = p_exercise_name;

    IF v_existing_sessions IS NULL THEN
        -- Insert new record
        INSERT INTO user_workout_patterns (
            user_id, exercise_name, avg_sets_completed, avg_reps_completed,
            avg_weight_used, total_sessions, last_performed_at, typical_adjustment
        ) VALUES (
            p_user_id, p_exercise_name, p_sets_completed, p_reps_completed,
            p_weight_used, 1, NOW(), p_adjustment_type
        );
    ELSE
        -- Update with rolling average
        UPDATE user_workout_patterns
        SET
            avg_sets_completed = ((v_existing_avg_sets * v_existing_sessions) + p_sets_completed) / (v_existing_sessions + 1),
            avg_reps_completed = ((v_existing_avg_reps * v_existing_sessions) + p_reps_completed) / (v_existing_sessions + 1),
            avg_weight_used = ((v_existing_avg_weight * v_existing_sessions) + p_weight_used) / (v_existing_sessions + 1),
            total_sessions = v_existing_sessions + 1,
            last_performed_at = NOW(),
            typical_adjustment = p_adjustment_type,
            updated_at = NOW()
        WHERE user_id = p_user_id AND exercise_name = p_exercise_name;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PART 9: Add constraint to ensure min_sets <= max_sets
-- ============================================================================

-- Add a check constraint to ensure min_sets is always <= max_sets
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'check_min_max_sets_valid'
    ) THEN
        ALTER TABLE user_rep_range_preferences
        ADD CONSTRAINT check_min_max_sets_valid
        CHECK (min_sets_per_exercise <= max_sets_per_exercise);
    END IF;
END $$;

-- ============================================================================
-- PART 10: Grant execute permissions on functions
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_exercise_muscles(VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION exercise_involves_muscle(VARCHAR, VARCHAR, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_exercises_for_muscle(VARCHAR, INTEGER, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_workout_pattern(UUID, VARCHAR, INTEGER, INTEGER, DECIMAL, VARCHAR) TO authenticated;

-- ============================================================================
-- Migration complete
-- ============================================================================

COMMENT ON TABLE user_workout_patterns IS 'Tracks historical workout patterns per user per exercise for personalized recommendations';
COMMENT ON TABLE exercise_muscle_mappings IS 'Maps exercises to muscle groups with involvement percentages for compound exercise tracking';
COMMENT ON FUNCTION get_exercise_muscles IS 'Returns all muscles targeted by a given exercise with involvement percentages';
COMMENT ON FUNCTION exercise_involves_muscle IS 'Checks if an exercise involves a specific muscle above a minimum threshold';
COMMENT ON FUNCTION get_exercises_for_muscle IS 'Returns all exercises that target a specific muscle group';
COMMENT ON FUNCTION update_user_workout_pattern IS 'Updates or creates a workout pattern record with rolling averages';
