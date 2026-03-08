-- 1590_puffs_sweets_variants.sql
-- Adds missing puffs and Hyderabadi sweets, and expands variant_names for existing sweets.
-- All values per 100g. Sources: IFCT 2017, snapcalorie, nutritionix, tarladalal, fatsecret

-- ═══════════════════════════════════════════════════════════════════
-- PART A: NEW ENTRIES (puffs + regional sweets)
-- ═══════════════════════════════════════════════════════════════════

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

-- Veg Puff (Indian bakery style)
('veg_puff', 'Veg Puff (Indian Bakery)', 290.0, 4.5, 32.0, 15.0,
 2.0, 1.5, 80, 80,
 'indian_traditional', ARRAY['veg puff', 'vegetable puff', 'veg patty', 'bakery veg puff',
   'potato puff', 'aloo puff', 'veg puff pastry', 'veg puffs',
   '1 veg puff', 'one veg puff'],
 'indian', NULL, 1, 'Per 100g. ~232 cal per puff (~80g). Flaky pastry with spiced potato-pea filling. Indian bakery staple.', TRUE,
 350, 5, 5.0, 0.2, 120, 20, 1.0, 15, 3.0, 0, 12, 0.4, 40, 2.0, 0.01),

-- Paneer Puff
('paneer_puff', 'Paneer Puff', 330.0, 10.0, 30.0, 18.0,
 1.5, 2.0, 90, 90,
 'indian_traditional', ARRAY['paneer puff', 'paneer patty', 'paneer puff pastry',
   'cottage cheese puff', 'paneer masala puff', 'paneer puffs',
   '1 paneer puff'],
 'indian', NULL, 1, 'Per 100g. ~297 cal per puff (~90g). Flaky pastry with spiced paneer filling. Higher protein than veg puff.', TRUE,
 320, 15, 7.0, 0.2, 100, 60, 0.8, 20, 1.0, 0, 15, 0.5, 55, 2.0, 0.01),

-- Mushroom Puff
('mushroom_puff', 'Mushroom Puff', 250.0, 5.0, 20.0, 15.0,
 1.5, 1.5, 80, 80,
 'indian_traditional', ARRAY['mushroom puff', 'mushroom patty', 'mushroom puff pastry',
   'mushroom puffs', '1 mushroom puff'],
 'indian', NULL, 1, 'Per 100g. ~200 cal per puff (~80g). Flaky pastry with sauteed mushroom filling. Lighter than veg/paneer puffs.', TRUE,
 300, 5, 5.0, 0.1, 180, 15, 0.8, 5, 2.0, 0, 10, 0.5, 45, 3.0, 0.01),

-- Double ka Meetha (Hyderabadi bread pudding)
('double_ka_meetha', 'Double ka Meetha (Hyderabadi Bread Pudding)', 360.0, 6.0, 45.0, 16.0,
 0.3, 30.0, 120, NULL,
 'indian_traditional', ARRAY['double ka meetha', 'double ka metha', 'shahi tukda', 'shahi tukra',
   'bread pudding indian', 'hyderabadi double ka meetha',
   'fried bread dessert'],
 'indian', NULL, 1, 'Per 100g. ~432 cal per serving (~120g). Deep-fried bread soaked in condensed milk with rabri, saffron, nuts. Iconic Hyderabadi dessert.', TRUE,
 120, 30, 6.0, 0.2, 140, 80, 0.5, 40, 0.5, 5, 15, 0.4, 60, 2.0, 0.01)

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
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active,
  sodium_mg = EXCLUDED.sodium_mg,
  cholesterol_mg = EXCLUDED.cholesterol_mg,
  saturated_fat_g = EXCLUDED.saturated_fat_g,
  trans_fat_g = EXCLUDED.trans_fat_g,
  potassium_mg = EXCLUDED.potassium_mg,
  calcium_mg = EXCLUDED.calcium_mg,
  iron_mg = EXCLUDED.iron_mg,
  vitamin_a_ug = EXCLUDED.vitamin_a_ug,
  vitamin_c_mg = EXCLUDED.vitamin_c_mg,
  vitamin_d_iu = EXCLUDED.vitamin_d_iu,
  magnesium_mg = EXCLUDED.magnesium_mg,
  zinc_mg = EXCLUDED.zinc_mg,
  phosphorus_mg = EXCLUDED.phosphorus_mg,
  selenium_ug = EXCLUDED.selenium_ug,
  omega3_g = EXCLUDED.omega3_g,
  updated_at = NOW();


-- ═══════════════════════════════════════════════════════════════════
-- PART B: EXPAND VARIANT NAMES FOR EXISTING SWEETS & PUFFS
-- ═══════════════════════════════════════════════════════════════════

-- generic_jalebi — add common search terms
-- Existing: ['jalebi', 'jilapi', 'zulbia', 'imarti']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'jalebi', 'jilapi', 'zulbia', 'imarti',
  'jalebi sweet', 'jilebi', 'plain jalebi',
  'hot jalebi', 'crispy jalebi', '1 jalebi', 'one jalebi'
] WHERE food_name_normalized = 'generic_jalebi';

-- gulab_jamun — add common search terms
-- Existing: ['gulab jaman', 'gulaab jamun', 'rose berry dessert']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'gulab jaman', 'gulaab jamun', 'rose berry dessert',
  'gulab jamun', 'gulab jamun sweet', 'gulab jaamun',
  '1 gulab jamun', 'one gulab jamun', '2 gulab jamun',
  'milk ball dessert', 'gulab jamun piece'
] WHERE food_name_normalized = 'gulab_jamun';

-- generic_rasgulla — add common search terms
-- Existing: ['rasgulla', 'rasogolla', 'rasgolla', 'rosogolla']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'rasgulla', 'rasogolla', 'rasgolla', 'rosogolla',
  'rasgulla sweet', 'chhena ball', 'paneer ball sweet',
  '1 rasgulla', 'one rasgulla', '2 rasgulla'
] WHERE food_name_normalized = 'generic_rasgulla';

-- generic_kaju_katli — add common search terms
-- Existing: ['kaju katli', 'kaju barfi', 'cashew barfi', 'kaju katri']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kaju katli', 'kaju barfi', 'cashew barfi', 'kaju katri',
  'kaju katli sweet', 'cashew fudge', 'kaju burfi',
  'kaju slice', '1 kaju katli', 'kaju katli piece'
] WHERE food_name_normalized = 'generic_kaju_katli';

-- generic_besan_laddu — add common search terms
-- Existing: ['besan laddu', 'besan ladoo', 'gram flour laddu', 'besan ke laddu']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'besan laddu', 'besan ladoo', 'gram flour laddu', 'besan ke laddu',
  'besan laddoo', 'besan ka ladoo', 'chickpea flour ladoo',
  '1 besan ladoo', 'one ladoo', '1 ladoo', 'one laddu', '1 laddu'
] WHERE food_name_normalized = 'generic_besan_laddu';

-- generic_motichoor_laddu — add common search terms
-- Existing: ['motichoor laddu', 'motichoor ladoo', 'motichur laddu']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'motichoor laddu', 'motichoor ladoo', 'motichur laddu',
  'motichoor laddoo', 'motichur ladoo', 'boondi ladoo',
  'boondi laddu', '1 motichoor ladoo'
] WHERE food_name_normalized = 'generic_motichoor_laddu';

-- generic_peda — add common search terms
-- Existing: ['peda', 'peda sweet', 'mathura peda', 'milk peda', 'doodh peda']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'peda', 'peda sweet', 'mathura peda', 'milk peda', 'doodh peda',
  'kesar peda', 'saffron peda', 'dharwad peda',
  '1 peda', 'one peda', 'peda piece'
] WHERE food_name_normalized = 'generic_peda';

-- generic_kheer — add common search terms
-- Existing: ['kheer', 'rice kheer', 'payasam', 'rice pudding indian', 'chawal ki kheer']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kheer', 'rice kheer', 'payasam', 'rice pudding indian', 'chawal ki kheer',
  'kheer sweet', 'dudh ki kheer', 'rice payasam',
  'paal payasam', 'semiya payasam',
  '1 bowl kheer', 'bowl of kheer'
] WHERE food_name_normalized = 'generic_kheer';

-- generic_rasmalai — add common search terms
-- Existing: ['rasmalai', 'ras malai', 'rossomalai', 'roshmalai']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'rasmalai', 'ras malai', 'rossomalai', 'roshmalai',
  'rasmalai sweet', 'ras malai sweet', 'kesar rasmalai',
  '1 rasmalai', 'one rasmalai', '2 rasmalai'
] WHERE food_name_normalized = 'generic_rasmalai';

-- generic_egg_puff — add more variants
-- Existing: ['egg puff', 'egg patty', 'anda puff', 'egg puff pastry']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'egg puff', 'egg patty', 'anda puff', 'egg puff pastry',
  'egg puffs', 'bakery egg puff', '1 egg puff', 'one egg puff'
] WHERE food_name_normalized = 'generic_egg_puff';

-- generic_chicken_puff — add more variants
-- Existing: ['chicken puff', 'chicken patty', 'murgh puff', 'chicken puff pastry']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chicken puff', 'chicken patty', 'murgh puff', 'chicken puff pastry',
  'chicken puffs', 'bakery chicken puff', '1 chicken puff', 'one chicken puff'
] WHERE food_name_normalized = 'generic_chicken_puff';

-- apricot_delight — add qubani ka meetha variants
-- Existing: ['khubani ka meetha', 'apricot dessert', 'hyderabadi apricot sweet']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'khubani ka meetha', 'apricot dessert', 'hyderabadi apricot sweet',
  'qubani ka meetha', 'qubani ka metha', 'kubani ka meetha',
  'apricot sweet', 'dried apricot dessert'
] WHERE food_name_normalized = 'apricot_delight';

-- mysore_pak — add common search terms
-- Existing: ['mysore pak', 'mysore pa', 'ghee mysore pak', 'soft mysore pak', 'ಮೈಸೂರು ಪಾಕ್']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'mysore pak', 'mysore pa', 'ghee mysore pak', 'soft mysore pak', 'ಮೈಸೂರು ಪಾಕ್',
  'mysuru pak', 'mysorepak', 'mysore pak sweet',
  '1 mysore pak', 'mysore pak piece'
] WHERE food_name_normalized = 'mysore_pak';

-- generic_soan_papdi — add common search terms
-- Existing: ['soan papdi', 'son papdi', 'patisa', 'sohan papdi', 'flaky sweet']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'soan papdi', 'son papdi', 'patisa', 'sohan papdi', 'flaky sweet',
  'soan papdi sweet', '1 soan papdi', 'soan papdi piece'
] WHERE food_name_normalized = 'generic_soan_papdi';
