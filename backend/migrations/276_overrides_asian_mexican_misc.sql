-- ============================================================================
-- 276_overrides_asian_mexican_misc.sql
-- Generated: 2026-02-28
-- Total items: 556
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes
) VALUES
-- =====================================================
-- BATCH 8: Restaurant Nutrition Data
-- Church's Chicken, El Pollo Loco, Del Taco, Moe's,
-- Qdoba, Pei Wei, P.F. Chang's, Sweetgreen, Cava, Waba Grill
-- Sources: fastfoodnutrition.org, healthyfastfood.org,
--          fatsecret.com, myfooddiary.com, official sites
-- =====================================================
-- =====================================================
-- 1. CHURCH'S CHICKEN
-- Source: churchs.com, fastfoodnutrition.org, fatsecret.com
-- =====================================================
-- Original Chicken Breast: 250 cal, 14g fat, 23g pro, 9g carb, 0g fiber, 0g sugar per piece (~170g)
-- Original Chicken Leg: 164 cal, 10g fat, 13g pro, 6g carb per piece (~80g)
-- Original Chicken Thigh: 347 cal, 24g fat, 18g pro, 14g carb per piece (~111g)
-- Original Chicken Wing: 290 cal, 18g fat, 24g pro, 8g carb per wing (~100g)
-- Spicy Chicken Breast: 280 cal, 17g fat, 22g pro, 12g carb per piece (~170g)
-- Spicy Chicken Leg: 160 cal, 9g fat, 13g pro, 9g carb per piece (~80g)
-- Spicy Chicken Thigh: 380 cal, 25g fat, 17g pro, 21g carb per piece (~111g)
-- Chicken Tender Original: 90 cal, 4g fat, 8g pro, 5g carb per tender (~45g)
-- Honey-Butter Biscuit: 230 cal, 15g fat, 3g pro, 25g carb per biscuit (~60g)
-- Chicken Biscuit: 380 cal, 19g fat, 17g pro, 39g carb per sandwich (~140g)
-- Bacon Egg & Cheese Biscuit: 550 cal, 40g fat, 21g pro, 31g carb (~180g)
-- Signature Chicken Sandwich Original: 651 cal, 35g fat, 32g pro, 53g carb (~220g)
-- COB Sandwich: 810 cal, 55g fat, 25g pro, 50g carb (~280g)
-- French Fries Regular: 210 cal, 9g fat, 3g pro, 29g carb (~73g)
-- Baked Mac & Cheese Regular: 210 cal, 12g fat, 9g pro, 19g carb (~120g)
-- Mashed Potatoes & Gravy Regular: 110 cal, 1g fat, 2g pro, 24g carb (~130g)
-- Fried Okra Regular: 280 cal, 15g fat, 3g pro, 30g carb (~100g)
-- Cole Slaw Regular: 170 cal, 12g fat, 1g pro, 16g carb (~110g)
-- Apple Pie: 270 cal, 13g fat, 3g pro, 36g carb (~100g)
-- Frosted Honey Butter Biscuit: 320 cal, 16g fat, 4g pro, 40g carb (~80g)
-- =====================================================
-- 2. EL POLLO LOCO
-- Source: elpolloloco.com, healthyfastfood.org
-- =====================================================
-- Fire-Grilled Chicken Breast: 220 cal, 9g fat, 36g pro, 0g carb (~170g)
-- Fire-Grilled Chicken Thigh: 210 cal, 15g fat, 21g pro, 0g carb (~120g)
-- Fire-Grilled Chicken Leg: 80 cal, 4g fat, 12g pro, 0g carb (~60g)
-- Fire-Grilled Chicken Wing: 90 cal, 5g fat, 12g pro, 0g carb (~50g)
-- Original Pollo Bowl: 530 cal, 7g fat, 36g pro, 80g carb (~400g)
-- Double Chicken Bowl: 860 cal, 27g fat, 65g pro, 86g carb (~500g)
-- Grande Avocado Chicken Bowl: 780 cal, 26g fat, 45g pro, 89g carb (~480g)
-- Classic Chicken Burrito: 510 cal, 15g fat, 26g pro, 65g carb (~300g)
-- Chicken Avocado Burrito: 890 cal, 48g fat, 46g pro, 71g carb (~400g)
-- Ranchero Burrito: 870 cal, 40g fat, 44g pro, 84g carb (~400g)
-- Original BRC Burrito: 410 cal, 11g fat, 14g pro, 61g carb (~250g)
-- Chicken Avocado Overstuffed Quesadilla: 940 cal, 59g fat, 47g pro, 60g carb (~300g)
-- Double Chicken Avocado Salad: 370 cal, 15g fat, 48g pro, 14g carb (~350g)
-- Chicken Taco Al Carbon: 160 cal, 6g fat, 10g pro, 18g carb (~100g)
-- Chicken Black Bean Bowl: 460 cal, 11g fat, 37g pro, 57g carb (~400g)
-- Rice side large: 380 cal, 4g fat, 8g pro, 76g carb (~250g)
-- Black Beans large: 370 cal, 2.5g fat, 22g pro, 65g carb (~250g)
-- Pinto Beans large: 400 cal, 7g fat, 20g pro, 64g carb (~250g)
-- Macaroni and Cheese large: 770 cal, 48g fat, 23g pro, 60g carb (~300g)
-- Cinnamon Churros: 320 cal, 22g fat, 3g pro, 30g carb (~80g)
-- Tortilla Chips: 200 cal, 11g fat, 2g pro, 22g carb (~50g)
-- =====================================================
-- 3. DEL TACO
-- Source: deltaco.com, healthyfastfood.org, myfooddiary.com
-- =====================================================
-- Chicken Al Carbon Taco: 150 cal, 5g fat, 10g pro, 19g carb (~100g)
-- Grilled Chicken Taco: 210 cal, 12g fat, 12g pro, 16g carb (~100g)
-- Beyond Meat Taco: 300 cal, 19g fat, 19g pro, 15g carb (~100g)
-- Carne Asada Street Taco: 180 cal, per taco (~113g from myfooddiary)
-- Beer Battered Fish Taco: 230 cal, 9g fat, 11g pro, 28g carb (~120g)
-- Crunchy Taco: 310 cal per taco (~125g from myfooddiary)
-- 8 Layer Veggie Burrito: 530 cal, 18g fat, 18g pro, 72g carb (~300g)
-- Del Beef Burrito: 500 cal, 24g fat, 27g pro, 40g carb (~250g)
-- Chicken Crunch Burrito: 460 cal, 19g fat, 15g pro, 57g carb (~250g)
-- Epic Crispy Chicken & Guac Burrito: 890 cal, 52g fat, 29g pro, 78g carb (~400g)
-- Crispy Jumbo Shrimp Burrito: 780 cal, 45g fat, 18g pro, 74g carb (~350g)
-- Macho Combo Burrito: 950 cal (~538g from myfooddiary)
-- Crinkle Cut Fries regular: 210 cal, 10g fat, 3g pro, 27g carb (~100g)
-- Loaded Queso Fries: 510 cal (~200g)
-- Chicken Cheddar Quesadilla: 460 cal (~180g)
-- Churros (2pc): 230 cal (~70g)
-- Chocolate Shake small: 580 cal (~350g)
-- Vanilla Shake small: 550 cal (~350g)
-- =====================================================
-- 4. MOE'S SOUTHWEST GRILL
-- Source: moes.com, fatsecret.com, fastfoodnutrition.org
-- =====================================================
-- Homewrecker Burrito Chicken: 1160 cal, 42g fat, 55g pro, 157g carb (~500g)
-- Homewrecker Burrito Steak: 1116 cal, 39g fat, 51g pro, 158g carb (~500g)
-- Homewrecker Bowl Steak: 806 cal, 31g fat, 43g pro, 107g carb (~450g)
-- Burrito Bowl Chicken: 724 cal, 23g fat, 43g pro, 99g carb (~400g)
-- Burrito Bowl Steak: 680 cal, 20g fat, 39g pro, 100g carb (~400g)
-- Burrito Chicken: 1025 cal, 30g fat, 51g pro, 149g carb (~450g)
-- Burrito Steak: 981 cal, 27g fat, 47g pro, 150g carb (~450g)
-- Quesadilla Chicken: 492 cal, 27g fat, 39g pro, 35g carb (~220g)
-- Quesadilla Steak: 448 cal, 24g fat, 35g pro, 36g carb (~220g)
-- Nachos Chicken: 439 cal, 22g fat, 35g pro, 37g carb (~300g)
-- Salad Steak: 422 cal, 22g fat, 34g pro, 37g carb (~350g)
-- Moe Meat Moe Cheese Bowl: 890 cal, 44g fat, 65g pro, 78g carb (~450g)
-- Moe Meat Moe Cheese Burrito: 990 cal, 53g fat, 79g pro, 106g carb (~500g)
-- Chocolate Chip Cookie: 160 cal, 8g fat, 2g pro, 23g carb (~40g)
-- Chips: 693 cal (~150g)
-- Queso: 130 cal (~60g)
-- Guacamole: 110 cal (~60g)
-- =====================================================
-- 5. QDOBA
-- Source: qdoba.com, fastfoodnutrition.org
-- =====================================================
-- Chicken Burrito (standard build): 850 cal (~450g)
-- Steak Burrito: 900 cal (~450g)
-- Chicken Burrito Bowl: 660 cal, 34g fat, 40g pro, 47g carb (~400g)
-- Steak Burrito Bowl: 710 cal (~400g)
-- Chicken Taco (flour): 260 cal (~100g)
-- Steak Taco: 280 cal (~100g)
-- Chicken Quesadilla: 620 cal (~220g)
-- Chicken Nachos: 730 cal (~300g)
-- Chips and Guac: 430 cal (~150g)
-- Chips and Queso: 450 cal (~150g)
-- Three Cheese Queso (side): 120 cal (~60g)
-- Guacamole side: 100 cal (~60g)
-- Mexican Rice: 180 cal (~120g)
-- Black Beans: 110 cal (~120g)
-- Grilled Chicken (protein): 130 cal (~110g)
-- Grilled Steak (protein): 170 cal (~110g)
-- Flour Tortilla (burrito): 300 cal (~100g)
-- =====================================================
-- 6. PEI WEI
-- Source: peiwei.com, healthyfastfood.org
-- =====================================================
-- Orange Chicken Regular: 980 cal, 50g fat, 34g pro, 94g carb (~450g)
-- Kung Pao Chicken: 975 cal, 60g fat, 46g pro, 44g carb (~400g)
-- Beef & Broccoli: 790 cal, 49g fat, 34g pro, 53g carb (~400g)
-- Chicken & Broccoli: 666 cal, 27g fat, 40g pro, 48g carb (~400g)
-- Mongolian Chicken: 636 cal, 27g fat, 39g pro, 39g carb (~400g)
-- Mongolian Steak: 760 cal, 49g fat, 33g pro, 44g carb (~400g)
-- Sesame Chicken: 895 cal, 47g fat, 41g pro, 56g carb (~400g)
-- Spicy General Tso's Chicken: 805 cal, 42g fat, 40g pro, 48g carb (~400g)
-- Teriyaki Chicken: 935 cal, 41g fat, 42g pro, 84g carb (~450g)
-- Sweet & Sour Chicken: 980 cal, 50g fat, 33g pro, 97g carb (~450g)
-- Firecracker Chicken: 1090 cal, 60g fat, 46g pro, 96g carb (~450g)
-- Thai Coconut Curry Chicken: 640 cal, 8g fat, 54g pro, 42g carb (~400g)
-- Chicken Fried Rice: 1106 cal, 27g fat, 54g pro, 137g carb (~500g)
-- Chicken Lo Mein: 1170 cal, 42g fat, 70g pro, 123g carb (~500g)
-- Chicken Pad Thai: 1490 cal, 42g fat, 82g pro, 167g carb (~550g)
-- Dan Dan Noodles: 990 cal, 40g fat, 46g pro, 110g carb (~450g)
-- Asian Chopped Chicken Salad: 660 cal, 35g fat, 46g pro, 44g carb (~350g)
-- Chicken Egg Roll: 200 cal, 14g fat, 10g pro, 24g carb (~80g)
-- Vegetable Spring Rolls: 120 cal, 6g fat, 2g pro, 15g carb (~60g)
-- Crab Wonton: 85 cal, 5g fat, 3g pro, 7g carb (~25g)
-- Edamame: 160 cal (~120g)
-- =====================================================
-- 7. P.F. CHANG'S
-- Source: pfchangs.com, fastfoodnutrition.org, eatthismuch.com
-- =====================================================
-- Chang's Chicken Lettuce Wraps (full order): 730 cal, 27g fat, 38g pro, 81g carb (~365g x4 servings -> ~365g total)
-- Orange Chicken: 1160 cal (~400g)
-- Kung Pao Chicken: 980 cal (~400g)
-- Beef with Broccoli: 880 cal (~400g)
-- Mongolian Beef: 920 cal (~400g)
-- Crispy Honey Chicken: 1140 cal (~400g)
-- Kung Pao Shrimp: 1020 cal (~400g)
-- Pad Thai Chicken: 1340 cal (~500g)
-- Lo Mein Chicken: 830 cal (~400g)
-- Fried Rice with Chicken: 1100 cal (~450g)
-- Ma Po Tofu: 920 cal, 59g fat, carbs 57g (~350g)
-- Shrimp Dumplings Steamed (6pc): 260 cal (~150g)
-- Chicken Dumplings Pan-Fried (6pc): 370 cal (~150g)
-- Crab Wontons (6pc): 400 cal (~150g)
-- Dynamite Shrimp: 640 cal (~250g)
-- White Rice: 430 cal (~250g)
-- Brown Rice: 380 cal (~250g)
-- Egg Drop Soup: 60 cal (~250g)
-- Wonton Soup: 290 cal (~350g)
-- Chocolate Lava Cake: 620 cal (~180g)
-- =====================================================
-- 8. SWEETGREEN
-- Source: sweetgreen.com, healthyfastfood.org, myfooddiary.com
-- =====================================================
-- Harvest Bowl: 695 cal, 35g fat, 37g pro, 60g carb (~362g)
-- Kale Caesar Salad: 405 cal, 24g fat, 40g pro, 13g carb (~319g)
-- Chicken Pesto Parm Bowl: 530 cal, 29g fat, 35g pro, 38g carb (~340g)
-- Crispy Rice Bowl: 635 cal, 29g fat, 28g pro, 69g carb (~380g)
-- Fish Taco Bowl: 685 cal, 44g fat, 31g pro, 47g carb (~380g)
-- Shroomami Bowl: 685 cal, 41g fat, 27g pro, 57g carb (~380g)
-- Garden Cobb Salad: 650 cal, 51g fat, 22g pro, 33g carb (~400g)
-- Buffalo Chicken Bowl: 445 cal, 27g fat, 31g pro, 22g carb (~320g)
-- Guacamole Greens Salad: 545 cal, 36g fat, 27g pro, 30g carb (~402g)
-- Super Green Goddess Salad: 460 cal, 27g fat, 20g pro, 46g carb (~380g)
-- BBQ Chicken Salad: 585 cal (~370g)
-- Warm Quinoa base: 120 cal (~90g)
-- Warm Wild Rice base: 190 cal (~130g)
-- Blackened Chicken: 130 cal, 6g fat, 17g pro, 1g carb (~100g)
-- Avocado: 160 cal, 15g fat, 3g pro, 9g carb (~80g)
-- =====================================================
-- 9. CAVA
-- Source: cava.com, cavanutritionfacts.com, fastfoodnutrition.org
-- =====================================================
-- Harissa Avocado Bowl: 830 cal, 49g fat, 41g pro, 62g carb (~450g)
-- Greek Salad Bowl: 580 cal, 40g fat, 37g pro, 19g carb (~380g)
-- Chicken + Rice Bowl: 700 cal, 42g fat, 40g pro, 44g carb (~420g)
-- Steak + Harissa Bowl: 610 cal, 35g fat, 37g pro, 39g carb (~400g)
-- Falafel Crunch Bowl: 860 cal, 56g fat, 24g pro, 88g carb (~450g)
-- Spicy Lamb + Avocado Bowl: 800 cal, 52g fat, 43g pro, 49g carb (~450g)
-- Harissa Chicken Power Bowl: 620 cal, 40g fat, 25g pro, 43g carb (~400g)
-- Crispy Falafel Pita: 955 cal (~350g)
-- Grilled Chicken protein: 250 cal (~140g)
-- Grilled Steak protein: 230 cal (~140g)
-- Falafel: 350 cal (~120g)
-- Spicy Lamb Meatballs: 310 cal (~140g)
-- Saffron Basmati Rice: 290 cal, 6g fat, 6g pro, 54g carb (~200g)
-- Greens & Grains base: 132 cal (~150g)
-- Pita: 230 cal (~80g)
-- Hummus: 30 cal per serving (~30g)
-- Crazy Feta: 60 cal per serving (~30g)
-- Tzatziki: 25 cal per serving (~30g)
-- Harissa dip: 60 cal per serving (~30g)
-- Greek Vinaigrette: 130 cal per serving (~30g)
-- Lemon Herb Tahini: 70 cal per serving (~30g)
-- Avocado: 160 cal, 15g fat, 2g pro, 9g carb (~80g)
-- =====================================================
-- 10. WABA GRILL
-- Source: wabagrill.com, fastfoodnutrition.org
-- =====================================================
-- Chicken Bowl: 640 cal, 11g fat, 38g pro, 100g carb (~420g)
-- White Meat Chicken Bowl: 630 cal, 5g fat, 46g pro, 100g carb (~420g)
-- Sweet & Spicy Chicken Bowl: 680 cal, 11g fat, 38g pro, 120g carb (~420g)
-- Rib-Eye Steak Bowl: 720 cal, 18g fat, 29g pro, 110g carb (~420g)
-- WaBa Chicken & Steak Bowl: 710 cal, 16g fat, 37g pro, 100g carb (~420g)
-- Wild Caught Salmon Bowl: 540 cal, 5g fat, 29g pro, 90g carb (~420g)
-- Shrimp Bowl: 490 cal, 1g fat, 19g pro, 90g carb (~420g)
-- Organic Tofu Bowl: 590 cal, 11g fat, 23g pro, 90g carb (~420g)
-- Chicken Mini Bowl: 320 cal, 5g fat, 17g pro, 50g carb (~220g)
-- White Meat Chicken Mini Bowl: 320 cal, 2g fat, 21g pro, 50g carb (~220g)
-- Chicken Plate: 820 cal, 15g fat, 54g pro, 110g carb (~550g)
-- White Meat Chicken Plate: 800 cal, 7g fat, 65g pro, 100g carb (~550g)
-- Rib-Eye Steak Plate: 980 cal, 27g fat, 44g pro, 130g carb (~550g)
-- Wild Caught Salmon Plate: 700 cal, 7g fat, 41g pro, 110g carb (~550g)
-- Chicken Veggie Bowl: 590 cal, 11g fat, 39g pro, 90g carb (~450g)
-- White Meat Chicken Veggie Bowl: 580 cal, 5g fat, 47g pro, 90g carb (~450g)
-- Chicken Taco: 210 cal, 11g fat, 13g pro, 20g carb (~90g)
-- Steak Taco: 240 cal, 14g fat, 10g pro, 20g carb (~90g)
-- Shrimp Taco: 170 cal, 8g fat, 9g pro, 20g carb (~90g)
-- Signature House Salad (White Meat Chicken): 320 cal, 8g fat, 44g pro, 20g carb (~350g)
-- Spicy Asian Salad (White Meat Chicken): 420 cal, 10g fat, 49g pro, 30g carb (~350g)
-- Side of White Rice: 370 cal (~200g)
-- Side of Brown Rice: 320 cal (~200g)
-- Pork Veggie Dumplings (6pc): 210 cal (~120g)
-- Miso Soup: 30 cal (~250g)
-- Side of Steamed Veggies: 50 cal (~150g)
('churchs_original_chicken_breast', 'Church''s Original Chicken Breast', 147.1, 13.5, 5.3, 8.2, 0.0, 0.0, 170, 170, 'churchs.com', ARRAY['churchs breast', 'church chicken breast'], '250 cal per breast (170g)'),
('churchs_original_chicken_leg', 'Church''s Original Chicken Leg', 205.0, 16.3, 7.5, 12.5, 0.0, 0.0, 80, 80, 'churchs.com', ARRAY['churchs leg', 'church chicken leg'], '164 cal per leg (80g)'),
('churchs_original_chicken_thigh', 'Church''s Original Chicken Thigh', 312.6, 16.2, 12.6, 21.6, 0.9, 0.0, 111, 111, 'churchs.com', ARRAY['churchs thigh', 'church chicken thigh'], '347 cal per thigh (111g)'),
('churchs_original_chicken_wing', 'Church''s Original Chicken Wing', 290.0, 24.0, 8.0, 18.0, 0.0, 0.0, 100, 100, 'churchs.com', ARRAY['churchs wing', 'church chicken wing'], '290 cal per wing (100g)'),
('churchs_spicy_chicken_breast', 'Church''s Spicy Chicken Breast', 164.7, 12.9, 7.1, 10.0, 0.6, 0.0, 170, 170, 'churchs.com', ARRAY['churchs spicy breast'], '280 cal per breast (170g)'),
('churchs_spicy_chicken_leg', 'Church''s Spicy Chicken Leg', 200.0, 16.3, 11.3, 11.3, 1.3, 0.0, 80, 80, 'churchs.com', ARRAY['churchs spicy leg'], '160 cal per leg (80g)'),
('churchs_spicy_chicken_thigh', 'Church''s Spicy Chicken Thigh', 342.3, 15.3, 18.9, 22.5, 0.9, 0.0, 111, 111, 'churchs.com', ARRAY['churchs spicy thigh'], '380 cal per thigh (111g)'),
('churchs_chicken_tender', 'Church''s Chicken Tender', 200.0, 17.8, 11.1, 8.9, 0.0, 0.0, 45, 45, 'churchs.com', ARRAY['churchs tender', 'church tender strip'], '90 cal per tender (45g)'),
('churchs_honey_butter_biscuit', 'Church''s Honey-Butter Biscuit', 383.3, 5.0, 41.7, 25.0, 0.0, 6.7, 60, 60, 'churchs.com', ARRAY['churchs biscuit', 'church biscuit'], '230 cal per biscuit (60g)'),
('churchs_chicken_biscuit', 'Church''s Chicken Biscuit', 271.4, 12.1, 27.9, 13.6, 0.7, 3.6, 140, 140, 'churchs.com', ARRAY['churchs chicken biscuit sandwich'], '380 cal per sandwich (140g)'),
('churchs_bacon_egg_cheese_biscuit', 'Church''s Bacon Egg & Cheese Biscuit', 305.6, 11.7, 17.2, 22.2, 0.6, 2.2, 180, 180, 'churchs.com', ARRAY['churchs breakfast biscuit bacon'], '550 cal per sandwich (180g)'),
('churchs_signature_sandwich', 'Church''s Signature Chicken Sandwich', 295.9, 14.5, 24.1, 15.9, 1.4, 3.6, 220, 220, 'churchs.com', ARRAY['churchs chicken sandwich', 'church sandwich'], '651 cal per sandwich (220g)'),
('churchs_cob_sandwich', 'Church''s COB Sandwich', 289.3, 8.9, 17.9, 19.6, 1.4, 2.1, 280, 280, 'churchs.com', ARRAY['churchs cob', 'church cob sandwich'], '810 cal per sandwich (280g)'),
('churchs_french_fries', 'Church''s French Fries', 287.7, 4.1, 39.7, 12.3, 2.7, 0.0, 73, 73, 'churchs.com', ARRAY['churchs fries', 'church fries'], '210 cal per regular (73g)'),
('churchs_mac_and_cheese', 'Church''s Baked Mac & Cheese', 175.0, 7.5, 15.8, 10.0, 0.8, 1.7, 120, 120, 'churchs.com', ARRAY['churchs mac cheese', 'church macaroni'], '210 cal per regular (120g)'),
('churchs_mashed_potatoes', 'Church''s Mashed Potatoes & Gravy', 84.6, 1.5, 18.5, 0.8, 1.5, 0.8, 130, 130, 'churchs.com', ARRAY['churchs mashed potatoes', 'church potatoes gravy'], '110 cal per regular (130g)'),
('churchs_fried_okra', 'Church''s Fried Okra', 280.0, 3.0, 30.0, 15.0, 3.0, 1.0, 100, 100, 'churchs.com', ARRAY['churchs okra', 'church fried okra'], '280 cal per regular (100g)'),
('churchs_cole_slaw', 'Church''s Cole Slaw', 154.5, 0.9, 14.5, 10.9, 1.8, 10.9, 110, 110, 'churchs.com', ARRAY['churchs coleslaw', 'church slaw'], '170 cal per regular (110g)'),
('churchs_apple_pie', 'Church''s Apple Pie', 270.0, 3.0, 36.0, 13.0, 1.0, 18.0, 100, 100, 'churchs.com', ARRAY['churchs pie', 'church apple pie'], '270 cal per pie (100g)'),
('churchs_frosted_honey_biscuit', 'Church''s Frosted Honey Butter Biscuit', 400.0, 5.0, 50.0, 20.0, 0.0, 25.0, 80, 80, 'churchs.com', ARRAY['churchs frosted biscuit'], '320 cal per biscuit (80g)'),
('epl_fire_grilled_breast', 'El Pollo Loco Fire-Grilled Chicken Breast', 129.4, 21.2, 0.0, 5.3, 0.0, 0.0, 170, 170, 'elpolloloco.com', ARRAY['el pollo loco breast', 'epl chicken breast'], '220 cal per breast (170g)'),
('epl_fire_grilled_thigh', 'El Pollo Loco Fire-Grilled Chicken Thigh', 175.0, 17.5, 0.0, 12.5, 0.0, 0.0, 120, 120, 'elpolloloco.com', ARRAY['el pollo loco thigh', 'epl chicken thigh'], '210 cal per thigh (120g)'),
('epl_fire_grilled_leg', 'El Pollo Loco Fire-Grilled Chicken Leg', 133.3, 20.0, 0.0, 6.7, 0.0, 0.0, 60, 60, 'elpolloloco.com', ARRAY['el pollo loco leg', 'epl chicken leg'], '80 cal per leg (60g)'),
('epl_fire_grilled_wing', 'El Pollo Loco Fire-Grilled Chicken Wing', 180.0, 24.0, 0.0, 10.0, 0.0, 0.0, 50, 50, 'elpolloloco.com', ARRAY['el pollo loco wing', 'epl chicken wing'], '90 cal per wing (50g)'),
('epl_original_pollo_bowl', 'El Pollo Loco Original Pollo Bowl', 132.5, 9.0, 20.0, 1.8, 2.5, 0.8, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco bowl', 'epl pollo bowl'], '530 cal per bowl (400g)'),
('epl_double_chicken_bowl', 'El Pollo Loco Double Chicken Bowl', 172.0, 13.0, 17.2, 5.4, 2.6, 1.0, 500, 500, 'elpolloloco.com', ARRAY['el pollo loco double bowl'], '860 cal per bowl (500g)'),
('epl_grande_avocado_bowl', 'El Pollo Loco Grande Avocado Chicken Bowl', 162.5, 9.4, 18.5, 5.4, 2.9, 1.3, 480, 480, 'elpolloloco.com', ARRAY['el pollo loco grande bowl', 'epl avocado bowl'], '780 cal per bowl (480g)'),
('epl_classic_chicken_burrito', 'El Pollo Loco Classic Chicken Burrito', 170.0, 8.7, 21.7, 5.0, 1.7, 0.3, 300, 300, 'elpolloloco.com', ARRAY['el pollo loco burrito', 'epl classic burrito'], '510 cal per burrito (300g)'),
('epl_chicken_avocado_burrito', 'El Pollo Loco Chicken Avocado Burrito', 222.5, 11.5, 17.8, 12.0, 2.5, 1.3, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco avocado burrito'], '890 cal per burrito (400g)'),
('epl_ranchero_burrito', 'El Pollo Loco Ranchero Burrito', 217.5, 11.0, 21.0, 10.0, 1.8, 1.3, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco ranchero'], '870 cal per burrito (400g)'),
('epl_brc_burrito', 'El Pollo Loco Original BRC Burrito', 164.0, 5.6, 24.4, 4.4, 2.0, 0.4, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco brc', 'epl bean rice cheese'], '410 cal per burrito (250g)'),
('epl_chicken_avocado_quesadilla', 'El Pollo Loco Chicken Avocado Quesadilla', 313.3, 15.7, 20.0, 19.7, 2.0, 1.0, 300, 300, 'elpolloloco.com', ARRAY['el pollo loco quesadilla'], '940 cal per quesadilla (300g)'),
('epl_double_chicken_avocado_salad', 'El Pollo Loco Double Chicken Avocado Salad', 105.7, 13.7, 4.0, 4.3, 1.7, 1.7, 350, 350, 'elpolloloco.com', ARRAY['el pollo loco salad', 'epl avocado salad'], '370 cal per salad (350g)'),
('epl_chicken_taco_al_carbon', 'El Pollo Loco Chicken Taco Al Carbon', 160.0, 10.0, 18.0, 6.0, 1.0, 1.0, 100, 100, 'elpolloloco.com', ARRAY['el pollo loco taco', 'epl taco al carbon'], '160 cal per taco (100g)'),
('epl_chicken_black_bean_bowl', 'El Pollo Loco Chicken Black Bean Bowl', 115.0, 9.3, 14.3, 2.8, 4.8, 1.5, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco black bean bowl'], '460 cal per bowl (400g)'),
('epl_rice', 'El Pollo Loco Rice', 152.0, 3.2, 30.4, 1.6, 0.4, 1.2, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco rice', 'epl spanish rice'], '380 cal per large (250g)'),
('epl_black_beans', 'El Pollo Loco Black Beans', 148.0, 8.8, 26.0, 1.0, 12.0, 1.6, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco beans', 'epl black beans'], '370 cal per large (250g)'),
('epl_pinto_beans', 'El Pollo Loco Pinto Beans', 160.0, 8.0, 25.6, 2.8, 8.0, 0.0, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco pinto beans'], '400 cal per large (250g)'),
('epl_mac_and_cheese', 'El Pollo Loco Macaroni and Cheese', 256.7, 7.7, 20.0, 16.0, 0.7, 3.0, 300, 300, 'elpolloloco.com', ARRAY['el pollo loco mac cheese'], '770 cal per large (300g)'),
('epl_churros', 'El Pollo Loco Cinnamon Churros', 400.0, 3.8, 37.5, 27.5, 1.3, 8.8, 80, 80, 'elpolloloco.com', ARRAY['el pollo loco churros'], '320 cal per serving (80g)'),
('epl_tortilla_chips', 'El Pollo Loco Tortilla Chips', 400.0, 4.0, 44.0, 22.0, 4.0, 0.0, 50, 50, 'elpolloloco.com', ARRAY['el pollo loco chips'], '200 cal per serving (50g)'),
('deltaco_chicken_al_carbon', 'Del Taco Chicken Al Carbon Taco', 150.0, 10.0, 19.0, 5.0, 1.0, 0.0, 100, 100, 'deltaco.com', ARRAY['del taco al carbon', 'del taco chicken taco'], '150 cal per taco (100g)'),
('deltaco_grilled_chicken_taco', 'Del Taco Grilled Chicken Taco', 210.0, 12.0, 16.0, 12.0, 1.0, 1.0, 100, 100, 'deltaco.com', ARRAY['del taco grilled chicken'], '210 cal per taco (100g)'),
('deltaco_beyond_meat_taco', 'Del Taco Beyond Meat Taco', 300.0, 19.0, 15.0, 19.0, 2.0, 1.0, 100, 100, 'deltaco.com', ARRAY['del taco beyond taco', 'del taco plant based'], '300 cal per taco (100g)'),
('deltaco_carne_asada_street_taco', 'Del Taco Carne Asada Street Taco', 159.3, 8.8, 17.7, 4.4, 0.9, 0.9, 113, 113, 'deltaco.com', ARRAY['del taco street taco', 'del taco carne asada'], '180 cal per taco (113g)'),
('deltaco_fish_taco', 'Del Taco Beer Battered Fish Taco', 191.7, 9.2, 23.3, 7.5, 1.7, 1.7, 120, 120, 'deltaco.com', ARRAY['del taco fish taco'], '230 cal per taco (120g)'),
('deltaco_crunchy_taco', 'Del Taco Crunchy Taco', 248.0, 12.0, 16.0, 12.8, 2.4, 1.6, 125, 125, 'deltaco.com', ARRAY['del taco crunchy', 'del taco hard taco'], '310 cal per taco (125g)'),
('deltaco_8_layer_veggie', 'Del Taco 8 Layer Veggie Burrito', 176.7, 6.0, 24.0, 6.0, 3.0, 0.7, 300, 300, 'deltaco.com', ARRAY['del taco veggie burrito', 'del taco 8 layer'], '530 cal per burrito (300g)'),
('deltaco_del_beef_burrito', 'Del Taco Del Beef Burrito', 200.0, 10.8, 16.0, 9.6, 1.2, 0.8, 250, 250, 'deltaco.com', ARRAY['del taco beef burrito'], '500 cal per burrito (250g)'),
('deltaco_chicken_crunch_burrito', 'Del Taco Chicken Crunch Burrito', 184.0, 6.0, 22.8, 7.6, 0.8, 0.4, 250, 250, 'deltaco.com', ARRAY['del taco chicken crunch'], '460 cal per burrito (250g)'),
('deltaco_epic_crispy_chicken_guac', 'Del Taco Epic Crispy Chicken & Guac Burrito', 222.5, 7.3, 19.5, 13.0, 1.3, 1.0, 400, 400, 'deltaco.com', ARRAY['del taco epic burrito', 'del taco crispy chicken guac'], '890 cal per burrito (400g)'),
('deltaco_crispy_shrimp_burrito', 'Del Taco Crispy Jumbo Shrimp Burrito', 222.9, 5.1, 21.1, 12.9, 0.9, 0.9, 350, 350, 'deltaco.com', ARRAY['del taco shrimp burrito'], '780 cal per burrito (350g)'),
('deltaco_macho_combo_burrito', 'Del Taco Macho Combo Burrito', 176.6, 9.3, 16.7, 9.3, 1.5, 0.7, 538, 538, 'deltaco.com', ARRAY['del taco macho burrito', 'del taco combo burrito'], '950 cal per burrito (538g)'),
('deltaco_fries', 'Del Taco Crinkle Cut Fries', 210.0, 3.0, 27.0, 10.0, 2.0, 0.0, 100, 100, 'deltaco.com', ARRAY['del taco fries', 'del taco crinkle fries'], '210 cal per regular (100g)'),
('deltaco_loaded_queso_fries', 'Del Taco Loaded Queso Fries', 255.0, 7.5, 27.5, 14.0, 2.0, 1.0, 200, 200, 'deltaco.com', ARRAY['del taco queso fries', 'del taco loaded fries'], '510 cal per serving (200g)'),
('deltaco_chicken_cheddar_quesadilla', 'Del Taco Chicken Cheddar Quesadilla', 255.6, 12.2, 19.4, 16.1, 1.1, 0.6, 180, 180, 'deltaco.com', ARRAY['del taco quesadilla'], '460 cal per quesadilla (180g)'),
('deltaco_churros', 'Del Taco Churros', 328.6, 4.3, 42.9, 14.3, 0.0, 14.3, 70, 70, 'deltaco.com', ARRAY['del taco churros'], '230 cal per 2 pieces (70g)'),
('deltaco_chocolate_shake', 'Del Taco Chocolate Shake', 165.7, 3.7, 31.4, 7.4, 0.6, 24.0, 350, 350, 'deltaco.com', ARRAY['del taco shake', 'del taco chocolate shake'], '580 cal per small (350g)'),
('deltaco_vanilla_shake', 'Del Taco Vanilla Shake', 157.1, 3.1, 29.7, 7.1, 0.0, 22.9, 350, 350, 'deltaco.com', ARRAY['del taco vanilla shake'], '550 cal per small (350g)'),
('moes_homewrecker_chicken', 'Moe''s Homewrecker Burrito Chicken', 232.0, 11.0, 31.4, 8.4, 3.0, 2.0, 500, 500, 'moes.com', ARRAY['moes homewrecker', 'moes burrito chicken'], '1160 cal per burrito (500g)'),
('moes_homewrecker_steak', 'Moe''s Homewrecker Burrito Steak', 223.2, 10.2, 31.6, 7.8, 2.8, 2.0, 500, 500, 'moes.com', ARRAY['moes homewrecker steak', 'moes steak burrito'], '1116 cal per burrito (500g)'),
('moes_homewrecker_bowl_steak', 'Moe''s Homewrecker Bowl Steak', 179.1, 9.6, 23.8, 6.9, 3.1, 1.8, 450, 450, 'moes.com', ARRAY['moes homewrecker bowl'], '806 cal per bowl (450g)'),
('moes_burrito_bowl_chicken', 'Moe''s Burrito Bowl Chicken', 181.0, 10.8, 24.8, 5.8, 2.5, 1.5, 400, 400, 'moes.com', ARRAY['moes bowl chicken', 'moes chicken bowl'], '724 cal per bowl (400g)'),
('moes_burrito_bowl_steak', 'Moe''s Burrito Bowl Steak', 170.0, 9.8, 25.0, 5.0, 2.3, 1.3, 400, 400, 'moes.com', ARRAY['moes bowl steak', 'moes steak bowl'], '680 cal per bowl (400g)'),
('moes_burrito_chicken', 'Moe''s Burrito Chicken', 227.8, 11.3, 33.1, 6.7, 2.4, 1.6, 450, 450, 'moes.com', ARRAY['moes chicken burrito'], '1025 cal per burrito (450g)'),
('moes_burrito_steak', 'Moe''s Burrito Steak', 218.0, 10.4, 33.3, 6.0, 2.2, 1.3, 450, 450, 'moes.com', ARRAY['moes steak burrito regular'], '981 cal per burrito (450g)'),
('moes_quesadilla_chicken', 'Moe''s Quesadilla Chicken', 223.6, 17.7, 15.9, 12.3, 0.9, 0.9, 220, 220, 'moes.com', ARRAY['moes quesadilla', 'moes chicken quesadilla'], '492 cal per quesadilla (220g)'),
('moes_quesadilla_steak', 'Moe''s Quesadilla Steak', 203.6, 15.9, 16.4, 10.9, 0.9, 0.9, 220, 220, 'moes.com', ARRAY['moes steak quesadilla'], '448 cal per quesadilla (220g)'),
('moes_nachos_chicken', 'Moe''s Nachos Chicken', 146.3, 11.7, 12.3, 7.3, 2.0, 1.0, 300, 300, 'moes.com', ARRAY['moes nachos', 'moes chicken nachos'], '439 cal per serving (300g)'),
('moes_salad_steak', 'Moe''s Salad Steak', 120.6, 9.7, 10.6, 6.3, 2.3, 1.4, 350, 350, 'moes.com', ARRAY['moes salad', 'moes steak salad'], '422 cal per salad (350g)'),
('moes_moe_meat_bowl', 'Moe''s Moe Meat Moe Cheese Bowl', 197.8, 14.4, 17.3, 9.8, 2.7, 1.3, 450, 450, 'moes.com', ARRAY['moes moe meat bowl', 'moes double meat'], '890 cal per bowl (450g)'),
('moes_moe_meat_burrito', 'Moe''s Moe Meat Moe Cheese Burrito', 198.0, 15.8, 21.2, 10.6, 2.2, 1.0, 500, 500, 'moes.com', ARRAY['moes moe meat burrito'], '990 cal per burrito (500g)'),
('moes_chocolate_chip_cookie', 'Moe''s Chocolate Chip Cookie', 400.0, 5.0, 57.5, 20.0, 0.0, 30.0, 40, 40, 'moes.com', ARRAY['moes cookie'], '160 cal per cookie (40g)'),
('moes_chips', 'Moe''s Tortilla Chips', 462.0, 6.0, 50.0, 25.3, 3.3, 0.0, 150, 150, 'moes.com', ARRAY['moes chips', 'moes tortilla chips'], '693 cal per serving (150g)'),
('moes_queso', 'Moe''s Queso', 216.7, 5.0, 13.3, 15.0, 0.0, 3.3, 60, 60, 'moes.com', ARRAY['moes queso', 'moes cheese dip'], '130 cal per serving (60g)'),
('moes_guacamole', 'Moe''s Guacamole', 183.3, 1.7, 8.3, 16.7, 5.0, 0.0, 60, 60, 'moes.com', ARRAY['moes guac', 'moes guacamole'], '110 cal per serving (60g)'),
('qdoba_chicken_burrito', 'Qdoba Chicken Burrito', 188.9, 10.0, 21.1, 7.8, 2.2, 1.1, 450, 450, 'qdoba.com', ARRAY['qdoba burrito', 'qdoba chicken burrito'], '850 cal per burrito (450g)'),
('qdoba_steak_burrito', 'Qdoba Steak Burrito', 200.0, 10.4, 21.8, 8.4, 2.2, 1.1, 450, 450, 'qdoba.com', ARRAY['qdoba steak burrito'], '900 cal per burrito (450g)'),
('qdoba_chicken_bowl', 'Qdoba Chicken Burrito Bowl', 165.0, 10.0, 11.8, 8.5, 2.8, 1.3, 400, 400, 'qdoba.com', ARRAY['qdoba bowl', 'qdoba chicken bowl'], '660 cal per bowl (400g)'),
('qdoba_steak_bowl', 'Qdoba Steak Burrito Bowl', 177.5, 10.5, 12.5, 9.3, 2.8, 1.3, 400, 400, 'qdoba.com', ARRAY['qdoba steak bowl'], '710 cal per bowl (400g)'),
('qdoba_chicken_taco', 'Qdoba Chicken Taco', 260.0, 14.0, 17.0, 12.0, 1.0, 1.0, 100, 100, 'qdoba.com', ARRAY['qdoba taco', 'qdoba chicken taco'], '260 cal per taco (100g)'),
('qdoba_steak_taco', 'Qdoba Steak Taco', 280.0, 14.0, 18.0, 13.0, 1.0, 1.0, 100, 100, 'qdoba.com', ARRAY['qdoba steak taco'], '280 cal per taco (100g)'),
('qdoba_chicken_quesadilla', 'Qdoba Chicken Quesadilla', 281.8, 18.2, 16.4, 15.5, 0.9, 0.9, 220, 220, 'qdoba.com', ARRAY['qdoba quesadilla'], '620 cal per quesadilla (220g)'),
('qdoba_chicken_nachos', 'Qdoba Chicken Nachos', 243.3, 11.0, 18.3, 14.7, 3.0, 1.3, 300, 300, 'qdoba.com', ARRAY['qdoba nachos'], '730 cal per serving (300g)'),
('qdoba_chips_guac', 'Qdoba Chips & Guacamole', 286.7, 3.3, 30.0, 18.7, 4.0, 0.7, 150, 150, 'qdoba.com', ARRAY['qdoba chips guacamole', 'qdoba chips and guac'], '430 cal per serving (150g)'),
('qdoba_chips_queso', 'Qdoba Chips & Queso', 300.0, 4.7, 30.7, 18.0, 2.0, 2.0, 150, 150, 'qdoba.com', ARRAY['qdoba chips queso', 'qdoba chips and queso'], '450 cal per serving (150g)'),
('qdoba_queso', 'Qdoba Three Cheese Queso', 200.0, 5.0, 10.0, 15.0, 0.0, 3.3, 60, 60, 'qdoba.com', ARRAY['qdoba queso dip', 'qdoba cheese dip'], '120 cal per side (60g)'),
('qdoba_guacamole', 'Qdoba Guacamole', 166.7, 1.7, 8.3, 15.0, 5.0, 0.0, 60, 60, 'qdoba.com', ARRAY['qdoba guac'], '100 cal per side (60g)'),
('qdoba_mexican_rice', 'Qdoba Mexican Rice', 150.0, 2.5, 27.5, 2.5, 0.8, 0.0, 120, 120, 'qdoba.com', ARRAY['qdoba rice'], '180 cal per serving (120g)'),
('qdoba_black_beans', 'Qdoba Black Beans', 91.7, 7.5, 15.0, 0.8, 5.0, 0.0, 120, 120, 'qdoba.com', ARRAY['qdoba beans', 'qdoba black beans'], '110 cal per serving (120g)'),
('qdoba_grilled_chicken', 'Qdoba Grilled Chicken', 118.2, 21.8, 0.9, 2.7, 0.0, 0.0, 110, 110, 'qdoba.com', ARRAY['qdoba chicken'], '130 cal per serving (110g)'),
('qdoba_grilled_steak', 'Qdoba Grilled Steak', 154.5, 20.0, 1.8, 5.5, 0.0, 0.0, 110, 110, 'qdoba.com', ARRAY['qdoba steak'], '170 cal per serving (110g)'),
('qdoba_flour_tortilla', 'Qdoba Flour Tortilla', 300.0, 7.0, 46.0, 9.0, 2.0, 2.0, 100, 100, 'qdoba.com', ARRAY['qdoba tortilla'], '300 cal per tortilla (100g)'),
('peiwei_orange_chicken', 'Pei Wei Orange Chicken', 217.8, 7.6, 20.9, 11.1, 2.2, 12.4, 450, 450, 'peiwei.com', ARRAY['pei wei orange chicken'], '980 cal per regular (450g)'),
('peiwei_kung_pao_chicken', 'Pei Wei Kung Pao Chicken', 243.8, 11.5, 11.0, 15.0, 1.8, 6.5, 400, 400, 'peiwei.com', ARRAY['pei wei kung pao'], '975 cal per regular (400g)'),
('peiwei_beef_broccoli', 'Pei Wei Beef & Broccoli', 197.5, 8.5, 13.3, 12.3, 1.5, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei beef broccoli'], '790 cal per regular (400g)'),
('peiwei_chicken_broccoli', 'Pei Wei Chicken & Broccoli', 166.5, 10.0, 12.0, 6.8, 1.3, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei chicken broccoli'], '666 cal per regular (400g)'),
('peiwei_mongolian_chicken', 'Pei Wei Mongolian Chicken', 159.0, 9.8, 9.8, 6.8, 0.5, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei mongolian chicken'], '636 cal per regular (400g)'),
('peiwei_mongolian_steak', 'Pei Wei Mongolian Steak', 190.0, 8.3, 11.0, 12.3, 0.8, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei mongolian steak'], '760 cal per regular (400g)'),
('peiwei_sesame_chicken', 'Pei Wei Sesame Chicken', 223.8, 10.3, 14.0, 11.8, 1.3, 10.0, 400, 400, 'peiwei.com', ARRAY['pei wei sesame chicken'], '895 cal per regular (400g)'),
('peiwei_general_tsos', 'Pei Wei Spicy General Tso''s Chicken', 201.3, 10.0, 12.0, 10.5, 1.3, 7.8, 400, 400, 'peiwei.com', ARRAY['pei wei general tso', 'pei wei general tsos'], '805 cal per regular (400g)'),
('peiwei_teriyaki_chicken', 'Pei Wei Teriyaki Chicken', 207.8, 9.3, 18.7, 9.1, 1.3, 15.1, 450, 450, 'peiwei.com', ARRAY['pei wei teriyaki'], '935 cal per regular (450g)'),
('peiwei_sweet_sour_chicken', 'Pei Wei Sweet & Sour Chicken', 217.8, 7.3, 21.6, 11.1, 2.4, 12.9, 450, 450, 'peiwei.com', ARRAY['pei wei sweet and sour'], '980 cal per regular (450g)'),
('peiwei_firecracker_chicken', 'Pei Wei Firecracker Chicken', 242.2, 10.2, 21.3, 13.3, 0.2, 11.6, 450, 450, 'peiwei.com', ARRAY['pei wei firecracker'], '1090 cal per regular (450g)'),
('peiwei_thai_coconut_curry', 'Pei Wei Thai Coconut Curry Chicken', 160.0, 13.5, 10.5, 2.0, 0.8, 5.3, 400, 400, 'peiwei.com', ARRAY['pei wei thai curry', 'pei wei coconut curry'], '640 cal per regular (400g)'),
('peiwei_chicken_fried_rice', 'Pei Wei Chicken Fried Rice', 221.2, 10.8, 27.4, 5.4, 1.0, 5.0, 500, 500, 'peiwei.com', ARRAY['pei wei fried rice'], '1106 cal per bowl (500g)'),
('peiwei_chicken_lo_mein', 'Pei Wei Chicken Lo Mein', 234.0, 14.0, 24.6, 8.4, 1.6, 4.6, 500, 500, 'peiwei.com', ARRAY['pei wei lo mein'], '1170 cal per bowl (500g)'),
('peiwei_chicken_pad_thai', 'Pei Wei Chicken Pad Thai', 270.9, 14.9, 30.4, 7.6, 2.5, 9.1, 550, 550, 'peiwei.com', ARRAY['pei wei pad thai'], '1490 cal per bowl (550g)'),
('peiwei_dan_dan_noodles', 'Pei Wei Dan Dan Noodles', 220.0, 10.2, 24.4, 8.9, 1.3, 5.6, 450, 450, 'peiwei.com', ARRAY['pei wei dan dan'], '990 cal per bowl (450g)'),
('peiwei_asian_chopped_salad', 'Pei Wei Asian Chopped Chicken Salad', 188.6, 13.1, 12.6, 10.0, 1.7, 3.7, 350, 350, 'peiwei.com', ARRAY['pei wei salad', 'pei wei chicken salad'], '660 cal per salad (350g)'),
('peiwei_chicken_egg_roll', 'Pei Wei Chicken Egg Roll', 250.0, 12.5, 30.0, 17.5, 3.8, 5.0, 80, 80, 'peiwei.com', ARRAY['pei wei egg roll'], '200 cal per roll (80g)'),
('peiwei_spring_rolls', 'Pei Wei Vegetable Spring Rolls', 200.0, 3.3, 25.0, 10.0, 3.3, 3.3, 60, 60, 'peiwei.com', ARRAY['pei wei spring rolls'], '120 cal per roll (60g)'),
('peiwei_crab_wonton', 'Pei Wei Crab Wonton', 340.0, 12.0, 28.0, 20.0, 4.0, 0.0, 25, 25, 'peiwei.com', ARRAY['pei wei wonton', 'pei wei crab rangoon'], '85 cal per wonton (25g)'),
('peiwei_edamame', 'Pei Wei Edamame', 133.3, 10.0, 8.3, 5.0, 3.3, 1.7, 120, 120, 'peiwei.com', ARRAY['pei wei edamame'], '160 cal per serving (120g)'),
('pfchangs_chicken_lettuce_wraps', 'P.F. Chang''s Chicken Lettuce Wraps', 200.0, 10.4, 22.2, 7.4, 2.2, 11.5, 365, 365, 'pfchangs.com', ARRAY['pf changs lettuce wraps', 'pfchangs wraps'], '730 cal per full order (365g)'),
('pfchangs_orange_chicken', 'P.F. Chang''s Orange Chicken', 290.0, 10.0, 27.5, 14.5, 1.3, 18.8, 400, 400, 'pfchangs.com', ARRAY['pf changs orange chicken'], '1160 cal per entree (400g)'),
('pfchangs_kung_pao_chicken', 'P.F. Chang''s Kung Pao Chicken', 245.0, 12.5, 15.0, 14.5, 2.5, 7.5, 400, 400, 'pfchangs.com', ARRAY['pf changs kung pao'], '980 cal per entree (400g)'),
('pfchangs_beef_broccoli', 'P.F. Chang''s Beef with Broccoli', 220.0, 10.5, 17.5, 11.5, 2.0, 7.5, 400, 400, 'pfchangs.com', ARRAY['pf changs beef broccoli'], '880 cal per entree (400g)'),
('pfchangs_mongolian_beef', 'P.F. Chang''s Mongolian Beef', 230.0, 10.0, 19.0, 12.5, 1.3, 10.0, 400, 400, 'pfchangs.com', ARRAY['pf changs mongolian beef'], '920 cal per entree (400g)'),
('pfchangs_crispy_honey_chicken', 'P.F. Chang''s Crispy Honey Chicken', 285.0, 10.0, 28.8, 14.0, 1.0, 20.0, 400, 400, 'pfchangs.com', ARRAY['pf changs honey chicken'], '1140 cal per entree (400g)'),
('pfchangs_kung_pao_shrimp', 'P.F. Chang''s Kung Pao Shrimp', 255.0, 10.0, 17.5, 15.0, 2.5, 7.5, 400, 400, 'pfchangs.com', ARRAY['pf changs kung pao shrimp'], '1020 cal per entree (400g)'),
('pfchangs_pad_thai_chicken', 'P.F. Chang''s Pad Thai Chicken', 268.0, 12.0, 29.0, 12.6, 2.0, 14.0, 500, 500, 'pfchangs.com', ARRAY['pf changs pad thai'], '1340 cal per entree (500g)'),
('pfchangs_lo_mein_chicken', 'P.F. Chang''s Lo Mein Chicken', 207.5, 10.0, 18.5, 10.0, 1.5, 5.0, 400, 400, 'pfchangs.com', ARRAY['pf changs lo mein'], '830 cal per entree (400g)'),
('pfchangs_fried_rice_chicken', 'P.F. Chang''s Fried Rice with Chicken', 244.4, 11.1, 35.3, 5.8, 1.1, 3.3, 450, 450, 'pfchangs.com', ARRAY['pf changs fried rice'], '1100 cal per entree (450g)'),
('pfchangs_ma_po_tofu', 'P.F. Chang''s Ma Po Tofu', 262.9, 10.3, 16.3, 16.9, 2.3, 4.3, 350, 350, 'pfchangs.com', ARRAY['pf changs mapo tofu'], '920 cal per entree (350g)'),
('pfchangs_shrimp_dumplings_steamed', 'P.F. Chang''s Shrimp Dumplings Steamed', 173.3, 8.0, 14.0, 6.0, 0.7, 2.0, 150, 150, 'pfchangs.com', ARRAY['pf changs shrimp dumplings'], '260 cal per 6pc (150g)'),
('pfchangs_chicken_dumplings_fried', 'P.F. Chang''s Chicken Dumplings Pan-Fried', 246.7, 10.0, 18.7, 12.7, 1.3, 2.7, 150, 150, 'pfchangs.com', ARRAY['pf changs chicken dumplings', 'pf changs potstickers'], '370 cal per 6pc (150g)'),
('pfchangs_crab_wontons', 'P.F. Chang''s Crab Wontons', 266.7, 8.0, 18.0, 16.0, 0.7, 2.0, 150, 150, 'pfchangs.com', ARRAY['pf changs crab wontons', 'pf changs rangoon'], '400 cal per 6pc (150g)'),
('pfchangs_dynamite_shrimp', 'P.F. Chang''s Dynamite Shrimp', 256.0, 10.0, 16.0, 15.6, 0.8, 8.0, 250, 250, 'pfchangs.com', ARRAY['pf changs dynamite shrimp'], '640 cal per appetizer (250g)'),
('pfchangs_white_rice', 'P.F. Chang''s White Rice', 172.0, 1.2, 36.0, 1.2, 0.4, 0.0, 250, 250, 'pfchangs.com', ARRAY['pf changs rice', 'pf changs steamed rice'], '430 cal per side (250g)'),
('pfchangs_brown_rice', 'P.F. Chang''s Brown Rice', 152.0, 1.2, 32.0, 2.4, 1.6, 0.0, 250, 250, 'pfchangs.com', ARRAY['pf changs brown rice'], '380 cal per side (250g)'),
('pfchangs_egg_drop_soup', 'P.F. Chang''s Egg Drop Soup', 24.0, 1.6, 2.8, 0.8, 0.0, 0.8, 250, 250, 'pfchangs.com', ARRAY['pf changs egg drop soup'], '60 cal per bowl (250g)'),
('pfchangs_wonton_soup', 'P.F. Chang''s Wonton Soup', 82.9, 4.6, 7.4, 4.0, 0.6, 1.4, 350, 350, 'pfchangs.com', ARRAY['pf changs wonton soup'], '290 cal per bowl (350g)'),
('pfchangs_chocolate_lava_cake', 'P.F. Chang''s Chocolate Lava Cake', 344.4, 5.6, 41.7, 19.4, 1.7, 27.8, 180, 180, 'pfchangs.com', ARRAY['pf changs lava cake', 'pf changs chocolate cake'], '620 cal per dessert (180g)'),
('sweetgreen_harvest_bowl', 'Sweetgreen Harvest Bowl', 191.9, 10.2, 16.6, 9.7, 2.5, 2.8, 362, 362, 'sweetgreen.com', ARRAY['sweetgreen harvest', 'sweetgreen harvest bowl'], '695 cal per bowl (362g)'),
('sweetgreen_kale_caesar', 'Sweetgreen Kale Caesar Salad', 126.9, 12.5, 4.1, 7.5, 1.6, 1.3, 319, 319, 'sweetgreen.com', ARRAY['sweetgreen caesar', 'sweetgreen kale caesar'], '405 cal per salad (319g)'),
('sweetgreen_chicken_pesto_parm', 'Sweetgreen Chicken Pesto Parm Bowl', 155.9, 10.3, 11.2, 8.5, 2.4, 1.2, 340, 340, 'sweetgreen.com', ARRAY['sweetgreen pesto parm', 'sweetgreen chicken pesto'], '530 cal per bowl (340g)'),
('sweetgreen_crispy_rice_bowl', 'Sweetgreen Crispy Rice Bowl', 167.1, 7.4, 18.2, 7.6, 2.4, 2.4, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen crispy rice'], '635 cal per bowl (380g)'),
('sweetgreen_fish_taco_bowl', 'Sweetgreen Fish Taco Bowl', 180.3, 8.2, 12.4, 11.6, 4.2, 1.1, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen fish taco'], '685 cal per bowl (380g)'),
('sweetgreen_shroomami', 'Sweetgreen Shroomami Bowl', 180.3, 7.1, 15.0, 10.8, 2.4, 2.1, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen shroomami', 'sweetgreen mushroom bowl'], '685 cal per bowl (380g)'),
('sweetgreen_garden_cobb', 'Sweetgreen Garden Cobb Salad', 162.5, 5.5, 8.3, 12.8, 3.8, 2.3, 400, 400, 'sweetgreen.com', ARRAY['sweetgreen cobb', 'sweetgreen garden cobb'], '650 cal per salad (400g)'),
('sweetgreen_buffalo_chicken', 'Sweetgreen Buffalo Chicken Bowl', 139.1, 9.7, 6.9, 8.4, 2.5, 1.9, 320, 320, 'sweetgreen.com', ARRAY['sweetgreen buffalo', 'sweetgreen buffalo chicken'], '445 cal per bowl (320g)'),
('sweetgreen_guacamole_greens', 'Sweetgreen Guacamole Greens Salad', 135.6, 6.7, 7.5, 9.0, 3.5, 0.7, 402, 402, 'sweetgreen.com', ARRAY['sweetgreen guac greens'], '545 cal per salad (402g)'),
('sweetgreen_super_green_goddess', 'Sweetgreen Super Green Goddess Salad', 121.1, 5.3, 12.1, 7.1, 3.7, 2.6, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen green goddess'], '460 cal per salad (380g)'),
('sweetgreen_bbq_chicken', 'Sweetgreen BBQ Chicken Salad', 158.1, 8.6, 15.7, 9.2, 2.7, 4.1, 370, 370, 'sweetgreen.com', ARRAY['sweetgreen bbq', 'sweetgreen bbq chicken salad'], '585 cal per salad (370g)'),
('sweetgreen_warm_quinoa', 'Sweetgreen Warm Quinoa', 133.3, 3.3, 20.0, 2.2, 2.2, 0.0, 90, 90, 'sweetgreen.com', ARRAY['sweetgreen quinoa'], '120 cal per serving (90g)'),
('sweetgreen_warm_wild_rice', 'Sweetgreen Warm Wild Rice', 146.2, 2.3, 30.0, 1.5, 1.5, 0.0, 130, 130, 'sweetgreen.com', ARRAY['sweetgreen wild rice'], '190 cal per serving (130g)'),
('sweetgreen_blackened_chicken', 'Sweetgreen Blackened Chicken', 130.0, 17.0, 1.0, 6.0, 1.0, 0.0, 100, 100, 'sweetgreen.com', ARRAY['sweetgreen chicken'], '130 cal per serving (100g)'),
('sweetgreen_avocado', 'Sweetgreen Avocado', 200.0, 3.8, 11.3, 18.8, 11.3, 0.0, 80, 80, 'sweetgreen.com', ARRAY['sweetgreen avocado'], '160 cal per serving (80g)'),
('cava_harissa_avocado_bowl', 'Cava Harissa Avocado Bowl', 184.4, 9.1, 13.8, 10.9, 2.9, 2.7, 450, 450, 'cava.com', ARRAY['cava harissa avocado', 'cava avocado bowl'], '830 cal per bowl (450g)'),
('cava_greek_salad_bowl', 'Cava Greek Salad Bowl', 152.6, 9.7, 5.0, 10.5, 1.8, 1.3, 380, 380, 'cava.com', ARRAY['cava greek salad', 'cava greek bowl'], '580 cal per bowl (380g)'),
('cava_chicken_rice_bowl', 'Cava Chicken + Rice Bowl', 166.7, 9.5, 10.5, 10.0, 1.4, 1.9, 420, 420, 'cava.com', ARRAY['cava chicken bowl', 'cava rice bowl'], '700 cal per bowl (420g)'),
('cava_steak_harissa_bowl', 'Cava Steak + Harissa Bowl', 152.5, 9.3, 9.8, 8.8, 1.8, 1.8, 400, 400, 'cava.com', ARRAY['cava steak bowl', 'cava harissa bowl'], '610 cal per bowl (400g)'),
('cava_falafel_crunch_bowl', 'Cava Falafel Crunch Bowl', 191.1, 5.3, 19.6, 12.4, 3.1, 2.9, 450, 450, 'cava.com', ARRAY['cava falafel bowl'], '860 cal per bowl (450g)'),
('cava_spicy_lamb_avocado', 'Cava Spicy Lamb + Avocado Bowl', 177.8, 9.6, 10.9, 11.6, 2.7, 2.4, 450, 450, 'cava.com', ARRAY['cava lamb bowl', 'cava spicy lamb'], '800 cal per bowl (450g)'),
('cava_harissa_chicken_power', 'Cava Harissa Chicken Power Bowl', 155.0, 6.3, 10.8, 10.0, 2.0, 2.8, 400, 400, 'cava.com', ARRAY['cava power bowl', 'cava harissa chicken'], '620 cal per bowl (400g)'),
('cava_crispy_falafel_pita', 'Cava Crispy Falafel Pita', 272.9, 8.6, 18.3, 17.1, 2.9, 2.3, 350, 350, 'cava.com', ARRAY['cava falafel pita', 'cava pita wrap'], '955 cal per pita (350g)'),
('cava_grilled_chicken', 'Cava Grilled Chicken', 178.6, 17.9, 1.4, 7.1, 0.0, 0.0, 140, 140, 'cava.com', ARRAY['cava chicken'], '250 cal per serving (140g)'),
('cava_grilled_steak', 'Cava Grilled Steak', 164.3, 16.4, 3.6, 7.1, 0.0, 0.0, 140, 140, 'cava.com', ARRAY['cava steak'], '230 cal per serving (140g)'),
('cava_falafel', 'Cava Falafel', 291.7, 6.7, 30.0, 15.0, 5.0, 1.7, 120, 120, 'cava.com', ARRAY['cava falafel'], '350 cal per serving (120g)'),
('cava_spicy_lamb_meatballs', 'Cava Spicy Lamb Meatballs', 221.4, 13.6, 12.1, 11.4, 0.7, 1.4, 140, 140, 'cava.com', ARRAY['cava lamb meatballs', 'cava meatballs'], '310 cal per serving (140g)'),
('cava_saffron_rice', 'Cava Saffron Basmati Rice', 145.0, 3.0, 27.0, 3.0, 0.5, 0.0, 200, 200, 'cava.com', ARRAY['cava rice', 'cava basmati'], '290 cal per serving (200g)'),
('cava_greens_grains', 'Cava Greens & Grains Base', 88.0, 4.0, 14.0, 2.0, 2.7, 0.7, 150, 150, 'cava.com', ARRAY['cava greens grains'], '132 cal per serving (150g)'),
('cava_pita', 'Cava Pita', 287.5, 3.8, 40.0, 5.0, 2.5, 1.3, 80, 80, 'cava.com', ARRAY['cava pita bread'], '230 cal per pita (80g)'),
('cava_hummus', 'Cava Hummus', 100.0, 3.3, 10.0, 5.0, 1.7, 0.0, 30, 30, 'cava.com', ARRAY['cava hummus'], '30 cal per serving (30g)'),
('cava_crazy_feta', 'Cava Crazy Feta', 200.0, 5.0, 6.7, 16.7, 0.0, 3.3, 30, 30, 'cava.com', ARRAY['cava feta', 'cava crazy feta dip'], '60 cal per serving (30g)'),
('cava_tzatziki', 'Cava Tzatziki', 83.3, 3.3, 3.3, 6.7, 0.0, 3.3, 30, 30, 'cava.com', ARRAY['cava tzatziki'], '25 cal per serving (30g)'),
('cava_harissa', 'Cava Harissa', 200.0, 3.3, 10.0, 16.7, 3.3, 3.3, 30, 30, 'cava.com', ARRAY['cava harissa dip'], '60 cal per serving (30g)'),
('cava_greek_vinaigrette', 'Cava Greek Vinaigrette', 433.3, 0.0, 3.3, 46.7, 0.0, 3.3, 30, 30, 'cava.com', ARRAY['cava vinaigrette', 'cava greek dressing'], '130 cal per serving (30g)'),
('cava_lemon_herb_tahini', 'Cava Lemon Herb Tahini', 233.3, 1.7, 6.7, 20.0, 0.0, 1.7, 30, 30, 'cava.com', ARRAY['cava tahini'], '70 cal per serving (30g)'),
('cava_avocado', 'Cava Avocado', 200.0, 2.5, 11.3, 18.8, 8.8, 0.0, 80, 80, 'cava.com', ARRAY['cava avocado'], '160 cal per serving (80g)'),
('waba_chicken_bowl', 'WaBa Grill Chicken Bowl', 152.4, 9.0, 23.8, 2.6, 0.2, 2.9, 420, 420, 'wabagrill.com', ARRAY['waba chicken bowl', 'waba grill chicken'], '640 cal per bowl (420g)'),
('waba_white_chicken_bowl', 'WaBa Grill White Meat Chicken Bowl', 150.0, 11.0, 23.8, 1.2, 0.2, 2.9, 420, 420, 'wabagrill.com', ARRAY['waba white chicken bowl', 'waba white meat'], '630 cal per bowl (420g)'),
('waba_sweet_spicy_bowl', 'WaBa Grill Sweet & Spicy Chicken Bowl', 161.9, 9.0, 28.6, 2.6, 0.2, 7.9, 420, 420, 'wabagrill.com', ARRAY['waba sweet spicy', 'waba spicy chicken'], '680 cal per bowl (420g)'),
('waba_steak_bowl', 'WaBa Grill Rib-Eye Steak Bowl', 171.4, 6.9, 26.2, 4.3, 0.2, 5.0, 420, 420, 'wabagrill.com', ARRAY['waba steak bowl', 'waba ribeye'], '720 cal per bowl (420g)'),
('waba_chicken_steak_bowl', 'WaBa Grill Chicken & Steak Bowl', 169.0, 8.8, 23.8, 3.8, 0.2, 4.0, 420, 420, 'wabagrill.com', ARRAY['waba combo bowl', 'waba chicken steak'], '710 cal per bowl (420g)'),
('waba_salmon_bowl', 'WaBa Grill Wild Caught Salmon Bowl', 128.6, 6.9, 21.4, 1.2, 0.2, 2.1, 420, 420, 'wabagrill.com', ARRAY['waba salmon bowl'], '540 cal per bowl (420g)'),
('waba_shrimp_bowl', 'WaBa Grill Jumbo Shrimp Bowl', 116.7, 4.5, 21.4, 0.2, 0.2, 2.1, 420, 420, 'wabagrill.com', ARRAY['waba shrimp bowl'], '490 cal per bowl (420g)'),
('waba_tofu_bowl', 'WaBa Grill Organic Tofu Bowl', 140.5, 5.5, 21.4, 2.6, 0.2, 2.1, 420, 420, 'wabagrill.com', ARRAY['waba tofu bowl'], '590 cal per bowl (420g)'),
('waba_chicken_mini_bowl', 'WaBa Grill Chicken Mini Bowl', 145.5, 7.7, 22.7, 2.3, 0.5, 4.1, 220, 220, 'wabagrill.com', ARRAY['waba mini bowl', 'waba small bowl'], '320 cal per mini bowl (220g)'),
('waba_white_chicken_mini', 'WaBa Grill White Meat Chicken Mini Bowl', 145.5, 9.5, 22.7, 0.9, 0.5, 4.1, 220, 220, 'wabagrill.com', ARRAY['waba white chicken mini'], '320 cal per mini bowl (220g)'),
('waba_chicken_plate', 'WaBa Grill Chicken Plate', 149.1, 9.8, 20.0, 2.7, 0.5, 3.8, 550, 550, 'wabagrill.com', ARRAY['waba chicken plate'], '820 cal per plate (550g)'),
('waba_white_chicken_plate', 'WaBa Grill White Meat Chicken Plate', 145.5, 11.8, 18.2, 1.3, 0.5, 3.8, 550, 550, 'wabagrill.com', ARRAY['waba white chicken plate'], '800 cal per plate (550g)'),
('waba_steak_plate', 'WaBa Grill Rib-Eye Steak Plate', 178.2, 8.0, 23.6, 4.9, 0.5, 6.4, 550, 550, 'wabagrill.com', ARRAY['waba steak plate'], '980 cal per plate (550g)'),
('waba_salmon_plate', 'WaBa Grill Wild Caught Salmon Plate', 127.3, 7.5, 20.0, 1.3, 0.5, 3.3, 550, 550, 'wabagrill.com', ARRAY['waba salmon plate'], '700 cal per plate (550g)'),
('waba_chicken_veggie_bowl', 'WaBa Grill Chicken Veggie Bowl', 131.1, 8.7, 20.0, 2.4, 3.1, 3.8, 450, 450, 'wabagrill.com', ARRAY['waba veggie bowl chicken'], '590 cal per veggie bowl (450g)'),
('waba_white_chicken_veggie', 'WaBa Grill White Meat Chicken Veggie Bowl', 128.9, 10.4, 20.0, 1.1, 0.9, 3.8, 450, 450, 'wabagrill.com', ARRAY['waba white chicken veggie'], '580 cal per veggie bowl (450g)'),
('waba_chicken_taco', 'WaBa Grill Chicken Taco', 233.3, 14.4, 22.2, 12.2, 2.2, 3.3, 90, 90, 'wabagrill.com', ARRAY['waba taco', 'waba chicken taco'], '210 cal per taco (90g)'),
('waba_steak_taco', 'WaBa Grill Steak Taco', 266.7, 11.1, 22.2, 15.6, 2.2, 4.4, 90, 90, 'wabagrill.com', ARRAY['waba steak taco'], '240 cal per taco (90g)'),
('waba_shrimp_taco', 'WaBa Grill Shrimp Taco', 188.9, 10.0, 22.2, 8.9, 2.2, 3.3, 90, 90, 'wabagrill.com', ARRAY['waba shrimp taco'], '170 cal per taco (90g)'),
('waba_house_salad', 'WaBa Grill Signature House Salad', 91.4, 12.6, 5.7, 2.3, 0.9, 1.1, 350, 350, 'wabagrill.com', ARRAY['waba salad', 'waba house salad'], '320 cal per salad (350g)'),
('waba_spicy_asian_salad', 'WaBa Grill Spicy Asian Salad', 120.0, 14.0, 8.6, 2.9, 1.4, 4.0, 350, 350, 'wabagrill.com', ARRAY['waba asian salad', 'waba spicy salad'], '420 cal per salad (350g)'),
('waba_white_rice', 'WaBa Grill White Rice', 185.0, 1.5, 40.0, 1.0, 0.0, 0.0, 200, 200, 'wabagrill.com', ARRAY['waba rice', 'waba white rice'], '370 cal per side (200g)'),
('waba_brown_rice', 'WaBa Grill Brown Rice', 160.0, 2.0, 33.0, 2.0, 1.5, 0.0, 200, 200, 'wabagrill.com', ARRAY['waba brown rice'], '320 cal per side (200g)'),
('waba_pork_dumplings', 'WaBa Grill Pork Veggie Dumplings', 175.0, 5.0, 20.0, 8.3, 0.8, 1.7, 120, 120, 'wabagrill.com', ARRAY['waba dumplings', 'waba potstickers'], '210 cal per 6pc (120g)'),
('waba_miso_soup', 'WaBa Grill Miso Soup', 12.0, 0.8, 1.2, 0.4, 0.4, 0.4, 250, 250, 'wabagrill.com', ARRAY['waba miso', 'waba soup'], '30 cal per bowl (250g)'),
('waba_steamed_veggies', 'WaBa Grill Steamed Veggies', 33.3, 2.0, 5.3, 0.7, 2.0, 2.0, 150, 150, 'wabagrill.com', ARRAY['waba vegetables', 'waba steamed vegetables'], '50 cal per side (150g)'),
-- =============================================================================
-- BATCH 9: Restaurant Nutrition Data (WITH MICRONUTRIENTS)
-- Teriyaki Madness, Sarku Japan, Yoshinoya, Halal Guys, Captain D's,
-- Long John Silver's, Checkers/Rally's, White Castle, Cook Out, Bojangles
-- Sources: Official restaurant nutrition pages, fastfoodnutrition.org,
--          eatthismuch.com, nutritionix.com, myfooddiary.com
-- Generated: 2026-02-28
-- =============================================================================
-- =============================================================================
-- 1. TERIYAKI MADNESS (teriyakimadness.com)
-- Source: teriyakimadness.com/nutritionals/, eatthismuch.com
-- =============================================================================
-- =============================================================================
-- 2. SARKU JAPAN (sarkujapan.com)
-- Source: sarkujapan.com/nutrition/, calorieking.com, carbmanager.com
-- =============================================================================
-- =============================================================================
-- 3. YOSHINOYA (yoshinoyaamerica.com)
-- Source: yoshinoyaamerica.com/nutrition, eatthismuch.com, carbmanager.com
-- =============================================================================
-- =============================================================================
-- 4. HALAL GUYS (thehalalguys.com)
-- Source: thehalalguys.com/nutritional-guide/ - official data with serving weights
-- =============================================================================
-- =============================================================================
-- 5. CAPTAIN D'S (captainds.com)
-- Source: captainds.com nutrition chart, myfooddiary.com, fastfoodnutrition.org
-- =============================================================================
-- =============================================================================
-- 6. LONG JOHN SILVER'S (ljsilvers.com)
-- Source: fastfoodnutrition.org, healthyfastfood.org, nutritionix.com
-- =============================================================================
-- =============================================================================
-- 7. CHECKERS/RALLY'S (checkersandrallys.com)
-- Source: checkers-menu.com, eatthismuch.com, calorieking.com
-- =============================================================================
-- =============================================================================
-- 8. WHITE CASTLE (whitecastle.com)
-- Source: whitecastle.com, fastfoodnutrition.org, healthyfastfood.org
-- =============================================================================
-- =============================================================================
-- 9. COOK OUT (cookout.com)
-- Source: cookout.com/nutrition, fastfoodnutrition.org, cookoutmenuss.com
-- =============================================================================
-- =============================================================================
-- 10. BOJANGLES (bojangles.com)
-- Source: bojangles.com/menu/nutrition/, fastfoodnutrition.org, myfooddiary.com
-- =============================================================================
('teriyaki_madness_chicken_teriyaki_bowl', 'Teriyaki Madness Chicken Teriyaki Bowl', 134.4, 6.8, 18.5, 3.1, 1.1, 3.3, 454, 454, 'teriyakimadness.com', ARRAY['tmad chicken bowl', 'teriyaki madness chicken rice'], '610 cal per 454g bowl. {"sodium_mg":154,"cholesterol_mg":19,"sat_fat_g":0.77,"trans_fat_g":0,"vitamin_a_pct":50,"vitamin_c_pct":33,"calcium_pct":6,"iron_pct":9}'),
('teriyaki_madness_spicy_chicken_bowl', 'Teriyaki Madness Spicy Chicken Bowl', 163.0, 6.6, 21.4, 5.9, 1.1, 3.1, 454, 454, 'teriyakimadness.com', ARRAY['tmad spicy chicken', 'teriyaki madness spicy bowl'], '740 cal per 454g bowl. {"sodium_mg":178,"cholesterol_mg":26,"sat_fat_g":2.42,"trans_fat_g":0,"vitamin_a_pct":58,"vitamin_c_pct":40,"calcium_pct":8,"iron_pct":90}'),
('teriyaki_madness_steak_teriyaki_bowl', 'Teriyaki Madness Steak Teriyaki Bowl', 154.2, 7.3, 18.3, 5.7, 1.1, 4.0, 454, 454, 'teriyakimadness.com', ARRAY['tmad steak bowl', 'teriyaki madness beef bowl'], '700 cal per 454g bowl. {"sodium_mg":190,"cholesterol_mg":30,"sat_fat_g":2.2,"trans_fat_g":0,"vitamin_a_pct":45,"vitamin_c_pct":30,"calcium_pct":6,"iron_pct":15}'),
('teriyaki_madness_salmon_teriyaki_bowl', 'Teriyaki Madness Salmon Teriyaki Bowl', 143.2, 7.0, 18.1, 4.2, 1.1, 3.3, 454, 454, 'teriyakimadness.com', ARRAY['tmad salmon bowl', 'teriyaki madness salmon rice'], '650 cal per 454g bowl. {"sodium_mg":205,"cholesterol_mg":29,"sat_fat_g":0.9,"trans_fat_g":0,"vitamin_a_pct":45,"vitamin_c_pct":30,"calcium_pct":6,"iron_pct":8}'),
('teriyaki_madness_chicken_katsu_bowl', 'Teriyaki Madness Chicken Katsu Bowl', 176.2, 6.8, 19.4, 8.8, 1.1, 3.5, 454, 454, 'teriyakimadness.com', ARRAY['tmad katsu bowl', 'teriyaki madness katsu'], '800 cal per 454g bowl. {"sodium_mg":178,"cholesterol_mg":28,"sat_fat_g":2.9,"trans_fat_g":0.2,"vitamin_a_pct":40,"vitamin_c_pct":28,"calcium_pct":6,"iron_pct":10}'),
('teriyaki_madness_orange_chicken_bowl', 'Teriyaki Madness Orange Chicken Bowl', 147.6, 6.4, 18.7, 5.1, 1.1, 5.5, 454, 454, 'teriyakimadness.com', ARRAY['tmad orange chicken', 'teriyaki madness orange chicken'], '670 cal per 454g bowl. {"sodium_mg":165,"cholesterol_mg":19,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":42,"vitamin_c_pct":30,"calcium_pct":6,"iron_pct":10}'),
('teriyaki_madness_tofu_teriyaki_bowl', 'Teriyaki Madness Tofu Teriyaki Bowl', 121.1, 5.5, 19.4, 3.1, 1.5, 3.1, 454, 454, 'teriyakimadness.com', ARRAY['tmad tofu bowl', 'teriyaki madness vegetarian'], '550 cal per 454g bowl. {"sodium_mg":155,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0,"vitamin_a_pct":35,"vitamin_c_pct":25,"calcium_pct":15,"iron_pct":12}'),
('teriyaki_madness_shrimp_teriyaki_bowl', 'Teriyaki Madness Shrimp Teriyaki Bowl', 127.8, 5.7, 18.7, 2.9, 1.1, 3.5, 454, 454, 'teriyakimadness.com', ARRAY['tmad shrimp bowl', 'teriyaki madness shrimp rice'], '580 cal per 454g bowl. {"sodium_mg":175,"cholesterol_mg":33,"sat_fat_g":0.6,"trans_fat_g":0,"vitamin_a_pct":40,"vitamin_c_pct":30,"calcium_pct":6,"iron_pct":10}'),
('teriyaki_madness_veggie_bowl', 'Teriyaki Madness Veggie Bowl', 99.1, 2.6, 19.8, 1.5, 2.2, 3.1, 454, 454, 'teriyakimadness.com', ARRAY['tmad veggie bowl', 'teriyaki madness vegetable'], '450 cal per 454g bowl. {"sodium_mg":130,"cholesterol_mg":0,"sat_fat_g":0.2,"trans_fat_g":0,"vitamin_a_pct":30,"vitamin_c_pct":25,"calcium_pct":4,"iron_pct":6}'),
('teriyaki_madness_spicy_chicken_power_bowl', 'Teriyaki Madness Spicy Chicken Power Bowl', 113.4, 10.8, 8.8, 3.3, 2.4, 2.2, 454, 454, 'teriyakimadness.com', ARRAY['tmad power bowl', 'teriyaki madness power bowl'], '515 cal per 454g power bowl. {"sodium_mg":150,"cholesterol_mg":22,"sat_fat_g":1.0,"trans_fat_g":0,"vitamin_a_pct":35,"vitamin_c_pct":30,"calcium_pct":6,"iron_pct":10}'),
('teriyaki_madness_gyoza', 'Teriyaki Madness Gyoza (6pc)', 200.0, 8.0, 24.0, 8.0, 2.0, 2.0, 150, 150, 'teriyakimadness.com', ARRAY['tmad dumplings', 'teriyaki madness potstickers'], '300 cal per 6pc (150g). {"sodium_mg":400,"cholesterol_mg":13,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":2,"iron_pct":6}'),
('teriyaki_madness_egg_roll', 'Teriyaki Madness Egg Roll', 225.0, 6.7, 28.3, 10.0, 1.7, 1.7, 60, 60, 'teriyakimadness.com', ARRAY['tmad egg roll', 'teriyaki madness spring roll'], '135 cal per roll (60g). {"sodium_mg":350,"cholesterol_mg":8,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":4}'),
('teriyaki_madness_edamame', 'Teriyaki Madness Edamame', 113.3, 9.3, 7.3, 4.7, 4.7, 0.7, 150, 150, 'teriyakimadness.com', ARRAY['tmad edamame', 'teriyaki madness soybeans'], '170 cal per 150g serving. {"sodium_mg":6,"cholesterol_mg":0,"sat_fat_g":0.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":10,"calcium_pct":6,"iron_pct":10}'),
('teriyaki_madness_white_rice', 'Teriyaki Madness White Rice', 163.5, 2.8, 36.1, 0.0, 0.4, 0.0, 252, 252, 'teriyakimadness.com', ARRAY['tmad rice', 'teriyaki madness steamed rice'], '412 cal per 252g serving. {"sodium_mg":1,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":8}'),
('teriyaki_madness_brown_rice', 'Teriyaki Madness Brown Rice', 138.9, 3.2, 28.6, 1.2, 2.4, 0.0, 252, 252, 'teriyakimadness.com', ARRAY['tmad brown rice'], '350 cal per 252g serving. {"sodium_mg":2,"cholesterol_mg":0,"sat_fat_g":0.2,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('teriyaki_madness_yakisoba_noodles', 'Teriyaki Madness Yakisoba Noodles', 173.3, 6.0, 26.0, 4.0, 2.0, 2.7, 300, 300, 'teriyakimadness.com', ARRAY['tmad noodles', 'teriyaki madness stir fry noodles'], '520 cal per 300g serving. {"sodium_mg":280,"cholesterol_mg":0,"sat_fat_g":0.7,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":10}'),
('sarku_japan_chicken_teriyaki_white_rice', 'Sarku Japan Chicken Teriyaki w/ White Rice', 160.0, 7.0, 19.8, 6.0, 0.5, 1.8, 400, 400, 'sarkujapan.com', ARRAY['sarku chicken rice', 'sarku japan chicken bowl'], '640 cal per 400g meal. {"sodium_mg":218,"cholesterol_mg":24,"sat_fat_g":1.25,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('sarku_japan_chicken_teriyaki_fried_rice', 'Sarku Japan Chicken Teriyaki w/ Fried Rice', 165.0, 7.0, 19.0, 7.0, 0.8, 2.5, 400, 400, 'sarkujapan.com', ARRAY['sarku chicken fried rice'], '660 cal per 400g meal. {"sodium_mg":383,"cholesterol_mg":24,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('sarku_japan_chicken_teriyaki_yakisoba', 'Sarku Japan Chicken Teriyaki w/ Yakisoba', 174.0, 8.6, 21.0, 6.4, 1.4, 2.0, 500, 500, 'sarkujapan.com', ARRAY['sarku chicken noodles'], '870 cal per 500g meal. {"sodium_mg":350,"cholesterol_mg":20,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":12}'),
('sarku_japan_beef_teriyaki_white_rice', 'Sarku Japan Beef Teriyaki w/ White Rice', 145.0, 7.5, 20.0, 4.0, 0.5, 2.3, 400, 400, 'sarkujapan.com', ARRAY['sarku beef rice', 'sarku japan steak'], '580 cal per 400g meal. {"sodium_mg":230,"cholesterol_mg":28,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":15}'),
('sarku_japan_beef_teriyaki_fried_rice', 'Sarku Japan Beef Teriyaki w/ Fried Rice', 150.0, 7.3, 19.0, 5.0, 0.8, 3.0, 400, 400, 'sarkujapan.com', ARRAY['sarku beef fried rice'], '600 cal per 400g meal. {"sodium_mg":390,"cholesterol_mg":28,"sat_fat_g":1.8,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":15}'),
('sarku_japan_shrimp_teriyaki_white_rice', 'Sarku Japan Shrimp Teriyaki w/ White Rice', 132.5, 6.8, 20.0, 3.0, 0.5, 2.5, 400, 400, 'sarkujapan.com', ARRAY['sarku shrimp rice'], '530 cal per 400g meal. {"sodium_mg":225,"cholesterol_mg":35,"sat_fat_g":0.8,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('sarku_japan_chicken_shrimp_white_rice', 'Sarku Japan Chicken & Shrimp w/ White Rice', 166.7, 8.9, 18.9, 6.4, 0.4, 2.7, 450, 450, 'sarkujapan.com', ARRAY['sarku combo rice'], '750 cal per 450g meal. {"sodium_mg":240,"cholesterol_mg":30,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('sarku_japan_chicken_teriyaki_bowl', 'Sarku Japan Chicken Teriyaki Bowl', 108.3, 4.8, 13.4, 4.0, 0.5, 1.3, 397, 397, 'sarkujapan.com', ARRAY['sarku small chicken bowl'], '430 cal per 14oz bowl. {"sodium_mg":200,"cholesterol_mg":18,"sat_fat_g":1.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":8}'),
('sarku_japan_chicken_bento', 'Sarku Japan Chicken Bento Box', 177.8, 6.2, 21.6, 7.1, 0.9, 3.6, 450, 450, 'sarkujapan.com', ARRAY['sarku bento box', 'sarku japan bento'], '800 cal per 450g bento. {"sodium_mg":250,"cholesterol_mg":22,"sat_fat_g":1.8,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('sarku_japan_beef_bento', 'Sarku Japan Beef Bento Box', 180.0, 8.0, 22.2, 6.4, 0.9, 4.4, 450, 450, 'sarkujapan.com', ARRAY['sarku beef bento'], '810 cal per 450g bento. {"sodium_mg":260,"cholesterol_mg":28,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":15}'),
('sarku_japan_dumplings', 'Sarku Japan Dumplings (6pc)', 173.3, 5.3, 19.3, 8.0, 1.3, 0.7, 150, 150, 'sarkujapan.com', ARRAY['sarku gyoza', 'sarku potstickers'], '260 cal per 6pc (150g). {"sodium_mg":320,"cholesterol_mg":10,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":2,"iron_pct":6}'),
('sarku_japan_shrimp_tempura', 'Sarku Japan Shrimp Tempura (3pc)', 260.0, 5.3, 15.3, 20.0, 0.7, 0.0, 150, 150, 'sarkujapan.com', ARRAY['sarku tempura'], '390 cal per 3pc. {"sodium_mg":350,"cholesterol_mg":30,"sat_fat_g":4.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":2,"iron_pct":4}'),
('sarku_japan_vegetable_spring_roll', 'Sarku Japan Vegetable Spring Roll', 228.6, 2.9, 21.4, 12.9, 1.4, 0.0, 70, 70, 'sarkujapan.com', ARRAY['sarku spring roll'], '160 cal per roll. {"sodium_mg":400,"cholesterol_mg":0,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":4}'),
('sarku_japan_edamame', 'Sarku Japan Edamame', 113.3, 9.3, 7.3, 4.7, 4.7, 0.7, 150, 150, 'sarkujapan.com', ARRAY['sarku soybeans'], '170 cal per 150g serving. {"sodium_mg":6,"cholesterol_mg":0,"sat_fat_g":0.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":10,"calcium_pct":6,"iron_pct":10}'),
('sarku_japan_miso_soup', 'Sarku Japan Miso Soup', 20.0, 1.6, 2.4, 0.8, 0.4, 2.4, 250, 250, 'sarkujapan.com', ARRAY['sarku soup'], '50 cal per serving. {"sodium_mg":320,"cholesterol_mg":0,"sat_fat_g":0.1,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('sarku_japan_california_roll', 'Sarku Japan California Roll', 150.0, 4.1, 25.9, 3.6, 1.8, 5.5, 220, 220, 'sarkujapan.com', ARRAY['sarku cali roll'], '330 cal per roll. {"sodium_mg":280,"cholesterol_mg":5,"sat_fat_g":0.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":6}'),
('sarku_japan_spicy_tuna_roll', 'Sarku Japan Spicy Tuna Roll', 195.5, 7.7, 25.0, 6.4, 1.4, 5.0, 220, 220, 'sarkujapan.com', ARRAY['sarku spicy tuna'], '430 cal per roll. {"sodium_mg":320,"cholesterol_mg":15,"sat_fat_g":1.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":6}'),
('sarku_japan_salmon_avocado_roll', 'Sarku Japan Salmon Avocado Roll', 159.1, 5.9, 22.3, 5.0, 1.8, 3.6, 220, 220, 'sarkujapan.com', ARRAY['sarku salmon roll'], '350 cal per roll. {"sodium_mg":260,"cholesterol_mg":12,"sat_fat_g":0.8,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":2,"iron_pct":4}'),
('sarku_japan_shrimp_tempura_roll', 'Sarku Japan Shrimp Tempura Roll', 236.4, 4.5, 29.5, 10.9, 1.8, 4.5, 220, 220, 'sarkujapan.com', ARRAY['sarku shrimp roll'], '520 cal per roll. {"sodium_mg":350,"cholesterol_mg":20,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":6}'),
('sarku_japan_philadelphia_roll', 'Sarku Japan Philadelphia Roll', 195.5, 7.7, 22.3, 8.2, 1.4, 4.1, 220, 220, 'sarkujapan.com', ARRAY['sarku philly roll'], '430 cal per roll. {"sodium_mg":290,"cholesterol_mg":15,"sat_fat_g":3.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":4}'),
('sarku_japan_rainbow_roll', 'Sarku Japan Rainbow Roll', 163.6, 9.5, 23.2, 3.2, 1.8, 4.5, 220, 220, 'sarkujapan.com', ARRAY['sarku rainbow'], '360 cal per roll. {"sodium_mg":280,"cholesterol_mg":15,"sat_fat_g":0.8,"trans_fat_g":0,"vitamin_a_pct":6,"vitamin_c_pct":6,"calcium_pct":2,"iron_pct":6}'),
('sarku_japan_white_sauce', 'Sarku Japan White/Yum Yum Sauce', 581.0, 0.0, 10.5, 58.1, 0.0, 10.5, 57, 57, 'sarkujapan.com', ARRAY['sarku yum yum sauce'], '330 cal per 2oz serving. {"sodium_mg":440,"cholesterol_mg":18,"sat_fat_g":9.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":0,"iron_pct":0}'),
('sarku_japan_vegetarian_dlite', 'Sarku Japan Vegetarian D''Lite w/ White Rice', 102.5, 2.0, 20.8, 1.5, 1.3, 2.0, 400, 400, 'sarkujapan.com', ARRAY['sarku vegetarian', 'sarku veggie meal'], '410 cal per 400g meal. {"sodium_mg":180,"cholesterol_mg":0,"sat_fat_g":0.2,"trans_fat_g":0,"vitamin_a_pct":15,"vitamin_c_pct":20,"calcium_pct":4,"iron_pct":6}'),
('yoshinoya_gyudon_beef_bowl_regular', 'Yoshinoya Gyudon Beef Bowl Regular', 152.0, 8.2, 18.1, 5.2, 0.0, 2.1, 425, 425, 'yoshinoyaamerica.com', ARRAY['yoshinoya beef bowl', 'yoshinoya original'], '646 cal per 425g bowl. {"sodium_mg":308,"cholesterol_mg":16,"sat_fat_g":2.8,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":15}'),
('yoshinoya_gyudon_beef_bowl_large', 'Yoshinoya Gyudon Beef Bowl Large', 154.5, 8.2, 17.8, 5.2, 0.2, 2.0, 595, 595, 'yoshinoyaamerica.com', ARRAY['yoshinoya large beef bowl'], '919 cal per 595g bowl. {"sodium_mg":314,"cholesterol_mg":17,"sat_fat_g":2.9,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":6,"iron_pct":20}'),
('yoshinoya_grilled_teriyaki_chicken_bowl', 'Yoshinoya Grilled Teriyaki Chicken Bowl Regular', 113.7, 7.3, 16.3, 1.8, 0.2, 2.2, 510, 510, 'yoshinoyaamerica.com', ARRAY['yoshinoya chicken bowl', 'yoshinoya teriyaki chicken'], '580 cal per 510g bowl. {"sodium_mg":230,"cholesterol_mg":14,"sat_fat_g":0.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('yoshinoya_grilled_teriyaki_chicken_large', 'Yoshinoya Grilled Teriyaki Chicken Bowl Large', 109.7, 6.9, 16.2, 1.6, 0.4, 1.6, 793, 793, 'yoshinoyaamerica.com', ARRAY['yoshinoya large chicken'], '870 cal per 793g bowl. {"sodium_mg":225,"cholesterol_mg":12,"sat_fat_g":0.4,"trans_fat_g":0,"vitamin_a_pct":6,"vitamin_c_pct":8,"calcium_pct":4,"iron_pct":10}'),
('yoshinoya_grilled_habanero_chicken_bowl', 'Yoshinoya Grilled Habanero Chicken Bowl Regular', 121.6, 6.5, 17.6, 2.2, 0.2, 3.3, 510, 510, 'yoshinoyaamerica.com', ARRAY['yoshinoya habanero chicken', 'yoshinoya spicy chicken'], '620 cal per 510g bowl. {"sodium_mg":245,"cholesterol_mg":14,"sat_fat_g":0.6,"trans_fat_g":0,"vitamin_a_pct":6,"vitamin_c_pct":8,"calcium_pct":4,"iron_pct":10}'),
('yoshinoya_grilled_ribeye_steak_bowl', 'Yoshinoya Grilled Ribeye Steak Bowl Regular', 119.2, 5.0, 17.1, 3.3, 0.2, 3.1, 520, 520, 'yoshinoyaamerica.com', ARRAY['yoshinoya steak bowl', 'yoshinoya ribeye'], '620 cal per 520g bowl. {"sodium_mg":250,"cholesterol_mg":15,"sat_fat_g":1.2,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":15}'),
('yoshinoya_grilled_teriyaki_salmon_bowl', 'Yoshinoya Grilled Teriyaki Salmon Bowl Regular', 117.6, 6.5, 16.7, 2.4, 0.2, 2.7, 510, 510, 'yoshinoyaamerica.com', ARRAY['yoshinoya salmon bowl'], '600 cal per 510g bowl. {"sodium_mg":235,"cholesterol_mg":14,"sat_fat_g":0.6,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":8}'),
('yoshinoya_tempura_orange_chicken', 'Yoshinoya Tempura Orange Chicken (combo)', 269.7, 14.1, 30.3, 9.9, 2.1, 9.9, 142, 142, 'yoshinoyaamerica.com', ARRAY['yoshinoya orange chicken', 'yoshinoya tfc'], '383 cal per 142g combo portion. {"sodium_mg":400,"cholesterol_mg":25,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":8}'),
('yoshinoya_veggie_bowl', 'Yoshinoya Veggie Bowl Regular', 87.0, 2.0, 18.9, 0.0, 0.4, 0.0, 539, 539, 'yoshinoyaamerica.com', ARRAY['yoshinoya vegetable bowl'], '469 cal per 539g bowl. {"sodium_mg":2,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":6,"vitamin_c_pct":10,"calcium_pct":2,"iron_pct":6}'),
('yoshinoya_crispy_gyoza_5pc', 'Yoshinoya Crispy Gyoza (5pc)', 260.2, 9.2, 30.6, 12.2, 3.1, 3.1, 98, 98, 'yoshinoyaamerica.com', ARRAY['yoshinoya dumplings', 'yoshinoya potstickers'], '255 cal per 5pc (98g). {"sodium_mg":350,"cholesterol_mg":12,"sat_fat_g":3.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":2,"iron_pct":6}'),
('yoshinoya_spring_rolls_2pc', 'Yoshinoya Spring Rolls (2pc)', 177.2, 2.5, 17.1, 7.6, 1.3, 12.0, 158, 158, 'yoshinoyaamerica.com', ARRAY['yoshinoya egg rolls'], '280 cal per 2pc (158g). {"sodium_mg":300,"cholesterol_mg":5,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":4}'),
('yoshinoya_shrimp_tempura_2pc', 'Yoshinoya Shrimp Tempura (2pc)', 189.8, 5.1, 17.3, 11.2, 1.0, 4.1, 98, 98, 'yoshinoyaamerica.com', ARRAY['yoshinoya tempura shrimp'], '186 cal per 2pc w/ sauce (98g). {"sodium_mg":350,"cholesterol_mg":30,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('yoshinoya_edamame', 'Yoshinoya Edamame', 113.3, 12.7, 8.0, 6.0, 6.0, 6.0, 150, 150, 'yoshinoyaamerica.com', ARRAY['yoshinoya soybeans'], '170 cal per 150g. {"sodium_mg":6,"cholesterol_mg":0,"sat_fat_g":0.7,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":10,"calcium_pct":6,"iron_pct":10}'),
('yoshinoya_clam_chowder', 'Yoshinoya Clam Chowder', 132.2, 4.0, 7.9, 9.7, 0.4, 2.2, 227, 227, 'yoshinoyaamerica.com', ARRAY['yoshinoya soup'], '300 cal per 227g. {"sodium_mg":350,"cholesterol_mg":18,"sat_fat_g":5.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":6,"iron_pct":6}'),
('yoshinoya_white_rice', 'Yoshinoya White Rice', 131.4, 2.2, 28.5, 0.0, 0.3, 0.0, 312, 312, 'yoshinoyaamerica.com', ARRAY['yoshinoya steamed rice'], '410 cal per 312g. {"sodium_mg":1,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":8}'),
('yoshinoya_brown_rice', 'Yoshinoya Brown Rice', 112.2, 2.2, 23.4, 1.0, 1.9, 0.0, 312, 312, 'yoshinoyaamerica.com', ARRAY['yoshinoya healthy rice'], '350 cal per 312g. {"sodium_mg":2,"cholesterol_mg":0,"sat_fat_g":0.2,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('yoshinoya_udon_noodles', 'Yoshinoya Japanese Udon Noodles', 179.3, 5.2, 35.9, 1.4, 2.1, 4.1, 290, 290, 'yoshinoyaamerica.com', ARRAY['yoshinoya noodles'], '520 cal per 290g. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":0.3,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":10}'),
('yoshinoya_mixed_veggies', 'Yoshinoya Mixed Veggies', 35.4, 1.8, 6.2, 0.0, 0.9, 2.7, 113, 113, 'yoshinoyaamerica.com', ARRAY['yoshinoya vegetables', 'yoshinoya side veggies'], '40 cal per 113g. {"sodium_mg":15,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":20,"vitamin_c_pct":15,"calcium_pct":2,"iron_pct":2}'),
('yoshinoya_teriyaki_sauce', 'Yoshinoya Teriyaki Sauce', 107.9, 1.6, 25.4, 0.0, 0.0, 19.0, 63, 63, 'yoshinoyaamerica.com', ARRAY['yoshinoya sauce'], '68 cal per 63g. {"sodium_mg":750,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":0,"iron_pct":2}'),
('yoshinoya_kids_beef_bowl', 'Yoshinoya Kids Beef Bowl', 113.0, 16.7, 1.5, 3.0, 0.4, 1.9, 269, 269, 'yoshinoyaamerica.com', ARRAY['yoshinoya kids meal'], '304 cal per 269g kids bowl. {"sodium_mg":280,"cholesterol_mg":14,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":10}'),
('halal_guys_chicken_platter_regular', 'Halal Guys Chicken Platter Regular', 124.4, 11.3, 15.2, 1.9, 0.4, 0.8, 521, 521, 'thehalalguys.com', ARRAY['halal guys chicken over rice', 'halal guys chicken plate'], '648 cal per 521g platter. {"sodium_mg":230,"cholesterol_mg":17,"sat_fat_g":0.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('halal_guys_chicken_platter_small', 'Halal Guys Chicken Platter Small', 132.3, 11.2, 17.1, 2.0, 0.3, 0.6, 356, 356, 'thehalalguys.com', ARRAY['halal guys small chicken'], '471 cal per 356g platter. {"sodium_mg":235,"cholesterol_mg":18,"sat_fat_g":0.6,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('halal_guys_beef_gyro_platter_regular', 'Halal Guys Beef Gyro Platter Regular', 180.2, 7.9, 21.7, 6.9, 0.4, 0.8, 521, 521, 'thehalalguys.com', ARRAY['halal guys gyro over rice', 'halal guys lamb platter'], '939 cal per 521g platter. {"sodium_mg":330,"cholesterol_mg":22,"sat_fat_g":2.8,"trans_fat_g":0.2,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":6,"iron_pct":15}'),
('halal_guys_beef_gyro_platter_small', 'Halal Guys Beef Gyro Platter Small', 186.8, 7.9, 23.3, 6.7, 0.3, 0.6, 356, 356, 'thehalalguys.com', ARRAY['halal guys small gyro'], '665 cal per 356g platter. {"sodium_mg":340,"cholesterol_mg":23,"sat_fat_g":2.9,"trans_fat_g":0.2,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":6,"iron_pct":15}'),
('halal_guys_combo_platter_regular', 'Halal Guys Combo Platter Regular', 152.4, 9.6, 18.4, 4.4, 0.4, 0.8, 521, 521, 'thehalalguys.com', ARRAY['halal guys chicken gyro combo', 'halal guys mixed platter'], '794 cal per 521g platter. {"sodium_mg":280,"cholesterol_mg":20,"sat_fat_g":1.6,"trans_fat_g":0.1,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":12}'),
('halal_guys_falafel_platter_regular', 'Halal Guys Falafel Platter Regular', 195.7, 5.4, 25.9, 7.8, 4.1, 1.1, 536, 536, 'thehalalguys.com', ARRAY['halal guys falafel over rice'], '1049 cal per 536g platter. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":1.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":8,"calcium_pct":6,"iron_pct":15}'),
('halal_guys_chicken_sandwich', 'Halal Guys Chicken Sandwich', 150.7, 14.7, 16.9, 2.5, 0.7, 1.4, 278, 278, 'thehalalguys.com', ARRAY['halal guys chicken pita'], '419 cal per 278g sandwich. {"sodium_mg":285,"cholesterol_mg":22,"sat_fat_g":0.7,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":6,"iron_pct":10}'),
('halal_guys_beef_gyro_sandwich', 'Halal Guys Beef Gyro Sandwich', 220.5, 10.4, 24.8, 8.6, 0.7, 1.4, 278, 278, 'thehalalguys.com', ARRAY['halal guys gyro pita', 'halal guys gyro wrap'], '613 cal per 278g sandwich. {"sodium_mg":380,"cholesterol_mg":28,"sat_fat_g":3.5,"trans_fat_g":0.2,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":6,"iron_pct":15}'),
('halal_guys_combo_sandwich', 'Halal Guys Combo Sandwich', 185.6, 12.6, 20.9, 5.8, 0.7, 1.4, 278, 278, 'thehalalguys.com', ARRAY['halal guys mixed sandwich'], '516 cal per 278g sandwich. {"sodium_mg":330,"cholesterol_mg":25,"sat_fat_g":2.0,"trans_fat_g":0.1,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":6,"iron_pct":12}'),
('halal_guys_falafel_sandwich', 'Halal Guys Falafel Sandwich', 232.2, 7.2, 29.7, 9.4, 5.1, 1.8, 276, 276, 'thehalalguys.com', ARRAY['halal guys falafel pita'], '641 cal per 276g sandwich. {"sodium_mg":290,"cholesterol_mg":0,"sat_fat_g":1.2,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":8,"calcium_pct":6,"iron_pct":15}'),
('halal_guys_hummus', 'Halal Guys Hummus', 221.8, 7.1, 17.1, 14.1, 7.6, 0.0, 170, 170, 'thehalalguys.com', ARRAY['halal guys hummus side'], '377 cal per 170g. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":1.8,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":10}'),
('halal_guys_french_fries', 'Halal Guys French Fries', 296.5, 3.2, 42.8, 12.4, 4.2, 0.0, 283, 283, 'thehalalguys.com', ARRAY['halal guys fries'], '839 cal per 283g. {"sodium_mg":200,"cholesterol_mg":0,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":10,"calcium_pct":2,"iron_pct":8}'),
('halal_guys_baklava', 'Halal Guys Baklava', 451.0, 5.9, 62.7, 19.6, 7.8, 33.3, 51, 51, 'thehalalguys.com', ARRAY['halal guys dessert'], '230 cal per 51g piece. {"sodium_mg":120,"cholesterol_mg":10,"sat_fat_g":3.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('halal_guys_white_sauce', 'Halal Guys White Sauce', 526.3, 0.0, 19.3, 49.1, 12.3, 1.8, 57, 57, 'thehalalguys.com', ARRAY['halal guys mayo sauce'], '300 cal per 57g. {"sodium_mg":350,"cholesterol_mg":25,"sat_fat_g":7.5,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":0,"iron_pct":0}'),
('halal_guys_pita_bread', 'Halal Guys Pita Bread', 284.8, 10.1, 53.2, 3.8, 2.5, 3.8, 79, 79, 'thehalalguys.com', ARRAY['halal guys bread'], '225 cal per 79g pita. {"sodium_mg":400,"cholesterol_mg":0,"sat_fat_g":0.5,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":8}'),
('halal_guys_falafel_side', 'Halal Guys Falafel (2 pieces)', 363.5, 10.8, 33.8, 20.3, 10.8, 1.4, 74, 74, 'thehalalguys.com', ARRAY['halal guys falafel balls'], '269 cal per 74g (2pc). {"sodium_mg":300,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":10}'),
('halal_guys_chicken_wing_platter', 'Halal Guys Chicken Wing Platter Regular', 139.9, 7.8, 16.4, 4.0, 0.6, 0.4, 675, 675, 'thehalalguys.com', ARRAY['halal guys wings over rice'], '945 cal per 675g platter. {"sodium_mg":220,"cholesterol_mg":18,"sat_fat_g":1.2,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":4,"iron_pct":10}'),
('captain_ds_batter_dipped_fish', 'Captain D''s Batter Dipped Fish (1pc)', 256.1, 12.2, 25.6, 18.3, 0.0, 1.2, 82, 82, 'captainds.com', ARRAY['captain ds fried fish', 'captain d fish'], '210 cal per filet (~82g). {"sodium_mg":732,"cholesterol_mg":61,"sat_fat_g":9.8,"trans_fat_g":1.2,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_country_style_fish', 'Captain D''s Country Style Fish (1pc)', 225.0, 11.3, 25.0, 15.0, 0.0, 1.3, 80, 80, 'captainds.com', ARRAY['captain ds breaded fish'], '180 cal per filet (~80g). {"sodium_mg":663,"cholesterol_mg":50,"sat_fat_g":7.5,"trans_fat_g":1.3,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_grilled_white_fish', 'Captain D''s Grilled White Fish', 105.9, 15.3, 0.0, 0.6, 0.0, 0.0, 170, 170, 'captainds.com', ARRAY['captain ds baked fish', 'captain ds healthy fish'], '180 cal per filet (170g). {"sodium_mg":235,"cholesterol_mg":35,"sat_fat_g":0.2,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_grilled_salmon', 'Captain D''s Grilled Salmon', 141.2, 14.1, 2.4, 7.1, 0.0, 0.0, 170, 170, 'captainds.com', ARRAY['captain ds salmon filet'], '240 cal per filet (170g). {"sodium_mg":200,"cholesterol_mg":35,"sat_fat_g":1.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_grilled_shrimp_skewer', 'Captain D''s Grilled Shrimp Skewer', 129.4, 14.1, 1.2, 5.9, 0.0, 0.0, 85, 85, 'captainds.com', ARRAY['captain ds grilled shrimp'], '110 cal per skewer (85g). {"sodium_mg":470,"cholesterol_mg":82,"sat_fat_g":1.2,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_butterfly_shrimp', 'Captain D''s Butterfly Shrimp', 423.5, 10.6, 28.2, 24.7, 0.0, 1.2, 85, 85, 'captainds.com', ARRAY['captain ds fried shrimp'], '360 cal per serving (85g). {"sodium_mg":824,"cholesterol_mg":94,"sat_fat_g":6.0,"trans_fat_g":0.6,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('captain_ds_chicken_tenders', 'Captain D''s Chicken Tenders (3pc)', 265.9, 14.1, 15.3, 12.9, 0.0, 0.0, 170, 170, 'captainds.com', ARRAY['captain ds chicken strips'], '452 cal per 3pc (170g). {"sodium_mg":600,"cholesterol_mg":35,"sat_fat_g":3.5,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('captain_ds_hushpuppy', 'Captain D''s Hushpuppy (1pc)', 320.0, 4.0, 44.0, 12.0, 0.0, 4.0, 25, 25, 'captainds.com', ARRAY['captain ds hush puppy'], '80 cal per piece (25g). {"sodium_mg":680,"cholesterol_mg":20,"sat_fat_g":2.4,"trans_fat_g":0.4,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":2}'),
('captain_ds_coleslaw', 'Captain D''s Cole Slaw', 120.0, 0.7, 12.0, 9.3, 1.3, 8.7, 150, 150, 'captainds.com', ARRAY['captain ds slaw'], '180 cal per 150g. {"sodium_mg":167,"cholesterol_mg":7,"sat_fat_g":1.3,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":15,"calcium_pct":2,"iron_pct":2}'),
('captain_ds_fries', 'Captain D''s French Fries', 275.0, 3.3, 35.8, 12.5, 2.5, 0.0, 120, 120, 'captainds.com', ARRAY['captain ds fries'], '330 cal per 120g. {"sodium_mg":458,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":10,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_green_beans', 'Captain D''s Green Beans', 20.0, 0.7, 3.3, 0.0, 1.3, 0.7, 150, 150, 'captainds.com', ARRAY['captain ds beans'], '30 cal per 150g. {"sodium_mg":200,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":10,"vitamin_c_pct":8,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_mac_and_cheese', 'Captain D''s Mac & Cheese', 133.3, 4.0, 16.7, 5.3, 0.7, 2.0, 150, 150, 'captainds.com', ARRAY['captain ds macaroni'], '200 cal per 150g. {"sodium_mg":400,"cholesterol_mg":10,"sat_fat_g":2.7,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":10,"iron_pct":4}'),
('captain_ds_rice', 'Captain D''s Rice', 100.0, 2.7, 17.3, 0.7, 1.3, 0.0, 150, 150, 'captainds.com', ARRAY['captain ds seasoned rice'], '150 cal per 150g. {"sodium_mg":267,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('captain_ds_breadstick', 'Captain D''s Breadstick', 233.3, 3.3, 38.3, 5.0, 1.7, 3.3, 60, 60, 'captainds.com', ARRAY['captain ds bread'], '140 cal per breadstick (60g). {"sodium_mg":417,"cholesterol_mg":0,"sat_fat_g":1.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('captain_ds_fish_sandwich', 'Captain D''s Great Little Fish Sandwich', 245.0, 12.5, 22.0, 12.0, 1.0, 2.5, 200, 200, 'captainds.com', ARRAY['captain ds sandwich'], '490 cal per sandwich (200g). {"sodium_mg":550,"cholesterol_mg":30,"sat_fat_g":5.0,"trans_fat_g":0.5,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":6,"iron_pct":8}'),
('captain_ds_crab_cake', 'Captain D''s Crab Cake', 208.3, 5.8, 15.0, 8.3, 0.0, 1.7, 120, 120, 'captainds.com', ARRAY['captain ds crab'], '250 cal per cake (120g). {"sodium_mg":500,"cholesterol_mg":42,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":6}'),
('long_john_silvers_battered_pollock', 'Long John Silver''s Battered Alaskan Pollock', 288.9, 13.3, 18.9, 17.8, 0.0, 0.0, 90, 90, 'ljsilvers.com', ARRAY['ljs fried fish', 'long john silvers fish'], '260 cal per piece (90g). {"sodium_mg":633,"cholesterol_mg":39,"sat_fat_g":4.4,"trans_fat_g":0.6,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('long_john_silvers_battered_cod', 'Long John Silver''s Battered Cod', 255.6, 15.6, 11.1, 16.7, 0.0, 0.0, 90, 90, 'ljsilvers.com', ARRAY['ljs cod', 'long john cod'], '230 cal per piece (90g). {"sodium_mg":611,"cholesterol_mg":44,"sat_fat_g":3.9,"trans_fat_g":0.6,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":2}'),
('long_john_silvers_baked_cod', 'Long John Silver''s Baked Cod', 70.6, 15.3, 0.0, 0.6, 0.0, 0.0, 170, 170, 'ljsilvers.com', ARRAY['ljs grilled fish', 'long john baked fish'], '120 cal per filet (170g). {"sodium_mg":294,"cholesterol_mg":35,"sat_fat_g":0.1,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":2}'),
('long_john_silvers_battered_shrimp', 'Long John Silver''s Battered Shrimp', 216.7, 8.3, 13.3, 15.0, 0.0, 0.0, 60, 60, 'ljsilvers.com', ARRAY['ljs fried shrimp'], '130 cal per 60g. {"sodium_mg":600,"cholesterol_mg":42,"sat_fat_g":2.5,"trans_fat_g":0.3,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('long_john_silvers_popcorn_shrimp', 'Long John Silver''s Popcorn Shrimp', 317.6, 10.6, 27.1, 18.8, 1.2, 1.2, 85, 85, 'ljsilvers.com', ARRAY['ljs popcorn shrimp'], '270 cal per 85g. {"sodium_mg":706,"cholesterol_mg":47,"sat_fat_g":3.5,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('long_john_silvers_chicken_tenders', 'Long John Silver''s Chicken Tenders (1pc)', 333.3, 20.0, 22.2, 24.4, 2.2, 0.0, 45, 45, 'ljsilvers.com', ARRAY['ljs chicken strips', 'long john chicken'], '150 cal per tender (45g). {"sodium_mg":689,"cholesterol_mg":44,"sat_fat_g":5.6,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('long_john_silvers_clam_strips', 'Long John Silver''s Breaded Clam Strips', 320.0, 9.0, 29.0, 19.0, 2.0, 1.0, 100, 100, 'ljsilvers.com', ARRAY['ljs clams', 'long john clam strips'], '320 cal per 100g. {"sodium_mg":680,"cholesterol_mg":25,"sat_fat_g":4.0,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":8}'),
('long_john_silvers_hushpuppy', 'Long John Silver''s Hushpuppy (1pc)', 240.0, 4.0, 36.0, 12.0, 4.0, 4.0, 25, 25, 'ljsilvers.com', ARRAY['ljs hushpuppy', 'long john hush puppy'], '60 cal per piece (25g). {"sodium_mg":600,"cholesterol_mg":20,"sat_fat_g":2.0,"trans_fat_g":0.4,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":2}'),
('long_john_silvers_fries', 'Long John Silver''s Fries', 275.0, 3.3, 36.7, 12.5, 2.5, 0.8, 120, 120, 'ljsilvers.com', ARRAY['ljs fries', 'long john fries'], '330 cal per 120g. {"sodium_mg":500,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0.4,"vitamin_a_pct":0,"vitamin_c_pct":8,"calcium_pct":2,"iron_pct":4}'),
('long_john_silvers_coleslaw', 'Long John Silver''s Cole Slaw', 133.3, 0.7, 10.0, 10.0, 2.0, 6.7, 150, 150, 'ljsilvers.com', ARRAY['ljs slaw', 'long john coleslaw'], '200 cal per 150g. {"sodium_mg":200,"cholesterol_mg":7,"sat_fat_g":1.7,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":20,"calcium_pct":2,"iron_pct":2}'),
('long_john_silvers_onion_rings', 'Long John Silver''s Battered Onion Rings', 308.3, 1.7, 22.5, 24.2, 1.7, 2.5, 120, 120, 'ljsilvers.com', ARRAY['ljs onion rings'], '370 cal per 120g. {"sodium_mg":583,"cholesterol_mg":0,"sat_fat_g":6.7,"trans_fat_g":0.8,"vitamin_a_pct":0,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":4}'),
('long_john_silvers_mac_and_cheese', 'Long John Silver''s Mac & Cheese', 100.0, 4.0, 12.7, 4.0, 0.7, 2.0, 150, 150, 'ljsilvers.com', ARRAY['ljs mac cheese'], '150 cal per 150g. {"sodium_mg":367,"cholesterol_mg":7,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":8,"iron_pct":4}'),
('long_john_silvers_green_beans', 'Long John Silver''s Seasoned Green Beans', 19.3, 0.7, 3.3, 0.0, 1.3, 0.7, 150, 150, 'ljsilvers.com', ARRAY['ljs green beans'], '29 cal per 150g. {"sodium_mg":220,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":10,"vitamin_c_pct":8,"calcium_pct":2,"iron_pct":4}'),
('long_john_silvers_fish_sandwich', 'Long John Silver''s Ciabatta Jack Fish Sandwich', 285.0, 10.0, 22.5, 17.5, 1.0, 1.0, 200, 200, 'ljsilvers.com', ARRAY['ljs fish sandwich'], '570 cal per sandwich (200g). {"sodium_mg":675,"cholesterol_mg":30,"sat_fat_g":6.0,"trans_fat_g":0.5,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":10,"iron_pct":10}'),
('long_john_silvers_fish_taco', 'Long John Silver''s Baja Fish Taco', 240.0, 6.0, 20.0, 15.3, 2.0, 1.3, 150, 150, 'ljsilvers.com', ARRAY['ljs taco', 'long john fish taco'], '360 cal per taco (150g). {"sodium_mg":533,"cholesterol_mg":20,"sat_fat_g":3.3,"trans_fat_g":0.3,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":6}'),
('long_john_silvers_chocolate_cream_pie', 'Long John Silver''s Chocolate Cream Pie', 233.3, 2.5, 23.3, 14.2, 0.8, 15.8, 120, 120, 'ljsilvers.com', ARRAY['ljs dessert', 'ljs pie'], '280 cal per slice (120g). {"sodium_mg":200,"cholesterol_mg":4,"sat_fat_g":8.3,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('checkers_rallys_rallyburger', 'Checkers/Rally''s Rallyburger', 227.1, 9.4, 18.2, 12.9, 1.8, 2.4, 170, 170, 'checkersandrallys.com', ARRAY['checkers burger', 'rallys burger', 'rally burger'], '386 cal per 170g burger. {"sodium_mg":399,"cholesterol_mg":12,"sat_fat_g":4.7,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":10}'),
('checkers_rallys_big_buford', 'Checkers/Rally''s Big Buford', 333.3, 17.7, 18.7, 20.3, 1.3, 3.0, 300, 300, 'checkersandrallys.com', ARRAY['checkers big buford', 'rallys big buford'], '1000 cal per 300g burger. {"sodium_mg":500,"cholesterol_mg":33,"sat_fat_g":8.0,"trans_fat_g":0.7,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":10,"iron_pct":20}'),
('checkers_rallys_baconzilla', 'Checkers/Rally''s Baconzilla', 376.7, 18.7, 19.0, 23.3, 1.0, 3.3, 300, 300, 'checkersandrallys.com', ARRAY['checkers baconzilla', 'rallys baconzilla'], '1130 cal per 300g burger. {"sodium_mg":600,"cholesterol_mg":50,"sat_fat_g":10.0,"trans_fat_g":1.0,"vitamin_a_pct":4,"vitamin_c_pct":4,"calcium_pct":15,"iron_pct":25}'),
('checkers_rallys_classic_cheeseburger', 'Checkers/Rally''s Classic Cheeseburger', 275.0, 13.5, 22.5, 15.0, 1.0, 3.0, 200, 200, 'checkersandrallys.com', ARRAY['checkers cheeseburger', 'rallys cheeseburger'], '550 cal per 200g burger. {"sodium_mg":500,"cholesterol_mg":35,"sat_fat_g":6.5,"trans_fat_g":0.5,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":10,"iron_pct":15}'),
('checkers_rallys_double_rallyburger', 'Checkers/Rally''s Double Rallyburger w/ Cheese', 196.0, 17.6, 12.8, 14.0, 0.8, 2.4, 250, 250, 'checkersandrallys.com', ARRAY['checkers double', 'rallys double burger'], '490 cal per 250g burger. {"sodium_mg":400,"cholesterol_mg":28,"sat_fat_g":6.0,"trans_fat_g":0.4,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":10,"iron_pct":15}'),
('checkers_rallys_famous_chicken_sandwich', 'Checkers/Rally''s Famous Chicken Sandwich', 260.0, 14.0, 22.5, 12.5, 1.0, 2.5, 200, 200, 'checkersandrallys.com', ARRAY['checkers chicken sandwich', 'rallys chicken'], '520 cal per 200g sandwich. {"sodium_mg":550,"cholesterol_mg":25,"sat_fat_g":3.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":6,"iron_pct":10}'),
('checkers_rallys_spicy_chicken_sandwich', 'Checkers/Rally''s Spicy Chicken Sandwich', 274.5, 15.0, 22.5, 13.0, 1.0, 2.5, 200, 200, 'checkersandrallys.com', ARRAY['checkers spicy chicken', 'rallys spicy chicken'], '549 cal per 200g sandwich. {"sodium_mg":600,"cholesterol_mg":25,"sat_fat_g":3.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":6,"calcium_pct":6,"iron_pct":10}'),
('checkers_rallys_chicken_tenders_5pc', 'Checkers/Rally''s Chicken Tenders (5pc)', 222.2, 11.1, 15.6, 12.4, 0.9, 0.4, 225, 225, 'checkersandrallys.com', ARRAY['checkers chicken strips', 'rallys tenders'], '500 cal per 5pc (225g). {"sodium_mg":556,"cholesterol_mg":22,"sat_fat_g":2.7,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('checkers_rallys_classic_wings_6pc', 'Checkers/Rally''s Classic Wings (6pc)', 280.0, 20.0, 3.3, 18.7, 0.0, 0.0, 150, 150, 'checkersandrallys.com', ARRAY['checkers wings', 'rallys wings'], '420 cal per 6pc (150g). {"sodium_mg":600,"cholesterol_mg":67,"sat_fat_g":5.3,"trans_fat_g":0.3,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('checkers_rallys_fish_sandwich', 'Checkers/Rally''s Classic Fish Sandwich', 225.0, 11.0, 20.0, 11.0, 1.0, 2.0, 200, 200, 'checkersandrallys.com', ARRAY['checkers fish', 'rallys fish sandwich'], '450 cal per 200g sandwich. {"sodium_mg":500,"cholesterol_mg":20,"sat_fat_g":3.0,"trans_fat_g":0.3,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":6,"iron_pct":8}'),
('checkers_rallys_hot_dog', 'Checkers/Rally''s Classic Hot Dog', 320.0, 12.0, 28.0, 18.0, 1.0, 3.0, 100, 100, 'checkersandrallys.com', ARRAY['checkers hot dog', 'rallys hot dog'], '320 cal per 100g hot dog. {"sodium_mg":750,"cholesterol_mg":30,"sat_fat_g":7.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":8}'),
('checkers_rallys_famous_fries', 'Checkers/Rally''s Famous Seasoned Fries', 350.0, 4.2, 45.8, 16.7, 3.3, 0.0, 120, 120, 'checkersandrallys.com', ARRAY['checkers fries', 'rallys fries', 'checkers seasoned fries'], '420 cal per 120g. {"sodium_mg":667,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":10,"calcium_pct":2,"iron_pct":6}'),
('checkers_rallys_funnel_cake_fries', 'Checkers/Rally''s Funnel Cake Fries', 392.9, 4.3, 50.0, 20.0, 0.7, 17.9, 140, 140, 'checkersandrallys.com', ARRAY['checkers funnel fries', 'rallys funnel cake'], '550 cal per 140g. {"sodium_mg":357,"cholesterol_mg":14,"sat_fat_g":5.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('checkers_rallys_vanilla_shake', 'Checkers/Rally''s Vanilla Shake', 160.0, 3.8, 26.3, 6.3, 0.0, 21.3, 400, 400, 'checkersandrallys.com', ARRAY['checkers vanilla shake', 'rallys vanilla shake'], '640 cal per 400ml shake. {"sodium_mg":75,"cholesterol_mg":8,"sat_fat_g":4.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":0,"calcium_pct":15,"iron_pct":2}'),
('white_castle_original_slider', 'White Castle The Original Slider', 259.3, 11.1, 29.6, 13.0, 1.9, 3.7, 54, 54, 'whitecastle.com', ARRAY['white castle slider', 'white castle hamburger'], '140 cal per slider (54g). {"sodium_mg":704,"cholesterol_mg":19,"sat_fat_g":4.6,"trans_fat_g":0.9,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('white_castle_cheese_slider', 'White Castle Cheese Slider', 283.3, 13.3, 26.7, 15.0, 1.7, 3.3, 60, 60, 'whitecastle.com', ARRAY['white castle cheeseburger'], '170 cal per slider (60g). {"sodium_mg":717,"cholesterol_mg":17,"sat_fat_g":5.8,"trans_fat_g":0.8,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":6,"iron_pct":6}'),
('white_castle_double_cheese_slider', 'White Castle Double Cheese Slider', 291.0, 13.6, 22.7, 17.3, 1.8, 2.7, 110, 110, 'whitecastle.com', ARRAY['white castle double slider'], '320 cal per slider (110g). {"sodium_mg":655,"cholesterol_mg":27,"sat_fat_g":7.3,"trans_fat_g":1.4,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":10,"iron_pct":10}'),
('white_castle_crispy_chicken_slider', 'White Castle Crispy Chicken Slider', 328.6, 15.7, 31.4, 14.3, 1.4, 2.9, 70, 70, 'whitecastle.com', ARRAY['white castle chicken slider'], '230 cal per slider (70g). {"sodium_mg":714,"cholesterol_mg":21,"sat_fat_g":2.9,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('white_castle_chicken_ring_slider', 'White Castle Chicken Ring Slider', 285.7, 12.9, 28.6, 14.3, 1.4, 2.9, 70, 70, 'whitecastle.com', ARRAY['white castle chicken ring sandwich'], '200 cal per slider (70g). {"sodium_mg":571,"cholesterol_mg":14,"sat_fat_g":2.9,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":4}'),
('white_castle_fish_slider', 'White Castle Fish Slider', 457.1, 10.0, 48.6, 22.9, 1.4, 4.3, 70, 70, 'whitecastle.com', ARRAY['white castle fish sandwich'], '320 cal per slider (70g). {"sodium_mg":929,"cholesterol_mg":14,"sat_fat_g":4.3,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('white_castle_impossible_slider', 'White Castle Impossible Slider', 300.0, 25.7, 25.7, 24.3, 1.4, 2.9, 70, 70, 'whitecastle.com', ARRAY['white castle plant based', 'white castle vegan slider'], '210 cal per slider (70g). {"sodium_mg":1243,"cholesterol_mg":0,"sat_fat_g":14.3,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":15}'),
('white_castle_bacon_cheese_slider', 'White Castle Bacon Cheese Slider', 328.6, 15.7, 22.9, 21.4, 1.4, 2.9, 70, 70, 'whitecastle.com', ARRAY['white castle bacon slider'], '230 cal per slider (70g). {"sodium_mg":843,"cholesterol_mg":21,"sat_fat_g":7.1,"trans_fat_g":0.7,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":6,"iron_pct":6}'),
('white_castle_chicken_waffles_slider', 'White Castle Chicken & Waffles Slider', 350.0, 9.0, 36.0, 18.0, 0.0, 14.0, 100, 100, 'whitecastle.com', ARRAY['white castle waffle slider'], '350 cal per slider (100g). {"sodium_mg":600,"cholesterol_mg":20,"sat_fat_g":4.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('white_castle_chicken_rings_6pc', 'White Castle Chicken Rings (6pc)', 310.0, 10.0, 20.0, 19.0, 1.0, 0.0, 100, 100, 'whitecastle.com', ARRAY['white castle chicken rings', 'white castle nuggets'], '310 cal per 6pc (100g). {"sodium_mg":710,"cholesterol_mg":20,"sat_fat_g":4.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('white_castle_french_fries', 'White Castle French Fries', 250.0, 2.5, 33.3, 11.7, 2.5, 0.0, 120, 120, 'whitecastle.com', ARRAY['white castle fries'], '300 cal per 120g. {"sodium_mg":333,"cholesterol_mg":0,"sat_fat_g":2.1,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":10,"calcium_pct":2,"iron_pct":4}'),
('white_castle_cheese_fries', 'White Castle Cheese Fries', 250.0, 3.1, 34.4, 10.9, 2.5, 0.6, 160, 160, 'whitecastle.com', ARRAY['white castle loaded fries'], '400 cal per 160g. {"sodium_mg":406,"cholesterol_mg":6,"sat_fat_g":3.1,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":8,"calcium_pct":6,"iron_pct":4}'),
('white_castle_onion_rings', 'White Castle Onion Rings', 291.7, 2.5, 35.0, 14.2, 1.7, 3.3, 120, 120, 'whitecastle.com', ARRAY['white castle rings'], '350 cal per 120g. {"sodium_mg":458,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":6}'),
('white_castle_mozzarella_sticks', 'White Castle Mozzarella Cheese Sticks (5pc)', 300.0, 8.3, 23.3, 15.0, 0.8, 0.8, 120, 120, 'whitecastle.com', ARRAY['white castle mozz sticks'], '360 cal per 5pc (120g). {"sodium_mg":692,"cholesterol_mg":13,"sat_fat_g":5.0,"trans_fat_g":0.4,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":10,"iron_pct":4}'),
('white_castle_bacon_egg_slider', 'White Castle Bacon & Egg Breakfast Slider', 371.4, 18.6, 21.4, 25.7, 1.4, 2.9, 70, 70, 'whitecastle.com', ARRAY['white castle breakfast slider'], '260 cal per slider (70g). {"sodium_mg":857,"cholesterol_mg":157,"sat_fat_g":10.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":0,"calcium_pct":6,"iron_pct":6}'),
('white_castle_sausage_egg_slider', 'White Castle Sausage & Egg Breakfast Slider', 450.0, 18.8, 20.0, 33.8, 1.3, 2.5, 80, 80, 'whitecastle.com', ARRAY['white castle sausage slider'], '360 cal per slider (80g). {"sodium_mg":900,"cholesterol_mg":169,"sat_fat_g":12.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":0,"calcium_pct":6,"iron_pct":8}'),
('cook_out_hamburger_regular', 'Cook Out Regular 1/4 lb Hamburger', 262.4, 17.6, 21.6, 11.2, 0.0, 3.2, 125, 125, 'cookout.com', ARRAY['cookout burger', 'cook out quarter pounder'], '328 cal per 125g (4.4oz). {"sodium_mg":440,"cholesterol_mg":44,"sat_fat_g":4.8,"trans_fat_g":0.8,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":6,"iron_pct":15}'),
('cook_out_hamburger_huge', 'Cook Out Huge 1/2 lb Hamburger', 252.9, 19.6, 13.2, 12.7, 0.0, 2.0, 204, 204, 'cookout.com', ARRAY['cookout big burger', 'cook out half pound'], '516 cal per 204g (7.2oz). {"sodium_mg":402,"cholesterol_mg":54,"sat_fat_g":5.4,"trans_fat_g":1.0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":6,"iron_pct":25}'),
('cook_out_big_double', 'Cook Out Big Double Burger', 169.0, 10.9, 14.7, 7.1, 0.0, 2.2, 184, 184, 'cookout.com', ARRAY['cookout double burger', 'cook out double'], '311 cal per 184g (6.5oz). {"sodium_mg":380,"cholesterol_mg":43,"sat_fat_g":3.3,"trans_fat_g":0.5,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":15}'),
('cook_out_chargrilled_chicken', 'Cook Out Char-Grilled Chicken Breast', 199.5, 13.2, 15.3, 9.0, 0.0, 2.6, 189, 189, 'cookout.com', ARRAY['cookout grilled chicken', 'cook out chicken sandwich'], '377 cal per 189g (6.67oz). {"sodium_mg":370,"cholesterol_mg":37,"sat_fat_g":2.6,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":8}'),
('cook_out_spicy_chicken', 'Cook Out Spicy Chicken Breast', 280.5, 13.2, 28.3, 11.3, 1.3, 3.1, 159, 159, 'cookout.com', ARRAY['cookout spicy chicken', 'cook out crispy chicken'], '446 cal per 159g (5.61oz). {"sodium_mg":500,"cholesterol_mg":28,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":8}'),
('cook_out_chicken_strips_3pc', 'Cook Out Chicken Strips (3pc)', 282.1, 15.4, 25.6, 14.1, 1.3, 0.0, 234, 234, 'cookout.com', ARRAY['cookout chicken tenders', 'cook out strips'], '660 cal per 234g (8.25oz). {"sodium_mg":513,"cholesterol_mg":26,"sat_fat_g":3.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":8}'),
('cook_out_bbq_sandwich', 'Cook Out BBQ Sandwich', 147.8, 2.0, 14.1, 4.8, 0.4, 3.6, 249, 249, 'cookout.com', ARRAY['cookout bbq', 'cook out pulled pork', 'cook out barbecue'], '368 cal per 249g (8.8oz). {"sodium_mg":361,"cholesterol_mg":12,"sat_fat_g":1.6,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":10}'),
('cook_out_hot_dog', 'Cook Out Hot Dog', 317.1, 9.8, 26.8, 18.3, 0.0, 3.7, 82, 82, 'cookout.com', ARRAY['cookout hot dog'], '260 cal per 82g (2.9oz). {"sodium_mg":805,"cholesterol_mg":24,"sat_fat_g":6.1,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":6}'),
('cook_out_style_hot_dog', 'Cook Out Style Hot Dog', 217.6, 6.3, 16.5, 11.4, 0.6, 4.0, 176, 176, 'cookout.com', ARRAY['cookout loaded hot dog', 'cook out special hot dog'], '383 cal per 176g (6.2oz). {"sodium_mg":625,"cholesterol_mg":22,"sat_fat_g":4.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":8}'),
('cook_out_cajun_wrap', 'Cook Out Cajun Wrap', 294.7, 14.7, 25.9, 15.9, 1.2, 0.0, 170, 170, 'cookout.com', ARRAY['cookout wrap', 'cook out chicken wrap'], '501 cal per 170g (6oz). {"sodium_mg":553,"cholesterol_mg":35,"sat_fat_g":4.7,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":10,"iron_pct":10}'),
('cook_out_ranch_wrap', 'Cook Out Ranch Wrap', 301.7, 14.5, 25.4, 16.8, 1.2, 0.0, 173, 173, 'cookout.com', ARRAY['cookout ranch wrap'], '522 cal per 173g (6.1oz). {"sodium_mg":570,"cholesterol_mg":35,"sat_fat_g":5.0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":10,"iron_pct":10}'),
('cook_out_cheese_quesadilla', 'Cook Out Cheese Quesadilla', 358.6, 13.1, 24.2, 23.2, 1.0, 1.0, 99, 99, 'cookout.com', ARRAY['cookout quesadilla'], '355 cal per 99g (3.5oz). {"sodium_mg":606,"cholesterol_mg":30,"sat_fat_g":12.1,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":0,"calcium_pct":20,"iron_pct":6}'),
('cook_out_chicken_quesadilla', 'Cook Out Chicken Quesadilla', 367.2, 15.6, 25.4, 23.0, 0.8, 1.6, 122, 122, 'cookout.com', ARRAY['cookout chicken quesadilla'], '449 cal per 122g (4.3oz). {"sodium_mg":574,"cholesterol_mg":33,"sat_fat_g":11.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":0,"calcium_pct":20,"iron_pct":8}'),
('cook_out_bbq_plate', 'Cook Out BBQ Plate', 199.2, 7.1, 21.4, 8.8, 2.0, 4.3, 490, 490, 'cookout.com', ARRAY['cookout bbq tray', 'cook out barbecue plate'], '976 cal per 490g (17.3oz). {"sodium_mg":306,"cholesterol_mg":14,"sat_fat_g":3.1,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":6,"iron_pct":15}'),
('cook_out_onion_rings', 'Cook Out Onion Rings', 184.2, 4.3, 40.3, 1.4, 2.2, 4.3, 139, 139, 'cookout.com', ARRAY['cookout rings'], '256 cal per 139g (4.9oz). {"sodium_mg":324,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":4}'),
('cook_out_vanilla_shake', 'Cook Out Vanilla Milkshake', 59.5, 1.7, 9.2, 1.9, 0.0, 8.9, 932, 932, 'cookout.com', ARRAY['cookout milkshake', 'cook out shake'], '555 cal per 932g (32.9oz). {"sodium_mg":21,"cholesterol_mg":7,"sat_fat_g":1.2,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":30,"iron_pct":2}'),
('cook_out_chocolate_shake', 'Cook Out Chocolate Milkshake', 66.5, 1.7, 11.8, 1.9, 0.0, 11.0, 932, 932, 'cookout.com', ARRAY['cookout chocolate shake'], '620 cal per 932g (32.9oz). {"sodium_mg":25,"cholesterol_mg":7,"sat_fat_g":1.2,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":30,"iron_pct":4}'),
('cook_out_peanut_butter_shake', 'Cook Out Peanut Butter Milkshake', 91.1, 2.9, 9.8, 4.8, 0.3, 8.9, 930, 930, 'cookout.com', ARRAY['cookout pb shake'], '847 cal per 930g (32.8oz). {"sodium_mg":34,"cholesterol_mg":7,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":2,"calcium_pct":30,"iron_pct":6}'),
('bojangles_chicken_breast', 'Bojangles Chicken Breast', 317.6, 24.1, 14.1, 17.1, 0.6, 0.0, 170, 170, 'bojangles.com', ARRAY['bojangles fried chicken breast'], '540 cal per breast (170g). {"sodium_mg":341,"cholesterol_mg":76,"sat_fat_g":5.9,"trans_fat_g":0.6,"vitamin_a_pct":2,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":8}'),
('bojangles_chicken_leg', 'Bojangles Chicken Leg', 211.1, 11.1, 8.9, 14.4, 0.0, 0.0, 90, 90, 'bojangles.com', ARRAY['bojangles drumstick'], '190 cal per leg (90g). {"sodium_mg":433,"cholesterol_mg":56,"sat_fat_g":3.3,"trans_fat_g":0.3,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('bojangles_chicken_thigh', 'Bojangles Chicken Thigh', 200.0, 17.5, 11.7, 8.3, 0.8, 0.0, 120, 120, 'bojangles.com', ARRAY['bojangles dark meat'], '240 cal per thigh (120g). {"sodium_mg":375,"cholesterol_mg":58,"sat_fat_g":2.5,"trans_fat_g":0.3,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('bojangles_chicken_wing', 'Bojangles Chicken Wing', 250.0, 16.7, 13.3, 13.3, 0.0, 0.0, 60, 60, 'bojangles.com', ARRAY['bojangles wing'], '150 cal per wing (60g). {"sodium_mg":500,"cholesterol_mg":50,"sat_fat_g":3.3,"trans_fat_g":0.3,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":4}'),
('bojangles_chicken_supremes_4pc', 'Bojangles Chicken Supremes (4pc)', 277.8, 16.7, 16.7, 13.9, 0.6, 0.0, 180, 180, 'bojangles.com', ARRAY['bojangles tenders', 'bojangles strips'], '500 cal per 4pc (180g). {"sodium_mg":500,"cholesterol_mg":39,"sat_fat_g":3.3,"trans_fat_g":0.3,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":2,"iron_pct":6}'),
('bojangles_roasted_bites', 'Bojangles Roasted Bites', 218.8, 27.5, 5.6, 8.8, 0.6, 3.1, 160, 160, 'bojangles.com', ARRAY['bojangles chicken bites'], '350 cal per 160g. {"sodium_mg":438,"cholesterol_mg":50,"sat_fat_g":2.5,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":6}'),
('bojangles_cajun_filet_biscuit', 'Bojangles Cajun Filet Biscuit', 380.0, 15.3, 38.0, 18.0, 0.7, 2.7, 150, 150, 'bojangles.com', ARRAY['bojangles chicken biscuit', 'bojangles filet'], '570 cal per 150g. {"sodium_mg":867,"cholesterol_mg":33,"sat_fat_g":5.3,"trans_fat_g":0.7,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":10}'),
('bojangles_bacon_egg_cheese_biscuit', 'Bojangles Bacon Egg & Cheese Biscuit', 391.7, 13.3, 32.5, 22.5, 0.8, 3.3, 120, 120, 'bojangles.com', ARRAY['bojangles breakfast biscuit'], '470 cal per 120g. {"sodium_mg":833,"cholesterol_mg":167,"sat_fat_g":8.3,"trans_fat_g":0.8,"vitamin_a_pct":6,"vitamin_c_pct":0,"calcium_pct":8,"iron_pct":10}'),
('bojangles_sausage_biscuit', 'Bojangles Sausage Biscuit', 391.7, 12.5, 31.7, 23.3, 0.8, 3.3, 120, 120, 'bojangles.com', ARRAY['bojangles breakfast sausage'], '470 cal per 120g. {"sodium_mg":750,"cholesterol_mg":33,"sat_fat_g":8.3,"trans_fat_g":0.8,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":8}'),
('bojangles_country_ham_biscuit', 'Bojangles Country Ham Biscuit', 380.0, 14.0, 38.0, 20.0, 1.0, 4.0, 100, 100, 'bojangles.com', ARRAY['bojangles ham biscuit'], '380 cal per 100g. {"sodium_mg":1200,"cholesterol_mg":25,"sat_fat_g":6.0,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":8}'),
('bojangles_plain_biscuit', 'Bojangles Plain Biscuit', 387.5, 7.5, 46.3, 18.8, 1.3, 5.0, 80, 80, 'bojangles.com', ARRAY['bojangles biscuit', 'bojangles buttermilk biscuit'], '310 cal per 80g. {"sodium_mg":813,"cholesterol_mg":6,"sat_fat_g":5.0,"trans_fat_g":0.6,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":8}'),
('bojangles_gravy_biscuit', 'Bojangles Gravy Biscuit', 358.3, 9.2, 40.8, 17.5, 0.8, 6.7, 120, 120, 'bojangles.com', ARRAY['bojangles sausage gravy biscuit'], '430 cal per 120g. {"sodium_mg":750,"cholesterol_mg":8,"sat_fat_g":5.0,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":8}'),
('bojangles_bo_berry_biscuit', 'Bojangles Bo-Berry Biscuit', 462.5, 6.3, 61.3, 21.3, 1.3, 22.5, 80, 80, 'bojangles.com', ARRAY['bojangles blueberry biscuit', 'bo berry'], '370 cal per 80g. {"sodium_mg":625,"cholesterol_mg":6,"sat_fat_g":5.0,"trans_fat_g":0.5,"vitamin_a_pct":0,"vitamin_c_pct":2,"calcium_pct":4,"iron_pct":6}'),
('bojangles_cinnamon_biscuit', 'Bojangles Cinnamon Biscuit', 612.5, 7.5, 71.3, 33.8, 1.3, 26.3, 80, 80, 'bojangles.com', ARRAY['bojangles sweet biscuit'], '490 cal per 80g. {"sodium_mg":563,"cholesterol_mg":6,"sat_fat_g":6.3,"trans_fat_g":0.6,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":4,"iron_pct":6}'),
('bojangles_sweet_potato_pie', 'Bojangles Sweet Potato Pie', 291.7, 2.5, 34.2, 24.2, 0.8, 15.0, 120, 120, 'bojangles.com', ARRAY['bojangles pie', 'bojangles dessert'], '350 cal per 120g. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":10.0,"trans_fat_g":0,"vitamin_a_pct":80,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":4}'),
('bojangles_cajun_filet_sandwich', 'Bojangles Cajun Filet Sandwich', 335.0, 11.5, 27.5, 20.0, 0.5, 3.0, 200, 200, 'bojangles.com', ARRAY['bojangles chicken sandwich'], '670 cal per 200g sandwich. {"sodium_mg":650,"cholesterol_mg":30,"sat_fat_g":5.0,"trans_fat_g":0.5,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":6,"iron_pct":10}'),
('bojangles_bos_chicken_sandwich', 'Bojangles Bo''s Chicken Sandwich', 279.2, 12.9, 39.6, 15.0, 0.0, 3.3, 240, 240, 'bojangles.com', ARRAY['bojangles bo sandwich'], '670 cal per 240g sandwich. {"sodium_mg":583,"cholesterol_mg":29,"sat_fat_g":3.8,"trans_fat_g":0.4,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":6,"iron_pct":10}'),
('bojangles_grilled_chicken_sandwich', 'Bojangles Grilled Chicken Sandwich', 285.0, 14.5, 18.0, 16.5, 0.5, 3.0, 200, 200, 'bojangles.com', ARRAY['bojangles grilled sandwich'], '570 cal per 200g sandwich. {"sodium_mg":575,"cholesterol_mg":38,"sat_fat_g":4.5,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":6,"calcium_pct":8,"iron_pct":8}'),
('bojangles_seasoned_fries', 'Bojangles Seasoned Fries', 300.0, 4.2, 36.7, 15.0, 2.5, 0.0, 120, 120, 'bojangles.com', ARRAY['bojangles fries', 'bo fries'], '360 cal per 120g. {"sodium_mg":500,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":8,"calcium_pct":2,"iron_pct":4}'),
('bojangles_dirty_rice', 'Bojangles Dirty Rice', 110.7, 3.3, 16.0, 4.0, 0.7, 0.7, 150, 150, 'bojangles.com', ARRAY['bojangles rice', 'bojangles cajun rice'], '166 cal per 150g. {"sodium_mg":400,"cholesterol_mg":7,"sat_fat_g":1.3,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":2,"calcium_pct":2,"iron_pct":6}'),
('bojangles_cajun_pintos', 'Bojangles Cajun Pintos', 73.3, 4.7, 13.3, 0.0, 3.3, 0.7, 150, 150, 'bojangles.com', ARRAY['bojangles beans', 'bojangles pinto beans'], '110 cal per 150g. {"sodium_mg":333,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":4,"iron_pct":6}'),
('bojangles_mac_and_cheese', 'Bojangles Mac & Cheese', 186.7, 7.3, 20.0, 8.0, 0.7, 2.0, 150, 150, 'bojangles.com', ARRAY['bojangles macaroni'], '280 cal per 150g. {"sodium_mg":467,"cholesterol_mg":13,"sat_fat_g":3.3,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":0,"calcium_pct":10,"iron_pct":4}'),
('bojangles_coleslaw', 'Bojangles Cole Slaw', 133.3, 1.3, 14.7, 8.7, 1.3, 10.0, 150, 150, 'bojangles.com', ARRAY['bojangles slaw'], '200 cal per 150g. {"sodium_mg":200,"cholesterol_mg":7,"sat_fat_g":1.3,"trans_fat_g":0,"vitamin_a_pct":4,"vitamin_c_pct":20,"calcium_pct":2,"iron_pct":2}'),
('bojangles_green_beans', 'Bojangles Green Beans', 33.3, 1.3, 4.7, 0.7, 1.3, 1.3, 150, 150, 'bojangles.com', ARRAY['bojangles beans side'], '50 cal per 150g. {"sodium_mg":200,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0,"vitamin_a_pct":10,"vitamin_c_pct":8,"calcium_pct":2,"iron_pct":4}'),
('bojangles_mashed_potatoes_gravy', 'Bojangles Mashed Potatoes & Gravy', 93.3, 2.0, 14.0, 2.7, 0.7, 0.7, 150, 150, 'bojangles.com', ARRAY['bojangles potatoes'], '140 cal per 150g. {"sodium_mg":367,"cholesterol_mg":3,"sat_fat_g":0.7,"trans_fat_g":0,"vitamin_a_pct":2,"vitamin_c_pct":4,"calcium_pct":2,"iron_pct":2}'),
('bojangles_garden_salad', 'Bojangles Garden Salad', 40.0, 2.0, 5.3, 1.3, 1.3, 2.0, 300, 300, 'bojangles.com', ARRAY['bojangles side salad'], '120 cal per 300g salad. {"sodium_mg":100,"cholesterol_mg":3,"sat_fat_g":0.7,"trans_fat_g":0,"vitamin_a_pct":30,"vitamin_c_pct":25,"calcium_pct":6,"iron_pct":4}'),
('bojangles_honey_mustard', 'Bojangles Honey Mustard Sauce', 280.0, 0.0, 28.0, 20.0, 0.0, 24.0, 50, 50, 'bojangles.com', ARRAY['bojangles dipping sauce'], '140 cal per 50g. {"sodium_mg":400,"cholesterol_mg":10,"sat_fat_g":3.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":0,"iron_pct":0}'),
('bojangles_bo_sauce', 'Bojangles Bo''s Special Sauce', 200.0, 0.0, 16.0, 16.0, 0.0, 12.0, 50, 50, 'bojangles.com', ARRAY['bojangles sauce', 'bo sauce'], '100 cal per 50g. {"sodium_mg":400,"cholesterol_mg":8,"sat_fat_g":2.0,"trans_fat_g":0,"vitamin_a_pct":0,"vitamin_c_pct":0,"calcium_pct":0,"iron_pct":0}'),
-- =====================================================
-- BATCH 10: Restaurant Nutrition Data (with micronutrients)
-- Golden Corral, Bob Evans, Perkins, McAlister's Deli,
-- Jason's Deli, Potbelly, Baja Fresh, Benihana,
-- Village Inn, Fazoli's
-- =====================================================
-- =====================================================
-- 1. GOLDEN CORRAL
-- Source: goldencorral.com, fastfoodnutrition.org, fatsecret.com
-- =====================================================
-- Golden Corral: 20 items written
-- =====================================================
-- 2. BOB EVANS (excluding bob_evans_reeses_pb_pie)
-- Source: bobevans.com, fastfoodnutrition.org, fatsecret.com
-- =====================================================
-- Bob Evans: 21 items written
-- =====================================================
-- 3. PERKINS
-- Source: perkinsrestaurants.com, nutritionix.com, fastfoodnutrition.org
-- =====================================================
-- Perkins: 18 items written
-- =====================================================
-- 4. McALISTER'S DELI
-- Source: mcalistersdeli.com, nutritionix.com
-- =====================================================
-- McAlister's Deli: 18 items written
-- =====================================================
-- 5. JASON'S DELI
-- Source: jasonsdeli.com, nutritionix.com
-- =====================================================
-- Jason's Deli: 15 items written
-- =====================================================
-- 6. POTBELLY
-- Source: potbelly.com, nutritionix.com, fastfoodnutrition.org
-- =====================================================
-- Potbelly: 11 items written
-- =====================================================
-- 7. BAJA FRESH
-- Source: bajafresh.com, nutritionix.com
-- =====================================================
-- Baja Fresh: 15 items written
-- =====================================================
-- 8. BENIHANA
-- Source: benihana.com, myfooddiary.com, nutritionvalue.org
-- =====================================================
-- Benihana: 14 items written
-- =====================================================
-- 9. VILLAGE INN
-- Source: villageinn.com, nutritionix.com
-- =====================================================
-- Village Inn: 17 items written
-- =====================================================
-- 10. FAZOLI'S
-- Source: fazolis.com, nutritionix.com, fastfoodnutrition.org
-- =====================================================
-- Fazoli's: 20 items written
('golden_corral_roasted_chicken_dark', 'Golden Corral Roasted Chicken (Dark Meat)', 106.7, 12.7, 0.0, 6.0, 0.0, 0.0, 150, 150, 'goldencorral.com', ARRAY['golden corral dark meat chicken', 'gc dark chicken'], '160 cal per 150g serving. {"sodium_mg":220,"cholesterol_mg":70,"sat_fat_g":2.0,"trans_fat_g":0}'),
('golden_corral_rotisserie_chicken', 'Golden Corral Rotisserie Chicken', 155.0, 21.5, 0.5, 7.5, 0.5, 0.5, 200, 200, 'goldencorral.com', ARRAY['golden corral chicken', 'gc rotisserie chicken'], '310 cal per 200g serving. {"sodium_mg":535,"cholesterol_mg":87.5,"sat_fat_g":2.25,"trans_fat_g":0}'),
('golden_corral_cheeseburger', 'Golden Corral Cheeseburger', 241.7, 15.0, 13.3, 14.2, 0.4, 3.8, 240, 240, 'goldencorral.com', ARRAY['gc cheeseburger', 'gc burger'], '580 cal per 240g burger. {"sodium_mg":337.5,"cholesterol_mg":8.3,"sat_fat_g":5.0,"trans_fat_g":0.83}'),
('golden_corral_corn', 'Golden Corral Corn', 86.7, 2.0, 12.7, 4.0, 0.7, 3.3, 150, 150, 'goldencorral.com', ARRAY['gc corn', 'golden corral buttered corn'], '130 cal per 150g serving. {"sodium_mg":126.7,"cholesterol_mg":0,"sat_fat_g":1.33,"trans_fat_g":0}'),
('golden_corral_breakfast_pizza', 'Golden Corral Breakfast Pizza', 266.7, 13.3, 16.7, 16.0, 0.7, 1.3, 150, 150, 'goldencorral.com', ARRAY['gc breakfast pizza'], '400 cal per 150g slice. {"sodium_mg":540,"cholesterol_mg":90,"sat_fat_g":8.0,"trans_fat_g":0}'),
('golden_corral_seafood_salad', 'Golden Corral Seafood Salad', 93.3, 3.3, 6.0, 6.7, 1.3, 2.7, 150, 150, 'goldencorral.com', ARRAY['gc seafood salad'], '140 cal per 150g serving. {"sodium_mg":453.3,"cholesterol_mg":6.7,"sat_fat_g":1.0,"trans_fat_g":0}'),
('golden_corral_carne_guisada', 'Golden Corral Carne Guisada', 77.8, 9.4, 2.2, 3.3, 0.6, 1.1, 180, 180, 'goldencorral.com', ARRAY['gc carne guisada', 'golden corral beef stew'], '140 cal per 180g serving. {"sodium_mg":216.7,"cholesterol_mg":27.8,"sat_fat_g":0.83,"trans_fat_g":0}'),
('golden_corral_sirloin_steak', 'Golden Corral Sirloin Steak', 86.7, 9.3, 0.7, 5.3, 0.0, 0.0, 150, 150, 'goldencorral.com', ARRAY['golden corral steak', 'gc sirloin'], '130 cal per 150g serving. {"sodium_mg":233.3,"cholesterol_mg":36.7,"sat_fat_g":2.0,"trans_fat_g":0}'),
('golden_corral_fried_chicken', 'Golden Corral Fried Chicken', 282.4, 22.4, 7.1, 17.6, 0.0, 0.0, 85, 85, 'goldencorral.com', ARRAY['golden corral crispy chicken', 'gc fried chicken'], '240 cal per 85g piece. {"sodium_mg":588,"cholesterol_mg":82.4,"sat_fat_g":5.9,"trans_fat_g":0}'),
('golden_corral_mac_and_cheese', 'Golden Corral Mac and Cheese', 120.0, 3.3, 12.7, 6.7, 0.7, 1.3, 150, 150, 'goldencorral.com', ARRAY['gc mac n cheese', 'golden corral macaroni and cheese'], '180 cal per 150g serving. {"sodium_mg":360,"cholesterol_mg":6.7,"sat_fat_g":2.0,"trans_fat_g":0}'),
('golden_corral_mashed_potatoes', 'Golden Corral Mashed Potatoes', 106.7, 1.3, 13.3, 5.3, 0.7, 0.7, 150, 150, 'goldencorral.com', ARRAY['gc mashed potatoes'], '160 cal per 150g serving. {"sodium_mg":266.7,"cholesterol_mg":3.3,"sat_fat_g":2.0,"trans_fat_g":0}'),
('golden_corral_bacon', 'Golden Corral Bacon', 541.7, 16.7, 16.7, 41.7, 0.0, 16.7, 24, 24, 'goldencorral.com', ARRAY['gc bacon', 'golden corral breakfast bacon'], '130 cal per 24g (2 strips). {"sodium_mg":1458.3,"cholesterol_mg":62.5,"sat_fat_g":10.4,"trans_fat_g":0}'),
('golden_corral_baked_fish', 'Golden Corral Baked Fish', 93.3, 19.3, 0.0, 2.0, 0.0, 0.0, 150, 150, 'goldencorral.com', ARRAY['golden corral fish', 'gc baked fish'], '140 cal per 150g serving. {"sodium_mg":200,"cholesterol_mg":40,"sat_fat_g":0.33,"trans_fat_g":0}'),
('golden_corral_pot_roast', 'Golden Corral Pot Roast', 116.7, 13.3, 3.3, 5.0, 0.3, 1.1, 180, 180, 'goldencorral.com', ARRAY['gc pot roast', 'golden corral beef roast'], '210 cal per 180g serving. {"sodium_mg":250,"cholesterol_mg":36.1,"sat_fat_g":1.67,"trans_fat_g":0}'),
('golden_corral_meatloaf', 'Golden Corral Meatloaf', 150.0, 10.0, 8.3, 7.8, 0.3, 2.8, 180, 180, 'goldencorral.com', ARRAY['gc meatloaf'], '270 cal per 180g serving. {"sodium_mg":344.4,"cholesterol_mg":41.7,"sat_fat_g":2.78,"trans_fat_g":0.28}'),
('golden_corral_bourbon_chicken', 'Golden Corral Bourbon Chicken', 146.7, 10.0, 12.0, 4.7, 0.0, 8.0, 150, 150, 'goldencorral.com', ARRAY['gc bourbon chicken'], '220 cal per 150g serving. {"sodium_mg":433.3,"cholesterol_mg":36.7,"sat_fat_g":1.0,"trans_fat_g":0}'),
('golden_corral_green_beans', 'Golden Corral Green Beans', 33.3, 1.3, 5.3, 1.3, 1.3, 1.3, 150, 150, 'goldencorral.com', ARRAY['gc green beans'], '50 cal per 150g serving. {"sodium_mg":133.3,"cholesterol_mg":0,"sat_fat_g":0.33,"trans_fat_g":0}'),
('golden_corral_steamed_broccoli', 'Golden Corral Steamed Broccoli', 33.3, 2.0, 4.0, 1.3, 2.0, 1.3, 150, 150, 'goldencorral.com', ARRAY['gc broccoli'], '50 cal per 150g serving. {"sodium_mg":100,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),
('golden_corral_yeast_rolls', 'Golden Corral Yeast Rolls', 253.3, 6.7, 40.0, 6.7, 1.3, 5.3, 75, 75, 'goldencorral.com', ARRAY['gc rolls', 'golden corral dinner rolls'], '190 cal per 75g roll. {"sodium_mg":386.7,"cholesterol_mg":0,"sat_fat_g":2.0,"trans_fat_g":0}'),
('golden_corral_scrambled_eggs', 'Golden Corral Scrambled Eggs', 128.6, 10.0, 0.7, 9.3, 0.0, 0.7, 140, 140, 'goldencorral.com', ARRAY['gc scrambled eggs', 'golden corral eggs'], '180 cal per 140g serving. {"sodium_mg":242.9,"cholesterol_mg":264.3,"sat_fat_g":2.86,"trans_fat_g":0}'),
('golden_corral_sausage_links', 'Golden Corral Sausage Links', 340.0, 16.0, 2.0, 30.0, 0.0, 0.0, 50, 50, 'goldencorral.com', ARRAY['gc sausage', 'golden corral breakfast sausage'], '170 cal per 2-link 50g serving. {"sodium_mg":700,"cholesterol_mg":70,"sat_fat_g":10.0,"trans_fat_g":0}'),
('golden_corral_french_toast', 'Golden Corral French Toast', 220.0, 6.0, 30.0, 8.0, 0.5, 8.0, 100, 100, 'goldencorral.com', ARRAY['gc french toast'], '220 cal per 100g slice. {"sodium_mg":280,"cholesterol_mg":60,"sat_fat_g":2.0,"trans_fat_g":0}'),
('golden_corral_chocolate_cake', 'Golden Corral Chocolate Cake', 291.7, 3.3, 41.7, 13.3, 1.7, 31.7, 120, 120, 'goldencorral.com', ARRAY['gc chocolate cake'], '350 cal per 120g slice. {"sodium_mg":291.7,"cholesterol_mg":29.2,"sat_fat_g":4.17,"trans_fat_g":0}'),
('golden_corral_soft_serve', 'Golden Corral Soft Serve Ice Cream', 133.3, 2.7, 22.0, 4.0, 0.0, 16.0, 150, 150, 'goldencorral.com', ARRAY['gc ice cream', 'gc soft serve'], '200 cal per 150g serving. {"sodium_mg":66.7,"cholesterol_mg":16.7,"sat_fat_g":2.67,"trans_fat_g":0}'),
('golden_corral_cornbread', 'Golden Corral Cornbread', 250.0, 5.0, 35.0, 10.0, 1.3, 12.5, 80, 80, 'goldencorral.com', ARRAY['gc cornbread'], '200 cal per 80g piece. {"sodium_mg":425,"cholesterol_mg":31.3,"sat_fat_g":2.5,"trans_fat_g":0}'),
('bob_evans_western_omelet', 'Bob Evans Western Omelet', 260.0, 16.0, 4.4, 20.0, 0.4, 2.0, 250, 250, 'bobevans.com', ARRAY['bob evans western omelette'], '650 cal per 250g omelet. {"sodium_mg":636,"cholesterol_mg":254,"sat_fat_g":6.8,"trans_fat_g":0}'),
('bob_evans_buttermilk_hotcakes', 'Bob Evans Buttermilk Hotcakes', 325.7, 4.9, 59.7, 8.0, 1.1, 11.1, 350, 350, 'bobevans.com', ARRAY['bob evans pancakes', 'bob evans hotcakes stack'], '1140 cal for 4 hotcakes w/ butter and syrup (~350g). {"sodium_mg":545.7,"cholesterol_mg":2.9,"sat_fat_g":2.57,"trans_fat_g":0}'),
('bob_evans_scrambled_eggs', 'Bob Evans Scrambled Eggs', 114.3, 10.0, 0.7, 7.9, 0.0, 0.0, 140, 140, 'bobevans.com', ARRAY['bob evans eggs'], '160 cal per 140g serving. {"sodium_mg":128.6,"cholesterol_mg":264.3,"sat_fat_g":2.14,"trans_fat_g":0}'),
('bob_evans_bacon', 'Bob Evans Hickory-Smoked Bacon', 325.0, 22.5, 0.0, 22.5, 0.0, 0.0, 40, 40, 'bobevans.com', ARRAY['bob evans bacon strips'], '130 cal per 40g (4 strips). {"sodium_mg":1150,"cholesterol_mg":75,"sat_fat_g":7.5,"trans_fat_g":0}'),
('bob_evans_sausage_links', 'Bob Evans Sausage Links', 350.0, 16.7, 0.0, 31.7, 0.0, 0.0, 60, 60, 'bobevans.com', ARRAY['bob evans sausage', 'bob evans pork sausage'], '210 cal per 60g (2 links). {"sodium_mg":783.3,"cholesterol_mg":75,"sat_fat_g":10.0,"trans_fat_g":0}'),
('bob_evans_hashbrowns', 'Bob Evans Hashbrowns', 120.0, 1.3, 18.7, 4.7, 2.0, 0.7, 150, 150, 'bobevans.com', ARRAY['bob evans hash browns'], '180 cal per 150g serving. {"sodium_mg":233.3,"cholesterol_mg":0,"sat_fat_g":0.67,"trans_fat_g":0}'),
('bob_evans_sausage_gravy_biscuits', 'Bob Evans Sausage Gravy & Biscuits', 283.3, 5.3, 19.0, 15.7, 0.3, 1.7, 300, 300, 'bobevans.com', ARRAY['bob evans biscuits and gravy'], '850 cal per bowl (~300g). {"sodium_mg":733.3,"cholesterol_mg":15,"sat_fat_g":4.67,"trans_fat_g":0}'),
('bob_evans_brioche_french_toast', 'Bob Evans Brioche French Toast', 260.0, 4.0, 55.5, 7.5, 0.5, 27.0, 200, 200, 'bobevans.com', ARRAY['bob evans french toast'], '520 cal per serving w/ butter/syrup (~200g). {"sodium_mg":215,"cholesterol_mg":60,"sat_fat_g":2.5,"trans_fat_g":0}'),
('bob_evans_steakhouse_burger', 'Bob Evans Steakhouse Burger', 362.5, 18.8, 19.6, 22.9, 0.8, 3.8, 240, 240, 'bobevans.com', ARRAY['bob evans burger', 'bob evans cheeseburger'], '870 cal per 240g burger. {"sodium_mg":583.3,"cholesterol_mg":70.8,"sat_fat_g":9.17,"trans_fat_g":0.83}'),
('bob_evans_fried_chicken_tenders', 'Bob Evans Fried Chicken Tenders', 238.9, 12.8, 17.2, 13.3, 0.6, 0.6, 180, 180, 'bobevans.com', ARRAY['bob evans chicken strips', 'bob evans chicken fingers'], '430 cal per 180g serving. {"sodium_mg":605.6,"cholesterol_mg":27.8,"sat_fat_g":2.78,"trans_fat_g":0}'),
('bob_evans_country_fried_steak', 'Bob Evans Country-Fried Steak', 180.0, 6.7, 11.7, 10.0, 0.3, 1.0, 300, 300, 'bobevans.com', ARRAY['bob evans chicken fried steak'], '540 cal per 300g serving w/ gravy. {"sodium_mg":540,"cholesterol_mg":25,"sat_fat_g":2.67,"trans_fat_g":0.17}'),
('bob_evans_turkey_sandwich', 'Bob Evans Legendary Turkey Sandwich', 233.3, 16.7, 20.3, 9.3, 1.0, 2.7, 300, 300, 'bobevans.com', ARRAY['bob evans turkey sandwich'], '700 cal per 300g sandwich. {"sodium_mg":700,"cholesterol_mg":33.3,"sat_fat_g":2.67,"trans_fat_g":0}'),
('bob_evans_blt', 'Bob Evans All American BLT', 226.7, 9.0, 21.3, 11.7, 1.0, 3.3, 300, 300, 'bobevans.com', ARRAY['bob evans blt sandwich'], '680 cal per 300g sandwich. {"sodium_mg":560,"cholesterol_mg":18.3,"sat_fat_g":3.33,"trans_fat_g":0}'),
('bob_evans_wildfire_chicken_salad', 'Bob Evans Wildfire Grilled Chicken Salad', 148.6, 12.9, 10.9, 6.0, 1.1, 5.7, 350, 350, 'bobevans.com', ARRAY['bob evans chicken salad'], '520 cal per 350g salad. {"sodium_mg":400,"cholesterol_mg":31.4,"sat_fat_g":1.71,"trans_fat_g":0}'),
('bob_evans_cranberry_pecan_salad', 'Bob Evans Cranberry Pecan Chicken Salad', 194.3, 15.7, 11.4, 9.7, 1.4, 4.6, 350, 350, 'bobevans.com', ARRAY['bob evans pecan salad'], '680 cal per 350g salad. {"sodium_mg":457.1,"cholesterol_mg":34.3,"sat_fat_g":2.57,"trans_fat_g":0}'),
('bob_evans_mashed_potatoes', 'Bob Evans Mashed Potatoes', 100.0, 2.0, 12.7, 4.7, 0.7, 0.7, 150, 150, 'bobevans.com', ARRAY['bob evans mashed potatoes and gravy'], '150 cal per 150g serving. {"sodium_mg":286.7,"cholesterol_mg":6.7,"sat_fat_g":1.67,"trans_fat_g":0}'),
('bob_evans_glazed_carrots', 'Bob Evans Glazed Carrots', 60.0, 0.0, 8.7, 3.0, 1.3, 5.3, 150, 150, 'bobevans.com', ARRAY['bob evans carrots'], '90 cal per 150g serving. {"sodium_mg":160,"cholesterol_mg":6.7,"sat_fat_g":1.33,"trans_fat_g":0}'),
('bob_evans_buttered_corn', 'Bob Evans Buttered Corn', 113.3, 2.0, 14.7, 6.7, 1.3, 4.0, 150, 150, 'bobevans.com', ARRAY['bob evans corn'], '170 cal per 150g serving. {"sodium_mg":260,"cholesterol_mg":6.7,"sat_fat_g":2.0,"trans_fat_g":0}'),
('bob_evans_chicken_noodle_soup', 'Bob Evans Chicken-N-Noodles (Cup)', 50.0, 2.9, 5.4, 2.1, 0.4, 0.4, 240, 240, 'bobevans.com', ARRAY['bob evans chicken noodle soup'], '120 cal per cup (240g). {"sodium_mg":345.8,"cholesterol_mg":10.4,"sat_fat_g":0.63,"trans_fat_g":0}'),
('bob_evans_pumpkin_pie', 'Bob Evans Pumpkin Pie', 261.1, 2.8, 38.3, 8.3, 1.1, 23.3, 180, 180, 'bobevans.com', ARRAY['bob evans pumpkin pie slice'], '470 cal per 180g slice. {"sodium_mg":222.2,"cholesterol_mg":33.3,"sat_fat_g":2.78,"trans_fat_g":0}'),
('bob_evans_apple_pie', 'Bob Evans Double-Crust Apple Pie', 333.3, 2.2, 45.6, 15.6, 1.1, 22.2, 180, 180, 'bobevans.com', ARRAY['bob evans apple pie slice'], '600 cal per 180g slice. {"sodium_mg":216.7,"cholesterol_mg":8.3,"sat_fat_g":5.56,"trans_fat_g":0}'),
('bob_evans_banana_nut_bread', 'Bob Evans Banana Nut Bread', 260.0, 4.0, 32.0, 9.0, 1.0, 16.0, 100, 100, 'bobevans.com', ARRAY['bob evans banana bread'], '260 cal per 100g slice. {"sodium_mg":300,"cholesterol_mg":30,"sat_fat_g":2.0,"trans_fat_g":0}'),
('perkins_buttermilk_pancakes', 'Perkins Buttermilk Pancakes (3)', 221.3, 3.7, 27.0, 10.7, 0.0, 4.9, 244, 244, 'perkinsrestaurants.com', ARRAY['perkins pancakes', 'perkins short stack'], '540 cal per 3-pancake order (244g). {"sodium_mg":405.7,"cholesterol_mg":22.5,"sat_fat_g":1.23,"trans_fat_g":0}'),
('perkins_blueberry_pancakes', 'Perkins Blueberry Pancakes (3)', 213.1, 3.3, 29.9, 8.6, 0.4, 7.8, 244, 244, 'perkinsrestaurants.com', ARRAY['perkins blueberry pancake stack'], '520 cal per 3-pancake order (244g). {"sodium_mg":393.4,"cholesterol_mg":22.5,"sat_fat_g":1.23,"trans_fat_g":0}'),
('perkins_belgian_waffle', 'Perkins Belgian Waffle', 227.8, 3.9, 27.2, 11.7, 1.1, 4.4, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins waffle'], '410 cal per 180g waffle. {"sodium_mg":327.8,"cholesterol_mg":66.7,"sat_fat_g":4.44,"trans_fat_g":0}'),
('perkins_brioche_french_toast', 'Perkins Brioche French Toast (2 slices)', 295.0, 13.0, 31.5, 13.0, 1.0, 8.0, 200, 200, 'perkinsrestaurants.com', ARRAY['perkins french toast'], '590 cal per 2-slice serving (~200g). {"sodium_mg":290,"cholesterol_mg":125,"sat_fat_g":5.0,"trans_fat_g":0}'),
('perkins_farmers_omelet', 'Perkins Farmer''s Omelet', 235.7, 13.9, 2.9, 19.3, 0.0, 0.7, 280, 280, 'perkinsrestaurants.com', ARRAY['perkins farmers omelette'], '660 cal per 280g omelet. {"sodium_mg":385.7,"cholesterol_mg":250,"sat_fat_g":7.14,"trans_fat_g":0.18}'),
('perkins_everything_skillet', 'Perkins Everything Skillet', 174.6, 6.6, 10.8, 11.6, 1.3, 1.3, 544, 544, 'perkinsrestaurants.com', ARRAY['perkins skillet breakfast'], '950 cal per 544g serving. {"sodium_mg":386,"cholesterol_mg":119.5,"sat_fat_g":4.04,"trans_fat_g":0.09}'),
('perkins_grilled_chicken', 'Perkins Grilled Chicken Breast', 123.5, 21.2, 0.0, 2.9, 0.0, 0.0, 170, 170, 'perkinsrestaurants.com', ARRAY['perkins chicken breast', 'perkins grilled chicken dinner'], '210 cal per 170g breast. {"sodium_mg":264.7,"cholesterol_mg":50,"sat_fat_g":0.88,"trans_fat_g":0}'),
('perkins_fish_and_chips', 'Perkins Fish & Chips', 228.6, 8.6, 18.6, 12.9, 1.1, 0.6, 350, 350, 'perkinsrestaurants.com', ARRAY['perkins fish n chips'], '800 cal per 350g serving. {"sodium_mg":514.3,"cholesterol_mg":25.7,"sat_fat_g":2.29,"trans_fat_g":0}'),
('perkins_classic_burger', 'Perkins Classic Burger', 282.6, 12.2, 18.3, 16.5, 0.9, 3.5, 230, 230, 'perkinsrestaurants.com', ARRAY['perkins hamburger', 'perkins cheeseburger'], '650 cal per 230g burger. {"sodium_mg":478.3,"cholesterol_mg":52.2,"sat_fat_g":6.09,"trans_fat_g":0.43}'),
('perkins_chicken_noodle_soup', 'Perkins Chicken Noodle Soup (Cup)', 50.0, 2.9, 5.8, 1.3, 0.4, 0.4, 240, 240, 'perkinsrestaurants.com', ARRAY['perkins chicken soup'], '120 cal per cup (240g). {"sodium_mg":341.7,"cholesterol_mg":10.4,"sat_fat_g":0.42,"trans_fat_g":0}'),
('perkins_french_silk_pie', 'Perkins French Silk Pie', 361.1, 3.3, 40.0, 22.2, 1.1, 26.7, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins chocolate pie', 'perkins silk pie'], '650 cal per 180g slice. {"sodium_mg":161.1,"cholesterol_mg":50,"sat_fat_g":12.22,"trans_fat_g":0}'),
('perkins_wildberry_pie', 'Perkins Wildberry Pie', 238.9, 2.2, 37.2, 10.0, 1.1, 19.4, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins berry pie', 'perkins wild berry pie slice'], '430 cal per 180g slice. {"sodium_mg":194.4,"cholesterol_mg":0,"sat_fat_g":3.89,"trans_fat_g":0}'),
('perkins_apple_pie', 'Perkins Apple Pie', 222.2, 1.7, 34.4, 10.0, 1.1, 18.3, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins apple pie slice'], '400 cal per 180g slice. {"sodium_mg":183.3,"cholesterol_mg":0,"sat_fat_g":3.89,"trans_fat_g":0}'),
('perkins_coconut_cream_pie', 'Perkins Coconut Cream Pie', 305.6, 3.9, 36.7, 16.7, 0.6, 24.4, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins coconut pie'], '550 cal per 180g slice. {"sodium_mg":188.9,"cholesterol_mg":27.8,"sat_fat_g":10.0,"trans_fat_g":0}'),
('perkins_peanut_butter_silk_pie', 'Perkins Peanut Butter Silk Pie', 372.2, 5.0, 38.9, 23.3, 1.7, 25.6, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins pb pie', 'perkins peanut butter pie'], '670 cal per 180g slice. {"sodium_mg":211.1,"cholesterol_mg":30.6,"sat_fat_g":10.0,"trans_fat_g":0}'),
('perkins_lemon_meringue_pie', 'Perkins Lemon Meringue Pie', 233.3, 2.2, 40.0, 8.3, 0.0, 27.2, 180, 180, 'perkinsrestaurants.com', ARRAY['perkins lemon pie'], '420 cal per 180g slice. {"sodium_mg":155.6,"cholesterol_mg":44.4,"sat_fat_g":2.78,"trans_fat_g":0}'),
('perkins_mashed_potatoes', 'Perkins Mashed Potatoes', 100.0, 2.0, 14.0, 4.0, 0.7, 0.7, 150, 150, 'perkinsrestaurants.com', ARRAY['perkins mashed potatoes and gravy'], '150 cal per 150g serving. {"sodium_mg":280,"cholesterol_mg":6.7,"sat_fat_g":1.33,"trans_fat_g":0}'),
('perkins_french_fries', 'Perkins French Fries', 220.0, 2.0, 30.0, 10.7, 2.0, 0.7, 150, 150, 'perkinsrestaurants.com', ARRAY['perkins fries'], '330 cal per 150g serving. {"sodium_mg":326.7,"cholesterol_mg":0,"sat_fat_g":2.0,"trans_fat_g":0}'),
('mcalisters_club_sandwich', 'McAlister''s Club Sandwich', 260.0, 12.9, 26.0, 12.6, 2.0, 6.6, 350, 350, 'mcalistersdeli.com', ARRAY['mcalisters club', 'mcalisters deli club'], '910 cal per 350g sandwich. {"sodium_mg":748.6,"cholesterol_mg":34.3,"sat_fat_g":4.0,"trans_fat_g":0}'),
('mcalisters_reuben', 'McAlister''s Reuben', 262.9, 16.3, 18.6, 13.7, 1.4, 4.6, 350, 350, 'mcalistersdeli.com', ARRAY['mcalisters reuben sandwich'], '920 cal per 350g sandwich. {"sodium_mg":937.1,"cholesterol_mg":48.6,"sat_fat_g":4.57,"trans_fat_g":0.29}'),
('mcalisters_new_yorker', 'McAlister''s The New Yorker', 243.3, 22.3, 17.3, 9.3, 0.7, 1.7, 300, 300, 'mcalistersdeli.com', ARRAY['mcalisters new yorker pastrami'], '730 cal per 300g sandwich. {"sodium_mg":953.3,"cholesterol_mg":63.3,"sat_fat_g":3.33,"trans_fat_g":0}'),
('mcalisters_grilled_chicken', 'McAlister''s Grilled Chicken Sandwich', 210.7, 13.9, 16.4, 9.6, 1.1, 4.6, 280, 280, 'mcalistersdeli.com', ARRAY['mcalisters chicken sandwich'], '590 cal per 280g sandwich. {"sodium_mg":557.1,"cholesterol_mg":35.7,"sat_fat_g":2.86,"trans_fat_g":0}'),
('mcalisters_turkey_ranch_blt', 'McAlister''s Turkey Ranch BLT', 223.3, 12.3, 16.3, 13.0, 0.7, 3.3, 300, 300, 'mcalistersdeli.com', ARRAY['mcalisters turkey blt'], '670 cal per 300g sandwich. {"sodium_mg":650,"cholesterol_mg":26.7,"sat_fat_g":3.33,"trans_fat_g":0}'),
('mcalisters_french_dip', 'McAlister''s French Dip (6-inch)', 228.6, 18.9, 16.1, 9.6, 0.7, 0.7, 280, 280, 'mcalistersdeli.com', ARRAY['mcalisters french dip sandwich'], '640 cal per 6-inch (280g). {"sodium_mg":1000,"cholesterol_mg":50,"sat_fat_g":3.93,"trans_fat_g":0.36}'),
('mcalisters_cuban', 'McAlister''s Cuban Sandwich (6-inch)', 289.3, 16.8, 18.2, 15.7, 0.7, 1.1, 280, 280, 'mcalistersdeli.com', ARRAY['mcalisters cuban', 'mcalisters cubano'], '810 cal per 6-inch (280g). {"sodium_mg":942.9,"cholesterol_mg":46.4,"sat_fat_g":5.71,"trans_fat_g":0}'),
('mcalisters_italian', 'McAlister''s The Italian (6-inch)', 289.3, 16.1, 18.6, 16.4, 1.1, 2.9, 280, 280, 'mcalistersdeli.com', ARRAY['mcalisters italian sub'], '810 cal per 6-inch (280g). {"sodium_mg":1028.6,"cholesterol_mg":39.3,"sat_fat_g":5.71,"trans_fat_g":0}'),
('mcalisters_broccoli_cheddar_soup', 'McAlister''s Broccoli Cheddar Soup (Cup)', 125.0, 4.6, 9.6, 7.9, 0.8, 1.7, 240, 240, 'mcalistersdeli.com', ARRAY['mcalisters broccoli cheese soup'], '300 cal per cup (240g). {"sodium_mg":400,"cholesterol_mg":16.7,"sat_fat_g":4.17,"trans_fat_g":0}'),
('mcalisters_chicken_tortilla_soup', 'McAlister''s Chicken Tortilla Soup (Cup)', 87.5, 2.9, 10.4, 3.8, 0.8, 0.8, 240, 240, 'mcalistersdeli.com', ARRAY['mcalisters tortilla soup'], '210 cal per cup (240g). {"sodium_mg":425,"cholesterol_mg":10.4,"sat_fat_g":1.25,"trans_fat_g":0}'),
('mcalisters_chili', 'McAlister''s Traditional Chili (Cup)', 125.0, 7.9, 13.3, 5.0, 0.8, 2.1, 240, 240, 'mcalistersdeli.com', ARRAY['mcalisters chili soup'], '300 cal per cup (240g). {"sodium_mg":445.8,"cholesterol_mg":20.8,"sat_fat_g":2.08,"trans_fat_g":0}'),
('mcalisters_grilled_chicken_salad', 'McAlister''s Grilled Chicken Salad', 140.0, 13.4, 5.7, 7.4, 1.1, 2.0, 350, 350, 'mcalistersdeli.com', ARRAY['mcalisters chicken salad'], '490 cal per 350g salad. {"sodium_mg":311.4,"cholesterol_mg":37.1,"sat_fat_g":2.29,"trans_fat_g":0}'),
('mcalisters_southwest_salad', 'McAlister''s Southwest Chicken & Avocado Salad', 150.0, 11.3, 9.0, 8.0, 2.5, 2.5, 400, 400, 'mcalistersdeli.com', ARRAY['mcalisters southwest salad'], '600 cal per 400g salad. {"sodium_mg":360,"cholesterol_mg":30,"sat_fat_g":2.0,"trans_fat_g":0}'),
('mcalisters_spud_max', 'McAlister''s Spud Max', 242.2, 10.0, 30.0, 9.3, 3.1, 2.4, 450, 450, 'mcalistersdeli.com', ARRAY['mcalisters loaded baked potato', 'mcalisters spud'], '1090 cal per 450g spud. {"sodium_mg":506.7,"cholesterol_mg":17.8,"sat_fat_g":3.56,"trans_fat_g":0}'),
('mcalisters_classic_spud', 'McAlister''s Classic Spud', 177.5, 4.3, 32.8, 3.5, 3.5, 2.3, 400, 400, 'mcalistersdeli.com', ARRAY['mcalisters plain baked potato'], '710 cal per 400g spud. {"sodium_mg":72.5,"cholesterol_mg":2.5,"sat_fat_g":1.25,"trans_fat_g":0}'),
('mcalisters_chocolate_chip_cookie', 'McAlister''s Chocolate Chip Cookie', 528.6, 5.7, 75.7, 24.3, 2.9, 47.1, 70, 70, 'mcalistersdeli.com', ARRAY['mcalisters cookie'], '370 cal per 70g cookie. {"sodium_mg":371.4,"cholesterol_mg":42.9,"sat_fat_g":14.29,"trans_fat_g":0}'),
('mcalisters_brownie', 'McAlister''s Brownie', 430.0, 4.0, 61.0, 21.0, 0.0, 40.0, 100, 100, 'mcalistersdeli.com', ARRAY['mcalisters chocolate brownie'], '430 cal per 100g brownie. {"sodium_mg":210,"cholesterol_mg":55,"sat_fat_g":7.0,"trans_fat_g":0}'),
('mcalisters_mac_and_cheese', 'McAlister''s Mac & Cheese', 153.3, 5.3, 13.3, 9.3, 0.7, 2.7, 150, 150, 'mcalistersdeli.com', ARRAY['mcalisters macaroni and cheese'], '230 cal per 150g side. {"sodium_mg":393.3,"cholesterol_mg":20,"sat_fat_g":4.67,"trans_fat_g":0}'),
('jasons_deli_amys_turkey_o', 'Jason''s Deli Amy''s Turkey-O', 140.0, 9.7, 14.0, 5.7, 2.0, 2.3, 300, 300, 'jasonsdeli.com', ARRAY['jasons amys turkey sandwich'], '420 cal per sandwich (300g). {"sodium_mg":393.3,"cholesterol_mg":18.3,"sat_fat_g":1.33,"trans_fat_g":0}'),
('jasons_deli_santa_fe_chicken', 'Jason''s Deli Santa Fe Chicken', 236.7, 18.0, 17.7, 10.7, 2.7, 4.0, 300, 300, 'jasonsdeli.com', ARRAY['jasons santa fe chicken sandwich'], '710 cal per sandwich (300g). {"sodium_mg":603.3,"cholesterol_mg":33.3,"sat_fat_g":3.33,"trans_fat_g":0}'),
('jasons_deli_meataballa', 'Jason''s Deli MeataBalla', 320.0, 16.6, 18.6, 18.9, 0.9, 1.4, 350, 350, 'jasonsdeli.com', ARRAY['jasons meatball sub', 'jasons meatball sandwich'], '1120 cal per full sandwich (350g). {"sodium_mg":794.3,"cholesterol_mg":51.4,"sat_fat_g":7.43,"trans_fat_g":0.29}'),
('jasons_deli_reuben', 'Jason''s Deli Reuben The Great', 268.6, 15.7, 14.3, 20.9, 1.7, 1.1, 350, 350, 'jasonsdeli.com', ARRAY['jasons reuben sandwich'], '940 cal per sandwich (350g). {"sodium_mg":931.4,"cholesterol_mg":51.4,"sat_fat_g":8.0,"trans_fat_g":0.14}'),
('jasons_deli_new_york_yankee', 'Jason''s Deli New York Yankee', 305.7, 20.0, 12.6, 23.7, 0.9, 0.3, 350, 350, 'jasonsdeli.com', ARRAY['jasons ny yankee', 'jasons pastrami sandwich'], '1070 cal per sandwich (350g). {"sodium_mg":1114.3,"cholesterol_mg":65.7,"sat_fat_g":9.14,"trans_fat_g":0}'),
('jasons_deli_california_club', 'Jason''s Deli California Club', 230.0, 12.3, 14.7, 13.7, 0.7, 2.3, 300, 300, 'jasonsdeli.com', ARRAY['jasons cali club sandwich'], '690 cal per sandwich (300g). {"sodium_mg":513.3,"cholesterol_mg":26.7,"sat_fat_g":4.0,"trans_fat_g":0}'),
('jasons_deli_turkey_muffaletta', 'Jason''s Deli Turkey Muffaletta (Quarter)', 196.0, 11.2, 16.4, 9.6, 1.2, 1.2, 250, 250, 'jasonsdeli.com', ARRAY['jasons turkey muffuletta'], '490 cal per quarter (250g). {"sodium_mg":588,"cholesterol_mg":26,"sat_fat_g":3.2,"trans_fat_g":0}'),
('jasons_deli_chicken_panini', 'Jason''s Deli Chicken Panini', 278.6, 17.1, 17.1, 15.4, 0.7, 1.1, 280, 280, 'jasonsdeli.com', ARRAY['jasons grilled chicken panini'], '780 cal per panini (280g). {"sodium_mg":585.7,"cholesterol_mg":42.9,"sat_fat_g":5.71,"trans_fat_g":0}'),
('jasons_deli_broccoli_cheese_soup', 'Jason''s Deli Broccoli Cheese Soup (Cup)', 108.3, 5.4, 9.6, 5.0, 0.4, 2.5, 240, 240, 'jasonsdeli.com', ARRAY['jasons broccoli soup'], '260 cal per cup (240g). {"sodium_mg":395.8,"cholesterol_mg":14.6,"sat_fat_g":2.5,"trans_fat_g":0}'),
('jasons_deli_tomato_basil_soup', 'Jason''s Deli Tomato Basil Soup (Cup)', 100.0, 2.9, 7.9, 5.8, 0.8, 4.6, 240, 240, 'jasonsdeli.com', ARRAY['jasons tomato soup'], '240 cal per cup (240g). {"sodium_mg":300,"cholesterol_mg":12.5,"sat_fat_g":3.33,"trans_fat_g":0}'),
('jasons_deli_nutty_mixed_up_salad', 'Jason''s Deli Nutty Mixed-Up Salad', 187.5, 10.0, 14.8, 11.8, 1.8, 11.8, 400, 400, 'jasonsdeli.com', ARRAY['jasons nutty salad', 'jasons mixed up salad'], '750 cal per salad (400g). {"sodium_mg":275,"cholesterol_mg":22.5,"sat_fat_g":2.5,"trans_fat_g":0}'),
('jasons_deli_texas_spud', 'Jason''s Deli Texas Style Spud', 312.0, 9.6, 45.6, 10.8, 4.0, 11.8, 500, 500, 'jasonsdeli.com', ARRAY['jasons baked potato', 'jasons texas spud'], '1560 cal per spud (500g). {"sodium_mg":284,"cholesterol_mg":14,"sat_fat_g":4.4,"trans_fat_g":0}'),
('jasons_deli_chocolate_chip_cookie', 'Jason''s Deli Chocolate Chip Cookie', 442.9, 4.3, 61.4, 21.4, 2.9, 38.6, 70, 70, 'jasonsdeli.com', ARRAY['jasons cookie'], '310 cal per 70g cookie. {"sodium_mg":328.6,"cholesterol_mg":35.7,"sat_fat_g":12.86,"trans_fat_g":0}'),
('jasons_deli_cheesecake', 'Jason''s Deli Classic Cheesecake', 425.0, 6.9, 35.6, 28.8, 1.3, 25.0, 160, 160, 'jasonsdeli.com', ARRAY['jasons cheesecake slice'], '680 cal per 160g slice. {"sodium_mg":275,"cholesterol_mg":112.5,"sat_fat_g":16.25,"trans_fat_g":0}'),
('jasons_deli_texas_chocolate_cake', 'Jason''s Deli Texas Chocolate Cake', 373.3, 2.7, 53.3, 18.0, 0.7, 42.0, 150, 150, 'jasonsdeli.com', ARRAY['jasons chocolate cake'], '560 cal per 150g slice. {"sodium_mg":333.3,"cholesterol_mg":33.3,"sat_fat_g":6.67,"trans_fat_g":0}'),
('potbelly_wreck', 'Potbelly A Wreck Sandwich (Original)', 184.2, 10.0, 16.8, 7.9, 1.1, 1.1, 380, 380, 'potbelly.com', ARRAY['potbelly wreck', 'potbelly a wreck original'], '700 cal per original sandwich (380g). {"sodium_mg":500,"cholesterol_mg":22.4,"sat_fat_g":2.63,"trans_fat_g":0}'),
('potbelly_italian', 'Potbelly Italian Sandwich (Original)', 194.7, 9.5, 15.8, 10.0, 0.8, 0.8, 380, 380, 'potbelly.com', ARRAY['potbelly italian', 'potbelly italian original'], '740 cal per original sandwich (380g). {"sodium_mg":578.9,"cholesterol_mg":25,"sat_fat_g":3.68,"trans_fat_g":0}'),
('potbelly_turkey_swiss', 'Potbelly Turkey Breast & Swiss (Original)', 170.3, 10.3, 19.7, 5.4, 1.4, 1.1, 370, 370, 'potbelly.com', ARRAY['potbelly turkey sandwich', 'potbelly turkey swiss'], '630 cal per original sandwich (370g). {"sodium_mg":443.2,"cholesterol_mg":17.6,"sat_fat_g":1.89,"trans_fat_g":0}'),
('potbelly_grilled_chicken_cheddar', 'Potbelly Grilled Chicken & Cheddar (Original)', 158.3, 13.9, 17.2, 3.9, 1.1, 0.8, 360, 360, 'potbelly.com', ARRAY['potbelly chicken sandwich', 'potbelly grilled chicken'], '570 cal per original sandwich (360g). {"sodium_mg":438.9,"cholesterol_mg":22.2,"sat_fat_g":1.39,"trans_fat_g":0}'),
('potbelly_avo_turkey', 'Potbelly Avo Turkey (Original)', 168.4, 12.1, 19.2, 6.3, 2.9, 0.8, 380, 380, 'potbelly.com', ARRAY['potbelly avocado turkey sandwich'], '640 cal per original sandwich (380g). {"sodium_mg":447.4,"cholesterol_mg":17.1,"sat_fat_g":1.84,"trans_fat_g":0}'),
('potbelly_mediterranean', 'Potbelly Mediterranean Sandwich (Original)', 176.3, 14.2, 21.3, 4.5, 2.9, 2.1, 380, 380, 'potbelly.com', ARRAY['potbelly med sandwich'], '670 cal per original sandwich (380g). {"sodium_mg":473.7,"cholesterol_mg":14.5,"sat_fat_g":1.58,"trans_fat_g":0}'),
('potbelly_broccoli_cheddar_soup', 'Potbelly Broccoli Cheddar Soup (Cup)', 72.9, 2.5, 5.0, 5.0, 0.8, 1.3, 240, 240, 'potbelly.com', ARRAY['potbelly broccoli cheese soup'], '175 cal per cup (240g). {"sodium_mg":325,"cholesterol_mg":12.5,"sat_fat_g":2.92,"trans_fat_g":0}'),
('potbelly_chili', 'Potbelly Chili (Cup)', 77.1, 3.8, 7.5, 3.3, 2.1, 1.3, 240, 240, 'potbelly.com', ARRAY['potbelly chili soup'], '185 cal per cup (240g). {"sodium_mg":258.3,"cholesterol_mg":10.4,"sat_fat_g":1.25,"trans_fat_g":0}'),
('potbelly_farmhouse_salad', 'Potbelly Farmhouse Salad', 189.5, 9.5, 8.5, 13.5, 1.8, 3.5, 400, 400, 'potbelly.com', ARRAY['potbelly farm salad'], '758 cal per 400g salad. {"sodium_mg":390,"cholesterol_mg":32.5,"sat_fat_g":3.5,"trans_fat_g":0}'),
('potbelly_occ_cookie', 'Potbelly Oatmeal Chocolate Chip Cookie', 525.0, 6.3, 77.5, 22.5, 2.5, 42.5, 80, 80, 'potbelly.com', ARRAY['potbelly cookie', 'potbelly occ cookie'], '420 cal per 80g cookie. {"sodium_mg":450,"cholesterol_mg":37.5,"sat_fat_g":12.5,"trans_fat_g":0}'),
('potbelly_chocolate_shake', 'Potbelly Chocolate Shake', 120.5, 3.0, 18.0, 4.5, 0.3, 15.0, 400, 400, 'potbelly.com', ARRAY['potbelly chocolate milkshake'], '482 cal per regular shake (400ml). {"sodium_mg":62.5,"cholesterol_mg":16.3,"sat_fat_g":2.75,"trans_fat_g":0.13}'),
('baja_fresh_chicken_burrito', 'Baja Fresh Chicken Baja Burrito', 200.0, 10.8, 14.5, 9.3, 1.5, 1.3, 400, 400, 'bajafresh.com', ARRAY['baja fresh chicken burrito', 'baja burrito chicken'], '800 cal per burrito (400g). {"sodium_mg":410,"cholesterol_mg":22.5,"sat_fat_g":3.5,"trans_fat_g":0}'),
('baja_fresh_steak_burrito', 'Baja Fresh Steak Baja Burrito', 197.5, 9.5, 14.5, 9.0, 1.5, 1.3, 400, 400, 'bajafresh.com', ARRAY['baja fresh steak burrito'], '790 cal per burrito (400g). {"sodium_mg":395,"cholesterol_mg":20,"sat_fat_g":3.25,"trans_fat_g":0}'),
('baja_fresh_burrito_mexicano', 'Baja Fresh Burrito Mexicano', 140.0, 2.9, 20.3, 5.4, 0.6, 1.1, 350, 350, 'bajafresh.com', ARRAY['baja fresh mexicano'], '490 cal per burrito (350g). {"sodium_mg":342.9,"cholesterol_mg":5.7,"sat_fat_g":1.71,"trans_fat_g":0}'),
('baja_fresh_burrito_ultimo', 'Baja Fresh Burrito Ultimo', 202.5, 6.3, 20.5, 10.5, 1.0, 2.0, 400, 400, 'bajafresh.com', ARRAY['baja fresh ultimo burrito'], '810 cal per burrito (400g). {"sodium_mg":445,"cholesterol_mg":25,"sat_fat_g":4.5,"trans_fat_g":0}'),
('baja_fresh_fish_taco', 'Baja Fresh Baja Fish Taco', 263.6, 9.1, 21.8, 16.4, 0.9, 1.8, 110, 110, 'bajafresh.com', ARRAY['baja fresh fish taco'], '290 cal per taco (110g). {"sodium_mg":345.5,"cholesterol_mg":22.7,"sat_fat_g":3.64,"trans_fat_g":0}'),
('baja_fresh_americano_taco', 'Baja Fresh Americano Taco', 225.0, 7.5, 26.3, 10.0, 1.3, 1.3, 80, 80, 'bajafresh.com', ARRAY['baja fresh hard taco'], '180 cal per taco (80g). {"sodium_mg":250,"cholesterol_mg":25,"sat_fat_g":3.75,"trans_fat_g":0}'),
('baja_fresh_shrimp_taco', 'Baja Fresh Grilled Shrimp Taco', 180.0, 10.0, 21.0, 7.0, 2.0, 3.0, 100, 100, 'bajafresh.com', ARRAY['baja fresh shrimp taco'], '180 cal per taco (100g). {"sodium_mg":360,"cholesterol_mg":50,"sat_fat_g":1.5,"trans_fat_g":0}'),
('baja_fresh_chicken_bowl', 'Baja Fresh Chicken Baja Bowl', 122.5, 6.8, 16.3, 3.0, 1.3, 2.3, 400, 400, 'bajafresh.com', ARRAY['baja fresh chicken bowl', 'baja bowl chicken'], '490 cal per bowl (400g). {"sodium_mg":300,"cholesterol_mg":13.8,"sat_fat_g":1.0,"trans_fat_g":0}'),
('baja_fresh_nachos', 'Baja Fresh Nachos', 286.0, 9.2, 22.6, 17.4, 5.0, 0.6, 500, 500, 'bajafresh.com', ARRAY['baja fresh cheese nachos'], '1430 cal per full nachos (500g). {"sodium_mg":480,"cholesterol_mg":24,"sat_fat_g":7.6,"trans_fat_g":0}'),
('baja_fresh_chicken_quesadilla', 'Baja Fresh Chicken Quesadilla', 288.6, 11.4, 15.4, 19.4, 1.1, 0.9, 350, 350, 'bajafresh.com', ARRAY['baja fresh quesadilla'], '1010 cal per quesadilla (350g). {"sodium_mg":628.6,"cholesterol_mg":45.7,"sat_fat_g":8.57,"trans_fat_g":0}'),
('baja_fresh_tostada_salad', 'Baja Fresh Tostada Salad', 180.0, 4.5, 16.3, 11.0, 2.3, 1.8, 400, 400, 'bajafresh.com', ARRAY['baja fresh tostada'], '720 cal per tostada salad (400g). {"sodium_mg":320,"cholesterol_mg":15,"sat_fat_g":4.0,"trans_fat_g":0}'),
('baja_fresh_guacamole', 'Baja Fresh Guacamole', 260.0, 3.3, 16.0, 22.7, 10.7, 2.0, 150, 150, 'bajafresh.com', ARRAY['baja fresh guac'], '390 cal per side (150g). {"sodium_mg":393.3,"cholesterol_mg":0,"sat_fat_g":3.33,"trans_fat_g":0}'),
('baja_fresh_chicken_tortilla_soup', 'Baja Fresh Chicken Tortilla Soup', 116.7, 5.4, 10.4, 5.4, 1.3, 2.1, 240, 240, 'bajafresh.com', ARRAY['baja fresh tortilla soup'], '280 cal per cup (240g). {"sodium_mg":400,"cholesterol_mg":14.6,"sat_fat_g":2.08,"trans_fat_g":0}'),
('baja_fresh_breakfast_burrito', 'Baja Fresh Breakfast Burrito', 202.5, 9.3, 17.8, 10.5, 0.8, 0.5, 400, 400, 'bajafresh.com', ARRAY['baja fresh egg burrito'], '810 cal per burrito (400g). {"sodium_mg":405,"cholesterol_mg":112.5,"sat_fat_g":4.0,"trans_fat_g":0}'),
('baja_fresh_churro', 'Baja Fresh Churro', 300.0, 2.9, 21.4, 22.9, 0.0, 5.7, 70, 70, 'bajafresh.com', ARRAY['baja fresh cinnamon churro'], '210 cal per churro (70g). {"sodium_mg":171.4,"cholesterol_mg":7.1,"sat_fat_g":2.86,"trans_fat_g":0}'),
('benihana_hibachi_chicken', 'Benihana Hibachi Chicken', 116.7, 19.2, 1.3, 4.2, 0.0, 0.4, 240, 240, 'benihana.com', ARRAY['benihana chicken hibachi', 'benihana grilled chicken'], '280 cal per 240g serving. {"sodium_mg":275,"cholesterol_mg":54.2,"sat_fat_g":1.25,"trans_fat_g":0}'),
('benihana_hibachi_steak', 'Benihana Hibachi Steak', 115.0, 15.0, 0.0, 6.0, 0.0, 0.0, 200, 200, 'benihana.com', ARRAY['benihana steak hibachi', 'benihana ny strip'], '230 cal per 200g serving. {"sodium_mg":260,"cholesterol_mg":45,"sat_fat_g":2.5,"trans_fat_g":0}'),
('benihana_hibachi_shrimp', 'Benihana Hibachi Shrimp', 100.0, 18.0, 1.5, 2.5, 0.0, 0.0, 200, 200, 'benihana.com', ARRAY['benihana shrimp hibachi'], '200 cal per 200g serving (14 shrimp). {"sodium_mg":390,"cholesterol_mg":140,"sat_fat_g":0.5,"trans_fat_g":0}'),
('benihana_filet_mignon', 'Benihana Filet Mignon', 125.0, 17.5, 0.0, 6.0, 0.0, 0.0, 200, 200, 'benihana.com', ARRAY['benihana filet', 'benihana tenderloin'], '250 cal per 200g serving. {"sodium_mg":230,"cholesterol_mg":40,"sat_fat_g":2.5,"trans_fat_g":0}'),
('benihana_teriyaki_chicken', 'Benihana Teriyaki Chicken', 132.1, 16.1, 6.1, 3.9, 0.0, 4.3, 280, 280, 'benihana.com', ARRAY['benihana chicken teriyaki'], '370 cal per 280g serving. {"sodium_mg":428.6,"cholesterol_mg":46.4,"sat_fat_g":1.07,"trans_fat_g":0}'),
('benihana_spicy_hibachi_chicken', 'Benihana Spicy Hibachi Chicken', 138.5, 18.5, 3.8, 4.6, 0.4, 2.3, 260, 260, 'benihana.com', ARRAY['benihana spicy chicken'], '360 cal per 260g serving. {"sodium_mg":376.9,"cholesterol_mg":50,"sat_fat_g":1.15,"trans_fat_g":0}'),
('benihana_fried_rice', 'Benihana Fried Rice', 114.3, 3.8, 11.9, 5.7, 0.5, 0.5, 210, 210, 'benihana.com', ARRAY['benihana hibachi fried rice'], '240 cal per 3/4 cup (210g). {"sodium_mg":276.2,"cholesterol_mg":28.6,"sat_fat_g":0.95,"trans_fat_g":0}'),
('benihana_miso_soup', 'Benihana Miso Soup', 16.4, 1.1, 2.2, 0.5, 0.5, 0.5, 183, 183, 'benihana.com', ARRAY['benihana miso'], '30 cal per 183g bowl. {"sodium_mg":366.1,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),
('benihana_house_salad', 'Benihana House Salad', 83.3, 1.9, 2.8, 7.4, 0.9, 0.9, 108, 108, 'benihana.com', ARRAY['benihana ginger dressing salad', 'benihana salad'], '90 cal per 108g salad. {"sodium_mg":259.3,"cholesterol_mg":0,"sat_fat_g":0.93,"trans_fat_g":0}'),
('benihana_california_roll', 'Benihana California Roll (4 pcs)', 175.0, 3.3, 20.8, 8.3, 0.8, 2.5, 120, 120, 'benihana.com', ARRAY['benihana cali roll'], '210 cal per 4-piece roll (120g). {"sodium_mg":316.7,"cholesterol_mg":12.5,"sat_fat_g":1.67,"trans_fat_g":0}'),
('benihana_spicy_tuna_roll', 'Benihana Spicy Tuna Roll', 173.3, 9.3, 20.0, 6.0, 0.7, 2.7, 150, 150, 'benihana.com', ARRAY['benihana spicy tuna sushi'], '260 cal per roll (150g). {"sodium_mg":293.3,"cholesterol_mg":20,"sat_fat_g":1.33,"trans_fat_g":0}'),
('benihana_edamame', 'Benihana Edamame', 80.0, 8.7, 5.3, 3.3, 2.7, 1.3, 150, 150, 'benihana.com', ARRAY['benihana soybeans'], '120 cal per 150g serving. {"sodium_mg":193.3,"cholesterol_mg":0,"sat_fat_g":0.33,"trans_fat_g":0}'),
('benihana_green_tea_ice_cream', 'Benihana Green Tea Ice Cream', 112.5, 3.1, 18.8, 3.1, 0.0, 15.0, 80, 80, 'benihana.com', ARRAY['benihana matcha ice cream'], '90 cal per 80g scoop. {"sodium_mg":43.8,"cholesterol_mg":18.8,"sat_fat_g":1.88,"trans_fat_g":0}'),
('benihana_banana_tempura', 'Benihana Banana Tempura', 227.8, 3.3, 30.6, 7.8, 1.1, 15.6, 180, 180, 'benihana.com', ARRAY['benihana fried banana dessert'], '410 cal per 180g serving. {"sodium_mg":105.6,"cholesterol_mg":11.1,"sat_fat_g":1.67,"trans_fat_g":0}'),
('village_inn_buttermilk_pancakes', 'Village Inn Buttermilk Pancakes (3)', 213.3, 5.3, 36.0, 3.6, 0.9, 8.0, 225, 225, 'villageinn.com', ARRAY['village inn pancakes', 'vi pancake stack'], '480 cal per 3-pancake stack (225g). {"sodium_mg":395.6,"cholesterol_mg":22.2,"sat_fat_g":1.33,"trans_fat_g":0}'),
('village_inn_belgian_waffle', 'Village Inn Belgian Waffle', 238.9, 4.4, 27.2, 11.7, 1.1, 4.4, 180, 180, 'villageinn.com', ARRAY['village inn waffle'], '430 cal per 180g waffle. {"sodium_mg":322.2,"cholesterol_mg":66.7,"sat_fat_g":4.44,"trans_fat_g":0}'),
('village_inn_two_eggs', 'Village Inn 2 Eggs Any Style', 157.1, 9.3, 0.7, 12.9, 0.0, 0.0, 140, 140, 'villageinn.com', ARRAY['village inn eggs', 'vi eggs any style'], '220 cal per 140g (2 eggs). {"sodium_mg":128.6,"cholesterol_mg":264.3,"sat_fat_g":3.57,"trans_fat_g":0}'),
('village_inn_ham_cheese_omelet', 'Village Inn Ham & Cheese Omelet', 232.1, 16.1, 4.3, 16.1, 0.4, 1.1, 280, 280, 'villageinn.com', ARRAY['village inn omelette', 'vi ham cheese omelet'], '650 cal per 280g omelet. {"sodium_mg":492.9,"cholesterol_mg":221.4,"sat_fat_g":5.71,"trans_fat_g":0}'),
('village_inn_cheeseburger', 'Village Inn All-American Cheeseburger', 308.7, 12.2, 20.9, 18.7, 0.9, 3.9, 230, 230, 'villageinn.com', ARRAY['village inn burger', 'vi cheeseburger'], '710 cal per 230g burger. {"sodium_mg":460.9,"cholesterol_mg":52.2,"sat_fat_g":6.96,"trans_fat_g":0.65}'),
('village_inn_chef_salad', 'Village Inn Celebrity Chef Salad', 125.7, 11.4, 6.9, 6.3, 0.9, 2.0, 350, 350, 'villageinn.com', ARRAY['village inn chef salad'], '440 cal per 350g salad. {"sodium_mg":342.9,"cholesterol_mg":45.7,"sat_fat_g":2.29,"trans_fat_g":0}'),
('village_inn_cobb_salad', 'Village Inn Classy Cobb Salad', 142.9, 10.0, 3.7, 10.0, 1.7, 1.4, 350, 350, 'villageinn.com', ARRAY['village inn cobb salad'], '500 cal per 350g salad. {"sodium_mg":314.3,"cholesterol_mg":57.1,"sat_fat_g":3.43,"trans_fat_g":0}'),
('village_inn_grilled_chicken', 'Village Inn Grilled Chicken Breast', 117.6, 21.2, 0.0, 3.5, 0.0, 0.0, 170, 170, 'villageinn.com', ARRAY['vi chicken breast dinner'], '200 cal per 170g breast. {"sodium_mg":282.4,"cholesterol_mg":52.9,"sat_fat_g":0.88,"trans_fat_g":0}'),
('village_inn_fish_and_chips', 'Village Inn Fish & Chips', 228.6, 7.1, 20.0, 12.9, 1.1, 0.6, 350, 350, 'villageinn.com', ARRAY['vi fish n chips'], '800 cal per 350g serving. {"sodium_mg":514.3,"cholesterol_mg":24.3,"sat_fat_g":2.29,"trans_fat_g":0}'),
('village_inn_tbone_steak', 'Village Inn 1 Lb T-Bone Steak', 288.5, 21.4, 4.6, 21.4, 0.0, 0.0, 454, 454, 'villageinn.com', ARRAY['village inn t-bone', 'vi t bone steak'], '1310 cal per 454g (1 lb) steak. {"sodium_mg":264.3,"cholesterol_mg":61.7,"sat_fat_g":8.37,"trans_fat_g":0.44}'),
('village_inn_banana_cream_pie', 'Village Inn Banana Cream Pie', 311.1, 3.3, 32.2, 17.8, 1.7, 18.9, 180, 180, 'villageinn.com', ARRAY['vi banana pie', 'village inn banana cream pie slice'], '560 cal per 180g slice. {"sodium_mg":155.6,"cholesterol_mg":36.1,"sat_fat_g":10.0,"trans_fat_g":0}'),
('village_inn_french_silk_pie', 'Village Inn French Silk Pie', 355.6, 3.3, 38.9, 22.2, 1.1, 27.8, 180, 180, 'villageinn.com', ARRAY['vi chocolate silk pie', 'village inn silk pie'], '640 cal per 180g slice. {"sodium_mg":166.7,"cholesterol_mg":44.4,"sat_fat_g":13.33,"trans_fat_g":0}'),
('village_inn_pecan_pie', 'Village Inn Pecan Pie', 372.2, 3.9, 47.2, 18.3, 1.7, 37.8, 180, 180, 'villageinn.com', ARRAY['vi pecan pie slice'], '670 cal per 180g slice. {"sodium_mg":194.4,"cholesterol_mg":38.9,"sat_fat_g":4.44,"trans_fat_g":0}'),
('village_inn_apple_pie', 'Village Inn Apple Pie', 227.8, 1.7, 35.0, 10.0, 1.1, 18.3, 180, 180, 'villageinn.com', ARRAY['vi apple pie slice'], '410 cal per 180g slice. {"sodium_mg":183.3,"cholesterol_mg":0,"sat_fat_g":3.89,"trans_fat_g":0}'),
('village_inn_cherry_pie', 'Village Inn Cherry Pie', 238.9, 1.7, 36.7, 10.6, 0.6, 22.2, 180, 180, 'villageinn.com', ARRAY['vi cherry pie slice'], '430 cal per 180g slice. {"sodium_mg":188.9,"cholesterol_mg":0,"sat_fat_g":4.44,"trans_fat_g":0}'),
('village_inn_mashed_potatoes', 'Village Inn Mashed Potatoes', 100.0, 2.0, 14.7, 4.7, 0.7, 0.7, 150, 150, 'villageinn.com', ARRAY['vi mashed potatoes'], '150 cal per 150g serving. {"sodium_mg":280,"cholesterol_mg":6.7,"sat_fat_g":2.0,"trans_fat_g":0}'),
('village_inn_chicken_noodle_soup', 'Village Inn Chicken Noodle Soup', 50.0, 3.3, 5.0, 1.3, 0.4, 0.4, 240, 240, 'villageinn.com', ARRAY['vi chicken soup'], '120 cal per cup (240g). {"sodium_mg":366.7,"cholesterol_mg":10.4,"sat_fat_g":0.42,"trans_fat_g":0}'),
('fazolis_spaghetti_marinara', 'Fazoli''s Spaghetti with Marinara', 127.5, 4.3, 25.5, 2.3, 1.8, 3.0, 400, 400, 'fazolis.com', ARRAY['fazolis spaghetti', 'fazolis pasta marinara'], '510 cal per regular (400g). {"sodium_mg":235,"cholesterol_mg":0,"sat_fat_g":0.38,"trans_fat_g":0}'),
('fazolis_spaghetti_meat_sauce', 'Fazoli''s Spaghetti with Meat Sauce', 152.5, 5.5, 27.3, 3.5, 1.8, 3.3, 400, 400, 'fazolis.com', ARRAY['fazolis meat sauce spaghetti'], '610 cal per regular (400g). {"sodium_mg":320,"cholesterol_mg":6.3,"sat_fat_g":1.0,"trans_fat_g":0}'),
('fazolis_spaghetti_meatballs', 'Fazoli''s Spaghetti with Meatballs', 164.4, 6.2, 24.9, 4.9, 1.8, 3.1, 450, 450, 'fazolis.com', ARRAY['fazolis spaghetti and meatballs'], '740 cal per regular (450g). {"sodium_mg":375.6,"cholesterol_mg":12.2,"sat_fat_g":1.56,"trans_fat_g":0}'),
('fazolis_fettuccine_alfredo', 'Fazoli''s Fettuccine Alfredo', 172.5, 4.0, 25.5, 6.5, 1.0, 1.8, 400, 400, 'fazolis.com', ARRAY['fazolis alfredo pasta'], '690 cal per regular (400g). {"sodium_mg":285,"cholesterol_mg":11.3,"sat_fat_g":3.0,"trans_fat_g":0}'),
('fazolis_chicken_alfredo', 'Fazoli''s Chicken Fettuccine Alfredo', 193.3, 8.4, 22.2, 7.3, 1.1, 1.8, 450, 450, 'fazolis.com', ARRAY['fazolis chicken alfredo'], '870 cal per regular (450g). {"sodium_mg":342.2,"cholesterol_mg":20,"sat_fat_g":3.11,"trans_fat_g":0}'),
('fazolis_baked_lasagna', 'Fazoli''s Baked Lasagna', 180.0, 10.0, 18.6, 7.4, 1.4, 2.9, 350, 350, 'fazolis.com', ARRAY['fazolis lasagna'], '630 cal per 350g serving. {"sodium_mg":434.3,"cholesterol_mg":20,"sat_fat_g":2.86,"trans_fat_g":0}'),
('fazolis_baked_spaghetti', 'Fazoli''s Baked Spaghetti', 165.7, 8.0, 20.9, 5.1, 1.4, 2.6, 350, 350, 'fazolis.com', ARRAY['fazolis baked pasta'], '580 cal per 350g serving. {"sodium_mg":422.9,"cholesterol_mg":14.3,"sat_fat_g":2.0,"trans_fat_g":0}'),
('fazolis_chicken_parmigiano', 'Fazoli''s Chicken Parmigiano', 210.0, 10.5, 24.5, 7.5, 1.8, 3.5, 400, 400, 'fazolis.com', ARRAY['fazolis chicken parm', 'fazolis chicken parmesan'], '840 cal per 400g serving. {"sodium_mg":525,"cholesterol_mg":20,"sat_fat_g":2.5,"trans_fat_g":0}'),
('fazolis_ravioli_marinara', 'Fazoli''s Ravioli with Marinara', 137.1, 7.1, 16.3, 4.9, 1.4, 2.9, 350, 350, 'fazolis.com', ARRAY['fazolis cheese ravioli'], '480 cal per 350g serving. {"sodium_mg":325.7,"cholesterol_mg":15.7,"sat_fat_g":2.29,"trans_fat_g":0}'),
('fazolis_cheese_pizza', 'Fazoli''s Cheese Pizza (Double Slice)', 254.5, 12.7, 29.1, 10.9, 1.4, 2.3, 220, 220, 'fazolis.com', ARRAY['fazolis cheese pizza slice'], '560 cal per double slice (220g). {"sodium_mg":627.3,"cholesterol_mg":25,"sat_fat_g":4.09,"trans_fat_g":0}'),
('fazolis_pepperoni_pizza', 'Fazoli''s Pepperoni Pizza (Double Slice)', 268.2, 12.7, 29.1, 12.7, 1.4, 2.3, 220, 220, 'fazolis.com', ARRAY['fazolis pepperoni pizza slice'], '590 cal per double slice (220g). {"sodium_mg":718.2,"cholesterol_mg":29.5,"sat_fat_g":5.0,"trans_fat_g":0}'),
('fazolis_meatball_sub', 'Fazoli''s Meatball Da Vinci Sub', 306.7, 16.0, 25.0, 16.0, 1.7, 3.0, 300, 300, 'fazolis.com', ARRAY['fazolis meatball sub sandwich'], '920 cal per sub (300g). {"sodium_mg":766.7,"cholesterol_mg":33.3,"sat_fat_g":6.0,"trans_fat_g":0.17}'),
('fazolis_turkey_club_sub', 'Fazoli''s Turkey Club Classico Sub', 282.1, 15.0, 24.3, 13.2, 1.1, 3.2, 280, 280, 'fazolis.com', ARRAY['fazolis turkey sub', 'fazolis turkey club'], '790 cal per sub (280g). {"sodium_mg":778.6,"cholesterol_mg":32.1,"sat_fat_g":4.29,"trans_fat_g":0}'),
('fazolis_breadstick', 'Fazoli''s Breadstick', 200.0, 5.0, 40.0, 2.5, 0.0, 2.5, 40, 40, 'fazolis.com', ARRAY['fazolis plain breadstick'], '80 cal per 40g breadstick. {"sodium_mg":325,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),
('fazolis_garlic_breadstick', 'Fazoli''s Garlic Breadstick', 288.9, 6.7, 40.0, 11.1, 0.0, 2.2, 45, 45, 'fazolis.com', ARRAY['fazolis signature garlic breadstick'], '130 cal per garlic breadstick (45g). {"sodium_mg":555.6,"cholesterol_mg":0,"sat_fat_g":2.22,"trans_fat_g":0}'),
('fazolis_caesar_salad', 'Fazoli''s Caesar Side Salad', 53.3, 3.3, 5.3, 2.7, 0.7, 0.7, 150, 150, 'fazolis.com', ARRAY['fazolis caesar salad'], '80 cal per 150g side salad. {"sodium_mg":120,"cholesterol_mg":3.3,"sat_fat_g":1.33,"trans_fat_g":0}'),
('fazolis_chicken_bacon_caesar', 'Fazoli''s Chicken Bacon Caesar Salad', 185.0, 10.0, 7.0, 13.0, 1.3, 1.5, 400, 400, 'fazolis.com', ARRAY['fazolis chicken caesar'], '740 cal per 400g salad. {"sodium_mg":420,"cholesterol_mg":32.5,"sat_fat_g":4.0,"trans_fat_g":0}'),
('fazolis_brownie', 'Fazoli''s Brownie', 360.0, 5.0, 52.0, 16.0, 0.0, 35.0, 100, 100, 'fazolis.com', ARRAY['fazolis chocolate brownie'], '360 cal per 100g brownie. {"sodium_mg":190,"cholesterol_mg":35,"sat_fat_g":5.0,"trans_fat_g":0}'),
('fazolis_cheesecake', 'Fazoli''s NY Style Cheesecake', 318.8, 4.4, 34.4, 18.1, 0.6, 26.3, 160, 160, 'fazolis.com', ARRAY['fazolis cheesecake', 'fazolis new york cheesecake'], '510 cal per 160g slice with strawberry. {"sodium_mg":225,"cholesterol_mg":68.8,"sat_fat_g":10.0,"trans_fat_g":0}'),
('fazolis_lemon_ice', 'Fazoli''s Original Italian Lemon Ice', 95.0, 0.0, 24.0, 0.0, 0.0, 22.5, 200, 200, 'fazolis.com', ARRAY['fazolis italian ice', 'fazolis lemon ice dessert'], '190 cal per regular (200g). {"sodium_mg":5,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}')


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
