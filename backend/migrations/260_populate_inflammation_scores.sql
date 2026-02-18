-- Migration: 260_populate_inflammation_scores.sql
-- Description: Populate inflammatory_score and inflammatory_category columns
--              in food_database for all rows, based on nutritional data,
--              processing level (nova_group), and name heuristics.
-- Created: 2026-02-17
--
-- This makes the food_database fallback tier useful for ingredient
-- inflammation lookups when the static dictionary misses.
--
-- Score convention:
--   1-2 = highly anti-inflammatory
--   3-4 = anti-inflammatory
--   5-6 = neutral
--   7-8 = moderately inflammatory
--   9-10 = highly inflammatory

-- ============================================================================
-- Step 1: Populate inflammatory_score based on multiple signals
-- ============================================================================

UPDATE food_database
SET inflammatory_score = CASE
    -- Ultra-processed (NOVA 4) + high sugar = highly inflammatory
    WHEN nova_group = 4 AND sugar_per_100g > 30 THEN 9
    WHEN nova_group = 4 AND sugar_per_100g > 15 THEN 8
    WHEN nova_group = 4 THEN 7

    -- NOVA 3 (processed foods) - moderately inflammatory
    WHEN nova_group = 3 AND sugar_per_100g > 20 THEN 8
    WHEN nova_group = 3 THEN 6

    -- Name-based heuristics for highly inflammatory items
    WHEN LOWER(name) SIMILAR TO '%(candy|candies|gummy|gummies|soda|pop|energy drink)%' THEN 9
    WHEN LOWER(name) SIMILAR TO '%(fried|deep fried|french fries|chips|nachos)%' THEN 8
    WHEN LOWER(name) SIMILAR TO '%(hot dog|bacon|sausage|salami|pepperoni|bologna)%' THEN 8
    WHEN LOWER(name) SIMILAR TO '%(donut|doughnut|pastry|croissant|danish)%' THEN 8
    WHEN LOWER(name) SIMILAR TO '%(cake|cookie|brownie|muffin|cupcake|pie|tart)%' THEN 7
    WHEN LOWER(name) SIMILAR TO '%(ice cream|frozen dessert|milkshake)%' THEN 7
    WHEN LOWER(name) SIMILAR TO '%(margarine|shortening)%' THEN 7
    WHEN LOWER(name) SIMILAR TO '%(white bread|white rice|white pasta)%' THEN 6

    -- Name-based heuristics for anti-inflammatory items
    WHEN LOWER(name) SIMILAR TO '%(turmeric|ginger|garlic|cinnamon|oregano)%' THEN 2
    WHEN LOWER(name) SIMILAR TO '%(salmon|sardine|mackerel|herring|anchov)%' THEN 2
    WHEN LOWER(name) SIMILAR TO '%(blueberr|blackberr|raspberr|acai|pomegranate)%' THEN 2
    WHEN LOWER(name) SIMILAR TO '%(spinach|kale|broccoli|brussels sprout)%' THEN 2
    WHEN LOWER(name) SIMILAR TO '%(walnut|chia|flax|hemp seed|avocado)%' THEN 3
    WHEN LOWER(name) SIMILAR TO '%(olive oil|avocado oil|flaxseed oil)%' THEN 2
    WHEN LOWER(name) SIMILAR TO '%(whole grain|whole wheat|oat|quinoa|barley|brown rice)%' THEN 4
    WHEN LOWER(name) SIMILAR TO '%(lentil|chickpea|black bean|kidney bean)%' THEN 3
    WHEN LOWER(name) SIMILAR TO '%(green tea|matcha|herbal tea)%' THEN 2
    WHEN LOWER(name) SIMILAR TO '%(yogurt|kefir|sauerkraut|kimchi|tempeh|miso)%' THEN 3

    -- Nutriscore-based (when available, scale -15 to 40 -> 1 to 10)
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= -5 THEN 2
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= 0 THEN 3
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= 5 THEN 4
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= 10 THEN 5
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= 15 THEN 6
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= 20 THEN 7
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score <= 30 THEN 8
    WHEN nutriscore_score IS NOT NULL AND nutriscore_score > 30 THEN 9

    -- Fiber-rich foods lean anti-inflammatory
    WHEN fiber_per_100g > 10 THEN 3
    WHEN fiber_per_100g > 5 AND sugar_per_100g < 10 THEN 4

    -- High sugar foods lean inflammatory
    WHEN sugar_per_100g > 50 THEN 9
    WHEN sugar_per_100g > 30 THEN 8
    WHEN sugar_per_100g > 20 THEN 7

    -- Category-based fallback
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(vegetable|fruit|legume|bean|lentil)%' THEN 3
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(nut|seed)%' THEN 3
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(fish|seafood)%' THEN 4
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(herb|spice)%' THEN 3
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(snack|candy|sweet|dessert)%' THEN 7
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(cereal|grain)%' THEN 5
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(dairy|milk|cheese)%' THEN 6
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(meat|poultry)%' THEN 5
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(beverage|drink)%' THEN 5
    WHEN LOWER(COALESCE(category, '')) SIMILAR TO '%(oil|fat)%' THEN 6

    -- Default neutral
    ELSE 5
END
WHERE inflammatory_score IS NULL;

-- ============================================================================
-- Step 2: Populate inflammatory_category based on score
-- ============================================================================

UPDATE food_database
SET inflammatory_category = CASE
    WHEN inflammatory_score <= 2 THEN 'highly_anti_inflammatory'
    WHEN inflammatory_score <= 4 THEN 'anti_inflammatory'
    WHEN inflammatory_score <= 6 THEN 'neutral'
    WHEN inflammatory_score <= 8 THEN 'moderately_inflammatory'
    ELSE 'highly_inflammatory'
END
WHERE inflammatory_category IS NULL AND inflammatory_score IS NOT NULL;

-- ============================================================================
-- Step 3: Add index for inflammation lookups
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_food_database_inflammatory_score
    ON food_database(inflammatory_score)
    WHERE inflammatory_score IS NOT NULL;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
