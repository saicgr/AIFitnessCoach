-- ============================================================================
-- Migration 066: Support multi-select nutrition goals
-- ============================================================================
-- This migration changes nutrition_goal from a single TEXT to TEXT[] (array)
-- to allow users to select multiple nutrition goals during onboarding.
-- ============================================================================

-- Step 1: Add new column for multiple goals
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS nutrition_goals TEXT[] DEFAULT '{}';

-- Step 2: Migrate existing single goals to array
UPDATE nutrition_preferences
SET nutrition_goals = ARRAY[nutrition_goal]
WHERE nutrition_goal IS NOT NULL AND nutrition_goals = '{}';

-- Step 3: Keep nutrition_goal for backward compatibility but make it nullable
-- The primary goal will be the first element of nutrition_goals array
-- We don't drop the old column to maintain backward compatibility

-- Step 4: Create a function to get primary goal from goals array
CREATE OR REPLACE FUNCTION get_primary_nutrition_goal(goals TEXT[])
RETURNS TEXT AS $$
BEGIN
  IF goals IS NULL OR array_length(goals, 1) IS NULL THEN
    RETURN 'maintain';
  END IF;
  RETURN goals[1];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 5: Add comment for documentation
COMMENT ON COLUMN nutrition_preferences.nutrition_goals IS 'Array of nutrition goals (multi-select). Valid values: lose_fat, build_muscle, maintain, improve_energy, eat_healthier, recomposition';
COMMENT ON COLUMN nutrition_preferences.nutrition_goal IS 'DEPRECATED: Legacy single goal column. Use nutrition_goals array instead. Kept for backward compatibility.';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
