-- 1631_overrides_organ_meats_animal_fats.sql
-- Carnivore / animal-based / ancestral diet staples: organ meats, animal fats.
-- Sources: USDA FoodData Central (fdc.nal.usda.gov).
-- All values per 100g. default_serving_g = typical serving weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- ORGAN MEATS (cooked unless noted)
-- ══════════════════════════════════════════

-- Beef liver, pan-fried: USDA 172468. 175 cal, 26g P, 5.2g C, 4.7g F per 100g
('beef_liver_cooked', 'Beef Liver (Cooked)', 175, 26.0, 5.2, 4.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['beef liver', 'beef liver cooked', 'pan fried beef liver', 'liver and onions', 'calves liver', 'calf liver'],
 'organ_meat', NULL, 1, '175 cal per 100g (149 cal per 85g serving). Exceptionally rich in vitamin A (1049% DV), B12 (1386% DV), copper, and iron. Carnivore diet superfood.', TRUE),

-- Chicken liver, pan-fried: USDA 172561. 167 cal, 25.8g P, 0.9g C, 6.4g F per 100g
('chicken_liver_cooked', 'Chicken Liver (Cooked)', 167, 25.8, 0.9, 6.4,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['chicken liver', 'chicken liver cooked', 'pan fried chicken liver', 'chicken livers', 'fried chicken livers'],
 'organ_meat', NULL, 1, '167 cal per 100g (142 cal per 85g serving). Very high in vitamin A, B12, and folate. Milder flavor than beef liver.', TRUE),

-- Beef heart, simmered: USDA 172459. 165 cal, 28.5g P, 0.1g C, 4.7g F per 100g
('beef_heart_cooked', 'Beef Heart (Cooked)', 165, 28.5, 0.1, 4.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['beef heart', 'beef heart cooked', 'ox heart', 'heart meat', 'simmered beef heart'],
 'organ_meat', NULL, 1, '165 cal per 100g (140 cal per 85g serving). High in CoQ10, B12, iron, and zinc. Lean organ meat with meaty flavor.', TRUE),

-- Beef kidney, simmered: USDA 172464. 158 cal, 27.3g P, 0.0g C, 4.7g F per 100g
('beef_kidney_cooked', 'Beef Kidney (Cooked)', 158, 27.3, 0.0, 4.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['beef kidney', 'beef kidney cooked', 'kidneys', 'simmered beef kidney', 'steak and kidney'],
 'organ_meat', NULL, 1, '158 cal per 100g (134 cal per 85g serving). Excellent source of B12, selenium, and iron. Traditional in British cuisine.', TRUE),

-- Beef tongue, simmered: USDA 172472. 284 cal, 22.3g P, 0.0g C, 20.7g F per 100g
('beef_tongue_cooked', 'Beef Tongue (Cooked)', 284, 22.3, 0.0, 20.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['beef tongue', 'beef tongue cooked', 'lengua', 'ox tongue', 'simmered beef tongue', 'braised tongue'],
 'organ_meat', NULL, 1, '284 cal per 100g (241 cal per 85g serving). Rich, tender meat high in B12, zinc, and iron. Popular in Mexican (lengua) and Jewish cuisine.', TRUE),

-- Oxtail, cooked: USDA 172474. 262 cal, 30.0g P, 0.0g C, 14.9g F per 100g
('oxtail_cooked', 'Oxtail (Cooked)', 262, 30.0, 0.0, 14.9,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['oxtail', 'oxtail cooked', 'braised oxtail', 'oxtail stew', 'oxtail soup', 'ox tail'],
 'organ_meat', NULL, 1, '262 cal per 100g (223 cal per 85g serving). Rich in collagen and gelatin. Excellent for bone broth and slow-cooked stews.', TRUE),

-- Bone marrow, raw: USDA 172457. 786 cal, 6.7g P, 0.0g C, 84.4g F per 100g
('bone_marrow_raw', 'Bone Marrow (Raw)', 786, 6.7, 0.0, 84.4,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['bone marrow', 'bone marrow raw', 'beef bone marrow', 'marrow bone', 'roasted bone marrow'],
 'organ_meat', NULL, 1, '786 cal per 100g (110 cal per 14g/1 tbsp). Almost pure fat. Rich in conjugated linoleic acid and fat-soluble vitamins.', TRUE),

-- ══════════════════════════════════════════
-- ANIMAL FATS & COOKING FATS
-- ══════════════════════════════════════════

-- Beef tallow: USDA 171400. 902 cal, 0g P, 0g C, 100g F per 100g
('beef_tallow', 'Beef Tallow', 902, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['beef tallow', 'tallow', 'rendered beef fat', 'beef dripping', 'beef suet rendered'],
 'cooking_fat', NULL, 1, '902 cal per 100g (126 cal per 14g/1 tbsp). Traditional cooking fat, high smoke point (250°C). Carnivore/keto staple.', TRUE),

-- Duck fat: USDA 171401. 882 cal, 0g P, 0g C, 99.8g F per 100g
('duck_fat', 'Duck Fat', 882, 0.0, 0.0, 99.8,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['duck fat', 'rendered duck fat', 'duck fat cooking', 'duck drippings'],
 'cooking_fat', NULL, 1, '882 cal per 100g (123 cal per 14g/1 tbsp). Gourmet cooking fat. High in monounsaturated fat (oleic acid). 190°C smoke point.', TRUE),

-- Pork belly, raw: USDA 167818. 518 cal, 9.3g P, 0.0g C, 53.0g F per 100g
('pork_belly_raw', 'Pork Belly (Raw)', 518, 9.3, 0.0, 53.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['pork belly', 'pork belly raw', 'raw pork belly', 'uncured pork belly', 'pork belly slices', 'fresh pork belly'],
 'pork', NULL, 1, '518 cal per 100g (440 cal per 85g serving). High fat cut popular in Asian cuisine and BBQ. Base for bacon.', TRUE),

-- Bacon, generic cooked (pan-fried): USDA 168322. 541 cal, 37.0g P, 1.4g C, 42.0g F per 100g
('bacon_generic_cooked', 'Bacon (Cooked)', 541, 37.0, 1.4, 42.0,
 0.0, 0.0, 8, NULL,
 'usda', ARRAY['bacon', 'bacon cooked', 'fried bacon', 'pan fried bacon', 'crispy bacon', 'bacon strips', 'pork bacon'],
 'pork', NULL, 1, '541 cal per 100g (43 cal per slice/8g). Classic breakfast staple. High protein when cooked crispy. Carnivore/keto friendly.', TRUE),

-- Beef suet, raw: USDA 172457. 854 cal, 1.5g P, 0.0g C, 94.0g F per 100g
('beef_suet_raw', 'Beef Suet (Raw)', 854, 1.5, 0.0, 94.0,
 0.0, 0.0, 28, NULL,
 'usda', ARRAY['beef suet', 'suet', 'raw suet', 'beef kidney fat', 'suet raw'],
 'cooking_fat', NULL, 1, '854 cal per 100g (239 cal per 28g/1oz). Hard fat around kidneys. Used for rendering tallow, suet pudding, and traditional cooking.', TRUE)

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
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
