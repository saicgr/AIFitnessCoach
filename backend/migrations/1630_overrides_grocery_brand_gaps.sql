-- 1630_overrides_grocery_brand_gaps.sql
-- Barilla, Tyson, Perdue, Progresso, and Hillshire Farm grocery products.
-- Sources: Package nutrition labels via fatsecret.com, nutritionix.com.
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
-- BARILLA — PASTA
-- ══════════════════════════════════════════

-- Barilla Classic Spaghetti: 200 cal per 56g dry serving
-- FatSecret: 200 cal, 1g fat, 38g carb (note: FatSecret shows 11g P but Barilla label shows 7g for classic)
-- Barilla label: 200 cal, 7g protein, 42g carb, 1g fat, 2g fiber, 2g sugar per 56g
-- Per 100g: 200/56*100 = 357 cal
('barilla_classic_spaghetti', 'Barilla Classic Spaghetti', 357, 12.5, 75.0, 1.8,
 3.6, 3.6, 56, NULL,
 'manufacturer', ARRAY['barilla spaghetti', 'barilla classic spaghetti', 'barilla pasta spaghetti', 'barilla blue box spaghetti'],
 'pasta', 'Barilla', 1, '200 cal per 2 oz dry (56g). Classic semolina durum wheat spaghetti. Cook 8-10 min.', TRUE),

-- Barilla Classic Penne: 200 cal per 56g dry serving
-- FatSecret: 200 cal, 11g protein, 38g carb, 1g fat, 3g fiber, 1g sugar per 56g
-- Per 100g: 357 cal
('barilla_classic_penne', 'Barilla Classic Penne', 357, 19.6, 67.9, 1.8,
 5.4, 1.8, 56, NULL,
 'manufacturer', ARRAY['barilla penne', 'barilla classic penne', 'barilla penne pasta', 'barilla penne rigate'],
 'pasta', 'Barilla', 1, '200 cal per 2 oz dry (56g). Classic semolina durum wheat penne rigate.', TRUE),

-- Barilla Protein+ Spaghetti: 190 cal per 56g dry serving
-- FatSecret: 190 cal, 10g protein, 38g carb, 1g fat, 5g fiber, 2g sugar per 56g
-- Per 100g: 190/56*100 = 339 cal
('barilla_protein_spaghetti', 'Barilla Protein+ Spaghetti', 339, 17.9, 67.9, 1.8,
 8.9, 3.6, 56, NULL,
 'manufacturer', ARRAY['barilla protein spaghetti', 'barilla protein plus spaghetti', 'barilla protein+ spaghetti', 'barilla high protein pasta'],
 'pasta', 'Barilla', 1, '190 cal per 2 oz dry (56g). Multigrain blend with lentils, chickpeas, and peas. 10g protein per serving.', TRUE),

-- Barilla Protein+ Penne: 190 cal per 56g dry serving
-- FatSecret: 190 cal, 10g protein, 38g carb, 1g fat, 5g fiber, 2g sugar per 56g
-- Per 100g: 339 cal
('barilla_protein_penne', 'Barilla Protein+ Penne', 339, 17.9, 67.9, 1.8,
 8.9, 3.6, 56, NULL,
 'manufacturer', ARRAY['barilla protein penne', 'barilla protein plus penne', 'barilla protein+ penne', 'barilla high protein penne'],
 'pasta', 'Barilla', 1, '190 cal per 2 oz dry (56g). Multigrain blend with lentils, chickpeas, and peas. 10g protein per serving.', TRUE),

-- Barilla Red Lentil Rotini: 190 cal per 56g dry serving
-- FatSecret: 190 cal, 14g protein, 34g carb, 1.5g fat, 6g fiber, 1g sugar per 56g
-- Per 100g: 339 cal
('barilla_red_lentil_rotini', 'Barilla Red Lentil Rotini', 339, 25.0, 60.7, 2.7,
 10.7, 1.8, 56, NULL,
 'manufacturer', ARRAY['barilla red lentil rotini', 'barilla red lentil pasta', 'barilla lentil rotini', 'barilla legume pasta'],
 'pasta', 'Barilla', 1, '190 cal per 2 oz dry (56g). Made from red lentil flour. 14g protein, 6g fiber per serving. Gluten-free.', TRUE),

-- ══════════════════════════════════════════
-- TYSON — CHICKEN PRODUCTS
-- ══════════════════════════════════════════

-- Tyson Grilled & Ready Chicken Breast Strips: 120 cal per 84g (3 oz)
-- FatSecret: 120 cal, 22g protein, 2g carb, 2.5g fat, 0g fiber, 1g sugar per 84g
-- Per 100g: 120/84*100 = 143 cal
('tyson_grilled_ready_strips', 'Tyson Grilled & Ready Chicken Breast Strips', 143, 26.2, 2.4, 3.0,
 0.0, 1.2, 84, NULL,
 'manufacturer', ARRAY['tyson grilled ready', 'tyson grilled chicken strips', 'tyson grilled ready strips', 'tyson chicken breast strips', 'tyson grilled and ready'],
 'chicken', 'Tyson', 1, '120 cal per 3 oz (84g). Fully cooked grilled chicken breast strips. High protein, low carb. Ready to eat.', TRUE),

-- Tyson Frozen Chicken Nuggets: 210 cal per 5 pieces (90g)
-- FatSecret: 210 cal, 11g protein, 12g carb, 13g fat, 0g fiber, 0g sugar per 90g
-- Per 100g: 210/90*100 = 233 cal
('tyson_frozen_nuggets', 'Tyson Frozen Chicken Nuggets', 233, 12.2, 13.3, 14.4,
 0.0, 0.0, NULL, 90,
 'manufacturer', ARRAY['tyson chicken nuggets', 'tyson frozen nuggets', 'tyson nuggets', 'tyson all natural chicken nuggets', 'tyson breaded nuggets'],
 'chicken', 'Tyson', 1, '210 cal per 5 pieces (90g). Breaded and fully cooked. 56% fat, 23% carb, 21% protein by calories.', TRUE),

-- Tyson Any'tizers Homestyle Boneless Chicken Bites: 260 cal per 84g (3 oz)
-- FatSecret: 260 cal, 12g protein, 23g carb, 14g fat, 2g fiber, 0g sugar per 84g
-- Per 100g: 260/84*100 = 310 cal
('tyson_boneless_bites', 'Tyson Any''tizers Boneless Chicken Bites', 310, 14.3, 27.4, 16.7,
 2.4, 0.0, 84, NULL,
 'manufacturer', ARRAY['tyson boneless bites', 'tyson anytizers boneless chicken bites', 'tyson chicken bites', 'tyson boneless chicken bites', 'tyson any tizers'],
 'chicken', 'Tyson', 1, '260 cal per 3 oz (84g). Breaded boneless chicken bites. Fully cooked, crispy coating.', TRUE),

-- Tyson Chicken Breast Tenderloins (Raw): 110 cal per 4 oz (112g)
-- FatSecret: 110 cal, 26g protein, 0g carb, 0.5g fat, 0g fiber, 0g sugar per 112g
-- Per 100g: 110/112*100 = 98 cal
('tyson_breast_tenderloins', 'Tyson Chicken Breast Tenderloins (Raw)', 98, 23.2, 0.0, 0.4,
 0.0, 0.0, 112, NULL,
 'manufacturer', ARRAY['tyson chicken tenderloins', 'tyson breast tenderloins', 'tyson raw chicken tenderloins', 'tyson chicken tenders raw', 'tyson all natural tenderloins'],
 'chicken', 'Tyson', 1, '110 cal per 4 oz raw (112g). All-natural boneless skinless chicken breast tenderloins. Very lean, high protein.', TRUE),

-- ══════════════════════════════════════════
-- PERDUE — CHICKEN PRODUCTS
-- ══════════════════════════════════════════

-- Perdue Simply Smart Lightly Breaded Chicken Strips: 150 cal per 84g (3 oz)
-- FatSecret: 150 cal, 15g protein, 8g carb, 6g fat, 0g fiber, 1g sugar per 84g
-- Per 100g: 150/84*100 = 179 cal
('perdue_simply_smart_strips', 'Perdue Simply Smart Chicken Breast Strips', 179, 17.9, 9.5, 7.1,
 0.0, 1.2, 84, NULL,
 'manufacturer', ARRAY['perdue simply smart strips', 'perdue simply smart chicken strips', 'perdue breaded chicken strips', 'perdue simply smart organics strips'],
 'chicken', 'Perdue', 1, '150 cal per 3 oz (84g). Lightly breaded chicken breast strips. No antibiotics ever.', TRUE),

-- Perdue Chicken Breast Tenderloins (Raw): 110 cal per 4 oz (112g)
-- FatSecret: 110 cal, 25g protein, 0g carb, 1g fat, 0g fiber, 0g sugar per 112g
-- Per 100g: 110/112*100 = 98 cal
('perdue_breast_tenderloins', 'Perdue Chicken Breast Tenderloins (Raw)', 98, 22.3, 0.0, 0.9,
 0.0, 0.0, 112, NULL,
 'manufacturer', ARRAY['perdue chicken tenderloins', 'perdue breast tenderloins', 'perdue raw chicken tenderloins', 'perdue chicken tenders raw'],
 'chicken', 'Perdue', 1, '110 cal per 4 oz raw (112g). Boneless skinless chicken breast tenderloins. No antibiotics ever.', TRUE),

-- Perdue Short Cuts Carved Chicken Breast (Original Roasted): 100 cal per 84g (3 oz)
-- FatSecret: 100 cal, 20g protein, 1g carb, 2g fat, 0g fiber, 0g sugar per 84g
-- Per 100g: 100/84*100 = 119 cal
('perdue_short_cuts', 'Perdue Short Cuts Carved Chicken Breast', 119, 23.8, 1.2, 2.4,
 0.0, 0.0, 84, NULL,
 'manufacturer', ARRAY['perdue short cuts', 'perdue short cuts chicken', 'perdue carved chicken breast', 'perdue short cuts original roasted', 'perdue grilled chicken strips'],
 'chicken', 'Perdue', 1, '100 cal per 3 oz (84g). Fully cooked carved chicken breast, original roasted. Ready to eat. High protein.', TRUE),

-- ══════════════════════════════════════════
-- PROGRESSO — SOUPS
-- ══════════════════════════════════════════

-- Progresso Light Chicken Noodle Soup: 65 cal per 1 cup (~248g)
-- FatSecret (per can 524g = ~2 cups): 130 cal, 1.5g fat, 19g carb, 11g protein, 2g fiber, 3g sugar
-- Per cup (~262g): 65 cal, 0.75g fat, 9.5g carb, 5.5g protein, 1g fiber, 1.5g sugar
-- Per 100g: 65/248*100 = 26 cal
('progresso_light_chicken_noodle', 'Progresso Light Chicken Noodle Soup', 26, 2.2, 3.8, 0.3,
 0.4, 0.6, 248, NULL,
 'manufacturer', ARRAY['progresso light chicken noodle', 'progresso chicken noodle light', 'progresso light soup chicken noodle', 'progresso low calorie chicken noodle'],
 'soup', 'Progresso', 1, '65 cal per cup (~248g). Light chicken noodle soup. Low calorie, good protein for a soup.', TRUE),

-- Progresso Traditional Chicken Noodle Soup: 115 cal per 1 cup (~248g)
-- FatSecret (per can 484g = ~2 cups): 230 cal, 6g fat, 28g carb, 15g protein, 2g fiber, 3g sugar
-- Per cup (~242g): 115 cal, 3g fat, 14g carb, 7.5g protein, 1g fiber, 1.5g sugar
-- Per 100g: 115/248*100 = 46 cal
('progresso_traditional_chicken_noodle', 'Progresso Traditional Chicken Noodle Soup', 46, 3.0, 5.6, 1.2,
 0.4, 0.6, 248, NULL,
 'manufacturer', ARRAY['progresso traditional chicken noodle', 'progresso chicken noodle', 'progresso chicken noodle soup', 'progresso classic chicken noodle'],
 'soup', 'Progresso', 1, '115 cal per cup (~248g). Traditional hearty chicken noodle soup. Classic comfort food.', TRUE),

-- Progresso Light Vegetable Soup (Italian-style): 70 cal per 1 cup (238g)
-- FatSecret: 70 cal, 0g fat, 15g carb, 2g protein, 4g fiber, 4g sugar per cup (238g)
-- Per 100g: 70/238*100 = 29 cal
('progresso_light_italian_veggie', 'Progresso Light Italian-Style Vegetable Soup', 29, 0.8, 6.3, 0.0,
 1.7, 1.7, 248, NULL,
 'manufacturer', ARRAY['progresso light vegetable', 'progresso light italian vegetable', 'progresso vegetable soup light', 'progresso light veggie soup'],
 'soup', 'Progresso', 1, '70 cal per cup (~248g). Light vegetable soup, Italian-style. Very low calorie, high fiber. Zero fat.', TRUE),

-- Progresso Rich & Hearty Chicken & Homestyle Noodles: 130 cal per 1 cup (246g)
-- FatSecret: 130 cal, 3.5g fat, 15g carb, 9g protein, 1g fiber, 2g sugar per cup (246g)
-- Per 100g: 130/246*100 = 53 cal
('progresso_rich_hearty_chicken_noodle', 'Progresso Rich & Hearty Chicken & Homestyle Noodles', 53, 3.7, 6.1, 1.4,
 0.4, 0.8, 248, NULL,
 'manufacturer', ARRAY['progresso rich hearty chicken noodle', 'progresso rich and hearty', 'progresso hearty chicken noodle', 'progresso homestyle noodles', 'progresso chicken homestyle noodles'],
 'soup', 'Progresso', 1, '130 cal per cup (~248g). Hearty chicken soup with thick egg noodles. Most filling Progresso chicken noodle.', TRUE),

-- ══════════════════════════════════════════
-- HILLSHIRE FARM — DELI MEATS & SAUSAGE
-- ══════════════════════════════════════════

-- Hillshire Farm Ultra Thin Oven Roasted Turkey Breast: 60 cal per 56g (2 oz, 4 slices)
-- FatSecret: 60 cal, 1.5g fat, 2g carb, 10g protein, 0g fiber, 1g sugar per 56g
-- Per 100g: 60/56*100 = 107 cal
('hillshire_ultra_thin_turkey', 'Hillshire Farm Ultra Thin Oven Roasted Turkey Breast', 107, 17.9, 3.6, 2.7,
 0.0, 1.8, 56, NULL,
 'manufacturer', ARRAY['hillshire farm turkey', 'hillshire ultra thin turkey', 'hillshire farm oven roasted turkey', 'hillshire deli turkey', 'hillshire farm ultra thin oven roasted turkey breast'],
 'deli_meat', 'Hillshire Farm', 1, '60 cal per 2 oz (56g, 4 slices). Ultra thin sliced oven roasted turkey breast. High protein, low fat deli meat.', TRUE),

-- Hillshire Farm Ultra Thin Honey Ham: 70 cal per 56g (2 oz)
-- FatSecret: 70 cal, 2.5g fat, 4g carb, 9g protein, 0g fiber, 3g sugar per 56g
-- Per 100g: 70/56*100 = 125 cal
('hillshire_ultra_thin_honey_ham', 'Hillshire Farm Ultra Thin Honey Ham', 125, 16.1, 7.1, 4.5,
 0.0, 5.4, 56, NULL,
 'manufacturer', ARRAY['hillshire farm honey ham', 'hillshire ultra thin honey ham', 'hillshire farm ham', 'hillshire deli ham', 'hillshire farm ultra thin honey ham'],
 'deli_meat', 'Hillshire Farm', 1, '70 cal per 2 oz (56g). Ultra thin sliced honey ham. Slightly sweet, good protein source.', TRUE),

-- Hillshire Farm Naturals Slow Roasted Turkey Breast: 50 cal per 52g (3 slices)
-- FatSecret: 50 cal, 0.5g fat, 1g carb, 10g protein, 0g fiber, 0g sugar per 52g
-- Per 100g: 50/52*100 = 96 cal
-- Normalized to 56g serving: ~54 cal
('hillshire_naturals_turkey', 'Hillshire Farm Naturals Hardwood Smoked Turkey Breast', 96, 19.2, 1.9, 1.0,
 0.0, 0.0, 56, NULL,
 'manufacturer', ARRAY['hillshire farm naturals turkey', 'hillshire naturals turkey', 'hillshire farm hardwood turkey', 'hillshire naturals hardwood smoked turkey', 'hillshire farm naturals slow roasted turkey'],
 'deli_meat', 'Hillshire Farm', 1, '50 cal per 52g (3 slices). No artificial ingredients, no added nitrates/nitrites. Very lean, high protein.', TRUE),

-- Hillshire Farm Lit'l Smokies Smoked Sausage: 190 cal per 60g (7 links)
-- FatSecret: 190 cal, 17g fat, 2g carb, 7g protein, 0g fiber, 1g sugar per 60g
-- Per 100g: 190/60*100 = 317 cal
-- Normalized to 56g serving: ~178 cal
('hillshire_litl_smokies', 'Hillshire Farm Lit''l Smokies Smoked Sausage', 317, 11.7, 3.3, 28.3,
 0.0, 1.7, 56, NULL,
 'manufacturer', ARRAY['hillshire farm litl smokies', 'hillshire farm lil smokies', 'lil smokies', 'little smokies', 'hillshire farm cocktail sausage', 'hillshire litl smokies smoked sausage'],
 'sausage', 'Hillshire Farm', 1, '190 cal per 7 links (60g). Mini smoked sausage links. Popular party appetizer. High fat.', TRUE)

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
