-- 1579_cooking_method_variants_and_variant_names.sql
-- Adds separate rows for cooking method variants (different macros per method)
-- and updates variant_names for existing foods with size variants, Hindi names, and common search terms.
-- Sources: USDA FoodData Central, nutritionvalue.org, fatsecret.com, calorieking.com.
-- All values per 100g.

-- ==========================================
-- PART A: COOKING METHOD VARIANT ROWS
-- Each cooking method has different macros due to oil absorption, water loss, etc.
-- ==========================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ── SALMON VARIANTS ──────────────────────────────────────────────
-- Base: Salmon (Cooked) = 208 cal, 20.4P, 0C, 13.4F (already in 1577)

-- Fried Salmon: pan-fried in oil adds ~50 cal from fat absorption
('salmon_fried', 'Salmon (Fried)', 261, 20.5, 1.5, 19.2,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['fried salmon', 'pan fried salmon', 'deep fried salmon', 'salmon fried'],
 'proteins', NULL, 1, '261 cal/100g. Pan-frying in oil adds ~50 cal vs baked. Higher fat from oil absorption.', TRUE),

-- Smoked Salmon: dehydration concentrates nutrients, lower fat from rendering
('salmon_smoked', 'Salmon (Smoked)', 117, 18.3, 0.0, 4.3,
 0.0, 0.0, 56, NULL,
 'usda', ARRAY['smoked salmon', 'lox', 'nova salmon', 'salmon lox', 'cold smoked salmon', 'hot smoked salmon'],
 'proteins', NULL, 1, '117 cal/100g. High in sodium (672mg/100g). Rich in omega-3. Popular on bagels.', TRUE),

-- Dried Salmon (salmon jerky): dehydrated concentrates protein
('salmon_dried', 'Salmon (Dried/Jerky)', 300, 55.0, 1.0, 8.0,
 0.0, 0.5, 28, NULL,
 'usda', ARRAY['dried salmon', 'salmon jerky', 'dehydrated salmon', 'salmon dried', 'salmon biltong'],
 'proteins', NULL, 1, '300 cal/100g. Very high protein (55g/100g) due to dehydration. Great portable protein.', TRUE),

-- Pan-Seared Salmon: light oil, high heat, minimal oil absorption
('salmon_pan_seared', 'Salmon (Pan-Seared)', 230, 22.0, 0.0, 15.5,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['pan seared salmon', 'seared salmon', 'salmon seared', 'pan sear salmon', 'crispy skin salmon'],
 'proteins', NULL, 1, '230 cal/100g. Light oil sear adds minimal fat vs baked. Crispy skin retains omega-3s.', TRUE),

-- Baked Salmon: dry heat, no added fat
('salmon_baked', 'Salmon (Baked)', 208, 20.4, 0.0, 13.4,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['baked salmon', 'oven baked salmon', 'roasted salmon', 'salmon baked'],
 'proteins', NULL, 1, '208 cal/100g. Same as base cooked salmon (dry heat, no added fat). Heart-healthy omega-3s.', TRUE),

-- Poached Salmon: cooked in liquid, slightly lower fat
('salmon_poached', 'Salmon (Poached)', 194, 21.6, 0.0, 11.5,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['poached salmon', 'salmon poached', 'salmon in broth'],
 'proteins', NULL, 1, '194 cal/100g. Gentle cooking preserves nutrients. Slightly lower fat than baked.', TRUE),

-- Stir-Fried Salmon: high heat with oil and sauce
('salmon_stir_fried', 'Salmon (Stir-Fried)', 245, 19.8, 3.2, 17.0,
 0.2, 1.5, 150, NULL,
 'usda', ARRAY['stir fried salmon', 'stir fry salmon', 'salmon stir fry', 'wok salmon', 'salmon wok fried'],
 'proteins', NULL, 1, '245 cal/100g. Wok-fried with oil and sauce adds carbs from sauce and fat from oil.', TRUE),

-- Raw Salmon (sashimi grade)
('salmon_raw', 'Salmon (Raw/Sashimi)', 142, 19.8, 0.0, 6.3,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['raw salmon', 'salmon sashimi', 'sashimi salmon', 'salmon raw', 'salmon sushi grade'],
 'proteins', NULL, 1, '142 cal/100g raw. Lower cal than cooked (water not lost). Used in sushi and sashimi.', TRUE),

-- ── CHICKEN BREAST VARIANTS ──────────────────────────────────────
-- Base: Chicken Breast (Grilled) = 165 cal, 31.0P, 0C, 3.6F (already in 1577)

-- Fried Chicken Breast: breaded and fried
('chicken_breast_fried', 'Chicken Breast (Fried)', 260, 28.0, 10.0, 12.0,
 0.5, 0.5, 120, NULL,
 'usda', ARRAY['fried chicken breast', 'breaded chicken breast', 'chicken breast fried', 'crispy chicken breast', 'chicken cutlet fried'],
 'proteins', NULL, 1, '260 cal/100g. Breading + frying adds ~95 cal vs grilled. Breading adds carbs, oil adds fat.', TRUE),

-- Baked Chicken Breast: dry heat, no added oil
('chicken_breast_baked', 'Chicken Breast (Baked)', 165, 31.0, 0.0, 3.6,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['baked chicken breast', 'oven baked chicken', 'roasted chicken breast', 'chicken breast baked'],
 'proteins', NULL, 1, '165 cal/100g. Same as grilled (dry heat, no added fat). Lean protein gold standard.', TRUE),

-- Boiled Chicken Breast: slightly less protein density due to water retention
('chicken_breast_boiled', 'Chicken Breast (Boiled)', 151, 28.8, 0.0, 3.3,
 0.0, 0.0, 120, NULL,
 'usda', ARRAY['boiled chicken breast', 'poached chicken breast', 'chicken breast boiled', 'chicken breast poached', 'steamed chicken breast'],
 'proteins', NULL, 1, '151 cal/100g. Boiling retains more water, slightly diluting macros. Great for soups and salads.', TRUE),

-- Stir-Fried Chicken Breast
('chicken_breast_stir_fried', 'Chicken Breast (Stir-Fried)', 195, 27.5, 3.0, 7.5,
 0.3, 1.0, 120, NULL,
 'usda', ARRAY['stir fried chicken breast', 'stir fry chicken', 'chicken stir fry', 'wok chicken breast', 'chicken breast stir fry'],
 'proteins', NULL, 1, '195 cal/100g. Stir-frying in oil with sauce adds fat and carbs vs plain grilled.', TRUE),

-- Pan-Seared Chicken Breast
('chicken_breast_pan_seared', 'Chicken Breast (Pan-Seared)', 185, 29.5, 0.0, 6.8,
 0.0, 0.0, 120, NULL,
 'usda', ARRAY['pan seared chicken breast', 'seared chicken breast', 'chicken breast pan seared', 'pan fried chicken breast no breading'],
 'proteins', NULL, 1, '185 cal/100g. Pan-searing with light oil adds ~20 cal vs baked.', TRUE),

-- ── CHICKEN THIGH VARIANTS ──────────────────────────────────────
-- Base: Chicken Thigh (Cooked) = 209 cal, 26.0P, 0C, 10.9F (already in 1577)

-- Fried Chicken Thigh
('chicken_thigh_fried', 'Chicken Thigh (Fried)', 280, 24.2, 8.5, 16.5,
 0.3, 0.3, 85, NULL,
 'usda', ARRAY['fried chicken thigh', 'chicken thigh fried', 'crispy chicken thigh', 'deep fried chicken thigh'],
 'proteins', NULL, 1, '280 cal/100g. Breading + frying significantly increases calories. Popular in fried chicken.', TRUE),

-- Stir-Fried Chicken Thigh
('chicken_thigh_stir_fried', 'Chicken Thigh (Stir-Fried)', 235, 24.0, 3.5, 13.5,
 0.2, 1.2, 85, NULL,
 'usda', ARRAY['stir fried chicken thigh', 'stir fry chicken thigh', 'chicken thigh stir fry', 'wok chicken thigh'],
 'proteins', NULL, 1, '235 cal/100g. Stir-frying thigh meat with sauce. Juicier than breast for stir-fry.', TRUE),

-- ── EGG VARIANTS ─────────────────────────────────────────────────
-- Base: Egg (large, whole) = ~143 cal, 12.6P, 0.7C, 9.5F per 100g (already in overrides)

-- Boiled Egg (hard-boiled)
('egg_boiled', 'Egg (Boiled)', 155, 12.6, 1.1, 10.6,
 0.0, 1.1, 50, 50,
 'usda', ARRAY['boiled egg', 'hard boiled egg', 'soft boiled egg', 'egg boiled', 'hardboiled egg'],
 'proteins', NULL, 1, '155 cal/100g. 1 large hard-boiled egg (50g): 78 cal. No added fat. Great portable protein.', TRUE),

-- Fried Egg
('egg_fried', 'Egg (Fried)', 196, 13.6, 0.8, 15.3,
 0.0, 0.4, 46, 46,
 'usda', ARRAY['fried egg', 'egg fried', 'sunny side up egg', 'over easy egg', 'pan fried egg', 'egg sunny side up', 'eggs over easy'],
 'proteins', NULL, 1, '196 cal/100g. 1 large fried egg (46g): 90 cal. Frying in oil/butter adds ~15 cal per egg.', TRUE),

-- Scrambled Egg (with milk and butter)
('egg_scrambled', 'Egg (Scrambled)', 149, 10.0, 1.6, 11.1,
 0.0, 1.4, 85, NULL,
 'usda', ARRAY['scrambled egg', 'scrambled eggs', 'egg scrambled', 'eggs scrambled'],
 'proteins', NULL, 1, '149 cal/100g. With milk and butter. Per 2-egg serving (85g): 127 cal. Fluffy and creamy.', TRUE),

-- Poached Egg
('egg_poached', 'Egg (Poached)', 143, 12.6, 0.7, 9.9,
 0.0, 0.4, 50, 50,
 'usda', ARRAY['poached egg', 'egg poached', 'eggs poached'],
 'proteins', NULL, 1, '143 cal/100g. 1 large poached egg (50g): 72 cal. No added fat, cooked in water. Healthiest method.', TRUE),

-- Omelette (with oil)
('omelette', 'Omelette', 183, 11.1, 0.6, 15.2,
 0.0, 0.3, 120, NULL,
 'usda', ARRAY['omelette', 'omelet', 'egg omelette', 'plain omelette', 'cheese omelette', 'veggie omelette'],
 'proteins', NULL, 1, '183 cal/100g plain. 2-egg omelette (~120g): 220 cal. Add-ins increase calories.', TRUE),

-- ── SHRIMP / PRAWN VARIANTS ─────────────────────────────────────

-- Shrimp (Boiled/Steamed)
('shrimp_boiled', 'Shrimp (Boiled/Steamed)', 99, 20.9, 0.2, 1.1,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['boiled shrimp', 'steamed shrimp', 'shrimp boiled', 'shrimp steamed', 'steamed prawns', 'boiled prawns', 'prawns boiled'],
 'proteins', NULL, 1, '99 cal/100g. Very lean protein. Per 3 oz (85g): 84 cal. Minimal fat when not fried.', TRUE),

-- Shrimp (Fried/Breaded)
('shrimp_fried', 'Shrimp (Fried)', 242, 18.2, 11.5, 13.2,
 0.4, 0.5, 85, NULL,
 'usda', ARRAY['fried shrimp', 'breaded shrimp', 'shrimp fried', 'deep fried shrimp', 'crispy shrimp', 'fried prawns', 'tempura shrimp'],
 'proteins', NULL, 1, '242 cal/100g. Breading + frying more than doubles calories vs steamed. Adds carbs and fat.', TRUE),

-- Shrimp (Grilled)
('shrimp_grilled', 'Shrimp (Grilled)', 120, 23.0, 0.5, 2.5,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['grilled shrimp', 'shrimp grilled', 'bbq shrimp', 'grilled prawns', 'prawns grilled'],
 'proteins', NULL, 1, '120 cal/100g. Light brush of oil for grilling. Per 3 oz (85g): 102 cal.', TRUE),

-- Shrimp (Stir-Fried)
('shrimp_stir_fried', 'Shrimp (Stir-Fried)', 165, 19.5, 4.0, 7.5,
 0.3, 1.5, 85, NULL,
 'usda', ARRAY['stir fried shrimp', 'shrimp stir fry', 'stir fry shrimp', 'wok shrimp', 'stir fried prawns', 'prawn stir fry'],
 'proteins', NULL, 1, '165 cal/100g. Wok-fried with oil and sauce. Moderate calorie increase over steamed.', TRUE),

-- ── POTATO VARIANTS ──────────────────────────────────────────────
-- Base: Potato (Boiled) = 87 cal, 1.9P, 20.1C, 0.1F (already in 1577)

-- Baked Potato (with skin)
('potato_baked', 'Potato (Baked)', 93, 2.5, 21.2, 0.1,
 2.2, 1.2, 173, 173,
 'usda', ARRAY['baked potato', 'oven baked potato', 'jacket potato', 'potato baked', 'baked russet potato'],
 'vegetables', NULL, 1, '93 cal/100g with skin. 1 medium (173g): 161 cal. Good source of potassium and vitamin C.', TRUE),

-- Mashed Potato (with butter and milk)
('potato_mashed', 'Mashed Potato', 113, 2.0, 16.0, 4.4,
 1.4, 1.3, 210, NULL,
 'usda', ARRAY['mashed potato', 'mashed potatoes', 'potato mash', 'creamy mashed potatoes', 'buttery mashed potatoes'],
 'vegetables', NULL, 1, '113 cal/100g with butter and milk. 1 cup (210g): 237 cal. Butter and milk add fat.', TRUE),

-- French Fries (deep fried)
('french_fries', 'French Fries', 312, 3.4, 41.4, 14.7,
 3.8, 0.3, 117, NULL,
 'usda', ARRAY['french fries', 'fries', 'chips', 'fried potatoes', 'hot chips', 'deep fried potato', 'freedom fries'],
 'vegetables', NULL, 1, '312 cal/100g. Medium serving (117g): 365 cal. Deep frying triples calories vs baked. Often fried in seed oils.', TRUE),

-- Roasted Potato
('potato_roasted', 'Potato (Roasted)', 149, 2.5, 22.0, 5.6,
 2.0, 1.0, 150, NULL,
 'usda', ARRAY['roasted potato', 'roast potatoes', 'potato roasted', 'oven roasted potatoes', 'crispy roasted potatoes'],
 'vegetables', NULL, 1, '149 cal/100g. Roasting with oil adds ~60 cal vs plain baked. Crispy exterior.', TRUE),

-- Hash Browns (fried)
('hash_browns', 'Hash Browns', 326, 3.2, 35.1, 19.4,
 3.2, 0.5, 72, NULL,
 'usda', ARRAY['hash browns', 'hashbrowns', 'hash brown patty', 'fried hash browns', 'potato hash'],
 'vegetables', NULL, 1, '326 cal/100g. 1 patty (72g): 235 cal. Pan-fried shredded potato. Often cooked in seed oils.', TRUE),

-- Potato (Stir-Fried / Home Fries)
('potato_stir_fried', 'Potato (Stir-Fried/Home Fries)', 180, 2.8, 24.0, 8.0,
 2.0, 1.5, 150, NULL,
 'usda', ARRAY['stir fried potato', 'stir fry potato', 'home fries', 'sauteed potatoes', 'pan fried potatoes', 'aloo stir fry'],
 'vegetables', NULL, 1, '180 cal/100g. Cubed/sliced potato fried in oil with seasoning.', TRUE),

-- ── SWEET POTATO VARIANTS ────────────────────────────────────────
-- Base: Sweet Potato (Baked) = 90 cal, 2.0P, 20.7C, 0.1F (already in 1577)

-- Sweet Potato (Boiled)
('sweet_potato_boiled', 'Sweet Potato (Boiled)', 76, 1.4, 17.7, 0.1,
 2.5, 5.7, 150, NULL,
 'usda', ARRAY['boiled sweet potato', 'sweet potato boiled', 'steamed sweet potato', 'sweet potato steamed'],
 'vegetables', NULL, 1, '76 cal/100g boiled. Lower GI than baked. Good source of beta-carotene.', TRUE),

-- Sweet Potato (Fried)
('sweet_potato_fried', 'Sweet Potato (Fried)', 260, 1.6, 33.0, 13.0,
 3.5, 6.0, 117, NULL,
 'usda', ARRAY['sweet potato fries', 'fried sweet potato', 'sweet potato chips', 'sweet potato fried'],
 'vegetables', NULL, 1, '260 cal/100g. Sweet potato fries have ~190 more cal/100g than baked due to oil absorption.', TRUE),

-- Sweet Potato (Mashed)
('sweet_potato_mashed', 'Sweet Potato (Mashed)', 101, 1.5, 20.0, 1.8,
 2.5, 6.5, 200, NULL,
 'usda', ARRAY['mashed sweet potato', 'sweet potato mash', 'sweet potato puree', 'sweet potato mashed'],
 'vegetables', NULL, 1, '101 cal/100g with a little butter. Per 1 cup (200g): 202 cal.', TRUE),

-- Sweet Potato (Stir-Fried)
('sweet_potato_stir_fried', 'Sweet Potato (Stir-Fried)', 155, 1.8, 22.0, 6.5,
 2.8, 6.5, 150, NULL,
 'usda', ARRAY['stir fried sweet potato', 'sweet potato stir fry', 'sauteed sweet potato', 'sweet potato sauteed'],
 'vegetables', NULL, 1, '155 cal/100g. Cubed sweet potato pan-fried in oil. Between baked and deep-fried in calories.', TRUE),

-- ── TOFU VARIANTS ────────────────────────────────────────────────
-- Base: Tofu (Firm) = 76 cal, 8.1P, 1.9C, 4.8F (already in 1577)

-- Fried Tofu
('tofu_fried', 'Tofu (Fried)', 271, 17.3, 10.5, 20.2,
 0.9, 0.5, 100, NULL,
 'usda', ARRAY['fried tofu', 'deep fried tofu', 'tofu fried', 'crispy tofu', 'agedashi tofu', 'tofu puff'],
 'proteins', NULL, 1, '271 cal/100g. Deep frying tofu absorbs significant oil, tripling calories vs plain firm.', TRUE),

-- Stir-Fried Tofu
('tofu_stir_fried', 'Tofu (Stir-Fried)', 145, 10.5, 4.5, 9.8,
 0.5, 1.0, 126, NULL,
 'usda', ARRAY['stir fried tofu', 'stir fry tofu', 'tofu stir fry', 'wok tofu', 'sauteed tofu', 'pan fried tofu'],
 'proteins', NULL, 1, '145 cal/100g. Stir-frying with sauce adds moderate fat and carbs. Nearly doubles calories vs plain.', TRUE),

-- Baked/Grilled Tofu
('tofu_baked', 'Tofu (Baked/Grilled)', 110, 12.0, 3.5, 5.5,
 0.5, 0.5, 126, NULL,
 'usda', ARRAY['baked tofu', 'grilled tofu', 'tofu baked', 'tofu grilled', 'roasted tofu', 'marinated baked tofu'],
 'proteins', NULL, 1, '110 cal/100g. Light marinade. Between plain and stir-fried. Good lean option.', TRUE),

-- Silken Tofu
('tofu_silken', 'Tofu (Silken/Soft)', 55, 4.8, 2.0, 3.3,
 0.1, 1.3, 126, NULL,
 'usda', ARRAY['silken tofu', 'soft tofu', 'tofu silken', 'tofu soft', 'japanese tofu', 'sundubu'],
 'proteins', NULL, 1, '55 cal/100g. Much softer and lower calorie than firm. Used in soups, smoothies, desserts.', TRUE),

-- ── RICE VARIANTS ────────────────────────────────────────────────
-- Base: White Rice (Cooked) = 130 cal, 2.7P, 28.2C, 0.3F (already in 1577 or earlier overrides)

-- Fried Rice
('fried_rice', 'Fried Rice', 186, 4.3, 25.5, 7.2,
 0.5, 0.5, 200, NULL,
 'usda', ARRAY['fried rice', 'chinese fried rice', 'egg fried rice', 'vegetable fried rice', 'rice fried', 'stir fried rice', 'stir fry rice'],
 'grains', NULL, 1, '186 cal/100g. 1 cup (200g): 372 cal. Oil and egg add ~55 cal vs plain white rice.', TRUE),

-- Chicken Fried Rice
('chicken_fried_rice', 'Chicken Fried Rice', 210, 8.5, 25.0, 8.2,
 0.6, 0.8, 200, NULL,
 'usda', ARRAY['chicken fried rice', 'fried rice with chicken', 'chicken rice fried'],
 'grains', NULL, 1, '210 cal/100g. 1 cup (200g): 420 cal. Added chicken bumps protein. Common takeout staple.', TRUE),

-- Shrimp Fried Rice
('shrimp_fried_rice', 'Shrimp Fried Rice', 195, 7.5, 25.0, 7.5,
 0.5, 0.6, 200, NULL,
 'usda', ARRAY['shrimp fried rice', 'prawn fried rice', 'fried rice with shrimp'],
 'grains', NULL, 1, '195 cal/100g. 1 cup (200g): 390 cal. Shrimp adds lean protein.', TRUE),

-- Steamed Rice (same as plain cooked, explicit name)
('steamed_rice', 'Rice (Steamed)', 130, 2.7, 28.2, 0.3,
 0.4, 0.0, 158, NULL,
 'usda', ARRAY['steamed rice', 'plain steamed rice', 'white steamed rice', 'rice steamed'],
 'grains', NULL, 1, '130 cal/100g. 1 cup (158g): 205 cal. Plain steamed, no added fat.', TRUE),

-- Biryani Rice (per 100g of just the rice portion)
('biryani_rice', 'Biryani Rice', 170, 4.0, 24.0, 6.0,
 0.5, 0.5, 200, NULL,
 'usda', ARRAY['biryani rice', 'biryani', 'chicken biryani rice', 'mutton biryani rice', 'veg biryani rice'],
 'grains', NULL, 1, '170 cal/100g (rice portion). Ghee/oil and spices add fat. Varies by recipe.', TRUE),

-- ── FISH VARIANTS (OTHER) ────────────────────────────────────────

-- Fried Fish (generic white fish, breaded)
('fish_fried', 'Fish (Fried/Breaded)', 232, 15.2, 11.0, 13.8,
 0.5, 0.5, 100, NULL,
 'usda', ARRAY['fried fish', 'breaded fish', 'fish fry', 'fish and chips fish', 'battered fish', 'deep fried fish', 'fish fried'],
 'proteins', NULL, 1, '232 cal/100g. Battered and fried white fish. Breading and oil nearly double calories. Often fried in seed oils.', TRUE),

-- Grilled Fish (generic white fish)
('fish_grilled', 'Fish (Grilled)', 120, 22.5, 0.0, 3.0,
 0.0, 0.0, 100, NULL,
 'usda', ARRAY['grilled fish', 'fish grilled', 'broiled fish', 'fish broiled', 'baked fish', 'fish baked'],
 'proteins', NULL, 1, '120 cal/100g. Lean white fish (cod/tilapia/haddock) grilled with minimal oil.', TRUE),

-- Steamed Fish
('fish_steamed', 'Fish (Steamed)', 110, 22.0, 0.0, 2.2,
 0.0, 0.0, 100, NULL,
 'usda', ARRAY['steamed fish', 'fish steamed', 'fish steamed chinese', 'cantonese steamed fish'],
 'proteins', NULL, 1, '110 cal/100g. No added fat. Popular Chinese preparation with ginger and soy.', TRUE),

-- Fish (Stir-Fried)
('fish_stir_fried', 'Fish (Stir-Fried)', 175, 18.5, 4.5, 9.0,
 0.3, 1.5, 100, NULL,
 'usda', ARRAY['stir fried fish', 'fish stir fry', 'stir fry fish', 'wok fish', 'fish wok fried'],
 'proteins', NULL, 1, '175 cal/100g. Wok-fried fish pieces with sauce. Oil and sauce add fat and carbs.', TRUE),

-- ── TUNA VARIANTS ────────────────────────────────────────────────

-- Tuna Steak (grilled/seared)
('tuna_steak_grilled', 'Tuna Steak (Grilled)', 184, 29.9, 0.0, 6.3,
 0.0, 0.0, 170, NULL,
 'usda', ARRAY['tuna steak', 'grilled tuna', 'seared tuna', 'ahi tuna steak', 'tuna steak grilled', 'tuna steak seared'],
 'proteins', NULL, 1, '184 cal/100g. Per steak (170g): 313 cal. High protein, moderate fat. Rich in omega-3.', TRUE),

-- Tuna (Raw/Sashimi)
('tuna_raw', 'Tuna (Raw/Sashimi)', 130, 28.2, 0.0, 1.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['raw tuna', 'tuna sashimi', 'sashimi tuna', 'ahi tuna raw', 'tuna tartare'],
 'proteins', NULL, 1, '130 cal/100g. Very lean when raw. Popular in sushi. High mercury, limit to 2-3 servings/week.', TRUE),

-- ── BEEF VARIANTS ────────────────────────────────────────────────

-- Beef (Stir-Fried)
('beef_stir_fried', 'Beef (Stir-Fried)', 230, 22.0, 3.5, 14.0,
 0.2, 1.5, 100, NULL,
 'usda', ARRAY['stir fried beef', 'beef stir fry', 'stir fry beef', 'wok beef', 'beef wok fried'],
 'proteins', NULL, 1, '230 cal/100g. Lean beef stir-fried with oil and sauce. Great for Asian dishes.', TRUE),

-- Beef (Grilled/Broiled, lean)
('beef_grilled', 'Beef (Grilled, Lean)', 217, 26.1, 0.0, 11.8,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['grilled beef', 'beef grilled', 'broiled beef', 'lean beef grilled'],
 'proteins', NULL, 1, '217 cal/100g. Lean cuts grilled. Per 3 oz (85g): 184 cal.', TRUE),

-- Beef Jerky
('beef_jerky', 'Beef Jerky', 410, 33.2, 11.0, 25.6,
 0.5, 8.0, 28, NULL,
 'usda', ARRAY['beef jerky', 'jerky', 'dried beef', 'beef biltong'],
 'proteins', NULL, 1, '410 cal/100g. 1 piece (28g): 115 cal. Dehydrated concentrates protein and fat. High sodium.', TRUE),

-- ── PORK VARIANTS ────────────────────────────────────────────────

-- Pork Chop (Grilled)
('pork_chop_grilled', 'Pork Chop (Grilled)', 231, 25.7, 0.0, 13.5,
 0.0, 0.0, 113, NULL,
 'usda', ARRAY['grilled pork chop', 'pork chop grilled', 'pork chop', 'bone in pork chop', 'pork loin chop'],
 'proteins', NULL, 1, '231 cal/100g. 1 chop (113g): 261 cal. Leaner than many assume.', TRUE),

-- Pork (Stir-Fried)
('pork_stir_fried', 'Pork (Stir-Fried)', 250, 22.0, 4.0, 16.0,
 0.2, 1.5, 100, NULL,
 'usda', ARRAY['stir fried pork', 'pork stir fry', 'stir fry pork', 'wok pork', 'pork wok fried'],
 'proteins', NULL, 1, '250 cal/100g. Pork pieces wok-fried with oil and sauce.', TRUE),

-- Pork Belly (cooked)
('pork_belly_cooked', 'Pork Belly (Cooked)', 518, 9.3, 0.0, 53.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['pork belly', 'cooked pork belly', 'roast pork belly', 'crispy pork belly', 'samgyeopsal'],
 'proteins', NULL, 1, '518 cal/100g. Very high in fat. Popular in Korean BBQ (samgyeopsal) and Chinese roast pork.', TRUE),

-- ── LAMB VARIANTS ────────────────────────────────────────────────

-- Lamb (Grilled)
('lamb_grilled', 'Lamb (Grilled)', 258, 25.5, 0.0, 16.5,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['grilled lamb', 'lamb grilled', 'lamb chops grilled', 'lamb kebab', 'lamb leg grilled'],
 'proteins', NULL, 1, '258 cal/100g. Per 3 oz (85g): 219 cal. Rich in B12 and iron.', TRUE),

-- Lamb (Stir-Fried)
('lamb_stir_fried', 'Lamb (Stir-Fried)', 270, 23.5, 3.5, 18.0,
 0.2, 1.0, 100, NULL,
 'usda', ARRAY['stir fried lamb', 'lamb stir fry', 'stir fry lamb', 'wok lamb', 'cumin lamb stir fry'],
 'proteins', NULL, 1, '270 cal/100g. Lamb pieces wok-fried with oil and sauce. Popular in Chinese cuisine.', TRUE),

-- ── VEGETABLE STIR-FRY VARIANTS ──────────────────────────────────

-- Mixed Vegetables (Stir-Fried)
('vegetables_stir_fried', 'Mixed Vegetables (Stir-Fried)', 75, 2.5, 7.5, 4.0,
 2.5, 3.0, 150, NULL,
 'usda', ARRAY['stir fried vegetables', 'vegetable stir fry', 'stir fry vegetables', 'mixed veg stir fry', 'wok vegetables', 'sauteed vegetables', 'stir fried veggies'],
 'vegetables', NULL, 1, '75 cal/100g. 1 cup (150g): 113 cal. Varies by oil amount and vegetables used.', TRUE),

-- Broccoli (Stir-Fried)
('broccoli_stir_fried', 'Broccoli (Stir-Fried)', 65, 3.5, 5.5, 3.5,
 2.8, 1.5, 150, NULL,
 'usda', ARRAY['stir fried broccoli', 'broccoli stir fry', 'sauteed broccoli', 'garlic broccoli stir fry', 'wok broccoli'],
 'vegetables', NULL, 1, '65 cal/100g stir-fried with garlic and oil. Almost doubles calories vs steamed (34 cal).', TRUE),

-- Green Beans (Stir-Fried)
('green_beans_stir_fried', 'Green Beans (Stir-Fried)', 80, 2.5, 7.5, 4.5,
 3.0, 2.0, 125, NULL,
 'usda', ARRAY['stir fried green beans', 'green bean stir fry', 'sauteed green beans', 'dry fried green beans', 'szechuan green beans'],
 'vegetables', NULL, 1, '80 cal/100g. Popular Chinese dry-fried preparation. Oil adds fat vs plain steamed.', TRUE),

-- Bok Choy (Stir-Fried)
('bok_choy_stir_fried', 'Bok Choy (Stir-Fried)', 50, 2.0, 3.5, 3.0,
 1.0, 1.5, 150, NULL,
 'usda', ARRAY['stir fried bok choy', 'bok choy stir fry', 'sauteed bok choy', 'garlic bok choy', 'wok bok choy'],
 'vegetables', NULL, 1, '50 cal/100g stir-fried. Very low calorie even with oil. Common in Asian cooking.', TRUE),

-- Mushrooms (Stir-Fried)
('mushrooms_stir_fried', 'Mushrooms (Stir-Fried)', 55, 2.5, 4.0, 3.5,
 1.2, 1.5, 100, NULL,
 'usda', ARRAY['stir fried mushrooms', 'mushroom stir fry', 'sauteed mushrooms', 'garlic mushrooms', 'wok mushrooms', 'pan fried mushrooms'],
 'vegetables', NULL, 1, '55 cal/100g stir-fried. Mushrooms absorb oil well. From 22 cal raw to 55 cal stir-fried.', TRUE),

-- Eggplant (Stir-Fried)
('eggplant_stir_fried', 'Eggplant (Stir-Fried)', 95, 1.5, 8.0, 6.5,
 3.0, 3.0, 150, NULL,
 'usda', ARRAY['stir fried eggplant', 'eggplant stir fry', 'sauteed eggplant', 'garlic eggplant', 'chinese eggplant stir fry', 'baingan stir fry'],
 'vegetables', NULL, 1, '95 cal/100g. Eggplant absorbs oil like a sponge — raw is only 25 cal/100g.', TRUE),

-- ── NOODLE VARIANTS ──────────────────────────────────────────────

-- Stir-Fried Noodles (chow mein style)
('noodles_stir_fried', 'Stir-Fried Noodles (Chow Mein)', 208, 7.0, 27.0, 8.5,
 1.5, 1.5, 200, NULL,
 'usda', ARRAY['stir fried noodles', 'chow mein', 'lo mein', 'noodle stir fry', 'fried noodles', 'stir fry noodles', 'wok noodles', 'yakisoba', 'pan fried noodles'],
 'grains', NULL, 1, '208 cal/100g. 1 plate (200g): 416 cal. Oil and sauce add significant calories.', TRUE),

-- Pad Thai
('pad_thai', 'Pad Thai', 170, 7.5, 22.0, 6.0,
 0.5, 5.0, 250, NULL,
 'usda', ARRAY['pad thai', 'pad thai noodles', 'thai stir fried noodles', 'shrimp pad thai', 'chicken pad thai'],
 'grains', NULL, 1, '170 cal/100g. 1 plate (250g): 425 cal. Rice noodles with tamarind sauce, egg, peanuts.', TRUE),

-- Singapore Noodles
('singapore_noodles', 'Singapore Noodles', 155, 6.0, 20.0, 5.5,
 1.0, 1.5, 250, NULL,
 'usda', ARRAY['singapore noodles', 'singapore style noodles', 'curry noodles stir fry', 'singapore vermicelli'],
 'grains', NULL, 1, '155 cal/100g. 1 plate (250g): 388 cal. Curry-flavored rice vermicelli stir-fry.', TRUE),

-- ── COMPLETE STIR-FRY DISHES ─────────────────────────────────────

-- Chicken Stir-Fry (with vegetables)
('chicken_stir_fry', 'Chicken Stir-Fry (with Vegetables)', 140, 14.5, 6.5, 6.5,
 1.5, 2.5, 250, NULL,
 'usda', ARRAY['chicken stir fry', 'chicken vegetable stir fry', 'stir fry chicken vegetables', 'chicken and veg stir fry'],
 'prepared_meals', NULL, 1, '140 cal/100g. 1 serving (250g): 350 cal. Complete meal with chicken, vegetables, and sauce.', TRUE),

-- Beef Stir-Fry (with vegetables)
('beef_stir_fry', 'Beef Stir-Fry (with Vegetables)', 155, 13.0, 7.0, 8.5,
 1.5, 2.5, 250, NULL,
 'usda', ARRAY['beef stir fry', 'beef vegetable stir fry', 'stir fry beef vegetables', 'beef and broccoli stir fry'],
 'prepared_meals', NULL, 1, '155 cal/100g. 1 serving (250g): 388 cal. Beef strips with mixed vegetables and sauce.', TRUE),

-- Tofu Stir-Fry (with vegetables)
('tofu_stir_fry', 'Tofu Stir-Fry (with Vegetables)', 95, 6.5, 7.0, 5.0,
 2.0, 2.5, 250, NULL,
 'usda', ARRAY['tofu stir fry', 'tofu vegetable stir fry', 'stir fry tofu vegetables', 'vegetable tofu stir fry'],
 'prepared_meals', NULL, 1, '95 cal/100g. 1 serving (250g): 238 cal. Plant-based protein with mixed vegetables.', TRUE),

-- Shrimp Stir-Fry (with vegetables)
('shrimp_stir_fry', 'Shrimp Stir-Fry (with Vegetables)', 110, 10.5, 6.5, 4.5,
 1.5, 2.5, 250, NULL,
 'usda', ARRAY['shrimp stir fry', 'prawn stir fry', 'shrimp vegetable stir fry', 'stir fry shrimp vegetables'],
 'prepared_meals', NULL, 1, '110 cal/100g. 1 serving (250g): 275 cal. Lean shrimp with mixed vegetables and sauce.', TRUE),

-- ── POPULAR ASIAN STIR-FRY DISHES ────────────────────────────────

-- Kung Pao Chicken
('kung_pao_chicken', 'Kung Pao Chicken', 175, 15.0, 10.0, 8.5,
 1.5, 4.0, 250, NULL,
 'usda', ARRAY['kung pao chicken', 'kung pao', 'gong bao chicken', 'kung po chicken'],
 'prepared_meals', NULL, 1, '175 cal/100g. 1 serving (250g): 438 cal. Spicy stir-fry with peanuts, chili, Sichuan pepper.', TRUE),

-- Beef and Broccoli
('beef_and_broccoli', 'Beef and Broccoli', 145, 12.0, 7.5, 7.5,
 1.5, 3.0, 250, NULL,
 'usda', ARRAY['beef and broccoli', 'beef broccoli', 'broccoli beef', 'beef broccoli stir fry', 'chinese beef broccoli'],
 'prepared_meals', NULL, 1, '145 cal/100g. 1 serving (250g): 363 cal. Classic Chinese-American stir-fry dish.', TRUE),

-- Cashew Chicken
('cashew_chicken', 'Cashew Chicken', 195, 14.5, 11.0, 10.5,
 1.0, 4.0, 250, NULL,
 'usda', ARRAY['cashew chicken', 'chicken cashew', 'cashew chicken stir fry', 'thai cashew chicken'],
 'prepared_meals', NULL, 1, '195 cal/100g. 1 serving (250g): 488 cal. Cashews add healthy fats but bump calories.', TRUE),

-- Sweet and Sour Chicken
('sweet_and_sour_chicken', 'Sweet and Sour Chicken', 210, 11.5, 22.0, 8.5,
 0.5, 14.0, 250, NULL,
 'usda', ARRAY['sweet and sour chicken', 'sweet sour chicken', 'chinese sweet and sour chicken'],
 'prepared_meals', NULL, 1, '210 cal/100g. Battered chicken in sugary sauce. High sugar content (14g/100g).', TRUE),

-- Teriyaki Chicken
('teriyaki_chicken', 'Teriyaki Chicken', 180, 18.0, 10.0, 7.5,
 0.0, 8.0, 200, NULL,
 'usda', ARRAY['teriyaki chicken', 'chicken teriyaki', 'teriyaki chicken stir fry'],
 'prepared_meals', NULL, 1, '180 cal/100g. 1 serving (200g): 360 cal. Sweet soy-based sauce adds sugar and calories.', TRUE),

-- General Tso's Chicken
('general_tsos_chicken', 'General Tso''s Chicken', 245, 12.5, 18.0, 14.0,
 0.5, 10.0, 250, NULL,
 'usda', ARRAY['general tsos chicken', 'general tso chicken', 'general tsos', 'tso chicken'],
 'prepared_meals', NULL, 1, '245 cal/100g. Deep-fried battered chicken in sweet/spicy sauce. High calorie Chinese takeout classic.', TRUE),

-- Mapo Tofu
('mapo_tofu', 'Mapo Tofu', 105, 6.5, 4.0, 7.0,
 0.5, 0.5, 250, NULL,
 'usda', ARRAY['mapo tofu', 'mapo doufu', 'spicy tofu', 'sichuan tofu', 'ma po tofu'],
 'prepared_meals', NULL, 1, '105 cal/100g. 1 serving (250g): 263 cal. Sichuan classic with silken tofu and minced pork.', TRUE),

-- ── DUCK VARIANTS ────────────────────────────────────────────────

-- Peking Duck
('peking_duck', 'Peking Duck', 337, 19.0, 1.0, 28.4,
 0.0, 0.5, 85, NULL,
 'usda', ARRAY['peking duck', 'beijing duck', 'duck peking', 'roast duck chinese', 'crispy duck'],
 'proteins', NULL, 1, '337 cal/100g with skin. Roasted duck is very high in fat from skin and fat layer.', TRUE),

-- Duck (Stir-Fried)
('duck_stir_fried', 'Duck (Stir-Fried)', 270, 19.5, 3.5, 19.5,
 0.2, 1.5, 100, NULL,
 'usda', ARRAY['stir fried duck', 'duck stir fry', 'stir fry duck', 'wok duck', 'duck breast stir fry'],
 'proteins', NULL, 1, '270 cal/100g. Rich and fatty meat. Stir-frying with sauce.', TRUE)

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


-- ==========================================
-- PART B: UPDATE VARIANT_NAMES FOR EXISTING FOODS
-- Adds size variants, Hindi names, cooking methods as search aliases
-- ==========================================

-- Fruits
UPDATE food_nutrition_overrides SET variant_names = ARRAY['banana', 'medium banana', 'large banana', 'small banana', 'ripe banana', 'plantain', 'kela', 'green banana', 'baby banana', '1 banana', 'one banana', 'half banana'] WHERE food_name_normalized = 'banana';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['apple', 'medium apple', 'red apple', 'green apple', 'gala apple', 'fuji apple', 'granny smith apple', 'honeycrisp apple', 'small apple', 'large apple', 'seb', '1 apple', 'one apple', 'sliced apple'] WHERE food_name_normalized = 'apple';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['orange', 'navel orange', 'medium orange', 'valencia orange', 'mandarin orange', 'blood orange', 'small orange', 'large orange', 'santra', 'narangi', '1 orange'] WHERE food_name_normalized = 'orange';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['mango', 'fresh mango', 'sliced mango', 'mango slices', 'aam', 'ripe mango', 'raw mango', 'alphonso mango', 'green mango', 'large mango', 'small mango', '1 mango'] WHERE food_name_normalized = 'mango';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['strawberry', 'strawberries', 'fresh strawberries', 'sliced strawberries', 'frozen strawberries', 'diced strawberries'] WHERE food_name_normalized = 'strawberry';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['blueberry', 'blueberries', 'fresh blueberries', 'wild blueberries', 'frozen blueberries'] WHERE food_name_normalized = 'blueberry';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['grapes', 'red grapes', 'green grapes', 'seedless grapes', 'thompson grapes', 'concord grapes', 'black grapes', 'angoor', '1 cup grapes'] WHERE food_name_normalized = 'grapes';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['watermelon', 'watermelon slices', 'seedless watermelon', 'watermelon cubes', 'tarbooz', '1 cup watermelon', 'watermelon diced'] WHERE food_name_normalized = 'watermelon';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['pineapple', 'pineapple slices', 'fresh pineapple', 'diced pineapple', 'ananas', 'pineapple chunks', '1 cup pineapple'] WHERE food_name_normalized = 'pineapple';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['avocado', 'medium avocado', 'large avocado', 'small avocado', 'hass avocado', 'ripe avocado', 'half avocado', '1 avocado', 'sliced avocado', 'mashed avocado'] WHERE food_name_normalized = 'avocado';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['peach', 'peaches', 'medium peach', 'large peach', 'fresh peach', 'yellow peach', 'white peach', 'aadoo', '1 peach'] WHERE food_name_normalized = 'peach';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['pear', 'pears', 'medium pear', 'green pear', 'bartlett pear', 'anjou pear', 'bosc pear', 'nashpati', '1 pear'] WHERE food_name_normalized = 'pear';

-- Vegetables
UPDATE food_nutrition_overrides SET variant_names = ARRAY['broccoli', 'steamed broccoli', 'raw broccoli', 'broccoli florets', 'fresh broccoli', 'boiled broccoli', '1 cup broccoli'] WHERE food_name_normalized = 'broccoli';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['spinach', 'raw spinach', 'baby spinach', 'cooked spinach', 'palak', 'fresh spinach', '1 cup spinach', 'spinach leaves'] WHERE food_name_normalized = 'spinach';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['carrot', 'carrots', 'raw carrot', 'medium carrot', 'large carrot', 'baby carrots', 'gajar', '1 carrot', 'sliced carrots', 'diced carrots', 'shredded carrot'] WHERE food_name_normalized = 'carrot';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['tomato', 'tomatoes', 'medium tomato', 'large tomato', 'cherry tomatoes', 'grape tomatoes', 'roma tomato', 'tamatar', '1 tomato', 'sliced tomato', 'diced tomato'] WHERE food_name_normalized = 'tomato';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['onion', 'onions', 'medium onion', 'large onion', 'small onion', 'red onion', 'white onion', 'yellow onion', 'pyaz', 'pyaaz', '1 onion', 'diced onion', 'sliced onion'] WHERE food_name_normalized = 'onion';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['cucumber', 'cucumbers', 'medium cucumber', 'sliced cucumber', 'english cucumber', 'kheera', '1 cucumber', 'diced cucumber'] WHERE food_name_normalized = 'cucumber';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['bell pepper', 'bell peppers', 'red bell pepper', 'green bell pepper', 'yellow bell pepper', 'orange bell pepper', 'capsicum', 'shimla mirch', '1 bell pepper', 'sliced bell pepper'] WHERE food_name_normalized = 'bell_pepper';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['potato', 'potatoes', 'medium potato', 'large potato', 'small potato', 'russet potato', 'red potato', 'yukon gold potato', 'aloo', '1 potato', 'boiled potato'] WHERE food_name_normalized = 'potato_boiled';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['sweet potato', 'sweet potatoes', 'medium sweet potato', 'large sweet potato', 'small sweet potato', 'baked sweet potato', 'yam', 'shakarkandi', '1 sweet potato'] WHERE food_name_normalized = 'sweet_potato_baked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['corn', 'corn on the cob', 'sweet corn', 'corn kernels', 'fresh corn', 'bhutta', 'maize', 'makka', '1 ear corn'] WHERE food_name_normalized = 'corn';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['cauliflower', 'raw cauliflower', 'steamed cauliflower', 'cauliflower florets', 'phool gobi', 'gobi', '1 cup cauliflower'] WHERE food_name_normalized = 'cauliflower';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['cabbage', 'green cabbage', 'raw cabbage', 'shredded cabbage', 'patta gobi', 'band gobi', '1 cup cabbage'] WHERE food_name_normalized = 'cabbage';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['zucchini', 'zucchinis', 'medium zucchini', 'courgette', 'summer squash', 'sliced zucchini', '1 zucchini', 'grilled zucchini'] WHERE food_name_normalized = 'zucchini';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['eggplant', 'aubergine', 'medium eggplant', 'baingan', 'brinjal', '1 eggplant', 'sliced eggplant', 'grilled eggplant'] WHERE food_name_normalized = 'eggplant';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['mushroom', 'mushrooms', 'white mushroom', 'button mushrooms', 'cremini mushrooms', 'portobello mushroom', 'sliced mushrooms', 'khumbi', '1 cup mushrooms'] WHERE food_name_normalized = 'mushroom';

-- Proteins - update existing base entries with more variants
UPDATE food_nutrition_overrides SET variant_names = ARRAY['chicken breast', 'grilled chicken breast', 'grilled chicken', 'boneless skinless chicken breast', 'chicken breast grilled', 'plain chicken breast', 'skinless chicken breast'] WHERE food_name_normalized = 'chicken_breast_grilled';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['chicken thigh', 'cooked chicken thigh', 'boneless chicken thigh', 'skinless chicken thigh', 'chicken thigh cooked', 'roasted chicken thigh'] WHERE food_name_normalized = 'chicken_thigh_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['salmon', 'cooked salmon', 'atlantic salmon', 'salmon fillet', 'salmon cooked', 'plain salmon'] WHERE food_name_normalized = 'salmon_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['ground beef', 'minced beef', 'ground beef 80/20', 'beef mince', 'hamburger meat', 'keema', 'ground chuck'] WHERE food_name_normalized = 'ground_beef_80_20';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['tofu', 'firm tofu', 'extra firm tofu', 'bean curd', 'soy tofu', 'plain tofu'] WHERE food_name_normalized = 'tofu_firm';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['shrimp', 'prawns', 'jhinga', 'medium shrimp', 'large shrimp', 'jumbo shrimp', 'tiger prawns'] WHERE food_name_normalized = 'shrimp_boiled';

-- Dairy
UPDATE food_nutrition_overrides SET variant_names = ARRAY['whole milk', 'full fat milk', 'full cream milk', 'cow milk', 'regular milk', 'doodh', '1 glass milk', '1 cup milk'] WHERE food_name_normalized = 'whole_milk';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['greek yogurt', 'plain greek yogurt', 'full fat greek yogurt', 'nonfat greek yogurt', 'greek yoghurt', '1 cup greek yogurt'] WHERE food_name_normalized = 'greek_yogurt_plain';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['cheddar cheese', 'cheddar', 'sharp cheddar', 'mild cheddar', 'sliced cheddar', '1 slice cheddar', '1 oz cheddar'] WHERE food_name_normalized = 'cheddar_cheese';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['cottage cheese', 'paneer', 'low fat cottage cheese', 'creamed cottage cheese', '1 cup cottage cheese'] WHERE food_name_normalized = 'cottage_cheese';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['butter', 'unsalted butter', 'salted butter', 'makhan', '1 tbsp butter', '1 pat butter', 'stick butter'] WHERE food_name_normalized = 'butter';

-- Grains
UPDATE food_nutrition_overrides SET variant_names = ARRAY['white rice', 'cooked white rice', 'plain rice', 'steamed white rice', 'chawal', 'boiled rice', '1 cup rice', 'basmati rice cooked', 'jasmine rice cooked'] WHERE food_name_normalized = 'white_rice_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['brown rice', 'cooked brown rice', 'steamed brown rice', 'whole grain rice', '1 cup brown rice'] WHERE food_name_normalized = 'brown_rice_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['oatmeal', 'oats', 'cooked oats', 'porridge', 'rolled oats cooked', 'daliya', '1 bowl oatmeal', '1 cup oatmeal'] WHERE food_name_normalized = 'oatmeal_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['quinoa', 'cooked quinoa', 'quinoa cooked', '1 cup quinoa'] WHERE food_name_normalized = 'quinoa_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['pasta', 'cooked pasta', 'spaghetti cooked', 'penne cooked', 'fusilli cooked', 'boiled pasta', '1 cup pasta', 'macaroni cooked'] WHERE food_name_normalized = 'pasta_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['whole wheat bread', 'whole grain bread', 'wheat bread', 'brown bread', '1 slice whole wheat bread', '1 slice wheat bread'] WHERE food_name_normalized = 'whole_wheat_bread';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['white bread', 'sandwich bread', 'bread', 'plain bread', 'toast bread', '1 slice bread', '1 slice white bread', 'roti bread'] WHERE food_name_normalized = 'white_bread';

-- Beans / Legumes
UPDATE food_nutrition_overrides SET variant_names = ARRAY['chickpeas', 'garbanzo beans', 'canned chickpeas', 'cooked chickpeas', 'chana', 'chole', 'kabuli chana', '1 cup chickpeas'] WHERE food_name_normalized = 'chickpeas_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['black beans', 'cooked black beans', 'canned black beans', 'rajma kala', '1 cup black beans'] WHERE food_name_normalized = 'black_beans_cooked';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['lentils', 'cooked lentils', 'dal', 'daal', 'masoor dal', 'brown lentils', 'red lentils cooked', '1 cup lentils'] WHERE food_name_normalized = 'lentils_cooked';

-- Nut Butters
UPDATE food_nutrition_overrides SET variant_names = ARRAY['peanut butter', 'pb', 'creamy peanut butter', 'crunchy peanut butter', 'natural peanut butter', 'smooth peanut butter', '1 tbsp peanut butter', '2 tbsp peanut butter'] WHERE food_name_normalized = 'peanut_butter';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['almond butter', 'almond spread', 'natural almond butter', '1 tbsp almond butter', '2 tbsp almond butter'] WHERE food_name_normalized = 'almond_butter';

-- Common Oils — add cooking method variants as search terms
UPDATE food_nutrition_overrides SET variant_names = ARRAY['olive oil', 'extra virgin olive oil', 'evoo', 'virgin olive oil', 'light olive oil', '1 tbsp olive oil', '1 tsp olive oil'] WHERE food_name_normalized = 'olive_oil';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['coconut oil', 'virgin coconut oil', 'refined coconut oil', '1 tbsp coconut oil', '1 tsp coconut oil', 'nariyal tel'] WHERE food_name_normalized = 'coconut_oil';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['avocado oil', 'refined avocado oil', '1 tbsp avocado oil', '1 tsp avocado oil'] WHERE food_name_normalized = 'avocado_oil';

-- Nuts
UPDATE food_nutrition_overrides SET variant_names = ARRAY['almonds', 'raw almonds', 'roasted almonds', 'whole almonds', 'badam', '1 oz almonds', 'handful almonds', 'almond nuts'] WHERE food_name_normalized = 'almonds';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['peanuts', 'raw peanuts', 'roasted peanuts', 'moongphali', 'groundnuts', '1 oz peanuts', 'handful peanuts', 'salted peanuts'] WHERE food_name_normalized = 'peanuts';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['cashews', 'raw cashews', 'roasted cashews', 'kaju', '1 oz cashews', 'handful cashews', 'salted cashews'] WHERE food_name_normalized = 'cashews';
UPDATE food_nutrition_overrides SET variant_names = ARRAY['walnuts', 'walnut halves', 'raw walnuts', 'akhrot', '1 oz walnuts', 'handful walnuts'] WHERE food_name_normalized = 'walnuts';
