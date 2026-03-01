-- ============================================================================
-- Batch 20: Chinese, Turkish & Misc Restaurant Chains
-- Restaurants: Din Tai Fung, German Doner Kebab, Pret a Manger, HuHot Mongolian Grill, La Granja
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com, calorieking.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. DIN TAI FUNG (~16 US locations)
-- Source: dintaifungusa.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Xiao Long Bao (Pork Soup Dumplings, 10 pcs): 480 cal, 22g protein, 42g carbs, 24g fat per 250g
('dtf_xiao_long_bao', 'Din Tai Fung Xiao Long Bao (Pork)', 192.0, 8.8, 16.8, 9.6, 0.5, 1.5, 25, 250, 'dintaifungusa.com', ARRAY['din tai fung xlb', 'din tai fung soup dumplings', 'din tai fung xiao long bao'], '480 cal per 10 pieces (250g). Signature pork soup dumplings.', 'Din Tai Fung', 'asian', 10),

-- Chicken Soup Dumplings (10 pcs): 420 cal, 24g protein, 40g carbs, 18g fat per 250g
('dtf_chicken_xlb', 'Din Tai Fung Chicken Xiao Long Bao', 168.0, 9.6, 16.0, 7.2, 0.5, 1.0, 25, 250, 'dintaifungusa.com', ARRAY['din tai fung chicken dumplings', 'din tai fung chicken xlb'], '420 cal per 10 pieces (250g).', 'Din Tai Fung', 'asian', 10),

-- Truffle & Pork XLB (5 pcs): 280 cal, 12g protein, 22g carbs, 16g fat per 130g
('dtf_truffle_xlb', 'Din Tai Fung Truffle Xiao Long Bao', 215.4, 9.2, 16.9, 12.3, 0.3, 1.0, 26, 130, 'dintaifungusa.com', ARRAY['din tai fung truffle dumplings', 'din tai fung truffle xlb'], '280 cal per 5 pieces (130g). Premium truffle-infused.', 'Din Tai Fung', 'asian', 5),

-- Shrimp & Pork Wontons (8 pcs): 320 cal, 18g protein, 28g carbs, 14g fat per 220g
('dtf_wontons', 'Din Tai Fung Shrimp & Pork Wontons', 145.5, 8.2, 12.7, 6.4, 0.3, 1.0, 28, 220, 'dintaifungusa.com', ARRAY['din tai fung wontons', 'din tai fung shrimp wontons'], '320 cal per 8 pieces (220g). In chili oil or broth.', 'Din Tai Fung', 'asian', 8),

-- Fried Rice with Shrimp: 520 cal, 18g protein, 62g carbs, 22g fat per 350g
('dtf_shrimp_fried_rice', 'Din Tai Fung Shrimp Fried Rice', 148.6, 5.1, 17.7, 6.3, 0.5, 1.0, NULL, 350, 'dintaifungusa.com', ARRAY['din tai fung fried rice', 'din tai fung shrimp rice'], '520 cal per 350g serving.', 'Din Tai Fung', 'asian', 1),

-- Dan Dan Noodles: 580 cal, 20g protein, 58g carbs, 28g fat per 380g
('dtf_dan_dan_noodles', 'Din Tai Fung Dan Dan Noodles', 152.6, 5.3, 15.3, 7.4, 1.0, 2.0, NULL, 380, 'dintaifungusa.com', ARRAY['din tai fung dan dan', 'din tai fung noodles'], '580 cal per 380g serving. Spicy Sichuan peanut noodles with pork.', 'Din Tai Fung', 'asian', 1),

-- Cucumber Salad: 80 cal, 2g protein, 6g carbs, 5g fat per 150g
('dtf_cucumber_salad', 'Din Tai Fung Cucumber Salad', 53.3, 1.3, 4.0, 3.3, 1.0, 2.0, NULL, 150, 'dintaifungusa.com', ARRAY['din tai fung cucumber'], '80 cal per 150g serving. Garlic sesame cucumber.', 'Din Tai Fung', 'salads', 1),

-- Baked Taro Buns (3 pcs): 360 cal, 6g protein, 48g carbs, 16g fat per 150g
('dtf_taro_buns', 'Din Tai Fung Baked Taro Buns', 240.0, 4.0, 32.0, 10.7, 1.0, 12.0, 50, 150, 'dintaifungusa.com', ARRAY['din tai fung taro buns', 'din tai fung dessert buns'], '360 cal per 3 buns (150g). Sweet taro paste filled buns.', 'Din Tai Fung', 'desserts', 3),

-- ============================================================================
-- 2. GERMAN DONER KEBAB (~10 US, 170+ worldwide)
-- Source: germandonerkebab.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Original Doner Kebab: 680 cal, 32g protein, 52g carbs, 36g fat per 380g
('gdk_original_kebab', 'German Doner Kebab Original', 178.9, 8.4, 13.7, 9.5, 1.5, 2.5, 380, 380, 'germandonerkebab.com', ARRAY['german doner kebab', 'gdk original', 'gdk doner'], '680 cal per kebab (380g). Seasoned beef/chicken in handmade bread.', 'German Doner Kebab', 'turkish', 1),

-- Chicken Doner Kebab: 620 cal, 36g protein, 50g carbs, 28g fat per 370g
('gdk_chicken_kebab', 'German Doner Kebab Chicken', 167.6, 9.7, 13.5, 7.6, 1.5, 2.0, 370, 370, 'germandonerkebab.com', ARRAY['gdk chicken doner', 'german doner chicken'], '620 cal per kebab (370g).', 'German Doner Kebab', 'turkish', 1),

-- Doner Quesadilla: 580 cal, 28g protein, 42g carbs, 32g fat per 300g
('gdk_quesadilla', 'German Doner Kebab Quesadilla', 193.3, 9.3, 14.0, 10.7, 1.0, 1.5, 300, 300, 'germandonerkebab.com', ARRAY['gdk quesadilla', 'german doner quesadilla'], '580 cal per quesadilla (300g).', 'German Doner Kebab', 'turkish', 1),

-- Doner Burger: 550 cal, 30g protein, 38g carbs, 30g fat per 280g
('gdk_burger', 'German Doner Kebab Doner Burger', 196.4, 10.7, 13.6, 10.7, 1.0, 2.0, 280, 280, 'germandonerkebab.com', ARRAY['gdk burger', 'german doner burger'], '550 cal per burger (280g). Doner meat in brioche bun.', 'German Doner Kebab', 'turkish', 1),

-- Fries: 320 cal, 4g protein, 40g carbs, 16g fat per 180g
('gdk_fries', 'German Doner Kebab Fries', 177.8, 2.2, 22.2, 8.9, 2.0, 0.5, NULL, 180, 'germandonerkebab.com', ARRAY['gdk fries', 'german doner fries'], '320 cal per regular (180g).', 'German Doner Kebab', 'sides', 1),

-- ============================================================================
-- 3. PRET A MANGER (~60 US locations)
-- Source: pret.com/en-US/nutrition, nutritionix.com
-- ============================================================================

-- Chicken Avocado Baguette: 520 cal, 28g protein, 48g carbs, 22g fat per 300g
('pret_chicken_avocado', 'Pret a Manger Chicken Avocado Baguette', 173.3, 9.3, 16.0, 7.3, 3.0, 2.0, 300, 300, 'pret.com', ARRAY['pret chicken avocado', 'pret chicken sandwich'], '520 cal per baguette (300g).', 'Pret a Manger', 'sandwiches', 1),

-- Tuna & Cucumber Baguette: 480 cal, 24g protein, 46g carbs, 20g fat per 280g
('pret_tuna_cucumber', 'Pret a Manger Tuna & Cucumber Baguette', 171.4, 8.6, 16.4, 7.1, 1.5, 1.5, 280, 280, 'pret.com', ARRAY['pret tuna sandwich', 'pret tuna baguette'], '480 cal per baguette (280g).', 'Pret a Manger', 'sandwiches', 1),

-- Classic Super Club: 550 cal, 30g protein, 42g carbs, 28g fat per 300g
('pret_super_club', 'Pret a Manger Classic Super Club', 183.3, 10.0, 14.0, 9.3, 1.5, 2.0, 300, 300, 'pret.com', ARRAY['pret club sandwich', 'pret super club'], '550 cal per sandwich (300g). Chicken, bacon, egg, mayo.', 'Pret a Manger', 'sandwiches', 1),

-- Chicken Caesar Wrap: 480 cal, 26g protein, 38g carbs, 24g fat per 270g
('pret_caesar_wrap', 'Pret a Manger Chicken Caesar Wrap', 177.8, 9.6, 14.1, 8.9, 1.5, 1.5, 270, 270, 'pret.com', ARRAY['pret chicken wrap', 'pret caesar wrap'], '480 cal per wrap (270g).', 'Pret a Manger', 'sandwiches', 1),

-- Almond Croissant: 440 cal, 10g protein, 38g carbs, 28g fat per 110g
('pret_almond_croissant', 'Pret a Manger Almond Croissant', 400.0, 9.1, 34.5, 25.5, 1.5, 12.0, 110, 110, 'pret.com', ARRAY['pret almond croissant', 'pret croissant'], '440 cal per croissant (110g).', 'Pret a Manger', 'french', 1),

-- Tomato Soup: 180 cal, 4g protein, 22g carbs, 8g fat per 350g
('pret_tomato_soup', 'Pret a Manger Tomato Soup', 51.4, 1.1, 6.3, 2.3, 1.5, 4.0, NULL, 350, 'pret.com', ARRAY['pret tomato soup'], '180 cal per bowl (350g).', 'Pret a Manger', 'soups', 1),

-- Chocolate Cookie: 380 cal, 5g protein, 46g carbs, 20g fat per 80g
('pret_chocolate_cookie', 'Pret a Manger Dark Chocolate Cookie', 475.0, 6.3, 57.5, 25.0, 2.0, 28.0, 80, 80, 'pret.com', ARRAY['pret cookie', 'pret chocolate chunk cookie'], '380 cal per cookie (80g).', 'Pret a Manger', 'desserts', 1),

-- ============================================================================
-- 4. HUHOT MONGOLIAN GRILL (~60 US locations)
-- Source: huhot.com, nutritionix.com, myfitnesspal.com
-- Build-your-own bowls - common combos shown
-- ============================================================================

-- Chicken Bowl (typical): 480 cal, 32g protein, 48g carbs, 16g fat per 400g
('huhot_chicken_bowl', 'HuHot Mongolian Chicken Bowl', 120.0, 8.0, 12.0, 4.0, 2.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot chicken', 'huhot chicken bowl', 'huhot mongolian chicken'], '480 cal per typical bowl (400g). Chicken with rice noodles, veggies, Khan''s Favorite sauce.', 'HuHot Mongolian Grill', 'asian', 1),

-- Beef Bowl (typical): 540 cal, 30g protein, 48g carbs, 24g fat per 400g
('huhot_beef_bowl', 'HuHot Mongolian Beef Bowl', 135.0, 7.5, 12.0, 6.0, 2.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot beef', 'huhot beef bowl', 'huhot mongolian beef'], '540 cal per typical bowl (400g). Beef with noodles, veggies, BBQ sauce.', 'HuHot Mongolian Grill', 'asian', 1),

-- Shrimp Bowl (typical): 420 cal, 28g protein, 48g carbs, 12g fat per 400g
('huhot_shrimp_bowl', 'HuHot Mongolian Shrimp Bowl', 105.0, 7.0, 12.0, 3.0, 2.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot shrimp', 'huhot shrimp bowl'], '420 cal per typical bowl (400g). Shrimp with rice, veggies, lemon sauce.', 'HuHot Mongolian Grill', 'asian', 1),

-- Tofu Bowl (typical): 380 cal, 18g protein, 50g carbs, 12g fat per 400g
('huhot_tofu_bowl', 'HuHot Mongolian Tofu Bowl', 95.0, 4.5, 12.5, 3.0, 3.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot tofu', 'huhot vegetarian bowl'], '380 cal per typical bowl (400g).', 'HuHot Mongolian Grill', 'asian', 1),

-- ============================================================================
-- 5. LA GRANJA (Peruvian, ~50 US locations in FL)
-- Source: lagranjarestaurants.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Pollo a la Brasa (quarter chicken): 350 cal, 32g protein, 0g carbs, 24g fat per 220g
('la_granja_pollo_brasa', 'La Granja Pollo a la Brasa (Quarter)', 159.1, 14.5, 0.0, 10.9, 0.0, 0.0, NULL, 220, 'lagranjarestaurants.com', ARRAY['la granja chicken', 'la granja pollo a la brasa', 'la granja rotisserie chicken'], '350 cal per quarter (220g). Peruvian-style rotisserie chicken.', 'La Granja', 'peruvian', 1),

-- Lomo Saltado: 520 cal, 28g protein, 42g carbs, 24g fat per 380g
('la_granja_lomo_saltado', 'La Granja Lomo Saltado', 136.8, 7.4, 11.1, 6.3, 1.5, 2.0, NULL, 380, 'lagranjarestaurants.com', ARRAY['la granja lomo saltado', 'la granja beef stir fry'], '520 cal per 380g plate. Peruvian stir-fried beef with onions, tomatoes, fries over rice.', 'La Granja', 'peruvian', 1),

-- Aji de Gallina: 480 cal, 22g protein, 38g carbs, 26g fat per 380g
('la_granja_aji_de_gallina', 'La Granja Aji de Gallina', 126.3, 5.8, 10.0, 6.8, 1.0, 1.5, NULL, 380, 'lagranjarestaurants.com', ARRAY['la granja aji de gallina', 'la granja creamy chicken'], '480 cal per 380g plate. Shredded chicken in creamy aji amarillo sauce.', 'La Granja', 'peruvian', 1),

-- Arroz con Pollo: 450 cal, 26g protein, 48g carbs, 16g fat per 400g
('la_granja_arroz_con_pollo', 'La Granja Arroz con Pollo', 112.5, 6.5, 12.0, 4.0, 1.0, 1.0, NULL, 400, 'lagranjarestaurants.com', ARRAY['la granja arroz con pollo', 'la granja chicken rice'], '450 cal per 400g plate. Green rice with chicken.', 'La Granja', 'peruvian', 1),

-- Ceviche: 220 cal, 22g protein, 12g carbs, 8g fat per 250g
('la_granja_ceviche', 'La Granja Ceviche', 88.0, 8.8, 4.8, 3.2, 1.0, 2.0, NULL, 250, 'lagranjarestaurants.com', ARRAY['la granja ceviche', 'la granja fish ceviche'], '220 cal per 250g serving. Fresh fish in lime juice with onions, cilantro.', 'La Granja', 'peruvian', 1),

-- Green Sauce (Aji Verde): 60 cal, 0.5g protein, 1g carbs, 6g fat per 30g
('la_granja_aji_verde', 'La Granja Aji Verde Sauce', 200.0, 1.7, 3.3, 20.0, 0.5, 0.5, NULL, 30, 'lagranjarestaurants.com', ARRAY['la granja green sauce', 'la granja aji verde'], '60 cal per 30g serving. Signature creamy green chili sauce.', 'La Granja', 'sauces', 1)
