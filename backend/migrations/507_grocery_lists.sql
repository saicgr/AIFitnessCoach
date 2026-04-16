-- Migration: 507_grocery_lists.sql
-- Description: Grocery lists derived from a meal plan or single recipe.
--   Lists persist so users can check off items across days; offline state synced via Drift.
--   Aisles are populated by an LLM classifier (cached), constrained to a known set.
-- Created: 2026-04-14

CREATE TABLE IF NOT EXISTS grocery_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_plan_id UUID REFERENCES meal_plans(id) ON DELETE SET NULL,
    source_recipe_id UUID REFERENCES user_recipes(id) ON DELETE SET NULL,  -- for single-recipe lists
    name TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS grocery_list_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID NOT NULL REFERENCES grocery_lists(id) ON DELETE CASCADE,
    ingredient_name TEXT NOT NULL,
    quantity NUMERIC(10,2),
    unit TEXT,
    aisle TEXT
        CHECK (aisle IS NULL OR aisle IN
              ('produce','dairy','meat_seafood','pantry','frozen','bakery','beverages','condiments','spices','snacks','household','other')),
    is_checked BOOLEAN DEFAULT FALSE,
    is_staple_suppressed BOOLEAN DEFAULT FALSE,  -- staples filter (oil/salt/pepper) per user prefs
    source_recipe_ids UUID[] DEFAULT '{}',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grocery_lists_user
    ON grocery_lists (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_plan
    ON grocery_lists (meal_plan_id) WHERE meal_plan_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_grocery_list_items_list_aisle
    ON grocery_list_items (list_id, aisle, is_checked);

ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_list_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own grocery lists" ON grocery_lists;
CREATE POLICY "Users manage own grocery lists"
    ON grocery_lists FOR ALL
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own grocery items" ON grocery_list_items;
CREATE POLICY "Users manage own grocery items"
    ON grocery_list_items FOR ALL
    USING (EXISTS (SELECT 1 FROM grocery_lists l WHERE l.id = list_id AND l.user_id = auth.uid()))
    WITH CHECK (EXISTS (SELECT 1 FROM grocery_lists l WHERE l.id = list_id AND l.user_id = auth.uid()));

DROP POLICY IF EXISTS "Service role full access grocery lists" ON grocery_lists;
CREATE POLICY "Service role full access grocery lists"
    ON grocery_lists FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS "Service role full access grocery items" ON grocery_list_items;
CREATE POLICY "Service role full access grocery items"
    ON grocery_list_items FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION set_grocery_lists_updated_at()
RETURNS TRIGGER SECURITY DEFINER SET search_path = public
AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_grocery_lists_updated_at ON grocery_lists;
CREATE TRIGGER trg_grocery_lists_updated_at
    BEFORE UPDATE ON grocery_lists
    FOR EACH ROW EXECUTE FUNCTION set_grocery_lists_updated_at();

DROP TRIGGER IF EXISTS trg_grocery_list_items_updated_at ON grocery_list_items;
CREATE TRIGGER trg_grocery_list_items_updated_at
    BEFORE UPDATE ON grocery_list_items
    FOR EACH ROW EXECUTE FUNCTION set_grocery_lists_updated_at();

-- User staples table (oil/salt/pepper etc.) suppressed by default in generated lists
CREATE TABLE IF NOT EXISTS user_grocery_staples (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ingredient_name TEXT NOT NULL,
    PRIMARY KEY (user_id, ingredient_name)
);
ALTER TABLE user_grocery_staples ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own staples" ON user_grocery_staples;
CREATE POLICY "Users manage own staples"
    ON user_grocery_staples FOR ALL
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Service role full access staples" ON user_grocery_staples;
CREATE POLICY "Service role full access staples"
    ON user_grocery_staples FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

COMMENT ON TABLE grocery_lists IS
    'Persisted grocery lists derived from a meal plan or single recipe; supports per-item checkoff and offline sync.';
COMMENT ON COLUMN grocery_list_items.is_staple_suppressed IS
    'TRUE when this item was hidden by the staples filter; user toggle to "show staples" reveals them.';
