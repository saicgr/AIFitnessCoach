-- Migration 1609: Fix override serving sizes + add chocolate pastry
-- Issue: UI shows per-100g calories with small serving labels (e.g. 420 kcal / 13g)
-- Fix: Adjust unrealistic servings, normalize multi-piece defaults to 1-piece

-- 5a. Fix unrealistically small servings (piece < 25g where serving == piece)
UPDATE food_nutrition_overrides
SET default_serving_g = 39, default_count = 3
WHERE food_name_normalized = 'rice_cakes_chocolate';

UPDATE food_nutrition_overrides
SET default_serving_g = 27, default_count = 3
WHERE food_name_normalized = 'rice_cakes_plain';

-- 5b. Fix multi-piece defaults to 1-piece
-- Gemini NL analysis already handles quantities like "2 eggs",
-- so keyword search should default to 1 piece.

UPDATE food_nutrition_overrides
SET default_serving_g = 50, default_count = 1
WHERE food_name_normalized = 'egg';

UPDATE food_nutrition_overrides
SET default_serving_g = 30, default_count = 1
WHERE food_name_normalized = 'bread_white';

UPDATE food_nutrition_overrides
SET default_serving_g = 35, default_count = 1
WHERE food_name_normalized = 'bread_whole_wheat';

UPDATE food_nutrition_overrides
SET default_serving_g = 40, default_count = 1
WHERE food_name_normalized = 'roti';

UPDATE food_nutrition_overrides
SET default_serving_g = 40, default_count = 1
WHERE food_name_normalized = 'idli';

UPDATE food_nutrition_overrides
SET default_serving_g = 25, default_count = 1
WHERE food_name_normalized = 'puri';

UPDATE food_nutrition_overrides
SET default_serving_g = 50, default_count = 1
WHERE food_name_normalized = 'vada';

-- 5c. Add missing "Chocolate Pastry" override
INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name, calories_per_100g,
  protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g, source,
  variant_names, food_category, restaurant_name, default_count, notes, is_active
) VALUES (
  'chocolate_pastry', 'Chocolate Pastry', 400.0,
  7.0, 46.0, 21.0, 2.0, 22.0,
  80, 80, 'usda',
  ARRAY['chocolate pastry', 'chocolate puff pastry', 'choco pastry'],
  'desserts', NULL, 1,
  '320 cal per pastry (80g). Flaky pastry with chocolate filling.', TRUE
);
