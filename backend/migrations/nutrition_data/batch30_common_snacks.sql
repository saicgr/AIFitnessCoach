-- ============================================================================
-- Batch 30: Common Snacks, Bars & Supplements
-- ~55 items commonly logged in fitness/calorie tracking apps
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central, manufacturer nutrition labels
-- All values are per 100g of product
-- Calorie verification: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- PROTEIN / FITNESS BARS (~8 items)
-- ============================================================================

-- Quest Bar (Cookie Dough): 60g bar, 200 cal, 21g protein, 22g carbs, 8g fat, 14g fiber
-- Per 100g: 333 cal, 35g protein, 36.7g carbs, 13.3g fat
-- Check: 35*4 + 36.7*4 + 13.3*9 = 140 + 146.8 + 119.7 = 406.5 (labeled 333, fiber 23.3g offsets)
('quest_bar_cookie_dough', 'Quest Bar (Cookie Dough)', 333.0, 35.0, 36.7, 13.3, 23.3, 1.7, 60, 60, 'usda', ARRAY['quest bar', 'quest protein bar', 'quest cookie dough', 'quest chocolate chip cookie dough'], '200 cal per bar (60g). 21g protein, 14g fiber.', NULL, 'snacks', 1),

-- Clif Bar (Chocolate Chip): 68g bar, 250 cal, 10g protein, 44g carbs, 5g fat, 4g fiber
-- Per 100g: 368 cal, 14.7g protein, 64.7g carbs, 7.4g fat
-- Check: 14.7*4 + 64.7*4 + 7.4*9 = 58.8 + 258.8 + 66.6 = 384.2 (labeled 368)
('clif_bar_chocolate_chip', 'Clif Bar (Chocolate Chip)', 368.0, 14.7, 64.7, 7.4, 5.9, 30.9, 68, 68, 'usda', ARRAY['clif bar', 'cliff bar', 'clif energy bar', 'clif bar chocolate'], '250 cal per bar (68g). 10g protein. Endurance energy bar.', NULL, 'snacks', 1),

-- KIND Bar (Dark Chocolate Nuts & Sea Salt): 40g bar, 200 cal, 6g protein, 16g carbs, 15g fat, 3g fiber
-- Per 100g: 500 cal, 15.0g protein, 40.0g carbs, 37.5g fat
-- Check: 15*4 + 40*4 + 37.5*9 = 60 + 160 + 337.5 = 557.5 (labeled 500, fiber offsets)
('kind_bar_dark_chocolate', 'KIND Bar (Dark Chocolate Nuts)', 500.0, 15.0, 40.0, 37.5, 7.5, 17.5, 40, 40, 'usda', ARRAY['kind bar', 'kind nut bar', 'kind dark chocolate', 'kind bar nuts sea salt'], '200 cal per bar (40g). 6g protein.', NULL, 'snacks', 1),

-- RXBar (Chocolate Sea Salt): 52g bar, 210 cal, 12g protein, 24g carbs, 9g fat, 5g fiber
-- Per 100g: 404 cal, 23.1g protein, 46.2g carbs, 17.3g fat
-- Check: 23.1*4 + 46.2*4 + 17.3*9 = 92.4 + 184.8 + 155.7 = 432.9 (labeled 404, fiber offsets)
('rxbar_chocolate_sea_salt', 'RXBar (Chocolate Sea Salt)', 404.0, 23.1, 46.2, 17.3, 9.6, 25.0, 52, 52, 'usda', ARRAY['rxbar', 'rx bar', 'rxbar chocolate', 'rx protein bar'], '210 cal per bar (52g). 12g protein. Egg white based.', NULL, 'snacks', 1),

-- ONE Bar (Birthday Cake): 60g bar, 220 cal, 20g protein, 23g carbs, 8g fat, 9g fiber
-- Per 100g: 367 cal, 33.3g protein, 38.3g carbs, 13.3g fat
-- Check: 33.3*4 + 38.3*4 + 13.3*9 = 133.2 + 153.2 + 119.7 = 406.1 (labeled 367, fiber 15g offsets)
('one_bar_birthday_cake', 'ONE Bar (Birthday Cake)', 367.0, 33.3, 38.3, 13.3, 15.0, 1.7, 60, 60, 'usda', ARRAY['one protein bar', 'one bar', 'oh yeah one bar', 'one birthday cake bar'], '220 cal per bar (60g). 20g protein.', NULL, 'snacks', 1),

-- Pure Protein Bar (Chocolate Peanut Butter): 50g bar, 200 cal, 20g protein, 17g carbs, 6g fat, 2g fiber
-- Per 100g: 400 cal, 40.0g protein, 34.0g carbs, 12.0g fat
-- Check: 40*4 + 34*4 + 12*9 = 160 + 136 + 108 = 404 (labeled 400)
('pure_protein_bar', 'Pure Protein Bar (Choc PB)', 400.0, 40.0, 34.0, 12.0, 4.0, 4.0, 50, 50, 'usda', ARRAY['pure protein bar', 'pure protein chocolate peanut butter'], '200 cal per bar (50g). 20g protein.', NULL, 'snacks', 1),

-- Larabar (Cashew Cookie): 48g bar, 220 cal, 5g protein, 24g carbs, 13g fat, 2g fiber
-- Per 100g: 458 cal, 10.4g protein, 50.0g carbs, 27.1g fat
-- Check: 10.4*4 + 50*4 + 27.1*9 = 41.6 + 200 + 243.9 = 485.5 (labeled 458, fiber offsets)
('larabar_cashew_cookie', 'Larabar (Cashew Cookie)', 458.0, 10.4, 50.0, 27.1, 4.2, 33.3, 48, 48, 'usda', ARRAY['larabar', 'lara bar', 'larabar cashew', 'larabar fruit and nut bar'], '220 cal per bar (48g). Only 2 ingredients: cashews and dates.', NULL, 'snacks', 1),

-- Nature Valley Granola Bar (Oats & Honey, 2 bars): 42g pouch, 190 cal, 4g protein, 29g carbs, 7g fat, 2g fiber
-- Per 100g: 452 cal, 9.5g protein, 69.0g carbs, 16.7g fat
-- Check: 9.5*4 + 69*4 + 16.7*9 = 38 + 276 + 150.3 = 464.3 (labeled 452)
('nature_valley_oats_honey', 'Nature Valley Granola Bar (Oats & Honey)', 452.0, 9.5, 69.0, 16.7, 4.8, 28.6, 21, 42, 'usda', ARRAY['nature valley bar', 'nature valley granola', 'nature valley crunchy', 'oats and honey bar'], '190 cal per 2-bar pouch (42g). 4g protein.', NULL, 'snacks', 2),

-- ============================================================================
-- CHIPS (~8 items)
-- ============================================================================

-- Potato Chips (plain/classic): 536 cal, 7.0g protein, 49.7g carbs, 35.0g fat per 100g. Serving=1oz (28g)
-- Check: 7*4 + 49.7*4 + 35*9 = 28 + 198.8 + 315 = 541.8 (labeled 536)
('potato_chips', 'Potato Chips (plain)', 536.0, 7.0, 49.7, 35.0, 4.4, 0.3, NULL, 28, 'usda', ARRAY['plain chips', 'salted chips', 'classic potato chips', 'thin chips'], '150 cal per 1 oz serving (28g, ~15 chips).', NULL, 'snacks', 1),

-- Tortilla Chips: 489 cal, 7.4g protein, 58.3g carbs, 25.6g fat per 100g. Serving=1oz (28g)
-- Check: 7.4*4 + 58.3*4 + 25.6*9 = 29.6 + 233.2 + 230.4 = 493.2 (labeled 489)
('tortilla_chips', 'Tortilla Chips', 489.0, 7.4, 58.3, 25.6, 4.0, 0.5, NULL, 28, 'usda', ARRAY['corn tortilla chips', 'tostitos', 'corn chips', 'nacho chips'], '137 cal per 1 oz serving (28g, ~7 chips).', NULL, 'snacks', 1),

-- Doritos (Nacho Cheese): 496 cal, 6.4g protein, 57.1g carbs, 26.8g fat per 100g. Serving=1oz (28g)
-- Check: 6.4*4 + 57.1*4 + 26.8*9 = 25.6 + 228.4 + 241.2 = 495.2
('doritos_nacho_cheese', 'Doritos (Nacho Cheese)', 496.0, 6.4, 57.1, 26.8, 3.6, 3.6, NULL, 28, 'usda', ARRAY['doritos', 'nacho cheese doritos', 'doritos nacho'], '140 cal per 1 oz serving (28g, ~12 chips).', NULL, 'snacks', 1),

-- Cheetos (Crunchy): 536 cal, 7.1g protein, 53.6g carbs, 33.9g fat per 100g. Serving=1oz (28g)
-- Check: 7.1*4 + 53.6*4 + 33.9*9 = 28.4 + 214.4 + 305.1 = 547.9 (labeled 536)
('cheetos_crunchy', 'Cheetos (Crunchy)', 536.0, 7.1, 53.6, 33.9, 0.0, 3.6, NULL, 28, 'usda', ARRAY['cheetos', 'crunchy cheetos', 'cheetos puffs', 'chester cheetah'], '150 cal per 1 oz serving (28g, ~21 pieces).', NULL, 'snacks', 1),

-- Lay's Classic: 536 cal, 7.1g protein, 50.0g carbs, 35.7g fat per 100g. Serving=1oz (28g)
-- Check: 7.1*4 + 50*4 + 35.7*9 = 28.4 + 200 + 321.3 = 549.7 (labeled 536)
('lays_classic', 'Lay''s Classic Potato Chips', 536.0, 7.1, 50.0, 35.7, 3.6, 0.0, NULL, 28, 'usda', ARRAY['lays chips', 'lays original', 'lays classic chips'], '150 cal per 1 oz serving (28g, ~15 chips).', NULL, 'snacks', 1),

-- Pringles (Original): 536 cal, 3.6g protein, 53.6g carbs, 35.7g fat per 100g. Serving=1oz (28g)
-- Check: 3.6*4 + 53.6*4 + 35.7*9 = 14.4 + 214.4 + 321.3 = 550.1 (labeled 536)
('pringles_original', 'Pringles (Original)', 536.0, 3.6, 53.6, 35.7, 3.6, 0.0, NULL, 28, 'usda', ARRAY['pringles', 'pringles original', 'pringles chips'], '150 cal per 1 oz serving (28g, ~16 crisps).', NULL, 'snacks', 1),

-- Kettle Cooked Chips: 536 cal, 7.1g protein, 50.0g carbs, 35.7g fat per 100g. Serving=1oz (28g)
-- Check: 7.1*4 + 50*4 + 35.7*9 = 28.4 + 200 + 321.3 = 549.7 (labeled 536)
('kettle_cooked_chips', 'Kettle Cooked Potato Chips', 536.0, 7.1, 50.0, 35.7, 3.6, 0.0, NULL, 28, 'usda', ARRAY['kettle chips', 'kettle brand chips', 'thick cut chips'], '150 cal per 1 oz serving (28g).', NULL, 'snacks', 1),

-- Veggie Straws: 464 cal, 3.6g protein, 64.3g carbs, 21.4g fat per 100g. Serving=1oz (28g)
-- Check: 3.6*4 + 64.3*4 + 21.4*9 = 14.4 + 257.2 + 192.6 = 464.2
('veggie_straws', 'Veggie Straws', 464.0, 3.6, 64.3, 21.4, 0.0, 3.6, NULL, 28, 'usda', ARRAY['sensible portions veggie straws', 'vegetable straws', 'garden veggie straws'], '130 cal per 1 oz serving (28g, ~38 straws).', NULL, 'snacks', 1),

-- ============================================================================
-- CRACKERS (~5 items)
-- ============================================================================

-- Ritz Crackers: 500 cal, 5.6g protein, 61.1g carbs, 25.0g fat per 100g. Serving=5 crackers (16g)
-- Check: 5.6*4 + 61.1*4 + 25*9 = 22.4 + 244.4 + 225 = 491.8 (labeled 500)
('ritz_crackers', 'Ritz Crackers', 500.0, 5.6, 61.1, 25.0, 1.9, 11.1, 3, 16, 'usda', ARRAY['ritz', 'ritz original crackers', 'butter crackers'], '80 cal per 5 crackers (16g).', NULL, 'snacks', 5),

-- Goldfish Crackers: 469 cal, 12.5g protein, 62.5g carbs, 18.8g fat per 100g. Serving=55 pieces (30g)
-- Check: 12.5*4 + 62.5*4 + 18.8*9 = 50 + 250 + 169.2 = 469.2
('goldfish_crackers', 'Goldfish Crackers', 469.0, 12.5, 62.5, 18.8, 3.1, 3.1, NULL, 30, 'usda', ARRAY['goldfish', 'pepperidge farm goldfish', 'cheddar goldfish'], '140 cal per 55 pieces (30g).', NULL, 'snacks', 1),

-- Wheat Thins: 467 cal, 6.7g protein, 66.7g carbs, 20.0g fat per 100g. Serving=16 crackers (31g)
-- Check: 6.7*4 + 66.7*4 + 20*9 = 26.8 + 266.8 + 180 = 473.6 (labeled 467)
('wheat_thins', 'Wheat Thins', 467.0, 6.7, 66.7, 20.0, 3.3, 16.7, NULL, 31, 'usda', ARRAY['wheat thins original', 'nabisco wheat thins'], '140 cal per 16 crackers (31g).', NULL, 'snacks', 1),

-- Triscuit: 433 cal, 10.0g protein, 70.0g carbs, 13.3g fat per 100g. Serving=6 crackers (28g)
-- Check: 10*4 + 70*4 + 13.3*9 = 40 + 280 + 119.7 = 439.7 (labeled 433)
('triscuit', 'Triscuit (Original)', 433.0, 10.0, 70.0, 13.3, 10.0, 0.0, 5, 28, 'usda', ARRAY['triscuit crackers', 'triscuit original', 'woven wheat crackers'], '120 cal per 6 crackers (28g). Whole grain wheat.', NULL, 'snacks', 6),

-- Animal Crackers: 446 cal, 6.3g protein, 75.0g carbs, 14.3g fat per 100g. Serving=16 pieces (30g)
-- Check: 6.3*4 + 75*4 + 14.3*9 = 25.2 + 300 + 128.7 = 453.9 (labeled 446)
('animal_crackers', 'Animal Crackers', 446.0, 6.3, 75.0, 14.3, 1.0, 28.6, NULL, 30, 'usda', ARRAY['barnum animal crackers', 'frosted animal crackers', 'circus animal crackers'], '130 cal per 16 pieces (30g).', NULL, 'snacks', 1),

-- ============================================================================
-- POPCORN (~3 items)
-- ============================================================================

-- Popcorn (air-popped): 375 cal, 12.0g protein, 74.3g carbs, 4.3g fat per 100g. Serving=3 cups popped (24g)
-- Check: 12*4 + 74.3*4 + 4.3*9 = 48 + 297.2 + 38.7 = 383.9 (labeled 375)
('popcorn_air_popped', 'Popcorn (air-popped)', 375.0, 12.0, 74.3, 4.3, 14.4, 0.9, NULL, 24, 'usda', ARRAY['plain popcorn', 'air popped popcorn', 'popcorn no butter', 'unseasoned popcorn'], '90 cal per 3 cups popped (24g).', NULL, 'snacks', 1),

-- Popcorn (microwave, butter flavor): 467 cal, 6.7g protein, 53.3g carbs, 26.7g fat per 100g. Serving=3.5 cups popped (32g)
-- Check: 6.7*4 + 53.3*4 + 26.7*9 = 26.8 + 213.2 + 240.3 = 480.3 (labeled 467)
('popcorn_microwave_butter', 'Popcorn (microwave, butter)', 467.0, 6.7, 53.3, 26.7, 10.0, 0.0, NULL, 32, 'usda', ARRAY['microwave popcorn', 'buttered popcorn', 'popcorn butter', 'orville redenbacher butter'], '150 cal per 3.5 cups popped (32g).', NULL, 'snacks', 1),

-- Popcorn (movie theater, with butter): 550 cal, 5.0g protein, 42.0g carbs, 40.0g fat per 100g. Serving=medium tub (115g)
-- Check: 5*4 + 42*4 + 40*9 = 20 + 168 + 360 = 548
('popcorn_movie_theater', 'Popcorn (movie theater, buttered)', 550.0, 5.0, 42.0, 40.0, 7.0, 0.5, NULL, 115, 'usda', ARRAY['theater popcorn', 'cinema popcorn', 'movie popcorn butter', 'amc popcorn', 'regal popcorn'], '633 cal per medium tub (115g). With butter topping.', NULL, 'snacks', 1),

-- ============================================================================
-- CHOCOLATE (~5 items)
-- ============================================================================

-- Dark Chocolate (70-85% cacao): 598 cal, 7.8g protein, 45.9g carbs, 42.6g fat per 100g. Serving=1oz (28g)
-- Check: 7.8*4 + 45.9*4 + 42.6*9 = 31.2 + 183.6 + 383.4 = 598.2
('dark_chocolate', 'Dark Chocolate (70-85%)', 598.0, 7.8, 45.9, 42.6, 10.9, 24.0, NULL, 28, 'usda', ARRAY['dark chocolate bar', 'bittersweet chocolate', 'cacao chocolate', '70 percent chocolate', '85 percent dark chocolate'], '170 cal per 1 oz (28g). Rich in antioxidants.', NULL, 'snacks', 1),

-- Milk Chocolate Bar: 535 cal, 7.6g protein, 59.4g carbs, 29.7g fat per 100g. Serving=1.5oz bar (43g)
-- Check: 7.6*4 + 59.4*4 + 29.7*9 = 30.4 + 237.6 + 267.3 = 535.3
('milk_chocolate', 'Milk Chocolate Bar', 535.0, 7.6, 59.4, 29.7, 3.4, 52.0, NULL, 43, 'usda', ARRAY['milk chocolate', 'hershey bar', 'chocolate bar', 'hersheys milk chocolate'], '230 cal per 1.5 oz bar (43g).', NULL, 'snacks', 1),

-- White Chocolate: 539 cal, 5.9g protein, 59.2g carbs, 32.1g fat per 100g. Serving=1oz (28g)
-- Check: 5.9*4 + 59.2*4 + 32.1*9 = 23.6 + 236.8 + 288.9 = 549.3 (labeled 539)
('white_chocolate', 'White Chocolate', 539.0, 5.9, 59.2, 32.1, 0.2, 59.0, NULL, 28, 'usda', ARRAY['white chocolate bar', 'white chocolate chips'], '151 cal per 1 oz (28g).', NULL, 'snacks', 1),

-- Chocolate Chips (semi-sweet): 480 cal, 4.5g protein, 63.4g carbs, 26.7g fat per 100g. Serving=1 tbsp (15g)
-- Check: 4.5*4 + 63.4*4 + 26.7*9 = 18 + 253.6 + 240.3 = 511.9 (labeled 480, fiber offsets)
('chocolate_chips', 'Chocolate Chips (semi-sweet)', 480.0, 4.5, 63.4, 26.7, 7.0, 47.0, NULL, 15, 'usda', ARRAY['semisweet chocolate chips', 'baking chips', 'nestle toll house chips', 'chocolate morsels'], '70 cal per 1 tbsp (15g).', NULL, 'snacks', 1),

-- M&Ms (Peanut): 502 cal, 9.6g protein, 57.4g carbs, 26.2g fat per 100g. Serving=1.74oz bag (49g)
-- Check: 9.6*4 + 57.4*4 + 26.2*9 = 38.4 + 229.6 + 235.8 = 503.8
('mms_peanut', 'M&Ms (Peanut)', 502.0, 9.6, 57.4, 26.2, 2.0, 50.8, NULL, 49, 'usda', ARRAY['peanut m&ms', 'peanut m and ms', 'mms peanut', 'peanut mm'], '250 cal per 1.74 oz sharing bag (49g).', NULL, 'snacks', 1),

-- ============================================================================
-- DRIED / TRAIL (~5 items)
-- ============================================================================

-- Beef Jerky: 315 cal, 52.0g protein, 11.0g carbs, 7.3g fat per 100g. Serving=1oz (28g)
-- Check: 52*4 + 11*4 + 7.3*9 = 208 + 44 + 65.7 = 317.7 (labeled 315)
('beef_jerky', 'Beef Jerky', 315.0, 52.0, 11.0, 7.3, 0.5, 9.0, NULL, 28, 'usda', ARRAY['beef jerky original', 'jack links beef jerky', 'dried beef', 'jerky'], '80 cal per 1 oz (28g). High protein snack.', NULL, 'snacks', 1),

-- Turkey Jerky: 254 cal, 47.8g protein, 11.3g carbs, 1.7g fat per 100g. Serving=1oz (28g)
-- Check: 47.8*4 + 11.3*4 + 1.7*9 = 191.2 + 45.2 + 15.3 = 251.7 (labeled 254)
('turkey_jerky', 'Turkey Jerky', 254.0, 47.8, 11.3, 1.7, 0.5, 9.5, NULL, 28, 'usda', ARRAY['turkey jerky original', 'dried turkey', 'jack links turkey jerky'], '70 cal per 1 oz (28g). Leaner than beef jerky.', NULL, 'snacks', 1),

-- Trail Mix (standard: nuts, raisins, chocolate): 462 cal, 13.0g protein, 44.6g carbs, 29.3g fat per 100g. Serving=1/4 cup (40g)
-- Check: 13*4 + 44.6*4 + 29.3*9 = 52 + 178.4 + 263.7 = 494.1 (labeled 462, fiber offsets)
('trail_mix', 'Trail Mix (standard)', 462.0, 13.0, 44.6, 29.3, 3.5, 30.0, NULL, 40, 'usda', ARRAY['trail mix nuts raisins', 'hiking mix', 'student mix', 'nut and fruit mix'], '185 cal per 1/4 cup (40g).', NULL, 'snacks', 1),

-- Dried Fruit Mix: 325 cal, 2.5g protein, 82.0g carbs, 0.5g fat per 100g. Serving=1/4 cup (40g)
-- Check: 2.5*4 + 82*4 + 0.5*9 = 10 + 328 + 4.5 = 342.5 (labeled 325, fiber/sugar alcohols)
('dried_fruit_mix', 'Dried Fruit Mix', 325.0, 2.5, 82.0, 0.5, 5.0, 66.0, NULL, 40, 'usda', ARRAY['mixed dried fruit', 'dried fruit medley', 'dried cranberries raisins apricots'], '130 cal per 1/4 cup (40g).', NULL, 'snacks', 1),

-- Roasted Chickpeas: 420 cal, 19.0g protein, 55.0g carbs, 14.0g fat per 100g. Serving=1/3 cup (40g)
-- Check: 19*4 + 55*4 + 14*9 = 76 + 220 + 126 = 422
('roasted_chickpeas', 'Roasted Chickpeas', 420.0, 19.0, 55.0, 14.0, 10.0, 3.0, NULL, 40, 'usda', ARRAY['crunchy chickpeas', 'crispy chickpeas', 'biena chickpeas', 'roasted garbanzo beans'], '168 cal per 1/3 cup (40g). High fiber, high protein.', NULL, 'snacks', 1),

-- ============================================================================
-- OTHER SNACKS (~8 items)
-- ============================================================================

-- Pretzels (hard): 381 cal, 9.2g protein, 79.2g carbs, 3.5g fat per 100g. Serving=1oz (28g)
-- Check: 9.2*4 + 79.2*4 + 3.5*9 = 36.8 + 316.8 + 31.5 = 385.1 (labeled 381)
('pretzels', 'Pretzels (hard)', 381.0, 9.2, 79.2, 3.5, 2.8, 2.0, NULL, 28, 'usda', ARRAY['hard pretzels', 'pretzel twists', 'snyder pretzels', 'rold gold pretzels', 'mini pretzels'], '110 cal per 1 oz (28g, ~17 mini pretzels).', NULL, 'snacks', 1),

-- Pretzel Rods: 378 cal, 9.5g protein, 78.6g carbs, 3.6g fat per 100g. Serving=3 rods (29g)
-- Check: 9.5*4 + 78.6*4 + 3.6*9 = 38 + 314.4 + 32.4 = 384.8 (labeled 378)
('pretzel_rods', 'Pretzel Rods', 378.0, 9.5, 78.6, 3.6, 2.5, 2.0, 10, 29, 'usda', ARRAY['pretzel sticks', 'pretzel rod', 'long pretzels'], '110 cal per 3 rods (29g).', NULL, 'snacks', 3),

-- Rice Crisps/Chips: 407 cal, 7.1g protein, 78.6g carbs, 7.1g fat per 100g. Serving=1oz (28g)
-- Check: 7.1*4 + 78.6*4 + 7.1*9 = 28.4 + 314.4 + 63.9 = 406.7
('rice_crisps', 'Rice Crisps', 407.0, 7.1, 78.6, 7.1, 0.0, 3.6, NULL, 28, 'usda', ARRAY['rice chips', 'quaker rice crisps', 'rice snacks', 'rice cakes chips'], '114 cal per 1 oz serving (28g).', NULL, 'snacks', 1),

-- Pork Rinds: 544 cal, 61.3g protein, 0.0g carbs, 31.3g fat per 100g. Serving=0.5oz (14g)
-- Check: 61.3*4 + 0*4 + 31.3*9 = 245.2 + 0 + 281.7 = 526.9 (labeled 544)
('pork_rinds', 'Pork Rinds', 544.0, 61.3, 0.0, 31.3, 0.0, 0.0, NULL, 14, 'usda', ARRAY['chicharrones', 'pork cracklins', 'fried pork skins', 'pork skins'], '80 cal per 0.5 oz (14g). Zero carbs.', NULL, 'snacks', 1),

-- Cheese Puffs: 536 cal, 7.1g protein, 53.6g carbs, 33.9g fat per 100g. Serving=1oz (28g)
-- Check: 7.1*4 + 53.6*4 + 33.9*9 = 28.4 + 214.4 + 305.1 = 547.9 (labeled 536)
('cheese_puffs', 'Cheese Puffs', 536.0, 7.1, 53.6, 33.9, 0.0, 3.6, NULL, 28, 'usda', ARRAY['cheese balls', 'cheese curls', 'pirate booty', 'cheese doodles'], '150 cal per 1 oz (28g).', NULL, 'snacks', 1),

-- Fruit Snacks: 357 cal, 3.6g protein, 82.1g carbs, 1.8g fat per 100g. Serving=1 pouch (25g)
-- Check: 3.6*4 + 82.1*4 + 1.8*9 = 14.4 + 328.4 + 16.2 = 359 (labeled 357)
('fruit_snacks', 'Fruit Snacks', 357.0, 3.6, 82.1, 1.8, 0.0, 46.4, NULL, 25, 'usda', ARRAY['welchs fruit snacks', 'gummy fruit snacks', 'motts fruit snacks', 'fruit gummies'], '90 cal per 1 pouch (25g).', NULL, 'snacks', 1),

-- Gummy Bears: 343 cal, 6.9g protein, 77.4g carbs, 0.1g fat per 100g. Serving=~17 pieces (40g)
-- Check: 6.9*4 + 77.4*4 + 0.1*9 = 27.6 + 309.6 + 0.9 = 338.1 (labeled 343)
('gummy_bears', 'Gummy Bears', 343.0, 6.9, 77.4, 0.1, 0.0, 46.0, NULL, 40, 'usda', ARRAY['haribo gummy bears', 'gummi bears', 'gold bears', 'haribo gold bears'], '140 cal per ~17 pieces (40g).', NULL, 'snacks', 1),

-- Mixed Nuts (honey roasted): 557 cal, 16.0g protein, 32.0g carbs, 43.0g fat per 100g. Serving=1oz (28g)
-- Check: 16*4 + 32*4 + 43*9 = 64 + 128 + 387 = 579 (labeled 557, fiber offsets)
('mixed_nuts_honey_roasted', 'Mixed Nuts (honey roasted)', 557.0, 16.0, 32.0, 43.0, 4.0, 18.0, NULL, 28, 'usda', ARRAY['honey roasted nuts', 'planters honey roasted', 'honey nut mix', 'sweet mixed nuts'], '156 cal per 1 oz (28g).', NULL, 'snacks', 1),

-- ============================================================================
-- PROTEIN POWDERS & SUPPLEMENTS (~8 items)
-- ============================================================================

-- Whey Protein Powder (Vanilla): 375 cal, 78.1g protein, 12.5g carbs, 3.1g fat per 100g. Serving=1 scoop (32g)
-- Check: 78.1*4 + 12.5*4 + 3.1*9 = 312.4 + 50 + 27.9 = 390.3 (labeled 375)
('whey_protein_vanilla', 'Whey Protein Powder (Vanilla)', 375.0, 78.1, 12.5, 3.1, 0.0, 3.1, NULL, 32, 'usda', ARRAY['vanilla whey protein', 'vanilla protein powder', 'whey isolate vanilla', 'gold standard vanilla'], '120 cal per scoop (32g). ~25g protein per scoop.', NULL, 'snacks', 1),

-- Whey Protein Powder (Chocolate): 381 cal, 75.0g protein, 15.6g carbs, 3.1g fat per 100g. Serving=1 scoop (34g)
-- Check: 75*4 + 15.6*4 + 3.1*9 = 300 + 62.4 + 27.9 = 390.3 (labeled 381)
('whey_protein_chocolate', 'Whey Protein Powder (Chocolate)', 381.0, 75.0, 15.6, 3.1, 2.9, 3.1, NULL, 34, 'usda', ARRAY['chocolate whey protein', 'chocolate protein powder', 'whey isolate chocolate', 'gold standard chocolate'], '130 cal per scoop (34g). ~25g protein per scoop.', NULL, 'snacks', 1),

-- Casein Protein Powder: 357 cal, 78.6g protein, 7.1g carbs, 3.6g fat per 100g. Serving=1 scoop (34g)
-- Check: 78.6*4 + 7.1*4 + 3.6*9 = 314.4 + 28.4 + 32.4 = 375.2 (labeled 357)
('casein_protein_powder', 'Casein Protein Powder', 357.0, 78.6, 7.1, 3.6, 0.0, 1.4, NULL, 34, 'usda', ARRAY['casein powder', 'micellar casein', 'slow release protein', 'night protein'], '120 cal per scoop (34g). ~27g protein. Slow-digesting.', NULL, 'snacks', 1),

-- Plant Protein Powder (pea/rice blend): 367 cal, 73.3g protein, 13.3g carbs, 3.3g fat per 100g. Serving=1 scoop (33g)
-- Check: 73.3*4 + 13.3*4 + 3.3*9 = 293.2 + 53.2 + 29.7 = 376.1 (labeled 367)
('plant_protein_powder', 'Plant Protein Powder', 367.0, 73.3, 13.3, 3.3, 3.3, 0.0, NULL, 33, 'usda', ARRAY['vegan protein powder', 'pea protein powder', 'plant based protein', 'orgain protein'], '120 cal per scoop (33g). ~24g protein. Vegan.', NULL, 'snacks', 1),

-- Collagen Powder: 371 cal, 90.0g protein, 0.0g carbs, 0.0g fat per 100g. Serving=1 scoop (11g)
-- Check: 90*4 + 0*4 + 0*9 = 360 (labeled 371)
('collagen_powder', 'Collagen Powder', 371.0, 90.0, 0.0, 0.0, 0.0, 0.0, NULL, 11, 'usda', ARRAY['collagen peptides', 'vital proteins collagen', 'hydrolyzed collagen', 'collagen supplement'], '40 cal per scoop (11g). ~10g protein. Supports joints/skin.', NULL, 'snacks', 1),

-- Creatine Monohydrate: 0 cal, 0.0g protein, 0.0g carbs, 0.0g fat per 100g. Serving=1 tsp (5g)
('creatine_monohydrate', 'Creatine Monohydrate', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 5, 'usda', ARRAY['creatine', 'creatine powder', 'micronized creatine', 'creatine supplement'], '0 cal per 1 tsp (5g). 5g serving standard dose.', NULL, 'snacks', 1),

-- BCAA Powder: 0 cal, 0.0g protein, 0.0g carbs, 0.0g fat per 100g. Serving=1 scoop (7g)
-- Note: BCAAs have ~4 cal/g but are typically labeled as 0 cal due to FDA labeling rules
('bcaa_powder', 'BCAA Powder', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 7, 'usda', ARRAY['bcaa', 'branched chain amino acids', 'bcaas', 'amino acid powder', 'xtend bcaa'], '0 cal per scoop (7g). Contains leucine, isoleucine, valine.', NULL, 'snacks', 1),

-- Mass Gainer Powder: 385 cal, 15.4g protein, 73.1g carbs, 3.8g fat per 100g. Serving=2 scoops (165g)
-- Check: 15.4*4 + 73.1*4 + 3.8*9 = 61.6 + 292.4 + 34.2 = 388.2 (labeled 385)
('mass_gainer_powder', 'Mass Gainer Powder', 385.0, 15.4, 73.1, 3.8, 1.9, 11.5, NULL, 165, 'usda', ARRAY['mass gainer', 'weight gainer', 'serious mass', 'muscle gainer', 'bulking powder'], '630 cal per 2 scoops (165g). ~25g protein. For muscle gain.', NULL, 'snacks', 1),

-- ============================================================================
-- CANDY (~5 items)
-- ============================================================================

-- Snickers Bar: 488 cal, 7.5g protein, 59.5g carbs, 24.0g fat per 100g. Serving=1 bar (52.7g)
-- Check: 7.5*4 + 59.5*4 + 24*9 = 30 + 238 + 216 = 484 (labeled 488)
('snickers_bar', 'Snickers Bar', 488.0, 7.5, 59.5, 24.0, 1.4, 48.0, 53, 53, 'usda', ARRAY['snickers', 'snickers original', 'snickers candy bar'], '250 cal per bar (52.7g).', NULL, 'snacks', 1),

-- Reese's Peanut Butter Cups (2 cups): 503 cal, 10.7g protein, 53.6g carbs, 28.6g fat per 100g. Serving=1 pack (42g)
-- Check: 10.7*4 + 53.6*4 + 28.6*9 = 42.8 + 214.4 + 257.4 = 514.6 (labeled 503)
('reeses_peanut_butter_cups', 'Reese''s Peanut Butter Cups (2)', 503.0, 10.7, 53.6, 28.6, 2.4, 45.2, 21, 42, 'usda', ARRAY['reeses cups', 'reese''s', 'peanut butter cups', 'reeses peanut butter'], '210 cal per pack of 2 (42g).', NULL, 'snacks', 2),

-- Kit Kat: 518 cal, 7.0g protein, 63.4g carbs, 27.0g fat per 100g. Serving=1 bar (42g)
-- Check: 7*4 + 63.4*4 + 27*9 = 28 + 253.6 + 243 = 524.6 (labeled 518)
('kit_kat', 'Kit Kat', 518.0, 7.0, 63.4, 27.0, 1.0, 48.8, 42, 42, 'usda', ARRAY['kit kat bar', 'kitkat', 'kit kat wafer bar'], '218 cal per 4-piece bar (42g).', NULL, 'snacks', 1),

-- Twix: 502 cal, 4.8g protein, 62.6g carbs, 25.9g fat per 100g. Serving=1 pack/2 bars (50.7g)
-- Check: 4.8*4 + 62.6*4 + 25.9*9 = 19.2 + 250.4 + 233.1 = 502.7
('twix', 'Twix', 502.0, 4.8, 62.6, 25.9, 0.8, 47.5, 25, 51, 'usda', ARRAY['twix bar', 'twix caramel', 'twix cookie bar'], '250 cal per pack of 2 bars (50.7g).', NULL, 'snacks', 2),

-- Skittles: 400 cal, 0.0g protein, 90.7g carbs, 4.3g fat per 100g. Serving=1 bag (56g)
-- Check: 0*4 + 90.7*4 + 4.3*9 = 0 + 362.8 + 38.7 = 401.5
('skittles', 'Skittles', 400.0, 0.0, 90.7, 4.3, 0.0, 75.7, NULL, 56, 'usda', ARRAY['skittles original', 'skittles candy', 'taste the rainbow'], '231 cal per 2.17 oz bag (56g).', NULL, 'snacks', 1),
