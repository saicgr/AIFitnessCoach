-- ============================================================================
-- Batch 18: French, Indian & Vietnamese Restaurant Chains
-- Restaurants: La Madeleine, Le Pain Quotidien, Curry Up Now, Choolaah, Pho Hoa, Lee's Sandwiches
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. LA MADELEINE FRENCH BAKERY (~85 US locations)
-- Source: lamadeleine.com/nutrition, nutritionix.com
-- ============================================================================

-- Quiche Lorraine: 380 cal, 16g protein, 22g carbs, 26g fat per 200g
('la_madeleine_quiche_lorraine', 'La Madeleine Quiche Lorraine', 190.0, 8.0, 11.0, 13.0, 0.5, 1.5, 200, 200, 'lamadeleine.com', ARRAY['la madeleine quiche', 'la madeleine lorraine'], '380 cal per slice (200g). Classic French quiche with bacon, Swiss cheese.', 'La Madeleine', 'french', 1),

-- Caesar Salad: 320 cal, 10g protein, 14g carbs, 24g fat per 220g
('la_madeleine_caesar', 'La Madeleine Caesar Salad', 145.5, 4.5, 6.4, 10.9, 2.0, 1.5, NULL, 220, 'lamadeleine.com', ARRAY['la madeleine caesar salad'], '320 cal per 220g salad.', 'La Madeleine', 'salads', 1),

-- Chicken Friand: 450 cal, 20g protein, 28g carbs, 28g fat per 200g
('la_madeleine_chicken_friand', 'La Madeleine Chicken Friand', 225.0, 10.0, 14.0, 14.0, 0.5, 1.0, 200, 200, 'lamadeleine.com', ARRAY['la madeleine friand', 'la madeleine chicken pastry'], '450 cal per pastry (200g). Flaky puff pastry filled with chicken, mushrooms.', 'La Madeleine', 'french', 1),

-- French Onion Soup: 280 cal, 12g protein, 22g carbs, 16g fat per 350g
('la_madeleine_french_onion_soup', 'La Madeleine French Onion Soup', 80.0, 3.4, 6.3, 4.6, 0.5, 3.0, NULL, 350, 'lamadeleine.com', ARRAY['la madeleine onion soup'], '280 cal per bowl (350g). With Gruyère cheese crouton.', 'La Madeleine', 'soups', 1),

-- Croque Monsieur: 520 cal, 28g protein, 32g carbs, 30g fat per 250g
('la_madeleine_croque_monsieur', 'La Madeleine Croque Monsieur', 208.0, 11.2, 12.8, 12.0, 0.5, 1.5, 250, 250, 'lamadeleine.com', ARRAY['la madeleine croque monsieur', 'la madeleine ham cheese sandwich'], '520 cal per sandwich (250g). Grilled ham and cheese with béchamel.', 'La Madeleine', 'french', 1),

-- Croissant: 310 cal, 6g protein, 32g carbs, 18g fat per 75g
('la_madeleine_croissant', 'La Madeleine Butter Croissant', 413.3, 8.0, 42.7, 24.0, 1.0, 4.0, 75, 75, 'lamadeleine.com', ARRAY['la madeleine croissant', 'la madeleine plain croissant'], '310 cal per croissant (75g).', 'La Madeleine', 'french', 1),

-- Tomato Basil Soup: 200 cal, 4g protein, 22g carbs, 10g fat per 350g
('la_madeleine_tomato_soup', 'La Madeleine Tomato Basil Soup', 57.1, 1.1, 6.3, 2.9, 1.5, 4.0, NULL, 350, 'lamadeleine.com', ARRAY['la madeleine tomato soup'], '200 cal per bowl (350g).', 'La Madeleine', 'soups', 1),

-- Palmier Cookie: 280 cal, 3g protein, 32g carbs, 16g fat per 60g
('la_madeleine_palmier', 'La Madeleine Palmier', 466.7, 5.0, 53.3, 26.7, 0.5, 18.0, 60, 60, 'lamadeleine.com', ARRAY['la madeleine palmier cookie'], '280 cal per cookie (60g). Caramelized puff pastry.', 'La Madeleine', 'desserts', 1),

-- ============================================================================
-- 2. LE PAIN QUOTIDIEN (~60 US locations)
-- Source: lepainquotidien.com, nutritionix.com
-- ============================================================================

-- Avocado Toast: 380 cal, 10g protein, 38g carbs, 22g fat per 200g
('le_pain_avocado_toast', 'Le Pain Quotidien Avocado Toast', 190.0, 5.0, 19.0, 11.0, 4.0, 1.5, NULL, 200, 'lepainquotidien.com', ARRAY['le pain quotidien avocado toast', 'le pain avocado'], '380 cal per serving (200g). Smashed avocado on organic wheat tartine.', 'Le Pain Quotidien', 'french', 1),

-- Tartine Gruyère: 420 cal, 18g protein, 34g carbs, 24g fat per 200g
('le_pain_tartine_gruyere', 'Le Pain Quotidien Tartine Gruyère', 210.0, 9.0, 17.0, 12.0, 1.0, 1.0, NULL, 200, 'lepainquotidien.com', ARRAY['le pain quotidien cheese tartine', 'le pain gruyere'], '420 cal per tartine (200g). Open-faced Gruyère on organic bread.', 'Le Pain Quotidien', 'french', 1),

-- Croissant aux Amandes: 420 cal, 8g protein, 38g carbs, 26g fat per 100g
('le_pain_almond_croissant', 'Le Pain Quotidien Almond Croissant', 420.0, 8.0, 38.0, 26.0, 1.5, 14.0, 100, 100, 'lepainquotidien.com', ARRAY['le pain quotidien almond croissant', 'le pain croissant'], '420 cal per croissant (100g). Filled with almond cream.', 'Le Pain Quotidien', 'french', 1),

-- Organic Granola Bowl: 380 cal, 10g protein, 52g carbs, 14g fat per 280g
('le_pain_granola_bowl', 'Le Pain Quotidien Granola Bowl', 135.7, 3.6, 18.6, 5.0, 3.0, 12.0, NULL, 280, 'lepainquotidien.com', ARRAY['le pain quotidien granola', 'le pain granola'], '380 cal per bowl (280g). With yogurt, honey, fresh fruit.', 'Le Pain Quotidien', 'breakfast', 1),

-- Mushroom & Gruyère Quiche: 400 cal, 16g protein, 24g carbs, 28g fat per 210g
('le_pain_mushroom_quiche', 'Le Pain Quotidien Mushroom Quiche', 190.5, 7.6, 11.4, 13.3, 0.5, 1.0, 210, 210, 'lepainquotidien.com', ARRAY['le pain quotidien quiche', 'le pain mushroom quiche'], '400 cal per slice (210g).', 'Le Pain Quotidien', 'french', 1),

-- ============================================================================
-- 3. CURRY UP NOW (~20 US locations)
-- Source: curryupnow.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Tikka Masala Burrito: 680 cal, 28g protein, 72g carbs, 30g fat per 400g
('curry_up_now_tikka_burrito', 'Curry Up Now Tikka Masala Burrito', 170.0, 7.0, 18.0, 7.5, 2.0, 3.0, 400, 400, 'curryupnow.com', ARRAY['curry up now burrito', 'curry up now tikka burrito'], '680 cal per burrito (400g). Indian-Mexican fusion with tikka masala, rice, naan.', 'Curry Up Now', 'indian', 1),

-- Naughty Naan: 520 cal, 18g protein, 48g carbs, 28g fat per 280g
('curry_up_now_naughty_naan', 'Curry Up Now Naughty Naan', 185.7, 6.4, 17.1, 10.0, 1.5, 2.5, NULL, 280, 'curryupnow.com', ARRAY['curry up now naughty naan', 'curry up now naan pizza'], '520 cal per 280g serving. Naan topped with tikka, chutney, sev.', 'Curry Up Now', 'indian', 1),

-- Samosas (3 pcs): 360 cal, 8g protein, 36g carbs, 20g fat per 180g
('curry_up_now_samosas', 'Curry Up Now Samosas', 200.0, 4.4, 20.0, 11.1, 2.0, 1.0, 60, 180, 'curryupnow.com', ARRAY['curry up now samosa', 'curry up now sexy fries'], '360 cal per 3 pieces (180g). Crispy potato-pea samosas.', 'Curry Up Now', 'indian', 3),

-- Thali Plate: 580 cal, 22g protein, 68g carbs, 24g fat per 450g
('curry_up_now_thali', 'Curry Up Now Thali Plate', 128.9, 4.9, 15.1, 5.3, 3.0, 3.0, NULL, 450, 'curryupnow.com', ARRAY['curry up now thali', 'curry up now plate'], '580 cal per 450g plate. Rice, curry, dal, raita, naan.', 'Curry Up Now', 'indian', 1),

-- ============================================================================
-- 4. CHOOLAAH INDIAN BBQ (~15 US locations)
-- Source: choolaah.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Chicken Tikka Bowl: 520 cal, 34g protein, 52g carbs, 18g fat per 420g
('choolaah_chicken_tikka_bowl', 'Choolaah Chicken Tikka Bowl', 123.8, 8.1, 12.4, 4.3, 2.0, 2.0, NULL, 420, 'choolaah.com', ARRAY['choolaah chicken bowl', 'choolaah tikka bowl'], '520 cal per 420g bowl. Tandoori chicken tikka with rice, dal, naan.', 'Choolaah', 'indian', 1),

-- Lamb Seekh Kebab Bowl: 580 cal, 30g protein, 52g carbs, 26g fat per 420g
('choolaah_lamb_kebab', 'Choolaah Lamb Seekh Kebab Bowl', 138.1, 7.1, 12.4, 6.2, 2.0, 2.0, NULL, 420, 'choolaah.com', ARRAY['choolaah lamb bowl', 'choolaah seekh kebab'], '580 cal per 420g bowl.', 'Choolaah', 'indian', 1),

-- Paneer Tikka Bowl: 540 cal, 22g protein, 54g carbs, 26g fat per 420g
('choolaah_paneer_bowl', 'Choolaah Paneer Tikka Bowl', 128.6, 5.2, 12.9, 6.2, 2.0, 2.5, NULL, 420, 'choolaah.com', ARRAY['choolaah paneer bowl', 'choolaah vegetarian bowl'], '540 cal per 420g bowl.', 'Choolaah', 'indian', 1),

-- Garlic Naan: 280 cal, 8g protein, 40g carbs, 10g fat per 100g
('choolaah_garlic_naan', 'Choolaah Garlic Naan', 280.0, 8.0, 40.0, 10.0, 1.5, 2.0, 100, 100, 'choolaah.com', ARRAY['choolaah naan', 'choolaah garlic naan bread'], '280 cal per naan (100g).', 'Choolaah', 'indian', 1),

-- ============================================================================
-- 5. PHO HOA (~70 worldwide locations)
-- Source: phohoa.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Pho Tai (Rare Steak Pho): 480 cal, 28g protein, 60g carbs, 12g fat per 700g
('pho_hoa_pho_tai', 'Pho Hoa Pho Tai (Rare Steak)', 68.6, 4.0, 8.6, 1.7, 0.5, 1.0, NULL, 700, 'phohoa.com', ARRAY['pho hoa rare steak pho', 'pho hoa pho tai'], '480 cal per large bowl (700g). Rice noodle soup with rare beef.', 'Pho Hoa', 'vietnamese', 1),

-- Pho Dac Biet (Special Combo Pho): 550 cal, 32g protein, 62g carbs, 18g fat per 750g
('pho_hoa_dac_biet', 'Pho Hoa Pho Dac Biet (Special)', 73.3, 4.3, 8.3, 2.4, 0.5, 1.0, NULL, 750, 'phohoa.com', ARRAY['pho hoa special combo', 'pho hoa dac biet'], '550 cal per large bowl (750g). Beef pho with steak, brisket, tendon, tripe.', 'Pho Hoa', 'vietnamese', 1),

-- Bun Bo Hue: 520 cal, 26g protein, 58g carbs, 18g fat per 700g
('pho_hoa_bun_bo_hue', 'Pho Hoa Bun Bo Hue', 74.3, 3.7, 8.3, 2.6, 0.5, 1.5, NULL, 700, 'phohoa.com', ARRAY['pho hoa bun bo hue', 'pho hoa spicy beef noodle'], '520 cal per bowl (700g). Spicy beef noodle soup, Hue style.', 'Pho Hoa', 'vietnamese', 1),

-- Spring Rolls (2 pcs): 180 cal, 8g protein, 22g carbs, 6g fat per 240g
('pho_hoa_spring_rolls', 'Pho Hoa Fresh Spring Rolls', 75.0, 3.3, 9.2, 2.5, 1.0, 2.0, 120, 240, 'phohoa.com', ARRAY['pho hoa spring rolls', 'pho hoa goi cuon'], '180 cal per 2 rolls (240g). Rice paper rolls with shrimp, pork, herbs.', 'Pho Hoa', 'vietnamese', 2),

-- Vietnamese Iced Coffee: 180 cal, 2g protein, 28g carbs, 6g fat per 350g
('pho_hoa_vietnamese_coffee', 'Pho Hoa Vietnamese Iced Coffee', 51.4, 0.6, 8.0, 1.7, 0.0, 7.0, NULL, 350, 'phohoa.com', ARRAY['pho hoa ca phe sua da', 'pho hoa iced coffee'], '180 cal per 350g glass. Strong coffee with sweetened condensed milk.', 'Pho Hoa', 'drinks', 1),

-- ============================================================================
-- 6. LEE'S SANDWICHES (~60 US locations)
-- Source: leessandwiches.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- #1 Special Combo Banh Mi: 480 cal, 24g protein, 48g carbs, 20g fat per 350g
('lees_special_combo_banh_mi', 'Lee''s Sandwiches #1 Special Combo', 137.1, 6.9, 13.7, 5.7, 1.5, 3.0, 350, 350, 'leessandwiches.com', ARRAY['lees special combo', 'lees banh mi combo', 'lee sandwiches special'], '480 cal per sandwich (350g). Pork, pâté, ham, pickled veggies, jalapeño.', 'Lee''s Sandwiches', 'vietnamese', 1),

-- Grilled Pork Banh Mi: 450 cal, 22g protein, 46g carbs, 18g fat per 330g
('lees_grilled_pork_banh_mi', 'Lee''s Sandwiches Grilled Pork Banh Mi', 136.4, 6.7, 13.9, 5.5, 1.5, 3.0, 330, 330, 'leessandwiches.com', ARRAY['lees grilled pork', 'lees bbq pork sandwich', 'lee sandwiches grilled pork'], '450 cal per sandwich (330g).', 'Lee''s Sandwiches', 'vietnamese', 1),

-- Chicken Banh Mi: 420 cal, 24g protein, 44g carbs, 14g fat per 330g
('lees_chicken_banh_mi', 'Lee''s Sandwiches Chicken Banh Mi', 127.3, 7.3, 13.3, 4.2, 1.5, 3.0, 330, 330, 'leessandwiches.com', ARRAY['lees chicken sandwich', 'lee sandwiches chicken'], '420 cal per sandwich (330g).', 'Lee''s Sandwiches', 'vietnamese', 1),

-- Vietnamese Iced Coffee: 160 cal, 2g protein, 26g carbs, 5g fat per 400g
('lees_vietnamese_coffee', 'Lee''s Sandwiches Vietnamese Iced Coffee', 40.0, 0.5, 6.5, 1.3, 0.0, 6.0, NULL, 400, 'leessandwiches.com', ARRAY['lees iced coffee', 'lee sandwiches ca phe'], '160 cal per 400g drink.', 'Lee''s Sandwiches', 'drinks', 1),

-- Egg Rolls (2 pcs): 320 cal, 10g protein, 28g carbs, 18g fat per 140g
('lees_egg_rolls', 'Lee''s Sandwiches Egg Rolls', 228.6, 7.1, 20.0, 12.9, 1.0, 1.5, 70, 140, 'leessandwiches.com', ARRAY['lees egg rolls', 'lee sandwiches cha gio'], '320 cal per 2 rolls (140g). Crispy fried rolls with pork, vegetables.', 'Lee''s Sandwiches', 'vietnamese', 2)
