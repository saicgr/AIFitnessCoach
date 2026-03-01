-- 400_theme_park_food.sql
-- Theme park food items (~180 items) covering Disney World, Universal Orlando,
-- Dollywood, Six Flags, Hersheypark, Knott's Berry Farm, Cedar Point,
-- Busch Gardens, SeaWorld, and generic theme park fare.
-- Sources: USDA FoodData Central, nutritionix.com, calorieking.com, fatsecret.com,
-- mynetdiary.com, snapcalorie.com, official park allergy/nutrition guides,
-- theme park food blogs. All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g
) VALUES

-- ==========================================
-- DISNEY WORLD (~50 items)
-- ==========================================

-- Turkey leg: ~680g each, ~1093 cal total. Per 100g: 161 cal, 20P, 0C, 8.5F. Extremely high sodium (brined).
('disney_turkey_leg', 'Disney World Turkey Leg', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['disney turkey leg', 'magic kingdom turkey leg', 'theme park turkey leg'],
 'theme_park', 'Disney World', 1, '161 cal/100g. ~1093 cal per leg (~680g). Smoked, brined turkey drumstick.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Churros: USDA ~371 cal/100g. Disney churro ~100g each, 240-370 cal.
('disney_churro', 'Disney World Churro', 371, 5.0, 41.7, 20.0,
 1.7, 10.0, 100, 100,
 'theme_park', ARRAY['disney churro', 'magic kingdom churro', 'disneyland churro', 'disney cinnamon churro'],
 'theme_park', 'Disney World', 1, '371 cal/100g. ~370 cal per churro (~100g). Cinnamon sugar coated.', TRUE,
 220, 15, 5.0, 0.5, 60, 20, 1.2, 5, 0.0, 0, 10, 0.4, 45, 8.0, 0.01),

-- Dole Whip pineapple: per 100g ~93 cal. Half cup (86g) = 80 cal. Dairy-free, vegan.
('disney_dole_whip_pineapple', 'Disney Dole Whip Pineapple', 93, 0.0, 21.0, 0.6,
 0.0, 19.8, 170, NULL,
 'theme_park', ARRAY['dole whip', 'dole whip pineapple', 'disney dole whip', 'pineapple dole whip'],
 'theme_park', 'Disney World', 1, '93 cal/100g. ~158 cal per serving (170g). Dairy-free pineapple soft serve.', TRUE,
 35, 0, 0.3, 0.0, 40, 5, 0.1, 0, 5.0, 0, 4, 0.1, 5, 0.5, 0.0),

-- Dole Whip other flavors (orange, raspberry, etc.): similar profile.
('disney_dole_whip_other', 'Disney Dole Whip (Other Flavors)', 100, 0.0, 23.0, 0.6,
 0.0, 21.0, 170, NULL,
 'theme_park', ARRAY['dole whip orange', 'dole whip raspberry', 'dole whip strawberry', 'dole whip mango', 'dole whip lemon'],
 'theme_park', 'Disney World', 1, '100 cal/100g. ~170 cal per serving. Various fruit flavors, dairy-free.', TRUE,
 35, 0, 0.3, 0.0, 35, 5, 0.1, 2, 4.0, 0, 4, 0.1, 5, 0.5, 0.0),

-- Mickey pretzel: soft pretzel ~338 cal/100g, ~300g each (~1000 cal).
('disney_mickey_pretzel', 'Disney Mickey Pretzel', 338, 8.2, 69.6, 3.1,
 1.5, 2.0, 300, 300,
 'theme_park', ARRAY['mickey pretzel', 'disney pretzel', 'magic kingdom pretzel', 'mickey mouse pretzel'],
 'theme_park', 'Disney World', 1, '338 cal/100g. ~1014 cal per pretzel (~300g). Mickey-shaped soft pretzel with cheese dip.', TRUE,
 870, 0, 0.8, 0.0, 80, 15, 3.0, 0, 0.0, 0, 18, 0.6, 70, 12.0, 0.01),

-- Mickey ice cream bar: ~270 cal per bar (~80g). Per 100g: 338 cal.
('disney_mickey_ice_cream_bar', 'Disney Mickey Ice Cream Bar', 338, 4.0, 35.0, 20.0,
 1.0, 28.0, 80, 80,
 'theme_park', ARRAY['mickey ice cream bar', 'mickey bar', 'disney mickey bar', 'mickey premium ice cream bar'],
 'theme_park', 'Disney World', 1, '338 cal/100g. ~270 cal per bar (~80g). Vanilla ice cream, chocolate coating.', TRUE,
 65, 30, 13.0, 0.2, 150, 80, 0.5, 50, 0.5, 20, 15, 0.5, 80, 2.0, 0.02),

-- Mickey ice cream sandwich: ~320 cal per sandwich (~100g).
('disney_mickey_ice_cream_sandwich', 'Disney Mickey Ice Cream Sandwich', 260, 4.0, 38.0, 10.0,
 1.0, 22.0, 100, 100,
 'theme_park', ARRAY['mickey ice cream sandwich', 'disney ice cream sandwich', 'mickey sandwich'],
 'theme_park', 'Disney World', 1, '260 cal/100g. ~260 cal per sandwich. Vanilla ice cream between chocolate wafers.', TRUE,
 160, 20, 5.5, 0.1, 130, 60, 1.0, 30, 0.0, 10, 12, 0.4, 65, 2.0, 0.01),

-- Grey Stuff cupcake: rich frosted cupcake ~350 cal/100g, ~150g each.
('disney_grey_stuff_cupcake', 'Disney Grey Stuff Cupcake', 350, 3.5, 48.0, 16.0,
 0.5, 35.0, 150, 150,
 'theme_park', ARRAY['grey stuff', 'gray stuff', 'disney grey stuff cupcake', 'be our guest grey stuff'],
 'theme_park', 'Disney World', 1, '350 cal/100g. ~525 cal per cupcake (~150g). Cookies and cream mousse topped cupcake.', TRUE,
 250, 40, 9.0, 0.2, 90, 40, 1.0, 30, 0.0, 5, 10, 0.3, 60, 3.0, 0.01),

-- Cheeseburger spring rolls: deep-fried, ~280 cal/100g, ~200g order.
('disney_cheeseburger_spring_rolls', 'Disney Cheeseburger Spring Rolls', 280, 10.0, 25.0, 15.0,
 1.0, 2.0, 200, 65,
 'theme_park', ARRAY['cheeseburger spring rolls', 'disney spring rolls', 'adventureland spring rolls'],
 'theme_park', 'Disney World', 1, '280 cal/100g. ~560 cal per order (~200g, 3 rolls). Deep-fried with beef and cheese.', TRUE,
 580, 35, 6.0, 0.3, 150, 80, 1.5, 15, 1.0, 3, 15, 1.5, 100, 10.0, 0.02),

-- Corn dog nuggets: ~270 cal/100g.
('disney_corn_dog_nuggets', 'Disney Corn Dog Nuggets', 270, 8.0, 28.0, 14.0,
 1.0, 4.0, 170, NULL,
 'theme_park', ARRAY['disney corn dog nuggets', 'casey''s corn dog nuggets', 'corn dog bites disney'],
 'theme_park', 'Disney World', 1, '270 cal/100g. ~459 cal per order (~170g). Bite-sized corn dogs.', TRUE,
 680, 30, 4.5, 0.2, 120, 30, 1.5, 5, 0.0, 3, 10, 0.8, 80, 8.0, 0.02),

-- Ronto Wrap: ~180 cal/100g, pita with pork sausage and slaw, ~330g per wrap.
('disney_ronto_wrap', 'Disney Ronto Wrap (Galaxy''s Edge)', 180, 11.0, 14.0, 9.0,
 1.0, 2.5, 330, 330,
 'theme_park', ARRAY['ronto wrap', 'galaxy''s edge ronto wrap', 'star wars ronto wrap', 'ronto roasters wrap'],
 'theme_park', 'Disney World', 1, '180 cal/100g. ~594 cal per wrap (~330g). Pork sausage, roasted pork, peppercorn sauce, slaw in pita.', TRUE,
 520, 45, 3.5, 0.1, 200, 35, 1.5, 10, 3.0, 3, 18, 1.8, 120, 15.0, 0.02),

-- Blue Milk: plant-based frozen drink, ~75 cal/100g, ~450ml serving.
('disney_blue_milk', 'Disney Blue Milk (Galaxy''s Edge)', 75, 0.5, 14.0, 2.5,
 0.3, 12.0, 400, NULL,
 'theme_park', ARRAY['blue milk', 'galaxy''s edge blue milk', 'star wars blue milk'],
 'theme_park', 'Disney World', 1, '75 cal/100g. ~300 cal per serving (~400ml). Plant-based frozen drink with coconut/rice milk, dragonfruit.', TRUE,
 30, 0, 2.0, 0.0, 60, 15, 0.2, 2, 3.0, 0, 8, 0.1, 10, 0.5, 0.0),

-- Green Milk: plant-based frozen drink, ~80 cal/100g.
('disney_green_milk', 'Disney Green Milk (Galaxy''s Edge)', 80, 0.5, 15.0, 2.8,
 0.3, 13.0, 400, NULL,
 'theme_park', ARRAY['green milk', 'galaxy''s edge green milk', 'star wars green milk'],
 'theme_park', 'Disney World', 1, '80 cal/100g. ~320 cal per serving (~400ml). Plant-based frozen drink, citrusy/herbaceous.', TRUE,
 30, 0, 2.2, 0.0, 55, 15, 0.2, 2, 4.0, 0, 8, 0.1, 10, 0.5, 0.0),

-- EPCOT School Bread (Norway): sweet cardamom bun with custard, ~320 cal/100g.
('disney_epcot_school_bread', 'Disney EPCOT School Bread (Norway)', 320, 6.0, 45.0, 12.0,
 1.0, 22.0, 120, 120,
 'theme_park', ARRAY['epcot school bread', 'norway school bread', 'disney school bread', 'school bread epcot'],
 'theme_park', 'Disney World', 1, '320 cal/100g. ~384 cal per bun (~120g). Cardamom bun with custard and coconut.', TRUE,
 200, 30, 5.0, 0.1, 80, 30, 1.0, 20, 0.0, 5, 12, 0.4, 60, 5.0, 0.01),

-- Belgian Waffles (Belgium pavilion): ~310 cal/100g.
('disney_epcot_belgian_waffle', 'Disney EPCOT Belgian Waffle', 310, 6.0, 40.0, 14.0,
 0.8, 18.0, 200, 200,
 'theme_park', ARRAY['epcot belgian waffle', 'disney belgian waffle', 'belgium pavilion waffle'],
 'theme_park', 'Disney World', 1, '310 cal/100g. ~620 cal per waffle with toppings (~200g). Thick Belgian-style waffle.', TRUE,
 350, 55, 7.0, 0.2, 100, 50, 1.5, 40, 0.5, 10, 12, 0.5, 80, 8.0, 0.02),

-- Fish & chips (UK pavilion): battered cod and chips, ~210 cal/100g.
('disney_epcot_fish_chips', 'Disney EPCOT Fish & Chips (UK)', 210, 9.0, 22.0, 10.0,
 1.5, 0.5, 350, NULL,
 'theme_park', ARRAY['epcot fish and chips', 'disney fish and chips', 'uk pavilion fish chips', 'yorkshire county fish shop'],
 'theme_park', 'Disney World', 1, '210 cal/100g. ~735 cal per serving (~350g). Beer-battered cod with thick-cut chips.', TRUE,
 480, 30, 2.5, 0.1, 300, 20, 1.0, 5, 3.0, 10, 25, 0.5, 120, 18.0, 0.08),

-- Bratwurst with sauerkraut (Germany): ~220 cal/100g combined.
('disney_epcot_bratwurst', 'Disney EPCOT Bratwurst with Sauerkraut (Germany)', 220, 10.0, 8.0, 17.0,
 1.5, 1.5, 280, NULL,
 'theme_park', ARRAY['epcot bratwurst', 'disney bratwurst', 'germany pavilion bratwurst', 'epcot brat'],
 'theme_park', 'Disney World', 1, '220 cal/100g. ~616 cal per serving (~280g). Grilled bratwurst with sauerkraut on roll.', TRUE,
 750, 55, 6.5, 0.1, 220, 25, 1.5, 0, 8.0, 3, 16, 2.0, 130, 12.0, 0.02),

-- Creme brulee (France): ~280 cal/100g.
('disney_epcot_creme_brulee', 'Disney EPCOT Creme Brulee (France)', 280, 4.5, 28.0, 16.5,
 0.0, 24.0, 150, NULL,
 'theme_park', ARRAY['epcot creme brulee', 'disney creme brulee', 'france pavilion creme brulee'],
 'theme_park', 'Disney World', 1, '280 cal/100g. ~420 cal per serving (~150g). Classic French custard with caramelized sugar.', TRUE,
 60, 180, 9.5, 0.1, 120, 90, 0.5, 120, 0.0, 30, 10, 0.6, 110, 5.0, 0.01),

-- Croissant doughnut: ~380 cal/100g.
('disney_croissant_doughnut', 'Disney Croissant Doughnut', 380, 5.0, 42.0, 22.0,
 0.8, 20.0, 110, 110,
 'theme_park', ARRAY['disney croissant doughnut', 'cronut disney', 'disney cronut'],
 'theme_park', 'Disney World', 1, '380 cal/100g. ~418 cal per piece (~110g). Flaky croissant-doughnut hybrid.', TRUE,
 280, 40, 12.0, 0.5, 55, 20, 1.2, 30, 0.0, 5, 8, 0.3, 45, 6.0, 0.01),

-- Flame Tree BBQ ribs: ~240 cal/100g.
('disney_flame_tree_ribs', 'Disney Flame Tree BBQ Ribs', 240, 17.0, 8.0, 16.0,
 0.3, 6.0, 340, NULL,
 'theme_park', ARRAY['flame tree bbq ribs', 'disney bbq ribs', 'animal kingdom ribs'],
 'theme_park', 'Disney World', 1, '240 cal/100g. ~816 cal per serving (~340g). Slow-smoked St. Louis ribs with BBQ sauce.', TRUE,
 620, 80, 6.0, 0.1, 280, 30, 1.5, 10, 2.0, 5, 20, 3.5, 180, 18.0, 0.03),

-- Flame Tree BBQ chicken: ~195 cal/100g.
('disney_flame_tree_chicken', 'Disney Flame Tree BBQ Chicken', 195, 22.0, 6.0, 9.0,
 0.2, 4.5, 300, NULL,
 'theme_park', ARRAY['flame tree bbq chicken', 'disney bbq chicken', 'animal kingdom chicken'],
 'theme_park', 'Disney World', 1, '195 cal/100g. ~585 cal per serving (~300g). BBQ-glazed half chicken.', TRUE,
 550, 85, 2.8, 0.0, 250, 18, 1.2, 15, 1.0, 5, 25, 1.5, 190, 22.0, 0.03),

-- Satu'li Canteen chicken bowl: ~150 cal/100g.
('disney_satuli_chicken_bowl', 'Disney Satu''li Canteen Chicken Bowl', 150, 12.0, 16.0, 4.5,
 2.0, 2.0, 380, NULL,
 'theme_park', ARRAY['satu''li chicken bowl', 'satuli canteen chicken', 'pandora chicken bowl'],
 'theme_park', 'Disney World', 1, '150 cal/100g. ~570 cal per bowl (~380g). Grilled chicken with grains, vegetables, sauce.', TRUE,
 420, 50, 1.2, 0.0, 300, 35, 1.5, 40, 5.0, 3, 30, 1.2, 150, 15.0, 0.03),

-- Satu'li beef bowl: ~165 cal/100g.
('disney_satuli_beef_bowl', 'Disney Satu''li Canteen Beef Bowl', 165, 11.0, 16.0, 6.5,
 2.0, 2.0, 380, NULL,
 'theme_park', ARRAY['satu''li beef bowl', 'satuli canteen beef', 'pandora beef bowl'],
 'theme_park', 'Disney World', 1, '165 cal/100g. ~627 cal per bowl (~380g). Slow-roasted beef with grains, vegetables, sauce.', TRUE,
 440, 40, 2.5, 0.1, 310, 30, 2.0, 35, 4.0, 3, 28, 2.5, 160, 14.0, 0.02),

-- Satu'li fish bowl: ~145 cal/100g.
('disney_satuli_fish_bowl', 'Disney Satu''li Canteen Fish Bowl', 145, 10.0, 16.0, 4.5,
 2.0, 2.0, 380, NULL,
 'theme_park', ARRAY['satu''li fish bowl', 'satuli canteen fish', 'pandora fish bowl'],
 'theme_park', 'Disney World', 1, '145 cal/100g. ~551 cal per bowl (~380g). Grilled fish with grains, vegetables, sauce.', TRUE,
 380, 35, 1.0, 0.0, 320, 30, 1.0, 30, 5.0, 15, 32, 0.8, 170, 20.0, 0.15),

-- Citrus Swirl Dole Whip Float: soft serve + OJ, ~70 cal/100g.
('disney_citrus_swirl_float', 'Disney Citrus Swirl Dole Whip Float', 70, 0.3, 16.0, 0.4,
 0.2, 14.0, 400, NULL,
 'theme_park', ARRAY['citrus swirl', 'dole whip float', 'citrus swirl float', 'orange dole whip float'],
 'theme_park', 'Disney World', 1, '70 cal/100g. ~280 cal per float (~400ml). Dole Whip swirled with orange juice.', TRUE,
 25, 0, 0.2, 0.0, 80, 10, 0.1, 5, 20.0, 0, 5, 0.1, 8, 0.3, 0.0),

-- Popcorn bucket: movie-style popcorn, ~500 cal/100g.
('disney_popcorn_bucket', 'Disney Popcorn Bucket', 500, 7.0, 52.0, 30.0,
 8.0, 0.5, 80, NULL,
 'theme_park', ARRAY['disney popcorn', 'disney popcorn bucket', 'magic kingdom popcorn'],
 'theme_park', 'Disney World', 1, '500 cal/100g. ~400 cal per serving (~80g). Buttered popcorn in collectible bucket.', TRUE,
 700, 0, 8.0, 0.5, 200, 5, 1.5, 15, 0.0, 0, 30, 1.0, 100, 5.0, 0.01),

-- Casey's Corner hot dog: ~250 cal/100g.
('disney_caseys_hot_dog', 'Disney Casey''s Corner Hot Dog', 250, 9.0, 22.0, 14.0,
 0.8, 3.0, 200, 200,
 'theme_park', ARRAY['casey''s corner hot dog', 'disney hot dog', 'magic kingdom hot dog'],
 'theme_park', 'Disney World', 1, '250 cal/100g. ~500 cal per hot dog (~200g). All-beef frank on toasted bun.', TRUE,
 780, 35, 5.5, 0.2, 150, 40, 2.0, 0, 0.5, 3, 12, 1.5, 100, 10.0, 0.02),

-- Plaza ice cream sundae: ~250 cal/100g.
('disney_plaza_sundae', 'Disney Plaza Ice Cream Sundae', 250, 3.5, 32.0, 12.5,
 0.5, 26.0, 250, NULL,
 'theme_park', ARRAY['plaza ice cream sundae', 'disney sundae', 'plaza restaurant sundae'],
 'theme_park', 'Disney World', 1, '250 cal/100g. ~625 cal per sundae (~250g). Ice cream with toppings and whipped cream.', TRUE,
 100, 45, 7.5, 0.2, 180, 100, 0.5, 60, 1.0, 15, 15, 0.5, 90, 2.5, 0.02),

-- Sleepy Hollow funnel cake: ~307 cal/100g.
('disney_sleepy_hollow_funnel_cake', 'Disney Sleepy Hollow Funnel Cake', 307, 5.0, 38.0, 15.0,
 0.8, 15.0, 250, 250,
 'theme_park', ARRAY['sleepy hollow funnel cake', 'disney funnel cake', 'magic kingdom funnel cake'],
 'theme_park', 'Disney World', 1, '307 cal/100g. ~768 cal per cake (~250g). Fried batter with powdered sugar and toppings.', TRUE,
 300, 50, 4.0, 0.3, 100, 40, 1.5, 15, 0.5, 8, 12, 0.5, 70, 10.0, 0.01),

-- Tonga Toast: banana-stuffed French toast, ~290 cal/100g.
('disney_tonga_toast', 'Disney Tonga Toast', 290, 5.5, 35.0, 14.5,
 1.5, 18.0, 250, 250,
 'theme_park', ARRAY['tonga toast', 'disney tonga toast', 'polynesian tonga toast'],
 'theme_park', 'Disney World', 1, '290 cal/100g. ~725 cal per order (~250g). Banana-stuffed sourdough French toast with cinnamon sugar.', TRUE,
 320, 60, 5.0, 0.2, 180, 40, 1.5, 30, 2.0, 8, 18, 0.5, 70, 8.0, 0.02),

-- Ohana bread pudding: ~300 cal/100g.
('disney_ohana_bread_pudding', 'Disney ''Ohana Bread Pudding', 300, 5.0, 42.0, 12.5,
 0.5, 28.0, 200, NULL,
 'theme_park', ARRAY['ohana bread pudding', 'disney bread pudding', 'polynesian bread pudding'],
 'theme_park', 'Disney World', 1, '300 cal/100g. ~600 cal per serving (~200g). Warm bread pudding with vanilla sauce and bananas.', TRUE,
 250, 55, 6.0, 0.1, 150, 60, 1.2, 40, 1.0, 12, 12, 0.4, 80, 6.0, 0.01),

-- Pineapple upside-down cake: ~310 cal/100g.
('disney_pineapple_cake', 'Disney Pineapple Upside-Down Cake', 310, 3.0, 45.0, 13.0,
 0.5, 30.0, 150, 150,
 'theme_park', ARRAY['disney pineapple cake', 'disney pineapple upside down cake'],
 'theme_park', 'Disney World', 1, '310 cal/100g. ~465 cal per slice (~150g). Classic pineapple upside-down cake.', TRUE,
 220, 45, 5.5, 0.1, 80, 30, 1.0, 25, 5.0, 8, 8, 0.3, 55, 4.0, 0.01),

-- Loaded tots: ~250 cal/100g.
('disney_loaded_tots', 'Disney Loaded Tots', 250, 8.0, 22.0, 15.0,
 1.5, 1.0, 300, NULL,
 'theme_park', ARRAY['disney loaded tots', 'disney tater tots', 'loaded tater tots disney'],
 'theme_park', 'Disney World', 1, '250 cal/100g. ~750 cal per order (~300g). Tater tots with cheese, bacon, sour cream.', TRUE,
 680, 30, 6.5, 0.2, 350, 80, 1.0, 25, 3.0, 3, 20, 1.0, 120, 5.0, 0.02),

-- Mac & Cheese hot dog: ~260 cal/100g.
('disney_mac_cheese_hot_dog', 'Disney Mac & Cheese Hot Dog', 260, 10.0, 24.0, 14.0,
 0.8, 3.0, 250, 250,
 'theme_park', ARRAY['disney mac and cheese hot dog', 'mac cheese hot dog disney', 'casey''s mac cheese dog'],
 'theme_park', 'Disney World', 1, '260 cal/100g. ~650 cal per dog (~250g). All-beef frank topped with mac and cheese.', TRUE,
 820, 40, 6.5, 0.2, 140, 100, 1.8, 20, 0.0, 5, 14, 1.5, 130, 10.0, 0.02),

-- Pulled pork sandwich: ~210 cal/100g.
('disney_pulled_pork_sandwich', 'Disney Pulled Pork Sandwich', 210, 14.0, 18.0, 9.0,
 0.8, 8.0, 300, 300,
 'theme_park', ARRAY['disney pulled pork', 'disney bbq pulled pork sandwich', 'flame tree pulled pork'],
 'theme_park', 'Disney World', 1, '210 cal/100g. ~630 cal per sandwich (~300g). Slow-smoked pulled pork with BBQ sauce on bun.', TRUE,
 580, 55, 3.0, 0.1, 280, 30, 1.8, 8, 1.0, 5, 20, 2.5, 150, 18.0, 0.02),

-- LeFou's Brew: frozen apple drink, ~55 cal/100g.
('disney_lefous_brew', 'Disney LeFou''s Brew', 55, 0.0, 14.0, 0.0,
 0.0, 13.0, 450, NULL,
 'theme_park', ARRAY['lefou''s brew', 'disney lefou''s brew', 'gaston''s tavern lefou''s brew'],
 'theme_park', 'Disney World', 1, '55 cal/100g. ~248 cal per cup (~450ml). Frozen apple juice with toasted marshmallow foam.', TRUE,
 10, 0, 0.0, 0.0, 50, 5, 0.1, 0, 2.0, 0, 3, 0.0, 5, 0.2, 0.0),

-- Candy apple: ~200 cal/100g.
('disney_candy_apple', 'Disney Candy Apple', 200, 0.3, 45.0, 3.0,
 1.5, 40.0, 300, 300,
 'theme_park', ARRAY['disney candy apple', 'disney caramel apple', 'magic kingdom candy apple'],
 'theme_park', 'Disney World', 1, '200 cal/100g. ~600 cal per apple (~300g). Apple coated in caramel/candy shell with toppings.', TRUE,
 50, 5, 1.5, 0.0, 100, 15, 0.3, 3, 4.0, 0, 5, 0.1, 10, 0.5, 0.01),

-- Rice Krispie treat: ~400 cal/100g.
('disney_rice_krispie_treat', 'Disney Rice Krispie Treat', 400, 2.5, 72.0, 10.0,
 0.2, 40.0, 120, 120,
 'theme_park', ARRAY['disney rice krispie treat', 'disney rice crispy treat', 'mickey rice krispie'],
 'theme_park', 'Disney World', 1, '400 cal/100g. ~480 cal per treat (~120g). Oversized, decorated Rice Krispie treat.', TRUE,
 280, 0, 3.0, 0.0, 30, 5, 4.0, 150, 5.0, 0, 8, 0.5, 25, 2.0, 0.0),

-- Cookies & cream shake: ~190 cal/100g.
('disney_cookies_cream_shake', 'Disney Cookies & Cream Milkshake', 190, 4.0, 28.0, 7.5,
 0.3, 24.0, 450, NULL,
 'theme_park', ARRAY['disney cookies and cream shake', 'disney milkshake', 'disney cookies cream shake'],
 'theme_park', 'Disney World', 1, '190 cal/100g. ~855 cal per shake (~450ml). Thick milkshake with Oreo cookies.', TRUE,
 160, 30, 4.5, 0.1, 250, 120, 0.5, 40, 0.5, 20, 18, 0.5, 100, 3.0, 0.02),

-- Waffle sandwich: ~320 cal/100g.
('disney_waffle_sandwich', 'Disney Waffle Sandwich', 320, 8.0, 35.0, 16.0,
 0.5, 12.0, 250, 250,
 'theme_park', ARRAY['disney waffle sandwich', 'sleepy hollow waffle sandwich'],
 'theme_park', 'Disney World', 1, '320 cal/100g. ~800 cal per sandwich (~250g). Waffle with savory fillings.', TRUE,
 550, 50, 6.0, 0.2, 160, 45, 1.5, 25, 1.0, 8, 14, 1.0, 100, 10.0, 0.02),


-- ==========================================
-- UNIVERSAL ORLANDO (~40 items)
-- ==========================================

-- Butterbeer frozen: ~50 cal/100ml (200 cal per 400ml serving).
('universal_butterbeer_frozen', 'Universal Frozen Butterbeer', 50, 0.0, 10.5, 0.9,
 0.0, 9.5, 400, NULL,
 'theme_park', ARRAY['frozen butterbeer', 'butterbeer frozen', 'harry potter frozen butterbeer'],
 'theme_park', 'Universal Orlando', 1, '50 cal/100g. ~200 cal per serving (400ml). Frozen butterscotch-cream soda, non-dairy.', TRUE,
 25, 0, 0.5, 0.0, 15, 5, 0.0, 0, 0.0, 0, 2, 0.0, 5, 0.2, 0.0),

-- Butterbeer cold: ~55 cal/100ml.
('universal_butterbeer_cold', 'Universal Cold Butterbeer', 55, 0.0, 12.0, 0.8,
 0.0, 11.0, 400, NULL,
 'theme_park', ARRAY['cold butterbeer', 'butterbeer cold', 'butterbeer regular'],
 'theme_park', 'Universal Orlando', 1, '55 cal/100g. ~220 cal per serving (400ml). Chilled butterscotch-cream soda.', TRUE,
 30, 0, 0.5, 0.0, 10, 5, 0.0, 0, 0.0, 0, 2, 0.0, 5, 0.2, 0.0),

-- Butterbeer hot: ~60 cal/100ml.
('universal_butterbeer_hot', 'Universal Hot Butterbeer', 60, 0.5, 12.5, 1.0,
 0.0, 11.5, 350, NULL,
 'theme_park', ARRAY['hot butterbeer', 'butterbeer hot', 'warm butterbeer'],
 'theme_park', 'Universal Orlando', 1, '60 cal/100g. ~210 cal per serving (350ml). Warm butterscotch drink with foam.', TRUE,
 35, 2, 0.6, 0.0, 20, 10, 0.0, 2, 0.0, 0, 3, 0.0, 8, 0.3, 0.0),

-- Butterbeer ice cream: ~220 cal/100g.
('universal_butterbeer_ice_cream', 'Universal Butterbeer Ice Cream', 220, 3.5, 30.0, 10.0,
 0.0, 26.0, 120, NULL,
 'theme_park', ARRAY['butterbeer ice cream', 'harry potter ice cream butterscotch'],
 'theme_park', 'Universal Orlando', 1, '220 cal/100g. ~264 cal per serving (~120g). Butterscotch-flavored ice cream.', TRUE,
 80, 35, 6.0, 0.1, 140, 80, 0.3, 40, 0.0, 15, 12, 0.4, 70, 2.0, 0.02),

-- Butterbeer fudge: ~430 cal/100g.
('universal_butterbeer_fudge', 'Universal Butterbeer Fudge', 430, 2.5, 62.0, 19.0,
 0.0, 55.0, 50, 50,
 'theme_park', ARRAY['butterbeer fudge', 'harry potter fudge'],
 'theme_park', 'Universal Orlando', 1, '430 cal/100g. ~215 cal per piece (~50g). Rich butterscotch fudge.', TRUE,
 100, 25, 12.0, 0.2, 70, 40, 0.2, 25, 0.0, 5, 5, 0.2, 35, 1.0, 0.01),

-- Pumpkin juice: ~50 cal/100ml.
('universal_pumpkin_juice', 'Universal Pumpkin Juice', 50, 0.0, 12.0, 0.0,
 0.2, 11.0, 400, NULL,
 'theme_park', ARRAY['pumpkin juice', 'harry potter pumpkin juice', 'wizarding world pumpkin juice'],
 'theme_park', 'Universal Orlando', 1, '50 cal/100g. ~200 cal per bottle (400ml). Apple cider, pumpkin puree, spices.', TRUE,
 10, 0, 0.0, 0.0, 80, 8, 0.3, 100, 2.0, 0, 5, 0.1, 8, 0.3, 0.0),

-- Krusty Burger: ~240 cal/100g.
('universal_krusty_burger', 'Universal Krusty Burger', 240, 13.0, 20.0, 12.0,
 1.0, 4.0, 300, 300,
 'theme_park', ARRAY['krusty burger', 'simpsons krusty burger', 'universal krusty burger'],
 'theme_park', 'Universal Orlando', 1, '240 cal/100g. ~720 cal per burger (~300g). Classic theme park cheeseburger.', TRUE,
 650, 55, 5.0, 0.3, 200, 80, 2.5, 15, 1.0, 5, 20, 2.8, 150, 15.0, 0.03),

-- Lard Lad Big Pink donut: ~400 cal/100g, ~400g each.
('universal_lard_lad_big_pink', 'Universal Lard Lad Big Pink Donut', 400, 5.0, 50.0, 20.0,
 1.0, 30.0, 400, 400,
 'theme_park', ARRAY['lard lad donut', 'big pink donut', 'simpsons donut', 'lard lad big pink'],
 'theme_park', 'Universal Orlando', 1, '400 cal/100g. ~1600 cal per donut (~400g). Giant pink-frosted donut with sprinkles.', TRUE,
 350, 25, 8.0, 0.5, 65, 30, 2.0, 10, 0.0, 3, 10, 0.4, 60, 6.0, 0.01),

-- Lard Lad other donuts: ~380 cal/100g, ~100g each.
('universal_lard_lad_other', 'Universal Lard Lad Donuts (Other)', 380, 5.0, 48.0, 19.0,
 0.8, 26.0, 100, 100,
 'theme_park', ARRAY['lard lad donuts', 'simpsons donuts', 'lard lad assorted'],
 'theme_park', 'Universal Orlando', 1, '380 cal/100g. ~380 cal per donut (~100g). Assorted glazed and topped donuts.', TRUE,
 320, 20, 7.0, 0.3, 55, 25, 1.5, 8, 0.0, 2, 8, 0.3, 50, 5.0, 0.01),

-- Brunch Burger: ~260 cal/100g.
('universal_brunch_burger', 'Universal Brunch Burger', 260, 14.0, 18.0, 15.0,
 0.8, 3.0, 350, 350,
 'theme_park', ARRAY['universal brunch burger', 'brunch burger universal'],
 'theme_park', 'Universal Orlando', 1, '260 cal/100g. ~910 cal per burger (~350g). Burger with fried egg and hash brown.', TRUE,
 720, 70, 6.0, 0.3, 220, 70, 2.5, 40, 1.0, 10, 22, 3.0, 160, 16.0, 0.03),

-- Leaky Cauldron fish & chips: ~210 cal/100g.
('universal_leaky_cauldron_fish_chips', 'Universal Leaky Cauldron Fish & Chips', 210, 9.0, 22.0, 10.0,
 1.5, 0.5, 350, NULL,
 'theme_park', ARRAY['leaky cauldron fish and chips', 'harry potter fish chips', 'universal fish and chips'],
 'theme_park', 'Universal Orlando', 1, '210 cal/100g. ~735 cal per serving (~350g). Beer-battered fish with chips.', TRUE,
 480, 30, 2.5, 0.1, 300, 20, 1.0, 5, 3.0, 10, 25, 0.5, 120, 18.0, 0.08),

-- Leaky Cauldron bangers and mash: ~155 cal/100g.
('universal_leaky_cauldron_bangers_mash', 'Universal Leaky Cauldron Bangers and Mash', 155, 7.0, 12.0, 9.0,
 1.0, 1.0, 400, NULL,
 'theme_park', ARRAY['leaky cauldron bangers and mash', 'harry potter bangers mash', 'universal bangers and mash'],
 'theme_park', 'Universal Orlando', 1, '155 cal/100g. ~620 cal per plate (~400g). Sausages with mashed potatoes and onion gravy.', TRUE,
 620, 40, 3.5, 0.1, 280, 25, 1.2, 5, 3.0, 3, 18, 1.5, 120, 10.0, 0.02),

-- Shepherd's pie: ~140 cal/100g.
('universal_shepherds_pie', 'Universal Leaky Cauldron Shepherd''s Pie', 140, 7.0, 10.0, 8.0,
 1.5, 1.0, 400, NULL,
 'theme_park', ARRAY['leaky cauldron shepherd''s pie', 'harry potter shepherd''s pie', 'universal shepherd''s pie'],
 'theme_park', 'Universal Orlando', 1, '140 cal/100g. ~560 cal per serving (~400g). Ground beef and vegetables topped with mashed potato.', TRUE,
 450, 30, 3.5, 0.1, 300, 30, 1.5, 80, 5.0, 3, 18, 2.0, 110, 8.0, 0.02),

-- Toothsome chocolate milkshake: ~200 cal/100g.
('universal_toothsome_choc_shake', 'Universal Toothsome Chocolate Milkshake', 200, 4.0, 28.0, 9.0,
 0.5, 24.0, 500, NULL,
 'theme_park', ARRAY['toothsome chocolate shake', 'toothsome milkshake', 'universal chocolate milkshake'],
 'theme_park', 'Universal Orlando', 1, '200 cal/100g. ~1000 cal per shake (~500ml). Rich chocolate milkshake with toppings.', TRUE,
 140, 35, 5.5, 0.1, 280, 130, 1.0, 50, 0.5, 20, 25, 0.7, 120, 3.5, 0.02),

-- Toothsome loaded milkshake: ~220 cal/100g.
('universal_toothsome_loaded_shake', 'Universal Toothsome Loaded Milkshake', 220, 4.0, 30.0, 10.0,
 0.5, 26.0, 550, NULL,
 'theme_park', ARRAY['toothsome loaded milkshake', 'toothsome freakshake'],
 'theme_park', 'Universal Orlando', 1, '220 cal/100g. ~1210 cal per shake (~550ml). Milkshake topped with cake, candy, cookies.', TRUE,
 160, 35, 6.0, 0.2, 260, 120, 1.0, 45, 0.5, 18, 22, 0.6, 110, 3.0, 0.02),

-- Mythos lamb burger: ~235 cal/100g.
('universal_mythos_lamb_burger', 'Universal Mythos Lamb Burger', 235, 14.0, 18.0, 12.0,
 1.2, 3.0, 320, 320,
 'theme_park', ARRAY['mythos lamb burger', 'universal mythos burger', 'islands of adventure lamb burger'],
 'theme_park', 'Universal Orlando', 1, '235 cal/100g. ~752 cal per burger (~320g). Lamb patty with feta and tzatziki.', TRUE,
 520, 55, 5.0, 0.2, 250, 70, 2.5, 20, 2.0, 3, 22, 3.5, 170, 12.0, 0.05),

-- Voodoo Doughnut original: ~380 cal/100g.
('universal_voodoo_doughnut', 'Universal Voodoo Doughnut (Original)', 380, 4.5, 50.0, 18.0,
 0.8, 28.0, 100, 100,
 'theme_park', ARRAY['voodoo doughnut', 'voodoo donut universal', 'voodoo doughnut original'],
 'theme_park', 'Universal Orlando', 1, '380 cal/100g. ~380 cal per doughnut (~100g). Raised yeast doughnut with glaze.', TRUE,
 300, 15, 7.0, 0.3, 50, 20, 1.5, 5, 0.0, 2, 8, 0.3, 45, 5.0, 0.01),

-- Voodoo Doughnut maple bacon: ~390 cal/100g.
('universal_voodoo_maple_bacon', 'Universal Voodoo Doughnut Maple Bacon', 390, 6.0, 48.0, 19.5,
 0.5, 26.0, 120, 120,
 'theme_park', ARRAY['voodoo maple bacon', 'maple bacon doughnut universal', 'voodoo bacon maple bar'],
 'theme_park', 'Universal Orlando', 1, '390 cal/100g. ~468 cal per bar (~120g). Maple-glazed bar topped with bacon strips.', TRUE,
 420, 20, 7.5, 0.3, 60, 20, 1.5, 5, 0.0, 3, 8, 0.4, 50, 6.0, 0.02),

-- Chicken & waffle sandwich: ~280 cal/100g.
('universal_chicken_waffle_sandwich', 'Universal Chicken & Waffle Sandwich', 280, 12.0, 28.0, 13.5,
 0.8, 6.0, 300, 300,
 'theme_park', ARRAY['universal chicken waffle sandwich', 'chicken and waffle sandwich universal'],
 'theme_park', 'Universal Orlando', 1, '280 cal/100g. ~840 cal per sandwich (~300g). Fried chicken between waffles with maple syrup.', TRUE,
 650, 50, 4.0, 0.2, 180, 35, 1.8, 15, 0.5, 5, 18, 1.0, 130, 12.0, 0.02),

-- Universal turkey leg: ~161 cal/100g.
('universal_turkey_leg', 'Universal Orlando Turkey Leg', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['universal turkey leg', 'universal studios turkey leg'],
 'theme_park', 'Universal Orlando', 1, '161 cal/100g. ~1095 cal per leg (~680g). Smoked turkey drumstick.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Universal corn dog: ~270 cal/100g.
('universal_corn_dog', 'Universal Orlando Corn Dog', 270, 8.0, 28.0, 14.0,
 1.0, 4.0, 175, 175,
 'theme_park', ARRAY['universal corn dog', 'universal studios corn dog'],
 'theme_park', 'Universal Orlando', 1, '270 cal/100g. ~473 cal per corn dog (~175g). Battered and deep-fried hot dog on a stick.', TRUE,
 680, 30, 4.5, 0.2, 120, 30, 1.5, 5, 0.0, 3, 10, 0.8, 80, 8.0, 0.02),

-- Duff beer (Moe's Tavern): ~43 cal/100ml (standard lager).
('universal_duff_beer', 'Universal Duff Beer (Moe''s Tavern)', 43, 0.3, 3.5, 0.0,
 0.0, 0.0, 475, NULL,
 'theme_park', ARRAY['duff beer', 'moe''s tavern beer', 'universal duff beer', 'simpsons duff beer'],
 'theme_park', 'Universal Orlando', 1, '43 cal/100ml. ~204 cal per pint (475ml). American-style lager.', TRUE,
 5, 0, 0.0, 0.0, 25, 5, 0.0, 0, 0.0, 0, 8, 0.0, 15, 0.5, 0.0),

-- Flaming Moe: ~60 cal/100ml.
('universal_flaming_moe', 'Universal Flaming Moe', 60, 0.0, 15.0, 0.0,
 0.0, 14.0, 400, NULL,
 'theme_park', ARRAY['flaming moe', 'moe''s flaming moe', 'simpsons flaming moe'],
 'theme_park', 'Universal Orlando', 1, '60 cal/100ml. ~240 cal per serving (400ml). Orange-flavored soda with dry-ice fog effect.', TRUE,
 15, 0, 0.0, 0.0, 10, 2, 0.0, 0, 5.0, 0, 2, 0.0, 3, 0.1, 0.0),

-- Three Broomsticks chicken platter: ~190 cal/100g.
('universal_three_broomsticks_chicken', 'Universal Three Broomsticks Chicken Platter', 190, 18.0, 10.0, 9.0,
 1.5, 1.0, 400, NULL,
 'theme_park', ARRAY['three broomsticks chicken', 'harry potter chicken dinner', 'three broomsticks platter'],
 'theme_park', 'Universal Orlando', 1, '190 cal/100g. ~760 cal per platter (~400g). Rotisserie chicken with corn and roasted potatoes.', TRUE,
 480, 75, 2.5, 0.0, 350, 25, 1.2, 20, 5.0, 5, 28, 1.5, 200, 22.0, 0.04),

-- Pumpkin pasty: ~350 cal/100g.
('universal_pumpkin_pasty', 'Universal Pumpkin Pasty', 350, 4.0, 45.0, 17.0,
 1.0, 22.0, 100, 100,
 'theme_park', ARRAY['pumpkin pasty', 'harry potter pumpkin pasty', 'honeydukes pumpkin pasty'],
 'theme_park', 'Universal Orlando', 1, '350 cal/100g. ~350 cal per pasty (~100g). Pumpkin-filled flaky pastry.', TRUE,
 250, 15, 8.0, 0.2, 80, 20, 1.0, 180, 1.0, 3, 10, 0.3, 40, 4.0, 0.01),

-- Cauldron cakes: ~370 cal/100g.
('universal_cauldron_cakes', 'Universal Cauldron Cakes', 370, 4.0, 50.0, 17.0,
 0.8, 32.0, 90, 90,
 'theme_park', ARRAY['cauldron cakes', 'harry potter cauldron cakes', 'honeydukes cauldron cake'],
 'theme_park', 'Universal Orlando', 1, '370 cal/100g. ~333 cal per cake (~90g). Chocolate cake with chocolate truffle center.', TRUE,
 200, 30, 9.0, 0.2, 120, 30, 1.5, 15, 0.0, 5, 20, 0.6, 65, 4.0, 0.01),

-- Florean Fortescue's ice cream: ~210 cal/100g.
('universal_florean_ice_cream', 'Universal Florean Fortescue''s Ice Cream', 210, 3.5, 28.0, 10.0,
 0.3, 24.0, 150, NULL,
 'theme_park', ARRAY['florean fortescue''s ice cream', 'harry potter ice cream', 'diagon alley ice cream'],
 'theme_park', 'Universal Orlando', 1, '210 cal/100g. ~315 cal per serving (~150g). Unique flavors: Earl Grey lavender, clotted cream, etc.', TRUE,
 70, 35, 6.0, 0.1, 160, 90, 0.3, 50, 0.5, 18, 14, 0.5, 85, 2.5, 0.02),

-- Confisco Grille fajitas: ~140 cal/100g.
('universal_confisco_fajitas', 'Universal Confisco Grille Fajitas', 140, 10.0, 10.0, 7.0,
 2.0, 2.5, 400, NULL,
 'theme_park', ARRAY['confisco grille fajitas', 'universal fajitas', 'islands of adventure fajitas'],
 'theme_park', 'Universal Orlando', 1, '140 cal/100g. ~560 cal per plate (~400g). Sizzling fajitas with peppers and onions.', TRUE,
 480, 40, 2.5, 0.1, 320, 40, 1.5, 35, 15.0, 3, 25, 2.0, 160, 12.0, 0.03),

-- Loaded cheese fries: ~280 cal/100g.
('universal_loaded_cheese_fries', 'Universal Loaded Cheese Fries', 280, 7.0, 28.0, 16.0,
 2.0, 1.0, 350, NULL,
 'theme_park', ARRAY['universal loaded fries', 'universal loaded cheese fries', 'theme park loaded fries'],
 'theme_park', 'Universal Orlando', 1, '280 cal/100g. ~980 cal per order (~350g). French fries with cheese sauce and toppings.', TRUE,
 750, 25, 7.0, 0.3, 400, 90, 1.0, 20, 5.0, 3, 22, 1.0, 130, 4.0, 0.02),


-- ==========================================
-- DOLLYWOOD (~20 items)
-- ==========================================

-- Cinnamon bread loaf: ~280 cal/100g, ~680g per loaf.
('dollywood_cinnamon_bread_loaf', 'Dollywood Cinnamon Bread (Loaf)', 280, 4.5, 42.0, 10.5,
 1.0, 18.0, 680, 680,
 'theme_park', ARRAY['dollywood cinnamon bread', 'dollywood cinnamon bread loaf', 'grist mill cinnamon bread'],
 'theme_park', 'Dollywood', 1, '280 cal/100g. ~1904 cal per loaf (~680g). Famous iced cinnamon bread from the Grist Mill.', TRUE,
 240, 30, 4.5, 0.2, 70, 25, 1.5, 20, 0.0, 5, 10, 0.4, 55, 6.0, 0.01),

-- Cinnamon bread slice: same per 100g, ~85g per slice.
('dollywood_cinnamon_bread_slice', 'Dollywood Cinnamon Bread (Slice)', 280, 4.5, 42.0, 10.5,
 1.0, 18.0, 85, 85,
 'theme_park', ARRAY['dollywood cinnamon bread slice', 'grist mill cinnamon bread slice'],
 'theme_park', 'Dollywood', 1, '280 cal/100g. ~238 cal per slice (~85g). Single slice of famous iced cinnamon bread.', TRUE,
 240, 30, 4.5, 0.2, 70, 25, 1.5, 20, 0.0, 5, 10, 0.4, 55, 6.0, 0.01),

-- Fried catfish: USDA ~229 cal/100g.
('dollywood_fried_catfish', 'Dollywood Fried Catfish', 229, 18.0, 8.0, 13.5,
 0.5, 0.5, 250, NULL,
 'theme_park', ARRAY['dollywood fried catfish', 'dollywood catfish', 'dollywood breaded catfish'],
 'theme_park', 'Dollywood', 1, '229 cal/100g. ~573 cal per serving (~250g). Southern-style breaded and fried catfish.', TRUE,
 420, 60, 3.0, 0.1, 340, 30, 1.0, 8, 0.5, 25, 28, 0.8, 220, 15.0, 0.10),

-- Pulled pork sandwich: ~210 cal/100g.
('dollywood_pulled_pork', 'Dollywood Pulled Pork Sandwich', 210, 14.0, 18.0, 9.0,
 0.8, 8.0, 300, 300,
 'theme_park', ARRAY['dollywood pulled pork', 'dollywood bbq pulled pork'],
 'theme_park', 'Dollywood', 1, '210 cal/100g. ~630 cal per sandwich (~300g). Slow-smoked pulled pork on a bun.', TRUE,
 580, 55, 3.0, 0.1, 280, 30, 1.8, 8, 1.0, 5, 20, 2.5, 150, 18.0, 0.02),

-- Turkey leg: ~161 cal/100g.
('dollywood_turkey_leg', 'Dollywood Turkey Leg', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['dollywood turkey leg', 'dollywood smoked turkey leg'],
 'theme_park', 'Dollywood', 1, '161 cal/100g. ~1095 cal per leg (~680g). Smoked turkey drumstick.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Fried chicken quarter: ~250 cal/100g.
('dollywood_fried_chicken', 'Dollywood Fried Chicken (Quarter)', 250, 20.0, 8.0, 15.0,
 0.3, 0.0, 280, NULL,
 'theme_park', ARRAY['dollywood fried chicken', 'dollywood chicken quarter'],
 'theme_park', 'Dollywood', 1, '250 cal/100g. ~700 cal per quarter (~280g). Southern-style fried chicken.', TRUE,
 550, 90, 4.0, 0.1, 230, 15, 1.3, 12, 0.0, 5, 24, 1.8, 185, 22.0, 0.04),

-- Fried chicken tenders: ~260 cal/100g.
('dollywood_chicken_tenders', 'Dollywood Fried Chicken Tenders', 260, 18.0, 14.0, 14.5,
 0.5, 0.5, 200, NULL,
 'theme_park', ARRAY['dollywood chicken tenders', 'dollywood chicken strips'],
 'theme_park', 'Dollywood', 1, '260 cal/100g. ~520 cal per order (~200g). Breaded and fried chicken tenders.', TRUE,
 600, 60, 3.5, 0.1, 210, 18, 1.2, 5, 0.0, 3, 22, 1.0, 170, 18.0, 0.02),

-- Pot roast: ~175 cal/100g.
('dollywood_pot_roast', 'Dollywood Pot Roast', 175, 18.0, 6.0, 8.5,
 1.0, 2.0, 300, NULL,
 'theme_park', ARRAY['dollywood pot roast', 'dollywood beef pot roast'],
 'theme_park', 'Dollywood', 1, '175 cal/100g. ~525 cal per serving (~300g). Braised beef with vegetables and gravy.', TRUE,
 380, 65, 3.2, 0.2, 350, 15, 2.5, 80, 3.0, 5, 22, 5.0, 185, 18.0, 0.03),

-- Funnel cake plain: ~307 cal/100g.
('dollywood_funnel_cake', 'Dollywood Funnel Cake (Plain)', 307, 5.0, 38.0, 15.0,
 0.8, 15.0, 200, 200,
 'theme_park', ARRAY['dollywood funnel cake', 'dollywood plain funnel cake'],
 'theme_park', 'Dollywood', 1, '307 cal/100g. ~614 cal per cake (~200g). Classic funnel cake with powdered sugar.', TRUE,
 300, 50, 4.0, 0.3, 100, 40, 1.5, 15, 0.5, 8, 12, 0.5, 70, 10.0, 0.01),

-- Funnel cake loaded: ~340 cal/100g.
('dollywood_funnel_cake_loaded', 'Dollywood Funnel Cake (Loaded)', 340, 5.0, 44.0, 16.5,
 1.0, 22.0, 280, 280,
 'theme_park', ARRAY['dollywood loaded funnel cake', 'dollywood funnel cake toppings'],
 'theme_park', 'Dollywood', 1, '340 cal/100g. ~952 cal per cake (~280g). Funnel cake with ice cream, fruit, and syrups.', TRUE,
 280, 45, 6.0, 0.3, 120, 50, 1.5, 20, 3.0, 10, 14, 0.5, 80, 8.0, 0.02),

-- Kettle corn: ~420 cal/100g.
('dollywood_kettle_corn', 'Dollywood Kettle Corn', 420, 5.0, 68.0, 15.0,
 6.0, 25.0, 60, NULL,
 'theme_park', ARRAY['dollywood kettle corn', 'dollywood sweet popcorn'],
 'theme_park', 'Dollywood', 1, '420 cal/100g. ~252 cal per serving (~60g). Sweet and salty kettle corn.', TRUE,
 300, 0, 2.0, 0.0, 100, 3, 1.5, 5, 0.0, 0, 30, 0.8, 90, 5.0, 0.01),

-- Smoked sausage on bun: ~260 cal/100g.
('dollywood_smoked_sausage', 'Dollywood Smoked Sausage on Bun', 260, 10.0, 20.0, 16.0,
 0.8, 3.0, 250, 250,
 'theme_park', ARRAY['dollywood smoked sausage', 'dollywood sausage sandwich'],
 'theme_park', 'Dollywood', 1, '260 cal/100g. ~650 cal per sandwich (~250g). Smoked sausage link on hoagie roll.', TRUE,
 780, 50, 6.0, 0.1, 200, 20, 1.5, 0, 1.0, 3, 14, 2.0, 120, 12.0, 0.02),

-- Corn on the cob: ~110 cal/100g.
('dollywood_corn_on_cob', 'Dollywood Corn on the Cob', 110, 3.5, 19.0, 3.5,
 2.0, 3.5, 200, 200,
 'theme_park', ARRAY['dollywood corn on cob', 'dollywood buttered corn'],
 'theme_park', 'Dollywood', 1, '110 cal/100g. ~220 cal per ear (~200g). Buttered corn on the cob.', TRUE,
 150, 5, 1.5, 0.0, 250, 3, 0.5, 10, 6.0, 0, 30, 0.5, 85, 0.5, 0.01),

-- Baked beans: ~110 cal/100g.
('dollywood_baked_beans', 'Dollywood Baked Beans', 110, 5.0, 18.0, 1.5,
 4.0, 8.0, 180, NULL,
 'theme_park', ARRAY['dollywood baked beans', 'dollywood bbq beans'],
 'theme_park', 'Dollywood', 1, '110 cal/100g. ~198 cal per serving (~180g). Sweet smoky baked beans.', TRUE,
 480, 5, 0.3, 0.0, 300, 50, 2.0, 5, 1.0, 0, 40, 1.0, 100, 3.0, 0.01),

-- Coleslaw: ~120 cal/100g.
('dollywood_coleslaw', 'Dollywood Coleslaw', 120, 1.0, 10.0, 8.5,
 1.5, 7.0, 150, NULL,
 'theme_park', ARRAY['dollywood coleslaw', 'dollywood cole slaw'],
 'theme_park', 'Dollywood', 1, '120 cal/100g. ~180 cal per serving (~150g). Creamy Southern-style coleslaw.', TRUE,
 250, 5, 1.2, 0.0, 150, 30, 0.4, 10, 15.0, 0, 8, 0.2, 18, 0.5, 0.02),

-- Fried green tomatoes: ~210 cal/100g.
('dollywood_fried_green_tomatoes', 'Dollywood Fried Green Tomatoes', 210, 4.0, 22.0, 12.0,
 1.5, 3.0, 180, NULL,
 'theme_park', ARRAY['dollywood fried green tomatoes', 'dollywood green tomatoes'],
 'theme_park', 'Dollywood', 1, '210 cal/100g. ~378 cal per order (~180g). Breaded and fried green tomato slices.', TRUE,
 380, 15, 2.5, 0.1, 250, 15, 1.0, 25, 10.0, 3, 12, 0.3, 40, 3.0, 0.01),

-- Blackberry cobbler: ~220 cal/100g.
('dollywood_blackberry_cobbler', 'Dollywood Blackberry Cobbler', 220, 2.5, 36.0, 8.0,
 2.5, 22.0, 200, NULL,
 'theme_park', ARRAY['dollywood blackberry cobbler', 'dollywood cobbler'],
 'theme_park', 'Dollywood', 1, '220 cal/100g. ~440 cal per serving (~200g). Warm blackberry cobbler with biscuit topping.', TRUE,
 180, 10, 3.5, 0.1, 100, 25, 1.0, 10, 8.0, 3, 12, 0.3, 30, 3.0, 0.01),

-- Banana pudding: ~180 cal/100g.
('dollywood_banana_pudding', 'Dollywood Banana Pudding', 180, 3.0, 28.0, 6.5,
 0.5, 20.0, 200, NULL,
 'theme_park', ARRAY['dollywood banana pudding', 'dollywood nana pudding'],
 'theme_park', 'Dollywood', 1, '180 cal/100g. ~360 cal per serving (~200g). Southern banana pudding with wafers and whipped cream.', TRUE,
 150, 20, 3.5, 0.1, 180, 60, 0.3, 20, 3.0, 10, 12, 0.3, 60, 2.0, 0.02),

-- Sweet tea large: ~35 cal/100ml.
('dollywood_sweet_tea', 'Dollywood Sweet Tea (Large)', 35, 0.0, 8.5, 0.0,
 0.0, 8.5, 600, NULL,
 'theme_park', ARRAY['dollywood sweet tea', 'dollywood iced tea', 'southern sweet tea'],
 'theme_park', 'Dollywood', 1, '35 cal/100ml. ~210 cal per large (600ml). Southern-style sweetened iced tea.', TRUE,
 5, 0, 0.0, 0.0, 20, 2, 0.0, 0, 0.0, 0, 2, 0.0, 2, 0.0, 0.0),


-- ==========================================
-- SIX FLAGS (~20 items)
-- ==========================================

-- Funnel cake plain: ~307 cal/100g.
('six_flags_funnel_cake', 'Six Flags Funnel Cake', 307, 5.0, 38.0, 15.0,
 0.8, 15.0, 200, 200,
 'theme_park', ARRAY['six flags funnel cake', 'six flags plain funnel cake'],
 'theme_park', 'Six Flags', 1, '307 cal/100g. ~614 cal per cake (~200g). Classic funnel cake with powdered sugar.', TRUE,
 300, 50, 4.0, 0.3, 100, 40, 1.5, 15, 0.5, 8, 12, 0.5, 70, 10.0, 0.01),

-- Turkey leg: ~161 cal/100g.
('six_flags_turkey_leg', 'Six Flags Turkey Leg', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['six flags turkey leg', 'six flags smoked turkey leg'],
 'theme_park', 'Six Flags', 1, '161 cal/100g. ~1095 cal per leg (~680g). Smoked turkey drumstick.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Corn dog: ~270 cal/100g.
('six_flags_corn_dog', 'Six Flags Corn Dog', 270, 8.0, 28.0, 14.0,
 1.0, 4.0, 175, 175,
 'theme_park', ARRAY['six flags corn dog', 'six flags corndog'],
 'theme_park', 'Six Flags', 1, '270 cal/100g. ~473 cal per corn dog (~175g). Battered and fried hot dog on a stick.', TRUE,
 680, 30, 4.5, 0.2, 120, 30, 1.5, 5, 0.0, 3, 10, 0.8, 80, 8.0, 0.02),

-- Loaded nachos: ~240 cal/100g.
('six_flags_loaded_nachos', 'Six Flags Loaded Nachos', 240, 8.0, 24.0, 13.0,
 2.5, 2.0, 400, NULL,
 'theme_park', ARRAY['six flags nachos', 'six flags loaded nachos'],
 'theme_park', 'Six Flags', 1, '240 cal/100g. ~960 cal per order (~400g). Tortilla chips with cheese, beef, jalapenos, sour cream.', TRUE,
 720, 30, 5.5, 0.3, 200, 120, 1.5, 30, 3.0, 3, 25, 1.5, 150, 6.0, 0.02),

-- BBQ pulled pork sandwich: ~210 cal/100g.
('six_flags_bbq_pulled_pork', 'Six Flags BBQ Pulled Pork Sandwich', 210, 14.0, 18.0, 9.0,
 0.8, 8.0, 300, 300,
 'theme_park', ARRAY['six flags pulled pork', 'six flags bbq sandwich'],
 'theme_park', 'Six Flags', 1, '210 cal/100g. ~630 cal per sandwich (~300g). Pulled pork with BBQ sauce on bun.', TRUE,
 580, 55, 3.0, 0.1, 280, 30, 1.8, 8, 1.0, 5, 20, 2.5, 150, 18.0, 0.02),

-- Chicken tenders basket: ~260 cal/100g.
('six_flags_chicken_tenders', 'Six Flags Chicken Tenders Basket', 260, 16.0, 18.0, 14.0,
 1.0, 0.5, 250, NULL,
 'theme_park', ARRAY['six flags chicken tenders', 'six flags chicken strips basket'],
 'theme_park', 'Six Flags', 1, '260 cal/100g. ~650 cal per basket (~250g). Breaded chicken tenders with fries.', TRUE,
 600, 50, 3.5, 0.2, 220, 18, 1.2, 5, 2.0, 3, 20, 1.0, 160, 15.0, 0.02),

-- Pizza slice: ~270 cal/100g.
('six_flags_pizza', 'Six Flags Pizza Slice', 270, 11.0, 30.0, 12.0,
 1.5, 4.0, 180, 180,
 'theme_park', ARRAY['six flags pizza', 'six flags pizza slice'],
 'theme_park', 'Six Flags', 1, '270 cal/100g. ~486 cal per slice (~180g). Large cheese pizza slice.', TRUE,
 600, 25, 5.0, 0.2, 150, 180, 1.5, 50, 2.0, 5, 18, 1.2, 160, 15.0, 0.02),

-- Dippin' Dots cup: ~210 cal/100g.
('six_flags_dippin_dots', 'Six Flags Dippin'' Dots (Cup)', 210, 3.5, 28.0, 10.0,
 0.0, 24.0, 100, NULL,
 'theme_park', ARRAY['six flags dippin dots', 'six flags dippin'' dots', 'dippin dots theme park'],
 'theme_park', 'Six Flags', 1, '210 cal/100g. ~210 cal per cup (~100g). Flash-frozen beaded ice cream.', TRUE,
 60, 25, 6.0, 0.1, 140, 80, 0.2, 40, 0.0, 15, 12, 0.4, 70, 2.0, 0.02),

-- Cotton candy bag: ~380 cal/100g.
('six_flags_cotton_candy', 'Six Flags Cotton Candy', 380, 0.0, 95.0, 0.0,
 0.0, 95.0, 30, NULL,
 'theme_park', ARRAY['six flags cotton candy', 'six flags candy floss'],
 'theme_park', 'Six Flags', 1, '380 cal/100g. ~114 cal per bag (~30g). Spun sugar, nearly pure carbohydrate.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0.0, 0.0),

-- Giant pretzel: ~338 cal/100g.
('six_flags_giant_pretzel', 'Six Flags Giant Pretzel', 338, 8.2, 69.6, 3.1,
 1.5, 2.0, 200, 200,
 'theme_park', ARRAY['six flags pretzel', 'six flags giant pretzel', 'six flags soft pretzel'],
 'theme_park', 'Six Flags', 1, '338 cal/100g. ~676 cal per pretzel (~200g). Large soft pretzel with salt.', TRUE,
 870, 0, 0.8, 0.0, 80, 15, 3.0, 0, 0.0, 0, 18, 0.6, 70, 12.0, 0.01),

-- Loaded fries: ~280 cal/100g.
('six_flags_loaded_fries', 'Six Flags Loaded Fries', 280, 7.0, 28.0, 16.0,
 2.0, 1.0, 350, NULL,
 'theme_park', ARRAY['six flags loaded fries', 'six flags cheese fries'],
 'theme_park', 'Six Flags', 1, '280 cal/100g. ~980 cal per order (~350g). French fries with cheese and bacon.', TRUE,
 750, 25, 7.0, 0.3, 400, 90, 1.0, 20, 5.0, 3, 22, 1.0, 130, 4.0, 0.02),

-- Philly cheesesteak: ~230 cal/100g.
('six_flags_philly_cheesesteak', 'Six Flags Philly Cheesesteak', 230, 14.0, 18.0, 11.0,
 1.0, 2.0, 300, 300,
 'theme_park', ARRAY['six flags cheesesteak', 'six flags philly cheesesteak'],
 'theme_park', 'Six Flags', 1, '230 cal/100g. ~690 cal per sandwich (~300g). Sliced beef with cheese on hoagie roll.', TRUE,
 650, 50, 4.5, 0.2, 220, 80, 2.5, 10, 3.0, 5, 20, 3.5, 160, 15.0, 0.03),

-- Churros: ~371 cal/100g.
('six_flags_churros', 'Six Flags Churros', 371, 5.0, 41.7, 20.0,
 1.7, 10.0, 100, 100,
 'theme_park', ARRAY['six flags churros', 'six flags churro'],
 'theme_park', 'Six Flags', 1, '371 cal/100g. ~371 cal per churro (~100g). Cinnamon sugar churros.', TRUE,
 220, 15, 5.0, 0.5, 60, 20, 1.2, 5, 0.0, 0, 10, 0.4, 45, 8.0, 0.01),

-- Frozen lemonade: ~50 cal/100g.
('six_flags_frozen_lemonade', 'Six Flags Frozen Lemonade', 50, 0.0, 13.0, 0.0,
 0.0, 12.0, 450, NULL,
 'theme_park', ARRAY['six flags frozen lemonade', 'six flags lemonade'],
 'theme_park', 'Six Flags', 1, '50 cal/100g. ~225 cal per cup (450ml). Frozen blended lemonade.', TRUE,
 5, 0, 0.0, 0.0, 30, 3, 0.1, 0, 10.0, 0, 3, 0.0, 5, 0.2, 0.0),

-- Italian sausage sandwich: ~245 cal/100g.
('six_flags_italian_sausage', 'Six Flags Italian Sausage Sandwich', 245, 11.0, 18.0, 14.5,
 1.2, 3.0, 280, 280,
 'theme_park', ARRAY['six flags italian sausage', 'six flags sausage sandwich'],
 'theme_park', 'Six Flags', 1, '245 cal/100g. ~686 cal per sandwich (~280g). Italian sausage with peppers and onions on roll.', TRUE,
 720, 50, 5.5, 0.1, 220, 25, 1.8, 15, 8.0, 3, 16, 2.0, 140, 14.0, 0.02),

-- Chicken quesadilla: ~240 cal/100g.
('six_flags_chicken_quesadilla', 'Six Flags Chicken Quesadilla', 240, 14.0, 18.0, 12.0,
 1.0, 1.5, 250, NULL,
 'theme_park', ARRAY['six flags quesadilla', 'six flags chicken quesadilla'],
 'theme_park', 'Six Flags', 1, '240 cal/100g. ~600 cal per quesadilla (~250g). Grilled tortilla with chicken and cheese.', TRUE,
 580, 50, 5.5, 0.2, 180, 150, 1.5, 30, 1.0, 5, 20, 2.0, 200, 14.0, 0.02),

-- Walking taco: ~210 cal/100g.
('six_flags_walking_taco', 'Six Flags Walking Taco', 210, 9.0, 22.0, 10.0,
 2.5, 2.0, 250, NULL,
 'theme_park', ARRAY['six flags walking taco', 'six flags taco in a bag'],
 'theme_park', 'Six Flags', 1, '210 cal/100g. ~525 cal per bag (~250g). Chip bag with seasoned beef, cheese, lettuce, salsa.', TRUE,
 600, 30, 4.0, 0.2, 200, 80, 1.5, 25, 3.0, 3, 20, 2.0, 130, 8.0, 0.02),

-- Onion rings: ~330 cal/100g.
('six_flags_onion_rings', 'Six Flags Onion Rings', 330, 4.0, 38.0, 18.0,
 2.0, 5.0, 170, NULL,
 'theme_park', ARRAY['six flags onion rings', 'six flags fried onion rings'],
 'theme_park', 'Six Flags', 1, '330 cal/100g. ~561 cal per order (~170g). Beer-battered deep-fried onion rings.', TRUE,
 500, 10, 4.5, 0.3, 120, 25, 1.0, 3, 2.0, 3, 10, 0.3, 40, 3.0, 0.01),

-- Ice cream sundae: ~250 cal/100g.
('six_flags_ice_cream_sundae', 'Six Flags Ice Cream Sundae', 250, 3.5, 32.0, 12.5,
 0.5, 26.0, 200, NULL,
 'theme_park', ARRAY['six flags sundae', 'six flags ice cream sundae'],
 'theme_park', 'Six Flags', 1, '250 cal/100g. ~500 cal per sundae (~200g). Vanilla ice cream with toppings and whipped cream.', TRUE,
 100, 45, 7.5, 0.2, 180, 100, 0.5, 60, 1.0, 15, 15, 0.5, 90, 2.5, 0.02),

-- Chocolate chip cookie: ~480 cal/100g.
('six_flags_choc_chip_cookie', 'Six Flags Chocolate Chip Cookie', 480, 5.0, 60.0, 24.0,
 2.0, 35.0, 80, 80,
 'theme_park', ARRAY['six flags cookie', 'six flags chocolate chip cookie'],
 'theme_park', 'Six Flags', 1, '480 cal/100g. ~384 cal per cookie (~80g). Large chocolate chip cookie.', TRUE,
 300, 25, 12.0, 0.3, 100, 20, 2.0, 20, 0.0, 3, 20, 0.6, 55, 5.0, 0.01),


-- ==========================================
-- HERSHEYPARK (~8 items)
-- ==========================================

-- Hershey's chocolate shake: ~200 cal/100g.
('hersheypark_chocolate_shake', 'Hersheypark Hershey''s Chocolate Shake', 200, 4.5, 28.0, 8.5,
 0.5, 24.0, 450, NULL,
 'theme_park', ARRAY['hershey chocolate shake', 'hersheypark milkshake', 'hershey''s shake'],
 'theme_park', 'Hersheypark', 1, '200 cal/100g. ~900 cal per shake (~450ml). Thick chocolate milkshake with Hershey''s syrup.', TRUE,
 150, 30, 5.0, 0.1, 280, 130, 0.8, 40, 0.5, 20, 25, 0.7, 120, 3.0, 0.02),

-- Chocolate funnel cake: ~340 cal/100g.
('hersheypark_chocolate_funnel_cake', 'Hersheypark Chocolate Funnel Cake', 340, 5.5, 42.0, 17.0,
 1.2, 22.0, 280, 280,
 'theme_park', ARRAY['hersheypark chocolate funnel cake', 'hershey funnel cake'],
 'theme_park', 'Hersheypark', 1, '340 cal/100g. ~952 cal per cake (~280g). Funnel cake drizzled with Hershey''s chocolate.', TRUE,
 310, 50, 6.0, 0.3, 140, 50, 2.0, 15, 0.0, 8, 18, 0.7, 80, 8.0, 0.01),

-- Whoopie pie: ~380 cal/100g.
('hersheypark_whoopie_pie', 'Hersheypark Whoopie Pie', 380, 4.0, 52.0, 18.0,
 1.5, 35.0, 120, 120,
 'theme_park', ARRAY['hersheypark whoopie pie', 'hershey whoopie pie', 'pennsylvania whoopie pie'],
 'theme_park', 'Hersheypark', 1, '380 cal/100g. ~456 cal per pie (~120g). Two chocolate cakes with cream filling.', TRUE,
 280, 25, 8.0, 0.5, 120, 30, 2.0, 10, 0.0, 3, 18, 0.6, 60, 5.0, 0.01),

-- Soft pretzel with cheese: ~300 cal/100g (pretzel + cheese dip).
('hersheypark_pretzel_cheese', 'Hersheypark Soft Pretzel with Cheese', 300, 8.0, 50.0, 8.0,
 1.5, 3.0, 250, NULL,
 'theme_park', ARRAY['hersheypark pretzel', 'hershey soft pretzel cheese'],
 'theme_park', 'Hersheypark', 1, '300 cal/100g. ~750 cal per serving (~250g). Soft pretzel with warm cheese dipping sauce.', TRUE,
 900, 10, 3.5, 0.1, 80, 60, 2.5, 15, 0.0, 3, 16, 0.6, 80, 10.0, 0.01),

-- Chicken & waffles: ~270 cal/100g.
('hersheypark_chicken_waffles', 'Hersheypark Chicken & Waffles', 270, 13.0, 26.0, 13.0,
 0.8, 5.0, 350, NULL,
 'theme_park', ARRAY['hersheypark chicken and waffles', 'hershey chicken waffles'],
 'theme_park', 'Hersheypark', 1, '270 cal/100g. ~945 cal per plate (~350g). Fried chicken on waffles with maple syrup.', TRUE,
 620, 60, 4.0, 0.2, 190, 40, 1.8, 20, 0.5, 5, 18, 1.2, 140, 14.0, 0.02),

-- Reese's sundae: ~280 cal/100g.
('hersheypark_reeses_sundae', 'Hersheypark Reese''s Sundae', 280, 5.0, 34.0, 14.0,
 1.0, 28.0, 250, NULL,
 'theme_park', ARRAY['hersheypark reese''s sundae', 'hershey reeses sundae', 'reese''s peanut butter sundae'],
 'theme_park', 'Hersheypark', 1, '280 cal/100g. ~700 cal per sundae (~250g). Ice cream with Reese''s peanut butter cups and sauce.', TRUE,
 160, 35, 7.0, 0.1, 250, 100, 0.8, 45, 0.5, 15, 30, 1.0, 110, 3.0, 0.03),

-- S'mores: ~420 cal/100g.
('hersheypark_smores', 'Hersheypark S''mores', 420, 4.0, 62.0, 17.0,
 1.5, 40.0, 80, 80,
 'theme_park', ARRAY['hersheypark s''mores', 'hershey smores', 'hersheypark smore'],
 'theme_park', 'Hersheypark', 1, '420 cal/100g. ~336 cal per s''more (~80g). Graham crackers, Hershey''s chocolate, marshmallow.', TRUE,
 200, 5, 8.0, 0.1, 80, 30, 1.5, 5, 0.0, 3, 15, 0.5, 45, 4.0, 0.01),

-- Chocolate dipped strawberry: ~180 cal/100g.
('hersheypark_choc_strawberry', 'Hersheypark Chocolate Dipped Strawberry', 180, 1.5, 28.0, 8.0,
 2.0, 22.0, 50, 50,
 'theme_park', ARRAY['hersheypark chocolate strawberry', 'hershey dipped strawberry', 'chocolate covered strawberry'],
 'theme_park', 'Hersheypark', 1, '180 cal/100g. ~90 cal per strawberry (~50g). Fresh strawberry dipped in Hershey''s chocolate.', TRUE,
 5, 3, 4.5, 0.0, 150, 15, 0.8, 2, 30.0, 0, 12, 0.3, 25, 1.0, 0.01),

-- ==========================================
-- KNOTT'S BERRY FARM (~7 items)
-- ==========================================

-- Mrs. Knott's fried chicken dinner: ~215 cal/100g (chicken portion).
('knotts_fried_chicken_dinner', 'Knott''s Berry Farm Mrs. Knott''s Fried Chicken Dinner', 215, 18.0, 10.0, 12.0,
 0.5, 0.5, 400, NULL,
 'theme_park', ARRAY['knott''s fried chicken', 'mrs knott''s chicken dinner', 'knott''s berry farm chicken'],
 'theme_park', 'Knott''s Berry Farm', 1, '215 cal/100g. ~860 cal per dinner (~400g). Famous fried chicken with sides and biscuits.', TRUE,
 520, 80, 3.5, 0.1, 260, 25, 1.5, 15, 2.0, 5, 24, 1.8, 190, 20.0, 0.03),

-- Boysenberry pie: ~260 cal/100g.
('knotts_boysenberry_pie', 'Knott''s Berry Farm Boysenberry Pie', 260, 2.5, 38.0, 11.0,
 2.5, 20.0, 150, 150,
 'theme_park', ARRAY['knott''s boysenberry pie', 'boysenberry pie', 'knott''s berry pie'],
 'theme_park', 'Knott''s Berry Farm', 1, '260 cal/100g. ~390 cal per slice (~150g). Famous boysenberry pie with flaky crust.', TRUE,
 200, 5, 4.5, 0.2, 80, 15, 0.8, 5, 5.0, 3, 8, 0.2, 25, 2.0, 0.02),

-- Boysenberry punch: ~50 cal/100ml.
('knotts_boysenberry_punch', 'Knott''s Berry Farm Boysenberry Punch', 50, 0.0, 12.5, 0.0,
 0.0, 12.0, 450, NULL,
 'theme_park', ARRAY['knott''s boysenberry punch', 'boysenberry punch', 'knott''s punch'],
 'theme_park', 'Knott''s Berry Farm', 1, '50 cal/100ml. ~225 cal per cup (450ml). Sweet boysenberry-flavored punch.', TRUE,
 10, 0, 0.0, 0.0, 40, 5, 0.2, 2, 8.0, 0, 3, 0.1, 5, 0.2, 0.0),

-- Boysenberry funnel cake: ~330 cal/100g.
('knotts_boysenberry_funnel_cake', 'Knott''s Berry Farm Boysenberry Funnel Cake', 330, 5.0, 42.0, 16.0,
 1.2, 20.0, 280, 280,
 'theme_park', ARRAY['knott''s boysenberry funnel cake', 'boysenberry funnel cake'],
 'theme_park', 'Knott''s Berry Farm', 1, '330 cal/100g. ~924 cal per cake (~280g). Funnel cake topped with boysenberry sauce.', TRUE,
 290, 50, 4.5, 0.3, 110, 40, 1.5, 10, 5.0, 8, 12, 0.5, 70, 8.0, 0.02),

-- Boysenberry jam (packet): ~250 cal/100g.
('knotts_boysenberry_jam', 'Knott''s Berry Farm Boysenberry Jam', 250, 0.3, 62.0, 0.0,
 1.0, 50.0, 20, NULL,
 'theme_park', ARRAY['knott''s boysenberry jam', 'boysenberry jam', 'knott''s jam'],
 'theme_park', 'Knott''s Berry Farm', 1, '250 cal/100g. ~50 cal per packet (~20g). Classic boysenberry preserves.', TRUE,
 5, 0, 0.0, 0.0, 30, 8, 0.3, 2, 4.0, 0, 4, 0.1, 5, 0.2, 0.01),

-- Chicken pot pie: ~190 cal/100g.
('knotts_chicken_pot_pie', 'Knott''s Berry Farm Chicken Pot Pie', 190, 8.0, 18.0, 10.0,
 1.5, 2.0, 350, NULL,
 'theme_park', ARRAY['knott''s chicken pot pie', 'knott''s pot pie'],
 'theme_park', 'Knott''s Berry Farm', 1, '190 cal/100g. ~665 cal per pie (~350g). Creamy chicken pot pie with flaky crust.', TRUE,
 520, 30, 4.0, 0.2, 200, 25, 1.2, 60, 2.0, 5, 15, 0.8, 100, 10.0, 0.02),

-- Boysenberry ice cream: ~210 cal/100g.
('knotts_boysenberry_ice_cream', 'Knott''s Berry Farm Boysenberry Ice Cream', 210, 3.5, 28.0, 10.0,
 0.5, 24.0, 150, NULL,
 'theme_park', ARRAY['knott''s boysenberry ice cream', 'boysenberry ice cream'],
 'theme_park', 'Knott''s Berry Farm', 1, '210 cal/100g. ~315 cal per scoop (~150g). Creamy boysenberry-flavored ice cream.', TRUE,
 65, 35, 6.0, 0.1, 150, 90, 0.3, 40, 3.0, 15, 12, 0.4, 80, 2.0, 0.02),

-- ==========================================
-- CEDAR POINT (~5 items)
-- ==========================================

-- Boardwalk fries: ~310 cal/100g.
('cedar_point_boardwalk_fries', 'Cedar Point Boardwalk Fries', 310, 3.5, 38.0, 16.0,
 3.0, 0.5, 250, NULL,
 'theme_park', ARRAY['cedar point fries', 'cedar point boardwalk fries'],
 'theme_park', 'Cedar Point', 1, '310 cal/100g. ~775 cal per order (~250g). Thick-cut seasoned boardwalk-style fries.', TRUE,
 550, 0, 3.0, 0.2, 500, 10, 0.8, 0, 8.0, 0, 25, 0.3, 55, 0.5, 0.01),

-- Deep dish Chicago pizza: ~260 cal/100g.
('cedar_point_deep_dish_pizza', 'Cedar Point Deep Dish Chicago Pizza', 260, 10.0, 28.0, 12.0,
 1.5, 4.0, 250, 250,
 'theme_park', ARRAY['cedar point deep dish pizza', 'cedar point chicago pizza'],
 'theme_park', 'Cedar Point', 1, '260 cal/100g. ~650 cal per slice (~250g). Thick-crust deep dish pizza.', TRUE,
 650, 30, 5.5, 0.2, 180, 180, 2.0, 50, 3.0, 5, 20, 1.5, 180, 16.0, 0.02),

-- BBQ rib platter: ~230 cal/100g.
('cedar_point_bbq_rib_platter', 'Cedar Point BBQ Rib Platter', 230, 16.0, 10.0, 14.0,
 0.5, 6.0, 400, NULL,
 'theme_park', ARRAY['cedar point ribs', 'cedar point bbq ribs', 'cedar point rib platter'],
 'theme_park', 'Cedar Point', 1, '230 cal/100g. ~920 cal per platter (~400g). Smoked ribs with BBQ sauce and sides.', TRUE,
 600, 70, 5.5, 0.1, 300, 35, 1.8, 10, 2.0, 5, 20, 3.5, 180, 18.0, 0.03),

-- Funnel cake: ~307 cal/100g.
('cedar_point_funnel_cake', 'Cedar Point Funnel Cake', 307, 5.0, 38.0, 15.0,
 0.8, 15.0, 200, 200,
 'theme_park', ARRAY['cedar point funnel cake'],
 'theme_park', 'Cedar Point', 1, '307 cal/100g. ~614 cal per cake (~200g). Classic funnel cake with powdered sugar.', TRUE,
 300, 50, 4.0, 0.3, 100, 40, 1.5, 15, 0.5, 8, 12, 0.5, 70, 10.0, 0.01),

-- Lake Erie perch basket: ~220 cal/100g.
('cedar_point_perch_basket', 'Cedar Point Lake Erie Perch Basket', 220, 14.0, 16.0, 11.0,
 1.0, 0.5, 300, NULL,
 'theme_park', ARRAY['cedar point perch', 'cedar point lake erie perch', 'cedar point fish basket'],
 'theme_park', 'Cedar Point', 1, '220 cal/100g. ~660 cal per basket (~300g). Breaded fried perch with fries and coleslaw.', TRUE,
 480, 45, 2.5, 0.1, 320, 30, 1.2, 5, 3.0, 15, 28, 0.8, 200, 25.0, 0.12),

-- ==========================================
-- BUSCH GARDENS (~5 items)
-- ==========================================

-- Bratwurst with sauerkraut: ~220 cal/100g.
('busch_gardens_bratwurst', 'Busch Gardens Bratwurst with Sauerkraut', 220, 10.0, 8.0, 17.0,
 1.5, 1.5, 280, NULL,
 'theme_park', ARRAY['busch gardens bratwurst', 'busch gardens brat', 'busch gardens sausage'],
 'theme_park', 'Busch Gardens', 1, '220 cal/100g. ~616 cal per serving (~280g). Grilled bratwurst with sauerkraut on roll.', TRUE,
 750, 55, 6.5, 0.1, 220, 25, 1.5, 0, 8.0, 3, 16, 2.0, 130, 12.0, 0.02),

-- Fish & chips: ~210 cal/100g.
('busch_gardens_fish_chips', 'Busch Gardens Fish & Chips', 210, 9.0, 22.0, 10.0,
 1.5, 0.5, 350, NULL,
 'theme_park', ARRAY['busch gardens fish and chips', 'busch gardens fish chips'],
 'theme_park', 'Busch Gardens', 1, '210 cal/100g. ~735 cal per serving (~350g). Beer-battered fish with chips.', TRUE,
 480, 30, 2.5, 0.1, 300, 20, 1.0, 5, 3.0, 10, 25, 0.5, 120, 18.0, 0.08),

-- Pasta Bolognese: ~150 cal/100g.
('busch_gardens_pasta_bolognese', 'Busch Gardens Pasta Bolognese', 150, 7.0, 18.0, 5.5,
 1.5, 3.0, 350, NULL,
 'theme_park', ARRAY['busch gardens bolognese', 'busch gardens pasta', 'busch gardens spaghetti'],
 'theme_park', 'Busch Gardens', 1, '150 cal/100g. ~525 cal per plate (~350g). Pasta with meat sauce.', TRUE,
 450, 25, 2.0, 0.1, 280, 30, 2.0, 30, 4.0, 3, 20, 2.0, 120, 12.0, 0.02),

-- Belgian waffles: ~310 cal/100g.
('busch_gardens_belgian_waffle', 'Busch Gardens Belgian Waffles', 310, 6.0, 40.0, 14.0,
 0.8, 18.0, 200, 200,
 'theme_park', ARRAY['busch gardens waffle', 'busch gardens belgian waffle'],
 'theme_park', 'Busch Gardens', 1, '310 cal/100g. ~620 cal per waffle with toppings (~200g). Thick Belgian-style waffle.', TRUE,
 350, 55, 7.0, 0.2, 100, 50, 1.5, 40, 0.5, 10, 12, 0.5, 80, 8.0, 0.02),

-- Pretzel with beer cheese: ~310 cal/100g.
('busch_gardens_pretzel_beer_cheese', 'Busch Gardens Pretzel with Beer Cheese', 310, 9.0, 48.0, 10.0,
 1.5, 3.0, 280, NULL,
 'theme_park', ARRAY['busch gardens pretzel', 'busch gardens beer cheese pretzel'],
 'theme_park', 'Busch Gardens', 1, '310 cal/100g. ~868 cal per serving (~280g). Soft pretzel with warm beer cheese dip.', TRUE,
 920, 15, 4.5, 0.1, 90, 80, 2.5, 20, 0.0, 3, 16, 0.8, 90, 10.0, 0.01),

-- ==========================================
-- SEAWORLD (~5 items)
-- ==========================================

-- Fish tacos (2): ~185 cal/100g.
('seaworld_fish_tacos', 'SeaWorld Fish Tacos (2)', 185, 10.0, 18.0, 8.0,
 2.0, 2.0, 280, NULL,
 'theme_park', ARRAY['seaworld fish tacos', 'seaworld tacos'],
 'theme_park', 'SeaWorld', 1, '185 cal/100g. ~518 cal per 2 tacos (~280g). Grilled or battered fish tacos with slaw.', TRUE,
 480, 30, 2.0, 0.1, 250, 50, 1.2, 15, 8.0, 8, 25, 0.6, 140, 15.0, 0.10),

-- Coconut shrimp basket: ~260 cal/100g.
('seaworld_coconut_shrimp', 'SeaWorld Coconut Shrimp Basket', 260, 10.0, 24.0, 14.0,
 2.0, 6.0, 300, NULL,
 'theme_park', ARRAY['seaworld coconut shrimp', 'seaworld shrimp basket'],
 'theme_park', 'SeaWorld', 1, '260 cal/100g. ~780 cal per basket (~300g). Coconut-crusted fried shrimp with fries.', TRUE,
 550, 100, 5.0, 0.2, 200, 40, 1.5, 10, 3.0, 8, 25, 1.0, 180, 20.0, 0.08),

-- Clam chowder bowl: ~85 cal/100g.
('seaworld_clam_chowder', 'SeaWorld Clam Chowder Bowl', 85, 3.5, 8.0, 4.5,
 0.5, 0.5, 350, NULL,
 'theme_park', ARRAY['seaworld clam chowder', 'seaworld chowder'],
 'theme_park', 'SeaWorld', 1, '85 cal/100g. ~298 cal per bowl (~350g). New England-style clam chowder in bread bowl.', TRUE,
 520, 15, 2.5, 0.1, 200, 40, 1.0, 15, 2.0, 5, 10, 0.5, 60, 5.0, 0.05),

-- Smoked turkey leg: ~161 cal/100g.
('seaworld_turkey_leg', 'SeaWorld Smoked Turkey Leg', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['seaworld turkey leg', 'seaworld smoked turkey leg'],
 'theme_park', 'SeaWorld', 1, '161 cal/100g. ~1095 cal per leg (~680g). Smoked turkey drumstick.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Shrimp po'boy: ~230 cal/100g.
('seaworld_shrimp_poboy', 'SeaWorld Shrimp Po''Boy', 230, 9.0, 26.0, 10.0,
 1.0, 2.0, 300, 300,
 'theme_park', ARRAY['seaworld shrimp po''boy', 'seaworld poboy', 'seaworld po boy'],
 'theme_park', 'SeaWorld', 1, '230 cal/100g. ~690 cal per sandwich (~300g). Fried shrimp on French bread with remoulade.', TRUE,
 650, 80, 2.5, 0.1, 180, 35, 2.0, 10, 3.0, 5, 20, 1.0, 140, 18.0, 0.06),


-- ==========================================
-- GENERIC THEME PARK (~20 items)
-- ==========================================

-- Turkey leg: ~161 cal/100g.
('theme_park_turkey_leg', 'Theme Park Turkey Leg', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['theme park turkey leg', 'amusement park turkey leg', 'carnival turkey leg'],
 'theme_park', 'Theme Park', 1, '161 cal/100g. ~1095 cal per leg (~680g). Smoked turkey drumstick, a theme park classic.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Corn dog: ~270 cal/100g.
('theme_park_corn_dog', 'Theme Park Corn Dog', 270, 8.0, 28.0, 14.0,
 1.0, 4.0, 175, 175,
 'theme_park', ARRAY['theme park corn dog', 'amusement park corn dog', 'carnival corn dog', 'fair corn dog'],
 'theme_park', 'Theme Park', 1, '270 cal/100g. ~473 cal per corn dog (~175g). Battered and fried hot dog on a stick.', TRUE,
 680, 30, 4.5, 0.2, 120, 30, 1.5, 5, 0.0, 3, 10, 0.8, 80, 8.0, 0.02),

-- Funnel cake plain: ~307 cal/100g.
('theme_park_funnel_cake', 'Theme Park Funnel Cake', 307, 5.0, 38.0, 15.0,
 0.8, 15.0, 200, 200,
 'theme_park', ARRAY['theme park funnel cake', 'carnival funnel cake', 'fair funnel cake', 'amusement park funnel cake'],
 'theme_park', 'Theme Park', 1, '307 cal/100g. ~614 cal per cake (~200g). Deep-fried batter with powdered sugar.', TRUE,
 300, 50, 4.0, 0.3, 100, 40, 1.5, 15, 0.5, 8, 12, 0.5, 70, 10.0, 0.01),

-- Cotton candy: ~380 cal/100g.
('theme_park_cotton_candy', 'Theme Park Cotton Candy', 380, 0.0, 95.0, 0.0,
 0.0, 95.0, 30, NULL,
 'theme_park', ARRAY['theme park cotton candy', 'carnival cotton candy', 'fair cotton candy', 'candy floss'],
 'theme_park', 'Theme Park', 1, '380 cal/100g. ~114 cal per bag (~30g). Spun sugar, nearly pure carbohydrate.', TRUE,
 0, 0, 0.0, 0.0, 0, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0.0, 0.0),

-- Giant pretzel: ~338 cal/100g.
('theme_park_giant_pretzel', 'Theme Park Giant Pretzel', 338, 8.2, 69.6, 3.1,
 1.5, 2.0, 200, 200,
 'theme_park', ARRAY['theme park pretzel', 'amusement park pretzel', 'carnival pretzel', 'fair soft pretzel'],
 'theme_park', 'Theme Park', 1, '338 cal/100g. ~676 cal per pretzel (~200g). Large soft pretzel with salt.', TRUE,
 870, 0, 0.8, 0.0, 80, 15, 3.0, 0, 0.0, 0, 18, 0.6, 70, 12.0, 0.01),

-- Dippin' Dots cup: ~210 cal/100g.
('theme_park_dippin_dots', 'Theme Park Dippin'' Dots', 210, 3.5, 28.0, 10.0,
 0.0, 24.0, 100, NULL,
 'theme_park', ARRAY['theme park dippin dots', 'amusement park dippin'' dots', 'dippin dots'],
 'theme_park', 'Theme Park', 1, '210 cal/100g. ~210 cal per cup (~100g). Flash-frozen beaded ice cream.', TRUE,
 60, 25, 6.0, 0.1, 140, 80, 0.2, 40, 0.0, 15, 12, 0.4, 70, 2.0, 0.02),

-- Popcorn bucket: ~500 cal/100g.
('theme_park_popcorn', 'Theme Park Popcorn Bucket', 500, 7.0, 52.0, 30.0,
 8.0, 0.5, 80, NULL,
 'theme_park', ARRAY['theme park popcorn', 'amusement park popcorn', 'carnival popcorn', 'fair popcorn'],
 'theme_park', 'Theme Park', 1, '500 cal/100g. ~400 cal per serving (~80g). Buttered popcorn in collectible bucket.', TRUE,
 700, 0, 8.0, 0.5, 200, 5, 1.5, 15, 0.0, 0, 30, 1.0, 100, 5.0, 0.01),

-- Lemonade large: ~40 cal/100ml.
('theme_park_lemonade', 'Theme Park Lemonade (Large)', 40, 0.0, 10.0, 0.0,
 0.0, 9.5, 550, NULL,
 'theme_park', ARRAY['theme park lemonade', 'amusement park lemonade', 'carnival lemonade', 'fresh squeezed lemonade'],
 'theme_park', 'Theme Park', 1, '40 cal/100ml. ~220 cal per large (550ml). Fresh-squeezed style lemonade.', TRUE,
 5, 0, 0.0, 0.0, 40, 3, 0.1, 0, 15.0, 0, 3, 0.0, 5, 0.2, 0.0),

-- Frozen slushie: ~45 cal/100ml.
('theme_park_frozen_slushie', 'Theme Park Frozen Slushie', 45, 0.0, 11.5, 0.0,
 0.0, 11.0, 500, NULL,
 'theme_park', ARRAY['theme park slushie', 'amusement park slush', 'carnival slushie', 'icee', 'frozen drink'],
 'theme_park', 'Theme Park', 1, '45 cal/100ml. ~225 cal per large (500ml). Frozen flavored ice drink.', TRUE,
 10, 0, 0.0, 0.0, 5, 2, 0.0, 0, 0.0, 0, 1, 0.0, 2, 0.1, 0.0),

-- Loaded fries: ~280 cal/100g.
('theme_park_loaded_fries', 'Theme Park Loaded Fries', 280, 7.0, 28.0, 16.0,
 2.0, 1.0, 350, NULL,
 'theme_park', ARRAY['theme park loaded fries', 'amusement park cheese fries', 'carnival loaded fries'],
 'theme_park', 'Theme Park', 1, '280 cal/100g. ~980 cal per order (~350g). French fries topped with cheese, bacon, sour cream.', TRUE,
 750, 25, 7.0, 0.3, 400, 90, 1.0, 20, 5.0, 3, 22, 1.0, 130, 4.0, 0.02),

-- Chicken tenders basket: ~260 cal/100g.
('theme_park_chicken_tenders', 'Theme Park Chicken Tenders Basket', 260, 16.0, 18.0, 14.0,
 1.0, 0.5, 250, NULL,
 'theme_park', ARRAY['theme park chicken tenders', 'amusement park chicken tenders', 'carnival chicken strips'],
 'theme_park', 'Theme Park', 1, '260 cal/100g. ~650 cal per basket (~250g). Breaded chicken tenders with fries.', TRUE,
 600, 50, 3.5, 0.2, 220, 18, 1.2, 5, 2.0, 3, 20, 1.0, 160, 15.0, 0.02),

-- BBQ sandwich: ~210 cal/100g.
('theme_park_bbq_sandwich', 'Theme Park BBQ Sandwich', 210, 14.0, 18.0, 9.0,
 0.8, 8.0, 300, 300,
 'theme_park', ARRAY['theme park bbq sandwich', 'amusement park bbq', 'carnival bbq sandwich'],
 'theme_park', 'Theme Park', 1, '210 cal/100g. ~630 cal per sandwich (~300g). Pulled pork or chicken BBQ on bun.', TRUE,
 580, 55, 3.0, 0.1, 280, 30, 1.8, 8, 1.0, 5, 20, 2.5, 150, 18.0, 0.02),

-- Caramel apple: ~200 cal/100g.
('theme_park_caramel_apple', 'Theme Park Caramel Apple', 200, 0.5, 44.0, 3.5,
 1.5, 38.0, 280, 280,
 'theme_park', ARRAY['theme park caramel apple', 'carnival caramel apple', 'candy apple', 'fair caramel apple'],
 'theme_park', 'Theme Park', 1, '200 cal/100g. ~560 cal per apple (~280g). Apple coated in caramel with toppings.', TRUE,
 50, 5, 1.8, 0.0, 100, 20, 0.3, 3, 4.0, 0, 5, 0.1, 12, 0.5, 0.01),

-- Ice cream sandwich: ~240 cal/100g.
('theme_park_ice_cream_sandwich', 'Theme Park Ice Cream Sandwich', 240, 3.5, 36.0, 9.5,
 0.8, 22.0, 100, 100,
 'theme_park', ARRAY['theme park ice cream sandwich', 'amusement park ice cream sandwich'],
 'theme_park', 'Theme Park', 1, '240 cal/100g. ~240 cal per sandwich (~100g). Vanilla ice cream between chocolate wafers.', TRUE,
 150, 20, 5.0, 0.1, 120, 55, 0.8, 25, 0.0, 10, 10, 0.3, 60, 2.0, 0.01),

-- Churros: ~371 cal/100g.
('theme_park_churros', 'Theme Park Churros', 371, 5.0, 41.7, 20.0,
 1.7, 10.0, 100, 100,
 'theme_park', ARRAY['theme park churros', 'amusement park churros', 'carnival churros', 'fair churros'],
 'theme_park', 'Theme Park', 1, '371 cal/100g. ~371 cal per churro (~100g). Cinnamon sugar churros.', TRUE,
 220, 15, 5.0, 0.5, 60, 20, 1.2, 5, 0.0, 0, 10, 0.4, 45, 8.0, 0.01),

-- Walking taco: ~210 cal/100g.
('theme_park_walking_taco', 'Theme Park Walking Taco', 210, 9.0, 22.0, 10.0,
 2.5, 2.0, 250, NULL,
 'theme_park', ARRAY['theme park walking taco', 'carnival walking taco', 'fair taco in a bag', 'walking taco'],
 'theme_park', 'Theme Park', 1, '210 cal/100g. ~525 cal per bag (~250g). Chip bag with seasoned beef, cheese, salsa, lettuce.', TRUE,
 600, 30, 4.0, 0.2, 200, 80, 1.5, 25, 3.0, 3, 20, 2.0, 130, 8.0, 0.02),

-- Fried Oreos: ~370 cal/100g.
('theme_park_fried_oreos', 'Theme Park Fried Oreos', 370, 5.0, 46.0, 19.0,
 1.0, 25.0, 150, NULL,
 'theme_park', ARRAY['theme park fried oreos', 'carnival fried oreos', 'fair fried oreos', 'deep fried oreos'],
 'theme_park', 'Theme Park', 1, '370 cal/100g. ~555 cal per order (~150g, 5-6 pieces). Batter-dipped fried Oreo cookies.', TRUE,
 350, 15, 5.0, 0.5, 80, 30, 2.0, 5, 0.0, 3, 12, 0.4, 55, 6.0, 0.01),

-- Elephant ears: ~380 cal/100g.
('theme_park_elephant_ears', 'Theme Park Elephant Ears', 380, 5.0, 48.0, 19.0,
 0.8, 20.0, 150, 150,
 'theme_park', ARRAY['theme park elephant ears', 'carnival elephant ears', 'fair elephant ears', 'fried dough'],
 'theme_park', 'Theme Park', 1, '380 cal/100g. ~570 cal per piece (~150g). Flat fried dough with cinnamon sugar or toppings.', TRUE,
 280, 20, 5.0, 0.5, 55, 20, 1.5, 10, 0.0, 3, 10, 0.4, 50, 8.0, 0.01),

-- Kettle corn: ~420 cal/100g.
('theme_park_kettle_corn', 'Theme Park Kettle Corn', 420, 5.0, 68.0, 15.0,
 6.0, 25.0, 60, NULL,
 'theme_park', ARRAY['theme park kettle corn', 'carnival kettle corn', 'fair kettle corn', 'sweet popcorn'],
 'theme_park', 'Theme Park', 1, '420 cal/100g. ~252 cal per serving (~60g). Sweet and salty kettle-popped corn.', TRUE,
 300, 0, 2.0, 0.0, 100, 3, 1.5, 5, 0.0, 0, 30, 0.8, 90, 5.0, 0.01),

-- Snow cone: ~40 cal/100g.
('theme_park_snow_cone', 'Theme Park Snow Cone', 40, 0.0, 10.0, 0.0,
 0.0, 10.0, 350, NULL,
 'theme_park', ARRAY['theme park snow cone', 'carnival snow cone', 'fair snow cone', 'shaved ice', 'sno cone'],
 'theme_park', 'Theme Park', 1, '40 cal/100g. ~140 cal per cone (~350g). Shaved ice with flavored syrup.', TRUE,
 5, 0, 0.0, 0.0, 5, 2, 0.0, 0, 0.0, 0, 1, 0.0, 2, 0.1, 0.0),

-- ==========================================
-- ADDITIONAL DISNEY WORLD ITEMS
-- ==========================================

-- Spring roll (cheeseburger) - alias handled above, adding egg roll variant.
('disney_egg_roll_pepperoni', 'Disney Pepperoni Pizza Spring Roll', 285, 9.0, 26.0, 16.0,
 1.0, 3.0, 200, 65,
 'theme_park', ARRAY['disney pizza spring roll', 'disney pepperoni spring roll', 'adventureland pizza egg roll'],
 'theme_park', 'Disney World', 1, '285 cal/100g. ~570 cal per order (~200g, 3 rolls). Deep-fried pepperoni pizza filling.', TRUE,
 620, 30, 6.5, 0.3, 140, 90, 1.5, 20, 2.0, 3, 14, 1.2, 110, 12.0, 0.02),

-- Disney Tonga Toast (already added above), adding additional Disney items below.

-- Disney popcorn (caramel): ~430 cal/100g.
('disney_caramel_popcorn', 'Disney Caramel Popcorn', 430, 3.0, 72.0, 15.0,
 2.0, 45.0, 80, NULL,
 'theme_park', ARRAY['disney caramel popcorn', 'disney caramel corn', 'main street caramel corn'],
 'theme_park', 'Disney World', 1, '430 cal/100g. ~344 cal per serving (~80g). Caramel-coated popcorn.', TRUE,
 400, 5, 4.0, 0.1, 60, 15, 1.0, 5, 0.0, 0, 15, 0.5, 40, 3.0, 0.01),

-- ==========================================
-- ADDITIONAL UNIVERSAL ITEMS
-- ==========================================

-- Bumblebee's Tuna sandwich: ~195 cal/100g.
('universal_bumblebees_tuna', 'Universal Bumblebee''s Tuna Sandwich', 195, 12.0, 18.0, 8.0,
 1.0, 2.0, 280, 280,
 'theme_park', ARRAY['bumblebee''s tuna sandwich', 'universal tuna sandwich'],
 'theme_park', 'Universal Orlando', 1, '195 cal/100g. ~546 cal per sandwich (~280g). Tuna salad on toasted bread.', TRUE,
 520, 30, 1.5, 0.0, 180, 25, 1.2, 5, 1.0, 15, 22, 0.6, 140, 25.0, 0.15),

-- ==========================================
-- ADDITIONAL DOLLYWOOD ITEMS
-- ==========================================

-- Dollywood apple butter: ~170 cal/100g.
('dollywood_apple_butter', 'Dollywood Apple Butter', 170, 0.3, 42.0, 0.0,
 1.5, 35.0, 30, NULL,
 'theme_park', ARRAY['dollywood apple butter', 'smoky mountain apple butter'],
 'theme_park', 'Dollywood', 1, '170 cal/100g. ~51 cal per serving (~30g). Slow-cooked spiced apple butter spread.', TRUE,
 5, 0, 0.0, 0.0, 80, 5, 0.3, 5, 2.0, 0, 3, 0.0, 5, 0.2, 0.01),

-- ==========================================
-- ADDITIONAL GENERIC THEME PARK ITEMS
-- ==========================================

-- Fried Twinkie: ~330 cal/100g.
('theme_park_fried_twinkie', 'Theme Park Fried Twinkie', 330, 4.0, 42.0, 17.0,
 0.3, 25.0, 80, 80,
 'theme_park', ARRAY['fried twinkie', 'deep fried twinkie', 'carnival fried twinkie'],
 'theme_park', 'Theme Park', 1, '330 cal/100g. ~264 cal per piece (~80g). Batter-dipped deep-fried Twinkie.', TRUE,
 300, 20, 5.0, 0.5, 40, 15, 1.0, 5, 0.0, 2, 5, 0.2, 30, 4.0, 0.01),

-- Giant turkey drumstick (smoked, generic): alias for generic turkey leg.
('theme_park_smoked_drumstick', 'Theme Park Smoked Drumstick', 161, 20.0, 0.0, 8.5,
 0.0, 0.0, 680, 680,
 'theme_park', ARRAY['smoked drumstick', 'giant drumstick', 'smoked turkey drumstick'],
 'theme_park', 'Theme Park', 1, '161 cal/100g. ~1095 cal per leg (~680g). Large smoked turkey drumstick.', TRUE,
 780, 85, 2.8, 0.0, 280, 18, 1.5, 0, 0.0, 8, 24, 3.2, 195, 28.0, 0.04),

-- Theme park hot dog: ~250 cal/100g.
('theme_park_hot_dog', 'Theme Park Hot Dog', 250, 9.0, 22.0, 14.0,
 0.8, 3.0, 180, 180,
 'theme_park', ARRAY['theme park hot dog', 'amusement park hot dog', 'carnival hot dog', 'fair hot dog'],
 'theme_park', 'Theme Park', 1, '250 cal/100g. ~450 cal per hot dog (~180g). Classic all-beef hot dog on bun.', TRUE,
 780, 35, 5.5, 0.2, 150, 40, 2.0, 0, 0.5, 3, 12, 1.5, 100, 10.0, 0.02),

-- Theme park pizza slice: ~270 cal/100g.
('theme_park_pizza_slice', 'Theme Park Pizza Slice', 270, 11.0, 30.0, 12.0,
 1.5, 4.0, 180, 180,
 'theme_park', ARRAY['theme park pizza', 'amusement park pizza', 'carnival pizza', 'fair pizza slice'],
 'theme_park', 'Theme Park', 1, '270 cal/100g. ~486 cal per slice (~180g). Large cheese or pepperoni pizza slice.', TRUE,
 600, 25, 5.0, 0.2, 150, 180, 1.5, 50, 2.0, 5, 18, 1.2, 160, 15.0, 0.02),

-- Theme park nachos: ~240 cal/100g.
('theme_park_nachos', 'Theme Park Nachos', 240, 8.0, 24.0, 13.0,
 2.5, 2.0, 350, NULL,
 'theme_park', ARRAY['theme park nachos', 'amusement park nachos', 'carnival nachos'],
 'theme_park', 'Theme Park', 1, '240 cal/100g. ~840 cal per order (~350g). Tortilla chips with cheese, jalapenos, salsa.', TRUE,
 720, 25, 5.5, 0.3, 200, 120, 1.5, 30, 3.0, 3, 25, 1.5, 150, 6.0, 0.02),

-- Theme park cheeseburger: ~245 cal/100g.
('theme_park_cheeseburger', 'Theme Park Cheeseburger', 245, 13.0, 20.0, 13.0,
 1.0, 4.0, 280, 280,
 'theme_park', ARRAY['theme park burger', 'amusement park cheeseburger', 'carnival cheeseburger'],
 'theme_park', 'Theme Park', 1, '245 cal/100g. ~686 cal per burger (~280g). Standard cheeseburger with lettuce and tomato.', TRUE,
 650, 50, 5.5, 0.3, 200, 80, 2.5, 15, 1.0, 5, 20, 2.8, 150, 15.0, 0.03),

-- Theme park onion rings: ~330 cal/100g.
('theme_park_onion_rings', 'Theme Park Onion Rings', 330, 4.0, 38.0, 18.0,
 2.0, 5.0, 170, NULL,
 'theme_park', ARRAY['theme park onion rings', 'carnival onion rings', 'fair onion rings'],
 'theme_park', 'Theme Park', 1, '330 cal/100g. ~561 cal per order (~170g). Beer-battered deep-fried onion rings.', TRUE,
 500, 10, 4.5, 0.3, 120, 25, 1.0, 3, 2.0, 3, 10, 0.3, 40, 3.0, 0.01),

-- Theme park milkshake: ~190 cal/100g.
('theme_park_milkshake', 'Theme Park Milkshake', 190, 4.0, 28.0, 7.5,
 0.0, 24.0, 450, NULL,
 'theme_park', ARRAY['theme park milkshake', 'amusement park shake', 'carnival milkshake'],
 'theme_park', 'Theme Park', 1, '190 cal/100g. ~855 cal per shake (~450ml). Classic thick milkshake (vanilla, chocolate, strawberry).', TRUE,
 140, 30, 4.5, 0.1, 250, 120, 0.3, 40, 0.5, 20, 18, 0.5, 100, 3.0, 0.02),

-- Theme park Italian sausage: ~245 cal/100g.
('theme_park_italian_sausage', 'Theme Park Italian Sausage Sandwich', 245, 11.0, 18.0, 14.5,
 1.2, 3.0, 280, 280,
 'theme_park', ARRAY['theme park sausage', 'amusement park italian sausage', 'carnival sausage sandwich'],
 'theme_park', 'Theme Park', 1, '245 cal/100g. ~686 cal per sandwich (~280g). Italian sausage with peppers and onions.', TRUE,
 720, 50, 5.5, 0.1, 220, 25, 1.8, 15, 8.0, 3, 16, 2.0, 140, 14.0, 0.02),

-- Theme park waffle cone ice cream: ~230 cal/100g.
('theme_park_waffle_cone', 'Theme Park Waffle Cone Ice Cream', 230, 4.0, 32.0, 10.0,
 0.5, 22.0, 200, NULL,
 'theme_park', ARRAY['theme park ice cream cone', 'amusement park waffle cone', 'theme park soft serve'],
 'theme_park', 'Theme Park', 1, '230 cal/100g. ~460 cal per cone (~200g). Two scoops of ice cream in a waffle cone.', TRUE,
 80, 35, 6.0, 0.1, 170, 100, 0.5, 50, 0.5, 18, 15, 0.5, 90, 2.5, 0.02),

-- Theme park fried dough: ~380 cal/100g.
('theme_park_fried_dough', 'Theme Park Fried Dough', 380, 5.0, 46.0, 20.0,
 0.8, 18.0, 150, 150,
 'theme_park', ARRAY['fried dough', 'carnival fried dough', 'fair fried dough', 'zeppole'],
 'theme_park', 'Theme Park', 1, '380 cal/100g. ~570 cal per piece (~150g). Fried dough with powdered sugar or cinnamon.', TRUE,
 280, 20, 5.0, 0.5, 55, 20, 1.5, 10, 0.0, 3, 10, 0.4, 50, 8.0, 0.01),

-- Theme park chocolate dipped banana: ~180 cal/100g.
('theme_park_choc_banana', 'Theme Park Chocolate Dipped Banana', 180, 2.0, 28.0, 8.0,
 2.0, 20.0, 150, 150,
 'theme_park', ARRAY['chocolate banana', 'frozen chocolate banana', 'carnival chocolate banana'],
 'theme_park', 'Theme Park', 1, '180 cal/100g. ~270 cal per banana (~150g). Frozen banana dipped in chocolate with toppings.', TRUE,
 10, 3, 4.5, 0.0, 280, 15, 0.6, 3, 5.0, 0, 25, 0.4, 25, 1.0, 0.01),

-- Theme park soft serve: ~140 cal/100g.
('theme_park_soft_serve', 'Theme Park Soft Serve', 140, 3.0, 22.0, 4.5,
 0.0, 18.0, 150, NULL,
 'theme_park', ARRAY['theme park soft serve', 'soft serve ice cream', 'carnival soft serve'],
 'theme_park', 'Theme Park', 1, '140 cal/100g. ~210 cal per serving (~150g). Classic soft serve vanilla or chocolate.', TRUE,
 60, 15, 2.8, 0.1, 140, 80, 0.2, 30, 0.0, 12, 10, 0.4, 70, 2.0, 0.01),

-- Theme park deep fried pickles: ~240 cal/100g.
('theme_park_fried_pickles', 'Theme Park Deep Fried Pickles', 240, 5.0, 26.0, 13.0,
 1.5, 2.0, 150, NULL,
 'theme_park', ARRAY['fried pickles', 'deep fried pickles', 'carnival fried pickles'],
 'theme_park', 'Theme Park', 1, '240 cal/100g. ~360 cal per order (~150g). Batter-dipped fried dill pickle slices.', TRUE,
 900, 10, 2.5, 0.2, 80, 20, 1.0, 5, 1.0, 3, 8, 0.3, 30, 3.0, 0.01),

-- Theme park giant smoked sausage: ~300 cal/100g.
('theme_park_smoked_sausage', 'Theme Park Giant Smoked Sausage', 300, 12.0, 3.0, 27.0,
 0.0, 2.0, 200, 200,
 'theme_park', ARRAY['smoked sausage', 'giant smoked sausage', 'carnival sausage link'],
 'theme_park', 'Theme Park', 1, '300 cal/100g. ~600 cal per link (~200g). Large smoked sausage link on bun.', TRUE,
 900, 65, 10.0, 0.1, 250, 15, 1.5, 0, 1.0, 5, 16, 2.5, 140, 14.0, 0.02),

-- Theme park foot-long hot dog: ~250 cal/100g.
('theme_park_footlong_hotdog', 'Theme Park Foot-Long Hot Dog', 250, 9.0, 22.0, 14.0,
 0.8, 3.0, 250, 250,
 'theme_park', ARRAY['foot long hot dog', 'footlong hot dog', 'giant hot dog'],
 'theme_park', 'Theme Park', 1, '250 cal/100g. ~625 cal per foot-long (~250g). Extra-long all-beef frank on bun.', TRUE,
 780, 40, 5.5, 0.2, 160, 45, 2.0, 0, 0.5, 3, 14, 1.5, 110, 12.0, 0.02),

-- Theme park deep fried candy bar: ~400 cal/100g.
('theme_park_fried_candy_bar', 'Theme Park Deep Fried Candy Bar', 400, 4.0, 50.0, 21.0,
 0.8, 35.0, 100, 100,
 'theme_park', ARRAY['fried candy bar', 'deep fried snickers', 'deep fried candy bar', 'fried mars bar'],
 'theme_park', 'Theme Park', 1, '400 cal/100g. ~400 cal per piece (~100g). Batter-dipped deep-fried candy bar.', TRUE,
 180, 15, 8.0, 0.5, 130, 40, 1.0, 10, 0.0, 3, 15, 0.5, 50, 4.0, 0.02)

ON CONFLICT (food_name_normalized) DO NOTHING;
