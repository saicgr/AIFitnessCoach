-- 317_overrides_warehouse_clubs.sql
-- Warehouse club food items: Costco Food Court, Costco Bakery,
-- Sam's Club Cafe, BJ's Wholesale food court.
-- Sources: calorieking.com, fatsecret.com, nutritionix.com, mynetdiary.com,
-- eatthismuch.com, fastfoodnutrition.org, myfooddiary.com, costcofdb.com

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ============================================================================
-- COSTCO FOOD COURT
-- ============================================================================

-- Costco Hot Dog (with bun): 570 cal per serving, serving ~235g (8.3oz)
-- 570/235*100 = ~243 cal/100g
('costco_hot_dog', 'Costco Food Court Hot Dog', 243, 10.2, 19.6, 14.0,
 0.9, 2.0, NULL, 235,
 'costco', ARRAY['costco food court hot dog', 'costco hot dog with bun', 'kirkland hot dog', 'costco 1/4 lb hot dog'],
 'warehouse_club', 'Costco', 1, '243 cal/100g. Per hot dog ~235g = 570 cal. Quarter-pound all-beef frank with bun. 24g protein, 33g fat, 46g carbs per serving.', TRUE),

-- Costco Cheese Pizza Slice: 710 cal per slice, slice ~278g (9.5oz)
-- 710/278*100 = ~255 cal/100g
('costco_cheese_pizza_slice', 'Costco Food Court Cheese Pizza Slice', 255, 14.7, 28.1, 9.7,
 3.2, 1.8, NULL, 278,
 'costco', ARRAY['costco cheese pizza', 'costco food court cheese pizza', 'costco pizza cheese slice'],
 'warehouse_club', 'Costco', 1, '255 cal/100g. Per slice ~278g = 710 cal. 18-inch pizza, 41g protein, 27g fat, 78g carbs per slice.', TRUE),

-- Costco Pepperoni Pizza Slice: 680 cal per slice, slice ~270g (9.5oz)
-- 680/270*100 = ~252 cal/100g
('costco_pepperoni_pizza_slice', 'Costco Food Court Pepperoni Pizza Slice', 252, 12.6, 28.1, 9.3,
 2.6, 2.0, NULL, 270,
 'costco', ARRAY['costco pepperoni pizza', 'costco food court pepperoni pizza', 'costco pizza pepperoni slice'],
 'warehouse_club', 'Costco', 1, '252 cal/100g. Per slice ~270g = 680 cal. 18-inch pizza with pepperoni. 34g protein, 25g fat, 76g carbs per slice.', TRUE),

-- Costco Combo Pizza Slice: 760 cal per slice, slice ~335g (11.8oz)
-- 760/335*100 = ~227 cal/100g
('costco_combo_pizza_slice', 'Costco Food Court Combo Pizza Slice', 227, 10.1, 24.5, 9.3,
 2.1, 2.5, NULL, 335,
 'costco', ARRAY['costco combo pizza', 'costco food court combo pizza', 'costco supreme pizza', 'costco pizza combo slice'],
 'warehouse_club', 'Costco', 1, '227 cal/100g. Per slice ~335g = 760 cal. 18-inch pizza with sausage, pepperoni, peppers, onions, olives. 34g protein, 31g fat, 82g carbs per slice.', TRUE),

-- Costco Chicken Bake: 770 cal per serving, serving ~227g (8oz)
-- 770/227*100 = ~339 cal/100g
('costco_chicken_bake', 'Costco Food Court Chicken Bake', 339, 20.3, 35.7, 11.5,
 1.3, 2.0, NULL, 227,
 'costco', ARRAY['costco food court chicken bake', 'kirkland chicken bake', 'costco caesar chicken bake'],
 'warehouse_club', 'Costco', 1, '339 cal/100g. Per piece ~227g = 770 cal. Baked dough with chicken breast, mozzarella, bacon, caesar dressing. 46g protein, 26g fat, 81g carbs.', TRUE),

-- Costco Acai Bowl: 330 cal per bowl, bowl ~350g (12.3oz)
-- 330/350*100 = ~94 cal/100g
('costco_acai_bowl', 'Costco Food Court Acai Bowl', 94, 2.9, 14.3, 2.9,
 2.0, 8.0, NULL, 350,
 'costco', ARRAY['costco food court acai bowl', 'costco acai', 'costco food court acai'],
 'warehouse_club', 'Costco', 1, '94 cal/100g. Per bowl ~350g = 330 cal. Blended acai with granola and fruit toppings. 10g protein, 10g fat, 50g carbs per bowl.', TRUE),

-- Costco Twisted Churro: 570 cal per churro, churro ~150g (5.3oz)
-- 570/150*100 = ~380 cal/100g
('costco_churro', 'Costco Food Court Churro', 380, 5.3, 58.7, 13.3,
 1.0, 17.3, NULL, 150,
 'costco', ARRAY['costco food court churro', 'costco twisted churro', 'costco cinnamon sugar churro'],
 'warehouse_club', 'Costco', 1, '380 cal/100g. Per churro ~150g = 570 cal. Twisted churro with cinnamon sugar coating. 8g protein, 20g fat, 88g carbs.', TRUE),

-- Costco Soft Serve (vanilla/chocolate twist): 550 cal per cup, cup ~284g (10oz)
-- 550/284*100 = ~194 cal/100g
('costco_soft_serve', 'Costco Food Court Soft Serve Ice Cream', 194, 3.2, 22.5, 10.6,
 0.0, 19.7, NULL, 284,
 'costco', ARRAY['costco ice cream', 'costco food court ice cream', 'costco vanilla soft serve', 'costco chocolate soft serve', 'costco twist soft serve'],
 'warehouse_club', 'Costco', 1, '194 cal/100g. Per cup ~284g (10oz) = 550 cal. Soft serve vanilla, chocolate, or twist. 9g protein, 30g fat, 64g carbs, 56g sugar per cup.', TRUE),

-- Costco Turkey & Provolone Sandwich: 730 cal per sandwich, sandwich ~310g (10.9oz)
-- 730/310*100 = ~235 cal/100g
('costco_turkey_provolone_sandwich', 'Costco Food Court Turkey & Provolone Sandwich', 235, 14.5, 16.5, 12.6,
 1.3, 2.5, NULL, 310,
 'costco', ARRAY['costco turkey sandwich', 'costco hot turkey sandwich', 'costco turkey provolone', 'costco food court turkey sandwich'],
 'warehouse_club', 'Costco', 1, '235 cal/100g. Per sandwich ~310g = 730 cal. Hot pressed sandwich with turkey, provolone, and pesto. 45g protein, 39g fat, 51g carbs.', TRUE),

-- Costco Rotisserie Chicken (per serving): 140 cal per 85g (3oz)
-- 140/85*100 = ~165 cal/100g
('costco_rotisserie_chicken', 'Costco Kirkland Rotisserie Chicken (per serving)', 165, 22.4, 0.0, 8.2,
 0.0, 0.0, 85, NULL,
 'costco', ARRAY['costco rotisserie chicken', 'kirkland rotisserie chicken', 'costco whole chicken'],
 'warehouse_club', 'Costco', 1, '165 cal/100g. Per 3oz serving (85g) = 140 cal. Whole seasoned rotisserie chicken ~3 lbs. 19g protein, 7g fat per serving. High protein, zero carbs.', TRUE),

-- Costco Rotisserie Chicken (whole): ~2240 cal whole, ~1360g total weight (~900g edible)
-- Using edible meat: 165 cal/100g (same as per serving)
('costco_rotisserie_chicken_whole', 'Costco Kirkland Rotisserie Chicken (whole)', 165, 22.4, 0.0, 8.2,
 0.0, 0.0, NULL, 1360,
 'costco', ARRAY['costco whole rotisserie chicken', 'kirkland whole chicken', 'costco 3lb rotisserie chicken'],
 'warehouse_club', 'Costco', 1, '165 cal/100g. Whole chicken ~1360g (3 lbs), ~900g edible meat = ~1485 cal edible. Seasoned and roasted, sold for $4.99.', TRUE),

-- Costco Berry Smoothie: 290 cal per 16oz, ~480ml (~480g)
-- 290/480*100 = ~60 cal/100g
('costco_berry_smoothie', 'Costco Food Court Berry Smoothie', 60, 0.4, 15.0, 0.0,
 0.5, 12.5, 480, NULL,
 'costco', ARRAY['costco fruit smoothie', 'costco food court smoothie', 'costco acai smoothie', 'costco berry fruit smoothie'],
 'warehouse_club', 'Costco', 1, '60 cal/100g. Per 16oz cup (~480g) = 290 cal. Blended strawberry, blackberry, acai with apple-pear-pineapple juice base. No added sugar.', TRUE),

-- Costco Mango Smoothie: 240 cal per 16oz, ~480ml (~480g)
-- 240/480*100 = ~50 cal/100g
('costco_mango_smoothie', 'Costco Food Court Mango Smoothie', 50, 0.2, 12.3, 0.0,
 0.2, 10.4, 480, NULL,
 'costco', ARRAY['costco food court mango smoothie', 'costco mango fruit smoothie'],
 'warehouse_club', 'Costco', 1, '50 cal/100g. Per 16oz cup (~480g) = 240 cal. Pure mango blend with no added sugars or preservatives. 59g carbs, 50g sugar per cup.', TRUE),

-- Costco Chicken Caesar Salad (with dressing): 710 cal per salad, salad ~420g (14.8oz)
-- 710/420*100 = ~169 cal/100g
('costco_chicken_caesar_salad', 'Costco Food Court Chicken Caesar Salad', 169, 9.5, 8.1, 9.5,
 1.4, 1.5, NULL, 420,
 'costco', ARRAY['costco caesar salad', 'costco food court caesar salad', 'costco chicken salad'],
 'warehouse_club', 'Costco', 1, '169 cal/100g. Per salad ~420g = 710 cal (with dressing & croutons). 40g protein, 40g fat, 34g carbs. Without dressing: only 195 cal.', TRUE),

-- ============================================================================
-- COSTCO BAKERY / PREPARED
-- ============================================================================

-- Costco Blueberry Muffin: 612 cal per muffin, muffin ~165g (5.8oz)
-- 612/165*100 = ~371 cal/100g
('costco_blueberry_muffin', 'Costco Kirkland Blueberry Muffin', 371, 4.8, 43.0, 19.4,
 1.2, 25.5, NULL, 165,
 'costco', ARRAY['costco muffin blueberry', 'kirkland blueberry muffin', 'costco bakery blueberry muffin'],
 'warehouse_club', 'Costco', 1, '371 cal/100g. Per muffin ~165g = 612 cal. Kirkland Signature jumbo muffin. 8g protein, 32g fat, 71g carbs per muffin.', TRUE),

-- Costco Double Chocolate Muffin: 690 cal per muffin, muffin ~167g (5.9oz)
-- 690/167*100 = ~413 cal/100g
('costco_chocolate_muffin', 'Costco Kirkland Double Chocolate Muffin', 413, 6.0, 47.3, 22.8,
 1.8, 28.7, NULL, 167,
 'costco', ARRAY['costco muffin chocolate', 'kirkland chocolate muffin', 'costco bakery chocolate muffin', 'costco double chocolate muffin'],
 'warehouse_club', 'Costco', 1, '413 cal/100g. Per muffin ~167g = 690 cal. Kirkland Signature jumbo chocolate muffin. 10g protein, 38g fat, 79g carbs per muffin.', TRUE),

-- Costco Almond Poppyseed Muffin: 660 cal per muffin, muffin ~165g
-- 660/165*100 = ~400 cal/100g
('costco_poppyseed_muffin', 'Costco Kirkland Almond Poppyseed Muffin', 400, 6.1, 42.4, 21.8,
 1.2, 25.5, NULL, 165,
 'costco', ARRAY['costco muffin poppyseed', 'kirkland almond poppy muffin', 'costco bakery poppyseed muffin', 'costco almond poppy muffin'],
 'warehouse_club', 'Costco', 1, '400 cal/100g. Per muffin ~165g = 660 cal. Kirkland Signature almond poppyseed jumbo muffin. 10g protein, 36g fat, 70g carbs.', TRUE),

-- Costco Butter Croissant: 300 cal per croissant, croissant ~69g (2.4oz)
-- 300/69*100 = ~435 cal/100g
('costco_butter_croissant', 'Costco Kirkland Butter Croissant', 435, 8.7, 43.5, 24.6,
 1.0, 5.8, NULL, 69,
 'costco', ARRAY['costco croissant', 'kirkland butter croissant', 'costco bakery croissant', 'costco all butter croissant'],
 'warehouse_club', 'Costco', 1, '435 cal/100g. Per croissant ~69g = 300 cal. Kirkland Signature all-butter croissant. 6g protein, 17g fat, 30g carbs.', TRUE),

-- Costco Chocolate Croissant (Pain au Chocolat): 180 cal per piece, piece ~45g (1.6oz)
-- 180/45*100 = ~400 cal/100g
('costco_chocolate_croissant', 'Costco Chocolate Croissant (Pain au Chocolat)', 400, 6.7, 46.7, 20.0,
 2.2, 13.3, NULL, 45,
 'costco', ARRAY['costco pain au chocolat', 'costco chocolatine', 'kirkland chocolate croissant', 'costco bakery chocolate croissant'],
 'warehouse_club', 'Costco', 1, '400 cal/100g. Per piece ~45g = 180 cal. La Boulangere chocolatine. 3g protein, 9g fat, 21g carbs per piece.', TRUE),

-- Costco Danish (cheese): 500 cal per danish, danish ~130g (4.6oz)
-- 500/130*100 = ~385 cal/100g
('costco_cheese_danish', 'Costco Kirkland Cheese Danish', 385, 5.4, 45.4, 20.8,
 0.8, 18.5, NULL, 130,
 'costco', ARRAY['costco danish', 'kirkland cheese danish', 'costco bakery danish', 'costco cream cheese danish'],
 'warehouse_club', 'Costco', 1, '385 cal/100g. Per danish ~130g = 500 cal. Kirkland Signature cheese danish. 7g protein, 27g fat, 59g carbs.', TRUE),

-- Costco Tiramisu Cake (per slice): 260 cal per slice, slice ~70g
-- 260/70*100 = ~371 cal/100g
('costco_tiramisu_cake', 'Costco Kirkland Tiramisu Cake (per slice)', 371, 7.1, 27.1, 25.7,
 0.3, 17.1, NULL, 70,
 'costco', ARRAY['costco tiramisu', 'kirkland tiramisu cake', 'costco bakery tiramisu', 'costco tiramisu scoop cake'],
 'warehouse_club', 'Costco', 1, '371 cal/100g. Per slice ~70g (1/18 cake) = 260 cal. Kirkland Signature tiramisu with mascarpone cream and coffee-soaked sponge. 5g protein, 18g fat, 19g carbs.', TRUE),

-- Costco Sheet Cake (white, per slice): 270 cal per slice, slice ~115g
-- 270/115*100 = ~235 cal/100g
('costco_sheet_cake_slice', 'Costco Sheet Cake (per slice)', 235, 2.6, 28.7, 11.3,
 0.2, 20.0, NULL, 115,
 'costco', ARRAY['costco cake', 'costco birthday cake', 'costco bakery sheet cake', 'costco white cake slice', 'costco sheet cake'],
 'warehouse_club', 'Costco', 1, '235 cal/100g. Per slice ~115g = 270 cal. White sheet cake with buttercream frosting. 3g protein, 13g fat, 33g carbs per slice.', TRUE),

-- Costco Chicken Pot Pie (per 1/8 pie): 390 cal per slice, slice ~180g
-- 390/180*100 = ~217 cal/100g
('costco_chicken_pot_pie', 'Costco Kirkland Chicken Pot Pie (per serving)', 217, 8.3, 17.2, 12.8,
 1.1, 1.5, 180, NULL,
 'costco', ARRAY['costco pot pie', 'kirkland chicken pot pie', 'costco bakery chicken pot pie'],
 'warehouse_club', 'Costco', 1, '217 cal/100g. Per 1/8 pie (~180g) = 390 cal. Flaky crust filled with chicken, vegetables, creamy gravy. 15g protein, 23g fat, 31g carbs.', TRUE),

-- Costco Street Tacos (chicken, per taco): 190 cal per taco, taco ~100g
-- 190/100*100 = ~190 cal/100g
('costco_street_tacos', 'Costco Kirkland Chicken Street Tacos', 190, 12.0, 20.0, 7.0,
 2.0, 1.0, NULL, 100,
 'costco', ARRAY['costco chicken street tacos', 'kirkland street tacos', 'costco deli street tacos', 'costco chicken tacos'],
 'warehouse_club', 'Costco', 1, '190 cal/100g. Per taco ~100g = 190 cal. Mini flour tortilla with seasoned chicken, cilantro lime salsa. 12g protein, 7g fat, 20g carbs.', TRUE),

-- ============================================================================
-- SAM'S CLUB CAFE
-- ============================================================================

-- Sam's Club Cheese Pizza Slice: 340 cal per slice, slice ~145g
-- Note: standard cafe slice, not the larger hot bake
-- 340/145*100 = ~234 cal/100g
('sams_club_cheese_pizza_slice', 'Sam''s Club Cafe Cheese Pizza Slice', 234, 11.0, 29.7, 8.3,
 1.4, 2.5, NULL, 145,
 'sams_club', ARRAY['sams club cheese pizza', 'sam''s club cafe cheese pizza', 'sams club pizza cheese'],
 'warehouse_club', 'Sam''s Club', 1, '234 cal/100g. Per slice ~145g = 340 cal. Standard cafe cheese pizza slice. 16g protein, 12g fat, 43g carbs.', TRUE),

-- Sam's Club Pepperoni Pizza Slice: 380 cal per slice, slice ~150g
-- 380/150*100 = ~253 cal/100g
('sams_club_pepperoni_pizza_slice', 'Sam''s Club Cafe Pepperoni Pizza Slice', 253, 12.0, 22.0, 13.3,
 1.3, 2.5, NULL, 150,
 'sams_club', ARRAY['sams club pepperoni pizza', 'sam''s club cafe pepperoni pizza', 'sams club pizza pepperoni'],
 'warehouse_club', 'Sam''s Club', 1, '253 cal/100g. Per slice ~150g = 380 cal. Cafe pepperoni pizza slice. 18g protein, 20g fat, 33g carbs.', TRUE),

-- Sam's Club Combo Pizza Slice (4 Meat): 440 cal per slice, slice ~170g
-- 440/170*100 = ~259 cal/100g
('sams_club_combo_pizza_slice', 'Sam''s Club Cafe Combo Pizza Slice', 259, 12.4, 21.2, 13.5,
 1.2, 2.5, NULL, 170,
 'sams_club', ARRAY['sams club combo pizza', 'sam''s club 4 meat pizza', 'sams club pizza combo', 'sams club 3 meat pizza'],
 'warehouse_club', 'Sam''s Club', 1, '259 cal/100g. Per slice ~170g = 440 cal. 4-meat combo pizza (pepperoni, ham, sausage, bacon). 21g protein, 23g fat, 36g carbs.', TRUE),

-- Sam's Club Hot Dog (with bun): 530 cal per hot dog, hot dog ~210g
-- 530/210*100 = ~252 cal/100g
('sams_club_hot_dog', 'Sam''s Club Cafe Hot Dog', 252, 9.5, 17.6, 14.3,
 0.8, 2.5, NULL, 210,
 'sams_club', ARRAY['sams club hot dog', 'sam''s club cafe hot dog', 'sams club food court hot dog', 'members mark hot dog'],
 'warehouse_club', 'Sam''s Club', 1, '252 cal/100g. Per hot dog ~210g = 530 cal. Member''s Mark cheddar pork frank with bun. 20g protein, 30g fat, 37g carbs.', TRUE),

-- Sam's Club Churro (Double Twisted): 310 cal per churro, churro ~95g
-- 310/95*100 = ~326 cal/100g
('sams_club_churro', 'Sam''s Club Cafe Churro', 326, 3.2, 57.9, 10.5,
 0.8, 15.0, NULL, 95,
 'sams_club', ARRAY['sams club churro', 'sam''s club cafe churro', 'sams club double twisted churro', 'sams club food court churro'],
 'warehouse_club', 'Sam''s Club', 1, '326 cal/100g. Per churro ~95g = 310 cal. Double twisted churro with cinnamon sugar. 3g protein, 10g fat, 55g carbs.', TRUE),

-- Sam's Club Soft Pretzel (with butter & salt): 470 cal per pretzel, pretzel ~166g
-- 470/166*100 = ~283 cal/100g
('sams_club_pretzel', 'Sam''s Club Cafe Soft Pretzel', 283, 5.4, 42.2, 1.2,
 1.2, 2.5, NULL, 166,
 'sams_club', ARRAY['sams club pretzel', 'sam''s club soft pretzel', 'sams club cafe pretzel', 'sams club food court pretzel'],
 'warehouse_club', 'Sam''s Club', 1, '283 cal/100g. Per pretzel ~166g = 470 cal. Soft pretzel with butter and salt. 9g protein, 2g fat, 70g carbs.', TRUE),

-- Sam's Club ICEE (32oz): 290 cal per 32oz cup, ~960ml (~960g)
-- 290/960*100 = ~30 cal/100g
('sams_club_icee', 'Sam''s Club ICEE', 30, 0.0, 8.3, 0.0,
 0.0, 8.3, 960, NULL,
 'sams_club', ARRAY['sams club icee', 'sam''s club icee', 'sams club frozen drink', 'sams club slushie', 'sams club cafe icee'],
 'warehouse_club', 'Sam''s Club', 1, '30 cal/100g. Per 32oz cup (~960g) = 290 cal. Frozen carbonated beverage. 0g protein, 0g fat, 80g carbs, 116g sugar per cup.', TRUE),

-- Sam's Club Rotisserie Chicken (per serving): 130 cal per 85g (3oz)
-- 130/85*100 = ~153 cal/100g
('sams_club_rotisserie_chicken', 'Sam''s Club Seasoned Rotisserie Chicken (per serving)', 153, 22.4, 1.2, 7.1,
 0.0, 0.0, 85, NULL,
 'sams_club', ARRAY['sams club rotisserie chicken', 'sam''s club whole chicken', 'members mark rotisserie chicken'],
 'warehouse_club', 'Sam''s Club', 1, '153 cal/100g. Per 3oz serving (85g) = 130 cal. Member''s Mark seasoned rotisserie chicken. 19g protein, 6g fat, 1g carbs per serving.', TRUE),

-- Sam's Club Caesar Salad (with chicken): 230 cal per bowl, bowl ~250g
-- 230/250*100 = ~92 cal/100g
('sams_club_caesar_salad', 'Sam''s Club Cafe Caesar Salad', 92, 8.4, 2.4, 5.6,
 0.8, 0.8, NULL, 250,
 'sams_club', ARRAY['sams club caesar salad', 'sam''s club chicken caesar salad', 'sams club cafe salad'],
 'warehouse_club', 'Sam''s Club', 1, '92 cal/100g. Per bowl ~250g = 230 cal. Grilled chicken caesar salad with dressing. 21g protein, 14g fat, 6g carbs.', TRUE),

-- ============================================================================
-- COSTCO FOOD COURT - ADDITIONAL ITEMS
-- ============================================================================

-- Costco Chicken Caesar Salad (no dressing): 195 cal, salad ~340g
-- 195/340*100 = ~57 cal/100g
('costco_chicken_caesar_salad_no_dressing', 'Costco Food Court Caesar Salad (no dressing)', 57, 9.7, 1.5, 0.9,
 1.0, 0.5, NULL, 340,
 'costco', ARRAY['costco caesar salad no dressing', 'costco salad undressed', 'costco chicken salad no dressing'],
 'warehouse_club', 'Costco', 1, '57 cal/100g. Per salad ~340g = 195 cal (without dressing or croutons). 33g protein, 3g fat, 5g net carbs. Very low calorie option.', TRUE),

-- Costco Almond Danish: 750 cal per danish, danish ~155g
-- 750/155*100 = ~484 cal/100g
('costco_almond_danish', 'Costco Kirkland Almond Danish', 484, 8.4, 45.8, 30.3,
 1.3, 22.6, NULL, 155,
 'costco', ARRAY['costco danish almond', 'kirkland almond danish', 'costco bakery almond danish'],
 'warehouse_club', 'Costco', 1, '484 cal/100g. Per danish ~155g = 750 cal. Kirkland Signature almond danish pastry. 13g protein, 47g fat, 71g carbs.', TRUE),

-- Costco Cherry Danish: 470 cal per danish, danish ~130g
-- 470/130*100 = ~362 cal/100g
('costco_cherry_danish', 'Costco Kirkland Cherry Danish', 362, 5.4, 45.4, 17.7,
 0.8, 22.0, NULL, 130,
 'costco', ARRAY['costco danish cherry', 'kirkland cherry danish', 'costco bakery cherry danish'],
 'warehouse_club', 'Costco', 1, '362 cal/100g. Per danish ~130g = 470 cal. Kirkland Signature cherry danish pastry. 7g protein, 23g fat, 59g carbs.', TRUE),

-- Costco Chocolate Sheet Cake (per slice): 320 cal per slice, slice ~115g
-- 320/115*100 = ~278 cal/100g
('costco_chocolate_cake_slice', 'Costco Chocolate Sheet Cake (per slice)', 278, 2.6, 34.8, 13.0,
 1.3, 24.0, NULL, 115,
 'costco', ARRAY['costco chocolate cake', 'costco chocolate sheet cake', 'costco bakery chocolate cake', 'costco chocolate birthday cake'],
 'warehouse_club', 'Costco', 1, '278 cal/100g. Per slice ~115g = 320 cal. Chocolate cake with chocolate mousse filling and buttercream frosting. 3g protein, 15g fat, 40g carbs.', TRUE),

-- ============================================================================
-- BJ'S WHOLESALE
-- ============================================================================

-- BJ's Pizza Slice (cheese, food court style): ~280 cal per slice, slice ~130g
-- Using typical warehouse club pizza data, cross-referenced with BJ's data
-- 280/130*100 = ~215 cal/100g
('bjs_pizza_slice', 'BJ''s Wholesale Pizza Slice', 215, 9.2, 24.6, 6.9,
 1.2, 2.5, NULL, 130,
 'bjs_wholesale', ARRAY['bjs pizza', 'bj''s wholesale pizza', 'bjs food court pizza', 'bjs cheese pizza slice'],
 'warehouse_club', 'BJ''s Wholesale', 1, '215 cal/100g. Per slice ~130g = 280 cal. BJ''s Wholesale food court cheese pizza slice. 12g protein, 9g fat, 32g carbs.', TRUE),

-- BJ's Hot Dog (food court): ~480 cal per hot dog, hot dog ~200g
-- Standard warehouse club hot dog profile
-- 480/200*100 = ~240 cal/100g
('bjs_hot_dog', 'BJ''s Wholesale Hot Dog', 240, 10.0, 18.5, 13.5,
 0.8, 2.5, NULL, 200,
 'bjs_wholesale', ARRAY['bjs hot dog', 'bj''s wholesale hot dog', 'bjs food court hot dog'],
 'warehouse_club', 'BJ''s Wholesale', 1, '240 cal/100g. Per hot dog ~200g = 480 cal. BJ''s Wholesale food court all-beef hot dog with bun. 20g protein, 27g fat, 37g carbs.', TRUE),

-- ============================================================================
-- SAM'S CLUB - ADDITIONAL ITEMS
-- ============================================================================

-- Sam's Club Rotisserie Chicken (whole): same per-100g as per serving
('sams_club_rotisserie_chicken_whole', 'Sam''s Club Seasoned Rotisserie Chicken (whole)', 153, 22.4, 1.2, 7.1,
 0.0, 0.0, NULL, 1300,
 'sams_club', ARRAY['sams club whole rotisserie chicken', 'sam''s club rotisserie chicken whole', 'members mark whole chicken'],
 'warehouse_club', 'Sam''s Club', 1, '153 cal/100g. Whole chicken ~1300g (~2.9 lbs). Member''s Mark seasoned rotisserie chicken. 19g protein, 6g fat, 1g carbs per 85g serving.', TRUE),

-- Sam's Club Hot Bake Cheese Pizza (larger slice): 670 cal per slice, slice ~280g
-- 670/280*100 = ~239 cal/100g
('sams_club_hot_bake_cheese_pizza', 'Sam''s Club Cafe Hot Bake Cheese Pizza', 239, 11.4, 25.7, 10.4,
 1.4, 2.5, NULL, 280,
 'sams_club', ARRAY['sams club hot bake cheese pizza', 'sam''s club large cheese pizza', 'sams club big pizza slice'],
 'warehouse_club', 'Sam''s Club', 1, '239 cal/100g. Per slice ~280g = 670 cal. Larger hot bake pizza slice. 32g protein, 29g fat, 72g carbs.', TRUE),

-- Sam's Club Hot Bake Pepperoni Pizza (larger slice): 700 cal per slice, slice ~280g
-- 700/280*100 = ~250 cal/100g
('sams_club_hot_bake_pepperoni_pizza', 'Sam''s Club Cafe Hot Bake Pepperoni Pizza', 250, 11.8, 25.0, 11.4,
 1.1, 2.5, NULL, 280,
 'sams_club', ARRAY['sams club hot bake pepperoni pizza', 'sam''s club large pepperoni pizza', 'sams club big pepperoni pizza slice'],
 'warehouse_club', 'Sam''s Club', 1, '250 cal/100g. Per slice ~280g = 700 cal. Larger hot bake pepperoni pizza slice. 33g protein, 32g fat, 70g carbs.', TRUE),

-- Sam's Club Pizza Pretzel: 440 cal per half pretzel, half pretzel ~160g
-- 440/160*100 = ~275 cal/100g
('sams_club_pizza_pretzel', 'Sam''s Club Cafe Pizza Pretzel', 275, 11.9, 34.4, 10.0,
 1.2, 2.5, NULL, 160,
 'sams_club', ARRAY['sams club pizza pretzel', 'sam''s club cafe pizza pretzel', 'sams club food court pizza pretzel'],
 'warehouse_club', 'Sam''s Club', 1, '275 cal/100g. Per half pretzel ~160g = 440 cal. Soft pretzel with pizza sauce and cheese. 19g protein, 16g fat, 55g carbs.', TRUE),

-- Sam's Club Cinnamon Sugar Pretzel: 490 cal per pretzel, pretzel ~170g
-- 490/170*100 = ~288 cal/100g
('sams_club_cinnamon_pretzel', 'Sam''s Club Cafe Cinnamon Sugar Pretzel', 288, 8.2, 53.5, 4.1,
 1.2, 17.6, NULL, 170,
 'sams_club', ARRAY['sams club cinnamon pretzel', 'sam''s club cinnamon sugar pretzel', 'sams club sweet pretzel'],
 'warehouse_club', 'Sam''s Club', 1, '288 cal/100g. Per pretzel ~170g = 490 cal. Soft pretzel with butter and cinnamon sugar coating. 14g protein, 7g fat, 91g carbs.', TRUE),

-- Sam's Club Southern Style Chicken Bites: 190 cal per serving, serving ~85g
-- 190/85*100 = ~224 cal/100g
('sams_club_chicken_bites', 'Sam''s Club Cafe Southern Chicken Bites', 224, 20.0, 19.0, 7.4,
 0.6, 0.5, 85, NULL,
 'sams_club', ARRAY['sams club chicken bites', 'sam''s club cafe chicken bites', 'sams club southern chicken', 'sams club chicken nuggets'],
 'warehouse_club', 'Sam''s Club', 1, '224 cal/100g. Per serving ~85g = 190 cal. Breaded southern-style chicken bites. 17g protein, 6.3g fat, 16g carbs.', TRUE)

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
