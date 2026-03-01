-- ============================================================================
-- 282_overrides_african.sql
-- Generated: 2026-02-28
-- Total items: 51
--
-- African cuisine nutrition overrides covering:
--   - Nando's PERi-PERi (restaurant chain)
--   - Ethiopian cuisine
--   - Nigerian / West African cuisine
--   - North African cuisine (Moroccan, Tunisian, etc.)
--   - South African cuisine
--
-- Sources: nandos.co.uk, nandos.com.au, fatsecret.co.uk, fatsecret.co.za,
--          eatthismuch.com, nutritionix.com, snapcalorie.com, mynetdiary.com,
--          nutritionvalue.org, nutriscan.app, USDA FoodData Central,
--          loseitnigerian.com, fitnigerian.com, africanbites.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes
) VALUES
-- ============================================================================
-- NANDO'S PERI-PERI
-- Sources: nandos.co.uk, nandos.com.au, fatsecret.co.uk, fatsecret.co.za,
--          eatthismuch.com, mynetdiary.com, snapcalorie.com, menuofnandos.uk
-- ============================================================================
-- Quarter Chicken: 265 cal, 30g pro, 0g carb, 15g fat per 200g serving
('nandos_quarter_chicken', 'Nando''s PERi-PERi Quarter Chicken', 132.5, 15.0, 0.0, 7.5, 0.0, 0.0, 200, 200, 'nandos.com', ARRAY['nandos quarter chicken', 'peri peri quarter chicken', 'nando''s 1/4 chicken'], '265 cal per quarter (200g)'),
-- Half Chicken: 577 cal, 62g pro, 0g carb, 35g fat per 400g serving
('nandos_half_chicken', 'Nando''s PERi-PERi Half Chicken', 144.3, 15.5, 0.0, 8.8, 0.0, 0.0, 400, 400, 'nandos.com', ARRAY['nandos half chicken', 'peri peri half chicken', 'nando''s 1/2 chicken'], '577 cal per half chicken (400g)'),
-- Whole Chicken: 1088 cal, ~120g pro, 0g carb, ~66g fat per 764g serving
('nandos_whole_chicken', 'Nando''s PERi-PERi Whole Chicken', 142.4, 15.7, 0.0, 8.6, 0.0, 0.0, 764, 764, 'nandos.com', ARRAY['nandos whole chicken', 'peri peri whole chicken', 'nando''s full chicken'], '1088 cal per whole chicken (764g)'),
-- Chicken Breast: 430 cal, 52g pro, 0g carb, 23g fat per ~250g serving (butterflied)
('nandos_chicken_breast', 'Nando''s PERi-PERi Chicken Breast', 172.0, 20.8, 0.0, 9.2, 0.0, 0.0, 250, 250, 'nandos.com', ARRAY['nandos chicken breast', 'peri peri chicken breast', 'nando''s butterfly breast'], '430 cal per breast (250g)'),
-- Chicken Thighs (2): 280 cal, 26g pro, 1g carb, 19g fat per ~200g serving
('nandos_chicken_thighs', 'Nando''s PERi-PERi Chicken Thighs', 140.0, 13.0, 0.5, 9.5, 0.0, 0.0, 100, 200, 'nandos.com', ARRAY['nandos chicken thighs', 'peri peri thighs', 'nando''s boneless thighs'], '280 cal per 2 thighs (200g)'),
-- Chicken Wings (10): 598 cal, 47g pro, 0g carb, 45g fat per ~400g serving
('nandos_chicken_wings', 'Nando''s PERi-PERi Chicken Wings', 149.5, 11.8, 0.0, 11.3, 0.0, 0.0, 40, 400, 'nandos.com', ARRAY['nandos wings', 'peri peri wings', 'nando''s chicken wings'], '598 cal per 10 wings (400g)'),
-- Chicken Wrap: 543 cal, 30g pro, 45g carb, 25g fat per ~280g serving
('nandos_chicken_wrap', 'Nando''s PERi-PERi Chicken Wrap', 193.9, 10.7, 16.1, 8.9, 1.4, 2.0, 280, 280, 'nandos.com', ARRAY['nandos wrap', 'peri peri wrap', 'nando''s chicken wrap', 'nandos grilled chicken wrap'], '543 cal per wrap (280g)'),
-- Chicken Burger: 386 cal, 28g pro, 30g carb, 16g fat per 230g serving
('nandos_chicken_burger', 'Nando''s PERi-PERi Chicken Burger', 167.8, 12.2, 13.0, 7.0, 1.3, 2.5, 230, 230, 'nandos.com', ARRAY['nandos burger', 'peri peri burger', 'nando''s chicken burger', 'nandos grilled chicken burger'], '386 cal per burger (230g)'),
-- Espetada: 349 cal, 48g pro, 4g carb, 16g fat per ~220g serving
('nandos_espetada', 'Nando''s Chicken Espetada', 158.6, 21.8, 1.8, 7.2, 0.0, 0.5, 220, 220, 'nandos.com', ARRAY['nandos espetada', 'peri peri espetada', 'chicken espetada', 'chicken skewer nandos'], '349 cal per espetada (220g)'),
-- Chicken Livers: 413 cal, 35g pro, 10g carb, 25g fat per ~200g serving
('nandos_chicken_livers', 'Nando''s PERi-PERi Chicken Livers', 206.5, 17.5, 5.0, 12.5, 0.5, 1.0, 200, 200, 'nandos.com', ARRAY['nandos chicken livers', 'peri peri livers', 'nando''s livers'], '413 cal per serving (200g)'),
-- Spicy Rice: 246 cal, 5g pro, 45g carb, 5g fat per ~200g regular serving
('nandos_spicy_rice', 'Nando''s Spicy Rice', 123.0, 2.5, 22.5, 2.5, 0.8, 0.5, NULL, 200, 'nandos.com', ARRAY['nandos spicy rice', 'peri peri rice', 'nando''s rice'], '246 cal per regular (200g)'),
-- Peri Chips: 450 cal, 5g pro, 55g carb, 23g fat per ~200g serving
('nandos_peri_chips', 'Nando''s PERi-Salted Chips', 225.0, 2.5, 27.5, 11.5, 2.5, 0.3, NULL, 200, 'nandos.com', ARRAY['nandos chips', 'peri chips', 'nando''s fries', 'nandos fries', 'peri salted chips'], '450 cal per regular (200g)'),
-- Coleslaw: 236 cal, 2g pro, 14g carb, 19g fat per ~150g serving
('nandos_coleslaw', 'Nando''s Coleslaw', 157.3, 1.3, 9.3, 12.7, 1.5, 6.0, NULL, 150, 'nandos.com', ARRAY['nandos coleslaw', 'nando''s coleslaw', 'nandos cole slaw'], '236 cal per regular (150g)'),
-- Corn on the Cob: 255 cal, 6g pro, 35g carb, 11g fat per ~200g serving
('nandos_corn_on_cob', 'Nando''s Corn on the Cob', 127.5, 3.0, 17.5, 5.5, 2.5, 4.0, 200, 200, 'nandos.com', ARRAY['nandos corn', 'nando''s corn on the cob', 'charred corn nandos'], '255 cal per cob (200g)'),
-- Portuguese Roll: 220 cal, 7g pro, 40g carb, 3g fat per ~80g roll
('nandos_portuguese_roll', 'Nando''s Portuguese Roll', 275.0, 8.8, 50.0, 3.8, 2.0, 2.5, 80, 80, 'nandos.com', ARRAY['nandos roll', 'portuguese roll', 'nando''s bread roll', 'nandos bread'], '220 cal per roll (80g)'),
-- Garlic Bread: 365 cal, 8g pro, 40g carb, 18g fat per ~100g serving
('nandos_garlic_bread', 'Nando''s Garlic Bread', 365.0, 8.0, 40.0, 18.0, 1.5, 2.0, 100, 100, 'nandos.com', ARRAY['nandos garlic bread', 'nando''s garlic bread'], '365 cal per serving (100g)'),
-- Halloumi: ~250 cal, 18g pro, 2g carb, 19g fat per ~80g serving
('nandos_halloumi', 'Nando''s Grilled Halloumi', 312.5, 22.5, 2.5, 23.8, 0.0, 1.0, 80, 80, 'nandos.com', ARRAY['nandos halloumi', 'nando''s halloumi', 'grilled halloumi nandos'], '250 cal per serving (80g)'),
-- Macho Peas: 180 cal, 10g pro, 18g carb, 7g fat per ~150g serving
('nandos_macho_peas', 'Nando''s Macho Peas', 120.0, 6.7, 12.0, 4.7, 4.0, 2.0, NULL, 150, 'nandos.com', ARRAY['nandos macho peas', 'nando''s macho peas', 'peri peri peas'], '180 cal per serving (150g)'),

-- ============================================================================
-- ETHIOPIAN CUISINE
-- Sources: nutritionvalue.org, nutriscan.app, snapcalorie.com, nutritionix.com,
--          meatcheftools.com, USDA FoodData Central
-- ============================================================================
-- Injera: 130 cal, 5g pro, 25g carb, 1g fat per 100g (USDA/nutritionvalue.org)
('injera', 'Injera (Ethiopian Flatbread)', 130.0, 5.0, 25.0, 1.0, 1.8, 0.5, 60, 180, 'african_cuisine', ARRAY['injera bread', 'ethiopian flatbread', 'teff bread', 'ethiopian bread', 'enjera'], 'Fermented teff flatbread, ~60g per piece, ~180g per serving (3 pieces)'),
-- Doro Wot: ~170 cal, 15g pro, 8g carb, 9g fat per 100g
('doro_wot', 'Doro Wot (Ethiopian Chicken Stew)', 170.0, 15.0, 8.0, 9.0, 1.5, 2.0, NULL, 250, 'african_cuisine', ARRAY['doro wot', 'doro wat', 'ethiopian chicken stew', 'doro wett', 'doro wet'], 'Spicy chicken stew with hard-boiled egg, ~250g per serving'),
-- Misir Wot: ~175 cal, 9g pro, 24g carb, 5g fat per 100g
('misir_wot', 'Misir Wot (Red Lentil Stew)', 175.0, 9.0, 24.0, 5.0, 5.0, 1.5, NULL, 200, 'african_cuisine', ARRAY['misir wot', 'mesir wot', 'ethiopian lentil stew', 'red lentil wot', 'misir wat'], 'Spiced red lentil stew, ~200g per serving'),
-- Shiro Wot: ~160 cal, 8g pro, 20g carb, 5.5g fat per 100g
('shiro_wot', 'Shiro Wot (Chickpea Stew)', 160.0, 8.0, 20.0, 5.5, 4.0, 1.0, NULL, 200, 'african_cuisine', ARRAY['shiro wot', 'shiro wat', 'ethiopian chickpea stew', 'chickpea flour stew', 'shiro'], 'Chickpea flour stew, common fasting dish, ~200g per serving'),
-- Kitfo: ~175 cal, 15g pro, 2.5g carb, 12.5g fat per 100g
('kitfo', 'Kitfo (Ethiopian Steak Tartare)', 175.0, 15.0, 2.5, 12.5, 0.0, 0.5, NULL, 200, 'african_cuisine', ARRAY['kitfo', 'ketfo', 'ethiopian raw beef', 'ethiopian tartare', 'kitfoo'], 'Minced raw beef with mitmita and niter kibbeh, ~200g per serving'),
-- Tibs: ~200 cal, 20g pro, 4g carb, 11g fat per 100g
('tibs', 'Tibs (Ethiopian Sauteed Meat)', 200.0, 20.0, 4.0, 11.0, 1.0, 1.5, NULL, 250, 'african_cuisine', ARRAY['tibs', 'tibbs', 'ethiopian tibs', 'derek tibs', 'tibs wot', 'sauteed beef ethiopian'], 'Sauteed beef or lamb with vegetables, ~250g per serving'),
-- Gomen: ~65 cal, 3g pro, 7g carb, 3g fat per 100g
('gomen', 'Gomen (Ethiopian Collard Greens)', 65.0, 3.0, 7.0, 3.0, 3.5, 1.0, NULL, 150, 'african_cuisine', ARRAY['gomen', 'gomen wot', 'ethiopian collard greens', 'gomen besiga', 'ye gomen kitfo'], 'Braised collard greens with Ethiopian spices, ~150g per serving'),
-- Ayib: ~98 cal, 11g pro, 3g carb, 4.5g fat per 100g
('ayib', 'Ayib (Ethiopian Cottage Cheese)', 98.0, 11.0, 3.0, 4.5, 0.0, 1.0, NULL, 80, 'african_cuisine', ARRAY['ayib', 'ayb', 'ethiopian cottage cheese', 'ethiopian cheese', 'lab'], 'Mild fresh cheese served as a cooling side, ~80g per serving'),
-- Firfir: ~165 cal, 4g pro, 20g carb, 8g fat per 100g
('firfir', 'Firfir (Injera Scramble)', 165.0, 4.0, 20.0, 8.0, 2.0, 1.5, NULL, 200, 'african_cuisine', ARRAY['firfir', 'fitfit', 'fit-fit', 'injera firfir', 'chechebsa'], 'Shredded injera sauteed in spiced butter and berbere, ~200g per serving'),
-- Yetsom Beyaynetu: ~140 cal, 6g pro, 18g carb, 5g fat per 100g (mixed plate average)
('yetsom_beyaynetu', 'Yetsom Beyaynetu (Ethiopian Veggie Combo)', 140.0, 6.0, 18.0, 5.0, 4.5, 2.0, NULL, 500, 'african_cuisine', ARRAY['yetsom beyaynetu', 'beyaynetu', 'ethiopian vegetable platter', 'fasting platter', 'veggie combo ethiopian'], 'Mixed vegetable platter on injera (fasting dish), ~500g per serving'),

-- ============================================================================
-- NIGERIAN / WEST AFRICAN CUISINE
-- Sources: loseitnigerian.com, fitnigerian.com, snapcalorie.com,
--          fatsecret.co.za, nutritionix.com, africanbites.com, USDA
-- ============================================================================
-- Jollof Rice: ~156 cal, 3.5g pro, 25g carb, 5g fat per 100g
('jollof_rice', 'Jollof Rice', 156.0, 3.5, 25.0, 5.0, 1.0, 2.0, NULL, 250, 'african_cuisine', ARRAY['jollof rice', 'nigerian jollof', 'west african jollof', 'jollof', 'jolof rice', 'ghanaian jollof'], 'Tomato-based seasoned rice, ~390 cal per 250g serving'),
-- Egusi Soup: ~180 cal, 9g pro, 5g carb, 14g fat per 100g
('egusi_soup', 'Egusi Soup', 180.0, 9.0, 5.0, 14.0, 2.5, 1.0, NULL, 250, 'african_cuisine', ARRAY['egusi soup', 'egusi stew', 'melon seed soup', 'nigerian egusi'], 'Melon seed soup with leafy greens and protein, ~250g per serving'),
-- Suya: ~250 cal, 25g pro, 5g carb, 14g fat per 100g
('suya', 'Suya (Grilled Meat Skewers)', 250.0, 25.0, 5.0, 14.0, 1.0, 0.5, 50, 150, 'african_cuisine', ARRAY['suya', 'nigerian suya', 'beef suya', 'chicken suya', 'suya kebab', 'yaji'], 'Spicy grilled beef skewers with ground peanut rub, ~50g per skewer'),
-- Puff Puff: ~340 cal, 5g pro, 48g carb, 14g fat per 100g
('puff_puff', 'Puff Puff (Nigerian Fried Dough)', 340.0, 5.0, 48.0, 14.0, 1.0, 12.0, 30, 120, 'african_cuisine', ARRAY['puff puff', 'puff-puff', 'nigerian puff puff', 'bofrot', 'mikate', 'african doughnut'], 'Sweet deep-fried dough balls, ~30g each'),
-- Moi Moi: ~120 cal, 7.5g pro, 11g carb, 5g fat per 100g
('moi_moi', 'Moi Moi (Steamed Bean Pudding)', 120.0, 7.5, 11.0, 5.0, 3.0, 1.0, 100, 200, 'african_cuisine', ARRAY['moi moi', 'moin moin', 'moyin moyin', 'nigerian bean pudding', 'bean cake'], 'Steamed black-eyed bean pudding, ~100g per wrap'),
-- Fufu: ~166 cal, 1.5g pro, 34g carb, 0.2g fat per 100g
('fufu', 'Fufu', 166.0, 1.5, 34.0, 0.2, 3.0, 0.5, NULL, 300, 'african_cuisine', ARRAY['fufu', 'foofoo', 'foutou', 'pounded yam fufu', 'cassava fufu', 'garri fufu'], 'Pounded starchy dough (cassava/yam), ~300g per serving'),
-- Ogbono Soup: ~85 cal, 5g pro, 4g carb, 6g fat per 100g
('ogbono_soup', 'Ogbono Soup', 85.0, 5.0, 4.0, 6.0, 2.0, 0.5, NULL, 250, 'african_cuisine', ARRAY['ogbono soup', 'draw soup', 'ogbono stew', 'nigerian ogbono'], 'Thick soup from ground ogbono (bush mango) seeds, ~250g per serving'),
-- Chin Chin: ~470 cal, 7g pro, 56g carb, 24g fat per 100g
('chin_chin', 'Chin Chin (Nigerian Fried Snack)', 470.0, 7.0, 56.0, 24.0, 1.5, 15.0, NULL, 50, 'african_cuisine', ARRAY['chin chin', 'chinchin', 'chin-chin', 'nigerian chin chin'], 'Crunchy fried flour snack, ~50g per handful'),
-- Fried Plantain: ~252 cal, 1.7g pro, 41g carb, 10g fat per 100g (USDA)
('fried_plantain', 'Fried Plantain (Dodo)', 252.0, 1.7, 41.0, 10.0, 2.3, 18.0, NULL, 150, 'african_cuisine', ARRAY['fried plantain', 'dodo', 'kelewele', 'fried ripe plantain', 'plantain fry', 'alloco'], 'Pan-fried ripe plantain slices, ~252 cal per 100g (USDA)'),
-- Pepper Soup: ~60 cal, 7g pro, 3g carb, 2.5g fat per 100g
('pepper_soup', 'Pepper Soup (Nigerian)', 60.0, 7.0, 3.0, 2.5, 0.5, 0.5, NULL, 350, 'african_cuisine', ARRAY['pepper soup', 'nigerian pepper soup', 'goat pepper soup', 'chicken pepper soup', 'catfish pepper soup', 'point and kill'], 'Spicy broth-based soup with meat or fish, ~350g per serving'),

-- ============================================================================
-- NORTH AFRICAN CUISINE (Morocco, Tunisia, Algeria, Egypt)
-- Sources: snapcalorie.com, fatsecret.com, nutritionix.com,
--          eatthismuch.com, nutriscan.app, caloriemenu.com
-- ============================================================================
-- Chicken Tagine: ~115 cal, 12g pro, 7g carb, 4.5g fat per 100g
('chicken_tagine', 'Chicken Tagine (Moroccan)', 115.0, 12.0, 7.0, 4.5, 1.5, 3.0, NULL, 350, 'african_cuisine', ARRAY['chicken tagine', 'moroccan chicken tagine', 'tagine chicken', 'tajine chicken', 'poulet tagine'], 'Slow-cooked chicken with preserved lemons and olives, ~350g per serving'),
-- Lamb Tagine: ~180 cal, 8g pro, 10g carb, 8g fat per 100g
('lamb_tagine', 'Lamb Tagine (Moroccan)', 180.0, 8.0, 10.0, 12.0, 2.0, 5.0, NULL, 350, 'african_cuisine', ARRAY['lamb tagine', 'moroccan lamb tagine', 'tagine lamb', 'tajine lamb', 'tagine agneau'], 'Slow-cooked lamb with dried fruits and spices, ~350g per serving'),
-- Couscous (cooked): ~112 cal, 3.8g pro, 23g carb, 0.2g fat per 100g (USDA)
('couscous', 'Couscous (Cooked)', 112.0, 3.8, 23.2, 0.2, 1.4, 0.1, NULL, 200, 'african_cuisine', ARRAY['couscous', 'cous cous', 'moroccan couscous', 'north african couscous', 'semolina couscous'], 'Steamed semolina granules, ~112 cal per 100g (USDA)'),
-- Harissa Chicken: ~165 cal, 22g pro, 3g carb, 7g fat per 100g
('harissa_chicken', 'Harissa Chicken', 165.0, 22.0, 3.0, 7.0, 0.5, 1.0, NULL, 200, 'african_cuisine', ARRAY['harissa chicken', 'harissa grilled chicken', 'north african chicken', 'spicy harissa chicken'], 'Chicken marinated and grilled with harissa paste, ~200g per serving'),
-- Shakshuka: ~131 cal, 7g pro, 8g carb, 8g fat per 100g
('shakshuka', 'Shakshuka (Eggs in Tomato Sauce)', 131.0, 7.0, 8.0, 8.0, 1.5, 4.0, NULL, 300, 'african_cuisine', ARRAY['shakshuka', 'shakshouka', 'eggs in tomato sauce', 'north african eggs', 'chakchouka'], '131 cal per 100g (fatsecret), ~300g per serving with 2 eggs'),
-- Merguez Sausage: ~280 cal, 16g pro, 1g carb, 24g fat per 100g
('merguez_sausage', 'Merguez Sausage', 280.0, 16.0, 1.0, 24.0, 0.0, 0.5, 75, 150, 'african_cuisine', ARRAY['merguez', 'merguez sausage', 'north african sausage', 'lamb merguez', 'spicy lamb sausage'], 'Spiced lamb/beef sausage, ~75g per link'),
-- Brik: ~310 cal, 11g pro, 25g carb, 18g fat per 100g
('brik', 'Brik (North African Pastry)', 310.0, 11.0, 25.0, 18.0, 1.0, 1.5, 120, 120, 'african_cuisine', ARRAY['brik', 'brick', 'tunisian brik', 'brik au thon', 'bourek', 'borek'], 'Crispy pastry filled with egg, tuna, or meat, ~120g per piece'),

-- ============================================================================
-- SOUTH AFRICAN CUISINE
-- Sources: fatsecret.co.za, eatthismuch.com, snapcalorie.com,
--          proteafoods.com, healthline.com, bobaasbiltong.co.za
-- ============================================================================
-- Bobotie: ~145 cal, 10g pro, 8g carb, 8g fat per 100g
('bobotie', 'Bobotie (South African Meat Bake)', 145.0, 10.0, 8.0, 8.0, 1.0, 3.0, NULL, 250, 'african_cuisine', ARRAY['bobotie', 'south african bobotie', 'cape malay bobotie', 'bobootie'], 'Spiced curried mince baked with egg custard topping, ~250g per serving'),
-- Bunny Chow: ~175 cal, 10g pro, 22g carb, 5.5g fat per 100g
('bunny_chow', 'Bunny Chow (Durban Curry in Bread)', 175.0, 10.0, 22.0, 5.5, 2.0, 2.5, 400, 400, 'african_cuisine', ARRAY['bunny chow', 'bunny', 'durban bunny chow', 'quarter bunny', 'bean bunny'], 'Hollowed bread loaf filled with curry, ~400g per quarter bunny'),
-- Biltong: ~250 cal, 53g pro, 1.5g carb, 4g fat per 100g
('biltong', 'Biltong (South African Dried Beef)', 250.0, 53.0, 1.5, 4.0, 0.0, 0.5, NULL, 50, 'african_cuisine', ARRAY['biltong', 'south african biltong', 'beef biltong', 'droewors', 'dried beef'], 'Air-dried seasoned beef, high-protein snack, ~50g per serving'),
-- Boerewors: ~270 cal, 16g pro, 3g carb, 22g fat per 100g
('boerewors', 'Boerewors (South African Sausage)', 270.0, 16.0, 3.0, 22.0, 0.0, 0.5, 150, 150, 'african_cuisine', ARRAY['boerewors', 'boerie', 'south african sausage', 'boerewors roll', 'braai sausage'], 'Traditional spiced beef/pork sausage, ~150g per coil portion'),
-- Chakalaka: ~93 cal, 3g pro, 8g carb, 6g fat per 100g
('chakalaka', 'Chakalaka (South African Relish)', 93.0, 3.0, 8.0, 6.0, 2.5, 3.0, NULL, 150, 'african_cuisine', ARRAY['chakalaka', 'south african chakalaka', 'spicy vegetable relish', 'chakalaka relish'], 'Spicy vegetable relish with beans and tomato, ~150g per serving'),
-- Pap: ~70 cal, 1.5g pro, 15g carb, 0.3g fat per 100g
('pap', 'Pap (South African Maize Porridge)', 70.0, 1.5, 15.0, 0.3, 1.0, 0.2, NULL, 300, 'african_cuisine', ARRAY['pap', 'mielie pap', 'maize porridge', 'mealie pap', 'ugali', 'sadza', 'nshima', 'phaleche'], 'Stiff maize meal porridge, staple side dish, ~300g per serving')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    sugar_per_100g = EXCLUDED.sugar_per_100g,
    default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
    default_serving_g = EXCLUDED.default_serving_g,
    source = EXCLUDED.source,
    variant_names = EXCLUDED.variant_names,
    notes = EXCLUDED.notes,
    updated_at = NOW();


-- ============================================================================
-- Backfill restaurant_name for Nando's items
-- ============================================================================
UPDATE food_nutrition_overrides
SET restaurant_name = 'Nando''s'
WHERE source = 'nandos.com'
  AND restaurant_name IS NULL;

-- ============================================================================
-- Backfill food_category for African cuisine items
-- ============================================================================
UPDATE food_nutrition_overrides
SET food_category = CASE
  -- Nando's chicken mains
  WHEN food_name_normalized IN ('nandos_quarter_chicken', 'nandos_half_chicken', 'nandos_whole_chicken', 'nandos_chicken_breast', 'nandos_chicken_thighs', 'nandos_chicken_wings', 'nandos_espetada', 'nandos_chicken_livers')
    THEN 'chicken'
  -- Nando's sandwiches/wraps
  WHEN food_name_normalized IN ('nandos_chicken_wrap', 'nandos_chicken_burger')
    THEN 'sandwiches'
  -- Nando's sides
  WHEN food_name_normalized IN ('nandos_spicy_rice', 'nandos_peri_chips', 'nandos_coleslaw', 'nandos_corn_on_cob', 'nandos_portuguese_roll', 'nandos_garlic_bread', 'nandos_halloumi', 'nandos_macho_peas')
    THEN 'sides'
  -- Ethiopian
  WHEN food_name_normalized IN ('injera', 'firfir')
    THEN 'ethiopian'
  WHEN food_name_normalized IN ('doro_wot', 'misir_wot', 'shiro_wot', 'kitfo', 'tibs', 'gomen', 'ayib', 'yetsom_beyaynetu')
    THEN 'ethiopian'
  -- Nigerian / West African
  WHEN food_name_normalized IN ('jollof_rice', 'egusi_soup', 'suya', 'puff_puff', 'moi_moi', 'fufu', 'ogbono_soup', 'chin_chin', 'fried_plantain', 'pepper_soup')
    THEN 'nigerian'
  -- North African
  WHEN food_name_normalized IN ('chicken_tagine', 'lamb_tagine', 'couscous', 'harissa_chicken', 'shakshuka', 'merguez_sausage', 'brik')
    THEN 'north_african'
  -- South African
  WHEN food_name_normalized IN ('bobotie', 'bunny_chow', 'biltong', 'boerewors', 'chakalaka', 'pap')
    THEN 'south_african'
  ELSE food_category
END
WHERE food_name_normalized IN (
  'nandos_quarter_chicken', 'nandos_half_chicken', 'nandos_whole_chicken',
  'nandos_chicken_breast', 'nandos_chicken_thighs', 'nandos_chicken_wings',
  'nandos_chicken_wrap', 'nandos_chicken_burger', 'nandos_espetada',
  'nandos_chicken_livers', 'nandos_spicy_rice', 'nandos_peri_chips',
  'nandos_coleslaw', 'nandos_corn_on_cob', 'nandos_portuguese_roll',
  'nandos_garlic_bread', 'nandos_halloumi', 'nandos_macho_peas',
  'injera', 'doro_wot', 'misir_wot', 'shiro_wot', 'kitfo', 'tibs',
  'gomen', 'ayib', 'firfir', 'yetsom_beyaynetu',
  'jollof_rice', 'egusi_soup', 'suya', 'puff_puff', 'moi_moi', 'fufu',
  'ogbono_soup', 'chin_chin', 'fried_plantain', 'pepper_soup',
  'chicken_tagine', 'lamb_tagine', 'couscous', 'harissa_chicken',
  'shakshuka', 'merguez_sausage', 'brik',
  'bobotie', 'bunny_chow', 'biltong', 'boerewors', 'chakalaka', 'pap'
);

-- ============================================================================
-- Backfill default_count for multi-piece items
-- ============================================================================
UPDATE food_nutrition_overrides
SET default_count = CASE
  WHEN food_name_normalized = 'nandos_chicken_wings' THEN 10
  WHEN food_name_normalized = 'nandos_chicken_thighs' THEN 2
  WHEN food_name_normalized = 'puff_puff' THEN 4
  WHEN food_name_normalized = 'moi_moi' THEN 2
  WHEN food_name_normalized = 'merguez_sausage' THEN 2
  WHEN food_name_normalized = 'injera' THEN 3
  WHEN food_name_normalized = 'suya' THEN 3
  ELSE 1
END
WHERE food_name_normalized IN (
  'nandos_quarter_chicken', 'nandos_half_chicken', 'nandos_whole_chicken',
  'nandos_chicken_breast', 'nandos_chicken_thighs', 'nandos_chicken_wings',
  'nandos_chicken_wrap', 'nandos_chicken_burger', 'nandos_espetada',
  'nandos_chicken_livers', 'nandos_spicy_rice', 'nandos_peri_chips',
  'nandos_coleslaw', 'nandos_corn_on_cob', 'nandos_portuguese_roll',
  'nandos_garlic_bread', 'nandos_halloumi', 'nandos_macho_peas',
  'injera', 'doro_wot', 'misir_wot', 'shiro_wot', 'kitfo', 'tibs',
  'gomen', 'ayib', 'firfir', 'yetsom_beyaynetu',
  'jollof_rice', 'egusi_soup', 'suya', 'puff_puff', 'moi_moi', 'fufu',
  'ogbono_soup', 'chin_chin', 'fried_plantain', 'pepper_soup',
  'chicken_tagine', 'lamb_tagine', 'couscous', 'harissa_chicken',
  'shakshuka', 'merguez_sausage', 'brik',
  'bobotie', 'bunny_chow', 'biltong', 'boerewors', 'chakalaka', 'pap'
);
