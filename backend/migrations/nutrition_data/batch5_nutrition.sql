-- =============================================
-- BATCH 5: Restaurant Nutrition Data
-- Culver's, Firehouse Subs, Shake Shack, In-N-Out Burger,
-- Noodles & Company, Waffle House, Crumbl Cookies,
-- Tropical Smoothie Cafe, Portillo's, Steak 'n Shake
-- Sources: fastfoodnutrition.org, nutritionix.com, official restaurant sites
-- Column order: cal/100g, protein/100g, carbs/100g, fat/100g, fiber/100g, sugar/100g
-- =============================================

-- =============================================
-- 1. CULVER'S (culvers.com)
-- =============================================

-- ButterBurger Single: 390cal, 20g pro, 38g carb, 17g fat, 1g fib, 6g sug, 132g
('culvers_butterburger_single', 'Culver''s ButterBurger Single', 295.5, 15.2, 28.8, 12.9, 0.8, 4.5, 132, 132, 'culvers.com', ARRAY['culvers original butterburger', 'culvers single burger'], '390 cal per 132g burger'),
-- Cheese ButterBurger Single: 460cal, 24g pro, 39g carb, 23g fat, 1g fib, 7g sug, ~155g
('culvers_butterburger_cheese_single', 'Culver''s ButterBurger Cheese Single', 296.8, 15.5, 25.2, 14.8, 0.6, 4.5, 155, 155, 'culvers.com', ARRAY['culvers cheese butterburger', 'culvers cheeseburger'], '460 cal per ~155g burger'),
-- Deluxe ButterBurger Single: 580cal, 24g pro, 41g carb, 34g fat, 1g fib, 7g sug, ~220g
('culvers_deluxe_butterburger_single', 'Culver''s Deluxe ButterBurger Single', 263.6, 10.9, 18.6, 15.5, 0.5, 3.2, 220, 220, 'culvers.com', ARRAY['culvers deluxe', 'culvers deluxe single'], '580 cal per ~220g burger'),
-- Double ButterBurger: 560cal, 34g pro, 38g carb, 30g fat, 1g fib, 6g sug, ~200g
('culvers_butterburger_double', 'Culver''s ButterBurger Double', 280.0, 17.0, 19.0, 15.0, 0.5, 3.0, 200, 200, 'culvers.com', ARRAY['culvers double butterburger', 'culvers double burger'], '560 cal per ~200g burger'),
-- Mushroom & Swiss Single: 530cal, 27g pro, 41g carb, 28g fat, 2g fib, 6g sug, ~210g
('culvers_mushroom_swiss_single', 'Culver''s Mushroom & Swiss ButterBurger Single', 252.4, 12.9, 19.5, 13.3, 1.0, 2.9, 210, 210, 'culvers.com', ARRAY['culvers mushroom swiss', 'culvers mushroom burger'], '530 cal per ~210g burger'),
-- Crispy Chicken Sandwich: 690cal, 28g pro, 65g carb, 35g fat, 2g fib, 9g sug, ~230g
('culvers_crispy_chicken_sandwich', 'Culver''s Crispy Chicken Sandwich', 300.0, 12.2, 28.3, 15.2, 0.9, 3.9, 230, 230, 'culvers.com', ARRAY['culvers chicken sandwich', 'culvers fried chicken sandwich'], '690 cal per ~230g sandwich'),
-- Grilled Chicken Sandwich: 480cal, 36g pro, 40g carb, 19g fat, 2g fib, 9g sug, ~220g
('culvers_grilled_chicken_sandwich', 'Culver''s Grilled Chicken Sandwich', 218.2, 16.4, 18.2, 8.6, 0.9, 4.1, 220, 220, 'culvers.com', ARRAY['culvers grilled chicken'], '480 cal per ~220g sandwich'),
-- Chicken Tenders 4pc: 520cal, 39g pro, 41g carb, 23g fat, 2g fib, 0g sug, ~200g
('culvers_chicken_tenders_4pc', 'Culver''s Chicken Tenders (4 piece)', 260.0, 19.5, 20.5, 11.5, 1.0, 0.0, 200, 200, 'culvers.com', ARRAY['culvers chicken tenders', 'culvers chicken strips'], '520 cal per 4-piece serving'),
-- Cod Sandwich: 600cal, 23g pro, 55g carb, 34g fat, 3g fib, 6g sug, ~230g
('culvers_cod_sandwich', 'Culver''s North Atlantic Cod Sandwich', 260.9, 10.0, 23.9, 14.8, 1.3, 2.6, 230, 230, 'culvers.com', ARRAY['culvers fish sandwich', 'culvers cod sandwich'], '600 cal per ~230g sandwich'),
-- Wisconsin Cheese Curds Regular: 510cal, 20g pro, 51g carb, 25g fat, 0g fib, 4g sug, ~140g
('culvers_cheese_curds_regular', 'Culver''s Wisconsin Cheese Curds (Regular)', 364.3, 14.3, 36.4, 17.9, 0.0, 2.9, 140, 140, 'culvers.com', ARRAY['culvers cheese curds', 'culvers curds'], '510 cal per regular serving (~140g)'),
-- Crinkle Cut Fries Large: 430cal, 5g pro, 62g carb, 18g fat, 4g fib, 0g sug, ~170g
('culvers_fries_large', 'Culver''s Crinkle Cut Fries (Large)', 252.9, 2.9, 36.5, 10.6, 2.4, 0.0, 170, 170, 'culvers.com', ARRAY['culvers fries', 'culvers french fries'], '430 cal per large serving (~170g)'),
-- Onion Rings Large: 840cal, 10g pro, 98g carb, 46g fat, 8g fib, 9g sug, ~220g
('culvers_onion_rings', 'Culver''s Onion Rings (Large)', 381.8, 4.5, 44.5, 20.9, 3.6, 4.1, 220, 220, 'culvers.com', ARRAY['culvers onion rings'], '840 cal per large serving (~220g)'),
-- Custard 1 Scoop Cake Cone: 330cal, 6g pro, 36g carb, 19g fat, 2g fib, 27g sug, ~120g
('culvers_custard_1_scoop', 'Culver''s Frozen Custard (1 Scoop Cake Cone)', 275.0, 5.0, 30.0, 15.8, 1.7, 22.5, 120, 120, 'culvers.com', ARRAY['culvers custard', 'culvers ice cream', 'culvers frozen custard'], '330 cal per 1-scoop cone (~120g)'),
-- Shake Large: 1030cal, 21g pro, 103g carb, 62g fat, 5g fib, 93g sug, ~450g
('culvers_shake_large', 'Culver''s Shake (Large)', 228.9, 4.7, 22.9, 13.8, 1.1, 20.7, 450, 450, 'culvers.com', ARRAY['culvers milkshake', 'culvers shake'], '1030 cal per large shake (~450g)'),
-- Chicken Cashew Salad: 430cal, 41g pro, 17g carb, 23g fat, 6g fib, 5g sug, ~350g
('culvers_chicken_cashew_salad', 'Culver''s Chicken Cashew Salad', 122.9, 11.7, 4.9, 6.6, 1.7, 1.4, 350, 350, 'culvers.com', ARRAY['culvers cashew chicken salad'], '430 cal per salad (~350g)'),
-- Cranberry Bacon Bleu Salad: 390cal, 46g pro, 18g carb, 16g fat, 5g fib, 12g sug, ~350g
('culvers_cranberry_bacon_bleu_salad', 'Culver''s Cranberry Bacon Bleu Salad', 111.4, 13.1, 5.1, 4.6, 1.4, 3.4, 350, 350, 'culvers.com', ARRAY['culvers cranberry salad', 'culvers bleu salad'], '390 cal per salad (~350g)'),

-- =============================================
-- 2. FIREHOUSE SUBS (firehousesubs.com)
-- =============================================

-- Hook & Ladder Medium: ~700cal, ~40g pro, ~55g carb, ~35g fat, ~3g fib, ~8g sug, ~230g
('firehouse_hook_ladder_medium', 'Firehouse Subs Hook & Ladder (Medium)', 304.3, 17.4, 23.9, 15.2, 1.3, 3.5, 230, 230, 'firehousesubs.com', ARRAY['firehouse hook and ladder', 'firehouse hook ladder'], '~700 cal per medium sub (~230g)'),
-- Cajun Chicken Medium: 700cal, 45g pro, 53g carb, 35g fat, 3g fib, 5g sug, ~230g
('firehouse_cajun_chicken_medium', 'Firehouse Subs Cajun Chicken (Medium)', 304.3, 19.6, 23.0, 15.2, 1.3, 2.2, 230, 230, 'firehousesubs.com', ARRAY['firehouse cajun chicken'], '700 cal per medium sub (~230g)'),
-- Meatball Large: 1310cal, 58g pro, 97g carb, 80g fat, 6g fib, 16g sug, ~400g
('firehouse_meatball_large', 'Firehouse Subs Meatball (Large)', 327.5, 14.5, 24.3, 20.0, 1.5, 4.0, 400, 400, 'firehousesubs.com', ARRAY['firehouse meatball sub', 'firehouse meatball'], '1310 cal per large sub (~400g)'),
-- Italian Large: 1410cal, 69g pro, 118g carb, 79g fat, 6g fib, 35g sug, ~400g
('firehouse_italian_large', 'Firehouse Subs Italian (Large)', 352.5, 17.3, 29.5, 19.8, 1.5, 8.8, 400, 400, 'firehousesubs.com', ARRAY['firehouse italian sub', 'firehouse italian'], '1410 cal per large sub (~400g)'),
-- NY Steamer Medium: ~710cal, 44g pro, 50g carb, 38g fat, 2g fib, 7g sug, ~230g
('firehouse_ny_steamer_medium', 'Firehouse Subs New York Steamer (Medium)', 308.7, 19.1, 21.7, 16.5, 0.9, 3.0, 230, 230, 'firehousesubs.com', ARRAY['firehouse new york steamer', 'firehouse ny steamer'], '~710 cal per medium sub (~230g)'),
-- Engineer Large: 1110cal, 68g pro, 101g carb, 54g fat, 9g fib, 15g sug, ~400g
('firehouse_engineer_large', 'Firehouse Subs Engineer (Large)', 277.5, 17.0, 25.3, 13.5, 2.3, 3.8, 400, 400, 'firehousesubs.com', ARRAY['firehouse engineer sub', 'firehouse engineer'], '1110 cal per large sub (~400g)'),
-- Hero Large: 1180cal, 68g pro, 108g carb, 56g fat, 6g fib, 27g sug, ~400g
('firehouse_hero_large', 'Firehouse Subs Hero (Large)', 295.0, 17.0, 27.0, 14.0, 1.5, 6.8, 400, 400, 'firehousesubs.com', ARRAY['firehouse hero sub', 'firehouse hero'], '1180 cal per large sub (~400g)'),
-- Turkey Medium: ~620cal, 32g pro, 57g carb, 32g fat, 4g fib, 9g sug, ~230g
('firehouse_turkey_medium', 'Firehouse Subs Turkey (Medium)', 269.6, 13.9, 24.8, 13.9, 1.7, 3.9, 230, 230, 'firehousesubs.com', ARRAY['firehouse turkey sub', 'firehouse turkey'], '~620 cal per medium sub (~230g)'),
-- Ham Medium: ~680cal, 34g pro, 68g carb, 33g fat, 4g fib, 20g sug, ~230g
('firehouse_ham_medium', 'Firehouse Subs Ham (Medium)', 295.7, 14.8, 29.6, 14.3, 1.7, 8.7, 230, 230, 'firehousesubs.com', ARRAY['firehouse ham sub', 'firehouse ham'], '~680 cal per medium sub (~230g)'),
-- Tuna Large: 1540cal, 71g pro, 103g carb, 97g fat, 6g fib, 20g sug, ~400g
('firehouse_tuna_large', 'Firehouse Subs Tuna (Large)', 385.0, 17.8, 25.8, 24.3, 1.5, 5.0, 400, 400, 'firehousesubs.com', ARRAY['firehouse tuna sub', 'firehouse tuna'], '1540 cal per large sub (~400g)'),
-- Chicken Noodle Soup 10oz: 120cal, 8g pro, 18g carb, 2g fat, 1g fib, 3g sug, ~280g
('firehouse_chicken_noodle_soup', 'Firehouse Subs Chicken Noodle Soup', 42.9, 2.9, 6.4, 0.7, 0.4, 1.1, 280, 280, 'firehousesubs.com', ARRAY['firehouse chicken noodle'], '120 cal per 10oz bowl (~280g)'),
-- Chili 10oz: 300cal, 18g pro, 22g carb, 15g fat, 5g fib, 5g sug, ~280g
('firehouse_chili', 'Firehouse Subs Chili', 107.1, 6.4, 7.9, 5.4, 1.8, 1.8, 280, 280, 'firehousesubs.com', ARRAY['firehouse chili'], '300 cal per 10oz bowl (~280g)'),
-- Broccoli Cheese Soup 10oz: 340cal, 11g pro, 12g carb, 28g fat, 1g fib, 5g sug, ~280g
('firehouse_broccoli_cheese_soup', 'Firehouse Subs Broccoli & Cheese Soup', 121.4, 3.9, 4.3, 10.0, 0.4, 1.8, 280, 280, 'firehousesubs.com', ARRAY['firehouse broccoli cheese'], '340 cal per 10oz bowl (~280g)'),
-- 5-Cheese Mac & Cheese: 380cal, 17g pro, 33g carb, 20g fat, 1g fib, 2g sug, ~170g
('firehouse_mac_cheese', 'Firehouse Subs 5-Cheese Mac & Cheese', 223.5, 10.0, 19.4, 11.8, 0.6, 1.2, 170, 170, 'firehousesubs.com', ARRAY['firehouse mac and cheese', 'firehouse mac cheese'], '380 cal per side (~170g)'),
-- Brownie: 430cal, 4g pro, 61g carb, 20g fat, 1g fib, 38g sug, ~100g
('firehouse_brownie', 'Firehouse Subs Brownie', 430.0, 4.0, 61.0, 20.0, 1.0, 38.0, 100, 100, 'firehousesubs.com', ARRAY['firehouse brownie'], '430 cal per brownie (~100g)'),
-- Hook & Ladder Salad: 320cal, 30g pro, 21g carb, 13g fat, 5g fib, 12g sug, ~350g
('firehouse_hook_ladder_salad', 'Firehouse Subs Hook & Ladder Salad', 91.4, 8.6, 6.0, 3.7, 1.4, 3.4, 350, 350, 'firehousesubs.com', ARRAY['firehouse salad'], '320 cal per salad (~350g)'),

-- =============================================
-- 3. SHAKE SHACK (shakeshack.com)
-- =============================================

-- Single ShackBurger: 500cal, 29g pro, 26g carb, 30g fat, 0g fib, 6g sug, ~200g
('shake_shack_shackburger_single', 'Shake Shack ShackBurger (Single)', 250.0, 14.5, 13.0, 15.0, 0.0, 3.0, 200, 200, 'shakeshack.com', ARRAY['shake shack burger', 'shack burger', 'shackburger'], '500 cal per single burger (~200g)'),
-- Double ShackBurger: 760cal, 51g pro, 27g carb, 48g fat, 0g fib, 6g sug, ~290g
('shake_shack_shackburger_double', 'Shake Shack ShackBurger (Double)', 262.1, 17.6, 9.3, 16.6, 0.0, 2.1, 290, 290, 'shakeshack.com', ARRAY['shake shack double', 'double shackburger'], '760 cal per double burger (~290g)'),
-- Single Cheeseburger: 440cal, 29g pro, 25g carb, 24g fat, 0g fib, 5g sug, ~185g
('shake_shack_cheeseburger_single', 'Shake Shack Cheeseburger (Single)', 237.8, 15.7, 13.5, 13.0, 0.0, 2.7, 185, 185, 'shakeshack.com', ARRAY['shake shack cheese burger', 'shake shack single cheeseburger'], '440 cal per single cheeseburger (~185g)'),
-- Avocado Bacon Burger Single: 610cal, 36g pro, 28g carb, 39g fat, 2g fib, 5g sug, ~240g
('shake_shack_avocado_bacon_burger', 'Shake Shack Avocado Bacon Burger (Single)', 254.2, 15.0, 11.7, 16.3, 0.8, 2.1, 240, 240, 'shakeshack.com', ARRAY['shake shack avocado burger', 'shake shack bacon avocado'], '610 cal per burger (~240g)'),
-- SmokeShack Single: 570cal, 31g pro, 28g carb, 34g fat, 1g fib, 6g sug, ~220g
('shake_shack_smokeshack', 'Shake Shack SmokeShack (Single)', 259.1, 14.1, 12.7, 15.5, 0.5, 2.7, 220, 220, 'shakeshack.com', ARRAY['smokeshack', 'shake shack smokeshack'], '570 cal per burger (~220g)'),
-- Chicken Shack: 550cal, 33g pro, 34g carb, 31g fat, 0g fib, 6g sug, ~220g
('shake_shack_chicken_shack', 'Shake Shack Chicken Shack', 250.0, 15.0, 15.5, 14.1, 0.0, 2.7, 220, 220, 'shakeshack.com', ARRAY['shake shack chicken sandwich', 'chicken shack'], '550 cal per sandwich (~220g)'),
-- Chicken Bites 6pc: 300cal, 17g pro, 15g carb, 19g fat, 0g fib, 1g sug, ~120g
('shake_shack_chicken_bites_6pc', 'Shake Shack Chicken Bites (6 Piece)', 250.0, 14.2, 12.5, 15.8, 0.0, 0.8, 120, 120, 'shakeshack.com', ARRAY['shake shack chicken bites', 'shake shack nuggets'], '300 cal per 6-piece (~120g)'),
-- Shack Dog: 370cal, 14g pro, 25g carb, 24g fat, 0g fib, 4g sug, ~120g
('shake_shack_hot_dog', 'Shake Shack Shack Dog', 308.3, 11.7, 20.8, 20.0, 0.0, 3.3, 120, 120, 'shakeshack.com', ARRAY['shake shack hot dog', 'shack dog'], '370 cal per hot dog (~120g)'),
-- Regular Fries: 470cal, 6g pro, 63g carb, 22g fat, 7g fib, 1g sug, ~150g
('shake_shack_fries', 'Shake Shack Fries', 313.3, 4.0, 42.0, 14.7, 4.7, 0.7, 150, 150, 'shakeshack.com', ARRAY['shake shack french fries', 'shake shack crinkle fries'], '470 cal per regular order (~150g)'),
-- Cheese Fries: 710cal, 12g pro, 64g carb, 44g fat, 7g fib, 1g sug, ~200g
('shake_shack_cheese_fries', 'Shake Shack Cheese Fries', 355.0, 6.0, 32.0, 22.0, 3.5, 0.5, 200, 200, 'shakeshack.com', ARRAY['shake shack cheese fries'], '710 cal per order (~200g)'),
-- Vanilla Shake: 680cal, 18g pro, 72g carb, 36g fat, 0g fib, 71g sug, ~400g
('shake_shack_vanilla_shake', 'Shake Shack Vanilla Shake', 170.0, 4.5, 18.0, 9.0, 0.0, 17.8, 400, 400, 'shakeshack.com', ARRAY['shake shack vanilla milkshake'], '680 cal per shake (~400g)'),
-- Chocolate Shake: 750cal, 16g pro, 76g carb, 45g fat, 0g fib, 69g sug, ~400g
('shake_shack_chocolate_shake', 'Shake Shack Chocolate Shake', 187.5, 4.0, 19.0, 11.3, 0.0, 17.3, 400, 400, 'shakeshack.com', ARRAY['shake shack chocolate milkshake'], '750 cal per shake (~400g)'),
-- Strawberry Shake: 690cal, 17g pro, 77g carb, 35g fat, 0g fib, 75g sug, ~400g
('shake_shack_strawberry_shake', 'Shake Shack Strawberry Shake', 172.5, 4.3, 19.3, 8.8, 0.0, 18.8, 400, 400, 'shakeshack.com', ARRAY['shake shack strawberry milkshake'], '690 cal per shake (~400g)'),
-- Bacon Egg Cheese: 400cal, 23g pro, 25g carb, 23g fat, 2g fib, 5g sug, ~170g
('shake_shack_bacon_egg_cheese', 'Shake Shack Bacon Egg & Cheese Sandwich', 235.3, 13.5, 14.7, 13.5, 1.2, 2.9, 170, 170, 'shakeshack.com', ARRAY['shake shack breakfast sandwich', 'shake shack bec'], '400 cal per sandwich (~170g)'),

-- =============================================
-- 4. IN-N-OUT BURGER (in-n-out.com)
-- =============================================

-- Hamburger with Onion: 360cal, 16g pro, 37g carb, 16g fat, 2g fib, 8g sug, ~200g
('in_n_out_hamburger', 'In-N-Out Hamburger', 180.0, 8.0, 18.5, 8.0, 1.0, 4.0, 200, 200, 'in-n-out.com', ARRAY['in n out hamburger', 'in n out burger', 'innout burger'], '360 cal per burger (~200g)'),
-- Cheeseburger with Onion: 430cal, 20g pro, 39g carb, 21g fat, 2g fib, 8g sug, ~215g
('in_n_out_cheeseburger', 'In-N-Out Cheeseburger', 200.0, 9.3, 18.1, 9.8, 0.9, 3.7, 215, 215, 'in-n-out.com', ARRAY['in n out cheeseburger', 'innout cheeseburger'], '430 cal per burger (~215g)'),
-- Double-Double with Onion: 610cal, 34g pro, 41g carb, 34g fat, 2g fib, 8g sug, ~310g
('in_n_out_double_double', 'In-N-Out Double-Double', 196.8, 11.0, 13.2, 11.0, 0.6, 2.6, 310, 310, 'in-n-out.com', ARRAY['in n out double double', 'innout double double', 'double double'], '610 cal per burger (~310g)'),
-- Hamburger Protein Style: 200cal, 12g pro, 8g carb, 14g fat, 2g fib, 5g sug, ~160g
('in_n_out_hamburger_protein_style', 'In-N-Out Hamburger Protein Style', 125.0, 7.5, 5.0, 8.8, 1.3, 3.1, 160, 160, 'in-n-out.com', ARRAY['in n out protein style', 'innout lettuce wrap burger'], '200 cal per burger wrapped in lettuce (~160g)'),
-- Cheeseburger Protein Style: 270cal, 16g pro, 10g carb, 19g fat, 2g fib, 6g sug, ~175g
('in_n_out_cheeseburger_protein_style', 'In-N-Out Cheeseburger Protein Style', 154.3, 9.1, 5.7, 10.9, 1.1, 3.4, 175, 175, 'in-n-out.com', ARRAY['in n out cheese protein style', 'innout cheese protein style'], '270 cal per burger wrapped in lettuce (~175g)'),
-- Double-Double Protein Style: 450cal, 30g pro, 12g carb, 32g fat, 2g fib, 6g sug, ~270g
('in_n_out_double_double_protein_style', 'In-N-Out Double-Double Protein Style', 166.7, 11.1, 4.4, 11.9, 0.7, 2.2, 270, 270, 'in-n-out.com', ARRAY['in n out double double protein style', 'innout double double lettuce wrap'], '450 cal per burger wrapped in lettuce (~270g)'),
-- Hamburger Animal Style: ~480cal, 18g pro, 42g carb, 27g fat, 2g fib, 10g sug, ~240g
('in_n_out_hamburger_animal_style', 'In-N-Out Hamburger Animal Style', 200.0, 7.5, 17.5, 11.3, 0.8, 4.2, 240, 240, 'in-n-out.com', ARRAY['in n out animal style', 'innout animal style burger'], '~480 cal per animal style burger (~240g)'),
-- Double-Double Animal Style: ~770cal, 38g pro, 43g carb, 50g fat, 2g fib, 10g sug, ~360g
('in_n_out_double_double_animal_style', 'In-N-Out Double-Double Animal Style', 213.9, 10.6, 11.9, 13.9, 0.6, 2.8, 360, 360, 'in-n-out.com', ARRAY['in n out double double animal style', 'innout double double animal'], '~770 cal per animal style double-double (~360g)'),
-- 3x3: ~830cal, 49g pro, 42g carb, 52g fat, 2g fib, 8g sug, ~400g
('in_n_out_3x3', 'In-N-Out 3x3', 207.5, 12.3, 10.5, 13.0, 0.5, 2.0, 400, 400, 'in-n-out.com', ARRAY['in n out 3x3', 'innout triple triple', 'in n out 3 by 3'], '~830 cal per 3x3 burger (~400g)'),
-- 4x4: ~1020cal, 63g pro, 43g carb, 68g fat, 2g fib, 9g sug, ~500g
('in_n_out_4x4', 'In-N-Out 4x4', 204.0, 12.6, 8.6, 13.6, 0.4, 1.8, 500, 500, 'in-n-out.com', ARRAY['in n out 4x4', 'innout quad quad', 'in n out 4 by 4'], '~1020 cal per 4x4 burger (~500g)'),
-- French Fries: 360cal, 6g pro, 49g carb, 15g fat, 6g fib, 0g sug, ~125g
('in_n_out_fries', 'In-N-Out French Fries', 288.0, 4.8, 39.2, 12.0, 4.8, 0.0, 125, 125, 'in-n-out.com', ARRAY['in n out fries', 'innout fries', 'in n out french fries'], '360 cal per order (~125g)'),
-- Animal Style Fries: ~750cal, 19g pro, 52g carb, 52g fat, 6g fib, 5g sug, ~280g
('in_n_out_animal_fries', 'In-N-Out Animal Style Fries', 267.9, 6.8, 18.6, 18.6, 2.1, 1.8, 280, 280, 'in-n-out.com', ARRAY['in n out animal fries', 'innout animal fries'], '~750 cal per order (~280g)'),
-- Chocolate Shake: 590cal, 16g pro, 66g carb, 30g fat, 0g fib, 55g sug, ~425g
('in_n_out_chocolate_shake', 'In-N-Out Chocolate Shake', 138.8, 3.8, 15.5, 7.1, 0.0, 12.9, 425, 425, 'in-n-out.com', ARRAY['in n out chocolate shake', 'innout chocolate milkshake'], '590 cal per shake (~425g)'),
-- Vanilla Shake: 610cal, 15g pro, 69g carb, 31g fat, 0g fib, 63g sug, ~425g
('in_n_out_vanilla_shake', 'In-N-Out Vanilla Shake', 143.5, 3.5, 16.2, 7.3, 0.0, 14.8, 425, 425, 'in-n-out.com', ARRAY['in n out vanilla shake', 'innout vanilla milkshake'], '610 cal per shake (~425g)'),
-- Strawberry Shake: 600cal, 15g pro, 74g carb, 30g fat, 0g fib, 62g sug, ~425g
('in_n_out_strawberry_shake', 'In-N-Out Strawberry Shake', 141.2, 3.5, 17.4, 7.1, 0.0, 14.6, 425, 425, 'in-n-out.com', ARRAY['in n out strawberry shake', 'innout strawberry milkshake'], '600 cal per shake (~425g)'),

-- =============================================
-- 5. NOODLES & COMPANY (noodles.com)
-- =============================================

-- Wisconsin Mac & Cheese Reg: 981cal, 42g pro, 119g carb, 38g fat, 5g fib, 11g sug, ~400g
('noodles_co_wisconsin_mac_cheese', 'Noodles & Company Wisconsin Mac & Cheese (Regular)', 245.3, 10.5, 29.8, 9.5, 1.3, 2.8, 400, 400, 'noodles.com', ARRAY['noodles company mac and cheese', 'noodles co mac cheese'], '981 cal per regular bowl (~400g)'),
-- Japanese Pan Noodles Reg: 641cal, 20g pro, 114g carb, 12g fat, 6g fib, 22g sug, ~400g
('noodles_co_japanese_pan_noodles', 'Noodles & Company Japanese Pan Noodles (Regular)', 160.3, 5.0, 28.5, 3.0, 1.5, 5.5, 400, 400, 'noodles.com', ARRAY['noodles company japanese pan noodles', 'noodles co pan noodles'], '641 cal per regular bowl (~400g)'),
-- Pesto Cavatappi Reg: 731cal, 23g pro, 93g carb, 31g fat, 7g fib, 7g sug, ~400g
('noodles_co_pesto_cavatappi', 'Noodles & Company Pesto Cavatappi (Regular)', 182.8, 5.8, 23.3, 7.8, 1.8, 1.8, 400, 400, 'noodles.com', ARRAY['noodles company pesto cavatappi', 'noodles co pesto pasta'], '731 cal per regular bowl (~400g)'),
-- Penne Rosa Reg: 721cal, 23g pro, 103g carb, 24g fat, 5g fib, 10g sug, ~400g
('noodles_co_penne_rosa', 'Noodles & Company Penne Rosa (Regular)', 180.3, 5.8, 25.8, 6.0, 1.3, 2.5, 400, 400, 'noodles.com', ARRAY['noodles company penne rosa', 'noodles co penne rosa'], '721 cal per regular bowl (~400g)'),
-- Spaghetti & Meatballs Reg: 981cal, 35g pro, 102g carb, 48g fat, 4g fib, 16g sug, ~400g
('noodles_co_spaghetti_meatballs', 'Noodles & Company Spaghetti & Meatballs (Regular)', 245.3, 8.8, 25.5, 12.0, 1.0, 4.0, 400, 400, 'noodles.com', ARRAY['noodles company spaghetti meatballs', 'noodles co spaghetti'], '981 cal per regular bowl (~400g)'),
-- Spicy Korean Beef Noodles Reg: 881cal, 30g pro, 112g carb, 34g fat, 4g fib, 43g sug, ~400g
('noodles_co_spicy_korean_beef', 'Noodles & Company Spicy Korean Beef Noodles (Regular)', 220.3, 7.5, 28.0, 8.5, 1.0, 10.8, 400, 400, 'noodles.com', ARRAY['noodles company korean beef', 'noodles co spicy korean'], '881 cal per regular bowl (~400g)'),
-- Buttered Egg Noodles Reg: 761cal, 22g pro, 98g carb, 35g fat, 4g fib, 6g sug, ~400g
('noodles_co_buttered_egg_noodles', 'Noodles & Company Buttered Egg Noodles (Regular)', 190.3, 5.5, 24.5, 8.8, 1.0, 1.5, 400, 400, 'noodles.com', ARRAY['noodles company buttered noodles', 'noodles co butter noodles'], '761 cal per regular bowl (~400g)'),
-- Steak Stroganoff Reg: 1201cal, 45g pro, 116g carb, 67g fat, 7g fib, 14g sug, ~400g
('noodles_co_steak_stroganoff', 'Noodles & Company Steak Stroganoff (Regular)', 300.3, 11.3, 29.0, 16.8, 1.8, 3.5, 400, 400, 'noodles.com', ARRAY['noodles company stroganoff', 'noodles co steak stroganoff'], '1201 cal per regular bowl (~400g)'),
-- Orange Chicken Lo Mein Reg: 841cal, 40g pro, 106g carb, 28g fat, 4g fib, 37g sug, ~400g
('noodles_co_orange_chicken_lo_mein', 'Noodles & Company Grilled Orange Chicken Lo Mein (Regular)', 210.3, 10.0, 26.5, 7.0, 1.0, 9.3, 400, 400, 'noodles.com', ARRAY['noodles company orange chicken', 'noodles co lo mein'], '841 cal per regular bowl (~400g)'),
-- Alfredo MontAmore w/ Chicken Reg: 1411cal, 52g pro, 110g carb, 84g fat, 6g fib, 14g sug, ~400g
('noodles_co_alfredo_montamore_chicken', 'Noodles & Company Alfredo MontAmore with Chicken (Regular)', 352.8, 13.0, 27.5, 21.0, 1.5, 3.5, 400, 400, 'noodles.com', ARRAY['noodles company alfredo chicken', 'noodles co alfredo'], '1411 cal per regular bowl (~400g)'),
-- 3-Cheese Tortelloni Pesto Reg: 790cal, 35g pro, 74g carb, 41g fat, 4g fib, 6g sug, ~400g
('noodles_co_tortelloni_pesto', 'Noodles & Company 3-Cheese Tortelloni Pesto (Regular)', 197.5, 8.8, 18.5, 10.3, 1.0, 1.5, 400, 400, 'noodles.com', ARRAY['noodles company tortelloni', 'noodles co cheese tortelloni'], '790 cal per regular bowl (~400g)'),
-- BBQ Pork Mac Reg: 1211cal, 64g pro, 129g carb, 47g fat, 5g fib, 18g sug, ~400g
('noodles_co_bbq_pork_mac', 'Noodles & Company BBQ Pork Mac & Cheese (Regular)', 302.8, 16.0, 32.3, 11.8, 1.3, 4.5, 400, 400, 'noodles.com', ARRAY['noodles company bbq mac cheese', 'noodles co bbq pork mac'], '1211 cal per regular bowl (~400g)'),
-- Potstickers Reg: 380cal, 16g pro, 54g carb, 10g fat, 2g fib, 14g sug, ~200g
('noodles_co_potstickers', 'Noodles & Company Potstickers (Regular)', 190.0, 8.0, 27.0, 5.0, 1.0, 7.0, 200, 200, 'noodles.com', ARRAY['noodles company potstickers', 'noodles co dumplings'], '380 cal per regular order (~200g)'),
-- Cheesy Garlic Bread Reg: 701cal, 22g pro, 81g carb, 33g fat, 4g fib, 3g sug, ~200g
('noodles_co_cheesy_garlic_bread', 'Noodles & Company Cheesy Garlic Bread (Regular)', 350.5, 11.0, 40.5, 16.5, 2.0, 1.5, 200, 200, 'noodles.com', ARRAY['noodles company garlic bread', 'noodles co cheesy bread'], '701 cal per regular order (~200g)'),
-- Chicken Noodle Soup Reg: 360cal, 30g pro, 41g carb, 10g fat, 2g fib, 9g sug, ~400g
('noodles_co_chicken_noodle_soup', 'Noodles & Company Chicken Noodle Soup (Regular)', 90.0, 7.5, 10.3, 2.5, 0.5, 2.3, 400, 400, 'noodles.com', ARRAY['noodles company chicken soup'], '360 cal per regular bowl (~400g)'),
-- Tomato Basil Bisque Reg: ~430cal, 8g pro, 38g carb, 28g fat, 3g fib, 15g sug, ~400g
('noodles_co_tomato_bisque', 'Noodles & Company Tomato Basil Bisque (Regular)', 107.5, 2.0, 9.5, 7.0, 0.8, 3.8, 400, 400, 'noodles.com', ARRAY['noodles company tomato soup', 'noodles co tomato bisque'], '~430 cal per regular bowl (~400g)'),
-- Caesar Chicken Salad Reg: 420cal, 28g pro, 18g carb, 27g fat, 3g fib, 4g sug, ~300g
('noodles_co_caesar_chicken_salad', 'Noodles & Company Caesar Chicken Salad (Regular)', 140.0, 9.3, 6.0, 9.0, 1.0, 1.3, 300, 300, 'noodles.com', ARRAY['noodles company caesar salad', 'noodles co chicken caesar'], '420 cal per regular salad (~300g)'),

-- =============================================
-- 6. WAFFLE HOUSE (wafflehouse.com)
-- =============================================

-- Classic Waffle: 410cal, 8g pro, 55g carb, 18g fat, 2g fib, 15g sug, ~120g
('waffle_house_classic_waffle', 'Waffle House Classic Waffle', 341.7, 6.7, 45.8, 15.0, 1.7, 12.5, 120, 120, 'wafflehouse.com', ARRAY['waffle house waffle', 'waffle house plain waffle'], '410 cal per waffle (~120g)'),
-- Pecan Waffle: ~480cal, 10g pro, 58g carb, 24g fat, 3g fib, 16g sug, ~135g
('waffle_house_pecan_waffle', 'Waffle House Pecan Waffle', 355.6, 7.4, 43.0, 17.8, 2.2, 11.9, 135, 135, 'wafflehouse.com', ARRAY['waffle house pecan waffle'], '~480 cal per waffle (~135g)'),
-- Chocolate Chip Waffle: ~530cal, 9g pro, 72g carb, 24g fat, 3g fib, 30g sug, ~140g
('waffle_house_chocolate_chip_waffle', 'Waffle House Chocolate Chip Waffle', 378.6, 6.4, 51.4, 17.1, 2.1, 21.4, 140, 140, 'wafflehouse.com', ARRAY['waffle house choc chip waffle'], '~530 cal per waffle (~140g)'),
-- 2 Scrambled Eggs: 180cal, 13g pro, 1g carb, 14g fat, 0g fib, 1g sug, ~100g
('waffle_house_2_scrambled_eggs', 'Waffle House 2 Scrambled Eggs', 180.0, 13.0, 1.0, 14.0, 0.0, 1.0, 100, 100, 'wafflehouse.com', ARRAY['waffle house eggs', 'waffle house scrambled eggs'], '180 cal per 2 eggs (~100g)'),
-- Bacon: 140cal, 8g pro, 0g carb, 12g fat, 0g fib, 0g sug, ~25g
('waffle_house_bacon', 'Waffle House Bacon', 560.0, 32.0, 0.0, 48.0, 0.0, 0.0, 25, 25, 'wafflehouse.com', ARRAY['waffle house bacon'], '140 cal per serving (~25g)'),
-- Sausage Patty: 260cal, 15g pro, 0g carb, 22g fat, 0g fib, 0g sug, ~60g
('waffle_house_sausage', 'Waffle House Sausage Patty', 433.3, 25.0, 0.0, 36.7, 0.0, 0.0, 60, 60, 'wafflehouse.com', ARRAY['waffle house sausage'], '260 cal per patty (~60g)'),
-- Hashbrowns Regular: 190cal, 3g pro, 29g carb, 7g fat, 3g fib, 0g sug, ~100g
('waffle_house_hashbrowns', 'Waffle House Hashbrowns', 190.0, 3.0, 29.0, 7.0, 3.0, 0.0, 100, 100, 'wafflehouse.com', ARRAY['waffle house hash browns', 'waffle house scattered hashbrowns'], '190 cal per regular order (~100g)'),
-- Hashbrowns SMC: 255cal, 6g pro, 32g carb, 11g fat, 3g fib, 1g sug, ~130g
('waffle_house_hashbrowns_smc', 'Waffle House Hashbrowns Scattered Smothered & Covered', 196.2, 4.6, 24.6, 8.5, 2.3, 0.8, 130, 130, 'wafflehouse.com', ARRAY['waffle house smothered covered hashbrowns', 'waffle house hashbrowns smc'], '255 cal per order with onions and cheese (~130g)'),
-- Sausage Egg Cheese Bowl: 921cal, 27g pro, 63g carb, 60g fat, 5g fib, 4g sug, ~350g
('waffle_house_sausage_egg_cheese_bowl', 'Waffle House Sausage Egg & Cheese Hashbrown Bowl', 263.1, 7.7, 18.0, 17.1, 1.4, 1.1, 350, 350, 'wafflehouse.com', ARRAY['waffle house sausage bowl', 'waffle house hashbrown bowl'], '921 cal per bowl (~350g)'),
-- Bacon Egg Cheese Sandwich: 410cal, 21g pro, 27g carb, 25g fat, 1g fib, 4g sug, ~160g
('waffle_house_bacon_egg_cheese_sandwich', 'Waffle House Bacon Egg & Cheese Sandwich', 256.3, 13.1, 16.9, 15.6, 0.6, 2.5, 160, 160, 'wafflehouse.com', ARRAY['waffle house bec sandwich', 'waffle house breakfast sandwich'], '410 cal per sandwich (~160g)'),
-- Texas Angus Patty Melt: 730cal, 26g pro, 42g carb, 50g fat, 3g fib, 6g sug, ~250g
('waffle_house_texas_patty_melt', 'Waffle House Texas Angus Patty Melt', 292.0, 10.4, 16.8, 20.0, 1.2, 2.4, 250, 250, 'wafflehouse.com', ARRAY['waffle house patty melt', 'waffle house texas melt'], '730 cal per patty melt (~250g)'),
-- Original Angus Hamburger: 466cal, 22g pro, 33g carb, 26g fat, 2g fib, 6g sug, ~200g
('waffle_house_hamburger', 'Waffle House Original Angus Hamburger', 233.0, 11.0, 16.5, 13.0, 1.0, 3.0, 200, 200, 'wafflehouse.com', ARRAY['waffle house burger', 'waffle house angus burger'], '466 cal per burger (~200g)'),
-- Double Cheeseburger Deluxe: 891cal, 46g pro, 48g carb, 56g fat, 3g fib, 8g sug, ~350g
('waffle_house_double_cheeseburger', 'Waffle House Double Angus Quarter Pound Cheeseburger Deluxe', 254.6, 13.1, 13.7, 16.0, 0.9, 2.3, 350, 350, 'wafflehouse.com', ARRAY['waffle house double cheeseburger', 'waffle house double burger'], '891 cal per double cheeseburger (~350g)'),
-- Grits: 90cal, 1g pro, 16g carb, 3g fat, 1g fib, 0g sug, ~150g
('waffle_house_grits', 'Waffle House Grits', 60.0, 0.7, 10.7, 2.0, 0.7, 0.0, 150, 150, 'wafflehouse.com', ARRAY['waffle house grits'], '90 cal per serving (~150g)'),
-- Grilled Biscuit: 380cal, 5g pro, 34g carb, 25g fat, 1g fib, 1g sug, ~80g
('waffle_house_biscuit', 'Waffle House Grilled Biscuit', 475.0, 6.3, 42.5, 31.3, 1.3, 1.3, 80, 80, 'wafflehouse.com', ARRAY['waffle house biscuit'], '380 cal per biscuit (~80g)'),
-- Sirloin Dinner: 616cal, 29g pro, 55g carb, 30g fat, 6g fib, 7g sug, ~350g
('waffle_house_sirloin_dinner', 'Waffle House Sirloin Steak Dinner', 176.0, 8.3, 15.7, 8.6, 1.7, 2.0, 350, 350, 'wafflehouse.com', ARRAY['waffle house steak dinner', 'waffle house sirloin'], '616 cal dinner with hashbrowns and toast (~350g)'),
-- T-Bone Dinner: 726cal, 35g pro, 55g carb, 42g fat, 6g fib, 7g sug, ~400g
('waffle_house_tbone_dinner', 'Waffle House T-Bone Steak Dinner', 181.5, 8.8, 13.8, 10.5, 1.5, 1.8, 400, 400, 'wafflehouse.com', ARRAY['waffle house t bone dinner', 'waffle house tbone'], '726 cal dinner with hashbrowns and toast (~400g)'),

-- =============================================
-- 7. CRUMBL COOKIES (crumblcookies.com)
-- =============================================

-- Classic Pink Sugar: 760cal, 8g pro, 120g carb, 28g fat, 0g fib, 76g sug, ~176g
('crumbl_classic_pink_sugar', 'Crumbl Classic Pink Sugar Cookie', 431.8, 4.5, 68.2, 15.9, 0.0, 43.2, 176, 176, 'crumblcookies.com', ARRAY['crumbl pink sugar', 'crumbl sugar cookie', 'crumbl classic sugar'], '760 cal per whole cookie (~176g)'),
-- Milk Chocolate Chip: 680cal, 12g pro, 96g carb, 32g fat, 4g fib, 52g sug, ~156g
('crumbl_milk_chocolate_chip', 'Crumbl Milk Chocolate Chip Cookie', 435.9, 7.7, 61.5, 20.5, 2.6, 33.3, 156, 156, 'crumblcookies.com', ARRAY['crumbl chocolate chip', 'crumbl choc chip cookie'], '680 cal per whole cookie (~156g)'),
-- Cookies & Cream: ~740cal, 8g pro, 104g carb, 32g fat, 2g fib, 64g sug, ~170g
('crumbl_cookies_and_cream', 'Crumbl Cookies & Cream Cookie', 435.3, 4.7, 61.2, 18.8, 1.2, 37.6, 170, 170, 'crumblcookies.com', ARRAY['crumbl oreo cookie', 'crumbl cookies cream'], '~740 cal per whole cookie (~170g)'),
-- Snickerdoodle: ~680cal, 8g pro, 100g carb, 28g fat, 0g fib, 56g sug, ~160g
('crumbl_snickerdoodle', 'Crumbl Snickerdoodle Cookie', 425.0, 5.0, 62.5, 17.5, 0.0, 35.0, 160, 160, 'crumblcookies.com', ARRAY['crumbl snickerdoodle'], '~680 cal per whole cookie (~160g)'),
-- Peanut Butter: ~720cal, 16g pro, 84g carb, 36g fat, 4g fib, 52g sug, ~165g
('crumbl_peanut_butter', 'Crumbl Peanut Butter Cookie', 436.4, 9.7, 50.9, 21.8, 2.4, 31.5, 165, 165, 'crumblcookies.com', ARRAY['crumbl pb cookie', 'crumbl peanut butter cookie'], '~720 cal per whole cookie (~165g)'),
-- Churro: ~700cal, 8g pro, 104g carb, 28g fat, 2g fib, 60g sug, ~165g
('crumbl_churro', 'Crumbl Churro Cookie', 424.2, 4.8, 63.0, 17.0, 1.2, 36.4, 165, 165, 'crumblcookies.com', ARRAY['crumbl churro cookie'], '~700 cal per whole cookie (~165g)'),
-- Lemon Glaze: ~700cal, 6g pro, 108g carb, 26g fat, 0g fib, 68g sug, ~170g
('crumbl_lemon_glaze', 'Crumbl Lemon Glaze Cookie', 411.8, 3.5, 63.5, 15.3, 0.0, 40.0, 170, 170, 'crumblcookies.com', ARRAY['crumbl lemon cookie', 'crumbl lemon glaze'], '~700 cal per whole cookie (~170g)'),
-- Cinnamon Fry Bread: ~720cal, 8g pro, 100g carb, 32g fat, 2g fib, 52g sug, ~170g
('crumbl_cinnamon_fry_bread', 'Crumbl Cinnamon Fry Bread Cookie', 423.5, 4.7, 58.8, 18.8, 1.2, 30.6, 170, 170, 'crumblcookies.com', ARRAY['crumbl cinnamon cookie', 'crumbl fry bread'], '~720 cal per whole cookie (~170g)'),
-- Semi-Sweet Chocolate Chunk: ~720cal, 10g pro, 96g carb, 34g fat, 4g fib, 56g sug, ~165g
('crumbl_semi_sweet_chocolate_chunk', 'Crumbl Semi-Sweet Chocolate Chunk Cookie', 436.4, 6.1, 58.2, 20.6, 2.4, 33.9, 165, 165, 'crumblcookies.com', ARRAY['crumbl chocolate chunk', 'crumbl semi sweet'], '~720 cal per whole cookie (~165g)'),
-- Confetti Cake: ~740cal, 8g pro, 108g carb, 30g fat, 0g fib, 72g sug, ~175g
('crumbl_confetti_cake', 'Crumbl Confetti Cake Cookie', 422.9, 4.6, 61.7, 17.1, 0.0, 41.1, 175, 175, 'crumblcookies.com', ARRAY['crumbl confetti cookie', 'crumbl birthday cake cookie', 'crumbl funfetti'], '~740 cal per whole cookie (~175g)'),

-- =============================================
-- 8. TROPICAL SMOOTHIE CAFE (tropicalsmoothiecafe.com)
-- =============================================

-- Detox Island Green 24oz: 190cal, 3g pro, 43g carb, 0g fat, 5g fib, 29g sug, ~680g
('tropical_smoothie_detox_island_green', 'Tropical Smoothie Cafe Detox Island Green', 27.9, 0.4, 6.3, 0.0, 0.7, 4.3, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie detox', 'tropical smoothie island green detox'], '190 cal per 24oz smoothie (~680g)'),
-- Island Green 24oz: 420cal, 3g pro, 102g carb, 0g fat, 4g fib, 88g sug, ~680g
('tropical_smoothie_island_green', 'Tropical Smoothie Cafe Island Green', 61.8, 0.4, 15.0, 0.0, 0.6, 12.9, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie island green regular'], '420 cal per 24oz smoothie (~680g)'),
-- Bahama Mama 24oz: 510cal, 2g pro, 115g carb, 4.5g fat, 3g fib, 109g sug, ~680g
('tropical_smoothie_bahama_mama', 'Tropical Smoothie Cafe Bahama Mama', 75.0, 0.3, 16.9, 0.7, 0.4, 16.0, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie bahama mama'], '510 cal per 24oz smoothie (~680g)'),
-- Acai Berry Boost 24oz: 470cal, 1g pro, 113g carb, 2g fat, 5g fib, 101g sug, ~680g
('tropical_smoothie_acai_berry_boost', 'Tropical Smoothie Cafe Acai Berry Boost', 69.1, 0.1, 16.6, 0.3, 0.7, 14.9, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie acai berry', 'tropical smoothie acai'], '470 cal per 24oz smoothie (~680g)'),
-- Peanut Butter Cup 24oz: 700cal, 10g pro, 131g carb, 18g fat, 7g fib, 108g sug, ~680g
('tropical_smoothie_peanut_butter_cup', 'Tropical Smoothie Cafe Peanut Butter Cup', 102.9, 1.5, 19.3, 2.6, 1.0, 15.9, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie pb cup', 'tropical smoothie peanut butter'], '700 cal per 24oz smoothie (~680g)'),
-- Mango Magic 24oz: 430cal, 3g pro, 103g carb, 0g fat, 2g fib, 94g sug, ~680g
('tropical_smoothie_mango_magic', 'Tropical Smoothie Cafe Mango Magic', 63.2, 0.4, 15.1, 0.0, 0.3, 13.8, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie mango', 'tropical smoothie mango magic'], '430 cal per 24oz smoothie (~680g)'),
-- Mocha Madness 24oz: 620cal, 6g pro, 143g carb, 5g fat, 3g fib, 118g sug, ~680g
('tropical_smoothie_mocha_madness', 'Tropical Smoothie Cafe Mocha Madness', 91.2, 0.9, 21.0, 0.7, 0.4, 17.4, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie mocha', 'tropical smoothie coffee smoothie'], '620 cal per 24oz smoothie (~680g)'),
-- Blueberry Bliss 24oz: 340cal, 1g pro, 85g carb, 0.5g fat, 4g fib, 75g sug, ~680g
('tropical_smoothie_blueberry_bliss', 'Tropical Smoothie Cafe Blueberry Bliss', 50.0, 0.1, 12.5, 0.1, 0.6, 11.0, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie blueberry'], '340 cal per 24oz smoothie (~680g)'),
-- Chia Banana Boost 24oz: 770cal, 15g pro, 128g carb, 26g fat, 15g fib, 91g sug, ~680g
('tropical_smoothie_chia_banana_boost', 'Tropical Smoothie Cafe Chia Banana Boost', 113.2, 2.2, 18.8, 3.8, 2.2, 13.4, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie chia banana', 'tropical smoothie chia'], '770 cal per 24oz smoothie (~680g)'),
-- Acai Bowl: 530cal, 4g pro, 100g carb, 17g fat, 11g fib, 55g sug, ~400g
('tropical_smoothie_acai_bowl', 'Tropical Smoothie Cafe Acai Bowl', 132.5, 1.0, 25.0, 4.3, 2.8, 13.8, 400, 400, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie acai bowl'], '530 cal per bowl (~400g)'),
-- PB Protein Crunch Bowl: 800cal, 32g pro, 71g carb, 45g fat, 9g fib, 39g sug, ~400g
('tropical_smoothie_pb_protein_bowl', 'Tropical Smoothie Cafe PB Protein Crunch Bowl', 200.0, 8.0, 17.8, 11.3, 2.3, 9.8, 400, 400, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie protein bowl', 'tropical smoothie peanut butter bowl'], '800 cal per bowl (~400g)'),
-- Dragon Fruit Bowl: 350cal, 4g pro, 77g carb, 5g fat, 5g fib, 48g sug, ~350g
('tropical_smoothie_dragon_fruit_bowl', 'Tropical Smoothie Cafe Dragon Fruit Bowl', 100.0, 1.1, 22.0, 1.4, 1.4, 13.7, 350, 350, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie dragon fruit', 'tropical smoothie pitaya bowl'], '350 cal per bowl (~350g)'),
-- Baja Chicken Wrap: 760cal, 38g pro, 83g carb, 30g fat, 7g fib, 8g sug, ~250g
('tropical_smoothie_baja_chicken_wrap', 'Tropical Smoothie Cafe Baja Chicken Wrap', 304.0, 15.2, 33.2, 12.0, 2.8, 3.2, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie baja wrap', 'tropical smoothie baja chicken'], '760 cal per wrap (~250g)'),
-- Buffalo Chicken Wrap: 620cal, 33g pro, 59g carb, 27g fat, 3g fib, 7g sug, ~250g
('tropical_smoothie_buffalo_chicken_wrap', 'Tropical Smoothie Cafe Buffalo Chicken Wrap', 248.0, 13.2, 23.6, 10.8, 1.2, 2.8, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie buffalo wrap'], '620 cal per wrap (~250g)'),
-- Thai Chicken Wrap: 600cal, 31g pro, 77g carb, 19g fat, 3g fib, 15g sug, ~250g
('tropical_smoothie_thai_chicken_wrap', 'Tropical Smoothie Cafe Thai Chicken Wrap', 240.0, 12.4, 30.8, 7.6, 1.2, 6.0, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie thai wrap', 'tropical smoothie thai chicken'], '600 cal per wrap (~250g)'),
-- Caesar Wrap: 750cal, 43g pro, 55g carb, 39g fat, 3g fib, 5g sug, ~250g
('tropical_smoothie_caesar_wrap', 'Tropical Smoothie Cafe Supergreen Caesar Chicken Wrap', 300.0, 17.2, 22.0, 15.6, 1.2, 2.0, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie caesar wrap', 'tropical smoothie caesar chicken'], '750 cal per wrap (~250g)'),
-- Hummus Veggie Wrap: 830cal, 23g pro, 95g carb, 41g fat, 11g fib, 11g sug, ~250g
('tropical_smoothie_hummus_veggie_wrap', 'Tropical Smoothie Cafe Hummus Veggie Wrap', 332.0, 9.2, 38.0, 16.4, 4.4, 4.4, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie veggie wrap', 'tropical smoothie hummus wrap'], '830 cal per wrap (~250g)'),
-- Chicken Bacon Ranch Flatbread: 510cal, 28g pro, 47g carb, 23g fat, 3g fib, 3g sug, ~230g
('tropical_smoothie_chicken_bacon_ranch_flatbread', 'Tropical Smoothie Cafe Chicken Bacon Ranch Flatbread', 221.7, 12.2, 20.4, 10.0, 1.3, 1.3, 230, 230, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie bacon ranch flatbread'], '510 cal per flatbread (~230g)'),
-- Chicken Pesto Flatbread: 490cal, 26g pro, 46g carb, 22g fat, 3g fib, 4g sug, ~230g
('tropical_smoothie_chicken_pesto_flatbread', 'Tropical Smoothie Cafe Chicken Pesto Flatbread', 213.0, 11.3, 20.0, 9.6, 1.3, 1.7, 230, 230, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie pesto flatbread'], '490 cal per flatbread (~230g)'),
-- Chipotle Chicken Club Flatbread: 520cal, 27g pro, 46g carb, 25g fat, 3g fib, 2g sug, ~230g
('tropical_smoothie_chipotle_chicken_flatbread', 'Tropical Smoothie Cafe Chipotle Chicken Club Flatbread', 226.1, 11.7, 20.0, 10.9, 1.3, 0.9, 230, 230, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie chipotle flatbread'], '520 cal per flatbread (~230g)'),

-- =============================================
-- 9. PORTILLO'S (portillos.com)
-- =============================================

-- Italian Beef: 690cal, 33g pro, 59g carb, 34g fat, 0g fib, 2g sug, ~250g
('portillos_italian_beef', 'Portillo''s Italian Beef', 276.0, 13.2, 23.6, 13.6, 0.0, 0.8, 250, 250, 'portillos.com', ARRAY['portillos italian beef sandwich', 'portillos beef'], '690 cal per sandwich (~250g)'),
-- Big Beef: 1040cal, 50g pro, 88g carb, 51g fat, 0g fib, 3g sug, ~380g
('portillos_big_beef', 'Portillo''s Big Beef', 273.7, 13.2, 23.2, 13.4, 0.0, 0.8, 380, 380, 'portillos.com', ARRAY['portillos big beef sandwich', 'portillos large italian beef'], '1040 cal per large sandwich (~380g)'),
-- Beef & Sausage Combo: 860cal, 38g pro, 63g carb, 49g fat, 0g fib, 5g sug, ~300g
('portillos_beef_sausage_combo', 'Portillo''s Italian Beef & Sausage Combo', 286.7, 12.7, 21.0, 16.3, 0.0, 1.7, 300, 300, 'portillos.com', ARRAY['portillos combo sandwich', 'portillos beef and sausage'], '860 cal per combo (~300g)'),
-- Hot Dog with Everything: 340cal, 12g pro, 39g carb, 15g fat, 2g fib, 13g sug, ~150g
('portillos_hot_dog', 'Portillo''s Hot Dog with Everything', 226.7, 8.0, 26.0, 10.0, 1.3, 8.7, 150, 150, 'portillos.com', ARRAY['portillos chicago hot dog', 'portillos hot dog'], '340 cal per hot dog (~150g)'),
-- Jumbo Hot Dog: 450cal, 18g pro, 40g carb, 25g fat, 2g fib, 14g sug, ~180g
('portillos_jumbo_hot_dog', 'Portillo''s Jumbo Hot Dog with Everything', 250.0, 10.0, 22.2, 13.9, 1.1, 7.8, 180, 180, 'portillos.com', ARRAY['portillos jumbo dog', 'portillos jumbo hot dog'], '450 cal per jumbo hot dog (~180g)'),
-- Chili Cheese Dog: 510cal, 22g pro, 36g carb, 31g fat, 2g fib, 5g sug, ~180g
('portillos_chili_cheese_dog', 'Portillo''s Chili Cheese Dog', 283.3, 12.2, 20.0, 17.2, 1.1, 2.8, 180, 180, 'portillos.com', ARRAY['portillos chili dog', 'portillos chili cheese hot dog'], '510 cal per chili cheese dog (~180g)'),
-- Single Hamburger: 590cal, 35g pro, 50g carb, 27g fat, 3g fib, 8g sug, ~230g
('portillos_hamburger', 'Portillo''s Single Hamburger', 256.5, 15.2, 21.7, 11.7, 1.3, 3.5, 230, 230, 'portillos.com', ARRAY['portillos burger', 'portillos hamburger'], '590 cal per burger (~230g)'),
-- Double Hamburger: 920cal, 62g pro, 50g carb, 51g fat, 3g fib, 8g sug, ~350g
('portillos_double_hamburger', 'Portillo''s Double Hamburger', 262.9, 17.7, 14.3, 14.6, 0.9, 2.3, 350, 350, 'portillos.com', ARRAY['portillos double burger'], '920 cal per double burger (~350g)'),
-- Single Bacon Burger: 700cal, 42g pro, 46g carb, 37g fat, 2g fib, 6g sug, ~250g
('portillos_bacon_burger', 'Portillo''s Single Bacon Burger', 280.0, 16.8, 18.4, 14.8, 0.8, 2.4, 250, 250, 'portillos.com', ARRAY['portillos bacon cheeseburger', 'portillos bacon burger'], '700 cal per burger (~250g)'),
-- Famous Chocolate Cake: 720cal, 6g pro, 86g carb, 37g fat, 4g fib, 64g sug, ~200g
('portillos_chocolate_cake', 'Portillo''s Famous Chocolate Cake', 360.0, 3.0, 43.0, 18.5, 2.0, 32.0, 200, 200, 'portillos.com', ARRAY['portillos cake', 'portillos chocolate cake slice'], '720 cal per slice (~200g)'),
-- Chocolate Eclair Cake: 520cal, 6g pro, 83g carb, 18g fat, 4g fib, 51g sug, ~200g
('portillos_eclair_cake', 'Portillo''s Chocolate Eclair Cake', 260.0, 3.0, 41.5, 9.0, 2.0, 25.5, 200, 200, 'portillos.com', ARRAY['portillos eclair cake', 'portillos eclair'], '520 cal per slice (~200g)'),
-- Small Fries: 340cal, 3g pro, 43g carb, 19g fat, 4g fib, 2g sug, ~120g
('portillos_fries_small', 'Portillo''s French Fries (Small)', 283.3, 2.5, 35.8, 15.8, 3.3, 1.7, 120, 120, 'portillos.com', ARRAY['portillos fries', 'portillos french fries'], '340 cal per small order (~120g)'),
-- Large Fries: 480cal, 5g pro, 61g carb, 27g fat, 5g fib, 3g sug, ~170g
('portillos_fries_large', 'Portillo''s French Fries (Large)', 282.4, 2.9, 35.9, 15.9, 2.9, 1.8, 170, 170, 'portillos.com', ARRAY['portillos large fries'], '480 cal per large order (~170g)'),
-- Chopped Salad: 510cal, 42g pro, 37g carb, 20g fat, 6g fib, 8g sug, ~350g
('portillos_chopped_salad', 'Portillo''s Chopped Salad', 145.7, 12.0, 10.6, 5.7, 1.7, 2.3, 350, 350, 'portillos.com', ARRAY['portillos salad', 'portillos chopped salad'], '510 cal per salad without dressing (~350g)'),

-- =============================================
-- 10. STEAK 'N SHAKE (steaknshake.com)
-- DO NOT DUPLICATE: steak_n_shake_cheese_fries, steak_n_shake_chicken_fingers_3pc,
--                    steak_n_shake_side_cheese_sauce, steak_n_shake_garlic_double
-- =============================================

-- Single with Cheese: 390cal, 19g pro, 32g carb, 20g fat, 3g fib, 6g sug, ~170g
('steak_n_shake_single_cheese', 'Steak ''n Shake Single Steakburger with Cheese', 229.4, 11.2, 18.8, 11.8, 1.8, 3.5, 170, 170, 'steaknshake.com', ARRAY['steak n shake single cheeseburger', 'steak n shake single with cheese'], '390 cal per single steakburger (~170g)'),
-- Original Double: 460cal, 23g pro, 33g carb, 26g fat, 2g fib, 6g sug, ~210g
('steak_n_shake_original_double', 'Steak ''n Shake Original Double Steakburger', 219.0, 11.0, 15.7, 12.4, 1.0, 2.9, 210, 210, 'steaknshake.com', ARRAY['steak n shake double steakburger', 'steak n shake double'], '460 cal per double steakburger (~210g)'),
-- Triple with Cheese: 750cal, 40g pro, 32g carb, 50g fat, 3g fib, 6g sug, ~290g
('steak_n_shake_triple_cheese', 'Steak ''n Shake Triple Steakburger with Cheese', 258.6, 13.8, 11.0, 17.2, 1.0, 2.1, 290, 290, 'steaknshake.com', ARRAY['steak n shake triple cheeseburger', 'steak n shake triple'], '750 cal per triple steakburger (~290g)'),
-- Bacon N Cheese Single: 460cal, 25g pro, 29g carb, 26g fat, 1g fib, 4g sug, ~180g
('steak_n_shake_bacon_cheese_single', 'Steak ''n Shake Bacon N Cheese Single Steakburger', 255.6, 13.9, 16.1, 14.4, 0.6, 2.2, 180, 180, 'steaknshake.com', ARRAY['steak n shake bacon cheeseburger', 'steak n shake bacon cheese'], '460 cal per single steakburger (~180g)'),
-- Bacon N Cheese Double: 600cal, 34g pro, 29g carb, 38g fat, 1g fib, 4g sug, ~230g
('steak_n_shake_bacon_cheese_double', 'Steak ''n Shake Bacon N Cheese Double Steakburger', 260.9, 14.8, 12.6, 16.5, 0.4, 1.7, 230, 230, 'steaknshake.com', ARRAY['steak n shake double bacon cheese'], '600 cal per double steakburger (~230g)'),
-- Western BBQ N Bacon: 790cal, 35g pro, 54g carb, 43g fat, 1g fib, 23g sug, ~270g
('steak_n_shake_western_bbq', 'Steak ''n Shake Western BBQ N Bacon Steakburger', 292.6, 13.0, 20.0, 15.9, 0.4, 8.5, 270, 270, 'steaknshake.com', ARRAY['steak n shake western bbq burger', 'steak n shake bbq bacon'], '790 cal per steakburger (~270g)'),
-- Small French Fries: 240cal, 2g pro, 30g carb, 13g fat, 3g fib, 0g sug, ~90g
('steak_n_shake_fries_small', 'Steak ''n Shake French Fries (Small)', 266.7, 2.2, 33.3, 14.4, 3.3, 0.0, 90, 90, 'steaknshake.com', ARRAY['steak n shake small fries'], '240 cal per small order (~90g)'),
-- Medium French Fries: 450cal, 4g pro, 54g carb, 24g fat, 5g fib, 1g sug, ~160g
('steak_n_shake_fries_medium', 'Steak ''n Shake French Fries (Medium)', 281.3, 2.5, 33.8, 15.0, 3.1, 0.6, 160, 160, 'steaknshake.com', ARRAY['steak n shake medium fries', 'steak n shake fries'], '450 cal per medium order (~160g)'),
-- Onion Rings Medium: 330cal, 4g pro, 39g carb, 17g fat, 2g fib, 3g sug, ~120g
('steak_n_shake_onion_rings', 'Steak ''n Shake Onion Rings (Medium)', 275.0, 3.3, 32.5, 14.2, 1.7, 2.5, 120, 120, 'steaknshake.com', ARRAY['steak n shake onion rings'], '330 cal per medium order (~120g)'),
-- Chicken Fingers 5pc: 550cal, 35g pro, 37g carb, 30g fat, 3g fib, 0g sug, ~200g
('steak_n_shake_chicken_fingers_5pc', 'Steak ''n Shake Chicken Fingers (5 piece)', 275.0, 17.5, 18.5, 15.0, 1.5, 0.0, 200, 200, 'steaknshake.com', ARRAY['steak n shake 5 piece chicken', 'steak n shake chicken strips 5pc'], '550 cal per 5-piece serving (~200g)'),
-- Chili Cheese Frank: 710cal, 33g pro, 46g carb, 44g fat, 4g fib, 5g sug, ~200g
('steak_n_shake_chili_cheese_frank', 'Steak ''n Shake Steak Frank Chili Cheese', 355.0, 16.5, 23.0, 22.0, 2.0, 2.5, 200, 200, 'steaknshake.com', ARRAY['steak n shake chili dog', 'steak n shake hot dog'], '710 cal per chili cheese frank (~200g)'),
-- Chili 3-Way: 710cal, 31g pro, 98g carb, 21g fat, 13g fib, 10g sug, ~350g
('steak_n_shake_chili_3way', 'Steak ''n Shake Chili 3-Way', 202.9, 8.9, 28.0, 6.0, 3.7, 2.9, 350, 350, 'steaknshake.com', ARRAY['steak n shake chili', 'steak n shake 3 way chili'], '710 cal with spaghetti and cheese (~350g)'),
-- Grilled Cheese N Bacon: 590cal, 24g pro, 41g carb, 35g fat, 2g fib, 2g sug, ~180g
('steak_n_shake_grilled_cheese_bacon', 'Steak ''n Shake Grilled Cheese N Bacon', 327.8, 13.3, 22.8, 19.4, 1.1, 1.1, 180, 180, 'steaknshake.com', ARRAY['steak n shake grilled cheese', 'steak n shake bacon grilled cheese'], '590 cal per sandwich (~180g)'),
-- Vanilla Shake Regular: 620cal, 37g pro, 105g carb, 17g fat, 0g fib, 93g sug, ~450g
('steak_n_shake_vanilla_shake', 'Steak ''n Shake Vanilla Milkshake (Regular)', 137.8, 8.2, 23.3, 3.8, 0.0, 20.7, 450, 450, 'steaknshake.com', ARRAY['steak n shake vanilla milkshake'], '620 cal per regular shake (~450g)'),
-- Chocolate Shake Regular: 600cal, 38g pro, 101g carb, 17g fat, 1g fib, 84g sug, ~450g
('steak_n_shake_chocolate_shake', 'Steak ''n Shake Chocolate Milkshake (Regular)', 133.3, 8.4, 22.4, 3.8, 0.2, 18.7, 450, 450, 'steaknshake.com', ARRAY['steak n shake chocolate milkshake'], '600 cal per regular shake (~450g)'),
-- Strawberry Shake Regular: 610cal, 37g pro, 103g carb, 17g fat, 0g fib, 94g sug, ~450g
('steak_n_shake_strawberry_shake', 'Steak ''n Shake Strawberry Milkshake (Regular)', 135.6, 8.2, 22.9, 3.8, 0.0, 20.9, 450, 450, 'steaknshake.com', ARRAY['steak n shake strawberry milkshake'], '610 cal per regular shake (~450g)'),
-- Reese's PB Shake Regular: 900cal, 47g pro, 98g carb, 47g fat, 3g fib, 83g sug, ~500g
('steak_n_shake_reeses_pb_shake', 'Steak ''n Shake Reese''s Peanut Butter Milkshake (Regular)', 180.0, 9.4, 19.6, 9.4, 0.6, 16.6, 500, 500, 'steaknshake.com', ARRAY['steak n shake peanut butter shake', 'steak n shake reeses shake'], '900 cal per regular shake (~500g)'),
-- Oreo Shake Regular: 730cal, 38g pro, 122g carb, 22g fat, 0g fib, 102g sug, ~500g
('steak_n_shake_oreo_shake', 'Steak ''n Shake Oreo Cookies ''n Cream Milkshake (Regular)', 146.0, 7.6, 24.4, 4.4, 0.0, 20.4, 500, 500, 'steaknshake.com', ARRAY['steak n shake oreo shake', 'steak n shake cookies cream shake'], '730 cal per regular shake (~500g)')
