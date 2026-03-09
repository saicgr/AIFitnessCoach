-- 1638_overrides_subway_expansion.sql
-- Subway menu expansion: additional 6" subs, footlongs, wraps, and cookies.
-- Sources: subway.com nutrition calculator, fastfoodnutrition.org, fatsecret.com,
--          nutritionix.com, eatthismuch.com, calorieking.com.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = label serving.
-- Note: All subs are on Italian bread with standard veggies (lettuce, tomato, cucumber,
--       green pepper, red onion) unless otherwise noted. No cheese, no sauce unless specified.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SUBWAY — 6" SUBS
-- ══════════════════════════════════════════

-- Subway 6" Chicken Teriyaki: 270 cal per sub (~270g)
-- FatSecret: 270 cal, 3.5g fat, 40g carb, 20g protein, 3g fiber, 8g sugar
-- Per 100g: 270/270*100 = 100 cal
('subway_chicken_teriyaki_6', 'Subway Chicken Teriyaki 6" Sub', 100, 7.4, 14.8, 1.3,
 1.1, 3.0, NULL, 270,
 'website', ARRAY['subway chicken teriyaki 6', 'subway chicken teriyaki 6 inch', 'subway teriyaki chicken sub', 'subway chicken teriyaki sub'],
 'sandwich', 'Subway', 1, '270 cal per 6" sub (~270g). Teriyaki-glazed chicken strips on Italian bread with standard veggies. Low fat.', TRUE),

-- Subway 6" Rotisserie Chicken: 300 cal per sub (~240g)
-- fastfoodnutrition.org/FatSecret: 300 cal, 6g fat, 39g carb, 22g protein, 3g fiber, 5g sugar
-- Per 100g: 300/240*100 = 125 cal
('subway_rotisserie_chicken_6', 'Subway Rotisserie-Style Chicken 6" Sub', 125, 9.2, 16.3, 2.5,
 1.3, 2.1, NULL, 240,
 'website', ARRAY['subway rotisserie chicken 6', 'subway rotisserie chicken 6 inch', 'subway rotisserie style chicken sub', 'subway rotisserie chicken'],
 'sandwich', 'Subway', 1, '300 cal per 6" sub (~240g). Slow-cooked rotisserie-style chicken on Italian bread. Good protein-to-calorie ratio.', TRUE),

-- Subway 6" Spicy Italian: 430 cal per sub (~230g)
-- fastfoodnutrition.org: 430 cal, 24g fat, 39g carb, 20g protein, 3g fiber, 5g sugar
-- Per 100g: 430/230*100 = 187 cal
('subway_spicy_italian_6', 'Subway Spicy Italian 6" Sub', 187, 8.7, 17.0, 10.4,
 1.3, 2.2, NULL, 230,
 'website', ARRAY['subway spicy italian 6', 'subway spicy italian 6 inch', 'subway spicy italian sub', 'subway spicy italian'],
 'sandwich', 'Subway', 1, '430 cal per 6" sub (~230g). Pepperoni and Genoa salami on Italian bread. Higher fat due to cured meats.', TRUE),

-- Subway 6" Meatball Marinara: 410 cal per sub (~295g)
-- fastfoodnutrition.org: 410 cal, 18g fat, 48g carb, 19g protein, 5g fiber, 9g sugar
-- FatSecret serving weight: 295g (some sources say 211g for bread-only; 295g with full toppings)
-- Per 100g: 410/295*100 = 139 cal
('subway_meatball_marinara_6', 'Subway Meatball Marinara 6" Sub', 139, 6.4, 16.3, 6.1,
 1.7, 3.1, NULL, 295,
 'website', ARRAY['subway meatball marinara 6', 'subway meatball marinara 6 inch', 'subway meatball sub', 'subway meatball marinara'],
 'sandwich', 'Subway', 1, '410 cal per 6" sub (~295g). Italian-style meatballs in marinara sauce on Italian bread. Hearty, saucy option.', TRUE),

-- Subway 6" Tuna: 430 cal per sub (~252g)
-- fastfoodnutrition.org: 430 cal, 25g fat, 37g carb, 19g protein, 3g fiber, 5g sugar
-- Per 100g: 430/252*100 = 171 cal
('subway_tuna_6', 'Subway Tuna 6" Sub', 171, 7.5, 14.7, 9.9,
 1.2, 2.0, NULL, 252,
 'website', ARRAY['subway tuna 6', 'subway tuna 6 inch', 'subway tuna sub', 'subway tuna sandwich'],
 'sandwich', 'Subway', 1, '430 cal per 6" sub (~252g). Tuna salad (tuna mixed with mayo) on Italian bread. Higher fat from mayo.', TRUE),

-- Subway 6" Veggie Delite: 200 cal per sub (~171g)
-- fastfoodnutrition.org: 200 cal, 2g fat, 39g carb, 7g protein, 3g fiber, 5g sugar
-- Per 100g: 200/171*100 = 117 cal
('subway_veggie_delite_6', 'Subway Veggie Delite 6" Sub', 117, 4.1, 22.8, 1.2,
 1.8, 2.9, NULL, 171,
 'website', ARRAY['subway veggie delite 6', 'subway veggie delite 6 inch', 'subway veggie sub', 'subway veggie delite', 'subway vegetarian sub'],
 'sandwich', 'Subway', 1, '200 cal per 6" sub (~171g). All-veggie sub: lettuce, tomato, cucumber, green pepper, red onion on Italian bread. Lowest calorie sub.', TRUE),

-- Subway 6" Cold Cut Combo: 280 cal per sub (~236g)
-- fastfoodnutrition.org: 280 cal, 10g fat, 38g carb, 13g protein, 3g fiber, 5g sugar
-- Per 100g: 280/236*100 = 119 cal
('subway_cold_cut_combo_6', 'Subway Cold Cut Combo 6" Sub', 119, 5.5, 16.1, 4.2,
 1.3, 2.1, NULL, 236,
 'website', ARRAY['subway cold cut combo 6', 'subway cold cut combo 6 inch', 'subway cold cut combo', 'subway cold cut sub'],
 'sandwich', 'Subway', 1, '280 cal per 6" sub (~236g). Turkey-based bologna, salami, and ham on Italian bread. Budget-friendly option.', TRUE),

-- Subway 6" Chicken & Bacon Ranch: 530 cal per sub (~270g)
-- fastfoodnutrition.org: 530 cal, 26g fat, 41g carb, 36g protein, 3g fiber, 5g sugar
-- Per 100g: 530/270*100 = 196 cal
('subway_chicken_bacon_ranch_6', 'Subway Chicken & Bacon Ranch 6" Sub', 196, 13.3, 15.2, 9.6,
 1.1, 1.9, NULL, 270,
 'website', ARRAY['subway chicken bacon ranch 6', 'subway chicken bacon ranch 6 inch', 'subway chicken bacon ranch', 'subway cbr sub', 'subway chicken bacon ranch melt'],
 'sandwich', 'Subway', 1, '530 cal per 6" sub (~270g). Rotisserie chicken, bacon, and ranch on Italian bread. Higher calorie, high protein.', TRUE),

-- Subway 6" Sweet Onion Chicken Teriyaki: 340 cal per sub (~262g)
-- FatSecret: 340 cal, 4g fat, 54g carb, 25g protein, 4g fiber, 14g sugar
-- Per 100g: 340/262*100 = 130 cal
('subway_sweet_onion_chicken_teriyaki_6', 'Subway Sweet Onion Chicken Teriyaki 6" Sub', 130, 9.5, 20.6, 1.5,
 1.5, 5.3, NULL, 262,
 'website', ARRAY['subway sweet onion chicken teriyaki 6', 'subway sweet onion teriyaki 6 inch', 'subway sweet onion chicken teriyaki', 'subway soct'],
 'sandwich', 'Subway', 1, '340 cal per 6" sub (~262g). Teriyaki chicken with sweet onion sauce. Low fat but higher sugar from sweet onion glaze.', TRUE),

-- Subway 6" Black Forest Ham: 270 cal per sub (~225g)
-- fastfoodnutrition.org: 270 cal, 4g fat, 41g carb, 18g protein, 3g fiber, 6g sugar
-- Per 100g: 270/225*100 = 120 cal
('subway_black_forest_ham_6', 'Subway Black Forest Ham 6" Sub', 120, 8.0, 18.2, 1.8,
 1.3, 2.7, NULL, 225,
 'website', ARRAY['subway black forest ham 6', 'subway black forest ham 6 inch', 'subway black forest ham', 'subway ham sub', 'subway ham sandwich'],
 'sandwich', 'Subway', 1, '270 cal per 6" sub (~225g). Black Forest ham on Italian bread. Lean deli meat, low fat option.', TRUE),

-- Subway 6" Roast Beef: 300 cal per sub (~223g)
-- fastfoodnutrition.org/EatThisMuch: 300 cal, 5g fat, 41g carb, 22g protein, 3g fiber, 5g sugar
-- Per 100g: 300/223*100 = 135 cal
('subway_roast_beef_6', 'Subway Roast Beef 6" Sub', 135, 9.9, 18.4, 2.2,
 1.3, 2.2, NULL, 223,
 'website', ARRAY['subway roast beef 6', 'subway roast beef 6 inch', 'subway roast beef sub', 'subway roast beef sandwich'],
 'sandwich', 'Subway', 1, '300 cal per 6" sub (~223g). Sliced roast beef on Italian bread. Good protein, low fat.', TRUE),

-- ══════════════════════════════════════════
-- SUBWAY — FOOTLONGS
-- ══════════════════════════════════════════

-- Subway Turkey Breast Footlong: 540 cal per sub (~450g)
-- Subway nutrition (2x 6"): 2 x 270 = 540 cal. 6g fat, 82g carb, 36g protein, 6g fiber, 10g sugar
-- Per 100g: 540/450*100 = 120 cal
('subway_turkey_breast_footlong', 'Subway Turkey Breast Footlong', 120, 8.0, 18.2, 1.3,
 1.3, 2.2, NULL, 450,
 'website', ARRAY['subway turkey breast footlong', 'subway turkey footlong', 'subway turkey 12 inch', 'subway footlong turkey'],
 'sandwich', 'Subway', 1, '540 cal per footlong (~450g). Oven-roasted turkey breast on Italian bread. Lean, high protein. One of the lowest calorie footlongs.', TRUE),

-- Subway Chicken Teriyaki Footlong: 540 cal per sub (~540g)
-- 2x 6" Chicken Teriyaki: 2 x 270 = 540 cal. 7g fat, 80g carb, 40g protein, 6g fiber, 16g sugar
-- Per 100g: 540/540*100 = 100 cal
('subway_chicken_teriyaki_footlong', 'Subway Chicken Teriyaki Footlong', 100, 7.4, 14.8, 1.3,
 1.1, 3.0, NULL, 540,
 'website', ARRAY['subway chicken teriyaki footlong', 'subway teriyaki footlong', 'subway chicken teriyaki 12 inch', 'subway footlong teriyaki'],
 'sandwich', 'Subway', 1, '540 cal per footlong (~540g). Teriyaki-glazed chicken on Italian bread. Low fat, good protein footlong option.', TRUE),

-- Subway Italian BMT Footlong: 720 cal per sub (~438g)
-- fastfoodnutrition.org: 720 cal, 32g fat, 78g carb, 36g protein, 6g fiber, 10g sugar
-- Per 100g: 720/438*100 = 164 cal
('subway_italian_bmt_footlong', 'Subway Italian B.M.T. Footlong', 164, 8.2, 17.8, 7.3,
 1.4, 2.3, NULL, 438,
 'website', ARRAY['subway italian bmt footlong', 'subway bmt footlong', 'subway italian bmt 12 inch', 'subway footlong italian bmt', 'subway footlong bmt'],
 'sandwich', 'Subway', 1, '720 cal per footlong (~438g). Genoa salami, spicy pepperoni, Black Forest ham on Italian bread. Classic deli favorite.', TRUE),

-- Subway Spicy Italian Footlong: 860 cal per sub (~460g)
-- 2x 6" Spicy Italian: 2 x 430 = 860 cal. 48g fat, 78g carb, 40g protein, 6g fiber, 10g sugar
-- Per 100g: 860/460*100 = 187 cal
('subway_spicy_italian_footlong', 'Subway Spicy Italian Footlong', 187, 8.7, 17.0, 10.4,
 1.3, 2.2, NULL, 460,
 'website', ARRAY['subway spicy italian footlong', 'subway spicy italian 12 inch', 'subway footlong spicy italian'],
 'sandwich', 'Subway', 1, '860 cal per footlong (~460g). Double pepperoni and Genoa salami on Italian bread. Highest fat footlong option.', TRUE),

-- Subway Meatball Marinara Footlong: 820 cal per sub (~590g)
-- fastfoodnutrition.org: 820 cal, 36g fat, 96g carb, 38g protein, 10g fiber, 18g sugar
-- Per 100g: 820/590*100 = 139 cal
('subway_meatball_marinara_footlong', 'Subway Meatball Marinara Footlong', 139, 6.4, 16.3, 6.1,
 1.7, 3.1, NULL, 590,
 'website', ARRAY['subway meatball marinara footlong', 'subway meatball footlong', 'subway meatball marinara 12 inch', 'subway footlong meatball'],
 'sandwich', 'Subway', 1, '820 cal per footlong (~590g). Italian-style meatballs in marinara sauce. Hearty, filling footlong.', TRUE),

-- ══════════════════════════════════════════
-- SUBWAY — WRAPS
-- ══════════════════════════════════════════

-- Subway Turkey Wrap: 310 cal per wrap (~260g)
-- EatThisMuch/CarbManager: 310 cal. Macros: 49% carb, 30% fat, 21% protein
-- ~38g carb, 10g fat, 16g protein, 2g fiber, 3g sugar
-- Per 100g: 310/260*100 = 119 cal
('subway_turkey_wrap', 'Subway Turkey Wrap', 119, 6.2, 14.6, 3.8,
 0.8, 1.2, NULL, 260,
 'website', ARRAY['subway turkey wrap', 'subway turkey breast wrap', 'subway wrap turkey'],
 'wrap', 'Subway', 1, '310 cal per wrap (~260g). Oven-roasted turkey breast in a flour tortilla wrap with veggies. Lower carb than a sub.', TRUE),

-- Subway Chicken Caesar Wrap: 520 cal per wrap (~280g)
-- fastfoodnutrition.org/CalorieFriend: 520 cal. ~24g fat, 42g carb, 32g protein, 2g fiber, 3g sugar
-- Per 100g: 520/280*100 = 186 cal
('subway_chicken_caesar_wrap', 'Subway Chicken Caesar Wrap', 186, 11.4, 15.0, 8.6,
 0.7, 1.1, NULL, 280,
 'website', ARRAY['subway chicken caesar wrap', 'subway caesar wrap', 'subway rotisserie chicken caesar wrap', 'subway chicken wrap caesar'],
 'wrap', 'Subway', 1, '520 cal per wrap (~280g). Rotisserie-style chicken, romaine, parmesan, Caesar dressing in a flour tortilla. Higher cal than 6" subs.', TRUE),

-- ══════════════════════════════════════════
-- SUBWAY — COOKIES / SIDES
-- ══════════════════════════════════════════

-- Subway Chocolate Chip Cookie: 210 cal per cookie (~45g)
-- fastfoodnutrition.org/FatSecret: 210 cal, 10g fat, 30g carb, 2g protein, 1g fiber, 18g sugar
-- Per 100g: 210/45*100 = 467 cal
('subway_chocolate_chip_cookie', 'Subway Chocolate Chip Cookie', 467, 4.4, 66.7, 22.2,
 2.2, 40.0, NULL, 45,
 'website', ARRAY['subway chocolate chip cookie', 'subway cookie chocolate chip', 'subway cookie', 'subway choc chip cookie'],
 'cookie', 'Subway', 1, '210 cal per cookie (~45g). Classic chocolate chip cookie. High sugar, treat item.', TRUE),

-- Subway White Chip Macadamia Nut Cookie: 220 cal per cookie (~45g)
-- FatSecret/EatThisMuch: 220 cal, 11g fat, 29g carb, 2g protein, 1g fiber, 17g sugar
-- Per 100g: 220/45*100 = 489 cal
('subway_white_chip_macadamia_cookie', 'Subway White Chip Macadamia Nut Cookie', 489, 4.4, 64.4, 24.4,
 2.2, 37.8, NULL, 45,
 'website', ARRAY['subway white chip macadamia cookie', 'subway macadamia cookie', 'subway white chocolate macadamia cookie', 'subway white chip macadamia nut cookie'],
 'cookie', 'Subway', 1, '220 cal per cookie (~45g). White chocolate chips with macadamia nuts. Slightly higher cal than chocolate chip.', TRUE)

ON CONFLICT (food_name_normalized) DO UPDATE SET
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
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
