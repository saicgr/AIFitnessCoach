-- ============================================================================
-- 278_overrides_korean.sql
-- Generated: 2026-02-28
-- Total items: 49 Korean cuisine dishes
-- Sources: USDA FoodData Central, nutritionvalue.org, nutritionix.com,
--          snapcalorie.com, fatsecret.com, eatthismuch.com,
--          bonchon.com, bbqchicken.com, mykoreankitchen.com
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES

-- ============================================================================
-- RICE DISHES
-- ============================================================================

-- Bibimbap: ~79 cal/100g (USDA 58150100). Typical mixed rice bowl with
-- vegetables, egg, gochujang. Serving ~500g bowl.
('bibimbap', 'Bibimbap', 79, 5.4, 8.3, 2.8,
  1.2, 1.5,
  NULL, 500,
  'korean_cuisine', ARRAY['bibimbop', 'bi bim bap', 'korean mixed rice', 'dolsot bibimbap', 'stone pot bibimbap'],
  '~395 cal per 500g bowl. Stone-pot version (dolsot) similar calories.',
  NULL, 'korean', 1),

-- Kimchi Fried Rice: ~152 cal/100g. Stir-fried rice with kimchi, sesame oil,
-- often topped with egg. Serving ~300g plate.
('kimchi_fried_rice', 'Kimchi Fried Rice', 152, 5.0, 20.0, 5.5,
  1.0, 2.0,
  NULL, 300,
  'korean_cuisine', ARRAY['kimchi bokkeumbap', 'kimchi bokkeum bap', 'kimchi rice', 'bokkeumbap'],
  '~456 cal per 300g serving.',
  NULL, 'korean', 1),

-- Japchae: ~133 cal/100g. Sweet potato glass noodles stir-fried with vegetables,
-- sesame oil, soy sauce. Serving ~250g.
('japchae', 'Japchae', 133, 3.2, 22.0, 3.5,
  1.5, 5.0,
  NULL, 250,
  'korean_cuisine', ARRAY['chapchae', 'glass noodles', 'korean glass noodles', 'sweet potato noodles', 'jabchae'],
  '~333 cal per 250g serving. As banchan side, ~100g.',
  NULL, 'korean', 1),

-- Kimbap: ~150 cal/100g. Seaweed rice rolls with vegetables, egg, pickled radish.
-- One roll ~250g, typically cut into 8 pieces (~31g each).
('kimbap', 'Kimbap', 150, 5.0, 25.0, 3.5,
  1.0, 2.5,
  31, 250,
  'korean_cuisine', ARRAY['gimbap', 'kim bap', 'gim bap', 'korean sushi roll', 'korean rice roll'],
  '~375 cal per roll (250g). 8 pieces per roll at ~31g each.',
  NULL, 'korean', 8),

-- Bokkeumbap (generic fried rice): ~155 cal/100g. Various Korean fried rice.
-- Serving ~300g.
('korean_fried_rice', 'Korean Fried Rice (Bokkeumbap)', 155, 5.5, 21.0, 5.0,
  0.8, 1.5,
  NULL, 300,
  'korean_cuisine', ARRAY['bokkeumbap', 'bokkeum bap', 'korean fried rice'],
  '~465 cal per 300g serving.',
  NULL, 'korean', 1),

-- ============================================================================
-- BBQ / GRILLED MEATS
-- ============================================================================

-- Bulgogi: ~188 cal/100g. Marinated thin-sliced beef, grilled. High protein.
-- Serving ~200g of meat.
('bulgogi', 'Bulgogi (Marinated Beef)', 188, 18.0, 8.0, 9.0,
  0.3, 5.0,
  NULL, 200,
  'korean_cuisine', ARRAY['bul go gi', 'korean bbq beef', 'marinated beef', 'fire meat', 'bulgogi beef'],
  '~376 cal per 200g serving. Sweet soy-based marinade.',
  NULL, 'korean', 1),

-- Galbi: ~233 cal/100g. Marinated beef short ribs, grilled. Higher fat than
-- bulgogi due to rib cut. Serving ~200g with bone.
('galbi', 'Galbi (Beef Short Ribs)', 233, 16.5, 6.5, 16.0,
  0.2, 4.0,
  NULL, 200,
  'korean_cuisine', ARRAY['kalbi', 'kal bi', 'galbi gui', 'korean short ribs', 'la galbi', 'beef galbi'],
  '~466 cal per 200g serving. LA galbi is cross-cut; standard is flanken-cut.',
  NULL, 'korean', 1),

-- Samgyeopsal: ~300 cal/100g. Grilled thick-sliced pork belly. Very high fat.
-- Typical serving ~150g of raw meat (shrinks with grilling).
('samgyeopsal', 'Samgyeopsal (Grilled Pork Belly)', 300, 20.0, 0.5, 24.0,
  0.0, 0.0,
  NULL, 150,
  'korean_cuisine', ARRAY['samgyupsal', 'sam gyeop sal', 'korean pork belly', 'grilled pork belly', 'thick pork belly'],
  '~450 cal per 150g serving. Usually wrapped in lettuce with ssamjang.',
  NULL, 'korean', 1),

-- Dak Galbi: ~140 cal/100g. Spicy stir-fried chicken with vegetables, gochujang,
-- rice cakes. Shared dish. Serving ~350g per person.
('dak_galbi', 'Dak Galbi (Spicy Chicken Stir-fry)', 140, 11.0, 13.0, 5.0,
  1.5, 3.5,
  NULL, 350,
  'korean_cuisine', ARRAY['dakgalbi', 'dak kal bi', 'chuncheon dakgalbi', 'spicy chicken stir fry', 'cheese dakgalbi'],
  '~490 cal per 350g serving. Often finished with fried rice.',
  NULL, 'korean', 1),

-- ============================================================================
-- STEWS & SOUPS (Jjigae / Guk / Tang)
-- ============================================================================

-- Kimchi Jjigae: ~50 cal/100g. Fermented kimchi stew with tofu and pork.
-- Very broth-heavy, low cal density. Serving ~400g bowl.
('kimchi_jjigae', 'Kimchi Jjigae (Kimchi Stew)', 50, 4.5, 3.0, 2.5,
  0.8, 1.0,
  NULL, 400,
  'korean_cuisine', ARRAY['kimchi jigae', 'kimchi chigae', 'kimchi stew', 'kimchi soup'],
  '~200 cal per 400g bowl. Served bubbling with rice on the side.',
  NULL, 'soups', 1),

-- Sundubu Jjigae: ~55 cal/100g. Spicy soft tofu stew, often with seafood or
-- pork. Served bubbling. Serving ~400g bowl.
('sundubu_jjigae', 'Sundubu Jjigae (Soft Tofu Stew)', 55, 4.5, 3.5, 2.5,
  0.5, 1.0,
  NULL, 400,
  'korean_cuisine', ARRAY['soondubu jjigae', 'soondubu', 'sundubu', 'soft tofu stew', 'silken tofu stew', 'soon tofu'],
  '~220 cal per 400g bowl. Usually has a raw egg cracked in.',
  NULL, 'soups', 1),

-- Doenjang Jjigae: ~52 cal/100g. Fermented soybean paste stew with tofu,
-- zucchini, potatoes. Serving ~400g bowl.
('doenjang_jjigae', 'Doenjang Jjigae (Soybean Paste Stew)', 52, 3.5, 4.5, 2.5,
  1.0, 1.0,
  NULL, 400,
  'korean_cuisine', ARRAY['dwaenjang jjigae', 'doen jang jigae', 'soybean paste stew', 'korean miso stew', 'bean paste stew'],
  '~208 cal per 400g bowl. Rich umami flavor from fermented paste.',
  NULL, 'soups', 1),

-- Budae Jjigae: ~110 cal/100g. Army stew with spam, sausage, ramen noodles,
-- kimchi, baked beans, cheese. Heavier than other jjigae. Serving ~500g.
('budae_jjigae', 'Budae Jjigae (Army Stew)', 110, 6.0, 9.0, 5.5,
  1.0, 2.0,
  NULL, 500,
  'korean_cuisine', ARRAY['army stew', 'budae jigae', 'army base stew', 'korean army stew'],
  '~550 cal per 500g serving. Shared communal stew with many ingredients.',
  NULL, 'soups', 1),

-- Tteokguk: ~82 cal/100g. Rice cake soup in beef broth with egg, seaweed.
-- Traditional New Year dish. Serving ~450g bowl.
('tteokguk', 'Tteokguk (Rice Cake Soup)', 82, 4.5, 12.0, 1.8,
  0.3, 0.5,
  NULL, 450,
  'korean_cuisine', ARRAY['tteok guk', 'rice cake soup', 'duk guk', 'new year rice cake soup', 'dduk guk'],
  '~369 cal per 450g bowl. Traditional Korean New Year dish.',
  NULL, 'soups', 1),

-- Seolleongtang: ~38 cal/100g. Milky ox bone soup, very light, broth-heavy.
-- Served with rice and salt to taste. Serving ~500g bowl (broth + meat).
('seolleongtang', 'Seolleongtang (Ox Bone Soup)', 38, 5.0, 1.0, 1.5,
  0.0, 0.0,
  NULL, 500,
  'korean_cuisine', ARRAY['sul lung tang', 'seol leong tang', 'ox bone soup', 'beef bone soup', 'korean bone broth'],
  '~190 cal per 500g bowl. Milky white broth, 12+ hours of simmering.',
  NULL, 'soups', 1),

-- Gamjatang: ~80 cal/100g. Pork bone stew with potatoes and perilla leaves.
-- Spicy and hearty. Serving ~450g.
('gamjatang', 'Gamjatang (Pork Bone Stew)', 80, 7.0, 4.0, 4.0,
  1.0, 1.0,
  NULL, 450,
  'korean_cuisine', ARRAY['gamja tang', 'pork bone stew', 'pork backbone stew', 'potato pork stew'],
  '~360 cal per 450g serving. Bone-in pork with potatoes.',
  NULL, 'soups', 1),

-- Samgyetang: ~83 cal/100g. Whole young chicken stuffed with ginseng, rice,
-- jujubes. One chicken per person. Serving ~600g (chicken + broth).
('samgyetang', 'Samgyetang (Ginseng Chicken Soup)', 83, 10.0, 3.3, 2.7,
  0.2, 0.5,
  NULL, 600,
  'korean_cuisine', ARRAY['sam gye tang', 'ginseng chicken soup', 'korean chicken soup', 'whole chicken soup'],
  '~498 cal per 600g serving. One small whole chicken per bowl.',
  NULL, 'soups', 1),

-- ============================================================================
-- NOODLES
-- ============================================================================

-- Jajangmyeon: ~122 cal/100g. Noodles in black bean sauce with diced pork and
-- vegetables. Serving ~450g bowl.
('jajangmyeon', 'Jajangmyeon (Black Bean Noodles)', 122, 4.0, 19.0, 3.0,
  1.0, 3.0,
  NULL, 450,
  'korean_cuisine', ARRAY['jjajangmyeon', 'jja jang myeon', 'black bean noodles', 'korean black bean noodles', 'zhajiangmian korean'],
  '~549 cal per 450g bowl. Korean-Chinese fusion dish.',
  NULL, 'korean', 1),

-- Naengmyeon: ~95 cal/100g. Cold buckwheat noodles in chilled broth (mul) or
-- spicy sauce (bibim). Serving ~500g.
('naengmyeon', 'Naengmyeon (Cold Noodles)', 95, 3.5, 18.0, 0.5,
  0.8, 2.0,
  NULL, 500,
  'korean_cuisine', ARRAY['naeng myeon', 'cold noodles', 'mul naengmyeon', 'bibim naengmyeon', 'korean cold noodles', 'buckwheat noodles'],
  '~475 cal per 500g serving. Mul = broth, bibim = spicy.',
  NULL, 'korean', 1),

-- Ramyeon (Korean-style): ~440 cal/100g for DRY noodle block. Cooked with
-- broth, the per-100g of the prepared soup+noodles is ~85 cal.
-- Using prepared dish values. Serving ~550g (1 packet cooked).
('korean_ramyeon', 'Korean Ramyeon', 85, 3.0, 12.0, 2.8,
  0.5, 1.0,
  NULL, 550,
  'korean_cuisine', ARRAY['ramyun', 'korean ramen', 'shin ramyun', 'shin ramyeon', 'korean instant noodles'],
  '~468 cal per 550g prepared bowl. Values are for cooked soup, not dry block.',
  NULL, 'korean', 1),

-- ============================================================================
-- FRIED / CHICKEN
-- ============================================================================

-- Korean Fried Chicken (plain crispy): ~250 cal/100g. Double-fried for extra
-- crunch. Serving ~300g (~6 pieces).
('korean_fried_chicken', 'Korean Fried Chicken', 250, 18.0, 14.0, 13.0,
  0.5, 1.0,
  50, 300,
  'korean_cuisine', ARRAY['kfc korean', 'korean chicken', 'huraideu chikin', 'double fried chicken', 'crispy korean chicken'],
  '~750 cal per 300g serving (~6 pieces). Double-fried technique.',
  NULL, 'chicken', 6),

-- Yangnyeom Chicken: ~265 cal/100g. Korean fried chicken coated in sweet-spicy
-- gochujang-based sauce. Serving ~300g (~6 pieces).
('yangnyeom_chicken', 'Yangnyeom Chicken (Sweet-Spicy)', 265, 16.0, 20.0, 13.0,
  0.5, 10.0,
  50, 300,
  'korean_cuisine', ARRAY['yangnyum chicken', 'yang nyeom chikin', 'sweet spicy chicken', 'korean sweet chili chicken', 'sweet and spicy korean chicken'],
  '~795 cal per 300g serving. Sauce adds ~15 cal/100g over plain.',
  NULL, 'chicken', 6),

-- Hotteok: ~220 cal/100g. Sweet filled pancake, pan-fried. Brown sugar,
-- cinnamon, nut filling. One piece ~100g.
('hotteok', 'Hotteok (Sweet Korean Pancake)', 220, 4.0, 38.0, 5.5,
  1.0, 18.0,
  100, 100,
  'korean_cuisine', ARRAY['ho tteok', 'hoddeok', 'korean sweet pancake', 'korean sugar pancake'],
  '~220 cal per piece (100g). Street food, pan-fried with sweet filling.',
  NULL, 'korean', 1),

-- Twigim: ~175 cal/100g. Korean-style tempura, mixed vegetables and shrimp.
-- Assorted platter serving ~200g.
('twigim', 'Twigim (Korean Tempura)', 175, 4.0, 18.0, 9.5,
  1.5, 1.0,
  NULL, 200,
  'korean_cuisine', ARRAY['korean tempura', 'korean fried vegetables', 'yachae twigim', 'vegetable twigim'],
  '~350 cal per 200g assorted platter.',
  NULL, 'korean', 1),

-- ============================================================================
-- SIDE DISHES (Banchan)
-- ============================================================================

-- Kimchi: ~15 cal/100g (USDA). Fermented napa cabbage. Very low calorie.
-- Banchan serving ~50-80g.
('kimchi', 'Kimchi (Napa Cabbage)', 15, 1.1, 2.4, 0.5,
  1.6, 1.1,
  NULL, 80,
  'korean_cuisine', ARRAY['kimchee', 'gimchi', 'baechu kimchi', 'napa cabbage kimchi', 'korean kimchi', 'fermented cabbage'],
  '~12 cal per 80g banchan serving. USDA verified data.',
  NULL, 'sides', 1),

-- Tteokbokki: ~131 cal/100g. Spicy rice cakes in gochujang sauce. Popular
-- street food. Serving ~250g.
('tteokbokki', 'Tteokbokki (Spicy Rice Cakes)', 131, 3.5, 22.0, 3.5,
  0.5, 5.0,
  NULL, 250,
  'korean_cuisine', ARRAY['dukboki', 'ddeokbokki', 'tteok bokki', 'rice cake stir fry', 'spicy rice cakes', 'topokki'],
  '~328 cal per 250g serving. Often includes fish cakes.',
  NULL, 'korean', 1),

-- Mandu (steamed/pan-fried dumplings): ~210 cal/100g. Pork and vegetable
-- filling. One piece ~30g. Typical order is 5 pieces (150g).
('mandu', 'Mandu (Korean Dumplings)', 210, 9.0, 23.0, 8.5,
  1.0, 1.5,
  30, 150,
  'korean_cuisine', ARRAY['mandoo', 'korean dumplings', 'gun mandu', 'jjin mandu', 'mool mandu', 'fried mandu'],
  '~315 cal per 5-piece serving (150g). Gun=pan-fried, jjin=steamed, mool=boiled.',
  NULL, 'korean', 5),

-- Kimchi Mandu: ~200 cal/100g. Dumplings with kimchi and pork filling.
-- One piece ~30g. Typical order 5 pieces.
('kimchi_mandu', 'Kimchi Mandu (Kimchi Dumplings)', 200, 8.0, 22.0, 8.0,
  1.2, 1.5,
  30, 150,
  'korean_cuisine', ARRAY['kimchi mandoo', 'kimchi dumpling', 'kimchi dumplings'],
  '~300 cal per 5-piece serving (150g).',
  NULL, 'korean', 5),

-- Pajeon: ~210 cal/100g. Scallion pancake, pan-fried. Can include seafood.
-- One pancake ~200g, cut into wedges.
('pajeon', 'Pajeon (Scallion Pancake)', 210, 5.0, 28.0, 8.5,
  1.5, 1.5,
  NULL, 200,
  'korean_cuisine', ARRAY['pa jeon', 'korean pancake', 'scallion pancake', 'haemul pajeon', 'seafood pajeon', 'green onion pancake'],
  '~420 cal per whole pancake (200g). Haemul pajeon includes seafood.',
  NULL, 'korean', 1),

-- Gyeran-jjim: ~72 cal/100g. Fluffy steamed egg custard with scallions.
-- Light side dish. Serving ~200g.
('gyeran_jjim', 'Gyeran-jjim (Korean Steamed Egg)', 72, 5.5, 1.5, 5.0,
  0.1, 0.5,
  NULL, 200,
  'korean_cuisine', ARRAY['gyeran jjim', 'steamed egg', 'korean egg custard', 'korean steamed eggs', 'egg jjim'],
  '~144 cal per 200g serving. Fluffy egg-to-water ratio.',
  NULL, 'sides', 1),

-- Japchae (as banchan side dish - smaller portion): already covered above.
-- Kongnamul (Bean Sprout Side): ~28 cal/100g. Simple seasoned bean sprouts.
('kongnamul', 'Kongnamul (Seasoned Bean Sprouts)', 28, 2.5, 3.0, 0.8,
  1.5, 0.5,
  NULL, 80,
  'korean_cuisine', ARRAY['kong namul', 'korean bean sprouts', 'seasoned bean sprouts', 'soybean sprout side dish'],
  '~22 cal per 80g banchan serving. Common banchan side.',
  NULL, 'sides', 1),

-- Sigeumchi Namul (Spinach Side): ~35 cal/100g. Blanched and seasoned spinach.
('sigeumchi_namul', 'Sigeumchi Namul (Seasoned Spinach)', 35, 3.0, 2.5, 1.5,
  2.0, 0.3,
  NULL, 80,
  'korean_cuisine', ARRAY['spinach namul', 'korean spinach side', 'seasoned spinach', 'sigumchi namul'],
  '~28 cal per 80g banchan serving.',
  NULL, 'sides', 1),

-- Oi Muchim (Spicy Cucumber Salad): ~25 cal/100g.
('oi_muchim', 'Oi Muchim (Spicy Cucumber Salad)', 25, 1.0, 4.0, 0.5,
  0.8, 2.0,
  NULL, 80,
  'korean_cuisine', ARRAY['cucumber salad korean', 'spicy cucumber', 'oi sobagi', 'korean cucumber side'],
  '~20 cal per 80g banchan serving.',
  NULL, 'sides', 1),

-- Danmuji (Pickled Yellow Radish): ~30 cal/100g.
('danmuji', 'Danmuji (Pickled Yellow Radish)', 30, 0.5, 7.0, 0.1,
  0.5, 5.0,
  NULL, 50,
  'korean_cuisine', ARRAY['takuan', 'pickled radish', 'yellow pickled radish', 'danmoo ji'],
  '~15 cal per 50g serving. Common accompaniment to kimbap.',
  NULL, 'sides', 1),

-- ============================================================================
-- ADDITIONAL POPULAR ITEMS
-- ============================================================================

-- Soy Garlic Korean Fried Chicken: ~240 cal/100g. Fried chicken glazed with
-- soy garlic sauce. Serving ~300g.
('soy_garlic_chicken', 'Soy Garlic Korean Fried Chicken', 240, 17.0, 16.0, 12.0,
  0.3, 6.0,
  50, 300,
  'korean_cuisine', ARRAY['soy garlic chicken', 'ganjang chikin', 'garlic soy fried chicken'],
  '~720 cal per 300g serving (~6 pieces).',
  NULL, 'chicken', 6),

-- Kimchi Jeon (Kimchi Pancake): ~185 cal/100g. Pan-fried kimchi pancake.
-- One pancake ~180g.
('kimchi_jeon', 'Kimchi Jeon (Kimchi Pancake)', 185, 5.0, 22.0, 8.0,
  1.5, 2.0,
  NULL, 180,
  'korean_cuisine', ARRAY['kimchi pancake', 'kimchijeon', 'kimchi buchimgae', 'kimchi jun'],
  '~333 cal per pancake (180g).',
  NULL, 'korean', 1),

-- Sundubu (plain soft tofu, as served without stew): ~55 cal/100g.
-- Haemul Pajeon (Seafood Scallion Pancake): ~220 cal/100g.
('haemul_pajeon', 'Haemul Pajeon (Seafood Pancake)', 220, 8.0, 24.0, 9.5,
  1.0, 1.5,
  NULL, 250,
  'korean_cuisine', ARRAY['seafood pajeon', 'haemul jeon', 'seafood korean pancake', 'mixed seafood pancake'],
  '~550 cal per pancake (250g). Shrimp, squid, and scallions.',
  NULL, 'korean', 1),

-- Dakgangjeong (Crispy Sweet Chicken): ~270 cal/100g. Bite-size crispy chicken
-- with sweet soy glaze.
('dakgangjeong', 'Dakgangjeong (Sweet Crispy Chicken)', 270, 15.0, 22.0, 14.0,
  0.3, 12.0,
  NULL, 250,
  'korean_cuisine', ARRAY['dak gang jeong', 'korean sweet crispy chicken', 'glazed fried chicken'],
  '~675 cal per 250g serving.',
  NULL, 'chicken', 1),

-- Japchae Bap (Japchae over rice): ~140 cal/100g. Glass noodles served on
-- steamed rice.
('japchae_bap', 'Japchae Bap (Japchae Rice Bowl)', 140, 4.0, 24.0, 3.0,
  1.0, 3.0,
  NULL, 400,
  'korean_cuisine', ARRAY['japchae rice', 'japchae over rice', 'japchae bap'],
  '~560 cal per 400g bowl.',
  NULL, 'korean', 1),

-- ============================================================================
-- BONCHON (Korean Fried Chicken Chain)
-- Source: bonchon.com nutritional information, fatsecret.com
-- ============================================================================

-- Bonchon Soy Garlic Wings: Per piece (~50g) = 147 cal from official data.
-- That is ~294 cal/100g.
('bonchon_soy_garlic_wings', 'Bonchon Soy Garlic Wings', 294, 17.0, 13.0, 19.0,
  0.3, 5.0,
  50, 300,
  'korean_cuisine', ARRAY['bonchon soy garlic', 'bonchon wings soy garlic'],
  '~882 cal per 6-piece serving (300g).',
  'Bonchon', 'chicken', 6),

-- Bonchon Spicy Wings: Similar calories to soy garlic, slightly more sugar
-- from gochujang sauce. ~290 cal/100g.
('bonchon_spicy_wings', 'Bonchon Spicy Wings', 290, 16.5, 14.0, 18.5,
  0.5, 6.0,
  50, 300,
  'korean_cuisine', ARRAY['bonchon spicy', 'bonchon wings spicy'],
  '~870 cal per 6-piece serving (300g).',
  'Bonchon', 'chicken', 6),

-- Bonchon Drumsticks Soy Garlic: Larger pieces ~80g each.
('bonchon_soy_garlic_drumsticks', 'Bonchon Soy Garlic Drumsticks', 260, 18.0, 10.0, 16.0,
  0.2, 4.5,
  80, 320,
  'korean_cuisine', ARRAY['bonchon drumstick soy garlic', 'bonchon drums'],
  '~832 cal per 4-piece serving (320g).',
  'Bonchon', 'chicken', 4),

-- Bonchon Chicken Sandwich: ~230 cal/100g. Single sandwich ~220g.
('bonchon_chicken_sandwich', 'Bonchon Chicken Sandwich', 230, 13.0, 22.0, 10.5,
  1.0, 4.0,
  220, 220,
  'korean_cuisine', ARRAY['bonchon sandwich', 'bonchon crispy chicken sandwich'],
  '~506 cal per sandwich (220g).',
  'Bonchon', 'chicken', 1),

-- Bonchon Bibimbap Bowl: ~115 cal/100g. Rice bowl ~450g.
('bonchon_bibimbap', 'Bonchon Bibimbap Bowl', 115, 6.0, 15.0, 3.5,
  1.0, 2.0,
  NULL, 450,
  'korean_cuisine', ARRAY['bonchon bibimbap', 'bonchon rice bowl'],
  '~518 cal per bowl (450g).',
  'Bonchon', 'korean', 1),

-- Bonchon Japchae: ~130 cal/100g. Noodle side ~200g.
('bonchon_japchae', 'Bonchon Japchae', 130, 3.0, 21.0, 3.5,
  1.5, 4.5,
  NULL, 200,
  'korean_cuisine', ARRAY['bonchon glass noodles', 'bonchon japchae side'],
  '~260 cal per serving (200g).',
  'Bonchon', 'sides', 1),

-- ============================================================================
-- BB.Q CHICKEN (Korean Fried Chicken Chain)
-- Source: bbqchicken.com nutrition PDF
-- ============================================================================

-- bb.q Golden Original: ~255 cal/100g. Classic Korean fried chicken.
('bbq_chicken_golden_original', 'bb.q Chicken Golden Original', 255, 19.0, 12.0, 14.5,
  0.3, 0.5,
  50, 300,
  'korean_cuisine', ARRAY['bbq chicken original', 'bbq golden original', 'bb.q original chicken'],
  '~765 cal per 6-piece serving (300g).',
  'bb.q Chicken', 'chicken', 6),

-- bb.q Honey Garlic: ~270 cal/100g. Honey garlic glazed.
('bbq_chicken_honey_garlic', 'bb.q Chicken Honey Garlic', 270, 17.0, 18.0, 14.0,
  0.3, 8.0,
  50, 300,
  'korean_cuisine', ARRAY['bbq honey garlic', 'bb.q honey garlic chicken'],
  '~810 cal per 6-piece serving (300g).',
  'bb.q Chicken', 'chicken', 6),

-- bb.q Gangnam Style Wings (spicy): ~260 cal/100g.
('bbq_chicken_gangnam_wings', 'bb.q Chicken Gangnam Style Wings', 260, 17.5, 15.0, 14.5,
  0.5, 5.0,
  50, 300,
  'korean_cuisine', ARRAY['bbq gangnam wings', 'bb.q spicy wings', 'bbq chicken spicy'],
  '~780 cal per 6-piece serving (300g).',
  'bb.q Chicken', 'chicken', 6),

-- bb.q Secret Sauce Wings: ~275 cal/100g.
('bbq_chicken_secret_sauce', 'bb.q Chicken Secret Sauce Wings', 275, 16.5, 19.0, 15.0,
  0.3, 9.0,
  50, 300,
  'korean_cuisine', ARRAY['bbq secret sauce', 'bb.q secret sauce chicken'],
  '~825 cal per 6-piece serving (300g).',
  'bb.q Chicken', 'chicken', 6)

ON CONFLICT (food_name_normalized) DO NOTHING;
