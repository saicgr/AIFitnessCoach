-- 330_fix_micronutrients_missed.sql
-- Fix 98 rows that got generic catch-all defaults from migration 329.
-- These items were missed by migrations 325-328 due to food_name_normalized
-- not matching (spaces vs underscores, different naming, etc.)
-- All values per 100g from USDA / brand data.

-- Common staple foods with space-separated names
UPDATE food_nutrition_overrides SET
  sodium_mg = 74, cholesterol_mg = 85, saturated_fat_g = 1.0, trans_fat_g = 0.0,
  potassium_mg = 256, calcium_mg = 15, iron_mg = 1.0, vitamin_a_ug = 6,
  vitamin_c_mg = 0, vitamin_d_iu = 5, magnesium_mg = 29, zinc_mg = 1.0,
  phosphorus_mg = 228, selenium_ug = 27.6, omega3_g = 0.01
WHERE food_name_normalized = 'chicken breast';

UPDATE food_nutrition_overrides SET
  sodium_mg = 84, cholesterol_mg = 110, saturated_fat_g = 2.3, trans_fat_g = 0.0,
  potassium_mg = 240, calcium_mg = 11, iron_mg = 1.1, vitamin_a_ug = 14,
  vitamin_c_mg = 0, vitamin_d_iu = 5, magnesium_mg = 25, zinc_mg = 2.0,
  phosphorus_mg = 195, selenium_ug = 24.0, omega3_g = 0.03
WHERE food_name_normalized = 'chicken thigh';

UPDATE food_nutrition_overrides SET
  sodium_mg = 166, cholesterol_mg = 0, saturated_fat_g = 0.3, trans_fat_g = 0.0,
  potassium_mg = 164, calcium_mg = 27, iron_mg = 2.4, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 69, zinc_mg = 1.5,
  phosphorus_mg = 210, selenium_ug = 7.5, omega3_g = 0.04
WHERE food_name_normalized = 'oats';

UPDATE food_nutrition_overrides SET
  sodium_mg = 142, cholesterol_mg = 372, saturated_fat_g = 3.1, trans_fat_g = 0.0,
  potassium_mg = 138, calcium_mg = 56, iron_mg = 1.8, vitamin_a_ug = 160,
  vitamin_c_mg = 0, vitamin_d_iu = 82, magnesium_mg = 12, zinc_mg = 1.3,
  phosphorus_mg = 198, selenium_ug = 30.7, omega3_g = 0.07
WHERE food_name_normalized = 'egg';

UPDATE food_nutrition_overrides SET
  sodium_mg = 166, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 163, calcium_mg = 7, iron_mg = 0.1, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 11, zinc_mg = 0.0,
  phosphorus_mg = 15, selenium_ug = 20.0, omega3_g = 0.0
WHERE food_name_normalized = 'egg white';

UPDATE food_nutrition_overrides SET
  sodium_mg = 36, cholesterol_mg = 5, saturated_fat_g = 0.6, trans_fat_g = 0.0,
  potassium_mg = 141, calcium_mg = 113, iron_mg = 0.1, vitamin_a_ug = 15,
  vitamin_c_mg = 0, vitamin_d_iu = 1, magnesium_mg = 11, zinc_mg = 0.4,
  phosphorus_mg = 84, selenium_ug = 3.3, omega3_g = 0.01
WHERE food_name_normalized = 'greek yogurt';

UPDATE food_nutrition_overrides SET
  sodium_mg = 43, cholesterol_mg = 5, saturated_fat_g = 1.9, trans_fat_g = 0.0,
  potassium_mg = 132, calcium_mg = 113, iron_mg = 0.0, vitamin_a_ug = 28,
  vitamin_c_mg = 0, vitamin_d_iu = 41, magnesium_mg = 10, zinc_mg = 0.4,
  phosphorus_mg = 84, selenium_ug = 3.7, omega3_g = 0.02
WHERE food_name_normalized = 'milk';

UPDATE food_nutrition_overrides SET
  sodium_mg = 17, cholesterol_mg = 0, saturated_fat_g = 3.3, trans_fat_g = 0.0,
  potassium_mg = 558, calcium_mg = 92, iron_mg = 1.7, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 168, zinc_mg = 3.1,
  phosphorus_mg = 376, selenium_ug = 4.1, omega3_g = 0.0
WHERE food_name_normalized = 'peanut butter';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 0, saturated_fat_g = 0.5, trans_fat_g = 0.0,
  potassium_mg = 254, calcium_mg = 161, iron_mg = 2.8, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 75, zinc_mg = 1.8,
  phosphorus_mg = 200, selenium_ug = 31.0, omega3_g = 0.02
WHERE food_name_normalized = 'whole wheat bread';

-- Branded sodas/drinks (per 100g/100ml)
UPDATE food_nutrition_overrides SET
  sodium_mg = 4, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 2, calcium_mg = 1, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 10, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'pepsi';

UPDATE food_nutrition_overrides SET
  sodium_mg = 10, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 4, calcium_mg = 1, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 0, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'pepsi_zero';

UPDATE food_nutrition_overrides SET
  sodium_mg = 10, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 4, calcium_mg = 1, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 0, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'diet_pepsi';

UPDATE food_nutrition_overrides SET
  sodium_mg = 10, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 4, calcium_mg = 1, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 0, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'coke_zero';

UPDATE food_nutrition_overrides SET
  sodium_mg = 10, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 4, calcium_mg = 1, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 0, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'diet_coke';

UPDATE food_nutrition_overrides SET
  sodium_mg = 17, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 3, calcium_mg = 1, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 2, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'mountain_dew';

-- Branded snacks (per 100g)
UPDATE food_nutrition_overrides SET
  sodium_mg = 570, cholesterol_mg = 0, saturated_fat_g = 3.1, trans_fat_g = 0.0,
  potassium_mg = 350, calcium_mg = 50, iron_mg = 1.0, vitamin_a_ug = 0,
  vitamin_c_mg = 9, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 0.5,
  phosphorus_mg = 80, selenium_ug = 3.0, omega3_g = 0.02
WHERE food_name_normalized = 'pringles';

UPDATE food_nutrition_overrides SET
  sodium_mg = 430, cholesterol_mg = 0, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 325, calcium_mg = 20, iron_mg = 0.8, vitamin_a_ug = 0,
  vitamin_c_mg = 10, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 0.5,
  phosphorus_mg = 60, selenium_ug = 3.0, omega3_g = 0.05
WHERE food_name_normalized = 'fritos';

UPDATE food_nutrition_overrides SET
  sodium_mg = 40, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 5, calcium_mg = 0, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 0, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'twizzlers';

UPDATE food_nutrition_overrides SET
  sodium_mg = 20, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 5, calcium_mg = 0, iron_mg = 0.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 0, zinc_mg = 0.0,
  phosphorus_mg = 0, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'nerds';

UPDATE food_nutrition_overrides SET
  sodium_mg = 50, cholesterol_mg = 0, saturated_fat_g = 1.0, trans_fat_g = 0.0,
  potassium_mg = 10, calcium_mg = 5, iron_mg = 0.1, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 2, zinc_mg = 0.0,
  phosphorus_mg = 5, selenium_ug = 0.0, omega3_g = 0.0
WHERE food_name_normalized = 'laffy_taffy';

-- Almonds (per 100g, USDA)
UPDATE food_nutrition_overrides SET
  sodium_mg = 1, cholesterol_mg = 0, saturated_fat_g = 3.7, trans_fat_g = 0.0,
  potassium_mg = 705, calcium_mg = 264, iron_mg = 3.7, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 268, zinc_mg = 3.1,
  phosphorus_mg = 484, selenium_ug = 4.1, omega3_g = 0.0
WHERE food_name_normalized = 'almonds';

-- Hot Sauce (per 100g)
UPDATE food_nutrition_overrides SET
  sodium_mg = 2640, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 110, calcium_mg = 10, iron_mg = 0.5, vitamin_a_ug = 30,
  vitamin_c_mg = 12, vitamin_d_iu = 0, magnesium_mg = 5, zinc_mg = 0.1,
  phosphorus_mg = 15, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'hot_sauce';

-- McDonald's items
UPDATE food_nutrition_overrides SET
  sodium_mg = 560, cholesterol_mg = 45, saturated_fat_g = 5.5, trans_fat_g = 0.3,
  potassium_mg = 165, calcium_mg = 60, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 18, zinc_mg = 1.8,
  phosphorus_mg = 140, selenium_ug = 15.0, omega3_g = 0.05
WHERE food_name_normalized = 'mcdonalds_chicken_mcnuggets_6pc';

UPDATE food_nutrition_overrides SET
  sodium_mg = 560, cholesterol_mg = 45, saturated_fat_g = 5.5, trans_fat_g = 0.3,
  potassium_mg = 165, calcium_mg = 60, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 18, zinc_mg = 1.8,
  phosphorus_mg = 140, selenium_ug = 15.0, omega3_g = 0.05
WHERE food_name_normalized = 'mcdonalds_chicken_mcnuggets_10pc';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 35, saturated_fat_g = 4.8, trans_fat_g = 0.2,
  potassium_mg = 150, calcium_mg = 55, iron_mg = 1.3, vitamin_a_ug = 12,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 16, zinc_mg = 1.5,
  phosphorus_mg = 130, selenium_ug = 14.0, omega3_g = 0.04
WHERE food_name_normalized = 'mcdonalds_chicken_mcnuggets_10pc_meal';

UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 50, saturated_fat_g = 6.0, trans_fat_g = 0.5,
  potassium_mg = 180, calcium_mg = 120, iron_mg = 2.5, vitamin_a_ug = 30,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 2.5,
  phosphorus_mg = 180, selenium_ug = 18.0, omega3_g = 0.06
WHERE food_name_normalized = 'mcdonalds_cheeseburger';

UPDATE food_nutrition_overrides SET
  sodium_mg = 480, cholesterol_mg = 80, saturated_fat_g = 8.0, trans_fat_g = 0.8,
  potassium_mg = 250, calcium_mg = 130, iron_mg = 3.5, vitamin_a_ug = 25,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 4.0,
  phosphorus_mg = 220, selenium_ug = 25.0, omega3_g = 0.08
WHERE food_name_normalized = 'mcdonalds_double_quarter_pounder_cheese';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 40, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 30, iron_mg = 1.8, vitamin_a_ug = 10,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 1.0,
  phosphorus_mg = 150, selenium_ug = 15.0, omega3_g = 0.04
WHERE food_name_normalized = 'mcdonalds_hot_n_spicy_mcchicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 440, cholesterol_mg = 35, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 180, calcium_mg = 28, iron_mg = 1.5, vitamin_a_ug = 8,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 18, zinc_mg = 0.9,
  phosphorus_mg = 130, selenium_ug = 13.0, omega3_g = 0.04
WHERE food_name_normalized = 'mcdonalds_hot_n_spicy_mcchicken_meal';

UPDATE food_nutrition_overrides SET
  sodium_mg = 520, cholesterol_mg = 45, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 210, calcium_mg = 35, iron_mg = 1.8, vitamin_a_ug = 12,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 1.2,
  phosphorus_mg = 155, selenium_ug = 16.0, omega3_g = 0.04
WHERE food_name_normalized = 'mcdonalds_spicy_mccrispy';

UPDATE food_nutrition_overrides SET
  sodium_mg = 460, cholesterol_mg = 38, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 190, calcium_mg = 30, iron_mg = 1.5, vitamin_a_ug = 10,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 1.0,
  phosphorus_mg = 140, selenium_ug = 14.0, omega3_g = 0.04
WHERE food_name_normalized = 'mcdonalds_spicy_mccrispy_meal';

UPDATE food_nutrition_overrides SET
  sodium_mg = 800, cholesterol_mg = 20, saturated_fat_g = 2.0, trans_fat_g = 0.0,
  potassium_mg = 50, calcium_mg = 5, iron_mg = 0.3, vitamin_a_ug = 5,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 5, zinc_mg = 0.3,
  phosphorus_mg = 50, selenium_ug = 5.0, omega3_g = 0.01
WHERE food_name_normalized = 'mcdonalds_bacon_side';

-- BWW (Buffalo Wild Wings) items
UPDATE food_nutrition_overrides SET
  sodium_mg = 550, cholesterol_mg = 50, saturated_fat_g = 4.5, trans_fat_g = 0.0,
  potassium_mg = 180, calcium_mg = 25, iron_mg = 1.2, vitamin_a_ug = 8,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 1.5,
  phosphorus_mg = 160, selenium_ug = 15.0, omega3_g = 0.04
WHERE food_name_normalized = 'bww_boneless_wings_12ct';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 70, saturated_fat_g = 8.0, trans_fat_g = 0.5,
  potassium_mg = 200, calcium_mg = 120, iron_mg = 2.5, vitamin_a_ug = 25,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 3.0,
  phosphorus_mg = 180, selenium_ug = 18.0, omega3_g = 0.06
WHERE food_name_normalized = 'bww_triple_bacon_cheeseburger';

UPDATE food_nutrition_overrides SET
  sodium_mg = 600, cholesterol_mg = 15, saturated_fat_g = 5.0, trans_fat_g = 0.0,
  potassium_mg = 30, calcium_mg = 30, iron_mg = 0.2, vitamin_a_ug = 20,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 3, zinc_mg = 0.2,
  phosphorus_mg = 30, selenium_ug = 1.0, omega3_g = 0.1
WHERE food_name_normalized = 'bww_bleu_cheese_dressing';

UPDATE food_nutrition_overrides SET
  sodium_mg = 700, cholesterol_mg = 10, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 80, calcium_mg = 80, iron_mg = 0.3, vitamin_a_ug = 15,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 10, zinc_mg = 0.5,
  phosphorus_mg = 100, selenium_ug = 3.0, omega3_g = 0.02
WHERE food_name_normalized = 'bww_hatch_queso';

UPDATE food_nutrition_overrides SET
  sodium_mg = 900, cholesterol_mg = 5, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 40, calcium_mg = 50, iron_mg = 0.2, vitamin_a_ug = 5,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 5, zinc_mg = 0.2,
  phosphorus_mg = 40, selenium_ug = 1.5, omega3_g = 0.01
WHERE food_name_normalized = 'bww_parmesan_garlic_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 40, saturated_fat_g = 5.0, trans_fat_g = 0.2,
  potassium_mg = 180, calcium_mg = 50, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 18, zinc_mg = 1.5,
  phosphorus_mg = 130, selenium_ug = 12.0, omega3_g = 0.05
WHERE food_name_normalized = 'bww_ultimate_sampler';

-- Chipotle sauces
UPDATE food_nutrition_overrides SET
  sodium_mg = 250, cholesterol_mg = 0, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 15, iron_mg = 0.5, vitamin_a_ug = 5,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 0.5,
  phosphorus_mg = 50, selenium_ug = 1.0, omega3_g = 0.3
WHERE food_name_normalized = 'chipotle_chips_and_guacamole';

UPDATE food_nutrition_overrides SET
  sodium_mg = 550, cholesterol_mg = 10, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 150, calcium_mg = 80, iron_mg = 0.5, vitamin_a_ug = 20,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.5,
  phosphorus_mg = 100, selenium_ug = 3.0, omega3_g = 0.02
WHERE food_name_normalized = 'chipotle_chips_and_queso_blanco';

UPDATE food_nutrition_overrides SET
  sodium_mg = 600, cholesterol_mg = 0, saturated_fat_g = 0.5, trans_fat_g = 0.0,
  potassium_mg = 100, calcium_mg = 10, iron_mg = 0.5, vitamin_a_ug = 20,
  vitamin_c_mg = 10, vitamin_d_iu = 0, magnesium_mg = 8, zinc_mg = 0.2,
  phosphorus_mg = 20, selenium_ug = 0.5, omega3_g = 0.01
WHERE food_name_normalized = 'chipotle_red_chimichurri';

-- Panda Express sauces
UPDATE food_nutrition_overrides SET
  sodium_mg = 420, cholesterol_mg = 35, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 30, iron_mg = 1.5, vitamin_a_ug = 10,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 1.0,
  phosphorus_mg = 120, selenium_ug = 10.0, omega3_g = 0.03
WHERE food_name_normalized = 'panda_express_bigger_plate';

UPDATE food_nutrition_overrides SET
  sodium_mg = 1500, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 50, calcium_mg = 5, iron_mg = 0.3, vitamin_a_ug = 10,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 5, zinc_mg = 0.1,
  phosphorus_mg = 15, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'panda_express_chili_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 5500, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 212, calcium_mg = 20, iron_mg = 1.3, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 40, zinc_mg = 0.4,
  phosphorus_mg = 130, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'panda_express_soy_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 3200, cholesterol_mg = 0, saturated_fat_g = 0.0, trans_fat_g = 0.0,
  potassium_mg = 100, calcium_mg = 15, iron_mg = 0.5, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.2,
  phosphorus_mg = 50, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'panda_express_teriyaki_sauce';

-- Papa John's items
UPDATE food_nutrition_overrides SET
  sodium_mg = 320, cholesterol_mg = 20, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 60, calcium_mg = 25, iron_mg = 1.0, vitamin_a_ug = 10,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 10, zinc_mg = 0.3,
  phosphorus_mg = 50, selenium_ug = 5.0, omega3_g = 0.02
WHERE food_name_normalized = 'papa_johns_cinnamon_pull_aparts';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 15, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 20, calcium_mg = 10, iron_mg = 0.1, vitamin_a_ug = 20,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 2, zinc_mg = 0.1,
  phosphorus_mg = 15, selenium_ug = 0.5, omega3_g = 0.02
WHERE food_name_normalized = 'papa_johns_special_garlic_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 10, saturated_fat_g = 2.0, trans_fat_g = 0.0,
  potassium_mg = 30, calcium_mg = 8, iron_mg = 0.2, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 3, zinc_mg = 0.1,
  phosphorus_mg = 12, selenium_ug = 0.5, omega3_g = 0.01
WHERE food_name_normalized = 'papa_johns_spicy_garlic_sauce';

-- Taco Bell sauces
UPDATE food_nutrition_overrides SET
  sodium_mg = 1800, cholesterol_mg = 0, saturated_fat_g = 0.5, trans_fat_g = 0.0,
  potassium_mg = 120, calcium_mg = 10, iron_mg = 0.5, vitamin_a_ug = 50,
  vitamin_c_mg = 15, vitamin_d_iu = 0, magnesium_mg = 10, zinc_mg = 0.2,
  phosphorus_mg = 20, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'taco_bell_franks_redhot_diablo_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 1500, cholesterol_mg = 5, saturated_fat_g = 1.5, trans_fat_g = 0.0,
  potassium_mg = 50, calcium_mg = 10, iron_mg = 0.3, vitamin_a_ug = 15,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 5, zinc_mg = 0.1,
  phosphorus_mg = 15, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'taco_bell_volcano_sauce';

-- Steak n Shake
UPDATE food_nutrition_overrides SET
  sodium_mg = 700, cholesterol_mg = 15, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 80, calcium_mg = 90, iron_mg = 0.2, vitamin_a_ug = 20,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 10, zinc_mg = 0.5,
  phosphorus_mg = 100, selenium_ug = 3.0, omega3_g = 0.02
WHERE food_name_normalized = 'steak_n_shake_side_cheese_sauce';

-- Hardee's items
UPDATE food_nutrition_overrides SET
  sodium_mg = 550, cholesterol_mg = 55, saturated_fat_g = 6.5, trans_fat_g = 0.3,
  potassium_mg = 200, calcium_mg = 100, iron_mg = 2.0, vitamin_a_ug = 20,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 2.0,
  phosphorus_mg = 180, selenium_ug = 15.0, omega3_g = 0.04
WHERE food_name_normalized = 'hardees_big_hot_ham_n_cheese';

UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 0, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 350, calcium_mg = 10, iron_mg = 0.5, vitamin_a_ug = 0,
  vitamin_c_mg = 10, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 0.3,
  phosphorus_mg = 50, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'hardees_crispy_curls_medium';

UPDATE food_nutrition_overrides SET
  sodium_mg = 600, cholesterol_mg = 50, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 20, iron_mg = 1.5, vitamin_a_ug = 5,
  vitamin_c_mg = 1, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 1.0,
  phosphorus_mg = 160, selenium_ug = 15.0, omega3_g = 0.03
WHERE food_name_normalized = 'hardees_spicy_chicken_tenders_3pc';

-- Red Robin items
UPDATE food_nutrition_overrides SET
  sodium_mg = 550, cholesterol_mg = 70, saturated_fat_g = 8.0, trans_fat_g = 0.5,
  potassium_mg = 250, calcium_mg = 100, iron_mg = 3.0, vitamin_a_ug = 20,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 3.5,
  phosphorus_mg = 200, selenium_ug = 20.0, omega3_g = 0.06
WHERE food_name_normalized = 'red_robin_a1_steakhouse_burger';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 55, saturated_fat_g = 6.5, trans_fat_g = 0.3,
  potassium_mg = 220, calcium_mg = 80, iron_mg = 2.5, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 3.0,
  phosphorus_mg = 180, selenium_ug = 18.0, omega3_g = 0.05
WHERE food_name_normalized = 'red_robin_haystack_double';

UPDATE food_nutrition_overrides SET
  sodium_mg = 520, cholesterol_mg = 65, saturated_fat_g = 7.5, trans_fat_g = 0.4,
  potassium_mg = 240, calcium_mg = 90, iron_mg = 2.8, vitamin_a_ug = 18,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 23, zinc_mg = 3.2,
  phosphorus_mg = 190, selenium_ug = 19.0, omega3_g = 0.05
WHERE food_name_normalized = 'red_robin_madlove_burger';

-- Curly Shawarma items
UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 45, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 40, iron_mg = 2.0, vitamin_a_ug = 15,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 2.0,
  phosphorus_mg = 180, selenium_ug = 15.0, omega3_g = 0.05
WHERE food_name_normalized = 'curly_shawarma_mix_grill';

UPDATE food_nutrition_overrides SET
  sodium_mg = 200, cholesterol_mg = 0, saturated_fat_g = 0.5, trans_fat_g = 0.0,
  potassium_mg = 80, calcium_mg = 15, iron_mg = 0.2, vitamin_a_ug = 0,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 5, zinc_mg = 0.2,
  phosphorus_mg = 20, selenium_ug = 1.0, omega3_g = 0.02
WHERE food_name_normalized = 'curly_shawarma_garlic_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 800, cholesterol_mg = 0, saturated_fat_g = 0.2, trans_fat_g = 0.0,
  potassium_mg = 100, calcium_mg = 10, iron_mg = 0.3, vitamin_a_ug = 30,
  vitamin_c_mg = 10, vitamin_d_iu = 0, magnesium_mg = 8, zinc_mg = 0.1,
  phosphorus_mg = 15, selenium_ug = 0.5, omega3_g = 0.0
WHERE food_name_normalized = 'curly_shawarma_hot_sauce';

UPDATE food_nutrition_overrides SET
  sodium_mg = 300, cholesterol_mg = 0, saturated_fat_g = 2.0, trans_fat_g = 0.0,
  potassium_mg = 120, calcium_mg = 40, iron_mg = 1.0, vitamin_a_ug = 0,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.5,
  phosphorus_mg = 100, selenium_ug = 3.0, omega3_g = 0.02
WHERE food_name_normalized = 'curly_shawarma_tahini';

-- Indian cuisine dishes (per 100g)
UPDATE food_nutrition_overrides SET
  sodium_mg = 350, cholesterol_mg = 0, saturated_fat_g = 1.5, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 30, iron_mg = 1.5, vitamin_a_ug = 50,
  vitamin_c_mg = 8, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 0.8,
  phosphorus_mg = 80, selenium_ug = 3.0, omega3_g = 0.02
WHERE food_name_normalized = 'aloo_matar';

UPDATE food_nutrition_overrides SET
  sodium_mg = 350, cholesterol_mg = 0, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 25, iron_mg = 1.2, vitamin_a_ug = 30,
  vitamin_c_mg = 15, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 0.5,
  phosphorus_mg = 60, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'pav_bhaji';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 0, saturated_fat_g = 1.0, trans_fat_g = 0.0,
  potassium_mg = 150, calcium_mg = 20, iron_mg = 1.0, vitamin_a_ug = 20,
  vitamin_c_mg = 10, vitamin_d_iu = 0, magnesium_mg = 18, zinc_mg = 0.5,
  phosphorus_mg = 50, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'gobi_manchurian';

UPDATE food_nutrition_overrides SET
  sodium_mg = 300, cholesterol_mg = 0, saturated_fat_g = 1.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 15, iron_mg = 0.8, vitamin_a_ug = 10,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.4,
  phosphorus_mg = 40, selenium_ug = 1.5, omega3_g = 0.01
WHERE food_name_normalized = 'gutti_vankaya';

UPDATE food_nutrition_overrides SET
  sodium_mg = 200, cholesterol_mg = 0, saturated_fat_g = 0.5, trans_fat_g = 0.0,
  potassium_mg = 100, calcium_mg = 10, iron_mg = 0.8, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.5,
  phosphorus_mg = 60, selenium_ug = 5.0, omega3_g = 0.01
WHERE food_name_normalized = 'jeera_rice';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 0, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 100, calcium_mg = 20, iron_mg = 2.0, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 10, zinc_mg = 0.3,
  phosphorus_mg = 40, selenium_ug = 5.0, omega3_g = 0.01
WHERE food_name_normalized = 'puri';

UPDATE food_nutrition_overrides SET
  sodium_mg = 1200, cholesterol_mg = 0, saturated_fat_g = 0.5, trans_fat_g = 0.0,
  potassium_mg = 150, calcium_mg = 25, iron_mg = 2.5, vitamin_a_ug = 0,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 0.5,
  phosphorus_mg = 60, selenium_ug = 3.0, omega3_g = 0.01
WHERE food_name_normalized = 'papad';

UPDATE food_nutrition_overrides SET
  sodium_mg = 180, cholesterol_mg = 15, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 120, calcium_mg = 50, iron_mg = 0.5, vitamin_a_ug = 20,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 10, zinc_mg = 0.3,
  phosphorus_mg = 50, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'indian_tres_leches';

UPDATE food_nutrition_overrides SET
  sodium_mg = 150, cholesterol_mg = 10, saturated_fat_g = 2.0, trans_fat_g = 0.0,
  potassium_mg = 100, calcium_mg = 40, iron_mg = 0.3, vitamin_a_ug = 15,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 8, zinc_mg = 0.2,
  phosphorus_mg = 40, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'butterscotch_pastry';

UPDATE food_nutrition_overrides SET
  sodium_mg = 100, cholesterol_mg = 5, saturated_fat_g = 1.0, trans_fat_g = 0.0,
  potassium_mg = 80, calcium_mg = 30, iron_mg = 0.2, vitamin_a_ug = 10,
  vitamin_c_mg = 0, vitamin_d_iu = 0, magnesium_mg = 8, zinc_mg = 0.2,
  phosphorus_mg = 35, selenium_ug = 1.5, omega3_g = 0.01
WHERE food_name_normalized = 'apricot_delight';

UPDATE food_nutrition_overrides SET
  sodium_mg = 50, cholesterol_mg = 5, saturated_fat_g = 1.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 50, iron_mg = 0.2, vitamin_a_ug = 10,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.3,
  phosphorus_mg = 50, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'chikoo_shake';

UPDATE food_nutrition_overrides SET
  sodium_mg = 50, cholesterol_mg = 5, saturated_fat_g = 1.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 50, iron_mg = 0.3, vitamin_a_ug = 30,
  vitamin_c_mg = 10, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.3,
  phosphorus_mg = 50, selenium_ug = 2.0, omega3_g = 0.01
WHERE food_name_normalized = 'sitaphal_shake';

-- Indian chicken dishes (per 100g)
UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 65, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 230, calcium_mg = 20, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 1.8,
  phosphorus_mg = 180, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'chilli_chicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 420, cholesterol_mg = 60, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 220, calcium_mg = 18, iron_mg = 1.3, vitamin_a_ug = 12,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 1.6,
  phosphorus_mg = 170, selenium_ug = 18.0, omega3_g = 0.03
WHERE food_name_normalized = 'chilli_chicken_lollipop';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 65, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 240, calcium_mg = 20, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 1.8,
  phosphorus_mg = 185, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'chicken_manchurian';

UPDATE food_nutrition_overrides SET
  sodium_mg = 420, cholesterol_mg = 60, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 220, calcium_mg = 18, iron_mg = 1.3, vitamin_a_ug = 12,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 1.6,
  phosphorus_mg = 170, selenium_ug = 18.0, omega3_g = 0.03
WHERE food_name_normalized = 'manchurian_chicken_lollipop';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 70, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 15, iron_mg = 1.5, vitamin_a_ug = 20,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 28, zinc_mg = 2.0,
  phosphorus_mg = 190, selenium_ug = 22.0, omega3_g = 0.04
WHERE food_name_normalized = 'chicken_chatkara';

UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 70, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 240, calcium_mg = 18, iron_mg = 1.5, vitamin_a_ug = 30,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 26, zinc_mg = 2.0,
  phosphorus_mg = 185, selenium_ug = 22.0, omega3_g = 0.04
WHERE food_name_normalized = 'karam_podi_chicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 65, saturated_fat_g = 3.0, trans_fat_g = 0.0,
  potassium_mg = 235, calcium_mg = 15, iron_mg = 1.3, vitamin_a_ug = 10,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 24, zinc_mg = 1.8,
  phosphorus_mg = 180, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'kodi_vepudu';

UPDATE food_nutrition_overrides SET
  sodium_mg = 380, cholesterol_mg = 65, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 230, calcium_mg = 15, iron_mg = 1.3, vitamin_a_ug = 10,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 24, zinc_mg = 1.8,
  phosphorus_mg = 180, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'mangalore_chicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 350, cholesterol_mg = 70, saturated_fat_g = 5.0, trans_fat_g = 0.0,
  potassium_mg = 240, calcium_mg = 18, iron_mg = 1.5, vitamin_a_ug = 30,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 26, zinc_mg = 2.0,
  phosphorus_mg = 190, selenium_ug = 22.0, omega3_g = 0.04
WHERE food_name_normalized = 'mangalore_ghee_chicken_roast';

UPDATE food_nutrition_overrides SET
  sodium_mg = 350, cholesterol_mg = 75, saturated_fat_g = 6.0, trans_fat_g = 0.0,
  potassium_mg = 260, calcium_mg = 20, iron_mg = 2.5, vitamin_a_ug = 35,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 3.5,
  phosphorus_mg = 200, selenium_ug = 12.0, omega3_g = 0.03
WHERE food_name_normalized = 'mangalore_ghee_goat_roast';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 65, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 240, calcium_mg = 15, iron_mg = 1.3, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 1.8,
  phosphorus_mg = 185, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'guntur_chicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 65, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 240, calcium_mg = 15, iron_mg = 1.5, vitamin_a_ug = 20,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 1.8,
  phosphorus_mg = 185, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'pachimirchi_chicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 380, cholesterol_mg = 65, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 230, calcium_mg = 15, iron_mg = 1.3, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 24, zinc_mg = 1.8,
  phosphorus_mg = 180, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'monagadu_chicken';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 65, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 235, calcium_mg = 15, iron_mg = 1.3, vitamin_a_ug = 12,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 24, zinc_mg = 1.8,
  phosphorus_mg = 180, selenium_ug = 20.0, omega3_g = 0.04
WHERE food_name_normalized = 'velluikaram_chicken';

-- Indian non-chicken dishes
UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 70, saturated_fat_g = 5.0, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 20, iron_mg = 2.5, vitamin_a_ug = 10,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 3.5,
  phosphorus_mg = 200, selenium_ug = 12.0, omega3_g = 0.03
WHERE food_name_normalized = 'goat_sukka';

UPDATE food_nutrition_overrides SET
  sodium_mg = 500, cholesterol_mg = 60, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 280, calcium_mg = 30, iron_mg = 3.0, vitamin_a_ug = 15,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 3.0,
  phosphorus_mg = 180, selenium_ug = 10.0, omega3_g = 0.03
WHERE food_name_normalized = 'mutton_haleem';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 65, saturated_fat_g = 4.5, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 25, iron_mg = 2.5, vitamin_a_ug = 12,
  vitamin_c_mg = 3, vitamin_d_iu = 0, magnesium_mg = 22, zinc_mg = 3.0,
  phosphorus_mg = 190, selenium_ug = 12.0, omega3_g = 0.03
WHERE food_name_normalized = 'mutton_mandi';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 50, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 250, calcium_mg = 30, iron_mg = 2.5, vitamin_a_ug = 15,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 25, zinc_mg = 3.0,
  phosphorus_mg = 200, selenium_ug = 12.0, omega3_g = 0.04
WHERE food_name_normalized = 'meat_lover_mandi';

UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 60, saturated_fat_g = 4.0, trans_fat_g = 0.0,
  potassium_mg = 280, calcium_mg = 50, iron_mg = 2.5, vitamin_a_ug = 30,
  vitamin_c_mg = 8, vitamin_d_iu = 0, magnesium_mg = 30, zinc_mg = 2.5,
  phosphorus_mg = 200, selenium_ug = 15.0, omega3_g = 0.05
WHERE food_name_normalized = 'non_veg_thali';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 40, saturated_fat_g = 3.5, trans_fat_g = 0.0,
  potassium_mg = 230, calcium_mg = 25, iron_mg = 2.0, vitamin_a_ug = 15,
  vitamin_c_mg = 5, vitamin_d_iu = 0, magnesium_mg = 20, zinc_mg = 1.5,
  phosphorus_mg = 150, selenium_ug = 10.0, omega3_g = 0.03
WHERE food_name_normalized = 'special_combo';

UPDATE food_nutrition_overrides SET
  sodium_mg = 450, cholesterol_mg = 0, saturated_fat_g = 2.0, trans_fat_g = 0.0,
  potassium_mg = 150, calcium_mg = 30, iron_mg = 1.5, vitamin_a_ug = 5,
  vitamin_c_mg = 2, vitamin_d_iu = 0, magnesium_mg = 15, zinc_mg = 0.5,
  phosphorus_mg = 60, selenium_ug = 3.0, omega3_g = 0.01
WHERE food_name_normalized = 'vada';

-- Indian seafood (per 100g)
UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 50, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 280, calcium_mg = 25, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 10, magnesium_mg = 30, zinc_mg = 0.8,
  phosphorus_mg = 200, selenium_ug = 35.0, omega3_g = 0.4
WHERE food_name_normalized = 'fish_65_dry';

UPDATE food_nutrition_overrides SET
  sodium_mg = 380, cholesterol_mg = 50, saturated_fat_g = 2.0, trans_fat_g = 0.0,
  potassium_mg = 270, calcium_mg = 20, iron_mg = 1.2, vitamin_a_ug = 10,
  vitamin_c_mg = 2, vitamin_d_iu = 8, magnesium_mg = 25, zinc_mg = 0.6,
  phosphorus_mg = 180, selenium_ug = 32.0, omega3_g = 0.35
WHERE food_name_normalized = 'nallakaram_fish';

UPDATE food_nutrition_overrides SET
  sodium_mg = 350, cholesterol_mg = 55, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 290, calcium_mg = 30, iron_mg = 1.5, vitamin_a_ug = 15,
  vitamin_c_mg = 3, vitamin_d_iu = 12, magnesium_mg = 30, zinc_mg = 0.7,
  phosphorus_mg = 200, selenium_ug = 38.0, omega3_g = 0.45
WHERE food_name_normalized = 'tawa_fish_fry';

UPDATE food_nutrition_overrides SET
  sodium_mg = 400, cholesterol_mg = 120, saturated_fat_g = 2.5, trans_fat_g = 0.0,
  potassium_mg = 200, calcium_mg = 25, iron_mg = 1.0, vitamin_a_ug = 10,
  vitamin_c_mg = 5, vitamin_d_iu = 5, magnesium_mg = 25, zinc_mg = 1.0,
  phosphorus_mg = 150, selenium_ug = 25.0, omega3_g = 0.15
WHERE food_name_normalized = 'shrimp_pepper_fry';
