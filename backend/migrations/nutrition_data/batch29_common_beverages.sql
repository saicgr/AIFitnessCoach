-- ============================================================================
-- Batch 29: Common Beverages
-- ~50 items commonly logged in fitness/calorie tracking apps
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central, manufacturer nutrition labels
-- All values are per 100g (for liquids, 100ml ≈ 100g approximately)
-- Calorie verification: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- COFFEE (~8 items)
-- ============================================================================

-- Black Coffee (brewed): 1 cal, 0.1g protein, 0.0g carbs, 0.0g fat per 100ml. Serving=8oz (237ml)
('black_coffee', 'Black Coffee (brewed)', 1.0, 0.1, 0.0, 0.0, 0.0, 0.0, NULL, 237, 'usda', ARRAY['brewed coffee', 'drip coffee', 'filter coffee', 'plain coffee', 'coffee black'], '2 cal per 8 oz cup (237ml).', NULL, 'drinks', 1),

-- Coffee with Cream (2 tbsp heavy cream): ~28 cal per 100ml when mixed. Serving=8oz (267ml: 237ml coffee + 30ml cream)
-- 2 tbsp heavy cream (30ml) = 100 cal. Total drink ~102 cal / 267ml * 100 = 38.2
('coffee_with_cream', 'Coffee with Cream (2 tbsp)', 38.0, 0.4, 0.5, 3.7, 0.0, 0.5, NULL, 267, 'usda', ARRAY['coffee cream', 'coffee with heavy cream', 'cream coffee'], '102 cal per cup (267ml). Brewed coffee + 2 tbsp heavy cream.', NULL, 'drinks', 1),

-- Coffee with Half and Half (2 tbsp): Serving=8oz (267ml: 237ml coffee + 30ml half & half)
-- 2 tbsp half & half (30ml) = 40 cal. Total ~42 cal / 267ml * 100 = 15.7
('coffee_half_and_half', 'Coffee with Half and Half', 16.0, 0.4, 0.7, 1.2, 0.0, 0.7, NULL, 267, 'usda', ARRAY['coffee half n half', 'coffee with half and half'], '42 cal per cup (267ml). Brewed coffee + 2 tbsp half & half.', NULL, 'drinks', 1),

-- Espresso (1 shot, 30ml): 1 cal per 100ml. Serving=1 shot (30ml)
('espresso', 'Espresso (1 shot)', 3.3, 0.1, 0.6, 0.0, 0.0, 0.0, NULL, 30, 'usda', ARRAY['espresso shot', 'single espresso', 'shot of espresso', 'ristretto'], '1 cal per 1 shot (30ml).', NULL, 'drinks', 1),

-- Latte (whole milk, 12oz): whole milk steamed. 12oz = 355ml. ~180 cal total.
-- 300ml whole milk + 30ml espresso ≈ 330ml. 180/355 * 100 = 50.7 cal/100ml
('latte_whole_milk', 'Latte (whole milk, 12oz)', 51.0, 2.6, 3.8, 2.7, 0.0, 3.8, NULL, 355, 'usda', ARRAY['caffe latte', 'milk latte', 'whole milk latte', 'hot latte'], '180 cal per 12 oz (355ml).', NULL, 'drinks', 1),

-- Cappuccino (whole milk, 12oz): less milk than latte. ~120 cal total.
-- 120/355*100 = 33.8
('cappuccino', 'Cappuccino (whole milk, 12oz)', 34.0, 1.7, 2.5, 1.8, 0.0, 2.5, NULL, 355, 'usda', ARRAY['cap', 'whole milk cappuccino'], '120 cal per 12 oz (355ml).', NULL, 'drinks', 1),

-- Cold Brew (black): 2 cal per 100ml. Serving=16oz (473ml)
('cold_brew', 'Cold Brew Coffee (black)', 2.0, 0.1, 0.0, 0.0, 0.0, 0.0, NULL, 473, 'usda', ARRAY['cold brew black', 'cold brewed coffee', 'cold brew concentrate', 'iced cold brew'], '5 cal per 16 oz (473ml). Slightly higher caffeine than drip.', NULL, 'drinks', 1),

-- Iced Coffee (black): 1 cal per 100ml. Serving=16oz (473ml)
('iced_coffee_black', 'Iced Coffee (black)', 1.0, 0.1, 0.0, 0.0, 0.0, 0.0, NULL, 473, 'usda', ARRAY['iced coffee', 'iced black coffee', 'cold coffee black'], '5 cal per 16 oz (473ml).', NULL, 'drinks', 1),

-- ============================================================================
-- TEA (~6 items)
-- ============================================================================

-- Black Tea (unsweetened): 1 cal per 100ml. Serving=8oz (237ml)
('black_tea', 'Black Tea (unsweetened)', 1.0, 0.0, 0.3, 0.0, 0.0, 0.0, NULL, 237, 'usda', ARRAY['hot tea', 'brewed black tea', 'english breakfast tea', 'earl grey tea', 'tea unsweetened'], '2 cal per 8 oz cup (237ml).', NULL, 'drinks', 1),

-- Green Tea (unsweetened): 1 cal per 100ml. Serving=8oz (237ml)
('green_tea', 'Green Tea (unsweetened)', 1.0, 0.0, 0.2, 0.0, 0.0, 0.0, NULL, 237, 'usda', ARRAY['brewed green tea', 'matcha green tea unsweetened', 'sencha', 'japanese green tea'], '1 cal per 8 oz cup (237ml).', NULL, 'drinks', 1),

-- Chai Tea Latte (whole milk, 12oz): ~190 cal total.
-- 190/355*100 = 53.5
('chai_tea_latte', 'Chai Tea Latte (whole milk)', 54.0, 2.3, 7.3, 1.8, 0.0, 6.2, NULL, 355, 'usda', ARRAY['chai latte', 'spiced chai latte', 'dirty chai', 'masala chai latte'], '190 cal per 12 oz (355ml).', NULL, 'drinks', 1),

-- Iced Tea (sweetened): 33 cal per 100ml. Serving=16oz (473ml)
-- Check: 0*4 + 8.1*4 + 0*9 = 32.4
('iced_tea_sweetened', 'Iced Tea (sweetened)', 33.0, 0.0, 8.1, 0.0, 0.0, 8.1, NULL, 473, 'usda', ARRAY['sweet tea', 'southern sweet tea', 'sweetened iced tea'], '156 cal per 16 oz (473ml).', NULL, 'drinks', 1),

-- Iced Tea (unsweetened): 1 cal per 100ml. Serving=16oz (473ml)
('iced_tea_unsweetened', 'Iced Tea (unsweetened)', 1.0, 0.0, 0.2, 0.0, 0.0, 0.0, NULL, 473, 'usda', ARRAY['unsweet tea', 'unsweetened tea', 'plain iced tea'], '5 cal per 16 oz (473ml).', NULL, 'drinks', 1),

-- Herbal Tea (unsweetened): 1 cal per 100ml. Serving=8oz (237ml)
('herbal_tea', 'Herbal Tea (unsweetened)', 1.0, 0.0, 0.2, 0.0, 0.0, 0.0, NULL, 237, 'usda', ARRAY['chamomile tea', 'peppermint tea', 'ginger tea', 'rooibos tea', 'herbal infusion'], '1 cal per 8 oz cup (237ml).', NULL, 'drinks', 1),

-- ============================================================================
-- JUICE (~8 items)
-- ============================================================================

-- Orange Juice: 45 cal, 0.7g protein, 10.4g carbs, 0.2g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.7*4 + 10.4*4 + 0.2*9 = 2.8 + 41.6 + 1.8 = 46.2 (labeled 45)
('orange_juice', 'Orange Juice', 45.0, 0.7, 10.4, 0.2, 0.2, 8.4, NULL, 240, 'usda', ARRAY['oj', 'fresh orange juice', 'tropicana orange juice', 'minute maid orange juice', 'fresh squeezed oj'], '108 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Apple Juice: 46 cal, 0.1g protein, 11.3g carbs, 0.1g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.1*4 + 11.3*4 + 0.1*9 = 0.4 + 45.2 + 0.9 = 46.5
('apple_juice', 'Apple Juice', 46.0, 0.1, 11.3, 0.1, 0.1, 9.6, NULL, 240, 'usda', ARRAY['apple cider', 'fresh apple juice', 'mott''s apple juice'], '110 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Cranberry Juice Cocktail: 54 cal, 0.0g protein, 13.5g carbs, 0.1g fat per 100ml. Serving=8oz (240ml)
-- Check: 0*4 + 13.5*4 + 0.1*9 = 54.9 (labeled 54)
('cranberry_juice_cocktail', 'Cranberry Juice Cocktail', 54.0, 0.0, 13.5, 0.1, 0.0, 12.1, NULL, 240, 'usda', ARRAY['cranberry juice', 'cran juice', 'ocean spray cranberry'], '130 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Grape Juice: 60 cal, 0.4g protein, 14.8g carbs, 0.1g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.4*4 + 14.8*4 + 0.1*9 = 1.6 + 59.2 + 0.9 = 61.7 (labeled 60)
('grape_juice', 'Grape Juice', 60.0, 0.4, 14.8, 0.1, 0.1, 14.2, NULL, 240, 'usda', ARRAY['concord grape juice', 'welchs grape juice', 'purple grape juice'], '144 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Grapefruit Juice: 39 cal, 0.5g protein, 9.2g carbs, 0.1g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.5*4 + 9.2*4 + 0.1*9 = 2 + 36.8 + 0.9 = 39.7
('grapefruit_juice', 'Grapefruit Juice', 39.0, 0.5, 9.2, 0.1, 0.1, 9.2, NULL, 240, 'usda', ARRAY['fresh grapefruit juice', 'ruby red grapefruit juice'], '94 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Tomato Juice: 17 cal, 0.8g protein, 3.5g carbs, 0.1g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.8*4 + 3.5*4 + 0.1*9 = 3.2 + 14 + 0.9 = 18.1 (labeled 17)
('tomato_juice', 'Tomato Juice', 17.0, 0.8, 3.5, 0.1, 0.4, 2.6, NULL, 240, 'usda', ARRAY['v8 tomato juice', 'tomato vegetable juice', 'canned tomato juice'], '41 cal per 8 oz glass (240ml). 600-900mg sodium per serving.', NULL, 'drinks', 1),

-- Lemonade: 40 cal, 0.1g protein, 10.6g carbs, 0.0g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.1*4 + 10.6*4 + 0*9 = 0.4 + 42.4 = 42.8 (labeled 40)
('lemonade', 'Lemonade', 40.0, 0.1, 10.6, 0.0, 0.0, 9.6, NULL, 240, 'usda', ARRAY['fresh lemonade', 'homemade lemonade', 'pink lemonade'], '96 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Pomegranate Juice: 54 cal, 0.2g protein, 13.1g carbs, 0.3g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.2*4 + 13.1*4 + 0.3*9 = 0.8 + 52.4 + 2.7 = 55.9 (labeled 54)
('pomegranate_juice', 'Pomegranate Juice', 54.0, 0.2, 13.1, 0.3, 0.1, 12.7, NULL, 240, 'usda', ARRAY['pom juice', 'pom wonderful', 'fresh pomegranate juice'], '130 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- ============================================================================
-- SODA (~8 items) - using 'soda_' prefix for normalized names
-- ============================================================================

-- Coca-Cola (generic, 12oz can): 42 cal, 0.0g protein, 10.6g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 10.6*4 = 42.4
('soda_coca_cola', 'Coca-Cola', 42.0, 0.0, 10.6, 0.0, 0.0, 10.6, NULL, 355, 'usda', ARRAY['coke', 'coca cola', 'coca-cola', 'cola', 'regular coke'], '140 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Diet Coke: 0 cal per 100ml. Serving=12oz can (355ml)
('soda_diet_coke', 'Diet Coke', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 355, 'usda', ARRAY['diet coca cola', 'coke zero', 'diet cola', 'zero sugar coke'], '0 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Pepsi: 42 cal, 0.0g protein, 11.2g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 0*4 + 11.2*4 + 0*9 = 44.8 (labeled 42, sucrose/HFCS factor)
('soda_pepsi', 'Pepsi', 42.0, 0.0, 11.2, 0.0, 0.0, 11.0, NULL, 355, 'usda', ARRAY['pepsi cola', 'pepsi soda'], '150 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Sprite: 40 cal, 0.0g protein, 10.1g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 10.1*4 = 40.4
('soda_sprite', 'Sprite', 40.0, 0.0, 10.1, 0.0, 0.0, 10.1, NULL, 355, 'usda', ARRAY['sprite soda', 'lemon lime soda'], '140 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Dr Pepper: 42 cal, 0.0g protein, 10.8g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 10.8*4 = 43.2 (labeled 42)
('soda_dr_pepper', 'Dr Pepper', 42.0, 0.0, 10.8, 0.0, 0.0, 10.8, NULL, 355, 'usda', ARRAY['dr. pepper', 'doctor pepper', 'dr pepper soda'], '150 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Mountain Dew: 46 cal, 0.0g protein, 12.3g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 12.3*4 = 49.2 (labeled 46)
('soda_mountain_dew', 'Mountain Dew', 46.0, 0.0, 12.3, 0.0, 0.0, 12.3, NULL, 355, 'usda', ARRAY['mtn dew', 'mt dew', 'mountain dew soda'], '170 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Ginger Ale: 34 cal, 0.0g protein, 8.8g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 8.8*4 = 35.2 (labeled 34)
('soda_ginger_ale', 'Ginger Ale', 34.0, 0.0, 8.8, 0.0, 0.0, 8.5, NULL, 355, 'usda', ARRAY['canada dry ginger ale', 'schweppes ginger ale', 'ginger soda'], '120 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- Root Beer: 42 cal, 0.0g protein, 10.6g carbs, 0.0g fat per 100ml. Serving=12oz can (355ml)
-- Check: 10.6*4 = 42.4
('soda_root_beer', 'Root Beer', 42.0, 0.0, 10.6, 0.0, 0.0, 10.6, NULL, 355, 'usda', ARRAY['a&w root beer', 'barqs root beer', 'mug root beer', 'root beer soda'], '150 cal per 12 oz can (355ml).', NULL, 'drinks', 1),

-- ============================================================================
-- SPORTS & ENERGY DRINKS (~6 items)
-- ============================================================================

-- Gatorade (original/lemon-lime): 25 cal, 0.0g protein, 6.3g carbs, 0.0g fat per 100ml. Serving=20oz (591ml)
-- Check: 6.3*4 = 25.2
('gatorade', 'Gatorade (original)', 25.0, 0.0, 6.3, 0.0, 0.0, 5.9, NULL, 591, 'usda', ARRAY['gatorade thirst quencher', 'gatorade lemon lime', 'gatorade orange', 'gatorade fruit punch'], '140 cal per 20 oz bottle (591ml).', NULL, 'drinks', 1),

-- Powerade: 19 cal, 0.0g protein, 4.9g carbs, 0.0g fat per 100ml. Serving=20oz (591ml)
-- Check: 4.9*4 = 19.6
('powerade', 'Powerade', 19.0, 0.0, 4.9, 0.0, 0.0, 4.9, NULL, 591, 'usda', ARRAY['powerade mountain blast', 'powerade sports drink', 'powerade ion4'], '112 cal per 20 oz bottle (591ml).', NULL, 'drinks', 1),

-- Coconut Water: 19 cal, 0.7g protein, 3.7g carbs, 0.2g fat per 100ml. Serving=11oz (330ml)
-- Check: 0.7*4 + 3.7*4 + 0.2*9 = 2.8 + 14.8 + 1.8 = 19.4
('coconut_water', 'Coconut Water', 19.0, 0.7, 3.7, 0.2, 1.1, 2.6, NULL, 330, 'usda', ARRAY['pure coconut water', 'vita coco', 'zico coconut water', 'tender coconut water'], '63 cal per 11 oz container (330ml). Rich in potassium.', NULL, 'drinks', 1),

-- Pedialyte: 10 cal, 0.0g protein, 2.5g carbs, 0.0g fat per 100ml. Serving=12oz (355ml)
-- Check: 2.5*4 = 10
('pedialyte', 'Pedialyte', 10.0, 0.0, 2.5, 0.0, 0.0, 2.5, NULL, 355, 'usda', ARRAY['pedialyte electrolyte solution', 'pedialyte advanced care'], '35 cal per 12 oz (355ml). Electrolyte replacement.', NULL, 'drinks', 1),

-- Red Bull (regular, 8.4oz): 45 cal, 0.3g protein, 11.2g carbs, 0.0g fat per 100ml. Serving=8.4oz can (250ml)
-- Check: 0.3*4 + 11.2*4 + 0*9 = 1.2 + 44.8 = 46.0 (labeled 45)
('red_bull', 'Red Bull (regular)', 45.0, 0.3, 11.2, 0.0, 0.0, 11.0, NULL, 250, 'usda', ARRAY['red bull energy drink', 'redbull', 'red bull original'], '112 cal per 8.4 oz can (250ml). 80mg caffeine.', NULL, 'drinks', 1),

-- Monster Energy (16oz): 42 cal, 0.0g protein, 10.6g carbs, 0.0g fat per 100ml. Serving=16oz can (473ml)
-- Check: 10.6*4 = 42.4
('monster_energy', 'Monster Energy', 42.0, 0.0, 10.6, 0.0, 0.0, 10.4, NULL, 473, 'usda', ARRAY['monster energy drink', 'monster green', 'monster original'], '200 cal per 16 oz can (473ml). 160mg caffeine.', NULL, 'drinks', 1),

-- ============================================================================
-- WATER (~3 items)
-- ============================================================================

-- Sparkling Water (plain): 0 cal per 100ml. Serving=12oz (355ml)
('sparkling_water', 'Sparkling Water (plain)', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 355, 'usda', ARRAY['seltzer water', 'club soda', 'carbonated water', 'la croix', 'perrier', 'topo chico'], '0 cal per 12 oz (355ml).', NULL, 'drinks', 1),

-- Vitamin Water: 20 cal, 0.0g protein, 5.2g carbs, 0.0g fat per 100ml. Serving=20oz (591ml)
-- Check: 5.2*4 = 20.8
('vitamin_water', 'Vitamin Water', 20.0, 0.0, 5.2, 0.0, 0.0, 5.0, NULL, 591, 'usda', ARRAY['vitaminwater', 'glaceau vitamin water'], '120 cal per 20 oz bottle (591ml).', NULL, 'drinks', 1),

-- Electrolyte Water (e.g., SmartWater, Essentia): 0 cal per 100ml. Serving=20oz (591ml)
('electrolyte_water', 'Electrolyte Water', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 591, 'usda', ARRAY['smart water', 'smartwater', 'essentia water', 'alkaline water', 'ionized water'], '0 cal per 20 oz bottle (591ml). Enhanced with electrolytes.', NULL, 'drinks', 1),

-- ============================================================================
-- ALCOHOL (~8 items)
-- ============================================================================

-- Beer (regular, 12oz): 43 cal, 0.5g protein, 3.6g carbs, 0.0g fat per 100ml. Serving=12oz (355ml)
-- Check: 0.5*4 + 3.6*4 + 0*9 = 2 + 14.4 = 16.4 (labeled 43, alcohol 3.9g*7=27.3 cal/100ml)
('beer_regular', 'Beer (regular, 12oz)', 43.0, 0.5, 3.6, 0.0, 0.0, 0.0, NULL, 355, 'usda', ARRAY['regular beer', 'lager', 'domestic beer', 'pale ale', 'draft beer', 'beer'], '153 cal per 12 oz can/bottle (355ml). ~5% ABV.', NULL, 'drinks', 1),

-- Beer (light, 12oz): 29 cal, 0.2g protein, 1.3g carbs, 0.0g fat per 100ml. Serving=12oz (355ml)
-- Check: 0.2*4 + 1.3*4 + 0*9 = 6.0 (labeled 29, alcohol ~3.2g*7=22.4 cal/100ml)
('beer_light', 'Beer (light, 12oz)', 29.0, 0.2, 1.3, 0.0, 0.0, 0.0, NULL, 355, 'usda', ARRAY['light beer', 'bud light', 'coors light', 'miller lite', 'michelob ultra'], '103 cal per 12 oz can/bottle (355ml). ~4.2% ABV.', NULL, 'drinks', 1),

-- Red Wine (5oz): 85 cal, 0.1g protein, 2.6g carbs, 0.0g fat per 100ml. Serving=5oz (148ml)
-- Check: 0.1*4 + 2.6*4 + 0*9 = 10.8 (labeled 85, alcohol 10.6g*7=74.2 cal/100ml)
('red_wine', 'Red Wine (5oz)', 85.0, 0.1, 2.6, 0.0, 0.0, 0.6, NULL, 148, 'usda', ARRAY['cabernet sauvignon', 'merlot', 'pinot noir', 'red wine glass', 'wine red'], '125 cal per 5 oz glass (148ml). ~13.5% ABV.', NULL, 'drinks', 1),

-- White Wine (5oz): 82 cal, 0.1g protein, 2.6g carbs, 0.0g fat per 100ml. Serving=5oz (148ml)
-- Check: 0.1*4 + 2.6*4 + 0*9 = 10.8 (labeled 82, alcohol ~10.1g*7=70.7 cal/100ml)
('white_wine', 'White Wine (5oz)', 82.0, 0.1, 2.6, 0.0, 0.0, 1.0, NULL, 148, 'usda', ARRAY['chardonnay', 'sauvignon blanc', 'pinot grigio', 'white wine glass', 'wine white', 'riesling'], '121 cal per 5 oz glass (148ml). ~13% ABV.', NULL, 'drinks', 1),

-- Vodka (1.5oz shot): 231 cal, 0.0g protein, 0.0g carbs, 0.0g fat per 100ml. Serving=1.5oz (44ml)
-- Check: all macros 0 (labeled 231, alcohol 33g*7=231 cal/100ml)
('vodka', 'Vodka (1.5oz shot)', 231.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 44, 'usda', ARRAY['vodka shot', 'plain vodka', 'unflavored vodka', 'shot of vodka'], '97 cal per 1.5 oz shot (44ml). 80 proof/40% ABV.', NULL, 'drinks', 1),

-- Whiskey (1.5oz shot): 250 cal, 0.0g protein, 0.0g carbs, 0.0g fat per 100ml. Serving=1.5oz (44ml)
-- Check: all macros 0 (labeled 250, alcohol 35.7g*7=250 cal/100ml)
('whiskey', 'Whiskey (1.5oz shot)', 250.0, 0.0, 0.0, 0.0, 0.0, 0.0, NULL, 44, 'usda', ARRAY['bourbon', 'scotch', 'rye whiskey', 'jack daniels', 'whisky', 'shot of whiskey'], '110 cal per 1.5 oz shot (44ml). 86 proof/43% ABV.', NULL, 'drinks', 1),

-- Margarita: 90 cal, 0.1g protein, 9.5g carbs, 0.0g fat per 100ml. Serving=8oz (240ml)
-- Check: 0.1*4 + 9.5*4 + 0*9 = 38.4 (labeled 90, alcohol ~7.4g*7=51.8 cal/100ml)
('margarita', 'Margarita', 90.0, 0.1, 9.5, 0.0, 0.1, 8.5, NULL, 240, 'usda', ARRAY['classic margarita', 'frozen margarita', 'lime margarita', 'margarita on the rocks'], '216 cal per 8 oz glass (240ml).', NULL, 'drinks', 1),

-- Mimosa: 62 cal, 0.3g protein, 5.5g carbs, 0.1g fat per 100ml. Serving=6oz (177ml)
-- Check: 0.3*4 + 5.5*4 + 0.1*9 = 1.2 + 22 + 0.9 = 24.1 (labeled 62, alcohol ~5.4g*7=37.8 cal/100ml)
('mimosa', 'Mimosa', 62.0, 0.3, 5.5, 0.1, 0.0, 4.5, NULL, 177, 'usda', ARRAY['champagne mimosa', 'brunch mimosa', 'bellini'], '110 cal per 6 oz glass (177ml). Champagne + orange juice.', NULL, 'drinks', 1),

-- ============================================================================
-- SMOOTHIES & SHAKES (~3 items)
-- ============================================================================

-- Protein Shake (whey, water): ~48 cal per 100ml. 1 scoop (31g, 120cal) in 350ml water = 381ml total
-- 120/381*100 = 31.5 cal/100ml
('protein_shake_whey', 'Protein Shake (whey + water)', 32.0, 6.6, 1.0, 0.4, 0.3, 0.5, NULL, 381, 'usda', ARRAY['whey protein shake', 'protein shake water', 'post workout shake', 'whey shake'], '120 cal per shake (1 scoop + 12oz water). ~24g protein per serving.', NULL, 'drinks', 1),

-- Green Smoothie (generic: spinach, banana, almond milk, protein): ~50 cal per 100ml. Serving=16oz (473ml)
-- ~240 cal total. 240/473*100 = 50.7
('green_smoothie', 'Green Smoothie (generic)', 51.0, 2.5, 8.5, 1.0, 1.5, 5.5, NULL, 473, 'usda', ARRAY['green juice', 'spinach smoothie', 'detox smoothie', 'green protein smoothie'], '240 cal per 16 oz (473ml). Spinach, banana, almond milk blend.', NULL, 'drinks', 1),

-- Fruit Smoothie (generic: mixed berry, banana, yogurt): ~65 cal per 100ml. Serving=16oz (473ml)
-- ~310 cal total. 310/473*100 = 65.5
('fruit_smoothie', 'Fruit Smoothie (generic)', 66.0, 1.7, 14.0, 0.6, 1.0, 11.0, NULL, 473, 'usda', ARRAY['berry smoothie', 'mixed fruit smoothie', 'banana smoothie', 'strawberry banana smoothie'], '310 cal per 16 oz (473ml). Mixed berries, banana, yogurt blend.', NULL, 'drinks', 1),
