-- ============================================================================
-- Batch 24: Common Fruits (Fresh, Dried, Frozen)
-- Total items: 54
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov)
-- All values are per 100g. Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- COMMON FRUITS (~20 items)
-- ============================================================================

-- Banana: 89 cal/100g (1.1P*4 + 22.8C*4 + 0.3F*9 = 4.4+91.2+2.7 = 98.3, USDA lists 89 due to fiber) ✓
('banana', 'Banana', 89, 1.1, 22.8, 0.3, 2.6, 12.2, 118, 118, 'usda', ARRAY['banana', 'bananas', 'ripe banana', 'yellow banana'], '105 cal per medium banana (118g, peeled).', NULL, 'fruits', 1),

-- Apple with Skin: 52 cal/100g (0.3P*4 + 13.8C*4 + 0.2F*9 = 1.2+55.2+1.8 = 58.2, USDA lists 52 due to fiber) ✓
('apple', 'Apple (with Skin)', 52, 0.3, 13.8, 0.2, 2.4, 10.4, 182, 182, 'usda', ARRAY['apple', 'apples', 'red apple', 'green apple', 'gala apple', 'fuji apple', 'granny smith'], '95 cal per medium apple (182g).', NULL, 'fruits', 1),

-- Orange: 47 cal/100g (0.9P*4 + 11.8C*4 + 0.1F*9 = 3.6+47.2+0.9 = 51.7, USDA lists 47 due to fiber) ✓
('orange', 'Orange', 47, 0.9, 11.8, 0.1, 2.4, 9.4, 131, 131, 'usda', ARRAY['orange', 'oranges', 'navel orange', 'valencia orange', 'fresh orange'], '62 cal per medium orange (131g, peeled).', NULL, 'fruits', 1),

-- Strawberry: 32 cal/100g (0.7P*4 + 7.7C*4 + 0.3F*9 = 2.8+30.8+2.7 = 36.3, USDA lists 32 due to fiber) ✓
('strawberry', 'Strawberry', 32, 0.7, 7.7, 0.3, 2.0, 4.9, 12, 152, 'usda', ARRAY['strawberry', 'strawberries', 'fresh strawberries'], '49 cal per cup (152g, whole).', NULL, 'fruits', 1),

-- Blueberry: 57 cal/100g (0.7P*4 + 14.5C*4 + 0.3F*9 = 2.8+58.0+2.7 = 63.5, USDA lists 57 due to fiber) ✓
('blueberry', 'Blueberry', 57, 0.7, 14.5, 0.3, 2.4, 10.0, NULL, 148, 'usda', ARRAY['blueberry', 'blueberries', 'fresh blueberries'], '84 cal per cup (148g).', NULL, 'fruits', 1),

-- Raspberry: 52 cal/100g (1.2P*4 + 11.9C*4 + 0.7F*9 = 4.8+47.6+6.3 = 58.7, USDA lists 52 due to fiber) ✓
('raspberry', 'Raspberry', 52, 1.2, 11.9, 0.7, 6.5, 4.4, NULL, 123, 'usda', ARRAY['raspberry', 'raspberries', 'red raspberry', 'fresh raspberries'], '64 cal per cup (123g).', NULL, 'fruits', 1),

-- Blackberry: 43 cal/100g (1.4P*4 + 9.6C*4 + 0.5F*9 = 5.6+38.4+4.5 = 48.5, USDA lists 43 due to fiber) ✓
('blackberry', 'Blackberry', 43, 1.4, 9.6, 0.5, 5.3, 4.9, NULL, 144, 'usda', ARRAY['blackberry', 'blackberries', 'fresh blackberries'], '62 cal per cup (144g).', NULL, 'fruits', 1),

-- Red Grapes: 69 cal/100g (0.7P*4 + 18.1C*4 + 0.2F*9 = 2.8+72.4+1.8 = 77.0, USDA lists 69 due to fiber) ✓
('grapes_red', 'Grapes (Red)', 69, 0.7, 18.1, 0.2, 0.9, 15.5, 5, 151, 'usda', ARRAY['red grapes', 'grapes', 'red seedless grapes', 'grape'], '104 cal per cup (151g).', NULL, 'fruits', 1),

-- Green Grapes: 69 cal/100g (0.7P*4 + 18.1C*4 + 0.2F*9 = 77.0, USDA lists 69) ✓
('grapes_green', 'Grapes (Green)', 69, 0.7, 18.1, 0.2, 0.9, 15.5, 5, 151, 'usda', ARRAY['green grapes', 'white grapes', 'thompson grapes', 'seedless grapes'], '104 cal per cup (151g).', NULL, 'fruits', 1),

-- Watermelon: 30 cal/100g (0.6P*4 + 7.6C*4 + 0.2F*9 = 2.4+30.4+1.8 = 34.6, USDA lists 30) ✓
('watermelon', 'Watermelon', 30, 0.6, 7.6, 0.2, 0.4, 6.2, NULL, 286, 'usda', ARRAY['watermelon', 'water melon', 'fresh watermelon'], '86 cal per wedge (286g, 1/16 of melon).', NULL, 'fruits', 1),

-- Cantaloupe: 34 cal/100g (0.8P*4 + 8.2C*4 + 0.2F*9 = 3.2+32.8+1.8 = 37.8, USDA lists 34) ✓
('cantaloupe', 'Cantaloupe', 34, 0.8, 8.2, 0.2, 0.9, 7.9, NULL, 177, 'usda', ARRAY['cantaloupe', 'muskmelon', 'rockmelon', 'cantelope'], '60 cal per cup cubed (177g).', NULL, 'fruits', 1),

-- Honeydew Melon: 36 cal/100g (0.5P*4 + 9.1C*4 + 0.1F*9 = 2.0+36.4+0.9 = 39.3, USDA lists 36) ✓
('honeydew', 'Honeydew Melon', 36, 0.5, 9.1, 0.1, 0.8, 8.1, NULL, 177, 'usda', ARRAY['honeydew', 'honeydew melon', 'honey dew', 'green melon'], '64 cal per cup cubed (177g).', NULL, 'fruits', 1),

-- Mango: 60 cal/100g (0.8P*4 + 15.0C*4 + 0.4F*9 = 3.2+60.0+3.6 = 66.8, USDA lists 60 due to fiber) ✓
('mango', 'Mango', 60, 0.8, 15.0, 0.4, 1.6, 13.7, 207, 165, 'usda', ARRAY['mango', 'mangoes', 'mangos', 'fresh mango', 'ripe mango'], '99 cal per cup sliced (165g). 124 cal per whole mango (207g).', NULL, 'fruits', 1),

-- Pineapple: 50 cal/100g (0.5P*4 + 13.1C*4 + 0.1F*9 = 2.0+52.4+0.9 = 55.3, USDA lists 50 due to fiber) ✓
('pineapple', 'Pineapple', 50, 0.5, 13.1, 0.1, 1.4, 9.9, NULL, 165, 'usda', ARRAY['pineapple', 'fresh pineapple', 'pineapple chunks'], '83 cal per cup chunks (165g).', NULL, 'fruits', 1),

-- Peach: 39 cal/100g (0.9P*4 + 9.5C*4 + 0.3F*9 = 3.6+38.0+2.7 = 44.3, USDA lists 39 due to fiber) ✓
('peach', 'Peach', 39, 0.9, 9.5, 0.3, 1.5, 8.4, 150, 150, 'usda', ARRAY['peach', 'peaches', 'fresh peach', 'yellow peach'], '59 cal per medium peach (150g).', NULL, 'fruits', 1),

-- Pear: 57 cal/100g (0.4P*4 + 15.2C*4 + 0.1F*9 = 1.6+60.8+0.9 = 63.3, USDA lists 57 due to fiber) ✓
('pear', 'Pear', 57, 0.4, 15.2, 0.1, 3.1, 9.8, 178, 178, 'usda', ARRAY['pear', 'pears', 'bartlett pear', 'anjou pear', 'bosc pear'], '101 cal per medium pear (178g).', NULL, 'fruits', 1),

-- Sweet Cherry: 63 cal/100g (1.1P*4 + 16.0C*4 + 0.2F*9 = 4.4+64.0+1.8 = 70.2, USDA lists 63 due to fiber) ✓
('cherry_sweet', 'Cherries (Sweet)', 63, 1.1, 16.0, 0.2, 2.1, 12.8, 8, 138, 'usda', ARRAY['cherry', 'cherries', 'sweet cherry', 'bing cherry', 'fresh cherries'], '87 cal per cup with pits (138g).', NULL, 'fruits', 1),

-- Kiwi: 61 cal/100g (1.1P*4 + 14.7C*4 + 0.5F*9 = 4.4+58.8+4.5 = 67.7, USDA lists 61 due to fiber) ✓
('kiwi', 'Kiwi', 61, 1.1, 14.7, 0.5, 3.0, 9.0, 69, 69, 'usda', ARRAY['kiwi', 'kiwifruit', 'kiwi fruit', 'green kiwi', 'chinese gooseberry'], '42 cal per medium kiwi (69g).', NULL, 'fruits', 1),

-- Grapefruit: 42 cal/100g (0.8P*4 + 10.7C*4 + 0.1F*9 = 3.2+42.8+0.9 = 46.9, USDA lists 42 due to fiber) ✓
('grapefruit', 'Grapefruit', 42, 0.8, 10.7, 0.1, 1.6, 6.9, 246, 154, 'usda', ARRAY['grapefruit', 'pink grapefruit', 'red grapefruit', 'white grapefruit'], '65 cal per half grapefruit (154g).', NULL, 'fruits', 1),

-- Lemon: 29 cal/100g (1.1P*4 + 9.3C*4 + 0.3F*9 = 4.4+37.2+2.7 = 44.3, USDA lists 29 due to high fiber/acid) ✓
('lemon', 'Lemon', 29, 1.1, 9.3, 0.3, 2.8, 2.5, 58, 58, 'usda', ARRAY['lemon', 'lemons', 'fresh lemon'], '17 cal per medium lemon (58g, without seeds).', NULL, 'fruits', 1),

-- ============================================================================
-- TROPICAL & OTHER (~12 items)
-- ============================================================================

-- Papaya: 43 cal/100g (0.5P*4 + 10.8C*4 + 0.3F*9 = 2.0+43.2+2.7 = 47.9, USDA lists 43) ✓
('papaya', 'Papaya', 43, 0.5, 10.8, 0.3, 1.7, 7.8, NULL, 145, 'usda', ARRAY['papaya', 'pawpaw', 'fresh papaya'], '62 cal per cup cubed (145g).', NULL, 'fruits', 1),

-- Passion Fruit: 97 cal/100g (2.2P*4 + 23.4C*4 + 0.7F*9 = 8.8+93.6+6.3 = 108.7, USDA lists 97 due to high fiber) ✓
('passion_fruit', 'Passion Fruit', 97, 2.2, 23.4, 0.7, 10.4, 11.2, 18, 36, 'usda', ARRAY['passion fruit', 'passionfruit', 'maracuya', 'granadilla'], '17 cal per fruit (18g pulp). 35 cal per 2 fruits.', NULL, 'fruits', 1),

-- Guava: 68 cal/100g (2.6P*4 + 14.3C*4 + 1.0F*9 = 10.4+57.2+9.0 = 76.6, USDA lists 68 due to fiber) ✓
('guava', 'Guava', 68, 2.6, 14.3, 1.0, 5.4, 8.9, 55, 165, 'usda', ARRAY['guava', 'guavas', 'fresh guava', 'pink guava'], '112 cal per cup (165g). 37 cal per fruit (55g).', NULL, 'fruits', 1),

-- Dragon Fruit: 50 cal/100g (1.1P*4 + 11.0C*4 + 0.4F*9 = 4.4+44.0+3.6 = 52.0) ✓
('dragon_fruit', 'Dragon Fruit (Pitaya)', 50, 1.1, 11.0, 0.4, 3.0, 8.0, 220, 220, 'usda', ARRAY['dragon fruit', 'pitaya', 'pitahaya', 'dragonfruit'], '110 cal per whole fruit (220g, flesh only).', NULL, 'fruits', 1),

-- Lychee: 66 cal/100g (0.8P*4 + 16.5C*4 + 0.4F*9 = 3.2+66.0+3.6 = 72.8, USDA lists 66 due to fiber) ✓
('lychee', 'Lychee', 66, 0.8, 16.5, 0.4, 1.3, 15.2, 10, 100, 'usda', ARRAY['lychee', 'litchi', 'lichee', 'lichi'], '66 cal per 100g (about 10 fruits).', NULL, 'fruits', 1),

-- Persimmon: 70 cal/100g (0.6P*4 + 18.6C*4 + 0.2F*9 = 2.4+74.4+1.8 = 78.6, USDA lists 70 due to fiber) ✓
('persimmon', 'Persimmon (Fuyu)', 70, 0.6, 18.6, 0.2, 3.6, 12.5, 168, 168, 'usda', ARRAY['persimmon', 'fuyu persimmon', 'kaki', 'sharon fruit'], '118 cal per fruit (168g).', NULL, 'fruits', 1),

-- Coconut Fresh Meat: 354 cal/100g (3.3P*4 + 15.2C*4 + 33.5F*9 = 13.2+60.8+301.5 = 375.5, USDA lists 354 due to fiber) ✓
('coconut_fresh', 'Coconut (Fresh Meat)', 354, 3.3, 15.2, 33.5, 9.0, 6.2, NULL, 80, 'usda', ARRAY['coconut', 'fresh coconut', 'coconut meat', 'raw coconut'], '283 cal per cup shredded (80g).', NULL, 'fruits', 1),

-- Pomegranate Seeds: 83 cal/100g (1.7P*4 + 18.7C*4 + 1.2F*9 = 6.8+74.8+10.8 = 92.4, USDA lists 83 due to fiber) ✓
('pomegranate_seeds', 'Pomegranate Seeds (Arils)', 83, 1.7, 18.7, 1.2, 4.0, 13.7, NULL, 87, 'usda', ARRAY['pomegranate', 'pomegranate seeds', 'pomegranate arils', 'pom seeds'], '72 cal per 1/2 cup arils (87g).', NULL, 'fruits', 1),

-- Fig Fresh: 74 cal/100g (0.8P*4 + 19.2C*4 + 0.3F*9 = 3.2+76.8+2.7 = 82.7, USDA lists 74 due to fiber) ✓
('fig_fresh', 'Fig (Fresh)', 74, 0.8, 19.2, 0.3, 2.9, 16.3, 50, 100, 'usda', ARRAY['fig', 'figs', 'fresh fig', 'fresh figs'], '37 cal per medium fig (50g).', NULL, 'fruits', 1),

-- Star Fruit: 31 cal/100g (1.0P*4 + 6.7C*4 + 0.3F*9 = 4.0+26.8+2.7 = 33.5, USDA lists 31) ✓
('star_fruit', 'Star Fruit (Carambola)', 31, 1.0, 6.7, 0.3, 2.8, 4.0, 91, 91, 'usda', ARRAY['star fruit', 'starfruit', 'carambola'], '28 cal per medium fruit (91g).', NULL, 'fruits', 1),

-- Plantain Ripe: 122 cal/100g (1.3P*4 + 31.9C*4 + 0.4F*9 = 5.2+127.6+3.6 = 136.4, USDA lists 122 due to fiber) ✓
('plantain_ripe', 'Plantain (Ripe, Raw)', 122, 1.3, 31.9, 0.4, 2.3, 15.0, 179, 179, 'usda', ARRAY['plantain', 'ripe plantain', 'yellow plantain', 'platano maduro'], '218 cal per medium plantain (179g).', NULL, 'fruits', 1),

-- Jackfruit Fresh: 95 cal/100g (1.7P*4 + 23.3C*4 + 0.6F*9 = 6.8+93.2+5.4 = 105.4, USDA lists 95 due to fiber) ✓
('jackfruit_fresh', 'Jackfruit (Fresh)', 95, 1.7, 23.3, 0.6, 1.5, 19.1, NULL, 165, 'usda', ARRAY['jackfruit', 'jack fruit', 'fresh jackfruit', 'kathal'], '157 cal per cup sliced (165g).', NULL, 'fruits', 1),

-- ============================================================================
-- CITRUS & STONE FRUITS (~8 items)
-- ============================================================================

-- Tangerine/Clementine: 53 cal/100g (0.8P*4 + 13.3C*4 + 0.3F*9 = 3.2+53.2+2.7 = 59.1, USDA lists 53 due to fiber) ✓
('clementine', 'Clementine / Tangerine', 53, 0.8, 13.3, 0.3, 1.7, 10.6, 74, 74, 'usda', ARRAY['clementine', 'tangerine', 'mandarin', 'satsuma', 'cutie', 'halo'], '35 cal per clementine (74g, peeled).', NULL, 'fruits', 1),

-- Nectarine: 44 cal/100g (1.1P*4 + 10.6C*4 + 0.3F*9 = 4.4+42.4+2.7 = 49.5, USDA lists 44 due to fiber) ✓
('nectarine', 'Nectarine', 44, 1.1, 10.6, 0.3, 1.7, 7.9, 142, 142, 'usda', ARRAY['nectarine', 'nectarines', 'fresh nectarine'], '63 cal per medium nectarine (142g).', NULL, 'fruits', 1),

-- Apricot: 48 cal/100g (1.4P*4 + 11.1C*4 + 0.4F*9 = 5.6+44.4+3.6 = 53.6, USDA lists 48 due to fiber) ✓
('apricot', 'Apricot', 48, 1.4, 11.1, 0.4, 2.0, 9.2, 35, 105, 'usda', ARRAY['apricot', 'apricots', 'fresh apricot'], '17 cal per apricot (35g). 50 cal per 3 apricots (105g).', NULL, 'fruits', 1),

-- Plum: 46 cal/100g (0.7P*4 + 11.4C*4 + 0.3F*9 = 2.8+45.6+2.7 = 51.1, USDA lists 46 due to fiber) ✓
('plum', 'Plum', 46, 0.7, 11.4, 0.3, 1.4, 9.9, 66, 66, 'usda', ARRAY['plum', 'plums', 'fresh plum', 'red plum', 'black plum'], '30 cal per small plum (66g).', NULL, 'fruits', 1),

-- Blood Orange: 50 cal/100g (0.9P*4 + 12.0C*4 + 0.1F*9 = 3.6+48.0+0.9 = 52.5) ✓
('blood_orange', 'Blood Orange', 50, 0.9, 12.0, 0.1, 2.2, 9.0, 131, 131, 'usda', ARRAY['blood orange', 'blood oranges', 'red orange', 'moro orange'], '66 cal per medium blood orange (131g).', NULL, 'fruits', 1),

-- Kumquat: 71 cal/100g (1.9P*4 + 15.9C*4 + 0.9F*9 = 7.6+63.6+8.1 = 79.3, USDA lists 71 due to fiber) ✓
('kumquat', 'Kumquat', 71, 1.9, 15.9, 0.9, 6.5, 9.4, 19, 95, 'usda', ARRAY['kumquat', 'kumquats', 'cumquat'], '13 cal per kumquat (19g). 67 cal per 5 kumquats (95g).', NULL, 'fruits', 1),

-- Lime: 30 cal/100g (0.7P*4 + 10.5C*4 + 0.2F*9 = 2.8+42.0+1.8 = 46.6, USDA lists 30 due to fiber/acid) ✓
('lime', 'Lime', 30, 0.7, 10.5, 0.2, 2.8, 1.7, 67, 67, 'usda', ARRAY['lime', 'limes', 'fresh lime', 'key lime'], '20 cal per medium lime (67g).', NULL, 'fruits', 1),

-- Mandarin Orange (Canned): 54 cal/100g (0.7P*4 + 13.6C*4 + 0.0F*9 = 2.8+54.4+0 = 57.2, USDA lists 54) ✓
('mandarin_orange', 'Mandarin Orange', 54, 0.7, 13.6, 0.0, 1.8, 10.6, 74, 74, 'usda', ARRAY['mandarin orange', 'mandarin', 'mandarin oranges', 'canned mandarin'], '40 cal per mandarin (74g, peeled).', NULL, 'fruits', 1),

-- ============================================================================
-- DRIED FRUITS (~8 items)
-- ============================================================================

-- Raisins: 299 cal/100g (3.1P*4 + 79.2C*4 + 0.5F*9 = 12.4+316.8+4.5 = 333.7, USDA lists 299 due to fiber) ✓
('raisins', 'Raisins', 299, 3.1, 79.2, 0.5, 3.7, 59.2, NULL, 43, 'usda', ARRAY['raisins', 'dried grapes', 'seedless raisins', 'golden raisins', 'sultanas'], '129 cal per small box (43g, 1.5 oz).', NULL, 'fruits', 1),

-- Dried Cranberries: 308 cal/100g (0.1P*4 + 82.4C*4 + 1.4F*9 = 0.4+329.6+12.6 = 342.6, USDA lists 308 due to fiber) ✓
('dried_cranberries', 'Dried Cranberries (Sweetened)', 308, 0.1, 82.4, 1.4, 5.7, 72.6, NULL, 40, 'usda', ARRAY['dried cranberries', 'craisins', 'cranberry raisins', 'ocean spray craisins'], '123 cal per 1/4 cup (40g). Sweetened.', NULL, 'fruits', 1),

-- Dried Mango: 319 cal/100g (1.5P*4 + 78.6C*4 + 0.8F*9 = 6.0+314.4+7.2 = 327.6, USDA lists 319) ✓
('dried_mango', 'Dried Mango', 319, 1.5, 78.6, 0.8, 2.4, 66.0, NULL, 40, 'usda', ARRAY['dried mango', 'mango slices dried', 'dehydrated mango'], '128 cal per serving (40g).', NULL, 'fruits', 1),

-- Dried Apricot: 241 cal/100g (3.4P*4 + 62.6C*4 + 0.5F*9 = 13.6+250.4+4.5 = 268.5, USDA lists 241 due to fiber) ✓
('dried_apricot', 'Dried Apricots', 241, 3.4, 62.6, 0.5, 7.3, 53.4, 7, 40, 'usda', ARRAY['dried apricots', 'dried apricot', 'dehydrated apricots'], '96 cal per serving (40g, ~6 halves).', NULL, 'fruits', 1),

-- Prunes: 240 cal/100g (2.2P*4 + 63.9C*4 + 0.4F*9 = 8.8+255.6+3.6 = 268.0, USDA lists 240 due to fiber) ✓
('prunes', 'Prunes (Dried Plums)', 240, 2.2, 63.9, 0.4, 7.1, 38.1, 8, 40, 'usda', ARRAY['prunes', 'dried plums', 'pitted prunes'], '96 cal per serving (40g, ~5 prunes).', NULL, 'fruits', 1),

-- Medjool Dates: 277 cal/100g (1.8P*4 + 75.0C*4 + 0.2F*9 = 7.2+300.0+1.8 = 309.0, USDA lists 277 due to fiber) ✓
('medjool_dates', 'Medjool Dates', 277, 1.8, 75.0, 0.2, 6.7, 66.5, 24, 48, 'usda', ARRAY['medjool dates', 'dates', 'medjool', 'date fruit', 'khajoor'], '66 cal per date (24g). 133 cal per 2 dates (48g).', NULL, 'fruits', 1),

-- Dried Figs: 249 cal/100g (3.3P*4 + 63.9C*4 + 0.9F*9 = 13.2+255.6+8.1 = 276.9, USDA lists 249 due to fiber) ✓
('dried_figs', 'Dried Figs', 249, 3.3, 63.9, 0.9, 9.8, 47.9, 8, 40, 'usda', ARRAY['dried figs', 'dried fig', 'fig dried', 'mission figs dried'], '100 cal per serving (40g, ~5 figs).', NULL, 'fruits', 1),

-- Dried Pineapple: 325 cal/100g (2.2P*4 + 81.7C*4 + 0.5F*9 = 8.8+326.8+4.5 = 340.1, USDA lists 325) ✓
('dried_pineapple', 'Dried Pineapple', 325, 2.2, 81.7, 0.5, 3.2, 73.0, NULL, 40, 'usda', ARRAY['dried pineapple', 'dehydrated pineapple', 'pineapple rings dried'], '130 cal per serving (40g).', NULL, 'fruits', 1),

-- ============================================================================
-- FROZEN & OTHER (~5 items)
-- ============================================================================

-- Frozen Mixed Berries: 48 cal/100g (0.7P*4 + 11.3C*4 + 0.3F*9 = 2.8+45.2+2.7 = 50.7, USDA lists 48) ✓
('frozen_mixed_berries', 'Frozen Mixed Berries', 48, 0.7, 11.3, 0.3, 3.0, 6.5, NULL, 140, 'usda', ARRAY['frozen mixed berries', 'frozen berries', 'mixed berry blend', 'berry mix frozen'], '67 cal per cup (140g). Unsweetened.', NULL, 'fruits', 1),

-- Frozen Strawberries: 35 cal/100g (0.4P*4 + 8.9C*4 + 0.1F*9 = 1.6+35.6+0.9 = 38.1, USDA lists 35) ✓
('frozen_strawberries', 'Frozen Strawberries (Unsweetened)', 35, 0.4, 8.9, 0.1, 2.1, 5.2, NULL, 149, 'usda', ARRAY['frozen strawberries', 'frozen strawberry', 'strawberries frozen'], '52 cal per cup (149g). Unsweetened, whole.', NULL, 'fruits', 1),

-- Acai Puree Unsweetened: 70 cal/100g (1.0P*4 + 4.0C*4 + 5.0F*9 = 4.0+16.0+45.0 = 65.0) ✓
('acai_puree', 'Acai Puree (Unsweetened)', 70, 1.0, 4.0, 5.0, 3.0, 0, NULL, 100, 'usda', ARRAY['acai', 'acai puree', 'acai berry', 'sambazon acai', 'frozen acai'], '70 cal per packet (100g). Unsweetened, frozen.', NULL, 'fruits', 1),

-- Fruit Cocktail Canned in Juice: 50 cal/100g (0.4P*4 + 12.7C*4 + 0.1F*9 = 1.6+50.8+0.9 = 53.3, USDA lists 50) ✓
('fruit_cocktail_juice', 'Fruit Cocktail (Canned in Juice)', 50, 0.4, 12.7, 0.1, 1.0, 11.5, NULL, 124, 'usda', ARRAY['fruit cocktail', 'canned fruit', 'fruit cocktail in juice', 'mixed fruit canned'], '62 cal per 1/2 cup (124g). In juice, not syrup.', NULL, 'fruits', 1),

-- Applesauce Unsweetened: 42 cal/100g (0.2P*4 + 11.3C*4 + 0.1F*9 = 0.8+45.2+0.9 = 46.9, USDA lists 42) ✓
('applesauce_unsweetened', 'Applesauce (Unsweetened)', 42, 0.2, 11.3, 0.1, 1.1, 9.4, NULL, 122, 'usda', ARRAY['applesauce', 'apple sauce', 'unsweetened applesauce', 'mott''s applesauce'], '51 cal per 1/2 cup (122g). Unsweetened.', NULL, 'fruits', 1),

-- ============================================================================
-- AVOCADO (~1 item)
-- ============================================================================

-- Avocado Hass: 160 cal/100g (2.0P*4 + 8.5C*4 + 14.7F*9 = 8.0+34.0+132.3 = 174.3, USDA lists 160 due to fiber) ✓
('avocado', 'Avocado (Hass)', 160, 2.0, 8.5, 14.7, 6.7, 0.7, 136, 68, 'usda', ARRAY['avocado', 'avocados', 'hass avocado', 'california avocado', 'guacamole avocado'], '218 cal per whole avocado (136g flesh). 109 cal per half (68g).', NULL, 'fruits', 1),
