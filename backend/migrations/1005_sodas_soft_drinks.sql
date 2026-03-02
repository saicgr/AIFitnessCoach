-- 1005_sodas_soft_drinks.sql
-- Sodas, diet sodas, zero-sugar variants, sparkling waters, and common beverages
-- All values per 100ml (since these are liquids, per 100g ~ per 100ml)
-- Sources: coca-cola.com, pepsicoproductfacts.com, kdpproductfacts.com, nutritionix.com,
--          fatsecret.com, calorieking.com, myfooddiary.com, USDA FoodData Central,
--          eatthismuch.com, official brand websites

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

-- =====================================================================
-- COCA-COLA FAMILY (~15 items)
-- =====================================================================

-- Coke Zero Sugar: 12 oz (355ml) = 0 cal, 0g sugar, 40mg sodium
('coke_zero_sugar', 'Coca-Cola Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['coke zero', 'coca cola zero', 'zero sugar coke', 'coke zero sugar', 'coca-cola zero sugar'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 34mg caffeine. Sweetened with aspartame and acesulfame-K.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Cherry Coke: 12 oz (355ml) = 150 cal, 42g sugar, 40g carbs
('cherry_coke', 'Coca-Cola Cherry', 42, 0.0, 11.3, 0.0,
 0.0, 11.3, 355, NULL,
 'beverage_brand', ARRAY['cherry coca cola', 'cherry coke', 'coca cola cherry', 'coke cherry'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). 34mg caffeine. Cherry flavored cola.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Vanilla Coke: 12 oz (355ml) = 150 cal, 42g sugar
('vanilla_coke', 'Coca-Cola Vanilla', 42, 0.0, 11.8, 0.0,
 0.0, 11.8, 355, NULL,
 'beverage_brand', ARRAY['vanilla coca cola', 'vanilla coke', 'coke vanilla', 'coca cola vanilla'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). 34mg caffeine. Vanilla flavored cola.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Cherry Coke Zero: 12 oz (355ml) = 0 cal, 0g sugar, 40mg sodium
('cherry_coke_zero', 'Coca-Cola Cherry Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['cherry coke zero', 'coke zero cherry', 'diet cherry coke', 'cherry coca cola zero'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 34mg caffeine. Zero sugar cherry cola.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Coca-Cola Cherry Vanilla: 12 oz (355ml) = 150 cal, ~42g sugar
('coke_cherry_vanilla', 'Coca-Cola Cherry Vanilla', 42, 0.0, 11.5, 0.0,
 0.0, 11.5, 355, NULL,
 'beverage_brand', ARRAY['cherry vanilla coke', 'coca cola cherry vanilla', 'coke cherry vanilla'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). 34mg caffeine. Cherry vanilla flavored cola.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Coca-Cola with Coffee Dark Blend: 12 oz (355ml) = 70 cal, 18g sugar, 69mg caffeine
('coke_with_coffee', 'Coca-Cola with Coffee (Dark Blend)', 20, 0.0, 5.1, 0.0,
 0.0, 5.1, 355, NULL,
 'beverage_brand', ARRAY['coca cola coffee', 'coke coffee', 'coke with coffee', 'coca cola with coffee dark blend'],
 'beverage', NULL, 1, '70 cal per 12 oz can (355ml). 69mg caffeine. Cola blended with Brazilian coffee.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Coca-Cola with Coffee Zero Sugar: 12 oz (355ml) = 0 cal, 0g sugar
('coke_with_coffee_zero', 'Coca-Cola with Coffee Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['coke coffee zero', 'coca cola coffee zero sugar', 'coke with coffee zero'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 69mg caffeine. Zero sugar cola with coffee.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mexican Coca-Cola: 12 oz (355ml) = 150 cal, 39g sugar, made with cane sugar
('mexican_coke', 'Mexican Coca-Cola', 42, 0.0, 11.0, 0.0,
 0.0, 11.0, 355, NULL,
 'beverage_brand', ARRAY['mexican coca cola', 'mexican coke', 'coca cola mexico', 'coca cola de mexico', 'coke mexico'],
 'beverage', NULL, 1, '150 cal per 12 oz bottle (355ml). Made with real cane sugar. Glass bottle.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 17, 0, 0),

-- Coca-Cola Spiced: 12 oz (355ml) = 150 cal, 41g sugar
('coke_spiced', 'Coca-Cola Spiced', 42, 0.0, 11.5, 0.0,
 0.0, 11.5, 355, NULL,
 'beverage_brand', ARRAY['coca cola spiced', 'coke spiced', 'spiced coke', 'spiced coca cola'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). 34mg caffeine. Raspberry-spiced cola.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Coca-Cola Spiced Zero Sugar: 12 oz (355ml) = 0 cal
('coke_spiced_zero', 'Coca-Cola Spiced Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['coca cola spiced zero', 'coke spiced zero', 'spiced coke zero'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 34mg caffeine. Zero sugar raspberry-spiced cola.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Coca-Cola Starlight: 12 oz (355ml) = 150 cal, 39g sugar
('coke_starlight', 'Coca-Cola Starlight', 42, 0.0, 11.0, 0.0,
 0.0, 11.0, 355, NULL,
 'beverage_brand', ARRAY['coca cola starlight', 'coke starlight', 'starlight coke'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). Limited edition space-inspired flavor.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Diet Coke Cherry: 12 oz (355ml) = 0 cal
('diet_coke_cherry', 'Diet Coke Cherry', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['diet cherry coke', 'cherry diet coke', 'diet coke cherry'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 34mg caffeine. Diet cherry cola.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Vanilla Coke Zero: 12 oz (355ml) = 0 cal
('vanilla_coke_zero', 'Coca-Cola Vanilla Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['vanilla coke zero', 'coke zero vanilla', 'coca cola vanilla zero sugar'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 34mg caffeine. Zero sugar vanilla cola.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- =====================================================================
-- PEPSI FAMILY (~10 items)
-- =====================================================================

-- Pepsi Wild Cherry: 12 oz (355ml) = 160 cal, 42g sugar, 30mg sodium
('pepsi_wild_cherry', 'Pepsi Wild Cherry', 45, 0.0, 11.8, 0.0,
 0.0, 11.8, 355, NULL,
 'beverage_brand', ARRAY['wild cherry pepsi', 'pepsi cherry', 'cherry pepsi'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). 38mg caffeine. Cherry flavored cola.', TRUE,
 8.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Pepsi Mango: 12 oz (355ml) = 150 cal, 41g sugar, 95mg sodium
('pepsi_mango', 'Pepsi Mango', 42, 0.0, 11.5, 0.0,
 0.0, 11.5, 355, NULL,
 'beverage_brand', ARRAY['mango pepsi', 'pepsi mango flavor'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). 38mg caffeine. Mango flavored cola.', TRUE,
 26.8, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Cherry Pepsi Zero: 12 oz (355ml) = 0 cal
('pepsi_zero_cherry', 'Pepsi Zero Sugar Wild Cherry', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['cherry pepsi zero', 'pepsi zero wild cherry', 'zero sugar cherry pepsi', 'pepsi zero sugar wild cherry'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 69mg caffeine. Zero sugar cherry cola.', TRUE,
 19.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Diet Pepsi: 12 oz (355ml) = 0 cal
('diet_pepsi', 'Diet Pepsi', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['diet pepsi cola', 'pepsi diet', 'pepsi light'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 35mg caffeine. Sweetened with aspartame.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mug Root Beer: 12 oz (355ml) = 160 cal, 43g sugar
('mug_root_beer', 'Mug Root Beer', 45, 0.0, 12.1, 0.0,
 0.0, 12.1, 355, NULL,
 'beverage_brand', ARRAY['mug root beer soda', 'mug rootbeer', 'mug rb'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). Caffeine free. Classic root beer.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Mug Cream Soda: 12 oz (355ml) = 170 cal, 46g sugar
('mug_cream_soda', 'Mug Cream Soda', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['mug cream soda', 'mug cream'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). Caffeine free. Vanilla cream soda.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Starry (lemon-lime): 12 oz (355ml) = 150 cal, 39g sugar, 35mg sodium
('starry_soda', 'Starry Lemon Lime Soda', 42, 0.0, 11.3, 0.0,
 0.0, 11.0, 355, NULL,
 'beverage_brand', ARRAY['starry', 'starry soda', 'starry lemon lime', 'sierra mist replacement'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). Caffeine free. PepsiCo lemon-lime soda (replaced Sierra Mist).', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Starry Zero Sugar: 12 oz (355ml) = 0 cal
('starry_zero', 'Starry Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['starry zero', 'starry zero sugar', 'diet starry'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero sugar lemon-lime soda.', TRUE,
 16.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- DR PEPPER FAMILY (~8 items)
-- =====================================================================

-- Dr Pepper Zero Sugar: 12 oz (355ml) = 0 cal, 0g sugar
('dr_pepper_zero', 'Dr Pepper Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['dr pepper zero', 'dr. pepper zero sugar', 'zero sugar dr pepper', 'diet dr pepper zero'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 41mg caffeine. Zero sugar version of Dr Pepper.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 17, 0, 0),

-- Dr Pepper Cherry: 12 oz (355ml) = 160 cal, 42g sugar, 55mg sodium
('dr_pepper_cherry', 'Dr Pepper Cherry', 45, 0.0, 12.1, 0.0,
 0.0, 11.8, 355, NULL,
 'beverage_brand', ARRAY['cherry dr pepper', 'dr. pepper cherry', 'dr pepper cherry soda'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). 41mg caffeine. Cherry flavored Dr Pepper.', TRUE,
 15.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 17, 0, 0),

-- Dr Pepper Cream Soda: 12 oz (355ml) = 150 cal, 40g sugar
('dr_pepper_cream_soda', 'Dr Pepper & Cream Soda', 42, 0.0, 11.3, 0.0,
 0.0, 11.3, 355, NULL,
 'beverage_brand', ARRAY['dr pepper cream soda', 'dr. pepper cream soda', 'dr pepper and cream soda'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). 39mg caffeine. Dr Pepper blended with cream soda.', TRUE,
 15.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 17, 0, 0),

-- Dr Pepper Zero Sugar Cherry: 12 oz (355ml) = 0 cal
('dr_pepper_zero_cherry', 'Dr Pepper Zero Sugar Cherry', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['dr pepper zero cherry', 'dr. pepper zero sugar cherry', 'cherry dr pepper zero'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 41mg caffeine. Zero sugar cherry Dr Pepper.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 17, 0, 0),

-- Dr Pepper Zero Sugar Cream Soda: 12 oz (355ml) = 0 cal
('dr_pepper_zero_cream_soda', 'Dr Pepper & Cream Soda Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['dr pepper cream soda zero', 'dr. pepper cream soda zero sugar', 'dr pepper zero cream soda'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 39mg caffeine. Zero sugar cream soda blend.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 17, 0, 0),

-- Pibb Xtra: 12 oz (355ml) = 140 cal, 39g sugar, 40mg caffeine
('pibb_xtra', 'Pibb Xtra', 39, 0.0, 11.0, 0.0,
 0.0, 11.0, 355, NULL,
 'beverage_brand', ARRAY['pibb xtra', 'pibb extra', 'mr pibb', 'pibb soda'],
 'beverage', NULL, 1, '140 cal per 12 oz can (355ml). 40mg caffeine. Spicy cherry soda.', TRUE,
 11.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Big Red: 12 oz (355ml) = 160 cal, 44g sugar
('big_red_soda', 'Big Red', 45, 0.0, 12.4, 0.0,
 0.0, 12.4, 355, NULL,
 'beverage_brand', ARRAY['big red', 'big red soda', 'big red pop'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). Caffeine free. Red cream soda.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Big Red Zero: 12 oz (355ml) = 0 cal
('big_red_zero', 'Big Red Zero', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['big red zero', 'big red zero sugar', 'diet big red'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero sugar red cream soda.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- SPRITE / 7UP / LEMON-LIME (~8 items)
-- =====================================================================

-- Sprite Zero: 12 oz (355ml) = 0 cal, 0g sugar
('sprite_zero', 'Sprite Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['sprite zero', 'diet sprite', 'sprite zero sugar', 'sprite sugar free'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero sugar lemon-lime soda.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- 7UP: 12 oz (355ml) = 140 cal, 38g sugar, 45mg sodium
('seven_up', '7UP', 39, 0.0, 11.0, 0.0,
 0.0, 10.7, 355, NULL,
 'beverage_brand', ARRAY['7 up', '7up', 'seven up', '7-up', '7up lemon lime'],
 'beverage', NULL, 1, '140 cal per 12 oz can (355ml). Caffeine free. Lemon-lime soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- 7UP Zero Sugar: 12 oz (355ml) = 0 cal
('seven_up_zero', '7UP Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['7up zero', '7 up zero', 'diet 7up', '7up zero sugar', '7-up zero sugar'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero sugar lemon-lime soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Squirt: 12 oz (355ml) = 150 cal, 38g sugar
('squirt_soda', 'Squirt', 42, 0.0, 10.7, 0.0,
 0.0, 10.7, 355, NULL,
 'beverage_brand', ARRAY['squirt', 'squirt grapefruit soda', 'squirt citrus'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). Caffeine free. Grapefruit citrus soda.', TRUE,
 16.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Fresca: 12 oz (355ml) = 0 cal, 0g sugar
('fresca_soda', 'Fresca Original Citrus', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['fresca', 'fresca citrus', 'fresca grapefruit', 'fresca soda', 'fresca sparkling'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero calorie citrus sparkling soda.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- MOUNTAIN DEW FAMILY (~8 items)
-- =====================================================================

-- Mountain Dew Zero Sugar: 12 oz (355ml) = 0 cal
('mountain_dew_zero', 'Mountain Dew Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['mtn dew zero', 'mountain dew zero', 'mt dew zero sugar', 'mtn dew zero sugar'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 68mg caffeine. Zero sugar Mountain Dew.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Diet Mountain Dew: 12 oz (355ml) = 0 cal
('diet_mountain_dew', 'Diet Mountain Dew', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['diet mtn dew', 'diet mt dew', 'diet mountain dew soda'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 54mg caffeine. Diet version of Mountain Dew.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mountain Dew Code Red: 12 oz (355ml) = 170 cal, 46g sugar
('mountain_dew_code_red', 'Mountain Dew Code Red', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['mtn dew code red', 'code red mountain dew', 'code red mtn dew', 'mt dew code red'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). 54mg caffeine. Cherry flavored Mountain Dew.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mountain Dew Baja Blast: 12 oz (355ml) = 170 cal, 46g sugar
('mountain_dew_baja_blast', 'Mountain Dew Baja Blast', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['mtn dew baja blast', 'baja blast', 'baja blast mtn dew', 'taco bell baja blast'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). 54mg caffeine. Tropical lime Mountain Dew.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mountain Dew Voltage: 12 oz (355ml) = 170 cal, 46g sugar
('mountain_dew_voltage', 'Mountain Dew Voltage', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['mtn dew voltage', 'voltage mountain dew', 'voltage mtn dew'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). 55mg caffeine. Raspberry citrus and ginseng.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mountain Dew Major Melon: 12 oz (355ml) = 170 cal, 46g sugar
('mountain_dew_major_melon', 'Mountain Dew Major Melon', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['mtn dew major melon', 'major melon mountain dew', 'major melon mtn dew'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). 55mg caffeine. Watermelon flavored Mountain Dew.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- Mountain Dew Baja Blast Zero Sugar: 12 oz (355ml) = 10 cal
('mountain_dew_baja_blast_zero', 'Mountain Dew Baja Blast Zero Sugar', 3, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['mtn dew baja blast zero', 'baja blast zero', 'baja blast zero sugar'],
 'beverage', NULL, 1, '10 cal per 12 oz can (355ml). 54mg caffeine. Zero sugar Baja Blast.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 14, 0, 0),

-- =====================================================================
-- FANTA / FRUIT SODAS (~10 items)
-- =====================================================================

-- Fanta Orange: 12 oz (355ml) = 160 cal, 44g sugar
('fanta_orange', 'Fanta Orange', 45, 0.0, 12.4, 0.0,
 0.0, 12.1, 355, NULL,
 'beverage_brand', ARRAY['fanta orange soda', 'orange fanta', 'fanta naranja'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). Caffeine free. Orange flavored soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Fanta Grape: 12 oz (355ml) = 180 cal, 48g sugar
('fanta_grape', 'Fanta Grape', 51, 0.0, 13.5, 0.0,
 0.0, 13.5, 355, NULL,
 'beverage_brand', ARRAY['fanta grape soda', 'grape fanta', 'fanta uva'],
 'beverage', NULL, 1, '180 cal per 12 oz can (355ml). Caffeine free. Grape flavored soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Fanta Strawberry: 12 oz (355ml) = 170 cal, 46g sugar
('fanta_strawberry', 'Fanta Strawberry', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['fanta strawberry soda', 'strawberry fanta', 'fanta fresa'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). Caffeine free. Strawberry flavored soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Fanta Zero Orange: 12 oz (355ml) = 0 cal
('fanta_zero_orange', 'Fanta Zero Sugar Orange', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['fanta zero', 'fanta orange zero', 'diet fanta orange', 'fanta zero sugar orange'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero sugar orange soda.', TRUE,
 9.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Crush Orange: 12 oz (355ml) = 160 cal, 44g sugar
('crush_orange', 'Crush Orange', 45, 0.0, 12.4, 0.0,
 0.0, 12.4, 355, NULL,
 'beverage_brand', ARRAY['orange crush', 'crush orange soda', 'crush soda orange'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). Caffeine free. Orange soda.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Crush Grape: 12 oz (355ml) = 180 cal, 48g sugar
('crush_grape', 'Crush Grape', 51, 0.0, 13.5, 0.0,
 0.0, 13.5, 355, NULL,
 'beverage_brand', ARRAY['grape crush', 'crush grape soda', 'crush soda grape'],
 'beverage', NULL, 1, '180 cal per 12 oz can (355ml). Caffeine free. Grape soda.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Crush Strawberry: 12 oz (355ml) = 170 cal, 45g sugar
('crush_strawberry', 'Crush Strawberry', 48, 0.0, 12.7, 0.0,
 0.0, 12.7, 355, NULL,
 'beverage_brand', ARRAY['strawberry crush', 'crush strawberry soda', 'crush soda strawberry'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). Caffeine free. Strawberry soda.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Sunkist Orange: 12 oz (355ml) = 170 cal, 44g sugar
('sunkist_orange', 'Sunkist Orange Soda', 48, 0.0, 12.4, 0.0,
 0.0, 12.4, 355, NULL,
 'beverage_brand', ARRAY['sunkist', 'sunkist orange', 'sunkist soda', 'sunkist orange soda'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). 19mg caffeine. Orange soda.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Jarritos Mandarin: 12.5 oz (370ml) = 150 cal, 37g sugar
('jarritos_mandarin', 'Jarritos Mandarin', 41, 0.0, 10.0, 0.0,
 0.0, 10.0, 370, NULL,
 'beverage_brand', ARRAY['jarritos mandarina', 'jarritos mandarin soda', 'jarritos orange'],
 'beverage', NULL, 1, '150 cal per 12.5 oz bottle (370ml). Caffeine free. Mexican mandarin soda with real sugar.', TRUE,
 8.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Jarritos Tamarind: 12.5 oz (370ml) = 140 cal, 36g sugar
('jarritos_tamarind', 'Jarritos Tamarind', 38, 0.0, 9.7, 0.0,
 0.0, 9.7, 370, NULL,
 'beverage_brand', ARRAY['jarritos tamarindo', 'jarritos tamarind soda'],
 'beverage', NULL, 1, '140 cal per 12.5 oz bottle (370ml). Caffeine free. Mexican tamarind soda with real sugar.', TRUE,
 8.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Jarritos Guava: 12.5 oz (370ml) = 140 cal, 35g sugar
('jarritos_guava', 'Jarritos Guava', 38, 0.0, 9.5, 0.0,
 0.0, 9.5, 370, NULL,
 'beverage_brand', ARRAY['jarritos guayaba', 'jarritos guava soda'],
 'beverage', NULL, 1, '140 cal per 12.5 oz bottle (370ml). Caffeine free. Mexican guava soda with real sugar.', TRUE,
 8.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Stewart's Orange Cream: 12 oz (355ml) = 180 cal, 45g sugar
('stewarts_orange_cream', 'Stewart''s Orange ''n Cream', 51, 0.0, 12.7, 0.0,
 0.0, 12.7, 355, NULL,
 'beverage_brand', ARRAY['stewarts orange cream', 'stewart''s orange cream soda', 'stewarts orange n cream'],
 'beverage', NULL, 1, '180 cal per 12 oz bottle (355ml). Made with real sugar. Orange cream soda.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- GINGER ALE / TONIC WATER (~6 items)
-- =====================================================================

-- Schweppes Ginger Ale: 12 oz (355ml) = 120 cal, 32g sugar, 55mg sodium
('schweppes_ginger_ale', 'Schweppes Ginger Ale', 34, 0.0, 9.0, 0.0,
 0.0, 9.0, 355, NULL,
 'beverage_brand', ARRAY['schweppes ginger ale', 'schweppes ginger'],
 'beverage', NULL, 1, '120 cal per 12 oz can (355ml). Caffeine free. Classic ginger ale.', TRUE,
 15.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Schweppes Tonic Water: 12 oz (355ml) = 130 cal, 32g sugar
('schweppes_tonic_water', 'Schweppes Tonic Water', 37, 0.0, 9.0, 0.0,
 0.0, 9.0, 355, NULL,
 'beverage_brand', ARRAY['schweppes tonic', 'tonic water schweppes', 'schweppes indian tonic'],
 'beverage', NULL, 1, '130 cal per 12 oz can (355ml). Caffeine free. Contains quinine.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Diet Tonic Water: 12 oz (355ml) = 0 cal
('diet_tonic_water', 'Diet Tonic Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['diet tonic', 'zero calorie tonic water', 'sugar free tonic water', 'schweppes diet tonic'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Contains quinine. Zero calorie.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Vernor's Ginger Ale: 12 oz (355ml) = 140 cal, 38g sugar
('vernors_ginger_ale', 'Vernors Ginger Ale', 39, 0.0, 10.7, 0.0,
 0.0, 10.7, 355, NULL,
 'beverage_brand', ARRAY['vernors', 'vernors ginger soda', 'vernors ginger'],
 'beverage', NULL, 1, '140 cal per 12 oz can (355ml). Caffeine free. Bold ginger soda. Aged 3 years.', TRUE,
 15.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Fever-Tree Tonic Water: 6.8 oz (200ml) = 70 cal, 17g sugar (per 100ml: 35 cal, 8.5g sugar)
('fever_tree_tonic', 'Fever-Tree Tonic Water', 35, 0.0, 8.5, 0.0,
 0.0, 8.5, 200, NULL,
 'beverage_brand', ARRAY['fever tree tonic', 'fever-tree tonic water', 'fever tree indian tonic', 'fever tree premium tonic'],
 'beverage', NULL, 1, '70 cal per 6.8 oz bottle (200ml). Premium tonic with natural quinine from Congo.', TRUE,
 5.0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Fever-Tree Light Tonic Water: 6.8 oz (200ml) = 30 cal
('fever_tree_light_tonic', 'Fever-Tree Refreshingly Light Tonic', 15, 0.0, 3.8, 0.0,
 0.0, 3.8, 200, NULL,
 'beverage_brand', ARRAY['fever tree light tonic', 'fever-tree light tonic', 'fever tree diet tonic'],
 'beverage', NULL, 1, '30 cal per 6.8 oz bottle (200ml). Lower calorie premium tonic water.', TRUE,
 5.0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- CREAM SODAS (~4 items)
-- =====================================================================

-- A&W Cream Soda: 12 oz (355ml) = 170 cal, 46g sugar
('aw_cream_soda', 'A&W Cream Soda', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['a&w cream soda', 'aw cream soda', 'a and w cream soda'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). 29mg caffeine. Vanilla cream soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Barq's Cream Soda: 12 oz (355ml) = 170 cal, 46g sugar
('barqs_cream_soda', 'Barq''s Cream Soda', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['barqs cream soda', 'barq''s creme soda', 'barqs french vanilla cream soda'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). Caffeine free. French vanilla cream soda.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- IBC Cream Soda: 12 oz (355ml) = 180 cal, 44g sugar
('ibc_cream_soda', 'IBC Cream Soda', 51, 0.0, 12.4, 0.0,
 0.0, 12.4, 355, NULL,
 'beverage_brand', ARRAY['ibc cream soda', 'ibc cream'],
 'beverage', NULL, 1, '180 cal per 12 oz bottle (355ml). Made with cane sugar. Premium cream soda.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Jones Cream Soda: 12 oz (355ml) = 180 cal, 46g sugar
('jones_cream_soda', 'Jones Cream Soda', 51, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['jones cream soda', 'jones soda cream', 'jones vanilla cream soda'],
 'beverage', NULL, 1, '180 cal per 12 oz bottle (355ml). Made with pure cane sugar. Premium cream soda.', TRUE,
 8.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- ROOT BEER (~5 items)
-- =====================================================================

-- A&W Root Beer: 12 oz (355ml) = 170 cal, 46g sugar
('aw_root_beer', 'A&W Root Beer', 48, 0.0, 13.0, 0.0,
 0.0, 13.0, 355, NULL,
 'beverage_brand', ARRAY['a&w root beer', 'aw root beer', 'a and w root beer', 'aw rb'],
 'beverage', NULL, 1, '170 cal per 12 oz can (355ml). Caffeine free. Aged vanilla root beer.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Barq's Root Beer: 12 oz (355ml) = 160 cal, 44g sugar, 65mg sodium
('barqs_root_beer', 'Barq''s Root Beer', 45, 0.0, 12.4, 0.0,
 0.0, 12.4, 355, NULL,
 'beverage_brand', ARRAY['barqs root beer', 'barq''s root beer', 'barqs rb'],
 'beverage', NULL, 1, '160 cal per 12 oz can (355ml). 22mg caffeine. Root beer with bite.', TRUE,
 18.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- IBC Root Beer: 12 oz (355ml) = 160 cal, 43g sugar
('ibc_root_beer', 'IBC Root Beer', 45, 0.0, 12.1, 0.0,
 0.0, 12.1, 355, NULL,
 'beverage_brand', ARRAY['ibc root beer', 'ibc rb'],
 'beverage', NULL, 1, '160 cal per 12 oz bottle (355ml). Made with cane sugar. Premium root beer.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Diet A&W Root Beer: 12 oz (355ml) = 0 cal
('diet_aw_root_beer', 'A&W Root Beer Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['diet a&w root beer', 'a&w zero sugar root beer', 'diet aw root beer', 'a&w diet root beer'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free. Zero sugar root beer.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Diet Barq's Root Beer: 12 oz (355ml) = 0 cal
('diet_barqs_root_beer', 'Barq''s Root Beer Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['diet barqs root beer', 'barqs zero sugar root beer', 'barq''s diet root beer'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Caffeine free (unlike regular Barq''s). Zero sugar root beer.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- SPARKLING WATER (~15 items)
-- =====================================================================

-- LaCroix Plain: 12 oz (355ml) = 0 cal
('lacroix_plain', 'LaCroix Sparkling Water (Plain)', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['lacroix', 'la croix plain', 'lacroix pure', 'lacroix sparkling water'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Naturally essenced sparkling water. No sweeteners.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- LaCroix Lime: 12 oz (355ml) = 0 cal
('lacroix_lime', 'LaCroix Lime', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['la croix lime', 'lacroix lime sparkling water'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Lime naturally essenced sparkling water.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- LaCroix Pamplemousse: 12 oz (355ml) = 0 cal
('lacroix_pamplemousse', 'LaCroix Pamplemousse', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['la croix pamplemousse', 'lacroix grapefruit', 'lacroix pamplemousse sparkling water'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Grapefruit naturally essenced sparkling water.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- LaCroix Lemon: 12 oz (355ml) = 0 cal
('lacroix_lemon', 'LaCroix Lemon', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['la croix lemon', 'lacroix lemon sparkling water'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Lemon naturally essenced sparkling water.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Perrier Plain: 11.15 oz (330ml) = 0 cal
('perrier_plain', 'Perrier Sparkling Mineral Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 330, NULL,
 'beverage_brand', ARRAY['perrier', 'perrier sparkling water', 'perrier mineral water', 'perrier plain'],
 'beverage', NULL, 1, '0 cal per 11.15 oz bottle (330ml). Natural mineral sparkling water from France.', TRUE,
 0, 0, 0.0, 0.0, 0, 5, 0.0, 0, 0.0, 0, 1, 0.0, 0, 0, 0),

-- Perrier Lime: 11.15 oz (330ml) = 0 cal
('perrier_lime', 'Perrier Lime', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 330, NULL,
 'beverage_brand', ARRAY['perrier lime', 'perrier lime sparkling water'],
 'beverage', NULL, 1, '0 cal per 11.15 oz bottle (330ml). Natural mineral water with lime flavor.', TRUE,
 0, 0, 0.0, 0.0, 0, 5, 0.0, 0, 0.0, 0, 1, 0.0, 0, 0, 0),

-- Perrier Grapefruit: 11.15 oz (330ml) = 0 cal
('perrier_grapefruit', 'Perrier Grapefruit', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 330, NULL,
 'beverage_brand', ARRAY['perrier grapefruit', 'perrier pamplemousse', 'perrier pink grapefruit'],
 'beverage', NULL, 1, '0 cal per 11.15 oz bottle (330ml). Natural mineral water with grapefruit flavor.', TRUE,
 0, 0, 0.0, 0.0, 0, 5, 0.0, 0, 0.0, 0, 1, 0.0, 0, 0, 0),

-- San Pellegrino (plain): 16.9 oz (500ml) = 0 cal
('san_pellegrino', 'S.Pellegrino Sparkling Mineral Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 500, NULL,
 'beverage_brand', ARRAY['san pellegrino', 'san pellegrino sparkling', 's pellegrino', 'pellegrino water'],
 'beverage', NULL, 1, '0 cal per 16.9 oz bottle (500ml). Italian natural mineral sparkling water.', TRUE,
 2.0, 0, 0.0, 0.0, 0, 17.4, 0.0, 0, 0.0, 0, 5.2, 0.0, 0, 0, 0),

-- Topo Chico: 12 oz (355ml) = 0 cal
('topo_chico', 'Topo Chico Mineral Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['topo chico', 'topo chico sparkling', 'topo chico mineral water', 'topo chico water'],
 'beverage', NULL, 1, '0 cal per 12 oz bottle (355ml). Mexican mineral sparkling water.', TRUE,
 15.5, 0, 0.0, 0.0, 0, 5, 0.0, 0, 0.0, 0, 1, 0.0, 0, 0, 0),

-- Bubly Lime: 12 oz (355ml) = 0 cal
('bubly_lime', 'Bubly Lime Sparkling Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['bubly lime', 'bubly lime sparkling', 'bubly sparkling water lime'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Lime flavored sparkling water. No sweeteners.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Bubly Strawberry: 12 oz (355ml) = 0 cal
('bubly_strawberry', 'Bubly Strawberry Sparkling Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['bubly strawberry', 'bubly strawberry sparkling', 'bubly sparkling water strawberry'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Strawberry flavored sparkling water. No sweeteners.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Bubly Mango: 12 oz (355ml) = 0 cal
('bubly_mango', 'Bubly Mango Sparkling Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['bubly mango', 'bubly mango sparkling', 'bubly sparkling water mango'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Mango flavored sparkling water. No sweeteners.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- AHA Lime + Watermelon: 12 oz (355ml) = 0 cal
('aha_lime_watermelon', 'AHA Lime + Watermelon', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['aha lime watermelon', 'aha sparkling water lime watermelon', 'aha lime and watermelon'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 30mg caffeine. Lime + watermelon sparkling water.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- AHA Blueberry + Pomegranate: 12 oz (355ml) = 0 cal
('aha_blueberry_pomegranate', 'AHA Blueberry + Pomegranate', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['aha blueberry pomegranate', 'aha sparkling water blueberry pomegranate'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). 30mg caffeine. Blueberry + pomegranate sparkling water.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Waterloo Sparkling Water: 12 oz (355ml) = 0 cal
('waterloo_sparkling', 'Waterloo Sparkling Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['waterloo', 'waterloo sparkling', 'waterloo sparkling water'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Flavored sparkling water. No sweeteners or sodium.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Spindrift Lemon: 12 oz (355ml) = 3 cal, <1g sugar
('spindrift_lemon', 'Spindrift Lemon Sparkling Water', 1, 0.0, 0.3, 0.0,
 0.0, 0.1, 355, NULL,
 'beverage_brand', ARRAY['spindrift lemon', 'spindrift lemon sparkling', 'spindrift lemon water'],
 'beverage', NULL, 1, '3 cal per 12 oz can (355ml). Made with real squeezed lemon juice. No added sugar.', TRUE,
 0, 0, 0.0, 0.0, 3, 0, 0.0, 0, 1.5, 0, 0, 0.0, 0, 0, 0),

-- Spindrift Raspberry Lime: 12 oz (355ml) = 5 cal, 1g sugar
('spindrift_raspberry_lime', 'Spindrift Raspberry Lime Sparkling Water', 1, 0.0, 0.3, 0.0,
 0.0, 0.3, 355, NULL,
 'beverage_brand', ARRAY['spindrift raspberry lime', 'spindrift raspberry', 'spindrift raspberry lime sparkling'],
 'beverage', NULL, 1, '5 cal per 12 oz can (355ml). Made with real squeezed fruit. 4% juice. No added sugar.', TRUE,
 0, 0, 0.0, 0.0, 5, 0, 0.0, 0, 1.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- ICED TEA (~10 items)
-- =====================================================================

-- Brisk Lemon Iced Tea: 12 oz (355ml) = 128 cal, 33g sugar
('brisk_lemon_iced_tea', 'Brisk Lemon Iced Tea', 36, 0.0, 9.3, 0.0,
 0.0, 9.3, 355, NULL,
 'beverage_brand', ARRAY['brisk iced tea', 'brisk lemon tea', 'brisk tea lemon', 'lipton brisk'],
 'beverage', NULL, 1, '128 cal per 12 oz can (355ml). Lemon flavored iced tea.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Pure Leaf Sweet Tea: 18.5 oz (547ml) = 190 cal, 48g sugar
('pure_leaf_sweet_tea', 'Pure Leaf Sweet Tea', 35, 0.0, 8.8, 0.0,
 0.0, 8.8, 547, NULL,
 'beverage_brand', ARRAY['pure leaf sweet tea', 'pure leaf sweet', 'pure leaf sweetened tea'],
 'beverage', NULL, 1, '190 cal per 18.5 oz bottle (547ml). Real brewed black tea. Sweetened.', TRUE,
 5.5, 0, 0.0, 0.0, 14, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Pure Leaf Unsweetened: 18.5 oz (547ml) = 0 cal
('pure_leaf_unsweetened', 'Pure Leaf Unsweetened Tea', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 547, NULL,
 'beverage_brand', ARRAY['pure leaf unsweetened', 'pure leaf unsweet tea', 'pure leaf no sugar'],
 'beverage', NULL, 1, '0 cal per 18.5 oz bottle (547ml). Real brewed black tea. No sugar.', TRUE,
 4.0, 0, 0.0, 0.0, 20, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Arizona Green Tea: 23 oz (680ml) = 210 cal, 51g sugar (per 100ml: 31 cal, 7.5g sugar)
('arizona_green_tea', 'AriZona Green Tea with Ginseng and Honey', 31, 0.0, 7.5, 0.0,
 0.0, 7.5, 680, NULL,
 'beverage_brand', ARRAY['arizona green tea', 'arizona honey green tea', 'arizona iced green tea', 'arizona tea green'],
 'beverage', NULL, 1, '210 cal per 23 oz can (680ml). Green tea with ginseng and honey.', TRUE,
 4.4, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Arizona Arnold Palmer: 23 oz (680ml) = 230 cal, 54g sugar
('arizona_arnold_palmer', 'AriZona Arnold Palmer Half & Half', 34, 0.0, 7.9, 0.0,
 0.0, 7.9, 680, NULL,
 'beverage_brand', ARRAY['arnold palmer', 'arizona arnold palmer', 'arizona half and half', 'half tea half lemonade'],
 'beverage', NULL, 1, '230 cal per 23 oz can (680ml). Half iced tea, half lemonade.', TRUE,
 5.9, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.5, 0, 0, 0.0, 0, 0, 0),

-- Snapple Lemon Tea: 16 oz (473ml) = 150 cal, 37g sugar
('snapple_lemon_tea', 'Snapple Lemon Tea', 32, 0.0, 7.8, 0.0,
 0.0, 7.8, 473, NULL,
 'beverage_brand', ARRAY['snapple lemon', 'snapple lemon tea', 'snapple iced tea lemon'],
 'beverage', NULL, 1, '150 cal per 16 oz bottle (473ml). Made from the best stuff on Earth.', TRUE,
 4.2, 0, 0.0, 0.0, 10, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Gold Peak Sweet Tea: 18.5 oz (547ml) = 190 cal, 48g sugar
('gold_peak_sweet_tea', 'Gold Peak Sweet Tea', 35, 0.0, 8.8, 0.0,
 0.0, 8.8, 547, NULL,
 'beverage_brand', ARRAY['gold peak sweet', 'gold peak sweet tea', 'gold peak sweetened tea'],
 'beverage', NULL, 1, '190 cal per 18.5 oz bottle (547ml). Real brewed sweet tea.', TRUE,
 5.5, 0, 0.0, 0.0, 12, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Lipton Iced Tea: 16.9 oz (500ml) = 190 cal, 45g sugar
('lipton_iced_tea', 'Lipton Iced Tea (Lemon)', 38, 0.0, 9.0, 0.0,
 0.0, 9.0, 500, NULL,
 'beverage_brand', ARRAY['lipton iced tea', 'lipton lemon tea', 'lipton iced tea lemon'],
 'beverage', NULL, 1, '190 cal per 16.9 oz bottle (500ml). Lemon flavored sweet iced tea.', TRUE,
 8.0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Honest Tea Honey Green: 16.9 oz (500ml) = 70 cal, 19g sugar
('honest_tea_honey_green', 'Honest Tea Honey Green Tea', 14, 0.0, 3.8, 0.0,
 0.0, 3.8, 500, NULL,
 'beverage_brand', ARRAY['honest tea', 'honest tea honey green', 'honest organic honey green tea'],
 'beverage', NULL, 1, '70 cal per 16.9 oz bottle (500ml). Organic fair trade green tea with honey.', TRUE,
 2.0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Tazo Iced Tea (unsweetened): 13.8 oz (408ml) = 0 cal
('tazo_iced_tea', 'Tazo Iced Tea (Unsweetened)', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 408, NULL,
 'beverage_brand', ARRAY['tazo iced tea', 'tazo tea', 'tazo organic iced tea', 'tazo unsweetened tea'],
 'beverage', NULL, 1, '0 cal per 13.8 oz bottle (408ml). Organic unsweetened iced tea.', TRUE,
 0, 0, 0.0, 0.0, 5, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- LEMONADE (~8 items)
-- =====================================================================

-- Minute Maid Lemonade: 12 oz (355ml) = 150 cal, 42g sugar
('minute_maid_lemonade', 'Minute Maid Lemonade', 42, 0.0, 11.8, 0.0,
 0.0, 11.8, 355, NULL,
 'beverage_brand', ARRAY['minute maid lemonade', 'minute maid lemon'],
 'beverage', NULL, 1, '150 cal per 12 oz can (355ml). Classic lemonade. 10% juice.', TRUE,
 14.1, 0, 0.0, 0.0, 0, 0, 0.0, 0, 5.0, 0, 0, 0.0, 0, 0, 0),

-- Simply Lemonade: 8 oz (240ml) = 110 cal, 28g sugar
('simply_lemonade', 'Simply Lemonade', 46, 0.0, 12.1, 0.0,
 0.0, 11.7, 240, NULL,
 'beverage_brand', ARRAY['simply lemonade', 'simply lemon', 'simply lemonade original'],
 'beverage', NULL, 1, '110 cal per 8 oz serving (240ml). All natural. 11% lemon juice.', TRUE,
 4.2, 0, 0.0, 0.0, 17, 0, 0.0, 0, 10.0, 0, 0, 0.0, 0, 0, 0),

-- Country Time Lemonade: 8 oz (240ml) = 60 cal, 15g sugar (prepared from mix)
('country_time_lemonade', 'Country Time Lemonade', 25, 0.0, 6.3, 0.0,
 0.0, 6.3, 240, NULL,
 'beverage_brand', ARRAY['country time lemonade', 'country time', 'country time lemon'],
 'beverage', NULL, 1, '60 cal per 8 oz glass (240ml). Prepared from drink mix. Classic lemonade flavor.', TRUE,
 8.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 6.0, 0, 0, 0.0, 0, 0, 0),

-- Newman's Own Lemonade: 8 oz (240ml) = 110 cal, 27g sugar
('newmans_own_lemonade', 'Newman''s Own Old Fashioned Roadside Lemonade', 46, 0.0, 11.3, 0.0,
 0.0, 11.3, 240, NULL,
 'beverage_brand', ARRAY['newmans own lemonade', 'newman''s own lemonade', 'newman''s own roadside lemonade'],
 'beverage', NULL, 1, '110 cal per 8 oz serving (240ml). Old fashioned lemonade with cane sugar.', TRUE,
 0, 0, 0.0, 0.0, 17, 0, 0.0, 0, 10.0, 0, 0, 0.0, 0, 0, 0),

-- Tropicana Lemonade: 8 oz (240ml) = 120 cal, 26g sugar
('tropicana_lemonade', 'Tropicana Lemonade', 50, 0.0, 10.8, 0.0,
 0.0, 10.8, 240, NULL,
 'beverage_brand', ARRAY['tropicana lemonade', 'tropicana lemon'],
 'beverage', NULL, 1, '120 cal per 8 oz serving (240ml). Made with real lemon juice.', TRUE,
 4.2, 0, 0.0, 0.0, 8, 0, 0.0, 0, 6.0, 0, 0, 0.0, 0, 0, 0),

-- Chick-fil-A Lemonade (generic recipe): 8 oz (240ml) = 110 cal, 25g sugar
('chick_fil_a_lemonade', 'Chick-fil-A Style Lemonade', 46, 0.0, 10.4, 0.0,
 0.0, 10.4, 240, NULL,
 'beverage_brand', ARRAY['chick fil a lemonade', 'chickfila lemonade', 'chick-fil-a lemonade', 'cfa lemonade'],
 'beverage', NULL, 1, '110 cal per 8 oz (240ml). Fresh-squeezed style lemonade with cane sugar.', TRUE,
 0, 0, 0.0, 0.0, 12, 0, 0.0, 0, 15.0, 0, 0, 0.0, 0, 0, 0),

-- Hubert's Lemonade: 16 oz (473ml) = 190 cal, 46g sugar
('huberts_lemonade', 'Hubert''s Original Lemonade', 40, 0.0, 9.7, 0.0,
 0.0, 9.7, 473, NULL,
 'beverage_brand', ARRAY['huberts lemonade', 'hubert''s lemonade', 'huberts original lemonade'],
 'beverage', NULL, 1, '190 cal per 16 oz bottle (473ml). Made with real lemon juice and cane sugar.', TRUE,
 2.1, 0, 0.0, 0.0, 15, 0, 0.0, 0, 10.0, 0, 0, 0.0, 0, 0, 0),

-- Mike's Hard Lemonade (non-alc equivalent, flavoring): 11.2 oz (330ml) = 220 cal, 33g sugar
('mikes_lemonade', 'Mike''s Hard Lemonade', 67, 0.0, 10.0, 0.0,
 0.0, 10.0, 330, NULL,
 'beverage_brand', ARRAY['mikes hard lemonade', 'mike''s hard lemonade', 'mikes lemonade'],
 'beverage', NULL, 1, '220 cal per 11.2 oz bottle (330ml). Note: contains 5% ABV alcohol.', TRUE,
 3.0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- JUICE DRINKS (~10 items)
-- =====================================================================

-- Capri Sun Fruit Punch: 6 oz pouch (177ml) = 60 cal, 14g sugar
('capri_sun_fruit_punch', 'Capri Sun Fruit Punch', 34, 0.0, 7.9, 0.0,
 0.0, 7.9, 177, NULL,
 'beverage_brand', ARRAY['capri sun', 'capri sun fruit punch', 'capri sun juice', 'caprisun'],
 'beverage', NULL, 1, '60 cal per 6 oz pouch (177ml). Juice drink blend for kids.', TRUE,
 8.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Hi-C Fruit Punch: 6 oz box (177ml) = 90 cal, 23g sugar
('hic_fruit_punch', 'Hi-C Fruit Punch (Flashin'' Fruit Punch)', 51, 0.0, 13.0, 0.0,
 0.0, 13.0, 177, NULL,
 'beverage_brand', ARRAY['hi-c fruit punch', 'hi c fruit punch', 'hic', 'hi-c flashin fruit punch'],
 'beverage', NULL, 1, '90 cal per 6 oz box (177ml). 10% juice. Fruit flavored drink.', TRUE,
 8.5, 0, 0.0, 0.0, 12, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- Kool-Aid (prepared): 8 oz (240ml) = 60 cal, 16g sugar
('kool_aid', 'Kool-Aid (Prepared)', 25, 0.0, 6.7, 0.0,
 0.0, 6.7, 240, NULL,
 'beverage_brand', ARRAY['kool aid', 'kool-aid', 'koolaid', 'kool aid fruit punch', 'kool aid cherry'],
 'beverage', NULL, 1, '60 cal per 8 oz glass (240ml). Prepared from sweetened powder mix.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 6.0, 0, 0, 0.0, 0, 0, 0),

-- Hawaiian Punch: 8 oz (240ml) = 70 cal, 16g sugar
('hawaiian_punch', 'Hawaiian Punch Fruit Juicy Red', 29, 0.0, 6.7, 0.0,
 0.0, 6.7, 240, NULL,
 'beverage_brand', ARRAY['hawaiian punch', 'hawaiian punch fruit punch', 'hawaiian punch red'],
 'beverage', NULL, 1, '70 cal per 8 oz serving (240ml). 5% juice. Fruit flavored punch.', TRUE,
 12.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- Sunny D Tangy Original: 8 oz (240ml) = 60 cal, 14g sugar
('sunny_d', 'SunnyD Tangy Original', 25, 0.0, 6.3, 0.0,
 0.0, 5.8, 240, NULL,
 'beverage_brand', ARRAY['sunny d', 'sunny delight', 'sunnyd', 'sunny d tangy original', 'sunny d orange'],
 'beverage', NULL, 1, '60 cal per 8 oz serving (240ml). 2% juice. 100% DV Vitamin C per serving.', TRUE,
 8.3, 0, 0.0, 0.0, 30, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- V8 Splash: 8 oz (240ml) = 70 cal, 16g sugar
('v8_splash', 'V8 Splash Fruit Medley', 29, 0.0, 6.7, 0.0,
 0.0, 6.7, 240, NULL,
 'beverage_brand', ARRAY['v8 splash', 'v8 splash fruit medley', 'v8 splash juice'],
 'beverage', NULL, 1, '70 cal per 8 oz serving (240ml). 5% juice. Fruit medley blend.', TRUE,
 8.3, 0, 0.0, 0.0, 30, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- Ocean Spray Cranberry Juice Cocktail: 8 oz (240ml) = 110 cal, 25g sugar
('ocean_spray_cranberry', 'Ocean Spray Cranberry Juice Cocktail', 46, 0.0, 10.4, 0.0,
 0.0, 10.4, 240, NULL,
 'beverage_brand', ARRAY['ocean spray cranberry', 'ocean spray cran', 'cranberry juice cocktail', 'ocean spray juice'],
 'beverage', NULL, 1, '110 cal per 8 oz serving (240ml). 27% cranberry juice. Classic cranberry cocktail.', TRUE,
 2.1, 0, 0.0, 0.0, 12, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- Welch's Grape Juice: 8 oz (240ml) = 140 cal, 36g sugar
('welchs_grape_juice', 'Welch''s 100% Grape Juice', 58, 0.3, 15.0, 0.0,
 0.0, 15.0, 240, NULL,
 'beverage_brand', ARRAY['welchs grape juice', 'welch''s grape juice', 'welchs concord grape'],
 'beverage', NULL, 1, '140 cal per 8 oz serving (240ml). 100% juice. Concord grape juice.', TRUE,
 4.2, 0, 0.0, 0.0, 150, 10, 0.2, 0, 0.3, 0, 5, 0.0, 8, 0, 0),

-- Tampico Citrus Punch: 8 oz (240ml) = 60 cal, 15g sugar
('tampico_citrus_punch', 'Tampico Citrus Punch', 25, 0.0, 6.3, 0.0,
 0.0, 6.3, 240, NULL,
 'beverage_brand', ARRAY['tampico', 'tampico citrus', 'tampico punch', 'tampico orange drink'],
 'beverage', NULL, 1, '60 cal per 8 oz serving (240ml). 1% juice. Citrus punch drink.', TRUE,
 4.2, 0, 0.0, 0.0, 0, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- Tropicana Fruit Punch: 8 oz (240ml) = 110 cal, 28g sugar
('tropicana_fruit_punch', 'Tropicana Fruit Punch', 46, 0.0, 11.7, 0.0,
 0.0, 11.7, 240, NULL,
 'beverage_brand', ARRAY['tropicana fruit punch', 'tropicana punch'],
 'beverage', NULL, 1, '110 cal per 8 oz serving (240ml). Fruit punch juice drink.', TRUE,
 4.2, 0, 0.0, 0.0, 15, 0, 0.0, 0, 30.0, 0, 0, 0.0, 0, 0, 0),

-- =====================================================================
-- OTHER / MISCELLANEOUS (~8 items)
-- =====================================================================

-- Club Soda: 12 oz (355ml) = 0 cal
('club_soda', 'Club Soda', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['club soda', 'club soda water', 'soda water'],
 'beverage', NULL, 1, '0 cal per 12 oz can (355ml). Carbonated water with added minerals. ~75mg sodium.', TRUE,
 21.1, 0, 0.0, 0.0, 2, 5, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Seltzer Water (plain): 12 oz (355ml) = 0 cal
('seltzer_water', 'Seltzer Water (Plain)', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'beverage_brand', ARRAY['seltzer water', 'plain seltzer', 'sparkling water plain', 'carbonated water'],
 'beverage', NULL, 1, '0 cal per 12 oz (355ml). Plain carbonated water. No added minerals or flavors.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Tonic Water (generic): 12 oz (355ml) = 124 cal, 32g sugar
('tonic_water_generic', 'Tonic Water', 35, 0.0, 9.0, 0.0,
 0.0, 9.0, 355, NULL,
 'beverage_brand', ARRAY['tonic water', 'tonic', 'indian tonic water', 'quinine water'],
 'beverage', NULL, 1, '124 cal per 12 oz (355ml). Contains quinine. Carbonated sweetened mixer.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Bitter Lemon: 12 oz (355ml) = 120 cal, 30g sugar
('bitter_lemon', 'Bitter Lemon Soda', 34, 0.0, 8.5, 0.0,
 0.0, 8.5, 355, NULL,
 'beverage_brand', ARRAY['bitter lemon', 'bitter lemon soda', 'schweppes bitter lemon'],
 'beverage', NULL, 1, '120 cal per 12 oz (355ml). Carbonated lemon-flavored soda with quinine.', TRUE,
 12.7, 0, 0.0, 0.0, 0, 0, 0.0, 0, 1.0, 0, 0, 0.0, 0, 0, 0),

-- Ginger Beer: 12 oz (355ml) = 160 cal, 40g sugar
('ginger_beer', 'Ginger Beer', 45, 0.0, 11.3, 0.0,
 0.0, 11.3, 355, NULL,
 'beverage_brand', ARRAY['ginger beer', 'ginger beer soda', 'ginger beer non alcoholic', 'goslings ginger beer', 'reed''s ginger beer'],
 'beverage', NULL, 1, '160 cal per 12 oz bottle (355ml). Non-alcoholic. Stronger ginger flavor than ginger ale.', TRUE,
 8.5, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 1, 0.0, 0, 0, 0),

-- Kombucha (generic): 16 oz (473ml) = 60 cal, 8g sugar
('kombucha_generic', 'Kombucha (Generic)', 13, 0.0, 2.5, 0.0,
 0.0, 1.7, 473, NULL,
 'beverage_brand', ARRAY['kombucha', 'kombucha tea', 'gt''s kombucha', 'health ade kombucha', 'fermented tea'],
 'beverage', NULL, 1, '60 cal per 16 oz bottle (473ml). Fermented tea. Contains probiotics and B vitamins.', TRUE,
 2.1, 0, 0.0, 0.0, 15, 0, 0.1, 0, 0.0, 0, 2, 0.0, 0, 0, 0),

-- Shirley Temple (mocktail): 8 oz (240ml) = 100 cal, 24g sugar
('shirley_temple', 'Shirley Temple (Mocktail)', 42, 0.0, 10.0, 0.0,
 0.0, 10.0, 240, NULL,
 'beverage_brand', ARRAY['shirley temple', 'shirley temple drink', 'kiddie cocktail', 'mocktail shirley temple'],
 'beverage', NULL, 1, '100 cal per 8 oz glass (240ml). Ginger ale/Sprite + grenadine + cherry. Non-alcoholic.', TRUE,
 8.3, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0),

-- Italian Soda (generic): 12 oz (355ml) = 130 cal, 32g sugar
('italian_soda', 'Italian Soda', 37, 0.0, 9.0, 0.0,
 0.0, 9.0, 355, NULL,
 'beverage_brand', ARRAY['italian soda', 'italian cream soda', 'torani italian soda', 'flavored italian soda'],
 'beverage', NULL, 1, '130 cal per 12 oz glass (355ml). Sparkling water + flavored syrup. Add 50 cal for cream.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0)

ON CONFLICT (food_name_normalized) DO NOTHING;
