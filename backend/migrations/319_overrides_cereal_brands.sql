-- 319_overrides_cereal_brands.sql
-- Popular cereal brands: General Mills, Kellogg's, Post, Quaker, and specialty brands.
-- Sources: USDA FoodData Central, nutritionvalue.org, foodstruct.com, eatthismuch.com,
-- official brand SmartLabel pages, nutritionix.com, fatsecret.com, calorieking.com

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ===================================================================
-- GENERAL MILLS
-- ===================================================================

-- ── CHEERIOS (ORIGINAL) ──────────────────────────────────────────
-- 376 cal/100g. Serving 28g (1 cup) = ~105 cal. Whole grain oat cereal.
('cheerios_original', 'Cheerios (Original)', 376, 12.1, 73.2, 6.7,
 10.1, 3.6, 28, NULL,
 'general_mills', ARRAY['cheerios', 'original cheerios', 'plain cheerios', 'regular cheerios'],
 'cereal', 'General Mills', 1, '376 cal/100g. 1 cup (28g) = ~105 cal. Whole grain oat cereal, low sugar, good source of fiber. USDA.', TRUE),

-- ── CHEERIOS (HONEY NUT) ─────────────────────────────────────────
-- 393 cal/100g. Serving 28g (3/4 cup) = ~110 cal. Honey-sweetened oat cereal.
('cheerios_honey_nut', 'Honey Nut Cheerios', 393, 7.1, 78.6, 5.4,
 7.1, 32.1, 28, NULL,
 'general_mills', ARRAY['honey nut cheerios', 'honey cheerios', 'cheerios honey'],
 'cereal', 'General Mills', 1, '393 cal/100g. 3/4 cup (28g) = ~110 cal. Honey and almond flavored oat cereal. USDA.', TRUE),

-- ── CHEERIOS (APPLE CINNAMON) ────────────────────────────────────
-- 386 cal/100g. Serving 37g (1 cup) = ~143 cal. Apple cinnamon flavored oat cereal.
('cheerios_apple_cinnamon', 'Apple Cinnamon Cheerios', 386, 8.3, 79.9, 6.1,
 5.4, 30.0, 37, NULL,
 'general_mills', ARRAY['apple cinnamon cheerios', 'cheerios apple cinnamon'],
 'cereal', 'General Mills', 1, '386 cal/100g. 1 cup (37g) = ~143 cal. Apple cinnamon flavored whole grain oat cereal. USDA.', TRUE),

-- ── CHEERIOS (FROSTED) ───────────────────────────────────────────
-- 376 cal/100g. Serving 30g (3/4 cup) = ~113 cal. Sugar-coated oat cereal.
('cheerios_frosted', 'Frosted Cheerios', 376, 9.0, 80.0, 4.5,
 8.0, 32.0, 30, NULL,
 'general_mills', ARRAY['frosted cheerios', 'cheerios frosted'],
 'cereal', 'General Mills', 1, '376 cal/100g. 3/4 cup (30g) = ~113 cal. Frosted whole grain oat cereal. USDA.', TRUE),

-- ── LUCKY CHARMS ─────────────────────────────────────────────────
-- 380 cal/100g. Serving 27g (3/4 cup) = ~103 cal. Oat cereal with marshmallows.
('lucky_charms', 'Lucky Charms', 380, 7.7, 80.0, 4.0,
 6.0, 37.0, 27, NULL,
 'general_mills', ARRAY['lucky charms cereal', 'lucky charms marshmallow cereal'],
 'cereal', 'General Mills', 1, '380 cal/100g. 3/4 cup (27g) = ~103 cal. Frosted oat cereal with marshmallow pieces. USDA.', TRUE),

-- ── CINNAMON TOAST CRUNCH ────────────────────────────────────────
-- 410 cal/100g. Serving 31g (3/4 cup) = ~127 cal. Cinnamon sugar coated squares.
('cinnamon_toast_crunch', 'Cinnamon Toast Crunch', 410, 5.5, 78.0, 10.3,
 7.0, 30.0, 31, NULL,
 'general_mills', ARRAY['cinnamon toast crunch cereal', 'ctc cereal', 'cinnamon crunch'],
 'cereal', 'General Mills', 1, '410 cal/100g. 3/4 cup (31g) = ~127 cal. Cinnamon sugar coated whole wheat and rice squares. USDA.', TRUE),

-- ── COCOA PUFFS ──────────────────────────────────────────────────
-- 389 cal/100g. Serving 36g (1 cup) = ~140 cal. Chocolate flavored puffed corn.
('cocoa_puffs', 'Cocoa Puffs', 389, 5.6, 86.0, 5.6,
 5.6, 33.0, 36, NULL,
 'general_mills', ARRAY['cocoa puffs cereal', 'chocolate puffs'],
 'cereal', 'General Mills', 1, '389 cal/100g. 1 cup (36g) = ~140 cal. Chocolate flavored corn puff cereal. USDA.', TRUE),

-- ── TRIX ─────────────────────────────────────────────────────────
-- 384 cal/100g. Serving 32g (1 cup) = ~123 cal. Fruit flavored corn puffs.
('trix_cereal', 'Trix', 384, 4.9, 86.2, 3.8,
 3.1, 31.3, 32, NULL,
 'general_mills', ARRAY['trix cereal', 'trix fruit cereal'],
 'cereal', 'General Mills', 1, '384 cal/100g. 1 cup (32g) = ~123 cal. Fruit flavored sweetened corn puff cereal. USDA.', TRUE),

-- ── RICE CHEX ────────────────────────────────────────────────────
-- 375 cal/100g. Serving 31g (1 cup) = ~116 cal. Gluten-free rice cereal squares.
('chex_rice', 'Rice Chex', 375, 7.5, 85.0, 1.3,
 2.0, 8.0, 31, NULL,
 'general_mills', ARRAY['rice chex', 'chex rice cereal', 'rice chex cereal', 'gluten free chex'],
 'cereal', 'General Mills', 1, '375 cal/100g. 1 cup (31g) = ~116 cal. Gluten-free oven-toasted rice cereal. USDA.', TRUE),

-- ── CORN CHEX ────────────────────────────────────────────────────
-- 367 cal/100g. Serving 31g (1 cup) = ~114 cal. Gluten-free corn cereal squares.
('chex_corn', 'Corn Chex', 367, 6.7, 85.1, 1.7,
 1.0, 9.7, 31, NULL,
 'general_mills', ARRAY['corn chex', 'chex corn cereal', 'corn chex cereal'],
 'cereal', 'General Mills', 1, '367 cal/100g. 1 cup (31g) = ~114 cal. Gluten-free oven-toasted corn cereal. USDA.', TRUE),

-- ── WHEAT CHEX ───────────────────────────────────────────────────
-- 345 cal/100g. Serving 47g (1 cup) = ~162 cal. Whole wheat cereal squares.
('chex_wheat', 'Wheat Chex', 345, 9.8, 82.2, 1.8,
 12.8, 10.6, 47, NULL,
 'general_mills', ARRAY['wheat chex', 'chex wheat cereal', 'wheat chex cereal'],
 'cereal', 'General Mills', 1, '345 cal/100g. 1 cup (47g) = ~162 cal. Whole grain wheat cereal with good fiber. USDA.', TRUE),

-- ===================================================================
-- KELLOGG''S
-- ===================================================================

-- ── FROSTED FLAKES ───────────────────────────────────────────────
-- 369 cal/100g. Serving 39g (1 cup) = ~144 cal. Sugar-frosted corn flakes.
('frosted_flakes', 'Frosted Flakes', 369, 4.0, 89.0, 2.0,
 2.0, 35.0, 39, NULL,
 'kelloggs', ARRAY['frosted flakes', 'kelloggs frosted flakes', 'tony the tiger cereal', 'frosties'],
 'cereal', 'Kellogg''s', 1, '369 cal/100g. 1 cup (39g) = ~144 cal. Sugar-frosted corn flake cereal. USDA.', TRUE),

-- ── FROOT LOOPS ──────────────────────────────────────────────────
-- 375 cal/100g. Serving 39g (1.5 cups) = ~146 cal. Fruit-flavored rings.
('froot_loops', 'Froot Loops', 375, 5.3, 87.7, 3.0,
 9.0, 42.0, 39, NULL,
 'kelloggs', ARRAY['froot loops', 'kelloggs froot loops', 'fruit loops', 'fruity loops'],
 'cereal', 'Kellogg''s', 1, '375 cal/100g. 1.5 cups (39g) = ~146 cal. Multi-colored fruit-flavored ring cereal. USDA.', TRUE),

-- ── RICE KRISPIES ────────────────────────────────────────────────
-- 381 cal/100g. Serving 33g (1.25 cups) = ~126 cal. Puffed rice cereal.
('rice_krispies', 'Rice Krispies', 381, 7.8, 85.0, 2.3,
 0.0, 10.0, 33, NULL,
 'kelloggs', ARRAY['rice krispies', 'kelloggs rice krispies', 'rice bubbles', 'snap crackle pop cereal'],
 'cereal', 'Kellogg''s', 1, '381 cal/100g. 1.25 cups (33g) = ~126 cal. Toasted puffed rice cereal. USDA.', TRUE),

-- ── CORN FLAKES ──────────────────────────────────────────────────
-- 357 cal/100g. Serving 29g (1 cup) = ~104 cal. Classic toasted corn flakes.
('corn_flakes', 'Corn Flakes', 357, 7.5, 84.1, 0.4,
 3.0, 10.0, 29, NULL,
 'kelloggs', ARRAY['corn flakes', 'kelloggs corn flakes', 'cornflakes'],
 'cereal', 'Kellogg''s', 1, '357 cal/100g. 1 cup (29g) = ~104 cal. Classic toasted corn flake cereal. USDA.', TRUE),

-- ── RAISIN BRAN ──────────────────────────────────────────────────
-- 377 cal/100g. Serving 59g (1 cup) = ~222 cal. Bran flakes with raisins.
('raisin_bran', 'Raisin Bran', 377, 8.0, 77.0, 3.0,
 11.0, 31.0, 59, NULL,
 'kelloggs', ARRAY['raisin bran', 'kelloggs raisin bran', 'raisin bran cereal'],
 'cereal', 'Kellogg''s', 1, '377 cal/100g. 1 cup (59g) = ~222 cal. Bran flakes with sun-dried raisins. High fiber. USDA.', TRUE),

-- ── FROSTED MINI-WHEATS ──────────────────────────────────────────
-- 350 cal/100g. Serving 60g (25 biscuits) = ~210 cal. Frosted shredded wheat.
('frosted_mini_wheats', 'Frosted Mini-Wheats', 350, 8.3, 85.0, 2.5,
 10.0, 20.0, 60, NULL,
 'kelloggs', ARRAY['frosted mini wheats', 'mini wheats', 'kelloggs frosted mini wheats', 'frosted shredded wheat'],
 'cereal', 'Kellogg''s', 1, '350 cal/100g. 25 biscuits (60g) = ~210 cal. Frosted whole wheat biscuit cereal, high fiber. USDA.', TRUE),

-- ── APPLE JACKS ──────────────────────────────────────────────────
-- 375 cal/100g. Serving 28g (1 cup) = ~105 cal. Apple cinnamon flavored rings.
('apple_jacks', 'Apple Jacks', 375, 5.1, 88.0, 3.1,
 9.3, 44.0, 28, NULL,
 'kelloggs', ARRAY['apple jacks', 'kelloggs apple jacks', 'apple jacks cereal'],
 'cereal', 'Kellogg''s', 1, '375 cal/100g. 1 cup (28g) = ~105 cal. Apple and cinnamon flavored sweetened cereal. USDA/foodstruct.', TRUE),

-- ── SPECIAL K (ORIGINAL) ─────────────────────────────────────────
-- 377 cal/100g. Serving 31g (1 cup) = ~117 cal. Lightly toasted rice flakes.
('special_k_original', 'Special K (Original)', 377, 18.0, 73.0, 1.8,
 1.4, 13.0, 31, NULL,
 'kelloggs', ARRAY['special k', 'kelloggs special k', 'special k original', 'special k cereal'],
 'cereal', 'Kellogg''s', 1, '377 cal/100g. 1 cup (31g) = ~117 cal. Lightly toasted rice flakes, high protein for a cereal. USDA.', TRUE),

-- ── SPECIAL K (RED BERRIES) ──────────────────────────────────────
-- 359 cal/100g. Serving 31g (1 cup) = ~111 cal. Rice flakes with strawberries.
('special_k_red_berries', 'Special K Red Berries', 359, 6.5, 87.0, 1.0,
 8.0, 30.0, 31, NULL,
 'kelloggs', ARRAY['special k red berries', 'special k strawberry', 'kelloggs special k red berries'],
 'cereal', 'Kellogg''s', 1, '359 cal/100g. 1 cup (31g) = ~111 cal. Rice flakes with freeze-dried strawberries. USDA.', TRUE),

-- ===================================================================
-- POST
-- ===================================================================

-- ── GRAPE-NUTS ───────────────────────────────────────────────────
-- 361 cal/100g. Serving 58g (1/2 cup) = ~209 cal. Dense crunchy wheat and barley.
('grape_nuts', 'Grape-Nuts', 361, 11.2, 80.5, 1.8,
 13.8, 8.6, 58, NULL,
 'post', ARRAY['grape nuts', 'grapenuts', 'post grape nuts', 'grape-nuts cereal'],
 'cereal', 'Post', 1, '361 cal/100g. 1/2 cup (58g) = ~209 cal. Dense nugget cereal from wheat and barley flour. Very high fiber. USDA.', TRUE),

-- ── HONEY BUNCHES OF OATS (ORIGINAL) ─────────────────────────────
-- 401 cal/100g. Serving 32g (3/4 cup) = ~128 cal. Flakes with oat clusters.
('honey_bunches_of_oats_original', 'Honey Bunches of Oats (Original)', 401, 7.1, 81.2, 5.5,
 4.2, 19.8, 32, NULL,
 'post', ARRAY['honey bunches of oats', 'honey bunches', 'hbo cereal', 'honey bunches of oats honey roasted'],
 'cereal', 'Post', 1, '401 cal/100g. 3/4 cup (32g) = ~128 cal. Crispy flakes with honey-roasted oat clusters. USDA.', TRUE),

-- ── HONEY BUNCHES OF OATS (ALMONDS) ──────────────────────────────
-- 409 cal/100g. Serving 32g (3/4 cup) = ~131 cal. Flakes with oat clusters and almonds.
('honey_bunches_of_oats_almonds', 'Honey Bunches of Oats with Almonds', 409, 7.7, 79.6, 7.3,
 5.5, 20.0, 32, NULL,
 'post', ARRAY['honey bunches of oats almonds', 'honey bunches almonds', 'hbo almonds'],
 'cereal', 'Post', 1, '409 cal/100g. 3/4 cup (32g) = ~131 cal. Crispy flakes with oat clusters and sliced almonds. USDA.', TRUE),

-- ── FRUITY PEBBLES ───────────────────────────────────────────────
-- 379 cal/100g. Serving 27g (3/4 cup) = ~102 cal. Fruit-flavored crispy rice.
('fruity_pebbles', 'Fruity Pebbles', 379, 3.6, 86.4, 3.6,
 0.0, 39.3, 27, NULL,
 'post', ARRAY['fruity pebbles', 'fruity pebbles cereal', 'post fruity pebbles'],
 'cereal', 'Post', 1, '379 cal/100g. 3/4 cup (27g) = ~102 cal. Sweetened crispy rice cereal with fruity flavors. USDA.', TRUE),

-- ── COCOA PEBBLES ────────────────────────────────────────────────
-- 397 cal/100g. Serving 30g (3/4 cup) = ~119 cal. Chocolate flavored crispy rice.
('cocoa_pebbles', 'Cocoa Pebbles', 397, 4.8, 85.7, 4.1,
 0.0, 36.7, 30, NULL,
 'post', ARRAY['cocoa pebbles', 'cocoa pebbles cereal', 'post cocoa pebbles', 'chocolate pebbles'],
 'cereal', 'Post', 1, '397 cal/100g. 3/4 cup (30g) = ~119 cal. Chocolate flavored crispy rice cereal. USDA.', TRUE),

-- ── GREAT GRAINS (CRUNCHY PECAN) ─────────────────────────────────
-- 396 cal/100g. Serving 53g (3/4 cup) = ~210 cal. Whole grain flakes with pecans.
('great_grains_crunchy_pecan', 'Great Grains Crunchy Pecan', 396, 9.0, 73.6, 9.4,
 9.4, 15.1, 53, NULL,
 'post', ARRAY['great grains', 'great grains crunchy pecan', 'post great grains', 'great grains cereal'],
 'cereal', 'Post', 1, '396 cal/100g. 3/4 cup (53g) = ~210 cal. Whole grain flakes with pecans and oat clusters. USDA.', TRUE),

-- ===================================================================
-- QUAKER
-- ===================================================================

-- ── QUAKER OATS (INSTANT) ────────────────────────────────────────
-- 357 cal/100g. Serving 28g (1 packet) = ~100 cal. Plain instant oatmeal.
('quaker_oats_instant', 'Quaker Oats Instant Oatmeal (Original)', 357, 14.3, 64.3, 7.1,
 10.7, 0.0, 28, NULL,
 'quaker', ARRAY['quaker instant oatmeal', 'instant oatmeal', 'quaker oats instant', 'instant oats', 'quaker original oatmeal'],
 'cereal', 'Quaker', 1, '357 cal/100g. 1 packet (28g) = ~100 cal. Plain instant whole grain oats, no added sugar. Official label.', TRUE),

-- ── QUAKER OATS (OLD FASHIONED) ──────────────────────────────────
-- 375 cal/100g. Serving 40g (1/2 cup dry) = ~150 cal. Rolled oats.
('quaker_oats_old_fashioned', 'Quaker Oats Old Fashioned', 375, 12.5, 67.5, 7.5,
 10.0, 2.5, 40, NULL,
 'quaker', ARRAY['quaker old fashioned oats', 'old fashioned oatmeal', 'rolled oats quaker', 'quaker oats', 'old fashioned oats'],
 'cereal', 'Quaker', 1, '375 cal/100g. 1/2 cup dry (40g) = ~150 cal. 100% whole grain rolled oats. Official label.', TRUE),

-- ── CAP''N CRUNCH (ORIGINAL) ─────────────────────────────────────
-- 396 cal/100g. Serving 27g (3/4 cup) = ~107 cal. Sweetened corn and oat cereal.
('capn_crunch_original', 'Cap''n Crunch (Original)', 396, 4.4, 85.2, 5.2,
 2.6, 44.3, 27, NULL,
 'quaker', ARRAY['capn crunch', 'captain crunch', 'cap''n crunch', 'cap''n crunch original'],
 'cereal', 'Quaker', 1, '396 cal/100g. 3/4 cup (27g) = ~107 cal. Sweetened corn and oat cereal. High sugar. USDA.', TRUE),

-- ── CAP''N CRUNCH (CRUNCH BERRIES) ───────────────────────────────
-- 393 cal/100g. Serving 27g (3/4 cup) = ~106 cal. With berry-flavored pieces.
('capn_crunch_berries', 'Cap''n Crunch Crunch Berries', 393, 4.0, 85.0, 5.0,
 2.5, 43.0, 27, NULL,
 'quaker', ARRAY['crunch berries', 'cap''n crunch crunch berries', 'captain crunch berries', 'capn crunch berries'],
 'cereal', 'Quaker', 1, '393 cal/100g. 3/4 cup (27g) = ~106 cal. Sweetened corn & oat cereal with berry-flavored pieces. USDA.', TRUE),

-- ── CAP''N CRUNCH (PEANUT BUTTER) ────────────────────────────────
-- 407 cal/100g. Serving 27g (3/4 cup) = ~110 cal. Peanut butter flavored.
('capn_crunch_peanut_butter', 'Cap''n Crunch Peanut Butter Crunch', 407, 7.4, 77.8, 11.1,
 1.9, 33.3, 27, NULL,
 'quaker', ARRAY['peanut butter crunch', 'cap''n crunch peanut butter', 'captain crunch peanut butter', 'pb crunch'],
 'cereal', 'Quaker', 1, '407 cal/100g. 3/4 cup (27g) = ~110 cal. Peanut butter flavored sweetened corn & oat cereal. Official label.', TRUE),

-- ── LIFE CEREAL ──────────────────────────────────────────────────
-- 376 cal/100g. Serving 43g (3/4 cup) = ~162 cal. Lightly sweet whole grain cereal.
('life_cereal', 'Life Cereal', 376, 9.3, 78.6, 4.1,
 7.1, 19.0, 43, NULL,
 'quaker', ARRAY['life cereal', 'quaker life', 'life cereal original', 'quaker life cereal'],
 'cereal', 'Quaker', 1, '376 cal/100g. 3/4 cup (43g) = ~162 cal. Lightly sweetened whole grain oat cereal. USDA.', TRUE),

-- ===================================================================
-- SPECIALTY / OTHER BRANDS
-- ===================================================================

-- ── KASHI GOLEAN ─────────────────────────────────────────────────
-- 311 cal/100g. Serving 52g (1 cup) = ~162 cal. High protein, high fiber.
('kashi_golean', 'Kashi GoLean', 311, 24.9, 67.2, 2.2,
 19.2, 17.3, 52, NULL,
 'kashi', ARRAY['kashi go lean', 'kashi golean', 'kashi go cereal', 'kashi protein cereal'],
 'cereal', 'Kashi', 1, '311 cal/100g. 1 cup (52g) = ~162 cal. High protein (25g/100g), high fiber cereal. USDA.', TRUE),

-- ── NATURE''S PATH HERITAGE FLAKES ───────────────────────────────
-- 400 cal/100g. Serving 40g (1 cup) = ~160 cal. Organic six ancient grains.
('natures_path_heritage_flakes', 'Nature''s Path Heritage Flakes', 400, 12.5, 77.5, 3.8,
 17.5, 12.5, 40, NULL,
 'natures_path', ARRAY['heritage flakes', 'nature''s path heritage', 'organic heritage flakes', 'natures path cereal'],
 'cereal', 'Nature''s Path', 1, '400 cal/100g. 1 cup (40g) = ~160 cal. Organic cereal with 6 ancient grains. Very high fiber. nutritionvalue.org.', TRUE),

-- ── MAGIC SPOON (FRUITY) ─────────────────────────────────────────
-- 395 cal/100g. Serving 38g (1 cup) = ~150 cal. High protein, keto-friendly.
('magic_spoon_fruity', 'Magic Spoon Fruity', 395, 34.2, 39.5, 21.1,
 2.6, 0.0, 38, NULL,
 'magic_spoon', ARRAY['magic spoon fruity', 'magic spoon fruit cereal', 'fruity magic spoon'],
 'cereal', 'Magic Spoon', 1, '395 cal/100g. 1 cup (38g) = ~150 cal. Grain-free, high protein (13g/serving), 0g sugar. Sweetened with allulose & monk fruit. Official label.', TRUE),

-- ── MAGIC SPOON (COCOA) ──────────────────────────────────────────
-- 378 cal/100g. Serving 37g (1 cup) = ~140 cal. High protein chocolate, keto-friendly.
('magic_spoon_cocoa', 'Magic Spoon Cocoa', 378, 35.1, 40.5, 24.3,
 5.4, 0.0, 37, NULL,
 'magic_spoon', ARRAY['magic spoon cocoa', 'magic spoon chocolate', 'chocolate magic spoon'],
 'cereal', 'Magic Spoon', 1, '378 cal/100g. 1 cup (37g) = ~140 cal. Grain-free, high protein (13g/serving), 0g sugar, real cocoa. Official label.', TRUE),

-- ── CATALINA CRUNCH (DARK CHOCOLATE) ─────────────────────────────
-- 306 cal/100g. Serving 36g (1/2 cup) = ~110 cal. Low carb, high protein & fiber.
('catalina_crunch_dark_chocolate', 'Catalina Crunch Dark Chocolate', 306, 30.6, 38.9, 16.7,
 25.0, 0.0, 36, NULL,
 'catalina_crunch', ARRAY['catalina crunch dark chocolate', 'catalina crunch chocolate', 'catalina dark chocolate cereal'],
 'cereal', 'Catalina Crunch', 1, '306 cal/100g. 1/2 cup (36g) = ~110 cal. Keto-friendly, 11g protein, 9g fiber, 0g sugar per serving. Official label.', TRUE),

-- ── CATALINA CRUNCH (CINNAMON TOAST) ─────────────────────────────
-- 306 cal/100g. Serving 36g (1/2 cup) = ~110 cal. Low carb cinnamon flavored.
('catalina_crunch_cinnamon_toast', 'Catalina Crunch Cinnamon Toast', 306, 30.6, 38.9, 16.7,
 25.0, 0.0, 36, NULL,
 'catalina_crunch', ARRAY['catalina crunch cinnamon toast', 'catalina cinnamon cereal', 'catalina crunch cinnamon'],
 'cereal', 'Catalina Crunch', 1, '306 cal/100g. 1/2 cup (36g) = ~110 cal. Keto-friendly, 11g protein, 9g fiber, 0g sugar per serving. Official label.', TRUE),

-- ── BEAR NAKED GRANOLA ───────────────────────────────────────────
-- 467 cal/100g. Serving 30g (1/4 cup) = ~140 cal. Crunchy all-natural granola.
('bear_naked_granola', 'Bear Naked Granola', 467, 20.0, 53.0, 20.0,
 6.7, 20.0, 30, NULL,
 'bear_naked', ARRAY['bear naked granola', 'bear naked cereal', 'bear naked original granola'],
 'cereal', 'Bear Naked', 1, '467 cal/100g. 1/4 cup (30g) = ~140 cal. All-natural crunchy granola with oats, nuts, and honey. nutritionvalue.org.', TRUE)

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
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
