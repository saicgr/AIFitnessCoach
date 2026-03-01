-- ============================================================================
-- Batch 31: Common Prepared Meals & Dishes
-- Categories: Sandwiches, Salads, Soups, Pasta, Meat Mains, Sides,
--             Rice/Grain Bowls, Mexican/Tex-Mex, Asian-American, Pizza, Wraps
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central, nutritionvalue.org, fatsecret.com,
--          calorieking.com, nutritionix.com, myfitnesspal.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- SANDWICHES (food_category = 'sandwiches')
-- ============================================================================

-- PB&J Sandwich: ~350 cal per sandwich (~92g) — USDA #27064
('pbj_sandwich', 'PB&J Sandwich', 380.4, 12.0, 44.6, 17.4, 3.0, 18.5, 92, 92, 'usda', ARRAY['peanut butter jelly sandwich', 'peanut butter and jelly', 'pb and j', 'pbj'], '350 cal per sandwich (92g). White bread, peanut butter, grape jelly.', NULL, 'sandwiches', 1),

-- BLT Sandwich: ~320 cal per sandwich (~140g)
('blt_sandwich', 'BLT Sandwich', 228.6, 8.6, 17.1, 14.3, 1.4, 3.2, 140, 140, 'usda', ARRAY['blt', 'bacon lettuce tomato sandwich', 'bacon lettuce tomato'], '320 cal per sandwich (140g). Bacon, lettuce, tomato, mayo on toasted bread.', NULL, 'sandwiches', 1),

-- Turkey & Cheese Sandwich: ~350 cal per sandwich (~170g)
('turkey_cheese_sandwich', 'Turkey & Cheese Sandwich', 205.9, 12.9, 17.6, 9.4, 1.2, 2.9, 170, 170, 'usda', ARRAY['turkey sandwich', 'turkey and cheese sandwich', 'turkey cheese sub'], '350 cal per sandwich (170g). Deli turkey, American cheese, lettuce, mayo on white bread.', NULL, 'sandwiches', 1),

-- Ham & Cheese Sandwich: ~360 cal per sandwich (~160g)
('ham_cheese_sandwich', 'Ham & Cheese Sandwich', 225.0, 13.1, 17.5, 11.3, 1.0, 3.0, 160, 160, 'usda', ARRAY['ham sandwich', 'ham and cheese sandwich', 'ham and cheese'], '360 cal per sandwich (160g). Deli ham, American cheese, mustard on white bread.', NULL, 'sandwiches', 1),

-- Grilled Cheese Sandwich: ~370 cal per sandwich (~120g)
('grilled_cheese_sandwich', 'Grilled Cheese Sandwich', 308.3, 11.7, 25.0, 18.3, 1.0, 3.3, 120, 120, 'usda', ARRAY['grilled cheese', 'cheese sandwich grilled', 'toasted cheese sandwich'], '370 cal per sandwich (120g). American cheese on buttered white bread, grilled.', NULL, 'sandwiches', 1),

-- Tuna Salad Sandwich: ~370 cal per sandwich (~170g)
('tuna_salad_sandwich', 'Tuna Salad Sandwich', 217.6, 12.4, 16.5, 11.2, 1.0, 2.8, 170, 170, 'usda', ARRAY['tuna sandwich', 'tuna salad sub', 'tuna melt'], '370 cal per sandwich (170g). Tuna salad with mayo on white bread.', NULL, 'sandwiches', 1),

-- Egg Salad Sandwich: ~340 cal per sandwich (~150g)
('egg_salad_sandwich', 'Egg Salad Sandwich', 226.7, 9.3, 17.3, 13.3, 0.8, 2.5, 150, 150, 'usda', ARRAY['egg sandwich', 'egg salad sub', 'egg salad on bread'], '340 cal per sandwich (150g). Egg salad with mayo on white bread.', NULL, 'sandwiches', 1),

-- Club Sandwich: ~540 cal per sandwich (~300g)
('club_sandwich', 'Club Sandwich', 180.0, 11.7, 12.0, 9.7, 0.8, 2.0, 300, 300, 'usda', ARRAY['club sub', 'triple decker sandwich', 'turkey club sandwich'], '540 cal per sandwich (300g). Turkey, bacon, lettuce, tomato, mayo on toasted triple-decker.', NULL, 'sandwiches', 1),

-- Chicken Salad Sandwich: ~380 cal per sandwich (~170g)
('chicken_salad_sandwich', 'Chicken Salad Sandwich', 223.5, 11.8, 16.5, 12.9, 1.0, 2.4, 170, 170, 'usda', ARRAY['chicken salad sub', 'chicken salad on bread'], '380 cal per sandwich (170g). Chicken salad with mayo, celery on white bread.', NULL, 'sandwiches', 1),

-- Reuben Sandwich: ~520 cal per sandwich (~280g)
('reuben_sandwich', 'Reuben Sandwich', 185.7, 11.4, 13.9, 9.6, 1.1, 2.5, 280, 280, 'usda', ARRAY['reuben', 'reuben on rye', 'corned beef reuben'], '520 cal per sandwich (280g). Corned beef, Swiss cheese, sauerkraut, Russian dressing on rye.', NULL, 'sandwiches', 1),

-- Monte Cristo Sandwich: ~620 cal per sandwich (~260g)
('monte_cristo_sandwich', 'Monte Cristo Sandwich', 238.5, 12.3, 18.5, 13.5, 0.5, 5.0, 260, 260, 'usda', ARRAY['monte cristo', 'fried ham and cheese sandwich'], '620 cal per sandwich (260g). Ham, turkey, Swiss cheese, battered and fried, dusted with powdered sugar.', NULL, 'sandwiches', 1),

-- Meatball Sub: ~480 cal per sub (~280g)
('meatball_sub', 'Meatball Sub', 171.4, 9.3, 16.4, 7.9, 1.4, 4.3, 280, 280, 'usda', ARRAY['meatball sandwich', 'meatball sub sandwich', 'meatball hero', 'meatball hoagie'], '480 cal per sub (280g). Beef meatballs, marinara, mozzarella on sub roll.', NULL, 'sandwiches', 1),

-- ============================================================================
-- SALADS (food_category = 'salads')
-- ============================================================================

-- Caesar Salad (with dressing, no chicken): ~200 cal per serving (~200g)
('caesar_salad', 'Caesar Salad (with Dressing)', 100.0, 3.5, 5.0, 7.5, 1.5, 1.0, NULL, 200, 'usda', ARRAY['caesar salad', 'caesar salad no chicken', 'side caesar'], '200 cal per serving (200g). Romaine, Parmesan, croutons, Caesar dressing.', NULL, 'salads', 1),

-- Caesar Salad with Grilled Chicken: ~370 cal per serving (~320g)
('caesar_salad_chicken', 'Caesar Salad with Grilled Chicken', 115.6, 10.6, 4.7, 6.3, 1.0, 0.8, NULL, 320, 'usda', ARRAY['chicken caesar salad', 'grilled chicken caesar', 'caesar with chicken'], '370 cal per serving (320g). Romaine, grilled chicken breast, Parmesan, croutons, Caesar dressing.', NULL, 'salads', 1),

-- Cobb Salad: ~450 cal per serving (~350g)
('cobb_salad', 'Cobb Salad', 128.6, 9.7, 4.3, 8.6, 1.7, 1.4, NULL, 350, 'usda', ARRAY['cobb salad', 'cobb salad with dressing'], '450 cal per serving (350g). Greens, chicken, bacon, egg, avocado, blue cheese, tomato, dressing.', NULL, 'salads', 1),

-- Garden Salad (no dressing): ~35 cal per serving (~150g)
('garden_salad_no_dressing', 'Garden Salad (No Dressing)', 23.3, 1.3, 4.0, 0.2, 1.5, 2.0, NULL, 150, 'usda', ARRAY['garden salad', 'side salad', 'house salad no dressing', 'tossed salad'], '35 cal per serving (150g). Mixed greens, tomato, cucumber, carrot, no dressing.', NULL, 'salads', 1),

-- Greek Salad: ~220 cal per serving (~250g)
('greek_salad', 'Greek Salad', 88.0, 3.6, 5.2, 6.4, 1.2, 2.8, NULL, 250, 'usda', ARRAY['greek salad', 'greek salad with feta', 'horiatiki salad'], '220 cal per serving (250g). Tomato, cucumber, red onion, olives, feta, olive oil dressing.', NULL, 'salads', 1),

-- Tuna Salad (the salad itself, no bread): ~190 cal per serving (~120g)
('tuna_salad', 'Tuna Salad', 158.3, 15.0, 2.5, 10.0, 0.0, 1.2, NULL, 120, 'usda', ARRAY['tuna salad', 'tuna mayo salad', 'tuna fish salad'], '190 cal per serving (120g). Tuna mixed with mayo, celery, seasonings.', NULL, 'salads', 1),

-- Chicken Salad (the salad itself, no bread): ~210 cal per serving (~120g)
('chicken_salad', 'Chicken Salad', 175.0, 14.2, 2.5, 12.1, 0.3, 1.0, NULL, 120, 'usda', ARRAY['chicken salad', 'chicken mayo salad'], '210 cal per serving (120g). Chicken mixed with mayo, celery, onion.', NULL, 'salads', 1),

-- Waldorf Salad: ~180 cal per serving (~150g)
('waldorf_salad', 'Waldorf Salad', 120.0, 1.3, 10.0, 8.7, 1.3, 7.3, NULL, 150, 'usda', ARRAY['waldorf salad', 'apple walnut salad'], '180 cal per serving (150g). Apples, celery, walnuts, grapes, mayo dressing.', NULL, 'salads', 1),

-- ============================================================================
-- SOUPS (food_category = 'soups')
-- ============================================================================

-- Chicken Noodle Soup: ~60 cal per cup (~245g)
('chicken_noodle_soup', 'Chicken Noodle Soup', 24.5, 1.6, 3.3, 0.5, 0.2, 0.4, NULL, 245, 'usda', ARRAY['chicken noodle soup', 'chicken soup', 'chicken noodle'], '60 cal per cup (245g). Classic broth-based with chicken, egg noodles, carrots, celery.', NULL, 'soups', 1),

-- Tomato Soup: ~90 cal per cup (~245g)
('tomato_soup', 'Tomato Soup', 36.7, 0.8, 6.9, 0.8, 0.6, 4.5, NULL, 245, 'usda', ARRAY['tomato soup', 'cream of tomato soup', 'tomato bisque'], '90 cal per cup (245g). Classic creamy tomato soup.', NULL, 'soups', 1),

-- Minestrone Soup: ~80 cal per cup (~245g)
('minestrone_soup', 'Minestrone Soup', 32.7, 1.6, 5.3, 0.6, 1.0, 1.2, NULL, 245, 'usda', ARRAY['minestrone', 'minestrone soup', 'italian vegetable soup'], '80 cal per cup (245g). Italian vegetable soup with beans and pasta.', NULL, 'soups', 1),

-- New England Clam Chowder: ~190 cal per cup (~245g)
('clam_chowder', 'New England Clam Chowder', 77.6, 3.3, 7.8, 3.7, 0.4, 0.8, NULL, 245, 'usda', ARRAY['clam chowder', 'new england clam chowder', 'chowder'], '190 cal per cup (245g). Cream-based with clams, potatoes, onion.', NULL, 'soups', 1),

-- Lentil Soup: ~100 cal per cup (~245g)
('lentil_soup', 'Lentil Soup', 40.8, 2.9, 6.5, 0.4, 2.0, 0.8, NULL, 245, 'usda', ARRAY['lentil soup', 'red lentil soup', 'dal soup'], '100 cal per cup (245g). Hearty lentil soup with vegetables.', NULL, 'soups', 1),

-- Vegetable Beef Soup: ~85 cal per cup (~245g)
('vegetable_beef_soup', 'Vegetable Beef Soup', 34.7, 2.9, 3.7, 0.8, 0.6, 0.8, NULL, 245, 'usda', ARRAY['vegetable beef soup', 'beef vegetable soup', 'beef stew soup'], '85 cal per cup (245g). Beef broth with beef chunks, mixed vegetables.', NULL, 'soups', 1),

-- Broccoli Cheddar Soup: ~200 cal per cup (~245g)
('broccoli_cheddar_soup', 'Broccoli Cheddar Soup', 81.6, 3.3, 5.3, 5.3, 0.6, 1.2, NULL, 245, 'usda', ARRAY['broccoli cheddar soup', 'broccoli cheese soup', 'cream of broccoli'], '200 cal per cup (245g). Creamy broccoli and cheddar cheese soup.', NULL, 'soups', 1),

-- French Onion Soup: ~170 cal per cup (~245g) with bread and cheese
('french_onion_soup', 'French Onion Soup', 69.4, 3.7, 6.5, 3.3, 0.4, 2.0, NULL, 245, 'usda', ARRAY['french onion soup', 'onion soup', 'french onion soup gratinee'], '170 cal per cup (245g). Caramelized onion broth with bread and melted Gruyere.', NULL, 'soups', 1),

-- Split Pea Soup: ~120 cal per cup (~245g)
('split_pea_soup', 'Split Pea Soup', 49.0, 3.3, 7.3, 0.6, 1.6, 1.2, NULL, 245, 'usda', ARRAY['split pea soup', 'pea soup', 'split pea and ham'], '120 cal per cup (245g). Split peas simmered with ham, carrots, onion.', NULL, 'soups', 1),

-- Chili Con Carne: ~240 cal per cup (~250g)
('chili_con_carne', 'Chili Con Carne', 96.0, 6.8, 8.0, 4.0, 2.4, 1.6, NULL, 250, 'usda', ARRAY['chili', 'chili con carne', 'beef chili', 'texas chili'], '240 cal per cup (250g). Ground beef, beans, tomatoes, chili spices.', NULL, 'soups', 1),

-- ============================================================================
-- PASTA DISHES (food_category = 'pasta')
-- ============================================================================

-- Spaghetti with Meat Sauce: ~140 cal/100g, ~420 cal per plate (~300g)
('spaghetti_meat_sauce', 'Spaghetti with Meat Sauce', 140.0, 6.3, 17.0, 5.0, 1.3, 3.0, NULL, 300, 'usda', ARRAY['spaghetti bolognese', 'spaghetti with meat sauce', 'pasta with meat sauce', 'spaghetti and meatballs sauce'], '420 cal per plate (300g). Spaghetti with ground beef tomato sauce.', NULL, 'pasta', 1),

-- Mac and Cheese (homemade): ~170 cal/100g, ~425 cal per serving (~250g)
('mac_and_cheese_homemade', 'Mac and Cheese (Homemade)', 170.0, 7.6, 17.2, 8.0, 0.6, 2.0, NULL, 250, 'usda', ARRAY['mac and cheese', 'macaroni and cheese', 'mac n cheese', 'homemade mac and cheese'], '425 cal per serving (250g). Elbow macaroni in cheddar cheese sauce.', NULL, 'pasta', 1),

-- Chicken Alfredo: ~165 cal/100g, ~495 cal per plate (~300g)
('chicken_alfredo', 'Chicken Alfredo Pasta', 165.0, 9.3, 14.7, 7.7, 0.5, 0.8, NULL, 300, 'usda', ARRAY['chicken alfredo', 'fettuccine alfredo with chicken', 'alfredo pasta'], '495 cal per plate (300g). Fettuccine in creamy Alfredo sauce with grilled chicken.', NULL, 'pasta', 1),

-- Lasagna (beef): ~150 cal/100g, ~450 cal per serving (~300g)
('lasagna_beef', 'Lasagna (Beef)', 150.0, 8.3, 12.0, 7.3, 0.7, 2.3, NULL, 300, 'usda', ARRAY['lasagna', 'beef lasagna', 'meat lasagna', 'lasagne'], '450 cal per serving (300g). Layered pasta with beef ragu, ricotta, mozzarella.', NULL, 'pasta', 1),

-- Baked Ziti: ~155 cal/100g, ~465 cal per serving (~300g)
('baked_ziti', 'Baked Ziti', 155.0, 7.7, 15.3, 7.0, 0.7, 2.3, NULL, 300, 'usda', ARRAY['baked ziti', 'ziti al forno', 'baked pasta'], '465 cal per serving (300g). Ziti with ricotta, mozzarella, and marinara.', NULL, 'pasta', 1),

-- Carbonara: ~190 cal/100g, ~475 cal per plate (~250g)
('pasta_carbonara', 'Pasta Carbonara', 190.0, 8.4, 18.0, 9.6, 0.6, 0.5, NULL, 250, 'usda', ARRAY['carbonara', 'spaghetti carbonara', 'pasta carbonara'], '475 cal per plate (250g). Pasta with egg, Pecorino, guanciale, black pepper.', NULL, 'pasta', 1),

-- Penne Arrabiata: ~130 cal/100g, ~390 cal per plate (~300g)
('penne_arrabiata', 'Penne Arrabiata', 130.0, 4.3, 21.0, 3.3, 1.3, 3.0, NULL, 300, 'usda', ARRAY['arrabiata', 'penne arrabiata', 'penne arrabbiata', 'spicy tomato pasta'], '390 cal per plate (300g). Penne in spicy garlic tomato sauce.', NULL, 'pasta', 1),

-- Shrimp Scampi Pasta: ~155 cal/100g, ~465 cal per plate (~300g)
('shrimp_scampi_pasta', 'Shrimp Scampi Pasta', 155.0, 8.3, 16.7, 6.0, 0.5, 0.5, NULL, 300, 'usda', ARRAY['shrimp scampi', 'shrimp scampi pasta', 'linguine shrimp scampi'], '465 cal per plate (300g). Linguine with shrimp in garlic butter white wine sauce.', NULL, 'pasta', 1),

-- ============================================================================
-- MEAT MAINS (food_category = 'proteins')
-- ============================================================================

-- Meatloaf: ~170 cal/100g, ~255 cal per slice (~150g)
('meatloaf', 'Meatloaf', 170.0, 12.0, 7.0, 10.5, 0.3, 2.5, 150, 150, 'usda', ARRAY['meatloaf', 'meat loaf', 'homemade meatloaf'], '255 cal per slice (150g). Ground beef meatloaf with ketchup glaze.', NULL, 'proteins', 1),

-- Meatballs (beef): ~220 cal/100g, ~66 cal per meatball (~30g)
('beef_meatballs', 'Beef Meatballs', 220.0, 14.0, 7.0, 15.0, 0.3, 1.0, 30, 120, 'usda', ARRAY['meatballs', 'beef meatballs', 'italian meatballs', 'homemade meatballs'], '264 cal per 4 meatballs (120g). Ground beef meatballs with breadcrumbs and herbs.', NULL, 'proteins', 4),

-- Pot Roast: ~155 cal/100g, ~310 cal per serving (~200g)
('pot_roast', 'Pot Roast', 155.0, 18.0, 4.0, 7.0, 0.5, 1.0, NULL, 200, 'usda', ARRAY['pot roast', 'beef pot roast', 'chuck roast', 'braised beef'], '310 cal per serving (200g). Slow-braised beef chuck with vegetables and gravy.', NULL, 'proteins', 1),

-- Beef Stew: ~100 cal/100g, ~300 cal per serving (~300g)
('beef_stew', 'Beef Stew', 100.0, 7.0, 7.3, 4.3, 0.8, 1.3, NULL, 300, 'usda', ARRAY['beef stew', 'stew beef', 'homemade beef stew'], '300 cal per serving (300g). Beef chunks, potatoes, carrots, onions in gravy.', NULL, 'proteins', 1),

-- Beef Stroganoff: ~140 cal/100g, ~420 cal per serving (~300g)
('beef_stroganoff', 'Beef Stroganoff', 140.0, 8.3, 10.7, 7.0, 0.3, 1.0, NULL, 300, 'usda', ARRAY['beef stroganoff', 'stroganoff', 'beef stroganoff with noodles'], '420 cal per serving (300g). Beef strips in sour cream mushroom sauce over egg noodles.', NULL, 'proteins', 1),

-- Shepherd's Pie: ~120 cal/100g, ~360 cal per serving (~300g)
('shepherds_pie', 'Shepherd''s Pie', 120.0, 6.3, 10.7, 5.3, 1.0, 1.3, NULL, 300, 'usda', ARRAY['shepherds pie', 'shepherd''s pie', 'cottage pie'], '360 cal per serving (300g). Ground lamb/beef with vegetables, topped with mashed potatoes.', NULL, 'proteins', 1),

-- Chicken Pot Pie: ~175 cal/100g, ~525 cal per serving (~300g)
('chicken_pot_pie', 'Chicken Pot Pie', 175.0, 6.7, 15.3, 9.7, 0.7, 1.3, NULL, 300, 'usda', ARRAY['chicken pot pie', 'pot pie', 'chicken pie'], '525 cal per serving (300g). Chicken, vegetables in creamy sauce under flaky pastry crust.', NULL, 'proteins', 1),

-- Fried Chicken (bone-in, thigh): ~250 cal/100g, ~250 cal per piece (~100g)
('fried_chicken_bone_in', 'Fried Chicken (Bone-In)', 250.0, 17.0, 10.0, 15.5, 0.3, 0.2, 100, 100, 'usda', ARRAY['fried chicken', 'fried chicken thigh', 'southern fried chicken', 'bone in fried chicken'], '250 cal per piece (100g thigh). Seasoned flour-battered and deep-fried.', NULL, 'proteins', 1),

-- Baked Chicken Breast: ~165 cal/100g, ~248 cal per breast (~150g)
('baked_chicken_breast', 'Baked Chicken Breast', 165.0, 31.0, 0.0, 3.6, 0.0, 0.0, 150, 150, 'usda', ARRAY['baked chicken breast', 'roasted chicken breast', 'plain chicken breast', 'grilled chicken breast'], '248 cal per breast (150g). Skinless boneless chicken breast, baked with light seasoning.', NULL, 'proteins', 1),

-- Grilled Salmon Fillet: ~208 cal/100g, ~354 cal per fillet (~170g)
('grilled_salmon_fillet', 'Grilled Salmon Fillet', 208.0, 20.4, 0.0, 13.4, 0.0, 0.0, 170, 170, 'usda', ARRAY['salmon fillet', 'grilled salmon', 'baked salmon', 'salmon'], '354 cal per fillet (170g). Atlantic salmon fillet, grilled.', NULL, 'proteins', 1),

-- Fish Sticks (baked): ~190 cal/100g, ~57 cal per stick (~30g)
('fish_sticks_baked', 'Fish Sticks (Baked)', 190.0, 10.0, 17.0, 9.0, 0.5, 1.5, 30, 120, 'usda', ARRAY['fish sticks', 'fish fingers', 'baked fish sticks'], '228 cal per 4 sticks (120g). Breaded fish sticks, baked.', NULL, 'proteins', 4),

-- Crab Cakes: ~175 cal/100g, ~140 cal per cake (~80g)
('crab_cakes', 'Crab Cakes', 175.0, 13.8, 7.5, 10.0, 0.2, 0.5, 80, 160, 'usda', ARRAY['crab cakes', 'crab cake', 'maryland crab cakes'], '280 cal per 2 cakes (160g). Lump crab meat, breadcrumbs, Old Bay, pan-fried.', NULL, 'proteins', 2),

-- ============================================================================
-- SIDES (food_category = 'sides')
-- ============================================================================

-- Mashed Potatoes: ~100 cal/100g, ~210 cal per serving (~210g)
('mashed_potatoes', 'Mashed Potatoes', 100.0, 2.0, 14.0, 4.0, 1.3, 1.0, NULL, 210, 'usda', ARRAY['mashed potatoes', 'mashed potato', 'whipped potatoes'], '210 cal per serving (210g). With butter and milk.', NULL, 'sides', 1),

-- Loaded Baked Potato: ~140 cal/100g, ~420 cal per potato (~300g)
('loaded_baked_potato', 'Baked Potato (Loaded)', 140.0, 4.3, 15.0, 7.0, 1.3, 0.7, 300, 300, 'usda', ARRAY['loaded baked potato', 'baked potato with toppings', 'baked potato loaded'], '420 cal per potato (300g). Baked russet with butter, sour cream, cheese, bacon bits.', NULL, 'sides', 1),

-- French Fries (baked): ~150 cal/100g, ~270 cal per serving (~180g)
('french_fries_baked', 'French Fries (Baked)', 150.0, 2.3, 23.0, 5.3, 2.0, 0.3, NULL, 180, 'usda', ARRAY['baked fries', 'oven fries', 'baked french fries', 'oven baked fries'], '270 cal per serving (180g). Oven-baked potato fries.', NULL, 'sides', 1),

-- French Fries (fried): ~312 cal/100g, ~365 cal per serving (~117g)
('french_fries_fried', 'French Fries (Fried)', 312.0, 3.4, 36.0, 17.1, 3.0, 0.3, NULL, 117, 'usda', ARRAY['french fries', 'fries', 'fried french fries', 'deep fried fries'], '365 cal per serving (117g). Deep-fried potato fries.', NULL, 'sides', 1),

-- Coleslaw: ~110 cal/100g, ~165 cal per serving (~150g)
('coleslaw', 'Coleslaw', 110.0, 1.0, 10.7, 7.0, 1.3, 8.0, NULL, 150, 'usda', ARRAY['coleslaw', 'cole slaw', 'creamy coleslaw'], '165 cal per serving (150g). Shredded cabbage and carrots in creamy dressing.', NULL, 'sides', 1),

-- Corn on the Cob: ~96 cal per ear (~146g with butter)
('corn_on_the_cob', 'Corn on the Cob', 107.0, 3.4, 17.8, 3.4, 2.0, 3.4, 146, 146, 'usda', ARRAY['corn on the cob', 'sweet corn', 'buttered corn', 'corn cob'], '156 cal per ear (146g). Sweet corn with butter.', NULL, 'sides', 1),

-- Baked Beans: ~120 cal/100g, ~300 cal per serving (~250g)
('baked_beans', 'Baked Beans', 120.0, 5.2, 19.2, 2.0, 5.2, 8.8, NULL, 250, 'usda', ARRAY['baked beans', 'bbq baked beans', 'boston baked beans'], '300 cal per serving (250g). Navy beans in sweet tomato sauce.', NULL, 'sides', 1),

-- Potato Salad: ~140 cal/100g, ~280 cal per serving (~200g)
('potato_salad', 'Potato Salad', 140.0, 2.5, 13.0, 8.5, 1.0, 2.5, NULL, 200, 'usda', ARRAY['potato salad', 'creamy potato salad', 'american potato salad'], '280 cal per serving (200g). Potatoes, mayo, mustard, celery, eggs.', NULL, 'sides', 1),

-- Macaroni Salad: ~170 cal/100g, ~340 cal per serving (~200g)
('macaroni_salad', 'Macaroni Salad', 170.0, 3.5, 17.0, 9.5, 0.7, 3.0, NULL, 200, 'usda', ARRAY['macaroni salad', 'mac salad', 'pasta salad mayo'], '340 cal per serving (200g). Elbow macaroni, mayo, vegetables.', NULL, 'sides', 1),

-- Creamed Spinach: ~80 cal/100g, ~160 cal per serving (~200g)
('creamed_spinach', 'Creamed Spinach', 80.0, 3.0, 5.0, 5.0, 1.5, 1.0, NULL, 200, 'usda', ARRAY['creamed spinach', 'cream spinach', 'steakhouse spinach'], '160 cal per serving (200g). Spinach in cream sauce with garlic and Parmesan.', NULL, 'sides', 1),

-- ============================================================================
-- RICE/GRAIN BOWLS (food_category = 'bowls')
-- ============================================================================

-- Chicken Rice Bowl: ~145 cal/100g, ~508 cal per bowl (~350g)
('chicken_rice_bowl', 'Chicken Rice Bowl', 145.0, 9.1, 17.1, 4.6, 0.6, 0.9, NULL, 350, 'usda', ARRAY['chicken rice bowl', 'chicken and rice bowl', 'teriyaki chicken bowl'], '508 cal per bowl (350g). Grilled chicken over steamed rice with vegetables.', NULL, 'bowls', 1),

-- Beef Teriyaki Bowl: ~155 cal/100g, ~543 cal per bowl (~350g)
('beef_teriyaki_bowl', 'Beef Teriyaki Bowl', 155.0, 8.6, 18.6, 5.1, 0.5, 4.3, NULL, 350, 'usda', ARRAY['beef teriyaki bowl', 'teriyaki bowl', 'beef bowl'], '543 cal per bowl (350g). Teriyaki-glazed beef over rice with steamed vegetables.', NULL, 'bowls', 1),

-- Poke Bowl (tuna): ~130 cal/100g, ~455 cal per bowl (~350g)
('poke_bowl_tuna', 'Poke Bowl (Tuna)', 130.0, 9.7, 14.3, 3.7, 1.1, 2.3, NULL, 350, 'usda', ARRAY['poke bowl', 'tuna poke bowl', 'ahi poke bowl', 'poke'], '455 cal per bowl (350g). Sushi-grade tuna over rice with edamame, seaweed, sesame.', NULL, 'bowls', 1),

-- Burrito Bowl: ~130 cal/100g, ~520 cal per bowl (~400g)
('burrito_bowl', 'Burrito Bowl', 130.0, 7.5, 14.5, 4.5, 2.5, 1.3, NULL, 400, 'usda', ARRAY['burrito bowl', 'rice bowl mexican', 'chipotle bowl'], '520 cal per bowl (400g). Rice, beans, chicken or beef, salsa, cheese, sour cream, lettuce.', NULL, 'bowls', 1),

-- Acai Bowl: ~105 cal/100g, ~368 cal per bowl (~350g)
('acai_bowl', 'Acai Bowl', 105.0, 2.3, 17.7, 3.1, 2.3, 11.4, NULL, 350, 'usda', ARRAY['acai bowl', 'açaí bowl', 'acai smoothie bowl'], '368 cal per bowl (350g). Blended acai base topped with granola, banana, berries, honey.', NULL, 'bowls', 1),

-- Smoothie Bowl: ~95 cal/100g, ~333 cal per bowl (~350g)
('smoothie_bowl', 'Smoothie Bowl', 95.0, 2.9, 15.7, 2.6, 1.7, 10.0, NULL, 350, 'usda', ARRAY['smoothie bowl', 'fruit smoothie bowl', 'blended bowl'], '333 cal per bowl (350g). Blended frozen fruit base topped with granola, seeds, fruit.', NULL, 'bowls', 1),

-- Buddha Bowl: ~110 cal/100g, ~440 cal per bowl (~400g)
('buddha_bowl', 'Buddha Bowl', 110.0, 4.5, 14.0, 4.0, 3.0, 2.0, NULL, 400, 'usda', ARRAY['buddha bowl', 'grain bowl', 'nourish bowl', 'power bowl'], '440 cal per bowl (400g). Quinoa, roasted vegetables, chickpeas, avocado, tahini drizzle.', NULL, 'bowls', 1),

-- Mediterranean Grain Bowl: ~125 cal/100g, ~500 cal per bowl (~400g)
('mediterranean_grain_bowl', 'Grain Bowl (Mediterranean)', 125.0, 5.0, 15.5, 4.8, 2.3, 1.5, NULL, 400, 'usda', ARRAY['mediterranean bowl', 'mediterranean grain bowl', 'falafel bowl', 'med bowl'], '500 cal per bowl (400g). Farro or quinoa, hummus, falafel, cucumber, tomato, feta, olives.', NULL, 'bowls', 1),

-- ============================================================================
-- MEXICAN / TEX-MEX (food_category = 'mexican')
-- ============================================================================

-- Cheese Quesadilla: ~285 cal/100g, ~400 cal per quesadilla (~140g)
('cheese_quesadilla', 'Cheese Quesadilla', 285.0, 12.1, 22.1, 16.4, 1.0, 0.7, 140, 140, 'usda', ARRAY['cheese quesadilla', 'quesadilla', 'plain quesadilla'], '400 cal per quesadilla (140g). Flour tortilla with melted cheese, grilled.', NULL, 'mexican', 1),

-- Bean & Cheese Burrito: ~180 cal/100g, ~450 cal per burrito (~250g)
('bean_cheese_burrito', 'Bean & Cheese Burrito', 180.0, 7.6, 22.0, 6.8, 3.2, 0.8, 250, 250, 'usda', ARRAY['bean burrito', 'bean and cheese burrito', 'bean cheese burrito'], '450 cal per burrito (250g). Flour tortilla with refried beans and cheese.', NULL, 'mexican', 1),

-- Chicken Tacos (soft, 2 tacos): ~170 cal/100g, ~340 cal per 2 tacos (~200g)
('chicken_tacos_soft', 'Chicken Tacos (Soft Shell)', 170.0, 10.5, 14.0, 8.0, 1.5, 1.0, 100, 200, 'usda', ARRAY['chicken taco', 'chicken tacos', 'soft chicken taco', 'chicken taco soft'], '340 cal per 2 tacos (200g). Seasoned chicken in soft flour tortillas with lettuce, cheese, salsa.', NULL, 'mexican', 2),

-- Beef Tacos (hard shell, 2 tacos): ~190 cal/100g, ~342 cal per 2 tacos (~180g)
('beef_tacos_hard_shell', 'Beef Tacos (Hard Shell)', 190.0, 10.0, 14.4, 10.0, 1.7, 1.1, 90, 180, 'usda', ARRAY['beef taco', 'beef tacos', 'hard shell taco', 'crispy taco'], '342 cal per 2 tacos (180g). Seasoned ground beef in crispy corn shells with toppings.', NULL, 'mexican', 2),

-- Nachos (loaded): ~195 cal/100g, ~683 cal per plate (~350g)
('loaded_nachos', 'Nachos (Loaded)', 195.0, 7.7, 16.6, 11.1, 2.3, 1.4, NULL, 350, 'usda', ARRAY['nachos', 'loaded nachos', 'nachos supreme', 'nachos with cheese'], '683 cal per plate (350g). Tortilla chips with cheese, beans, beef, sour cream, salsa, jalapenos.', NULL, 'mexican', 1),

-- Chicken Enchiladas (2): ~135 cal/100g, ~405 cal per 2 enchiladas (~300g)
('chicken_enchiladas', 'Enchiladas (Chicken)', 135.0, 8.3, 10.7, 6.3, 1.3, 1.7, 150, 300, 'usda', ARRAY['chicken enchiladas', 'enchiladas', 'cheese enchiladas'], '405 cal per 2 enchiladas (300g). Corn tortillas filled with chicken, topped with salsa and cheese.', NULL, 'mexican', 2),

-- Pork Tamale: ~165 cal/100g, ~248 cal per tamale (~150g)
('pork_tamale', 'Tamale (Pork)', 165.0, 6.7, 16.7, 8.0, 1.3, 0.7, 150, 150, 'usda', ARRAY['tamale', 'pork tamale', 'tamales', 'mexican tamale'], '248 cal per tamale (150g). Corn masa filled with shredded pork, steamed in corn husk.', NULL, 'mexican', 1),

-- Taco Salad: ~115 cal/100g, ~460 cal per serving (~400g)
('taco_salad', 'Taco Salad', 115.0, 6.0, 9.5, 6.0, 1.8, 1.5, NULL, 400, 'usda', ARRAY['taco salad', 'taco salad bowl', 'mexican salad'], '460 cal per serving (400g). Seasoned beef, lettuce, cheese, tomato, sour cream in tortilla bowl.', NULL, 'mexican', 1),

-- ============================================================================
-- ASIAN-AMERICAN (food_category = 'asian')
-- ============================================================================

-- General Tso's Chicken: ~195 cal/100g, ~585 cal per serving (~300g)
('general_tsos_chicken', 'General Tso''s Chicken', 195.0, 10.3, 18.3, 9.0, 0.3, 8.0, NULL, 300, 'usda', ARRAY['general tso chicken', 'general tsos chicken', 'general tso''s', 'general tao chicken'], '585 cal per serving (300g). Battered fried chicken in sweet-spicy sauce.', NULL, 'asian', 1),

-- Chicken Lo Mein: ~135 cal/100g, ~405 cal per serving (~300g)
('chicken_lo_mein', 'Lo Mein (Chicken)', 135.0, 6.7, 15.7, 5.0, 0.7, 2.0, NULL, 300, 'usda', ARRAY['lo mein', 'chicken lo mein', 'lo mein noodles'], '405 cal per serving (300g). Soft wheat noodles stir-fried with chicken and vegetables.', NULL, 'asian', 1),

-- Veggie Chow Mein: ~120 cal/100g, ~360 cal per serving (~300g)
('veggie_chow_mein', 'Chow Mein (Veggie)', 120.0, 3.7, 17.3, 4.0, 1.3, 2.0, NULL, 300, 'usda', ARRAY['chow mein', 'vegetable chow mein', 'veggie chow mein'], '360 cal per serving (300g). Crispy noodles stir-fried with mixed vegetables.', NULL, 'asian', 1),

-- Egg Roll: ~215 cal/100g, ~172 cal per roll (~80g)
('egg_roll', 'Egg Roll', 215.0, 6.3, 21.3, 11.3, 1.3, 2.0, 80, 80, 'usda', ARRAY['egg roll', 'pork egg roll', 'chinese egg roll', 'spring roll fried'], '172 cal per roll (80g). Fried wrapper filled with pork, cabbage, and vegetables.', NULL, 'asian', 1),

-- Wonton Soup: ~35 cal/100g, ~140 cal per cup (~400g)
('wonton_soup', 'Wonton Soup', 35.0, 2.5, 3.5, 1.0, 0.1, 0.3, NULL, 400, 'usda', ARRAY['wonton soup', 'won ton soup', 'wonton broth'], '140 cal per bowl (400g). Pork-filled wontons in clear chicken broth.', NULL, 'asian', 1),

-- Hot & Sour Soup: ~30 cal/100g, ~120 cal per cup (~400g)
('hot_sour_soup', 'Hot & Sour Soup', 30.0, 2.0, 3.3, 0.8, 0.3, 0.5, NULL, 400, 'usda', ARRAY['hot and sour soup', 'hot sour soup', 'chinese hot sour soup'], '120 cal per bowl (400g). Tofu, mushrooms, bamboo shoots in spicy-sour broth.', NULL, 'asian', 1),

-- Kung Pao Chicken: ~175 cal/100g, ~525 cal per serving (~300g)
('kung_pao_chicken', 'Kung Pao Chicken', 175.0, 12.0, 10.3, 10.0, 1.0, 3.0, NULL, 300, 'usda', ARRAY['kung pao chicken', 'kung pao', 'gong bao chicken'], '525 cal per serving (300g). Chicken with peanuts, chili peppers in spicy sauce.', NULL, 'asian', 1),

-- Sweet & Sour Chicken: ~185 cal/100g, ~555 cal per serving (~300g)
('sweet_sour_chicken', 'Sweet & Sour Chicken', 185.0, 9.0, 22.0, 7.0, 0.5, 10.0, NULL, 300, 'usda', ARRAY['sweet and sour chicken', 'sweet sour chicken'], '555 cal per serving (300g). Battered fried chicken in sweet-sour pineapple sauce.', NULL, 'asian', 1),

-- Chicken Fried Rice: ~170 cal/100g, ~510 cal per serving (~300g)
('chicken_fried_rice', 'Fried Rice (Chicken)', 170.0, 7.3, 22.0, 6.0, 0.7, 0.5, NULL, 300, 'usda', ARRAY['fried rice', 'chicken fried rice', 'chinese fried rice'], '510 cal per serving (300g). Wok-fried rice with chicken, egg, vegetables, soy sauce.', NULL, 'asian', 1),

-- Beef & Broccoli Stir Fry: ~110 cal/100g, ~330 cal per serving (~300g)
('beef_broccoli', 'Beef & Broccoli Stir Fry', 110.0, 9.3, 6.0, 5.7, 1.0, 2.0, NULL, 300, 'usda', ARRAY['beef and broccoli', 'beef broccoli', 'beef broccoli stir fry'], '330 cal per serving (300g). Sliced beef and broccoli in garlic soy sauce.', NULL, 'asian', 1),

-- ============================================================================
-- PIZZA (food_category = 'pizza')
-- ============================================================================

-- Cheese Pizza (1 slice, 14" pie): ~267 cal/100g, ~267 cal per slice (~100g)
('cheese_pizza_slice', 'Cheese Pizza (1 Slice, 14")', 267.0, 11.0, 30.0, 11.5, 1.5, 3.5, 100, 100, 'usda', ARRAY['cheese pizza', 'cheese pizza slice', 'plain pizza', 'pizza slice'], '267 cal per slice (100g). Regular crust cheese pizza, 1/8 of 14-inch pie.', NULL, 'pizza', 1),

-- Pepperoni Pizza (1 slice, 14"): ~290 cal/100g, ~290 cal per slice (~100g)
('pepperoni_pizza_slice', 'Pepperoni Pizza (1 Slice, 14")', 290.0, 12.0, 28.0, 14.0, 1.5, 3.5, 100, 100, 'usda', ARRAY['pepperoni pizza', 'pepperoni pizza slice', 'pepperoni slice'], '290 cal per slice (100g). Regular crust pepperoni pizza, 1/8 of 14-inch pie.', NULL, 'pizza', 1),

-- Margherita Pizza (1 slice): ~240 cal/100g, ~216 cal per slice (~90g)
('margherita_pizza_slice', 'Margherita Pizza (1 Slice)', 240.0, 10.0, 28.0, 10.0, 1.5, 3.0, 90, 90, 'usda', ARRAY['margherita pizza', 'margherita slice', 'margarita pizza'], '216 cal per slice (90g). Thin crust with fresh mozzarella, tomato sauce, basil.', NULL, 'pizza', 1),

-- Veggie Pizza (1 slice): ~235 cal/100g, ~212 cal per slice (~90g)
('veggie_pizza_slice', 'Veggie Pizza (1 Slice)', 235.0, 9.5, 28.5, 9.5, 2.0, 4.0, 90, 90, 'usda', ARRAY['veggie pizza', 'vegetable pizza', 'veggie pizza slice'], '212 cal per slice (90g). Cheese pizza with peppers, onions, mushrooms, olives.', NULL, 'pizza', 1),

-- ============================================================================
-- WRAPS & OTHER SANDWICHES (food_category = 'sandwiches')
-- ============================================================================

-- Chicken Caesar Wrap: ~210 cal/100g, ~441 cal per wrap (~210g)
('chicken_caesar_wrap', 'Chicken Caesar Wrap', 210.0, 12.4, 15.7, 11.0, 1.0, 1.0, 210, 210, 'usda', ARRAY['chicken caesar wrap', 'caesar wrap', 'grilled chicken wrap'], '441 cal per wrap (210g). Grilled chicken, romaine, Parmesan, Caesar dressing in flour tortilla.', NULL, 'sandwiches', 1),

-- Turkey Wrap: ~180 cal/100g, ~360 cal per wrap (~200g)
('turkey_wrap', 'Turkey Wrap', 180.0, 10.5, 16.0, 8.0, 1.5, 1.5, 200, 200, 'usda', ARRAY['turkey wrap', 'turkey club wrap', 'deli turkey wrap'], '360 cal per wrap (200g). Deli turkey, lettuce, tomato, cheese, ranch in tortilla.', NULL, 'sandwiches', 1),

-- Falafel Wrap: ~205 cal/100g, ~410 cal per wrap (~200g)
('falafel_wrap', 'Falafel Wrap', 205.0, 7.0, 24.0, 9.0, 3.0, 2.0, 200, 200, 'usda', ARRAY['falafel wrap', 'falafel pita', 'falafel sandwich'], '410 cal per wrap (200g). Falafel balls, hummus, lettuce, tomato, tahini in pita.', NULL, 'sandwiches', 1),

-- Gyro: ~230 cal/100g, ~506 cal per gyro (~220g)
('gyro', 'Gyro', 230.0, 11.4, 18.2, 12.7, 1.0, 2.3, 220, 220, 'usda', ARRAY['gyro', 'lamb gyro', 'gyro sandwich', 'greek gyro'], '506 cal per gyro (220g). Lamb/beef gyro meat, pita, tomato, onion, tzatziki sauce.', NULL, 'sandwiches', 1),

-- Philly Cheesesteak: ~215 cal/100g, ~580 cal per sandwich (~270g)
('philly_cheesesteak', 'Philly Cheesesteak', 215.0, 12.6, 16.7, 11.1, 0.7, 2.2, 270, 270, 'usda', ARRAY['philly cheesesteak', 'cheesesteak', 'cheese steak', 'philly steak'], '580 cal per sandwich (270g). Shaved steak, Cheez Whiz/provolone, onions on hoagie roll.', NULL, 'sandwiches', 1),

-- Sloppy Joe: ~155 cal/100g, ~310 cal per sandwich (~200g)
('sloppy_joe', 'Sloppy Joe', 155.0, 8.5, 14.5, 7.0, 0.5, 5.0, 200, 200, 'usda', ARRAY['sloppy joe', 'sloppy joes', 'manwich'], '310 cal per sandwich (200g). Ground beef in sweet tomato sauce on hamburger bun.', NULL, 'sandwiches', 1),
