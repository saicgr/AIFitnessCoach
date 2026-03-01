-- 341_chinese_buffet.sql
-- Chinese Buffet items (~90 items): appetizers, chicken, beef, pork, seafood,
-- noodles/rice, soups, vegetables, sushi bar, and desserts.
-- All values per 100g. Sources: USDA FoodData Central, nutritionix.com,
-- calorieking.com, nutritionvalue.org, fatsecret.com.
-- All items prefixed with 'chinese_buffet_' to avoid collisions with existing entries.
-- restaurant_name = NULL (generic Chinese buffet, not a specific chain).

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
-- APPETIZERS (~10 items)
-- ==========================================

-- Crab Rangoon: USDA ~271 cal/100g. Cream cheese + imitation crab in fried wonton wrapper.
('chinese_buffet_crab_rangoon', 'Crab Rangoon (Chinese Buffet)', 271, 9.4, 28.2, 13.5,
 1.2, 2.4, 100, 25,
 'chinese_buffet', ARRAY['crab rangoon', 'cream cheese wonton', 'crab puff', 'crab wonton', 'cheese wonton', 'chinese buffet crab rangoon'],
 'asian', NULL, 4, '271 cal/100g. ~68 cal per piece (25g). Fried wonton skin with cream cheese and imitation crab.', TRUE,
 420, 35, 5.5, 0.2, 65, 40, 1.0, 25, 0.5, 2, 8, 0.4, 55, 8.0, 0.03),

-- Pork Egg Roll: USDA ~215 cal/100g. Fried wrapper with pork, cabbage, carrots.
('chinese_buffet_pork_egg_roll', 'Pork Egg Roll (Chinese Buffet)', 215, 6.3, 21.3, 11.3,
 1.3, 2.0, 80, 80,
 'chinese_buffet', ARRAY['pork egg roll', 'egg roll', 'chinese egg roll', 'buffet egg roll', 'fried egg roll'],
 'asian', NULL, 1, '215 cal/100g. ~172 cal per roll (80g). Fried wrapper with pork, cabbage, vegetables.', TRUE,
 480, 25, 2.8, 0.1, 120, 22, 1.5, 15, 3.0, 0, 12, 0.6, 50, 7.0, 0.02),

-- Veggie Egg Roll: Slightly lower cal than pork version. ~190 cal/100g.
('chinese_buffet_veggie_egg_roll', 'Vegetable Egg Roll (Chinese Buffet)', 190, 4.5, 23.0, 9.0,
 2.0, 2.5, 80, 80,
 'chinese_buffet', ARRAY['veggie egg roll', 'vegetable egg roll', 'vegetarian egg roll', 'spring roll fried vegetable'],
 'asian', NULL, 1, '190 cal/100g. ~152 cal per roll (80g). Fried wrapper with cabbage, carrots, bean sprouts.', TRUE,
 420, 5, 2.0, 0.1, 140, 25, 1.2, 60, 5.0, 0, 14, 0.4, 35, 4.0, 0.01),

-- Shrimp Egg Roll: ~225 cal/100g. Shrimp and vegetable filling.
('chinese_buffet_shrimp_egg_roll', 'Shrimp Egg Roll (Chinese Buffet)', 225, 7.5, 22.0, 11.8,
 1.2, 2.0, 80, 80,
 'chinese_buffet', ARRAY['shrimp egg roll', 'prawn egg roll', 'shrimp spring roll fried'],
 'asian', NULL, 1, '225 cal/100g. ~180 cal per roll (80g). Fried wrapper with shrimp and vegetables.', TRUE,
 500, 45, 2.5, 0.1, 110, 25, 1.3, 12, 2.5, 0, 15, 0.7, 65, 12.0, 0.05),

-- Fried Wontons: ~280 cal/100g. Crispy fried pork-filled wontons.
('chinese_buffet_fried_wontons', 'Fried Wontons (Chinese Buffet)', 280, 8.5, 26.0, 15.5,
 0.8, 1.5, 100, 18,
 'chinese_buffet', ARRAY['fried wontons', 'fried wonton', 'crispy wontons', 'wonton chips', 'fried pork wontons'],
 'asian', NULL, 6, '280 cal/100g. ~50 cal per piece (18g). Pork-filled crispy fried wontons.', TRUE,
 510, 30, 3.5, 0.2, 85, 18, 1.5, 8, 0.5, 0, 10, 0.5, 45, 6.0, 0.02),

-- Pot Stickers / Dumplings (pan-fried): ~220 cal/100g.
('chinese_buffet_pot_stickers', 'Pot Stickers / Dumplings (Chinese Buffet)', 220, 8.0, 24.0, 10.0,
 1.0, 1.5, 120, 30,
 'chinese_buffet', ARRAY['pot stickers', 'potstickers', 'dumplings', 'pan fried dumplings', 'gyoza', 'chinese dumplings', 'pork dumplings'],
 'asian', NULL, 4, '220 cal/100g. ~66 cal per piece (30g). Pan-fried pork and cabbage dumplings.', TRUE,
 450, 25, 2.5, 0.1, 110, 20, 1.4, 10, 1.5, 0, 12, 0.8, 55, 8.0, 0.02),

-- Crispy Spring Rolls: ~310 cal/100g. Thinner wrapper, more fried crunch.
('chinese_buffet_spring_rolls', 'Crispy Spring Rolls (Chinese Buffet)', 310, 5.0, 30.0, 18.5,
 1.5, 2.0, 60, 30,
 'chinese_buffet', ARRAY['spring rolls', 'crispy spring roll', 'fried spring rolls', 'mini spring rolls', 'vegetable spring rolls'],
 'asian', NULL, 2, '310 cal/100g. ~93 cal per roll (30g). Thin crispy fried wrapper with vegetable filling.', TRUE,
 380, 10, 4.0, 0.2, 100, 15, 1.0, 30, 3.0, 0, 10, 0.3, 30, 3.5, 0.01),

-- BBQ Spare Ribs: ~285 cal/100g. Chinese-style glazed pork ribs.
('chinese_buffet_bbq_spare_ribs', 'BBQ Spare Ribs (Chinese Buffet)', 285, 18.5, 12.0, 18.0,
 0.2, 8.5, 150, NULL,
 'chinese_buffet', ARRAY['bbq spare ribs', 'chinese spare ribs', 'barbecue ribs', 'pork spare ribs', 'glazed ribs', 'honey garlic ribs'],
 'asian', NULL, 1, '285 cal/100g. Pork ribs glazed with sweet BBQ sauce, Chinese style.', TRUE,
 620, 85, 6.5, 0.1, 220, 30, 1.5, 5, 1.0, 5, 18, 2.5, 160, 18.0, 0.04),

-- Fried Shrimp (Chinese style): ~240 cal/100g. Light batter, fried.
('chinese_buffet_fried_shrimp', 'Fried Shrimp Chinese Style (Chinese Buffet)', 240, 12.0, 20.0, 12.5,
 0.5, 1.0, 100, 15,
 'chinese_buffet', ARRAY['fried shrimp', 'chinese fried shrimp', 'battered shrimp', 'crispy shrimp', 'golden shrimp'],
 'asian', NULL, 6, '240 cal/100g. ~36 cal per piece (15g). Lightly battered and fried shrimp.', TRUE,
 520, 110, 2.5, 0.1, 130, 30, 1.0, 8, 1.0, 0, 20, 0.8, 120, 22.0, 0.08),

-- Chicken Wings (Chinese garlic): ~250 cal/100g. Garlic sauce glaze.
('chinese_buffet_garlic_chicken_wings', 'Chinese Garlic Chicken Wings (Chinese Buffet)', 250, 17.0, 10.0, 16.0,
 0.2, 5.0, 120, 40,
 'chinese_buffet', ARRAY['chinese chicken wings', 'garlic chicken wings', 'chinese garlic wings', 'soy garlic wings', 'buffet chicken wings'],
 'asian', NULL, 3, '250 cal/100g. ~100 cal per wing (40g). Fried wings in garlic soy glaze.', TRUE,
 580, 75, 4.5, 0.1, 160, 15, 1.2, 20, 0.5, 3, 15, 1.5, 130, 16.0, 0.04),

-- ==========================================
-- CHICKEN DISHES (~10 items)
-- ==========================================

-- General Tso's Chicken: USDA ~295 cal/100g. Battered fried chicken in sweet-spicy sauce.
('chinese_buffet_general_tsos', 'General Tso''s Chicken (Chinese Buffet)', 295, 12.9, 23.0, 17.0,
 0.3, 10.0, 200, NULL,
 'chinese_buffet', ARRAY['general tso chicken', 'general tso''s chicken', 'general tao chicken', 'buffet general tso', 'general tso''s'],
 'asian', NULL, 1, '295 cal/100g. Battered fried chicken pieces in sweet-spicy sauce. Buffet style.', TRUE,
 435, 55, 3.5, 0.1, 180, 18, 1.2, 10, 2.0, 3, 18, 0.9, 110, 14.0, 0.02),

-- Sesame Chicken: USDA ~293 cal/100g. Similar to General Tso's but sweeter, sesame seeds.
('chinese_buffet_sesame_chicken', 'Sesame Chicken (Chinese Buffet)', 293, 14.3, 26.2, 14.0,
 0.4, 12.0, 200, NULL,
 'chinese_buffet', ARRAY['sesame chicken', 'chinese sesame chicken', 'buffet sesame chicken', 'sesame seed chicken'],
 'asian', NULL, 1, '293 cal/100g. Fried chicken in sweet sesame glaze with sesame seeds.', TRUE,
 482, 50, 3.0, 0.1, 175, 25, 1.3, 8, 1.5, 3, 22, 1.0, 115, 14.0, 0.02),

-- Cashew Chicken: ~185 cal/100g. Stir-fried chicken with cashews and vegetables.
('chinese_buffet_cashew_chicken', 'Cashew Chicken (Chinese Buffet)', 185, 13.0, 10.5, 10.5,
 1.0, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['cashew chicken', 'chicken with cashews', 'cashew nut chicken', 'buffet cashew chicken'],
 'asian', NULL, 1, '185 cal/100g. Stir-fried chicken with cashew nuts, bell peppers, and brown sauce.', TRUE,
 520, 45, 2.5, 0.0, 250, 18, 1.5, 15, 8.0, 3, 30, 1.2, 140, 14.0, 0.03),

-- Lemon Chicken: USDA ~252 cal/100g. Battered chicken with lemon sauce.
('chinese_buffet_lemon_chicken', 'Lemon Chicken (Chinese Buffet)', 252, 11.9, 19.6, 14.0,
 0.3, 8.5, 200, NULL,
 'chinese_buffet', ARRAY['lemon chicken', 'chinese lemon chicken', 'lemon sauce chicken', 'buffet lemon chicken'],
 'asian', NULL, 1, '252 cal/100g. Battered fried chicken with tangy lemon glaze.', TRUE,
 410, 50, 3.0, 0.1, 160, 15, 1.0, 8, 10.0, 3, 16, 0.8, 100, 12.0, 0.02),

-- Bourbon Chicken: ~210 cal/100g. Sweet and savory glazed chicken.
('chinese_buffet_bourbon_chicken', 'Bourbon Chicken (Chinese Buffet)', 210, 14.0, 16.0, 9.5,
 0.3, 10.0, 200, NULL,
 'chinese_buffet', ARRAY['bourbon chicken', 'bourbon street chicken', 'mall bourbon chicken', 'sweet bourbon chicken'],
 'asian', NULL, 1, '210 cal/100g. Chicken thigh pieces in sweet bourbon-soy glaze. Popular mall food court item.', TRUE,
 550, 60, 2.5, 0.0, 200, 12, 1.0, 8, 1.0, 3, 18, 1.0, 120, 15.0, 0.02),

-- Honey Walnut Chicken: ~275 cal/100g. Battered chicken with candied walnuts.
('chinese_buffet_honey_walnut_chicken', 'Honey Walnut Chicken (Chinese Buffet)', 275, 12.0, 22.0, 16.0,
 1.0, 12.0, 200, NULL,
 'chinese_buffet', ARRAY['honey walnut chicken', 'walnut chicken', 'honey chicken with walnuts'],
 'asian', NULL, 1, '275 cal/100g. Battered chicken with candied walnuts in creamy honey sauce.', TRUE,
 380, 45, 3.0, 0.1, 170, 20, 1.2, 8, 1.0, 2, 25, 1.0, 110, 12.0, 0.15),

-- Chicken with Broccoli: ~140 cal/100g. Lighter stir-fry.
('chinese_buffet_chicken_broccoli', 'Chicken with Broccoli (Chinese Buffet)', 140, 12.0, 7.5, 7.0,
 1.5, 2.0, 250, NULL,
 'chinese_buffet', ARRAY['chicken broccoli', 'chicken with broccoli', 'broccoli chicken', 'chinese chicken broccoli'],
 'asian', NULL, 1, '140 cal/100g. Stir-fried chicken and broccoli in light garlic sauce.', TRUE,
 480, 40, 1.5, 0.0, 280, 40, 1.0, 30, 25.0, 3, 20, 0.8, 120, 12.0, 0.02),

-- Chicken with Mixed Vegetables: ~120 cal/100g.
('chinese_buffet_chicken_mixed_veg', 'Chicken with Mixed Vegetables (Chinese Buffet)', 120, 10.0, 8.0, 5.5,
 1.5, 2.5, 250, NULL,
 'chinese_buffet', ARRAY['chicken mixed vegetables', 'chicken with vegetables', 'chicken vegetable stir fry', 'chinese chicken vegetables'],
 'asian', NULL, 1, '120 cal/100g. Stir-fried chicken with assorted vegetables in light sauce.', TRUE,
 450, 35, 1.2, 0.0, 260, 30, 1.0, 80, 15.0, 3, 18, 0.7, 100, 10.0, 0.02),

-- Sweet & Sour Chicken: ~185 cal/100g. Battered chicken in sweet-sour sauce.
('chinese_buffet_sweet_sour_chicken', 'Sweet & Sour Chicken (Chinese Buffet)', 185, 9.0, 22.0, 7.0,
 0.5, 10.0, 200, NULL,
 'chinese_buffet', ARRAY['sweet and sour chicken', 'sweet sour chicken', 'sweet & sour chicken', 'buffet sweet sour chicken'],
 'asian', NULL, 1, '185 cal/100g. Battered fried chicken in pineapple sweet-sour sauce.', TRUE,
 350, 40, 1.5, 0.1, 150, 15, 0.8, 10, 8.0, 2, 14, 0.6, 80, 10.0, 0.02),

-- Kung Pao Chicken: USDA ~175 cal/100g. Spicy with peanuts.
('chinese_buffet_kung_pao_chicken', 'Kung Pao Chicken (Chinese Buffet)', 175, 12.0, 10.3, 10.0,
 1.0, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['kung pao chicken', 'kung pao', 'gong bao chicken', 'kung po chicken', 'spicy peanut chicken'],
 'asian', NULL, 1, '175 cal/100g. Diced chicken with peanuts, chili peppers in spicy Sichuan sauce.', TRUE,
 600, 50, 2.0, 0.0, 260, 20, 1.5, 20, 6.0, 3, 28, 1.2, 140, 14.0, 0.03),

-- ==========================================
-- BEEF DISHES (~6 items)
-- ==========================================

-- Mongolian Beef: ~190 cal/100g. Sliced beef in sweet soy-ginger sauce with scallions.
('chinese_buffet_mongolian_beef', 'Mongolian Beef (Chinese Buffet)', 190, 14.0, 12.0, 10.0,
 0.5, 6.5, 200, NULL,
 'chinese_buffet', ARRAY['mongolian beef', 'chinese mongolian beef', 'sweet soy beef', 'scallion beef'],
 'asian', NULL, 1, '190 cal/100g. Sliced flank steak in sweet soy-ginger sauce with scallions.', TRUE,
 650, 55, 3.5, 0.2, 280, 15, 2.5, 5, 2.0, 5, 22, 4.0, 170, 18.0, 0.03),

-- Pepper Steak: ~160 cal/100g. Beef with bell peppers and onions.
('chinese_buffet_pepper_steak', 'Pepper Steak (Chinese Buffet)', 160, 13.5, 8.0, 8.5,
 1.2, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['pepper steak', 'beef pepper steak', 'green pepper steak', 'chinese pepper steak', 'beef with peppers'],
 'asian', NULL, 1, '160 cal/100g. Sliced beef stir-fried with bell peppers and onions in savory sauce.', TRUE,
 580, 50, 3.0, 0.2, 300, 15, 2.2, 25, 30.0, 5, 20, 3.8, 160, 16.0, 0.03),

-- Beef with Mushrooms: ~155 cal/100g.
('chinese_buffet_beef_mushrooms', 'Beef with Mushrooms (Chinese Buffet)', 155, 13.0, 6.5, 8.5,
 0.8, 2.0, 200, NULL,
 'chinese_buffet', ARRAY['beef mushrooms', 'beef with mushrooms', 'mushroom beef', 'chinese beef mushroom'],
 'asian', NULL, 1, '155 cal/100g. Sliced beef stir-fried with mushrooms in oyster-soy sauce.', TRUE,
 540, 50, 3.0, 0.2, 320, 10, 2.5, 0, 1.0, 10, 18, 4.2, 180, 20.0, 0.03),

-- Beef Chow Fun: ~170 cal/100g. Wide rice noodles with beef.
('chinese_buffet_beef_chow_fun', 'Beef Chow Fun (Chinese Buffet)', 170, 8.0, 20.0, 6.5,
 0.5, 1.5, 300, NULL,
 'chinese_buffet', ARRAY['beef chow fun', 'chow fun', 'ho fun', 'flat rice noodles beef', 'hor fun'],
 'asian', NULL, 1, '170 cal/100g. Wide flat rice noodles stir-fried with sliced beef, bean sprouts, scallions.', TRUE,
 500, 30, 2.0, 0.1, 150, 12, 1.5, 5, 1.5, 5, 12, 2.0, 80, 10.0, 0.02),

-- Beef with Broccoli: USDA ~150 cal/100g.
('chinese_buffet_beef_broccoli', 'Beef with Broccoli (Chinese Buffet)', 150, 12.0, 8.0, 8.0,
 1.5, 2.5, 250, NULL,
 'chinese_buffet', ARRAY['beef broccoli', 'beef with broccoli', 'broccoli beef', 'chinese beef broccoli'],
 'asian', NULL, 1, '150 cal/100g. Sliced beef and broccoli in savory brown sauce.', TRUE,
 550, 40, 2.8, 0.2, 300, 35, 2.0, 25, 22.0, 5, 22, 3.5, 155, 16.0, 0.03),

-- Beef with String Beans: ~145 cal/100g.
('chinese_buffet_beef_string_beans', 'Beef with String Beans (Chinese Buffet)', 145, 12.5, 7.0, 7.5,
 2.0, 2.0, 200, NULL,
 'chinese_buffet', ARRAY['beef string beans', 'beef with string beans', 'beef green beans', 'szechuan beef string beans'],
 'asian', NULL, 1, '145 cal/100g. Sliced beef stir-fried with string beans in garlic-soy sauce.', TRUE,
 520, 45, 2.5, 0.1, 280, 30, 2.2, 20, 8.0, 5, 22, 3.5, 150, 14.0, 0.03),

-- ==========================================
-- PORK DISHES (~5 items)
-- ==========================================

-- Sweet & Sour Pork: USDA ~270 cal/100g. Battered pork in sweet-sour sauce.
('chinese_buffet_sweet_sour_pork', 'Sweet & Sour Pork (Chinese Buffet)', 270, 8.9, 22.3, 16.0,
 0.5, 10.0, 200, NULL,
 'chinese_buffet', ARRAY['sweet and sour pork', 'sweet sour pork', 'sweet & sour pork', 'gu lao rou'],
 'asian', NULL, 1, '270 cal/100g. Battered fried pork in pineapple sweet-sour sauce.', TRUE,
 400, 45, 4.5, 0.1, 180, 15, 1.2, 10, 6.0, 3, 15, 1.8, 110, 14.0, 0.03),

-- Mu Shu Pork: ~150 cal/100g. Shredded pork with eggs, vegetables, hoisin.
('chinese_buffet_mu_shu_pork', 'Mu Shu Pork (Chinese Buffet)', 150, 10.0, 8.5, 8.5,
 1.0, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['mu shu pork', 'moo shu pork', 'mu shu', 'moo shoo pork', 'mushu pork'],
 'asian', NULL, 1, '150 cal/100g. Shredded pork stir-fried with eggs, mushrooms, cabbage. Served with hoisin sauce.', TRUE,
 500, 65, 2.5, 0.1, 220, 25, 1.5, 30, 3.0, 8, 16, 2.0, 130, 14.0, 0.03),

-- Char Siu (BBQ Pork): ~220 cal/100g. Cantonese roasted/grilled pork.
('chinese_buffet_char_siu', 'Char Siu BBQ Pork (Chinese Buffet)', 220, 20.0, 10.0, 11.0,
 0.0, 8.0, 120, NULL,
 'chinese_buffet', ARRAY['char siu', 'chinese bbq pork', 'char siu pork', 'cantonese bbq pork', 'cha siu', 'honey bbq pork'],
 'asian', NULL, 1, '220 cal/100g. Cantonese-style roasted pork with sweet honey-soy glaze.', TRUE,
 720, 70, 4.0, 0.0, 280, 12, 1.5, 5, 0.5, 5, 20, 2.5, 185, 22.0, 0.03),

-- Twice-Cooked Pork: ~200 cal/100g. Sliced pork belly stir-fried with cabbage and peppers.
('chinese_buffet_twice_cooked_pork', 'Twice-Cooked Pork (Chinese Buffet)', 200, 11.0, 8.0, 14.0,
 1.0, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['twice cooked pork', 'double cooked pork', 'hui guo rou', 'twice-cooked pork'],
 'asian', NULL, 1, '200 cal/100g. Sliced pork belly stir-fried with cabbage, peppers, and doubanjiang.', TRUE,
 580, 55, 5.0, 0.1, 230, 20, 1.3, 15, 10.0, 3, 16, 2.0, 140, 16.0, 0.03),

-- Pork with Garlic Sauce: ~165 cal/100g.
('chinese_buffet_pork_garlic_sauce', 'Pork with Garlic Sauce (Chinese Buffet)', 165, 11.0, 10.0, 9.5,
 1.2, 4.0, 200, NULL,
 'chinese_buffet', ARRAY['pork garlic sauce', 'pork with garlic sauce', 'garlic pork', 'yu xiang pork', 'szechuan garlic pork'],
 'asian', NULL, 1, '165 cal/100g. Shredded pork in spicy garlic sauce with bamboo shoots, water chestnuts.', TRUE,
 620, 45, 3.0, 0.1, 250, 18, 1.5, 12, 5.0, 3, 18, 2.0, 135, 15.0, 0.03),

-- ==========================================
-- SEAFOOD (~8 items)
-- ==========================================

-- Salt & Pepper Shrimp: ~200 cal/100g. Lightly fried with salt-pepper seasoning.
('chinese_buffet_salt_pepper_shrimp', 'Salt & Pepper Shrimp (Chinese Buffet)', 200, 16.0, 10.0, 11.0,
 0.5, 0.5, 150, NULL,
 'chinese_buffet', ARRAY['salt pepper shrimp', 'salt and pepper shrimp', 'chinese salt pepper shrimp', 'crispy salt shrimp'],
 'asian', NULL, 1, '200 cal/100g. Shell-on shrimp lightly fried with salt, pepper, garlic, jalape\u00f1o.', TRUE,
 780, 150, 2.0, 0.1, 180, 50, 1.5, 10, 2.0, 0, 28, 1.2, 190, 30.0, 0.12),

-- Coconut Shrimp: ~290 cal/100g. Coconut-breaded fried shrimp.
('chinese_buffet_coconut_shrimp', 'Coconut Shrimp (Chinese Buffet)', 290, 11.0, 22.0, 18.0,
 2.0, 6.0, 120, 20,
 'chinese_buffet', ARRAY['coconut shrimp', 'coconut fried shrimp', 'breaded coconut shrimp', 'crispy coconut shrimp'],
 'asian', NULL, 6, '290 cal/100g. ~58 cal per piece (20g). Shrimp in coconut flake breading, deep fried.', TRUE,
 450, 100, 10.0, 0.1, 140, 20, 1.0, 5, 1.0, 0, 22, 0.8, 130, 22.0, 0.08),

-- Shrimp with Lobster Sauce: ~110 cal/100g. Light egg-based sauce, not from lobster.
('chinese_buffet_shrimp_lobster_sauce', 'Shrimp with Lobster Sauce (Chinese Buffet)', 110, 10.0, 5.0, 5.5,
 0.3, 1.0, 200, NULL,
 'chinese_buffet', ARRAY['shrimp lobster sauce', 'shrimp with lobster sauce', 'shrimp in lobster sauce', 'cantonese shrimp'],
 'asian', NULL, 1, '110 cal/100g. Shrimp in egg-based white sauce with ground pork, peas. No actual lobster.', TRUE,
 520, 120, 1.5, 0.0, 180, 35, 1.2, 25, 2.0, 5, 25, 1.0, 160, 28.0, 0.10),

-- Snow Crab Legs: USDA ~115 cal/100g. Steamed/boiled.
('chinese_buffet_snow_crab_legs', 'Snow Crab Legs (Chinese Buffet)', 115, 23.7, 0.0, 1.5,
 0.0, 0.0, 200, NULL,
 'chinese_buffet', ARRAY['snow crab legs', 'crab legs', 'buffet crab legs', 'snow crab', 'steamed crab legs'],
 'asian', NULL, 1, '115 cal/100g. Steamed snow crab legs. Weight includes shell; edible meat ~50%.', TRUE,
 539, 55, 0.2, 0.0, 270, 50, 0.5, 3, 0.0, 0, 50, 3.6, 250, 34.0, 0.40),

-- King Crab Legs: USDA ~84 cal/100g.
('chinese_buffet_king_crab_legs', 'King Crab Legs (Chinese Buffet)', 84, 18.3, 0.0, 0.6,
 0.0, 0.0, 200, NULL,
 'chinese_buffet', ARRAY['king crab legs', 'alaskan king crab', 'king crab', 'buffet king crab'],
 'asian', NULL, 1, '84 cal/100g. Steamed Alaskan king crab legs. Weight includes shell; edible meat ~50%.', TRUE,
 836, 42, 0.1, 0.0, 204, 46, 0.6, 7, 0.0, 0, 49, 6.5, 238, 36.0, 0.35),

-- Fried Fish Fillet (Chinese style): ~225 cal/100g.
('chinese_buffet_fried_fish', 'Fried Fish Fillet Chinese Style (Chinese Buffet)', 225, 13.0, 15.0, 12.5,
 0.5, 2.0, 150, NULL,
 'chinese_buffet', ARRAY['fried fish', 'chinese fried fish', 'fried fish fillet', 'battered fish', 'crispy fish fillet'],
 'asian', NULL, 1, '225 cal/100g. White fish fillet lightly battered and fried with sweet chili glaze.', TRUE,
 420, 40, 2.5, 0.1, 200, 20, 0.8, 5, 0.5, 20, 22, 0.5, 160, 25.0, 0.15),

-- Honey Walnut Shrimp: ~280 cal/100g. Crispy shrimp with candied walnuts and mayo.
('chinese_buffet_honey_walnut_shrimp', 'Honey Walnut Shrimp (Chinese Buffet)', 280, 10.0, 22.0, 17.5,
 0.8, 12.0, 200, NULL,
 'chinese_buffet', ARRAY['honey walnut shrimp', 'walnut shrimp', 'honey shrimp', 'candied walnut shrimp'],
 'asian', NULL, 1, '280 cal/100g. Crispy battered shrimp with candied walnuts in creamy honey-mayo sauce.', TRUE,
 360, 90, 3.5, 0.1, 150, 25, 1.0, 8, 1.0, 0, 28, 1.0, 140, 24.0, 0.20),

-- Kung Pao Shrimp: ~160 cal/100g.
('chinese_buffet_kung_pao_shrimp', 'Kung Pao Shrimp (Chinese Buffet)', 160, 13.0, 9.0, 8.5,
 1.0, 2.5, 200, NULL,
 'chinese_buffet', ARRAY['kung pao shrimp', 'kung pao prawns', 'spicy peanut shrimp', 'gong bao shrimp'],
 'asian', NULL, 1, '160 cal/100g. Shrimp with peanuts, chili peppers in spicy Sichuan sauce.', TRUE,
 580, 120, 1.5, 0.0, 220, 30, 1.5, 15, 5.0, 0, 30, 1.2, 170, 28.0, 0.12),

-- ==========================================
-- NOODLES & RICE (~9 items)
-- ==========================================

-- Pork Fried Rice: ~168 cal/100g.
('chinese_buffet_pork_fried_rice', 'Pork Fried Rice (Chinese Buffet)', 168, 6.5, 22.0, 6.0,
 0.7, 0.5, 250, NULL,
 'chinese_buffet', ARRAY['pork fried rice', 'roast pork fried rice', 'bbq pork fried rice'],
 'asian', NULL, 1, '168 cal/100g. Wok-fried rice with diced roast pork, egg, scallions, soy sauce.', TRUE,
 520, 55, 1.5, 0.0, 130, 15, 1.2, 10, 1.0, 5, 12, 1.0, 80, 12.0, 0.02),

-- Shrimp Fried Rice: ~165 cal/100g.
('chinese_buffet_shrimp_fried_rice', 'Shrimp Fried Rice (Chinese Buffet)', 165, 7.0, 22.0, 5.5,
 0.7, 0.5, 250, NULL,
 'chinese_buffet', ARRAY['shrimp fried rice', 'prawn fried rice', 'seafood fried rice'],
 'asian', NULL, 1, '165 cal/100g. Wok-fried rice with shrimp, egg, peas, scallions, soy sauce.', TRUE,
 510, 70, 1.2, 0.0, 140, 20, 1.2, 12, 1.5, 5, 15, 0.8, 95, 15.0, 0.05),

-- Combo/House Fried Rice: ~175 cal/100g. Multiple proteins.
('chinese_buffet_house_fried_rice', 'House/Combo Fried Rice (Chinese Buffet)', 175, 7.5, 22.0, 6.5,
 0.8, 0.5, 250, NULL,
 'chinese_buffet', ARRAY['house fried rice', 'combo fried rice', 'special fried rice', 'combination fried rice', 'house special fried rice'],
 'asian', NULL, 1, '175 cal/100g. Fried rice with chicken, shrimp, pork, egg, peas, carrots.', TRUE,
 540, 65, 1.5, 0.0, 145, 18, 1.3, 15, 2.0, 5, 14, 1.0, 90, 14.0, 0.04),

-- Vegetable Fried Rice: ~155 cal/100g.
('chinese_buffet_veg_fried_rice', 'Vegetable Fried Rice (Chinese Buffet)', 155, 4.0, 24.0, 5.0,
 1.2, 1.0, 250, NULL,
 'chinese_buffet', ARRAY['vegetable fried rice', 'veggie fried rice', 'mixed vegetable fried rice', 'veg fried rice'],
 'asian', NULL, 1, '155 cal/100g. Fried rice with egg, mixed vegetables, soy sauce. No meat.', TRUE,
 440, 40, 1.0, 0.0, 160, 18, 1.0, 40, 4.0, 5, 14, 0.5, 60, 8.0, 0.01),

-- Pork Lo Mein: ~135 cal/100g.
('chinese_buffet_pork_lo_mein', 'Pork Lo Mein (Chinese Buffet)', 135, 6.0, 17.0, 4.8,
 0.8, 2.0, 300, NULL,
 'chinese_buffet', ARRAY['pork lo mein', 'roast pork lo mein', 'lo mein pork'],
 'asian', NULL, 1, '135 cal/100g. Soft wheat noodles stir-fried with pork, cabbage, carrots, soy sauce.', TRUE,
 490, 20, 1.2, 0.0, 100, 12, 1.5, 10, 2.0, 0, 10, 0.8, 55, 8.0, 0.02),

-- Shrimp Lo Mein: ~130 cal/100g.
('chinese_buffet_shrimp_lo_mein', 'Shrimp Lo Mein (Chinese Buffet)', 130, 6.5, 16.5, 4.5,
 0.8, 2.0, 300, NULL,
 'chinese_buffet', ARRAY['shrimp lo mein', 'prawn lo mein', 'seafood lo mein'],
 'asian', NULL, 1, '130 cal/100g. Soft wheat noodles stir-fried with shrimp, vegetables, soy sauce.', TRUE,
 500, 40, 1.0, 0.0, 120, 15, 1.4, 12, 2.5, 0, 14, 0.7, 70, 12.0, 0.04),

-- Combo Lo Mein: ~140 cal/100g.
('chinese_buffet_combo_lo_mein', 'Combo Lo Mein (Chinese Buffet)', 140, 7.0, 17.0, 5.0,
 0.8, 2.0, 300, NULL,
 'chinese_buffet', ARRAY['combo lo mein', 'house lo mein', 'special lo mein', 'combination lo mein'],
 'asian', NULL, 1, '140 cal/100g. Soft noodles with chicken, shrimp, pork, and vegetables.', TRUE,
 510, 35, 1.2, 0.0, 115, 14, 1.5, 12, 2.0, 3, 12, 0.9, 65, 10.0, 0.03),

-- Singapore Rice Noodles: ~175 cal/100g. Curry-flavored thin rice noodles.
('chinese_buffet_singapore_noodles', 'Singapore Rice Noodles (Chinese Buffet)', 175, 7.0, 22.0, 7.0,
 1.0, 1.5, 250, NULL,
 'chinese_buffet', ARRAY['singapore noodles', 'singapore rice noodles', 'singapore mei fun', 'curry rice noodles', 'singapore style noodles'],
 'asian', NULL, 1, '175 cal/100g. Thin rice vermicelli stir-fried with curry powder, shrimp, pork, vegetables.', TRUE,
 530, 45, 1.5, 0.0, 160, 18, 1.5, 15, 5.0, 3, 15, 0.8, 80, 10.0, 0.03),

-- Pan-Fried Noodles (crispy): ~200 cal/100g.
('chinese_buffet_pan_fried_noodles', 'Pan-Fried Noodles Crispy (Chinese Buffet)', 200, 5.5, 25.0, 9.0,
 1.0, 1.5, 250, NULL,
 'chinese_buffet', ARRAY['pan fried noodles', 'crispy noodles', 'hong kong style noodles', 'crispy chow mein', 'pan-fried noodles'],
 'asian', NULL, 1, '200 cal/100g. Crispy pan-fried egg noodle cake topped with meat and vegetable gravy.', TRUE,
 480, 15, 2.0, 0.1, 100, 10, 1.8, 5, 1.0, 0, 10, 0.5, 50, 8.0, 0.01),

-- ==========================================
-- SOUPS (~4 items)
-- ==========================================

-- Egg Drop Soup: USDA ~27 cal/100g. Very light.
('chinese_buffet_egg_drop_soup', 'Egg Drop Soup (Chinese Buffet)', 27, 1.2, 4.3, 0.6,
 0.0, 0.3, 250, NULL,
 'chinese_buffet', ARRAY['egg drop soup', 'egg flower soup', 'chinese egg soup', 'buffet egg drop soup'],
 'asian', NULL, 1, '27 cal/100g. ~68 cal per bowl (250g). Light broth with wispy beaten egg ribbons.', TRUE,
 370, 25, 0.2, 0.0, 40, 8, 0.3, 10, 0.0, 5, 3, 0.2, 20, 3.0, 0.01),

-- Wonton Soup: USDA ~35 cal/100g. Pork wontons in broth.
('chinese_buffet_wonton_soup', 'Wonton Soup (Chinese Buffet)', 35, 2.5, 3.5, 1.0,
 0.1, 0.3, 350, NULL,
 'chinese_buffet', ARRAY['wonton soup', 'won ton soup', 'wonton broth', 'buffet wonton soup'],
 'asian', NULL, 1, '35 cal/100g. ~123 cal per bowl (350g). Pork-filled wontons in clear chicken broth.', TRUE,
 406, 10, 0.3, 0.0, 30, 8, 0.5, 5, 0.5, 0, 4, 0.3, 18, 3.0, 0.01),

-- Hot and Sour Soup: USDA ~39 cal/100g.
('chinese_buffet_hot_sour_soup', 'Hot & Sour Soup (Chinese Buffet)', 39, 2.5, 4.0, 1.2,
 0.4, 0.5, 350, NULL,
 'chinese_buffet', ARRAY['hot and sour soup', 'hot sour soup', 'hot & sour soup', 'suan la tang'],
 'asian', NULL, 1, '39 cal/100g. ~137 cal per bowl (350g). Spicy sour broth with tofu, mushrooms, bamboo shoots, egg.', TRUE,
 480, 10, 0.3, 0.0, 50, 10, 0.6, 5, 1.0, 0, 6, 0.3, 25, 2.0, 0.01),

-- Corn Soup (Chinese style): ~55 cal/100g. Creamy egg-corn soup.
('chinese_buffet_corn_soup', 'Corn Soup Chinese Style (Chinese Buffet)', 55, 2.0, 9.0, 1.2,
 0.5, 3.0, 300, NULL,
 'chinese_buffet', ARRAY['corn soup', 'chinese corn soup', 'egg corn soup', 'cream corn soup', 'corn egg drop soup'],
 'asian', NULL, 1, '55 cal/100g. ~165 cal per bowl (300g). Creamy corn and egg soup, lightly thickened.', TRUE,
 350, 15, 0.3, 0.0, 85, 5, 0.3, 8, 2.0, 3, 10, 0.3, 30, 2.0, 0.01),

-- ==========================================
-- VEGETABLE DISHES (~6 items)
-- ==========================================

-- Mapo Tofu: ~120 cal/100g. Spicy Sichuan tofu with ground pork.
('chinese_buffet_mapo_tofu', 'Mapo Tofu (Chinese Buffet)', 120, 7.0, 5.5, 8.0,
 0.5, 1.5, 250, NULL,
 'chinese_buffet', ARRAY['mapo tofu', 'ma po tofu', 'spicy tofu', 'sichuan tofu', 'tofu with ground pork'],
 'asian', NULL, 1, '120 cal/100g. Silken tofu cubes in spicy chili-bean sauce with ground pork. Sichuan style.', TRUE,
 650, 20, 2.0, 0.0, 200, 80, 2.0, 10, 1.0, 0, 35, 1.0, 90, 6.0, 0.02),

-- Stir-Fried Green Beans (dry-fried): ~110 cal/100g.
('chinese_buffet_stir_fried_green_beans', 'Stir-Fried Green Beans (Chinese Buffet)', 110, 3.5, 8.5, 7.0,
 2.5, 2.5, 150, NULL,
 'chinese_buffet', ARRAY['stir fried green beans', 'dry fried green beans', 'szechuan green beans', 'chinese green beans', 'sauteed green beans'],
 'asian', NULL, 1, '110 cal/100g. Green beans stir-fried with garlic, chili flakes, and ground pork.', TRUE,
 420, 10, 1.2, 0.0, 200, 40, 1.0, 35, 10.0, 0, 22, 0.3, 35, 1.0, 0.02),

-- Broccoli in Garlic Sauce: ~80 cal/100g.
('chinese_buffet_broccoli_garlic', 'Broccoli in Garlic Sauce (Chinese Buffet)', 80, 3.0, 8.0, 4.0,
 2.0, 2.5, 200, NULL,
 'chinese_buffet', ARRAY['broccoli garlic sauce', 'broccoli in garlic sauce', 'garlic broccoli', 'chinese broccoli garlic'],
 'asian', NULL, 1, '80 cal/100g. Broccoli florets stir-fried in savory garlic-soy sauce.', TRUE,
 480, 0, 0.5, 0.0, 280, 45, 0.8, 30, 45.0, 0, 20, 0.4, 60, 2.0, 0.01),

-- Eggplant in Garlic Sauce: ~95 cal/100g.
('chinese_buffet_eggplant_garlic', 'Eggplant in Garlic Sauce (Chinese Buffet)', 95, 2.5, 12.0, 4.5,
 2.5, 4.0, 200, NULL,
 'chinese_buffet', ARRAY['eggplant garlic sauce', 'eggplant in garlic sauce', 'chinese eggplant', 'szechuan eggplant', 'yu xiang eggplant'],
 'asian', NULL, 1, '95 cal/100g. Fried eggplant in spicy garlic-chili sauce with scallions.', TRUE,
 520, 0, 0.8, 0.0, 220, 12, 0.5, 10, 3.0, 0, 14, 0.2, 25, 1.0, 0.01),

-- Buddha's Delight (mixed vegetables): ~60 cal/100g.
('chinese_buffet_buddhas_delight', 'Buddha''s Delight Mixed Vegetables (Chinese Buffet)', 60, 3.5, 6.0, 2.5,
 1.8, 2.0, 250, NULL,
 'chinese_buffet', ARRAY['buddha''s delight', 'buddhas delight', 'mixed vegetables chinese', 'lo han jai', 'buddhist delight', 'jai'],
 'asian', NULL, 1, '60 cal/100g. Mixed vegetables and tofu stir-fried in light sauce. Vegetarian.', TRUE,
 350, 0, 0.3, 0.0, 250, 50, 1.2, 60, 12.0, 0, 25, 0.5, 55, 2.0, 0.02),

-- Steamed Mixed Vegetables: ~35 cal/100g. Plain steamed.
('chinese_buffet_steamed_vegetables', 'Steamed Mixed Vegetables (Chinese Buffet)', 35, 2.0, 5.5, 0.5,
 2.0, 2.0, 200, NULL,
 'chinese_buffet', ARRAY['steamed vegetables', 'steamed mixed vegetables', 'chinese steamed vegetables', 'steamed veggies'],
 'asian', NULL, 1, '35 cal/100g. Plain steamed broccoli, snow peas, carrots, baby corn, mushrooms.', TRUE,
 15, 0, 0.1, 0.0, 250, 35, 0.8, 80, 20.0, 0, 18, 0.3, 40, 1.0, 0.01),

-- ==========================================
-- SUSHI BAR ITEMS (~10 items)
-- ==========================================

-- California Roll: USDA ~145 cal/100g. Imitation crab, avocado, cucumber.
('chinese_buffet_california_roll', 'California Roll (Chinese Buffet Sushi Bar)', 145, 3.5, 24.0, 4.0,
 1.5, 3.0, 180, 30,
 'chinese_buffet', ARRAY['california roll', 'cali roll', 'california maki', 'buffet california roll'],
 'asian', NULL, 6, '145 cal/100g. ~44 cal per piece (30g). Rice, nori, imitation crab, avocado, cucumber.', TRUE,
 350, 5, 0.6, 0.0, 130, 10, 0.5, 5, 2.0, 0, 12, 0.3, 30, 5.0, 0.04),

-- Spicy Tuna Roll: ~155 cal/100g. Tuna with spicy mayo.
('chinese_buffet_spicy_tuna_roll', 'Spicy Tuna Roll (Chinese Buffet Sushi Bar)', 155, 6.5, 22.0, 4.5,
 0.8, 2.5, 180, 30,
 'chinese_buffet', ARRAY['spicy tuna roll', 'spicy tuna maki', 'spicy tuna sushi', 'buffet spicy tuna roll'],
 'asian', NULL, 6, '155 cal/100g. ~47 cal per piece (30g). Sushi rice with spicy tuna and mayo.', TRUE,
 380, 15, 0.8, 0.0, 120, 8, 0.5, 30, 0.5, 15, 15, 0.3, 50, 12.0, 0.15),

-- Salmon Nigiri: ~150 cal/100g.
('chinese_buffet_salmon_nigiri', 'Salmon Nigiri (Chinese Buffet Sushi Bar)', 150, 8.0, 20.0, 4.0,
 0.3, 2.0, 60, 30,
 'chinese_buffet', ARRAY['salmon nigiri', 'salmon sushi', 'sake nigiri', 'buffet salmon nigiri'],
 'asian', NULL, 2, '150 cal/100g. ~45 cal per piece (30g). Sushi rice topped with raw salmon slice.', TRUE,
 280, 15, 0.8, 0.0, 140, 8, 0.3, 12, 0.0, 15, 14, 0.3, 90, 15.0, 0.80),

-- Shrimp Tempura Roll: ~190 cal/100g.
('chinese_buffet_shrimp_tempura_roll', 'Shrimp Tempura Roll (Chinese Buffet Sushi Bar)', 190, 5.5, 26.0, 7.0,
 0.8, 3.0, 200, 33,
 'chinese_buffet', ARRAY['shrimp tempura roll', 'tempura roll', 'ebi tempura maki', 'fried shrimp roll'],
 'asian', NULL, 6, '190 cal/100g. ~63 cal per piece (33g). Fried tempura shrimp with rice and avocado.', TRUE,
 420, 25, 1.5, 0.1, 100, 12, 0.5, 5, 1.0, 0, 12, 0.4, 50, 10.0, 0.05),

-- Philadelphia Roll: ~170 cal/100g. Cream cheese and salmon.
('chinese_buffet_philadelphia_roll', 'Philadelphia Roll (Chinese Buffet Sushi Bar)', 170, 5.5, 22.0, 6.5,
 0.5, 2.5, 180, 30,
 'chinese_buffet', ARRAY['philadelphia roll', 'philly roll', 'cream cheese roll', 'salmon cream cheese roll'],
 'asian', NULL, 6, '170 cal/100g. ~51 cal per piece (30g). Rice with smoked salmon, cream cheese, cucumber.', TRUE,
 320, 20, 3.0, 0.0, 100, 20, 0.3, 15, 0.0, 10, 10, 0.3, 50, 10.0, 0.40),

-- Rainbow Roll: ~165 cal/100g. California roll topped with assorted fish.
('chinese_buffet_rainbow_roll', 'Rainbow Roll (Chinese Buffet Sushi Bar)', 165, 6.0, 22.0, 5.5,
 1.0, 2.5, 250, 35,
 'chinese_buffet', ARRAY['rainbow roll', 'rainbow sushi roll', 'assorted fish roll'],
 'asian', NULL, 7, '165 cal/100g. ~58 cal per piece (35g). California roll topped with tuna, salmon, shrimp, avocado.', TRUE,
 340, 15, 1.0, 0.0, 150, 12, 0.5, 15, 1.5, 10, 15, 0.4, 60, 12.0, 0.30),

-- Dragon Roll: ~185 cal/100g. Shrimp tempura inside, eel and avocado on top.
('chinese_buffet_dragon_roll', 'Dragon Roll (Chinese Buffet Sushi Bar)', 185, 6.5, 24.0, 7.0,
 1.0, 4.0, 250, 35,
 'chinese_buffet', ARRAY['dragon roll', 'dragon sushi roll', 'eel avocado roll'],
 'asian', NULL, 7, '185 cal/100g. ~65 cal per piece (35g). Shrimp tempura inside, unagi eel and avocado outside.', TRUE,
 380, 30, 1.5, 0.1, 130, 15, 0.5, 80, 1.0, 5, 14, 0.5, 70, 12.0, 0.25),

-- Spider Roll: ~195 cal/100g. Soft-shell crab tempura.
('chinese_buffet_spider_roll', 'Spider Roll (Chinese Buffet Sushi Bar)', 195, 7.0, 24.0, 7.5,
 1.0, 3.0, 220, 37,
 'chinese_buffet', ARRAY['spider roll', 'soft shell crab roll', 'spider sushi roll'],
 'asian', NULL, 6, '195 cal/100g. ~72 cal per piece (37g). Fried soft-shell crab with avocado, cucumber, spicy mayo.', TRUE,
 400, 35, 1.5, 0.1, 120, 20, 0.6, 8, 1.0, 0, 18, 0.5, 65, 14.0, 0.08),

-- Eel (Unagi) Nigiri: ~180 cal/100g.
('chinese_buffet_eel_nigiri', 'Eel (Unagi) Nigiri (Chinese Buffet Sushi Bar)', 180, 7.5, 22.0, 6.5,
 0.3, 4.0, 60, 35,
 'chinese_buffet', ARRAY['eel nigiri', 'unagi nigiri', 'unagi sushi', 'freshwater eel sushi', 'eel sushi'],
 'asian', NULL, 2, '180 cal/100g. ~63 cal per piece (35g). Rice topped with grilled freshwater eel and sweet sauce.', TRUE,
 350, 55, 1.5, 0.0, 180, 15, 0.5, 100, 1.0, 5, 15, 0.5, 120, 8.0, 0.35),

-- Cucumber Roll: ~120 cal/100g. Simple vegetable roll.
('chinese_buffet_cucumber_roll', 'Cucumber Roll (Chinese Buffet Sushi Bar)', 120, 2.0, 25.0, 0.5,
 0.8, 3.0, 130, 22,
 'chinese_buffet', ARRAY['cucumber roll', 'kappa maki', 'cucumber sushi', 'veggie roll cucumber'],
 'asian', NULL, 6, '120 cal/100g. ~26 cal per piece (22g). Simple sushi rice with cucumber. Vegetarian.', TRUE,
 250, 0, 0.1, 0.0, 65, 8, 0.3, 3, 1.0, 0, 6, 0.1, 15, 1.0, 0.01),

-- ==========================================
-- DESSERTS (~8 items)
-- ==========================================

-- Fortune Cookies: USDA ~378 cal/100g.
('chinese_buffet_fortune_cookie', 'Fortune Cookies (Chinese Buffet)', 378, 4.2, 84.0, 2.0,
 0.8, 45.0, 8, 8,
 'chinese_buffet', ARRAY['fortune cookie', 'fortune cookies', 'chinese fortune cookie'],
 'asian', NULL, 2, '378 cal/100g. ~30 cal per cookie (8g). Crispy folded cookie with paper fortune inside.', TRUE,
 25, 5, 0.5, 0.0, 20, 5, 0.5, 0, 0.0, 0, 3, 0.1, 12, 2.0, 0.0),

-- Almond Cookies: ~480 cal/100g. Traditional Chinese almond cookies.
('chinese_buffet_almond_cookie', 'Almond Cookies (Chinese Buffet)', 480, 7.0, 55.0, 26.0,
 1.5, 22.0, 30, 30,
 'chinese_buffet', ARRAY['almond cookie', 'almond cookies', 'chinese almond cookie', 'almond biscuit'],
 'asian', NULL, 1, '480 cal/100g. ~144 cal per cookie (30g). Crumbly butter cookie with almond flavor.', TRUE,
 180, 30, 8.0, 0.1, 60, 20, 1.0, 15, 0.0, 3, 20, 0.5, 40, 4.0, 0.01),

-- Fried Donut Sticks (Youtiao): ~350 cal/100g. Chinese fried dough.
('chinese_buffet_youtiao', 'Fried Donut Sticks / Youtiao (Chinese Buffet)', 350, 6.0, 40.0, 18.0,
 1.0, 3.0, 60, 60,
 'chinese_buffet', ARRAY['youtiao', 'chinese donut', 'fried donut sticks', 'chinese cruller', 'you tiao', 'chinese fried dough', 'oil stick'],
 'asian', NULL, 1, '350 cal/100g. ~210 cal per piece (60g). Long golden fried dough sticks. Light and airy.', TRUE,
 380, 15, 3.5, 0.2, 55, 10, 1.5, 0, 0.0, 0, 10, 0.3, 35, 5.0, 0.01),

-- Sesame Balls (Jian Dui): ~340 cal/100g. Fried glutinous rice with red bean paste.
('chinese_buffet_sesame_balls', 'Sesame Balls / Jian Dui (Chinese Buffet)', 340, 4.0, 50.0, 14.0,
 2.0, 18.0, 45, 45,
 'chinese_buffet', ARRAY['sesame balls', 'jian dui', 'sesame seed balls', 'fried sesame balls', 'jin deui', 'glutinous rice balls'],
 'asian', NULL, 1, '340 cal/100g. ~153 cal per ball (45g). Fried glutinous rice dough with red bean paste, sesame seeds.', TRUE,
 40, 5, 2.5, 0.1, 80, 25, 1.5, 0, 0.0, 0, 15, 0.5, 30, 3.0, 0.01),

-- Mochi (assorted): ~260 cal/100g. Glutinous rice cake with filling.
('chinese_buffet_mochi', 'Mochi Assorted (Chinese Buffet)', 260, 3.5, 55.0, 3.0,
 0.5, 22.0, 45, 45,
 'chinese_buffet', ARRAY['mochi', 'mochi ice cream', 'rice cake dessert', 'glutinous rice cake', 'assorted mochi'],
 'asian', NULL, 1, '260 cal/100g. ~117 cal per piece (45g). Chewy glutinous rice cake with sweet filling.', TRUE,
 15, 5, 1.5, 0.0, 30, 10, 0.3, 3, 0.0, 0, 5, 0.2, 15, 1.0, 0.01),

-- Soft Serve Ice Cream: ~220 cal/100g. Vanilla soft serve from machine.
('chinese_buffet_soft_serve', 'Soft Serve Ice Cream (Chinese Buffet)', 220, 4.0, 33.0, 8.0,
 0.0, 22.0, 100, NULL,
 'chinese_buffet', ARRAY['soft serve ice cream', 'soft serve', 'vanilla soft serve', 'buffet ice cream', 'ice cream machine'],
 'asian', NULL, 1, '220 cal/100g. Vanilla soft serve from self-serve machine. Common at Chinese buffets.', TRUE,
 80, 30, 5.0, 0.1, 200, 130, 0.1, 65, 0.5, 22, 14, 0.5, 100, 2.0, 0.01),

-- Red Bean Bun: ~250 cal/100g. Steamed or baked bun with red bean paste.
('chinese_buffet_red_bean_bun', 'Red Bean Bun (Chinese Buffet)', 250, 6.0, 48.0, 3.5,
 3.0, 18.0, 80, 80,
 'chinese_buffet', ARRAY['red bean bun', 'red bean paste bun', 'anko bun', 'sweet bean bun', 'dou sha bao'],
 'asian', NULL, 1, '250 cal/100g. ~200 cal per bun (80g). Soft steamed bun filled with sweet red bean paste.', TRUE,
 120, 0, 0.5, 0.0, 120, 15, 1.5, 0, 0.0, 0, 20, 0.5, 50, 3.0, 0.01),

-- Fried Banana: ~240 cal/100g. Battered and fried banana slices.
('chinese_buffet_fried_banana', 'Fried Banana (Chinese Buffet)', 240, 2.0, 38.0, 9.5,
 2.0, 18.0, 80, NULL,
 'chinese_buffet', ARRAY['fried banana', 'banana fritter', 'fried banana dessert', 'battered banana', 'chinese fried banana'],
 'asian', NULL, 1, '240 cal/100g. ~192 cal per serving (80g). Battered and deep-fried banana slices with honey drizzle.', TRUE,
 25, 5, 2.0, 0.1, 300, 8, 0.5, 5, 5.0, 0, 22, 0.2, 20, 1.0, 0.02),

-- ==========================================
-- ADDITIONAL POPULAR ITEMS (~14 items)
-- ==========================================

-- Orange Chicken: USDA ~262 cal/100g. Sweet orange-glazed fried chicken.
('chinese_buffet_orange_chicken', 'Orange Chicken (Chinese Buffet)', 262, 14.5, 22.5, 12.7,
 0.3, 10.0, 200, NULL,
 'chinese_buffet', ARRAY['orange chicken', 'chinese orange chicken', 'orange peel chicken', 'mandarin chicken', 'buffet orange chicken'],
 'asian', NULL, 1, '262 cal/100g. Battered fried chicken in sweet tangy orange glaze. Very popular buffet item.', TRUE,
 450, 50, 2.8, 0.1, 170, 15, 1.0, 10, 8.0, 3, 16, 0.8, 105, 13.0, 0.02),

-- Teriyaki Chicken: ~175 cal/100g. Grilled chicken with teriyaki glaze.
('chinese_buffet_teriyaki_chicken', 'Teriyaki Chicken (Chinese Buffet)', 175, 15.0, 10.0, 8.0,
 0.2, 7.0, 200, NULL,
 'chinese_buffet', ARRAY['teriyaki chicken', 'chinese teriyaki chicken', 'buffet teriyaki chicken', 'grilled teriyaki chicken'],
 'asian', NULL, 1, '175 cal/100g. Grilled or pan-fried chicken with sweet teriyaki glaze.', TRUE,
 680, 55, 2.0, 0.0, 210, 12, 1.0, 8, 1.0, 3, 18, 0.9, 120, 14.0, 0.02),

-- Black Pepper Chicken: ~165 cal/100g. Stir-fried with onions and peppers.
('chinese_buffet_black_pepper_chicken', 'Black Pepper Chicken (Chinese Buffet)', 165, 14.0, 8.0, 8.5,
 0.8, 2.5, 200, NULL,
 'chinese_buffet', ARRAY['black pepper chicken', 'pepper chicken', 'chinese black pepper chicken'],
 'asian', NULL, 1, '165 cal/100g. Stir-fried chicken with celery, onions in black pepper sauce.', TRUE,
 560, 50, 2.0, 0.0, 240, 15, 1.2, 12, 6.0, 3, 18, 0.9, 120, 13.0, 0.02),

-- Hunan Beef: ~170 cal/100g. Spicy stir-fried beef.
('chinese_buffet_hunan_beef', 'Hunan Beef (Chinese Buffet)', 170, 13.0, 9.0, 9.5,
 1.2, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['hunan beef', 'spicy hunan beef', 'chinese hunan beef', 'hunan style beef'],
 'asian', NULL, 1, '170 cal/100g. Sliced beef stir-fried with chili peppers, garlic, vegetables in spicy Hunan sauce.', TRUE,
 600, 50, 3.2, 0.2, 290, 15, 2.3, 30, 15.0, 5, 20, 3.8, 160, 16.0, 0.03),

-- Chicken Chow Mein (crispy noodles): ~160 cal/100g.
('chinese_buffet_chicken_chow_mein', 'Chicken Chow Mein (Chinese Buffet)', 160, 8.0, 18.0, 6.5,
 1.0, 2.0, 300, NULL,
 'chinese_buffet', ARRAY['chicken chow mein', 'chow mein', 'crispy chow mein', 'chinese chow mein'],
 'asian', NULL, 1, '160 cal/100g. Crispy egg noodles topped with chicken, vegetables in thick sauce.', TRUE,
 520, 25, 1.5, 0.1, 140, 15, 1.6, 15, 3.0, 3, 12, 0.7, 60, 9.0, 0.02),

-- White Rice (steamed): ~130 cal/100g. Staple side dish.
('chinese_buffet_white_rice', 'Steamed White Rice (Chinese Buffet)', 130, 2.7, 28.0, 0.3,
 0.4, 0.0, 200, NULL,
 'chinese_buffet', ARRAY['white rice', 'steamed rice', 'plain rice', 'buffet rice', 'jasmine rice'],
 'asian', NULL, 1, '130 cal/100g. Plain steamed long-grain jasmine rice.', TRUE,
 1, 0, 0.1, 0.0, 35, 10, 0.2, 0, 0.0, 0, 12, 0.5, 43, 8.0, 0.0),

-- Szechuan Shrimp: ~145 cal/100g. Spicy stir-fried shrimp.
('chinese_buffet_szechuan_shrimp', 'Szechuan Shrimp (Chinese Buffet)', 145, 13.5, 7.0, 7.0,
 1.0, 2.5, 200, NULL,
 'chinese_buffet', ARRAY['szechuan shrimp', 'sichuan shrimp', 'spicy shrimp', 'chinese spicy shrimp'],
 'asian', NULL, 1, '145 cal/100g. Shrimp stir-fried with chili peppers, garlic, vegetables in spicy Szechuan sauce.', TRUE,
 640, 130, 1.2, 0.0, 200, 35, 1.5, 15, 8.0, 0, 28, 1.0, 170, 28.0, 0.10),

-- Crab Meat Cheese Puff: ~300 cal/100g. Puffier version of rangoon.
('chinese_buffet_cheese_puff', 'Crab Meat Cheese Puff (Chinese Buffet)', 300, 8.0, 25.0, 18.0,
 0.8, 3.0, 100, 30,
 'chinese_buffet', ARRAY['cheese puff', 'crab cheese puff', 'cream cheese puff', 'crab puff', 'cheese wonton puff'],
 'asian', NULL, 3, '300 cal/100g. ~90 cal per piece (30g). Puffed fried pastry with crab and cream cheese filling.', TRUE,
 440, 40, 7.0, 0.2, 55, 45, 0.8, 30, 0.5, 2, 8, 0.4, 50, 7.0, 0.03),

-- Walnut Shrimp: ~265 cal/100g. Similar to honey walnut but different preparation.
('chinese_buffet_szechuan_chicken', 'Szechuan Chicken (Chinese Buffet)', 180, 13.0, 10.0, 10.0,
 1.0, 3.5, 200, NULL,
 'chinese_buffet', ARRAY['szechuan chicken', 'sichuan chicken', 'spicy szechuan chicken', 'chinese spicy chicken'],
 'asian', NULL, 1, '180 cal/100g. Chicken stir-fried with dried chilies, peppercorns, garlic in numbing-spicy sauce.', TRUE,
 620, 50, 2.2, 0.0, 240, 15, 1.3, 20, 8.0, 3, 20, 1.0, 125, 14.0, 0.02),

-- Beef with Snow Peas: ~140 cal/100g. Light stir-fry.
('chinese_buffet_beef_snow_peas', 'Beef with Snow Peas (Chinese Buffet)', 140, 12.0, 7.5, 7.0,
 1.5, 2.5, 200, NULL,
 'chinese_buffet', ARRAY['beef snow peas', 'beef with snow peas', 'snow pea beef', 'beef and peapods'],
 'asian', NULL, 1, '140 cal/100g. Sliced beef stir-fried with crisp snow peas in oyster sauce.', TRUE,
 500, 40, 2.5, 0.1, 290, 25, 2.0, 20, 18.0, 5, 20, 3.5, 155, 15.0, 0.03),

-- Garlic Shrimp: ~130 cal/100g. Lighter preparation.
('chinese_buffet_garlic_shrimp', 'Garlic Shrimp (Chinese Buffet)', 130, 14.0, 5.0, 6.0,
 0.5, 1.5, 200, NULL,
 'chinese_buffet', ARRAY['garlic shrimp', 'shrimp with garlic', 'chinese garlic shrimp', 'garlic butter shrimp'],
 'asian', NULL, 1, '130 cal/100g. Shrimp stir-fried with garlic, ginger, scallions in light sauce.', TRUE,
 500, 140, 1.0, 0.0, 200, 40, 1.2, 10, 3.0, 0, 28, 1.0, 170, 30.0, 0.10),

-- Hunan Chicken: ~165 cal/100g. Spicy stir-fry.
('chinese_buffet_hunan_chicken', 'Hunan Chicken (Chinese Buffet)', 165, 13.5, 8.5, 8.5,
 1.2, 3.0, 200, NULL,
 'chinese_buffet', ARRAY['hunan chicken', 'spicy hunan chicken', 'hunan style chicken'],
 'asian', NULL, 1, '165 cal/100g. Chicken stir-fried with chili peppers, garlic, vegetables in spicy Hunan sauce.', TRUE,
 580, 45, 2.0, 0.0, 260, 15, 1.2, 25, 12.0, 3, 18, 0.9, 120, 13.0, 0.02),

-- Fried Tofu (Chinese style): ~195 cal/100g.
('chinese_buffet_fried_tofu', 'Fried Tofu (Chinese Buffet)', 195, 10.0, 8.0, 14.0,
 1.5, 1.0, 150, NULL,
 'chinese_buffet', ARRAY['fried tofu', 'deep fried tofu', 'crispy tofu', 'chinese fried tofu', 'tofu puffs'],
 'asian', NULL, 1, '195 cal/100g. Firm tofu cubes deep fried until golden, often served with sauce.', TRUE,
 280, 0, 2.0, 0.0, 180, 150, 2.5, 0, 0.0, 0, 40, 1.2, 120, 8.0, 0.02),

-- Chicken with String Beans: ~135 cal/100g.
('chinese_buffet_chicken_string_beans', 'Chicken with String Beans (Chinese Buffet)', 135, 11.0, 7.5, 7.0,
 2.0, 2.0, 200, NULL,
 'chinese_buffet', ARRAY['chicken string beans', 'chicken with string beans', 'chicken green beans', 'szechuan chicken green beans'],
 'asian', NULL, 1, '135 cal/100g. Diced chicken stir-fried with string beans in garlic-soy sauce.', TRUE,
 480, 40, 1.5, 0.0, 250, 30, 1.2, 25, 8.0, 3, 20, 0.8, 120, 12.0, 0.02)

ON CONFLICT (food_name_normalized) DO NOTHING;
