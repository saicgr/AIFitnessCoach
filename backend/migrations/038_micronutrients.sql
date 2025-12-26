-- Migration: Add Micronutrient Tracking
-- Created: 2025-12-25
-- Description: Add comprehensive micronutrient columns to food_logs and nutrition targets

-- ============================================================
-- ADD MICRONUTRIENT COLUMNS TO FOOD_LOGS
-- ============================================================

-- Vitamins
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_a_ug DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_c_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_d_iu DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_e_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_k_ug DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b1_mg DECIMAL(10,2);  -- Thiamine
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b2_mg DECIMAL(10,2);  -- Riboflavin
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b3_mg DECIMAL(10,2);  -- Niacin
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b5_mg DECIMAL(10,2);  -- Pantothenic Acid
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b6_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b7_ug DECIMAL(10,2);  -- Biotin
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b9_ug DECIMAL(10,2);  -- Folate
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS vitamin_b12_ug DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS choline_mg DECIMAL(10,2);

-- Minerals
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS calcium_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS iron_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS magnesium_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS zinc_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS selenium_ug DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS potassium_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS sodium_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS phosphorus_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS copper_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS manganese_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS iodine_ug DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS chromium_ug DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS molybdenum_ug DECIMAL(10,2);

-- Fatty Acids
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS omega3_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS omega6_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS saturated_fat_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS trans_fat_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS monounsaturated_fat_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS polyunsaturated_fat_g DECIMAL(10,2);

-- Other
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS cholesterol_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS sugar_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS added_sugar_g DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS water_ml DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS caffeine_mg DECIMAL(10,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS alcohol_g DECIMAL(10,2);

-- ============================================================
-- ADD MICRONUTRIENT TARGETS TO USERS
-- ============================================================

-- Vitamin targets
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_a_ug DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_c_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_d_iu DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_e_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_k_ug DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_b1_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_b2_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_b3_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_b6_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_b9_ug DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_vitamin_b12_ug DECIMAL(10,2);

-- Mineral targets
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_calcium_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_iron_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_magnesium_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_zinc_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_selenium_ug DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_potassium_mg DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_sodium_mg DECIMAL(10,2);

-- Other targets
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_omega3_g DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_fiber_g DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_water_ml DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_sugar_g DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_cholesterol_mg DECIMAL(10,2);

-- ============================================================
-- PINNED MICRONUTRIENTS (user preference)
-- ============================================================

-- Users can pin up to 8 micronutrients to their dashboard
ALTER TABLE users ADD COLUMN IF NOT EXISTS pinned_nutrients TEXT[] DEFAULT ARRAY['vitamin_d', 'calcium', 'iron', 'omega3'];

-- ============================================================
-- DEFAULT RDA VALUES TABLE (Reference Daily Allowances)
-- ============================================================

CREATE TABLE IF NOT EXISTS nutrient_rdas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nutrient_name VARCHAR(50) NOT NULL UNIQUE,
    nutrient_key VARCHAR(50) NOT NULL UNIQUE,  -- e.g., 'vitamin_a_ug'
    unit VARCHAR(20) NOT NULL,                  -- e.g., 'ug', 'mg', 'g', 'IU'
    category VARCHAR(30) NOT NULL,              -- 'vitamin', 'mineral', 'fatty_acid', 'other'

    -- Default RDA values (can be overridden by user)
    rda_floor DECIMAL(10,2),     -- Lower threshold (97-98% of people need more)
    rda_target DECIMAL(10,2),    -- Recommended Daily Allowance
    rda_ceiling DECIMAL(10,2),   -- Upper limit (potential toxicity)

    -- Gender-specific RDAs (optional)
    rda_target_male DECIMAL(10,2),
    rda_target_female DECIMAL(10,2),

    -- Display info
    display_name VARCHAR(100) NOT NULL,
    display_order INTEGER DEFAULT 0,
    icon VARCHAR(50),
    color_hex VARCHAR(7),

    -- Health context
    deficiency_symptoms TEXT,
    excess_symptoms TEXT,
    good_sources TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default RDA values
INSERT INTO nutrient_rdas (nutrient_name, nutrient_key, unit, category, rda_floor, rda_target, rda_ceiling, rda_target_male, rda_target_female, display_name, display_order, color_hex) VALUES
-- Vitamins
('Vitamin A', 'vitamin_a_ug', 'ug', 'vitamin', 500, 900, 3000, 900, 700, 'Vitamin A', 1, '#FF9F43'),
('Vitamin C', 'vitamin_c_mg', 'mg', 'vitamin', 60, 90, 2000, 90, 75, 'Vitamin C', 2, '#FFA502'),
('Vitamin D', 'vitamin_d_iu', 'IU', 'vitamin', 400, 800, 4000, 800, 800, 'Vitamin D', 3, '#FFD700'),
('Vitamin E', 'vitamin_e_mg', 'mg', 'vitamin', 12, 15, 1000, 15, 15, 'Vitamin E', 4, '#FF6B6B'),
('Vitamin K', 'vitamin_k_ug', 'ug', 'vitamin', 90, 120, NULL, 120, 90, 'Vitamin K', 5, '#00D9C0'),
('Vitamin B1', 'vitamin_b1_mg', 'mg', 'vitamin', 0.9, 1.2, NULL, 1.2, 1.1, 'Thiamine (B1)', 6, '#FF9F43'),
('Vitamin B2', 'vitamin_b2_mg', 'mg', 'vitamin', 1.0, 1.3, NULL, 1.3, 1.1, 'Riboflavin (B2)', 7, '#FF9F43'),
('Vitamin B3', 'vitamin_b3_mg', 'mg', 'vitamin', 12, 16, 35, 16, 14, 'Niacin (B3)', 8, '#FF9F43'),
('Vitamin B6', 'vitamin_b6_mg', 'mg', 'vitamin', 1.0, 1.7, 100, 1.7, 1.5, 'Vitamin B6', 9, '#FF9F43'),
('Folate', 'vitamin_b9_ug', 'ug', 'vitamin', 300, 400, 1000, 400, 400, 'Folate (B9)', 10, '#FF9F43'),
('Vitamin B12', 'vitamin_b12_ug', 'ug', 'vitamin', 2.0, 2.4, NULL, 2.4, 2.4, 'Vitamin B12', 11, '#FF9F43'),
('Choline', 'choline_mg', 'mg', 'vitamin', 400, 550, 3500, 550, 425, 'Choline', 12, '#FF9F43'),

-- Minerals
('Calcium', 'calcium_mg', 'mg', 'mineral', 800, 1000, 2500, 1000, 1000, 'Calcium', 20, '#00D9C0'),
('Iron', 'iron_mg', 'mg', 'mineral', 6, 18, 45, 8, 18, 'Iron', 21, '#C0392B'),
('Magnesium', 'magnesium_mg', 'mg', 'mineral', 300, 420, 350, 420, 320, 'Magnesium', 22, '#00D9C0'),
('Zinc', 'zinc_mg', 'mg', 'mineral', 7, 11, 40, 11, 8, 'Zinc', 23, '#00D9C0'),
('Selenium', 'selenium_ug', 'ug', 'mineral', 40, 55, 400, 55, 55, 'Selenium', 24, '#00D9C0'),
('Potassium', 'potassium_mg', 'mg', 'mineral', 2000, 4700, NULL, 4700, 4700, 'Potassium', 25, '#00D9C0'),
('Sodium', 'sodium_mg', 'mg', 'mineral', 500, 2300, 2300, 2300, 2300, 'Sodium', 26, '#00D9C0'),
('Phosphorus', 'phosphorus_mg', 'mg', 'mineral', 580, 700, 4000, 700, 700, 'Phosphorus', 27, '#00D9C0'),
('Copper', 'copper_mg', 'mg', 'mineral', 0.7, 0.9, 10, 0.9, 0.9, 'Copper', 28, '#00D9C0'),
('Manganese', 'manganese_mg', 'mg', 'mineral', 1.6, 2.3, 11, 2.3, 1.8, 'Manganese', 29, '#00D9C0'),
('Iodine', 'iodine_ug', 'ug', 'mineral', 110, 150, 1100, 150, 150, 'Iodine', 30, '#00D9C0'),

-- Fatty Acids & Other
('Omega-3', 'omega3_g', 'g', 'fatty_acid', 0.5, 1.6, NULL, 1.6, 1.1, 'Omega-3', 40, '#4D96FF'),
('Omega-6', 'omega6_g', 'g', 'fatty_acid', 8, 17, NULL, 17, 12, 'Omega-6', 41, '#4D96FF'),
('Fiber', 'fiber_g', 'g', 'other', 20, 30, NULL, 38, 25, 'Fiber', 50, '#9B59B6'),
('Cholesterol', 'cholesterol_mg', 'mg', 'other', 0, 300, 300, 300, 300, 'Cholesterol', 51, '#E74C3C'),
('Water', 'water_ml', 'ml', 'other', 2000, 3000, NULL, 3700, 2700, 'Water', 52, '#3498DB'),
('Sugar', 'sugar_g', 'g', 'other', 0, 25, 50, 36, 25, 'Sugar', 53, '#E74C3C'),
('Caffeine', 'caffeine_mg', 'mg', 'other', 0, 400, 400, 400, 400, 'Caffeine', 54, '#8B4513')
ON CONFLICT (nutrient_key) DO NOTHING;

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_nutrient_rdas_key ON nutrient_rdas(nutrient_key);
CREATE INDEX IF NOT EXISTS idx_nutrient_rdas_category ON nutrient_rdas(category);

COMMENT ON TABLE nutrient_rdas IS 'Reference Daily Allowances for micronutrients with floor/target/ceiling values';

-- ============================================================
-- UPDATE SAVED_FOODS TO INCLUDE MICRONUTRIENTS
-- ============================================================

-- Add micronutrient totals to saved_foods
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS vitamin_d_iu DECIMAL(10,2);
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS calcium_mg DECIMAL(10,2);
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS iron_mg DECIMAL(10,2);
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS omega3_g DECIMAL(10,2);
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS sodium_mg DECIMAL(10,2);
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS sugar_g DECIMAL(10,2);

-- Add full micronutrients JSON for flexibility
ALTER TABLE saved_foods ADD COLUMN IF NOT EXISTS micronutrients JSONB DEFAULT '{}';

COMMENT ON COLUMN saved_foods.micronutrients IS 'Full micronutrient data as JSON object';
