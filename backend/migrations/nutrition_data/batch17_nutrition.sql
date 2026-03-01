-- ============================================================================
-- Batch 17: Hawaiian & Filipino Restaurant Chains
-- Restaurants: L&L Hawaiian BBQ, Ono Hawaiian BBQ, Zippy's, Red Ribbon, Chowking, Max's
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. L&L HAWAIIAN BARBECUE (~220 US locations)
-- Source: hawaiianbarbecue.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- BBQ Chicken Plate: 680 cal, 38g protein, 72g carbs, 22g fat per 500g
('ll_bbq_chicken', 'L&L BBQ Chicken Plate', 136.0, 7.6, 14.4, 4.4, 0.5, 5.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l bbq chicken', 'l&l chicken plate', 'll hawaiian chicken'], '680 cal per plate (500g). Grilled chicken with 2 scoops rice, macaroni salad.', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- Chicken Katsu Plate: 850 cal, 35g protein, 82g carbs, 40g fat per 500g
('ll_chicken_katsu', 'L&L Chicken Katsu Plate', 170.0, 7.0, 16.4, 8.0, 0.5, 2.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l chicken katsu', 'l&l katsu', 'll katsu plate'], '850 cal per plate (500g). Breaded fried chicken cutlet with rice, mac salad.', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- Kalua Pig Plate: 720 cal, 34g protein, 72g carbs, 30g fat per 500g
('ll_kalua_pig', 'L&L Kalua Pig Plate', 144.0, 6.8, 14.4, 6.0, 0.5, 1.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l kalua pork', 'l&l kalua pig', 'll kalua plate'], '720 cal per plate (500g). Slow-smoked shredded pork with cabbage.', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- Loco Moco: 780 cal, 32g protein, 68g carbs, 40g fat per 480g
('ll_loco_moco', 'L&L Loco Moco', 162.5, 6.7, 14.2, 8.3, 0.5, 1.5, NULL, 480, 'hawaiianbarbecue.com', ARRAY['l and l loco moco', 'l&l loco moco', 'll loco moco'], '780 cal per plate (480g). Hamburger patty over rice with egg and gravy.', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- Spam Musubi: 280 cal, 10g protein, 40g carbs, 8g fat per 160g
('ll_spam_musubi', 'L&L Spam Musubi', 175.0, 6.3, 25.0, 5.0, 0.3, 2.0, 160, 160, 'hawaiianbarbecue.com', ARRAY['l and l spam musubi', 'l&l musubi', 'll spam musubi'], '280 cal per musubi (160g).', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- Beef Short Ribs Plate: 820 cal, 36g protein, 72g carbs, 40g fat per 500g
('ll_short_ribs', 'L&L Hawaiian BBQ Short Ribs Plate', 164.0, 7.2, 14.4, 8.0, 0.3, 3.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l short ribs', 'l&l beef ribs', 'll kalbi ribs'], '820 cal per plate (500g). Korean-style marinated short ribs with rice.', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- Macaroni Salad (side): 280 cal, 4g protein, 22g carbs, 20g fat per 150g
('ll_mac_salad', 'L&L Macaroni Salad', 186.7, 2.7, 14.7, 13.3, 0.5, 2.0, NULL, 150, 'hawaiianbarbecue.com', ARRAY['l and l mac salad', 'l&l macaroni salad', 'll mac salad'], '280 cal per scoop (150g).', 'L&L Hawaiian BBQ', 'sides', 1),

-- Garlic Shrimp Plate: 750 cal, 30g protein, 74g carbs, 34g fat per 480g
('ll_garlic_shrimp', 'L&L Garlic Shrimp Plate', 156.3, 6.3, 15.4, 7.1, 0.3, 1.5, NULL, 480, 'hawaiianbarbecue.com', ARRAY['l and l garlic shrimp', 'l&l shrimp plate', 'll garlic shrimp'], '750 cal per plate (480g).', 'L&L Hawaiian BBQ', 'hawaiian', 1),

-- ============================================================================
-- 2. ONO HAWAIIAN BBQ (~100 US locations)
-- Source: onohawaiianbbq.com, nutritionix.com
-- ============================================================================

-- Chicken Katsu Plate: 820 cal, 32g protein, 80g carbs, 38g fat per 500g
('ono_chicken_katsu', 'Ono Hawaiian BBQ Chicken Katsu', 164.0, 6.4, 16.0, 7.6, 0.5, 2.0, NULL, 500, 'onohawaiianbbq.com', ARRAY['ono chicken katsu', 'ono katsu plate'], '820 cal per plate (500g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),

-- BBQ Mix Plate: 900 cal, 42g protein, 74g carbs, 44g fat per 550g
('ono_bbq_mix', 'Ono Hawaiian BBQ Mix Plate', 163.6, 7.6, 13.5, 8.0, 0.5, 3.0, NULL, 550, 'onohawaiianbbq.com', ARRAY['ono mix plate', 'ono bbq combo'], '900 cal per plate (550g). Combo of chicken, beef, and shrimp.', 'Ono Hawaiian BBQ', 'hawaiian', 1),

-- Kalbi Short Ribs Plate: 840 cal, 36g protein, 72g carbs, 42g fat per 500g
('ono_kalbi_ribs', 'Ono Hawaiian BBQ Kalbi Short Ribs', 168.0, 7.2, 14.4, 8.4, 0.3, 4.0, NULL, 500, 'onohawaiianbbq.com', ARRAY['ono kalbi', 'ono short ribs', 'ono kalbi plate'], '840 cal per plate (500g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),

-- Loco Moco: 750 cal, 30g protein, 66g carbs, 38g fat per 470g
('ono_loco_moco', 'Ono Hawaiian BBQ Loco Moco', 159.6, 6.4, 14.0, 8.1, 0.5, 1.5, NULL, 470, 'onohawaiianbbq.com', ARRAY['ono loco moco'], '750 cal per plate (470g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),

-- Spam Musubi: 260 cal, 9g protein, 38g carbs, 7g fat per 155g
('ono_spam_musubi', 'Ono Hawaiian BBQ Spam Musubi', 167.7, 5.8, 24.5, 4.5, 0.3, 1.5, 155, 155, 'onohawaiianbbq.com', ARRAY['ono spam musubi', 'ono musubi'], '260 cal per musubi (155g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),

-- ============================================================================
-- 3. ZIPPY'S (~24 HI + 1 LV locations)
-- Source: zippys.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Zip Pac (Fried Chicken): 780 cal, 34g protein, 72g carbs, 36g fat per 480g
('zippys_zip_pac_chicken', 'Zippy''s Zip Pac Fried Chicken', 162.5, 7.1, 15.0, 7.5, 0.5, 2.0, NULL, 480, 'zippys.com', ARRAY['zippys fried chicken plate', 'zippys zip pac'], '780 cal per plate (480g). Fried chicken with rice, mac salad.', 'Zippy''s', 'hawaiian', 1),

-- Chili: 280 cal, 18g protein, 24g carbs, 12g fat per 250g
('zippys_chili', 'Zippy''s Chili', 112.0, 7.2, 9.6, 4.8, 3.0, 2.0, NULL, 250, 'zippys.com', ARRAY['zippys famous chili', 'zippys chili bowl'], '280 cal per bowl (250g). Famous Zippy''s chili.', 'Zippy''s', 'soups', 1),

-- Korean Fried Chicken Plate: 850 cal, 36g protein, 78g carbs, 40g fat per 500g
('zippys_korean_chicken', 'Zippy''s Korean Fried Chicken Plate', 170.0, 7.2, 15.6, 8.0, 0.5, 4.0, NULL, 500, 'zippys.com', ARRAY['zippys korean chicken'], '850 cal per plate (500g).', 'Zippy''s', 'hawaiian', 1),

-- Oxtail Soup: 320 cal, 22g protein, 18g carbs, 18g fat per 400g
('zippys_oxtail_soup', 'Zippy''s Oxtail Soup', 80.0, 5.5, 4.5, 4.5, 0.5, 1.0, NULL, 400, 'zippys.com', ARRAY['zippys oxtail', 'zippys oxtail stew'], '320 cal per bowl (400g).', 'Zippy''s', 'soups', 1),

-- Hamburger Steak Plate: 720 cal, 30g protein, 68g carbs, 34g fat per 480g
('zippys_hamburger_steak', 'Zippy''s Hamburger Steak Plate', 150.0, 6.3, 14.2, 7.1, 0.5, 2.0, NULL, 480, 'zippys.com', ARRAY['zippys hamburger steak', 'zippys hamburgah steak'], '720 cal per plate (480g). With gravy, rice, mac salad.', 'Zippy''s', 'hawaiian', 1),

-- ============================================================================
-- 4. RED RIBBON BAKESHOP (~30 US locations)
-- Source: redribbonbakeshop.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Chicken Empanada: 280 cal, 10g protein, 28g carbs, 14g fat per 110g
('red_ribbon_chicken_empanada', 'Red Ribbon Chicken Empanada', 254.5, 9.1, 25.5, 12.7, 1.0, 1.5, 110, 110, 'redribbonbakeshop.com', ARRAY['red ribbon empanada', 'red ribbon chicken pie'], '280 cal per empanada (110g).', 'Red Ribbon', 'filipino', 1),

-- Mango Cake (slice): 380 cal, 5g protein, 48g carbs, 20g fat per 130g
('red_ribbon_mango_cake', 'Red Ribbon Mango Cake', 292.3, 3.8, 36.9, 15.4, 0.5, 28.0, 130, 130, 'redribbonbakeshop.com', ARRAY['red ribbon mango cake slice', 'red ribbon mango supreme'], '380 cal per slice (130g). Signature mango chiffon cake.', 'Red Ribbon', 'desserts', 1),

-- Ube Cake (slice): 350 cal, 4g protein, 44g carbs, 18g fat per 120g
('red_ribbon_ube_cake', 'Red Ribbon Ube Cake', 291.7, 3.3, 36.7, 15.0, 0.5, 26.0, 120, 120, 'redribbonbakeshop.com', ARRAY['red ribbon ube cake slice', 'red ribbon purple yam cake'], '350 cal per slice (120g). Purple yam (ube) layer cake.', 'Red Ribbon', 'desserts', 1),

-- Palabok Fiesta: 420 cal, 15g protein, 52g carbs, 16g fat per 350g
('red_ribbon_palabok', 'Red Ribbon Palabok Fiesta', 120.0, 4.3, 14.9, 4.6, 0.5, 1.0, NULL, 350, 'redribbonbakeshop.com', ARRAY['red ribbon palabok', 'red ribbon noodles'], '420 cal per 350g serving. Filipino rice noodles with shrimp sauce.', 'Red Ribbon', 'filipino', 1),

-- Buko Pandan Salad: 280 cal, 3g protein, 38g carbs, 14g fat per 150g
('red_ribbon_buko_pandan', 'Red Ribbon Buko Pandan', 186.7, 2.0, 25.3, 9.3, 0.5, 18.0, NULL, 150, 'redribbonbakeshop.com', ARRAY['red ribbon buko pandan salad'], '280 cal per 150g serving. Coconut pandan gelatin dessert.', 'Red Ribbon', 'desserts', 1),

-- ============================================================================
-- 5. CHOWKING (~10 US locations)
-- Source: chowking.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Chao Fan (Fried Rice): 380 cal, 12g protein, 50g carbs, 14g fat per 280g
('chowking_chao_fan', 'Chowking Chao Fan', 135.7, 4.3, 17.9, 5.0, 0.5, 1.0, NULL, 280, 'chowking.com', ARRAY['chowking fried rice', 'chowking chao fan'], '380 cal per 280g serving. Chinese-Filipino fried rice.', 'Chowking', 'filipino', 1),

-- Halo-Halo: 340 cal, 5g protein, 62g carbs, 8g fat per 350g
('chowking_halo_halo', 'Chowking Halo-Halo', 97.1, 1.4, 17.7, 2.3, 0.5, 14.0, NULL, 350, 'chowking.com', ARRAY['chowking halo halo', 'chowking haluhalo'], '340 cal per 350g serving. Filipino shaved ice with beans, jellies, ube, leche flan.', 'Chowking', 'desserts', 1),

-- Chicken Lauriat: 680 cal, 30g protein, 72g carbs, 28g fat per 450g
('chowking_chicken_lauriat', 'Chowking Chicken Lauriat', 151.1, 6.7, 16.0, 6.2, 0.5, 2.0, NULL, 450, 'chowking.com', ARRAY['chowking chicken meal', 'chowking fried chicken plate'], '680 cal per 450g plate. Fried chicken with rice, chao fan, siopao.', 'Chowking', 'filipino', 1),

-- Siopao (Asado): 280 cal, 10g protein, 38g carbs, 10g fat per 130g
('chowking_siopao', 'Chowking Siopao Asado', 215.4, 7.7, 29.2, 7.7, 0.5, 4.0, 130, 130, 'chowking.com', ARRAY['chowking siopao', 'chowking steamed bun'], '280 cal per bun (130g). Steamed bun with sweet pork filling.', 'Chowking', 'filipino', 1),

-- ============================================================================
-- 6. MAX'S RESTAURANT (~10 US locations)
-- Source: maxsrestaurant.com, nutritionix.com
-- ============================================================================

-- Whole Fried Chicken (quarter portion): 380 cal, 32g protein, 12g carbs, 22g fat per 220g
('maxs_fried_chicken', 'Max''s Fried Chicken (Quarter)', 172.7, 14.5, 5.5, 10.0, 0.0, 0.5, NULL, 220, 'maxsrestaurant.com', ARRAY['maxs chicken', 'maxs fried chicken', 'max restaurant chicken'], '380 cal per quarter (220g). Signature "sarap to the bones" fried chicken.', 'Max''s Restaurant', 'filipino', 1),

-- Pancit Canton: 350 cal, 12g protein, 46g carbs, 12g fat per 300g
('maxs_pancit_canton', 'Max''s Pancit Canton', 116.7, 4.0, 15.3, 4.0, 1.0, 1.5, NULL, 300, 'maxsrestaurant.com', ARRAY['maxs pancit', 'maxs noodles', 'max restaurant noodles'], '350 cal per 300g serving. Stir-fried egg noodles with vegetables, meat.', 'Max''s Restaurant', 'filipino', 1),

-- Kare-Kare: 420 cal, 22g protein, 18g carbs, 28g fat per 350g
('maxs_kare_kare', 'Max''s Kare-Kare', 120.0, 6.3, 5.1, 8.0, 1.5, 2.0, NULL, 350, 'maxsrestaurant.com', ARRAY['maxs kare kare', 'max restaurant kare kare'], '420 cal per 350g serving. Oxtail stew in peanut sauce with vegetables.', 'Max''s Restaurant', 'filipino', 1),

-- Sinigang na Baboy: 280 cal, 18g protein, 12g carbs, 18g fat per 400g
('maxs_sinigang', 'Max''s Sinigang na Baboy', 70.0, 4.5, 3.0, 4.5, 1.0, 1.5, NULL, 400, 'maxsrestaurant.com', ARRAY['maxs sinigang', 'max restaurant sinigang'], '280 cal per 400g bowl. Sour tamarind pork soup with vegetables.', 'Max''s Restaurant', 'filipino', 1),

-- Leche Flan: 260 cal, 6g protein, 34g carbs, 12g fat per 100g
('maxs_leche_flan', 'Max''s Leche Flan', 260.0, 6.0, 34.0, 12.0, 0.0, 30.0, 100, 100, 'maxsrestaurant.com', ARRAY['maxs flan', 'max restaurant leche flan'], '260 cal per 100g slice. Filipino caramel custard.', 'Max''s Restaurant', 'desserts', 1)
