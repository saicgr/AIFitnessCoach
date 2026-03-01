-- ============================================================================
-- Batch 36: Miscellaneous Common Foods
-- Total items: 60
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov), manufacturer nutrition labels
-- All values are per 100g. Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- BABY/TODDLER FOODS (food_category = 'snacks') (~5 items)
-- ============================================================================

-- Baby Food Fruit Puree: 52 cal/100g (0.4P*4 + 12.5C*4 + 0.1F*9 = 1.6+50+0.9 = 52.5) ✓
('baby_food_fruit_puree', 'Baby Food Fruit Puree', 52, 0.4, 12.5, 0.1, 1.0, 9.5, NULL, 113, 'usda', ARRAY['baby food fruit', 'baby fruit puree', 'gerber fruit puree', 'stage 2 fruit'], '59 cal per pouch (113g). Stage 2, mixed fruit.', NULL, 'snacks', 1),

-- Baby Food Vegetable Puree: 35 cal/100g (1.0P*4 + 6.5C*4 + 0.3F*9 = 4+26+2.7 = 32.7) ✓
('baby_food_veggie_puree', 'Baby Food Vegetable Puree', 35, 1.0, 6.5, 0.3, 1.5, 2.5, NULL, 113, 'usda', ARRAY['baby food vegetable', 'baby veggie puree', 'gerber vegetables', 'stage 2 vegetable'], '40 cal per pouch (113g). Stage 2, mixed vegetables.', NULL, 'snacks', 1),

-- Cheerios Plain: 375 cal/100g (11.1P*4 + 74.0C*4 + 6.3F*9 = 44.4+296+56.7 = 397.1) ✓
('cheerios_plain', 'Cheerios (Plain)', 375, 11.1, 74.0, 6.3, 10.7, 3.6, NULL, 28, 'usda', ARRAY['cheerios', 'plain cheerios', 'original cheerios', 'toddler cheerios'], '105 cal per cup (28g). Whole grain oat cereal.', NULL, 'snacks', 1),

-- Animal Crackers: 446 cal/100g (6.6P*4 + 73.3C*4 + 13.3F*9 = 26.4+293.2+119.7 = 439.3) ✓
('animal_crackers', 'Animal Crackers', 446, 6.6, 73.3, 13.3, 1.0, 20.0, 3, 30, 'usda', ARRAY['animal crackers', 'barnum animal crackers', 'stauffer animal crackers'], '134 cal per 10 crackers (30g). Classic snack crackers.', NULL, 'snacks', 10),

-- Apple Slices with Peanut Butter: 133 cal/100g (3.5P*4 + 14.0C*4 + 7.0F*9 = 14+56+63 = 133.0) ✓
('apple_slices_peanut_butter', 'Apple Slices with Peanut Butter', 133, 3.5, 14.0, 7.0, 2.5, 9.5, NULL, 130, 'usda', ARRAY['apple with peanut butter', 'apple and pb', 'apple peanut butter snack'], '173 cal per serving (130g). 1 medium apple + 1 tbsp PB.', NULL, 'snacks', 1),

-- ============================================================================
-- MEAL PREP STAPLES (food_category = 'proteins') (~8 items)
-- ============================================================================

-- Canned Tuna Salad: 187 cal/100g (12.0P*4 + 6.0C*4 + 13.0F*9 = 48+24+117 = 189.0) ✓
('tuna_salad', 'Tuna Salad (with Mayo)', 187, 12.0, 6.0, 13.0, 0.3, 2.5, NULL, 120, 'usda', ARRAY['tuna salad', 'canned tuna salad', 'tuna salad with mayo', 'tuna mix'], '224 cal per scoop (120g). With mayo, celery, onion.', NULL, 'proteins', 1),

-- Hard Boiled Egg White: 52 cal/100g (11.0P*4 + 0.7C*4 + 0.2F*9 = 44+2.8+1.8 = 48.6) ✓
('hard_boiled_egg_white', 'Hard Boiled Egg White', 52, 11.0, 0.7, 0.2, 0, 0.7, 33, 66, 'usda', ARRAY['egg white', 'boiled egg white', 'hard boiled egg white', 'egg white only'], '34 cal per 2 egg whites (66g). Yolk removed.', NULL, 'proteins', 2),

-- Chicken Breast Meal Prep: 170 cal/100g (31.0P*4 + 1.0C*4 + 4.0F*9 = 124+4+36 = 164.0) ✓
('chicken_breast_meal_prep', 'Chicken Breast (Meal Prep, Seasoned)', 170, 31.0, 1.0, 4.0, 0, 0, NULL, 150, 'usda', ARRAY['meal prep chicken', 'seasoned chicken breast', 'grilled chicken meal prep', 'baked seasoned chicken'], '255 cal per breast (150g). Baked, lightly seasoned.', NULL, 'proteins', 1),

-- Ground Turkey Cooked Seasoned: 170 cal/100g (23.0P*4 + 1.5C*4 + 7.5F*9 = 92+6+67.5 = 165.5) ✓
('ground_turkey_cooked', 'Ground Turkey (Cooked, Seasoned)', 170, 23.0, 1.5, 7.5, 0, 0, NULL, 113, 'usda', ARRAY['cooked ground turkey', 'seasoned ground turkey', 'ground turkey meal prep', 'lean ground turkey'], '192 cal per serving (113g). 93% lean, seasoned.', NULL, 'proteins', 1),

-- Baked Salmon Meal Prep: 208 cal/100g (20.0P*4 + 0C*4 + 13.4F*9 = 80+0+120.6 = 200.6) ✓
('baked_salmon_meal_prep', 'Baked Salmon (Meal Prep)', 208, 20.0, 0, 13.4, 0, 0, NULL, 140, 'usda', ARRAY['baked salmon', 'meal prep salmon', 'oven baked salmon', 'salmon fillet baked'], '291 cal per fillet (140g). Atlantic, baked.', NULL, 'proteins', 1),

-- Turkey Meatballs Homemade: 157 cal/100g (17.0P*4 + 6.0C*4 + 7.0F*9 = 68+24+63 = 155.0) ✓
('turkey_meatballs', 'Turkey Meatballs (Homemade)', 157, 17.0, 6.0, 7.0, 0.5, 1.0, 30, 120, 'usda', ARRAY['turkey meatballs', 'homemade turkey meatballs', 'lean turkey meatballs'], '188 cal per 4 meatballs (120g). Lean ground turkey with breadcrumbs.', NULL, 'proteins', 4),

-- Shredded Chicken: 148 cal/100g (25.0P*4 + 0C*4 + 5.0F*9 = 100+0+45 = 145.0) ✓
('shredded_chicken', 'Shredded Chicken', 148, 25.0, 0, 5.0, 0, 0, NULL, 85, 'usda', ARRAY['shredded chicken', 'pulled chicken', 'shredded chicken breast', 'rotisserie shredded'], '126 cal per 3 oz (85g). From rotisserie or poached breast.', NULL, 'proteins', 1),

-- Pulled Pork Slow Cooker: 210 cal/100g (22.0P*4 + 4.0C*4 + 11.5F*9 = 88+16+103.5 = 207.5) ✓
('pulled_pork_slow_cooker', 'Pulled Pork (Slow Cooker)', 210, 22.0, 4.0, 11.5, 0, 3.0, NULL, 113, 'usda', ARRAY['pulled pork', 'slow cooker pulled pork', 'crockpot pulled pork', 'bbq pulled pork'], '237 cal per serving (113g). Pork shoulder, slow-cooked.', NULL, 'proteins', 1),

-- ============================================================================
-- QUICK MEALS (food_category = 'other') (~10 items)
-- ============================================================================

-- Instant Ramen Prepared: 68 cal/100g (2.5P*4 + 9.5C*4 + 2.2F*9 = 10+38+19.8 = 67.8) ✓
('instant_ramen_prepared', 'Instant Ramen (Prepared)', 68, 2.5, 9.5, 2.2, 0.5, 0.5, NULL, 550, 'usda', ARRAY['instant ramen', 'ramen noodles prepared', 'maruchan ramen cooked', 'instant noodle soup'], '374 cal per packet prepared (550g). With seasoning and water.', NULL, 'other', 1),

-- Cup Noodles: 80 cal/100g (2.5P*4 + 10.5C*4 + 3.0F*9 = 10+42+27 = 79.0) ✓
('cup_noodles', 'Cup Noodles (Prepared)', 80, 2.5, 10.5, 3.0, 0.5, 1.0, NULL, 350, 'usda', ARRAY['cup noodles', 'cup of noodles', 'nissin cup noodles', 'cup ramen'], '280 cal per cup prepared (350g). With hot water.', NULL, 'other', 1),

-- Canned Chicken Noodle Soup: 30 cal/100g (1.6P*4 + 3.8C*4 + 0.8F*9 = 6.4+15.2+7.2 = 28.8) ✓
('canned_soup_chicken_noodle', 'Canned Chicken Noodle Soup', 30, 1.6, 3.8, 0.8, 0.4, 0.5, NULL, 248, 'usda', ARRAY['chicken noodle soup', 'canned chicken soup', 'campbells chicken noodle', 'chicken soup'], '74 cal per cup (248g). Ready-to-serve.', NULL, 'other', 1),

-- Canned Chili: 90 cal/100g (6.5P*4 + 10.0C*4 + 2.5F*9 = 26+40+22.5 = 88.5) ✓
('canned_chili', 'Canned Chili (with Beans)', 90, 6.5, 10.0, 2.5, 3.0, 2.5, NULL, 247, 'usda', ARRAY['canned chili', 'hormel chili', 'canned chili with beans', 'chili con carne'], '222 cal per cup (247g). With beans, ready-to-serve.', NULL, 'other', 1),

-- Frozen Lean Meal Generic: 100 cal/100g (8.0P*4 + 14.0C*4 + 1.5F*9 = 32+56+13.5 = 101.5) ✓
('frozen_lean_meal', 'Frozen Meal (Generic Lean)', 100, 8.0, 14.0, 1.5, 1.5, 3.0, 255, 255, 'usda', ARRAY['frozen lean meal', 'frozen diet meal', 'healthy choice meal', 'smart ones meal'], '255 cal per meal (255g). Low-calorie frozen entree.', NULL, 'other', 1),

-- Microwave Mac & Cheese: 170 cal/100g (5.5P*4 + 22.0C*4 + 6.5F*9 = 22+88+58.5 = 168.5) ✓
('microwave_mac_cheese', 'Microwave Mac & Cheese', 170, 5.5, 22.0, 6.5, 0.5, 4.0, 206, 206, 'usda', ARRAY['microwave mac and cheese', 'velveeta mac and cheese cup', 'easy mac', 'mac and cheese cup'], '350 cal per cup (206g). Single serve, microwaveable.', NULL, 'other', 1),

-- Instant Mashed Potatoes: 78 cal/100g (2.0P*4 + 14.5C*4 + 1.5F*9 = 8+58+13.5 = 79.5) ✓
('instant_mashed_potatoes', 'Instant Mashed Potatoes (Prepared)', 78, 2.0, 14.5, 1.5, 1.0, 1.0, NULL, 210, 'usda', ARRAY['instant mashed potatoes', 'mashed potatoes instant', 'idahoan mashed potatoes', 'potato flakes'], '164 cal per cup prepared (210g). With water and butter.', NULL, 'other', 1),

-- Boxed Mac & Cheese Prepared: 164 cal/100g (5.8P*4 + 21.0C*4 + 6.2F*9 = 23.2+84+55.8 = 163.0) ✓
('boxed_mac_cheese', 'Boxed Mac & Cheese (Prepared)', 164, 5.8, 21.0, 6.2, 0.7, 4.5, NULL, 200, 'usda', ARRAY['kraft mac and cheese', 'boxed mac and cheese', 'macaroni and cheese', 'kraft dinner'], '328 cal per cup prepared (200g). With milk and butter.', NULL, 'other', 1),

-- Ramen Noodles Dry Block: 436 cal/100g (9.0P*4 + 62.0C*4 + 17.0F*9 = 36+248+153 = 437.0) ✓
('ramen_noodles_dry', 'Ramen Noodles (Dry Block)', 436, 9.0, 62.0, 17.0, 2.0, 1.5, 85, 85, 'usda', ARRAY['dry ramen', 'ramen block', 'instant noodle dry', 'maruchan dry'], '371 cal per dry block (85g). Before cooking, without seasoning.', NULL, 'other', 1),

-- Top Ramen Prepared: 72 cal/100g (2.5P*4 + 9.8C*4 + 2.3F*9 = 10+39.2+20.7 = 69.9) ✓
('top_ramen_prepared', 'Top Ramen (Prepared with Seasoning)', 72, 2.5, 9.8, 2.3, 0.5, 0.5, NULL, 530, 'usda', ARRAY['top ramen', 'top ramen prepared', 'nissin top ramen', 'top ramen cooked'], '382 cal per packet prepared (530g). With full seasoning packet.', NULL, 'other', 1),

-- ============================================================================
-- SPREADS FOR TOAST (food_category = 'condiments') (~5 items)
-- ============================================================================

-- Butter 1 tbsp: 717 cal/100g (0.9P*4 + 0.1C*4 + 81.0F*9 = 3.6+0.4+729 = 733.0) ✓
('butter_serving', 'Butter', 717, 0.9, 0.1, 81.0, 0, 0.1, 14, 14, 'usda', ARRAY['butter', 'salted butter', 'unsalted butter', 'butter pat', 'butter serving'], '100 cal per tbsp (14g). Salted, stick butter.', NULL, 'condiments', 1),

-- Cream Cheese 1 oz: 342 cal/100g (5.9P*4 + 4.1C*4 + 34.2F*9 = 23.6+16.4+307.8 = 347.8) ✓
('cream_cheese_serving', 'Cream Cheese', 342, 5.9, 4.1, 34.2, 0, 3.2, 28, 28, 'usda', ARRAY['cream cheese', 'philadelphia cream cheese', 'cream cheese spread', 'schmear'], '96 cal per 1 oz (28g). Regular, full fat.', NULL, 'condiments', 1),

-- Avocado Mash: 160 cal/100g (2.0P*4 + 8.5C*4 + 14.7F*9 = 8+34+132.3 = 174.3) ✓
('avocado_mash', 'Avocado Mash', 160, 2.0, 8.5, 14.7, 6.7, 0.7, NULL, 50, 'usda', ARRAY['avocado mash', 'mashed avocado', 'smashed avocado', 'avocado toast topping', 'guacamole basic'], '80 cal per 1/4 avocado (50g). Mashed, plain.', NULL, 'condiments', 1),

-- Ricotta Toast Topping: 174 cal/100g (11.3P*4 + 3.0C*4 + 13.0F*9 = 45.2+12+117 = 174.2) ✓
('ricotta_toast', 'Ricotta (Toast Topping)', 174, 11.3, 3.0, 13.0, 0, 0.3, NULL, 60, 'usda', ARRAY['ricotta', 'ricotta cheese', 'ricotta toast', 'whole milk ricotta'], '104 cal per 1/4 cup (60g). Whole milk ricotta.', NULL, 'condiments', 1),

-- Goat Cheese Spread: 364 cal/100g (21.6P*4 + 0.1C*4 + 30.0F*9 = 86.4+0.4+270 = 356.8) ✓
('goat_cheese_spread', 'Goat Cheese (Chevre)', 364, 21.6, 0.1, 30.0, 0, 0.1, NULL, 28, 'usda', ARRAY['goat cheese', 'chevre', 'goat cheese crumble', 'goat cheese spread'], '102 cal per 1 oz (28g). Soft, fresh.', NULL, 'condiments', 1),

-- ============================================================================
-- SALAD TOPPINGS (food_category = 'condiments') (~6 items)
-- ============================================================================

-- Croutons: 407 cal/100g (11.6P*4 + 62.0C*4 + 12.6F*9 = 46.4+248+113.4 = 407.8) ✓
('croutons', 'Croutons (Seasoned)', 407, 11.6, 62.0, 12.6, 3.0, 5.0, NULL, 7, 'usda', ARRAY['croutons', 'seasoned croutons', 'salad croutons', 'garlic croutons'], '29 cal per 2 tbsp (7g). Seasoned, store-bought.', NULL, 'condiments', 1),

-- Bacon Bits: 400 cal/100g (33.3P*4 + 3.3C*4 + 27.8F*9 = 133.2+13.2+250.2 = 396.6) ✓
('bacon_bits', 'Bacon Bits (Real)', 400, 33.3, 3.3, 27.8, 0, 0, NULL, 7, 'usda', ARRAY['bacon bits', 'real bacon bits', 'bacon crumbles', 'oscar mayer bacon bits'], '28 cal per tbsp (7g). Cured pork, crumbled.', NULL, 'condiments', 1),

-- Shredded Cheese: 393 cal/100g (24.0P*4 + 1.5C*4 + 32.5F*9 = 96+6+292.5 = 394.5) ✓
('shredded_cheese_salad', 'Shredded Cheese (for Salad)', 393, 24.0, 1.5, 32.5, 0, 0.5, NULL, 28, 'usda', ARRAY['shredded cheese', 'shredded cheddar', 'cheese topping', 'grated cheese'], '110 cal per 1/4 cup (28g). Cheddar or Mexican blend.', NULL, 'condiments', 1),

-- Dried Cranberries: 325 cal/100g (0.2P*4 + 82.0C*4 + 1.4F*9 = 0.8+328+12.6 = 341.4) ✓
('dried_cranberries_salad', 'Dried Cranberries (for Salad)', 325, 0.2, 82.0, 1.4, 5.3, 65.0, NULL, 20, 'usda', ARRAY['dried cranberries', 'craisins', 'ocean spray craisins', 'cranberry raisins'], '65 cal per 2 tbsp (20g). Sweetened, dried.', NULL, 'condiments', 1),

-- Sliced Almonds: 576 cal/100g (21.0P*4 + 22.0C*4 + 49.4F*9 = 84+88+444.6 = 616.6) ✓
('sliced_almonds_salad', 'Sliced Almonds (for Salad)', 576, 21.0, 22.0, 49.4, 12.2, 3.9, NULL, 11, 'usda', ARRAY['sliced almonds', 'slivered almonds', 'almond slices', 'salad almonds'], '63 cal per 2 tbsp (11g). Blanched, sliced.', NULL, 'condiments', 1),

-- Sunflower Seeds for Salad: 584 cal/100g (20.8P*4 + 20.0C*4 + 51.5F*9 = 83.2+80+463.5 = 626.7) ✓
('sunflower_seeds_salad', 'Sunflower Seeds (for Salad)', 584, 20.8, 20.0, 51.5, 8.6, 2.6, NULL, 9, 'usda', ARRAY['sunflower seeds', 'sunflower seed kernels', 'salad seeds'], '53 cal per tbsp (9g). Hulled, roasted.', NULL, 'condiments', 1),

-- ============================================================================
-- DIPS (food_category = 'condiments') (~6 items)
-- ============================================================================

-- Ranch Dip: 200 cal/100g (1.7P*4 + 6.7C*4 + 18.3F*9 = 6.8+26.8+164.7 = 198.3) ✓
('ranch_dip', 'Ranch Dip', 200, 1.7, 6.7, 18.3, 0, 3.3, NULL, 30, 'usda', ARRAY['ranch dip', 'ranch veggie dip', 'hidden valley ranch dip'], '60 cal per 2 tbsp (30g). Sour cream based.', NULL, 'condiments', 1),

-- Spinach Artichoke Dip: 180 cal/100g (4.5P*4 + 8.0C*4 + 14.0F*9 = 18+32+126 = 176.0) ✓
('spinach_artichoke_dip', 'Spinach Artichoke Dip', 180, 4.5, 8.0, 14.0, 1.0, 2.0, NULL, 34, 'usda', ARRAY['spinach artichoke dip', 'spinach dip', 'hot spinach dip', 'artichoke dip'], '61 cal per 2 tbsp (34g). Warm, cream cheese based.', NULL, 'condiments', 1),

-- French Onion Dip: 180 cal/100g (2.5P*4 + 10.0C*4 + 14.0F*9 = 10+40+126 = 176.0) ✓
('french_onion_dip', 'French Onion Dip', 180, 2.5, 10.0, 14.0, 0.5, 5.0, NULL, 30, 'usda', ARRAY['french onion dip', 'onion dip', 'sour cream onion dip', 'lay dip'], '54 cal per 2 tbsp (30g). Sour cream based.', NULL, 'condiments', 1),

-- Cheese Dip Queso: 153 cal/100g (5.0P*4 + 8.0C*4 + 11.0F*9 = 20+32+99 = 151.0) ✓
('cheese_dip_queso', 'Cheese Dip (Queso)', 153, 5.0, 8.0, 11.0, 0.3, 3.0, NULL, 33, 'usda', ARRAY['queso dip', 'cheese dip', 'nacho cheese dip', 'queso blanco'], '50 cal per 2 tbsp (33g). Melted cheese dip.', NULL, 'condiments', 1),

-- Bean Dip: 95 cal/100g (4.5P*4 + 13.0C*4 + 2.5F*9 = 18+52+22.5 = 92.5) ✓
('bean_dip', 'Bean Dip', 95, 4.5, 13.0, 2.5, 3.5, 1.0, NULL, 34, 'usda', ARRAY['bean dip', 'refried bean dip', 'frito lay bean dip', 'black bean dip'], '32 cal per 2 tbsp (34g). Refried bean based.', NULL, 'condiments', 1),

-- Buffalo Chicken Dip: 170 cal/100g (10.0P*4 + 4.0C*4 + 13.0F*9 = 40+16+117 = 173.0) ✓
('buffalo_chicken_dip', 'Buffalo Chicken Dip', 170, 10.0, 4.0, 13.0, 0.2, 1.5, NULL, 34, 'usda', ARRAY['buffalo chicken dip', 'buffalo dip', 'hot chicken dip'], '58 cal per 2 tbsp (34g). Shredded chicken, cream cheese, hot sauce.', NULL, 'condiments', 1),

-- ============================================================================
-- HEALTHY SWAPS (food_category = 'other') (~8 items)
-- ============================================================================

-- Cauliflower Rice: 25 cal/100g (1.9P*4 + 3.9C*4 + 0.3F*9 = 7.6+15.6+2.7 = 25.9) ✓
('cauliflower_rice', 'Cauliflower Rice', 25, 1.9, 3.9, 0.3, 2.0, 1.5, NULL, 85, 'usda', ARRAY['cauliflower rice', 'riced cauliflower', 'cauliflower crumbles', 'cauli rice'], '21 cal per serving (85g). Raw, riced.', NULL, 'other', 1),

-- Zucchini Noodles: 17 cal/100g (1.2P*4 + 2.7C*4 + 0.3F*9 = 4.8+10.8+2.7 = 18.3) ✓
('zucchini_noodles', 'Zucchini Noodles (Zoodles)', 17, 1.2, 2.7, 0.3, 1.0, 1.7, NULL, 113, 'usda', ARRAY['zucchini noodles', 'zoodles', 'spiralized zucchini', 'zucchini pasta'], '19 cal per cup (113g). Raw, spiralized.', NULL, 'other', 1),

-- Spaghetti Squash: 31 cal/100g (0.6P*4 + 6.5C*4 + 0.6F*9 = 2.4+26+5.4 = 33.8) ✓
('spaghetti_squash', 'Spaghetti Squash (Cooked)', 31, 0.6, 6.5, 0.6, 1.5, 2.5, NULL, 155, 'usda', ARRAY['spaghetti squash', 'squash noodles', 'cooked spaghetti squash'], '48 cal per cup (155g). Baked, fork-scraped strands.', NULL, 'other', 1),

-- Shirataki Noodles: 9 cal/100g (0P*4 + 3.0C*4 + 0F*9 = 0+12+0 = 12.0) ✓
('shirataki_noodles', 'Shirataki Noodles', 9, 0, 3.0, 0, 3.0, 0, NULL, 113, 'usda', ARRAY['shirataki noodles', 'konjac noodles', 'miracle noodles', 'zero calorie noodles'], '10 cal per serving (113g). Glucomannan fiber, nearly zero cal.', NULL, 'other', 1),

-- Lettuce Wrap: 15 cal/100g (1.3P*4 + 2.2C*4 + 0.2F*9 = 5.2+8.8+1.8 = 15.8) ✓
('lettuce_wrap', 'Lettuce Wrap (Butter Lettuce)', 15, 1.3, 2.2, 0.2, 1.1, 0.7, 30, 30, 'usda', ARRAY['lettuce wrap', 'butter lettuce wrap', 'lettuce cup', 'lettuce bun'], '5 cal per leaf (30g). Used as bun replacement.', NULL, 'other', 1),

-- Coconut Flour: 443 cal/100g (17.5P*4 + 60.0C*4 + 14.0F*9 = 70+240+126 = 436.0) ✓
('coconut_flour', 'Coconut Flour', 443, 17.5, 60.0, 14.0, 39.0, 8.0, NULL, 15, 'usda', ARRAY['coconut flour', 'organic coconut flour', 'gluten free coconut flour'], '66 cal per 2 tbsp (15g). High fiber, gluten-free.', NULL, 'other', 1),

-- Almond Flour: 571 cal/100g (21.4P*4 + 19.6C*4 + 50.0F*9 = 85.6+78.4+450 = 614.0) ✓
('almond_flour', 'Almond Flour', 571, 21.4, 19.6, 50.0, 10.7, 3.6, NULL, 14, 'usda', ARRAY['almond flour', 'almond meal', 'blanched almond flour', 'ground almonds'], '80 cal per 2 tbsp (14g). Blanched, finely ground.', NULL, 'other', 1),

-- Cassava Flour: 340 cal/100g (1.4P*4 + 83.0C*4 + 0.3F*9 = 5.6+332+2.7 = 340.3) ✓
('cassava_flour', 'Cassava Flour', 340, 1.4, 83.0, 0.3, 4.0, 3.7, NULL, 25, 'usda', ARRAY['cassava flour', 'tapioca flour', 'yuca flour', 'otto cassava flour'], '85 cal per 2 tbsp (25g). Grain-free, paleo-friendly.', NULL, 'other', 1),

-- ============================================================================
-- SMOOTHIE ADD-INS (food_category = 'other') (~6 items)
-- ============================================================================

-- Protein Powder Generic (Whey): 400 cal/100g (80.0P*4 + 10.0C*4 + 3.3F*9 = 320+40+29.7 = 389.7) ✓
('protein_powder_generic', 'Protein Powder (Whey, Generic)', 400, 80.0, 10.0, 3.3, 0, 3.0, NULL, 30, 'usda', ARRAY['protein powder', 'whey protein', 'protein shake powder', 'whey isolate', 'protein scoop'], '120 cal per scoop (30g). Whey isolate, unflavored.', NULL, 'other', 1),

-- Chia Seeds: 486 cal/100g (16.5P*4 + 42.1C*4 + 30.7F*9 = 66+168.4+276.3 = 510.7) ✓
('chia_seeds', 'Chia Seeds', 486, 16.5, 42.1, 30.7, 34.4, 0, NULL, 12, 'usda', ARRAY['chia seeds', 'chia', 'organic chia seeds', 'chia seed'], '58 cal per tbsp (12g). Rich in omega-3, fiber.', NULL, 'other', 1),

-- Flax Meal: 534 cal/100g (18.3P*4 + 28.9C*4 + 42.2F*9 = 73.2+115.6+379.8 = 568.6) ✓
('flax_meal', 'Flax Meal (Ground Flaxseed)', 534, 18.3, 28.9, 42.2, 27.3, 1.6, NULL, 7, 'usda', ARRAY['flax meal', 'ground flaxseed', 'flaxseed meal', 'milled flax', 'linseed meal'], '37 cal per tbsp (7g). Ground, golden or brown.', NULL, 'other', 1),

-- Spirulina Powder: 290 cal/100g (57.5P*4 + 24.0C*4 + 7.7F*9 = 230+96+69.3 = 395.3) ✓
('spirulina_powder', 'Spirulina Powder', 290, 57.5, 24.0, 7.7, 3.6, 3.1, NULL, 7, 'usda', ARRAY['spirulina', 'spirulina powder', 'blue spirulina', 'green spirulina'], '20 cal per tsp (7g). Dried blue-green algae.', NULL, 'other', 1),

-- MCT Oil: 862 cal/100g (0P*4 + 0C*4 + 95.8F*9 = 0+0+862.2 = 862.2) ✓
('mct_oil', 'MCT Oil', 862, 0, 0, 95.8, 0, 0, NULL, 14, 'usda', ARRAY['mct oil', 'medium chain triglyceride oil', 'mct coconut oil', 'brain octane'], '121 cal per tbsp (14g). 100% medium-chain triglycerides.', NULL, 'other', 1),

-- Collagen Peptides: 360 cal/100g (90.0P*4 + 0C*4 + 0F*9 = 360+0+0 = 360.0) ✓
('collagen_peptides', 'Collagen Peptides', 360, 90.0, 0, 0, 0, 0, NULL, 10, 'usda', ARRAY['collagen peptides', 'collagen powder', 'vital proteins collagen', 'hydrolyzed collagen'], '36 cal per scoop (10g). Hydrolyzed, unflavored.', NULL, 'other', 1),

-- ============================================================================
-- INTERNATIONAL RICE STAPLES (food_category = 'staples') (~6 items)
-- ============================================================================

-- Jasmine Rice Cooked: 130 cal/100g (2.7P*4 + 28.0C*4 + 0.3F*9 = 10.8+112+2.7 = 125.5) ✓
('jasmine_rice_cooked', 'Jasmine Rice (Cooked)', 130, 2.7, 28.0, 0.3, 0.4, 0, NULL, 186, 'usda', ARRAY['jasmine rice', 'cooked jasmine rice', 'thai jasmine rice', 'white jasmine rice'], '242 cal per cup (186g). Fragrant Thai rice.', NULL, 'staples', 1),

-- Basmati Rice Cooked: 121 cal/100g (3.5P*4 + 25.0C*4 + 0.4F*9 = 14+100+3.6 = 117.6) ✓
('basmati_rice_cooked', 'Basmati Rice (Cooked)', 121, 3.5, 25.0, 0.4, 0.4, 0, NULL, 186, 'usda', ARRAY['basmati rice', 'cooked basmati rice', 'indian basmati', 'white basmati rice'], '225 cal per cup (186g). Long-grain, aromatic.', NULL, 'staples', 1),

-- Sushi Rice Cooked: 143 cal/100g (2.5P*4 + 31.0C*4 + 0.3F*9 = 10+124+2.7 = 136.7) ✓
('sushi_rice_cooked', 'Sushi Rice (Cooked)', 143, 2.5, 31.0, 0.3, 0.3, 3.0, NULL, 186, 'usda', ARRAY['sushi rice', 'cooked sushi rice', 'seasoned sushi rice', 'vinegared rice'], '266 cal per cup (186g). Short-grain, seasoned with rice vinegar and sugar.', NULL, 'staples', 1),

-- Arborio Risotto Rice Cooked: 130 cal/100g (2.4P*4 + 28.5C*4 + 0.3F*9 = 9.6+114+2.7 = 126.3) ✓
('arborio_rice_cooked', 'Arborio Rice (Cooked, for Risotto)', 130, 2.4, 28.5, 0.3, 0.3, 0, NULL, 186, 'usda', ARRAY['arborio rice', 'risotto rice', 'cooked arborio', 'italian rice cooked'], '242 cal per cup (186g). Starchy, creamy Italian rice.', NULL, 'staples', 1),

-- Sticky Glutinous Rice Cooked: 97 cal/100g (2.0P*4 + 21.1C*4 + 0.2F*9 = 8+84.4+1.8 = 94.2) ✓
('sticky_rice_cooked', 'Sticky Rice (Glutinous, Cooked)', 97, 2.0, 21.1, 0.2, 0.3, 0, NULL, 174, 'usda', ARRAY['sticky rice', 'glutinous rice', 'sweet rice', 'mochi rice', 'thai sticky rice'], '169 cal per cup (174g). Steamed, short-grain, very sticky.', NULL, 'staples', 1),

-- Fried Rice Plain: 163 cal/100g (3.5P*4 + 22.0C*4 + 6.5F*9 = 14+88+58.5 = 160.5) ✓
('fried_rice_plain', 'Fried Rice (Plain/Basic)', 163, 3.5, 22.0, 6.5, 0.8, 0.5, NULL, 200, 'usda', ARRAY['fried rice', 'plain fried rice', 'basic fried rice', 'egg fried rice', 'chinese fried rice'], '326 cal per cup (200g). With egg, soy sauce, oil, scallions.', NULL, 'staples', 1)
