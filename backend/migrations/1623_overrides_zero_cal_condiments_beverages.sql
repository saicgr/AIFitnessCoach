-- 1623_overrides_zero_cal_condiments_beverages.sql
-- Zero/low-calorie condiments, beverages, and sweeteners:
-- Walden Farms, G Hughes, Zevia, Crystal Light, Mio, Primal Kitchen, sweeteners.
-- Sources: Package nutrition labels via waldenfarms.com, ghughessauce.com, zevia.com,
-- fatsecret.com, nutritionix.com, eatthismuch.com, primalkitchen.com.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = label serving.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- WALDEN FARMS — ZERO-CALORIE DRESSINGS (2 tbsp / 30g serving)
-- ══════════════════════════════════════════

-- Walden Farms Ranch Dressing: 0 cal per 2 tbsp (30g)
('walden_ranch', 'Walden Farms Ranch Dressing', 0, 3.3, 6.7, 0.0,
 3.3, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms ranch', 'walden farms ranch dressing', 'walden farms calorie free ranch', 'walden farms zero calorie ranch dressing'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, dairy-free, gluten-free. 0g net carbs (2g carb, 1g fiber per serving).', TRUE),

-- Walden Farms Thousand Island Dressing: 0 cal per 2 tbsp (30g)
('walden_thousand_island', 'Walden Farms Thousand Island Dressing', 0, 0.0, 6.7, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms thousand island', 'walden farms thousand island dressing', 'walden farms calorie free thousand island', 'walden farms zero calorie thousand island'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free. 2g carbs per serving.', TRUE),

-- Walden Farms Caesar Dressing: 0 cal per 2 tbsp (30g)
('walden_caesar', 'Walden Farms Caesar Dressing', 0, 0.0, 6.7, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms caesar', 'walden farms caesar dressing', 'walden farms calorie free caesar', 'walden farms zero calorie caesar dressing'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free. Creamy caesar flavor with zero guilt.', TRUE),

-- Walden Farms Italian Dressing: 0 cal per 2 tbsp (30g)
('walden_italian', 'Walden Farms Zesty Italian Dressing', 0, 0.0, 3.3, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms italian', 'walden farms italian dressing', 'walden farms zesty italian', 'walden farms calorie free italian dressing'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free zesty Italian dressing.', TRUE),

-- Walden Farms Balsamic Vinaigrette: 0 cal per 2 tbsp (30g)
('walden_balsamic_vinaigrette', 'Walden Farms Balsamic Vinaigrette', 0, 0.0, 3.3, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms balsamic vinaigrette', 'walden farms balsamic', 'walden farms calorie free balsamic', 'walden farms zero calorie balsamic vinaigrette'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free balsamic vinaigrette. 1g carbs per serving.', TRUE),

-- Walden Farms Honey Dijon Dressing: 0 cal per 2 tbsp (30g)
('walden_honey_dijon', 'Walden Farms Honey Dijon Dressing', 0, 0.0, 6.7, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms honey dijon', 'walden farms honey dijon dressing', 'walden farms calorie free honey dijon', 'walden farms zero calorie honey dijon'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free honey dijon flavor.', TRUE),

-- ══════════════════════════════════════════
-- WALDEN FARMS — ZERO-CALORIE SAUCES & SYRUPS
-- ══════════════════════════════════════════

-- Walden Farms Chocolate Syrup: 0 cal per 2 tbsp (30g)
('walden_chocolate_syrup', 'Walden Farms Chocolate Syrup', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms chocolate syrup', 'walden farms calorie free chocolate syrup', 'walden farms zero calorie chocolate syrup', 'walden farms chocolate sauce'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free chocolate syrup. Vegan, gluten-free.', TRUE),

-- Walden Farms Pancake Syrup: 0 cal per 2 tbsp (30g)
('walden_pancake_syrup', 'Walden Farms Pancake Syrup', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['walden farms pancake syrup', 'walden farms calorie free pancake syrup', 'walden farms zero calorie syrup', 'walden farms maple syrup'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (30g). Sugar-free, calorie-free. Saves ~220 cal vs regular pancake syrup per serving.', TRUE),

-- Walden Farms Alfredo Sauce: 0 cal per 1/4 cup (60g)
('walden_alfredo_sauce', 'Walden Farms Alfredo Sauce', 0, 0.0, 1.7, 0.0,
 1.7, 0.0, 60, NULL,
 'manufacturer', ARRAY['walden farms alfredo sauce', 'walden farms calorie free alfredo', 'walden farms zero calorie alfredo sauce', 'walden farms pasta sauce alfredo'],
 'condiment', 'Walden Farms', 1, '0 cal per 1/4 cup (60g). Sugar-free, dairy-free alfredo sauce. 0g net carbs (1g carb, 1g fiber per serving).', TRUE),

-- Walden Farms Marinara Sauce: 0 cal per 2 tbsp (28g)
('walden_marinara_sauce', 'Walden Farms Tomato Basil Marinara Sauce', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 28, NULL,
 'manufacturer', ARRAY['walden farms marinara', 'walden farms marinara sauce', 'walden farms tomato basil sauce', 'walden farms calorie free marinara', 'walden farms pasta sauce marinara'],
 'condiment', 'Walden Farms', 1, '0 cal per 2 tbsp (28g). Sugar-free, calorie-free tomato basil marinara. Vegan, gluten-free.', TRUE),

-- ══════════════════════════════════════════
-- G HUGHES — SUGAR-FREE SAUCES
-- ══════════════════════════════════════════

-- G Hughes Sugar-Free BBQ Sauce Original: 10 cal per 2 tbsp (33g)
('ghughes_bbq_original', 'G Hughes Sugar Free BBQ Sauce Original', 30, 0.0, 6.1, 0.0,
 0.0, 0.0, 33, NULL,
 'manufacturer', ARRAY['g hughes bbq sauce', 'g hughes original bbq', 'g hughes sugar free bbq sauce original', 'g hughes smokehouse bbq sauce'],
 'condiment', 'G Hughes', 1, '10 cal per 2 tbsp (33g). Sugar-free, gluten-free. 2g total carbs per serving.', TRUE),

-- G Hughes Sugar-Free BBQ Sauce Hickory: 10 cal per 2 tbsp (33g)
('ghughes_bbq_hickory', 'G Hughes Sugar Free BBQ Sauce Hickory', 30, 0.0, 6.1, 0.0,
 0.0, 0.0, 33, NULL,
 'manufacturer', ARRAY['g hughes hickory bbq', 'g hughes sugar free hickory bbq', 'g hughes smokehouse hickory bbq sauce', 'g hughes hickory bbq sauce'],
 'condiment', 'G Hughes', 1, '10 cal per 2 tbsp (33g). Sugar-free, gluten-free hickory-flavored BBQ sauce.', TRUE),

-- G Hughes Sugar-Free BBQ Sauce Honey: 10 cal per 2 tbsp (33g)
('ghughes_bbq_honey', 'G Hughes Sugar Free BBQ Sauce Honey', 30, 0.0, 6.1, 0.0,
 0.0, 0.0, 33, NULL,
 'manufacturer', ARRAY['g hughes honey bbq', 'g hughes sugar free honey bbq', 'g hughes smokehouse honey bbq sauce', 'g hughes honey bbq sauce'],
 'condiment', 'G Hughes', 1, '10 cal per 2 tbsp (33g). Sugar-free, gluten-free honey-flavored BBQ sauce.', TRUE),

-- G Hughes Sugar-Free BBQ Sauce Maple Brown: 10 cal per 2 tbsp (33g)
('ghughes_bbq_maple_brown', 'G Hughes Sugar Free BBQ Sauce Maple Brown', 30, 0.0, 6.1, 0.0,
 0.0, 0.0, 33, NULL,
 'manufacturer', ARRAY['g hughes maple brown bbq', 'g hughes sugar free maple brown bbq', 'g hughes smokehouse maple brown bbq sauce', 'g hughes maple brown'],
 'condiment', 'G Hughes', 1, '10 cal per 2 tbsp (33g). Sugar-free, gluten-free maple brown-flavored BBQ sauce.', TRUE),

-- G Hughes Sugar-Free Ketchup: 5 cal per 1 tbsp (17g)
('ghughes_ketchup', 'G Hughes Sugar Free Ketchup', 29, 0.0, 5.9, 0.0,
 0.0, 0.0, 17, NULL,
 'manufacturer', ARRAY['g hughes ketchup', 'g hughes sugar free ketchup', 'g hughes smokehouse ketchup', 'g hughes sf ketchup'],
 'condiment', 'G Hughes', 1, '5 cal per 1 tbsp (17g). Sugar-free, gluten-free. 1g carb per serving. No high fructose corn syrup.', TRUE),

-- G Hughes Sugar-Free Steak Sauce: 5 cal per 1 tbsp (17g)
('ghughes_steak_sauce', 'G Hughes Sugar Free Steak Sauce', 29, 0.0, 5.9, 0.0,
 0.0, 0.0, 17, NULL,
 'manufacturer', ARRAY['g hughes steak sauce', 'g hughes sugar free steak sauce', 'g hughes smokehouse steak sauce', 'g hughes sf steak sauce'],
 'condiment', 'G Hughes', 1, '5 cal per 1 tbsp (17g). Sugar-free, gluten-free steak sauce. 1g carb per serving.', TRUE),

-- ══════════════════════════════════════════
-- ZEVIA — ZERO-CALORIE SODAS (355ml / 12oz can)
-- ══════════════════════════════════════════

-- Zevia Cola: 0 cal per can (355ml)
('zevia_cola', 'Zevia Zero Sugar Cola', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['zevia cola', 'zevia zero sugar cola', 'zevia soda cola', 'zevia zero calorie cola'],
 'beverage', 'Zevia', 1, '0 cal per can (355ml, 12oz). Sweetened with stevia. No artificial sweeteners, colors or preservatives. Contains caffeine.', TRUE),

-- Zevia Ginger Root Beer: 0 cal per can (355ml)
('zevia_ginger_root_beer', 'Zevia Zero Sugar Ginger Root Beer', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['zevia ginger root beer', 'zevia root beer', 'zevia zero sugar root beer', 'zevia ginger beer'],
 'beverage', 'Zevia', 1, '0 cal per can (355ml, 12oz). Sweetened with stevia. Caffeine-free.', TRUE),

-- Zevia Cream Soda: 0 cal per can (355ml)
('zevia_cream_soda', 'Zevia Zero Sugar Cream Soda', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['zevia cream soda', 'zevia zero sugar cream soda', 'zevia soda cream', 'zevia cream'],
 'beverage', 'Zevia', 1, '0 cal per can (355ml, 12oz). Sweetened with stevia. Caffeine-free.', TRUE),

-- Zevia Grape: 0 cal per can (355ml)
('zevia_grape', 'Zevia Zero Sugar Grape', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['zevia grape', 'zevia grape soda', 'zevia zero sugar grape', 'zevia zero calorie grape'],
 'beverage', 'Zevia', 1, '0 cal per can (355ml, 12oz). Sweetened with stevia. Caffeine-free.', TRUE),

-- Zevia Black Cherry: 0 cal per can (355ml)
('zevia_black_cherry', 'Zevia Zero Sugar Black Cherry', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, NULL, 355,
 'manufacturer', ARRAY['zevia black cherry', 'zevia cherry', 'zevia zero sugar black cherry', 'zevia zero calorie black cherry'],
 'beverage', 'Zevia', 1, '0 cal per can (355ml, 12oz). Sweetened with stevia. Caffeine-free.', TRUE),

-- ══════════════════════════════════════════
-- CRYSTAL LIGHT — ON THE GO PACKETS
-- ══════════════════════════════════════════

-- Crystal Light On The Go Lemonade: 10 cal per packet (~2g)
('crystallight_lemonade', 'Crystal Light On The Go Lemonade', 500, 0.0, 100.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['crystal light lemonade', 'crystal light on the go lemonade', 'crystal light otg lemonade', 'crystal light lemonade packet'],
 'beverage', 'Crystal Light', 1, '10 cal per packet (~2g powder). Mix with 16oz water. Sugar-free, low sodium.', TRUE),

-- Crystal Light On The Go Fruit Punch: 5 cal per packet (~2g)
('crystallight_fruit_punch', 'Crystal Light On The Go Fruit Punch', 250, 0.0, 50.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['crystal light fruit punch', 'crystal light on the go fruit punch', 'crystal light otg fruit punch', 'crystal light fruit punch packet'],
 'beverage', 'Crystal Light', 1, '5 cal per packet (~2g powder). Mix with 16oz water. Sugar-free.', TRUE),

-- Crystal Light On The Go Peach Mango Green Tea: 5 cal per packet (~2g)
('crystallight_peach_mango', 'Crystal Light On The Go Peach Mango Green Tea', 250, 0.0, 50.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['crystal light peach mango green tea', 'crystal light peach mango', 'crystal light on the go peach mango', 'crystal light green tea peach mango'],
 'beverage', 'Crystal Light', 1, '5 cal per packet (~2g powder). Mix with 16oz water. Sugar-free, contains green tea.', TRUE),

-- Crystal Light On The Go Raspberry Lemonade: 5 cal per packet (~2g)
('crystallight_raspberry_lemonade', 'Crystal Light On The Go Raspberry Lemonade', 250, 0.0, 50.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['crystal light raspberry lemonade', 'crystal light on the go raspberry lemonade', 'crystal light otg raspberry lemonade', 'crystal light raspberry lemon'],
 'beverage', 'Crystal Light', 1, '5 cal per packet (~2g powder). Mix with 16oz water. Sugar-free.', TRUE),

-- ══════════════════════════════════════════
-- MIO — WATER ENHANCERS
-- ══════════════════════════════════════════

-- Mio Berry Pomegranate: 0 cal per squeeze (~2g)
('mio_berry', 'Mio Water Enhancer Berry Pomegranate', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['mio berry', 'mio berry pomegranate', 'mio water enhancer berry', 'mio liquid water enhancer berry'],
 'beverage', 'Mio', 1, '0 cal per squeeze (~2g). Sugar-free liquid water enhancer. Makes 8 fl oz.', TRUE),

-- Mio Lemonade: 0 cal per squeeze (~2g)
('mio_lemonade', 'Mio Water Enhancer Lemonade', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['mio lemonade', 'mio water enhancer lemonade', 'mio liquid lemonade', 'mio liquid water enhancer lemonade'],
 'beverage', 'Mio', 1, '0 cal per squeeze (~2g). Sugar-free liquid water enhancer. Makes 8 fl oz.', TRUE),

-- Mio Fruit Punch: 0 cal per squeeze (~2g)
('mio_fruit_punch', 'Mio Water Enhancer Fruit Punch', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['mio fruit punch', 'mio water enhancer fruit punch', 'mio liquid fruit punch', 'mio liquid water enhancer fruit punch'],
 'beverage', 'Mio', 1, '0 cal per squeeze (~2g). Sugar-free liquid water enhancer. Makes 8 fl oz.', TRUE),

-- ══════════════════════════════════════════
-- SWEETENERS
-- ══════════════════════════════════════════

-- Stevia In The Raw: 0 cal per packet (1g)
('stevia_in_the_raw', 'Stevia In The Raw Sweetener', 0, 0.0, 100.0, 0.0,
 0.0, 0.0, NULL, 1,
 'manufacturer', ARRAY['stevia in the raw', 'stevia raw', 'stevia in the raw packet', 'stevia in the raw sweetener packet'],
 'sweetener', 'Stevia In The Raw', 1, '0 cal per packet (1g). Zero-calorie stevia-based sweetener. Each packet equals sweetness of 2 tsp sugar.', TRUE),

-- Splenda Original: 0 cal per packet (1g)
('splenda_original', 'Splenda Original Sweetener', 0, 0.0, 100.0, 0.0,
 0.0, 0.0, NULL, 1,
 'manufacturer', ARRAY['splenda', 'splenda original', 'splenda packet', 'splenda sweetener', 'splenda no calorie sweetener'],
 'sweetener', 'Splenda', 1, '0 cal per packet (1g). Sucralose-based zero-calorie sweetener. Each packet equals sweetness of 2 tsp sugar.', TRUE),

-- Monk Fruit In The Raw: 0 cal per packet (0.8g)
('monk_fruit_in_the_raw', 'Monk Fruit In The Raw Sweetener', 0, 0.0, 100.0, 0.0,
 0.0, 0.0, NULL, 1,
 'manufacturer', ARRAY['monk fruit in the raw', 'monk fruit raw', 'monk fruit in the raw packet', 'monk fruit sweetener packet'],
 'sweetener', 'Monk Fruit In The Raw', 1, '0 cal per packet (~0.8g). Zero-calorie monk fruit extract sweetener. Each packet equals sweetness of 2 tsp sugar.', TRUE),

-- Swerve Sweetener: 0 cal per tsp (4g)
('swerve_sweetener', 'Swerve Granular Sweetener', 0, 0.0, 100.0, 0.0,
 0.0, 0.0, 4, NULL,
 'manufacturer', ARRAY['swerve sweetener', 'swerve granular', 'swerve sugar replacement', 'swerve zero calorie sweetener', 'swerve erythritol sweetener'],
 'sweetener', 'Swerve', 1, '0 cal per tsp (4g). Zero-calorie erythritol-based sweetener. 0g net carbs. Measures like sugar 1:1.', TRUE),

-- ══════════════════════════════════════════
-- PRIMAL KITCHEN — AVOCADO OIL DRESSINGS
-- ══════════════════════════════════════════

-- Primal Kitchen Ranch Dressing: 120 cal per 2 tbsp (30g)
('primal_ranch', 'Primal Kitchen Ranch Dressing', 400, 0.0, 6.7, 43.3,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['primal kitchen ranch', 'primal kitchen ranch dressing', 'primal kitchen avocado oil ranch', 'primal ranch dressing'],
 'condiment', 'Primal Kitchen', 1, '120 cal per 2 tbsp (30g). Made with avocado oil. Dairy-free, sugar-free, no seed oils. 13g fat, 2g carbs per serving.', TRUE),

-- Primal Kitchen Caesar Dressing: 130 cal per 2 tbsp (30g)
('primal_caesar', 'Primal Kitchen Caesar Dressing', 433, 0.0, 3.3, 46.7,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['primal kitchen caesar', 'primal kitchen caesar dressing', 'primal kitchen avocado oil caesar', 'primal caesar dressing'],
 'condiment', 'Primal Kitchen', 1, '130 cal per 2 tbsp (30g). Made with avocado oil. Dairy-free, no seed oils. 14g fat, 1g carbs per serving.', TRUE),

-- Primal Kitchen Green Goddess Dressing: 130 cal per 2 tbsp (30g)
('primal_green_goddess', 'Primal Kitchen Green Goddess Dressing', 433, 0.0, 6.7, 46.7,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['primal kitchen green goddess', 'primal kitchen green goddess dressing', 'primal kitchen avocado oil green goddess', 'primal green goddess dressing'],
 'condiment', 'Primal Kitchen', 1, '130 cal per 2 tbsp (30g). Made with avocado oil. Dairy-free, Whole30 approved. 14g fat, 2g carbs per serving.', TRUE)

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
