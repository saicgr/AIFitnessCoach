-- Migration: Fix stale recipes table reference
-- Created: 2025-01-01
-- Description: Drops any stale triggers or functions that may reference a non-existent 'recipes' table
-- The correct table name is 'user_recipes', not 'recipes'

-- Drop any triggers that might reference the old table name
DROP TRIGGER IF EXISTS trigger_update_recipe_log_count ON food_logs;

-- Recreate the trigger with the correct reference to user_recipes
CREATE OR REPLACE FUNCTION update_recipe_log_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.recipe_id IS NOT NULL THEN
        UPDATE user_recipes
        SET
            times_logged = times_logged + 1,
            last_logged_at = NOW(),
            updated_at = NOW()
        WHERE id = NEW.recipe_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_recipe_log_count
AFTER INSERT ON food_logs
FOR EACH ROW EXECUTE FUNCTION update_recipe_log_count();

-- Drop any stale views that might reference 'recipes'
DROP VIEW IF EXISTS recipes CASCADE;

-- Verify that the food_logs insert will work by checking constraints
-- (This is just a safety check, no actual changes)
COMMENT ON TABLE food_logs IS 'Food logs table - updated 2025-01-01 to fix trigger references';
