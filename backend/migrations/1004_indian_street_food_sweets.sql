-- 1004_indian_street_food_sweets.sql
-- Indian street food, sweets (mithai), traditional snacks, and beverages
-- All values per 100g. Sources: IFCT 2017, USDA, nutritionix, snapcalorie,
-- tarladalal.com, fatsecret.co.in, eatthismuch.com, nutribit.app, kandrafoods.com

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
-- INDIAN STREET FOOD - CHAAT (~15 items)
-- ==========================================

-- Pani Puri / Gol Gappa: ~300 cal/100g (assembled with filling and water)
('generic_pani_puri', 'Pani Puri (Gol Gappa)', 300, 5.0, 45.0, 11.0,
 2.5, 3.0, 120, 15,
 'indian_traditional', ARRAY['pani puri', 'gol gappa', 'gol gappe', 'puchka', 'gup chup', 'phuchka', 'pani ke batashe'],
 'indian', NULL, 8, 'Per 100g. 8 pieces with water ~120g = 360 cal. Crispy hollow puris filled with spiced potato and tangy water.', TRUE,
 380, 0, 2.0, 0.5, 180, 15, 1.5, 5, 8, 0, 15, 0.5, 50, 2, 0.01),

-- Bhel Puri: ~270 cal/100g
('generic_bhel_puri', 'Bhel Puri', 270, 5.5, 40.0, 10.0,
 3.0, 4.0, 150, NULL,
 'indian_traditional', ARRAY['bhel puri', 'bhel', 'jhaal muri', 'bhelpuri', 'bhel poori'],
 'indian', NULL, 1, 'Per 100g. Serving ~150g = 405 cal. Puffed rice tossed with sev, onion, tomato, chutneys.', TRUE,
 350, 0, 1.5, 0.3, 200, 18, 1.8, 8, 10, 0, 20, 0.6, 55, 3, 0.01),

-- Sev Puri: ~310 cal/100g
('generic_sev_puri', 'Sev Puri', 310, 5.0, 38.0, 15.0,
 2.5, 5.0, 120, 20,
 'indian_traditional', ARRAY['sev puri', 'sev poori', 'sevpuri'],
 'indian', NULL, 6, 'Per 100g. 6 pieces ~120g = 372 cal. Flat puris topped with potato, onion, chutneys, sev.', TRUE,
 400, 0, 3.0, 0.5, 170, 15, 1.5, 8, 8, 0, 15, 0.5, 45, 2, 0.01),

-- Dahi Puri: ~240 cal/100g
('generic_dahi_puri', 'Dahi Puri', 240, 5.5, 32.0, 10.0,
 2.0, 6.0, 120, 20,
 'indian_traditional', ARRAY['dahi puri', 'dahi poori', 'dahi batasha', 'curd puri'],
 'indian', NULL, 6, 'Per 100g. 6 pieces ~120g = 288 cal. Puris filled with potato, topped with yogurt and chutneys.', TRUE,
 320, 5, 2.5, 0.3, 180, 50, 1.2, 10, 6, 1, 14, 0.5, 55, 2, 0.01),

-- Ragda Pattice: ~175 cal/100g
('generic_ragda_pattice', 'Ragda Pattice', 175, 5.0, 25.0, 6.0,
 3.0, 3.0, 250, NULL,
 'indian_traditional', ARRAY['ragda pattice', 'ragda patties', 'ragda patis', 'ragada pattice'],
 'indian', NULL, 1, 'Per 100g. Serving ~250g = 438 cal. Crispy potato patties topped with white pea curry and chutneys.', TRUE,
 350, 0, 1.0, 0.1, 280, 20, 2.0, 5, 8, 0, 22, 0.6, 60, 3, 0.02),

-- Aloo Tikki Chaat: ~185 cal/100g
('generic_aloo_tikki_chaat', 'Aloo Tikki Chaat', 185, 4.0, 24.0, 8.0,
 2.5, 4.0, 200, 80,
 'indian_traditional', ARRAY['aloo tikki chaat', 'aloo tikki', 'tikki chaat', 'potato tikki chaat'],
 'indian', NULL, 1, 'Per 100g. Serving ~200g = 370 cal. Spiced potato patties with yogurt, chutneys, and sev.', TRUE,
 380, 5, 1.5, 0.2, 300, 30, 1.5, 8, 10, 1, 20, 0.5, 50, 2, 0.01),

-- Papdi Chaat: ~280 cal/100g
('generic_papdi_chaat', 'Papdi Chaat', 280, 5.0, 35.0, 13.0,
 2.5, 5.0, 150, NULL,
 'indian_traditional', ARRAY['papdi chaat', 'papri chaat', 'papdi chat', 'dahi papdi chaat'],
 'indian', NULL, 1, 'Per 100g. Serving ~150g = 420 cal. Fried flour crisps with potato, chickpeas, yogurt, chutneys.', TRUE,
 380, 5, 3.0, 0.5, 180, 40, 1.5, 8, 6, 1, 15, 0.5, 50, 2, 0.01),

-- Kachori Chaat: ~290 cal/100g
('generic_kachori_chaat', 'Kachori Chaat', 290, 6.0, 32.0, 15.0,
 3.0, 4.0, 200, 60,
 'indian_traditional', ARRAY['kachori chaat', 'kachori chat', 'dal kachori chaat'],
 'indian', NULL, 1, 'Per 100g. Serving ~200g = 580 cal. Fried pastry with lentil filling, topped with chutneys and yogurt.', TRUE,
 400, 5, 3.0, 0.5, 200, 25, 2.0, 5, 6, 0, 18, 0.6, 60, 3, 0.02),

-- Dahi Bhalla / Dahi Vada: ~155 cal/100g
('generic_dahi_bhalla', 'Dahi Bhalla (Dahi Vada)', 155, 5.5, 18.0, 6.5,
 1.5, 5.0, 200, 50,
 'indian_traditional', ARRAY['dahi bhalla', 'dahi vada', 'dahi bhalle', 'dahi wade', 'doi bora', 'thayir vadai'],
 'indian', NULL, 1, 'Per 100g. Serving ~200g = 310 cal. Fried lentil dumplings soaked in yogurt with chutneys.', TRUE,
 350, 8, 1.5, 0.1, 200, 55, 1.5, 10, 5, 2, 15, 0.5, 60, 3, 0.01),

-- Aloo Chaat (dry): ~200 cal/100g
('generic_aloo_chaat_dry', 'Aloo Chaat (Dry)', 200, 3.0, 28.0, 9.0,
 2.5, 2.0, 150, NULL,
 'indian_traditional', ARRAY['aloo chaat', 'aloo chat', 'dry aloo chaat', 'potato chaat', 'alu chaat'],
 'indian', NULL, 1, 'Per 100g. Serving ~150g = 300 cal. Fried potato cubes tossed with spices, lemon, chaat masala.', TRUE,
 380, 0, 1.5, 0.3, 320, 12, 1.2, 3, 12, 0, 18, 0.4, 40, 2, 0.01),

-- Raj Kachori: ~200 cal/100g
('generic_raj_kachori', 'Raj Kachori', 200, 6.0, 25.0, 8.5,
 2.5, 4.0, 150, 150,
 'indian_traditional', ARRAY['raj kachori', 'raj kachori chaat', 'tokri chaat', 'basket chaat'],
 'indian', NULL, 1, 'Per 100g. One piece ~150g = 300 cal. Large crispy kachori shell filled with potato, chickpeas, yogurt, chutneys.', TRUE,
 420, 8, 2.0, 0.3, 250, 35, 2.0, 8, 8, 1, 20, 0.6, 65, 3, 0.02),

-- Chole Kulche (street): ~220 cal/100g
('generic_chole_kulche', 'Chole Kulche (Street Style)', 220, 7.0, 32.0, 7.0,
 4.0, 2.5, 300, NULL,
 'indian_traditional', ARRAY['chole kulche', 'chole kulcha', 'chhole kulche', 'kulche chole', 'amritsari chole kulche'],
 'indian', NULL, 1, 'Per 100g. Serving ~300g = 660 cal. Spiced chickpea curry with soft leavened bread.', TRUE,
 450, 0, 1.5, 0.1, 280, 40, 2.5, 5, 3, 0, 30, 1.0, 80, 4, 0.02),

-- Masala Corn Cup: ~130 cal/100g
('generic_masala_corn_cup', 'Masala Corn Cup (Chaat Masala)', 130, 3.5, 22.0, 3.5,
 2.5, 3.0, 120, NULL,
 'indian_traditional', ARRAY['masala corn cup', 'corn chaat', 'butter corn cup', 'sweet corn chaat', 'masala corn'],
 'indian', NULL, 1, 'Per 100g. Cup ~120g = 156 cal. Boiled sweet corn with butter, lime, chaat masala.', TRUE,
 250, 5, 1.5, 0.1, 260, 5, 0.5, 10, 6, 0, 30, 0.5, 80, 1, 0.01),

-- Masala Peanuts (street): ~540 cal/100g
('generic_masala_peanuts', 'Masala Peanuts (Street Style)', 540, 22.0, 25.0, 40.0,
 5.0, 3.0, 50, NULL,
 'indian_traditional', ARRAY['masala peanuts', 'masala moongphali', 'spicy peanuts', 'chaat peanuts', 'masala groundnut'],
 'indian', NULL, 1, 'Per 100g. Handful ~50g = 270 cal. Roasted peanuts coated with spiced besan batter and fried.', TRUE,
 400, 0, 6.0, 0.1, 550, 40, 2.0, 2, 1, 0, 100, 2.5, 250, 5, 0.02),

-- ==========================================
-- INDIAN STREET FOOD - ROLLS/WRAPS (~5 items)
-- ==========================================

-- Kolkata Egg Roll: ~210 cal/100g
('generic_kolkata_egg_roll', 'Kolkata Egg Roll', 210, 8.5, 25.0, 8.5,
 1.5, 2.0, 200, 200,
 'indian_traditional', ARRAY['egg roll', 'kolkata egg roll', 'anda roll', 'egg kathi roll', 'dim roll'],
 'indian', NULL, 1, 'Per 100g. One roll ~200g = 420 cal. Paratha wrap with egg, onion, green chutney, lemon.', TRUE,
 420, 120, 2.5, 0.2, 180, 30, 1.5, 50, 5, 10, 15, 0.8, 90, 10, 0.03),

-- Kolkata Chicken Roll: ~230 cal/100g
('generic_kolkata_chicken_roll', 'Kolkata Chicken Roll', 230, 12.0, 22.0, 10.0,
 1.5, 2.0, 220, 220,
 'indian_traditional', ARRAY['chicken roll', 'kolkata chicken roll', 'chicken kathi roll', 'murgh roll'],
 'indian', NULL, 1, 'Per 100g. One roll ~220g = 506 cal. Paratha wrap with spiced chicken, onion, chutney.', TRUE,
 450, 45, 3.0, 0.2, 220, 25, 1.5, 15, 4, 3, 20, 1.2, 120, 12, 0.04),

-- Paneer Roll: ~240 cal/100g
('generic_paneer_roll', 'Paneer Roll', 240, 10.0, 24.0, 12.0,
 1.5, 2.0, 200, 200,
 'indian_traditional', ARRAY['paneer roll', 'paneer kathi roll', 'paneer tikka roll', 'paneer wrap'],
 'indian', NULL, 1, 'Per 100g. One roll ~200g = 480 cal. Paratha wrap with spiced paneer tikka, onion, chutney.', TRUE,
 400, 20, 5.0, 0.2, 150, 80, 1.2, 30, 3, 2, 18, 1.0, 100, 8, 0.02),

-- Frankie (Bombay): ~225 cal/100g
('generic_bombay_frankie', 'Frankie (Bombay Style)', 225, 7.0, 28.0, 9.5,
 2.0, 2.5, 200, 200,
 'indian_traditional', ARRAY['frankie', 'bombay frankie', 'veg frankie', 'mumbai frankie', 'frankie roll'],
 'indian', NULL, 1, 'Per 100g. One frankie ~200g = 450 cal. Chapati wrap with spiced potato/paneer filling, schezwan sauce.', TRUE,
 400, 10, 2.0, 0.2, 200, 30, 1.5, 10, 5, 0, 18, 0.6, 60, 3, 0.01),

-- ==========================================
-- INDIAN STREET FOOD - FRIED (~14 items)
-- ==========================================

-- Onion Pakora: ~275 cal/100g
('generic_onion_pakora', 'Onion Pakora (Pyaz Pakoda)', 275, 6.5, 28.0, 15.0,
 3.0, 2.5, 100, 25,
 'indian_traditional', ARRAY['onion pakora', 'pyaz pakoda', 'kanda bhaji', 'onion bhaji', 'onion pakoda', 'pyaz ke pakode'],
 'indian', NULL, 4, 'Per 100g. 4 pieces ~100g = 275 cal. Sliced onion in spiced chickpea flour batter, deep-fried.', TRUE,
 380, 5, 2.5, 0.3, 200, 25, 2.0, 8, 5, 0, 20, 0.6, 60, 3, 0.02),

-- Potato Pakora: ~290 cal/100g
('generic_potato_pakora', 'Potato Pakora (Aloo Pakoda)', 290, 5.0, 30.0, 16.0,
 2.5, 1.5, 100, 30,
 'indian_traditional', ARRAY['potato pakora', 'aloo pakoda', 'aloo pakora', 'aloo bhaji', 'batata bhaji'],
 'indian', NULL, 4, 'Per 100g. 4 pieces ~100g = 290 cal. Potato slices in spiced besan batter, deep-fried.', TRUE,
 370, 0, 2.5, 0.4, 300, 20, 1.5, 5, 8, 0, 18, 0.4, 50, 2, 0.01),

-- Palak (Spinach) Pakora: ~260 cal/100g
('generic_palak_pakora', 'Palak Pakora (Spinach Pakoda)', 260, 7.0, 25.0, 15.0,
 3.5, 1.5, 100, 20,
 'indian_traditional', ARRAY['palak pakora', 'spinach pakoda', 'palak pakoda', 'spinach fritter'],
 'indian', NULL, 5, 'Per 100g. 5 pieces ~100g = 260 cal. Spinach leaves in spiced besan batter, deep-fried.', TRUE,
 350, 5, 2.5, 0.3, 350, 60, 3.0, 200, 12, 0, 40, 0.8, 65, 3, 0.02),

-- Paneer Pakora: ~310 cal/100g
('generic_paneer_pakora', 'Paneer Pakora', 310, 12.0, 20.0, 20.0,
 1.5, 1.5, 100, 30,
 'indian_traditional', ARRAY['paneer pakora', 'paneer pakoda', 'paneer bhaji', 'cottage cheese fritter'],
 'indian', NULL, 4, 'Per 100g. 4 pieces ~100g = 310 cal. Paneer cubes in spiced besan batter, deep-fried.', TRUE,
 350, 25, 7.0, 0.3, 130, 120, 1.5, 25, 2, 3, 15, 1.0, 100, 5, 0.02),

-- Bread Pakora: ~320 cal/100g
('generic_bread_pakora', 'Bread Pakora', 320, 7.0, 35.0, 16.5,
 2.0, 2.5, 120, 60,
 'indian_traditional', ARRAY['bread pakora', 'bread pakoda', 'stuffed bread pakora', 'bread bhaji'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~120g = 384 cal. Bread stuffed with potato, dipped in besan batter, deep-fried.', TRUE,
 450, 5, 3.0, 0.5, 180, 25, 2.0, 5, 3, 0, 15, 0.5, 55, 3, 0.02),

-- Gobi Pakora: ~265 cal/100g
('generic_gobi_pakora', 'Gobi Pakora (Cauliflower Pakoda)', 265, 6.0, 26.0, 15.0,
 3.0, 2.0, 100, 25,
 'indian_traditional', ARRAY['gobi pakora', 'cauliflower pakora', 'gobi pakoda', 'phool gobi pakora'],
 'indian', NULL, 4, 'Per 100g. 4 pieces ~100g = 265 cal. Cauliflower florets in spiced besan batter, deep-fried.', TRUE,
 360, 5, 2.5, 0.3, 250, 25, 1.5, 5, 20, 0, 15, 0.5, 50, 2, 0.01),

-- Mysore Bonda / Aloo Bonda: ~250 cal/100g
('generic_aloo_bonda', 'Aloo Bonda (Mysore Bonda)', 250, 5.0, 30.0, 12.0,
 2.5, 1.5, 120, 40,
 'indian_traditional', ARRAY['aloo bonda', 'mysore bonda', 'batata vada', 'bonda', 'potato bonda', 'goli baje'],
 'indian', NULL, 3, 'Per 100g. 3 pieces ~120g = 300 cal. Spiced potato ball in besan batter, deep-fried.', TRUE,
 380, 0, 2.0, 0.3, 280, 20, 1.5, 5, 6, 0, 18, 0.5, 55, 2, 0.01),

-- Mirchi Bajji: ~240 cal/100g
('generic_mirchi_bajji', 'Mirchi Bajji (Chilli Fritters)', 240, 4.5, 28.0, 12.5,
 3.0, 2.0, 100, 50,
 'indian_traditional', ARRAY['mirchi bajji', 'mirchi pakora', 'mirchi bhaji', 'stuffed chilli fritter', 'bharwan mirch pakora', 'milagai bajji'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~100g = 240 cal. Large green chillies stuffed with potato, batter-fried.', TRUE,
 350, 0, 2.0, 0.3, 200, 15, 1.5, 30, 40, 0, 15, 0.4, 40, 2, 0.01),

-- Veg Cutlet: ~220 cal/100g
('generic_veg_cutlet', 'Veg Cutlet (Indian)', 220, 4.5, 26.0, 11.0,
 3.0, 2.0, 120, 60,
 'indian_traditional', ARRAY['veg cutlet', 'vegetable cutlet', 'mixed veg cutlet', 'sabzi cutlet'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~120g = 264 cal. Mixed vegetable patties coated in breadcrumbs, shallow-fried.', TRUE,
 380, 5, 2.0, 0.2, 250, 20, 1.5, 40, 8, 0, 18, 0.5, 50, 2, 0.01),

-- Egg Puff: ~300 cal/100g
('generic_egg_puff', 'Egg Puff (Indian Bakery)', 300, 8.0, 25.0, 18.0,
 0.8, 2.0, 100, 100,
 'indian_traditional', ARRAY['egg puff', 'egg patty', 'anda puff', 'egg puff pastry'],
 'indian', NULL, 1, 'Per 100g. One piece ~100g = 300 cal. Flaky puff pastry with spiced egg filling.', TRUE,
 400, 130, 8.0, 0.5, 120, 25, 1.8, 45, 1, 12, 12, 0.8, 80, 12, 0.03),

-- Chicken Puff: ~270 cal/100g
('generic_chicken_puff', 'Chicken Puff (Indian Bakery)', 270, 10.0, 22.0, 16.0,
 0.8, 1.5, 100, 100,
 'indian_traditional', ARRAY['chicken puff', 'chicken patty', 'murgh puff', 'chicken puff pastry'],
 'indian', NULL, 1, 'Per 100g. One piece ~100g = 270 cal. Flaky puff pastry with spiced minced chicken filling.', TRUE,
 420, 35, 7.0, 0.5, 150, 20, 1.5, 10, 1, 3, 15, 1.0, 100, 14, 0.04),

-- Veg Momos (steamed): ~150 cal/100g
('generic_veg_momos', 'Veg Momos (Steamed)', 150, 5.0, 24.0, 3.5,
 2.0, 1.5, 120, 20,
 'indian_traditional', ARRAY['veg momos', 'veg momo', 'vegetable momos', 'steamed veg momos', 'veg dim sum'],
 'indian', NULL, 6, 'Per 100g. 6 pieces ~120g = 180 cal. Steamed dumplings with cabbage, carrot, spring onion filling.', TRUE,
 350, 0, 0.5, 0.1, 150, 20, 1.0, 30, 5, 0, 12, 0.4, 40, 2, 0.01),

-- Chicken Momos (steamed): ~170 cal/100g
('generic_chicken_momos', 'Chicken Momos (Steamed)', 170, 10.0, 18.0, 6.0,
 1.0, 1.0, 120, 25,
 'indian_traditional', ARRAY['chicken momos', 'chicken momo', 'steamed chicken momos', 'chicken dim sum'],
 'indian', NULL, 5, 'Per 100g. 5 pieces ~120g = 204 cal. Steamed dumplings with minced chicken and vegetable filling.', TRUE,
 380, 30, 1.5, 0.1, 180, 15, 1.2, 8, 3, 3, 15, 1.0, 90, 10, 0.03),

-- ==========================================
-- INDIAN STREET FOOD - GRILLED (~3 items)
-- ==========================================

-- Bhutta (Roasted Corn on Cob): ~110 cal/100g
('generic_bhutta', 'Bhutta (Roasted Corn on Cob)', 110, 3.5, 20.0, 2.0,
 2.5, 3.5, 150, 150,
 'indian_traditional', ARRAY['bhutta', 'roasted corn', 'masala bhutta', 'corn on cob Indian', 'bhutta masala'],
 'indian', NULL, 1, 'Per 100g. One cob ~150g = 165 cal. Roasted street corn with lime, salt, chilli powder.', TRUE,
 30, 0, 0.3, 0.0, 270, 5, 0.5, 10, 6, 0, 30, 0.5, 80, 1, 0.01),

-- Tandoori Corn: ~130 cal/100g
('generic_tandoori_corn', 'Tandoori Corn', 130, 3.5, 18.0, 5.0,
 2.5, 3.5, 150, 150,
 'indian_traditional', ARRAY['tandoori corn', 'tandoori bhutta', 'grilled masala corn'],
 'indian', NULL, 1, 'Per 100g. One cob ~150g = 195 cal. Corn coated with tandoori spice yogurt marinade, grilled.', TRUE,
 200, 3, 1.5, 0.0, 280, 20, 0.6, 15, 6, 0, 30, 0.5, 85, 1, 0.01),

-- Paneer Tikka (street style): ~220 cal/100g
('generic_paneer_tikka_street', 'Paneer Tikka (Street Style)', 220, 14.0, 6.0, 16.0,
 1.0, 2.0, 120, NULL,
 'indian_traditional', ARRAY['paneer tikka', 'paneer tikka street style', 'grilled paneer', 'tandoori paneer'],
 'indian', NULL, 1, 'Per 100g. Serving ~120g = 264 cal. Marinated paneer cubes grilled on skewers with peppers and onion.', TRUE,
 350, 30, 8.0, 0.1, 120, 200, 1.0, 40, 10, 3, 20, 1.2, 150, 5, 0.02),

-- ==========================================
-- INDIAN STREET FOOD - OTHER (~2 items)
-- ==========================================

-- Kulfi Falooda: ~190 cal/100g
('generic_kulfi_falooda', 'Kulfi Falooda', 190, 5.0, 25.0, 8.0,
 0.5, 20.0, 200, NULL,
 'indian_traditional', ARRAY['kulfi falooda', 'falooda kulfi', 'kulfi with falooda', 'matka kulfi falooda'],
 'indian', NULL, 1, 'Per 100g. Glass ~200g = 380 cal. Dense Indian ice cream with vermicelli, basil seeds, rose syrup.', TRUE,
 50, 15, 5.0, 0.1, 150, 80, 0.5, 20, 1, 5, 15, 0.5, 80, 3, 0.02),

-- Kachori (plain, fried): ~400 cal/100g
('generic_kachori_plain', 'Kachori (Plain/Dal)', 400, 8.0, 40.0, 22.0,
 3.0, 2.0, 60, 60,
 'indian_traditional', ARRAY['kachori', 'dal kachori', 'moong dal kachori', 'urad dal kachori', 'khasta kachori'],
 'indian', NULL, 1, 'Per 100g. One piece ~60g = 240 cal. Flaky deep-fried pastry with spiced lentil filling.', TRUE,
 400, 5, 4.0, 0.5, 200, 25, 2.5, 5, 2, 0, 25, 0.8, 80, 4, 0.02),

-- ==========================================
-- INDIAN SWEETS / MITHAI - MILK BASED (~15 items)
-- ==========================================

-- Rasmalai: ~200 cal/100g
('generic_rasmalai', 'Rasmalai', 200, 6.0, 25.0, 8.0,
 0.0, 22.0, 120, 60,
 'indian_traditional', ARRAY['rasmalai', 'ras malai', 'rossomalai', 'roshmalai'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~120g = 240 cal. Soft paneer discs soaked in sweetened saffron-cardamom milk.', TRUE,
 45, 15, 5.0, 0.1, 120, 90, 0.3, 25, 0.5, 5, 10, 0.5, 80, 3, 0.01),

-- Rabri / Rabdi: ~200 cal/100g
('generic_rabri', 'Rabri (Rabdi)', 200, 5.0, 24.0, 9.5,
 0.0, 22.0, 100, NULL,
 'indian_traditional', ARRAY['rabri', 'rabdi', 'rabari', 'lachhedar rabri'],
 'indian', NULL, 1, 'Per 100g. Serving ~100g = 200 cal. Thickened sweetened milk with layers of cream, cardamom, saffron.', TRUE,
 50, 25, 6.0, 0.1, 140, 100, 0.3, 30, 0.5, 8, 12, 0.5, 80, 3, 0.01),

-- Malpua with Rabri: ~350 cal/100g
('generic_malpua', 'Malpua (with Rabri)', 350, 5.0, 45.0, 16.0,
 1.0, 30.0, 120, 60,
 'indian_traditional', ARRAY['malpua', 'malpua with rabri', 'malpura', 'malpoa', 'malapua'],
 'indian', NULL, 2, 'Per 100g. 2 pieces with rabri ~120g = 420 cal. Fried sweet pancakes soaked in syrup, topped with rabri.', TRUE,
 40, 20, 4.0, 0.3, 120, 60, 1.0, 15, 0.3, 3, 10, 0.4, 55, 3, 0.01),

-- Khoya Barfi: ~380 cal/100g
('generic_khoya_barfi', 'Khoya Barfi', 380, 8.0, 42.0, 20.0,
 0.3, 35.0, 50, 25,
 'indian_traditional', ARRAY['khoya barfi', 'mawa barfi', 'khoa barfi', 'khoya burfi', 'mawa burfi'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~50g = 190 cal. Dense fudge made from reduced milk solids with sugar and cardamom.', TRUE,
 40, 20, 12.0, 0.1, 140, 80, 0.5, 25, 0.3, 5, 12, 0.5, 80, 3, 0.01),

-- Kalakand: ~330 cal/100g
('generic_kalakand', 'Kalakand', 330, 7.0, 40.0, 15.0,
 0.2, 35.0, 50, 25,
 'indian_traditional', ARRAY['kalakand', 'milk cake', 'kalakan', 'karachihalwa kalakand'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~50g = 165 cal. Grainy milk fudge made from curdled milk and sugar.', TRUE,
 40, 15, 9.0, 0.1, 130, 90, 0.3, 20, 0.3, 5, 10, 0.4, 75, 3, 0.01),

-- Milk Cake (Indian): ~350 cal/100g
('generic_milk_cake', 'Milk Cake (Indian Sweet)', 350, 7.5, 43.0, 16.0,
 0.0, 38.0, 50, 25,
 'indian_traditional', ARRAY['milk cake', 'Alwar ka milk cake', 'doodh cake', 'Indian milk cake'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~50g = 175 cal. Caramelized condensed milk sweet, brownish with grainy texture.', TRUE,
 45, 18, 10.0, 0.1, 130, 85, 0.3, 22, 0.2, 5, 10, 0.4, 75, 3, 0.01),

-- Cham Cham: ~277 cal/100g
('generic_cham_cham', 'Cham Cham (Chum Chum)', 277, 6.0, 45.0, 8.0,
 0.0, 40.0, 80, 40,
 'indian_traditional', ARRAY['cham cham', 'chum chum', 'chom chom', 'chumchum'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~80g = 222 cal. Oblong cottage cheese sweet soaked in syrup, coated with cream.', TRUE,
 35, 10, 5.0, 0.1, 80, 50, 0.3, 10, 0.2, 3, 8, 0.3, 45, 2, 0.01),

-- Pantua: ~340 cal/100g
('generic_pantua', 'Pantua (Bengali Sweet)', 340, 4.5, 48.0, 14.5,
 0.2, 42.0, 80, 40,
 'indian_traditional', ARRAY['pantua', 'ledikeni', 'langcha', 'bengali gulab jamun'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~80g = 272 cal. Deep-fried Bengali cottage cheese balls in sugar syrup, darker than gulab jamun.', TRUE,
 35, 12, 7.0, 0.2, 70, 30, 0.5, 10, 0.2, 2, 6, 0.3, 35, 2, 0.01),

-- Doodh Peda (Mathura style): ~390 cal/100g
('generic_doodh_peda', 'Doodh Peda (Mathura Style)', 390, 8.5, 45.0, 19.0,
 0.2, 40.0, 40, 20,
 'indian_traditional', ARRAY['doodh peda', 'mathura peda', 'mathura ka peda', 'milk peda'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 156 cal. Dense milk fudge from Mathura, golden-brown with caramelized flavor.', TRUE,
 35, 18, 12.0, 0.1, 140, 95, 0.4, 28, 0.3, 5, 12, 0.5, 85, 3, 0.01),

-- Imarti / Jangiri: ~360 cal/100g
('generic_imarti', 'Imarti (Jangiri)', 360, 5.0, 52.0, 15.0,
 1.0, 38.0, 60, 30,
 'indian_traditional', ARRAY['imarti', 'jangiri', 'jangri', 'amriti', 'jhangri'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~60g = 216 cal. Flower-shaped urad dal batter fried and soaked in sugar syrup.', TRUE,
 30, 5, 3.0, 0.3, 120, 15, 1.5, 3, 0.2, 0, 12, 0.5, 50, 3, 0.01),

-- Mawa Jalebi: ~420 cal/100g
('generic_mawa_jalebi', 'Mawa Jalebi', 420, 5.0, 50.0, 22.0,
 0.5, 38.0, 60, 30,
 'indian_traditional', ARRAY['mawa jalebi', 'khoya jalebi', 'mawa jilebi', 'paneer jalebi'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~60g = 252 cal. Thicker jalebi made with khoya/mawa, richer than regular jalebi.', TRUE,
 35, 15, 10.0, 0.5, 100, 40, 0.8, 15, 0.2, 3, 8, 0.3, 45, 2, 0.01),

-- Petha (Agra sweet): ~280 cal/100g
('generic_petha', 'Petha (Agra Sweet)', 280, 0.5, 70.0, 0.2,
 0.5, 62.0, 50, 25,
 'indian_traditional', ARRAY['petha', 'agra petha', 'agra ka petha', 'paan petha', 'kesar petha', 'angoori petha'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~50g = 140 cal. Translucent ash gourd sweet from Agra, very sugary, low fat.', TRUE,
 15, 0, 0.0, 0.0, 50, 10, 0.3, 0, 2, 0, 5, 0.1, 10, 1, 0.0),

-- Balushahi: ~370 cal/100g
('generic_balushahi', 'Balushahi (Badusha)', 370, 3.5, 48.0, 18.0,
 0.5, 35.0, 60, 30,
 'indian_traditional', ARRAY['balushahi', 'badusha', 'balusahi', 'khurmi', 'balushahi sweet'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~60g = 222 cal. Flaky deep-fried pastry soaked in sugar syrup, similar to donut texture.', TRUE,
 30, 8, 8.0, 0.5, 60, 10, 0.8, 5, 0.2, 0, 6, 0.3, 30, 2, 0.01),

-- Paneer Sandesh: ~310 cal/100g
('generic_paneer_sandesh', 'Paneer Sandesh (Bengali)', 310, 8.5, 38.0, 13.5,
 0.2, 33.0, 40, 20,
 'indian_traditional', ARRAY['paneer sandesh', 'nolen gurer sandesh', 'mishti sandesh', 'karapak sandesh'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 124 cal. Shaped Bengal cottage cheese sweet with jaggery or sugar.', TRUE,
 30, 12, 7.5, 0.1, 100, 65, 0.3, 15, 0.2, 3, 8, 0.4, 60, 3, 0.01),

-- ==========================================
-- INDIAN SWEETS - GHEE/FLOUR BASED (~12 items)
-- ==========================================

-- Mysore Pak: ~480 cal/100g
('generic_mysore_pak', 'Mysore Pak', 480, 5.5, 40.0, 33.0,
 2.0, 30.0, 50, 25,
 'indian_traditional', ARRAY['mysore pak', 'mysore pa', 'mysore pak sweet', 'ghee mysore pak', 'mysuru pak'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~50g = 240 cal. Rich besan (chickpea flour) sweet with generous ghee and sugar.', TRUE,
 20, 30, 18.0, 0.2, 120, 15, 1.5, 15, 0.2, 2, 15, 0.5, 50, 3, 0.02),

-- Soan Papdi: ~480 cal/100g
('generic_soan_papdi', 'Soan Papdi (Patisa)', 480, 5.0, 60.0, 24.0,
 1.0, 42.0, 50, 25,
 'indian_traditional', ARRAY['soan papdi', 'son papdi', 'patisa', 'sohan papdi', 'flaky sweet'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~50g = 240 cal. Flaky, layered sweet made with besan, sugar, ghee, cardamom.', TRUE,
 25, 10, 10.0, 0.2, 80, 12, 1.0, 5, 0.2, 0, 10, 0.4, 40, 2, 0.01),

-- Gujiya: ~400 cal/100g
('generic_gujiya', 'Gujiya', 400, 5.0, 48.0, 20.0,
 1.5, 28.0, 60, 30,
 'indian_traditional', ARRAY['gujiya', 'gujia', 'karanji', 'ghughra', 'pedakiya', 'nevri'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~60g = 240 cal. Fried pastry with khoya and dried fruit filling. Holi festival special.', TRUE,
 25, 10, 5.0, 0.5, 130, 20, 1.0, 5, 0.5, 0, 15, 0.5, 50, 3, 0.02),

-- Shakarpara (Sweet): ~490 cal/100g
('generic_shakarpara', 'Shakarpara (Sweet Diamond Cookies)', 490, 5.0, 62.0, 24.0,
 1.0, 28.0, 50, NULL,
 'indian_traditional', ARRAY['shakarpara', 'shankarpali', 'shakkar para', 'sweet diamond biscuit', 'shakkarpare'],
 'indian', NULL, 1, 'Per 100g. Handful ~50g = 245 cal. Sweet deep-fried diamond-shaped flour cookies. Festival snack.', TRUE,
 30, 8, 6.0, 0.5, 60, 12, 1.0, 3, 0.2, 0, 8, 0.3, 35, 2, 0.01),

-- Pinni: ~530 cal/100g
('generic_pinni', 'Pinni (Punjabi Sweet)', 530, 8.0, 50.0, 32.0,
 3.0, 30.0, 40, 40,
 'indian_traditional', ARRAY['pinni', 'atta pinni', 'atta ladoo', 'punjabi pinni', 'winter pinni'],
 'indian', NULL, 1, 'Per 100g. One piece ~40g = 212 cal. Dense Punjabi winter sweet with wheat flour, ghee, jaggery, dry fruits.', TRUE,
 20, 15, 12.0, 0.1, 200, 30, 2.0, 10, 0.5, 2, 30, 1.0, 80, 4, 0.02),

-- Coconut Ladoo: ~420 cal/100g
('generic_coconut_ladoo', 'Coconut Ladoo (Nariyal Laddu)', 420, 4.0, 48.0, 24.0,
 4.0, 38.0, 40, 20,
 'indian_traditional', ARRAY['coconut ladoo', 'nariyal laddu', 'nariyal ke laddu', 'coconut laddu'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 168 cal. Sweet balls of grated coconut with condensed milk and cardamom.', TRUE,
 30, 5, 20.0, 0.0, 200, 15, 1.2, 0, 1, 0, 25, 0.6, 50, 4, 0.01),

-- Rava Ladoo: ~430 cal/100g
('generic_rava_ladoo', 'Rava Ladoo (Sooji Laddu)', 430, 5.5, 50.0, 23.0,
 1.5, 32.0, 40, 20,
 'indian_traditional', ARRAY['rava ladoo', 'sooji laddu', 'rava laddu', 'semolina laddu', 'suji ke laddu'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 172 cal. Sweet balls of roasted semolina with ghee, sugar, cashews.', TRUE,
 20, 12, 10.0, 0.1, 80, 15, 0.8, 8, 0.2, 2, 10, 0.4, 45, 3, 0.01),

-- Til Ladoo (Sesame): ~490 cal/100g
('generic_til_ladoo', 'Til Ladoo (Sesame Laddu)', 490, 12.0, 42.0, 30.0,
 5.0, 28.0, 40, 20,
 'indian_traditional', ARRAY['til ladoo', 'til laddu', 'sesame laddu', 'til ke laddu', 'tilgul', 'til gul'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 196 cal. Sesame seeds bound with jaggery. Makar Sankranti special.', TRUE,
 20, 0, 4.5, 0.0, 350, 350, 6.0, 0, 0.5, 0, 100, 3.5, 350, 15, 0.1),

-- Modak (Ganesh Chaturthi): ~320 cal/100g
('generic_modak', 'Modak (Steamed)', 320, 4.0, 48.0, 12.0,
 3.0, 30.0, 60, 30,
 'indian_traditional', ARRAY['modak', 'modaka', 'kozhukattai', 'ukadiche modak', 'steamed modak'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~60g = 192 cal. Rice flour dumplings with coconut-jaggery filling. Ganesh Chaturthi special.', TRUE,
 15, 0, 6.0, 0.0, 180, 15, 1.0, 0, 0.5, 0, 20, 0.5, 50, 3, 0.01),

-- Chirote: ~450 cal/100g
('generic_chirote', 'Chirote (Maharashtrian Sweet)', 450, 4.0, 52.0, 25.0,
 1.0, 25.0, 60, 30,
 'indian_traditional', ARRAY['chirote', 'chiroti', 'maharashtrian chirote'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~60g = 270 cal. Flaky layered deep-fried pastry dusted with powdered sugar.', TRUE,
 20, 8, 10.0, 0.5, 50, 10, 0.8, 3, 0.2, 0, 6, 0.3, 30, 2, 0.01),

-- ==========================================
-- INDIAN SWEETS - HALWA (~5 items)
-- ==========================================

-- Gajar Halwa (Carrot): ~250 cal/100g
('generic_gajar_halwa', 'Gajar Halwa (Carrot Halwa)', 250, 4.0, 33.0, 11.0,
 1.5, 25.0, 120, NULL,
 'indian_traditional', ARRAY['gajar halwa', 'gajar ka halwa', 'carrot halwa', 'gajrela'],
 'indian', NULL, 1, 'Per 100g. Bowl ~120g = 300 cal. Grated carrots slow-cooked with milk, ghee, sugar, nuts.', TRUE,
 35, 15, 6.0, 0.1, 200, 60, 0.5, 300, 3, 5, 12, 0.4, 60, 2, 0.02),

-- Sooji Halwa (Semolina): ~300 cal/100g
('generic_sooji_halwa', 'Sooji Halwa (Suji Ka Halwa)', 300, 3.5, 42.0, 13.0,
 0.8, 28.0, 100, NULL,
 'indian_traditional', ARRAY['sooji halwa', 'suji ka halwa', 'rava sheera', 'semolina halwa', 'sheera'],
 'indian', NULL, 1, 'Per 100g. Bowl ~100g = 300 cal. Roasted semolina cooked with ghee, sugar, water, and nuts.', TRUE,
 20, 12, 6.0, 0.1, 60, 12, 0.8, 8, 0.2, 2, 8, 0.4, 40, 5, 0.01),

-- Moong Dal Halwa: ~350 cal/100g
('generic_moong_dal_halwa', 'Moong Dal Halwa', 350, 8.0, 40.0, 18.0,
 2.0, 28.0, 100, NULL,
 'indian_traditional', ARRAY['moong dal halwa', 'moong dal ka halwa', 'moong halwa', 'mung dal halwa'],
 'indian', NULL, 1, 'Per 100g. Bowl ~100g = 350 cal. Yellow lentil paste slow-cooked with ghee, sugar, milk, cardamom.', TRUE,
 20, 15, 8.0, 0.1, 250, 25, 2.0, 10, 0.5, 2, 25, 1.0, 100, 4, 0.02),

-- Badam Halwa (Almond): ~400 cal/100g
('generic_badam_halwa', 'Badam Halwa (Almond Halwa)', 400, 8.0, 42.0, 22.0,
 2.5, 30.0, 80, NULL,
 'indian_traditional', ARRAY['badam halwa', 'badam ka halwa', 'almond halwa', 'badam halva'],
 'indian', NULL, 1, 'Per 100g. Serving ~80g = 320 cal. Ground almonds cooked with ghee, sugar, saffron, and cardamom.', TRUE,
 15, 12, 5.0, 0.0, 250, 60, 1.5, 5, 0.5, 0, 60, 1.5, 120, 3, 0.02),

-- Lauki Halwa (Bottle Gourd): ~270 cal/100g
('generic_lauki_halwa', 'Lauki Halwa (Bottle Gourd Halwa)', 270, 4.0, 38.0, 12.0,
 1.0, 28.0, 120, NULL,
 'indian_traditional', ARRAY['lauki halwa', 'lauki ka halwa', 'doodhi halwa', 'bottle gourd halwa', 'dudhi halwa'],
 'indian', NULL, 1, 'Per 100g. Bowl ~120g = 324 cal. Grated bottle gourd cooked with milk, ghee, sugar, cardamom.', TRUE,
 30, 12, 5.5, 0.1, 150, 50, 0.4, 15, 5, 3, 10, 0.3, 50, 2, 0.01),

-- ==========================================
-- INDIAN SWEETS - NUT/DRY FRUIT BASED (~8 items)
-- ==========================================

-- Badam Burfi: ~460 cal/100g
('generic_badam_burfi', 'Badam Burfi (Almond Barfi)', 460, 12.0, 45.0, 26.0,
 2.5, 35.0, 50, 12,
 'indian_traditional', ARRAY['badam burfi', 'badam barfi', 'almond burfi', 'almond barfi', 'badaam ki burfi'],
 'indian', NULL, 4, 'Per 100g. 4 pieces ~50g = 230 cal. Dense almond fudge with sugar and cardamom.', TRUE,
 15, 5, 3.0, 0.0, 300, 50, 1.5, 0, 0.5, 0, 60, 1.5, 120, 3, 0.02),

-- Pista Burfi: ~450 cal/100g
('generic_pista_burfi', 'Pista Burfi (Pistachio Barfi)', 450, 11.0, 48.0, 24.0,
 2.0, 36.0, 50, 12,
 'indian_traditional', ARRAY['pista burfi', 'pista barfi', 'pistachio burfi', 'pistachio barfi', 'pista ki burfi'],
 'indian', NULL, 4, 'Per 100g. 4 pieces ~50g = 225 cal. Green pistachio fudge with sugar and cardamom.', TRUE,
 15, 5, 3.0, 0.0, 280, 30, 1.5, 10, 1, 0, 30, 1.0, 120, 3, 0.02),

-- Dry Fruit Roll: ~470 cal/100g
('generic_dry_fruit_roll', 'Dry Fruit Roll', 470, 10.0, 50.0, 25.0,
 3.0, 35.0, 50, NULL,
 'indian_traditional', ARRAY['dry fruit roll', 'dry fruit barfi roll', 'mixed dry fruit roll', 'mewa roll'],
 'indian', NULL, 1, 'Per 100g. Serving ~50g = 235 cal. Rolled sweet with mixed nuts, dried fruits, and condensed milk.', TRUE,
 20, 5, 4.0, 0.0, 400, 50, 2.0, 5, 1, 0, 50, 1.5, 150, 5, 0.03),

-- Anjeer Barfi (Fig): ~380 cal/100g
('generic_anjeer_barfi', 'Anjeer Barfi (Fig Barfi)', 380, 5.0, 55.0, 16.0,
 4.0, 40.0, 50, 15,
 'indian_traditional', ARRAY['anjeer barfi', 'anjeer burfi', 'fig barfi', 'fig burfi', 'anjeer ki barfi'],
 'indian', NULL, 3, 'Per 100g. 3 pieces ~50g = 190 cal. Sweet made from dried figs with nuts and cardamom.', TRUE,
 20, 0, 2.0, 0.0, 350, 80, 2.0, 3, 1, 0, 40, 0.5, 60, 3, 0.02),

-- Mixed Dry Fruit Ladoo: ~480 cal/100g
('generic_dry_fruit_ladoo', 'Mixed Dry Fruit Ladoo', 480, 10.0, 48.0, 28.0,
 3.5, 32.0, 40, 20,
 'indian_traditional', ARRAY['dry fruit ladoo', 'dry fruit laddu', 'mewa ladoo', 'sugar free dry fruit ladoo'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 192 cal. Sweet balls of mixed nuts, dates, and honey.', TRUE,
 15, 0, 4.0, 0.0, 400, 50, 2.0, 5, 1, 0, 55, 1.5, 150, 5, 0.03),

-- Peanut Chikki: ~520 cal/100g
('generic_peanut_chikki', 'Peanut Chikki (Peanut Brittle)', 520, 18.0, 48.0, 28.0,
 3.0, 35.0, 50, NULL,
 'indian_traditional', ARRAY['chikki', 'peanut chikki', 'groundnut chikki', 'moongphali chikki', 'peanut brittle', 'gur chikki'],
 'indian', NULL, 1, 'Per 100g. Piece ~50g = 260 cal. Peanuts set in jaggery or sugar brittle. Popular winter snack.', TRUE,
 25, 0, 4.0, 0.0, 450, 30, 2.5, 0, 0.5, 0, 80, 2.5, 200, 5, 0.02),

-- Gajak (Sesame Brittle): ~510 cal/100g
('generic_gajak', 'Gajak (Sesame Brittle)', 510, 10.0, 50.0, 30.0,
 4.0, 35.0, 50, NULL,
 'indian_traditional', ARRAY['gajak', 'til gajak', 'sesame brittle', 'til patti', 'til ki gajak'],
 'indian', NULL, 1, 'Per 100g. Piece ~50g = 255 cal. Sesame seeds set in jaggery brittle. Makar Sankranti special.', TRUE,
 20, 0, 4.5, 0.0, 300, 300, 5.5, 0, 0.5, 0, 90, 3.0, 300, 12, 0.08),

-- Rewdi: ~430 cal/100g
('generic_rewdi', 'Rewdi (Sesame Candy)', 430, 6.0, 62.0, 18.0,
 2.5, 48.0, 40, NULL,
 'indian_traditional', ARRAY['rewdi', 'revdi', 'rewri', 'til rewdi', 'sesame candy'],
 'indian', NULL, 1, 'Per 100g. Handful ~40g = 172 cal. Small sesame-jaggery candy balls. Winter and festival special.', TRUE,
 15, 0, 2.5, 0.0, 200, 200, 4.0, 0, 0.3, 0, 60, 2.0, 200, 8, 0.05),

-- ==========================================
-- TRADITIONAL INDIAN SNACKS - NAMKEEN (~12 items)
-- ==========================================

-- Sev (plain): ~560 cal/100g
('generic_sev_namkeen', 'Sev (Namkeen)', 560, 10.0, 48.0, 36.0,
 4.0, 2.0, 30, NULL,
 'indian_traditional', ARRAY['sev', 'plain sev', 'bhujia sev', 'nylon sev', 'ratlami sev'],
 'indian', NULL, 1, 'Per 100g. Handful ~30g = 168 cal. Thin crispy chickpea flour noodles, deep-fried and salted.', TRUE,
 600, 0, 6.0, 0.3, 200, 25, 2.5, 3, 0.5, 0, 25, 1.0, 80, 4, 0.02),

-- Chivda (Flattened Rice Mix): ~450 cal/100g
('generic_chivda', 'Chivda (Poha Chivda)', 450, 7.0, 52.0, 24.0,
 3.0, 4.0, 50, NULL,
 'indian_traditional', ARRAY['chivda', 'poha chivda', 'flattened rice mix', 'chiwda', 'beaten rice mixture'],
 'indian', NULL, 1, 'Per 100g. Handful ~50g = 225 cal. Flattened rice fried with peanuts, curry leaves, spices, and turmeric.', TRUE,
 500, 0, 4.0, 0.2, 250, 20, 3.0, 5, 2, 0, 25, 0.8, 80, 3, 0.02),

-- Khakhra (Gujarati): ~430 cal/100g
('generic_khakhra', 'Khakhra (Gujarati Crisp)', 430, 10.0, 58.0, 18.0,
 5.0, 2.0, 30, 30,
 'indian_traditional', ARRAY['khakhra', 'khakhara', 'masala khakhra', 'methi khakhra', 'Gujarati khakra'],
 'indian', NULL, 1, 'Per 100g. One piece ~30g = 129 cal. Thin crispy whole wheat flatbread roasted with oil and spices.', TRUE,
 500, 0, 3.0, 0.1, 250, 30, 3.0, 5, 0.5, 0, 40, 1.5, 120, 8, 0.02),

-- Mathri: ~530 cal/100g
('generic_mathri', 'Mathri', 530, 7.0, 48.0, 34.0,
 2.0, 1.5, 40, 20,
 'indian_traditional', ARRAY['mathri', 'mathi', 'namkeen mathri', 'masala mathri', 'rajasthani mathri'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 212 cal. Crispy deep-fried flaky wheat flour crackers with ajwain.', TRUE,
 550, 0, 8.0, 0.5, 80, 15, 1.5, 2, 0.2, 0, 12, 0.5, 50, 3, 0.01),

-- Namak Para: ~520 cal/100g
('generic_namak_para', 'Namak Para', 520, 7.0, 50.0, 32.0,
 1.5, 1.0, 40, NULL,
 'indian_traditional', ARRAY['namak para', 'namak pare', 'nimki', 'namakpare', 'salty diamonds'],
 'indian', NULL, 1, 'Per 100g. Handful ~40g = 208 cal. Diamond-shaped deep-fried salty flour crackers.', TRUE,
 600, 0, 7.0, 0.5, 70, 12, 1.2, 2, 0.2, 0, 10, 0.4, 40, 2, 0.01),

-- Moong Dal Namkeen: ~540 cal/100g
('generic_moong_dal_namkeen', 'Moong Dal Namkeen', 540, 24.0, 38.0, 30.0,
 5.0, 1.5, 30, NULL,
 'indian_traditional', ARRAY['moong dal namkeen', 'fried moong dal', 'moong dal snack', 'salted moong dal'],
 'indian', NULL, 1, 'Per 100g. Handful ~30g = 162 cal. Split green gram deep-fried with salt and spices.', TRUE,
 550, 0, 4.5, 0.2, 350, 30, 3.0, 5, 1, 0, 40, 1.5, 150, 5, 0.02),

-- Aloo Bhujia: ~540 cal/100g
('generic_aloo_bhujia', 'Aloo Bhujia', 540, 8.0, 50.0, 34.0,
 3.0, 2.0, 30, NULL,
 'indian_traditional', ARRAY['aloo bhujia', 'potato bhujia', 'alu bhujia', 'bikaneri aloo bhujia'],
 'indian', NULL, 1, 'Per 100g. Handful ~30g = 162 cal. Thin crispy potato and besan noodles, spiced and fried.', TRUE,
 650, 0, 5.5, 0.3, 300, 20, 2.0, 5, 3, 0, 20, 0.6, 60, 3, 0.01),

-- Bhakarwadi: ~450 cal/100g
('generic_bhakarwadi', 'Bhakarwadi', 450, 7.0, 50.0, 24.0,
 3.0, 5.0, 50, NULL,
 'indian_traditional', ARRAY['bhakarwadi', 'bakarwadi', 'bhakar wadi', 'chitale bhakarwadi'],
 'indian', NULL, 1, 'Per 100g. Handful ~50g = 225 cal. Spiral rolls of spiced coconut-sesame filling in crispy pastry.', TRUE,
 450, 0, 4.5, 0.3, 180, 30, 2.0, 3, 1, 0, 20, 0.6, 60, 3, 0.02),

-- Chakli / Murukku: ~490 cal/100g
('generic_chakli_murukku', 'Chakli (Murukku)', 490, 8.0, 55.0, 26.0,
 3.0, 1.5, 40, 20,
 'indian_traditional', ARRAY['chakli', 'murukku', 'chakri', 'chakali', 'rice murukku', 'thenkuzhal'],
 'indian', NULL, 2, 'Per 100g. 2 pieces ~40g = 196 cal. Spiral deep-fried savory snack from rice flour and urad dal flour.', TRUE,
 500, 0, 4.0, 0.3, 120, 15, 2.0, 3, 0.5, 0, 15, 0.5, 60, 3, 0.01),

-- Makhana (Fox Nuts, Plain Roasted): ~350 cal/100g
('generic_makhana_plain', 'Makhana (Fox Nuts, Plain)', 350, 10.0, 65.0, 2.0,
 2.0, 0.5, 30, NULL,
 'indian_traditional', ARRAY['makhana', 'fox nuts', 'lotus seeds', 'phool makhana', 'makhane'],
 'indian', NULL, 1, 'Per 100g. Handful ~30g = 105 cal. Roasted fox nut seeds. Low-fat, high-protein snack.', TRUE,
 5, 0, 0.3, 0.0, 200, 40, 1.5, 0, 0.5, 0, 50, 1.0, 100, 4, 0.01),

-- Masala Makhana (Roasted, Spiced): ~400 cal/100g
('generic_masala_makhana', 'Masala Makhana (Roasted Fox Nuts)', 400, 9.0, 55.0, 16.0,
 2.5, 1.0, 40, NULL,
 'indian_traditional', ARRAY['masala makhana', 'roasted makhana', 'spicy makhana', 'ghee makhana'],
 'indian', NULL, 1, 'Per 100g. Handful ~40g = 160 cal. Fox nuts roasted in ghee with turmeric, chilli, and salt.', TRUE,
 250, 8, 8.0, 0.0, 210, 42, 1.5, 5, 0.5, 0, 50, 1.0, 100, 4, 0.01),

-- Roasted Chana: ~370 cal/100g
('generic_roasted_chana', 'Roasted Chana (Bhuna Chana)', 370, 20.0, 55.0, 6.0,
 12.0, 5.0, 40, NULL,
 'indian_traditional', ARRAY['roasted chana', 'bhuna chana', 'chana dal roasted', 'roasted chickpeas', 'bhune chane'],
 'indian', NULL, 1, 'Per 100g. Handful ~40g = 148 cal. Dry-roasted whole or split chickpeas. High-protein snack.', TRUE,
 25, 0, 0.8, 0.0, 600, 60, 5.0, 5, 1, 0, 60, 2.5, 200, 6, 0.03),

-- ==========================================
-- INDIAN BEVERAGES - HOT (~6 items)
-- ==========================================

-- Masala Chai: ~50 cal/100ml
('generic_masala_chai', 'Masala Chai', 50, 1.5, 7.5, 1.5,
 0.0, 6.0, 150, NULL,
 'indian_traditional', ARRAY['masala chai', 'chai', 'masala tea', 'Indian tea', 'adrak elaichi chai'],
 'indian', NULL, 1, 'Per 100g. Cup ~150ml = 75 cal. Black tea brewed with milk, sugar, ginger, cardamom, cinnamon.', TRUE,
 25, 5, 1.0, 0.0, 80, 40, 0.2, 10, 0.5, 3, 5, 0.2, 30, 1, 0.01),

-- Cutting Chai: ~40 cal/100ml
('generic_cutting_chai', 'Cutting Chai', 40, 1.2, 6.0, 1.2,
 0.0, 5.0, 80, NULL,
 'indian_traditional', ARRAY['cutting chai', 'half chai', 'tapri chai', 'mumbai cutting chai'],
 'indian', NULL, 1, 'Per 100ml. Glass ~80ml = 32 cal. Mumbai half-cup strong milky tea from roadside stalls.', TRUE,
 20, 4, 0.8, 0.0, 60, 35, 0.2, 8, 0.3, 2, 4, 0.1, 25, 1, 0.01),

-- Irani Chai: ~65 cal/100ml
('generic_irani_chai', 'Irani Chai', 65, 2.0, 8.5, 2.5,
 0.0, 7.5, 150, NULL,
 'indian_traditional', ARRAY['Irani chai', 'Irani tea', 'Hyderabadi chai', 'mawa chai'],
 'indian', NULL, 1, 'Per 100ml. Cup ~150ml = 98 cal. Rich creamy tea made with mawa (milk solids), popular in Hyderabad.', TRUE,
 30, 8, 1.5, 0.0, 90, 50, 0.2, 15, 0.3, 4, 6, 0.2, 35, 1, 0.01),

-- South Indian Filter Coffee: ~45 cal/100ml
('generic_filter_coffee', 'South Indian Filter Coffee', 45, 1.5, 6.0, 1.5,
 0.0, 5.5, 150, NULL,
 'indian_traditional', ARRAY['filter coffee', 'South Indian coffee', 'filter kaapi', 'degree coffee', 'mylapore coffee'],
 'indian', NULL, 1, 'Per 100ml. Tumbler ~150ml = 68 cal. Decoction brewed coffee with boiled milk and sugar.', TRUE,
 20, 5, 1.0, 0.0, 100, 40, 0.2, 8, 0.3, 3, 8, 0.1, 30, 1, 0.01),

-- Kashmiri Kahwa: ~25 cal/100ml
('generic_kashmiri_kahwa', 'Kashmiri Kahwa', 25, 0.5, 4.5, 0.5,
 0.2, 3.5, 150, NULL,
 'indian_traditional', ARRAY['kahwa', 'kashmiri kahwa', 'Kashmiri green tea', 'kehwa', 'qahwa'],
 'indian', NULL, 1, 'Per 100ml. Cup ~150ml = 38 cal. Green tea with saffron, cinnamon, cardamom, almonds, honey.', TRUE,
 5, 0, 0.1, 0.0, 40, 5, 0.3, 2, 2, 0, 5, 0.1, 10, 1, 0.01),

-- Adrak Chai (Ginger Tea): ~45 cal/100ml
('generic_adrak_chai', 'Adrak Chai (Ginger Tea)', 45, 1.3, 6.5, 1.3,
 0.0, 5.5, 150, NULL,
 'indian_traditional', ARRAY['adrak chai', 'ginger tea', 'adrak wali chai', 'ginger milk tea'],
 'indian', NULL, 1, 'Per 100ml. Cup ~150ml = 68 cal. Milk tea with fresh ginger. Common cold and monsoon favourite.', TRUE,
 22, 4, 0.8, 0.0, 70, 38, 0.2, 8, 0.5, 2, 5, 0.1, 28, 1, 0.01),

-- ==========================================
-- INDIAN BEVERAGES - COLD (~15 items)
-- ==========================================

-- Salted Lassi: ~50 cal/100ml
('generic_salted_lassi', 'Salted Lassi (Namkeen Lassi)', 50, 2.5, 4.5, 2.0,
 0.0, 4.0, 250, NULL,
 'indian_traditional', ARRAY['salted lassi', 'namkeen lassi', 'plain lassi', 'salt lassi', 'chaach'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 125 cal. Yogurt blended with water, salt, roasted cumin.', TRUE,
 200, 8, 1.2, 0.0, 150, 80, 0.1, 12, 0.5, 3, 10, 0.4, 60, 2, 0.01),

-- Chaas / Buttermilk: ~30 cal/100ml
('generic_chaas', 'Chaas (Indian Buttermilk)', 30, 1.5, 3.0, 1.0,
 0.0, 2.5, 250, NULL,
 'indian_traditional', ARRAY['chaas', 'chaach', 'mattha', 'takra', 'Indian buttermilk', 'spiced buttermilk', 'masala chaas'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 75 cal. Diluted yogurt drink with cumin, coriander, salt, asafoetida.', TRUE,
 180, 5, 0.6, 0.0, 120, 60, 0.1, 8, 0.5, 2, 8, 0.3, 50, 2, 0.01),

-- Nimbu Pani / Shikanji: ~35 cal/100ml
('generic_nimbu_pani', 'Nimbu Pani (Indian Lemonade)', 35, 0.2, 8.5, 0.1,
 0.0, 8.0, 250, NULL,
 'indian_traditional', ARRAY['nimbu pani', 'shikanji', 'nimbu sharbat', 'Indian lemonade', 'nimbu paani'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 88 cal. Fresh lime juice with water, sugar, salt, roasted cumin.', TRUE,
 200, 0, 0.0, 0.0, 40, 5, 0.1, 0, 15, 0, 3, 0.1, 5, 0, 0.0),

-- Aam Panna: ~40 cal/100ml
('generic_aam_panna', 'Aam Panna (Raw Mango Drink)', 40, 0.3, 9.5, 0.2,
 0.3, 8.0, 250, NULL,
 'indian_traditional', ARRAY['aam panna', 'kairi panna', 'raw mango drink', 'aam pana', 'green mango sharbat'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 100 cal. Boiled raw mango pulp with sugar, roasted cumin, mint. Summer cooler.', TRUE,
 100, 0, 0.0, 0.0, 60, 8, 0.3, 25, 15, 0, 5, 0.1, 10, 0, 0.0),

-- Jaljeera: ~20 cal/100ml
('generic_jaljeera', 'Jaljeera', 20, 0.3, 4.5, 0.1,
 0.2, 3.5, 250, NULL,
 'indian_traditional', ARRAY['jaljeera', 'jal jeera', 'jaljira', 'cumin water drink'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 50 cal. Spiced cumin-mint water with tamarind, black salt, lemon.', TRUE,
 250, 0, 0.0, 0.0, 50, 10, 0.5, 5, 8, 0, 5, 0.1, 10, 0, 0.0),

-- Rooh Afza Sharbat: ~60 cal/100ml (as served, diluted)
('generic_rooh_afza_sharbat', 'Rooh Afza Sharbat', 60, 0.0, 15.0, 0.0,
 0.0, 14.5, 250, NULL,
 'indian_traditional', ARRAY['rooh afza', 'rooh afza sharbat', 'roohafza', 'rose syrup drink', 'rooh afza milk'],
 'indian', NULL, 1, 'Per 100ml (diluted). Glass ~250ml = 150 cal. Rose-based herbal syrup diluted with water or milk.', TRUE,
 10, 0, 0.0, 0.0, 15, 3, 0.1, 0, 0.5, 0, 1, 0.0, 2, 0, 0.0),

-- Thandai: ~120 cal/100ml
('generic_thandai', 'Thandai', 120, 3.5, 14.0, 5.5,
 0.5, 12.0, 250, NULL,
 'indian_traditional', ARRAY['thandai', 'sardai', 'thandai drink', 'holi drink', 'bhaang thandai base'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 300 cal. Chilled milk with almonds, cashews, melon seeds, saffron, rose, cardamom. Holi special.', TRUE,
 30, 10, 3.0, 0.0, 200, 80, 0.5, 15, 1, 5, 20, 0.5, 80, 3, 0.02),

-- Badam Milk (Indian Almond Milk): ~95 cal/100ml
('generic_badam_milk', 'Badam Milk (Indian Almond Milk)', 95, 3.5, 12.0, 4.0,
 0.5, 10.0, 250, NULL,
 'indian_traditional', ARRAY['badam milk', 'badam doodh', 'almond milk Indian', 'kesar badam doodh'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 238 cal. Hot or cold milk with ground almonds, sugar, saffron, cardamom.', TRUE,
 30, 10, 2.0, 0.0, 180, 80, 0.4, 12, 0.5, 5, 20, 0.5, 80, 2, 0.02),

-- Rose Milk: ~70 cal/100ml
('generic_rose_milk', 'Rose Milk', 70, 2.0, 11.0, 2.0,
 0.0, 10.5, 250, NULL,
 'indian_traditional', ARRAY['rose milk', 'panneer rose milk', 'gulab doodh', 'rose flavored milk'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 175 cal. Chilled milk with rose syrup and sugar. Popular in South India.', TRUE,
 30, 8, 1.2, 0.0, 120, 70, 0.1, 10, 0.3, 5, 8, 0.3, 55, 2, 0.01),

-- Sugarcane Juice: ~74 cal/100ml
('generic_sugarcane_juice', 'Sugarcane Juice (Ganne Ka Ras)', 74, 0.2, 18.0, 0.0,
 0.0, 17.0, 250, NULL,
 'indian_traditional', ARRAY['sugarcane juice', 'ganne ka ras', 'ganna juice', 'fresh cane juice'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 185 cal. Fresh pressed sugarcane with lemon and ginger. Street favourite.', TRUE,
 15, 0, 0.0, 0.0, 60, 10, 0.4, 0, 2, 0, 5, 0.1, 5, 0, 0.0),

-- Coconut Water (Tender): ~20 cal/100ml
('generic_nariyal_paani', 'Nariyal Paani (Tender Coconut Water)', 20, 0.5, 4.0, 0.2,
 0.0, 3.0, 300, NULL,
 'indian_traditional', ARRAY['nariyal paani', 'coconut water', 'tender coconut water', 'daab ka paani', 'elaneer'],
 'indian', NULL, 1, 'Per 100ml. Coconut ~300ml = 60 cal. Fresh tender coconut water. Natural electrolyte drink.', TRUE,
 25, 0, 0.0, 0.0, 200, 20, 0.3, 0, 2, 0, 15, 0.1, 10, 1, 0.0),

-- Kokum Sharbat: ~35 cal/100ml
('generic_kokum_sharbat', 'Kokum Sharbat', 35, 0.2, 8.5, 0.1,
 0.2, 7.5, 250, NULL,
 'indian_traditional', ARRAY['kokum sharbat', 'kokum juice', 'kokam sharbat', 'amsul sharbat', 'kokum cooler'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 88 cal. Kokum (Garcinia) fruit drink with sugar, cumin, salt. Konkan coastal cooler.', TRUE,
 100, 0, 0.0, 0.0, 40, 5, 0.3, 3, 5, 0, 3, 0.1, 5, 0, 0.0),

-- Sol Kadhi: ~55 cal/100ml
('generic_sol_kadhi', 'Sol Kadhi', 55, 1.0, 5.0, 3.5,
 0.5, 3.0, 200, NULL,
 'indian_traditional', ARRAY['sol kadhi', 'solkadhi', 'kokum coconut milk', 'sol kadi'],
 'indian', NULL, 1, 'Per 100ml. Serving ~200ml = 110 cal. Kokum fruit steeped in coconut milk with garlic and cumin. Konkan digestive.', TRUE,
 80, 0, 3.0, 0.0, 120, 10, 0.5, 3, 5, 0, 10, 0.2, 20, 1, 0.01),

-- Kanji (Fermented Carrot Drink): ~25 cal/100ml
('generic_kanji', 'Kanji (Fermented Carrot Drink)', 25, 0.3, 5.5, 0.1,
 0.3, 3.0, 250, NULL,
 'indian_traditional', ARRAY['kanji', 'gajar ki kanji', 'fermented carrot water', 'kanji drink'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 63 cal. Fermented black carrot and mustard water. Probiotic Holi drink.', TRUE,
 300, 0, 0.0, 0.0, 80, 10, 0.3, 100, 3, 0, 5, 0.1, 10, 0, 0.0),

-- ==========================================
-- INDIAN BEVERAGES - MILK BASED (~3 items)
-- ==========================================

-- Kesar Milk: ~80 cal/100ml
('generic_kesar_milk', 'Kesar Milk (Saffron Milk)', 80, 3.0, 10.0, 3.0,
 0.0, 9.0, 250, NULL,
 'indian_traditional', ARRAY['kesar milk', 'kesar doodh', 'saffron milk', 'kesari doodh'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 200 cal. Warm milk with saffron strands, sugar, and cardamom.', TRUE,
 35, 10, 2.0, 0.0, 140, 80, 0.2, 12, 0.5, 8, 10, 0.3, 65, 2, 0.01),

-- Haldi Doodh (Turmeric Milk): ~70 cal/100ml
('generic_haldi_doodh', 'Haldi Doodh (Turmeric Milk)', 70, 3.0, 8.5, 2.5,
 0.1, 7.0, 250, NULL,
 'indian_traditional', ARRAY['haldi doodh', 'turmeric milk', 'golden milk', 'haldi wala doodh', 'turmeric latte'],
 'indian', NULL, 1, 'Per 100ml. Glass ~250ml = 175 cal. Warm milk with turmeric, black pepper, and honey. Immunity booster.', TRUE,
 30, 8, 1.5, 0.0, 140, 80, 0.3, 10, 0.5, 8, 10, 0.3, 65, 2, 0.01),

-- Rabri Milk: ~110 cal/100ml
('generic_rabri_milk', 'Rabri Milk', 110, 3.5, 13.0, 5.0,
 0.0, 12.0, 200, NULL,
 'indian_traditional', ARRAY['rabri milk', 'rabdi milk', 'rabri wala doodh'],
 'indian', NULL, 1, 'Per 100ml. Glass ~200ml = 220 cal. Chilled sweetened thickened milk with rabri, nuts, and saffron.', TRUE,
 35, 15, 3.0, 0.0, 130, 80, 0.2, 20, 0.3, 5, 10, 0.3, 65, 2, 0.01)

ON CONFLICT (food_name_normalized) DO NOTHING;
