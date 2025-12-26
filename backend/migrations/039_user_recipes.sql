-- Migration: User Recipes
-- Created: 2025-12-25
-- Description: Create tables for user recipe management (MacroFactor-style recipe builder)

-- ============================================================
-- USER RECIPES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS user_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Recipe metadata
    name VARCHAR(255) NOT NULL,
    description TEXT,
    servings INTEGER NOT NULL DEFAULT 1,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,

    -- Instructions (can be null for simple ingredient combinations)
    instructions TEXT,

    -- Recipe image (optional)
    image_url TEXT,

    -- Category/tags
    category VARCHAR(50),  -- 'breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'drink'
    cuisine VARCHAR(50),   -- 'indian', 'italian', 'mexican', etc.
    tags TEXT[],           -- ['high-protein', 'low-carb', 'vegetarian', etc.]

    -- Calculated nutrition per serving (auto-calculated from ingredients)
    calories_per_serving INTEGER,
    protein_per_serving_g DECIMAL(8,2),
    carbs_per_serving_g DECIMAL(8,2),
    fat_per_serving_g DECIMAL(8,2),
    fiber_per_serving_g DECIMAL(8,2),
    sugar_per_serving_g DECIMAL(8,2),

    -- Micronutrients per serving (top ones for quick display)
    vitamin_d_per_serving_iu DECIMAL(8,2),
    calcium_per_serving_mg DECIMAL(8,2),
    iron_per_serving_mg DECIMAL(8,2),
    omega3_per_serving_g DECIMAL(8,2),
    sodium_per_serving_mg DECIMAL(8,2),

    -- Full micronutrients JSON (for detailed view)
    micronutrients_per_serving JSONB DEFAULT '{}',

    -- Usage stats
    times_logged INTEGER DEFAULT 0,
    last_logged_at TIMESTAMPTZ,

    -- Source (if imported)
    source_url TEXT,        -- URL if imported from website
    source_type VARCHAR(20) DEFAULT 'manual',  -- 'manual', 'imported', 'ai_generated'

    -- Sharing
    is_public BOOLEAN DEFAULT FALSE,
    shared_with_community BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ  -- Soft delete
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_recipes_user ON user_recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_recipes_user_not_deleted ON user_recipes(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_user_recipes_name ON user_recipes(name);
CREATE INDEX IF NOT EXISTS idx_user_recipes_category ON user_recipes(category);
CREATE INDEX IF NOT EXISTS idx_user_recipes_cuisine ON user_recipes(cuisine);
CREATE INDEX IF NOT EXISTS idx_user_recipes_tags ON user_recipes USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_user_recipes_times_logged ON user_recipes(times_logged DESC);
CREATE INDEX IF NOT EXISTS idx_user_recipes_is_public ON user_recipes(is_public) WHERE is_public = TRUE;

COMMENT ON TABLE user_recipes IS 'User-created recipes with ingredients and calculated nutrition';

-- ============================================================
-- RECIPE INGREDIENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES user_recipes(id) ON DELETE CASCADE,

    -- Ingredient identification
    ingredient_order INTEGER NOT NULL DEFAULT 0,  -- Order in recipe
    food_name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),  -- Optional brand for specific products

    -- Amount
    amount DECIMAL(10,2) NOT NULL,
    unit VARCHAR(30) NOT NULL,  -- 'g', 'ml', 'cup', 'tbsp', 'tsp', 'oz', 'piece', etc.
    amount_grams DECIMAL(10,2),  -- Converted to grams for calculation

    -- Optional: Link to barcode product
    barcode VARCHAR(50),

    -- Nutrition per amount specified
    calories DECIMAL(8,2),
    protein_g DECIMAL(8,2),
    carbs_g DECIMAL(8,2),
    fat_g DECIMAL(8,2),
    fiber_g DECIMAL(8,2),
    sugar_g DECIMAL(8,2),

    -- Micronutrients (key ones)
    vitamin_a_ug DECIMAL(8,2),
    vitamin_c_mg DECIMAL(8,2),
    vitamin_d_iu DECIMAL(8,2),
    vitamin_e_mg DECIMAL(8,2),
    vitamin_k_ug DECIMAL(8,2),
    vitamin_b6_mg DECIMAL(8,2),
    vitamin_b12_ug DECIMAL(8,2),
    folate_ug DECIMAL(8,2),
    calcium_mg DECIMAL(8,2),
    iron_mg DECIMAL(8,2),
    magnesium_mg DECIMAL(8,2),
    zinc_mg DECIMAL(8,2),
    selenium_ug DECIMAL(8,2),
    potassium_mg DECIMAL(8,2),
    sodium_mg DECIMAL(8,2),
    omega3_g DECIMAL(8,2),
    omega6_g DECIMAL(8,2),
    cholesterol_mg DECIMAL(8,2),

    -- Full micronutrients JSON (for completeness)
    micronutrients JSONB DEFAULT '{}',

    -- Notes
    notes TEXT,  -- e.g., "finely chopped", "room temperature"
    is_optional BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_order ON recipe_ingredients(recipe_id, ingredient_order);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_barcode ON recipe_ingredients(barcode) WHERE barcode IS NOT NULL;

COMMENT ON TABLE recipe_ingredients IS 'Individual ingredients in a recipe with nutrition data';

-- ============================================================
-- TRIGGER: Auto-calculate recipe nutrition when ingredients change
-- ============================================================

CREATE OR REPLACE FUNCTION recalculate_recipe_nutrition()
RETURNS TRIGGER AS $$
DECLARE
    recipe_servings INTEGER;
    total_calories DECIMAL;
    total_protein DECIMAL;
    total_carbs DECIMAL;
    total_fat DECIMAL;
    total_fiber DECIMAL;
    total_sugar DECIMAL;
    total_vitamin_d DECIMAL;
    total_calcium DECIMAL;
    total_iron DECIMAL;
    total_omega3 DECIMAL;
    total_sodium DECIMAL;
BEGIN
    -- Get the recipe's servings
    SELECT servings INTO recipe_servings FROM user_recipes WHERE id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    IF recipe_servings IS NULL OR recipe_servings < 1 THEN
        recipe_servings := 1;
    END IF;

    -- Calculate totals from all ingredients
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
        total_calories,
        total_protein,
        total_carbs,
        total_fat,
        total_fiber,
        total_sugar,
        total_vitamin_d,
        total_calcium,
        total_iron,
        total_omega3,
        total_sodium
    FROM recipe_ingredients
    WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id);

    -- Update the recipe with per-serving values
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

-- Create triggers
DROP TRIGGER IF EXISTS trigger_recalc_nutrition_insert ON recipe_ingredients;
DROP TRIGGER IF EXISTS trigger_recalc_nutrition_update ON recipe_ingredients;
DROP TRIGGER IF EXISTS trigger_recalc_nutrition_delete ON recipe_ingredients;

CREATE TRIGGER trigger_recalc_nutrition_insert
AFTER INSERT ON recipe_ingredients
FOR EACH ROW EXECUTE FUNCTION recalculate_recipe_nutrition();

CREATE TRIGGER trigger_recalc_nutrition_update
AFTER UPDATE ON recipe_ingredients
FOR EACH ROW EXECUTE FUNCTION recalculate_recipe_nutrition();

CREATE TRIGGER trigger_recalc_nutrition_delete
AFTER DELETE ON recipe_ingredients
FOR EACH ROW EXECUTE FUNCTION recalculate_recipe_nutrition();

-- ============================================================
-- ADD recipe_id TO FOOD_LOGS (for logging recipes)
-- ============================================================

ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS recipe_id UUID REFERENCES user_recipes(id);
CREATE INDEX IF NOT EXISTS idx_food_logs_recipe ON food_logs(recipe_id) WHERE recipe_id IS NOT NULL;

-- ============================================================
-- TRIGGER: Update recipe times_logged when logged
-- ============================================================

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

DROP TRIGGER IF EXISTS trigger_update_recipe_log_count ON food_logs;
CREATE TRIGGER trigger_update_recipe_log_count
AFTER INSERT ON food_logs
FOR EACH ROW EXECUTE FUNCTION update_recipe_log_count();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE user_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;

-- User Recipes policies
CREATE POLICY "Users can view their own recipes"
    ON user_recipes FOR SELECT
    USING (user_id = auth.uid() OR is_public = TRUE);

CREATE POLICY "Users can create recipes"
    ON user_recipes FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own recipes"
    ON user_recipes FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own recipes"
    ON user_recipes FOR DELETE
    USING (user_id = auth.uid());

-- Recipe Ingredients policies (inherit from recipe ownership)
CREATE POLICY "Users can view ingredients of accessible recipes"
    ON recipe_ingredients FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_recipes
            WHERE id = recipe_ingredients.recipe_id
            AND (user_id = auth.uid() OR is_public = TRUE)
        )
    );

CREATE POLICY "Users can add ingredients to their recipes"
    ON recipe_ingredients FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_recipes
            WHERE id = recipe_ingredients.recipe_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update ingredients of their recipes"
    ON recipe_ingredients FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM user_recipes
            WHERE id = recipe_ingredients.recipe_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete ingredients from their recipes"
    ON recipe_ingredients FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM user_recipes
            WHERE id = recipe_ingredients.recipe_id
            AND user_id = auth.uid()
        )
    );

-- ============================================================
-- HELPER VIEWS
-- ============================================================

-- View: Recipes with ingredient count
CREATE OR REPLACE VIEW recipes_with_stats AS
SELECT
    r.*,
    COUNT(ri.id) AS ingredient_count,
    r.prep_time_minutes + r.cook_time_minutes AS total_time_minutes
FROM user_recipes r
LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
WHERE r.deleted_at IS NULL
GROUP BY r.id;

-- View: Popular community recipes
CREATE OR REPLACE VIEW popular_community_recipes AS
SELECT *
FROM user_recipes
WHERE is_public = TRUE
AND deleted_at IS NULL
ORDER BY times_logged DESC, created_at DESC
LIMIT 100;
