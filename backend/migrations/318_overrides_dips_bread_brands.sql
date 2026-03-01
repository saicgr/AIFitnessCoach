-- 318_overrides_dips_bread_brands.sql
-- Guacamole/dip brands and bread brands with accurate per-100g nutrition data.
-- Sources: nutritionvalue.org, fatsecret.com, nutritionix.com, calorieking.com,
--          official brand websites (eatwholly.com, sabra.com, missionfoods.com,
--          daveskillerbread.com, thomasbreads.com, pepperidgefarm.com, kingshawaiian.com)

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- =====================================================================
-- GUACAMOLE BRANDS
-- =====================================================================

-- Wholly Guacamole Classic: 60 cal/30g serving => 200 cal/100g
-- nutritionvalue.org, fatsecret.com
('wholly_guacamole_classic', 'Wholly Guacamole Classic', 200, 3.3, 10.0, 16.7,
 6.7, 0.0, 30, NULL,
 'wholly_guacamole', ARRAY['wholly guacamole classic', 'wholly guacamole mild', 'wholly classic guacamole'],
 'dips_spreads', 'Wholly Guacamole', 1, '200 cal/100g. Serving 2 tbsp (30g) = 60 cal. Made with Hass avocados. America''s #1 guacamole brand.', TRUE),

-- Wholly Guacamole Spicy: 60 cal/30g serving => 200 cal/100g
-- myfooddata.com, fatsecret.com
('wholly_guacamole_spicy', 'Wholly Guacamole Spicy', 200, 3.3, 10.0, 16.7,
 6.7, 0.0, 30, NULL,
 'wholly_guacamole', ARRAY['wholly guacamole spicy', 'wholly spicy guacamole', 'wholly guacamole hot'],
 'dips_spreads', 'Wholly Guacamole', 1, '200 cal/100g. Serving 2 tbsp (30g) = 60 cal. With jalapeno peppers for heat.', TRUE),

-- Wholly Guacamole Chunky: 50 cal/30g serving => 167 cal/100g
-- fatsecret.com, eatwholly.com
('wholly_guacamole_chunky', 'Wholly Guacamole Chunky', 167, 3.3, 10.0, 13.3,
 6.7, 0.0, 30, NULL,
 'wholly_guacamole', ARRAY['wholly guacamole chunky', 'wholly chunky guacamole', 'wholly homestyle guacamole'],
 'dips_spreads', 'Wholly Guacamole', 1, '167 cal/100g. Serving 2 tbsp (30g) = 50 cal. Chunky texture with visible avocado pieces.', TRUE),

-- Wholly Guacamole Minis (single-serve cups): 110 cal/57g cup => 193 cal/100g
-- fatsecret.com, eatwholly.com
('wholly_guacamole_minis', 'Wholly Guacamole Classic Minis', 193, 1.8, 8.8, 17.5,
 5.3, 1.8, NULL, 57,
 'wholly_guacamole', ARRAY['wholly guacamole mini cups', 'wholly minis', 'wholly guacamole snack cups', 'wholly guacamole single serve'],
 'dips_spreads', 'Wholly Guacamole', 1, '193 cal/100g. Per mini cup (57g) = 110 cal. Convenient single-serve 2 oz cups.', TRUE),

-- Sabra Classic Guacamole: 50 cal/31g serving => 161 cal/100g
-- fatsecret.com, myfooddiary.com
('sabra_guacamole_classic', 'Sabra Classic Guacamole', 161, 3.2, 9.7, 12.9,
 6.5, 0.0, 31, NULL,
 'sabra', ARRAY['sabra guacamole', 'sabra classic guacamole', 'sabra guac'],
 'dips_spreads', 'Sabra', 1, '161 cal/100g. Serving 2 tbsp (31g) = 50 cal. Made with real Hass avocados.', TRUE),

-- Sabra Spicy Guacamole: 50 cal/31g serving => 161 cal/100g
-- myfooddiary.com, fatsecret.com
('sabra_guacamole_spicy', 'Sabra Spicy Guacamole', 161, 3.2, 9.7, 12.9,
 6.5, 0.0, 31, NULL,
 'sabra', ARRAY['sabra spicy guacamole', 'sabra guacamole spicy'],
 'dips_spreads', 'Sabra', 1, '161 cal/100g. Serving 2 tbsp (31g) = 50 cal. Spicy version with chili peppers.', TRUE),

-- Good Foods Chunky Guacamole: 40 cal/33g serving => 121 cal/100g
-- goodfoods.com, myfooddiary.com
('good_foods_chunky_guacamole', 'Good Foods Chunky Guacamole', 121, 3.0, 9.1, 10.6,
 6.1, 0.0, 33, NULL,
 'good_foods', ARRAY['good foods guacamole', 'good foods chunky guac', 'good foods tableside guacamole'],
 'dips_spreads', 'Good Foods', 1, '121 cal/100g. Serving 2 tbsp (33g) = 40 cal. No artificial ingredients, simple recipe.', TRUE),

-- Yucatan Guacamole: 50 cal/30g serving => 167 cal/100g
-- fatsecret.com, nutritionvalue.org
('yucatan_guacamole', 'Yucatan Guacamole', 167, 1.7, 10.0, 13.3,
 3.3, 0.0, 30, NULL,
 'yucatan', ARRAY['yucatan guac', 'yucatan authentic guacamole', 'yucatan restaurant style guacamole'],
 'dips_spreads', 'Yucatan', 1, '167 cal/100g. Serving 2 tbsp (30g) = 50 cal. 95% avocado, authentic style.', TRUE),

-- Hope Foods Guacamole (Green Chile): 45 cal/30g => 150 cal/100g
-- fatsecret.com, myfooddiary.com
('hope_foods_guacamole', 'Hope Foods Green Chile Guacamole', 150, 3.3, 10.0, 13.3,
 6.7, 0.0, 30, NULL,
 'hope_foods', ARRAY['hope guacamole', 'hope foods guac', 'hope green chile guacamole'],
 'dips_spreads', 'Hope Foods', 1, '150 cal/100g. Serving 2 tbsp (30g) = 45 cal. Organic avocado with green chile. Vegan, gluten-free.', TRUE),

-- =====================================================================
-- HUMMUS & OTHER DIP BRANDS
-- =====================================================================

-- Sabra Classic Hummus: 70 cal/28g => 250 cal/100g
-- nutritionvalue.org, fatsecret.com
('sabra_hummus_classic', 'Sabra Classic Hummus', 250, 7.1, 14.3, 17.9,
 7.1, 0.0, 28, NULL,
 'sabra', ARRAY['sabra hummus', 'sabra classic hummus', 'sabra original hummus'],
 'dips_spreads', 'Sabra', 1, '250 cal/100g. Serving 2 tbsp (28g) = 70 cal. America''s #1 hummus brand. Chickpea-based.', TRUE),

-- Sabra Roasted Red Pepper Hummus: 70 cal/28g => 250 cal/100g
-- fatsecret.com, calorieking.com
('sabra_hummus_roasted_red_pepper', 'Sabra Roasted Red Pepper Hummus', 250, 7.1, 14.3, 17.9,
 3.6, 0.0, 28, NULL,
 'sabra', ARRAY['sabra red pepper hummus', 'sabra roasted red pepper', 'sabra rrp hummus'],
 'dips_spreads', 'Sabra', 1, '250 cal/100g. Serving 2 tbsp (28g) = 70 cal. With roasted red peppers blended in.', TRUE),

-- Sabra Roasted Garlic Hummus: 70 cal/28g => 250 cal/100g
-- fatsecret.com, nutritionix.com
('sabra_hummus_roasted_garlic', 'Sabra Roasted Garlic Hummus', 250, 7.1, 17.9, 17.9,
 3.6, 0.0, 28, NULL,
 'sabra', ARRAY['sabra garlic hummus', 'sabra roasted garlic', 'sabra garlic hummus dip'],
 'dips_spreads', 'Sabra', 1, '250 cal/100g. Serving 2 tbsp (28g) = 70 cal. With roasted garlic flavor.', TRUE),

-- Sabra Supremely Spicy Hummus: 70 cal/28g => 250 cal/100g
-- fatsecret.com, calorieking.com, snapcalorie.com
('sabra_hummus_supremely_spicy', 'Sabra Supremely Spicy Hummus', 250, 7.1, 14.3, 17.9,
 3.6, 0.0, 28, NULL,
 'sabra', ARRAY['sabra spicy hummus', 'sabra supremely spicy', 'sabra hot hummus'],
 'dips_spreads', 'Sabra', 1, '250 cal/100g. Serving 2 tbsp (28g) = 70 cal. Spiciest Sabra hummus variety.', TRUE),

-- Tostitos Salsa Con Queso: 40 cal/30g => 133 cal/100g
-- nutritionvalue.org, fatsecret.com
('tostitos_salsa_con_queso', 'Tostitos Salsa Con Queso', 133, 2.9, 11.7, 8.3,
 0.6, 1.4, 30, NULL,
 'tostitos', ARRAY['tostitos queso', 'tostitos cheese dip', 'tostitos salsa con queso medium'],
 'dips_spreads', 'Tostitos', 1, '133 cal/100g. Serving 2 tbsp (30g) = 40 cal. Cheese-based salsa dip.', TRUE),

-- Tostitos Chunky Salsa: 10 cal/30g => 33 cal/100g
-- fatsecret.com, tostitos.com
('tostitos_chunky_salsa', 'Tostitos Chunky Salsa', 33, 0.0, 6.7, 0.0,
 3.3, 3.3, 30, NULL,
 'tostitos', ARRAY['tostitos salsa', 'tostitos mild chunky salsa', 'tostitos medium chunky salsa'],
 'dips_spreads', 'Tostitos', 1, '33 cal/100g. Serving 2 tbsp (30g) = 10 cal. Tomato-based chunky salsa, very low calorie.', TRUE),

-- Tostitos Restaurant Style Salsa: 15 cal/30g => 50 cal/100g
-- eatthismuch.com, tostitos.com
('tostitos_restaurant_style_salsa', 'Tostitos Restaurant Style Salsa', 50, 0.0, 10.0, 0.0,
 3.3, 3.3, 30, NULL,
 'tostitos', ARRAY['tostitos restaurant salsa', 'tostitos smooth salsa'],
 'dips_spreads', 'Tostitos', 1, '50 cal/100g. Serving 2 tbsp (30g) = 15 cal. Smooth restaurant-style salsa.', TRUE),

-- Lay's French Onion Dip: 60 cal/30g => 200 cal/100g
-- fatsecret.com, calorieking.com
('lays_french_onion_dip', 'Lay''s French Onion Dip', 200, 3.3, 6.7, 16.7,
 0.0, 3.3, 30, NULL,
 'lays', ARRAY['lay''s onion dip', 'frito lay french onion dip', 'lays dip french onion'],
 'dips_spreads', 'Lay''s', 1, '200 cal/100g. Serving 2 tbsp (30g) = 60 cal. Sour cream-based onion dip.', TRUE),

-- Dean's French Onion Dip: 60 cal/30g => 200 cal/100g
-- nutritionvalue.org, calorieking.com
('deans_french_onion_dip', 'Dean''s French Onion Dip', 200, 3.3, 6.7, 16.7,
 0.0, 3.3, 30, NULL,
 'deans', ARRAY['dean''s onion dip', 'deans dip french onion'],
 'dips_spreads', 'Dean''s', 1, '200 cal/100g. Serving 2 tbsp (30g) = 60 cal. Cultured sour cream with onion seasoning.', TRUE),

-- Spinach Artichoke Dip (generic/deli style): ~220 cal/100g
-- nutritionvalue.org, snapcalorie.com
('spinach_artichoke_dip', 'Spinach Artichoke Dip', 220, 5.0, 7.0, 19.0,
 1.5, 1.5, 30, NULL,
 'generic_dip', ARRAY['spinach dip', 'artichoke dip', 'spinach artichoke', 'hot spinach artichoke dip', 'creamy spinach artichoke dip'],
 'dips_spreads', 'Generic', 1, '220 cal/100g. Serving 2 tbsp (30g) = 66 cal. Cream cheese/sour cream based with spinach and artichoke hearts.', TRUE),

-- Buffalo Chicken Dip (generic/deli style): ~200 cal/100g
-- nutritionix.com, snapcalorie.com
('buffalo_chicken_dip', 'Buffalo Chicken Dip', 200, 10.0, 3.3, 16.0,
 0.3, 1.0, 30, NULL,
 'generic_dip', ARRAY['buffalo dip', 'hot buffalo chicken dip', 'frank''s buffalo chicken dip', 'spicy chicken dip'],
 'dips_spreads', 'Generic', 1, '200 cal/100g. Serving 2 tbsp (30g) = 60 cal. Cream cheese, shredded chicken, hot sauce, ranch.', TRUE),

-- Ranch Dip (prepared, sour cream-based): 50 cal/15g => 333 cal/100g
-- Hidden Valley style. fatsecret.com, mynetdiary.com
('ranch_dip', 'Ranch Dip', 333, 3.3, 6.7, 33.3,
 0.0, 3.3, 30, NULL,
 'generic_dip', ARRAY['hidden valley ranch dip', 'ranch dip sour cream', 'creamy ranch dip', 'veggie ranch dip'],
 'dips_spreads', 'Generic', 1, '333 cal/100g. Serving 2 tbsp (30g) = 100 cal. Sour cream-based ranch dip (prepared from mix).', TRUE),

-- =====================================================================
-- BREAD BRANDS
-- =====================================================================

-- Dave's Killer Bread 21 Whole Grains: 110 cal/slice (45g) => 244 cal/100g
-- daveskillerbread.com, fatsecret.com, carbmanager.com
('daves_killer_bread_21_grains', 'Dave''s Killer Bread 21 Whole Grains & Seeds', 244, 11.1, 48.9, 3.3,
 11.1, 11.1, NULL, 45,
 'daves_killer_bread', ARRAY['dkb 21 grains', 'dave''s 21 whole grains', 'daves killer bread 21 grain', 'dave''s killer bread'],
 'bread', 'Dave''s Killer Bread', 1, '244 cal/100g. Per slice (45g) = 110 cal, 5g protein, 22g carbs, 1.5g fat, 5g fiber. Organic.', TRUE),

-- Dave's Killer Bread Good Seed: 120 cal/slice (45g) => 267 cal/100g
-- daveskillerbread.com, myfooddiary.com
('daves_killer_bread_good_seed', 'Dave''s Killer Bread Good Seed', 267, 13.3, 48.9, 6.7,
 6.7, 11.1, NULL, 45,
 'daves_killer_bread', ARRAY['dkb good seed', 'dave''s good seed bread', 'daves killer good seed'],
 'bread', 'Dave''s Killer Bread', 1, '267 cal/100g. Per slice (45g) = 120 cal, 6g protein, 22g carbs, 3g fat. Organic with flax, sunflower, sesame seeds.', TRUE),

-- Dave's Killer Bread White Bread Done Right: 110 cal/slice (40g) => 275 cal/100g
-- daveskillerbread.com, fatsecret.com
('daves_killer_bread_white_done_right', 'Dave''s Killer Bread White Bread Done Right', 275, 5.0, 50.0, 5.0,
 5.0, 12.5, NULL, 40,
 'daves_killer_bread', ARRAY['dkb white bread', 'dave''s white bread done right', 'daves killer white bread'],
 'bread', 'Dave''s Killer Bread', 1, '275 cal/100g. Per slice (40g) = 110 cal. Organic white bread with whole grains, no bleached flour.', TRUE),

-- Dave's Killer Bread Thin-Sliced 21 Grains: 60 cal/slice (28g) => 214 cal/100g
-- daveskillerbread.com, amazon.com
('daves_killer_bread_thin_21_grains', 'Dave''s Killer Bread 21 Grains Thin-Sliced', 214, 10.7, 46.4, 3.6,
 10.7, 10.7, NULL, 28,
 'daves_killer_bread', ARRAY['dkb thin sliced', 'dave''s thin sliced 21 grains', 'daves killer thin bread'],
 'bread', 'Dave''s Killer Bread', 1, '214 cal/100g. Per slice (28g) = 60 cal, 3g protein. Thin-sliced for lower calories per sandwich.', TRUE),

-- Sara Lee Artesano: 110 cal/slice (38g) => 289 cal/100g
-- fatsecret.com, myfooddiary.com
('sara_lee_artesano', 'Sara Lee Artesano Bread', 289, 7.9, 52.6, 3.9,
 1.3, 5.3, NULL, 38,
 'sara_lee', ARRAY['sara lee artesano original', 'artesano bread', 'artesano bakery bread'],
 'bread', 'Sara Lee', 1, '289 cal/100g. Per slice (38g) = 110 cal, 3g protein, 20g carbs, 1.5g fat. Thick-sliced bakery style.', TRUE),

-- Sara Lee Honey Wheat: 70 cal/slice (26g) => 269 cal/100g
-- fatsecret.com, calorieking.com
('sara_lee_honey_wheat', 'Sara Lee Honey Wheat Bread', 269, 7.7, 50.0, 3.8,
 3.8, 7.7, NULL, 26,
 'sara_lee', ARRAY['sara lee honey wheat', 'sara lee wheat bread'],
 'bread', 'Sara Lee', 1, '269 cal/100g. Per slice (26g) = 70 cal, 2g protein, 13g carbs, 1g fat. Soft honey wheat.', TRUE),

-- Sara Lee Classic White: 75 cal/slice (25g) => 300 cal/100g
-- fatsecret.com, saraleebread.com
('sara_lee_classic_white', 'Sara Lee Classic White Bread', 300, 8.0, 56.0, 4.0,
 2.0, 6.0, NULL, 25,
 'sara_lee', ARRAY['sara lee white bread', 'sara lee classic white'],
 'bread', 'Sara Lee', 1, '300 cal/100g. Per slice (25g) = 75 cal. Good source of calcium, enriched.', TRUE),

-- Nature's Own Honey Wheat: 70 cal/slice (26g) => 269 cal/100g
-- naturesownbread.com, fatsecret.com
('natures_own_honey_wheat', 'Nature''s Own Honey Wheat Bread', 269, 11.5, 50.0, 1.9,
 3.8, 7.7, NULL, 26,
 'natures_own', ARRAY['nature''s own honey wheat', 'natures own wheat bread'],
 'bread', 'Nature''s Own', 1, '269 cal/100g. Per slice (26g) = 70 cal, 3g protein, 13g carbs, 0.5g fat. No artificial preservatives.', TRUE),

-- Nature's Own 100% Whole Wheat: 60 cal/slice (25g) => 240 cal/100g
-- naturesownbread.com, fatsecret.com
('natures_own_100_whole_wheat', 'Nature''s Own 100% Whole Wheat Bread', 240, 12.0, 44.0, 4.0,
 8.0, 4.0, NULL, 25,
 'natures_own', ARRAY['nature''s own whole wheat', 'natures own 100 percent whole wheat'],
 'bread', 'Nature''s Own', 1, '240 cal/100g. Per slice (25g) = 60 cal. 13g whole grain per slice. No HFCS.', TRUE),

-- Nature's Own Butterbread: 70 cal/slice (26g) => 269 cal/100g
-- naturesownbread.com, fatsecret.com
('natures_own_butterbread', 'Nature''s Own Butterbread', 269, 7.7, 53.8, 3.8,
 1.9, 7.7, NULL, 26,
 'natures_own', ARRAY['nature''s own butter bread', 'natures own butterbread white'],
 'bread', 'Nature''s Own', 1, '269 cal/100g. Per slice (26g) = 70 cal, 2g protein, 14g carbs, 1g fat. Soft white bread, no HFCS.', TRUE),

-- Wonder Bread Classic White: 70 cal/slice (26g) => 269 cal/100g
-- fatsecret.com, wonderbread.com
('wonder_bread_classic_white', 'Wonder Bread Classic White', 269, 7.7, 50.0, 3.8,
 0.0, 9.6, NULL, 26,
 'wonder_bread', ARRAY['wonder bread', 'wonder white bread', 'wonder classic white'],
 'bread', 'Wonder Bread', 1, '269 cal/100g. Per slice (26g) = 70 cal. Calcium fortified, classic American white bread.', TRUE),

-- Arnold Whole Grains 100% Whole Wheat: 110 cal/slice (43g) => 256 cal/100g
-- arnoldbread.com, fatsecret.com
('arnold_whole_grains_100', 'Arnold Whole Grains 100% Whole Wheat', 256, 9.3, 44.2, 2.3,
 7.0, 7.0, NULL, 43,
 'arnold', ARRAY['arnold 100 whole wheat', 'arnold whole grains bread', 'brownberry whole grains 100'],
 'bread', 'Arnold', 1, '256 cal/100g. Per slice (43g) = 110 cal, 4g protein, 19g carbs, 1g fat, 3g fiber. Also sold as Brownberry.', TRUE),

-- Arnold Oat Nut: 120 cal/slice (43g) => 279 cal/100g
-- arnoldbread.com, fatsecret.com, myfooddiary.com
('arnold_oat_nut', 'Arnold Oatnut Bread', 279, 9.3, 48.8, 5.8,
 4.7, 9.3, NULL, 43,
 'arnold', ARRAY['arnold oatnut', 'brownberry oat nut bread', 'arnold oat nut bread'],
 'bread', 'Arnold', 1, '279 cal/100g. Per slice (43g) = 120 cal, 4g protein, 21g carbs, 2.5g fat. With oats and hazelnuts.', TRUE),

-- King's Hawaiian Sweet Rolls: 90 cal/roll (28g) => 321 cal/100g
-- kingshawaiian.com, calorieking.com, fatsecret.com
('kings_hawaiian_sweet_rolls', 'King''s Hawaiian Original Sweet Rolls', 321, 7.1, 50.0, 7.1,
 1.8, 17.9, NULL, 28,
 'kings_hawaiian', ARRAY['hawaiian rolls', 'king''s hawaiian rolls', 'kings hawaiian dinner rolls', 'hawaiian sweet rolls'],
 'bread', 'King''s Hawaiian', 1, '321 cal/100g. Per roll (28g) = 90 cal, 2g protein, 14g carbs, 2g fat, 5g sugar. Soft, sweet rolls.', TRUE),

-- King's Hawaiian Slider Buns: 90 cal/bun (31g) => 290 cal/100g
-- kingshawaiian.com, fatsecret.com, nutritionix.com
('kings_hawaiian_slider_buns', 'King''s Hawaiian Sweet Slider Buns', 290, 9.7, 48.4, 6.5,
 1.6, 16.1, NULL, 31,
 'kings_hawaiian', ARRAY['kings hawaiian sliders', 'hawaiian slider buns', 'king''s hawaiian mini buns'],
 'bread', 'King''s Hawaiian', 1, '290 cal/100g. Per bun (31g) = 90 cal, 3g protein, 15g carbs, 2g fat. Mini slider size.', TRUE),

-- King's Hawaiian Sliced Bread: 120 cal/slice (37g) => 324 cal/100g
-- fatsecret.com, kingshawaiian.com
('kings_hawaiian_sliced_bread', 'King''s Hawaiian Sweet Sliced Bread', 324, 8.1, 54.1, 6.8,
 1.4, 16.2, NULL, 37,
 'kings_hawaiian', ARRAY['kings hawaiian bread', 'hawaiian sweet bread sliced', 'king''s hawaiian loaf'],
 'bread', 'King''s Hawaiian', 1, '324 cal/100g. Per slice (37g) = 120 cal, 3g protein, 20g carbs, 2.5g fat. Sweet sandwich bread.', TRUE),

-- Pepperidge Farm Farmhouse Hearty White: 120 cal/slice (43g) => 279 cal/100g
-- pepperidgefarm.com, calorieking.com
('pepperidge_farm_farmhouse_white', 'Pepperidge Farm Farmhouse Hearty White', 279, 9.3, 48.8, 2.3,
 2.3, 7.0, NULL, 43,
 'pepperidge_farm', ARRAY['pepperidge farm white bread', 'farmhouse hearty white', 'pepperidge farm farmhouse'],
 'bread', 'Pepperidge Farm', 1, '279 cal/100g. Per slice (43g) = 120 cal, 4g protein, 21g carbs, 1g fat. Thick-sliced, soft.', TRUE),

-- Pepperidge Farm Farmhouse Whole Grain White: 120 cal/slice (49g) => 245 cal/100g
-- pepperidgefarm.com, eatthismuch.com, fatsecret.com
('pepperidge_farm_whole_grain_white', 'Pepperidge Farm Farmhouse Whole Grain White', 245, 8.2, 51.0, 2.0,
 8.2, 8.2, NULL, 49,
 'pepperidge_farm', ARRAY['pepperidge farm whole grain white bread', 'farmhouse whole grain white'],
 'bread', 'Pepperidge Farm', 1, '245 cal/100g. Per slice (49g) = 120 cal, 4g protein, 25g carbs, 1g fat, 4g fiber. White bread with whole grains.', TRUE),

-- Pepperidge Farm Swirl Cinnamon: 80 cal/slice (28g) => 286 cal/100g
-- pepperidgefarm.com, fatsecret.com
('pepperidge_farm_cinnamon_swirl', 'Pepperidge Farm Cinnamon Swirl Bread', 286, 7.1, 53.6, 5.4,
 1.8, 17.9, NULL, 28,
 'pepperidge_farm', ARRAY['pepperidge farm cinnamon bread', 'cinnamon swirl bread pepperidge', 'pepperidge swirl'],
 'bread', 'Pepperidge Farm', 1, '286 cal/100g. Per slice (28g) = 80 cal. Sweet cinnamon swirl, great for toast.', TRUE),

-- Thomas' Original English Muffins: 130 cal/muffin (57g) => 228 cal/100g
-- thomasbreads.com, fatsecret.com, calorieking.com
('thomas_english_muffin_original', 'Thomas'' Original English Muffins', 228, 7.0, 42.1, 1.8,
 1.8, 3.5, NULL, 57,
 'thomas', ARRAY['thomas english muffin', 'thomas'' original muffin', 'english muffin thomas'],
 'bread', 'Thomas''', 1, '228 cal/100g. Per muffin (57g) = 130 cal, 4g protein, 24g carbs, 1g fat. Nooks & crannies texture.', TRUE),

-- Thomas' 100% Whole Wheat English Muffin: 120 cal/muffin (57g) => 211 cal/100g
-- thomasbreads.com, fatsecret.com
('thomas_english_muffin_whole_wheat', 'Thomas'' 100% Whole Wheat English Muffins', 211, 7.0, 38.6, 1.8,
 5.3, 1.8, NULL, 57,
 'thomas', ARRAY['thomas whole wheat muffin', 'thomas'' wheat english muffin'],
 'bread', 'Thomas''', 1, '211 cal/100g. Per muffin (57g) = 120 cal. 25g whole grains per muffin. Good source of fiber.', TRUE),

-- Thomas' Everything Bagel: 280 cal/bagel (95g) => 295 cal/100g
-- fatsecret.com, calorieking.com, myfooddiary.com
('thomas_everything_bagel', 'Thomas'' Everything Bagel', 295, 9.5, 55.8, 3.2,
 2.1, 5.3, NULL, 95,
 'thomas', ARRAY['thomas everything bagel', 'thomas'' bagel everything', 'everything bagel thomas'],
 'bread', 'Thomas''', 1, '295 cal/100g. Per bagel (95g) = 280 cal, 9g protein, 53g carbs, 3g fat. Topped with sesame, poppy, onion, garlic.', TRUE),

-- Mission Flour Tortillas Burrito Size: 210 cal/tortilla (71g) => 296 cal/100g
-- missionfoods.com, fatsecret.com
('mission_flour_tortilla_burrito', 'Mission Flour Tortillas (Burrito Size)', 296, 8.5, 49.3, 6.3,
 1.4, 2.8, NULL, 71,
 'mission', ARRAY['mission burrito tortilla', 'mission flour tortilla large', 'mission 10 inch tortilla'],
 'bread', 'Mission', 1, '296 cal/100g. Per tortilla (71g) = 210 cal, 6g protein, 35g carbs, 4.5g fat. 10-inch burrito size.', TRUE),

-- Mission Corn Tortillas: 50 cal/tortilla (24g) => 208 cal/100g
-- missionfoods.com, calorieking.com
('mission_corn_tortillas', 'Mission White Corn Tortillas', 208, 4.2, 41.7, 2.1,
 4.2, 0.0, NULL, 24,
 'mission', ARRAY['mission corn tortilla', 'mission yellow corn tortillas', 'mission tortillas corn'],
 'bread', 'Mission', 1, '208 cal/100g. Per tortilla (24g) = 50 cal. Gluten-free corn tortilla, 6-inch size.', TRUE),

-- Mission Whole Wheat Tortillas (Soft Taco): 110 cal/tortilla (40g) => 275 cal/100g
-- missionfoods.com, fatsecret.com
('mission_whole_wheat_tortilla', 'Mission Whole Wheat Flour Tortillas', 275, 10.0, 55.0, 5.0,
 5.0, 2.5, NULL, 40,
 'mission', ARRAY['mission whole wheat tortilla', 'mission wheat tortilla soft taco'],
 'bread', 'Mission', 1, '275 cal/100g. Per tortilla (40g) = 110 cal, 4g protein, 22g carbs, 2g fat, 2g fiber.', TRUE),

-- Old El Paso Stand N Stuff Taco Shells: 130 cal/2 shells (27g) => 481 cal/100g
-- oldelpaso.com, calorieking.com, fatsecret.com
('old_el_paso_stand_n_stuff', 'Old El Paso Stand ''N Stuff Taco Shells', 481, 7.4, 63.0, 22.2,
 7.4, 0.0, NULL, 14,
 'old_el_paso', ARRAY['stand n stuff taco shells', 'old el paso stand and stuff', 'flat bottom taco shells'],
 'bread', 'Old El Paso', 1, '481 cal/100g. Per shell (~14g) = 65 cal. Flat-bottomed shells that stand upright. Per 2 shells (27g) = 130 cal.', TRUE),

-- Old El Paso Crunchy Taco Shells: 150 cal/3 shells (39g) => 385 cal/100g
-- oldelpaso.com, calorieking.com, fatsecret.com
('old_el_paso_crunchy_taco_shells', 'Old El Paso Crunchy Taco Shells', 385, 5.1, 51.3, 17.9,
 5.1, 0.0, NULL, 13,
 'old_el_paso', ARRAY['old el paso taco shells', 'crunchy taco shells', 'old el paso hard taco shells'],
 'bread', 'Old El Paso', 1, '385 cal/100g. Per shell (~13g) = 50 cal. Per 3 shells (39g) = 150 cal. Classic crunchy corn taco shells.', TRUE)

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
