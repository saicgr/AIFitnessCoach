-- 1622_overrides_weight_loss_frozen_meals.sql
-- Weight-loss-oriented frozen meals: Smart Ones, Evol, Atkins, Freshly, Healthy Choice Power Bowls.
-- Sources: Package nutrition labels via fatsecret.com, nutritionix.com, calorieking.com,
-- kraftheinz.com, eatthismuch.com, atkins.com, evolfoods.com, healthychoice.com.
-- All values per 100g. default_serving_g = label serving.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SMART ONES — CLASSIC FAVORITES
-- ══════════════════════════════════════════

-- Smart Ones Santa Fe Rice & Beans: 260 cal per package (255g)
('smartones_santa_fe_rice_beans', 'Smart Ones Santa Fe Rice & Beans', 102, 4.3, 15.3, 2.4,
 2.4, 2.0, 255, NULL,
 'manufacturer', ARRAY['smart ones santa fe rice beans', 'smart ones santa fe', 'weight watchers santa fe rice beans', 'smartones santa fe rice and beans'],
 'frozen_meals', 'Smart Ones', 1, '260 cal per package (255g). Spicy rice and beans with zucchini, corn, green chile sour cream sauce and mozzarella.', TRUE),

-- Smart Ones Three Cheese Ziti Marinara: 300 cal per package (255g)
('smartones_three_cheese_ziti', 'Smart Ones Three Cheese Ziti Marinara', 118, 4.7, 16.9, 3.1,
 1.2, 1.6, 255, NULL,
 'manufacturer', ARRAY['smart ones three cheese ziti', 'smart ones ziti marinara', 'weight watchers ziti', 'smartones three cheese ziti marinara'],
 'frozen_meals', 'Smart Ones', 1, '300 cal per package (255g). Ziti pasta with marinara sauce topped with mozzarella, Monterey Jack and Parmesan.', TRUE),

-- Smart Ones Chicken Parmesan: 290 cal per package (283g)
('smartones_chicken_parmesan', 'Smart Ones Chicken Parmesan', 102, 6.7, 12.4, 2.1,
 1.8, 2.1, 283, NULL,
 'manufacturer', ARRAY['smart ones chicken parmesan', 'smart ones chicken parm', 'weight watchers chicken parmesan', 'smartones chicken parmesan'],
 'frozen_meals', 'Smart Ones', 1, '290 cal per package (283g, 10oz). Breaded white meat chicken with spaghetti, marinara sauce and cheese blend.', TRUE),

-- Smart Ones Fettuccine Alfredo: 250 cal per package (262g)
('smartones_fettuccine_alfredo', 'Smart Ones Fettuccine Alfredo', 95, 4.6, 16.0, 1.5,
 1.1, 1.5, 262, NULL,
 'manufacturer', ARRAY['smart ones fettuccine alfredo', 'smart ones alfredo', 'weight watchers fettuccine alfredo', 'smartones fettuccine alfredo'],
 'frozen_meals', 'Smart Ones', 1, '250 cal per package (262g). Fettuccine pasta with broccoli florets in a creamy Alfredo sauce.', TRUE),

-- Smart Ones Pasta with Ricotta & Spinach: 280 cal per package (255g)
('smartones_pasta_ricotta_spinach', 'Smart Ones Pasta with Ricotta & Spinach', 110, 5.5, 16.9, 2.0,
 2.4, 2.0, 255, NULL,
 'manufacturer', ARRAY['smart ones pasta ricotta spinach', 'smart ones ricotta spinach', 'weight watchers pasta ricotta spinach', 'smartones pasta with ricotta and spinach'],
 'frozen_meals', 'Smart Ones', 1, '280 cal per package (255g, 9oz). Mini pasta ribbons in creamy white sauce with ricotta cheese and spinach.', TRUE),

-- ══════════════════════════════════════════
-- SMART ONES — SMART CREATIONS
-- ══════════════════════════════════════════

-- Smart Ones Chicken Oriental: 260 cal per package (255g)
('smartones_chicken_oriental', 'Smart Ones Chicken Oriental', 102, 4.7, 17.3, 1.0,
 0.8, 2.0, 255, NULL,
 'manufacturer', ARRAY['smart ones chicken oriental', 'smart ones asian chicken', 'weight watchers chicken oriental', 'smartones chicken oriental soy sauce'],
 'frozen_meals', 'Smart Ones', 1, '260 cal per package (255g, 9oz). Premium white meat chicken with soy sauce, mixed vegetables and white rice.', TRUE),

-- Smart Ones Fiesta Chicken: 250 cal per package (255g)
('smartones_fiesta_chicken', 'Smart Ones Fiesta Chicken', 98, 4.7, 13.7, 2.4,
 1.2, 1.6, 255, NULL,
 'manufacturer', ARRAY['smart ones fiesta chicken', 'smart ones chicken fiesta', 'weight watchers fiesta chicken', 'smartones fiesta chicken'],
 'frozen_meals', 'Smart Ones', 1, '250 cal per package (255g, 9oz). Chicken with rice, beans, corn and peppers in zesty sauce.', TRUE),

-- Smart Ones Broccoli & Cheddar Roasted Potatoes: 200 cal per package (255g)
('smartones_broccoli_cheddar_potato', 'Smart Ones Broccoli & Cheddar Roasted Potatoes', 78, 3.5, 10.2, 2.7,
 1.6, 1.2, 255, NULL,
 'manufacturer', ARRAY['smart ones broccoli cheddar potatoes', 'smart ones broccoli cheddar', 'weight watchers broccoli cheddar potato', 'smartones broccoli cheddar roasted potatoes'],
 'frozen_meals', 'Smart Ones', 1, '200 cal per package (255g, 9oz). Roasted potatoes with broccoli and cheddar cheese sauce.', TRUE),

-- Smart Ones Pasta with Swedish Meatballs: 290 cal per package (258g, 9.12oz)
('smartones_swedish_meatballs', 'Smart Ones Pasta with Swedish Meatballs', 112, 7.0, 15.9, 1.9,
 1.2, 2.7, 258, NULL,
 'manufacturer', ARRAY['smart ones swedish meatballs', 'smart ones meatballs', 'weight watchers swedish meatballs', 'smartones pasta with swedish meatballs'],
 'frozen_meals', 'Smart Ones', 1, '290 cal per package (258g, 9.12oz). Swedish meatballs in creamy sauce over pasta.', TRUE),

-- Smart Ones Slow Roasted Turkey Breast: 170 cal per package (255g)
('smartones_slow_roasted_turkey', 'Smart Ones Slow Roasted Turkey Breast', 67, 7.5, 5.9, 2.0,
 0.8, 1.2, 255, NULL,
 'manufacturer', ARRAY['smart ones turkey breast', 'smart ones slow roasted turkey', 'weight watchers turkey breast', 'smartones slow roasted turkey breast mashed potatoes'],
 'frozen_meals', 'Smart Ones', 1, '170 cal per package (255g, 9oz). Slow roasted turkey breast with gravy and garlic-herb mashed potatoes. Excellent protein source.', TRUE),

-- ══════════════════════════════════════════
-- EVOL — LEAN & FIT BOWLS
-- ══════════════════════════════════════════

-- Evol Chicken Tikka Masala: 270 cal per bowl (255g)
('evol_chicken_tikka_masala', 'Evol Chicken Tikka Masala', 106, 4.7, 14.1, 3.5,
 1.2, 2.4, 255, NULL,
 'manufacturer', ARRAY['evol chicken tikka masala', 'evol tikka masala', 'evol lean fit tikka masala', 'evol chicken tikka masala bowl'],
 'frozen_meals', 'Evol', 1, '270 cal per bowl (255g, 9oz). Gluten-free. White meat chicken, white rice, carrots, peas and onions with tikka masala sauce.', TRUE),

-- Evol Teriyaki Chicken: 280 cal per bowl (255g)
('evol_teriyaki_chicken', 'Evol Teriyaki Chicken', 110, 5.5, 18.4, 1.2,
 1.2, 2.0, 255, NULL,
 'manufacturer', ARRAY['evol teriyaki chicken', 'evol lean fit teriyaki chicken', 'evol teriyaki chicken bowl', 'evol teriyaki'],
 'frozen_meals', 'Evol', 1, '280 cal per bowl (255g, 9oz). Gluten-free. Grilled white meat chicken with brown rice, carrots, peppers, snap peas, broccoli and teriyaki sauce.', TRUE),

-- Evol Truffle Parmesan Mac & Cheese: 460 cal per bowl (227g, 8oz)
('evol_truffle_parmesan_mac', 'Evol Truffle Parmesan Mac & Cheese', 203, 5.7, 19.4, 11.0,
 0.9, 2.2, 227, NULL,
 'manufacturer', ARRAY['evol truffle parmesan mac', 'evol mac and cheese', 'evol truffle mac cheese', 'evol truffle parmesan mac and cheese'],
 'frozen_meals', 'Evol', 1, '460 cal per bowl (227g, 8oz). Vegetarian. Tubetti pasta with truffle parmesan cheese sauce and panko breadcrumbs.', TRUE),

-- ══════════════════════════════════════════
-- EVOL — BURRITOS
-- ══════════════════════════════════════════

-- Evol Cilantro Lime Chicken Burrito: 310 cal per burrito (170g, 6oz)
('evol_cilantro_lime_chicken', 'Evol Cilantro Lime Chicken Burrito', 182, 8.2, 25.3, 4.7,
 1.8, 1.2, NULL, 170,
 'manufacturer', ARRAY['evol cilantro lime chicken burrito', 'evol cilantro lime chicken', 'evol chicken burrito', 'evol cilantro lime burrito'],
 'frozen_meals', 'Evol', 1, '310 cal per burrito (170g, 6oz). Chicken, rice, beans and cilantro lime salsa in a flour tortilla.', TRUE),

-- Evol Egg & Green Chile Burrito: 320 cal per burrito (170g, 6oz)
('evol_egg_green_chile', 'Evol Egg & Green Chile Burrito', 188, 7.1, 26.5, 5.9,
 2.9, 1.2, NULL, 170,
 'manufacturer', ARRAY['evol egg green chile burrito', 'evol breakfast burrito', 'evol egg and green chile', 'evol egg green chile breakfast burrito'],
 'frozen_meals', 'Evol', 1, '320 cal per burrito (170g, 6oz). Vegetarian. Cage-free scrambled eggs, roasted potatoes, pinto beans, cheddar and green chile.', TRUE),

-- Evol Shredded Beef Burrito: 320 cal per burrito (170g, 6oz)
('evol_shredded_beef', 'Evol Shredded Beef Burrito', 188, 8.2, 27.6, 5.3,
 2.4, 1.8, NULL, 170,
 'manufacturer', ARRAY['evol shredded beef burrito', 'evol beef burrito', 'evol shredded beef', 'evol beef burrito frozen'],
 'frozen_meals', 'Evol', 1, '320 cal per burrito (170g, 6oz). Tender beef, pinto beans, rice, cheddar, roasted corn and tomato salsa. Beef raised without antibiotics.', TRUE),

-- ══════════════════════════════════════════
-- ATKINS — FROZEN MEALS (LOW CARB)
-- ══════════════════════════════════════════

-- Atkins Chicken Broccoli Alfredo: 330 cal per tray (255g, 9oz)
('atkins_frozen_chicken_broccoli_alfredo', 'Atkins Chicken & Broccoli Alfredo', 129, 10.2, 3.5, 7.8,
 1.6, 0.8, 255, NULL,
 'manufacturer', ARRAY['atkins chicken broccoli alfredo', 'atkins chicken alfredo', 'atkins frozen chicken broccoli alfredo', 'atkins low carb chicken alfredo'],
 'frozen_meals', 'Atkins', 1, '330 cal per tray (255g, 9oz). 26g protein, 5g net carbs. Low-carb chicken and broccoli in Alfredo sauce.', TRUE),

-- Atkins Meatloaf with Portobello Mushroom Gravy: 330 cal per tray (255g, 9oz)
('atkins_frozen_meatloaf', 'Atkins Meatloaf with Portobello Mushroom Gravy', 129, 9.4, 4.7, 8.2,
 1.6, 0.8, 255, NULL,
 'manufacturer', ARRAY['atkins meatloaf', 'atkins meatloaf portobello', 'atkins frozen meatloaf', 'atkins meatloaf mushroom gravy'],
 'frozen_meals', 'Atkins', 1, '330 cal per tray (255g, 9oz). 24g protein, 8g net carbs. Meatloaf with portobello mushroom gravy, cauliflower, green beans and zucchini.', TRUE),

-- Atkins Beef Teriyaki Stir-Fry: 260 cal per tray (227g, 8oz)
('atkins_frozen_beef_teriyaki', 'Atkins Beef Teriyaki Stir-Fry', 115, 7.0, 4.4, 7.9,
 1.8, 1.3, 227, NULL,
 'manufacturer', ARRAY['atkins beef teriyaki', 'atkins beef teriyaki stir fry', 'atkins frozen beef teriyaki', 'atkins low carb beef teriyaki'],
 'frozen_meals', 'Atkins', 1, '260 cal per tray (227g, 8oz). 16g protein, 6g net carbs. Beef, broccoli, carrots and bamboo shoots in teriyaki sauce.', TRUE),

-- Atkins Crustless Chicken Pot Pie: 330 cal per bowl (255g, 9oz)
('atkins_frozen_chicken_pot_pie', 'Atkins Crustless Chicken Pot Pie', 129, 8.6, 3.1, 8.6,
 0.8, 0.8, 255, NULL,
 'manufacturer', ARRAY['atkins chicken pot pie', 'atkins crustless pot pie', 'atkins frozen chicken pot pie', 'atkins crustless chicken pot pie'],
 'frozen_meals', 'Atkins', 1, '330 cal per bowl (255g, 9oz). 22g protein, 6g net carbs. White meat chicken, broccoli, cauliflower, spinach, carrots in sherry herb cream sauce.', TRUE),

-- Atkins Chili Con Carne: 320 cal per bowl (255g, 9oz)
('atkins_frozen_chili_con_carne', 'Atkins Chili Con Carne', 125, 9.4, 3.1, 8.2,
 1.6, 0.8, 255, NULL,
 'manufacturer', ARRAY['atkins chili con carne', 'atkins chili', 'atkins frozen chili', 'atkins low carb chili con carne'],
 'frozen_meals', 'Atkins', 1, '320 cal per bowl (255g, 9oz). 24g protein, 4g net carbs. Ground beef with peppers and tomatoes in chili sauce, topped with cheddar.', TRUE),

-- ══════════════════════════════════════════
-- FRESHLY — PREPARED MEALS
-- ══════════════════════════════════════════

-- Freshly Steak Peppercorn: 470 cal per tray (394g)
('freshly_steak_peppercorn', 'Freshly Steak Peppercorn', 119, 7.4, 8.9, 6.1,
 1.3, 1.5, 394, NULL,
 'manufacturer', ARRAY['freshly steak peppercorn', 'freshly steak', 'freshly peppercorn steak', 'freshly steak peppercorn sauteed carrots green beans'],
 'frozen_meals', 'Freshly', 1, '470 cal per tray (394g). Steak peppercorn with sauteed carrots and French green beans. 29g protein per serving.', TRUE),

-- Freshly Buffalo Chicken: 470 cal per tray (340g)
('freshly_buffalo_chicken', 'Freshly Buffalo Chicken', 138, 11.2, 4.7, 8.2,
 1.2, 1.5, 340, NULL,
 'manufacturer', ARRAY['freshly buffalo chicken', 'freshly buffalo chicken breast', 'freshly buffalo chicken loaded cauliflower', 'freshly buffalo'],
 'frozen_meals', 'Freshly', 1, '470 cal per tray (~340g). Buffalo chicken breast with loaded cauliflower. 38g protein per serving. High protein.', TRUE),

-- Freshly Chicken Pesto: 500 cal per tray (354g)
('freshly_chicken_pesto', 'Freshly Chicken Pesto Bowl', 141, 7.9, 11.3, 7.1,
 1.4, 1.7, 354, NULL,
 'manufacturer', ARRAY['freshly chicken pesto', 'freshly pesto chicken', 'freshly chicken pesto bowl', 'freshly pesto chicken bowl'],
 'frozen_meals', 'Freshly', 1, '500 cal per tray (354g). Chicken pesto bowl with vegetables. 28g protein per serving.', TRUE),

-- Freshly Teriyaki Chicken: 430 cal per tray (340g)
('freshly_teriyaki_chicken', 'Freshly Teriyaki Chicken', 126, 7.9, 15.9, 3.5,
 1.2, 2.4, 340, NULL,
 'manufacturer', ARRAY['freshly teriyaki chicken', 'freshly chicken teriyaki', 'freshly teriyaki', 'freshly teriyaki chicken bowl'],
 'frozen_meals', 'Freshly', 1, '430 cal per tray (~340g). Teriyaki chicken with rice and vegetables. 27g protein per serving.', TRUE),

-- Freshly Sicilian-Style Chicken Parm: 410 cal per tray (356g)
('freshly_sicilian_chicken', 'Freshly Sicilian-Style Chicken Parm', 115, 7.6, 8.4, 5.3,
 1.1, 1.7, 356, NULL,
 'manufacturer', ARRAY['freshly sicilian chicken', 'freshly chicken parm', 'freshly sicilian chicken parm', 'freshly sicilian style chicken parmigiana'],
 'frozen_meals', 'Freshly', 1, '410 cal per tray (356g). Sicilian-style chicken parmigiana with broccoli. 27g protein per serving.', TRUE),

-- ══════════════════════════════════════════
-- HEALTHY CHOICE — POWER BOWLS
-- ══════════════════════════════════════════

-- Healthy Choice Power Bowl Chicken Feta & Farro: 310 cal per bowl (269g, 9.5oz)
('hc_power_chicken_feta_farro', 'Healthy Choice Power Bowl Chicken Feta & Farro', 115, 8.6, 12.6, 3.3,
 2.2, 0.7, 269, NULL,
 'manufacturer', ARRAY['healthy choice chicken feta farro', 'healthy choice power bowl chicken feta', 'hc power bowl feta farro', 'healthy choice chicken feta and farro power bowl'],
 'frozen_meals', 'Healthy Choice', 1, '310 cal per bowl (269g, 9.5oz). 23g protein, 6g fiber. Chicken, feta, farro and vegetables. No preservatives.', TRUE),

-- Healthy Choice Power Bowl Korean-Inspired Beef: 310 cal per bowl (269g, 9.5oz)
('hc_power_korean_beef', 'Healthy Choice Power Bowl Korean-Inspired Beef', 115, 5.6, 13.8, 3.7,
 1.9, 2.2, 269, NULL,
 'manufacturer', ARRAY['healthy choice korean beef', 'healthy choice power bowl korean beef', 'hc power bowl korean inspired beef', 'healthy choice korean inspired beef bowl'],
 'frozen_meals', 'Healthy Choice', 1, '310 cal per bowl (269g, 9.5oz). 15g protein, 5g fiber. USDA choice beef, mushrooms, vegetables on brown/red rice, quinoa and barley with gochujang soy sauce.', TRUE),

-- Healthy Choice Power Bowl Adobo Chicken: 330 cal per bowl (276g, 9.75oz)
('hc_power_adobo_chicken', 'Healthy Choice Power Bowl Adobo Chicken', 120, 9.4, 12.7, 3.6,
 2.9, 1.4, 276, NULL,
 'manufacturer', ARRAY['healthy choice adobo chicken', 'healthy choice power bowl adobo chicken', 'hc power bowl adobo chicken', 'healthy choice adobo chicken power bowl'],
 'frozen_meals', 'Healthy Choice', 1, '330 cal per bowl (276g, 9.75oz). 26g protein, 8g fiber. Adobo chicken with whole grains and vegetables. No preservatives.', TRUE),

-- Healthy Choice Power Bowl Cauliflower Butternut Squash: 290 cal per bowl (269g, 9.5oz)
('hc_power_cauliflower_butternut', 'Healthy Choice Power Bowl Cauliflower Butternut Squash', 108, 2.6, 18.6, 1.3,
 2.6, 3.0, 269, NULL,
 'manufacturer', ARRAY['healthy choice cauliflower butternut', 'healthy choice power bowl cauliflower butternut squash', 'hc power bowl cauliflower butternut', 'healthy choice cauliflower butternut squash bowl'],
 'frozen_meals', 'Healthy Choice', 1, '290 cal per bowl (269g, 9.5oz). Plant-based with cauliflower, butternut squash, and whole grains. 7g protein, 7g fiber.', TRUE)

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
