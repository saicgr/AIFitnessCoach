-- ============================================================================
-- Batch 13: Mediterranean & Greek Restaurant Chains
-- Restaurants: Taziki's, The Great Greek, Luna Grill, Naf Naf Grill, Nick the Greek
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. TAZIKI'S MEDITERRANEAN CAFE (~103 US locations)
-- Source: tazikiscafe.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Grilled Chicken Plate: 420 cal, 38g protein, 28g carbs, 16g fat per 350g
('tazikis_grilled_chicken', 'Taziki''s Grilled Chicken Plate', 120.0, 10.9, 8.0, 4.6, 1.0, 1.5, NULL, 350, 'tazikiscafe.com', ARRAY['tazikis chicken', 'tazikis grilled chicken plate'], '420 cal per 350g plate. Grilled chicken with rice, side salad.', 'Taziki''s', 'mediterranean', 1),

-- Lamb Burger: 580 cal, 32g protein, 38g carbs, 32g fat per 280g
('tazikis_lamb_burger', 'Taziki''s Lamb Burger', 207.1, 11.4, 13.6, 11.4, 1.0, 2.5, 280, 280, 'tazikiscafe.com', ARRAY['tazikis lamb burger'], '580 cal per burger (280g). Ground lamb with feta, tzatziki on bun.', 'Taziki''s', 'mediterranean', 1),

-- Gyro Plate: 520 cal, 28g protein, 42g carbs, 26g fat per 380g
('tazikis_gyro_plate', 'Taziki''s Gyro Plate', 136.8, 7.4, 11.1, 6.8, 1.0, 2.0, NULL, 380, 'tazikiscafe.com', ARRAY['tazikis gyro', 'tazikis lamb gyro'], '520 cal per 380g plate. Lamb-beef gyro with pita, veggies, tzatziki.', 'Taziki''s', 'mediterranean', 1),

-- Grilled Salmon: 480 cal, 35g protein, 28g carbs, 24g fat per 350g
('tazikis_grilled_salmon', 'Taziki''s Grilled Salmon', 137.1, 10.0, 8.0, 6.9, 1.0, 1.0, NULL, 350, 'tazikiscafe.com', ARRAY['tazikis salmon', 'tazikis salmon plate'], '480 cal per 350g plate. Grilled Atlantic salmon with rice pilaf, salad.', 'Taziki''s', 'mediterranean', 1),

-- Hummus Dip: 280 cal, 10g protein, 28g carbs, 14g fat per 170g
('tazikis_hummus', 'Taziki''s Hummus', 164.7, 5.9, 16.5, 8.2, 3.0, 1.0, NULL, 170, 'tazikiscafe.com', ARRAY['tazikis hummus dip'], '280 cal per 170g serving with pita.', 'Taziki''s', 'mediterranean', 1),

-- Greek Salad: 280 cal, 8g protein, 14g carbs, 22g fat per 250g
('tazikis_greek_salad', 'Taziki''s Greek Salad', 112.0, 3.2, 5.6, 8.8, 2.0, 3.0, NULL, 250, 'tazikiscafe.com', ARRAY['tazikis salad', 'tazikis greek salad'], '280 cal per 250g serving.', 'Taziki''s', 'salads', 1),

-- ============================================================================
-- 2. THE GREAT GREEK MEDITERRANEAN GRILL (~54 US locations)
-- Source: thegreatgreekgrill.com, nutritionix.com
-- ============================================================================

-- Chicken Souvlaki Plate: 480 cal, 36g protein, 38g carbs, 20g fat per 380g
('great_greek_chicken_souvlaki', 'Great Greek Chicken Souvlaki Plate', 126.3, 9.5, 10.0, 5.3, 1.0, 1.5, NULL, 380, 'thegreatgreekgrill.com', ARRAY['great greek chicken', 'great greek souvlaki'], '480 cal per 380g plate. Grilled chicken skewers with rice, salad, pita.', 'The Great Greek', 'mediterranean', 1),

-- Lamb Chops: 550 cal, 38g protein, 28g carbs, 30g fat per 350g
('great_greek_lamb_chops', 'Great Greek Lamb Chops', 157.1, 10.9, 8.0, 8.6, 0.5, 1.0, NULL, 350, 'thegreatgreekgrill.com', ARRAY['great greek lamb'], '550 cal per 350g plate. Grilled lamb chops with sides.', 'The Great Greek', 'mediterranean', 1),

-- Gyro Wrap: 580 cal, 25g protein, 48g carbs, 32g fat per 350g
('great_greek_gyro_wrap', 'Great Greek Gyro Wrap', 165.7, 7.1, 13.7, 9.1, 1.0, 2.0, 350, 350, 'thegreatgreekgrill.com', ARRAY['great greek gyro', 'great greek gyro wrap'], '580 cal per 350g wrap. Lamb-beef gyro in warm pita.', 'The Great Greek', 'mediterranean', 1),

-- Falafel Plate: 450 cal, 14g protein, 48g carbs, 22g fat per 350g
('great_greek_falafel', 'Great Greek Falafel Plate', 128.6, 4.0, 13.7, 6.3, 3.0, 1.5, NULL, 350, 'thegreatgreekgrill.com', ARRAY['great greek falafel'], '450 cal per 350g plate. Crispy chickpea falafel with hummus, salad, pita.', 'The Great Greek', 'mediterranean', 1),

-- Spanakopita: 320 cal, 10g protein, 24g carbs, 20g fat per 150g
('great_greek_spanakopita', 'Great Greek Spanakopita', 213.3, 6.7, 16.0, 13.3, 1.5, 1.0, 150, 150, 'thegreatgreekgrill.com', ARRAY['great greek spinach pie'], '320 cal per 150g serving. Spinach and feta in phyllo dough.', 'The Great Greek', 'mediterranean', 1),

-- Baklava: 280 cal, 4g protein, 34g carbs, 15g fat per 80g
('great_greek_baklava', 'Great Greek Baklava', 350.0, 5.0, 42.5, 18.8, 1.5, 25.0, 80, 80, 'thegreatgreekgrill.com', ARRAY['great greek baklava dessert'], '280 cal per piece (80g). Layers of phyllo, nuts, honey syrup.', 'The Great Greek', 'desserts', 1),

-- ============================================================================
-- 3. LUNA GRILL (~55 US locations)
-- Source: lunagrill.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Chicken Kebab Plate: 520 cal, 40g protein, 42g carbs, 20g fat per 400g
('luna_grill_chicken_kebab', 'Luna Grill Chicken Kebab Plate', 130.0, 10.0, 10.5, 5.0, 1.5, 1.0, NULL, 400, 'lunagrill.com', ARRAY['luna grill chicken', 'luna grill chicken kebab'], '520 cal per 400g plate. Grilled chicken with basmati rice, veggies, pita.', 'Luna Grill', 'mediterranean', 1),

-- Lamb Kebab Plate: 580 cal, 35g protein, 42g carbs, 28g fat per 400g
('luna_grill_lamb_kebab', 'Luna Grill Lamb Kebab Plate', 145.0, 8.8, 10.5, 7.0, 1.5, 1.0, NULL, 400, 'lunagrill.com', ARRAY['luna grill lamb', 'luna grill lamb kebab'], '580 cal per 400g plate.', 'Luna Grill', 'mediterranean', 1),

-- Falafel Wrap: 480 cal, 14g protein, 52g carbs, 24g fat per 320g
('luna_grill_falafel_wrap', 'Luna Grill Falafel Wrap', 150.0, 4.4, 16.3, 7.5, 3.0, 2.0, 320, 320, 'lunagrill.com', ARRAY['luna grill falafel', 'luna grill falafel wrap'], '480 cal per 320g wrap.', 'Luna Grill', 'mediterranean', 1),

-- Mediterranean Bowl: 550 cal, 32g protein, 48g carbs, 24g fat per 420g
('luna_grill_med_bowl', 'Luna Grill Mediterranean Bowl', 131.0, 7.6, 11.4, 5.7, 2.0, 2.0, NULL, 420, 'lunagrill.com', ARRAY['luna grill bowl', 'luna grill med bowl'], '550 cal per 420g bowl. Protein, rice, hummus, veggies, tahini.', 'Luna Grill', 'mediterranean', 1),

-- Shawarma Plate: 560 cal, 34g protein, 44g carbs, 26g fat per 400g
('luna_grill_shawarma', 'Luna Grill Chicken Shawarma Plate', 140.0, 8.5, 11.0, 6.5, 1.0, 1.5, NULL, 400, 'lunagrill.com', ARRAY['luna grill shawarma', 'luna grill chicken shawarma'], '560 cal per 400g plate.', 'Luna Grill', 'mediterranean', 1),

-- ============================================================================
-- 4. NAF NAF GRILL (~35 US locations)
-- Source: nafnafgrill.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Chicken Shawarma Plate: 540 cal, 38g protein, 44g carbs, 22g fat per 400g
('naf_naf_chicken_shawarma', 'Naf Naf Chicken Shawarma Plate', 135.0, 9.5, 11.0, 5.5, 1.5, 1.5, NULL, 400, 'nafnafgrill.com', ARRAY['naf naf chicken', 'naf naf shawarma'], '540 cal per 400g plate. Slow-roasted chicken with rice, veggies, pita.', 'Naf Naf Grill', 'mediterranean', 1),

-- Lamb & Beef Shawarma: 620 cal, 32g protein, 44g carbs, 34g fat per 400g
('naf_naf_lamb_beef_shawarma', 'Naf Naf Lamb & Beef Shawarma Plate', 155.0, 8.0, 11.0, 8.5, 1.0, 1.5, NULL, 400, 'nafnafgrill.com', ARRAY['naf naf lamb shawarma', 'naf naf beef shawarma'], '620 cal per 400g plate.', 'Naf Naf Grill', 'mediterranean', 1),

-- Falafel Pita: 480 cal, 15g protein, 54g carbs, 22g fat per 300g
('naf_naf_falafel_pita', 'Naf Naf Falafel Pita', 160.0, 5.0, 18.0, 7.3, 3.0, 2.0, 300, 300, 'nafnafgrill.com', ARRAY['naf naf falafel', 'naf naf falafel wrap'], '480 cal per 300g pita sandwich.', 'Naf Naf Grill', 'mediterranean', 1),

-- Hummus: 240 cal, 8g protein, 24g carbs, 14g fat per 150g
('naf_naf_hummus', 'Naf Naf Hummus', 160.0, 5.3, 16.0, 9.3, 3.0, 0.5, NULL, 150, 'nafnafgrill.com', ARRAY['naf naf hummus side'], '240 cal per 150g serving.', 'Naf Naf Grill', 'mediterranean', 1),

-- Basmati Rice: 220 cal, 4g protein, 46g carbs, 2g fat per 180g
('naf_naf_basmati_rice', 'Naf Naf Basmati Rice', 122.2, 2.2, 25.6, 1.1, 0.5, 0.0, NULL, 180, 'nafnafgrill.com', ARRAY['naf naf rice'], '220 cal per 180g serving.', 'Naf Naf Grill', 'sides', 1),

-- ============================================================================
-- 5. NICK THE GREEK (~80 US locations)
-- Source: nickthegreek.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Chicken Gyro Wrap: 520 cal, 30g protein, 42g carbs, 24g fat per 320g
('nick_greek_chicken_gyro', 'Nick the Greek Chicken Gyro', 162.5, 9.4, 13.1, 7.5, 1.0, 2.0, 320, 320, 'nickthegreek.com', ARRAY['nick the greek chicken gyro', 'nick greek chicken'], '520 cal per 320g wrap.', 'Nick the Greek', 'mediterranean', 1),

-- Lamb Gyro Wrap: 580 cal, 26g protein, 42g carbs, 34g fat per 330g
('nick_greek_lamb_gyro', 'Nick the Greek Lamb Gyro', 175.8, 7.9, 12.7, 10.3, 1.0, 2.0, 330, 330, 'nickthegreek.com', ARRAY['nick the greek lamb gyro', 'nick greek lamb'], '580 cal per 330g wrap.', 'Nick the Greek', 'mediterranean', 1),

-- Greek Fries: 420 cal, 8g protein, 48g carbs, 22g fat per 250g
('nick_greek_fries', 'Nick the Greek Greek Fries', 168.0, 3.2, 19.2, 8.8, 2.0, 1.0, NULL, 250, 'nickthegreek.com', ARRAY['nick the greek fries', 'nick greek fries'], '420 cal per 250g serving. Seasoned fries with feta, oregano.', 'Nick the Greek', 'sides', 1),

-- Souvlaki Plate: 560 cal, 36g protein, 44g carbs, 24g fat per 400g
('nick_greek_souvlaki_plate', 'Nick the Greek Souvlaki Plate', 140.0, 9.0, 11.0, 6.0, 1.5, 1.0, NULL, 400, 'nickthegreek.com', ARRAY['nick the greek souvlaki', 'nick greek souvlaki'], '560 cal per 400g plate. Grilled meat skewers with rice, pita, salad.', 'Nick the Greek', 'mediterranean', 1),

-- Falafel Plate: 480 cal, 16g protein, 52g carbs, 22g fat per 380g
('nick_greek_falafel_plate', 'Nick the Greek Falafel Plate', 126.3, 4.2, 13.7, 5.8, 3.5, 1.5, NULL, 380, 'nickthegreek.com', ARRAY['nick the greek falafel', 'nick greek falafel'], '480 cal per 380g plate.', 'Nick the Greek', 'mediterranean', 1)
