-- 1621_overrides_supplements_extras.sql
-- Supplements, protein powders, collagen, pre-workouts, creatine, greens, light ice cream, protein chips.
-- Sources: Package nutrition labels via fatsecret.com, nutritionix.com, manufacturer websites,
-- eatthismuch.com, mynetdiary.com.
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
-- VITAL PROTEINS — COLLAGEN PEPTIDES
-- ══════════════════════════════════════════

-- Vital Proteins Collagen Peptides Unflavored: 70 cal, 18g P per 2 scoops (20g)
('vitalproteins_collagen_unflavored', 'Vital Proteins Collagen Peptides (Unflavored)', 350, 90.0, 0.0, 0.0,
 0.0, 0.0, 20, NULL,
 'manufacturer', ARRAY['vital proteins collagen', 'vital proteins collagen peptides', 'vital proteins unflavored', 'vital proteins collagen peptides unflavored', 'vp collagen peptides'],
 'collagen', 'Vital Proteins', 1, '70 cal, 18g protein per 2 scoops (20g). Grass-fed, pasture-raised bovine collagen. Unflavored, mixes into any drink.', TRUE),

-- Vital Proteins Collagen Peptides Chocolate: 90 cal, 18g P per 2 scoops (27g)
('vitalproteins_collagen_chocolate', 'Vital Proteins Collagen Peptides (Chocolate)', 333, 66.7, 11.1, 3.7,
 3.7, 0.0, 27, NULL,
 'manufacturer', ARRAY['vital proteins chocolate collagen', 'vital proteins collagen peptides chocolate', 'vital proteins chocolate', 'vp collagen chocolate'],
 'collagen', 'Vital Proteins', 1, '90 cal, 18g protein per 2 scoops (27g). Chocolate flavored collagen peptides with cocoa. 17% carbs, 5% fat, 78% protein.', TRUE),

-- Vital Proteins Collagen Peptides Vanilla: 80 cal, 18g P per 2 scoops (23g)
('vitalproteins_collagen_vanilla', 'Vital Proteins Collagen Peptides (Vanilla)', 348, 78.3, 13.0, 0.0,
 0.0, 0.0, 23, NULL,
 'manufacturer', ARRAY['vital proteins vanilla collagen', 'vital proteins collagen peptides vanilla', 'vital proteins vanilla', 'vp collagen vanilla'],
 'collagen', 'Vital Proteins', 1, '80 cal, 18g protein per 2 scoops (23g). Vanilla flavored with natural flavors, whole grain oats, sea salt, stevia.', TRUE),

-- ══════════════════════════════════════════
-- GARDEN OF LIFE — RAW ORGANIC PROTEIN
-- ══════════════════════════════════════════

-- Garden of Life Raw Organic Protein Vanilla: 120 cal, 22g P per scoop (28.5g)
('gol_protein_vanilla', 'Garden of Life Raw Organic Protein (Vanilla)', 421, 77.2, 14.0, 5.3,
 7.0, 0.0, 29, NULL,
 'manufacturer', ARRAY['garden of life protein vanilla', 'garden of life raw organic protein vanilla', 'gol protein vanilla', 'garden of life vanilla protein powder'],
 'protein_powder', 'Garden of Life', 1, '120 cal, 22g protein per scoop (28.5g). Organic plant-based with pea, sprouted grains, seeds. Probiotics and enzymes included.', TRUE),

-- Garden of Life Raw Organic Protein Chocolate: 140 cal, 22g P per scoop (35g)
('gol_protein_chocolate', 'Garden of Life Raw Organic Protein (Chocolate)', 400, 62.9, 20.0, 5.7,
 14.3, 0.0, 35, NULL,
 'manufacturer', ARRAY['garden of life protein chocolate', 'garden of life raw organic protein chocolate', 'gol protein chocolate', 'garden of life chocolate protein powder', 'garden of life chocolate cacao protein'],
 'protein_powder', 'Garden of Life', 1, '140 cal, 22g protein per scoop (35g). Organic chocolate cacao plant-based protein with 4g BCAAs and 5g fiber.', TRUE),

-- Garden of Life Raw Organic Protein Unflavored: 110 cal, 22g P per scoop (28g)
('gol_protein_unflavored', 'Garden of Life Raw Organic Protein (Unflavored)', 393, 78.6, 7.1, 8.9,
 3.6, 0.0, 28, NULL,
 'manufacturer', ARRAY['garden of life protein unflavored', 'garden of life raw organic protein unflavored', 'gol protein unflavored', 'garden of life unflavored protein powder'],
 'protein_powder', 'Garden of Life', 1, '110 cal, 22g protein per scoop (28g). Organic unflavored plant-based protein with 4g BCAAs. No stevia.', TRUE),

-- ══════════════════════════════════════════
-- ORGAIN — ORGANIC PROTEIN POWDER
-- ══════════════════════════════════════════

-- Orgain Organic Protein Chocolate Fudge: 150 cal, 21g P per 2 scoops (46g)
('orgain_protein_chocolate_fudge', 'Orgain Organic Protein Powder (Creamy Chocolate Fudge)', 326, 45.7, 32.6, 8.7,
 15.2, 2.2, 46, NULL,
 'manufacturer', ARRAY['orgain chocolate fudge', 'orgain protein chocolate', 'orgain organic protein chocolate fudge', 'orgain creamy chocolate fudge', 'orgain chocolate protein powder'],
 'protein_powder', 'Orgain', 1, '150 cal, 21g protein per 2 scoops (46g). Organic pea, brown rice, chia seed protein. 7g prebiotic fiber, <1g sugar.', TRUE),

-- Orgain Organic Protein Vanilla Bean: 150 cal, 21g P per 2 scoops (46g)
('orgain_protein_vanilla_bean', 'Orgain Organic Protein Powder (Vanilla Bean)', 326, 45.7, 32.6, 8.7,
 15.2, 2.2, 46, NULL,
 'manufacturer', ARRAY['orgain vanilla bean', 'orgain protein vanilla', 'orgain organic protein vanilla bean', 'orgain vanilla protein powder', 'orgain sweet vanilla bean'],
 'protein_powder', 'Orgain', 1, '150 cal, 21g protein per 2 scoops (46g). Organic plant-based vanilla protein. 7g prebiotic fiber, no added sugar.', TRUE),

-- Orgain Organic Protein Peanut Butter: 150 cal, 21g P per 2 scoops (46g)
('orgain_protein_peanut_butter', 'Orgain Organic Protein Powder (Peanut Butter)', 326, 45.7, 32.6, 8.7,
 15.2, 2.2, 46, NULL,
 'manufacturer', ARRAY['orgain peanut butter', 'orgain protein peanut butter', 'orgain organic protein peanut butter', 'orgain pb protein powder'],
 'protein_powder', 'Orgain', 1, '150 cal, 21g protein per 2 scoops (46g). Organic plant-based peanut butter protein. 7g prebiotic fiber, no added sugar.', TRUE),

-- ══════════════════════════════════════════
-- NICK'S — LIGHT ICE CREAM PINTS
-- ══════════════════════════════════════════

-- Nick's Swedish Vanilj: 80 cal, 3g P, 5g F, 18g C per 2/3 cup (87g) — ~250 cal/pint
('nicks_swedish_vanilj', 'Nick''s Swedish Vanilj Light Ice Cream', 92, 3.4, 20.7, 5.7,
 5.7, 4.6, 87, NULL,
 'manufacturer', ARRAY['nicks vanilla', 'nicks swedish vanilj', 'nicks vanilla ice cream', 'nicks light ice cream vanilla', 'nick''s swedish vanilj'],
 'ice_cream', 'Nick''s', 1, '80 cal per 2/3 cup (87g), ~250 cal/pint. No added sugar, Swedish-style light ice cream. 4g net carbs per serving.', TRUE),

-- Nick's Mint Chokladchip: 80 cal, 4g P, 6g F, 15g C per 2/3 cup (87g) — ~340 cal/pint
('nicks_mint_chokladchip', 'Nick''s Mint Chokladchip Light Ice Cream', 92, 4.6, 17.2, 6.9,
 6.9, 3.4, 87, NULL,
 'manufacturer', ARRAY['nicks mint chocolate chip', 'nicks mint chokladchip', 'nicks mint choc chip', 'nicks mint ice cream', 'nick''s mint chokladchip'],
 'ice_cream', 'Nick''s', 1, '80 cal per 2/3 cup (87g), ~340 cal/pint. Cool minty ice cream with chocolate flakes. 4g net carbs per serving.', TRUE),

-- Nick's Peanot Butter Cup: 130 cal, 4g P, 9g F, 19g C per 2/3 cup (87g) — ~390 cal/pint
('nicks_peanot_butter_cup', 'Nick''s Peanot Butter Cup Light Ice Cream', 149, 4.6, 21.8, 10.3,
 6.9, 3.4, 87, NULL,
 'manufacturer', ARRAY['nicks peanut butter cup', 'nicks peanot butter cup', 'nicks pb cup', 'nicks peanut butter ice cream', 'nick''s peanot butter cup'],
 'ice_cream', 'Nick''s', 1, '130 cal per 2/3 cup (87g), ~390 cal/pint. Rich peanut butter ice cream with whole PB cups. 5g net carbs per serving.', TRUE),

-- Nick's Swedish Cookie Dough: 100 cal, 4g P, 5g F, 20g C per 2/3 cup (94g) — ~390 cal/pint
('nicks_swedish_cookie_dough', 'Nick''s Swedish Cookie Dough Light Ice Cream', 106, 4.3, 21.3, 5.3,
 5.3, 4.3, 94, NULL,
 'manufacturer', ARRAY['nicks cookie dough', 'nicks swedish cookie dough', 'nicks chocolate chip cookie dough', 'nicks cookie dough ice cream', 'nick''s swedish cookie dough'],
 'ice_cream', 'Nick''s', 1, '100 cal per 2/3 cup (94g), ~390 cal/pint. Soft vanilla ice cream with sugar cookie dough chunks. 5g net carbs per serving.', TRUE),

-- ══════════════════════════════════════════
-- ENLIGHTENED — ICE CREAM BARS & PINTS
-- ══════════════════════════════════════════

-- Enlightened Chocolate Peanut Butter Bar: 100 cal, 8g P per bar (63g)
('enlightened_choc_pb_bar', 'Enlightened Chocolate Peanut Butter Ice Cream Bar', 159, 12.7, 22.2, 4.8,
 4.8, 6.3, NULL, 63,
 'manufacturer', ARRAY['enlightened chocolate peanut butter bar', 'enlightened choc pb bar', 'enlightened peanut butter ice cream bar', 'enlightened chocolate peanut butter light bar'],
 'ice_cream', 'Enlightened', 1, '100 cal, 8g protein per bar (63g). Light ice cream bar with chocolate and peanut butter. 60% fewer calories than regular bars.', TRUE),

-- Enlightened Caramel Dark Chocolate Peanut Bar (Keto): 230 cal, 3g P per bar (63g)
('enlightened_caramel_dark_choc_bar', 'Enlightened Caramel Dark Chocolate Peanut Ice Cream Bar', 365, 4.8, 17.5, 33.3,
 14.3, 1.6, NULL, 63,
 'manufacturer', ARRAY['enlightened caramel dark chocolate peanut bar', 'enlightened keto caramel bar', 'enlightened dark chocolate caramel peanut bar', 'enlightened caramel dark choc bar'],
 'ice_cream', 'Enlightened', 1, '230 cal, 3g protein per bar (63g). Keto caramel ice cream rolled in crushed peanuts and dipped in dark chocolate. 1g net carbs.', TRUE),

-- Enlightened Chocolate Peanut Butter Pint: 100 cal, 8g P per 1/2 cup (66g)
('enlightened_choc_pb_pint', 'Enlightened Chocolate Peanut Butter Light Ice Cream (Pint)', 152, 12.1, 22.7, 4.5,
 4.5, 6.1, 66, NULL,
 'manufacturer', ARRAY['enlightened chocolate peanut butter pint', 'enlightened chocolate peanut butter ice cream', 'enlightened choc pb ice cream pint'],
 'ice_cream', 'Enlightened', 1, '100 cal, 8g protein per 1/2 cup (66g), ~400 cal/pint. High protein, low sugar light ice cream with chocolate and peanut butter.', TRUE),

-- Enlightened Movie Night Pint: 90 cal, 5g P per 1/2 cup (69g)
('enlightened_movie_night', 'Enlightened Movie Night Light Ice Cream (Pint)', 130, 7.2, 26.1, 3.6,
 5.8, 8.7, 69, NULL,
 'manufacturer', ARRAY['enlightened movie night', 'enlightened movie night ice cream', 'enlightened movie night pint', 'enlightened movie night light ice cream'],
 'ice_cream', 'Enlightened', 1, '90 cal, 5g protein per 1/2 cup (69g), ~380 cal/pint. Movie-themed flavor light ice cream. 8g net carbs per serving.', TRUE),

-- ══════════════════════════════════════════
-- PRE-WORKOUT POWDERS
-- ══════════════════════════════════════════

-- C4 Original Pre-Workout Fruit Punch: 5 cal per scoop (6.5g)
('c4_original_fruit_punch', 'C4 Original Pre-Workout (Fruit Punch)', 77, 0.0, 15.4, 0.0,
 0.0, 0.0, 6.5, NULL,
 'manufacturer', ARRAY['c4 pre workout', 'c4 original', 'c4 fruit punch', 'cellucor c4', 'c4 original pre workout fruit punch', 'c4 preworkout'],
 'pre_workout', 'Cellucor', 1, '5 cal per scoop (6.5g). Contains 150mg caffeine, 1.6g beta-alanine, 1g creatine nitrate. Popular entry-level pre-workout.', TRUE),

-- Transparent Labs BULK Pre-Workout: 5 cal per scoop (20.8g)
('tl_preworkout_bulk', 'Transparent Labs BULK Pre-Workout', 24, 0.0, 4.8, 0.0,
 0.0, 0.0, 21, NULL,
 'manufacturer', ARRAY['transparent labs bulk', 'transparent labs pre workout', 'tl bulk', 'transparent labs bulk pre workout', 'tl preworkout'],
 'pre_workout', 'Transparent Labs', 1, '5 cal per scoop (20.8g). Contains 200mg caffeine, 8g citrulline, 4g beta-alanine. Clinically dosed, no artificial sweeteners.', TRUE),

-- Gorilla Mode Pre-Workout: 5 cal per scoop (15.4g)
('gorilla_preworkout_mode', 'Gorilla Mode Pre-Workout', 32, 0.0, 6.5, 0.0,
 0.0, 0.0, 15, NULL,
 'manufacturer', ARRAY['gorilla mode', 'gorilla mode pre workout', 'gorilla mind pre workout', 'gorilla mode preworkout'],
 'pre_workout', 'Gorilla Mind', 1, '5 cal per scoop (15.4g). Contains 175mg caffeine (half dose), 4.5g citrulline, 1.25g creatine per scoop. Max dose is 2 scoops.', TRUE),

-- Ghost Legend Pre-Workout: 5 cal per scoop (12.5g)
('ghost_preworkout_legend', 'Ghost Legend Pre-Workout', 40, 0.0, 8.0, 0.0,
 0.0, 0.0, 13, NULL,
 'manufacturer', ARRAY['ghost legend', 'ghost pre workout', 'ghost legend pre workout', 'ghost preworkout', 'ghost legend v3'],
 'pre_workout', 'Ghost', 1, '5 cal per scoop (12.5g). Contains 250mg caffeine, 4g citrulline, 3.2g beta-alanine. Licensed flavor collaborations.', TRUE),

-- ══════════════════════════════════════════
-- CREATINE
-- ══════════════════════════════════════════

-- ON Micronized Creatine Monohydrate: 5 cal per scoop (5g)
('on_creatine_micronized', 'Optimum Nutrition Micronized Creatine Powder', 100, 0.0, 0.0, 0.0,
 0.0, 0.0, 5, NULL,
 'manufacturer', ARRAY['on creatine', 'optimum nutrition creatine', 'on micronized creatine', 'optimum nutrition micronized creatine monohydrate', 'on creatine monohydrate'],
 'creatine', 'Optimum Nutrition', 1, '5 cal per rounded teaspoon (5g). Pure micronized creatine monohydrate. 5g creatine per serving. Unflavored.', TRUE),

-- Transparent Labs Creatine HMB: 5 cal per scoop (7.1g)
('tl_creatine_hmb', 'Transparent Labs Creatine HMB', 70, 0.0, 0.0, 0.0,
 0.0, 0.0, 7, NULL,
 'manufacturer', ARRAY['transparent labs creatine', 'tl creatine hmb', 'transparent labs creatine hmb', 'tl creatine'],
 'creatine', 'Transparent Labs', 1, '5 cal per scoop (7.1g). Contains 5g creatine monohydrate + 1.5g HMB. No artificial sweeteners. Available in multiple flavors.', TRUE),

-- Myprotein Creatine Monohydrate: 0 cal per scoop (5g)
('myprotein_creatine_monohydrate', 'Myprotein Creatine Monohydrate', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 5, NULL,
 'manufacturer', ARRAY['myprotein creatine', 'myprotein creatine monohydrate', 'my protein creatine', 'myprotein creatine powder'],
 'creatine', 'Myprotein', 1, '0 cal per teaspoon (5g). Pure creatine monohydrate powder. 5g creatine per serving. Unflavored.', TRUE),

-- ══════════════════════════════════════════
-- GREENS POWDERS
-- ══════════════════════════════════════════

-- AG1 (Athletic Greens): 40 cal per scoop (12g)
('ag1_greens', 'AG1 Daily Greens Powder', 333, 16.7, 50.0, 0.0,
 16.7, 4.2, 12, NULL,
 'manufacturer', ARRAY['ag1', 'athletic greens', 'ag1 greens', 'athletic greens ag1', 'ag1 daily nutrition', 'ag1 powder'],
 'greens_powder', 'AG1', 1, '40 cal per scoop (12g). 75 vitamins, minerals, probiotics, adaptogens. 2g protein, 6g carbs, 2g fiber per serving.', TRUE),

-- Bloom Nutrition Greens & Superfoods: 15 cal per scoop (5g)
('bloom_greens', 'Bloom Nutrition Greens & Superfoods', 300, 20.0, 60.0, 0.0,
 40.0, 0.0, 5, NULL,
 'manufacturer', ARRAY['bloom greens', 'bloom nutrition greens', 'bloom superfoods', 'bloom greens and superfoods', 'bloom nutrition greens powder', 'bloom greens superfood'],
 'greens_powder', 'Bloom Nutrition', 1, '15 cal per scoop (5g). 30+ ingredients with prebiotics, probiotics, digestive enzymes, spirulina, chlorella. Bloating relief.', TRUE),

-- ══════════════════════════════════════════
-- PROTEIN CHIPS
-- ══════════════════════════════════════════

-- Quevos Egg White Chips: 140 cal, 8g P per bag (28g)
('quevos_egg_white_chips', 'Quevos Egg White Chips', 500, 28.6, 28.6, 35.7,
 14.3, 3.6, NULL, 28,
 'manufacturer', ARRAY['quevos', 'quevos chips', 'quevos egg white chips', 'quevos egg chips', 'quevos keto chips'],
 'protein_chips', 'Quevos', 1, '140 cal, 8g protein per bag (28g). Made from egg whites, high fiber (4g), low net carbs (4g). Gluten-free, grain-free.', TRUE),

-- Shrewd Food Protein Puffs: 90 cal, 14g P per bag (21g)
('shrewd_protein_puffs', 'Shrewd Food Protein Puffs', 429, 66.7, 9.5, 14.3,
 0.0, 4.8, NULL, 21,
 'manufacturer', ARRAY['shrewd food', 'shrewd food protein puffs', 'shrewd puffs', 'shrewd food puffs', 'shrewd protein chips'],
 'protein_chips', 'Shrewd Food', 1, '90 cal, 14g protein per bag (21g). High protein, low carb cheese puffs. Available in Baked Cheddar, Pizza, Nacho flavors. Keto-friendly.', TRUE),

-- Wilde Protein Chips: 170 cal, 10g P per bag (28g)
('wilde_protein_chips', 'Wilde Protein Chips', 607, 35.7, 28.6, 35.7,
 0.0, 3.6, NULL, 28,
 'manufacturer', ARRAY['wilde chips', 'wilde protein chips', 'wilde chicken chips', 'wilde brands chips'],
 'protein_chips', 'Wilde', 1, '170 cal, 10g protein per bag (28g). Made from real chicken breast, egg whites, bone broth. Available in Nashville Hot, BBQ, Sea Salt flavors.', TRUE)

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
