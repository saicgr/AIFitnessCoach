-- 1602_overrides_pressed_juicery.sql
-- Pressed Juicery (~100+ locations) — cold-pressed juices, wellness shots,
-- almond milks, freezes.
-- Sources: pressed.com (official), FatSecret, CarbManager, MyNetDiary.
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- PRESSED JUICERY — DAILY GREENS JUICES
-- ══════════════════════════════════════════

-- Pressed Juicery Daily Greens 1 (Cucumber Lemon): 50 cal per bottle (450g)
('pressed_daily_greens_1', 'Pressed Juicery Daily Greens 1 (Cucumber Lemon)', 11.1, 0.4, 2.2, 0.0,
 0.2, 2.0, NULL, 450,
 'manufacturer', ARRAY['pressed juicery greens 1', 'pressed greens 1 cucumber lemon', 'pressed juicery daily greens 1', 'pressed greens juice'],
 'juice', 'Pressed Juicery', 1, '50 cal per bottle (450ml). Cold-pressed cucumber, celery, lemon, spinach, kale, parsley.', TRUE),

-- Pressed Juicery Daily Greens 2 (Sweet Apple): 140 cal per bottle (450g)
('pressed_daily_greens_2', 'Pressed Juicery Daily Greens 2 (Sweet Apple)', 31.1, 0.2, 7.3, 0.0,
 0.0, 6.2, NULL, 450,
 'manufacturer', ARRAY['pressed juicery greens 2', 'pressed greens 2 sweet apple', 'pressed juicery daily greens 2', 'pressed green juice apple'],
 'juice', 'Pressed Juicery', 1, '140 cal per bottle (450ml). Cold-pressed apple, cucumber, celery, spinach, kale, lemon.', TRUE),

-- Pressed Juicery Daily Greens 3 (Ginger): 130 cal per bottle (450g)
('pressed_daily_greens_3', 'Pressed Juicery Daily Greens 3 (Ginger)', 28.9, 0.2, 7.1, 0.0,
 0.0, 6.0, NULL, 450,
 'manufacturer', ARRAY['pressed juicery greens 3', 'pressed greens 3 ginger', 'pressed juicery daily greens 3', 'pressed green juice ginger'],
 'juice', 'Pressed Juicery', 1, '130 cal per bottle (450ml). Cold-pressed apple, cucumber, celery, spinach, kale, ginger, lemon.', TRUE),

-- Pressed Juicery Daily Greens 4: 35 cal per 8 fl oz (240g)
('pressed_daily_greens_4', 'Pressed Juicery Daily Greens 4', 14.6, 0.4, 3.3, 0.0,
 0.4, 1.3, 240, NULL,
 'manufacturer', ARRAY['pressed juicery greens 4', 'pressed greens 4', 'pressed juicery daily greens 4', 'pressed green juice light'],
 'juice', 'Pressed Juicery', 1, '35 cal per 8 fl oz (240ml). Light cold-pressed green juice.', TRUE),

-- ══════════════════════════════════════════
-- PRESSED JUICERY — DAILY CITRUS JUICES
-- ══════════════════════════════════════════

-- Pressed Juicery Daily Citrus 1 (Cucumber Coconut Water): 130 cal per bottle (450g)
('pressed_daily_citrus_1', 'Pressed Juicery Daily Citrus 1 (Cucumber Coconut Water)', 28.9, 0.2, 6.7, 0.0,
 0.4, 5.3, NULL, 450,
 'manufacturer', ARRAY['pressed juicery citrus 1', 'pressed citrus 1 cucumber coconut', 'pressed juicery daily citrus 1', 'pressed citrus juice'],
 'juice', 'Pressed Juicery', 1, '130 cal per bottle (450ml). Cold-pressed with cucumber, coconut water, pineapple, lemon.', TRUE),

-- Pressed Juicery Daily Citrus 2 (Pineapple Mint): 240 cal per bottle (450g)
('pressed_daily_citrus_2', 'Pressed Juicery Daily Citrus 2 (Pineapple Mint)', 53.3, 0.0, 12.9, 0.0,
 0.0, 10.9, NULL, 450,
 'manufacturer', ARRAY['pressed juicery citrus 2', 'pressed citrus 2 pineapple mint', 'pressed juicery daily citrus 2', 'pressed pineapple juice'],
 'juice', 'Pressed Juicery', 1, '240 cal per bottle (450ml). Cold-pressed pineapple, orange, mint, lemon.', TRUE),

-- Pressed Juicery Daily Citrus 3 (Grapefruit Aloe Vera): 140 cal per bottle (450g)
('pressed_daily_citrus_3', 'Pressed Juicery Daily Citrus 3 (Grapefruit Aloe Vera)', 31.1, 0.2, 7.6, 0.0,
 0.7, 6.7, NULL, 450,
 'manufacturer', ARRAY['pressed juicery citrus 3', 'pressed citrus 3 grapefruit aloe', 'pressed juicery daily citrus 3', 'pressed grapefruit juice'],
 'juice', 'Pressed Juicery', 1, '140 cal per bottle (450ml). Cold-pressed grapefruit, orange, aloe vera, lemon.', TRUE),

-- ══════════════════════════════════════════
-- PRESSED JUICERY — DAILY ROOTS JUICES
-- ══════════════════════════════════════════

-- Pressed Juicery Daily Roots 1 (Butternut Squash Beet): 130 cal per bottle (450g)
('pressed_daily_roots_1', 'Pressed Juicery Daily Roots 1 (Butternut Squash Beet)', 28.9, 0.9, 6.9, 0.0,
 0.7, 4.0, NULL, 450,
 'manufacturer', ARRAY['pressed juicery roots 1', 'pressed roots 1 butternut squash beet', 'pressed juicery daily roots 1', 'pressed roots juice'],
 'juice', 'Pressed Juicery', 1, '130 cal per bottle (450ml). Cold-pressed butternut squash, beet, apple, lemon, ginger.', TRUE),

-- Pressed Juicery Daily Roots 2 (Sweet Apple): 160 cal per bottle (450g)
('pressed_daily_roots_2', 'Pressed Juicery Daily Roots 2 (Sweet Apple)', 35.6, 0.7, 8.9, 0.0,
 0.9, 5.1, NULL, 450,
 'manufacturer', ARRAY['pressed juicery roots 2', 'pressed roots 2 sweet apple', 'pressed juicery daily roots 2', 'pressed beet juice apple'],
 'juice', 'Pressed Juicery', 1, '160 cal per bottle (450ml). Cold-pressed beet, apple, carrot, ginger, lemon.', TRUE),

-- Pressed Juicery Daily Roots 3 (Ginger): 190 cal per bottle (450g)
('pressed_daily_roots_3', 'Pressed Juicery Daily Roots 3 (Ginger)', 42.2, 0.0, 10.7, 0.0,
 0.0, 8.9, NULL, 450,
 'manufacturer', ARRAY['pressed juicery roots 3', 'pressed roots 3 ginger', 'pressed juicery daily roots 3', 'pressed beet juice ginger'],
 'juice', 'Pressed Juicery', 1, '190 cal per bottle (450ml). Cold-pressed beet, apple, carrot, ginger, lemon.', TRUE),

-- ══════════════════════════════════════════
-- PRESSED JUICERY — WELLNESS SHOTS
-- ══════════════════════════════════════════

-- Pressed Juicery Immunity Shot: 25 cal per shot (59g)
('pressed_immunity_shot', 'Pressed Juicery Immunity Shot', 42.4, 0.0, 8.5, 0.0,
 0.0, 5.1, NULL, 59,
 'manufacturer', ARRAY['pressed juicery immunity shot', 'pressed immunity shot', 'pressed juicery wellness shot immunity', 'pressed juice shot'],
 'wellness_shot', 'Pressed Juicery', 1, '25 cal per 2oz shot (59g). Cold-pressed with ginger, turmeric, vitamin C.', TRUE),

-- Pressed Juicery Energy Shot: 35 cal per shot (59g)
('pressed_energy_shot', 'Pressed Juicery Energy Shot', 59.3, 1.7, 11.9, 0.0,
 0.0, 10.2, NULL, 59,
 'manufacturer', ARRAY['pressed juicery energy shot', 'pressed energy shot', 'pressed juicery wellness shot energy', 'pressed matcha shot'],
 'wellness_shot', 'Pressed Juicery', 1, '35 cal per 2oz shot (59g). Cold-pressed with matcha, lemon, agave.', TRUE),

-- Pressed Juicery Ginger Lemon Cayenne Shot: 5 cal per shot (59g)
('pressed_ginger_lemon_cayenne_shot', 'Pressed Juicery Ginger Lemon Cayenne Shot', 8.5, 0.0, 3.4, 0.0,
 0.0, 0.0, NULL, 59,
 'manufacturer', ARRAY['pressed juicery ginger lemon cayenne shot', 'pressed wellness shot', 'pressed ginger shot', 'pressed juicery cayenne shot'],
 'wellness_shot', 'Pressed Juicery', 1, '5 cal per 2oz shot (59g). Cold-pressed ginger, lemon, cayenne pepper.', TRUE),

-- Pressed Juicery Debloat Shot: 30 cal per shot (59g)
('pressed_debloat_shot', 'Pressed Juicery Debloat Shot', 50.8, 0.0, 11.9, 0.0,
 0.0, 8.5, NULL, 59,
 'manufacturer', ARRAY['pressed juicery debloat shot', 'pressed debloat shot', 'pressed juicery digestion shot', 'pressed digestive shot'],
 'wellness_shot', 'Pressed Juicery', 1, '30 cal per 2oz shot (59g). Cold-pressed for digestive support.', TRUE),

-- Pressed Juicery Elderberry Shot: 30 cal per shot (59g)
('pressed_elderberry_shot', 'Pressed Juicery Elderberry Shot', 50.8, 0.0, 13.6, 0.0,
 0.0, 8.5, NULL, 59,
 'manufacturer', ARRAY['pressed juicery elderberry shot', 'pressed elderberry shot', 'pressed juicery wellness shot elderberry', 'pressed immune shot elderberry'],
 'wellness_shot', 'Pressed Juicery', 1, '30 cal per 2oz shot (59g). Cold-pressed elderberry for immune support.', TRUE),

-- Pressed Juicery Beauty Shot: 30 cal per shot (59g)
('pressed_beauty_shot', 'Pressed Juicery Beauty Shot', 50.8, 0.0, 11.9, 0.0,
 0.0, 10.2, NULL, 59,
 'manufacturer', ARRAY['pressed juicery beauty shot', 'pressed beauty shot', 'pressed juicery wellness shot beauty', 'pressed collagen shot'],
 'wellness_shot', 'Pressed Juicery', 1, '30 cal per 2oz shot (59g). Cold-pressed with ingredients for skin and hair support.', TRUE),

-- Pressed Juicery Turmeric Glow Shot: 10 cal per shot (59g)
('pressed_turmeric_glow_shot', 'Pressed Juicery Turmeric Glow Shot', 16.9, 0.0, 3.4, 0.0,
 0.0, 0.0, NULL, 59,
 'manufacturer', ARRAY['pressed juicery turmeric glow shot', 'pressed turmeric shot', 'pressed juicery wellness shot turmeric', 'pressed anti-inflammatory shot'],
 'wellness_shot', 'Pressed Juicery', 1, '10 cal per 2oz shot (59g). Cold-pressed turmeric, ginger, lemon, black pepper.', TRUE),

-- ══════════════════════════════════════════
-- PRESSED JUICERY — ALMOND MILKS
-- ══════════════════════════════════════════

-- Pressed Juicery Vanilla Almond Milk: 250 cal per bottle (450g)
('pressed_vanilla_almond_milk', 'Pressed Juicery Vanilla Almond Milk', 55.6, 1.6, 5.8, 3.1,
 0.0, 2.4, NULL, 450,
 'manufacturer', ARRAY['pressed juicery vanilla almond milk', 'pressed vanilla almond milk', 'pressed juicery almond milk vanilla', 'pressed nut milk vanilla'],
 'beverage', 'Pressed Juicery', 1, '250 cal per bottle (450ml). Cold-pressed almond milk with vanilla, dates, cinnamon.', TRUE),

-- Pressed Juicery Chocolate Almond Milk: 250 cal per bottle (450g)
('pressed_chocolate_almond_milk', 'Pressed Juicery Chocolate Almond Milk', 55.6, 1.3, 5.3, 2.9,
 0.0, 4.0, NULL, 450,
 'manufacturer', ARRAY['pressed juicery chocolate almond milk', 'pressed chocolate almond milk', 'pressed juicery almond milk chocolate', 'pressed nut milk chocolate'],
 'beverage', 'Pressed Juicery', 1, '250 cal per bottle (450ml). Cold-pressed almond milk with cacao, dates, vanilla.', TRUE),

-- ══════════════════════════════════════════
-- PRESSED JUICERY — FREEZES (DAIRY-FREE SOFT SERVE)
-- ══════════════════════════════════════════

-- Pressed Juicery Vanilla Freeze: 220 cal per serving (~200g)
('pressed_vanilla_freeze', 'Pressed Juicery Vanilla Freeze', 110.0, 2.0, 16.5, 0.0,
 0.0, 0.0, 200, NULL,
 'manufacturer', ARRAY['pressed juicery vanilla freeze', 'pressed vanilla freeze', 'pressed juicery freeze vanilla', 'pressed soft serve vanilla', 'pressed dairy free ice cream'],
 'dessert', 'Pressed Juicery', 1, '220 cal per serving (~200g). Dairy-free soft serve made from fruits and vegetables.', TRUE)

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
