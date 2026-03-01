-- 338_pizza_variants.sql
-- Generic pizza variant items covering all major pizza styles:
-- NY Style, Chicago Deep Dish, Detroit Style, Neapolitan, Sicilian,
-- Pan Pizza, Stuffed Pizza, Flatbread Pizza, Calzone, Stromboli, and misc.
-- Sources: USDA FoodData Central, nutritionix.com, calorieking.com, fatsecret.com,
--          nutritionvalue.org, snapcalorie.com, myfooddata.com, eatthismuch.com
-- All values per 100g, computed from per-serving or per-slice label data.

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
-- NEW YORK STYLE THIN CRUST (~180g per slice)
-- ==========================================

-- NY Style Cheese: USDA 173292 cheese pizza per 100g: 266 cal, 11.4P, 31.0C, 10.9F
('ny_style_cheese_pizza', 'New York Style Cheese Pizza (Slice)', 266, 11.4, 31.0, 10.9,
 1.8, 3.6, 180, 180,
 'pizza_generic', ARRAY['ny cheese pizza', 'new york cheese pizza', 'ny style cheese slice', 'plain cheese pizza slice', 'cheese pizza ny'],
 'pizza', NULL, 1, '266 cal/100g. Per 180g slice: ~479 cal. Classic NY thin crust cheese.', TRUE,
 598, 22, 4.5, 0.2, 172, 188, 2.5, 60, 1.5, 3, 18, 1.4, 165, 18.0, 0.08),

-- NY Style Pepperoni: USDA 173295 pepperoni pizza per 100g: 275 cal, 12.0P, 28.7C, 12.5F
('ny_style_pepperoni_pizza', 'New York Style Pepperoni Pizza (Slice)', 275, 12.0, 28.7, 12.5,
 1.6, 3.2, 180, 180,
 'pizza_generic', ARRAY['ny pepperoni pizza', 'new york pepperoni pizza', 'pepperoni pizza slice', 'ny style pepperoni slice'],
 'pizza', NULL, 1, '275 cal/100g. Per 180g slice: ~495 cal. Classic NY thin crust with pepperoni.', TRUE,
 680, 28, 5.2, 0.2, 180, 170, 2.6, 55, 1.2, 3, 17, 1.6, 170, 20.0, 0.07),

-- NY Style Meat Lovers: Higher fat/protein from multiple meats
('ny_style_meat_lovers_pizza', 'New York Style Meat Lovers Pizza (Slice)', 295, 13.5, 27.0, 14.8,
 1.4, 3.0, 180, 180,
 'pizza_generic', ARRAY['ny meat lovers pizza', 'meat lovers pizza slice', 'new york meat pizza', 'all meat pizza ny', 'meat feast pizza'],
 'pizza', NULL, 1, '295 cal/100g. Per 180g slice: ~531 cal. Pepperoni, sausage, ham, bacon.', TRUE,
 750, 38, 6.2, 0.3, 195, 160, 2.8, 50, 1.0, 3, 18, 2.0, 175, 22.0, 0.06),

-- NY Style Veggie
('ny_style_veggie_pizza', 'New York Style Veggie Pizza (Slice)', 240, 9.8, 30.5, 9.2,
 2.4, 4.0, 180, 180,
 'pizza_generic', ARRAY['ny veggie pizza', 'vegetable pizza ny', 'new york veggie pizza', 'garden veggie pizza slice', 'veggie pizza slice'],
 'pizza', NULL, 1, '240 cal/100g. Per 180g slice: ~432 cal. Peppers, onions, mushrooms, olives.', TRUE,
 520, 16, 3.8, 0.1, 210, 165, 2.2, 75, 5.0, 3, 20, 1.2, 148, 16.0, 0.06),

-- NY Style White Pizza (no tomato sauce, ricotta and mozzarella)
('ny_style_white_pizza', 'New York Style White Pizza (Slice)', 280, 11.0, 28.0, 13.5,
 1.2, 2.0, 180, 180,
 'pizza_generic', ARRAY['ny white pizza', 'white pizza slice', 'new york white pizza', 'ricotta pizza ny', 'bianca pizza'],
 'pizza', NULL, 1, '280 cal/100g. Per 180g slice: ~504 cal. Ricotta, mozzarella, garlic, olive oil.', TRUE,
 550, 30, 6.5, 0.2, 140, 200, 1.8, 65, 0.5, 4, 16, 1.5, 175, 16.0, 0.08),

-- NY Style Sausage
('ny_style_sausage_pizza', 'New York Style Sausage Pizza (Slice)', 278, 12.2, 28.5, 12.8,
 1.6, 3.2, 180, 180,
 'pizza_generic', ARRAY['ny sausage pizza', 'sausage pizza slice', 'new york sausage pizza', 'italian sausage pizza ny'],
 'pizza', NULL, 1, '278 cal/100g. Per 180g slice: ~500 cal. Italian sausage crumbles.', TRUE,
 660, 30, 5.0, 0.2, 185, 165, 2.5, 52, 1.2, 3, 17, 1.6, 168, 19.0, 0.06),

-- NY Style Mushroom
('ny_style_mushroom_pizza', 'New York Style Mushroom Pizza (Slice)', 248, 10.5, 30.0, 9.5,
 2.0, 3.4, 180, 180,
 'pizza_generic', ARRAY['ny mushroom pizza', 'mushroom pizza slice', 'new york mushroom pizza', 'fungi pizza'],
 'pizza', NULL, 1, '248 cal/100g. Per 180g slice: ~446 cal. Fresh mushrooms on cheese pizza.', TRUE,
 560, 20, 4.0, 0.1, 200, 175, 2.3, 58, 1.5, 3, 19, 1.3, 158, 17.5, 0.07),

-- NY Style Buffalo Chicken
('ny_style_buffalo_chicken_pizza', 'New York Style Buffalo Chicken Pizza (Slice)', 272, 13.0, 27.5, 12.0,
 1.2, 2.5, 180, 180,
 'pizza_generic', ARRAY['ny buffalo chicken pizza', 'buffalo chicken pizza slice', 'new york buffalo chicken pizza', 'hot buffalo pizza'],
 'pizza', NULL, 1, '272 cal/100g. Per 180g slice: ~490 cal. Grilled chicken, buffalo sauce, blue cheese.', TRUE,
 720, 32, 5.0, 0.2, 175, 170, 2.0, 55, 1.0, 3, 18, 1.5, 170, 19.0, 0.06),

-- NY Style Hawaiian
('ny_style_hawaiian_pizza', 'New York Style Hawaiian Pizza (Slice)', 258, 11.5, 30.5, 10.0,
 1.6, 5.5, 180, 180,
 'pizza_generic', ARRAY['ny hawaiian pizza', 'hawaiian pizza slice', 'new york hawaiian pizza', 'ham and pineapple pizza', 'pineapple pizza slice'],
 'pizza', NULL, 1, '258 cal/100g. Per 180g slice: ~464 cal. Ham, pineapple, mozzarella.', TRUE,
 640, 24, 4.2, 0.2, 185, 168, 2.2, 48, 6.0, 3, 17, 1.4, 160, 18.0, 0.06),

-- NY Style Supreme
('ny_style_supreme_pizza', 'New York Style Supreme Pizza (Slice)', 270, 11.8, 28.8, 12.2,
 2.0, 3.5, 180, 180,
 'pizza_generic', ARRAY['ny supreme pizza', 'supreme pizza slice', 'new york supreme pizza', 'combo pizza ny', 'deluxe pizza slice', 'everything pizza'],
 'pizza', NULL, 1, '270 cal/100g. Per 180g slice: ~486 cal. Pepperoni, sausage, peppers, onions, mushrooms.', TRUE,
 670, 28, 5.0, 0.2, 200, 165, 2.6, 60, 3.5, 3, 18, 1.6, 168, 19.5, 0.07),

-- ==========================================
-- CHICAGO DEEP DISH (~250g per slice)
-- ==========================================

-- Chicago Deep Dish Cheese: Denser crust, more cheese. ~250 cal/100g
('chicago_deep_dish_cheese', 'Chicago Deep Dish Cheese Pizza (Slice)', 250, 10.0, 26.5, 12.0,
 1.4, 3.0, 250, 250,
 'pizza_generic', ARRAY['chicago deep dish cheese', 'deep dish cheese pizza', 'chicago style cheese pizza', 'deep dish pizza cheese'],
 'pizza', NULL, 1, '250 cal/100g. Per 250g slice: ~625 cal. Thick buttery crust, layers of cheese.', TRUE,
 580, 28, 5.8, 0.2, 155, 195, 2.2, 62, 1.0, 4, 17, 1.5, 172, 17.5, 0.08),

-- Chicago Deep Dish Pepperoni
('chicago_deep_dish_pepperoni', 'Chicago Deep Dish Pepperoni Pizza (Slice)', 268, 11.2, 25.5, 13.5,
 1.2, 2.8, 250, 250,
 'pizza_generic', ARRAY['chicago deep dish pepperoni', 'deep dish pepperoni pizza', 'chicago style pepperoni pizza'],
 'pizza', NULL, 1, '268 cal/100g. Per 250g slice: ~670 cal. Deep dish with pepperoni layer.', TRUE,
 660, 32, 6.2, 0.2, 165, 180, 2.5, 55, 1.0, 4, 17, 1.7, 175, 19.0, 0.07),

-- Chicago Deep Dish Sausage: Signature Chicago combo
('chicago_deep_dish_sausage', 'Chicago Deep Dish Sausage Pizza (Slice)', 272, 11.5, 25.0, 14.0,
 1.2, 2.8, 250, 250,
 'pizza_generic', ARRAY['chicago deep dish sausage', 'deep dish sausage pizza', 'chicago sausage pizza', 'lou malnati''s style sausage'],
 'pizza', NULL, 1, '272 cal/100g. Per 250g slice: ~680 cal. Thick crust with Italian sausage patty layer.', TRUE,
 650, 35, 6.0, 0.2, 170, 175, 2.6, 52, 1.0, 4, 18, 1.8, 178, 19.5, 0.06),

-- Chicago Deep Dish Spinach
('chicago_deep_dish_spinach', 'Chicago Deep Dish Spinach Pizza (Slice)', 245, 10.5, 26.0, 11.5,
 2.0, 2.5, 250, 250,
 'pizza_generic', ARRAY['chicago deep dish spinach', 'deep dish spinach pizza', 'chicago spinach pizza', 'spinach deep dish'],
 'pizza', NULL, 1, '245 cal/100g. Per 250g slice: ~612 cal. Deep dish with spinach and cheese.', TRUE,
 540, 25, 5.5, 0.1, 210, 200, 2.8, 180, 4.0, 4, 25, 1.4, 170, 17.0, 0.08),

-- Chicago Deep Dish Meat Combo
('chicago_deep_dish_meat_combo', 'Chicago Deep Dish Meat Combo Pizza (Slice)', 290, 13.0, 25.0, 15.5,
 1.2, 2.5, 250, 250,
 'pizza_generic', ARRAY['chicago deep dish meat combo', 'deep dish meat pizza', 'chicago meat lovers deep dish', 'deep dish all meat'],
 'pizza', NULL, 1, '290 cal/100g. Per 250g slice: ~725 cal. Sausage, pepperoni, ham, bacon deep dish.', TRUE,
 740, 40, 7.0, 0.3, 190, 165, 2.8, 48, 1.0, 3, 18, 2.0, 178, 21.0, 0.06),

-- Chicago Deep Dish Supreme
('chicago_deep_dish_supreme', 'Chicago Deep Dish Supreme Pizza (Slice)', 265, 11.2, 26.0, 13.0,
 1.8, 3.0, 250, 250,
 'pizza_generic', ARRAY['chicago deep dish supreme', 'deep dish supreme pizza', 'chicago supreme deep dish', 'deep dish combo pizza'],
 'pizza', NULL, 1, '265 cal/100g. Per 250g slice: ~662 cal. Sausage, peppers, onions, mushrooms deep dish.', TRUE,
 660, 30, 5.8, 0.2, 200, 170, 2.6, 58, 3.0, 3, 19, 1.6, 172, 19.0, 0.07),

-- ==========================================
-- DETROIT STYLE (~200g per slice)
-- ==========================================

-- Detroit Style Cheese: Thick airy crust, crispy cheese edges
('detroit_style_cheese_pizza', 'Detroit Style Cheese Pizza (Slice)', 265, 11.5, 27.0, 12.5,
 1.4, 3.0, 200, 200,
 'pizza_generic', ARRAY['detroit style cheese pizza', 'detroit cheese pizza', 'detroit style pizza cheese', 'motor city pizza'],
 'pizza', NULL, 1, '265 cal/100g. Per 200g slice: ~530 cal. Thick crust, brick cheese, crispy edges.', TRUE,
 580, 26, 5.5, 0.2, 160, 190, 2.3, 60, 1.0, 4, 17, 1.5, 170, 18.0, 0.08),

-- Detroit Style Pepperoni
('detroit_style_pepperoni_pizza', 'Detroit Style Pepperoni Pizza (Slice)', 280, 12.0, 26.5, 13.5,
 1.2, 2.8, 200, 200,
 'pizza_generic', ARRAY['detroit style pepperoni pizza', 'detroit pepperoni pizza', 'detroit style pepperoni', 'buddy''s style pepperoni'],
 'pizza', NULL, 1, '280 cal/100g. Per 200g slice: ~560 cal. Crispy-edged pepperoni on thick crust.', TRUE,
 660, 30, 6.0, 0.2, 170, 175, 2.5, 55, 1.0, 3, 17, 1.7, 172, 19.5, 0.07),

-- Detroit Style Supreme
('detroit_style_supreme_pizza', 'Detroit Style Supreme Pizza (Slice)', 272, 11.5, 26.0, 13.0,
 1.8, 3.0, 200, 200,
 'pizza_generic', ARRAY['detroit style supreme pizza', 'detroit supreme pizza', 'detroit style combo pizza', 'detroit loaded pizza'],
 'pizza', NULL, 1, '272 cal/100g. Per 200g slice: ~544 cal. Multi-topping on Detroit thick crust.', TRUE,
 660, 28, 5.5, 0.2, 195, 172, 2.6, 58, 3.0, 3, 18, 1.6, 168, 19.0, 0.07),

-- Detroit Style Four Cheese
('detroit_style_four_cheese_pizza', 'Detroit Style Four Cheese Pizza (Slice)', 278, 12.0, 26.0, 14.0,
 1.2, 2.5, 200, 200,
 'pizza_generic', ARRAY['detroit style four cheese pizza', 'detroit four cheese pizza', 'detroit 4 cheese pizza', 'detroit style quattro formaggi'],
 'pizza', NULL, 1, '278 cal/100g. Per 200g slice: ~556 cal. Mozzarella, brick, parmesan, provolone.', TRUE,
 570, 32, 7.0, 0.2, 145, 220, 2.0, 68, 0.5, 5, 18, 1.6, 185, 17.0, 0.09),

-- ==========================================
-- NEAPOLITAN (~300g whole personal pie)
-- ==========================================

-- Neapolitan Margherita: Lighter, wood-fired. ~222 cal/100g
('neapolitan_margherita_pizza', 'Neapolitan Margherita Pizza (Personal Pie)', 222, 9.0, 29.0, 7.0,
 1.5, 3.0, 300, 300,
 'pizza_generic', ARRAY['neapolitan margherita', 'margherita pizza', 'neapolitan pizza', 'wood fired margherita', 'pizza margherita', 'margherita pie'],
 'pizza', NULL, 1, '222 cal/100g. Per 300g pie: ~666 cal. San Marzano tomato, fresh mozzarella, basil.', TRUE,
 480, 18, 3.5, 0.1, 180, 150, 1.8, 55, 3.0, 3, 16, 1.2, 140, 15.0, 0.08),

-- Neapolitan Marinara (no cheese, just tomato, garlic, oregano)
('neapolitan_marinara_pizza', 'Neapolitan Marinara Pizza (Personal Pie)', 195, 5.5, 32.0, 5.0,
 2.0, 4.0, 300, 300,
 'pizza_generic', ARRAY['neapolitan marinara pizza', 'marinara pizza', 'pizza marinara', 'tomato garlic pizza', 'cheeseless neapolitan'],
 'pizza', NULL, 1, '195 cal/100g. Per 300g pie: ~585 cal. Tomato, garlic, oregano, olive oil. No cheese.', TRUE,
 420, 0, 0.7, 0.0, 195, 30, 1.8, 40, 5.0, 0, 18, 0.6, 60, 14.0, 0.05),

-- Neapolitan Quattro Formaggi
('neapolitan_quattro_formaggi', 'Neapolitan Quattro Formaggi Pizza (Personal Pie)', 265, 11.0, 26.0, 13.0,
 1.2, 2.0, 300, 300,
 'pizza_generic', ARRAY['neapolitan quattro formaggi', 'four cheese pizza', 'quattro formaggi pizza', '4 cheese neapolitan', 'pizza quattro formaggi'],
 'pizza', NULL, 1, '265 cal/100g. Per 300g pie: ~795 cal. Mozzarella, gorgonzola, fontina, parmesan.', TRUE,
 520, 35, 7.0, 0.2, 140, 225, 1.5, 70, 0.5, 5, 16, 1.6, 190, 16.0, 0.09),

-- Neapolitan Prosciutto
('neapolitan_prosciutto_pizza', 'Neapolitan Prosciutto Pizza (Personal Pie)', 238, 11.0, 28.0, 8.5,
 1.4, 2.8, 300, 300,
 'pizza_generic', ARRAY['neapolitan prosciutto pizza', 'prosciutto pizza', 'pizza prosciutto', 'ham pizza neapolitan', 'prosciutto mozzarella pizza'],
 'pizza', NULL, 1, '238 cal/100g. Per 300g pie: ~714 cal. Fresh mozzarella, prosciutto crudo, arugula.', TRUE,
 620, 25, 3.8, 0.1, 185, 155, 2.0, 52, 2.0, 3, 17, 1.5, 155, 16.5, 0.07),

-- Neapolitan Diavola (spicy salami)
('neapolitan_diavola_pizza', 'Neapolitan Diavola Pizza (Personal Pie)', 252, 10.5, 28.0, 10.5,
 1.4, 3.0, 300, 300,
 'pizza_generic', ARRAY['neapolitan diavola pizza', 'diavola pizza', 'pizza diavola', 'spicy salami pizza', 'calabrese pizza'],
 'pizza', NULL, 1, '252 cal/100g. Per 300g pie: ~756 cal. Spicy salami, tomato, mozzarella.', TRUE,
 650, 28, 4.5, 0.2, 175, 155, 2.2, 55, 2.0, 3, 17, 1.5, 158, 18.0, 0.07),

-- ==========================================
-- SICILIAN STYLE (~200g per square slice)
-- ==========================================

-- Sicilian Cheese: Thick, spongy crust. ~260 cal/100g
('sicilian_cheese_pizza', 'Sicilian Cheese Pizza (Square Slice)', 260, 10.0, 30.0, 11.0,
 1.6, 3.2, 200, 200,
 'pizza_generic', ARRAY['sicilian cheese pizza', 'sicilian pizza', 'square pizza cheese', 'thick crust cheese pizza', 'sfincione'],
 'pizza', NULL, 1, '260 cal/100g. Per 200g slice: ~520 cal. Thick, spongy Sicilian-style crust.', TRUE,
 570, 20, 4.5, 0.2, 165, 175, 2.3, 58, 1.5, 3, 18, 1.3, 160, 17.0, 0.07),

-- Sicilian Pepperoni
('sicilian_pepperoni_pizza', 'Sicilian Pepperoni Pizza (Square Slice)', 278, 11.2, 29.0, 12.5,
 1.4, 3.0, 200, 200,
 'pizza_generic', ARRAY['sicilian pepperoni pizza', 'square pepperoni pizza', 'thick crust pepperoni pizza', 'sicilian style pepperoni'],
 'pizza', NULL, 1, '278 cal/100g. Per 200g slice: ~556 cal. Thick Sicilian crust with pepperoni.', TRUE,
 660, 28, 5.2, 0.2, 175, 165, 2.5, 52, 1.0, 3, 17, 1.5, 165, 19.0, 0.07),

-- Sicilian Grandma Style (thinner than typical Sicilian, olive oil)
('sicilian_grandma_pizza', 'Grandma Style Pizza (Square Slice)', 255, 9.5, 29.5, 11.0,
 1.6, 3.5, 200, 200,
 'pizza_generic', ARRAY['grandma pizza', 'grandma style pizza', 'grandma slice', 'sicilian grandma pizza', 'thin sicilian pizza'],
 'pizza', NULL, 1, '255 cal/100g. Per 200g slice: ~510 cal. Thin crispy Sicilian crust, fresh tomato, olive oil.', TRUE,
 540, 18, 4.2, 0.1, 180, 160, 2.2, 55, 2.5, 3, 18, 1.3, 155, 16.5, 0.07),

-- ==========================================
-- PAN PIZZA (~150g per slice)
-- ==========================================

-- Pan Pizza Cheese: ~280 cal/100g, oilier crust
('pan_pizza_cheese', 'Pan Pizza Cheese (Slice)', 280, 10.5, 30.0, 13.0,
 1.6, 3.2, 150, 150,
 'pizza_generic', ARRAY['pan pizza cheese', 'cheese pan pizza', 'thick crust pan pizza', 'pan crust cheese pizza'],
 'pizza', NULL, 1, '280 cal/100g. Per 150g slice: ~420 cal. Oil-crisped pan crust with cheese.', TRUE,
 590, 22, 5.5, 0.2, 155, 180, 2.2, 58, 1.0, 3, 17, 1.4, 168, 17.5, 0.07),

-- Pan Pizza Pepperoni
('pan_pizza_pepperoni', 'Pan Pizza Pepperoni (Slice)', 295, 11.5, 28.5, 14.5,
 1.4, 3.0, 150, 150,
 'pizza_generic', ARRAY['pan pizza pepperoni', 'pepperoni pan pizza', 'thick crust pepperoni pan pizza'],
 'pizza', NULL, 1, '295 cal/100g. Per 150g slice: ~442 cal. Pan crust with pepperoni.', TRUE,
 680, 30, 6.0, 0.2, 168, 168, 2.5, 52, 1.0, 3, 17, 1.6, 172, 19.0, 0.07),

-- Pan Pizza Supreme
('pan_pizza_supreme', 'Pan Pizza Supreme (Slice)', 278, 11.0, 28.5, 13.5,
 1.8, 3.2, 150, 150,
 'pizza_generic', ARRAY['pan pizza supreme', 'supreme pan pizza', 'pan pizza combo', 'pan pizza loaded', 'pan pizza deluxe'],
 'pizza', NULL, 1, '278 cal/100g. Per 150g slice: ~417 cal. Pan crust with pepperoni, sausage, veggies.', TRUE,
 660, 26, 5.5, 0.2, 195, 165, 2.5, 58, 3.0, 3, 18, 1.5, 168, 18.5, 0.07),

-- ==========================================
-- STUFFED PIZZA (~250g per slice)
-- ==========================================

-- Stuffed Pizza Cheese: Double crust, extra cheese. ~285 cal/100g
('stuffed_pizza_cheese', 'Stuffed Cheese Pizza (Slice)', 285, 11.5, 28.0, 14.5,
 1.2, 2.5, 250, 250,
 'pizza_generic', ARRAY['stuffed cheese pizza', 'stuffed pizza cheese', 'stuffed crust cheese pizza', 'double crust cheese pizza'],
 'pizza', NULL, 1, '285 cal/100g. Per 250g slice: ~712 cal. Double dough layers stuffed with cheese.', TRUE,
 590, 32, 7.0, 0.2, 145, 210, 2.2, 65, 0.5, 5, 17, 1.6, 185, 17.0, 0.09),

-- Stuffed Pizza Sausage
('stuffed_pizza_sausage', 'Stuffed Sausage Pizza (Slice)', 295, 12.5, 27.0, 15.5,
 1.2, 2.5, 250, 250,
 'pizza_generic', ARRAY['stuffed sausage pizza', 'stuffed pizza sausage', 'chicago stuffed sausage pizza', 'deep stuffed sausage'],
 'pizza', NULL, 1, '295 cal/100g. Per 250g slice: ~738 cal. Double crust stuffed with sausage and cheese.', TRUE,
 660, 38, 6.8, 0.2, 170, 185, 2.6, 52, 1.0, 4, 18, 1.8, 178, 19.5, 0.07),

-- Stuffed Pizza Spinach
('stuffed_pizza_spinach', 'Stuffed Spinach Pizza (Slice)', 262, 11.0, 28.0, 12.0,
 2.0, 2.5, 250, 250,
 'pizza_generic', ARRAY['stuffed spinach pizza', 'stuffed pizza spinach', 'spinach stuffed pizza', 'stuffed spinach deep dish'],
 'pizza', NULL, 1, '262 cal/100g. Per 250g slice: ~655 cal. Double crust stuffed with spinach and cheese.', TRUE,
 550, 28, 5.8, 0.1, 215, 205, 2.8, 175, 4.0, 4, 25, 1.5, 178, 17.0, 0.08),

-- ==========================================
-- FLATBREAD PIZZA (~200g per piece)
-- ==========================================

-- Flatbread Margherita: Lighter, thinner base
('flatbread_margherita_pizza', 'Flatbread Margherita Pizza', 235, 9.5, 28.0, 9.0,
 1.6, 3.5, 200, 200,
 'pizza_generic', ARRAY['flatbread margherita pizza', 'margherita flatbread', 'flatbread pizza margherita', 'thin flatbread margherita'],
 'pizza', NULL, 1, '235 cal/100g. Per 200g flatbread: ~470 cal. Thin flatbread with tomato, mozzarella, basil.', TRUE,
 490, 18, 3.8, 0.1, 175, 155, 1.8, 55, 3.0, 3, 16, 1.2, 142, 15.5, 0.07),

-- Flatbread BBQ Chicken
('flatbread_bbq_chicken_pizza', 'Flatbread BBQ Chicken Pizza', 248, 13.0, 28.5, 8.5,
 1.4, 6.0, 200, 200,
 'pizza_generic', ARRAY['flatbread bbq chicken pizza', 'bbq chicken flatbread', 'barbecue chicken flatbread pizza', 'bbq chicken pizza flatbread'],
 'pizza', NULL, 1, '248 cal/100g. Per 200g flatbread: ~496 cal. Grilled chicken, BBQ sauce, red onion.', TRUE,
 580, 35, 3.5, 0.1, 200, 145, 1.8, 42, 2.0, 3, 20, 1.5, 155, 18.0, 0.05),

-- Flatbread Veggie
('flatbread_veggie_pizza', 'Flatbread Veggie Pizza', 225, 8.5, 29.0, 8.0,
 2.5, 4.0, 200, 200,
 'pizza_generic', ARRAY['flatbread veggie pizza', 'veggie flatbread pizza', 'vegetable flatbread', 'garden flatbread pizza'],
 'pizza', NULL, 1, '225 cal/100g. Per 200g flatbread: ~450 cal. Roasted vegetables, goat cheese.', TRUE,
 480, 12, 3.2, 0.1, 215, 140, 2.0, 70, 5.0, 2, 20, 1.1, 135, 15.0, 0.06),

-- Flatbread Mediterranean
('flatbread_mediterranean_pizza', 'Flatbread Mediterranean Pizza', 232, 9.0, 27.5, 9.5,
 2.2, 3.5, 200, 200,
 'pizza_generic', ARRAY['flatbread mediterranean pizza', 'mediterranean flatbread', 'greek flatbread pizza', 'flatbread with feta olives'],
 'pizza', NULL, 1, '232 cal/100g. Per 200g flatbread: ~464 cal. Feta, olives, sun-dried tomato, artichoke.', TRUE,
 560, 15, 4.0, 0.1, 200, 148, 2.0, 60, 3.5, 2, 20, 1.2, 140, 15.5, 0.08),

-- ==========================================
-- CALZONE (~300g each)
-- ==========================================

-- Calzone Cheese: Folded pizza dough stuffed with ricotta and mozzarella
('calzone_cheese', 'Cheese Calzone', 265, 12.0, 28.0, 11.5,
 1.4, 2.5, 300, 300,
 'pizza_generic', ARRAY['cheese calzone', 'calzone cheese', 'ricotta calzone', 'plain calzone', 'calzone'],
 'pizza', NULL, 1, '265 cal/100g. Per 300g calzone: ~795 cal. Ricotta, mozzarella, parmesan in folded dough.', TRUE,
 580, 30, 5.5, 0.2, 150, 195, 2.2, 60, 0.5, 4, 17, 1.5, 175, 17.0, 0.08),

-- Calzone Pepperoni
('calzone_pepperoni', 'Pepperoni Calzone', 285, 13.5, 27.0, 13.5,
 1.2, 2.5, 300, 300,
 'pizza_generic', ARRAY['pepperoni calzone', 'calzone pepperoni', 'pepperoni and cheese calzone'],
 'pizza', NULL, 1, '285 cal/100g. Per 300g calzone: ~855 cal. Pepperoni, ricotta, mozzarella.', TRUE,
 680, 35, 6.2, 0.2, 168, 178, 2.5, 55, 0.5, 3, 17, 1.7, 175, 19.0, 0.07),

-- Calzone Meat
('calzone_meat', 'Meat Calzone', 300, 15.0, 26.0, 15.0,
 1.2, 2.2, 300, 300,
 'pizza_generic', ARRAY['meat calzone', 'calzone meat', 'meat lovers calzone', 'sausage and pepperoni calzone', 'italian calzone'],
 'pizza', NULL, 1, '300 cal/100g. Per 300g calzone: ~900 cal. Sausage, pepperoni, ham, mozzarella.', TRUE,
 740, 40, 6.8, 0.3, 185, 170, 2.8, 50, 0.5, 3, 18, 2.0, 180, 21.0, 0.06),

-- Calzone Veggie
('calzone_veggie', 'Veggie Calzone', 245, 10.0, 29.0, 10.0,
 2.2, 3.5, 300, 300,
 'pizza_generic', ARRAY['veggie calzone', 'calzone veggie', 'vegetable calzone', 'spinach calzone', 'garden calzone'],
 'pizza', NULL, 1, '245 cal/100g. Per 300g calzone: ~735 cal. Spinach, mushrooms, peppers, ricotta.', TRUE,
 520, 18, 4.5, 0.1, 210, 180, 2.4, 80, 4.0, 3, 22, 1.3, 160, 16.0, 0.07),

-- ==========================================
-- STROMBOLI (~250g each)
-- ==========================================

-- Stromboli Italian: Rolled dough with deli meats and cheese
('stromboli_italian', 'Italian Stromboli', 310, 14.5, 26.0, 16.0,
 1.0, 2.0, 250, 250,
 'pizza_generic', ARRAY['italian stromboli', 'stromboli italian', 'stromboli', 'deli stromboli', 'italian roll stromboli'],
 'pizza', NULL, 1, '310 cal/100g. Per 250g stromboli: ~775 cal. Salami, capicola, provolone, peppers.', TRUE,
 780, 42, 6.5, 0.2, 180, 165, 2.5, 48, 2.0, 3, 17, 2.0, 175, 20.0, 0.06),

-- Stromboli Pepperoni
('stromboli_pepperoni', 'Pepperoni Stromboli', 305, 14.0, 26.5, 15.5,
 1.0, 2.2, 250, 250,
 'pizza_generic', ARRAY['pepperoni stromboli', 'stromboli pepperoni', 'pepperoni cheese stromboli', 'pepperoni roll'],
 'pizza', NULL, 1, '305 cal/100g. Per 250g stromboli: ~762 cal. Pepperoni, mozzarella rolled in dough.', TRUE,
 750, 38, 6.5, 0.2, 172, 170, 2.5, 52, 0.5, 3, 17, 1.8, 175, 20.0, 0.07),

-- Stromboli Ham & Cheese
('stromboli_ham_cheese', 'Ham & Cheese Stromboli', 290, 14.0, 27.0, 14.0,
 1.0, 2.5, 250, 250,
 'pizza_generic', ARRAY['ham and cheese stromboli', 'stromboli ham cheese', 'ham cheese stromboli', 'ham stromboli'],
 'pizza', NULL, 1, '290 cal/100g. Per 250g stromboli: ~725 cal. Deli ham, mozzarella, provolone.', TRUE,
 720, 35, 6.0, 0.2, 175, 172, 2.2, 45, 0.5, 3, 16, 1.7, 170, 18.5, 0.06),

-- ==========================================
-- SPECIALTY & GOURMET
-- ==========================================

-- BBQ Chicken Pizza (standard, not flatbread)
('bbq_chicken_pizza', 'BBQ Chicken Pizza (Slice)', 258, 13.0, 29.0, 9.5,
 1.4, 5.5, 180, 180,
 'pizza_generic', ARRAY['bbq chicken pizza', 'barbecue chicken pizza', 'bbq chicken pizza slice', 'california bbq chicken pizza'],
 'pizza', NULL, 1, '258 cal/100g. Per 180g slice: ~464 cal. Grilled chicken, BBQ sauce, red onion, cilantro.', TRUE,
 580, 32, 3.8, 0.1, 195, 150, 1.8, 42, 2.0, 3, 19, 1.5, 155, 18.0, 0.05),

-- Margherita Pizza (generic/American style, not Neapolitan)
('margherita_pizza', 'Margherita Pizza (Slice)', 245, 10.0, 29.0, 9.5,
 1.6, 3.5, 180, 180,
 'pizza_generic', ARRAY['margherita pizza slice', 'margherita pie', 'fresh mozzarella pizza', 'tomato basil pizza'],
 'pizza', NULL, 1, '245 cal/100g. Per 180g slice: ~441 cal. Fresh mozzarella, tomato, basil.', TRUE,
 490, 20, 4.0, 0.1, 180, 160, 2.0, 58, 3.0, 3, 17, 1.3, 148, 16.0, 0.08),

-- Pepperoni & Sausage (double meat classic)
('pepperoni_sausage_pizza', 'Pepperoni & Sausage Pizza (Slice)', 285, 12.5, 27.5, 13.8,
 1.4, 3.0, 180, 180,
 'pizza_generic', ARRAY['pepperoni and sausage pizza', 'pepperoni sausage pizza', 'double meat pizza', 'pepperoni sausage slice'],
 'pizza', NULL, 1, '285 cal/100g. Per 180g slice: ~513 cal. Pepperoni and Italian sausage combo.', TRUE,
 700, 32, 5.8, 0.2, 185, 168, 2.6, 52, 1.0, 3, 17, 1.7, 172, 20.0, 0.06),

-- Four Cheese Pizza (American style)
('four_cheese_pizza', 'Four Cheese Pizza (Slice)', 275, 11.5, 27.5, 13.5,
 1.2, 2.5, 180, 180,
 'pizza_generic', ARRAY['four cheese pizza', '4 cheese pizza', 'quattro formaggi pizza', 'multi cheese pizza', 'cheese blend pizza'],
 'pizza', NULL, 1, '275 cal/100g. Per 180g slice: ~495 cal. Mozzarella, ricotta, parmesan, provolone.', TRUE,
 560, 32, 7.0, 0.2, 140, 220, 1.8, 68, 0.5, 5, 17, 1.6, 188, 16.5, 0.09),

-- Chicken Alfredo Pizza (white sauce)
('chicken_alfredo_pizza', 'Chicken Alfredo Pizza (Slice)', 268, 13.0, 26.0, 12.5,
 1.0, 2.0, 180, 180,
 'pizza_generic', ARRAY['chicken alfredo pizza', 'alfredo pizza', 'white sauce chicken pizza', 'creamy chicken pizza'],
 'pizza', NULL, 1, '268 cal/100g. Per 180g slice: ~482 cal. Grilled chicken, alfredo sauce, mozzarella.', TRUE,
 560, 35, 6.0, 0.2, 165, 180, 1.8, 55, 0.5, 4, 17, 1.5, 172, 18.0, 0.06),

-- Bacon Ranch Pizza
('bacon_ranch_pizza', 'Bacon Ranch Pizza (Slice)', 290, 12.5, 27.0, 14.5,
 1.2, 2.5, 180, 180,
 'pizza_generic', ARRAY['bacon ranch pizza', 'ranch pizza', 'chicken bacon ranch pizza', 'bacon ranch slice'],
 'pizza', NULL, 1, '290 cal/100g. Per 180g slice: ~522 cal. Bacon, ranch dressing, chicken, mozzarella.', TRUE,
 700, 35, 6.0, 0.2, 170, 168, 2.0, 48, 0.5, 3, 16, 1.6, 170, 19.0, 0.06),

-- Pesto Pizza
('pesto_pizza', 'Pesto Pizza (Slice)', 265, 10.5, 26.0, 13.5,
 1.4, 2.0, 180, 180,
 'pizza_generic', ARRAY['pesto pizza', 'basil pesto pizza', 'pesto chicken pizza', 'green pizza pesto'],
 'pizza', NULL, 1, '265 cal/100g. Per 180g slice: ~477 cal. Basil pesto base, mozzarella, tomatoes.', TRUE,
 480, 22, 5.0, 0.1, 175, 165, 2.0, 60, 2.0, 3, 20, 1.3, 155, 16.0, 0.10),

-- Philly Cheesesteak Pizza
('philly_cheesesteak_pizza', 'Philly Cheesesteak Pizza (Slice)', 275, 13.0, 27.0, 13.0,
 1.2, 2.5, 180, 180,
 'pizza_generic', ARRAY['philly cheesesteak pizza', 'cheesesteak pizza', 'steak pizza', 'philly pizza'],
 'pizza', NULL, 1, '275 cal/100g. Per 180g slice: ~495 cal. Shaved steak, peppers, onions, provolone.', TRUE,
 640, 35, 5.5, 0.3, 190, 165, 2.8, 45, 3.0, 3, 19, 2.2, 175, 20.0, 0.06),

-- Spinach & Artichoke Pizza
('spinach_artichoke_pizza', 'Spinach & Artichoke Pizza (Slice)', 242, 10.0, 27.5, 10.5,
 2.4, 2.5, 180, 180,
 'pizza_generic', ARRAY['spinach artichoke pizza', 'spinach and artichoke pizza', 'artichoke pizza', 'spinach pizza'],
 'pizza', NULL, 1, '242 cal/100g. Per 180g slice: ~436 cal. Creamy spinach artichoke, mozzarella.', TRUE,
 530, 22, 4.8, 0.1, 220, 175, 2.5, 150, 5.0, 3, 24, 1.3, 165, 16.0, 0.08),

-- Taco Pizza
('taco_pizza', 'Taco Pizza (Slice)', 268, 12.0, 28.0, 12.0,
 2.0, 3.0, 180, 180,
 'pizza_generic', ARRAY['taco pizza', 'mexican pizza', 'taco pizza slice', 'fiesta pizza'],
 'pizza', NULL, 1, '268 cal/100g. Per 180g slice: ~482 cal. Seasoned beef, cheddar, lettuce, tomato, sour cream.', TRUE,
 620, 28, 5.0, 0.2, 195, 160, 2.5, 50, 3.0, 3, 18, 2.0, 165, 18.0, 0.06),

-- ==========================================
-- FROZEN / CONVENIENCE PIZZA STYLES
-- ==========================================

-- French Bread Pizza: Open-face on French bread (~170g per piece)
('french_bread_pizza', 'French Bread Pizza', 255, 10.0, 30.0, 10.5,
 1.8, 4.0, 170, 170,
 'pizza_generic', ARRAY['french bread pizza', 'french bread pizza cheese', 'open face pizza', 'stouffers french bread pizza'],
 'pizza', NULL, 1, '255 cal/100g. Per 170g piece: ~434 cal. Pizza on a French bread base.', TRUE,
 580, 18, 4.2, 0.2, 160, 165, 2.2, 52, 1.5, 3, 17, 1.3, 155, 16.5, 0.06),

-- Bagel Pizza Bites: Small bagel-based pizza snacks (~88g for 4 pieces)
('bagel_pizza_bites', 'Bagel Pizza Bites (Cheese & Pepperoni)', 230, 8.5, 32.0, 7.5,
 1.4, 3.5, 88, 22,
 'pizza_generic', ARRAY['bagel bites', 'bagel pizza bites', 'pizza bagels', 'bagel bites pizza', 'mini bagel pizzas'],
 'pizza', NULL, 4, '230 cal/100g. Per 88g serving (4 pieces): ~202 cal. Mini bagel-based pizza snacks.', TRUE,
 550, 12, 3.0, 0.1, 120, 130, 1.8, 40, 0.5, 2, 14, 0.9, 120, 12.0, 0.04),

-- Pizza Rolls (~85g for 6 pieces)
('pizza_rolls_generic', 'Pizza Rolls (Pepperoni & Cheese)', 245, 7.0, 30.0, 10.5,
 1.2, 3.0, 85, 14,
 'pizza_generic', ARRAY['pizza rolls', 'totinos pizza rolls', 'pizza roll snacks', 'pizza bites rolls', 'pizza pockets'],
 'pizza', NULL, 6, '245 cal/100g. Per 85g serving (6 rolls): ~208 cal. Crispy dough stuffed with pizza filling.', TRUE,
 540, 10, 3.5, 0.2, 120, 100, 1.8, 30, 0.5, 1, 12, 0.8, 105, 10.0, 0.04),

-- ==========================================
-- GENERIC / CATCH-ALL PIZZA ENTRIES
-- ==========================================

-- Generic Cheese Pizza (when style unspecified)
('cheese_pizza', 'Cheese Pizza (Slice)', 266, 11.4, 31.0, 10.9,
 1.8, 3.6, 107, 107,
 'pizza_generic', ARRAY['cheese pizza', 'plain pizza', 'pizza slice', 'regular pizza', 'cheese pizza slice', 'slice of pizza'],
 'pizza', NULL, 1, '266 cal/100g. Per 107g slice: ~285 cal. USDA standard cheese pizza.', TRUE,
 598, 22, 4.5, 0.2, 172, 188, 2.5, 60, 1.5, 3, 18, 1.4, 165, 18.0, 0.08),

-- Generic Pepperoni Pizza (when style unspecified)
('pepperoni_pizza', 'Pepperoni Pizza (Slice)', 275, 12.0, 28.7, 12.5,
 1.6, 3.2, 113, 113,
 'pizza_generic', ARRAY['pepperoni pizza', 'pepperoni pizza slice', 'pep pizza', 'pepperoni slice'],
 'pizza', NULL, 1, '275 cal/100g. Per 113g slice: ~311 cal. USDA standard pepperoni pizza.', TRUE,
 680, 28, 5.2, 0.2, 180, 170, 2.6, 55, 1.2, 3, 17, 1.6, 170, 20.0, 0.07),

-- Generic Veggie Pizza
('veggie_pizza', 'Veggie Pizza (Slice)', 240, 9.8, 30.5, 9.2,
 2.4, 4.0, 113, 113,
 'pizza_generic', ARRAY['veggie pizza', 'vegetable pizza', 'garden pizza', 'veggie pizza slice'],
 'pizza', NULL, 1, '240 cal/100g. Per 113g slice: ~271 cal. Standard veggie pizza.', TRUE,
 520, 16, 3.8, 0.1, 210, 165, 2.2, 75, 5.0, 3, 20, 1.2, 148, 16.0, 0.06),

-- Generic Meat Lovers Pizza
('meat_lovers_pizza', 'Meat Lovers Pizza (Slice)', 295, 13.5, 27.0, 14.8,
 1.4, 3.0, 130, 130,
 'pizza_generic', ARRAY['meat lovers pizza', 'meat pizza', 'all meat pizza', 'meat feast pizza', 'meat lovers slice', 'meatzza'],
 'pizza', NULL, 1, '295 cal/100g. Per 130g slice: ~384 cal. Pepperoni, sausage, ham, bacon.', TRUE,
 750, 38, 6.2, 0.3, 195, 160, 2.8, 50, 1.0, 3, 18, 2.0, 175, 22.0, 0.06),

-- Generic Supreme Pizza
('supreme_pizza', 'Supreme Pizza (Slice)', 270, 11.8, 28.8, 12.2,
 2.0, 3.5, 120, 120,
 'pizza_generic', ARRAY['supreme pizza', 'combo pizza', 'deluxe pizza', 'loaded pizza', 'works pizza', 'everything pizza slice'],
 'pizza', NULL, 1, '270 cal/100g. Per 120g slice: ~324 cal. Multiple meats and vegetables.', TRUE,
 670, 28, 5.0, 0.2, 200, 165, 2.6, 60, 3.5, 3, 18, 1.6, 168, 19.5, 0.07),

-- Generic Hawaiian Pizza
('hawaiian_pizza', 'Hawaiian Pizza (Slice)', 258, 11.5, 30.5, 10.0,
 1.6, 5.5, 115, 115,
 'pizza_generic', ARRAY['hawaiian pizza', 'ham pineapple pizza', 'pineapple pizza', 'hawaiian pizza slice', 'ham and pineapple'],
 'pizza', NULL, 1, '258 cal/100g. Per 115g slice: ~297 cal. Ham and pineapple.', TRUE,
 640, 24, 4.2, 0.2, 185, 168, 2.2, 48, 6.0, 3, 17, 1.4, 160, 18.0, 0.06),

-- Generic Sausage Pizza
('sausage_pizza', 'Sausage Pizza (Slice)', 278, 12.2, 28.5, 12.8,
 1.6, 3.2, 115, 115,
 'pizza_generic', ARRAY['sausage pizza', 'italian sausage pizza', 'sausage pizza slice'],
 'pizza', NULL, 1, '278 cal/100g. Per 115g slice: ~320 cal. Italian sausage crumbles.', TRUE,
 660, 30, 5.0, 0.2, 185, 165, 2.5, 52, 1.2, 3, 17, 1.6, 168, 19.0, 0.06),

-- Generic Mushroom Pizza
('mushroom_pizza', 'Mushroom Pizza (Slice)', 248, 10.5, 30.0, 9.5,
 2.0, 3.4, 110, 110,
 'pizza_generic', ARRAY['mushroom pizza', 'mushroom pizza slice', 'fungi pizza'],
 'pizza', NULL, 1, '248 cal/100g. Per 110g slice: ~273 cal. Fresh mushrooms on cheese pizza.', TRUE,
 560, 20, 4.0, 0.1, 200, 175, 2.3, 58, 1.5, 3, 19, 1.3, 158, 17.5, 0.07),

-- Generic Buffalo Chicken Pizza
('buffalo_chicken_pizza', 'Buffalo Chicken Pizza (Slice)', 272, 13.0, 27.5, 12.0,
 1.2, 2.5, 120, 120,
 'pizza_generic', ARRAY['buffalo chicken pizza', 'buffalo pizza', 'hot chicken pizza', 'buffalo chicken slice'],
 'pizza', NULL, 1, '272 cal/100g. Per 120g slice: ~326 cal. Grilled chicken, buffalo sauce, blue cheese.', TRUE,
 720, 32, 5.0, 0.2, 175, 170, 2.0, 55, 1.0, 3, 18, 1.5, 170, 19.0, 0.06),

-- Generic White Pizza
('white_pizza', 'White Pizza (Slice)', 280, 11.0, 28.0, 13.5,
 1.2, 2.0, 115, 115,
 'pizza_generic', ARRAY['white pizza', 'bianca pizza', 'garlic white pizza', 'no sauce pizza', 'olive oil pizza'],
 'pizza', NULL, 1, '280 cal/100g. Per 115g slice: ~322 cal. Ricotta, mozzarella, garlic, olive oil.', TRUE,
 550, 30, 6.5, 0.2, 140, 200, 1.8, 65, 0.5, 4, 16, 1.5, 175, 16.0, 0.08),

-- ==========================================
-- THIN CRUST & SPECIALTY CRUST
-- ==========================================

-- Thin Crust Cheese Pizza
('thin_crust_cheese_pizza', 'Thin Crust Cheese Pizza (Slice)', 285, 12.5, 25.5, 14.5,
 1.0, 2.8, 105, 105,
 'pizza_generic', ARRAY['thin crust cheese pizza', 'crispy thin pizza', 'thin pizza slice', 'extra thin crust pizza'],
 'pizza', NULL, 1, '285 cal/100g. Per 105g slice: ~299 cal. Extra-thin crispy crust, less bread more cheese.', TRUE,
 600, 28, 6.0, 0.2, 150, 195, 2.0, 62, 1.0, 4, 16, 1.5, 175, 17.0, 0.08),

-- Thin Crust Pepperoni Pizza
('thin_crust_pepperoni_pizza', 'Thin Crust Pepperoni Pizza (Slice)', 300, 13.5, 24.0, 16.0,
 1.0, 2.5, 105, 105,
 'pizza_generic', ARRAY['thin crust pepperoni pizza', 'crispy thin pepperoni pizza', 'thin crust pepperoni slice'],
 'pizza', NULL, 1, '300 cal/100g. Per 105g slice: ~315 cal. Thin crust with pepperoni.', TRUE,
 700, 32, 6.5, 0.2, 162, 178, 2.4, 55, 1.0, 3, 16, 1.7, 178, 19.5, 0.07),

-- Cauliflower Crust Cheese Pizza
('cauliflower_crust_cheese_pizza', 'Cauliflower Crust Cheese Pizza (Slice)', 215, 10.0, 18.0, 11.5,
 2.0, 3.0, 130, 130,
 'pizza_generic', ARRAY['cauliflower crust pizza', 'cauliflower pizza', 'gluten free cauliflower pizza', 'cauli crust pizza', 'low carb pizza'],
 'pizza', NULL, 1, '215 cal/100g. Per 130g slice: ~280 cal. Cauliflower-based crust, lower carb.', TRUE,
 480, 22, 4.5, 0.1, 180, 175, 1.8, 55, 5.0, 3, 18, 1.3, 155, 15.0, 0.07),

-- Gluten-Free Crust Cheese Pizza
('gluten_free_cheese_pizza', 'Gluten-Free Crust Cheese Pizza (Slice)', 255, 9.5, 30.0, 11.0,
 1.5, 3.5, 120, 120,
 'pizza_generic', ARRAY['gluten free pizza', 'gluten free cheese pizza', 'gf pizza', 'celiac friendly pizza'],
 'pizza', NULL, 1, '255 cal/100g. Per 120g slice: ~306 cal. Rice/tapioca-based GF crust.', TRUE,
 560, 20, 4.5, 0.1, 140, 170, 1.5, 55, 1.0, 3, 15, 1.0, 148, 14.0, 0.06),

-- ==========================================
-- PIZZA BY THE PIE (WHOLE)
-- ==========================================

-- Large Cheese Pizza (whole, ~800g for 14" pizza)
('large_cheese_pizza_whole', 'Large Cheese Pizza (Whole 14")', 266, 11.4, 31.0, 10.9,
 1.8, 3.6, 800, NULL,
 'pizza_generic', ARRAY['whole cheese pizza', 'large cheese pizza', 'full cheese pizza', '14 inch cheese pizza', 'whole pie cheese'],
 'pizza', NULL, 1, '266 cal/100g. Per 800g whole pie: ~2128 cal. Standard 14-inch cheese pizza.', TRUE,
 598, 22, 4.5, 0.2, 172, 188, 2.5, 60, 1.5, 3, 18, 1.4, 165, 18.0, 0.08),

-- Medium Cheese Pizza (whole, ~600g for 12" pizza)
('medium_cheese_pizza_whole', 'Medium Cheese Pizza (Whole 12")', 266, 11.4, 31.0, 10.9,
 1.8, 3.6, 600, NULL,
 'pizza_generic', ARRAY['medium cheese pizza', '12 inch cheese pizza', 'medium pie cheese', 'regular cheese pizza whole'],
 'pizza', NULL, 1, '266 cal/100g. Per 600g whole pie: ~1596 cal. Standard 12-inch cheese pizza.', TRUE,
 598, 22, 4.5, 0.2, 172, 188, 2.5, 60, 1.5, 3, 18, 1.4, 165, 18.0, 0.08),

-- Personal/Small Cheese Pizza (whole, ~350g for 10" pizza)
('personal_cheese_pizza_whole', 'Personal Cheese Pizza (Whole 10")', 266, 11.4, 31.0, 10.9,
 1.8, 3.6, 350, NULL,
 'pizza_generic', ARRAY['personal cheese pizza', 'small cheese pizza', '10 inch cheese pizza', 'individual cheese pizza', 'personal pan pizza'],
 'pizza', NULL, 1, '266 cal/100g. Per 350g whole pie: ~931 cal. Personal-size 10-inch cheese pizza.', TRUE,
 598, 22, 4.5, 0.2, 172, 188, 2.5, 60, 1.5, 3, 18, 1.4, 165, 18.0, 0.08),

-- ==========================================
-- COLD / LEFTOVER / REHEATED
-- ==========================================

-- Cold Pizza (leftover, slightly drier texture, same macros)
('cold_pizza', 'Cold Pizza (Leftover Slice)', 268, 11.5, 30.5, 11.0,
 1.8, 3.5, 107, 107,
 'pizza_generic', ARRAY['cold pizza', 'leftover pizza', 'day old pizza', 'refrigerated pizza', 'cold pizza slice'],
 'pizza', NULL, 1, '268 cal/100g. Per 107g slice: ~287 cal. Leftover pizza, same nutrition as fresh.', TRUE,
 600, 22, 4.5, 0.2, 170, 185, 2.5, 58, 1.5, 3, 18, 1.4, 165, 18.0, 0.08),

-- ==========================================
-- PIZZA ADJACENT / SPECIALTY
-- ==========================================

-- Pizza Bread / Garlic Bread Pizza
('pizza_bread', 'Pizza Bread (Garlic Bread with Cheese & Sauce)', 290, 8.5, 32.0, 14.0,
 1.4, 3.5, 150, 150,
 'pizza_generic', ARRAY['pizza bread', 'garlic bread pizza', 'cheesy garlic bread', 'pizza garlic bread', 'cheese bread pizza style'],
 'pizza', NULL, 1, '290 cal/100g. Per 150g piece: ~435 cal. Garlic bread topped with sauce and cheese.', TRUE,
 620, 18, 5.5, 0.2, 120, 150, 2.0, 45, 1.0, 2, 14, 1.0, 130, 14.0, 0.06),

-- Pepperoni Bread / Pepperoni Roll
('pepperoni_bread', 'Pepperoni Bread (Pepperoni Roll)', 310, 12.0, 28.0, 16.0,
 1.0, 2.0, 120, 120,
 'pizza_generic', ARRAY['pepperoni bread', 'pepperoni roll', 'pepperoni rolls', 'WV pepperoni roll', 'pizza roll bread'],
 'pizza', NULL, 1, '310 cal/100g. Per 120g roll: ~372 cal. Bread dough baked around pepperoni and cheese.', TRUE,
 720, 30, 6.0, 0.2, 155, 150, 2.2, 40, 0.5, 2, 15, 1.5, 155, 17.0, 0.06),

-- Pizza Dip (served with breadsticks)
('pizza_dip', 'Pizza Dip (Cheese & Pepperoni)', 215, 10.0, 8.0, 16.0,
 0.8, 2.5, 60, NULL,
 'pizza_generic', ARRAY['pizza dip', 'hot pizza dip', 'pepperoni pizza dip', 'cheesy pizza dip', 'pizza dip appetizer'],
 'pizza', NULL, 1, '215 cal/100g. Per 60g serving: ~129 cal. Melted cheese, pepperoni, pizza sauce dip.', TRUE,
 580, 40, 8.0, 0.2, 130, 200, 1.5, 60, 1.0, 4, 12, 1.5, 170, 14.0, 0.07)

ON CONFLICT (food_name_normalized) DO NOTHING;
