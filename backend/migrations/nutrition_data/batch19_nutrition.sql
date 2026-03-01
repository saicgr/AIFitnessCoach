-- ============================================================================
-- Batch 19: Mexican & Caribbean Restaurant Chains
-- Restaurants: Torchy's Tacos, Rubio's Coastal Grill, Taco John's, On The Border, Golden Krust
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com, calorieking.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. TORCHY'S TACOS (~130 US locations)
-- Source: torchystacos.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Trailer Park (Trashy): 420 cal, 22g protein, 26g carbs, 26g fat per 200g
('torchys_trailer_park', 'Torchy''s Trailer Park Taco (Trashy)', 210.0, 11.0, 13.0, 13.0, 1.0, 1.5, 200, 200, 'torchystacos.com', ARRAY['torchys trailer park', 'torchys trashy taco'], '420 cal per taco (200g). Fried chicken, green chiles, cheese, pico, lettuce on flour tortilla.', 'Torchy''s Tacos', 'mexican', 1),

-- Democrat: 380 cal, 18g protein, 28g carbs, 22g fat per 190g
('torchys_democrat', 'Torchy''s Democrat Taco', 200.0, 9.5, 14.7, 11.6, 2.0, 2.0, 190, 190, 'torchystacos.com', ARRAY['torchys democrat taco'], '380 cal per taco (190g). Barbacoa, avocado, queso fresco, cilantro, lime on corn tortilla.', 'Torchy''s Tacos', 'mexican', 1),

-- Crossroads: 350 cal, 14g protein, 30g carbs, 20g fat per 180g
('torchys_crossroads', 'Torchy''s Crossroads Taco', 194.4, 7.8, 16.7, 11.1, 2.5, 2.0, 180, 180, 'torchystacos.com', ARRAY['torchys crossroads', 'torchys veggie taco'], '350 cal per taco (180g). Roasted veggies, avocado, cheese on corn tortilla.', 'Torchy''s Tacos', 'mexican', 1),

-- Green Chile Queso: 280 cal, 10g protein, 16g carbs, 20g fat per 150g
('torchys_queso', 'Torchy''s Green Chile Queso', 186.7, 6.7, 10.7, 13.3, 0.5, 1.5, NULL, 150, 'torchystacos.com', ARRAY['torchys queso', 'torchys green chile queso'], '280 cal per 150g serving with chips.', 'Torchy''s Tacos', 'mexican', 1),

-- Brushfire: 400 cal, 24g protein, 24g carbs, 24g fat per 200g
('torchys_brushfire', 'Torchy''s Brushfire Taco', 200.0, 12.0, 12.0, 12.0, 1.5, 3.0, 200, 200, 'torchystacos.com', ARRAY['torchys brushfire', 'torchys jamaican jerk chicken'], '400 cal per taco (200g). Jamaican jerk chicken, grilled jalapeños, slaw, diablo sauce.', 'Torchy''s Tacos', 'mexican', 1),

-- Fried Avocado Taco: 440 cal, 10g protein, 36g carbs, 30g fat per 200g
('torchys_fried_avocado', 'Torchy''s Fried Avocado Taco', 220.0, 5.0, 18.0, 15.0, 4.0, 1.5, 200, 200, 'torchystacos.com', ARRAY['torchys fried avocado', 'torchys avocado taco'], '440 cal per taco (200g). Beer-battered avocado with refried beans, cheese, lettuce.', 'Torchy''s Tacos', 'mexican', 1),

-- ============================================================================
-- 2. RUBIO'S COASTAL GRILL (~170 US locations)
-- Source: rubios.com/nutrition, nutritionix.com
-- ============================================================================

-- Original Fish Taco: 310 cal, 14g protein, 28g carbs, 16g fat per 160g
('rubios_original_fish_taco', 'Rubio''s Original Fish Taco', 193.8, 8.8, 17.5, 10.0, 1.5, 1.5, 160, 160, 'rubios.com', ARRAY['rubios fish taco', 'rubios original fish'], '310 cal per taco (160g). Beer-battered fish with white sauce, cabbage.', 'Rubio''s', 'mexican', 1),

-- Grilled Gourmet Shrimp Taco: 280 cal, 16g protein, 24g carbs, 14g fat per 160g
('rubios_grilled_shrimp_taco', 'Rubio''s Grilled Shrimp Taco', 175.0, 10.0, 15.0, 8.8, 1.5, 1.5, 160, 160, 'rubios.com', ARRAY['rubios shrimp taco', 'rubios grilled shrimp'], '280 cal per taco (160g).', 'Rubio''s', 'mexican', 1),

-- Coastal Grilled Chicken Burrito: 720 cal, 36g protein, 72g carbs, 30g fat per 420g
('rubios_chicken_burrito', 'Rubio''s Coastal Grilled Chicken Burrito', 171.4, 8.6, 17.1, 7.1, 3.0, 2.0, 420, 420, 'rubios.com', ARRAY['rubios chicken burrito', 'rubios grilled chicken burrito'], '720 cal per burrito (420g).', 'Rubio''s', 'mexican', 1),

-- Salsa Verde Shrimp Bowl: 520 cal, 28g protein, 58g carbs, 18g fat per 400g
('rubios_shrimp_bowl', 'Rubio''s Salsa Verde Shrimp Bowl', 130.0, 7.0, 14.5, 4.5, 3.0, 2.0, NULL, 400, 'rubios.com', ARRAY['rubios shrimp bowl', 'rubios salsa verde bowl'], '520 cal per bowl (400g).', 'Rubio''s', 'mexican', 1),

-- Chips & Guac: 380 cal, 4g protein, 36g carbs, 24g fat per 180g
('rubios_chips_guac', 'Rubio''s Chips & Guacamole', 211.1, 2.2, 20.0, 13.3, 3.5, 1.0, NULL, 180, 'rubios.com', ARRAY['rubios chips and guacamole', 'rubios guac'], '380 cal per 180g serving.', 'Rubio''s', 'mexican', 1),

-- ============================================================================
-- 3. TACO JOHN'S (~365 US locations)
-- Source: tacojohns.com/nutrition, nutritionix.com
-- ============================================================================

-- Beef Crispy Taco: 180 cal, 9g protein, 13g carbs, 10g fat per 85g
('taco_johns_crispy_taco', 'Taco John''s Beef Crispy Taco', 211.8, 10.6, 15.3, 11.8, 1.5, 1.0, 85, 85, 'tacojohns.com', ARRAY['taco johns crispy taco', 'taco johns beef taco'], '180 cal per taco (85g).', 'Taco John''s', 'mexican', 1),

-- Meat & Potato Burrito: 500 cal, 18g protein, 56g carbs, 22g fat per 280g
('taco_johns_meat_potato_burrito', 'Taco John''s Meat & Potato Burrito', 178.6, 6.4, 20.0, 7.9, 2.0, 1.5, 280, 280, 'tacojohns.com', ARRAY['taco johns meat potato burrito', 'taco johns potato burrito'], '500 cal per burrito (280g).', 'Taco John''s', 'mexican', 1),

-- Potato Olés (regular): 430 cal, 5g protein, 48g carbs, 24g fat per 200g
('taco_johns_potato_oles', 'Taco John''s Potato Olés', 215.0, 2.5, 24.0, 12.0, 3.0, 0.5, NULL, 200, 'tacojohns.com', ARRAY['taco johns potato oles', 'taco johns oles', 'potato oles'], '430 cal per regular (200g). Signature seasoned potato rounds.', 'Taco John''s', 'sides', 1),

-- Chicken Quesadilla: 480 cal, 26g protein, 36g carbs, 26g fat per 230g
('taco_johns_chicken_quesadilla', 'Taco John''s Chicken Quesadilla', 208.7, 11.3, 15.7, 11.3, 1.0, 1.0, 230, 230, 'tacojohns.com', ARRAY['taco johns quesadilla', 'taco johns chicken quesadilla'], '480 cal per quesadilla (230g).', 'Taco John''s', 'mexican', 1),

-- Sirloin Steak Burrito: 540 cal, 24g protein, 54g carbs, 24g fat per 300g
('taco_johns_steak_burrito', 'Taco John''s Sirloin Steak Burrito', 180.0, 8.0, 18.0, 8.0, 2.0, 1.5, 300, 300, 'tacojohns.com', ARRAY['taco johns steak burrito'], '540 cal per burrito (300g).', 'Taco John''s', 'mexican', 1),

-- ============================================================================
-- 4. ON THE BORDER (~100 US locations)
-- Source: ontheborder.com/nutrition, nutritionix.com
-- ============================================================================

-- Classic Fajitas (chicken): 520 cal, 38g protein, 24g carbs, 30g fat per 350g (meat+veggies only)
('otb_chicken_fajitas', 'On The Border Chicken Fajitas', 148.6, 10.9, 6.9, 8.6, 2.0, 3.0, NULL, 350, 'ontheborder.com', ARRAY['on the border chicken fajitas', 'otb chicken fajitas'], '520 cal for meat and veggie portion (350g). Excludes tortillas, sides.', 'On The Border', 'mexican', 1),

-- Grande Taco Salad: 780 cal, 32g protein, 52g carbs, 48g fat per 450g
('otb_taco_salad', 'On The Border Grande Taco Salad', 173.3, 7.1, 11.6, 10.7, 3.0, 3.0, NULL, 450, 'ontheborder.com', ARRAY['on the border taco salad', 'otb taco salad'], '780 cal per 450g salad in taco shell.', 'On The Border', 'mexican', 1),

-- Border Sampler: 1200 cal, 42g protein, 88g carbs, 72g fat per 550g
('otb_border_sampler', 'On The Border Border Sampler', 218.2, 7.6, 16.0, 13.1, 2.0, 2.5, NULL, 550, 'ontheborder.com', ARRAY['on the border sampler', 'otb appetizer sampler'], '1200 cal per platter (550g). Wings, quesadilla, flautas, queso.', 'On The Border', 'mexican', 1),

-- Tres Enchiladas (cheese): 680 cal, 28g protein, 48g carbs, 42g fat per 350g
('otb_cheese_enchiladas', 'On The Border Tres Cheese Enchiladas', 194.3, 8.0, 13.7, 12.0, 2.0, 2.5, NULL, 350, 'ontheborder.com', ARRAY['on the border enchiladas', 'otb cheese enchiladas'], '680 cal per 3 enchiladas (350g).', 'On The Border', 'mexican', 1),

-- Guacamole (house-made): 220 cal, 3g protein, 12g carbs, 18g fat per 120g
('otb_guacamole', 'On The Border House-Made Guacamole', 183.3, 2.5, 10.0, 15.0, 5.0, 1.0, NULL, 120, 'ontheborder.com', ARRAY['on the border guacamole', 'otb guac'], '220 cal per 120g serving (no chips).', 'On The Border', 'mexican', 1),

-- Sopapillas: 480 cal, 6g protein, 58g carbs, 24g fat per 160g
('otb_sopapillas', 'On The Border Sopapillas', 300.0, 3.8, 36.3, 15.0, 0.5, 16.0, NULL, 160, 'ontheborder.com', ARRAY['on the border sopapillas', 'otb sopapillas dessert'], '480 cal per serving (160g). Fried pastry with honey, whipped cream.', 'On The Border', 'desserts', 1),

-- ============================================================================
-- 5. GOLDEN KRUST CARIBBEAN (~125 US locations)
-- Source: goldenkrust.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Beef Patty: 380 cal, 12g protein, 38g carbs, 20g fat per 150g
('golden_krust_beef_patty', 'Golden Krust Beef Patty', 253.3, 8.0, 25.3, 13.3, 1.5, 1.5, 150, 150, 'goldenkrust.com', ARRAY['golden krust beef patty', 'golden krust jamaican patty'], '380 cal per patty (150g). Flaky pastry with seasoned ground beef.', 'Golden Krust', 'caribbean', 1),

-- Chicken Patty: 350 cal, 14g protein, 36g carbs, 16g fat per 150g
('golden_krust_chicken_patty', 'Golden Krust Chicken Patty', 233.3, 9.3, 24.0, 10.7, 1.5, 1.0, 150, 150, 'goldenkrust.com', ARRAY['golden krust chicken patty'], '350 cal per patty (150g).', 'Golden Krust', 'caribbean', 1),

-- Jerk Chicken Plate: 480 cal, 32g protein, 42g carbs, 18g fat per 400g
('golden_krust_jerk_chicken', 'Golden Krust Jerk Chicken Plate', 120.0, 8.0, 10.5, 4.5, 1.5, 2.0, NULL, 400, 'goldenkrust.com', ARRAY['golden krust jerk chicken', 'golden krust chicken plate'], '480 cal per plate (400g). Jerk chicken with rice and peas.', 'Golden Krust', 'caribbean', 1),

-- Oxtail Plate: 550 cal, 28g protein, 48g carbs, 26g fat per 420g
('golden_krust_oxtail', 'Golden Krust Oxtail Plate', 131.0, 6.7, 11.4, 6.2, 2.0, 1.5, NULL, 420, 'goldenkrust.com', ARRAY['golden krust oxtail', 'golden krust oxtail stew'], '550 cal per plate (420g). Braised oxtail with butter beans, rice.', 'Golden Krust', 'caribbean', 1),

-- Curry Goat Plate: 520 cal, 26g protein, 46g carbs, 24g fat per 400g
('golden_krust_curry_goat', 'Golden Krust Curry Goat Plate', 130.0, 6.5, 11.5, 6.0, 1.5, 1.5, NULL, 400, 'goldenkrust.com', ARRAY['golden krust curry goat', 'golden krust goat curry'], '520 cal per plate (400g). Jamaican curry goat with rice and peas.', 'Golden Krust', 'caribbean', 1),

-- Coco Bread: 280 cal, 6g protein, 38g carbs, 12g fat per 100g
('golden_krust_coco_bread', 'Golden Krust Coco Bread', 280.0, 6.0, 38.0, 12.0, 1.0, 6.0, 100, 100, 'goldenkrust.com', ARRAY['golden krust coco bread', 'golden krust coconut bread'], '280 cal per bread (100g). Soft coconut bread, often stuffed with a patty.', 'Golden Krust', 'caribbean', 1)
