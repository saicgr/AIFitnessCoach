-- Migration 333: Validate fast food chain micronutrients against published nutrition data
-- Sources: fastfoodnutrition.org, nutritionix.com, mcdmenus.com, chain official websites
-- All values stored per 100g (converted from chain's published per-serving data)
-- Only corrections where published data differs by >15% from DB values
-- Chains validated: 8
-- Items checked against published data: 149
-- Total corrections: 144

BEGIN;

-- === Burger King ===
UPDATE food_nutrition_overrides SET sodium_mg = 723.1, trans_fat_g = 0.0, cholesterol_mg = 34.6, updated_at = NOW() WHERE food_name_normalized = 'bk_bacon_cheeseburger';
UPDATE food_nutrition_overrides SET sodium_mg = 644.6, trans_fat_g = 0.0, cholesterol_mg = 33.1, updated_at = NOW() WHERE food_name_normalized = 'bk_cheeseburger';
UPDATE food_nutrition_overrides SET sodium_mg = 825.0, saturated_fat_g = 4.17, trans_fat_g = 0.0, cholesterol_mg = 45.8, updated_at = NOW() WHERE food_name_normalized = 'bk_chicken_nuggets_8pc';
UPDATE food_nutrition_overrides SET sodium_mg = 335.1, trans_fat_g = 0.14, cholesterol_mg = 40.5, updated_at = NOW() WHERE food_name_normalized = 'bk_double_whopper';
UPDATE food_nutrition_overrides SET sodium_mg = 230.8, saturated_fat_g = 1.71, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'bk_french_fries_medium';
UPDATE food_nutrition_overrides SET sodium_mg = 291.1, trans_fat_g = 0.0, cholesterol_mg = 12.7, updated_at = NOW() WHERE food_name_normalized = 'bk_hersheys_sundae_pie';
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.7, trans_fat_g = 0.0, cholesterol_mg = 5.6, updated_at = NOW() WHERE food_name_normalized = 'bk_impossible_whopper';
UPDATE food_nutrition_overrides SET sodium_mg = 635.3, saturated_fat_g = 5.88, trans_fat_g = 0.0, cholesterol_mg = 23.5, updated_at = NOW() WHERE food_name_normalized = 'bk_mozzarella_sticks';
UPDATE food_nutrition_overrides SET sodium_mg = 703.3, saturated_fat_g = 2.75, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'bk_onion_rings_medium';
UPDATE food_nutrition_overrides SET sodium_mg = 633.0, saturated_fat_g = 3.21, trans_fat_g = 0.0, cholesterol_mg = 29.8, updated_at = NOW() WHERE food_name_normalized = 'bk_original_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 642.3, saturated_fat_g = 3.25, trans_fat_g = 0.0, cholesterol_mg = 32.5, updated_at = NOW() WHERE food_name_normalized = 'bk_spicy_chking';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.13, cholesterol_mg = 13.9, updated_at = NOW() WHERE food_name_normalized = 'bk_vanilla_shake_medium';
UPDATE food_nutrition_overrides SET sodium_mg = 403.4, saturated_fat_g = 4.14, trans_fat_g = 0.0, cholesterol_mg = 29.3, updated_at = NOW() WHERE food_name_normalized = 'bk_whopper';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.75, cholesterol_mg = 34.8, updated_at = NOW() WHERE food_name_normalized = 'bk_whopper_cheese';
UPDATE food_nutrition_overrides SET sodium_mg = 381.0, saturated_fat_g = 3.4, trans_fat_g = 0.0, cholesterol_mg = 23.8, updated_at = NOW() WHERE food_name_normalized = 'bk_whopper_jr';

-- === Chick-fil-A ===
UPDATE food_nutrition_overrides SET sodium_mg = 803.0, saturated_fat_g = 3.03, trans_fat_g = 0.0, cholesterol_mg = 45.5, updated_at = NOW() WHERE food_name_normalized = 'chickfila_chick_n_minis';
UPDATE food_nutrition_overrides SET sodium_mg = 736.2, trans_fat_g = 0.0, cholesterol_mg = 30.7, updated_at = NOW() WHERE food_name_normalized = 'chickfila_chicken_biscuit';
UPDATE food_nutrition_overrides SET sodium_mg = 415.6, saturated_fat_g = 1.26, updated_at = NOW() WHERE food_name_normalized = 'chickfila_chicken_soup';
UPDATE food_nutrition_overrides SET sodium_mg = 500.0, saturated_fat_g = 2.08, trans_fat_g = 0.0, cholesterol_mg = 45.8, updated_at = NOW() WHERE food_name_normalized = 'chickfila_chicken_strips_3ct';
UPDATE food_nutrition_overrides SET sodium_mg = 78.8, trans_fat_g = 0.0, cholesterol_mg = 13.5, updated_at = NOW() WHERE food_name_normalized = 'chickfila_chocolate_milkshake';
UPDATE food_nutrition_overrides SET sodium_mg = 453.5, saturated_fat_g = 3.02, cholesterol_mg = 53.5, updated_at = NOW() WHERE food_name_normalized = 'chickfila_cobb_salad';
UPDATE food_nutrition_overrides SET sodium_mg = 762.3, trans_fat_g = 0.0, cholesterol_mg = 38.1, updated_at = NOW() WHERE food_name_normalized = 'chickfila_deluxe_sandwich';
UPDATE food_nutrition_overrides SET cholesterol_mg = 33.8, updated_at = NOW() WHERE food_name_normalized = 'chickfila_egg_white_grill';
UPDATE food_nutrition_overrides SET sodium_mg = 15.6, saturated_fat_g = 0.93, cholesterol_mg = 5.2, updated_at = NOW() WHERE food_name_normalized = 'chickfila_frosted_lemonade';
UPDATE food_nutrition_overrides SET saturated_fat_g = 1.2, cholesterol_mg = 36.1, updated_at = NOW() WHERE food_name_normalized = 'chickfila_grilled_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 389.4, saturated_fat_g = 0.44, cholesterol_mg = 75.2, updated_at = NOW() WHERE food_name_normalized = 'chickfila_grilled_nuggets_8ct';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.82, trans_fat_g = 0.0, cholesterol_mg = 14.1, updated_at = NOW() WHERE food_name_normalized = 'chickfila_icedream_cone';
UPDATE food_nutrition_overrides SET sodium_mg = 524.2, saturated_fat_g = 7.05, updated_at = NOW() WHERE food_name_normalized = 'chickfila_mac_and_cheese';
UPDATE food_nutrition_overrides SET sodium_mg = 1070.6, saturated_fat_g = 2.06, trans_fat_g = 0.0, cholesterol_mg = 76.5, updated_at = NOW() WHERE food_name_normalized = 'chickfila_nuggets_12ct';
UPDATE food_nutrition_overrides SET sodium_mg = 1070.8, saturated_fat_g = 2.21, trans_fat_g = 0.0, cholesterol_mg = 75.2, updated_at = NOW() WHERE food_name_normalized = 'chickfila_nuggets_8ct';
UPDATE food_nutrition_overrides SET sodium_mg = 750.0, saturated_fat_g = 1.79, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'chickfila_polynesian_sauce';
UPDATE food_nutrition_overrides SET cholesterol_mg = 35.7, updated_at = NOW() WHERE food_name_normalized = 'chickfila_sauce';
UPDATE food_nutrition_overrides SET sodium_mg = 771.3, saturated_fat_g = 2.69, trans_fat_g = 0.0, cholesterol_mg = 35.9, updated_at = NOW() WHERE food_name_normalized = 'chickfila_spicy_deluxe_sandwich';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.0, updated_at = NOW() WHERE food_name_normalized = 'chickfila_waffle_fries_medium';

-- === KFC ===
UPDATE food_nutrition_overrides SET sodium_mg = 946.4, saturated_fat_g = 7.14, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'kfc_biscuit';
UPDATE food_nutrition_overrides SET sodium_mg = 738.5, saturated_fat_g = 2.31, trans_fat_g = 0.0, cholesterol_mg = 30.8, updated_at = NOW() WHERE food_name_normalized = 'kfc_chicken_nuggets';
UPDATE food_nutrition_overrides SET sodium_mg = 703.4, trans_fat_g = 0.0, cholesterol_mg = 19.1, updated_at = NOW() WHERE food_name_normalized = 'kfc_chicken_pot_pie';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.38, trans_fat_g = 0.0, cholesterol_mg = 26.2, updated_at = NOW() WHERE food_name_normalized = 'kfc_chicken_sandwich';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.0, trans_fat_g = 0.0, cholesterol_mg = 40.0, updated_at = NOW() WHERE food_name_normalized = 'kfc_chicken_tenders';
UPDATE food_nutrition_overrides SET sodium_mg = 208.3, saturated_fat_g = 6.94, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'kfc_chocolate_chip_cookie';
UPDATE food_nutrition_overrides SET sodium_mg = 140.6, saturated_fat_g = 1.56, updated_at = NOW() WHERE food_name_normalized = 'kfc_coleslaw';
UPDATE food_nutrition_overrides SET sodium_mg = 6.1, saturated_fat_g = 0.31, updated_at = NOW() WHERE food_name_normalized = 'kfc_corn_on_cob';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.55, trans_fat_g = 0.0, cholesterol_mg = 45.5, updated_at = NOW() WHERE food_name_normalized = 'kfc_extra_crispy_breast';
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.68, trans_fat_g = 0.0, cholesterol_mg = 51.5, updated_at = NOW() WHERE food_name_normalized = 'kfc_extra_crispy_drumstick';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.24, trans_fat_g = 0.0, cholesterol_mg = 50.8, updated_at = NOW() WHERE food_name_normalized = 'kfc_extra_crispy_thigh';
UPDATE food_nutrition_overrides SET sodium_mg = 588.4, saturated_fat_g = 2.21, trans_fat_g = 0.0, cholesterol_mg = 15.2, updated_at = NOW() WHERE food_name_normalized = 'kfc_famous_bowl';
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.44, cholesterol_mg = 15.3, updated_at = NOW() WHERE food_name_normalized = 'kfc_mac_and_cheese';
UPDATE food_nutrition_overrides SET sodium_mg = 366.0, saturated_fat_g = 0.98, cholesterol_mg = 3.3, updated_at = NOW() WHERE food_name_normalized = 'kfc_mashed_potatoes_gravy';
UPDATE food_nutrition_overrides SET sodium_mg = 606.1, saturated_fat_g = 2.97, updated_at = NOW() WHERE food_name_normalized = 'kfc_original_recipe_breast';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.99, trans_fat_g = 0.0, cholesterol_mg = 89.6, updated_at = NOW() WHERE food_name_normalized = 'kfc_original_recipe_drumstick';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.13, trans_fat_g = 0.0, cholesterol_mg = 82.6, updated_at = NOW() WHERE food_name_normalized = 'kfc_original_recipe_thigh';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'kfc_original_recipe_wing';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.62, trans_fat_g = 0.0, cholesterol_mg = 26.2, updated_at = NOW() WHERE food_name_normalized = 'kfc_spicy_chicken_sandwich';

-- === McDonald's ===
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.9, trans_fat_g = 0.0, cholesterol_mg = 6.5, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_apple_pie';
UPDATE food_nutrition_overrides SET sodium_mg = 742.3, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_bacon_egg_cheese_biscuit';
UPDATE food_nutrition_overrides SET saturated_fat_g = 5.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_big_mac';
UPDATE food_nutrition_overrides SET sodium_mg = 571.4, saturated_fat_g = 5.04, trans_fat_g = 0.42, cholesterol_mg = 33.6, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_cheeseburger';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.78, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_chicken_mcnuggets_10pc';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.58, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_chicken_mcnuggets_6pc';
UPDATE food_nutrition_overrides SET sodium_mg = 74.3, cholesterol_mg = 14.6, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_chocolate_shake_medium';
UPDATE food_nutrition_overrides SET sodium_mg = 636.4, trans_fat_g = 0.61, cholesterol_mg = 51.5, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_double_cheeseburger';
UPDATE food_nutrition_overrides SET cholesterol_mg = 62.5, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_double_quarter_pounder_cheese';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.38, trans_fat_g = 0.0, cholesterol_mg = 178.8, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_egg_mcmuffin';
UPDATE food_nutrition_overrides SET cholesterol_mg = 33.6, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_filet_o_fish';
UPDATE food_nutrition_overrides SET sodium_mg = 196.6, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_french_fries_medium';
UPDATE food_nutrition_overrides SET sodium_mg = 225.4, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_french_fries_small';
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.0, cholesterol_mg = 30.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_hamburger';
UPDATE food_nutrition_overrides SET sodium_mg = 571.4, saturated_fat_g = 2.68, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_hash_brown';
UPDATE food_nutrition_overrides SET sodium_mg = 408.2, saturated_fat_g = 2.38, cholesterol_mg = 30.6, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_hot_n_spicy_mcchicken';
UPDATE food_nutrition_overrides SET sodium_mg = 230.8, saturated_fat_g = 2.31, cholesterol_mg = 15.4, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_hotcakes';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.8, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_mcchicken';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.0, cholesterol_mg = 35.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_mccrispy';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.68, cholesterol_mg = 47.6, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_mcdouble';
UPDATE food_nutrition_overrides SET sodium_mg = 65.6, trans_fat_g = 0.0, cholesterol_mg = 21.3, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_mcflurry_mm';
UPDATE food_nutrition_overrides SET sodium_mg = 98.2, trans_fat_g = 0.18, cholesterol_mg = 15.8, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_mcflurry_oreo';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.74, cholesterol_mg = 49.5, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_quarter_pounder_cheese';
UPDATE food_nutrition_overrides SET sodium_mg = 675.0, trans_fat_g = 0.42, cholesterol_mg = 29.2, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_sausage_biscuit';
UPDATE food_nutrition_overrides SET sodium_mg = 643.2, saturated_fat_g = 6.53, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_sausage_egg_cheese_mcgriddles';
UPDATE food_nutrition_overrides SET sodium_mg = 660.9, trans_fat_g = 0.43, cholesterol_mg = 47.8, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_sausage_mcmuffin';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.31, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_sausage_mcmuffin_egg';
UPDATE food_nutrition_overrides SET sodium_mg = 628.6, saturated_fat_g = 1.9, cholesterol_mg = 31.0, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_spicy_mccrispy';
UPDATE food_nutrition_overrides SET sodium_mg = 56.3, trans_fat_g = 0.0, cholesterol_mg = 14.1, updated_at = NOW() WHERE food_name_normalized = 'mcdonalds_vanilla_cone';

-- === Popeyes ===
UPDATE food_nutrition_overrides SET sodium_mg = 272.7, saturated_fat_g = 3.03, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'popeyes_apple_pie';
UPDATE food_nutrition_overrides SET sodium_mg = 716.7, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'popeyes_biscuit';
UPDATE food_nutrition_overrides SET sodium_mg = 635.3, saturated_fat_g = 3.53, updated_at = NOW() WHERE food_name_normalized = 'popeyes_cajun_fries_regular';
UPDATE food_nutrition_overrides SET cholesterol_mg = 8.8, updated_at = NOW() WHERE food_name_normalized = 'popeyes_cajun_rice';
UPDATE food_nutrition_overrides SET sodium_mg = 782.4, trans_fat_g = 0.59, cholesterol_mg = 64.7, updated_at = NOW() WHERE food_name_normalized = 'popeyes_chicken_breast';
UPDATE food_nutrition_overrides SET sodium_mg = 637.5, trans_fat_g = 0.62, cholesterol_mg = 68.8, updated_at = NOW() WHERE food_name_normalized = 'popeyes_chicken_leg';
UPDATE food_nutrition_overrides SET sodium_mg = 660.6, saturated_fat_g = 3.21, trans_fat_g = 0.46, cholesterol_mg = 34.4, updated_at = NOW() WHERE food_name_normalized = 'popeyes_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 636.4, trans_fat_g = 0.45, cholesterol_mg = 63.6, updated_at = NOW() WHERE food_name_normalized = 'popeyes_chicken_thigh';
UPDATE food_nutrition_overrides SET sodium_mg = 766.7, trans_fat_g = 0.83, cholesterol_mg = 66.7, updated_at = NOW() WHERE food_name_normalized = 'popeyes_chicken_wing';
UPDATE food_nutrition_overrides SET cholesterol_mg = 7.8, updated_at = NOW() WHERE food_name_normalized = 'popeyes_coleslaw';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.04, trans_fat_g = 0.25, cholesterol_mg = 17.7, updated_at = NOW() WHERE food_name_normalized = 'popeyes_mac_and_cheese';
UPDATE food_nutrition_overrides SET sodium_mg = 394.4, cholesterol_mg = 3.5, updated_at = NOW() WHERE food_name_normalized = 'popeyes_mashed_potatoes_gravy';
UPDATE food_nutrition_overrides SET cholesterol_mg = 5.9, updated_at = NOW() WHERE food_name_normalized = 'popeyes_red_beans_rice';
UPDATE food_nutrition_overrides SET sodium_mg = 766.1, saturated_fat_g = 3.21, trans_fat_g = 0.46, cholesterol_mg = 34.4, updated_at = NOW() WHERE food_name_normalized = 'popeyes_spicy_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 852.2, saturated_fat_g = 3.04, trans_fat_g = 0.43, cholesterol_mg = 39.1, updated_at = NOW() WHERE food_name_normalized = 'popeyes_tenders_3pc';
UPDATE food_nutrition_overrides SET sodium_mg = 849.0, trans_fat_g = 0.52, cholesterol_mg = 39.1, updated_at = NOW() WHERE food_name_normalized = 'popeyes_tenders_5pc';

-- === Subway ===
UPDATE food_nutrition_overrides SET saturated_fat_g = 1.09, updated_at = NOW() WHERE food_name_normalized = 'subway_6_turkey_breast';

-- === Taco Bell ===
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.27, cholesterol_mg = 2.5, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_bean_burrito';
UPDATE food_nutrition_overrides SET saturated_fat_g = 3.21, cholesterol_mg = 12.0, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_beefy_5_layer_burrito';
UPDATE food_nutrition_overrides SET sodium_mg = 352.9, saturated_fat_g = 2.61, cholesterol_mg = 3.3, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_black_bean_chalupa_supreme';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.42, cholesterol_mg = 10.1, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_burrito_supreme';
UPDATE food_nutrition_overrides SET sodium_mg = 340.1, saturated_fat_g = 1.76, cholesterol_mg = 18.9, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cantina_chicken_bowl';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cantina_chicken_quesadilla';
UPDATE food_nutrition_overrides SET sodium_mg = 372.5, saturated_fat_g = 3.27, cholesterol_mg = 16.3, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_chalupa_supreme';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.25, cholesterol_mg = 2.5, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cheesy_bean_rice_burrito';
UPDATE food_nutrition_overrides SET cholesterol_mg = 15.4, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cheesy_double_beef_burrito';
UPDATE food_nutrition_overrides SET sodium_mg = 398.2, saturated_fat_g = 1.77, cholesterol_mg = 4.4, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cheesy_fiesta_potatoes';
UPDATE food_nutrition_overrides SET sodium_mg = 346.4, saturated_fat_g = 4.58, cholesterol_mg = 26.1, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cheesy_gordita_crunch';
UPDATE food_nutrition_overrides SET sodium_mg = 701.8, cholesterol_mg = 26.3, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cheesy_roll_up';
UPDATE food_nutrition_overrides SET sodium_mg = 554.3, saturated_fat_g = 5.43, trans_fat_g = 0.0, cholesterol_mg = 40.8, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_chicken_quesadilla';
UPDATE food_nutrition_overrides SET saturated_fat_g = 1.75, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_chips_nacho_cheese';
UPDATE food_nutrition_overrides SET sodium_mg = 281.2, saturated_fat_g = 6.25, trans_fat_g = 0.0, cholesterol_mg = 15.6, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cinnabon_delights';
UPDATE food_nutrition_overrides SET sodium_mg = 571.4, trans_fat_g = 0.0, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_cinnamon_twists';
UPDATE food_nutrition_overrides SET cholesterol_mg = 13.8, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_crunchwrap_supreme';
UPDATE food_nutrition_overrides SET sodium_mg = 318.6, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_crunchy_taco_supreme';
UPDATE food_nutrition_overrides SET sodium_mg = 343.6, saturated_fat_g = 4.29, cholesterol_mg = 24.5, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_doritos_cheesy_gordita_crunch';
UPDATE food_nutrition_overrides SET sodium_mg = 448.7, cholesterol_mg = 32.1, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_doritos_locos_taco';
UPDATE food_nutrition_overrides SET sodium_mg = 423.9, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_doritos_locos_taco_supreme';
UPDATE food_nutrition_overrides SET cholesterol_mg = 17.6, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_grilled_cheese_burrito';
UPDATE food_nutrition_overrides SET sodium_mg = 328.6, saturated_fat_g = 3.29, trans_fat_g = 0.0, cholesterol_mg = 11.7, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_mexican_pizza';
UPDATE food_nutrition_overrides SET saturated_fat_g = 1.56, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_nacho_fries';
UPDATE food_nutrition_overrides SET sodium_mg = 263.0, saturated_fat_g = 1.95, cholesterol_mg = 4.9, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_nachos_bellgrande';
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.73, cholesterol_mg = 7.8, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_pintos_n_cheese';
UPDATE food_nutrition_overrides SET saturated_fat_g = 4.04, cholesterol_mg = 25.3, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_soft_taco';
UPDATE food_nutrition_overrides SET sodium_mg = 400.0, saturated_fat_g = 3.7, cholesterol_mg = 22.2, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_soft_taco_supreme';
UPDATE food_nutrition_overrides SET sodium_mg = 318.6, saturated_fat_g = 1.33, cholesterol_mg = 0.0, updated_at = NOW() WHERE food_name_normalized = 'taco_bell_spicy_potato_soft_taco';

-- === Wendy's ===
UPDATE food_nutrition_overrides SET saturated_fat_g = 2.77, trans_fat_g = 0.13, updated_at = NOW() WHERE food_name_normalized = 'wendys_apple_pecan_salad';
UPDATE food_nutrition_overrides SET trans_fat_g = 0.94, cholesterol_mg = 47.2, updated_at = NOW() WHERE food_name_normalized = 'wendys_baconator';
UPDATE food_nutrition_overrides SET sodium_mg = 14.1, updated_at = NOW() WHERE food_name_normalized = 'wendys_baked_potato';
UPDATE food_nutrition_overrides SET sodium_mg = 17.7, cholesterol_mg = 1.6, updated_at = NOW() WHERE food_name_normalized = 'wendys_baked_potato_sour_cream';
UPDATE food_nutrition_overrides SET sodium_mg = 462.6, saturated_fat_g = 1.98, trans_fat_g = 0.22, updated_at = NOW() WHERE food_name_normalized = 'wendys_chili_medium';
UPDATE food_nutrition_overrides SET sodium_mg = 79.3, saturated_fat_g = 2.64, cholesterol_mg = 15.4, updated_at = NOW() WHERE food_name_normalized = 'wendys_chocolate_frosty_small';
UPDATE food_nutrition_overrides SET saturated_fat_g = 1.54, trans_fat_g = 0.0, cholesterol_mg = 33.0, updated_at = NOW() WHERE food_name_normalized = 'wendys_classic_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 447.6, saturated_fat_g = 2.1, trans_fat_g = 0.0, cholesterol_mg = 28.0, updated_at = NOW() WHERE food_name_normalized = 'wendys_crispy_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 353.6, saturated_fat_g = 6.35, trans_fat_g = 0.83, updated_at = NOW() WHERE food_name_normalized = 'wendys_daves_double';
UPDATE food_nutrition_overrides SET cholesterol_mg = 29.4, updated_at = NOW() WHERE food_name_normalized = 'wendys_daves_single';
UPDATE food_nutrition_overrides SET sodium_mg = 368.7, saturated_fat_g = 7.51, trans_fat_g = 0.99, updated_at = NOW() WHERE food_name_normalized = 'wendys_daves_triple';
UPDATE food_nutrition_overrides SET sodium_mg = 429.5, trans_fat_g = 0.67, cholesterol_mg = 30.2, updated_at = NOW() WHERE food_name_normalized = 'wendys_jr_bacon_cheeseburger';
UPDATE food_nutrition_overrides SET sodium_mg = 612.9, saturated_fat_g = 3.87, trans_fat_g = 0.0, cholesterol_mg = 51.6, updated_at = NOW() WHERE food_name_normalized = 'wendys_nuggets_10pc';
UPDATE food_nutrition_overrides SET saturated_fat_g = 1.54, trans_fat_g = 0.0, cholesterol_mg = 30.8, updated_at = NOW() WHERE food_name_normalized = 'wendys_spicy_chicken_sandwich';
UPDATE food_nutrition_overrides SET sodium_mg = 767.7, saturated_fat_g = 4.52, trans_fat_g = 0.0, updated_at = NOW() WHERE food_name_normalized = 'wendys_spicy_nuggets_10pc';
UPDATE food_nutrition_overrides SET sodium_mg = 79.3, cholesterol_mg = 15.4, updated_at = NOW() WHERE food_name_normalized = 'wendys_vanilla_frosty_small';

COMMIT;