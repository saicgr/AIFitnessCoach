-- 1642_overrides_grocery_brands.sql
-- 365 by Whole Foods (~500+ stores) — organic staples, dairy, pantry.
-- Kroger / Simple Truth (~2,700+ stores) — organic, deli, dairy.
-- H-E-B / Central Market (~400+ stores, TX) — Meal Simple, bakery, deli.
-- Publix (~1,300+ stores, SE USA) — Pub Subs, deli, bakery, GreenWise.
-- Wegmans (~110+ stores, NE USA) — sushi, subs, dairy, pasta sauce.
-- Sources: official store nutrition labels, USDA FoodData Central, FatSecret, Nutritionix.
-- All values per 100g. default_serving_g = typical serving weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- 365 BY WHOLE FOODS — PROTEINS & DAIRY
-- ══════════════════════════════════════════

-- 365 Organic Chicken Breast: ~120 cal per 100g, serving 112g (4oz)
('wf365_organic_chicken_breast', '365 by Whole Foods Organic Chicken Breast', 120.0, 23.0, 0.0, 2.6,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['365 organic chicken breast', 'whole foods 365 chicken breast', '365 by whole foods chicken', 'whole foods organic chicken'],
 'protein', '365 by Whole Foods', 1, '120 cal per 100g (134 cal per 4oz/112g serving). Boneless skinless organic chicken breast. USDA Organic certified.', TRUE),

-- 365 Greek Yogurt: ~97 cal per 100g, serving 170g (6oz)
('wf365_greek_yogurt', '365 by Whole Foods Greek Yogurt', 97.0, 10.0, 13.0, 0.7,
 0.0, 7.0, 170, NULL,
 'website', ARRAY['365 greek yogurt', 'whole foods 365 greek yogurt', '365 by whole foods yogurt', 'whole foods plain greek yogurt'],
 'dairy', '365 by Whole Foods', 1, '97 cal per 100g (165 cal per 170g container). Plain nonfat Greek yogurt. High protein.', TRUE),

-- 365 Organic Whole Milk: ~61 cal per 100g, serving 240g (1 cup)
('wf365_organic_whole_milk', '365 by Whole Foods Organic Whole Milk', 61.0, 3.2, 4.8, 3.3,
 0.0, 4.8, 240, NULL,
 'website', ARRAY['365 organic whole milk', 'whole foods 365 whole milk', '365 by whole foods milk', 'whole foods organic milk'],
 'dairy', '365 by Whole Foods', 1, '61 cal per 100g (146 cal per 1 cup/240g). USDA Organic whole milk.', TRUE),

-- 365 Organic Eggs: ~143 cal per 100g, per piece 50g
('wf365_organic_eggs', '365 by Whole Foods Organic Eggs', 143.0, 13.0, 0.7, 9.5,
 0.0, 0.7, NULL, 50,
 'website', ARRAY['365 organic eggs', 'whole foods 365 eggs', '365 by whole foods organic eggs', 'whole foods cage free organic eggs'],
 'protein', '365 by Whole Foods', 1, '143 cal per 100g (72 cal per large egg/50g). USDA Organic, cage-free.', TRUE),

-- ══════════════════════════════════════════
-- 365 BY WHOLE FOODS — PANTRY
-- ══════════════════════════════════════════

-- 365 Organic Pasta (dry): ~350 cal per 100g, serving 56g (2oz)
('wf365_organic_pasta', '365 by Whole Foods Organic Pasta', 350.0, 13.0, 71.0, 1.5,
 2.5, 2.0, 56, NULL,
 'website', ARRAY['365 organic pasta', 'whole foods 365 pasta', '365 by whole foods spaghetti', 'whole foods organic penne'],
 'grain', '365 by Whole Foods', 1, '350 cal per 100g dry (196 cal per 56g/2oz dry serving). Organic durum wheat semolina.', TRUE),

-- 365 Marinara Sauce: ~50 cal per 100g, serving 125g (1/2 cup)
('wf365_marinara_sauce', '365 by Whole Foods Marinara Sauce', 50.0, 1.5, 8.0, 1.5,
 1.5, 5.0, 125, NULL,
 'website', ARRAY['365 marinara sauce', 'whole foods 365 marinara', '365 by whole foods pasta sauce', 'whole foods organic marinara'],
 'sauce', '365 by Whole Foods', 1, '50 cal per 100g (63 cal per 125g/1/2 cup serving). Classic marinara with tomatoes, olive oil, garlic.', TRUE),

-- 365 Peanut Butter: ~588 cal per 100g, serving 32g (2 tbsp)
('wf365_peanut_butter', '365 by Whole Foods Peanut Butter', 588.0, 25.0, 20.0, 50.0,
 6.0, 6.0, 32, NULL,
 'website', ARRAY['365 peanut butter', 'whole foods 365 peanut butter', '365 by whole foods pb', 'whole foods creamy peanut butter'],
 'spread', '365 by Whole Foods', 1, '588 cal per 100g (188 cal per 32g/2 tbsp serving). Dry roasted peanuts, salt only. No added sugar/oil.', TRUE),

-- 365 Organic Brown Rice (dry): ~362 cal per 100g, serving 45g (1/4 cup dry)
('wf365_organic_brown_rice', '365 by Whole Foods Organic Brown Rice', 362.0, 7.5, 76.0, 2.7,
 3.5, 0.7, 45, NULL,
 'website', ARRAY['365 organic brown rice', 'whole foods 365 brown rice', '365 by whole foods rice', 'whole foods organic long grain brown rice'],
 'grain', '365 by Whole Foods', 1, '362 cal per 100g dry (163 cal per 45g/1/4 cup dry). Organic long grain brown rice.', TRUE),

-- 365 Organic Oats: ~379 cal per 100g, serving 40g (1/2 cup dry)
('wf365_organic_oats', '365 by Whole Foods Organic Oats', 379.0, 13.0, 68.0, 7.0,
 10.0, 1.0, 40, NULL,
 'website', ARRAY['365 organic oats', 'whole foods 365 oats', '365 by whole foods oatmeal', 'whole foods organic rolled oats'],
 'grain', '365 by Whole Foods', 1, '379 cal per 100g dry (152 cal per 40g/1/2 cup dry). Organic rolled oats. High fiber.', TRUE),

-- 365 Almond Milk (unsweetened): ~15 cal per 100g, serving 240g (1 cup)
('wf365_almond_milk_unsweetened', '365 by Whole Foods Unsweetened Almond Milk', 15.0, 0.5, 0.3, 1.2,
 0.4, 0.0, 240, NULL,
 'website', ARRAY['365 almond milk unsweetened', 'whole foods 365 almond milk', '365 by whole foods almond milk', 'whole foods unsweetened almond milk'],
 'dairy_alt', '365 by Whole Foods', 1, '15 cal per 100g (36 cal per 1 cup/240g). Unsweetened, low calorie dairy alternative.', TRUE),

-- ══════════════════════════════════════════
-- KROGER / SIMPLE TRUTH — PROTEINS
-- ══════════════════════════════════════════

-- Kroger Simple Truth Organic Chicken Breast: ~120 cal per 100g, serving 112g
('kroger_simple_truth_chicken', 'Kroger Simple Truth Organic Chicken Breast', 120.0, 23.0, 0.0, 2.6,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['kroger simple truth chicken breast', 'simple truth organic chicken', 'kroger organic chicken breast', 'simple truth chicken'],
 'protein', 'Kroger', 1, '120 cal per 100g (134 cal per 4oz/112g serving). Simple Truth Organic boneless skinless chicken breast.', TRUE),

-- Kroger Deli Rotisserie Chicken: ~190 cal per 100g, serving 112g
('kroger_rotisserie_chicken', 'Kroger Deli Rotisserie Chicken', 190.0, 25.0, 0.0, 10.0,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['kroger rotisserie chicken', 'kroger deli chicken', 'kroger whole rotisserie chicken', 'kroger roasted chicken'],
 'protein', 'Kroger', 1, '190 cal per 100g (213 cal per 4oz/112g serving). Fully cooked seasoned rotisserie chicken from deli.', TRUE),

-- Kroger Simple Truth Turkey Breast (deli): ~100 cal per 100g, serving 56g (2oz)
('kroger_simple_truth_turkey_deli', 'Kroger Simple Truth Turkey Breast (Deli)', 100.0, 18.0, 2.0, 1.5,
 0.0, 1.0, 56, NULL,
 'website', ARRAY['kroger simple truth turkey breast', 'simple truth deli turkey', 'kroger turkey breast deli', 'simple truth oven roasted turkey'],
 'deli', 'Kroger', 1, '100 cal per 100g (56 cal per 2oz/56g serving). Oven roasted turkey breast, no antibiotics.', TRUE),

-- ══════════════════════════════════════════
-- KROGER / SIMPLE TRUTH — DAIRY
-- ══════════════════════════════════════════

-- Kroger Simple Truth Greek Yogurt: ~97 cal per 100g, serving 170g
('kroger_simple_truth_greek_yogurt', 'Kroger Simple Truth Greek Yogurt', 97.0, 10.0, 13.0, 0.7,
 0.0, 7.0, 170, NULL,
 'website', ARRAY['kroger simple truth greek yogurt', 'simple truth greek yogurt', 'kroger greek yogurt', 'simple truth plain greek'],
 'dairy', 'Kroger', 1, '97 cal per 100g (165 cal per 170g container). Plain nonfat Greek yogurt.', TRUE),

-- Kroger Simple Truth Organic Eggs: ~143 cal per 100g, per piece 50g
('kroger_simple_truth_eggs', 'Kroger Simple Truth Organic Eggs', 143.0, 13.0, 0.7, 9.5,
 0.0, 0.7, NULL, 50,
 'website', ARRAY['kroger simple truth eggs', 'simple truth organic eggs', 'kroger organic eggs', 'simple truth cage free eggs'],
 'protein', 'Kroger', 1, '143 cal per 100g (72 cal per large egg/50g). USDA Organic, cage-free.', TRUE),

-- Kroger Cottage Cheese (4% milkfat): ~98 cal per 100g, serving 113g (1/2 cup)
('kroger_cottage_cheese', 'Kroger Cottage Cheese (4%)', 98.0, 11.0, 3.5, 4.3,
 0.0, 3.0, 113, NULL,
 'website', ARRAY['kroger cottage cheese', 'kroger small curd cottage cheese', 'kroger 4 percent cottage cheese', 'kroger full fat cottage cheese'],
 'dairy', 'Kroger', 1, '98 cal per 100g (111 cal per 113g/1/2 cup serving). Small curd, 4% milkfat. Good protein source.', TRUE),

-- Kroger String Cheese: ~280 cal per 100g, per piece 28g
('kroger_string_cheese', 'Kroger String Cheese', 280.0, 25.0, 1.8, 19.6,
 0.0, 0.0, NULL, 28,
 'website', ARRAY['kroger string cheese', 'kroger mozzarella string cheese', 'kroger cheese stick', 'kroger part skim mozzarella string'],
 'dairy', 'Kroger', 1, '280 cal per 100g (78 cal per stick/28g). Part-skim mozzarella. Convenient high-protein snack.', TRUE),

-- Kroger Simple Truth Almond Milk: ~15 cal per 100g, serving 240g
('kroger_simple_truth_almond_milk', 'Kroger Simple Truth Almond Milk', 15.0, 0.5, 0.3, 1.2,
 0.4, 0.0, 240, NULL,
 'website', ARRAY['kroger simple truth almond milk', 'simple truth almond milk unsweetened', 'kroger almond milk', 'simple truth unsweetened almond'],
 'dairy_alt', 'Kroger', 1, '15 cal per 100g (36 cal per 1 cup/240g). Unsweetened organic almond milk.', TRUE),

-- ══════════════════════════════════════════
-- H-E-B — MEAL SIMPLE & PREPARED
-- ══════════════════════════════════════════

-- H-E-B Meal Simple Chicken Fajitas: ~135 cal per 100g, serving 280g — verified via FatSecret/HEB.com
('heb_meal_simple_chicken_fajitas', 'H-E-B Meal Simple Chicken Fajitas', 135.0, 15.0, 9.0, 4.5,
 1.5, 1.5, 280, NULL,
 'website', ARRAY['heb meal simple chicken fajitas', 'h-e-b meal simple fajitas', 'heb chicken fajita bowl', 'heb meal simple fajita chicken'],
 'entree', 'H-E-B', 1, '135 cal per 100g (378 cal per 280g serving). Ready-to-heat chicken fajitas with peppers and onions.', TRUE),

-- H-E-B Meal Simple Salmon: ~150 cal per 100g, serving 250g
('heb_meal_simple_salmon', 'H-E-B Meal Simple Salmon', 150.0, 18.0, 5.0, 6.5,
 1.0, 1.0, 250, NULL,
 'website', ARRAY['heb meal simple salmon', 'h-e-b meal simple salmon', 'heb salmon dinner', 'heb meal simple atlantic salmon'],
 'entree', 'H-E-B', 1, '150 cal per 100g (375 cal per 250g serving). Ready-to-heat seasoned Atlantic salmon with sides.', TRUE),

-- H-E-B Central Market Organic Chicken: ~120 cal per 100g, serving 112g
('heb_central_market_chicken', 'H-E-B Central Market Organic Chicken Breast', 120.0, 23.0, 0.0, 2.6,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['heb central market organic chicken', 'h-e-b central market chicken breast', 'central market organic chicken', 'heb organic chicken breast'],
 'protein', 'H-E-B', 1, '120 cal per 100g (134 cal per 4oz/112g serving). Central Market brand organic chicken breast.', TRUE),

-- H-E-B 1905 Sausage (Original): ~290 cal per 100g, per piece 76g
('heb_1905_sausage', 'H-E-B 1905 Sausage (Original)', 290.0, 14.0, 3.0, 25.0,
 0.0, 1.5, NULL, 76,
 'website', ARRAY['heb 1905 sausage', 'h-e-b 1905 original sausage', 'heb sausage original', 'heb 1905 pork sausage'],
 'protein', 'H-E-B', 1, '290 cal per 100g (220 cal per link/76g). Premium pork sausage, H-E-B signature brand since 1905.', TRUE),

-- H-E-B Bakery Flour Tortillas: ~300 cal per 100g, per piece 45g
('heb_bakery_flour_tortillas', 'H-E-B Bakery Flour Tortillas', 300.0, 7.0, 46.0, 9.0,
 2.0, 2.0, NULL, 45,
 'website', ARRAY['heb bakery flour tortillas', 'h-e-b flour tortillas', 'heb tortillas', 'heb bakery tortilla'],
 'bread', 'H-E-B', 1, '300 cal per 100g (135 cal per tortilla/45g). Fresh-baked in-store flour tortillas.', TRUE),

-- H-E-B That Green Sauce: ~40 cal per 100g, serving 30g (2 tbsp)
('heb_that_green_sauce', 'H-E-B That Green Sauce', 40.0, 0.5, 3.0, 3.0,
 0.5, 1.0, 30, NULL,
 'website', ARRAY['heb that green sauce', 'h-e-b that green sauce', 'heb green sauce', 'heb salsa verde creamy'],
 'sauce', 'H-E-B', 1, '40 cal per 100g (12 cal per 30g/2 tbsp serving). Creamy jalapeño-cilantro sauce. Cult-favorite condiment.', TRUE),

-- H-E-B Creamy Creations Ice Cream: ~230 cal per 100g, serving 66g (1/3 cup)
('heb_creamy_creations_ice_cream', 'H-E-B Creamy Creations Ice Cream', 230.0, 3.5, 26.0, 12.5,
 0.5, 22.0, 66, NULL,
 'website', ARRAY['heb creamy creations ice cream', 'h-e-b creamy creations', 'heb ice cream', 'heb creamy creations vanilla'],
 'dessert', 'H-E-B', 1, '230 cal per 100g (152 cal per 66g/1/3 cup serving). Premium H-E-B store brand ice cream.', TRUE),

-- H-E-B Thin Sliced Turkey: ~90 cal per 100g, serving 56g (2oz)
('heb_thin_sliced_turkey', 'H-E-B Thin Sliced Turkey Breast', 90.0, 17.0, 2.0, 1.0,
 0.0, 1.5, 56, NULL,
 'website', ARRAY['heb thin sliced turkey', 'h-e-b deli turkey breast', 'heb turkey breast deli', 'heb oven roasted turkey sliced'],
 'deli', 'H-E-B', 1, '90 cal per 100g (50 cal per 2oz/56g serving). Thin-sliced oven roasted turkey breast.', TRUE),

-- ══════════════════════════════════════════
-- PUBLIX — PUB SUBS
-- ══════════════════════════════════════════

-- Publix Pub Sub Turkey (whole): ~180 cal per 100g, serving 350g — verified via FatSecret/Nutritionix
('publix_pub_sub_turkey', 'Publix Pub Sub Turkey (Whole)', 180.0, 10.3, 20.0, 5.7,
 1.1, 2.3, 350, 350,
 'website', ARRAY['publix pub sub turkey', 'publix turkey sub', 'pub sub turkey whole', 'publix deli turkey sub'],
 'sandwich', 'Publix', 1, '180 cal per 100g (630 cal per whole sub/350g). Turkey breast with lettuce, tomato, onion on white sub roll. Add mayo/cheese increases calories.', TRUE),

-- Publix Pub Sub Italian (whole): ~250 cal per 100g, serving 370g
('publix_pub_sub_italian', 'Publix Pub Sub Italian (Whole)', 250.0, 12.0, 22.0, 12.5,
 1.0, 2.0, 370, 370,
 'website', ARRAY['publix pub sub italian', 'publix italian sub', 'pub sub italian whole', 'publix deli italian sub'],
 'sandwich', 'Publix', 1, '250 cal per 100g (925 cal per whole sub/370g). Ham, salami, capicola, provolone with lettuce, tomato, oil and vinegar on sub roll.', TRUE),

-- Publix Pub Sub Chicken Tender (whole): ~240 cal per 100g, serving 350g
('publix_pub_sub_chicken_tender', 'Publix Pub Sub Chicken Tender (Whole)', 240.0, 13.0, 22.0, 10.5,
 1.0, 2.5, 350, 350,
 'website', ARRAY['publix pub sub chicken tender', 'publix chicken tender sub', 'pub sub chicken tender whole', 'publix tenders sub'],
 'sandwich', 'Publix', 1, '240 cal per 100g (840 cal per whole sub/350g). Hand-breaded chicken tenders on sub roll. Fan-favorite menu item.', TRUE),

-- ══════════════════════════════════════════
-- PUBLIX — DELI & BAKERY
-- ══════════════════════════════════════════

-- Publix Deli Rotisserie Chicken: ~190 cal per 100g, serving 112g
('publix_rotisserie_chicken', 'Publix Deli Rotisserie Chicken', 190.0, 25.0, 0.0, 10.0,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['publix rotisserie chicken', 'publix deli rotisserie chicken', 'publix whole roasted chicken', 'publix hot deli chicken'],
 'protein', 'Publix', 1, '190 cal per 100g (213 cal per 4oz/112g serving). Seasoned rotisserie chicken from deli.', TRUE),

-- Publix Bakery Birthday Cake (slice): ~350 cal per 100g, per piece 100g
('publix_bakery_birthday_cake', 'Publix Bakery Birthday Cake (Slice)', 350.0, 3.0, 50.0, 16.0,
 0.0, 38.0, NULL, 100,
 'website', ARRAY['publix bakery birthday cake', 'publix birthday cake slice', 'publix bakery cake', 'publix decorated cake slice'],
 'dessert', 'Publix', 1, '350 cal per slice (100g). Classic Publix bakery cake with buttercream frosting. High sugar.', TRUE),

-- ══════════════════════════════════════════
-- PUBLIX — GREENWISE
-- ══════════════════════════════════════════

-- Publix GreenWise Organic Chicken: ~120 cal per 100g, serving 112g
('publix_greenwise_chicken', 'Publix GreenWise Organic Chicken Breast', 120.0, 23.0, 0.0, 2.6,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['publix greenwise organic chicken', 'publix greenwise chicken breast', 'greenwise organic chicken', 'publix organic chicken breast'],
 'protein', 'Publix', 1, '120 cal per 100g (134 cal per 4oz/112g serving). GreenWise brand organic chicken breast.', TRUE),

-- Publix GreenWise Greek Yogurt: ~97 cal per 100g, serving 170g
('publix_greenwise_greek_yogurt', 'Publix GreenWise Greek Yogurt', 97.0, 10.0, 13.0, 0.7,
 0.0, 7.0, 170, NULL,
 'website', ARRAY['publix greenwise greek yogurt', 'publix greenwise yogurt', 'greenwise greek yogurt', 'publix organic greek yogurt'],
 'dairy', 'Publix', 1, '97 cal per 100g (165 cal per 170g container). Plain nonfat Greek yogurt, GreenWise brand.', TRUE),

-- ══════════════════════════════════════════
-- WEGMANS — PREPARED FOODS
-- ══════════════════════════════════════════

-- Wegmans Organic Chicken Breast: ~120 cal per 100g, serving 112g
('wegmans_organic_chicken', 'Wegmans Organic Chicken Breast', 120.0, 23.0, 0.0, 2.6,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['wegmans organic chicken breast', 'wegmans chicken breast', 'wegmans organic boneless chicken', 'wegmans poultry chicken breast'],
 'protein', 'Wegmans', 1, '120 cal per 100g (134 cal per 4oz/112g serving). Organic boneless skinless chicken breast.', TRUE),

-- Wegmans Italian Classics Pasta Sauce: ~60 cal per 100g, serving 125g (1/2 cup)
('wegmans_italian_classics_pasta_sauce', 'Wegmans Italian Classics Pasta Sauce', 60.0, 2.0, 9.0, 2.0,
 1.5, 5.5, 125, NULL,
 'website', ARRAY['wegmans italian classics pasta sauce', 'wegmans marinara', 'wegmans pasta sauce', 'wegmans italian classics marinara'],
 'sauce', 'Wegmans', 1, '60 cal per 100g (75 cal per 125g/1/2 cup serving). Premium Italian-style pasta sauce.', TRUE),

-- Wegmans Sushi California Roll: ~150 cal per 100g, serving 180g (6pc) — verified via FatSecret
('wegmans_sushi_california_roll', 'Wegmans Sushi California Roll (6pc)', 150.0, 4.0, 27.0, 2.5,
 1.0, 3.5, 180, NULL,
 'website', ARRAY['wegmans california roll', 'wegmans sushi california roll', 'wegmans california roll 6 piece', 'wegmans sushi crab california'],
 'sushi', 'Wegmans', 1, '150 cal per 100g (270 cal per 6-piece pack/180g). Imitation crab, avocado, cucumber with sushi rice.', TRUE),

-- Wegmans Sushi Spicy Tuna Roll: ~160 cal per 100g, serving 180g (6pc)
('wegmans_sushi_spicy_tuna_roll', 'Wegmans Sushi Spicy Tuna Roll (6pc)', 160.0, 7.0, 24.0, 4.0,
 0.8, 3.0, 180, NULL,
 'website', ARRAY['wegmans spicy tuna roll', 'wegmans sushi spicy tuna roll', 'wegmans spicy tuna roll 6 piece', 'wegmans sushi tuna roll'],
 'sushi', 'Wegmans', 1, '160 cal per 100g (288 cal per 6-piece pack/180g). Spicy tuna, cucumber, and sriracha mayo with sushi rice.', TRUE),

-- Wegmans Danny's Favorites Sub: ~230 cal per 100g, serving 330g
('wegmans_dannys_favorites_sub', 'Wegmans Danny''s Favorites Sub', 230.0, 13.0, 20.0, 11.0,
 1.0, 2.5, 330, 330,
 'website', ARRAY['wegmans dannys favorites sub', 'wegmans danny sub', 'wegmans deli sub dannys favorite', 'wegmans signature sub'],
 'sandwich', 'Wegmans', 1, '230 cal per 100g (759 cal per sub/330g). Signature deli sub with premium meats and cheese.', TRUE),

-- ══════════════════════════════════════════
-- WEGMANS — DAIRY
-- ══════════════════════════════════════════

-- Wegmans Greek Yogurt: ~97 cal per 100g, serving 170g
('wegmans_greek_yogurt', 'Wegmans Greek Yogurt', 97.0, 10.0, 13.0, 0.7,
 0.0, 7.0, 170, NULL,
 'website', ARRAY['wegmans greek yogurt', 'wegmans plain greek yogurt', 'wegmans nonfat greek yogurt', 'wegmans yogurt plain greek'],
 'dairy', 'Wegmans', 1, '97 cal per 100g (165 cal per 170g container). Plain nonfat Greek yogurt.', TRUE),

-- Wegmans Organic Whole Milk: ~61 cal per 100g, serving 240g (1 cup)
('wegmans_organic_whole_milk', 'Wegmans Organic Whole Milk', 61.0, 3.2, 4.8, 3.3,
 0.0, 4.8, 240, NULL,
 'website', ARRAY['wegmans organic whole milk', 'wegmans whole milk', 'wegmans organic milk', 'wegmans milk whole organic'],
 'dairy', 'Wegmans', 1, '61 cal per 100g (146 cal per 1 cup/240g). USDA Organic whole milk.', TRUE)

ON CONFLICT (food_name_normalized) DO UPDATE SET
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
