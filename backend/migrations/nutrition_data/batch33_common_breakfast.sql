-- ============================================================================
-- Batch 33: Common Breakfast Foods
-- Categories: Eggs, Pancakes/Waffles, Breakfast Meats, Breakfast Carbs,
--             Breakfast Combos, Cereal/Hot, Sides, Spreads, Smoothies/Drinks
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central, nutritionvalue.org, fatsecret.com,
--          calorieking.com, nutritionix.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- EGGS PREPARED
-- ============================================================================

-- Scrambled Eggs (with butter, 2 large eggs): ~149 cal/100g, ~203 cal per serving (~136g)
('scrambled_eggs', 'Scrambled Eggs (with Butter)', 149.0, 10.0, 1.6, 11.2, 0.0, 1.4, NULL, 136, 'usda', ARRAY['scrambled eggs', 'scrambled egg', 'eggs scrambled'], '203 cal per serving of 2 eggs (136g). Two large eggs scrambled with butter and milk.', NULL, 'breakfast', 1),

-- Fried Egg (in oil, 1 large): ~196 cal/100g, ~90 cal per egg (~46g)
('fried_egg', 'Fried Egg (in Oil)', 196.0, 13.6, 0.8, 15.3, 0.0, 0.4, 46, 92, 'usda', ARRAY['fried egg', 'eggs fried', 'sunny side up egg', 'over easy egg'], '180 cal per 2 eggs (92g). Large eggs fried in vegetable oil.', NULL, 'breakfast', 2),

-- Poached Egg (1 large): ~143 cal/100g, ~72 cal per egg (~50g)
('poached_egg', 'Poached Egg', 143.0, 12.5, 0.7, 9.9, 0.0, 0.4, 50, 100, 'usda', ARRAY['poached egg', 'eggs poached', 'poached eggs'], '143 cal per 2 eggs (100g). Eggs cooked in simmering water without shell.', NULL, 'breakfast', 2),

-- Cheese Omelette (2 eggs): ~175 cal/100g, ~263 cal per omelette (~150g)
('cheese_omelette', 'Omelette (Cheese)', 175.0, 12.7, 1.3, 13.3, 0.0, 0.7, 150, 150, 'usda', ARRAY['cheese omelette', 'cheese omelet', 'omelette', 'omelet'], '263 cal per omelette (150g). Two-egg omelette with cheddar cheese.', NULL, 'breakfast', 1),

-- Egg White Omelette: ~70 cal/100g, ~91 cal per omelette (~130g)
('egg_white_omelette', 'Egg White Omelette', 70.0, 11.5, 1.5, 2.3, 0.2, 0.5, 130, 130, 'usda', ARRAY['egg white omelette', 'egg white omelet', 'egg whites omelette'], '91 cal per omelette (130g). Three egg whites with spinach and mushrooms.', NULL, 'breakfast', 1),

-- Deviled Eggs: ~195 cal/100g, ~63 cal per half (~32g)
('deviled_eggs', 'Deviled Eggs', 195.0, 10.0, 1.6, 16.6, 0.0, 1.3, 32, 128, 'usda', ARRAY['deviled eggs', 'devilled eggs', 'stuffed eggs'], '250 cal per 4 halves (128g). Hard-boiled egg halves filled with yolk, mayo, mustard.', NULL, 'breakfast', 4),

-- ============================================================================
-- PANCAKES / WAFFLES
-- ============================================================================

-- Pancakes (homemade, 1 pancake ~38g): ~227 cal/100g, ~86 cal per pancake
('pancake_homemade', 'Pancakes (Homemade)', 227.0, 6.3, 28.4, 9.5, 0.8, 6.8, 38, 114, 'usda', ARRAY['pancake', 'pancakes', 'homemade pancakes', 'flapjacks', 'hotcakes'], '258 cal per 3 pancakes (114g). Buttermilk pancakes, no syrup or butter.', NULL, 'breakfast', 3),

-- Waffles (homemade, 1 waffle ~75g): ~291 cal/100g, ~218 cal per waffle
('waffle_homemade', 'Waffles (Homemade)', 291.0, 7.9, 32.9, 14.1, 0.8, 5.0, 75, 75, 'usda', ARRAY['waffle', 'waffles', 'homemade waffle', 'belgian waffle'], '218 cal per waffle (75g). Homemade waffle, no syrup or butter.', NULL, 'breakfast', 1),

-- French Toast: ~229 cal/100g, ~160 cal per slice (~70g)
('french_toast', 'French Toast', 229.0, 7.1, 24.3, 11.4, 0.6, 6.4, 70, 140, 'usda', ARRAY['french toast', 'pain perdu', 'eggy bread'], '321 cal per 2 slices (140g). Bread dipped in egg mixture, pan-fried in butter. No syrup.', NULL, 'breakfast', 2),

-- Crepes (plain): ~185 cal/100g, ~111 cal per crepe (~60g)
('crepes_plain', 'Crepes (Plain)', 185.0, 6.7, 22.5, 7.5, 0.3, 3.3, 60, 120, 'usda', ARRAY['crepe', 'crepes', 'plain crepe', 'french crepe'], '222 cal per 2 crepes (120g). Thin French pancakes, unfilled.', NULL, 'breakfast', 2),

-- Crepes (Nutella & banana): ~255 cal/100g, ~204 cal per crepe (~80g)
('crepes_nutella_banana', 'Crepes (Nutella & Banana)', 255.0, 5.0, 33.8, 11.3, 1.3, 21.3, 80, 160, 'usda', ARRAY['nutella crepe', 'nutella banana crepe', 'chocolate banana crepe'], '408 cal per 2 crepes (160g). French crepe filled with Nutella and sliced banana.', NULL, 'breakfast', 2),

-- Silver Dollar Pancakes: ~227 cal/100g, ~34 cal per mini pancake (~15g)
('silver_dollar_pancakes', 'Silver Dollar Pancakes', 227.0, 6.3, 28.4, 9.5, 0.8, 6.8, 15, 90, 'usda', ARRAY['silver dollar pancakes', 'mini pancakes', 'dollar pancakes'], '204 cal per 6 mini pancakes (90g). Small buttermilk pancakes.', NULL, 'breakfast', 6),

-- ============================================================================
-- BREAKFAST MEATS
-- ============================================================================

-- Breakfast Sausage Links (2 links): ~339 cal/100g, ~170 cal per 2 links (~50g)
('breakfast_sausage_links', 'Breakfast Sausage Links', 339.0, 14.0, 1.0, 31.0, 0.0, 0.5, 25, 50, 'usda', ARRAY['breakfast sausage links', 'pork sausage links', 'sausage links', 'breakfast links'], '170 cal per 2 links (50g). Pork breakfast sausage links.', NULL, 'breakfast', 2),

-- Breakfast Sausage Patty: ~325 cal/100g, ~163 cal per patty (~50g)
('breakfast_sausage_patty', 'Breakfast Sausage Patty', 325.0, 14.0, 1.0, 29.0, 0.0, 0.5, 50, 50, 'usda', ARRAY['sausage patty', 'breakfast patty', 'pork sausage patty'], '163 cal per patty (50g). Pork breakfast sausage patty.', NULL, 'breakfast', 1),

-- Canadian Bacon: ~131 cal/100g, ~43 cal per slice (~33g)
('canadian_bacon', 'Canadian Bacon', 131.0, 18.0, 1.5, 5.5, 0.0, 0.5, 33, 66, 'usda', ARRAY['canadian bacon', 'back bacon', 'peameal bacon'], '86 cal per 2 slices (66g). Lean back bacon slices.', NULL, 'breakfast', 2),

-- Turkey Sausage: ~170 cal/100g, ~85 cal per 2 links (~50g)
('turkey_sausage', 'Turkey Sausage', 170.0, 16.0, 2.0, 10.0, 0.0, 0.5, 25, 50, 'usda', ARRAY['turkey sausage', 'turkey breakfast sausage', 'turkey sausage links'], '85 cal per 2 links (50g). Lean turkey breakfast sausage.', NULL, 'breakfast', 2),

-- Chicken Sausage Link: ~140 cal/100g, ~98 cal per link (~70g)
('chicken_sausage_link', 'Chicken Sausage Link', 140.0, 17.1, 2.9, 6.4, 0.0, 1.4, 70, 70, 'usda', ARRAY['chicken sausage', 'chicken breakfast sausage', 'chicken apple sausage'], '98 cal per link (70g). Fully cooked chicken sausage link.', NULL, 'breakfast', 1),

-- Scrapple: ~213 cal/100g, ~128 cal per slice (~60g)
('scrapple', 'Scrapple', 213.0, 8.3, 13.3, 13.3, 0.5, 0.5, 60, 120, 'usda', ARRAY['scrapple', 'fried scrapple', 'pork scrapple'], '256 cal per 2 slices (120g). Pan-fried pork scrapple (cornmeal and pork offal loaf).', NULL, 'breakfast', 2),

-- ============================================================================
-- BREAKFAST CARBS
-- ============================================================================

-- Toast (white with butter): ~313 cal/100g, ~128 cal per slice (~41g)
('toast_white_butter', 'Toast (White with Butter)', 313.0, 7.3, 39.0, 14.6, 1.5, 3.7, 41, 41, 'usda', ARRAY['toast with butter', 'white toast', 'buttered toast', 'toast'], '128 cal per slice (41g). White bread toasted with 1 pat butter.', NULL, 'breakfast', 1),

-- Toast (whole wheat with butter): ~295 cal/100g, ~121 cal per slice (~41g)
('toast_wheat_butter', 'Toast (Whole Wheat with Butter)', 295.0, 8.5, 34.1, 13.4, 3.7, 3.2, 41, 41, 'usda', ARRAY['wheat toast', 'whole wheat toast', 'whole wheat toast with butter'], '121 cal per slice (41g). Whole wheat bread toasted with 1 pat butter.', NULL, 'breakfast', 1),

-- Bagel with Cream Cheese: ~280 cal/100g, ~370 cal per bagel (~132g)
('bagel_cream_cheese', 'Bagel with Cream Cheese', 280.0, 8.3, 36.4, 11.4, 1.1, 4.5, 132, 132, 'usda', ARRAY['bagel with cream cheese', 'bagel and cream cheese', 'bagel cream cheese', 'plain bagel with cc'], '370 cal per bagel (132g). Plain bagel (105g) with 2 tbsp cream cheese (28g).', NULL, 'breakfast', 1),

-- English Muffin with Butter: ~260 cal/100g, ~166 cal per muffin (~64g)
('english_muffin_butter', 'English Muffin with Butter', 260.0, 7.8, 35.9, 9.4, 1.6, 3.1, 64, 64, 'usda', ARRAY['english muffin', 'english muffin with butter', 'toasted english muffin'], '166 cal per muffin (64g). Toasted English muffin with 1 pat butter.', NULL, 'breakfast', 1),

-- Buttermilk Biscuit: ~327 cal/100g, ~196 cal per biscuit (~60g)
('buttermilk_biscuit', 'Biscuit (Buttermilk)', 327.0, 6.3, 39.7, 15.5, 1.0, 3.2, 60, 60, 'usda', ARRAY['biscuit', 'buttermilk biscuit', 'breakfast biscuit', 'southern biscuit'], '196 cal per biscuit (60g). Fluffy buttermilk biscuit.', NULL, 'breakfast', 1),

-- Hash Browns: ~265 cal/100g, ~212 cal per serving (~80g)
('hash_browns', 'Hash Browns', 265.0, 3.0, 28.8, 15.5, 2.5, 0.3, NULL, 80, 'usda', ARRAY['hash browns', 'hashbrowns', 'hash brown patty', 'hashed browns'], '212 cal per serving (80g). Shredded potatoes, pan-fried until crispy.', NULL, 'breakfast', 1),

-- Home Fries: ~150 cal/100g, ~225 cal per serving (~150g)
('home_fries', 'Home Fries', 150.0, 2.7, 18.7, 7.3, 1.7, 1.0, NULL, 150, 'usda', ARRAY['home fries', 'home fried potatoes', 'breakfast potatoes', 'diced potatoes'], '225 cal per serving (150g). Diced potatoes sauteed with onions and peppers.', NULL, 'breakfast', 1),

-- Avocado Toast: ~195 cal/100g, ~234 cal per slice (~120g)
('avocado_toast', 'Avocado Toast', 195.0, 5.0, 17.5, 11.7, 4.2, 1.3, 120, 120, 'usda', ARRAY['avocado toast', 'avo toast', 'smashed avocado toast'], '234 cal per slice (120g). Whole wheat toast with mashed avocado, salt, lemon.', NULL, 'breakfast', 1),

-- ============================================================================
-- BREAKFAST COMBOS
-- ============================================================================

-- Breakfast Burrito (egg, cheese, sausage): ~195 cal/100g, ~488 cal per burrito (~250g)
('breakfast_burrito', 'Breakfast Burrito (Egg, Cheese, Sausage)', 195.0, 10.0, 16.0, 10.0, 0.8, 1.2, 250, 250, 'usda', ARRAY['breakfast burrito', 'egg burrito', 'breakfast wrap'], '488 cal per burrito (250g). Flour tortilla with scrambled eggs, sausage, cheese, salsa.', NULL, 'breakfast', 1),

-- Breakfast Sandwich (egg, cheese, English muffin): ~230 cal/100g, ~300 cal per sandwich (~130g)
('breakfast_sandwich', 'Breakfast Sandwich (Egg, Cheese, English Muffin)', 230.0, 13.1, 20.8, 10.8, 0.8, 2.3, 130, 130, 'usda', ARRAY['breakfast sandwich', 'egg sandwich', 'egg cheese muffin', 'egg mcmuffin style'], '300 cal per sandwich (130g). Fried egg and American cheese on toasted English muffin.', NULL, 'breakfast', 1),

-- Eggs Benedict: ~195 cal/100g, ~468 cal per serving (~240g)
('eggs_benedict', 'Eggs Benedict', 195.0, 9.6, 11.7, 12.5, 0.4, 1.3, NULL, 240, 'usda', ARRAY['eggs benedict', 'eggs benny', 'benedict'], '468 cal per serving (240g). Two poached eggs, Canadian bacon on English muffin with hollandaise.', NULL, 'breakfast', 1),

-- Huevos Rancheros: ~130 cal/100g, ~390 cal per serving (~300g)
('huevos_rancheros', 'Huevos Rancheros', 130.0, 7.3, 12.7, 5.7, 2.3, 2.0, NULL, 300, 'usda', ARRAY['huevos rancheros', 'mexican eggs', 'ranch eggs'], '390 cal per serving (300g). Fried eggs on corn tortillas with ranchero sauce, beans.', NULL, 'breakfast', 1),

-- Shakshuka: ~90 cal/100g, ~270 cal per serving (~300g)
('shakshuka', 'Shakshuka', 90.0, 5.7, 6.3, 5.0, 1.3, 3.3, NULL, 300, 'usda', ARRAY['shakshuka', 'shakshouka', 'eggs in tomato sauce', 'middle eastern eggs'], '270 cal per serving (300g). Eggs poached in spiced tomato-pepper sauce.', NULL, 'breakfast', 1),

-- Breakfast Bowl (egg, rice, veggies): ~125 cal/100g, ~375 cal per bowl (~300g)
('breakfast_bowl', 'Breakfast Bowl (Egg, Rice, Veggies)', 125.0, 5.7, 15.0, 4.7, 1.3, 0.7, NULL, 300, 'usda', ARRAY['breakfast bowl', 'egg rice bowl', 'morning bowl'], '375 cal per bowl (300g). Fried egg over rice with sauteed vegetables and avocado.', NULL, 'breakfast', 1),

-- Yogurt Parfait (yogurt, granola, berries): ~120 cal/100g, ~300 cal per parfait (~250g)
('yogurt_parfait', 'Yogurt Parfait', 120.0, 4.8, 18.0, 3.2, 1.2, 12.8, NULL, 250, 'usda', ARRAY['yogurt parfait', 'yogurt granola', 'parfait', 'fruit yogurt parfait'], '300 cal per parfait (250g). Greek yogurt layered with granola and mixed berries.', NULL, 'breakfast', 1),

-- Overnight Oats: ~130 cal/100g, ~325 cal per serving (~250g)
('overnight_oats', 'Overnight Oats', 130.0, 4.8, 19.2, 3.6, 2.4, 7.2, NULL, 250, 'usda', ARRAY['overnight oats', 'cold oats', 'overnight oatmeal'], '325 cal per serving (250g). Rolled oats soaked in milk with chia seeds, banana, honey.', NULL, 'breakfast', 1),

-- ============================================================================
-- CEREAL & HOT BREAKFAST
-- ============================================================================

-- Cereal with Milk (generic): ~135 cal/100g, ~270 cal per bowl (~200g)
('cereal_with_milk', 'Cereal with Milk', 135.0, 3.5, 22.0, 3.5, 0.5, 10.5, NULL, 200, 'usda', ARRAY['cereal', 'cereal with milk', 'breakfast cereal', 'bowl of cereal'], '270 cal per bowl (200g). Generic cereal (40g) with 1 cup whole milk (160g).', NULL, 'breakfast', 1),

-- Oatmeal (cooked with water): ~68 cal/100g, ~163 cal per bowl (~240g)
('oatmeal_water', 'Oatmeal (Cooked with Water)', 68.0, 2.5, 12.0, 1.0, 1.7, 0.3, NULL, 240, 'usda', ARRAY['oatmeal', 'oatmeal with water', 'plain oatmeal', 'porridge'], '163 cal per bowl (240g). Rolled oats cooked in water, unsweetened.', NULL, 'breakfast', 1),

-- Oatmeal (cooked with milk): ~95 cal/100g, ~228 cal per bowl (~240g)
('oatmeal_milk', 'Oatmeal (Cooked with Milk)', 95.0, 3.8, 14.2, 2.5, 1.3, 3.3, NULL, 240, 'usda', ARRAY['oatmeal with milk', 'creamy oatmeal', 'milk oatmeal'], '228 cal per bowl (240g). Rolled oats cooked in whole milk, unsweetened.', NULL, 'breakfast', 1),

-- Cream of Wheat: ~65 cal/100g, ~156 cal per bowl (~240g)
('cream_of_wheat', 'Cream of Wheat', 65.0, 2.1, 13.3, 0.4, 0.4, 0.1, NULL, 240, 'usda', ARRAY['cream of wheat', 'farina', 'hot cereal', 'semolina porridge'], '156 cal per bowl (240g). Semolina hot cereal cooked with water.', NULL, 'breakfast', 1),

-- Grits (cooked with butter): ~90 cal/100g, ~216 cal per bowl (~240g)
('grits_butter', 'Grits (Cooked with Butter)', 90.0, 2.1, 13.3, 3.3, 0.4, 0.1, NULL, 240, 'usda', ARRAY['grits', 'grits with butter', 'southern grits', 'cheese grits'], '216 cal per bowl (240g). Corn grits with a pat of butter.', NULL, 'breakfast', 1),

-- Congee / Rice Porridge: ~46 cal/100g, ~138 cal per bowl (~300g)
('congee', 'Congee / Rice Porridge', 46.0, 1.0, 9.7, 0.2, 0.1, 0.0, NULL, 300, 'usda', ARRAY['congee', 'rice porridge', 'jook', 'rice congee', 'kanji'], '138 cal per bowl (300g). Plain rice porridge. Calories vary with toppings.', NULL, 'breakfast', 1),

-- ============================================================================
-- BREAKFAST SIDES
-- ============================================================================

-- Fruit Cup / Fruit Salad: ~50 cal/100g, ~100 cal per serving (~200g)
('fruit_cup', 'Fruit Cup / Fruit Salad', 50.0, 0.5, 12.5, 0.2, 1.3, 9.5, NULL, 200, 'usda', ARRAY['fruit cup', 'fruit salad', 'mixed fruit', 'fresh fruit cup'], '100 cal per serving (200g). Mixed fresh fruits (melon, berries, grapes, pineapple).', NULL, 'breakfast', 1),

-- Cottage Cheese: ~98 cal/100g, ~110 cal per serving (~113g)
('cottage_cheese', 'Cottage Cheese', 98.0, 11.1, 3.4, 4.3, 0.0, 2.7, NULL, 113, 'usda', ARRAY['cottage cheese', 'cottage cheese cup', 'low fat cottage cheese'], '110 cal per serving (113g). 4% milkfat cottage cheese.', NULL, 'breakfast', 1),

-- Smoked Salmon / Lox: ~117 cal/100g, ~66 cal per serving (~56g)
('smoked_salmon_lox', 'Smoked Salmon / Lox', 117.0, 18.3, 0.0, 4.3, 0.0, 0.0, NULL, 56, 'usda', ARRAY['smoked salmon', 'lox', 'nova lox', 'salmon lox', 'cold smoked salmon'], '66 cal per serving (56g, ~2 oz). Cold-smoked salmon slices.', NULL, 'breakfast', 1),

-- Granola: ~471 cal/100g, ~236 cal per serving (~50g)
('granola', 'Granola', 471.0, 10.0, 56.0, 23.0, 5.0, 20.0, NULL, 50, 'usda', ARRAY['granola', 'granola cereal', 'homemade granola', 'crunchy granola'], '236 cal per serving (50g, ~1/2 cup). Oat-based granola with nuts and dried fruit.', NULL, 'breakfast', 1),

-- Bacon (2 strips, pan-fried): ~541 cal/100g, ~87 cal per 2 strips (~16g)
('bacon_strips', 'Bacon (2 Strips)', 541.0, 37.0, 1.4, 42.0, 0.0, 0.0, 8, 16, 'usda', ARRAY['bacon', 'bacon strips', 'crispy bacon', 'pan fried bacon'], '87 cal per 2 strips (16g cooked). Pork bacon, pan-fried crispy.', NULL, 'breakfast', 2),

-- Sausage Link (1 link): ~339 cal/100g, ~85 cal per link (~25g)
('sausage_link_single', 'Sausage Link (1)', 339.0, 14.0, 1.0, 31.0, 0.0, 0.5, 25, 25, 'usda', ARRAY['sausage link', 'single sausage', 'pork sausage link'], '85 cal per link (25g). One pork breakfast sausage link.', NULL, 'breakfast', 1),

-- ============================================================================
-- SPREADS & TOPPINGS
-- ============================================================================

-- Butter on Toast (1 tbsp / 14g butter): ~717 cal/100g butter, ~100 cal per tbsp
('butter_spread', 'Butter (1 Tbsp)', 717.0, 0.9, 0.1, 81.1, 0.0, 0.1, NULL, 14, 'usda', ARRAY['butter', 'pat of butter', 'butter spread', 'tablespoon butter'], '100 cal per tbsp (14g). Salted butter, 1 tablespoon.', NULL, 'breakfast', 1),

-- Cream Cheese (2 tbsp / 28g): ~342 cal/100g, ~96 cal per 2 tbsp
('cream_cheese_spread', 'Cream Cheese (2 Tbsp)', 342.0, 5.9, 4.1, 33.6, 0.0, 3.2, NULL, 28, 'usda', ARRAY['cream cheese', 'cream cheese spread', 'philadelphia cream cheese'], '96 cal per 2 tbsp (28g). Regular cream cheese.', NULL, 'breakfast', 1),

-- Peanut Butter on Toast (2 tbsp / 32g PB): ~588 cal/100g PB, ~188 cal per 2 tbsp
('peanut_butter_spread', 'Peanut Butter (2 Tbsp)', 588.0, 25.0, 20.0, 50.0, 6.3, 9.4, NULL, 32, 'usda', ARRAY['peanut butter', 'pb on toast', 'peanut butter spread'], '188 cal per 2 tbsp (32g). Smooth peanut butter.', NULL, 'breakfast', 1),

-- Jam / Jelly (1 tbsp / 20g): ~250 cal/100g, ~50 cal per tbsp
('jam_jelly', 'Jam / Jelly (1 Tbsp)', 250.0, 0.2, 62.5, 0.1, 0.3, 48.5, NULL, 20, 'usda', ARRAY['jam', 'jelly', 'preserves', 'grape jelly', 'strawberry jam'], '50 cal per tbsp (20g). Fruit jam or jelly, any flavor.', NULL, 'breakfast', 1),

-- ============================================================================
-- SMOOTHIES & BREAKFAST DRINKS
-- ============================================================================

-- Green Smoothie: ~55 cal/100g, ~220 cal per smoothie (~400g)
('green_smoothie', 'Green Smoothie', 55.0, 1.8, 10.0, 0.8, 1.5, 6.3, NULL, 400, 'usda', ARRAY['green smoothie', 'green juice smoothie', 'spinach smoothie', 'kale smoothie'], '220 cal per smoothie (400g). Spinach, banana, apple, almond milk blended.', NULL, 'breakfast', 1),

-- Berry Smoothie: ~65 cal/100g, ~260 cal per smoothie (~400g)
('berry_smoothie', 'Berry Smoothie', 65.0, 1.5, 13.5, 0.5, 1.8, 9.5, NULL, 400, 'usda', ARRAY['berry smoothie', 'mixed berry smoothie', 'strawberry smoothie', 'blueberry smoothie'], '260 cal per smoothie (400g). Mixed berries, banana, yogurt, orange juice blended.', NULL, 'breakfast', 1),

-- Banana Peanut Butter Smoothie: ~100 cal/100g, ~400 cal per smoothie (~400g)
('banana_pb_smoothie', 'Banana Peanut Butter Smoothie', 100.0, 4.5, 13.0, 3.5, 1.3, 7.5, NULL, 400, 'usda', ARRAY['banana peanut butter smoothie', 'pb banana smoothie', 'peanut butter smoothie'], '400 cal per smoothie (400g). Banana, peanut butter, milk, honey blended.', NULL, 'breakfast', 1),

-- Protein Smoothie (whey + banana): ~80 cal/100g, ~320 cal per smoothie (~400g)
('protein_smoothie', 'Protein Smoothie (Whey + Banana)', 80.0, 6.3, 10.0, 1.5, 0.8, 6.0, NULL, 400, 'usda', ARRAY['protein smoothie', 'protein shake', 'whey smoothie', 'post workout smoothie'], '320 cal per smoothie (400g). Whey protein powder, banana, milk, ice blended.', NULL, 'breakfast', 1),

-- Orange Juice (8 oz / 240ml): ~45 cal/100g, ~112 cal per glass (~248g)
('orange_juice', 'Orange Juice (8 oz)', 45.0, 0.7, 10.4, 0.2, 0.2, 8.4, NULL, 248, 'usda', ARRAY['orange juice', 'oj', 'fresh orange juice', 'florida orange juice'], '112 cal per glass (248g, 8 oz). 100% orange juice, not from concentrate.', NULL, 'breakfast', 1),

-- Milk (8 oz glass, whole): ~61 cal/100g, ~149 cal per glass (~244g)
('milk_whole_glass', 'Milk (Whole, 8 oz)', 61.0, 3.2, 4.8, 3.3, 0.0, 5.1, NULL, 244, 'usda', ARRAY['milk', 'whole milk', 'glass of milk', 'cup of milk'], '149 cal per glass (244g, 8 oz). Whole milk (3.25% fat).', NULL, 'breakfast', 1),
