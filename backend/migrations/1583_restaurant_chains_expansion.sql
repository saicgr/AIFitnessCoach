-- 1583_restaurant_chains_expansion.sql
-- Expansion: IHOP, Waffle House, Denny's, Cracker Barrel, Five Guys, Shake Shack,
-- Whataburger, Steak 'n Shake, Wingstop, Buffalo Wild Wings, Raising Cane's,
-- Zaxby's, Church's Chicken, plus hidden/secret menu items from Chipotle,
-- Starbucks, In-N-Out, and McDonald's.
-- Sources: Official chain nutrition PDFs, fastfoodnutrition.org, calorieking.com,
-- nutritionix.com, fatsecret.com, myfooddiary.com, eatthismuch.com.
-- All values per 100g. default_serving_g = full item weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- IHOP
-- ══════════════════════════════════════════

-- IHOP Original Buttermilk Pancakes Short Stack (3): 460 cal, 13P, 61C, 18F (270g)
('ihop_buttermilk_pancakes_short_stack', 'IHOP Original Buttermilk Pancakes (Short Stack)', 170, 4.8, 22.6, 6.7,
 0.7, 6.0, 270, NULL,
 'manufacturer', ARRAY['ihop short stack', 'ihop pancakes short stack', 'ihop buttermilk pancakes 3', 'ihop original pancakes short stack'],
 'breakfast', 'IHOP', 1, '460 cal. 3 original buttermilk pancakes with whipped butter. Classic IHOP breakfast staple.', TRUE),

-- IHOP Original Buttermilk Pancakes Full Stack (5): 750 cal, 22P, 115C, 22F (450g)
('ihop_buttermilk_pancakes_full_stack', 'IHOP Original Buttermilk Pancakes (Full Stack)', 167, 4.9, 25.6, 4.9,
 0.7, 5.8, 450, NULL,
 'manufacturer', ARRAY['ihop full stack', 'ihop pancakes full stack', 'ihop buttermilk pancakes 5', 'ihop original pancakes full stack'],
 'breakfast', 'IHOP', 1, '750 cal. 5 original buttermilk pancakes with whipped butter.', TRUE),

-- IHOP Belgian Waffle: 560 cal, 10P, 64C, 29F (210g)
('ihop_belgian_waffle', 'IHOP Belgian Waffle', 267, 4.8, 30.5, 13.8,
 0.5, 10.0, 210, 210,
 'manufacturer', ARRAY['ihop waffle', 'ihop belgian waffle', 'ihop waffle plain'],
 'breakfast', 'IHOP', 1, '560 cal. Thick Belgian-style waffle with whipped butter.', TRUE),

-- IHOP French Toast: 500 cal, 14P, 61C, 22F (200g)
('ihop_french_toast', 'IHOP French Toast', 250, 7.0, 30.5, 11.0,
 0.5, 8.0, 200, NULL,
 'manufacturer', ARRAY['ihop french toast', 'ihop original french toast', 'ihop thick cut french toast'],
 'breakfast', 'IHOP', 1, '500 cal. Thick-cut French toast with powdered sugar and whipped butter.', TRUE),

-- IHOP Veggie Omelette: 330 cal, 28P, 13C, 20F (280g)
('ihop_veggie_omelette', 'IHOP Veggie Omelette', 118, 10.0, 4.6, 7.1,
 0.7, 1.5, 280, NULL,
 'manufacturer', ARRAY['ihop veggie omelette', 'ihop vegetable omelette', 'ihop egg white veggie omelette'],
 'breakfast', 'IHOP', 1, '330 cal. Egg white omelette loaded with peppers, onions, mushrooms, tomatoes, spinach.', TRUE),

-- IHOP Western Omelette: 870 cal, 45P, 18C, 68F (380g)
('ihop_western_omelette', 'IHOP Western Omelette', 229, 11.8, 4.7, 17.9,
 0.3, 2.0, 380, NULL,
 'manufacturer', ARRAY['ihop western omelette', 'ihop cheesy western omelette'],
 'breakfast', 'IHOP', 1, '870 cal. Ham, peppers, onions, cheddar and American cheese omelette.', TRUE),

-- IHOP Colorado Omelette: 1240 cal, 74P, 18C, 100F (440g)
('ihop_colorado_omelette', 'IHOP Colorado Omelette', 282, 16.8, 4.1, 22.7,
 0.3, 1.5, 440, NULL,
 'manufacturer', ARRAY['ihop colorado omelette', 'colorado omelette ihop'],
 'breakfast', 'IHOP', 1, '1240 cal. Bacon, ham, peppers, onions, diced tomatoes, cheddar, Jack cheese. IHOP''s heartiest omelette.', TRUE),

-- IHOP Breakfast Sampler: 960 cal, 35P, 60C, 63F (480g)
('ihop_breakfast_sampler', 'IHOP Breakfast Sampler', 200, 7.3, 12.5, 13.1,
 0.6, 4.0, 480, NULL,
 'manufacturer', ARRAY['ihop breakfast sampler', 'ihop sampler', 'ihop ultimate sampler'],
 'breakfast', 'IHOP', 1, '960 cal. Eggs, bacon, sausage, ham, hash browns, pancakes. A bit of everything.', TRUE),

-- IHOP Chicken & Waffles: 1010 cal, 45P, 101C, 51F (420g)
('ihop_chicken_waffles', 'IHOP Chicken & Waffles', 240, 10.7, 24.0, 12.1,
 0.5, 6.0, 420, NULL,
 'manufacturer', ARRAY['ihop chicken and waffles', 'ihop chicken waffles', 'chicken waffles ihop'],
 'breakfast', 'IHOP', 1, '1010 cal. Hand-breaded chicken breast strips atop a Belgian waffle with Nashville hot or classic flavors.', TRUE),

-- IHOP Crepes with Fruit: 400 cal, 8P, 56C, 16F (250g)
('ihop_crepes_fruit', 'IHOP Crepes with Fruit', 160, 3.2, 22.4, 6.4,
 1.0, 12.0, 250, NULL,
 'manufacturer', ARRAY['ihop crepes', 'ihop fruit crepes', 'ihop crepes with fruit', 'ihop strawberry crepes'],
 'breakfast', 'IHOP', 1, '400 cal. Thin French-style crepes filled with seasonal fruit and whipped topping.', TRUE),

-- IHOP Country Fried Steak & Eggs: 960 cal, 38P, 58C, 63F (450g)
('ihop_country_fried_steak_eggs', 'IHOP Country Fried Steak & Eggs', 213, 8.4, 12.9, 14.0,
 0.4, 1.5, 450, NULL,
 'manufacturer', ARRAY['ihop country fried steak', 'ihop country fried steak and eggs', 'chicken fried steak ihop'],
 'breakfast', 'IHOP', 1, '960 cal. Breaded beef steak topped with country gravy, two eggs, hash browns.', TRUE),

-- IHOP Big Brunch Burger: 990 cal, 48P, 52C, 64F (380g)
('ihop_big_brunch_burger', 'IHOP Big Brunch Burger', 260, 12.6, 13.7, 16.8,
 1.0, 4.0, 380, 380,
 'manufacturer', ARRAY['ihop big brunch burger', 'ihop brunch burger', 'ihop burger'],
 'burgers', 'IHOP', 1, '990 cal. Beef burger topped with bacon, fried egg, cheese, onion rings on a brioche bun.', TRUE),

-- IHOP Mozzarella Sticks: 740 cal, 30P, 60C, 42F (280g)
('ihop_mozzarella_sticks', 'IHOP Mozzarella Sticks', 264, 10.7, 21.4, 15.0,
 1.0, 2.5, 280, NULL,
 'manufacturer', ARRAY['ihop mozz sticks', 'ihop mozzarella sticks', 'ihop cheese sticks'],
 'appetizers', 'IHOP', 1, '740 cal. Breaded mozzarella sticks with marinara sauce.', TRUE),

-- ══════════════════════════════════════════
-- WAFFLE HOUSE
-- ══════════════════════════════════════════

-- Waffle House Plain Waffle: 410 cal, 8P, 55C, 18F (170g)
('waffle_house_plain_waffle', 'Waffle House Plain Waffle', 241, 4.7, 32.4, 10.6,
 0.6, 8.8, 170, 170,
 'manufacturer', ARRAY['waffle house waffle', 'waffle house plain waffle', 'waffle house classic waffle'],
 'breakfast', 'Waffle House', 1, '410 cal. Classic golden-brown waffle, served plain.', TRUE),

-- Waffle House Pecan Waffle: 490 cal, 10P, 56C, 26F (190g)
('waffle_house_pecan_waffle', 'Waffle House Pecan Waffle', 258, 5.3, 29.5, 13.7,
 1.0, 9.0, 190, 190,
 'manufacturer', ARRAY['waffle house pecan waffle', 'pecan waffle waffle house'],
 'breakfast', 'Waffle House', 1, '490 cal. Classic waffle studded with pecans.', TRUE),

-- Waffle House Chocolate Chip Waffle: 470 cal, 9P, 62C, 22F (185g)
('waffle_house_chocolate_chip_waffle', 'Waffle House Chocolate Chip Waffle', 254, 4.9, 33.5, 11.9,
 1.0, 14.0, 185, 185,
 'manufacturer', ARRAY['waffle house chocolate chip waffle', 'chocolate waffle waffle house'],
 'breakfast', 'Waffle House', 1, '470 cal. Classic waffle with chocolate chips baked in.', TRUE),

-- Waffle House Hashbrowns Plain: 270 cal, 3P, 26C, 17F (140g)
('waffle_house_hashbrowns', 'Waffle House Hashbrowns (Plain)', 193, 2.1, 18.6, 12.1,
 1.4, 0.3, 140, NULL,
 'manufacturer', ARRAY['waffle house hashbrowns', 'waffle house hash browns', 'waffle house hashbrowns plain', 'waffle house scattered hashbrowns'],
 'sides', 'Waffle House', 1, '270 cal. Crispy shredded potato hashbrowns on the grill. Can be ordered scattered, smothered, covered, chunked, etc.', TRUE),

-- Waffle House All-Star Special: 790 cal, 32P, 58C, 48F (400g)
('waffle_house_all_star_special', 'Waffle House All-Star Special', 198, 8.0, 14.5, 12.0,
 0.8, 5.0, 400, NULL,
 'manufacturer', ARRAY['waffle house all star', 'waffle house all star special', 'all star special waffle house', 'waffle house all-star'],
 'combo_meals', 'Waffle House', 1, '790 cal. Waffle, 2 eggs, bacon or sausage, hashbrowns, toast or biscuit. The iconic combo.', TRUE),

-- Waffle House Patty Melt: 600 cal, 28P, 36C, 38F (260g)
('waffle_house_patty_melt', 'Waffle House Patty Melt', 231, 10.8, 13.8, 14.6,
 0.5, 3.0, 260, 260,
 'manufacturer', ARRAY['waffle house patty melt', 'patty melt waffle house'],
 'sandwiches', 'Waffle House', 1, '600 cal. Beef patty with grilled onions, American cheese on Texas toast.', TRUE),

-- Waffle House Texas Bacon Cheesesteak Melt: 750 cal, 38P, 42C, 46F (320g)
('waffle_house_texas_bacon_cheesesteak', 'Waffle House Texas Bacon Cheesesteak Melt', 234, 11.9, 13.1, 14.4,
 0.5, 2.5, 320, 320,
 'manufacturer', ARRAY['waffle house cheesesteak', 'waffle house texas bacon cheesesteak', 'texas bacon cheesesteak melt waffle house'],
 'sandwiches', 'Waffle House', 1, '750 cal. Grilled steak, bacon, cheese, onions, peppers on Texas toast.', TRUE),

-- Waffle House Sausage Egg & Cheese Biscuit: 520 cal, 18P, 32C, 36F (180g)
('waffle_house_sausage_egg_cheese_biscuit', 'Waffle House Sausage Egg & Cheese Biscuit', 289, 10.0, 17.8, 20.0,
 0.3, 2.0, 180, 180,
 'manufacturer', ARRAY['waffle house sausage biscuit', 'waffle house sausage egg cheese biscuit', 'sausage egg cheese biscuit waffle house'],
 'breakfast', 'Waffle House', 1, '520 cal. Buttermilk biscuit with sausage patty, egg, American cheese.', TRUE),

-- ══════════════════════════════════════════
-- DENNY'S
-- ══════════════════════════════════════════

-- Denny's Grand Slam: 770 cal, 34P, 79C, 34F (420g)
('dennys_grand_slam', 'Denny''s Grand Slam', 183, 8.1, 18.8, 8.1,
 0.7, 4.5, 420, NULL,
 'manufacturer', ARRAY['dennys grand slam', 'denny grand slam', 'grand slam dennys', 'original grand slam'],
 'breakfast', 'Denny''s', 1, '770 cal. 2 eggs, 2 bacon, 2 sausage links, 2 pancakes. The iconic Denny''s combo.', TRUE),

-- Denny's Moons Over My Hammy: 780 cal, 44P, 31C, 53F (350g)
('dennys_moons_over_my_hammy', 'Denny''s Moons Over My Hammy', 223, 12.6, 8.9, 15.1,
 0.5, 2.0, 350, 350,
 'manufacturer', ARRAY['moons over my hammy', 'dennys moons over my hammy', 'denny moons over hammy'],
 'sandwiches', 'Denny''s', 1, '780 cal. Scrambled egg, ham, Swiss and American cheese on sourdough. A Denny''s classic.', TRUE),

-- Denny's Lumberjack Slam: 1070 cal, 45P, 95C, 56F (520g)
('dennys_lumberjack_slam', 'Denny''s Lumberjack Slam', 206, 8.7, 18.3, 10.8,
 1.0, 5.0, 520, NULL,
 'manufacturer', ARRAY['dennys lumberjack slam', 'denny lumberjack slam', 'lumberjack slam'],
 'breakfast', 'Denny''s', 1, '1070 cal. 2 eggs, 2 bacon, 2 sausage, ham, hashbrowns, 2 pancakes. The biggest breakfast platter.', TRUE),

-- Denny's Fit Slam: 390 cal, 30P, 42C, 12F (350g)
('dennys_fit_slam', 'Denny''s Fit Slam', 111, 8.6, 12.0, 3.4,
 2.0, 5.0, 350, NULL,
 'manufacturer', ARRAY['dennys fit slam', 'denny fit slam', 'fit slam dennys'],
 'breakfast', 'Denny''s', 1, '390 cal. Egg whites, turkey bacon, seasonal fruit, English muffin. The lighter choice.', TRUE),

-- Denny's Build Your Own Slam (base): 350 cal, 20P, 25C, 18F (260g)
('dennys_build_your_own_slam', 'Denny''s Build Your Own Slam (Base)', 135, 7.7, 9.6, 6.9,
 0.3, 2.0, 260, NULL,
 'manufacturer', ARRAY['dennys build your own slam', 'denny build your own', 'build your own slam dennys', 'byos dennys'],
 'breakfast', 'Denny''s', 1, '350 cal base. Choose your eggs and 4 items. Calories vary with selections.', TRUE),

-- Denny's Loaded Veggie Omelette: 470 cal, 28P, 18C, 32F (330g)
('dennys_loaded_veggie_omelette', 'Denny''s Loaded Veggie Omelette', 142, 8.5, 5.5, 9.7,
 1.2, 2.5, 330, NULL,
 'manufacturer', ARRAY['dennys veggie omelette', 'dennys loaded veggie omelette', 'denny veggie omelette'],
 'breakfast', 'Denny''s', 1, '470 cal. Three-egg omelette stuffed with mushrooms, peppers, onions, tomatoes, spinach, cheese.', TRUE),

-- Denny's Nashville Hot Chicken Melt: 880 cal, 42P, 60C, 50F (370g)
('dennys_nashville_hot_chicken_melt', 'Denny''s Nashville Hot Chicken Melt', 238, 11.4, 16.2, 13.5,
 1.0, 3.0, 370, 370,
 'manufacturer', ARRAY['dennys nashville hot chicken', 'dennys nashville chicken melt', 'nashville hot chicken melt dennys'],
 'sandwiches', 'Denny''s', 1, '880 cal. Crispy chicken with Nashville hot sauce, pickles, coleslaw, American cheese on brioche.', TRUE),

-- ══════════════════════════════════════════
-- CRACKER BARREL
-- ══════════════════════════════════════════

-- Cracker Barrel Old Timer's Breakfast: 630 cal, 28P, 48C, 36F (380g)
('cracker_barrel_old_timers_breakfast', 'Cracker Barrel Old Timer''s Breakfast', 166, 7.4, 12.6, 9.5,
 0.5, 1.5, 380, NULL,
 'manufacturer', ARRAY['cracker barrel old timers breakfast', 'old timers breakfast cracker barrel', 'cracker barrel old timer'],
 'breakfast', 'Cracker Barrel', 1, '630 cal. Two eggs, breakfast meat, biscuits n gravy, grits or hashbrown casserole.', TRUE),

-- Cracker Barrel Grandpa's Country Fried Breakfast: 1020 cal, 38P, 80C, 60F (480g)
('cracker_barrel_grandpas_country_fried', 'Cracker Barrel Grandpa''s Country Fried Breakfast', 213, 7.9, 16.7, 12.5,
 0.8, 2.0, 480, NULL,
 'manufacturer', ARRAY['cracker barrel grandpas breakfast', 'grandpa country fried breakfast', 'cracker barrel country fried breakfast'],
 'breakfast', 'Cracker Barrel', 1, '1020 cal. Country fried steak with sawmill gravy, eggs, hashbrown casserole, biscuits. A massive breakfast.', TRUE),

-- Cracker Barrel Chicken n' Dumplins: 380 cal, 25P, 38C, 14F (310g)
('cracker_barrel_chicken_dumplins', 'Cracker Barrel Chicken n'' Dumplins', 123, 8.1, 12.3, 4.5,
 0.6, 1.0, 310, NULL,
 'manufacturer', ARRAY['cracker barrel chicken dumplins', 'chicken and dumplings cracker barrel', 'cracker barrel chicken n dumplins'],
 'entrees', 'Cracker Barrel', 1, '380 cal. Tender chicken simmered with made-from-scratch dumplings in chicken broth.', TRUE),

-- Cracker Barrel Country Fried Steak: 530 cal, 22P, 36C, 33F (250g)
('cracker_barrel_country_fried_steak', 'Cracker Barrel Country Fried Steak', 212, 8.8, 14.4, 13.2,
 0.5, 1.0, 250, NULL,
 'manufacturer', ARRAY['cracker barrel country fried steak', 'country fried steak cracker barrel', 'cracker barrel chicken fried steak'],
 'entrees', 'Cracker Barrel', 1, '530 cal. Breaded and fried beef cutlet topped with sawmill gravy. Without sides.', TRUE),

-- Cracker Barrel Meatloaf: 400 cal, 22P, 18C, 26F (230g)
('cracker_barrel_meatloaf', 'Cracker Barrel Meatloaf', 174, 9.6, 7.8, 11.3,
 0.3, 3.0, 230, NULL,
 'manufacturer', ARRAY['cracker barrel meatloaf', 'meatloaf cracker barrel', 'cracker barrel homestyle meatloaf'],
 'entrees', 'Cracker Barrel', 1, '400 cal. Thick slice of homestyle meatloaf with tomato glaze. Without sides.', TRUE),

-- Cracker Barrel Hashbrown Casserole: 270 cal, 7P, 20C, 18F (170g)
('cracker_barrel_hashbrown_casserole', 'Cracker Barrel Hashbrown Casserole', 159, 4.1, 11.8, 10.6,
 0.6, 1.0, 170, NULL,
 'manufacturer', ARRAY['cracker barrel hashbrown casserole', 'hashbrown casserole cracker barrel', 'cracker barrel hash brown casserole'],
 'sides', 'Cracker Barrel', 1, '270 cal. Shredded potatoes with Colby cheese, cream of chicken soup, baked. Iconic side.', TRUE),

-- Cracker Barrel Turnip Greens: 60 cal, 3P, 5C, 3F (120g)
('cracker_barrel_turnip_greens', 'Cracker Barrel Turnip Greens', 50, 2.5, 4.2, 2.5,
 2.0, 0.5, 120, NULL,
 'manufacturer', ARRAY['cracker barrel turnip greens', 'turnip greens cracker barrel', 'cracker barrel greens'],
 'sides', 'Cracker Barrel', 1, '60 cal. Slow-cooked Southern-style turnip greens. One of the lowest-calorie sides.', TRUE),

-- Cracker Barrel Biscuits & Gravy: 460 cal, 10P, 44C, 27F (260g)
('cracker_barrel_biscuits_gravy', 'Cracker Barrel Biscuits & Gravy', 177, 3.8, 16.9, 10.4,
 0.4, 2.0, 260, NULL,
 'manufacturer', ARRAY['cracker barrel biscuits and gravy', 'cracker barrel biscuits gravy', 'biscuits n gravy cracker barrel'],
 'breakfast', 'Cracker Barrel', 1, '460 cal. Buttermilk biscuits smothered in sawmill sausage gravy.', TRUE),

-- ══════════════════════════════════════════
-- FIVE GUYS
-- ══════════════════════════════════════════

-- Five Guys Little Hamburger: 480 cal, 24P, 39C, 26F (195g)
('five_guys_little_hamburger', 'Five Guys Little Hamburger', 246, 12.3, 20.0, 13.3,
 1.5, 4.0, 195, 195,
 'manufacturer', ARRAY['five guys little hamburger', 'five guys little burger', 'five guys small burger', 'little hamburger five guys'],
 'burgers', 'Five Guys', 1, '480 cal. Single patty on a sesame seed bun with standard toppings. Five Guys'' smallest burger.', TRUE),

-- Five Guys Hamburger: 700 cal, 39P, 39C, 43F (303g)
('five_guys_hamburger', 'Five Guys Hamburger', 231, 12.9, 12.9, 14.2,
 1.0, 3.5, 303, 303,
 'manufacturer', ARRAY['five guys hamburger', 'five guys burger', 'five guys regular burger', 'hamburger five guys'],
 'burgers', 'Five Guys', 1, '700 cal. Two hand-formed patties on a sesame seed bun. The standard Five Guys burger.', TRUE),

-- Five Guys Cheeseburger: 840 cal, 47P, 40C, 55F (330g)
('five_guys_cheeseburger', 'Five Guys Cheeseburger', 255, 14.2, 12.1, 16.7,
 1.0, 3.5, 330, 330,
 'manufacturer', ARRAY['five guys cheeseburger', 'five guys cheese burger', 'cheeseburger five guys'],
 'burgers', 'Five Guys', 1, '840 cal. Two beef patties with American cheese on a sesame seed bun.', TRUE),

-- Five Guys Bacon Cheeseburger: 920 cal, 47P, 40C, 62F (317g)
('five_guys_bacon_cheeseburger', 'Five Guys Bacon Cheeseburger', 290, 14.8, 12.6, 19.6,
 1.0, 3.5, 317, 317,
 'manufacturer', ARRAY['five guys bacon cheeseburger', 'five guys bacon cheese burger', 'bacon cheeseburger five guys'],
 'burgers', 'Five Guys', 1, '920 cal. Two beef patties, American cheese, and applewood-smoked bacon.', TRUE),

-- Five Guys Little Bacon Burger: 560 cal, 27P, 39C, 33F (213g)
('five_guys_little_bacon_burger', 'Five Guys Little Bacon Burger', 263, 12.7, 18.3, 15.5,
 1.0, 4.0, 213, 213,
 'manufacturer', ARRAY['five guys little bacon burger', 'five guys little bacon hamburger', 'little bacon burger five guys'],
 'burgers', 'Five Guys', 1, '560 cal. Single patty with applewood-smoked bacon on sesame seed bun.', TRUE),

-- Five Guys Cajun Fries Regular: 950 cal, 12P, 82C, 64F (284g)
('five_guys_cajun_fries', 'Five Guys Cajun Fries (Regular)', 335, 4.2, 28.9, 22.5,
 4.5, 0.3, 284, NULL,
 'manufacturer', ARRAY['five guys cajun fries', 'cajun fries five guys', 'five guys fries cajun'],
 'sides', 'Five Guys', 1, '950 cal. Boardwalk-style fries seasoned with Cajun spices. Generous portions.', TRUE),

-- Five Guys Regular Fries: 950 cal, 12P, 82C, 64F (284g)
('five_guys_regular_fries', 'Five Guys Fries (Regular)', 335, 4.2, 28.9, 22.5,
 4.5, 0.3, 284, NULL,
 'manufacturer', ARRAY['five guys fries', 'five guys regular fries', 'five guys french fries', 'fries five guys'],
 'sides', 'Five Guys', 1, '950 cal. Fresh-cut boardwalk-style fries cooked in peanut oil. Famously large portions.', TRUE),

-- Five Guys Grilled Cheese: 470 cal, 18P, 41C, 26F (170g)
('five_guys_grilled_cheese', 'Five Guys Grilled Cheese', 276, 10.6, 24.1, 15.3,
 1.0, 3.0, 170, 170,
 'manufacturer', ARRAY['five guys grilled cheese', 'grilled cheese five guys', 'five guys grilled cheese sandwich'],
 'sandwiches', 'Five Guys', 1, '470 cal. Toasted bun with melted American cheese and grilled onions/mushrooms available.', TRUE),

-- Five Guys BLT: 430 cal, 18P, 37C, 25F (180g)
('five_guys_blt', 'Five Guys BLT', 239, 10.0, 20.6, 13.9,
 1.5, 3.0, 180, 180,
 'manufacturer', ARRAY['five guys blt', 'blt five guys', 'five guys bacon lettuce tomato'],
 'sandwiches', 'Five Guys', 1, '430 cal. Applewood-smoked bacon, lettuce, tomato on a toasted bun.', TRUE),

-- Five Guys Veggie Sandwich: 440 cal, 16P, 60C, 15F (280g)
('five_guys_veggie_sandwich', 'Five Guys Veggie Sandwich', 157, 5.7, 21.4, 5.4,
 2.5, 4.0, 280, 280,
 'manufacturer', ARRAY['five guys veggie sandwich', 'veggie sandwich five guys', 'five guys vegetarian'],
 'sandwiches', 'Five Guys', 1, '440 cal. Grilled onions, mushrooms, peppers, lettuce, tomato on a sesame seed bun.', TRUE),

-- Five Guys Hot Dog: 545 cal, 18P, 40C, 35F (180g)
('five_guys_hot_dog', 'Five Guys Hot Dog', 303, 10.0, 22.2, 19.4,
 0.6, 3.0, 180, 180,
 'manufacturer', ARRAY['five guys hot dog', 'hot dog five guys', 'five guys kosher hot dog'],
 'hot_dogs', 'Five Guys', 1, '545 cal. Split and grilled all-beef kosher hot dog on a toasted bun.', TRUE),

-- Five Guys Vanilla Milkshake: 870 cal, 17P, 78C, 54F (480g)
('five_guys_vanilla_milkshake', 'Five Guys Vanilla Milkshake', 181, 3.5, 16.3, 11.3,
 0.0, 13.0, 480, NULL,
 'manufacturer', ARRAY['five guys vanilla milkshake', 'five guys milkshake vanilla', 'five guys shake vanilla'],
 'beverages', 'Five Guys', 1, '870 cal. Hand-spun milkshake made with real vanilla. Can add mix-ins.', TRUE),

-- ══════════════════════════════════════════
-- SHAKE SHACK
-- ══════════════════════════════════════════

-- Shake Shack ShackBurger: 530 cal, 29P, 26C, 34F (200g)
('shake_shack_shackburger', 'Shake Shack ShackBurger', 265, 14.5, 13.0, 17.0,
 0.5, 3.0, 200, 200,
 'manufacturer', ARRAY['shackburger', 'shake shack shackburger', 'shake shack burger', 'shack burger'],
 'burgers', 'Shake Shack', 1, '530 cal. 100% Angus beef, lettuce, tomato, ShackSauce on a potato bun. The original.', TRUE),

-- Shake Shack SmokeShack: 610 cal, 34P, 28C, 40F (230g)
('shake_shack_smokeshack', 'Shake Shack SmokeShack', 265, 14.8, 12.2, 17.4,
 0.5, 3.0, 230, 230,
 'manufacturer', ARRAY['smokeshack', 'shake shack smokeshack', 'smoke shack', 'smokeshack burger'],
 'burgers', 'Shake Shack', 1, '610 cal. Cheeseburger topped with applewood-smoked bacon, cherry peppers, ShackSauce.', TRUE),

-- Shake Shack Shack Stack: 720 cal, 30P, 38C, 50F (260g)
('shake_shack_shack_stack', 'Shake Shack Shack Stack', 277, 11.5, 14.6, 19.2,
 1.0, 3.0, 260, 260,
 'manufacturer', ARRAY['shack stack', 'shake shack shack stack', 'shake shack stack'],
 'burgers', 'Shake Shack', 1, '720 cal. Cheeseburger plus a crispy-fried portobello mushroom filled with muenster and cheddar.', TRUE),

-- Shake Shack Chick'n Shack: 580 cal, 33P, 48C, 28F (240g)
('shake_shack_chickn_shack', 'Shake Shack Chick''n Shack', 242, 13.8, 20.0, 11.7,
 1.0, 3.0, 240, 240,
 'manufacturer', ARRAY['chickn shack', 'shake shack chicken', 'shake shack chicken sandwich', 'chick n shack'],
 'sandwiches', 'Shake Shack', 1, '580 cal. Crispy chicken breast with lettuce, pickles, buttermilk herb mayo on a potato bun.', TRUE),

-- Shake Shack Crinkle Cut Fries: 470 cal, 6P, 63C, 22F (170g)
('shake_shack_fries', 'Shake Shack Crinkle Cut Fries', 276, 3.5, 37.1, 12.9,
 3.5, 0.3, 170, NULL,
 'manufacturer', ARRAY['shake shack fries', 'shake shack crinkle cut fries', 'crinkle fries shake shack'],
 'sides', 'Shake Shack', 1, '470 cal. Crinkle-cut fries cooked in 100% sunflower oil.', TRUE),

-- Shake Shack Cheese Fries: 570 cal, 10P, 65C, 30F (210g)
('shake_shack_cheese_fries', 'Shake Shack Cheese Fries', 271, 4.8, 31.0, 14.3,
 3.0, 1.0, 210, NULL,
 'manufacturer', ARRAY['shake shack cheese fries', 'cheese fries shake shack'],
 'sides', 'Shake Shack', 1, '570 cal. Crinkle-cut fries topped with cheese sauce and cheddar-Jack blend.', TRUE),

-- Shake Shack Vanilla Shake: 700 cal, 14P, 85C, 34F (470g)
('shake_shack_vanilla_shake', 'Shake Shack Vanilla Shake', 149, 3.0, 18.1, 7.2,
 0.0, 15.0, 470, NULL,
 'manufacturer', ARRAY['shake shack vanilla shake', 'shake shack milkshake vanilla', 'vanilla shake shake shack'],
 'beverages', 'Shake Shack', 1, '700 cal. Hand-spun vanilla frozen custard shake.', TRUE),

-- Shake Shack Chocolate Shake: 740 cal, 14P, 92C, 36F (480g)
('shake_shack_chocolate_shake', 'Shake Shack Chocolate Shake', 154, 2.9, 19.2, 7.5,
 0.5, 16.0, 480, NULL,
 'manufacturer', ARRAY['shake shack chocolate shake', 'shake shack milkshake chocolate', 'chocolate shake shake shack'],
 'beverages', 'Shake Shack', 1, '740 cal. Hand-spun chocolate frozen custard shake.', TRUE),

-- ══════════════════════════════════════════
-- WHATABURGER
-- ══════════════════════════════════════════

-- Whataburger (single): 590 cal, 28P, 52C, 30F (280g)
('whataburger_single', 'Whataburger', 211, 10.0, 18.6, 10.7,
 1.1, 5.0, 280, 280,
 'manufacturer', ARRAY['whataburger', 'whataburger single', 'whataburger original', 'whataburger burger'],
 'burgers', 'Whataburger', 1, '590 cal. Quarter-pound beef patty, mustard, lettuce, tomato, pickles, onions on a 5-inch toasted bun.', TRUE),

-- Double Meat Whataburger: 890 cal, 50P, 52C, 54F (385g)
('whataburger_double_meat', 'Double Meat Whataburger', 231, 13.0, 13.5, 14.0,
 1.0, 5.0, 385, 385,
 'manufacturer', ARRAY['double meat whataburger', 'whataburger double', 'double whataburger', 'whataburger double meat'],
 'burgers', 'Whataburger', 1, '890 cal. Two quarter-pound beef patties with standard toppings on a 5-inch toasted bun.', TRUE),

-- Triple Meat Whataburger: 1170 cal, 70P, 52C, 76F (490g)
('whataburger_triple_meat', 'Triple Meat Whataburger', 239, 14.3, 10.6, 15.5,
 0.8, 4.0, 490, 490,
 'manufacturer', ARRAY['triple meat whataburger', 'whataburger triple', 'triple whataburger', 'whataburger triple meat'],
 'burgers', 'Whataburger', 1, '1170 cal. Three quarter-pound beef patties. Over 1 lb of meat and toppings.', TRUE),

-- Whataburger Patty Melt: 780 cal, 40P, 45C, 48F (310g)
('whataburger_patty_melt', 'Whataburger Patty Melt', 252, 12.9, 14.5, 15.5,
 0.6, 3.0, 310, 310,
 'manufacturer', ARRAY['whataburger patty melt', 'patty melt whataburger'],
 'burgers', 'Whataburger', 1, '780 cal. Beef patty with grilled onions and creamy pepper sauce on Texas toast.', TRUE),

-- Whataburger Honey BBQ Chicken Strip Sandwich: 690 cal, 32P, 72C, 30F (280g)
('whataburger_honey_bbq_chicken_strip', 'Whataburger Honey BBQ Chicken Strip Sandwich', 246, 11.4, 25.7, 10.7,
 1.0, 8.0, 280, 280,
 'manufacturer', ARRAY['whataburger honey bbq chicken strip sandwich', 'honey bbq chicken strip whataburger', 'whataburger chicken strip sandwich'],
 'sandwiches', 'Whataburger', 1, '690 cal. Crispy chicken strips with Honey BBQ sauce, lettuce, tomato on a bun.', TRUE),

-- Whataburger Breakfast on a Bun with Sausage: 480 cal, 18P, 28C, 33F (190g)
('whataburger_breakfast_bun_sausage', 'Whataburger Breakfast on a Bun (Sausage)', 253, 9.5, 14.7, 17.4,
 0.5, 2.0, 190, 190,
 'manufacturer', ARRAY['whataburger breakfast on a bun sausage', 'breakfast on a bun whataburger sausage', 'whataburger breakfast bun'],
 'breakfast', 'Whataburger', 1, '480 cal. Sausage patty, egg, cheese on a toasted bun. Whataburger breakfast staple.', TRUE),

-- Whataburger Honey Butter Chicken Biscuit: 470 cal, 16P, 46C, 24F (170g)
('whataburger_honey_butter_chicken_biscuit', 'Whataburger Honey Butter Chicken Biscuit', 276, 9.4, 27.1, 14.1,
 0.4, 6.0, 170, 170,
 'manufacturer', ARRAY['honey butter chicken biscuit', 'whataburger honey butter chicken biscuit', 'hbcb whataburger', 'whataburger chicken biscuit'],
 'breakfast', 'Whataburger', 1, '470 cal. Breaded chicken strip with honey butter sauce on a buttermilk biscuit. Fan-favorite cult classic.', TRUE),

-- ══════════════════════════════════════════
-- STEAK 'N SHAKE
-- ══════════════════════════════════════════

-- Steak 'n Shake Original Double Steakburger: 430 cal, 24P, 32C, 22F (190g)
('steak_n_shake_original_double', 'Steak ''n Shake Original Double Steakburger', 226, 12.6, 16.8, 11.6,
 1.0, 3.5, 190, 190,
 'manufacturer', ARRAY['steak n shake double steakburger', 'steak and shake double', 'steak n shake original double', 'original double steakburger'],
 'burgers', 'Steak ''n Shake', 1, '430 cal. Two thin steakburger patties with mustard, ketchup, pickle, onion on a toasted bun.', TRUE),

-- Steak 'n Shake Frisco Melt: 640 cal, 34P, 39C, 38F (260g)
('steak_n_shake_frisco_melt', 'Steak ''n Shake Frisco Melt', 246, 13.1, 15.0, 14.6,
 0.5, 3.0, 260, 260,
 'manufacturer', ARRAY['steak n shake frisco melt', 'frisco melt steak n shake', 'frisco melt steakburger'],
 'burgers', 'Steak ''n Shake', 1, '640 cal. Two steakburger patties with American cheese and Frisco sauce on sourdough bread.', TRUE),

-- Steak 'n Shake Garlic Double Steakburger: 500 cal, 28P, 32C, 28F (210g)
('steak_n_shake_garlic_double', 'Steak ''n Shake Garlic Double Steakburger', 238, 13.3, 15.2, 13.3,
 0.5, 3.0, 210, 210,
 'manufacturer', ARRAY['steak n shake garlic double', 'garlic double steakburger', 'garlic steakburger steak n shake'],
 'burgers', 'Steak ''n Shake', 1, '500 cal. Two steakburger patties with roasted garlic, cheese, garlic butter bun.', TRUE),

-- Steak 'n Shake Royale Steakburger: 580 cal, 30P, 38C, 34F (240g)
('steak_n_shake_royale', 'Steak ''n Shake Royale Steakburger', 242, 12.5, 15.8, 14.2,
 0.5, 3.5, 240, 240,
 'manufacturer', ARRAY['steak n shake royale', 'royale steakburger', 'steak n shake royale steakburger'],
 'burgers', 'Steak ''n Shake', 1, '580 cal. Two steakburger patties with American and Swiss cheese, lettuce, tomato, special sauce.', TRUE),

-- Steak 'n Shake Vanilla Milkshake: 680 cal, 14P, 93C, 28F (440g)
('steak_n_shake_vanilla_milkshake', 'Steak ''n Shake Vanilla Milkshake', 155, 3.2, 21.1, 6.4,
 0.0, 18.0, 440, NULL,
 'manufacturer', ARRAY['steak n shake vanilla milkshake', 'steak n shake milkshake vanilla', 'vanilla milkshake steak n shake'],
 'beverages', 'Steak ''n Shake', 1, '680 cal. Hand-dipped real ice cream milkshake, classic vanilla.', TRUE),

-- Steak 'n Shake Chocolate Milkshake: 710 cal, 14P, 98C, 30F (450g)
('steak_n_shake_chocolate_milkshake', 'Steak ''n Shake Chocolate Milkshake', 158, 3.1, 21.8, 6.7,
 0.5, 19.0, 450, NULL,
 'manufacturer', ARRAY['steak n shake chocolate milkshake', 'steak n shake milkshake chocolate', 'chocolate milkshake steak n shake'],
 'beverages', 'Steak ''n Shake', 1, '710 cal. Hand-dipped real ice cream milkshake, classic chocolate.', TRUE),

-- ══════════════════════════════════════════
-- WINGSTOP
-- ══════════════════════════════════════════

-- Wingstop Classic Wings 6pc Plain: 430 cal, 46P, 0C, 26F (228g, ~38g/wing)
('wingstop_classic_wings_6pc_plain', 'Wingstop Classic Wings 6pc (Plain)', 189, 20.2, 0.0, 11.4,
 0.0, 0.0, 228, 38,
 'manufacturer', ARRAY['wingstop plain wings 6', 'wingstop classic wings 6 plain', 'wingstop wings plain 6pc', 'wingstop bone in 6 plain'],
 'wings', 'Wingstop', 1, '430 cal. 6 classic bone-in wings unbreaded, plain. High protein, zero carb.', TRUE),

-- Wingstop Classic Wings 10pc Plain: 720 cal, 77P, 0C, 43F (380g)
('wingstop_classic_wings_10pc_plain', 'Wingstop Classic Wings 10pc (Plain)', 189, 20.3, 0.0, 11.3,
 0.0, 0.0, 380, 38,
 'manufacturer', ARRAY['wingstop plain wings 10', 'wingstop classic wings 10 plain', 'wingstop wings plain 10pc', 'wingstop bone in 10 plain'],
 'wings', 'Wingstop', 1, '720 cal. 10 classic bone-in wings unbreaded, plain.', TRUE),

-- Wingstop Lemon Pepper Wings 6pc: 470 cal, 46P, 2C, 30F (234g)
('wingstop_lemon_pepper_6pc', 'Wingstop Lemon Pepper Wings 6pc', 201, 19.7, 0.9, 12.8,
 0.0, 0.0, 234, 39,
 'manufacturer', ARRAY['wingstop lemon pepper', 'wingstop lemon pepper wings 6', 'lemon pepper wings wingstop'],
 'wings', 'Wingstop', 1, '470 cal. 6 bone-in wings tossed in tangy lemon pepper dry rub. Fan favorite.', TRUE),

-- Wingstop Atomic Wings 6pc: 450 cal, 46P, 2C, 28F (234g)
('wingstop_atomic_6pc', 'Wingstop Atomic Wings 6pc', 192, 19.7, 0.9, 12.0,
 0.0, 0.5, 234, 39,
 'manufacturer', ARRAY['wingstop atomic', 'wingstop atomic wings 6', 'atomic wings wingstop', 'wingstop hottest wings'],
 'wings', 'Wingstop', 1, '450 cal. 6 bone-in wings in Wingstop''s hottest sauce. Not for the faint of heart.', TRUE),

-- Wingstop Garlic Parmesan Wings 6pc: 510 cal, 46P, 4C, 34F (240g)
('wingstop_garlic_parmesan_6pc', 'Wingstop Garlic Parmesan Wings 6pc', 213, 19.2, 1.7, 14.2,
 0.0, 0.5, 240, 40,
 'manufacturer', ARRAY['wingstop garlic parmesan', 'wingstop garlic parm wings 6', 'garlic parm wingstop', 'garlic parmesan wings wingstop'],
 'wings', 'Wingstop', 1, '510 cal. 6 bone-in wings tossed in buttery garlic parmesan sauce.', TRUE),

-- Wingstop Mango Habanero Wings 6pc: 460 cal, 46P, 8C, 27F (240g)
('wingstop_mango_habanero_6pc', 'Wingstop Mango Habanero Wings 6pc', 192, 19.2, 3.3, 11.3,
 0.0, 2.5, 240, 40,
 'manufacturer', ARRAY['wingstop mango habanero', 'wingstop mango habanero wings 6', 'mango habanero wingstop'],
 'wings', 'Wingstop', 1, '460 cal. 6 bone-in wings in sweet and spicy mango habanero sauce.', TRUE),

-- Wingstop Louisiana Rub Wings 6pc: 440 cal, 46P, 2C, 27F (234g)
('wingstop_louisiana_rub_6pc', 'Wingstop Louisiana Rub Wings 6pc', 188, 19.7, 0.9, 11.5,
 0.0, 0.0, 234, 39,
 'manufacturer', ARRAY['wingstop louisiana rub', 'wingstop louisiana rub wings 6', 'louisiana rub wingstop'],
 'wings', 'Wingstop', 1, '440 cal. 6 bone-in wings with Louisiana-style Cajun dry rub.', TRUE),

-- Wingstop Original Hot Wings 6pc: 440 cal, 46P, 2C, 27F (234g)
('wingstop_original_hot_6pc', 'Wingstop Original Hot Wings 6pc', 188, 19.7, 0.9, 11.5,
 0.0, 0.5, 234, 39,
 'manufacturer', ARRAY['wingstop original hot', 'wingstop original hot wings 6', 'original hot wingstop', 'wingstop hot wings'],
 'wings', 'Wingstop', 1, '440 cal. 6 bone-in wings in classic cayenne pepper hot sauce.', TRUE),

-- Wingstop Boneless Wings 6pc: 360 cal, 20P, 22C, 22F (170g)
('wingstop_boneless_6pc', 'Wingstop Boneless Wings 6pc', 212, 11.8, 12.9, 12.9,
 0.5, 1.0, 170, 28,
 'manufacturer', ARRAY['wingstop boneless', 'wingstop boneless wings 6', 'boneless wingstop 6pc', 'wingstop boneless 6'],
 'wings', 'Wingstop', 1, '360 cal. 6 boneless wing pieces, breaded and fried. Lower cal than bone-in.', TRUE),

-- Wingstop Thighs 4pc: 690 cal, 52P, 24C, 42F (320g)
('wingstop_thighs_4pc', 'Wingstop Thighs 4pc', 216, 16.3, 7.5, 13.1,
 0.3, 0.5, 320, 80,
 'manufacturer', ARRAY['wingstop thighs', 'wingstop thighs 4', 'wingstop chicken thighs 4pc'],
 'chicken', 'Wingstop', 1, '690 cal. 4 bone-in chicken thighs, crispy fried.', TRUE),

-- Wingstop Regular Fries: 380 cal, 5P, 46C, 20F (150g)
('wingstop_fries', 'Wingstop Fries (Regular)', 253, 3.3, 30.7, 13.3,
 2.5, 0.2, 150, NULL,
 'manufacturer', ARRAY['wingstop fries', 'wingstop regular fries', 'wingstop seasoned fries', 'fries wingstop'],
 'sides', 'Wingstop', 1, '380 cal. Seasoned cut fries. Regular portion.', TRUE),

-- Wingstop Veggie Sticks: 25 cal, 1P, 5C, 0F (80g)
('wingstop_veggie_sticks', 'Wingstop Veggie Sticks', 31, 1.3, 6.3, 0.0,
 1.5, 2.5, 80, NULL,
 'manufacturer', ARRAY['wingstop veggie sticks', 'wingstop celery carrots', 'veggie sticks wingstop'],
 'sides', 'Wingstop', 1, '25 cal. Celery and carrot sticks. The lightest side option.', TRUE),

-- ══════════════════════════════════════════
-- BUFFALO WILD WINGS
-- ══════════════════════════════════════════

-- BWW Traditional Wings 6pc Plain: 430 cal, 50P, 0C, 24F (228g)
('bww_traditional_6pc_plain', 'Buffalo Wild Wings Traditional Wings 6pc (Plain)', 189, 21.9, 0.0, 10.5,
 0.0, 0.0, 228, 38,
 'manufacturer', ARRAY['buffalo wild wings traditional 6', 'bww traditional wings 6', 'bww plain wings 6', 'bdubs traditional 6'],
 'wings', 'Buffalo Wild Wings', 1, '430 cal. 6 bone-in traditional wings, naked/plain. High protein.', TRUE),

-- BWW Traditional Wings 10pc Plain: 720 cal, 83P, 0C, 41F (380g)
('bww_traditional_10pc_plain', 'Buffalo Wild Wings Traditional Wings 10pc (Plain)', 189, 21.8, 0.0, 10.8,
 0.0, 0.0, 380, 38,
 'manufacturer', ARRAY['buffalo wild wings traditional 10', 'bww traditional wings 10', 'bww plain wings 10', 'bdubs traditional 10'],
 'wings', 'Buffalo Wild Wings', 1, '720 cal. 10 bone-in traditional wings, naked/plain.', TRUE),

-- BWW Blazin' Wings 6pc: 440 cal, 50P, 4C, 24F (234g)
('bww_blazin_6pc', 'Buffalo Wild Wings Blazin'' Wings 6pc', 188, 21.4, 1.7, 10.3,
 0.0, 1.0, 234, 39,
 'manufacturer', ARRAY['bww blazin wings 6', 'buffalo wild wings blazin 6', 'bdubs blazin wings', 'blazin wings bww'],
 'wings', 'Buffalo Wild Wings', 1, '440 cal. 6 bone-in wings in Blazin'' sauce, the hottest option. Challenge-level heat.', TRUE),

-- BWW Wild Wings 6pc: 440 cal, 50P, 2C, 25F (234g)
('bww_wild_6pc', 'Buffalo Wild Wings Wild Wings 6pc', 188, 21.4, 0.9, 10.7,
 0.0, 0.5, 234, 39,
 'manufacturer', ARRAY['bww wild wings 6', 'buffalo wild wings wild 6', 'bdubs wild wings', 'wild sauce bww'],
 'wings', 'Buffalo Wild Wings', 1, '440 cal. 6 bone-in wings in BWW signature Wild sauce.', TRUE),

-- BWW Mango Habanero Wings 6pc: 480 cal, 50P, 12C, 24F (240g)
('bww_mango_habanero_6pc', 'Buffalo Wild Wings Mango Habanero Wings 6pc', 200, 20.8, 5.0, 10.0,
 0.0, 4.0, 240, 40,
 'manufacturer', ARRAY['bww mango habanero 6', 'buffalo wild wings mango habanero 6', 'bdubs mango habanero', 'mango habanero wings bww'],
 'wings', 'Buffalo Wild Wings', 1, '480 cal. 6 bone-in wings in sweet and spicy mango habanero sauce.', TRUE),

-- BWW Asian Zing Wings 6pc: 470 cal, 50P, 10C, 24F (240g)
('bww_asian_zing_6pc', 'Buffalo Wild Wings Asian Zing Wings 6pc', 196, 20.8, 4.2, 10.0,
 0.0, 3.5, 240, 40,
 'manufacturer', ARRAY['bww asian zing 6', 'buffalo wild wings asian zing 6', 'bdubs asian zing', 'asian zing wings bww'],
 'wings', 'Buffalo Wild Wings', 1, '470 cal. 6 bone-in wings in Asian Zing sweet chili-soy glaze.', TRUE),

-- BWW Honey BBQ Wings 6pc: 480 cal, 50P, 14C, 24F (240g)
('bww_honey_bbq_6pc', 'Buffalo Wild Wings Honey BBQ Wings 6pc', 200, 20.8, 5.8, 10.0,
 0.0, 5.0, 240, 40,
 'manufacturer', ARRAY['bww honey bbq 6', 'buffalo wild wings honey bbq 6', 'bdubs honey bbq', 'honey bbq wings bww'],
 'wings', 'Buffalo Wild Wings', 1, '480 cal. 6 bone-in wings glazed in sweet honey BBQ sauce.', TRUE),

-- BWW Parmesan Garlic Wings 6pc: 490 cal, 50P, 4C, 30F (240g)
('bww_parmesan_garlic_6pc', 'Buffalo Wild Wings Parmesan Garlic Wings 6pc', 204, 20.8, 1.7, 12.5,
 0.0, 0.5, 240, 40,
 'manufacturer', ARRAY['bww parmesan garlic 6', 'buffalo wild wings parmesan garlic 6', 'bdubs parm garlic', 'parmesan garlic wings bww'],
 'wings', 'Buffalo Wild Wings', 1, '490 cal. 6 bone-in wings in buttery parmesan garlic sauce.', TRUE),

-- BWW Boneless Wings 8pc: 580 cal, 30P, 44C, 32F (250g)
('bww_boneless_8pc', 'Buffalo Wild Wings Boneless Wings 8pc', 232, 12.0, 17.6, 12.8,
 0.5, 2.0, 250, 31,
 'manufacturer', ARRAY['bww boneless 8', 'buffalo wild wings boneless 8', 'bdubs boneless wings', 'boneless wings bww 8pc'],
 'wings', 'Buffalo Wild Wings', 1, '580 cal. 8 boneless wings, breaded and fried with choice of sauce.', TRUE),

-- BWW Mozzarella Sticks: 720 cal, 32P, 60C, 40F (300g)
('bww_mozzarella_sticks', 'Buffalo Wild Wings Mozzarella Sticks', 240, 10.7, 20.0, 13.3,
 0.7, 2.5, 300, NULL,
 'manufacturer', ARRAY['bww mozz sticks', 'buffalo wild wings mozzarella sticks', 'bdubs mozzarella sticks', 'bww cheese sticks'],
 'appetizers', 'Buffalo Wild Wings', 1, '720 cal. Crispy breaded mozzarella sticks with marinara dipping sauce.', TRUE),

-- BWW Loaded Tots: 960 cal, 32P, 72C, 60F (400g)
('bww_loaded_tots', 'Buffalo Wild Wings Loaded Tots', 240, 8.0, 18.0, 15.0,
 2.0, 1.5, 400, NULL,
 'manufacturer', ARRAY['bww loaded tots', 'buffalo wild wings loaded tots', 'bdubs loaded tots', 'loaded tater tots bww'],
 'appetizers', 'Buffalo Wild Wings', 1, '960 cal. Crispy tater tots loaded with cheese, bacon, sour cream, green onions.', TRUE),

-- ══════════════════════════════════════════
-- RAISING CANE'S
-- ══════════════════════════════════════════

-- Raising Cane's The Box Combo: 1250 cal, 48P, 117C, 65F (550g)
('raising_canes_box_combo', 'Raising Cane''s The Box Combo', 227, 8.7, 21.3, 11.8,
 1.5, 2.0, 550, NULL,
 'manufacturer', ARRAY['raising canes box combo', 'canes box combo', 'raising canes the box', 'canes box meal'],
 'combo_meals', 'Raising Cane''s', 1, '1250 cal. 4 chicken fingers, crinkle-cut fries, Texas toast, coleslaw, Cane''s sauce, regular drink.', TRUE),

-- Raising Cane's 3 Finger Combo: 880 cal, 32P, 82C, 46F (400g)
('raising_canes_3_finger_combo', 'Raising Cane''s 3 Finger Combo', 220, 8.0, 20.5, 11.5,
 1.2, 2.0, 400, NULL,
 'manufacturer', ARRAY['raising canes 3 finger combo', 'canes 3 finger combo', 'canes 3 finger meal'],
 'combo_meals', 'Raising Cane''s', 1, '880 cal. 3 chicken fingers, crinkle-cut fries, Texas toast, Cane''s sauce, regular drink.', TRUE),

-- Raising Cane's Caniac Combo: 1720 cal, 68P, 152C, 96F (720g)
('raising_canes_caniac_combo', 'Raising Cane''s Caniac Combo', 239, 9.4, 21.1, 13.3,
 1.5, 2.5, 720, NULL,
 'manufacturer', ARRAY['raising canes caniac combo', 'canes caniac', 'caniac combo', 'raising canes caniac'],
 'combo_meals', 'Raising Cane''s', 1, '1720 cal. 6 chicken fingers, crinkle-cut fries, 2 Cane''s sauces, Texas toast, coleslaw, large drink. The biggest combo.', TRUE),

-- Raising Cane's Chicken Finger (1pc): 130 cal, 10P, 6C, 7F (43g)
('raising_canes_chicken_finger', 'Raising Cane''s Chicken Finger (1pc)', 302, 23.3, 14.0, 16.3,
 0.2, 0.3, 43, 43,
 'manufacturer', ARRAY['raising canes chicken finger', 'canes chicken finger', 'canes finger', 'raising canes tender'],
 'chicken', 'Raising Cane''s', 1, '130 cal per finger. Premium chicken tenderloin, marinated and hand-battered.', TRUE),

-- Raising Cane's Texas Toast (1 slice): 150 cal, 3P, 16C, 8F (42g)
('raising_canes_texas_toast', 'Raising Cane''s Texas Toast (1 slice)', 357, 7.1, 38.1, 19.0,
 0.5, 2.0, 42, 42,
 'manufacturer', ARRAY['raising canes texas toast', 'canes texas toast', 'canes toast', 'raising canes bread'],
 'sides', 'Raising Cane''s', 1, '150 cal per slice. Thick-cut garlic buttered Texas toast, grilled golden.', TRUE),

-- Raising Cane's Coleslaw: 180 cal, 1P, 14C, 14F (110g)
('raising_canes_coleslaw', 'Raising Cane''s Coleslaw', 164, 0.9, 12.7, 12.7,
 1.0, 9.0, 110, NULL,
 'manufacturer', ARRAY['raising canes coleslaw', 'canes coleslaw', 'canes slaw', 'raising canes cole slaw'],
 'sides', 'Raising Cane''s', 1, '180 cal. Creamy, tangy coleslaw with a hint of sweetness.', TRUE),

-- Raising Cane's Crinkle-Cut Fries: 320 cal, 4P, 42C, 16F (130g)
('raising_canes_fries', 'Raising Cane''s Crinkle-Cut Fries', 246, 3.1, 32.3, 12.3,
 2.5, 0.2, 130, NULL,
 'manufacturer', ARRAY['raising canes fries', 'canes fries', 'canes crinkle cut fries', 'raising canes french fries'],
 'sides', 'Raising Cane''s', 1, '320 cal. Crinkle-cut fries, golden and crispy.', TRUE),

-- Raising Cane's Sauce (1 cup): 190 cal, 1P, 7C, 18F (28g)
('raising_canes_sauce', 'Raising Cane''s Sauce (1 cup)', 679, 3.6, 25.0, 64.3,
 0.0, 5.0, 28, 28,
 'manufacturer', ARRAY['canes sauce', 'raising canes sauce', 'canes dipping sauce', 'raising canes cane sauce'],
 'condiments', 'Raising Cane''s', 1, '190 cal per cup. Tangy, slightly spicy signature sauce. Addictively good.', TRUE),

-- ══════════════════════════════════════════
-- ZAXBY'S
-- ══════════════════════════════════════════

-- Zaxby's Chicken Fingerz 5pc: 540 cal, 38P, 19C, 34F (200g)
('zaxbys_chicken_fingerz_5pc', 'Zaxby''s Chicken Fingerz 5pc', 270, 19.0, 9.5, 17.0,
 0.5, 0.5, 200, 40,
 'manufacturer', ARRAY['zaxbys chicken fingerz 5', 'zaxby chicken fingers 5', 'zaxbys fingerz 5pc', 'zaxbys 5 piece fingerz'],
 'chicken', 'Zaxby''s', 1, '540 cal. 5 hand-breaded chicken fingerz. Just the fingers, no sides.', TRUE),

-- Zaxby's Chicken Fingerz 8pc: 860 cal, 61P, 30C, 54F (320g)
('zaxbys_chicken_fingerz_8pc', 'Zaxby''s Chicken Fingerz 8pc', 269, 19.1, 9.4, 16.9,
 0.5, 0.5, 320, 40,
 'manufacturer', ARRAY['zaxbys chicken fingerz 8', 'zaxby chicken fingers 8', 'zaxbys fingerz 8pc', 'zaxbys 8 piece fingerz'],
 'chicken', 'Zaxby''s', 1, '860 cal. 8 hand-breaded chicken fingerz. Just the fingers, no sides.', TRUE),

-- Zaxby's Wings & Things: 980 cal, 58P, 50C, 58F (380g)
('zaxbys_wings_and_things', 'Zaxby''s Wings & Things', 258, 15.3, 13.2, 15.3,
 1.0, 1.0, 380, NULL,
 'manufacturer', ARRAY['zaxbys wings and things', 'zaxby wings things', 'zaxbys wings n things'],
 'combo_meals', 'Zaxby''s', 1, '980 cal. Combination of chicken fingerz and traditional wings with fries, Texas toast, Zax sauce.', TRUE),

-- Zaxby's Boneless Wings 6pc: 490 cal, 26P, 28C, 30F (190g)
('zaxbys_boneless_wings_6pc', 'Zaxby''s Boneless Wings 6pc', 258, 13.7, 14.7, 15.8,
 0.5, 1.0, 190, 32,
 'manufacturer', ARRAY['zaxbys boneless wings 6', 'zaxby boneless 6', 'zaxbys boneless 6pc'],
 'wings', 'Zaxby''s', 1, '490 cal. 6 boneless wing pieces, breaded, fried, tossed in choice of sauce.', TRUE),

-- Zaxby's Crinkle Fries Regular: 350 cal, 4P, 44C, 18F (140g)
('zaxbys_fries', 'Zaxby''s Crinkle Fries (Regular)', 250, 2.9, 31.4, 12.9,
 2.5, 0.2, 140, NULL,
 'manufacturer', ARRAY['zaxbys fries', 'zaxby fries', 'zaxbys crinkle fries', 'zaxbys french fries'],
 'sides', 'Zaxby''s', 1, '350 cal. Crinkle-cut fries, regular size.', TRUE),

-- ══════════════════════════════════════════
-- CHURCH'S CHICKEN
-- ══════════════════════════════════════════

-- Church's Spicy Chicken Sandwich: 490 cal, 22P, 42C, 25F (200g)
('churchs_spicy_chicken_sandwich', 'Church''s Spicy Chicken Sandwich', 245, 11.0, 21.0, 12.5,
 1.0, 3.0, 200, 200,
 'manufacturer', ARRAY['churchs spicy chicken sandwich', 'church chicken spicy sandwich', 'churchs chicken sandwich spicy'],
 'sandwiches', 'Church''s Chicken', 1, '490 cal. Spicy crispy chicken fillet with lettuce, mayo on a toasted bun.', TRUE),

-- Church's Original Leg: 110 cal, 10P, 3C, 6F (57g)
('churchs_original_leg', 'Church''s Chicken Original Leg', 193, 17.5, 5.3, 10.5,
 0.0, 0.0, 57, 57,
 'manufacturer', ARRAY['churchs chicken leg', 'church chicken original leg', 'churchs leg original'],
 'chicken', 'Church''s Chicken', 1, '110 cal per leg. Classic hand-battered and fried chicken drumstick.', TRUE),

-- Church's Original Thigh: 230 cal, 15P, 7C, 16F (102g)
('churchs_original_thigh', 'Church''s Chicken Original Thigh', 225, 14.7, 6.9, 15.7,
 0.0, 0.0, 102, 102,
 'manufacturer', ARRAY['churchs chicken thigh', 'church chicken original thigh', 'churchs thigh original'],
 'chicken', 'Church''s Chicken', 1, '230 cal per thigh. Hand-battered and fried bone-in chicken thigh.', TRUE),

-- Church's Original Breast: 300 cal, 28P, 10C, 17F (150g)
('churchs_original_breast', 'Church''s Chicken Original Breast', 200, 18.7, 6.7, 11.3,
 0.0, 0.0, 150, 150,
 'manufacturer', ARRAY['churchs chicken breast', 'church chicken original breast', 'churchs breast original'],
 'chicken', 'Church''s Chicken', 1, '300 cal per breast. Hand-battered and fried bone-in chicken breast.', TRUE),

-- Church's Original Wing: 160 cal, 10P, 5C, 11F (60g)
('churchs_original_wing', 'Church''s Chicken Original Wing', 267, 16.7, 8.3, 18.3,
 0.0, 0.0, 60, 60,
 'manufacturer', ARRAY['churchs chicken wing', 'church chicken original wing', 'churchs wing original'],
 'chicken', 'Church''s Chicken', 1, '160 cal per wing. Hand-battered and fried chicken wing.', TRUE),

-- Church's Tender Strip (1pc): 120 cal, 8P, 6C, 7F (42g)
('churchs_tender_strip', 'Church''s Chicken Tender Strip (1pc)', 286, 19.0, 14.3, 16.7,
 0.2, 0.3, 42, 42,
 'manufacturer', ARRAY['churchs tender strip', 'church chicken tender', 'churchs chicken strip', 'churchs tender'],
 'chicken', 'Church''s Chicken', 1, '120 cal per strip. Hand-battered chicken tender strip.', TRUE),

-- Church's Honey Biscuit: 180 cal, 3P, 22C, 9F (56g)
('churchs_honey_biscuit', 'Church''s Chicken Honey Biscuit', 321, 5.4, 39.3, 16.1,
 0.5, 5.0, 56, 56,
 'manufacturer', ARRAY['churchs honey biscuit', 'church chicken biscuit', 'churchs biscuit', 'churchs honey butter biscuit'],
 'sides', 'Church''s Chicken', 1, '180 cal per biscuit. Fluffy buttermilk biscuit with a touch of honey.', TRUE),

-- Church's Fried Okra (Regular): 210 cal, 3P, 24C, 12F (90g)
('churchs_fried_okra', 'Church''s Chicken Fried Okra (Regular)', 233, 3.3, 26.7, 13.3,
 2.0, 1.0, 90, NULL,
 'manufacturer', ARRAY['churchs fried okra', 'church chicken okra', 'churchs okra'],
 'sides', 'Church''s Chicken', 1, '210 cal. Battered and fried okra, regular side.', TRUE),

-- Church's Corn on the Cob: 140 cal, 4P, 24C, 3F (140g)
('churchs_corn_cob', 'Church''s Chicken Corn on the Cob', 100, 2.9, 17.1, 2.1,
 2.5, 4.0, 140, 140,
 'manufacturer', ARRAY['churchs corn on the cob', 'church chicken corn', 'churchs corn'],
 'sides', 'Church''s Chicken', 1, '140 cal. Whole ear of sweet corn with butter.', TRUE),

-- Church's Jalapeno Cheese Bombers (4pc): 240 cal, 8P, 28C, 12F (100g)
('churchs_jalapeno_cheese_bombers', 'Church''s Chicken Jalapeno Cheese Bombers (4pc)', 240, 8.0, 28.0, 12.0,
 1.0, 2.0, 100, 25,
 'manufacturer', ARRAY['churchs jalapeno cheese bombers', 'church chicken bombers', 'churchs cheese bombers', 'jalapeno bombers churchs'],
 'appetizers', 'Church''s Chicken', 1, '240 cal for 4pc. Crispy breaded jalapeno peppers stuffed with cream cheese.', TRUE),

-- ══════════════════════════════════════════
-- HIDDEN / SECRET MENU ITEMS
-- ══════════════════════════════════════════

-- === CHIPOTLE SECRET MENU ===

-- Chipotle Quesarito: 1000 cal, 48P, 90C, 48F (450g)
('chipotle_quesarito', 'Chipotle Quesarito', 222, 10.7, 20.0, 10.7,
 3.0, 2.0, 450, NULL,
 'manufacturer', ARRAY['chipotle quesarito', 'quesarito chipotle', 'chipotle secret menu quesarito', 'chipotle burrito quesadilla'],
 'burritos', 'Chipotle', 1, '~1000 cal. Secret menu item: burrito wrapped inside a cheese quesadilla. Must request specifically.', TRUE),

-- Chipotle Burritodilla: 800 cal, 38P, 68C, 40F (350g)
('chipotle_burritodilla', 'Chipotle Burritodilla', 229, 10.9, 19.4, 11.4,
 2.5, 1.5, 350, NULL,
 'manufacturer', ARRAY['chipotle burritodilla', 'burritodilla chipotle', 'chipotle secret burritodilla'],
 'burritos', 'Chipotle', 1, '~800 cal. Secret menu: quesadilla folded burrito-style with fillings inside. Ask nicely.', TRUE),

-- Chipotle Nachos: 770 cal, 32P, 62C, 44F (380g)
('chipotle_nachos', 'Chipotle Nachos', 203, 8.4, 16.3, 11.6,
 3.0, 1.5, 380, NULL,
 'manufacturer', ARRAY['chipotle nachos', 'nachos chipotle', 'chipotle secret nachos', 'chipotle chips nachos'],
 'appetizers', 'Chipotle', 1, '~770 cal. Secret menu: tortilla chips topped with your choice of protein, cheese, salsa, guac.', TRUE),

-- Chipotle Dragon Sauce: 50 cal, 0P, 4C, 4F (28g)
('chipotle_dragon_sauce', 'Chipotle Dragon Sauce', 179, 0.0, 14.3, 14.3,
 0.0, 7.0, 28, 28,
 'manufacturer', ARRAY['chipotle dragon sauce', 'dragon sauce chipotle', 'chipotle secret sauce dragon'],
 'condiments', 'Chipotle', 1, '~50 cal per portion. Secret menu: mix of hot salsa + sour cream for a spicy-creamy dip.', TRUE),

-- === STARBUCKS SECRET MENU ===

-- Starbucks Medicine Ball (Honey Citrus Mint Tea) Grande: 130 cal, 0P, 33C, 0F (473g)
('starbucks_medicine_ball', 'Starbucks Medicine Ball (Grande)', 27, 0.0, 7.0, 0.0,
 0.0, 6.5, 473, NULL,
 'manufacturer', ARRAY['starbucks medicine ball', 'medicine ball starbucks', 'honey citrus mint tea', 'starbucks cold buster', 'starbucks sick tea'],
 'beverages', 'Starbucks', 1, '130 cal. Jade Citrus Mint + Peach Tranquility teas with steamed lemonade and honey. Soothing when sick.', TRUE),

-- Starbucks Cotton Candy Frappuccino Grande: 420 cal, 5P, 65C, 16F (473g)
('starbucks_cotton_candy_frapp', 'Starbucks Cotton Candy Frappuccino (Grande)', 89, 1.1, 13.7, 3.4,
 0.0, 12.0, 473, NULL,
 'manufacturer', ARRAY['starbucks cotton candy frapp', 'cotton candy frappuccino', 'starbucks cotton candy', 'cotton candy frapp starbucks'],
 'beverages', 'Starbucks', 1, '~420 cal. Secret menu: Vanilla Bean Frapp + raspberry syrup. Tastes like cotton candy.', TRUE),

-- Starbucks Purple Drink Grande: 180 cal, 1P, 38C, 4F (473g)
('starbucks_purple_drink', 'Starbucks Purple Drink (Grande)', 38, 0.2, 8.0, 0.8,
 0.0, 7.0, 473, NULL,
 'manufacturer', ARRAY['starbucks purple drink', 'purple drink starbucks', 'starbucks violet drink', 'violet drink starbucks'],
 'beverages', 'Starbucks', 1, '180 cal. Very Berry Hibiscus + coconut milk instead of water. Sweet, fruity, Instagram-famous.', TRUE),

-- Starbucks Butterbeer Frappuccino Grande: 460 cal, 5P, 72C, 18F (473g)
('starbucks_butterbeer_frapp', 'Starbucks Butterbeer Frappuccino (Grande)', 97, 1.1, 15.2, 3.8,
 0.0, 13.0, 473, NULL,
 'manufacturer', ARRAY['starbucks butterbeer frapp', 'butterbeer frappuccino', 'starbucks butterbeer', 'harry potter frapp starbucks'],
 'beverages', 'Starbucks', 1, '~460 cal. Secret menu: Caramel Frapp + toffee nut + caramel drizzle. Harry Potter-inspired.', TRUE),

-- === IN-N-OUT SECRET MENU ===

-- In-N-Out Flying Dutchman: 330 cal, 18P, 1C, 25F (115g)
('in_n_out_flying_dutchman', 'In-N-Out Flying Dutchman', 287, 15.7, 0.9, 21.7,
 0.0, 0.0, 115, 115,
 'manufacturer', ARRAY['in n out flying dutchman', 'flying dutchman in n out', 'flying dutchman', 'in and out flying dutchman'],
 'burgers', 'In-N-Out', 1, '330 cal. Secret menu: 2 beef patties with 2 slices of melted cheese, no bun. Ultra low-carb.', TRUE),

-- In-N-Out Neapolitan Shake: 680 cal, 12P, 86C, 33F (420g)
('in_n_out_neapolitan_shake', 'In-N-Out Neapolitan Shake', 162, 2.9, 20.5, 7.9,
 0.0, 17.0, 420, NULL,
 'manufacturer', ARRAY['in n out neapolitan shake', 'neapolitan shake in n out', 'in and out neapolitan milkshake', 'in n out 3 flavor shake'],
 'beverages', 'In-N-Out', 1, '~680 cal. Secret menu: chocolate + vanilla + strawberry mixed shake. The best of all three.', TRUE),

-- In-N-Out Root Beer Float: 350 cal, 4P, 56C, 13F (450g)
('in_n_out_root_beer_float', 'In-N-Out Root Beer Float', 78, 0.9, 12.4, 2.9,
 0.0, 11.0, 450, NULL,
 'manufacturer', ARRAY['in n out root beer float', 'root beer float in n out', 'in and out float', 'in n out ice cream float'],
 'beverages', 'In-N-Out', 1, '~350 cal. Secret menu: vanilla ice cream scooped into root beer. Classic soda fountain treat.', TRUE),

-- === McDONALD'S SECRET MENU ===

-- McDonald's McGangBang: 590 cal, 30P, 50C, 30F (260g)
('mcdonalds_mcgangbang', 'McDonald''s McGangBang', 227, 11.5, 19.2, 11.5,
 1.5, 4.0, 260, NULL,
 'manufacturer', ARRAY['mcdonalds mcgangbang', 'mcgangbang', 'mcdonald mcgangbang', 'mcdouble mcchicken combo'],
 'burgers', 'McDonald''s', 1, '~590 cal. Secret menu: McChicken sandwich placed inside a McDouble. A cult classic mashup.', TRUE),

-- McDonald's Land Sea & Air Burger: 900 cal, 55P, 70C, 44F (430g)
('mcdonalds_land_sea_air', 'McDonald''s Land Sea & Air Burger', 209, 12.8, 16.3, 10.2,
 1.5, 4.0, 430, NULL,
 'manufacturer', ARRAY['mcdonalds land sea air', 'land sea and air burger', 'mcdonald land sea air', 'mcdonalds surf turf sky'],
 'burgers', 'McDonald''s', 1, '~900 cal. Secret menu: Big Mac + Filet-O-Fish patty + McChicken patty stacked together. Ridiculous.', TRUE),

-- McDonald's Poor Man's Big Mac: 500 cal, 26P, 37C, 27F (200g)
('mcdonalds_poor_mans_big_mac', 'McDonald''s Poor Man''s Big Mac', 250, 13.0, 18.5, 13.5,
 1.5, 4.0, 200, 200,
 'manufacturer', ARRAY['poor mans big mac', 'mcdonalds poor mans big mac', 'mcdonald poor man big mac', 'budget big mac'],
 'burgers', 'McDonald''s', 1, '~500 cal. Secret menu: McDouble with Big Mac sauce, extra lettuce, no ketchup/mustard. Tastes like a Big Mac for less.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL IHOP ITEMS
-- ══════════════════════════════════════════

-- IHOP Big Steak Omelette: 1100 cal, 58P, 20C, 88F (420g)
('ihop_big_steak_omelette', 'IHOP Big Steak Omelette', 262, 13.8, 4.8, 21.0,
 0.3, 1.5, 420, NULL,
 'manufacturer', ARRAY['ihop big steak omelette', 'big steak omelette ihop', 'ihop steak omelette'],
 'breakfast', 'IHOP', 1, '1100 cal. Steak, onions, peppers, mushrooms, tomatoes with Jack and cheddar cheese.', TRUE),

-- IHOP Crispy Chicken Strips: 580 cal, 32P, 38C, 32F (240g)
('ihop_crispy_chicken_strips', 'IHOP Crispy Chicken Strips', 242, 13.3, 15.8, 13.3,
 0.5, 1.5, 240, NULL,
 'manufacturer', ARRAY['ihop chicken strips', 'ihop crispy chicken strips', 'ihop chicken tenders'],
 'chicken', 'IHOP', 1, '580 cal. Hand-breaded chicken breast strips with ranch or honey mustard.', TRUE),

-- IHOP Onion Rings: 510 cal, 8P, 58C, 28F (200g)
('ihop_onion_rings', 'IHOP Onion Rings', 255, 4.0, 29.0, 14.0,
 2.0, 4.0, 200, NULL,
 'manufacturer', ARRAY['ihop onion rings', 'onion rings ihop'],
 'appetizers', 'IHOP', 1, '510 cal. Beer-battered onion rings with tangy dipping sauce.', TRUE),

-- IHOP Loaded Waffle Fries: 620 cal, 16P, 52C, 38F (280g)
('ihop_loaded_waffle_fries', 'IHOP Loaded Waffle Fries', 221, 5.7, 18.6, 13.6,
 1.5, 1.5, 280, NULL,
 'manufacturer', ARRAY['ihop loaded waffle fries', 'ihop waffle fries', 'loaded fries ihop'],
 'appetizers', 'IHOP', 1, '620 cal. Waffle fries loaded with cheese sauce, bacon, sour cream.', TRUE),

-- IHOP Ham & Cheese Omelette: 560 cal, 36P, 10C, 42F (310g)
('ihop_ham_cheese_omelette', 'IHOP Ham & Cheese Omelette', 181, 11.6, 3.2, 13.5,
 0.2, 1.0, 310, NULL,
 'manufacturer', ARRAY['ihop ham cheese omelette', 'ham and cheese omelette ihop', 'ihop ham omelette'],
 'breakfast', 'IHOP', 1, '560 cal. Three-egg omelette with diced ham, Swiss and American cheese.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL WAFFLE HOUSE ITEMS
-- ══════════════════════════════════════════

-- Waffle House Grilled Chicken Sandwich: 390 cal, 32P, 30C, 14F (220g)
('waffle_house_grilled_chicken', 'Waffle House Grilled Chicken Sandwich', 177, 14.5, 13.6, 6.4,
 1.0, 2.0, 220, 220,
 'manufacturer', ARRAY['waffle house grilled chicken', 'waffle house chicken sandwich', 'grilled chicken waffle house'],
 'sandwiches', 'Waffle House', 1, '390 cal. Springer Mountain Farms grilled chicken breast with lettuce, tomato on a toasted bun.', TRUE),

-- Waffle House Bacon Egg Cheese Sandwich: 480 cal, 22P, 28C, 31F (180g)
('waffle_house_bacon_egg_cheese', 'Waffle House Bacon Egg & Cheese Sandwich', 267, 12.2, 15.6, 17.2,
 0.3, 2.0, 180, 180,
 'manufacturer', ARRAY['waffle house bacon egg cheese', 'waffle house breakfast sandwich bacon', 'bacon egg cheese waffle house'],
 'breakfast', 'Waffle House', 1, '480 cal. Bacon, egg, and American cheese on Texas toast or biscuit.', TRUE),

-- Waffle House Hashbrowns Scattered Smothered Covered: 420 cal, 10P, 30C, 30F (200g)
('waffle_house_hashbrowns_smc', 'Waffle House Hashbrowns (Scattered, Smothered, Covered)', 210, 5.0, 15.0, 15.0,
 1.5, 0.5, 200, NULL,
 'manufacturer', ARRAY['waffle house hashbrowns smothered covered', 'scattered smothered covered', 'waffle house smc hashbrowns', 'hashbrowns smothered covered waffle house'],
 'sides', 'Waffle House', 1, '420 cal. Hashbrowns scattered on grill, smothered with onions, covered with cheese.', TRUE),

-- Waffle House Double Hash Brown Bowl: 560 cal, 28P, 34C, 36F (320g)
('waffle_house_double_hash_bowl', 'Waffle House Double Hash Brown Bowl', 175, 8.8, 10.6, 11.3,
 1.0, 1.0, 320, NULL,
 'manufacturer', ARRAY['waffle house hash brown bowl', 'waffle house double hash bowl', 'hash brown bowl waffle house'],
 'combo_meals', 'Waffle House', 1, '560 cal. Double hashbrowns loaded with choice of meat, cheese, eggs.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL DENNY'S ITEMS
-- ══════════════════════════════════════════

-- Denny's Cinnamon Roll Pancakes: 860 cal, 16P, 112C, 40F (380g)
('dennys_cinnamon_roll_pancakes', 'Denny''s Cinnamon Roll Pancakes', 226, 4.2, 29.5, 10.5,
 0.5, 18.0, 380, NULL,
 'manufacturer', ARRAY['dennys cinnamon roll pancakes', 'denny cinnamon pancakes', 'cinnamon roll pancakes dennys'],
 'breakfast', 'Denny''s', 1, '860 cal. Pancakes swirled with cinnamon, topped with cream cheese icing.', TRUE),

-- Denny's Slam Burger: 820 cal, 44P, 48C, 50F (350g)
('dennys_slam_burger', 'Denny''s Slam Burger', 234, 12.6, 13.7, 14.3,
 1.0, 3.5, 350, 350,
 'manufacturer', ARRAY['dennys slam burger', 'denny slam burger', 'dennys burger'],
 'burgers', 'Denny''s', 1, '820 cal. Beef patty topped with bacon, fried egg, American cheese on a brioche bun.', TRUE),

-- Denny's All-American Slam: 730 cal, 36P, 48C, 44F (400g)
('dennys_all_american_slam', 'Denny''s All-American Slam', 183, 9.0, 12.0, 11.0,
 0.7, 3.5, 400, NULL,
 'manufacturer', ARRAY['dennys all american slam', 'denny all american slam', 'all american slam dennys'],
 'breakfast', 'Denny''s', 1, '730 cal. Eggs, bacon, sausage, hashbrowns, 2 buttermilk pancakes.', TRUE),

-- Denny's French Toast Slam: 680 cal, 22P, 70C, 34F (350g)
('dennys_french_toast_slam', 'Denny''s French Toast Slam', 194, 6.3, 20.0, 9.7,
 0.5, 8.0, 350, NULL,
 'manufacturer', ARRAY['dennys french toast slam', 'denny french toast slam', 'french toast slam dennys'],
 'breakfast', 'Denny''s', 1, '680 cal. French toast, eggs, bacon or sausage.', TRUE),

-- Denny's Super Bird Sandwich: 630 cal, 38P, 36C, 36F (300g)
('dennys_super_bird', 'Denny''s Super Bird Sandwich', 210, 12.7, 12.0, 12.0,
 1.0, 2.5, 300, 300,
 'manufacturer', ARRAY['dennys super bird', 'denny super bird', 'super bird sandwich dennys'],
 'sandwiches', 'Denny''s', 1, '630 cal. Sliced turkey, bacon, Swiss cheese, tomato on sourdough bread.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL CRACKER BARREL ITEMS
-- ══════════════════════════════════════════

-- Cracker Barrel Sunrise Sampler: 740 cal, 30P, 52C, 46F (380g)
('cracker_barrel_sunrise_sampler', 'Cracker Barrel Sunrise Sampler', 195, 7.9, 13.7, 12.1,
 0.5, 2.0, 380, NULL,
 'manufacturer', ARRAY['cracker barrel sunrise sampler', 'sunrise sampler cracker barrel'],
 'breakfast', 'Cracker Barrel', 1, '740 cal. Eggs, fried apples, bacon or sausage, grits, biscuits.', TRUE),

-- Cracker Barrel Pancakes (3 Buttermilk): 410 cal, 10P, 60C, 14F (250g)
('cracker_barrel_pancakes', 'Cracker Barrel Buttermilk Pancakes (3)', 164, 4.0, 24.0, 5.6,
 0.5, 6.0, 250, NULL,
 'manufacturer', ARRAY['cracker barrel pancakes', 'cracker barrel buttermilk pancakes', 'pancakes cracker barrel'],
 'breakfast', 'Cracker Barrel', 1, '410 cal. Three fluffy buttermilk pancakes with butter.', TRUE),

-- Cracker Barrel Grilled Chicken Tenders: 340 cal, 40P, 8C, 16F (200g)
('cracker_barrel_grilled_chicken_tenders', 'Cracker Barrel Grilled Chicken Tenders', 170, 20.0, 4.0, 8.0,
 0.0, 0.5, 200, NULL,
 'manufacturer', ARRAY['cracker barrel grilled chicken tenders', 'grilled chicken tenders cracker barrel', 'cracker barrel chicken tenders grilled'],
 'chicken', 'Cracker Barrel', 1, '340 cal. Grilled chicken tenderloins, without sides. A lighter entree choice.', TRUE),

-- Cracker Barrel Country Fried Chicken: 560 cal, 30P, 30C, 36F (260g)
('cracker_barrel_country_fried_chicken', 'Cracker Barrel Country Fried Chicken', 215, 11.5, 11.5, 13.8,
 0.5, 1.0, 260, NULL,
 'manufacturer', ARRAY['cracker barrel country fried chicken', 'fried chicken cracker barrel', 'cracker barrel chicken fried'],
 'chicken', 'Cracker Barrel', 1, '560 cal. Hand-breaded country fried chicken with gravy. Without sides.', TRUE),

-- Cracker Barrel Fried Apples: 200 cal, 0P, 42C, 4F (150g)
('cracker_barrel_fried_apples', 'Cracker Barrel Fried Apples', 133, 0.0, 28.0, 2.7,
 2.0, 22.0, 150, NULL,
 'manufacturer', ARRAY['cracker barrel fried apples', 'fried apples cracker barrel', 'cracker barrel apples'],
 'sides', 'Cracker Barrel', 1, '200 cal. Sweet cinnamon-spiced fried apple slices. Southern comfort side.', TRUE),

-- Cracker Barrel Mac n Cheese: 300 cal, 12P, 28C, 16F (170g)
('cracker_barrel_mac_cheese', 'Cracker Barrel Mac n Cheese', 176, 7.1, 16.5, 9.4,
 0.5, 2.0, 170, NULL,
 'manufacturer', ARRAY['cracker barrel mac and cheese', 'cracker barrel mac n cheese', 'mac cheese cracker barrel'],
 'sides', 'Cracker Barrel', 1, '300 cal. Homestyle macaroni and cheese, baked.', TRUE),

-- Cracker Barrel Loaded Baked Potato: 350 cal, 10P, 38C, 18F (250g)
('cracker_barrel_loaded_baked_potato', 'Cracker Barrel Loaded Baked Potato', 140, 4.0, 15.2, 7.2,
 2.0, 1.5, 250, NULL,
 'manufacturer', ARRAY['cracker barrel loaded baked potato', 'baked potato cracker barrel', 'cracker barrel potato loaded'],
 'sides', 'Cracker Barrel', 1, '350 cal. Baked potato topped with butter, sour cream, cheese, bacon.', TRUE),

-- Cracker Barrel Pinto Beans: 120 cal, 7P, 20C, 1F (150g)
('cracker_barrel_pinto_beans', 'Cracker Barrel Pinto Beans', 80, 4.7, 13.3, 0.7,
 5.0, 0.5, 150, NULL,
 'manufacturer', ARRAY['cracker barrel pinto beans', 'pinto beans cracker barrel', 'cracker barrel beans'],
 'sides', 'Cracker Barrel', 1, '120 cal. Slow-simmered pinto beans. High fiber, low fat side.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL FIVE GUYS ITEMS
-- ══════════════════════════════════════════

-- Five Guys Little Cheeseburger: 550 cal, 27P, 39C, 32F (213g)
('five_guys_little_cheeseburger', 'Five Guys Little Cheeseburger', 258, 12.7, 18.3, 15.0,
 1.0, 3.5, 213, 213,
 'manufacturer', ARRAY['five guys little cheeseburger', 'five guys little cheese burger', 'little cheeseburger five guys'],
 'burgers', 'Five Guys', 1, '550 cal. Single patty with American cheese on a sesame seed bun.', TRUE),

-- Five Guys Bacon Burger: 780 cal, 41P, 39C, 50F (310g)
('five_guys_bacon_burger', 'Five Guys Bacon Burger', 252, 13.2, 12.6, 16.1,
 1.0, 3.5, 310, 310,
 'manufacturer', ARRAY['five guys bacon burger', 'five guys bacon hamburger', 'bacon burger five guys'],
 'burgers', 'Five Guys', 1, '780 cal. Two hand-formed patties with applewood-smoked bacon.', TRUE),

-- Five Guys Little Bacon Cheeseburger: 630 cal, 30P, 39C, 39F (230g)
('five_guys_little_bacon_cheeseburger', 'Five Guys Little Bacon Cheeseburger', 274, 13.0, 17.0, 17.0,
 1.0, 3.5, 230, 230,
 'manufacturer', ARRAY['five guys little bacon cheeseburger', 'five guys little bacon cheese', 'little bacon cheeseburger five guys'],
 'burgers', 'Five Guys', 1, '630 cal. Single patty with American cheese and applewood-smoked bacon.', TRUE),

-- Five Guys Cheese Dog: 615 cal, 22P, 41C, 40F (200g)
('five_guys_cheese_dog', 'Five Guys Cheese Dog', 308, 11.0, 20.5, 20.0,
 0.5, 3.0, 200, 200,
 'manufacturer', ARRAY['five guys cheese dog', 'five guys cheese hot dog', 'cheese dog five guys'],
 'hot_dogs', 'Five Guys', 1, '615 cal. Kosher hot dog with melted American cheese on a toasted bun.', TRUE),

-- Five Guys Bacon Dog: 640 cal, 24P, 40C, 42F (210g)
('five_guys_bacon_dog', 'Five Guys Bacon Dog', 305, 11.4, 19.0, 20.0,
 0.5, 3.0, 210, 210,
 'manufacturer', ARRAY['five guys bacon dog', 'five guys bacon hot dog', 'bacon dog five guys'],
 'hot_dogs', 'Five Guys', 1, '640 cal. Kosher hot dog wrapped in applewood-smoked bacon.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL SHAKE SHACK ITEMS
-- ══════════════════════════════════════════

-- Shake Shack Double ShackBurger: 770 cal, 46P, 27C, 52F (300g)
('shake_shack_double_shackburger', 'Shake Shack Double ShackBurger', 257, 15.3, 9.0, 17.3,
 0.5, 3.0, 300, 300,
 'manufacturer', ARRAY['double shackburger', 'shake shack double shackburger', 'shake shack double', 'double shack burger'],
 'burgers', 'Shake Shack', 1, '770 cal. Two Angus beef patties with lettuce, tomato, ShackSauce on a potato bun.', TRUE),

-- Shake Shack Double SmokeShack: 930 cal, 56P, 29C, 66F (360g)
('shake_shack_double_smokeshack', 'Shake Shack Double SmokeShack', 258, 15.6, 8.1, 18.3,
 0.5, 3.0, 360, 360,
 'manufacturer', ARRAY['double smokeshack', 'shake shack double smokeshack', 'shake shack double smoke'],
 'burgers', 'Shake Shack', 1, '930 cal. Two beef patties with bacon, cherry peppers, ShackSauce.', TRUE),

-- Shake Shack Shroom Burger: 490 cal, 18P, 41C, 29F (220g)
('shake_shack_shroom_burger', 'Shake Shack ''Shroom Burger', 223, 8.2, 18.6, 13.2,
 1.5, 3.0, 220, 220,
 'manufacturer', ARRAY['shroom burger', 'shake shack shroom burger', 'shake shack mushroom burger', 'shroom burger shake shack'],
 'burgers', 'Shake Shack', 1, '490 cal. Crispy-fried portobello mushroom filled with muenster and cheddar. Vegetarian.', TRUE),

-- Shake Shack Strawberry Shake: 710 cal, 13P, 90C, 34F (480g)
('shake_shack_strawberry_shake', 'Shake Shack Strawberry Shake', 148, 2.7, 18.8, 7.1,
 0.2, 15.5, 480, NULL,
 'manufacturer', ARRAY['shake shack strawberry shake', 'strawberry shake shake shack', 'shake shack strawberry milkshake'],
 'beverages', 'Shake Shack', 1, '710 cal. Hand-spun strawberry frozen custard shake.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL WHATABURGER ITEMS
-- ══════════════════════════════════════════

-- Whataburger Jalape\~{n}o & Cheese Whataburger: 640 cal, 30P, 54C, 34F (295g)
('whataburger_jalapeno_cheese', 'Whataburger Jalapeno & Cheese Whataburger', 217, 10.2, 18.3, 11.5,
 1.0, 5.0, 295, 295,
 'manufacturer', ARRAY['whataburger jalapeno cheese', 'jalapeno cheese whataburger', 'whataburger jalapeno'],
 'burgers', 'Whataburger', 1, '640 cal. Beef patty with jalapenos, cheese, mustard on a toasted bun.', TRUE),

-- Whataburger Avocado Bacon Burger: 710 cal, 34P, 50C, 42F (310g)
('whataburger_avocado_bacon', 'Whataburger Avocado Bacon Burger', 229, 11.0, 16.1, 13.5,
 2.0, 4.5, 310, 310,
 'manufacturer', ARRAY['whataburger avocado bacon', 'avocado bacon burger whataburger', 'whataburger avocado bacon burger'],
 'burgers', 'Whataburger', 1, '710 cal. Beef patty with avocado, bacon, pepper jack cheese, ranch.', TRUE),

-- Whataburger Taquito with Cheese: 370 cal, 14P, 26C, 24F (150g)
('whataburger_taquito_cheese', 'Whataburger Taquito with Cheese', 247, 9.3, 17.3, 16.0,
 0.5, 1.0, 150, 150,
 'manufacturer', ARRAY['whataburger taquito', 'whataburger taquito cheese', 'taquito whataburger'],
 'breakfast', 'Whataburger', 1, '370 cal. Flour tortilla with scrambled eggs and cheese. Whataburger breakfast staple.', TRUE),

-- Whataburger Onion Rings: 420 cal, 5P, 50C, 22F (150g)
('whataburger_onion_rings', 'Whataburger Onion Rings (Medium)', 280, 3.3, 33.3, 14.7,
 2.0, 4.0, 150, NULL,
 'manufacturer', ARRAY['whataburger onion rings', 'onion rings whataburger', 'whataburger rings'],
 'sides', 'Whataburger', 1, '420 cal. Beer-battered onion rings, medium order.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL STEAK 'N SHAKE ITEMS
-- ══════════════════════════════════════════

-- Steak 'n Shake Single Steakburger: 280 cal, 15P, 28C, 12F (145g)
('steak_n_shake_single', 'Steak ''n Shake Single Steakburger', 193, 10.3, 19.3, 8.3,
 0.5, 3.0, 145, 145,
 'manufacturer', ARRAY['steak n shake single steakburger', 'steak and shake single', 'single steakburger steak n shake'],
 'burgers', 'Steak ''n Shake', 1, '280 cal. One thin steakburger patty with mustard, ketchup, pickle, onion on a toasted bun.', TRUE),

-- Steak 'n Shake Triple Steakburger: 610 cal, 36P, 32C, 38F (280g)
('steak_n_shake_triple', 'Steak ''n Shake Triple Steakburger', 218, 12.9, 11.4, 13.6,
 0.5, 3.0, 280, 280,
 'manufacturer', ARRAY['steak n shake triple steakburger', 'steak and shake triple', 'triple steakburger steak n shake'],
 'burgers', 'Steak ''n Shake', 1, '610 cal. Three thin steakburger patties with standard toppings.', TRUE),

-- Steak 'n Shake Bacon 'n Cheese Single: 460 cal, 22P, 30C, 28F (190g)
('steak_n_shake_bacon_cheese_single', 'Steak ''n Shake Bacon ''n Cheese Single', 242, 11.6, 15.8, 14.7,
 0.5, 3.5, 190, 190,
 'manufacturer', ARRAY['steak n shake bacon cheese single', 'bacon cheese steakburger single', 'steak n shake bacon single'],
 'burgers', 'Steak ''n Shake', 1, '460 cal. Single steakburger with applewood bacon and American cheese.', TRUE),

-- Steak 'n Shake Fries: 340 cal, 4P, 44C, 16F (140g)
('steak_n_shake_fries', 'Steak ''n Shake Thin ''n Crispy Fries', 243, 2.9, 31.4, 11.4,
 2.5, 0.2, 140, NULL,
 'manufacturer', ARRAY['steak n shake fries', 'steak and shake fries', 'thin n crispy fries steak n shake'],
 'sides', 'Steak ''n Shake', 1, '340 cal. Thin-cut crispy fries, regular order.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL WINGSTOP ITEMS (count variants)
-- ══════════════════════════════════════════

-- Wingstop Lemon Pepper Wings 10pc: 780 cal, 77P, 4C, 50F (390g)
('wingstop_lemon_pepper_10pc', 'Wingstop Lemon Pepper Wings 10pc', 200, 19.7, 1.0, 12.8,
 0.0, 0.0, 390, 39,
 'manufacturer', ARRAY['wingstop lemon pepper 10', 'wingstop lemon pepper wings 10', 'lemon pepper wings 10 wingstop'],
 'wings', 'Wingstop', 1, '780 cal. 10 bone-in wings tossed in lemon pepper dry rub.', TRUE),

-- Wingstop Garlic Parmesan Wings 10pc: 850 cal, 77P, 6C, 56F (400g)
('wingstop_garlic_parmesan_10pc', 'Wingstop Garlic Parmesan Wings 10pc', 213, 19.3, 1.5, 14.0,
 0.0, 0.5, 400, 40,
 'manufacturer', ARRAY['wingstop garlic parmesan 10', 'wingstop garlic parm wings 10', 'garlic parm 10 wingstop'],
 'wings', 'Wingstop', 1, '850 cal. 10 bone-in wings in garlic parmesan sauce.', TRUE),

-- Wingstop Mango Habanero Wings 10pc: 770 cal, 77P, 14C, 44F (400g)
('wingstop_mango_habanero_10pc', 'Wingstop Mango Habanero Wings 10pc', 193, 19.3, 3.5, 11.0,
 0.0, 2.5, 400, 40,
 'manufacturer', ARRAY['wingstop mango habanero 10', 'wingstop mango habanero wings 10', 'mango habanero 10 wingstop'],
 'wings', 'Wingstop', 1, '770 cal. 10 bone-in wings in mango habanero sauce.', TRUE),

-- Wingstop Atomic Wings 10pc: 750 cal, 77P, 4C, 46F (390g)
('wingstop_atomic_10pc', 'Wingstop Atomic Wings 10pc', 192, 19.7, 1.0, 11.8,
 0.0, 0.5, 390, 39,
 'manufacturer', ARRAY['wingstop atomic 10', 'wingstop atomic wings 10', 'atomic 10 wingstop'],
 'wings', 'Wingstop', 1, '750 cal. 10 bone-in wings in the hottest Atomic sauce.', TRUE),

-- Wingstop Boneless Wings 10pc: 600 cal, 34P, 36C, 36F (284g)
('wingstop_boneless_10pc', 'Wingstop Boneless Wings 10pc', 211, 12.0, 12.7, 12.7,
 0.5, 1.0, 284, 28,
 'manufacturer', ARRAY['wingstop boneless 10', 'wingstop boneless wings 10', 'boneless wingstop 10pc'],
 'wings', 'Wingstop', 1, '600 cal. 10 boneless wing pieces, breaded and fried.', TRUE),

-- Wingstop Cajun Corn: 210 cal, 3P, 26C, 12F (120g)
('wingstop_cajun_corn', 'Wingstop Cajun Fried Corn', 175, 2.5, 21.7, 10.0,
 2.0, 3.0, 120, NULL,
 'manufacturer', ARRAY['wingstop cajun corn', 'wingstop fried corn', 'cajun corn wingstop'],
 'sides', 'Wingstop', 1, '210 cal. Corn on the cob dusted with Cajun seasoning.', TRUE),

-- Wingstop Louisiana Voodoo Fries: 480 cal, 6P, 52C, 28F (200g)
('wingstop_voodoo_fries', 'Wingstop Louisiana Voodoo Fries', 240, 3.0, 26.0, 14.0,
 2.5, 1.0, 200, NULL,
 'manufacturer', ARRAY['wingstop voodoo fries', 'louisiana voodoo fries wingstop', 'wingstop loaded fries'],
 'sides', 'Wingstop', 1, '480 cal. Seasoned fries topped with ranch, cheddar cheese, Cajun seasoning.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL BUFFALO WILD WINGS ITEMS
-- ══════════════════════════════════════════

-- BWW Traditional Wings 15pc Plain: 1080 cal, 124P, 0C, 61F (570g)
('bww_traditional_15pc_plain', 'Buffalo Wild Wings Traditional Wings 15pc (Plain)', 189, 21.8, 0.0, 10.7,
 0.0, 0.0, 570, 38,
 'manufacturer', ARRAY['buffalo wild wings traditional 15', 'bww traditional wings 15', 'bww plain wings 15', 'bdubs traditional 15'],
 'wings', 'Buffalo Wild Wings', 1, '1080 cal. 15 bone-in traditional wings, naked/plain.', TRUE),

-- BWW Traditional Wings 20pc Plain: 1440 cal, 166P, 0C, 82F (760g)
('bww_traditional_20pc_plain', 'Buffalo Wild Wings Traditional Wings 20pc (Plain)', 189, 21.8, 0.0, 10.8,
 0.0, 0.0, 760, 38,
 'manufacturer', ARRAY['buffalo wild wings traditional 20', 'bww traditional wings 20', 'bww plain wings 20', 'bdubs traditional 20'],
 'wings', 'Buffalo Wild Wings', 1, '1440 cal. 20 bone-in traditional wings, naked/plain.', TRUE),

-- BWW Boneless Wings 15pc: 1090 cal, 56P, 82C, 60F (470g)
('bww_boneless_15pc', 'Buffalo Wild Wings Boneless Wings 15pc', 232, 11.9, 17.4, 12.8,
 0.5, 2.0, 470, 31,
 'manufacturer', ARRAY['bww boneless 15', 'buffalo wild wings boneless 15', 'bdubs boneless wings 15'],
 'wings', 'Buffalo Wild Wings', 1, '1090 cal. 15 boneless wings, breaded and fried.', TRUE),

-- BWW Garden Salad: 180 cal, 5P, 14C, 12F (200g)
('bww_garden_salad', 'Buffalo Wild Wings Garden Salad', 90, 2.5, 7.0, 6.0,
 2.0, 4.0, 200, NULL,
 'manufacturer', ARRAY['bww garden salad', 'buffalo wild wings salad', 'bdubs garden salad'],
 'salads', 'Buffalo Wild Wings', 1, '180 cal. Mixed greens with tomato, cucumber, croutons, ranch dressing.', TRUE),

-- BWW Cheese Curds: 830 cal, 38P, 56C, 52F (320g)
('bww_cheese_curds', 'Buffalo Wild Wings Cheese Curds', 259, 11.9, 17.5, 16.3,
 0.5, 2.0, 320, NULL,
 'manufacturer', ARRAY['bww cheese curds', 'buffalo wild wings cheese curds', 'bdubs cheese curds'],
 'appetizers', 'Buffalo Wild Wings', 1, '830 cal. Wisconsin white cheddar cheese curds, breaded and fried.', TRUE),

-- BWW Chicken Quesadilla: 680 cal, 36P, 42C, 40F (300g)
('bww_chicken_quesadilla', 'Buffalo Wild Wings Chicken Quesadilla', 227, 12.0, 14.0, 13.3,
 1.0, 2.0, 300, NULL,
 'manufacturer', ARRAY['bww chicken quesadilla', 'buffalo wild wings quesadilla', 'bdubs quesadilla'],
 'appetizers', 'Buffalo Wild Wings', 1, '680 cal. Grilled chicken, pico de gallo, cheddar Jack cheese in a flour tortilla.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL RAISING CANE'S ITEMS
-- ══════════════════════════════════════════

-- Raising Cane's Sandwich Combo: 950 cal, 38P, 98C, 44F (450g)
('raising_canes_sandwich_combo', 'Raising Cane''s Sandwich Combo', 211, 8.4, 21.8, 9.8,
 1.0, 3.0, 450, NULL,
 'manufacturer', ARRAY['raising canes sandwich combo', 'canes chicken sandwich combo', 'canes sandwich meal'],
 'combo_meals', 'Raising Cane''s', 1, '950 cal. Chicken finger sandwich, crinkle-cut fries, regular drink.', TRUE),

-- Raising Cane's Tailgate: 2360 cal, 90P, 210C, 128F (960g)
('raising_canes_tailgate', 'Raising Cane''s The Tailgate', 246, 9.4, 21.9, 13.3,
 1.5, 2.5, 960, NULL,
 'manufacturer', ARRAY['raising canes tailgate', 'canes tailgate', 'tailgate combo canes'],
 'combo_meals', 'Raising Cane''s', 1, '2360 cal. 25 chicken fingers, 2 family fries, 6 Texas toasts, 6 Cane''s sauces. Feeds a group.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL ZAXBY'S ITEMS
-- ══════════════════════════════════════════

-- Zaxby's Big Zax Snak: 470 cal, 22P, 38C, 24F (200g)
('zaxbys_big_zax_snak', 'Zaxby''s Big Zax Snak', 235, 11.0, 19.0, 12.0,
 1.0, 2.5, 200, 200,
 'manufacturer', ARRAY['zaxbys big zax snak', 'big zax snak', 'zaxby big zax'],
 'sandwiches', 'Zaxby''s', 1, '470 cal. Chicken finger sandwich with Zax sauce, lettuce, tomato on a toasted bun.', TRUE),

-- Zaxby's Grilled Chicken Sandwich: 580 cal, 38P, 44C, 26F (270g)
('zaxbys_grilled_chicken_sandwich', 'Zaxby''s Grilled Chicken Sandwich', 215, 14.1, 16.3, 9.6,
 1.0, 3.0, 270, 270,
 'manufacturer', ARRAY['zaxbys grilled chicken sandwich', 'zaxby grilled chicken', 'zaxbys grilled sandwich'],
 'sandwiches', 'Zaxby''s', 1, '580 cal. Grilled chicken breast with lettuce, tomato, pickles on a toasted bun.', TRUE),

-- Zaxby's Chicken Finger Plate (5): 1290 cal, 66P, 104C, 68F (480g)
('zaxbys_chicken_finger_plate_5', 'Zaxby''s Chicken Finger Plate (5pc)', 269, 13.8, 21.7, 14.2,
 1.5, 1.5, 480, NULL,
 'manufacturer', ARRAY['zaxbys chicken finger plate 5', 'zaxby finger plate 5', 'zaxbys 5 finger plate'],
 'combo_meals', 'Zaxby''s', 1, '1290 cal. 5 chicken fingerz with fries, Texas toast, coleslaw, Zax sauce.', TRUE),

-- Zaxby's Texas Toast: 140 cal, 3P, 16C, 7F (40g)
('zaxbys_texas_toast', 'Zaxby''s Texas Toast', 350, 7.5, 40.0, 17.5,
 0.5, 2.0, 40, 40,
 'manufacturer', ARRAY['zaxbys texas toast', 'zaxby texas toast', 'zaxbys toast'],
 'sides', 'Zaxby''s', 1, '140 cal per slice. Garlic-buttered Texas toast.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL CHURCH'S ITEMS
-- ══════════════════════════════════════════

-- Church's Spicy Leg: 150 cal, 11P, 6C, 9F (62g)
('churchs_spicy_leg', 'Church''s Chicken Spicy Leg', 242, 17.7, 9.7, 14.5,
 0.0, 0.0, 62, 62,
 'manufacturer', ARRAY['churchs spicy leg', 'church chicken spicy leg', 'churchs leg spicy'],
 'chicken', 'Church''s Chicken', 1, '150 cal per spicy leg. Hand-battered spicy fried chicken drumstick.', TRUE),

-- Church's Spicy Thigh: 290 cal, 17P, 10C, 20F (115g)
('churchs_spicy_thigh', 'Church''s Chicken Spicy Thigh', 252, 14.8, 8.7, 17.4,
 0.0, 0.0, 115, 115,
 'manufacturer', ARRAY['churchs spicy thigh', 'church chicken spicy thigh', 'churchs thigh spicy'],
 'chicken', 'Church''s Chicken', 1, '290 cal per spicy thigh. Hand-battered spicy fried chicken thigh.', TRUE),

-- Church's Spicy Breast: 360 cal, 30P, 12C, 22F (160g)
('churchs_spicy_breast', 'Church''s Chicken Spicy Breast', 225, 18.8, 7.5, 13.8,
 0.0, 0.0, 160, 160,
 'manufacturer', ARRAY['churchs spicy breast', 'church chicken spicy breast', 'churchs breast spicy'],
 'chicken', 'Church''s Chicken', 1, '360 cal per spicy breast. Hand-battered spicy fried chicken breast.', TRUE),

-- Church's Spicy Wing: 180 cal, 11P, 6C, 13F (65g)
('churchs_spicy_wing', 'Church''s Chicken Spicy Wing', 277, 16.9, 9.2, 20.0,
 0.0, 0.0, 65, 65,
 'manufacturer', ARRAY['churchs spicy wing', 'church chicken spicy wing', 'churchs wing spicy'],
 'chicken', 'Church''s Chicken', 1, '180 cal per spicy wing. Hand-battered spicy fried chicken wing.', TRUE),

-- Church's Spicy Tender (1pc): 140 cal, 9P, 7C, 8F (45g)
('churchs_spicy_tender', 'Church''s Chicken Spicy Tender Strip (1pc)', 311, 20.0, 15.6, 17.8,
 0.2, 0.3, 45, 45,
 'manufacturer', ARRAY['churchs spicy tender', 'church chicken spicy tender', 'churchs spicy strip'],
 'chicken', 'Church''s Chicken', 1, '140 cal per strip. Hand-battered spicy chicken tender strip.', TRUE),

-- Church's Cole Slaw: 150 cal, 1P, 14C, 10F (110g)
('churchs_coleslaw', 'Church''s Chicken Cole Slaw', 136, 0.9, 12.7, 9.1,
 1.0, 8.0, 110, NULL,
 'manufacturer', ARRAY['churchs coleslaw', 'church chicken cole slaw', 'churchs cole slaw'],
 'sides', 'Church''s Chicken', 1, '150 cal. Creamy coleslaw, regular side.', TRUE),

-- Church's Mashed Potatoes & Gravy: 110 cal, 2P, 15C, 5F (130g)
('churchs_mashed_potatoes', 'Church''s Chicken Mashed Potatoes & Gravy', 85, 1.5, 11.5, 3.8,
 0.5, 0.5, 130, NULL,
 'manufacturer', ARRAY['churchs mashed potatoes', 'church chicken mashed potatoes gravy', 'churchs potatoes'],
 'sides', 'Church''s Chicken', 1, '110 cal. Mashed potatoes with white gravy.', TRUE),

-- ══════════════════════════════════════════
-- ADDITIONAL HIDDEN / SECRET MENU ITEMS
-- ══════════════════════════════════════════

-- In-N-Out Protein Style Burger: 330 cal, 18P, 11C, 25F (200g)
('in_n_out_protein_style', 'In-N-Out Protein Style Burger', 165, 9.0, 5.5, 12.5,
 1.5, 3.0, 200, 200,
 'manufacturer', ARRAY['in n out protein style', 'protein style in n out', 'in and out protein style', 'lettuce wrap in n out'],
 'burgers', 'In-N-Out', 1, '330 cal. Any burger wrapped in lettuce instead of a bun. Low-carb option.', TRUE),

-- In-N-Out Animal Style Fries: 750 cal, 22P, 58C, 48F (350g)
('in_n_out_animal_style_fries', 'In-N-Out Animal Style Fries', 214, 6.3, 16.6, 13.7,
 2.0, 3.0, 350, NULL,
 'manufacturer', ARRAY['in n out animal style fries', 'animal style fries in n out', 'animal fries in and out'],
 'sides', 'In-N-Out', 1, '750 cal. Secret menu: fries topped with spread, cheese, grilled onions.', TRUE),

-- In-N-Out 4x4: 1050 cal, 68P, 39C, 68F (480g)
('in_n_out_4x4', 'In-N-Out 4x4', 219, 14.2, 8.1, 14.2,
 0.5, 4.0, 480, 480,
 'manufacturer', ARRAY['in n out 4x4', 'in n out four by four', 'in and out 4x4', '4x4 in n out'],
 'burgers', 'In-N-Out', 1, '~1050 cal. Secret menu: 4 beef patties and 4 cheese slices. Maximum size officially allowed.', TRUE),

-- Starbucks Caramel Apple Spice: 380 cal, 0P, 92C, 0F (473g)
('starbucks_caramel_apple_spice', 'Starbucks Caramel Apple Spice (Grande)', 80, 0.0, 19.5, 0.0,
 0.0, 18.0, 473, NULL,
 'manufacturer', ARRAY['starbucks caramel apple spice', 'caramel apple spice starbucks', 'starbucks apple cider'],
 'beverages', 'Starbucks', 1, '380 cal. Steamed apple juice with cinnamon dolce syrup, whipped cream, caramel drizzle.', TRUE),

-- Starbucks Matcha Pink Drink: 210 cal, 2P, 40C, 5F (473g)
('starbucks_matcha_pink_drink', 'Starbucks Matcha Pink Drink (Grande)', 44, 0.4, 8.5, 1.1,
 0.5, 7.5, 473, NULL,
 'manufacturer', ARRAY['starbucks matcha pink drink', 'matcha pink drink starbucks', 'starbucks pink matcha', 'tiktok pink drink'],
 'beverages', 'Starbucks', 1, '210 cal. Secret menu: Pink Drink blended with matcha powder. TikTok famous.', TRUE),

-- Starbucks Cinderella Latte: 310 cal, 8P, 52C, 8F (473g)
('starbucks_cinderella_latte', 'Starbucks Cinderella Latte (Grande)', 66, 1.7, 11.0, 1.7,
 0.0, 10.0, 473, NULL,
 'manufacturer', ARRAY['starbucks cinderella latte', 'cinderella latte starbucks', 'starbucks pumpkin white mocha'],
 'beverages', 'Starbucks', 1, '~310 cal. Secret menu: White mocha + pumpkin spice latte combo. Tastes like pumpkin pie.', TRUE),

-- Chipotle Double Wrapped Burrito: 1100 cal, 52P, 110C, 48F (520g)
('chipotle_double_wrapped', 'Chipotle Double Wrapped Burrito', 212, 10.0, 21.2, 9.2,
 3.0, 2.0, 520, NULL,
 'manufacturer', ARRAY['chipotle double wrapped', 'chipotle double tortilla', 'chipotle double wrap burrito'],
 'burritos', 'Chipotle', 1, '~1100 cal. Secret menu: burrito with two tortillas for extra durability and carbs.', TRUE),

-- Taco Bell Cheesy Gordita Crunch (classic but oft-forgotten): 500 cal, 20P, 40C, 28F (195g)
('taco_bell_cheesy_gordita_crunch', 'Taco Bell Cheesy Gordita Crunch', 256, 10.3, 20.5, 14.4,
 1.5, 2.0, 195, 195,
 'manufacturer', ARRAY['taco bell cheesy gordita crunch', 'cheesy gordita crunch', 'cgc taco bell', 'gordita crunch taco bell'],
 'tacos', 'Taco Bell', 1, '500 cal. A warm flatbread lined with pepper jack and wrapped around a crunchy taco. Fan favorite.', TRUE),

-- Taco Bell Enchirito (hidden): 370 cal, 18P, 34C, 18F (215g)
('taco_bell_enchirito', 'Taco Bell Enchirito', 172, 8.4, 15.8, 8.4,
 2.0, 2.0, 215, 215,
 'manufacturer', ARRAY['taco bell enchirito', 'enchirito taco bell', 'taco bell secret menu enchirito'],
 'burritos', 'Taco Bell', 1, '370 cal. Secret/retired menu: burrito smothered in red sauce and melted cheese. Must ask specifically.', TRUE),

-- ══════════════════════════════════════════
-- MORE CHAIN EXPANSION ITEMS
-- ══════════════════════════════════════════

-- Wingstop Original Hot Wings 10pc: 730 cal, 77P, 4C, 44F (390g)
('wingstop_original_hot_10pc', 'Wingstop Original Hot Wings 10pc', 187, 19.7, 1.0, 11.3,
 0.0, 0.5, 390, 39,
 'manufacturer', ARRAY['wingstop original hot 10', 'wingstop original hot wings 10', 'original hot 10 wingstop'],
 'wings', 'Wingstop', 1, '730 cal. 10 bone-in wings in classic hot sauce.', TRUE),

-- Wingstop Louisiana Rub Wings 10pc: 730 cal, 77P, 4C, 44F (390g)
('wingstop_louisiana_rub_10pc', 'Wingstop Louisiana Rub Wings 10pc', 187, 19.7, 1.0, 11.3,
 0.0, 0.0, 390, 39,
 'manufacturer', ARRAY['wingstop louisiana rub 10', 'wingstop louisiana rub wings 10', 'louisiana rub 10 wingstop'],
 'wings', 'Wingstop', 1, '730 cal. 10 bone-in wings with Cajun dry rub.', TRUE),

-- BWW Mango Habanero Wings 10pc: 800 cal, 83P, 20C, 40F (400g)
('bww_mango_habanero_10pc', 'Buffalo Wild Wings Mango Habanero Wings 10pc', 200, 20.8, 5.0, 10.0,
 0.0, 4.0, 400, 40,
 'manufacturer', ARRAY['bww mango habanero 10', 'buffalo wild wings mango habanero 10', 'bdubs mango habanero 10'],
 'wings', 'Buffalo Wild Wings', 1, '800 cal. 10 bone-in wings in mango habanero sauce.', TRUE),

-- BWW Honey BBQ Wings 10pc: 800 cal, 83P, 24C, 40F (400g)
('bww_honey_bbq_10pc', 'Buffalo Wild Wings Honey BBQ Wings 10pc', 200, 20.8, 6.0, 10.0,
 0.0, 5.0, 400, 40,
 'manufacturer', ARRAY['bww honey bbq 10', 'buffalo wild wings honey bbq 10', 'bdubs honey bbq 10'],
 'wings', 'Buffalo Wild Wings', 1, '800 cal. 10 bone-in wings in honey BBQ sauce.', TRUE),

-- BWW Asian Zing Wings 10pc: 780 cal, 83P, 16C, 40F (400g)
('bww_asian_zing_10pc', 'Buffalo Wild Wings Asian Zing Wings 10pc', 195, 20.8, 4.0, 10.0,
 0.0, 3.5, 400, 40,
 'manufacturer', ARRAY['bww asian zing 10', 'buffalo wild wings asian zing 10', 'bdubs asian zing 10'],
 'wings', 'Buffalo Wild Wings', 1, '780 cal. 10 bone-in wings in Asian Zing sauce.', TRUE),

-- BWW Parmesan Garlic Wings 10pc: 820 cal, 83P, 6C, 50F (400g)
('bww_parmesan_garlic_10pc', 'Buffalo Wild Wings Parmesan Garlic Wings 10pc', 205, 20.8, 1.5, 12.5,
 0.0, 0.5, 400, 40,
 'manufacturer', ARRAY['bww parmesan garlic 10', 'buffalo wild wings parmesan garlic 10', 'bdubs parm garlic 10'],
 'wings', 'Buffalo Wild Wings', 1, '820 cal. 10 bone-in wings in parmesan garlic sauce.', TRUE),

-- BWW Blazin' Wings 10pc: 730 cal, 83P, 6C, 40F (390g)
('bww_blazin_10pc', 'Buffalo Wild Wings Blazin'' Wings 10pc', 187, 21.3, 1.5, 10.3,
 0.0, 1.0, 390, 39,
 'manufacturer', ARRAY['bww blazin wings 10', 'buffalo wild wings blazin 10', 'bdubs blazin wings 10'],
 'wings', 'Buffalo Wild Wings', 1, '730 cal. 10 bone-in wings in Blazin'' sauce. The hottest.', TRUE),

-- Shake Shack Veggie Shack: 510 cal, 18P, 52C, 26F (220g)
('shake_shack_veggie_shack', 'Shake Shack Veggie Shack', 232, 8.2, 23.6, 11.8,
 2.5, 3.0, 220, 220,
 'manufacturer', ARRAY['veggie shack', 'shake shack veggie shack', 'shake shack veggie burger', 'veggie burger shake shack'],
 'burgers', 'Shake Shack', 1, '510 cal. Crispy veggie patty with provolone, lettuce, tomato, vegan mustard honey on a potato bun.', TRUE),

-- Shake Shack Hot Chick'n: 620 cal, 34P, 50C, 30F (250g)
('shake_shack_hot_chickn', 'Shake Shack Hot Chick''n', 248, 13.6, 20.0, 12.0,
 1.0, 3.5, 250, 250,
 'manufacturer', ARRAY['shake shack hot chicken', 'hot chickn shake shack', 'shake shack spicy chicken sandwich'],
 'sandwiches', 'Shake Shack', 1, '620 cal. Crispy chicken with habanero mayo and cherry pepper slaw on a potato bun.', TRUE),

-- Shake Shack Cookie Dough Shake: 790 cal, 16P, 100C, 38F (500g)
('shake_shack_cookie_dough_shake', 'Shake Shack Cookie Dough Shake', 158, 3.2, 20.0, 7.6,
 0.2, 17.0, 500, NULL,
 'manufacturer', ARRAY['shake shack cookie dough shake', 'cookie dough shake shake shack', 'shake shack cookie shake'],
 'beverages', 'Shake Shack', 1, '790 cal. Frozen custard blended with cookie dough pieces and vanilla.', TRUE),

-- Five Guys Chocolate Milkshake: 900 cal, 18P, 80C, 56F (490g)
('five_guys_chocolate_milkshake', 'Five Guys Chocolate Milkshake', 184, 3.7, 16.3, 11.4,
 0.5, 14.0, 490, NULL,
 'manufacturer', ARRAY['five guys chocolate milkshake', 'five guys milkshake chocolate', 'five guys shake chocolate'],
 'beverages', 'Five Guys', 1, '900 cal. Hand-spun milkshake with real chocolate. Can add mix-ins like Oreo, PB, etc.', TRUE),

-- Denny's Bacon Avocado Cheeseburger: 970 cal, 46P, 50C, 64F (380g)
('dennys_bacon_avocado_cheeseburger', 'Denny''s Bacon Avocado Cheeseburger', 255, 12.1, 13.2, 16.8,
 2.0, 3.5, 380, 380,
 'manufacturer', ARRAY['dennys bacon avocado cheeseburger', 'denny bacon avocado burger', 'dennys avocado burger'],
 'burgers', 'Denny''s', 1, '970 cal. Beef patty with bacon, avocado, Swiss cheese, lettuce, tomato, red onion on brioche.', TRUE),

-- Denny's Chicken Strips: 480 cal, 28P, 32C, 26F (220g)
('dennys_chicken_strips', 'Denny''s Chicken Strips', 218, 12.7, 14.5, 11.8,
 0.5, 1.5, 220, NULL,
 'manufacturer', ARRAY['dennys chicken strips', 'denny chicken strips', 'dennys chicken tenders'],
 'chicken', 'Denny''s', 1, '480 cal. Crispy breaded chicken strips with ranch or BBQ sauce.', TRUE),

-- Cracker Barrel Fried Chicken Tenders: 490 cal, 32P, 24C, 30F (230g)
('cracker_barrel_fried_chicken_tenders', 'Cracker Barrel Fried Chicken Tenders', 213, 13.9, 10.4, 13.0,
 0.3, 0.5, 230, NULL,
 'manufacturer', ARRAY['cracker barrel fried chicken tenders', 'cracker barrel chicken tenders', 'chicken tenders cracker barrel'],
 'chicken', 'Cracker Barrel', 1, '490 cal. Hand-breaded fried chicken tenderloins. Without sides.', TRUE),

-- Cracker Barrel Coleslaw: 120 cal, 1P, 10C, 9F (120g)
('cracker_barrel_coleslaw', 'Cracker Barrel Coleslaw', 100, 0.8, 8.3, 7.5,
 1.0, 6.0, 120, NULL,
 'manufacturer', ARRAY['cracker barrel coleslaw', 'cracker barrel cole slaw', 'coleslaw cracker barrel'],
 'sides', 'Cracker Barrel', 1, '120 cal. Creamy coleslaw side.', TRUE),

-- Cracker Barrel Dumplins (side): 220 cal, 5P, 30C, 8F (140g)
('cracker_barrel_dumplins', 'Cracker Barrel Dumplins (Side)', 157, 3.6, 21.4, 5.7,
 0.3, 0.5, 140, NULL,
 'manufacturer', ARRAY['cracker barrel dumplins', 'cracker barrel dumplings side', 'dumplins cracker barrel'],
 'sides', 'Cracker Barrel', 1, '220 cal. Homemade dumplings in chicken broth. A unique southern side.', TRUE),

-- Whataburger Fries (Medium): 400 cal, 5P, 50C, 20F (150g)
('whataburger_fries', 'Whataburger Fries (Medium)', 267, 3.3, 33.3, 13.3,
 2.5, 0.2, 150, NULL,
 'manufacturer', ARRAY['whataburger fries', 'whataburger french fries', 'fries whataburger'],
 'sides', 'Whataburger', 1, '400 cal. French fries, medium order.', TRUE),

-- Whataburger Gravy Biscuit: 530 cal, 10P, 48C, 34F (220g)
('whataburger_gravy_biscuit', 'Whataburger Biscuit with Sausage Gravy', 241, 4.5, 21.8, 15.5,
 0.5, 2.0, 220, 220,
 'manufacturer', ARRAY['whataburger biscuit gravy', 'whataburger sausage gravy biscuit', 'biscuit gravy whataburger'],
 'breakfast', 'Whataburger', 1, '530 cal. Buttermilk biscuit smothered in creamy sausage gravy.', TRUE)

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
