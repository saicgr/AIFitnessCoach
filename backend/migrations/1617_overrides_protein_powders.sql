-- 1617_overrides_protein_powders.sql
-- Popular protein powder brands with per-flavor entries.
-- Sources: Package nutrition labels via fatsecret.com, eatthismuch.com,
-- nutritionix.com, manufacturer websites, amazon.com.
-- All values per 100g. default_serving_g = scoop weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- OPTIMUM NUTRITION — GOLD STANDARD 100% WHEY
-- All flavors: ~120 cal, 24g P, 3g C, 1.5g F per 30.4g scoop
-- per 100g = (value / 30.4) * 100
-- ══════════════════════════════════════════

-- ON Gold Standard Whey Double Rich Chocolate: 120 cal / 30.4g scoop
('on_gold_standard_whey_chocolate', 'Optimum Nutrition Gold Standard Whey - Double Rich Chocolate', 395, 78.9, 9.9, 4.9,
 3.3, 3.3, 30.4, NULL,
 'manufacturer', ARRAY['on gold standard whey chocolate', 'optimum nutrition whey chocolate', 'gold standard whey double rich chocolate', 'on whey chocolate', 'optimum nutrition double rich chocolate'],
 'protein_powder', 'Optimum Nutrition', 1, '120 cal per scoop (30.4g). 24g protein, 3g carbs, 1.5g fat. 5.5g BCAAs per serving.', TRUE),

-- ON Gold Standard Whey Vanilla Ice Cream: 120 cal / 30.4g scoop
('on_gold_standard_whey_vanilla', 'Optimum Nutrition Gold Standard Whey - Vanilla Ice Cream', 395, 78.9, 9.9, 4.9,
 3.3, 3.3, 30.4, NULL,
 'manufacturer', ARRAY['on gold standard whey vanilla', 'optimum nutrition whey vanilla', 'gold standard whey vanilla ice cream', 'on whey vanilla', 'optimum nutrition vanilla ice cream whey'],
 'protein_powder', 'Optimum Nutrition', 1, '120 cal per scoop (30.4g). 24g protein, 3g carbs, 1.5g fat. 5.5g BCAAs per serving.', TRUE),

-- ON Gold Standard Whey Cookies & Cream: 120 cal / 30.4g scoop
('on_gold_standard_whey_cookies_cream', 'Optimum Nutrition Gold Standard Whey - Cookies & Cream', 395, 78.9, 9.9, 4.9,
 3.3, 3.3, 30.4, NULL,
 'manufacturer', ARRAY['on gold standard whey cookies and cream', 'optimum nutrition whey cookies cream', 'gold standard whey cookies cream', 'on whey cookies and cream', 'optimum nutrition cookies cream'],
 'protein_powder', 'Optimum Nutrition', 1, '120 cal per scoop (30.4g). 24g protein, 3g carbs, 1.5g fat. 5.5g BCAAs per serving.', TRUE),

-- ON Gold Standard Whey Mocha Cappuccino: 120 cal / 30.4g scoop
('on_gold_standard_whey_mocha', 'Optimum Nutrition Gold Standard Whey - Mocha Cappuccino', 395, 78.9, 9.9, 4.9,
 3.3, 3.3, 30.4, NULL,
 'manufacturer', ARRAY['on gold standard whey mocha', 'optimum nutrition whey mocha cappuccino', 'gold standard whey mocha', 'on whey mocha', 'optimum nutrition mocha cappuccino whey'],
 'protein_powder', 'Optimum Nutrition', 1, '120 cal per scoop (30.4g). 24g protein, 3g carbs, 1.5g fat. 5.5g BCAAs per serving.', TRUE),

-- ON Gold Standard Whey Banana Cream: 120 cal / 31g scoop
('on_gold_standard_whey_banana', 'Optimum Nutrition Gold Standard Whey - Banana Cream', 387, 77.4, 9.7, 4.8,
 3.2, 3.2, 31, NULL,
 'manufacturer', ARRAY['on gold standard whey banana', 'optimum nutrition whey banana cream', 'gold standard whey banana', 'on whey banana cream', 'optimum nutrition banana cream whey'],
 'protein_powder', 'Optimum Nutrition', 1, '120 cal per scoop (31g). 24g protein, 3g carbs, 1.5g fat. 5.5g BCAAs per serving.', TRUE),

-- ══════════════════════════════════════════
-- DYMATIZE — ISO 100 HYDROLYZED WHEY PROTEIN ISOLATE
-- Most flavors: 120 cal, 25g P, 2g C, 0.5g F per 32g scoop
-- Vanilla: 110 cal, 25g P, 1g C, 0g F per 30g scoop
-- per 100g = (value / scoop_g) * 100
-- ══════════════════════════════════════════

-- Dymatize ISO 100 Gourmet Chocolate: 120 cal / 32g scoop
('dymatize_iso100_chocolate', 'Dymatize ISO 100 - Gourmet Chocolate', 375, 78.1, 6.3, 1.6,
 0.0, 3.1, 32, NULL,
 'manufacturer', ARRAY['dymatize iso 100 chocolate', 'dymatize iso100 gourmet chocolate', 'iso 100 chocolate', 'dymatize chocolate protein', 'dymatize gourmet chocolate whey'],
 'protein_powder', 'Dymatize', 1, '120 cal per scoop (32g). 25g protein, 2g carbs, 0.5g fat. Hydrolyzed whey protein isolate. 5.5g BCAAs.', TRUE),

-- Dymatize ISO 100 Gourmet Vanilla: 110 cal / 30g scoop
('dymatize_iso100_vanilla', 'Dymatize ISO 100 - Gourmet Vanilla', 367, 83.3, 3.3, 0.0,
 0.0, 3.3, 30, NULL,
 'manufacturer', ARRAY['dymatize iso 100 vanilla', 'dymatize iso100 gourmet vanilla', 'iso 100 vanilla', 'dymatize vanilla protein', 'dymatize gourmet vanilla whey'],
 'protein_powder', 'Dymatize', 1, '110 cal per scoop (30g). 25g protein, 1g carbs, 0g fat. Hydrolyzed whey protein isolate. 5.5g BCAAs.', TRUE),

-- Dymatize ISO 100 Cookies & Cream: 120 cal / 32g scoop
('dymatize_iso100_cookies_cream', 'Dymatize ISO 100 - Cookies & Cream', 375, 78.1, 6.3, 1.6,
 0.0, 3.1, 32, NULL,
 'manufacturer', ARRAY['dymatize iso 100 cookies cream', 'dymatize iso100 cookies and cream', 'iso 100 cookies cream', 'dymatize cookies cream protein'],
 'protein_powder', 'Dymatize', 1, '120 cal per scoop (32g). 25g protein, 2g carbs, 0.5g fat. Hydrolyzed whey protein isolate. 5.5g BCAAs.', TRUE),

-- Dymatize ISO 100 Peanut Butter: 120 cal / 32g scoop
('dymatize_iso100_peanut_butter', 'Dymatize ISO 100 - Peanut Butter', 375, 78.1, 6.3, 1.6,
 0.0, 3.1, 32, NULL,
 'manufacturer', ARRAY['dymatize iso 100 peanut butter', 'dymatize iso100 peanut butter', 'iso 100 peanut butter', 'dymatize peanut butter protein', 'dymatize pb whey'],
 'protein_powder', 'Dymatize', 1, '120 cal per scoop (32g). 25g protein, 2g carbs, 0.5g fat. Hydrolyzed whey protein isolate. 5.5g BCAAs.', TRUE),

-- Dymatize ISO 100 Fudge Brownie: 120 cal / 32g scoop
('dymatize_iso100_fudge_brownie', 'Dymatize ISO 100 - Fudge Brownie', 375, 78.1, 6.3, 1.6,
 0.0, 3.1, 32, NULL,
 'manufacturer', ARRAY['dymatize iso 100 fudge brownie', 'dymatize iso100 fudge brownie', 'iso 100 fudge brownie', 'dymatize fudge brownie protein', 'dymatize brownie whey'],
 'protein_powder', 'Dymatize', 1, '120 cal per scoop (32g). 25g protein, 2g carbs, 0.5g fat. Hydrolyzed whey protein isolate. 5.5g BCAAs.', TRUE),

-- ══════════════════════════════════════════
-- MYPROTEIN — IMPACT WHEY PROTEIN
-- Flavored: ~103 cal, 21g P, 1g C, 1.9g F per 25g scoop
-- Unflavored: ~103 cal, 21g P, 1.5g C, 1.8g F per 25g scoop
-- per 100g = (value / 25) * 100
-- ══════════════════════════════════════════

-- Myprotein Impact Whey Chocolate Smooth: 103 cal / 25g scoop
('myprotein_impact_whey_chocolate', 'Myprotein Impact Whey - Chocolate Smooth', 412, 80.0, 6.0, 7.6,
 0.0, 4.0, 25, NULL,
 'manufacturer', ARRAY['myprotein whey chocolate', 'myprotein impact whey chocolate smooth', 'impact whey chocolate', 'myprotein chocolate smooth', 'myprotein chocolate protein'],
 'protein_powder', 'Myprotein', 1, '103 cal per scoop (25g). 20g protein, 1.5g carbs, 1.9g fat. Popular budget-friendly whey concentrate.', TRUE),

-- Myprotein Impact Whey Vanilla: 103 cal / 25g scoop
('myprotein_impact_whey_vanilla', 'Myprotein Impact Whey - Vanilla', 412, 80.0, 6.0, 7.6,
 0.0, 4.0, 25, NULL,
 'manufacturer', ARRAY['myprotein whey vanilla', 'myprotein impact whey vanilla', 'impact whey vanilla', 'myprotein vanilla', 'myprotein vanilla protein'],
 'protein_powder', 'Myprotein', 1, '103 cal per scoop (25g). 20g protein, 1.5g carbs, 1.9g fat. Popular budget-friendly whey concentrate.', TRUE),

-- Myprotein Impact Whey Cookies & Cream: 102 cal / 25g scoop
('myprotein_impact_whey_cookies_cream', 'Myprotein Impact Whey - Cookies & Cream', 408, 80.0, 4.0, 8.0,
 0.0, 4.0, 25, NULL,
 'manufacturer', ARRAY['myprotein whey cookies cream', 'myprotein impact whey cookies cream', 'impact whey cookies and cream', 'myprotein cookies cream', 'myprotein cookies cream protein'],
 'protein_powder', 'Myprotein', 1, '102 cal per scoop (25g). 20g protein, 1g carbs, 2g fat. Popular budget-friendly whey concentrate.', TRUE),

-- Myprotein Impact Whey Unflavored: 103 cal / 25g scoop
('myprotein_impact_whey_unflavored', 'Myprotein Impact Whey - Unflavored', 412, 88.0, 4.0, 6.0,
 0.0, 4.0, 25, NULL,
 'manufacturer', ARRAY['myprotein whey unflavored', 'myprotein impact whey unflavored', 'impact whey unflavoured', 'myprotein plain whey', 'myprotein unflavored protein'],
 'protein_powder', 'Myprotein', 1, '103 cal per scoop (25g). 22g protein, 1g carbs, 1.5g fat. Highest protein percentage in the Impact Whey range.', TRUE),

-- ══════════════════════════════════════════
-- TRANSPARENT LABS — 100% GRASS-FED WHEY PROTEIN ISOLATE
-- All flavors: ~120 cal, 28g P, 1g C, 0g F per 32g scoop
-- per 100g = (value / 32) * 100
-- ══════════════════════════════════════════

-- Transparent Labs Whey Isolate Chocolate: 120 cal / 32g scoop
('tl_whey_isolate_chocolate', 'Transparent Labs Grass-Fed Whey Isolate - Milk Chocolate', 375, 87.5, 3.1, 0.0,
 0.0, 0.0, 32, NULL,
 'manufacturer', ARRAY['transparent labs whey chocolate', 'transparent labs isolate chocolate', 'tl whey chocolate', 'transparent labs milk chocolate protein', 'grass fed whey isolate chocolate'],
 'protein_powder', 'Transparent Labs', 1, '120 cal per scoop (32g). 28g protein, 1g carbs, 0g fat. 100% grass-fed whey isolate. 87.5% protein by weight.', TRUE),

-- Transparent Labs Whey Isolate French Vanilla: 120 cal / 32g scoop
('tl_whey_isolate_vanilla', 'Transparent Labs Grass-Fed Whey Isolate - French Vanilla', 375, 87.5, 3.1, 0.0,
 0.0, 0.0, 32, NULL,
 'manufacturer', ARRAY['transparent labs whey vanilla', 'transparent labs isolate vanilla', 'tl whey vanilla', 'transparent labs french vanilla protein', 'grass fed whey isolate vanilla'],
 'protein_powder', 'Transparent Labs', 1, '120 cal per scoop (32g). 28g protein, 1g carbs, 0g fat. 100% grass-fed whey isolate. 87.5% protein by weight.', TRUE),

-- Transparent Labs Whey Isolate Strawberry: 120 cal / 32g scoop
('tl_whey_isolate_strawberry', 'Transparent Labs Grass-Fed Whey Isolate - Strawberry', 375, 87.5, 3.1, 0.0,
 0.0, 0.0, 32, NULL,
 'manufacturer', ARRAY['transparent labs whey strawberry', 'transparent labs isolate strawberry', 'tl whey strawberry', 'transparent labs strawberry protein', 'grass fed whey isolate strawberry'],
 'protein_powder', 'Transparent Labs', 1, '120 cal per scoop (32g). 28g protein, 1g carbs, 0g fat. 100% grass-fed whey isolate. 87.5% protein by weight.', TRUE),

-- Transparent Labs Whey Isolate Mocha: 120 cal / 32g scoop
('tl_whey_isolate_mocha', 'Transparent Labs Grass-Fed Whey Isolate - Mocha', 375, 87.5, 3.1, 0.0,
 0.0, 0.0, 32, NULL,
 'manufacturer', ARRAY['transparent labs whey mocha', 'transparent labs isolate mocha', 'tl whey mocha', 'transparent labs mocha protein', 'grass fed whey isolate mocha'],
 'protein_powder', 'Transparent Labs', 1, '120 cal per scoop (32g). 28g protein, 1g carbs, 0g fat. 100% grass-fed whey isolate. 87.5% protein by weight.', TRUE),

-- ══════════════════════════════════════════
-- ISOPURE — ZERO CARB 100% WHEY PROTEIN ISOLATE
-- All flavors: ~110 cal, 25g P, 0g C, 0.5g F per 31g scoop
-- per 100g = (value / 31) * 100
-- ══════════════════════════════════════════

-- Isopure Zero Carb Creamy Vanilla: 110 cal / 31g scoop
('isopure_zero_carb_vanilla', 'Isopure Zero Carb - Creamy Vanilla', 355, 80.6, 0.0, 1.6,
 0.0, 0.0, 31, NULL,
 'manufacturer', ARRAY['isopure zero carb vanilla', 'isopure creamy vanilla', 'isopure vanilla protein', 'isopure whey isolate vanilla', 'zero carb protein vanilla'],
 'protein_powder', 'Isopure', 1, '110 cal per scoop (31g). 25g protein, 0g carbs, 0.5g fat. Zero carb whey protein isolate with vitamins.', TRUE),

-- Isopure Zero Carb Dutch Chocolate: 110 cal / 33g scoop
('isopure_zero_carb_chocolate', 'Isopure Zero Carb - Dutch Chocolate', 333, 75.8, 0.0, 1.5,
 0.0, 0.0, 33, NULL,
 'manufacturer', ARRAY['isopure zero carb chocolate', 'isopure dutch chocolate', 'isopure chocolate protein', 'isopure whey isolate chocolate', 'zero carb protein chocolate'],
 'protein_powder', 'Isopure', 1, '110 cal per scoop (33g). 25g protein, 0g carbs, 0.5g fat. Zero carb whey protein isolate with vitamins.', TRUE),

-- Isopure Zero Carb Cookies & Cream: 110 cal / 31g scoop
('isopure_zero_carb_cookies_cream', 'Isopure Zero Carb - Cookies & Cream', 355, 80.6, 0.0, 1.6,
 0.0, 0.0, 31, NULL,
 'manufacturer', ARRAY['isopure zero carb cookies cream', 'isopure cookies and cream', 'isopure cookies cream protein', 'isopure whey isolate cookies cream', 'zero carb protein cookies cream'],
 'protein_powder', 'Isopure', 1, '110 cal per scoop (31g). 25g protein, 0g carbs, 0.5g fat. Zero carb whey protein isolate with vitamins.', TRUE),

-- ══════════════════════════════════════════
-- LEGION — WHEY+ GRASS-FED WHEY PROTEIN ISOLATE
-- All flavors: ~110 cal, 22g P, 4g C, 0g F per 29g scoop
-- per 100g = (value / 29) * 100
-- ══════════════════════════════════════════

-- Legion Whey+ Dutch Chocolate: 110 cal / 29g scoop
('legion_whey_plus_chocolate', 'Legion Whey+ - Dutch Chocolate', 379, 75.9, 13.8, 0.0,
 0.0, 0.0, 29, NULL,
 'manufacturer', ARRAY['legion whey plus chocolate', 'legion whey+ chocolate', 'legion dutch chocolate protein', 'legion athletics whey chocolate', 'whey+ chocolate'],
 'protein_powder', 'Legion Athletics', 1, '110 cal per scoop (29g). 22g protein, 4g carbs, 0g fat. Grass-fed whey isolate, no lactose, no added sugar.', TRUE),

-- Legion Whey+ French Vanilla: 110 cal / 29g scoop
('legion_whey_plus_vanilla', 'Legion Whey+ - French Vanilla', 379, 75.9, 13.8, 0.0,
 0.0, 0.0, 29, NULL,
 'manufacturer', ARRAY['legion whey plus vanilla', 'legion whey+ vanilla', 'legion french vanilla protein', 'legion athletics whey vanilla', 'whey+ vanilla'],
 'protein_powder', 'Legion Athletics', 1, '110 cal per scoop (29g). 22g protein, 4g carbs, 0g fat. Grass-fed whey isolate, no lactose, no added sugar.', TRUE),

-- Legion Whey+ Cookies & Cream: 110 cal / 29g scoop
('legion_whey_plus_cookies_cream', 'Legion Whey+ - Cookies & Cream', 379, 75.9, 13.8, 0.0,
 0.0, 0.0, 29, NULL,
 'manufacturer', ARRAY['legion whey plus cookies cream', 'legion whey+ cookies cream', 'legion cookies cream protein', 'legion athletics whey cookies cream', 'whey+ cookies cream'],
 'protein_powder', 'Legion Athletics', 1, '110 cal per scoop (29g). 22g protein, 4g carbs, 0g fat. Grass-fed whey isolate, no lactose, no added sugar.', TRUE),

-- ══════════════════════════════════════════
-- GORILLA MIND — GORILLA MODE PREMIUM WHEY PROTEIN
-- All flavors: ~130 cal, 25g P, 4g C, 2.5g F per 36g scoop
-- per 100g = (value / 36) * 100
-- ══════════════════════════════════════════

-- Gorilla Mode Whey Chocolate: 130 cal / 36g scoop
('gorilla_mode_whey_chocolate', 'Gorilla Mind Gorilla Mode Whey - Milk Chocolate', 361, 69.4, 11.1, 6.9,
 2.8, 2.8, 36, NULL,
 'manufacturer', ARRAY['gorilla mind whey chocolate', 'gorilla mode protein chocolate', 'gorilla mode whey chocolate', 'gorilla mind chocolate protein', 'gorilla mind milk chocolate whey'],
 'protein_powder', 'Gorilla Mind', 1, '130 cal per scoop (36g). 25g protein, 4g carbs, 2.5g fat. 90% WPI + 80% WPC blend. Nearly lactose-free.', TRUE),

-- Gorilla Mode Whey Vanilla: 130 cal / 36g scoop
('gorilla_mode_whey_vanilla', 'Gorilla Mind Gorilla Mode Whey - Vanilla', 361, 69.4, 11.1, 6.9,
 2.8, 2.8, 36, NULL,
 'manufacturer', ARRAY['gorilla mind whey vanilla', 'gorilla mode protein vanilla', 'gorilla mode whey vanilla', 'gorilla mind vanilla protein', 'gorilla mind vanilla whey'],
 'protein_powder', 'Gorilla Mind', 1, '130 cal per scoop (36g). 25g protein, 4g carbs, 2.5g fat. 90% WPI + 80% WPC blend. Nearly lactose-free.', TRUE)

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
