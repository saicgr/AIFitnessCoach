-- 1576_overrides_snacks_chocolates_oils.sql
-- Branded chocolate bars, nut products, pork rinds, honey & syrups, seed & trail mix,
-- cooking & specialty oils, international & specialty snacks, health/organic snacks.
-- Sources: USDA FoodData Central, nutritionix.com, nutritionvalue.org, eatthismuch.com,
-- calorieking.com, fatsecret.com, manufacturer labels, snapcalorie.com, foodstruct.com.
-- All values per 100g, computed from per-serving label data where noted.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ==========================================
-- A. BRANDED CHOCOLATE BARS (~60 items)
-- ==========================================

-- ---- HERSHEY'S ----

-- Hershey's Milk Chocolate Bar: per 100g from USDA/nutritionvalue: 512 cal, 7.0P, 60.5C, 30.2F, 1.2 fiber, 54.7 sugar.
('hersheys_milk_chocolate', 'Hershey''s Milk Chocolate Bar', 512, 7.0, 60.5, 30.2,
 1.2, 54.7, 43, 43,
 'hersheys', ARRAY['hersheys milk chocolate', 'hershey''s milk chocolate bar', 'hershey bar', 'hersheys chocolate bar'],
 'chocolate', 'Hershey''s', 1, '512 cal/100g. Per 43g bar: 220 cal. Classic American milk chocolate.', TRUE),

-- Hershey's Cookies 'n' Creme: per 100g: 534 cal, 6.0P, 61.5C, 30.0F, 0.5 fiber, 52.0 sugar.
('hersheys_cookies_n_creme', 'Hershey''s Cookies ''n'' Creme Bar', 534, 6.0, 61.5, 30.0,
 0.5, 52.0, 43, 43,
 'hersheys', ARRAY['hersheys cookies and creme', 'hershey''s cookies n creme', 'cookies and cream hershey', 'hersheys cookies n cream bar'],
 'chocolate', 'Hershey''s', 1, '534 cal/100g. Per 43g bar: 230 cal. White creme with chocolate cookie pieces.', TRUE),

-- Hershey's Special Dark: per 100g: 490 cal, 5.3P, 62.2C, 26.7F, 4.4 fiber, 46.7 sugar.
('hersheys_special_dark', 'Hershey''s Special Dark Mildly Sweet Chocolate', 490, 5.3, 62.2, 26.7,
 4.4, 46.7, 41, 41,
 'hersheys', ARRAY['hersheys special dark', 'hershey''s special dark', 'hershey dark chocolate', 'special dark bar'],
 'chocolate', 'Hershey''s', 1, '490 cal/100g. Per 41g bar: 200 cal. Mildly sweet dark chocolate (45% cacao).', TRUE),

-- Hershey's Kisses Milk Chocolate: per 100g: 533 cal, 6.7P, 60.0C, 31.1F, 1.1 fiber, 55.6 sugar.
('hersheys_kisses', 'Hershey''s Kisses Milk Chocolate', 533, 6.7, 60.0, 31.1,
 1.1, 55.6, 41, 4.5,
 'hersheys', ARRAY['hershey kisses', 'hershey''s kisses', 'hersheys kisses milk chocolate', 'chocolate kisses'],
 'chocolate', 'Hershey''s', 9, '533 cal/100g. Per piece (4.5g): 24 cal. Iconic drop-shaped milk chocolates.', TRUE),

-- Hershey's Nuggets Milk Chocolate: per 100g: 533 cal, 7.1P, 57.1C, 32.1F, 1.8 fiber, 50.0 sugar.
('hersheys_nuggets', 'Hershey''s Nuggets Milk Chocolate', 533, 7.1, 57.1, 32.1,
 1.8, 50.0, 40, 10,
 'hersheys', ARRAY['hersheys nuggets', 'hershey''s nuggets', 'hershey nuggets milk chocolate'],
 'chocolate', 'Hershey''s', 4, '533 cal/100g. Per piece (10g): 53 cal. Bite-sized milk chocolate nuggets.', TRUE),

-- ---- MARS / MILKY WAY ----

-- Snickers Bar: per 100g from USDA: 491 cal, 7.5P, 61.0C, 23.9F, 2.3 fiber, 50.5 sugar.
('snickers', 'Snickers Bar', 491, 7.5, 61.0, 23.9,
 2.3, 50.5, 52, 52,
 'mars', ARRAY['snickers bar', 'snickers', 'snickers candy bar', 'snickers original'],
 'chocolate', 'Mars', 1, '491 cal/100g. Per 52g bar: 255 cal. Peanuts, nougat, caramel, milk chocolate.', TRUE),

-- Milky Way Bar: per 100g from USDA: 456 cal, 3.9P, 71.2C, 17.3F, 0.8 fiber, 60.0 sugar.
('milky_way', 'Milky Way Bar', 456, 3.9, 71.2, 17.3,
 0.8, 60.0, 52, 52,
 'mars', ARRAY['milky way', 'milky way bar', 'milky way candy bar', 'milky way chocolate'],
 'chocolate', 'Mars', 1, '456 cal/100g. Per 52g bar: 240 cal. Nougat topped with caramel, covered in milk chocolate.', TRUE),

-- Mars Bar: per 100g: 449 cal, 4.3P, 69.0C, 17.4F, 0.6 fiber, 60.6 sugar.
('mars_bar', 'Mars Bar', 449, 4.3, 69.0, 17.4,
 0.6, 60.6, 51, 51,
 'mars', ARRAY['mars bar', 'mars candy bar', 'mars chocolate bar'],
 'chocolate', 'Mars', 1, '449 cal/100g. Per 51g bar: 229 cal. Nougat and caramel covered in milk chocolate.', TRUE),

-- Bounty: per 100g: 487 cal, 3.7P, 58.9C, 25.7F, 3.5 fiber, 49.1 sugar.
('bounty', 'Bounty Coconut Milk Chocolate Bar', 487, 3.7, 58.9, 25.7,
 3.5, 49.1, 57, 28.5,
 'mars', ARRAY['bounty bar', 'bounty coconut', 'bounty chocolate', 'bounty milk chocolate'],
 'chocolate', 'Mars', 1, '487 cal/100g. Per 57g pack (2 bars): 278 cal. Sweet coconut filling in milk chocolate.', TRUE),

-- 3 Musketeers: per 100g from USDA: 430 cal, 3.0P, 74.0C, 13.0F, 1.0 fiber, 63.0 sugar.
('three_musketeers', '3 Musketeers Bar', 430, 3.0, 74.0, 13.0,
 1.0, 63.0, 54, 54,
 'mars', ARRAY['3 musketeers', 'three musketeers', '3 musketeers bar', '3 musketeers candy bar'],
 'chocolate', 'Mars', 1, '430 cal/100g. Per 54g bar: 232 cal. Fluffy whipped nougat covered in milk chocolate.', TRUE),

-- Twix: per 100g from USDA: 502 cal, 4.9P, 63.7C, 25.3F, 0.8 fiber, 49.0 sugar.
('twix', 'Twix Caramel Cookie Bars', 502, 4.9, 63.7, 25.3,
 0.8, 49.0, 50, 25,
 'mars', ARRAY['twix bar', 'twix', 'twix caramel cookie', 'twix candy bar'],
 'chocolate', 'Mars', 1, '502 cal/100g. Per 50g pack (2 bars): 250 cal. Cookie, caramel, milk chocolate.', TRUE),

-- Butterfinger: per 100g from USDA: 459 cal, 5.4P, 65.0C, 19.5F, 1.4 fiber, 47.0 sugar.
('butterfinger', 'Butterfinger Bar', 459, 5.4, 65.0, 19.5,
 1.4, 47.0, 54, 54,
 'ferrero', ARRAY['butterfinger', 'butterfinger bar', 'butterfinger candy bar', 'butter finger'],
 'chocolate', 'Butterfinger', 1, '459 cal/100g. Per 54g bar: 248 cal. Crispy peanut butter center in milk chocolate.', TRUE),

-- Baby Ruth: per 100g from USDA: 459 cal, 5.4P, 63.0C, 21.0F, 1.4 fiber, 47.3 sugar.
('baby_ruth', 'Baby Ruth Bar', 459, 5.4, 63.0, 21.0,
 1.4, 47.3, 53, 53,
 'ferrero', ARRAY['baby ruth', 'baby ruth bar', 'baby ruth candy bar'],
 'chocolate', 'Ferrero', 1, '459 cal/100g. Per 53g bar: 243 cal. Peanuts, caramel, nougat in milk chocolate.', TRUE),

-- Crunch Bar (Nestle): per 100g: 510 cal, 5.0P, 62.0C, 27.0F, 1.0 fiber, 52.0 sugar.
('nestle_crunch', 'Nestle Crunch Bar', 510, 5.0, 62.0, 27.0,
 1.0, 52.0, 44, 44,
 'nestle', ARRAY['nestle crunch', 'crunch bar', 'nestle crunch bar', 'crunch candy bar'],
 'chocolate', 'Nestle', 1, '510 cal/100g. Per 44g bar: 224 cal. Milk chocolate with crisped rice.', TRUE),

-- Almond Joy: per 100g from USDA: 479 cal, 4.1P, 59.5C, 26.9F, 3.2 fiber, 46.0 sugar.
('almond_joy', 'Almond Joy Candy Bar', 479, 4.1, 59.5, 26.9,
 3.2, 46.0, 45, 45,
 'hersheys', ARRAY['almond joy', 'almond joy bar', 'almond joy candy bar', 'almond joy coconut'],
 'chocolate', 'Hershey''s', 1, '479 cal/100g. Per 45g bar: 216 cal. Coconut, almonds, milk chocolate.', TRUE),

-- Mounds: per 100g from USDA: 486 cal, 4.6P, 58.6C, 27.0F, 3.7 fiber, 45.0 sugar.
('mounds', 'Mounds Dark Chocolate Coconut Bar', 486, 4.6, 58.6, 27.0,
 3.7, 45.0, 49, 24.5,
 'hersheys', ARRAY['mounds', 'mounds bar', 'mounds candy bar', 'mounds dark chocolate coconut'],
 'chocolate', 'Hershey''s', 1, '486 cal/100g. Per 49g pack (2 bars): 238 cal. Coconut filling in dark chocolate.', TRUE),

-- Heath Bar: per 100g: 530 cal, 3.4P, 57.6C, 32.2F, 0.0 fiber, 50.8 sugar.
('heath_bar', 'Heath Milk Chocolate English Toffee Bar', 530, 3.4, 57.6, 32.2,
 0.0, 50.8, 39, 39,
 'hersheys', ARRAY['heath bar', 'heath toffee', 'heath candy bar', 'heath english toffee'],
 'chocolate', 'Hershey''s', 1, '530 cal/100g. Per 39g bar: 207 cal. English toffee covered in milk chocolate.', TRUE),

-- PayDay: per 100g from USDA: 490 cal, 13.4P, 49.1C, 26.5F, 2.7 fiber, 36.5 sugar.
('payday', 'PayDay Peanut Caramel Bar', 490, 13.4, 49.1, 26.5,
 2.7, 36.5, 52, 52,
 'hersheys', ARRAY['payday', 'payday bar', 'payday candy bar', 'pay day peanut caramel'],
 'chocolate', 'Hershey''s', 1, '490 cal/100g. Per 52g bar: 255 cal. Salted peanuts around a caramel center. No chocolate coating.', TRUE),

-- Skor: per 100g from USDA: 541 cal, 3.3P, 54.1C, 34.4F, 0.0 fiber, 52.5 sugar.
('skor', 'Skor Milk Chocolate Butter Toffee Bar', 541, 3.3, 54.1, 34.4,
 0.0, 52.5, 39, 39,
 'hersheys', ARRAY['skor bar', 'skor toffee', 'skor candy bar', 'skor butter toffee'],
 'chocolate', 'Hershey''s', 1, '541 cal/100g. Per 39g bar: 211 cal. Butter toffee in milk chocolate.', TRUE),

-- 100 Grand: per 100g: 476 cal, 3.5P, 64.7C, 22.4F, 0.6 fiber, 52.9 sugar.
('hundred_grand', '100 Grand Bar', 476, 3.5, 64.7, 22.4,
 0.6, 52.9, 43, 43,
 'ferrero', ARRAY['100 grand', '100 grand bar', 'hundred grand bar', '100 grand candy bar'],
 'chocolate', 'Ferrero', 1, '476 cal/100g. Per 43g bar: 205 cal. Caramel, crisped rice, milk chocolate.', TRUE),

-- York Peppermint Patty: per 100g from USDA: 384 cal, 2.2P, 81.0C, 6.9F, 2.2 fiber, 64.0 sugar.
('york_peppermint_patty', 'York Peppermint Pattie', 384, 2.2, 81.0, 6.9,
 2.2, 64.0, 39, 39,
 'hersheys', ARRAY['york peppermint patty', 'york peppermint pattie', 'york patty', 'york dark chocolate peppermint'],
 'chocolate', 'Hershey''s', 1, '384 cal/100g. Per 39g patty: 150 cal. Cool peppermint center in dark chocolate.', TRUE),

-- Take 5: per 100g: 476 cal, 9.5P, 57.1C, 23.8F, 1.9 fiber, 40.5 sugar.
('take_5', 'Reese''s Take 5 Bar', 476, 9.5, 57.1, 23.8,
 1.9, 40.5, 42, 42,
 'hersheys', ARRAY['take 5', 'take five', 'reese''s take 5', 'take5 candy bar'],
 'chocolate', 'Hershey''s', 1, '476 cal/100g. Per 42g bar: 200 cal. 5 layers: pretzels, peanut butter, caramel, peanuts, chocolate.', TRUE),

-- Whatchamacallit: per 100g from USDA: 494 cal, 8.0P, 63.2C, 23.7F, 1.3 fiber, 42.1 sugar.
('whatchamacallit', 'Whatchamacallit Candy Bar', 494, 8.0, 63.2, 23.7,
 1.3, 42.1, 45, 45,
 'hersheys', ARRAY['whatchamacallit', 'whatchamacallit bar', 'whatchamacallit candy'],
 'chocolate', 'Hershey''s', 1, '494 cal/100g. Per 45g bar: 222 cal. Peanut butter crisp, caramel, chocolate.', TRUE),

-- ---- CADBURY ----

-- Cadbury Dairy Milk: per 100g: 534 cal, 7.3P, 57.0C, 30.5F, 0.9 fiber, 55.0 sugar.
('cadbury_dairy_milk', 'Cadbury Dairy Milk Chocolate Bar', 534, 7.3, 57.0, 30.5,
 0.9, 55.0, 45, NULL,
 'cadbury', ARRAY['cadbury dairy milk', 'dairy milk chocolate', 'cadbury milk chocolate', 'cadbury chocolate bar'],
 'chocolate', 'Cadbury', 1, '534 cal/100g. Classic Cadbury milk chocolate. Glass-and-a-half of milk per 200g.', TRUE),

-- Cadbury Fruit & Nut: per 100g: 480 cal, 7.5P, 54.0C, 26.0F, 2.0 fiber, 49.5 sugar.
('cadbury_fruit_nut', 'Cadbury Dairy Milk Fruit & Nut', 480, 7.5, 54.0, 26.0,
 2.0, 49.5, 49, NULL,
 'cadbury', ARRAY['cadbury fruit and nut', 'cadbury fruit & nut', 'dairy milk fruit nut', 'cadbury fruit nut bar'],
 'chocolate', 'Cadbury', 1, '480 cal/100g. Milk chocolate with raisins and almonds.', TRUE),

-- Cadbury Caramello: per 100g: 490 cal, 5.0P, 62.0C, 24.0F, 0.5 fiber, 54.0 sugar.
('cadbury_caramello', 'Cadbury Caramello Bar', 490, 5.0, 62.0, 24.0,
 0.5, 54.0, 45, 45,
 'cadbury', ARRAY['caramello', 'cadbury caramello', 'caramello bar', 'cadbury caramel chocolate'],
 'chocolate', 'Cadbury', 1, '490 cal/100g. Per 45g bar: 220 cal. Creamy caramel in Cadbury milk chocolate.', TRUE),

-- Cadbury Roses: per 100g: 490 cal, 5.5P, 60.0C, 25.0F, 1.0 fiber, 54.0 sugar.
('cadbury_roses', 'Cadbury Roses Chocolates', 490, 5.5, 60.0, 25.0,
 1.0, 54.0, 10, 10,
 'cadbury', ARRAY['cadbury roses', 'roses chocolates', 'cadbury roses box'],
 'chocolate', 'Cadbury', 1, '490 cal/100g. Per piece (~10g): 49 cal. Assorted wrapped chocolate selection.', TRUE),

-- Cadbury Twirl: per 100g: 530 cal, 7.0P, 56.0C, 31.0F, 1.5 fiber, 53.0 sugar.
('cadbury_twirl', 'Cadbury Twirl', 530, 7.0, 56.0, 31.0,
 1.5, 53.0, 43, 21.5,
 'cadbury', ARRAY['cadbury twirl', 'twirl chocolate', 'twirl bar', 'cadbury twirl bar'],
 'chocolate', 'Cadbury', 1, '530 cal/100g. Per 43g pack (2 fingers): 228 cal. Flaked milk chocolate with smooth center.', TRUE),

-- Cadbury Flake: per 100g: 530 cal, 7.5P, 55.5C, 31.5F, 1.0 fiber, 53.5 sugar.
('cadbury_flake', 'Cadbury Flake', 530, 7.5, 55.5, 31.5,
 1.0, 53.5, 32, 32,
 'cadbury', ARRAY['cadbury flake', 'flake bar', 'flake chocolate', 'cadbury flake bar'],
 'chocolate', 'Cadbury', 1, '530 cal/100g. Per 32g bar: 170 cal. Thinly folded layers of Cadbury milk chocolate.', TRUE),

-- ---- LINDT ----

-- Lindt Excellence 70% Cocoa: per 100g: 550 cal, 9.2P, 34.0C, 41.0F, 11.0 fiber, 24.0 sugar.
('lindt_70_dark', 'Lindt Excellence 70% Cocoa Dark Chocolate', 550, 9.2, 34.0, 41.0,
 11.0, 24.0, 40, NULL,
 'lindt', ARRAY['lindt 70%', 'lindt excellence 70', 'lindt dark chocolate 70%', 'lindt excellence dark 70'],
 'chocolate', 'Lindt', 1, '550 cal/100g. High-cacao dark chocolate. 11g fiber per 100g from cocoa.', TRUE),

-- Lindt Excellence 85% Cocoa: per 100g: 600 cal, 12.5P, 20.0C, 50.0F, 14.0 fiber, 12.0 sugar.
('lindt_85_dark', 'Lindt Excellence 85% Cocoa Dark Chocolate', 600, 12.5, 20.0, 50.0,
 14.0, 12.0, 40, NULL,
 'lindt', ARRAY['lindt 85%', 'lindt excellence 85', 'lindt dark chocolate 85%', 'lindt excellence dark 85'],
 'chocolate', 'Lindt', 1, '600 cal/100g. Extra dark chocolate. Very low sugar (12g/100g), high fiber from cocoa.', TRUE),

-- Lindt Lindor Truffles (Milk): per 100g: 600 cal, 6.2P, 47.0C, 43.0F, 1.5 fiber, 43.0 sugar.
('lindt_lindor_truffles', 'Lindt Lindor Milk Chocolate Truffles', 600, 6.2, 47.0, 43.0,
 1.5, 43.0, 36, 12.0,
 'lindt', ARRAY['lindor truffles', 'lindt lindor', 'lindor milk chocolate', 'lindt truffles'],
 'chocolate', 'Lindt', 3, '600 cal/100g. Per piece (12g): 72 cal. Smooth melting milk chocolate shell with truffle center.', TRUE),

-- Lindt Swiss Classic Milk: per 100g: 540 cal, 6.5P, 55.0C, 33.0F, 1.0 fiber, 52.0 sugar.
('lindt_swiss_classic', 'Lindt Swiss Classic Milk Chocolate', 540, 6.5, 55.0, 33.0,
 1.0, 52.0, 100, NULL,
 'lindt', ARRAY['lindt swiss classic', 'lindt milk chocolate', 'lindt classic milk chocolate'],
 'chocolate', 'Lindt', 1, '540 cal/100g. Premium Swiss milk chocolate with fine cocoa.', TRUE),

-- ---- FERRERO ----

-- Ferrero Rocher: per 100g: 600 cal, 8.0P, 48.0C, 42.0F, 2.0 fiber, 40.0 sugar.
('ferrero_rocher', 'Ferrero Rocher Hazelnut Chocolates', 600, 8.0, 48.0, 42.0,
 2.0, 40.0, 37.5, 12.5,
 'ferrero', ARRAY['ferrero rocher', 'ferrero rocher chocolates', 'rocher chocolate', 'ferrero rocher hazelnut'],
 'chocolate', 'Ferrero', 3, '600 cal/100g. Per piece (12.5g): 75 cal. Whole hazelnut in wafer shell with chocolate and hazelnuts.', TRUE),

-- Raffaello: per 100g: 627 cal, 7.4P, 38.6C, 48.3F, 2.5 fiber, 33.6 sugar.
('raffaello', 'Ferrero Raffaello Almond Coconut', 627, 7.4, 38.6, 48.3,
 2.5, 33.6, 30, 10,
 'ferrero', ARRAY['raffaello', 'ferrero raffaello', 'raffaello coconut', 'raffaello almond coconut'],
 'chocolate', 'Ferrero', 3, '627 cal/100g. Per piece (10g): 63 cal. Coconut and almond confection.', TRUE),

-- Kinder Bueno: per 100g: 567 cal, 8.4P, 49.3C, 37.2F, 1.0 fiber, 41.0 sugar.
('kinder_bueno', 'Kinder Bueno', 567, 8.4, 49.3, 37.2,
 1.0, 41.0, 43, 21.5,
 'ferrero', ARRAY['kinder bueno', 'kinder bueno bar', 'kinder bueno chocolate', 'bueno bar'],
 'chocolate', 'Ferrero', 1, '567 cal/100g. Per 43g pack (2 bars): 244 cal. Crispy wafer with hazelnut cream filling in milk chocolate.', TRUE),

-- Kinder Joy: per 100g: 545 cal, 8.0P, 47.0C, 36.5F, 0.5 fiber, 43.0 sugar.
('kinder_joy', 'Kinder Joy Egg', 545, 8.0, 47.0, 36.5,
 0.5, 43.0, 20, 20,
 'ferrero', ARRAY['kinder joy', 'kinder egg', 'kinder joy egg', 'kinder surprise egg'],
 'chocolate', 'Ferrero', 1, '545 cal/100g. Per egg (20g): 109 cal. Cocoa and milk cream with wafer bites. Includes toy.', TRUE),

-- Kinder Happy Hippo: per 100g: 570 cal, 7.0P, 52.0C, 37.0F, 1.0 fiber, 41.0 sugar.
('kinder_happy_hippo', 'Kinder Happy Hippo Cocoa', 570, 7.0, 52.0, 37.0,
 1.0, 41.0, 21, 21,
 'ferrero', ARRAY['kinder happy hippo', 'happy hippo', 'kinder hippo cocoa'],
 'chocolate', 'Ferrero', 1, '570 cal/100g. Per piece (21g): 120 cal. Crispy wafer biscuit with cocoa and milk filling.', TRUE),

-- ---- GHIRARDELLI ----

-- Ghirardelli Intense Dark 72%: per 100g: 560 cal, 7.5P, 40.0C, 42.0F, 10.0 fiber, 27.0 sugar.
('ghirardelli_intense_dark', 'Ghirardelli Intense Dark Chocolate Squares 72% Cacao', 560, 7.5, 40.0, 42.0,
 10.0, 27.0, 43, 10.6,
 'ghirardelli', ARRAY['ghirardelli dark chocolate', 'ghirardelli intense dark', 'ghirardelli 72%', 'ghirardelli dark squares'],
 'chocolate', 'Ghirardelli', 4, '560 cal/100g. Per square (10.6g): 59 cal. Premium American dark chocolate.', TRUE),

-- Ghirardelli Milk Chocolate Caramel Squares: per 100g: 467 cal, 5.0P, 55.5C, 25.0F, 0.5 fiber, 48.0 sugar.
('ghirardelli_milk_caramel', 'Ghirardelli Milk Chocolate Caramel Squares', 467, 5.0, 55.5, 25.0,
 0.5, 48.0, 43, 10.6,
 'ghirardelli', ARRAY['ghirardelli milk chocolate caramel', 'ghirardelli caramel squares', 'ghirardelli caramel milk chocolate'],
 'chocolate', 'Ghirardelli', 4, '467 cal/100g. Per square (10.6g): 50 cal. Milk chocolate with liquid caramel filling.', TRUE),

-- ---- TOBLERONE / MILKA / RITTER SPORT ----

-- Toblerone Milk Chocolate: per 100g: 545 cal, 6.5P, 57.0C, 33.0F, 1.0 fiber, 55.0 sugar.
('toblerone', 'Toblerone Swiss Milk Chocolate', 545, 6.5, 57.0, 33.0,
 1.0, 55.0, 35, NULL,
 'toblerone', ARRAY['toblerone', 'toblerone milk chocolate', 'toblerone bar', 'toblerone swiss chocolate'],
 'chocolate', 'Toblerone', 1, '545 cal/100g. Distinctive triangular bar with honey & almond nougat. Swiss-made.', TRUE),

-- Milka Alpine Milk: per 100g: 530 cal, 6.6P, 58.5C, 30.0F, 0.8 fiber, 56.5 sugar.
('milka_alpine_milk', 'Milka Alpine Milk Chocolate', 530, 6.6, 58.5, 30.0,
 0.8, 56.5, 100, NULL,
 'milka', ARRAY['milka', 'milka alpine milk', 'milka chocolate', 'milka milk chocolate'],
 'chocolate', 'Milka', 1, '530 cal/100g. Made with Alpine milk. Distinctively smooth and creamy.', TRUE),

-- Milka Oreo: per 100g: 520 cal, 5.8P, 60.5C, 28.5F, 1.0 fiber, 52.0 sugar.
('milka_oreo', 'Milka Oreo Chocolate Bar', 520, 5.8, 60.5, 28.5,
 1.0, 52.0, 100, NULL,
 'milka', ARRAY['milka oreo', 'milka oreo bar', 'milka with oreo', 'milka oreo chocolate'],
 'chocolate', 'Milka', 1, '520 cal/100g. Milka milk chocolate with Oreo cookie pieces and vanilla creme filling.', TRUE),

-- Ritter Sport Milk Chocolate: per 100g: 553 cal, 7.0P, 55.0C, 33.0F, 1.0 fiber, 53.0 sugar.
('ritter_sport', 'Ritter Sport Milk Chocolate', 553, 7.0, 55.0, 33.0,
 1.0, 53.0, 100, NULL,
 'ritter_sport', ARRAY['ritter sport', 'ritter sport milk chocolate', 'ritter sport chocolate', 'ritter sport bar'],
 'chocolate', 'Ritter Sport', 1, '553 cal/100g. 100g square bar. Quality chocolate from Stuttgart, Germany.', TRUE),

-- ---- GODIVA ----

-- Godiva Masterpieces Milk Chocolate: per 100g: 524 cal, 6.5P, 54.0C, 32.0F, 1.5 fiber, 50.0 sugar.
('godiva_masterpieces', 'Godiva Masterpieces Milk Chocolate', 524, 6.5, 54.0, 32.0,
 1.5, 50.0, 30, 10,
 'godiva', ARRAY['godiva masterpieces', 'godiva chocolate', 'godiva milk chocolate', 'godiva masterpieces chocolate'],
 'chocolate', 'Godiva', 3, '524 cal/100g. Per piece (10g): 52 cal. Premium Belgian chocolate.', TRUE),

-- Godiva Dark Chocolate Bar: per 100g: 545 cal, 7.0P, 42.0C, 39.0F, 7.0 fiber, 33.0 sugar.
('godiva_dark', 'Godiva Dark Chocolate Bar', 545, 7.0, 42.0, 39.0,
 7.0, 33.0, 43, NULL,
 'godiva', ARRAY['godiva dark chocolate', 'godiva dark bar', 'godiva dark chocolate bar'],
 'chocolate', 'Godiva', 1, '545 cal/100g. Premium Belgian dark chocolate.', TRUE),

-- ---- TONY'S CHOCOLONELY ----

-- Tony's Chocolonely Milk: per 100g: 530 cal, 7.0P, 55.0C, 31.0F, 1.0 fiber, 52.0 sugar.
('tonys_chocolonely_milk', 'Tony''s Chocolonely Milk Chocolate', 530, 7.0, 55.0, 31.0,
 1.0, 52.0, 180, NULL,
 'tonys_chocolonely', ARRAY['tony''s chocolonely', 'tonys chocolonely milk', 'tony''s chocolonely milk chocolate'],
 'chocolate', 'Tony''s Chocolonely', 1, '530 cal/100g. Fairtrade milk chocolate. Unequally divided bar for slave-free chocolate awareness.', TRUE),

-- Tony's Chocolonely Dark 70%: per 100g: 545 cal, 8.0P, 38.0C, 40.0F, 9.0 fiber, 27.0 sugar.
('tonys_chocolonely_dark', 'Tony''s Chocolonely Dark Chocolate 70%', 545, 8.0, 38.0, 40.0,
 9.0, 27.0, 180, NULL,
 'tonys_chocolonely', ARRAY['tony''s chocolonely dark', 'tonys chocolonely dark 70', 'tony''s chocolonely dark chocolate'],
 'chocolate', 'Tony''s Chocolonely', 1, '545 cal/100g. Fairtrade dark chocolate 70% cacao.', TRUE),

-- Tony's Chocolonely Caramel Sea Salt: per 100g: 533 cal, 7.0P, 53.0C, 33.0F, 1.0 fiber, 49.0 sugar.
('tonys_chocolonely_caramel', 'Tony''s Chocolonely Milk Caramel Sea Salt', 533, 7.0, 53.0, 33.0,
 1.0, 49.0, 180, NULL,
 'tonys_chocolonely', ARRAY['tony''s chocolonely caramel sea salt', 'tonys chocolonely caramel', 'tony''s caramel sea salt'],
 'chocolate', 'Tony''s Chocolonely', 1, '533 cal/100g. Fairtrade milk chocolate with caramel pieces and sea salt.', TRUE),

-- ---- DUBAI / SPECIALTY CHOCOLATE ----

-- Dubai Chocolate (FIX Kunafa Pistachio): per 100g: 579 cal, 12.5P, 40.7C, 41.3F, 3.0 fiber, 29.7 sugar.
('dubai_chocolate_kunafa', 'Dubai Chocolate Kunafa Pistachio (FIX)', 579, 12.5, 40.7, 41.3,
 3.0, 29.7, 100, NULL,
 'fix_dessert', ARRAY['dubai chocolate', 'fix chocolate', 'kunafa pistachio chocolate', 'fix kunafa', 'dubai kunafa chocolate', 'viral dubai chocolate'],
 'chocolate', 'FIX Dessert Chocolatier', 1, '579 cal/100g. Viral Dubai chocolate with tahini-pistachio filling, crispy kataifi pastry, Belgian chocolate shell.', TRUE),

-- Lotus Biscoff Chocolate: per 100g: 570 cal, 5.5P, 55.0C, 36.0F, 1.0 fiber, 48.0 sugar.
('lotus_biscoff_chocolate', 'Lotus Biscoff Chocolate Bar', 570, 5.5, 55.0, 36.0,
 1.0, 48.0, 150, NULL,
 'lotus', ARRAY['lotus biscoff chocolate', 'biscoff chocolate', 'lotus chocolate bar', 'biscoff chocolate bar'],
 'chocolate', 'Lotus', 1, '570 cal/100g. Belgian milk chocolate filled with Biscoff speculoos biscuit pieces.', TRUE),

-- ---- AFTER EIGHT / TERRY'S / OTHERS ----

-- After Eight: per 100g: 410 cal, 2.0P, 73.0C, 12.0F, 3.0 fiber, 65.0 sugar.
('after_eight', 'After Eight Thin Mints', 410, 2.0, 73.0, 12.0,
 3.0, 65.0, 8, 8,
 'nestle', ARRAY['after eight', 'after eight mints', 'after eight thin mints', 'after eight chocolate mints'],
 'chocolate', 'Nestle', 1, '410 cal/100g. Per piece (8g): 33 cal. Peppermint fondant in dark chocolate.', TRUE),

-- Terry's Chocolate Orange: per 100g: 530 cal, 5.5P, 58.0C, 31.0F, 2.0 fiber, 54.0 sugar.
('terrys_chocolate_orange', 'Terry''s Chocolate Orange', 530, 5.5, 58.0, 31.0,
 2.0, 54.0, 175, 8,
 'terrys', ARRAY['terry''s chocolate orange', 'terrys chocolate orange', 'chocolate orange', 'terry''s orange'],
 'chocolate', 'Terry''s', 1, '530 cal/100g. Per segment (~8g): 42 cal. Orange-flavored milk chocolate ball shaped like an orange.', TRUE),

-- Lion Bar: per 100g: 489 cal, 5.0P, 63.0C, 24.0F, 1.0 fiber, 47.0 sugar.
('lion_bar', 'Lion Bar', 489, 5.0, 63.0, 24.0,
 1.0, 47.0, 42, 42,
 'nestle', ARRAY['lion bar', 'nestle lion bar', 'lion candy bar', 'lion chocolate bar'],
 'chocolate', 'Nestle', 1, '489 cal/100g. Per 42g bar: 205 cal. Wafer, caramel, puffed rice in milk chocolate.', TRUE),

-- Aero: per 100g: 530 cal, 7.0P, 57.0C, 30.0F, 1.0 fiber, 53.0 sugar.
('aero', 'Aero Milk Chocolate Bar', 530, 7.0, 57.0, 30.0,
 1.0, 53.0, 36, NULL,
 'nestle', ARRAY['aero bar', 'aero chocolate', 'aero milk chocolate', 'nestle aero'],
 'chocolate', 'Nestle', 1, '530 cal/100g. Per 36g bar: 191 cal. Bubbly-textured aerated milk chocolate.', TRUE),

-- Smarties (Nestle): per 100g: 475 cal, 4.5P, 67.0C, 21.0F, 1.0 fiber, 63.0 sugar.
('nestle_smarties', 'Nestle Smarties', 475, 4.5, 67.0, 21.0,
 1.0, 63.0, 38, NULL,
 'nestle', ARRAY['smarties', 'nestle smarties', 'smarties candy', 'smarties chocolate'],
 'chocolate', 'Nestle', 1, '475 cal/100g. Per 38g tube: 180 cal. Candy-coated milk chocolate drops.', TRUE),

-- Brookside Dark Choc Acai: per 100g: 425 cal, 4.0P, 64.0C, 18.0F, 4.0 fiber, 48.0 sugar.
('brookside_acai', 'Brookside Dark Chocolate Acai & Blueberry', 425, 4.0, 64.0, 18.0,
 4.0, 48.0, 40, NULL,
 'brookside', ARRAY['brookside acai', 'brookside dark chocolate acai', 'brookside blueberry', 'brookside dark chocolate acai blueberry'],
 'chocolate', 'Brookside', 1, '425 cal/100g. Dark chocolate covered acai and blueberry flavored fruit center.', TRUE),

-- Brookside Pomegranate: per 100g: 425 cal, 4.0P, 64.0C, 18.0F, 4.0 fiber, 47.0 sugar.
('brookside_pomegranate', 'Brookside Dark Chocolate Pomegranate', 425, 4.0, 64.0, 18.0,
 4.0, 47.0, 40, NULL,
 'brookside', ARRAY['brookside pomegranate', 'brookside dark chocolate pomegranate', 'brookside pom'],
 'chocolate', 'Brookside', 1, '425 cal/100g. Dark chocolate covered pomegranate flavored fruit center.', TRUE),

-- Quality Street (per 100g average): per 100g: 470 cal, 3.5P, 63.0C, 23.0F, 0.5 fiber, 55.0 sugar.
('quality_street', 'Quality Street Chocolates', 470, 3.5, 63.0, 23.0,
 0.5, 55.0, 10, 10,
 'nestle', ARRAY['quality street', 'quality street chocolates', 'nestle quality street', 'quality street box'],
 'chocolate', 'Nestle', 1, '470 cal/100g. Per piece (~10g): 47 cal. Assorted filled chocolates and toffees.', TRUE),

-- Celebrations (per 100g average): per 100g: 490 cal, 5.0P, 60.0C, 25.0F, 1.0 fiber, 52.0 sugar.
('celebrations', 'Mars Celebrations', 490, 5.0, 60.0, 25.0,
 1.0, 52.0, 13, 13,
 'mars', ARRAY['celebrations', 'mars celebrations', 'celebrations box', 'celebrations chocolates'],
 'chocolate', 'Mars', 1, '490 cal/100g. Per piece (~13g): 64 cal. Assorted miniature Mars, Snickers, Twix, Bounty, etc.', TRUE),

-- ==========================================
-- B. BRANDED NUT PRODUCTS (~25 items)
-- ==========================================

-- Planters Honey Roasted Peanuts: per 100g: 571 cal, 21.4P, 28.6C, 42.9F, 7.1 fiber, 17.9 sugar.
('planters_honey_roasted_peanuts', 'Planters Honey Roasted Peanuts', 571, 21.4, 28.6, 42.9,
 7.1, 17.9, 28, NULL,
 'planters', ARRAY['planters honey roasted peanuts', 'honey roasted peanuts', 'planters honey peanuts'],
 'nuts_seeds', 'Planters', 1, '571 cal/100g. Per 28g: 160 cal. Honey roasted peanuts with sea salt.', TRUE),

-- Planters Cashew Halves: per 100g: 571 cal, 17.9P, 28.6C, 46.4F, 3.6 fiber, 3.6 sugar.
('planters_cashew_halves', 'Planters Cashew Halves & Pieces', 571, 17.9, 28.6, 46.4,
 3.6, 3.6, 28, NULL,
 'planters', ARRAY['planters cashews', 'planters cashew halves', 'planters cashew halves and pieces'],
 'nuts_seeds', 'Planters', 1, '571 cal/100g. Per 28g: 160 cal. Lightly salted cashew halves and pieces.', TRUE),

-- Planters Deluxe Mixed Nuts: per 100g: 607 cal, 17.9P, 21.4C, 53.6F, 3.6 fiber, 3.6 sugar.
('planters_deluxe_mixed', 'Planters Deluxe Mixed Nuts', 607, 17.9, 21.4, 53.6,
 3.6, 3.6, 28, NULL,
 'planters', ARRAY['planters deluxe mixed nuts', 'planters mixed nuts', 'planters deluxe nuts'],
 'nuts_seeds', 'Planters', 1, '607 cal/100g. Per 28g: 170 cal. Cashews, almonds, pecans, pistachios, macadamias.', TRUE),

-- Planters Cocktail Peanuts: per 100g: 607 cal, 25.0P, 14.3C, 53.6F, 7.1 fiber, 3.6 sugar.
('planters_cocktail_peanuts', 'Planters Cocktail Peanuts', 607, 25.0, 14.3, 53.6,
 7.1, 3.6, 28, NULL,
 'planters', ARRAY['planters cocktail peanuts', 'planters peanuts', 'planters salted peanuts'],
 'nuts_seeds', 'Planters', 1, '607 cal/100g. Per 28g: 170 cal. Lightly salted roasted peanuts.', TRUE),

-- Planters Dry Roasted Peanuts: per 100g: 585 cal, 24.4P, 21.5C, 49.7F, 8.0 fiber, 4.2 sugar.
('planters_dry_roasted', 'Planters Dry Roasted Peanuts', 585, 24.4, 21.5, 49.7,
 8.0, 4.2, 28, NULL,
 'planters', ARRAY['planters dry roasted', 'planters dry roasted peanuts', 'dry roasted peanuts planters'],
 'nuts_seeds', 'Planters', 1, '585 cal/100g. Per 28g: 164 cal. Dry roasted with sea salt.', TRUE),

-- Blue Diamond Smokehouse Almonds: per 100g: 607 cal, 21.4P, 17.9C, 53.6F, 10.7 fiber, 3.6 sugar.
('blue_diamond_smokehouse', 'Blue Diamond Smokehouse Almonds', 607, 21.4, 17.9, 53.6,
 10.7, 3.6, 28, NULL,
 'blue_diamond', ARRAY['blue diamond smokehouse', 'smokehouse almonds', 'blue diamond almonds smokehouse'],
 'nuts_seeds', 'Blue Diamond', 1, '607 cal/100g. Per 28g: 170 cal. Bold smoky flavor roasted almonds.', TRUE),

-- Blue Diamond Wasabi & Soy Sauce: per 100g: 571 cal, 21.4P, 21.4C, 50.0F, 10.7 fiber, 3.6 sugar.
('blue_diamond_wasabi', 'Blue Diamond Wasabi & Soy Sauce Almonds', 571, 21.4, 21.4, 50.0,
 10.7, 3.6, 28, NULL,
 'blue_diamond', ARRAY['blue diamond wasabi', 'wasabi almonds', 'blue diamond wasabi soy sauce', 'wasabi soy sauce almonds'],
 'nuts_seeds', 'Blue Diamond', 1, '571 cal/100g. Per 28g: 160 cal. Almonds with wasabi and soy sauce seasoning.', TRUE),

-- Blue Diamond Honey Roasted: per 100g: 571 cal, 17.9P, 28.6C, 46.4F, 7.1 fiber, 14.3 sugar.
('blue_diamond_honey_roasted', 'Blue Diamond Honey Roasted Almonds', 571, 17.9, 28.6, 46.4,
 7.1, 14.3, 28, NULL,
 'blue_diamond', ARRAY['blue diamond honey roasted', 'honey roasted almonds', 'blue diamond honey almonds'],
 'nuts_seeds', 'Blue Diamond', 1, '571 cal/100g. Per 28g: 160 cal. Almonds with sweet honey roasted coating.', TRUE),

-- Blue Diamond Bold Sriracha: per 100g: 571 cal, 21.4P, 21.4C, 50.0F, 10.7 fiber, 3.6 sugar.
('blue_diamond_sriracha', 'Blue Diamond Bold Sriracha Almonds', 571, 21.4, 21.4, 50.0,
 10.7, 3.6, 28, NULL,
 'blue_diamond', ARRAY['blue diamond sriracha', 'sriracha almonds', 'blue diamond bold sriracha'],
 'nuts_seeds', 'Blue Diamond', 1, '571 cal/100g. Per 28g: 160 cal. Almonds with bold sriracha seasoning.', TRUE),

-- Wonderful Pistachios Roasted & Salted: per 100g: 571 cal, 21.0P, 29.0C, 46.0F, 10.0 fiber, 7.0 sugar.
('wonderful_pistachios', 'Wonderful Pistachios Roasted & Salted', 571, 21.0, 29.0, 46.0,
 10.0, 7.0, 30, NULL,
 'wonderful', ARRAY['wonderful pistachios', 'pistachios roasted salted', 'wonderful pistachios roasted'],
 'nuts_seeds', 'Wonderful', 1, '571 cal/100g. In-shell pistachios. ~50% of weight is shell.', TRUE),

-- Wonderful Pistachios No Shell: per 100g: 591 cal, 24.0P, 19.0C, 48.0F, 10.0 fiber, 7.0 sugar.
('wonderful_pistachios_no_shell', 'Wonderful Pistachios No Shells', 591, 24.0, 19.0, 48.0,
 10.0, 7.0, 28, NULL,
 'wonderful', ARRAY['wonderful pistachios no shells', 'pistachios no shell', 'shelled pistachios wonderful'],
 'nuts_seeds', 'Wonderful', 1, '591 cal/100g. Per 28g: 165 cal. Shelled pistachios for easy snacking.', TRUE),

-- Wonderful Pistachios Chili Roasted: per 100g: 571 cal, 21.0P, 28.0C, 46.0F, 10.0 fiber, 7.0 sugar.
('wonderful_pistachios_chili', 'Wonderful Pistachios Chili Roasted', 571, 21.0, 28.0, 46.0,
 10.0, 7.0, 28, NULL,
 'wonderful', ARRAY['wonderful pistachios chili', 'chili roasted pistachios', 'wonderful chili pistachios'],
 'nuts_seeds', 'Wonderful', 1, '571 cal/100g. Per 28g: 160 cal. Bold chili roasted pistachios.', TRUE),

-- Sahale Glazed Mix: per 100g: 464 cal, 14.3P, 39.3C, 28.6F, 3.6 fiber, 21.4 sugar.
('sahale_glazed_mix', 'Sahale Snacks Glazed Mix', 464, 14.3, 39.3, 28.6,
 3.6, 21.4, 28, NULL,
 'sahale', ARRAY['sahale glazed mix', 'sahale snacks', 'sahale glazed nuts', 'sahale nut mix'],
 'nuts_seeds', 'Sahale', 1, '464 cal/100g. Per 28g: 130 cal. Premium glazed nut and fruit mix.', TRUE),

-- Emerald 100 Calorie Pack Almonds: per 100g: 571 cal, 21.4P, 21.4C, 46.4F, 10.7 fiber, 3.6 sugar.
('emerald_100_cal_almonds', 'Emerald 100 Calorie Pack Almonds', 571, 21.4, 21.4, 46.4,
 10.7, 3.6, 18, NULL,
 'emerald', ARRAY['emerald 100 calorie pack', 'emerald almonds 100 cal', 'emerald 100 cal almonds'],
 'nuts_seeds', 'Emerald', 1, '571 cal/100g. Per 18g pack: 100 cal. Portion-controlled almond packs.', TRUE),

-- ==========================================
-- C. BRANDED PORK RINDS (~8 items)
-- ==========================================

-- Epic Sea Salt Pepper Pork Rinds: per 100g: 571 cal, 57.1P, 0.0C, 35.7F, 0.0 fiber, 0.0 sugar.
('epic_sea_salt_pepper', 'Epic Sea Salt & Pepper Pork Rinds', 571, 57.1, 0.0, 35.7,
 0.0, 0.0, 28, NULL,
 'epic', ARRAY['epic pork rinds sea salt pepper', 'epic sea salt pepper', 'epic pork rinds'],
 'pork_rinds', 'Epic', 1, '571 cal/100g. Per 28g: 160 cal. Oven-baked pork rinds. Zero carb, high protein.', TRUE),

-- Epic Pink Himalayan Salt: per 100g: 571 cal, 57.1P, 0.0C, 35.7F, 0.0 fiber, 0.0 sugar.
('epic_himalayan_salt', 'Epic Pink Himalayan Salt Pork Rinds', 571, 57.1, 0.0, 35.7,
 0.0, 0.0, 28, NULL,
 'epic', ARRAY['epic himalayan salt pork rinds', 'epic pink salt', 'epic himalayan pork rinds'],
 'pork_rinds', 'Epic', 1, '571 cal/100g. Per 28g: 160 cal. Oven-baked with pink Himalayan salt. Zero carb.', TRUE),

-- Epic BBQ Pork Rinds: per 100g: 571 cal, 53.6P, 3.6C, 35.7F, 0.0 fiber, 3.6 sugar.
('epic_bbq', 'Epic BBQ Seasoned Pork Rinds', 571, 53.6, 3.6, 35.7,
 0.0, 3.6, 28, NULL,
 'epic', ARRAY['epic bbq pork rinds', 'epic bbq', 'epic barbecue pork rinds'],
 'pork_rinds', 'Epic', 1, '571 cal/100g. Per 28g: 160 cal. Oven-baked with BBQ seasoning.', TRUE),

-- Epic Chili Lime: per 100g: 571 cal, 53.6P, 3.6C, 35.7F, 0.0 fiber, 0.0 sugar.
('epic_chili_lime', 'Epic Chili Lime Pork Rinds', 571, 53.6, 3.6, 35.7,
 0.0, 0.0, 28, NULL,
 'epic', ARRAY['epic chili lime pork rinds', 'epic chili lime', 'epic lime pork rinds'],
 'pork_rinds', 'Epic', 1, '571 cal/100g. Per 28g: 160 cal. Oven-baked with chili lime seasoning.', TRUE),

-- Baken-ets Traditional: per 100g: 544 cal, 61.0P, 0.0C, 32.0F, 0.0 fiber, 0.0 sugar.
('bakenets_traditional', 'Baken-ets Traditional Fried Pork Skins', 544, 61.0, 0.0, 32.0,
 0.0, 0.0, 14, NULL,
 'bakenets', ARRAY['baken-ets', 'bakenets', 'baken-ets traditional', 'baken-ets pork rinds', 'baken ets fried pork skins'],
 'pork_rinds', 'Baken-ets', 1, '544 cal/100g. Per 14g (9 pieces): 80 cal. Classic fried pork skins. Zero carb.', TRUE),

-- Baken-ets Hot 'n Spicy: per 100g: 544 cal, 57.1P, 3.6C, 32.1F, 0.0 fiber, 0.0 sugar.
('bakenets_hot_spicy', 'Baken-ets Hot ''N Spicy Chicharrones', 544, 57.1, 3.6, 32.1,
 0.0, 0.0, 14, NULL,
 'bakenets', ARRAY['baken-ets hot n spicy', 'bakenets hot spicy', 'hot cheetos pork rinds', 'baken-ets hot and spicy'],
 'pork_rinds', 'Baken-ets', 1, '544 cal/100g. Per 14g: 80 cal. Hot and spicy flavored fried pork skins.', TRUE),

-- Baken-ets Chicharrones: per 100g: 544 cal, 61.0P, 0.0C, 32.0F, 0.0 fiber, 0.0 sugar.
('bakenets_chicharrones', 'Baken-ets Chicharrones', 544, 61.0, 0.0, 32.0,
 0.0, 0.0, 14, NULL,
 'bakenets', ARRAY['baken-ets chicharrones', 'bakenets chicharrones', 'chicharrones baken-ets'],
 'pork_rinds', 'Baken-ets', 1, '544 cal/100g. Per 14g: 80 cal. Classic chicharrones (fried pork skins).', TRUE),

-- 4505 Classic Chicharrones: per 100g: 571 cal, 57.1P, 0.0C, 39.3F, 0.0 fiber, 0.0 sugar.
('4505_classic_chicharrones', '4505 Meats Classic Chicharrones', 571, 57.1, 0.0, 39.3,
 0.0, 0.0, 28, NULL,
 '4505_meats', ARRAY['4505 chicharrones', '4505 meats chicharrones', '4505 pork rinds', '4505 classic chicharrones'],
 'pork_rinds', '4505 Meats', 1, '571 cal/100g. Per 28g: 160 cal. Premium fried pork rinds. Keto-friendly, zero carb.', TRUE),

-- ==========================================
-- D. HONEY & SYRUPS (~10 items)
-- ==========================================

-- Manuka Honey UMF 10+: per 100g: 328 cal, 0.3P, 82.0C, 0.0F, 0.0 fiber, 78.0 sugar.
('manuka_honey', 'Manuka Honey UMF 10+', 328, 0.3, 82.0, 0.0,
 0.0, 78.0, 21, NULL,
 'generic', ARRAY['manuka honey', 'manuka honey umf 10', 'new zealand manuka honey', 'umf manuka honey'],
 'honey_syrups', NULL, 1, '328 cal/100g. Per tbsp (21g): 69 cal. New Zealand origin, antibacterial properties.', TRUE),

-- Raw Unfiltered Honey: per 100g: 304 cal, 0.3P, 82.4C, 0.0F, 0.2 fiber, 82.1 sugar.
('raw_honey', 'Raw Unfiltered Honey', 304, 0.3, 82.4, 0.0,
 0.2, 82.1, 21, NULL,
 'usda', ARRAY['raw honey', 'unfiltered honey', 'pure honey', 'raw unfiltered honey', 'natural honey'],
 'honey_syrups', NULL, 1, '304 cal/100g. Per tbsp (21g): 64 cal. Unpasteurized with pollen and enzymes intact.', TRUE),

-- Wildflower Honey: per 100g: 304 cal, 0.3P, 82.4C, 0.0F, 0.2 fiber, 82.1 sugar.
('wildflower_honey', 'Wildflower Honey', 304, 0.3, 82.4, 0.0,
 0.2, 82.1, 21, NULL,
 'usda', ARRAY['wildflower honey', 'multi-floral honey', 'polyfloral honey'],
 'honey_syrups', NULL, 1, '304 cal/100g. Per tbsp (21g): 64 cal. Multi-floral honey with complex flavor profile.', TRUE),

-- Buckwheat Honey: per 100g: 304 cal, 0.3P, 82.4C, 0.0F, 0.0 fiber, 82.0 sugar.
('buckwheat_honey', 'Buckwheat Honey', 304, 0.3, 82.4, 0.0,
 0.0, 82.0, 21, NULL,
 'usda', ARRAY['buckwheat honey', 'dark buckwheat honey'],
 'honey_syrups', NULL, 1, '304 cal/100g. Per tbsp (21g): 64 cal. Dark, robust flavor. Higher antioxidant content than lighter honeys.', TRUE),

-- Agave Nectar Light: per 100g: 310 cal, 0.0P, 76.4C, 0.0F, 0.2 fiber, 68.0 sugar.
('agave_nectar_light', 'Agave Nectar (Light)', 310, 0.0, 76.4, 0.0,
 0.2, 68.0, 21, NULL,
 'usda', ARRAY['agave nectar', 'light agave', 'agave syrup', 'agave nectar light'],
 'honey_syrups', NULL, 1, '310 cal/100g. Per tbsp (21g): 65 cal. High fructose (~90%). Mild, neutral sweetener.', TRUE),

-- Agave Nectar Dark: per 100g: 310 cal, 0.0P, 76.4C, 0.0F, 0.2 fiber, 68.0 sugar.
('agave_nectar_dark', 'Agave Nectar (Dark)', 310, 0.0, 76.4, 0.0,
 0.2, 68.0, 21, NULL,
 'usda', ARRAY['dark agave', 'dark agave nectar', 'amber agave syrup'],
 'honey_syrups', NULL, 1, '310 cal/100g. Per tbsp (21g): 65 cal. Stronger, more caramel-like flavor than light agave.', TRUE),

-- Maple Syrup Grade A: per 100g: 260 cal, 0.0P, 67.0C, 0.1F, 0.0 fiber, 60.0 sugar.
('maple_syrup', 'Maple Syrup Grade A', 260, 0.0, 67.0, 0.1,
 0.0, 60.0, 30, NULL,
 'usda', ARRAY['maple syrup', 'pure maple syrup', 'grade a maple syrup', 'real maple syrup'],
 'honey_syrups', NULL, 1, '260 cal/100g. Per tbsp (30g): 78 cal. Contains manganese and zinc. Lower GI than table sugar.', TRUE),

-- Molasses: per 100g: 290 cal, 0.0P, 74.7C, 0.0F, 0.0 fiber, 74.7 sugar.
('molasses', 'Molasses', 290, 0.0, 74.7, 0.0,
 0.0, 74.7, 20, NULL,
 'usda', ARRAY['molasses', 'blackstrap molasses', 'dark molasses'],
 'honey_syrups', NULL, 1, '290 cal/100g. Per tbsp (20g): 58 cal. Rich in iron, calcium, magnesium. Byproduct of sugar refining.', TRUE),

-- Date Syrup: per 100g: 293 cal, 1.8P, 72.0C, 0.2F, 3.5 fiber, 63.0 sugar.
('date_syrup', 'Date Syrup', 293, 1.8, 72.0, 0.2,
 3.5, 63.0, 21, NULL,
 'generic', ARRAY['date syrup', 'date molasses', 'silan', 'date honey'],
 'honey_syrups', NULL, 1, '293 cal/100g. Per tbsp (21g): 62 cal. Made from dates. Contains potassium and fiber.', TRUE),

-- Golden Syrup (Lyle's): per 100g: 325 cal, 0.0P, 79.0C, 0.0F, 0.0 fiber, 79.0 sugar.
('golden_syrup', 'Golden Syrup', 325, 0.0, 79.0, 0.0,
 0.0, 79.0, 20, NULL,
 'generic', ARRAY['golden syrup', 'lyles golden syrup', 'lyle''s golden syrup', 'treacle'],
 'honey_syrups', NULL, 1, '325 cal/100g. Per tbsp (20g): 65 cal. Inverted sugar syrup with amber color. British staple.', TRUE),

-- ==========================================
-- E. SEED & TRAIL MIX PRODUCTS (~15 items)
-- ==========================================

-- David Ranch Sunflower Seeds: per 100g (kernels): 575 cal, 19.3P, 24.1C, 49.3F, 8.6 fiber, 3.6 sugar.
('david_ranch_sunflower', 'David Ranch Sunflower Seeds', 575, 19.3, 24.1, 49.3,
 8.6, 3.6, 28, NULL,
 'david', ARRAY['david ranch sunflower seeds', 'david seeds ranch', 'ranch sunflower seeds'],
 'nuts_seeds', 'David', 1, '575 cal/100g (kernel only). Per 28g serving: 161 cal. In-shell seeds with ranch seasoning.', TRUE),

-- David BBQ Sunflower Seeds: per 100g: 575 cal, 19.3P, 24.1C, 49.3F, 8.6 fiber, 3.6 sugar.
('david_bbq_sunflower', 'David BBQ Sunflower Seeds', 575, 19.3, 24.1, 49.3,
 8.6, 3.6, 28, NULL,
 'david', ARRAY['david bbq sunflower seeds', 'david seeds bbq', 'bbq sunflower seeds'],
 'nuts_seeds', 'David', 1, '575 cal/100g (kernel only). Per 28g serving: 161 cal. In-shell seeds with BBQ seasoning.', TRUE),

-- David Original Sunflower Seeds: per 100g: 585 cal, 20.0P, 20.0C, 51.5F, 9.0 fiber, 2.0 sugar.
('david_original_sunflower', 'David Original Sunflower Seeds', 585, 20.0, 20.0, 51.5,
 9.0, 2.0, 28, NULL,
 'david', ARRAY['david sunflower seeds', 'david original sunflower seeds', 'david seeds original'],
 'nuts_seeds', 'David', 1, '585 cal/100g (kernel only). Per 28g serving: 164 cal. Classic roasted and salted.', TRUE),

-- Spitz Cracked Pepper Seeds: per 100g: 536 cal, 17.9P, 25.0C, 46.4F, 7.1 fiber, 3.6 sugar.
('spitz_cracked_pepper', 'Spitz Cracked Pepper Sunflower Seeds', 536, 17.9, 25.0, 46.4,
 7.1, 3.6, 28, NULL,
 'spitz', ARRAY['spitz cracked pepper', 'spitz sunflower seeds cracked pepper', 'spitz pepper seeds'],
 'nuts_seeds', 'Spitz', 1, '536 cal/100g. Per 28g: 150 cal. Cracked pepper flavored sunflower seeds.', TRUE),

-- Spitz Dill Pickle: per 100g: 536 cal, 17.9P, 25.0C, 46.4F, 7.1 fiber, 3.6 sugar.
('spitz_dill_pickle', 'Spitz Dill Pickle Sunflower Seeds', 536, 17.9, 25.0, 46.4,
 7.1, 3.6, 28, NULL,
 'spitz', ARRAY['spitz dill pickle', 'spitz sunflower seeds dill pickle', 'spitz pickle seeds'],
 'nuts_seeds', 'Spitz', 1, '536 cal/100g. Per 28g: 150 cal. Dill pickle flavored sunflower seeds.', TRUE),

-- Nature Valley Trail Mix Fruit & Nut: per 100g: 429 cal, 8.6P, 62.9C, 17.1F, 2.9 fiber, 25.7 sugar.
('nature_valley_trail_mix', 'Nature Valley Trail Mix Fruit & Nut Bar', 429, 8.6, 62.9, 17.1,
 2.9, 25.7, 35, 35,
 'nature_valley', ARRAY['nature valley trail mix', 'nature valley fruit and nut', 'nature valley trail mix bar'],
 'nuts_seeds', 'Nature Valley', 1, '429 cal/100g. Per 35g bar: 150 cal. Chewy granola bar with fruit and nuts.', TRUE),

-- Nature Valley Protein Granola: per 100g: 436 cal, 17.9P, 57.1C, 17.9F, 7.1 fiber, 21.4 sugar.
('nature_valley_protein_granola', 'Nature Valley Protein Granola Oats & Honey', 436, 17.9, 57.1, 17.9,
 7.1, 21.4, 56, NULL,
 'nature_valley', ARRAY['nature valley protein granola', 'nature valley granola', 'nature valley protein oats honey'],
 'nuts_seeds', 'Nature Valley', 1, '436 cal/100g. Per 56g serving: 244 cal. Crunchy protein granola clusters.', TRUE),

-- Kirkland Trail Mix: per 100g: 533 cal, 17.3P, 30.0C, 40.0F, 4.0 fiber, 20.0 sugar.
('kirkland_trail_mix', 'Kirkland Signature Trail Mix', 533, 17.3, 30.0, 40.0,
 4.0, 20.0, 28, NULL,
 'kirkland', ARRAY['kirkland trail mix', 'costco trail mix', 'kirkland signature trail mix'],
 'nuts_seeds', 'Kirkland', 1, '533 cal/100g. Per 28g: 149 cal. M&Ms, peanuts, raisins, almonds, cashews.', TRUE),

-- Kirkland Nut Bars: per 100g: 500 cal, 14.3P, 40.0C, 32.1F, 5.0 fiber, 22.0 sugar.
('kirkland_nut_bars', 'Kirkland Signature Nut Bars', 500, 14.3, 40.0, 32.1,
 5.0, 22.0, 40, 40,
 'kirkland', ARRAY['kirkland nut bars', 'costco nut bars', 'kirkland signature nut bars'],
 'nuts_seeds', 'Kirkland', 1, '500 cal/100g. Per 40g bar: 200 cal. Almonds, peanuts, with chocolate drizzle.', TRUE),

-- Kind Fruit & Nut Delight: per 100g: 486 cal, 10.7P, 42.9C, 32.1F, 7.1 fiber, 25.0 sugar.
('kind_fruit_nut_delight', 'Kind Fruit & Nut Delight', 486, 10.7, 42.9, 32.1,
 7.1, 25.0, 40, 40,
 'kind', ARRAY['kind fruit and nut', 'kind fruit nut delight', 'kind fruit & nut delight bar'],
 'nuts_seeds', 'Kind', 1, '486 cal/100g. Per 40g bar: 194 cal. Almonds, peanuts, with fruit pieces and honey.', TRUE),

-- Kind Dark Chocolate Nuts & Sea Salt: per 100g: 475 cal, 15.0P, 35.0C, 32.5F, 7.5 fiber, 15.0 sugar.
('kind_dark_choc_sea_salt', 'Kind Dark Chocolate Nuts & Sea Salt', 475, 15.0, 35.0, 32.5,
 7.5, 15.0, 40, 40,
 'kind', ARRAY['kind dark chocolate nuts sea salt', 'kind dark chocolate', 'kind dark chocolate and sea salt'],
 'nuts_seeds', 'Kind', 1, '475 cal/100g. Per 40g bar: 190 cal. Almonds, peanuts, dark chocolate, sea salt. 5g sugar/bar.', TRUE),

-- Sahale Glazed Cashews: per 100g: 464 cal, 14.3P, 39.3C, 28.6F, 3.6 fiber, 21.4 sugar.
('sahale_glazed_cashews', 'Sahale Snacks Glazed Cashews', 464, 14.3, 39.3, 28.6,
 3.6, 21.4, 28, NULL,
 'sahale', ARRAY['sahale glazed cashews', 'sahale cashews', 'sahale snacks cashews'],
 'nuts_seeds', 'Sahale', 1, '464 cal/100g. Per 28g: 130 cal. Premium glazed cashews with warm spices.', TRUE),

-- Sahale Honey Almonds: per 100g: 500 cal, 14.3P, 42.9C, 32.1F, 7.1 fiber, 25.0 sugar.
('sahale_honey_almonds', 'Sahale Snacks Honey Almonds Glazed Mix', 500, 14.3, 42.9, 32.1,
 7.1, 25.0, 28, NULL,
 'sahale', ARRAY['sahale honey almonds', 'sahale almonds', 'sahale honey almond mix'],
 'nuts_seeds', 'Sahale', 1, '500 cal/100g. Per 28g: 140 cal. Almonds glazed with honey and sesame seeds.', TRUE),

-- ==========================================
-- F. COOKING & SPECIALTY OILS (~20 items)
-- ==========================================

-- Mustard Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('mustard_oil', 'Mustard Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['mustard oil', 'sarson ka tel', 'kachi ghani mustard oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — favorable omega-6:omega-3 ratio (~2.5:1). Contains erucic acid (21%). Rich in MUFA. Common in Indian cuisine. NOT a seed oil.', TRUE),

-- Peanut Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('peanut_oil', 'Peanut Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['peanut oil', 'groundnut oil', 'arachis oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — moderate omega-6:omega-3 ratio (~32:1). High smoke point (450F). Rich in MUFA (46%). Good for deep-frying.', TRUE),

-- Sunflower Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('sunflower_oil', 'Sunflower Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['sunflower oil', 'sunflower seed oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — very high omega-6:omega-3 ratio (~40:1). High in linoleic acid (68% omega-6 PUFA). Consider olive oil or ghee for lower inflammatory profile.', TRUE),

-- Corn Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('corn_oil', 'Corn Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['corn oil', 'maize oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — high omega-6:omega-3 ratio (~46:1). 54% polyunsaturated (mostly omega-6). Consider olive oil or ghee for lower inflammatory profile.', TRUE),

-- Grapeseed Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('grapeseed_oil', 'Grapeseed Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['grapeseed oil', 'grape seed oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — very high omega-6:omega-3 ratio (~696:1). 70% omega-6 PUFA. One of the highest omega-6 oils. Consider olive oil or ghee for lower inflammatory profile.', TRUE),

-- Rice Bran Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('rice_bran_oil', 'Rice Bran Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['rice bran oil', 'rice oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — high omega-6:omega-3 ratio (~20:1). Contains oryzanol antioxidant. 39% MUFA, 34% PUFA. High smoke point (490F).', TRUE),

-- Safflower Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('safflower_oil', 'Safflower Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['safflower oil', 'safflower seed oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — extremely high omega-6:omega-3 ratio (~133:1). 75% omega-6 linoleic acid. Consider olive oil or ghee for lower inflammatory profile.', TRUE),

-- Soybean Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('soybean_oil', 'Soybean Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['soybean oil', 'soy oil', 'vegetable oil soybean'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — high omega-6:omega-3 ratio (~7:1). Most common "vegetable oil" in US. 51% omega-6, 7% omega-3 PUFA. Consider olive oil or ghee for lower inflammatory profile.', TRUE),

-- Walnut Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('walnut_oil', 'Walnut Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['walnut oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Better omega-6:omega-3 ratio (~5:1). 53% omega-6, 10% omega-3 (ALA). Good for salads, low smoke point (320F). Not for frying.', TRUE),

-- Flaxseed Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('flaxseed_oil', 'Flaxseed Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['flaxseed oil', 'linseed oil', 'flax oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Excellent omega-6:omega-3 ratio (~0.3:1). 57% omega-3 (ALA). Anti-inflammatory. Must be refrigerated. Never heat — low smoke point (225F).', TRUE),

-- Hemp Seed Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('hemp_seed_oil', 'Hemp Seed Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['hemp seed oil', 'hemp oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Good omega-6:omega-3 ratio (~3:1). Contains GLA (gamma-linolenic acid). Cold-pressed, best unheated. Nutty flavor.', TRUE),

-- Almond Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('almond_oil', 'Almond Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['almond oil', 'sweet almond oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — low omega-6:omega-3 ratio. 70% MUFA (oleic acid). Similar profile to olive oil. Good for high-heat cooking (420F smoke point).', TRUE),

-- Truffle Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('truffle_oil', 'Truffle Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 5, NULL,
 'generic', ARRAY['truffle oil', 'white truffle oil', 'black truffle oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Per tsp (5g): 44 cal. Olive oil base infused with truffle aroma. Used as finishing oil, not for cooking.', TRUE),

-- Palm Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('palm_oil', 'Palm Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['palm oil', 'red palm oil', 'palm kernel oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — low omega-6:omega-3 ratio. 50% saturated, 40% MUFA. Contains carotenoids (vitamin A precursor). High smoke point (450F).', TRUE),

-- Cottonseed Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('cottonseed_oil', 'Cottonseed Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['cottonseed oil', 'cotton seed oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — high omega-6:omega-3 ratio (~54:1). 52% omega-6 PUFA. Common in processed foods. Consider olive oil or ghee for lower inflammatory profile.', TRUE),

-- Amul Ghee: per 100g: 900 cal, 0.0P, 0.0C, 99.7F, 0.0 fiber, 0.0 sugar.
('amul_ghee', 'Amul Pure Ghee (Clarified Butter)', 900, 0.0, 0.0, 99.7,
 0.0, 0.0, 14, NULL,
 'amul', ARRAY['amul ghee', 'amul pure ghee', 'ghee amul', 'amul cow ghee', 'desi ghee amul'],
 'oils_fats', 'Amul', 1, '900 cal/100g. Traditional fat — negligible omega-6:omega-3 ratio. 62% saturated, 29% MUFA, 4% PUFA. Contains butyric acid, CLA. High smoke point (485F). NOT a seed oil.', TRUE),

-- Cooking Spray PAM: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('pam_cooking_spray', 'PAM Original Cooking Spray', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 0.25, NULL,
 'pam', ARRAY['pam cooking spray', 'pam spray', 'cooking spray', 'pam original', 'non-stick spray'],
 'oils_fats', 'PAM', 1, '884 cal/100g. Per 1s spray (~0.25g): 2 cal. Canola oil based. Seed oil — high omega-6. Serving is negligible calories due to tiny spray amount.', TRUE),

-- ==========================================
-- G. INTERNATIONAL & SPECIALTY SNACKS (~30 items)
-- ==========================================

-- Pocky Chocolate: per 100g: 500 cal, 7.0P, 66.0C, 23.0F, 2.0 fiber, 33.0 sugar.
('pocky_chocolate', 'Glico Pocky Chocolate', 500, 7.0, 66.0, 23.0,
 2.0, 33.0, 26, NULL,
 'glico', ARRAY['pocky chocolate', 'pocky', 'glico pocky', 'pocky sticks chocolate'],
 'international_snacks', 'Glico', 1, '500 cal/100g. Per 26g pack: 130 cal. Japanese biscuit sticks coated in chocolate.', TRUE),

-- Pocky Strawberry: per 100g: 495 cal, 6.5P, 68.0C, 22.0F, 1.5 fiber, 36.0 sugar.
('pocky_strawberry', 'Glico Pocky Strawberry', 495, 6.5, 68.0, 22.0,
 1.5, 36.0, 26, NULL,
 'glico', ARRAY['pocky strawberry', 'strawberry pocky', 'glico pocky strawberry'],
 'international_snacks', 'Glico', 1, '495 cal/100g. Per 26g pack: 129 cal. Japanese biscuit sticks coated in strawberry cream.', TRUE),

-- Pretz (Glico): per 100g: 470 cal, 9.0P, 68.0C, 18.0F, 2.0 fiber, 5.0 sugar.
('pretz', 'Glico Pretz Salad Flavor', 470, 9.0, 68.0, 18.0,
 2.0, 5.0, 30, NULL,
 'glico', ARRAY['pretz', 'glico pretz', 'pretz salad', 'pretz sticks'],
 'international_snacks', 'Glico', 1, '470 cal/100g. Per 30g: 141 cal. Japanese savory pretzel sticks.', TRUE),

-- Hi-Chew: per 100g: 385 cal, 0.0P, 85.0C, 5.0F, 0.0 fiber, 56.0 sugar.
('hi_chew', 'Hi-Chew Fruit Chews', 385, 0.0, 85.0, 5.0,
 0.0, 56.0, 44, 7.3,
 'morinaga', ARRAY['hi-chew', 'hi chew', 'hichew', 'hi-chew fruit chews'],
 'international_snacks', 'Morinaga', 6, '385 cal/100g. Per piece (7.3g): 28 cal. Japanese chewy fruit candy.', TRUE),

-- Haribo Gummy Bears: per 100g from USDA: 343 cal, 6.9P, 77.0C, 0.5F, 0.0 fiber, 46.0 sugar.
('haribo_gummy_bears', 'Haribo Goldbears Gummy Bears', 343, 6.9, 77.0, 0.5,
 0.0, 46.0, 30, NULL,
 'haribo', ARRAY['haribo gummy bears', 'haribo gold bears', 'gummy bears haribo', 'haribo goldbears'],
 'international_snacks', 'Haribo', 1, '343 cal/100g. Per 30g: 103 cal. Classic gummy bear shapes. Contains gelatin.', TRUE),

-- Swedish Fish: per 100g: 360 cal, 0.0P, 90.0C, 0.0F, 0.0 fiber, 54.0 sugar.
('swedish_fish', 'Swedish Fish Candy', 360, 0.0, 90.0, 0.0,
 0.0, 54.0, 40, NULL,
 'mondelez', ARRAY['swedish fish', 'swedish fish candy', 'swedish fish mini'],
 'international_snacks', 'Swedish Fish', 1, '360 cal/100g. Per 40g: 144 cal. Chewy fish-shaped candy. Fat-free.', TRUE),

-- Sour Patch Kids: per 100g: 367 cal, 0.0P, 90.0C, 0.0F, 0.0 fiber, 72.0 sugar.
('sour_patch_kids', 'Sour Patch Kids Candy', 367, 0.0, 90.0, 0.0,
 0.0, 72.0, 30, NULL,
 'mondelez', ARRAY['sour patch kids', 'sour patch', 'sour patch kids candy', 'sour kids'],
 'international_snacks', 'Sour Patch Kids', 1, '367 cal/100g. Per 30g: 110 cal. Sour then sweet gummy candy. Fat-free.', TRUE),

-- Trolli Sour Brite Crawlers: per 100g: 300 cal, 4.3P, 68.6C, 0.0F, 0.0 fiber, 40.0 sugar.
('trolli_sour_worms', 'Trolli Sour Brite Crawlers', 300, 4.3, 68.6, 0.0,
 0.0, 40.0, 35, NULL,
 'trolli', ARRAY['trolli sour worms', 'trolli sour brite crawlers', 'sour worms trolli', 'trolli gummy worms'],
 'international_snacks', 'Trolli', 1, '300 cal/100g. Per 35g: 105 cal. Dual-textured sour gummy worms. Fat-free.', TRUE),

-- Slim Jim Original: per 100g: 469 cal, 24.0P, 10.7C, 37.5F, 0.0 fiber, 3.6 sugar.
('slim_jim_original', 'Slim Jim Original Smoked Snack Stick', 469, 24.0, 10.7, 37.5,
 0.0, 3.6, 28, 28,
 'conagra', ARRAY['slim jim', 'slim jim original', 'slim jim snack stick', 'slim jim meat stick'],
 'international_snacks', 'Slim Jim', 1, '469 cal/100g. Per 28g stick: 131 cal. Smoked meat snack. Beef, pork, mechanically separated chicken.', TRUE),

-- Slim Jim Mild: per 100g: 469 cal, 24.0P, 10.7C, 37.5F, 0.0 fiber, 3.6 sugar.
('slim_jim_mild', 'Slim Jim Mild Smoked Snack Stick', 469, 24.0, 10.7, 37.5,
 0.0, 3.6, 28, 28,
 'conagra', ARRAY['slim jim mild', 'mild slim jim', 'slim jim mild snack stick'],
 'international_snacks', 'Slim Jim', 1, '469 cal/100g. Per 28g stick: 131 cal. Milder version of the classic Slim Jim.', TRUE),

-- Jack Link's Beef Jerky Original: per 100g: 286 cal, 46.4P, 17.9C, 3.6F, 0.0 fiber, 14.3 sugar.
('jack_links_original', 'Jack Link''s Beef Jerky Original', 286, 46.4, 17.9, 3.6,
 0.0, 14.3, 28, NULL,
 'jack_links', ARRAY['jack links beef jerky', 'jack link''s original', 'beef jerky jack links', 'jack links jerky original'],
 'international_snacks', 'Jack Link''s', 1, '286 cal/100g. Per 28g: 80 cal. 100% beef jerky. 10g protein per serving.', TRUE),

-- Jack Link's Teriyaki Beef Jerky: per 100g: 321 cal, 42.9P, 25.0C, 3.6F, 0.0 fiber, 21.4 sugar.
('jack_links_teriyaki', 'Jack Link''s Beef Jerky Teriyaki', 321, 42.9, 25.0, 3.6,
 0.0, 21.4, 28, NULL,
 'jack_links', ARRAY['jack links teriyaki', 'jack link''s teriyaki', 'teriyaki jerky jack links', 'jack links beef jerky teriyaki'],
 'international_snacks', 'Jack Link''s', 1, '321 cal/100g. Per 28g: 90 cal. Teriyaki-flavored beef jerky. Higher sugar than original.', TRUE),

-- Jack Link's Pepper Beef Jerky: per 100g: 286 cal, 46.4P, 17.9C, 3.6F, 0.0 fiber, 14.3 sugar.
('jack_links_pepper', 'Jack Link''s Beef Jerky Peppered', 286, 46.4, 17.9, 3.6,
 0.0, 14.3, 28, NULL,
 'jack_links', ARRAY['jack links pepper', 'jack link''s peppered', 'pepper jerky jack links', 'jack links pepper beef jerky'],
 'international_snacks', 'Jack Link''s', 1, '286 cal/100g. Per 28g: 80 cal. Cracked black pepper flavored beef jerky.', TRUE),

-- Biltong: per 100g: 250 cal, 50.0P, 2.0C, 5.0F, 0.0 fiber, 1.0 sugar.
('biltong', 'Biltong (South African Dried Beef)', 250, 50.0, 2.0, 5.0,
 0.0, 1.0, 28, NULL,
 'generic', ARRAY['biltong', 'south african biltong', 'dried beef biltong', 'beef biltong'],
 'international_snacks', NULL, 1, '250 cal/100g. Per 28g: 70 cal. Air-dried cured South African meat. Higher protein, lower fat than jerky.', TRUE),

-- Dried Mango: per 100g: 319 cal, 1.5P, 78.6C, 0.5F, 2.0 fiber, 73.0 sugar.
('dried_mango', 'Dried Mango', 319, 1.5, 78.6, 0.5,
 2.0, 73.0, 40, NULL,
 'usda', ARRAY['dried mango', 'dried mango slices', 'mango dried fruit', 'dehydrated mango'],
 'international_snacks', NULL, 1, '319 cal/100g. Per 40g serving: 128 cal. High in vitamin A and natural sugar.', TRUE),

-- Dried Cranberries (Craisins): per 100g: 325 cal, 0.4P, 82.4C, 1.4F, 5.3 fiber, 72.6 sugar.
('craisins', 'Ocean Spray Craisins Dried Cranberries', 325, 0.4, 82.4, 1.4,
 5.3, 72.6, 40, NULL,
 'ocean_spray', ARRAY['craisins', 'dried cranberries', 'ocean spray craisins', 'dried cranberry'],
 'international_snacks', 'Ocean Spray', 1, '325 cal/100g. Per 40g: 130 cal. Sweetened dried cranberries. Contains added sugar.', TRUE),

-- Rice Cakes Plain: per 100g: 387 cal, 8.0P, 81.1C, 2.8F, 4.2 fiber, 0.5 sugar.
('rice_cakes_plain', 'Rice Cakes Plain', 387, 8.0, 81.1, 2.8,
 4.2, 0.5, 9, 9,
 'usda', ARRAY['rice cakes', 'plain rice cakes', 'rice cake', 'puffed rice cakes'],
 'international_snacks', NULL, 1, '387 cal/100g. Per cake (9g): 35 cal. Low calorie, crunchy snack base.', TRUE),

-- Rice Cakes Chocolate: per 100g: 420 cal, 5.0P, 77.0C, 10.0F, 1.5 fiber, 30.0 sugar.
('rice_cakes_chocolate', 'Chocolate Rice Cakes', 420, 5.0, 77.0, 10.0,
 1.5, 30.0, 13, 13,
 'generic', ARRAY['chocolate rice cakes', 'rice cakes chocolate', 'chocolate covered rice cakes'],
 'international_snacks', NULL, 1, '420 cal/100g. Per cake (13g): 55 cal. Rice cake topped with chocolate coating.', TRUE),

-- Seaweed Snacks Roasted: per 100g: 350 cal, 30.0P, 20.0C, 22.0F, 14.0 fiber, 3.0 sugar.
('seaweed_snacks', 'Roasted Seaweed Snacks', 350, 30.0, 20.0, 22.0,
 14.0, 3.0, 5, NULL,
 'generic', ARRAY['seaweed snacks', 'roasted seaweed', 'nori snacks', 'seaweed sheets', 'korean seaweed snacks'],
 'international_snacks', NULL, 1, '350 cal/100g. Per 5g pack: 18 cal. Very low calorie per serving. Rich in iodine and minerals.', TRUE),

-- Halvah: per 100g from USDA: 522 cal, 12.5P, 55.0C, 29.0F, 4.0 fiber, 42.0 sugar.
('halvah', 'Halvah (Sesame Halva)', 522, 12.5, 55.0, 29.0,
 4.0, 42.0, 30, NULL,
 'usda', ARRAY['halvah', 'halva', 'halwa sesame', 'tahini halvah', 'sesame halvah'],
 'international_snacks', NULL, 1, '522 cal/100g. Per 30g: 157 cal. Dense confection of tahini (sesame paste) and sugar. Middle Eastern origin.', TRUE),

-- Turkish Delight: per 100g: 350 cal, 0.5P, 86.0C, 0.5F, 0.0 fiber, 80.0 sugar.
('turkish_delight', 'Turkish Delight (Lokum)', 350, 0.5, 86.0, 0.5,
 0.0, 80.0, 25, 8,
 'generic', ARRAY['turkish delight', 'lokum', 'turkish delight candy', 'rose turkish delight'],
 'international_snacks', NULL, 1, '350 cal/100g. Per piece (~8g): 28 cal. Gel confection of starch and sugar, dusted in powdered sugar.', TRUE),

-- Baklava (per piece): per 100g: 428 cal, 5.2P, 48.0C, 22.6F, 2.0 fiber, 30.0 sugar.
('baklava', 'Baklava', 428, 5.2, 48.0, 22.6,
 2.0, 30.0, 25, 25,
 'usda', ARRAY['baklava', 'baklawa', 'pistachio baklava', 'walnut baklava'],
 'international_snacks', NULL, 1, '428 cal/100g. Per piece (~25g): 107 cal. Layered phyllo dough with nuts and honey/syrup.', TRUE),

-- Churros: per 100g: 425 cal, 6.0P, 42.6C, 25.2F, 1.5 fiber, 16.0 sugar.
('churros', 'Churros', 425, 6.0, 42.6, 25.2,
 1.5, 16.0, 40, 40,
 'usda', ARRAY['churros', 'churro', 'cinnamon sugar churro', 'fried churro'],
 'international_snacks', NULL, 1, '425 cal/100g. Per churro (~40g): 170 cal. Fried dough with cinnamon sugar. Often served with chocolate sauce.', TRUE),

-- Mochi (per piece): per 100g: 264 cal, 4.0P, 56.0C, 2.5F, 1.0 fiber, 20.0 sugar.
('mochi', 'Mochi (Japanese Rice Cake)', 264, 4.0, 56.0, 2.5,
 1.0, 20.0, 40, 40,
 'generic', ARRAY['mochi', 'japanese mochi', 'mochi ice cream', 'daifuku mochi', 'rice cake mochi'],
 'international_snacks', NULL, 1, '264 cal/100g. Per piece (~40g): 106 cal. Chewy glutinous rice cake, often with sweet filling.', TRUE),

-- Jalebi: per 100g: 350 cal, 2.0P, 65.0C, 9.0F, 0.5 fiber, 55.0 sugar.
('jalebi', 'Jalebi (Indian Sweet)', 350, 2.0, 65.0, 9.0,
 0.5, 55.0, 40, 40,
 'generic', ARRAY['jalebi', 'jilebi', 'zulbia', 'imarti', 'indian jalebi'],
 'international_snacks', NULL, 1, '350 cal/100g. Per piece (~40g): 140 cal. Deep-fried spiral-shaped sweet soaked in sugar syrup.', TRUE),

-- ==========================================
-- H. HEALTH/ORGANIC SNACKS (~15 items)
-- ==========================================

-- Perfect Bar Dark Chocolate Peanut Butter: per 100g: 407 cal, 22.0P, 35.0C, 22.0F, 3.0 fiber, 22.0 sugar.
('perfect_bar_dark_choc_pb', 'Perfect Bar Dark Chocolate Chip Peanut Butter', 407, 22.0, 35.0, 22.0,
 3.0, 22.0, 65, 65,
 'perfect_bar', ARRAY['perfect bar dark chocolate', 'perfect bar peanut butter', 'perfect bar dark choc pb', 'perfect bar dark chocolate peanut butter'],
 'health_snacks', 'Perfect Bar', 1, '407 cal/100g. Per 65g bar: 265 cal. 15g protein, 20+ superfoods. Refrigerated protein bar.', TRUE),

-- LARABAR Apple Pie: per 100g: 448 cal, 6.9P, 55.2C, 24.1F, 6.9 fiber, 34.5 sugar.
('larabar_apple_pie', 'LARABAR Apple Pie', 448, 6.9, 55.2, 24.1,
 6.9, 34.5, 45, 45,
 'larabar', ARRAY['larabar apple pie', 'larabar apple', 'lara bar apple pie'],
 'health_snacks', 'LARABAR', 1, '448 cal/100g. Per 45g bar: 200 cal. Only 3 ingredients: dates, almonds, cinnamon. Minimally processed.', TRUE),

-- LARABAR Peanut Butter Cookie: per 100g: 467 cal, 13.3P, 40.0C, 28.9F, 4.4 fiber, 24.4 sugar.
('larabar_pb_cookie', 'LARABAR Peanut Butter Cookie', 467, 13.3, 40.0, 28.9,
 4.4, 24.4, 45, 45,
 'larabar', ARRAY['larabar peanut butter cookie', 'larabar pb cookie', 'lara bar peanut butter'],
 'health_snacks', 'LARABAR', 1, '467 cal/100g. Per 45g bar: 210 cal. Only 3 ingredients: dates, peanuts, salt. Minimally processed.', TRUE),

-- ThinkThin High Protein Bar: per 100g: 400 cal, 33.3P, 40.0C, 13.3F, 1.7 fiber, 0.0 sugar.
('thinkthin_protein_bar', 'think! High Protein Bar Chunky Peanut Butter', 400, 33.3, 40.0, 13.3,
 1.7, 0.0, 60, 60,
 'thinkthin', ARRAY['thinkthin bar', 'think thin bar', 'think high protein bar', 'thinkthin protein bar'],
 'health_snacks', 'think!', 1, '400 cal/100g. Per 60g bar: 240 cal. 20g protein, 0g sugar. Gluten-free.', TRUE),

-- Hippeas Vegan White Cheddar: per 100g: 464 cal, 17.9P, 53.6C, 21.4F, 7.1 fiber, 3.6 sugar.
('hippeas_white_cheddar', 'Hippeas Vegan White Cheddar Chickpea Puffs', 464, 17.9, 53.6, 21.4,
 7.1, 3.6, 28, NULL,
 'hippeas', ARRAY['hippeas', 'hippeas white cheddar', 'hippeas vegan white cheddar', 'hippeas chickpea puffs'],
 'health_snacks', 'Hippeas', 1, '464 cal/100g. Per 28g: 130 cal. 4g protein, 3g fiber per serving. Chickpea-based.', TRUE),

-- SkinnyPop Popcorn (already exists in 320 migration, ON CONFLICT will update): per 100g: 536 cal, 7.1P, 53.6C, 35.7F, 7.1 fiber, 0.0 sugar.
('skinnypop_original', 'SkinnyPop Original Popcorn', 536, 7.1, 53.6, 35.7,
 7.1, 0.0, 28, NULL,
 'skinnypop', ARRAY['skinnypop', 'skinny pop', 'skinnypop original', 'skinny pop popcorn', 'skinnypop original popcorn'],
 'chips_snacks', 'SkinnyPop', 1, '536 cal/100g. Per 28g bag: 150 cal. Popcorn, sunflower oil, salt. Simple ingredients.', TRUE),

-- Veggie Straws (already exists in 320 migration, ON CONFLICT will update): per 100g: 464 cal, 3.6P, 60.7C, 25.0F, 0.0 fiber, 3.6 sugar.
('veggie_straws', 'Sensible Portions Garden Veggie Straws Sea Salt', 464, 3.6, 60.7, 25.0,
 0.0, 3.6, 28, NULL,
 'sensible_portions', ARRAY['veggie straws', 'veggie straw chips', 'garden veggie straws', 'sensible portions veggie straws', 'vegetable straws'],
 'chips_snacks', 'Sensible Portions', 1, '464 cal/100g. Per 28g bag (38 straws): 130 cal. Vegetable and potato snack.', TRUE),

-- Pirate's Booty (already exists in 320 migration, ON CONFLICT will update): per 100g: 464 cal, 7.1P, 67.9C, 17.9F, 0.0 fiber, 3.6 sugar.
('pirates_booty', 'Pirate''s Booty Aged White Cheddar', 464, 7.1, 67.9, 17.9,
 0.0, 3.6, 28, NULL,
 'pirates_booty', ARRAY['pirates booty', 'pirate''s booty', 'pirate booty', 'pirates booty white cheddar', 'pirate''s booty aged white cheddar'],
 'chips_snacks', 'Pirate''s Booty', 1, '464 cal/100g. Per 28g bag: 130 cal. Baked rice & corn puffs with aged white cheddar.', TRUE),

-- Siete Grain-Free Tortilla Chips: per 100g: 464 cal, 3.6P, 57.1C, 25.0F, 7.1 fiber, 3.6 sugar.
('siete_tortilla_chips', 'Siete Grain-Free Tortilla Chips Sea Salt', 464, 3.6, 57.1, 25.0,
 7.1, 3.6, 28, NULL,
 'siete', ARRAY['siete chips', 'siete tortilla chips', 'siete grain free chips', 'siete sea salt chips'],
 'health_snacks', 'Siete', 1, '464 cal/100g. Per 28g: 130 cal. Cassava flour based. Grain-free, dairy-free, paleo-friendly.', TRUE),

-- Lesser Evil Paleo Puffs: per 100g: 536 cal, 7.1P, 57.1C, 32.1F, 3.6 fiber, 0.0 sugar.
('lesser_evil_paleo_puffs', 'Lesser Evil Paleo Puffs No Cheese Cheesiness', 536, 7.1, 57.1, 32.1,
 3.6, 0.0, 28, NULL,
 'lesser_evil', ARRAY['lesser evil paleo puffs', 'paleo puffs', 'lesser evil puffs'],
 'health_snacks', 'Lesser Evil', 1, '536 cal/100g. Per 28g: 150 cal. Coconut oil puffed snack. Paleo-friendly, grain-free.', TRUE),

-- Chomps Beef Stick Original: per 100g: 185 cal, 37.0P, 0.0C, 4.6F, 0.0 fiber, 0.0 sugar.
('chomps_beef_stick', 'Chomps Original Beef Stick', 185, 37.0, 0.0, 4.6,
 0.0, 0.0, 27, 27,
 'chomps', ARRAY['chomps', 'chomps beef stick', 'chomps original', 'chomps meat stick'],
 'health_snacks', 'Chomps', 1, '185 cal/100g. Per 27g stick: 50 cal. 10g protein, 0g sugar. 100% grass-fed beef. Whole30 approved.', TRUE),

-- ==========================================
-- ADDITIONAL CHOCOLATE BARS (to reach 200+)
-- ==========================================

-- Kit Kat: per 100g from USDA: 518 cal, 6.5P, 64.6C, 26.0F, 1.5 fiber, 49.0 sugar.
('kit_kat', 'Kit Kat Wafer Bar', 518, 6.5, 64.6, 26.0,
 1.5, 49.0, 42, 42,
 'hersheys', ARRAY['kit kat', 'kitkat', 'kit kat bar', 'kit kat wafer bar'],
 'chocolate', 'Hershey''s', 1, '518 cal/100g. Per 42g bar: 218 cal. Crispy wafer fingers covered in milk chocolate.', TRUE),

-- Reese's Peanut Butter Cups: per 100g from USDA: 515 cal, 10.2P, 55.4C, 30.5F, 2.0 fiber, 47.0 sugar.
('reeses_peanut_butter_cups', 'Reese''s Peanut Butter Cups', 515, 10.2, 55.4, 30.5,
 2.0, 47.0, 42, 21,
 'hersheys', ARRAY['reese''s peanut butter cups', 'reeses cups', 'reeses peanut butter cup', 'reese''s cups'],
 'chocolate', 'Hershey''s', 1, '515 cal/100g. Per 42g pack (2 cups): 216 cal. Chocolate cups filled with peanut butter.', TRUE),

-- Reese's Pieces: per 100g: 500 cal, 12.5P, 55.0C, 25.0F, 2.5 fiber, 45.0 sugar.
('reeses_pieces', 'Reese''s Pieces Candy', 500, 12.5, 55.0, 25.0,
 2.5, 45.0, 43, NULL,
 'hersheys', ARRAY['reese''s pieces', 'reeses pieces', 'reese''s pieces candy'],
 'chocolate', 'Hershey''s', 1, '500 cal/100g. Per 43g pack: 215 cal. Peanut butter candy in crunchy shell.', TRUE),

-- M&M's Milk Chocolate: per 100g: 492 cal, 4.7P, 66.7C, 22.0F, 2.0 fiber, 61.0 sugar.
('mms_milk_chocolate', 'M&M''s Milk Chocolate Candies', 492, 4.7, 66.7, 22.0,
 2.0, 61.0, 42, NULL,
 'mars', ARRAY['m&ms', 'm and ms', 'mms', 'm&m''s milk chocolate', 'mms plain'],
 'chocolate', 'Mars', 1, '492 cal/100g. Per 42g pack: 207 cal. Milk chocolate in colorful candy shell.', TRUE),

-- M&M's Peanut: per 100g: 506 cal, 9.4P, 57.8C, 26.5F, 2.5 fiber, 50.0 sugar.
('mms_peanut', 'M&M''s Peanut Candies', 506, 9.4, 57.8, 26.5,
 2.5, 50.0, 49, NULL,
 'mars', ARRAY['m&m''s peanut', 'mms peanut', 'peanut m&ms', 'm and ms peanut'],
 'chocolate', 'Mars', 1, '506 cal/100g. Per 49g pack: 248 cal. Whole peanut in milk chocolate in candy shell.', TRUE),

-- Skittles Original: per 100g: 400 cal, 0.0P, 91.0C, 4.5F, 0.0 fiber, 75.0 sugar.
('skittles', 'Skittles Original Fruit Candies', 400, 0.0, 91.0, 4.5,
 0.0, 75.0, 56, NULL,
 'mars', ARRAY['skittles', 'skittles original', 'skittles fruit', 'skittles candy'],
 'chocolate', 'Mars', 1, '400 cal/100g. Per 56g pack: 224 cal. Fruit-flavored candy in colorful shell. Taste the rainbow.', TRUE),

-- Nerds: per 100g: 400 cal, 0.0P, 93.3C, 0.0F, 0.0 fiber, 86.7 sugar.
('nerds_candy', 'Nerds Candy', 400, 0.0, 93.3, 0.0,
 0.0, 86.7, 47, NULL,
 'ferrara', ARRAY['nerds', 'nerds candy', 'wonka nerds', 'nerds grape strawberry'],
 'international_snacks', 'Nerds', 1, '400 cal/100g. Per 47g box: 188 cal. Tiny crunchy tangy candy pieces. Fat-free.', TRUE),

-- Starburst: per 100g: 408 cal, 0.0P, 85.7C, 7.1F, 0.0 fiber, 57.1 sugar.
('starburst', 'Starburst Fruit Chews Original', 408, 0.0, 85.7, 7.1,
 0.0, 57.1, 14, 4.7,
 'mars', ARRAY['starburst', 'starburst fruit chews', 'starburst candy', 'starburst original'],
 'international_snacks', 'Mars', 3, '408 cal/100g. Per piece (4.7g): 19 cal. Soft fruit-flavored taffy chews.', TRUE),

-- Airheads: per 100g: 385 cal, 0.0P, 88.5C, 3.8F, 0.0 fiber, 65.4 sugar.
('airheads', 'Airheads Candy Bar', 385, 0.0, 88.5, 3.8,
 0.0, 65.4, 15.6, 15.6,
 'perfetti', ARRAY['airheads', 'airheads candy', 'airheads bar', 'air heads'],
 'international_snacks', 'Airheads', 1, '385 cal/100g. Per 15.6g bar: 60 cal. Stretchy fruit-flavored taffy candy.', TRUE),

-- Jolly Rancher: per 100g: 389 cal, 0.0P, 97.2C, 0.0F, 0.0 fiber, 69.4 sugar.
('jolly_rancher', 'Jolly Rancher Hard Candy', 389, 0.0, 97.2, 0.0,
 0.0, 69.4, 17, 6,
 'hersheys', ARRAY['jolly rancher', 'jolly rancher hard candy', 'jolly rancher candy'],
 'international_snacks', 'Hershey''s', 3, '389 cal/100g. Per piece (6g): 23 cal. Intensely fruity hard candy. Fat-free.', TRUE),

-- Laffy Taffy: per 100g: 393 cal, 0.0P, 88.6C, 5.7F, 0.0 fiber, 62.9 sugar.
('laffy_taffy', 'Laffy Taffy', 393, 0.0, 88.6, 5.7,
 0.0, 62.9, 42, 42,
 'ferrara', ARRAY['laffy taffy', 'laffy taffy candy', 'laffy taffy bar'],
 'international_snacks', 'Laffy Taffy', 1, '393 cal/100g. Per 42g bar: 165 cal. Stretchy taffy candy in fruit flavors. Jokes on every wrapper.', TRUE),

-- Twizzlers: per 100g: 342 cal, 2.6P, 79.0C, 2.6F, 0.0 fiber, 42.1 sugar.
('twizzlers', 'Twizzlers Twists Strawberry', 342, 2.6, 79.0, 2.6,
 0.0, 42.1, 40, NULL,
 'hersheys', ARRAY['twizzlers', 'twizzlers strawberry', 'twizzlers twists', 'twizzler candy'],
 'international_snacks', 'Hershey''s', 1, '342 cal/100g. Per 40g (4 pieces): 137 cal. Classic strawberry-flavored licorice twists. Low fat.', TRUE),

-- Mike and Ike: per 100g: 370 cal, 0.0P, 90.0C, 0.0F, 0.0 fiber, 66.7 sugar.
('mike_and_ike', 'Mike and Ike Original Fruits', 370, 0.0, 90.0, 0.0,
 0.0, 66.7, 43, NULL,
 'just_born', ARRAY['mike and ike', 'mike & ike', 'mike and ike original', 'mike and ike candy'],
 'international_snacks', 'Mike and Ike', 1, '370 cal/100g. Per 43g box: 159 cal. Fruit-flavored chewy candy. Fat-free.', TRUE),

-- Werther's Original: per 100g: 417 cal, 0.0P, 83.3C, 8.3F, 0.0 fiber, 66.7 sugar.
('werthers_original', 'Werther''s Original Classic Caramels', 417, 0.0, 83.3, 8.3,
 0.0, 66.7, 30, 6,
 'storck', ARRAY['werther''s original', 'werthers', 'werthers original', 'werther''s caramel'],
 'international_snacks', 'Werther''s', 5, '417 cal/100g. Per piece (6g): 25 cal. Butter caramel hard candy. German origin.', TRUE),

-- ==========================================
-- ADDITIONAL SPECIALTY ITEMS
-- ==========================================

-- Canola Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('canola_oil', 'Canola Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['canola oil', 'rapeseed oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Seed oil — moderate omega-6:omega-3 ratio (~2:1). 7% omega-3 ALA, 21% omega-6 LA. Often highly refined. Consider olive oil or ghee as traditional alternatives.', TRUE),

-- Sesame Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('sesame_oil', 'Sesame Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['sesame oil', 'toasted sesame oil', 'gingelly oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — moderate omega-6:omega-3 ratio (~45:1). Contains sesamin and sesamol antioxidants. NOT a typical seed oil — traditional in Asian cuisine for centuries.', TRUE),

-- Avocado Oil: per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('avocado_oil', 'Avocado Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['avocado oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — excellent omega-6:omega-3 ratio (~13:1). 70% MUFA (oleic acid). Very high smoke point (520F). Premium cooking oil.', TRUE),

-- Nutella: per 100g: 541 cal, 6.0P, 57.3C, 31.6F, 3.4 fiber, 54.0 sugar.
('nutella', 'Nutella Hazelnut Spread', 541, 6.0, 57.3, 31.6,
 3.4, 54.0, 37, NULL,
 'ferrero', ARRAY['nutella', 'nutella spread', 'nutella hazelnut spread', 'ferrero nutella'],
 'chocolate', 'Ferrero', 1, '541 cal/100g. Per tbsp (37g): 200 cal. Hazelnut cocoa spread. Contains palm oil and sugar as first ingredients.', TRUE),

-- Hershey's Reese's Sticks: per 100g: 514 cal, 8.6P, 54.3C, 30.0F, 1.4 fiber, 40.0 sugar.
('reeses_sticks', 'Reese''s Sticks Wafer Bar', 514, 8.6, 54.3, 30.0,
 1.4, 40.0, 42, 42,
 'hersheys', ARRAY['reese''s sticks', 'reeses sticks', 'reese sticks', 'reese''s wafer sticks'],
 'chocolate', 'Hershey''s', 1, '514 cal/100g. Per 42g pack: 216 cal. Crispy wafer with peanut butter and chocolate.', TRUE),

-- Hershey's Zero Sugar: per 100g: 467 cal, 6.7P, 66.7C, 23.3F, 6.7 fiber, 0.0 sugar.
('hersheys_zero_sugar', 'Hershey''s Zero Sugar Milk Chocolate', 467, 6.7, 66.7, 23.3,
 6.7, 0.0, 30, NULL,
 'hersheys', ARRAY['hersheys zero sugar', 'hershey''s sugar free', 'hershey''s zero sugar chocolate'],
 'chocolate', 'Hershey''s', 1, '467 cal/100g. Per 30g: 140 cal. Sugar-free milk chocolate alternative. Contains sugar alcohols.', TRUE),

-- Maltesers: per 100g: 498 cal, 7.4P, 60.8C, 24.8F, 1.5 fiber, 55.0 sugar.
('maltesers', 'Maltesers Chocolate Malt Balls', 498, 7.4, 60.8, 24.8,
 1.5, 55.0, 37, NULL,
 'mars', ARRAY['maltesers', 'malteser', 'maltesers chocolate', 'malt balls'],
 'chocolate', 'Mars', 1, '498 cal/100g. Per 37g bag: 184 cal. Light, honeycomb-malt center in milk chocolate.', TRUE),

-- Tic Tac Mints: per 100g: 394 cal, 0.0P, 97.5C, 0.5F, 0.0 fiber, 95.0 sugar.
('tic_tac', 'Tic Tac Fresh Mint', 394, 0.0, 97.5, 0.5,
 0.0, 95.0, 49, 0.5,
 'ferrero', ARRAY['tic tac', 'tic tacs', 'tic tac mints', 'tic tac fresh mint'],
 'international_snacks', 'Ferrero', 1, '394 cal/100g. Per piece (0.5g): 2 cal. Listed as "0 calories" per piece due to rounding. Nearly pure sugar.', TRUE),

-- Mentos: per 100g: 390 cal, 0.0P, 93.0C, 2.5F, 0.0 fiber, 67.0 sugar.
('mentos', 'Mentos Original Chewy Mints', 390, 0.0, 93.0, 2.5,
 0.0, 67.0, 38, 2.7,
 'perfetti', ARRAY['mentos', 'mentos mint', 'mentos original', 'mentos chewy mints'],
 'international_snacks', 'Mentos', 1, '390 cal/100g. Per piece (2.7g): 11 cal. Chewy coated candy in various flavors.', TRUE),

-- Tootsie Roll: per 100g: 389 cal, 0.8P, 83.0C, 6.8F, 0.0 fiber, 57.6 sugar.
('tootsie_roll', 'Tootsie Roll Midgees', 389, 0.8, 83.0, 6.8,
 0.0, 57.6, 40, 6,
 'tootsie', ARRAY['tootsie roll', 'tootsie rolls', 'tootsie roll midgees'],
 'international_snacks', 'Tootsie Roll', 1, '389 cal/100g. Per piece (6g): 23 cal. Chocolate-flavored taffy candy since 1907.', TRUE),

-- Milka Whole Hazelnut: per 100g: 545 cal, 8.0P, 52.0C, 34.0F, 2.0 fiber, 49.0 sugar.
('milka_hazelnut', 'Milka Whole Hazelnut Chocolate', 545, 8.0, 52.0, 34.0,
 2.0, 49.0, 100, NULL,
 'milka', ARRAY['milka hazelnut', 'milka whole hazelnut', 'milka hazelnuss'],
 'chocolate', 'Milka', 1, '545 cal/100g. Milka Alpine milk chocolate with whole hazelnuts.', TRUE),

-- Crunch (branded): per 100g: 500 cal, 5.0P, 65.0C, 24.0F, 1.0 fiber, 52.0 sugar.
('ferrero_crunch', 'Ferrero Crunch Bar', 500, 5.0, 65.0, 24.0,
 1.0, 52.0, 33, 33,
 'ferrero', ARRAY['crunch bar', 'nestle crunch bar', 'ferrero crunch'],
 'chocolate', 'Ferrero', 1, '500 cal/100g. Per 33g bar: 165 cal. Milk chocolate with crisped rice.', TRUE),

-- Rolo: per 100g: 476 cal, 3.8P, 66.7C, 21.4F, 0.5 fiber, 57.1 sugar.
('rolo', 'Rolo Chewy Caramels in Milk Chocolate', 476, 3.8, 66.7, 21.4,
 0.5, 57.1, 42, 5,
 'hersheys', ARRAY['rolo', 'rolo caramels', 'rolo chocolate caramels'],
 'chocolate', 'Hershey''s', 8, '476 cal/100g. Per piece (5g): 24 cal. Chewy caramel wrapped in smooth milk chocolate.', TRUE),

-- Dove Milk Chocolate: per 100g: 533 cal, 6.7P, 56.7C, 33.3F, 2.2 fiber, 50.0 sugar.
('dove_milk_chocolate', 'Dove Milk Chocolate Promises', 533, 6.7, 56.7, 33.3,
 2.2, 50.0, 37, 9.2,
 'mars', ARRAY['dove chocolate', 'dove milk chocolate', 'dove promises', 'dove chocolate promises'],
 'chocolate', 'Mars', 4, '533 cal/100g. Per piece (9.2g): 49 cal. Smooth, silky milk chocolate. Messages inside wrapper.', TRUE),

-- Dove Dark Chocolate: per 100g: 550 cal, 6.7P, 50.0C, 36.7F, 5.0 fiber, 40.0 sugar.
('dove_dark_chocolate', 'Dove Dark Chocolate Promises', 550, 6.7, 50.0, 36.7,
 5.0, 40.0, 37, 9.2,
 'mars', ARRAY['dove dark chocolate', 'dove dark promises', 'dove dark chocolate promises'],
 'chocolate', 'Mars', 4, '550 cal/100g. Per piece (9.2g): 51 cal. Rich, smooth dark chocolate. Messages inside wrapper.', TRUE),

-- 5th Avenue: per 100g: 486 cal, 8.6P, 57.1C, 25.7F, 2.0 fiber, 42.9 sugar.
('fifth_avenue', '5th Avenue Candy Bar', 486, 8.6, 57.1, 25.7,
 2.0, 42.9, 56, 56,
 'hersheys', ARRAY['5th avenue', 'fifth avenue bar', '5th avenue candy bar'],
 'chocolate', 'Hershey''s', 1, '486 cal/100g. Per 56g bar: 272 cal. Crunchy peanut butter layers in milk chocolate.', TRUE),

-- Zero Bar: per 100g: 467 cal, 3.3P, 66.7C, 20.0F, 0.0 fiber, 53.3 sugar.
('zero_bar', 'Zero Bar Candy', 467, 3.3, 66.7, 20.0,
 0.0, 53.3, 52, 52,
 'hersheys', ARRAY['zero bar', 'zero candy bar', 'zero bar candy'],
 'chocolate', 'Hershey''s', 1, '467 cal/100g. Per 52g bar: 243 cal. White fudge, caramel, peanut nougat.', TRUE),

-- Mr. Goodbar: per 100g: 543 cal, 10.7P, 50.0C, 35.7F, 3.6 fiber, 42.9 sugar.
('mr_goodbar', 'Hershey''s Mr. Goodbar', 543, 10.7, 50.0, 35.7,
 3.6, 42.9, 49, 49,
 'hersheys', ARRAY['mr goodbar', 'mr. goodbar', 'hershey''s mr goodbar', 'mister goodbar'],
 'chocolate', 'Hershey''s', 1, '543 cal/100g. Per 49g bar: 266 cal. Milk chocolate packed with peanuts since 1925.', TRUE),

-- Krackel: per 100g: 514 cal, 6.0P, 62.0C, 27.0F, 1.0 fiber, 52.0 sugar.
('krackel', 'Hershey''s Krackel Bar', 514, 6.0, 62.0, 27.0,
 1.0, 52.0, 43, 43,
 'hersheys', ARRAY['krackel', 'krackel bar', 'hershey''s krackel'],
 'chocolate', 'Hershey''s', 1, '514 cal/100g. Per 43g bar: 221 cal. Milk chocolate with crisped rice. Similar to Crunch bar.', TRUE),

-- White Chocolate Reese's: per 100g: 536 cal, 10.0P, 53.6C, 32.1F, 1.0 fiber, 46.4 sugar.
('reeses_white', 'Reese''s White Peanut Butter Cups', 536, 10.0, 53.6, 32.1,
 1.0, 46.4, 42, 21,
 'hersheys', ARRAY['reese''s white', 'white reeses', 'reese''s white peanut butter cups', 'white chocolate reeses'],
 'chocolate', 'Hershey''s', 1, '536 cal/100g. Per 42g pack (2 cups): 225 cal. White creme cups with peanut butter.', TRUE),

-- Peanut M&M's Sharing Size: per 100g: 506 cal, 9.4P, 57.8C, 26.5F, 2.5 fiber, 50.0 sugar.
('mms_almond', 'M&M''s Almond Candies', 512, 8.5, 56.0, 28.0,
 3.0, 48.0, 42, NULL,
 'mars', ARRAY['m&m''s almond', 'mms almond', 'almond m&ms', 'm and ms almond'],
 'chocolate', 'Mars', 1, '512 cal/100g. Per 42g pack: 215 cal. Whole almond in milk chocolate in candy shell.', TRUE),

-- Ghirardelli Sea Salt Caramel: per 100g: 500 cal, 5.0P, 53.0C, 30.0F, 2.5 fiber, 43.0 sugar.
('ghirardelli_sea_salt_caramel', 'Ghirardelli Dark Chocolate Sea Salt Caramel Squares', 500, 5.0, 53.0, 30.0,
 2.5, 43.0, 43, 10.6,
 'ghirardelli', ARRAY['ghirardelli sea salt caramel', 'ghirardelli dark sea salt caramel', 'ghirardelli salted caramel squares'],
 'chocolate', 'Ghirardelli', 4, '500 cal/100g. Per square (10.6g): 53 cal. Dark chocolate with liquid salted caramel filling.', TRUE),

-- Cadbury Creme Egg: per 100g: 450 cal, 3.3P, 66.7C, 16.7F, 0.0 fiber, 63.3 sugar.
('cadbury_creme_egg', 'Cadbury Creme Egg', 450, 3.3, 66.7, 16.7,
 0.0, 63.3, 34, 34,
 'cadbury', ARRAY['cadbury creme egg', 'cadbury cream egg', 'creme egg', 'cadbury easter egg'],
 'chocolate', 'Cadbury', 1, '450 cal/100g. Per egg (34g): 153 cal. Milk chocolate shell with fondant creme filling. Seasonal (Easter).', TRUE),

-- Kinder Chocolate: per 100g: 560 cal, 8.5P, 52.5C, 35.0F, 1.0 fiber, 50.0 sugar.
('kinder_chocolate', 'Kinder Chocolate Bar', 560, 8.5, 52.5, 35.0,
 1.0, 50.0, 12.5, 12.5,
 'ferrero', ARRAY['kinder chocolate', 'kinder bar', 'kinder chocolate bar', 'kinder riegel'],
 'chocolate', 'Ferrero', 1, '560 cal/100g. Per bar (12.5g): 70 cal. Milk chocolate with creamy milk filling. Kid-sized.', TRUE),

-- Ritter Sport Hazelnut: per 100g: 561 cal, 7.5P, 50.0C, 37.0F, 2.5 fiber, 46.0 sugar.
('ritter_sport_hazelnut', 'Ritter Sport Whole Hazelnuts', 561, 7.5, 50.0, 37.0,
 2.5, 46.0, 100, NULL,
 'ritter_sport', ARRAY['ritter sport hazelnut', 'ritter sport whole hazelnuts', 'ritter sport nuss'],
 'chocolate', 'Ritter Sport', 1, '561 cal/100g. 100g square bar with whole hazelnuts in milk chocolate.', TRUE),

-- Lindt Excellence 90%: per 100g: 592 cal, 11.0P, 18.0C, 55.0F, 14.0 fiber, 7.0 sugar.
('lindt_90_dark', 'Lindt Excellence 90% Cocoa Supreme Dark', 592, 11.0, 18.0, 55.0,
 14.0, 7.0, 40, NULL,
 'lindt', ARRAY['lindt 90%', 'lindt excellence 90', 'lindt supreme dark 90%', 'lindt 90 cocoa'],
 'chocolate', 'Lindt', 1, '592 cal/100g. Extremely dark chocolate. Only 7g sugar/100g, 14g fiber from cocoa.', TRUE),

-- Milkybar (Nestle): per 100g: 552 cal, 6.5P, 58.0C, 33.0F, 0.0 fiber, 57.5 sugar.
('milkybar', 'Nestle Milkybar White Chocolate', 552, 6.5, 58.0, 33.0,
 0.0, 57.5, 25, NULL,
 'nestle', ARRAY['milkybar', 'milky bar', 'nestle milkybar', 'milky bar white chocolate'],
 'chocolate', 'Nestle', 1, '552 cal/100g. Per 25g bar: 138 cal. White chocolate bar made with milk.', TRUE),

-- Roasted Almonds (generic plain): per 100g: 598 cal, 21.0P, 19.5C, 52.5F, 11.8 fiber, 4.4 sugar.
('roasted_almonds_plain', 'Roasted Almonds (Plain)', 598, 21.0, 19.5, 52.5,
 11.8, 4.4, 28, NULL,
 'usda', ARRAY['roasted almonds', 'plain roasted almonds', 'dry roasted almonds', 'unsalted almonds'],
 'nuts_seeds', NULL, 1, '598 cal/100g. Per 28g: 167 cal. Excellent source of vitamin E, magnesium, fiber.', TRUE),

-- Mixed Nuts Unsalted: per 100g: 594 cal, 18.0P, 22.0C, 52.0F, 6.5 fiber, 4.5 sugar.
('mixed_nuts_unsalted', 'Mixed Nuts (Unsalted)', 594, 18.0, 22.0, 52.0,
 6.5, 4.5, 28, NULL,
 'usda', ARRAY['mixed nuts', 'unsalted mixed nuts', 'mixed nuts no salt', 'plain mixed nuts'],
 'nuts_seeds', NULL, 1, '594 cal/100g. Per 28g: 166 cal. Almonds, cashews, brazils, pecans, walnuts.', TRUE),

-- Pumpkin Seeds (Pepitas): per 100g: 559 cal, 30.2P, 10.7C, 49.1F, 6.0 fiber, 1.4 sugar.
('pumpkin_seeds', 'Pumpkin Seeds (Pepitas)', 559, 30.2, 10.7, 49.1,
 6.0, 1.4, 28, NULL,
 'usda', ARRAY['pumpkin seeds', 'pepitas', 'roasted pumpkin seeds', 'pepitas pumpkin seeds'],
 'nuts_seeds', NULL, 1, '559 cal/100g. Per 28g: 157 cal. Excellent source of magnesium, zinc, iron. Keto-friendly.', TRUE),

-- Macadamia Nuts: per 100g: 718 cal, 7.9P, 13.8C, 75.8F, 8.6 fiber, 4.6 sugar.
('macadamia_nuts', 'Macadamia Nuts Roasted & Salted', 718, 7.9, 13.8, 75.8,
 8.6, 4.6, 28, NULL,
 'usda', ARRAY['macadamia nuts', 'macadamias', 'roasted macadamia nuts', 'mac nuts'],
 'nuts_seeds', NULL, 1, '718 cal/100g. Per 28g: 201 cal. Highest calorie nut. Very high MUFA. Buttery, rich flavor.', TRUE),

-- Brazil Nuts: per 100g: 659 cal, 14.3P, 11.7C, 67.1F, 7.5 fiber, 2.3 sugar.
('brazil_nuts', 'Brazil Nuts', 659, 14.3, 11.7, 67.1,
 7.5, 2.3, 28, NULL,
 'usda', ARRAY['brazil nuts', 'brazil nut', 'para nuts'],
 'nuts_seeds', NULL, 1, '659 cal/100g. Per 28g (6 nuts): 185 cal. Richest food source of selenium. 1-2 nuts provides daily selenium need.', TRUE),

-- Coconut Oil (for completeness): per 100g: 862 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('coconut_oil', 'Coconut Oil (Virgin)', 862, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['coconut oil', 'virgin coconut oil', 'extra virgin coconut oil', 'cold pressed coconut oil'],
 'oils_fats', NULL, 1, '862 cal/100g. Traditional fat — no omega-6. 82% saturated (mostly MCTs: lauric, capric, caprylic acid). High smoke point (350F). NOT a seed oil.', TRUE),

-- Olive Oil (for completeness): per 100g: 884 cal, 0.0P, 0.0C, 100.0F, 0.0 fiber, 0.0 sugar.
('olive_oil', 'Extra Virgin Olive Oil', 884, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'usda', ARRAY['olive oil', 'extra virgin olive oil', 'evoo', 'cold pressed olive oil'],
 'oils_fats', NULL, 1, '884 cal/100g. Traditional fat — low omega-6:omega-3 ratio (~13:1). 73% MUFA (oleic acid). Rich in polyphenols. Gold standard cooking oil. NOT a seed oil.', TRUE)

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
