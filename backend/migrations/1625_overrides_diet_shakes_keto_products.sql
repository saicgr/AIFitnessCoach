-- 1625_overrides_diet_shakes_keto_products.sql
-- Diet/meal replacement shakes, protein shakes, and keto-friendly products.
-- Sources: Package nutrition labels via fatsecret.com, eatthismuch.com,
-- nutritionvalue.org, manufacturer websites, mynetdiary.com, calorieking.com.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = label serving.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SLIMFAST — ORIGINAL READY-TO-DRINK SHAKES
-- ══════════════════════════════════════════

-- SlimFast Original Rich Chocolate Shake RTD: 180 cal per bottle (325ml ~325g). 10g P, 26g C (5g fiber), 6g F.
('slimfast_original_rich_chocolate', 'SlimFast Original Rich Chocolate Royale Shake', 55, 3.1, 8.0, 1.8,
 1.5, 4.6, 325, NULL,
 'manufacturer', ARRAY['slimfast original rich chocolate', 'slimfast rich chocolate royale shake', 'slimfast original chocolate shake', 'slim fast chocolate shake', 'slimfast chocolate meal replacement'],
 'meal_replacement', 'SlimFast', 1, '180 cal per 11 fl oz bottle (325ml). 10g protein, 24 vitamins & minerals. 4 hours hunger control.', TRUE),

-- SlimFast Original French Vanilla Shake RTD: 180 cal per bottle (325ml). 10g P, 26g C (5g fiber), 6g F.
('slimfast_original_french_vanilla', 'SlimFast Original French Vanilla Shake', 55, 3.1, 8.0, 1.8,
 1.5, 4.6, 325, NULL,
 'manufacturer', ARRAY['slimfast original french vanilla', 'slimfast french vanilla shake', 'slimfast original vanilla shake', 'slim fast vanilla shake', 'slimfast vanilla meal replacement'],
 'meal_replacement', 'SlimFast', 1, '180 cal per 11 fl oz bottle (325ml). 10g protein, 24 vitamins & minerals.', TRUE),

-- SlimFast Original Strawberries & Cream Shake RTD: 180 cal per bottle (325ml). 10g P, 26g C (5g fiber), 6g F.
('slimfast_original_strawberries_cream', 'SlimFast Original Strawberries & Cream Shake', 55, 3.1, 8.0, 1.8,
 1.5, 4.6, 325, NULL,
 'manufacturer', ARRAY['slimfast original strawberries cream', 'slimfast strawberries and cream shake', 'slimfast strawberry shake', 'slim fast strawberry shake', 'slimfast strawberries cream meal replacement'],
 'meal_replacement', 'SlimFast', 1, '180 cal per 11 fl oz bottle (325ml). 10g protein, 24 vitamins & minerals.', TRUE),

-- ══════════════════════════════════════════
-- SLIMFAST — ADVANCED NUTRITION SHAKES
-- ══════════════════════════════════════════

-- SlimFast Advanced Nutrition Creamy Chocolate: 190 cal per bottle (325ml). 20g P, 9g C (5g fiber), 9g F.
('slimfast_advanced_creamy_chocolate', 'SlimFast Advanced Nutrition Creamy Chocolate Shake', 58, 6.2, 2.8, 2.8,
 1.5, 0.3, 325, NULL,
 'manufacturer', ARRAY['slimfast advanced nutrition creamy chocolate', 'slimfast advanced chocolate shake', 'slimfast high protein chocolate shake', 'slim fast advanced nutrition chocolate', 'slimfast creamy chocolate shake'],
 'meal_replacement', 'SlimFast', 1, '190 cal per 11 fl oz bottle (325ml). 20g protein, 1g sugar, 5g fiber. Gluten-free, 99.8% lactose-free.', TRUE),

-- SlimFast Advanced Nutrition Vanilla Cream: 180 cal per bottle (325ml). 20g P, 8g C (5g fiber), 8g F.
('slimfast_advanced_vanilla_cream', 'SlimFast Advanced Nutrition Vanilla Cream Shake', 55, 6.2, 2.5, 2.5,
 1.5, 0.3, 325, NULL,
 'manufacturer', ARRAY['slimfast advanced nutrition vanilla cream', 'slimfast advanced vanilla shake', 'slimfast high protein vanilla shake', 'slim fast advanced nutrition vanilla', 'slimfast vanilla cream shake'],
 'meal_replacement', 'SlimFast', 1, '180 cal per 11 fl oz bottle (325ml). 20g protein, 1g sugar, 5g fiber. Gluten-free.', TRUE),

-- ══════════════════════════════════════════
-- SLIMFAST — KETO SHAKE
-- ══════════════════════════════════════════

-- SlimFast Keto Fudge Brownie Shake Mix: 190 cal per 2 scoops (36g dry). 8g P, 9g C (4g fiber), 15g F.
('slimfast_keto_fudge_brownie', 'SlimFast Keto Fudge Brownie Batter Shake', 528, 22.2, 25.0, 41.7,
 11.1, 2.8, 36, NULL,
 'manufacturer', ARRAY['slimfast keto fudge brownie', 'slimfast keto shake fudge brownie', 'slim fast keto shake', 'slimfast keto meal replacement', 'slimfast keto fudge brownie batter'],
 'meal_replacement', 'SlimFast', 1, '190 cal per 2-scoop serving (36g dry). 8g protein, 15g fat. MCTs, whey & collagen protein. Mix with water.', TRUE),

-- ══════════════════════════════════════════
-- SLIMFAST — MEAL BARS
-- ══════════════════════════════════════════

-- SlimFast Meal Bar Chocolate Crunch: 200 cal per bar (52g). 8g P, 26g C (3g fiber), 8g F.
('slimfast_bar_chocolate_crunch', 'SlimFast Meal Bar Chocolate Crunch', 385, 15.4, 50.0, 15.4,
 5.8, 17.3, NULL, 52,
 'manufacturer', ARRAY['slimfast meal bar chocolate crunch', 'slimfast chocolate crunch bar', 'slim fast chocolate bar', 'slimfast meal replacement bar chocolate', 'slimfast chocolate crunch meal bar'],
 'protein_bar', 'SlimFast', 1, '200 cal per bar (52g). 8g protein, 24 vitamins & minerals. Meal replacement bar.', TRUE),

-- SlimFast Meal Bar Peanut Butter Crunch: 200 cal per bar (52g). 8g P, 25g C (3g fiber), 9g F.
('slimfast_bar_peanut_butter_crunch', 'SlimFast Meal Bar Peanut Butter Crunch', 385, 15.4, 48.1, 17.3,
 5.8, 15.4, NULL, 52,
 'manufacturer', ARRAY['slimfast meal bar peanut butter crunch', 'slimfast peanut butter crunch bar', 'slim fast peanut butter bar', 'slimfast meal replacement bar peanut butter', 'slimfast pb crunch meal bar'],
 'protein_bar', 'SlimFast', 1, '200 cal per bar (52g). 8g protein, 24 vitamins & minerals. Peanut butter crunch flavor.', TRUE),

-- ══════════════════════════════════════════
-- ATKINS — PROTEIN SHAKES
-- ══════════════════════════════════════════

-- Atkins Milk Chocolate Delight Shake: 160 cal per bottle (325ml). 15g P, 5g C (3g fiber), 9g F. 1g sugar.
('atkins_shake_milk_chocolate', 'Atkins Milk Chocolate Delight Protein Shake', 49, 4.6, 1.5, 2.8,
 0.9, 0.3, 325, NULL,
 'manufacturer', ARRAY['atkins milk chocolate delight shake', 'atkins chocolate protein shake', 'atkins milk chocolate shake', 'atkins protein shake chocolate', 'atkins shake milk chocolate delight'],
 'meal_replacement', 'Atkins', 1, '160 cal per 11 fl oz bottle (325ml). 15g protein, 1g sugar, 3g fiber. Low carb, keto friendly.', TRUE),

-- Atkins Creamy Vanilla Shake: 160 cal per bottle (325ml). 15g P, 5g C (3g fiber), 9g F. 1g sugar.
('atkins_shake_vanilla', 'Atkins Creamy Vanilla Protein Shake', 49, 4.6, 1.5, 2.8,
 0.9, 0.3, 325, NULL,
 'manufacturer', ARRAY['atkins vanilla shake', 'atkins creamy vanilla shake', 'atkins vanilla protein shake', 'atkins protein shake vanilla', 'atkins shake vanilla'],
 'meal_replacement', 'Atkins', 1, '160 cal per 11 fl oz bottle (325ml). 15g protein, 1g sugar, 3g fiber. Low carb, keto friendly.', TRUE),

-- Atkins Dark Chocolate Royale Shake: 160 cal per bottle (325ml). 15g P, 5g C (3g fiber), 9g F. 1g sugar.
('atkins_shake_dark_choc_royale', 'Atkins Dark Chocolate Royale Protein Shake', 49, 4.6, 1.5, 2.8,
 0.9, 0.3, 325, NULL,
 'manufacturer', ARRAY['atkins dark chocolate royale shake', 'atkins dark chocolate shake', 'atkins dark choc royale protein shake', 'atkins protein shake dark chocolate', 'atkins shake dark chocolate royale'],
 'meal_replacement', 'Atkins', 1, '160 cal per 11 fl oz bottle (325ml). 15g protein, 1g sugar, 3g fiber. Rich dark chocolate flavor.', TRUE),

-- Atkins Cafe Caramel Shake: 160 cal per bottle (325ml). 15g P, 5g C (3g fiber), 9g F. 1g sugar.
('atkins_shake_cafe_caramel', 'Atkins Cafe Caramel Protein Shake', 49, 4.6, 1.5, 2.8,
 0.9, 0.3, 325, NULL,
 'manufacturer', ARRAY['atkins cafe caramel shake', 'atkins caramel protein shake', 'atkins creamy caramel shake', 'atkins protein shake caramel', 'atkins shake cafe caramel'],
 'meal_replacement', 'Atkins', 1, '160 cal per 11 fl oz bottle (325ml). 15g protein, 1g sugar, 3g fiber. Coffee caramel flavor.', TRUE),

-- ══════════════════════════════════════════
-- ATKINS — SNACK BARS
-- ══════════════════════════════════════════

-- Atkins Caramel Chocolate Nut Roll Snack Bar: 190 cal per bar (44g). 7g P, 20g C (7g fiber), 12g F.
('atkins_snack_caramel_choc_nut', 'Atkins Caramel Chocolate Nut Roll Snack Bar', 432, 15.9, 45.5, 27.3,
 15.9, 4.5, NULL, 44,
 'manufacturer', ARRAY['atkins caramel chocolate nut roll', 'atkins caramel choc nut roll bar', 'atkins snack bar caramel chocolate', 'atkins nut roll caramel chocolate', 'atkins caramel chocolate snack bar'],
 'protein_bar', 'Atkins', 1, '190 cal per bar (44g). 7g protein, 3g net carbs, 7g fiber. Low sugar snack bar.', TRUE),

-- Atkins Chocolate Chip Granola Bar: 200 cal per bar (48g). 17g P, 22g C (7g fiber), 9g F.
('atkins_snack_choc_chip_granola', 'Atkins Chocolate Chip Granola Protein Bar', 417, 35.4, 45.8, 18.8,
 14.6, 2.1, NULL, 48,
 'manufacturer', ARRAY['atkins chocolate chip granola bar', 'atkins choc chip granola', 'atkins granola bar chocolate chip', 'atkins protein bar chocolate chip granola', 'atkins chocolate chip granola meal bar'],
 'protein_bar', 'Atkins', 1, '200 cal per bar (48g). 17g protein, 3g net carbs, 1g sugar. Meal-size protein bar.', TRUE),

-- Atkins Peanut Butter Fudge Crisp Snack Bar: 150 cal per bar (35g). 5g P, 18g C (6g fiber), 8g F.
('atkins_snack_pb_fudge_crisp', 'Atkins Peanut Butter Fudge Crisp Snack Bar', 429, 14.3, 51.4, 22.9,
 17.1, 5.7, NULL, 35,
 'manufacturer', ARRAY['atkins peanut butter fudge crisp', 'atkins pb fudge crisp bar', 'atkins snack bar peanut butter fudge', 'atkins peanut butter fudge snack bar', 'atkins pb fudge crisp snack'],
 'protein_bar', 'Atkins', 1, '150 cal per bar (35g). 5g protein, 6g fiber, 2g sugar. Crispy peanut butter fudge flavor.', TRUE),

-- ══════════════════════════════════════════
-- ATKINS — MEAL BARS
-- ══════════════════════════════════════════

-- Atkins Chocolate PB Pretzel Meal Bar: 200 cal per bar (48g). 16g P, 18g C (7g fiber), 10g F.
('atkins_meal_choc_pb_pretzel', 'Atkins Chocolate Peanut Butter Pretzel Meal Bar', 417, 33.3, 37.5, 20.8,
 14.6, 2.1, NULL, 48,
 'manufacturer', ARRAY['atkins chocolate peanut butter pretzel bar', 'atkins choc pb pretzel meal bar', 'atkins pretzel bar chocolate peanut butter', 'atkins meal bar pb pretzel', 'atkins chocolate pb pretzel bar'],
 'protein_bar', 'Atkins', 1, '200 cal per bar (48g). 16g protein, 4g net carbs, 1g sugar. Chocolate PB pretzel meal bar.', TRUE),

-- Atkins Cookies & Cream Meal Bar: 170 cal per bar (50g). 13g P, 20g C (8g fiber), 9g F.
('atkins_meal_cookies_cream', 'Atkins Cookies & Cream Meal Bar', 340, 26.0, 40.0, 18.0,
 16.0, 4.0, NULL, 50,
 'manufacturer', ARRAY['atkins cookies cream meal bar', 'atkins cookies and cream bar', 'atkins cookies n creme bar', 'atkins meal bar cookies cream', 'atkins cookies cream protein bar'],
 'protein_bar', 'Atkins', 1, '170 cal per bar (50g). 13g protein, 4g net carbs, 8g fiber. Cookies & cream flavor.', TRUE),

-- ══════════════════════════════════════════
-- ATKINS — ENDULGE TREATS
-- ══════════════════════════════════════════

-- Atkins Endulge Chocolate Peanut Candies: 130 cal per pack (34g). 3g P, 16g C, 10g F.
('atkins_endulge_choc_peanut', 'Atkins Endulge Chocolate Peanut Candies', 382, 8.8, 47.1, 29.4,
 2.9, 2.9, NULL, 34,
 'manufacturer', ARRAY['atkins endulge chocolate peanut candies', 'atkins endulge chocolate candies', 'atkins chocolate peanut candies', 'atkins endulge treat chocolate peanut', 'atkins peanut chocolate candy'],
 'protein_bar', 'Atkins', 1, '130 cal per pack (34g). 3g protein, 0g sugar alcohol adjusted net carbs. Keto treat.', TRUE),

-- ══════════════════════════════════════════
-- ORGAIN — CLEAN PROTEIN SHAKES
-- ══════════════════════════════════════════

-- Orgain Clean Protein Shake Creamy Chocolate Fudge: 130 cal per bottle (330ml). 20g P, 7g C (2g fiber), 2.5g F.
('orgain_clean_creamy_chocolate', 'Orgain Clean Protein Shake Creamy Chocolate Fudge', 39, 6.1, 2.1, 0.8,
 0.6, 0.9, 330, NULL,
 'manufacturer', ARRAY['orgain clean protein shake chocolate', 'orgain creamy chocolate fudge shake', 'orgain protein shake chocolate', 'orgain grass fed protein shake chocolate', 'orgain clean shake chocolate'],
 'meal_replacement', 'Orgain', 1, '130 cal per 11 fl oz bottle (330ml). 20g grass-fed whey protein, 3g sugar. Kosher, gluten-free.', TRUE),

-- Orgain Clean Protein Shake Vanilla Bean: 130 cal per bottle (330ml). 20g P, 7g C (1g fiber), 2.5g F.
('orgain_clean_vanilla_bean', 'Orgain Clean Protein Shake Vanilla Bean', 39, 6.1, 2.1, 0.8,
 0.3, 0.9, 330, NULL,
 'manufacturer', ARRAY['orgain clean protein shake vanilla', 'orgain vanilla bean shake', 'orgain protein shake vanilla', 'orgain grass fed protein shake vanilla', 'orgain clean shake vanilla bean'],
 'meal_replacement', 'Orgain', 1, '130 cal per 11 fl oz bottle (330ml). 20g grass-fed whey protein, low net carbs. Kosher, gluten-free.', TRUE),

-- ══════════════════════════════════════════
-- PREMIER PROTEIN — EXPANSION FLAVORS
-- ══════════════════════════════════════════

-- Premier Protein Bananas & Cream: 160 cal per bottle (340ml). 30g P, 5g C (3g fiber), 3g F.
('premier_bananas_cream', 'Premier Protein Shake Bananas & Cream', 47, 8.8, 1.5, 0.9,
 0.9, 0.3, 340, NULL,
 'manufacturer', ARRAY['premier protein bananas cream', 'premier protein banana shake', 'premier protein bananas and cream shake', 'premier protein shake banana', 'premier bananas cream shake'],
 'protein_shake', 'Premier Protein', 1, '160 cal per 11.5 fl oz bottle (340ml). 30g protein, 1g sugar, 24 vitamins & minerals.', TRUE),

-- Premier Protein Cookies & Cream: 160 cal per bottle (340ml). 30g P, 5g C (3g fiber), 3g F.
('premier_cookies_cream', 'Premier Protein Shake Cookies & Cream', 47, 8.8, 1.5, 0.9,
 0.9, 0.3, 340, NULL,
 'manufacturer', ARRAY['premier protein cookies cream', 'premier protein cookies and cream shake', 'premier protein shake cookies cream', 'premier cookies cream shake', 'premier protein cookies n cream'],
 'protein_shake', 'Premier Protein', 1, '160 cal per 11.5 fl oz bottle (340ml). 30g protein, 1g sugar. Cookies & cream flavor.', TRUE),

-- Premier Protein Peaches & Cream: 160 cal per bottle (340ml). 30g P, 5g C (3g fiber), 3g F.
('premier_peaches_cream', 'Premier Protein Shake Peaches & Cream', 47, 8.8, 1.5, 0.9,
 0.9, 0.3, 340, NULL,
 'manufacturer', ARRAY['premier protein peaches cream', 'premier protein peaches and cream shake', 'premier protein shake peaches cream', 'premier peaches cream shake', 'premier protein peach shake'],
 'protein_shake', 'Premier Protein', 1, '160 cal per 11.5 fl oz bottle (340ml). 30g protein, 1g sugar. Peaches & cream flavor.', TRUE),

-- ══════════════════════════════════════════
-- RATIO — KETO YOGURT
-- ══════════════════════════════════════════

-- Ratio Keto Vanilla Yogurt: 150 cal per cup (150g). 15g P, 3g C, 9g F. 1g sugar.
('ratio_keto_vanilla', 'Ratio Keto Friendly Vanilla Yogurt', 100, 10.0, 2.0, 6.0,
 0.0, 0.7, 150, NULL,
 'manufacturer', ARRAY['ratio keto vanilla yogurt', 'ratio vanilla yogurt keto', 'ratio keto friendly vanilla yogurt', 'ratio yogurt vanilla', 'ratio trio vanilla yogurt'],
 'yogurt', 'Ratio', 1, '150 cal per 5.3 oz cup (150g). 15g protein, 1g sugar, 3g carbs. Keto friendly cultured dairy snack.', TRUE),

-- Ratio Keto Strawberry Yogurt: 150 cal per cup (150g). 15g P, 3g C, 9g F. 1g sugar.
('ratio_keto_strawberry', 'Ratio Keto Friendly Strawberry Yogurt', 100, 10.0, 2.0, 6.0,
 0.0, 0.7, 150, NULL,
 'manufacturer', ARRAY['ratio keto strawberry yogurt', 'ratio strawberry yogurt keto', 'ratio keto friendly strawberry yogurt', 'ratio yogurt strawberry', 'ratio trio strawberry yogurt'],
 'yogurt', 'Ratio', 1, '150 cal per 5.3 oz cup (150g). 15g protein, 1g sugar, 3g carbs. Real strawberry keto yogurt.', TRUE),

-- Ratio Keto Coconut Yogurt: 200 cal per cup (150g). 15g P, 3g C, 15g F. 1g sugar.
('ratio_keto_coconut', 'Ratio Keto Friendly Coconut Yogurt', 133, 10.0, 2.0, 10.0,
 0.0, 0.7, 150, NULL,
 'manufacturer', ARRAY['ratio keto coconut yogurt', 'ratio coconut yogurt keto', 'ratio keto friendly coconut yogurt', 'ratio yogurt coconut', 'ratio trio coconut yogurt'],
 'yogurt', 'Ratio', 1, '200 cal per 5.3 oz cup (150g). 15g protein, 15g fat, 1g sugar. Coconut flavor, keto cultured dairy.', TRUE),

-- ══════════════════════════════════════════
-- REBEL CREAMERY — KETO ICE CREAM
-- ══════════════════════════════════════════

-- Rebel Mint Chip Ice Cream: 210 cal per 2/3 cup (88g). 3g P, 15g C (4g fiber, 11g sugar alcohol), 21g F. 0g sugar.
('rebel_mint_chip', 'Rebel Mint Chip Keto Ice Cream', 239, 3.4, 17.0, 23.9,
 4.5, 0.0, 88, NULL,
 'manufacturer', ARRAY['rebel mint chip ice cream', 'rebel ice cream mint chip', 'rebel mint chocolate chip', 'rebel keto ice cream mint chip', 'rebel creamery mint chip'],
 'ice_cream', 'Rebel Creamery', 1, '210 cal per 2/3 cup (88g). 3g protein, 21g fat, 0g sugar. Zero net carbs. Full fat, keto ice cream.', TRUE),

-- Rebel Cookie Dough Ice Cream: 220 cal per 2/3 cup (88g). 3g P, 18g C (3g fiber, 14g sugar alcohol), 20g F. 1g sugar.
('rebel_cookie_dough', 'Rebel Cookie Dough Keto Ice Cream', 250, 3.4, 20.5, 22.7,
 3.4, 1.1, 88, NULL,
 'manufacturer', ARRAY['rebel cookie dough ice cream', 'rebel ice cream cookie dough', 'rebel keto ice cream cookie dough', 'rebel creamery cookie dough', 'rebel cookie dough keto'],
 'ice_cream', 'Rebel Creamery', 1, '220 cal per 2/3 cup (88g). 3g protein, 20g fat, 1g sugar. ~2g net carbs. Full fat, keto ice cream.', TRUE),

-- ══════════════════════════════════════════
-- FAT SNAX — KETO COOKIES
-- ══════════════════════════════════════════

-- Fat Snax Chocolate Chip Cookies: 100 cal per cookie (20g). 2g P, 7g C (2g fiber), 8g F. 0g sugar.
('fatsnax_chocolate_chip', 'Fat Snax Chocolate Chip Keto Cookie', 500, 10.0, 35.0, 40.0,
 10.0, 0.0, NULL, 20,
 'manufacturer', ARRAY['fat snax chocolate chip cookie', 'fat snax keto cookies chocolate chip', 'fat snax cookies chocolate chip', 'fatsnax chocolate chip', 'fat snax choc chip keto cookie'],
 'cookie', 'Fat Snax', 1, '100 cal per cookie (20g). 2g protein, 2g net carbs, 0g sugar. Keto-friendly, grain-free cookie.', TRUE),

-- Fat Snax Lemony Lemon Cookies: 90 cal per cookie (20g). 2g P, 6g C (2g fiber), 7g F. 0g sugar.
('fatsnax_lemony_lemon', 'Fat Snax Lemony Lemon Keto Cookie', 450, 10.0, 30.0, 35.0,
 10.0, 0.0, NULL, 20,
 'manufacturer', ARRAY['fat snax lemony lemon cookie', 'fat snax keto cookies lemon', 'fat snax cookies lemony lemon', 'fatsnax lemony lemon', 'fat snax lemon keto cookie'],
 'cookie', 'Fat Snax', 1, '90 cal per cookie (20g). 2g protein, ~2g net carbs, 0g sugar. Keto-friendly lemon cookie.', TRUE)

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
