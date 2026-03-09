-- 1618_overrides_huel_expansion.sql
-- Huel full product line expansion: Black Edition, Original Powder, RTD,
-- Black RTD, Hot & Savory, Complete Nutrition Bar, Daily Greens.
-- Sources: Package nutrition labels via huel.com, fatsecret.com,
-- eatthismuch.com, amazon.com, openfoodfacts.org.
-- All values per 100g. default_serving_g for powders, default_weight_per_piece_g
-- for bars and RTD bottles.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- HUEL — BLACK EDITION POWDER
-- All flavors: ~400 cal, 40g P, 17g C, 17g F, 7g fiber per 90g serving
-- per 100g = (value / 90) * 100
-- ══════════════════════════════════════════

-- Huel Black Edition Chocolate: 400 cal / 90g serving
('huel_black_chocolate', 'Huel Black Edition - Chocolate', 444, 44.4, 18.9, 18.9,
 7.8, 1.1, 90, NULL,
 'manufacturer', ARRAY['huel black chocolate', 'huel black edition chocolate', 'huel chocolate powder', 'huel chocolate meal replacement', 'huel black chocolate shake'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (90g). 40g protein, 17g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Black Edition Vanilla: 400 cal / 90g serving
('huel_black_vanilla', 'Huel Black Edition - Vanilla', 444, 44.4, 18.9, 18.9,
 7.8, 1.1, 90, NULL,
 'manufacturer', ARRAY['huel black vanilla', 'huel black edition vanilla', 'huel vanilla powder', 'huel vanilla meal replacement', 'huel black vanilla shake'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (90g). 40g protein, 17g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Black Edition Banana: 400 cal / 90g serving
('huel_black_banana', 'Huel Black Edition - Banana', 444, 44.4, 18.9, 18.9,
 7.8, 1.1, 90, NULL,
 'manufacturer', ARRAY['huel black banana', 'huel black edition banana', 'huel banana powder', 'huel banana meal replacement', 'huel black banana shake'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (90g). 40g protein, 17g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Black Edition Salted Caramel: 400 cal / 90g serving
('huel_black_salted_caramel', 'Huel Black Edition - Salted Caramel', 444, 44.4, 18.9, 18.9,
 7.8, 1.1, 90, NULL,
 'manufacturer', ARRAY['huel black salted caramel', 'huel black edition salted caramel', 'huel salted caramel powder', 'huel salted caramel meal replacement', 'huel black caramel shake'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (90g). 40g protein, 17g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- ══════════════════════════════════════════
-- HUEL — ORIGINAL POWDER v3.1
-- All flavors: ~400 cal, 30g P, 46g C, 13g F, 7g fiber per 100g serving
-- per 100g = values as-is (serving IS 100g)
-- ══════════════════════════════════════════

-- Huel Original Vanilla: 400 cal / 100g serving
('huel_original_vanilla', 'Huel Original v3.1 - Vanilla', 400, 30.0, 46.0, 13.0,
 7.0, 1.0, 100, NULL,
 'manufacturer', ARRAY['huel original vanilla', 'huel v3 vanilla', 'huel powder vanilla', 'huel vanilla shake', 'huel v3.1 vanilla'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (100g). 30g protein, 46g carbs, 13g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Original Chocolate: 400 cal / 100g serving
('huel_original_chocolate', 'Huel Original v3.1 - Chocolate', 400, 30.0, 46.0, 13.0,
 7.0, 1.0, 100, NULL,
 'manufacturer', ARRAY['huel original chocolate', 'huel v3 chocolate', 'huel powder chocolate', 'huel chocolate shake', 'huel v3.1 chocolate'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (100g). 30g protein, 46g carbs, 13g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Original Banana: 400 cal / 100g serving
('huel_original_banana', 'Huel Original v3.1 - Banana', 400, 30.0, 46.0, 13.0,
 7.0, 1.0, 100, NULL,
 'manufacturer', ARRAY['huel original banana', 'huel v3 banana', 'huel powder banana', 'huel banana shake', 'huel v3.1 banana'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (100g). 30g protein, 46g carbs, 13g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Original Berry: 400 cal / 100g serving
('huel_original_berry', 'Huel Original v3.1 - Berry', 400, 30.0, 46.0, 13.0,
 7.0, 1.0, 100, NULL,
 'manufacturer', ARRAY['huel original berry', 'huel v3 berry', 'huel powder berry', 'huel berry shake', 'huel v3.1 berry'],
 'huel', 'Huel', 1, '400 cal per 2 scoops (100g). 30g protein, 46g carbs, 13g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- ══════════════════════════════════════════
-- HUEL — READY-TO-DRINK (ORIGINAL RTD)
-- All flavors: ~400 cal, 20g P, 41g C, 19g F per 500ml bottle (~510g)
-- per 100g = (value / 510) * 100
-- ══════════════════════════════════════════

-- Huel RTD Chocolate: 400 cal / 500ml bottle (~510g)
('huel_rtd_chocolate', 'Huel Ready-to-Drink - Chocolate', 78, 3.9, 8.0, 3.7,
 1.2, 1.6, NULL, 510,
 'manufacturer', ARRAY['huel rtd chocolate', 'huel ready to drink chocolate', 'huel chocolate bottle', 'huel drink chocolate', 'huel chocolate rtd'],
 'huel', 'Huel', 1, '400 cal per bottle (500ml/~510g). 20g protein, 41g carbs, 19g fat, 6g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel RTD Vanilla: 400 cal / 500ml bottle (~510g)
('huel_rtd_vanilla', 'Huel Ready-to-Drink - Vanilla', 78, 3.9, 8.0, 3.7,
 1.2, 1.6, NULL, 510,
 'manufacturer', ARRAY['huel rtd vanilla', 'huel ready to drink vanilla', 'huel vanilla bottle', 'huel drink vanilla', 'huel vanilla rtd'],
 'huel', 'Huel', 1, '400 cal per bottle (500ml/~510g). 20g protein, 41g carbs, 19g fat, 6g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- ══════════════════════════════════════════
-- HUEL — BLACK EDITION RTD
-- All flavors: ~400 cal, 35g P, 23g C, 17g F per 500ml bottle (~510g)
-- per 100g = (value / 510) * 100
-- ══════════════════════════════════════════

-- Huel Black RTD Chocolate: 400 cal / 500ml bottle (~510g)
('huel_black_rtd_chocolate', 'Huel Black Edition RTD - Chocolate', 78, 6.9, 4.5, 3.3,
 1.4, 0.8, NULL, 510,
 'manufacturer', ARRAY['huel black rtd chocolate', 'huel black ready to drink chocolate', 'huel black chocolate bottle', 'huel black edition rtd chocolate'],
 'huel', 'Huel', 1, '400 cal per bottle (500ml/~510g). 35g protein, 23g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Black RTD Vanilla: 400 cal / 500ml bottle (~510g)
('huel_black_rtd_vanilla', 'Huel Black Edition RTD - Vanilla', 78, 6.9, 4.5, 3.3,
 1.4, 0.8, NULL, 510,
 'manufacturer', ARRAY['huel black rtd vanilla', 'huel black ready to drink vanilla', 'huel black vanilla bottle', 'huel black edition rtd vanilla'],
 'huel', 'Huel', 1, '400 cal per bottle (500ml/~510g). 35g protein, 23g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Black RTD Salted Caramel: 400 cal / 500ml bottle (~510g)
('huel_black_rtd_salted_caramel', 'Huel Black Edition RTD - Salted Caramel', 78, 6.9, 4.5, 3.3,
 1.4, 0.8, NULL, 510,
 'manufacturer', ARRAY['huel black rtd salted caramel', 'huel black ready to drink salted caramel', 'huel black caramel bottle', 'huel black edition rtd salted caramel'],
 'huel', 'Huel', 1, '400 cal per bottle (500ml/~510g). 35g protein, 23g carbs, 17g fat, 7g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- ══════════════════════════════════════════
-- HUEL — HOT & SAVORY
-- Serving size ~95g. Macros vary by flavor.
-- per 100g = (value / serving_g) * 100
-- ══════════════════════════════════════════

-- Huel Hot & Savory Mac & Cheeze: 400 cal, 25g P, 55g C, 10g F per 95g
('huel_hs_mac_cheeze', 'Huel Hot & Savory - Mac & Cheeze', 421, 26.3, 57.9, 10.5,
 10.5, 2.1, 95, NULL,
 'manufacturer', ARRAY['huel hot savory mac cheeze', 'huel mac and cheese', 'huel hot and savory mac cheeze', 'huel mac cheeze', 'huel macaroni cheese'],
 'huel', 'Huel', 1, '400 cal per serving (95g). 25g protein, 55g carbs, 10g fat, 10g fiber. Complete meal with 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Hot & Savory Mexican Chili: 400 cal, 24g P, 48g C, 13g F per 97g
('huel_hs_mexican_chili', 'Huel Hot & Savory - Mexican Chili', 412, 24.7, 49.5, 13.4,
 14.4, 2.1, 97, NULL,
 'manufacturer', ARRAY['huel hot savory mexican chili', 'huel mexican chili', 'huel hot and savory mexican chilli', 'huel chili', 'huel hot savory chili'],
 'huel', 'Huel', 1, '400 cal per serving (97g). 24g protein, 48g carbs, 13g fat, 14g fiber. Complete meal with 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Hot & Savory Thai Green Curry: 400 cal, 24g P, 50g C, 13g F per 95g
('huel_hs_thai_green_curry', 'Huel Hot & Savory - Thai Green Curry', 421, 25.3, 52.6, 13.7,
 10.5, 2.1, 95, NULL,
 'manufacturer', ARRAY['huel hot savory thai green curry', 'huel thai curry', 'huel hot and savory thai green curry', 'huel green curry', 'huel hot savory curry'],
 'huel', 'Huel', 1, '400 cal per serving (95g). 24g protein, 50g carbs, 13g fat, 10g fiber. Complete meal with 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Hot & Savory Tomato & Herb: 400 cal, 23g P, 49g C, 12g F per 95g
('huel_hs_tomato_herb', 'Huel Hot & Savory - Tomato & Herb', 421, 24.2, 51.6, 12.6,
 10.5, 2.1, 95, NULL,
 'manufacturer', ARRAY['huel hot savory tomato herb', 'huel tomato herb', 'huel hot and savory tomato herb', 'huel tomato', 'huel hot savory tomato'],
 'huel', 'Huel', 1, '400 cal per serving (95g). 23g protein, 49g carbs, 12g fat, 10g fiber. Complete meal with 27 vitamins & minerals. Vegan.', TRUE),

-- ══════════════════════════════════════════
-- HUEL — COMPLETE NUTRITION BAR
-- Per bar (51g): 210 cal, 15g P, 17g C, 7g F
-- per 100g = (value / 51) * 100
-- ══════════════════════════════════════════

-- Huel Complete Nutrition Bar Chocolate Caramel: 210 cal / 51g bar
('huel_bar_chocolate_caramel', 'Huel Complete Nutrition Bar - Chocolate Caramel', 412, 29.4, 33.3, 13.7,
 11.8, 3.9, NULL, 51,
 'manufacturer', ARRAY['huel bar chocolate caramel', 'huel protein bar chocolate', 'huel nutrition bar chocolate caramel', 'huel bar chocolate', 'huel complete bar caramel'],
 'protein_bar', 'Huel', 1, '210 cal per bar (51g). 15g protein, 17g carbs, 7g fat, 6g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- Huel Complete Nutrition Bar Peanut Caramel: 210 cal / 51g bar
('huel_bar_peanut_caramel', 'Huel Complete Nutrition Bar - Peanut Caramel', 412, 29.4, 33.3, 13.7,
 11.8, 3.9, NULL, 51,
 'manufacturer', ARRAY['huel bar peanut caramel', 'huel protein bar peanut', 'huel nutrition bar peanut caramel', 'huel bar peanut butter', 'huel complete bar peanut'],
 'protein_bar', 'Huel', 1, '210 cal per bar (51g). 15g protein, 17g carbs, 7g fat, 6g fiber. 27 vitamins & minerals. Vegan.', TRUE),

-- ══════════════════════════════════════════
-- HUEL — DAILY GREENS
-- Per scoop (8.5g): 25 cal, <1g P, 5g C, 0g F, 1g fiber
-- per 100g = (value / 8.5) * 100
-- ══════════════════════════════════════════

-- Huel Daily Greens: 25 cal / 8.5g scoop
('huel_greens', 'Huel Daily Greens', 294, 5.9, 58.8, 0.0,
 11.8, 5.9, 8.5, NULL,
 'manufacturer', ARRAY['huel daily greens', 'huel greens powder', 'huel super greens', 'huel greens supplement', 'huel daily greens powder'],
 'greens_powder', 'Huel', 1, '25 cal per scoop (8.5g). <1g protein, 5g carbs, 0g fat, 1g fiber. 91 vitamins, minerals, and wholefood-sourced ingredients. Adaptogens and probiotics.', TRUE)

ON CONFLICT (food_name_normalized) DO UPDATE SET
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
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
