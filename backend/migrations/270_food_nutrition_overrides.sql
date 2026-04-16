-- Migration 270: Food Nutrition Overrides
-- Purpose: Curated, verified nutrition data that takes priority over the base food_database.
-- Fixes known issues: inflated calories (dosa=639 instead of 150), duplicate branded entries (eggs).
-- ── Table ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS food_nutrition_overrides (
    id SERIAL PRIMARY KEY,
    food_name_normalized TEXT NOT NULL UNIQUE,       -- lowercase match key (e.g. 'dosa')
    display_name TEXT NOT NULL,                       -- user-facing name (e.g. 'Dosa (plain)')
    calories_per_100g REAL NOT NULL,
    protein_per_100g REAL NOT NULL,
    carbs_per_100g REAL NOT NULL,
    fat_per_100g REAL NOT NULL,
    fiber_per_100g REAL NOT NULL DEFAULT 0,
    sugar_per_100g REAL DEFAULT NULL,
    default_weight_per_piece_g REAL DEFAULT NULL,     -- dosa=100g, egg=50g
    default_serving_g REAL DEFAULT NULL,              -- typical serving size
    source TEXT DEFAULT 'manual',                     -- 'manual', 'usda_verified'
    notes TEXT DEFAULT NULL,
    variant_names TEXT[] DEFAULT NULL,                 -- e.g. {'dosai', 'thosai'}
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_food_overrides_active
    ON food_nutrition_overrides (is_active)
    WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_food_overrides_variants
    ON food_nutrition_overrides USING GIN (variant_names)
    WHERE variant_names IS NOT NULL;

-- ── RLS ────────────────────────────────────────────────────────────

ALTER TABLE food_nutrition_overrides ENABLE ROW LEVEL SECURITY;

-- Service role: full access
CREATE POLICY "service_role_full_access"
    ON food_nutrition_overrides
    FOR ALL
    TO service_role
    USING (TRUE)
    WITH CHECK (TRUE);

-- Authenticated users: read-only on active rows
CREATE POLICY "authenticated_read_active"
    ON food_nutrition_overrides
    FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

-- ── Updated-at trigger ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_food_overrides_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_food_overrides_updated_at
    BEFORE UPDATE ON food_nutrition_overrides
    FOR EACH ROW
    EXECUTE FUNCTION update_food_overrides_updated_at();

-- ── Seed data ──────────────────────────────────────────────────────
-- Sources: USDA FoodData Central, IFCT (Indian Food Composition Tables)
-- All values are per 100g of cooked/prepared food unless noted.

INSERT INTO food_nutrition_overrides
    (food_name_normalized, display_name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, default_weight_per_piece_g, default_serving_g, source, variant_names, notes)
VALUES
    -- ── Indian breads & snacks ──
    ('dosa', 'Dosa (plain)', 150, 3.9, 25.0, 3.7, 1.0, 100, 100, 'usda_verified',
     ARRAY['dosai', 'thosai', 'plain dosa'], 'Plain rice-lentil crepe, ~100g each'),

    ('masala dosa', 'Masala Dosa', 165, 4.2, 26.0, 5.0, 1.5, 150, 150, 'usda_verified',
     ARRAY['masala dosai', 'potato dosa'], 'Dosa with potato filling, ~150g each'),

    ('roti', 'Roti (whole wheat)', 300, 9.0, 50.0, 7.0, 4.0, 40, 80, 'usda_verified',
     ARRAY['chapati', 'chapatti', 'phulka', 'wheat roti'], 'Whole wheat flatbread, ~40g each'),

    ('paratha', 'Paratha (plain)', 320, 7.0, 45.0, 13.0, 3.0, 80, 80, 'usda_verified',
     ARRAY['parantha', 'plain paratha', 'wheat paratha'], 'Pan-fried wheat flatbread, ~80g each'),

    ('aloo paratha', 'Aloo Paratha', 260, 5.5, 36.0, 11.0, 2.5, 120, 120, 'usda_verified',
     ARRAY['potato paratha', 'aloo parantha'], 'Stuffed potato paratha, ~120g each'),

    ('idli', 'Idli', 130, 4.0, 24.0, 1.5, 1.0, 40, 120, 'usda_verified',
     ARRAY['idly', 'rice idli'], 'Steamed rice-lentil cake, ~40g each'),

    ('naan', 'Naan', 290, 8.0, 50.0, 5.0, 2.0, 90, 90, 'usda_verified',
     ARRAY['plain naan', 'tandoori naan'], 'Leavened oven-baked bread, ~90g each'),

    ('samosa', 'Samosa (vegetable)', 260, 4.5, 30.0, 14.0, 2.0, 80, 80, 'usda_verified',
     ARRAY['veg samosa', 'aloo samosa', 'potato samosa'], 'Fried pastry with potato filling, ~80g each'),

    ('puri', 'Puri', 350, 7.0, 48.0, 15.0, 2.0, 25, 75, 'usda_verified',
     ARRAY['poori', 'deep fried bread'], 'Deep-fried wheat bread, ~25g each'),

    ('uttapam', 'Uttapam', 155, 4.5, 24.0, 4.5, 1.5, 120, 120, 'usda_verified',
     ARRAY['uthappam', 'utthapam'], 'Thick rice-lentil pancake with toppings, ~120g each'),

    ('vada', 'Medu Vada', 290, 10.0, 30.0, 15.0, 3.0, 50, 100, 'usda_verified',
     ARRAY['medu vada', 'urad vada', 'vadai'], 'Deep-fried lentil donut, ~50g each'),

    -- ── Indian curries & dal ──
    ('dal', 'Dal (cooked lentils)', 105, 7.0, 15.0, 2.0, 4.0, NULL, 200, 'usda_verified',
     ARRAY['dhal', 'daal', 'lentil curry', 'toor dal', 'moong dal'], 'Cooked lentil curry, ~200g serving'),

    ('paneer', 'Paneer', 265, 18.0, 2.0, 21.0, 0, 30, 100, 'usda_verified',
     ARRAY['cottage cheese', 'indian cheese'], 'Fresh Indian cheese, ~30g per cube'),

    ('rajma', 'Rajma (kidney bean curry)', 125, 7.0, 18.0, 2.5, 5.0, NULL, 200, 'usda_verified',
     ARRAY['kidney bean curry', 'rajma masala'], 'Cooked kidney bean curry, ~200g serving'),

    ('chole', 'Chole (chickpea curry)', 140, 7.5, 20.0, 3.5, 5.0, NULL, 200, 'usda_verified',
     ARRAY['chana masala', 'chhole', 'chickpea curry'], 'Cooked chickpea curry, ~200g serving'),

    -- ── Rice ──
    ('rice', 'Rice (cooked, white)', 130, 2.7, 28.0, 0.3, 0.4, NULL, 200, 'usda_verified',
     ARRAY['white rice', 'cooked rice', 'steamed rice', 'plain rice'], 'Cooked white rice, ~200g per serving'),

    ('brown rice', 'Brown Rice (cooked)', 112, 2.6, 23.5, 0.9, 1.8, NULL, 200, 'usda_verified',
     ARRAY['cooked brown rice'], 'Cooked brown rice, ~200g per serving'),

    ('biryani', 'Biryani (chicken)', 175, 10.0, 22.0, 5.5, 1.0, NULL, 300, 'usda_verified',
     ARRAY['chicken biryani', 'biriyani', 'briyani'], 'Chicken biryani, ~300g per serving'),

    -- ── Eggs ──
    ('egg', 'Whole Egg', 155, 13.0, 1.1, 11.0, 0, 50, 100, 'usda_verified',
     ARRAY['eggs', 'whole egg', 'hen egg', 'chicken egg', 'boiled egg', 'fried egg'],
     'Standard large egg, ~50g each. Boiled/fried similar per 100g.'),

    ('egg white', 'Egg White', 52, 11.0, 0.7, 0.2, 0, 33, 99, 'usda_verified',
     ARRAY['egg whites'], 'Egg white only, ~33g per egg white'),

    -- ── Common proteins ──
    ('chicken breast', 'Chicken Breast (cooked)', 165, 31.0, 0, 3.6, 0, NULL, 150, 'usda_verified',
     ARRAY['grilled chicken breast', 'baked chicken breast', 'cooked chicken breast'],
     'Skinless boneless cooked chicken breast'),

    ('chicken thigh', 'Chicken Thigh (cooked)', 209, 26.0, 0, 11.0, 0, NULL, 100, 'usda_verified',
     ARRAY['cooked chicken thigh'], 'Skin-on cooked chicken thigh'),

    -- ── Common foods ──
    ('banana', 'Banana', 89, 1.1, 22.8, 0.3, 2.6, 120, 120, 'usda_verified',
     ARRAY['bananas', 'ripe banana'], 'Medium banana, ~120g each (peeled)'),

    ('apple', 'Apple', 52, 0.3, 13.8, 0.2, 2.4, 180, 180, 'usda_verified',
     ARRAY['apples', 'green apple', 'red apple'], 'Medium apple, ~180g each'),

    ('milk', 'Whole Milk', 61, 3.2, 4.8, 3.3, 0, NULL, 250, 'usda_verified',
     ARRAY['whole milk', 'full cream milk', 'dairy milk'], 'Whole milk, ~250ml per glass'),

    ('oats', 'Oats (dry)', 379, 13.2, 67.7, 6.5, 10.1, NULL, 40, 'usda_verified',
     ARRAY['rolled oats', 'oatmeal', 'porridge oats'], 'Dry rolled oats, ~40g per serving'),

    ('peanut butter', 'Peanut Butter', 588, 25.0, 20.0, 50.0, 6.0, NULL, 32, 'usda_verified',
     ARRAY['peanut butter spread'], 'Natural peanut butter, ~32g (2 tbsp) per serving'),

    ('almonds', 'Almonds', 579, 21.2, 21.7, 49.9, 12.5, 1.2, 30, 'usda_verified',
     ARRAY['almond', 'raw almonds', 'whole almonds'], '~1.2g per almond, ~30g (23 almonds) per serving'),

    ('greek yogurt', 'Greek Yogurt (plain)', 97, 9.0, 3.6, 5.0, 0, NULL, 170, 'usda_verified',
     ARRAY['plain greek yogurt', 'greek yoghurt'], 'Plain full-fat Greek yogurt, ~170g per serving'),

    ('bread', 'Bread (white)', 265, 9.0, 49.0, 3.2, 2.7, 30, 60, 'usda_verified',
     ARRAY['white bread', 'sandwich bread', 'bread slice'], 'White bread, ~30g per slice'),

    ('whole wheat bread', 'Whole Wheat Bread', 247, 13.0, 43.0, 3.4, 7.0, 35, 70, 'usda_verified',
     ARRAY['wheat bread', 'brown bread', 'wholemeal bread'], 'Whole wheat bread, ~35g per slice')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
    default_serving_g = EXCLUDED.default_serving_g,
    source = EXCLUDED.source,
    variant_names = EXCLUDED.variant_names,
    notes = EXCLUDED.notes,
    updated_at = NOW();
