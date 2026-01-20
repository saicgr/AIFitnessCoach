-- Migration: Muscle Focus Points & Primary Goal
-- Created: 2025-01-19
-- Purpose: Add muscle focus points allocation and primary goal for workout customization

-- ============================================
-- Add muscle_focus_points column to users
-- ============================================
-- Stores user's muscle focus allocations (5 points total)
-- Example: {"triceps": 2, "lats": 1, "obliques": 2}
ALTER TABLE users
ADD COLUMN IF NOT EXISTS muscle_focus_points JSONB DEFAULT '{}';

COMMENT ON COLUMN users.muscle_focus_points IS 'Muscle focus point allocations (max 5 total). Format: {"muscle_name": points}';

-- ============================================
-- Add primary_goal column to users
-- ============================================
-- Stores user's primary training goal
-- Values: 'muscle_hypertrophy', 'muscle_strength', 'strength_hypertrophy'
ALTER TABLE users
ADD COLUMN IF NOT EXISTS primary_goal TEXT;

COMMENT ON COLUMN users.primary_goal IS 'Primary training goal: muscle_hypertrophy, muscle_strength, or strength_hypertrophy';

-- ============================================
-- Create index for querying users by primary goal
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_primary_goal ON users(primary_goal) WHERE primary_goal IS NOT NULL;

-- ============================================
-- Function: Validate muscle focus points total
-- ============================================
CREATE OR REPLACE FUNCTION validate_muscle_focus_points()
RETURNS TRIGGER AS $$
DECLARE
    total_points INT;
BEGIN
    -- Calculate total points from JSONB
    SELECT COALESCE(SUM((value)::int), 0) INTO total_points
    FROM jsonb_each_text(NEW.muscle_focus_points);

    -- Validate total doesn't exceed 5
    IF total_points > 5 THEN
        RAISE EXCEPTION 'Muscle focus points cannot exceed 5. Current total: %', total_points;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Trigger: Validate muscle focus points on insert/update
-- ============================================
DROP TRIGGER IF EXISTS trigger_validate_muscle_focus_points ON users;
CREATE TRIGGER trigger_validate_muscle_focus_points
    BEFORE INSERT OR UPDATE OF muscle_focus_points ON users
    FOR EACH ROW
    WHEN (NEW.muscle_focus_points IS NOT NULL AND NEW.muscle_focus_points != '{}')
    EXECUTE FUNCTION validate_muscle_focus_points();

-- ============================================
-- Reference data: Available muscle groups for focus
-- ============================================
COMMENT ON COLUMN users.muscle_focus_points IS 'Available muscles: triceps, upper_traps, obliques, neck, lats, chest, shoulders, biceps, forearms, lower_back, upper_back, abs, quadriceps, hamstrings, glutes, calves, hip_flexors, adductors, abductors';
