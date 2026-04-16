-- Migration: 504_meal_plans.sql
-- Description: Day-level meal planner with simulation + apply-to-today.
--   meal_plans hold a day's intent (breakfast/lunch/dinner/snack slots).
--   meal_plan_items hold each line, either referencing a recipe_id or storing ad-hoc food_items JSON.
--   target_snapshot captures the user's daily macro goals at create-time so the plan stays comparable.
-- Created: 2026-04-14

CREATE TABLE IF NOT EXISTS meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT,                      -- nullable; "Tuesday cut", "High-protein day"
    plan_date DATE,                 -- NULL when is_template=TRUE
    is_template BOOLEAN DEFAULT FALSE,
    target_snapshot JSONB,          -- {calories, protein_g, carbs_g, fat_g, fiber_g}
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS meal_plan_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    slot_order INT DEFAULT 0,       -- preserves intra-meal ordering
    recipe_id UUID REFERENCES user_recipes(id) ON DELETE SET NULL,
    food_items JSONB,               -- ad-hoc items when no recipe_id (same shape as meal_templates.food_items)
    servings NUMERIC(5,2) DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- An item must reference EITHER a recipe OR ad-hoc food_items (xor)
    CHECK ( (recipe_id IS NOT NULL)::int + (food_items IS NOT NULL)::int = 1 )
);

CREATE INDEX IF NOT EXISTS idx_meal_plans_user_date
    ON meal_plans (user_id, plan_date) WHERE plan_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_template
    ON meal_plans (user_id) WHERE is_template = TRUE;
CREATE INDEX IF NOT EXISTS idx_meal_plan_items_plan_meal
    ON meal_plan_items (plan_id, meal_type, slot_order);

ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own meal plans" ON meal_plans;
CREATE POLICY "Users manage own meal plans"
    ON meal_plans FOR ALL
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own meal plan items" ON meal_plan_items;
CREATE POLICY "Users manage own meal plan items"
    ON meal_plan_items FOR ALL
    USING (EXISTS (SELECT 1 FROM meal_plans p WHERE p.id = plan_id AND p.user_id = auth.uid()))
    WITH CHECK (EXISTS (SELECT 1 FROM meal_plans p WHERE p.id = plan_id AND p.user_id = auth.uid()));

DROP POLICY IF EXISTS "Service role full access meal plans" ON meal_plans;
CREATE POLICY "Service role full access meal plans"
    ON meal_plans FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS "Service role full access meal plan items" ON meal_plan_items;
CREATE POLICY "Service role full access meal plan items"
    ON meal_plan_items FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION set_meal_plans_updated_at()
RETURNS TRIGGER SECURITY DEFINER SET search_path = public
AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_meal_plans_updated_at ON meal_plans;
CREATE TRIGGER trg_meal_plans_updated_at
    BEFORE UPDATE ON meal_plans
    FOR EACH ROW EXECUTE FUNCTION set_meal_plans_updated_at();

COMMENT ON TABLE meal_plans IS
    'A day''s planned meals with macro target snapshot. Used by Meal Planner for what-if + apply-to-today flows.';
COMMENT ON COLUMN meal_plans.target_snapshot IS
    'Macro/calorie targets captured at plan creation so AI swap suggestions stay reproducible.';
COMMENT ON COLUMN meal_plan_items.food_items IS
    'Ad-hoc items when no recipe is attached. Same shape as meal_templates.food_items.';
