-- ============================================================================
-- Migration 272: Food Nutrition Overrides - Restaurant & Packaged Foods
-- Generated: 2026-02-28
--
-- Adds ~160 curated nutrition overrides for foods from:
--   - Indian restaurants (Biryani House, Bay Leaf, Rice and Spice)
--   - McDonald's, Hardee's
--   - Taco Bell, Chipotle, Papa John's
--   - Buffalo Wild Wings, Red Robin, Steak 'n Shake
--   - Panda Express, Bob Evans, Hokkaido, Curly Shawarma
--   - Kung Fu Tea, The Shake Bar
--   - Packaged drinks, snacks, candy, sauces
--
-- Sources: Official restaurant nutrition guides, USDA FoodData Central,
--          nutritionix.com, fatsecret.com, calorieking.com, eatthismuch.com,
--          manufacturer labels, tarladalal.com, snapcalorie.com
--
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

INSERT INTO food_nutrition_overrides
  (food_name_normalized, display_name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, default_weight_per_piece_g, default_serving_g, source, variant_names, notes)
VALUES

-- ============================================================================
-- INDIAN RESTAURANTS: BIRYANIS & PULAO
-- ============================================================================

('hyderabadi_chicken_dum_biryani', 'Hyderabadi Chicken Dum Biryani', 155, 7.8, 21.0, 4.3, 0.8, 1.0, NULL, 400, 'nutritionix', ARRAY['chicken dum biryani', 'hyderabadi biryani chicken', 'chicken biryani hyderabadi'], '~620 cal per 400g serving'),
('hyderabadi_goat_dum_biryani', 'Hyderabadi Goat Dum Biryani', 163, 7.5, 18.8, 6.3, 1.0, 2.0, NULL, 400, 'nutritionix', ARRAY['goat dum biryani', 'mutton dum biryani', 'hyderabadi mutton biryani'], '~650 cal per 400g serving'),
('goat_keema_biryani', 'Goat Keema Biryani', 167, 6.7, 21.7, 5.0, 0.8, 1.0, NULL, 400, 'nutribit', ARRAY['keema biryani', 'mutton keema biryani', 'minced meat biryani'], '~668 cal per 400g serving'),
('goat_keema_pulao', 'Goat Keema Pulao', 150, 6.7, 20.0, 4.5, 0.8, 0.8, NULL, 350, 'estimated', ARRAY['keema pulao', 'mutton keema pulao', 'minced goat pulao'], '~525 cal per 350g serving'),
('nalli_gosht_biryani', 'Nalli Gosht Biryani', 170, 8.0, 18.5, 7.0, 0.8, 1.5, NULL, 450, 'estimated', ARRAY['nalli gosh biryani', 'bone-in goat biryani', 'nalli biryani'], '~765 cal per 450g serving'),
('chicken_65_biryani', 'Chicken 65 Biryani', 163, 7.3, 16.8, 7.0, 0.6, 1.0, NULL, 400, 'mynetdiary', ARRAY['65 chicken biryani', 'spicy chicken 65 biryani'], '~650 cal per 400g serving'),
('thalapakatti_biryani', 'Thalapakatti Biryani', 158, 6.5, 20.0, 5.5, 0.7, 1.0, NULL, 400, 'estimated', ARRAY['thalappakatti biryani', 'dindigul biryani', 'south indian biryani'], '~632 cal per 400g serving'),
('spl_lollipop_biryani', 'Spl Lollipop Biryani', 170, 7.5, 18.0, 7.5, 0.6, 1.0, NULL, 400, 'estimated', ARRAY['lollipop biryani', 'chicken lollipop biryani', 'special lollipop biryani'], '~680 cal per 400g serving'),
('masakali_biryani', 'Masakali Biryani', 160, 7.5, 19.5, 5.5, 0.8, 1.2, NULL, 400, 'estimated', ARRAY['masakkali biryani', 'special biryani'], '~640 cal per 400g serving'),
('chicken_roast_pulao', 'Chicken Roast Pulao', 150, 8.0, 18.0, 4.8, 0.6, 0.8, NULL, 350, 'snapcalorie', ARRAY['roast chicken pulao', 'chicken pulav roast'], '~525 cal per 350g serving'),
('goat_roast_pulao', 'Goat Roast Pulao', 157, 7.4, 17.1, 6.3, 0.7, 0.8, NULL, 350, 'snapcalorie', ARRAY['mutton roast pulao', 'goat pulav roast'], '~550 cal per 350g serving'),
('shrimp_roast_pulao', 'Shrimp Roast Pulao', 140, 7.4, 18.0, 4.0, 0.5, 0.6, NULL, 350, 'estimated', ARRAY['prawn roast pulao', 'shrimp pulav roast', 'jhinga pulao'], '~490 cal per 350g serving'),
('pachimirchi_chicken_pulao', 'Pachimirchi Chicken Pulao', 148, 7.5, 18.5, 4.5, 0.8, 0.8, NULL, 350, 'estimated', ARRAY['green chilli chicken pulao', 'pachimirchi pulao'], '~518 cal per 350g serving'),
('monagadu_goat_pulao', 'Monagadu Goat Pulao', 155, 7.0, 17.5, 6.0, 0.7, 0.8, NULL, 350, 'estimated', ARRAY['monagadu pulao', 'spicy goat pulao'], '~543 cal per 350g serving'),
('house_special_goat_biryani', 'House Special Goat Biryani', 168, 8.0, 18.5, 6.8, 1.0, 1.5, NULL, 425, 'estimated', ARRAY['special goat biryani', 'restaurant special mutton biryani'], '~714 cal per 425g serving'),
('house_special_boneless_chicken_biryani', 'House Special Boneless Chicken Biryani', 158, 8.5, 19.5, 4.8, 0.7, 1.0, NULL, 425, 'estimated', ARRAY['special chicken biryani', 'boneless chicken biryani special'], '~672 cal per 425g serving'),
('vijayawada_goat_biryani', 'Vijayawada Goat Biryani', 165, 7.5, 17.5, 6.5, 0.8, 1.2, NULL, 400, 'nutribit', ARRAY['vijaywada goat biryani', 'vijayawada mutton biryani', 'andhra goat biryani'], '~660 cal per 400g serving'),
('vijayawada_chicken_biryani', 'Vijayawada Chicken Biryani', 150, 6.3, 17.5, 6.3, 1.0, 1.3, NULL, 400, 'nutribit', ARRAY['vjayawada chicken biryani', 'vijaywada chicken biryani', 'andhra chicken biryani'], '~600 cal per 400g serving'),

-- ============================================================================
-- INDIAN RESTAURANTS: CURRIES & DRY DISHES
-- ============================================================================

('mutton_haleem', 'Mutton Haleem', 140, 8.0, 16.0, 5.2, 2.5, 1.5, NULL, 300, 'fatsecret', ARRAY['haleem', 'goat haleem', 'hyderabadi haleem'], '~420 cal per 300g serving'),
('goat_sukka', 'Goat Sukka', 195, 18.0, 5.0, 11.5, 1.5, 1.0, NULL, 200, 'estimated', ARRAY['mutton sukka', 'goat chukka', 'mutton chukka varuval', 'dry goat fry'], '~390 cal per 200g serving'),
('dal_tadka', 'Dal Tadka', 115, 5.5, 14.5, 4.0, 3.5, 1.5, NULL, 250, 'tarladalal', ARRAY['yellow dal tadka', 'toor dal tadka', 'daal tadka', 'tempered lentils'], '~288 cal per 250g serving'),
('spicy_andhra_chicken_curry', 'Spicy Andhra Chicken Curry', 155, 12.0, 5.5, 9.5, 1.5, 2.0, NULL, 250, 'snapcalorie', ARRAY['andhra chicken curry', 'kodi kura', 'andhra kodi curry', 'spicy chicken curry'], '~388 cal per 250g serving'),
('andhra_chicken_curry', 'Andhra Chicken Curry', 155, 12.0, 5.5, 9.5, 1.5, 2.0, NULL, 250, 'snapcalorie', ARRAY['kodi kura', 'andhra kodi curry'], '~388 cal per 250g serving'),
('karam_podi_chicken', 'Karam Podi Chicken', 200, 17.0, 8.0, 11.5, 2.0, 1.0, NULL, 200, 'estimated', ARRAY['podi chicken', 'spice powder chicken', 'masala podi chicken', 'karampodi chicken'], '~400 cal per 200g serving'),
('chilli_chicken', 'Chilli Chicken', 175, 14.5, 10.0, 9.0, 1.0, 3.0, NULL, 200, 'snapcalorie', ARRAY['chili chicken', 'indo chinese chilli chicken', 'chicken chilli dry'], '~350 cal per 200g serving'),
('chilli_chicken_lollipop', 'Chilli Chicken Lollipop', 210, 16.0, 12.0, 11.0, 0.5, 3.5, NULL, 200, 'snapcalorie', ARRAY['chicken lollipop chilli', 'chili chicken lollipop', 'drumette chilli'], '~420 cal per 200g serving'),
('manchurian_chicken_lollipop', 'Manchurian Chicken Lollipop', 195, 14.0, 13.5, 9.5, 0.5, 4.0, NULL, 200, 'mynetdiary', ARRAY['chicken lollipop manchurian', 'manchurian lollipop', 'chicken drumette manchurian'], '~390 cal per 200g serving'),
('chicken_chatkara', 'Chicken Chatkara', 185, 16.0, 6.0, 11.0, 1.0, 1.5, NULL, 200, 'estimated', ARRAY['chatkhara chicken', 'chatkara chicken fry'], '~370 cal per 200g serving'),
('monagadu_chicken', 'Monagadu Chicken', 180, 15.0, 5.0, 11.0, 1.5, 1.5, NULL, 200, 'estimated', ARRAY['monagadu kodi', 'spicy monagadu chicken'], '~360 cal per 200g serving'),
('guntur_chicken', 'Guntur Chicken', 185, 15.5, 6.0, 11.5, 1.5, 1.5, NULL, 200, 'nutritionix', ARRAY['guntur kodi', 'guntur chicken roast', 'guntur style chicken'], '~370 cal per 200g serving'),
('kodi_vepudu', 'Kodi Vepudu', 190, 17.0, 5.5, 11.5, 1.5, 1.0, NULL, 200, 'nutritionix', ARRAY['andhra chicken fry', 'chicken vepudu', 'kodi fry'], '~380 cal per 200g serving'),
('velluikaram_chicken', 'Velluikaram Chicken', 180, 15.5, 6.0, 10.5, 1.2, 1.5, NULL, 200, 'estimated', ARRAY['vellui karam chicken', 'garlic chilli chicken andhra'], '~360 cal per 200g serving'),
('pachimirchi_chicken', 'Pachimirchi Chicken', 175, 15.0, 5.5, 10.5, 1.5, 1.5, NULL, 200, 'estimated', ARRAY['green chilli chicken', 'pachi mirchi chicken', 'mirchi chicken'], '~350 cal per 200g serving'),
('mangalore_chicken', 'Mangalore Chicken', 170, 14.0, 6.0, 10.0, 1.5, 1.5, NULL, 200, 'estimated', ARRAY['mangalorean chicken', 'mangalore chicken curry', 'mangalore style chicken'], '~340 cal per 200g serving'),
('mangalore_ghee_chicken_roast', 'Mangalore Ghee Chicken Roast', 195, 13.5, 5.0, 13.5, 1.0, 1.0, NULL, 200, 'estimated', ARRAY['chicken ghee roast', 'mangalorean ghee roast chicken', 'ghee chicken roast'], '~390 cal per 200g serving'),
('mangalore_ghee_goat_roast', 'Mangalore Ghee Goat Roast', 210, 14.0, 5.0, 14.5, 1.0, 1.0, NULL, 200, 'estimated', ARRAY['goat ghee roast', 'mangalorean ghee roast goat', 'mutton ghee roast'], '~420 cal per 200g serving'),
('gongura_chicken_curry', 'Gongura Chicken Curry', 160, 12.5, 5.5, 10.0, 2.0, 1.5, NULL, 250, 'clearcals', ARRAY['gongura chicken', 'sorrel leaves chicken', 'gongura kodi'], '~400 cal per 250g serving'),
('nallakaram_fish', 'Nallakaram Fish', 180, 18.0, 6.0, 9.5, 1.0, 1.0, NULL, 200, 'estimated', ARRAY['nalla karam fish', 'spicy fish andhra', 'chepa nallakaram'], '~360 cal per 200g serving'),
('tawa_fish_fry', 'Tawa Fish Fry', 190, 19.0, 5.5, 10.5, 0.5, 0.5, NULL, 150, 'nutribit', ARRAY['fish tawa fry', 'pan fried fish', 'fish fry indian'], '~285 cal per 150g serving'),
('fish_65_dry', 'Fish 65 Dry', 210, 18.0, 10.0, 11.0, 0.5, 1.5, NULL, 180, 'estimated', ARRAY['fish 65', 'deep fried fish 65', 'crispy fish 65'], '~378 cal per 180g serving'),
('shrimp_pepper_fry', 'Shrimp Pepper Fry', 175, 17.0, 6.0, 9.5, 0.8, 1.0, NULL, 180, 'snapcalorie', ARRAY['prawn pepper fry', 'pepper shrimp', 'jhinga pepper fry'], '~315 cal per 180g serving'),
('egg_masala', 'Egg Masala', 145, 7.5, 6.5, 10.0, 1.0, 2.5, NULL, 200, 'tarladalal', ARRAY['anda masala', 'egg curry', 'masala egg curry'], '~290 cal per 200g serving'),
('navratan_korma', 'Navratan Korma', 130, 3.5, 10.0, 8.5, 1.5, 3.0, NULL, 250, 'nutritionvalue', ARRAY['navratna korma', 'mixed vegetable korma', 'nine gem korma'], '~325 cal per 250g serving'),
('channa_masala', 'Channa Masala', 120, 5.5, 16.0, 4.0, 4.0, 2.5, NULL, 250, 'nutritionix', ARRAY['chole masala', 'chickpea curry', 'chana masala', 'chole'], '~300 cal per 250g serving'),
('gobi_manchurian', 'Gobi Manchurian', 155, 3.0, 17.0, 8.5, 2.0, 3.5, NULL, 200, 'snapcalorie', ARRAY['cauliflower manchurian', 'gobi manchurian dry', 'manchurian gobi'], '~310 cal per 200g serving'),
('chicken_manchurian', 'Chicken Manchurian', 180, 13.0, 14.0, 8.0, 0.8, 3.5, NULL, 200, 'snapcalorie', ARRAY['manchurian chicken', 'indo chinese chicken manchurian'], '~360 cal per 200g serving'),
('aloo_matar', 'Aloo Matar', 95, 2.5, 13.0, 3.8, 2.0, 2.0, NULL, 250, 'anuvaad', ARRAY['aloo mutter', 'potato peas curry', 'matar aloo'], '~238 cal per 250g serving'),
('gutti_vankaya', 'Gutti Vankaya', 110, 2.5, 8.0, 7.8, 3.0, 3.5, NULL, 250, 'sparkrecipes', ARRAY['stuffed eggplant curry', 'gutti vankaya kura', 'stuffed brinjal'], '~275 cal per 250g serving'),
('saag_paneer', 'Saag Paneer', 150, 8.5, 5.5, 11.0, 2.0, 2.0, NULL, 250, 'nutritionix', ARRAY['palak paneer', 'spinach paneer', 'spinach with cottage cheese'], '~375 cal per 250g serving'),
('pav_bhaji', 'Pav Bhaji', 160, 3.8, 23.0, 5.8, 2.5, 3.5, NULL, 350, 'tarladalal', ARRAY['pav bhajji', 'mumbai pav bhaji', 'pao bhaji'], '~560 cal per 350g serving, includes 2 pav'),

-- ============================================================================
-- INDIAN RESTAURANTS: RICE DISHES
-- ============================================================================

('jeera_rice', 'Jeera Rice', 160, 2.5, 27.0, 4.5, 0.4, 0.3, NULL, 200, 'eatthismuch', ARRAY['cumin rice', 'zeera rice', 'jeera pulao'], '~320 cal per 200g serving'),
('chicken_fried_rice', 'Chicken Fried Rice', 175, 7.5, 22.0, 6.0, 1.0, 1.0, NULL, 300, 'fatsecret', ARRAY['indo chinese chicken fried rice', 'chicken fry rice'], '~525 cal per 300g serving'),

-- ============================================================================
-- INDIAN RESTAURANTS: SIDES & COMBOS
-- ============================================================================

('samosa_chaat', 'Samosa Chaat', 140, 3.5, 18.0, 6.0, 2.0, 4.0, NULL, 250, 'snapcalorie', ARRAY['samosa chat', 'samosa chaat plate'], '~350 cal per 250g serving'),
('idli_bonda_combo', 'Idli Bonda Combo', 130, 3.5, 20.0, 4.0, 1.5, 1.0, NULL, 300, 'estimated', ARRAY['2 idli 2 bonda combo', 'idli bonda plate'], '~390 cal per 300g serving'),
('idli_dosa_combo', 'Idli Dosa Combo', 120, 3.0, 20.0, 3.0, 1.2, 1.0, NULL, 350, 'estimated', ARRAY['idli and dosa combo', 'south indian combo'], '~420 cal per 350g serving'),
('andhra_karam_masala_dosa', 'Andhra Karam Masala Dosa', 155, 3.5, 22.0, 6.0, 1.5, 1.5, NULL, 250, 'estimated', ARRAY['karam dosa', 'spicy masala dosa', 'andhra masala dosa'], '~388 cal per 250g serving'),
('chilli_garlic_naan', 'Chilli Garlic Naan', 280, 8.0, 42.0, 8.5, 2.0, 2.5, 90, 90, 'mynetdiary', ARRAY['garlic chilli naan', 'chili garlic naan', 'mirchi garlic naan'], '~252 cal per 90g piece'),
('raita', 'Raita', 55, 3.0, 5.0, 2.5, 0.3, 3.5, NULL, 100, 'nutritionix', ARRAY['yogurt raita', 'cucumber raita', 'boondi raita', 'onion raita'], '~55 cal per 100g serving'),
('papad', 'Papad', 371, 25.5, 53.0, 6.5, 4.0, 1.0, 15, 15, 'foodstruct', ARRAY['papadum', 'poppadom', 'appalam'], '~56 cal per 15g piece'),
('non_veg_thali', 'Non Veg Thali', 140, 5.5, 18.5, 5.0, 2.0, 2.5, NULL, 600, 'snapcalorie', ARRAY['nonveg thali', 'non vegetarian thali', 'meat thali combo'], '~840 cal per 600g serving'),
('special_combo', 'Special Combo', 145, 5.5, 20.0, 4.5, 1.5, 1.5, NULL, 500, 'estimated', ARRAY['rice curry combo', 'lunch combo', 'special meal combo'], '~725 cal per 500g serving'),

-- ============================================================================
-- INDIAN RESTAURANTS: MANDI DISHES
-- ============================================================================

('mutton_mandi', 'Mutton Mandi', 186, 10.0, 21.4, 7.1, 0.8, 0.5, NULL, 400, 'snapcalorie', ARRAY['lamb mandi', 'goat mandi', 'mandi mutton', 'yemeni mandi mutton'], '~743 cal per 400g serving'),
('meat_lover_mandi', 'Meat Lover Mandi', 195, 11.0, 20.0, 8.0, 0.7, 0.5, NULL, 450, 'estimated', ARRAY['mixed meat mandi', 'special meat mandi'], '~878 cal per 450g serving'),
('tandoori_chicken_mandi', 'Tandoori Chicken Mandi', 165, 10.5, 20.0, 5.0, 0.7, 0.5, NULL, 400, 'estimated', ARRAY['chicken tandoori mandi', 'tandoori mandi'], '~660 cal per 400g serving'),

-- ============================================================================
-- INDIAN RESTAURANTS: DESSERTS & DRINKS
-- ============================================================================

('gulab_jamun', 'Gulab Jamun', 325, 3.5, 52.0, 12.0, 0.3, 40.0, 40, 80, 'nutritionix', ARRAY['gulab jaman', 'gulaab jamun', 'rose berry dessert'], '~260 cal per 2 pieces (80g)'),
('indian_tres_leches', 'Indian Tres Leches', 270, 6.5, 42.0, 8.8, 0.2, 30.0, NULL, 120, 'nutritionvalue', ARRAY['tres leches cake', 'three milk cake indian'], '~324 cal per 120g serving'),
('butterscotch_pastry', 'Butterscotch Pastry', 305, 4.8, 48.0, 10.3, 0.3, 30.0, NULL, 90, 'swisscastle', ARRAY['butterscotch cake pastry', 'butterscotch cream pastry'], '~275 cal per 90g piece'),
('apricot_delight', 'Apricot Delight', 175, 2.0, 33.0, 4.5, 2.0, 28.0, NULL, 150, 'snapcalorie', ARRAY['khubani ka meetha', 'apricot dessert', 'hyderabadi apricot sweet'], '~263 cal per 150g serving'),
('chikoo_shake', 'Chikoo Shake', 80, 2.5, 13.0, 2.0, 0.8, 11.0, NULL, 300, 'snapcalorie', ARRAY['sapodilla milkshake', 'chickoo shake', 'sapota shake', 'chiku shake'], '~240 cal per 300ml serving'),
('sitaphal_shake', 'Sitaphal Shake', 85, 2.0, 14.5, 2.5, 0.8, 11.5, NULL, 300, 'tarladalal', ARRAY['custard apple shake', 'custard apple milkshake', 'sitaphal milkshake'], '~255 cal per 300ml serving'),

-- ============================================================================
-- McDONALD'S
-- ============================================================================

('mcdonalds_chicken_mcnuggets_10pc', 'McDonald''s 10 pc. Chicken McNuggets', 259.3, 13.6, 16.0, 15.4, 0.0, 0.0, 16.2, 162.0, 'mcdonalds.com', ARRAY['10 piece', '10pc nuggets', '10 pc chicken mcnuggets'], 'Without sauce. Each nugget ~16.2g. 420 cal total.'),
('mcdonalds_chicken_mcnuggets_6pc', 'McDonald''s 6 pc. Chicken McNuggets', 257.7, 14.4, 15.5, 15.5, 0.0, 0.0, 16.2, 97.0, 'mcdonalds.com', ARRAY['6 piece', '6pc nuggets', '6 pc chicken mcnuggets'], 'Without sauce. 250 cal total.'),
('mcdonalds_hot_n_spicy_mcchicken', 'McDonald''s Hot ''N Spicy McChicken', 265.3, 9.5, 27.9, 11.6, 1.4, 3.4, 147.0, 147.0, 'mcdonalds.com', ARRAY['hot n spicy', 'mcchicken spicy', 'hot n spicy mcchicken'], 'Sandwich only. 390 cal.'),
('mcdonalds_spicy_mccrispy', 'McDonald''s Spicy McCrispy', 252.4, 12.9, 22.9, 12.4, 1.0, 4.3, 210.0, 210.0, 'mcdonalds.com', ARRAY['spicy mccrispy', 'spicy crispy chicken sandwich'], 'Sandwich only. 530 cal.'),
('mcdonalds_sausage_egg_cheese_mcgriddles', 'McDonald''s Sausage Egg & Cheese McGriddles', 276.4, 10.1, 22.6, 16.1, 0.5, 7.5, 199.0, 199.0, 'mcdonalds.com', ARRAY['mcgriddles', 'sausage egg cheese mcgriddle'], '550 cal.'),
('mcdonalds_steak_egg_mcmuffin', 'McDonald''s Steak & Egg McMuffin', 233.7, 14.1, 16.3, 12.0, 1.1, 1.6, 184.0, 184.0, 'mcdonalds.com', ARRAY['steak egg mcmuffin', 'steak egg cheese mcmuffin'], '430 cal.'),
('mcdonalds_hash_brown', 'McDonald''s Hash Brown', 250.0, 3.6, 32.1, 14.3, 3.6, 0.0, 56.0, 56.0, 'mcdonalds.com', ARRAY['hash brown', 'hashbrown'], '140 cal per piece.'),
('mcdonalds_french_fries_medium', 'McDonald''s French Fries (Medium)', 273.5, 4.3, 36.8, 12.8, 3.4, 0.0, 117.0, 117.0, 'mcdonalds.com', ARRAY['medium fries', 'world famous fries medium', 'french fries'], '320 cal per medium.'),
('mcdonalds_cheeseburger', 'McDonald''s Classic Cheeseburger', 265.5, 13.3, 29.2, 11.5, 1.8, 6.2, 113.0, 113.0, 'mcdonalds.com', ARRAY['cheeseburger', 'classic cheeseburger'], '300 cal. Part of Classic Cheeseburger Pack.'),
('mcdonalds_double_quarter_pounder_cheese', 'McDonald''s Double Quarter Pounder with Cheese', 264.3, 17.1, 15.4, 15.0, 0.7, 3.6, 280.0, 280.0, 'mcdonalds.com', ARRAY['double quarter pounder', 'dqpc', 'double quarter pounder with cheese deluxe'], '740 cal.'),
('mcdonalds_bacon_side', 'McDonald''s Bacon (2 Half Strips)', 636.4, 36.4, 9.1, 54.5, 0.0, 0.0, 5.5, 11.0, 'mcdonalds.com', ARRAY['bacon side', 'half strips bacon', '2 bacon strips', '2 half strips bacon'], '70 cal per 2 half strips.'),
('mcdonalds_sweet_iced_tea_medium', 'McDonald''s Sweet Iced Tea (Medium)', 17.7, 0.0, 4.5, 0.0, 0.0, 4.5, 621.0, 621.0, 'mcdonalds.com', ARRAY['sweet tea', 'sweet iced tea', 'mcdonalds sweet tea'], '110 cal per medium 21oz.'),
('mcdonalds_hot_chocolate_medium', 'McDonald''s Premium Hot Chocolate (Medium)', 93.0, 3.0, 12.9, 3.4, 0.2, 11.8, 473.0, 473.0, 'mcdonalds.com', ARRAY['hot chocolate', 'mccafe hot chocolate', 'premium hot chocolate'], '440 cal per medium 16oz.'),
('mcdonalds_hot_n_spicy_mcchicken_meal', 'McDonald''s Hot ''N Spicy McChicken Meal', 265.3, 9.5, 27.9, 11.6, 1.4, 3.4, 147.0, 147.0, 'mcdonalds.com', ARRAY['hot n spicy meal', 'mcchicken meal'], 'Nutrition for sandwich only. Fries + drink logged separately.'),
('mcdonalds_chicken_mcnuggets_10pc_meal', 'McDonald''s 10 pc. Chicken McNuggets Meal', 259.3, 13.6, 16.0, 15.4, 0.0, 0.0, 16.2, 162.0, 'mcdonalds.com', ARRAY['10pc nuggets meal', 'mcnuggets meal', '10 pc chicken mcnuggets meal'], 'Nutrition for nuggets only. Fries + drink logged separately.'),
('mcdonalds_spicy_mccrispy_meal', 'McDonald''s Spicy McCrispy Meal', 252.4, 12.9, 22.9, 12.4, 1.0, 4.3, 210.0, 210.0, 'mcdonalds.com', ARRAY['spicy mccrispy meal', 'spicy crispy chicken meal'], 'Nutrition for sandwich only. Fries + drink logged separately.'),

-- ============================================================================
-- HARDEE'S
-- ============================================================================

('hardees_big_hot_ham_n_cheese', 'Hardee''s Big Hot Ham ''N'' Cheese', 222.7, 14.3, 21.4, 8.4, 0.8, 2.5, 238.0, 238.0, 'hardees.com', ARRAY['big hot ham n cheese', 'hot ham cheese'], '530 cal.'),
('hardees_crispy_curls_medium', 'Hardee''s Crispy Curls (Medium)', 311.1, 3.7, 39.3, 15.6, 3.0, 3.7, 135.0, 135.0, 'hardees.com', ARRAY['crispy curls', 'curly fries', 'hardees curly fries'], '420 cal per medium.'),
('hardees_vanilla_ice_cream_shake', 'Hardee''s Vanilla Ice Cream Shake (Medium)', 178.8, 3.3, 21.9, 8.8, 0.0, 17.6, 397.0, 397.0, 'hardees.com', ARRAY['ice cream shake', 'vanilla shake', 'hand scooped ice cream shake'], '710 cal per medium.'),
('hardees_spicy_chicken_tenders_3pc', 'Hardee''s Spicy Hand-Breaded Chicken Tenders (3 pc)', 203.1, 19.5, 10.2, 10.2, 1.6, 0.0, 42.7, 128.0, 'hardees.com', ARRAY['spicy chicken tenders', 'hand breaded chicken tenders', 'spicy hand-breaded chicken tenders'], '260 cal for 3 pieces. Without sauce.'),

-- ============================================================================
-- TACO BELL
-- ============================================================================

('taco_bell_chicken_quesadilla', 'Taco Bell Chicken Quesadilla', 277.2, 14.1, 20.1, 14.1, 1.1, 1.6, 184, 184, 'tacobell.com', ARRAY['chicken quesadilla', 'taco bell quesadilla'], '510 cal per quesadilla.'),
('taco_bell_cantina_chicken_quesadilla', 'Taco Bell Cantina Chicken Quesadilla', 221.8, 11.3, 16.3, 12.5, 1.6, 1.2, 257, 257, 'tacobell.com', ARRAY['cantina chicken quesadilla'], '570 cal per quesadilla.'),
('taco_bell_cinnabon_delights', 'Taco Bell Cinnabon Delights', 265.6, 3.1, 23.4, 17.2, 0.0, 15.6, 32, 32, 'tacobell.com', ARRAY['cinnabon delights', 'cinnabon delights 2 pack', 'cinnabon delights 12 pack'], 'Per piece (~32g). 2-pack=170 cal, 12-pack=1010 cal.'),
('taco_bell_cinnamon_twists', 'Taco Bell Cinnamon Twists', 485.7, 2.9, 77.1, 17.1, 2.9, 28.6, 35, 35, 'tacobell.com', ARRAY['cinnamon twists'], '170 cal per order (35g).'),
('taco_bell_salted_caramel_churros', 'Taco Bell Salted Caramel Churros', 295.0, 2.7, 25.8, 20.4, 1.2, 15.4, 26, 26, 'tacobell.com', ARRAY['salted caramel churros', 'salted caramel churros 3pk', 'churros'], 'Per piece (~26g). 3pk=230 cal.'),
('taco_bell_franks_redhot_diablo_sauce', 'Taco Bell Frank''s RedHot Diablo Sauce', 107.1, 0.0, 7.1, 7.1, 0.0, 0.0, 14, 14, 'tacobell.com', ARRAY['franks redhot diablo sauce', 'diablo sauce'], 'Per packet (~14g). Creamy mashup of Buffalo and Diablo flavors.'),
('taco_bell_volcano_sauce', 'Taco Bell Volcano Sauce', 214.3, 0.0, 7.1, 21.4, 0.0, 7.1, 14, 14, 'tacobell.com', ARRAY['volcano sauce', 'lava sauce'], 'Per packet (~14g). Spicy creamy sauce. Limited time offering.'),
('taco_bell_reduced_fat_sour_cream', 'Taco Bell Reduced-Fat Sour Cream', 142.9, 4.8, 9.5, 9.5, 0.0, 4.8, 21, 21, 'tacobell.com', ARRAY['reduced fat sour cream', 'sour cream side'], '30 cal per side (21g).'),
('taco_bell_chicken_quesadilla_combo', 'Taco Bell Chicken Quesadilla Combo', 277.2, 14.1, 20.1, 14.1, 1.1, 1.6, 184, 184, 'tacobell.com', ARRAY['chicken quesadilla combo'], 'Nutrition for quesadilla only. Combo includes drink + side.'),
('taco_bell_cantina_chicken_quesadilla_meal', 'Taco Bell Cantina Chicken Quesadilla Meal', 221.8, 11.3, 16.3, 12.5, 1.6, 1.2, 257, 257, 'tacobell.com', ARRAY['cantina chicken quesadilla meal'], 'Nutrition for quesadilla only. Meal includes drink + side.'),

-- ============================================================================
-- CHIPOTLE
-- ============================================================================

('chipotle_burrito_bowl_chicken', 'Chipotle Chicken Burrito Bowl', 121.8, 9.6, 12.5, 3.9, 1.8, 0.6, 542, 542, 'chipotle.com', ARRAY['burrito bowl', 'chicken burrito bowl', 'chicken bowl'], 'Standard build: rice, beans, chicken, salsa, cheese, lettuce. ~660 cal total (~542g).'),
('chipotle_chips_and_guacamole', 'Chipotle Chips & Guacamole', 339.2, 4.0, 35.7, 20.7, 5.7, 0.9, 227, 227, 'chipotle.com', ARRAY['chips and guacamole', 'chips & guacamole', 'chips guac'], '770 cal per order (8oz/227g).'),
('chipotle_chips_and_queso_blanco', 'Chipotle Chips & Queso Blanco', 343.6, 7.5, 35.2, 18.9, 1.8, 1.3, 227, 227, 'chipotle.com', ARRAY['chips and queso', 'chips & queso blanco', 'chips queso'], '780 cal per order (8oz/227g).'),
('chipotle_chicken_tacos', 'Chipotle Chicken Tacos (3)', 173.7, 12.7, 9.6, 8.8, 0.6, 2.5, 354, 354, 'chipotle.com', ARRAY['chicken tacos', 'three tacos', '3 tacos'], '615 cal total (354g). Standard build with cheese, lettuce, salsa.'),
('chipotle_red_chimichurri', 'Chipotle Red Chimichurri', 322.0, 1.7, 13.6, 28.8, 3.4, 3.4, 59, 59, 'chipotle.com', ARRAY['red chimichurri', 'chimichurri', 'side of red chimichurri'], '190 cal per 2oz/59g.'),

-- ============================================================================
-- PAPA JOHN'S
-- ============================================================================

('papa_johns_philly_cheesesteak_papadia', 'Papa John''s Philly Cheesesteak Papadia', 205.1, 10.1, 20.3, 8.9, 1.0, 2.8, 395, 395, 'papajohns.com', ARRAY['philly cheesesteak papadia', 'papadia'], '810 cal per papadia (395g).'),
('papa_johns_the_works_pizza', 'Papa John''s The Works Pizza (Large Slice)', 215.7, 10.5, 24.8, 9.8, 1.3, 3.3, 153, 153, 'papajohns.com', ARRAY['the works pizza', 'works pizza'], '330 cal per slice (153g). Large 14" original crust, 1/8 pizza.'),
('papa_johns_garlic_epic_stuffed_crust_pizza', 'Papa John''s Garlic Epic Stuffed Crust Pizza (Large Slice)', 238.7, 10.3, 25.2, 10.3, 1.3, 2.6, 155, 155, 'papajohns.com', ARRAY['garlic epic stuffed crust', 'epic stuffed crust pizza', 'stuffed crust'], '370 cal per slice (155g).'),
('papa_johns_cinnamon_pull_aparts', 'Papa John''s Cinnamon Pull Aparts', 411.8, 4.2, 55.5, 20.2, 0.8, 27.7, 119, 119, 'papajohns.com', ARRAY['cinnamon pull aparts', 'pull aparts'], '490 cal per order (119g).'),
('papa_johns_special_garlic_sauce', 'Papa John''s Special Garlic Sauce', 535.7, 0.0, 0.0, 60.7, 0.0, 0.0, 28, 28, 'papajohns.com', ARRAY['special garlic sauce', 'garlic dipping sauce', 'garlic butter sauce'], '150 cal per cup (28g).'),
('papa_johns_spicy_garlic_sauce', 'Papa John''s Spicy Garlic Sauce', 535.7, 0.0, 0.0, 60.7, 0.0, 0.0, 28, 28, 'papajohns.com', ARRAY['spicy garlic sauce', 'spicy garlic dipping sauce'], '150 cal per packet (28g).'),

-- ============================================================================
-- BUFFALO WILD WINGS
-- ============================================================================

('bww_boneless_wings_12ct', 'BWW Boneless Wings (12ct Plain)', 211.8, 17.1, 11.8, 11.2, 0.6, 0.0, 28, 340, 'buffalo_wild_wings_official', ARRAY['boneless wings', 'naked wings', 'bdubs boneless'], 'Plain/naked base; sauce adds 100-300cal. 720 cal for 12ct.'),
('bww_hatch_queso', 'BWW Hatch Queso with Chips', 277.5, 7.0, 29.8, 14.8, 1.5, 2.0, 400, 400, 'buffalo_wild_wings_official', ARRAY['hatch chile con queso', 'bdubs queso', 'hatch queso'], '~1110cal per order.'),
('bww_triple_bacon_cheeseburger', 'BWW Triple-Bacon Cheeseburger', 315.8, 18.9, 10.8, 21.8, 0.8, 2.1, 380, 380, 'buffalo_wild_wings_official', ARRAY['triple bacon burger', 'bdubs burger', 'triple-bacon cheeseburger'], '1200cal. Burger only, no fries.'),
('bww_ultimate_sampler', 'BWW Ultimate Sampler', 330.0, 8.9, 25.0, 16.2, 1.3, 2.2, 900, 900, 'buffalo_wild_wings_official', ARRAY['house sampler', 'bdubs sampler', 'appetizer platter', 'ultimate sampler'], '~2970cal total. Varies by selection.'),
('bww_triple_choc_cookie_skillet', 'BWW Triple Chocolate Chip Cookie Skillet', 330.0, 3.5, 47.5, 14.5, 1.5, 27.5, 200, 200, 'buffalo_wild_wings_official', ARRAY['cookie skillet', 'bdubs dessert', 'chocolate cookie skillet'], '660cal per order.'),
('bww_parmesan_garlic_sauce', 'BWW Parmesan Garlic Sauce', 473.7, 3.5, 10.5, 42.1, 0.0, 1.8, 57, 57, 'buffalo_wild_wings_official', ARRAY['parm garlic', 'parmesan garlic', 'bdubs parmesan garlic'], '270cal per 2oz serving.'),
('bww_bleu_cheese_dressing', 'BWW Bleu Cheese Dressing', 491.2, 3.5, 3.5, 50.9, 0.0, 1.8, 57, 57, 'buffalo_wild_wings_official', ARRAY['blue cheese', 'bleu cheese', 'bdubs bleu cheese'], '280cal per 2oz serving.'),

-- ============================================================================
-- RED ROBIN
-- ============================================================================

('red_robin_madlove_burger', 'Red Robin MadLove Burger', 265.0, 16.3, 16.3, 14.3, 1.8, 4.8, 400, 400, 'red_robin_official', ARRAY['mad love burger', 'madlove'], '1060cal. No fries.'),
('red_robin_haystack_double', 'Red Robin Haystack Double', 246.7, 12.3, 13.0, 13.7, 0.0, 3.3, 300, 300, 'red_robin_official', ARRAY['haystack tavern double', 'haystack burger', 'haystack double'], '740cal. No fries.'),
('red_robin_a1_steakhouse_burger', 'Red Robin A.1. Steakhouse Burger', 307.0, 11.9, 16.5, 21.6, 1.2, 3.0, 430, 430, 'red_robin_official', ARRAY['a1 steakhouse', 'steakhouse burger', 'a.1. steakhouse'], '1320cal. No fries.'),
('red_robin_cookie_dough_mudd_pie', 'Red Robin Cookie Dough Mudd Pie', 306.9, 3.6, 43.3, 13.1, 1.6, 29.6, 450, 450, 'red_robin_official', ARRAY['mudd pie', 'mud pie', 'cookie dough pie', 'cookie dough mudd pie'], '~1381cal.'),
('red_robin_oreo_candy_cane_shake', 'Red Robin OREO Candy Cane Milkshake', 206.7, 3.1, 31.1, 7.8, 0.2, 24.4, 450, 450, 'red_robin_official', ARRAY['oreo candy cane shake', 'candy cane milkshake'], '930cal. Seasonal.'),
('red_robin_strawberry_milkshake', 'Red Robin Strawberry Milkshake', 195.8, 4.0, 27.3, 8.1, 0.4, 24.4, 480, 480, 'red_robin_official', ARRAY['strawberry shake', 'strawberry milkshake'], '940cal.'),
('red_robin_creamy_milkshake', 'Red Robin Creamy Milkshake (Vanilla)', 195.8, 3.8, 27.9, 8.1, 0.2, 25.0, 480, 480, 'red_robin_official', ARRAY['vanilla milkshake', 'creamy shake', 'creamy milkshake'], '940cal.'),

-- ============================================================================
-- STEAK 'N SHAKE
-- ============================================================================

('steak_n_shake_cheese_fries', 'Steak n Shake Cheese Fries', 165.0, 2.5, 19.0, 9.0, 1.5, 0.5, 200, 200, 'steak_n_shake_official', ARRAY['cheese fries'], '330cal regular size.'),
('steak_n_shake_chicken_fingers_3pc', 'Steak n Shake 3 PC Chicken Fingers', 247.1, 13.5, 18.8, 14.1, 1.2, 0.6, 57, 170, 'steak_n_shake_official', ARRAY['chicken fingers', 'chicken tenders', '3 pc chicken fingers'], '420cal for 3 pieces.'),
('steak_n_shake_side_cheese_sauce', 'Steak n Shake Side Cheese Sauce', 228.6, 0.0, 8.6, 20.0, 0.0, 2.9, 35, 35, 'steak_n_shake_official', ARRAY['cheese sauce', 'side cheese', 'side cheese sauce'], '80cal per side cup.'),
('steak_n_shake_garlic_double', 'Steak n Shake Garlic Double Steakburger', 260.7, 10.0, 11.8, 17.9, 0.4, 1.8, 280, 280, 'steak_n_shake_official', ARRAY['garlic double steakburger', 'garlic burger', 'garlic double steakburger combo'], '730cal burger only.'),

-- ============================================================================
-- PANDA EXPRESS
-- ============================================================================

('panda_express_bigger_plate', 'Panda Express Bigger Plate', 220.9, 7.9, 26.6, 9.5, 1.1, 4.1, 738, 738, 'panda_express_official', ARRAY['bigger plate', 'panda bigger plate'], '~1630cal total. Varies by entree selection.'),
('panda_express_teriyaki_sauce', 'Panda Express Teriyaki Sauce', 137.3, 2.0, 29.4, 0.0, 0.0, 23.5, 51, 51, 'panda_express_official', ARRAY['teriyaki sauce packet', 'mandarin teriyaki'], '70cal per 1.8oz packet.'),
('panda_express_chili_sauce', 'Panda Express Chili Sauce', 166.7, 0.0, 33.3, 0.0, 0.0, 16.7, 6, 6, 'panda_express_official', ARRAY['chili sauce packet'], '10cal per packet (0.2oz).'),
('panda_express_soy_sauce', 'Panda Express Soy Sauce', 83.3, 0.0, 0.0, 0.0, 0.0, 0.0, 6, 6, 'panda_express_official', ARRAY['soy sauce packet'], '5cal per packet. Very high sodium.'),

-- ============================================================================
-- BOB EVANS
-- ============================================================================

('bob_evans_reeses_pb_pie', 'Bob Evans Reese''s Peanut Butter Pie', 355.6, 4.4, 38.3, 23.3, 1.1, 26.7, 180, 180, 'bob_evans_official', ARRAY['reeses pie', 'peanut butter pie', 'reeses peanut butter pie'], '640cal per slice.'),

-- ============================================================================
-- HOKKAIDO (Japanese)
-- ============================================================================

('hokkaido_onion_soup', 'Hokkaido Onion Soup (Japanese)', 20.0, 0.8, 2.8, 0.4, 0.4, 1.2, 250, 250, 'generic_japanese', ARRAY['japanese onion soup', 'hibachi soup', 'clear onion soup', 'onion soup'], '~50cal per 250ml.'),
('hokkaido_rainbow_fried_rice', 'Hokkaido Rainbow Fried Rice (Hibachi)', 175.0, 4.0, 25.0, 5.0, 0.9, 0.6, 350, 350, 'generic_japanese', ARRAY['hibachi fried rice', 'rainbow rice', 'japanese fried rice', 'rainbow fried rice', 'rainbow fried rice combination'], '~612cal per 350g serving.'),
('hokkaido_gyoza', 'Hokkaido Gyoza (per piece)', 228.0, 8.0, 28.0, 10.0, 2.0, 2.0, 25, 25, 'generic_japanese', ARRAY['gyoza', 'potsticker', 'japanese dumpling'], '~57cal per piece (25g). Order of 8 = ~456cal.'),

-- ============================================================================
-- CURLY SHAWARMA (Middle Eastern)
-- ============================================================================

('curly_shawarma_mix_grill', 'Curly Shawarma Mix Grill Plate', 200.0, 8.0, 22.0, 7.0, 0.8, 0.6, 500, 500, 'generic_middle_eastern', ARRAY['mixed grill plate', 'shawarma plate', 'mix grill plate'], '~1000cal per 500g plate.'),
('curly_shawarma_tahini', 'Curly Shawarma Tahini Sauce', 593.3, 17.3, 21.3, 54.0, 4.7, 1.3, 15, 15, 'generic_middle_eastern', ARRAY['tahini', 'tahina', 'sesame sauce', 'tahini sauce'], '89cal per tablespoon (15g).'),
('curly_shawarma_garlic_sauce', 'Curly Shawarma Garlic Sauce (Toum)', 600.0, 0.0, 3.3, 66.7, 0.0, 0.0, 15, 15, 'generic_middle_eastern', ARRAY['toum', 'garlic whip', 'lebanese garlic sauce', 'garlic sauce'], '~90cal per tablespoon (15g).'),
('curly_shawarma_hot_sauce', 'Curly Shawarma Hot Sauce (Shatta)', 166.7, 0.7, 13.3, 13.3, 3.3, 3.3, 15, 15, 'generic_middle_eastern', ARRAY['shatta', 'middle eastern hot sauce'], '~25cal per tablespoon.'),

-- ============================================================================
-- KUNG FU TEA
-- ============================================================================

('kung_fu_tea_mega_matcha', 'Kung Fu Tea Mega Matcha Evolution (Large)', 92.9, 2.4, 12.1, 2.4, 0.1, 10.0, 700, 700, 'kung_fu_tea_estimated', ARRAY['mega matcha evolution', 'matcha bubble tea', 'kft matcha'], '~650cal per 700ml.'),

-- ============================================================================
-- THE SHAKE BAR
-- ============================================================================

('shake_bar_creamy_dream', 'The Shake Bar Creamy Dream', 120.0, 2.4, 16.0, 5.0, 0.2, 13.0, 500, 500, 'generic_milkshake', ARRAY['creamy dream'], '~600cal per 500ml.'),
('shake_bar_sweet_dreams', 'The Shake Bar Sweet Dreams', 130.0, 2.4, 18.0, 5.4, 0.2, 14.4, 500, 500, 'generic_milkshake', ARRAY['sweet dreams'], '~650cal per 500ml.'),
('shake_bar_blended_fantasy', 'The Shake Bar Blended Fantasy', 124.0, 2.2, 17.0, 4.8, 0.4, 13.6, 500, 500, 'generic_milkshake', ARRAY['blended fantasy'], '~620cal per 500ml.'),

-- ============================================================================
-- DRINKS: DIET / ZERO-CALORIE
-- ============================================================================

('diet_coke', 'Diet Coke', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 355, 355, 'manufacturer', ARRAY['diet coca-cola', 'coca-cola diet', 'coke diet'], '0 cal per 12oz can. Sweetened with aspartame.'),
('diet_pepsi', 'Diet Pepsi', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 355, 355, 'manufacturer', ARRAY['pepsi diet'], '0 cal per 12oz can. Sweetened with aspartame.'),
('coke_zero', 'Coke Zero Sugar', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 355, 355, 'manufacturer', ARRAY['coca-cola zero', 'coke zero sugar', 'coca-cola zero sugar', 'zero coke'], '0 cal per 12oz can.'),
('pepsi_zero', 'Pepsi Zero Sugar', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 355, 355, 'manufacturer', ARRAY['pepsi zero', 'pepsi max', 'pepsi zero sugar'], '0 cal per 12oz can.'),

-- ============================================================================
-- DRINKS: REGULAR SODAS
-- ============================================================================

('coca_cola', 'Coca-Cola', 37.8, 0.0, 10.5, 0.0, 0.0, 10.5, 370, 370, 'manufacturer', ARRAY['coke', 'coca cola', 'coca-cola classic', 'coke classic', 'regular coke'], '140 cal per 12oz can (370g).'),
('mexican_coca_cola', 'Mexican Coca-Cola', 40.5, 0.0, 10.8, 0.0, 0.0, 10.8, 370, 370, 'manufacturer', ARRAY['mexican coke', 'coca-cola mexico', 'coke mexico', 'coca cola de mexico'], '150 cal per 12oz bottle. Made with cane sugar.'),
('pepsi', 'Pepsi', 40.5, 0.0, 11.1, 0.0, 0.0, 11.1, 370, 370, 'manufacturer', ARRAY['pepsi cola', 'pepsi-cola', 'regular pepsi'], '150 cal per 12oz can.'),
('mountain_dew', 'Mountain Dew', 45.9, 0.0, 12.4, 0.0, 0.0, 12.4, 370, 370, 'manufacturer', ARRAY['mtn dew', 'mt dew', 'mountain dew original'], '170 cal per 12oz can.'),

-- ============================================================================
-- PACKAGED SNACKS
-- ============================================================================

('doritos', 'Doritos Nacho Cheese', 500.0, 7.1, 57.1, 28.6, 3.6, 0.0, 28, 28, 'manufacturer', ARRAY['doritos nacho', 'nacho cheese doritos', 'doritos nacho cheese'], '140 cal per 1oz bag (28g).'),
('pringles', 'Pringles Original', 536.0, 3.6, 57.1, 32.1, 1.8, 0.0, 28, 28, 'manufacturer', ARRAY['pringles original', 'pringles chips', 'pringles crisps'], '150 cal per 1oz (28g).'),
('fritos', 'Fritos Original', 571.0, 7.1, 57.1, 35.7, 3.6, 0.0, 28, 28, 'manufacturer', ARRAY['fritos original', 'fritos corn chips', 'original fritos'], '160 cal per 1oz bag (28g).'),

-- ============================================================================
-- CANDY
-- ============================================================================

('twizzlers', 'Twizzlers Strawberry', 356.0, 2.2, 80.0, 1.1, 0.0, 42.2, 11, 45, 'manufacturer', ARRAY['twizzlers strawberry twists', 'strawberry twizzlers', 'twizzler', 'red licorice'], 'Per piece ~11g (40 cal). 4 pieces = 45g = 160 cal.'),
('laffy_taffy', 'Laffy Taffy', 333.0, 0.0, 78.6, 4.8, 0.0, 45.2, 14, 42, 'manufacturer', ARRAY['laffy taffy candy', 'laffy taffy assorted'], 'Per piece ~14g (47 cal). 3 pieces = 42g = 140 cal.'),
('nerds', 'Nerds Candy', 400.0, 0.0, 93.3, 0.0, 0.0, 86.7, 15, 15, 'manufacturer', ARRAY['nerds candy', 'wonka nerds', 'nerds grape strawberry'], '60 cal per mini box (15g). Nearly pure sugar.'),

-- ============================================================================
-- SAUCES & CONDIMENTS (generic)
-- ============================================================================

('soy_sauce', 'Soy Sauce', 53.0, 8.1, 4.9, 0.6, 0.6, 0.4, NULL, 16, 'usda', ARRAY['shoyu', 'soy sauce regular', 'dark soy sauce', 'kikkoman soy sauce'], '9 cal per 1 tbsp (16g). Very high sodium.'),
('teriyaki_sauce', 'Teriyaki Sauce', 89.0, 5.9, 15.6, 0.0, 0.1, 7.6, NULL, 18, 'usda', ARRAY['teriyaki', 'teriyaki glaze', 'kikkoman teriyaki'], '16 cal per 1 tbsp (18g).'),
('hot_sauce', 'Hot Sauce', 20.0, 0.0, 4.0, 0.0, 0.0, 2.0, NULL, 5, 'usda', ARRAY['sriracha', 'franks red hot', 'tabasco', 'cholula', 'valentina', 'tapatio'], '~1 cal per tsp (5g). Negligible calories.')

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
  updated_at = NOW();
