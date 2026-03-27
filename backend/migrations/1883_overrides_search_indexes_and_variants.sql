-- Migration: Add search indexes to food_nutrition_overrides + missing food variants
-- Fixes: 20-35s food search (missing indexes) and 63s analyze (missing variants)

-- ============================================================
-- Part 1: Indexes for faster override search
-- ============================================================

-- Btree index for exact match on food_name_normalized (Step 1 in _search_overrides_db)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_overrides_name_normalized
ON food_nutrition_overrides (food_name_normalized)
WHERE is_active = TRUE;

-- Trigram index for ILIKE on display_name (Steps 2-4 in _search_overrides_db)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_overrides_display_name_trgm
ON food_nutrition_overrides USING gin (display_name gin_trgm_ops)
WHERE is_active = TRUE;

-- Trigram index on food_name_normalized (used by fuzzy trigram search Step 4)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_overrides_name_normalized_trgm
ON food_nutrition_overrides USING gin (food_name_normalized gin_trgm_ops)
WHERE is_active = TRUE;


-- ============================================================
-- Part 2: Missing food variants (common user queries that miss overrides)
-- ============================================================

-- Avocado preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['avocado mash', 'avocado spread', 'smashed avocado', 'avo mash', 'avo spread', 'avo smash', 'guac', 'avo']
) WHERE food_name_normalized = 'avocado'
AND NOT ('avocado mash' = ANY(variant_names));

-- Egg preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['scramble egg', 'scramble eggs', 'fry egg', 'fry eggs', 'boil egg', 'boil eggs', 'poach egg', 'poach eggs']
) WHERE food_name_normalized = 'egg'
AND NOT ('scramble egg' = ANY(variant_names));

-- Chicken preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['chicken grilled', 'chicken roasted', 'chicken baked', 'chicken steamed', 'grill chicken', 'roast chicken', 'bake chicken']
) WHERE food_name_normalized = 'chicken_breast'
AND NOT ('chicken grilled' = ANY(variant_names));

-- Rice preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['rice steamed', 'rice boiled', 'steam rice', 'boil rice', 'plain rice']
) WHERE food_name_normalized = 'white_rice'
AND NOT ('rice steamed' = ANY(variant_names));

-- Brown rice
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['rice brown', 'brown rice steamed', 'brown rice boiled']
) WHERE food_name_normalized = 'brown_rice'
AND NOT ('rice brown' = ANY(variant_names));

-- Potato preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['potato mashed', 'potato baked', 'potato boiled', 'potato roasted', 'mash potato', 'bake potato', 'boil potato', 'roast potato']
) WHERE food_name_normalized = 'potato'
AND NOT ('potato mashed' = ANY(variant_names));

-- Sweet potato preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['sweet potato roasted', 'sweet potato baked', 'sweet potato mashed', 'roast sweet potato', 'bake sweet potato', 'mash sweet potato']
) WHERE food_name_normalized = 'sweet_potato'
AND NOT ('sweet potato roasted' = ANY(variant_names));

-- Broccoli preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['broccoli steamed', 'broccoli boiled', 'broccoli roasted', 'steam broccoli', 'boil broccoli', 'roast broccoli']
) WHERE food_name_normalized = 'broccoli'
AND NOT ('broccoli steamed' = ANY(variant_names));

-- Salmon preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['salmon grilled', 'salmon baked', 'salmon smoked', 'grill salmon', 'bake salmon', 'smoke salmon']
) WHERE food_name_normalized = 'salmon'
AND NOT ('salmon grilled' = ANY(variant_names));

-- Oats preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['oats cooked', 'cooked oats', 'oats porridge', 'porridge oats']
) WHERE food_name_normalized = 'oats'
AND NOT ('oats cooked' = ANY(variant_names));

-- Toast
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['toasted bread', 'bread toasted', 'bread toast']
) WHERE food_name_normalized = 'toast'
AND NOT ('toasted bread' = ANY(variant_names));

-- Spinach preparations
UPDATE food_nutrition_overrides SET variant_names = array_cat(
  variant_names,
  ARRAY['spinach sauteed', 'spinach steamed', 'spinach boiled', 'saute spinach', 'steam spinach', 'boil spinach']
) WHERE food_name_normalized = 'spinach'
AND NOT ('spinach sauteed' = ANY(variant_names));
