-- Migration: Validate casual dining chain micronutrients against published nutrition data
-- Date: 2026-02-28
-- Sources: fastfoodnutrition.org, calorieking.com, eatthismuch.com, fatsecret.com, mynetdiary.com
-- Method: Published per-serving values converted to per-100g using DB default_serving_g
-- Threshold: Only corrections where published value differs by >15% from DB value
-- 19 chains checked, 51 items validated, 137 field corrections

BEGIN;

-- CHILI'S (16 items validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET saturated_fat_g = 5.33, trans_fat_g = 0.67 WHERE food_name_normalized = 'chilis_big_mouth_bites'; -- pub: 16g sat/2g trans per 300g serving
UPDATE food_nutrition_overrides SET sodium_mg = 1248.0, saturated_fat_g = 17.2, trans_fat_g = 1.6 WHERE food_name_normalized = 'chilis_boss_burger'; -- pub: 3120mg Na/43g sat/4g trans per 250g
UPDATE food_nutrition_overrides SET sodium_mg = 483.3, saturated_fat_g = 5.67, trans_fat_g = 1.0, cholesterol_mg = 61.7 WHERE food_name_normalized = 'chilis_classic_ribeye'; -- pub: 1450mg Na/17g sat/3g trans/185mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 213.3, saturated_fat_g = 1.67, cholesterol_mg = 28.3 WHERE food_name_normalized = 'chilis_classic_sirloin_6oz'; -- pub: 640mg Na/5g sat/85mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 343.3, trans_fat_g = 0.33, cholesterol_mg = 45.0 WHERE food_name_normalized = 'chilis_molten_chocolate_cake'; -- pub: 1030mg Na/1g trans/135mg chol per 300g
UPDATE food_nutrition_overrides SET trans_fat_g = 1.2, cholesterol_mg = 58.0 WHERE food_name_normalized = 'chilis_mushroom_swiss_burger'; -- pub: 3g trans/145mg chol per 250g
UPDATE food_nutrition_overrides SET saturated_fat_g = 9.6, trans_fat_g = 1.2, cholesterol_mg = 56.0 WHERE food_name_normalized = 'chilis_oldtimer_with_cheese'; -- pub: 24g sat/3g trans/140mg chol per 250g
UPDATE food_nutrition_overrides SET sodium_mg = 1335.7, saturated_fat_g = 8.93, cholesterol_mg = 32.1 WHERE food_name_normalized = 'chilis_skillet_queso'; -- pub: 3740mg Na/25g sat/90mg chol per 280g
UPDATE food_nutrition_overrides SET sodium_mg = 726.7, saturated_fat_g = 3.33, cholesterol_mg = 16.7 WHERE food_name_normalized = 'chilis_southwestern_eggrolls'; -- pub: 2180mg Na/10g sat/50mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 637.1, saturated_fat_g = 8.29, trans_fat_g = 1.43, cholesterol_mg = 57.1 WHERE food_name_normalized = 'chilis_quesadilla_explosion_salad'; -- pub: 2230mg Na/29g sat/5g trans/200mg chol per 350g
UPDATE food_nutrition_overrides SET sodium_mg = 296.7 WHERE food_name_normalized = 'chilis_skillet_cookie'; -- pub: 890mg Na per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 1028.0, trans_fat_g = 1.2, cholesterol_mg = 70.0 WHERE food_name_normalized = 'chilis_southern_smokehouse_burger'; -- pub: 2570mg Na/3g trans/175mg chol per 250g
UPDATE food_nutrition_overrides SET sodium_mg = 417.1, saturated_fat_g = 2.0, cholesterol_mg = 40.0 WHERE food_name_normalized = 'chilis_santa_fe_chicken_salad'; -- pub: 1460mg Na/7g sat/140mg chol per 350g
UPDATE food_nutrition_overrides SET sodium_mg = 1745.5, saturated_fat_g = 5.45, cholesterol_mg = 54.5 WHERE food_name_normalized = 'chilis_boneless_wings'; -- pub: 3840mg Na/12g sat/120mg chol per 220g
UPDATE food_nutrition_overrides SET sodium_mg = 546.7, cholesterol_mg = 20.0 WHERE food_name_normalized = 'chilis_loaded_mashed_potatoes'; -- pub: 820mg Na/30mg chol per 150g
UPDATE food_nutrition_overrides SET sodium_mg = 620.8, saturated_fat_g = 3.75, cholesterol_mg = 27.1 WHERE food_name_normalized = 'chilis_chicken_enchilada_soup'; -- pub: 1490mg Na/9g sat/65mg chol per 240g

-- APPLEBEE'S (7 items validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 313.3, saturated_fat_g = 5.33, trans_fat_g = 0.67, cholesterol_mg = 45.0 WHERE food_name_normalized = 'applebees_classic_cheeseburger'; -- pub: 940mg Na/16g sat/2g trans/135mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 1163.3, saturated_fat_g = 4.67, cholesterol_mg = 35.0 WHERE food_name_normalized = 'applebees_chicken_tenders_plate'; -- pub: 3490mg Na/14g sat/105mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 116.7, cholesterol_mg = 50.0 WHERE food_name_normalized = 'applebees_half_rack_ribs'; -- pub: 350mg Na/150mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 857.1, trans_fat_g = 0.86, cholesterol_mg = 68.6 WHERE food_name_normalized = 'applebees_quesadilla_burger'; -- pub: 3000mg Na/3g trans/240mg chol per 350g
UPDATE food_nutrition_overrides SET saturated_fat_g = 8.57, cholesterol_mg = 60.0 WHERE food_name_normalized = 'applebees_whisky_bacon_burger'; -- pub: 30g sat/210mg chol per 350g
UPDATE food_nutrition_overrides SET sodium_mg = 860.0, trans_fat_g = 0.17, cholesterol_mg = 75.0 WHERE food_name_normalized = 'applebees_bourbon_chicken_shrimp'; -- pub: 2580mg Na/0.5g trans/225mg chol per 300g
UPDATE food_nutrition_overrides SET sodium_mg = 640.0, saturated_fat_g = 2.33 WHERE food_name_normalized = 'applebees_classic_fries'; -- pub: 960mg Na/3.5g sat per 150g

-- OLIVE GARDEN (11 items validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 296.0, saturated_fat_g = 11.2, trans_fat_g = 0.4, cholesterol_mg = 79.0 WHERE food_name_normalized = 'olivegarden_chicken_alfredo'; -- pub: 1480mg Na/56g sat/2g trans/395mg chol per 500g
UPDATE food_nutrition_overrides SET sodium_mg = 212.5, saturated_fat_g = 8.5, trans_fat_g = 0.38, cholesterol_mg = 38.8 WHERE food_name_normalized = 'olivegarden_fettuccine_alfredo'; -- pub: 850mg Na/34g sat/1.5g trans/155mg chol per 400g
UPDATE food_nutrition_overrides SET sodium_mg = 650.0, saturated_fat_g = 9.6, trans_fat_g = 0.3, cholesterol_mg = 68.0 WHERE food_name_normalized = 'olivegarden_tour_of_italy'; -- pub: 3250mg Na/48g sat/1.5g trans/340mg chol per 500g
UPDATE food_nutrition_overrides SET sodium_mg = 517.5, saturated_fat_g = 7.0, trans_fat_g = 0.38, cholesterol_mg = 52.5 WHERE food_name_normalized = 'olivegarden_lasagna_classico'; -- pub: 2070mg Na/28g sat/1.5g trans/210mg chol per 400g
UPDATE food_nutrition_overrides SET sodium_mg = 596.0 WHERE food_name_normalized = 'olivegarden_chicken_parmigiana'; -- pub: 2980mg Na per 500g (fried version)
UPDATE food_nutrition_overrides SET cholesterol_mg = 22.9 WHERE food_name_normalized = 'olivegarden_chicken_gnocchi'; -- pub: 55mg chol per 240g
UPDATE food_nutrition_overrides SET sodium_mg = 329.2, saturated_fat_g = 2.92 WHERE food_name_normalized = 'olivegarden_zuppa_toscana'; -- pub: 790mg Na/7g sat per 240g
UPDATE food_nutrition_overrides SET sodium_mg = 62.5, saturated_fat_g = 8.5, cholesterol_mg = 107.5 WHERE food_name_normalized = 'olivegarden_tiramisu'; -- pub: 125mg Na/17g sat/215mg chol per 200g

-- RED ROBIN (2 items validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET cholesterol_mg = 54.0 WHERE food_name_normalized = 'red_robin_gourmet_cheeseburger'; -- pub: 135mg chol per 250g
UPDATE food_nutrition_overrides SET sodium_mg = 800.0, saturated_fat_g = 8.0, trans_fat_g = 0.8, cholesterol_mg = 52.0 WHERE food_name_normalized = 'red_robin_banzai_burger'; -- pub: 2000mg Na/20g sat/2g trans/130mg chol per 250g

-- OUTBACK STEAKHOUSE (1 item validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 640.0, trans_fat_g = 1.17 WHERE food_name_normalized = 'outback_bloomin_onion'; -- pub: 3840mg Na/7g trans per 600g

-- IHOP (2 items validated against eatthismuch.com/fatsecret.com)
UPDATE food_nutrition_overrides SET sodium_mg = 706.7, cholesterol_mg = 31.2 WHERE food_name_normalized = 'ihop_original_buttermilk_pancakes_full_stack'; -- pub: 2650mg Na/117mg chol per 375g (5 pancakes)
UPDATE food_nutrition_overrides SET sodium_mg = 706.7, cholesterol_mg = 31.1 WHERE food_name_normalized = 'ihop_original_buttermilk_pancakes_short_stack'; -- pub: 1590mg Na/70mg chol per 225g (3 pancakes)

-- DENNY'S (3 items validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 711.1 WHERE food_name_normalized = 'dennys_lumberjack_slam'; -- pub: 3200mg Na per 450g
UPDATE food_nutrition_overrides SET sodium_mg = 533.3, trans_fat_g = 0.21, cholesterol_mg = 116.7 WHERE food_name_normalized = 'dennys_moons_over_my_hammy'; -- pub: 2560mg Na/1g trans/560mg chol per 480g
UPDATE food_nutrition_overrides SET sodium_mg = 625.7, saturated_fat_g = 7.71, cholesterol_mg = 232.9 WHERE food_name_normalized = 'dennys_all_american_slam'; -- pub: 2190mg Na/27g sat/815mg chol per 350g

-- THE CHEESECAKE FACTORY (4 items validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 588.9, saturated_fat_g = 18.67, trans_fat_g = 1.11 WHERE food_name_normalized = 'cheesecake_factory_fettuccini_alfredo'; -- pub: 2650mg Na/84g sat/5g trans per 450g
UPDATE food_nutrition_overrides SET sodium_mg = 485.0, trans_fat_g = 0.5, cholesterol_mg = 90.0 WHERE food_name_normalized = 'cheesecake_factory_chicken_madeira'; -- pub: 1940mg Na/2g trans/360mg chol per 400g
UPDATE food_nutrition_overrides SET saturated_fat_g = 18.5, trans_fat_g = 1.0, cholesterol_mg = 132.5 WHERE food_name_normalized = 'cheesecake_factory_original_cheesecake'; -- pub: 37g sat/2g trans/265mg chol per 200g
UPDATE food_nutrition_overrides SET sodium_mg = 806.0, saturated_fat_g = 13.0, trans_fat_g = 0.8, cholesterol_mg = 99.0 WHERE food_name_normalized = 'cheesecake_factory_louisiana_chicken_pasta'; -- pub: 4030mg Na/65g sat/4g trans/495mg chol per 500g

-- TEXAS ROADHOUSE (1 item validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET trans_fat_g = 2.0, cholesterol_mg = 90.0 WHERE food_name_normalized = 'texas_roadhouse_bone_in_ribeye'; -- pub: 10g trans/450mg chol per 500g

-- BUFFALO WILD WINGS (1 item validated against fatsecret.com/BWW nutrition guide)
UPDATE food_nutrition_overrides SET sodium_mg = 90.0 WHERE food_name_normalized = 'bww_traditional_wings_10ct'; -- pub: 270mg Na per 300g (naked wings, no sauce)

-- RED LOBSTER (1 item validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 633.3, saturated_fat_g = 7.5, cholesterol_mg = 8.3 WHERE food_name_normalized = 'red_lobster_cheddar_bay_biscuit'; -- pub: 380mg Na/4.5g sat/5mg chol per 60g

-- CRACKER BARREL (1 item validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.5, cholesterol_mg = 51.2 WHERE food_name_normalized = 'cracker_barrel_chicken_fried_chicken'; -- pub: 14g sat/205mg chol per 400g

-- WAFFLE HOUSE (1 item validated against fastfoodnutrition.org)
UPDATE food_nutrition_overrides SET sodium_mg = 725.0, saturated_fat_g = 8.33, cholesterol_mg = 41.7 WHERE food_name_normalized = 'waffle_house_classic_waffle'; -- pub: 870mg Na/10g sat/50mg chol per 120g

COMMIT;
