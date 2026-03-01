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
('ihop_original_buttermilk_pancakes_short_stack', 'IHOP Original Buttermilk Pancakes (Short Stack)', 200.0, 5.8, 26.2, 8.0, 1.3, 4.9, 225, 225, 'ihop.com', ARRAY['ihop pancakes', 'ihop short stack', 'ihop buttermilk pancakes'], '450 cal per short stack (3 pancakes, ~225g)'),
-- Pancakes (5 pancakes full stack ~375g)
('ihop_original_buttermilk_pancakes_full_stack', 'IHOP Original Buttermilk Pancakes (Full Stack)', 197.6, 5.6, 25.9, 8.0, 1.3, 4.8, 375, 375, 'ihop.com', ARRAY['ihop full stack pancakes', 'ihop 5 pancakes'], '741 cal per full stack (5 pancakes, ~375g)'),
-- Chocolate Chip Pancakes (4 pancakes ~350g)
('ihop_chocolate_chip_pancakes', 'IHOP Chocolate Chip Buttermilk Pancakes', 197.4, 5.1, 31.4, 6.0, 1.7, 11.7, 350, 350, 'ihop.com', ARRAY['ihop chocolate chip pancakes', 'ihop choc chip'], '691 cal per 4 pancakes (~350g)'),
-- New York Cheesecake Pancakes (4 pancakes ~400g)
('ihop_new_york_cheesecake_pancakes', 'IHOP New York Cheesecake Pancakes', 232.8, 5.8, 32.5, 9.0, 1.5, 12.8, 400, 400, 'ihop.com', ARRAY['ihop cheesecake pancakes', 'ihop ny cheesecake pancakes'], '931 cal per 4 pancakes (~400g)'),
-- Strawberry Banana Pancakes (4 pancakes ~380g)
('ihop_strawberry_banana_pancakes', 'IHOP Strawberry Banana Pancakes', 179.2, 5.0, 31.6, 3.9, 2.1, 10.8, 380, 380, 'ihop.com', ARRAY['ihop strawberry banana pancakes', 'ihop fruit pancakes'], '681 cal per 4 pancakes (~380g)'),
-- Belgian Waffle (~200g)
('ihop_belgian_waffle', 'IHOP Belgian Waffle', 295.5, 5.5, 34.5, 15.0, 1.5, 8.5, 200, 200, 'ihop.com', ARRAY['ihop waffle', 'ihop belgian waffle'], '591 cal per waffle (~200g)'),
-- Chicken Fajita Omelette (~300g)
('ihop_chicken_fajita_omelette', 'IHOP Chicken Fajita Omelette', 303.7, 25.0, 8.3, 19.0, 1.0, 3.0, 300, 300, 'ihop.com', ARRAY['ihop chicken fajita omelette', 'ihop fajita omelette'], '911 cal per omelette (~300g)'),
-- Bacon Temptation Omelette (~320g)
('ihop_bacon_temptation_omelette', 'IHOP Bacon Temptation Omelette', 347.2, 23.1, 5.0, 25.9, 0.3, 1.6, 320, 320, 'ihop.com', ARRAY['ihop bacon omelette', 'ihop bacon temptation'], '1111 cal per omelette (~320g)'),
-- Spinach & Mushroom Omelette (~300g)
('ihop_spinach_mushroom_omelette', 'IHOP Spinach & Mushroom Omelette', 303.7, 15.7, 7.7, 23.7, 1.0, 2.0, 300, 300, 'ihop.com', ARRAY['ihop spinach omelette', 'ihop mushroom omelette'], '911 cal per omelette (~300g)'),
-- Big Steak Omelette (~350g)
('ihop_big_steak_omelette', 'IHOP Big Steak Omelette', 297.4, 18.9, 11.4, 19.7, 1.4, 2.0, 350, 350, 'ihop.com', ARRAY['ihop steak omelette', 'ihop big steak'], '1041 cal per omelette (~350g)'),
-- Avocado Bacon & Cheese Omelette (~280g)
('ihop_avocado_bacon_cheese_omelette', 'IHOP Avocado Bacon & Cheese Omelette', 314.6, 20.4, 5.4, 23.9, 1.4, 0.7, 280, 280, 'ihop.com', ARRAY['ihop avocado omelette', 'ihop abc omelette'], '881 cal per omelette (~280g)'),
-- Classic Steakburger (~250g)
('ihop_classic_steakburger', 'IHOP Classic Steakburger', 268.4, 12.8, 16.8, 16.8, 1.2, 3.2, 250, 250, 'ihop.com', ARRAY['ihop burger', 'ihop steakburger', 'ihop cheeseburger'], '671 cal per burger (~250g)'),
-- Big Brunch Steakburger (~350g)
('ihop_big_brunch_steakburger', 'IHOP Big Brunch Steakburger', 286.0, 13.1, 16.9, 18.3, 1.1, 3.4, 350, 350, 'ihop.com', ARRAY['ihop brunch burger', 'ihop big brunch'], '1001 cal per burger (~350g)'),
-- Grilled Tilapia (~200g)
('ihop_grilled_tilapia', 'IHOP Grilled Tilapia', 120.0, 19.0, 1.0, 5.0, 0.5, 0.5, 200, 200, 'ihop.com', ARRAY['ihop tilapia', 'ihop grilled fish'], '240 cal per serving (~200g)'),
-- T-Bone Steak 12oz (~340g)
('ihop_tbone_steak', 'IHOP T-Bone Steak (12 oz)', 114.7, 15.9, 0.3, 5.6, 0.0, 0.0, 340, 340, 'ihop.com', ARRAY['ihop t-bone', 'ihop steak', 'ihop tbone'], '390 cal per 12oz steak (~340g)'),
-- Buttermilk Crispy Chicken & Fries (~350g)
('ihop_crispy_chicken_and_fries', 'IHOP Buttermilk Crispy Chicken & Fries', 254.6, 13.4, 23.1, 12.3, 1.7, 1.4, 350, 350, 'ihop.com', ARRAY['ihop crispy chicken', 'ihop chicken and fries'], '891 cal per serving (~350g)'),
-- Pot Roast Entree (~300g)
('ihop_pot_roast', 'IHOP Pot Roast Entree', 123.3, 10.7, 5.0, 7.0, 0.0, 0.7, 300, 300, 'ihop.com', ARRAY['ihop pot roast', 'ihop roast'], '370 cal per serving (~300g)'),
-- BLTA Sandwich (~350g)
('ihop_blta_sandwich', 'IHOP BLTA Sandwich', 334.6, 8.9, 21.1, 24.0, 2.3, 4.0, 350, 350, 'ihop.com', ARRAY['ihop blt', 'ihop blta', 'ihop bacon sandwich'], '1171 cal per sandwich (~350g)'),
-- Ham & Egg Melt Sandwich (~300g)
('ihop_ham_egg_melt', 'IHOP Ham & Egg Melt Sandwich', 320.3, 19.0, 22.7, 17.0, 1.3, 3.0, 300, 300, 'ihop.com', ARRAY['ihop ham egg melt', 'ihop ham sandwich'], '961 cal per sandwich (~300g)'),
-- Breakfast Sampler (~350g)
('ihop_breakfast_sampler', 'IHOP Breakfast Sampler', 251.7, 9.1, 17.7, 16.0, 1.1, 2.9, 350, 350, 'ihop.com', ARRAY['ihop sampler', 'ihop breakfast sampler'], '881 cal per serving (~350g)'),
-- 2x2x2 Combo (~200g)
('ihop_2x2x2_combo', 'IHOP 2x2x2 Combo', 160.0, 4.5, 19.5, 7.5, 1.0, 3.5, 200, 200, 'ihop.com', ARRAY['ihop 2x2x2', 'ihop combo'], '320 cal per combo (~200g)'),
-- 55+ Grilled Chicken Dinner (~180g)
('ihop_55_grilled_chicken', 'IHOP 55+ Grilled Chicken Dinner', 83.3, 17.8, 0.6, 1.7, 0.6, 0.6, 180, 180, 'ihop.com', ARRAY['ihop senior chicken', 'ihop grilled chicken dinner'], '150 cal per serving (~180g)'),
-- French Toast (~250g)
('ihop_original_french_toast', 'IHOP Original French Toast', 284.0, 8.0, 36.0, 12.0, 1.6, 12.0, 250, 250, 'ihop.com', ARRAY['ihop french toast', 'ihop thick cut french toast'], '710 cal per serving (~250g)'),
-- Crepe (Swedish) (~220g)
('ihop_swedish_crepe', 'IHOP Swedish Crepe', 268.6, 6.4, 32.7, 12.7, 0.9, 14.5, 220, 220, 'ihop.com', ARRAY['ihop crepe', 'ihop swedish crepe', 'ihop crepes'], '591 cal per serving (~220g)'),
-- Egg White Omelette (~150g)
('ihop_egg_white_omelette', 'IHOP Egg White Omelette', 66.7, 12.0, 0.7, 2.0, 0.7, 0.0, 150, 150, 'ihop.com', ARRAY['ihop egg white omelette', 'ihop healthy omelette'], '100 cal per omelette (~150g)'),
-- Hash Browns (~150g)
('ihop_hash_browns', 'IHOP Hash Browns', 193.3, 2.7, 24.0, 10.0, 2.0, 0.7, 150, 150, 'ihop.com', ARRAY['ihop hash browns', 'ihop hashbrowns'], '290 cal per serving (~150g)'),
-- Onion Rings (~140g)
('ihop_onion_rings', 'IHOP Onion Rings', 364.3, 3.6, 35.7, 21.4, 2.1, 5.0, 140, 140, 'ihop.com', ARRAY['ihop onion rings'], '510 cal per serving (~140g)'),
-- Mozzarella Sticks (~180g)
('ihop_mozzarella_sticks', 'IHOP Mozzarella Sticks', 338.9, 13.9, 27.8, 18.3, 1.1, 2.8, 180, 180, 'ihop.com', ARRAY['ihop mozzarella sticks', 'ihop mozz sticks'], '610 cal per serving (~180g)'),
-- Crispy Chicken Strips (~200g)
('ihop_crispy_chicken_strips', 'IHOP Crispy Chicken Strips', 285.0, 21.0, 17.0, 13.0, 1.0, 1.0, 200, 200, 'ihop.com', ARRAY['ihop chicken strips', 'ihop chicken tenders'], '570 cal per serving (~200g)'),
-- House Salad (~200g)
('ihop_house_salad', 'IHOP House Salad', 55.0, 3.0, 7.0, 2.0, 2.0, 3.0, 200, 200, 'ihop.com', ARRAY['ihop salad', 'ihop side salad', 'ihop house salad'], '110 cal per salad (~200g)'),

-- ============================================
-- 2. DENNY'S
-- Source: dennys.com, fastfoodnutrition.org, fastfoodmenuprices.com
-- ============================================

-- Original Grand Slam (~310g / 11oz)
('dennys_original_grand_slam', 'Denny''s Original Grand Slam', 225.8, 7.1, 25.5, 11.0, 1.0, 4.5, 310, 310, 'dennys.com', ARRAY['dennys grand slam', 'dennys slam', 'dennys breakfast'], '700 cal per serving (~310g)'),
-- Lumberjack Slam (~450g)
('dennys_lumberjack_slam', 'Denny''s Lumberjack Slam', 215.8, 8.2, 22.0, 10.4, 0.9, 3.1, 450, 450, 'dennys.com', ARRAY['dennys lumberjack slam', 'dennys lumberjack'], '971 cal per serving (~450g)'),
-- Moons Over My Hammy (~480g / 17oz)
('dennys_moons_over_my_hammy', 'Denny''s Moons Over My Hammy', 202.1, 9.2, 11.9, 12.9, 0.8, 2.5, 480, 480, 'dennys.com', ARRAY['dennys moons over my hammy', 'dennys moon hammy'], '970 cal per serving (~480g)'),
-- Buttermilk Pancakes (3) (~225g)
('dennys_buttermilk_pancakes', 'Denny''s Buttermilk Pancakes (3)', 182.2, 4.4, 28.0, 6.2, 0.9, 4.9, 225, 225, 'dennys.com', ARRAY['dennys pancakes', 'dennys buttermilk pancakes'], '410 cal per 3 pancakes (~225g)'),
-- Chocolate Lava Cake (~200g)
('dennys_chocolate_lava_cake', 'Denny''s Chocolate Lava Cake', 350.5, 4.0, 42.5, 17.5, 2.0, 30.0, 200, 200, 'dennys.com', ARRAY['dennys lava cake', 'dennys chocolate cake'], '701 cal per serving (~200g)'),
-- Sirloin Steak Dinner (8oz ~227g steak only)
('dennys_sirloin_steak', 'Denny''s Sirloin Steak (8 oz)', 158.6, 26.4, 0.9, 6.2, 0.0, 0.0, 227, 227, 'dennys.com', ARRAY['dennys steak', 'dennys sirloin', 'dennys steak dinner'], '360 cal per 8oz steak (~227g)'),
-- French Fries (~120g)
('dennys_french_fries', 'Denny''s French Fries', 333.3, 3.3, 41.7, 16.7, 3.3, 0.0, 120, 120, 'dennys.com', ARRAY['dennys fries', 'dennys french fries'], '400 cal per serving (~120g)'),
-- Hash Browns (~150g)
('dennys_hash_browns', 'Denny''s Hash Browns', 140.0, 2.0, 20.0, 6.0, 2.0, 0.7, 150, 150, 'dennys.com', ARRAY['dennys hash browns', 'dennys hashbrowns'], '210 cal per serving (~150g)'),
-- All-American Slam (~350g)
('dennys_all_american_slam', 'Denny''s All-American Slam', 220.0, 10.3, 14.3, 12.9, 0.6, 2.3, 350, 350, 'dennys.com', ARRAY['dennys all american slam', 'dennys all american'], '770 cal per serving (~350g)'),
-- Loaded Veggie Omelette (~300g)
('dennys_loaded_veggie_omelette', 'Denny''s Loaded Veggie Omelette', 206.7, 14.0, 10.0, 12.3, 1.3, 3.3, 300, 300, 'dennys.com', ARRAY['dennys veggie omelette', 'dennys vegetable omelette'], '620 cal per omelette (~300g)'),
-- Ultimate Omelette (~320g)
('dennys_ultimate_omelette', 'Denny''s Ultimate Omelette', 278.1, 16.9, 6.9, 19.4, 0.6, 1.9, 320, 320, 'dennys.com', ARRAY['dennys ultimate omelette'], '890 cal per omelette (~320g)'),
-- Slamburger (~250g)
('dennys_slamburger', 'Denny''s Slamburger', 340.0, 16.0, 24.0, 20.0, 1.2, 4.0, 250, 250, 'dennys.com', ARRAY['dennys slamburger', 'dennys burger'], '850 cal per burger (~250g)'),
-- Bacon Slamburger (~280g)
('dennys_bacon_slamburger', 'Denny''s Bacon Slamburger', 346.4, 16.4, 22.5, 20.7, 1.1, 3.6, 280, 280, 'dennys.com', ARRAY['dennys bacon slamburger', 'dennys bacon burger'], '970 cal per burger (~280g)'),
-- Country Fried Steak & Eggs (~350g)
('dennys_country_fried_steak_eggs', 'Denny''s Country Fried Steak & Eggs', 262.9, 10.9, 21.7, 13.7, 0.9, 1.7, 350, 350, 'dennys.com', ARRAY['dennys country fried steak', 'dennys CFS'], '920 cal per serving (~350g)'),
-- Chicken Strips (~200g)
('dennys_chicken_strips', 'Denny''s Chicken Strips', 290.0, 20.0, 19.0, 14.0, 1.0, 1.0, 200, 200, 'dennys.com', ARRAY['dennys chicken strips', 'dennys chicken tenders'], '580 cal per serving (~200g)'),
-- Fit Slam (~280g)
('dennys_fit_slam', 'Denny''s Fit Slam', 135.7, 14.3, 12.5, 3.9, 1.4, 4.6, 280, 280, 'dennys.com', ARRAY['dennys fit slam', 'dennys healthy breakfast'], '380 cal per serving (~280g)'),
-- Super Bird (~250g)
('dennys_super_bird', 'Denny''s Super Bird', 292.0, 17.2, 22.0, 14.8, 0.8, 3.2, 250, 250, 'dennys.com', ARRAY['dennys super bird', 'dennys turkey sandwich'], '730 cal per sandwich (~250g)'),
-- Club Sandwich (~280g)
('dennys_club_sandwich', 'Denny''s Club Sandwich', 296.4, 12.5, 22.9, 15.7, 1.1, 3.2, 280, 280, 'dennys.com', ARRAY['dennys club sandwich', 'dennys club'], '830 cal per sandwich (~280g)'),
-- Seasoned Fries (~150g)
('dennys_seasoned_fries', 'Denny''s Seasoned Fries', 300.0, 3.3, 36.7, 15.3, 3.3, 0.7, 150, 150, 'dennys.com', ARRAY['dennys seasoned fries'], '450 cal per serving (~150g)'),
-- Mozzarella Sticks (~180g)
('dennys_mozzarella_sticks', 'Denny''s Mozzarella Sticks', 327.8, 13.3, 27.8, 17.2, 1.1, 2.2, 180, 180, 'dennys.com', ARRAY['dennys mozzarella sticks', 'dennys mozz sticks'], '590 cal per serving (~180g)'),
-- Zesty Nachos (~350g)
('dennys_zesty_nachos', 'Denny''s Zesty Nachos', 322.9, 10.0, 27.1, 18.6, 2.9, 2.9, 350, 350, 'dennys.com', ARRAY['dennys nachos', 'dennys zesty nachos'], '1130 cal per serving (~350g)'),
-- Brownie (~150g)
('dennys_brownie', 'Denny''s Brownie', 380.0, 4.7, 48.7, 18.0, 2.0, 34.7, 150, 150, 'dennys.com', ARRAY['dennys brownie', 'dennys chocolate brownie'], '570 cal per brownie (~150g)'),
-- Pancake Puppies (~180g)
('dennys_pancake_puppies', 'Denny''s Pancake Puppies', 355.6, 4.4, 41.1, 17.2, 1.1, 17.8, 180, 180, 'dennys.com', ARRAY['dennys pancake puppies'], '640 cal per serving (~180g)'),

-- ============================================
-- 3. CRACKER BARREL
-- Source: crackerbarrel.com, crackerbarrelmenuwithprices.com
-- ============================================

-- Old Timer's Breakfast (eggs/meat portion ~200g)
('cracker_barrel_old_timers_breakfast', 'Cracker Barrel Old Timer''s Breakfast', 75.0, 7.0, 1.0, 5.0, 0.0, 0.5, 200, 200, 'crackerbarrel.com', ARRAY['cracker barrel old timers', 'cracker barrel breakfast'], '150 cal per serving (~200g)'),
-- Biscuits n Gravy (~250g)
('cracker_barrel_biscuits_n_gravy', 'Cracker Barrel Biscuits n'' Gravy', 200.0, 5.2, 21.2, 10.8, 0.8, 1.6, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel biscuits gravy', 'cracker barrel biscuits and gravy'], '500 cal per serving (~250g)'),
-- Biscuit (1 biscuit ~80g)
('cracker_barrel_biscuit', 'Cracker Barrel Biscuit', 200.0, 3.8, 25.0, 8.8, 0.6, 2.5, 80, 80, 'crackerbarrel.com', ARRAY['cracker barrel biscuit'], '160 cal per biscuit (~80g)'),
-- Country Fried Steak with Gravy (~300g)
('cracker_barrel_country_fried_steak', 'Cracker Barrel Country Fried Steak w/ Gravy', 200.0, 12.3, 16.3, 9.3, 0.3, 0.3, 300, 300, 'crackerbarrel.com', ARRAY['cracker barrel country fried steak', 'cracker barrel CFS'], '600 cal per serving (~300g)'),
-- Meatloaf (~250g)
('cracker_barrel_meatloaf', 'Cracker Barrel Meatloaf', 180.0, 12.8, 5.6, 11.6, 0.4, 2.4, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel meatloaf', 'cracker barrel meat loaf'], '450 cal per serving (~250g)'),
-- Chicken n Dumplins (~350g)
('cracker_barrel_chicken_n_dumplins', 'Cracker Barrel Chicken n'' Dumplins', 102.9, 5.4, 15.1, 2.3, 1.7, 0.6, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel chicken dumplins', 'cracker barrel chicken and dumplings'], '360 cal per serving (~350g)'),
-- Chicken Fried Chicken w/ Gravy (~400g)
('cracker_barrel_chicken_fried_chicken', 'Cracker Barrel Chicken Fried Chicken w/ Gravy', 285.0, 18.5, 17.5, 15.0, 1.3, 1.0, 400, 400, 'crackerbarrel.com', ARRAY['cracker barrel chicken fried chicken', 'cracker barrel CFC'], '1140 cal per serving (~400g)'),
-- Grilled Chicken Tenderloins (6) (~250g)
('cracker_barrel_grilled_chicken_tenders', 'Cracker Barrel Grilled Chicken Tenderloins', 128.0, 22.8, 2.4, 3.2, 0.2, 2.0, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel grilled chicken', 'cracker barrel chicken tenders'], '320 cal per 6 tenders (~250g)'),
-- Hand-Breaded Fried Chicken Tenders (~250g)
('cracker_barrel_fried_chicken_tenders', 'Cracker Barrel Hand-Breaded Fried Chicken Tenders', 240.0, 22.8, 10.4, 12.0, 1.6, 0.0, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel fried chicken tenders'], '600 cal per serving (~250g)'),
-- Homestyle Chicken w/ Gravy (~300g)
('cracker_barrel_homestyle_chicken', 'Cracker Barrel Homestyle Chicken w/ Gravy', 203.3, 12.7, 12.3, 11.3, 0.7, 0.7, 300, 300, 'crackerbarrel.com', ARRAY['cracker barrel homestyle chicken'], '610 cal per serving (~300g)'),
-- Fried Catfish w/ Hushpuppies (~350g)
('cracker_barrel_fried_catfish', 'Cracker Barrel Fried Catfish w/ Hushpuppies', 231.4, 10.9, 10.0, 16.3, 1.1, 1.4, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel fried catfish', 'cracker barrel catfish'], '810 cal per serving (~350g)'),
-- Spicy Grilled Catfish (~200g)
('cracker_barrel_grilled_catfish', 'Cracker Barrel Spicy Grilled Catfish', 130.0, 16.5, 1.5, 7.5, 0.5, 0.0, 200, 200, 'crackerbarrel.com', ARRAY['cracker barrel grilled catfish'], '260 cal per 2 fillets (~200g)'),
-- Friday Fish Fry (4 cod) (~350g)
('cracker_barrel_fish_fry', 'Cracker Barrel Friday Fish Fry', 211.4, 10.6, 17.1, 11.1, 0.9, 0.9, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel fish fry', 'cracker barrel cod'], '740 cal per 4 fillets (~350g)'),
-- Chicken Pot Pie (~400g)
('cracker_barrel_chicken_pot_pie', 'Cracker Barrel Sunday Chicken Pot Pie', 240.0, 8.8, 20.5, 13.8, 1.8, 1.0, 400, 400, 'crackerbarrel.com', ARRAY['cracker barrel pot pie', 'cracker barrel chicken pot pie'], '960 cal per serving (~400g)'),
-- Saturday BBQ Ribs (~350g)
('cracker_barrel_bbq_ribs', 'Cracker Barrel Saturday Southern BBQ Ribs', 220.0, 10.0, 13.1, 14.6, 0.1, 12.3, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel ribs', 'cracker barrel bbq ribs'], '770 cal per serving (~350g)'),
-- Turkey n Dressing (~250g)
('cracker_barrel_turkey_n_dressing', 'Cracker Barrel Thursday Turkey n'' Dressing', 92.0, 11.6, 4.8, 3.2, 0.2, 1.2, 250, 250, 'crackerbarrel.com', ARRAY['cracker barrel turkey', 'cracker barrel turkey dressing'], '230 cal per serving (~250g)'),
-- Thick-Sliced Bacon (3 slices ~50g)
('cracker_barrel_bacon', 'Cracker Barrel Thick-Sliced Bacon (3)', 380.0, 26.0, 0.0, 32.0, 0.0, 0.0, 50, 50, 'crackerbarrel.com', ARRAY['cracker barrel bacon'], '190 cal per 3 slices (~50g)'),
-- Smoked Sausage Patties (~80g)
('cracker_barrel_sausage_patties', 'Cracker Barrel Smoked Sausage Patties', 300.0, 17.5, 2.5, 25.0, 0.0, 0.0, 80, 80, 'crackerbarrel.com', ARRAY['cracker barrel sausage', 'cracker barrel sausage patties'], '240 cal per serving (~80g)'),
-- Mini Pancakes (kids ~120g)
('cracker_barrel_mini_pancakes', 'Cracker Barrel Mini Pancakes', 266.7, 3.3, 34.2, 12.5, 2.5, 4.2, 120, 120, 'crackerbarrel.com', ARRAY['cracker barrel mini pancakes', 'cracker barrel kids pancakes'], '320 cal per serving (~120g)'),
-- Scrambled Eggs (~80g)
('cracker_barrel_scrambled_eggs', 'Cracker Barrel Scrambled Eggs', 87.5, 8.8, 0.6, 5.6, 0.0, 0.0, 80, 80, 'crackerbarrel.com', ARRAY['cracker barrel eggs', 'cracker barrel scrambled eggs'], '70 cal per serving (~80g)'),
-- Broccoli Cheddar Chicken (~350g)
('cracker_barrel_broccoli_cheddar_chicken', 'Cracker Barrel Wednesday Broccoli Cheddar Chicken', 197.1, 11.4, 10.0, 12.6, 1.4, 0.3, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel broccoli cheddar chicken'], '690 cal per serving (~350g)'),
-- Country Fried Pork Chops (~400g)
('cracker_barrel_country_fried_pork_chops', 'Cracker Barrel Tuesday Country Fried Pork Chops', 260.0, 13.3, 10.8, 18.0, 0.8, 0.5, 400, 400, 'crackerbarrel.com', ARRAY['cracker barrel pork chops', 'cracker barrel fried pork'], '1040 cal per serving (~400g)'),
-- Chicken n Rice (~350g)
('cracker_barrel_chicken_n_rice', 'Cracker Barrel Monday Chicken n'' Rice', 145.7, 6.9, 16.0, 5.7, 0.0, 0.6, 350, 350, 'crackerbarrel.com', ARRAY['cracker barrel chicken rice'], '510 cal per serving (~350g)'),
-- Mini Confetti Pancakes (kids ~130g)
('cracker_barrel_confetti_pancakes', 'Cracker Barrel Mini Confetti Pancakes', 300.0, 3.8, 44.6, 12.3, 2.3, 10.0, 130, 130, 'crackerbarrel.com', ARRAY['cracker barrel confetti pancakes'], '390 cal per serving (~130g)')

-- ============================================
-- 4. OUTBACK STEAKHOUSE
-- Source: outback.com, fastfoodnutrition.org, fatsecret.com
-- ============================================

-- Bloomin' Onion (~600g whole appetizer)
('outback_bloomin_onion', 'Outback Bloomin'' Onion', 325.0, 3.0, 20.5, 25.8, 2.8, 4.0, 600, 600, 'outback.com', ARRAY['outback bloomin onion', 'outback blooming onion'], '1950 cal per whole appetizer (~600g)'),
-- Victoria's Filet Mignon 6oz (~170g)
('outback_victorias_filet_6oz', 'Outback Victoria''s Filet Mignon (6 oz)', 141.2, 27.6, 0.0, 5.3, 0.0, 0.0, 170, 170, 'outback.com', ARRAY['outback filet mignon', 'outback victorias filet', 'outback filet 6oz'], '240 cal per 6oz filet (~170g)'),
-- Victoria's Filet Mignon 9oz (~255g)
('outback_victorias_filet_9oz', 'Outback Victoria''s Filet Mignon (9 oz)', 149.0, 28.6, 0.0, 5.5, 0.0, 0.0, 255, 255, 'outback.com', ARRAY['outback filet 9oz', 'outback large filet'], '380 cal per 9oz filet (~255g)'),
-- Outback Center-Cut Sirloin 6oz (~170g)
('outback_center_cut_sirloin_6oz', 'Outback Center-Cut Sirloin (6 oz)', 247.1, 29.4, 2.9, 12.9, 0.6, 0.6, 170, 170, 'outback.com', ARRAY['outback sirloin', 'outback sirloin 6oz'], '420 cal per 6oz sirloin (~170g)'),
-- Outback Center-Cut Sirloin 10oz (~283g)
('outback_center_cut_sirloin_10oz', 'Outback Center-Cut Sirloin (10 oz)', 229.0, 27.6, 2.1, 12.0, 0.4, 0.4, 283, 283, 'outback.com', ARRAY['outback sirloin 10oz'], '648 cal per 10oz sirloin (~283g)'),
-- Bone-In Ribeye 18oz (~510g)
('outback_bone_in_ribeye', 'Outback Bone-In Ribeye (18 oz)', 235.3, 21.6, 0.2, 15.7, 0.0, 0.0, 510, 510, 'outback.com', ARRAY['outback ribeye', 'outback bone in ribeye'], '1200 cal per 18oz (~510g)'),
-- NY Strip 14oz (~400g)
('outback_ny_strip', 'Outback New York Strip (14 oz)', 215.0, 22.5, 0.5, 13.0, 0.0, 0.0, 400, 400, 'outback.com', ARRAY['outback ny strip', 'outback new york strip'], '860 cal per 14oz (~400g)'),
-- Outback Ribs Half Rack (~350g)
('outback_baby_back_ribs_half', 'Outback Baby Back Ribs (Half Rack)', 205.7, 17.1, 5.1, 12.6, 0.3, 3.4, 350, 350, 'outback.com', ARRAY['outback half rack ribs', 'outback baby back ribs half'], '720 cal per half rack (~350g)'),
-- Outback Ribs Full Rack (~700g)
('outback_baby_back_ribs_full', 'Outback Baby Back Ribs (Full Rack)', 205.7, 17.1, 5.1, 13.0, 0.3, 3.4, 700, 700, 'outback.com', ARRAY['outback full rack ribs', 'outback baby back ribs'], '1440 cal per full rack (~700g)'),
-- Aussie Cheese Fries (~450g)
('outback_aussie_cheese_fries', 'Outback Aussie Cheese Fries', 313.3, 8.9, 26.7, 18.9, 2.2, 1.1, 450, 450, 'outback.com', ARRAY['outback cheese fries', 'outback aussie fries'], '1410 cal per serving (~450g)'),
-- Gold Coast Coconut Shrimp (~200g)
('outback_coconut_shrimp', 'Outback Gold Coast Coconut Shrimp', 220.0, 8.0, 20.0, 12.0, 1.0, 6.0, 200, 200, 'outback.com', ARRAY['outback coconut shrimp', 'outback gold coast shrimp'], '440 cal per serving (~200g)'),
-- Kookaburra Wings (~350g)
('outback_kookaburra_wings', 'Outback Kookaburra Wings', 240.0, 18.6, 8.6, 14.3, 0.6, 2.9, 350, 350, 'outback.com', ARRAY['outback wings', 'outback kookaburra wings'], '840 cal per serving (~350g)'),
-- Alice Springs Chicken (~350g)
('outback_alice_springs_chicken', 'Outback Alice Springs Chicken', 228.6, 24.3, 8.6, 10.9, 0.6, 2.9, 350, 350, 'outback.com', ARRAY['outback alice springs chicken', 'outback alice springs'], '800 cal per serving (~350g)'),
-- Grilled Chicken on the Barbie (~250g)
('outback_grilled_chicken', 'Outback Grilled Chicken on the Barbie', 156.0, 25.2, 4.0, 4.4, 0.4, 1.6, 250, 250, 'outback.com', ARRAY['outback grilled chicken', 'outback chicken on barbie'], '390 cal per serving (~250g)'),
-- Loaded Baked Potato (~300g)
('outback_loaded_baked_potato', 'Outback Loaded Baked Potato', 113.3, 3.0, 15.7, 4.7, 1.3, 1.0, 300, 300, 'outback.com', ARRAY['outback loaded potato', 'outback baked potato loaded'], '340 cal per potato (~300g)'),
-- Sweet Potato (~250g)
('outback_sweet_potato', 'Outback Sweet Potato', 132.0, 2.4, 22.8, 4.0, 2.8, 10.0, 250, 250, 'outback.com', ARRAY['outback sweet potato'], '330 cal per potato (~250g)'),
-- House Salad (no dressing ~200g)
('outback_house_salad', 'Outback House Salad (no dressing)', 90.0, 3.0, 10.0, 4.5, 2.5, 4.0, 200, 200, 'outback.com', ARRAY['outback house salad', 'outback side salad'], '180 cal per salad (~200g)'),
-- Caesar Salad w/ Dressing (~200g)
('outback_caesar_salad', 'Outback Caesar Salad w/ Dressing', 130.0, 3.0, 10.0, 9.0, 1.5, 1.5, 200, 200, 'outback.com', ARRAY['outback caesar salad'], '260 cal per salad (~200g)'),
-- Wedge Salad w/ Dressing (~250g)
('outback_wedge_salad', 'Outback Wedge Salad w/ Dressing', 176.0, 4.0, 8.4, 18.4, 1.6, 4.0, 250, 250, 'outback.com', ARRAY['outback wedge salad'], '440 cal per salad (~250g)'),
-- Steamed Broccoli (~150g)
('outback_steamed_broccoli', 'Outback Steamed Fresh Broccoli', 40.0, 3.3, 4.0, 1.3, 2.0, 1.3, 150, 150, 'outback.com', ARRAY['outback broccoli', 'outback steamed broccoli'], '60 cal per serving (~150g)'),
-- Grilled Asparagus (~120g)
('outback_grilled_asparagus', 'Outback Grilled Asparagus', 58.3, 3.3, 3.3, 3.3, 1.7, 1.7, 120, 120, 'outback.com', ARRAY['outback asparagus'], '70 cal per serving (~120g)'),
-- Chocolate Thunder From Down Under (~300g)
('outback_chocolate_thunder', 'Outback Chocolate Thunder From Down Under', 546.7, 5.0, 60.0, 30.0, 3.3, 43.3, 300, 300, 'outback.com', ARRAY['outback chocolate thunder', 'outback chocolate dessert'], '1640 cal per serving (~300g)'),
-- NY Cheesecake (~200g)
('outback_ny_cheesecake', 'Outback New York Style Cheesecake', 355.0, 6.0, 32.5, 22.5, 0.5, 22.0, 200, 200, 'outback.com', ARRAY['outback cheesecake', 'outback ny cheesecake'], '710 cal per slice (~200g)'),
-- Steak Fries (~200g)
('outback_steak_fries', 'Outback Steak Fries', 205.0, 3.0, 26.0, 10.0, 2.0, 0.5, 200, 200, 'outback.com', ARRAY['outback fries', 'outback steak fries'], '410 cal per serving (~200g)'),
-- Mac A Roo n Cheese (~250g)
('outback_mac_n_cheese', 'Outback Mac A Roo n'' Cheese', 280.0, 10.0, 24.0, 16.0, 0.8, 2.0, 250, 250, 'outback.com', ARRAY['outback mac and cheese', 'outback mac n cheese'], '700 cal per serving (~250g)'),
-- Fresh Fruit (~150g)
('outback_fresh_fruit', 'Outback Fresh Fruit', 33.3, 0.7, 8.0, 0.3, 1.3, 6.0, 150, 150, 'outback.com', ARRAY['outback fruit', 'outback fresh fruit'], '50 cal per serving (~150g)'),

-- ============================================
-- 5. RED LOBSTER
-- Source: redlobster.com, fastfoodnutrition.org
-- ============================================

-- Cheddar Bay Biscuit (~60g)
('red_lobster_cheddar_bay_biscuit', 'Red Lobster Cheddar Bay Biscuit', 266.7, 3.3, 26.7, 16.7, 0.8, 1.7, 60, 60, 'redlobster.com', ARRAY['red lobster biscuit', 'red lobster cheddar bay biscuit', 'cheddar bay biscuit'], '160 cal per biscuit (~60g)'),
-- Admiral's Feast (~500g)
('red_lobster_admirals_feast', 'Red Lobster Admiral''s Feast', 284.0, 14.0, 28.0, 12.0, 2.0, 2.0, 500, 500, 'redlobster.com', ARRAY['red lobster admirals feast', 'red lobster admiral feast'], '1420 cal per serving (~500g)'),
-- Live Maine Lobster (~500g / 1.25lb)
('red_lobster_live_maine_lobster', 'Red Lobster Live Maine Lobster', 88.0, 16.0, 2.0, 1.6, 0.0, 0.0, 500, 500, 'redlobster.com', ARRAY['red lobster maine lobster', 'red lobster live lobster'], '440 cal per lobster (~500g)'),
-- Snow Crab Legs (~400g)
('red_lobster_snow_crab_legs', 'Red Lobster Snow Crab Legs', 110.0, 20.0, 0.5, 4.0, 0.0, 0.0, 400, 400, 'redlobster.com', ARRAY['red lobster snow crab', 'red lobster crab legs'], '440 cal per serving (~400g)'),
-- Rock Lobster Tail (~250g)
('red_lobster_rock_lobster_tail', 'Red Lobster Rock Lobster Tail', 284.0, 20.0, 20.0, 14.0, 0.4, 1.2, 250, 250, 'redlobster.com', ARRAY['red lobster lobster tail', 'red lobster rock lobster'], '710 cal per serving (~250g)'),
-- Walt's Favorite Shrimp (~250g)
('red_lobster_walts_favorite_shrimp', 'Red Lobster Walt''s Favorite Shrimp', 248.0, 12.0, 24.0, 10.4, 1.2, 1.2, 250, 250, 'redlobster.com', ARRAY['red lobster walts shrimp', 'red lobster hand breaded shrimp'], '620 cal per serving (~250g)'),
-- Garlic Shrimp Scampi (~250g)
('red_lobster_garlic_shrimp_scampi', 'Red Lobster Garlic Shrimp Scampi', 140.0, 16.0, 1.6, 7.6, 0.4, 0.4, 250, 250, 'redlobster.com', ARRAY['red lobster shrimp scampi', 'red lobster scampi'], '350 cal per serving (~250g)'),
-- Parrot Isle Coconut Shrimp (~300g)
('red_lobster_coconut_shrimp', 'Red Lobster Parrot Isle Jumbo Coconut Shrimp', 320.0, 8.0, 32.0, 16.0, 2.0, 8.0, 300, 300, 'redlobster.com', ARRAY['red lobster coconut shrimp', 'red lobster parrot isle shrimp'], '960 cal per serving (~300g)'),
-- Seaside Shrimp Trio (~400g)
('red_lobster_seaside_shrimp_trio', 'Red Lobster Seaside Shrimp Trio', 325.0, 13.0, 30.0, 14.0, 1.5, 3.0, 400, 400, 'redlobster.com', ARRAY['red lobster shrimp trio', 'red lobster seaside trio'], '1300 cal per serving (~400g)'),
-- Fish and Chips (~350g)
('red_lobster_fish_and_chips', 'Red Lobster Fish and Chips', 257.1, 10.3, 27.1, 11.4, 2.0, 1.1, 350, 350, 'redlobster.com', ARRAY['red lobster fish and chips', 'red lobster fish chips'], '900 cal per serving (~350g)'),
-- Parmesan-Crusted Fresh Tilapia (~250g)
('red_lobster_parmesan_tilapia', 'Red Lobster Parmesan-Crusted Fresh Tilapia', 220.0, 16.0, 12.0, 10.0, 0.4, 0.8, 250, 250, 'redlobster.com', ARRAY['red lobster tilapia', 'red lobster parmesan tilapia'], '550 cal per serving (~250g)'),
-- Maple-Glazed Chicken (~250g)
('red_lobster_maple_glazed_chicken', 'Red Lobster Maple-Glazed Chicken', 188.0, 22.0, 10.0, 6.0, 0.4, 6.0, 250, 250, 'redlobster.com', ARRAY['red lobster chicken', 'red lobster maple chicken'], '470 cal per serving (~250g)'),
-- Wood-Grilled Peppercorn Sirloin (~300g)
('red_lobster_peppercorn_sirloin', 'Red Lobster Wood-Grilled Peppercorn Sirloin', 216.7, 22.0, 6.7, 10.7, 0.7, 1.3, 300, 300, 'redlobster.com', ARRAY['red lobster sirloin', 'red lobster steak'], '650 cal per serving (~300g)'),
-- Salmon New Orleans (~300g)
('red_lobster_salmon_new_orleans', 'Red Lobster Salmon New Orleans', 226.7, 18.0, 8.7, 13.3, 0.7, 2.0, 300, 300, 'redlobster.com', ARRAY['red lobster salmon', 'red lobster salmon new orleans'], '680 cal per serving (~300g)'),
-- Shrimp Linguini Alfredo (~400g)
('red_lobster_shrimp_linguini_alfredo', 'Red Lobster Shrimp Linguini Alfredo', 335.0, 11.0, 32.5, 16.3, 1.5, 2.5, 400, 400, 'redlobster.com', ARRAY['red lobster alfredo', 'red lobster shrimp pasta'], '1340 cal per serving (~400g)'),
-- Chocolate Wave (~200g)
('red_lobster_chocolate_wave', 'Red Lobster Chocolate Wave', 565.0, 6.0, 62.5, 30.0, 3.0, 45.0, 200, 200, 'redlobster.com', ARRAY['red lobster chocolate wave', 'red lobster chocolate cake'], '1130 cal per serving (~200g)'),
-- Key Lime Pie (~150g)
('red_lobster_key_lime_pie', 'Red Lobster Key Lime Pie', 266.7, 4.0, 32.0, 14.0, 0.7, 22.0, 150, 150, 'redlobster.com', ARRAY['red lobster key lime pie'], '400 cal per slice (~150g)'),
-- Strawberry Cheesecake (~180g)
('red_lobster_strawberry_cheesecake', 'Red Lobster Strawberry Cheesecake', 327.8, 5.6, 34.4, 18.3, 0.6, 23.3, 180, 180, 'redlobster.com', ARRAY['red lobster cheesecake', 'red lobster strawberry cheesecake'], '590 cal per slice (~180g)'),
-- Crispy Calamari (~350g)
('red_lobster_crispy_calamari', 'Red Lobster Crispy Calamari and Vegetables', 505.7, 12.9, 44.3, 28.6, 3.4, 4.0, 350, 350, 'redlobster.com', ARRAY['red lobster calamari', 'red lobster fried calamari'], '1770 cal per serving (~350g)'),
-- Seafood-Stuffed Mushrooms (~200g)
('red_lobster_stuffed_mushrooms', 'Red Lobster Seafood-Stuffed Mushrooms', 220.0, 12.0, 14.0, 12.0, 1.0, 2.0, 200, 200, 'redlobster.com', ARRAY['red lobster stuffed mushrooms', 'red lobster mushrooms'], '440 cal per serving (~200g)'),
-- Shrimp Cocktail (~120g)
('red_lobster_shrimp_cocktail', 'Red Lobster Shrimp Cocktail', 108.3, 18.3, 6.7, 0.8, 0.8, 3.3, 120, 120, 'redlobster.com', ARRAY['red lobster shrimp cocktail'], '130 cal per serving (~120g)'),
-- Mashed Potatoes (~200g)
('red_lobster_mashed_potatoes', 'Red Lobster Mashed Potatoes', 95.0, 2.5, 14.0, 3.5, 1.0, 1.0, 200, 200, 'redlobster.com', ARRAY['red lobster mashed potatoes'], '190 cal per serving (~200g)'),
-- French Fries (~120g)
('red_lobster_french_fries', 'Red Lobster French Fries', 241.7, 3.3, 30.0, 11.7, 2.5, 0.0, 120, 120, 'redlobster.com', ARRAY['red lobster fries', 'red lobster french fries'], '290 cal per serving (~120g)'),
-- Coleslaw (~150g)
('red_lobster_coleslaw', 'Red Lobster Coleslaw', 173.3, 1.3, 14.0, 12.7, 2.0, 10.7, 150, 150, 'redlobster.com', ARRAY['red lobster coleslaw', 'red lobster cole slaw'], '260 cal per serving (~150g)'),
-- Wild Rice Pilaf (~150g)
('red_lobster_wild_rice_pilaf', 'Red Lobster Wild Rice Pilaf', 93.3, 2.7, 16.0, 2.0, 1.3, 0.7, 150, 150, 'redlobster.com', ARRAY['red lobster rice', 'red lobster wild rice'], '140 cal per serving (~150g)'),
-- Baked Potato (~250g)
('red_lobster_baked_potato', 'Red Lobster Baked Potato', 84.0, 3.2, 16.0, 1.2, 1.6, 0.8, 250, 250, 'redlobster.com', ARRAY['red lobster baked potato'], '210 cal per potato (~250g)'),

-- ============================================
-- 6. TEXAS ROADHOUSE
-- Source: texasroadhouse.com, texasroadhousenutritioncalculator.us
-- ============================================

-- 6oz Dallas Filet (~170g)
('texas_roadhouse_dallas_filet_6oz', 'Texas Roadhouse Dallas Filet (6 oz)', 158.8, 26.5, 3.5, 5.9, 1.2, 1.2, 170, 170, 'texasroadhouse.com', ARRAY['texas roadhouse filet', 'texas roadhouse dallas filet'], '270 cal per 6oz filet (~170g)'),
-- 8oz Dallas Filet (~227g)
('texas_roadhouse_dallas_filet_8oz', 'Texas Roadhouse Dallas Filet (8 oz)', 158.6, 26.4, 3.5, 5.7, 0.9, 0.9, 227, 227, 'texasroadhouse.com', ARRAY['texas roadhouse filet 8oz', 'texas roadhouse 8oz filet'], '360 cal per 8oz filet (~227g)'),
-- 6oz USDA Choice Sirloin (~170g)
('texas_roadhouse_sirloin_6oz', 'Texas Roadhouse USDA Choice Sirloin (6 oz)', 147.1, 27.1, 1.8, 3.5, 0.6, 0.6, 170, 170, 'texasroadhouse.com', ARRAY['texas roadhouse sirloin', 'texas roadhouse 6oz sirloin'], '250 cal per 6oz sirloin (~170g)'),
-- 12oz Ft. Worth Ribeye (~340g)
('texas_roadhouse_ribeye_12oz', 'Texas Roadhouse Ft. Worth Ribeye (12 oz)', 282.4, 22.9, 3.5, 21.2, 1.2, 0.6, 340, 340, 'texasroadhouse.com', ARRAY['texas roadhouse ribeye', 'texas roadhouse ft worth ribeye'], '960 cal per 12oz ribeye (~340g)'),
-- Bone-In Ribeye (~500g)
('texas_roadhouse_bone_in_ribeye', 'Texas Roadhouse Bone-In Ribeye', 296.0, 21.6, 1.0, 22.4, 0.6, 0.4, 500, 500, 'texasroadhouse.com', ARRAY['texas roadhouse bone in ribeye'], '1480 cal per bone-in ribeye (~500g)'),
-- Fall-off-the-Bone Ribs Full Slab (~650g)
('texas_roadhouse_ribs_full', 'Texas Roadhouse Fall-off-the-Bone Ribs (Full)', 223.1, 17.8, 2.3, 15.7, 0.6, 1.5, 650, 650, 'texasroadhouse.com', ARRAY['texas roadhouse full rack ribs', 'texas roadhouse ribs full slab'], '1450 cal per full slab (~650g)'),
-- Fall-off-the-Bone Ribs Half Slab (~350g)
('texas_roadhouse_ribs_half', 'Texas Roadhouse Fall-off-the-Bone Ribs (Half)', 257.1, 20.6, 2.6, 18.0, 0.9, 1.7, 350, 350, 'texasroadhouse.com', ARRAY['texas roadhouse half rack ribs', 'texas roadhouse ribs half'], '900 cal per half slab (~350g)'),
-- Grilled BBQ Chicken (~250g)
('texas_roadhouse_grilled_bbq_chicken', 'Texas Roadhouse Grilled BBQ Chicken', 120.0, 18.4, 7.6, 1.4, 0.8, 6.0, 250, 250, 'texasroadhouse.com', ARRAY['texas roadhouse bbq chicken', 'texas roadhouse grilled chicken'], '300 cal per serving (~250g)'),
-- Herb Crusted Chicken (~220g)
('texas_roadhouse_herb_crusted_chicken', 'Texas Roadhouse Herb Crusted Chicken', 118.2, 21.4, 5.5, 1.8, 1.8, 3.6, 220, 220, 'texasroadhouse.com', ARRAY['texas roadhouse herb chicken', 'texas roadhouse herb crusted chicken'], '260 cal per serving (~220g)'),
-- Country Fried Chicken (~300g)
('texas_roadhouse_country_fried_chicken', 'Texas Roadhouse Country Fried Chicken', 250.0, 15.0, 15.0, 12.0, 1.0, 1.0, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse country fried chicken', 'texas roadhouse fried chicken'], '750 cal per serving (~300g)'),
-- Chicken Critters (~200g)
('texas_roadhouse_chicken_critters', 'Texas Roadhouse Chicken Critters', 240.0, 22.5, 13.0, 10.5, 1.5, 1.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse chicken critters', 'texas roadhouse chicken tenders'], '480 cal per serving (~200g)'),
-- Grilled Salmon 5oz (~140g)
('texas_roadhouse_grilled_salmon_5oz', 'Texas Roadhouse Grilled Salmon (5 oz)', 292.9, 19.3, 1.4, 23.6, 0.0, 0.0, 140, 140, 'texasroadhouse.com', ARRAY['texas roadhouse salmon', 'texas roadhouse grilled salmon'], '410 cal per 5oz (~140g)'),
-- Fish and Chips (~400g)
('texas_roadhouse_fish_and_chips', 'Texas Roadhouse Fish and Chips', 197.5, 10.5, 17.8, 9.5, 2.0, 0.5, 400, 400, 'texasroadhouse.com', ARRAY['texas roadhouse fish and chips', 'texas roadhouse fish chips'], '790 cal per serving (~400g)'),
-- Fresh Baked Bread (roll) (~60g)
('texas_roadhouse_bread_roll', 'Texas Roadhouse Fresh Baked Bread Roll', 200.0, 5.0, 30.0, 5.0, 1.7, 5.0, 60, 60, 'texasroadhouse.com', ARRAY['texas roadhouse roll', 'texas roadhouse bread', 'texas roadhouse rolls'], '120 cal per roll (~60g)'),
-- Honey Cinnamon Butter (~30g)
('texas_roadhouse_honey_cinnamon_butter', 'Texas Roadhouse Honey Cinnamon Butter', 333.3, 0.0, 20.0, 26.7, 0.0, 16.7, 30, 30, 'texasroadhouse.com', ARRAY['texas roadhouse butter', 'texas roadhouse cinnamon butter'], '100 cal per serving (~30g)'),
-- Cactus Blossom (~500g)
('texas_roadhouse_cactus_blossom', 'Texas Roadhouse Cactus Blossom', 450.0, 5.0, 47.2, 27.0, 3.8, 7.2, 500, 500, 'texasroadhouse.com', ARRAY['texas roadhouse cactus blossom', 'texas roadhouse onion blossom'], '2250 cal per appetizer (~500g)'),
-- Fried Pickles (~200g)
('texas_roadhouse_fried_pickles', 'Texas Roadhouse Fried Pickles', 275.0, 5.0, 30.0, 13.0, 2.5, 3.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse fried pickles', 'texas roadhouse pickles'], '550 cal per serving (~200g)'),
-- Rattlesnake Bites (~200g)
('texas_roadhouse_rattlesnake_bites', 'Texas Roadhouse Rattlesnake Bites', 280.0, 8.0, 28.0, 14.0, 2.0, 2.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse rattlesnake bites', 'texas roadhouse jalapeno bites'], '560 cal per serving (~200g)'),
-- Cheese Fries (~400g)
('texas_roadhouse_cheese_fries', 'Texas Roadhouse Cheese Fries', 310.0, 9.5, 31.5, 16.3, 3.5, 0.5, 400, 400, 'texasroadhouse.com', ARRAY['texas roadhouse cheese fries'], '1240 cal per serving (~400g)'),
-- Mashed Potatoes (~200g)
('texas_roadhouse_mashed_potatoes', 'Texas Roadhouse Mashed Potatoes', 110.0, 2.5, 16.0, 4.5, 1.0, 1.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse mashed potatoes'], '220 cal per serving (~200g)'),
-- Green Beans (~150g)
('texas_roadhouse_green_beans', 'Texas Roadhouse Green Beans', 66.7, 2.0, 8.0, 3.3, 2.7, 2.7, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse green beans'], '100 cal per serving (~150g)'),
-- Buttered Corn (~150g)
('texas_roadhouse_buttered_corn', 'Texas Roadhouse Buttered Corn', 140.0, 2.7, 18.7, 6.7, 2.0, 4.7, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse corn', 'texas roadhouse buttered corn'], '210 cal per serving (~150g)'),
-- Steak Fries (~150g)
('texas_roadhouse_steak_fries', 'Texas Roadhouse Steak Fries', 240.0, 2.7, 32.0, 11.3, 2.7, 0.0, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse fries', 'texas roadhouse steak fries'], '360 cal per serving (~150g)'),
-- Loaded Baked Potato (~300g)
('texas_roadhouse_loaded_baked_potato', 'Texas Roadhouse Loaded Baked Potato', 216.7, 5.0, 26.7, 10.0, 2.3, 1.7, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse loaded potato', 'texas roadhouse baked potato'], '650 cal per potato (~300g)'),
-- Sweet Potato (~250g)
('texas_roadhouse_sweet_potato', 'Texas Roadhouse Sweet Potato', 140.0, 2.0, 24.0, 4.0, 3.2, 10.0, 250, 250, 'texasroadhouse.com', ARRAY['texas roadhouse sweet potato'], '350 cal per potato (~250g)'),
-- Coleslaw (~150g)
('texas_roadhouse_coleslaw', 'Texas Roadhouse Coleslaw', 220.0, 1.3, 16.0, 16.7, 2.0, 12.0, 150, 150, 'texasroadhouse.com', ARRAY['texas roadhouse coleslaw', 'texas roadhouse cole slaw'], '330 cal per serving (~150g)'),
-- Strawberry Cheesecake (~200g)
('texas_roadhouse_strawberry_cheesecake', 'Texas Roadhouse Strawberry Cheesecake', 390.0, 6.0, 37.0, 22.0, 1.0, 27.0, 200, 200, 'texasroadhouse.com', ARRAY['texas roadhouse cheesecake', 'texas roadhouse strawberry cheesecake'], '780 cal per slice (~200g)'),
-- Big Ol Brownie (~250g)
('texas_roadhouse_brownie', 'Texas Roadhouse Big Ol'' Brownie', 492.0, 6.0, 56.0, 24.0, 2.4, 40.0, 250, 250, 'texasroadhouse.com', ARRAY['texas roadhouse brownie', 'texas roadhouse big brownie'], '1230 cal per serving (~250g)'),
-- Granny's Apple Classic (~300g)
('texas_roadhouse_grannys_apple', 'Texas Roadhouse Granny''s Apple Classic', 420.0, 4.0, 58.0, 18.0, 2.7, 36.0, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse apple dessert', 'texas roadhouse grannys apple'], '1260 cal per serving (~300g)'),
-- All-American Cheeseburger (~300g)
('texas_roadhouse_cheeseburger', 'Texas Roadhouse All-American Cheeseburger', 336.7, 14.0, 23.3, 21.0, 1.3, 4.0, 300, 300, 'texasroadhouse.com', ARRAY['texas roadhouse cheeseburger', 'texas roadhouse burger'], '1010 cal per burger (~300g)'),
-- Smokehouse Burger (~350g)
('texas_roadhouse_smokehouse_burger', 'Texas Roadhouse Smokehouse Burger', 342.9, 13.7, 22.9, 20.0, 1.4, 4.6, 350, 350, 'texasroadhouse.com', ARRAY['texas roadhouse smokehouse burger'], '1200 cal per burger (~350g)'),
-- Country Fried Sirloin (~400g)
('texas_roadhouse_country_fried_sirloin', 'Texas Roadhouse Country Fried Sirloin', 275.0, 13.0, 20.0, 15.0, 1.5, 1.5, 400, 400, 'texasroadhouse.com', ARRAY['texas roadhouse country fried sirloin'], '1100 cal per serving (~400g)')

-- ============================================
-- 7. TGI FRIDAY'S
-- Source: tgifridays.com, fastfoodnutrition.org
-- ============================================

-- Loaded Potato Skins (~300g)
('tgi_fridays_loaded_potato_skins', 'TGI Friday''s Loaded Potato Skins', 306.7, 8.7, 20.0, 19.3, 2.0, 2.0, 300, 300, 'tgifridays.com', ARRAY['tgi fridays potato skins', 'fridays potato skins'], '920 cal per serving (~300g)'),
-- Mozzarella Sticks (~200g)
('tgi_fridays_mozzarella_sticks', 'TGI Friday''s Mozzarella Sticks', 285.0, 14.0, 25.0, 14.0, 1.0, 2.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays mozzarella sticks', 'fridays mozz sticks'], '570 cal per serving (~200g)'),
-- Spinach & Artichoke Dip (~300g)
('tgi_fridays_spinach_artichoke_dip', 'TGI Friday''s Spinach & Artichoke Dip', 240.0, 6.7, 20.0, 14.7, 2.0, 2.7, 300, 300, 'tgifridays.com', ARRAY['tgi fridays spinach dip', 'fridays artichoke dip'], '720 cal per serving (~300g)'),
-- Boneless Wings (~300g)
('tgi_fridays_boneless_wings', 'TGI Friday''s Boneless Wings', 296.7, 16.7, 23.3, 14.0, 1.3, 5.0, 300, 300, 'tgifridays.com', ARRAY['tgi fridays boneless wings', 'fridays wings boneless'], '890 cal per serving (~300g)'),
-- Wings Appetizer (bone-in ~300g)
('tgi_fridays_wings', 'TGI Friday''s Wings', 266.7, 21.3, 8.0, 15.3, 0.7, 3.3, 300, 300, 'tgifridays.com', ARRAY['tgi fridays wings', 'fridays wings'], '800 cal per serving (~300g)'),
-- Chicken Quesadilla (~400g)
('tgi_fridays_chicken_quesadilla', 'TGI Friday''s Chicken Quesadilla', 405.0, 15.0, 32.5, 22.5, 2.5, 2.5, 400, 400, 'tgifridays.com', ARRAY['tgi fridays quesadilla', 'fridays chicken quesadilla'], '1620 cal per serving (~400g)'),
-- Tostado Nachos (~500g)
('tgi_fridays_tostado_nachos', 'TGI Friday''s Tostado Nachos', 390.0, 10.0, 34.0, 22.0, 4.0, 4.0, 500, 500, 'tgifridays.com', ARRAY['tgi fridays nachos', 'fridays nachos'], '1950 cal per serving (~500g)'),
-- Pan-Seared Pot Stickers (~200g)
('tgi_fridays_pot_stickers', 'TGI Friday''s Pan-Seared Pot Stickers', 195.0, 8.5, 22.0, 7.5, 1.5, 4.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays pot stickers', 'fridays potstickers'], '390 cal per serving (~200g)'),
-- Giant Soft Pretzel (~200g)
('tgi_fridays_soft_pretzel', 'TGI Friday''s Giant Soft Pretzel', 315.0, 7.5, 48.0, 9.5, 2.0, 3.5, 200, 200, 'tgifridays.com', ARRAY['tgi fridays pretzel', 'fridays soft pretzel'], '630 cal per pretzel (~200g)'),
-- Cheeseburger (~250g)
('tgi_fridays_cheeseburger', 'TGI Friday''s Cheeseburger', 252.0, 12.8, 20.0, 14.0, 1.2, 3.2, 250, 250, 'tgifridays.com', ARRAY['tgi fridays cheeseburger', 'fridays burger'], '630 cal per burger (~250g)'),
-- Bacon Cheeseburger (~280g)
('tgi_fridays_bacon_cheeseburger', 'TGI Friday''s Bacon Cheeseburger', 250.0, 13.6, 18.2, 14.6, 1.1, 3.2, 280, 280, 'tgifridays.com', ARRAY['tgi fridays bacon cheeseburger', 'fridays bacon burger'], '700 cal per burger (~280g)'),
-- Whiskey-Glazed Burger (~350g)
('tgi_fridays_whiskey_glazed_burger', 'TGI Friday''s Whiskey-Glazed Burger', 277.1, 12.6, 21.4, 16.0, 1.4, 6.0, 350, 350, 'tgifridays.com', ARRAY['tgi fridays whiskey burger', 'fridays whiskey glazed burger'], '970 cal per burger (~350g)'),
-- Crispy Chicken Tenders with Fries (~350g)
('tgi_fridays_chicken_tenders', 'TGI Friday''s Crispy Chicken Tenders with Fries', 288.6, 14.6, 24.6, 14.3, 2.3, 1.4, 350, 350, 'tgifridays.com', ARRAY['tgi fridays chicken tenders', 'fridays chicken tenders'], '1010 cal per serving (~350g)'),
-- Whiskey-Glazed Chicken (~350g)
('tgi_fridays_whiskey_glazed_chicken', 'TGI Friday''s Whiskey-Glazed Chicken', 274.3, 14.3, 18.6, 13.1, 0.9, 10.3, 350, 350, 'tgifridays.com', ARRAY['tgi fridays whiskey chicken', 'fridays glazed chicken'], '960 cal per serving (~350g)'),
-- Simply Grilled Salmon (~300g)
('tgi_fridays_grilled_salmon', 'TGI Friday''s Simply Grilled Salmon', 240.0, 16.7, 3.3, 16.7, 0.3, 0.7, 300, 300, 'tgifridays.com', ARRAY['tgi fridays salmon', 'fridays grilled salmon'], '720 cal per serving (~300g)'),
-- Dragon-Glaze Salmon (~300g)
('tgi_fridays_dragon_glaze_salmon', 'TGI Friday''s Dragon-Glaze Salmon', 266.7, 14.0, 16.7, 15.3, 0.7, 8.0, 300, 300, 'tgifridays.com', ARRAY['tgi fridays dragon salmon', 'fridays dragon glaze salmon'], '800 cal per serving (~300g)'),
-- Fish and Chips (~400g)
('tgi_fridays_fish_and_chips', 'TGI Friday''s Fish & Chips', 295.0, 10.0, 28.8, 14.5, 2.5, 1.0, 400, 400, 'tgifridays.com', ARRAY['tgi fridays fish and chips', 'fridays fish chips'], '1180 cal per serving (~400g)'),
-- BBQ Chicken Salad (~350g)
('tgi_fridays_bbq_chicken_salad', 'TGI Friday''s BBQ Chicken Salad', 220.0, 12.6, 15.4, 10.0, 3.1, 6.3, 350, 350, 'tgifridays.com', ARRAY['tgi fridays bbq chicken salad', 'fridays bbq salad'], '770 cal per salad (~350g)'),
-- Caesar Salad with Grilled Chicken (~300g)
('tgi_fridays_caesar_salad_chicken', 'TGI Friday''s Caesar Salad with Grilled Chicken', 193.3, 16.0, 10.0, 10.0, 2.0, 1.7, 300, 300, 'tgifridays.com', ARRAY['tgi fridays caesar salad', 'fridays chicken caesar'], '580 cal per salad (~300g)'),
-- Million Dollar Cobb Salad (~350g)
('tgi_fridays_cobb_salad', 'TGI Friday''s Million Dollar Cobb Salad', 220.0, 12.3, 10.3, 14.0, 2.6, 2.9, 350, 350, 'tgifridays.com', ARRAY['tgi fridays cobb salad', 'fridays cobb salad'], '770 cal per salad (~350g)'),
-- Bucket of Bones (~450g)
('tgi_fridays_bucket_of_bones', 'TGI Friday''s Bucket of Bones', 348.9, 22.2, 11.1, 20.0, 0.9, 5.6, 450, 450, 'tgifridays.com', ARRAY['tgi fridays bucket of bones', 'fridays ribs'], '1570 cal per serving (~450g)'),
-- Brownie Obsession (~250g)
('tgi_fridays_brownie_obsession', 'TGI Friday''s Brownie Obsession', 376.0, 5.2, 44.0, 20.0, 2.4, 32.0, 250, 250, 'tgifridays.com', ARRAY['tgi fridays brownie', 'fridays brownie obsession'], '940 cal per serving (~250g)'),
-- Oreo Madness (~200g)
('tgi_fridays_oreo_madness', 'TGI Friday''s Oreo Madness', 335.0, 5.0, 40.0, 17.0, 1.5, 28.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays oreo madness', 'fridays oreo dessert'], '670 cal per serving (~200g)'),
-- Donut Cheesecake (~200g)
('tgi_fridays_donut_cheesecake', 'TGI Friday''s Donut Cheesecake', 435.0, 6.5, 42.0, 25.0, 1.0, 30.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays cheesecake', 'fridays donut cheesecake'], '870 cal per serving (~200g)'),
-- Green Bean Fries (~250g)
('tgi_fridays_green_bean_fries', 'TGI Friday''s Green Bean Fries', 360.0, 6.0, 32.0, 20.0, 4.0, 4.0, 250, 250, 'tgifridays.com', ARRAY['tgi fridays green bean fries', 'fridays green bean fries'], '900 cal per serving (~250g)'),
-- Chips & Salsa (~200g)
('tgi_fridays_chips_salsa', 'TGI Friday''s Chips & Salsa', 140.0, 2.0, 20.0, 6.0, 2.0, 2.0, 200, 200, 'tgifridays.com', ARRAY['tgi fridays chips salsa', 'fridays chips and salsa'], '280 cal per serving (~200g)'),
-- Red Velvet Cake (~250g)
('tgi_fridays_red_velvet_cake', 'TGI Friday''s Red Velvet Cake', 520.0, 4.8, 56.0, 28.0, 1.2, 44.0, 250, 250, 'tgifridays.com', ARRAY['tgi fridays red velvet', 'fridays red velvet cake'], '1300 cal per slice (~250g)'),

-- ============================================
-- 8. CHEESECAKE FACTORY
-- Source: thecheesecakefactory.com, fastfoodnutrition.org
-- ============================================

-- Original Cheesecake (~200g)
('cheesecake_factory_original_cheesecake', 'Cheesecake Factory Original Cheesecake', 415.0, 4.0, 23.5, 30.0, 0.5, 18.0, 200, 200, 'thecheesecakefactory.com', ARRAY['cheesecake factory original', 'cheesecake factory plain cheesecake'], '830 cal per slice (~200g)'),
-- Oreo Dream Extreme Cheesecake (~250g)
('cheesecake_factory_oreo_dream', 'Cheesecake Factory Oreo Dream Extreme Cheesecake', 648.0, 5.6, 60.0, 40.0, 2.0, 48.0, 250, 250, 'thecheesecakefactory.com', ARRAY['cheesecake factory oreo cheesecake', 'cheesecake factory oreo dream'], '1620 cal per slice (~250g)'),
-- Fresh Strawberry Cheesecake (~200g)
('cheesecake_factory_strawberry_cheesecake', 'Cheesecake Factory Fresh Strawberry Cheesecake', 500.0, 4.5, 28.0, 26.5, 1.0, 20.0, 200, 200, 'thecheesecakefactory.com', ARRAY['cheesecake factory strawberry', 'cheesecake factory strawberry cheesecake'], '1000 cal per slice (~200g)'),
-- Godiva Chocolate Cheesecake (~230g)
('cheesecake_factory_godiva_chocolate', 'Cheesecake Factory Godiva Chocolate Cheesecake', 608.7, 5.2, 52.2, 37.4, 2.6, 40.0, 230, 230, 'thecheesecakefactory.com', ARRAY['cheesecake factory godiva', 'cheesecake factory chocolate cheesecake'], '1400 cal per slice (~230g)'),
-- Dulce De Leche Cheesecake (~230g)
('cheesecake_factory_dulce_de_leche', 'Cheesecake Factory Dulce De Leche Caramel Cheesecake', 604.3, 5.2, 50.0, 37.0, 0.9, 40.0, 230, 230, 'thecheesecakefactory.com', ARRAY['cheesecake factory dulce de leche', 'cheesecake factory caramel cheesecake'], '1390 cal per slice (~230g)'),
-- Low Carb Cheesecake (~180g)
('cheesecake_factory_low_carb', 'Cheesecake Factory Low Carb Cheesecake', 338.9, 5.6, 16.7, 26.7, 1.1, 8.3, 180, 180, 'thecheesecakefactory.com', ARRAY['cheesecake factory low carb', 'cheesecake factory keto cheesecake'], '610 cal per slice (~180g)'),
-- Tiramisu Cheesecake (~200g)
('cheesecake_factory_tiramisu_cheesecake', 'Cheesecake Factory Tiramisu Cheesecake', 480.0, 5.0, 38.0, 30.0, 1.0, 28.0, 200, 200, 'thecheesecakefactory.com', ARRAY['cheesecake factory tiramisu'], '960 cal per slice (~200g)'),
-- Chicken Madeira (~400g)
('cheesecake_factory_chicken_madeira', 'Cheesecake Factory Chicken Madeira', 337.5, 17.5, 17.5, 17.5, 1.3, 3.8, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory chicken madeira', 'cheesecake factory madeira chicken'], '1350 cal per serving (~400g)'),
-- Louisiana Chicken Pasta (~500g)
('cheesecake_factory_louisiana_chicken_pasta', 'Cheesecake Factory Louisiana Chicken Pasta', 330.0, 12.0, 30.0, 16.0, 2.0, 4.0, 500, 500, 'thecheesecakefactory.com', ARRAY['cheesecake factory louisiana pasta', 'cheesecake factory cajun pasta'], '1650 cal per serving (~500g)'),
-- Fettuccini Alfredo (~450g)
('cheesecake_factory_fettuccini_alfredo', 'Cheesecake Factory Fettuccini Alfredo', 388.9, 8.9, 33.3, 22.2, 1.3, 2.2, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory alfredo', 'cheesecake factory fettuccine'], '1750 cal per serving (~450g)'),
-- Bistro Shrimp Pasta (~500g)
('cheesecake_factory_bistro_shrimp_pasta', 'Cheesecake Factory Bistro Shrimp Pasta', 356.0, 10.0, 32.0, 18.0, 2.0, 4.0, 500, 500, 'thecheesecakefactory.com', ARRAY['cheesecake factory shrimp pasta', 'cheesecake factory bistro shrimp'], '1780 cal per serving (~500g)'),
-- Pasta Carbonara (~450g)
('cheesecake_factory_pasta_carbonara', 'Cheesecake Factory Pasta Carbonara', 400.0, 11.1, 31.1, 22.2, 1.3, 2.2, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory carbonara'], '1800 cal per serving (~450g)'),
-- Americana Cheeseburger (~350g)
('cheesecake_factory_americana_cheeseburger', 'Cheesecake Factory Americana Cheeseburger', 400.0, 14.3, 28.6, 21.4, 1.4, 5.7, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory burger', 'cheesecake factory cheeseburger'], '1400 cal per burger (~350g)'),
-- Bacon Bacon Cheeseburger (~400g)
('cheesecake_factory_bacon_cheeseburger', 'Cheesecake Factory Bacon-Bacon Cheeseburger', 397.5, 14.5, 25.0, 23.0, 1.3, 5.0, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory bacon burger'], '1590 cal per burger (~400g)'),
-- Crispy Fried Chicken Sandwich (~400g)
('cheesecake_factory_fried_chicken_sandwich', 'Cheesecake Factory Crispy Fried Chicken Sandwich', 430.0, 12.5, 30.0, 25.0, 2.0, 4.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory chicken sandwich', 'cheesecake factory fried chicken sandwich'], '1720 cal per sandwich (~400g)'),
-- Herb Crusted Salmon (~400g)
('cheesecake_factory_herb_crusted_salmon', 'Cheesecake Factory Herb Crusted Filet of Salmon', 327.5, 17.5, 15.0, 20.0, 2.0, 2.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory salmon', 'cheesecake factory herb salmon'], '1310 cal per serving (~400g)'),
-- Fresh Grilled Salmon (~400g)
('cheesecake_factory_grilled_salmon', 'Cheesecake Factory Fresh Grilled Salmon', 310.0, 17.5, 12.5, 18.8, 2.5, 2.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory grilled salmon'], '1240 cal per serving (~400g)'),
-- Miso Salmon (~350g)
('cheesecake_factory_miso_salmon', 'Cheesecake Factory Miso Salmon', 382.9, 16.0, 22.9, 21.4, 1.7, 10.0, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory miso salmon'], '1340 cal per serving (~350g)'),
-- Shrimp Scampi (~400g)
('cheesecake_factory_shrimp_scampi', 'Cheesecake Factory Shrimp Scampi', 337.5, 12.5, 25.0, 17.5, 1.3, 2.5, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory shrimp scampi', 'cheesecake factory scampi'], '1350 cal per serving (~400g)'),
-- Fried Shrimp Platter (~450g)
('cheesecake_factory_fried_shrimp', 'Cheesecake Factory Fried Shrimp Platter', 426.7, 10.0, 38.9, 22.2, 2.7, 3.3, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory fried shrimp'], '1920 cal per serving (~450g)'),
-- Breakfast Burrito (~450g)
('cheesecake_factory_breakfast_burrito', 'Cheesecake Factory Breakfast Burrito', 433.3, 12.2, 30.0, 24.4, 3.3, 3.3, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory burrito', 'cheesecake factory breakfast burrito'], '1950 cal per burrito (~450g)'),
-- Bruleed French Toast (~400g)
('cheesecake_factory_french_toast', 'Cheesecake Factory Bruleed French Toast', 495.0, 5.0, 52.5, 27.5, 1.3, 30.0, 400, 400, 'thecheesecakefactory.com', ARRAY['cheesecake factory french toast', 'cheesecake factory bruleed french toast'], '1980 cal per serving (~400g)'),
-- Cinnamon Roll Pancakes (~450g)
('cheesecake_factory_cinnamon_roll_pancakes', 'Cheesecake Factory Cinnamon Roll Pancakes', 453.3, 5.6, 55.6, 22.2, 1.3, 33.3, 450, 450, 'thecheesecakefactory.com', ARRAY['cheesecake factory pancakes', 'cheesecake factory cinnamon pancakes'], '2040 cal per serving (~450g)'),
-- Chocolate Tower Truffle Cake (~250g)
('cheesecake_factory_chocolate_tower_cake', 'Cheesecake Factory Chocolate Tower Truffle Cake', 708.0, 5.6, 68.0, 42.0, 4.0, 52.0, 250, 250, 'thecheesecakefactory.com', ARRAY['cheesecake factory chocolate cake', 'cheesecake factory truffle cake'], '1770 cal per slice (~250g)'),
-- Godiva Chocolate Brownie Sundae (~350g)
('cheesecake_factory_brownie_sundae', 'Cheesecake Factory Godiva Chocolate Brownie Sundae', 500.0, 5.7, 54.3, 27.1, 2.9, 40.0, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory brownie sundae', 'cheesecake factory brownie'], '1750 cal per serving (~350g)'),
-- Avocado Eggrolls (~300g)
('cheesecake_factory_avocado_eggrolls', 'Cheesecake Factory Avocado Eggrolls', 440.0, 6.7, 33.3, 30.0, 4.7, 4.7, 300, 300, 'thecheesecakefactory.com', ARRAY['cheesecake factory avocado eggrolls', 'cheesecake factory eggrolls'], '1320 cal per serving (~300g)'),
-- Fried Mac and Cheese Bites (~250g)
('cheesecake_factory_fried_mac_cheese', 'Cheesecake Factory Fried Mac and Cheese', 440.0, 12.0, 36.0, 24.0, 1.2, 2.0, 250, 250, 'thecheesecakefactory.com', ARRAY['cheesecake factory mac and cheese bites', 'cheesecake factory fried mac'], '1100 cal per serving (~250g)'),
-- Cheese Flatbread Pizza (~350g)
('cheesecake_factory_cheese_flatbread', 'Cheesecake Factory Cheese Flatbread Pizza', 285.7, 10.0, 28.6, 14.3, 1.4, 2.9, 350, 350, 'thecheesecakefactory.com', ARRAY['cheesecake factory flatbread', 'cheesecake factory pizza'], '1000 cal per flatbread (~350g)'),
-- Kids French Fries (~120g)
('cheesecake_factory_french_fries', 'Cheesecake Factory French Fries', 250.0, 3.3, 30.0, 12.5, 2.5, 0.0, 120, 120, 'thecheesecakefactory.com', ARRAY['cheesecake factory fries', 'cheesecake factory french fries'], '300 cal per serving (~120g)')

-- ============================================
-- 9. ARBY'S
-- Source: arbys.com, fastfoodnutrition.org, nutritionvalue.org
-- ============================================

-- Classic Roast Beef (~154g)
('arbys_classic_roast_beef', 'Arby''s Classic Roast Beef', 233.8, 14.9, 24.0, 9.1, 1.3, 3.7, 154, 154, 'arbys.com', ARRAY['arbys roast beef', 'arbys classic roast beef'], '360 cal per sandwich (~154g)'),
-- Double Roast Beef (~220g)
('arbys_double_roast_beef', 'Arby''s Double Roast Beef', 254.5, 17.3, 19.5, 11.4, 0.9, 2.7, 220, 220, 'arbys.com', ARRAY['arbys double roast beef'], '560 cal per sandwich (~220g)'),
-- Half Pound Roast Beef (~280g)
('arbys_half_pound_roast_beef', 'Arby''s Half Pound Roast Beef', 250.0, 18.6, 16.1, 11.4, 0.7, 2.5, 280, 280, 'arbys.com', ARRAY['arbys half pound roast beef', 'arbys big roast beef'], '700 cal per sandwich (~280g)'),
-- Beef n Cheddar Classic (~200g)
('arbys_beef_n_cheddar', 'Arby''s Beef ''n Cheddar Classic', 225.0, 11.5, 22.5, 10.0, 1.0, 4.0, 200, 200, 'arbys.com', ARRAY['arbys beef and cheddar', 'arbys beef n cheddar'], '450 cal per sandwich (~200g)'),
-- Smokehouse Brisket (~300g)
('arbys_smokehouse_brisket', 'Arby''s Smokehouse Brisket', 290.0, 14.0, 22.0, 15.0, 1.3, 5.3, 300, 300, 'arbys.com', ARRAY['arbys brisket', 'arbys smokehouse brisket'], '870 cal per sandwich (~300g)'),
-- Crispy Chicken Sandwich (~200g)
('arbys_crispy_chicken_sandwich', 'Arby''s Classic Crispy Chicken Sandwich', 255.0, 11.5, 21.5, 12.5, 1.0, 2.5, 200, 200, 'arbys.com', ARRAY['arbys crispy chicken', 'arbys chicken sandwich'], '510 cal per sandwich (~200g)'),
-- Roast Turkey & Swiss (~300g)
('arbys_roast_turkey_swiss', 'Arby''s Roast Turkey & Swiss', 246.7, 14.3, 20.0, 12.0, 1.0, 3.3, 300, 300, 'arbys.com', ARRAY['arbys turkey sandwich', 'arbys turkey swiss'], '740 cal per sandwich (~300g)'),
-- Corned Beef Reuben (~300g)
('arbys_corned_beef_reuben', 'Arby''s Corned Beef Reuben', 256.7, 12.7, 20.0, 13.3, 1.3, 3.3, 300, 300, 'arbys.com', ARRAY['arbys reuben', 'arbys corned beef'], '770 cal per sandwich (~300g)'),
-- French Dip & Swiss (~280g)
('arbys_french_dip_swiss', 'Arby''s French Dip & Swiss', 221.4, 14.3, 18.2, 10.0, 0.7, 3.2, 280, 280, 'arbys.com', ARRAY['arbys french dip', 'arbys french dip swiss'], '620 cal per sandwich (~280g)'),
-- Gyro (Greek) (~250g)
('arbys_greek_gyro', 'Arby''s Greek Gyro', 276.0, 8.8, 20.0, 16.8, 1.2, 3.6, 250, 250, 'arbys.com', ARRAY['arbys gyro', 'arbys greek gyro'], '690 cal per gyro (~250g)'),
-- Curly Fries Medium (~130g)
('arbys_curly_fries_medium', 'Arby''s Curly Fries (Medium)', 323.1, 4.6, 36.2, 16.9, 3.1, 0.0, 130, 130, 'arbys.com', ARRAY['arbys curly fries', 'arbys fries medium'], '420 cal per medium (~130g)'),
-- Curly Fries Large (~180g)
('arbys_curly_fries_large', 'Arby''s Curly Fries (Large)', 338.9, 4.4, 36.7, 17.8, 3.3, 0.0, 180, 180, 'arbys.com', ARRAY['arbys curly fries large', 'arbys large fries'], '610 cal per large (~180g)'),
-- Crinkle Fries Medium (~130g)
('arbys_crinkle_fries_medium', 'Arby''s Crinkle Fries (Medium)', 300.0, 3.1, 36.9, 13.8, 2.3, 0.0, 130, 130, 'arbys.com', ARRAY['arbys crinkle fries', 'arbys regular fries'], '390 cal per medium (~130g)'),
-- Mozzarella Sticks (~140g)
('arbys_mozzarella_sticks', 'Arby''s Mozzarella Sticks', 342.9, 14.3, 22.9, 18.6, 1.4, 2.9, 140, 140, 'arbys.com', ARRAY['arbys mozzarella sticks', 'arbys mozz sticks'], '480 cal per 4 sticks (~140g)'),
-- Jalapeno Bites (~120g)
('arbys_jalapeno_bites', 'Arby''s Jalapeno Bites', 275.0, 5.8, 25.0, 15.0, 1.7, 2.5, 120, 120, 'arbys.com', ARRAY['arbys jalapeno bites', 'arbys jalapeno poppers'], '330 cal per serving (~120g)'),
-- Onion Rings (~140g)
('arbys_onion_rings', 'Arby''s Onion Rings', 321.4, 3.6, 32.9, 17.9, 2.1, 4.3, 140, 140, 'arbys.com', ARRAY['arbys onion rings'], '450 cal per serving (~140g)'),
-- Vanilla Shake (~400g)
('arbys_vanilla_shake', 'Arby''s Vanilla Shake (Medium)', 162.5, 5.8, 24.5, 5.3, 0.0, 18.5, 400, 400, 'arbys.com', ARRAY['arbys vanilla shake', 'arbys milkshake vanilla'], '650 cal per medium shake (~400g)'),
-- Chocolate Shake (~400g)
('arbys_chocolate_shake', 'Arby''s Chocolate Shake (Medium)', 167.5, 5.5, 26.3, 5.3, 0.5, 20.0, 400, 400, 'arbys.com', ARRAY['arbys chocolate shake', 'arbys milkshake chocolate'], '670 cal per medium shake (~400g)'),
-- Jamocha Shake (~400g)
('arbys_jamocha_shake', 'Arby''s Jamocha Shake (Medium)', 157.5, 5.3, 24.5, 5.0, 0.0, 18.0, 400, 400, 'arbys.com', ARRAY['arbys jamocha shake', 'arbys coffee shake'], '630 cal per medium shake (~400g)'),
-- Turnover (Apple or Cherry) (~90g)
('arbys_apple_turnover', 'Arby''s Apple Turnover', 300.0, 2.2, 33.3, 15.6, 1.1, 15.6, 90, 90, 'arbys.com', ARRAY['arbys turnover', 'arbys apple turnover'], '270 cal per turnover (~90g)'),
-- Chocolate Lava Cake (~110g)
('arbys_chocolate_lava_cake', 'Arby''s Chocolate Lava Cake', 318.2, 3.6, 40.0, 15.5, 1.8, 27.3, 110, 110, 'arbys.com', ARRAY['arbys lava cake', 'arbys chocolate cake'], '350 cal per cake (~110g)'),
-- Market Fresh Roast Turkey Ranch & Bacon (~350g)
('arbys_turkey_ranch_bacon', 'Arby''s Market Fresh Turkey Ranch & Bacon', 245.7, 12.9, 17.1, 12.9, 1.7, 2.9, 350, 350, 'arbys.com', ARRAY['arbys turkey ranch bacon', 'arbys market fresh turkey'], '860 cal per sandwich (~350g)'),
-- Loaded Italian (~300g)
('arbys_loaded_italian', 'Arby''s Loaded Italian', 303.3, 13.3, 20.0, 16.7, 1.3, 3.3, 300, 300, 'arbys.com', ARRAY['arbys loaded italian', 'arbys italian sub'], '910 cal per sandwich (~300g)'),
-- Chicken Nuggets (6 piece ~100g)
('arbys_chicken_nuggets', 'Arby''s Chicken Nuggets (6 pc)', 270.0, 12.0, 18.0, 14.0, 1.0, 0.0, 100, 100, 'arbys.com', ARRAY['arbys nuggets', 'arbys chicken nuggets'], '270 cal per 6 nuggets (~100g)'),
-- Side Salad (~120g)
('arbys_side_salad', 'Arby''s Side Salad', 20.8, 1.7, 3.3, 0.0, 1.7, 1.7, 120, 120, 'arbys.com', ARRAY['arbys salad', 'arbys side salad'], '25 cal per salad (~120g)'),
-- Potato Cakes (~120g)
('arbys_potato_cakes', 'Arby''s Potato Cakes (2 pc)', 233.3, 2.5, 26.7, 13.3, 2.5, 0.0, 120, 120, 'arbys.com', ARRAY['arbys potato cakes', 'arbys hash browns'], '280 cal per 2 cakes (~120g)'),

-- ============================================
-- 10. HARDEE'S / CARL'S JR.
-- Source: hardees.com, carlsjr.com, fastfoodnutrition.org
-- Note: Existing items NOT duplicated:
--   hardees_big_hot_ham_n_cheese, hardees_crispy_curls_medium,
--   hardees_vanilla_ice_cream_shake, hardees_spicy_chicken_tenders_3pc
-- ============================================

-- Famous Star with Cheese (~260g)
('hardees_famous_star_with_cheese', 'Hardee''s Famous Star with Cheese', 253.8, 10.4, 17.3, 15.0, 1.2, 3.5, 260, 260, 'hardees.com', ARRAY['hardees famous star', 'carls jr famous star'], '660 cal per burger (~260g)'),
-- Super Star with Cheese (~340g)
('hardees_super_star_with_cheese', 'Hardee''s Super Star with Cheese', 270.6, 15.0, 14.1, 15.6, 0.9, 2.6, 340, 340, 'hardees.com', ARRAY['hardees super star', 'carls jr super star'], '920 cal per burger (~340g)'),
-- Monster Double Thickburger (~450g)
('hardees_monster_thickburger', 'Hardee''s Monster Double Thickburger', 311.1, 16.0, 15.6, 20.0, 0.7, 2.2, 450, 450, 'hardees.com', ARRAY['hardees monster burger', 'hardees monster thickburger'], '1400 cal per burger (~450g)'),
-- Original Thickburger (~280g)
('hardees_original_thickburger', 'Hardee''s Original Thickburger', 292.9, 12.9, 18.2, 16.4, 0.7, 3.2, 280, 280, 'hardees.com', ARRAY['hardees thickburger', 'hardees original thickburger'], '820 cal per burger (~280g)'),
-- Frisco Thickburger (~280g)
('hardees_frisco_thickburger', 'Hardee''s Frisco Thickburger', 271.4, 12.5, 17.9, 14.3, 0.7, 3.2, 280, 280, 'hardees.com', ARRAY['hardees frisco burger', 'hardees frisco thickburger'], '760 cal per burger (~280g)'),
-- Western Bacon Cheeseburger (~300g)
('hardees_western_bacon_cheeseburger', 'Hardee''s Western Bacon Cheeseburger', 270.0, 10.7, 23.0, 13.3, 1.0, 5.3, 300, 300, 'hardees.com', ARRAY['hardees western bacon', 'carls jr western bacon'], '810 cal per burger (~300g)'),
-- Big Cheeseburger (~200g)
('hardees_big_cheeseburger', 'Hardee''s Big Cheeseburger', 270.0, 12.5, 19.0, 13.5, 0.5, 3.5, 200, 200, 'hardees.com', ARRAY['hardees big cheeseburger', 'hardees cheeseburger'], '540 cal per burger (~200g)'),
-- Small Cheeseburger (~130g)
('hardees_small_cheeseburger', 'Hardee''s Small Cheeseburger', 230.8, 10.8, 18.5, 10.0, 0.8, 3.1, 130, 130, 'hardees.com', ARRAY['hardees small cheeseburger'], '300 cal per burger (~130g)'),
-- Big Chicken Fillet Sandwich (~220g)
('hardees_chicken_fillet_sandwich', 'Hardee''s Big Chicken Fillet Sandwich', 268.2, 10.9, 21.4, 14.1, 0.9, 2.7, 220, 220, 'hardees.com', ARRAY['hardees chicken sandwich', 'hardees chicken fillet'], '590 cal per sandwich (~220g)'),
-- Charbroiled Chicken Club (~250g)
('hardees_charbroiled_chicken_club', 'Hardee''s Charbroiled Chicken Club', 260.0, 14.0, 14.4, 13.2, 0.8, 2.4, 250, 250, 'hardees.com', ARRAY['hardees chicken club', 'hardees charbroiled chicken'], '650 cal per sandwich (~250g)'),
-- Big Roast Beef (~200g)
('hardees_big_roast_beef', 'Hardee''s Big Roast Beef', 250.0, 12.0, 20.5, 11.5, 0.5, 2.5, 200, 200, 'hardees.com', ARRAY['hardees roast beef', 'hardees big roast beef'], '500 cal per sandwich (~200g)'),
-- Monster Roast Beef (~300g)
('hardees_monster_roast_beef', 'Hardee''s Monster Roast Beef', 290.0, 15.0, 18.7, 15.3, 0.7, 2.7, 300, 300, 'hardees.com', ARRAY['hardees monster roast beef'], '870 cal per sandwich (~300g)'),
-- Bacon Egg & Cheese Biscuit (~200g)
('hardees_bacon_egg_cheese_biscuit', 'Hardee''s Bacon, Egg & Cheese Biscuit', 310.0, 10.0, 20.0, 18.5, 0.5, 2.0, 200, 200, 'hardees.com', ARRAY['hardees bacon egg cheese', 'hardees BEC biscuit'], '620 cal per biscuit (~200g)'),
-- Sausage Biscuit (~190g)
('hardees_sausage_biscuit', 'Hardee''s Sausage Biscuit', 331.6, 8.4, 19.5, 22.6, 0.5, 1.6, 190, 190, 'hardees.com', ARRAY['hardees sausage biscuit'], '630 cal per biscuit (~190g)'),
-- Sausage & Egg Biscuit (~220g)
('hardees_sausage_egg_biscuit', 'Hardee''s Sausage & Egg Biscuit', 318.2, 10.0, 19.1, 20.9, 0.5, 1.4, 220, 220, 'hardees.com', ARRAY['hardees sausage egg biscuit'], '700 cal per biscuit (~220g)'),
-- Monster Biscuit (~300g)
('hardees_monster_biscuit', 'Hardee''s Monster Biscuit', 296.7, 10.0, 18.3, 20.0, 0.3, 1.3, 300, 300, 'hardees.com', ARRAY['hardees monster biscuit'], '890 cal per biscuit (~300g)'),
-- Biscuit n Gravy (~250g)
('hardees_biscuit_n_gravy', 'Hardee''s Biscuit ''N'' Gravy', 240.0, 5.2, 24.0, 12.4, 0.4, 1.6, 250, 250, 'hardees.com', ARRAY['hardees biscuit and gravy', 'hardees biscuit gravy'], '600 cal per serving (~250g)'),
-- Made from Scratch Biscuit (~80g)
('hardees_biscuit', 'Hardee''s Made from Scratch Biscuit', 325.0, 3.8, 27.5, 18.8, 0.6, 2.5, 80, 80, 'hardees.com', ARRAY['hardees biscuit', 'hardees plain biscuit'], '260 cal per biscuit (~80g)'),
-- Loaded Breakfast Burrito (~250g)
('hardees_loaded_breakfast_burrito', 'Hardee''s Loaded Breakfast Burrito', 232.0, 8.8, 16.0, 12.8, 1.2, 1.2, 250, 250, 'hardees.com', ARRAY['hardees breakfast burrito', 'hardees burrito'], '580 cal per burrito (~250g)'),
-- Frisco Breakfast Sandwich (~160g)
('hardees_frisco_breakfast_sandwich', 'Hardee''s Frisco Breakfast Sandwich', 268.8, 12.5, 14.4, 15.6, 0.6, 2.5, 160, 160, 'hardees.com', ARRAY['hardees frisco breakfast', 'hardees frisco sandwich'], '430 cal per sandwich (~160g)'),
-- Country Fried Steak Biscuit (~230g)
('hardees_country_fried_steak_biscuit', 'Hardee''s Country Fried Steak Biscuit', 282.6, 7.8, 23.9, 15.7, 0.4, 1.3, 230, 230, 'hardees.com', ARRAY['hardees country fried steak biscuit'], '650 cal per biscuit (~230g)'),
-- Chicken Fillet Biscuit (~220g)
('hardees_chicken_fillet_biscuit', 'Hardee''s Chicken Fillet Biscuit', 300.0, 10.0, 22.7, 16.4, 0.9, 2.3, 220, 220, 'hardees.com', ARRAY['hardees chicken biscuit', 'hardees chicken fillet biscuit'], '660 cal per biscuit (~220g)'),
-- Natural-Cut French Fries Medium (~140g)
('hardees_french_fries_medium', 'Hardee''s Natural-Cut French Fries (Medium)', 242.9, 3.6, 30.7, 11.4, 2.9, 0.0, 140, 140, 'hardees.com', ARRAY['hardees fries', 'hardees french fries', 'carls jr fries'], '340 cal per medium (~140g)'),
-- Onion Rings (~140g)
('hardees_onion_rings', 'Hardee''s Onion Rings', 478.6, 5.0, 42.9, 28.6, 2.9, 7.1, 140, 140, 'hardees.com', ARRAY['hardees onion rings', 'carls jr onion rings'], '670 cal per serving (~140g)'),
-- Cole Slaw (~120g)
('hardees_cole_slaw', 'Hardee''s Cole Slaw', 141.7, 1.7, 10.0, 10.8, 1.7, 6.7, 120, 120, 'hardees.com', ARRAY['hardees coleslaw', 'hardees cole slaw'], '170 cal per serving (~120g)'),
-- Green Beans (~100g)
('hardees_green_beans', 'Hardee''s Green Beans', 60.0, 2.0, 6.0, 2.0, 2.0, 2.0, 100, 100, 'hardees.com', ARRAY['hardees green beans'], '60 cal per serving (~100g)'),
-- Mashed Potatoes (~120g)
('hardees_mashed_potatoes', 'Hardee''s Mashed Potatoes', 75.0, 1.7, 12.5, 2.5, 0.8, 0.8, 120, 120, 'hardees.com', ARRAY['hardees mashed potatoes'], '90 cal per serving (~120g)'),
-- Apple Turnover (~90g)
('hardees_apple_turnover', 'Hardee''s Apple Turnover', 300.0, 2.2, 32.2, 15.6, 1.1, 14.4, 90, 90, 'hardees.com', ARRAY['hardees apple turnover', 'hardees turnover'], '270 cal per turnover (~90g)'),
-- Chocolate Chip Cookie (~50g)
('hardees_chocolate_chip_cookie', 'Hardee''s Chocolate Chip Cookie', 400.0, 4.0, 48.0, 18.0, 2.0, 28.0, 50, 50, 'hardees.com', ARRAY['hardees cookie', 'hardees chocolate chip cookie'], '200 cal per cookie (~50g)'),
-- Ice Cream Shake (Chocolate) (~450g)
('hardees_chocolate_shake', 'Hardee''s Chocolate Ice Cream Shake', 155.6, 5.8, 24.0, 4.4, 0.4, 17.8, 450, 450, 'hardees.com', ARRAY['hardees chocolate shake', 'hardees milkshake chocolate'], '700 cal per shake (~450g)'),
-- Jumbo Chili Dog (~200g)
('hardees_jumbo_chili_dog', 'Hardee''s Jumbo Chili Dog', 195.0, 7.5, 16.5, 11.5, 1.0, 3.0, 200, 200, 'hardees.com', ARRAY['hardees chili dog', 'hardees hot dog'], '390 cal per chili dog (~200g)'),
-- Redhook Beer-Battered Cod (~220g)
('hardees_cod_fish_sandwich', 'Hardee''s Beer-Battered Cod Fish Sandwich', 240.9, 8.6, 17.7, 8.2, 0.9, 2.3, 220, 220, 'hardees.com', ARRAY['hardees fish sandwich', 'hardees cod sandwich'], '530 cal per sandwich (~220g)'),
-- Beyond Thickburger (~300g)
('hardees_beyond_thickburger', 'Hardee''s Beyond Thickburger', 260.0, 9.3, 18.7, 14.3, 2.0, 3.0, 300, 300, 'hardees.com', ARRAY['hardees beyond burger', 'hardees plant based burger'], '780 cal per burger (~300g)'),
-- Hash Rounds Medium (~100g)
('hardees_hash_rounds', 'Hardee''s Hash Rounds (Medium)', 340.0, 3.0, 34.0, 20.0, 3.0, 0.0, 100, 100, 'hardees.com', ARRAY['hardees hash rounds', 'hardees hash browns'], '340 cal per medium (~100g)'),
-- Grits (~200g)
('hardees_grits', 'Hardee''s Grits', 50.0, 2.0, 10.0, 0.5, 0.5, 0.0, 200, 200, 'hardees.com', ARRAY['hardees grits'], '100 cal per serving (~200g)'),
-- Low Carb Breakfast Bowl (~250g)
('hardees_low_carb_breakfast_bowl', 'Hardee''s Low Carb Breakfast Bowl', 304.0, 17.2, 3.6, 24.0, 0.4, 1.2, 250, 250, 'hardees.com', ARRAY['hardees breakfast bowl', 'hardees low carb bowl'], '760 cal per bowl (~250g)')
