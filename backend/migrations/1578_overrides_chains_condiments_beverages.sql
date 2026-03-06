-- 1578_overrides_chains_condiments_beverages.sql
-- Restaurant chains (Five Guys, Shake Shack, In-N-Out, Wingstop, Raising Cane's, KFC,
-- Panera Bread, Waffle House, Panda Express), condiments, beverages, deli meats,
-- cookies & crackers, protein powders, instant ramen, frozen meals.
-- Sources: USDA FoodData Central, manufacturer nutrition pages, fastfoodnutrition.org,
-- calorieking.com, fatsecret.com, nutritionix.com, eatthismuch.com.
-- All values per 100g unless noted.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ==========================================
-- A. FIVE GUYS (~10 items)
-- ==========================================

-- Five Guys Little Hamburger: 540 cal per 302g patty+bun. Per 100g: 179 cal.
('five_guys_little_hamburger', 'Five Guys Little Hamburger', 179, 12.6, 13.0, 8.6,
 0.7, 2.0, 302, 302,
 'five_guys', ARRAY['five guys little hamburger', 'five guys small burger', 'little hamburger five guys'],
 'fast_food', 'Five Guys', 1, '179 cal/100g. Per burger (302g): 540 cal, 26g fat, 39g carb, 38g protein.', TRUE),

-- Five Guys Cheeseburger (regular, 2 patties): 980 cal per 425g. Per 100g: 231 cal.
('five_guys_cheeseburger', 'Five Guys Cheeseburger', 231, 13.2, 9.4, 16.5,
 0.5, 2.0, 425, 425,
 'five_guys', ARRAY['five guys cheeseburger', 'five guys cheese burger', 'five guys regular cheeseburger'],
 'fast_food', 'Five Guys', 1, '231 cal/100g. Per burger (425g): 980 cal, 55g fat, 40g carb, 56g protein.', TRUE),

-- Five Guys Bacon Cheeseburger: 920 cal per 380g. Per 100g: 242 cal.
('five_guys_bacon_cheeseburger', 'Five Guys Bacon Cheeseburger', 242, 14.2, 10.5, 16.3,
 0.5, 2.0, 380, 380,
 'five_guys', ARRAY['five guys bacon cheeseburger', 'five guys bacon cheese burger'],
 'fast_food', 'Five Guys', 1, '242 cal/100g. Per burger (380g): 920 cal, 62g fat, 40g carb, 54g protein.', TRUE),

-- Five Guys Little Cheeseburger: 610 cal per 275g. Per 100g: 222 cal.
('five_guys_little_cheeseburger', 'Five Guys Little Cheeseburger', 222, 14.2, 14.5, 11.6,
 0.5, 2.0, 275, 275,
 'five_guys', ARRAY['five guys little cheeseburger', 'five guys small cheeseburger'],
 'fast_food', 'Five Guys', 1, '222 cal/100g. Per burger (275g): 610 cal, 32g fat, 40g carb, 39g protein.', TRUE),

-- Five Guys Cajun Fries Regular: 780 cal per 411g. Per 100g: 190 cal.
('five_guys_cajun_fries', 'Five Guys Cajun Fries (Regular)', 190, 3.4, 23.4, 9.5,
 2.2, 0.5, 411, 411,
 'five_guys', ARRAY['five guys cajun fries', 'cajun fries five guys', 'five guys fries cajun'],
 'fast_food', 'Five Guys', 1, '190 cal/100g. Per regular order (411g): 780 cal. Hand-cut, fried in peanut oil.', TRUE),

-- Five Guys Regular Fries: 953 cal per 567g. Per 100g: 168 cal.
('five_guys_regular_fries', 'Five Guys Regular Fries', 168, 3.0, 21.0, 8.0,
 2.0, 0.3, 567, 567,
 'five_guys', ARRAY['five guys fries', 'five guys regular fries', 'five guys french fries'],
 'fast_food', 'Five Guys', 1, '168 cal/100g. Per regular order (567g): 953 cal. Hand-cut, fried in peanut oil.', TRUE),

-- Five Guys Hot Dog: 545 cal per 175g. Per 100g: 311 cal.
('five_guys_hot_dog', 'Five Guys Hot Dog', 311, 10.3, 13.7, 20.0,
 0.5, 2.5, 175, 175,
 'five_guys', ARRAY['five guys hot dog', 'five guys kosher hot dog', 'hot dog five guys'],
 'fast_food', 'Five Guys', 1, '311 cal/100g. Per hot dog (175g): 545 cal, 35g fat, 24g carb, 18g protein.', TRUE),

-- Five Guys Grilled Cheese: 470 cal per 180g. Per 100g: 261 cal.
('five_guys_grilled_cheese', 'Five Guys Grilled Cheese', 261, 10.0, 18.3, 14.4,
 0.5, 2.0, 180, 180,
 'five_guys', ARRAY['five guys grilled cheese', 'grilled cheese five guys'],
 'fast_food', 'Five Guys', 1, '261 cal/100g. Per sandwich (180g): 470 cal, 26g fat, 33g carb, 18g protein.', TRUE),

-- Five Guys BLT: 450 cal per 195g. Per 100g: 231 cal.
('five_guys_blt', 'Five Guys BLT', 231, 9.2, 14.4, 12.8,
 0.8, 2.0, 195, 195,
 'five_guys', ARRAY['five guys blt', 'five guys bacon lettuce tomato', 'blt five guys'],
 'fast_food', 'Five Guys', 1, '231 cal/100g. Per sandwich (195g): 450 cal, 25g fat, 28g carb, 18g protein.', TRUE),

-- Five Guys Vanilla Milkshake: 670 cal per 473ml (~500g). Per 100g: 134 cal.
('five_guys_milkshake_vanilla', 'Five Guys Vanilla Milkshake', 134, 3.8, 13.8, 7.8,
 0.0, 12.0, 500, 500,
 'five_guys', ARRAY['five guys vanilla milkshake', 'five guys milkshake', 'five guys shake vanilla'],
 'fast_food', 'Five Guys', 1, '134 cal/100g. Per shake (~500g): 670 cal, 39g fat, 69g carb. Mix-in milkshake.', TRUE),

-- ==========================================
-- B. SHAKE SHACK (~8 items)
-- ==========================================

-- Shake Shack ShackBurger Single: 530 cal per 194g. Per 100g: 273 cal.
('shake_shack_shackburger_single', 'Shake Shack ShackBurger (Single)', 273, 14.4, 12.9, 18.6,
 0.5, 3.0, 194, 194,
 'shake_shack', ARRAY['shackburger', 'shake shack shackburger', 'shake shack burger', 'shack burger single'],
 'fast_food', 'Shake Shack', 1, '273 cal/100g. Per burger (194g): 530 cal. Angus beef, lettuce, tomato, ShackSauce.', TRUE),

-- Shake Shack ShackBurger Double: 760 cal per 280g. Per 100g: 271 cal.
('shake_shack_shackburger_double', 'Shake Shack ShackBurger (Double)', 271, 16.1, 9.6, 18.9,
 0.4, 2.5, 280, 280,
 'shake_shack', ARRAY['double shackburger', 'shake shack double shackburger', 'shackburger double'],
 'fast_food', 'Shake Shack', 1, '271 cal/100g. Per burger (280g): 760 cal. Double Angus beef patties.', TRUE),

-- Shake Shack SmokeShack Single: 570 cal per 210g. Per 100g: 271 cal.
('shake_shack_smokeshack', 'Shake Shack SmokeShack (Single)', 271, 14.3, 11.4, 18.6,
 0.5, 3.0, 210, 210,
 'shake_shack', ARRAY['smokeshack', 'shake shack smokeshack', 'smoke shack burger'],
 'fast_food', 'Shake Shack', 1, '271 cal/100g. Per burger (210g): 570 cal. Angus beef, cherry peppers, bacon, ShackSauce.', TRUE),

-- Shake Shack Chicken Shack: 580 cal per 218g. Per 100g: 266 cal.
('shake_shack_chicken_shack', 'Shake Shack Chicken Shack', 266, 13.3, 16.5, 15.6,
 0.5, 3.0, 218, 218,
 'shake_shack', ARRAY['chicken shack', 'shake shack chicken sandwich', 'shake shack chicken shack'],
 'fast_food', 'Shake Shack', 1, '266 cal/100g. Per sandwich (218g): 580 cal. Crispy chicken breast, pickles, buttermilk herb mayo.', TRUE),

-- Shake Shack Crinkle Cut Fries: 470 cal per 170g. Per 100g: 276 cal.
('shake_shack_fries', 'Shake Shack Crinkle Cut Fries', 276, 3.5, 37.1, 12.9,
 2.9, 0.3, 170, 170,
 'shake_shack', ARRAY['shake shack fries', 'shake shack crinkle cut fries', 'crinkle fries shake shack'],
 'fast_food', 'Shake Shack', 1, '276 cal/100g. Per order (170g): 470 cal, 22g fat, 63g carb. Crinkle-cut, golden fried.', TRUE),

-- Shake Shack Vanilla Shake: 680 cal per 470g. Per 100g: 145 cal.
('shake_shack_vanilla_shake', 'Shake Shack Vanilla Shake', 145, 3.4, 17.0, 7.2,
 0.0, 15.0, 470, 470,
 'shake_shack', ARRAY['shake shack vanilla shake', 'shake shack milkshake vanilla', 'vanilla shake shake shack'],
 'fast_food', 'Shake Shack', 1, '145 cal/100g. Per shake (~470g): 680 cal. Made with frozen custard.', TRUE),

-- Shake Shack Chocolate Shake: 700 cal per 470g. Per 100g: 149 cal.
('shake_shack_chocolate_shake', 'Shake Shack Chocolate Shake', 149, 3.4, 18.1, 7.4,
 0.5, 16.0, 470, 470,
 'shake_shack', ARRAY['shake shack chocolate shake', 'shake shack milkshake chocolate', 'chocolate shake shake shack'],
 'fast_food', 'Shake Shack', 1, '149 cal/100g. Per shake (~470g): 700 cal. Made with frozen custard and chocolate.', TRUE),

-- ==========================================
-- C. IN-N-OUT (~8 items)
-- ==========================================

-- In-N-Out Double-Double: 670 cal per 330g. Per 100g: 203 cal.
('in_n_out_double_double', 'In-N-Out Double-Double', 203, 11.2, 12.7, 10.3,
 0.9, 3.0, 330, 330,
 'in_n_out', ARRAY['double double', 'in n out double double', 'in-n-out double-double', 'double double burger'],
 'fast_food', 'In-N-Out', 1, '203 cal/100g. Per burger (330g): 670 cal, 34g fat, 42g carb, 37g protein.', TRUE),

-- In-N-Out Cheeseburger: 480 cal per 268g. Per 100g: 179 cal.
('in_n_out_cheeseburger', 'In-N-Out Cheeseburger', 179, 10.4, 14.9, 7.5,
 0.7, 3.0, 268, 268,
 'in_n_out', ARRAY['in n out cheeseburger', 'in-n-out cheeseburger', 'in n out cheese burger'],
 'fast_food', 'In-N-Out', 1, '179 cal/100g. Per burger (268g): 480 cal, 27g fat, 40g carb, 22g protein.', TRUE),

-- In-N-Out Hamburger: 390 cal per 243g. Per 100g: 160 cal.
('in_n_out_hamburger', 'In-N-Out Hamburger', 160, 9.1, 15.2, 6.6,
 0.8, 3.0, 243, 243,
 'in_n_out', ARRAY['in n out hamburger', 'in-n-out hamburger', 'in n out burger'],
 'fast_food', 'In-N-Out', 1, '160 cal/100g. Per burger (243g): 390 cal, 19g fat, 39g carb, 16g protein.', TRUE),

-- In-N-Out Protein Style (Double-Double lettuce wrap): 520 cal per 300g. Per 100g: 173 cal.
('in_n_out_protein_style', 'In-N-Out Double-Double Protein Style', 173, 11.7, 3.7, 12.3,
 1.0, 2.5, 300, 300,
 'in_n_out', ARRAY['in n out protein style', 'in-n-out protein style', 'double double protein style', 'lettuce wrap burger in n out'],
 'fast_food', 'In-N-Out', 1, '173 cal/100g. Per burger (300g): 520 cal. Lettuce-wrapped, no bun.', TRUE),

-- In-N-Out Animal Style Fries: 750 cal per 280g. Per 100g: 268 cal.
('in_n_out_animal_style_fries', 'In-N-Out Animal Style Fries', 268, 5.0, 25.0, 16.1,
 1.8, 2.0, 280, 280,
 'in_n_out', ARRAY['animal style fries', 'in n out animal fries', 'in-n-out animal style fries', 'animal fries'],
 'fast_food', 'In-N-Out', 1, '268 cal/100g. Per order (280g): 750 cal. Fries with cheese, grilled onions, spread.', TRUE),

-- In-N-Out French Fries: 360 cal per 125g. Per 100g: 288 cal.
('in_n_out_french_fries', 'In-N-Out French Fries', 288, 4.8, 39.2, 12.0,
 3.2, 0.3, 125, 125,
 'in_n_out', ARRAY['in n out fries', 'in-n-out fries', 'in n out french fries'],
 'fast_food', 'In-N-Out', 1, '288 cal/100g. Per order (125g): 360 cal, 15g fat, 49g carb, 6g protein.', TRUE),

-- In-N-Out Vanilla Shake: 590 cal per 425g (15oz). Per 100g: 139 cal.
('in_n_out_vanilla_shake', 'In-N-Out Vanilla Shake', 139, 3.8, 15.5, 7.3,
 0.0, 14.0, 425, 425,
 'in_n_out', ARRAY['in n out vanilla shake', 'in-n-out vanilla milkshake', 'in n out milkshake vanilla'],
 'fast_food', 'In-N-Out', 1, '139 cal/100g. Per shake (425g/15oz): 590 cal, 31g fat, 66g carb, 16g protein.', TRUE),

-- In-N-Out Chocolate Shake: 610 cal per 425g (15oz). Per 100g: 144 cal.
('in_n_out_chocolate_shake', 'In-N-Out Chocolate Shake', 144, 3.8, 17.4, 7.1,
 0.2, 15.0, 425, 425,
 'in_n_out', ARRAY['in n out chocolate shake', 'in-n-out chocolate milkshake', 'in n out milkshake chocolate'],
 'fast_food', 'In-N-Out', 1, '144 cal/100g. Per shake (425g/15oz): 610 cal, 30g fat, 74g carb, 16g protein.', TRUE),

-- ==========================================
-- D. WINGSTOP (~10 items)
-- ==========================================

-- Wingstop Classic Wings Lemon Pepper: per wing ~35g, 120 cal. Per 100g: 343 cal.
('wingstop_lemon_pepper_wings', 'Wingstop Classic Wings Lemon Pepper', 343, 26.0, 1.7, 25.7,
 0.0, 0.0, 70, 35,
 'wingstop', ARRAY['wingstop lemon pepper', 'lemon pepper wings wingstop', 'wingstop classic lemon pepper wings'],
 'fast_food', 'Wingstop', 2, '343 cal/100g. Per wing (~35g): 120 cal. Default 2 wings (70g). Classic bone-in.', TRUE),

-- Wingstop Classic Wings Garlic Parmesan: per wing ~36g, 120 cal. Per 100g: 333 cal.
('wingstop_garlic_parmesan_wings', 'Wingstop Classic Wings Garlic Parmesan', 333, 24.0, 3.3, 25.0,
 0.0, 0.5, 72, 36,
 'wingstop', ARRAY['wingstop garlic parmesan', 'garlic parm wings wingstop', 'wingstop garlic parmesan wings'],
 'fast_food', 'Wingstop', 2, '333 cal/100g. Per wing (~36g): 120 cal. Default 2 wings (72g). Garlic parmesan dry rub.', TRUE),

-- Wingstop Classic Wings Buffalo (Original Hot): per wing ~39g, 100 cal. Per 100g: 256 cal.
('wingstop_buffalo_wings', 'Wingstop Classic Wings Original Hot', 256, 21.5, 2.6, 17.4,
 0.3, 0.5, 78, 39,
 'wingstop', ARRAY['wingstop buffalo wings', 'wingstop original hot', 'wingstop hot wings', 'wingstop buffalo'],
 'fast_food', 'Wingstop', 2, '256 cal/100g. Per wing (~39g): 100 cal. Default 2 wings (78g). Classic buffalo sauce.', TRUE),

-- Wingstop Classic Wings Atomic: per wing ~39g, 90 cal. Per 100g: 231 cal.
('wingstop_atomic_wings', 'Wingstop Classic Wings Atomic', 231, 20.5, 2.6, 15.4,
 0.3, 0.5, 78, 39,
 'wingstop', ARRAY['wingstop atomic wings', 'wingstop atomic', 'atomic wings wingstop'],
 'fast_food', 'Wingstop', 2, '231 cal/100g. Per wing (~39g): 90 cal. Default 2 wings (78g). Hottest flavor.', TRUE),

-- Wingstop Classic Wings Mango Habanero: per wing ~39g, 100 cal. Per 100g: 256 cal.
('wingstop_mango_habanero_wings', 'Wingstop Classic Wings Mango Habanero', 256, 20.5, 5.6, 16.7,
 0.2, 4.0, 78, 39,
 'wingstop', ARRAY['wingstop mango habanero', 'mango habanero wings wingstop', 'wingstop mango habanero wings'],
 'fast_food', 'Wingstop', 2, '256 cal/100g. Per wing (~39g): 100 cal. Default 2 wings (78g). Sweet-spicy sauce.', TRUE),

-- Wingstop Classic Wings Hickory Smoked BBQ: per wing ~39g, 105 cal. Per 100g: 269 cal.
('wingstop_bbq_wings', 'Wingstop Classic Wings Hickory Smoked BBQ', 269, 20.5, 6.4, 17.4,
 0.2, 5.0, 78, 39,
 'wingstop', ARRAY['wingstop bbq wings', 'wingstop hickory smoked bbq', 'wingstop barbecue wings'],
 'fast_food', 'Wingstop', 2, '269 cal/100g. Per wing (~39g): 105 cal. Default 2 wings (78g). Hickory BBQ sauce.', TRUE),

-- Wingstop Boneless Wings (plain): per 2 pieces ~70g, 172 cal. Per 100g: 246 cal.
('wingstop_boneless_wings', 'Wingstop Boneless Wings', 246, 16.0, 16.6, 12.6,
 0.5, 1.0, 140, 35,
 'wingstop', ARRAY['wingstop boneless', 'wingstop boneless wings', 'boneless wings wingstop'],
 'fast_food', 'Wingstop', 4, '246 cal/100g. Per 2pc (~70g): 172 cal. Default 4pc (140g). Breaded chicken breast.', TRUE),

-- Wingstop Chicken Tenders (plain crispy): per 2pc ~80g, 224 cal. Per 100g: 280 cal.
('wingstop_chicken_tenders', 'Wingstop Crispy Tenders', 280, 18.0, 17.5, 14.0,
 0.5, 0.5, 120, 40,
 'wingstop', ARRAY['wingstop tenders', 'wingstop chicken tenders', 'wingstop crispy tenders'],
 'fast_food', 'Wingstop', 3, '280 cal/100g. Per 2pc (~80g): 224 cal. Default 3pc (120g). Crispy breaded strips.', TRUE),

-- Wingstop Seasoned Fries Regular: 390 cal per 170g (6oz). Per 100g: 229 cal.
('wingstop_seasoned_fries', 'Wingstop Seasoned Fries (Regular)', 229, 3.5, 30.6, 10.6,
 2.4, 0.3, 170, 170,
 'wingstop', ARRAY['wingstop fries', 'wingstop seasoned fries', 'seasoned fries wingstop'],
 'fast_food', 'Wingstop', 1, '229 cal/100g. Per regular order (170g/6oz): 390 cal. Signature seasoned fries.', TRUE),

-- Wingstop Ranch: per 28g cup, 140 cal. Per 100g: 500 cal.
('wingstop_ranch', 'Wingstop Ranch Dip', 500, 1.1, 3.6, 53.6,
 0.0, 1.8, 28, 28,
 'wingstop', ARRAY['wingstop ranch', 'wingstop ranch dip', 'ranch dip wingstop'],
 'fast_food', 'Wingstop', 1, '500 cal/100g. Per dip cup (28g): 140 cal. Creamy ranch dipping sauce.', TRUE),

-- ==========================================
-- E. RAISING CANE'S (~6 items)
-- ==========================================

-- Raising Cane's Chicken Fingers (3pc): 420 cal per 213g. Per 100g: 197 cal.
('raising_canes_chicken_fingers', 'Raising Cane''s Chicken Fingers (3pc)', 197, 18.3, 8.5, 9.9,
 0.3, 0.2, 213, 71,
 'raising_canes', ARRAY['raising canes chicken fingers', 'canes chicken fingers', 'raising cane''s tenders', 'canes fingers'],
 'fast_food', 'Raising Cane''s', 3, '197 cal/100g. Per 3pc (213g): 420 cal, 21g fat, 18g carb, 39g protein. Marinated chicken tenders.', TRUE),

-- Raising Cane's The Box Combo (fingers+fries+sauce+toast+drink): ~1250 cal total combo. Chicken+sides only ~970 cal per ~500g. Per 100g: 194 cal.
('raising_canes_box_combo', 'Raising Cane''s The Box Combo', 194, 12.0, 18.6, 7.4,
 1.0, 2.0, 500, 500,
 'raising_canes', ARRAY['raising canes box combo', 'canes box combo', 'the box combo canes', 'canes combo'],
 'fast_food', 'Raising Cane''s', 1, '194 cal/100g. Per combo (~500g, no drink): 970 cal. 4 fingers, fries, sauce, toast, coleslaw.', TRUE),

-- Raising Cane's Cane's Sauce: per 28g cup, 190 cal. Per 100g: 679 cal.
('raising_canes_sauce', 'Raising Cane''s Cane''s Sauce', 679, 0.4, 10.7, 71.4,
 0.0, 7.1, 28, 28,
 'raising_canes', ARRAY['canes sauce', 'raising canes sauce', 'cane''s sauce', 'raising cane''s dipping sauce'],
 'fast_food', 'Raising Cane''s', 1, '679 cal/100g. Per sauce cup (28g): 190 cal. Signature mayo-based dipping sauce.', TRUE),

-- Raising Cane's Texas Toast: 150 cal per 47g slice. Per 100g: 319 cal.
('raising_canes_texas_toast', 'Raising Cane''s Texas Toast', 319, 6.4, 34.0, 17.0,
 0.6, 3.0, 47, 47,
 'raising_canes', ARRAY['canes texas toast', 'raising canes toast', 'texas toast canes'],
 'fast_food', 'Raising Cane''s', 1, '319 cal/100g. Per slice (47g): 150 cal. Buttered and toasted thick white bread.', TRUE),

-- Raising Cane's Crinkle Cut Fries: 310 cal per 113g. Per 100g: 274 cal.
('raising_canes_fries', 'Raising Cane''s Crinkle Cut Fries', 274, 3.5, 37.2, 12.4,
 2.7, 0.3, 113, 113,
 'raising_canes', ARRAY['canes fries', 'raising canes fries', 'raising cane''s crinkle cut fries'],
 'fast_food', 'Raising Cane''s', 1, '274 cal/100g. Per regular order (113g): 310 cal. Crinkle-cut, golden fried.', TRUE),

-- Raising Cane's Coleslaw: 200 cal per 142g. Per 100g: 141 cal.
('raising_canes_coleslaw', 'Raising Cane''s Coleslaw', 141, 0.7, 10.6, 10.6,
 1.4, 8.5, 142, 142,
 'raising_canes', ARRAY['canes coleslaw', 'raising canes coleslaw', 'raising cane''s cole slaw'],
 'fast_food', 'Raising Cane''s', 1, '141 cal/100g. Per cup (142g): 200 cal. Creamy southern-style coleslaw.', TRUE),

-- ==========================================
-- F. KFC (~15 items)
-- ==========================================

-- KFC Original Recipe Breast: 320 cal per 153g piece. Per 100g: 209 cal.
('kfc_original_breast', 'KFC Original Recipe Chicken Breast', 209, 19.6, 4.6, 12.4,
 0.2, 0.0, 153, 153,
 'kfc', ARRAY['kfc breast', 'kfc original recipe breast', 'kfc chicken breast original'],
 'fast_food', 'KFC', 1, '209 cal/100g. Per breast (153g): 320 cal, 14g fat, 7g carb, 30g protein. 11 herbs & spices.', TRUE),

-- KFC Original Recipe Thigh: 280 cal per 114g piece. Per 100g: 246 cal.
('kfc_original_thigh', 'KFC Original Recipe Chicken Thigh', 246, 15.8, 5.3, 17.5,
 0.2, 0.0, 114, 114,
 'kfc', ARRAY['kfc thigh', 'kfc original recipe thigh', 'kfc chicken thigh original'],
 'fast_food', 'KFC', 1, '246 cal/100g. Per thigh (114g): 280 cal, 20g fat, 6g carb, 18g protein.', TRUE),

-- KFC Original Recipe Drumstick: 130 cal per 55g piece. Per 100g: 236 cal.
('kfc_original_drumstick', 'KFC Original Recipe Chicken Drumstick', 236, 20.0, 5.5, 14.5,
 0.2, 0.0, 55, 55,
 'kfc', ARRAY['kfc drumstick', 'kfc original drumstick', 'kfc chicken drumstick original', 'kfc leg'],
 'fast_food', 'KFC', 1, '236 cal/100g. Per drumstick (55g): 130 cal, 8g fat, 3g carb, 11g protein.', TRUE),

-- KFC Original Recipe Wing: 130 cal per 48g piece. Per 100g: 271 cal.
('kfc_original_wing', 'KFC Original Recipe Chicken Wing', 271, 18.8, 6.3, 18.8,
 0.2, 0.0, 48, 48,
 'kfc', ARRAY['kfc wing', 'kfc original wing', 'kfc chicken wing original'],
 'fast_food', 'KFC', 1, '271 cal/100g. Per wing (48g): 130 cal, 9g fat, 3g carb, 9g protein.', TRUE),

-- KFC Extra Crispy Breast: 530 cal per 176g piece. Per 100g: 301 cal.
('kfc_extra_crispy_breast', 'KFC Extra Crispy Chicken Breast', 301, 15.3, 9.7, 22.2,
 0.5, 0.0, 176, 176,
 'kfc', ARRAY['kfc extra crispy breast', 'kfc extra crispy chicken breast', 'kfc crispy breast'],
 'fast_food', 'KFC', 1, '301 cal/100g. Per breast (176g): 530 cal, 35g fat, 17g carb, 27g protein. Double breaded.', TRUE),

-- KFC Popcorn Chicken (large): 620 cal per 226g. Per 100g: 274 cal.
('kfc_popcorn_chicken', 'KFC Popcorn Chicken', 274, 15.0, 16.8, 16.4,
 0.5, 0.5, 226, 6.4,
 'kfc', ARRAY['kfc popcorn chicken', 'kfc popcorn nuggets', 'popcorn chicken kfc'],
 'fast_food', 'KFC', 1, '274 cal/100g. Per large (226g): 620 cal, 27g fat, 39g protein. Bite-sized crispy chicken.', TRUE),

-- KFC Famous Bowl: 710 cal per 525g. Per 100g: 135 cal.
('kfc_famous_bowl', 'KFC Famous Bowl', 135, 4.6, 14.3, 6.5,
 0.8, 0.5, 525, 525,
 'kfc', ARRAY['kfc famous bowl', 'famous bowl kfc', 'kfc mashed potato bowl', 'kfc bowl'],
 'fast_food', 'KFC', 1, '135 cal/100g. Per bowl (525g): 710 cal, 34g fat, 75g carb, 24g protein. Mashed potato, corn, chicken, gravy, cheese.', TRUE),

-- KFC Chicken Pot Pie: 720 cal per 360g. Per 100g: 200 cal.
('kfc_pot_pie', 'KFC Chicken Pot Pie', 200, 4.7, 15.6, 11.4,
 1.1, 2.0, 360, 360,
 'kfc', ARRAY['kfc pot pie', 'kfc chicken pot pie', 'chicken pot pie kfc'],
 'fast_food', 'KFC', 1, '200 cal/100g. Per pie (360g): 720 cal, 41g fat, 56g carb, 17g protein. Flaky crust with chicken and vegetables.', TRUE),

-- KFC Chicken Sandwich: 650 cal per 223g. Per 100g: 291 cal.
('kfc_chicken_sandwich', 'KFC Chicken Sandwich', 291, 11.2, 19.3, 18.4,
 0.9, 3.0, 223, 223,
 'kfc', ARRAY['kfc chicken sandwich', 'kfc sandwich', 'kfc crispy chicken sandwich'],
 'fast_food', 'KFC', 1, '291 cal/100g. Per sandwich (223g): 650 cal, 41g fat, 43g carb, 25g protein.', TRUE),

-- KFC Mac & Cheese (individual): 170 cal per 131g. Per 100g: 130 cal.
('kfc_mac_and_cheese', 'KFC Mac & Cheese', 130, 5.3, 13.0, 6.1,
 0.5, 2.0, 131, 131,
 'kfc', ARRAY['kfc mac and cheese', 'kfc mac cheese', 'kfc macaroni and cheese'],
 'fast_food', 'KFC', 1, '130 cal/100g. Per individual (131g): 170 cal, 8g fat, 17g carb, 7g protein.', TRUE),

-- KFC Mashed Potatoes & Gravy: 120 cal per 153g. Per 100g: 78 cal.
('kfc_mashed_potatoes', 'KFC Mashed Potatoes & Gravy', 78, 1.3, 11.1, 3.3,
 0.7, 0.5, 153, 153,
 'kfc', ARRAY['kfc mashed potatoes', 'kfc mashed potatoes and gravy', 'kfc mashed potato gravy'],
 'fast_food', 'KFC', 1, '78 cal/100g. Per individual (153g): 120 cal, 5g fat, 17g carb, 2g protein.', TRUE),

-- KFC Coleslaw: 170 cal per 128g. Per 100g: 133 cal.
('kfc_coleslaw', 'KFC Coleslaw', 133, 0.8, 10.2, 10.2,
 1.2, 8.6, 128, 128,
 'kfc', ARRAY['kfc coleslaw', 'kfc cole slaw', 'coleslaw kfc'],
 'fast_food', 'KFC', 1, '133 cal/100g. Per individual (128g): 170 cal, 9g fat, 22g carb, 1g protein.', TRUE),

-- KFC Biscuit: 180 cal per 56g. Per 100g: 321 cal.
('kfc_biscuit', 'KFC Biscuit', 321, 5.4, 35.7, 16.1,
 0.9, 3.6, 56, 56,
 'kfc', ARRAY['kfc biscuit', 'biscuit kfc', 'kfc buttermilk biscuit'],
 'fast_food', 'KFC', 1, '321 cal/100g. Per biscuit (56g): 180 cal, 9g fat, 20g carb, 3g protein. Flaky buttermilk.', TRUE),

-- KFC Corn on the Cob: 70 cal per 78g. Per 100g: 90 cal.
('kfc_corn_on_cob', 'KFC Corn on the Cob', 90, 2.6, 12.8, 3.2,
 1.9, 3.5, 78, 78,
 'kfc', ARRAY['kfc corn', 'kfc corn on the cob', 'corn on cob kfc'],
 'fast_food', 'KFC', 1, '90 cal/100g. Per ear (78g): 70 cal, 2.5g fat, 10g carb, 2g protein. Buttered.', TRUE)

,

-- ==========================================
-- G. PANERA BREAD (~15 items)
-- ==========================================

-- Panera Broccoli Cheddar Soup (bread bowl): 910 cal per 530g. Per 100g: 172 cal.
('panera_broccoli_cheddar_soup', 'Panera Bread Broccoli Cheddar Soup (Bread Bowl)', 172, 5.7, 18.5, 8.3,
 1.3, 2.8, 530, 530,
 'panera_bread', ARRAY['panera broccoli cheddar soup', 'panera broccoli cheddar bread bowl', 'broccoli cheddar soup panera'],
 'fast_food', 'Panera Bread', 1, '172 cal/100g. Per bread bowl (530g): 910 cal. Soup in sourdough bread bowl. Cup only (240g): 360 cal.', TRUE),

-- Panera Tomato Basil Bisque (cup): 200 cal per 240g cup. Per 100g: 83 cal.
('panera_tomato_soup', 'Panera Bread Creamy Tomato Basil Soup', 83, 1.7, 10.0, 4.2,
 1.3, 5.8, 240, 240,
 'panera_bread', ARRAY['panera tomato soup', 'panera tomato basil bisque', 'creamy tomato soup panera'],
 'fast_food', 'Panera Bread', 1, '83 cal/100g. Per cup (240g): 200 cal, 10g fat, 24g carb, 4g protein.', TRUE),

-- Panera Chicken Noodle Soup (cup): 120 cal per 240g. Per 100g: 50 cal.
('panera_chicken_noodle_soup', 'Panera Bread Chicken Noodle Soup', 50, 3.3, 5.0, 1.7,
 0.4, 0.8, 240, 240,
 'panera_bread', ARRAY['panera chicken noodle soup', 'panera chicken noodle', 'chicken noodle panera'],
 'fast_food', 'Panera Bread', 1, '50 cal/100g. Per cup (240g): 120 cal, 4g fat, 12g carb, 8g protein.', TRUE),

-- Panera Frontega Chicken Panini: 860 cal per 370g. Per 100g: 232 cal.
('panera_frontega_chicken', 'Panera Bread Frontega Chicken Panini', 232, 10.0, 14.6, 14.6,
 1.4, 2.0, 370, 370,
 'panera_bread', ARRAY['panera frontega chicken', 'frontega chicken panini panera', 'panera chicken panini'],
 'fast_food', 'Panera Bread', 1, '232 cal/100g. Per sandwich (370g): 860 cal, 42g fat, 54g carb, 37g protein. Smoked chicken, mozzarella, tomatoes.', TRUE),

-- Panera Turkey Avocado BLT: 730 cal per 350g. Per 100g: 209 cal.
('panera_turkey_avocado_blt', 'Panera Bread Roasted Turkey & Avocado BLT', 209, 8.6, 11.4, 14.0,
 1.4, 2.0, 350, 350,
 'panera_bread', ARRAY['panera turkey avocado blt', 'panera turkey blt', 'turkey avocado blt panera'],
 'fast_food', 'Panera Bread', 1, '209 cal/100g. Per sandwich (350g): 730 cal, 42g fat, 40g carb, 30g protein.', TRUE),

-- Panera Fuji Apple Chicken Salad (whole): 570 cal per 396g. Per 100g: 144 cal.
('panera_fuji_apple_salad', 'Panera Bread Fuji Apple Chicken Salad', 144, 7.1, 8.6, 8.8,
 1.3, 6.3, 396, 396,
 'panera_bread', ARRAY['panera fuji apple chicken salad', 'fuji apple salad panera', 'panera apple salad'],
 'fast_food', 'Panera Bread', 1, '144 cal/100g. Per whole salad (396g): 570 cal, 35g fat, 34g carb, 28g protein. Chicken, mixed greens, apple chips, pecans.', TRUE),

-- Panera Mac & Cheese (individual): 490 cal per 283g. Per 100g: 173 cal.
('panera_mac_and_cheese', 'Panera Bread Mac & Cheese', 173, 5.7, 13.4, 10.6,
 0.7, 2.8, 283, 283,
 'panera_bread', ARRAY['panera mac and cheese', 'panera mac cheese', 'panera macaroni and cheese'],
 'fast_food', 'Panera Bread', 1, '173 cal/100g. Per individual (283g): 490 cal, 30g fat, 38g carb, 16g protein. White cheddar shells.', TRUE),

-- Panera Cinnamon Crunch Bagel: 430 cal per 120g. Per 100g: 358 cal.
('panera_cinnamon_crunch_bagel', 'Panera Bread Cinnamon Crunch Bagel', 358, 7.5, 60.0, 9.2,
 2.5, 21.7, 120, 120,
 'panera_bread', ARRAY['panera cinnamon crunch bagel', 'cinnamon crunch bagel panera', 'panera cinnamon bagel'],
 'fast_food', 'Panera Bread', 1, '358 cal/100g. Per bagel (120g): 430 cal, 11g fat, 72g carb, 9g protein. Topped with cinnamon crunch topping.', TRUE),

-- Panera Asiago Cheese Bagel: 330 cal per 113g. Per 100g: 292 cal.
('panera_asiago_bagel', 'Panera Bread Asiago Cheese Bagel', 292, 10.6, 44.2, 7.1,
 1.8, 5.3, 113, 113,
 'panera_bread', ARRAY['panera asiago bagel', 'asiago cheese bagel panera', 'panera asiago'],
 'fast_food', 'Panera Bread', 1, '292 cal/100g. Per bagel (113g): 330 cal, 6g fat, 50g carb, 12g protein. Topped with asiago cheese.', TRUE),

-- Panera Caesar Salad (whole): 360 cal per 280g. Per 100g: 129 cal.
('panera_caesar_salad', 'Panera Bread Caesar Salad', 129, 4.3, 5.7, 10.0,
 1.4, 1.4, 280, 280,
 'panera_bread', ARRAY['panera caesar salad', 'caesar salad panera', 'panera side caesar'],
 'fast_food', 'Panera Bread', 1, '129 cal/100g. Per whole salad (280g): 360 cal, 28g fat, 16g carb, 12g protein. Romaine, parmesan, croutons.', TRUE),

-- Panera Greek Salad (whole): 400 cal per 340g. Per 100g: 118 cal.
('panera_greek_salad', 'Panera Bread Greek Salad', 118, 3.2, 5.3, 9.4,
 1.2, 2.6, 340, 340,
 'panera_bread', ARRAY['panera greek salad', 'greek salad panera'],
 'fast_food', 'Panera Bread', 1, '118 cal/100g. Per whole salad (340g): 400 cal, 32g fat, 18g carb, 11g protein. Feta, olives, pepperoncini.', TRUE),

-- Panera Charged Lemonade (regular 20oz): 260 cal per 590ml (~600g). Per 100g: 43 cal.
('panera_charged_lemonade', 'Panera Bread Charged Lemonade', 43, 0.0, 10.8, 0.0,
 0.0, 10.5, 600, 600,
 'panera_bread', ARRAY['panera charged lemonade', 'charged lemonade panera', 'panera lemonade caffeine'],
 'fast_food', 'Panera Bread', 1, '43 cal/100g. Per regular 20oz (~600g): 260 cal. Contains caffeine (260mg). Highly caffeinated lemonade.', TRUE),

-- Panera Strawberry Banana Smoothie: 300 cal per 450g (16oz). Per 100g: 67 cal.
('panera_strawberry_smoothie', 'Panera Bread Strawberry Banana Smoothie', 67, 1.1, 14.7, 0.4,
 1.1, 11.8, 450, 450,
 'panera_bread', ARRAY['panera strawberry banana smoothie', 'panera smoothie', 'strawberry smoothie panera'],
 'fast_food', 'Panera Bread', 1, '67 cal/100g. Per 16oz (~450g): 300 cal, 2g fat, 66g carb, 5g protein. Real fruit smoothie.', TRUE),

-- ==========================================
-- H. WAFFLE HOUSE (~10 items)
-- ==========================================

-- Waffle House Original Waffle: 410 cal per 190g. Per 100g: 216 cal.
('waffle_house_waffle', 'Waffle House Original Waffle', 216, 6.3, 29.5, 8.4,
 0.5, 6.3, 190, 190,
 'waffle_house', ARRAY['waffle house waffle', 'waffle house original waffle', 'waffle house plain waffle'],
 'fast_food', 'Waffle House', 1, '216 cal/100g. Per waffle (190g): 410 cal. Classic Belgian-style waffle.', TRUE),

-- Waffle House Pecan Waffle: 510 cal per 210g. Per 100g: 243 cal.
('waffle_house_pecan_waffle', 'Waffle House Pecan Waffle', 243, 7.1, 28.6, 11.4,
 1.0, 7.1, 210, 210,
 'waffle_house', ARRAY['waffle house pecan waffle', 'pecan waffle waffle house'],
 'fast_food', 'Waffle House', 1, '243 cal/100g. Per waffle (210g): 510 cal. Original waffle with pecans baked in.', TRUE),

-- Waffle House Hash Browns (scattered): 190 cal per 150g. Per 100g: 127 cal.
('waffle_house_hash_browns', 'Waffle House Hash Browns (Scattered)', 127, 2.0, 16.0, 6.0,
 1.3, 0.3, 150, 150,
 'waffle_house', ARRAY['waffle house hash browns', 'waffle house hashbrowns', 'waffle house scattered hash browns'],
 'fast_food', 'Waffle House', 1, '127 cal/100g. Per order (150g): 190 cal. Shredded potatoes, griddled. Base for toppings.', TRUE),

-- Waffle House Bacon (3 strips): 150 cal per 36g. Per 100g: 417 cal.
('waffle_house_bacon', 'Waffle House Bacon (3 Strips)', 417, 25.0, 0.0, 33.3,
 0.0, 0.0, 36, 12,
 'waffle_house', ARRAY['waffle house bacon', 'bacon waffle house'],
 'fast_food', 'Waffle House', 3, '417 cal/100g. Per 3 strips (36g): 150 cal. Hickory smoked bacon, griddled.', TRUE),

-- Waffle House Sausage Patty: 260 cal per 85g. Per 100g: 306 cal.
('waffle_house_sausage', 'Waffle House Sausage Patty', 306, 14.1, 1.2, 27.1,
 0.0, 0.6, 85, 85,
 'waffle_house', ARRAY['waffle house sausage', 'waffle house sausage patty', 'sausage waffle house'],
 'fast_food', 'Waffle House', 1, '306 cal/100g. Per patty (85g): 260 cal. Seasoned pork sausage patty.', TRUE),

-- Waffle House Eggs Scrambled (2): 180 cal per 100g. Per 100g: 180 cal.
('waffle_house_eggs_scrambled', 'Waffle House Scrambled Eggs (2)', 180, 12.0, 1.0, 14.0,
 0.0, 0.5, 100, 50,
 'waffle_house', ARRAY['waffle house scrambled eggs', 'waffle house eggs', 'eggs scrambled waffle house'],
 'fast_food', 'Waffle House', 2, '180 cal/100g. Per 2 eggs (100g): 180 cal. Scrambled on the grill with oil.', TRUE),

-- Waffle House Grits: 90 cal per 195g. Per 100g: 46 cal.
('waffle_house_grits', 'Waffle House Grits', 46, 1.0, 8.2, 1.0,
 0.3, 0.2, 195, 195,
 'waffle_house', ARRAY['waffle house grits', 'grits waffle house', 'waffle house regular grits'],
 'fast_food', 'Waffle House', 1, '46 cal/100g. Per serving (195g): 90 cal. Creamy homestyle grits.', TRUE),

-- Waffle House Toast (white, 2 slices): 160 cal per 56g. Per 100g: 286 cal.
('waffle_house_toast', 'Waffle House Toast (White, 2 slices)', 286, 7.1, 46.4, 7.1,
 1.8, 3.6, 56, 28,
 'waffle_house', ARRAY['waffle house toast', 'toast waffle house', 'waffle house white toast'],
 'fast_food', 'Waffle House', 2, '286 cal/100g. Per 2 slices (56g): 160 cal. Buttered white toast.', TRUE),

-- Waffle House T-bone Steak: 620 cal per 340g (12oz). Per 100g: 182 cal.
('waffle_house_tbone', 'Waffle House T-bone Steak', 182, 20.6, 0.0, 10.6,
 0.0, 0.0, 340, 340,
 'waffle_house', ARRAY['waffle house t-bone', 'waffle house tbone steak', 'waffle house steak', 't bone steak waffle house'],
 'fast_food', 'Waffle House', 1, '182 cal/100g. Per 12oz steak (340g): 620 cal, 36g fat, 0g carb, 70g protein. Grilled T-bone.', TRUE),

-- ==========================================
-- I. PANDA EXPRESS (~12 items)
-- ==========================================

-- Panda Express Orange Chicken: 490 cal per 162g serving. Per 100g: 302 cal. CRITICAL - most searched.
('panda_express_orange_chicken', 'Panda Express Orange Chicken', 302, 8.6, 32.7, 14.8,
 0.6, 12.3, 162, 162,
 'panda_express', ARRAY['panda express orange chicken', 'orange chicken panda', 'panda orange chicken', 'panda express orange'],
 'fast_food', 'Panda Express', 1, '302 cal/100g. Per entree serving (162g): 490 cal, 24g fat, 53g carb, 14g protein. MOST POPULAR item — crispy chicken in orange sauce.', TRUE),

-- Panda Express Broccoli Beef: 150 cal per 163g serving. Per 100g: 92 cal.
('panda_express_broccoli_beef', 'Panda Express Broccoli Beef', 92, 6.1, 7.4, 4.3,
 1.2, 3.1, 163, 163,
 'panda_express', ARRAY['panda express broccoli beef', 'broccoli beef panda', 'panda broccoli beef'],
 'fast_food', 'Panda Express', 1, '92 cal/100g. Per entree serving (163g): 150 cal, 7g fat, 12g carb, 10g protein. Tender beef and broccoli in ginger soy sauce.', TRUE),

-- Panda Express Kung Pao Chicken: 290 cal per 163g serving. Per 100g: 178 cal.
('panda_express_kung_pao', 'Panda Express Kung Pao Chicken', 178, 10.4, 8.6, 11.0,
 1.2, 3.7, 163, 163,
 'panda_express', ARRAY['panda express kung pao chicken', 'kung pao panda', 'panda kung pao'],
 'fast_food', 'Panda Express', 1, '178 cal/100g. Per entree serving (163g): 290 cal, 18g fat, 14g carb, 17g protein. Spicy with peanuts and vegetables.', TRUE),

-- Panda Express Beijing Beef: 470 cal per 163g serving. Per 100g: 288 cal.
('panda_express_beijing_beef', 'Panda Express Beijing Beef', 288, 7.4, 28.2, 15.3,
 1.2, 14.1, 163, 163,
 'panda_express', ARRAY['panda express beijing beef', 'beijing beef panda', 'panda beijing beef'],
 'fast_food', 'Panda Express', 1, '288 cal/100g. Per entree serving (163g): 470 cal, 25g fat, 46g carb, 12g protein. Crispy beef strips in sweet-tangy sauce.', TRUE),

-- Panda Express Honey Walnut Shrimp: 360 cal per 163g serving. Per 100g: 221 cal.
('panda_express_honey_walnut_shrimp', 'Panda Express Honey Walnut Shrimp', 221, 7.4, 19.6, 12.3,
 0.6, 9.2, 163, 163,
 'panda_express', ARRAY['panda express honey walnut shrimp', 'honey walnut shrimp panda', 'panda walnut shrimp'],
 'fast_food', 'Panda Express', 1, '221 cal/100g. Per entree serving (163g): 360 cal, 20g fat, 32g carb, 12g protein. Tempura shrimp with walnuts.', TRUE),

-- Panda Express String Bean Chicken Breast: 190 cal per 163g serving. Per 100g: 117 cal.
('panda_express_string_bean_chicken', 'Panda Express String Bean Chicken Breast', 117, 9.2, 5.5, 6.1,
 1.2, 2.5, 163, 163,
 'panda_express', ARRAY['panda express string bean chicken', 'string bean chicken panda', 'panda string bean chicken breast'],
 'fast_food', 'Panda Express', 1, '117 cal/100g. Per entree serving (163g): 190 cal, 10g fat, 9g carb, 15g protein. Chicken breast with green beans.', TRUE),

-- Panda Express Mushroom Chicken: 220 cal per 163g serving. Per 100g: 135 cal.
('panda_express_mushroom_chicken', 'Panda Express Mushroom Chicken', 135, 8.6, 5.5, 8.0,
 0.6, 3.1, 163, 163,
 'panda_express', ARRAY['panda express mushroom chicken', 'mushroom chicken panda', 'panda mushroom chicken'],
 'fast_food', 'Panda Express', 1, '135 cal/100g. Per entree serving (163g): 220 cal, 13g fat, 9g carb, 14g protein. Chicken, mushrooms, zucchini.', TRUE),

-- Panda Express Chow Mein: 510 cal per 273g serving. Per 100g: 187 cal.
('panda_express_chow_mein', 'Panda Express Chow Mein', 187, 3.7, 24.2, 8.4,
 1.5, 2.2, 273, 273,
 'panda_express', ARRAY['panda express chow mein', 'chow mein panda', 'panda chow mein'],
 'fast_food', 'Panda Express', 1, '187 cal/100g. Per side serving (273g): 510 cal, 23g fat, 66g carb, 10g protein. Stir-fried wheat noodles.', TRUE),

-- Panda Express Fried Rice: 520 cal per 273g serving. Per 100g: 190 cal.
('panda_express_fried_rice', 'Panda Express Fried Rice', 190, 3.7, 27.5, 7.3,
 0.7, 0.7, 273, 273,
 'panda_express', ARRAY['panda express fried rice', 'fried rice panda', 'panda fried rice'],
 'fast_food', 'Panda Express', 1, '190 cal/100g. Per side serving (273g): 520 cal, 20g fat, 75g carb, 10g protein. Wok-fried rice with egg and vegetables.', TRUE),

-- Panda Express White Steamed Rice: 380 cal per 273g serving. Per 100g: 139 cal.
('panda_express_steamed_rice', 'Panda Express White Steamed Rice', 139, 2.9, 30.8, 0.4,
 0.0, 0.0, 273, 273,
 'panda_express', ARRAY['panda express steamed rice', 'panda express white rice', 'white rice panda', 'panda steamed rice'],
 'fast_food', 'Panda Express', 1, '139 cal/100g. Per side serving (273g): 380 cal, 1g fat, 84g carb, 8g protein. Plain steamed long grain rice.', TRUE),

-- Panda Express Chicken Egg Roll: 200 cal per 78g. Per 100g: 256 cal.
('panda_express_egg_roll', 'Panda Express Chicken Egg Roll', 256, 6.4, 21.8, 15.4,
 1.3, 2.6, 78, 78,
 'panda_express', ARRAY['panda express egg roll', 'panda egg roll', 'chicken egg roll panda express'],
 'fast_food', 'Panda Express', 1, '256 cal/100g. Per roll (78g): 200 cal, 12g fat, 17g carb, 5g protein. Crispy fried egg roll with chicken and vegetables.', TRUE),

-- Panda Express Cream Cheese Rangoon: 190 cal per 64g (2pc). Per 100g: 297 cal.
('panda_express_cream_cheese_rangoon', 'Panda Express Cream Cheese Rangoon', 297, 4.7, 25.0, 18.8,
 0.8, 3.1, 64, 32,
 'panda_express', ARRAY['panda express cream cheese rangoon', 'panda express rangoon', 'cream cheese rangoon panda'],
 'fast_food', 'Panda Express', 2, '297 cal/100g. Per 2pc (64g): 190 cal, 12g fat, 16g carb, 3g protein. Crispy wonton with cream cheese filling.', TRUE)

,

-- ==========================================
-- J. CONDIMENTS (~25 items)
-- ==========================================

-- Heinz Ketchup: per 100g: 112 cal. USDA.
('heinz_ketchup', 'Heinz Tomato Ketchup', 112, 1.2, 27.4, 0.1,
 0.3, 22.8, 17, 17,
 'heinz', ARRAY['heinz ketchup', 'heinz tomato ketchup', 'ketchup heinz'],
 'condiments', NULL, 1, '112 cal/100g. Per tbsp (17g): 19 cal. America''s favorite ketchup.', TRUE),

-- Generic Ketchup: per 100g: 101 cal. USDA.
('ketchup_generic', 'Ketchup (Generic)', 101, 1.0, 27.0, 0.1,
 0.3, 21.3, 17, 17,
 'usda', ARRAY['ketchup', 'tomato ketchup', 'catsup'],
 'condiments', NULL, 1, '101 cal/100g. Per tbsp (17g): 17 cal.', TRUE),

-- Hellmann's Real Mayonnaise: per 100g: 680 cal. Manufacturer label.
('hellmanns_mayo', 'Hellmann''s Real Mayonnaise', 680, 0.7, 0.7, 73.3,
 0.0, 0.7, 15, 15,
 'hellmanns', ARRAY['hellmanns mayo', 'hellmann''s real mayonnaise', 'hellmanns real mayo', 'best foods mayo'],
 'condiments', NULL, 1, '680 cal/100g. Per tbsp (15g): 100 cal. Soybean oil, eggs, vinegar.', TRUE),

-- Duke's Mayonnaise: per 100g: 667 cal.
('dukes_mayo', 'Duke''s Real Mayonnaise', 667, 0.0, 0.0, 73.3,
 0.0, 0.0, 15, 15,
 'dukes', ARRAY['dukes mayo', 'duke''s mayonnaise', 'duke''s real mayo'],
 'condiments', NULL, 1, '667 cal/100g. Per tbsp (15g): 100 cal. No sugar added. Southern classic.', TRUE),

-- Miracle Whip: per 100g: 333 cal.
('miracle_whip', 'Miracle Whip Original', 333, 0.0, 13.3, 33.3,
 0.0, 13.3, 15, 15,
 'kraft', ARRAY['miracle whip', 'miracle whip original', 'miracle whip dressing'],
 'condiments', NULL, 1, '333 cal/100g. Per tbsp (15g): 50 cal. Not mayo — tangy dressing.', TRUE),

-- French's Yellow Mustard: per 100g: 60 cal. USDA.
('frenchs_yellow_mustard', 'French''s Classic Yellow Mustard', 60, 3.3, 6.7, 3.3,
 3.3, 0.0, 5, 5,
 'frenchs', ARRAY['frenchs yellow mustard', 'french''s mustard', 'yellow mustard frenchs', 'classic yellow mustard'],
 'condiments', NULL, 1, '60 cal/100g. Per tsp (5g): 3 cal. Stone ground #1 grade mustard seed.', TRUE),

-- Grey Poupon Dijon Mustard: per 100g: 67 cal.
('grey_poupon_dijon', 'Grey Poupon Dijon Mustard', 67, 4.0, 3.3, 4.0,
 2.0, 0.7, 5, 5,
 'grey_poupon', ARRAY['grey poupon', 'grey poupon dijon', 'dijon mustard grey poupon'],
 'condiments', NULL, 1, '67 cal/100g. Per tsp (5g): 3 cal. Classic French-style Dijon.', TRUE),

-- Honey Mustard (generic): per 100g: 250 cal.
('honey_mustard', 'Honey Mustard (Generic)', 250, 2.0, 30.0, 14.0,
 0.7, 26.0, 15, 15,
 'usda', ARRAY['honey mustard', 'honey mustard sauce', 'honey mustard dressing'],
 'condiments', NULL, 1, '250 cal/100g. Per tbsp (15g): 38 cal. Blend of honey, mustard, and mayo.', TRUE),

-- Hidden Valley Ranch: per 100g: 477 cal.
('hidden_valley_ranch', 'Hidden Valley Original Ranch Dressing', 477, 1.5, 6.2, 49.2,
 0.0, 3.1, 30, 30,
 'hidden_valley', ARRAY['hidden valley ranch', 'ranch dressing hidden valley', 'hidden valley original ranch'],
 'condiments', NULL, 1, '477 cal/100g. Per 2 tbsp (30g): 143 cal. Classic buttermilk ranch dressing.', TRUE),

-- Sweet Baby Ray's BBQ Sauce Original: per 100g: 162 cal.
('sweet_baby_rays_bbq', 'Sweet Baby Ray''s BBQ Sauce Original', 162, 0.0, 37.8, 0.0,
 0.0, 32.4, 37, 37,
 'sweet_baby_rays', ARRAY['sweet baby rays bbq', 'sweet baby ray''s barbecue sauce', 'sweet baby rays original bbq'],
 'condiments', NULL, 1, '162 cal/100g. Per 2 tbsp (37g): 60 cal. Award-winning sweet-tangy BBQ sauce.', TRUE),

-- Frank's RedHot Original: per 100g: 0 cal (trace).
('franks_redhot', 'Frank''s RedHot Original Cayenne Pepper Sauce', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 5, 5,
 'franks', ARRAY['franks redhot', 'frank''s red hot', 'franks hot sauce', 'redhot original'],
 'condiments', NULL, 1, '0 cal/100g. Per tsp (5g): 0 cal. Cayenne pepper sauce, zero calories. Great for adding heat without calories.', TRUE),

-- Sriracha Huy Fong: per 100g: 93 cal. Manufacturer.
('sriracha_huy_fong', 'Huy Fong Sriracha Hot Chili Sauce', 93, 2.0, 18.7, 0.7,
 1.3, 14.7, 5, 5,
 'huy_fong', ARRAY['sriracha', 'huy fong sriracha', 'sriracha hot sauce', 'rooster sauce'],
 'condiments', NULL, 1, '93 cal/100g. Per tsp (5g): 5 cal. Iconic rooster bottle. Chili, garlic, sugar, vinegar.', TRUE),

-- Cholula Original Hot Sauce: per 100g: 0 cal.
('cholula_hot_sauce', 'Cholula Original Hot Sauce', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 5, 5,
 'cholula', ARRAY['cholula', 'cholula hot sauce', 'cholula original'],
 'condiments', NULL, 1, '0 cal/100g. Per tsp (5g): 0 cal. Pequin and arbol peppers. Zero calories.', TRUE),

-- Tabasco Original Red: per 100g: 12 cal.
('tabasco', 'Tabasco Original Red Pepper Sauce', 12, 1.2, 0.0, 0.4,
 0.4, 0.0, 5, 5,
 'tabasco', ARRAY['tabasco', 'tabasco sauce', 'tabasco original', 'tabasco red pepper sauce'],
 'condiments', NULL, 1, '12 cal/100g. Per tsp (5g): 1 cal. Aged cayenne pepper mash, vinegar, salt.', TRUE),

-- Kikkoman Soy Sauce: per 100g: 60 cal. USDA.
('kikkoman_soy_sauce', 'Kikkoman Soy Sauce', 60, 8.7, 5.3, 0.0,
 0.7, 0.7, 15, 15,
 'kikkoman', ARRAY['kikkoman soy sauce', 'soy sauce kikkoman', 'kikkoman naturally brewed soy sauce'],
 'condiments', NULL, 1, '60 cal/100g. Per tbsp (15g): 9 cal. Naturally brewed. Very high sodium (5493mg/100g).', TRUE),

-- Worcestershire Sauce: per 100g: 78 cal. USDA.
('worcestershire_sauce', 'Lea & Perrins Worcestershire Sauce', 78, 0.0, 19.5, 0.0,
 0.0, 10.0, 5, 5,
 'lea_perrins', ARRAY['worcestershire sauce', 'lea and perrins', 'worcestershire', 'lea perrins worcestershire'],
 'condiments', NULL, 1, '78 cal/100g. Per tsp (5g): 4 cal. Fermented anchovy and tamarind based.', TRUE),

-- Hoisin Sauce: per 100g: 220 cal. USDA.
('hoisin_sauce', 'Hoisin Sauce (Generic)', 220, 3.3, 44.1, 3.4,
 1.9, 30.0, 16, 16,
 'usda', ARRAY['hoisin sauce', 'hoisin', 'chinese bbq sauce', 'peking sauce'],
 'condiments', NULL, 1, '220 cal/100g. Per tbsp (16g): 35 cal. Sweet, thick sauce from soybeans, garlic, chili.', TRUE),

-- Balsamic Vinegar: per 100g: 88 cal. USDA.
('balsamic_vinegar', 'Balsamic Vinegar', 88, 0.5, 17.0, 0.0,
 0.0, 14.9, 15, 15,
 'usda', ARRAY['balsamic vinegar', 'balsamic', 'balsamic vinegar of modena'],
 'condiments', NULL, 1, '88 cal/100g. Per tbsp (15g): 13 cal. Aged Italian vinegar from grape must.', TRUE),

-- Apple Cider Vinegar Bragg's: per 100g: 22 cal. USDA/Bragg.
('braggs_apple_cider_vinegar', 'Bragg''s Apple Cider Vinegar', 22, 0.0, 0.9, 0.0,
 0.0, 0.4, 15, 15,
 'braggs', ARRAY['braggs apple cider vinegar', 'bragg''s acv', 'apple cider vinegar braggs', 'bragg acv'],
 'condiments', NULL, 1, '22 cal/100g. Per tbsp (15g): 3 cal. Raw, unfiltered, with the mother. Health wellness staple.', TRUE),

-- Coconut Aminos: per 100g: 100 cal.
('coconut_aminos', 'Coconut Aminos', 100, 0.0, 20.0, 0.0,
 0.0, 20.0, 5, 5,
 'coconut_secret', ARRAY['coconut aminos', 'coconut aminos sauce', 'soy sauce alternative coconut'],
 'condiments', NULL, 1, '100 cal/100g. Per tsp (5g): 5 cal. Soy-free soy sauce alternative from coconut tree sap. Lower sodium.', TRUE),

-- Primal Kitchen Mayo: per 100g: 733 cal.
('primal_kitchen_mayo', 'Primal Kitchen Mayo (Avocado Oil)', 733, 0.0, 0.0, 80.0,
 0.0, 0.0, 15, 15,
 'primal_kitchen', ARRAY['primal kitchen mayo', 'primal kitchen avocado oil mayo', 'avocado oil mayonnaise primal kitchen'],
 'condiments', NULL, 1, '733 cal/100g. Per tbsp (15g): 110 cal. Made with avocado oil. No sugar, no seed oils. Paleo/keto-friendly.', TRUE),

-- ==========================================
-- K. BEVERAGES (~20 items)
-- ==========================================

-- Sprite: per 100ml: 39 cal. Manufacturer.
('sprite', 'Sprite', 39, 0.0, 10.2, 0.0,
 0.0, 10.0, 355, 355,
 'coca_cola', ARRAY['sprite', 'sprite soda', 'sprite lemon lime'],
 'beverages', NULL, 1, '39 cal/100ml. Per 12oz can (355ml): 140 cal. Lemon-lime soda.', TRUE),

-- Sprite Zero: 0 cal. Manufacturer.
('sprite_zero', 'Sprite Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, 355,
 'coca_cola', ARRAY['sprite zero', 'sprite zero sugar', 'sprite diet', 'sprite sugar free'],
 'beverages', NULL, 1, '0 cal/100ml. Per 12oz can (355ml): 0 cal. Zero sugar, zero calorie.', TRUE),

-- Dr Pepper: per 100ml: 42 cal. Manufacturer.
('dr_pepper', 'Dr Pepper', 42, 0.0, 10.6, 0.0,
 0.0, 10.6, 355, 355,
 'dr_pepper', ARRAY['dr pepper', 'dr. pepper', 'dr pepper soda', 'dr pepper original'],
 'beverages', NULL, 1, '42 cal/100ml. Per 12oz can (355ml): 150 cal. Unique 23-flavor soda.', TRUE),

-- Diet Dr Pepper: 0 cal. Manufacturer.
('diet_dr_pepper', 'Diet Dr Pepper', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, 355,
 'dr_pepper', ARRAY['diet dr pepper', 'diet dr. pepper', 'dr pepper diet', 'dr pepper zero'],
 'beverages', NULL, 1, '0 cal/100ml. Per 12oz can (355ml): 0 cal. Zero calorie Dr Pepper.', TRUE),

-- Fanta Orange: per 100ml: 44 cal. Manufacturer.
('fanta_orange', 'Fanta Orange', 44, 0.0, 11.3, 0.0,
 0.0, 11.3, 355, 355,
 'coca_cola', ARRAY['fanta orange', 'fanta', 'fanta orange soda', 'orange fanta'],
 'beverages', NULL, 1, '44 cal/100ml. Per 12oz can (355ml): 160 cal. Orange-flavored soda.', TRUE),

-- 7UP: per 100ml: 39 cal. Manufacturer.
('seven_up', '7UP', 39, 0.0, 10.0, 0.0,
 0.0, 10.0, 355, 355,
 'pepsico', ARRAY['7up', '7 up', 'seven up', '7up soda', '7up lemon lime'],
 'beverages', NULL, 1, '39 cal/100ml. Per 12oz can (355ml): 140 cal. Lemon-lime soda.', TRUE),

-- LaCroix Sparkling Water: 0 cal.
('lacroix', 'LaCroix Sparkling Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, 355,
 'lacroix', ARRAY['lacroix', 'la croix', 'lacroix sparkling water', 'lacroix seltzer'],
 'beverages', NULL, 1, '0 cal/100ml. Per can (355ml): 0 cal. Naturally essenced sparkling water. Zero everything.', TRUE),

-- Topo Chico Mineral Water: 0 cal.
('topo_chico', 'Topo Chico Mineral Water', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, 355,
 'topo_chico', ARRAY['topo chico', 'topo chico mineral water', 'topo chico sparkling'],
 'beverages', NULL, 1, '0 cal/100ml. Per bottle (355ml): 0 cal. Mexican sparkling mineral water.', TRUE),

-- Black Coffee (brewed): per 100ml: 2 cal. USDA.
('black_coffee', 'Black Coffee (Brewed)', 2, 0.1, 0.0, 0.0,
 0.0, 0.0, 240, 240,
 'usda', ARRAY['black coffee', 'brewed coffee', 'drip coffee', 'coffee black', 'regular coffee'],
 'beverages', NULL, 1, '2 cal/100ml. Per 8oz cup (240ml): 5 cal. Plain brewed coffee, no additions. ~95mg caffeine.', TRUE),

-- Green Tea (brewed, unsweetened): per 100ml: 1 cal. USDA.
('green_tea', 'Green Tea (Brewed, Unsweetened)', 1, 0.0, 0.0, 0.0,
 0.0, 0.0, 240, 240,
 'usda', ARRAY['green tea', 'brewed green tea', 'green tea unsweetened', 'hot green tea'],
 'beverages', NULL, 1, '1 cal/100ml. Per 8oz cup (240ml): 2 cal. Plain brewed green tea. ~25-50mg caffeine. Rich in catechins.', TRUE),

-- Tropicana Orange Juice: per 100ml: 44 cal. Manufacturer.
('tropicana_oj', 'Tropicana Pure Premium Orange Juice', 44, 0.8, 10.0, 0.0,
 0.0, 9.2, 240, 240,
 'tropicana', ARRAY['tropicana orange juice', 'tropicana oj', 'tropicana pure premium', 'orange juice tropicana'],
 'beverages', NULL, 1, '44 cal/100ml. Per 8oz glass (240ml): 110 cal. 100% pure squeezed orange juice. Good source of vitamin C.', TRUE),

-- Apple Juice (generic): per 100ml: 46 cal. USDA.
('apple_juice', 'Apple Juice (Generic)', 46, 0.1, 11.3, 0.1,
 0.1, 9.6, 240, 240,
 'usda', ARRAY['apple juice', 'apple juice generic', '100 percent apple juice'],
 'beverages', NULL, 1, '46 cal/100ml. Per 8oz glass (240ml): 110 cal. 100% apple juice from concentrate.', TRUE),

-- Vita Coco Coconut Water: per 100ml: 19 cal. Manufacturer.
('vita_coco', 'Vita Coco Coconut Water', 19, 0.0, 4.6, 0.0,
 0.0, 4.2, 330, 330,
 'vita_coco', ARRAY['vita coco', 'vita coco coconut water', 'coconut water vita coco'],
 'beverages', NULL, 1, '19 cal/100ml. Per carton (330ml): 63 cal. Natural electrolytes, potassium-rich. Hydration drink.', TRUE),

-- GT's Kombucha Original: per 100ml: 12 cal. Manufacturer.
('gts_kombucha', 'GT''s Synergy Kombucha', 12, 0.0, 2.9, 0.0,
 0.0, 2.3, 473, 473,
 'gts_living_foods', ARRAY['gts kombucha', 'gt''s synergy', 'gt''s kombucha', 'kombucha gts'],
 'beverages', NULL, 1, '12 cal/100ml. Per 16oz bottle (473ml): 60 cal. Raw, organic kombucha. Probiotics.', TRUE),

-- White Claw Hard Seltzer: per 355ml can: 100 cal. Per 100ml: 28 cal.
('white_claw', 'White Claw Hard Seltzer', 28, 0.0, 1.4, 0.0,
 0.0, 1.4, 355, 355,
 'white_claw', ARRAY['white claw', 'white claw hard seltzer', 'white claw seltzer'],
 'beverages', NULL, 1, '28 cal/100ml. Per 12oz can (355ml): 100 cal, 5% ABV, 2g carb. Low-calorie alcoholic seltzer.', TRUE),

-- Bud Light: per 355ml can: 110 cal. Per 100ml: 31 cal.
('bud_light', 'Bud Light', 31, 0.3, 1.8, 0.0,
 0.0, 0.0, 355, 355,
 'anheuser_busch', ARRAY['bud light', 'bud light beer', 'budweiser light'],
 'beverages', NULL, 1, '31 cal/100ml. Per 12oz can (355ml): 110 cal, 4.2% ABV, 6.6g carb. America''s #1 light beer.', TRUE),

-- Red Wine (generic): per 100ml: 85 cal. USDA.
('red_wine', 'Red Wine (Generic)', 85, 0.1, 2.6, 0.0,
 0.0, 0.6, 148, 148,
 'usda', ARRAY['red wine', 'wine red', 'cabernet sauvignon', 'merlot', 'pinot noir', 'red wine glass'],
 'beverages', NULL, 1, '85 cal/100ml. Per 5oz glass (148ml): 125 cal. Average of common red varietals (~13.5% ABV).', TRUE),

-- White Wine (generic): per 100ml: 82 cal. USDA.
('white_wine', 'White Wine (Generic)', 82, 0.1, 2.6, 0.0,
 0.0, 1.0, 148, 148,
 'usda', ARRAY['white wine', 'wine white', 'chardonnay', 'sauvignon blanc', 'pinot grigio', 'white wine glass'],
 'beverages', NULL, 1, '82 cal/100ml. Per 5oz glass (148ml): 121 cal. Average of common white varietals (~12.5% ABV).', TRUE)

,

-- ==========================================
-- L. DELI MEATS (~15 items)
-- ==========================================

-- Sliced Turkey Breast (generic deli): per 100g: 104 cal, 18g protein. USDA.
('deli_turkey_breast', 'Sliced Turkey Breast (Deli)', 104, 18.0, 3.5, 1.5,
 0.0, 1.5, 56, 28,
 'usda', ARRAY['deli turkey breast', 'sliced turkey breast', 'turkey deli meat', 'turkey cold cut', 'lunch meat turkey'],
 'deli_meats', NULL, 2, '104 cal/100g. Per 2oz serving (56g): 58 cal. Lean protein source. Watch sodium.', TRUE),

-- Boar's Head Turkey Breast: per 100g: 100 cal.
('boars_head_turkey', 'Boar''s Head Ovengold Turkey Breast', 100, 19.6, 1.8, 1.8,
 0.0, 0.0, 56, 28,
 'boars_head', ARRAY['boars head turkey', 'boar''s head ovengold', 'boars head turkey breast', 'boar''s head turkey'],
 'deli_meats', NULL, 2, '100 cal/100g. Per 2oz serving (56g): 56 cal. Premium deli turkey, lower sodium option available.', TRUE),

-- Sliced Ham (deli): per 100g: 145 cal. USDA.
('deli_ham', 'Sliced Ham (Deli)', 145, 17.5, 3.5, 6.0,
 0.0, 2.5, 56, 28,
 'usda', ARRAY['deli ham', 'sliced ham', 'ham deli meat', 'lunch meat ham', 'honey ham deli'],
 'deli_meats', NULL, 2, '145 cal/100g. Per 2oz serving (56g): 81 cal.', TRUE),

-- Roast Beef (deli): per 100g: 170 cal. USDA.
('deli_roast_beef', 'Roast Beef (Deli)', 170, 22.0, 0.5, 8.0,
 0.0, 0.0, 56, 28,
 'usda', ARRAY['deli roast beef', 'sliced roast beef', 'roast beef deli meat', 'rare roast beef deli'],
 'deli_meats', NULL, 2, '170 cal/100g. Per 2oz serving (56g): 95 cal. Good protein source.', TRUE),

-- Genoa Salami: per 100g: 385 cal. USDA.
('genoa_salami', 'Genoa Salami', 385, 21.0, 0.5, 32.0,
 0.0, 0.5, 28, 9,
 'usda', ARRAY['genoa salami', 'salami genoa', 'salami deli', 'italian salami'],
 'deli_meats', NULL, 3, '385 cal/100g. Per 3 slices (28g): 108 cal. High fat, cured Italian sausage. Track portions carefully.', TRUE),

-- Pepperoni Hormel: per 100g: 494 cal. Manufacturer.
('hormel_pepperoni', 'Hormel Pepperoni', 494, 20.7, 1.4, 44.8,
 0.0, 0.0, 28, 2,
 'hormel', ARRAY['hormel pepperoni', 'pepperoni hormel', 'pepperoni slices', 'pepperoni deli'],
 'deli_meats', NULL, 14, '494 cal/100g. Per 14 slices (28g): 138 cal. Very calorie-dense. Common pizza topping.', TRUE),

-- Bologna Oscar Mayer: per 100g: 313 cal. Manufacturer.
('oscar_mayer_bologna', 'Oscar Mayer Bologna', 313, 11.3, 3.5, 28.5,
 0.0, 2.8, 28, 28,
 'oscar_mayer', ARRAY['oscar mayer bologna', 'bologna oscar mayer', 'bologna deli', 'baloney'],
 'deli_meats', NULL, 1, '313 cal/100g. Per slice (28g): 88 cal. Classic American processed meat.', TRUE),

-- Prosciutto: per 100g: 195 cal. USDA.
('prosciutto', 'Prosciutto (Italian Dry-Cured Ham)', 195, 28.0, 0.0, 8.5,
 0.0, 0.0, 28, 14,
 'usda', ARRAY['prosciutto', 'prosciutto di parma', 'italian prosciutto', 'dry cured ham', 'prosciutto crudo'],
 'deli_meats', NULL, 2, '195 cal/100g. Per 2 slices (28g): 55 cal. High protein, thin-sliced Italian classic.', TRUE),

-- Pastrami: per 100g: 147 cal. USDA.
('pastrami', 'Pastrami (Deli)', 147, 22.0, 1.5, 5.5,
 0.0, 0.5, 56, 28,
 'usda', ARRAY['pastrami', 'pastrami deli', 'sliced pastrami', 'beef pastrami'],
 'deli_meats', NULL, 2, '147 cal/100g. Per 2oz serving (56g): 82 cal. Smoked and spiced cured beef.', TRUE),

-- Bacon Oscar Mayer: per 100g: 541 cal. Manufacturer/USDA.
('oscar_mayer_bacon', 'Oscar Mayer Naturally Hardwood Smoked Bacon', 541, 33.3, 2.1, 43.8,
 0.0, 0.0, 16, 8,
 'oscar_mayer', ARRAY['oscar mayer bacon', 'bacon oscar mayer', 'hardwood smoked bacon'],
 'deli_meats', NULL, 2, '541 cal/100g. Per 2 cooked slices (16g): 87 cal. Calorie dense — measure carefully.', TRUE),

-- Turkey Bacon: per 100g: 218 cal. USDA.
('turkey_bacon', 'Turkey Bacon', 218, 16.1, 2.0, 16.1,
 0.0, 1.0, 16, 8,
 'usda', ARRAY['turkey bacon', 'turkey bacon slices', 'turkey bacon cooked'],
 'deli_meats', NULL, 2, '218 cal/100g. Per 2 cooked slices (16g): 35 cal. Lower fat alternative to pork bacon.', TRUE),

-- Canadian Bacon: per 100g: 131 cal. USDA.
('canadian_bacon', 'Canadian Bacon (Back Bacon)', 131, 18.0, 1.0, 5.5,
 0.0, 0.5, 56, 28,
 'usda', ARRAY['canadian bacon', 'back bacon', 'peameal bacon', 'canadian bacon sliced'],
 'deli_meats', NULL, 2, '131 cal/100g. Per 2 slices (56g): 73 cal. Lean, from pork loin. Great for egg sandwiches.', TRUE),

-- Hot Dog (beef): per 100g: 290 cal. USDA.
('hot_dog_beef', 'Beef Hot Dog (Generic)', 290, 11.4, 2.7, 26.1,
 0.0, 1.5, 52, 52,
 'usda', ARRAY['beef hot dog', 'hot dog beef', 'beef frank', 'frankfurter beef', 'hot dog'],
 'deli_meats', NULL, 1, '290 cal/100g. Per frank (52g): 151 cal. Classic all-beef frank. Bun adds ~120 cal.', TRUE),

-- Hot Dog (turkey): per 100g: 154 cal. USDA.
('hot_dog_turkey', 'Turkey Hot Dog', 154, 11.5, 3.8, 10.6,
 0.0, 1.0, 52, 52,
 'usda', ARRAY['turkey hot dog', 'hot dog turkey', 'turkey frank', 'turkey frankfurter'],
 'deli_meats', NULL, 1, '154 cal/100g. Per frank (52g): 80 cal. Lower fat than beef. Lighter option.', TRUE),

-- ==========================================
-- M. COOKIES & CRACKERS (~15 items)
-- ==========================================

-- Oreo Original: per 100g: 482 cal. Manufacturer/USDA.
('oreo_original', 'Oreo Original Cookies', 482, 4.5, 68.2, 20.5,
 1.8, 36.4, 34, 11.3,
 'nabisco', ARRAY['oreo', 'oreo original', 'oreo cookies', 'oreo chocolate sandwich cookies'],
 'cookies_crackers', NULL, 3, '482 cal/100g. Per cookie (11.3g): 53 cal. Per 3-cookie serving (34g): 160 cal. America''s favorite cookie.', TRUE),

-- Oreo Double Stuf: per 100g: 483 cal. Manufacturer.
('oreo_double_stuf', 'Oreo Double Stuf Cookies', 483, 3.4, 67.2, 22.4,
 1.0, 39.7, 30, 15,
 'nabisco', ARRAY['oreo double stuf', 'oreo double stuff', 'double stuf oreo', 'oreo double stuffed'],
 'cookies_crackers', NULL, 2, '483 cal/100g. Per cookie (15g): 72 cal. Per 2-cookie serving (30g): 145 cal. Extra creme filling.', TRUE),

-- Oreo Thins: per 100g: 500 cal. Manufacturer.
('oreo_thins', 'Oreo Thins Cookies', 500, 4.3, 65.2, 23.9,
 1.4, 34.8, 29, 9.7,
 'nabisco', ARRAY['oreo thins', 'oreo thin cookies', 'thin oreos'],
 'cookies_crackers', NULL, 3, '500 cal/100g. Per cookie (9.7g): 49 cal. Per 3-cookie serving (29g): 145 cal. Crispy thin version.', TRUE),

-- Chips Ahoy Original: per 100g: 474 cal. Manufacturer.
('chips_ahoy_original', 'Chips Ahoy! Original Cookies', 474, 3.8, 63.5, 22.1,
 1.0, 32.7, 33, 11,
 'nabisco', ARRAY['chips ahoy', 'chips ahoy original', 'chips ahoy cookies', 'chips ahoy chocolate chip'],
 'cookies_crackers', NULL, 3, '474 cal/100g. Per cookie (11g): 52 cal. Per 3-cookie serving (33g): 160 cal.', TRUE),

-- Chips Ahoy Chewy: per 100g: 471 cal. Manufacturer.
('chips_ahoy_chewy', 'Chips Ahoy! Chewy Cookies', 471, 3.8, 64.7, 20.6,
 0.6, 35.3, 33, 16.5,
 'nabisco', ARRAY['chips ahoy chewy', 'chewy chips ahoy', 'chips ahoy soft'],
 'cookies_crackers', NULL, 2, '471 cal/100g. Per cookie (16.5g): 78 cal. Per 2-cookie serving (33g): 155 cal. Soft and chewy.', TRUE),

-- Ritz Crackers Original: per 100g: 492 cal. Manufacturer/USDA.
('ritz_crackers', 'Ritz Crackers Original', 492, 6.3, 56.3, 25.0,
 1.3, 9.4, 16, 3.2,
 'nabisco', ARRAY['ritz crackers', 'ritz crackers original', 'ritz original', 'ritz'],
 'cookies_crackers', NULL, 5, '492 cal/100g. Per cracker (3.2g): 16 cal. Per 5-cracker serving (16g): 79 cal. Buttery round crackers.', TRUE),

-- Cheez-It Original: per 100g: 490 cal. Manufacturer.
('cheez_it_original', 'Cheez-It Original Crackers', 490, 10.0, 56.7, 23.3,
 1.7, 3.3, 30, 1.3,
 'cheez_it', ARRAY['cheez it', 'cheez-it original', 'cheez it crackers', 'cheez its'],
 'cookies_crackers', NULL, 1, '490 cal/100g. Per 30g serving (~23 crackers): 147 cal. Baked cheese crackers.', TRUE),

-- Cheez-It Extra Toasty: per 100g: 497 cal. Manufacturer.
('cheez_it_extra_toasty', 'Cheez-It Extra Toasty Crackers', 497, 10.0, 56.7, 24.7,
 1.7, 3.3, 30, 1.3,
 'cheez_it', ARRAY['cheez it extra toasty', 'cheez-it extra toasty', 'extra toasty cheez its'],
 'cookies_crackers', NULL, 1, '497 cal/100g. Per 30g serving: 150 cal. Toasted longer for extra flavor.', TRUE),

-- Wheat Thins Original: per 100g: 448 cal. Manufacturer/USDA.
('wheat_thins', 'Wheat Thins Original', 448, 6.9, 65.5, 17.2,
 3.4, 10.3, 31, 2,
 'nabisco', ARRAY['wheat thins', 'wheat thins original', 'wheat thin crackers'],
 'cookies_crackers', NULL, 1, '448 cal/100g. Per 31g serving (~16 crackers): 139 cal. Whole grain wheat crackers.', TRUE),

-- Triscuit Original: per 100g: 428 cal. Manufacturer/USDA.
('triscuit_original', 'Triscuit Original Crackers', 428, 8.9, 64.3, 14.3,
 7.1, 0.0, 28, 4.7,
 'nabisco', ARRAY['triscuit', 'triscuit original', 'triscuit crackers', 'triscuits'],
 'cookies_crackers', NULL, 6, '428 cal/100g. Per 6-cracker serving (28g): 120 cal. Woven wheat, 3 ingredients. High fiber.', TRUE),

-- Graham Crackers: per 100g: 430 cal. USDA.
('graham_crackers', 'Graham Crackers (Honey Maid)', 430, 6.9, 73.8, 11.5,
 2.3, 30.0, 31, 7.75,
 'honey_maid', ARRAY['graham crackers', 'honey maid graham crackers', 'graham cracker sheets'],
 'cookies_crackers', NULL, 4, '430 cal/100g. Per sheet (31g/4 crackers): 130 cal. Classic honey graham. S''mores essential.', TRUE),

-- Snyder's Mini Pretzels: per 100g: 375 cal. Manufacturer.
('snyders_mini_pretzels', 'Snyder''s of Hanover Mini Pretzels', 375, 10.0, 78.6, 3.6,
 3.6, 3.6, 28, 28,
 'snyders', ARRAY['snyders mini pretzels', 'snyder''s of hanover mini pretzels', 'mini pretzels snyders', 'snyder pretzels'],
 'cookies_crackers', NULL, 1, '375 cal/100g. Per 1oz serving (28g): 110 cal. Low fat pretzel snack.', TRUE),

-- Nutter Butter: per 100g: 487 cal. Manufacturer.
('nutter_butter', 'Nutter Butter Peanut Butter Cookies', 487, 6.7, 60.0, 23.3,
 1.3, 26.7, 30, 10,
 'nabisco', ARRAY['nutter butter', 'nutter butter cookies', 'nutter butter peanut butter'],
 'cookies_crackers', NULL, 3, '487 cal/100g. Per cookie (10g): 49 cal. Per 3 serving (30g): 146 cal. Peanut-shaped sandwich cookies.', TRUE),

-- Pepperidge Farm Milano: per 100g: 500 cal. Manufacturer.
('pepperidge_farm_milano', 'Pepperidge Farm Milano Cookies', 500, 5.0, 57.5, 27.5,
 2.5, 32.5, 25, 12.5,
 'pepperidge_farm', ARRAY['pepperidge farm milano', 'milano cookies', 'pepperidge milano', 'milano chocolate'],
 'cookies_crackers', NULL, 2, '500 cal/100g. Per cookie (12.5g): 63 cal. Per 2-cookie serving (25g): 125 cal. Dark chocolate between crispy cookies.', TRUE),

-- ==========================================
-- N. PROTEIN POWDERS & SUPPLEMENTS (~10 items)
-- ==========================================

-- ON Gold Standard Whey Chocolate: per 31g scoop: 120 cal, 24g P. Per 100g: 387 cal, 77.4g P.
('on_gold_standard_whey_chocolate', 'Optimum Nutrition Gold Standard Whey (Double Rich Chocolate)', 387, 77.4, 9.7, 3.2,
 3.2, 3.2, 31, 31,
 'optimum_nutrition', ARRAY['on gold standard whey chocolate', 'optimum nutrition whey chocolate', 'gold standard whey double rich chocolate', 'on whey chocolate'],
 'supplements', NULL, 1, '387 cal/100g. Per scoop (31g): 120 cal, 24g protein, 3g carb, 1g fat. #1 selling whey protein worldwide.', TRUE),

-- ON Gold Standard Whey Vanilla: per 31g scoop: 120 cal, 24g P. Per 100g: 387 cal.
('on_gold_standard_whey_vanilla', 'Optimum Nutrition Gold Standard Whey (Vanilla Ice Cream)', 387, 77.4, 12.9, 3.2,
 0.0, 3.2, 31, 31,
 'optimum_nutrition', ARRAY['on gold standard whey vanilla', 'optimum nutrition whey vanilla', 'gold standard whey vanilla ice cream', 'on whey vanilla'],
 'supplements', NULL, 1, '387 cal/100g. Per scoop (31g): 120 cal, 24g protein. Whey protein isolate/concentrate/hydrolyzed blend.', TRUE),

-- Dymatize ISO100 Fudge Brownie: per 32g scoop: 120 cal, 25g P. Per 100g: 375 cal.
('dymatize_iso100_fudge_brownie', 'Dymatize ISO100 Hydrolyzed Whey (Fudge Brownie)', 375, 78.1, 6.3, 1.6,
 0.0, 3.1, 32, 32,
 'dymatize', ARRAY['dymatize iso100 fudge brownie', 'iso100 fudge brownie', 'dymatize fudge brownie protein'],
 'supplements', NULL, 1, '375 cal/100g. Per scoop (32g): 120 cal, 25g protein, 2g carb, 0.5g fat. Hydrolyzed whey isolate.', TRUE),

-- Dymatize ISO100 Gourmet Chocolate: per 36g scoop: 120 cal, 25g P. Per 100g: 333 cal.
('dymatize_iso100_chocolate', 'Dymatize ISO100 Hydrolyzed Whey (Gourmet Chocolate)', 333, 69.4, 5.6, 1.4,
 0.0, 2.8, 36, 36,
 'dymatize', ARRAY['dymatize iso100 chocolate', 'iso100 gourmet chocolate', 'dymatize chocolate protein'],
 'supplements', NULL, 1, '333 cal/100g. Per scoop (36g): 120 cal, 25g protein. 5.5g BCAAs per serving. Fast absorbing.', TRUE),

-- Ghost Whey Chips Ahoy: per 36g scoop: 130 cal, 25g P. Per 100g: 361 cal.
('ghost_whey_chips_ahoy', 'GHOST Whey Protein (Chips Ahoy)', 361, 69.4, 11.1, 4.2,
 0.0, 5.6, 36, 36,
 'ghost', ARRAY['ghost whey chips ahoy', 'ghost protein chips ahoy', 'ghost whey chips ahoy flavor'],
 'supplements', NULL, 1, '361 cal/100g. Per scoop (36g): 130 cal, 25g protein. Licensed Chips Ahoy flavor collab.', TRUE),

-- Vega Sport Vanilla: per 41g scoop: 160 cal, 30g P. Per 100g: 390 cal.
('vega_sport_vanilla', 'Vega Sport Premium Protein (Vanilla)', 390, 73.2, 12.2, 7.3,
 2.4, 2.4, 41, 41,
 'vega', ARRAY['vega sport vanilla', 'vega sport protein vanilla', 'vega plant protein vanilla'],
 'supplements', NULL, 1, '390 cal/100g. Per scoop (41g): 160 cal, 30g protein. Plant-based (pea, sunflower, pumpkin seed). NSF certified.', TRUE),

-- Vital Proteins Collagen Peptides: per 20g (2 scoops): 70 cal, 18g P. Per 100g: 350 cal.
('vital_proteins_collagen', 'Vital Proteins Collagen Peptides (Unflavored)', 350, 90.0, 0.0, 0.0,
 0.0, 0.0, 20, 10,
 'vital_proteins', ARRAY['vital proteins collagen', 'vital proteins collagen peptides', 'collagen peptides vital proteins'],
 'supplements', NULL, 2, '350 cal/100g. Per 2-scoop serving (20g): 70 cal, 18g protein. Grass-fed bovine collagen. Dissolves in hot or cold.', TRUE),

-- Ensure Original Vanilla: per 237ml bottle: 220 cal, 9g P. Per 100g: 93 cal.
('ensure_original_vanilla', 'Ensure Original Nutrition Shake (Vanilla)', 93, 3.8, 13.5, 2.5,
 0.4, 6.3, 237, 237,
 'abbott', ARRAY['ensure original vanilla', 'ensure vanilla', 'ensure nutrition shake vanilla', 'ensure original'],
 'supplements', NULL, 1, '93 cal/100g. Per bottle (237ml): 220 cal, 9g protein, 32g carb, 6g fat. 26 vitamins & minerals. Complete nutrition.', TRUE),

-- Boost High Protein: per 237ml bottle: 240 cal, 20g P. Per 100g: 101 cal.
('boost_high_protein', 'Boost High Protein Nutritional Shake', 101, 8.4, 12.7, 2.5,
 0.4, 6.8, 237, 237,
 'nestle', ARRAY['boost high protein', 'boost protein shake', 'boost high protein vanilla'],
 'supplements', NULL, 1, '101 cal/100g. Per bottle (237ml): 240 cal, 20g protein. 27 vitamins & minerals. For active lifestyles.', TRUE),

-- Huel Black Edition Vanilla: per 90g serving: 400 cal, 40g P. Per 100g: 444 cal.
('huel_black_vanilla', 'Huel Black Edition (Vanilla)', 444, 44.4, 18.9, 18.9,
 5.6, 3.3, 90, 90,
 'huel', ARRAY['huel black vanilla', 'huel black edition vanilla', 'huel vanilla protein', 'huel meal replacement'],
 'supplements', NULL, 1, '444 cal/100g. Per serving (90g): 400 cal, 40g protein, 17g fat, 17g carb. Complete meal replacement. 27 vitamins & minerals.', TRUE)

,

-- ==========================================
-- O. INSTANT RAMEN (~8 items)
-- ==========================================

-- Maruchan Ramen Chicken: per 43g half-block serving: 190 cal. Per 100g: 442 cal. Full package is 85g.
('maruchan_ramen_chicken', 'Maruchan Ramen Noodle Soup (Chicken)', 442, 9.3, 60.5, 17.4,
 2.3, 2.3, 85, 85,
 'maruchan', ARRAY['maruchan ramen chicken', 'maruchan chicken ramen', 'maruchan chicken flavor ramen noodles'],
 'instant_noodles', NULL, 1, '442 cal/100g. Per package (85g dry): 376 cal (label says 190/half). The quintessential instant ramen.', TRUE),

-- Maruchan Ramen Beef: per 100g: 442 cal.
('maruchan_ramen_beef', 'Maruchan Ramen Noodle Soup (Beef)', 442, 9.3, 60.5, 17.4,
 2.3, 2.3, 85, 85,
 'maruchan', ARRAY['maruchan ramen beef', 'maruchan beef ramen', 'maruchan beef flavor ramen'],
 'instant_noodles', NULL, 1, '442 cal/100g. Per package (85g dry): 376 cal. Same noodle block, beef seasoning.', TRUE),

-- Nissin Cup Noodles Chicken: per 64g cup: 290 cal. Per 100g: 453 cal.
('nissin_cup_noodles_chicken', 'Nissin Cup Noodles (Chicken)', 453, 7.8, 57.8, 20.3,
 2.3, 3.1, 64, 64,
 'nissin', ARRAY['nissin cup noodles chicken', 'cup noodles chicken', 'cup o noodles chicken', 'nissin cup noodle chicken'],
 'instant_noodles', NULL, 1, '453 cal/100g. Per cup (64g dry): 290 cal. Just add hot water. Iconic foam cup.', TRUE),

-- Nissin Cup Noodles Beef: per 64g cup: 290 cal. Per 100g: 453 cal.
('nissin_cup_noodles_beef', 'Nissin Cup Noodles (Beef)', 453, 7.8, 57.8, 20.3,
 2.3, 3.1, 64, 64,
 'nissin', ARRAY['nissin cup noodles beef', 'cup noodles beef', 'cup o noodles beef'],
 'instant_noodles', NULL, 1, '453 cal/100g. Per cup (64g dry): 290 cal. Beef flavor. Just add hot water.', TRUE),

-- Nissin Top Ramen Chicken: per 43g half-block: 190 cal. Per 100g: 442 cal. Package 85g.
('nissin_top_ramen_chicken', 'Nissin Top Ramen (Chicken)', 442, 9.3, 60.5, 17.4,
 2.3, 2.3, 85, 85,
 'nissin', ARRAY['nissin top ramen chicken', 'top ramen chicken', 'top ramen chicken flavor'],
 'instant_noodles', NULL, 1, '442 cal/100g. Per package (85g dry): 376 cal. Maruchan''s main competitor.', TRUE),

-- Shin Ramyun (Nongshim): per 120g package: 520 cal. Per 100g: 433 cal.
('shin_ramyun', 'Nongshim Shin Ramyun', 433, 8.3, 58.3, 18.3,
 2.5, 3.3, 120, 120,
 'nongshim', ARRAY['shin ramyun', 'shin ramen', 'nongshim shin ramyun', 'shin ramyun noodles', 'korean spicy ramen'],
 'instant_noodles', NULL, 1, '433 cal/100g. Per package (120g dry): 520 cal. Korea''s #1 selling ramen. Spicy beef broth. Premium.', TRUE),

-- Nongshim Shin Black: per 130g package: 560 cal. Per 100g: 431 cal.
('shin_black', 'Nongshim Shin Ramyun Black', 431, 9.2, 56.2, 18.5,
 2.3, 3.1, 130, 130,
 'nongshim', ARRAY['shin black', 'shin ramyun black', 'nongshim shin black', 'shin black premium ramen'],
 'instant_noodles', NULL, 1, '431 cal/100g. Per package (130g dry): 560 cal. Premium Shin with garlic beef bone broth.', TRUE),

-- Samyang Buldak 2x Spicy: per 140g package: 550 cal. Per 100g: 393 cal.
('samyang_buldak_2x', 'Samyang Buldak 2x Spicy Hot Chicken Ramen', 393, 9.3, 60.7, 12.1,
 1.4, 5.0, 140, 140,
 'samyang', ARRAY['samyang buldak 2x spicy', 'buldak 2x spicy', 'samyang 2x spicy', 'fire noodles 2x', 'korean fire noodles', 'buldak ramen'],
 'instant_noodles', NULL, 1, '393 cal/100g. Per package (140g dry): 550 cal. Extremely spicy stir-fried noodles. TikTok viral challenge.', TRUE),

-- ==========================================
-- P. FROZEN MEALS (~8 items)
-- ==========================================

-- Trader Joe's Mandarin Orange Chicken: per 140g serving: 320 cal. Per 100g: 229 cal.
('tj_mandarin_orange_chicken', 'Trader Joe''s Mandarin Orange Chicken (Frozen)', 229, 15.0, 17.1, 10.7,
 0.7, 10.0, 140, 140,
 'trader_joes', ARRAY['trader joes mandarin orange chicken', 'trader joe''s orange chicken', 'tj orange chicken frozen'],
 'frozen_meals', NULL, 1, '229 cal/100g. Per serving (140g/1 cup): 320 cal, 15g fat, 24g carb, 21g protein. TJ''s #1 frozen product.', TRUE),

-- Trader Joe's Cauliflower Gnocchi: per 140g serving: 140 cal. Per 100g: 100 cal.
('tj_cauliflower_gnocchi', 'Trader Joe''s Cauliflower Gnocchi (Frozen)', 100, 1.4, 15.7, 2.1,
 4.3, 1.4, 140, 140,
 'trader_joes', ARRAY['trader joes cauliflower gnocchi', 'trader joe''s cauliflower gnocchi', 'tj cauliflower gnocchi'],
 'frozen_meals', NULL, 1, '100 cal/100g. Per serving (140g/1 cup): 140 cal, 3g fat, 22g carb, 2g protein. Low-cal pasta alternative.', TRUE),

-- Trader Joe's Chicken Tikka Masala: per 241g package: 300 cal. Per 100g: 124 cal.
('tj_chicken_tikka_masala', 'Trader Joe''s Chicken Tikka Masala (Frozen)', 124, 6.6, 7.1, 7.9,
 0.8, 2.1, 241, 241,
 'trader_joes', ARRAY['trader joes chicken tikka masala', 'trader joe''s tikka masala', 'tj tikka masala frozen'],
 'frozen_meals', NULL, 1, '124 cal/100g. Per package (241g): 300 cal. Indian-inspired chicken in tomato cream sauce with basmati rice.', TRUE),

-- Trader Joe's Butter Chicken: per 241g package: 310 cal. Per 100g: 129 cal.
('tj_butter_chicken', 'Trader Joe''s Butter Chicken (Frozen)', 129, 6.2, 8.3, 7.5,
 0.8, 2.5, 241, 241,
 'trader_joes', ARRAY['trader joes butter chicken', 'trader joe''s butter chicken', 'tj butter chicken frozen'],
 'frozen_meals', NULL, 1, '129 cal/100g. Per package (241g): 310 cal. Chicken in rich buttery tomato sauce with basmati rice.', TRUE),

-- Eggo Waffles Homestyle: per 70g (2 waffles): 180 cal. Per 100g: 257 cal.
('eggo_waffles_homestyle', 'Eggo Homestyle Waffles', 257, 5.7, 40.0, 8.6,
 1.4, 5.7, 70, 35,
 'kelloggs', ARRAY['eggo waffles', 'eggo homestyle waffles', 'eggo homestyle', 'eggo waffles homestyle'],
 'frozen_meals', NULL, 2, '257 cal/100g. Per waffle (35g): 90 cal. Per 2-waffle serving (70g): 180 cal. Leggo my Eggo.', TRUE),

-- Eggo Waffles Blueberry: per 70g (2 waffles): 180 cal. Per 100g: 257 cal.
('eggo_waffles_blueberry', 'Eggo Blueberry Waffles', 257, 5.7, 41.4, 7.1,
 1.4, 8.6, 70, 35,
 'kelloggs', ARRAY['eggo blueberry waffles', 'eggo blueberry', 'blueberry eggo waffles'],
 'frozen_meals', NULL, 2, '257 cal/100g. Per waffle (35g): 90 cal. Per 2-waffle serving (70g): 180 cal. With real blueberries.', TRUE),

-- Bibigo Frozen Dumplings (chicken & vegetable): per 128g (4 dumplings): 230 cal. Per 100g: 180 cal.
('bibigo_frozen_dumplings', 'Bibigo Chicken & Vegetable Steamed Dumplings', 180, 7.8, 18.0, 8.6,
 1.6, 2.3, 128, 32,
 'bibigo', ARRAY['bibigo dumplings', 'bibigo frozen dumplings', 'bibigo steamed dumplings', 'bibigo chicken dumplings'],
 'frozen_meals', NULL, 4, '180 cal/100g. Per dumpling (32g): 58 cal. Per 4-dumpling serving (128g): 230 cal. Korean-style.', TRUE),

-- Ling Ling Potstickers (Chicken & Vegetable): per 140g (5 potstickers + sauce): 260 cal. Per 100g: 186 cal.
('ling_ling_potstickers', 'Ling Ling Chicken & Vegetable Potstickers', 186, 7.1, 22.9, 5.7,
 1.4, 2.1, 140, 24,
 'ling_ling', ARRAY['ling ling potstickers', 'ling ling dumplings', 'ling ling chicken potstickers'],
 'frozen_meals', NULL, 5, '186 cal/100g. Per 5-potsticker serving with sauce (140g): 260 cal. Pan-fry or steam. Includes dipping sauce.', TRUE)

ON CONFLICT (food_name_normalized)
DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_serving_g = EXCLUDED.default_serving_g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
