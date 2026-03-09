-- 1608_overrides_good_gather_simple_truth.sql
-- Good & Gather (Target store brand) — chicken sausages, protein bowls, yogurt, trail mix.
-- Simple Truth (Kroger store brand) — proteins, mac & cheese, protein powders, dairy.
-- Sources: MyFoodDiary, CalorieKing, EatThisMuch, Target.com, Kroger.com, NutritionValue.org.
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- GOOD & GATHER — CHICKEN SAUSAGES
-- ══════════════════════════════════════════

-- Good & Gather Italian-Style Smoked Chicken Sausage: 130 cal per 85g link
('gg_italian_chicken_sausage', 'Good & Gather Italian-Style Smoked Chicken Sausage', 152.9, 18.8, 3.5, 5.9,
 0.0, 1.2, NULL, 85,
 'manufacturer', ARRAY['good and gather italian chicken sausage', 'good gather italian sausage', 'target italian chicken sausage', 'good & gather italian style chicken sausage', 'gg italian chicken sausage'],
 'sausage', 'Good & Gather', 1, '130 cal per 85g link. Smoked chicken sausage with Italian herbs. Target store brand.', TRUE),

-- Good & Gather Jalapeno & Cheddar Smoked Chicken Sausage: 150 cal per 85g link
('gg_jalapeno_cheddar_chicken_sausage', 'Good & Gather Jalapeno & Cheddar Smoked Chicken Sausage', 176.5, 17.6, 3.5, 9.4,
 0.0, 1.2, NULL, 85,
 'manufacturer', ARRAY['good and gather jalapeno cheddar sausage', 'good gather jalapeno cheddar chicken sausage', 'target jalapeno cheddar chicken sausage', 'good & gather jalapeno cheddar sausage', 'gg jalapeno cheddar sausage'],
 'sausage', 'Good & Gather', 1, '150 cal per 85g link. Smoked chicken sausage with jalapeno peppers and cheddar cheese. Target store brand.', TRUE),

-- Good & Gather Andouille Smoked Chicken Sausage: 130 cal per 85g link
('gg_andouille_chicken_sausage', 'Good & Gather Andouille Smoked Chicken Sausage', 152.9, 18.8, 3.5, 5.9,
 0.0, 1.2, NULL, 85,
 'manufacturer', ARRAY['good and gather andouille sausage', 'good gather andouille chicken sausage', 'target andouille chicken sausage', 'good & gather andouille smoked chicken sausage', 'gg andouille sausage'],
 'sausage', 'Good & Gather', 1, '130 cal per 85g link. Cajun-style andouille smoked chicken sausage. Target store brand.', TRUE),

-- Good & Gather Apple & Gouda Smoked Chicken Sausage: 140 cal per 85g link
('gg_apple_gouda_chicken_sausage', 'Good & Gather Apple & Gouda Cheese Smoked Chicken Sausage', 164.7, 17.6, 4.7, 7.1,
 0.0, 2.4, NULL, 85,
 'manufacturer', ARRAY['good and gather apple gouda sausage', 'good gather apple gouda chicken sausage', 'target apple gouda chicken sausage', 'good & gather apple gouda sausage', 'gg apple gouda sausage'],
 'sausage', 'Good & Gather', 1, '140 cal per 85g link. Smoked chicken sausage with apple and gouda cheese. Target store brand.', TRUE),

-- Good & Gather Apple & Maple Breakfast Mini Links: 100 cal per 56g (3 links)
('gg_apple_maple_mini_links', 'Good & Gather Apple & Maple Breakfast Mini Chicken Sausage Links', 178.6, 16.1, 12.5, 7.1,
 0.0, 5.4, 56, NULL,
 'manufacturer', ARRAY['good and gather apple maple mini links', 'good gather apple maple breakfast sausage', 'target apple maple mini sausage links', 'good & gather apple maple mini links', 'gg apple maple mini sausage'],
 'sausage', 'Good & Gather', 1, '100 cal per 56g serving (3 mini links). Breakfast-style chicken sausage with apple and maple. Target store brand.', TRUE),

-- ══════════════════════════════════════════
-- GOOD & GATHER — PROTEIN BOWLS & SALADS
-- ══════════════════════════════════════════

-- Good & Gather Turkey & Bacon Cobb Salad Bowl: 210 cal per 177g bowl
('gg_turkey_bacon_cobb_salad', 'Good & Gather Turkey & Uncured Bacon Cobb Salad Bowl', 118.6, 7.9, 4.5, 7.9,
 1.7, 1.7, 177, NULL,
 'manufacturer', ARRAY['good and gather turkey bacon cobb salad', 'good gather turkey cobb salad', 'target turkey bacon cobb bowl', 'good & gather turkey cobb salad bowl', 'gg turkey cobb salad'],
 'salad', 'Good & Gather', 1, '210 cal per 177g bowl. Turkey and uncured bacon cobb salad with dressing included. Target store brand.', TRUE),

-- Good & Gather Cobb Salad w/ Chicken & Uncured Bacon: 330 cal per 177g bowl
('gg_chicken_bacon_cobb_salad', 'Good & Gather Cobb Salad with Chicken & Uncured Bacon', 186.4, 12.4, 5.6, 13.0,
 1.7, 2.3, 177, NULL,
 'manufacturer', ARRAY['good and gather chicken bacon cobb salad', 'good gather chicken cobb salad', 'target chicken bacon cobb bowl', 'good & gather cobb salad chicken bacon', 'gg chicken cobb salad'],
 'salad', 'Good & Gather', 1, '330 cal per 177g bowl. Chicken and uncured bacon cobb salad with dressing included. Target store brand.', TRUE),

-- Good & Gather Santa Fe Style Salad Bowl: 280 cal per 180g bowl
('gg_santa_fe_salad', 'Good & Gather Santa Fe Style Salad Bowl', 155.6, 7.8, 12.2, 8.9,
 2.2, 2.8, 180, NULL,
 'manufacturer', ARRAY['good and gather santa fe salad', 'good gather santa fe style salad', 'target santa fe salad bowl', 'good & gather santa fe salad bowl', 'gg santa fe salad'],
 'salad', 'Good & Gather', 1, '280 cal per 180g bowl. Santa Fe style salad with southwest dressing included. Target store brand.', TRUE),

-- Good & Gather Chicken Caesar Salad Bowl: 260 cal per 184g bowl
('gg_chicken_caesar_salad', 'Good & Gather Chicken Caesar Salad Bowl', 141.3, 9.8, 6.5, 8.7,
 1.1, 1.1, 184, NULL,
 'manufacturer', ARRAY['good and gather chicken caesar salad', 'good gather caesar salad chicken', 'target chicken caesar salad bowl', 'good & gather chicken caesar bowl', 'gg chicken caesar salad'],
 'salad', 'Good & Gather', 1, '260 cal per 184g bowl. Chicken caesar salad with dressing included. Target store brand.', TRUE),

-- Good & Gather Chicken Burrito Bowl (Frozen): 350 cal per 283g bowl
('gg_chicken_burrito_bowl', 'Good & Gather Chicken Burrito Bowl (Frozen)', 123.7, 6.7, 16.6, 2.5,
 2.5, 1.1, 283, NULL,
 'manufacturer', ARRAY['good and gather chicken burrito bowl', 'good gather frozen burrito bowl', 'target chicken burrito bowl frozen', 'good & gather chicken burrito bowl frozen', 'gg burrito bowl'],
 'bowl', 'Good & Gather', 1, '350 cal per 283g frozen bowl. Chicken burrito bowl with rice, beans, and vegetables. Target store brand.', TRUE),

-- ══════════════════════════════════════════
-- GOOD & GATHER — GREEK YOGURT
-- ══════════════════════════════════════════

-- Good & Gather Plain Nonfat Greek Yogurt: 100 cal per 170g
('gg_plain_nonfat_greek_yogurt', 'Good & Gather Plain Nonfat Greek Yogurt', 58.8, 10.6, 3.5, 0.0,
 0.0, 3.5, 170, NULL,
 'manufacturer', ARRAY['good and gather plain greek yogurt', 'good gather nonfat greek yogurt', 'target plain greek yogurt', 'good & gather plain nonfat greek yogurt', 'gg greek yogurt plain'],
 'yogurt', 'Good & Gather', 1, '100 cal per 170g (3/4 cup). 18g protein, 0g fat. Nonfat plain Greek yogurt. Target store brand.', TRUE),

-- Good & Gather Vanilla Blended Nonfat Greek Yogurt: 120 cal per 170g
('gg_vanilla_nonfat_greek_yogurt', 'Good & Gather Vanilla Blended Nonfat Greek Yogurt', 70.6, 8.8, 8.8, 0.0,
 0.0, 7.1, 170, NULL,
 'manufacturer', ARRAY['good and gather vanilla greek yogurt', 'good gather vanilla nonfat greek yogurt', 'target vanilla greek yogurt', 'good & gather vanilla blended greek yogurt', 'gg greek yogurt vanilla'],
 'yogurt', 'Good & Gather', 1, '120 cal per 170g (3/4 cup). 15g protein, 0g fat. Vanilla blended nonfat Greek yogurt. Target store brand.', TRUE),

-- ══════════════════════════════════════════
-- GOOD & GATHER — TRAIL MIX
-- ══════════════════════════════════════════

-- Good & Gather Cashew Cranberry Almond Trail Mix: 160 cal per 32g
('gg_cashew_cranberry_almond_trail_mix', 'Good & Gather Cashew Cranberry Almond Trail Mix', 500.0, 15.6, 50.0, 31.3,
 6.3, 25.0, 32, NULL,
 'manufacturer', ARRAY['good and gather cashew cranberry almond trail mix', 'good gather trail mix cashew cranberry', 'target cashew cranberry trail mix', 'good & gather cashew cranberry almond', 'gg cashew cranberry trail mix'],
 'trail_mix', 'Good & Gather', 1, '160 cal per 32g (1/4 cup). Cashews, cranberries, and almonds. Target store brand.', TRUE),

-- Good & Gather Omega-3 Trail Mix: 160 cal per 29g
('gg_omega3_trail_mix', 'Good & Gather Omega-3 Trail Mix', 551.7, 13.8, 41.4, 41.4,
 6.9, 20.7, 29, NULL,
 'manufacturer', ARRAY['good and gather omega 3 trail mix', 'good gather omega trail mix', 'target omega 3 trail mix', 'good & gather omega-3 trail mix', 'gg omega 3 trail mix'],
 'trail_mix', 'Good & Gather', 1, '160 cal per 29g (1/4 cup). Trail mix with omega-3 rich nuts and seeds. Target store brand.', TRUE),

-- Good & Gather Sweet Cajun Trail Mix: 160 cal per 29g
('gg_sweet_cajun_trail_mix', 'Good & Gather Sweet Cajun Trail Mix', 551.7, 13.8, 51.7, 34.5,
 6.9, 24.1, 29, NULL,
 'manufacturer', ARRAY['good and gather sweet cajun trail mix', 'good gather sweet cajun trail mix', 'target sweet cajun trail mix', 'good & gather sweet cajun', 'gg sweet cajun trail mix'],
 'trail_mix', 'Good & Gather', 1, '160 cal per 29g (1/4 cup). Sweet and spicy Cajun-seasoned trail mix. Target store brand.', TRUE),

-- Good & Gather Heart Healthy Trail Mix: 150 cal per 28g
('gg_heart_healthy_trail_mix', 'Good & Gather Heart Healthy Trail Mix', 535.7, 17.9, 46.4, 39.3,
 7.1, 21.4, 28, NULL,
 'manufacturer', ARRAY['good and gather heart healthy trail mix', 'good gather heart healthy trail mix', 'target heart healthy trail mix', 'good & gather heart healthy', 'gg heart healthy trail mix'],
 'trail_mix', 'Good & Gather', 1, '150 cal per 28g pouch. Heart-healthy nut and dried fruit mix. Target store brand.', TRUE),

-- ══════════════════════════════════════════
-- SIMPLE TRUTH — PROTEINS
-- ══════════════════════════════════════════

-- Simple Truth Organic Boneless Skinless Chicken Breast: 110 cal per 112g (4oz)
('st_organic_chicken_breast', 'Simple Truth Organic Boneless Skinless Chicken Breast', 98.2, 22.3, 0.0, 0.9,
 0.0, 0.0, 112, NULL,
 'manufacturer', ARRAY['simple truth organic chicken breast', 'simple truth chicken breast', 'kroger simple truth chicken', 'simple truth boneless skinless chicken', 'kroger organic chicken breast'],
 'protein', 'Simple Truth', 1, '110 cal per 112g (4oz). USDA Organic boneless skinless chicken breast. Very lean, high protein. Kroger store brand.', TRUE),

-- Simple Truth Emerge Plant-Based Meatless Burger: 270 cal per 113g patty
('st_plant_based_burger', 'Simple Truth Emerge Plant-Based Meatless Burger', 238.9, 17.7, 8.0, 15.0,
 0.9, 1.8, NULL, 113,
 'manufacturer', ARRAY['simple truth plant based burger', 'simple truth meatless burger', 'kroger simple truth plant burger', 'simple truth emerge burger', 'kroger plant based burger patty'],
 'protein', 'Simple Truth', 1, '270 cal per 113g patty. 20g plant protein. Meatless burger alternative. Kroger store brand.', TRUE),

-- ══════════════════════════════════════════
-- SIMPLE TRUTH — MAC & CHEESE / PASTA
-- ══════════════════════════════════════════

-- Simple Truth Protein Cheddar Macaroni and Cheese: 280 cal per 170g
('st_protein_cheddar_mac_cheese', 'Simple Truth Protein Cheddar Macaroni and Cheese', 164.7, 8.2, 22.4, 3.5,
 4.1, 1.8, 170, NULL,
 'manufacturer', ARRAY['simple truth protein mac and cheese', 'simple truth protein macaroni cheese', 'kroger simple truth protein mac', 'simple truth protein cheddar mac', 'kroger protein mac and cheese'],
 'pasta', 'Simple Truth', 1, '280 cal per 170g serving. 14g protein, 7g fiber. High-protein cheddar mac & cheese. Kroger store brand.', TRUE),

-- Simple Truth Organic Deluxe White Cheddar Shells & Cheese: 220 cal per 71g (2.5oz dry)
('st_deluxe_white_cheddar_shells', 'Simple Truth Organic Deluxe White Cheddar Shells & Cheese', 309.9, 12.7, 46.5, 9.9,
 1.4, 2.8, 71, NULL,
 'manufacturer', ARRAY['simple truth white cheddar shells', 'simple truth organic shells cheese', 'kroger simple truth white cheddar mac', 'simple truth deluxe shells and cheese', 'kroger organic white cheddar shells'],
 'pasta', 'Simple Truth', 1, '220 cal per 71g serving (2.5oz dry). 9g protein. Organic shells with white cheddar cheese sauce. Kroger store brand.', TRUE),

-- ══════════════════════════════════════════
-- SIMPLE TRUTH — PROTEIN POWDERS & BEVERAGES
-- ══════════════════════════════════════════

-- Simple Truth Vanilla Whey Protein Powder: 80 cal per 24g scoop
('st_vanilla_whey_protein', 'Simple Truth Vanilla Whey Protein Powder', 333.3, 75.0, 12.5, 2.1,
 0.0, 0.0, 24, NULL,
 'manufacturer', ARRAY['simple truth vanilla whey protein', 'simple truth vanilla protein powder', 'kroger simple truth whey vanilla', 'simple truth whey protein vanilla', 'kroger vanilla whey protein'],
 'protein_powder', 'Simple Truth', 1, '80 cal per 24g scoop. 18g whey protein. Less than 1g sugar. Kroger store brand.', TRUE),

-- Simple Truth Chocolate Whey Protein Powder: 90 cal per 25g scoop
('st_chocolate_whey_protein', 'Simple Truth Chocolate Whey Protein Powder', 360.0, 72.0, 20.0, 4.0,
 4.0, 0.0, 25, NULL,
 'manufacturer', ARRAY['simple truth chocolate whey protein', 'simple truth chocolate protein powder', 'kroger simple truth whey chocolate', 'simple truth whey protein chocolate', 'kroger chocolate whey protein'],
 'protein_powder', 'Simple Truth', 1, '90 cal per 25g scoop. 18g whey protein, 1g fiber. Less than 1g sugar. Kroger store brand.', TRUE),

-- Simple Truth Protein Tropical Fusion Water: 60 cal per 355g (12 fl oz)
('st_protein_tropical_fusion_water', 'Simple Truth Protein Tropical Fusion Infused Water', 16.9, 3.4, 0.6, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['simple truth protein water tropical', 'simple truth tropical fusion water', 'kroger simple truth protein water', 'simple truth protein infused water', 'kroger protein water tropical'],
 'beverage', 'Simple Truth', 1, '60 cal per 355g bottle (12 fl oz). 12g protein. Zero fat, zero sugar protein-infused water. Kroger store brand.', TRUE),

-- Simple Truth Protein Original Almond Milk: 80 cal per 240g cup
('st_protein_almond_milk', 'Simple Truth Protein Original Almond Milk', 33.3, 4.2, 2.5, 1.3,
 0.4, 1.3, 240, NULL,
 'manufacturer', ARRAY['simple truth protein almond milk', 'simple truth almond milk protein', 'kroger simple truth protein almond milk', 'simple truth protein original almond', 'kroger protein almond milk'],
 'beverage', 'Simple Truth', 1, '80 cal per 240g cup. 10g protein. Plant-based protein-fortified almond milk. Kroger store brand.', TRUE),

-- ══════════════════════════════════════════
-- SIMPLE TRUTH — DAIRY
-- ══════════════════════════════════════════

-- Simple Truth Organic Vitamin D Whole Milk: 150 cal per 240g cup
('st_organic_vitamin_d_whole_milk', 'Simple Truth Organic Vitamin D Whole Milk', 62.5, 3.3, 5.0, 3.3,
 0.0, 5.0, 240, NULL,
 'manufacturer', ARRAY['simple truth organic whole milk', 'simple truth vitamin d milk', 'kroger simple truth organic milk', 'simple truth organic vitamin d whole milk', 'kroger organic whole milk'],
 'dairy', 'Simple Truth', 1, '150 cal per 240g cup. 8g protein, 8g fat, 12g carbs. Organic vitamin D fortified whole milk. Kroger store brand.', TRUE),

-- Simple Truth Organic 100% Grassfed Whole Milk: 160 cal per 240g cup
('st_organic_grassfed_whole_milk', 'Simple Truth Organic 100% Grassfed Whole Milk', 66.7, 3.3, 5.0, 3.8,
 0.0, 5.0, 240, NULL,
 'manufacturer', ARRAY['simple truth grassfed milk', 'simple truth organic grassfed whole milk', 'kroger simple truth grassfed milk', 'simple truth 100% grassfed milk', 'kroger organic grassfed whole milk'],
 'dairy', 'Simple Truth', 1, '160 cal per 240g cup. 8g protein, 9g fat, 12g carbs. Organic 100% grassfed whole milk. Kroger store brand.', TRUE)

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
