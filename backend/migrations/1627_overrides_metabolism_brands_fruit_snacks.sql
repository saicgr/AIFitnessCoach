-- 1627_overrides_metabolism_brands_fruit_snacks.sql
-- Bulletproof MCT/collagen, Jade Leaf matcha, Bragg ACV, Four Sigmatic mushroom coffee,
-- Laird Superfood creamers, That's It fruit bars, Bare Snacks chips,
-- Dole fruit cups, Natierra freeze-dried fruit.
-- Sources: Package nutrition labels via fatsecret.com, nutritionix.com,
-- eatthismuch.com, nutritionvalue.org, manufacturer websites.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = label serving.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- BULLETPROOF — MCT OIL, COFFEE, COLLAGEN
-- ══════════════════════════════════════════

-- Bulletproof Brain Octane MCT Oil: 130 cal per 1 tbsp (15ml ~14g)
('bulletproof_brain_octane_mct_oil', 'Bulletproof Brain Octane C8 MCT Oil', 929, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'manufacturer', ARRAY['bulletproof mct oil', 'bulletproof brain octane', 'brain octane c8 mct oil', 'bulletproof brain octane oil'],
 'mct_oil', 'Bulletproof', 1, '130 cal per tbsp (14g). 100% C8 MCT oil from coconuts. Triple-distilled, keto energy supplement. Pure fat, no protein or carbs.', TRUE),

-- Bulletproof Ground Coffee: 0 cal per serving (10g)
('bulletproof_ground_coffee', 'Bulletproof Ground Coffee', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 10, NULL,
 'manufacturer', ARRAY['bulletproof coffee', 'bulletproof ground coffee', 'bulletproof coffee grounds', 'bulletproof medium roast coffee'],
 'coffee', 'Bulletproof', 1, '0 cal per serving (10g dry grounds). Clean, mold-free coffee beans. Medium roast, single-origin.', TRUE),

-- Bulletproof Collagen Protein: 45 cal per scoop (12g)
('bulletproof_collagen_protein', 'Bulletproof Collagen Protein Powder', 375, 83.3, 0.0, 0.0,
 0.0, 0.0, 20, NULL,
 'manufacturer', ARRAY['bulletproof collagen', 'bulletproof collagen protein', 'bulletproof collagen peptides', 'bulletproof unflavored collagen'],
 'collagen', 'Bulletproof', 1, '45 cal per scoop (12g). Grass-fed collagen peptides types I and III. 10g protein per scoop. Unflavored, mixes in hot or cold.', TRUE),

-- Bulletproof InnerFuel Prebiotic: 35 cal per 2 scoops (19g)
('bulletproof_innerfuel_prebiotic', 'Bulletproof InnerFuel Prebiotic', 184, 0.0, 89.5, 0.0,
 31.6, 0.0, 12, NULL,
 'manufacturer', ARRAY['bulletproof innerfuel', 'bulletproof prebiotic', 'bulletproof innerfuel prebiotic', 'innerfuel prebiotic fiber'],
 'supplement', 'Bulletproof', 1, '35 cal per 2 scoops (19g). Prebiotic fiber blend: organic acacia, guar gum, larch arabinogalactan. No sugar, gut health support.', TRUE),

-- ══════════════════════════════════════════
-- JADE LEAF — MATCHA
-- ══════════════════════════════════════════

-- Jade Leaf Culinary Matcha: 3 cal per 1/2 tsp (1g)
('jadeleaf_culinary_matcha', 'Jade Leaf Organic Culinary Matcha', 300, 100.0, 100.0, 0.0,
 0.0, 0.0, 1, NULL,
 'manufacturer', ARRAY['jade leaf culinary matcha', 'jade leaf matcha culinary', 'jade leaf organic culinary matcha', 'jade leaf matcha powder cooking'],
 'matcha', 'Jade Leaf', 1, '3 cal per 1/2 tsp (1g). Organic Japanese culinary matcha powder. Ideal for lattes, baking, smoothies. Contains L-theanine.', TRUE),

-- Jade Leaf Ceremonial Matcha: 3 cal per 1/2 tsp (1g)
('jadeleaf_ceremonial_matcha', 'Jade Leaf Organic Ceremonial Matcha', 300, 100.0, 100.0, 0.0,
 0.0, 0.0, 1, NULL,
 'manufacturer', ARRAY['jade leaf ceremonial matcha', 'jade leaf matcha ceremonial', 'jade leaf organic ceremonial matcha', 'jade leaf matcha premium'],
 'matcha', 'Jade Leaf', 1, '3 cal per 1/2 tsp (1g). Premium organic Japanese ceremonial matcha. First harvest, bright green, smooth flavor.', TRUE),

-- Jade Leaf Matcha Latte Mix: 40 cal per 2 tsp (10g)
('jadeleaf_matcha_latte_mix', 'Jade Leaf Matcha Latte Mix', 400, 5.0, 90.0, 0.0,
 0.0, 50.0, 21, NULL,
 'manufacturer', ARRAY['jade leaf matcha latte', 'jade leaf latte mix', 'jade leaf matcha latte mix', 'jade leaf sweetened matcha'],
 'matcha', 'Jade Leaf', 1, '40 cal per 2 tsp (10g). Cafe-style sweetened matcha latte mix. Just add water or milk. 95% carbs.', TRUE),

-- ══════════════════════════════════════════
-- BRAGG — APPLE CIDER VINEGAR
-- ══════════════════════════════════════════

-- Bragg ACV Drink Honey: 35 cal per 8oz serving (240ml ~240g)
('bragg_acv_drink_honey', 'Bragg ACV Refresher Honey Green Tea', 15, 0.0, 3.3, 0.0,
 0.0, 3.3, 240, NULL,
 'manufacturer', ARRAY['bragg acv drink honey', 'bragg apple cider vinegar drink honey', 'bragg acv refresher honey', 'bragg honey green tea acv'],
 'beverage', 'Bragg', 1, '35 cal per 8oz (240ml). Organic ACV refresher with honey and green tea. 750mg acetic acid per serving. Low calorie.', TRUE),

-- Bragg ACV Drink Ginger Lemon: 35 cal per 8oz serving (240ml ~240g)
('bragg_acv_drink_ginger_lemon', 'Bragg ACV Refresher Ginger Lemon Honey', 15, 0.0, 3.8, 0.0,
 0.0, 3.8, 240, NULL,
 'manufacturer', ARRAY['bragg acv drink ginger lemon', 'bragg apple cider vinegar ginger lemon', 'bragg acv refresher ginger lemon', 'bragg ginger lemon honey acv'],
 'beverage', 'Bragg', 1, '35 cal per 8oz (240ml). Organic ACV refresher with ginger, lemon, and honey. USDA organic, non-GMO, gluten-free.', TRUE),

-- Bragg ACV Drink Apple Cinnamon: 20 cal per 8oz serving (240ml ~240g)
('bragg_acv_drink_apple_cinnamon', 'Bragg ACV Refresher Apple Cinnamon', 8, 0.0, 1.7, 0.0,
 0.0, 1.7, 240, NULL,
 'manufacturer', ARRAY['bragg acv drink apple cinnamon', 'bragg apple cider vinegar apple cinnamon', 'bragg acv refresher apple cinnamon', 'bragg apple cinnamon acv'],
 'beverage', 'Bragg', 1, '20 cal per 8oz (240ml). Organic ACV refresher with apple cinnamon flavor. Made from fresh organic apple juice.', TRUE),

-- Bragg Organic Apple Cider Vinegar: 0 cal per tbsp (15ml ~15g)
('bragg_organic_acv', 'Bragg Organic Raw Apple Cider Vinegar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 15, NULL,
 'manufacturer', ARRAY['bragg apple cider vinegar', 'bragg acv', 'bragg organic apple cider vinegar', 'bragg raw unfiltered acv'],
 'vinegar', 'Bragg', 1, '0 cal per tbsp (15ml). Raw, unfiltered, with the Mother. USDA organic, 5% acidity. Kitchen staple.', TRUE),

-- ══════════════════════════════════════════
-- FOUR SIGMATIC — MUSHROOM COFFEE
-- ══════════════════════════════════════════

-- Four Sigmatic Mushroom Coffee Lion's Mane: 0 cal per packet (2.5g)
('foursigmatic_mushroom_coffee_lions_mane', 'Four Sigmatic Think Mushroom Coffee with Lion''s Mane', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['four sigmatic lions mane coffee', 'four sigmatic mushroom coffee', 'four sigmatic think coffee', 'four sigmatic lions mane instant coffee'],
 'mushroom_coffee', 'Four Sigmatic', 1, '0 cal per packet (2.5g). Instant organic coffee with lion''s mane and chaga mushroom extracts. Supports focus and clarity.', TRUE),

-- Four Sigmatic Think Coffee Ground: 0 cal per serving (21g dry)
('foursigmatic_think_coffee_ground', 'Four Sigmatic Think Ground Coffee with Lion''s Mane', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 10, NULL,
 'manufacturer', ARRAY['four sigmatic think ground coffee', 'four sigmatic ground coffee lions mane', 'four sigmatic think coffee ground', 'four sigmatic lions mane ground'],
 'mushroom_coffee', 'Four Sigmatic', 1, '0 cal per serving (21g dry / 12oz brewed). Organic ground coffee with lion''s mane extract and L-theanine.', TRUE),

-- Four Sigmatic Adaptogen Ground Coffee: 5 cal per serving (21g dry)
('foursigmatic_adaptogen_coffee', 'Four Sigmatic Balance Adaptogen Ground Coffee', 24, 0.0, 4.8, 0.0,
 0.0, 0.0, 10, NULL,
 'manufacturer', ARRAY['four sigmatic adaptogen coffee', 'four sigmatic balance coffee', 'four sigmatic ashwagandha coffee', 'four sigmatic adaptogen ground coffee'],
 'mushroom_coffee', 'Four Sigmatic', 1, '5 cal per serving (21g dry). Organic half-caf coffee with ashwagandha, chaga, eleuthero, and tulsi. 75mg caffeine.', TRUE),

-- Four Sigmatic Protein Powder: 170 cal per packet (40g)
('foursigmatic_protein_powder', 'Four Sigmatic Plant-Based Protein Powder', 425, 50.0, 27.5, 10.0,
 7.5, 2.5, 36, NULL,
 'manufacturer', ARRAY['four sigmatic protein powder', 'four sigmatic protein', 'four sigmatic plant protein', 'four sigmatic mushroom protein'],
 'protein_powder', 'Four Sigmatic', 1, '170 cal per packet (40g). Organic plant-based protein with functional mushrooms. 20g protein per serving. Vegan, gluten-free.', TRUE),

-- ══════════════════════════════════════════
-- LAIRD SUPERFOOD — COFFEE CREAMERS
-- ══════════════════════════════════════════

-- Laird Superfood Original Creamer: 45 cal per tbsp (8g)
('laird_original_creamer', 'Laird Superfood Original Creamer', 563, 0.0, 25.0, 50.0,
 0.0, 12.5, 7, NULL,
 'manufacturer', ARRAY['laird superfood creamer', 'laird superfood original creamer', 'laird original creamer', 'laird superfood coffee creamer'],
 'coffee_creamer', 'Laird Superfood', 1, '45 cal per tbsp (8g). Plant-based coffee creamer with coconut oil and Aquamin. Dairy-free, non-GMO.', TRUE),

-- Laird Superfood Instafuel: 150 cal per 3.5 tbsp (26g)
('laird_instafuel', 'Laird Superfood Instafuel', 577, 7.7, 46.2, 42.3,
 0.0, 26.9, 15, NULL,
 'manufacturer', ARRAY['laird superfood instafuel', 'laird instafuel', 'laird superfood instant coffee', 'laird instafuel coffee creamer'],
 'coffee_creamer', 'Laird Superfood', 1, '150 cal per 3.5 tbsp (26g). Instant coffee + superfood creamer combo. Coconut sugar, coconut oil, Aquamin. Just add water.', TRUE),

-- Laird Superfood Cacao Creamer: 25 cal per 2 tsp (8g)
('laird_cacao_creamer', 'Laird Superfood Cacao Creamer', 313, 0.0, 37.5, 18.8,
 0.0, 12.5, 9, NULL,
 'manufacturer', ARRAY['laird superfood cacao creamer', 'laird cacao creamer', 'laird superfood chocolate creamer', 'laird cacao coffee creamer'],
 'coffee_creamer', 'Laird Superfood', 1, '25 cal per 2 tsp (8g). Plant-based cacao coffee creamer. Coconut oil, cacao, Aquamin. Dairy-free.', TRUE),

-- ══════════════════════════════════════════
-- THAT''S IT — FRUIT BARS
-- ══════════════════════════════════════════

-- That's It Apple + Mango Bar: 100 cal per bar (35g)
('thatsit_apple_mango', 'That''s It Apple + Mango Fruit Bar', 286, 0.0, 71.4, 0.0,
 8.6, 65.7, NULL, 35,
 'manufacturer', ARRAY['thats it apple mango', 'that''s it apple mango bar', 'thats it fruit bar apple mango', 'thats it mango bar'],
 'fruit_bar', 'That''s It', 1, '100 cal per bar (35g). Only 2 ingredients: apples and mangoes. No added sugar, no preservatives.', TRUE),

-- That's It Apple + Blueberry Bar: 100 cal per bar (35g)
('thatsit_apple_blueberry', 'That''s It Apple + Blueberry Fruit Bar', 286, 0.0, 74.3, 0.0,
 11.4, 54.3, NULL, 35,
 'manufacturer', ARRAY['thats it apple blueberry', 'that''s it apple blueberry bar', 'thats it fruit bar apple blueberry', 'thats it blueberry bar'],
 'fruit_bar', 'That''s It', 1, '100 cal per bar (35g). Only 2 ingredients: apples and blueberries. 4g fiber, no added sugar.', TRUE),

-- That's It Apple + Strawberry Bar: 100 cal per bar (35g)
('thatsit_apple_strawberry', 'That''s It Apple + Strawberry Fruit Bar', 286, 0.0, 71.4, 0.0,
 8.6, 60.0, NULL, 35,
 'manufacturer', ARRAY['thats it apple strawberry', 'that''s it apple strawberry bar', 'thats it fruit bar apple strawberry', 'thats it strawberry bar'],
 'fruit_bar', 'That''s It', 1, '100 cal per bar (35g). Only 2 ingredients: apples and strawberries. 3g fiber, vitamins A and C.', TRUE),

-- That's It Apple + Fig Bar: 70 cal per bar (35g)
('thatsit_apple_fig', 'That''s It Apple + Fig Fruit Bar', 200, 0.0, 51.4, 0.0,
 8.6, 42.9, NULL, 35,
 'manufacturer', ARRAY['thats it apple fig', 'that''s it apple fig bar', 'thats it fruit bar apple fig', 'thats it fig bar'],
 'fruit_bar', 'That''s It', 1, '70 cal per bar (35g). Only 2 ingredients: apples and figs. Natural fiber, no added sugar.', TRUE),

-- ══════════════════════════════════════════
-- BARE SNACKS — FRUIT CHIPS
-- ══════════════════════════════════════════

-- Bare Apple Chips: 110 cal per 1 oz (28g)
('bare_apple_chips', 'Bare Baked Crunchy Apple Chips', 321, 0.0, 82.1, 0.0,
 10.7, 67.9, 28, NULL,
 'manufacturer', ARRAY['bare apple chips', 'bare snacks apple chips', 'bare baked crunchy apple chips', 'bare fuji reds apple chips'],
 'fruit_snack', 'Bare', 1, '110 cal per oz (28g). Baked, never fried apple chips. Only ingredient: apples. No added sugar, fat-free, gluten-free.', TRUE),

-- Bare Banana Chips: 120 cal per 1 oz (28g)
('bare_banana_chips', 'Bare Baked Crunchy Banana Chips', 429, 3.6, 100.0, 0.0,
 14.3, 75.0, 28, NULL,
 'manufacturer', ARRAY['bare banana chips', 'bare snacks banana chips', 'bare baked crunchy banana chips', 'bare simply banana chips'],
 'fruit_snack', 'Bare', 1, '120 cal per oz (28g). Baked banana chips. Only ingredient: bananas. No added sugar, fat-free.', TRUE),

-- Bare Coconut Chips: 170 cal per 1 oz (28g)
('bare_coconut_chips', 'Bare Toasted Coconut Chips', 607, 7.1, 50.0, 42.9,
 17.9, 32.1, 28, NULL,
 'manufacturer', ARRAY['bare coconut chips', 'bare snacks coconut chips', 'bare toasted coconut chips', 'bare baked coconut chips'],
 'fruit_snack', 'Bare', 1, '170 cal per oz (28g). Toasted coconut chips. Only ingredient: coconut. High in fiber. No added sugar.', TRUE),

-- ══════════════════════════════════════════
-- DOLE — FRUIT CUPS
-- ══════════════════════════════════════════

-- Dole Diced Peaches: 60 cal per cup (113g)
('dole_diced_peaches', 'Dole Diced Peaches in 100% Juice', 53, 0.4, 16.8, 0.1,
 0.9, 15.9, 113, NULL,
 'manufacturer', ARRAY['dole diced peaches', 'dole peach cup', 'dole peaches fruit cup', 'dole fruit bowl peaches'],
 'fruit_cup', 'Dole', 1, '60 cal per cup (113g). Yellow cling diced peaches in 100% fruit juice. No added sugar, excellent source of vitamin C.', TRUE),

-- Dole Mixed Fruit: 70 cal per cup (113g)
('dole_mixed_fruit', 'Dole Mixed Fruit in 100% Juice', 62, 0.9, 14.2, 0.0,
 0.9, 12.4, 113, NULL,
 'manufacturer', ARRAY['dole mixed fruit', 'dole mixed fruit cup', 'dole fruit bowl mixed fruit', 'dole fruit cocktail cup'],
 'fruit_cup', 'Dole', 1, '70 cal per cup (113g). Mix of peaches, pears, and cherries in 100% fruit juice. No added sugar.', TRUE),

-- Dole Pineapple Chunks: 70 cal per 1/2 cup (122g)
('dole_pineapple_chunks', 'Dole Pineapple Chunks in 100% Juice', 57, 0.0, 14.8, 0.0,
 0.8, 12.3, 122, NULL,
 'manufacturer', ARRAY['dole pineapple chunks', 'dole pineapple cup', 'dole pineapple fruit cup', 'dole fruit bowl pineapple'],
 'fruit_cup', 'Dole', 1, '70 cal per 1/2 cup (122g). Pineapple chunks in 100% pineapple juice. No added sugar, good source of vitamin C.', TRUE),

-- ══════════════════════════════════════════
-- NATIERRA — FREEZE-DRIED FRUIT
-- ══════════════════════════════════════════

-- Natierra Freeze-Dried Strawberries: 40 cal per 1/4 cup (10g)
('natierra_freeze_dried_strawberries', 'Natierra Organic Freeze-Dried Strawberries', 400, 8.0, 80.0, 4.0,
 12.0, 52.0, 10, NULL,
 'manufacturer', ARRAY['natierra freeze dried strawberries', 'natierra strawberries', 'natierra organic strawberries', 'natierra dried strawberries'],
 'dried_fruit', 'Natierra', 1, '40 cal per 1/4 cup (10g). Organic freeze-dried strawberries. Only ingredient: strawberries. Crunchy, no added sugar.', TRUE),

-- Natierra Freeze-Dried Mangos: 40 cal per serving (10g)
('natierra_freeze_dried_mangos', 'Natierra Organic Freeze-Dried Mangos', 400, 2.3, 88.4, 3.5,
 4.7, 76.7, 10, NULL,
 'manufacturer', ARRAY['natierra freeze dried mango', 'natierra mangos', 'natierra organic mango', 'natierra dried mango'],
 'dried_fruit', 'Natierra', 1, '40 cal per serving (10g). Organic freeze-dried mango slices. Only ingredient: mangos. No added sugar, good source of vitamin C.', TRUE),

-- Natierra Freeze-Dried Blueberries: 40 cal per serving (10g)
('natierra_freeze_dried_blueberries', 'Natierra Organic Freeze-Dried Blueberries', 412, 2.9, 91.2, 2.9,
 17.6, 67.6, 10, NULL,
 'manufacturer', ARRAY['natierra freeze dried blueberries', 'natierra blueberries', 'natierra organic blueberries', 'natierra dried blueberries'],
 'dried_fruit', 'Natierra', 1, '40 cal per serving (10g). Organic freeze-dried blueberries. Only ingredient: blueberries. Rich in antioxidants, no added sugar.', TRUE)

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
