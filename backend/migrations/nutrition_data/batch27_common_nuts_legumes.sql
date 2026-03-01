-- ============================================================================
-- Batch 27: Common Nuts, Seeds & Legumes
-- ~50 items commonly logged in fitness/calorie tracking apps
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov), nutritionvalue.org
-- All values are per 100g. Cooked values used for legumes.
-- Calorie cross-check: cal ≈ (protein*4 + carbs*4 + fat*9)
-- ============================================================================

-- ============================================================================
-- NUTS (~12 items), food_category = 'nuts_seeds'
-- ============================================================================

-- Almonds (raw): 579 cal, 21.2g P, 21.6g C, 49.9g F per 100g (USDA 170567)
('almonds_raw', 'Almonds (Raw)', 579, 21.2, 21.6, 49.9, 12.5, 4.4, NULL, 28, 'usda', ARRAY['raw almonds', 'almonds', 'whole almonds', 'natural almonds'], '162 cal per 1 oz (28g, ~23 almonds). Heart-healthy raw tree nut.', NULL, 'nuts_seeds', 1),

-- Almonds (roasted, salted): 598 cal, 20.4g P, 21.0g C, 52.5g F per 100g (USDA 170568)
('almonds_roasted', 'Almonds (Dry Roasted)', 598, 20.4, 21.0, 52.5, 11.8, 4.5, NULL, 28, 'usda', ARRAY['roasted almonds', 'toasted almonds', 'dry roasted almonds', 'salted almonds'], '167 cal per 1 oz (28g). Roasted almonds, lightly salted.', NULL, 'nuts_seeds', 1),

-- Peanuts (dry roasted): 585 cal, 23.7g P, 21.5g C, 49.2g F per 100g (USDA 172430)
('peanuts_dry_roasted', 'Peanuts (Dry Roasted)', 585, 23.7, 21.5, 49.2, 8.0, 4.2, NULL, 28, 'usda', ARRAY['roasted peanuts', 'peanuts', 'dry roasted peanuts', 'salted peanuts'], '164 cal per 1 oz (28g). Crunchy protein-rich legume/nut.', NULL, 'nuts_seeds', 1),

-- Walnuts (halves): 654 cal, 15.2g P, 13.7g C, 65.2g F per 100g (USDA 170187)
('walnuts', 'Walnuts', 654, 15.2, 13.7, 65.2, 6.7, 2.6, NULL, 28, 'usda', ARRAY['walnut halves', 'english walnuts', 'raw walnuts', 'walnut pieces'], '183 cal per 1 oz (28g, ~14 halves). Rich in omega-3 fatty acids.', NULL, 'nuts_seeds', 1),

-- Cashews (roasted): 574 cal, 15.3g P, 32.7g C, 46.4g F per 100g (USDA 170162)
('cashews', 'Cashews (Roasted)', 574, 15.3, 32.7, 46.4, 3.0, 5.0, NULL, 28, 'usda', ARRAY['cashew nuts', 'roasted cashews', 'salted cashews', 'cashews'], '161 cal per 1 oz (28g, ~18 cashews). Creamy, mildly sweet nut.', NULL, 'nuts_seeds', 1),

-- Pecans (halves): 691 cal, 9.2g P, 13.9g C, 72.0g F per 100g (USDA 170182)
('pecans', 'Pecans', 691, 9.2, 13.9, 72.0, 9.6, 4.0, NULL, 28, 'usda', ARRAY['pecan halves', 'raw pecans', 'pecan pieces', 'shelled pecans'], '193 cal per 1 oz (28g, ~19 halves). Buttery Southern nut.', NULL, 'nuts_seeds', 1),

-- Pistachios (shelled): 562 cal, 20.2g P, 27.2g C, 45.3g F per 100g (USDA 170184)
('pistachios', 'Pistachios', 562, 20.2, 27.2, 45.3, 10.6, 7.7, NULL, 28, 'usda', ARRAY['pistachio nuts', 'shelled pistachios', 'roasted pistachios', 'pistachio kernels'], '157 cal per 1 oz (28g, ~49 pistachios). Green-hued snacking nut.', NULL, 'nuts_seeds', 1),

-- Macadamia Nuts: 718 cal, 7.9g P, 13.8g C, 75.8g F per 100g (USDA 170178)
('macadamia_nuts', 'Macadamia Nuts', 718, 7.9, 13.8, 75.8, 8.6, 4.6, NULL, 28, 'usda', ARRAY['macadamia', 'mac nuts', 'raw macadamias', 'macadamia nut'], '201 cal per 1 oz (28g, ~10 nuts). Highest fat nut, buttery flavor.', NULL, 'nuts_seeds', 1),

-- Hazelnuts (filberts): 628 cal, 15.0g P, 16.7g C, 60.8g F per 100g (USDA 170581)
('hazelnuts', 'Hazelnuts', 628, 15.0, 16.7, 60.8, 9.7, 4.3, NULL, 28, 'usda', ARRAY['filberts', 'hazelnut', 'raw hazelnuts', 'cobnut'], '176 cal per 1 oz (28g, ~21 nuts). Base nut for Nutella/praline.', NULL, 'nuts_seeds', 1),

-- Brazil Nuts: 659 cal, 14.3g P, 11.7g C, 67.1g F per 100g (USDA 170569)
('brazil_nuts', 'Brazil Nuts', 659, 14.3, 11.7, 67.1, 7.5, 2.3, 5, 28, 'usda', ARRAY['brazil nut', 'raw brazil nuts', 'para nuts'], '185 cal per 1 oz (28g, ~6 nuts). Extremely high in selenium.', NULL, 'nuts_seeds', 1),

-- Mixed Nuts (roasted, salted): 607 cal, 17.9g P, 21.4g C, 54.3g F per 100g (USDA 168597)
('mixed_nuts_roasted', 'Mixed Nuts (Roasted)', 607, 17.9, 21.4, 54.3, 7.1, 3.6, NULL, 28, 'usda', ARRAY['mixed nuts', 'nut mix', 'roasted mixed nuts', 'salted mixed nuts', 'party nuts'], '170 cal per 1 oz (28g). Assorted roasted and salted tree nuts.', NULL, 'nuts_seeds', 1),

-- Coconut (dried, shredded, unsweetened): 660 cal, 6.9g P, 23.7g C, 64.5g F per 100g (USDA 170172)
('coconut_dried_shredded', 'Coconut (Dried, Shredded)', 660, 6.9, 23.7, 64.5, 16.3, 7.4, NULL, 23, 'usda', ARRAY['desiccated coconut', 'shredded coconut', 'dried coconut', 'coconut flakes unsweetened'], '152 cal per 1/4 cup (23g). Unsweetened dried coconut meat.', NULL, 'nuts_seeds', 1),

-- ============================================================================
-- NUT BUTTERS (~5 items), food_category = 'nuts_seeds'
-- ============================================================================

-- Peanut Butter (smooth): 588 cal, 25.1g P, 19.6g C, 50.4g F per 100g (USDA 172470)
('peanut_butter_smooth', 'Peanut Butter (Smooth)', 588, 25.1, 19.6, 50.4, 6.0, 9.2, NULL, 32, 'usda', ARRAY['peanut butter', 'creamy peanut butter', 'pb', 'smooth peanut butter', 'skippy peanut butter', 'jif peanut butter'], '188 cal per 2 tbsp (32g). Classic smooth peanut butter.', NULL, 'nuts_seeds', 1),

-- Peanut Butter (natural, no stir): 593 cal, 25.0g P, 17.7g C, 51.5g F per 100g
('peanut_butter_natural', 'Peanut Butter (Natural)', 593, 25.0, 17.7, 51.5, 6.0, 6.0, NULL, 32, 'usda', ARRAY['natural peanut butter', 'no stir peanut butter', 'peanut butter natural', 'organic peanut butter'], '190 cal per 2 tbsp (32g). Peanuts and salt only, no added sugar/oil.', NULL, 'nuts_seeds', 1),

-- Almond Butter: 614 cal, 21.0g P, 18.8g C, 55.5g F per 100g (USDA 168588)
('almond_butter', 'Almond Butter', 614, 21.0, 18.8, 55.5, 10.5, 4.4, NULL, 32, 'usda', ARRAY['almond spread', 'raw almond butter', 'ab'], '196 cal per 2 tbsp (32g). Smooth ground almond spread.', NULL, 'nuts_seeds', 1),

-- Cashew Butter: 587 cal, 17.6g P, 27.6g C, 49.4g F per 100g (USDA 168591)
('cashew_butter', 'Cashew Butter', 587, 17.6, 27.6, 49.4, 2.0, 5.3, NULL, 32, 'usda', ARRAY['cashew spread', 'cashew nut butter'], '188 cal per 2 tbsp (32g). Creamy cashew spread.', NULL, 'nuts_seeds', 1),

-- Sunflower Seed Butter: 617 cal, 17.3g P, 24.0g C, 55.2g F per 100g (USDA 168604)
('sunflower_seed_butter', 'Sunflower Seed Butter', 617, 17.3, 24.0, 55.2, 4.4, 8.5, NULL, 32, 'usda', ARRAY['sun butter', 'sunbutter', 'sunflower butter', 'seed butter'], '197 cal per 2 tbsp (32g). Nut-free peanut butter alternative.', NULL, 'nuts_seeds', 1),

-- ============================================================================
-- SEEDS (~8 items), food_category = 'nuts_seeds'
-- ============================================================================

-- Chia Seeds: 486 cal, 16.5g P, 42.1g C, 30.7g F per 100g (USDA 170554)
('chia_seeds', 'Chia Seeds', 486, 16.5, 42.1, 30.7, 34.4, 0.0, NULL, 12, 'usda', ARRAY['chia', 'whole chia seeds', 'black chia seeds'], '58 cal per 1 tbsp (12g). Extremely high fiber superfood seed.', NULL, 'nuts_seeds', 1),

-- Flaxseed (ground): 534 cal, 18.3g P, 28.9g C, 42.2g F per 100g (USDA 169414)
('flaxseed_ground', 'Flaxseed (Ground)', 534, 18.3, 28.9, 42.2, 27.3, 1.6, NULL, 7, 'usda', ARRAY['ground flax', 'flax meal', 'milled flaxseed', 'linseed ground'], '37 cal per 1 tbsp (7g). Rich in omega-3 ALA, best absorbed when ground.', NULL, 'nuts_seeds', 1),

-- Hemp Seeds (hulled): 553 cal, 31.6g P, 8.7g C, 48.8g F per 100g (USDA 170148)
('hemp_seeds', 'Hemp Seeds (Hulled)', 553, 31.6, 8.7, 48.8, 4.0, 1.5, NULL, 30, 'usda', ARRAY['hemp hearts', 'shelled hemp seeds', 'hulled hemp seeds', 'hemp seed hearts'], '166 cal per 3 tbsp (30g). Complete plant protein with all essential aminos.', NULL, 'nuts_seeds', 1),

-- Pumpkin Seeds (pepitas, raw): 559 cal, 30.2g P, 10.7g C, 49.1g F per 100g (USDA 170188)
('pumpkin_seeds', 'Pumpkin Seeds (Pepitas)', 559, 30.2, 10.7, 49.1, 6.0, 1.4, NULL, 28, 'usda', ARRAY['pepitas', 'pumpkin seed kernels', 'raw pumpkin seeds', 'green pumpkin seeds'], '157 cal per 1 oz (28g). Excellent source of magnesium and zinc.', NULL, 'nuts_seeds', 1),

-- Sunflower Seeds (hulled, dry roasted): 582 cal, 19.3g P, 24.1g C, 49.8g F per 100g (USDA 170562)
('sunflower_seeds', 'Sunflower Seeds (Hulled)', 582, 19.3, 24.1, 49.8, 9.0, 2.6, NULL, 28, 'usda', ARRAY['sunflower kernels', 'shelled sunflower seeds', 'roasted sunflower seeds'], '163 cal per 1 oz (28g). Popular high vitamin E snack seed.', NULL, 'nuts_seeds', 1),

-- Sesame Seeds: 573 cal, 17.7g P, 23.5g C, 49.7g F per 100g (USDA 170150)
('sesame_seeds', 'Sesame Seeds', 573, 17.7, 23.5, 49.7, 11.8, 0.3, NULL, 9, 'usda', ARRAY['white sesame seeds', 'toasted sesame seeds', 'sesame', 'til seeds'], '52 cal per 1 tbsp (9g). Used in baking, cooking, tahini base.', NULL, 'nuts_seeds', 1),

-- Poppy Seeds: 525 cal, 17.9g P, 28.1g C, 41.6g F per 100g (USDA 170184)
('poppy_seeds', 'Poppy Seeds', 525, 17.9, 28.1, 41.6, 19.5, 2.9, NULL, 9, 'usda', ARRAY['poppyseed', 'poppy seed', 'baking poppy seeds'], '47 cal per 1 tbsp (9g). Blue-grey seeds for baking and garnish.', NULL, 'nuts_seeds', 1),

-- Tahini: 595 cal, 17.0g P, 21.2g C, 53.8g F per 100g (USDA 168604)
('tahini', 'Tahini (Sesame Paste)', 595, 17.0, 21.2, 53.8, 9.3, 0.5, NULL, 15, 'usda', ARRAY['sesame paste', 'tahina', 'sesame tahini', 'sesame seed butter'], '89 cal per 1 tbsp (15g). Ground sesame seed paste, key in hummus.', NULL, 'nuts_seeds', 1),

-- ============================================================================
-- LEGUMES (COOKED) (~15 items), food_category = 'legumes'
-- ============================================================================

-- Black Beans (cooked): 132 cal, 8.9g P, 23.7g C, 0.5g F per 100g (USDA 173735)
('black_beans', 'Black Beans (Cooked)', 132, 8.9, 23.7, 0.5, 8.7, 0.3, NULL, 172, 'usda', ARRAY['cooked black beans', 'black turtle beans', 'frijoles negros', 'canned black beans'], '227 cal per 1 cup (172g). Staple high-fiber, high-protein legume.', NULL, 'legumes', 1),

-- Kidney Beans (cooked): 127 cal, 8.7g P, 22.8g C, 0.5g F per 100g (USDA 175194)
('kidney_beans', 'Kidney Beans (Cooked)', 127, 8.7, 22.8, 0.5, 6.4, 0.3, NULL, 177, 'usda', ARRAY['cooked kidney beans', 'red kidney beans', 'rajma', 'canned kidney beans'], '225 cal per 1 cup (177g). Classic bean for chili and salads.', NULL, 'legumes', 1),

-- Pinto Beans (cooked): 143 cal, 9.0g P, 26.2g C, 0.7g F per 100g (USDA 173744)
('pinto_beans', 'Pinto Beans (Cooked)', 143, 9.0, 26.2, 0.7, 9.0, 0.3, NULL, 171, 'usda', ARRAY['cooked pinto beans', 'frijoles', 'canned pinto beans', 'brown beans'], '245 cal per 1 cup (171g). Mexican/Southwestern staple bean.', NULL, 'legumes', 1),

-- Navy Beans (cooked): 140 cal, 8.2g P, 26.1g C, 0.6g F per 100g (USDA 173742)
('navy_beans', 'Navy Beans (Cooked)', 140, 8.2, 26.1, 0.6, 10.5, 0.3, NULL, 182, 'usda', ARRAY['cooked navy beans', 'white navy beans', 'haricot beans', 'boston beans'], '255 cal per 1 cup (182g). Small white bean, base for baked beans.', NULL, 'legumes', 1),

-- Cannellini / White Beans (cooked): 139 cal, 9.7g P, 25.1g C, 0.4g F per 100g (USDA 175196)
('cannellini_beans', 'Cannellini Beans (Cooked)', 139, 9.7, 25.1, 0.4, 6.3, 0.3, NULL, 179, 'usda', ARRAY['white beans', 'great northern beans', 'cooked white beans', 'cannellini', 'white kidney beans'], '249 cal per 1 cup (179g). Creamy white Italian bean.', NULL, 'legumes', 1),

-- Chickpeas / Garbanzo Beans (cooked): 164 cal, 8.9g P, 27.4g C, 2.6g F per 100g (USDA 173757)
('chickpeas', 'Chickpeas (Cooked)', 164, 8.9, 27.4, 2.6, 7.6, 4.8, NULL, 164, 'usda', ARRAY['garbanzo beans', 'chole', 'cooked chickpeas', 'canned chickpeas', 'chana'], '269 cal per 1 cup (164g). Versatile legume for hummus, curries, salads.', NULL, 'legumes', 1),

-- Green Lentils (cooked): 116 cal, 9.0g P, 20.1g C, 0.4g F per 100g (USDA 172421)
('lentils_green', 'Lentils (Green, Cooked)', 116, 9.0, 20.1, 0.4, 7.9, 1.8, NULL, 198, 'usda', ARRAY['cooked green lentils', 'french lentils', 'green lentils', 'lentils cooked'], '230 cal per 1 cup (198g). Hold shape well, great for salads.', NULL, 'legumes', 1),

-- Red Lentils (cooked): 116 cal, 9.0g P, 20.1g C, 0.4g F per 100g (USDA 172421)
('lentils_red', 'Lentils (Red, Cooked)', 116, 9.0, 20.1, 0.4, 7.9, 1.8, NULL, 198, 'usda', ARRAY['cooked red lentils', 'masoor dal', 'red split lentils', 'red lentils'], '230 cal per 1 cup (198g). Cook down soft, perfect for soups and dal.', NULL, 'legumes', 1),

-- Split Peas (cooked): 118 cal, 8.3g P, 21.1g C, 0.4g F per 100g (USDA 173746)
('split_peas', 'Split Peas (Cooked)', 118, 8.3, 21.1, 0.4, 8.3, 2.9, NULL, 196, 'usda', ARRAY['cooked split peas', 'green split peas', 'yellow split peas', 'pea soup peas'], '231 cal per 1 cup (196g). Classic split pea soup base.', NULL, 'legumes', 1),

-- Lima Beans (cooked): 115 cal, 7.8g P, 20.9g C, 0.4g F per 100g (USDA 173750)
('lima_beans', 'Lima Beans (Cooked)', 115, 7.8, 20.9, 0.4, 7.0, 2.9, NULL, 170, 'usda', ARRAY['cooked lima beans', 'butter beans', 'large lima beans', 'baby lima beans'], '196 cal per 1 cup (170g). Also called butter beans, creamy texture.', NULL, 'legumes', 1),

-- Black-Eyed Peas (cooked): 116 cal, 7.7g P, 20.8g C, 0.5g F per 100g (USDA 175198)
('black_eyed_peas', 'Black-Eyed Peas (Cooked)', 116, 7.7, 20.8, 0.5, 6.5, 3.3, NULL, 172, 'usda', ARRAY['cowpeas', 'cooked black eyed peas', 'black eye peas', 'southern peas'], '200 cal per 1 cup (172g). Southern staple, earthy mild flavor.', NULL, 'legumes', 1),

-- Refried Beans (canned): 91 cal, 5.4g P, 14.9g C, 1.2g F per 100g (USDA 172437)
('refried_beans', 'Refried Beans', 91, 5.4, 14.9, 1.2, 5.4, 0.5, NULL, 126, 'usda', ARRAY['frijoles refritos', 'canned refried beans', 'mashed pinto beans', 'refried pinto beans'], '115 cal per 1/2 cup (126g). Mashed seasoned pinto beans.', NULL, 'legumes', 1),

-- Baked Beans (canned): 94 cal, 4.8g P, 17.5g C, 0.5g F per 100g (USDA 172438)
('baked_beans', 'Baked Beans (Canned)', 94, 4.8, 17.5, 0.5, 5.5, 8.5, NULL, 130, 'usda', ARRAY['canned baked beans', 'bush baked beans', 'bbq baked beans', 'beans in sauce'], '122 cal per 1/2 cup (130g). Navy beans in sweet tomato sauce.', NULL, 'legumes', 1),

-- Soybeans / Edamame (shelled, cooked): 141 cal, 12.4g P, 11.1g C, 6.4g F per 100g (USDA 168411)
('edamame', 'Edamame (Shelled, Cooked)', 141, 12.4, 11.1, 6.4, 5.2, 2.2, NULL, 155, 'usda', ARRAY['soybeans', 'cooked edamame', 'shelled edamame', 'soy beans', 'mukimame'], '219 cal per 1 cup shelled (155g). Young soybeans, complete plant protein.', NULL, 'legumes', 1),

-- Hummus: 166 cal, 7.9g P, 14.3g C, 9.6g F per 100g (USDA 174288)
('hummus', 'Hummus', 166, 7.9, 14.3, 9.6, 6.0, 0.3, NULL, 30, 'usda', ARRAY['plain hummus', 'chickpea hummus', 'hommus', 'houmous'], '50 cal per 2 tbsp (30g). Chickpea and tahini dip/spread.', NULL, 'legumes', 1),

-- ============================================================================
-- OTHER (~5 items)
-- ============================================================================

-- Trail Mix (standard, nuts/seeds/raisins): 462 cal, 13.8g P, 44.5g C, 28.6g F per 100g (USDA 168601)
('trail_mix', 'Trail Mix', 462, 13.8, 44.5, 28.6, 4.9, 31.0, NULL, 40, 'usda', ARRAY['nut and raisin mix', 'gorp', 'hiking mix', 'standard trail mix'], '185 cal per 1/4 cup (40g). Nuts, seeds, raisins, M&Ms mix.', NULL, 'nuts_seeds', 1),

-- Mixed Nuts and Dried Fruit: 483 cal, 11.0g P, 47.0g C, 30.0g F per 100g
('mixed_nuts_dried_fruit', 'Mixed Nuts and Dried Fruit', 483, 11.0, 47.0, 30.0, 5.5, 30.0, NULL, 40, 'usda', ARRAY['fruit and nut mix', 'nut fruit trail mix', 'dried fruit nut blend'], '193 cal per 1/4 cup (40g). Blend of roasted nuts and dried fruits.', NULL, 'nuts_seeds', 1),

-- Granola Clusters: 471 cal, 9.0g P, 64.0g C, 20.0g F per 100g
('granola_clusters', 'Granola Clusters', 471, 9.0, 64.0, 20.0, 5.0, 25.0, NULL, 30, 'usda', ARRAY['crunchy granola clusters', 'granola bites', 'oat clusters'], '141 cal per 1/3 cup (30g). Crunchy baked oat, nut, and honey clusters.', NULL, 'nuts_seeds', 1),

-- Peanut Flour (defatted): 327 cal, 52.2g P, 34.7g C, 0.6g F per 100g (USDA 168600)
('peanut_flour_defatted', 'Peanut Flour (Defatted)', 327, 52.2, 34.7, 0.6, 4.5, 7.5, NULL, 15, 'usda', ARRAY['peanut powder', 'pb2', 'powdered peanut butter', 'defatted peanut flour', 'pbfit'], '49 cal per 2 tbsp (15g). Low-fat, high-protein peanut powder.', NULL, 'nuts_seeds', 1),

-- Coconut Flour: 443 cal, 19.3g P, 60.0g C, 14.7g F per 100g (USDA 168847)
('coconut_flour', 'Coconut Flour', 443, 19.3, 60.0, 14.7, 39.0, 8.0, NULL, 14, 'usda', ARRAY['ground coconut', 'coconut baking flour', 'gluten free coconut flour'], '62 cal per 2 tbsp (14g). High-fiber, gluten-free baking flour.', NULL, 'nuts_seeds', 1)