-- 1581_fast_food_combos_new_2026_items.sql
-- McDonald's 2026 new items (Big Arch, Hot Honey), combo meals with size variants,
-- Chick-fil-A, Burger King, Wendy's, Taco Bell, Popeyes, Subway combos and sides.
-- Sources: Official chain nutrition calculators, fastfoodnutrition.org, calorieking.com, fatsecret.com.
-- All values per item (default_serving_g = full item weight).

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- McDONALD'S — NEW 2026 ITEMS
-- ══════════════════════════════════════════

-- Big Arch Burger (NEW March 2026): 1020 cal, 53P, 59C, 65F per item (280g)
('mcdonalds_big_arch', 'McDonald''s Big Arch', 364, 18.9, 21.1, 23.2,
 1.1, 5.4, 280, 280,
 'manufacturer', ARRAY['big arch', 'mcdonald big arch', 'mcdonalds big arch', 'big arch burger', 'the big arch'],
 'burgers', 'McDonald''s', 1, '1020 cal per burger. Two 1/4 lb patties, 3 white cheddar slices, crispy onions, Big Arch sauce. McDonald''s most calorie-dense burger.', TRUE),

-- Big Arch Meal (medium fries + medium Coke): 1610 cal
('mcdonalds_big_arch_meal_medium', 'McDonald''s Big Arch Meal (Medium)', 296, 10.9, 32.3, 14.0,
 1.2, 8.5, 544, NULL,
 'manufacturer', ARRAY['big arch meal', 'big arch combo', 'mcdonald big arch meal', 'big arch meal medium'],
 'combo_meals', 'McDonald''s', 1, '1610 cal total. Big Arch (1020) + Medium Fries (320) + Medium Coke (220). Approx 2/3 of daily calories.', TRUE),

-- Big Arch Meal (large fries + large Coke): 1730 cal
('mcdonalds_big_arch_meal_large', 'McDonald''s Big Arch Meal (Large)', 300, 10.2, 33.5, 14.2,
 1.2, 9.0, 577, NULL,
 'manufacturer', ARRAY['big arch meal large', 'big arch combo large', 'large big arch meal'],
 'combo_meals', 'McDonald''s', 1, '1730 cal total. Big Arch (1020) + Large Fries (400) + Large Coke (290).', TRUE),

-- Hot Honey McCrispy (NEW Jan 2026): 660 cal, 27P, 62C
('mcdonalds_hot_honey_mccrispy', 'McDonald''s Hot Honey McCrispy', 290, 11.9, 27.3, 15.0,
 1.0, 5.0, 228, 228,
 'manufacturer', ARRAY['hot honey mccrispy', 'mcdonald hot honey mccrispy', 'hot honey chicken sandwich mcdonalds', 'hot honey crispy'],
 'sandwiches', 'McDonald''s', 1, '660 cal per sandwich. McCrispy with Hot Honey Sauce, jalapenos, lettuce, mayo. New 2026 item.', TRUE),

-- Bacon Hot Honey McCrispy (NEW Jan 2026): 770 cal, 33P, 63C
('mcdonalds_bacon_hot_honey_mccrispy', 'McDonald''s Bacon Hot Honey McCrispy', 310, 13.3, 25.4, 17.7,
 1.0, 5.0, 248, 248,
 'manufacturer', ARRAY['bacon hot honey mccrispy', 'bacon hot honey mccrispy mcdonalds', 'hot honey bacon mccrispy'],
 'sandwiches', 'McDonald''s', 1, '770 cal per sandwich. Hot Honey McCrispy with bacon added. New 2026 item.', TRUE),

-- Hot Honey Sausage Egg Biscuit (NEW Jan 2026): 550 cal, 17P, 41C
('mcdonalds_hot_honey_sausage_biscuit', 'McDonald''s Hot Honey Sausage Egg Biscuit', 340, 10.5, 25.3, 22.0,
 1.0, 5.0, 162, 162,
 'manufacturer', ARRAY['hot honey sausage biscuit', 'hot honey breakfast mcdonalds', 'hot honey sausage egg biscuit'],
 'breakfast', 'McDonald''s', 1, '550 cal. Sausage patty, folded egg, Hot Honey Sauce on biscuit. New 2026 breakfast item.', TRUE),

-- Hot Honey Snack Wrap (NEW Jan 2026): 350 cal, 17P, 38C
('mcdonalds_hot_honey_snack_wrap', 'McDonald''s Hot Honey Snack Wrap', 292, 14.2, 31.7, 11.7,
 1.0, 4.0, 120, 120,
 'manufacturer', ARRAY['hot honey snack wrap', 'mcdonald snack wrap hot honey', 'hot honey wrap mcdonalds'],
 'sandwiches', 'McDonald''s', 1, '350 cal. Crispy chicken, Hot Honey Sauce in a flour tortilla. New 2026 item.', TRUE),

-- ══════════════════════════════════════════
-- McDONALD'S — CORE MENU ITEMS (standalone)
-- ══════════════════════════════════════════

-- Big Mac: 580 cal (200g)
('mcdonalds_big_mac', 'McDonald''s Big Mac', 290, 13.0, 22.5, 16.5,
 1.5, 4.5, 200, 200,
 'manufacturer', ARRAY['big mac', 'mcdonald big mac', 'mcdonalds big mac', 'bigmac'],
 'burgers', 'McDonald''s', 1, '580 cal per burger. Two all-beef patties, special sauce, lettuce, cheese, pickles, onions, sesame seed bun.', TRUE),

-- Quarter Pounder with Cheese: 520 cal (200g)
('mcdonalds_quarter_pounder', 'McDonald''s Quarter Pounder with Cheese', 260, 15.0, 17.0, 14.0,
 1.0, 4.5, 200, 200,
 'manufacturer', ARRAY['quarter pounder', 'mcdonald quarter pounder', 'qpc', 'quarter pounder cheese', 'mcdonalds quarter pounder'],
 'burgers', 'McDonald''s', 1, '520 cal per burger. 1/4 lb fresh beef, 2 slices American cheese, onions, pickles, ketchup, mustard.', TRUE),

-- McCrispy: 470 cal (190g)
('mcdonalds_mccrispy', 'McDonald''s McCrispy', 247, 13.2, 21.6, 12.1,
 0.5, 2.6, 190, 190,
 'manufacturer', ARRAY['mccrispy', 'mcdonalds mccrispy', 'mcdonald mccrispy', 'mccrispy chicken sandwich', 'crispy chicken sandwich mcdonalds'],
 'sandwiches', 'McDonald''s', 1, '470 cal per sandwich. Crispy chicken fillet, crinkle-cut pickles, butter on toasted potato roll.', TRUE),

-- McChicken: 400 cal (143g)
('mcdonalds_mcchicken', 'McDonald''s McChicken', 280, 9.8, 22.4, 16.1,
 0.7, 3.5, 143, 143,
 'manufacturer', ARRAY['mcchicken', 'mcdonald mcchicken', 'mcdonalds mcchicken', 'mc chicken'],
 'sandwiches', 'McDonald''s', 1, '400 cal per sandwich. Chicken patty, lettuce, mayo on a regular bun.', TRUE),

-- McDouble: 390 cal (155g)
('mcdonalds_mcdouble', 'McDonald''s McDouble', 252, 14.2, 17.4, 13.5,
 0.6, 3.9, 155, 155,
 'manufacturer', ARRAY['mcdouble', 'mcdonald mcdouble', 'mcdonalds mcdouble', 'mc double'],
 'burgers', 'McDonald''s', 1, '390 cal per burger. Two beef patties, 1 cheese slice, onions, pickles, ketchup, mustard.', TRUE),

-- Filet-O-Fish: 390 cal (142g)
('mcdonalds_filet_o_fish', 'McDonald''s Filet-O-Fish', 275, 10.6, 24.6, 14.1,
 0.7, 3.5, 142, 142,
 'manufacturer', ARRAY['filet o fish', 'filet-o-fish', 'mcdonald fish sandwich', 'mcdonalds filet o fish', 'fish filet mcdonalds'],
 'sandwiches', 'McDonald''s', 1, '390 cal per sandwich. Fish fillet, tartar sauce, half cheese slice, steamed bun.', TRUE),

-- 10 Piece McNuggets: 410 cal (162g)
('mcdonalds_10pc_mcnuggets', 'McDonald''s 10pc McNuggets', 253, 14.8, 15.4, 14.8,
 0.6, 0.0, 162, NULL,
 'manufacturer', ARRAY['10 piece mcnuggets', 'mcnuggets 10 piece', '10 pc nuggets mcdonalds', 'mcdonalds nuggets 10', 'chicken mcnuggets 10'],
 'chicken', 'McDonald''s', 1, '410 cal for 10 pieces (without sauce). Add ~50 cal per dipping sauce packet.', TRUE),

-- 20 Piece McNuggets: 830 cal (324g)
('mcdonalds_20pc_mcnuggets', 'McDonald''s 20pc McNuggets', 256, 14.8, 15.4, 15.1,
 0.6, 0.0, 324, NULL,
 'manufacturer', ARRAY['20 piece mcnuggets', 'mcnuggets 20 piece', '20 pc nuggets mcdonalds', 'mcdonalds nuggets 20'],
 'chicken', 'McDonald''s', 1, '830 cal for 20 pieces (without sauce).', TRUE),

-- ══════════════════════════════════════════
-- McDONALD'S — SIDES (by size)
-- ══════════════════════════════════════════

-- Small Fries: 230 cal (71g)
('mcdonalds_fries_small', 'McDonald''s Fries (Small)', 324, 4.2, 42.3, 14.1,
 2.8, 0.0, 71, NULL,
 'manufacturer', ARRAY['mcdonalds small fries', 'mcdonald fries small', 'small fries mcdonalds', 'small mcd fries'],
 'sides', 'McDonald''s', 1, '230 cal. Small order of World Famous Fries.', TRUE),

-- Medium Fries: 320 cal (111g)
('mcdonalds_fries_medium', 'McDonald''s Fries (Medium)', 288, 3.6, 37.8, 13.5,
 2.7, 0.0, 111, NULL,
 'manufacturer', ARRAY['mcdonalds medium fries', 'mcdonald fries medium', 'medium fries mcdonalds', 'medium mcd fries'],
 'sides', 'McDonald''s', 1, '320 cal. Medium order of World Famous Fries. Included in most combo meals.', TRUE),

-- Large Fries: 400 cal (154g)
('mcdonalds_fries_large', 'McDonald''s Fries (Large)', 260, 3.2, 36.4, 11.7,
 2.6, 0.0, 154, NULL,
 'manufacturer', ARRAY['mcdonalds large fries', 'mcdonald fries large', 'large fries mcdonalds', 'large mcd fries'],
 'sides', 'McDonald''s', 1, '400 cal. Large order of World Famous Fries.', TRUE),

-- ══════════════════════════════════════════
-- McDONALD'S — DRINKS (by size)
-- ══════════════════════════════════════════

-- Small Coke: 150 cal
('mcdonalds_coke_small', 'McDonald''s Coca-Cola (Small)', 19, 0.0, 4.7, 0.0,
 0.0, 4.7, 473, NULL,
 'manufacturer', ARRAY['mcdonalds small coke', 'mcdonald coke small', 'small coke mcdonalds', 'small coca cola mcdonalds'],
 'drinks', 'McDonald''s', 1, '150 cal. Small fountain Coca-Cola (16 oz).', TRUE),

-- Medium Coke: 220 cal
('mcdonalds_coke_medium', 'McDonald''s Coca-Cola (Medium)', 28, 0.0, 6.9, 0.0,
 0.0, 6.9, 621, NULL,
 'manufacturer', ARRAY['mcdonalds medium coke', 'mcdonald coke medium', 'medium coke mcdonalds', 'medium coca cola mcdonalds'],
 'drinks', 'McDonald''s', 1, '220 cal. Medium fountain Coca-Cola (21 oz). Included in most combo meals.', TRUE),

-- Large Coke: 290 cal
('mcdonalds_coke_large', 'McDonald''s Coca-Cola (Large)', 34, 0.0, 8.5, 0.0,
 0.0, 8.5, 887, NULL,
 'manufacturer', ARRAY['mcdonalds large coke', 'mcdonald coke large', 'large coke mcdonalds', 'large coca cola mcdonalds'],
 'drinks', 'McDonald''s', 1, '290 cal. Large fountain Coca-Cola (30 oz).', TRUE),

-- Diet Coke (any size): 0 cal
('mcdonalds_diet_coke', 'McDonald''s Diet Coke (Any Size)', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 621, NULL,
 'manufacturer', ARRAY['mcdonalds diet coke', 'diet coke mcdonalds', 'mcd diet coke', 'coke zero mcdonalds'],
 'drinks', 'McDonald''s', 1, '0 cal. Diet Coke or Coke Zero — zero calories any size.', TRUE),

-- Sprite Medium: 200 cal
('mcdonalds_sprite_medium', 'McDonald''s Sprite (Medium)', 26, 0.0, 6.3, 0.0,
 0.0, 6.3, 621, NULL,
 'manufacturer', ARRAY['mcdonalds sprite', 'sprite mcdonalds', 'mcd sprite medium'],
 'drinks', 'McDonald''s', 1, '200 cal. Medium fountain Sprite (21 oz).', TRUE),

-- ══════════════════════════════════════════
-- McDONALD'S — COMBO MEALS
-- ══════════════════════════════════════════

-- Big Mac Meal (Medium): 580 + 320 + 220 = 1120 cal
('mcdonalds_big_mac_meal_medium', 'McDonald''s Big Mac Meal (Medium)', 233, 7.0, 27.0, 10.3,
 1.2, 5.5, 481, NULL,
 'manufacturer', ARRAY['big mac meal', 'big mac combo', 'big mac meal medium', 'mcdonalds big mac meal'],
 'combo_meals', 'McDonald''s', 1, '1120 cal total. Big Mac (580) + Medium Fries (320) + Medium Coke (220).', TRUE),

-- Big Mac Meal (Large): 580 + 400 + 290 = 1270 cal
('mcdonalds_big_mac_meal_large', 'McDonald''s Big Mac Meal (Large)', 245, 6.5, 28.0, 10.5,
 1.1, 5.6, 518, NULL,
 'manufacturer', ARRAY['big mac meal large', 'big mac combo large', 'large big mac meal'],
 'combo_meals', 'McDonald''s', 1, '1270 cal total. Big Mac (580) + Large Fries (400) + Large Coke (290).', TRUE),

-- Quarter Pounder Meal (Medium): 520 + 320 + 220 = 1060 cal
('mcdonalds_qpc_meal_medium', 'McDonald''s Quarter Pounder Meal (Medium)', 228, 7.2, 24.5, 10.2,
 1.0, 5.2, 465, NULL,
 'manufacturer', ARRAY['quarter pounder meal', 'qpc meal', 'quarter pounder combo', 'quarter pounder meal medium'],
 'combo_meals', 'McDonald''s', 1, '1060 cal total. Quarter Pounder w/ Cheese (520) + Medium Fries (320) + Medium Coke (220).', TRUE),

-- 10pc McNuggets Meal (Medium): 410 + 320 + 220 = 950 cal
('mcdonalds_nuggets_meal_medium', 'McDonald''s 10pc McNuggets Meal (Medium)', 220, 5.8, 26.5, 9.3,
 1.0, 4.0, 432, NULL,
 'manufacturer', ARRAY['mcnuggets meal', '10 piece nuggets meal', 'nuggets combo mcdonalds', 'mcnuggets meal medium'],
 'combo_meals', 'McDonald''s', 1, '950 cal total. 10pc McNuggets (410) + Medium Fries (320) + Medium Coke (220). Add ~50 cal per sauce.', TRUE),

-- McCrispy Meal (Medium): 470 + 320 + 220 = 1010 cal
('mcdonalds_mccrispy_meal_medium', 'McDonald''s McCrispy Meal (Medium)', 224, 6.0, 24.5, 10.0,
 0.7, 4.0, 451, NULL,
 'manufacturer', ARRAY['mccrispy meal', 'mccrispy combo', 'mccrispy meal medium', 'crispy chicken meal mcdonalds'],
 'combo_meals', 'McDonald''s', 1, '1010 cal total. McCrispy (470) + Medium Fries (320) + Medium Coke (220).', TRUE),

-- Filet-O-Fish Meal (Medium): 390 + 320 + 220 = 930 cal
('mcdonalds_filet_o_fish_meal', 'McDonald''s Filet-O-Fish Meal (Medium)', 224, 5.2, 26.0, 9.5,
 0.8, 4.5, 415, NULL,
 'manufacturer', ARRAY['filet o fish meal', 'fish sandwich meal mcdonalds', 'filet o fish combo'],
 'combo_meals', 'McDonald''s', 1, '930 cal total. Filet-O-Fish (390) + Medium Fries (320) + Medium Coke (220).', TRUE),

-- ══════════════════════════════════════════
-- McDONALD'S — BREAKFAST
-- ══════════════════════════════════════════

-- Egg McMuffin: 300 cal (137g)
('mcdonalds_egg_mcmuffin', 'McDonald''s Egg McMuffin', 219, 12.4, 18.2, 9.5,
 1.5, 2.2, 137, 137,
 'manufacturer', ARRAY['egg mcmuffin', 'mcdonalds egg mcmuffin', 'mcdonald egg mcmuffin', 'mcmuffin egg'],
 'breakfast', 'McDonald''s', 1, '300 cal. Canadian bacon, egg, American cheese on toasted English muffin. Best macro ratio breakfast.', TRUE),

-- Sausage McMuffin with Egg: 480 cal (165g)
('mcdonalds_sausage_mcmuffin_egg', 'McDonald''s Sausage McMuffin with Egg', 291, 12.7, 17.0, 18.8,
 1.2, 1.8, 165, 165,
 'manufacturer', ARRAY['sausage mcmuffin with egg', 'sausage egg mcmuffin', 'mcdonalds sausage mcmuffin', 'sausage mcmuffin egg'],
 'breakfast', 'McDonald''s', 1, '480 cal. Sausage patty, egg, American cheese on English muffin.', TRUE),

-- Hash Brown: 140 cal (56g)
('mcdonalds_hash_brown', 'McDonald''s Hash Brown', 250, 1.8, 25.0, 15.2,
 1.8, 0.0, 56, 56,
 'manufacturer', ARRAY['mcdonalds hash brown', 'mcdonald hash brown', 'hash brown mcdonalds', 'mcd hash brown'],
 'breakfast', 'McDonald''s', 1, '140 cal per piece. Crispy shredded potato patty.', TRUE),

-- Hotcakes: 580 cal (221g)
('mcdonalds_hotcakes', 'McDonald''s Hotcakes', 262, 3.6, 40.7, 9.5,
 0.9, 18.6, 221, NULL,
 'manufacturer', ARRAY['mcdonalds hotcakes', 'mcdonalds pancakes', 'mcdonald hotcakes', 'hotcakes mcdonalds', 'mcd pancakes'],
 'breakfast', 'McDonald''s', 1, '580 cal. Three golden brown hotcakes with butter and syrup.', TRUE),

-- ══════════════════════════════════════════
-- McDONALD'S — DESSERTS
-- ══════════════════════════════════════════

-- McFlurry OREO (regular): 510 cal (285g)
('mcdonalds_mcflurry_oreo', 'McDonald''s McFlurry OREO (Regular)', 179, 3.2, 25.6, 7.0,
 0.4, 19.3, 285, NULL,
 'manufacturer', ARRAY['mcflurry oreo', 'oreo mcflurry', 'mcflurry mcdonalds', 'mcdonald mcflurry oreo'],
 'desserts', 'McDonald''s', 1, '510 cal. Vanilla soft serve with OREO cookie pieces.', TRUE),

-- Shamrock Shake (Medium) (seasonal 2026): 530 cal
('mcdonalds_shamrock_shake', 'McDonald''s Shamrock Shake (Medium)', 167, 2.8, 25.9, 5.7,
 0.0, 22.0, 318, NULL,
 'manufacturer', ARRAY['shamrock shake', 'mcdonalds shamrock shake', 'green shake mcdonalds', 'mint shake mcdonalds'],
 'desserts', 'McDonald''s', 1, '530 cal. Seasonal minty vanilla shake. Returns Feb 2026.', TRUE),

-- ══════════════════════════════════════════
-- CHICK-FIL-A — ENTREES & COMBOS
-- ══════════════════════════════════════════

-- Chick-fil-A Chicken Sandwich: 440 cal (167g)
('chickfila_chicken_sandwich', 'Chick-fil-A Chicken Sandwich', 263, 16.8, 24.6, 10.8,
 0.6, 3.6, 167, 167,
 'manufacturer', ARRAY['chick fil a sandwich', 'chickfila sandwich', 'chick-fil-a chicken sandwich', 'cfa sandwich', 'chickfila original sandwich'],
 'sandwiches', 'Chick-fil-A', 1, '440 cal. Original breaded chicken breast, pickles, butter on toasted bun.', TRUE),

-- Chick-fil-A Spicy Deluxe: 500 cal (227g)
('chickfila_spicy_deluxe', 'Chick-fil-A Spicy Deluxe Sandwich', 220, 12.8, 18.9, 10.1,
 0.9, 2.6, 227, 227,
 'manufacturer', ARRAY['chick fil a spicy deluxe', 'chickfila spicy deluxe', 'spicy deluxe sandwich', 'cfa spicy deluxe'],
 'sandwiches', 'Chick-fil-A', 1, '500 cal. Spicy chicken breast, lettuce, tomato, pepper jack, pickles on toasted bun.', TRUE),

-- Chick-fil-A Nuggets (8 count): 260 cal (113g)
('chickfila_nuggets_8', 'Chick-fil-A Nuggets (8 count)', 230, 24.8, 7.1, 10.6,
 0.0, 0.9, 113, NULL,
 'manufacturer', ARRAY['chick fil a nuggets', 'chickfila nuggets 8', 'cfa nuggets 8 count', 'chick fil a nuggets 8', 'chickfila chicken nuggets'],
 'chicken', 'Chick-fil-A', 1, '260 cal for 8 pieces. Bite-sized boneless chicken breast. Add ~80 cal per sauce.', TRUE),

-- Chick-fil-A Nuggets (12 count): 380 cal (170g)
('chickfila_nuggets_12', 'Chick-fil-A Nuggets (12 count)', 224, 24.7, 7.1, 10.6,
 0.0, 0.6, 170, NULL,
 'manufacturer', ARRAY['chick fil a nuggets 12', 'chickfila nuggets 12', 'cfa nuggets 12 count', '12 piece nuggets chickfila'],
 'chicken', 'Chick-fil-A', 1, '380 cal for 12 pieces.', TRUE),

-- Chick-fil-A Grilled Nuggets (8 count): 130 cal (93g)
('chickfila_grilled_nuggets_8', 'Chick-fil-A Grilled Nuggets (8 count)', 140, 21.5, 1.1, 3.2,
 0.0, 0.0, 93, NULL,
 'manufacturer', ARRAY['chick fil a grilled nuggets', 'chickfila grilled nuggets', 'cfa grilled nuggets', 'grilled nuggets chickfila'],
 'chicken', 'Chick-fil-A', 1, '130 cal for 8 pieces. Marinated grilled chicken. Much lower calorie than breaded (260 cal).', TRUE),

-- Chick-fil-A Waffle Fries (Small): 320 cal (96g)
('chickfila_fries_small', 'Chick-fil-A Waffle Fries (Small)', 333, 3.1, 36.5, 18.8,
 3.1, 0.0, 96, NULL,
 'manufacturer', ARRAY['chick fil a small fries', 'chickfila small waffle fries', 'cfa fries small', 'small waffle fries'],
 'sides', 'Chick-fil-A', 1, '320 cal. Small order of waffle-cut potato fries.', TRUE),

-- Chick-fil-A Waffle Fries (Medium): 420 cal (125g)
('chickfila_fries_medium', 'Chick-fil-A Waffle Fries (Medium)', 336, 3.2, 36.0, 18.4,
 3.2, 0.0, 125, NULL,
 'manufacturer', ARRAY['chick fil a medium fries', 'chickfila medium waffle fries', 'cfa fries medium', 'medium waffle fries'],
 'sides', 'Chick-fil-A', 1, '420 cal. Medium order of waffle fries.', TRUE),

-- Chick-fil-A Waffle Fries (Large): 520 cal (179g)
('chickfila_fries_large', 'Chick-fil-A Waffle Fries (Large)', 291, 2.8, 33.0, 15.6,
 3.4, 0.0, 179, NULL,
 'manufacturer', ARRAY['chick fil a large fries', 'chickfila large waffle fries', 'cfa fries large', 'large waffle fries'],
 'sides', 'Chick-fil-A', 1, '520 cal. Large order of waffle fries.', TRUE),

-- Chick-fil-A Chicken Sandwich Meal (Medium): 440 + 420 + 170 = 1030 cal
('chickfila_sandwich_meal', 'Chick-fil-A Sandwich Meal (Medium)', 265, 8.8, 31.0, 11.5,
 1.3, 5.5, 389, NULL,
 'manufacturer', ARRAY['chick fil a meal', 'chickfila sandwich meal', 'cfa combo', 'chickfila combo meal', 'chick fil a sandwich combo'],
 'combo_meals', 'Chick-fil-A', 1, '~1030 cal total. Chicken Sandwich (440) + Medium Waffle Fries (420) + Medium Lemonade (~170). Varies by drink.', TRUE),

-- Chick-fil-A Nuggets Meal (8pc, Medium): 260 + 420 + 170 = 850 cal
('chickfila_nuggets_meal', 'Chick-fil-A 8pc Nuggets Meal (Medium)', 250, 9.5, 29.0, 10.5,
 1.0, 4.5, 340, NULL,
 'manufacturer', ARRAY['chick fil a nuggets meal', 'chickfila nuggets meal', 'cfa nuggets combo', 'nuggets combo chickfila'],
 'combo_meals', 'Chick-fil-A', 1, '~850 cal total. 8pc Nuggets (260) + Medium Waffle Fries (420) + Medium Lemonade (~170).', TRUE),

-- ══════════════════════════════════════════
-- BURGER KING
-- ══════════════════════════════════════════

-- Whopper: 660 cal (270g)
('bk_whopper', 'Burger King Whopper', 244, 10.4, 17.8, 14.4,
 0.7, 4.1, 270, 270,
 'manufacturer', ARRAY['whopper', 'burger king whopper', 'bk whopper', 'flame grilled whopper'],
 'burgers', 'Burger King', 1, '660 cal. Flame-grilled beef, tomatoes, lettuce, mayo, pickles, onions on sesame seed bun.', TRUE),

-- Whopper Meal (Medium): 660 + 380 + 220 = 1260 cal
('bk_whopper_meal_medium', 'Burger King Whopper Meal (Medium)', 250, 6.5, 27.5, 11.5,
 0.8, 5.5, 504, NULL,
 'manufacturer', ARRAY['whopper meal', 'whopper combo', 'bk whopper meal', 'burger king whopper combo', 'whopper meal medium'],
 'combo_meals', 'Burger King', 1, '~1260 cal total. Whopper (660) + Medium Fries (380) + Medium Coke (220).', TRUE),

-- Whopper Jr: 310 cal (133g)
('bk_whopper_jr', 'Burger King Whopper Jr.', 233, 9.8, 18.0, 13.5,
 0.8, 3.8, 133, 133,
 'manufacturer', ARRAY['whopper jr', 'whopper junior', 'bk whopper jr', 'junior whopper'],
 'burgers', 'Burger King', 1, '310 cal. Smaller version of the Whopper. Flame-grilled beef with classic toppings.', TRUE),

-- Chicken Fries (9 piece): 280 cal (103g)
('bk_chicken_fries', 'Burger King Chicken Fries (9pc)', 272, 13.6, 17.5, 16.5,
 1.0, 0.5, 103, NULL,
 'manufacturer', ARRAY['bk chicken fries', 'burger king chicken fries', 'chicken fries', 'chicken fries 9 piece'],
 'chicken', 'Burger King', 1, '280 cal for 9 pieces. Breaded chicken strips shaped like fries.', TRUE),

-- ══════════════════════════════════════════
-- WENDY'S
-- ══════════════════════════════════════════

-- Dave's Single: 570 cal (218g)
('wendys_daves_single', 'Wendy''s Dave''s Single', 261, 12.8, 17.0, 16.1,
 0.9, 3.7, 218, 218,
 'manufacturer', ARRAY['daves single', 'wendys daves single', 'dave single', 'wendys single burger', 'wendy dave single'],
 'burgers', 'Wendy''s', 1, '570 cal. Fresh beef patty, lettuce, tomato, pickle, onion, ketchup, mayo on toasted bun.', TRUE),

-- Dave's Double: 850 cal (308g)
('wendys_daves_double', 'Wendy''s Dave''s Double', 276, 14.3, 13.6, 18.8,
 0.6, 3.2, 308, 308,
 'manufacturer', ARRAY['daves double', 'wendys daves double', 'dave double', 'wendys double burger'],
 'burgers', 'Wendy''s', 1, '850 cal. Two fresh beef patties, American cheese, lettuce, tomato, pickle, onion, condiments.', TRUE),

-- Dave's Single Meal (Medium): 570 + 350 + 200 = 1120 cal
('wendys_daves_single_meal', 'Wendy''s Dave''s Single Meal (Medium)', 238, 7.5, 25.0, 11.0,
 0.8, 5.0, 470, NULL,
 'manufacturer', ARRAY['daves single meal', 'wendys single meal', 'daves single combo', 'wendys combo meal'],
 'combo_meals', 'Wendy''s', 1, '~1120 cal total. Dave''s Single (570) + Medium Fries (350) + Medium Coke (200).', TRUE),

-- Spicy Chicken Sandwich: 480 cal (185g)
('wendys_spicy_chicken', 'Wendy''s Spicy Chicken Sandwich', 259, 14.1, 24.3, 12.4,
 0.5, 2.7, 185, 185,
 'manufacturer', ARRAY['wendys spicy chicken', 'spicy chicken wendys', 'wendy spicy chicken sandwich', 'wendys spicy sandwich'],
 'sandwiches', 'Wendy''s', 1, '480 cal. Spicy chicken breast fillet, lettuce, tomato, mayo on toasted bun.', TRUE),

-- Baconator: 940 cal (306g)
('wendys_baconator', 'Wendy''s Baconator', 307, 17.6, 12.1, 21.2,
 0.3, 3.3, 306, 306,
 'manufacturer', ARRAY['baconator', 'wendys baconator', 'wendy baconator', 'baconator burger'],
 'burgers', 'Wendy''s', 1, '940 cal. Two fresh beef patties, 6 strips of bacon, American cheese, ketchup, mayo.', TRUE),

-- Wendy's Medium Fries: 350 cal (125g)
('wendys_fries_medium', 'Wendy''s Fries (Medium)', 280, 3.2, 36.0, 14.4,
 3.2, 0.0, 125, NULL,
 'manufacturer', ARRAY['wendys medium fries', 'wendy fries medium', 'medium fries wendys'],
 'sides', 'Wendy''s', 1, '350 cal. Natural-cut fries with sea salt.', TRUE),

-- Frosty (Medium chocolate): 460 cal (340g)
('wendys_frosty_medium', 'Wendy''s Frosty Chocolate (Medium)', 135, 2.6, 21.2, 4.7,
 0.3, 16.5, 340, NULL,
 'manufacturer', ARRAY['wendys frosty', 'frosty chocolate', 'wendy frosty medium', 'chocolate frosty wendys'],
 'desserts', 'Wendy''s', 1, '460 cal. Signature frozen dessert. Medium size.', TRUE),

-- ══════════════════════════════════════════
-- TACO BELL
-- ══════════════════════════════════════════

-- Crunchwrap Supreme: 530 cal (254g)
('taco_bell_crunchwrap_supreme', 'Taco Bell Crunchwrap Supreme', 209, 6.7, 18.5, 11.4,
 1.2, 1.6, 254, 254,
 'manufacturer', ARRAY['crunchwrap supreme', 'taco bell crunchwrap', 'crunchwrap', 'crunchwrap supreme taco bell'],
 'burritos', 'Taco Bell', 1, '530 cal. Seasoned beef, nacho cheese, lettuce, tomato, sour cream, tostada shell in grilled flour tortilla.', TRUE),

-- Crunchwrap Supreme Combo: 530 + 170 + 200 = 900 cal
('taco_bell_crunchwrap_combo', 'Taco Bell Crunchwrap Supreme Combo', 205, 5.5, 22.0, 8.5,
 1.0, 4.0, 440, NULL,
 'manufacturer', ARRAY['crunchwrap combo', 'taco bell crunchwrap combo', 'crunchwrap supreme combo', 'crunchwrap meal'],
 'combo_meals', 'Taco Bell', 1, '~900 cal total. Crunchwrap Supreme (530) + Chips & Nacho Cheese (170) + Medium Baja Blast (200).', TRUE),

-- Cheesy Gordita Crunch: 500 cal (153g)
('taco_bell_cheesy_gordita_crunch', 'Taco Bell Cheesy Gordita Crunch', 327, 10.5, 21.6, 21.6,
 1.3, 2.0, 153, 153,
 'manufacturer', ARRAY['cheesy gordita crunch', 'taco bell gordita crunch', 'cgc taco bell', 'gordita crunch'],
 'burritos', 'Taco Bell', 1, '500 cal. Crunchy taco inside a warm flatbread with spicy ranch and three-cheese blend.', TRUE),

-- Mexican Pizza: 540 cal (213g)
('taco_bell_mexican_pizza', 'Taco Bell Mexican Pizza', 253, 8.9, 17.4, 16.4,
 1.4, 1.4, 213, 213,
 'manufacturer', ARRAY['mexican pizza', 'taco bell mexican pizza', 'tb mexican pizza'],
 'burritos', 'Taco Bell', 1, '540 cal. Seasoned beef, beans, pizza sauce, cheese, tomato between two fried flour shells.', TRUE),

-- Taco (crunchy): 170 cal (78g)
('taco_bell_crunchy_taco', 'Taco Bell Crunchy Taco', 218, 10.3, 15.4, 12.8,
 1.3, 1.3, 78, 78,
 'manufacturer', ARRAY['taco bell crunchy taco', 'crunchy taco', 'taco bell taco', 'hard shell taco taco bell'],
 'tacos', 'Taco Bell', 1, '170 cal. Seasoned beef, lettuce, cheddar cheese in a crunchy corn shell.', TRUE),

-- Burrito Supreme: 380 cal (248g)
('taco_bell_burrito_supreme', 'Taco Bell Burrito Supreme', 153, 5.6, 16.1, 7.3,
 2.0, 1.2, 248, 248,
 'manufacturer', ARRAY['burrito supreme', 'taco bell burrito supreme', 'burrito supreme taco bell'],
 'burritos', 'Taco Bell', 1, '380 cal. Seasoned beef, beans, lettuce, tomato, sour cream, onion, red sauce in flour tortilla.', TRUE),

-- ══════════════════════════════════════════
-- POPEYES
-- ══════════════════════════════════════════

-- Popeyes Chicken Sandwich: 700 cal (218g)
('popeyes_chicken_sandwich', 'Popeyes Chicken Sandwich', 321, 12.8, 22.5, 19.7,
 0.9, 2.8, 218, 218,
 'manufacturer', ARRAY['popeyes chicken sandwich', 'popeyes sandwich', 'popeye chicken sandwich', 'popeyes crispy chicken sandwich'],
 'sandwiches', 'Popeyes', 1, '700 cal. Buttermilk-battered chicken breast, pickles, mayo on toasted brioche bun.', TRUE),

-- Popeyes 3pc Chicken Tenders: 340 cal (127g)
('popeyes_3pc_tenders', 'Popeyes 3pc Chicken Tenders', 268, 18.9, 11.8, 16.5,
 0.8, 0.0, 127, NULL,
 'manufacturer', ARRAY['popeyes tenders', 'popeyes chicken tenders 3 piece', 'popeye tenders', 'popeyes 3pc tenders'],
 'chicken', 'Popeyes', 1, '340 cal for 3 tenders. Hand-battered and breaded.', TRUE),

-- Popeyes Chicken Sandwich Combo: 700 + 260 + 220 = 1180 cal
('popeyes_sandwich_combo', 'Popeyes Chicken Sandwich Combo', 262, 7.5, 25.0, 13.5,
 0.8, 5.0, 450, NULL,
 'manufacturer', ARRAY['popeyes combo', 'popeyes sandwich combo', 'popeyes chicken sandwich meal', 'popeyes sandwich meal'],
 'combo_meals', 'Popeyes', 1, '~1180 cal total. Chicken Sandwich (700) + Regular Fries (260) + Regular Drink (220).', TRUE),

-- ══════════════════════════════════════════
-- SUBWAY (6-inch)
-- ══════════════════════════════════════════

-- Subway Turkey Breast (6"): 270 cal (213g)
('subway_turkey_6inch', 'Subway Turkey Breast (6")', 127, 8.5, 16.0, 2.8,
 2.3, 3.3, 213, 213,
 'manufacturer', ARRAY['subway turkey', 'subway 6 inch turkey', 'subway turkey breast', 'turkey sub subway'],
 'sandwiches', 'Subway', 1, '270 cal. 6-inch turkey breast sub with standard veggies on white bread.', TRUE),

-- Subway Italian BMT (6"): 370 cal (232g)
('subway_italian_bmt_6inch', 'Subway Italian BMT (6")', 159, 7.3, 16.4, 7.3,
 2.2, 3.0, 232, 232,
 'manufacturer', ARRAY['subway italian bmt', 'subway bmt', 'italian bmt sub', 'subway italian sandwich'],
 'sandwiches', 'Subway', 1, '370 cal. Genoa salami, spicy pepperoni, Black Forest ham with veggies.', TRUE),

-- Subway Steak & Cheese (6"): 350 cal (240g)
('subway_steak_cheese_6inch', 'Subway Steak & Cheese (6")', 146, 10.4, 16.3, 4.6,
 2.1, 2.9, 240, 240,
 'manufacturer', ARRAY['subway steak and cheese', 'subway steak cheese', 'steak cheese sub subway', 'subway philly cheesesteak'],
 'sandwiches', 'Subway', 1, '350 cal. Shaved steak with American cheese on white bread with veggies.', TRUE),

-- Subway Footlong Turkey: 540 cal (426g)
('subway_turkey_footlong', 'Subway Turkey Breast (Footlong)', 127, 8.5, 16.0, 2.8,
 2.3, 3.3, 426, 426,
 'manufacturer', ARRAY['subway footlong turkey', 'footlong turkey sub', 'subway 12 inch turkey', 'turkey footlong subway'],
 'sandwiches', 'Subway', 1, '540 cal. Footlong turkey breast sub. Double the 6-inch.', TRUE),

-- Subway Meal Deal (6" sub + chips + drink)
('subway_meal_deal', 'Subway Meal Deal (6" + Chips + Drink)', 210, 6.0, 28.5, 7.5,
 1.8, 6.0, 400, NULL,
 'manufacturer', ARRAY['subway meal', 'subway combo', 'subway meal deal', 'subway sub combo'],
 'combo_meals', 'Subway', 1, '~840 cal total avg. 6" Turkey (270) + Lay''s Chips (160) + Medium Fountain Drink (~200). Varies by sub choice.', TRUE)

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
