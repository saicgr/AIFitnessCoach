-- 1632_overrides_fermented_foods_seaweed.sql
-- Fermented foods (gut health / microbiome diet) and seaweed / sea vegetables
-- (Japanese / thyroid / iodine diets).
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
-- FERMENTED FOODS
-- ══════════════════════════════════════════

-- Sauerkraut, canned: USDA 169279. 19 cal, 0.9g P, 4.3g C, 0.1g F per 100g
('sauerkraut', 'Sauerkraut', 19, 0.9, 4.3, 0.1,
 2.9, 1.8, 142, NULL,
 'usda', ARRAY['sauerkraut', 'fermented cabbage', 'sauerkraut canned', 'german sauerkraut', 'raw sauerkraut', 'kraut'],
 'fermented_food', NULL, 1, '19 cal per 100g (27 cal per 1 cup/142g). Rich in probiotics, vitamin C, and vitamin K. Low calorie gut health food.', TRUE),

-- Kimchi: USDA 174963. 15 cal, 1.1g P, 2.4g C, 0.5g F per 100g
('kimchi', 'Kimchi', 15, 1.1, 2.4, 0.5,
 1.6, 1.1, 150, NULL,
 'usda', ARRAY['kimchi', 'kimchee', 'korean kimchi', 'napa cabbage kimchi', 'fermented kimchi', 'baechu kimchi'],
 'fermented_food', NULL, 1, '15 cal per 100g (23 cal per 1 cup/150g). Korean fermented vegetables. Rich in probiotics, vitamins A/C/K. Anti-inflammatory.', TRUE),

-- Natto: USDA 172443. 212 cal, 17.7g P, 14.4g C, 11.0g F per 100g
('natto', 'Natto (Fermented Soybeans)', 212, 17.7, 14.4, 11.0,
 5.4, 4.9, 45, NULL,
 'usda', ARRAY['natto', 'fermented soybeans', 'japanese natto', 'nattō', 'fermented soy beans'],
 'fermented_food', NULL, 1, '212 cal per 100g (95 cal per 45g serving). Japanese fermented soybeans. Richest food source of vitamin K2 (MK-7). High in protein and nattokinase.', TRUE),

-- Kefir, plain whole milk: USDA 172186. 63 cal, 3.3g P, 4.8g C, 3.5g F per 100g
('kefir_plain', 'Kefir (Plain, Whole Milk)', 63, 3.3, 4.8, 3.5,
 0.0, 4.6, 243, NULL,
 'usda', ARRAY['kefir', 'plain kefir', 'whole milk kefir', 'milk kefir', 'kefir plain', 'kefir drink'],
 'fermented_food', NULL, 1, '63 cal per 100g (153 cal per 1 cup/243g). Fermented milk drink with 30+ probiotic strains. More diverse cultures than yogurt. Good source of calcium.', TRUE),

-- Pickled ginger (gari): USDA 168559. 20 cal, 0.2g P, 4.6g C, 0.0g F per 100g
('pickled_ginger', 'Pickled Ginger (Gari)', 20, 0.2, 4.6, 0.0,
 0.5, 3.1, 28, NULL,
 'usda', ARRAY['pickled ginger', 'gari', 'sushi ginger', 'pickled ginger slices', 'ginger pickle', 'japanese pickled ginger'],
 'fermented_food', NULL, 1, '20 cal per 100g (6 cal per 28g serving). Thinly sliced ginger pickled in vinegar. Palate cleanser served with sushi. Aids digestion.', TRUE),

-- Kombucha (plain): ~30 cal, 0g P, 7g C, 0g F per 100g (average of brands)
('kombucha_plain', 'Kombucha (Plain)', 30, 0.0, 7.0, 0.0,
 0.0, 5.0, 240, NULL,
 'usda', ARRAY['kombucha', 'plain kombucha', 'kombucha tea', 'fermented tea', 'raw kombucha'],
 'fermented_food', NULL, 1, '30 cal per 100g (72 cal per 8oz/240ml). Fermented tea rich in probiotics, B vitamins, and organic acids. Low sugar option for gut health.', TRUE),

-- ══════════════════════════════════════════
-- SEAWEED / SEA VEGETABLES
-- ══════════════════════════════════════════

-- Nori, dried: USDA 167608. 35 cal per sheet (~3g). Per 100g: 349 cal, 46.1g P
('nori_sheets', 'Nori Sheets (Dried)', 349, 46.1, 5.1, 0.3,
 0.3, 0.5, NULL, 3,
 'usda', ARRAY['nori', 'nori sheets', 'dried nori', 'seaweed sheets', 'sushi nori', 'roasted seaweed', 'seaweed snack'],
 'seaweed', NULL, 1, '349 cal per 100g (~10 cal per sheet/3g). Used for sushi wrapping and snacking. High in iodine, B12, and iron. Very low calorie per sheet.', TRUE),

-- Kelp/Kombu, dried: USDA 167607. 43 cal, 1.7g P, 9.6g C, 0.6g F per 100g
('kelp_kombu_dried', 'Kelp / Kombu (Dried)', 43, 1.7, 9.6, 0.6,
 1.3, 0.6, 10, NULL,
 'usda', ARRAY['kelp', 'kombu', 'dried kelp', 'dried kombu', 'dashi kombu', 'sea kelp', 'kelp seaweed'],
 'seaweed', NULL, 1, '43 cal per 100g (4 cal per 10g piece). Base for Japanese dashi stock. Extremely high in iodine (2984% DV per 100g). Rich in glutamate (umami).', TRUE),

-- Wakame, dried: USDA 167609. 45 cal, 3.0g P, 8.6g C, 0.6g F per 100g
('wakame_dried', 'Wakame (Dried)', 45, 3.0, 8.6, 0.6,
 0.5, 0.5, 10, NULL,
 'usda', ARRAY['wakame', 'dried wakame', 'wakame seaweed', 'seaweed salad wakame', 'miso soup seaweed'],
 'seaweed', NULL, 1, '45 cal per 100g (5 cal per 10g serving, rehydrates to ~80g). Used in miso soup and seaweed salad. Good source of iodine, manganese, and folate.', TRUE),

-- Dulse, dried: USDA 167606. 247 cal, 21.5g P, 44.5g C, 1.7g F per 100g
('dulse_dried', 'Dulse (Dried)', 247, 21.5, 44.5, 1.7,
 4.7, 0.0, 10, NULL,
 'usda', ARRAY['dulse', 'dried dulse', 'dulse flakes', 'dulse seaweed', 'red seaweed', 'sea lettuce dulse'],
 'seaweed', NULL, 1, '247 cal per 100g (25 cal per 10g serving). Red seaweed, smoky/salty flavor. High in protein for seaweed. Rich in iron, potassium, and B6.', TRUE),

-- Arame, dried: 260 cal, 7.5g P, 56g C, 0.1g F per 100g (est.)
('arame_dried', 'Arame (Dried)', 260, 7.5, 56.0, 0.1,
 7.0, 0.0, 7, NULL,
 'usda', ARRAY['arame', 'dried arame', 'arame seaweed', 'japanese arame', 'sea oak arame'],
 'seaweed', NULL, 1, '260 cal per 100g (18 cal per 7g serving, rehydrates 5x). Mild, slightly sweet Japanese seaweed. Good source of calcium, iron, and iodine. Used in salads and stir-fries.', TRUE),

-- Irish moss / carrageenan (raw seaweed): USDA 167614. 49 cal, 1.5g P, 12.3g C, 0.2g F per 100g
('irish_moss_raw', 'Irish Moss / Sea Moss (Raw)', 49, 1.5, 12.3, 0.2,
 1.3, 0.0, 10, NULL,
 'usda', ARRAY['irish moss', 'sea moss', 'carrageen moss', 'irish sea moss', 'raw sea moss', 'chondrus crispus'],
 'seaweed', NULL, 1, '49 cal per 100g (5 cal per 10g serving). Atlantic red algae used as natural thickener. Contains 92 of 102 minerals the body needs. Popular health supplement.', TRUE)

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
