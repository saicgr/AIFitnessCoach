-- ============================================================================
-- Batch 1: Restaurant Nutrition Data
-- Restaurants: McDonald's, Chick-fil-A, Starbucks, Taco Bell, Wendy's,
--              Burger King, Subway, Dunkin', Domino's, Popeyes
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, fastfoodnutrition.org,
--          nutritionvalue.org, fatsecret.com, eatthismuch.com, nutritionix.com,
--          snapcalorie.com, calorieking.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- McDONALD'S (expanding beyond existing 16 items)
-- ============================================================================

-- Big Mac: 580 cal, 34g fat, 25g protein, 45g carbs, 3g fiber, 7g sugar per 219g
('mcdonalds_big_mac', 'McDonald''s Big Mac', 264.8, 11.4, 20.5, 15.5, 1.4, 3.2, 219, 219, 'mcdonalds.com', ARRAY['big mac', 'bigmac'], '580 cal per sandwich (219g)'),

-- Quarter Pounder with Cheese: 520 cal, 26g fat, 30g protein, 42g carbs, 2g fiber, 10g sugar per 202g
('mcdonalds_quarter_pounder_cheese', 'McDonald''s Quarter Pounder with Cheese', 257.4, 14.9, 20.8, 12.9, 1.0, 5.0, 202, 202, 'mcdonalds.com', ARRAY['quarter pounder', 'qpc', 'quarter pounder with cheese'], '520 cal per sandwich (202g)'),

-- McDouble: 390 cal, 20g fat, 22g protein, 32g carbs, 2g fiber, 6g sugar per 147g
('mcdonalds_mcdouble', 'McDonald''s McDouble', 265.3, 15.0, 21.8, 13.6, 1.4, 4.1, 147, 147, 'mcdonalds.com', ARRAY['mcdouble', 'mc double'], '390 cal per sandwich (147g)'),

-- Double Cheeseburger: 440 cal, 24g fat, 25g protein, 34g carbs, 2g fiber, 6g sugar per 165g
('mcdonalds_double_cheeseburger', 'McDonald''s Double Cheeseburger', 266.7, 15.2, 20.6, 14.5, 1.2, 3.6, 165, 165, 'mcdonalds.com', ARRAY['double cheeseburger', 'double cheese burger'], '440 cal per sandwich (165g)'),

-- Hamburger: 250 cal, 9g fat, 12g protein, 30g carbs, 1g fiber, 5g sugar per 100g
('mcdonalds_hamburger', 'McDonald''s Hamburger', 250.0, 12.0, 30.0, 9.0, 1.0, 5.0, 100, 100, 'mcdonalds.com', ARRAY['hamburger', 'plain hamburger'], '250 cal per sandwich (100g)'),

-- McChicken: 390 cal, 21g fat, 14g protein, 38g carbs, 1g fiber, 4g sugar per 143g
('mcdonalds_mcchicken', 'McDonald''s McChicken', 272.7, 9.8, 26.6, 14.7, 0.7, 2.8, 143, 143, 'mcdonalds.com', ARRAY['mcchicken', 'mc chicken'], '390 cal per sandwich (143g)'),

-- Filet-O-Fish: 380 cal, 19g fat, 16g protein, 38g carbs, 1g fiber, 4g sugar per 141g
('mcdonalds_filet_o_fish', 'McDonald''s Filet-O-Fish', 269.5, 11.3, 26.9, 13.5, 0.7, 2.8, 141, 141, 'mcdonalds.com', ARRAY['filet o fish', 'fish sandwich', 'filet-o-fish'], '380 cal per sandwich (141g)'),

-- McCrispy (Classic): 470 cal, 20g fat, 27g protein, 45g carbs, 1g fiber, 9g sugar per 200g
('mcdonalds_mccrispy', 'McDonald''s McCrispy', 235.0, 13.5, 22.5, 10.0, 0.5, 4.5, 200, 200, 'mcdonalds.com', ARRAY['mccrispy', 'crispy chicken sandwich', 'classic mccrispy'], '470 cal per sandwich (200g)'),

-- Egg McMuffin: 310 cal, 13g fat, 17g protein, 30g carbs, 2g fiber, 3g sugar per 137g
('mcdonalds_egg_mcmuffin', 'McDonald''s Egg McMuffin', 226.3, 12.4, 21.9, 9.5, 1.5, 2.2, 137, 137, 'mcdonalds.com', ARRAY['egg mcmuffin', 'egg mc muffin', 'mcmuffin'], '310 cal per sandwich (137g)'),

-- Sausage McMuffin: 400 cal, 25g fat, 14g protein, 29g carbs, 2g fiber, 2g sugar per 115g
('mcdonalds_sausage_mcmuffin', 'McDonald''s Sausage McMuffin', 347.8, 12.2, 25.2, 21.7, 1.7, 1.7, 115, 115, 'mcdonalds.com', ARRAY['sausage mcmuffin', 'sausage mc muffin'], '400 cal per sandwich (115g)'),

-- Sausage McMuffin with Egg: 480 cal, 30g fat, 21g protein, 30g carbs, 2g fiber, 2g sugar per 163g
('mcdonalds_sausage_mcmuffin_egg', 'McDonald''s Sausage McMuffin with Egg', 294.5, 12.9, 18.4, 18.4, 1.2, 1.2, 163, 163, 'mcdonalds.com', ARRAY['sausage egg mcmuffin', 'sausage mcmuffin with egg'], '480 cal per sandwich (163g)'),

-- Bacon Egg & Cheese Biscuit: 450 cal, 23g fat, 18g protein, 41g carbs, 2g fiber, 4g sugar per 163g
('mcdonalds_bacon_egg_cheese_biscuit', 'McDonald''s Bacon Egg & Cheese Biscuit', 276.1, 11.0, 25.2, 14.1, 1.2, 2.5, 163, 163, 'mcdonalds.com', ARRAY['bacon egg cheese biscuit', 'bec biscuit'], '450 cal per sandwich (163g)'),

-- Sausage Biscuit: 460 cal, 30g fat, 11g protein, 37g carbs, 2g fiber, 2g sugar per 120g
('mcdonalds_sausage_biscuit', 'McDonald''s Sausage Biscuit', 383.3, 9.2, 30.8, 25.0, 1.7, 1.7, 120, 120, 'mcdonalds.com', ARRAY['sausage biscuit'], '460 cal per biscuit (120g)'),

-- Hotcakes: 580 cal, 15g fat, 12g protein, 100g carbs, 2g fiber, 45g sugar per 260g
('mcdonalds_hotcakes', 'McDonald''s Hotcakes', 223.1, 4.6, 38.5, 5.8, 0.8, 17.3, 260, 260, 'mcdonalds.com', ARRAY['hotcakes', 'pancakes', 'hot cakes'], '580 cal per order with syrup (260g)'),

-- French Fries Small: 220 cal, 10g fat, 3g protein, 29g carbs, 3g fiber, 0g sugar per 75g
('mcdonalds_french_fries_small', 'McDonald''s French Fries (Small)', 293.3, 4.0, 38.7, 13.3, 4.0, 0.0, 75, 75, 'mcdonalds.com', ARRAY['small fries', 'small french fries'], '220 cal per small (75g)'),

-- French Fries Large: 480 cal, 23g fat, 7g protein, 64g carbs, 6g fiber, 0g sugar per 150g
('mcdonalds_french_fries_large', 'McDonald''s French Fries (Large)', 320.0, 4.7, 42.7, 15.3, 4.0, 0.0, 150, 150, 'mcdonalds.com', ARRAY['large fries', 'large french fries'], '480 cal per large (150g)'),

-- Apple Pie: 230 cal, 11g fat, 3g protein, 32g carbs, 1g fiber, 14g sugar per 77g
('mcdonalds_apple_pie', 'McDonald''s Baked Apple Pie', 298.7, 3.9, 41.6, 14.3, 1.3, 18.2, 77, 77, 'mcdonalds.com', ARRAY['apple pie', 'baked apple pie'], '230 cal per pie (77g)'),

-- McFlurry with OREO (Regular): 510 cal, 17g fat, 12g protein, 80g carbs, 1g fiber, 63g sugar per 285g
('mcdonalds_mcflurry_oreo', 'McDonald''s McFlurry with OREO Cookies', 178.9, 4.2, 28.1, 6.0, 0.4, 22.1, 285, 285, 'mcdonalds.com', ARRAY['mcflurry oreo', 'oreo mcflurry', 'mcflurry'], '510 cal per regular (285g)'),

-- McFlurry with M&M's (Regular): 630 cal, 23g fat, 14g protein, 96g carbs, 1g fiber, 83g sugar per 305g
('mcdonalds_mcflurry_mm', 'McDonald''s McFlurry with M&M''s', 206.6, 4.6, 31.5, 7.5, 0.3, 27.2, 305, 305, 'mcdonalds.com', ARRAY['mcflurry m&m', 'mm mcflurry', 'm&m mcflurry'], '630 cal per regular (305g)'),

-- Vanilla Cone: 200 cal, 5g fat, 5g protein, 33g carbs, 0g fiber, 24g sugar per 142g
('mcdonalds_vanilla_cone', 'McDonald''s Vanilla Cone', 140.8, 3.5, 23.2, 3.5, 0.0, 16.9, 142, 142, 'mcdonalds.com', ARRAY['vanilla cone', 'soft serve cone', 'ice cream cone'], '200 cal per cone (142g)'),

-- Chocolate Shake Medium: 630 cal, 16g fat, 14g protein, 109g carbs, 1g fiber, 90g sugar per 444g
('mcdonalds_chocolate_shake_medium', 'McDonald''s Chocolate Shake (Medium)', 141.9, 3.2, 24.5, 3.6, 0.2, 20.3, 444, 444, 'mcdonalds.com', ARRAY['chocolate shake', 'chocolate milkshake'], '630 cal per medium (444g)'),

-- Coca-Cola Medium: 210 cal, 0g fat, 0g protein, 58g carbs, 0g fiber, 58g sugar per 630ml
('mcdonalds_coca_cola_medium', 'McDonald''s Coca-Cola (Medium)', 33.3, 0.0, 9.2, 0.0, 0.0, 9.2, 630, 630, 'mcdonalds.com', ARRAY['medium coke', 'coca cola medium'], '210 cal per medium 21oz (630ml)'),

-- Sprite Medium: 200 cal, 0g fat, 0g protein, 54g carbs, 0g fiber, 54g sugar per 630ml
('mcdonalds_sprite_medium', 'McDonald''s Sprite (Medium)', 31.7, 0.0, 8.6, 0.0, 0.0, 8.6, 630, 630, 'mcdonalds.com', ARRAY['medium sprite', 'sprite medium'], '200 cal per medium 21oz (630ml)'),

-- ============================================================================
-- CHICK-FIL-A
-- ============================================================================

-- Chicken Sandwich: 420 cal, 18g fat, 29g protein, 41g carbs, 1g fiber, 6g sugar per 187g
('chickfila_chicken_sandwich', 'Chick-fil-A Chicken Sandwich', 224.6, 15.5, 21.9, 9.6, 0.5, 3.2, 187, 187, 'chick-fil-a.com', ARRAY['chick fil a sandwich', 'chickfila sandwich', 'chicken sandwich'], '420 cal per sandwich (187g)'),

-- Spicy Chicken Sandwich: 450 cal, 19g fat, 29g protein, 42g carbs, 2g fiber, 6g sugar per 187g
('chickfila_spicy_chicken_sandwich', 'Chick-fil-A Spicy Chicken Sandwich', 240.6, 15.5, 22.5, 10.2, 1.1, 3.2, 187, 187, 'chick-fil-a.com', ARRAY['spicy chicken sandwich', 'chickfila spicy'], '450 cal per sandwich (187g)'),

-- Deluxe Chicken Sandwich: 500 cal, 22g fat, 30g protein, 47g carbs, 2g fiber, 8g sugar per 223g
('chickfila_deluxe_sandwich', 'Chick-fil-A Deluxe Sandwich', 224.2, 13.5, 21.1, 9.9, 0.9, 3.6, 223, 223, 'chick-fil-a.com', ARRAY['deluxe sandwich', 'chickfila deluxe'], '500 cal per sandwich (223g)'),

-- Spicy Deluxe Sandwich: 540 cal, 24g fat, 31g protein, 48g carbs, 2g fiber, 8g sugar per 223g
('chickfila_spicy_deluxe_sandwich', 'Chick-fil-A Spicy Deluxe Sandwich', 242.2, 13.9, 21.5, 10.8, 0.9, 3.6, 223, 223, 'chick-fil-a.com', ARRAY['spicy deluxe', 'spicy deluxe sandwich'], '540 cal per sandwich (223g)'),

-- Grilled Chicken Sandwich: 390 cal, 12g fat, 28g protein, 44g carbs, 3g fiber, 11g sugar per 208g
('chickfila_grilled_chicken_sandwich', 'Chick-fil-A Grilled Chicken Sandwich', 187.5, 13.5, 21.2, 5.8, 1.4, 5.3, 208, 208, 'chick-fil-a.com', ARRAY['grilled chicken sandwich', 'grilled sandwich'], '390 cal per sandwich (208g)'),

-- Chicken Nuggets 8ct: 250 cal, 11g fat, 27g protein, 11g carbs, 0g fiber, 1g sugar per 113g
('chickfila_nuggets_8ct', 'Chick-fil-A Nuggets (8 ct)', 221.2, 23.9, 9.7, 9.7, 0.0, 0.9, 14, 113, 'chick-fil-a.com', ARRAY['8 count nuggets', '8ct nuggets', 'chick-fil-a nuggets'], '250 cal per 8 ct (113g)'),

-- Chicken Nuggets 12ct: 380 cal, 17g fat, 40g protein, 17g carbs, 0g fiber, 1g sugar per 170g
('chickfila_nuggets_12ct', 'Chick-fil-A Nuggets (12 ct)', 223.5, 23.5, 10.0, 10.0, 0.0, 0.6, 14, 170, 'chick-fil-a.com', ARRAY['12 count nuggets', '12ct nuggets'], '380 cal per 12 ct (170g)'),

-- Grilled Nuggets 8ct: 130 cal, 3g fat, 25g protein, 1g carbs, 0g fiber, 1g sugar per 113g
('chickfila_grilled_nuggets_8ct', 'Chick-fil-A Grilled Nuggets (8 ct)', 115.0, 22.1, 0.9, 2.7, 0.0, 0.9, 14, 113, 'chick-fil-a.com', ARRAY['grilled nuggets', '8ct grilled nuggets'], '130 cal per 8 ct (113g)'),

-- Chick-n-Strips 3ct: 310 cal, 15g fat, 29g protein, 16g carbs, 0g fiber, 2g sugar per 120g
('chickfila_chicken_strips_3ct', 'Chick-fil-A Chick-n-Strips (3 ct)', 258.3, 24.2, 13.3, 12.5, 0.0, 1.7, 40, 120, 'chick-fil-a.com', ARRAY['chick n strips', 'chicken strips', '3 count strips'], '310 cal per 3 ct (120g)'),

-- Waffle Fries Medium: 420 cal, 24g fat, 5g protein, 46g carbs, 5g fiber, 1g sugar per 125g
('chickfila_waffle_fries_medium', 'Chick-fil-A Waffle Potato Fries (Medium)', 336.0, 4.0, 36.8, 19.2, 4.0, 0.8, 125, 125, 'chick-fil-a.com', ARRAY['waffle fries', 'medium fries', 'waffle potato fries'], '420 cal per medium (125g)'),

-- Mac & Cheese Medium: 450 cal, 29g fat, 20g protein, 28g carbs, 3g fiber, 3g sugar per 227g
('chickfila_mac_and_cheese', 'Chick-fil-A Mac & Cheese (Medium)', 198.2, 8.8, 12.3, 12.8, 1.3, 1.3, 227, 227, 'chick-fil-a.com', ARRAY['mac and cheese', 'mac n cheese'], '450 cal per medium (227g)'),

-- Chicken Soup Medium: 340 cal, 10g fat, 24g protein, 36g carbs, 3g fiber, 2g sugar per 397g
('chickfila_chicken_soup', 'Chick-fil-A Chicken Tortilla Soup (Medium)', 85.6, 6.0, 9.1, 2.5, 0.8, 0.5, 397, 397, 'chick-fil-a.com', ARRAY['chicken tortilla soup', 'chicken soup', 'tortilla soup'], '340 cal per medium (397g)'),

-- Chick-fil-A Sauce: 140 cal, 13g fat, 0g protein, 7g carbs, 0g fiber, 6g sugar per 28g
('chickfila_sauce', 'Chick-fil-A Sauce', 500.0, 0.0, 25.0, 46.4, 0.0, 21.4, 28, 28, 'chick-fil-a.com', ARRAY['chick fil a sauce', 'cfa sauce', 'chickfila sauce'], '140 cal per packet (28g)'),

-- Polynesian Sauce: 110 cal, 6g fat, 0g protein, 13g carbs, 0g fiber, 12g sugar per 28g
('chickfila_polynesian_sauce', 'Chick-fil-A Polynesian Sauce', 392.9, 0.0, 46.4, 21.4, 0.0, 42.9, 28, 28, 'chick-fil-a.com', ARRAY['polynesian sauce', 'poly sauce'], '110 cal per packet (28g)'),

-- Icedream Cone: 170 cal, 4g fat, 5g protein, 31g carbs, 0g fiber, 24g sugar per 142g
('chickfila_icedream_cone', 'Chick-fil-A Icedream Cone', 119.7, 3.5, 21.8, 2.8, 0.0, 16.9, 142, 142, 'chick-fil-a.com', ARRAY['icedream', 'ice cream cone', 'ice dream'], '170 cal per cone (142g)'),

-- Chocolate Milkshake: 590 cal, 22g fat, 14g protein, 87g carbs, 1g fiber, 76g sugar per 482g
('chickfila_chocolate_milkshake', 'Chick-fil-A Chocolate Milkshake', 122.4, 2.9, 18.0, 4.6, 0.2, 15.8, 482, 482, 'chick-fil-a.com', ARRAY['chocolate milkshake', 'chocolate shake'], '590 cal per serving (482g)'),

-- Chicken Biscuit: 460 cal, 23g fat, 19g protein, 45g carbs, 2g fiber, 6g sugar per 163g
('chickfila_chicken_biscuit', 'Chick-fil-A Chicken Biscuit', 282.2, 11.7, 27.6, 14.1, 1.2, 3.7, 163, 163, 'chick-fil-a.com', ARRAY['chicken biscuit', 'breakfast chicken biscuit'], '460 cal per biscuit (163g)'),

-- 4ct Chick-n-Minis: 360 cal, 13g fat, 20g protein, 41g carbs, 2g fiber, 8g sugar per 132g
('chickfila_chick_n_minis', 'Chick-fil-A Chick-n-Minis (4 ct)', 272.7, 15.2, 31.1, 9.8, 1.5, 6.1, 33, 132, 'chick-fil-a.com', ARRAY['chick n minis', 'chicken minis', '4 count minis'], '360 cal per 4 ct (132g)'),

-- Egg White Grill: 300 cal, 8g fat, 27g protein, 29g carbs, 1g fiber, 2g sugar per 148g
('chickfila_egg_white_grill', 'Chick-fil-A Egg White Grill', 202.7, 18.2, 19.6, 5.4, 0.7, 1.4, 148, 148, 'chick-fil-a.com', ARRAY['egg white grill', 'grilled chicken egg white'], '300 cal per sandwich (148g)'),

-- Cobb Salad: 530 cal, 28g fat, 40g protein, 28g carbs, 5g fiber, 6g sugar per 430g
('chickfila_cobb_salad', 'Chick-fil-A Cobb Salad', 123.3, 9.3, 6.5, 6.5, 1.2, 1.4, 430, 430, 'chick-fil-a.com', ARRAY['cobb salad', 'chickfila cobb salad'], '530 cal with toppings (430g)'),

-- Frosted Lemonade: 370 cal, 6g fat, 6g protein, 75g carbs, 0g fiber, 71g sugar per 482g
('chickfila_frosted_lemonade', 'Chick-fil-A Frosted Lemonade', 76.8, 1.2, 15.6, 1.2, 0.0, 14.7, 482, 482, 'chick-fil-a.com', ARRAY['frosted lemonade', 'frozen lemonade'], '370 cal per serving (482g)'),

-- ============================================================================
-- STARBUCKS
-- ============================================================================

-- Caffe Latte Grande (2% milk): 190 cal, 7g fat, 13g protein, 19g carbs, 0g fiber, 17g sugar per 473ml
('starbucks_caffe_latte_grande', 'Starbucks Caffe Latte (Grande)', 40.2, 2.7, 4.0, 1.5, 0.0, 3.6, 473, 473, 'starbucks.com', ARRAY['latte', 'caffe latte', 'grande latte'], '190 cal per grande 16oz (473ml)'),

-- Caramel Macchiato Grande: 250 cal, 7g fat, 10g protein, 35g carbs, 0g fiber, 33g sugar per 473ml
('starbucks_caramel_macchiato_grande', 'Starbucks Caramel Macchiato (Grande)', 52.9, 2.1, 7.4, 1.5, 0.0, 7.0, 473, 473, 'starbucks.com', ARRAY['caramel macchiato', 'caramel macc'], '250 cal per grande 16oz (473ml)'),

-- Vanilla Sweet Cream Cold Brew Grande: 200 cal, 10g fat, 2g protein, 24g carbs, 0g fiber, 24g sugar per 473ml
('starbucks_vanilla_cold_brew_grande', 'Starbucks Vanilla Sweet Cream Cold Brew (Grande)', 42.3, 0.4, 5.1, 2.1, 0.0, 5.1, 473, 473, 'starbucks.com', ARRAY['vanilla cold brew', 'sweet cream cold brew', 'vanilla sweet cream cold brew'], '200 cal per grande 16oz (473ml)'),

-- Caramel Frappuccino Grande: 370 cal, 15g fat, 5g protein, 54g carbs, 0g fiber, 50g sugar per 473ml
('starbucks_caramel_frappuccino_grande', 'Starbucks Caramel Frappuccino (Grande)', 78.2, 1.1, 11.4, 3.2, 0.0, 10.6, 473, 473, 'starbucks.com', ARRAY['caramel frappuccino', 'caramel frap', 'caramel frapp'], '370 cal per grande 16oz (473ml)'),

-- Mocha Frappuccino Grande: 370 cal, 14g fat, 5g protein, 55g carbs, 1g fiber, 51g sugar per 473ml
('starbucks_mocha_frappuccino_grande', 'Starbucks Mocha Frappuccino (Grande)', 78.2, 1.1, 11.6, 3.0, 0.2, 10.8, 473, 473, 'starbucks.com', ARRAY['mocha frappuccino', 'mocha frap', 'mocha frapp'], '370 cal per grande 16oz (473ml)'),

-- Java Chip Frappuccino Grande: 440 cal, 18g fat, 6g protein, 63g carbs, 2g fiber, 55g sugar per 473ml
('starbucks_java_chip_frappuccino_grande', 'Starbucks Java Chip Frappuccino (Grande)', 93.0, 1.3, 13.3, 3.8, 0.4, 11.6, 473, 473, 'starbucks.com', ARRAY['java chip frappuccino', 'java chip frap'], '440 cal per grande 16oz (473ml)'),

-- White Chocolate Mocha Grande: 430 cal, 16g fat, 12g protein, 59g carbs, 0g fiber, 57g sugar per 473ml
('starbucks_white_chocolate_mocha_grande', 'Starbucks White Chocolate Mocha (Grande)', 90.9, 2.5, 12.5, 3.4, 0.0, 12.1, 473, 473, 'starbucks.com', ARRAY['white chocolate mocha', 'white mocha'], '430 cal per grande 16oz (473ml)'),

-- Chai Tea Latte Grande: 240 cal, 4.5g fat, 8g protein, 42g carbs, 0g fiber, 42g sugar per 473ml
('starbucks_chai_tea_latte_grande', 'Starbucks Chai Tea Latte (Grande)', 50.7, 1.7, 8.9, 1.0, 0.0, 8.9, 473, 473, 'starbucks.com', ARRAY['chai latte', 'chai tea latte'], '240 cal per grande 16oz (473ml)'),

-- Matcha Creme Frappuccino Grande: 420 cal, 16g fat, 6g protein, 63g carbs, 1g fiber, 61g sugar per 473ml
('starbucks_matcha_frappuccino_grande', 'Starbucks Matcha Creme Frappuccino (Grande)', 88.8, 1.3, 13.3, 3.4, 0.2, 12.9, 473, 473, 'starbucks.com', ARRAY['matcha frappuccino', 'matcha frap', 'green tea frappuccino'], '420 cal per grande 16oz (473ml)'),

-- Pumpkin Spice Latte Grande: 390 cal, 14g fat, 14g protein, 52g carbs, 0g fiber, 50g sugar per 473ml
('starbucks_pumpkin_spice_latte_grande', 'Starbucks Pumpkin Spice Latte (Grande)', 82.5, 3.0, 11.0, 3.0, 0.0, 10.6, 473, 473, 'starbucks.com', ARRAY['pumpkin spice latte', 'psl', 'pumpkin latte'], '390 cal per grande 16oz (473ml). Seasonal.'),

-- Iced White Chocolate Mocha Grande: 420 cal, 15g fat, 11g protein, 61g carbs, 0g fiber, 56g sugar per 473ml
('starbucks_iced_white_mocha_grande', 'Starbucks Iced White Chocolate Mocha (Grande)', 88.8, 2.3, 12.9, 3.2, 0.0, 11.8, 473, 473, 'starbucks.com', ARRAY['iced white mocha', 'iced white chocolate mocha'], '420 cal per grande 16oz (473ml)'),

-- Pink Drink Grande: 140 cal, 2.5g fat, 1g protein, 26g carbs, 1g fiber, 24g sugar per 473ml
('starbucks_pink_drink_grande', 'Starbucks Pink Drink (Grande)', 29.6, 0.2, 5.5, 0.5, 0.2, 5.1, 473, 473, 'starbucks.com', ARRAY['pink drink', 'strawberry acai lemonade'], '140 cal per grande 16oz (473ml)'),

-- Mango Dragonfruit Lemonade Refresher Grande: 140 cal, 0g fat, 1g protein, 34g carbs, 0g fiber, 30g sugar per 473ml
('starbucks_mango_dragonfruit_grande', 'Starbucks Mango Dragonfruit Lemonade (Grande)', 29.6, 0.2, 7.2, 0.0, 0.0, 6.3, 473, 473, 'starbucks.com', ARRAY['mango dragonfruit', 'dragon drink lemonade'], '140 cal per grande 16oz (473ml)'),

-- Bacon Gouda Breakfast Sandwich: 370 cal, 19g fat, 18g protein, 32g carbs, 1g fiber, 4g sugar per 138g
('starbucks_bacon_gouda_sandwich', 'Starbucks Bacon Gouda & Egg Sandwich', 268.1, 13.0, 23.2, 13.8, 0.7, 2.9, 138, 138, 'starbucks.com', ARRAY['bacon gouda', 'bacon gouda sandwich', 'bacon gouda egg sandwich'], '370 cal per sandwich (138g)'),

-- Tomato Mozzarella on Focaccia: 360 cal, 12g fat, 15g protein, 47g carbs, 2g fiber, 5g sugar per 155g
('starbucks_tomato_mozzarella_focaccia', 'Starbucks Tomato & Mozzarella on Focaccia', 232.3, 9.7, 30.3, 7.7, 1.3, 3.2, 155, 155, 'starbucks.com', ARRAY['tomato mozzarella', 'focaccia sandwich'], '360 cal per sandwich (155g)'),

-- Egg & Cheese Protein Box: 470 cal, 31g fat, 28g protein, 18g carbs, 4g fiber, 8g sugar per 213g
('starbucks_egg_cheese_protein_box', 'Starbucks Egg & Cheese Protein Box', 220.7, 13.1, 8.5, 14.6, 1.9, 3.8, 213, 213, 'starbucks.com', ARRAY['protein box', 'egg cheese protein box'], '470 cal per box (213g)'),

-- Chocolate Croissant: 340 cal, 17g fat, 6g protein, 39g carbs, 2g fiber, 15g sugar per 85g
('starbucks_chocolate_croissant', 'Starbucks Chocolate Croissant', 400.0, 7.1, 45.9, 20.0, 2.4, 17.6, 85, 85, 'starbucks.com', ARRAY['chocolate croissant', 'pain au chocolat'], '340 cal per pastry (85g)'),

-- Butter Croissant: 260 cal, 14g fat, 5g protein, 28g carbs, 1g fiber, 5g sugar per 68g
('starbucks_butter_croissant', 'Starbucks Butter Croissant', 382.4, 7.4, 41.2, 20.6, 1.5, 7.4, 68, 68, 'starbucks.com', ARRAY['butter croissant', 'plain croissant', 'croissant'], '260 cal per pastry (68g)'),

-- Old Fashioned Glazed Doughnut: 480 cal, 27g fat, 5g protein, 56g carbs, 1g fiber, 32g sugar per 113g
('starbucks_glazed_doughnut', 'Starbucks Old Fashioned Glazed Doughnut', 424.8, 4.4, 49.6, 23.9, 0.9, 28.3, 113, 113, 'starbucks.com', ARRAY['glazed donut', 'glazed doughnut', 'old fashioned donut'], '480 cal per donut (113g)'),

-- Vanilla Bean Scone: 480 cal, 18g fat, 7g protein, 71g carbs, 1g fiber, 37g sugar per 128g
('starbucks_vanilla_bean_scone', 'Starbucks Vanilla Bean Scone', 375.0, 5.5, 55.5, 14.1, 0.8, 28.9, 128, 128, 'starbucks.com', ARRAY['vanilla scone', 'vanilla bean scone'], '480 cal per scone (128g)'),

-- Blueberry Muffin: 390 cal, 16g fat, 5g protein, 57g carbs, 1g fiber, 31g sugar per 113g
('starbucks_blueberry_muffin', 'Starbucks Blueberry Muffin', 345.1, 4.4, 50.4, 14.2, 0.9, 27.4, 113, 113, 'starbucks.com', ARRAY['blueberry muffin'], '390 cal per muffin (113g)'),

-- Cake Pop (Birthday): 170 cal, 8g fat, 2g protein, 22g carbs, 0g fiber, 18g sugar per 42g
('starbucks_birthday_cake_pop', 'Starbucks Birthday Cake Pop', 404.8, 4.8, 52.4, 19.0, 0.0, 42.9, 42, 42, 'starbucks.com', ARRAY['cake pop', 'birthday cake pop'], '170 cal per pop (42g)'),

-- ============================================================================
-- TACO BELL (expanding beyond existing items)
-- ============================================================================

-- Chalupa Supreme (Beef): 400 cal, 24g fat, 13g protein, 31g carbs, 2g fiber, 3g sugar per 153g
('taco_bell_chalupa_supreme', 'Taco Bell Chalupa Supreme', 261.4, 8.5, 20.3, 15.7, 1.3, 2.0, 153, 153, 'tacobell.com', ARRAY['chalupa supreme', 'beef chalupa supreme', 'chalupa'], '400 cal per chalupa (153g)'),

-- Doritos Locos Tacos: 170 cal, 9g fat, 8g protein, 13g carbs, 3g fiber, 1g sugar per 78g
('taco_bell_doritos_locos_taco', 'Taco Bell Nacho Cheese Doritos Locos Tacos', 217.9, 10.3, 16.7, 11.5, 3.8, 1.3, 78, 78, 'tacobell.com', ARRAY['doritos locos taco', 'dlt', 'doritos taco', 'nacho cheese doritos locos taco'], '170 cal per taco (78g)'),

-- Doritos Locos Tacos Supreme: 190 cal, 11g fat, 8g protein, 14g carbs, 3g fiber, 1g sugar per 92g
('taco_bell_doritos_locos_taco_supreme', 'Taco Bell Doritos Locos Tacos Supreme', 206.5, 8.7, 15.2, 12.0, 3.3, 1.1, 92, 92, 'tacobell.com', ARRAY['doritos locos taco supreme', 'dlt supreme', 'doritos taco supreme'], '190 cal per taco (92g)'),

-- Soft Taco (Beef): 180 cal, 9g fat, 8g protein, 18g carbs, 3g fiber, 1g sugar per 99g
('taco_bell_soft_taco', 'Taco Bell Soft Taco', 181.8, 8.1, 18.2, 9.1, 3.0, 1.0, 99, 99, 'tacobell.com', ARRAY['soft taco', 'beef soft taco'], '180 cal per taco (99g)'),

-- Crunchy Taco: 170 cal, 10g fat, 8g protein, 13g carbs, 3g fiber, 1g sugar per 78g
('taco_bell_crunchy_taco', 'Taco Bell Crunchy Taco', 217.9, 10.3, 16.7, 12.8, 3.8, 1.3, 78, 78, 'tacobell.com', ARRAY['crunchy taco', 'hard taco', 'beef crunchy taco'], '170 cal per taco (78g)'),

-- Crunchy Taco Supreme: 190 cal, 11g fat, 8g protein, 14g carbs, 3g fiber, 2g sugar per 92g
('taco_bell_crunchy_taco_supreme', 'Taco Bell Crunchy Taco Supreme', 206.5, 8.7, 15.2, 12.0, 3.3, 2.2, 92, 92, 'tacobell.com', ARRAY['crunchy taco supreme', 'hard taco supreme'], '190 cal per taco (92g)'),

-- Soft Taco Supreme: 210 cal, 10g fat, 9g protein, 22g carbs, 3g fiber, 2g sugar per 113g
('taco_bell_soft_taco_supreme', 'Taco Bell Soft Taco Supreme', 185.8, 8.0, 19.5, 8.8, 2.7, 1.8, 113, 113, 'tacobell.com', ARRAY['soft taco supreme'], '210 cal per taco (113g)'),

-- Black Bean Chalupa Supreme: 330 cal, 18g fat, 10g protein, 34g carbs, 5g fiber, 4g sugar per 153g
('taco_bell_black_bean_chalupa_supreme', 'Taco Bell Black Bean Chalupa Supreme', 215.7, 6.5, 22.2, 11.8, 3.3, 2.6, 153, 153, 'tacobell.com', ARRAY['black bean chalupa', 'black bean chalupa supreme', 'veggie chalupa'], '330 cal per chalupa (153g)'),

-- Spicy Potato Soft Taco: 220 cal, 10g fat, 4g protein, 27g carbs, 3g fiber, 2g sugar per 99g
('taco_bell_spicy_potato_soft_taco', 'Taco Bell Spicy Potato Soft Taco', 222.2, 4.0, 27.3, 10.1, 3.0, 2.0, 99, 99, 'tacobell.com', ARRAY['spicy potato taco', 'potato soft taco'], '220 cal per taco (99g)'),

-- Doritos Cheesy Gordita Crunch: 500 cal, 29g fat, 15g protein, 41g carbs, 4g fiber, 4g sugar per 163g
('taco_bell_doritos_cheesy_gordita_crunch', 'Taco Bell Doritos Cheesy Gordita Crunch', 306.7, 9.2, 25.2, 17.8, 2.5, 2.5, 163, 163, 'tacobell.com', ARRAY['doritos cheesy gordita crunch', 'dcgc'], '500 cal (163g)'),

-- Cheesy Gordita Crunch: 500 cal, 29g fat, 15g protein, 41g carbs, 4g fiber, 4g sugar per 163g
('taco_bell_cheesy_gordita_crunch', 'Taco Bell Cheesy Gordita Crunch', 306.7, 9.2, 25.2, 17.8, 2.5, 2.5, 163, 163, 'tacobell.com', ARRAY['cheesy gordita crunch', 'gordita crunch'], '500 cal (163g)'),

-- Grilled Cheese Burrito: 720 cal, 34g fat, 27g protein, 76g carbs, 5g fiber, 4g sugar per 312g
('taco_bell_grilled_cheese_burrito', 'Taco Bell Grilled Cheese Burrito', 230.8, 8.7, 24.4, 10.9, 1.6, 1.3, 312, 312, 'tacobell.com', ARRAY['grilled cheese burrito', 'gcb'], '720 cal per burrito (312g)'),

-- Beefy 5-Layer Burrito: 490 cal, 18g fat, 18g protein, 63g carbs, 6g fiber, 3g sugar per 241g
('taco_bell_beefy_5_layer_burrito', 'Taco Bell Beefy 5-Layer Burrito', 203.3, 7.5, 26.1, 7.5, 2.5, 1.2, 241, 241, 'tacobell.com', ARRAY['beefy 5 layer', 'beefy five layer burrito', '5 layer burrito'], '490 cal per burrito (241g)'),

-- Burrito Supreme: 380 cal, 14g fat, 15g protein, 50g carbs, 7g fiber, 4g sugar per 248g
('taco_bell_burrito_supreme', 'Taco Bell Burrito Supreme', 153.2, 6.0, 20.2, 5.6, 2.8, 1.6, 248, 248, 'tacobell.com', ARRAY['burrito supreme'], '380 cal per burrito (248g)'),

-- Bean Burrito: 370 cal, 10g fat, 14g protein, 55g carbs, 8g fiber, 3g sugar per 198g
('taco_bell_bean_burrito', 'Taco Bell Bean Burrito', 186.9, 7.1, 27.8, 5.1, 4.0, 1.5, 198, 198, 'tacobell.com', ARRAY['bean burrito'], '370 cal per burrito (198g)'),

-- Cheesy Bean and Rice Burrito: 420 cal, 16g fat, 12g protein, 57g carbs, 5g fiber, 3g sugar per 227g
('taco_bell_cheesy_bean_rice_burrito', 'Taco Bell Cheesy Bean and Rice Burrito', 185.0, 5.3, 25.1, 7.0, 2.2, 1.3, 227, 227, 'tacobell.com', ARRAY['cheesy bean and rice', 'cheesy bean rice burrito'], '420 cal per burrito (227g)'),

-- Black Bean Grilled Cheese Burrito: 650 cal, 28g fat, 22g protein, 77g carbs, 8g fiber, 5g sugar per 312g
('taco_bell_black_bean_grilled_cheese_burrito', 'Taco Bell Black Bean Grilled Cheese Burrito', 208.3, 7.1, 24.7, 9.0, 2.6, 1.6, 312, 312, 'tacobell.com', ARRAY['black bean grilled cheese burrito', 'veggie grilled cheese burrito'], '650 cal per burrito (312g)'),

-- Cheesy Double Beef Burrito: 450 cal, 19g fat, 18g protein, 51g carbs, 4g fiber, 3g sugar per 227g
('taco_bell_cheesy_double_beef_burrito', 'Taco Bell Cheesy Double Beef Burrito', 198.2, 7.9, 22.5, 8.4, 1.8, 1.3, 227, 227, 'tacobell.com', ARRAY['cheesy double beef', 'cheesy double beef burrito'], '450 cal per burrito (227g)'),

-- Crunchwrap Supreme: 530 cal, 20g fat, 15g protein, 73g carbs, 6g fiber, 6g sugar per 254g
('taco_bell_crunchwrap_supreme', 'Taco Bell Crunchwrap Supreme', 208.7, 5.9, 28.7, 7.9, 2.4, 2.4, 254, 254, 'tacobell.com', ARRAY['crunchwrap supreme', 'crunchwrap'], '530 cal per crunchwrap (254g)'),

-- Mexican Pizza: 540 cal, 30g fat, 19g protein, 48g carbs, 7g fiber, 3g sugar per 213g
('taco_bell_mexican_pizza', 'Taco Bell Mexican Pizza', 253.5, 8.9, 22.5, 14.1, 3.3, 1.4, 213, 213, 'tacobell.com', ARRAY['mexican pizza'], '540 cal per pizza (213g)'),

-- Nacho Fries: 320 cal, 16g fat, 4g protein, 41g carbs, 4g fiber, 0g sugar per 128g
('taco_bell_nacho_fries', 'Taco Bell Nacho Fries', 250.0, 3.1, 32.0, 12.5, 3.1, 0.0, 128, 128, 'tacobell.com', ARRAY['nacho fries'], '320 cal per order (128g)'),

-- Cheesy Roll Up: 180 cal, 10g fat, 7g protein, 15g carbs, 0g fiber, 1g sugar per 57g
('taco_bell_cheesy_roll_up', 'Taco Bell Cheesy Roll Up', 315.8, 12.3, 26.3, 17.5, 0.0, 1.8, 57, 57, 'tacobell.com', ARRAY['cheesy roll up', 'cheese roll up'], '180 cal per roll up (57g)'),

-- Nacho Fries Large: 440 cal, 22g fat, 5g protein, 56g carbs, 5g fiber, 0g sugar per 170g
('taco_bell_nacho_fries_large', 'Taco Bell Nacho Fries (Large)', 258.8, 2.9, 32.9, 12.9, 2.9, 0.0, 170, 170, 'tacobell.com', ARRAY['large nacho fries'], '440 cal per large (170g)'),

-- 3 Cheese Chicken Flatbread Melt: 310 cal, 14g fat, 16g protein, 30g carbs, 1g fiber, 2g sugar per 128g
('taco_bell_3_cheese_chicken_flatbread', 'Taco Bell 3 Cheese Chicken Flatbread Melt', 242.2, 12.5, 23.4, 10.9, 0.8, 1.6, 128, 128, 'tacobell.com', ARRAY['3 cheese chicken flatbread', 'cheese chicken flatbread melt', 'flatbread melt'], '310 cal (128g)'),

-- Nachos BellGrande: 740 cal, 39g fat, 16g protein, 80g carbs, 9g fiber, 5g sugar per 305g
('taco_bell_nachos_bellgrande', 'Taco Bell Nachos BellGrande', 242.6, 5.2, 26.2, 12.8, 3.0, 1.6, 305, 305, 'tacobell.com', ARRAY['nachos bellgrande', 'nachos bell grande'], '740 cal per order (305g)'),

-- Chips and Nacho Cheese Sauce: 220 cal, 12g fat, 3g protein, 25g carbs, 1g fiber, 1g sugar per 57g
('taco_bell_chips_nacho_cheese', 'Taco Bell Chips and Nacho Cheese Sauce', 386.0, 5.3, 43.9, 21.1, 1.8, 1.8, 57, 57, 'tacobell.com', ARRAY['chips and nacho cheese', 'chips and cheese'], '220 cal per order (57g)'),

-- Chips and Guacamole: 230 cal, 14g fat, 3g protein, 23g carbs, 4g fiber, 1g sugar per 78g
('taco_bell_chips_guacamole', 'Taco Bell Chips and Guacamole', 294.9, 3.8, 29.5, 17.9, 5.1, 1.3, 78, 78, 'tacobell.com', ARRAY['chips and guac', 'chips and guacamole'], '230 cal per order (78g)'),

-- Cantina Chicken Bowl: 570 cal, 24g fat, 30g protein, 58g carbs, 7g fiber, 4g sugar per 397g
('taco_bell_cantina_chicken_bowl', 'Taco Bell Cantina Chicken Bowl', 143.6, 7.6, 14.6, 6.0, 1.8, 1.0, 397, 397, 'tacobell.com', ARRAY['cantina chicken bowl', 'chicken bowl'], '570 cal per bowl (397g)'),

-- Veggie Bowl: 530 cal, 21g fat, 15g protein, 71g carbs, 10g fiber, 4g sugar per 397g
('taco_bell_veggie_bowl', 'Taco Bell Veggie Bowl', 133.5, 3.8, 17.9, 5.3, 2.5, 1.0, 397, 397, 'tacobell.com', ARRAY['veggie bowl', 'vegetarian bowl'], '530 cal per bowl (397g)'),

-- Cheesy Fiesta Potatoes: 230 cal, 14g fat, 3g protein, 24g carbs, 2g fiber, 1g sugar per 113g
('taco_bell_cheesy_fiesta_potatoes', 'Taco Bell Cheesy Fiesta Potatoes', 203.5, 2.7, 21.2, 12.4, 1.8, 0.9, 113, 113, 'tacobell.com', ARRAY['cheesy fiesta potatoes', 'fiesta potatoes'], '230 cal per order (113g)'),

-- Pintos N Cheese: 160 cal, 5g fat, 8g protein, 20g carbs, 5g fiber, 1g sugar per 128g
('taco_bell_pintos_n_cheese', 'Taco Bell Pintos N Cheese', 125.0, 6.3, 15.6, 3.9, 3.9, 0.8, 128, 128, 'tacobell.com', ARRAY['pintos n cheese', 'pintos and cheese'], '160 cal per order (128g)'),

-- Black Beans and Rice: 180 cal, 3g fat, 6g protein, 32g carbs, 4g fiber, 1g sugar per 170g
('taco_bell_black_beans_and_rice', 'Taco Bell Black Beans and Rice', 105.9, 3.5, 18.8, 1.8, 2.4, 0.6, 170, 170, 'tacobell.com', ARRAY['black beans and rice', 'beans and rice'], '180 cal per order (170g)'),

-- Black Beans: 50 cal, 0g fat, 3g protein, 8g carbs, 3g fiber, 0g sugar per 57g
('taco_bell_black_beans', 'Taco Bell Black Beans', 87.7, 5.3, 14.0, 0.0, 5.3, 0.0, 57, 57, 'tacobell.com', ARRAY['black beans', 'side of black beans'], '50 cal per side (57g)'),

-- Crispy Chicken Nuggets 10pc: 460 cal, 26g fat, 20g protein, 35g carbs, 2g fiber, 1g sugar per 165g
('taco_bell_crispy_chicken_nuggets_10pc', 'Taco Bell Crispy Chicken Nuggets (10 pc)', 278.8, 12.1, 21.2, 15.8, 1.2, 0.6, 16.5, 165, 'tacobell.com', ARRAY['chicken nuggets 10pc', 'crispy chicken nuggets', '10 piece nuggets'], '460 cal per 10 pc (165g)'),

-- Avocado Ranch Chicken Stacker: 310 cal, 16g fat, 12g protein, 29g carbs, 2g fiber, 2g sugar per 142g
('taco_bell_avocado_ranch_chicken_stacker', 'Taco Bell Avocado Ranch Chicken Stacker', 218.3, 8.5, 20.4, 11.3, 1.4, 1.4, 142, 142, 'tacobell.com', ARRAY['avocado ranch chicken stacker', 'chicken stacker'], '310 cal (142g)'),

-- Mini Taco Salad: 510 cal, 26g fat, 16g protein, 52g carbs, 6g fiber, 4g sugar per 284g
('taco_bell_mini_taco_salad', 'Taco Bell Mini Taco Salad', 179.6, 5.6, 18.3, 9.2, 2.1, 1.4, 284, 284, 'tacobell.com', ARRAY['mini taco salad', 'taco salad'], '510 cal per salad (284g)'),

-- ============================================================================
-- WENDY'S
-- ============================================================================

-- Dave's Single: 570 cal, 34g fat, 30g protein, 40g carbs, 3g fiber, 9g sugar per 244g
('wendys_daves_single', 'Wendy''s Dave''s Single', 233.6, 12.3, 16.4, 13.9, 1.2, 3.7, 244, 244, 'wendys.com', ARRAY['daves single', 'dave''s single', 'single burger'], '570 cal per sandwich (244g)'),

-- Dave's Double: 850 cal, 54g fat, 48g protein, 40g carbs, 3g fiber, 9g sugar per 340g
('wendys_daves_double', 'Wendy''s Dave''s Double', 250.0, 14.1, 11.8, 15.9, 0.9, 2.6, 340, 340, 'wendys.com', ARRAY['daves double', 'dave''s double', 'double burger'], '850 cal per sandwich (340g)'),

-- Dave's Triple: 1100 cal, 72g fat, 69g protein, 40g carbs, 3g fiber, 9g sugar per 430g
('wendys_daves_triple', 'Wendy''s Dave''s Triple', 255.8, 16.0, 9.3, 16.7, 0.7, 2.1, 430, 430, 'wendys.com', ARRAY['daves triple', 'dave''s triple', 'triple burger'], '1100 cal per sandwich (430g)'),

-- Baconator: 950 cal, 62g fat, 59g protein, 40g carbs, 2g fiber, 8g sugar per 344g
('wendys_baconator', 'Wendy''s Baconator', 276.2, 17.2, 11.6, 18.0, 0.6, 2.3, 344, 344, 'wendys.com', ARRAY['baconator'], '950 cal per sandwich (344g)'),

-- Jr. Bacon Cheeseburger: 370 cal, 21g fat, 19g protein, 27g carbs, 1g fiber, 6g sugar per 151g
('wendys_jr_bacon_cheeseburger', 'Wendy''s Jr. Bacon Cheeseburger', 245.0, 12.6, 17.9, 13.9, 0.7, 4.0, 151, 151, 'wendys.com', ARRAY['jr bacon cheeseburger', 'junior bacon cheeseburger'], '370 cal per sandwich (151g)'),

-- Spicy Chicken Sandwich: 500 cal, 19g fat, 28g protein, 53g carbs, 2g fiber, 6g sugar per 213g
('wendys_spicy_chicken_sandwich', 'Wendy''s Spicy Chicken Sandwich', 234.7, 13.1, 24.9, 8.9, 0.9, 2.8, 213, 213, 'wendys.com', ARRAY['spicy chicken sandwich', 'spicy chicken'], '500 cal per sandwich (213g)'),

-- Classic Chicken Sandwich: 490 cal, 20g fat, 28g protein, 50g carbs, 2g fiber, 5g sugar per 213g
('wendys_classic_chicken_sandwich', 'Wendy''s Classic Chicken Sandwich', 230.0, 13.1, 23.5, 9.4, 0.9, 2.3, 213, 213, 'wendys.com', ARRAY['classic chicken sandwich'], '490 cal per sandwich (213g)'),

-- Crispy Chicken Sandwich: 330 cal, 16g fat, 14g protein, 33g carbs, 2g fiber, 4g sugar per 143g
('wendys_crispy_chicken_sandwich', 'Wendy''s Crispy Chicken Sandwich', 230.8, 9.8, 23.1, 11.2, 1.4, 2.8, 143, 143, 'wendys.com', ARRAY['crispy chicken sandwich', 'crispy chicken'], '330 cal per sandwich (143g)'),

-- 10pc Nuggets: 420 cal, 27g fat, 22g protein, 24g carbs, 1g fiber, 0g sugar per 147g
('wendys_nuggets_10pc', 'Wendy''s Chicken Nuggets (10 pc)', 285.7, 15.0, 16.3, 18.4, 0.7, 0.0, 15, 147, 'wendys.com', ARRAY['10 piece nuggets', '10pc nuggets', 'chicken nuggets'], '420 cal per 10 pc (147g)'),

-- Spicy Nuggets 10pc: 430 cal, 27g fat, 22g protein, 26g carbs, 2g fiber, 0g sugar per 147g
('wendys_spicy_nuggets_10pc', 'Wendy''s Spicy Chicken Nuggets (10 pc)', 292.5, 15.0, 17.7, 18.4, 1.4, 0.0, 15, 147, 'wendys.com', ARRAY['spicy nuggets 10pc', '10 piece spicy nuggets'], '430 cal per 10 pc (147g)'),

-- Natural Cut Fries Medium: 350 cal, 16g fat, 5g protein, 47g carbs, 4g fiber, 0g sugar per 142g
('wendys_fries_medium', 'Wendy''s Natural-Cut Fries (Medium)', 246.5, 3.5, 33.1, 11.3, 2.8, 0.0, 142, 142, 'wendys.com', ARRAY['medium fries', 'natural cut fries medium'], '350 cal per medium (142g)'),

-- Chili Medium: 250 cal, 8g fat, 19g protein, 25g carbs, 5g fiber, 6g sugar per 284g
('wendys_chili_medium', 'Wendy''s Chili (Medium)', 88.0, 6.7, 8.8, 2.8, 1.8, 2.1, 284, 284, 'wendys.com', ARRAY['chili medium', 'wendys chili'], '250 cal per medium (284g)'),

-- Baked Potato Plain: 270 cal, 0g fat, 7g protein, 63g carbs, 7g fiber, 3g sugar per 284g
('wendys_baked_potato', 'Wendy''s Baked Potato', 95.1, 2.5, 22.2, 0.0, 2.5, 1.1, 284, 284, 'wendys.com', ARRAY['baked potato', 'plain baked potato'], '270 cal per potato (284g)'),

-- Baked Potato Sour Cream & Chive: 310 cal, 4g fat, 8g protein, 63g carbs, 7g fiber, 4g sugar per 311g
('wendys_baked_potato_sour_cream', 'Wendy''s Baked Potato (Sour Cream & Chive)', 99.7, 2.6, 20.3, 1.3, 2.3, 1.3, 311, 311, 'wendys.com', ARRAY['sour cream chive potato', 'loaded baked potato'], '310 cal per potato (311g)'),

-- Chocolate Frosty Small: 350 cal, 9g fat, 10g protein, 58g carbs, 0g fiber, 47g sugar per 255g
('wendys_chocolate_frosty_small', 'Wendy''s Chocolate Frosty (Small)', 137.3, 3.9, 22.7, 3.5, 0.0, 18.4, 255, 255, 'wendys.com', ARRAY['chocolate frosty', 'frosty small', 'small frosty'], '350 cal per small (255g)'),

-- Vanilla Frosty Small: 340 cal, 9g fat, 10g protein, 56g carbs, 0g fiber, 45g sugar per 255g
('wendys_vanilla_frosty_small', 'Wendy''s Vanilla Frosty (Small)', 133.3, 3.9, 22.0, 3.5, 0.0, 17.6, 255, 255, 'wendys.com', ARRAY['vanilla frosty', 'vanilla frosty small'], '340 cal per small (255g)'),

-- Apple Pecan Salad Full: 560 cal, 24g fat, 38g protein, 52g carbs, 7g fiber, 40g sugar per 397g
('wendys_apple_pecan_salad', 'Wendy''s Apple Pecan Chicken Salad (Full)', 141.1, 9.6, 13.1, 6.0, 1.8, 10.1, 397, 397, 'wendys.com', ARRAY['apple pecan salad', 'apple pecan chicken salad'], '560 cal per full salad (397g)'),

-- ============================================================================
-- BURGER KING
-- ============================================================================

-- Whopper: 610 cal, 33g fat, 31g protein, 47g carbs, 4g fiber, 11g sugar per 270g
('bk_whopper', 'Burger King Whopper', 225.9, 11.5, 17.4, 12.2, 1.5, 4.1, 270, 270, 'bk.com', ARRAY['whopper', 'burger king whopper'], '610 cal per sandwich (270g)'),

-- Whopper with Cheese: 700 cal, 40g fat, 35g protein, 48g carbs, 4g fiber, 11g sugar per 290g
('bk_whopper_cheese', 'Burger King Whopper with Cheese', 241.4, 12.1, 16.6, 13.8, 1.4, 3.8, 290, 290, 'bk.com', ARRAY['whopper with cheese', 'cheese whopper'], '700 cal per sandwich (290g)'),

-- Double Whopper: 850 cal, 52g fat, 48g protein, 47g carbs, 4g fiber, 11g sugar per 373g
('bk_double_whopper', 'Burger King Double Whopper', 227.9, 12.9, 12.6, 13.9, 1.1, 2.9, 373, 373, 'bk.com', ARRAY['double whopper'], '850 cal per sandwich (373g)'),

-- Whopper Jr.: 310 cal, 15g fat, 14g protein, 29g carbs, 2g fiber, 7g sugar per 143g
('bk_whopper_jr', 'Burger King Whopper Jr.', 216.8, 9.8, 20.3, 10.5, 1.4, 4.9, 143, 143, 'bk.com', ARRAY['whopper jr', 'whopper junior'], '310 cal per sandwich (143g)'),

-- Impossible Whopper: 630 cal, 34g fat, 25g protein, 58g carbs, 7g fiber, 12g sugar per 270g
('bk_impossible_whopper', 'Burger King Impossible Whopper', 233.3, 9.3, 21.5, 12.6, 2.6, 4.4, 270, 270, 'bk.com', ARRAY['impossible whopper', 'plant based whopper'], '630 cal per sandwich (270g)'),

-- Bacon Cheeseburger: 330 cal, 16g fat, 18g protein, 27g carbs, 1g fiber, 6g sugar per 130g
('bk_bacon_cheeseburger', 'Burger King Bacon Cheeseburger', 253.8, 13.8, 20.8, 12.3, 0.8, 4.6, 130, 130, 'bk.com', ARRAY['bacon cheeseburger', 'bk bacon cheeseburger'], '330 cal per sandwich (130g)'),

-- Cheeseburger: 280 cal, 13g fat, 14g protein, 27g carbs, 1g fiber, 6g sugar per 113g
('bk_cheeseburger', 'Burger King Cheeseburger', 247.8, 12.4, 23.9, 11.5, 0.9, 5.3, 113, 113, 'bk.com', ARRAY['bk cheeseburger', 'burger king cheeseburger'], '280 cal per sandwich (113g)'),

-- Original Chicken Sandwich: 660 cal, 40g fat, 22g protein, 54g carbs, 3g fiber, 5g sugar per 209g
('bk_original_chicken_sandwich', 'Burger King Original Chicken Sandwich', 315.8, 10.5, 25.8, 19.1, 1.4, 2.4, 209, 209, 'bk.com', ARRAY['original chicken sandwich', 'bk chicken sandwich'], '660 cal per sandwich (209g)'),

-- Spicy Ch'King: 700 cal, 32g fat, 28g protein, 74g carbs, 3g fiber, 10g sugar per 246g
('bk_spicy_chking', 'Burger King Spicy Ch''King', 284.6, 11.4, 30.1, 13.0, 1.2, 4.1, 246, 246, 'bk.com', ARRAY['spicy chking', 'spicy chicken king', 'ch king spicy'], '700 cal per sandwich (246g)'),

-- Chicken Nuggets 8pc: 340 cal, 21g fat, 16g protein, 20g carbs, 1g fiber, 0g sugar per 120g
('bk_chicken_nuggets_8pc', 'Burger King Chicken Nuggets (8 pc)', 283.3, 13.3, 16.7, 17.5, 0.8, 0.0, 15, 120, 'bk.com', ARRAY['8pc chicken nuggets', 'bk nuggets'], '340 cal per 8 pc (120g)'),

-- French Fries Medium: 380 cal, 17g fat, 5g protein, 53g carbs, 4g fiber, 0g sugar per 128g
('bk_french_fries_medium', 'Burger King French Fries (Medium)', 296.9, 3.9, 41.4, 13.3, 3.1, 0.0, 128, 128, 'bk.com', ARRAY['medium fries', 'bk fries medium'], '380 cal per medium (128g)'),

-- Onion Rings Medium: 370 cal, 18g fat, 5g protein, 48g carbs, 3g fiber, 4g sugar per 113g
('bk_onion_rings_medium', 'Burger King Onion Rings (Medium)', 327.4, 4.4, 42.5, 15.9, 2.7, 3.5, 113, 113, 'bk.com', ARRAY['onion rings', 'bk onion rings', 'medium onion rings'], '370 cal per medium (113g)'),

-- Mozzarella Sticks 4pc: 300 cal, 16g fat, 12g protein, 28g carbs, 2g fiber, 2g sugar per 85g
('bk_mozzarella_sticks', 'Burger King Mozzarella Sticks (4 pc)', 352.9, 14.1, 32.9, 18.8, 2.4, 2.4, 21, 85, 'bk.com', ARRAY['mozzarella sticks', 'mozz sticks'], '300 cal per 4 pc (85g)'),

-- HERSHEY'S Sundae Pie: 310 cal, 18g fat, 3g protein, 32g carbs, 1g fiber, 19g sugar per 79g
('bk_hersheys_sundae_pie', 'Burger King HERSHEY''S Sundae Pie', 392.4, 3.8, 40.5, 22.8, 1.3, 24.1, 79, 79, 'bk.com', ARRAY['hersheys pie', 'sundae pie', 'chocolate pie'], '310 cal per slice (79g)'),

-- Vanilla Shake Medium: 570 cal, 17g fat, 12g protein, 91g carbs, 0g fiber, 79g sugar per 397g
('bk_vanilla_shake_medium', 'Burger King Vanilla Shake (Medium)', 143.6, 3.0, 22.9, 4.3, 0.0, 19.9, 397, 397, 'bk.com', ARRAY['vanilla shake', 'vanilla milkshake medium'], '570 cal per medium (397g)'),

-- ============================================================================
-- SUBWAY
-- ============================================================================

-- 6" Italian B.M.T.: 410 cal, 16g fat, 20g protein, 46g carbs, 3g fiber, 7g sugar per 234g
('subway_6_italian_bmt', 'Subway 6" Italian B.M.T.', 175.2, 8.5, 19.7, 6.8, 1.3, 3.0, 234, 234, 'subway.com', ARRAY['italian bmt 6 inch', '6 inch italian bmt', 'italian bmt'], '410 cal per 6" sub (234g)'),

-- 6" Turkey Breast: 270 cal, 3.5g fat, 18g protein, 43g carbs, 3g fiber, 6g sugar per 220g
('subway_6_turkey_breast', 'Subway 6" Turkey Breast', 122.7, 8.2, 19.5, 1.6, 1.4, 2.7, 220, 220, 'subway.com', ARRAY['turkey breast 6 inch', '6 inch turkey', 'turkey sub'], '270 cal per 6" sub (220g)'),

-- 6" Subway Club: 310 cal, 5g fat, 24g protein, 43g carbs, 3g fiber, 6g sugar per 241g
('subway_6_subway_club', 'Subway 6" Subway Club', 128.6, 10.0, 17.8, 2.1, 1.2, 2.5, 241, 241, 'subway.com', ARRAY['subway club 6 inch', '6 inch club'], '310 cal per 6" sub (241g)'),

-- 6" Steak & Cheese: 380 cal, 11g fat, 25g protein, 44g carbs, 3g fiber, 7g sugar per 258g
('subway_6_steak_cheese', 'Subway 6" Steak & Cheese', 147.3, 9.7, 17.1, 4.3, 1.2, 2.7, 258, 258, 'subway.com', ARRAY['steak and cheese 6 inch', '6 inch steak cheese', 'philly steak'], '380 cal per 6" sub (258g)'),

-- 6" Chicken Teriyaki: 330 cal, 4.5g fat, 26g protein, 46g carbs, 3g fiber, 12g sugar per 258g
('subway_6_chicken_teriyaki', 'Subway 6" Sweet Onion Chicken Teriyaki', 127.9, 10.1, 17.8, 1.7, 1.2, 4.7, 258, 258, 'subway.com', ARRAY['chicken teriyaki 6 inch', 'sweet onion teriyaki', 'teriyaki sub'], '330 cal per 6" sub (258g)'),

-- 6" Meatball Marinara: 480 cal, 18g fat, 22g protein, 56g carbs, 5g fiber, 12g sugar per 284g
('subway_6_meatball_marinara', 'Subway 6" Meatball Marinara', 169.0, 7.7, 19.7, 6.3, 1.8, 4.2, 284, 284, 'subway.com', ARRAY['meatball marinara 6 inch', '6 inch meatball', 'meatball sub'], '480 cal per 6" sub (284g)'),

-- 6" Tuna: 450 cal, 22g fat, 19g protein, 44g carbs, 3g fiber, 6g sugar per 234g
('subway_6_tuna', 'Subway 6" Tuna', 192.3, 8.1, 18.8, 9.4, 1.3, 2.6, 234, 234, 'subway.com', ARRAY['tuna 6 inch', '6 inch tuna', 'tuna sub'], '450 cal per 6" sub (234g)'),

-- 6" Cold Cut Combo: 310 cal, 10g fat, 16g protein, 43g carbs, 3g fiber, 6g sugar per 234g
('subway_6_cold_cut_combo', 'Subway 6" Cold Cut Combo', 132.5, 6.8, 18.4, 4.3, 1.3, 2.6, 234, 234, 'subway.com', ARRAY['cold cut combo 6 inch', '6 inch cold cut', 'cold cut'], '310 cal per 6" sub (234g)'),

-- 6" Spicy Italian: 470 cal, 23g fat, 20g protein, 46g carbs, 3g fiber, 7g sugar per 234g
('subway_6_spicy_italian', 'Subway 6" Spicy Italian', 200.9, 8.5, 19.7, 9.8, 1.3, 3.0, 234, 234, 'subway.com', ARRAY['spicy italian 6 inch', '6 inch spicy italian'], '470 cal per 6" sub (234g)'),

-- 6" Veggie Delite: 200 cal, 2g fat, 7g protein, 39g carbs, 3g fiber, 5g sugar per 157g
('subway_6_veggie_delite', 'Subway 6" Veggie Delite', 127.4, 4.5, 24.8, 1.3, 1.9, 3.2, 157, 157, 'subway.com', ARRAY['veggie delite 6 inch', '6 inch veggie', 'veggie sub'], '200 cal per 6" sub (157g)'),

-- Footlong Italian B.M.T.: 820 cal, 32g fat, 40g protein, 92g carbs, 6g fiber, 14g sugar per 468g
('subway_footlong_italian_bmt', 'Subway Footlong Italian B.M.T.', 175.2, 8.5, 19.7, 6.8, 1.3, 3.0, 468, 468, 'subway.com', ARRAY['footlong italian bmt', 'footlong bmt', '12 inch italian bmt'], '820 cal per footlong (468g)'),

-- Footlong Meatball Marinara: 960 cal, 36g fat, 44g protein, 112g carbs, 10g fiber, 24g sugar per 568g
('subway_footlong_meatball_marinara', 'Subway Footlong Meatball Marinara', 169.0, 7.7, 19.7, 6.3, 1.8, 4.2, 568, 568, 'subway.com', ARRAY['footlong meatball marinara', 'footlong meatball', '12 inch meatball'], '960 cal per footlong (568g)'),

-- Chocolate Chip Cookie: 210 cal, 10g fat, 2g protein, 30g carbs, 1g fiber, 18g sugar per 45g
('subway_chocolate_chip_cookie', 'Subway Chocolate Chip Cookie', 466.7, 4.4, 66.7, 22.2, 2.2, 40.0, 45, 45, 'subway.com', ARRAY['chocolate chip cookie', 'subway cookie'], '210 cal per cookie (45g)'),

-- ============================================================================
-- DUNKIN'
-- ============================================================================

-- Glazed Donut: 260 cal, 12g fat, 3g protein, 33g carbs, 1g fiber, 12g sugar per 74g
('dunkin_glazed_donut', 'Dunkin'' Glazed Donut', 351.4, 4.1, 44.6, 16.2, 1.4, 16.2, 74, 74, 'dunkindonuts.com', ARRAY['glazed donut', 'dunkin glazed', 'glazed doughnut'], '260 cal per donut (74g)'),

-- Chocolate Frosted Donut: 290 cal, 14g fat, 3g protein, 38g carbs, 1g fiber, 18g sugar per 78g
('dunkin_chocolate_frosted_donut', 'Dunkin'' Chocolate Frosted Donut', 371.8, 3.8, 48.7, 17.9, 1.3, 23.1, 78, 78, 'dunkindonuts.com', ARRAY['chocolate frosted donut', 'chocolate donut'], '290 cal per donut (78g)'),

-- Boston Kreme Donut: 280 cal, 12g fat, 3g protein, 39g carbs, 1g fiber, 17g sugar per 99g
('dunkin_boston_kreme_donut', 'Dunkin'' Boston Kreme Donut', 282.8, 3.0, 39.4, 12.1, 1.0, 17.2, 99, 99, 'dunkindonuts.com', ARRAY['boston kreme', 'boston cream donut'], '280 cal per donut (99g)'),

-- Jelly Donut: 270 cal, 11g fat, 3g protein, 39g carbs, 1g fiber, 14g sugar per 86g
('dunkin_jelly_donut', 'Dunkin'' Jelly Donut', 314.0, 3.5, 45.3, 12.8, 1.2, 16.3, 86, 86, 'dunkindonuts.com', ARRAY['jelly donut', 'jelly filled donut'], '270 cal per donut (86g)'),

-- Blueberry Muffin: 460 cal, 16g fat, 6g protein, 73g carbs, 2g fiber, 39g sugar per 152g
('dunkin_blueberry_muffin', 'Dunkin'' Blueberry Muffin', 302.6, 3.9, 48.0, 10.5, 1.3, 25.7, 152, 152, 'dunkindonuts.com', ARRAY['blueberry muffin', 'dunkin muffin'], '460 cal per muffin (152g)'),

-- Everything Bagel: 350 cal, 5g fat, 13g protein, 64g carbs, 3g fiber, 6g sugar per 122g
('dunkin_everything_bagel', 'Dunkin'' Everything Bagel', 286.9, 10.7, 52.5, 4.1, 2.5, 4.9, 122, 122, 'dunkindonuts.com', ARRAY['everything bagel', 'dunkin bagel'], '350 cal per bagel (122g)'),

-- Plain Bagel: 320 cal, 2g fat, 12g protein, 65g carbs, 3g fiber, 6g sugar per 119g
('dunkin_plain_bagel', 'Dunkin'' Plain Bagel', 268.9, 10.1, 54.6, 1.7, 2.5, 5.0, 119, 119, 'dunkindonuts.com', ARRAY['plain bagel'], '320 cal per bagel (119g)'),

-- Bacon Egg & Cheese Croissant: 550 cal, 33g fat, 19g protein, 42g carbs, 1g fiber, 6g sugar per 173g
('dunkin_bacon_egg_cheese_croissant', 'Dunkin'' Bacon Egg & Cheese on Croissant', 317.9, 11.0, 24.3, 19.1, 0.6, 3.5, 173, 173, 'dunkindonuts.com', ARRAY['bacon egg cheese croissant', 'bec croissant'], '550 cal per sandwich (173g)'),

-- Sausage Egg & Cheese Croissant: 650 cal, 42g fat, 21g protein, 42g carbs, 1g fiber, 6g sugar per 192g
('dunkin_sausage_egg_cheese_croissant', 'Dunkin'' Sausage Egg & Cheese on Croissant', 338.5, 10.9, 21.9, 21.9, 0.5, 3.1, 192, 192, 'dunkindonuts.com', ARRAY['sausage egg cheese croissant', 'sec croissant'], '650 cal per sandwich (192g)'),

-- Bacon Egg & Cheese on English Muffin: 360 cal, 17g fat, 18g protein, 33g carbs, 1g fiber, 3g sugar per 147g
('dunkin_bec_english_muffin', 'Dunkin'' Bacon Egg & Cheese on English Muffin', 244.9, 12.2, 22.4, 11.6, 0.7, 2.0, 147, 147, 'dunkindonuts.com', ARRAY['bacon egg cheese english muffin', 'bec muffin'], '360 cal per sandwich (147g)'),

-- Hash Browns 6pc: 370 cal, 23g fat, 3g protein, 38g carbs, 3g fiber, 0g sugar per 96g
('dunkin_hash_browns', 'Dunkin'' Hash Browns (6 pc)', 385.4, 3.1, 39.6, 24.0, 3.1, 0.0, 16, 96, 'dunkindonuts.com', ARRAY['hash browns', 'dunkin hash browns', '6 piece hash browns'], '370 cal per 6 pc (96g)'),

-- Medium Iced Coffee (with cream and sugar): 260 cal, 6g fat, 2g protein, 49g carbs, 0g fiber, 49g sugar per 680ml
('dunkin_iced_coffee_medium', 'Dunkin'' Medium Iced Coffee (Cream & Sugar)', 38.2, 0.3, 7.2, 0.9, 0.0, 7.2, 680, 680, 'dunkindonuts.com', ARRAY['iced coffee', 'medium iced coffee', 'dunkin iced coffee'], '260 cal per medium 24oz (680ml)'),

-- Medium Latte: 170 cal, 7g fat, 11g protein, 17g carbs, 0g fiber, 16g sugar per 397g
('dunkin_latte_medium', 'Dunkin'' Latte (Medium)', 42.8, 2.8, 4.3, 1.8, 0.0, 4.0, 397, 397, 'dunkindonuts.com', ARRAY['latte', 'dunkin latte', 'medium latte'], '170 cal per medium (397g)'),

-- Medium Caramel Swirl Latte: 310 cal, 7g fat, 11g protein, 51g carbs, 0g fiber, 46g sugar per 397g
('dunkin_caramel_swirl_latte', 'Dunkin'' Caramel Swirl Latte (Medium)', 78.1, 2.8, 12.8, 1.8, 0.0, 11.6, 397, 397, 'dunkindonuts.com', ARRAY['caramel swirl latte', 'caramel latte'], '310 cal per medium (397g)'),

-- Medium Frozen Coffee: 420 cal, 11g fat, 3g protein, 76g carbs, 1g fiber, 72g sugar per 680ml
('dunkin_frozen_coffee_medium', 'Dunkin'' Frozen Coffee (Medium)', 61.8, 0.4, 11.2, 1.6, 0.1, 10.6, 680, 680, 'dunkindonuts.com', ARRAY['frozen coffee', 'dunkin frozen coffee'], '420 cal per medium 24oz (680ml)'),

-- Medium Charli Cold Brew: 330 cal, 6g fat, 3g protein, 63g carbs, 0g fiber, 63g sugar per 680ml
('dunkin_charli_cold_brew', 'Dunkin'' Charli Cold Brew (Medium)', 48.5, 0.4, 9.3, 0.9, 0.0, 9.3, 680, 680, 'dunkindonuts.com', ARRAY['charli cold brew', 'charli drink', 'the charli'], '330 cal per medium 24oz (680ml)'),

-- ============================================================================
-- DOMINO'S
-- ============================================================================

-- Hand Tossed Cheese Pizza (14" Large, 1 slice): 280 cal, 10g fat, 12g protein, 36g carbs, 2g fiber, 3g sugar per 113g
('dominos_cheese_pizza_large_slice', 'Domino''s Hand Tossed Cheese Pizza (Large Slice)', 247.8, 10.6, 31.9, 8.8, 1.8, 2.7, 113, 113, 'dominos.com', ARRAY['cheese pizza slice', 'large cheese pizza slice', 'dominos cheese pizza'], '280 cal per slice (113g). Large 14" 1/8 pizza.'),

-- Hand Tossed Pepperoni Pizza (14" Large, 1 slice): 300 cal, 12g fat, 13g protein, 36g carbs, 2g fiber, 3g sugar per 113g
('dominos_pepperoni_pizza_large_slice', 'Domino''s Hand Tossed Pepperoni Pizza (Large Slice)', 265.5, 11.5, 31.9, 10.6, 1.8, 2.7, 113, 113, 'dominos.com', ARRAY['pepperoni pizza slice', 'large pepperoni pizza slice', 'dominos pepperoni'], '300 cal per slice (113g). Large 14" 1/8 pizza.'),

-- Hand Tossed MeatZZa Pizza (14" Large, 1 slice): 340 cal, 16g fat, 16g protein, 35g carbs, 2g fiber, 3g sugar per 128g
('dominos_meatzza_pizza_large_slice', 'Domino''s MeatZZa Pizza (Large Slice)', 265.6, 12.5, 27.3, 12.5, 1.6, 2.3, 128, 128, 'dominos.com', ARRAY['meatzza pizza', 'meatzza slice', 'meat lovers pizza'], '340 cal per slice (128g). Large 14" 1/8 pizza.'),

-- Hand Tossed Deluxe Pizza (14" Large, 1 slice): 300 cal, 13g fat, 12g protein, 35g carbs, 2g fiber, 3g sugar per 123g
('dominos_deluxe_pizza_large_slice', 'Domino''s Deluxe Pizza (Large Slice)', 243.9, 9.8, 28.5, 10.6, 1.6, 2.4, 123, 123, 'dominos.com', ARRAY['deluxe pizza slice', 'dominos deluxe'], '300 cal per slice (123g). Large 14" 1/8 pizza.'),

-- Hand Tossed BBQ Chicken Pizza (14" Large, 1 slice): 290 cal, 9g fat, 14g protein, 39g carbs, 1g fiber, 8g sugar per 123g
('dominos_bbq_chicken_pizza_large_slice', 'Domino''s BBQ Chicken Pizza (Large Slice)', 235.8, 11.4, 31.7, 7.3, 0.8, 6.5, 123, 123, 'dominos.com', ARRAY['bbq chicken pizza', 'bbq chicken slice'], '290 cal per slice (123g). Large 14" 1/8 pizza.'),

-- Medium Hand Tossed Cheese Pizza (12", 1 slice): 210 cal, 7.5g fat, 9g protein, 27g carbs, 1g fiber, 2g sugar per 85g
('dominos_cheese_pizza_medium_slice', 'Domino''s Hand Tossed Cheese Pizza (Medium Slice)', 247.1, 10.6, 31.8, 8.8, 1.2, 2.4, 85, 85, 'dominos.com', ARRAY['medium cheese pizza slice', 'medium cheese slice'], '210 cal per slice (85g). Medium 12" 1/8 pizza.'),

-- Stuffed Cheesy Bread: 120 cal, 6g fat, 5g protein, 12g carbs, 1g fiber, 1g sugar per 38g
('dominos_stuffed_cheesy_bread', 'Domino''s Stuffed Cheesy Bread (1 piece)', 315.8, 13.2, 31.6, 15.8, 2.6, 2.6, 38, 38, 'dominos.com', ARRAY['stuffed cheesy bread', 'cheesy bread'], '120 cal per piece (38g). 8 pieces per order.'),

-- Boneless Chicken Wings 8pc: 700 cal, 34g fat, 32g protein, 66g carbs, 3g fiber, 4g sugar per 228g
('dominos_boneless_wings_8pc', 'Domino''s Boneless Chicken Wings (8 pc)', 307.0, 14.0, 28.9, 14.9, 1.3, 1.8, 28, 228, 'dominos.com', ARRAY['boneless wings', 'boneless chicken', 'dominos boneless wings'], '700 cal per 8 pc (228g). Without dipping sauce.'),

-- Bread Twists: 200 cal, 8g fat, 5g protein, 27g carbs, 1g fiber, 2g sugar per 57g
('dominos_bread_twists', 'Domino''s Bread Twists (2 pc)', 350.9, 8.8, 47.4, 14.0, 1.8, 3.5, 28, 57, 'dominos.com', ARRAY['bread twists', 'garlic bread twists'], '200 cal per 2 pc (57g). Served with marinara sauce.'),

-- Pasta in Dish - Chicken Alfredo: 600 cal, 30g fat, 26g protein, 56g carbs, 3g fiber, 4g sugar per 397g
('dominos_chicken_alfredo_pasta', 'Domino''s Chicken Alfredo Pasta', 151.1, 6.5, 14.1, 7.6, 0.8, 1.0, 397, 397, 'dominos.com', ARRAY['chicken alfredo pasta', 'alfredo pasta', 'pasta in a dish'], '600 cal per order (397g)'),

-- Pasta in Dish - Italian Sausage Marinara: 560 cal, 21g fat, 23g protein, 70g carbs, 5g fiber, 8g sugar per 397g
('dominos_sausage_marinara_pasta', 'Domino''s Italian Sausage Marinara Pasta', 141.1, 5.8, 17.6, 5.3, 1.3, 2.0, 397, 397, 'dominos.com', ARRAY['sausage marinara pasta', 'marinara pasta'], '560 cal per order (397g)'),

-- Cinnamon Bread Twists: 250 cal, 11g fat, 3g protein, 34g carbs, 1g fiber, 11g sugar per 57g
('dominos_cinnamon_bread_twists', 'Domino''s Cinnamon Bread Twists (2 pc)', 438.6, 5.3, 59.6, 19.3, 1.8, 19.3, 57, 57, 'dominos.com', ARRAY['cinnamon twists', 'cinnamon bread twists'], '250 cal per 2 pc (57g). With sweet icing.'),

-- Marbled Cookie Brownie: 200 cal, 9g fat, 2g protein, 28g carbs, 1g fiber, 17g sugar per 51g
('dominos_marbled_cookie_brownie', 'Domino''s Marbled Cookie Brownie (1 pc)', 392.2, 3.9, 54.9, 17.6, 2.0, 33.3, 51, 51, 'dominos.com', ARRAY['cookie brownie', 'marbled brownie', 'brownie'], '200 cal per piece (51g). 9 pc per order.'),

-- ============================================================================
-- POPEYES
-- ============================================================================

-- Classic Chicken Sandwich: 700 cal, 42g fat, 28g protein, 50g carbs, 2g fiber, 8g sugar per 200g
('popeyes_chicken_sandwich', 'Popeyes Classic Chicken Sandwich', 350.0, 14.0, 25.0, 21.0, 1.0, 4.0, 200, 200, 'popeyes.com', ARRAY['chicken sandwich', 'popeyes sandwich', 'classic chicken sandwich'], '700 cal per sandwich (200g)'),

-- Spicy Chicken Sandwich: 700 cal, 42g fat, 28g protein, 50g carbs, 2g fiber, 8g sugar per 200g
('popeyes_spicy_chicken_sandwich', 'Popeyes Spicy Chicken Sandwich', 350.0, 14.0, 25.0, 21.0, 1.0, 4.0, 200, 200, 'popeyes.com', ARRAY['spicy sandwich', 'spicy chicken sandwich'], '700 cal per sandwich (200g)'),

-- 3pc Chicken Tenders (Mild): 340 cal, 14g fat, 35g protein, 16g carbs, 1g fiber, 0g sugar per 127g
('popeyes_tenders_3pc', 'Popeyes Chicken Tenders (3 pc)', 267.7, 27.6, 12.6, 11.0, 0.8, 0.0, 42, 127, 'popeyes.com', ARRAY['3 piece tenders', 'chicken tenders', '3pc tenders'], '340 cal per 3 pc (127g)'),

-- 5pc Chicken Tenders (Mild): 570 cal, 23g fat, 58g protein, 27g carbs, 2g fiber, 0g sugar per 212g
('popeyes_tenders_5pc', 'Popeyes Chicken Tenders (5 pc)', 268.9, 27.4, 12.7, 10.8, 0.9, 0.0, 42, 212, 'popeyes.com', ARRAY['5 piece tenders', '5pc tenders'], '570 cal per 5 pc (212g)'),

-- 2pc Chicken (Breast & Wing, Mild): 440 cal, 26g fat, 35g protein, 16g carbs, 1g fiber, 0g sugar per 178g
('popeyes_2pc_chicken_breast_wing', 'Popeyes 2 pc Chicken (Breast & Wing)', 247.2, 19.7, 9.0, 14.6, 0.6, 0.0, 178, 178, 'popeyes.com', ARRAY['2 piece chicken', '2pc breast wing'], '440 cal per 2 pc (178g)'),

-- 2pc Chicken (Leg & Thigh, Mild): 350 cal, 22g fat, 22g protein, 14g carbs, 1g fiber, 0g sugar per 152g
('popeyes_2pc_chicken_leg_thigh', 'Popeyes 2 pc Chicken (Leg & Thigh)', 230.3, 14.5, 9.2, 14.5, 0.7, 0.0, 152, 152, 'popeyes.com', ARRAY['2 piece leg thigh', '2pc dark meat'], '350 cal per 2 pc (152g)'),

-- Chicken Breast (Mild): 280 cal, 16g fat, 24g protein, 10g carbs, 0g fiber, 0g sugar per 128g
('popeyes_chicken_breast', 'Popeyes Chicken Breast', 218.8, 18.8, 7.8, 12.5, 0.0, 0.0, 128, 128, 'popeyes.com', ARRAY['chicken breast', 'breast piece'], '280 cal per breast (128g)'),

-- Chicken Leg (Mild): 160 cal, 9g fat, 14g protein, 5g carbs, 0g fiber, 0g sugar per 72g
('popeyes_chicken_leg', 'Popeyes Chicken Leg', 222.2, 19.4, 6.9, 12.5, 0.0, 0.0, 72, 72, 'popeyes.com', ARRAY['chicken leg', 'drumstick'], '160 cal per leg (72g)'),

-- Chicken Thigh (Mild): 230 cal, 15g fat, 14g protein, 9g carbs, 1g fiber, 0g sugar per 99g
('popeyes_chicken_thigh', 'Popeyes Chicken Thigh', 232.3, 14.1, 9.1, 15.2, 1.0, 0.0, 99, 99, 'popeyes.com', ARRAY['chicken thigh', 'thigh piece'], '230 cal per thigh (99g)'),

-- Chicken Wing (Mild): 150 cal, 10g fat, 10g protein, 5g carbs, 0g fiber, 0g sugar per 57g
('popeyes_chicken_wing', 'Popeyes Chicken Wing', 263.2, 17.5, 8.8, 17.5, 0.0, 0.0, 57, 57, 'popeyes.com', ARRAY['chicken wing', 'wing piece'], '150 cal per wing (57g)'),

-- Biscuit: 200 cal, 11g fat, 3g protein, 23g carbs, 1g fiber, 2g sugar per 57g
('popeyes_biscuit', 'Popeyes Biscuit', 350.9, 5.3, 40.4, 19.3, 1.8, 3.5, 57, 57, 'popeyes.com', ARRAY['biscuit', 'popeyes biscuit', 'buttermilk biscuit'], '200 cal per biscuit (57g)'),

-- Cajun Fries Regular: 260 cal, 14g fat, 3g protein, 31g carbs, 3g fiber, 0g sugar per 99g
('popeyes_cajun_fries_regular', 'Popeyes Cajun Fries (Regular)', 262.6, 3.0, 31.3, 14.1, 3.0, 0.0, 99, 99, 'popeyes.com', ARRAY['cajun fries', 'regular fries', 'popeyes fries'], '260 cal per regular (99g)'),

-- Cajun Fries Large: 470 cal, 25g fat, 5g protein, 57g carbs, 5g fiber, 0g sugar per 170g
('popeyes_cajun_fries_large', 'Popeyes Cajun Fries (Large)', 276.5, 2.9, 33.5, 14.7, 2.9, 0.0, 170, 170, 'popeyes.com', ARRAY['large cajun fries', 'large fries'], '470 cal per large (170g)'),

-- Red Beans & Rice Regular: 230 cal, 6g fat, 8g protein, 34g carbs, 6g fiber, 1g sugar per 142g
('popeyes_red_beans_rice', 'Popeyes Red Beans & Rice (Regular)', 162.0, 5.6, 23.9, 4.2, 4.2, 0.7, 142, 142, 'popeyes.com', ARRAY['red beans and rice', 'red beans rice'], '230 cal per regular (142g)'),

-- Mashed Potatoes & Gravy Regular: 110 cal, 4g fat, 1g protein, 18g carbs, 2g fiber, 1g sugar per 142g
('popeyes_mashed_potatoes_gravy', 'Popeyes Mashed Potatoes & Gravy (Regular)', 77.5, 0.7, 12.7, 2.8, 1.4, 0.7, 142, 142, 'popeyes.com', ARRAY['mashed potatoes', 'mashed potatoes and gravy'], '110 cal per regular (142g)'),

-- Coleslaw Regular: 200 cal, 15g fat, 1g protein, 17g carbs, 2g fiber, 13g sugar per 128g
('popeyes_coleslaw', 'Popeyes Coleslaw (Regular)', 156.3, 0.8, 13.3, 11.7, 1.6, 10.2, 128, 128, 'popeyes.com', ARRAY['coleslaw', 'cole slaw'], '200 cal per regular (128g)'),

-- Mac & Cheese Regular: 340 cal, 19g fat, 14g protein, 28g carbs, 1g fiber, 4g sugar per 142g
('popeyes_mac_and_cheese', 'Popeyes Mac & Cheese (Regular)', 239.4, 9.9, 19.7, 13.4, 0.7, 2.8, 142, 142, 'popeyes.com', ARRAY['mac and cheese', 'mac n cheese', 'macaroni and cheese'], '340 cal per regular (142g)'),

-- Cajun Rice Regular: 170 cal, 5g fat, 7g protein, 25g carbs, 1g fiber, 0g sugar per 113g
('popeyes_cajun_rice', 'Popeyes Cajun Rice (Regular)', 150.4, 6.2, 22.1, 4.4, 0.9, 0.0, 113, 113, 'popeyes.com', ARRAY['cajun rice'], '170 cal per regular (113g)'),

-- Apple Pie: 230 cal, 11g fat, 3g protein, 31g carbs, 1g fiber, 14g sugar per 85g
('popeyes_apple_pie', 'Popeyes Cinnamon Apple Pie', 270.6, 3.5, 36.5, 12.9, 1.2, 16.5, 85, 85, 'popeyes.com', ARRAY['apple pie', 'cinnamon apple pie'], '230 cal per pie (85g)')
