-- 1579_update_variant_names_comprehensive.sql
-- Comprehensive variant_names update for food_nutrition_overrides.
-- Adds cooking methods, size variants, common search terms, and Hindi names
-- to improve food search matching.

-- ==========================================
-- A. FRUITS (~25 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'banana', 'medium banana', 'large banana', 'small banana', 'ripe banana',
  'green banana', '1 banana', 'kela', 'plantain', 'banana fruit',
  'organic banana', 'frozen banana', 'sliced banana'
] WHERE food_name_normalized = 'banana';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'apple', 'medium apple', 'large apple', 'small apple', 'green apple',
  'red apple', 'gala apple', 'fuji apple', '1 apple', 'seb',
  'granny smith apple', 'honeycrisp apple', 'pink lady apple',
  'sliced apple', 'apple slices', 'organic apple'
] WHERE food_name_normalized = 'apple';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'orange', 'medium orange', 'large orange', 'small orange', 'navel orange',
  'mandarin', 'santra', '1 orange', 'valencia orange', 'blood orange',
  'mandarin orange', 'clementine', 'tangerine', 'satsuma'
] WHERE food_name_normalized = 'orange';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'mango', 'ripe mango', 'aam', 'alphonso mango', 'large mango',
  'fresh mango', 'sliced mango', 'mango slices', 'mango chunks',
  'small mango', 'medium mango', 'kesar mango', 'mango fruit'
] WHERE food_name_normalized = 'mango';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'strawberry', 'strawberries', 'fresh strawberries', 'sliced strawberries',
  'frozen strawberries', 'organic strawberries', 'whole strawberries',
  'large strawberry', 'medium strawberry', '1 strawberry'
] WHERE food_name_normalized = 'strawberry';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'blueberry', 'blueberries', 'fresh blueberries', 'wild blueberries',
  'frozen blueberries', 'organic blueberries', 'dried blueberries',
  'blueberry fruit'
] WHERE food_name_normalized = 'blueberry';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'raspberry', 'raspberries', 'fresh raspberries', 'red raspberries',
  'frozen raspberries', 'organic raspberries', 'black raspberries',
  'raspberry fruit'
] WHERE food_name_normalized = 'raspberry';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'blackberry', 'blackberries', 'fresh blackberries', 'frozen blackberries',
  'organic blackberries', 'wild blackberries', 'blackberry fruit'
] WHERE food_name_normalized = 'blackberry';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'grapes', 'red grapes', 'green grapes', 'seedless grapes',
  'thompson grapes', 'concord grapes', 'black grapes', 'frozen grapes',
  'grape', 'angoor', 'angur'
] WHERE food_name_normalized = 'grapes';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'watermelon', 'watermelon slices', 'seedless watermelon', 'watermelon cubes',
  'watermelon chunks', 'tarbooz', 'tarbuj', 'cut watermelon',
  'fresh watermelon', 'large watermelon slice'
] WHERE food_name_normalized = 'watermelon';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'pineapple', 'fresh pineapple', 'pineapple chunks', 'pineapple slices',
  'canned pineapple', 'ananas', 'pineapple rings', 'cut pineapple',
  'pineapple pieces', 'frozen pineapple'
] WHERE food_name_normalized = 'pineapple';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'peach', 'peaches', 'fresh peach', 'yellow peach', 'white peach',
  'medium peach', 'large peach', 'small peach', '1 peach',
  'sliced peach', 'aadu', 'aaru'
] WHERE food_name_normalized = 'peach';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'pear', 'pears', 'bartlett pear', 'anjou pear', 'bosc pear',
  'medium pear', 'large pear', 'small pear', '1 pear',
  'green pear', 'red pear', 'nashpati'
] WHERE food_name_normalized = 'pear';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kiwi', 'kiwifruit', 'green kiwi', 'gold kiwi', 'kiwi fruit',
  'medium kiwi', 'large kiwi', 'small kiwi', '1 kiwi',
  'golden kiwi', 'zespri kiwi'
] WHERE food_name_normalized = 'kiwi';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cherry', 'cherries', 'sweet cherries', 'fresh cherries', 'bing cherries',
  'dark cherries', 'tart cherries', 'frozen cherries', 'pitted cherries',
  'rainier cherries', 'maraschino cherries'
] WHERE food_name_normalized = 'cherry';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'grapefruit', 'pink grapefruit', 'red grapefruit', 'white grapefruit',
  'medium grapefruit', 'large grapefruit', 'half grapefruit',
  'ruby red grapefruit', 'chakotra'
] WHERE food_name_normalized = 'grapefruit';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cantaloupe', 'cantaloupe melon', 'muskmelon', 'rockmelon',
  'kharbuja', 'kharbooja', 'cantaloupe slices', 'cantaloupe cubes',
  'fresh cantaloupe', 'medium cantaloupe'
] WHERE food_name_normalized = 'cantaloupe';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'honeydew', 'honeydew melon', 'honey dew melon', 'green melon',
  'honeydew slices', 'honeydew cubes', 'fresh honeydew',
  'medium honeydew'
] WHERE food_name_normalized = 'honeydew';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'avocado', 'half avocado', 'whole avocado', 'hass avocado',
  'avocado fruit', 'small avocado', 'medium avocado', 'large avocado',
  'avocados', 'california avocado', 'florida avocado',
  'guacamole avocado', 'sliced avocado', 'mashed avocado'
] WHERE food_name_normalized = 'avocado';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'date', 'dates', 'medjool date', 'medjool dates', 'deglet noor date',
  'khajoor', 'khajur', '1 date', 'dried date', 'fresh date',
  'pitted dates', 'stuffed date'
] WHERE food_name_normalized = 'date';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'pomegranate seeds', 'pomegranate', 'pomegranate arils', 'pom seeds',
  'anaar', 'anar', 'pomegranate fruit', 'fresh pomegranate',
  'pomegranate kernels'
] WHERE food_name_normalized = 'pomegranate_seeds';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'papaya', 'fresh papaya', 'papaya slices', 'pawpaw',
  'papita', 'ripe papaya', 'papaya chunks', 'medium papaya',
  'large papaya', 'green papaya'
] WHERE food_name_normalized = 'papaya';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'lemon', 'lemons', 'fresh lemon', 'lemon fruit',
  'nimbu', 'lemon juice', 'medium lemon', '1 lemon',
  'lemon wedge', 'lemon slice'
] WHERE food_name_normalized = 'lemon';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'lime', 'limes', 'fresh lime', 'key lime',
  'lime juice', 'medium lime', '1 lime',
  'lime wedge', 'lime slice', 'persian lime'
] WHERE food_name_normalized = 'lime';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'coconut', 'fresh coconut', 'coconut meat', 'raw coconut',
  'nariyal', 'coconut flesh', 'coconut pieces', 'dried coconut',
  'desiccated coconut', 'shredded coconut', 'coconut chunks'
] WHERE food_name_normalized = 'coconut_fresh';

-- ==========================================
-- B. VEGETABLES (~29 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'broccoli', 'steamed broccoli', 'raw broccoli', 'roasted broccoli',
  'broccoli florets', 'boiled broccoli', 'grilled broccoli',
  'sauteed broccoli', 'frozen broccoli', 'fresh broccoli',
  'baked broccoli', 'broccoli crowns'
] WHERE food_name_normalized = 'broccoli';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'spinach', 'raw spinach', 'cooked spinach', 'baby spinach',
  'palak', 'steamed spinach', 'sauteed spinach', 'wilted spinach',
  'fresh spinach', 'frozen spinach', 'spinach leaves',
  'creamed spinach', 'boiled spinach'
] WHERE food_name_normalized = 'spinach';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kale', 'fresh kale', 'curly kale', 'lacinato kale',
  'baby kale', 'tuscan kale', 'raw kale', 'steamed kale',
  'sauteed kale', 'roasted kale', 'kale chips', 'massaged kale',
  'dinosaur kale', 'chopped kale'
] WHERE food_name_normalized = 'kale';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'carrot', 'carrots', 'raw carrot', 'baby carrots', 'carrot sticks',
  'boiled carrot', 'steamed carrot', 'roasted carrot', 'grilled carrot',
  'grated carrot', 'shredded carrot', 'gajar',
  'medium carrot', 'large carrot', '1 carrot'
] WHERE food_name_normalized = 'carrot';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cucumber', 'cucumbers', 'fresh cucumber', 'sliced cucumber',
  'english cucumber', 'kheera', 'raw cucumber', 'diced cucumber',
  'cucumber slices', 'persian cucumber', 'mini cucumber',
  'chopped cucumber', 'peeled cucumber'
] WHERE food_name_normalized = 'cucumber';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'tomato', 'tomatoes', 'fresh tomato', 'red tomato', 'cherry tomatoes',
  'grape tomatoes', 'roma tomato', 'tamatar', 'sliced tomato',
  'diced tomato', 'raw tomato', 'medium tomato', 'large tomato',
  'heirloom tomato', 'beefsteak tomato', 'plum tomato'
] WHERE food_name_normalized = 'tomato';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'red bell pepper', 'red pepper', 'bell pepper red', 'sweet red pepper',
  'capsicum red', 'roasted red pepper', 'grilled red pepper',
  'raw red pepper', 'sliced red pepper', 'diced red pepper',
  'lal shimla mirch', 'red capsicum'
] WHERE food_name_normalized = 'red_bell_pepper';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'green bell pepper', 'green pepper', 'bell pepper green', 'sweet green pepper',
  'capsicum green', 'roasted green pepper', 'grilled green pepper',
  'raw green pepper', 'sliced green pepper', 'diced green pepper',
  'hari shimla mirch', 'green capsicum'
] WHERE food_name_normalized = 'green_bell_pepper';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'onion', 'onions', 'yellow onion', 'white onion', 'red onion',
  'sweet onion', 'pyaaz', 'raw onion', 'diced onion', 'sliced onion',
  'chopped onion', 'sauteed onion', 'caramelized onion',
  'grilled onion', 'medium onion', '1 onion', 'vidalia onion'
] WHERE food_name_normalized = 'onion';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'garlic', 'garlic clove', 'fresh garlic', 'minced garlic',
  'lehsun', 'crushed garlic', 'chopped garlic', 'roasted garlic',
  'garlic cloves', '1 clove garlic', 'raw garlic'
] WHERE food_name_normalized = 'garlic';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'zucchini', 'zucchini squash', 'courgette', 'green zucchini',
  'zoodles', 'grilled zucchini', 'roasted zucchini', 'sauteed zucchini',
  'raw zucchini', 'sliced zucchini', 'spiralized zucchini',
  'baked zucchini', 'zucchini noodles'
] WHERE food_name_normalized = 'zucchini';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cauliflower', 'cauliflower florets', 'riced cauliflower',
  'cauliflower rice', 'gobi', 'roasted cauliflower', 'steamed cauliflower',
  'raw cauliflower', 'grilled cauliflower', 'mashed cauliflower',
  'baked cauliflower', 'boiled cauliflower', 'frozen cauliflower',
  'phool gobi'
] WHERE food_name_normalized = 'cauliflower';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'asparagus', 'asparagus spears', 'green asparagus', 'fresh asparagus',
  'grilled asparagus', 'roasted asparagus', 'steamed asparagus',
  'sauteed asparagus', 'raw asparagus', 'baked asparagus',
  'white asparagus', 'asparagus tips'
] WHERE food_name_normalized = 'asparagus';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'green beans', 'string beans', 'snap beans', 'french beans',
  'haricots verts', 'steamed green beans', 'roasted green beans',
  'sauteed green beans', 'boiled green beans', 'raw green beans',
  'frozen green beans', 'grilled green beans', 'french cut green beans'
] WHERE food_name_normalized = 'green_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'brussels sprouts', 'brussel sprouts', 'brussels', 'sprouts',
  'roasted brussels sprouts', 'steamed brussels sprouts',
  'grilled brussels sprouts', 'sauteed brussels sprouts',
  'raw brussels sprouts', 'shaved brussels sprouts',
  'baked brussels sprouts', 'crispy brussels sprouts'
] WHERE food_name_normalized = 'brussels_sprouts';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'celery', 'celery sticks', 'celery stalks', 'fresh celery',
  'raw celery', 'chopped celery', 'diced celery', 'celery ribs',
  'celery pieces', 'ajwain patta'
] WHERE food_name_normalized = 'celery';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'romaine lettuce', 'romaine', 'cos lettuce', 'romaine hearts',
  'chopped romaine', 'shredded romaine', 'romaine salad',
  'fresh romaine', 'romaine leaves'
] WHERE food_name_normalized = 'romaine_lettuce';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'iceberg lettuce', 'iceberg', 'head lettuce', 'crisphead lettuce',
  'chopped iceberg', 'shredded iceberg', 'iceberg salad',
  'lettuce', 'salad lettuce'
] WHERE food_name_normalized = 'iceberg_lettuce';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cabbage', 'green cabbage', 'red cabbage', 'napa cabbage',
  'patta gobi', 'bandh gobi', 'shredded cabbage', 'chopped cabbage',
  'raw cabbage', 'steamed cabbage', 'sauteed cabbage', 'boiled cabbage',
  'coleslaw cabbage', 'purple cabbage'
] WHERE food_name_normalized = 'cabbage';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'corn', 'sweet corn', 'corn on the cob', 'corn kernels',
  'yellow corn', 'maize', 'makka', 'boiled corn', 'grilled corn',
  'roasted corn', 'steamed corn', 'bhutta', 'fresh corn',
  'corn ear', '1 corn'
] WHERE food_name_normalized = 'corn';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'peas', 'green peas', 'garden peas', 'sweet peas',
  'english peas', 'matar', 'boiled peas', 'steamed peas',
  'frozen peas', 'fresh peas', 'cooked peas', 'sugar snap peas',
  'snow peas', 'hara matar'
] WHERE food_name_normalized = 'peas';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'edamame', 'edamame beans', 'soybeans in pod', 'mukimame',
  'steamed edamame', 'boiled edamame', 'shelled edamame',
  'frozen edamame', 'fresh edamame'
] WHERE food_name_normalized = 'edamame';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'mushroom', 'mushrooms', 'white mushroom', 'button mushroom',
  'champignon', 'sliced mushrooms', 'raw mushroom', 'sauteed mushrooms',
  'grilled mushrooms', 'roasted mushrooms', 'cooked mushrooms',
  'fresh mushrooms', 'diced mushrooms', 'cremini mushroom'
] WHERE food_name_normalized = 'mushroom';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'portobello mushroom', 'portobello', 'portabella mushroom',
  'portabello', 'grilled portobello', 'roasted portobello',
  'baked portobello', 'stuffed portobello', 'portobello cap',
  'portobello burger', 'raw portobello'
] WHERE food_name_normalized = 'portobello_mushroom';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'beet', 'beets', 'beetroot', 'red beet', 'golden beet',
  'chukandar', 'roasted beet', 'boiled beet', 'steamed beet',
  'raw beet', 'pickled beet', 'beet root', 'fresh beet',
  'cooked beet', 'baked beet'
] WHERE food_name_normalized = 'beet';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'eggplant', 'aubergine', 'brinjal', 'baingan',
  'roasted eggplant', 'grilled eggplant', 'baked eggplant',
  'sauteed eggplant', 'fried eggplant', 'raw eggplant',
  'baby eggplant', 'japanese eggplant', 'chinese eggplant'
] WHERE food_name_normalized = 'eggplant';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'sweet potato', 'yam', 'shakarkandi',
  'steamed sweet potato', 'grilled sweet potato', 'medium sweet potato',
  'large sweet potato', '1 sweet potato', 'sweet potatoes',
  'roasted sweet potato'
] WHERE food_name_normalized = 'sweet_potato';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'potato', 'baked potato', 'aloo', 'russet potato', 'jacket potato',
  'idaho potato', 'medium potato', 'large potato', '1 potato',
  'grilled potato', 'steamed potato',
  'red potato', 'yukon gold potato', 'gold potato'
] WHERE food_name_normalized = 'baked_potato';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'butternut squash', 'butternut', 'winter squash',
  'baked butternut squash', 'roasted butternut squash',
  'steamed butternut squash', 'mashed butternut squash',
  'butternut squash soup', 'butternut squash cubes',
  'grilled butternut squash'
] WHERE food_name_normalized = 'butternut_squash';

-- ==========================================
-- C. PASTA & GRAINS (~15 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'spaghetti', 'cooked spaghetti', 'spaghetti noodles', 'pasta',
  'spaghetti pasta', 'boiled spaghetti', 'whole wheat spaghetti',
  'thin spaghetti', 'angel hair pasta', 'spaghettini'
] WHERE food_name_normalized = 'spaghetti_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'penne', 'cooked penne', 'penne pasta', 'penne rigate',
  'boiled penne', 'penne noodles', 'mostaccioli'
] WHERE food_name_normalized = 'penne_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'fettuccine', 'cooked fettuccine', 'fettuccine pasta', 'fettuccini',
  'boiled fettuccine', 'fettuccine noodles', 'flat pasta'
] WHERE food_name_normalized = 'fettuccine_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'macaroni', 'cooked macaroni', 'elbow macaroni', 'elbow pasta', 'mac',
  'boiled macaroni', 'mac and cheese pasta', 'macaroni noodles'
] WHERE food_name_normalized = 'macaroni_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'whole wheat pasta', 'whole grain pasta', 'whole wheat spaghetti',
  'wheat pasta', 'brown pasta', 'whole wheat penne',
  'whole wheat macaroni', 'whole grain spaghetti',
  'multigrain pasta', 'atta pasta'
] WHERE food_name_normalized = 'whole_wheat_pasta_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'quinoa', 'cooked quinoa', 'quinoa bowl', 'white quinoa',
  'red quinoa', 'black quinoa', 'tricolor quinoa',
  'quinoa grain', 'boiled quinoa', 'steamed quinoa',
  'quinoa salad', 'warm quinoa'
] WHERE food_name_normalized = 'quinoa_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'couscous', 'cooked couscous', 'pearl couscous', 'israeli couscous',
  'moroccan couscous', 'whole wheat couscous', 'steamed couscous',
  'couscous salad'
] WHERE food_name_normalized = 'couscous_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'basmati rice', 'basmati', 'steamed basmati', 'cooked basmati rice',
  'white basmati rice', 'chawal', 'boiled basmati rice',
  'long grain rice', 'indian rice', 'basmati chawal',
  'plain rice', 'white rice', 'steamed rice', 'cooked rice'
] WHERE food_name_normalized = 'basmati_rice_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'jasmine rice', 'cooked jasmine rice', 'thai jasmine rice',
  'white jasmine rice', 'steamed jasmine rice', 'boiled jasmine rice',
  'thai rice', 'fragrant rice'
] WHERE food_name_normalized = 'jasmine_rice_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'wild rice', 'cooked wild rice', 'wild rice blend',
  'boiled wild rice', 'steamed wild rice', 'wild rice pilaf',
  'wild rice mix'
] WHERE food_name_normalized = 'wild_rice_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'farro', 'cooked farro', 'emmer wheat', 'pearled farro',
  'boiled farro', 'farro grain', 'farro salad', 'warm farro'
] WHERE food_name_normalized = 'farro_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'bulgur', 'bulgur wheat', 'cooked bulgur', 'cracked wheat',
  'tabbouleh wheat', 'boiled bulgur', 'dalia', 'daliya',
  'bulgur pilaf'
] WHERE food_name_normalized = 'bulgur_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'oatmeal', 'cooked oatmeal', 'oat porridge', 'porridge',
  'rolled oats cooked', 'steel cut oats cooked', 'hot oatmeal',
  'cooked oats', 'daliya', 'oat meal', 'morning oats',
  'instant oatmeal', 'overnight oats', 'warm oatmeal',
  'bowl of oatmeal', 'quaker oats'
] WHERE food_name_normalized = 'oatmeal_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'grits', 'cooked grits', 'corn grits', 'hominy grits',
  'yellow grits', 'white grits', 'cheesy grits',
  'butter grits', 'stone ground grits', 'instant grits'
] WHERE food_name_normalized = 'grits_cooked';

-- ==========================================
-- D. BEANS & LEGUMES (~10 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'black beans', 'cooked black beans', 'canned black beans',
  'frijoles negros', 'turtle beans', 'black beans canned',
  'boiled black beans', 'seasoned black beans', 'black bean',
  'kale chane'
] WHERE food_name_normalized = 'black_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kidney beans', 'red kidney beans', 'cooked kidney beans', 'rajma',
  'canned kidney beans', 'boiled kidney beans', 'dark red kidney beans',
  'light red kidney beans', 'kidney bean', 'rajmah'
] WHERE food_name_normalized = 'kidney_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chickpeas', 'garbanzo beans', 'cooked chickpeas', 'chana', 'chole',
  'canned chickpeas', 'kabuli chana', 'boiled chickpeas',
  'roasted chickpeas', 'chickpea', 'garbanzo', 'hummus beans'
] WHERE food_name_normalized = 'chickpeas';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'green lentils', 'lentils', 'cooked lentils', 'french lentils',
  'dal', 'masoor', 'boiled lentils', 'lentil', 'brown lentils',
  'green dal', 'whole masoor', 'sabut masoor'
] WHERE food_name_normalized = 'green_lentils';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'red lentils', 'cooked red lentils', 'masoor dal', 'red dal',
  'split red lentils', 'boiled red lentils', 'lal masoor',
  'masoor ki dal', 'red lentil soup'
] WHERE food_name_normalized = 'red_lentils';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'pinto beans', 'cooked pinto beans', 'frijoles', 'refried bean base',
  'canned pinto beans', 'boiled pinto beans', 'pinto bean',
  'seasoned pinto beans'
] WHERE food_name_normalized = 'pinto_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'navy beans', 'white beans', 'cooked navy beans', 'haricot beans',
  'great northern beans', 'canned navy beans', 'boiled navy beans',
  'cannellini beans', 'white kidney beans', 'navy bean'
] WHERE food_name_normalized = 'navy_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'lima beans', 'butter beans', 'cooked lima beans', 'baby lima beans',
  'canned lima beans', 'boiled lima beans', 'large lima beans',
  'lima bean', 'frozen lima beans'
] WHERE food_name_normalized = 'lima_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'soybeans', 'cooked soybeans', 'soya beans', 'soy beans',
  'boiled soybeans', 'soybean', 'mature soybeans', 'dried soybeans'
] WHERE food_name_normalized = 'soybeans_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'split peas', 'cooked split peas', 'green split peas',
  'yellow split peas', 'split pea soup base', 'boiled split peas',
  'dried split peas', 'split pea', 'matar dal'
] WHERE food_name_normalized = 'split_peas';

-- ==========================================
-- E. CANNED GOODS (~12 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'canned tuna', 'tuna in water', 'canned tuna in water',
  'chunk light tuna', 'starkist tuna', 'bumble bee tuna',
  'tuna can', 'drained tuna', 'white albacore tuna',
  'tuna fish', 'tuna packet'
] WHERE food_name_normalized = 'canned_tuna_water';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'tuna in oil', 'canned tuna in oil', 'tuna packed in oil',
  'oil packed tuna', 'tuna in olive oil', 'tonno',
  'italian tuna', 'tuna in sunflower oil'
] WHERE food_name_normalized = 'canned_tuna_oil';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'canned salmon', 'canned pink salmon', 'salmon canned',
  'canned sockeye salmon', 'canned red salmon',
  'salmon in can', 'tinned salmon', 'canned wild salmon'
] WHERE food_name_normalized = 'canned_salmon';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'canned chicken', 'canned chicken breast', 'chunk chicken canned',
  'chicken in can', 'tinned chicken', 'canned white chicken'
] WHERE food_name_normalized = 'canned_chicken';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'campbell''s chicken noodle soup', 'campbells chicken noodle',
  'chicken noodle soup canned', 'chicken noodle soup',
  'campbell chicken noodle', 'campbells chicken noodle soup',
  'canned chicken noodle soup'
] WHERE food_name_normalized = 'campbells_chicken_noodle_soup';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'campbell''s tomato soup', 'campbells tomato soup',
  'tomato soup canned', 'cream of tomato soup',
  'campbell tomato soup', 'campbells tomato',
  'canned tomato soup', 'tomato soup'
] WHERE food_name_normalized = 'campbells_tomato_soup';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'amy''s lentil soup', 'amys lentil soup',
  'amy''s organic lentil soup', 'organic lentil soup',
  'amy lentil soup', 'amys organic lentil soup'
] WHERE food_name_normalized = 'amys_lentil_soup';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'bush''s baked beans', 'bushs baked beans', 'baked beans',
  'bush''s original baked beans', 'bush baked beans',
  'canned baked beans', 'bbq beans'
] WHERE food_name_normalized = 'bushs_baked_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'canned corn', 'canned sweet corn', 'corn canned',
  'canned corn kernels', 'creamed corn', 'tinned corn',
  'sweet corn canned', 'whole kernel corn canned'
] WHERE food_name_normalized = 'canned_corn';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'canned green beans', 'green beans canned', 'canned string beans',
  'canned cut green beans', 'tinned green beans',
  'canned french cut green beans'
] WHERE food_name_normalized = 'canned_green_beans';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'canned diced tomatoes', 'diced tomatoes', 'canned tomatoes',
  'crushed tomatoes', 'stewed tomatoes', 'tinned tomatoes',
  'chopped tomatoes canned', 'canned whole tomatoes',
  'san marzano tomatoes', 'fire roasted tomatoes'
] WHERE food_name_normalized = 'canned_diced_tomatoes';

-- ==========================================
-- F. BASIC PROTEINS (~15 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chicken breast', 'grilled chicken breast',
  'pan seared chicken', 'boneless chicken', 'skinless chicken breast',
  'roasted chicken breast',
  'boneless skinless chicken breast', 'chicken breast grilled',
  'sauteed chicken breast',
  'sliced chicken breast', 'diced chicken breast',
  'air fried chicken breast', 'tandoori chicken breast'
] WHERE food_name_normalized = 'chicken_breast_grilled';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'chicken thigh', 'cooked chicken thigh', 'boneless chicken thigh',
  'chicken thigh grilled', 'grilled chicken thigh',
  'roasted chicken thigh',
  'skinless chicken thigh',
  'pan seared chicken thigh', 'braised chicken thigh'
] WHERE food_name_normalized = 'chicken_thigh_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'ground beef 90/10', '90/10 ground beef', 'lean ground beef',
  '90 lean ground beef', 'extra lean ground beef',
  'cooked lean ground beef', 'browned lean ground beef',
  'lean mince', 'lean beef mince', 'keema lean'
] WHERE food_name_normalized = 'ground_beef_90_10';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'ground beef 80/20', '80/20 ground beef', 'regular ground beef',
  '80 lean ground beef', 'ground chuck', 'ground beef',
  'cooked ground beef', 'browned ground beef',
  'beef mince', 'minced beef', 'keema'
] WHERE food_name_normalized = 'ground_beef_80_20';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'sirloin steak', 'sirloin', 'top sirloin', 'grilled sirloin steak',
  'sirloin steak cooked', 'pan seared sirloin', 'broiled sirloin',
  'baked sirloin', 'medium rare sirloin', 'sirloin steak grilled'
] WHERE food_name_normalized = 'sirloin_steak';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'ribeye steak', 'ribeye', 'rib eye steak', 'grilled ribeye',
  'ribeye cooked', 'pan seared ribeye', 'broiled ribeye',
  'rib eye', 'cowboy steak', 'bone in ribeye',
  'medium rare ribeye', 'ribeye steak grilled'
] WHERE food_name_normalized = 'ribeye_steak';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'salmon', 'grilled salmon', 'pan seared salmon',
  'salmon fillet', 'atlantic salmon',
  'cooked salmon', 'roasted salmon', 'poached salmon',
  'broiled salmon', 'wild salmon', 'sockeye salmon',
  'salmon steak', 'bbq salmon', 'teriyaki salmon'
] WHERE food_name_normalized = 'salmon_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'tilapia', 'cooked tilapia', 'baked tilapia', 'grilled tilapia',
  'tilapia fillet', 'fried tilapia', 'pan seared tilapia',
  'broiled tilapia', 'blackened tilapia', 'tilapia fish'
] WHERE food_name_normalized = 'tilapia_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'shrimp', 'cooked shrimp', 'steamed shrimp',
  'prawns', 'jumbo shrimp', 'jhinga',
  'sauteed shrimp', 'garlic shrimp',
  'shrimp cocktail', 'large shrimp',
  'prawn', 'tiger prawns', 'king prawns'
] WHERE food_name_normalized = 'shrimp_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'pork chop', 'cooked pork chop', 'grilled pork chop',
  'pork loin chop', 'boneless pork chop', 'baked pork chop',
  'fried pork chop', 'pan seared pork chop', 'broiled pork chop',
  'bone in pork chop', 'center cut pork chop', 'pork cutlet'
] WHERE food_name_normalized = 'pork_chop_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'turkey breast', 'cooked turkey breast', 'roasted turkey breast',
  'turkey breast sliced', 'grilled turkey breast', 'baked turkey breast',
  'smoked turkey breast', 'turkey deli meat', 'sliced turkey',
  'turkey cold cuts', 'oven roasted turkey', 'turkey meat'
] WHERE food_name_normalized = 'turkey_breast_cooked';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'tofu', 'firm tofu', 'extra firm tofu', 'bean curd', 'soy tofu',
  'grilled tofu', 'baked tofu', 'pan seared tofu',
  'scrambled tofu', 'crispy tofu', 'marinated tofu',
  'pressed tofu', 'smoked tofu'
] WHERE food_name_normalized = 'tofu_firm';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'tempeh', 'soy tempeh', 'fermented soybean', 'tempeh block',
  'grilled tempeh', 'baked tempeh', 'fried tempeh',
  'pan seared tempeh', 'marinated tempeh', 'crumbled tempeh',
  'steamed tempeh', 'tempeh strips'
] WHERE food_name_normalized = 'tempeh';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'egg', 'large egg',
  '1 egg', 'anda', 'whole egg',
  'medium egg',
  'baked egg', 'deviled egg', '2 eggs', 'eggs'
] WHERE food_name_normalized = 'whole_egg';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'egg white', 'egg whites', 'boiled egg white', '1 egg white',
  'large egg white', 'liquid egg whites', 'egg white omelette',
  'scrambled egg whites', 'whipped egg whites',
  'pasteurized egg whites'
] WHERE food_name_normalized = 'egg_white';

-- ==========================================
-- G. DAIRY (~21 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'milk', 'whole milk', 'full fat milk', 'glass of milk', 'doodh',
  'vitamin d milk', 'regular milk', 'full cream milk',
  'cow milk', 'dairy milk', 'cup of milk', 'warm milk',
  'cold milk', '1 glass milk'
] WHERE food_name_normalized = 'whole_milk';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  '2% milk', '2 percent milk', 'reduced fat milk', 'low fat milk',
  'two percent milk', 'semi skimmed milk', '2% reduced fat milk',
  '2 percent dairy milk'
] WHERE food_name_normalized = 'two_percent_milk';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'skim milk', 'fat free milk', 'nonfat milk', 'skimmed milk',
  '0% milk', 'zero fat milk', 'non fat milk', 'light milk',
  'fat free dairy milk'
] WHERE food_name_normalized = 'skim_milk';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'fairlife 2% milk', 'fairlife milk', 'fairlife 2 percent',
  'ultra filtered milk', 'fairlife', 'fairlife 2%',
  'fairlife ultra filtered', 'fairlife protein milk'
] WHERE food_name_normalized = 'fairlife_2_percent';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cottage cheese', 'full fat cottage cheese', 'regular cottage cheese',
  '4% cottage cheese', 'creamed cottage cheese', 'paneer cottage cheese',
  'cottage cheese full fat', 'small curd cottage cheese',
  'large curd cottage cheese'
] WHERE food_name_normalized = 'cottage_cheese_4';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'low fat cottage cheese', '2% cottage cheese', 'lowfat cottage cheese',
  'reduced fat cottage cheese', 'cottage cheese 2%',
  'light cottage cheese 2%'
] WHERE food_name_normalized = 'cottage_cheese_2';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  '1% cottage cheese', 'light cottage cheese', 'fat free cottage cheese',
  'nonfat cottage cheese', 'diet cottage cheese',
  'zero fat cottage cheese'
] WHERE food_name_normalized = 'cottage_cheese_1';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cream cheese', 'philadelphia cream cheese', 'philly cream cheese',
  'block cream cheese', 'cream cheese spread', 'plain cream cheese',
  'original cream cheese', 'whipped cream cheese',
  'softened cream cheese'
] WHERE food_name_normalized = 'philadelphia_cream_cheese';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'sour cream', 'regular sour cream', 'full fat sour cream',
  'daisy sour cream', 'plain sour cream', 'thick sour cream',
  'sour cream dollop', 'cream sour'
] WHERE food_name_normalized = 'sour_cream';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'butter', 'salted butter', 'pat of butter', 'makhan',
  'sweet cream butter', 'regular butter', 'stick of butter',
  'melted butter', 'softened butter', '1 tbsp butter',
  'butter pat', 'cooking butter', 'table butter'
] WHERE food_name_normalized = 'butter_salted';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'kerrygold butter', 'kerrygold', 'irish butter', 'grass fed butter',
  'kerrygold pure irish butter', 'kerrygold salted butter',
  'kerrygold unsalted butter', 'european style butter',
  'premium butter'
] WHERE food_name_normalized = 'kerrygold_butter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'american cheese', 'american cheese slice', 'kraft american cheese',
  'singles cheese', 'processed cheese', 'american singles',
  'american cheese slices', 'kraft singles', 'deli american cheese',
  'yellow american cheese'
] WHERE food_name_normalized = 'american_cheese';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cheddar cheese', 'cheddar', 'sharp cheddar', 'mild cheddar',
  'aged cheddar', 'shredded cheddar', 'sliced cheddar',
  'block cheddar', 'cheddar slice', 'medium cheddar',
  'extra sharp cheddar', 'white cheddar', 'cheddar block'
] WHERE food_name_normalized = 'cheddar_cheese';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'mozzarella', 'mozzarella cheese', 'part skim mozzarella',
  'shredded mozzarella', 'fresh mozzarella', 'string cheese',
  'mozzarella ball', 'buffalo mozzarella', 'low moisture mozzarella',
  'mozzarella slices', 'melted mozzarella', 'pizza cheese'
] WHERE food_name_normalized = 'mozzarella_cheese';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'parmesan', 'parmesan cheese', 'parmigiano reggiano',
  'grated parmesan', 'parm', 'shaved parmesan',
  'parmesan shavings', 'parmigiano', 'parmesan wedge',
  'sprinkled parmesan'
] WHERE food_name_normalized = 'parmesan_cheese';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'swiss cheese', 'swiss', 'emmental cheese', 'emmentaler',
  'baby swiss', 'swiss cheese slice', 'sliced swiss',
  'jarlsberg', 'gruyere', 'swiss cheese block'
] WHERE food_name_normalized = 'swiss_cheese';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'heavy cream', 'heavy whipping cream', 'whipping cream',
  'double cream', 'heavy cream for coffee', 'thick cream',
  'whipped cream', '35% cream', 'cooking cream',
  'cream for coffee'
] WHERE food_name_normalized = 'heavy_whipping_cream';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'half and half', 'half & half', 'coffee cream', 'light cream',
  'half n half', 'table cream', 'creamer', 'half and half cream',
  'coffee creamer dairy'
] WHERE food_name_normalized = 'half_and_half';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'oat milk', 'oatly', 'oatly oat milk', 'oatly original',
  'oat milk original', 'oat milk unsweetened', 'barista oat milk',
  'oat beverage', 'plant milk oat', 'oat milk plain'
] WHERE food_name_normalized = 'oatly_oat_milk';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'almond milk', 'unsweetened almond milk', 'almond milk unsweetened',
  'almond breeze unsweetened', 'almond beverage', 'vanilla almond milk',
  'plain almond milk', 'plant milk almond', 'badam milk',
  'almond milk original'
] WHERE food_name_normalized = 'almond_milk_unsweetened';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'soy milk', 'soymilk', 'silk soy milk', 'unsweetened soy milk',
  'soya milk', 'soy beverage', 'vanilla soy milk',
  'plain soy milk', 'plant milk soy', 'soy milk original'
] WHERE food_name_normalized = 'soy_milk';

-- ==========================================
-- H. NUT BUTTERS (~8 items)
-- ==========================================

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'jif peanut butter', 'jif creamy', 'jif pb',
  'jif creamy peanut butter', 'jif natural peanut butter',
  'peanut butter jif', 'jif peanut butter creamy'
] WHERE food_name_normalized = 'jif_creamy_peanut_butter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'skippy peanut butter', 'skippy creamy', 'skippy pb',
  'skippy creamy peanut butter', 'skippy natural peanut butter',
  'peanut butter skippy', 'skippy peanut butter creamy'
] WHERE food_name_normalized = 'skippy_creamy_peanut_butter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'almond butter', 'almond nut butter', 'plain almond butter',
  'natural almond butter', 'creamy almond butter',
  'crunchy almond butter', 'roasted almond butter',
  'raw almond butter', 'organic almond butter', 'badam butter'
] WHERE food_name_normalized = 'almond_butter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'cashew butter', 'cashew nut butter', 'natural cashew butter',
  'creamy cashew butter', 'raw cashew butter',
  'roasted cashew butter', 'organic cashew butter', 'kaju butter'
] WHERE food_name_normalized = 'cashew_butter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'justin''s almond butter', 'justins almond butter',
  'justin''s classic almond butter', 'justins classic almond butter',
  'justin almond butter', 'justins ab'
] WHERE food_name_normalized = 'justins_almond_butter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'sunbutter', 'sunflower butter', 'sunflower seed butter',
  'sun butter', 'nut free butter', 'sunflower spread',
  'soy free butter', 'allergen free butter',
  'sunbutter natural', 'sunbutter creamy'
] WHERE food_name_normalized = 'sunbutter';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'tahini', 'sesame paste', 'tahini paste', 'sesame butter',
  'sesame seed paste', 'tahina', 'raw tahini', 'roasted tahini',
  'organic tahini', 'hulled tahini'
] WHERE food_name_normalized = 'tahini';

UPDATE food_nutrition_overrides SET variant_names = ARRAY[
  'nutella', 'nutella spread', 'hazelnut spread',
  'chocolate hazelnut spread', 'nutella hazelnut',
  'chocolate spread', 'nutella chocolate', 'ferrero nutella',
  'hazelnut chocolate spread', 'nutella jar'
] WHERE food_name_normalized = 'nutella';


-- ==========================================================================
-- PART 2: NEW ROWS FOR COOKING METHOD VARIANTS WITH DIFFERENT MACROS
-- ==========================================================================
-- These are separate entries because the cooking method meaningfully changes
-- the macronutrient profile (e.g., frying adds oil calories).
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ==========================================
-- SALMON VARIANTS
-- ==========================================

-- Salmon (Baked): per 100g USDA: 206 cal, 22.1P, 0C, 12.4F. Similar to grilled, no added oil.
('salmon_baked', 'Salmon (Baked)', 206, 22.1, 0.0, 12.4,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['baked salmon', 'oven baked salmon', 'roasted salmon fillet', 'salmon baked in oven'],
 'proteins', NULL, 1, '206 cal/100g baked. Per fillet (154g): 317 cal. Baked without added oil, similar to grilled.', TRUE),

-- Salmon (Fried): per 100g: 261 cal, 22P, 3C, 17F. Frying in oil adds ~50 cal.
('salmon_fried', 'Salmon (Fried)', 261, 22.0, 3.0, 17.0,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['fried salmon', 'pan fried salmon', 'breaded salmon', 'salmon fried in oil', 'crispy salmon'],
 'proteins', NULL, 1, '261 cal/100g fried. Per fillet (154g): 402 cal. Frying adds ~50 cal/100g from oil absorption.', TRUE),

-- Salmon (Smoked): per 100g USDA: 117 cal, 18.3P, 0C, 4.3F. Lower moisture, concentrated.
('salmon_smoked', 'Salmon (Smoked)', 117, 18.3, 0.0, 4.3,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['smoked salmon', 'lox', 'nova salmon', 'cold smoked salmon', 'hot smoked salmon', 'salmon lox', 'nova lox'],
 'proteins', NULL, 1, '117 cal/100g. Per 3 oz (85g): 99 cal. Lower fat than cooked due to smoking process. High in sodium.', TRUE),

-- Salmon (Dried/Jerky): per 100g: 307 cal, 58P, 0C, 7F. Very concentrated protein.
('salmon_dried', 'Salmon (Dried/Jerky)', 307, 58.0, 0.0, 7.0,
 0.0, 0.0, 28, NULL,
 'usda', ARRAY['salmon jerky', 'dried salmon', 'salmon strips dried', 'dehydrated salmon'],
 'proteins', NULL, 1, '307 cal/100g. Per 1 oz (28g): 86 cal. Concentrated protein source. Shelf-stable snack.', TRUE),

-- Salmon (Raw/Sashimi): per 100g USDA: 127 cal, 20.5P, 0C, 4.4F.
('salmon_raw_sashimi', 'Salmon (Raw/Sashimi)', 127, 20.5, 0.0, 4.4,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['raw salmon', 'salmon sashimi', 'sashimi salmon', 'salmon sushi grade', 'salmon nigiri', 'salmon tartare'],
 'proteins', NULL, 1, '127 cal/100g raw. Per 3 oz (85g): 108 cal. Sushi-grade raw salmon. Lower cal than cooked due to retained moisture.', TRUE),

-- ==========================================
-- CHICKEN BREAST VARIANTS
-- ==========================================

-- Chicken Breast (Baked): per 100g USDA: 165 cal, 31P, 0C, 3.6F. Same as grilled, dry heat no oil.
('chicken_breast_baked', 'Chicken Breast (Baked)', 165, 31.0, 0.0, 3.6,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['baked chicken breast', 'oven baked chicken', 'roasted chicken breast boneless', 'chicken breast baked'],
 'proteins', NULL, 1, '165 cal/100g baked. 1 breast (120g): 198 cal. Dry-heat cooking, same macros as grilled.', TRUE),

-- Chicken Breast (Fried): per 100g: 223 cal, 28P, 4C, 10F. Breaded and fried.
('chicken_breast_fried', 'Chicken Breast (Fried)', 223, 28.0, 4.0, 10.0,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['fried chicken breast', 'breaded chicken breast', 'crispy chicken breast', 'chicken breast fried', 'pan fried chicken breast', 'chicken cutlet fried'],
 'proteins', NULL, 1, '223 cal/100g fried. 1 breast (120g): 268 cal. Breading + oil adds ~60 cal/100g vs grilled.', TRUE),

-- Chicken Breast (Boiled): per 100g USDA: 151 cal, 30P, 0C, 2.8F. Leaner than grilled.
('chicken_breast_boiled', 'Chicken Breast (Boiled)', 151, 30.0, 0.0, 2.8,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['boiled chicken', 'boiled chicken breast', 'chicken breast boiled', 'steamed chicken breast', 'poached chicken breast'],
 'proteins', NULL, 1, '151 cal/100g boiled. 1 breast (120g): 181 cal. Slightly leaner than grilled as fat renders into water.', TRUE),

-- Chicken Breast (Poached): per 100g USDA: 151 cal, 30P, 0C, 2.8F. Same as boiled.
('chicken_breast_poached', 'Chicken Breast (Poached)', 151, 30.0, 0.0, 2.8,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['poached chicken', 'poached chicken breast', 'chicken breast poached', 'gently poached chicken'],
 'proteins', NULL, 1, '151 cal/100g poached. 1 breast (120g): 181 cal. Gentle moist-heat cooking, same as boiled.', TRUE),

-- ==========================================
-- CHICKEN THIGH VARIANTS
-- ==========================================

-- Chicken Thigh (Fried): per 100g: 262 cal, 24P, 5C, 16F.
('chicken_thigh_fried', 'Chicken Thigh (Fried)', 262, 24.0, 5.0, 16.0,
 0.0, 0.0, 85, 85,
 'usda', ARRAY['fried chicken thigh', 'breaded chicken thigh', 'crispy chicken thigh', 'chicken thigh fried', 'pan fried chicken thigh'],
 'proteins', NULL, 1, '262 cal/100g fried. 1 thigh (85g): 223 cal. Breading + oil adds ~53 cal/100g vs baked.', TRUE),

-- Chicken Thigh (Baked): per 100g USDA: 209 cal, 26P, 0C, 11F. Same as base cooked entry.
('chicken_thigh_baked', 'Chicken Thigh (Baked)', 209, 26.0, 0.0, 11.0,
 0.0, 0.0, 85, 85,
 'usda', ARRAY['baked chicken thigh', 'oven baked chicken thigh', 'roasted chicken thigh boneless', 'chicken thigh baked'],
 'proteins', NULL, 1, '209 cal/100g baked. 1 thigh (85g): 178 cal. Dry-heat cooking without added oil.', TRUE),

-- ==========================================
-- EGG VARIANTS
-- ==========================================

-- Egg (Boiled): per 100g USDA: 155 cal, 12.6P, 1.1C, 10.6F. Same macros as whole egg.
('egg_boiled', 'Egg (Boiled)', 155, 12.6, 1.1, 10.6,
 0.0, 1.1, 50, 50,
 'usda', ARRAY['boiled egg', 'hard boiled egg', 'soft boiled egg', 'hard cooked egg', 'eggs boiled', '1 boiled egg'],
 'proteins', NULL, 1, '155 cal/100g. 1 large boiled egg (50g): 78 cal. No added fat, same macros as raw egg.', TRUE),

-- Egg (Fried): per 100g USDA: 196 cal, 13.6P, 0.8C, 15.3F. Fried in oil/butter.
('egg_fried', 'Egg (Fried)', 196, 13.6, 0.8, 15.3,
 0.0, 0.8, 46, 46,
 'usda', ARRAY['fried egg', 'eggs fried', 'sunny side up', 'over easy egg', 'over medium egg', 'over hard egg', '1 fried egg', 'sunny side up egg'],
 'proteins', NULL, 1, '196 cal/100g. 1 large fried egg (46g): 90 cal. Oil/butter adds ~5g fat per egg vs boiled.', TRUE),

-- Egg (Scrambled): per 100g USDA: 149 cal, 10.3P, 1.6C, 11.2F. With milk/butter.
('egg_scrambled', 'Egg (Scrambled)', 149, 10.3, 1.6, 11.2,
 0.0, 1.6, 61, NULL,
 'usda', ARRAY['scrambled egg', 'scrambled eggs', 'eggs scrambled', 'fluffy scrambled eggs', 'soft scrambled eggs'],
 'proteins', NULL, 1, '149 cal/100g. 1 large egg scrambled (61g): 91 cal. Milk dilutes protein density. Butter adds fat.', TRUE),

-- Egg (Poached): per 100g USDA: 143 cal, 12.5P, 0.7C, 9.9F.
('egg_poached', 'Egg (Poached)', 143, 12.5, 0.7, 9.9,
 0.0, 0.7, 50, 50,
 'usda', ARRAY['poached egg', 'eggs poached', '1 poached egg', 'poached eggs', 'eggs benedict egg'],
 'proteins', NULL, 1, '143 cal/100g. 1 large poached egg (50g): 72 cal. No added fat, slightly lower cal than boiled due to water absorption.', TRUE),

-- Egg (Omelette): per 100g USDA: 154 cal, 10.6P, 0.6C, 12.2F. Plain with butter.
('egg_omelette', 'Egg (Omelette)', 154, 10.6, 0.6, 12.2,
 0.0, 0.6, 61, NULL,
 'usda', ARRAY['omelette', 'egg omelette', 'plain omelette', 'french omelette', 'omelet', 'egg omelet', 'omelette plain'],
 'proteins', NULL, 1, '154 cal/100g. 1 large egg omelette (61g): 94 cal. Plain with butter, no fillings.', TRUE),

-- ==========================================
-- SHRIMP VARIANTS
-- ==========================================

-- Shrimp (Fried): per 100g: 242 cal, 18P, 11C, 13F. Breaded/battered.
('shrimp_fried', 'Shrimp (Fried)', 242, 18.0, 11.0, 13.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['fried shrimp', 'breaded shrimp', 'battered shrimp', 'popcorn shrimp', 'tempura shrimp', 'crispy shrimp', 'coconut shrimp'],
 'proteins', NULL, 1, '242 cal/100g fried. Per 3 oz (85g): 206 cal. Breading + oil more than doubles the calories vs plain.', TRUE),

-- Shrimp (Boiled): per 100g USDA: 99 cal, 24P, 0.2C, 0.3F. Very lean.
('shrimp_boiled', 'Shrimp (Boiled)', 99, 24.0, 0.2, 0.3,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['boiled shrimp', 'shrimp boiled', 'steamed shrimp boiled', 'shrimp cocktail boiled', 'plain boiled shrimp'],
 'proteins', NULL, 1, '99 cal/100g boiled. Per 3 oz (85g): 84 cal. Leanest shrimp preparation. No added fat.', TRUE),

-- Shrimp (Grilled): per 100g: 119 cal, 24P, 0C, 1.7F.
('shrimp_grilled', 'Shrimp (Grilled)', 119, 24.0, 0.0, 1.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['grilled shrimp', 'shrimp grilled', 'bbq shrimp', 'chargrilled shrimp', 'shrimp skewers grilled'],
 'proteins', NULL, 1, '119 cal/100g grilled. Per 3 oz (85g): 101 cal. Light oil brushing adds minimal fat vs boiled.', TRUE),

-- ==========================================
-- POTATO VARIANTS
-- ==========================================

-- Potato (Boiled): per 100g USDA: 87 cal, 1.9P, 20C, 0.1F.
('potato_boiled', 'Potato (Boiled)', 87, 1.9, 20.0, 0.1,
 1.8, 0.9, 150, NULL,
 'usda', ARRAY['boiled potato', 'boiled potatoes', 'potato boiled', 'plain boiled potato', 'steamed potato'],
 'vegetables', NULL, 1, '87 cal/100g boiled. 1 medium (150g): 131 cal. No added fat. Lowest calorie potato prep.', TRUE),

-- Potato (Mashed): per 100g USDA: 113 cal, 2P, 16C, 4.5F. With butter/milk.
('potato_mashed', 'Potato (Mashed)', 113, 2.0, 16.0, 4.5,
 1.5, 1.5, 210, NULL,
 'usda', ARRAY['mashed potato', 'mashed potatoes', 'potato mash', 'creamy mashed potatoes', 'buttery mashed potatoes', 'whipped potatoes'],
 'vegetables', NULL, 1, '113 cal/100g. 1 cup (210g): 237 cal. Butter and milk add fat. Calories vary with recipe.', TRUE),

-- Potato (Fried/French Fries): per 100g USDA: 312 cal, 3.4P, 41C, 15F.
('potato_fried', 'French Fries', 312, 3.4, 41.0, 15.0,
 3.8, 0.3, 117, NULL,
 'usda', ARRAY['french fries', 'fries', 'fried potato', 'fried potatoes', 'chips', 'potato fries', 'deep fried potato', 'steak fries', 'shoestring fries', 'curly fries', 'waffle fries'],
 'vegetables', NULL, 1, '312 cal/100g. 1 medium serving (117g): 365 cal. Deep frying triples calories vs boiled.', TRUE),

-- Potato (Roasted): per 100g USDA: 149 cal, 2.9P, 23C, 5.4F. With oil.
('potato_roasted', 'Potato (Roasted)', 149, 2.9, 23.0, 5.4,
 2.0, 1.0, 150, NULL,
 'usda', ARRAY['roasted potato', 'roasted potatoes', 'oven roasted potato', 'roast potato', 'crispy roasted potatoes', 'potato wedges roasted'],
 'vegetables', NULL, 1, '149 cal/100g. 1 medium (150g): 224 cal. Oil coating adds moderate fat vs baked.', TRUE),

-- ==========================================
-- SWEET POTATO VARIANTS
-- ==========================================

-- Sweet Potato (Boiled): per 100g USDA: 76 cal, 1.4P, 17.7C, 0.1F.
('sweet_potato_boiled', 'Sweet Potato (Boiled)', 76, 1.4, 17.7, 0.1,
 2.5, 5.7, 114, NULL,
 'usda', ARRAY['boiled sweet potato', 'sweet potato boiled', 'steamed sweet potato boiled', 'plain sweet potato boiled'],
 'vegetables', NULL, 1, '76 cal/100g boiled. 1 medium (114g): 87 cal. Lowest calorie sweet potato prep.', TRUE),

-- Sweet Potato (Baked): per 100g USDA: 90 cal, 2P, 20.7C, 0.2F. Same as base entry.
('sweet_potato_baked', 'Sweet Potato (Baked)', 90, 2.0, 20.7, 0.2,
 3.3, 6.5, 114, 114,
 'usda', ARRAY['baked sweet potato', 'sweet potato baked', 'oven baked sweet potato', 'roasted sweet potato baked'],
 'vegetables', NULL, 1, '90 cal/100g baked. 1 medium (114g): 103 cal. Natural caramelization increases sweetness.', TRUE),

-- Sweet Potato (Mashed): per 100g: 101 cal, 1.7P, 21C, 2.3F. With butter.
('sweet_potato_mashed', 'Sweet Potato (Mashed)', 101, 1.7, 21.0, 2.3,
 2.8, 7.0, 200, NULL,
 'usda', ARRAY['mashed sweet potato', 'sweet potato mash', 'sweet potato puree', 'whipped sweet potato', 'creamy sweet potato'],
 'vegetables', NULL, 1, '101 cal/100g. 1 cup (200g): 202 cal. Butter adds moderate fat. Smooth creamy texture.', TRUE),

-- Sweet Potato (Fried/Fries): per 100g: 260 cal, 2P, 34C, 13F.
('sweet_potato_fried', 'Sweet Potato Fries', 260, 2.0, 34.0, 13.0,
 3.0, 5.0, 117, NULL,
 'usda', ARRAY['sweet potato fries', 'fried sweet potato', 'sweet potato chips', 'sweet potato wedges fried', 'crispy sweet potato fries'],
 'vegetables', NULL, 1, '260 cal/100g fried. 1 serving (117g): 304 cal. Deep frying nearly triples calories vs boiled.', TRUE),

-- ==========================================
-- TOFU VARIANTS
-- ==========================================

-- Tofu (Fried): per 100g USDA: 271 cal, 17.3P, 10.5C, 20.2F.
('tofu_fried', 'Tofu (Fried)', 271, 17.3, 10.5, 20.2,
 0.5, 0.5, 126, NULL,
 'usda', ARRAY['fried tofu', 'deep fried tofu', 'crispy tofu fried', 'tofu fried in oil', 'agedashi tofu', 'tofu puffs'],
 'proteins', NULL, 1, '271 cal/100g fried. Per 0.5 cup (126g): 341 cal. Frying triples calories vs plain firm tofu.', TRUE),

-- Tofu (Steamed/Silken): per 100g USDA: 62 cal, 7P, 2C, 3.5F.
('tofu_steamed', 'Tofu (Steamed/Silken)', 62, 7.0, 2.0, 3.5,
 0.0, 0.0, 126, NULL,
 'usda', ARRAY['steamed tofu', 'silken tofu', 'soft tofu', 'japanese silken tofu', 'tofu steamed', 'smooth tofu'],
 'proteins', NULL, 1, '62 cal/100g. Per 0.5 cup (126g): 78 cal. Softer, higher water content than firm tofu.', TRUE),

-- ==========================================
-- RICE VARIANTS
-- ==========================================

-- Fried Rice (egg fried rice style): per 100g USDA: 174 cal, 3.4P, 24C, 7.2F.
('white_rice_fried', 'Fried Rice', 174, 3.4, 24.0, 7.2,
 0.8, 0.3, 200, NULL,
 'usda', ARRAY['fried rice', 'egg fried rice', 'chinese fried rice', 'vegetable fried rice', 'rice fried', 'stir fried rice', 'yang chow fried rice'],
 'grains_pasta', NULL, 1, '174 cal/100g. 1 cup (200g): 348 cal. Oil and egg add ~44 cal/100g vs plain steamed rice.', TRUE)

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
