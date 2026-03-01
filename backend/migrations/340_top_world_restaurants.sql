-- 340_top_world_restaurants.sql
-- Top international restaurant chains: Greggs, Wetherspoons, Pizza Express (UK),
-- Swiss Chalet, Harvey's, A&W Canada (Canada), CoCo Ichibanya, Ichiran Ramen,
-- Genki Sushi (Japan), Nando's, Guzman y Gomez (Australia), Leon, Dishoom (UK).
-- Sources: official brand nutrition pages, fatsecret.co.uk, nutritionix.com,
-- calorieking.com, fastfoodnutrition.org, eatthismuch.com, USDA FoodData Central.
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g
) VALUES

-- ==========================================
-- GREGGS (UK Bakery Chain)
-- ==========================================

-- Greggs Sausage Roll: 103g per roll, 348 cal. Per 100g: 338 cal, 8.9P, 23.3C, 23.3F, 1.5 fiber, 0 sugar, 10.7 sat fat.
('greggs_sausage_roll', 'Greggs Sausage Roll', 338, 8.9, 23.3, 23.3,
 1.5, 0.0, 103, NULL,
 'greggs', ARRAY['greggs sausage roll', 'sausage roll greggs', 'greggs roll'],
 'bakery', 'Greggs', 1, '338 cal/100g. Per roll (103g): 348 cal. Pork sausage meat in flaky pastry.', TRUE,
 582, 35, 10.7, 0.1, 120, 30, 1.2, 5, 0.0, 0, 12, 1.0, 95, 10.0, 0.02),

-- Greggs Vegan Sausage Roll: 101g per roll, 312 cal. Per 100g: 309 cal, 10.9P, 22.8C, 18.8F.
('greggs_vegan_sausage_roll', 'Greggs Vegan Sausage Roll', 309, 10.9, 22.8, 18.8,
 2.0, 0.5, 101, NULL,
 'greggs', ARRAY['greggs vegan sausage roll', 'vegan sausage roll greggs', 'greggs vegan roll'],
 'bakery', 'Greggs', 1, '309 cal/100g. Per roll (101g): 312 cal. Quorn filling in puff pastry.', TRUE,
 550, 0, 8.6, 0.1, 140, 25, 2.0, 0, 0.0, 0, 18, 0.8, 80, 5.0, 0.01),

-- Greggs Steak Bake: 136g per bake, 408 cal. Per 100g: 300 cal, 9.6P, 22.1C, 19.1F.
('greggs_steak_bake', 'Greggs Steak Bake', 300, 9.6, 22.1, 19.1,
 1.0, 0.5, 136, NULL,
 'greggs', ARRAY['greggs steak bake', 'steak bake greggs', 'greggs steak'],
 'bakery', 'Greggs', 1, '300 cal/100g. Per bake (136g): 408 cal. Beef steak in gravy with pastry.', TRUE,
 520, 30, 8.8, 0.1, 150, 25, 1.8, 3, 0.0, 0, 14, 1.5, 90, 8.0, 0.02),

-- Greggs Chicken Bake: 132g per bake, 424 cal. Per 100g: 321 cal, 10.6P, 23.5C, 20.5F.
('greggs_chicken_bake', 'Greggs Chicken Bake', 321, 10.6, 23.5, 20.5,
 1.0, 0.8, 132, NULL,
 'greggs', ARRAY['greggs chicken bake', 'chicken bake greggs'],
 'bakery', 'Greggs', 1, '321 cal/100g. Per bake (132g): 424 cal. Chicken in creamy sauce with pastry.', TRUE,
 490, 32, 9.5, 0.1, 130, 35, 1.0, 15, 0.0, 2, 15, 0.9, 100, 9.0, 0.02),

-- Greggs Cheese & Onion Bake: 128g per bake, 352 cal. Per 100g: 275 cal, 6.3P, 23.8C, 16.9F.
('greggs_cheese_onion_bake', 'Greggs Cheese & Onion Bake', 275, 6.3, 23.8, 16.9,
 1.2, 1.5, 128, NULL,
 'greggs', ARRAY['greggs cheese and onion bake', 'cheese onion bake greggs', 'greggs cheese & onion bake'],
 'bakery', 'Greggs', 1, '275 cal/100g. Per bake (128g): 352 cal. Cheese and onion in puff pastry.', TRUE,
 480, 25, 8.0, 0.1, 100, 90, 0.8, 30, 0.0, 2, 12, 0.7, 110, 6.0, 0.01),

-- Greggs Ham & Cheese Baguette: 210g per baguette, 462 cal. Per 100g: 220 cal, 11.0P, 26.0C, 7.6F.
('greggs_ham_cheese_baguette', 'Greggs Ham & Cheese Baguette', 220, 11.0, 26.0, 7.6,
 1.5, 2.0, 210, NULL,
 'greggs', ARRAY['greggs ham and cheese baguette', 'ham cheese baguette greggs'],
 'bakery', 'Greggs', 1, '220 cal/100g. Per baguette (210g): 462 cal. Ham and cheese in white baguette.', TRUE,
 520, 25, 3.2, 0.0, 120, 80, 1.5, 10, 0.0, 2, 18, 1.0, 130, 12.0, 0.01),

-- Greggs Tuna Crunch Baguette: 225g per baguette, 454 cal. Per 100g: 202 cal, 9.3P, 24.0C, 7.3F.
('greggs_tuna_crunch_baguette', 'Greggs Tuna Crunch Baguette', 202, 9.3, 24.0, 7.3,
 1.5, 2.0, 225, NULL,
 'greggs', ARRAY['greggs tuna crunch baguette', 'tuna baguette greggs', 'greggs tuna mayo baguette'],
 'bakery', 'Greggs', 1, '202 cal/100g. Per baguette (225g): 454 cal. Tuna mayo with sweetcorn in baguette.', TRUE,
 400, 20, 1.2, 0.0, 130, 30, 1.2, 8, 0.0, 10, 20, 0.5, 110, 18.0, 0.10),

-- Greggs Bacon Roll: 115g per roll, 292 cal. Per 100g: 254 cal, 13.0P, 22.0C, 12.2F.
('greggs_bacon_roll', 'Greggs Bacon Roll', 254, 13.0, 22.0, 12.2,
 1.0, 1.5, 115, NULL,
 'greggs', ARRAY['greggs bacon roll', 'bacon roll greggs', 'greggs bacon bap'],
 'bakery', 'Greggs', 1, '254 cal/100g. Per roll (115g): 292 cal. Smoked bacon in a soft roll.', TRUE,
 680, 30, 4.5, 0.1, 150, 25, 1.0, 0, 0.0, 5, 14, 1.2, 100, 12.0, 0.01),

-- Greggs Sausage Breakfast Roll: 135g per roll, 378 cal. Per 100g: 280 cal, 10.0P, 21.0C, 17.0F.
('greggs_sausage_breakfast_roll', 'Greggs Sausage Breakfast Roll', 280, 10.0, 21.0, 17.0,
 1.0, 1.0, 135, NULL,
 'greggs', ARRAY['greggs sausage breakfast roll', 'sausage breakfast roll greggs'],
 'bakery', 'Greggs', 1, '280 cal/100g. Per roll (135g): 378 cal. Sausage in a soft breakfast roll.', TRUE,
 600, 35, 6.5, 0.1, 130, 28, 1.3, 5, 0.0, 3, 13, 1.1, 95, 10.0, 0.02),

-- Greggs Yum Yum: 75g per piece, 311 cal. Per 100g: 415 cal, 4.5P, 48.0C, 23.0F.
('greggs_yum_yum', 'Greggs Yum Yum', 415, 4.5, 48.0, 23.0,
 1.0, 20.0, 75, NULL,
 'greggs', ARRAY['greggs yum yum', 'yum yum greggs', 'greggs glazed yum yum'],
 'bakery', 'Greggs', 1, '415 cal/100g. Per piece (75g): 311 cal. Twisted glazed doughnut pastry.', TRUE,
 200, 15, 10.0, 0.2, 60, 20, 0.8, 10, 0.0, 0, 8, 0.3, 40, 5.0, 0.01),

-- Greggs Ring Donut: 65g per donut, 260 cal. Per 100g: 400 cal, 4.6P, 48.5C, 21.5F.
('greggs_ring_donut', 'Greggs Ring Donut', 400, 4.6, 48.5, 21.5,
 1.0, 22.0, 65, NULL,
 'greggs', ARRAY['greggs ring donut', 'ring donut greggs', 'greggs doughnut'],
 'bakery', 'Greggs', 1, '400 cal/100g. Per donut (65g): 260 cal. Sugar-glazed ring doughnut.', TRUE,
 220, 15, 9.5, 0.2, 55, 25, 0.7, 8, 0.0, 0, 7, 0.3, 38, 5.0, 0.01),

-- Greggs Festive Bake: 132g per bake, 453 cal. Per 100g: 343 cal, 8.3P, 23.0C, 24.2F.
('greggs_festive_bake', 'Greggs Festive Bake', 343, 8.3, 23.0, 24.2,
 1.0, 1.0, 132, NULL,
 'greggs', ARRAY['greggs festive bake', 'festive bake greggs', 'greggs christmas bake'],
 'bakery', 'Greggs', 1, '343 cal/100g. Per bake (132g): 453 cal. Chicken, bacon, stuffing in creamy sage sauce.', TRUE,
 510, 30, 11.0, 0.1, 125, 30, 1.0, 12, 0.0, 2, 13, 0.8, 90, 8.0, 0.02),

-- Greggs Mexican Chicken Baguette: 220g per baguette, 462 cal. Per 100g: 210 cal, 10.5P, 25.0C, 7.0F.
('greggs_mexican_chicken_baguette', 'Greggs Mexican Chicken Baguette', 210, 10.5, 25.0, 7.0,
 1.8, 2.5, 220, NULL,
 'greggs', ARRAY['greggs mexican chicken baguette', 'mexican chicken baguette greggs'],
 'bakery', 'Greggs', 1, '210 cal/100g. Per baguette (220g): 462 cal. Spiced chicken with peppers.', TRUE,
 480, 22, 2.5, 0.0, 140, 30, 1.2, 15, 3.0, 0, 16, 0.7, 100, 10.0, 0.01),

-- Greggs Pizza Slice: 125g per slice, 294 cal. Per 100g: 235 cal, 9.6P, 25.6C, 10.4F.
('greggs_pizza_slice', 'Greggs Pizza Slice', 235, 9.6, 25.6, 10.4,
 1.5, 3.0, 125, NULL,
 'greggs', ARRAY['greggs pizza slice', 'pizza slice greggs', 'greggs cheese pizza'],
 'bakery', 'Greggs', 1, '235 cal/100g. Per slice (125g): 294 cal. Cheese and tomato pizza slice.', TRUE,
 480, 18, 4.5, 0.0, 120, 80, 1.0, 25, 1.0, 2, 14, 0.8, 100, 8.0, 0.01),

-- Greggs Steak & Cheese Roll: 130g per roll, 390 cal. Per 100g: 300 cal, 10.0P, 22.0C, 19.2F.
('greggs_steak_cheese_roll', 'Greggs Steak & Cheese Roll', 300, 10.0, 22.0, 19.2,
 1.0, 0.5, 130, NULL,
 'greggs', ARRAY['greggs steak and cheese roll', 'steak cheese roll greggs'],
 'bakery', 'Greggs', 1, '300 cal/100g. Per roll (130g): 390 cal. Steak and cheese in pastry roll.', TRUE,
 530, 35, 9.0, 0.1, 140, 60, 1.5, 10, 0.0, 2, 14, 1.3, 100, 9.0, 0.02),

-- Greggs Cornish Pasty: 165g per pasty, 459 cal. Per 100g: 278 cal, 6.7P, 24.8C, 16.7F.
('greggs_cornish_pasty', 'Greggs Cornish Pasty', 278, 6.7, 24.8, 16.7,
 1.5, 0.8, 165, NULL,
 'greggs', ARRAY['greggs cornish pasty', 'cornish pasty greggs'],
 'bakery', 'Greggs', 1, '278 cal/100g. Per pasty (165g): 459 cal. Beef, potato, swede, onion in pastry.', TRUE,
 450, 22, 7.5, 0.1, 160, 20, 1.5, 3, 2.0, 0, 14, 1.2, 85, 7.0, 0.01),

-- Greggs Belgian Bun: 110g per bun, 370 cal. Per 100g: 336 cal, 5.5P, 50.0C, 12.7F.
('greggs_belgian_bun', 'Greggs Belgian Bun', 336, 5.5, 50.0, 12.7,
 1.0, 25.0, 110, NULL,
 'greggs', ARRAY['greggs belgian bun', 'belgian bun greggs'],
 'bakery', 'Greggs', 1, '336 cal/100g. Per bun (110g): 370 cal. Iced bun with lemon filling and cherry.', TRUE,
 180, 20, 5.0, 0.1, 70, 30, 0.8, 10, 1.0, 0, 8, 0.4, 45, 5.0, 0.01),

-- Greggs Caramel Custard Donut: 85g per donut, 298 cal. Per 100g: 351 cal, 4.7P, 43.5C, 17.6F.
('greggs_caramel_custard_donut', 'Greggs Caramel Custard Donut', 351, 4.7, 43.5, 17.6,
 0.8, 20.0, 85, NULL,
 'greggs', ARRAY['greggs caramel custard donut', 'caramel custard donut greggs', 'greggs caramel donut'],
 'bakery', 'Greggs', 1, '351 cal/100g. Per donut (85g): 298 cal. Filled with caramel custard.', TRUE,
 200, 20, 7.5, 0.1, 65, 35, 0.6, 15, 0.0, 2, 8, 0.3, 50, 5.0, 0.01),

-- Greggs Egg Mayo Sandwich: 155g per sandwich, 310 cal. Per 100g: 200 cal, 7.7P, 20.0C, 10.3F.
('greggs_egg_mayo_sandwich', 'Greggs Egg Mayo Sandwich', 200, 7.7, 20.0, 10.3,
 1.2, 2.0, 155, NULL,
 'greggs', ARRAY['greggs egg mayo sandwich', 'egg mayo sandwich greggs', 'greggs egg sandwich'],
 'bakery', 'Greggs', 1, '200 cal/100g. Per sandwich (155g): 310 cal. Egg mayonnaise on white bread.', TRUE,
 380, 120, 2.0, 0.0, 90, 30, 1.0, 40, 0.0, 5, 10, 0.6, 80, 10.0, 0.01),

-- ==========================================
-- WETHERSPOONS (UK Pub Chain)
-- ==========================================

-- Wetherspoons Fish & Chips: 550g per serving, 1240 cal. Per 100g: 225 cal, 10.9P, 22.0C, 10.9F.
('wetherspoons_fish_chips', 'Wetherspoons Fish & Chips', 225, 10.9, 22.0, 10.9,
 1.8, 0.5, 550, NULL,
 'wetherspoons', ARRAY['wetherspoons fish and chips', 'spoons fish and chips', 'wetherspoons cod and chips'],
 'pub', 'Wetherspoons', 1, '225 cal/100g. Per serving (550g): 1240 cal. Battered cod with chips and peas.', TRUE,
 350, 40, 2.0, 0.1, 300, 25, 1.0, 5, 3.0, 5, 25, 0.5, 150, 20.0, 0.08),

-- Wetherspoons 8oz Sirloin Steak: 450g per plate, 900 cal. Per 100g: 200 cal, 18.0P, 10.0C, 9.5F.
('wetherspoons_sirloin_steak', 'Wetherspoons 8oz Sirloin Steak', 200, 18.0, 10.0, 9.5,
 1.5, 0.5, 450, NULL,
 'wetherspoons', ARRAY['wetherspoons sirloin steak', 'spoons steak', 'wetherspoons 8oz steak'],
 'pub', 'Wetherspoons', 1, '200 cal/100g. Per plate (450g): 900 cal. 8oz sirloin with chips and peas.', TRUE,
 280, 65, 4.0, 0.2, 380, 15, 2.5, 0, 2.0, 5, 25, 4.5, 200, 25.0, 0.03),

-- Wetherspoons Classic Burger: 350g per serving, 840 cal. Per 100g: 240 cal, 12.9P, 17.1C, 14.3F.
('wetherspoons_classic_burger', 'Wetherspoons Classic Burger', 240, 12.9, 17.1, 14.3,
 1.5, 3.0, 350, NULL,
 'wetherspoons', ARRAY['wetherspoons classic burger', 'spoons burger', 'wetherspoons beef burger'],
 'pub', 'Wetherspoons', 1, '240 cal/100g. Per serving (350g): 840 cal. Beef burger with lettuce, tomato in bun.', TRUE,
 450, 55, 6.0, 0.3, 280, 40, 2.5, 5, 2.0, 0, 22, 3.5, 170, 18.0, 0.02),

-- Wetherspoons Chicken Burger: 330g per serving, 760 cal. Per 100g: 230 cal, 14.5P, 18.2C, 11.5F.
('wetherspoons_chicken_burger', 'Wetherspoons Chicken Burger', 230, 14.5, 18.2, 11.5,
 1.5, 3.0, 330, NULL,
 'wetherspoons', ARRAY['wetherspoons chicken burger', 'spoons chicken burger'],
 'pub', 'Wetherspoons', 1, '230 cal/100g. Per serving (330g): 760 cal. Breaded chicken fillet in bun.', TRUE,
 480, 45, 2.5, 0.1, 250, 35, 1.2, 5, 2.0, 2, 22, 1.0, 160, 16.0, 0.02),

-- Wetherspoons Full Breakfast: 500g per plate, 1100 cal. Per 100g: 220 cal, 10.0P, 14.0C, 14.0F.
('wetherspoons_full_breakfast', 'Wetherspoons Full Breakfast', 220, 10.0, 14.0, 14.0,
 1.5, 1.0, 500, NULL,
 'wetherspoons', ARRAY['wetherspoons full breakfast', 'spoons full english', 'wetherspoons large breakfast'],
 'pub', 'Wetherspoons', 1, '220 cal/100g. Per plate (500g): 1100 cal. Eggs, bacon, sausage, beans, toast, tomato.', TRUE,
 550, 180, 5.0, 0.2, 300, 40, 2.0, 50, 5.0, 10, 20, 2.0, 180, 15.0, 0.03),

-- Wetherspoons Small Breakfast: 320g per plate, 640 cal. Per 100g: 200 cal, 10.0P, 13.0C, 12.5F.
('wetherspoons_small_breakfast', 'Wetherspoons Small Breakfast', 200, 10.0, 13.0, 12.5,
 1.5, 1.0, 320, NULL,
 'wetherspoons', ARRAY['wetherspoons small breakfast', 'spoons small breakfast'],
 'pub', 'Wetherspoons', 1, '200 cal/100g. Per plate (320g): 640 cal. Egg, bacon, sausage, beans, toast.', TRUE,
 520, 150, 4.5, 0.2, 280, 35, 1.8, 45, 4.0, 8, 18, 1.8, 160, 13.0, 0.02),

-- Wetherspoons Scampi & Chips: 480g per serving, 960 cal. Per 100g: 200 cal, 7.5P, 22.9C, 8.8F.
('wetherspoons_scampi_chips', 'Wetherspoons Scampi & Chips', 200, 7.5, 22.9, 8.8,
 1.5, 0.5, 480, NULL,
 'wetherspoons', ARRAY['wetherspoons scampi and chips', 'spoons scampi', 'wetherspoons wholetail scampi'],
 'pub', 'Wetherspoons', 1, '200 cal/100g. Per serving (480g): 960 cal. Breaded scampi with chips and peas.', TRUE,
 400, 60, 1.5, 0.1, 250, 25, 1.0, 5, 2.0, 3, 20, 0.6, 120, 15.0, 0.05),

-- Wetherspoons Steak & Ale Pie: 450g per serving, 990 cal. Per 100g: 220 cal, 8.0P, 20.0C, 11.8F.
('wetherspoons_steak_ale_pie', 'Wetherspoons Steak & Ale Pie', 220, 8.0, 20.0, 11.8,
 1.2, 1.0, 450, NULL,
 'wetherspoons', ARRAY['wetherspoons steak and ale pie', 'spoons steak pie', 'wetherspoons pie'],
 'pub', 'Wetherspoons', 1, '220 cal/100g. Per serving (450g): 990 cal. Steak & ale pie with chips and peas.', TRUE,
 380, 30, 5.0, 0.1, 220, 20, 2.0, 3, 1.0, 0, 16, 2.5, 120, 10.0, 0.02),

-- Wetherspoons Chicken Caesar Salad: 350g per serving, 560 cal. Per 100g: 160 cal, 12.0P, 5.7C, 10.3F.
('wetherspoons_chicken_caesar_salad', 'Wetherspoons Chicken Caesar Salad', 160, 12.0, 5.7, 10.3,
 1.5, 1.5, 350, NULL,
 'wetherspoons', ARRAY['wetherspoons chicken caesar salad', 'spoons caesar salad'],
 'pub', 'Wetherspoons', 1, '160 cal/100g. Per serving (350g): 560 cal. Grilled chicken, parmesan, croutons.', TRUE,
 420, 45, 3.0, 0.0, 250, 80, 1.0, 40, 5.0, 2, 18, 1.0, 150, 14.0, 0.02),

-- Wetherspoons Lasagne: 400g per serving, 720 cal. Per 100g: 180 cal, 8.5P, 14.0C, 10.0F.
('wetherspoons_lasagne', 'Wetherspoons Lasagne', 180, 8.5, 14.0, 10.0,
 1.0, 2.5, 400, NULL,
 'wetherspoons', ARRAY['wetherspoons lasagne', 'spoons lasagne', 'wetherspoons lasagna'],
 'pub', 'Wetherspoons', 1, '180 cal/100g. Per serving (400g): 720 cal. Beef lasagne with garlic bread and salad.', TRUE,
 350, 35, 4.5, 0.1, 250, 70, 1.5, 30, 2.0, 2, 18, 2.0, 140, 12.0, 0.02),

-- Wetherspoons Chicken Tikka Masala: 450g per serving, 720 cal. Per 100g: 160 cal, 10.0P, 16.0C, 6.2F.
('wetherspoons_chicken_tikka_masala', 'Wetherspoons Chicken Tikka Masala', 160, 10.0, 16.0, 6.2,
 1.0, 2.0, 450, NULL,
 'wetherspoons', ARRAY['wetherspoons chicken tikka masala', 'spoons curry', 'wetherspoons tikka masala'],
 'pub', 'Wetherspoons', 1, '160 cal/100g. Per serving (450g): 720 cal. Chicken tikka masala with rice and naan.', TRUE,
 400, 35, 2.5, 0.0, 280, 40, 1.5, 20, 2.0, 0, 22, 1.2, 150, 12.0, 0.02),

-- Wetherspoons BBQ Chicken: 380g per serving, 760 cal. Per 100g: 200 cal, 15.8P, 12.6C, 9.5F.
('wetherspoons_bbq_chicken', 'Wetherspoons BBQ Chicken', 200, 15.8, 12.6, 9.5,
 1.0, 5.0, 380, NULL,
 'wetherspoons', ARRAY['wetherspoons bbq chicken', 'spoons bbq chicken'],
 'pub', 'Wetherspoons', 1, '200 cal/100g. Per serving (380g): 760 cal. BBQ glazed chicken with chips.', TRUE,
 420, 55, 2.5, 0.0, 300, 20, 1.2, 8, 3.0, 2, 24, 1.5, 170, 18.0, 0.02),

-- Wetherspoons Mac & Cheese: 380g per serving, 720 cal. Per 100g: 189 cal, 7.4P, 16.8C, 10.5F.
('wetherspoons_mac_cheese', 'Wetherspoons Mac & Cheese', 189, 7.4, 16.8, 10.5,
 0.8, 2.0, 380, NULL,
 'wetherspoons', ARRAY['wetherspoons mac and cheese', 'spoons mac and cheese', 'wetherspoons macaroni cheese'],
 'pub', 'Wetherspoons', 1, '189 cal/100g. Per serving (380g): 720 cal. Macaroni in cheese sauce.', TRUE,
 380, 25, 5.5, 0.1, 120, 120, 0.8, 35, 0.0, 2, 14, 1.0, 140, 8.0, 0.01),

-- Wetherspoons Fish Finger Sandwich: 300g per serving, 660 cal. Per 100g: 220 cal, 9.3P, 22.0C, 10.7F.
('wetherspoons_fish_finger_sandwich', 'Wetherspoons Fish Finger Sandwich', 220, 9.3, 22.0, 10.7,
 1.5, 2.0, 300, NULL,
 'wetherspoons', ARRAY['wetherspoons fish finger sandwich', 'spoons fish finger sandwich'],
 'pub', 'Wetherspoons', 1, '220 cal/100g. Per serving (300g): 660 cal. Fish fingers in bread with tartare sauce.', TRUE,
 450, 30, 2.0, 0.1, 200, 25, 1.0, 5, 1.0, 5, 18, 0.5, 120, 15.0, 0.06),

-- Wetherspoons Chocolate Fudge Cake: 140g per slice, 490 cal. Per 100g: 350 cal, 4.3P, 45.0C, 17.1F.
('wetherspoons_chocolate_fudge_cake', 'Wetherspoons Chocolate Fudge Cake', 350, 4.3, 45.0, 17.1,
 2.0, 32.0, 140, NULL,
 'wetherspoons', ARRAY['wetherspoons chocolate fudge cake', 'spoons fudge cake', 'wetherspoons chocolate cake'],
 'pub', 'Wetherspoons', 1, '350 cal/100g. Per slice (140g): 490 cal. Chocolate fudge cake with cream.', TRUE,
 200, 25, 8.5, 0.1, 180, 30, 2.5, 15, 0.0, 2, 35, 1.0, 80, 4.0, 0.01),

-- ==========================================
-- PIZZA EXPRESS (UK Pizza Chain)
-- ==========================================

-- Pizza Express American: 380g per pizza, 802 cal. Per 100g: 211 cal, 10.0P, 25.5C, 7.4F.
('pizza_express_american', 'Pizza Express American Pizza', 211, 10.0, 25.5, 7.4,
 1.5, 3.0, 380, NULL,
 'pizza_express', ARRAY['pizza express american', 'pizza express american hot', 'pizzaexpress american'],
 'pizza', 'Pizza Express', 1, '211 cal/100g. Per pizza (380g): 802 cal. Pepperoni, mozzarella, tomato.', TRUE,
 480, 30, 3.5, 0.1, 200, 120, 1.5, 30, 3.0, 2, 18, 1.5, 150, 12.0, 0.02),

-- Pizza Express Margherita: 350g per pizza, 674 cal. Per 100g: 193 cal, 8.6P, 25.3C, 6.0F.
('pizza_express_margherita', 'Pizza Express Margherita', 193, 8.6, 25.3, 6.0,
 1.5, 3.0, 350, NULL,
 'pizza_express', ARRAY['pizza express margherita', 'pizzaexpress margherita', 'pizza express classic margherita'],
 'pizza', 'Pizza Express', 1, '193 cal/100g. Per pizza (350g): 674 cal. Mozzarella and tomato sauce.', TRUE,
 400, 20, 3.0, 0.0, 180, 130, 1.2, 25, 3.0, 2, 16, 1.2, 140, 10.0, 0.01),

-- Pizza Express Padana: 390g per pizza, 883 cal. Per 100g: 226 cal, 9.5P, 24.0C, 10.3F.
('pizza_express_padana', 'Pizza Express Padana', 226, 9.5, 24.0, 10.3,
 1.5, 3.0, 390, NULL,
 'pizza_express', ARRAY['pizza express padana', 'pizzaexpress padana', 'pizza express goats cheese pizza'],
 'pizza', 'Pizza Express', 1, '226 cal/100g. Per pizza (390g): 883 cal. Goat''s cheese, caramelised onion, spinach.', TRUE,
 420, 25, 5.0, 0.0, 200, 100, 1.5, 80, 2.0, 2, 18, 1.0, 130, 10.0, 0.01),

-- Pizza Express Sloppy Giuseppe: 400g per pizza, 768 cal. Per 100g: 192 cal, 9.2P, 23.0C, 6.8F.
('pizza_express_sloppy_giuseppe', 'Pizza Express Sloppy Giuseppe', 192, 9.2, 23.0, 6.8,
 1.8, 3.5, 400, NULL,
 'pizza_express', ARRAY['pizza express sloppy giuseppe', 'pizzaexpress sloppy giuseppe'],
 'pizza', 'Pizza Express', 1, '192 cal/100g. Per pizza (400g): 768 cal. Spicy beef, green peppers, onion, mozzarella.', TRUE,
 440, 25, 3.0, 0.1, 220, 100, 1.8, 20, 5.0, 0, 18, 2.0, 140, 10.0, 0.02),

-- Pizza Express Fiorentina: 370g per pizza, 700 cal. Per 100g: 189 cal, 9.2P, 23.0C, 6.8F.
('pizza_express_fiorentina', 'Pizza Express Fiorentina', 189, 9.2, 23.0, 6.8,
 2.0, 2.5, 370, NULL,
 'pizza_express', ARRAY['pizza express fiorentina', 'pizzaexpress fiorentina', 'pizza express spinach egg pizza'],
 'pizza', 'Pizza Express', 1, '189 cal/100g. Per pizza (370g): 700 cal. Spinach, egg, mozzarella, olives.', TRUE,
 380, 100, 3.0, 0.0, 250, 120, 2.0, 120, 4.0, 5, 25, 1.0, 150, 12.0, 0.02),

-- Pizza Express Leggera Margherita: 290g per pizza, 460 cal. Per 100g: 159 cal, 7.6P, 22.0C, 4.1F.
('pizza_express_leggera', 'Pizza Express Leggera Margherita', 159, 7.6, 22.0, 4.1,
 2.0, 3.0, 290, NULL,
 'pizza_express', ARRAY['pizza express leggera', 'pizzaexpress leggera', 'pizza express light pizza'],
 'pizza', 'Pizza Express', 1, '159 cal/100g. Per pizza (290g): 460 cal. Lighter pizza with hole filled with salad.', TRUE,
 340, 15, 2.0, 0.0, 180, 100, 1.2, 30, 4.0, 2, 16, 1.0, 120, 8.0, 0.01),

-- Pizza Express Dough Balls: 180g per portion (8 balls), 430 cal. Per 100g: 239 cal, 7.2P, 38.9C, 5.6F.
('pizza_express_dough_balls', 'Pizza Express Dough Balls', 239, 7.2, 38.9, 5.6,
 1.5, 2.0, 180, 22,
 'pizza_express', ARRAY['pizza express dough balls', 'pizzaexpress dough balls', 'dough balls with garlic butter'],
 'pizza', 'Pizza Express', 1, '239 cal/100g. Per portion (180g, 8 balls): 430 cal. With garlic butter dip.', TRUE,
 380, 5, 2.5, 0.0, 80, 15, 1.5, 5, 0.0, 0, 12, 0.5, 60, 8.0, 0.01),

-- Pizza Express Caesar Salad: 280g per serving, 390 cal. Per 100g: 139 cal, 8.2P, 6.4C, 9.3F.
('pizza_express_caesar_salad', 'Pizza Express Caesar Salad', 139, 8.2, 6.4, 9.3,
 1.5, 1.5, 280, NULL,
 'pizza_express', ARRAY['pizza express caesar salad', 'pizzaexpress caesar salad'],
 'pizza', 'Pizza Express', 1, '139 cal/100g. Per serving (280g): 390 cal. Chicken, romaine, parmesan, croutons.', TRUE,
 400, 40, 2.5, 0.0, 220, 80, 1.0, 45, 5.0, 2, 16, 1.0, 140, 12.0, 0.02),

-- Pizza Express Garlic Bread: 130g per portion, 365 cal. Per 100g: 281 cal, 7.7P, 35.4C, 12.3F.
('pizza_express_garlic_bread', 'Pizza Express Garlic Bread', 281, 7.7, 35.4, 12.3,
 1.5, 1.5, 130, NULL,
 'pizza_express', ARRAY['pizza express garlic bread', 'pizzaexpress garlic bread'],
 'pizza', 'Pizza Express', 1, '281 cal/100g. Per portion (130g): 365 cal. Classic garlic bread.', TRUE,
 420, 5, 4.0, 0.0, 80, 20, 1.2, 10, 0.5, 0, 12, 0.5, 55, 8.0, 0.01),

-- Pizza Express Tiramisu: 140g per serving, 340 cal. Per 100g: 243 cal, 4.3P, 27.1C, 12.9F.
('pizza_express_tiramisu', 'Pizza Express Tiramisu', 243, 4.3, 27.1, 12.9,
 0.3, 18.0, 140, NULL,
 'pizza_express', ARRAY['pizza express tiramisu', 'pizzaexpress tiramisu'],
 'pizza', 'Pizza Express', 1, '243 cal/100g. Per serving (140g): 340 cal. Classic Italian coffee dessert.', TRUE,
 60, 80, 7.5, 0.0, 100, 40, 0.5, 50, 0.0, 5, 8, 0.3, 60, 3.0, 0.01),

-- Pizza Express Chocolate Fudge Cake: 130g per slice, 410 cal. Per 100g: 315 cal, 4.6P, 40.0C, 15.4F.
('pizza_express_chocolate_fudge_cake', 'Pizza Express Chocolate Fudge Cake', 315, 4.6, 40.0, 15.4,
 2.0, 30.0, 130, NULL,
 'pizza_express', ARRAY['pizza express chocolate fudge cake', 'pizzaexpress fudge cake'],
 'pizza', 'Pizza Express', 1, '315 cal/100g. Per slice (130g): 410 cal. Rich chocolate fudge cake.', TRUE,
 180, 25, 8.0, 0.1, 170, 30, 2.5, 12, 0.0, 2, 35, 1.0, 75, 4.0, 0.01),

-- Pizza Express Pollo Pesto: 400g per pizza, 880 cal. Per 100g: 220 cal, 12.0P, 23.0C, 8.5F.
('pizza_express_pollo_pesto', 'Pizza Express Pollo Pesto Pizza', 220, 12.0, 23.0, 8.5,
 1.5, 2.5, 400, NULL,
 'pizza_express', ARRAY['pizza express pollo pesto', 'pizzaexpress pollo pesto', 'pizza express chicken pesto'],
 'pizza', 'Pizza Express', 1, '220 cal/100g. Per pizza (400g): 880 cal. Chicken, pesto, pine nuts, mozzarella.', TRUE,
 430, 30, 3.5, 0.0, 210, 110, 1.5, 25, 2.0, 2, 20, 1.2, 150, 12.0, 0.03),

-- ==========================================
-- SWISS CHALET (Canadian Rotisserie Chain)
-- ==========================================

-- Swiss Chalet Quarter Chicken White: 180g per serving, 290 cal. Per 100g: 161 cal, 26.7P, 0.0C, 5.6F.
('swiss_chalet_quarter_chicken_white', 'Swiss Chalet Quarter Chicken Dinner (White Meat)', 161, 26.7, 0.0, 5.6,
 0.0, 0.0, 180, NULL,
 'swiss_chalet', ARRAY['swiss chalet quarter chicken white', 'swiss chalet white meat', 'swiss chalet quarter chicken breast'],
 'canadian', 'Swiss Chalet', 1, '161 cal/100g. Per quarter (180g): 290 cal. Rotisserie chicken breast with skin.', TRUE,
 380, 85, 1.5, 0.0, 250, 14, 1.0, 6, 0.0, 5, 28, 1.0, 220, 27.0, 0.03),

-- Swiss Chalet Quarter Chicken Dark: 200g per serving, 380 cal. Per 100g: 190 cal, 22.0P, 0.0C, 11.0F.
('swiss_chalet_quarter_chicken_dark', 'Swiss Chalet Quarter Chicken Dinner (Dark Meat)', 190, 22.0, 0.0, 11.0,
 0.0, 0.0, 200, NULL,
 'swiss_chalet', ARRAY['swiss chalet quarter chicken dark', 'swiss chalet dark meat', 'swiss chalet quarter chicken leg'],
 'canadian', 'Swiss Chalet', 1, '190 cal/100g. Per quarter (200g): 380 cal. Rotisserie chicken leg/thigh with skin.', TRUE,
 350, 110, 3.5, 0.1, 230, 12, 1.3, 20, 0.0, 5, 23, 2.4, 180, 22.0, 0.05),

-- Swiss Chalet Half Chicken: 380g per serving, 530 cal. Per 100g: 139 cal, 22.0P, 0.0C, 5.5F.
('swiss_chalet_half_chicken', 'Swiss Chalet Half Chicken', 139, 22.0, 0.0, 5.5,
 0.0, 0.0, 380, NULL,
 'swiss_chalet', ARRAY['swiss chalet half chicken', 'swiss chalet 1/2 chicken'],
 'canadian', 'Swiss Chalet', 1, '139 cal/100g. Per half chicken (380g): 530 cal. Half rotisserie chicken.', TRUE,
 360, 95, 2.0, 0.0, 240, 13, 1.1, 12, 0.0, 5, 26, 1.8, 200, 25.0, 0.04),

-- Swiss Chalet Rotisserie Beef: 220g per serving, 440 cal. Per 100g: 200 cal, 24.0P, 0.5C, 11.0F.
('swiss_chalet_rotisserie_beef', 'Swiss Chalet Rotisserie Beef', 200, 24.0, 0.5, 11.0,
 0.0, 0.0, 220, NULL,
 'swiss_chalet', ARRAY['swiss chalet rotisserie beef', 'swiss chalet beef'],
 'canadian', 'Swiss Chalet', 1, '200 cal/100g. Per serving (220g): 440 cal. Slow-roasted beef.', TRUE,
 300, 75, 4.5, 0.2, 340, 15, 2.5, 0, 0.0, 5, 22, 5.0, 200, 25.0, 0.03),

-- Swiss Chalet Baby Back Ribs: 350g per serving, 770 cal. Per 100g: 220 cal, 18.0P, 5.0C, 14.3F.
('swiss_chalet_baby_back_ribs', 'Swiss Chalet Baby Back Ribs', 220, 18.0, 5.0, 14.3,
 0.0, 4.0, 350, NULL,
 'swiss_chalet', ARRAY['swiss chalet baby back ribs', 'swiss chalet ribs'],
 'canadian', 'Swiss Chalet', 1, '220 cal/100g. Per serving (350g): 770 cal. BBQ glazed baby back ribs.', TRUE,
 450, 80, 5.5, 0.1, 280, 25, 1.5, 5, 2.0, 5, 20, 3.5, 175, 18.0, 0.03),

-- Swiss Chalet Chicken Pot Pie: 350g per serving, 560 cal. Per 100g: 160 cal, 8.0P, 16.0C, 7.1F.
('swiss_chalet_chicken_pot_pie', 'Swiss Chalet Chicken Pot Pie', 160, 8.0, 16.0, 7.1,
 1.0, 1.5, 350, NULL,
 'swiss_chalet', ARRAY['swiss chalet chicken pot pie', 'swiss chalet pot pie'],
 'canadian', 'Swiss Chalet', 1, '160 cal/100g. Per pie (350g): 560 cal. Chicken and vegetables in pastry.', TRUE,
 420, 35, 3.0, 0.1, 180, 25, 1.2, 50, 3.0, 2, 16, 1.0, 120, 12.0, 0.02),

-- Swiss Chalet Chalet Dipping Sauce: 60g per serving, 25 cal. Per 100g: 42 cal, 0.5P, 8.3C, 0.8F.
('swiss_chalet_dipping_sauce', 'Swiss Chalet Chalet Dipping Sauce', 42, 0.5, 8.3, 0.8,
 0.0, 3.0, 60, NULL,
 'swiss_chalet', ARRAY['swiss chalet dipping sauce', 'chalet sauce', 'swiss chalet sauce'],
 'canadian', 'Swiss Chalet', 1, '42 cal/100g. Per serving (60g): 25 cal. Signature dipping sauce for chicken.', TRUE,
 550, 0, 0.1, 0.0, 50, 5, 0.2, 5, 1.0, 0, 3, 0.1, 10, 0.5, 0.00),

-- Swiss Chalet Poutine: 350g per serving, 910 cal. Per 100g: 260 cal, 8.6P, 25.7C, 14.3F.
('swiss_chalet_poutine', 'Swiss Chalet Poutine', 260, 8.6, 25.7, 14.3,
 2.0, 1.0, 350, NULL,
 'swiss_chalet', ARRAY['swiss chalet poutine', 'swiss chalet fries poutine'],
 'canadian', 'Swiss Chalet', 1, '260 cal/100g. Per serving (350g): 910 cal. Fries, cheese curds, gravy.', TRUE,
 550, 30, 6.5, 0.2, 400, 120, 1.0, 10, 5.0, 2, 20, 1.5, 150, 5.0, 0.01),

-- Swiss Chalet Caesar Salad: 200g per serving, 220 cal. Per 100g: 110 cal, 4.5P, 6.0C, 7.5F.
('swiss_chalet_caesar_salad', 'Swiss Chalet Caesar Salad', 110, 4.5, 6.0, 7.5,
 1.5, 1.0, 200, NULL,
 'swiss_chalet', ARRAY['swiss chalet caesar salad'],
 'canadian', 'Swiss Chalet', 1, '110 cal/100g. Per serving (200g): 220 cal. Romaine, croutons, parmesan, dressing.', TRUE,
 350, 15, 2.0, 0.0, 150, 60, 0.8, 40, 5.0, 2, 12, 0.5, 80, 5.0, 0.01),

-- Swiss Chalet Garlic Bread: 100g per serving, 350 cal. Per 100g: 350 cal, 8.0P, 38.0C, 18.0F.
('swiss_chalet_garlic_bread', 'Swiss Chalet Garlic Bread', 350, 8.0, 38.0, 18.0,
 1.5, 2.0, 100, NULL,
 'swiss_chalet', ARRAY['swiss chalet garlic bread', 'swiss chalet garlic toast'],
 'canadian', 'Swiss Chalet', 1, '350 cal/100g. Per serving (100g): 350 cal. Toasted garlic bread.', TRUE,
 450, 5, 5.0, 0.0, 80, 25, 1.5, 10, 0.5, 0, 14, 0.5, 60, 8.0, 0.01),

-- Swiss Chalet Apple Pie: 130g per slice, 300 cal. Per 100g: 231 cal, 2.3P, 32.3C, 10.8F.
('swiss_chalet_apple_pie', 'Swiss Chalet Apple Pie', 231, 2.3, 32.3, 10.8,
 1.5, 15.0, 130, NULL,
 'swiss_chalet', ARRAY['swiss chalet apple pie'],
 'canadian', 'Swiss Chalet', 1, '231 cal/100g. Per slice (130g): 300 cal. Classic apple pie.', TRUE,
 200, 0, 3.5, 0.1, 80, 10, 0.5, 5, 2.0, 0, 6, 0.2, 20, 2.0, 0.01),

-- Swiss Chalet Sweet Potato Fries: 150g per serving, 300 cal. Per 100g: 200 cal, 2.0P, 30.0C, 8.0F.
('swiss_chalet_sweet_potato_fries', 'Swiss Chalet Sweet Potato Fries', 200, 2.0, 30.0, 8.0,
 3.0, 6.0, 150, NULL,
 'swiss_chalet', ARRAY['swiss chalet sweet potato fries'],
 'canadian', 'Swiss Chalet', 1, '200 cal/100g. Per serving (150g): 300 cal. Crispy sweet potato fries.', TRUE,
 280, 0, 1.5, 0.0, 350, 30, 0.6, 500, 5.0, 0, 22, 0.3, 45, 1.0, 0.01),

-- Swiss Chalet Chicken Caesar Wrap: 280g per wrap, 560 cal. Per 100g: 200 cal, 13.0P, 16.0C, 9.6F.
('swiss_chalet_chicken_caesar_wrap', 'Swiss Chalet Chicken Caesar Wrap', 200, 13.0, 16.0, 9.6,
 1.5, 1.5, 280, NULL,
 'swiss_chalet', ARRAY['swiss chalet chicken caesar wrap', 'swiss chalet chicken wrap'],
 'canadian', 'Swiss Chalet', 1, '200 cal/100g. Per wrap (280g): 560 cal. Grilled chicken, romaine, parmesan in wrap.', TRUE,
 480, 40, 3.0, 0.0, 220, 70, 1.2, 35, 4.0, 2, 18, 1.0, 140, 14.0, 0.02),

-- ==========================================
-- HARVEY'S (Canadian Fast Food)
-- ==========================================

-- Harvey's Original Hamburger: 210g per burger, 360 cal. Per 100g: 171 cal, 8.6P, 16.2C, 7.6F.
('harveys_original_hamburger', 'Harvey''s Original Hamburger', 171, 8.6, 16.2, 7.6,
 1.0, 3.0, 210, NULL,
 'harveys', ARRAY['harvey''s original hamburger', 'harveys hamburger', 'harvey''s burger'],
 'fast_food', 'Harvey''s', 1, '171 cal/100g. Per burger (210g): 360 cal. Flame-grilled beef patty with toppings.', TRUE,
 430, 40, 3.2, 0.2, 200, 35, 2.0, 5, 2.0, 0, 18, 2.5, 130, 14.0, 0.02),

-- Harvey's Angus Burger: 230g per burger, 410 cal. Per 100g: 178 cal, 8.3P, 14.3C, 9.6F.
('harveys_angus_burger', 'Harvey''s Angus Burger', 178, 8.3, 14.3, 9.6,
 1.0, 3.0, 230, NULL,
 'harveys', ARRAY['harvey''s angus burger', 'harveys angus', 'harvey''s angus beef burger'],
 'fast_food', 'Harvey''s', 1, '178 cal/100g. Per burger (230g): 410 cal. Angus beef patty flame-grilled.', TRUE,
 480, 50, 4.0, 0.3, 220, 40, 2.5, 5, 2.0, 0, 20, 3.0, 150, 16.0, 0.02),

-- Harvey's Veggie Burger: 200g per burger, 340 cal. Per 100g: 170 cal, 12.0P, 20.0C, 5.0F.
('harveys_veggie_burger', 'Harvey''s Veggie Burger', 170, 12.0, 20.0, 5.0,
 3.0, 3.0, 200, NULL,
 'harveys', ARRAY['harvey''s veggie burger', 'harveys veggie', 'harvey''s plant burger'],
 'fast_food', 'Harvey''s', 1, '170 cal/100g. Per burger (200g): 340 cal. Plant-based patty with toppings.', TRUE,
 450, 0, 1.0, 0.0, 250, 40, 2.5, 5, 3.0, 0, 25, 1.5, 120, 8.0, 0.01),

-- Harvey's Poutine: 350g per serving, 730 cal. Per 100g: 209 cal, 7.1P, 24.3C, 9.4F.
('harveys_poutine', 'Harvey''s Poutine', 209, 7.1, 24.3, 9.4,
 2.0, 0.5, 350, NULL,
 'harveys', ARRAY['harvey''s poutine', 'harveys poutine', 'harvey''s classic poutine'],
 'fast_food', 'Harvey''s', 1, '209 cal/100g. Per serving (350g): 730 cal. Fries, cheese curds, gravy.', TRUE,
 520, 25, 4.0, 0.2, 380, 100, 1.0, 5, 4.0, 2, 18, 1.2, 130, 4.0, 0.01),

-- Harvey's Hot Dog: 140g per hot dog, 290 cal. Per 100g: 207 cal, 8.6P, 17.1C, 11.4F.
('harveys_hot_dog', 'Harvey''s Grilled Hot Dog', 207, 8.6, 17.1, 11.4,
 0.8, 3.0, 140, NULL,
 'harveys', ARRAY['harvey''s hot dog', 'harveys hot dog', 'harvey''s grilled hot dog'],
 'fast_food', 'Harvey''s', 1, '207 cal/100g. Per hot dog (140g): 290 cal. Flame-grilled hot dog in bun.', TRUE,
 600, 35, 4.5, 0.1, 150, 30, 1.0, 0, 1.0, 0, 12, 1.5, 100, 10.0, 0.01),

-- Harvey's Chicken Sandwich: 220g per sandwich, 450 cal. Per 100g: 205 cal, 12.7P, 17.3C, 9.5F.
('harveys_chicken_sandwich', 'Harvey''s Chicken Sandwich', 205, 12.7, 17.3, 9.5,
 1.0, 3.0, 220, NULL,
 'harveys', ARRAY['harvey''s chicken sandwich', 'harveys chicken sandwich'],
 'fast_food', 'Harvey''s', 1, '205 cal/100g. Per sandwich (220g): 450 cal. Breaded chicken fillet in bun.', TRUE,
 520, 40, 2.0, 0.1, 200, 30, 1.0, 5, 2.0, 2, 20, 0.8, 140, 14.0, 0.02),

-- Harvey's Onion Rings: 120g per serving, 360 cal. Per 100g: 300 cal, 4.2P, 35.0C, 16.7F.
('harveys_onion_rings', 'Harvey''s Onion Rings', 300, 4.2, 35.0, 16.7,
 2.0, 4.0, 120, NULL,
 'harveys', ARRAY['harvey''s onion rings', 'harveys onion rings'],
 'fast_food', 'Harvey''s', 1, '300 cal/100g. Per serving (120g): 360 cal. Battered onion rings.', TRUE,
 480, 5, 3.0, 0.2, 100, 20, 1.0, 0, 2.0, 0, 10, 0.3, 40, 3.0, 0.01),

-- Harvey's Frings: 150g per serving, 400 cal. Per 100g: 267 cal, 4.0P, 30.0C, 14.7F.
('harveys_frings', 'Harvey''s Frings', 267, 4.0, 30.0, 14.7,
 2.0, 2.0, 150, NULL,
 'harveys', ARRAY['harvey''s frings', 'harveys frings', 'harvey''s fries and rings'],
 'fast_food', 'Harvey''s', 1, '267 cal/100g. Per serving (150g): 400 cal. Half fries, half onion rings.', TRUE,
 450, 3, 3.0, 0.2, 250, 15, 0.8, 0, 3.0, 0, 14, 0.3, 45, 3.0, 0.01),

-- Harvey's Milkshake: 400g per serving, 520 cal. Per 100g: 130 cal, 3.5P, 20.0C, 4.0F.
('harveys_milkshake', 'Harvey''s Milkshake', 130, 3.5, 20.0, 4.0,
 0.0, 18.0, 400, NULL,
 'harveys', ARRAY['harvey''s milkshake', 'harveys milkshake'],
 'fast_food', 'Harvey''s', 1, '130 cal/100g. Per shake (400g): 520 cal. Thick vanilla milkshake.', TRUE,
 150, 18, 2.5, 0.1, 200, 120, 0.2, 25, 1.0, 20, 15, 0.5, 100, 3.0, 0.01),

-- Harvey's Buffalo Chicken Sandwich: 240g per sandwich, 560 cal. Per 100g: 233 cal, 11.7P, 18.3C, 12.9F.
('harveys_buffalo_chicken_sandwich', 'Harvey''s Buffalo Chicken Sandwich', 233, 11.7, 18.3, 12.9,
 1.0, 3.5, 240, NULL,
 'harveys', ARRAY['harvey''s buffalo chicken sandwich', 'harveys buffalo chicken'],
 'fast_food', 'Harvey''s', 1, '233 cal/100g. Per sandwich (240g): 560 cal. Spicy buffalo chicken fillet.', TRUE,
 620, 45, 3.0, 0.1, 200, 30, 1.2, 15, 2.0, 2, 20, 0.9, 140, 14.0, 0.02),

-- ==========================================
-- A&W CANADA (Canadian Fast Food)
-- ==========================================

-- A&W Mama Burger: 190g per burger, 400 cal. Per 100g: 211 cal, 10.0P, 16.8C, 10.5F.
('aw_canada_mama_burger', 'A&W Canada Mama Burger', 211, 10.0, 16.8, 10.5,
 1.0, 4.0, 190, NULL,
 'aw_canada', ARRAY['a&w mama burger', 'aw mama burger', 'a&w canada mama burger'],
 'fast_food', 'A&W Canada', 1, '211 cal/100g. Per burger (190g): 400 cal. Single beef patty, lettuce, tomato, Teen sauce.', TRUE,
 500, 45, 4.5, 0.3, 200, 40, 2.0, 5, 2.0, 0, 18, 2.5, 130, 14.0, 0.02),

-- A&W Papa Burger: 270g per burger, 580 cal. Per 100g: 215 cal, 12.2P, 14.1C, 12.2F.
('aw_canada_papa_burger', 'A&W Canada Papa Burger', 215, 12.2, 14.1, 12.2,
 1.0, 4.0, 270, NULL,
 'aw_canada', ARRAY['a&w papa burger', 'aw papa burger', 'a&w canada papa burger'],
 'fast_food', 'A&W Canada', 1, '215 cal/100g. Per burger (270g): 580 cal. Double beef patties, lettuce, tomato.', TRUE,
 580, 70, 5.5, 0.4, 250, 45, 2.8, 5, 2.0, 0, 22, 4.0, 170, 18.0, 0.02),

-- A&W Teen Burger: 230g per burger, 490 cal. Per 100g: 213 cal, 10.9P, 15.2C, 11.3F.
('aw_canada_teen_burger', 'A&W Canada Teen Burger', 213, 10.9, 15.2, 11.3,
 1.0, 4.0, 230, NULL,
 'aw_canada', ARRAY['a&w teen burger', 'aw teen burger', 'a&w canada teen burger'],
 'fast_food', 'A&W Canada', 1, '213 cal/100g. Per burger (230g): 490 cal. Beef patty, bacon, cheese, lettuce, tomato.', TRUE,
 550, 55, 5.0, 0.3, 220, 80, 2.2, 15, 2.0, 2, 20, 3.0, 150, 16.0, 0.02),

-- A&W Buddy Burger: 130g per burger, 280 cal. Per 100g: 215 cal, 11.5P, 16.9C, 10.8F.
('aw_canada_buddy_burger', 'A&W Canada Buddy Burger', 215, 11.5, 16.9, 10.8,
 0.8, 4.0, 130, NULL,
 'aw_canada', ARRAY['a&w buddy burger', 'aw buddy burger', 'a&w canada buddy burger'],
 'fast_food', 'A&W Canada', 1, '215 cal/100g. Per burger (130g): 280 cal. Simple single patty burger.', TRUE,
 450, 35, 4.5, 0.2, 170, 35, 1.8, 3, 1.0, 0, 16, 2.2, 110, 12.0, 0.02),

-- A&W Mozza Burger: 250g per burger, 560 cal. Per 100g: 224 cal, 11.2P, 14.4C, 13.6F.
('aw_canada_mozza_burger', 'A&W Canada Mozza Burger', 224, 11.2, 14.4, 13.6,
 1.0, 3.5, 250, NULL,
 'aw_canada', ARRAY['a&w mozza burger', 'aw mozza burger', 'a&w canada mozza burger'],
 'fast_food', 'A&W Canada', 1, '224 cal/100g. Per burger (250g): 560 cal. Beef patty with mozzarella, mushrooms.', TRUE,
 520, 55, 6.0, 0.3, 230, 100, 2.0, 8, 2.0, 2, 20, 3.5, 160, 16.0, 0.02),

-- A&W Onion Rings: 130g per serving, 350 cal. Per 100g: 269 cal, 4.6P, 33.1C, 13.1F.
('aw_canada_onion_rings', 'A&W Canada Onion Rings', 269, 4.6, 33.1, 13.1,
 2.0, 4.0, 130, NULL,
 'aw_canada', ARRAY['a&w onion rings', 'aw onion rings', 'a&w canada onion rings'],
 'fast_food', 'A&W Canada', 1, '269 cal/100g. Per serving (130g): 350 cal. Battered onion rings.', TRUE,
 500, 5, 2.5, 0.2, 100, 20, 1.0, 0, 2.0, 0, 10, 0.3, 40, 3.0, 0.01),

-- A&W Sweet Potato Fries: 140g per serving, 310 cal. Per 100g: 221 cal, 2.1P, 30.7C, 10.0F.
('aw_canada_sweet_potato_fries', 'A&W Canada Sweet Potato Fries', 221, 2.1, 30.7, 10.0,
 3.0, 5.0, 140, NULL,
 'aw_canada', ARRAY['a&w sweet potato fries', 'aw sweet potato fries'],
 'fast_food', 'A&W Canada', 1, '221 cal/100g. Per serving (140g): 310 cal. Crispy sweet potato fries.', TRUE,
 300, 0, 2.0, 0.0, 330, 25, 0.5, 450, 4.0, 0, 20, 0.3, 40, 1.0, 0.01),

-- A&W Root Beer Float: 450g per serving, 350 cal. Per 100g: 78 cal, 1.3P, 15.6C, 1.3F.
('aw_canada_root_beer_float', 'A&W Canada Root Beer Float', 78, 1.3, 15.6, 1.3,
 0.0, 14.0, 450, NULL,
 'aw_canada', ARRAY['a&w root beer float', 'aw root beer float', 'a&w canada root beer float'],
 'fast_food', 'A&W Canada', 1, '78 cal/100g. Per float (450g): 350 cal. A&W Root Beer with vanilla ice cream.', TRUE,
 50, 8, 0.8, 0.0, 80, 50, 0.1, 12, 0.5, 10, 8, 0.2, 40, 1.0, 0.01),

-- A&W Chubby Chicken Burger: 220g per burger, 480 cal. Per 100g: 218 cal, 11.4P, 18.2C, 11.4F.
('aw_canada_chubby_chicken_burger', 'A&W Canada Chubby Chicken Burger', 218, 11.4, 18.2, 11.4,
 1.0, 3.5, 220, NULL,
 'aw_canada', ARRAY['a&w chubby chicken burger', 'aw chubby chicken', 'a&w canada chubby chicken'],
 'fast_food', 'A&W Canada', 1, '218 cal/100g. Per burger (220g): 480 cal. Breaded chicken fillet in bun.', TRUE,
 550, 40, 2.5, 0.1, 200, 30, 1.2, 5, 2.0, 2, 20, 0.8, 140, 14.0, 0.02),

-- A&W Breakfast Wrap: 200g per wrap, 420 cal. Per 100g: 210 cal, 10.0P, 16.0C, 11.5F.
('aw_canada_breakfast_wrap', 'A&W Canada Breakfast Wrap', 210, 10.0, 16.0, 11.5,
 1.0, 2.0, 200, NULL,
 'aw_canada', ARRAY['a&w breakfast wrap', 'aw breakfast wrap', 'a&w canada breakfast wrap'],
 'fast_food', 'A&W Canada', 1, '210 cal/100g. Per wrap (200g): 420 cal. Egg, bacon, cheese in flour tortilla.', TRUE,
 550, 150, 4.5, 0.1, 180, 80, 1.5, 40, 0.0, 8, 16, 1.5, 140, 14.0, 0.02),

-- ==========================================
-- COCO ICHIBANYA (Japanese Curry Chain)
-- ==========================================

-- CoCo Pork Cutlet Curry: 500g per serving, 755 cal. Per 100g: 151 cal, 5.6P, 17.2C, 6.4F.
('coco_ichibanya_pork_cutlet_curry', 'CoCo Ichibanya Pork Cutlet Curry', 151, 5.6, 17.2, 6.4,
 1.5, 2.0, 500, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya pork cutlet curry', 'coco curry pork katsu', 'coco ichiban pork cutlet'],
 'japanese', 'CoCo Ichibanya', 1, '151 cal/100g. Per serving (500g): 755 cal. Pork tonkatsu on Japanese curry with rice.', TRUE,
 520, 30, 2.0, 0.1, 250, 25, 1.5, 10, 1.0, 2, 20, 1.5, 120, 10.0, 0.02),

-- CoCo Chicken Cutlet Curry: 490g per serving, 730 cal. Per 100g: 149 cal, 6.5P, 17.0C, 5.7F.
('coco_ichibanya_chicken_cutlet_curry', 'CoCo Ichibanya Chicken Cutlet Curry', 149, 6.5, 17.0, 5.7,
 1.5, 2.0, 490, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya chicken cutlet curry', 'coco curry chicken katsu', 'coco ichiban chicken cutlet'],
 'japanese', 'CoCo Ichibanya', 1, '149 cal/100g. Per serving (490g): 730 cal. Chicken katsu on Japanese curry with rice.', TRUE,
 500, 25, 1.5, 0.1, 240, 20, 1.2, 8, 1.0, 2, 20, 1.0, 130, 12.0, 0.02),

-- CoCo Vegetable Curry: 450g per serving, 580 cal. Per 100g: 129 cal, 3.0P, 20.0C, 4.0F.
('coco_ichibanya_vegetable_curry', 'CoCo Ichibanya Vegetable Curry', 129, 3.0, 20.0, 4.0,
 2.5, 3.0, 450, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya vegetable curry', 'coco curry vegetable', 'coco ichiban veggie curry'],
 'japanese', 'CoCo Ichibanya', 1, '129 cal/100g. Per serving (450g): 580 cal. Mixed vegetables in curry with rice.', TRUE,
 420, 0, 1.0, 0.0, 300, 30, 1.5, 80, 8.0, 0, 25, 0.5, 80, 5.0, 0.01),

-- CoCo Shrimp Curry: 470g per serving, 640 cal. Per 100g: 136 cal, 5.5P, 17.4C, 4.7F.
('coco_ichibanya_shrimp_curry', 'CoCo Ichibanya Shrimp Curry', 136, 5.5, 17.4, 4.7,
 1.5, 2.0, 470, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya shrimp curry', 'coco curry shrimp', 'coco ichiban ebi curry'],
 'japanese', 'CoCo Ichibanya', 1, '136 cal/100g. Per serving (470g): 640 cal. Fried shrimp on Japanese curry with rice.', TRUE,
 480, 60, 1.2, 0.0, 220, 30, 1.0, 10, 1.0, 5, 22, 0.8, 140, 20.0, 0.05),

-- CoCo Beef Curry: 460g per serving, 680 cal. Per 100g: 148 cal, 5.2P, 17.0C, 6.1F.
('coco_ichibanya_beef_curry', 'CoCo Ichibanya Beef Curry', 148, 5.2, 17.0, 6.1,
 1.5, 2.5, 460, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya beef curry', 'coco curry beef', 'coco ichiban beef curry'],
 'japanese', 'CoCo Ichibanya', 1, '148 cal/100g. Per serving (460g): 680 cal. Sliced beef in Japanese curry with rice.', TRUE,
 500, 35, 2.5, 0.1, 260, 15, 2.0, 3, 0.0, 3, 18, 3.0, 130, 12.0, 0.02),

-- CoCo Cheese Curry: 480g per serving, 720 cal. Per 100g: 150 cal, 5.0P, 16.0C, 7.1F.
('coco_ichibanya_cheese_curry', 'CoCo Ichibanya Cheese Curry', 150, 5.0, 16.0, 7.1,
 1.0, 2.0, 480, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya cheese curry', 'coco curry cheese', 'coco ichiban cheese curry'],
 'japanese', 'CoCo Ichibanya', 1, '150 cal/100g. Per serving (480g): 720 cal. Japanese curry with melted cheese and rice.', TRUE,
 480, 20, 4.0, 0.1, 200, 100, 1.0, 30, 0.0, 2, 16, 1.2, 120, 8.0, 0.01),

-- CoCo Omelette Curry: 500g per serving, 750 cal. Per 100g: 150 cal, 5.6P, 16.0C, 6.8F.
('coco_ichibanya_omelette_curry', 'CoCo Ichibanya Omelette Curry', 150, 5.6, 16.0, 6.8,
 1.0, 2.0, 500, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya omelette curry', 'coco curry omelette', 'coco ichiban egg curry'],
 'japanese', 'CoCo Ichibanya', 1, '150 cal/100g. Per serving (500g): 750 cal. Japanese curry with omelette on rice.', TRUE,
 490, 120, 2.5, 0.1, 220, 35, 1.2, 50, 0.0, 8, 18, 1.0, 130, 14.0, 0.02),

-- CoCo Sausage Curry: 480g per serving, 700 cal. Per 100g: 146 cal, 5.0P, 16.5C, 6.3F.
('coco_ichibanya_sausage_curry', 'CoCo Ichibanya Sausage Curry', 146, 5.0, 16.5, 6.3,
 1.0, 2.0, 480, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya sausage curry', 'coco curry sausage', 'coco ichiban sausage curry'],
 'japanese', 'CoCo Ichibanya', 1, '146 cal/100g. Per serving (480g): 700 cal. Sliced sausages in Japanese curry with rice.', TRUE,
 520, 30, 2.5, 0.1, 200, 15, 1.0, 5, 0.5, 2, 14, 1.2, 100, 10.0, 0.01),

-- CoCo Spinach Curry: 450g per serving, 560 cal. Per 100g: 124 cal, 3.3P, 18.0C, 4.2F.
('coco_ichibanya_spinach_curry', 'CoCo Ichibanya Spinach Curry', 124, 3.3, 18.0, 4.2,
 2.0, 2.5, 450, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya spinach curry', 'coco curry spinach', 'coco ichiban spinach curry'],
 'japanese', 'CoCo Ichibanya', 1, '124 cal/100g. Per serving (450g): 560 cal. Japanese curry with spinach and rice.', TRUE,
 430, 0, 1.0, 0.0, 350, 55, 2.5, 300, 10.0, 0, 40, 0.6, 85, 5.0, 0.01),

-- CoCo Naan Curry Set: 520g per set, 780 cal. Per 100g: 150 cal, 4.8P, 20.0C, 5.4F.
('coco_ichibanya_naan_curry_set', 'CoCo Ichibanya Naan Curry Set', 150, 4.8, 20.0, 5.4,
 1.5, 3.0, 520, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya naan curry set', 'coco curry naan', 'coco ichiban naan set'],
 'japanese', 'CoCo Ichibanya', 1, '150 cal/100g. Per set (520g): 780 cal. Japanese curry served with naan bread.', TRUE,
 450, 10, 2.0, 0.0, 200, 30, 1.5, 10, 1.0, 0, 18, 0.8, 90, 8.0, 0.01),

-- CoCo Fried Chicken Curry: 490g per serving, 740 cal. Per 100g: 151 cal, 6.1P, 17.0C, 6.1F.
('coco_ichibanya_fried_chicken_curry', 'CoCo Ichibanya Fried Chicken Curry', 151, 6.1, 17.0, 6.1,
 1.5, 2.0, 490, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya fried chicken curry', 'coco curry karaage', 'coco ichiban fried chicken'],
 'japanese', 'CoCo Ichibanya', 1, '151 cal/100g. Per serving (490g): 740 cal. Karaage fried chicken on curry with rice.', TRUE,
 500, 35, 1.5, 0.1, 230, 20, 1.2, 8, 0.5, 2, 20, 1.0, 130, 12.0, 0.02),

-- CoCo Hamburg Curry: 500g per serving, 760 cal. Per 100g: 152 cal, 6.0P, 16.5C, 6.6F.
('coco_ichibanya_hamburg_curry', 'CoCo Ichibanya Hamburg Curry', 152, 6.0, 16.5, 6.6,
 1.0, 2.5, 500, NULL,
 'coco_ichibanya', ARRAY['coco ichibanya hamburg curry', 'coco curry hamburg steak', 'coco ichiban hamburg'],
 'japanese', 'CoCo Ichibanya', 1, '152 cal/100g. Per serving (500g): 760 cal. Japanese hamburg steak on curry with rice.', TRUE,
 490, 40, 2.8, 0.1, 240, 18, 1.8, 5, 0.5, 3, 18, 2.5, 120, 12.0, 0.02),

-- ==========================================
-- ICHIRAN RAMEN (Japanese Ramen Chain)
-- ==========================================

-- Ichiran Tonkotsu Ramen: 550g per bowl, 531 cal. Per 100g: 97 cal, 3.3P, 11.5C, 4.0F.
('ichiran_tonkotsu_ramen', 'Ichiran Tonkotsu Ramen (Original)', 97, 3.3, 11.5, 4.0,
 0.5, 0.5, 550, NULL,
 'ichiran', ARRAY['ichiran tonkotsu ramen', 'ichiran ramen', 'ichiran original ramen'],
 'japanese', 'Ichiran Ramen', 1, '97 cal/100g. Per bowl (550g): 531 cal. Original tonkotsu pork bone broth ramen.', TRUE,
 550, 20, 2.0, 0.0, 150, 15, 1.0, 5, 0.5, 0, 12, 0.8, 80, 8.0, 0.05),

-- Ichiran Kaedama (extra noodles): 130g per serving, 195 cal. Per 100g: 150 cal, 5.0P, 28.5C, 1.5F.
('ichiran_kaedama', 'Ichiran Kaedama (Extra Noodles)', 150, 5.0, 28.5, 1.5,
 1.0, 0.5, 130, NULL,
 'ichiran', ARRAY['ichiran kaedama', 'ichiran extra noodles', 'ichiran noodle refill'],
 'japanese', 'Ichiran Ramen', 1, '150 cal/100g. Per serving (130g): 195 cal. Extra portion of thin noodles.', TRUE,
 150, 0, 0.3, 0.0, 30, 10, 0.8, 0, 0.0, 0, 10, 0.3, 40, 8.0, 0.00),

-- Ichiran Seasoned Egg: 60g per egg, 80 cal. Per 100g: 133 cal, 10.0P, 1.7C, 9.5F.
('ichiran_seasoned_egg', 'Ichiran Seasoned Egg (Ajitsuke Tamago)', 133, 10.0, 1.7, 9.5,
 0.0, 0.5, 60, 60,
 'ichiran', ARRAY['ichiran seasoned egg', 'ichiran ajitsuke tamago', 'ichiran ramen egg'],
 'japanese', 'Ichiran Ramen', 1, '133 cal/100g. Per egg (60g): 80 cal. Marinated soft-boiled egg.', TRUE,
 400, 350, 3.0, 0.0, 120, 50, 1.5, 80, 0.0, 40, 10, 1.0, 170, 25.0, 0.05),

-- Ichiran Extra Chashu: 50g per serving, 105 cal. Per 100g: 210 cal, 18.0P, 1.0C, 15.0F.
('ichiran_extra_chashu', 'Ichiran Extra Chashu Pork', 210, 18.0, 1.0, 15.0,
 0.0, 0.5, 50, NULL,
 'ichiran', ARRAY['ichiran extra chashu', 'ichiran chashu pork', 'ichiran pork slices'],
 'japanese', 'Ichiran Ramen', 1, '210 cal/100g. Per serving (50g): 105 cal. Extra sliced braised pork belly.', TRUE,
 450, 55, 6.0, 0.1, 200, 8, 0.8, 3, 0.0, 8, 12, 1.8, 120, 15.0, 0.02),

-- Ichiran Green Onions: 15g per serving, 5 cal. Per 100g: 30 cal, 1.8P, 5.0C, 0.5F.
('ichiran_green_onions', 'Ichiran Green Onions (Negi)', 30, 1.8, 5.0, 0.5,
 2.5, 2.0, 15, NULL,
 'ichiran', ARRAY['ichiran green onions', 'ichiran negi', 'ichiran scallions'],
 'japanese', 'Ichiran Ramen', 1, '30 cal/100g. Per serving (15g): 5 cal. Extra chopped green onions.', TRUE,
 15, 0, 0.0, 0.0, 260, 72, 1.5, 50, 18.0, 0, 20, 0.4, 37, 0.6, 0.01),

-- Ichiran Nori Pack: 5g per serving, 15 cal. Per 100g: 300 cal, 35.0P, 35.0C, 3.0F.
('ichiran_nori_pack', 'Ichiran Nori Pack (Seaweed)', 300, 35.0, 35.0, 3.0,
 30.0, 0.0, 5, NULL,
 'ichiran', ARRAY['ichiran nori pack', 'ichiran seaweed', 'ichiran nori sheets'],
 'japanese', 'Ichiran Ramen', 1, '300 cal/100g. Per pack (5g): 15 cal. Extra nori seaweed sheets.', TRUE,
 600, 0, 0.5, 0.0, 2200, 280, 12.0, 520, 12.0, 0, 300, 1.0, 350, 6.0, 0.20),

-- Ichiran Original Spice: 2g per serving, 5 cal. Per 100g: 250 cal, 8.0P, 35.0C, 10.0F.
('ichiran_original_spice', 'Ichiran Original Spice Powder', 250, 8.0, 35.0, 10.0,
 15.0, 3.0, 2, NULL,
 'ichiran', ARRAY['ichiran original spice', 'ichiran spice powder', 'ichiran red seasoning'],
 'japanese', 'Ichiran Ramen', 1, '250 cal/100g. Per serving (2g): 5 cal. Signature chili spice blend.', TRUE,
 800, 0, 2.0, 0.0, 500, 40, 5.0, 200, 15.0, 0, 40, 1.0, 60, 3.0, 0.01),

-- Ichiran Spicy Level 5: 560g per bowl, 550 cal. Per 100g: 98 cal, 3.3P, 11.5C, 4.1F.
('ichiran_spicy_level_5', 'Ichiran Tonkotsu Ramen (Spicy Level 5)', 98, 3.3, 11.5, 4.1,
 0.5, 0.5, 560, NULL,
 'ichiran', ARRAY['ichiran spicy level 5', 'ichiran extra spicy ramen', 'ichiran level 5'],
 'japanese', 'Ichiran Ramen', 1, '98 cal/100g. Per bowl (560g): 550 cal. Tonkotsu ramen with extra spice level 5.', TRUE,
 580, 20, 2.0, 0.0, 160, 16, 1.2, 20, 2.0, 0, 14, 0.9, 82, 8.0, 0.05),

-- ==========================================
-- GENKI SUSHI (Japanese Conveyor Belt Sushi)
-- ==========================================

-- Genki Salmon Nigiri: 35g per piece, 52 cal. Per 100g: 149 cal, 9.4P, 17.1C, 4.3F.
('genki_sushi_salmon_nigiri', 'Genki Sushi Salmon Nigiri', 149, 9.4, 17.1, 4.3,
 0.3, 1.5, 35, 35,
 'genki_sushi', ARRAY['genki sushi salmon nigiri', 'genki salmon sushi', 'genki sake nigiri'],
 'japanese', 'Genki Sushi', 1, '149 cal/100g. Per piece (35g): 52 cal. Salmon slice on vinegared rice.', TRUE,
 200, 15, 0.8, 0.0, 120, 8, 0.3, 5, 0.0, 200, 14, 0.3, 100, 15.0, 0.80),

-- Genki Tuna Nigiri: 35g per piece, 48 cal. Per 100g: 137 cal, 10.6P, 17.1C, 2.3F.
('genki_sushi_tuna_nigiri', 'Genki Sushi Tuna Nigiri', 137, 10.6, 17.1, 2.3,
 0.3, 1.5, 35, 35,
 'genki_sushi', ARRAY['genki sushi tuna nigiri', 'genki tuna sushi', 'genki maguro nigiri'],
 'japanese', 'Genki Sushi', 1, '137 cal/100g. Per piece (35g): 48 cal. Tuna slice on vinegared rice.', TRUE,
 180, 18, 0.3, 0.0, 150, 5, 0.5, 100, 0.0, 60, 18, 0.3, 120, 25.0, 0.12),

-- Genki Shrimp Nigiri: 35g per piece, 45 cal. Per 100g: 129 cal, 8.0P, 17.7C, 2.0F.
('genki_sushi_shrimp_nigiri', 'Genki Sushi Shrimp Nigiri', 129, 8.0, 17.7, 2.0,
 0.3, 1.5, 35, 35,
 'genki_sushi', ARRAY['genki sushi shrimp nigiri', 'genki shrimp sushi', 'genki ebi nigiri'],
 'japanese', 'Genki Sushi', 1, '129 cal/100g. Per piece (35g): 45 cal. Cooked shrimp on vinegared rice.', TRUE,
 220, 55, 0.3, 0.0, 80, 20, 0.3, 5, 0.5, 5, 15, 0.5, 100, 18.0, 0.04),

-- Genki California Roll: 180g per 6 pieces, 255 cal. Per 100g: 142 cal, 4.4P, 22.2C, 3.9F.
('genki_sushi_california_roll', 'Genki Sushi California Roll', 142, 4.4, 22.2, 3.9,
 1.5, 2.5, 180, 30,
 'genki_sushi', ARRAY['genki sushi california roll', 'genki california maki'],
 'japanese', 'Genki Sushi', 1, '142 cal/100g. Per 6 pieces (180g): 255 cal. Crab, avocado, cucumber inside-out roll.', TRUE,
 350, 10, 0.5, 0.0, 130, 15, 0.5, 10, 2.0, 5, 14, 0.4, 60, 8.0, 0.10),

-- Genki Spicy Tuna Roll: 170g per 6 pieces, 260 cal. Per 100g: 153 cal, 6.5P, 21.2C, 4.7F.
('genki_sushi_spicy_tuna_roll', 'Genki Sushi Spicy Tuna Roll', 153, 6.5, 21.2, 4.7,
 1.0, 2.0, 170, 28,
 'genki_sushi', ARRAY['genki sushi spicy tuna roll', 'genki spicy tuna maki'],
 'japanese', 'Genki Sushi', 1, '153 cal/100g. Per 6 pieces (170g): 260 cal. Spicy tuna with mayo inside-out roll.', TRUE,
 300, 15, 0.8, 0.0, 140, 8, 0.6, 50, 0.5, 30, 16, 0.3, 90, 18.0, 0.10),

-- Genki Edamame: 100g per serving, 122 cal. Per 100g: 122 cal, 11.0P, 8.0C, 5.0F.
('genki_sushi_edamame', 'Genki Sushi Edamame', 122, 11.0, 8.0, 5.0,
 5.0, 2.0, 100, NULL,
 'genki_sushi', ARRAY['genki sushi edamame', 'genki edamame beans'],
 'japanese', 'Genki Sushi', 1, '122 cal/100g. Per serving (100g): 122 cal. Steamed salted edamame beans.', TRUE,
 300, 0, 0.6, 0.0, 436, 63, 2.3, 10, 6.0, 0, 64, 1.4, 169, 1.5, 0.36),

-- Genki Miso Soup: 200g per bowl, 40 cal. Per 100g: 20 cal, 1.5P, 1.8C, 0.6F.
('genki_sushi_miso_soup', 'Genki Sushi Miso Soup', 20, 1.5, 1.8, 0.6,
 0.5, 0.5, 200, NULL,
 'genki_sushi', ARRAY['genki sushi miso soup', 'genki miso soup'],
 'japanese', 'Genki Sushi', 1, '20 cal/100g. Per bowl (200g): 40 cal. Traditional miso soup with tofu and seaweed.', TRUE,
 400, 0, 0.1, 0.0, 80, 15, 0.6, 3, 0.5, 0, 12, 0.3, 30, 1.0, 0.02),

-- Genki Karaage: 150g per serving, 285 cal. Per 100g: 190 cal, 16.0P, 10.0C, 9.3F.
('genki_sushi_karaage', 'Genki Sushi Karaage (Fried Chicken)', 190, 16.0, 10.0, 9.3,
 0.5, 0.5, 150, NULL,
 'genki_sushi', ARRAY['genki sushi karaage', 'genki fried chicken', 'genki sushi chicken karaage'],
 'japanese', 'Genki Sushi', 1, '190 cal/100g. Per serving (150g): 285 cal. Japanese-style fried chicken.', TRUE,
 450, 60, 2.0, 0.1, 220, 15, 1.0, 8, 0.0, 3, 22, 1.0, 160, 18.0, 0.02),

-- Genki Takoyaki: 140g per 6 pieces, 230 cal. Per 100g: 164 cal, 6.4P, 18.6C, 7.1F.
('genki_sushi_takoyaki', 'Genki Sushi Takoyaki (Octopus Balls)', 164, 6.4, 18.6, 7.1,
 0.5, 2.0, 140, 23,
 'genki_sushi', ARRAY['genki sushi takoyaki', 'genki takoyaki', 'genki octopus balls'],
 'japanese', 'Genki Sushi', 1, '164 cal/100g. Per 6 pieces (140g): 230 cal. Fried octopus balls with bonito and sauce.', TRUE,
 420, 25, 1.5, 0.0, 100, 20, 1.0, 5, 0.5, 2, 12, 0.5, 70, 12.0, 0.05),

-- Genki Gyoza: 130g per 6 pieces, 200 cal. Per 100g: 154 cal, 7.7P, 16.9C, 6.2F.
('genki_sushi_gyoza', 'Genki Sushi Gyoza (Dumplings)', 154, 7.7, 16.9, 6.2,
 1.0, 1.5, 130, 22,
 'genki_sushi', ARRAY['genki sushi gyoza', 'genki dumplings', 'genki pan fried dumplings'],
 'japanese', 'Genki Sushi', 1, '154 cal/100g. Per 6 pieces (130g): 200 cal. Pan-fried pork and vegetable dumplings.', TRUE,
 400, 20, 1.8, 0.1, 150, 15, 1.0, 5, 2.0, 2, 12, 1.0, 70, 8.0, 0.02),

-- ==========================================
-- NANDO'S (International Peri-Peri Chicken)
-- ==========================================

-- Nando's 1/4 Chicken Breast: 170g per serving, 289 cal. Per 100g: 170 cal, 28.0P, 0.0C, 6.5F.
('nandos_quarter_chicken_breast', 'Nando''s 1/4 Chicken Breast', 170, 28.0, 0.0, 6.5,
 0.0, 0.0, 170, NULL,
 'nandos', ARRAY['nando''s quarter chicken breast', 'nandos 1/4 chicken breast', 'nando''s chicken breast'],
 'chicken', 'Nando''s', 1, '170 cal/100g. Per quarter (170g): 289 cal. Peri-peri marinated chicken breast.', TRUE,
 450, 85, 1.8, 0.0, 260, 14, 1.0, 8, 2.0, 5, 28, 1.0, 220, 27.0, 0.03),

-- Nando's 1/4 Chicken Leg: 185g per serving, 346 cal. Per 100g: 187 cal, 22.0P, 0.1C, 10.8F.
('nandos_quarter_chicken_leg', 'Nando''s 1/4 Chicken Leg', 187, 22.0, 0.1, 10.8,
 0.0, 0.0, 185, NULL,
 'nandos', ARRAY['nando''s quarter chicken leg', 'nandos 1/4 chicken leg', 'nando''s chicken thigh and drumstick'],
 'chicken', 'Nando''s', 1, '187 cal/100g. Per quarter (185g): 346 cal. Peri-peri marinated leg with skin.', TRUE,
 420, 110, 3.5, 0.1, 240, 12, 1.3, 20, 2.0, 5, 23, 2.4, 180, 22.0, 0.05),

-- Nando's Butterfly Chicken: 300g per serving, 331 cal. Per 100g: 110 cal, 19.7P, 0.0C, 3.3F.
('nandos_butterfly_chicken', 'Nando''s Butterfly Chicken', 110, 19.7, 0.0, 3.3,
 0.0, 0.0, 300, NULL,
 'nandos', ARRAY['nando''s butterfly chicken', 'nandos butterfly', 'nando''s whole chicken breast butterflied'],
 'chicken', 'Nando''s', 1, '110 cal/100g. Per serving (300g): 331 cal. Whole chicken breast, butterflied and grilled.', TRUE,
 400, 80, 1.0, 0.0, 270, 12, 0.9, 6, 2.0, 5, 30, 0.9, 230, 28.0, 0.03),

-- Nando's Chicken Thighs (3): 250g per serving, 706 cal. Per 100g: 282 cal, 22.0P, 2.0C, 21.0F.
('nandos_chicken_thighs', 'Nando''s Chicken Thighs (3)', 282, 22.0, 2.0, 21.0,
 0.0, 1.0, 250, 83,
 'nandos', ARRAY['nando''s chicken thighs', 'nandos 3 chicken thighs', 'nando''s boneless thighs'],
 'chicken', 'Nando''s', 1, '282 cal/100g. Per 3 thighs (250g): 706 cal. Boneless peri-peri chicken thighs.', TRUE,
 450, 130, 6.5, 0.1, 230, 12, 1.3, 22, 2.0, 5, 22, 2.4, 175, 22.0, 0.05),

-- Nando's Chicken Wings (5): 200g per serving, 392 cal. Per 100g: 196 cal, 18.5P, 1.5C, 12.8F.
('nandos_chicken_wings', 'Nando''s Chicken Wings (5)', 196, 18.5, 1.5, 12.8,
 0.0, 0.5, 200, 40,
 'nandos', ARRAY['nando''s chicken wings', 'nandos 5 chicken wings', 'nando''s peri peri wings'],
 'chicken', 'Nando''s', 1, '196 cal/100g. Per 5 wings (200g): 392 cal. Peri-peri chicken wings.', TRUE,
 480, 80, 4.0, 0.1, 180, 15, 1.3, 45, 2.0, 5, 18, 1.8, 150, 18.0, 0.04),

-- Nando's Peri-Peri Fries: 200g per regular, 450 cal. Per 100g: 225 cal, 3.5P, 30.0C, 10.5F.
('nandos_peri_peri_fries', 'Nando''s Peri-Peri Fries', 225, 3.5, 30.0, 10.5,
 3.0, 0.5, 200, NULL,
 'nandos', ARRAY['nando''s peri peri fries', 'nandos fries', 'nando''s peri salted chips'],
 'chicken', 'Nando''s', 1, '225 cal/100g. Per regular (200g): 450 cal. Fries seasoned with peri-peri salt.', TRUE,
 380, 0, 1.5, 0.1, 450, 10, 0.5, 0, 5.0, 0, 22, 0.3, 55, 2.0, 0.01),

-- Nando's Spicy Rice: 200g per regular, 246 cal. Per 100g: 123 cal, 3.5P, 20.0C, 3.0F.
('nandos_spicy_rice', 'Nando''s Spicy Rice', 123, 3.5, 20.0, 3.0,
 1.5, 1.0, 200, NULL,
 'nandos', ARRAY['nando''s spicy rice', 'nandos spicy rice', 'nando''s peri peri rice'],
 'chicken', 'Nando''s', 1, '123 cal/100g. Per regular (200g): 246 cal. Rice with peri-peri seasoning and vegetables.', TRUE,
 320, 0, 0.5, 0.0, 100, 15, 0.8, 10, 2.0, 0, 15, 0.5, 50, 5.0, 0.01),

-- Nando's Corn on the Cob: 200g per serving, 189 cal. Per 100g: 95 cal, 3.0P, 16.0C, 2.5F.
('nandos_corn_on_cob', 'Nando''s Corn on the Cob', 95, 3.0, 16.0, 2.5,
 2.0, 4.5, 200, NULL,
 'nandos', ARRAY['nando''s corn on the cob', 'nandos corn', 'nando''s sweetcorn'],
 'chicken', 'Nando''s', 1, '95 cal/100g. Per serving (200g): 189 cal. Grilled corn on the cob.', TRUE,
 15, 0, 0.5, 0.0, 270, 2, 0.5, 10, 7.0, 0, 37, 0.5, 89, 0.6, 0.02),

-- Nando's Coleslaw: 150g per regular, 236 cal. Per 100g: 157 cal, 1.0P, 8.0C, 13.3F.
('nandos_coleslaw', 'Nando''s Coleslaw', 157, 1.0, 8.0, 13.3,
 1.5, 6.0, 150, NULL,
 'nandos', ARRAY['nando''s coleslaw', 'nandos coleslaw'],
 'chicken', 'Nando''s', 1, '157 cal/100g. Per regular (150g): 236 cal. Creamy coleslaw.', TRUE,
 250, 10, 2.0, 0.0, 120, 25, 0.3, 15, 10.0, 0, 8, 0.2, 20, 1.0, 0.05),

-- Nando's Garlic Bread: 150g per regular, 365 cal. Per 100g: 243 cal, 7.3P, 30.0C, 10.7F.
('nandos_garlic_bread', 'Nando''s Garlic Bread', 243, 7.3, 30.0, 10.7,
 1.5, 2.0, 150, NULL,
 'nandos', ARRAY['nando''s garlic bread', 'nandos garlic bread'],
 'chicken', 'Nando''s', 1, '243 cal/100g. Per regular (150g): 365 cal. Toasted garlic bread.', TRUE,
 420, 5, 4.0, 0.0, 80, 25, 1.5, 10, 0.5, 0, 14, 0.5, 60, 8.0, 0.01),

-- Nando's Halloumi Sticks: 100g per serving, 267 cal. Per 100g: 267 cal, 18.0P, 3.0C, 20.5F.
('nandos_halloumi_sticks', 'Nando''s Halloumi Sticks', 267, 18.0, 3.0, 20.5,
 0.0, 1.0, 100, NULL,
 'nandos', ARRAY['nando''s halloumi sticks', 'nandos halloumi', 'nando''s grilled halloumi'],
 'chicken', 'Nando''s', 1, '267 cal/100g. Per serving (100g): 267 cal. Grilled halloumi cheese sticks.', TRUE,
 500, 55, 13.0, 0.0, 50, 600, 0.2, 50, 0.0, 5, 20, 1.5, 350, 5.0, 0.01),

-- Nando's Grilled Chicken Wrap: 300g per wrap, 556 cal. Per 100g: 185 cal, 12.0P, 15.3C, 8.3F.
('nandos_grilled_chicken_wrap', 'Nando''s Grilled Chicken Wrap', 185, 12.0, 15.3, 8.3,
 1.5, 2.0, 300, NULL,
 'nandos', ARRAY['nando''s grilled chicken wrap', 'nandos chicken wrap', 'nando''s wrap'],
 'chicken', 'Nando''s', 1, '185 cal/100g. Per wrap (300g): 556 cal. Grilled chicken with salad in wrap.', TRUE,
 480, 40, 2.5, 0.0, 220, 40, 1.5, 20, 5.0, 2, 22, 1.0, 150, 14.0, 0.02),

-- Nando's Peri-Peri Chicken Burger: 280g per burger, 500 cal. Per 100g: 179 cal, 13.6P, 13.9C, 7.9F.
('nandos_peri_peri_chicken_burger', 'Nando''s Peri-Peri Chicken Burger', 179, 13.6, 13.9, 7.9,
 1.5, 2.5, 280, NULL,
 'nandos', ARRAY['nando''s peri peri chicken burger', 'nandos chicken burger', 'nando''s burger'],
 'chicken', 'Nando''s', 1, '179 cal/100g. Per burger (280g): 500 cal. Grilled chicken fillet burger.', TRUE,
 500, 50, 2.0, 0.0, 230, 35, 1.2, 10, 3.0, 2, 24, 1.0, 160, 16.0, 0.02),

-- Nando's Sunset Burger: 350g per burger, 733 cal. Per 100g: 209 cal, 11.1P, 14.9C, 11.7F.
('nandos_sunset_burger', 'Nando''s Sunset Burger', 209, 11.1, 14.9, 11.7,
 1.5, 3.0, 350, NULL,
 'nandos', ARRAY['nando''s sunset burger', 'nandos sunset burger'],
 'chicken', 'Nando''s', 1, '209 cal/100g. Per burger (350g): 733 cal. Chicken, halloumi, portobello mushroom, perinaise.', TRUE,
 550, 60, 5.5, 0.0, 250, 100, 1.5, 15, 3.0, 3, 22, 1.5, 170, 16.0, 0.02),

-- Nando's Portuguese Roll: 80g per roll, 269 cal. Per 100g: 336 cal, 10.0P, 55.0C, 8.8F.
('nandos_portuguese_roll', 'Nando''s Portuguese Roll', 336, 10.0, 55.0, 8.8,
 2.0, 3.0, 80, NULL,
 'nandos', ARRAY['nando''s portuguese roll', 'nandos roll', 'nando''s bread roll'],
 'chicken', 'Nando''s', 1, '336 cal/100g. Per roll (80g): 269 cal. Traditional Portuguese-style crusty roll.', TRUE,
 380, 0, 1.5, 0.0, 80, 25, 1.5, 0, 0.0, 0, 15, 0.5, 55, 10.0, 0.01),

-- ==========================================
-- GUZMAN Y GOMEZ (Australian Mexican Chain)
-- ==========================================

-- GYG Classic Burrito: 500g per burrito, 700 cal. Per 100g: 140 cal, 7.0P, 16.0C, 5.4F.
('gyg_classic_burrito', 'Guzman y Gomez Classic Burrito', 140, 7.0, 16.0, 5.4,
 2.5, 1.5, 500, NULL,
 'gyg', ARRAY['guzman y gomez classic burrito', 'gyg burrito', 'guzman y gomez burrito'],
 'mexican', 'Guzman y Gomez', 1, '140 cal/100g. Per burrito (500g): 700 cal. Flour tortilla with meat, rice, beans, salsa.', TRUE,
 450, 30, 2.0, 0.1, 280, 60, 2.0, 15, 5.0, 0, 25, 2.0, 140, 10.0, 0.02),

-- GYG Mini Burrito: 300g per burrito, 420 cal. Per 100g: 140 cal, 7.0P, 16.0C, 5.4F.
('gyg_mini_burrito', 'Guzman y Gomez Mini Burrito', 140, 7.0, 16.0, 5.4,
 2.5, 1.5, 300, NULL,
 'gyg', ARRAY['guzman y gomez mini burrito', 'gyg mini burrito', 'gyg small burrito'],
 'mexican', 'Guzman y Gomez', 1, '140 cal/100g. Per burrito (300g): 420 cal. Smaller burrito with same fillings.', TRUE,
 450, 25, 2.0, 0.1, 250, 50, 1.8, 12, 4.0, 0, 22, 1.8, 120, 8.0, 0.02),

-- GYG Nachos: 450g per serving, 680 cal. Per 100g: 151 cal, 6.7P, 14.2C, 7.8F.
('gyg_nachos', 'Guzman y Gomez Nachos', 151, 6.7, 14.2, 7.8,
 2.0, 1.5, 450, NULL,
 'gyg', ARRAY['guzman y gomez nachos', 'gyg nachos'],
 'mexican', 'Guzman y Gomez', 1, '151 cal/100g. Per serving (450g): 680 cal. Corn chips with meat, cheese, salsa, guacamole.', TRUE,
 480, 25, 3.5, 0.1, 250, 100, 1.5, 20, 5.0, 2, 22, 2.0, 130, 8.0, 0.02),

-- GYG Enchilada: 350g per serving, 525 cal. Per 100g: 150 cal, 8.6P, 12.9C, 7.1F.
('gyg_enchilada', 'Guzman y Gomez Enchilada', 150, 8.6, 12.9, 7.1,
 2.0, 2.0, 350, NULL,
 'gyg', ARRAY['guzman y gomez enchilada', 'gyg enchilada'],
 'mexican', 'Guzman y Gomez', 1, '150 cal/100g. Per serving (350g): 525 cal. Corn tortilla with meat, sauce, cheese.', TRUE,
 420, 30, 3.0, 0.1, 250, 80, 1.5, 25, 4.0, 2, 20, 1.5, 130, 8.0, 0.02),

-- GYG Tacos (3): 270g per 3 tacos, 450 cal. Per 100g: 167 cal, 8.3P, 16.7C, 7.4F.
('gyg_tacos', 'Guzman y Gomez Tacos (3)', 167, 8.3, 16.7, 7.4,
 2.5, 1.5, 270, 90,
 'gyg', ARRAY['guzman y gomez tacos', 'gyg tacos', 'gyg 3 tacos'],
 'mexican', 'Guzman y Gomez', 1, '167 cal/100g. Per 3 tacos (270g): 450 cal. Corn tortillas with meat, salsa, lettuce.', TRUE,
 400, 30, 2.5, 0.1, 230, 50, 1.5, 15, 5.0, 0, 22, 1.8, 120, 8.0, 0.02),

-- GYG Quesadilla: 280g per serving, 530 cal. Per 100g: 189 cal, 9.3P, 16.1C, 9.6F.
('gyg_quesadilla', 'Guzman y Gomez Quesadilla', 189, 9.3, 16.1, 9.6,
 1.5, 1.0, 280, NULL,
 'gyg', ARRAY['guzman y gomez quesadilla', 'gyg quesadilla'],
 'mexican', 'Guzman y Gomez', 1, '189 cal/100g. Per serving (280g): 530 cal. Flour tortilla with cheese and meat.', TRUE,
 450, 35, 4.5, 0.1, 200, 120, 1.2, 20, 2.0, 2, 18, 2.0, 150, 10.0, 0.02),

-- GYG Fries: 200g per serving, 420 cal. Per 100g: 210 cal, 3.0P, 28.0C, 10.0F.
('gyg_fries', 'Guzman y Gomez Fries', 210, 3.0, 28.0, 10.0,
 2.5, 0.5, 200, NULL,
 'gyg', ARRAY['guzman y gomez fries', 'gyg fries', 'gyg chips'],
 'mexican', 'Guzman y Gomez', 1, '210 cal/100g. Per serving (200g): 420 cal. Seasoned fries.', TRUE,
 350, 0, 1.5, 0.1, 400, 10, 0.5, 0, 5.0, 0, 20, 0.3, 50, 2.0, 0.01),

-- GYG Guacamole: 80g per serving, 120 cal. Per 100g: 150 cal, 2.0P, 8.0C, 12.5F.
('gyg_guacamole', 'Guzman y Gomez Guacamole', 150, 2.0, 8.0, 12.5,
 5.0, 1.0, 80, NULL,
 'gyg', ARRAY['guzman y gomez guacamole', 'gyg guacamole', 'gyg guac'],
 'mexican', 'Guzman y Gomez', 1, '150 cal/100g. Per serving (80g): 120 cal. Fresh avocado guacamole.', TRUE,
 200, 0, 1.8, 0.0, 400, 12, 0.5, 8, 10.0, 0, 25, 0.5, 45, 0.5, 0.05),

-- GYG Grilled Chicken Bowl: 400g per bowl, 520 cal. Per 100g: 130 cal, 9.0P, 14.0C, 4.0F.
('gyg_grilled_chicken_bowl', 'Guzman y Gomez Grilled Chicken Bowl', 130, 9.0, 14.0, 4.0,
 2.5, 1.5, 400, NULL,
 'gyg', ARRAY['guzman y gomez grilled chicken bowl', 'gyg chicken bowl', 'gyg burrito bowl chicken'],
 'mexican', 'Guzman y Gomez', 1, '130 cal/100g. Per bowl (400g): 520 cal. Grilled chicken on rice with salsa and veggies.', TRUE,
 400, 30, 1.0, 0.0, 300, 40, 1.5, 20, 6.0, 0, 25, 1.5, 140, 12.0, 0.02),

-- GYG Breakfast Burrito: 350g per burrito, 540 cal. Per 100g: 154 cal, 8.0P, 14.3C, 7.1F.
('gyg_breakfast_burrito', 'Guzman y Gomez Breakfast Burrito', 154, 8.0, 14.3, 7.1,
 1.5, 1.5, 350, NULL,
 'gyg', ARRAY['guzman y gomez breakfast burrito', 'gyg breakfast burrito', 'gyg brekkie burrito'],
 'mexican', 'Guzman y Gomez', 1, '154 cal/100g. Per burrito (350g): 540 cal. Eggs, bacon, cheese, hash brown in tortilla.', TRUE,
 480, 120, 3.0, 0.1, 200, 60, 1.5, 40, 2.0, 8, 18, 1.5, 140, 14.0, 0.02),

-- ==========================================
-- LEON (UK Healthy Fast Food)
-- ==========================================

-- Leon Chargrilled Chicken: 350g per serving, 432 cal. Per 100g: 123 cal, 14.9P, 7.1C, 4.0F.
('leon_chargrilled_chicken', 'Leon Chargrilled Chicken', 123, 14.9, 7.1, 4.0,
 1.5, 1.5, 350, NULL,
 'leon', ARRAY['leon chargrilled chicken', 'leon chicken', 'leon chargrilled chicken burger'],
 'healthy', 'Leon', 1, '123 cal/100g. Per serving (350g): 432 cal. Chargrilled chicken with sides.', TRUE,
 380, 50, 1.0, 0.0, 280, 20, 1.2, 10, 3.0, 2, 25, 1.0, 180, 18.0, 0.02),

-- Leon LOVe Burger: 280g per burger, 450 cal. Per 100g: 161 cal, 8.6P, 15.7C, 7.1F.
('leon_love_burger', 'Leon LOVe Burger', 161, 8.6, 15.7, 7.1,
 3.0, 3.0, 280, NULL,
 'leon', ARRAY['leon love burger', 'leon plant burger', 'leon vegan burger'],
 'healthy', 'Leon', 1, '161 cal/100g. Per burger (280g): 450 cal. Plant-based patty with vegan cheddar.', TRUE,
 420, 0, 1.5, 0.0, 300, 40, 2.5, 5, 3.0, 0, 25, 1.5, 100, 5.0, 0.03),

-- Leon Chicken Satay Rice Box: 400g per box, 520 cal. Per 100g: 130 cal, 9.0P, 14.0C, 4.0F.
('leon_chicken_satay_rice_box', 'Leon Chicken Satay Rice Box', 130, 9.0, 14.0, 4.0,
 1.5, 2.0, 400, NULL,
 'leon', ARRAY['leon chicken satay rice box', 'leon satay box', 'leon peanut satay'],
 'healthy', 'Leon', 1, '130 cal/100g. Per box (400g): 520 cal. Chargrilled chicken with satay sauce on brown rice.', TRUE,
 400, 35, 1.0, 0.0, 250, 25, 1.5, 10, 3.0, 2, 30, 1.5, 160, 14.0, 0.02),

-- Leon Moroccan Meatballs: 380g per serving, 490 cal. Per 100g: 129 cal, 8.4P, 12.1C, 5.3F.
('leon_moroccan_meatballs', 'Leon Moroccan Meatballs', 129, 8.4, 12.1, 5.3,
 2.0, 3.0, 380, NULL,
 'leon', ARRAY['leon moroccan meatballs', 'leon meatballs', 'leon moroccan meatball box'],
 'healthy', 'Leon', 1, '129 cal/100g. Per serving (380g): 490 cal. Spiced beef meatballs with tomato sauce on rice.', TRUE,
 380, 30, 2.0, 0.1, 280, 30, 2.0, 25, 5.0, 0, 22, 2.5, 130, 12.0, 0.02),

-- Leon Mac & Cheese: 350g per serving, 525 cal. Per 100g: 150 cal, 6.0P, 14.3C, 7.7F.
('leon_mac_cheese', 'Leon Mac & Cheese', 150, 6.0, 14.3, 7.7,
 0.8, 2.0, 350, NULL,
 'leon', ARRAY['leon mac and cheese', 'leon mac & cheese', 'leon macaroni cheese'],
 'healthy', 'Leon', 1, '150 cal/100g. Per serving (350g): 525 cal. Macaroni in cheese sauce.', TRUE,
 400, 25, 4.0, 0.1, 130, 110, 0.8, 30, 0.0, 2, 14, 1.0, 130, 8.0, 0.01),

-- Leon Baked Fries: 200g per serving, 300 cal. Per 100g: 150 cal, 2.5P, 24.0C, 5.0F.
('leon_baked_fries', 'Leon Baked Fries', 150, 2.5, 24.0, 5.0,
 3.0, 0.5, 200, NULL,
 'leon', ARRAY['leon baked fries', 'leon fries', 'leon chips'],
 'healthy', 'Leon', 1, '150 cal/100g. Per serving (200g): 300 cal. Oven-baked fries.', TRUE,
 250, 0, 0.8, 0.0, 400, 10, 0.5, 0, 5.0, 0, 20, 0.3, 50, 2.0, 0.01),

-- Leon Aioli Fries: 220g per serving, 380 cal. Per 100g: 173 cal, 2.7P, 22.0C, 8.2F.
('leon_aioli_fries', 'Leon Aioli Fries', 173, 2.7, 22.0, 8.2,
 3.0, 0.5, 220, NULL,
 'leon', ARRAY['leon aioli fries', 'leon garlic aioli fries'],
 'healthy', 'Leon', 1, '173 cal/100g. Per serving (220g): 380 cal. Baked fries with garlic aioli dip.', TRUE,
 300, 8, 1.5, 0.0, 380, 12, 0.5, 3, 4.5, 0, 19, 0.3, 50, 2.0, 0.01),

-- Leon Haloumi Wrap: 300g per wrap, 510 cal. Per 100g: 170 cal, 8.3P, 16.0C, 8.3F.
('leon_haloumi_wrap', 'Leon Haloumi Wrap', 170, 8.3, 16.0, 8.3,
 2.0, 2.0, 300, NULL,
 'leon', ARRAY['leon haloumi wrap', 'leon halloumi wrap'],
 'healthy', 'Leon', 1, '170 cal/100g. Per wrap (300g): 510 cal. Grilled halloumi with salad in wrap.', TRUE,
 480, 30, 5.0, 0.0, 180, 150, 1.0, 20, 4.0, 2, 18, 1.2, 180, 8.0, 0.01),

-- Leon Waffle Fries: 180g per serving, 340 cal. Per 100g: 189 cal, 2.8P, 25.6C, 8.3F.
('leon_waffle_fries', 'Leon Waffle Fries', 189, 2.8, 25.6, 8.3,
 2.5, 0.5, 180, NULL,
 'leon', ARRAY['leon waffle fries', 'leon waffle chips'],
 'healthy', 'Leon', 1, '189 cal/100g. Per serving (180g): 340 cal. Crispy waffle-cut fries.', TRUE,
 280, 0, 1.2, 0.1, 380, 10, 0.5, 0, 4.0, 0, 18, 0.3, 48, 2.0, 0.01),

-- Leon Brownie: 80g per brownie, 320 cal. Per 100g: 400 cal, 5.0P, 45.0C, 22.5F.
('leon_brownie', 'Leon Brownie', 400, 5.0, 45.0, 22.5,
 2.5, 30.0, 80, NULL,
 'leon', ARRAY['leon brownie', 'leon chocolate brownie'],
 'healthy', 'Leon', 1, '400 cal/100g. Per brownie (80g): 320 cal. Rich chocolate brownie.', TRUE,
 120, 30, 12.0, 0.1, 200, 25, 2.5, 15, 0.0, 2, 40, 1.0, 80, 4.0, 0.01),

-- ==========================================
-- DISHOOM (UK Indian Restaurant)
-- ==========================================

-- Dishoom Black Daal: 300g per serving, 390 cal. Per 100g: 130 cal, 6.0P, 13.0C, 6.0F.
('dishoom_black_daal', 'Dishoom Black Daal', 130, 6.0, 13.0, 6.0,
 4.0, 1.5, 300, NULL,
 'dishoom', ARRAY['dishoom black daal', 'dishoom black dal', 'dishoom house black daal'],
 'indian', 'Dishoom', 1, '130 cal/100g. Per serving (300g): 390 cal. 24-hour slow-cooked black lentil daal.', TRUE,
 350, 10, 3.5, 0.1, 350, 40, 3.0, 20, 2.0, 0, 40, 1.5, 120, 5.0, 0.03),

-- Dishoom Chicken Ruby: 350g per serving, 525 cal. Per 100g: 150 cal, 12.0P, 5.7C, 9.1F.
('dishoom_chicken_ruby', 'Dishoom Chicken Ruby', 150, 12.0, 5.7, 9.1,
 1.0, 2.5, 350, NULL,
 'dishoom', ARRAY['dishoom chicken ruby', 'dishoom chicken curry', 'dishoom ruby chicken'],
 'indian', 'Dishoom', 1, '150 cal/100g. Per serving (350g): 525 cal. Chicken in classic makhani-style sauce.', TRUE,
 400, 55, 4.0, 0.1, 280, 30, 1.5, 40, 3.0, 2, 22, 1.5, 160, 14.0, 0.02),

-- Dishoom Lamb Raan: 280g per serving, 530 cal. Per 100g: 189 cal, 16.0P, 3.0C, 12.9F.
('dishoom_lamb_raan', 'Dishoom Lamb Raan', 189, 16.0, 3.0, 12.9,
 0.5, 1.0, 280, NULL,
 'dishoom', ARRAY['dishoom lamb raan', 'dishoom slow-cooked lamb', 'dishoom lamb leg'],
 'indian', 'Dishoom', 1, '189 cal/100g. Per serving (280g): 530 cal. Slow-cooked lamb leg with spices.', TRUE,
 350, 65, 5.5, 0.2, 300, 20, 2.5, 5, 1.0, 3, 22, 4.0, 180, 18.0, 0.03),

-- Dishoom Paneer Tikka: 200g per serving, 360 cal. Per 100g: 180 cal, 12.0P, 5.0C, 13.0F.
('dishoom_paneer_tikka', 'Dishoom Paneer Tikka', 180, 12.0, 5.0, 13.0,
 1.0, 2.0, 200, NULL,
 'dishoom', ARRAY['dishoom paneer tikka', 'dishoom grilled paneer'],
 'indian', 'Dishoom', 1, '180 cal/100g. Per serving (200g): 360 cal. Tandoor-grilled marinated paneer.', TRUE,
 400, 40, 8.0, 0.0, 120, 250, 1.0, 50, 2.0, 2, 18, 1.5, 200, 5.0, 0.01),

-- Dishoom Gunpowder Potatoes: 200g per serving, 280 cal. Per 100g: 140 cal, 2.5P, 18.0C, 6.5F.
('dishoom_gunpowder_potatoes', 'Dishoom Gunpowder Potatoes', 140, 2.5, 18.0, 6.5,
 2.0, 1.0, 200, NULL,
 'dishoom', ARRAY['dishoom gunpowder potatoes', 'dishoom potatoes', 'dishoom spiced potatoes'],
 'indian', 'Dishoom', 1, '140 cal/100g. Per serving (200g): 280 cal. Smoky grilled potatoes with crushed spices.', TRUE,
 300, 5, 1.5, 0.0, 400, 15, 1.0, 5, 8.0, 0, 22, 0.3, 50, 2.0, 0.01),

-- Dishoom Plain Naan: 100g per naan, 285 cal. Per 100g: 285 cal, 8.0P, 48.0C, 6.5F.
('dishoom_plain_naan', 'Dishoom Plain Naan', 285, 8.0, 48.0, 6.5,
 2.0, 3.0, 100, NULL,
 'dishoom', ARRAY['dishoom plain naan', 'dishoom naan bread'],
 'indian', 'Dishoom', 1, '285 cal/100g. Per naan (100g): 285 cal. Traditional tandoor-baked naan.', TRUE,
 380, 5, 1.5, 0.0, 90, 30, 2.0, 0, 0.0, 0, 18, 0.6, 65, 10.0, 0.01),

-- Dishoom Garlic Naan: 110g per naan, 330 cal. Per 100g: 300 cal, 8.2P, 46.0C, 9.1F.
('dishoom_garlic_naan', 'Dishoom Garlic Naan', 300, 8.2, 46.0, 9.1,
 2.0, 3.0, 110, NULL,
 'dishoom', ARRAY['dishoom garlic naan', 'dishoom garlic naan bread'],
 'indian', 'Dishoom', 1, '300 cal/100g. Per naan (110g): 330 cal. Tandoor naan with garlic butter.', TRUE,
 400, 8, 3.0, 0.0, 95, 32, 2.0, 5, 0.5, 0, 18, 0.6, 65, 10.0, 0.01),

-- Dishoom Cheese Naan: 120g per naan, 380 cal. Per 100g: 317 cal, 10.8P, 40.0C, 12.5F.
('dishoom_cheese_naan', 'Dishoom Cheese Naan', 317, 10.8, 40.0, 12.5,
 1.8, 3.0, 120, NULL,
 'dishoom', ARRAY['dishoom cheese naan', 'dishoom cheese naan bread'],
 'indian', 'Dishoom', 1, '317 cal/100g. Per naan (120g): 380 cal. Naan stuffed with melted cheese.', TRUE,
 450, 20, 6.5, 0.1, 80, 120, 1.8, 30, 0.0, 2, 16, 1.0, 140, 8.0, 0.01),

-- Dishoom Chicken Tikka: 200g per serving, 300 cal. Per 100g: 150 cal, 22.0P, 3.0C, 5.5F.
('dishoom_chicken_tikka', 'Dishoom Chicken Tikka', 150, 22.0, 3.0, 5.5,
 0.5, 1.5, 200, NULL,
 'dishoom', ARRAY['dishoom chicken tikka', 'dishoom grilled chicken'],
 'indian', 'Dishoom', 1, '150 cal/100g. Per serving (200g): 300 cal. Tandoor-grilled marinated chicken.', TRUE,
 420, 70, 1.5, 0.0, 260, 20, 1.2, 15, 2.0, 3, 25, 1.2, 200, 20.0, 0.02),

-- Dishoom Biryani: 450g per serving, 630 cal. Per 100g: 140 cal, 6.2P, 18.0C, 4.9F.
('dishoom_biryani', 'Dishoom Biryani', 140, 6.2, 18.0, 4.9,
 1.0, 1.0, 450, NULL,
 'dishoom', ARRAY['dishoom biryani', 'dishoom chicken biryani', 'dishoom lamb biryani'],
 'indian', 'Dishoom', 1, '140 cal/100g. Per serving (450g): 630 cal. Fragrant basmati rice with spiced meat.', TRUE,
 380, 30, 1.5, 0.0, 200, 25, 1.5, 15, 2.0, 2, 22, 1.5, 120, 10.0, 0.02),

-- Dishoom Mango Lassi: 300g per glass, 210 cal. Per 100g: 70 cal, 2.3P, 12.0C, 1.5F.
('dishoom_mango_lassi', 'Dishoom Mango Lassi', 70, 2.3, 12.0, 1.5,
 0.3, 10.0, 300, NULL,
 'dishoom', ARRAY['dishoom mango lassi', 'dishoom lassi mango'],
 'indian', 'Dishoom', 1, '70 cal/100g. Per glass (300g): 210 cal. Yogurt drink with mango.', TRUE,
 40, 5, 1.0, 0.0, 150, 80, 0.2, 30, 10.0, 5, 12, 0.3, 60, 2.0, 0.01),

-- Dishoom Vada Pav: 150g per serving, 320 cal. Per 100g: 213 cal, 5.3P, 28.0C, 9.3F.
('dishoom_vada_pav', 'Dishoom Vada Pav', 213, 5.3, 28.0, 9.3,
 2.0, 2.0, 150, NULL,
 'dishoom', ARRAY['dishoom vada pav', 'dishoom potato fritter bun'],
 'indian', 'Dishoom', 1, '213 cal/100g. Per serving (150g): 320 cal. Spiced potato fritter in soft bun.', TRUE,
 380, 0, 2.0, 0.1, 280, 15, 1.5, 5, 5.0, 0, 20, 0.5, 60, 3.0, 0.01),

-- Dishoom Okra Fries: 120g per serving, 180 cal. Per 100g: 150 cal, 3.0P, 12.0C, 10.0F.
('dishoom_okra_fries', 'Dishoom Okra Fries', 150, 3.0, 12.0, 10.0,
 3.5, 2.0, 120, NULL,
 'dishoom', ARRAY['dishoom okra fries', 'dishoom crispy okra', 'dishoom bhindi fries'],
 'indian', 'Dishoom', 1, '150 cal/100g. Per serving (120g): 180 cal. Crispy fried okra with spices.', TRUE,
 250, 0, 1.5, 0.0, 250, 60, 1.0, 30, 15.0, 0, 35, 0.5, 50, 1.0, 0.01)

ON CONFLICT (food_name_normalized) DO NOTHING;
