-- 1577_overrides_fruits_vegetables_staples.sql
-- Fruits, vegetables, grains/pasta, beans/legumes, canned goods, basic proteins, dairy, nut butters.
-- Sources: USDA FoodData Central, nutritionvalue.org, fatsecret.com, foodstruct.com,
-- snapcalorie.com, manufacturer labels, eatthismuch.com.
-- All values per 100g unless noted otherwise.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ==========================================
-- A. FRUITS (~25 items)
-- ==========================================

-- Banana: per 100g USDA: 89 cal, 1.1P, 22.8C, 0.3F, 2.6 fiber, 12.2 sugar. Medium banana ~118g.
('banana', 'Banana', 89, 1.1, 22.8, 0.3,
 2.6, 12.2, 118, 118,
 'usda', ARRAY['banana', 'medium banana', 'large banana', 'small banana', 'ripe banana', 'plantain', 'kela'],
 'fruits', NULL, 1, '89 cal/100g. Medium banana (118g): 105 cal. Excellent source of potassium and vitamin B6.', TRUE),

-- Apple: per 100g USDA: 52 cal, 0.3P, 13.8C, 0.2F, 2.4 fiber, 10.4 sugar. Medium apple ~182g.
('apple', 'Apple', 52, 0.3, 13.8, 0.2,
 2.4, 10.4, 182, 182,
 'usda', ARRAY['apple', 'medium apple', 'red apple', 'green apple', 'gala apple', 'fuji apple', 'granny smith apple', 'honeycrisp apple'],
 'fruits', NULL, 1, '52 cal/100g. Medium apple (182g): 95 cal. Good source of fiber and vitamin C.', TRUE),

-- Orange: per 100g USDA: 47 cal, 0.9P, 11.8C, 0.1F, 2.4 fiber, 9.4 sugar. Medium orange ~131g.
('orange', 'Orange', 47, 0.9, 11.8, 0.1,
 2.4, 9.4, 131, 131,
 'usda', ARRAY['orange', 'navel orange', 'medium orange', 'valencia orange', 'mandarin orange', 'blood orange'],
 'fruits', NULL, 1, '47 cal/100g. Medium orange (131g): 62 cal. Excellent source of vitamin C.', TRUE),

-- Mango: per 100g USDA: 60 cal, 0.8P, 15.0C, 0.4F, 1.6 fiber, 13.7 sugar. Medium mango ~200g.
('mango', 'Mango', 60, 0.8, 15.0, 0.4,
 1.6, 13.7, 200, 200,
 'usda', ARRAY['mango', 'fresh mango', 'sliced mango', 'mango slices', 'aam'],
 'fruits', NULL, 1, '60 cal/100g. Medium mango (200g): 120 cal. Rich in vitamin A and C.', TRUE),

-- Strawberry: per 100g USDA: 32 cal, 0.7P, 7.7C, 0.3F, 2.0 fiber, 4.9 sugar.
('strawberry', 'Strawberries', 32, 0.7, 7.7, 0.3,
 2.0, 4.9, 150, 12,
 'usda', ARRAY['strawberry', 'strawberries', 'fresh strawberries', 'sliced strawberries'],
 'fruits', NULL, 1, '32 cal/100g. 1 cup (150g): 48 cal. Excellent source of vitamin C and manganese.', TRUE),

-- Blueberry: per 100g USDA: 57 cal, 0.7P, 14.5C, 0.3F, 2.4 fiber, 10.0 sugar.
('blueberry', 'Blueberries', 57, 0.7, 14.5, 0.3,
 2.4, 10.0, 148, 1.5,
 'usda', ARRAY['blueberry', 'blueberries', 'fresh blueberries', 'wild blueberries'],
 'fruits', NULL, 1, '57 cal/100g. 1 cup (148g): 84 cal. Rich in antioxidants and vitamin K.', TRUE),

-- Raspberry: per 100g USDA: 52 cal, 1.2P, 11.9C, 0.7F, 6.5 fiber, 4.4 sugar.
('raspberry', 'Raspberries', 52, 1.2, 11.9, 0.7,
 6.5, 4.4, 123, 2,
 'usda', ARRAY['raspberry', 'raspberries', 'fresh raspberries', 'red raspberries'],
 'fruits', NULL, 1, '52 cal/100g. 1 cup (123g): 64 cal. Very high in fiber (6.5g/100g) and vitamin C.', TRUE),

-- Blackberry: per 100g USDA: 43 cal, 1.4P, 9.6C, 0.5F, 5.3 fiber, 4.9 sugar.
('blackberry', 'Blackberries', 43, 1.4, 9.6, 0.5,
 5.3, 4.9, 144, 3,
 'usda', ARRAY['blackberry', 'blackberries', 'fresh blackberries'],
 'fruits', NULL, 1, '43 cal/100g. 1 cup (144g): 62 cal. High in fiber, vitamin C, and manganese.', TRUE),

-- Grapes: per 100g USDA: 69 cal, 0.7P, 18.1C, 0.2F, 0.9 fiber, 15.5 sugar.
('grapes', 'Grapes', 69, 0.7, 18.1, 0.2,
 0.9, 15.5, 151, 5,
 'usda', ARRAY['grapes', 'red grapes', 'green grapes', 'seedless grapes', 'thompson grapes', 'concord grapes'],
 'fruits', NULL, 1, '69 cal/100g. 1 cup (151g): 104 cal. Good source of vitamin K and resveratrol.', TRUE),

-- Watermelon: per 100g USDA: 30 cal, 0.6P, 7.6C, 0.2F, 0.4 fiber, 6.2 sugar.
('watermelon', 'Watermelon', 30, 0.6, 7.6, 0.2,
 0.4, 6.2, 280, NULL,
 'usda', ARRAY['watermelon', 'watermelon slices', 'seedless watermelon', 'watermelon cubes'],
 'fruits', NULL, 1, '30 cal/100g. 1 cup diced (280g): 84 cal. Hydrating fruit with vitamin C and lycopene.', TRUE),

-- Pineapple: per 100g USDA: 50 cal, 0.5P, 13.1C, 0.1F, 1.4 fiber, 9.9 sugar.
('pineapple', 'Pineapple', 50, 0.5, 13.1, 0.1,
 1.4, 9.9, 165, NULL,
 'usda', ARRAY['pineapple', 'fresh pineapple', 'pineapple chunks', 'pineapple slices'],
 'fruits', NULL, 1, '50 cal/100g. 1 cup chunks (165g): 83 cal. Rich in vitamin C and bromelain enzyme.', TRUE),

-- Peach: per 100g USDA: 39 cal, 0.9P, 9.5C, 0.3F, 1.5 fiber, 8.4 sugar. Medium peach ~150g.
('peach', 'Peach', 39, 0.9, 9.5, 0.3,
 1.5, 8.4, 150, 150,
 'usda', ARRAY['peach', 'peaches', 'fresh peach', 'yellow peach', 'white peach'],
 'fruits', NULL, 1, '39 cal/100g. Medium peach (150g): 59 cal. Good source of vitamins A and C.', TRUE),

-- Pear: per 100g USDA: 57 cal, 0.4P, 15.2C, 0.1F, 3.1 fiber, 9.8 sugar. Medium pear ~178g.
('pear', 'Pear', 57, 0.4, 15.2, 0.1,
 3.1, 9.8, 178, 178,
 'usda', ARRAY['pear', 'pears', 'bartlett pear', 'anjou pear', 'bosc pear'],
 'fruits', NULL, 1, '57 cal/100g. Medium pear (178g): 101 cal. Good source of fiber and vitamin C.', TRUE),

-- Kiwi: per 100g USDA: 61 cal, 1.1P, 14.7C, 0.5F, 3.0 fiber, 9.0 sugar. Medium kiwi ~69g.
('kiwi', 'Kiwi', 61, 1.1, 14.7, 0.5,
 3.0, 9.0, 69, 69,
 'usda', ARRAY['kiwi', 'kiwifruit', 'green kiwi', 'gold kiwi', 'kiwi fruit'],
 'fruits', NULL, 1, '61 cal/100g. Medium kiwi (69g): 42 cal. Extremely high in vitamin C (93mg/100g).', TRUE),

-- Cherry: per 100g USDA: 50 cal, 1.0P, 12.2C, 0.3F, 1.6 fiber, 8.5 sugar.
('cherry', 'Cherries', 50, 1.0, 12.2, 0.3,
 1.6, 8.5, 138, 8,
 'usda', ARRAY['cherry', 'cherries', 'sweet cherries', 'fresh cherries', 'bing cherries'],
 'fruits', NULL, 1, '50 cal/100g. 1 cup with pits (138g): 87 cal. Rich in antioxidants and melatonin.', TRUE),

-- Grapefruit: per 100g USDA: 42 cal, 0.8P, 10.7C, 0.1F, 1.6 fiber, 6.9 sugar. Half grapefruit ~123g.
('grapefruit', 'Grapefruit', 42, 0.8, 10.7, 0.1,
 1.6, 6.9, 123, 246,
 'usda', ARRAY['grapefruit', 'pink grapefruit', 'red grapefruit', 'white grapefruit'],
 'fruits', NULL, 1, '42 cal/100g. Half grapefruit (123g): 52 cal. Excellent source of vitamin C. Note: interacts with some medications.', TRUE),

-- Cantaloupe: per 100g USDA: 34 cal, 0.8P, 8.2C, 0.2F, 0.9 fiber, 7.9 sugar.
('cantaloupe', 'Cantaloupe', 34, 0.8, 8.2, 0.2,
 0.9, 7.9, 177, NULL,
 'usda', ARRAY['cantaloupe', 'cantaloupe melon', 'muskmelon', 'rockmelon'],
 'fruits', NULL, 1, '34 cal/100g. 1 cup diced (177g): 60 cal. Excellent source of vitamins A and C.', TRUE),

-- Honeydew: per 100g USDA: 36 cal, 0.5P, 9.1C, 0.1F, 0.8 fiber, 8.1 sugar.
('honeydew', 'Honeydew Melon', 36, 0.5, 9.1, 0.1,
 0.8, 8.1, 177, NULL,
 'usda', ARRAY['honeydew', 'honeydew melon', 'honey dew melon', 'green melon'],
 'fruits', NULL, 1, '36 cal/100g. 1 cup diced (177g): 64 cal. Good source of vitamin C and potassium.', TRUE),

-- Avocado: per 100g USDA: 160 cal, 2.0P, 8.5C, 14.7F, 6.7 fiber, 0.7 sugar. Medium avocado ~150g flesh.
('avocado', 'Avocado', 160, 2.0, 8.5, 14.7,
 6.7, 0.7, 150, 150,
 'usda', ARRAY['avocado', 'avocados', 'hass avocado', 'california avocado', 'florida avocado', 'guacamole avocado'],
 'fruits', NULL, 1, '160 cal/100g. Medium avocado flesh (150g): 240 cal. High in healthy monounsaturated fats, potassium, and fiber.', TRUE),

-- Date (Medjool): per 100g USDA: 277 cal, 1.8P, 75.0C, 0.2F, 6.7 fiber, 66.5 sugar. One date ~24g.
('date', 'Medjool Date', 277, 1.8, 75.0, 0.2,
 6.7, 66.5, 24, 24,
 'usda', ARRAY['date', 'dates', 'medjool date', 'medjool dates', 'deglet noor date', 'khajoor'],
 'fruits', NULL, 1, '277 cal/100g. One Medjool date (24g): 66 cal. Natural sweetener, high in potassium and fiber.', TRUE),

-- Pomegranate Seeds: per 100g USDA: 83 cal, 1.7P, 18.7C, 1.2F, 4.0 fiber, 13.7 sugar.
('pomegranate_seeds', 'Pomegranate Seeds', 83, 1.7, 18.7, 1.2,
 4.0, 13.7, 87, NULL,
 'usda', ARRAY['pomegranate seeds', 'pomegranate', 'pomegranate arils', 'pom seeds', 'anaar'],
 'fruits', NULL, 1, '83 cal/100g. 0.5 cup arils (87g): 72 cal. Rich in antioxidants (punicalagins) and vitamin K.', TRUE),

-- Papaya: per 100g USDA: 43 cal, 0.5P, 10.8C, 0.3F, 1.7 fiber, 7.8 sugar.
('papaya', 'Papaya', 43, 0.5, 10.8, 0.3,
 1.7, 7.8, 145, NULL,
 'usda', ARRAY['papaya', 'fresh papaya', 'papaya slices', 'pawpaw'],
 'fruits', NULL, 1, '43 cal/100g. 1 cup chunks (145g): 62 cal. Rich in vitamin C, vitamin A, and papain enzyme.', TRUE),

-- Lemon: per 100g USDA: 29 cal, 1.1P, 9.3C, 0.3F, 2.8 fiber, 2.5 sugar. Medium lemon ~58g.
('lemon', 'Lemon', 29, 1.1, 9.3, 0.3,
 2.8, 2.5, 58, 58,
 'usda', ARRAY['lemon', 'lemons', 'fresh lemon', 'lemon fruit'],
 'fruits', NULL, 1, '29 cal/100g. Medium lemon (58g): 17 cal. Very high in vitamin C (53mg/100g). Mostly used as flavoring.', TRUE),

-- Lime: per 100g USDA: 30 cal, 0.7P, 10.5C, 0.2F, 2.8 fiber, 1.7 sugar. Medium lime ~67g.
('lime', 'Lime', 30, 0.7, 10.5, 0.2,
 2.8, 1.7, 67, 67,
 'usda', ARRAY['lime', 'limes', 'fresh lime', 'key lime'],
 'fruits', NULL, 1, '30 cal/100g. Medium lime (67g): 20 cal. Good source of vitamin C. Mostly used as flavoring.', TRUE),

-- Coconut (fresh meat): per 100g USDA: 354 cal, 3.3P, 15.2C, 33.5F, 9.0 fiber, 6.2 sugar.
('coconut_fresh', 'Coconut (Fresh Meat)', 354, 3.3, 15.2, 33.5,
 9.0, 6.2, 80, NULL,
 'usda', ARRAY['coconut', 'fresh coconut', 'coconut meat', 'raw coconut', 'nariyal'],
 'fruits', NULL, 1, '354 cal/100g. Per piece (80g): 283 cal. High in MCTs (medium chain triglycerides) and fiber.', TRUE),

-- ==========================================
-- B. VEGETABLES (~30 items)
-- ==========================================

-- Broccoli (raw): per 100g USDA: 34 cal, 2.8P, 6.6C, 0.4F, 2.6 fiber, 1.7 sugar.
('broccoli', 'Broccoli', 34, 2.8, 6.6, 0.4,
 2.6, 1.7, 91, NULL,
 'usda', ARRAY['broccoli', 'broccoli florets', 'fresh broccoli', 'steamed broccoli', 'raw broccoli'],
 'vegetables', NULL, 1, '34 cal/100g. 1 cup chopped (91g): 31 cal. Excellent source of vitamins C and K.', TRUE),

-- Spinach (raw): per 100g USDA: 23 cal, 2.9P, 3.6C, 0.4F, 2.2 fiber, 0.4 sugar.
('spinach', 'Spinach', 23, 2.9, 3.6, 0.4,
 2.2, 0.4, 30, NULL,
 'usda', ARRAY['spinach', 'fresh spinach', 'baby spinach', 'raw spinach', 'palak'],
 'vegetables', NULL, 1, '23 cal/100g. 1 cup raw (30g): 7 cal. Rich in iron, vitamins A, C, K, and folate.', TRUE),

-- Kale (raw): per 100g USDA: 49 cal, 4.3P, 8.8C, 0.9F, 3.6 fiber, 2.3 sugar.
('kale', 'Kale', 49, 4.3, 8.8, 0.9,
 3.6, 2.3, 67, NULL,
 'usda', ARRAY['kale', 'fresh kale', 'curly kale', 'lacinato kale', 'baby kale', 'tuscan kale'],
 'vegetables', NULL, 1, '49 cal/100g. 1 cup chopped (67g): 33 cal. One of the most nutrient-dense vegetables.', TRUE),

-- Carrot (raw): per 100g USDA: 41 cal, 0.9P, 9.6C, 0.2F, 2.8 fiber, 4.7 sugar. Medium carrot ~61g.
('carrot', 'Carrot', 41, 0.9, 9.6, 0.2,
 2.8, 4.7, 61, 61,
 'usda', ARRAY['carrot', 'carrots', 'raw carrot', 'baby carrots', 'carrot sticks'],
 'vegetables', NULL, 1, '41 cal/100g. Medium carrot (61g): 25 cal. Excellent source of beta-carotene (vitamin A).', TRUE),

-- Cucumber (raw with peel): per 100g USDA: 15 cal, 0.7P, 3.6C, 0.1F, 0.5 fiber, 1.7 sugar.
('cucumber', 'Cucumber', 15, 0.7, 3.6, 0.1,
 0.5, 1.7, 301, NULL,
 'usda', ARRAY['cucumber', 'cucumbers', 'fresh cucumber', 'sliced cucumber', 'english cucumber', 'kheera'],
 'vegetables', NULL, 1, '15 cal/100g. 1 medium (301g): 45 cal. Very hydrating (96% water). Low calorie snack.', TRUE),

-- Tomato (raw): per 100g USDA: 18 cal, 0.9P, 3.9C, 0.2F, 1.2 fiber, 2.6 sugar. Medium tomato ~123g.
('tomato', 'Tomato', 18, 0.9, 3.9, 0.2,
 1.2, 2.6, 123, 123,
 'usda', ARRAY['tomato', 'tomatoes', 'fresh tomato', 'red tomato', 'cherry tomatoes', 'grape tomatoes', 'roma tomato'],
 'vegetables', NULL, 1, '18 cal/100g. Medium tomato (123g): 22 cal. Good source of lycopene and vitamin C.', TRUE),

-- Red Bell Pepper: per 100g USDA: 31 cal, 1.0P, 6.0C, 0.3F, 2.1 fiber, 4.2 sugar.
('red_bell_pepper', 'Red Bell Pepper', 31, 1.0, 6.0, 0.3,
 2.1, 4.2, 119, 119,
 'usda', ARRAY['red bell pepper', 'red pepper', 'bell pepper red', 'sweet red pepper', 'capsicum red'],
 'vegetables', NULL, 1, '31 cal/100g. Medium pepper (119g): 37 cal. Extremely high in vitamin C (128mg/100g).', TRUE),

-- Green Bell Pepper: per 100g USDA: 20 cal, 0.9P, 4.6C, 0.2F, 1.7 fiber, 2.4 sugar.
('green_bell_pepper', 'Green Bell Pepper', 20, 0.9, 4.6, 0.2,
 1.7, 2.4, 119, 119,
 'usda', ARRAY['green bell pepper', 'green pepper', 'bell pepper green', 'sweet green pepper', 'capsicum green'],
 'vegetables', NULL, 1, '20 cal/100g. Medium pepper (119g): 24 cal. Good source of vitamin C.', TRUE),

-- Onion (raw): per 100g USDA: 40 cal, 1.1P, 9.3C, 0.1F, 1.7 fiber, 4.2 sugar. Medium onion ~110g.
('onion', 'Onion', 40, 1.1, 9.3, 0.1,
 1.7, 4.2, 110, 110,
 'usda', ARRAY['onion', 'onions', 'yellow onion', 'white onion', 'red onion', 'sweet onion', 'pyaaz'],
 'vegetables', NULL, 1, '40 cal/100g. Medium onion (110g): 44 cal. Contains quercetin and allicin compounds.', TRUE),

-- Garlic (raw): per 100g USDA: 149 cal, 6.4P, 33.1C, 0.5F, 2.1 fiber, 1.0 sugar. Clove ~3g.
('garlic', 'Garlic', 149, 6.4, 33.1, 0.5,
 2.1, 1.0, 3, 3,
 'usda', ARRAY['garlic', 'garlic clove', 'fresh garlic', 'minced garlic', 'lehsun'],
 'vegetables', NULL, 1, '149 cal/100g. 1 clove (3g): 4 cal. Rich in allicin. Used in small quantities as flavoring.', TRUE),

-- Zucchini (raw): per 100g USDA: 17 cal, 1.2P, 3.1C, 0.3F, 1.0 fiber, 2.5 sugar.
('zucchini', 'Zucchini', 17, 1.2, 3.1, 0.3,
 1.0, 2.5, 113, NULL,
 'usda', ARRAY['zucchini', 'zucchini squash', 'courgette', 'green zucchini', 'zoodles'],
 'vegetables', NULL, 1, '17 cal/100g. 1 medium (113g): 19 cal. Very low calorie. Popular as pasta substitute (zoodles).', TRUE),

-- Cauliflower (raw): per 100g USDA: 25 cal, 1.9P, 5.0C, 0.3F, 2.0 fiber, 1.9 sugar.
('cauliflower', 'Cauliflower', 25, 1.9, 5.0, 0.3,
 2.0, 1.9, 107, NULL,
 'usda', ARRAY['cauliflower', 'cauliflower florets', 'riced cauliflower', 'cauliflower rice', 'gobi'],
 'vegetables', NULL, 1, '25 cal/100g. 1 cup chopped (107g): 27 cal. Popular low-carb substitute for rice and pizza crust.', TRUE),

-- Asparagus (raw): per 100g USDA: 20 cal, 2.2P, 3.9C, 0.1F, 2.1 fiber, 1.9 sugar.
('asparagus', 'Asparagus', 20, 2.2, 3.9, 0.1,
 2.1, 1.9, 134, 16,
 'usda', ARRAY['asparagus', 'asparagus spears', 'green asparagus', 'fresh asparagus'],
 'vegetables', NULL, 1, '20 cal/100g. 1 cup (134g): 27 cal. Good source of folate, vitamins A, C, and K.', TRUE),

-- Green Beans (raw): per 100g USDA: 31 cal, 1.8P, 7.0C, 0.2F, 2.7 fiber, 3.3 sugar.
('green_beans', 'Green Beans', 31, 1.8, 7.0, 0.2,
 2.7, 3.3, 110, NULL,
 'usda', ARRAY['green beans', 'string beans', 'snap beans', 'french beans', 'haricots verts'],
 'vegetables', NULL, 1, '31 cal/100g. 1 cup (110g): 34 cal. Good source of vitamins C, K, and fiber.', TRUE),

-- Brussels Sprouts (raw): per 100g USDA: 43 cal, 3.4P, 9.0C, 0.3F, 3.8 fiber, 2.2 sugar.
('brussels_sprouts', 'Brussels Sprouts', 43, 3.4, 9.0, 0.3,
 3.8, 2.2, 88, 19,
 'usda', ARRAY['brussels sprouts', 'brussel sprouts', 'brussels', 'sprouts'],
 'vegetables', NULL, 1, '43 cal/100g. 1 cup (88g): 38 cal. Excellent source of vitamins C and K, and fiber.', TRUE),

-- Celery (raw): per 100g USDA: 16 cal, 0.7P, 3.0C, 0.2F, 1.6 fiber, 1.3 sugar.
('celery', 'Celery', 16, 0.7, 3.0, 0.2,
 1.6, 1.3, 101, 40,
 'usda', ARRAY['celery', 'celery sticks', 'celery stalks', 'fresh celery'],
 'vegetables', NULL, 1, '16 cal/100g. 1 medium stalk (40g): 6 cal. Very low calorie, good source of vitamin K.', TRUE),

-- Romaine Lettuce: per 100g USDA: 17 cal, 1.2P, 3.3C, 0.3F, 2.1 fiber, 1.2 sugar.
('romaine_lettuce', 'Romaine Lettuce', 17, 1.2, 3.3, 0.3,
 2.1, 1.2, 47, NULL,
 'usda', ARRAY['romaine lettuce', 'romaine', 'cos lettuce', 'romaine hearts'],
 'vegetables', NULL, 1, '17 cal/100g. 1 cup shredded (47g): 8 cal. Good source of vitamins A and K.', TRUE),

-- Iceberg Lettuce: per 100g USDA: 14 cal, 0.9P, 3.0C, 0.1F, 1.2 fiber, 2.0 sugar.
('iceberg_lettuce', 'Iceberg Lettuce', 14, 0.9, 3.0, 0.1,
 1.2, 2.0, 72, NULL,
 'usda', ARRAY['iceberg lettuce', 'iceberg', 'head lettuce', 'crisphead lettuce'],
 'vegetables', NULL, 1, '14 cal/100g. 1 cup shredded (72g): 10 cal. Very low calorie, mostly water.', TRUE),

-- Cabbage (green, raw): per 100g USDA: 25 cal, 1.3P, 5.8C, 0.1F, 2.5 fiber, 3.2 sugar.
('cabbage', 'Cabbage', 25, 1.3, 5.8, 0.1,
 2.5, 3.2, 89, NULL,
 'usda', ARRAY['cabbage', 'green cabbage', 'red cabbage', 'napa cabbage', 'patta gobi'],
 'vegetables', NULL, 1, '25 cal/100g. 1 cup shredded (89g): 22 cal. Good source of vitamin C and fiber.', TRUE),

-- Corn (sweet, cooked): per 100g USDA: 96 cal, 3.4P, 21.0C, 1.5F, 2.4 fiber, 4.5 sugar.
('corn', 'Sweet Corn', 96, 3.4, 21.0, 1.5,
 2.4, 4.5, 146, NULL,
 'usda', ARRAY['corn', 'sweet corn', 'corn on the cob', 'corn kernels', 'yellow corn', 'maize', 'makka'],
 'vegetables', NULL, 1, '96 cal/100g cooked. 1 medium ear (146g): 140 cal. Good source of fiber and B vitamins.', TRUE),

-- Peas (green, cooked): per 100g USDA: 84 cal, 5.4P, 15.6C, 0.2F, 5.1 fiber, 5.9 sugar.
('peas', 'Green Peas', 84, 5.4, 15.6, 0.2,
 5.1, 5.9, 160, NULL,
 'usda', ARRAY['peas', 'green peas', 'garden peas', 'sweet peas', 'english peas', 'matar'],
 'vegetables', NULL, 1, '84 cal/100g cooked. 1 cup (160g): 134 cal. Good plant-based protein source with fiber.', TRUE),

-- Edamame (cooked): per 100g USDA: 121 cal, 12.0P, 8.9C, 5.2F, 5.2 fiber, 2.2 sugar.
('edamame', 'Edamame', 121, 12.0, 8.9, 5.2,
 5.2, 2.2, 155, NULL,
 'usda', ARRAY['edamame', 'edamame beans', 'soybeans in pod', 'mukimame'],
 'vegetables', NULL, 1, '121 cal/100g cooked. 1 cup shelled (155g): 188 cal. Excellent plant protein source. Complete protein.', TRUE),

-- White Mushroom (raw): per 100g USDA: 22 cal, 3.1P, 3.3C, 0.3F, 1.0 fiber, 2.0 sugar.
('mushroom', 'Mushroom (White)', 22, 3.1, 3.3, 0.3,
 1.0, 2.0, 70, 18,
 'usda', ARRAY['mushroom', 'mushrooms', 'white mushroom', 'button mushroom', 'champignon', 'sliced mushrooms'],
 'vegetables', NULL, 1, '22 cal/100g. 1 cup sliced (70g): 15 cal. Good source of selenium, B vitamins, and vitamin D if sun-exposed.', TRUE),

-- Portobello Mushroom (raw): per 100g USDA: 22 cal, 2.1P, 3.9C, 0.4F, 1.3 fiber, 2.5 sugar.
('portobello_mushroom', 'Portobello Mushroom', 22, 2.1, 3.9, 0.4,
 1.3, 2.5, 84, 84,
 'usda', ARRAY['portobello mushroom', 'portobello', 'portabella mushroom', 'portabello', 'grilled portobello'],
 'vegetables', NULL, 1, '22 cal/100g. 1 cap (84g): 18 cal. Popular meat substitute for burgers. Rich in selenium.', TRUE),

-- Beet (raw): per 100g USDA: 43 cal, 1.6P, 9.6C, 0.2F, 2.8 fiber, 6.8 sugar.
('beet', 'Beet', 43, 1.6, 9.6, 0.2,
 2.8, 6.8, 82, 82,
 'usda', ARRAY['beet', 'beets', 'beetroot', 'red beet', 'golden beet', 'chukandar'],
 'vegetables', NULL, 1, '43 cal/100g. 1 medium beet (82g): 35 cal. Rich in nitrates which may improve blood flow and exercise performance.', TRUE),

-- Eggplant (raw): per 100g USDA: 25 cal, 1.0P, 5.9C, 0.2F, 3.0 fiber, 3.5 sugar.
('eggplant', 'Eggplant', 25, 1.0, 5.9, 0.2,
 3.0, 3.5, 82, NULL,
 'usda', ARRAY['eggplant', 'aubergine', 'brinjal', 'baingan'],
 'vegetables', NULL, 1, '25 cal/100g. 1 cup cubed (82g): 20 cal. Low calorie, good source of fiber and anthocyanins.', TRUE),

-- Sweet Potato (baked, flesh only): per 100g USDA: 90 cal, 2.0P, 20.7C, 0.1F, 3.3 fiber, 6.5 sugar. Medium ~114g.
('sweet_potato', 'Sweet Potato (Baked)', 90, 2.0, 20.7, 0.1,
 3.3, 6.5, 114, 114,
 'usda', ARRAY['sweet potato', 'baked sweet potato', 'yam', 'sweet potatoes', 'shakarkandi'],
 'vegetables', NULL, 1, '90 cal/100g baked. Medium sweet potato (114g): 103 cal. Excellent source of vitamin A (beta-carotene) and fiber.', TRUE),

-- Potato (baked, flesh and skin): per 100g USDA: 93 cal, 2.5P, 21.2C, 0.1F, 2.2 fiber, 1.2 sugar. Medium ~173g.
('baked_potato', 'Potato (Baked)', 93, 2.5, 21.2, 0.1,
 2.2, 1.2, 173, 173,
 'usda', ARRAY['baked potato', 'potato', 'russet potato', 'idaho potato', 'jacket potato', 'aloo'],
 'vegetables', NULL, 1, '93 cal/100g baked with skin. Medium potato (173g): 161 cal. Good source of potassium, vitamin C, and B6.', TRUE),

-- Butternut Squash (baked): per 100g USDA: 40 cal, 0.9P, 10.5C, 0.1F, 3.2 fiber, 2.0 sugar.
('butternut_squash', 'Butternut Squash (Baked)', 40, 0.9, 10.5, 0.1,
 3.2, 2.0, 205, NULL,
 'usda', ARRAY['butternut squash', 'butternut', 'winter squash', 'baked butternut squash'],
 'vegetables', NULL, 1, '40 cal/100g baked. 1 cup cubed (205g): 82 cal. Excellent source of vitamin A and fiber.', TRUE),

-- ==========================================
-- C. PASTA & GRAINS (~15 items)
-- ==========================================

-- Spaghetti (cooked, enriched): per 100g USDA: 158 cal, 5.8P, 31.0C, 0.9F, 1.8 fiber, 0.6 sugar.
('spaghetti_cooked', 'Spaghetti (Cooked)', 158, 5.8, 31.0, 0.9,
 1.8, 0.6, 140, NULL,
 'usda', ARRAY['spaghetti', 'cooked spaghetti', 'spaghetti pasta', 'spaghetti noodles'],
 'grains_pasta', NULL, 1, '158 cal/100g cooked. 1 cup (140g): 221 cal. Enriched with iron and B vitamins.', TRUE),

-- Penne (cooked): per 100g USDA: 157 cal, 5.8P, 30.7C, 0.9F, 1.8 fiber, 0.6 sugar.
('penne_cooked', 'Penne Pasta (Cooked)', 157, 5.8, 30.7, 0.9,
 1.8, 0.6, 140, NULL,
 'usda', ARRAY['penne', 'cooked penne', 'penne pasta', 'penne rigate'],
 'grains_pasta', NULL, 1, '157 cal/100g cooked. 1 cup (140g): 220 cal. Same nutrition as spaghetti (different shape).', TRUE),

-- Fettuccine (cooked): per 100g USDA: 158 cal, 5.8P, 31.0C, 0.9F, 1.8 fiber, 0.6 sugar.
('fettuccine_cooked', 'Fettuccine (Cooked)', 158, 5.8, 31.0, 0.9,
 1.8, 0.6, 140, NULL,
 'usda', ARRAY['fettuccine', 'cooked fettuccine', 'fettuccine pasta', 'fettuccini'],
 'grains_pasta', NULL, 1, '158 cal/100g cooked. 1 cup (140g): 221 cal. Flat ribbon pasta, same base nutrition as spaghetti.', TRUE),

-- Macaroni (cooked): per 100g USDA: 157 cal, 5.8P, 30.6C, 0.9F, 1.8 fiber, 0.6 sugar.
('macaroni_cooked', 'Macaroni (Cooked)', 157, 5.8, 30.6, 0.9,
 1.8, 0.6, 140, NULL,
 'usda', ARRAY['macaroni', 'cooked macaroni', 'elbow macaroni', 'elbow pasta', 'mac'],
 'grains_pasta', NULL, 1, '157 cal/100g cooked. 1 cup (140g): 220 cal. Same base nutrition as other white pasta shapes.', TRUE),

-- Whole Wheat Pasta (cooked): per 100g USDA: 124 cal, 5.3P, 26.5C, 0.5F, 4.5 fiber, 0.8 sugar.
('whole_wheat_pasta_cooked', 'Whole Wheat Pasta (Cooked)', 124, 5.3, 26.5, 0.5,
 4.5, 0.8, 140, NULL,
 'usda', ARRAY['whole wheat pasta', 'whole grain pasta', 'whole wheat spaghetti', 'wheat pasta', 'brown pasta'],
 'grains_pasta', NULL, 1, '124 cal/100g cooked. 1 cup (140g): 174 cal. Higher fiber and slightly more protein than white pasta.', TRUE),

-- Quinoa (cooked): per 100g USDA: 120 cal, 4.4P, 21.3C, 1.9F, 2.8 fiber, 0.9 sugar.
('quinoa_cooked', 'Quinoa (Cooked)', 120, 4.4, 21.3, 1.9,
 2.8, 0.9, 185, NULL,
 'usda', ARRAY['quinoa', 'cooked quinoa', 'white quinoa', 'red quinoa', 'black quinoa', 'tricolor quinoa'],
 'grains_pasta', NULL, 1, '120 cal/100g cooked. 1 cup (185g): 222 cal. Complete protein (all 9 essential amino acids). Gluten-free.', TRUE),

-- Couscous (cooked): per 100g USDA: 112 cal, 3.8P, 23.2C, 0.2F, 1.4 fiber, 0.1 sugar.
('couscous_cooked', 'Couscous (Cooked)', 112, 3.8, 23.2, 0.2,
 1.4, 0.1, 157, NULL,
 'usda', ARRAY['couscous', 'cooked couscous', 'pearl couscous', 'israeli couscous'],
 'grains_pasta', NULL, 1, '112 cal/100g cooked. 1 cup (157g): 176 cal. Quick-cooking grain made from semolina wheat.', TRUE),

-- Basmati Rice (cooked): per 100g USDA: 130 cal, 2.7P, 28.2C, 0.3F, 0.4 fiber, 0.1 sugar.
('basmati_rice_cooked', 'Basmati Rice (Cooked)', 130, 2.7, 28.2, 0.3,
 0.4, 0.1, 158, NULL,
 'usda', ARRAY['basmati rice', 'cooked basmati rice', 'white basmati rice', 'basmati', 'chawal'],
 'grains_pasta', NULL, 1, '130 cal/100g cooked. 1 cup (158g): 205 cal. Long-grain aromatic rice. Low GI compared to other white rice.', TRUE),

-- Jasmine Rice (cooked): per 100g USDA: 129 cal, 2.7P, 28.0C, 0.3F, 0.4 fiber, 0.1 sugar.
('jasmine_rice_cooked', 'Jasmine Rice (Cooked)', 129, 2.7, 28.0, 0.3,
 0.4, 0.1, 158, NULL,
 'usda', ARRAY['jasmine rice', 'cooked jasmine rice', 'thai jasmine rice', 'white jasmine rice'],
 'grains_pasta', NULL, 1, '129 cal/100g cooked. 1 cup (158g): 204 cal. Fragrant long-grain rice popular in Thai cuisine.', TRUE),

-- Wild Rice (cooked): per 100g USDA: 101 cal, 4.0P, 21.3C, 0.3F, 1.8 fiber, 0.7 sugar.
('wild_rice_cooked', 'Wild Rice (Cooked)', 101, 4.0, 21.3, 0.3,
 1.8, 0.7, 164, NULL,
 'usda', ARRAY['wild rice', 'cooked wild rice', 'wild rice blend'],
 'grains_pasta', NULL, 1, '101 cal/100g cooked. 1 cup (164g): 166 cal. Higher protein than white rice. Technically a grass seed, not true rice.', TRUE),

-- Farro (cooked): per 100g USDA: 120 cal, 5.0P, 24.0C, 0.7F, 3.5 fiber, 0.5 sugar.
('farro_cooked', 'Farro (Cooked)', 120, 5.0, 24.0, 0.7,
 3.5, 0.5, 170, NULL,
 'usda', ARRAY['farro', 'cooked farro', 'emmer wheat', 'pearled farro'],
 'grains_pasta', NULL, 1, '120 cal/100g cooked. 1 cup (170g): 204 cal. Ancient wheat grain, nutty flavor, high in fiber and protein.', TRUE),

-- Bulgur Wheat (cooked): per 100g USDA: 83 cal, 3.1P, 18.6C, 0.2F, 4.5 fiber, 0.1 sugar.
('bulgur_cooked', 'Bulgur Wheat (Cooked)', 83, 3.1, 18.6, 0.2,
 4.5, 0.1, 182, NULL,
 'usda', ARRAY['bulgur', 'bulgur wheat', 'cooked bulgur', 'cracked wheat', 'tabbouleh wheat'],
 'grains_pasta', NULL, 1, '83 cal/100g cooked. 1 cup (182g): 151 cal. Very high in fiber. Key ingredient in tabbouleh.', TRUE),

-- Oatmeal (cooked with water): per 100g USDA: 68 cal, 2.4P, 12.0C, 1.4F, 1.7 fiber, 0.3 sugar.
('oatmeal_cooked', 'Oatmeal (Cooked)', 68, 2.4, 12.0, 1.4,
 1.7, 0.3, 234, NULL,
 'usda', ARRAY['oatmeal', 'cooked oatmeal', 'oat porridge', 'porridge', 'rolled oats cooked', 'steel cut oats cooked'],
 'grains_pasta', NULL, 1, '68 cal/100g cooked. 1 cup (234g): 159 cal. Rich in beta-glucan fiber which lowers cholesterol.', TRUE),

-- Grits (cooked with water): per 100g USDA: 65 cal, 1.2P, 13.9C, 0.4F, 0.6 fiber, 0.1 sugar.
('grits_cooked', 'Grits (Cooked)', 65, 1.2, 13.9, 0.4,
 0.6, 0.1, 242, NULL,
 'usda', ARRAY['grits', 'cooked grits', 'corn grits', 'hominy grits', 'yellow grits', 'white grits'],
 'grains_pasta', NULL, 1, '65 cal/100g cooked. 1 cup (242g): 157 cal. Southern staple made from ground corn.', TRUE),

-- ==========================================
-- D. BEANS & LEGUMES (~10 items)
-- ==========================================

-- Black Beans (cooked): per 100g USDA: 132 cal, 8.9P, 23.7C, 0.5F, 8.7 fiber, 0.3 sugar.
('black_beans', 'Black Beans (Cooked)', 132, 8.9, 23.7, 0.5,
 8.7, 0.3, 172, NULL,
 'usda', ARRAY['black beans', 'cooked black beans', 'frijoles negros', 'turtle beans', 'black beans canned'],
 'beans_legumes', NULL, 1, '132 cal/100g cooked. 1 cup (172g): 227 cal. Excellent fiber and plant protein source.', TRUE),

-- Kidney Beans (cooked): per 100g USDA: 127 cal, 8.7P, 22.8C, 0.5F, 7.4 fiber, 0.3 sugar.
('kidney_beans', 'Kidney Beans (Cooked)', 127, 8.7, 22.8, 0.5,
 7.4, 0.3, 177, NULL,
 'usda', ARRAY['kidney beans', 'red kidney beans', 'cooked kidney beans', 'rajma'],
 'beans_legumes', NULL, 1, '127 cal/100g cooked. 1 cup (177g): 225 cal. High in fiber and folate. Must be cooked thoroughly.', TRUE),

-- Chickpeas (cooked): per 100g USDA: 164 cal, 8.9P, 27.4C, 2.6F, 7.6 fiber, 4.8 sugar.
('chickpeas', 'Chickpeas (Cooked)', 164, 8.9, 27.4, 2.6,
 7.6, 4.8, 164, NULL,
 'usda', ARRAY['chickpeas', 'garbanzo beans', 'cooked chickpeas', 'chana', 'chole', 'canned chickpeas'],
 'beans_legumes', NULL, 1, '164 cal/100g cooked. 1 cup (164g): 269 cal. Versatile legume used in hummus, curries, and salads.', TRUE),

-- Green Lentils (cooked): per 100g USDA: 116 cal, 9.0P, 20.1C, 0.4F, 7.9 fiber, 1.8 sugar.
('green_lentils', 'Green Lentils (Cooked)', 116, 9.0, 20.1, 0.4,
 7.9, 1.8, 198, NULL,
 'usda', ARRAY['green lentils', 'lentils', 'cooked lentils', 'french lentils', 'dal', 'masoor'],
 'beans_legumes', NULL, 1, '116 cal/100g cooked. 1 cup (198g): 230 cal. Excellent source of protein, fiber, iron, and folate.', TRUE),

-- Red Lentils (cooked): per 100g USDA: 116 cal, 9.0P, 20.1C, 0.4F, 7.9 fiber, 1.8 sugar.
('red_lentils', 'Red Lentils (Cooked)', 116, 9.0, 20.1, 0.4,
 7.9, 1.8, 198, NULL,
 'usda', ARRAY['red lentils', 'cooked red lentils', 'masoor dal', 'red dal', 'split red lentils'],
 'beans_legumes', NULL, 1, '116 cal/100g cooked. 1 cup (198g): 230 cal. Cook faster than green lentils. Common in Indian dal.', TRUE),

-- Pinto Beans (cooked): per 100g USDA: 143 cal, 9.0P, 26.2C, 0.7F, 9.0 fiber, 0.3 sugar.
('pinto_beans', 'Pinto Beans (Cooked)', 143, 9.0, 26.2, 0.7,
 9.0, 0.3, 171, NULL,
 'usda', ARRAY['pinto beans', 'cooked pinto beans', 'frijoles', 'refried bean base'],
 'beans_legumes', NULL, 1, '143 cal/100g cooked. 1 cup (171g): 245 cal. Most popular bean in Mexican cuisine. Very high in fiber.', TRUE),

-- Navy Beans (cooked): per 100g USDA: 140 cal, 8.2P, 26.1C, 0.6F, 10.5 fiber, 0.3 sugar.
('navy_beans', 'Navy Beans (Cooked)', 140, 8.2, 26.1, 0.6,
 10.5, 0.3, 182, NULL,
 'usda', ARRAY['navy beans', 'white beans', 'cooked navy beans', 'haricot beans', 'great northern beans'],
 'beans_legumes', NULL, 1, '140 cal/100g cooked. 1 cup (182g): 255 cal. Highest fiber of common beans. Used in baked beans and soups.', TRUE),

-- Lima Beans (cooked): per 100g USDA: 115 cal, 7.8P, 20.9C, 0.4F, 7.0 fiber, 2.9 sugar.
('lima_beans', 'Lima Beans (Cooked)', 115, 7.8, 20.9, 0.4,
 7.0, 2.9, 170, NULL,
 'usda', ARRAY['lima beans', 'butter beans', 'cooked lima beans', 'baby lima beans'],
 'beans_legumes', NULL, 1, '115 cal/100g cooked. 1 cup (170g): 196 cal. Also called butter beans. Good source of iron.', TRUE),

-- Soybeans (cooked): per 100g USDA: 173 cal, 16.6P, 9.9C, 9.0F, 6.0 fiber, 3.0 sugar.
('soybeans_cooked', 'Soybeans (Cooked)', 173, 16.6, 9.9, 9.0,
 6.0, 3.0, 172, NULL,
 'usda', ARRAY['soybeans', 'cooked soybeans', 'soya beans', 'soy beans'],
 'beans_legumes', NULL, 1, '173 cal/100g cooked. 1 cup (172g): 298 cal. Complete protein. Highest protein among legumes.', TRUE),

-- Split Peas (cooked): per 100g USDA: 118 cal, 8.3P, 21.1C, 0.4F, 8.3 fiber, 2.9 sugar.
('split_peas', 'Split Peas (Cooked)', 118, 8.3, 21.1, 0.4,
 8.3, 2.9, 196, NULL,
 'usda', ARRAY['split peas', 'cooked split peas', 'green split peas', 'yellow split peas', 'split pea soup base'],
 'beans_legumes', NULL, 1, '118 cal/100g cooked. 1 cup (196g): 231 cal. Popular in split pea soup. High in fiber and protein.', TRUE),

-- ==========================================
-- E. CANNED GOODS (~12 items)
-- ==========================================

-- Canned Tuna in Water (drained): per 100g USDA: 86 cal, 19.4P, 0.0C, 0.8F, 0.0 fiber, 0.0 sugar.
('canned_tuna_water', 'Canned Tuna in Water', 86, 19.4, 0.0, 0.8,
 0.0, 0.0, 56, NULL,
 'usda', ARRAY['canned tuna', 'tuna in water', 'canned tuna in water', 'chunk light tuna', 'starkist tuna', 'bumble bee tuna'],
 'canned_goods', NULL, 1, '86 cal/100g drained. Per can drained (112g): 96 cal. High protein, very low fat. Great for meal prep.', TRUE),

-- Canned Tuna in Oil (drained): per 100g USDA: 198 cal, 29.1P, 0.0C, 8.2F, 0.0 fiber, 0.0 sugar.
('canned_tuna_oil', 'Canned Tuna in Oil', 198, 29.1, 0.0, 8.2,
 0.0, 0.0, 56, NULL,
 'usda', ARRAY['tuna in oil', 'canned tuna in oil', 'tuna packed in oil', 'oil packed tuna'],
 'canned_goods', NULL, 1, '198 cal/100g drained. Per can drained (112g): 222 cal. Higher calorie than water-packed due to oil.', TRUE),

-- Canned Salmon (pink, drained): per 100g USDA: 136 cal, 24.6P, 0.0C, 4.2F, 0.0 fiber, 0.0 sugar.
('canned_salmon', 'Canned Salmon', 136, 24.6, 0.0, 4.2,
 0.0, 0.0, 56, NULL,
 'usda', ARRAY['canned salmon', 'canned pink salmon', 'salmon canned', 'canned sockeye salmon'],
 'canned_goods', NULL, 1, '136 cal/100g drained. Per can drained (112g): 152 cal. Rich in omega-3 fatty acids and vitamin D.', TRUE),

-- Canned Chicken (drained): per 100g USDA: 153 cal, 25.3P, 0.0C, 5.2F, 0.0 fiber, 0.0 sugar.
('canned_chicken', 'Canned Chicken', 153, 25.3, 0.0, 5.2,
 0.0, 0.0, 56, NULL,
 'usda', ARRAY['canned chicken', 'canned chicken breast', 'chunk chicken canned'],
 'canned_goods', NULL, 1, '153 cal/100g drained. Convenient protein source. Good for quick salads and wraps.', TRUE),

-- Campbell's Chicken Noodle Soup (condensed, as prepared): per 100g: 25 cal, 1.2P, 3.0C, 0.8F, 0.3 fiber, 0.2 sugar.
('campbells_chicken_noodle_soup', 'Campbell''s Chicken Noodle Soup', 25, 1.2, 3.0, 0.8,
 0.3, 0.2, 248, NULL,
 'campbells', ARRAY['campbell''s chicken noodle soup', 'campbells chicken noodle', 'chicken noodle soup canned', 'chicken noodle soup'],
 'canned_goods', 'Campbell''s', 1, '25 cal/100g prepared (diluted). Per 1 cup prepared (248g): 62 cal. Classic comfort soup. Condensed: add equal part water.', TRUE),

-- Campbell's Tomato Soup (condensed, as prepared): per 100g: 33 cal, 0.7P, 7.2C, 0.0F, 0.4 fiber, 4.1 sugar.
('campbells_tomato_soup', 'Campbell''s Tomato Soup', 33, 0.7, 7.2, 0.0,
 0.4, 4.1, 248, NULL,
 'campbells', ARRAY['campbell''s tomato soup', 'campbells tomato soup', 'tomato soup canned', 'cream of tomato soup'],
 'canned_goods', 'Campbell''s', 1, '33 cal/100g prepared (diluted with water). Per 1 cup prepared (248g): 82 cal. Condensed: add equal part water.', TRUE),

-- Amy's Lentil Soup: per 100g: 58 cal, 3.3P, 8.7C, 1.4F, 2.4 fiber, 0.8 sugar.
('amys_lentil_soup', 'Amy''s Organic Lentil Soup', 58, 3.3, 8.7, 1.4,
 2.4, 0.8, 245, NULL,
 'amys', ARRAY['amy''s lentil soup', 'amys lentil soup', 'amy''s organic lentil soup', 'organic lentil soup'],
 'canned_goods', 'Amy''s', 1, '58 cal/100g. Per can (245g): 142 cal. Organic, ready-to-eat. Good source of plant protein and fiber.', TRUE),

-- Bush's Baked Beans (Original): per 100g: 123 cal, 5.4P, 25.4C, 0.4F, 5.4 fiber, 10.8 sugar.
('bushs_baked_beans', 'Bush''s Baked Beans (Original)', 123, 5.4, 25.4, 0.4,
 5.4, 10.8, 130, NULL,
 'bushs', ARRAY['bush''s baked beans', 'bushs baked beans', 'baked beans', 'bush''s original baked beans'],
 'canned_goods', 'Bush''s', 1, '123 cal/100g. Per 0.5 cup (130g): 160 cal. Classic BBQ side dish. Contains added sugars in sauce.', TRUE),

-- Canned Corn (sweet, drained): per 100g USDA: 67 cal, 2.3P, 14.3C, 1.2F, 1.7 fiber, 3.2 sugar.
('canned_corn', 'Canned Corn', 67, 2.3, 14.3, 1.2,
 1.7, 3.2, 128, NULL,
 'usda', ARRAY['canned corn', 'canned sweet corn', 'corn canned', 'canned corn kernels', 'creamed corn'],
 'canned_goods', NULL, 1, '67 cal/100g drained. Per 0.5 cup drained (128g): 86 cal. Convenient shelf-stable vegetable.', TRUE),

-- Canned Green Beans (drained): per 100g USDA: 20 cal, 1.2P, 4.3C, 0.1F, 1.6 fiber, 0.8 sugar.
('canned_green_beans', 'Canned Green Beans', 20, 1.2, 4.3, 0.1,
 1.6, 0.8, 121, NULL,
 'usda', ARRAY['canned green beans', 'green beans canned', 'canned string beans', 'canned cut green beans'],
 'canned_goods', NULL, 1, '20 cal/100g drained. Per 0.5 cup drained (121g): 24 cal. Very low calorie canned vegetable.', TRUE),

-- Canned Diced Tomatoes: per 100g USDA: 24 cal, 0.8P, 4.8C, 0.1F, 1.0 fiber, 2.4 sugar.
('canned_diced_tomatoes', 'Canned Diced Tomatoes', 24, 0.8, 4.8, 0.1,
 1.0, 2.4, 121, NULL,
 'usda', ARRAY['canned diced tomatoes', 'diced tomatoes', 'canned tomatoes', 'crushed tomatoes', 'stewed tomatoes'],
 'canned_goods', NULL, 1, '24 cal/100g. Per 0.5 cup (121g): 29 cal. Pantry staple for sauces, soups, and stews. Good source of lycopene.', TRUE),

-- ==========================================
-- F. BASIC PROTEINS (~15 items)
-- ==========================================

-- Chicken Breast (grilled, skinless): per 100g USDA: 165 cal, 31.0P, 0.0C, 3.6F, 0.0 fiber, 0.0 sugar.
('chicken_breast_grilled', 'Chicken Breast (Grilled)', 165, 31.0, 0.0, 3.6,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['chicken breast', 'grilled chicken breast', 'grilled chicken', 'baked chicken breast', 'boneless skinless chicken breast'],
 'proteins', NULL, 1, '165 cal/100g. 1 breast (120g): 198 cal. Gold standard lean protein. 31g protein per 100g.', TRUE),

-- Chicken Thigh (cooked, boneless, skinless): per 100g USDA: 209 cal, 26.0P, 0.0C, 10.9F, 0.0 fiber, 0.0 sugar.
('chicken_thigh_cooked', 'Chicken Thigh (Cooked)', 209, 26.0, 0.0, 10.9,
 0.0, 0.0, 85, 85,
 'usda', ARRAY['chicken thigh', 'cooked chicken thigh', 'boneless chicken thigh', 'chicken thigh grilled'],
 'proteins', NULL, 1, '209 cal/100g. 1 thigh (85g): 178 cal. More flavorful than breast due to higher fat content.', TRUE),

-- Ground Beef 90/10 (cooked): per 100g USDA: 217 cal, 26.1P, 0.0C, 11.7F, 0.0 fiber, 0.0 sugar.
('ground_beef_90_10', 'Ground Beef 90/10 (Cooked)', 217, 26.1, 0.0, 11.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground beef 90/10', '90/10 ground beef', 'lean ground beef', '90 lean ground beef', 'extra lean ground beef'],
 'proteins', NULL, 1, '217 cal/100g cooked. Per 3 oz patty (85g): 184 cal. Lean option for burgers and meatballs.', TRUE),

-- Ground Beef 80/20 (cooked): per 100g USDA: 254 cal, 25.6P, 0.0C, 17.1F, 0.0 fiber, 0.0 sugar.
('ground_beef_80_20', 'Ground Beef 80/20 (Cooked)', 254, 25.6, 0.0, 17.1,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground beef 80/20', '80/20 ground beef', 'regular ground beef', '80 lean ground beef', 'ground chuck'],
 'proteins', NULL, 1, '254 cal/100g cooked. Per 3 oz patty (85g): 216 cal. Standard ground beef for burgers. More flavor from higher fat.', TRUE),

-- Sirloin Steak (cooked): per 100g USDA: 206 cal, 28.5P, 0.0C, 9.4F, 0.0 fiber, 0.0 sugar.
('sirloin_steak', 'Sirloin Steak (Cooked)', 206, 28.5, 0.0, 9.4,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['sirloin steak', 'sirloin', 'top sirloin', 'grilled sirloin steak', 'sirloin steak cooked'],
 'proteins', NULL, 1, '206 cal/100g cooked. Per 3 oz (85g): 175 cal. Lean steak cut with excellent protein-to-fat ratio.', TRUE),

-- Ribeye Steak (cooked): per 100g USDA: 271 cal, 26.0P, 0.0C, 18.0F, 0.0 fiber, 0.0 sugar.
('ribeye_steak', 'Ribeye Steak (Cooked)', 271, 26.0, 0.0, 18.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ribeye steak', 'ribeye', 'rib eye steak', 'grilled ribeye', 'ribeye cooked'],
 'proteins', NULL, 1, '271 cal/100g cooked. Per 3 oz (85g): 230 cal. Well-marbled, flavorful steak cut. Higher in fat.', TRUE),

-- Salmon (cooked, Atlantic, farmed): per 100g USDA: 208 cal, 20.4P, 0.0C, 13.4F, 0.0 fiber, 0.0 sugar.
('salmon_cooked', 'Salmon (Cooked)', 208, 20.4, 0.0, 13.4,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['salmon', 'cooked salmon', 'baked salmon', 'grilled salmon', 'atlantic salmon', 'salmon fillet'],
 'proteins', NULL, 1, '208 cal/100g cooked. Per fillet (154g): 320 cal. Excellent source of omega-3 fatty acids and vitamin D.', TRUE),

-- Tilapia (cooked): per 100g USDA: 128 cal, 26.2P, 0.0C, 2.7F, 0.0 fiber, 0.0 sugar.
('tilapia_cooked', 'Tilapia (Cooked)', 128, 26.2, 0.0, 2.7,
 0.0, 0.0, 87, NULL,
 'usda', ARRAY['tilapia', 'cooked tilapia', 'baked tilapia', 'grilled tilapia', 'tilapia fillet'],
 'proteins', NULL, 1, '128 cal/100g cooked. Per fillet (87g): 111 cal. Mild-flavored, lean white fish. Very low in fat.', TRUE),

-- Shrimp (cooked): per 100g USDA: 99 cal, 24.0P, 0.2C, 0.3F, 0.0 fiber, 0.0 sugar.
('shrimp_cooked', 'Shrimp (Cooked)', 99, 24.0, 0.2, 0.3,
 0.0, 0.0, 85, 7,
 'usda', ARRAY['shrimp', 'cooked shrimp', 'grilled shrimp', 'steamed shrimp', 'prawns', 'jumbo shrimp', 'jhinga'],
 'proteins', NULL, 1, '99 cal/100g cooked. Per 3 oz (85g): 84 cal. Very lean protein. Low calorie, high protein.', TRUE),

-- Pork Chop (cooked, boneless): per 100g USDA: 231 cal, 25.7P, 0.0C, 13.7F, 0.0 fiber, 0.0 sugar.
('pork_chop_cooked', 'Pork Chop (Cooked)', 231, 25.7, 0.0, 13.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['pork chop', 'cooked pork chop', 'grilled pork chop', 'pork loin chop', 'boneless pork chop'],
 'proteins', NULL, 1, '231 cal/100g cooked. Per chop (85g): 196 cal. Good source of thiamin (B1) and selenium.', TRUE),

-- Turkey Breast (cooked, skinless): per 100g USDA: 135 cal, 30.0P, 0.0C, 0.7F, 0.0 fiber, 0.0 sugar.
('turkey_breast_cooked', 'Turkey Breast (Cooked)', 135, 30.0, 0.0, 0.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['turkey breast', 'cooked turkey breast', 'roasted turkey breast', 'turkey breast sliced'],
 'proteins', NULL, 1, '135 cal/100g cooked. Per 3 oz (85g): 115 cal. Leanest common poultry. Even leaner than chicken breast.', TRUE),

-- Tofu (firm): per 100g USDA: 76 cal, 8.1P, 1.9C, 4.8F, 0.3 fiber, 0.5 sugar.
('tofu_firm', 'Tofu (Firm)', 76, 8.1, 1.9, 4.8,
 0.3, 0.5, 126, NULL,
 'usda', ARRAY['tofu', 'firm tofu', 'extra firm tofu', 'bean curd', 'soy tofu'],
 'proteins', NULL, 1, '76 cal/100g. Per 0.5 cup (126g): 96 cal. Complete plant protein. Versatile meat substitute.', TRUE),

-- Tempeh: per 100g USDA: 192 cal, 20.3P, 7.6C, 10.8F, 0.0 fiber, 0.0 sugar.
('tempeh', 'Tempeh', 192, 20.3, 7.6, 10.8,
 0.0, 0.0, 84, NULL,
 'usda', ARRAY['tempeh', 'soy tempeh', 'fermented soybean', 'tempeh block'],
 'proteins', NULL, 1, '192 cal/100g. Per 3 oz (84g): 161 cal. Fermented soybeans. Higher protein than tofu. Nutty flavor.', TRUE),

-- Whole Egg (large, cooked): per 100g USDA: 155 cal, 12.6P, 1.1C, 10.6F, 0.0 fiber, 1.1 sugar. Large egg ~50g.
('whole_egg', 'Egg (Large, Whole)', 155, 12.6, 1.1, 10.6,
 0.0, 1.1, 50, 50,
 'usda', ARRAY['egg', 'whole egg', 'large egg', 'hard boiled egg', 'scrambled egg', 'fried egg', 'anda'],
 'proteins', NULL, 1, '155 cal/100g. 1 large egg (50g): 78 cal. Complete protein with choline, B12, and vitamin D.', TRUE),

-- Egg White (large): per 100g USDA: 52 cal, 10.9P, 0.7C, 0.2F, 0.0 fiber, 0.7 sugar. One white ~33g.
('egg_white', 'Egg White (Large)', 52, 10.9, 0.7, 0.2,
 0.0, 0.7, 33, 33,
 'usda', ARRAY['egg white', 'egg whites', 'large egg white', 'liquid egg whites'],
 'proteins', NULL, 1, '52 cal/100g. 1 large egg white (33g): 17 cal. Pure protein with virtually no fat. Popular in bodybuilding.', TRUE),

-- ==========================================
-- G. DAIRY (~20 items)
-- ==========================================

-- Whole Milk: per 100g USDA: 61 cal, 3.2P, 4.8C, 3.3F, 0.0 fiber, 5.1 sugar.
('whole_milk', 'Whole Milk', 61, 3.2, 4.8, 3.3,
 0.0, 5.1, 244, NULL,
 'usda', ARRAY['whole milk', 'full fat milk', 'vitamin d milk', 'regular milk', 'full cream milk'],
 'dairy', NULL, 1, '61 cal/100g. 1 cup (244g): 149 cal. Contains vitamins A and D. 3.25% milk fat.', TRUE),

-- 2% Milk: per 100g USDA: 50 cal, 3.3P, 4.8C, 2.0F, 0.0 fiber, 5.1 sugar.
('two_percent_milk', '2% Reduced Fat Milk', 50, 3.3, 4.8, 2.0,
 0.0, 5.1, 244, NULL,
 'usda', ARRAY['2% milk', '2 percent milk', 'reduced fat milk', 'low fat milk', 'two percent milk'],
 'dairy', NULL, 1, '50 cal/100g. 1 cup (244g): 122 cal. Most popular milk in the US. Good balance of taste and fat.', TRUE),

-- Skim Milk: per 100g USDA: 34 cal, 3.4P, 5.0C, 0.1F, 0.0 fiber, 5.1 sugar.
('skim_milk', 'Skim Milk (Fat Free)', 34, 3.4, 5.0, 0.1,
 0.0, 5.1, 245, NULL,
 'usda', ARRAY['skim milk', 'fat free milk', 'nonfat milk', 'skimmed milk', '0% milk'],
 'dairy', NULL, 1, '34 cal/100g. 1 cup (245g): 83 cal. Lowest calorie cow milk. Slightly higher protein per calorie.', TRUE),

-- Fairlife 2% Milk: per 100g: 50 cal, 5.4P, 2.5C, 1.9F, 0.0 fiber, 2.5 sugar.
('fairlife_2_percent', 'Fairlife 2% Ultra-Filtered Milk', 50, 5.4, 2.5, 1.9,
 0.0, 2.5, 240, NULL,
 'fairlife', ARRAY['fairlife 2% milk', 'fairlife milk', 'fairlife 2 percent', 'ultra filtered milk', 'fairlife'],
 'dairy', 'Fairlife', 1, '50 cal/100g. 1 cup (240g): 120 cal. 50% more protein, 50% less sugar than regular milk. Lactose-free.', TRUE),

-- Cottage Cheese 4%: per 100g USDA: 98 cal, 11.1P, 3.4C, 4.3F, 0.0 fiber, 2.7 sugar.
('cottage_cheese_4', 'Cottage Cheese (4% Full Fat)', 98, 11.1, 3.4, 4.3,
 0.0, 2.7, 113, NULL,
 'usda', ARRAY['cottage cheese', 'full fat cottage cheese', '4% cottage cheese', 'creamed cottage cheese'],
 'dairy', NULL, 1, '98 cal/100g. 0.5 cup (113g): 111 cal. High protein dairy. Popular bodybuilding food.', TRUE),

-- Cottage Cheese 2%: per 100g USDA: 81 cal, 10.5P, 4.3C, 2.3F, 0.0 fiber, 4.0 sugar.
('cottage_cheese_2', 'Cottage Cheese (2% Low Fat)', 81, 10.5, 4.3, 2.3,
 0.0, 4.0, 113, NULL,
 'usda', ARRAY['low fat cottage cheese', '2% cottage cheese', 'lowfat cottage cheese'],
 'dairy', NULL, 1, '81 cal/100g. 0.5 cup (113g): 92 cal. Good protein-to-calorie ratio.', TRUE),

-- Cottage Cheese 1%: per 100g USDA: 72 cal, 10.3P, 3.9C, 1.0F, 0.0 fiber, 3.5 sugar.
('cottage_cheese_1', 'Cottage Cheese (1% Low Fat)', 72, 10.3, 3.9, 1.0,
 0.0, 3.5, 113, NULL,
 'usda', ARRAY['1% cottage cheese', 'light cottage cheese', 'fat free cottage cheese'],
 'dairy', NULL, 1, '72 cal/100g. 0.5 cup (113g): 81 cal. Leanest cottage cheese option with high protein.', TRUE),

-- Philadelphia Cream Cheese: per 100g: 342 cal, 6.2P, 4.1C, 34.2F, 0.0 fiber, 3.2 sugar.
('philadelphia_cream_cheese', 'Philadelphia Cream Cheese', 342, 6.2, 4.1, 34.2,
 0.0, 3.2, 28, NULL,
 'kraft', ARRAY['cream cheese', 'philadelphia cream cheese', 'philly cream cheese', 'block cream cheese', 'cream cheese spread'],
 'dairy', 'Philadelphia', 1, '342 cal/100g. Per tbsp (28g): 96 cal. Classic cream cheese for bagels and cheesecake.', TRUE),

-- Sour Cream: per 100g USDA: 198 cal, 2.4P, 4.6C, 19.4F, 0.0 fiber, 3.5 sugar.
('sour_cream', 'Sour Cream', 198, 2.4, 4.6, 19.4,
 0.0, 3.5, 30, NULL,
 'usda', ARRAY['sour cream', 'regular sour cream', 'full fat sour cream', 'daisy sour cream'],
 'dairy', NULL, 1, '198 cal/100g. Per 2 tbsp (30g): 59 cal. Common topping for baked potatoes, tacos, and nachos.', TRUE),

-- Butter (salted): per 100g USDA: 717 cal, 0.9P, 0.1C, 81.1F, 0.0 fiber, 0.1 sugar.
('butter_salted', 'Butter (Salted)', 717, 0.9, 0.1, 81.1,
 0.0, 0.1, 14, NULL,
 'usda', ARRAY['butter', 'salted butter', 'sweet cream butter', 'regular butter'],
 'dairy', NULL, 1, '717 cal/100g. Per tbsp (14g): 100 cal. 81% fat. Use in moderation.', TRUE),

-- Kerrygold Butter: per 100g: 720 cal, 0.7P, 0.1C, 81.0F, 0.0 fiber, 0.1 sugar.
('kerrygold_butter', 'Kerrygold Irish Butter', 720, 0.7, 0.1, 81.0,
 0.0, 0.1, 14, NULL,
 'kerrygold', ARRAY['kerrygold butter', 'kerrygold', 'irish butter', 'grass fed butter', 'kerrygold pure irish butter'],
 'dairy', 'Kerrygold', 1, '720 cal/100g. Per tbsp (14g): 101 cal. Grass-fed, rich golden color, higher in omega-3 and CLA.', TRUE),

-- American Cheese (slice): per 100g USDA: 307 cal, 17.1P, 6.3C, 23.8F, 0.0 fiber, 5.8 sugar.
('american_cheese', 'American Cheese Slice', 307, 17.1, 6.3, 23.8,
 0.0, 5.8, 21, 21,
 'usda', ARRAY['american cheese', 'american cheese slice', 'kraft american cheese', 'singles cheese', 'processed cheese'],
 'dairy', NULL, 1, '307 cal/100g. Per slice (21g): 64 cal. Processed cheese. Popular for burgers and grilled cheese.', TRUE),

-- Cheddar Cheese: per 100g USDA: 403 cal, 24.9P, 1.3C, 33.1F, 0.0 fiber, 0.5 sugar.
('cheddar_cheese', 'Cheddar Cheese', 403, 24.9, 1.3, 33.1,
 0.0, 0.5, 28, NULL,
 'usda', ARRAY['cheddar cheese', 'cheddar', 'sharp cheddar', 'mild cheddar', 'aged cheddar', 'shredded cheddar'],
 'dairy', NULL, 1, '403 cal/100g. Per 1 oz (28g): 113 cal. Rich in calcium (721mg/100g) and protein.', TRUE),

-- Mozzarella Cheese: per 100g USDA: 280 cal, 27.5P, 3.1C, 17.1F, 0.0 fiber, 1.0 sugar.
('mozzarella_cheese', 'Mozzarella Cheese', 280, 27.5, 3.1, 17.1,
 0.0, 1.0, 28, NULL,
 'usda', ARRAY['mozzarella', 'mozzarella cheese', 'part skim mozzarella', 'shredded mozzarella', 'fresh mozzarella', 'string cheese'],
 'dairy', NULL, 1, '280 cal/100g. Per 1 oz (28g): 78 cal. Lower fat than cheddar. Key pizza cheese.', TRUE),

-- Parmesan Cheese: per 100g USDA: 392 cal, 35.8P, 3.2C, 25.8F, 0.0 fiber, 0.8 sugar.
('parmesan_cheese', 'Parmesan Cheese', 392, 35.8, 3.2, 25.8,
 0.0, 0.8, 5, NULL,
 'usda', ARRAY['parmesan', 'parmesan cheese', 'parmigiano reggiano', 'grated parmesan', 'parm'],
 'dairy', NULL, 1, '392 cal/100g. Per tbsp grated (5g): 20 cal. Highest protein cheese. Used as flavoring in small amounts.', TRUE),

-- Swiss Cheese: per 100g USDA: 380 cal, 27.0P, 5.4C, 27.8F, 0.0 fiber, 1.4 sugar.
('swiss_cheese', 'Swiss Cheese', 380, 27.0, 5.4, 27.8,
 0.0, 1.4, 28, NULL,
 'usda', ARRAY['swiss cheese', 'swiss', 'emmental cheese', 'emmentaler', 'baby swiss'],
 'dairy', NULL, 1, '380 cal/100g. Per 1 oz (28g): 106 cal. Known for characteristic holes. Rich in calcium and vitamin B12.', TRUE),

-- Heavy Whipping Cream: per 100g USDA: 340 cal, 2.1P, 2.8C, 36.1F, 0.0 fiber, 2.9 sugar.
('heavy_whipping_cream', 'Heavy Whipping Cream', 340, 2.1, 2.8, 36.1,
 0.0, 2.9, 15, NULL,
 'usda', ARRAY['heavy cream', 'heavy whipping cream', 'whipping cream', 'double cream', 'heavy cream for coffee'],
 'dairy', NULL, 1, '340 cal/100g. Per tbsp (15g): 51 cal. 36% milk fat. Used in sauces, whipped cream, and coffee.', TRUE),

-- Half and Half: per 100g USDA: 131 cal, 2.9P, 4.3C, 11.5F, 0.0 fiber, 4.1 sugar.
('half_and_half', 'Half and Half', 131, 2.9, 4.3, 11.5,
 0.0, 4.1, 15, NULL,
 'usda', ARRAY['half and half', 'half & half', 'coffee cream', 'light cream'],
 'dairy', NULL, 1, '131 cal/100g. Per tbsp (15g): 20 cal. 10-12% milk fat. Popular coffee creamer.', TRUE),

-- Oatly Oat Milk (Original): per 100g: 50 cal, 0.4P, 6.3C, 2.5F, 0.4 fiber, 2.9 sugar.
('oatly_oat_milk', 'Oatly Oat Milk (Original)', 50, 0.4, 6.3, 2.5,
 0.4, 2.9, 240, NULL,
 'oatly', ARRAY['oat milk', 'oatly', 'oatly oat milk', 'oatly original', 'oat milk original'],
 'dairy', 'Oatly', 1, '50 cal/100g. 1 cup (240g): 120 cal. Vegan, fortified with calcium and vitamin D. Popular coffee milk.', TRUE),

-- Almond Milk (unsweetened): per 100g USDA: 15 cal, 0.6P, 0.3C, 1.1F, 0.0 fiber, 0.0 sugar.
('almond_milk_unsweetened', 'Almond Milk (Unsweetened)', 15, 0.6, 0.3, 1.1,
 0.0, 0.0, 240, NULL,
 'usda', ARRAY['almond milk', 'unsweetened almond milk', 'almond milk unsweetened', 'almond breeze unsweetened'],
 'dairy', NULL, 1, '15 cal/100g. 1 cup (240g): 36 cal. Very low calorie milk alternative. Vegan. Fortified with calcium.', TRUE),

-- Soy Milk: per 100g USDA: 33 cal, 2.8P, 1.7C, 1.6F, 0.2 fiber, 0.8 sugar.
('soy_milk', 'Soy Milk', 33, 2.8, 1.7, 1.6,
 0.2, 0.8, 243, NULL,
 'usda', ARRAY['soy milk', 'soymilk', 'silk soy milk', 'unsweetened soy milk', 'soya milk'],
 'dairy', NULL, 1, '33 cal/100g. 1 cup (243g): 80 cal. Best plant milk for protein. Complete protein source.', TRUE),

-- ==========================================
-- H. NUT BUTTERS (~8 items)
-- ==========================================

-- Jif Creamy Peanut Butter: per 100g: 588 cal, 21.9P, 21.9C, 50.0F, 6.3 fiber, 9.4 sugar.
('jif_creamy_peanut_butter', 'Jif Creamy Peanut Butter', 588, 21.9, 21.9, 50.0,
 6.3, 9.4, 33, NULL,
 'jif', ARRAY['jif peanut butter', 'jif creamy', 'jif pb', 'jif creamy peanut butter'],
 'nut_butters', 'Jif', 1, '588 cal/100g. Per 2 tbsp (33g): 194 cal. Most popular PB brand in the US. Contains added sugar and palm oil.', TRUE),

-- Skippy Creamy Peanut Butter: per 100g: 588 cal, 21.9P, 21.9C, 50.0F, 6.3 fiber, 9.4 sugar.
('skippy_creamy_peanut_butter', 'Skippy Creamy Peanut Butter', 588, 21.9, 21.9, 50.0,
 6.3, 9.4, 33, NULL,
 'skippy', ARRAY['skippy peanut butter', 'skippy creamy', 'skippy pb', 'skippy creamy peanut butter'],
 'nut_butters', 'Skippy', 1, '588 cal/100g. Per 2 tbsp (33g): 194 cal. Very similar nutrition to Jif. Creamier texture.', TRUE),

-- Almond Butter (generic): per 100g USDA: 614 cal, 21.0P, 18.8C, 55.5F, 10.5 fiber, 4.4 sugar.
('almond_butter', 'Almond Butter', 614, 21.0, 18.8, 55.5,
 10.5, 4.4, 32, NULL,
 'usda', ARRAY['almond butter', 'almond nut butter', 'plain almond butter', 'natural almond butter'],
 'nut_butters', NULL, 1, '614 cal/100g. Per 2 tbsp (32g): 196 cal. Higher in fiber and vitamin E than peanut butter.', TRUE),

-- Cashew Butter (generic): per 100g USDA: 587 cal, 17.6P, 27.6C, 49.4F, 2.0 fiber, 5.7 sugar.
('cashew_butter', 'Cashew Butter', 587, 17.6, 27.6, 49.4,
 2.0, 5.7, 32, NULL,
 'usda', ARRAY['cashew butter', 'cashew nut butter', 'natural cashew butter'],
 'nut_butters', NULL, 1, '587 cal/100g. Per 2 tbsp (32g): 188 cal. Creamiest nut butter. Lower protein than peanut or almond butter.', TRUE),

-- Justin's Almond Butter: per 100g: 594 cal, 21.9P, 18.8C, 50.0F, 9.4 fiber, 6.3 sugar.
('justins_almond_butter', 'Justin''s Classic Almond Butter', 594, 21.9, 18.8, 50.0,
 9.4, 6.3, 32, NULL,
 'justins', ARRAY['justin''s almond butter', 'justins almond butter', 'justin''s classic almond butter'],
 'nut_butters', 'Justin''s', 1, '594 cal/100g. Per 2 tbsp (32g): 190 cal. Premium almond butter brand. Dry-roasted almonds with palm oil.', TRUE),

-- SunButter (sunflower seed butter): per 100g: 617 cal, 17.6P, 23.5C, 52.9F, 5.9 fiber, 11.8 sugar.
('sunbutter', 'SunButter Sunflower Butter', 617, 17.6, 23.5, 52.9,
 5.9, 11.8, 32, NULL,
 'sunbutter', ARRAY['sunbutter', 'sunflower butter', 'sunflower seed butter', 'sun butter', 'nut free butter'],
 'nut_butters', 'SunButter', 1, '617 cal/100g. Per 2 tbsp (32g): 197 cal. Nut-free allergen alternative. Made from sunflower seeds.', TRUE),

-- Tahini (sesame seed paste): per 100g USDA: 595 cal, 17.0P, 21.2C, 53.8F, 9.3 fiber, 0.5 sugar.
('tahini', 'Tahini', 595, 17.0, 21.2, 53.8,
 9.3, 0.5, 15, NULL,
 'usda', ARRAY['tahini', 'sesame paste', 'tahini paste', 'sesame butter', 'sesame seed paste'],
 'nut_butters', NULL, 1, '595 cal/100g. Per tbsp (15g): 89 cal. Key ingredient in hummus and halva. Rich in calcium and iron.', TRUE),

-- Nutella: per 100g: 539 cal, 6.3P, 57.5C, 30.9F, 3.4 fiber, 56.3 sugar.
('nutella', 'Nutella Hazelnut Spread', 539, 6.3, 57.5, 30.9,
 3.4, 56.3, 37, NULL,
 'ferrero', ARRAY['nutella', 'nutella spread', 'hazelnut spread', 'chocolate hazelnut spread', 'nutella hazelnut'],
 'nut_butters', 'Ferrero', 1, '539 cal/100g. Per 2 tbsp (37g): 200 cal. WARNING: 56% sugar by weight. More dessert than nut butter.', TRUE)

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
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
