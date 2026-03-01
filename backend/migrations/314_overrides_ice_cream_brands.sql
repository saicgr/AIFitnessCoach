-- 314_overrides_ice_cream_brands.sql
-- Popular ice cream brand items: Ben & Jerry's, Haagen-Dazs, Talenti,
-- Halo Top, Blue Bell, Breyers, and Magnum bars.
-- Sources: nutritionvalue.org, fatsecret.com, calorieking.com, myfooddiary.com,
--          nutritionix.com, eatthismuch.com, official brand websites/SmartLabel

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════════════════════════════
-- BEN & JERRY'S  (pints, per 2/3 cup ~104-141g serving)
-- ══════════════════════════════════════════════════════════════════

-- Cherry Garcia: 240 cal per 1/2 cup (105g) = ~229 cal/100g
-- Per 105g: 240 cal, 13g fat, 26g carbs, 4g protein, 23g sugar, <1g fiber
('ben_jerrys_cherry_garcia', 'Ben & Jerry''s Cherry Garcia', 229, 3.8, 24.8, 12.4,
 0.5, 21.9, 105, NULL,
 'ben_and_jerrys', ARRAY['bj cherry garcia', 'ben and jerrys cherry garcia', 'cherry garcia ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '229 cal/100g. 2/3 cup (141g) ~323 cal. Cherry ice cream with cherries & fudge flakes.', TRUE),

-- Half Baked: 260 cal per 1/2 cup (105g) = ~248 cal/100g
-- Per 105g: 260 cal, 14g fat, 33g carbs, 4g protein, 25g sugar, 1g fiber
('ben_jerrys_half_baked', 'Ben & Jerry''s Half Baked', 248, 3.8, 31.4, 13.3,
 1.0, 23.8, 105, NULL,
 'ben_and_jerrys', ARRAY['bj half baked', 'ben and jerrys half baked', 'half baked ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '248 cal/100g. 2/3 cup (141g) ~350 cal. Chocolate & vanilla with cookie dough & brownie pieces.', TRUE),

-- Chocolate Fudge Brownie: 260 cal per 1/2 cup (106g) = ~245 cal/100g
-- Per 106g: 260 cal, 13g fat, 33g carbs, 5g protein, 27g sugar, 2g fiber
('ben_jerrys_chocolate_fudge_brownie', 'Ben & Jerry''s Chocolate Fudge Brownie', 245, 4.7, 31.1, 12.3,
 1.9, 25.5, 106, NULL,
 'ben_and_jerrys', ARRAY['bj chocolate fudge brownie', 'ben and jerrys chocolate fudge brownie', 'chocolate fudge brownie ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '245 cal/100g. 2/3 cup (141g) ~345 cal. Chocolate ice cream with fudge brownies.', TRUE),

-- Phish Food: 290 cal per 1/2 cup (107g) = ~271 cal/100g
-- Per 107g: 290 cal, 14g fat, 38g carbs, 4g protein, 32g sugar, 2g fiber
('ben_jerrys_phish_food', 'Ben & Jerry''s Phish Food', 271, 3.7, 35.5, 13.1,
 1.9, 29.9, 107, NULL,
 'ben_and_jerrys', ARRAY['bj phish food', 'ben and jerrys phish food', 'phish food ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '271 cal/100g. 2/3 cup (143g) ~387 cal. Chocolate ice cream with gooey marshmallow, caramel swirl & fudge fish.', TRUE),

-- Tonight Dough: 300 cal per 1/2 cup (108g) = ~278 cal/100g
-- Per 108g: 300 cal, 15g fat, 37g carbs, 5g protein, 28g sugar, 1g fiber
('ben_jerrys_tonight_dough', 'Ben & Jerry''s The Tonight Dough', 278, 4.6, 34.3, 13.9,
 0.9, 25.9, 108, NULL,
 'ben_and_jerrys', ARRAY['bj tonight dough', 'ben and jerrys tonight dough', 'tonight dough ice cream', 'jimmy fallon ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '278 cal/100g. 2/3 cup (144g) ~400 cal. Caramel & chocolate ice creams with cookie dough & peanut butter cookie dough.', TRUE),

-- Americone Dream: 280 cal per 1/2 cup (108g) = ~259 cal/100g
-- Per 108g: 280 cal, 15g fat, 31g carbs, 4g protein, 26g sugar, 0g fiber
('ben_jerrys_americone_dream', 'Ben & Jerry''s Americone Dream', 259, 3.7, 28.7, 13.9,
 0.0, 24.1, 108, NULL,
 'ben_and_jerrys', ARRAY['bj americone dream', 'ben and jerrys americone dream', 'americone dream ice cream', 'stephen colbert ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '259 cal/100g. 2/3 cup (144g) ~373 cal. Vanilla ice cream with fudge-covered waffle cone pieces & caramel swirl.', TRUE),

-- Chocolate Chip Cookie Dough: 270 cal per 1/2 cup (105g) = ~257 cal/100g
-- Per 105g: 270 cal, 14g fat, 32g carbs, 4g protein, 25g sugar, <1g fiber
('ben_jerrys_cookie_dough', 'Ben & Jerry''s Chocolate Chip Cookie Dough', 257, 3.8, 30.5, 13.3,
 0.5, 23.8, 105, NULL,
 'ben_and_jerrys', ARRAY['bj cookie dough', 'ben and jerrys cookie dough', 'cookie dough ice cream', 'chocolate chip cookie dough ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '257 cal/100g. 2/3 cup (140g) ~360 cal. Vanilla ice cream with gobs of chocolate chip cookie dough.', TRUE),

-- Strawberry Cheesecake: 250 cal per 1/2 cup (106g) = ~236 cal/100g
-- Per 106g: 250 cal, 13g fat, 28g carbs, 4g protein, 24g sugar, 0g fiber
('ben_jerrys_strawberry_cheesecake', 'Ben & Jerry''s Strawberry Cheesecake', 236, 3.8, 26.4, 12.3,
 0.0, 22.6, 106, NULL,
 'ben_and_jerrys', ARRAY['bj strawberry cheesecake', 'ben and jerrys strawberry cheesecake', 'strawberry cheesecake ice cream'],
 'ice_cream', 'Ben & Jerry''s', 1, '236 cal/100g. 2/3 cup (141g) ~333 cal. Strawberry cheesecake ice cream with strawberries & graham cracker swirl.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- HAAGEN-DAZS  (pints, per 2/3 cup ~129-132g serving)
-- ══════════════════════════════════════════════════════════════════

-- Vanilla: 320 cal per 2/3 cup (129g) = ~248 cal/100g
-- Per 129g: 320 cal, 21g fat, 27g carbs, 5g protein, 25g sugar, 0g fiber
('haagen_dazs_vanilla', 'Haagen-Dazs Vanilla', 248, 3.9, 20.9, 16.3,
 0.0, 19.4, 129, NULL,
 'haagen_dazs', ARRAY['haagen dazs vanilla', 'hd vanilla', 'haagen dazs vanilla ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '248 cal/100g. 2/3 cup (129g) = 320 cal. Five simple ingredients: cream, skim milk, cane sugar, egg yolks, vanilla extract.', TRUE),

-- Chocolate: 330 cal per 2/3 cup (130g) = ~254 cal/100g
-- Per 130g: 330 cal, 21g fat, 28g carbs, 6g protein, 25g sugar, 2g fiber
('haagen_dazs_chocolate', 'Haagen-Dazs Chocolate', 254, 4.6, 21.5, 16.2,
 1.5, 19.2, 130, NULL,
 'haagen_dazs', ARRAY['haagen dazs chocolate', 'hd chocolate', 'haagen dazs chocolate ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '254 cal/100g. 2/3 cup (130g) = 330 cal. Rich chocolate ice cream made with cocoa.', TRUE),

-- Strawberry: 310 cal per 2/3 cup (131g) = ~237 cal/100g
-- Per 131g: 310 cal, 19g fat, 29g carbs, 5g protein, 28g sugar, 0g fiber
('haagen_dazs_strawberry', 'Haagen-Dazs Strawberry', 237, 3.8, 22.1, 14.5,
 0.0, 21.4, 131, NULL,
 'haagen_dazs', ARRAY['haagen dazs strawberry', 'hd strawberry', 'haagen dazs strawberry ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '237 cal/100g. 2/3 cup (131g) = 310 cal. Strawberry ice cream with real strawberries.', TRUE),

-- Cookies & Cream: 320 cal per 2/3 cup (131g) = ~244 cal/100g
-- Per 131g: 320 cal, 20g fat, 30g carbs, 5g protein, 26g sugar, 0g fiber
('haagen_dazs_cookies_cream', 'Haagen-Dazs Cookies & Cream', 244, 3.8, 22.9, 15.3,
 0.0, 19.8, 131, NULL,
 'haagen_dazs', ARRAY['haagen dazs cookies and cream', 'hd cookies cream', 'haagen dazs cookies cream ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '244 cal/100g. 2/3 cup (131g) = 320 cal. Vanilla ice cream with chocolate cookie pieces.', TRUE),

-- Dulce de Leche: 340 cal per 2/3 cup (132g) = ~258 cal/100g
-- Per 132g: 340 cal, 19g fat, 36g carbs, 6g protein, 33g sugar, 0g fiber
('haagen_dazs_dulce_de_leche', 'Haagen-Dazs Dulce de Leche', 258, 4.5, 27.3, 14.4,
 0.0, 25.0, 132, NULL,
 'haagen_dazs', ARRAY['haagen dazs dulce de leche', 'hd dulce de leche', 'haagen dazs caramel ice cream', 'dulce de leche ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '258 cal/100g. 2/3 cup (132g) = 340 cal. Caramel ice cream with swirls of caramel.', TRUE),

-- Coffee: 300 cal per 2/3 cup (129g) = ~233 cal/100g
-- Per 129g: 300 cal, 21g fat, 25g carbs, 5g protein, 24g sugar, 0g fiber
('haagen_dazs_coffee', 'Haagen-Dazs Coffee', 233, 3.9, 19.4, 16.3,
 0.0, 18.6, 129, NULL,
 'haagen_dazs', ARRAY['haagen dazs coffee', 'hd coffee', 'haagen dazs coffee ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '233 cal/100g. 2/3 cup (129g) = 300 cal. Coffee ice cream made with Brazilian coffee.', TRUE),

-- Butter Pecan: 370 cal per 2/3 cup (129g) = ~287 cal/100g
-- Per 129g: 370 cal, 26g fat, 28g carbs, 6g protein, 22g sugar, 1g fiber
('haagen_dazs_butter_pecan', 'Haagen-Dazs Butter Pecan', 287, 4.7, 21.7, 20.2,
 0.8, 17.1, 129, NULL,
 'haagen_dazs', ARRAY['haagen dazs butter pecan', 'hd butter pecan', 'haagen dazs butter pecan ice cream'],
 'ice_cream', 'Haagen-Dazs', 1, '287 cal/100g. 2/3 cup (129g) = 370 cal. Butter ice cream with roasted pecans.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- TALENTI  (gelato jars, per 2/3 cup ~128-131g serving)
-- ══════════════════════════════════════════════════════════════════

-- Sea Salt Caramel: 320 cal per 2/3 cup (128g) = ~250 cal/100g
-- Per 128g: 320 cal, 14g fat, 42g carbs, 6g protein, 37g sugar, 0g fiber
('talenti_sea_salt_caramel', 'Talenti Sea Salt Caramel Gelato', 250, 4.7, 32.8, 10.9,
 0.0, 28.9, 128, NULL,
 'talenti', ARRAY['talenti sea salt caramel', 'sea salt caramel gelato', 'talenti salted caramel'],
 'ice_cream', 'Talenti', 1, '250 cal/100g. 2/3 cup (128g) = 320 cal. Argentinian caramel gelato with chocolate-covered caramel truffles & sea salt.', TRUE),

-- Mediterranean Mint: 290 cal per 2/3 cup (131g) = ~221 cal/100g
-- Per 131g: 290 cal, 14g fat, 35g carbs, 5g protein, 30g sugar, 1g fiber
('talenti_mediterranean_mint', 'Talenti Mediterranean Mint Gelato', 221, 3.8, 26.7, 10.7,
 0.8, 22.9, 131, NULL,
 'talenti', ARRAY['talenti mediterranean mint', 'mediterranean mint gelato', 'talenti mint chip', 'talenti mint gelato'],
 'ice_cream', 'Talenti', 1, '221 cal/100g. 2/3 cup (131g) = 290 cal. Mint gelato with chocolate chips.', TRUE),

-- Alphonso Mango Sorbetto: 130 cal per 2/3 cup (131g) = ~99 cal/100g
-- Per 131g: 130 cal, 0g fat, 34g carbs, 0g protein, 29g sugar, 1g fiber
('talenti_alphonso_mango', 'Talenti Alphonso Mango Sorbetto', 99, 0.0, 26.0, 0.0,
 0.8, 22.1, 131, NULL,
 'talenti', ARRAY['talenti alphonso mango', 'alphonso mango sorbetto', 'talenti mango', 'mango sorbetto'],
 'ice_cream', 'Talenti', 1, '99 cal/100g. 2/3 cup (131g) = 130 cal. Dairy-free sorbetto made with Alphonso mangoes.', TRUE),

-- Vanilla Bean: 260 cal per 2/3 cup (128g) = ~203 cal/100g
-- Per 128g: 260 cal, 13g fat, 30g carbs, 5g protein, 27g sugar, 0g fiber
('talenti_vanilla_bean', 'Talenti Madagascan Vanilla Bean Gelato', 203, 3.9, 23.4, 10.2,
 0.0, 21.1, 128, NULL,
 'talenti', ARRAY['talenti vanilla bean', 'vanilla bean gelato', 'talenti vanilla', 'madagascan vanilla bean gelato'],
 'ice_cream', 'Talenti', 1, '203 cal/100g. 2/3 cup (128g) = 260 cal. Gelato made with Madagascan vanilla beans.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- HALO TOP  (pints, per 2/3 cup ~85-88g serving, light ice cream)
-- ══════════════════════════════════════════════════════════════════

-- Vanilla Bean: 100 cal per 2/3 cup (88g) = ~114 cal/100g
-- Per 88g: 100 cal, 2g fat, 20g carbs, 5g protein, 6g sugar, 5g fiber
('halo_top_vanilla_bean', 'Halo Top Vanilla Bean', 114, 5.7, 22.7, 2.3,
 5.7, 6.8, 88, NULL,
 'halo_top', ARRAY['halo top vanilla', 'halo top vanilla bean ice cream', 'halotop vanilla'],
 'ice_cream', 'Halo Top', 1, '114 cal/100g. 2/3 cup (88g) = 100 cal. Light ice cream, high protein, 290 cal/pint.', TRUE),

-- Chocolate: 100 cal per 2/3 cup (85g) = ~118 cal/100g
-- Per 85g: 100 cal, 2g fat, 21g carbs, 6g protein, 8g sugar, 6g fiber
('halo_top_chocolate', 'Halo Top Chocolate', 118, 7.1, 24.7, 2.4,
 7.1, 9.4, 85, NULL,
 'halo_top', ARRAY['halo top chocolate ice cream', 'halotop chocolate'],
 'ice_cream', 'Halo Top', 1, '118 cal/100g. 2/3 cup (85g) = 100 cal. Light chocolate ice cream, 300 cal/pint.', TRUE),

-- Birthday Cake: 100 cal per 2/3 cup (85g) = ~118 cal/100g
-- Per 85g: 100 cal, 2g fat, 22g carbs, 5g protein, 7g sugar, 3g fiber
('halo_top_birthday_cake', 'Halo Top Birthday Cake', 118, 5.9, 25.9, 2.4,
 3.5, 8.2, 85, NULL,
 'halo_top', ARRAY['halo top birthday cake ice cream', 'halotop birthday cake'],
 'ice_cream', 'Halo Top', 1, '118 cal/100g. 2/3 cup (85g) = 100 cal. Light birthday cake ice cream with cake pieces & sprinkles.', TRUE),

-- Peanut Butter Cup: 110 cal per 2/3 cup (87g) = ~126 cal/100g
-- Per 87g: 110 cal, 3g fat, 20g carbs, 5g protein, 6g sugar, 4g fiber
('halo_top_peanut_butter_cup', 'Halo Top Peanut Butter Cup', 126, 5.7, 23.0, 3.4,
 4.6, 6.9, 87, NULL,
 'halo_top', ARRAY['halo top peanut butter cup ice cream', 'halotop peanut butter cup', 'halo top pb cup'],
 'ice_cream', 'Halo Top', 1, '126 cal/100g. 2/3 cup (87g) = 110 cal. Light ice cream with peanut butter swirl & chocolate cups, 330 cal/pint.', TRUE),

-- Mint Chip: 110 cal per 2/3 cup (86g) = ~128 cal/100g
-- Per 86g: 110 cal, 3g fat, 22g carbs, 5g protein, 7g sugar, 4g fiber
('halo_top_mint_chip', 'Halo Top Mint Chip', 128, 5.8, 25.6, 3.5,
 4.7, 8.1, 86, NULL,
 'halo_top', ARRAY['halo top mint chip ice cream', 'halotop mint chip', 'halo top mint chocolate chip'],
 'ice_cream', 'Halo Top', 1, '128 cal/100g. 2/3 cup (86g) = 110 cal. Light mint ice cream with chocolate chips, 330 cal/pint.', TRUE),

-- Cookies & Cream: 100 cal per 2/3 cup (86g) = ~116 cal/100g
-- Per 86g: 100 cal, 2g fat, 21g carbs, 5g protein, 7g sugar, 4g fiber
('halo_top_cookies_cream', 'Halo Top Cookies & Cream', 116, 5.8, 24.4, 2.3,
 4.7, 8.1, 86, NULL,
 'halo_top', ARRAY['halo top cookies and cream ice cream', 'halotop cookies cream'],
 'ice_cream', 'Halo Top', 1, '116 cal/100g. 2/3 cup (86g) = 100 cal. Light ice cream with chocolate cookie pieces, 310 cal/pint.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- BLUE BELL  (1/2 gallon & pints, per 1/2 cup ~73-82g serving)
-- ══════════════════════════════════════════════════════════════════

-- Homemade Vanilla: 210 cal per 2/3 cup (106g) = ~198 cal/100g
-- Per 1/2 cup (79g): 160 cal, 9g fat, 17g carbs, 3g protein, 15g sugar, 0g fiber
('blue_bell_homemade_vanilla', 'Blue Bell Homemade Vanilla', 203, 3.8, 21.5, 11.4,
 0.0, 19.0, 79, NULL,
 'blue_bell', ARRAY['blue bell vanilla', 'blue bell homemade vanilla ice cream', 'blue bell vanilla ice cream'],
 'ice_cream', 'Blue Bell', 1, '203 cal/100g. 1/2 cup (79g) = 160 cal. Homemade vanilla flavor, Blue Bell signature.', TRUE),

-- Dutch Chocolate: 160 cal per 1/2 cup (74g) = ~216 cal/100g
-- Per 74g: 160 cal, 9g fat, 18g carbs, 4g protein, 15g sugar, 1g fiber
('blue_bell_dutch_chocolate', 'Blue Bell Dutch Chocolate', 216, 5.4, 24.3, 12.2,
 1.4, 20.3, 74, NULL,
 'blue_bell', ARRAY['blue bell chocolate', 'blue bell dutch chocolate ice cream'],
 'ice_cream', 'Blue Bell', 1, '216 cal/100g. 1/2 cup (74g) = 160 cal. Rich Dutch chocolate ice cream.', TRUE),

-- Cookies & Cream: 180 cal per 1/2 cup (74g) = ~243 cal/100g
-- Per 74g: 180 cal, 10g fat, 21g carbs, 3g protein, 17g sugar, 0g fiber
('blue_bell_cookies_cream', 'Blue Bell Cookies ''n Cream', 243, 4.1, 28.4, 13.5,
 0.0, 23.0, 74, NULL,
 'blue_bell', ARRAY['blue bell cookies and cream', 'blue bell cookies n cream ice cream'],
 'ice_cream', 'Blue Bell', 1, '243 cal/100g. 1/2 cup (74g) = 180 cal. Cookies & cream ice cream with chocolate cookie pieces.', TRUE),

-- The Great Divide: 170 cal per 1/2 cup (82g) = ~207 cal/100g
-- Per 82g: 170 cal, 9g fat, 20g carbs, 3g protein, 16g sugar, 0g fiber
('blue_bell_great_divide', 'Blue Bell The Great Divide', 207, 3.7, 24.4, 11.0,
 0.0, 19.5, 82, NULL,
 'blue_bell', ARRAY['blue bell great divide', 'blue bell great divide ice cream', 'great divide ice cream'],
 'ice_cream', 'Blue Bell', 1, '207 cal/100g. 1/2 cup (82g) = 170 cal. Half homemade vanilla, half Dutch chocolate.', TRUE),

-- Banana Pudding: 170 cal per 1/2 cup (79g) = ~215 cal/100g
-- Per 79g: 170 cal, 8g fat, 21g carbs, 4g protein, 16g sugar, 0g fiber
('blue_bell_banana_pudding', 'Blue Bell Banana Pudding', 215, 5.1, 26.6, 10.1,
 0.0, 20.3, 79, NULL,
 'blue_bell', ARRAY['blue bell banana pudding ice cream', 'banana pudding ice cream'],
 'ice_cream', 'Blue Bell', 1, '215 cal/100g. 1/2 cup (79g) = 170 cal. Banana-flavored ice cream with vanilla wafer pieces & caramel swirl.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- BREYERS  (1.5 qt tubs, per 1/2 cup ~65g serving)
-- ══════════════════════════════════════════════════════════════════

-- Natural Vanilla: 130 cal per 1/2 cup (65g) = ~200 cal/100g
-- Per 65g: 130 cal, 7g fat, 14g carbs, 3g protein, 14g sugar, 0g fiber
('breyers_natural_vanilla', 'Breyers Natural Vanilla', 200, 4.6, 21.5, 10.8,
 0.0, 21.5, 65, NULL,
 'breyers', ARRAY['breyers vanilla', 'breyers natural vanilla ice cream', 'breyers all natural vanilla'],
 'ice_cream', 'Breyers', 1, '200 cal/100g. 1/2 cup (65g) = 130 cal. Made with fresh cream, sugar, milk & vanilla bean.', TRUE),

-- Chocolate: 140 cal per 1/2 cup (65g) = ~215 cal/100g
-- Per 65g: 140 cal, 7g fat, 17g carbs, 3g protein, 16g sugar, 1g fiber
('breyers_chocolate', 'Breyers Chocolate', 215, 4.6, 26.2, 10.8,
 1.5, 24.6, 65, NULL,
 'breyers', ARRAY['breyers chocolate ice cream'],
 'ice_cream', 'Breyers', 1, '215 cal/100g. 1/2 cup (65g) = 140 cal. Chocolate ice cream made with real cocoa.', TRUE),

-- Cookies & Cream: 140 cal per 1/2 cup (65g) = ~215 cal/100g
-- Per 65g: 140 cal, 6g fat, 20g carbs, 2g protein, 15g sugar, 0g fiber
('breyers_cookies_cream', 'Breyers Cookies & Cream', 215, 3.1, 30.8, 9.2,
 0.0, 23.1, 65, NULL,
 'breyers', ARRAY['breyers cookies and cream ice cream', 'breyers cookies n cream'],
 'ice_cream', 'Breyers', 1, '215 cal/100g. 1/2 cup (65g) = 140 cal. Vanilla with chocolate cookie pieces.', TRUE),

-- Mint Chocolate Chip: 150 cal per 1/2 cup (65g) = ~231 cal/100g
-- Per 65g: 150 cal, 8g fat, 18g carbs, 2g protein, 16g sugar, 0g fiber
('breyers_mint_chocolate_chip', 'Breyers Mint Chocolate Chip', 231, 3.1, 27.7, 12.3,
 0.0, 24.6, 65, NULL,
 'breyers', ARRAY['breyers mint choc chip', 'breyers mint chocolate chip ice cream'],
 'ice_cream', 'Breyers', 1, '231 cal/100g. 1/2 cup (65g) = 150 cal. Mint ice cream with chocolate chips.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- MAGNUM  (ice cream bars, per bar ~76-90g)
-- ══════════════════════════════════════════════════════════════════

-- Classic: 250 cal per bar (80g) = ~313 cal/100g
-- Per 80g bar: 250 cal, 17g fat, 22g carbs, 3g protein, 20g sugar, 1g fiber
('magnum_classic', 'Magnum Classic Bar', 313, 3.8, 27.5, 21.3,
 1.3, 25.0, NULL, 80,
 'magnum', ARRAY['magnum classic ice cream bar', 'magnum bar', 'magnum classic'],
 'ice_cream', 'Magnum', 1, '313 cal/100g. Per bar (80g) = 250 cal. Vanilla ice cream dipped in Belgian chocolate.', TRUE),

-- Almond: 270 cal per bar (82g) = ~329 cal/100g
-- Per 82g bar: 270 cal, 19g fat, 23g carbs, 4g protein, 19g sugar, 1g fiber
('magnum_almond', 'Magnum Almond Bar', 329, 4.9, 28.0, 23.2,
 1.2, 23.2, NULL, 82,
 'magnum', ARRAY['magnum almond ice cream bar', 'magnum almond'],
 'ice_cream', 'Magnum', 1, '329 cal/100g. Per bar (82g) = 270 cal. Vanilla ice cream dipped in Belgian chocolate with almonds.', TRUE),

-- Double Caramel: 250 cal per bar (79g) = ~316 cal/100g
-- Per 79g bar: 250 cal, 14g fat, 29g carbs, 3g protein, 25g sugar, 0g fiber
('magnum_double_caramel', 'Magnum Double Caramel Bar', 316, 3.8, 36.7, 17.7,
 0.0, 31.6, NULL, 79,
 'magnum', ARRAY['magnum double caramel ice cream bar', 'magnum caramel'],
 'ice_cream', 'Magnum', 1, '316 cal/100g. Per bar (79g) = 250 cal. Vanilla ice cream with caramel swirl, dipped in chocolate & caramel.', TRUE),

-- White Chocolate: 250 cal per bar (77g) = ~325 cal/100g
-- Per 77g bar: 250 cal, 16g fat, 24g carbs, 3g protein, 22g sugar, 0g fiber
('magnum_white_chocolate', 'Magnum White Chocolate Bar', 325, 3.9, 31.2, 20.8,
 0.0, 28.6, NULL, 77,
 'magnum', ARRAY['magnum white chocolate ice cream bar', 'magnum white'],
 'ice_cream', 'Magnum', 1, '325 cal/100g. Per bar (77g) = 250 cal. Vanilla ice cream dipped in white Belgian chocolate.', TRUE)

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
