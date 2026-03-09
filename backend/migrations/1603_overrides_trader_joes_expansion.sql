-- 1603_overrides_trader_joes_expansion.sql
-- Trader Joe's — frozen entrees, chicken sausages, snacks, spreads, desserts.
-- Expands existing 4 items (orange chicken, cauliflower gnocchi, tikka masala, butter chicken).
-- Sources: FatSecret, EatThisMuch, MyNetDiary, traderjoes.com.
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- TRADER JOE'S — FROZEN ENTREES
-- ══════════════════════════════════════════

-- Trader Joe's Chicken Tikka Masala w/ Basmati Rice: 290 cal per cup (227g)
('tj_chicken_tikka_masala', 'Trader Joe''s Chicken Tikka Masala w/ Basmati Rice', 127.8, 7.9, 15.9, 4.0,
 0.9, 1.3, 227, NULL,
 'manufacturer', ARRAY['trader joes chicken tikka masala', 'tj chicken tikka masala', 'trader joes tikka masala', 'trader joe''s chicken tikka masala', 'tj tikka masala'],
 'frozen_meals', 'Trader Joe''s', 1, '290 cal per cup (227g). Chicken tikka masala with basmati rice. Package contains ~2 servings.', TRUE),

-- Trader Joe's Mandarin Orange Chicken: 320 cal per cup (163g)
('tj_mandarin_orange_chicken', 'Trader Joe''s Mandarin Orange Chicken', 196.3, 13.5, 21.5, 6.1,
 0.6, 3.7, 163, NULL,
 'manufacturer', ARRAY['trader joes orange chicken', 'tj orange chicken', 'trader joes mandarin orange chicken', 'trader joe''s mandarin orange chicken', 'tj mandarin chicken'],
 'frozen_meals', 'Trader Joe''s', 1, '320 cal per cup (163g). Crispy tempura chicken in sweet mandarin orange sauce. Top-selling TJ''s item.', TRUE),

-- Trader Joe's Butter Chicken w/ Basmati Rice: 400 cal per package (354g)
('tj_butter_chicken', 'Trader Joe''s Butter Chicken w/ Basmati Rice', 113.0, 6.8, 13.8, 3.7,
 0.6, 0.8, 354, NULL,
 'manufacturer', ARRAY['trader joes butter chicken', 'tj butter chicken', 'trader joes butter chicken rice', 'trader joe''s butter chicken', 'tj butter chicken basmati'],
 'frozen_meals', 'Trader Joe''s', 1, '400 cal per full package (354g). Butter chicken with basmati rice.', TRUE),

-- Trader Joe's Chana Masala: 180 cal per half package (142g)
('tj_chana_masala', 'Trader Joe''s Chana Masala', 126.8, 4.2, 15.5, 6.3,
 4.9, 2.1, 142, NULL,
 'manufacturer', ARRAY['trader joes chana masala', 'tj chana masala', 'trader joes chickpea curry', 'trader joe''s chana masala', 'tj chickpea masala'],
 'frozen_meals', 'Trader Joe''s', 1, '180 cal per half package (142g). Indian-style chickpea curry. Vegan.', TRUE),

-- Trader Joe's Palak Paneer: 210 cal per half package (142g)
('tj_palak_paneer', 'Trader Joe''s Palak Paneer', 147.9, 7.0, 6.3, 11.3,
 2.8, 2.1, 142, NULL,
 'manufacturer', ARRAY['trader joes palak paneer', 'tj palak paneer', 'trader joes spinach paneer', 'trader joe''s palak paneer', 'tj saag paneer'],
 'frozen_meals', 'Trader Joe''s', 1, '210 cal per half package (142g). Creamy spinach with paneer cheese. Vegetarian.', TRUE),

-- Trader Joe's Japanese Style Fried Rice: 340 cal per 1.5 cups (180g)
('tj_japanese_fried_rice', 'Trader Joe''s Japanese Style Fried Rice', 188.9, 5.0, 32.2, 3.9,
 1.7, 0.0, 180, NULL,
 'manufacturer', ARRAY['trader joes japanese fried rice', 'tj fried rice', 'trader joes fried rice', 'trader joe''s japanese fried rice', 'tj japanese rice'],
 'frozen_meals', 'Trader Joe''s', 1, '340 cal per 1.5 cups (180g). Japanese-style fried rice with edamame, tofu, vegetables.', TRUE),

-- Trader Joe's Chicken Gyoza Potstickers: 200 cal per 7 pcs (~140g)
('tj_chicken_gyoza', 'Trader Joe''s Chicken Gyoza Potstickers', 142.9, 7.1, 21.4, 3.2,
 2.9, 0.0, 140, NULL,
 'manufacturer', ARRAY['trader joes chicken gyoza', 'tj gyoza', 'trader joes potstickers', 'trader joe''s chicken gyoza', 'tj chicken potstickers'],
 'frozen_meals', 'Trader Joe''s', 1, '200 cal per 7 pieces (~140g). Japanese-style chicken potstickers/gyoza.', TRUE),

-- Trader Joe's Reduced Guilt Mac & Cheese: 270 cal per container (198g)
('tj_reduced_guilt_mac_cheese', 'Trader Joe''s Reduced Guilt Mac & Cheese', 136.4, 7.6, 20.2, 3.0,
 0.5, 2.0, 198, NULL,
 'manufacturer', ARRAY['trader joes reduced guilt mac and cheese', 'tj mac and cheese', 'trader joes mac cheese', 'trader joe''s reduced guilt mac & cheese', 'tj reduced guilt mac cheese'],
 'frozen_meals', 'Trader Joe''s', 1, '270 cal per container (198g). Lower-calorie macaroni and cheese.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — FROZEN PROTEINS
-- ══════════════════════════════════════════

-- Trader Joe's Turkey Burgers: 180 cal per patty (112g)
('tj_turkey_burgers', 'Trader Joe''s Turkey Burgers', 160.7, 19.6, 0.0, 8.9,
 0.0, 0.0, NULL, 112,
 'manufacturer', ARRAY['trader joes turkey burgers', 'tj turkey burgers', 'trader joes turkey patties', 'trader joe''s turkey burgers', 'tj frozen turkey burgers'],
 'frozen_meals', 'Trader Joe''s', 1, '180 cal per patty (112g). All-natural turkey burger patties. High protein, zero carb.', TRUE),

-- Trader Joe's Thai Sweet Chili Veggie Burger: 170 cal per patty (71g)
('tj_thai_veggie_burger', 'Trader Joe''s Thai Sweet Chili Veggie Burger', 239.4, 11.3, 25.4, 11.3,
 5.6, 7.0, NULL, 71,
 'manufacturer', ARRAY['trader joes thai veggie burger', 'tj veggie burger', 'trader joes sweet chili veggie burger', 'trader joe''s thai sweet chili veggie burger', 'tj thai veggie patty'],
 'frozen_meals', 'Trader Joe''s', 1, '170 cal per patty (71g). Thai-inspired veggie burger with sweet chili flavor.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — CHICKEN SAUSAGES
-- ══════════════════════════════════════════

-- Trader Joe's Sweet Apple Chicken Sausage: 120 cal per link (71g)
('tj_sweet_apple_chicken_sausage', 'Trader Joe''s Sweet Apple Chicken Sausage', 169.0, 19.7, 8.5, 6.3,
 0.0, 5.6, NULL, 71,
 'manufacturer', ARRAY['trader joes sweet apple chicken sausage', 'tj apple chicken sausage', 'trader joes chicken sausage apple', 'trader joe''s sweet apple chicken sausage', 'tj sweet apple sausage'],
 'sausage', 'Trader Joe''s', 1, '120 cal per link (71g). Sweet apple flavored chicken sausage. High protein.', TRUE),

-- Trader Joe's Spicy Jalapeno Chicken Sausage: 100 cal per link (68g)
('tj_spicy_jalapeno_chicken_sausage', 'Trader Joe''s Spicy Jalapeno Chicken Sausage', 147.1, 16.2, 2.9, 8.8,
 0.0, 0.0, NULL, 68,
 'manufacturer', ARRAY['trader joes spicy jalapeno chicken sausage', 'tj jalapeno chicken sausage', 'trader joes chicken sausage jalapeno', 'trader joe''s spicy jalapeno chicken sausage', 'tj spicy chicken sausage'],
 'sausage', 'Trader Joe''s', 1, '100 cal per link (68g). Spicy jalapeno flavored chicken sausage. High protein.', TRUE),

-- Trader Joe's Garlic Herb Chicken Sausage: 130 cal per link (85g)
('tj_garlic_herb_chicken_sausage', 'Trader Joe''s Garlic Herb Chicken Sausage', 152.9, 20.0, 0.0, 8.2,
 0.0, 0.0, NULL, 85,
 'manufacturer', ARRAY['trader joes garlic herb chicken sausage', 'tj garlic herb chicken sausage', 'trader joes chicken sausage garlic', 'trader joe''s garlic herb chicken sausage', 'tj herb chicken sausage'],
 'sausage', 'Trader Joe''s', 1, '130 cal per link (85g). Garlic herb flavored chicken sausage. High protein, zero carb.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — REFRIGERATED
-- ══════════════════════════════════════════

-- Trader Joe's Everything But The Bagel Smoked Salmon: 80 cal per 2 slices (56g)
('tj_ebtb_smoked_salmon', 'Trader Joe''s Everything But The Bagel Smoked Salmon', 142.9, 19.6, 0.0, 6.3,
 0.0, 0.0, 56, NULL,
 'manufacturer', ARRAY['trader joes everything but the bagel smoked salmon', 'tj ebtb salmon', 'trader joes smoked salmon', 'trader joe''s everything bagel smoked salmon', 'tj smoked salmon'],
 'deli', 'Trader Joe''s', 1, '80 cal per 2 slices (56g). Smoked salmon with everything bagel seasoning. High protein.', TRUE),

-- Trader Joe's Unexpected Cheddar Cheese: 120 cal per 1oz (28g)
('tj_unexpected_cheddar', 'Trader Joe''s Unexpected Cheddar Cheese', 428.6, 25.0, 0.0, 35.7,
 0.0, 0.0, 28, NULL,
 'manufacturer', ARRAY['trader joes unexpected cheddar', 'tj unexpected cheddar', 'trader joes cheddar cheese', 'trader joe''s unexpected cheddar cheese', 'tj unexpected cheddar cheese'],
 'cheese', 'Trader Joe''s', 1, '120 cal per oz (28g). Award-winning cheddar with parmesan-like flavor. Fan favorite.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — FROZEN PIZZA & BREAD
-- ══════════════════════════════════════════

-- Trader Joe's Cauliflower Gnocchi: 140 cal per cup (140g)
('tj_cauliflower_gnocchi', 'Trader Joe''s Cauliflower Gnocchi', 100.0, 1.4, 15.7, 2.1,
 4.3, 0.0, 140, NULL,
 'manufacturer', ARRAY['trader joes cauliflower gnocchi', 'tj cauliflower gnocchi', 'trader joes gnocchi', 'trader joe''s cauliflower gnocchi', 'tj gnocchi cauliflower'],
 'frozen_meals', 'Trader Joe''s', 1, '140 cal per cup (140g). Made with cauliflower, cassava flour, potato starch. Gluten-free. TJ''s cult favorite.', TRUE),

-- Trader Joe's Cauliflower Pizza Crust: 120 cal per crust (71g)
('tj_cauliflower_pizza_crust', 'Trader Joe''s Cauliflower Pizza Crust', 169.0, 14.1, 5.6, 8.5,
 1.4, 1.4, NULL, 71,
 'manufacturer', ARRAY['trader joes cauliflower pizza crust', 'tj cauliflower crust', 'trader joes cauliflower crust pizza', 'trader joe''s cauliflower pizza crust', 'tj pizza crust cauliflower'],
 'frozen_meals', 'Trader Joe''s', 1, '120 cal per crust (71g). Gluten-free cauliflower-based pizza crust. Low carb.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — FROZEN BOWLS
-- ══════════════════════════════════════════

-- Trader Joe's Organic Acai Bowl: 270 cal per bowl (284g)
('tj_organic_acai_bowl', 'Trader Joe''s Organic Acai Bowl', 95.1, 1.8, 16.9, 2.5,
 2.1, 7.4, 284, NULL,
 'manufacturer', ARRAY['trader joes acai bowl', 'tj acai bowl', 'trader joes organic acai bowl', 'trader joe''s acai bowl', 'tj frozen acai bowl'],
 'bowl', 'Trader Joe''s', 1, '270 cal per bowl (284g). Organic acai blend with banana, strawberry, blueberry.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — FROZEN DESSERTS
-- ══════════════════════════════════════════

-- Trader Joe's Gone Bananas (Chocolate Covered Banana): 100 cal per 4 pcs (43g)
('tj_gone_bananas', 'Trader Joe''s Gone Bananas (Chocolate Covered Banana)', 232.6, 2.3, 37.2, 8.1,
 4.7, 27.9, 43, NULL,
 'manufacturer', ARRAY['trader joes gone bananas', 'tj gone bananas', 'trader joes chocolate covered banana', 'trader joe''s gone bananas', 'tj chocolate banana'],
 'dessert', 'Trader Joe''s', 1, '100 cal per 4 pieces (43g). Frozen banana slices dipped in dark chocolate.', TRUE),

-- Trader Joe's Hold The Cone Mini Ice Cream Cones: 260 cal per 3 cones (84g)
('tj_hold_the_cone', 'Trader Joe''s Hold The Cone Mini Ice Cream Cones', 309.5, 4.8, 40.5, 14.3,
 2.4, 22.6, 84, NULL,
 'manufacturer', ARRAY['trader joes hold the cone', 'tj hold the cone', 'trader joes mini ice cream cones', 'trader joe''s hold the cone', 'tj mini ice cream'],
 'dessert', 'Trader Joe''s', 1, '260 cal per 3 mini cones (84g). Miniature ice cream cones in assorted flavors.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — SNACKS
-- ══════════════════════════════════════════

-- Trader Joe's Dark Chocolate Peanut Butter Cups: 190 cal per 3 pcs (34g)
('tj_dark_chocolate_pb_cups', 'Trader Joe''s Dark Chocolate Peanut Butter Cups', 558.8, 8.8, 52.9, 35.3,
 2.9, 32.4, 34, NULL,
 'manufacturer', ARRAY['trader joes dark chocolate peanut butter cups', 'tj pb cups', 'trader joes peanut butter cups', 'trader joe''s dark chocolate pb cups', 'tj chocolate peanut butter cups'],
 'snacks', 'Trader Joe''s', 1, '190 cal per 3 pieces (34g). Dark chocolate cups filled with peanut butter.', TRUE),

-- Trader Joe's Dark Chocolate Covered Almonds: 160 cal per 8 pcs (30g)
('tj_dark_chocolate_almonds', 'Trader Joe''s Dark Chocolate Covered Almonds', 533.3, 10.0, 46.7, 36.7,
 10.0, 33.3, 30, NULL,
 'manufacturer', ARRAY['trader joes dark chocolate almonds', 'tj chocolate almonds', 'trader joes chocolate covered almonds', 'trader joe''s dark chocolate almonds', 'tj dark chocolate almonds'],
 'snacks', 'Trader Joe''s', 1, '160 cal per 8 pieces (30g). Whole almonds coated in dark chocolate.', TRUE),

-- Trader Joe's Peanut Butter Filled Pretzels: 150 cal per 10 pcs (31g)
('tj_pb_filled_pretzels', 'Trader Joe''s Peanut Butter Filled Pretzels', 483.9, 16.1, 54.8, 22.6,
 3.2, 6.5, 31, NULL,
 'manufacturer', ARRAY['trader joes peanut butter pretzels', 'tj pb pretzels', 'trader joes pb filled pretzels', 'trader joe''s peanut butter filled pretzels', 'tj peanut butter pretzels'],
 'snacks', 'Trader Joe''s', 1, '150 cal per 10 pieces (31g). Crunchy pretzel nuggets filled with peanut butter.', TRUE),

-- Trader Joe's Everything But The Bagel Seasoned Chips: 140 cal per 16 chips (28g)
('tj_everything_bagel_chips', 'Trader Joe''s Everything But The Bagel Seasoned Chips', 500.0, 7.1, 60.7, 25.0,
 7.1, 0.0, 28, NULL,
 'manufacturer', ARRAY['trader joes everything bagel chips', 'tj bagel chips', 'trader joes ebtb chips', 'trader joe''s everything bagel chips', 'tj everything chips'],
 'snacks', 'Trader Joe''s', 1, '140 cal per 16 chips (28g). Bagel chips with everything but the bagel seasoning.', TRUE),

-- Trader Joe's Elote Corn Chip Dippers: 160 cal per 12 chips (28g)
('tj_elote_corn_chip_dippers', 'Trader Joe''s Elote Corn Chip Dippers', 571.4, 7.1, 57.1, 35.7,
 3.6, 3.6, 28, NULL,
 'manufacturer', ARRAY['trader joes elote corn chip dippers', 'tj elote chips', 'trader joes corn chip dippers', 'trader joe''s elote chips', 'tj elote dippers'],
 'snacks', 'Trader Joe''s', 1, '160 cal per 12 chips (28g). Mexican street corn flavored corn chip dippers.', TRUE),

-- Trader Joe's Cowboy Bark: 220 cal per 1/6 pkg (43g)
('tj_cowboy_bark', 'Trader Joe''s Cowboy Bark', 511.6, 7.0, 60.5, 25.6,
 0.0, 46.5, 43, NULL,
 'manufacturer', ARRAY['trader joes cowboy bark', 'tj cowboy bark', 'trader joes chocolate bark', 'trader joe''s cowboy bark', 'tj bark chocolate'],
 'snacks', 'Trader Joe''s', 1, '220 cal per 1/6 package (43g). Dark and milk chocolate bark with pretzels, toffee, Joe-Joe''s cookies.', TRUE),

-- Trader Joe's Triple Ginger Snaps: 120 cal per 6 cookies (30g)
('tj_triple_ginger_snaps', 'Trader Joe''s Triple Ginger Snaps', 400.0, 3.3, 60.0, 15.0,
 3.3, 30.0, 30, NULL,
 'manufacturer', ARRAY['trader joes triple ginger snaps', 'tj ginger snaps', 'trader joes ginger cookies', 'trader joe''s triple ginger snaps', 'tj ginger snap cookies'],
 'snacks', 'Trader Joe''s', 1, '120 cal per 6 cookies (30g). Crispy ginger snap cookies with fresh, crystallized, and ground ginger.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — SPREADS & CONDIMENTS
-- ══════════════════════════════════════════

-- Trader Joe's Speculoos Cookie Butter: 170 cal per 2 tbsp (30g)
('tj_speculoos_cookie_butter', 'Trader Joe''s Speculoos Cookie Butter', 566.7, 3.3, 53.3, 36.7,
 0.0, 36.7, 30, NULL,
 'manufacturer', ARRAY['trader joes cookie butter', 'tj cookie butter', 'trader joes speculoos', 'trader joe''s speculoos cookie butter', 'tj speculoos spread'],
 'condiment', 'Trader Joe''s', 1, '170 cal per 2 tbsp (30g). Spreadable cookie butter made from speculoos biscuits. TJ''s iconic product.', TRUE),

-- Trader Joe's Green Goddess Salad Dressing: 20 cal per 2 tbsp (31g)
('tj_green_goddess_dressing', 'Trader Joe''s Green Goddess Salad Dressing', 64.5, 0.0, 3.2, 6.5,
 0.0, 0.0, 31, NULL,
 'manufacturer', ARRAY['trader joes green goddess dressing', 'tj green goddess dressing', 'trader joes green goddess', 'trader joe''s green goddess salad dressing', 'tj green goddess'],
 'dressing', 'Trader Joe''s', 1, '20 cal per 2 tbsp (31g). Creamy green goddess dressing. Viral TikTok sensation.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — PROTEIN BARS
-- ══════════════════════════════════════════

-- Trader Joe's Chewy Chocolate & Peanut Butter Protein Bar: 190 cal per bar (40g)
('tj_chewy_choc_pb_protein_bar', 'Trader Joe''s Chewy Chocolate & Peanut Butter Protein Bar', 475.0, 25.0, 37.5, 27.5,
 10.0, 20.0, NULL, 40,
 'manufacturer', ARRAY['trader joes protein bar', 'tj protein bar', 'trader joes chewy protein bar', 'trader joe''s chocolate peanut butter protein bar', 'tj chewy pb protein bar'],
 'protein_bar', 'Trader Joe''s', 1, '190 cal per bar (40g). Chewy protein bar with chocolate and peanut butter. 10g protein.', TRUE),

-- ══════════════════════════════════════════
-- TRADER JOE'S — BEVERAGES
-- ══════════════════════════════════════════

-- Trader Joe's Coconut Cold Brew Coffee Concentrate: 10 cal per 4 fl oz (~120g)
('tj_coconut_cold_brew', 'Trader Joe''s Coconut Cold Brew Coffee Concentrate', 8.3, 0.8, 1.7, 0.0,
 0.0, 1.7, 120, NULL,
 'manufacturer', ARRAY['trader joes coconut cold brew', 'tj coconut cold brew', 'trader joes cold brew coffee', 'trader joe''s coconut cold brew coffee', 'tj cold brew coconut'],
 'coffee', 'Trader Joe''s', 1, '10 cal per 4 fl oz (~120g). Cold brew coffee concentrate with coconut cream.', TRUE)

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
