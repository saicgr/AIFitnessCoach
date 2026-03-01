-- ============================================================================
-- 274_overrides_casual_dining.sql
-- Generated: 2026-02-28
-- Total items: 436
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes
) VALUES
-- ============================================
-- BATCH 4: Restaurant Nutrition Data
-- IHOP, Denny's, Cracker Barrel, Outback Steakhouse,
-- Red Lobster, Texas Roadhouse, TGI Friday's,
-- Cheesecake Factory, Arby's, Hardee's/Carl's Jr.
-- ============================================
-- ============================================
-- 1. IHOP
-- Source: ihop.com, healthyfastfood.org, fastfoodnutrition.org
-- ============================================
-- Pancakes (3 pancakes short stack ~225g)
-- Pancakes (5 pancakes full stack ~375g)
-- Chocolate Chip Pancakes (4 pancakes ~350g)
-- New York Cheesecake Pancakes (4 pancakes ~400g)
-- Strawberry Banana Pancakes (4 pancakes ~380g)
-- Belgian Waffle (~200g)
-- Chicken Fajita Omelette (~300g)
-- Bacon Temptation Omelette (~320g)
-- Spinach & Mushroom Omelette (~300g)
-- Big Steak Omelette (~350g)
-- Avocado Bacon & Cheese Omelette (~280g)
-- Classic Steakburger (~250g)
-- Big Brunch Steakburger (~350g)
-- Grilled Tilapia (~200g)
-- T-Bone Steak 12oz (~340g)
-- Buttermilk Crispy Chicken & Fries (~350g)
-- Pot Roast Entree (~300g)
-- BLTA Sandwich (~350g)
-- Ham & Egg Melt Sandwich (~300g)
-- Breakfast Sampler (~350g)
-- 2x2x2 Combo (~200g)
-- 55+ Grilled Chicken Dinner (~180g)
-- French Toast (~250g)
-- Crepe (Swedish) (~220g)
-- Egg White Omelette (~150g)
-- Hash Browns (~150g)
-- Onion Rings (~140g)
-- Mozzarella Sticks (~180g)
-- Crispy Chicken Strips (~200g)
-- House Salad (~200g)
-- ============================================
-- 2. DENNY'S
-- Source: dennys.com, fastfoodnutrition.org, fastfoodmenuprices.com
-- ============================================
-- Original Grand Slam (~310g / 11oz)
-- Lumberjack Slam (~450g)
-- Moons Over My Hammy (~480g / 17oz)
-- Buttermilk Pancakes (3) (~225g)
-- Chocolate Lava Cake (~200g)
-- Sirloin Steak Dinner (8oz ~227g steak only)
-- French Fries (~120g)
-- Hash Browns (~150g)
-- All-American Slam (~350g)
-- Loaded Veggie Omelette (~300g)
-- Ultimate Omelette (~320g)
-- Slamburger (~250g)
-- Bacon Slamburger (~280g)
-- Country Fried Steak & Eggs (~350g)
-- Chicken Strips (~200g)
-- Fit Slam (~280g)
-- Super Bird (~250g)
-- Club Sandwich (~280g)
-- Seasoned Fries (~150g)
-- Mozzarella Sticks (~180g)
-- Zesty Nachos (~350g)
-- Brownie (~150g)
-- Pancake Puppies (~180g)
-- ============================================
-- 3. CRACKER BARREL
-- Source: crackerbarrel.com, crackerbarrelmenuwithprices.com
-- ============================================
-- Old Timer's Breakfast (eggs/meat portion ~200g)
-- Biscuits n Gravy (~250g)
-- Biscuit (1 biscuit ~80g)
-- Country Fried Steak with Gravy (~300g)
-- Meatloaf (~250g)
-- Chicken n Dumplins (~350g)
-- Chicken Fried Chicken w/ Gravy (~400g)
-- Grilled Chicken Tenderloins (6) (~250g)
-- Hand-Breaded Fried Chicken Tenders (~250g)
-- Homestyle Chicken w/ Gravy (~300g)
-- Fried Catfish w/ Hushpuppies (~350g)
-- Spicy Grilled Catfish (~200g)
-- Friday Fish Fry (4 cod) (~350g)
-- Chicken Pot Pie (~400g)
-- Saturday BBQ Ribs (~350g)
-- Turkey n Dressing (~250g)
-- Thick-Sliced Bacon (3 slices ~50g)
-- Smoked Sausage Patties (~80g)
-- Mini Pancakes (kids ~120g)
-- Scrambled Eggs (~80g)
-- Broccoli Cheddar Chicken (~350g)
-- Country Fried Pork Chops (~400g)
-- Chicken n Rice (~350g)
-- Mini Confetti Pancakes (kids ~130g)
-- ============================================
-- 4. OUTBACK STEAKHOUSE
-- Source: outback.com, fastfoodnutrition.org, fatsecret.com
-- ============================================
-- Bloomin' Onion (~600g whole appetizer)
-- Victoria's Filet Mignon 6oz (~170g)
-- Victoria's Filet Mignon 9oz (~255g)
-- Outback Center-Cut Sirloin 6oz (~170g)
-- Outback Center-Cut Sirloin 10oz (~283g)
-- Bone-In Ribeye 18oz (~510g)
-- NY Strip 14oz (~400g)
-- Outback Ribs Half Rack (~350g)
-- Outback Ribs Full Rack (~700g)
-- Aussie Cheese Fries (~450g)
-- Gold Coast Coconut Shrimp (~200g)
-- Kookaburra Wings (~350g)
-- Alice Springs Chicken (~350g)
-- Grilled Chicken on the Barbie (~250g)
-- Loaded Baked Potato (~300g)
-- Sweet Potato (~250g)
-- House Salad (no dressing ~200g)
-- Caesar Salad w/ Dressing (~200g)
-- Wedge Salad w/ Dressing (~250g)
-- Steamed Broccoli (~150g)
-- Grilled Asparagus (~120g)
-- Chocolate Thunder From Down Under (~300g)
-- NY Cheesecake (~200g)
-- Steak Fries (~200g)
-- Mac A Roo n Cheese (~250g)
-- Fresh Fruit (~150g)
-- ============================================
-- 5. RED LOBSTER
-- Source: redlobster.com, fastfoodnutrition.org
-- ============================================
-- Cheddar Bay Biscuit (~60g)
-- Admiral's Feast (~500g)
-- Live Maine Lobster (~500g / 1.25lb)
-- Snow Crab Legs (~400g)
-- Rock Lobster Tail (~250g)
-- Walt's Favorite Shrimp (~250g)
-- Garlic Shrimp Scampi (~250g)
-- Parrot Isle Coconut Shrimp (~300g)
-- Seaside Shrimp Trio (~400g)
-- Fish and Chips (~350g)
-- Parmesan-Crusted Fresh Tilapia (~250g)
-- Maple-Glazed Chicken (~250g)
-- Wood-Grilled Peppercorn Sirloin (~300g)
-- Salmon New Orleans (~300g)
-- Shrimp Linguini Alfredo (~400g)
-- Chocolate Wave (~200g)
-- Key Lime Pie (~150g)
-- Strawberry Cheesecake (~180g)
-- Crispy Calamari (~350g)
-- Seafood-Stuffed Mushrooms (~200g)
-- Shrimp Cocktail (~120g)
-- Mashed Potatoes (~200g)
-- French Fries (~120g)
-- Coleslaw (~150g)
-- Wild Rice Pilaf (~150g)
-- Baked Potato (~250g)
-- ============================================
-- 6. TEXAS ROADHOUSE
-- Source: texasroadhouse.com, texasroadhousenutritioncalculator.us
-- ============================================
-- 6oz Dallas Filet (~170g)
-- 8oz Dallas Filet (~227g)
-- 6oz USDA Choice Sirloin (~170g)
-- 12oz Ft. Worth Ribeye (~340g)
-- Bone-In Ribeye (~500g)
-- Fall-off-the-Bone Ribs Full Slab (~650g)
-- Fall-off-the-Bone Ribs Half Slab (~350g)
-- Grilled BBQ Chicken (~250g)
-- Herb Crusted Chicken (~220g)
-- Country Fried Chicken (~300g)
-- Chicken Critters (~200g)
-- Grilled Salmon 5oz (~140g)
-- Fish and Chips (~400g)
-- Fresh Baked Bread (roll) (~60g)
-- Honey Cinnamon Butter (~30g)
-- Cactus Blossom (~500g)
-- Fried Pickles (~200g)
-- Rattlesnake Bites (~200g)
-- Cheese Fries (~400g)
-- Mashed Potatoes (~200g)
-- Green Beans (~150g)
-- Buttered Corn (~150g)
-- Steak Fries (~150g)
-- Loaded Baked Potato (~300g)
-- Sweet Potato (~250g)
-- Coleslaw (~150g)
-- Strawberry Cheesecake (~200g)
-- Big Ol Brownie (~250g)
-- Granny's Apple Classic (~300g)
-- All-American Cheeseburger (~300g)
-- Smokehouse Burger (~350g)
-- Country Fried Sirloin (~400g)
-- ============================================
-- 7. TGI FRIDAY'S
-- Source: tgifridays.com, fastfoodnutrition.org
-- ============================================
-- Loaded Potato Skins (~300g)
-- Mozzarella Sticks (~200g)
-- Spinach & Artichoke Dip (~300g)
-- Boneless Wings (~300g)
-- Wings Appetizer (bone-in ~300g)
-- Chicken Quesadilla (~400g)
-- Tostado Nachos (~500g)
-- Pan-Seared Pot Stickers (~200g)
-- Giant Soft Pretzel (~200g)
-- Cheeseburger (~250g)
-- Bacon Cheeseburger (~280g)
-- Whiskey-Glazed Burger (~350g)
-- Crispy Chicken Tenders with Fries (~350g)
-- Whiskey-Glazed Chicken (~350g)
-- Simply Grilled Salmon (~300g)
-- Dragon-Glaze Salmon (~300g)
-- Fish and Chips (~400g)
-- BBQ Chicken Salad (~350g)
-- Caesar Salad with Grilled Chicken (~300g)
-- Million Dollar Cobb Salad (~350g)
-- Bucket of Bones (~450g)
-- Brownie Obsession (~250g)
-- Oreo Madness (~200g)
-- Donut Cheesecake (~200g)
-- Green Bean Fries (~250g)
-- Chips & Salsa (~200g)
-- Red Velvet Cake (~250g)
-- ============================================
-- 8. CHEESECAKE FACTORY
-- Source: thecheesecakefactory.com, fastfoodnutrition.org
-- ============================================
-- Original Cheesecake (~200g)
-- Oreo Dream Extreme Cheesecake (~250g)
-- Fresh Strawberry Cheesecake (~200g)
-- Godiva Chocolate Cheesecake (~230g)
-- Dulce De Leche Cheesecake (~230g)
-- Low Carb Cheesecake (~180g)
-- Tiramisu Cheesecake (~200g)
-- Chicken Madeira (~400g)
-- Louisiana Chicken Pasta (~500g)
-- Fettuccini Alfredo (~450g)
-- Bistro Shrimp Pasta (~500g)
-- Pasta Carbonara (~450g)
-- Americana Cheeseburger (~350g)
-- Bacon Bacon Cheeseburger (~400g)
-- Crispy Fried Chicken Sandwich (~400g)
-- Herb Crusted Salmon (~400g)
-- Fresh Grilled Salmon (~400g)
-- Miso Salmon (~350g)
-- Shrimp Scampi (~400g)
-- Fried Shrimp Platter (~450g)
-- Breakfast Burrito (~450g)
-- Bruleed French Toast (~400g)
-- Cinnamon Roll Pancakes (~450g)
-- Chocolate Tower Truffle Cake (~250g)
-- Godiva Chocolate Brownie Sundae (~350g)
-- Avocado Eggrolls (~300g)
-- Fried Mac and Cheese Bites (~250g)
-- Cheese Flatbread Pizza (~350g)
-- Kids French Fries (~120g)
-- ============================================
-- 9. ARBY'S
-- Source: arbys.com, fastfoodnutrition.org, nutritionvalue.org
-- ============================================
-- Classic Roast Beef (~154g)
-- Double Roast Beef (~220g)
-- Half Pound Roast Beef (~280g)
-- Beef n Cheddar Classic (~200g)
-- Smokehouse Brisket (~300g)
-- Crispy Chicken Sandwich (~200g)
-- Roast Turkey & Swiss (~300g)
-- Corned Beef Reuben (~300g)
-- French Dip & Swiss (~280g)
-- Gyro (Greek) (~250g)
-- Curly Fries Medium (~130g)
-- Curly Fries Large (~180g)
-- Crinkle Fries Medium (~130g)
-- Mozzarella Sticks (~140g)
-- Jalapeno Bites (~120g)
-- Onion Rings (~140g)
-- Vanilla Shake (~400g)
-- Chocolate Shake (~400g)
-- Jamocha Shake (~400g)
-- Turnover (Apple or Cherry) (~90g)
-- Chocolate Lava Cake (~110g)
-- Market Fresh Roast Turkey Ranch & Bacon (~350g)
-- Loaded Italian (~300g)
-- Chicken Nuggets (6 piece ~100g)
-- Side Salad (~120g)
-- Potato Cakes (~120g)
-- ============================================
-- 10. HARDEE'S / CARL'S JR.
-- Source: hardees.com, carlsjr.com, fastfoodnutrition.org
-- Note: Existing items NOT duplicated:
--   hardees_big_hot_ham_n_cheese, hardees_crispy_curls_medium,
--   hardees_vanilla_ice_cream_shake, hardees_spicy_chicken_tenders_3pc
-- ============================================
-- Famous Star with Cheese (~260g)
-- Super Star with Cheese (~340g)
-- Monster Double Thickburger (~450g)
-- Original Thickburger (~280g)
-- Frisco Thickburger (~280g)
-- Western Bacon Cheeseburger (~300g)
-- Big Cheeseburger (~200g)
-- Small Cheeseburger (~130g)
-- Big Chicken Fillet Sandwich (~220g)
-- Charbroiled Chicken Club (~250g)
-- Big Roast Beef (~200g)
-- Monster Roast Beef (~300g)
-- Bacon Egg & Cheese Biscuit (~200g)
-- Sausage Biscuit (~190g)
-- Sausage & Egg Biscuit (~220g)
-- Monster Biscuit (~300g)
-- Biscuit n Gravy (~250g)
-- Made from Scratch Biscuit (~80g)
-- Loaded Breakfast Burrito (~250g)
-- Frisco Breakfast Sandwich (~160g)
-- Country Fried Steak Biscuit (~230g)
-- Chicken Fillet Biscuit (~220g)
-- Natural-Cut French Fries Medium (~140g)
-- Onion Rings (~140g)
-- Cole Slaw (~120g)
-- Green Beans (~100g)
-- Mashed Potatoes (~120g)
-- Apple Turnover (~90g)
-- Chocolate Chip Cookie (~50g)
-- Ice Cream Shake (Chocolate) (~450g)
-- Jumbo Chili Dog (~200g)
-- Redhook Beer-Battered Cod (~220g)
-- Beyond Thickburger (~300g)
-- Hash Rounds Medium (~100g)
-- Grits (~200g)
-- Low Carb Breakfast Bowl (~250g)
('ihop_original_buttermilk_pancakes_short_stack', 'IHOP Original Buttermilk Pancakes (Short Stack)', 200.0, 5.8, 26.2, 8.0, 1.3, 4.9, 225, 225, 'ihop.com', ARRAY['ihop pancakes', 'ihop short stack', 'ihop buttermilk pancakes'], '450 cal per short stack (3 pancakes, ~225g)'),
('ihop_original_buttermilk_pancakes_full_stack', 'IHOP Original Buttermilk Pancakes (Full Stack)', 197.6, 5.6, 25.9, 8.0, 1.3, 4.8, 375, 375, 'ihop.com', ARRAY['ihop full stack pancakes', 'ihop 5 pancakes'], '741 cal per full stack (5 pancakes, ~375g)'),
('ihop_chocolate_chip_pancakes', 'IHOP Chocolate Chip Buttermilk Pancakes', 197.4, 5.1, 31.4, 6.0, 1.7, 11.7, 350, 350, 'ihop.com', ARRAY['ihop chocolate chip pancakes', 'ihop choc chip'], '691 cal per 4 pancakes (~350g)'),
('ihop_new_york_cheesecake_pancakes', 'IHOP New York Cheesecake Pancakes', 232.8, 5.8, 32.5, 9.0, 1.5, 12.8, 400, 400, 'ihop.com', ARRAY['ihop cheesecake pancakes', 'ihop ny cheesecake pancakes'], '931 cal per 4 pancakes (~400g)'),
('ihop_strawberry_banana_pancakes', 'IHOP Strawberry Banana Pancakes', 179.2, 5.0, 31.6, 3.9, 2.1, 10.8, 380, 380, 'ihop.com', ARRAY['ihop strawberry banana pancakes', 'ihop fruit pancakes'], '681 cal per 4 pancakes (~380g)'),
('ihop_belgian_waffle', 'IHOP Belgian Waffle', 295.5, 5.5, 34.5, 15.0, 1.5, 8.5, 200, 200, 'ihop.com', ARRAY['ihop waffle', 'ihop belgian waffle'], '591 cal per waffle (~200g)'),
('ihop_chicken_fajita_omelette', 'IHOP Chicken Fajita Omelette', 303.7, 25.0, 8.3, 19.0, 1.0, 3.0, 300, 300, 'ihop.com', ARRAY['ihop chicken fajita omelette', 'ihop fajita omelette'], '911 cal per omelette (~300g)'),
('ihop_bacon_temptation_omelette', 'IHOP Bacon Temptation Omelette', 347.2, 23.1, 5.0, 25.9, 0.3, 1.6, 320, 320, 'ihop.com', ARRAY['ihop bacon omelette', 'ihop bacon temptation'], '1111 cal per omelette (~320g)'),
('ihop_spinach_mushroom_omelette', 'IHOP Spinach & Mushroom Omelette', 303.7, 15.7, 7.7, 23.7, 1.0, 2.0, 300, 300, 'ihop.com', ARRAY['ihop spinach omelette', 'ihop mushroom omelette'], '911 cal per omelette (~300g)'),
('ihop_big_steak_omelette', 'IHOP Big Steak Omelette', 297.4, 18.9, 11.4, 19.7, 1.4, 2.0, 350, 350, 'ihop.com', ARRAY['ihop steak omelette', 'ihop big steak'], '1041 cal per omelette (~350g)'),
('ihop_avocado_bacon_cheese_omelette', 'IHOP Avocado Bacon & Cheese Omelette', 314.6, 20.4, 5.4, 23.9, 1.4, 0.7, 280, 280, 'ihop.com', ARRAY['ihop avocado omelette', 'ihop abc omelette'], '881 cal per omelette (~280g)'),
('ihop_classic_steakburger', 'IHOP Classic Steakburger', 268.4, 12.8, 16.8, 16.8, 1.2, 3.2, 250, 250, 'ihop.com', ARRAY['ihop burger', 'ihop steakburger', 'ihop cheeseburger'], '671 cal per burger (~250g)'),
('ihop_big_brunch_steakburger', 'IHOP Big Brunch Steakburger', 286.0, 13.1, 16.9, 18.3, 1.1, 3.4, 350, 350, 'ihop.com', ARRAY['ihop brunch burger', 'ihop big brunch'], '1001 cal per burger (~350g)'),
('ihop_grilled_tilapia', 'IHOP Grilled Tilapia', 120.0, 19.0, 1.0, 5.0, 0.5, 0.5, 200, 200, 'ihop.com', ARRAY['ihop tilapia', 'ihop grilled fish'], '240 cal per serving (~200g)'),
('ihop_tbone_steak', 'IHOP T-Bone Steak (12 oz)', 114.7, 15.9, 0.3, 5.6, 0.0, 0.0, 340, 340, 'ihop.com', ARRAY['ihop t-bone', 'ihop steak', 'ihop tbone'], '390 cal per 12oz steak (~340g)'),
('ihop_crispy_chicken_and_fries', 'IHOP Buttermilk Crispy Chicken & Fries', 254.6, 13.4, 23.1, 12.3, 1.7, 1.4, 350, 350, 'ihop.com', ARRAY['ihop crispy chicken', 'ihop chicken and fries'], '891 cal per serving (~350g)'),
('ihop_pot_roast', 'IHOP Pot Roast Entree', 123.3, 10.7, 5.0, 7.0, 0.0, 0.7, 300, 300, 'ihop.com', ARRAY['ihop pot roast', 'ihop roast'], '370 cal per serving (~300g)'),
('ihop_blta_sandwich', 'IHOP BLTA Sandwich', 334.6, 8.9, 21.1, 24.0, 2.3, 4.0, 350, 350, 'ihop.com', ARRAY['ihop blt', 'ihop blta', 'ihop bacon sandwich'], '1171 cal per sandwich (~350g)'),
('ihop_ham_egg_melt', 'IHOP Ham & Egg Melt Sandwich', 320.3, 19.0, 22.7, 17.0, 1.3, 3.0, 300, 300, 'ihop.com', ARRAY['ihop ham egg melt', 'ihop ham sandwich'], '961 cal per sandwich (~300g)'),
('ihop_breakfast_sampler', 'IHOP Breakfast Sampler', 251.7, 9.1, 17.7, 16.0, 1.1, 2.9, 350, 350, 'ihop.com', ARRAY['ihop sampler', 'ihop breakfast sampler'], '881 cal per serving (~350g)'),
('ihop_2x2x2_combo', 'IHOP 2x2x2 Combo', 160.0, 4.5, 19.5, 7.5, 1.0, 3.5, 200, 200, 'ihop.com', ARRAY['ihop 2x2x2', 'ihop combo'], '320 cal per combo (~200g)'),
('ihop_55_grilled_chicken', 'IHOP 55+ Grilled Chicken Dinner', 83.3, 17.8, 0.6, 1.7, 0.6, 0.6, 180, 180, 'ihop.com', ARRAY['ihop senior chicken', 'ihop grilled chicken dinner'], '150 cal per serving (~180g)'),
('ihop_original_french_toast', 'IHOP Original French Toast', 284.0, 8.0, 36.0, 12.0, 1.6, 12.0, 250, 250, 'ihop.com', ARRAY['ihop french toast', 'ihop thick cut french toast'], '710 cal per serving (~250g)'),
('ihop_swedish_crepe', 'IHOP Swedish Crepe', 268.6, 6.4, 32.7, 12.7, 0.9, 14.5, 220, 220, 'ihop.com', ARRAY['ihop crepe', 'ihop swedish crepe', 'ihop crepes'], '591 cal per serving (~220g)'),
('ihop_egg_white_omelette', 'IHOP Egg White Omelette', 66.7, 12.0, 0.7, 2.0, 0.7, 0.0, 150, 150, 'ihop.com', ARRAY['ihop egg white omelette', 'ihop healthy omelette'], '100 cal per omelette (~150g)'),
('ihop_hash_browns', 'IHOP Hash Browns', 193.3, 2.7, 24.0, 10.0, 2.0, 0.7, 150, 150, 'ihop.com', ARRAY['ihop hash browns', 'ihop hashbrowns'], '290 cal per serving (~150g)'),
('ihop_onion_rings', 'IHOP Onion Rings', 364.3, 3.6, 35.7, 21.4, 2.1, 5.0, 140, 140, 'ihop.com', ARRAY['ihop onion rings'], '510 cal per serving (~140g)'),
('ihop_mozzarella_sticks', 'IHOP Mozzarella Sticks', 338.9, 13.9, 27.8, 18.3, 1.1, 2.8, 180, 180, 'ihop.com', ARRAY['ihop mozzarella sticks', 'ihop mozz sticks'], '610 cal per serving (~180g)'),
('ihop_crispy_chicken_strips', 'IHOP Crispy Chicken Strips', 285.0, 21.0, 17.0, 13.0, 1.0, 1.0, 200, 200, 'ihop.com', ARRAY['ihop chicken strips', 'ihop chicken tenders'], '570 cal per serving (~200g)'),
('ihop_house_salad', 'IHOP House Salad', 55.0, 3.0, 7.0, 2.0, 2.0, 3.0, 200, 200, 'ihop.com', ARRAY['ihop salad', 'ihop side salad', 'ihop house salad'], '110 cal per salad (~200g)'),
('dennys_original_grand_slam', 'Denny''s Original Grand Slam', 225.8, 7.1, 25.5, 11.0, 1.0, 4.5, 310, 310, 'dennys.com', ARRAY['dennys grand slam', 'dennys slam', 'dennys breakfast'], '700 cal per serving (~310g)'),
('dennys_lumberjack_slam', 'Denny''s Lumberjack Slam', 215.8, 8.2, 22.0, 10.4, 0.9, 3.1, 450, 450, 'dennys.com', ARRAY['dennys lumberjack slam', 'dennys lumberjack'], '971 cal per serving (~450g)'),
('dennys_moons_over_my_hammy', 'Denny''s Moons Over My Hammy', 202.1, 9.2, 11.9, 12.9, 0.8, 2.5, 480, 480, 'dennys.com', ARRAY['dennys moons over my hammy', 'dennys moon hammy'], '970 cal per serving (~480g)'),
('dennys_buttermilk_pancakes', 'Denny''s Buttermilk Pancakes (3)', 182.2, 4.4, 28.0, 6.2, 0.9, 4.9, 225, 225, 'dennys.com', ARRAY['dennys pancakes', 'dennys buttermilk pancakes'], '410 cal per 3 pancakes (~225g)'),
('dennys_chocolate_lava_cake', 'Denny''s Chocolate Lava Cake', 350.5, 4.0, 42.5, 17.5, 2.0, 30.0, 200, 200, 'dennys.com', ARRAY['dennys lava cake', 'dennys chocolate cake'], '701 cal per serving (~200g)'),
('dennys_sirloin_steak', 'Denny''s Sirloin Steak (8 oz)', 158.6, 26.4, 0.9, 6.2, 0.0, 0.0, 227, 227, 'dennys.com', ARRAY['dennys steak', 'dennys sirloin', 'dennys steak dinner'], '360 cal per 8oz steak (~227g)'),
('dennys_french_fries', 'Denny''s French Fries', 333.3, 3.3, 41.7, 16.7, 3.3, 0.0, 120, 120, 'dennys.com', ARRAY['dennys fries', 'dennys french fries'], '400 cal per serving (~120g)'),
('dennys_hash_browns', 'Denny''s Hash Browns', 140.0, 2.0, 20.0, 6.0, 2.0, 0.7, 150, 150, 'dennys.com', ARRAY['dennys hash browns', 'dennys hashbrowns'], '210 cal per serving (~150g)'),
('dennys_all_american_slam', 'Denny''s All-American Slam', 220.0, 10.3, 14.3, 12.9, 0.6, 2.3, 350, 350, 'dennys.com', ARRAY['dennys all american slam', 'dennys all american'], '770 cal per serving (~350g)'),
('dennys_loaded_veggie_omelette', 'Denny''s Loaded Veggie Omelette', 206.7, 14.0, 10.0, 12.3, 1.3, 3.3, 300, 300, 'dennys.com', ARRAY['dennys veggie omelette', 'dennys vegetable omelette'], '620 cal per omelette (~300g)'),
('dennys_ultimate_omelette', 'Denny''s Ultimate Omelette', 278.1, 16.9, 6.9, 19.4, 0.6, 1.9, 320, 320, 'dennys.com', ARRAY['dennys ultimate omelette'], '890 cal per omelette (~320g)'),
('dennys_slamburger', 'Denny''s Slamburger', 340.0, 16.0, 24.0, 20.0, 1.2, 4.0, 250, 250, 'dennys.com', ARRAY['dennys slamburger', 'dennys burger'], '850 cal per burger (~250g)'),
('dennys_bacon_slamburger', 'Denny''s Bacon Slamburger', 346.4, 16.4, 22.5, 20.7, 1.1, 3.6, 280, 280, 'dennys.com', ARRAY['dennys bacon slamburger', 'dennys bacon burger'], '970 cal per burger (~280g)'),
('dennys_country_fried_steak_eggs', 'Denny''s Country Fried Steak & Eggs', 262.9, 10.9, 21.7, 13.7, 0.9, 1.7, 350, 350, 'dennys.com', ARRAY['dennys country fried steak', 'dennys CFS'], '920 cal per serving (~350g)'),
('dennys_chicken_strips', 'Denny''s Chicken Strips', 290.0, 20.0, 19.0, 14.0, 1.0, 1.0, 200, 200, 'dennys.com', ARRAY['dennys chicken strips', 'dennys chicken tenders'], '580 cal per serving (~200g)'),
('dennys_fit_slam', 'Denny''s Fit Slam', 135.7, 14.3, 12.5, 3.9, 1.4, 4.6, 280, 280, 'dennys.com', ARRAY['dennys fit slam', 'dennys healthy breakfast'], '380 cal per serving (~280g)'),
('dennys_super_bird', 'Denny''s Super Bird', 292.0, 17.2, 22.0, 14.8, 0.8, 3.2, 250, 250, 'dennys.com', ARRAY['dennys super bird', 'dennys turkey sandwich'], '730 cal per sandwich (~250g)'),
('dennys_club_sandwich', 'Denny''s Club Sandwich', 296.4, 12.5, 22.9, 15.7, 1.1, 3.2, 280, 280, 'dennys.com', ARRAY['dennys club sandwich', 'dennys club'], '830 cal per sandwich (~280g)'),
('dennys_seasoned_fries', 'Denny''s Seasoned Fries', 300.0, 3.3, 36.7, 15.3, 3.3, 0.7, 150, 150, 'dennys.com', ARRAY['dennys seasoned fries'], '450 cal per serving (~150g)'),
('dennys_mozzarella_sticks', 'Denny''s Mozzarella Sticks', 327.8, 13.3, 27.8, 17.2, 1.1, 2.2, 180, 180, 'dennys.com', ARRAY['dennys mozzarella sticks', 'dennys mozz sticks'], '590 cal per serving (~180g)'),
('dennys_zesty_nachos', 'Denny''s Zesty Nachos', 322.9, 10.0, 27.1, 18.6, 2.9, 2.9, 350, 350, 'dennys.com', ARRAY['dennys nachos', 'dennys zesty nachos'], '1130 cal per serving (~350g)'),
('dennys_brownie', 'Denny''s Brownie', 380.0, 4.7, 48.7, 18.0, 2.0, 34.7, 150, 150, 'dennys.com', ARRAY['dennys brownie', 'dennys chocolate brownie'], '570 cal per brownie (~150g)'),
('dennys_pancake_puppies', 'Denny''s Pancake Puppies', 355.6, 4.4, 41.1, 17.2, 1.1, 17.8, 180, 180, 'dennys.com', ARRAY['dennys pancake puppies'], '640 cal per serving (~180g)'),
('cracker_barrel_old_timers_breakfast', 'Cracker Barrel Old Timer''s Breakfast', 75.0, 7.0, 1.0, 5.0, 0.0, 0.5, 200, 200, 'crackerbarrel.com', ARRAY['cracker barrel old timers', 'cracker barrel breakfast'], '150 cal per serving (~200g)'),
('cracker_barrel_biscuits_n_gravy', 'Cracker Barrel Biscuits n'' Gravy', 200.0, 5.2, 21.2, 10.8, 0.8, 1.6, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel biscuits gravy', 'cracker barrel biscuits and gravy'], '500 cal per serving (~250g)'),
('cracker_barrel_biscuit', 'Cracker Barrel Biscuit', 200.0, 3.8, 25.0, 8.8, 0.6, 2.5, 80, 80, 'crackerbarrel.com', ARRAY['cracker barrel biscuit'], '160 cal per biscuit (~80g)'),
('cracker_barrel_country_fried_steak', 'Cracker Barrel Country Fried Steak w/ Gravy', 200.0, 12.3, 16.3, 9.3, 0.3, 0.3, 300, 300, 'crackerbarrel.com', ARRAY['cracker barrel country fried steak', 'cracker barrel CFS'], '600 cal per serving (~300g)'),
('cracker_barrel_meatloaf', 'Cracker Barrel Meatloaf', 180.0, 12.8, 5.6, 11.6, 0.4, 2.4, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel meatloaf', 'cracker barrel meat loaf'], '450 cal per serving (~250g)'),
('cracker_barrel_chicken_n_dumplins', 'Cracker Barrel Chicken n'' Dumplins', 102.9, 5.4, 15.1, 2.3, 1.7, 0.6, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel chicken dumplins', 'cracker barrel chicken and dumplings'], '360 cal per serving (~350g)'),
('cracker_barrel_chicken_fried_chicken', 'Cracker Barrel Chicken Fried Chicken w/ Gravy', 285.0, 18.5, 17.5, 15.0, 1.3, 1.0, 400, 400, 'crackerbarrel.com', ARRAY['cracker barrel chicken fried chicken', 'cracker barrel CFC'], '1140 cal per serving (~400g)'),
('cracker_barrel_grilled_chicken_tenders', 'Cracker Barrel Grilled Chicken Tenderloins', 128.0, 22.8, 2.4, 3.2, 0.2, 2.0, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel grilled chicken', 'cracker barrel chicken tenders'], '320 cal per 6 tenders (~250g)'),
('cracker_barrel_fried_chicken_tenders', 'Cracker Barrel Hand-Breaded Fried Chicken Tenders', 240.0, 22.8, 10.4, 12.0, 1.6, 0.0, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel fried chicken tenders'], '600 cal per serving (~250g)'),
('cracker_barrel_homestyle_chicken', 'Cracker Barrel Homestyle Chicken w/ Gravy', 203.3, 12.7, 12.3, 11.3, 0.7, 0.7, 300, 300, 'crackerbarrel.com', ARRAY['cracker barrel homestyle chicken'], '610 cal per serving (~300g)'),
('cracker_barrel_fried_catfish', 'Cracker Barrel Fried Catfish w/ Hushpuppies', 231.4, 10.9, 10.0, 16.3, 1.1, 1.4, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel fried catfish', 'cracker barrel catfish'], '810 cal per serving (~350g)'),
('cracker_barrel_grilled_catfish', 'Cracker Barrel Spicy Grilled Catfish', 130.0, 16.5, 1.5, 7.5, 0.5, 0.0, 200, 200, 'crackerbarrel.com', ARRAY['cracker barrel grilled catfish'], '260 cal per 2 fillets (~200g)'),
('cracker_barrel_fish_fry', 'Cracker Barrel Friday Fish Fry', 211.4, 10.6, 17.1, 11.1, 0.9, 0.9, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel fish fry', 'cracker barrel cod'], '740 cal per 4 fillets (~350g)'),
('cracker_barrel_chicken_pot_pie', 'Cracker Barrel Sunday Chicken Pot Pie', 240.0, 8.8, 20.5, 13.8, 1.8, 1.0, 400, 400, 'crackerbarrel.com', ARRAY['cracker barrel pot pie', 'cracker barrel chicken pot pie'], '960 cal per serving (~400g)'),
('cracker_barrel_bbq_ribs', 'Cracker Barrel Saturday Southern BBQ Ribs', 220.0, 10.0, 13.1, 14.6, 0.1, 12.3, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel ribs', 'cracker barrel bbq ribs'], '770 cal per serving (~350g)'),
('cracker_barrel_turkey_n_dressing', 'Cracker Barrel Thursday Turkey n'' Dressing', 92.0, 11.6, 4.8, 3.2, 0.2, 1.2, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel turkey', 'cracker barrel turkey dressing'], '230 cal per serving (~250g)'),
('cracker_barrel_bacon', 'Cracker Barrel Thick-Sliced Bacon (3)', 380.0, 26.0, 0.0, 32.0, 0.0, 0.0, 50, 50, 'crackerbarrel.com', ARRAY['cracker barrel bacon'], '190 cal per 3 slices (~50g)'),
('cracker_barrel_sausage_patties', 'Cracker Barrel Smoked Sausage Patties', 300.0, 17.5, 2.5, 25.0, 0.0, 0.0, 80, 80, 'crackerbarrel.com', ARRAY['cracker barrel sausage', 'cracker barrel sausage patties'], '240 cal per serving (~80g)'),
('cracker_barrel_mini_pancakes', 'Cracker Barrel Mini Pancakes', 266.7, 3.3, 34.2, 12.5, 2.5, 4.2, 120, 120, 'crackerbarrel.com', ARRAY['cracker barrel mini pancakes', 'cracker barrel kids pancakes'], '320 cal per serving (~120g)'),
('cracker_barrel_scrambled_eggs', 'Cracker Barrel Scrambled Eggs', 87.5, 8.8, 0.6, 5.6, 0.0, 0.0, 80, 80, 'crackerbarrel.com', ARRAY['cracker barrel eggs', 'cracker barrel scrambled eggs'], '70 cal per serving (~80g)'),
('cracker_barrel_broccoli_cheddar_chicken', 'Cracker Barrel Wednesday Broccoli Cheddar Chicken', 197.1, 11.4, 10.0, 12.6, 1.4, 0.3, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel broccoli cheddar chicken'], '690 cal per serving (~350g)'),
('cracker_barrel_country_fried_pork_chops', 'Cracker Barrel Tuesday Country Fried Pork Chops', 260.0, 13.3, 10.8, 18.0, 0.8, 0.5, 400, 400, 'crackerbarrel.com', ARRAY['cracker barrel pork chops', 'cracker barrel fried pork'], '1040 cal per serving (~400g)'),
('cracker_barrel_chicken_n_rice', 'Cracker Barrel Monday Chicken n'' Rice', 145.7, 6.9, 16.0, 5.7, 0.0, 0.6, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel chicken rice'], '510 cal per serving (~350g)'),
('cracker_barrel_confetti_pancakes', 'Cracker Barrel Mini Confetti Pancakes', 300.0, 3.8, 44.6, 12.3, 2.3, 10.0, 130, 130, 'crackerbarrel.com', ARRAY['cracker barrel confetti pancakes'], '390 cal per serving (~130g)'),
('outback_bloomin_onion', 'Outback Bloomin'' Onion', 325.0, 3.0, 20.5, 25.8, 2.8, 4.0, 600, 600, 'outback.com', ARRAY['outback bloomin onion', 'outback blooming onion'], '1950 cal per whole appetizer (~600g)'),
('outback_victorias_filet_6oz', 'Outback Victoria''s Filet Mignon (6 oz)', 141.2, 27.6, 0.0, 5.3, 0.0, 0.0, 170, 170, 'outback.com', ARRAY['outback filet mignon', 'outback victorias filet', 'outback filet 6oz'], '240 cal per 6oz filet (~170g)'),
('outback_victorias_filet_9oz', 'Outback Victoria''s Filet Mignon (9 oz)', 149.0, 28.6, 0.0, 5.5, 0.0, 0.0, 255, 255, 'outback.com', ARRAY['outback filet 9oz', 'outback large filet'], '380 cal per 9oz filet (~255g)'),
('outback_center_cut_sirloin_6oz', 'Outback Center-Cut Sirloin (6 oz)', 247.1, 29.4, 2.9, 12.9, 0.6, 0.6, 170, 170, 'outback.com', ARRAY['outback sirloin', 'outback sirloin 6oz'], '420 cal per 6oz sirloin (~170g)'),
('outback_center_cut_sirloin_10oz', 'Outback Center-Cut Sirloin (10 oz)', 229.0, 27.6, 2.1, 12.0, 0.4, 0.4, 283, 283, 'outback.com', ARRAY['outback sirloin 10oz'], '648 cal per 10oz sirloin (~283g)'),
('outback_bone_in_ribeye', 'Outback Bone-In Ribeye (18 oz)', 235.3, 21.6, 0.2, 15.7, 0.0, 0.0, 510, 510, 'outback.com', ARRAY['outback ribeye', 'outback bone in ribeye'], '1200 cal per 18oz (~510g)'),
('outback_ny_strip', 'Outback New York Strip (14 oz)', 215.0, 22.5, 0.5, 13.0, 0.0, 0.0, 400, 400, 'outback.com', ARRAY['outback ny strip', 'outback new york strip'], '860 cal per 14oz (~400g)'),
('outback_baby_back_ribs_half', 'Outback Baby Back Ribs (Half Rack)', 205.7, 17.1, 5.1, 12.6, 0.3, 3.4, 350, 350, 'outback.com', ARRAY['outback half rack ribs', 'outback baby back ribs half'], '720 cal per half rack (~350g)'),
('outback_baby_back_ribs_full', 'Outback Baby Back Ribs (Full Rack)', 205.7, 17.1, 5.1, 13.0, 0.3, 3.4, 700, 700, 'outback.com', ARRAY['outback full rack ribs', 'outback baby back ribs'], '1440 cal per full rack (~700g)'),
('outback_aussie_cheese_fries', 'Outback Aussie Cheese Fries', 313.3, 8.9, 26.7, 18.9, 2.2, 1.1, 450, 450, 'outback.com', ARRAY['outback cheese fries', 'outback aussie fries'], '1410 cal per serving (~450g)'),
('outback_coconut_shrimp', 'Outback Gold Coast Coconut Shrimp', 220.0, 8.0, 20.0, 12.0, 1.0, 6.0, 200, 200, 'outback.com', ARRAY['outback coconut shrimp', 'outback gold coast shrimp'], '440 cal per serving (~200g)'),
('outback_kookaburra_wings', 'Outback Kookaburra Wings', 240.0, 18.6, 8.6, 14.3, 0.6, 2.9, 350, 350, 'outback.com', ARRAY['outback wings', 'outback kookaburra wings'], '840 cal per serving (~350g)'),
('outback_alice_springs_chicken', 'Outback Alice Springs Chicken', 228.6, 24.3, 8.6, 10.9, 0.6, 2.9, 350, 350, 'outback.com', ARRAY['outback alice springs chicken', 'outback alice springs'], '800 cal per serving (~350g)'),
('outback_grilled_chicken', 'Outback Grilled Chicken on the Barbie', 156.0, 25.2, 4.0, 4.4, 0.4, 1.6, 250, 250, 'outback.com', ARRAY['outback grilled chicken', 'outback chicken on barbie'], '390 cal per serving (~250g)'),
('outback_loaded_baked_potato', 'Outback Loaded Baked Potato', 113.3, 3.0, 15.7, 4.7, 1.3, 1.0, 300, 300, 'outback.com', ARRAY['outback loaded potato', 'outback baked potato loaded'], '340 cal per potato (~300g)'),
('outback_sweet_potato', 'Outback Sweet Potato', 132.0, 2.4, 22.8, 4.0, 2.8, 10.0, 250, 250, 'outback.com', ARRAY['outback sweet potato'], '330 cal per potato (~250g)'),
('outback_house_salad', 'Outback House Salad (no dressing)', 90.0, 3.0, 10.0, 4.5, 2.5, 4.0, 200, 200, 'outback.com', ARRAY['outback house salad', 'outback side salad'], '180 cal per salad (~200g)'),
('outback_caesar_salad', 'Outback Caesar Salad w/ Dressing', 130.0, 3.0, 10.0, 9.0, 1.5, 1.5, 200, 200, 'outback.com', ARRAY['outback caesar salad'], '260 cal per salad (~200g)'),
('outback_wedge_salad', 'Outback Wedge Salad w/ Dressing', 176.0, 4.0, 8.4, 18.4, 1.6, 4.0, 250, 250, 'outback.com', ARRAY['outback wedge salad'], '440 cal per salad (~250g)'),
('outback_steamed_broccoli', 'Outback Steamed Fresh Broccoli', 40.0, 3.3, 4.0, 1.3, 2.0, 1.3, 150, 150, 'outback.com', ARRAY['outback broccoli', 'outback steamed broccoli'], '60 cal per serving (~150g)'),
('outback_grilled_asparagus', 'Outback Grilled Asparagus', 58.3, 3.3, 3.3, 3.3, 1.7, 1.7, 120, 120, 'outback.com', ARRAY['outback asparagus'], '70 cal per serving (~120g)'),
('outback_chocolate_thunder', 'Outback Chocolate Thunder From Down Under', 546.7, 5.0, 60.0, 30.0, 3.3, 43.3, 300, 300, 'outback.com', ARRAY['outback chocolate thunder', 'outback chocolate dessert'], '1640 cal per serving (~300g)'),
('outback_ny_cheesecake', 'Outback New York Style Cheesecake', 355.0, 6.0, 32.5, 22.5, 0.5, 22.0, 200, 200, 'outback.com', ARRAY['outback cheesecake', 'outback ny cheesecake'], '710 cal per slice (~200g)'),
('outback_steak_fries', 'Outback Steak Fries', 205.0, 3.0, 26.0, 10.0, 2.0, 0.5, 200, 200, 'outback.com', ARRAY['outback fries', 'outback steak fries'], '410 cal per serving (~200g)'),
('outback_mac_n_cheese', 'Outback Mac A Roo n'' Cheese', 280.0, 10.0, 24.0, 16.0, 0.8, 2.0, 250, 250, 'outback.com', ARRAY['outback mac and cheese', 'outback mac n cheese'], '700 cal per serving (~250g)'),
('outback_fresh_fruit', 'Outback Fresh Fruit', 33.3, 0.7, 8.0, 0.3, 1.3, 6.0, 150, 150, 'outback.com', ARRAY['outback fruit', 'outback fresh fruit'], '50 cal per serving (~150g)'),
('red_lobster_cheddar_bay_biscuit', 'Red Lobster Cheddar Bay Biscuit', 266.7, 3.3, 26.7, 16.7, 0.8, 1.7, 60, 60, 'redlobster.com', ARRAY['red lobster biscuit', 'red lobster cheddar bay biscuit', 'cheddar bay biscuit'], '160 cal per biscuit (~60g)'),
('red_lobster_admirals_feast', 'Red Lobster Admiral''s Feast', 284.0, 14.0, 28.0, 12.0, 2.0, 2.0, 500, 500, 'redlobster.com', ARRAY['red lobster admirals feast', 'red lobster admiral feast'], '1420 cal per serving (~500g)'),
('red_lobster_live_maine_lobster', 'Red Lobster Live Maine Lobster', 88.0, 16.0, 2.0, 1.6, 0.0, 0.0, 500, 500, 'redlobster.com', ARRAY['red lobster maine lobster', 'red lobster live lobster'], '440 cal per lobster (~500g)'),
('red_lobster_snow_crab_legs', 'Red Lobster Snow Crab Legs', 110.0, 20.0, 0.5, 4.0, 0.0, 0.0, 400, 400, 'redlobster.com', ARRAY['red lobster snow crab', 'red lobster crab legs'], '440 cal per serving (~400g)'),
('red_lobster_rock_lobster_tail', 'Red Lobster Rock Lobster Tail', 284.0, 20.0, 20.0, 14.0, 0.4, 1.2, 250, 250, 'redlobster.com', ARRAY['red lobster lobster tail', 'red lobster rock lobster'], '710 cal per serving (~250g)'),
('red_lobster_walts_favorite_shrimp', 'Red Lobster Walt''s Favorite Shrimp', 248.0, 12.0, 24.0, 10.4, 1.2, 1.2, 250, 250, 'redlobster.com', ARRAY['red lobster walts shrimp', 'red lobster hand breaded shrimp'], '620 cal per serving (~250g)'),
('red_lobster_garlic_shrimp_scampi', 'Red Lobster Garlic Shrimp Scampi', 140.0, 16.0, 1.6, 7.6, 0.4, 0.4, 250, 250, 'redlobster.com', ARRAY['red lobster shrimp scampi', 'red lobster scampi'], '350 cal per serving (~250g)'),
('red_lobster_coconut_shrimp', 'Red Lobster Parrot Isle Jumbo Coconut Shrimp', 320.0, 8.0, 32.0, 16.0, 2.0, 8.0, 300, 300, 'redlobster.com', ARRAY['red lobster coconut shrimp', 'red lobster parrot isle shrimp'], '960 cal per serving (~300g)'),
('red_lobster_seaside_shrimp_trio', 'Red Lobster Seaside Shrimp Trio', 325.0, 13.0, 30.0, 14.0, 1.5, 3.0, 400, 400, 'redlobster.com', ARRAY['red lobster shrimp trio', 'red lobster seaside trio'], '1300 cal per serving (~400g)'),
('red_lobster_fish_and_chips', 'Red Lobster Fish and Chips', 257.1, 10.3, 27.1, 11.4, 2.0, 1.1, 350, 350, 'redlobster.com', ARRAY['red lobster fish and chips', 'red lobster fish chips'], '900 cal per serving (~350g)'),
('red_lobster_parmesan_tilapia', 'Red Lobster Parmesan-Crusted Fresh Tilapia', 220.0, 16.0, 12.0, 10.0, 0.4, 0.8, 250, 250, 'redlobster.com', ARRAY['red lobster tilapia', 'red lobster parmesan tilapia'], '550 cal per serving (~250g)'),
('red_lobster_maple_glazed_chicken', 'Red Lobster Maple-Glazed Chicken', 188.0, 22.0, 10.0, 6.0, 0.4, 6.0, 250, 250, 'redlobster.com', ARRAY['red lobster chicken', 'red lobster maple chicken'], '470 cal per serving (~250g)'),
('red_lobster_peppercorn_sirloin', 'Red Lobster Wood-Grilled Peppercorn Sirloin', 216.7, 22.0, 6.7, 10.7, 0.7, 1.3, 300, 300, 'redlobster.com', ARRAY['red lobster sirloin', 'red lobster steak'], '650 cal per serving (~300g)'),
('red_lobster_salmon_new_orleans', 'Red Lobster Salmon New Orleans', 226.7, 18.0, 8.7, 13.3, 0.7, 2.0, 300, 300, 'redlobster.com', ARRAY['red lobster salmon', 'red lobster salmon new orleans'], '680 cal per serving (~300g)'),
('red_lobster_shrimp_linguini_alfredo', 'Red Lobster Shrimp Linguini Alfredo', 335.0, 11.0, 32.5, 16.3, 1.5, 2.5, 400, 400, 'redlobster.com', ARRAY['red lobster alfredo', 'red lobster shrimp pasta'], '1340 cal per serving (~400g)'),
('red_lobster_chocolate_wave', 'Red Lobster Chocolate Wave', 565.0, 6.0, 62.5, 30.0, 3.0, 45.0, 200, 200, 'redlobster.com', ARRAY['red lobster chocolate wave', 'red lobster chocolate cake'], '1130 cal per serving (~200g)'),
('red_lobster_key_lime_pie', 'Red Lobster Key Lime Pie', 266.7, 4.0, 32.0, 14.0, 0.7, 22.0, 150, 150, 'redlobster.com', ARRAY['red lobster key lime pie'], '400 cal per slice (~150g)'),
('red_lobster_strawberry_cheesecake', 'Red Lobster Strawberry Cheesecake', 327.8, 5.6, 34.4, 18.3, 0.6, 23.3, 180, 180, 'redlobster.com', ARRAY['red lobster cheesecake', 'red lobster strawberry cheesecake'], '590 cal per slice (~180g)'),
('red_lobster_crispy_calamari', 'Red Lobster Crispy Calamari and Vegetables', 505.7, 12.9, 44.3, 28.6, 3.4, 4.0, 350, 350, 'redlobster.com', ARRAY['red lobster calamari', 'red lobster fried calamari'], '1770 cal per serving (~350g)'),
('red_lobster_stuffed_mushrooms', 'Red Lobster Seafood-Stuffed Mushrooms', 220.0, 12.0, 14.0, 12.0, 1.0, 2.0, 200, 200, 'redlobster.com', ARRAY['red lobster stuffed mushrooms', 'red lobster mushrooms'], '440 cal per serving (~200g)'),
('red_lobster_shrimp_cocktail', 'Red Lobster Shrimp Cocktail', 108.3, 18.3, 6.7, 0.8, 0.8, 3.3, 120, 120, 'redlobster.com', ARRAY['red lobster shrimp cocktail'], '130 cal per serving (~120g)'),
('red_lobster_mashed_potatoes', 'Red Lobster Mashed Potatoes', 95.0, 2.5, 14.0, 3.5, 1.0, 1.0, 200, 200, 'redlobster.com', ARRAY['red lobster mashed potatoes'], '190 cal per serving (~200g)'),
('red_lobster_french_fries', 'Red Lobster French Fries', 241.7, 3.3, 30.0, 11.7, 2.5, 0.0, 120, 120, 'redlobster.com', ARRAY['red lobster fries', 'red lobster french fries'], '290 cal per serving (~120g)'),
('red_lobster_coleslaw', 'Red Lobster Coleslaw', 173.3, 1.3, 14.0, 12.7, 2.0, 10.7, 150, 150, 'redlobster.com', ARRAY['red lobster coleslaw', 'red lobster cole slaw'], '260 cal per serving (~150g)'),
('red_lobster_wild_rice_pilaf', 'Red Lobster Wild Rice Pilaf', 93.3, 2.7, 16.0, 2.0, 1.3, 0.7, 150, 150, 'redlobster.com', ARRAY['red lobster rice', 'red lobster wild rice'], '140 cal per serving (~150g)'),
('red_lobster_baked_potato', 'Red Lobster Baked Potato', 84.0, 3.2, 16.0, 1.2, 1.6, 0.8, 250, 250, 'redlobster.com', ARRAY['red lobster baked potato'], '210 cal per potato (~250g)'),
('texas_roadhouse_dallas_filet_6oz', 'Texas Roadhouse Dallas Filet (6 oz)', 158.8, 26.5, 3.5, 5.9, 1.2, 1.2, 170, 170, 'texasroadhouse.com', ARRAY['texas roadhouse filet', 'texas roadhouse dallas filet'], '270 cal per 6oz filet (~170g)'),
('texas_roadhouse_dallas_filet_8oz', 'Texas Roadhouse Dallas Filet (8 oz)', 158.6, 26.4, 3.5, 5.7, 0.9, 0.9, 227, 227, 'texasroadhouse.com', ARRAY['texas roadhouse filet 8oz', 'texas roadhouse 8oz filet'], '360 cal per 8oz filet (~227g)'),
('texas_roadhouse_sirloin_6oz', 'Texas Roadhouse USDA Choice Sirloin (6 oz)', 147.1, 27.1, 1.8, 3.5, 0.6, 0.6, 170, 170, 'texasroadhouse.com', ARRAY['texas roadhouse sirloin', 'texas roadhouse 6oz sirloin'], '250 cal per 6oz sirloin (~170g)'),
('texas_roadhouse_ribeye_12oz', 'Texas Roadhouse Ft. Worth Ribeye (12 oz)', 282.4, 22.9, 3.5, 21.2, 1.2, 0.6, 340, 340, 'texasroadhouse.com', ARRAY['texas roadhouse ribeye', 'texas roadhouse ft worth ribeye'], '960 cal per 12oz ribeye (~340g)'),
('texas_roadhouse_bone_in_ribeye', 'Texas Roadhouse Bone-In Ribeye', 296.0, 21.6, 1.0, 22.4, 0.6, 0.4, 500, 500, 'texasroadhouse.com', ARRAY['texas roadhouse bone in ribeye'], '1480 cal per bone-in ribeye (~500g)'),
('texas_roadhouse_ribs_full', 'Texas Roadhouse Fall-off-the-Bone Ribs (Full)', 223.1, 17.8, 2.3, 15.7, 0.6, 1.5, 650, 650, 'texasroadhouse.com', ARRAY['texas roadhouse full rack ribs', 'texas roadhouse ribs full slab'], '1450 cal per full slab (~650g)'),
('texas_roadhouse_ribs_half', 'Texas Roadhouse Fall-off-the-Bone Ribs (Half)', 257.1, 20.6, 2.6, 18.0, 0.9, 1.7, 350, 350, 'texasroadhouse.com', ARRAY['texas roadhouse half rack ribs', 'texas roadhouse ribs half'], '900 cal per half slab (~350g)'),
('texas_roadhouse_grilled_bbq_chicken', 'Texas Roadhouse Grilled BBQ Chicken', 120.0, 18.4, 7.6, 1.4, 0.8, 6.0, 250, 250, 'texasroadhouse.com', ARRAY['texas roadhouse bbq chicken', 'texas roadhouse grilled chicken'], '300 cal per serving (~250g)'),
('texas_roadhouse_herb_crusted_chicken', 'Texas Roadhouse Herb Crusted Chicken', 118.2, 21.4, 5.5, 1.8, 1.8, 3.6, 220, 220, 'texasroadhouse.com', ARRAY['texas roadhouse herb chicken', 'texas roadhouse herb crusted chicken'], '260 cal per serving (~220g)'),
('texas_roadhouse_country_fried_chicken', 'Texas Roadhouse Country Fried Chicken', 250.0, 15.0, 15.0, 12.0, 1.0, 1.0, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse country fried chicken', 'texas roadhouse fried chicken'], '750 cal per serving (~300g)'),
('texas_roadhouse_chicken_critters', 'Texas Roadhouse Chicken Critters', 240.0, 22.5, 13.0, 10.5, 1.5, 1.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse chicken critters', 'texas roadhouse chicken tenders'], '480 cal per serving (~200g)'),
('texas_roadhouse_grilled_salmon_5oz', 'Texas Roadhouse Grilled Salmon (5 oz)', 292.9, 19.3, 1.4, 23.6, 0.0, 0.0, 140, 140, 'texasroadhouse.com', ARRAY['texas roadhouse salmon', 'texas roadhouse grilled salmon'], '410 cal per 5oz (~140g)'),
('texas_roadhouse_fish_and_chips', 'Texas Roadhouse Fish and Chips', 197.5, 10.5, 17.8, 9.5, 2.0, 0.5, 400, 400, 'texasroadhouse.com', ARRAY['texas roadhouse fish and chips', 'texas roadhouse fish chips'], '790 cal per serving (~400g)'),
('texas_roadhouse_bread_roll', 'Texas Roadhouse Fresh Baked Bread Roll', 200.0, 5.0, 30.0, 5.0, 1.7, 5.0, 60, 60, 'texasroadhouse.com', ARRAY['texas roadhouse roll', 'texas roadhouse bread', 'texas roadhouse rolls'], '120 cal per roll (~60g)'),
('texas_roadhouse_honey_cinnamon_butter', 'Texas Roadhouse Honey Cinnamon Butter', 333.3, 0.0, 20.0, 26.7, 0.0, 16.7, 30, 30, 'texasroadhouse.com', ARRAY['texas roadhouse butter', 'texas roadhouse cinnamon butter'], '100 cal per serving (~30g)'),
('texas_roadhouse_cactus_blossom', 'Texas Roadhouse Cactus Blossom', 450.0, 5.0, 47.2, 27.0, 3.8, 7.2, 500, 500, 'texasroadhouse.com', ARRAY['texas roadhouse cactus blossom', 'texas roadhouse onion blossom'], '2250 cal per appetizer (~500g)'),
('texas_roadhouse_fried_pickles', 'Texas Roadhouse Fried Pickles', 275.0, 5.0, 30.0, 13.0, 2.5, 3.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse fried pickles', 'texas roadhouse pickles'], '550 cal per serving (~200g)'),
('texas_roadhouse_rattlesnake_bites', 'Texas Roadhouse Rattlesnake Bites', 280.0, 8.0, 28.0, 14.0, 2.0, 2.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse rattlesnake bites', 'texas roadhouse jalapeno bites'], '560 cal per serving (~200g)'),
('texas_roadhouse_cheese_fries', 'Texas Roadhouse Cheese Fries', 310.0, 9.5, 31.5, 16.3, 3.5, 0.5, 400, 400, 'texasroadhouse.com', ARRAY['texas roadhouse cheese fries'], '1240 cal per serving (~400g)'),
('texas_roadhouse_mashed_potatoes', 'Texas Roadhouse Mashed Potatoes', 110.0, 2.5, 16.0, 4.5, 1.0, 1.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse mashed potatoes'], '220 cal per serving (~200g)'),
('texas_roadhouse_green_beans', 'Texas Roadhouse Green Beans', 66.7, 2.0, 8.0, 3.3, 2.7, 2.7, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse green beans'], '100 cal per serving (~150g)'),
('texas_roadhouse_buttered_corn', 'Texas Roadhouse Buttered Corn', 140.0, 2.7, 18.7, 6.7, 2.0, 4.7, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse corn', 'texas roadhouse buttered corn'], '210 cal per serving (~150g)'),
('texas_roadhouse_steak_fries', 'Texas Roadhouse Steak Fries', 240.0, 2.7, 32.0, 11.3, 2.7, 0.0, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse fries', 'texas roadhouse steak fries'], '360 cal per serving (~150g)'),
('texas_roadhouse_loaded_baked_potato', 'Texas Roadhouse Loaded Baked Potato', 216.7, 5.0, 26.7, 10.0, 2.3, 1.7, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse loaded potato', 'texas roadhouse baked potato'], '650 cal per potato (~300g)'),
('texas_roadhouse_sweet_potato', 'Texas Roadhouse Sweet Potato', 140.0, 2.0, 24.0, 4.0, 3.2, 10.0, 250, 250, 'texasroadhouse.com', ARRAY['texas roadhouse sweet potato'], '350 cal per potato (~250g)'),
('texas_roadhouse_coleslaw', 'Texas Roadhouse Coleslaw', 220.0, 1.3, 16.0, 16.7, 2.0, 12.0, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse coleslaw', 'texas roadhouse cole slaw'], '330 cal per serving (~150g)'),
('texas_roadhouse_strawberry_cheesecake', 'Texas Roadhouse Strawberry Cheesecake', 390.0, 6.0, 37.0, 22.0, 1.0, 27.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse cheesecake', 'texas roadhouse strawberry cheesecake'], '780 cal per slice (~200g)'),
('texas_roadhouse_brownie', 'Texas Roadhouse Big Ol'' Brownie', 492.0, 6.0, 56.0, 24.0, 2.4, 40.0, 250, 250, 'texasroadhouse.com', ARRAY['texas roadhouse brownie', 'texas roadhouse big brownie'], '1230 cal per serving (~250g)'),
('texas_roadhouse_grannys_apple', 'Texas Roadhouse Granny''s Apple Classic', 420.0, 4.0, 58.0, 18.0, 2.7, 36.0, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse apple dessert', 'texas roadhouse grannys apple'], '1260 cal per serving (~300g)'),
('texas_roadhouse_cheeseburger', 'Texas Roadhouse All-American Cheeseburger', 336.7, 14.0, 23.3, 21.0, 1.3, 4.0, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse cheeseburger', 'texas roadhouse burger'], '1010 cal per burger (~300g)'),
('texas_roadhouse_smokehouse_burger', 'Texas Roadhouse Smokehouse Burger', 342.9, 13.7, 22.9, 20.0, 1.4, 4.6, 350, 350, 'texasroadhouse.com', ARRAY['texas roadhouse smokehouse burger'], '1200 cal per burger (~350g)'),
('texas_roadhouse_country_fried_sirloin', 'Texas Roadhouse Country Fried Sirloin', 275.0, 13.0, 20.0, 15.0, 1.5, 1.5, 400, 400, 'texasroadhouse.com', ARRAY['texas roadhouse country fried sirloin'], '1100 cal per serving (~400g)'),
('tgi_fridays_loaded_potato_skins', 'TGI Friday''s Loaded Potato Skins', 306.7, 8.7, 20.0, 19.3, 2.0, 2.0, 300, 300, 'tgifridays.com', ARRAY['tgi fridays potato skins', 'fridays potato skins'], '920 cal per serving (~300g)'),
('tgi_fridays_mozzarella_sticks', 'TGI Friday''s Mozzarella Sticks', 285.0, 14.0, 25.0, 14.0, 1.0, 2.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays mozzarella sticks', 'fridays mozz sticks'], '570 cal per serving (~200g)'),
('tgi_fridays_spinach_artichoke_dip', 'TGI Friday''s Spinach & Artichoke Dip', 240.0, 6.7, 20.0, 14.7, 2.0, 2.7, 300, 300, 'tgifridays.com', ARRAY['tgi fridays spinach dip', 'fridays artichoke dip'], '720 cal per serving (~300g)'),
('tgi_fridays_boneless_wings', 'TGI Friday''s Boneless Wings', 296.7, 16.7, 23.3, 14.0, 1.3, 5.0, 300, 300, 'tgifridays.com', ARRAY['tgi fridays boneless wings', 'fridays wings boneless'], '890 cal per serving (~300g)'),
('tgi_fridays_wings', 'TGI Friday''s Wings', 266.7, 21.3, 8.0, 15.3, 0.7, 3.3, 300, 300, 'tgifridays.com', ARRAY['tgi fridays wings', 'fridays wings'], '800 cal per serving (~300g)'),
('tgi_fridays_chicken_quesadilla', 'TGI Friday''s Chicken Quesadilla', 405.0, 15.0, 32.5, 22.5, 2.5, 2.5, 400, 400, 'tgifridays.com', ARRAY['tgi fridays quesadilla', 'fridays chicken quesadilla'], '1620 cal per serving (~400g)'),
('tgi_fridays_tostado_nachos', 'TGI Friday''s Tostado Nachos', 390.0, 10.0, 34.0, 22.0, 4.0, 4.0, 500, 500, 'tgifridays.com', ARRAY['tgi fridays nachos', 'fridays nachos'], '1950 cal per serving (~500g)'),
('tgi_fridays_pot_stickers', 'TGI Friday''s Pan-Seared Pot Stickers', 195.0, 8.5, 22.0, 7.5, 1.5, 4.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays pot stickers', 'fridays potstickers'], '390 cal per serving (~200g)'),
('tgi_fridays_soft_pretzel', 'TGI Friday''s Giant Soft Pretzel', 315.0, 7.5, 48.0, 9.5, 2.0, 3.5, 200, 200, 'tgifridays.com', ARRAY['tgi fridays pretzel', 'fridays soft pretzel'], '630 cal per pretzel (~200g)'),
('tgi_fridays_cheeseburger', 'TGI Friday''s Cheeseburger', 252.0, 12.8, 20.0, 14.0, 1.2, 3.2, 250, 250, 'tgifridays.com', ARRAY['tgi fridays cheeseburger', 'fridays burger'], '630 cal per burger (~250g)'),
('tgi_fridays_bacon_cheeseburger', 'TGI Friday''s Bacon Cheeseburger', 250.0, 13.6, 18.2, 14.6, 1.1, 3.2, 280, 280, 'tgifridays.com', ARRAY['tgi fridays bacon cheeseburger', 'fridays bacon burger'], '700 cal per burger (~280g)'),
('tgi_fridays_whiskey_glazed_burger', 'TGI Friday''s Whiskey-Glazed Burger', 277.1, 12.6, 21.4, 16.0, 1.4, 6.0, 350, 350, 'tgifridays.com', ARRAY['tgi fridays whiskey burger', 'fridays whiskey glazed burger'], '970 cal per burger (~350g)'),
('tgi_fridays_chicken_tenders', 'TGI Friday''s Crispy Chicken Tenders with Fries', 288.6, 14.6, 24.6, 14.3, 2.3, 1.4, 350, 350, 'tgifridays.com', ARRAY['tgi fridays chicken tenders', 'fridays chicken tenders'], '1010 cal per serving (~350g)'),
('tgi_fridays_whiskey_glazed_chicken', 'TGI Friday''s Whiskey-Glazed Chicken', 274.3, 14.3, 18.6, 13.1, 0.9, 10.3, 350, 350, 'tgifridays.com', ARRAY['tgi fridays whiskey chicken', 'fridays glazed chicken'], '960 cal per serving (~350g)'),
('tgi_fridays_grilled_salmon', 'TGI Friday''s Simply Grilled Salmon', 240.0, 16.7, 3.3, 16.7, 0.3, 0.7, 300, 300, 'tgifridays.com', ARRAY['tgi fridays salmon', 'fridays grilled salmon'], '720 cal per serving (~300g)'),
('tgi_fridays_dragon_glaze_salmon', 'TGI Friday''s Dragon-Glaze Salmon', 266.7, 14.0, 16.7, 15.3, 0.7, 8.0, 300, 300, 'tgifridays.com', ARRAY['tgi fridays dragon salmon', 'fridays dragon glaze salmon'], '800 cal per serving (~300g)'),
('tgi_fridays_fish_and_chips', 'TGI Friday''s Fish & Chips', 295.0, 10.0, 28.8, 14.5, 2.5, 1.0, 400, 400, 'tgifridays.com', ARRAY['tgi fridays fish and chips', 'fridays fish chips'], '1180 cal per serving (~400g)'),
('tgi_fridays_bbq_chicken_salad', 'TGI Friday''s BBQ Chicken Salad', 220.0, 12.6, 15.4, 10.0, 3.1, 6.3, 350, 350, 'tgifridays.com', ARRAY['tgi fridays bbq chicken salad', 'fridays bbq salad'], '770 cal per salad (~350g)'),
('tgi_fridays_caesar_salad_chicken', 'TGI Friday''s Caesar Salad with Grilled Chicken', 193.3, 16.0, 10.0, 10.0, 2.0, 1.7, 300, 300, 'tgifridays.com', ARRAY['tgi fridays caesar salad', 'fridays chicken caesar'], '580 cal per salad (~300g)'),
('tgi_fridays_cobb_salad', 'TGI Friday''s Million Dollar Cobb Salad', 220.0, 12.3, 10.3, 14.0, 2.6, 2.9, 350, 350, 'tgifridays.com', ARRAY['tgi fridays cobb salad', 'fridays cobb salad'], '770 cal per salad (~350g)'),
('tgi_fridays_bucket_of_bones', 'TGI Friday''s Bucket of Bones', 348.9, 22.2, 11.1, 20.0, 0.9, 5.6, 450, 450, 'tgifridays.com', ARRAY['tgi fridays bucket of bones', 'fridays ribs'], '1570 cal per serving (~450g)'),
('tgi_fridays_brownie_obsession', 'TGI Friday''s Brownie Obsession', 376.0, 5.2, 44.0, 20.0, 2.4, 32.0, 250, 250, 'tgifridays.com', ARRAY['tgi fridays brownie', 'fridays brownie obsession'], '940 cal per serving (~250g)'),
('tgi_fridays_oreo_madness', 'TGI Friday''s Oreo Madness', 335.0, 5.0, 40.0, 17.0, 1.5, 28.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays oreo madness', 'fridays oreo dessert'], '670 cal per serving (~200g)'),
('tgi_fridays_donut_cheesecake', 'TGI Friday''s Donut Cheesecake', 435.0, 6.5, 42.0, 25.0, 1.0, 30.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays cheesecake', 'fridays donut cheesecake'], '870 cal per serving (~200g)'),
('tgi_fridays_green_bean_fries', 'TGI Friday''s Green Bean Fries', 360.0, 6.0, 32.0, 20.0, 4.0, 4.0, 250, 250, 'tgifridays.com', ARRAY['tgi fridays green bean fries', 'fridays green bean fries'], '900 cal per serving (~250g)'),
('tgi_fridays_chips_salsa', 'TGI Friday''s Chips & Salsa', 140.0, 2.0, 20.0, 6.0, 2.0, 2.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays chips salsa', 'fridays chips and salsa'], '280 cal per serving (~200g)'),
('tgi_fridays_red_velvet_cake', 'TGI Friday''s Red Velvet Cake', 520.0, 4.8, 56.0, 28.0, 1.2, 44.0, 250, 250, 'tgifridays.com', ARRAY['tgi fridays red velvet', 'fridays red velvet cake'], '1300 cal per slice (~250g)'),
('cheesecake_factory_original_cheesecake', 'Cheesecake Factory Original Cheesecake', 415.0, 4.0, 23.5, 30.0, 0.5, 18.0, 200, 200, 'thecheesecakefactory.com', ARRAY['cheesecake factory original', 'cheesecake factory plain cheesecake'], '830 cal per slice (~200g)'),
('cheesecake_factory_oreo_dream', 'Cheesecake Factory Oreo Dream Extreme Cheesecake', 648.0, 5.6, 60.0, 40.0, 2.0, 48.0, 250, 250, 'thecheesecakefactory.com', ARRAY['cheesecake factory oreo cheesecake', 'cheesecake factory oreo dream'], '1620 cal per slice (~250g)'),
('cheesecake_factory_strawberry_cheesecake', 'Cheesecake Factory Fresh Strawberry Cheesecake', 500.0, 4.5, 28.0, 26.5, 1.0, 20.0, 200, 200, 'thecheesecakefactory.com', ARRAY['cheesecake factory strawberry', 'cheesecake factory strawberry cheesecake'], '1000 cal per slice (~200g)'),
('cheesecake_factory_godiva_chocolate', 'Cheesecake Factory Godiva Chocolate Cheesecake', 608.7, 5.2, 52.2, 37.4, 2.6, 40.0, 230, 230, 'thecheesecakefactory.com', ARRAY['cheesecake factory godiva', 'cheesecake factory chocolate cheesecake'], '1400 cal per slice (~230g)'),
('cheesecake_factory_dulce_de_leche', 'Cheesecake Factory Dulce De Leche Caramel Cheesecake', 604.3, 5.2, 50.0, 37.0, 0.9, 40.0, 230, 230, 'thecheesecakefactory.com', ARRAY['cheesecake factory dulce de leche', 'cheesecake factory caramel cheesecake'], '1390 cal per slice (~230g)'),
('cheesecake_factory_low_carb', 'Cheesecake Factory Low Carb Cheesecake', 338.9, 5.6, 16.7, 26.7, 1.1, 8.3, 180, 180, 'thecheesecakefactory.com', ARRAY['cheesecake factory low carb', 'cheesecake factory keto cheesecake'], '610 cal per slice (~180g)'),
('cheesecake_factory_tiramisu_cheesecake', 'Cheesecake Factory Tiramisu Cheesecake', 480.0, 5.0, 38.0, 30.0, 1.0, 28.0, 200, 200, 'thecheesecakefactory.com', ARRAY['cheesecake factory tiramisu'], '960 cal per slice (~200g)'),
('cheesecake_factory_chicken_madeira', 'Cheesecake Factory Chicken Madeira', 337.5, 17.5, 17.5, 17.5, 1.3, 3.8, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory chicken madeira', 'cheesecake factory madeira chicken'], '1350 cal per serving (~400g)'),
('cheesecake_factory_louisiana_chicken_pasta', 'Cheesecake Factory Louisiana Chicken Pasta', 330.0, 12.0, 30.0, 16.0, 2.0, 4.0, 500, 500, 'thecheesecakefactory.com', ARRAY['cheesecake factory louisiana pasta', 'cheesecake factory cajun pasta'], '1650 cal per serving (~500g)'),
('cheesecake_factory_fettuccini_alfredo', 'Cheesecake Factory Fettuccini Alfredo', 388.9, 8.9, 33.3, 22.2, 1.3, 2.2, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory alfredo', 'cheesecake factory fettuccine'], '1750 cal per serving (~450g)'),
('cheesecake_factory_bistro_shrimp_pasta', 'Cheesecake Factory Bistro Shrimp Pasta', 356.0, 10.0, 32.0, 18.0, 2.0, 4.0, 500, 500, 'thecheesecakefactory.com', ARRAY['cheesecake factory shrimp pasta', 'cheesecake factory bistro shrimp'], '1780 cal per serving (~500g)'),
('cheesecake_factory_pasta_carbonara', 'Cheesecake Factory Pasta Carbonara', 400.0, 11.1, 31.1, 22.2, 1.3, 2.2, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory carbonara'], '1800 cal per serving (~450g)'),
('cheesecake_factory_americana_cheeseburger', 'Cheesecake Factory Americana Cheeseburger', 400.0, 14.3, 28.6, 21.4, 1.4, 5.7, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory burger', 'cheesecake factory cheeseburger'], '1400 cal per burger (~350g)'),
('cheesecake_factory_bacon_cheeseburger', 'Cheesecake Factory Bacon-Bacon Cheeseburger', 397.5, 14.5, 25.0, 23.0, 1.3, 5.0, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory bacon burger'], '1590 cal per burger (~400g)'),
('cheesecake_factory_fried_chicken_sandwich', 'Cheesecake Factory Crispy Fried Chicken Sandwich', 430.0, 12.5, 30.0, 25.0, 2.0, 4.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory chicken sandwich', 'cheesecake factory fried chicken sandwich'], '1720 cal per sandwich (~400g)'),
('cheesecake_factory_herb_crusted_salmon', 'Cheesecake Factory Herb Crusted Filet of Salmon', 327.5, 17.5, 15.0, 20.0, 2.0, 2.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory salmon', 'cheesecake factory herb salmon'], '1310 cal per serving (~400g)'),
('cheesecake_factory_grilled_salmon', 'Cheesecake Factory Fresh Grilled Salmon', 310.0, 17.5, 12.5, 18.8, 2.5, 2.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory grilled salmon'], '1240 cal per serving (~400g)'),
('cheesecake_factory_miso_salmon', 'Cheesecake Factory Miso Salmon', 382.9, 16.0, 22.9, 21.4, 1.7, 10.0, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory miso salmon'], '1340 cal per serving (~350g)'),
('cheesecake_factory_shrimp_scampi', 'Cheesecake Factory Shrimp Scampi', 337.5, 12.5, 25.0, 17.5, 1.3, 2.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory shrimp scampi', 'cheesecake factory scampi'], '1350 cal per serving (~400g)'),
('cheesecake_factory_fried_shrimp', 'Cheesecake Factory Fried Shrimp Platter', 426.7, 10.0, 38.9, 22.2, 2.7, 3.3, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory fried shrimp'], '1920 cal per serving (~450g)'),
('cheesecake_factory_breakfast_burrito', 'Cheesecake Factory Breakfast Burrito', 433.3, 12.2, 30.0, 24.4, 3.3, 3.3, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory burrito', 'cheesecake factory breakfast burrito'], '1950 cal per burrito (~450g)'),
('cheesecake_factory_french_toast', 'Cheesecake Factory Bruleed French Toast', 495.0, 5.0, 52.5, 27.5, 1.3, 30.0, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory french toast', 'cheesecake factory bruleed french toast'], '1980 cal per serving (~400g)'),
('cheesecake_factory_cinnamon_roll_pancakes', 'Cheesecake Factory Cinnamon Roll Pancakes', 453.3, 5.6, 55.6, 22.2, 1.3, 33.3, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory pancakes', 'cheesecake factory cinnamon pancakes'], '2040 cal per serving (~450g)'),
('cheesecake_factory_chocolate_tower_cake', 'Cheesecake Factory Chocolate Tower Truffle Cake', 708.0, 5.6, 68.0, 42.0, 4.0, 52.0, 250, 250, 'thecheesecakefactory.com', ARRAY['cheesecake factory chocolate cake', 'cheesecake factory truffle cake'], '1770 cal per slice (~250g)'),
('cheesecake_factory_brownie_sundae', 'Cheesecake Factory Godiva Chocolate Brownie Sundae', 500.0, 5.7, 54.3, 27.1, 2.9, 40.0, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory brownie sundae', 'cheesecake factory brownie'], '1750 cal per serving (~350g)'),
('cheesecake_factory_avocado_eggrolls', 'Cheesecake Factory Avocado Eggrolls', 440.0, 6.7, 33.3, 30.0, 4.7, 4.7, 300, 300, 'thecheesecakefactory.com', ARRAY['cheesecake factory avocado eggrolls', 'cheesecake factory eggrolls'], '1320 cal per serving (~300g)'),
('cheesecake_factory_fried_mac_cheese', 'Cheesecake Factory Fried Mac and Cheese', 440.0, 12.0, 36.0, 24.0, 1.2, 2.0, 250, 250, 'thecheesecakefactory.com', ARRAY['cheesecake factory mac and cheese bites', 'cheesecake factory fried mac'], '1100 cal per serving (~250g)'),
('cheesecake_factory_cheese_flatbread', 'Cheesecake Factory Cheese Flatbread Pizza', 285.7, 10.0, 28.6, 14.3, 1.4, 2.9, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory flatbread', 'cheesecake factory pizza'], '1000 cal per flatbread (~350g)'),
('cheesecake_factory_french_fries', 'Cheesecake Factory French Fries', 250.0, 3.3, 30.0, 12.5, 2.5, 0.0, 120, 120, 'thecheesecakefactory.com', ARRAY['cheesecake factory fries', 'cheesecake factory french fries'], '300 cal per serving (~120g)'),
('arbys_classic_roast_beef', 'Arby''s Classic Roast Beef', 233.8, 14.9, 24.0, 9.1, 1.3, 3.7, 154, 154, 'arbys.com', ARRAY['arbys roast beef', 'arbys classic roast beef'], '360 cal per sandwich (~154g)'),
('arbys_double_roast_beef', 'Arby''s Double Roast Beef', 254.5, 17.3, 19.5, 11.4, 0.9, 2.7, 220, 220, 'arbys.com', ARRAY['arbys double roast beef'], '560 cal per sandwich (~220g)'),
('arbys_half_pound_roast_beef', 'Arby''s Half Pound Roast Beef', 250.0, 18.6, 16.1, 11.4, 0.7, 2.5, 280, 280, 'arbys.com', ARRAY['arbys half pound roast beef', 'arbys big roast beef'], '700 cal per sandwich (~280g)'),
('arbys_beef_n_cheddar', 'Arby''s Beef ''n Cheddar Classic', 225.0, 11.5, 22.5, 10.0, 1.0, 4.0, 200, 200, 'arbys.com', ARRAY['arbys beef and cheddar', 'arbys beef n cheddar'], '450 cal per sandwich (~200g)'),
('arbys_smokehouse_brisket', 'Arby''s Smokehouse Brisket', 290.0, 14.0, 22.0, 15.0, 1.3, 5.3, 300, 300, 'arbys.com', ARRAY['arbys brisket', 'arbys smokehouse brisket'], '870 cal per sandwich (~300g)'),
('arbys_crispy_chicken_sandwich', 'Arby''s Classic Crispy Chicken Sandwich', 255.0, 11.5, 21.5, 12.5, 1.0, 2.5, 200, 200, 'arbys.com', ARRAY['arbys crispy chicken', 'arbys chicken sandwich'], '510 cal per sandwich (~200g)'),
('arbys_roast_turkey_swiss', 'Arby''s Roast Turkey & Swiss', 246.7, 14.3, 20.0, 12.0, 1.0, 3.3, 300, 300, 'arbys.com', ARRAY['arbys turkey sandwich', 'arbys turkey swiss'], '740 cal per sandwich (~300g)'),
('arbys_corned_beef_reuben', 'Arby''s Corned Beef Reuben', 256.7, 12.7, 20.0, 13.3, 1.3, 3.3, 300, 300, 'arbys.com', ARRAY['arbys reuben', 'arbys corned beef'], '770 cal per sandwich (~300g)'),
('arbys_french_dip_swiss', 'Arby''s French Dip & Swiss', 221.4, 14.3, 18.2, 10.0, 0.7, 3.2, 280, 280, 'arbys.com', ARRAY['arbys french dip', 'arbys french dip swiss'], '620 cal per sandwich (~280g)'),
('arbys_greek_gyro', 'Arby''s Greek Gyro', 276.0, 8.8, 20.0, 16.8, 1.2, 3.6, 250, 250, 'arbys.com', ARRAY['arbys gyro', 'arbys greek gyro'], '690 cal per gyro (~250g)'),
('arbys_curly_fries_medium', 'Arby''s Curly Fries (Medium)', 323.1, 4.6, 36.2, 16.9, 3.1, 0.0, 130, 130, 'arbys.com', ARRAY['arbys curly fries', 'arbys fries medium'], '420 cal per medium (~130g)'),
('arbys_curly_fries_large', 'Arby''s Curly Fries (Large)', 338.9, 4.4, 36.7, 17.8, 3.3, 0.0, 180, 180, 'arbys.com', ARRAY['arbys curly fries large', 'arbys large fries'], '610 cal per large (~180g)'),
('arbys_crinkle_fries_medium', 'Arby''s Crinkle Fries (Medium)', 300.0, 3.1, 36.9, 13.8, 2.3, 0.0, 130, 130, 'arbys.com', ARRAY['arbys crinkle fries', 'arbys regular fries'], '390 cal per medium (~130g)'),
('arbys_mozzarella_sticks', 'Arby''s Mozzarella Sticks', 342.9, 14.3, 22.9, 18.6, 1.4, 2.9, 140, 140, 'arbys.com', ARRAY['arbys mozzarella sticks', 'arbys mozz sticks'], '480 cal per 4 sticks (~140g)'),
('arbys_jalapeno_bites', 'Arby''s Jalapeno Bites', 275.0, 5.8, 25.0, 15.0, 1.7, 2.5, 120, 120, 'arbys.com', ARRAY['arbys jalapeno bites', 'arbys jalapeno poppers'], '330 cal per serving (~120g)'),
('arbys_onion_rings', 'Arby''s Onion Rings', 321.4, 3.6, 32.9, 17.9, 2.1, 4.3, 140, 140, 'arbys.com', ARRAY['arbys onion rings'], '450 cal per serving (~140g)'),
('arbys_vanilla_shake', 'Arby''s Vanilla Shake (Medium)', 162.5, 5.8, 24.5, 5.3, 0.0, 18.5, 400, 400, 'arbys.com', ARRAY['arbys vanilla shake', 'arbys milkshake vanilla'], '650 cal per medium shake (~400g)'),
('arbys_chocolate_shake', 'Arby''s Chocolate Shake (Medium)', 167.5, 5.5, 26.3, 5.3, 0.5, 20.0, 400, 400, 'arbys.com', ARRAY['arbys chocolate shake', 'arbys milkshake chocolate'], '670 cal per medium shake (~400g)'),
('arbys_jamocha_shake', 'Arby''s Jamocha Shake (Medium)', 157.5, 5.3, 24.5, 5.0, 0.0, 18.0, 400, 400, 'arbys.com', ARRAY['arbys jamocha shake', 'arbys coffee shake'], '630 cal per medium shake (~400g)'),
('arbys_apple_turnover', 'Arby''s Apple Turnover', 300.0, 2.2, 33.3, 15.6, 1.1, 15.6, 90, 90, 'arbys.com', ARRAY['arbys turnover', 'arbys apple turnover'], '270 cal per turnover (~90g)'),
('arbys_chocolate_lava_cake', 'Arby''s Chocolate Lava Cake', 318.2, 3.6, 40.0, 15.5, 1.8, 27.3, 110, 110, 'arbys.com', ARRAY['arbys lava cake', 'arbys chocolate cake'], '350 cal per cake (~110g)'),
('arbys_turkey_ranch_bacon', 'Arby''s Market Fresh Turkey Ranch & Bacon', 245.7, 12.9, 17.1, 12.9, 1.7, 2.9, 350, 350, 'arbys.com', ARRAY['arbys turkey ranch bacon', 'arbys market fresh turkey'], '860 cal per sandwich (~350g)'),
('arbys_loaded_italian', 'Arby''s Loaded Italian', 303.3, 13.3, 20.0, 16.7, 1.3, 3.3, 300, 300, 'arbys.com', ARRAY['arbys loaded italian', 'arbys italian sub'], '910 cal per sandwich (~300g)'),
('arbys_chicken_nuggets', 'Arby''s Chicken Nuggets (6 pc)', 270.0, 12.0, 18.0, 14.0, 1.0, 0.0, 100, 100, 'arbys.com', ARRAY['arbys nuggets', 'arbys chicken nuggets'], '270 cal per 6 nuggets (~100g)'),
('arbys_side_salad', 'Arby''s Side Salad', 20.8, 1.7, 3.3, 0.0, 1.7, 1.7, 120, 120, 'arbys.com', ARRAY['arbys salad', 'arbys side salad'], '25 cal per salad (~120g)'),
('arbys_potato_cakes', 'Arby''s Potato Cakes (2 pc)', 233.3, 2.5, 26.7, 13.3, 2.5, 0.0, 120, 120, 'arbys.com', ARRAY['arbys potato cakes', 'arbys hash browns'], '280 cal per 2 cakes (~120g)'),
('hardees_famous_star_with_cheese', 'Hardee''s Famous Star with Cheese', 253.8, 10.4, 17.3, 15.0, 1.2, 3.5, 260, 260, 'hardees.com', ARRAY['hardees famous star', 'carls jr famous star'], '660 cal per burger (~260g)'),
('hardees_super_star_with_cheese', 'Hardee''s Super Star with Cheese', 270.6, 15.0, 14.1, 15.6, 0.9, 2.6, 340, 340, 'hardees.com', ARRAY['hardees super star', 'carls jr super star'], '920 cal per burger (~340g)'),
('hardees_monster_thickburger', 'Hardee''s Monster Double Thickburger', 311.1, 16.0, 15.6, 20.0, 0.7, 2.2, 450, 450, 'hardees.com', ARRAY['hardees monster burger', 'hardees monster thickburger'], '1400 cal per burger (~450g)'),
('hardees_original_thickburger', 'Hardee''s Original Thickburger', 292.9, 12.9, 18.2, 16.4, 0.7, 3.2, 280, 280, 'hardees.com', ARRAY['hardees thickburger', 'hardees original thickburger'], '820 cal per burger (~280g)'),
('hardees_frisco_thickburger', 'Hardee''s Frisco Thickburger', 271.4, 12.5, 17.9, 14.3, 0.7, 3.2, 280, 280, 'hardees.com', ARRAY['hardees frisco burger', 'hardees frisco thickburger'], '760 cal per burger (~280g)'),
('hardees_western_bacon_cheeseburger', 'Hardee''s Western Bacon Cheeseburger', 270.0, 10.7, 23.0, 13.3, 1.0, 5.3, 300, 300, 'hardees.com', ARRAY['hardees western bacon', 'carls jr western bacon'], '810 cal per burger (~300g)'),
('hardees_big_cheeseburger', 'Hardee''s Big Cheeseburger', 270.0, 12.5, 19.0, 13.5, 0.5, 3.5, 200, 200, 'hardees.com', ARRAY['hardees big cheeseburger', 'hardees cheeseburger'], '540 cal per burger (~200g)'),
('hardees_small_cheeseburger', 'Hardee''s Small Cheeseburger', 230.8, 10.8, 18.5, 10.0, 0.8, 3.1, 130, 130, 'hardees.com', ARRAY['hardees small cheeseburger'], '300 cal per burger (~130g)'),
('hardees_chicken_fillet_sandwich', 'Hardee''s Big Chicken Fillet Sandwich', 268.2, 10.9, 21.4, 14.1, 0.9, 2.7, 220, 220, 'hardees.com', ARRAY['hardees chicken sandwich', 'hardees chicken fillet'], '590 cal per sandwich (~220g)'),
('hardees_charbroiled_chicken_club', 'Hardee''s Charbroiled Chicken Club', 260.0, 14.0, 14.4, 13.2, 0.8, 2.4, 250, 250, 'hardees.com', ARRAY['hardees chicken club', 'hardees charbroiled chicken'], '650 cal per sandwich (~250g)'),
('hardees_big_roast_beef', 'Hardee''s Big Roast Beef', 250.0, 12.0, 20.5, 11.5, 0.5, 2.5, 200, 200, 'hardees.com', ARRAY['hardees roast beef', 'hardees big roast beef'], '500 cal per sandwich (~200g)'),
('hardees_monster_roast_beef', 'Hardee''s Monster Roast Beef', 290.0, 15.0, 18.7, 15.3, 0.7, 2.7, 300, 300, 'hardees.com', ARRAY['hardees monster roast beef'], '870 cal per sandwich (~300g)'),
('hardees_bacon_egg_cheese_biscuit', 'Hardee''s Bacon, Egg & Cheese Biscuit', 310.0, 10.0, 20.0, 18.5, 0.5, 2.0, 200, 200, 'hardees.com', ARRAY['hardees bacon egg cheese', 'hardees BEC biscuit'], '620 cal per biscuit (~200g)'),
('hardees_sausage_biscuit', 'Hardee''s Sausage Biscuit', 331.6, 8.4, 19.5, 22.6, 0.5, 1.6, 190, 190, 'hardees.com', ARRAY['hardees sausage biscuit'], '630 cal per biscuit (~190g)'),
('hardees_sausage_egg_biscuit', 'Hardee''s Sausage & Egg Biscuit', 318.2, 10.0, 19.1, 20.9, 0.5, 1.4, 220, 220, 'hardees.com', ARRAY['hardees sausage egg biscuit'], '700 cal per biscuit (~220g)'),
('hardees_monster_biscuit', 'Hardee''s Monster Biscuit', 296.7, 10.0, 18.3, 20.0, 0.3, 1.3, 300, 300, 'hardees.com', ARRAY['hardees monster biscuit'], '890 cal per biscuit (~300g)'),
('hardees_biscuit_n_gravy', 'Hardee''s Biscuit ''N'' Gravy', 240.0, 5.2, 24.0, 12.4, 0.4, 1.6, 250, 250, 'hardees.com', ARRAY['hardees biscuit and gravy', 'hardees biscuit gravy'], '600 cal per serving (~250g)'),
('hardees_biscuit', 'Hardee''s Made from Scratch Biscuit', 325.0, 3.8, 27.5, 18.8, 0.6, 2.5, 80, 80, 'hardees.com', ARRAY['hardees biscuit', 'hardees plain biscuit'], '260 cal per biscuit (~80g)'),
('hardees_loaded_breakfast_burrito', 'Hardee''s Loaded Breakfast Burrito', 232.0, 8.8, 16.0, 12.8, 1.2, 1.2, 250, 250, 'hardees.com', ARRAY['hardees breakfast burrito', 'hardees burrito'], '580 cal per burrito (~250g)'),
('hardees_frisco_breakfast_sandwich', 'Hardee''s Frisco Breakfast Sandwich', 268.8, 12.5, 14.4, 15.6, 0.6, 2.5, 160, 160, 'hardees.com', ARRAY['hardees frisco breakfast', 'hardees frisco sandwich'], '430 cal per sandwich (~160g)'),
('hardees_country_fried_steak_biscuit', 'Hardee''s Country Fried Steak Biscuit', 282.6, 7.8, 23.9, 15.7, 0.4, 1.3, 230, 230, 'hardees.com', ARRAY['hardees country fried steak biscuit'], '650 cal per biscuit (~230g)'),
('hardees_chicken_fillet_biscuit', 'Hardee''s Chicken Fillet Biscuit', 300.0, 10.0, 22.7, 16.4, 0.9, 2.3, 220, 220, 'hardees.com', ARRAY['hardees chicken biscuit', 'hardees chicken fillet biscuit'], '660 cal per biscuit (~220g)'),
('hardees_french_fries_medium', 'Hardee''s Natural-Cut French Fries (Medium)', 242.9, 3.6, 30.7, 11.4, 2.9, 0.0, 140, 140, 'hardees.com', ARRAY['hardees fries', 'hardees french fries', 'carls jr fries'], '340 cal per medium (~140g)'),
('hardees_onion_rings', 'Hardee''s Onion Rings', 478.6, 5.0, 42.9, 28.6, 2.9, 7.1, 140, 140, 'hardees.com', ARRAY['hardees onion rings', 'carls jr onion rings'], '670 cal per serving (~140g)'),
('hardees_cole_slaw', 'Hardee''s Cole Slaw', 141.7, 1.7, 10.0, 10.8, 1.7, 6.7, 120, 120, 'hardees.com', ARRAY['hardees coleslaw', 'hardees cole slaw'], '170 cal per serving (~120g)'),
('hardees_green_beans', 'Hardee''s Green Beans', 60.0, 2.0, 6.0, 2.0, 2.0, 2.0, 100, 100, 'hardees.com', ARRAY['hardees green beans'], '60 cal per serving (~100g)'),
('hardees_mashed_potatoes', 'Hardee''s Mashed Potatoes', 75.0, 1.7, 12.5, 2.5, 0.8, 0.8, 120, 120, 'hardees.com', ARRAY['hardees mashed potatoes'], '90 cal per serving (~120g)'),
('hardees_apple_turnover', 'Hardee''s Apple Turnover', 300.0, 2.2, 32.2, 15.6, 1.1, 14.4, 90, 90, 'hardees.com', ARRAY['hardees apple turnover', 'hardees turnover'], '270 cal per turnover (~90g)'),
('hardees_chocolate_chip_cookie', 'Hardee''s Chocolate Chip Cookie', 400.0, 4.0, 48.0, 18.0, 2.0, 28.0, 50, 50, 'hardees.com', ARRAY['hardees cookie', 'hardees chocolate chip cookie'], '200 cal per cookie (~50g)'),
('hardees_chocolate_shake', 'Hardee''s Chocolate Ice Cream Shake', 155.6, 5.8, 24.0, 4.4, 0.4, 17.8, 450, 450, 'hardees.com', ARRAY['hardees chocolate shake', 'hardees milkshake chocolate'], '700 cal per shake (~450g)'),
('hardees_jumbo_chili_dog', 'Hardee''s Jumbo Chili Dog', 195.0, 7.5, 16.5, 11.5, 1.0, 3.0, 200, 200, 'hardees.com', ARRAY['hardees chili dog', 'hardees hot dog'], '390 cal per chili dog (~200g)'),
('hardees_cod_fish_sandwich', 'Hardee''s Beer-Battered Cod Fish Sandwich', 240.9, 8.6, 17.7, 8.2, 0.9, 2.3, 220, 220, 'hardees.com', ARRAY['hardees fish sandwich', 'hardees cod sandwich'], '530 cal per sandwich (~220g)'),
('hardees_beyond_thickburger', 'Hardee''s Beyond Thickburger', 260.0, 9.3, 18.7, 14.3, 2.0, 3.0, 300, 300, 'hardees.com', ARRAY['hardees beyond burger', 'hardees plant based burger'], '780 cal per burger (~300g)'),
('hardees_hash_rounds', 'Hardee''s Hash Rounds (Medium)', 340.0, 3.0, 34.0, 20.0, 3.0, 0.0, 100, 100, 'hardees.com', ARRAY['hardees hash rounds', 'hardees hash browns'], '340 cal per medium (~100g)'),
('hardees_grits', 'Hardee''s Grits', 50.0, 2.0, 10.0, 0.5, 0.5, 0.0, 200, 200, 'hardees.com', ARRAY['hardees grits'], '100 cal per serving (~200g)'),
('hardees_low_carb_breakfast_bowl', 'Hardee''s Low Carb Breakfast Bowl', 304.0, 17.2, 3.6, 24.0, 0.4, 1.2, 250, 250, 'hardees.com', ARRAY['hardees breakfast bowl', 'hardees low carb bowl'], '760 cal per bowl (~250g)'),
-- =============================================
-- BATCH 5: Restaurant Nutrition Data
-- Culver's, Firehouse Subs, Shake Shack, In-N-Out Burger,
-- Noodles & Company, Waffle House, Crumbl Cookies,
-- Tropical Smoothie Cafe, Portillo's, Steak 'n Shake
-- Sources: fastfoodnutrition.org, nutritionix.com, official restaurant sites
-- Column order: cal/100g, protein/100g, carbs/100g, fat/100g, fiber/100g, sugar/100g
-- =============================================
-- =============================================
-- 1. CULVER'S (culvers.com)
-- =============================================
-- ButterBurger Single: 390cal, 20g pro, 38g carb, 17g fat, 1g fib, 6g sug, 132g
-- Cheese ButterBurger Single: 460cal, 24g pro, 39g carb, 23g fat, 1g fib, 7g sug, ~155g
-- Deluxe ButterBurger Single: 580cal, 24g pro, 41g carb, 34g fat, 1g fib, 7g sug, ~220g
-- Double ButterBurger: 560cal, 34g pro, 38g carb, 30g fat, 1g fib, 6g sug, ~200g
-- Mushroom & Swiss Single: 530cal, 27g pro, 41g carb, 28g fat, 2g fib, 6g sug, ~210g
-- Crispy Chicken Sandwich: 690cal, 28g pro, 65g carb, 35g fat, 2g fib, 9g sug, ~230g
-- Grilled Chicken Sandwich: 480cal, 36g pro, 40g carb, 19g fat, 2g fib, 9g sug, ~220g
-- Chicken Tenders 4pc: 520cal, 39g pro, 41g carb, 23g fat, 2g fib, 0g sug, ~200g
-- Cod Sandwich: 600cal, 23g pro, 55g carb, 34g fat, 3g fib, 6g sug, ~230g
-- Wisconsin Cheese Curds Regular: 510cal, 20g pro, 51g carb, 25g fat, 0g fib, 4g sug, ~140g
-- Crinkle Cut Fries Large: 430cal, 5g pro, 62g carb, 18g fat, 4g fib, 0g sug, ~170g
-- Onion Rings Large: 840cal, 10g pro, 98g carb, 46g fat, 8g fib, 9g sug, ~220g
-- Custard 1 Scoop Cake Cone: 330cal, 6g pro, 36g carb, 19g fat, 2g fib, 27g sug, ~120g
-- Shake Large: 1030cal, 21g pro, 103g carb, 62g fat, 5g fib, 93g sug, ~450g
-- Chicken Cashew Salad: 430cal, 41g pro, 17g carb, 23g fat, 6g fib, 5g sug, ~350g
-- Cranberry Bacon Bleu Salad: 390cal, 46g pro, 18g carb, 16g fat, 5g fib, 12g sug, ~350g
-- =============================================
-- 2. FIREHOUSE SUBS (firehousesubs.com)
-- =============================================
-- Hook & Ladder Medium: ~700cal, ~40g pro, ~55g carb, ~35g fat, ~3g fib, ~8g sug, ~230g
-- Cajun Chicken Medium: 700cal, 45g pro, 53g carb, 35g fat, 3g fib, 5g sug, ~230g
-- Meatball Large: 1310cal, 58g pro, 97g carb, 80g fat, 6g fib, 16g sug, ~400g
-- Italian Large: 1410cal, 69g pro, 118g carb, 79g fat, 6g fib, 35g sug, ~400g
-- NY Steamer Medium: ~710cal, 44g pro, 50g carb, 38g fat, 2g fib, 7g sug, ~230g
-- Engineer Large: 1110cal, 68g pro, 101g carb, 54g fat, 9g fib, 15g sug, ~400g
-- Hero Large: 1180cal, 68g pro, 108g carb, 56g fat, 6g fib, 27g sug, ~400g
-- Turkey Medium: ~620cal, 32g pro, 57g carb, 32g fat, 4g fib, 9g sug, ~230g
-- Ham Medium: ~680cal, 34g pro, 68g carb, 33g fat, 4g fib, 20g sug, ~230g
-- Tuna Large: 1540cal, 71g pro, 103g carb, 97g fat, 6g fib, 20g sug, ~400g
-- Chicken Noodle Soup 10oz: 120cal, 8g pro, 18g carb, 2g fat, 1g fib, 3g sug, ~280g
-- Chili 10oz: 300cal, 18g pro, 22g carb, 15g fat, 5g fib, 5g sug, ~280g
-- Broccoli Cheese Soup 10oz: 340cal, 11g pro, 12g carb, 28g fat, 1g fib, 5g sug, ~280g
-- 5-Cheese Mac & Cheese: 380cal, 17g pro, 33g carb, 20g fat, 1g fib, 2g sug, ~170g
-- Brownie: 430cal, 4g pro, 61g carb, 20g fat, 1g fib, 38g sug, ~100g
-- Hook & Ladder Salad: 320cal, 30g pro, 21g carb, 13g fat, 5g fib, 12g sug, ~350g
-- =============================================
-- 3. SHAKE SHACK (shakeshack.com)
-- =============================================
-- Single ShackBurger: 500cal, 29g pro, 26g carb, 30g fat, 0g fib, 6g sug, ~200g
-- Double ShackBurger: 760cal, 51g pro, 27g carb, 48g fat, 0g fib, 6g sug, ~290g
-- Single Cheeseburger: 440cal, 29g pro, 25g carb, 24g fat, 0g fib, 5g sug, ~185g
-- Avocado Bacon Burger Single: 610cal, 36g pro, 28g carb, 39g fat, 2g fib, 5g sug, ~240g
-- SmokeShack Single: 570cal, 31g pro, 28g carb, 34g fat, 1g fib, 6g sug, ~220g
-- Chicken Shack: 550cal, 33g pro, 34g carb, 31g fat, 0g fib, 6g sug, ~220g
-- Chicken Bites 6pc: 300cal, 17g pro, 15g carb, 19g fat, 0g fib, 1g sug, ~120g
-- Shack Dog: 370cal, 14g pro, 25g carb, 24g fat, 0g fib, 4g sug, ~120g
-- Regular Fries: 470cal, 6g pro, 63g carb, 22g fat, 7g fib, 1g sug, ~150g
-- Cheese Fries: 710cal, 12g pro, 64g carb, 44g fat, 7g fib, 1g sug, ~200g
-- Vanilla Shake: 680cal, 18g pro, 72g carb, 36g fat, 0g fib, 71g sug, ~400g
-- Chocolate Shake: 750cal, 16g pro, 76g carb, 45g fat, 0g fib, 69g sug, ~400g
-- Strawberry Shake: 690cal, 17g pro, 77g carb, 35g fat, 0g fib, 75g sug, ~400g
-- Bacon Egg Cheese: 400cal, 23g pro, 25g carb, 23g fat, 2g fib, 5g sug, ~170g
-- =============================================
-- 4. IN-N-OUT BURGER (in-n-out.com)
-- =============================================
-- Hamburger with Onion: 360cal, 16g pro, 37g carb, 16g fat, 2g fib, 8g sug, ~200g
-- Cheeseburger with Onion: 430cal, 20g pro, 39g carb, 21g fat, 2g fib, 8g sug, ~215g
-- Double-Double with Onion: 610cal, 34g pro, 41g carb, 34g fat, 2g fib, 8g sug, ~310g
-- Hamburger Protein Style: 200cal, 12g pro, 8g carb, 14g fat, 2g fib, 5g sug, ~160g
-- Cheeseburger Protein Style: 270cal, 16g pro, 10g carb, 19g fat, 2g fib, 6g sug, ~175g
-- Double-Double Protein Style: 450cal, 30g pro, 12g carb, 32g fat, 2g fib, 6g sug, ~270g
-- Hamburger Animal Style: ~480cal, 18g pro, 42g carb, 27g fat, 2g fib, 10g sug, ~240g
-- Double-Double Animal Style: ~770cal, 38g pro, 43g carb, 50g fat, 2g fib, 10g sug, ~360g
-- 3x3: ~830cal, 49g pro, 42g carb, 52g fat, 2g fib, 8g sug, ~400g
-- 4x4: ~1020cal, 63g pro, 43g carb, 68g fat, 2g fib, 9g sug, ~500g
-- French Fries: 360cal, 6g pro, 49g carb, 15g fat, 6g fib, 0g sug, ~125g
-- Animal Style Fries: ~750cal, 19g pro, 52g carb, 52g fat, 6g fib, 5g sug, ~280g
-- Chocolate Shake: 590cal, 16g pro, 66g carb, 30g fat, 0g fib, 55g sug, ~425g
-- Vanilla Shake: 610cal, 15g pro, 69g carb, 31g fat, 0g fib, 63g sug, ~425g
-- Strawberry Shake: 600cal, 15g pro, 74g carb, 30g fat, 0g fib, 62g sug, ~425g
-- =============================================
-- 5. NOODLES & COMPANY (noodles.com)
-- =============================================
-- Wisconsin Mac & Cheese Reg: 981cal, 42g pro, 119g carb, 38g fat, 5g fib, 11g sug, ~400g
-- Japanese Pan Noodles Reg: 641cal, 20g pro, 114g carb, 12g fat, 6g fib, 22g sug, ~400g
-- Pesto Cavatappi Reg: 731cal, 23g pro, 93g carb, 31g fat, 7g fib, 7g sug, ~400g
-- Penne Rosa Reg: 721cal, 23g pro, 103g carb, 24g fat, 5g fib, 10g sug, ~400g
-- Spaghetti & Meatballs Reg: 981cal, 35g pro, 102g carb, 48g fat, 4g fib, 16g sug, ~400g
-- Spicy Korean Beef Noodles Reg: 881cal, 30g pro, 112g carb, 34g fat, 4g fib, 43g sug, ~400g
-- Buttered Egg Noodles Reg: 761cal, 22g pro, 98g carb, 35g fat, 4g fib, 6g sug, ~400g
-- Steak Stroganoff Reg: 1201cal, 45g pro, 116g carb, 67g fat, 7g fib, 14g sug, ~400g
-- Orange Chicken Lo Mein Reg: 841cal, 40g pro, 106g carb, 28g fat, 4g fib, 37g sug, ~400g
-- Alfredo MontAmore w/ Chicken Reg: 1411cal, 52g pro, 110g carb, 84g fat, 6g fib, 14g sug, ~400g
-- 3-Cheese Tortelloni Pesto Reg: 790cal, 35g pro, 74g carb, 41g fat, 4g fib, 6g sug, ~400g
-- BBQ Pork Mac Reg: 1211cal, 64g pro, 129g carb, 47g fat, 5g fib, 18g sug, ~400g
-- Potstickers Reg: 380cal, 16g pro, 54g carb, 10g fat, 2g fib, 14g sug, ~200g
-- Cheesy Garlic Bread Reg: 701cal, 22g pro, 81g carb, 33g fat, 4g fib, 3g sug, ~200g
-- Chicken Noodle Soup Reg: 360cal, 30g pro, 41g carb, 10g fat, 2g fib, 9g sug, ~400g
-- Tomato Basil Bisque Reg: ~430cal, 8g pro, 38g carb, 28g fat, 3g fib, 15g sug, ~400g
-- Caesar Chicken Salad Reg: 420cal, 28g pro, 18g carb, 27g fat, 3g fib, 4g sug, ~300g
-- =============================================
-- 6. WAFFLE HOUSE (wafflehouse.com)
-- =============================================
-- Classic Waffle: 410cal, 8g pro, 55g carb, 18g fat, 2g fib, 15g sug, ~120g
-- Pecan Waffle: ~480cal, 10g pro, 58g carb, 24g fat, 3g fib, 16g sug, ~135g
-- Chocolate Chip Waffle: ~530cal, 9g pro, 72g carb, 24g fat, 3g fib, 30g sug, ~140g
-- 2 Scrambled Eggs: 180cal, 13g pro, 1g carb, 14g fat, 0g fib, 1g sug, ~100g
-- Bacon: 140cal, 8g pro, 0g carb, 12g fat, 0g fib, 0g sug, ~25g
-- Sausage Patty: 260cal, 15g pro, 0g carb, 22g fat, 0g fib, 0g sug, ~60g
-- Hashbrowns Regular: 190cal, 3g pro, 29g carb, 7g fat, 3g fib, 0g sug, ~100g
-- Hashbrowns SMC: 255cal, 6g pro, 32g carb, 11g fat, 3g fib, 1g sug, ~130g
-- Sausage Egg Cheese Bowl: 921cal, 27g pro, 63g carb, 60g fat, 5g fib, 4g sug, ~350g
-- Bacon Egg Cheese Sandwich: 410cal, 21g pro, 27g carb, 25g fat, 1g fib, 4g sug, ~160g
-- Texas Angus Patty Melt: 730cal, 26g pro, 42g carb, 50g fat, 3g fib, 6g sug, ~250g
-- Original Angus Hamburger: 466cal, 22g pro, 33g carb, 26g fat, 2g fib, 6g sug, ~200g
-- Double Cheeseburger Deluxe: 891cal, 46g pro, 48g carb, 56g fat, 3g fib, 8g sug, ~350g
-- Grits: 90cal, 1g pro, 16g carb, 3g fat, 1g fib, 0g sug, ~150g
-- Grilled Biscuit: 380cal, 5g pro, 34g carb, 25g fat, 1g fib, 1g sug, ~80g
-- Sirloin Dinner: 616cal, 29g pro, 55g carb, 30g fat, 6g fib, 7g sug, ~350g
-- T-Bone Dinner: 726cal, 35g pro, 55g carb, 42g fat, 6g fib, 7g sug, ~400g
-- =============================================
-- 7. CRUMBL COOKIES (crumblcookies.com)
-- =============================================
-- Classic Pink Sugar: 760cal, 8g pro, 120g carb, 28g fat, 0g fib, 76g sug, ~176g
-- Milk Chocolate Chip: 680cal, 12g pro, 96g carb, 32g fat, 4g fib, 52g sug, ~156g
-- Cookies & Cream: ~740cal, 8g pro, 104g carb, 32g fat, 2g fib, 64g sug, ~170g
-- Snickerdoodle: ~680cal, 8g pro, 100g carb, 28g fat, 0g fib, 56g sug, ~160g
-- Peanut Butter: ~720cal, 16g pro, 84g carb, 36g fat, 4g fib, 52g sug, ~165g
-- Churro: ~700cal, 8g pro, 104g carb, 28g fat, 2g fib, 60g sug, ~165g
-- Lemon Glaze: ~700cal, 6g pro, 108g carb, 26g fat, 0g fib, 68g sug, ~170g
-- Cinnamon Fry Bread: ~720cal, 8g pro, 100g carb, 32g fat, 2g fib, 52g sug, ~170g
-- Semi-Sweet Chocolate Chunk: ~720cal, 10g pro, 96g carb, 34g fat, 4g fib, 56g sug, ~165g
-- Confetti Cake: ~740cal, 8g pro, 108g carb, 30g fat, 0g fib, 72g sug, ~175g
-- =============================================
-- 8. TROPICAL SMOOTHIE CAFE (tropicalsmoothiecafe.com)
-- =============================================
-- Detox Island Green 24oz: 190cal, 3g pro, 43g carb, 0g fat, 5g fib, 29g sug, ~680g
-- Island Green 24oz: 420cal, 3g pro, 102g carb, 0g fat, 4g fib, 88g sug, ~680g
-- Bahama Mama 24oz: 510cal, 2g pro, 115g carb, 4.5g fat, 3g fib, 109g sug, ~680g
-- Acai Berry Boost 24oz: 470cal, 1g pro, 113g carb, 2g fat, 5g fib, 101g sug, ~680g
-- Peanut Butter Cup 24oz: 700cal, 10g pro, 131g carb, 18g fat, 7g fib, 108g sug, ~680g
-- Mango Magic 24oz: 430cal, 3g pro, 103g carb, 0g fat, 2g fib, 94g sug, ~680g
-- Mocha Madness 24oz: 620cal, 6g pro, 143g carb, 5g fat, 3g fib, 118g sug, ~680g
-- Blueberry Bliss 24oz: 340cal, 1g pro, 85g carb, 0.5g fat, 4g fib, 75g sug, ~680g
-- Chia Banana Boost 24oz: 770cal, 15g pro, 128g carb, 26g fat, 15g fib, 91g sug, ~680g
-- Acai Bowl: 530cal, 4g pro, 100g carb, 17g fat, 11g fib, 55g sug, ~400g
-- PB Protein Crunch Bowl: 800cal, 32g pro, 71g carb, 45g fat, 9g fib, 39g sug, ~400g
-- Dragon Fruit Bowl: 350cal, 4g pro, 77g carb, 5g fat, 5g fib, 48g sug, ~350g
-- Baja Chicken Wrap: 760cal, 38g pro, 83g carb, 30g fat, 7g fib, 8g sug, ~250g
-- Buffalo Chicken Wrap: 620cal, 33g pro, 59g carb, 27g fat, 3g fib, 7g sug, ~250g
-- Thai Chicken Wrap: 600cal, 31g pro, 77g carb, 19g fat, 3g fib, 15g sug, ~250g
-- Caesar Wrap: 750cal, 43g pro, 55g carb, 39g fat, 3g fib, 5g sug, ~250g
-- Hummus Veggie Wrap: 830cal, 23g pro, 95g carb, 41g fat, 11g fib, 11g sug, ~250g
-- Chicken Bacon Ranch Flatbread: 510cal, 28g pro, 47g carb, 23g fat, 3g fib, 3g sug, ~230g
-- Chicken Pesto Flatbread: 490cal, 26g pro, 46g carb, 22g fat, 3g fib, 4g sug, ~230g
-- Chipotle Chicken Club Flatbread: 520cal, 27g pro, 46g carb, 25g fat, 3g fib, 2g sug, ~230g
-- =============================================
-- 9. PORTILLO'S (portillos.com)
-- =============================================
-- Italian Beef: 690cal, 33g pro, 59g carb, 34g fat, 0g fib, 2g sug, ~250g
-- Big Beef: 1040cal, 50g pro, 88g carb, 51g fat, 0g fib, 3g sug, ~380g
-- Beef & Sausage Combo: 860cal, 38g pro, 63g carb, 49g fat, 0g fib, 5g sug, ~300g
-- Hot Dog with Everything: 340cal, 12g pro, 39g carb, 15g fat, 2g fib, 13g sug, ~150g
-- Jumbo Hot Dog: 450cal, 18g pro, 40g carb, 25g fat, 2g fib, 14g sug, ~180g
-- Chili Cheese Dog: 510cal, 22g pro, 36g carb, 31g fat, 2g fib, 5g sug, ~180g
-- Single Hamburger: 590cal, 35g pro, 50g carb, 27g fat, 3g fib, 8g sug, ~230g
-- Double Hamburger: 920cal, 62g pro, 50g carb, 51g fat, 3g fib, 8g sug, ~350g
-- Single Bacon Burger: 700cal, 42g pro, 46g carb, 37g fat, 2g fib, 6g sug, ~250g
-- Famous Chocolate Cake: 720cal, 6g pro, 86g carb, 37g fat, 4g fib, 64g sug, ~200g
-- Chocolate Eclair Cake: 520cal, 6g pro, 83g carb, 18g fat, 4g fib, 51g sug, ~200g
-- Small Fries: 340cal, 3g pro, 43g carb, 19g fat, 4g fib, 2g sug, ~120g
-- Large Fries: 480cal, 5g pro, 61g carb, 27g fat, 5g fib, 3g sug, ~170g
-- Chopped Salad: 510cal, 42g pro, 37g carb, 20g fat, 6g fib, 8g sug, ~350g
-- =============================================
-- 10. STEAK 'N SHAKE (steaknshake.com)
-- DO NOT DUPLICATE: steak_n_shake_cheese_fries, steak_n_shake_chicken_fingers_3pc,
--                    steak_n_shake_side_cheese_sauce, steak_n_shake_garlic_double
-- =============================================
-- Single with Cheese: 390cal, 19g pro, 32g carb, 20g fat, 3g fib, 6g sug, ~170g
-- Original Double: 460cal, 23g pro, 33g carb, 26g fat, 2g fib, 6g sug, ~210g
-- Triple with Cheese: 750cal, 40g pro, 32g carb, 50g fat, 3g fib, 6g sug, ~290g
-- Bacon N Cheese Single: 460cal, 25g pro, 29g carb, 26g fat, 1g fib, 4g sug, ~180g
-- Bacon N Cheese Double: 600cal, 34g pro, 29g carb, 38g fat, 1g fib, 4g sug, ~230g
-- Western BBQ N Bacon: 790cal, 35g pro, 54g carb, 43g fat, 1g fib, 23g sug, ~270g
-- Small French Fries: 240cal, 2g pro, 30g carb, 13g fat, 3g fib, 0g sug, ~90g
-- Medium French Fries: 450cal, 4g pro, 54g carb, 24g fat, 5g fib, 1g sug, ~160g
-- Onion Rings Medium: 330cal, 4g pro, 39g carb, 17g fat, 2g fib, 3g sug, ~120g
-- Chicken Fingers 5pc: 550cal, 35g pro, 37g carb, 30g fat, 3g fib, 0g sug, ~200g
-- Chili Cheese Frank: 710cal, 33g pro, 46g carb, 44g fat, 4g fib, 5g sug, ~200g
-- Chili 3-Way: 710cal, 31g pro, 98g carb, 21g fat, 13g fib, 10g sug, ~350g
-- Grilled Cheese N Bacon: 590cal, 24g pro, 41g carb, 35g fat, 2g fib, 2g sug, ~180g
-- Vanilla Shake Regular: 620cal, 37g pro, 105g carb, 17g fat, 0g fib, 93g sug, ~450g
-- Chocolate Shake Regular: 600cal, 38g pro, 101g carb, 17g fat, 1g fib, 84g sug, ~450g
-- Strawberry Shake Regular: 610cal, 37g pro, 103g carb, 17g fat, 0g fib, 94g sug, ~450g
-- Reese's PB Shake Regular: 900cal, 47g pro, 98g carb, 47g fat, 3g fib, 83g sug, ~500g
-- Oreo Shake Regular: 730cal, 38g pro, 122g carb, 22g fat, 0g fib, 102g sug, ~500g
('culvers_butterburger_single', 'Culver''s ButterBurger Single', 295.5, 15.2, 28.8, 12.9, 0.8, 4.5, 132, 132, 'culvers.com', ARRAY['culvers original butterburger', 'culvers single burger'], '390 cal per 132g burger'),
('culvers_butterburger_cheese_single', 'Culver''s ButterBurger Cheese Single', 296.8, 15.5, 25.2, 14.8, 0.6, 4.5, 155, 155, 'culvers.com', ARRAY['culvers cheese butterburger', 'culvers cheeseburger'], '460 cal per ~155g burger'),
('culvers_deluxe_butterburger_single', 'Culver''s Deluxe ButterBurger Single', 263.6, 10.9, 18.6, 15.5, 0.5, 3.2, 220, 220, 'culvers.com', ARRAY['culvers deluxe', 'culvers deluxe single'], '580 cal per ~220g burger'),
('culvers_butterburger_double', 'Culver''s ButterBurger Double', 280.0, 17.0, 19.0, 15.0, 0.5, 3.0, 200, 200, 'culvers.com', ARRAY['culvers double butterburger', 'culvers double burger'], '560 cal per ~200g burger'),
('culvers_mushroom_swiss_single', 'Culver''s Mushroom & Swiss ButterBurger Single', 252.4, 12.9, 19.5, 13.3, 1.0, 2.9, 210, 210, 'culvers.com', ARRAY['culvers mushroom swiss', 'culvers mushroom burger'], '530 cal per ~210g burger'),
('culvers_crispy_chicken_sandwich', 'Culver''s Crispy Chicken Sandwich', 300.0, 12.2, 28.3, 15.2, 0.9, 3.9, 230, 230, 'culvers.com', ARRAY['culvers chicken sandwich', 'culvers fried chicken sandwich'], '690 cal per ~230g sandwich'),
('culvers_grilled_chicken_sandwich', 'Culver''s Grilled Chicken Sandwich', 218.2, 16.4, 18.2, 8.6, 0.9, 4.1, 220, 220, 'culvers.com', ARRAY['culvers grilled chicken'], '480 cal per ~220g sandwich'),
('culvers_chicken_tenders_4pc', 'Culver''s Chicken Tenders (4 piece)', 260.0, 19.5, 20.5, 11.5, 1.0, 0.0, 200, 200, 'culvers.com', ARRAY['culvers chicken tenders', 'culvers chicken strips'], '520 cal per 4-piece serving'),
('culvers_cod_sandwich', 'Culver''s North Atlantic Cod Sandwich', 260.9, 10.0, 23.9, 14.8, 1.3, 2.6, 230, 230, 'culvers.com', ARRAY['culvers fish sandwich', 'culvers cod sandwich'], '600 cal per ~230g sandwich'),
('culvers_cheese_curds_regular', 'Culver''s Wisconsin Cheese Curds (Regular)', 364.3, 14.3, 36.4, 17.9, 0.0, 2.9, 140, 140, 'culvers.com', ARRAY['culvers cheese curds', 'culvers curds'], '510 cal per regular serving (~140g)'),
('culvers_fries_large', 'Culver''s Crinkle Cut Fries (Large)', 252.9, 2.9, 36.5, 10.6, 2.4, 0.0, 170, 170, 'culvers.com', ARRAY['culvers fries', 'culvers french fries'], '430 cal per large serving (~170g)'),
('culvers_onion_rings', 'Culver''s Onion Rings (Large)', 381.8, 4.5, 44.5, 20.9, 3.6, 4.1, 220, 220, 'culvers.com', ARRAY['culvers onion rings'], '840 cal per large serving (~220g)'),
('culvers_custard_1_scoop', 'Culver''s Frozen Custard (1 Scoop Cake Cone)', 275.0, 5.0, 30.0, 15.8, 1.7, 22.5, 120, 120, 'culvers.com', ARRAY['culvers custard', 'culvers ice cream', 'culvers frozen custard'], '330 cal per 1-scoop cone (~120g)'),
('culvers_shake_large', 'Culver''s Shake (Large)', 228.9, 4.7, 22.9, 13.8, 1.1, 20.7, 450, 450, 'culvers.com', ARRAY['culvers milkshake', 'culvers shake'], '1030 cal per large shake (~450g)'),
('culvers_chicken_cashew_salad', 'Culver''s Chicken Cashew Salad', 122.9, 11.7, 4.9, 6.6, 1.7, 1.4, 350, 350, 'culvers.com', ARRAY['culvers cashew chicken salad'], '430 cal per salad (~350g)'),
('culvers_cranberry_bacon_bleu_salad', 'Culver''s Cranberry Bacon Bleu Salad', 111.4, 13.1, 5.1, 4.6, 1.4, 3.4, 350, 350, 'culvers.com', ARRAY['culvers cranberry salad', 'culvers bleu salad'], '390 cal per salad (~350g)'),
('firehouse_hook_ladder_medium', 'Firehouse Subs Hook & Ladder (Medium)', 304.3, 17.4, 23.9, 15.2, 1.3, 3.5, 230, 230, 'firehousesubs.com', ARRAY['firehouse hook and ladder', 'firehouse hook ladder'], '~700 cal per medium sub (~230g)'),
('firehouse_cajun_chicken_medium', 'Firehouse Subs Cajun Chicken (Medium)', 304.3, 19.6, 23.0, 15.2, 1.3, 2.2, 230, 230, 'firehousesubs.com', ARRAY['firehouse cajun chicken'], '700 cal per medium sub (~230g)'),
('firehouse_meatball_large', 'Firehouse Subs Meatball (Large)', 327.5, 14.5, 24.3, 20.0, 1.5, 4.0, 400, 400, 'firehousesubs.com', ARRAY['firehouse meatball sub', 'firehouse meatball'], '1310 cal per large sub (~400g)'),
('firehouse_italian_large', 'Firehouse Subs Italian (Large)', 352.5, 17.3, 29.5, 19.8, 1.5, 8.8, 400, 400, 'firehousesubs.com', ARRAY['firehouse italian sub', 'firehouse italian'], '1410 cal per large sub (~400g)'),
('firehouse_ny_steamer_medium', 'Firehouse Subs New York Steamer (Medium)', 308.7, 19.1, 21.7, 16.5, 0.9, 3.0, 230, 230, 'firehousesubs.com', ARRAY['firehouse new york steamer', 'firehouse ny steamer'], '~710 cal per medium sub (~230g)'),
('firehouse_engineer_large', 'Firehouse Subs Engineer (Large)', 277.5, 17.0, 25.3, 13.5, 2.3, 3.8, 400, 400, 'firehousesubs.com', ARRAY['firehouse engineer sub', 'firehouse engineer'], '1110 cal per large sub (~400g)'),
('firehouse_hero_large', 'Firehouse Subs Hero (Large)', 295.0, 17.0, 27.0, 14.0, 1.5, 6.8, 400, 400, 'firehousesubs.com', ARRAY['firehouse hero sub', 'firehouse hero'], '1180 cal per large sub (~400g)'),
('firehouse_turkey_medium', 'Firehouse Subs Turkey (Medium)', 269.6, 13.9, 24.8, 13.9, 1.7, 3.9, 230, 230, 'firehousesubs.com', ARRAY['firehouse turkey sub', 'firehouse turkey'], '~620 cal per medium sub (~230g)'),
('firehouse_ham_medium', 'Firehouse Subs Ham (Medium)', 295.7, 14.8, 29.6, 14.3, 1.7, 8.7, 230, 230, 'firehousesubs.com', ARRAY['firehouse ham sub', 'firehouse ham'], '~680 cal per medium sub (~230g)'),
('firehouse_tuna_large', 'Firehouse Subs Tuna (Large)', 385.0, 17.8, 25.8, 24.3, 1.5, 5.0, 400, 400, 'firehousesubs.com', ARRAY['firehouse tuna sub', 'firehouse tuna'], '1540 cal per large sub (~400g)'),
('firehouse_chicken_noodle_soup', 'Firehouse Subs Chicken Noodle Soup', 42.9, 2.9, 6.4, 0.7, 0.4, 1.1, 280, 280, 'firehousesubs.com', ARRAY['firehouse chicken noodle'], '120 cal per 10oz bowl (~280g)'),
('firehouse_chili', 'Firehouse Subs Chili', 107.1, 6.4, 7.9, 5.4, 1.8, 1.8, 280, 280, 'firehousesubs.com', ARRAY['firehouse chili'], '300 cal per 10oz bowl (~280g)'),
('firehouse_broccoli_cheese_soup', 'Firehouse Subs Broccoli & Cheese Soup', 121.4, 3.9, 4.3, 10.0, 0.4, 1.8, 280, 280, 'firehousesubs.com', ARRAY['firehouse broccoli cheese'], '340 cal per 10oz bowl (~280g)'),
('firehouse_mac_cheese', 'Firehouse Subs 5-Cheese Mac & Cheese', 223.5, 10.0, 19.4, 11.8, 0.6, 1.2, 170, 170, 'firehousesubs.com', ARRAY['firehouse mac and cheese', 'firehouse mac cheese'], '380 cal per side (~170g)'),
('firehouse_brownie', 'Firehouse Subs Brownie', 430.0, 4.0, 61.0, 20.0, 1.0, 38.0, 100, 100, 'firehousesubs.com', ARRAY['firehouse brownie'], '430 cal per brownie (~100g)'),
('firehouse_hook_ladder_salad', 'Firehouse Subs Hook & Ladder Salad', 91.4, 8.6, 6.0, 3.7, 1.4, 3.4, 350, 350, 'firehousesubs.com', ARRAY['firehouse salad'], '320 cal per salad (~350g)'),
('shake_shack_shackburger_single', 'Shake Shack ShackBurger (Single)', 250.0, 14.5, 13.0, 15.0, 0.0, 3.0, 200, 200, 'shakeshack.com', ARRAY['shake shack burger', 'shack burger', 'shackburger'], '500 cal per single burger (~200g)'),
('shake_shack_shackburger_double', 'Shake Shack ShackBurger (Double)', 262.1, 17.6, 9.3, 16.6, 0.0, 2.1, 290, 290, 'shakeshack.com', ARRAY['shake shack double', 'double shackburger'], '760 cal per double burger (~290g)'),
('shake_shack_cheeseburger_single', 'Shake Shack Cheeseburger (Single)', 237.8, 15.7, 13.5, 13.0, 0.0, 2.7, 185, 185, 'shakeshack.com', ARRAY['shake shack cheese burger', 'shake shack single cheeseburger'], '440 cal per single cheeseburger (~185g)'),
('shake_shack_avocado_bacon_burger', 'Shake Shack Avocado Bacon Burger (Single)', 254.2, 15.0, 11.7, 16.3, 0.8, 2.1, 240, 240, 'shakeshack.com', ARRAY['shake shack avocado burger', 'shake shack bacon avocado'], '610 cal per burger (~240g)'),
('shake_shack_smokeshack', 'Shake Shack SmokeShack (Single)', 259.1, 14.1, 12.7, 15.5, 0.5, 2.7, 220, 220, 'shakeshack.com', ARRAY['smokeshack', 'shake shack smokeshack'], '570 cal per burger (~220g)'),
('shake_shack_chicken_shack', 'Shake Shack Chicken Shack', 250.0, 15.0, 15.5, 14.1, 0.0, 2.7, 220, 220, 'shakeshack.com', ARRAY['shake shack chicken sandwich', 'chicken shack'], '550 cal per sandwich (~220g)'),
('shake_shack_chicken_bites_6pc', 'Shake Shack Chicken Bites (6 Piece)', 250.0, 14.2, 12.5, 15.8, 0.0, 0.8, 120, 120, 'shakeshack.com', ARRAY['shake shack chicken bites', 'shake shack nuggets'], '300 cal per 6-piece (~120g)'),
('shake_shack_hot_dog', 'Shake Shack Shack Dog', 308.3, 11.7, 20.8, 20.0, 0.0, 3.3, 120, 120, 'shakeshack.com', ARRAY['shake shack hot dog', 'shack dog'], '370 cal per hot dog (~120g)'),
('shake_shack_fries', 'Shake Shack Fries', 313.3, 4.0, 42.0, 14.7, 4.7, 0.7, 150, 150, 'shakeshack.com', ARRAY['shake shack french fries', 'shake shack crinkle fries'], '470 cal per regular order (~150g)'),
('shake_shack_cheese_fries', 'Shake Shack Cheese Fries', 355.0, 6.0, 32.0, 22.0, 3.5, 0.5, 200, 200, 'shakeshack.com', ARRAY['shake shack cheese fries'], '710 cal per order (~200g)'),
('shake_shack_vanilla_shake', 'Shake Shack Vanilla Shake', 170.0, 4.5, 18.0, 9.0, 0.0, 17.8, 400, 400, 'shakeshack.com', ARRAY['shake shack vanilla milkshake'], '680 cal per shake (~400g)'),
('shake_shack_chocolate_shake', 'Shake Shack Chocolate Shake', 187.5, 4.0, 19.0, 11.3, 0.0, 17.3, 400, 400, 'shakeshack.com', ARRAY['shake shack chocolate milkshake'], '750 cal per shake (~400g)'),
('shake_shack_strawberry_shake', 'Shake Shack Strawberry Shake', 172.5, 4.3, 19.3, 8.8, 0.0, 18.8, 400, 400, 'shakeshack.com', ARRAY['shake shack strawberry milkshake'], '690 cal per shake (~400g)'),
('shake_shack_bacon_egg_cheese', 'Shake Shack Bacon Egg & Cheese Sandwich', 235.3, 13.5, 14.7, 13.5, 1.2, 2.9, 170, 170, 'shakeshack.com', ARRAY['shake shack breakfast sandwich', 'shake shack bec'], '400 cal per sandwich (~170g)'),
('in_n_out_hamburger', 'In-N-Out Hamburger', 180.0, 8.0, 18.5, 8.0, 1.0, 4.0, 200, 200, 'in-n-out.com', ARRAY['in n out hamburger', 'in n out burger', 'innout burger'], '360 cal per burger (~200g)'),
('in_n_out_cheeseburger', 'In-N-Out Cheeseburger', 200.0, 9.3, 18.1, 9.8, 0.9, 3.7, 215, 215, 'in-n-out.com', ARRAY['in n out cheeseburger', 'innout cheeseburger'], '430 cal per burger (~215g)'),
('in_n_out_double_double', 'In-N-Out Double-Double', 196.8, 11.0, 13.2, 11.0, 0.6, 2.6, 310, 310, 'in-n-out.com', ARRAY['in n out double double', 'innout double double', 'double double'], '610 cal per burger (~310g)'),
('in_n_out_hamburger_protein_style', 'In-N-Out Hamburger Protein Style', 125.0, 7.5, 5.0, 8.8, 1.3, 3.1, 160, 160, 'in-n-out.com', ARRAY['in n out protein style', 'innout lettuce wrap burger'], '200 cal per burger wrapped in lettuce (~160g)'),
('in_n_out_cheeseburger_protein_style', 'In-N-Out Cheeseburger Protein Style', 154.3, 9.1, 5.7, 10.9, 1.1, 3.4, 175, 175, 'in-n-out.com', ARRAY['in n out cheese protein style', 'innout cheese protein style'], '270 cal per burger wrapped in lettuce (~175g)'),
('in_n_out_double_double_protein_style', 'In-N-Out Double-Double Protein Style', 166.7, 11.1, 4.4, 11.9, 0.7, 2.2, 270, 270, 'in-n-out.com', ARRAY['in n out double double protein style', 'innout double double lettuce wrap'], '450 cal per burger wrapped in lettuce (~270g)'),
('in_n_out_hamburger_animal_style', 'In-N-Out Hamburger Animal Style', 200.0, 7.5, 17.5, 11.3, 0.8, 4.2, 240, 240, 'in-n-out.com', ARRAY['in n out animal style', 'innout animal style burger'], '~480 cal per animal style burger (~240g)'),
('in_n_out_double_double_animal_style', 'In-N-Out Double-Double Animal Style', 213.9, 10.6, 11.9, 13.9, 0.6, 2.8, 360, 360, 'in-n-out.com', ARRAY['in n out double double animal style', 'innout double double animal'], '~770 cal per animal style double-double (~360g)'),
('in_n_out_3x3', 'In-N-Out 3x3', 207.5, 12.3, 10.5, 13.0, 0.5, 2.0, 400, 400, 'in-n-out.com', ARRAY['in n out 3x3', 'innout triple triple', 'in n out 3 by 3'], '~830 cal per 3x3 burger (~400g)'),
('in_n_out_4x4', 'In-N-Out 4x4', 204.0, 12.6, 8.6, 13.6, 0.4, 1.8, 500, 500, 'in-n-out.com', ARRAY['in n out 4x4', 'innout quad quad', 'in n out 4 by 4'], '~1020 cal per 4x4 burger (~500g)'),
('in_n_out_fries', 'In-N-Out French Fries', 288.0, 4.8, 39.2, 12.0, 4.8, 0.0, 125, 125, 'in-n-out.com', ARRAY['in n out fries', 'innout fries', 'in n out french fries'], '360 cal per order (~125g)'),
('in_n_out_animal_fries', 'In-N-Out Animal Style Fries', 267.9, 6.8, 18.6, 18.6, 2.1, 1.8, 280, 280, 'in-n-out.com', ARRAY['in n out animal fries', 'innout animal fries'], '~750 cal per order (~280g)'),
('in_n_out_chocolate_shake', 'In-N-Out Chocolate Shake', 138.8, 3.8, 15.5, 7.1, 0.0, 12.9, 425, 425, 'in-n-out.com', ARRAY['in n out chocolate shake', 'innout chocolate milkshake'], '590 cal per shake (~425g)'),
('in_n_out_vanilla_shake', 'In-N-Out Vanilla Shake', 143.5, 3.5, 16.2, 7.3, 0.0, 14.8, 425, 425, 'in-n-out.com', ARRAY['in n out vanilla shake', 'innout vanilla milkshake'], '610 cal per shake (~425g)'),
('in_n_out_strawberry_shake', 'In-N-Out Strawberry Shake', 141.2, 3.5, 17.4, 7.1, 0.0, 14.6, 425, 425, 'in-n-out.com', ARRAY['in n out strawberry shake', 'innout strawberry milkshake'], '600 cal per shake (~425g)'),
('noodles_co_wisconsin_mac_cheese', 'Noodles & Company Wisconsin Mac & Cheese (Regular)', 245.3, 10.5, 29.8, 9.5, 1.3, 2.8, 400, 400, 'noodles.com', ARRAY['noodles company mac and cheese', 'noodles co mac cheese'], '981 cal per regular bowl (~400g)'),
('noodles_co_japanese_pan_noodles', 'Noodles & Company Japanese Pan Noodles (Regular)', 160.3, 5.0, 28.5, 3.0, 1.5, 5.5, 400, 400, 'noodles.com', ARRAY['noodles company japanese pan noodles', 'noodles co pan noodles'], '641 cal per regular bowl (~400g)'),
('noodles_co_pesto_cavatappi', 'Noodles & Company Pesto Cavatappi (Regular)', 182.8, 5.8, 23.3, 7.8, 1.8, 1.8, 400, 400, 'noodles.com', ARRAY['noodles company pesto cavatappi', 'noodles co pesto pasta'], '731 cal per regular bowl (~400g)'),
('noodles_co_penne_rosa', 'Noodles & Company Penne Rosa (Regular)', 180.3, 5.8, 25.8, 6.0, 1.3, 2.5, 400, 400, 'noodles.com', ARRAY['noodles company penne rosa', 'noodles co penne rosa'], '721 cal per regular bowl (~400g)'),
('noodles_co_spaghetti_meatballs', 'Noodles & Company Spaghetti & Meatballs (Regular)', 245.3, 8.8, 25.5, 12.0, 1.0, 4.0, 400, 400, 'noodles.com', ARRAY['noodles company spaghetti meatballs', 'noodles co spaghetti'], '981 cal per regular bowl (~400g)'),
('noodles_co_spicy_korean_beef', 'Noodles & Company Spicy Korean Beef Noodles (Regular)', 220.3, 7.5, 28.0, 8.5, 1.0, 10.8, 400, 400, 'noodles.com', ARRAY['noodles company korean beef', 'noodles co spicy korean'], '881 cal per regular bowl (~400g)'),
('noodles_co_buttered_egg_noodles', 'Noodles & Company Buttered Egg Noodles (Regular)', 190.3, 5.5, 24.5, 8.8, 1.0, 1.5, 400, 400, 'noodles.com', ARRAY['noodles company buttered noodles', 'noodles co butter noodles'], '761 cal per regular bowl (~400g)'),
('noodles_co_steak_stroganoff', 'Noodles & Company Steak Stroganoff (Regular)', 300.3, 11.3, 29.0, 16.8, 1.8, 3.5, 400, 400, 'noodles.com', ARRAY['noodles company stroganoff', 'noodles co steak stroganoff'], '1201 cal per regular bowl (~400g)'),
('noodles_co_orange_chicken_lo_mein', 'Noodles & Company Grilled Orange Chicken Lo Mein (Regular)', 210.3, 10.0, 26.5, 7.0, 1.0, 9.3, 400, 400, 'noodles.com', ARRAY['noodles company orange chicken', 'noodles co lo mein'], '841 cal per regular bowl (~400g)'),
('noodles_co_alfredo_montamore_chicken', 'Noodles & Company Alfredo MontAmore with Chicken (Regular)', 352.8, 13.0, 27.5, 21.0, 1.5, 3.5, 400, 400, 'noodles.com', ARRAY['noodles company alfredo chicken', 'noodles co alfredo'], '1411 cal per regular bowl (~400g)'),
('noodles_co_tortelloni_pesto', 'Noodles & Company 3-Cheese Tortelloni Pesto (Regular)', 197.5, 8.8, 18.5, 10.3, 1.0, 1.5, 400, 400, 'noodles.com', ARRAY['noodles company tortelloni', 'noodles co cheese tortelloni'], '790 cal per regular bowl (~400g)'),
('noodles_co_bbq_pork_mac', 'Noodles & Company BBQ Pork Mac & Cheese (Regular)', 302.8, 16.0, 32.3, 11.8, 1.3, 4.5, 400, 400, 'noodles.com', ARRAY['noodles company bbq mac cheese', 'noodles co bbq pork mac'], '1211 cal per regular bowl (~400g)'),
('noodles_co_potstickers', 'Noodles & Company Potstickers (Regular)', 190.0, 8.0, 27.0, 5.0, 1.0, 7.0, 200, 200, 'noodles.com', ARRAY['noodles company potstickers', 'noodles co dumplings'], '380 cal per regular order (~200g)'),
('noodles_co_cheesy_garlic_bread', 'Noodles & Company Cheesy Garlic Bread (Regular)', 350.5, 11.0, 40.5, 16.5, 2.0, 1.5, 200, 200, 'noodles.com', ARRAY['noodles company garlic bread', 'noodles co cheesy bread'], '701 cal per regular order (~200g)'),
('noodles_co_chicken_noodle_soup', 'Noodles & Company Chicken Noodle Soup (Regular)', 90.0, 7.5, 10.3, 2.5, 0.5, 2.3, 400, 400, 'noodles.com', ARRAY['noodles company chicken soup'], '360 cal per regular bowl (~400g)'),
('noodles_co_tomato_bisque', 'Noodles & Company Tomato Basil Bisque (Regular)', 107.5, 2.0, 9.5, 7.0, 0.8, 3.8, 400, 400, 'noodles.com', ARRAY['noodles company tomato soup', 'noodles co tomato bisque'], '~430 cal per regular bowl (~400g)'),
('noodles_co_caesar_chicken_salad', 'Noodles & Company Caesar Chicken Salad (Regular)', 140.0, 9.3, 6.0, 9.0, 1.0, 1.3, 300, 300, 'noodles.com', ARRAY['noodles company caesar salad', 'noodles co chicken caesar'], '420 cal per regular salad (~300g)'),
('waffle_house_classic_waffle', 'Waffle House Classic Waffle', 341.7, 6.7, 45.8, 15.0, 1.7, 12.5, 120, 120, 'wafflehouse.com', ARRAY['waffle house waffle', 'waffle house plain waffle'], '410 cal per waffle (~120g)'),
('waffle_house_pecan_waffle', 'Waffle House Pecan Waffle', 355.6, 7.4, 43.0, 17.8, 2.2, 11.9, 135, 135, 'wafflehouse.com', ARRAY['waffle house pecan waffle'], '~480 cal per waffle (~135g)'),
('waffle_house_chocolate_chip_waffle', 'Waffle House Chocolate Chip Waffle', 378.6, 6.4, 51.4, 17.1, 2.1, 21.4, 140, 140, 'wafflehouse.com', ARRAY['waffle house choc chip waffle'], '~530 cal per waffle (~140g)'),
('waffle_house_2_scrambled_eggs', 'Waffle House 2 Scrambled Eggs', 180.0, 13.0, 1.0, 14.0, 0.0, 1.0, 100, 100, 'wafflehouse.com', ARRAY['waffle house eggs', 'waffle house scrambled eggs'], '180 cal per 2 eggs (~100g)'),
('waffle_house_bacon', 'Waffle House Bacon', 560.0, 32.0, 0.0, 48.0, 0.0, 0.0, 25, 25, 'wafflehouse.com', ARRAY['waffle house bacon'], '140 cal per serving (~25g)'),
('waffle_house_sausage', 'Waffle House Sausage Patty', 433.3, 25.0, 0.0, 36.7, 0.0, 0.0, 60, 60, 'wafflehouse.com', ARRAY['waffle house sausage'], '260 cal per patty (~60g)'),
('waffle_house_hashbrowns', 'Waffle House Hashbrowns', 190.0, 3.0, 29.0, 7.0, 3.0, 0.0, 100, 100, 'wafflehouse.com', ARRAY['waffle house hash browns', 'waffle house scattered hashbrowns'], '190 cal per regular order (~100g)'),
('waffle_house_hashbrowns_smc', 'Waffle House Hashbrowns Scattered Smothered & Covered', 196.2, 4.6, 24.6, 8.5, 2.3, 0.8, 130, 130, 'wafflehouse.com', ARRAY['waffle house smothered covered hashbrowns', 'waffle house hashbrowns smc'], '255 cal per order with onions and cheese (~130g)'),
('waffle_house_sausage_egg_cheese_bowl', 'Waffle House Sausage Egg & Cheese Hashbrown Bowl', 263.1, 7.7, 18.0, 17.1, 1.4, 1.1, 350, 350, 'wafflehouse.com', ARRAY['waffle house sausage bowl', 'waffle house hashbrown bowl'], '921 cal per bowl (~350g)'),
('waffle_house_bacon_egg_cheese_sandwich', 'Waffle House Bacon Egg & Cheese Sandwich', 256.3, 13.1, 16.9, 15.6, 0.6, 2.5, 160, 160, 'wafflehouse.com', ARRAY['waffle house bec sandwich', 'waffle house breakfast sandwich'], '410 cal per sandwich (~160g)'),
('waffle_house_texas_patty_melt', 'Waffle House Texas Angus Patty Melt', 292.0, 10.4, 16.8, 20.0, 1.2, 2.4, 250, 250, 'wafflehouse.com', ARRAY['waffle house patty melt', 'waffle house texas melt'], '730 cal per patty melt (~250g)'),
('waffle_house_hamburger', 'Waffle House Original Angus Hamburger', 233.0, 11.0, 16.5, 13.0, 1.0, 3.0, 200, 200, 'wafflehouse.com', ARRAY['waffle house burger', 'waffle house angus burger'], '466 cal per burger (~200g)'),
('waffle_house_double_cheeseburger', 'Waffle House Double Angus Quarter Pound Cheeseburger Deluxe', 254.6, 13.1, 13.7, 16.0, 0.9, 2.3, 350, 350, 'wafflehouse.com', ARRAY['waffle house double cheeseburger', 'waffle house double burger'], '891 cal per double cheeseburger (~350g)'),
('waffle_house_grits', 'Waffle House Grits', 60.0, 0.7, 10.7, 2.0, 0.7, 0.0, 150, 150, 'wafflehouse.com', ARRAY['waffle house grits'], '90 cal per serving (~150g)'),
('waffle_house_biscuit', 'Waffle House Grilled Biscuit', 475.0, 6.3, 42.5, 31.3, 1.3, 1.3, 80, 80, 'wafflehouse.com', ARRAY['waffle house biscuit'], '380 cal per biscuit (~80g)'),
('waffle_house_sirloin_dinner', 'Waffle House Sirloin Steak Dinner', 176.0, 8.3, 15.7, 8.6, 1.7, 2.0, 350, 350, 'wafflehouse.com', ARRAY['waffle house steak dinner', 'waffle house sirloin'], '616 cal dinner with hashbrowns and toast (~350g)'),
('waffle_house_tbone_dinner', 'Waffle House T-Bone Steak Dinner', 181.5, 8.8, 13.8, 10.5, 1.5, 1.8, 400, 400, 'wafflehouse.com', ARRAY['waffle house t bone dinner', 'waffle house tbone'], '726 cal dinner with hashbrowns and toast (~400g)'),
('crumbl_classic_pink_sugar', 'Crumbl Classic Pink Sugar Cookie', 431.8, 4.5, 68.2, 15.9, 0.0, 43.2, 176, 176, 'crumblcookies.com', ARRAY['crumbl pink sugar', 'crumbl sugar cookie', 'crumbl classic sugar'], '760 cal per whole cookie (~176g)'),
('crumbl_milk_chocolate_chip', 'Crumbl Milk Chocolate Chip Cookie', 435.9, 7.7, 61.5, 20.5, 2.6, 33.3, 156, 156, 'crumblcookies.com', ARRAY['crumbl chocolate chip', 'crumbl choc chip cookie'], '680 cal per whole cookie (~156g)'),
('crumbl_cookies_and_cream', 'Crumbl Cookies & Cream Cookie', 435.3, 4.7, 61.2, 18.8, 1.2, 37.6, 170, 170, 'crumblcookies.com', ARRAY['crumbl oreo cookie', 'crumbl cookies cream'], '~740 cal per whole cookie (~170g)'),
('crumbl_snickerdoodle', 'Crumbl Snickerdoodle Cookie', 425.0, 5.0, 62.5, 17.5, 0.0, 35.0, 160, 160, 'crumblcookies.com', ARRAY['crumbl snickerdoodle'], '~680 cal per whole cookie (~160g)'),
('crumbl_peanut_butter', 'Crumbl Peanut Butter Cookie', 436.4, 9.7, 50.9, 21.8, 2.4, 31.5, 165, 165, 'crumblcookies.com', ARRAY['crumbl pb cookie', 'crumbl peanut butter cookie'], '~720 cal per whole cookie (~165g)'),
('crumbl_churro', 'Crumbl Churro Cookie', 424.2, 4.8, 63.0, 17.0, 1.2, 36.4, 165, 165, 'crumblcookies.com', ARRAY['crumbl churro cookie'], '~700 cal per whole cookie (~165g)'),
('crumbl_lemon_glaze', 'Crumbl Lemon Glaze Cookie', 411.8, 3.5, 63.5, 15.3, 0.0, 40.0, 170, 170, 'crumblcookies.com', ARRAY['crumbl lemon cookie', 'crumbl lemon glaze'], '~700 cal per whole cookie (~170g)'),
('crumbl_cinnamon_fry_bread', 'Crumbl Cinnamon Fry Bread Cookie', 423.5, 4.7, 58.8, 18.8, 1.2, 30.6, 170, 170, 'crumblcookies.com', ARRAY['crumbl cinnamon cookie', 'crumbl fry bread'], '~720 cal per whole cookie (~170g)'),
('crumbl_semi_sweet_chocolate_chunk', 'Crumbl Semi-Sweet Chocolate Chunk Cookie', 436.4, 6.1, 58.2, 20.6, 2.4, 33.9, 165, 165, 'crumblcookies.com', ARRAY['crumbl chocolate chunk', 'crumbl semi sweet'], '~720 cal per whole cookie (~165g)'),
('crumbl_confetti_cake', 'Crumbl Confetti Cake Cookie', 422.9, 4.6, 61.7, 17.1, 0.0, 41.1, 175, 175, 'crumblcookies.com', ARRAY['crumbl confetti cookie', 'crumbl birthday cake cookie', 'crumbl funfetti'], '~740 cal per whole cookie (~175g)'),
('tropical_smoothie_detox_island_green', 'Tropical Smoothie Cafe Detox Island Green', 27.9, 0.4, 6.3, 0.0, 0.7, 4.3, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie detox', 'tropical smoothie island green detox'], '190 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_island_green', 'Tropical Smoothie Cafe Island Green', 61.8, 0.4, 15.0, 0.0, 0.6, 12.9, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie island green regular'], '420 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_bahama_mama', 'Tropical Smoothie Cafe Bahama Mama', 75.0, 0.3, 16.9, 0.7, 0.4, 16.0, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie bahama mama'], '510 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_acai_berry_boost', 'Tropical Smoothie Cafe Acai Berry Boost', 69.1, 0.1, 16.6, 0.3, 0.7, 14.9, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie acai berry', 'tropical smoothie acai'], '470 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_peanut_butter_cup', 'Tropical Smoothie Cafe Peanut Butter Cup', 102.9, 1.5, 19.3, 2.6, 1.0, 15.9, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie pb cup', 'tropical smoothie peanut butter'], '700 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_mango_magic', 'Tropical Smoothie Cafe Mango Magic', 63.2, 0.4, 15.1, 0.0, 0.3, 13.8, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie mango', 'tropical smoothie mango magic'], '430 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_mocha_madness', 'Tropical Smoothie Cafe Mocha Madness', 91.2, 0.9, 21.0, 0.7, 0.4, 17.4, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie mocha', 'tropical smoothie coffee smoothie'], '620 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_blueberry_bliss', 'Tropical Smoothie Cafe Blueberry Bliss', 50.0, 0.1, 12.5, 0.1, 0.6, 11.0, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie blueberry'], '340 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_chia_banana_boost', 'Tropical Smoothie Cafe Chia Banana Boost', 113.2, 2.2, 18.8, 3.8, 2.2, 13.4, 680, 680, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie chia banana', 'tropical smoothie chia'], '770 cal per 24oz smoothie (~680g)'),
('tropical_smoothie_acai_bowl', 'Tropical Smoothie Cafe Acai Bowl', 132.5, 1.0, 25.0, 4.3, 2.8, 13.8, 400, 400, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie acai bowl'], '530 cal per bowl (~400g)'),
('tropical_smoothie_pb_protein_bowl', 'Tropical Smoothie Cafe PB Protein Crunch Bowl', 200.0, 8.0, 17.8, 11.3, 2.3, 9.8, 400, 400, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie protein bowl', 'tropical smoothie peanut butter bowl'], '800 cal per bowl (~400g)'),
('tropical_smoothie_dragon_fruit_bowl', 'Tropical Smoothie Cafe Dragon Fruit Bowl', 100.0, 1.1, 22.0, 1.4, 1.4, 13.7, 350, 350, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie dragon fruit', 'tropical smoothie pitaya bowl'], '350 cal per bowl (~350g)'),
('tropical_smoothie_baja_chicken_wrap', 'Tropical Smoothie Cafe Baja Chicken Wrap', 304.0, 15.2, 33.2, 12.0, 2.8, 3.2, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie baja wrap', 'tropical smoothie baja chicken'], '760 cal per wrap (~250g)'),
('tropical_smoothie_buffalo_chicken_wrap', 'Tropical Smoothie Cafe Buffalo Chicken Wrap', 248.0, 13.2, 23.6, 10.8, 1.2, 2.8, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie buffalo wrap'], '620 cal per wrap (~250g)'),
('tropical_smoothie_thai_chicken_wrap', 'Tropical Smoothie Cafe Thai Chicken Wrap', 240.0, 12.4, 30.8, 7.6, 1.2, 6.0, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie thai wrap', 'tropical smoothie thai chicken'], '600 cal per wrap (~250g)'),
('tropical_smoothie_caesar_wrap', 'Tropical Smoothie Cafe Supergreen Caesar Chicken Wrap', 300.0, 17.2, 22.0, 15.6, 1.2, 2.0, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie caesar wrap', 'tropical smoothie caesar chicken'], '750 cal per wrap (~250g)'),
('tropical_smoothie_hummus_veggie_wrap', 'Tropical Smoothie Cafe Hummus Veggie Wrap', 332.0, 9.2, 38.0, 16.4, 4.4, 4.4, 250, 250, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie veggie wrap', 'tropical smoothie hummus wrap'], '830 cal per wrap (~250g)'),
('tropical_smoothie_chicken_bacon_ranch_flatbread', 'Tropical Smoothie Cafe Chicken Bacon Ranch Flatbread', 221.7, 12.2, 20.4, 10.0, 1.3, 1.3, 230, 230, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie bacon ranch flatbread'], '510 cal per flatbread (~230g)'),
('tropical_smoothie_chicken_pesto_flatbread', 'Tropical Smoothie Cafe Chicken Pesto Flatbread', 213.0, 11.3, 20.0, 9.6, 1.3, 1.7, 230, 230, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie pesto flatbread'], '490 cal per flatbread (~230g)'),
('tropical_smoothie_chipotle_chicken_flatbread', 'Tropical Smoothie Cafe Chipotle Chicken Club Flatbread', 226.1, 11.7, 20.0, 10.9, 1.3, 0.9, 230, 230, 'tropicalsmoothiecafe.com', ARRAY['tropical smoothie chipotle flatbread'], '520 cal per flatbread (~230g)'),
('portillos_italian_beef', 'Portillo''s Italian Beef', 276.0, 13.2, 23.6, 13.6, 0.0, 0.8, 250, 250, 'portillos.com', ARRAY['portillos italian beef sandwich', 'portillos beef'], '690 cal per sandwich (~250g)'),
('portillos_big_beef', 'Portillo''s Big Beef', 273.7, 13.2, 23.2, 13.4, 0.0, 0.8, 380, 380, 'portillos.com', ARRAY['portillos big beef sandwich', 'portillos large italian beef'], '1040 cal per large sandwich (~380g)'),
('portillos_beef_sausage_combo', 'Portillo''s Italian Beef & Sausage Combo', 286.7, 12.7, 21.0, 16.3, 0.0, 1.7, 300, 300, 'portillos.com', ARRAY['portillos combo sandwich', 'portillos beef and sausage'], '860 cal per combo (~300g)'),
('portillos_hot_dog', 'Portillo''s Hot Dog with Everything', 226.7, 8.0, 26.0, 10.0, 1.3, 8.7, 150, 150, 'portillos.com', ARRAY['portillos chicago hot dog', 'portillos hot dog'], '340 cal per hot dog (~150g)'),
('portillos_jumbo_hot_dog', 'Portillo''s Jumbo Hot Dog with Everything', 250.0, 10.0, 22.2, 13.9, 1.1, 7.8, 180, 180, 'portillos.com', ARRAY['portillos jumbo dog', 'portillos jumbo hot dog'], '450 cal per jumbo hot dog (~180g)'),
('portillos_chili_cheese_dog', 'Portillo''s Chili Cheese Dog', 283.3, 12.2, 20.0, 17.2, 1.1, 2.8, 180, 180, 'portillos.com', ARRAY['portillos chili dog', 'portillos chili cheese hot dog'], '510 cal per chili cheese dog (~180g)'),
('portillos_hamburger', 'Portillo''s Single Hamburger', 256.5, 15.2, 21.7, 11.7, 1.3, 3.5, 230, 230, 'portillos.com', ARRAY['portillos burger', 'portillos hamburger'], '590 cal per burger (~230g)'),
('portillos_double_hamburger', 'Portillo''s Double Hamburger', 262.9, 17.7, 14.3, 14.6, 0.9, 2.3, 350, 350, 'portillos.com', ARRAY['portillos double burger'], '920 cal per double burger (~350g)'),
('portillos_bacon_burger', 'Portillo''s Single Bacon Burger', 280.0, 16.8, 18.4, 14.8, 0.8, 2.4, 250, 250, 'portillos.com', ARRAY['portillos bacon cheeseburger', 'portillos bacon burger'], '700 cal per burger (~250g)'),
('portillos_chocolate_cake', 'Portillo''s Famous Chocolate Cake', 360.0, 3.0, 43.0, 18.5, 2.0, 32.0, 200, 200, 'portillos.com', ARRAY['portillos cake', 'portillos chocolate cake slice'], '720 cal per slice (~200g)'),
('portillos_eclair_cake', 'Portillo''s Chocolate Eclair Cake', 260.0, 3.0, 41.5, 9.0, 2.0, 25.5, 200, 200, 'portillos.com', ARRAY['portillos eclair cake', 'portillos eclair'], '520 cal per slice (~200g)'),
('portillos_fries_small', 'Portillo''s French Fries (Small)', 283.3, 2.5, 35.8, 15.8, 3.3, 1.7, 120, 120, 'portillos.com', ARRAY['portillos fries', 'portillos french fries'], '340 cal per small order (~120g)'),
('portillos_fries_large', 'Portillo''s French Fries (Large)', 282.4, 2.9, 35.9, 15.9, 2.9, 1.8, 170, 170, 'portillos.com', ARRAY['portillos large fries'], '480 cal per large order (~170g)'),
('portillos_chopped_salad', 'Portillo''s Chopped Salad', 145.7, 12.0, 10.6, 5.7, 1.7, 2.3, 350, 350, 'portillos.com', ARRAY['portillos salad', 'portillos chopped salad'], '510 cal per salad without dressing (~350g)'),
('steak_n_shake_single_cheese', 'Steak ''n Shake Single Steakburger with Cheese', 229.4, 11.2, 18.8, 11.8, 1.8, 3.5, 170, 170, 'steaknshake.com', ARRAY['steak n shake single cheeseburger', 'steak n shake single with cheese'], '390 cal per single steakburger (~170g)'),
('steak_n_shake_original_double', 'Steak ''n Shake Original Double Steakburger', 219.0, 11.0, 15.7, 12.4, 1.0, 2.9, 210, 210, 'steaknshake.com', ARRAY['steak n shake double steakburger', 'steak n shake double'], '460 cal per double steakburger (~210g)'),
('steak_n_shake_triple_cheese', 'Steak ''n Shake Triple Steakburger with Cheese', 258.6, 13.8, 11.0, 17.2, 1.0, 2.1, 290, 290, 'steaknshake.com', ARRAY['steak n shake triple cheeseburger', 'steak n shake triple'], '750 cal per triple steakburger (~290g)'),
('steak_n_shake_bacon_cheese_single', 'Steak ''n Shake Bacon N Cheese Single Steakburger', 255.6, 13.9, 16.1, 14.4, 0.6, 2.2, 180, 180, 'steaknshake.com', ARRAY['steak n shake bacon cheeseburger', 'steak n shake bacon cheese'], '460 cal per single steakburger (~180g)'),
('steak_n_shake_bacon_cheese_double', 'Steak ''n Shake Bacon N Cheese Double Steakburger', 260.9, 14.8, 12.6, 16.5, 0.4, 1.7, 230, 230, 'steaknshake.com', ARRAY['steak n shake double bacon cheese'], '600 cal per double steakburger (~230g)'),
('steak_n_shake_western_bbq', 'Steak ''n Shake Western BBQ N Bacon Steakburger', 292.6, 13.0, 20.0, 15.9, 0.4, 8.5, 270, 270, 'steaknshake.com', ARRAY['steak n shake western bbq burger', 'steak n shake bbq bacon'], '790 cal per steakburger (~270g)'),
('steak_n_shake_fries_small', 'Steak ''n Shake French Fries (Small)', 266.7, 2.2, 33.3, 14.4, 3.3, 0.0, 90, 90, 'steaknshake.com', ARRAY['steak n shake small fries'], '240 cal per small order (~90g)'),
('steak_n_shake_fries_medium', 'Steak ''n Shake French Fries (Medium)', 281.3, 2.5, 33.8, 15.0, 3.1, 0.6, 160, 160, 'steaknshake.com', ARRAY['steak n shake medium fries', 'steak n shake fries'], '450 cal per medium order (~160g)'),
('steak_n_shake_onion_rings', 'Steak ''n Shake Onion Rings (Medium)', 275.0, 3.3, 32.5, 14.2, 1.7, 2.5, 120, 120, 'steaknshake.com', ARRAY['steak n shake onion rings'], '330 cal per medium order (~120g)'),
('steak_n_shake_chicken_fingers_5pc', 'Steak ''n Shake Chicken Fingers (5 piece)', 275.0, 17.5, 18.5, 15.0, 1.5, 0.0, 200, 200, 'steaknshake.com', ARRAY['steak n shake 5 piece chicken', 'steak n shake chicken strips 5pc'], '550 cal per 5-piece serving (~200g)'),
('steak_n_shake_chili_cheese_frank', 'Steak ''n Shake Steak Frank Chili Cheese', 355.0, 16.5, 23.0, 22.0, 2.0, 2.5, 200, 200, 'steaknshake.com', ARRAY['steak n shake chili dog', 'steak n shake hot dog'], '710 cal per chili cheese frank (~200g)'),
('steak_n_shake_chili_3way', 'Steak ''n Shake Chili 3-Way', 202.9, 8.9, 28.0, 6.0, 3.7, 2.9, 350, 350, 'steaknshake.com', ARRAY['steak n shake chili', 'steak n shake 3 way chili'], '710 cal with spaghetti and cheese (~350g)'),
('steak_n_shake_grilled_cheese_bacon', 'Steak ''n Shake Grilled Cheese N Bacon', 327.8, 13.3, 22.8, 19.4, 1.1, 1.1, 180, 180, 'steaknshake.com', ARRAY['steak n shake grilled cheese', 'steak n shake bacon grilled cheese'], '590 cal per sandwich (~180g)'),
('steak_n_shake_vanilla_shake', 'Steak ''n Shake Vanilla Milkshake (Regular)', 137.8, 8.2, 23.3, 3.8, 0.0, 20.7, 450, 450, 'steaknshake.com', ARRAY['steak n shake vanilla milkshake'], '620 cal per regular shake (~450g)'),
('steak_n_shake_chocolate_shake', 'Steak ''n Shake Chocolate Milkshake (Regular)', 133.3, 8.4, 22.4, 3.8, 0.2, 18.7, 450, 450, 'steaknshake.com', ARRAY['steak n shake chocolate milkshake'], '600 cal per regular shake (~450g)'),
('steak_n_shake_strawberry_shake', 'Steak ''n Shake Strawberry Milkshake (Regular)', 135.6, 8.2, 22.9, 3.8, 0.0, 20.9, 450, 450, 'steaknshake.com', ARRAY['steak n shake strawberry milkshake'], '610 cal per regular shake (~450g)'),
('steak_n_shake_reeses_pb_shake', 'Steak ''n Shake Reese''s Peanut Butter Milkshake (Regular)', 180.0, 9.4, 19.6, 9.4, 0.6, 16.6, 500, 500, 'steaknshake.com', ARRAY['steak n shake peanut butter shake', 'steak n shake reeses shake'], '900 cal per regular shake (~500g)'),
('steak_n_shake_oreo_shake', 'Steak ''n Shake Oreo Cookies ''n Cream Milkshake (Regular)', 146.0, 7.6, 24.4, 4.4, 0.0, 20.4, 500, 500, 'steaknshake.com', ARRAY['steak n shake oreo shake', 'steak n shake cookies cream shake'], '730 cal per regular shake (~500g)')


ON CONFLICT (food_name_normalized) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  default_serving_g = EXCLUDED.default_serving_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  updated_at = NOW();
