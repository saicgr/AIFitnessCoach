-- 1619_overrides_smoothie_chains.sql
-- Smoothie King, Tropical Smoothie Cafe, and Jamba smoothie products.
-- Sources: fastfoodnutrition.org, calorieking.com, fatsecret.com,
-- eatthismuch.com, official brand nutrition pages.
-- All values per 100g. Smoothie density ~1.0 g/ml used for fl oz to g conversion:
--   20 fl oz = 591g, 24 fl oz = 710g, 16 fl oz = 473g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SMOOTHIE KING
-- ══════════════════════════════════════════

-- Smoothie King Gladiator Chocolate: 230 cal per 20oz (591g)
('sk_gladiator_chocolate', 'Smoothie King Gladiator Chocolate', 38.9, 7.6, 0.8, 0.6,
 0.5, 0.3, 591, NULL,
 'manufacturer', ARRAY['smoothie king gladiator chocolate', 'gladiator chocolate smoothie', 'sk gladiator chocolate', 'smoothie king gladiator', 'gladiator chocolate protein smoothie'],
 'smoothie', 'Smoothie King', 1, '230 cal per 20oz (591g). 45g protein, 3.5g fat, 5g carbs. High-protein fitness blend with chocolate protein.', TRUE),

-- Smoothie King Gladiator Strawberry: 220 cal per 20oz (591g)
('sk_gladiator_strawberry', 'Smoothie King Gladiator Strawberry', 37.2, 7.6, 0.7, 0.5,
 0.5, 0.2, 591, NULL,
 'manufacturer', ARRAY['smoothie king gladiator strawberry', 'gladiator strawberry smoothie', 'sk gladiator strawberry', 'gladiator strawberry protein smoothie'],
 'smoothie', 'Smoothie King', 1, '220 cal per 20oz (591g). 45g protein, 3g fat, 4g carbs. High-protein fitness blend with strawberry protein.', TRUE),

-- Smoothie King The Activator Recovery Strawberry Banana: 260 cal per 20oz (591g)
('sk_activator_strawberry_banana', 'Smoothie King The Activator Recovery Strawberry Banana', 44.0, 4.4, 6.3, 0.4,
 0.7, 4.1, 591, NULL,
 'manufacturer', ARRAY['smoothie king activator strawberry banana', 'activator recovery strawberry banana', 'sk activator strawberry banana', 'smoothie king activator recovery', 'activator strawberry banana smoothie'],
 'smoothie', 'Smoothie King', 1, '260 cal per 20oz (591g). 26g protein, 2.5g fat, 37g carbs. Recovery blend with strawberry and banana.', TRUE),

-- Smoothie King Lean1 Strawberry: 200 cal per 20oz (591g)
('sk_lean1_strawberry', 'Smoothie King Lean1 Strawberry', 33.8, 3.2, 4.6, 0.8,
 1.7, 1.4, 591, NULL,
 'manufacturer', ARRAY['smoothie king lean1 strawberry', 'lean1 strawberry smoothie', 'sk lean1 strawberry', 'smoothie king lean 1 strawberry', 'lean one strawberry smoothie'],
 'smoothie', 'Smoothie King', 1, '200 cal per 20oz (591g). 19g protein, 5g fat, 27g carbs, 10g fiber. Weight management blend.', TRUE),

-- Smoothie King Lean1 Chocolate: 250 cal per 20oz (591g)
('sk_lean1_chocolate', 'Smoothie King Lean1 Chocolate', 42.3, 3.4, 4.7, 1.9,
 2.2, 1.4, 591, NULL,
 'manufacturer', ARRAY['smoothie king lean1 chocolate', 'lean1 chocolate smoothie', 'sk lean1 chocolate', 'smoothie king lean 1 chocolate', 'lean one chocolate smoothie'],
 'smoothie', 'Smoothie King', 1, '250 cal per 20oz (591g). 20g protein, 11g fat, 28g carbs, 13g fiber. Weight management blend with chocolate.', TRUE),

-- Smoothie King Peanut Power Plus Chocolate: 600 cal per 20oz (591g)
('sk_peanut_power_plus_chocolate', 'Smoothie King Peanut Power Plus Chocolate', 101.5, 3.9, 13.0, 4.1,
 2.0, 9.0, 591, NULL,
 'manufacturer', ARRAY['smoothie king peanut power plus chocolate', 'peanut power plus chocolate smoothie', 'sk peanut power plus', 'smoothie king peanut power chocolate', 'peanut power plus smoothie'],
 'smoothie', 'Smoothie King', 1, '600 cal per 20oz (591g). 23g protein, 24g fat, 77g carbs. Fitness blend with peanut butter, bananas, dates, cocoa.', TRUE),

-- Smoothie King Slim-N-Trim Strawberry: 150 cal per 20oz (591g)
('sk_slim_n_trim_strawberry', 'Smoothie King Slim-N-Trim Strawberry', 25.4, 2.4, 4.4, 0.4,
 1.2, 2.0, 591, NULL,
 'manufacturer', ARRAY['smoothie king slim n trim strawberry', 'slim n trim strawberry smoothie', 'sk slim n trim strawberry', 'smoothie king slim and trim strawberry', 'slim trim strawberry'],
 'smoothie', 'Smoothie King', 1, '150 cal per 20oz (591g). 14g protein, 2.5g fat, 26g carbs, 7g fiber. Low-calorie weight management blend.', TRUE),

-- Smoothie King Slim-N-Trim Vanilla: 180 cal per 20oz (591g)
('sk_slim_n_trim_vanilla', 'Smoothie King Slim-N-Trim Vanilla', 30.5, 2.4, 5.8, 0.4,
 1.0, 2.7, 591, NULL,
 'manufacturer', ARRAY['smoothie king slim n trim vanilla', 'slim n trim vanilla smoothie', 'sk slim n trim vanilla', 'smoothie king slim and trim vanilla', 'slim trim vanilla'],
 'smoothie', 'Smoothie King', 1, '180 cal per 20oz (591g). 14g protein, 2.5g fat, 34g carbs, 6g fiber. Low-calorie weight management blend.', TRUE),

-- ══════════════════════════════════════════
-- TROPICAL SMOOTHIE CAFE
-- ══════════════════════════════════════════

-- Tropical Smoothie Cafe Detox Island Green: 180 cal per 24oz (710g)
('tsc_detox_island_green', 'Tropical Smoothie Cafe Detox Island Green', 25.4, 0.6, 6.1, 0.0,
 0.7, 4.1, 710, NULL,
 'manufacturer', ARRAY['tropical smoothie detox island green', 'detox island green smoothie', 'tsc detox island green', 'tropical smoothie cafe detox green', 'detox green smoothie tropical'],
 'smoothie', 'Tropical Smoothie Cafe', 1, '180 cal per 24oz (710g). 4g protein, 0g fat, 43g carbs, 5g fiber. Spinach, kale, mango, pineapple, banana, ginger.', TRUE),

-- Tropical Smoothie Cafe Island Green: 410 cal per 24oz (710g)
('tsc_island_green', 'Tropical Smoothie Cafe Island Green', 57.7, 0.4, 14.4, 0.0,
 0.6, 12.4, 710, NULL,
 'manufacturer', ARRAY['tropical smoothie island green', 'island green smoothie', 'tsc island green', 'tropical smoothie cafe island green', 'island green tropical smoothie'],
 'smoothie', 'Tropical Smoothie Cafe', 1, '410 cal per 24oz (710g). 3g protein, 0g fat, 102g carbs. Spinach, kale, mango, pineapple, banana with turbinado sugar.', TRUE),

-- Tropical Smoothie Cafe Peanut Butter Cup: 710 cal per 24oz (710g)
('tsc_peanut_butter_cup', 'Tropical Smoothie Cafe Peanut Butter Cup', 100.0, 1.7, 17.9, 2.8,
 1.0, 15.1, 710, NULL,
 'manufacturer', ARRAY['tropical smoothie peanut butter cup', 'peanut butter cup smoothie', 'tsc peanut butter cup', 'tropical smoothie cafe peanut butter cup', 'tropical smoothie pb cup'],
 'smoothie', 'Tropical Smoothie Cafe', 1, '710 cal per 24oz (710g). 12g protein, 20g fat, 127g carbs, 7g fiber, 107g sugar. Indulgent chocolate peanut butter blend.', TRUE),

-- Tropical Smoothie Cafe Bahama Mama: 500 cal per 24oz (710g)
('tsc_bahama_mama', 'Tropical Smoothie Cafe Bahama Mama', 70.4, 0.4, 16.5, 0.6,
 0.4, 15.5, 710, NULL,
 'manufacturer', ARRAY['tropical smoothie bahama mama', 'bahama mama smoothie', 'tsc bahama mama', 'tropical smoothie cafe bahama mama', 'bahama mama tropical'],
 'smoothie', 'Tropical Smoothie Cafe', 1, '500 cal per 24oz (710g). 3g protein, 4.5g fat, 117g carbs, 110g sugar. Strawberries, pineapple, white chocolate, coconut.', TRUE),

-- Tropical Smoothie Cafe Chia Banana Boost (with Strawberry): 610 cal per 24oz (710g)
('tsc_chia_banana_boost', 'Tropical Smoothie Cafe Chia Banana Boost', 85.9, 1.1, 17.9, 1.7,
 2.0, 13.2, 710, NULL,
 'manufacturer', ARRAY['tropical smoothie chia banana boost', 'chia banana boost smoothie', 'tsc chia banana boost', 'tropical smoothie cafe chia banana', 'chia banana boost with strawberry'],
 'smoothie', 'Tropical Smoothie Cafe', 1, '610 cal per 24oz (710g). 8g protein, 12g fat, 127g carbs, 14g fiber. Banana, oats, chia seeds, almond milk, strawberry.', TRUE),

-- Tropical Smoothie Cafe Avocolada: 600 cal per 24oz (710g)
('tsc_avocolada', 'Tropical Smoothie Cafe Avocolada', 84.5, 0.6, 15.8, 2.4,
 1.3, 13.2, 710, NULL,
 'manufacturer', ARRAY['tropical smoothie avocolada', 'avocolada smoothie', 'tsc avocolada', 'tropical smoothie cafe avocolada', 'tropical avocolada', 'avocado colada smoothie'],
 'smoothie', 'Tropical Smoothie Cafe', 1, '600 cal per 24oz (710g). 4g protein, 17g fat, 112g carbs, 9g fiber. Avocado, pineapple, spinach, kale, coconut, banana.', TRUE),

-- ══════════════════════════════════════════
-- JAMBA
-- ══════════════════════════════════════════

-- Jamba Protein Berry Workout (Whey): 284 cal per 16oz (473g)
('jamba_protein_berry_workout', 'Jamba Protein Berry Workout (Whey)', 60.0, 3.2, 11.1, 0.2,
 0.8, 8.6, 473, NULL,
 'manufacturer', ARRAY['jamba protein berry workout', 'protein berry workout smoothie', 'jamba juice protein berry workout', 'jamba berry protein smoothie', 'protein berry workout whey jamba'],
 'smoothie', 'Jamba', 1, '284 cal per 16oz (473g). 15.3g protein, 1.1g fat, 52.4g carbs. Whey protein with strawberries and bananas.', TRUE),

-- Jamba PB & Banana Protein (Whey): 459 cal per 16oz (473g)
('jamba_pb_banana_protein', 'Jamba PB & Banana Protein (Whey)', 97.0, 5.9, 10.8, 3.5,
 0.5, 8.2, 473, NULL,
 'manufacturer', ARRAY['jamba pb banana protein', 'jamba peanut butter banana protein', 'jamba juice pb banana protein', 'pb banana protein smoothie jamba', 'jamba peanut butter banana smoothie'],
 'smoothie', 'Jamba', 1, '459 cal per 16oz (473g). 27.7g protein, 16.7g fat, 51g carbs. Whey protein with peanut butter, banana, honey.', TRUE),

-- Jamba Mango-a-Go-Go: 300 cal per 16oz (473g)
('jamba_mango_a_go_go', 'Jamba Mango-a-Go-Go', 63.4, 0.2, 15.4, 0.3,
 0.4, 14.0, 473, NULL,
 'manufacturer', ARRAY['jamba mango a go go', 'mango a go go smoothie', 'jamba juice mango a go go', 'jamba mango smoothie', 'mango-a-go-go jamba'],
 'smoothie', 'Jamba', 1, '300 cal per 16oz (473g). 1g protein, 1.5g fat, 73g carbs, 66g sugar. Mango, passion-mango juice blend, pineapple sherbet.', TRUE),

-- Jamba Caribbean Passion: 248 cal per 16oz (473g)
('jamba_caribbean_passion', 'Jamba Caribbean Passion', 52.4, 0.2, 9.2, 0.2,
 0.3, 8.1, 473, NULL,
 'manufacturer', ARRAY['jamba caribbean passion', 'caribbean passion smoothie', 'jamba juice caribbean passion', 'jamba caribbean passion smoothie', 'caribbean passion jamba juice'],
 'smoothie', 'Jamba', 1, '248 cal per 16oz (473g). 1.1g protein, 0.8g fat, 43.5g carbs, 38.1g sugar. Passion fruit-mango juice, strawberries, peaches, orange sherbet.', TRUE),

-- Jamba Acai Super-Antioxidant: 340 cal per 16oz (473g)
('jamba_acai_super_antioxidant', 'Jamba Acai Super-Antioxidant', 71.9, 1.3, 14.6, 1.0,
 0.8, 11.0, 473, NULL,
 'manufacturer', ARRAY['jamba acai super antioxidant', 'acai super antioxidant smoothie', 'jamba juice acai smoothie', 'jamba acai smoothie', 'jamba acai primo smoothie', 'acai super antioxidant jamba'],
 'smoothie', 'Jamba', 1, '340 cal per 16oz (473g). 6g protein, 4.5g fat, 69g carbs, 52g sugar. Acai juice blend, strawberries, blueberries, soymilk.', TRUE),

-- Jamba Greens 'n Ginger: 230 cal per 16oz (473g)
('jamba_greens_n_ginger', 'Jamba Greens ''n Ginger', 48.6, 0.8, 11.8, 0.2,
 0.8, 14.0, 473, NULL,
 'manufacturer', ARRAY['jamba greens n ginger', 'greens n ginger smoothie', 'jamba juice greens n ginger', 'jamba green ginger smoothie', 'greens and ginger jamba', 'jamba greens ginger'],
 'smoothie', 'Jamba', 1, '230 cal per 16oz (473g). 4g protein, 1g fat, 56g carbs, 66g sugar. Kale, lemon juice, peaches, mangoes, ginger.', TRUE)

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
