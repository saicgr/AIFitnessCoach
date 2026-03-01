-- ============================================================================
-- Batch 28: Common Condiments, Oils, Sauces & Spreads
-- ~55 items commonly logged in fitness/calorie tracking apps
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central, manufacturer nutrition labels
-- All values are per 100g of product
-- Calorie verification: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- OILS (~7 items)
-- ============================================================================

-- Olive Oil (Extra Virgin): 884 cal, 0g protein, 0g carbs, 100g fat per 100g. Serving=1 tbsp (14g)
-- Check: 0*4 + 0*4 + 100*9 = 900 (labeled 884 due to rounding)
('olive_oil', 'Olive Oil (Extra Virgin)', 884.0, 0.0, 0.0, 100.0, 0.0, 0.0, NULL, 14, 'usda', ARRAY['extra virgin olive oil', 'evoo', 'olive oil extra virgin'], '124 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Canola Oil: 884 cal, 0g protein, 0g carbs, 100g fat per 100g. Serving=1 tbsp (14g)
('canola_oil', 'Canola Oil', 884.0, 0.0, 0.0, 100.0, 0.0, 0.0, NULL, 14, 'usda', ARRAY['rapeseed oil', 'vegetable canola oil'], '124 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Coconut Oil: 862 cal, 0g protein, 0g carbs, 100g fat per 100g. Serving=1 tbsp (14g)
-- Check: 100*9 = 900 (labeled 862, MCT content affects metabolizable energy)
('coconut_oil', 'Coconut Oil', 862.0, 0.0, 0.0, 100.0, 0.0, 0.0, NULL, 14, 'usda', ARRAY['virgin coconut oil', 'coconut oil virgin'], '121 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Avocado Oil: 884 cal, 0g protein, 0g carbs, 100g fat per 100g. Serving=1 tbsp (14g)
('avocado_oil', 'Avocado Oil', 884.0, 0.0, 0.0, 100.0, 0.0, 0.0, NULL, 14, 'usda', ARRAY['avocado cooking oil'], '124 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Vegetable Oil (soybean): 884 cal, 0g protein, 0g carbs, 100g fat per 100g. Serving=1 tbsp (14g)
('vegetable_oil', 'Vegetable Oil', 884.0, 0.0, 0.0, 100.0, 0.0, 0.0, NULL, 14, 'usda', ARRAY['soybean oil', 'cooking oil', 'salad oil'], '124 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Sesame Oil: 884 cal, 0g protein, 0g carbs, 100g fat per 100g. Serving=1 tbsp (14g)
('sesame_oil', 'Sesame Oil', 884.0, 0.0, 0.0, 100.0, 0.0, 0.0, NULL, 14, 'usda', ARRAY['toasted sesame oil', 'dark sesame oil'], '124 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Butter (salted): 717 cal, 0.9g protein, 0.1g carbs, 81.1g fat per 100g. Serving=1 tbsp (14g)
-- Check: 0.9*4 + 0.1*4 + 81.1*9 = 3.6 + 0.4 + 729.9 = 733.9 (labeled 717, water content)
('butter', 'Butter (salted)', 717.0, 0.9, 0.1, 81.1, 0.0, 0.1, NULL, 14, 'usda', ARRAY['salted butter', 'unsalted butter', 'stick butter', 'butter stick'], '100 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- ============================================================================
-- SWEETENERS (~7 items)
-- ============================================================================

-- White Sugar (granulated): 387 cal, 0g protein, 100g carbs, 0g fat per 100g. Serving=1 tsp (4g)
-- Check: 0*4 + 100*4 + 0*9 = 400 (labeled 387 due to sucrose energy factor 3.87)
('white_sugar', 'White Sugar (granulated)', 387.0, 0.0, 100.0, 0.0, 0.0, 100.0, NULL, 4, 'usda', ARRAY['granulated sugar', 'table sugar', 'cane sugar', 'sugar'], '15 cal per 1 tsp (4g).', NULL, 'condiments', 1),

-- Brown Sugar: 380 cal, 0g protein, 98.1g carbs, 0g fat per 100g. Serving=1 tsp (4.6g)
-- Check: 98.1*4 = 392.4 (labeled 380)
('brown_sugar', 'Brown Sugar', 380.0, 0.0, 98.1, 0.0, 0.0, 97.0, NULL, 5, 'usda', ARRAY['light brown sugar', 'dark brown sugar', 'packed brown sugar'], '17 cal per 1 tsp (4.6g).', NULL, 'condiments', 1),

-- Honey: 304 cal, 0.3g protein, 82.4g carbs, 0g fat per 100g. Serving=1 tbsp (21g)
-- Check: 0.3*4 + 82.4*4 + 0*9 = 330.8 (labeled 304, fructose lower energy factor)
('honey', 'Honey', 304.0, 0.3, 82.4, 0.0, 0.2, 82.1, NULL, 21, 'usda', ARRAY['raw honey', 'pure honey', 'clover honey'], '64 cal per 1 tbsp (21g).', NULL, 'condiments', 1),

-- Maple Syrup (pure): 260 cal, 0.0g protein, 67.0g carbs, 0.1g fat per 100g. Serving=1 tbsp (20g)
-- Check: 0*4 + 67*4 + 0.1*9 = 268.9 (labeled 260)
('maple_syrup', 'Maple Syrup (pure)', 260.0, 0.0, 67.0, 0.1, 0.0, 60.4, NULL, 20, 'usda', ARRAY['pure maple syrup', 'real maple syrup', 'grade a maple syrup'], '52 cal per 1 tbsp (20g).', NULL, 'condiments', 1),

-- Agave Nectar: 310 cal, 0.0g protein, 76.4g carbs, 0.5g fat per 100g. Serving=1 tbsp (21g)
-- Check: 0*4 + 76.4*4 + 0.5*9 = 310.1
('agave_nectar', 'Agave Nectar', 310.0, 0.0, 76.4, 0.5, 0.2, 68.0, NULL, 21, 'usda', ARRAY['agave syrup', 'light agave', 'blue agave nectar'], '65 cal per 1 tbsp (21g).', NULL, 'condiments', 1),

-- Powdered Sugar: 389 cal, 0g protein, 99.8g carbs, 0g fat per 100g. Serving=1 tbsp (8g)
-- Check: 99.8*4 = 399.2 (labeled 389)
('powdered_sugar', 'Powdered Sugar', 389.0, 0.0, 99.8, 0.0, 0.0, 97.8, NULL, 8, 'usda', ARRAY['confectioners sugar', 'icing sugar', '10x sugar'], '31 cal per 1 tbsp (8g).', NULL, 'condiments', 1),

-- Molasses: 290 cal, 0g protein, 74.7g carbs, 0.1g fat per 100g. Serving=1 tbsp (20g)
-- Check: 0*4 + 74.7*4 + 0.1*9 = 299.7 (labeled 290)
('molasses', 'Molasses', 290.0, 0.0, 74.7, 0.1, 0.0, 74.7, NULL, 20, 'usda', ARRAY['blackstrap molasses', 'dark molasses', 'light molasses'], '58 cal per 1 tbsp (20g).', NULL, 'condiments', 1),

-- ============================================================================
-- SAUCES (~15 items)
-- ============================================================================

-- Ketchup: 112 cal, 1.7g protein, 25.8g carbs, 0.1g fat per 100g. Serving=1 tbsp (17g)
-- Check: 1.7*4 + 25.8*4 + 0.1*9 = 110.9
('ketchup', 'Ketchup', 112.0, 1.7, 25.8, 0.1, 0.3, 22.8, NULL, 17, 'usda', ARRAY['tomato ketchup', 'catsup', 'heinz ketchup'], '19 cal per 1 tbsp (17g).', NULL, 'condiments', 1),

-- Yellow Mustard: 60 cal, 3.7g protein, 5.3g carbs, 3.3g fat per 100g. Serving=1 tsp (5g)
-- Check: 3.7*4 + 5.3*4 + 3.3*9 = 14.8 + 21.2 + 29.7 = 65.7 (labeled 60)
('yellow_mustard', 'Yellow Mustard', 60.0, 3.7, 5.3, 3.3, 3.3, 2.8, NULL, 5, 'usda', ARRAY['prepared mustard', 'classic yellow mustard', 'french mustard'], '3 cal per 1 tsp (5g).', NULL, 'condiments', 1),

-- Dijon Mustard: 66 cal, 3.6g protein, 5.8g carbs, 3.5g fat per 100g. Serving=1 tsp (5g)
-- Check: 3.6*4 + 5.8*4 + 3.5*9 = 14.4 + 23.2 + 31.5 = 69.1 (labeled 66)
('dijon_mustard', 'Dijon Mustard', 66.0, 3.6, 5.8, 3.5, 2.0, 2.2, NULL, 5, 'usda', ARRAY['grey poupon dijon', 'dijon style mustard'], '3 cal per 1 tsp (5g).', NULL, 'condiments', 1),

-- Mayonnaise (regular): 680 cal, 1.0g protein, 0.6g carbs, 74.9g fat per 100g. Serving=1 tbsp (15g)
-- Check: 1.0*4 + 0.6*4 + 74.9*9 = 4 + 2.4 + 674.1 = 680.5
('mayonnaise', 'Mayonnaise', 680.0, 1.0, 0.6, 74.9, 0.0, 0.6, NULL, 15, 'usda', ARRAY['mayo', 'real mayonnaise', 'hellmanns mayo', 'best foods mayo'], '102 cal per 1 tbsp (15g).', NULL, 'condiments', 1),

-- Ranch Dressing: 462 cal, 1.5g protein, 6.1g carbs, 47.8g fat per 100g. Serving=2 tbsp (30g)
-- Check: 1.5*4 + 6.1*4 + 47.8*9 = 6 + 24.4 + 430.2 = 460.6
('ranch_dressing', 'Ranch Dressing', 462.0, 1.5, 6.1, 47.8, 0.2, 3.0, NULL, 30, 'usda', ARRAY['ranch', 'hidden valley ranch', 'buttermilk ranch dressing'], '139 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Italian Dressing: 227 cal, 0.6g protein, 10.0g carbs, 20.8g fat per 100g. Serving=2 tbsp (30g)
-- Check: 0.6*4 + 10.0*4 + 20.8*9 = 2.4 + 40 + 187.2 = 229.6 (labeled 227)
('italian_dressing', 'Italian Dressing', 227.0, 0.6, 10.0, 20.8, 0.1, 8.3, NULL, 30, 'usda', ARRAY['italian salad dressing', 'zesty italian dressing'], '68 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Balsamic Vinaigrette: 186 cal, 0.5g protein, 12.0g carbs, 15.3g fat per 100g. Serving=2 tbsp (30g)
-- Check: 0.5*4 + 12.0*4 + 15.3*9 = 2 + 48 + 137.7 = 187.7
('balsamic_vinaigrette', 'Balsamic Vinaigrette', 186.0, 0.5, 12.0, 15.3, 0.1, 10.5, NULL, 30, 'usda', ARRAY['balsamic dressing', 'balsamic vinaigrette dressing'], '56 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- BBQ Sauce: 172 cal, 0.8g protein, 40.7g carbs, 0.6g fat per 100g. Serving=2 tbsp (36g)
-- Check: 0.8*4 + 40.7*4 + 0.6*9 = 3.2 + 162.8 + 5.4 = 171.4
('bbq_sauce', 'BBQ Sauce', 172.0, 0.8, 40.7, 0.6, 0.5, 33.3, NULL, 36, 'usda', ARRAY['barbecue sauce', 'barbeque sauce', 'sweet baby rays bbq'], '62 cal per 2 tbsp (36g).', NULL, 'condiments', 1),

-- Teriyaki Sauce: 89 cal, 5.9g protein, 15.6g carbs, 0.0g fat per 100g. Serving=1 tbsp (18g)
-- Check: 5.9*4 + 15.6*4 + 0*9 = 23.6 + 62.4 = 86.0 (labeled 89)
('teriyaki_sauce', 'Teriyaki Sauce', 89.0, 5.9, 15.6, 0.0, 0.1, 14.1, NULL, 18, 'usda', ARRAY['teriyaki glaze', 'teriyaki marinade', 'kikkoman teriyaki'], '16 cal per 1 tbsp (18g).', NULL, 'condiments', 1),

-- Soy Sauce: 53 cal, 8.1g protein, 4.9g carbs, 0.0g fat per 100g. Serving=1 tbsp (16g)
-- Check: 8.1*4 + 4.9*4 + 0*9 = 32.4 + 19.6 = 52.0 (labeled 53)
('soy_sauce', 'Soy Sauce', 53.0, 8.1, 4.9, 0.0, 0.0, 0.4, NULL, 16, 'usda', ARRAY['shoyu', 'tamari', 'kikkoman soy sauce', 'soya sauce'], '8 cal per 1 tbsp (16g). High sodium ~879mg per tbsp.', NULL, 'condiments', 1),

-- Worcestershire Sauce: 78 cal, 0.0g protein, 19.5g carbs, 0.0g fat per 100g. Serving=1 tsp (5g)
-- Check: 0*4 + 19.5*4 + 0*9 = 78.0
('worcestershire_sauce', 'Worcestershire Sauce', 78.0, 0.0, 19.5, 0.0, 0.0, 10.0, NULL, 5, 'usda', ARRAY['worcester sauce', 'lea perrins worcestershire'], '4 cal per 1 tsp (5g).', NULL, 'condiments', 1),

-- Buffalo/Hot Sauce: 33 cal, 0.5g protein, 6.7g carbs, 0.4g fat per 100g. Serving=1 tsp (5g)
-- Check: 0.5*4 + 6.7*4 + 0.4*9 = 2 + 26.8 + 3.6 = 32.4 (labeled 33)
('buffalo_sauce', 'Buffalo Hot Sauce', 33.0, 0.5, 6.7, 0.4, 0.5, 0.2, NULL, 5, 'usda', ARRAY['hot sauce', 'wing sauce', 'buffalo wing sauce', 'cayenne pepper sauce'], '2 cal per 1 tsp (5g).', NULL, 'condiments', 1),

-- Marinara Sauce: 50 cal, 1.5g protein, 7.8g carbs, 1.5g fat per 100g. Serving=1/2 cup (125g)
-- Check: 1.5*4 + 7.8*4 + 1.5*9 = 6 + 31.2 + 13.5 = 50.7
('marinara_sauce', 'Marinara Sauce', 50.0, 1.5, 7.8, 1.5, 1.5, 5.0, NULL, 125, 'usda', ARRAY['pasta sauce', 'spaghetti sauce', 'tomato marinara', 'red sauce'], '63 cal per 1/2 cup (125g).', NULL, 'condiments', 1),

-- Alfredo Sauce: 177 cal, 3.7g protein, 4.5g carbs, 16.2g fat per 100g. Serving=1/4 cup (62g)
-- Check: 3.7*4 + 4.5*4 + 16.2*9 = 14.8 + 18 + 145.8 = 178.6 (labeled 177)
('alfredo_sauce', 'Alfredo Sauce', 177.0, 3.7, 4.5, 16.2, 0.1, 1.8, NULL, 62, 'usda', ARRAY['white sauce', 'cream sauce', 'fettuccine alfredo sauce'], '110 cal per 1/4 cup (62g).', NULL, 'condiments', 1),

-- Pesto (basil): 375 cal, 5.3g protein, 6.0g carbs, 37.0g fat per 100g. Serving=2 tbsp (30g)
-- Check: 5.3*4 + 6.0*4 + 37.0*9 = 21.2 + 24 + 333 = 378.2 (labeled 375)
('pesto', 'Pesto (basil)', 375.0, 5.3, 6.0, 37.0, 1.0, 1.0, NULL, 30, 'usda', ARRAY['basil pesto', 'pesto sauce', 'genovese pesto'], '113 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- ============================================================================
-- DIPS & SPREADS (~8 items)
-- ============================================================================

-- Salsa (tomato): 36 cal, 1.5g protein, 7.0g carbs, 0.2g fat per 100g. Serving=2 tbsp (32g)
-- Check: 1.5*4 + 7.0*4 + 0.2*9 = 6 + 28 + 1.8 = 35.8
('salsa', 'Salsa (tomato)', 36.0, 1.5, 7.0, 0.2, 1.5, 3.8, NULL, 32, 'usda', ARRAY['tomato salsa', 'chunky salsa', 'pico de gallo', 'restaurant salsa'], '12 cal per 2 tbsp (32g).', NULL, 'condiments', 1),

-- Guacamole: 160 cal, 2.0g protein, 8.5g carbs, 14.7g fat per 100g. Serving=2 tbsp (30g)
-- Check: 2.0*4 + 8.5*4 + 14.7*9 = 8 + 34 + 132.3 = 174.3 (labeled 160, fiber offsets)
('guacamole', 'Guacamole', 160.0, 2.0, 8.5, 14.7, 6.7, 0.7, NULL, 30, 'usda', ARRAY['avocado dip', 'fresh guacamole', 'homemade guacamole'], '48 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Hummus (classic): 166 cal, 7.9g protein, 14.3g carbs, 9.6g fat per 100g. Serving=2 tbsp (30g)
-- Check: 7.9*4 + 14.3*4 + 9.6*9 = 31.6 + 57.2 + 86.4 = 175.2 (labeled 166, fiber)
('hummus', 'Hummus (classic)', 166.0, 7.9, 14.3, 9.6, 6.0, 0.3, NULL, 30, 'usda', ARRAY['classic hummus', 'chickpea hummus', 'sabra hummus', 'hommus'], '50 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Tzatziki: 56 cal, 3.5g protein, 4.0g carbs, 2.7g fat per 100g. Serving=2 tbsp (30g)
-- Check: 3.5*4 + 4.0*4 + 2.7*9 = 14 + 16 + 24.3 = 54.3 (labeled 56)
('tzatziki', 'Tzatziki', 56.0, 3.5, 4.0, 2.7, 0.3, 2.5, NULL, 30, 'usda', ARRAY['cucumber yogurt sauce', 'greek yogurt dip', 'tzatziki sauce'], '17 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Cream Cheese Spread: 342 cal, 5.9g protein, 4.1g carbs, 33.8g fat per 100g. Serving=2 tbsp (29g)
-- Check: 5.9*4 + 4.1*4 + 33.8*9 = 23.6 + 16.4 + 304.2 = 344.2 (labeled 342)
('cream_cheese_spread', 'Cream Cheese Spread', 342.0, 5.9, 4.1, 33.8, 0.0, 3.5, NULL, 29, 'usda', ARRAY['cream cheese', 'philadelphia cream cheese', 'spreadable cream cheese'], '99 cal per 2 tbsp (29g).', NULL, 'condiments', 1),

-- Nutella: 539 cal, 6.3g protein, 57.5g carbs, 30.9g fat per 100g. Serving=2 tbsp (37g)
-- Check: 6.3*4 + 57.5*4 + 30.9*9 = 25.2 + 230 + 278.1 = 533.3 (labeled 539)
('nutella', 'Nutella', 539.0, 6.3, 57.5, 30.9, 3.4, 54.4, NULL, 37, 'usda', ARRAY['hazelnut spread', 'chocolate hazelnut spread', 'nutella spread'], '200 cal per 2 tbsp (37g).', NULL, 'condiments', 1),

-- Jam/Jelly (grape): 250 cal, 0.4g protein, 65.5g carbs, 0.1g fat per 100g. Serving=1 tbsp (20g)
-- Check: 0.4*4 + 65.5*4 + 0.1*9 = 1.6 + 262 + 0.9 = 264.5 (labeled 250, fiber offsets)
('grape_jelly', 'Grape Jelly', 250.0, 0.4, 65.5, 0.1, 0.3, 48.5, NULL, 20, 'usda', ARRAY['grape jam', 'jelly', 'jam', 'fruit preserves', 'strawberry jam'], '50 cal per 1 tbsp (20g).', NULL, 'condiments', 1),

-- Apple Butter: 173 cal, 0.4g protein, 43.0g carbs, 0.5g fat per 100g. Serving=1 tbsp (18g)
-- Check: 0.4*4 + 43.0*4 + 0.5*9 = 1.6 + 172 + 4.5 = 178.1 (labeled 173)
('apple_butter', 'Apple Butter', 173.0, 0.4, 43.0, 0.5, 1.0, 38.0, NULL, 18, 'usda', ARRAY['fruit butter', 'apple butter spread'], '31 cal per 1 tbsp (18g).', NULL, 'condiments', 1),

-- ============================================================================
-- VINEGAR (~3 items)
-- ============================================================================

-- Balsamic Vinegar: 88 cal, 0.5g protein, 17.0g carbs, 0.0g fat per 100g. Serving=1 tbsp (16g)
-- Check: 0.5*4 + 17.0*4 + 0*9 = 2 + 68 = 70 (labeled 88, organic acids contribute energy)
('balsamic_vinegar', 'Balsamic Vinegar', 88.0, 0.5, 17.0, 0.0, 0.0, 12.3, NULL, 16, 'usda', ARRAY['balsamic', 'modena vinegar', 'aged balsamic'], '14 cal per 1 tbsp (16g).', NULL, 'condiments', 1),

-- Apple Cider Vinegar: 21 cal, 0.0g protein, 0.9g carbs, 0.0g fat per 100g. Serving=1 tbsp (15g)
-- Check: 0*4 + 0.9*4 + 0*9 = 3.6 (labeled 21, acetic acid provides energy)
('apple_cider_vinegar', 'Apple Cider Vinegar', 21.0, 0.0, 0.9, 0.0, 0.0, 0.4, NULL, 15, 'usda', ARRAY['acv', 'cider vinegar', 'braggs apple cider vinegar'], '3 cal per 1 tbsp (15g).', NULL, 'condiments', 1),

-- Rice Vinegar: 18 cal, 0.0g protein, 0.5g carbs, 0.0g fat per 100g. Serving=1 tbsp (15g)
-- Check: 0*4 + 0.5*4 + 0*9 = 2.0 (labeled 18, acetic acid)
('rice_vinegar', 'Rice Vinegar', 18.0, 0.0, 0.5, 0.0, 0.0, 0.5, NULL, 15, 'usda', ARRAY['rice wine vinegar', 'seasoned rice vinegar'], '3 cal per 1 tbsp (15g).', NULL, 'condiments', 1),

-- ============================================================================
-- OTHER SAUCES & CONDIMENTS (~10 items)
-- ============================================================================

-- Tartar Sauce: 352 cal, 0.9g protein, 9.5g carbs, 34.5g fat per 100g. Serving=2 tbsp (30g)
-- Check: 0.9*4 + 9.5*4 + 34.5*9 = 3.6 + 38 + 310.5 = 352.1
('tartar_sauce', 'Tartar Sauce', 352.0, 0.9, 9.5, 34.5, 0.3, 6.5, NULL, 30, 'usda', ARRAY['tartare sauce', 'fish sauce dip'], '106 cal per 2 tbsp (30g).', NULL, 'condiments', 1),

-- Cocktail Sauce: 120 cal, 1.4g protein, 27.3g carbs, 0.8g fat per 100g. Serving=2 tbsp (34g)
-- Check: 1.4*4 + 27.3*4 + 0.8*9 = 5.6 + 109.2 + 7.2 = 122.0 (labeled 120)
('cocktail_sauce', 'Cocktail Sauce', 120.0, 1.4, 27.3, 0.8, 0.5, 22.1, NULL, 34, 'usda', ARRAY['seafood sauce', 'shrimp cocktail sauce'], '41 cal per 2 tbsp (34g).', NULL, 'condiments', 1),

-- Horseradish (prepared): 48 cal, 1.2g protein, 11.3g carbs, 0.7g fat per 100g. Serving=1 tsp (5g)
-- Check: 1.2*4 + 11.3*4 + 0.7*9 = 4.8 + 45.2 + 6.3 = 56.3 (labeled 48, fiber offsets)
('horseradish', 'Horseradish (prepared)', 48.0, 1.2, 11.3, 0.7, 3.3, 7.3, NULL, 5, 'usda', ARRAY['prepared horseradish', 'horseradish sauce'], '2 cal per 1 tsp (5g).', NULL, 'condiments', 1),

-- Pickle Relish (sweet): 131 cal, 0.5g protein, 33.5g carbs, 0.5g fat per 100g. Serving=1 tbsp (15g)
-- Check: 0.5*4 + 33.5*4 + 0.5*9 = 2 + 134 + 4.5 = 140.5 (labeled 131)
('pickle_relish', 'Pickle Relish (sweet)', 131.0, 0.5, 33.5, 0.5, 0.5, 28.6, NULL, 15, 'usda', ARRAY['sweet relish', 'dill relish', 'hot dog relish'], '20 cal per 1 tbsp (15g).', NULL, 'condiments', 1),

-- Olive Oil Mayonnaise: 487 cal, 0.8g protein, 3.3g carbs, 52.4g fat per 100g. Serving=1 tbsp (14g)
-- Check: 0.8*4 + 3.3*4 + 52.4*9 = 3.2 + 13.2 + 471.6 = 488.0 (labeled 487)
('olive_oil_mayo', 'Olive Oil Mayonnaise', 487.0, 0.8, 3.3, 52.4, 0.0, 1.7, NULL, 14, 'usda', ARRAY['olive oil mayo', 'light olive oil mayo', 'hellmanns olive oil mayo'], '68 cal per 1 tbsp (14g).', NULL, 'condiments', 1),

-- Chipotle Mayo: 500 cal, 0.7g protein, 3.3g carbs, 53.3g fat per 100g. Serving=1 tbsp (15g)
-- Check: 0.7*4 + 3.3*4 + 53.3*9 = 2.8 + 13.2 + 479.7 = 495.7 (labeled 500)
('chipotle_mayo', 'Chipotle Mayo', 500.0, 0.7, 3.3, 53.3, 0.3, 1.7, NULL, 15, 'usda', ARRAY['chipotle mayonnaise', 'chipotle aioli', 'spicy mayo'], '75 cal per 1 tbsp (15g).', NULL, 'condiments', 1),

-- Sriracha: 93 cal, 2.0g protein, 18.5g carbs, 1.0g fat per 100g. Serving=1 tsp (5g)
-- Check: 2.0*4 + 18.5*4 + 1.0*9 = 8 + 74 + 9 = 91.0 (labeled 93)
('sriracha', 'Sriracha', 93.0, 2.0, 18.5, 1.0, 0.5, 15.0, NULL, 5, 'usda', ARRAY['sriracha sauce', 'rooster sauce', 'huy fong sriracha', 'chili garlic sauce'], '5 cal per 1 tsp (5g).', NULL, 'condiments', 1),

-- Frank's Red Hot: 0 cal, 0.0g protein, 0.0g carbs, 0.0g fat per 100g. Serving=1 tsp (5g)
-- (virtually zero calories, mainly vinegar and cayenne pepper)
('franks_red_hot', 'Frank''s RedHot Sauce', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 5, 'usda', ARRAY['franks hot sauce', 'frank red hot', 'franks buffalo sauce', 'cayenne pepper sauce'], '0 cal per 1 tsp (5g). 190mg sodium per tsp.', NULL, 'condiments', 1),

-- Hoisin Sauce: 220 cal, 3.3g protein, 44.1g carbs, 3.4g fat per 100g. Serving=1 tbsp (16g)
-- Check: 3.3*4 + 44.1*4 + 3.4*9 = 13.2 + 176.4 + 30.6 = 220.2
('hoisin_sauce', 'Hoisin Sauce', 220.0, 3.3, 44.1, 3.4, 1.5, 32.5, NULL, 16, 'usda', ARRAY['hoisin', 'chinese bbq sauce', 'peking sauce'], '35 cal per 1 tbsp (16g).', NULL, 'condiments', 1),

-- Fish Sauce: 35 cal, 5.1g protein, 3.6g carbs, 0.0g fat per 100g. Serving=1 tbsp (18g)
-- Check: 5.1*4 + 3.6*4 + 0*9 = 20.4 + 14.4 = 34.8 (labeled 35)
('fish_sauce', 'Fish Sauce', 35.0, 5.1, 3.6, 0.0, 0.0, 3.6, NULL, 18, 'usda', ARRAY['nam pla', 'nuoc mam', 'thai fish sauce'], '6 cal per 1 tbsp (18g). Very high sodium ~1400mg per tbsp.', NULL, 'condiments', 1),

-- ============================================================================
-- TOPPINGS (~5 items)
-- ============================================================================

-- Pickles (dill): 11 cal, 0.3g protein, 2.3g carbs, 0.2g fat per 100g. Serving=1 spear (35g)
-- Check: 0.3*4 + 2.3*4 + 0.2*9 = 1.2 + 9.2 + 1.8 = 12.2 (labeled 11)
('pickles_dill', 'Pickles (dill)', 11.0, 0.3, 2.3, 0.2, 1.2, 1.1, 35, 35, 'usda', ARRAY['dill pickle', 'kosher dill pickle', 'pickle spear', 'dill pickle spear'], '4 cal per 1 spear (35g).', NULL, 'condiments', 1),

-- Olives (black, ripe): 115 cal, 0.8g protein, 6.3g carbs, 10.7g fat per 100g. Serving=5 olives (20g)
-- Check: 0.8*4 + 6.3*4 + 10.7*9 = 3.2 + 25.2 + 96.3 = 124.7 (labeled 115, fiber)
('olives_black', 'Olives (black, ripe)', 115.0, 0.8, 6.3, 10.7, 3.2, 0.0, 4, 20, 'usda', ARRAY['black olives', 'ripe olives', 'canned black olives', 'sliced black olives'], '23 cal per 5 olives (20g).', NULL, 'condiments', 5),

-- Olives (green): 145 cal, 1.0g protein, 3.8g carbs, 15.3g fat per 100g. Serving=5 olives (20g)
-- Check: 1.0*4 + 3.8*4 + 15.3*9 = 4 + 15.2 + 137.7 = 156.9 (labeled 145, fiber/water)
('olives_green', 'Olives (green)', 145.0, 1.0, 3.8, 15.3, 3.3, 0.5, 4, 20, 'usda', ARRAY['green olives', 'manzanilla olives', 'stuffed olives', 'pimento olives'], '29 cal per 5 olives (20g).', NULL, 'condiments', 5),

-- Capers: 23 cal, 2.4g protein, 1.7g carbs, 0.9g fat per 100g. Serving=1 tbsp (9g)
-- Check: 2.4*4 + 1.7*4 + 0.9*9 = 9.6 + 6.8 + 8.1 = 24.5 (labeled 23)
('capers', 'Capers', 23.0, 2.4, 1.7, 0.9, 3.2, 0.4, NULL, 9, 'usda', ARRAY['caper berries', 'nonpareille capers'], '2 cal per 1 tbsp (9g).', NULL, 'condiments', 1),

-- Sun-Dried Tomatoes: 258 cal, 14.1g protein, 55.8g carbs, 3.0g fat per 100g. Serving=5 pieces (10g)
-- Check: 14.1*4 + 55.8*4 + 3.0*9 = 56.4 + 223.2 + 27 = 306.6 (labeled 258, high fiber offsets)
('sun_dried_tomatoes', 'Sun-Dried Tomatoes', 258.0, 14.1, 55.8, 3.0, 12.3, 37.6, 2, 10, 'usda', ARRAY['sundried tomatoes', 'dried tomatoes', 'sun dried tomato'], '26 cal per 5 pieces (10g).', NULL, 'condiments', 5),
