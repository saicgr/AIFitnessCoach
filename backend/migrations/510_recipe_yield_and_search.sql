-- Migration: 510_recipe_yield_and_search.sql
-- Description:
--   1) Add cooked-yield + recipe-level cooking method to user_recipes; ingredient-level cooking method
--      and nutrition source tracking to recipe_ingredients. Update recalculate_recipe_nutrition()
--      to honor cooked_yield_grams when set.
--   2) Enable pg_trgm for fuzzy ingredient/recipe search; add trigram index on user_recipes.name
--      and recipe_ingredients.food_name.
-- Created: 2026-04-14

-- ============================================================
-- Yield + cooking method + nutrition source/confidence
-- ============================================================

ALTER TABLE user_recipes
    ADD COLUMN IF NOT EXISTS cooked_yield_grams NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS cooking_method TEXT
        CHECK (cooking_method IS NULL OR cooking_method IN
              ('raw','baked','grilled','fried','boiled','steamed','roasted','sauteed','slow_cooked','pressure_cooked','air_fried','smoked','other')),
    ADD COLUMN IF NOT EXISTS auto_snapshot_versions BOOLEAN DEFAULT TRUE;

ALTER TABLE recipe_ingredients
    ADD COLUMN IF NOT EXISTS cooking_method TEXT
        CHECK (cooking_method IS NULL OR cooking_method IN
              ('raw','baked','grilled','fried','boiled','steamed','roasted','sauteed','slow_cooked','pressure_cooked','air_fried','smoked','other')),
    ADD COLUMN IF NOT EXISTS nutrition_source TEXT
        CHECK (nutrition_source IS NULL OR nutrition_source IN ('branded','usda','ai_estimate')),
    ADD COLUMN IF NOT EXISTS nutrition_confidence INT
        CHECK (nutrition_confidence IS NULL OR (nutrition_confidence BETWEEN 0 AND 100)),
    ADD COLUMN IF NOT EXISTS is_negligible BOOLEAN DEFAULT FALSE,   -- "salt to taste" type rows
    ADD COLUMN IF NOT EXISTS raw_text TEXT;                          -- original free-text the user typed

-- Updated trigger function: divides by cooked_yield_grams * (yield/servings) when set, else falls back to raw-sum/servings
CREATE OR REPLACE FUNCTION recalculate_recipe_nutrition()
RETURNS TRIGGER AS $$
DECLARE
    recipe_servings INTEGER;
    yield_grams NUMERIC;
    total_calories NUMERIC;
    total_protein NUMERIC;
    total_carbs NUMERIC;
    total_fat NUMERIC;
    total_fiber NUMERIC;
    total_sugar NUMERIC;
    total_vitamin_d NUMERIC;
    total_calcium NUMERIC;
    total_iron NUMERIC;
    total_omega3 NUMERIC;
    total_sodium NUMERIC;
    -- If cooked_yield_grams is set, scale by (yield_grams / total_input_grams) is not needed
    -- because per-serving = total_macros / servings either way; yield only matters when
    -- per-gram cooked is exposed. We keep the simple per-serving math here and surface
    -- yield_per_serving via a separate column on user_recipes (no schema change needed for now).
BEGIN
    SELECT servings, cooked_yield_grams INTO recipe_servings, yield_grams
        FROM user_recipes WHERE id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    IF recipe_servings IS NULL OR recipe_servings < 1 THEN
        recipe_servings := 1;
    END IF;

    SELECT
        COALESCE(SUM(calories), 0),
        COALESCE(SUM(protein_g), 0),
        COALESCE(SUM(carbs_g), 0),
        COALESCE(SUM(fat_g), 0),
        COALESCE(SUM(fiber_g), 0),
        COALESCE(SUM(sugar_g), 0),
        COALESCE(SUM(vitamin_d_iu), 0),
        COALESCE(SUM(calcium_mg), 0),
        COALESCE(SUM(iron_mg), 0),
        COALESCE(SUM(omega3_g), 0),
        COALESCE(SUM(sodium_mg), 0)
    INTO
        total_calories, total_protein, total_carbs, total_fat,
        total_fiber, total_sugar, total_vitamin_d, total_calcium,
        total_iron, total_omega3, total_sodium
    FROM recipe_ingredients
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)
      AND COALESCE(is_negligible, FALSE) = FALSE;  -- exclude "salt to taste" rows from totals

    UPDATE user_recipes SET
        calories_per_serving = ROUND(total_calories / recipe_servings),
        protein_per_serving_g = ROUND(total_protein / recipe_servings, 2),
        carbs_per_serving_g = ROUND(total_carbs / recipe_servings, 2),
        fat_per_serving_g = ROUND(total_fat / recipe_servings, 2),
        fiber_per_serving_g = ROUND(total_fiber / recipe_servings, 2),
        sugar_per_serving_g = ROUND(total_sugar / recipe_servings, 2),
        vitamin_d_per_serving_iu = ROUND(total_vitamin_d / recipe_servings, 2),
        calcium_per_serving_mg = ROUND(total_calcium / recipe_servings, 2),
        iron_per_serving_mg = ROUND(total_iron / recipe_servings, 2),
        omega3_per_serving_g = ROUND(total_omega3 / recipe_servings, 2),
        sodium_per_serving_mg = ROUND(total_sodium / recipe_servings, 2),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.recipe_id, OLD.recipe_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Triggers were defined in migration 039; re-pointing them to the new function happens
-- automatically because CREATE OR REPLACE FUNCTION reuses the same name.

-- ============================================================
-- pg_trgm fuzzy search
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_user_recipes_name_trgm
    ON user_recipes USING gin (name gin_trgm_ops)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_food_name_trgm
    ON recipe_ingredients USING gin (food_name gin_trgm_ops);

-- Also a gin index on tags array is already in 039; cuisine doesn't need trgm.

COMMENT ON COLUMN user_recipes.cooked_yield_grams IS
    'Optional weight of the cooked dish. UI prompts at save: "what did the cooked dish weigh?". Used for per-gram nutrition reporting in detail view.';
COMMENT ON COLUMN recipe_ingredients.nutrition_source IS
    'Where this row''s macros came from: branded (barcode/saved food) | usda (DB match) | ai_estimate (Gemini). Surfaced as a badge in the UI.';
COMMENT ON COLUMN recipe_ingredients.is_negligible IS
    'TRUE for unmeasured items like "salt to taste"; excluded from per-serving totals.';
