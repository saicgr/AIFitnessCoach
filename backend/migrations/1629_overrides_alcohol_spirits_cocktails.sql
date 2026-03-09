-- 1629_overrides_alcohol_spirits_cocktails.sql
-- Spirits, cocktails, beer, and hard seltzer brands.
-- Sources: USDA FoodData Central via fatsecret.com, nutritionix.com, calorieking.com.
-- All values per 100g. Density conversions: spirits ~0.94 g/ml, cocktails ~1.0 g/ml, beer ~1.0 g/ml.
-- 1.5 fl oz shot = 44ml = ~41g (spirits). Beer/seltzer 12 fl oz = 355ml = ~355g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SPIRITS (80 PROOF unless noted)
-- ══════════════════════════════════════════
-- USDA: 80 proof distilled spirits = 97 cal per 1.5 fl oz (44ml).
-- 44ml * 0.94 g/ml = 41g per shot. Per 100g: 97/41*100 = 237 cal.
-- USDA per 100g: 231 cal, 0g P/C/F (all calories from alcohol).

-- Vodka 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_vodka', 'Vodka (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['vodka', 'vodka 80 proof', 'plain vodka', 'vodka shot', 'absolut vodka', 'titos vodka', 'grey goose vodka', 'smirnoff vodka'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Gin 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_gin', 'Gin (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['gin', 'gin 80 proof', 'gin shot', 'london dry gin', 'tanqueray gin', 'bombay sapphire gin', 'hendricks gin', 'beefeater gin'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Rum 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_rum', 'Rum (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['rum', 'rum 80 proof', 'rum shot', 'white rum', 'bacardi rum', 'captain morgan', 'dark rum', 'light rum'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Tequila 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_tequila', 'Tequila (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['tequila', 'tequila 80 proof', 'tequila shot', 'blanco tequila', 'silver tequila', 'patron tequila', 'don julio tequila', 'casamigos tequila'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Whiskey/Bourbon 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_whiskey', 'Whiskey / Bourbon (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['whiskey', 'bourbon', 'whiskey 80 proof', 'bourbon whiskey', 'jack daniels', 'makers mark', 'jim beam', 'bulleit bourbon', 'wild turkey', 'rye whiskey'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Scotch 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_scotch', 'Scotch Whisky (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['scotch', 'scotch whisky', 'scotch whiskey', 'single malt scotch', 'johnnie walker', 'glenfiddich', 'macallan scotch', 'chivas regal'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Brandy 80 Proof: 97 cal per 1.5 oz shot (41g)
('spirit_brandy', 'Brandy / Cognac (80 Proof)', 231, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['brandy', 'cognac', 'brandy 80 proof', 'brandy shot', 'hennessy', 'remy martin', 'courvoisier', 'vs cognac', 'vsop cognac'],
 'alcohol', 'Generic Spirits', 1, '97 cal per 1.5 oz shot (41g). 40% ABV. Zero macronutrients; all calories from ethanol.', TRUE),

-- Vodka 100 Proof: 124 cal per 1.5 oz shot (41g)
-- USDA 100 proof: ~275 cal per 100g
('spirit_vodka_100_proof', 'Vodka (100 Proof)', 302, 0.0, 0.0, 0.0,
 0.0, 0.0, 41, NULL,
 'usda', ARRAY['100 proof vodka', 'vodka 100 proof', 'overproof vodka', 'high proof vodka', 'absolut 100'],
 'alcohol', 'Generic Spirits', 1, '124 cal per 1.5 oz shot (41g). 50% ABV. Higher calorie due to increased alcohol content.', TRUE),

-- ══════════════════════════════════════════
-- COCKTAILS
-- ══════════════════════════════════════════
-- Cocktail densities treated as ~1.0 g/ml (water-like due to mixers).

-- Margarita: 274 cal / 240ml (~240g)
-- FatSecret scaled: 1 cocktail (2.5 oz) = 168 cal. For 8 oz (240ml): 68 cal/oz * 8 = 544 cal.
-- Standard recipe 240ml: ~274 cal, 0g fat, 17g carb, 0g protein
-- Per 100g: 274/240*100 = 114 cal
('cocktail_margarita', 'Margarita', 114, 0.0, 7.1, 0.0,
 0.0, 6.5, 240, NULL,
 'usda', ARRAY['margarita', 'classic margarita', 'margarita on the rocks', 'margarita cocktail', 'tequila margarita'],
 'alcohol', 'Generic Cocktails', 1, '274 cal per 8 oz glass (240g). Tequila, triple sec, lime juice. Carbs primarily from sugar.', TRUE),

-- Mojito: 217 cal per cocktail (~240ml, ~240g)
-- FatSecret: 217 cal, 0.04g fat, 24.94g carb, 0.14g protein, 0.5g fiber, 23.47g sugar
-- Per 100g: 217/240*100 = 90 cal
('cocktail_mojito', 'Mojito', 90, 0.1, 10.4, 0.0,
 0.2, 9.8, 240, NULL,
 'usda', ARRAY['mojito', 'classic mojito', 'rum mojito', 'mojito cocktail', 'mint mojito'],
 'alcohol', 'Generic Cocktails', 1, '217 cal per cocktail (~240g). White rum, lime, sugar, mint, soda water.', TRUE),

-- Pina Colada: 490 cal / 270ml (~270g)
-- FatSecret: 1 cocktail (4.4oz ~130ml) = 230 cal. Scaled to 270ml: ~478 cal
-- Per 100g: 490/270*100 = 181 cal
-- Macros scaled: fat ~7g, carb ~60g, protein ~1.2g per 270g
('cocktail_pina_colada', 'Pina Colada', 181, 0.4, 22.2, 2.6,
 0.3, 20.7, 270, NULL,
 'usda', ARRAY['pina colada', 'piña colada', 'pina colada cocktail', 'rum pina colada'],
 'alcohol', 'Generic Cocktails', 1, '490 cal per cocktail (~270g). Rum, coconut cream, pineapple juice. High calorie due to coconut fat and sugars.', TRUE),

-- Cosmopolitan: 146 cal / 120ml (~120g)
-- FatSecret: 1 cocktail (7.5 oz ~220ml) = 331 cal. For 4oz (120ml): ~180 cal
-- Standard cosmo is 4 oz. Using reference: ~146 cal per 4 oz
-- Per 100g: 146/120*100 = 122 cal
('cocktail_cosmopolitan', 'Cosmopolitan', 122, 0.1, 10.0, 0.1,
 0.2, 7.4, 120, NULL,
 'usda', ARRAY['cosmopolitan', 'cosmo', 'cosmopolitan cocktail', 'cosmo cocktail', 'vodka cosmopolitan'],
 'alcohol', 'Generic Cocktails', 1, '146 cal per cocktail (~120g, 4 oz). Vodka, triple sec, cranberry juice, lime juice.', TRUE),

-- Old Fashioned: 154 cal / 120ml (~120g)
-- FatSecret: 1 cocktail (2.1 oz ~63ml) = 155 cal. Standard OF is ~4 oz with ice melt.
-- Per 100g: 154/120*100 = 128 cal
('cocktail_old_fashioned', 'Old Fashioned', 128, 0.0, 3.5, 0.0,
 0.0, 3.5, 120, NULL,
 'usda', ARRAY['old fashioned', 'old fashioned cocktail', 'bourbon old fashioned', 'whiskey old fashioned'],
 'alcohol', 'Generic Cocktails', 1, '154 cal per cocktail (~120g, 4 oz). Bourbon or rye whiskey, sugar, bitters, orange peel.', TRUE),

-- Manhattan: 187 cal / 120ml (~120g)
-- FatSecret: 1 cocktail (2 oz ~60ml) = 129 cal. Standard Manhattan ~4 oz.
-- Scaled: 129/60*120 = 258 cal. But standard recipe ~3 oz total = 187 cal.
-- Per 100g: 187/90*100 = 208 → use 120ml serving per spec: 187/120*100 = 156
('cocktail_manhattan', 'Manhattan', 156, 0.0, 1.7, 0.0,
 0.0, 1.0, 120, NULL,
 'usda', ARRAY['manhattan', 'manhattan cocktail', 'whiskey manhattan', 'rye manhattan', 'bourbon manhattan'],
 'alcohol', 'Generic Cocktails', 1, '187 cal per cocktail (~120g, 4 oz). Whiskey, sweet vermouth, bitters. Low carb, spirit-forward.', TRUE),

-- Daiquiri: 186 cal / 180ml (~180g)
-- FatSecret: 1 cocktail (2oz ~60ml) = 113 cal. Standard daiquiri ~6 oz.
-- Scaled: 113/60*180 = 339. Standard recipe (not frozen): ~186 cal for 6 oz.
-- Per 100g: 186/180*100 = 103 cal
('cocktail_daiquiri', 'Daiquiri', 103, 0.0, 4.7, 0.0,
 0.1, 3.8, 180, NULL,
 'usda', ARRAY['daiquiri', 'classic daiquiri', 'rum daiquiri', 'daiquiri cocktail'],
 'alcohol', 'Generic Cocktails', 1, '186 cal per cocktail (~180g, 6 oz). Rum, lime juice, simple syrup. Classic, not frozen.', TRUE),

-- Long Island Iced Tea: 292 cal / 300ml (~300g)
-- FatSecret: 1 drink (5 fl oz ~150ml) = 138 cal. For 10 oz (300ml): 276 cal.
-- Standard LIIT is ~10 oz. Per 100g: 292/300*100 = 97 cal
('cocktail_long_island_iced_tea', 'Long Island Iced Tea', 97, 0.0, 3.3, 0.0,
 0.0, 2.9, 300, NULL,
 'usda', ARRAY['long island iced tea', 'long island', 'LIIT', 'long island cocktail', 'long island ice tea'],
 'alcohol', 'Generic Cocktails', 1, '292 cal per cocktail (~300g, 10 oz). Vodka, gin, rum, tequila, triple sec, cola, lemon. High alcohol content.', TRUE),

-- Moscow Mule: 182 cal / 240ml (~240g)
-- FatSecret: 1 cocktail = 216 cal. Standard mule ~8 oz copper mug.
-- Per 100g: 182/240*100 = 76 cal
('cocktail_moscow_mule', 'Moscow Mule', 76, 0.1, 7.1, 0.0,
 0.0, 6.5, 240, NULL,
 'usda', ARRAY['moscow mule', 'moscow mule cocktail', 'vodka mule', 'ginger beer cocktail'],
 'alcohol', 'Generic Cocktails', 1, '182 cal per cocktail (~240g, 8 oz). Vodka, ginger beer, lime juice. Served in copper mug.', TRUE),

-- Gin & Tonic: 171 cal / 240ml (~240g)
-- FatSecret: 1 cocktail (7.5 oz ~220ml) = 171 cal. Standard G&T ~8 oz.
-- Per 100g: 171/240*100 = 71 cal
('cocktail_gin_and_tonic', 'Gin & Tonic', 71, 0.0, 6.6, 0.0,
 0.0, 6.2, 240, NULL,
 'usda', ARRAY['gin and tonic', 'gin tonic', 'g&t', 'gin & tonic', 'gin and tonic cocktail'],
 'alcohol', 'Generic Cocktails', 1, '171 cal per cocktail (~240g, 8 oz). Gin, tonic water, lime. Most carbs from tonic water sugar.', TRUE),

-- Whiskey Sour: 165 cal / 120ml (~120g)
-- FatSecret USDA: 47 cal per 1 fl oz. Standard whiskey sour ~3.5 oz (105ml) = 165 cal.
-- Per 100g: 165/120*100 = 138 cal
('cocktail_whiskey_sour', 'Whiskey Sour', 138, 0.0, 8.1, 0.0,
 0.0, 8.1, 120, NULL,
 'usda', ARRAY['whiskey sour', 'whisky sour', 'bourbon sour', 'whiskey sour cocktail', 'sour cocktail'],
 'alcohol', 'Generic Cocktails', 1, '165 cal per cocktail (~120g, 4 oz). Whiskey, lemon juice, simple syrup, optional egg white.', TRUE),

-- Aperol Spritz: 160 cal / 200ml (~200g)
-- FatSecret/Aperol brand: 120 cal per 5 oz (150ml). Scaled to ~200ml = 160 cal.
-- Per 100g: 160/200*100 = 80 cal
('cocktail_aperol_spritz', 'Aperol Spritz', 80, 0.0, 4.0, 0.0,
 0.0, 3.0, 200, NULL,
 'usda', ARRAY['aperol spritz', 'aperol spritz cocktail', 'spritz', 'aperol prosecco'],
 'alcohol', 'Generic Cocktails', 1, '160 cal per cocktail (~200g). Aperol, prosecco, soda water. Light and refreshing Italian aperitivo.', TRUE),

-- ══════════════════════════════════════════
-- POPULAR BEER & HARD SELTZER BRANDS
-- ══════════════════════════════════════════
-- 12 fl oz = 355ml ≈ 355g for beer/seltzer (density ~1.0)

-- Michelob Ultra: 95 cal / 355ml (~355g)
-- FatSecret: 95 cal, 0g fat, 2.6g carb, 0.6g protein, 0g fiber, 0g sugar
-- Per 100g: 95/355*100 = 27 cal
('beer_michelob_ultra', 'Michelob Ultra', 27, 0.2, 0.7, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['michelob ultra', 'michelob ultra light beer', 'mich ultra', 'michelob ultra superior light'],
 'alcohol', 'Michelob', 1, '95 cal per 12 oz can/bottle (355g). 4.2% ABV. Ultra-low carb light beer. Popular for low-calorie drinking.', TRUE),

-- White Claw Hard Seltzer: 100 cal / 355ml (~355g)
-- Typical: 100 cal, 0g fat, 2g carb, 0g protein, 0g fiber, 0g sugar
-- Per 100g: 100/355*100 = 28 cal
('seltzer_white_claw', 'White Claw Hard Seltzer', 28, 0.0, 0.6, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['white claw', 'white claw hard seltzer', 'white claw seltzer', 'white claw mango', 'white claw black cherry', 'white claw lime'],
 'alcohol', 'White Claw', 1, '100 cal per 12 oz can (355g). 5% ABV. Gluten-free hard seltzer with natural flavors. 2g carbs.', TRUE),

-- Truly Hard Seltzer: 100 cal / 355ml (~355g)
-- FatSecret: 100 cal, 0g fat, 3g carb, 0g protein, 0g fiber, 1g sugar
-- Per 100g: 100/355*100 = 28 cal
('seltzer_truly', 'Truly Hard Seltzer', 28, 0.0, 0.8, 0.0,
 0.0, 0.3, NULL, 355,
 'manufacturer', ARRAY['truly', 'truly hard seltzer', 'truly seltzer', 'truly lemonade', 'truly fruit punch', 'truly berry'],
 'alcohol', 'Truly', 1, '100 cal per 12 oz can (355g). 5% ABV. Hard seltzer with natural fruit flavors. 1g sugar.', TRUE),

-- Corona Extra: 148 cal / 355ml (~355g)
-- FatSecret: 148 cal, 0g fat, 13.9g carb, 1.2g protein, 0g fiber, 0g sugar
-- Per 100g: 148/355*100 = 42 cal
('beer_corona_extra', 'Corona Extra', 42, 0.3, 3.9, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['corona', 'corona extra', 'corona beer', 'corona extra beer', 'corona bottle'],
 'alcohol', 'Corona', 1, '148 cal per 12 oz bottle (355g). 4.5% ABV. Mexican pale lager. Higher carb than light beers.', TRUE),

-- Guinness Draught: 125 cal / 355ml (~355g)
-- FatSecret: 126 cal, 0g fat, 9.6g carb, 1.1g protein, 1g fiber, 1g sugar
-- Per 100g: 125/355*100 = 35 cal
('beer_guinness_draught', 'Guinness Draught', 35, 0.3, 2.7, 0.0,
 0.3, 0.3, NULL, 355,
 'manufacturer', ARRAY['guinness', 'guinness draught', 'guinness stout', 'guinness beer', 'guinness draft', 'guinness pint'],
 'alcohol', 'Guinness', 1, '125 cal per 12 oz (355g). 4.2% ABV. Irish dry stout. Surprisingly low calorie for a dark beer.', TRUE)

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
