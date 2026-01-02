-- Migration: 114_cooking_conversions.sql
-- Add cooking conversion factors table for raw/cooked weight conversions
-- This addresses user feedback: "ability to input cooked grains"

-- Create cooking_conversion_factors table
CREATE TABLE IF NOT EXISTS cooking_conversion_factors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_category TEXT NOT NULL CHECK (food_category IN ('grains', 'legumes', 'meats', 'poultry', 'seafood', 'vegetables', 'eggs')),
    food_name TEXT NOT NULL,
    raw_to_cooked_ratio DECIMAL(4,2) NOT NULL CHECK (raw_to_cooked_ratio > 0),
    cooking_method TEXT NOT NULL CHECK (cooking_method IN ('boiling', 'steaming', 'grilling', 'pan_frying', 'deep_frying', 'baking', 'roasting', 'poaching', 'sauteing', 'raw')),
    calories_retention DECIMAL(4,2) DEFAULT 1.0 CHECK (calories_retention > 0 AND calories_retention <= 2),
    protein_retention DECIMAL(4,2) DEFAULT 1.0 CHECK (protein_retention > 0 AND protein_retention <= 2),
    carbs_retention DECIMAL(4,2) DEFAULT 1.0 CHECK (carbs_retention > 0 AND carbs_retention <= 2),
    fat_change DECIMAL(4,2) DEFAULT 1.0 CHECK (fat_change > 0 AND fat_change <= 3),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(food_name, cooking_method)
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_cooking_conversions_food_name ON cooking_conversion_factors(food_name);
CREATE INDEX IF NOT EXISTS idx_cooking_conversions_category ON cooking_conversion_factors(food_category);
CREATE INDEX IF NOT EXISTS idx_cooking_conversions_method ON cooking_conversion_factors(cooking_method);

-- Pre-populate with common conversion factors

-- GRAINS - absorb water and increase in weight
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, notes)
VALUES
    ('grains', 'white_rice', 2.5, 'boiling', 'White rice absorbs about 2.5x its weight in water'),
    ('grains', 'brown_rice', 2.4, 'boiling', 'Brown rice absorbs slightly less water than white rice'),
    ('grains', 'basmati_rice', 2.8, 'boiling', 'Basmati rice elongates significantly and absorbs more water'),
    ('grains', 'pasta', 2.0, 'boiling', 'Pasta roughly doubles in weight when cooked'),
    ('grains', 'spaghetti', 2.2, 'boiling', 'Long pasta absorbs slightly more water'),
    ('grains', 'penne', 2.0, 'boiling', 'Tube pasta absorbs standard amount'),
    ('grains', 'oats', 2.5, 'boiling', 'Rolled oats absorb significant water'),
    ('grains', 'steel_cut_oats', 3.0, 'boiling', 'Steel cut oats absorb more water than rolled'),
    ('grains', 'quinoa', 2.6, 'boiling', 'Quinoa expands significantly when cooked'),
    ('grains', 'couscous', 2.5, 'steaming', 'Couscous absorbs water when steamed'),
    ('grains', 'bulgur', 2.8, 'boiling', 'Bulgur wheat absorbs considerable water'),
    ('grains', 'barley', 3.0, 'boiling', 'Pearl barley absorbs about 3x its weight'),
    ('grains', 'farro', 2.5, 'boiling', 'Farro expands moderately when cooked')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- LEGUMES - absorb significant water
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, notes)
VALUES
    ('legumes', 'lentils', 2.5, 'boiling', 'Lentils absorb about 2.5x their weight'),
    ('legumes', 'red_lentils', 2.3, 'boiling', 'Red lentils break down more and absorb slightly less'),
    ('legumes', 'chickpeas', 2.0, 'boiling', 'Dried chickpeas double in weight when cooked'),
    ('legumes', 'black_beans', 2.2, 'boiling', 'Black beans absorb about 2.2x their weight'),
    ('legumes', 'kidney_beans', 2.2, 'boiling', 'Kidney beans absorb about 2.2x their weight'),
    ('legumes', 'pinto_beans', 2.3, 'boiling', 'Pinto beans absorb about 2.3x their weight'),
    ('legumes', 'split_peas', 2.5, 'boiling', 'Split peas absorb significant water'),
    ('legumes', 'mung_beans', 2.4, 'boiling', 'Mung beans expand considerably')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- POULTRY - lose moisture when cooked
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, protein_retention, notes)
VALUES
    ('poultry', 'chicken_breast', 0.75, 'grilling', 1.0, 'Chicken breast loses ~25% weight when grilled'),
    ('poultry', 'chicken_breast', 0.80, 'poaching', 1.0, 'Poaching retains more moisture'),
    ('poultry', 'chicken_breast', 0.70, 'baking', 1.0, 'Baking causes more moisture loss'),
    ('poultry', 'turkey_breast', 0.72, 'roasting', 1.0, 'Turkey breast loses about 28% when roasted')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, fat_change, notes)
VALUES
    ('poultry', 'chicken_thigh', 0.70, 'grilling', 0.9, 'Thighs lose fat and moisture when grilled')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- MEATS - lose moisture, fat may render
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, fat_change, notes)
VALUES
    ('meats', 'beef_steak', 0.75, 'grilling', 0.85, 'Steak loses ~25% weight, some fat renders'),
    ('meats', 'beef_ground', 0.70, 'pan_frying', 0.75, 'Ground beef loses ~30% weight, fat renders'),
    ('meats', 'beef_ground_lean', 0.75, 'pan_frying', 0.85, 'Lean ground beef retains more weight'),
    ('meats', 'pork_chop', 0.72, 'grilling', 0.9, 'Pork chop loses ~28% weight when grilled'),
    ('meats', 'pork_tenderloin', 0.75, 'roasting', 1.0, 'Lean cut retains more moisture'),
    ('meats', 'lamb_chop', 0.68, 'grilling', 0.80, 'Lamb loses significant fat when grilled'),
    ('meats', 'bacon', 0.35, 'pan_frying', 0.50, 'Bacon loses ~65% weight, mostly fat renders')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- SEAFOOD
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, fat_change, notes)
VALUES
    ('seafood', 'salmon', 0.80, 'baking', 0.95, 'Salmon retains most fat, loses some moisture'),
    ('seafood', 'salmon', 0.85, 'poaching', 1.0, 'Poaching preserves more moisture'),
    ('seafood', 'tilapia', 0.78, 'baking', 1.0, 'Lean fish loses more moisture'),
    ('seafood', 'shrimp', 0.75, 'boiling', 1.0, 'Shrimp shrink when cooked'),
    ('seafood', 'tuna', 0.82, 'grilling', 1.0, 'Tuna steak retains moisture well'),
    ('seafood', 'cod', 0.75, 'baking', 1.0, 'Cod loses about 25% moisture')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- VEGETABLES - varies widely
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, notes)
VALUES
    ('vegetables', 'broccoli', 0.90, 'steaming', 'Steamed broccoli loses minimal weight'),
    ('vegetables', 'spinach', 0.10, 'sauteing', 'Spinach wilts dramatically, loses ~90% volume/weight'),
    ('vegetables', 'mushrooms', 0.50, 'sauteing', 'Mushrooms release significant moisture'),
    ('vegetables', 'zucchini', 0.70, 'grilling', 'Zucchini loses moisture when grilled'),
    ('vegetables', 'carrots', 0.90, 'boiling', 'Carrots retain most weight when boiled'),
    ('vegetables', 'potatoes', 0.95, 'boiling', 'Potatoes retain weight well when boiled'),
    ('vegetables', 'potatoes', 0.75, 'baking', 'Baked potatoes lose more moisture'),
    ('vegetables', 'sweet_potato', 0.92, 'boiling', 'Sweet potatoes retain weight well'),
    ('vegetables', 'asparagus', 0.85, 'grilling', 'Asparagus loses some moisture'),
    ('vegetables', 'bell_pepper', 0.75, 'roasting', 'Roasted peppers lose moisture'),
    ('vegetables', 'onion', 0.60, 'sauteing', 'Onions caramelize and lose significant moisture'),
    ('vegetables', 'cabbage', 0.70, 'boiling', 'Cabbage wilts and loses volume'),
    ('vegetables', 'kale', 0.20, 'sauteing', 'Kale wilts dramatically like spinach')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- EGGS
INSERT INTO cooking_conversion_factors (food_category, food_name, raw_to_cooked_ratio, cooking_method, fat_change, notes)
VALUES
    ('eggs', 'egg_whole', 0.90, 'boiling', 1.0, 'Hard-boiled eggs lose minimal weight'),
    ('eggs', 'egg_whole', 0.85, 'pan_frying', 1.15, 'Fried eggs with added oil'),
    ('eggs', 'egg_white', 0.88, 'boiling', 1.0, 'Egg whites lose slight moisture')
ON CONFLICT (food_name, cooking_method) DO NOTHING;

-- Enable RLS
ALTER TABLE cooking_conversion_factors ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for read access (everyone can read conversion factors)
DROP POLICY IF EXISTS "cooking_conversions_read_all" ON cooking_conversion_factors;
CREATE POLICY "cooking_conversions_read_all" ON cooking_conversion_factors
    FOR SELECT
    USING (true);

-- Create update trigger for updated_at
CREATE OR REPLACE FUNCTION update_cooking_conversion_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cooking_conversion_updated_at ON cooking_conversion_factors;
CREATE TRIGGER trigger_cooking_conversion_updated_at
    BEFORE UPDATE ON cooking_conversion_factors
    FOR EACH ROW
    EXECUTE FUNCTION update_cooking_conversion_updated_at();

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '114_cooking_conversions',
    NOW(),
    'Added cooking conversion factors table for raw/cooked weight conversions'
) ON CONFLICT DO NOTHING;

COMMENT ON TABLE cooking_conversion_factors IS 'Conversion factors for raw to cooked food weights, addresses user request for cooked grain input';
COMMENT ON COLUMN cooking_conversion_factors.raw_to_cooked_ratio IS 'Multiplier: >1 means food gains weight (grains), <1 means food loses weight (meats)';
COMMENT ON COLUMN cooking_conversion_factors.calories_retention IS 'Fraction of calories retained after cooking (usually 1.0)';
COMMENT ON COLUMN cooking_conversion_factors.fat_change IS 'Fat multiplier: >1 if fat added (frying), <1 if fat renders out';
