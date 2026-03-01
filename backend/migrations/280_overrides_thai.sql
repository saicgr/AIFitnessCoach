-- ============================================================================
-- 280_overrides_thai.sql
-- Generated: 2026-02-28
-- Total items: 35
--
-- Thai cuisine nutrition overrides.
-- All values are per 100g of prepared/cooked food.
--
-- Sources: USDA FoodData Central, nutritionvalue.org, fatsecret.com,
--          eatthismuch.com, snapcalorie.com, nutritionix.com, calorieking.com,
--          myfooddiary.com, calories-info.com
--
-- Methodology: Cross-referenced multiple nutrition databases per dish.
-- Serving weights based on typical Thai restaurant portions.
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, food_category, notes
) VALUES

-- ============================================================================
-- CURRIES
-- Base is coconut milk + protein + aromatics. Typically served with rice.
-- Sources: fatsecret.com, eatthismuch.com, snapcalorie.com, myfooddiary.com
-- ============================================================================

-- Green Curry: ~120 cal/100g. Rich coconut milk base with green chili paste.
-- Cross-ref: Sharwood's 104/100g (sauce only), prepared ~120 cal with chicken.
('thai_green_curry', 'Green Curry (Gaeng Khiao Wan)', 118, 7.5, 5.0, 7.8, 0.8, 2.5, NULL, 300, 'thai_cuisine',
 ARRAY['gaeng khiao wan', 'green curry chicken', 'thai green curry', 'green curry with chicken', 'kaeng khiao wan'],
 'curries',
 '~354 cal per 300g serving. Coconut milk, green curry paste, Thai basil, bamboo shoots.'),

-- Red Curry: Slightly hotter than green, similar coconut milk base.
-- Cross-ref: fatsecret ~115 cal/100g, eatthismuch ~125 cal/100g
('thai_red_curry', 'Red Curry (Gaeng Daeng)', 122, 7.8, 5.5, 8.0, 0.7, 2.8, NULL, 300, 'thai_cuisine',
 ARRAY['gaeng daeng', 'red curry chicken', 'thai red curry', 'red curry with chicken', 'kaeng daeng'],
 'curries',
 '~366 cal per 300g serving. Coconut milk, red curry paste, Thai basil, bamboo shoots, bell pepper.'),

-- Massaman Curry: Richer/heavier with potatoes and peanuts.
-- Cross-ref: snapcalorie ~140 cal/100g, eatthismuch 123-171 cal/100g
('thai_massaman_curry', 'Massaman Curry', 140, 8.0, 10.0, 8.2, 1.2, 3.0, NULL, 350, 'thai_cuisine',
 ARRAY['massaman', 'massaman curry chicken', 'massaman curry beef', 'muslim curry', 'gaeng massaman'],
 'curries',
 '~490 cal per 350g serving. Coconut milk, potatoes, peanuts, cinnamon, cardamom, star anise.'),

-- Panang Curry: Thicker than green/red, less brothy, more peanut.
-- Cross-ref: eatthismuch 123-167 cal/100g, myfooddiary ~130 cal/100g
('thai_panang_curry', 'Panang Curry', 132, 8.5, 5.5, 8.8, 0.6, 2.2, NULL, 300, 'thai_cuisine',
 ARRAY['panang', 'phanaeng curry', 'panaeng curry', 'panang curry chicken', 'panang curry beef'],
 'curries',
 '~396 cal per 300g serving. Thick coconut cream, panang paste, kaffir lime leaves, crushed peanuts.'),

-- Yellow Curry: Milder, turmeric-based, often with potatoes.
-- Cross-ref: snapcalorie ~110 cal/100g, similar density to massaman but lighter coconut
('thai_yellow_curry', 'Yellow Curry', 110, 6.5, 8.5, 5.8, 1.0, 3.0, NULL, 300, 'thai_cuisine',
 ARRAY['gaeng karee', 'kaeng kari', 'yellow curry chicken', 'thai yellow curry'],
 'curries',
 '~330 cal per 300g serving. Coconut milk, turmeric, curry powder, potatoes, onions.'),

-- Khao Soi: Northern Thai curry noodle soup, rich coconut broth.
-- Cross-ref: nutritionix ~150 cal/100g, myfooddiary ~145 cal/100g (dense with noodles)
('thai_khao_soi', 'Khao Soi (Curry Noodles)', 148, 8.0, 14.0, 7.0, 0.8, 2.0, NULL, 400, 'thai_cuisine',
 ARRAY['khao soi', 'khao soy', 'chiang mai curry noodles', 'northern thai curry noodles', 'kao soi'],
 'curries',
 '~592 cal per 400g serving. Coconut curry broth, egg noodles, crispy noodle topping, pickled mustard greens.'),

-- ============================================================================
-- NOODLES
-- Sources: calories-info.com, fatsecret.com, snapcalorie.com, nutritionvalue.org
-- ============================================================================

-- Pad Thai: Thailand's signature noodle dish.
-- Cross-ref: calories-info 153/100g, fatsecret ~155/100g, nutritionvalue 153/100g
('thai_pad_thai', 'Pad Thai', 155, 8.0, 22.0, 4.5, 1.0, 5.0, NULL, 350, 'thai_cuisine',
 ARRAY['pad thai', 'phad thai', 'pad thai chicken', 'pad thai shrimp', 'pad thai tofu', 'thai stir fried noodles'],
 'noodles',
 '~543 cal per 350g serving. Rice noodles, tamarind sauce, egg, bean sprouts, peanuts, lime.'),

-- Pad See Ew: Wide rice noodles with dark soy sauce.
-- Cross-ref: fatsecret 173/100g, snapcalorie ~167/100g
('thai_pad_see_ew', 'Pad See Ew', 170, 7.5, 20.0, 6.5, 0.8, 3.5, NULL, 350, 'thai_cuisine',
 ARRAY['pad see ew', 'pad si ew', 'pad si io', 'thai stir fried wide noodles', 'pad see ew chicken'],
 'noodles',
 '~595 cal per 350g serving. Wide rice noodles, dark soy sauce, Chinese broccoli, egg.'),

-- Drunken Noodles (Pad Kee Mao): Spicy wide rice noodles with Thai basil.
-- Cross-ref: snapcalorie ~150/100g, myfooddiary ~155/100g
('thai_drunken_noodles', 'Drunken Noodles (Pad Kee Mao)', 152, 7.0, 19.5, 5.2, 1.0, 2.8, NULL, 350, 'thai_cuisine',
 ARRAY['pad kee mao', 'drunken noodles', 'pad ki mao', 'spicy basil noodles', 'thai drunken noodles'],
 'noodles',
 '~532 cal per 350g serving. Wide rice noodles, Thai basil, chili, garlic, bell peppers.'),

-- Boat Noodles: Rich, savory broth with dark soy and spices.
-- Cross-ref: snapcalorie ~95/100g (broth-heavy), fitia ~293/100g (instant/concentrated)
-- Using restaurant-style bowl values which are broth-heavy
('thai_boat_noodles', 'Boat Noodles (Kuay Teow Rua)', 98, 6.5, 10.0, 3.5, 0.5, 1.5, NULL, 300, 'thai_cuisine',
 ARRAY['boat noodles', 'kuay teow rua', 'guay tiew rua', 'thai boat noodle soup'],
 'noodles',
 '~294 cal per 300g serving. Rich spiced beef/pork broth, thin rice noodles, meatballs, bean sprouts.'),

-- ============================================================================
-- STIR-FRY
-- Sources: snapcalorie.com, arise-app.com, eatthismuch.com
-- ============================================================================

-- Pad Krapow: Thailand's most popular street food stir-fry with holy basil.
-- Cross-ref: snapcalorie ~155/100g (without rice), arise-app ~150/100g
('thai_pad_krapow', 'Pad Krapow (Thai Basil Stir-Fry)', 155, 14.0, 5.5, 8.5, 0.8, 1.5, NULL, 200, 'thai_cuisine',
 ARRAY['pad krapow', 'pad kra pao', 'pad gaprao', 'thai basil chicken', 'thai basil pork', 'holy basil stir fry', 'gai pad krapow', 'pad krapow moo'],
 'thai',
 '~310 cal per 200g serving (without rice). Minced meat, holy basil, chili, garlic, fish sauce. Typically topped with fried egg.'),

-- Cashew Chicken: Stir-fried chicken with roasted cashews.
-- Cross-ref: snapcalorie ~160/100g, eatthismuch ~155-165/100g
('thai_cashew_chicken', 'Cashew Chicken (Gai Pad Med Mamuang)', 162, 12.5, 9.0, 9.0, 1.0, 3.5, NULL, 250, 'thai_cuisine',
 ARRAY['gai pad med mamuang', 'cashew chicken', 'thai cashew chicken', 'gai pad met mamuang himaphan', 'chicken with cashew nuts'],
 'thai',
 '~405 cal per 250g serving. Chicken, roasted cashews, dried chili, onion, bell pepper, oyster sauce.'),

-- Pad Pak Ruam: Mixed vegetable stir-fry, lighter option.
-- Cross-ref: snapcalorie ~65/100g, typical Thai vegetable stir-fry
('thai_pad_pak_ruam', 'Pad Pak Ruam (Mixed Vegetable Stir-Fry)', 68, 2.5, 6.5, 3.8, 2.0, 2.5, NULL, 250, 'thai_cuisine',
 ARRAY['pad pak ruam', 'thai mixed vegetables', 'stir fried vegetables thai', 'pad pak', 'thai vegetable stir fry'],
 'thai',
 '~170 cal per 250g serving. Mixed vegetables, garlic, oyster sauce, soy sauce. Low calorie option.'),

-- ============================================================================
-- SOUPS
-- Sources: fatsecret.com, snapcalorie.com, nutritionix.com, nutritionvalue.org
-- ============================================================================

-- Tom Yum Goong: Hot and sour shrimp soup (clear broth version).
-- Cross-ref: fatsecret ~36/100g (clear), arise-app ~40/100g, nutritionix ~38/100g
('thai_tom_yum_goong', 'Tom Yum Goong (Spicy Shrimp Soup)', 38, 3.5, 3.0, 1.2, 0.3, 1.0, NULL, 350, 'thai_cuisine',
 ARRAY['tom yum goong', 'tom yum kung', 'tom yam goong', 'spicy shrimp soup', 'hot and sour soup thai', 'tom yum'],
 'soups',
 '~133 cal per 350g serving. Clear broth, shrimp, lemongrass, galangal, kaffir lime, chili, mushrooms.'),

-- Tom Kha Gai: Coconut milk-based chicken soup, richer than tom yum.
-- Cross-ref: snapcalorie ~72/100g, myfooddiary ~65/100g, fatsecret ~70/100g
('thai_tom_kha_gai', 'Tom Kha Gai (Coconut Chicken Soup)', 72, 5.0, 4.0, 4.2, 0.3, 1.8, NULL, 350, 'thai_cuisine',
 ARRAY['tom kha gai', 'tom kha kai', 'coconut chicken soup', 'thai coconut soup', 'tom kha'],
 'soups',
 '~252 cal per 350g serving. Coconut milk broth, chicken, galangal, lemongrass, kaffir lime, mushrooms.'),

-- ============================================================================
-- RICE DISHES
-- Sources: fatsecret.com, snapcalorie.com, nutritionix.com
-- ============================================================================

-- Khao Pad: Thai fried rice, lighter than Chinese fried rice.
-- Cross-ref: snapcalorie ~155/100g, sparkpeople ~150/100g
('thai_khao_pad', 'Khao Pad (Thai Fried Rice)', 155, 5.5, 22.0, 5.0, 0.8, 1.5, NULL, 300, 'thai_cuisine',
 ARRAY['khao pad', 'kao pad', 'thai fried rice', 'khao phad', 'fried rice thai'],
 'rice',
 '~465 cal per 300g serving. Jasmine rice, egg, garlic, fish sauce, soy sauce, vegetables, lime.'),

-- Pineapple Fried Rice: Sweet and savory fried rice with pineapple.
-- Cross-ref: snapcalorie ~145/100g, fatsecret ~150/100g
('thai_pineapple_fried_rice', 'Pineapple Fried Rice', 148, 5.0, 23.0, 4.2, 1.0, 4.0, NULL, 350, 'thai_cuisine',
 ARRAY['pineapple fried rice', 'khao pad sapparot', 'thai pineapple fried rice'],
 'rice',
 '~518 cal per 350g serving. Jasmine rice, pineapple chunks, cashews, raisins, curry powder, shrimp.'),

-- Sticky Rice (plain): Glutinous rice, staple of Isaan/Northern Thai cuisine.
-- Cross-ref: fatsecret 97/100g, nutritionix 96/100g, USDA ~98/100g
('thai_sticky_rice', 'Sticky Rice (Khao Niao)', 97, 2.0, 21.0, 0.2, 0.5, 0.0, NULL, 150, 'thai_cuisine',
 ARRAY['khao niao', 'glutinous rice', 'sticky rice', 'thai sticky rice', 'khao niaw'],
 'rice',
 '~146 cal per 150g serving. Steamed glutinous rice, staple side dish for Isaan and Northern Thai food.'),

-- ============================================================================
-- SALADS
-- Sources: fatsecret.com, snapcalorie.com, myfooddiary.com
-- ============================================================================

-- Som Tum: Green papaya salad, iconic Thai street food.
-- Cross-ref: snapcalorie ~80/100g, myfooddiary ~82/100g, fatsecret ~78/100g
('thai_som_tum', 'Som Tum (Green Papaya Salad)', 80, 2.5, 12.0, 2.0, 2.5, 7.0, NULL, 200, 'thai_cuisine',
 ARRAY['som tum', 'som tam', 'papaya salad', 'green papaya salad', 'thai papaya salad', 'somtam'],
 'thai',
 '~160 cal per 200g serving. Shredded green papaya, tomatoes, green beans, peanuts, dried shrimp, lime, chili, fish sauce.'),

-- Larb / Laab: Minced meat salad with fresh herbs, lime, and chili.
-- Cross-ref: fatsecret ~120/100g, snapcalorie ~125/100g, carbmanager ~130/100g
('thai_larb', 'Larb (Thai Meat Salad)', 125, 15.0, 5.0, 5.5, 1.0, 1.5, NULL, 200, 'thai_cuisine',
 ARRAY['larb', 'laab', 'laap', 'larb gai', 'larb moo', 'thai minced meat salad', 'larb chicken', 'larb pork'],
 'thai',
 '~250 cal per 200g serving. Minced meat, lime juice, fish sauce, toasted rice powder, shallots, mint, cilantro, chili.'),

-- Yum Woon Sen: Glass noodle salad with shrimp and pork.
-- Cross-ref: snapcalorie ~105/100g, fatsecret ~110/100g
('thai_yum_woon_sen', 'Yum Woon Sen (Glass Noodle Salad)', 108, 7.5, 12.5, 3.5, 0.5, 2.5, NULL, 250, 'thai_cuisine',
 ARRAY['yum woon sen', 'glass noodle salad', 'thai glass noodle salad', 'yam woon sen', 'mung bean noodle salad'],
 'thai',
 '~270 cal per 250g serving. Glass noodles, shrimp, ground pork, celery, onion, lime, chili, fish sauce.'),

-- ============================================================================
-- APPETIZERS
-- Sources: nutritionix.com, fatsecret.com, eatthismuch.com, calories-info.com
-- ============================================================================

-- Satay: Grilled marinated meat skewers with peanut sauce.
-- Cross-ref: nutritionix ~190/100g (without sauce), snapcalorie ~195/100g
('thai_satay', 'Satay (Grilled Skewers)', 190, 20.0, 5.0, 10.0, 0.5, 3.0, 30, 120, 'thai_cuisine',
 ARRAY['satay', 'chicken satay', 'pork satay', 'satay chicken', 'satay gai', 'satay moo', 'thai satay skewers'],
 'thai',
 '~228 cal per 4-skewer serving (120g). Marinated grilled meat, served with peanut sauce and cucumber relish. ~30g per skewer.'),

-- Thai Spring Rolls (fried): Crispy fried spring rolls.
-- Cross-ref: eatthismuch 140-197/100g, fatsecret ~220/100g (fried), using mid-range
('thai_spring_rolls', 'Thai Spring Rolls (Fried)', 210, 5.5, 24.0, 10.5, 1.5, 2.0, 40, 160, 'thai_cuisine',
 ARRAY['thai spring rolls', 'spring rolls', 'por pia tod', 'fried spring rolls', 'poh pia tod'],
 'thai',
 '~336 cal per 4-piece serving (160g). Fried pastry with glass noodles, vegetables, mushrooms. ~40g per roll.'),

-- Crab Rangoon: Crispy fried wontons with cream cheese and crab.
-- Cross-ref: calories-info 271/100g, eatthismuch 213-341/100g, fatsecret ~260/100g
('thai_crab_rangoon', 'Crab Rangoon', 265, 7.0, 22.0, 16.0, 0.5, 2.0, 25, 125, 'thai_cuisine',
 ARRAY['crab rangoon', 'cream cheese wontons', 'crab wonton', 'crab puffs'],
 'thai',
 '~331 cal per 5-piece serving (125g). Fried wonton wrapper, cream cheese, crab meat. ~25g per piece.'),

-- Tod Mun Pla: Thai fish cakes, aromatic and bouncy.
-- Cross-ref: myfooddiary ~180/100g, snapcalorie ~175/100g, nutritionix ~185/100g
('thai_tod_mun_pla', 'Tod Mun Pla (Thai Fish Cakes)', 180, 14.0, 8.0, 10.0, 0.8, 1.5, 30, 150, 'thai_cuisine',
 ARRAY['tod mun pla', 'tod man pla', 'thai fish cakes', 'fish cake thai', 'tord mun pla'],
 'thai',
 '~270 cal per 5-piece serving (150g). White fish, red curry paste, long beans, kaffir lime leaves, deep fried. ~30g per cake.'),

-- ============================================================================
-- DESSERTS & DRINKS
-- Sources: snapcalorie.com, nutritionix.com, healthline.com, fatsecret.com
-- ============================================================================

-- Mango Sticky Rice: Classic Thai dessert.
-- Cross-ref: snapcalorie ~186/100g, nutritionix ~190/100g, eatthismuch ~200 cal per 200g
('thai_mango_sticky_rice', 'Mango Sticky Rice (Khao Niao Mamuang)', 190, 2.5, 35.0, 5.0, 1.0, 14.0, NULL, 200, 'thai_cuisine',
 ARRAY['mango sticky rice', 'khao niao mamuang', 'mango with sticky rice', 'kao niew mamuang', 'sweet sticky rice with mango'],
 'thai',
 '~380 cal per 200g serving. Glutinous rice, coconut milk, sugar, fresh mango slices.'),

-- Thai Iced Tea: Sweet, creamy, bright orange tea beverage.
-- Cross-ref: healthline 154 cal per 240ml, snapcalorie ~64 cal/100ml, nutritionix ~65 cal/100ml
('thai_iced_tea', 'Thai Iced Tea (Cha Yen)', 65, 1.5, 11.0, 1.8, 0.0, 10.0, NULL, 360, 'thai_cuisine',
 ARRAY['thai iced tea', 'cha yen', 'thai tea', 'thai milk tea', 'cha thai'],
 'thai',
 '~234 cal per 360ml glass. Strong black tea, sweetened condensed milk, evaporated milk, sugar, served over ice.'),

-- Thai Coconut Ice Cream: Creamy coconut-based ice cream.
-- Cross-ref: snapcalorie ~180/100g, typical coconut ice cream ~175-200 cal/100g
('thai_coconut_ice_cream', 'Thai Coconut Ice Cream', 185, 2.0, 22.0, 10.5, 0.5, 18.0, NULL, 120, 'thai_cuisine',
 ARRAY['coconut ice cream', 'thai coconut ice cream', 'ice cream coconut thai', 'itim kati'],
 'thai',
 '~222 cal per 120g serving (1 scoop). Coconut milk, sugar, often topped with peanuts, corn, sticky rice.'),

-- ============================================================================
-- STREET FOOD
-- Sources: snapcalorie.com, nutritionix.com, fatsecret.com
-- ============================================================================

-- Gai Yang: Thai grilled chicken, marinated with garlic and coriander root.
-- Cross-ref: nutritionix ~185/100g (skin-on), snapcalorie ~180/100g, fatsecret ~190/100g
('thai_gai_yang', 'Gai Yang (Thai Grilled Chicken)', 185, 22.0, 2.5, 10.0, 0.0, 1.0, NULL, 250, 'thai_cuisine',
 ARRAY['gai yang', 'kai yang', 'thai grilled chicken', 'thai bbq chicken', 'grilled chicken thai'],
 'thai',
 '~463 cal per 250g half-chicken serving. Marinated with garlic, coriander root, white pepper, lemongrass, fish sauce.'),

-- Moo Ping: Grilled pork skewers, sweet and savory.
-- Cross-ref: nutritionix ~200/100g, snapcalorie ~195/100g
('thai_moo_ping', 'Moo Ping (Grilled Pork Skewers)', 198, 18.0, 6.0, 11.0, 0.2, 4.0, 35, 140, 'thai_cuisine',
 ARRAY['moo ping', 'mu ping', 'grilled pork skewers', 'thai pork skewers', 'thai grilled pork'],
 'thai',
 '~277 cal per 4-skewer serving (140g). Pork marinated in coconut milk, garlic, coriander root, palm sugar. ~35g per skewer.'),

-- Roti: Thai-style pan-fried flatbread, flaky and buttery.
-- Cross-ref: fatsecret ~300/100g (plain), snapcalorie ~310/100g. Thai roti is richer than Indian roti.
('thai_roti', 'Thai Roti', 310, 5.5, 38.0, 15.0, 1.0, 6.0, 80, 80, 'thai_cuisine',
 ARRAY['roti thai', 'thai roti', 'roti canai', 'thai flatbread', 'roti mataba'],
 'thai',
 '~248 cal per piece (80g). Flaky pan-fried flatbread, often served with sweetened condensed milk or with curry.')

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
  food_category = EXCLUDED.food_category,
  notes = EXCLUDED.notes,
  updated_at = NOW();
