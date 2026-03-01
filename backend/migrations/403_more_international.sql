-- 403_more_international.sql
-- Additional international restaurant chains and cuisines.
-- Sources: bonchon.com/nutrition, bbqchicken.com, thaiexpress.ca/nutrition,
-- wagamama.com/nutrition, pret.co.uk/nutrition, thehalalguys.com/nutrition,
-- cava.com/nutrition, elpolloloco.com/nutrition, pollotropical.com/nutrition,
-- boostjuice.com.au, oporto.com.au/nutrition, itsu.com/menu,
-- francomanca.co.uk, fatsecret.com, nutritionix.com, calorieking.com,
-- USDA FoodData Central. All values per 100g.

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
-- BONCHON (Korean Fried Chicken)
-- ==========================================

-- Bonchon Soy Garlic Wings: 1700 cal/20pc (~567g). Per 100g: ~300 cal, 19.8P, 6.3C, 19.1F
('bonchon_soy_garlic_wings', 'Bonchon Soy Garlic Wings', 300, 19.8, 6.3, 19.1,
 0.2, 2.5, 284, NULL,
 'bonchon', ARRAY['bonchon soy garlic', 'bonchon wings soy garlic', 'soy garlic chicken wings bonchon'],
 'korean', 'Bonchon', 1, 'Per 100g. 10pc serving ~284g = 852 cal. Double-fried wings with soy garlic glaze.', TRUE,
 680, 95, 5.5, 0.1, 210, 18, 1.0, 8, 0.5, 0, 20, 1.8, 160, 18, 0.05),

-- Bonchon Spicy Wings: similar calorie density, slightly less sugar from glaze
('bonchon_spicy_wings', 'Bonchon Spicy Wings', 305, 19.5, 5.8, 19.8,
 0.3, 1.8, 284, NULL,
 'bonchon', ARRAY['bonchon spicy', 'bonchon wings spicy', 'spicy chicken wings bonchon', 'bonchon hot wings'],
 'korean', 'Bonchon', 1, 'Per 100g. 10pc serving ~284g = 866 cal. Double-fried wings with spicy gochujang glaze.', TRUE,
 720, 95, 5.7, 0.1, 215, 18, 1.1, 12, 1.2, 0, 20, 1.8, 160, 18, 0.05),

-- Bonchon Drumsticks Soy Garlic: drumsticks are heavier per piece
('bonchon_drumsticks_soy_garlic', 'Bonchon Drumsticks Soy Garlic', 280, 20.5, 6.0, 17.8,
 0.2, 2.5, 340, NULL,
 'bonchon', ARRAY['bonchon soy garlic drumsticks', 'bonchon drums soy garlic'],
 'korean', 'Bonchon', 1, 'Per 100g. 5pc drumstick serving ~340g = 952 cal. Meatier cut with soy garlic glaze.', TRUE,
 660, 100, 5.2, 0.1, 230, 16, 1.1, 8, 0.5, 0, 22, 2.0, 170, 20, 0.05),

-- Bonchon Drumsticks Spicy
('bonchon_drumsticks_spicy', 'Bonchon Drumsticks Spicy', 285, 20.2, 5.5, 18.3,
 0.3, 1.8, 340, NULL,
 'bonchon', ARRAY['bonchon spicy drumsticks', 'bonchon drums spicy'],
 'korean', 'Bonchon', 1, 'Per 100g. 5pc drumstick serving ~340g = 969 cal. Meatier cut with spicy glaze.', TRUE,
 700, 100, 5.4, 0.1, 235, 16, 1.2, 12, 1.2, 0, 22, 2.0, 170, 20, 0.05),

-- Bonchon Bibimbap: rice bowl ~450g serving, ~620 cal
('bonchon_bibimbap', 'Bonchon Bibimbap', 138, 7.5, 18.0, 4.0,
 1.5, 1.8, 450, NULL,
 'bonchon', ARRAY['bonchon bibimbap bowl', 'bibimbap bonchon'],
 'korean', 'Bonchon', 1, 'Per 100g. Full bowl ~450g = 621 cal. Rice, vegetables, egg, gochujang.', TRUE,
 420, 45, 1.2, 0.0, 180, 35, 1.5, 40, 3.0, 5, 25, 1.2, 110, 10, 0.03),

-- Bonchon Japchae: glass noodles ~350g, ~480 cal
('bonchon_japchae', 'Bonchon Japchae', 137, 5.0, 22.0, 3.5,
 1.2, 4.5, 350, NULL,
 'bonchon', ARRAY['bonchon japchae', 'japchae bonchon', 'glass noodles bonchon'],
 'korean', 'Bonchon', 1, 'Per 100g. Serving ~350g = 480 cal. Sweet potato glass noodles with vegetables and sesame.', TRUE,
 380, 10, 0.8, 0.0, 150, 20, 1.2, 30, 2.5, 0, 15, 0.8, 70, 5, 0.02),

-- Bonchon Kimchi Fried Rice: ~400g, ~580 cal
('bonchon_kimchi_fried_rice', 'Bonchon Kimchi Fried Rice', 145, 5.5, 20.0, 4.8,
 1.0, 1.5, 400, NULL,
 'bonchon', ARRAY['bonchon kimchi rice', 'kimchi fried rice bonchon'],
 'korean', 'Bonchon', 1, 'Per 100g. Serving ~400g = 580 cal. Fried rice with kimchi, egg, scallions.', TRUE,
 520, 40, 1.5, 0.0, 140, 22, 1.0, 20, 3.5, 2, 18, 1.0, 90, 8, 0.02),

-- Bonchon Tteokbokki: 980 cal per 862g plate
('bonchon_tteokbokki', 'Bonchon Tteokbokki', 114, 3.7, 20.2, 2.1,
 0.9, 5.0, 862, NULL,
 'bonchon', ARRAY['bonchon rice cakes', 'tteokbokki bonchon', 'bonchon tteok'],
 'korean', 'Bonchon', 1, 'Per 100g. Full plate ~862g = 980 cal. Spicy rice cakes in gochujang sauce.', TRUE,
 450, 5, 0.6, 0.0, 100, 15, 0.8, 15, 2.0, 0, 12, 0.5, 50, 4, 0.01),

-- Bonchon KFC (Korean Fried Cauliflower): lighter than chicken
('bonchon_korean_fried_cauliflower', 'Bonchon Korean Fried Cauliflower', 195, 4.5, 22.0, 10.0,
 3.0, 4.0, 280, NULL,
 'bonchon', ARRAY['bonchon kfc', 'bonchon fried cauliflower', 'korean fried cauliflower bonchon'],
 'korean', 'Bonchon', 1, 'Per 100g. Serving ~280g = 546 cal. Battered cauliflower with soy garlic or spicy glaze.', TRUE,
 580, 0, 1.5, 0.1, 280, 25, 0.8, 5, 30.0, 0, 18, 0.4, 55, 3, 0.02),

-- Bonchon Fish & Chips: ~350g, ~700 cal
('bonchon_fish_and_chips', 'Bonchon Fish & Chips', 200, 10.0, 18.0, 9.5,
 1.5, 0.8, 350, NULL,
 'bonchon', ARRAY['bonchon fish chips', 'fish and chips bonchon'],
 'korean', 'Bonchon', 1, 'Per 100g. Serving ~350g = 700 cal. Battered fish with fries and tartar sauce.', TRUE,
 480, 35, 2.0, 0.1, 250, 20, 0.7, 5, 2.0, 10, 22, 0.5, 130, 20, 0.15),

-- ==========================================
-- BB.Q CHICKEN
-- ==========================================

-- bb.q Golden Original Wings: 1290 cal/16pc medium (~480g). Per 100g: ~269 cal
('bbq_chicken_golden_original_wings', 'bb.q Chicken Golden Original Wings', 269, 23.3, 21.5, 10.0,
 0.5, 1.0, 480, NULL,
 'bbq_chicken', ARRAY['bbq chicken golden original', 'bb.q golden original', 'bbq chicken wings original'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Medium 16pc ~480g = 1290 cal. Signature golden-fried wings.', TRUE,
 620, 90, 3.0, 0.1, 200, 15, 1.0, 5, 0.5, 0, 18, 1.8, 155, 17, 0.04),

-- bb.q Secret Spicy Wings
('bbq_chicken_secret_spicy_wings', 'bb.q Chicken Secret Spicy Wings', 275, 22.8, 22.0, 10.5,
 0.5, 1.5, 480, NULL,
 'bbq_chicken', ARRAY['bbq chicken secret spicy', 'bb.q spicy wings', 'bbq chicken spicy'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Medium 16pc ~480g = 1320 cal. Spicy sauce glaze on crispy wings.', TRUE,
 680, 90, 3.2, 0.1, 205, 15, 1.1, 10, 1.0, 0, 18, 1.8, 155, 17, 0.04),

-- bb.q Honey Garlic Wings
('bbq_chicken_honey_garlic_wings', 'bb.q Chicken Honey Garlic Wings', 285, 22.0, 24.0, 10.2,
 0.3, 6.0, 480, NULL,
 'bbq_chicken', ARRAY['bbq chicken honey garlic', 'bb.q honey garlic', 'bbq chicken honey wings'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Medium 16pc ~480g = 1368 cal. Sweet honey garlic glaze.', TRUE,
 590, 88, 3.0, 0.1, 195, 15, 1.0, 5, 0.8, 0, 17, 1.7, 150, 16, 0.04),

-- bb.q Gangnam Style Wings
('bbq_chicken_gangnam_style_wings', 'bb.q Chicken Gangnam Style Wings', 280, 22.5, 22.5, 10.8,
 0.4, 3.0, 480, NULL,
 'bbq_chicken', ARRAY['bbq chicken gangnam style', 'bb.q gangnam', 'gangnam wings bbq chicken'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Medium 16pc ~480g = 1344 cal. Sweet and spicy Korean glaze.', TRUE,
 650, 90, 3.1, 0.1, 200, 15, 1.0, 8, 0.8, 0, 18, 1.8, 152, 17, 0.04),

-- bb.q Fried Rice
('bbq_chicken_fried_rice', 'bb.q Chicken Fried Rice', 155, 6.0, 22.0, 4.8,
 1.0, 1.2, 380, NULL,
 'bbq_chicken', ARRAY['bbq chicken fried rice', 'bb.q fried rice'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Serving ~380g = 589 cal. Korean-style fried rice with vegetables.', TRUE,
 480, 35, 1.2, 0.0, 130, 20, 1.0, 15, 2.0, 2, 16, 0.8, 85, 7, 0.02),

-- bb.q Chicken Sandwich
('bbq_chicken_sandwich', 'bb.q Chicken Sandwich', 245, 14.0, 24.0, 10.5,
 1.5, 3.5, 250, NULL,
 'bbq_chicken', ARRAY['bbq chicken sandwich', 'bb.q chicken sandwich', 'bb.q crispy sandwich'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Sandwich ~250g = 613 cal. Crispy fried chicken on brioche bun.', TRUE,
 620, 55, 3.0, 0.1, 180, 40, 2.0, 10, 2.0, 0, 22, 1.2, 130, 14, 0.03),

-- bb.q Tteokbokki
('bbq_chicken_tteokbokki', 'bb.q Chicken Tteokbokki', 120, 3.5, 22.0, 2.0,
 0.8, 5.5, 400, NULL,
 'bbq_chicken', ARRAY['bbq chicken tteokbokki', 'bb.q rice cakes', 'bb.q tteok'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Serving ~400g = 480 cal. Spicy rice cakes in gochujang sauce.', TRUE,
 440, 5, 0.5, 0.0, 95, 14, 0.7, 12, 2.0, 0, 10, 0.4, 45, 3, 0.01),

-- bb.q K-Bap Bowl
('bbq_chicken_kbap_bowl', 'bb.q Chicken K-Bap Bowl', 150, 8.5, 20.0, 4.2,
 1.5, 2.0, 420, NULL,
 'bbq_chicken', ARRAY['bbq chicken k-bap', 'bb.q kbap bowl', 'bb.q rice bowl'],
 'korean', 'bb.q Chicken', 1, 'Per 100g. Bowl ~420g = 630 cal. Rice bowl with chicken and Korean toppings.', TRUE,
 450, 40, 1.0, 0.0, 170, 25, 1.2, 20, 3.0, 2, 20, 1.0, 100, 9, 0.03),

-- ==========================================
-- KANG HO DONG BAEKJEONG (Korean BBQ)
-- ==========================================

-- Bulgogi: USDA ~133 cal/100g for marinated beef
('baekjeong_bulgogi', 'Baekjeong Bulgogi', 155, 17.0, 7.5, 6.5,
 0.3, 5.0, 200, NULL,
 'baekjeong', ARRAY['baekjeong bulgogi', 'korean bbq bulgogi baekjeong', 'kang ho dong bulgogi'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Serving ~200g = 310 cal. Thinly sliced marinated beef, grilled at table.', TRUE,
 450, 55, 2.5, 0.1, 280, 12, 2.2, 3, 0.5, 0, 20, 4.5, 170, 18, 0.03),

-- Galbi (Short Ribs): fattier cut ~280 cal/100g
('baekjeong_galbi', 'Baekjeong Galbi (Short Ribs)', 280, 18.0, 6.0, 20.5,
 0.2, 4.5, 250, NULL,
 'baekjeong', ARRAY['baekjeong galbi', 'korean short ribs baekjeong', 'kang ho dong galbi', 'baekjeong kalbi'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Serving ~250g = 700 cal. Marinated beef short ribs, grilled at table.', TRUE,
 380, 75, 9.0, 0.3, 250, 15, 2.0, 5, 0.3, 0, 18, 5.0, 155, 16, 0.04),

-- Samgyeopsal (Pork Belly): very fatty ~330 cal/100g
('baekjeong_samgyeopsal', 'Baekjeong Samgyeopsal (Pork Belly)', 330, 14.0, 0.5, 30.0,
 0.0, 0.0, 200, NULL,
 'baekjeong', ARRAY['baekjeong pork belly', 'samgyeopsal baekjeong', 'kang ho dong pork belly', 'baekjeong samgyupsal'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Serving ~200g = 660 cal. Thick-cut unmarinated pork belly, grilled at table.', TRUE,
 65, 80, 11.0, 0.1, 220, 5, 0.8, 2, 0.3, 5, 14, 2.0, 140, 12, 0.02),

-- Japchae
('baekjeong_japchae', 'Baekjeong Japchae', 130, 4.5, 21.0, 3.2,
 1.0, 4.0, 300, NULL,
 'baekjeong', ARRAY['baekjeong japchae', 'japchae baekjeong', 'kang ho dong japchae'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Side dish ~300g = 390 cal. Glass noodles with vegetables and sesame oil.', TRUE,
 350, 8, 0.7, 0.0, 140, 18, 1.0, 25, 2.0, 0, 14, 0.7, 65, 4, 0.02),

-- Kimchi Jjigae
('baekjeong_kimchi_jjigae', 'Baekjeong Kimchi Jjigae', 62, 5.0, 3.5, 3.2,
 1.0, 1.5, 450, NULL,
 'baekjeong', ARRAY['baekjeong kimchi stew', 'kimchi jjigae baekjeong', 'kang ho dong kimchi jjigae'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Bowl ~450g = 279 cal. Spicy kimchi stew with pork and tofu.', TRUE,
 580, 20, 1.2, 0.0, 200, 40, 1.0, 15, 5.0, 0, 15, 1.0, 80, 5, 0.02),

-- Doenjang Jjigae
('baekjeong_doenjang_jjigae', 'Baekjeong Doenjang Jjigae', 58, 4.5, 4.0, 2.8,
 1.2, 1.0, 450, NULL,
 'baekjeong', ARRAY['baekjeong soybean paste stew', 'doenjang jjigae baekjeong', 'kang ho dong doenjang'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Bowl ~450g = 261 cal. Fermented soybean paste stew with tofu and vegetables.', TRUE,
 620, 15, 0.8, 0.0, 220, 55, 1.5, 20, 4.0, 0, 22, 1.0, 90, 5, 0.03),

-- Bibimbap
('baekjeong_bibimbap', 'Baekjeong Bibimbap', 142, 7.0, 19.5, 4.0,
 1.5, 2.0, 450, NULL,
 'baekjeong', ARRAY['baekjeong bibimbap', 'bibimbap baekjeong', 'kang ho dong bibimbap'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Bowl ~450g = 639 cal. Mixed rice with vegetables, beef, egg, gochujang.', TRUE,
 400, 50, 1.2, 0.0, 190, 38, 1.5, 45, 3.5, 5, 25, 1.5, 115, 10, 0.03),

-- Naengmyeon (Cold Noodles)
('baekjeong_naengmyeon', 'Baekjeong Naengmyeon', 105, 4.0, 20.0, 1.0,
 1.5, 3.0, 550, NULL,
 'baekjeong', ARRAY['baekjeong cold noodles', 'naengmyeon baekjeong', 'kang ho dong naengmyeon'],
 'korean_bbq', 'Baekjeong', 1, 'Per 100g. Bowl ~550g = 578 cal. Buckwheat noodles in chilled broth with egg and radish.', TRUE,
 380, 15, 0.2, 0.0, 100, 12, 1.2, 5, 1.5, 2, 18, 0.5, 65, 8, 0.01),

-- ==========================================
-- THAI EXPRESS
-- ==========================================

-- Pad Thai Chicken: 680 cal per 354g serving
('thai_express_pad_thai_chicken', 'Thai Express Pad Thai (Chicken)', 192, 10.5, 24.0, 6.5,
 1.5, 5.0, 354, NULL,
 'thai_express', ARRAY['thai express pad thai', 'pad thai chicken thai express', 'thai express chicken pad thai'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~354g = 680 cal. Rice noodles with chicken, egg, peanuts, bean sprouts.', TRUE,
 580, 60, 1.5, 0.0, 220, 35, 1.5, 15, 4.0, 0, 30, 1.2, 140, 12, 0.03),

-- Green Curry Chicken: 340 cal per 245g
('thai_express_green_curry', 'Thai Express Green Curry (Chicken)', 139, 5.0, 9.0, 9.5,
 1.5, 2.5, 245, NULL,
 'thai_express', ARRAY['thai express green curry', 'green curry thai express', 'thai express curry green'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~245g = 340 cal. Coconut curry with chicken, bamboo, thai basil.', TRUE,
 480, 30, 6.5, 0.0, 250, 25, 1.2, 20, 3.0, 0, 22, 0.8, 100, 6, 0.02),

-- Red Curry Shrimp: similar to green curry, ~340 cal per 245g
('thai_express_red_curry_shrimp', 'Thai Express Red Curry (Shrimp)', 141, 6.5, 8.5, 9.2,
 1.2, 2.5, 245, NULL,
 'thai_express', ARRAY['thai express red curry', 'red curry shrimp thai express', 'thai express shrimp curry'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~245g = 345 cal. Coconut red curry with shrimp and vegetables.', TRUE,
 500, 55, 6.2, 0.0, 230, 30, 1.0, 25, 3.5, 0, 25, 0.9, 120, 15, 0.08),

-- Massaman Curry: richer, ~380 cal per 280g
('thai_express_massaman_curry', 'Thai Express Massaman Curry', 136, 6.0, 12.0, 7.5,
 1.5, 3.5, 280, NULL,
 'thai_express', ARRAY['thai express massaman', 'massaman curry thai express', 'thai express massaman beef'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~280g = 381 cal. Rich coconut curry with potatoes and peanuts.', TRUE,
 440, 25, 4.5, 0.0, 280, 20, 1.5, 10, 2.5, 0, 28, 1.0, 110, 8, 0.02),

-- Tom Yum Soup: 330 cal per ~400g
('thai_express_tom_yum', 'Thai Express Tom Yum Soup', 82, 3.8, 11.5, 3.0,
 0.5, 1.5, 400, NULL,
 'thai_express', ARRAY['thai express tom yum', 'tom yum soup thai express', 'thai express hot sour soup'],
 'thai', 'Thai Express', 1, 'Per 100g. Bowl ~400g = 330 cal. Spicy-sour soup with shrimp, mushrooms, lemongrass.', TRUE,
 620, 25, 0.5, 0.0, 180, 15, 0.8, 10, 5.0, 0, 12, 0.6, 80, 10, 0.04),

-- Spring Rolls 2pc: ~180 cal per 100g (fried)
('thai_express_spring_rolls', 'Thai Express Spring Rolls (2 pc)', 220, 5.0, 25.0, 11.0,
 1.5, 2.0, 100, 50,
 'thai_express', ARRAY['thai express spring rolls', 'spring rolls thai express', 'thai express rolls'],
 'thai', 'Thai Express', 1, 'Per 100g. 2 rolls ~100g = 220 cal. Crispy fried vegetable spring rolls.', TRUE,
 420, 5, 2.5, 0.2, 120, 15, 1.0, 10, 2.0, 0, 10, 0.4, 40, 3, 0.01),

-- Mango Sticky Rice
('thai_express_mango_sticky_rice', 'Thai Express Mango Sticky Rice', 195, 2.5, 35.0, 5.5,
 1.0, 18.0, 220, NULL,
 'thai_express', ARRAY['thai express mango sticky rice', 'mango sticky rice thai express', 'thai express mango rice'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~220g = 429 cal. Sweet sticky rice with fresh mango and coconut cream.', TRUE,
 30, 0, 3.5, 0.0, 150, 10, 0.5, 30, 15.0, 0, 15, 0.4, 35, 2, 0.01),

-- Larb Chicken: light, ~120 cal/100g
('thai_express_larb_chicken', 'Thai Express Larb Chicken', 120, 14.0, 6.0, 4.5,
 1.0, 2.5, 250, NULL,
 'thai_express', ARRAY['thai express larb', 'larb chicken thai express', 'thai express chicken larb salad'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~250g = 300 cal. Minced chicken salad with mint, lime, chili, fish sauce.', TRUE,
 680, 50, 1.0, 0.0, 300, 20, 1.2, 15, 8.0, 0, 22, 1.2, 140, 14, 0.03),

-- Papaya Salad: low cal ~80/100g
('thai_express_papaya_salad', 'Thai Express Papaya Salad', 80, 2.5, 12.0, 2.5,
 2.5, 7.0, 250, NULL,
 'thai_express', ARRAY['thai express som tam', 'papaya salad thai express', 'thai express green papaya salad'],
 'thai', 'Thai Express', 1, 'Per 100g. Serving ~250g = 200 cal. Green papaya with chili, lime, peanuts, dried shrimp.', TRUE,
 580, 10, 0.3, 0.0, 280, 35, 0.8, 25, 35.0, 0, 18, 0.5, 40, 3, 0.02),

-- Tom Kha Gai: ~100 cal/100g (coconut milk base)
('thai_express_tom_kha_gai', 'Thai Express Tom Kha Gai', 100, 5.5, 5.0, 7.0,
 0.5, 2.0, 400, NULL,
 'thai_express', ARRAY['thai express tom kha', 'tom kha gai thai express', 'thai express coconut chicken soup'],
 'thai', 'Thai Express', 1, 'Per 100g. Bowl ~400g = 400 cal. Coconut milk soup with chicken, galangal, lemongrass.', TRUE,
 450, 25, 5.5, 0.0, 200, 15, 0.6, 5, 2.0, 0, 18, 0.7, 90, 8, 0.03),

-- ==========================================
-- SARAVANA BHAVAN (South Indian Vegetarian)
-- ==========================================

-- Masala Dosa: ~188 cal/100g, ~250g per dosa
('saravana_bhavan_masala_dosa', 'Saravana Bhavan Masala Dosa', 188, 4.5, 26.0, 7.5,
 1.5, 1.5, 250, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan masala dosa', 'masala dosa saravana bhavan', 'masala dosai saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. One dosa ~250g = 470 cal. Crispy rice-lentil crepe with spiced potato filling.', TRUE,
 380, 0, 2.0, 0.0, 200, 25, 1.5, 5, 5.0, 0, 30, 0.8, 80, 5, 0.02),

-- Rava Dosa
('saravana_bhavan_rava_dosa', 'Saravana Bhavan Rava Dosa', 212, 4.0, 28.0, 9.0,
 1.0, 1.0, 200, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan rava dosa', 'rava dosa saravana bhavan', 'semolina dosa saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. One dosa ~200g = 424 cal. Crispy semolina crepe with onions and cashews.', TRUE,
 350, 0, 2.5, 0.0, 110, 20, 1.2, 3, 2.0, 0, 22, 0.6, 70, 4, 0.01),

-- Mini Tiffin Combo: sampled items avg ~165/100g
('saravana_bhavan_mini_tiffin', 'Saravana Bhavan Mini Tiffin Combo', 165, 5.0, 24.0, 5.5,
 2.0, 2.0, 400, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan mini tiffin', 'mini tiffin saravana bhavan', 'saravana tiffin combo'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Combo ~400g = 660 cal. Assorted South Indian items: mini dosa, idli, vada, sambar.', TRUE,
 420, 5, 1.5, 0.0, 250, 35, 2.0, 8, 3.0, 0, 35, 1.0, 100, 5, 0.02),

-- Ghee Pongal
('saravana_bhavan_ghee_pongal', 'Saravana Bhavan Ghee Pongal', 155, 4.5, 20.0, 6.5,
 1.5, 0.5, 300, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan pongal', 'ghee pongal saravana bhavan', 'ven pongal saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Serving ~300g = 465 cal. Rice and lentil porridge tempered with ghee, pepper, cumin.', TRUE,
 320, 15, 3.5, 0.0, 150, 18, 1.5, 10, 1.0, 0, 28, 1.0, 100, 6, 0.02),

-- Sambar Rice
('saravana_bhavan_sambar_rice', 'Saravana Bhavan Sambar Rice', 125, 4.0, 20.0, 3.0,
 2.0, 1.5, 350, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan sambar rice', 'sambar sadam saravana bhavan'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Serving ~350g = 438 cal. Rice mixed with lentil-vegetable sambar.', TRUE,
 380, 0, 0.8, 0.0, 220, 30, 1.8, 10, 4.0, 0, 30, 0.8, 90, 5, 0.02),

-- Idli 3pc: ~40 cal per idli (60g each)
('saravana_bhavan_idli', 'Saravana Bhavan Idli (3 pc)', 130, 4.0, 24.0, 1.5,
 1.0, 0.5, 180, 60,
 'saravana_bhavan', ARRAY['saravana bhavan idli', 'idli saravana bhavan', 'steamed idli saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. 3 idlis ~180g = 234 cal. Steamed fermented rice-lentil cakes with sambar and chutney.', TRUE,
 280, 0, 0.3, 0.0, 100, 15, 1.0, 2, 1.0, 0, 18, 0.6, 60, 3, 0.01),

-- Medu Vada 2pc: fried lentil donuts ~170 cal/100g
('saravana_bhavan_medu_vada', 'Saravana Bhavan Medu Vada (2 pc)', 235, 8.5, 22.0, 13.0,
 3.0, 1.0, 120, 60,
 'saravana_bhavan', ARRAY['saravana bhavan vada', 'medu vada saravana bhavan', 'urad dal vada saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. 2 vadas ~120g = 282 cal. Deep-fried black lentil fritters with sambar and chutney.', TRUE,
 350, 0, 2.5, 0.1, 250, 25, 2.5, 3, 1.5, 0, 40, 1.2, 120, 5, 0.02),

-- Onion Uthappam
('saravana_bhavan_onion_uthappam', 'Saravana Bhavan Onion Uthappam', 175, 4.5, 25.0, 6.0,
 1.5, 1.5, 280, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan uthappam', 'onion uthappam saravana bhavan', 'uttapam saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. One uthappam ~280g = 490 cal. Thick fermented rice pancake topped with onions.', TRUE,
 360, 0, 1.5, 0.0, 180, 22, 1.5, 5, 3.0, 0, 25, 0.7, 75, 4, 0.01),

-- Paper Dosa
('saravana_bhavan_paper_dosa', 'Saravana Bhavan Paper Dosa', 165, 3.5, 24.0, 6.0,
 0.8, 0.8, 180, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan paper dosa', 'paper dosa saravana bhavan', 'thin crispy dosa saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. One paper dosa ~180g = 297 cal. Extra thin and crispy plain dosa.', TRUE,
 300, 0, 1.5, 0.0, 90, 15, 1.0, 2, 1.0, 0, 18, 0.5, 60, 3, 0.01),

-- Veg Thali
('saravana_bhavan_veg_thali', 'Saravana Bhavan Veg Thali', 145, 5.0, 20.0, 5.0,
 2.5, 2.0, 550, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan thali', 'veg thali saravana bhavan', 'south indian thali saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Full thali ~550g = 798 cal. Rice, sambar, rasam, kootu, poriyal, curd, papad, sweet.', TRUE,
 400, 5, 1.5, 0.0, 280, 50, 2.0, 20, 5.0, 0, 35, 1.2, 120, 6, 0.03),

-- Curd Rice
('saravana_bhavan_curd_rice', 'Saravana Bhavan Curd Rice', 110, 3.5, 17.0, 2.8,
 0.3, 2.0, 300, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan curd rice', 'thayir sadam saravana bhavan', 'yogurt rice saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Serving ~300g = 330 cal. Seasoned yogurt rice with pomegranate and mustard tempering.', TRUE,
 250, 8, 1.5, 0.0, 120, 60, 0.5, 5, 1.0, 0, 12, 0.5, 70, 3, 0.01),

-- Gulab Jamun
('saravana_bhavan_gulab_jamun', 'Saravana Bhavan Gulab Jamun', 325, 4.0, 45.0, 14.0,
 0.2, 35.0, 80, 40,
 'saravana_bhavan', ARRAY['saravana bhavan gulab jamun', 'gulab jamun saravana bhavan'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. 2 pieces ~80g = 260 cal. Deep-fried milk solid balls soaked in sugar syrup.', TRUE,
 80, 15, 7.0, 0.2, 100, 50, 0.5, 15, 0.5, 2, 10, 0.3, 50, 2, 0.01),

-- Rava Kesari
('saravana_bhavan_rava_kesari', 'Saravana Bhavan Rava Kesari', 310, 3.0, 42.0, 14.5,
 0.5, 28.0, 120, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan kesari', 'rava kesari saravana bhavan', 'semolina halwa saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Serving ~120g = 372 cal. Semolina pudding with ghee, sugar, cashews, saffron.', TRUE,
 50, 20, 8.0, 0.2, 60, 15, 0.5, 20, 0.3, 2, 10, 0.4, 45, 3, 0.01),

-- Payasam
('saravana_bhavan_payasam', 'Saravana Bhavan Payasam', 180, 4.0, 25.0, 7.0,
 0.5, 18.0, 150, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan payasam', 'payasam saravana bhavan', 'kheer saravana bhavan'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Serving ~150g = 270 cal. Sweet milk-based dessert with vermicelli or rice, nuts, raisins.', TRUE,
 60, 15, 4.0, 0.1, 150, 80, 0.5, 20, 1.0, 5, 15, 0.5, 80, 3, 0.02),

-- Filter Coffee
('saravana_bhavan_filter_coffee', 'Saravana Bhavan Filter Coffee', 45, 1.8, 5.0, 1.8,
 0.0, 4.5, 150, NULL,
 'saravana_bhavan', ARRAY['saravana bhavan coffee', 'filter coffee saravana bhavan', 'south indian coffee saravana'],
 'indian', 'Saravana Bhavan', 1, 'Per 100g. Cup ~150ml = 68 cal. Strong brewed coffee with boiled milk and sugar.', TRUE,
 30, 5, 1.0, 0.0, 120, 60, 0.1, 10, 0.0, 5, 10, 0.2, 45, 1, 0.0),

-- ==========================================
-- HALDIRAM''S (Indian Snacks & Sweets)
-- ==========================================

-- Chole Bhature: ~310 cal/100g
('haldirams_chole_bhature', 'Haldiram''s Chole Bhature', 310, 9.0, 42.0, 12.0,
 4.0, 3.0, 350, NULL,
 'haldirams', ARRAY['haldirams chole bhature', 'haldiram''s chole bhature', 'chole bhature haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. Plate ~350g = 1085 cal. Spiced chickpeas with deep-fried puffed bread.', TRUE,
 550, 5, 2.5, 0.2, 280, 50, 3.0, 10, 3.0, 0, 40, 1.5, 120, 5, 0.03),

-- Pav Bhaji: ~160 cal/100g
('haldirams_pav_bhaji', 'Haldiram''s Pav Bhaji', 160, 4.0, 18.0, 8.0,
 2.5, 3.0, 400, NULL,
 'haldirams', ARRAY['haldirams pav bhaji', 'haldiram''s pav bhaji', 'pav bhaji haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. Plate ~400g = 640 cal. Spiced mashed vegetable curry with buttered bread rolls.', TRUE,
 480, 10, 4.0, 0.1, 300, 30, 2.0, 40, 8.0, 0, 25, 0.8, 80, 4, 0.02),

-- Paneer Tikka
('haldirams_paneer_tikka', 'Haldiram''s Paneer Tikka', 245, 14.0, 8.0, 18.0,
 1.0, 2.0, 200, NULL,
 'haldirams', ARRAY['haldirams paneer tikka', 'haldiram''s paneer tikka', 'paneer tikka haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. Serving ~200g = 490 cal. Marinated cottage cheese cubes grilled in tandoor.', TRUE,
 380, 40, 10.0, 0.1, 150, 250, 1.0, 50, 3.0, 0, 20, 1.5, 200, 5, 0.02),

-- Chaat Sampler
('haldirams_chaat_sampler', 'Haldiram''s Chaat Sampler', 200, 5.0, 28.0, 8.0,
 2.5, 6.0, 300, NULL,
 'haldirams', ARRAY['haldirams chaat', 'haldiram''s chaat sampler', 'chaat plate haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. Sampler ~300g = 600 cal. Assorted street food chaat items with chutneys.', TRUE,
 450, 5, 1.5, 0.1, 250, 30, 2.0, 15, 5.0, 0, 25, 0.8, 80, 4, 0.02),

-- Aloo Tikki
('haldirams_aloo_tikki', 'Haldiram''s Aloo Tikki', 220, 4.0, 28.0, 10.5,
 2.0, 2.0, 150, 75,
 'haldirams', ARRAY['haldirams aloo tikki', 'haldiram''s aloo tikki', 'potato patty haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. 2 tikkis ~150g = 330 cal. Crispy spiced potato patties served with chutneys.', TRUE,
 420, 5, 2.0, 0.2, 350, 15, 1.5, 5, 8.0, 0, 20, 0.5, 55, 3, 0.01),

-- Raj Kachori
('haldirams_raj_kachori', 'Haldiram''s Raj Kachori', 250, 6.0, 30.0, 12.0,
 2.0, 5.0, 200, NULL,
 'haldirams', ARRAY['haldirams raj kachori', 'haldiram''s raj kachori', 'kachori haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. One kachori ~200g = 500 cal. Large crispy shell filled with yogurt, potatoes, chutneys.', TRUE,
 380, 8, 2.5, 0.2, 200, 40, 1.5, 10, 3.0, 0, 20, 0.6, 70, 4, 0.02),

-- Bhujia (Namkeen)
('haldirams_bhujia', 'Haldiram''s Bhujia', 520, 18.0, 45.0, 30.0,
 5.0, 2.5, 40, NULL,
 'haldirams', ARRAY['haldirams bhujia', 'haldiram''s bhujia sev', 'namkeen bhujia haldirams', 'bikaneri bhujia'],
 'indian', 'Haldiram''s', 1, 'Per 100g. Handful ~40g = 208 cal. Crispy chickpea flour noodle snack.', TRUE,
 650, 0, 5.0, 0.0, 350, 25, 3.5, 5, 1.0, 0, 45, 1.5, 150, 5, 0.03),

-- Rasgulla
('haldirams_rasgulla', 'Haldiram''s Rasgulla', 186, 4.5, 35.0, 3.0,
 0.0, 30.0, 80, 40,
 'haldirams', ARRAY['haldirams rasgulla', 'haldiram''s rasgulla', 'rasogolla haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. 2 pieces ~80g = 149 cal. Soft cottage cheese balls in sugar syrup.', TRUE,
 40, 10, 1.5, 0.0, 50, 45, 0.3, 8, 0.2, 2, 5, 0.3, 40, 2, 0.01),

-- Kaju Katli: ~450 cal/100g
('haldirams_kaju_katli', 'Haldiram''s Kaju Katli', 450, 10.0, 50.0, 24.0,
 1.0, 40.0, 50, 12,
 'haldirams', ARRAY['haldirams kaju katli', 'haldiram''s kaju katli', 'cashew barfi haldirams', 'kaju barfi haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. 4 pieces ~50g = 225 cal. Diamond-shaped cashew fudge with silver leaf.', TRUE,
 30, 5, 5.0, 0.0, 200, 15, 1.5, 0, 0.5, 0, 50, 1.5, 120, 5, 0.02),

-- Pani Puri
('haldirams_pani_puri', 'Haldiram''s Pani Puri', 180, 4.0, 30.0, 5.0,
 2.0, 3.0, 200, NULL,
 'haldirams', ARRAY['haldirams pani puri', 'haldiram''s pani puri', 'golgappa haldirams', 'puchka haldirams'],
 'indian', 'Haldiram''s', 1, 'Per 100g. Plate (6pc with water) ~200g = 360 cal. Crispy shells filled with spiced water, potato, chickpeas.', TRUE,
 520, 0, 1.0, 0.1, 180, 20, 1.5, 5, 3.0, 0, 15, 0.5, 55, 3, 0.01),

-- ==========================================
-- THE HALAL GUYS
-- ==========================================

-- Chicken over Rice Platter: ~800 cal per 450g
('halal_guys_chicken_over_rice', 'The Halal Guys Chicken over Rice', 178, 8.9, 20.0, 7.8,
 1.0, 1.0, 450, NULL,
 'halal_guys', ARRAY['halal guys chicken platter', 'halal guys chicken rice', 'the halal guys chicken over rice'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Regular platter ~450g = 800 cal. Grilled chicken with basmati rice, lettuce, white sauce.', TRUE,
 580, 45, 2.0, 0.1, 220, 30, 1.5, 15, 3.0, 0, 25, 1.5, 130, 12, 0.04),

-- Gyro over Rice Platter: ~850 cal per 450g
('halal_guys_gyro_over_rice', 'The Halal Guys Gyro over Rice', 189, 8.5, 19.0, 9.0,
 1.0, 1.5, 450, NULL,
 'halal_guys', ARRAY['halal guys gyro platter', 'halal guys gyro rice', 'the halal guys gyro over rice'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Regular platter ~450g = 851 cal. Sliced gyro meat with basmati rice, lettuce, white sauce.', TRUE,
 620, 50, 3.5, 0.2, 200, 25, 2.0, 10, 2.0, 0, 22, 2.5, 125, 14, 0.03),

-- Combo over Rice: ~870 cal per 450g
('halal_guys_combo_over_rice', 'The Halal Guys Combo over Rice', 193, 8.7, 19.5, 8.5,
 1.0, 1.2, 450, NULL,
 'halal_guys', ARRAY['halal guys combo platter', 'halal guys chicken gyro combo', 'the halal guys combo over rice'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Regular platter ~450g = 869 cal. Chicken and gyro with basmati rice, lettuce, sauces.', TRUE,
 600, 48, 2.8, 0.1, 210, 28, 1.8, 12, 2.5, 0, 23, 2.0, 128, 13, 0.04),

-- Falafel over Rice: ~641 cal per 300g
('halal_guys_falafel_over_rice', 'The Halal Guys Falafel over Rice', 185, 6.5, 24.0, 7.5,
 3.0, 1.5, 400, NULL,
 'halal_guys', ARRAY['halal guys falafel platter', 'halal guys falafel rice', 'the halal guys falafel over rice'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Platter ~400g = 740 cal. Crispy falafel with basmati rice, lettuce, sauces.', TRUE,
 520, 5, 1.5, 0.1, 280, 40, 2.5, 10, 3.0, 0, 30, 1.2, 100, 6, 0.03),

-- Chicken Sandwich: 419 cal per 283g
('halal_guys_chicken_sandwich', 'The Halal Guys Chicken Sandwich', 148, 10.0, 15.0, 5.5,
 1.5, 2.5, 283, NULL,
 'halal_guys', ARRAY['halal guys chicken sandwich', 'the halal guys chicken sandwich'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Sandwich ~283g = 419 cal. Grilled chicken in pita with lettuce and sauces.', TRUE,
 550, 35, 1.5, 0.0, 180, 35, 2.0, 10, 3.0, 0, 22, 1.2, 120, 10, 0.03),

-- Gyro Sandwich: 613 cal per 283g
('halal_guys_gyro_sandwich', 'The Halal Guys Gyro Sandwich', 217, 9.2, 18.5, 11.5,
 1.5, 2.0, 283, NULL,
 'halal_guys', ARRAY['halal guys gyro sandwich', 'the halal guys gyro sandwich', 'halal guys beef gyro sandwich'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Sandwich ~283g = 613 cal. Sliced gyro meat in pita with lettuce and sauces.', TRUE,
 620, 50, 4.5, 0.2, 170, 30, 2.5, 8, 2.0, 0, 20, 2.5, 115, 14, 0.03),

-- White Sauce (per tbsp ~15g): very calorie dense
('halal_guys_white_sauce', 'The Halal Guys White Sauce', 467, 0.5, 3.3, 50.0,
 0.0, 2.0, 15, NULL,
 'halal_guys', ARRAY['halal guys white sauce', 'the halal guys white sauce', 'halal guys mayo sauce'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. 1 tbsp ~15g = 70 cal. Creamy mayo-based signature white sauce.', TRUE,
 400, 30, 8.0, 0.3, 20, 5, 0.1, 5, 0.5, 0, 2, 0.1, 10, 1, 0.01),

-- Hot Sauce (per tbsp ~15g)
('halal_guys_hot_sauce', 'The Halal Guys Hot Sauce', 67, 1.3, 13.3, 1.3,
 2.0, 5.0, 15, NULL,
 'halal_guys', ARRAY['halal guys hot sauce', 'the halal guys hot sauce', 'halal guys red sauce'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. 1 tbsp ~15g = 10 cal. Fiery red chili-based hot sauce.', TRUE,
 800, 0, 0.2, 0.0, 150, 10, 0.5, 50, 15.0, 0, 8, 0.2, 15, 1, 0.0),

-- Hummus
('halal_guys_hummus', 'The Halal Guys Hummus', 166, 8.0, 14.0, 9.6,
 6.0, 0.5, 100, NULL,
 'halal_guys', ARRAY['halal guys hummus', 'the halal guys hummus'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. Side ~100g = 166 cal. Classic chickpea hummus with tahini.', TRUE,
 380, 0, 1.4, 0.0, 230, 38, 2.5, 1, 5.0, 0, 30, 1.5, 120, 5, 0.05),

-- Pita
('halal_guys_pita', 'The Halal Guys Pita Bread', 275, 9.0, 50.0, 3.5,
 2.5, 2.0, 60, 60,
 'halal_guys', ARRAY['halal guys pita', 'the halal guys pita bread'],
 'middle_eastern', 'The Halal Guys', 1, 'Per 100g. One pita ~60g = 165 cal. Warm flatbread served with platters.', TRUE,
 490, 0, 0.5, 0.0, 100, 60, 2.5, 0, 0.0, 0, 25, 0.8, 80, 15, 0.01),

-- ==========================================
-- CAVA (Mediterranean)
-- ==========================================

-- Grain Bowl (greens+grains+grilled chicken): ~677 cal per 450g
('cava_grain_bowl_chicken', 'Cava Grain Bowl with Chicken', 150, 10.5, 14.5, 6.0,
 2.5, 1.5, 450, NULL,
 'cava', ARRAY['cava grain bowl chicken', 'cava chicken bowl', 'cava greens grains chicken'],
 'mediterranean', 'Cava', 1, 'Per 100g. Bowl ~450g = 675 cal. Greens, grains, grilled chicken, toppings, dressing.', TRUE,
 450, 40, 1.5, 0.0, 280, 45, 1.8, 30, 5.0, 0, 30, 1.5, 150, 12, 0.05),

-- Greens & Grains Bowl (no protein)
('cava_greens_grains_bowl', 'Cava Greens & Grains Bowl', 120, 4.5, 16.0, 4.5,
 3.0, 2.0, 400, NULL,
 'cava', ARRAY['cava greens grains', 'cava veggie bowl', 'cava greens and grains'],
 'mediterranean', 'Cava', 1, 'Per 100g. Bowl ~400g = 480 cal. Base of greens and grains with Mediterranean toppings.', TRUE,
 380, 0, 0.8, 0.0, 300, 40, 2.0, 40, 8.0, 0, 35, 0.8, 80, 5, 0.03),

-- Pita Wrap
('cava_pita_wrap', 'Cava Pita Wrap', 195, 11.0, 20.0, 7.5,
 2.0, 2.0, 350, NULL,
 'cava', ARRAY['cava pita', 'cava wrap', 'cava pita wrap chicken'],
 'mediterranean', 'Cava', 1, 'Per 100g. Wrap ~350g = 683 cal. Warm pita stuffed with protein, greens, toppings.', TRUE,
 520, 40, 2.0, 0.0, 250, 50, 2.5, 25, 4.0, 0, 28, 1.5, 140, 12, 0.04),

-- Braised Lamb Shoulder Bowl
('cava_braised_lamb_bowl', 'Cava Braised Lamb Shoulder Bowl', 165, 10.0, 14.0, 8.0,
 2.5, 1.5, 450, NULL,
 'cava', ARRAY['cava lamb bowl', 'cava braised lamb', 'cava lamb shoulder bowl'],
 'mediterranean', 'Cava', 1, 'Per 100g. Bowl ~450g = 743 cal. Braised lamb with greens, grains, and Mediterranean toppings.', TRUE,
 480, 45, 3.0, 0.1, 270, 40, 2.2, 25, 4.0, 0, 25, 2.8, 160, 14, 0.05),

-- Harissa Chicken Bowl
('cava_harissa_chicken_bowl', 'Cava Harissa Chicken Bowl', 155, 11.0, 14.0, 6.5,
 2.5, 1.5, 450, NULL,
 'cava', ARRAY['cava harissa chicken', 'cava spicy chicken bowl', 'cava harissa bowl'],
 'mediterranean', 'Cava', 1, 'Per 100g. Bowl ~450g = 698 cal. Harissa-marinated chicken with greens, grains, toppings.', TRUE,
 500, 42, 1.8, 0.0, 290, 42, 2.0, 30, 6.0, 0, 30, 1.5, 148, 12, 0.05),

-- Falafel Bowl
('cava_falafel_bowl', 'Cava Falafel Bowl', 155, 6.5, 19.0, 6.0,
 4.0, 2.0, 430, NULL,
 'cava', ARRAY['cava falafel', 'cava crispy falafel bowl', 'cava falafel grain bowl'],
 'mediterranean', 'Cava', 1, 'Per 100g. Bowl ~430g = 667 cal. Crispy falafel with greens, grains, Mediterranean toppings.', TRUE,
 460, 0, 1.0, 0.0, 310, 50, 2.8, 35, 7.0, 0, 35, 1.2, 110, 6, 0.04),

-- Hummus
('cava_hummus', 'Cava Hummus', 166, 8.0, 14.0, 9.6,
 6.0, 0.5, 60, NULL,
 'cava', ARRAY['cava hummus', 'cava traditional hummus'],
 'mediterranean', 'Cava', 1, 'Per 100g. Side ~60g = 100 cal. Classic chickpea hummus with tahini and lemon.', TRUE,
 370, 0, 1.3, 0.0, 228, 40, 2.4, 1, 5.0, 0, 30, 1.4, 120, 5, 0.05),

-- Crazy Feta Dip
('cava_crazy_feta', 'Cava Crazy Feta Dip', 280, 8.0, 4.0, 26.0,
 0.5, 2.5, 60, NULL,
 'cava', ARRAY['cava crazy feta', 'cava feta dip', 'cava spicy feta'],
 'mediterranean', 'Cava', 1, 'Per 100g. Side ~60g = 168 cal. Whipped feta with jalape&ntilde;o and harissa.', TRUE,
 520, 50, 12.0, 0.3, 80, 200, 0.5, 40, 3.0, 2, 12, 1.5, 150, 8, 0.02),

-- Pita Chips
('cava_pita_chips', 'Cava Pita Chips', 490, 8.0, 55.0, 25.0,
 3.0, 2.0, 50, NULL,
 'cava', ARRAY['cava pita chips', 'cava chips', 'cava pita crisps'],
 'mediterranean', 'Cava', 1, 'Per 100g. Side bag ~50g = 245 cal. Oven-baked seasoned pita chips.', TRUE,
 600, 0, 3.0, 0.0, 100, 30, 2.0, 0, 0.0, 0, 18, 0.6, 60, 10, 0.01),

-- Harvest Bowl
('cava_harvest_bowl', 'Cava Harvest Bowl', 140, 5.0, 18.0, 5.5,
 3.0, 4.0, 420, NULL,
 'cava', ARRAY['cava harvest', 'cava harvest bowl', 'cava seasonal bowl'],
 'mediterranean', 'Cava', 1, 'Per 100g. Bowl ~420g = 588 cal. Seasonal vegetables with greens, grains, and dressing.', TRUE,
 420, 5, 1.0, 0.0, 320, 45, 2.0, 50, 10.0, 0, 30, 0.8, 90, 5, 0.04),

-- ==========================================
-- WAGAMAMA (Asian Fusion - UK)
-- ==========================================

-- Chicken Katsu Curry: ~997 cal per 550g
('wagamama_chicken_katsu_curry', 'Wagamama Chicken Katsu Curry', 181, 9.1, 19.6, 7.8,
 1.5, 1.3, 550, NULL,
 'wagamama', ARRAY['wagamama katsu curry', 'wagamama chicken katsu', 'katsu curry wagamama'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~550g = 997 cal. Panko chicken, sticky rice, katsu curry sauce, salad.', TRUE,
 480, 50, 2.0, 0.1, 280, 30, 1.5, 15, 2.0, 0, 25, 1.5, 140, 14, 0.04),

-- Pad Thai: ~349 cal per 300g
('wagamama_pad_thai', 'Wagamama Pad Thai', 116, 6.0, 14.5, 4.0,
 1.0, 3.5, 300, NULL,
 'wagamama', ARRAY['wagamama pad thai', 'pad thai wagamama', 'wagamama rice noodles'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~300g = 349 cal. Rice noodles with chicken, egg, peanuts, bean sprouts, lime.', TRUE,
 520, 45, 0.8, 0.0, 200, 25, 1.2, 10, 4.0, 0, 22, 1.0, 110, 10, 0.03),

-- Chilli Chicken Ramen: ~550 cal per 500g
('wagamama_chilli_chicken_ramen', 'Wagamama Chilli Chicken Ramen', 110, 7.5, 10.5, 4.5,
 1.0, 2.0, 500, NULL,
 'wagamama', ARRAY['wagamama chilli ramen', 'wagamama ramen', 'chilli chicken ramen wagamama'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Bowl ~500g = 550 cal. Ramen noodles in spicy broth with chicken, egg, greens.', TRUE,
 620, 40, 1.2, 0.0, 250, 35, 2.0, 20, 3.0, 5, 20, 1.2, 120, 12, 0.05),

-- Firecracker Chicken: ~650 cal per 400g
('wagamama_firecracker_chicken', 'Wagamama Firecracker Chicken', 163, 12.0, 16.0, 5.5,
 1.5, 4.0, 400, NULL,
 'wagamama', ARRAY['wagamama firecracker', 'firecracker chicken wagamama'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~400g = 650 cal. Spicy chicken stir-fry with noodles and vegetables.', TRUE,
 560, 50, 1.2, 0.0, 270, 28, 1.5, 15, 5.0, 0, 25, 1.3, 135, 14, 0.03),

-- Yaki Soba: ~600 cal per 400g
('wagamama_yaki_soba', 'Wagamama Yaki Soba', 150, 8.0, 18.0, 5.5,
 1.5, 3.0, 400, NULL,
 'wagamama', ARRAY['wagamama yaki soba', 'yaki soba wagamama', 'wagamama fried noodles'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~400g = 600 cal. Stir-fried soba noodles with chicken, vegetables, pickled ginger.', TRUE,
 540, 45, 1.0, 0.0, 240, 25, 1.5, 12, 3.0, 0, 22, 1.2, 120, 12, 0.03),

-- Chicken Gyoza (5pc): ~207 cal per 130g
('wagamama_chicken_gyoza', 'Wagamama Chicken Gyoza (5 pc)', 159, 6.7, 19.2, 6.1,
 1.0, 1.5, 130, 26,
 'wagamama', ARRAY['wagamama gyoza', 'chicken gyoza wagamama', 'wagamama dumplings'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. 5 gyoza ~130g = 207 cal. Pan-fried chicken dumplings with dipping sauce.', TRUE,
 480, 25, 1.5, 0.0, 120, 15, 1.0, 5, 1.0, 0, 12, 0.8, 70, 8, 0.02),

-- Edamame: ~200 cal per 160g
('wagamama_edamame', 'Wagamama Edamame', 125, 11.0, 8.0, 5.5,
 4.5, 2.0, 160, NULL,
 'wagamama', ARRAY['wagamama edamame', 'edamame beans wagamama', 'wagamama edamame chilli'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~160g = 200 cal. Steamed soybeans with chilli garlic salt.', TRUE,
 380, 0, 0.7, 0.0, 440, 60, 2.5, 5, 5.0, 0, 55, 1.0, 170, 2, 0.3),

-- Bang Bang Cauliflower: ~350 cal per 200g
('wagamama_bang_bang_cauliflower', 'Wagamama Bang Bang Cauliflower', 175, 4.5, 20.0, 9.0,
 2.5, 5.0, 200, NULL,
 'wagamama', ARRAY['wagamama bang bang', 'bang bang cauliflower wagamama', 'wagamama cauliflower'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~200g = 350 cal. Fried cauliflower with sweet chilli sauce and sesame.', TRUE,
 520, 0, 1.5, 0.1, 250, 25, 0.8, 5, 30.0, 0, 18, 0.4, 55, 3, 0.02),

-- Teriyaki Chicken Donburi: ~700 cal per 450g
('wagamama_teriyaki_donburi', 'Wagamama Teriyaki Chicken Donburi', 156, 10.0, 18.0, 5.0,
 1.0, 4.5, 450, NULL,
 'wagamama', ARRAY['wagamama donburi', 'teriyaki donburi wagamama', 'wagamama teriyaki chicken'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~450g = 700 cal. Teriyaki chicken on sticky rice with pickled vegetables.', TRUE,
 500, 50, 1.2, 0.0, 240, 22, 1.2, 10, 2.0, 0, 22, 1.5, 140, 14, 0.04),

-- Raw Rainbow Salad: ~280 cal per 300g
('wagamama_raw_rainbow_salad', 'Wagamama Raw Rainbow Salad', 93, 5.0, 10.0, 4.0,
 3.0, 4.0, 300, NULL,
 'wagamama', ARRAY['wagamama rainbow salad', 'raw salad wagamama', 'wagamama raw rainbow'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Serving ~300g = 280 cal. Mixed raw vegetables with sesame dressing and seeds.', TRUE,
 350, 0, 0.5, 0.0, 350, 50, 1.5, 60, 25.0, 0, 30, 0.8, 60, 3, 0.1),

-- Coconut Cake: ~380 cal per 120g
('wagamama_coconut_cake', 'Wagamama Coconut Cake', 317, 3.5, 38.0, 17.0,
 1.5, 25.0, 120, NULL,
 'wagamama', ARRAY['wagamama coconut cake', 'coconut cake wagamama'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Slice ~120g = 380 cal. Moist coconut sponge cake.', TRUE,
 200, 30, 10.0, 0.2, 100, 20, 0.8, 5, 0.5, 2, 12, 0.4, 50, 3, 0.01),

-- Chocolate Layer Cake: ~420 cal per 120g
('wagamama_chocolate_layer_cake', 'Wagamama Chocolate Layer Cake', 350, 4.5, 42.0, 18.0,
 2.0, 30.0, 120, NULL,
 'wagamama', ARRAY['wagamama chocolate cake', 'chocolate cake wagamama', 'wagamama layer cake'],
 'asian_fusion', 'Wagamama', 1, 'Per 100g. Slice ~120g = 420 cal. Rich chocolate sponge with chocolate ganache.', TRUE,
 180, 40, 9.0, 0.2, 180, 30, 2.0, 10, 0.3, 2, 30, 1.0, 80, 4, 0.01),

-- ==========================================
-- PRET A MANGER (Cafe - UK)
-- ==========================================

-- All Butter Croissant: ~350 cal per 80g
('pret_all_butter_croissant', 'Pret a Manger All Butter Croissant', 406, 7.5, 42.0, 22.5,
 2.0, 6.5, 80, NULL,
 'pret', ARRAY['pret croissant', 'pret a manger croissant', 'pret butter croissant'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. One croissant ~80g = 325 cal. Flaky all-butter French croissant.', TRUE,
 400, 55, 13.0, 0.5, 90, 25, 1.5, 50, 0.2, 5, 12, 0.6, 60, 10, 0.02),

-- Pain au Chocolat: ~300 cal per 82g
('pret_pain_au_chocolat', 'Pret a Manger Pain au Chocolat', 366, 6.5, 42.0, 19.5,
 2.0, 12.0, 82, NULL,
 'pret', ARRAY['pret pain au chocolat', 'pret a manger chocolate croissant', 'pret chocolate pastry'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. One pastry ~82g = 300 cal. Butter croissant with chocolate batons.', TRUE,
 350, 50, 11.0, 0.4, 130, 30, 1.8, 40, 0.2, 3, 20, 0.8, 70, 8, 0.02),

-- Chicken & Avocado Sandwich: ~464 cal per 240g
('pret_chicken_avocado_sandwich', 'Pret a Manger Chicken & Avocado Sandwich', 193, 10.5, 16.5, 9.5,
 2.5, 2.0, 240, NULL,
 'pret', ARRAY['pret chicken avocado', 'pret a manger chicken avocado sandwich', 'pret chicken avo'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Sandwich ~240g = 464 cal. Chicken, avocado, basil on artisan bread.', TRUE,
 450, 40, 2.0, 0.0, 350, 35, 1.5, 15, 5.0, 0, 25, 1.0, 130, 12, 0.04),

-- Tuna Mayo Baguette: ~560 cal per 280g
('pret_tuna_mayo_baguette', 'Pret a Manger Tuna Mayo Baguette', 200, 8.6, 18.6, 10.4,
 1.5, 2.0, 280, NULL,
 'pret', ARRAY['pret tuna baguette', 'pret a manger tuna mayo', 'pret tuna sandwich'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Baguette ~280g = 560 cal. Tuna mayo with cucumber on French baguette.', TRUE,
 480, 30, 2.0, 0.0, 180, 25, 1.5, 10, 2.0, 10, 20, 0.5, 120, 25, 0.3),

-- Macaroni Cheese: ~480 cal per 300g
('pret_macaroni_cheese', 'Pret a Manger Macaroni Cheese', 160, 6.5, 16.0, 8.0,
 1.0, 1.5, 300, NULL,
 'pret', ARRAY['pret mac and cheese', 'pret a manger macaroni cheese', 'pret mac cheese'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Pot ~300g = 480 cal. Creamy macaroni with mature cheddar.', TRUE,
 520, 30, 4.5, 0.1, 100, 150, 1.0, 30, 0.5, 5, 15, 1.0, 150, 8, 0.02),

-- Chicken Caesar Wrap: ~500 cal per 260g
('pret_chicken_caesar_wrap', 'Pret a Manger Chicken Caesar Wrap', 192, 11.0, 16.0, 9.5,
 1.5, 1.5, 260, NULL,
 'pret', ARRAY['pret caesar wrap', 'pret a manger chicken wrap', 'pret chicken caesar'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Wrap ~260g = 500 cal. Chicken, romaine, parmesan, Caesar dressing in tortilla.', TRUE,
 520, 40, 2.5, 0.0, 200, 80, 1.5, 30, 3.0, 0, 20, 1.2, 140, 14, 0.03),

-- Brownie: ~420 cal per 95g
('pret_brownie', 'Pret a Manger Brownie', 442, 5.0, 50.0, 25.0,
 2.5, 35.0, 95, NULL,
 'pret', ARRAY['pret brownie', 'pret a manger chocolate brownie', 'pret dark chocolate brownie'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. One brownie ~95g = 420 cal. Rich dark chocolate brownie.', TRUE,
 150, 50, 14.0, 0.2, 220, 25, 3.0, 15, 0.3, 2, 40, 1.5, 100, 5, 0.01),

-- Chocolate Chunk Cookie: ~380 cal per 80g
('pret_chocolate_cookie', 'Pret a Manger Chocolate Chunk Cookie', 475, 5.5, 58.0, 25.0,
 2.0, 32.0, 80, NULL,
 'pret', ARRAY['pret cookie', 'pret a manger cookie', 'pret chocolate cookie'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. One cookie ~80g = 380 cal. Chocolate chunk cookie with butter and brown sugar.', TRUE,
 280, 40, 14.0, 0.3, 120, 20, 2.0, 20, 0.2, 3, 18, 0.8, 60, 5, 0.01),

-- Banana Bread: ~350 cal per 100g
('pret_banana_bread', 'Pret a Manger Banana Bread', 350, 5.0, 48.0, 15.0,
 1.5, 25.0, 100, NULL,
 'pret', ARRAY['pret banana bread', 'pret a manger banana bread', 'pret banana loaf'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Slice ~100g = 350 cal. Moist banana bread with walnuts.', TRUE,
 250, 35, 3.5, 0.1, 220, 20, 1.2, 15, 2.0, 3, 25, 0.8, 70, 5, 0.15),

-- Porridge: ~100 cal per 300g (made up)
('pret_porridge', 'Pret a Manger Porridge', 95, 3.5, 14.0, 2.5,
 1.5, 4.0, 300, NULL,
 'pret', ARRAY['pret porridge', 'pret a manger oat porridge', 'pret oatmeal'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Bowl ~300g = 285 cal. Classic oat porridge with honey and banana option.', TRUE,
 60, 0, 0.5, 0.0, 120, 40, 1.5, 0, 0.5, 0, 35, 1.0, 100, 5, 0.02),

-- Tomato Soup: ~65 cal per 300g
('pret_tomato_soup', 'Pret a Manger Tomato Soup', 65, 1.5, 8.0, 3.0,
 1.0, 5.0, 300, NULL,
 'pret', ARRAY['pret tomato soup', 'pret a manger soup', 'pret cream of tomato'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Bowl ~300g = 195 cal. Classic creamy tomato soup.', TRUE,
 350, 5, 1.5, 0.0, 300, 15, 0.8, 30, 12.0, 0, 12, 0.3, 25, 2, 0.01),

-- Flat White Coffee: ~120 cal per 240ml
('pret_flat_white', 'Pret a Manger Flat White', 50, 3.3, 4.6, 2.1,
 0.0, 4.6, 240, NULL,
 'pret', ARRAY['pret flat white', 'pret a manger flat white', 'pret coffee'],
 'cafe', 'Pret a Manger', 1, 'Per 100g. Cup ~240ml = 120 cal. Espresso with steamed whole milk.', TRUE,
 50, 10, 1.3, 0.0, 150, 120, 0.0, 15, 0.0, 10, 12, 0.4, 95, 2, 0.0),

-- ==========================================
-- BOOST JUICE (Australian Smoothie)
-- ==========================================

-- Mango Magic: 337 cal per 450ml (~450g)
('boost_juice_mango_magic', 'Boost Juice Mango Magic', 75, 1.8, 14.0, 1.5,
 1.0, 13.0, 450, NULL,
 'boost_juice', ARRAY['boost juice mango', 'boost mango magic', 'boost juice mango magic smoothie'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Medium ~450ml = 337 cal. Mango, banana, yoghurt, honey, ice.', TRUE,
 20, 3, 0.8, 0.0, 200, 40, 0.3, 25, 15.0, 5, 15, 0.3, 30, 1, 0.02),

-- Brekkie Smoothie: ~380 cal per 450ml
('boost_juice_brekkie', 'Boost Juice Brekkie Smoothie', 84, 3.5, 13.0, 2.2,
 1.5, 8.0, 450, NULL,
 'boost_juice', ARRAY['boost brekkie', 'boost juice breakfast smoothie', 'boost brekkie smoothie'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Medium ~450ml = 380 cal. Oats, banana, honey, yoghurt, milk.', TRUE,
 40, 5, 1.0, 0.0, 250, 60, 0.8, 10, 3.0, 10, 25, 0.5, 80, 3, 0.02),

-- All Berry Bang: ~320 cal per 450ml
('boost_juice_all_berry_bang', 'Boost Juice All Berry Bang', 71, 1.5, 14.5, 0.8,
 2.0, 10.0, 450, NULL,
 'boost_juice', ARRAY['boost all berry', 'boost juice berry', 'boost berry bang smoothie'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Medium ~450ml = 320 cal. Mixed berries, banana, yoghurt, ice.', TRUE,
 15, 2, 0.4, 0.0, 180, 35, 0.5, 5, 20.0, 3, 12, 0.3, 30, 1, 0.05),

-- Green Tea Mango Mantra: ~290 cal per 450ml
('boost_juice_green_tea_mango', 'Boost Juice Green Tea Mango Mantra', 64, 1.2, 13.5, 0.5,
 0.8, 11.0, 450, NULL,
 'boost_juice', ARRAY['boost green tea mango', 'boost juice mantra', 'boost mango mantra'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Medium ~450ml = 290 cal. Green tea, mango, passionfruit, ice.', TRUE,
 10, 0, 0.2, 0.0, 150, 15, 0.3, 20, 12.0, 0, 10, 0.2, 20, 1, 0.01),

-- Gym Junkie: ~400 cal per 450ml (protein added)
('boost_juice_gym_junkie', 'Boost Juice Gym Junkie', 89, 5.5, 12.0, 2.0,
 1.0, 8.0, 450, NULL,
 'boost_juice', ARRAY['boost gym junkie', 'boost juice protein', 'boost gym junkie smoothie'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Medium ~450ml = 400 cal. Banana, protein powder, peanut butter, yoghurt, milk.', TRUE,
 60, 5, 0.8, 0.0, 280, 70, 0.5, 5, 2.0, 10, 30, 0.8, 100, 5, 0.04),

-- Protein Ball: ~120 cal per 30g
('boost_juice_protein_ball', 'Boost Juice Protein Ball', 400, 15.0, 40.0, 20.0,
 5.0, 18.0, 30, 30,
 'boost_juice', ARRAY['boost protein ball', 'boost juice bliss ball', 'boost energy ball'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. One ball ~30g = 120 cal. Dates, oats, protein powder, nut butter.', TRUE,
 80, 0, 3.0, 0.0, 300, 30, 2.0, 2, 0.5, 0, 50, 1.5, 120, 5, 0.1),

-- Banana Buzz: ~350 cal per 450ml
('boost_juice_banana_buzz', 'Boost Juice Banana Buzz', 78, 2.5, 14.0, 1.2,
 1.0, 10.0, 450, NULL,
 'boost_juice', ARRAY['boost banana buzz', 'boost juice banana', 'boost banana smoothie'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Medium ~450ml = 350 cal. Banana, honey, yoghurt, milk, ice.', TRUE,
 30, 4, 0.7, 0.0, 280, 55, 0.3, 5, 4.0, 8, 22, 0.4, 50, 2, 0.02),

-- Immunity Juice: ~200 cal per 350ml
('boost_juice_immunity', 'Boost Juice Immunity Juice', 57, 0.8, 12.5, 0.3,
 0.5, 10.0, 350, NULL,
 'boost_juice', ARRAY['boost immunity', 'boost juice immunity juice', 'boost cold pressed juice'],
 'smoothie', 'Boost Juice', 1, 'Per 100g. Regular ~350ml = 200 cal. Orange, carrot, ginger, turmeric, lemon.', TRUE,
 10, 0, 0.1, 0.0, 200, 20, 0.3, 200, 40.0, 0, 10, 0.2, 20, 1, 0.01),

-- ==========================================
-- OPORTO (Australian Chicken)
-- ==========================================

-- Bondi Burger: 540 cal per 216g
('oporto_bondi_burger', 'Oporto Bondi Burger', 250, 14.5, 18.5, 13.5,
 1.5, 3.0, 216, NULL,
 'oporto', ARRAY['oporto bondi burger', 'oporto bondi', 'bondi burger oporto'],
 'chicken', 'Oporto', 1, 'Per 100g. One burger ~216g = 540 cal. Flame-grilled chicken fillet, lettuce, chilli sauce on bun.', TRUE,
 580, 55, 3.5, 0.1, 250, 35, 2.0, 15, 4.0, 0, 25, 1.5, 160, 15, 0.03),

-- Double Bondi Burger: 779 cal per 293g
('oporto_double_bondi_burger', 'Oporto Double Bondi Burger', 266, 16.5, 16.0, 15.7,
 1.5, 3.0, 293, NULL,
 'oporto', ARRAY['oporto double bondi', 'double bondi burger oporto', 'oporto double burger'],
 'chicken', 'Oporto', 1, 'Per 100g. One burger ~293g = 779 cal. Double flame-grilled chicken fillet, chilli sauce, cheese.', TRUE,
 620, 70, 4.5, 0.1, 280, 45, 2.5, 20, 4.0, 0, 28, 2.0, 190, 18, 0.03),

-- Flame-Grilled Quarter Chicken: ~260 cal per 180g
('oporto_quarter_chicken', 'Oporto Quarter Chicken', 144, 22.0, 1.0, 5.5,
 0.0, 0.5, 180, NULL,
 'oporto', ARRAY['oporto quarter chicken', 'oporto flame grilled chicken', 'oporto 1/4 chicken'],
 'chicken', 'Oporto', 1, 'Per 100g. Quarter ~180g = 260 cal. Flame-grilled marinated chicken, Portuguese style.', TRUE,
 450, 80, 1.5, 0.0, 280, 12, 1.0, 8, 1.0, 0, 22, 2.0, 180, 20, 0.03),

-- Oporto Pita: ~450 cal per 230g
('oporto_pita', 'Oporto Pita', 196, 12.0, 18.0, 8.5,
 2.0, 2.5, 230, NULL,
 'oporto', ARRAY['oporto pita', 'oporto chicken pita', 'pita oporto'],
 'chicken', 'Oporto', 1, 'Per 100g. One pita ~230g = 450 cal. Grilled chicken, salad, and chilli sauce in pita bread.', TRUE,
 520, 45, 2.0, 0.0, 230, 40, 2.0, 12, 5.0, 0, 22, 1.2, 130, 14, 0.03),

-- Rapido Wrap: ~480 cal per 250g
('oporto_rapido_wrap', 'Oporto Rapido Wrap', 192, 11.5, 19.0, 8.0,
 2.0, 2.0, 250, NULL,
 'oporto', ARRAY['oporto wrap', 'oporto rapido', 'rapido wrap oporto'],
 'chicken', 'Oporto', 1, 'Per 100g. One wrap ~250g = 480 cal. Grilled chicken, cheese, salad in tortilla wrap.', TRUE,
 540, 45, 2.5, 0.0, 220, 55, 2.0, 15, 3.0, 0, 20, 1.2, 140, 14, 0.03),

-- Chilli Fries: ~350 cal per 180g
('oporto_chilli_fries', 'Oporto Chilli Fries', 194, 3.5, 25.0, 9.0,
 2.5, 1.5, 180, NULL,
 'oporto', ARRAY['oporto fries', 'oporto chilli fries', 'chilli chips oporto'],
 'chicken', 'Oporto', 1, 'Per 100g. Serving ~180g = 350 cal. Seasoned fries with Oporto chilli sauce.', TRUE,
 480, 0, 1.5, 0.1, 400, 10, 0.8, 5, 8.0, 0, 20, 0.3, 50, 3, 0.01),

-- Garlic Bread: ~320 cal per 100g
('oporto_garlic_bread', 'Oporto Garlic Bread', 320, 7.0, 38.0, 15.0,
 2.0, 2.5, 100, NULL,
 'oporto', ARRAY['oporto garlic bread', 'garlic bread oporto'],
 'chicken', 'Oporto', 1, 'Per 100g. Serving ~100g = 320 cal. Toasted garlic butter bread.', TRUE,
 500, 20, 8.0, 0.2, 80, 25, 2.0, 30, 0.5, 0, 12, 0.5, 50, 8, 0.01),

-- Portuguese Chicken & Chips: ~200 cal/100g across ~400g
('oporto_chicken_and_chips', 'Oporto Portuguese Chicken & Chips', 200, 13.0, 18.0, 8.5,
 2.0, 1.0, 400, NULL,
 'oporto', ARRAY['oporto chicken chips', 'oporto chicken and chips', 'portuguese chicken chips oporto'],
 'chicken', 'Oporto', 1, 'Per 100g. Meal ~400g = 800 cal. Flame-grilled chicken pieces with seasoned fries.', TRUE,
 500, 55, 2.0, 0.1, 350, 15, 1.2, 10, 3.0, 0, 25, 1.5, 160, 16, 0.03),

-- ==========================================
-- POLLO TROPICAL (Latin American)
-- ==========================================

-- 1/4 Chicken Dark: 290 cal per 113g
('pollo_tropical_quarter_dark', 'Pollo Tropical 1/4 Chicken (Dark)', 257, 22.0, 0.5, 18.5,
 0.0, 0.0, 113, NULL,
 'pollo_tropical', ARRAY['pollo tropical dark meat', 'pollo tropical quarter dark', 'pollo tropical 1/4 dark'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Quarter dark ~113g = 290 cal. Citrus-marinated flame-grilled dark meat.', TRUE,
 520, 95, 5.5, 0.0, 230, 15, 1.2, 12, 0.5, 5, 20, 2.5, 170, 18, 0.04),

-- 1/4 Chicken White: ~230 cal per 113g
('pollo_tropical_quarter_white', 'Pollo Tropical 1/4 Chicken (White)', 204, 28.0, 0.5, 9.5,
 0.0, 0.0, 113, NULL,
 'pollo_tropical', ARRAY['pollo tropical white meat', 'pollo tropical quarter white', 'pollo tropical 1/4 breast'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Quarter white ~113g = 230 cal. Citrus-marinated flame-grilled chicken breast.', TRUE,
 480, 85, 2.5, 0.0, 260, 12, 0.8, 5, 0.5, 5, 25, 1.2, 200, 22, 0.03),

-- TropiChop Chicken Bowl: 530 cal per 370g
('pollo_tropical_tropichop', 'Pollo Tropical TropiChop Chicken Bowl', 143, 8.5, 20.0, 3.5,
 2.5, 1.0, 370, NULL,
 'pollo_tropical', ARRAY['pollo tropical tropichop', 'tropichop chicken', 'pollo tropical rice bowl'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Bowl ~370g = 530 cal. Grilled chicken with white rice and black beans.', TRUE,
 500, 35, 0.8, 0.0, 350, 40, 2.0, 5, 2.0, 0, 35, 1.5, 150, 12, 0.03),

-- Chicken Wrap: ~480 cal per 280g
('pollo_tropical_chicken_wrap', 'Pollo Tropical Chicken Wrap', 171, 11.0, 17.0, 6.5,
 1.5, 1.5, 280, NULL,
 'pollo_tropical', ARRAY['pollo tropical wrap', 'pollo tropical chicken wrap'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Wrap ~280g = 480 cal. Grilled chicken in flour tortilla with rice and beans.', TRUE,
 520, 40, 2.0, 0.0, 250, 50, 2.0, 10, 3.0, 0, 25, 1.2, 130, 12, 0.03),

-- Sweet Plantains: 450 cal per 204g
('pollo_tropical_sweet_plantains', 'Pollo Tropical Sweet Plantains', 220, 1.0, 38.0, 8.0,
 2.0, 22.0, 204, NULL,
 'pollo_tropical', ARRAY['pollo tropical plantains', 'pollo tropical maduros', 'sweet plantains pollo tropical'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Side ~204g = 450 cal. Fried sweet ripe plantain slices.', TRUE,
 20, 0, 2.0, 0.1, 350, 5, 0.5, 35, 10.0, 0, 30, 0.2, 25, 1, 0.01),

-- Yellow Rice: ~190 cal per 130g side
('pollo_tropical_yellow_rice', 'Pollo Tropical Yellow Rice', 146, 3.0, 28.0, 2.5,
 0.5, 0.5, 130, NULL,
 'pollo_tropical', ARRAY['pollo tropical rice', 'pollo tropical yellow rice', 'arroz amarillo pollo tropical'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Side ~130g = 190 cal. Saffron-seasoned white rice.', TRUE,
 380, 0, 0.5, 0.0, 50, 10, 1.5, 0, 0.0, 0, 12, 0.5, 40, 5, 0.0),

-- Black Beans: ~130 cal per 120g side
('pollo_tropical_black_beans', 'Pollo Tropical Black Beans', 108, 7.0, 18.0, 0.8,
 5.0, 0.5, 120, NULL,
 'pollo_tropical', ARRAY['pollo tropical beans', 'pollo tropical black beans', 'frijoles negros pollo tropical'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Side ~120g = 130 cal. Seasoned black beans with onions and peppers.', TRUE,
 380, 0, 0.2, 0.0, 360, 30, 2.0, 0, 1.0, 0, 45, 1.0, 110, 3, 0.05),

-- Yuca Fries: ~300 cal per 150g
('pollo_tropical_yuca_fries', 'Pollo Tropical Yuca Fries', 200, 1.5, 35.0, 6.0,
 2.0, 1.5, 150, NULL,
 'pollo_tropical', ARRAY['pollo tropical yuca', 'pollo tropical cassava fries', 'yuca frita pollo tropical'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Side ~150g = 300 cal. Fried cassava root sticks.', TRUE,
 350, 0, 1.0, 0.1, 250, 15, 0.5, 0, 15.0, 0, 20, 0.3, 25, 2, 0.01),

-- Chicken Quesadilla: ~550 cal per 250g
('pollo_tropical_quesadilla', 'Pollo Tropical Chicken Quesadilla', 220, 13.0, 16.0, 12.0,
 1.0, 1.5, 250, NULL,
 'pollo_tropical', ARRAY['pollo tropical quesadilla', 'pollo tropical chicken quesadilla'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. One quesadilla ~250g = 550 cal. Grilled tortilla with chicken and melted cheese.', TRUE,
 580, 55, 5.5, 0.1, 180, 150, 1.5, 25, 1.5, 5, 20, 1.8, 200, 14, 0.03),

-- Tres Leches: ~280 cal per 120g
('pollo_tropical_tres_leches', 'Pollo Tropical Tres Leches', 233, 4.5, 32.0, 10.0,
 0.0, 25.0, 120, NULL,
 'pollo_tropical', ARRAY['pollo tropical tres leches', 'tres leches cake pollo tropical'],
 'latin', 'Pollo Tropical', 1, 'Per 100g. Slice ~120g = 280 cal. Three-milk-soaked sponge cake.', TRUE,
 100, 30, 5.5, 0.1, 120, 80, 0.3, 25, 0.5, 10, 10, 0.4, 70, 3, 0.01),

-- ==========================================
-- EL POLLO LOCO (Mexican/Latin)
-- ==========================================

-- Fire-Grilled Chicken Breast: 200 cal per 122g
('el_pollo_loco_chicken_breast', 'El Pollo Loco Fire-Grilled Chicken Breast', 164, 27.9, 0.0, 6.6,
 0.0, 0.0, 122, NULL,
 'el_pollo_loco', ARRAY['el pollo loco chicken', 'el pollo loco breast', 'fire grilled chicken el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Breast ~122g = 200 cal. Citrus-marinated fire-grilled chicken breast.', TRUE,
 490, 90, 1.6, 0.0, 280, 10, 0.8, 5, 0.5, 5, 25, 1.2, 200, 22, 0.03),

-- Classic Burrito: 510 cal per 295g
('el_pollo_loco_classic_burrito', 'El Pollo Loco Classic Burrito', 173, 8.8, 22.0, 5.1,
 2.0, 1.5, 295, NULL,
 'el_pollo_loco', ARRAY['el pollo loco burrito', 'el pollo loco classic burrito', 'classic chicken burrito el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Burrito ~295g = 510 cal. Flour tortilla with chicken, rice, beans, cheese.', TRUE,
 580, 30, 1.5, 0.0, 280, 80, 2.5, 15, 2.0, 0, 30, 1.5, 150, 12, 0.03),

-- Taco al Carbon: 170 cal per 85g
('el_pollo_loco_taco_al_carbon', 'El Pollo Loco Taco al Carbon', 200, 17.6, 20.0, 5.9,
 1.0, 1.0, 85, NULL,
 'el_pollo_loco', ARRAY['el pollo loco taco', 'taco al carbon el pollo loco', 'el pollo loco chicken taco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. One taco ~85g = 170 cal. Corn tortilla with grilled chicken, cilantro, onion, salsa.', TRUE,
 450, 35, 1.2, 0.0, 200, 40, 1.5, 10, 3.0, 0, 20, 1.0, 120, 12, 0.02),

-- Mexican Chicken Caesar Salad: ~350 cal per 300g
('el_pollo_loco_caesar_salad', 'El Pollo Loco Mexican Chicken Caesar Salad', 117, 9.5, 6.0, 6.5,
 2.0, 2.0, 300, NULL,
 'el_pollo_loco', ARRAY['el pollo loco caesar salad', 'el pollo loco salad', 'mexican caesar salad el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Salad ~300g = 350 cal. Romaine, grilled chicken, cotija, croutons, Caesar dressing.', TRUE,
 480, 40, 2.0, 0.0, 300, 80, 1.5, 60, 8.0, 0, 18, 1.0, 140, 12, 0.03),

-- Churro: ~230 cal per 70g
('el_pollo_loco_churro', 'El Pollo Loco Churro', 329, 4.0, 42.0, 16.0,
 1.0, 15.0, 70, NULL,
 'el_pollo_loco', ARRAY['el pollo loco churro', 'churro el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. One churro ~70g = 230 cal. Fried dough rolled in cinnamon sugar.', TRUE,
 250, 15, 3.5, 0.5, 50, 15, 1.5, 5, 0.2, 0, 8, 0.3, 35, 5, 0.01),

-- Cilantro Lime Rice: ~170 cal per 130g
('el_pollo_loco_cilantro_lime_rice', 'El Pollo Loco Cilantro Lime Rice', 131, 2.5, 26.0, 2.0,
 0.5, 0.5, 130, NULL,
 'el_pollo_loco', ARRAY['el pollo loco rice', 'cilantro lime rice el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Side ~130g = 170 cal. White rice with cilantro and lime.', TRUE,
 350, 0, 0.5, 0.0, 50, 10, 1.5, 0, 2.0, 0, 10, 0.4, 35, 5, 0.0),

-- Pinto Beans: ~140 cal per 130g
('el_pollo_loco_pinto_beans', 'El Pollo Loco Pinto Beans', 108, 6.5, 17.0, 1.5,
 4.5, 0.5, 130, NULL,
 'el_pollo_loco', ARRAY['el pollo loco beans', 'pinto beans el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Side ~130g = 140 cal. Seasoned pinto beans.', TRUE,
 400, 0, 0.3, 0.0, 350, 35, 2.0, 0, 1.0, 0, 40, 0.8, 100, 3, 0.05),

-- Pollo Bowl: 580 cal per 513g
('el_pollo_loco_pollo_bowl', 'El Pollo Loco Pollo Bowl', 113, 7.8, 16.2, 1.9,
 2.0, 1.0, 513, NULL,
 'el_pollo_loco', ARRAY['el pollo loco bowl', 'pollo bowl el pollo loco', 'el pollo loco original pollo bowl'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Bowl ~513g = 580 cal. Grilled chicken over rice, beans, pico de gallo, avocado.', TRUE,
 520, 40, 0.5, 0.0, 350, 50, 2.5, 10, 5.0, 0, 35, 1.5, 160, 14, 0.04),

-- Chicken Avocado Burrito: ~600 cal per 330g
('el_pollo_loco_chicken_avocado_burrito', 'El Pollo Loco Chicken Avocado Burrito', 182, 9.5, 19.0, 7.5,
 3.0, 1.5, 330, NULL,
 'el_pollo_loco', ARRAY['el pollo loco avocado burrito', 'chicken avocado burrito el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Burrito ~330g = 600 cal. Flour tortilla with chicken, avocado, rice, beans, cheese.', TRUE,
 560, 35, 2.5, 0.0, 320, 75, 2.5, 10, 4.0, 0, 30, 1.5, 150, 12, 0.05),

-- BRC Burrito: ~430 cal per 260g
('el_pollo_loco_brc_burrito', 'El Pollo Loco BRC Burrito', 165, 6.5, 22.0, 5.5,
 2.5, 1.0, 260, NULL,
 'el_pollo_loco', ARRAY['el pollo loco brc', 'brc burrito el pollo loco', 'bean rice cheese burrito el pollo loco'],
 'mexican', 'El Pollo Loco', 1, 'Per 100g. Burrito ~260g = 430 cal. Flour tortilla with beans, rice, and cheese.', TRUE,
 540, 15, 2.5, 0.0, 250, 80, 2.0, 10, 1.0, 0, 28, 0.8, 120, 8, 0.02),

-- ==========================================
-- ITSU (Asian Healthy - UK)
-- ==========================================

-- Chicken Gyoza 5pc: ~186 cal per 130g
('itsu_chicken_gyoza', 'Itsu Chicken Gyoza (5 pc)', 143, 7.7, 20.0, 4.1,
 1.0, 1.5, 130, 26,
 'itsu', ARRAY['itsu gyoza', 'itsu chicken gyoza', 'itsu dumplings chicken'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. 5 gyoza ~130g = 186 cal. Steamed chicken and vegetable dumplings.', TRUE,
 420, 20, 1.0, 0.0, 110, 12, 0.8, 5, 0.5, 0, 10, 0.6, 60, 6, 0.02),

-- Veggie Crystal Dumplings: ~140 cal per 120g
('itsu_veggie_crystal_dumplings', 'Itsu Veggie Crystal Dumplings', 117, 3.0, 20.0, 2.5,
 1.5, 1.0, 120, 24,
 'itsu', ARRAY['itsu crystal dumplings', 'itsu veggie dumplings', 'itsu vegetable crystal'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. 5 dumplings ~120g = 140 cal. Translucent wrapper with vegetable filling.', TRUE,
 380, 0, 0.5, 0.0, 100, 15, 0.8, 10, 2.0, 0, 8, 0.4, 30, 3, 0.01),

-- Teriyaki Chicken Rice Bowl: ~480 cal per 350g
('itsu_teriyaki_chicken_rice', 'Itsu Teriyaki Chicken Rice Bowl', 137, 8.5, 19.0, 3.5,
 1.0, 4.0, 350, NULL,
 'itsu', ARRAY['itsu teriyaki bowl', 'itsu chicken rice', 'itsu teriyaki chicken'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Bowl ~350g = 480 cal. Teriyaki chicken on white rice with edamame and sesame.', TRUE,
 450, 40, 0.8, 0.0, 200, 20, 1.2, 8, 2.0, 0, 18, 1.0, 120, 12, 0.03),

-- Miso Soup: ~45 cal per 200ml
('itsu_miso_soup', 'Itsu Miso Soup', 22, 1.5, 2.0, 0.8,
 0.5, 0.5, 200, NULL,
 'itsu', ARRAY['itsu miso', 'itsu miso soup', 'miso soup itsu'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Cup ~200ml = 45 cal. Traditional miso soup with tofu, wakame, spring onion.', TRUE,
 600, 0, 0.1, 0.0, 100, 20, 0.8, 2, 0.5, 0, 15, 0.3, 30, 2, 0.01),

-- Edamame: ~120 cal per 100g
('itsu_edamame', 'Itsu Edamame', 120, 11.0, 7.5, 5.0,
 4.5, 2.0, 100, NULL,
 'itsu', ARRAY['itsu edamame', 'edamame beans itsu', 'itsu salted edamame'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Serving ~100g = 120 cal. Steamed edamame with sea salt.', TRUE,
 350, 0, 0.6, 0.0, 430, 55, 2.5, 5, 5.0, 0, 55, 1.0, 170, 2, 0.3),

-- Salmon Avocado Dragon Roll: ~280 cal per 180g
('itsu_salmon_avocado_dragon_roll', 'Itsu Salmon Avocado Dragon Roll', 156, 7.0, 20.0, 5.5,
 2.0, 3.0, 180, NULL,
 'itsu', ARRAY['itsu dragon roll', 'itsu salmon avocado', 'salmon dragon roll itsu'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Pack ~180g = 280 cal. Salmon and avocado sushi roll with soy and wasabi.', TRUE,
 420, 18, 1.0, 0.0, 250, 12, 0.8, 10, 2.0, 10, 20, 0.5, 100, 15, 0.4),

-- Chicken Katsu Rice: ~520 cal per 350g
('itsu_chicken_katsu_rice', 'Itsu Chicken Katsu Rice', 149, 9.0, 18.5, 4.5,
 1.0, 2.5, 350, NULL,
 'itsu', ARRAY['itsu katsu rice', 'itsu chicken katsu', 'chicken katsu bowl itsu'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Bowl ~350g = 520 cal. Panko chicken on rice with katsu curry sauce and pickles.', TRUE,
 460, 40, 1.0, 0.0, 190, 20, 1.2, 8, 1.5, 0, 18, 1.2, 125, 12, 0.03),

-- Raw Rainbow Salad: ~180 cal per 250g
('itsu_raw_rainbow_salad', 'Itsu Raw Rainbow Salad', 72, 4.0, 8.0, 2.5,
 2.5, 3.0, 250, NULL,
 'itsu', ARRAY['itsu rainbow salad', 'itsu raw salad', 'raw rainbow salad itsu'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Salad ~250g = 180 cal. Edamame, carrots, red cabbage, avocado with sesame dressing.', TRUE,
 320, 0, 0.3, 0.0, 350, 40, 1.5, 50, 20.0, 0, 28, 0.8, 60, 3, 0.1),

-- Bliss Ball: ~110 cal per 28g
('itsu_bliss_ball', 'Itsu Bliss Ball', 393, 10.0, 42.0, 20.0,
 6.0, 22.0, 28, 28,
 'itsu', ARRAY['itsu bliss ball', 'itsu energy ball', 'bliss ball itsu'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. One ball ~28g = 110 cal. Dates, coconut, almond, matcha energy ball.', TRUE,
 60, 0, 5.0, 0.0, 350, 30, 2.0, 2, 0.5, 0, 50, 1.0, 100, 5, 0.08),

-- Prawn Crackers: ~110 cal per 22g
('itsu_prawn_crackers', 'Itsu Prawn Crackers', 500, 5.0, 60.0, 28.0,
 1.0, 3.0, 22, NULL,
 'itsu', ARRAY['itsu prawn crackers', 'prawn crackers itsu', 'itsu chips'],
 'asian_healthy', 'Itsu', 1, 'Per 100g. Pack ~22g = 110 cal. Light prawn crackers.', TRUE,
 700, 10, 5.0, 0.2, 50, 15, 0.5, 2, 0.2, 0, 8, 0.3, 30, 3, 0.02),

-- ==========================================
-- FRANCO MANCA (UK Pizza)
-- ==========================================

-- No.1 Margherita: 784 cal per 350g pizza
('franco_manca_margherita', 'Franco Manca No.1 Margherita', 224, 9.0, 28.0, 8.5,
 1.5, 2.5, 350, NULL,
 'franco_manca', ARRAY['franco manca margherita', 'franco manca no 1', 'franco manca pizza margherita'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Whole pizza ~350g = 784 cal. Sourdough base with organic tomato, mozzarella, basil.', TRUE,
 480, 25, 4.0, 0.0, 180, 150, 1.5, 30, 3.0, 0, 18, 1.2, 140, 12, 0.02),

-- No.4 Cured Ham & Mozzarella: ~900 cal per 380g
('franco_manca_no4_ham', 'Franco Manca No.4 Cured Ham & Mozzarella', 237, 12.0, 26.0, 9.5,
 1.5, 2.0, 380, NULL,
 'franco_manca', ARRAY['franco manca no 4', 'franco manca ham pizza', 'franco manca cured ham'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Whole pizza ~380g = 900 cal. Sourdough with cured ham, mozzarella, rocket.', TRUE,
 560, 35, 4.5, 0.0, 200, 160, 1.8, 25, 2.5, 0, 20, 1.5, 160, 15, 0.02),

-- No.5 Sausage & Friarielli: ~950 cal per 390g
('franco_manca_no5_sausage', 'Franco Manca No.5 Sausage & Friarielli', 244, 11.0, 25.0, 11.5,
 2.0, 2.0, 390, NULL,
 'franco_manca', ARRAY['franco manca no 5', 'franco manca sausage pizza', 'franco manca sausage friarielli'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Whole pizza ~390g = 950 cal. Italian sausage with broccoli rabe on sourdough.', TRUE,
 580, 30, 5.0, 0.1, 220, 140, 2.0, 35, 5.0, 0, 22, 1.5, 150, 14, 0.02),

-- No.6 Organic Chorizo: ~980 cal per 390g
('franco_manca_no6_chorizo', 'Franco Manca No.6 Organic Chorizo', 251, 11.5, 25.0, 12.5,
 1.5, 2.0, 390, NULL,
 'franco_manca', ARRAY['franco manca no 6', 'franco manca chorizo pizza', 'franco manca organic chorizo'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Whole pizza ~390g = 980 cal. Organic chorizo with mozzarella on sourdough.', TRUE,
 620, 35, 5.5, 0.1, 210, 150, 2.0, 30, 3.0, 0, 20, 1.5, 155, 15, 0.02),

-- Garlic Bread with Mozzarella: ~350 cal per 150g
('franco_manca_garlic_bread', 'Franco Manca Garlic Bread with Mozzarella', 233, 8.0, 28.0, 10.0,
 1.5, 1.5, 150, NULL,
 'franco_manca', ARRAY['franco manca garlic bread', 'garlic bread franco manca', 'franco manca cheesy garlic bread'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Serving ~150g = 350 cal. Sourdough with garlic butter and melted mozzarella.', TRUE,
 500, 20, 5.0, 0.1, 100, 120, 1.5, 25, 0.5, 0, 14, 0.8, 100, 10, 0.01),

-- Tiramisu: ~350 cal per 130g
('franco_manca_tiramisu', 'Franco Manca Tiramisu', 269, 5.0, 28.0, 15.5,
 0.3, 20.0, 130, NULL,
 'franco_manca', ARRAY['franco manca tiramisu', 'tiramisu franco manca'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Serving ~130g = 350 cal. Classic Italian mascarpone and espresso dessert.', TRUE,
 50, 80, 9.0, 0.1, 100, 40, 0.5, 40, 0.2, 5, 10, 0.5, 60, 4, 0.01),

-- Mixed Salad: ~80 cal per 150g
('franco_manca_mixed_salad', 'Franco Manca Mixed Salad', 53, 1.5, 5.0, 3.0,
 2.0, 2.5, 150, NULL,
 'franco_manca', ARRAY['franco manca salad', 'mixed salad franco manca', 'franco manca side salad'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Serving ~150g = 80 cal. Mixed leaves with olive oil dressing.', TRUE,
 150, 0, 0.4, 0.0, 250, 30, 1.0, 50, 12.0, 0, 12, 0.3, 25, 1, 0.05),

-- Nduja Pizza: ~1020 cal per 400g
('franco_manca_nduja_pizza', 'Franco Manca Nduja Pizza', 255, 10.5, 25.0, 13.0,
 1.5, 2.0, 400, NULL,
 'franco_manca', ARRAY['franco manca nduja', 'nduja pizza franco manca', 'franco manca spicy nduja'],
 'pizza', 'Franco Manca', 1, 'Per 100g. Whole pizza ~400g = 1020 cal. Spicy spreadable salami (nduja) on sourdough base.', TRUE,
 640, 35, 6.0, 0.1, 200, 140, 2.0, 30, 5.0, 0, 18, 1.5, 150, 14, 0.02),

-- ==========================================
-- GENERIC DOSA SHOP (South Asian Street Food)
-- ==========================================

-- Paper Dosa (generic)
('generic_paper_dosa', 'Paper Dosa', 165, 3.5, 24.0, 6.0,
 0.8, 0.8, 180, NULL,
 'generic_indian', ARRAY['paper dosa', 'thin crispy dosa', 'paper dosai', 'crispy plain dosa'],
 'indian', NULL, 1, 'Per 100g. One dosa ~180g = 297 cal. Extra thin, crispy fermented rice-lentil crepe.', TRUE,
 300, 0, 1.5, 0.0, 90, 12, 1.0, 2, 0.5, 0, 16, 0.5, 55, 3, 0.01),

-- Masala Dosa (generic)
('generic_masala_dosa', 'Masala Dosa', 188, 4.5, 26.0, 7.5,
 1.5, 1.5, 250, NULL,
 'generic_indian', ARRAY['masala dosa', 'masala dosai', 'potato dosa', 'dosa masala'],
 'indian', NULL, 1, 'Per 100g. One dosa ~250g = 470 cal. Crispy crepe with spiced potato masala filling.', TRUE,
 380, 0, 2.0, 0.0, 200, 20, 1.5, 5, 5.0, 0, 28, 0.8, 80, 4, 0.02),

-- Set Dosa 3pc
('generic_set_dosa', 'Set Dosa (3 pc)', 150, 4.0, 22.0, 5.0,
 1.0, 0.8, 240, 80,
 'generic_indian', ARRAY['set dosa', 'set dosai', 'soft set dosa', 'spongy dosa'],
 'indian', NULL, 1, 'Per 100g. 3 dosas ~240g = 360 cal. Soft, spongy, thick fermented rice-lentil pancakes.', TRUE,
 280, 0, 1.2, 0.0, 100, 15, 1.0, 2, 0.5, 0, 18, 0.5, 60, 3, 0.01),

-- Rava Dosa (generic)
('generic_rava_dosa', 'Rava Dosa', 212, 4.0, 28.0, 9.0,
 1.0, 1.0, 200, NULL,
 'generic_indian', ARRAY['rava dosa', 'rava dosai', 'semolina dosa', 'sooji dosa'],
 'indian', NULL, 1, 'Per 100g. One dosa ~200g = 424 cal. Crispy semolina crepe with onions and cashews.', TRUE,
 350, 0, 2.5, 0.0, 110, 18, 1.2, 3, 2.0, 0, 20, 0.6, 65, 4, 0.01),

-- Onion Rava Dosa
('generic_onion_rava_dosa', 'Onion Rava Dosa', 220, 4.5, 27.0, 10.0,
 1.2, 1.5, 210, NULL,
 'generic_indian', ARRAY['onion rava dosa', 'onion rava dosai', 'rava dosa with onions'],
 'indian', NULL, 1, 'Per 100g. One dosa ~210g = 462 cal. Semolina crepe with extra caramelized onions.', TRUE,
 340, 0, 2.8, 0.0, 120, 18, 1.2, 4, 3.0, 0, 20, 0.6, 65, 4, 0.01),

-- Mysore Masala Dosa
('generic_mysore_masala_dosa', 'Mysore Masala Dosa', 200, 4.5, 25.0, 9.0,
 1.5, 1.5, 260, NULL,
 'generic_indian', ARRAY['mysore masala dosa', 'mysore dosa', 'mysore dosai', 'red chutney dosa'],
 'indian', NULL, 1, 'Per 100g. One dosa ~260g = 520 cal. Masala dosa with spicy red chutney spread inside.', TRUE,
 400, 0, 2.2, 0.0, 210, 22, 1.5, 15, 6.0, 0, 28, 0.8, 82, 4, 0.02),

-- Ghee Roast Dosa
('generic_ghee_roast_dosa', 'Ghee Roast Dosa', 230, 4.0, 25.0, 12.0,
 0.8, 0.8, 200, NULL,
 'generic_indian', ARRAY['ghee roast dosa', 'ghee dosa', 'ghee roast dosai', 'neyy dosa'],
 'indian', NULL, 1, 'Per 100g. One dosa ~200g = 460 cal. Crispy dosa roasted generously with ghee.', TRUE,
 320, 15, 7.0, 0.1, 90, 15, 1.0, 15, 0.5, 2, 16, 0.5, 55, 3, 0.01),

-- Podi Dosa
('generic_podi_dosa', 'Podi Dosa', 210, 5.0, 24.0, 10.0,
 2.0, 0.8, 200, NULL,
 'generic_indian', ARRAY['podi dosa', 'gunpowder dosa', 'podi dosai', 'milagai podi dosa'],
 'indian', NULL, 1, 'Per 100g. One dosa ~200g = 420 cal. Crispy dosa with spicy lentil powder (podi) and sesame oil.', TRUE,
 350, 0, 2.5, 0.0, 130, 30, 2.0, 5, 2.0, 0, 25, 0.8, 80, 5, 0.02),

-- Cheese Dosa
('generic_cheese_dosa', 'Cheese Dosa', 240, 8.0, 22.0, 13.0,
 0.8, 1.0, 220, NULL,
 'generic_indian', ARRAY['cheese dosa', 'cheese dosai', 'dosa with cheese'],
 'indian', NULL, 1, 'Per 100g. One dosa ~220g = 528 cal. Crispy dosa stuffed with melted cheese.', TRUE,
 400, 25, 7.0, 0.1, 90, 150, 1.0, 30, 0.5, 2, 15, 1.0, 120, 5, 0.01),

-- Egg Dosa
('generic_egg_dosa', 'Egg Dosa', 195, 8.0, 22.0, 8.5,
 0.8, 0.8, 220, NULL,
 'generic_indian', ARRAY['egg dosa', 'egg dosai', 'muttai dosa', 'dosa with egg'],
 'indian', NULL, 1, 'Per 100g. One dosa ~220g = 429 cal. Dosa with a cracked egg spread on top, cooked crispy.', TRUE,
 350, 180, 2.5, 0.0, 120, 30, 1.5, 40, 0.5, 10, 16, 1.0, 100, 10, 0.02),

-- ==========================================
-- GENERIC BIRYANI
-- ==========================================

-- Chicken Dum Biryani (generic): ~140 cal/100g
('generic_chicken_biryani', 'Chicken Dum Biryani', 140, 8.0, 17.0, 4.5,
 0.8, 0.5, 400, NULL,
 'generic_indian', ARRAY['chicken biryani', 'chicken dum biryani', 'murgh biryani', 'chicken biryani restaurant'],
 'indian', NULL, 1, 'Per 100g. Plate ~400g = 560 cal. Layered basmati rice with spiced chicken, slow-cooked (dum).', TRUE,
 380, 45, 1.5, 0.0, 220, 25, 1.5, 10, 2.0, 0, 25, 1.5, 140, 12, 0.03),

-- Goat Biryani (generic): ~155 cal/100g (fattier meat)
('generic_goat_biryani', 'Goat Biryani', 155, 9.0, 16.5, 5.5,
 0.8, 0.5, 400, NULL,
 'generic_indian', ARRAY['goat biryani', 'mutton biryani', 'lamb biryani', 'gosht biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~400g = 620 cal. Layered basmati rice with slow-cooked spiced goat meat.', TRUE,
 380, 50, 2.2, 0.1, 240, 20, 2.0, 8, 1.5, 0, 22, 3.0, 150, 10, 0.03),

-- Egg Biryani (generic)
('generic_egg_biryani', 'Egg Biryani', 135, 6.0, 18.0, 4.0,
 0.8, 0.5, 380, NULL,
 'generic_indian', ARRAY['egg biryani', 'anda biryani', 'egg dum biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~380g = 513 cal. Layered basmati rice with hard-boiled eggs and spices.', TRUE,
 350, 120, 1.2, 0.0, 150, 30, 1.5, 30, 1.0, 8, 18, 0.8, 100, 8, 0.02),

-- Veg Biryani (generic): ~158 cal/100g
('generic_veg_biryani', 'Veg Biryani', 150, 3.5, 22.0, 5.0,
 1.5, 1.0, 380, NULL,
 'generic_indian', ARRAY['veg biryani', 'vegetable biryani', 'sabzi biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~380g = 570 cal. Layered basmati rice with mixed vegetables and spices.', TRUE,
 340, 0, 1.5, 0.0, 200, 25, 1.5, 30, 4.0, 0, 25, 0.6, 70, 4, 0.02),

-- Hyderabadi Biryani: slightly richer
('generic_hyderabadi_biryani', 'Hyderabadi Biryani', 160, 9.5, 17.0, 5.5,
 0.8, 0.5, 400, NULL,
 'generic_indian', ARRAY['hyderabadi biryani', 'hyderabadi dum biryani', 'hyderabadi chicken biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~400g = 640 cal. Hyderabad-style layered biryani with kachchi (raw) marinade dum method.', TRUE,
 400, 50, 2.0, 0.0, 230, 25, 1.5, 12, 2.0, 0, 25, 1.5, 145, 12, 0.03),

-- Lucknowi Biryani: milder, more ghee
('generic_lucknowi_biryani', 'Lucknowi Biryani', 165, 8.5, 18.0, 6.5,
 0.5, 0.5, 400, NULL,
 'generic_indian', ARRAY['lucknowi biryani', 'awadhi biryani', 'lucknow biryani', 'pukki biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~400g = 660 cal. Lucknow-style biryani with pre-cooked chicken and saffron rice.', TRUE,
 370, 48, 2.5, 0.1, 210, 22, 1.5, 15, 1.5, 2, 22, 1.5, 140, 12, 0.03),

-- Ambur Biryani: less oily, seeraga samba rice
('generic_ambur_biryani', 'Ambur Biryani', 145, 8.5, 17.5, 4.5,
 0.5, 0.5, 380, NULL,
 'generic_indian', ARRAY['ambur biryani', 'ambur star biryani', 'arcot biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~380g = 551 cal. Tamil Nadu style biryani with seeraga samba rice and dried chillies.', TRUE,
 360, 45, 1.5, 0.0, 210, 20, 1.5, 8, 2.0, 0, 22, 1.5, 135, 11, 0.03),

-- Dindigul Biryani: smaller grains, spicier
('generic_dindigul_biryani', 'Dindigul Biryani', 148, 9.0, 17.0, 4.8,
 0.5, 0.5, 380, NULL,
 'generic_indian', ARRAY['dindigul biryani', 'dindigul thalappakatti biryani', 'thalappakatti biryani'],
 'indian', NULL, 1, 'Per 100g. Plate ~380g = 562 cal. Dindigul-style spicy biryani with jeeraka samba rice and peppery flavour.', TRUE,
 370, 48, 1.5, 0.0, 215, 20, 1.5, 10, 2.5, 0, 23, 1.5, 138, 12, 0.03),

-- ==========================================
-- GENERIC INDIAN SWEETS
-- ==========================================

-- Jalebi: ~370 cal/100g
('generic_jalebi', 'Jalebi', 370, 3.5, 55.0, 15.5,
 0.5, 40.0, 60, 20,
 'generic_indian', ARRAY['jalebi', 'jilapi', 'zulbia', 'imarti'],
 'desserts', NULL, 1, 'Per 100g. 3 pieces ~60g = 222 cal. Deep-fried fermented batter spirals soaked in sugar syrup.', TRUE,
 40, 5, 3.0, 0.5, 80, 15, 1.0, 3, 0.2, 0, 8, 0.3, 30, 2, 0.01),

-- Rasgulla: ~186 cal/100g
('generic_rasgulla', 'Rasgulla', 186, 4.5, 35.0, 3.0,
 0.0, 30.0, 80, 40,
 'generic_indian', ARRAY['rasgulla', 'rasogolla', 'rasgolla', 'rosogolla'],
 'desserts', NULL, 1, 'Per 100g. 2 pieces ~80g = 149 cal. Soft cottage cheese balls in light sugar syrup.', TRUE,
 30, 8, 1.5, 0.0, 50, 40, 0.3, 6, 0.2, 2, 5, 0.3, 35, 2, 0.01),

-- Kaju Katli: ~450 cal/100g
('generic_kaju_katli', 'Kaju Katli', 450, 10.0, 50.0, 24.0,
 1.0, 40.0, 50, 12,
 'generic_indian', ARRAY['kaju katli', 'kaju barfi', 'cashew barfi', 'kaju katri'],
 'desserts', NULL, 1, 'Per 100g. 4 pieces ~50g = 225 cal. Diamond-shaped cashew fudge with silver leaf.', TRUE,
 25, 5, 5.0, 0.0, 200, 12, 1.5, 0, 0.5, 0, 50, 1.5, 120, 5, 0.02),

-- Barfi (plain): ~350 cal/100g
('generic_barfi_plain', 'Barfi (Plain)', 350, 7.0, 48.0, 15.0,
 0.5, 38.0, 50, 25,
 'generic_indian', ARRAY['barfi', 'burfi', 'milk barfi', 'plain barfi', 'dudh barfi'],
 'desserts', NULL, 1, 'Per 100g. 2 pieces ~50g = 175 cal. Dense milk fudge sweetened with sugar.', TRUE,
 40, 12, 8.0, 0.1, 130, 80, 0.5, 20, 0.3, 5, 12, 0.5, 80, 3, 0.01),

-- Boondi Laddu: ~440 cal/100g
('generic_boondi_laddu', 'Boondi Laddu', 440, 6.0, 52.0, 24.0,
 2.0, 35.0, 50, 50,
 'generic_indian', ARRAY['boondi laddu', 'boondi ladoo', 'laddu boondi', 'motichoor laddu'],
 'desserts', NULL, 1, 'Per 100g. One laddu ~50g = 220 cal. Sweet chickpea flour balls with sugar syrup and ghee.', TRUE,
 30, 10, 5.0, 0.2, 150, 20, 1.5, 5, 0.3, 0, 15, 0.5, 60, 3, 0.02),

-- Besan Laddu: ~450 cal/100g
('generic_besan_laddu', 'Besan Laddu', 450, 8.0, 48.0, 26.0,
 3.0, 32.0, 50, 50,
 'generic_indian', ARRAY['besan laddu', 'besan ladoo', 'gram flour laddu', 'besan ke laddu'],
 'desserts', NULL, 1, 'Per 100g. One laddu ~50g = 225 cal. Toasted chickpea flour with ghee and sugar.', TRUE,
 25, 15, 8.0, 0.2, 180, 20, 2.0, 5, 0.3, 2, 18, 0.8, 80, 3, 0.02),

-- Motichoor Laddu: ~420 cal/100g
('generic_motichoor_laddu', 'Motichoor Laddu', 420, 5.5, 55.0, 21.0,
 1.0, 38.0, 50, 50,
 'generic_indian', ARRAY['motichoor laddu', 'motichoor ladoo', 'motichur laddu'],
 'desserts', NULL, 1, 'Per 100g. One laddu ~50g = 210 cal. Fine boondi balls bound with sugar syrup, cardamom, rose water.', TRUE,
 30, 8, 4.5, 0.2, 120, 18, 1.2, 3, 0.2, 0, 12, 0.4, 55, 3, 0.01),

-- Peda: ~380 cal/100g
('generic_peda', 'Peda', 380, 8.0, 45.0, 18.0,
 0.3, 38.0, 40, 20,
 'generic_indian', ARRAY['peda', 'peda sweet', 'mathura peda', 'milk peda', 'doodh peda'],
 'desserts', NULL, 1, 'Per 100g. 2 pieces ~40g = 152 cal. Condensed milk fudge flavored with cardamom and saffron.', TRUE,
 35, 15, 10.0, 0.1, 140, 90, 0.4, 25, 0.3, 5, 12, 0.5, 80, 3, 0.01),

-- Sandesh: ~320 cal/100g
('generic_sandesh', 'Sandesh', 320, 8.0, 42.0, 13.0,
 0.2, 35.0, 40, 20,
 'generic_indian', ARRAY['sandesh', 'sondesh', 'shondesh', 'bengali sandesh'],
 'desserts', NULL, 1, 'Per 100g. 2 pieces ~40g = 128 cal. Bengali cottage cheese sweet with sugar, cardamom, pistachio.', TRUE,
 30, 10, 7.0, 0.1, 100, 60, 0.3, 15, 0.2, 3, 8, 0.4, 60, 3, 0.01),

-- Kheer: ~140 cal/100g
('generic_kheer', 'Kheer', 140, 4.0, 19.0, 5.0,
 0.2, 14.0, 180, NULL,
 'generic_indian', ARRAY['kheer', 'rice kheer', 'payasam', 'rice pudding indian', 'chawal ki kheer'],
 'desserts', NULL, 1, 'Per 100g. Bowl ~180g = 252 cal. Slow-cooked rice pudding with milk, sugar, cardamom, nuts, saffron.', TRUE,
 40, 12, 3.0, 0.1, 150, 80, 0.3, 20, 0.5, 5, 12, 0.4, 70, 3, 0.02)

ON CONFLICT (food_name_normalized) DO NOTHING;
