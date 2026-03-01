-- 312_overrides_missing_common.sql
-- Missing common foods: Spam Fried Rice, Hawaiian Garlic Shrimp (generic),
-- Saimin, and other gaps identified during audit.
-- Sources: snapcalorie.com, inlivo.com, nutritionix.com, fatsecret.com, USDA

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ── SPAM FRIED RICE ─────────────────────────────────────────────
-- Spam Fried Rice: ~180 cal/100g (snapcalorie, inlivo, recipe cross-ref)
-- Serving ~350g = ~630 cal. Wok-fried rice with diced spam, egg, soy sauce.
('spam_fried_rice', 'Spam Fried Rice', 180, 6.5, 21.0, 7.5,
 0.8, 0.5, NULL, NULL,
 'hawaiian_cuisine', ARRAY['hawaiian spam fried rice', 'spam rice', 'spam chahan', 'fried rice with spam'],
 'hawaiian', NULL, 1, '180 cal/100g. Plate ~350g = ~630 cal. Wok-fried rice with diced spam, egg, scallions, soy sauce.', TRUE),

-- Hawaiian Garlic Shrimp (generic, not chain-specific): ~165 cal/100g
-- Serving ~250g = ~413 cal. North Shore style garlic butter shrimp.
('hawaiian_garlic_shrimp', 'Hawaiian Garlic Shrimp', 165, 14.0, 5.0, 10.0,
 0.3, 0.5, NULL, NULL,
 'hawaiian_cuisine', ARRAY['garlic shrimp plate', 'north shore garlic shrimp', 'garlic butter shrimp hawaiian', 'shrimp scampi hawaiian'],
 'hawaiian', NULL, 1, '165 cal/100g. Serving ~250g = ~413 cal. Shell-on shrimp sauteed in garlic butter. Hawaii North Shore classic.', TRUE),

-- Saimin (Hawaiian noodle soup): ~75 cal/100g
-- Serving ~450g = ~338 cal. Dashi broth with thin noodles, char siu, kamaboko.
('saimin', 'Saimin (Hawaiian Noodle Soup)', 75, 3.5, 10.0, 2.0,
 0.3, 0.5, NULL, NULL,
 'hawaiian_cuisine', ARRAY['hawaiian saimin', 'saimin noodles', 'zippy''s saimin'],
 'hawaiian', NULL, 1, '75 cal/100g. Bowl ~450g = ~338 cal. Dashi-based noodle soup with char siu, kamaboko, green onions.', TRUE),

-- Manapua (Hawaiian steamed bun): ~250 cal/100g
-- Per piece ~100g. Hawaiian take on char siu bao.
('manapua', 'Manapua (Hawaiian Char Siu Bun)', 250, 8.0, 35.0, 8.5,
 1.0, 5.0, NULL, 100,
 'hawaiian_cuisine', ARRAY['hawaiian manapua', 'char siu bao hawaiian', 'manapua bun', 'baked manapua'],
 'hawaiian', NULL, 1, '250 cal/100g. Per bun ~100g. Steamed or baked bun filled with sweet BBQ pork.', TRUE)

ON CONFLICT (food_name_normalized)
DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_serving_g = EXCLUDED.default_serving_g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
