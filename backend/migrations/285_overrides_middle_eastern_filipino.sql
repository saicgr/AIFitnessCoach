-- ============================================================================
-- 285_overrides_middle_eastern_filipino.sql
-- Generated: 2026-02-28
-- Total items: 69
--
-- Cuisines: Lebanese/Middle Eastern, Turkish, Filipino, Hawaiian/Polynesian
-- Sources: USDA FoodData Central, fatsecret.com, nutritionix.com,
--          snapcalorie.com, nutritionvalue.org, nutriscan.app,
--          Hawaii Nutrition Center, fitia.app
-- All values are per 100g of prepared/cooked food.
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, food_category, restaurant_name, default_count, notes
) VALUES

-- =====================================================
-- LEBANESE / MIDDLE EASTERN CUISINE
-- Sources: fatsecret.com, nutritionix.com, snapcalorie.com, USDA
-- =====================================================

-- Chicken Shawarma Wrap: ~205 cal/100g, 10.6g pro, 20g carb, 7.3g fat per 100g (whole wrap ~300g)
('chicken_shawarma_wrap', 'Chicken Shawarma Wrap', 205, 10.6, 20.0, 7.3, 1.5, 1.0, 300, 300,
 'lebanese_cuisine', ARRAY['shawarma wrap', 'chicken shawarma', 'shawarma sandwich'],
 'lebanese', NULL, 1, '205 cal/100g. Whole wrap ~300g. Pita, chicken, garlic sauce, pickles.'),

-- Beef Shawarma Wrap: slightly higher fat than chicken, ~230 cal/100g
('beef_shawarma_wrap', 'Beef Shawarma Wrap', 230, 11.0, 19.0, 11.5, 1.5, 1.0, 300, 300,
 'lebanese_cuisine', ARRAY['beef shawarma', 'lamb shawarma wrap', 'meat shawarma wrap'],
 'lebanese', NULL, 1, '230 cal/100g. Whole wrap ~300g. Pita, beef/lamb, tahini, pickles.'),

-- Shawarma Plate (meat + rice + salad): ~155 cal/100g combined
('shawarma_plate', 'Shawarma Plate', 155, 9.0, 16.0, 6.0, 1.0, 1.0, NULL, 450,
 'lebanese_cuisine', ARRAY['shawarma platter', 'chicken shawarma plate', 'shawarma rice plate'],
 'lebanese', NULL, 1, '155 cal/100g. Plate ~450g with rice, salad, garlic sauce.'),

-- Kibbeh (Fried): 257 cal/100g, 19.5g pro, 25.8g carb, 9g fat (fatsecret.com)
('kibbeh_fried', 'Kibbeh (Fried)', 257, 19.5, 25.8, 9.0, 6.2, 0.7, 60, 120,
 'lebanese_cuisine', ARRAY['fried kibbeh', 'kibbe', 'kubba', 'kebbeh'],
 'lebanese', NULL, 2, '257 cal/100g. Per piece ~60g. Bulgur wheat shell with spiced meat filling.'),

-- Kibbeh (Baked): leaner than fried, ~210 cal/100g
('kibbeh_baked', 'Kibbeh (Baked)', 210, 18.0, 22.0, 5.5, 5.0, 0.5, NULL, 150,
 'lebanese_cuisine', ARRAY['baked kibbeh', 'kibbeh bil sanieh', 'kibbeh tray'],
 'lebanese', NULL, 1, '210 cal/100g. Baked tray-style kibbeh, leaner than fried.'),

-- Fattoush: ~110 cal/100g (olive oil dressing, fried pita chips, vegetables)
('fattoush', 'Fattoush', 110, 2.0, 10.0, 7.0, 2.0, 3.0, NULL, 200,
 'lebanese_cuisine', ARRAY['fattoush salad', 'lebanese bread salad'],
 'lebanese', NULL, 1, '110 cal/100g. Serving ~200g. Fried pita, sumac dressing, mixed vegetables.'),

-- Tabbouleh: 124 cal/100g (USDA, nutritionvalue.org)
('tabbouleh', 'Tabbouleh', 124, 1.6, 9.7, 9.7, 1.8, 1.5, NULL, 150,
 'lebanese_cuisine', ARRAY['tabouleh', 'tabouli', 'bulgur parsley salad'],
 'lebanese', NULL, 1, '124 cal/100g. USDA data. Bulgur, parsley, tomato, olive oil, lemon.'),

-- Manakish Zaatar: ~304 cal/100g (snapcalorie.com, caloriehealthy.com)
('manakish_zaatar', 'Manakish (Za''atar Flatbread)', 304, 8.0, 40.0, 13.0, 2.5, 1.5, 150, 150,
 'lebanese_cuisine', ARRAY['manaeesh', 'manouche zaatar', 'zaatar flatbread', 'zaatar pizza', 'manakish'],
 'lebanese', NULL, 1, '304 cal/100g. Per piece ~150g. Za''atar herb & olive oil on flatbread.'),

-- Labneh: 150 cal/100g, 6g pro, 4g carb, 10g fat (healthline.com, snapcalorie.com)
('labneh', 'Labneh', 150, 6.0, 4.0, 10.0, 0.0, 3.5, NULL, 60,
 'lebanese_cuisine', ARRAY['labne', 'lebanese yogurt', 'strained yogurt', 'yogurt cheese'],
 'lebanese', NULL, 1, '150 cal/100g. Serving ~60g (2 tbsp). Strained yogurt spread.'),

-- Baba Ganoush: 137 cal/100g, 2g pro, 9g carb, 12g fat (fitia.app)
('baba_ganoush', 'Baba Ganoush', 137, 2.0, 9.0, 12.0, 3.5, 2.5, NULL, 60,
 'lebanese_cuisine', ARRAY['baba ghanoush', 'baba ghanouj', 'eggplant dip', 'mutabbal'],
 'lebanese', NULL, 1, '137 cal/100g. Serving ~60g. Roasted eggplant, tahini, lemon, garlic.'),

-- Muhammara: ~200 cal/100g, high in healthy fats from walnuts (nutritionvalue.org)
('muhammara', 'Muhammara', 200, 4.0, 16.0, 13.3, 3.0, 8.0, NULL, 60,
 'lebanese_cuisine', ARRAY['red pepper walnut dip', 'roasted pepper dip', 'muhammara dip'],
 'lebanese', NULL, 1, '200 cal/100g. Serving ~60g. Roasted red pepper, walnut, pomegranate dip.'),

-- Kafta/Kofta (Grilled): ~202 cal/100g, 13g pro, 2g carb, 15g fat (snapcalorie.com)
('kafta_grilled', 'Kafta (Grilled)', 202, 13.0, 2.0, 15.0, 0.5, 0.5, 100, 200,
 'lebanese_cuisine', ARRAY['kofta', 'kefta', 'grilled kafta', 'kafta kebab', 'kafta skewer'],
 'lebanese', NULL, 2, '202 cal/100g. Per skewer ~100g. Spiced ground beef/lamb with parsley & onion.'),

-- Fatayer (Meat Pie): ~250 cal/100g, 12g pro, 28g carb, 10g fat (nutriscan.app)
('fatayer_meat', 'Fatayer (Meat Pie)', 250, 12.0, 28.0, 10.0, 1.5, 1.0, 80, 160,
 'lebanese_cuisine', ARRAY['meat fatayer', 'lahm bi ajeen', 'meat pie lebanese'],
 'lebanese', NULL, 2, '250 cal/100g. Per piece ~80g. Pastry filled with spiced ground meat.'),

-- Fatayer (Spinach Pie): lighter than meat version, ~200 cal/100g
('fatayer_spinach', 'Fatayer (Spinach Pie)', 200, 5.0, 25.0, 9.0, 2.5, 1.0, 70, 140,
 'lebanese_cuisine', ARRAY['spinach fatayer', 'fatayer sabanekh', 'spinach pie lebanese'],
 'lebanese', NULL, 2, '200 cal/100g. Per piece ~70g. Pastry filled with spinach, onion, lemon.'),

-- Maqluba: ~150 cal/100g, 6.7g pro, 20g carb, 5g fat (snapcalorie.com)
('maqluba', 'Maqluba', 150, 6.7, 20.0, 5.0, 1.7, 1.7, NULL, 350,
 'lebanese_cuisine', ARRAY['maqlooba', 'maklouba', 'upside down rice', 'maqlubeh'],
 'lebanese', NULL, 1, '150 cal/100g. Serving ~350g. Layered rice, meat, eggplant/cauliflower.'),

-- Knafeh: ~267 cal/100g, 5.3g pro, 33.3g carb, 13.3g fat (snapcalorie.com, nutribit.app)
('knafeh', 'Knafeh', 267, 5.3, 33.3, 13.3, 1.3, 20.0, 120, 120,
 'lebanese_cuisine', ARRAY['kunafa', 'kanafeh', 'konafa', 'knafeh cheese'],
 'lebanese', NULL, 1, '267 cal/100g. Per piece ~120g. Shredded phyllo, cheese, sugar syrup.'),

-- Baklava: 440 cal/100g (USDA FoodData Central)
('baklava', 'Baklava', 440, 6.6, 37.6, 29.3, 1.8, 12.8, 40, 80,
 'lebanese_cuisine', ARRAY['baklawa', 'pistachio baklava', 'walnut baklava'],
 'lebanese', NULL, 2, '440 cal/100g. USDA data. Per piece ~40g. Layered phyllo, nuts, honey syrup.'),

-- Hummus with Meat (Hummus bil Lahmeh): richer than plain hummus, ~195 cal/100g
('hummus_with_meat', 'Hummus with Meat', 195, 10.0, 14.0, 11.0, 3.5, 0.5, NULL, 250,
 'lebanese_cuisine', ARRAY['hummus bil lahmeh', 'hummus with ground beef', 'hummus kawarma'],
 'lebanese', NULL, 1, '195 cal/100g. Serving ~250g. Hummus topped with spiced ground beef & pine nuts.'),

-- Sfiha (Open Meat Pie): ~260 cal/100g
('sfiha', 'Sfiha (Meat Pie)', 260, 12.0, 26.0, 12.0, 1.0, 1.5, 60, 180,
 'lebanese_cuisine', ARRAY['sfeeha', 'lahm bi ajeen open', 'lebanese meat pie'],
 'lebanese', NULL, 3, '260 cal/100g. Per piece ~60g. Open-faced mini meat pie with tomato & onion.'),

-- Luqaimat: ~350 cal/100g (deep-fried dough, sugar syrup)
('luqaimat', 'Luqaimat', 350, 4.0, 48.0, 16.0, 0.5, 28.0, 15, 90,
 'lebanese_cuisine', ARRAY['lokma', 'luqmat', 'sweet dumplings', 'awamat'],
 'lebanese', NULL, 6, '350 cal/100g. Per piece ~15g. Deep-fried dough balls in date/sugar syrup.'),

-- =====================================================
-- TURKISH CUISINE
-- Sources: nutriscan.app, snapcalorie.com, fitia.app, USDA, nutriely.com
-- =====================================================

-- Doner Kebab (meat only): 215 cal/100g, 18g pro, 6g carb, 13.5g fat (fitia.app)
('doner_kebab', 'Doner Kebab', 215, 18.0, 6.0, 13.5, 0.5, 1.0, NULL, 200,
 'turkish_cuisine', ARRAY['doner', 'donner kebab', 'doner meat', 'turkish doner'],
 'turkish', NULL, 1, '215 cal/100g. Serving ~200g. Seasoned meat cooked on vertical rotisserie.'),

-- Iskender Kebab: ~175 cal/100g (meat + bread + tomato sauce + yogurt + butter)
('iskender_kebab', 'Iskender Kebab', 175, 12.0, 10.0, 10.0, 0.5, 2.0, NULL, 400,
 'turkish_cuisine', ARRAY['iskender', 'bursa kebab', 'alexander kebab'],
 'turkish', NULL, 1, '175 cal/100g. Plate ~400g. Doner over pita with tomato sauce, yogurt, butter.'),

-- Adana Kebab: 225 cal/100g, 25g pro, 2g carb, 13g fat (nutriscan.app)
('adana_kebab', 'Adana Kebab', 225, 25.0, 2.0, 13.0, 0.5, 0.0, 100, 200,
 'turkish_cuisine', ARRAY['adana', 'spicy kebab', 'adana kofte'],
 'turkish', NULL, 2, '225 cal/100g. Per skewer ~100g. Spicy minced lamb on flat skewer, chargrilled.'),

-- Shish Kebab: 165 cal/100g, 22g pro, 3g carb, 7g fat (calorieking, snapcalorie.com)
('shish_kebab', 'Shish Kebab', 165, 22.0, 3.0, 7.0, 1.0, 1.5, 150, 150,
 'turkish_cuisine', ARRAY['sis kebab', 'shish kabob', 'lamb shish', 'meat skewer'],
 'turkish', NULL, 1, '165 cal/100g. Per skewer ~150g. Cubed marinated meat & vegetables, grilled.'),

-- Lahmacun (Turkish Pizza): 235 cal/100g, 8.1g pro, 18.4g carb, 12.5g fat (foodpal-app.com)
('lahmacun', 'Lahmacun (Turkish Pizza)', 235, 8.1, 18.4, 12.5, 2.1, 1.8, 180, 180,
 'turkish_cuisine', ARRAY['lahmajun', 'lahm bi ajeen', 'turkish pizza', 'lahma bi ajeen'],
 'turkish', NULL, 1, '235 cal/100g. Per piece ~180g. Thin flatbread with spiced minced meat topping.'),

-- Pide (Turkish Flatbread Boat): ~275 cal/100g (taskin bakery, snapcalorie.com)
('pide', 'Pide (Turkish Flatbread)', 275, 9.0, 38.0, 9.5, 2.0, 2.0, 250, 250,
 'turkish_cuisine', ARRAY['turkish pide', 'pide bread', 'ramazan pidesi', 'kasarli pide'],
 'turkish', NULL, 1, '275 cal/100g. Per piece ~250g. Boat-shaped bread with cheese/meat filling.'),

-- Borek (Cheese): ~320 cal/100g, 12g pro, 28g carb, 18g fat (nutriscan.app, aashpazi.com)
('borek', 'Borek (Cheese Pastry)', 320, 12.0, 28.0, 18.0, 1.0, 2.0, 100, 200,
 'turkish_cuisine', ARRAY['burek', 'sigara boregi', 'su boregi', 'cheese borek', 'turkish pastry'],
 'turkish', NULL, 2, '320 cal/100g. Per piece ~100g. Layered phyllo pastry with cheese or meat.'),

-- Kumpir (Loaded Baked Potato): ~155 cal/100g (aashpazi.com)
('kumpir', 'Kumpir (Turkish Loaded Potato)', 155, 4.8, 15.0, 8.5, 2.2, 1.8, NULL, 400,
 'turkish_cuisine', ARRAY['turkish baked potato', 'loaded baked potato turkish'],
 'turkish', NULL, 1, '155 cal/100g. Serving ~400g. Mashed inside skin, loaded with toppings.'),

-- Menemen (Turkish Scrambled Eggs): 71 cal/100g (dytseydaertas.com)
('menemen', 'Menemen (Turkish Scrambled Eggs)', 71, 4.5, 4.0, 4.0, 1.0, 2.5, NULL, 250,
 'turkish_cuisine', ARRAY['turkish scrambled eggs', 'menemen eggs', 'turkish eggs'],
 'turkish', NULL, 1, '71 cal/100g. Serving ~250g. Eggs scrambled with tomatoes, peppers, onions.'),

-- Kofte (Turkish Meatballs): ~220 cal/100g, 18g pro, 8g carb, 13g fat
('kofte', 'Kofte (Turkish Meatballs)', 220, 18.0, 8.0, 13.0, 0.5, 0.5, 30, 150,
 'turkish_cuisine', ARRAY['kofta', 'turkish meatballs', 'inegol kofte', 'izmir kofte'],
 'turkish', NULL, 5, '220 cal/100g. Per piece ~30g. Spiced ground meat shaped into balls/patties.'),

-- Manti (Turkish Dumplings): ~190 cal/100g, 8g pro, 25g carb, 6g fat (nutriscan.app)
('manti', 'Manti (Turkish Dumplings)', 190, 8.0, 25.0, 6.0, 1.0, 1.0, NULL, 250,
 'turkish_cuisine', ARRAY['turkish dumplings', 'turkish manti', 'manti dumplings'],
 'turkish', NULL, 1, '190 cal/100g. Serving ~250g. Tiny meat-filled dumplings with yogurt & garlic.'),

-- Imam Bayildi (Stuffed Eggplant): ~100 cal/100g (lower oil version)
('imam_bayildi', 'Imam Bayildi (Stuffed Eggplant)', 100, 1.5, 8.0, 7.0, 3.0, 4.0, 200, 200,
 'turkish_cuisine', ARRAY['imam bayildi', 'stuffed eggplant turkish', 'turkish aubergine'],
 'turkish', NULL, 1, '100 cal/100g. Per half ~200g. Eggplant stuffed with tomato, onion, olive oil.'),

-- Simit (Sesame Bread Ring): ~310 cal/100g (nutritionix.com)
('simit', 'Simit (Turkish Sesame Bread Ring)', 310, 10.0, 52.0, 7.0, 2.5, 3.0, 120, 120,
 'turkish_cuisine', ARRAY['turkish bagel', 'sesame bread ring', 'gevrek'],
 'turkish', NULL, 1, '310 cal/100g. Per ring ~120g. Circular bread coated in sesame seeds.'),

-- Turkish Delight (Lokum): ~390 cal/100g (nutritionvalue.org, checkyourfood.com)
('turkish_delight', 'Turkish Delight (Lokum)', 390, 0.5, 89.0, 1.2, 0.0, 78.0, 8, 40,
 'turkish_cuisine', ARRAY['lokum', 'loukoum', 'rahat lokum', 'turkish delight candy'],
 'turkish', NULL, 5, '390 cal/100g. Per piece ~8g. Gel confection with starch, sugar, rosewater.'),

-- Ayran (Turkish Yogurt Drink): ~40 cal/100g
('ayran', 'Ayran (Turkish Yogurt Drink)', 40, 2.0, 3.0, 2.0, 0.0, 3.0, NULL, 250,
 'turkish_cuisine', ARRAY['ayran drink', 'turkish yogurt drink', 'salted yogurt drink'],
 'turkish', NULL, 1, '40 cal/100g. Serving ~250ml glass. Yogurt, water, salt. Refreshing beverage.'),

-- Kunefe (Turkish): same base as knafeh but prepared Turkish style, ~280 cal/100g
('kunefe', 'Kunefe (Turkish Cheese Dessert)', 280, 6.0, 32.0, 14.0, 0.5, 22.0, 150, 150,
 'turkish_cuisine', ARRAY['Turkish kunafa', 'kunefe dessert', 'hatay kunefe'],
 'turkish', NULL, 1, '280 cal/100g. Per piece ~150g. Shredded kadayif, melted cheese, sugar syrup.'),

-- =====================================================
-- FILIPINO CUISINE
-- Sources: fatsecret.com, snapcalorie.com, nutritionix.com, FNRI
-- (Food and Nutrition Research Institute of the Philippines)
-- =====================================================

-- Chicken Adobo: ~141 cal/100g, ~16g pro (fatsecret.com)
('chicken_adobo', 'Chicken Adobo', 141, 16.0, 3.0, 7.0, 0.2, 1.5, NULL, 250,
 'filipino_cuisine', ARRAY['adobong manok', 'filipino chicken adobo', 'adobo chicken'],
 'filipino', NULL, 1, '141 cal/100g. Serving ~250g. Chicken braised in vinegar, soy sauce, garlic.'),

-- Pork Adobo: higher fat than chicken version, ~185 cal/100g
('pork_adobo', 'Pork Adobo', 185, 14.0, 3.0, 13.0, 0.2, 1.5, NULL, 250,
 'filipino_cuisine', ARRAY['adobong baboy', 'filipino pork adobo', 'adobo pork'],
 'filipino', NULL, 1, '185 cal/100g. Serving ~250g. Pork braised in vinegar, soy sauce, garlic, bay.'),

-- Sinigang (Pork): ~67 cal/100g (fitia.app, fatsecret.com)
('sinigang', 'Sinigang (Sour Soup)', 67, 5.0, 4.0, 3.5, 1.0, 1.5, NULL, 350,
 'filipino_cuisine', ARRAY['sinigang na baboy', 'pork sinigang', 'sinigang soup', 'tamarind soup'],
 'filipino', NULL, 1, '67 cal/100g. Serving ~350g bowl. Tamarind-sour soup with pork & vegetables.'),

-- Lumpia (Fried Spring Rolls): ~250 cal/100g (deep-fried pork filling)
('lumpia', 'Lumpia (Fried Spring Rolls)', 250, 10.0, 22.0, 13.0, 1.0, 1.0, 25, 150,
 'filipino_cuisine', ARRAY['lumpiang shanghai', 'fried lumpia', 'filipino spring roll', 'egg roll filipino'],
 'filipino', NULL, 6, '250 cal/100g. Per piece ~25g. Deep-fried pork & vegetable spring rolls.'),

-- Pancit Canton: ~170 cal/100g cooked with toppings (snapcalorie.com)
('pancit_canton', 'Pancit Canton (Stir-Fried Noodles)', 170, 6.0, 24.0, 5.5, 1.5, 1.5, NULL, 250,
 'filipino_cuisine', ARRAY['pancit', 'pansit canton', 'filipino stir fried noodles', 'pancit guisado'],
 'filipino', NULL, 1, '170 cal/100g. Serving ~250g. Egg noodles stir-fried with vegetables & meat.'),

-- Pancit Bihon: ~165 cal/100g cooked (snapcalorie.com, fatsecret.com)
('pancit_bihon', 'Pancit Bihon (Rice Noodles)', 165, 4.0, 28.0, 4.0, 1.0, 1.0, NULL, 250,
 'filipino_cuisine', ARRAY['bihon', 'pansit bihon', 'rice noodle stir fry', 'bihon guisado'],
 'filipino', NULL, 1, '165 cal/100g. Serving ~250g. Rice noodles stir-fried with vegetables & meat.'),

-- Lechon Kawali (Crispy Pork Belly): ~320 cal/100g (snapcalorie.com, fatsecret.com)
('lechon_kawali', 'Lechon Kawali (Crispy Pork Belly)', 320, 15.0, 5.0, 27.0, 0.0, 0.0, NULL, 150,
 'filipino_cuisine', ARRAY['crispy pata', 'fried pork belly', 'lechon kawali filipino'],
 'filipino', NULL, 1, '320 cal/100g. Serving ~150g. Deep-fried pork belly, crispy outside, tender inside.'),

-- Sisig: ~200 cal/100g (nutriscan.app)
('sisig', 'Sisig (Sizzling Pork)', 200, 13.0, 4.0, 15.0, 0.5, 0.5, NULL, 200,
 'filipino_cuisine', ARRAY['pork sisig', 'sizzling sisig', 'sisig kapampangan'],
 'filipino', NULL, 1, '200 cal/100g. Serving ~200g. Chopped pork face/ears, chili, onion, calamansi.'),

-- Kare-Kare: ~130 cal/100g (estimated from multiple recipe sources)
('kare_kare', 'Kare-Kare (Oxtail Peanut Stew)', 130, 8.0, 8.0, 8.0, 1.5, 2.0, NULL, 350,
 'filipino_cuisine', ARRAY['kare kare', 'oxtail stew', 'peanut stew filipino'],
 'filipino', NULL, 1, '130 cal/100g. Serving ~350g. Oxtail & vegetables in thick peanut sauce.'),

-- Tinola (Chicken Ginger Soup): ~60 cal/100g (snapcalorie.com, nutritionix.com)
('tinola', 'Tinola (Chicken Ginger Soup)', 60, 5.0, 4.0, 3.0, 0.8, 1.0, NULL, 350,
 'filipino_cuisine', ARRAY['tinolang manok', 'chicken tinola', 'ginger chicken soup filipino'],
 'filipino', NULL, 1, '60 cal/100g. Serving ~350g bowl. Chicken soup with ginger, green papaya, chili leaves.'),

-- Longganisa (Sweet Sausage): ~320 cal/100g (snapcalorie.com, fitia.app)
('longganisa', 'Longganisa (Filipino Sausage)', 320, 14.0, 8.0, 26.0, 0.0, 5.0, 50, 100,
 'filipino_cuisine', ARRAY['longanisa', 'filipino sausage', 'pork longganisa'],
 'filipino', NULL, 2, '320 cal/100g. Per link ~50g. Sweet garlic pork sausage, pan-fried.'),

-- Tapa (Cured Beef): ~180 cal/100g
('tapa', 'Tapa (Cured Beef)', 180, 22.0, 5.0, 8.0, 0.0, 4.0, NULL, 100,
 'filipino_cuisine', ARRAY['beef tapa', 'cured beef filipino', 'tapa beef'],
 'filipino', NULL, 1, '180 cal/100g. Serving ~100g. Thinly sliced cured/marinated beef, pan-fried.'),

-- Tocino (Sweet Cured Pork): ~220 cal/100g (mynetdiary.com)
('tocino', 'Tocino (Sweet Cured Pork)', 220, 12.0, 18.0, 11.0, 0.0, 15.0, NULL, 100,
 'filipino_cuisine', ARRAY['pork tocino', 'sweet pork filipino', 'tocino pork'],
 'filipino', NULL, 1, '220 cal/100g. Serving ~100g. Sweet-cured pork slices, caramelized when fried.'),

-- Tapsilog (Tapa + Sinangag + Itlog): ~185 cal/100g combined plate
('tapsilog', 'Tapsilog (Tapa, Garlic Rice, Egg)', 185, 10.0, 22.0, 6.5, 0.5, 2.0, NULL, 350,
 'filipino_cuisine', ARRAY['tap si log', 'tapa silog', 'tapa meal'],
 'filipino', NULL, 1, '185 cal/100g. Plate ~350g. Beef tapa + garlic fried rice + fried egg.'),

-- Longsilog (Longganisa + Sinangag + Itlog): ~210 cal/100g combined plate
('longsilog', 'Longsilog (Sausage, Garlic Rice, Egg)', 210, 8.0, 24.0, 9.0, 0.5, 3.0, NULL, 350,
 'filipino_cuisine', ARRAY['longganisa silog', 'longsi log', 'longganisa meal'],
 'filipino', NULL, 1, '210 cal/100g. Plate ~350g. Longganisa sausage + garlic fried rice + fried egg.'),

-- Halo-Halo: ~125 cal/100g (fatsecret.com)
('halo_halo', 'Halo-Halo', 125, 1.7, 23.0, 2.7, 0.5, 17.0, NULL, 300,
 'filipino_cuisine', ARRAY['halo halo', 'haluhalo', 'filipino shaved ice', 'halo halo dessert'],
 'filipino', NULL, 1, '125 cal/100g. Serving ~300g. Shaved ice, sweetened beans, fruits, ube ice cream.'),

-- Turon (Banana Spring Roll): ~280 cal/100g (estimated from multiple recipe sources)
('turon', 'Turon (Banana Spring Roll)', 280, 2.0, 42.0, 12.0, 1.5, 22.0, 60, 120,
 'filipino_cuisine', ARRAY['banana lumpia', 'fried banana roll', 'turon banana'],
 'filipino', NULL, 2, '280 cal/100g. Per piece ~60g. Banana & jackfruit in wrapper, fried, caramelized.'),

-- Bibingka (Rice Cake): ~250 cal/100g (mynetdiary.com)
('bibingka', 'Bibingka (Filipino Rice Cake)', 250, 4.0, 38.0, 9.0, 0.5, 18.0, 120, 120,
 'filipino_cuisine', ARRAY['rice cake filipino', 'bibingka galapong', 'coconut rice cake'],
 'filipino', NULL, 1, '250 cal/100g. Per piece ~120g. Baked rice cake with coconut milk & salted egg.'),

-- Dinuguan: ~106 cal/100g (fatsecret.com, wikicalories.com)
('dinuguan', 'Dinuguan (Pork Blood Stew)', 106, 14.0, 2.2, 4.3, 0.2, 0.5, NULL, 250,
 'filipino_cuisine', ARRAY['pork blood stew', 'chocolate meat', 'dinuguan filipino'],
 'filipino', NULL, 1, '106 cal/100g. Serving ~250g. Pork offal simmered in pork blood & vinegar.'),

-- Laing: ~85 cal/100g (fatsecret.com)
('laing', 'Laing (Taro Leaves in Coconut)', 85, 4.0, 5.0, 6.5, 2.0, 1.5, NULL, 200,
 'filipino_cuisine', ARRAY['laing bicolano', 'taro leaves coconut', 'gabi leaves'],
 'filipino', NULL, 1, '85 cal/100g. Serving ~200g. Taro leaves slow-cooked in coconut milk & chili.'),

-- Pinakbet: ~55 cal/100g (fatsecret.com)
('pinakbet', 'Pinakbet (Mixed Vegetables)', 55, 2.5, 6.0, 2.5, 2.0, 2.5, NULL, 200,
 'filipino_cuisine', ARRAY['pakbet', 'pinakbet ilocano', 'mixed vegetables filipino'],
 'filipino', NULL, 1, '55 cal/100g. Serving ~200g. Bitter melon, squash, eggplant in shrimp paste.'),

-- =====================================================
-- HAWAIIAN / POLYNESIAN CUISINE
-- Sources: Hawaii Nutrition Center, fatsecret.com, nutritionix.com,
--          snapcalorie.com, orderhawaiianfood.com
-- =====================================================

-- Poke (Tuna, marinated): ~133 cal/100g (snapcalorie.com, USDA)
('tuna_poke', 'Tuna Poke', 133, 17.0, 4.0, 5.3, 0.5, 2.0, NULL, 170,
 'hawaiian_cuisine', ARRAY['ahi poke', 'raw tuna poke', 'hawaiian poke', 'tuna poke bowl'],
 'hawaiian', NULL, 1, '133 cal/100g. Serving ~170g. Cubed raw ahi tuna in soy, sesame oil, onion.'),

-- Poke (Salmon, marinated): slightly higher fat than tuna, ~145 cal/100g
('salmon_poke', 'Salmon Poke', 145, 15.0, 4.0, 7.5, 0.5, 2.0, NULL, 170,
 'hawaiian_cuisine', ARRAY['salmon poke bowl', 'raw salmon poke', 'hawaiian salmon poke'],
 'hawaiian', NULL, 1, '145 cal/100g. Serving ~170g. Cubed raw salmon in soy, sesame oil, onion.'),

-- Loco Moco: ~153 cal/100g (slism.com, snapcalorie.com)
('loco_moco', 'Loco Moco', 153, 8.0, 15.0, 7.0, 0.3, 0.5, NULL, 450,
 'hawaiian_cuisine', ARRAY['hawaiian loco moco', 'loco moco plate'],
 'hawaiian', NULL, 1, '153 cal/100g. Plate ~450g. Rice, hamburger patty, fried egg, brown gravy.'),

-- Kalua Pork: 200 cal/100g, 20g pro, 0g carb, 12g fat (snapcalorie.com, Hawaii Nutrition Center)
('kalua_pork', 'Kalua Pork', 200, 20.0, 0.0, 12.0, 0.0, 0.0, NULL, 170,
 'hawaiian_cuisine', ARRAY['kalua pig', 'hawaiian pulled pork', 'kalua pua''a'],
 'hawaiian', NULL, 1, '200 cal/100g. Serving ~170g. Slow-smoked shredded pork, Hawaiian sea salt.'),

-- Spam Musubi: ~204 cal/100g (nutriscan.app, snapcalorie.com)
('spam_musubi', 'Spam Musubi', 204, 7.0, 28.0, 7.0, 0.3, 5.0, 120, 120,
 'hawaiian_cuisine', ARRAY['musubi', 'spam rice', 'hawaii spam musubi'],
 'hawaiian', NULL, 1, '204 cal/100g. Per piece ~120g. Grilled spam on sushi rice wrapped in nori.'),

-- Plate Lunch (Chicken Katsu): ~175 cal/100g (typical plate)
('plate_lunch_katsu', 'Plate Lunch (Chicken Katsu)', 175, 8.0, 20.0, 7.0, 0.5, 1.5, NULL, 500,
 'hawaiian_cuisine', ARRAY['chicken katsu plate', 'katsu plate lunch', 'hawaiian plate lunch'],
 'hawaiian', NULL, 1, '175 cal/100g. Plate ~500g. Chicken katsu + 2 scoops rice + macaroni salad.'),

-- Hawaiian Macaroni Salad: ~175 cal/100g (snapcalorie.com, nutritionix.com)
('hawaiian_macaroni_salad', 'Hawaiian Macaroni Salad', 175, 3.5, 18.0, 10.0, 0.8, 2.0, NULL, 150,
 'hawaiian_cuisine', ARRAY['mac salad', 'hawaiian mac salad', 'macaroni salad plate lunch'],
 'hawaiian', NULL, 1, '175 cal/100g. Serving ~150g. Elbow macaroni, mayo, apple cider vinegar.'),

-- Haupia (Coconut Pudding): ~190 cal/100g (eatthismuch.com, adjusted for standard recipe)
('haupia', 'Haupia (Coconut Pudding)', 190, 2.0, 22.0, 11.0, 0.5, 16.0, 60, 60,
 'hawaiian_cuisine', ARRAY['coconut pudding', 'hawaiian coconut dessert', 'haupia squares'],
 'hawaiian', NULL, 1, '190 cal/100g. Per square ~60g. Coconut milk pudding set with cornstarch.'),

-- Malasada (Portuguese Donut): ~350 cal/100g (snapcalorie.com, hawaii nutrition center)
('malasada', 'Malasada (Portuguese Donut)', 350, 6.0, 45.0, 16.0, 1.0, 18.0, 90, 90,
 'hawaiian_cuisine', ARRAY['malassada', 'portuguese donut', 'hawaiian donut', 'leonard''s malasada'],
 'hawaiian', NULL, 1, '350 cal/100g. Per piece ~90g. Deep-fried yeast dough rolled in sugar.'),

-- Lau Lau: ~165 cal/100g (nutritionix.com, fatsecret.com, Hawaii Nutrition Center)
('lau_lau', 'Lau Lau', 165, 16.0, 2.0, 10.5, 1.5, 0.5, 200, 200,
 'hawaiian_cuisine', ARRAY['laulau', 'hawaiian lau lau', 'pork lau lau'],
 'hawaiian', NULL, 1, '165 cal/100g. Per bundle ~200g. Pork & fish wrapped in taro/ti leaves, steamed.'),

-- Poi: ~55 cal/100g (USDA, fatsecret.com for cooked taro paste)
('poi', 'Poi', 55, 0.4, 13.0, 0.1, 0.5, 0.5, NULL, 120,
 'hawaiian_cuisine', ARRAY['hawaiian poi', 'taro poi', 'pounded taro'],
 'hawaiian', NULL, 1, '55 cal/100g. Serving ~120g. Cooked taro root pounded to paste, staple starch.'),

-- Shoyu Chicken: ~150 cal/100g (snapcalorie.com, hawaiian recipe sources)
('shoyu_chicken', 'Shoyu Chicken', 150, 15.0, 5.0, 7.5, 0.2, 4.0, NULL, 200,
 'hawaiian_cuisine', ARRAY['hawaiian shoyu chicken', 'soy sauce chicken hawaiian'],
 'hawaiian', NULL, 1, '150 cal/100g. Serving ~200g. Chicken simmered in soy sauce, ginger, brown sugar.')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    sugar_per_100g = EXCLUDED.sugar_per_100g,
    default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
    default_serving_g = EXCLUDED.default_serving_g,
    source = EXCLUDED.source,
    variant_names = EXCLUDED.variant_names,
    food_category = EXCLUDED.food_category,
    restaurant_name = EXCLUDED.restaurant_name,
    default_count = EXCLUDED.default_count,
    notes = EXCLUDED.notes,
    updated_at = NOW();
