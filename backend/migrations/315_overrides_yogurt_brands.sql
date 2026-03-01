-- 315_overrides_yogurt_brands.sql
-- Popular yogurt brand items: Chobani, Fage, Oikos, Yoplait, Siggi's, Two Good, Activia, Noosa.
-- Sources: chobani.com, usa.fage, oikos.com, yoplait.com, siggis.com, heytoogoodandco.com,
--          activia.us.com, noosayoghurt.com, nutritionvalue.org, fatsecret.com, nutritionix.com,
--          eatthismuch.com, myfooddiary.com, USDA FoodData Central

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- =====================================================================
-- CHOBANI - Greek Yogurt (5.3oz / 150g cups)
-- =====================================================================

-- Chobani Plain Nonfat Greek Yogurt: 80 cal / 150g = 53 cal/100g
-- USDA / nutritionvalue.org: 54 cal, 9.5g protein, 3.4g carbs, 0.2g fat per 100g
('chobani_plain', 'Chobani Plain Nonfat Greek Yogurt', 54, 9.5, 3.4, 0.2,
 0.2, 2.4, 150, NULL,
 'chobani', ARRAY['chobani plain', 'chobani plain greek', 'chobani nonfat plain', 'chobani 0 plain'],
 'yogurt', 'Chobani', 1, '54 cal/100g. Cup 150g = 80 cal, 14g protein. Plain nonfat Greek yogurt.', TRUE),

-- Chobani Strawberry Nonfat Greek Yogurt: 120 cal / 150g = 80 cal/100g
-- nutritionvalue.org: 79 cal, 7.3g protein, 12g carbs, 0.2g fat, 0.4g fiber, 10g sugar per 100g
('chobani_strawberry', 'Chobani Strawberry Greek Yogurt', 79, 7.3, 12.0, 0.2,
 0.4, 10.0, 150, NULL,
 'chobani', ARRAY['chobani strawberry', 'chobani strawberry on the bottom', 'chobani strawberry greek'],
 'yogurt', 'Chobani', 1, '79 cal/100g. Cup 150g = 120 cal, 11g protein. Fruit on the bottom nonfat Greek yogurt.', TRUE),

-- Chobani Blueberry Nonfat Greek Yogurt: 120 cal / 150g = 80 cal/100g
-- nutritionvalue.org: 82 cal, 7.2g protein, 13g carbs, 0.2g fat, 0.5g fiber, 10g sugar per 100g
('chobani_blueberry', 'Chobani Blueberry Greek Yogurt', 82, 7.2, 13.0, 0.2,
 0.5, 10.0, 150, NULL,
 'chobani', ARRAY['chobani blueberry', 'chobani blueberry on the bottom', 'chobani blueberry greek'],
 'yogurt', 'Chobani', 1, '82 cal/100g. Cup 150g = 123 cal, 11g protein. Blueberry fruit on the bottom nonfat Greek yogurt.', TRUE),

-- Chobani Vanilla Nonfat Greek Yogurt: 107 cal / 150g = 71 cal/100g
-- nutritionvalue.org: 71 cal, 9.1g protein, 8.1g carbs, 0.2g fat, 0.3g fiber, 7.6g sugar per 100g
('chobani_vanilla', 'Chobani Vanilla Nonfat Greek Yogurt', 71, 9.1, 8.1, 0.2,
 0.3, 7.6, 150, NULL,
 'chobani', ARRAY['chobani vanilla', 'chobani vanilla greek', 'chobani vanilla blended'],
 'yogurt', 'Chobani', 1, '71 cal/100g. Cup 150g = 107 cal, 14g protein. Vanilla blended nonfat Greek yogurt.', TRUE),

-- Chobani Peach Nonfat Greek Yogurt: 120 cal / 150g = 80 cal/100g
-- Based on USDA data for Chobani peach nonfat: similar to strawberry profile
('chobani_peach', 'Chobani Peach Greek Yogurt', 80, 7.3, 12.0, 0.2,
 0.4, 10.0, 150, NULL,
 'chobani', ARRAY['chobani peach', 'chobani peach on the bottom', 'chobani peach greek'],
 'yogurt', 'Chobani', 1, '80 cal/100g. Cup 150g = 120 cal, 11g protein. Peach fruit on the bottom nonfat Greek yogurt.', TRUE),

-- Chobani Mango Low-Fat Greek Yogurt: 130 cal / 150g = 87 cal/100g
-- USDA (172199): 93 cal/100g for 2% mango; nonfat ~87 cal/100g from label
('chobani_mango', 'Chobani Mango Greek Yogurt', 87, 7.3, 13.3, 1.0,
 0.3, 11.0, 150, NULL,
 'chobani', ARRAY['chobani mango', 'chobani mango on the bottom', 'chobani mango greek'],
 'yogurt', 'Chobani', 1, '87 cal/100g. Cup 150g = 130 cal, 11g protein. Mango on the bottom low-fat Greek yogurt.', TRUE),

-- Chobani Key Lime Blended Greek Yogurt: 140 cal / 150g = 93 cal/100g
-- myfooddata, mynetdiary: 140 cal, 11g protein, 17g carbs, 2.5g fat per 150g
('chobani_key_lime', 'Chobani Key Lime Greek Yogurt', 93, 7.3, 11.3, 1.7,
 0.2, 9.3, 150, NULL,
 'chobani', ARRAY['chobani key lime', 'chobani key lime blended', 'chobani key lime greek'],
 'yogurt', 'Chobani', 1, '93 cal/100g. Cup 150g = 140 cal, 11g protein. Key lime blended low-fat Greek yogurt.', TRUE),

-- Chobani Flip Almond Coco Loco: 230 cal / 150g = 153 cal/100g
-- eatthismuch, fatsecret: 230 cal, 12g protein, 23g carbs, 10g fat per 150g container
('chobani_flip_almond_coco_loco', 'Chobani Flip Almond Coco Loco', 153, 8.0, 15.3, 6.7,
 0.7, 11.3, 150, NULL,
 'chobani', ARRAY['chobani flip almond coco loco', 'chobani flip coconut', 'chobani almond coco loco'],
 'yogurt', 'Chobani', 1, '153 cal/100g. Cup 150g = 230 cal, 12g protein. Low-fat Greek yogurt with dark chocolate, almonds, coconut.', TRUE),

-- Chobani Flip Cookie Dough: 190 cal / 150g = 127 cal/100g
-- fatsecret, myfooddiary: 190 cal, 12g protein, 24g carbs, 5g fat per 150g
('chobani_flip_cookie_dough', 'Chobani Flip Cookie Dough', 127, 8.0, 16.0, 3.3,
 0.3, 12.0, 150, NULL,
 'chobani', ARRAY['chobani flip cookie dough', 'chobani cookie dough', 'chobani flip chocolate cookie dough'],
 'yogurt', 'Chobani', 1, '127 cal/100g. Cup 150g = 190 cal, 12g protein. Low-fat Greek yogurt with cookie dough pieces, choc chips.', TRUE),

-- Chobani Zero Sugar Vanilla: 60 cal / 150g = 40 cal/100g
-- chobani.com, fatsecret: 60 cal, 10g protein, 5g carbs, 0g fat, 0g sugar per 150g
('chobani_zero_sugar_vanilla', 'Chobani Zero Sugar Vanilla Greek Yogurt', 40, 6.7, 3.3, 0.0,
 0.7, 0.0, 150, NULL,
 'chobani', ARRAY['chobani zero sugar vanilla', 'chobani less sugar vanilla', 'chobani no sugar vanilla'],
 'yogurt', 'Chobani', 1, '40 cal/100g. Cup 150g = 60 cal, 10g protein. Zero sugar nonfat Greek yogurt, lactose-free.', TRUE),

-- =====================================================================
-- FAGE - Greek Yogurt (5.3oz / 150g cups)
-- =====================================================================

-- Fage Total 0% Plain: 80 cal / 150g = 53 cal/100g
-- usa.fage, fatsecret: 80 cal, 16g protein, 5g carbs, 0g fat, 5g sugar per 150g
('fage_total_0_plain', 'Fage Total 0% Plain Greek Yogurt', 53, 10.7, 3.3, 0.0,
 0.0, 3.3, 150, NULL,
 'fage', ARRAY['fage 0', 'fage total 0', 'fage nonfat', 'fage plain nonfat', 'fage total 0 percent'],
 'yogurt', 'Fage', 1, '53 cal/100g. Cup 150g = 80 cal, 16g protein. All-natural nonfat strained Greek yogurt.', TRUE),

-- Fage Total 2% Plain: 100 cal / 150g = 67 cal/100g
-- usa.fage: 100 cal, 15g protein, 5g carbs, 3g fat, 5g sugar per 150g
('fage_total_2_plain', 'Fage Total 2% Plain Greek Yogurt', 67, 10.0, 3.3, 2.0,
 0.0, 3.3, 150, NULL,
 'fage', ARRAY['fage 2', 'fage total 2', 'fage lowfat', 'fage 2 percent', 'fage total 2 percent'],
 'yogurt', 'Fage', 1, '67 cal/100g. Cup 150g = 100 cal, 15g protein. Reduced fat 2% strained Greek yogurt.', TRUE),

-- Fage Total 5% Plain: 140 cal / 150g = 93 cal/100g
-- usa.fage: 140 cal, 14g protein, 5g carbs, 8g fat, 5g sugar per 150g
('fage_total_5_plain', 'Fage Total 5% Plain Greek Yogurt', 93, 9.3, 3.3, 5.3,
 0.0, 3.3, 150, NULL,
 'fage', ARRAY['fage 5', 'fage total 5', 'fage whole milk', 'fage full fat', 'fage total 5 percent'],
 'yogurt', 'Fage', 1, '93 cal/100g. Cup 150g = 140 cal, 14g protein. Whole milk 5% strained Greek yogurt.', TRUE),

-- Fage Total 0% Honey Split Cup: 150g cup total ~120 cal
-- home.fage: 104 cal per 150g (78% yogurt + 22% honey), 8.1g protein, 18g carbs, 0g fat, 18g sugar
('fage_total_0_honey', 'Fage Total 0% with Honey Greek Yogurt', 69, 5.4, 12.0, 0.0,
 0.0, 12.0, 150, NULL,
 'fage', ARRAY['fage 0 honey', 'fage honey split cup', 'fage total 0 honey', 'fage honey nonfat'],
 'yogurt', 'Fage', 1, '69 cal/100g. Cup 150g = 104 cal, 8g protein. Nonfat Greek yogurt with honey side cup.', TRUE),

-- Fage Total 0% Strawberry Split Cup: 150g
-- home.fage: 67 cal per 150g, 8.3g protein, 8.4g carbs, 0g fat, 7.6g sugar
('fage_total_0_strawberry', 'Fage Total 0% Strawberry Greek Yogurt', 45, 5.5, 5.6, 0.0,
 0.3, 5.1, 150, NULL,
 'fage', ARRAY['fage 0 strawberry', 'fage strawberry split cup', 'fage total 0 strawberry'],
 'yogurt', 'Fage', 1, '45 cal/100g. Cup 150g = 67 cal, 8g protein. Nonfat Greek yogurt with strawberry side cup.', TRUE),

-- Fage Total 0% Blueberry Split Cup: 150g, similar profile to strawberry
-- home.fage: ~70 cal per 150g, ~8g protein, ~9g carbs, 0g fat, ~7.5g sugar
('fage_total_0_blueberry', 'Fage Total 0% Blueberry Greek Yogurt', 47, 5.3, 6.0, 0.0,
 0.3, 5.0, 150, NULL,
 'fage', ARRAY['fage 0 blueberry', 'fage blueberry split cup', 'fage total 0 blueberry'],
 'yogurt', 'Fage', 1, '47 cal/100g. Cup 150g = 70 cal, 8g protein. Nonfat Greek yogurt with blueberry side cup.', TRUE),

-- Fage Total 2% Honey Split Cup: 180 cal / 150g = 120 cal/100g
-- usa.fage: 180 cal, 12g protein, 28g carbs, 2.5g fat, 28g sugar per 150g
('fage_total_2_honey', 'Fage Total 2% with Honey Greek Yogurt', 120, 8.0, 18.7, 1.7,
 0.0, 18.7, 150, NULL,
 'fage', ARRAY['fage 2 honey', 'fage total 2 honey', 'fage honey lowfat'],
 'yogurt', 'Fage', 1, '120 cal/100g. Cup 150g = 180 cal, 12g protein. Reduced fat Greek yogurt with honey side cup.', TRUE),

-- Fage Total 2% Strawberry Split Cup: ~130 cal / 150g = 87 cal/100g
-- usa.fage: ~130 cal, 12g protein, 16g carbs, 2.5g fat, 14g sugar per 150g
('fage_total_2_strawberry', 'Fage Total 2% Strawberry Greek Yogurt', 87, 8.0, 10.7, 1.7,
 0.3, 9.3, 150, NULL,
 'fage', ARRAY['fage 2 strawberry', 'fage total 2 strawberry', 'fage strawberry lowfat'],
 'yogurt', 'Fage', 1, '87 cal/100g. Cup 150g = 130 cal, 12g protein. Reduced fat Greek yogurt with strawberry side cup.', TRUE),

-- =====================================================================
-- OIKOS (Dannon) - Greek Yogurt (5.3oz / 150g cups)
-- =====================================================================

-- Oikos Triple Zero Vanilla: 90 cal / 150g = 60 cal/100g
-- oikos.com: 90 cal, 15g protein, 7g carbs, 0g fat, 5g sugar, 0g added sugar per 150g
('oikos_triple_zero_vanilla', 'Oikos Triple Zero Vanilla Greek Yogurt', 60, 10.0, 4.7, 0.0,
 2.0, 3.3, 150, NULL,
 'oikos', ARRAY['oikos triple zero vanilla', 'dannon triple zero vanilla', 'oikos 0 vanilla'],
 'yogurt', 'Oikos', 1, '60 cal/100g. Cup 150g = 90 cal, 15g protein. Nonfat, 0 added sugar, 0 artificial sweeteners.', TRUE),

-- Oikos Triple Zero Strawberry: 90 cal / 150g = 60 cal/100g
-- oikos.com: 90 cal, 15g protein, 7g carbs, 0g fat, 5g sugar per 150g
('oikos_triple_zero_strawberry', 'Oikos Triple Zero Strawberry Greek Yogurt', 60, 10.0, 4.7, 0.0,
 2.0, 3.3, 150, NULL,
 'oikos', ARRAY['oikos triple zero strawberry', 'dannon triple zero strawberry', 'oikos 0 strawberry'],
 'yogurt', 'Oikos', 1, '60 cal/100g. Cup 150g = 90 cal, 15g protein. Nonfat, 0 added sugar, 0 artificial sweeteners.', TRUE),

-- Oikos Triple Zero Mixed Berry: 90 cal / 150g = 60 cal/100g
-- oikos.com: 90 cal, 15g protein, 7g carbs, 0g fat, 5g sugar per 150g
('oikos_triple_zero_mixed_berry', 'Oikos Triple Zero Mixed Berry Greek Yogurt', 60, 10.0, 4.7, 0.0,
 2.0, 3.3, 150, NULL,
 'oikos', ARRAY['oikos triple zero mixed berry', 'dannon triple zero mixed berry', 'oikos 0 mixed berry'],
 'yogurt', 'Oikos', 1, '60 cal/100g. Cup 150g = 90 cal, 15g protein. Nonfat, 0 added sugar, 0 artificial sweeteners.', TRUE),

-- Oikos Pro Vanilla (high protein): ~110 cal / 150g = 73 cal/100g
-- oikos.com, danoneawayfromhome.com: 110 cal, 20g protein, 3g carbs, 1.5g fat, 2g sugar per 150g
('oikos_pro_vanilla', 'Oikos Pro Vanilla High Protein Yogurt', 73, 13.3, 2.0, 1.0,
 0.0, 1.3, 150, NULL,
 'oikos', ARRAY['oikos pro vanilla', 'oikos pro', 'dannon oikos pro vanilla', 'oikos high protein vanilla'],
 'yogurt', 'Oikos', 1, '73 cal/100g. Cup 150g = 110 cal, 20g protein. Ultra-filtered, 0g added sugar, high protein.', TRUE),

-- =====================================================================
-- YOPLAIT
-- =====================================================================

-- Yoplait Original Strawberry: 140 cal / 170g (6oz) = 82 cal/100g
-- yoplait.com: 140 cal, 5g protein, 26g carbs, 1.5g fat, 18g sugar per 170g
('yoplait_original_strawberry', 'Yoplait Original Strawberry Yogurt', 82, 2.9, 15.3, 0.9,
 0.0, 10.6, 170, NULL,
 'yoplait', ARRAY['yoplait strawberry', 'yoplait original strawberry', 'yoplait strawberry yogurt'],
 'yogurt', 'Yoplait', 1, '82 cal/100g. Cup 170g (6oz) = 140 cal, 5g protein. Low-fat yogurt with real strawberry.', TRUE),

-- Yoplait Original French Vanilla: 140 cal / 170g = 82 cal/100g
-- yoplait.com: 140 cal, 5g protein, 26g carbs, 1.5g fat, 18g sugar per 170g
('yoplait_original_french_vanilla', 'Yoplait Original French Vanilla Yogurt', 82, 2.9, 15.3, 0.9,
 0.0, 10.6, 170, NULL,
 'yoplait', ARRAY['yoplait french vanilla', 'yoplait original vanilla', 'yoplait vanilla yogurt'],
 'yogurt', 'Yoplait', 1, '82 cal/100g. Cup 170g (6oz) = 140 cal, 5g protein. Low-fat French vanilla yogurt.', TRUE),

-- Yoplait Light Strawberry: 80 cal / 170g = 47 cal/100g
-- yoplait.com: 80 cal, 5g protein, 14g carbs, 0g fat, 8g sugar per 170g
('yoplait_light_strawberry', 'Yoplait Light Strawberry Yogurt', 47, 2.9, 8.2, 0.0,
 0.0, 4.7, 170, NULL,
 'yoplait', ARRAY['yoplait light strawberry', 'yoplait light', 'yoplait fat free strawberry'],
 'yogurt', 'Yoplait', 1, '47 cal/100g. Cup 170g (6oz) = 80 cal, 5g protein. Fat-free, 1g added sugar.', TRUE),

-- Yoplait Light Vanilla: 80 cal / 170g = 47 cal/100g
-- yoplait.com: 80 cal, 5g protein, 14g carbs, 0g fat, 8g sugar per 170g
('yoplait_light_vanilla', 'Yoplait Light Vanilla Yogurt', 47, 2.9, 8.2, 0.0,
 0.0, 4.7, 170, NULL,
 'yoplait', ARRAY['yoplait light vanilla', 'yoplait light french vanilla', 'yoplait fat free vanilla'],
 'yogurt', 'Yoplait', 1, '47 cal/100g. Cup 170g (6oz) = 80 cal, 5g protein. Fat-free light vanilla yogurt.', TRUE),

-- Yoplait Go-GURT Strawberry (kids tube): 50 cal / 64g = 78 cal/100g
-- yoplait.com, nutritionvalue.org: 50 cal, 2g protein, 9g carbs, 1g fat, 6g sugar per 64g tube
('yoplait_gogurt', 'Yoplait Go-GURT Kids Yogurt Tube', 78, 3.1, 14.1, 1.6,
 0.0, 9.4, 64, 64,
 'yoplait', ARRAY['gogurt', 'go-gurt', 'yoplait gogurt', 'yoplait go gurt', 'gogurt tube', 'go gurt strawberry'],
 'yogurt', 'Yoplait', 1, '78 cal/100g. Tube 64g = 50 cal, 2g protein. Kids portable low-fat yogurt tube.', TRUE),

-- =====================================================================
-- SIGGI'S - Icelandic Skyr (5.3oz / 150g cups)
-- =====================================================================

-- Siggi's Plain 0%: 90 cal / 150g = 60 cal/100g
-- siggis.com: 90 cal, 16g protein, 6g carbs, 0g fat, 4g sugar per 150g
('siggis_plain', 'Siggi''s Plain 0% Nonfat Icelandic Skyr', 60, 10.7, 4.0, 0.0,
 0.0, 2.7, 150, NULL,
 'siggis', ARRAY['siggis plain', 'siggi''s plain', 'siggis nonfat plain', 'siggi''s skyr plain'],
 'yogurt', 'Siggi''s', 1, '60 cal/100g. Cup 150g = 90 cal, 16g protein. Simple ingredients, no added sugar, Icelandic skyr.', TRUE),

-- Siggi's Vanilla 0%: 110 cal / 150g = 73 cal/100g
-- siggis.com, target.com: 110 cal, 15g protein, 11g carbs, 0g fat, 9g sugar per 150g
('siggis_vanilla', 'Siggi''s Vanilla Nonfat Icelandic Skyr', 73, 10.0, 7.3, 0.0,
 0.0, 6.0, 150, NULL,
 'siggis', ARRAY['siggis vanilla', 'siggi''s vanilla', 'siggis nonfat vanilla', 'siggi''s skyr vanilla'],
 'yogurt', 'Siggi''s', 1, '73 cal/100g. Cup 150g = 110 cal, 15g protein. Icelandic skyr with Madagascar vanilla.', TRUE),

-- Siggi's Strawberry 0%: 120 cal / 150g = 80 cal/100g
-- siggis.com, target.com: 120 cal, 15g protein, 13g carbs, 0g fat, 11g sugar per 150g
('siggis_strawberry', 'Siggi''s Strawberry Nonfat Icelandic Skyr', 80, 10.0, 8.7, 0.0,
 0.3, 7.3, 150, NULL,
 'siggis', ARRAY['siggis strawberry', 'siggi''s strawberry', 'siggis nonfat strawberry', 'siggi''s skyr strawberry'],
 'yogurt', 'Siggi''s', 1, '80 cal/100g. Cup 150g = 120 cal, 15g protein. Icelandic skyr with real strawberries.', TRUE),

-- Siggi's Blueberry 0%: 120 cal / 150g = 80 cal/100g
-- siggis.com, myfooddiary.com: 120 cal, 15g protein, 12g carbs, 0g fat, 10g sugar per 150g
('siggis_blueberry', 'Siggi''s Blueberry Nonfat Icelandic Skyr', 80, 10.0, 8.0, 0.0,
 0.3, 6.7, 150, NULL,
 'siggis', ARRAY['siggis blueberry', 'siggi''s blueberry', 'siggis nonfat blueberry', 'siggi''s skyr blueberry'],
 'yogurt', 'Siggi''s', 1, '80 cal/100g. Cup 150g = 120 cal, 15g protein. Icelandic skyr with real blueberries.', TRUE),

-- =====================================================================
-- TWO GOOD (by Dannon) - Low Sugar Greek Yogurt (5.3oz / 150g cups)
-- =====================================================================

-- Two Good Vanilla: 80 cal / 150g = 53 cal/100g
-- heytoogoodandco.com, fatsecret: 80 cal, 12g protein, 4g carbs, 2g fat, 2g sugar per 150g
('two_good_vanilla', 'Two Good Vanilla Greek Yogurt', 53, 8.0, 2.7, 1.3,
 0.0, 1.3, 150, NULL,
 'two_good', ARRAY['two good vanilla', 'too good vanilla', 'two good vanilla yogurt', 'too good and co vanilla'],
 'yogurt', 'Two Good', 1, '53 cal/100g. Cup 150g = 80 cal, 12g protein. Low sugar, 2g total sugar, 0g added sugar.', TRUE),

-- Two Good Strawberry: 80 cal / 150g = 53 cal/100g
-- danoneawayfromhome.com: 80 cal, 12g protein, 4g carbs, 2g fat, 2g sugar per 150g
('two_good_strawberry', 'Two Good Strawberry Greek Yogurt', 53, 8.0, 2.7, 1.3,
 0.0, 1.3, 150, NULL,
 'two_good', ARRAY['two good strawberry', 'too good strawberry', 'two good strawberry yogurt'],
 'yogurt', 'Two Good', 1, '53 cal/100g. Cup 150g = 80 cal, 12g protein. Low sugar, 2g total sugar, 0g added sugar.', TRUE),

-- Two Good Mixed Berry: 80 cal / 150g = 53 cal/100g
-- Same macro profile as other Two Good flavors
('two_good_mixed_berry', 'Two Good Mixed Berry Greek Yogurt', 53, 8.0, 2.7, 1.3,
 0.0, 1.3, 150, NULL,
 'two_good', ARRAY['two good mixed berry', 'too good mixed berry', 'two good berry yogurt'],
 'yogurt', 'Two Good', 1, '53 cal/100g. Cup 150g = 80 cal, 12g protein. Low sugar, 2g total sugar, 0g added sugar.', TRUE),

-- Two Good Peach: 80 cal / 150g = 53 cal/100g
('two_good_peach', 'Two Good Peach Greek Yogurt', 53, 8.0, 2.7, 1.3,
 0.0, 1.3, 150, NULL,
 'two_good', ARRAY['two good peach', 'too good peach', 'two good peach yogurt'],
 'yogurt', 'Two Good', 1, '53 cal/100g. Cup 150g = 80 cal, 12g protein. Low sugar, 2g total sugar, 0g added sugar.', TRUE),

-- =====================================================================
-- ACTIVIA (Dannon) - Probiotic Yogurt
-- =====================================================================

-- Activia Strawberry: 90 cal / 113g (4oz) = 80 cal/100g
-- activia.us.com, danoneawayfromhome: 90 cal, 4g protein, 15g carbs, 1.5g fat, 12g sugar per 113g
('activia_strawberry', 'Activia Strawberry Probiotic Yogurt', 80, 3.5, 13.3, 1.3,
 0.0, 10.6, 113, NULL,
 'activia', ARRAY['activia strawberry', 'dannon activia strawberry', 'activia probiotic strawberry'],
 'yogurt', 'Activia', 1, '80 cal/100g. Cup 113g (4oz) = 90 cal, 4g protein. Low-fat probiotic yogurt with B. lactis.', TRUE),

-- Activia Vanilla: 90 cal / 113g (4oz) = 80 cal/100g
-- activia.us.com, eatthismuch.com: 90 cal, 4g protein, 15g carbs, 1.5g fat, 12g sugar per 113g
('activia_vanilla', 'Activia Vanilla Probiotic Yogurt', 80, 3.5, 13.3, 1.3,
 0.0, 10.6, 113, NULL,
 'activia', ARRAY['activia vanilla', 'dannon activia vanilla', 'activia probiotic vanilla'],
 'yogurt', 'Activia', 1, '80 cal/100g. Cup 113g (4oz) = 90 cal, 4g protein. Low-fat probiotic yogurt with B. lactis.', TRUE),

-- Activia Probiotic Dailies (drinkable): 70 cal / 93ml (~93g) = 75 cal/100g
-- activia.us.com, walmart: 70 cal, 3g protein, 11g carbs, 1.5g fat, 10g sugar per 3.1 fl oz (93ml)
('activia_dailies', 'Activia Probiotic Dailies Yogurt Drink', 75, 3.2, 11.8, 1.6,
 0.0, 10.8, 93, 93,
 'activia', ARRAY['activia dailies', 'activia probiotic dailies', 'activia drinkable yogurt', 'activia drink', 'activia shot'],
 'yogurt', 'Activia', 1, '75 cal/100g. Bottle 93g (3.1 fl oz) = 70 cal, 3g protein. Daily probiotic low-fat yogurt drink.', TRUE),

-- =====================================================================
-- NOOSA - Australian-style Yoghurt (8oz / 227g tubs)
-- =====================================================================

-- Noosa Honey: 290 cal / 227g = 128 cal/100g
-- noosayoghurt.com, eatthismuch.com: 290 cal, 13g protein, 33g carbs, 12g fat, 30g sugar per 227g
('noosa_honey', 'Noosa Honey Yoghurt', 128, 5.7, 14.5, 5.3,
 0.0, 13.2, 227, NULL,
 'noosa', ARRAY['noosa honey', 'noosa honey yogurt', 'noosa honey yoghurt', 'noosa australian honey'],
 'yogurt', 'Noosa', 1, '128 cal/100g. Tub 227g (8oz) = 290 cal, 13g protein. Whole milk Australian-style yoghurt with honey.', TRUE),

-- Noosa Strawberry Rhubarb: 280 cal / 227g = 123 cal/100g
-- noosayoghurt.com, fatsecret: 280 cal, 12g protein, 34g carbs, 11g fat, 30g sugar per 227g
('noosa_strawberry_rhubarb', 'Noosa Strawberry Rhubarb Yoghurt', 123, 5.3, 15.0, 4.8,
 0.4, 13.2, 227, NULL,
 'noosa', ARRAY['noosa strawberry rhubarb', 'noosa strawberry', 'noosa strawberry rhubarb yogurt'],
 'yogurt', 'Noosa', 1, '123 cal/100g. Tub 227g (8oz) = 280 cal, 12g protein. Whole milk Australian-style yoghurt.', TRUE),

-- Noosa Lemon: 320 cal / 227g = 141 cal/100g
-- noosayoghurt.com, fatsecret: 320 cal, 11g protein, 39g carbs, 13g fat, 35g sugar per 227g
('noosa_lemon', 'Noosa Lemon Yoghurt', 141, 4.8, 17.2, 5.7,
 0.0, 15.4, 227, NULL,
 'noosa', ARRAY['noosa lemon', 'noosa lemon yogurt', 'noosa lemon yoghurt', 'noosa lemon curd'],
 'yogurt', 'Noosa', 1, '141 cal/100g. Tub 227g (8oz) = 320 cal, 11g protein. Whole milk Australian-style yoghurt with lemon curd.', TRUE)

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
