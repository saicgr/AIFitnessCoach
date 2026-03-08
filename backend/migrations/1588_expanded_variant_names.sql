-- 1588_expanded_variant_names.sql
-- Adds missing common user-typed variant names to food_nutrition_overrides.
-- Fixes exact-match lookup failures for common phrases like "boiled rice", "ridge gourd", etc.
-- Each UPDATE replaces the entire variant_names array, so ALL existing + new variants are included.

-- ═══════════════════════════════════════════════════════════════════
-- CRITICAL: Staple Foods (most-searched, currently failing)
-- ═══════════════════════════════════════════════════════════════════

-- rice (key: 'rice', from 270)
-- Existing: ['white rice', 'cooked rice', 'steamed rice', 'plain rice']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'white rice', 'cooked rice', 'steamed rice', 'plain rice',
  'boiled rice', 'hot rice', 'warm rice',
  'basmati rice', 'basmati rice cooked', 'cooked basmati',
  'boiled white rice', 'plain white rice', 'cooked white rice',
  'jasmine rice', 'long grain rice',
  'chawal', 'bhat', 'annam',
  'rice bowl', '1 cup rice', 'one cup rice',
  'plate rice', 'rice plate'
] WHERE food_name_normalized = 'rice';

-- steamed_rice (key: 'steamed_rice', from 1579 INSERT)
-- Existing: ['steamed rice', 'plain steamed rice', 'white steamed rice', 'rice steamed']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'steamed rice', 'plain steamed rice', 'white steamed rice', 'rice steamed',
  'boiled rice plain', 'steam rice', 'simple rice', 'just rice'
] WHERE food_name_normalized = 'steamed_rice';

-- brown rice (key: 'brown rice', from 270 — note: space in key)
-- Existing: ['cooked brown rice']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cooked brown rice',
  'brown rice cooked', 'brown rice plain', 'boiled brown rice',
  'whole grain rice', 'brown basmati rice',
  'brown rice bowl', '1 cup brown rice'
] WHERE food_name_normalized = 'brown rice';

-- dal (key: 'dal', from 270)
-- Existing: ['dhal', 'daal', 'lentil curry', 'toor dal', 'moong dal']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'dhal', 'daal', 'lentil curry', 'toor dal', 'moong dal',
  'plain dal', 'plain daal', 'simple dal', 'boiled dal',
  'cooked lentils', 'yellow dal', 'yellow daal',
  'red dal', 'red lentil dal', 'masoor dal',
  'urad dal', 'chana dal', 'mix dal', 'mixed dal',
  'arhar dal', 'dal fry', 'dal plain',
  'lentil soup', 'lentils cooked', 'pappu',
  '1 cup dal', 'bowl of dal', 'dal bowl'
] WHERE food_name_normalized = 'dal';

-- beerakaya_curry (key: 'beerakaya_curry', from 1000)
-- Existing: ['ridge gourd curry', 'beerakaya koora', 'peerkangai kootu', 'turai sabzi', 'beerakaya pappu']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'ridge gourd curry', 'beerakaya koora', 'peerkangai kootu', 'turai sabzi', 'beerakaya pappu',
  'ridge gourd', 'ridge gourd sabzi', 'ridge gourd vegetable',
  'turai curry', 'turai', 'beerakaya',
  'peerkangai', 'jhinga', 'gilki',
  'torai sabzi', 'cooked ridge gourd', 'ridge gourd cooked'
] WHERE food_name_normalized = 'beerakaya_curry';

-- kozhukattai (key: 'kozhukattai', from 1000b)
-- Existing: ['kozhukattai', 'kozhukkattai', 'modak', 'kolukattai', 'pidi kozhukattai', 'கொழுக்கட்டை', 'കൊഴുക്കട്ട']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kozhukattai', 'kozhukkattai', 'modak', 'kolukattai', 'pidi kozhukattai',
  'கொழுக்கட்டை', 'കൊഴുക്കട്ട',
  'steamed dumpling',
  'rice dumpling', 'rice dumplings',
  'sweet dumpling', 'sweet dumplings',
  'modak sweet', 'rice flour dumpling',
  'south indian dumpling', 'steamed modak'
] WHERE food_name_normalized = 'kozhukattai';


-- ═══════════════════════════════════════════════════════════════════
-- HIGH: Common Indian Foods
-- ═══════════════════════════════════════════════════════════════════

-- roti (key: 'roti', from 270)
-- Existing: ['chapati', 'chapatti', 'phulka', 'wheat roti']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chapati', 'chapatti', 'phulka', 'wheat roti',
  'plain roti', 'rotli', 'plain chapati', 'soft roti',
  'homemade roti', 'home made roti',
  'indian flatbread', 'wheat flatbread',
  'fulka', 'tawa roti',
  '1 roti', 'one roti', 'two roti', '2 roti'
] WHERE food_name_normalized = 'roti';

-- paratha (key: 'paratha', from 270)
-- Existing: ['parantha', 'plain paratha', 'wheat paratha']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'parantha', 'plain paratha', 'wheat paratha',
  'paratha plain', 'parathas', 'prata',
  'parantha plain', 'pan fried paratha',
  'tawa paratha', 'layered paratha',
  '1 paratha', 'one paratha', 'butter paratha'
] WHERE food_name_normalized = 'paratha';

-- idli (key: 'idli', from 270)
-- Existing: ['idly', 'rice idli']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'idly', 'rice idli',
  'plain idli', 'steamed idli', 'idli plain', 'soft idli',
  'idli steamed', '1 idli', 'one idli', 'two idli', '2 idli',
  'rice cake south indian'
] WHERE food_name_normalized = 'idli';

-- dosa (key: 'dosa', from 270)
-- Existing: ['dosai', 'thosai', 'plain dosa']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'dosai', 'thosai', 'plain dosa',
  'dosa plain', 'crispy dosa', 'soft dosa', 'thin dosa',
  '1 dosa', 'one dosa', 'sada dosa'
] WHERE food_name_normalized = 'dosa';

-- samosa (key: 'samosa', from 270)
-- Existing: ['veg samosa', 'aloo samosa', 'potato samosa']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'veg samosa', 'aloo samosa', 'potato samosa',
  'vegetable samosa', 'fried samosa', 'deep fried samosa',
  '1 samosa', 'one samosa', 'two samosa', '2 samosa',
  'samosa snack'
] WHERE food_name_normalized = 'samosa';

-- paneer (key: 'paneer', from 270)
-- Existing: ['cottage cheese', 'indian cheese']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cottage cheese', 'indian cheese',
  'paneer plain', 'fresh paneer', 'paneer cheese',
  'raw paneer', 'paneer cubes', '100g paneer', 'homemade paneer'
] WHERE food_name_normalized = 'paneer';

-- chole (key: 'chole', from 270)
-- Existing: ['chana masala', 'chhole', 'chickpea curry']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chana masala', 'chhole', 'chickpea curry',
  'chole curry', 'chana curry', 'chana',
  'chickpea', 'chickpeas', 'cooked chickpea', 'boiled chickpea',
  'chickpeas cooked', 'kabuli chana', 'chole masala'
] WHERE food_name_normalized = 'chole';

-- rajma (key: 'rajma', from 270)
-- Existing: ['kidney bean curry', 'rajma masala']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kidney bean curry', 'rajma masala',
  'rajma curry', 'rajma cooked', 'cooked rajma',
  'red bean curry'
] WHERE food_name_normalized = 'rajma';

-- egg (key: 'egg', from 270)
-- Existing: ['eggs', 'whole egg', 'hen egg', 'chicken egg', 'boiled egg', 'fried egg']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'eggs', 'whole egg', 'hen egg', 'chicken egg', 'boiled egg', 'fried egg',
  '1 egg', 'one egg', 'two eggs', '2 eggs',
  'large egg', 'medium egg',
  'egg scrambled',
  'poached egg', 'hard boiled egg', 'soft boiled egg',
  'egg boiled', 'egg fried',
  'half fry egg', 'half fry',
  'anda', 'anda fry'
] WHERE food_name_normalized = 'egg';

-- chicken breast (key: 'chicken breast', from 270 — note: space in key)
-- Existing: ['grilled chicken breast', 'baked chicken breast', 'cooked chicken breast']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'grilled chicken breast', 'baked chicken breast', 'cooked chicken breast',
  'plain chicken breast', 'boiled chicken breast', 'steamed chicken breast',
  'boneless chicken breast', 'skinless chicken breast',
  'chicken breast plain', 'chicken breast cooked'
] WHERE food_name_normalized = 'chicken breast';


-- ═══════════════════════════════════════════════════════════════════
-- MEDIUM: South Indian / Regional Foods
-- ═══════════════════════════════════════════════════════════════════

-- sorakaya_curry (key: 'sorakaya_curry', from 1000)
-- Existing: ['bottle gourd curry', 'lauki curry', 'sorakaya koora', 'suraikkai kootu', 'anapakaya curry']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'bottle gourd curry', 'lauki curry', 'sorakaya koora', 'suraikkai kootu', 'anapakaya curry',
  'bottle gourd', 'lauki', 'lauki sabzi',
  'ghiya curry', 'dudhi',
  'cooked bottle gourd', 'bottle gourd vegetable'
] WHERE food_name_normalized = 'sorakaya_curry';

-- mudda_pappu (key: 'mudda_pappu', from 1000)
-- Existing: ['plain toor dal', 'arhar dal', 'mudda pappu andhra', 'parippu', 'toor dal boiled', 'kandi pappu']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'plain toor dal', 'arhar dal', 'mudda pappu andhra', 'parippu', 'toor dal boiled', 'kandi pappu',
  'plain arhar dal', 'boiled toor dal', 'boiled arhar dal',
  'simple toor dal', 'toor dal plain', 'pappu plain'
] WHERE food_name_normalized = 'mudda_pappu';

-- pesarattu (key: 'pesarattu', from 1000)
-- Existing: ['green moong dosa', 'pesarattu andhra', 'pesara dosa', 'moong dal dosa', 'green gram crepe', 'pesara attu']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'green moong dosa', 'pesarattu andhra', 'pesara dosa', 'moong dal dosa', 'green gram crepe', 'pesara attu',
  'green lentil dosa', 'moong dal crepe', 'moong dosa',
  'green gram dosa', 'pesarattu dosa'
] WHERE food_name_normalized = 'pesarattu';

-- sambar_rice (key: 'sambar_rice', from 1000b — no standalone 'sambar' exists)
-- Existing: ['sambar rice', 'sambar sadam', 'sambar sadham', 'sambhar rice', 'சாம்பார் சாதம்']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'sambar rice', 'sambar sadam', 'sambar sadham', 'sambhar rice', 'சாம்பார் சாதம்',
  'sambhar', 'sambar plain', 'sambar curry',
  'lentil vegetable curry', 'south indian sambar'
] WHERE food_name_normalized = 'sambar_rice';

-- rasam_rice (key: 'rasam_rice', from 1000b — no standalone 'rasam' exists)
-- Existing: ['rasam rice', 'rasam sadam', 'rasam sadham', 'chaaru annam', 'ரசம் சாதம்']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'rasam rice', 'rasam sadam', 'rasam sadham', 'chaaru annam', 'ரசம் சாதம்',
  'chaaru', 'pepper rasam', 'tomato rasam',
  'lemon rasam', 'rasam soup'
] WHERE food_name_normalized = 'rasam_rice';

-- puri (key: 'puri', from 270)
-- Existing: ['poori', 'deep fried bread']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'poori', 'deep fried bread',
  'fried bread', 'puri bread', 'fried puri',
  'deep fried puri', 'puffed bread',
  '1 puri', 'one puri'
] WHERE food_name_normalized = 'puri';

-- naan (key: 'naan', from 270)
-- Existing: ['plain naan', 'tandoori naan']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'plain naan', 'tandoori naan',
  'butter naan', 'naan bread',
  '1 naan', 'one naan', 'garlic naan'
] WHERE food_name_normalized = 'naan';

-- biryani (key: 'biryani', from 270)
-- Existing: ['chicken biryani', 'biriyani', 'briyani']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chicken biryani', 'biriyani', 'briyani',
  'veg biryani', 'mutton biryani',
  'dum biryani',
  '1 plate biryani', 'biryani plate'
] WHERE food_name_normalized = 'biryani';


-- ═══════════════════════════════════════════════════════════════════
-- LOW: Gourd/Vegetable Variants
-- ═══════════════════════════════════════════════════════════════════

-- dondakaya_fry (key: 'dondakaya_fry', from 1000)
-- Existing: ['ivy gourd fry', 'tindora fry', 'dondakaya vepudu', 'kovakkai poriyal', 'tendli fry']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'ivy gourd fry', 'tindora fry', 'dondakaya vepudu', 'kovakkai poriyal', 'tendli fry',
  'ivy gourd', 'tindora', 'dondakaya', 'kovakkai', 'tendli'
] WHERE food_name_normalized = 'dondakaya_fry';

-- bendakaya_fry (key: 'bendakaya_fry', from 1000)
-- Existing: ['okra fry', 'bhindi fry', 'bendakaya vepudu', 'ladies finger fry', 'vendakkai poriyal']
UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'okra fry', 'bhindi fry', 'bendakaya vepudu', 'ladies finger fry', 'vendakkai poriyal',
  'ladies finger', 'bhindi sabzi'
] WHERE food_name_normalized = 'bendakaya_fry';
