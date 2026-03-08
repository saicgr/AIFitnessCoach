-- 1589_missing_indian_snacks.sql
-- Adds missing Telugu/South Indian snacks to food_nutrition_overrides
-- and expands variant_names for existing snack entries.
-- All values per 100g. Sources: IFCT 2017, snapcalorie.com, nutritionix, tarladalal.com

-- ═══════════════════════════════════════════════════════════════════
-- PART A: NEW SNACK ENTRIES (INSERT)
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

-- Punugulu: Deep-fried idli/dosa batter fritters. ~250 cal/100g. ~25g per piece.
('punugulu', 'Punugulu (Fried Batter Balls)', 250.0, 5.0, 35.0, 10.0,
 2.0, 2.0, 125, 25,
 'indian_traditional', ARRAY['punugulu', 'punukulu', 'pungulu', 'goli bajji andhra', 'batter balls',
   'crispy punugulu', 'dosa batter fritters', 'idli batter fritters',
   'punugulu snack', 'andhra punugulu', 'telugu punugulu'],
 'indian', NULL, 5, 'Per 100g. ~63 cal per piece (~25g). Deep-fried idli/dosa batter balls with onion, chilli, curry leaves. Popular Andhra/Telangana rainy-day snack.', TRUE,
 300, 0, 1.5, 0.0, 120, 20, 1.0, 5, 2.0, 0, 18, 0.4, 55, 1.5, 0.01),

-- Mirapakaya Bajji (Stuffed Chilli Bajji - Telugu style, thicker than generic mirchi bajji)
('mirapakaya_bajji', 'Mirapakaya Bajji (Telugu Stuffed Chilli Fritter)', 230.0, 5.0, 26.0, 12.0,
 3.0, 2.0, 100, 50,
 'indian_traditional', ARRAY['mirapakaya bajji', 'mirapakaya bajji telugu', 'mirchi bajji telugu',
   'stuffed mirchi bajji', 'stuffed chilli bajji', 'chilli bajji andhra',
   'green chilli fritter'],
 'indian', NULL, 2, 'Per 100g. ~115 cal per piece (~50g). Besan-battered green chilli stuffed with spiced potato, deep-fried. Andhra tea-time staple.', TRUE,
 280, 0, 1.8, 0.0, 180, 25, 1.2, 30, 65.0, 0, 20, 0.5, 60, 1.0, 0.01),

-- Boorelu (Sweet Stuffed Rice Balls)
('boorelu', 'Boorelu (Sweet Stuffed Rice Balls)', 340.0, 5.0, 52.0, 12.0,
 2.0, 20.0, 100, 40,
 'indian_traditional', ARRAY['boorelu', 'poornalu', 'poornam boorelu', 'purnam boorelu',
   'sweet stuffed rice balls', 'boorelu telugu', 'bobbatlu balls',
   'andhra boorelu'],
 'indian', NULL, 2, 'Per 100g. ~136 cal per piece (~40g). Rice flour shell with sweet chana dal + jaggery + coconut filling. Deep-fried Telugu festival sweet.', TRUE,
 80, 0, 2.0, 0.0, 150, 30, 1.5, 5, 1.0, 0, 25, 0.6, 80, 2.0, 0.01),

-- Kajjikayalu (Sweet Stuffed Pastry)
('kajjikayalu', 'Kajjikayalu (Sweet Fried Pastry)', 380.0, 5.5, 50.0, 18.0,
 1.5, 22.0, 80, 30,
 'indian_traditional', ARRAY['kajjikayalu', 'karanji', 'gujiya andhra', 'kajjikaya',
   'sweet samosa telugu', 'karjikai', 'nevri',
   'kajjikayalu telugu'],
 'indian', NULL, 2, 'Per 100g. ~114 cal per piece (~30g). Maida pastry stuffed with coconut + sugar/jaggery, deep-fried. Sankranti and Diwali sweet.', TRUE,
 60, 5, 4.0, 0.1, 100, 18, 0.8, 2, 0.5, 0, 15, 0.4, 45, 1.0, 0.01),

-- Sarva Pindi (Telangana Rice Flour Pancake)
('sarva_pindi', 'Sarva Pindi (Telangana Rice Pancake)', 280.0, 6.0, 38.0, 12.0,
 2.5, 1.0, 120, 120,
 'indian_traditional', ARRAY['sarva pindi', 'ginne appa', 'sarvapindi', 'sarva pindi telangana',
   'rice flour pancake telangana', 'rice roti telangana'],
 'indian', NULL, 1, 'Per 100g. ~336 cal per piece (~120g). Rice flour + chana dal + peanuts cooked on griddle with oil. Telangana breakfast special.', TRUE,
 220, 0, 1.8, 0.0, 180, 25, 1.5, 5, 1.0, 0, 30, 0.8, 90, 2.5, 0.02),

-- Chegodilu (Savory Rice Flour Rings)
('chegodilu', 'Chegodilu (Rice Flour Rings)', 450.0, 6.0, 58.0, 22.0,
 2.0, 1.0, 30, 15,
 'indian_traditional', ARRAY['chegodilu', 'chegodi', 'chekodi', 'ring murukku telugu',
   'chegodilu snack', 'chegodilu telugu'],
 'indian', NULL, 2, 'Per 100g. ~68 cal per piece (~15g). Deep-fried rice flour rings with sesame and cumin. Crunchy Telugu festival snack.', TRUE,
 250, 0, 3.0, 0.1, 90, 40, 1.5, 1, 0.0, 0, 25, 0.7, 55, 2.0, 0.01),

-- Uggani (Puffed Rice Upma)
('uggani', 'Uggani (Spiced Puffed Rice)', 180.0, 4.0, 30.0, 5.5,
 2.0, 1.0, 150, NULL,
 'indian_traditional', ARRAY['uggani', 'borugula upma', 'puffed rice upma', 'murmura upma',
   'uggani telugu', 'spiced puffed rice'],
 'indian', NULL, 1, 'Per 100g. ~270 cal per plate (~150g). Tempered puffed rice with peanuts, onion, curry leaves. Quick Telugu breakfast/snack.', TRUE,
 280, 0, 0.8, 0.0, 140, 15, 1.0, 5, 3.0, 0, 20, 0.5, 60, 1.5, 0.01),

-- Atukulu Upma (Flattened Rice Upma - Telugu style Poha)
('atukulu_upma', 'Atukulu Upma (Telugu Poha)', 155.0, 3.0, 26.0, 4.5,
 1.5, 1.0, 200, NULL,
 'indian_traditional', ARRAY['atukulu upma', 'atukulu', 'aval upma', 'telugu poha',
   'flattened rice upma', 'beaten rice telugu'],
 'indian', NULL, 1, 'Per 100g. ~310 cal per plate (~200g). Tempered flattened rice with peanuts, mustard, curry leaves. Telugu everyday breakfast.', TRUE,
 240, 0, 0.6, 0.0, 130, 12, 1.5, 5, 2.0, 0, 18, 0.4, 50, 1.2, 0.01),

-- Uppudi Pindi (Semolina Upma - Telugu)
('uppudi_pindi', 'Uppudi Pindi (Rava Upma)', 130.0, 3.5, 20.0, 4.0,
 1.0, 0.5, 200, NULL,
 'indian_traditional', ARRAY['uppudi pindi', 'upma telugu', 'rava upma', 'suji upma',
   'semolina upma', 'uppindi', 'upma south indian'],
 'indian', NULL, 1, 'Per 100g. ~260 cal per plate (~200g). Semolina cooked with veggies, peanuts, mustard tempering. South Indian breakfast staple.', TRUE,
 280, 0, 0.6, 0.0, 100, 15, 0.8, 10, 3.0, 0, 15, 0.4, 55, 2.0, 0.01)

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
-- PART B: ADD VARIANT NAMES TO EXISTING SNACK ENTRIES
-- ═══════════════════════════════════════════════════════════════════

-- vada (key: 'vada', from 270) — add Telugu/regional names
-- Existing: ['medu vada', 'urad vada', 'vadai']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'medu vada', 'urad vada', 'vadai',
  'garelu', 'minapa garelu', 'minapa vada',
  'ulundu vadai', 'ulundu vada',
  'uzhunnu vada', 'urad dal vada',
  '1 vada', 'one vada', 'two vada', '2 vada',
  'crispy vada', 'south indian vada'
] WHERE food_name_normalized = 'vada';

-- generic_mirchi_bajji — add more Telugu variants
-- Existing: ['mirchi bajji', 'mirchi pakora', 'mirchi bhaji', 'stuffed chilli fritter', 'bharwan mirch pakora', 'milagai bajji']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'mirchi bajji', 'mirchi pakora', 'mirchi bhaji', 'stuffed chilli fritter', 'bharwan mirch pakora', 'milagai bajji',
  'chilli bajji', 'bajji', 'green chilli bajji',
  '1 bajji', 'one bajji'
] WHERE food_name_normalized = 'generic_mirchi_bajji';

-- generic_aloo_bonda — add more variants
-- Existing: ['aloo bonda', 'mysore bonda', 'batata vada', 'bonda', 'potato bonda', 'goli baje']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'aloo bonda', 'mysore bonda', 'batata vada', 'bonda', 'potato bonda', 'goli baje',
  'potato ball', 'aloo ball', 'deep fried potato ball',
  '1 bonda', 'one bonda'
] WHERE food_name_normalized = 'generic_aloo_bonda';

-- generic_onion_pakora — add variants
-- Existing: ['onion pakora', 'pyaz pakoda', 'kanda bhajji', 'onion bhaji', 'pakoda', 'vengaya pakoda']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'onion pakora', 'pyaz pakoda', 'kanda bhajji', 'onion bhaji', 'pakoda', 'vengaya pakoda',
  'pakodi', 'onion pakodi', 'pakora',
  'ulli pakodi', 'onion fritter',
  '1 pakora', 'one pakora'
] WHERE food_name_normalized = 'generic_onion_pakora';

-- samosa (key: 'samosa', from 270) — add more variants
-- Current (from 1588): ['veg samosa', 'aloo samosa', 'potato samosa', 'vegetable samosa', 'fried samosa', 'deep fried samosa', '1 samosa', 'one samosa', 'two samosa', '2 samosa', 'samosa snack']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'veg samosa', 'aloo samosa', 'potato samosa',
  'vegetable samosa', 'fried samosa', 'deep fried samosa',
  '1 samosa', 'one samosa', 'two samosa', '2 samosa',
  'samosa snack', 'samosa chaat'
] WHERE food_name_normalized = 'samosa';
