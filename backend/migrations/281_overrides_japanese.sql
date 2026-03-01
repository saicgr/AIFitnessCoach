-- ============================================================================
-- 281_overrides_japanese.sql
-- Generated: 2026-02-28
-- Total items: 40 Japanese cuisine foods
-- Sources: nutritionvalue.org, eatthismuch.com, snapcalorie.com, nutritionix.com,
--          calorieking.com, fatsecret.com, foodstruct.com, slism.com (Calorie Slism Japan),
--          myfooddiary.com, calories-info.com
-- All values are per 100g of cooked/prepared food.
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES

-- ============================================================================
-- SUSHI - Nigiri
-- Nigiri: ~35g per piece (small mound of rice topped with fish)
-- Source: calorieking.com, eatthismuch.com, nutritionvalue.org, checkyourfood.com
-- ============================================================================
-- Salmon Nigiri: ~48 cal per piece (35g), 155 cal/100g
('salmon nigiri', 'Salmon Nigiri', 155, 8.5, 20.0, 4.2,
  0.3, 3.0,
  35, 70,
  'japanese_cuisine', ARRAY['sake nigiri', 'salmon sushi', 'sake sushi', 'nigiri salmon'],
  '~35g per piece, 2-piece order. Rice with raw salmon slice.',
  NULL, 'sushi', 2),

-- Tuna Nigiri: ~45 cal per piece (35g), leaner than salmon
('tuna nigiri', 'Tuna Nigiri', 148, 10.0, 20.0, 2.5,
  0.3, 3.0,
  35, 70,
  'japanese_cuisine', ARRAY['maguro nigiri', 'tuna sushi', 'maguro sushi', 'nigiri tuna'],
  '~35g per piece, 2-piece order. Rice with raw tuna slice.',
  NULL, 'sushi', 2),

-- ============================================================================
-- SUSHI - Rolls (Maki)
-- Standard roll: ~180-220g for 6-8 pieces
-- Source: nutritionvalue.org, snapcalorie.com, healthline.com, eatthismuch.com
-- ============================================================================
-- California Roll: 145 cal/100g, ~250-300 cal per 8-piece roll (~200g)
('california roll', 'California Roll', 145, 3.5, 24.0, 3.8,
  1.5, 3.5,
  28, 200,
  'japanese_cuisine', ARRAY['cali roll', 'california maki', 'kani roll', 'california sushi roll'],
  '~28g per piece, 8-piece roll. Imitation crab, avocado, cucumber.',
  NULL, 'sushi', 8),

-- Spicy Tuna Roll: 160 cal/100g, includes spicy mayo
('spicy tuna roll', 'Spicy Tuna Roll', 160, 7.5, 21.0, 5.0,
  0.8, 3.0,
  27, 190,
  'japanese_cuisine', ARRAY['spicy tuna maki', 'spicy tuna sushi roll', 'spicy tuna hand roll'],
  '~27g per piece, 6-8 piece roll. Spicy mayo adds fat.',
  NULL, 'sushi', 6),

-- Dragon Roll: 180 cal/100g, topped with eel and avocado
('dragon roll', 'Dragon Roll', 180, 6.0, 25.0, 6.0,
  1.2, 4.5,
  30, 220,
  'japanese_cuisine', ARRAY['dragon maki', 'dragon sushi roll', 'eel avocado roll'],
  '~30g per piece, 8-piece roll. Shrimp tempura inside, eel & avocado on top.',
  NULL, 'sushi', 8),

-- Rainbow Roll: 175 cal/100g, california roll topped with assorted fish
('rainbow roll', 'Rainbow Roll', 175, 7.5, 22.0, 5.5,
  1.2, 3.0,
  30, 220,
  'japanese_cuisine', ARRAY['rainbow maki', 'rainbow sushi roll', 'assorted fish roll'],
  '~30g per piece, 8-piece roll. California roll base with assorted sashimi on top.',
  NULL, 'sushi', 8),

-- Philadelphia Roll: 185, higher fat from cream cheese
('philadelphia roll', 'Philadelphia Roll', 185, 7.0, 22.0, 7.5,
  0.5, 3.5,
  28, 200,
  'japanese_cuisine', ARRAY['philly roll', 'cream cheese roll', 'philly sushi roll', 'philadelphia maki'],
  '~28g per piece, 8-piece roll. Salmon, cream cheese, cucumber.',
  NULL, 'sushi', 8),

-- ============================================================================
-- SUSHI - Sides
-- Source: foodstruct.com, nutritionvalue.org, snapcalorie.com
-- ============================================================================
-- Edamame: 121 cal/100g, high plant protein
('edamame', 'Edamame', 121, 12.0, 9.0, 5.2,
  5.2, 2.2,
  NULL, 150,
  'japanese_cuisine', ARRAY['soybeans', 'boiled soybeans', 'mukimame', 'green soybeans'],
  'Steamed young soybeans in pods. ~150g per appetizer serving.',
  NULL, 'japanese', 1),

-- Miso Soup: 35 cal/100g, very light
('miso soup', 'Miso Soup', 35, 2.5, 3.5, 1.2,
  0.5, 1.0,
  NULL, 240,
  'japanese_cuisine', ARRAY['misoshiru', 'miso shiru', 'tofu miso soup', 'wakame miso soup'],
  '~240ml per bowl. Dashi broth with miso paste, tofu, wakame seaweed.',
  NULL, 'japanese', 1),

-- ============================================================================
-- RAMEN
-- Typical bowl: 500-700g including broth
-- Source: immieats.com, snapcalorie.com, slism.com, apexsk.com
-- ============================================================================
-- Tonkotsu Ramen: rich pork bone broth, ~500 cal per 600g bowl
('tonkotsu ramen', 'Tonkotsu Ramen', 85, 5.0, 8.5, 3.8,
  0.3, 0.5,
  NULL, 650,
  'japanese_cuisine', ARRAY['pork bone ramen', 'hakata ramen', 'tonkotsu', 'pork broth ramen'],
  '~650g per bowl. Rich creamy pork bone broth, chashu, egg, noodles.',
  NULL, 'ramen', 1),

-- Shoyu Ramen: soy sauce based, lighter broth
('shoyu ramen', 'Shoyu Ramen', 78, 4.5, 8.0, 3.0,
  0.3, 0.8,
  NULL, 620,
  'japanese_cuisine', ARRAY['soy sauce ramen', 'shoyu', 'tokyo ramen', 'soy ramen'],
  '~620g per bowl. Clear soy sauce broth with chashu, nori, menma, egg.',
  NULL, 'ramen', 1),

-- Miso Ramen: miso paste broth, slightly higher cal
('miso ramen', 'Miso Ramen', 90, 5.0, 9.0, 3.5,
  0.5, 1.0,
  NULL, 650,
  'japanese_cuisine', ARRAY['miso ramen soup', 'sapporo ramen', 'miso noodle soup'],
  '~650g per bowl. Miso-based broth, richer and heartier than shoyu.',
  NULL, 'ramen', 1),

-- Shio Ramen: salt based, lightest broth
('shio ramen', 'Shio Ramen', 72, 4.0, 8.0, 2.5,
  0.2, 0.3,
  NULL, 600,
  'japanese_cuisine', ARRAY['salt ramen', 'shio', 'light ramen', 'clear broth ramen'],
  '~600g per bowl. Light, clear salt-based broth. Lowest calorie ramen variety.',
  NULL, 'ramen', 1),

-- ============================================================================
-- DONBURI (Rice Bowls)
-- Typical bowl: 350-460g
-- Source: slism.com (Calorie Slism Japan), snapcalorie.com, nutritionix.com
-- ============================================================================
-- Gyudon: beef and onion over rice, 185 cal/100g
('gyudon', 'Gyudon (Beef Bowl)', 185, 8.0, 22.0, 7.5,
  0.5, 4.0,
  NULL, 400,
  'japanese_cuisine', ARRAY['beef bowl', 'beef rice bowl', 'yoshinoya beef bowl', 'japanese beef bowl', 'beef don'],
  '~400g per bowl. Thinly sliced beef and onion simmered in sweet soy sauce over rice.',
  NULL, 'rice', 1),

-- Katsudon: deep-fried pork cutlet with egg on rice
('katsudon', 'Katsudon (Pork Cutlet Bowl)', 200, 10.5, 21.0, 8.0,
  0.5, 3.5,
  NULL, 400,
  'japanese_cuisine', ARRAY['pork cutlet bowl', 'pork katsu don', 'katsu don', 'tonkatsu bowl', 'cutlet rice bowl'],
  '~400g per bowl. Breaded fried pork cutlet simmered with egg on rice.',
  NULL, 'rice', 1),

-- Oyakodon: chicken and egg over rice
('oyakodon', 'Oyakodon (Chicken & Egg Bowl)', 146, 8.5, 18.0, 4.0,
  0.3, 3.0,
  NULL, 420,
  'japanese_cuisine', ARRAY['chicken egg bowl', 'chicken and egg rice', 'oyako don', 'parent child bowl'],
  '~420g per bowl. Chicken and egg simmered in dashi-soy sauce over rice.',
  NULL, 'rice', 1),

-- Tendon: tempura over rice
('tendon', 'Tendon (Tempura Bowl)', 175, 5.5, 22.0, 7.0,
  0.8, 3.0,
  NULL, 400,
  'japanese_cuisine', ARRAY['tempura don', 'tempura bowl', 'tempura rice bowl', 'tendon bowl'],
  '~400g per bowl. Assorted tempura (shrimp, vegetables) on rice with tsuyu sauce.',
  NULL, 'rice', 1),

-- Chirashi: scattered sashimi over sushi rice
('chirashi', 'Chirashi (Scattered Sushi Bowl)', 160, 9.5, 20.0, 4.0,
  0.5, 4.0,
  NULL, 400,
  'japanese_cuisine', ARRAY['chirashi don', 'chirashizushi', 'scattered sushi', 'chirashi bowl', 'bara chirashi'],
  '~400g per bowl. Assorted sashimi scattered over sushi rice.',
  NULL, 'sushi', 1),

-- ============================================================================
-- NOODLES
-- Source: nutritionvalue.org, snapcalorie.com, foodstruct.com
-- ============================================================================
-- Udon: thick wheat noodles, cooked
('udon', 'Udon Noodles', 105, 3.5, 21.5, 0.5,
  0.8, 0.5,
  NULL, 250,
  'japanese_cuisine', ARRAY['udon noodles', 'kake udon', 'udon soup', 'kitsune udon', 'tempura udon'],
  '~250g noodles per bowl (not counting broth). Thick chewy wheat flour noodles.',
  NULL, 'japanese', 1),

-- Soba: buckwheat noodles, cooked
('soba', 'Soba (Buckwheat Noodles)', 99, 5.0, 21.0, 0.1,
  0.0, 0.5,
  NULL, 200,
  'japanese_cuisine', ARRAY['soba noodles', 'buckwheat noodles', 'zaru soba', 'kake soba', 'cold soba'],
  '~200g noodles per serving. Thin buckwheat noodles, served hot or cold.',
  NULL, 'japanese', 1),

-- Yakisoba: stir-fried noodles with sauce
('yakisoba', 'Yakisoba (Fried Noodles)', 180, 5.5, 27.0, 5.5,
  1.5, 3.0,
  NULL, 300,
  'japanese_cuisine', ARRAY['yakisoba noodles', 'stir fried noodles', 'fried noodles', 'japanese fried noodles'],
  '~300g per serving. Stir-fried wheat noodles with vegetables, pork, yakisoba sauce.',
  NULL, 'japanese', 1),

-- ============================================================================
-- FRIED ITEMS
-- Source: fatsecret.com, nutritionix.com, snapcalorie.com, slism.com
-- ============================================================================
-- Shrimp Tempura: battered and deep-fried shrimp
('shrimp tempura', 'Shrimp Tempura', 245, 10.0, 20.0, 14.0,
  0.5, 0.5,
  20, 100,
  'japanese_cuisine', ARRAY['ebi tempura', 'prawn tempura', 'tempura shrimp', 'ebi furai'],
  '~20g per piece. Light crispy batter-fried shrimp. 5-piece serving.',
  NULL, 'japanese', 5),

-- Vegetable Tempura: assorted vegetables in tempura batter
('vegetable tempura', 'Vegetable Tempura', 220, 3.5, 22.0, 13.5,
  2.0, 1.0,
  25, 150,
  'japanese_cuisine', ARRAY['yasai tempura', 'veggie tempura', 'mixed tempura vegetables', 'assorted tempura'],
  '~25g per piece. Assorted vegetables (sweet potato, eggplant, shiso, kabocha) in tempura batter.',
  NULL, 'japanese', 6),

-- Tonkatsu: breaded deep-fried pork cutlet
('tonkatsu', 'Tonkatsu (Pork Cutlet)', 275, 18.0, 12.0, 17.5,
  0.5, 1.5,
  NULL, 150,
  'japanese_cuisine', ARRAY['pork katsu', 'pork cutlet', 'breaded pork', 'tonkatsu pork', 'katsu'],
  '~150g per serving. Panko-breaded deep-fried pork loin cutlet with tonkatsu sauce.',
  NULL, 'japanese', 1),

-- Chicken Karaage: Japanese fried chicken
('chicken karaage', 'Chicken Karaage', 250, 18.0, 12.0, 14.5,
  0.2, 0.5,
  25, 150,
  'japanese_cuisine', ARRAY['karaage', 'japanese fried chicken', 'tori karaage', 'karaage chicken'],
  '~25g per piece. Bite-sized marinated chicken, coated in potato starch and deep-fried.',
  NULL, 'japanese', 6),

-- Korokke: Japanese potato croquette
('korokke', 'Korokke (Croquette)', 210, 5.0, 24.0, 10.5,
  1.5, 1.0,
  80, 160,
  'japanese_cuisine', ARRAY['croquette', 'japanese croquette', 'potato croquette', 'korokke croquette'],
  '~80g per piece. Mashed potato with ground meat, panko-breaded and deep-fried.',
  NULL, 'japanese', 2),

-- Gyoza: pan-fried dumplings
('gyoza', 'Gyoza (Dumplings)', 195, 8.0, 22.0, 8.5,
  0.8, 1.5,
  25, 150,
  'japanese_cuisine', ARRAY['potstickers', 'japanese dumplings', 'pan fried dumplings', 'jiaozi', 'yaki gyoza'],
  '~25g per piece, 6 per order. Pan-fried pork and cabbage dumplings.',
  NULL, 'japanese', 6),

-- ============================================================================
-- GRILLED ITEMS
-- Source: slism.com, snapcalorie.com, nutritionix.com, calorieking.com
-- ============================================================================
-- Yakitori: grilled chicken skewer
('yakitori', 'Yakitori (Chicken Skewer)', 175, 18.0, 5.0, 9.0,
  0.0, 3.5,
  40, 120,
  'japanese_cuisine', ARRAY['chicken skewer', 'grilled chicken skewer', 'yakitori chicken', 'chicken yakitori'],
  '~40g per skewer (tare sauce), 3-skewer serving. Bite-sized chicken grilled on bamboo skewers.',
  NULL, 'japanese', 3),

-- Teriyaki Chicken: glazed grilled chicken
('teriyaki chicken', 'Teriyaki Chicken', 165, 20.0, 7.0, 6.5,
  0.0, 5.5,
  NULL, 170,
  'japanese_cuisine', ARRAY['chicken teriyaki', 'grilled teriyaki chicken', 'teriyaki chicken thigh'],
  '~170g per serving. Grilled chicken with sweet soy glaze.',
  NULL, 'japanese', 1),

-- Teriyaki Salmon: glazed grilled salmon
('teriyaki salmon', 'Teriyaki Salmon', 170, 18.0, 7.0, 8.0,
  0.0, 5.0,
  NULL, 170,
  'japanese_cuisine', ARRAY['salmon teriyaki', 'grilled teriyaki salmon', 'sake teriyaki'],
  '~170g fillet. Grilled salmon with teriyaki glaze.',
  NULL, 'japanese', 1),

-- Unagi: grilled eel with kabayaki sauce
('unagi', 'Unagi (Grilled Eel)', 255, 18.0, 8.0, 17.0,
  0.0, 6.0,
  NULL, 120,
  'japanese_cuisine', ARRAY['grilled eel', 'kabayaki', 'unagi kabayaki', 'freshwater eel', 'eel'],
  '~120g per serving. Freshwater eel glazed and grilled with sweet kabayaki sauce.',
  NULL, 'japanese', 1),

-- ============================================================================
-- SIDES & SNACKS
-- Source: slism.com, snapcalorie.com, nutritionix.com, fitia.app
-- ============================================================================
-- Takoyaki: octopus balls
('takoyaki', 'Takoyaki (Octopus Balls)', 175, 6.5, 20.0, 7.5,
  0.5, 2.0,
  35, 210,
  'japanese_cuisine', ARRAY['octopus balls', 'tako yaki', 'octopus dumplings', 'takoyaki balls'],
  '~35g per ball, 6 per serving. Battered octopus balls with mayo, sauce, bonito flakes.',
  NULL, 'sides', 6),

-- Onigiri: rice ball
('onigiri', 'Onigiri (Rice Ball)', 170, 3.5, 37.0, 0.5,
  0.3, 0.5,
  110, 110,
  'japanese_cuisine', ARRAY['rice ball', 'musubi', 'omusubi', 'japanese rice ball', 'onigiri rice ball'],
  '~110g per piece. Pressed rice triangle with nori seaweed, various fillings (salmon, tuna mayo, umeboshi).',
  NULL, 'sides', 1),

-- Tamagoyaki: rolled egg omelet
('tamagoyaki', 'Tamagoyaki (Egg Roll)', 155, 10.0, 3.5, 10.5,
  0.0, 3.0,
  80, 80,
  'japanese_cuisine', ARRAY['japanese egg roll', 'rolled omelette', 'japanese omelette', 'tamago', 'dashimaki tamago'],
  '~80g per piece. Sweet rolled egg omelet with dashi. Popular bento item and sushi topping.',
  NULL, 'sides', 1),

-- Agedashi Tofu: lightly fried tofu in dashi broth
('agedashi tofu', 'Agedashi Tofu', 115, 7.0, 6.0, 7.0,
  0.5, 1.0,
  NULL, 200,
  'japanese_cuisine', ARRAY['agedashi', 'fried tofu', 'deep fried tofu', 'age tofu', 'agedashi dofu'],
  '~200g per serving. Lightly dusted tofu, deep-fried, served in warm dashi broth with grated daikon.',
  NULL, 'sides', 1),

-- ============================================================================
-- DESSERTS
-- Source: snapcalorie.com, eatthismuch.com, calories-info.com
-- ============================================================================
-- Mochi: rice cake dessert
('mochi', 'Mochi (Rice Cake)', 280, 4.5, 62.0, 1.0,
  0.5, 28.0,
  40, 80,
  'japanese_cuisine', ARRAY['rice cake', 'daifuku', 'mochi dessert', 'japanese mochi', 'daifuku mochi'],
  '~40g per piece, 2-piece serving. Glutinous rice cake, often filled with sweet red bean paste.',
  NULL, 'japanese', 2),

-- Matcha Ice Cream
('matcha ice cream', 'Matcha Ice Cream', 215, 4.0, 26.0, 10.5,
  0.5, 22.0,
  NULL, 100,
  'japanese_cuisine', ARRAY['green tea ice cream', 'matcha gelato', 'green tea gelato', 'matcha soft serve'],
  '~100g per scoop. Creamy ice cream made with matcha green tea powder.',
  NULL, 'japanese', 1),

-- Dorayaki: red bean pancake
('dorayaki', 'Dorayaki (Red Bean Pancake)', 305, 6.0, 56.0, 5.5,
  2.5, 30.0,
  75, 75,
  'japanese_cuisine', ARRAY['red bean pancake', 'japanese pancake', 'dorayaki pancake', 'anko pancake'],
  '~75g per piece. Two fluffy honey pancakes sandwiching sweet red bean (anko) paste.',
  NULL, 'japanese', 1),

-- ============================================================================
-- DRINKS
-- Source: snapcalorie.com, eatthismuch.com, mynetdiary.com
-- ============================================================================
-- Matcha Latte
('matcha latte', 'Matcha Latte', 55, 2.5, 7.5, 1.8,
  0.5, 5.5,
  NULL, 350,
  'japanese_cuisine', ARRAY['green tea latte', 'matcha milk', 'hot matcha latte', 'iced matcha latte'],
  '~350ml per cup. Matcha green tea powder whisked with steamed milk.',
  NULL, 'japanese', 1),

-- Ramune: Japanese marble soda
('ramune', 'Ramune (Japanese Soda)', 38, 0.0, 9.5, 0.0,
  0.0, 9.0,
  NULL, 200,
  'japanese_cuisine', ARRAY['ramune soda', 'japanese soda', 'marble soda', 'japanese lemonade'],
  '~200ml per bottle. Carbonated lemon-lime soda in iconic Codd-neck glass bottle with marble stopper.',
  NULL, 'japanese', 1)

ON CONFLICT (food_name_normalized) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  default_serving_g = EXCLUDED.default_serving_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  restaurant_name = EXCLUDED.restaurant_name,
  food_category = EXCLUDED.food_category,
  default_count = EXCLUDED.default_count,
  updated_at = NOW();
