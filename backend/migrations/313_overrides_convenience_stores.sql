-- 313_overrides_convenience_stores.sql
-- Convenience store food items from 7-Eleven, Wawa, Sheetz, QuikTrip, and Casey's.
-- Sources: fastfoodnutrition.org, nutritionix.com, calorieking.com, fatsecret.com,
--          eatthismuch.com, mynetdiary.com, official brand nutrition pages/PDFs.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════════════════════════════
-- 7-ELEVEN (12 items)
-- ══════════════════════════════════════════════════════════════════

-- 7-Eleven Big Bite Hot Dog (1/4 lb frank only): 360 cal per frank ~113g
-- 318 cal/100g. Sources: calorieking.com, nutritionix.com, eatthismuch.com
('7eleven_big_bite_hot_dog', '7-Eleven Big Bite Hot Dog (Frank Only)', 318, 9.7, 1.8, 30.1,
 0.0, 0.0, NULL, 113,
 '7eleven', ARRAY['7-eleven big bite', 'big bite hot dog', '7-11 hot dog', 'big bite frank', 'seven eleven hot dog'],
 'convenience_store', '7-Eleven', 1, '318 cal/100g. Frank ~113g = 360 cal. Quarter-pound all-beef hot dog frank only.', TRUE),

-- 7-Eleven Big Bite Hot Dog with Bun: 570 cal per sandwich ~170g
-- 335 cal/100g. Sources: myfooddiary.com, nutritionix.com
('7eleven_big_bite_hot_dog_with_bun', '7-Eleven Big Bite Hot Dog with Bun', 335, 10.9, 28.2, 19.4,
 1.2, 3.5, NULL, 170,
 '7eleven', ARRAY['7-eleven hot dog with bun', 'big bite with bun', '7-11 hot dog sandwich', '711 hot dog'],
 'convenience_store', '7-Eleven', 1, '335 cal/100g. Per hot dog ~170g = 570 cal. Quarter-pound frank in a bun.', TRUE),

-- 7-Eleven Monterey Jack & Chicken Taquito: 280 cal per taquito ~85g
-- 329 cal/100g. Sources: fastfoodnutrition.org, fatsecret.com
('7eleven_chicken_taquito', '7-Eleven Monterey Jack & Chicken Taquito', 329, 8.2, 35.3, 16.5,
 3.5, 1.2, NULL, 85,
 '7eleven', ARRAY['7-eleven chicken taquito', '7-11 chicken taquito', 'monterey jack chicken taquito', '711 chicken taquito'],
 'convenience_store', '7-Eleven', 1, '329 cal/100g. Per taquito ~85g = 280 cal. Crispy rolled tortilla with chicken and Monterey Jack cheese.', TRUE),

-- 7-Eleven Steak & Cheese Taquito: 210 cal per taquito ~85g
-- 247 cal/100g. Sources: fastfoodnutrition.org, fatsecret.com
('7eleven_steak_cheese_taquito', '7-Eleven Steak & Cheese Taquito', 247, 7.1, 25.9, 12.9,
 1.2, 1.2, NULL, 85,
 '7eleven', ARRAY['7-eleven steak taquito', '7-11 steak and cheese taquito', 'steak cheese taquito 7-eleven', '711 steak taquito'],
 'convenience_store', '7-Eleven', 1, '247 cal/100g. Per taquito ~85g = 210 cal. Crispy rolled tortilla with steak and cheese.', TRUE),

-- 7-Eleven Pepperoni Pizza Slice: 300 cal per slice ~120g
-- 250 cal/100g. Sources: fastfoodnutrition.org, fatsecret.com
('7eleven_pepperoni_pizza', '7-Eleven Pepperoni Pizza Slice', 250, 11.7, 25.0, 11.7,
 1.7, 1.7, NULL, 120,
 '7eleven', ARRAY['7-eleven pepperoni pizza', '7-11 pizza pepperoni', '7-eleven pizza slice pepperoni', '711 pepperoni pizza'],
 'convenience_store', '7-Eleven', 1, '250 cal/100g. Per slice ~120g = 300 cal. Grab-and-go pepperoni pizza slice.', TRUE),

-- 7-Eleven Cheese Pizza Slice: 290 cal per slice ~120g
-- 242 cal/100g. Sources: eatthismuch.com, fatsecret.com, mynetdiary.com
('7eleven_cheese_pizza', '7-Eleven Cheese Pizza Slice', 242, 11.7, 26.7, 10.0,
 1.7, 2.5, NULL, 120,
 '7eleven', ARRAY['7-eleven cheese pizza', '7-11 pizza cheese', '7-eleven pizza slice', '711 cheese pizza'],
 'convenience_store', '7-Eleven', 1, '242 cal/100g. Per slice ~120g = 290 cal. Grab-and-go cheese pizza slice.', TRUE),

-- 7-Eleven Slurpee Small (16 oz / 473ml): 130 cal
-- 28 cal/100g. Sources: calorieking.com, ibtimes.com, eatthismuch.com
('7eleven_slurpee_small', '7-Eleven Slurpee (Small, 16 oz)', 28, 0.0, 7.0, 0.0,
 0.0, 7.0, 473, NULL,
 '7eleven', ARRAY['slurpee small', '7-eleven slurpee 16oz', '7-11 slurpee', 'small slurpee'],
 'convenience_store', '7-Eleven', 1, '28 cal/100g. 16 oz (473ml) = ~130 cal. Frozen carbonated beverage. Flavor varies.', TRUE),

-- 7-Eleven Slurpee Large (30 oz / 887ml): ~244 cal
-- 28 cal/100g. Sources: calorieking.com, eatthismuch.com
('7eleven_slurpee_large', '7-Eleven Slurpee (Large, 30 oz)', 28, 0.0, 7.0, 0.0,
 0.0, 7.0, 887, NULL,
 '7eleven', ARRAY['slurpee large', '7-eleven slurpee 30oz', 'large slurpee', 'slurpee 30 oz'],
 'convenience_store', '7-Eleven', 1, '28 cal/100g. 30 oz (887ml) = ~244 cal. Frozen carbonated beverage. Flavor varies.', TRUE),

-- 7-Eleven Big Gulp (32 oz / 946ml Coca-Cola): ~312 cal
-- 33 cal/100g. Sources: fatsecret.com, fitia.app
('7eleven_big_gulp', '7-Eleven Big Gulp (32 oz)', 33, 0.0, 8.3, 0.0,
 0.0, 8.3, 946, NULL,
 '7eleven', ARRAY['big gulp', '7-eleven big gulp', '7-11 big gulp', 'big gulp 32oz'],
 'convenience_store', '7-Eleven', 1, '33 cal/100g. 32 oz (946ml) = ~312 cal. Fountain soda (Coca-Cola base).', TRUE),

-- 7-Eleven Buffalo Chicken Roller: 190 cal per roller ~85g (3 oz)
-- 224 cal/100g. Sources: fastfoodnutrition.org, calorieking.com, fatsecret.com
('7eleven_buffalo_chicken_roller', '7-Eleven Buffalo Chicken Roller', 224, 17.6, 18.8, 8.2,
 1.2, 2.4, NULL, 85,
 '7eleven', ARRAY['buffalo chicken roller', '7-eleven roller', '7-11 buffalo roller', 'chicken roller 7-eleven'],
 'convenience_store', '7-Eleven', 1, '224 cal/100g. Per roller ~85g = 190 cal. Roller grill item with buffalo chicken filling.', TRUE),

-- 7-Eleven Cheeseburger Bite: 440 cal per link ~119g
-- 370 cal/100g. Sources: fatsecret.com, fooducate.com, calorieking.com
('7eleven_cheeseburger_bite', '7-Eleven Cheeseburger Bite', 370, 17.6, 1.7, 31.9,
 0.0, 0.0, NULL, 119,
 '7eleven', ARRAY['cheeseburger bite', '7-eleven cheeseburger roller', '7-11 cheeseburger bite', 'roller grill cheeseburger'],
 'convenience_store', '7-Eleven', 1, '370 cal/100g. Per piece ~119g = 440 cal. Roller grill cheeseburger link.', TRUE),

-- 7-Eleven Chocolate Chunk Cookie: 250 cal per cookie ~57g
-- 439 cal/100g. Sources: fatsecret.com, nutritionix.com
('7eleven_chocolate_chunk_cookie', '7-Eleven Chocolate Chunk Cookie', 439, 4.4, 59.6, 21.1,
 1.8, 31.6, NULL, 57,
 '7eleven', ARRAY['7-eleven cookie', '7-11 chocolate chip cookie', '7-eleven chocolate cookie', '7-select cookie'],
 'convenience_store', '7-Eleven', 1, '439 cal/100g. Per cookie ~57g = 250 cal. Fresh-baked style chocolate chunk cookie.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- WAWA (11 items)
-- ══════════════════════════════════════════════════════════════════

-- Wawa Italian Hoagie (Shorti, 6"): 620 cal per sandwich ~250g
-- 248 cal/100g. Sources: carbmanager.com, calorieking.com
('wawa_italian_hoagie', 'Wawa Italian Hoagie (Shorti)', 248, 11.6, 21.2, 13.2,
 1.6, 2.4, NULL, 250,
 'wawa', ARRAY['wawa italian sub', 'wawa italian hoagie shorti', 'wawa italian sandwich', 'wawa cold italian'],
 'convenience_store', 'Wawa', 1, '248 cal/100g. Shorti ~250g = 620 cal. Ham, salami, pepperoni, provolone on a shorti roll.', TRUE),

-- Wawa Turkey Hoagie (Shorti): 500 cal per sandwich ~250g
-- 200 cal/100g. Sources: calorieking.com, eatthismuch.com
('wawa_turkey_hoagie', 'Wawa Turkey Hoagie (Shorti)', 200, 10.4, 18.0, 8.8,
 1.2, 2.0, NULL, 250,
 'wawa', ARRAY['wawa turkey sub', 'wawa turkey hoagie shorti', 'wawa oven roasted turkey hoagie'],
 'convenience_store', 'Wawa', 1, '200 cal/100g. Shorti ~250g = 500 cal. Oven roasted turkey on a shorti roll.', TRUE),

-- Wawa Meatball Hoagie (Shorti): 720 cal per sandwich ~300g
-- 240 cal/100g. Sources: calorieking.com, fatsecret.com
('wawa_meatball_hoagie', 'Wawa Meatball Hoagie (Shorti)', 240, 12.0, 21.3, 12.0,
 1.7, 4.3, NULL, 300,
 'wawa', ARRAY['wawa meatball sub', 'wawa meatball marinara hoagie', 'wawa meatball sandwich'],
 'convenience_store', 'Wawa', 1, '240 cal/100g. Shorti ~300g = 720 cal. Meatballs with marinara sauce on a shorti roll.', TRUE),

-- Wawa Mac & Cheese (Small): 350 cal per serving 198g
-- 177 cal/100g. Sources: fastfoodnutrition.org, nutritionix.com
('wawa_mac_and_cheese', 'Wawa Mac & Cheese (Small)', 177, 7.6, 17.2, 8.6,
 0.5, 2.5, 198, NULL,
 'wawa', ARRAY['wawa macaroni and cheese', 'wawa mac n cheese', 'wawa mac & cheese side'],
 'convenience_store', 'Wawa', 1, '177 cal/100g. Small serving 198g = 350 cal. Creamy elbow macaroni with cheese sauce.', TRUE),

-- Wawa Sizzli Sausage Egg & Cheese Bagel: 550 cal per sandwich 198g
-- 278 cal/100g. Sources: calorieking.com, fatsecret.com
('wawa_sizzli_sausage_egg_cheese_bagel', 'Wawa Sizzli Sausage, Egg & Cheese Bagel', 278, 10.1, 21.2, 14.6,
 1.5, 3.5, NULL, 198,
 'wawa', ARRAY['wawa sizzli bagel', 'wawa sausage egg cheese bagel', 'sizzli breakfast bagel'],
 'convenience_store', 'Wawa', 1, '278 cal/100g. Per sandwich 198g = 550 cal. Sausage patty, egg, cheese on a bagel.', TRUE),

-- Wawa Sizzli Sausage Egg & Cheese Croissant: 520 cal per sandwich ~170g
-- 306 cal/100g. Sources: calorieking.com, carbmanager.com
('wawa_sizzli_sausage_egg_cheese_croissant', 'Wawa Sizzli Sausage, Egg & Cheese Croissant', 306, 10.6, 15.9, 22.9,
 0.6, 2.4, NULL, 170,
 'wawa', ARRAY['wawa sizzli croissant', 'wawa sausage egg cheese croissant', 'sizzli breakfast croissant'],
 'convenience_store', 'Wawa', 1, '306 cal/100g. Per sandwich ~170g = 520 cal. Sausage patty, egg, cheese on a croissant.', TRUE),

-- Wawa Sizzli Bacon Egg & Cheese Croissant: 440 cal per sandwich 143g
-- 308 cal/100g. Sources: calorieking.com, fatsecret.com
('wawa_sizzli_bacon_egg_cheese_croissant', 'Wawa Sizzli Bacon, Egg & Cheese Croissant', 308, 12.6, 18.2, 18.9,
 0.7, 2.1, NULL, 143,
 'wawa', ARRAY['wawa bacon egg cheese croissant', 'wawa sizzli bacon croissant', 'bacon sizzli wawa'],
 'convenience_store', 'Wawa', 1, '308 cal/100g. Per sandwich 143g = 440 cal. Bacon, egg, cheese on a buttery croissant.', TRUE),

-- Wawa Gobbler (Shorti): 480 cal per sandwich ~250g
-- 192 cal/100g. Sources: fatsecret.com, mynetdiary.com
('wawa_gobbler', 'Wawa Gobbler Hoagie (Shorti)', 192, 7.2, 24.0, 7.6,
 1.6, 6.0, NULL, 250,
 'wawa', ARRAY['wawa turkey gobbler', 'wawa gobbler sub', 'wawa thanksgiving hoagie', 'gobbler hoagie'],
 'convenience_store', 'Wawa', 1, '192 cal/100g. Shorti ~250g = 480 cal. Turkey, stuffing, cranberry sauce, gravy on a shorti roll.', TRUE),

-- Wawa Soft Pretzel: 330 cal per pretzel 128g
-- 258 cal/100g. Sources: fastfoodnutrition.org, calorieking.com, fatsecret.com
('wawa_soft_pretzel', 'Wawa Soft Pretzel', 258, 9.4, 50.8, 2.7,
 3.1, 1.6, NULL, 128,
 'wawa', ARRAY['wawa pretzel', 'wawa salted pretzel', 'soft pretzel wawa'],
 'convenience_store', 'Wawa', 1, '258 cal/100g. Per pretzel 128g = 330 cal. Classic soft pretzel with salt.', TRUE),

-- Wawa Strawberry Banana Smoothie (16 oz): 450 cal per 16oz ~473g
-- 95 cal/100g. Sources: calorieking.com, fastfoodnutrition.org
('wawa_strawberry_banana_smoothie', 'Wawa Strawberry Banana Smoothie (16 oz)', 95, 0.2, 24.3, 0.0,
 1.5, 22.0, 473, NULL,
 'wawa', ARRAY['wawa smoothie', 'wawa fruit smoothie', 'wawa strawberry smoothie', 'wawa banana smoothie'],
 'convenience_store', 'Wawa', 1, '95 cal/100g. 16 oz (473ml) = 450 cal. Blended fruit smoothie with strawberry and banana.', TRUE),

-- Wawa Chicken Noodle Soup (Medium): 180 cal per medium ~325g
-- 55 cal/100g. Sources: fastfoodnutrition.org, calorieking.com
('wawa_chicken_noodle_soup', 'Wawa Chicken Noodle Soup (Medium)', 55, 3.7, 6.5, 1.8,
 0.3, 0.6, 325, NULL,
 'wawa', ARRAY['wawa chicken soup', 'wawa chicken noodle', 'wawa soup'],
 'convenience_store', 'Wawa', 1, '55 cal/100g. Medium ~325g = 180 cal. Classic chicken noodle soup.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- SHEETZ (10 items)
-- ══════════════════════════════════════════════════════════════════

-- Sheetz MTO Italian Sub (6" on white roll, base): 350 cal per sub ~200g
-- 175 cal/100g. Sources: eatthismuch.com, mynetdiary.com
('sheetz_mto_italian_sub', 'Sheetz MTO Italian Cold Sub (6")', 175, 10.5, 24.5, 3.5,
 1.5, 2.0, NULL, 200,
 'sheetz', ARRAY['sheetz italian sub', 'sheetz mto sub italian', 'sheetz cold sub'],
 'convenience_store', 'Sheetz', 1, '175 cal/100g. 6-inch sub ~200g = 350 cal. Italian cold cut sub on white roll (base, no extras).', TRUE),

-- Sheetz MTO Steak & Cheese Hoagie: 400 cal per sub ~200g
-- 200 cal/100g. Sources: mynetdiary.com, sheetz.com
('sheetz_mto_steak_cheese', 'Sheetz MTO Steak & Cheese Hoagie', 200, 11.5, 24.0, 6.0,
 1.0, 2.5, NULL, 200,
 'sheetz', ARRAY['sheetz steak and cheese', 'sheetz cheesesteak', 'sheetz philly cheesesteak', 'sheetz steak sub'],
 'convenience_store', 'Sheetz', 1, '200 cal/100g. Per sub ~200g = 400 cal. Shaved steak with melted cheese on a sub roll.', TRUE),

-- Sheetz Boom Boom Shrimp: 220 cal per order ~113g
-- 195 cal/100g. Sources: nutritionvalue.org, sheetz.com
('sheetz_boom_boom_shrimp', 'Sheetz Boom Boom Shrimp', 195, 12.4, 16.8, 8.8,
 0.9, 1.8, 113, NULL,
 'sheetz', ARRAY['sheetz shrimp', 'boom boom shrimp sheetz', 'sheetz fried shrimp'],
 'convenience_store', 'Sheetz', 1, '195 cal/100g. Serving ~113g = 220 cal. Crispy breaded shrimp with spicy boom boom sauce.', TRUE),

-- Sheetz Fried Pickles (Regular): 224 cal per order ~96g
-- 233 cal/100g. Sources: fastfoodnutrition.org, calorieking.com
('sheetz_fried_pickles', 'Sheetz Fried Pickles (Regular)', 233, 3.1, 24.0, 14.0,
 2.1, 0.0, 96, NULL,
 'sheetz', ARRAY['sheetz fried pickle chips', 'fried pickles sheetz', 'sheetz pickle chips'],
 'convenience_store', 'Sheetz', 1, '233 cal/100g. Regular order ~96g = 224 cal. Battered and fried pickle chips.', TRUE),

-- Sheetz Turkey Pretzel Meltz: 694 cal per melt ~300g
-- 231 cal/100g. Sources: fatsecret.com, myfooddiary.com
('sheetz_pretzel_meltz_turkey', 'Sheetz Turkey Pretzel Meltz', 231, 10.7, 28.3, 8.3,
 1.3, 2.7, NULL, 300,
 'sheetz', ARRAY['sheetz pretzel melt turkey', 'turkey pretzel meltz', 'sheetz pretzel sub turkey'],
 'convenience_store', 'Sheetz', 1, '231 cal/100g. Per melt ~300g = 694 cal. Turkey and cheese on a pretzel roll, toasted.', TRUE),

-- Sheetz Mac & Cheese Bites: 371 cal per order 128g (4.5 oz)
-- 290 cal/100g. Sources: fastfoodnutrition.org, calorieking.com
('sheetz_mac_cheese_bites', 'Sheetz Mac & Cheese Bites', 290, 7.0, 31.3, 15.1,
 1.6, 2.3, 128, NULL,
 'sheetz', ARRAY['sheetz mac n cheese bites', 'mac and cheese bites sheetz', 'sheetz mac bites'],
 'convenience_store', 'Sheetz', 1, '290 cal/100g. Per order 128g = 371 cal. Breaded and fried mac and cheese bites.', TRUE),

-- Sheetz Crispy Chicken Strips (3 piece): 328 cal per 3-piece ~150g
-- 219 cal/100g. Sources: fastfoodnutrition.org, carbmanager.com
('sheetz_crispy_chicken_strips', 'Sheetz Crispy Chicken Strips (3 Piece)', 219, 13.3, 26.0, 7.1,
 0.7, 0.7, NULL, 150,
 'sheetz', ARRAY['sheetz chicken strips', 'sheetz chicken tenders', 'sheetz chicken stripz', 'sheetz crispy chicken'],
 'convenience_store', 'Sheetz', 1, '219 cal/100g. 3-piece order ~150g = 328 cal. Breaded and fried chicken tenders.', TRUE),

-- Sheetz Mozzarella Sticks: 410 cal per order 153g (5.4 oz)
-- 268 cal/100g. Sources: calorieking.com, fastfoodnutrition.org
('sheetz_mozzarella_sticks', 'Sheetz Mozzarella Cheese Sticks', 268, 11.8, 26.8, 13.1,
 1.3, 2.0, 153, NULL,
 'sheetz', ARRAY['sheetz mozz sticks', 'mozzarella sticks sheetz', 'sheetz cheese sticks'],
 'convenience_store', 'Sheetz', 1, '268 cal/100g. Per order 153g = 410 cal. Breaded and fried mozzarella sticks.', TRUE),

-- Sheetz Soft Pretzel: 280 cal per pretzel ~115g
-- 243 cal/100g. Sources: mynetdiary.com, fatsecret.com
('sheetz_soft_pretzel', 'Sheetz Soft Pretzel', 243, 8.7, 47.0, 3.5,
 1.7, 1.7, NULL, 115,
 'sheetz', ARRAY['sheetz pretzel', 'sheetz salted pretzel', 'soft pretzel sheetz'],
 'convenience_store', 'Sheetz', 1, '243 cal/100g. Per pretzel ~115g = 280 cal. Classic soft pretzel with salt.', TRUE),

-- Sheetz MTO Burger: 440 cal per burger ~180g
-- 244 cal/100g. Sources: eatthismuch.com, fastfoodnutrition.org
('sheetz_mto_burger', 'Sheetz MTO Burger', 244, 20.0, 17.8, 11.1,
 1.0, 3.0, NULL, 180,
 'sheetz', ARRAY['sheetz burger', 'sheetz mto cheeseburger', 'sheetz hamburger'],
 'convenience_store', 'Sheetz', 1, '244 cal/100g. Per burger ~180g = 440 cal. Made-to-order burger on a bun.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- QUIKTRIP (10 items)
-- ══════════════════════════════════════════════════════════════════

-- QuikTrip Spicy Chicken Taquito: 270 cal per taquito 113g
-- 239 cal/100g. Sources: fatsecret.com, eatthismuch.com, quiktrip.com
('quiktrip_spicy_chicken_taquito', 'QuikTrip Spicy Chicken Taquito', 239, 12.4, 31.0, 7.1,
 1.8, 1.8, NULL, 113,
 'quiktrip', ARRAY['qt chicken taquito', 'quiktrip taquito chicken', 'qt spicy taquito', 'qt kitchens taquito'],
 'convenience_store', 'QuikTrip', 1, '239 cal/100g. Per taquito 113g = 270 cal. Spicy chicken-filled crispy taquito.', TRUE),

-- QuikTrip Steak & Cheese Taquito: 240 cal per taquito 106g
-- 226 cal/100g. Sources: fatsecret.com, eatthismuch.com
('quiktrip_steak_cheese_taquito', 'QuikTrip Steak & Cheese Taquito', 226, 9.4, 29.2, 8.5,
 1.9, 0.9, NULL, 106,
 'quiktrip', ARRAY['qt steak taquito', 'quiktrip steak and cheese taquito', 'qt kitchens steak taquito'],
 'convenience_store', 'QuikTrip', 1, '226 cal/100g. Per taquito 106g = 240 cal. Steak and cheese filled crispy taquito.', TRUE),

-- QuikTrip Pepperoni Pizza Slice: 410 cal per slice 167g
-- 245 cal/100g. Sources: fatsecret.com, eatthismuch.com, mynetdiary.com
('quiktrip_pepperoni_pizza', 'QuikTrip Pepperoni Pizza Slice', 245, 10.2, 28.1, 10.2,
 1.8, 3.0, NULL, 167,
 'quiktrip', ARRAY['qt pepperoni pizza', 'quiktrip pizza pepperoni', 'qt kitchens pizza pepperoni'],
 'convenience_store', 'QuikTrip', 1, '245 cal/100g. Per slice 167g = 410 cal. QT Kitchens hand-tossed pepperoni pizza.', TRUE),

-- QuikTrip Cheese Pizza Slice: 350 cal per slice 154g
-- 227 cal/100g. Sources: quiktrip.com official PDF, mynetdiary.com
('quiktrip_cheese_pizza', 'QuikTrip Cheese Pizza Slice', 227, 9.7, 30.5, 7.8,
 1.9, 3.2, NULL, 154,
 'quiktrip', ARRAY['qt cheese pizza', 'quiktrip pizza cheese', 'qt kitchens pizza cheese'],
 'convenience_store', 'QuikTrip', 1, '227 cal/100g. Per slice 154g = 350 cal. QT Kitchens hand-tossed cheese pizza.', TRUE),

-- QuikTrip Breakfast Pizza Slice: 510 cal per slice 198g
-- 258 cal/100g. Sources: eatthismuch.com, mynetdiary.com, quiktrip.com
('quiktrip_breakfast_pizza', 'QuikTrip Breakfast Pizza Slice', 258, 11.1, 24.2, 13.1,
 1.0, 2.5, NULL, 198,
 'quiktrip', ARRAY['qt breakfast pizza', 'quiktrip breakfast pizza slice', 'qt kitchens breakfast pizza'],
 'convenience_store', 'QuikTrip', 1, '258 cal/100g. Per slice 198g = 510 cal. Sausage gravy, scrambled eggs, sausage, bacon, cheddar jack.', TRUE),

-- QuikTrip Sausage Egg & Cheese Croissant: 590 cal per sandwich 192g
-- 307 cal/100g. Sources: fatsecret.com, mynetdiary.com
('quiktrip_sausage_egg_cheese_croissant', 'QuikTrip Sausage, Egg & Cheese Croissant', 307, 9.4, 14.6, 24.0,
 0.5, 2.6, NULL, 192,
 'quiktrip', ARRAY['qt breakfast croissant', 'quiktrip sausage croissant', 'qt sausage egg cheese'],
 'convenience_store', 'QuikTrip', 1, '307 cal/100g. Per sandwich 192g = 590 cal. Sausage, egg, cheese on a flaky croissant.', TRUE),

-- QuikTrip Buffalo Chicken Roller: 190 cal per roller ~85g
-- 224 cal/100g. Sources: eatthismuch.com, carbmanager.com
('quiktrip_buffalo_chicken_roller', 'QuikTrip Buffalo Chicken Roller', 224, 17.6, 18.8, 8.2,
 1.2, 2.4, NULL, 85,
 'quiktrip', ARRAY['qt buffalo chicken roller', 'qt roller grill buffalo chicken', 'quiktrip roller'],
 'convenience_store', 'QuikTrip', 1, '224 cal/100g. Per roller ~85g = 190 cal. Roller grill buffalo chicken item.', TRUE),

-- QuikTrip Sausage Biscuit: 460 cal per biscuit ~150g
-- 307 cal/100g. Sources: eatthismuch.com, fatsecret.com
('quiktrip_sausage_biscuit', 'QuikTrip Sausage Biscuit', 307, 6.7, 28.0, 18.7,
 0.7, 3.3, NULL, 150,
 'quiktrip', ARRAY['qt sausage biscuit', 'quiktrip breakfast biscuit', 'qt kitchens sausage biscuit'],
 'convenience_store', 'QuikTrip', 1, '307 cal/100g. Per biscuit ~150g = 460 cal. Sausage patty in a buttermilk biscuit.', TRUE),

-- QuikTrip Jalapeno Cheddar Smoked Sausage: 260 cal per link 91g
-- 286 cal/100g. Sources: fatsecret.com, quiktrip.com
('quiktrip_jalapeno_cheddar_sausage', 'QuikTrip Jalapeno Cheddar Smoked Sausage', 286, 13.2, 1.1, 29.0,
 0.0, 0.5, NULL, 91,
 'quiktrip', ARRAY['qt jalapeno sausage', 'quiktrip smoked sausage', 'qt roller grill sausage'],
 'convenience_store', 'QuikTrip', 1, '286 cal/100g. Per link 91g = 260 cal. Smoked sausage with jalapeno and cheddar on roller grill.', TRUE),

-- QuikTrip Chicken & Cheese Flatbread: 410 cal per flatbread 155g
-- 265 cal/100g. Sources: quiktrip.com official PDF
('quiktrip_chicken_cheese_flatbread', 'QuikTrip Chicken & Cheese Flatbread', 265, 14.2, 25.8, 11.6,
 1.3, 2.6, NULL, 155,
 'quiktrip', ARRAY['qt chicken flatbread', 'quiktrip flatbread', 'qt kitchens flatbread'],
 'convenience_store', 'QuikTrip', 1, '265 cal/100g. Per flatbread 155g = 410 cal. QT Kitchens chicken and cheese flatbread.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- CASEY'S (11 items)
-- ══════════════════════════════════════════════════════════════════

-- Casey's Cheese Pizza (Large, per slice 1/12): 210 cal per slice ~100g
-- 210 cal/100g. Sources: calorieking.com, fastfoodnutrition.org
('caseys_cheese_pizza', 'Casey''s Cheese Pizza (Large, per slice)', 210, 10.0, 28.0, 9.0,
 1.0, 2.0, NULL, 100,
 'caseys', ARRAY['casey''s cheese pizza slice', 'caseys pizza cheese', 'casey''s large cheese pizza slice'],
 'convenience_store', 'Casey''s', 1, '210 cal/100g. Per large slice (1/12) ~100g = 210 cal. Hand-made cheese pizza on original crust.', TRUE),

-- Casey's Pepperoni Pizza (Large, per slice 1/12): 267 cal per slice ~110g
-- 243 cal/100g. Sources: mynetdiary.com, fastfoodnutrition.org
('caseys_pepperoni_pizza', 'Casey''s Pepperoni Pizza (Large, per slice)', 243, 10.9, 30.0, 10.9,
 1.8, 2.7, NULL, 110,
 'caseys', ARRAY['casey''s pepperoni pizza slice', 'caseys pizza pepperoni', 'casey''s large pepperoni pizza'],
 'convenience_store', 'Casey''s', 1, '243 cal/100g. Per large slice (1/12) ~110g = 267 cal. Classic pepperoni pizza on original crust.', TRUE),

-- Casey's Sausage Pizza (Large, per slice 1/12): 296 cal per slice ~115g
-- 257 cal/100g. Sources: mynetdiary.com, eatthismuch.com
('caseys_sausage_pizza', 'Casey''s Sausage Pizza (Large, per slice)', 257, 11.3, 28.7, 11.3,
 1.7, 2.6, NULL, 115,
 'caseys', ARRAY['casey''s sausage pizza slice', 'caseys pizza sausage', 'casey''s large sausage pizza'],
 'convenience_store', 'Casey''s', 1, '257 cal/100g. Per large slice (1/12) ~115g = 296 cal. Italian sausage pizza on original crust.', TRUE),

-- Casey's Supreme Pizza (Large, per slice 1/12): 312 cal per slice ~120g
-- 260 cal/100g. Sources: fastfoodnutrition.org, calorieking.com
('caseys_supreme_pizza', 'Casey''s Supreme Pizza (Large, per slice)', 260, 13.3, 28.3, 11.7,
 1.7, 3.3, NULL, 120,
 'caseys', ARRAY['casey''s supreme pizza slice', 'caseys pizza supreme', 'casey''s large supreme pizza'],
 'convenience_store', 'Casey''s', 1, '260 cal/100g. Per large slice (1/12) ~120g = 312 cal. Pepperoni, sausage, onion, green pepper, mushroom.', TRUE),

-- Casey's Taco Pizza (Large, per slice 1/12): 377 cal per slice ~140g
-- 269 cal/100g. Sources: fastfoodnutrition.org, calorieking.com, fatsecret.com
('caseys_taco_pizza', 'Casey''s Taco Pizza (Large, per slice)', 269, 11.4, 30.7, 12.1,
 2.1, 2.9, NULL, 140,
 'caseys', ARRAY['casey''s taco pizza slice', 'caseys pizza taco', 'casey''s large taco pizza'],
 'convenience_store', 'Casey''s', 1, '269 cal/100g. Per large slice (1/12) ~140g = 377 cal. Taco seasoned beef, lettuce, tomato, cheese, taco sauce.', TRUE),

-- Casey's Breakfast Pizza Sausage (Large, per slice 1/12): 320 cal per slice ~130g
-- 246 cal/100g. Sources: fastfoodnutrition.org, mynetdiary.com
('caseys_breakfast_pizza', 'Casey''s Sausage Breakfast Pizza (Large, per slice)', 246, 11.5, 25.4, 11.5,
 0.8, 2.3, NULL, 130,
 'caseys', ARRAY['casey''s breakfast pizza slice', 'caseys sausage breakfast pizza', 'casey''s morning pizza'],
 'convenience_store', 'Casey''s', 1, '246 cal/100g. Per large slice (1/12) ~130g = 320 cal. Scrambled eggs, sausage, cheese on pizza crust.', TRUE),

-- Casey's Bacon Breakfast Pizza (Large, per slice 1/12): 310 cal per slice ~130g
-- 238 cal/100g. Sources: carbmanager.com, fastfoodnutrition.org
('caseys_bacon_breakfast_pizza', 'Casey''s Bacon Breakfast Pizza (Large, per slice)', 238, 10.0, 24.6, 10.8,
 0.8, 2.3, NULL, 130,
 'caseys', ARRAY['casey''s bacon breakfast pizza slice', 'caseys bacon breakfast pizza'],
 'convenience_store', 'Casey''s', 1, '238 cal/100g. Per large slice (1/12) ~130g = 310 cal. Scrambled eggs, bacon, cheese on pizza crust.', TRUE),

-- Casey's Glazed Donut: 260 cal per donut ~65g
-- 400 cal/100g. Sources: fastfoodnutrition.org, mynetdiary.com
('caseys_glazed_donut', 'Casey''s Glazed Donut', 400, 7.7, 47.7, 20.0,
 1.5, 15.4, NULL, 65,
 'caseys', ARRAY['casey''s donut glazed', 'caseys glazed doughnut', 'casey''s yeast donut'],
 'convenience_store', 'Casey''s', 1, '400 cal/100g. Per donut ~65g = 260 cal. Classic yeast-raised glazed donut.', TRUE),

-- Casey's Chocolate Cake Donut: 230 cal per donut ~60g
-- 383 cal/100g. Sources: fastfoodnutrition.org, fitia.app
('caseys_chocolate_cake_donut', 'Casey''s Chocolate Cake Donut', 383, 5.0, 38.3, 23.3,
 1.7, 18.3, NULL, 60,
 'caseys', ARRAY['casey''s chocolate donut', 'caseys cake donut chocolate', 'casey''s chocolate iced donut'],
 'convenience_store', 'Casey''s', 1, '383 cal/100g. Per donut ~60g = 230 cal. Rich chocolate-iced cake donut.', TRUE),

-- Casey's Apple Fritter: 420 cal per fritter ~120g
-- 350 cal/100g. Sources: fastfoodnutrition.org, calorieking.com
('caseys_apple_fritter', 'Casey''s Apple Fritter', 350, 4.2, 45.8, 17.5,
 1.7, 20.0, NULL, 120,
 'caseys', ARRAY['casey''s fritter', 'caseys apple fritter donut', 'casey''s fritter pastry'],
 'convenience_store', 'Casey''s', 1, '350 cal/100g. Per fritter ~120g = 420 cal. Fried dough with apple pieces and glaze.', TRUE),

-- Casey's Cheese Breadsticks (Full Order): 810 cal per order ~330g
-- 245 cal/100g. Sources: calorieking.com, fastfoodnutrition.org
('caseys_cheese_breadsticks', 'Casey''s Cheese Breadsticks (Full Order)', 245, 9.7, 27.3, 12.4,
 1.0, 3.0, 330, NULL,
 'caseys', ARRAY['casey''s breadsticks', 'caseys cheesy breadsticks', 'casey''s cheese sticks'],
 'convenience_store', 'Casey''s', 1, '245 cal/100g. Full order ~330g = 810 cal. Baked breadsticks topped with melted cheese blend.', TRUE)

ON CONFLICT (food_name_normalized)
DO UPDATE SET
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
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
