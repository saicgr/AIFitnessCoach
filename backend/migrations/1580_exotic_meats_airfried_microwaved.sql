-- 1580_exotic_meats_airfried_microwaved.sql
-- Adds exotic/game meats, air-fried variants, and microwaved food entries.
-- Sources: USDA FoodData Central, nutritionvalue.org, fatsecret.com, calorieking.com.
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
-- A. EXOTIC / GAME MEATS
-- ==========================================

-- Venison (deer, roasted): per 100g USDA: 158 cal, 30.2P, 0C, 3.2F
('venison_roasted', 'Venison (Roasted)', 158, 30.2, 0.0, 3.2,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['venison', 'deer meat', 'venison steak', 'roasted venison', 'venison roast', 'deer steak', 'venison loin'],
 'proteins', NULL, 1, '158 cal/100g. Very lean red meat. Higher in iron than beef. Low fat, high protein game meat.', TRUE),

-- Venison (Ground, cooked)
('venison_ground', 'Venison (Ground)', 187, 26.5, 0.0, 8.2,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground venison', 'venison mince', 'minced deer meat', 'venison burger meat', 'deer ground meat'],
 'proteins', NULL, 1, '187 cal/100g. Leaner than ground beef. Per 3 oz (85g): 159 cal.', TRUE),

-- Venison Jerky
('venison_jerky', 'Venison Jerky', 390, 50.0, 8.0, 16.0,
 0.0, 6.0, 28, NULL,
 'usda', ARRAY['venison jerky', 'deer jerky', 'game jerky', 'venison dried'],
 'proteins', NULL, 1, '390 cal/100g. 1 oz (28g): 109 cal. Concentrated lean protein snack.', TRUE),

-- Bison (roasted): per 100g USDA: 143 cal, 28.4P, 0C, 2.4F
('bison_roasted', 'Bison (Roasted)', 143, 28.4, 0.0, 2.4,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['bison', 'bison steak', 'buffalo meat', 'roasted bison', 'american buffalo', 'bison roast', 'bison tenderloin'],
 'proteins', NULL, 1, '143 cal/100g. Leaner than beef with more protein. Rich in B12, iron, zinc. Grass-fed standard.', TRUE),

-- Bison (Ground, cooked)
('bison_ground', 'Bison (Ground)', 182, 25.5, 0.0, 8.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground bison', 'bison mince', 'minced bison', 'bison burger', 'buffalo burger meat', 'bison patty'],
 'proteins', NULL, 1, '182 cal/100g. Leaner than 80/20 ground beef (254 cal). Popular beef alternative.', TRUE),

-- Bison Jerky
('bison_jerky', 'Bison Jerky', 380, 48.0, 10.0, 15.0,
 0.0, 7.0, 28, NULL,
 'usda', ARRAY['bison jerky', 'buffalo jerky', 'bison dried meat'],
 'proteins', NULL, 1, '380 cal/100g. 1 oz (28g): 106 cal. Lean dried game meat snack.', TRUE),

-- Elk (roasted): per 100g USDA: 146 cal, 30.2P, 0C, 1.9F
('elk_roasted', 'Elk (Roasted)', 146, 30.2, 0.0, 1.9,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['elk', 'elk steak', 'elk meat', 'roasted elk', 'elk loin', 'elk roast', 'wapiti'],
 'proteins', NULL, 1, '146 cal/100g. One of the leanest red meats. 30g protein per 100g. Rich in B12 and iron.', TRUE),

-- Elk (Ground)
('elk_ground', 'Elk (Ground)', 164, 26.0, 0.0, 6.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground elk', 'elk mince', 'minced elk', 'elk burger meat'],
 'proteins', NULL, 1, '164 cal/100g. Very lean ground meat alternative. Per 3 oz (85g): 139 cal.', TRUE),

-- Ostrich (cooked): per 100g USDA: 155 cal, 27.6P, 0C, 4.2F
('ostrich_cooked', 'Ostrich (Cooked)', 155, 27.6, 0.0, 4.2,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ostrich', 'ostrich steak', 'ostrich meat', 'ostrich fillet', 'cooked ostrich', 'grilled ostrich'],
 'proteins', NULL, 1, '155 cal/100g. Tastes like lean beef but lower in fat. Red meat that is actually lean. Rich in iron.', TRUE),

-- Ostrich (Ground)
('ostrich_ground', 'Ostrich (Ground)', 175, 24.0, 0.0, 8.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground ostrich', 'ostrich mince', 'ostrich burger', 'minced ostrich'],
 'proteins', NULL, 1, '175 cal/100g. Ground ostrich is a popular lean burger alternative.', TRUE),

-- Kangaroo (cooked): per 100g: 140 cal, 28.0P, 0C, 2.5F
('kangaroo_cooked', 'Kangaroo (Cooked)', 140, 28.0, 0.0, 2.5,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['kangaroo', 'kangaroo steak', 'kangaroo meat', 'roo meat', 'grilled kangaroo', 'kangaroo fillet'],
 'proteins', NULL, 1, '140 cal/100g. Extremely lean, high protein. Popular in Australia. Low in fat, rich in iron and zinc.', TRUE),

-- Rabbit (roasted): per 100g USDA: 197 cal, 29.1P, 0C, 8.1F
('rabbit_roasted', 'Rabbit (Roasted)', 197, 29.1, 0.0, 8.1,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['rabbit', 'rabbit meat', 'roasted rabbit', 'rabbit stew meat', 'hare', 'bunny meat', 'khargosh'],
 'proteins', NULL, 1, '197 cal/100g. Lean, high protein white meat. Common in European and Mediterranean cuisine.', TRUE),

-- Goat (cooked): per 100g USDA: 143 cal, 27.1P, 0C, 3.0F
('goat_cooked', 'Goat (Cooked)', 143, 27.1, 0.0, 3.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['goat meat', 'goat', 'mutton goat', 'chevon', 'cabrito', 'bakri ka gosht', 'goat curry meat', 'goat stew meat'],
 'proteins', NULL, 1, '143 cal/100g. Leaner than beef, lamb, or pork. Popular worldwide. Rich in iron and B12.', TRUE),

-- Goat Curry (with gravy)
('goat_curry', 'Goat Curry', 165, 15.0, 5.0, 9.5,
 1.0, 1.5, 200, NULL,
 'usda', ARRAY['goat curry', 'mutton curry', 'bakri curry', 'lamb curry goat', 'spicy goat curry'],
 'prepared_meals', NULL, 1, '165 cal/100g including gravy. 1 serving (200g): 330 cal. Oil and spices add to base goat macros.', TRUE),

-- Wild Boar (roasted): per 100g USDA: 160 cal, 28.3P, 0C, 4.4F
('wild_boar_roasted', 'Wild Boar (Roasted)', 160, 28.3, 0.0, 4.4,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['wild boar', 'wild boar meat', 'boar meat', 'roasted wild boar', 'wild pig', 'feral hog'],
 'proteins', NULL, 1, '160 cal/100g. Leaner and more flavorful than domestic pork. Game meat rich in B vitamins.', TRUE),

-- Quail (cooked): per 100g USDA: 234 cal, 25.1P, 0C, 14.1F
('quail_cooked', 'Quail (Cooked)', 234, 25.1, 0.0, 14.1,
 0.0, 0.0, 110, 110,
 'usda', ARRAY['quail', 'quail meat', 'roasted quail', 'grilled quail', 'bater', 'quail whole'],
 'proteins', NULL, 1, '234 cal/100g. 1 whole quail (110g): 257 cal. Small game bird, richer than chicken.', TRUE),

-- Pheasant (cooked): per 100g USDA: 239 cal, 32.4P, 0C, 11.2F
('pheasant_cooked', 'Pheasant (Cooked)', 239, 32.4, 0.0, 11.2,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['pheasant', 'pheasant meat', 'roasted pheasant', 'pheasant breast'],
 'proteins', NULL, 1, '239 cal/100g. Game bird with rich flavor. Higher fat than chicken breast, very high protein.', TRUE),

-- Duck Breast (skinless, cooked): per 100g USDA: 201 cal, 23.5P, 0C, 11.2F
('duck_breast_skinless', 'Duck Breast (Skinless)', 201, 23.5, 0.0, 11.2,
 0.0, 0.0, 100, NULL,
 'usda', ARRAY['duck breast', 'skinless duck breast', 'duck breast no skin', 'duck fillet', 'duck breast cooked'],
 'proteins', NULL, 1, '201 cal/100g without skin. Much leaner than with skin (337 cal). Rich, deep flavor.', TRUE),

-- Alligator (cooked): per 100g: 143 cal, 29.9P, 0C, 2.6F
('alligator_cooked', 'Alligator (Cooked)', 143, 29.9, 0.0, 2.6,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['alligator', 'alligator meat', 'gator meat', 'fried alligator', 'alligator tail', 'crocodile meat'],
 'proteins', NULL, 1, '143 cal/100g. Very lean, mild white meat. Tastes between chicken and fish. Popular in Southern US.', TRUE),

-- Frog Legs (fried): per 100g: 175 cal, 18.5P, 6.5, 8.2F
('frog_legs_fried', 'Frog Legs (Fried)', 175, 18.5, 6.5, 8.2,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['frog legs', 'fried frog legs', 'frog leg', 'cuisses de grenouille'],
 'proteins', NULL, 1, '175 cal/100g fried. Delicate flavor similar to chicken. French and Asian delicacy.', TRUE),

-- Yak (cooked): per 100g: 138 cal, 28.0P, 0C, 2.4F
('yak_cooked', 'Yak (Cooked)', 138, 28.0, 0.0, 2.4,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['yak', 'yak meat', 'yak steak', 'yak burger', 'ground yak'],
 'proteins', NULL, 1, '138 cal/100g. Extremely lean red meat. Similar to bison. Rich in omega-3 and CLA.', TRUE),

-- Emu (cooked): per 100g: 150 cal, 27.0P, 0C, 4.0F
('emu_cooked', 'Emu (Cooked)', 150, 27.0, 0.0, 4.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['emu', 'emu meat', 'emu steak', 'emu fillet'],
 'proteins', NULL, 1, '150 cal/100g. Similar to ostrich — lean red meat bird. Rich in iron and B12.', TRUE),

-- Bison Steak (grilled)
('bison_steak_grilled', 'Bison Steak (Grilled)', 155, 29.0, 0.0, 3.5,
 0.0, 0.0, 170, NULL,
 'usda', ARRAY['bison steak', 'grilled bison steak', 'buffalo steak', 'bison ribeye', 'bison sirloin'],
 'proteins', NULL, 1, '155 cal/100g. 1 steak (170g): 264 cal. Leaner than beef steak. Grass-fed standard.', TRUE),

-- Lamb (Ground, cooked)
('lamb_ground', 'Lamb (Ground)', 283, 24.8, 0.0, 19.7,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['ground lamb', 'lamb mince', 'minced lamb', 'lamb keema', 'lamb burger meat', 'lamb kofta meat'],
 'proteins', NULL, 1, '283 cal/100g. Higher fat than ground beef. Per 3 oz (85g): 240 cal. Rich flavor for kofta, burgers.', TRUE),

-- Lamb Shank (braised)
('lamb_shank_braised', 'Lamb Shank (Braised)', 248, 28.5, 0.0, 14.0,
 0.0, 0.0, 200, NULL,
 'usda', ARRAY['lamb shank', 'braised lamb shank', 'lamb shanks', 'slow cooked lamb shank', 'lamb leg braised'],
 'proteins', NULL, 1, '248 cal/100g. 1 shank with bone (200g meat): 496 cal. Fall-off-the-bone tender.', TRUE),

-- ==========================================
-- B. AIR-FRIED VARIANTS
-- Air frying uses ~80% less oil than deep frying
-- ==========================================

-- Air-Fried Chicken Breast
('chicken_breast_air_fried', 'Chicken Breast (Air-Fried)', 180, 30.0, 2.0, 5.5,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['air fried chicken breast', 'air fryer chicken breast', 'chicken breast air fried', 'air fried chicken', 'airfried chicken breast'],
 'proteins', NULL, 1, '180 cal/100g. Air frying adds minimal oil (~15 cal vs grilled). Much less than deep fried (260 cal).', TRUE),

-- Air-Fried Chicken Wings
('chicken_wings_air_fried', 'Chicken Wings (Air-Fried)', 216, 20.5, 1.0, 14.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['air fried chicken wings', 'air fryer wings', 'chicken wings air fried', 'air fried wings', 'crispy air fryer wings'],
 'proteins', NULL, 1, '216 cal/100g. Per 4 wings (85g): 184 cal. Crispy without deep frying. Saves ~40 cal vs deep fried.', TRUE),

-- Air-Fried Chicken Thigh
('chicken_thigh_air_fried', 'Chicken Thigh (Air-Fried)', 225, 25.0, 1.5, 13.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['air fried chicken thigh', 'air fryer chicken thigh', 'chicken thigh air fried', 'crispy air fried thigh'],
 'proteins', NULL, 1, '225 cal/100g. Crispy skin, juicy meat. Less oil than deep fried (280 cal).', TRUE),

-- Air-Fried French Fries
('french_fries_air_fried', 'French Fries (Air-Fried)', 185, 2.8, 30.0, 6.0,
 2.5, 0.5, 117, NULL,
 'usda', ARRAY['air fried fries', 'air fryer fries', 'air fried french fries', 'air fryer french fries', 'air fried chips', 'airfried fries'],
 'vegetables', NULL, 1, '185 cal/100g. Saves ~130 cal vs deep fried (312 cal). Light oil spray only. Crispy exterior.', TRUE),

-- Air-Fried Sweet Potato Fries
('sweet_potato_fries_air_fried', 'Sweet Potato Fries (Air-Fried)', 155, 1.5, 28.0, 4.0,
 3.0, 5.5, 117, NULL,
 'usda', ARRAY['air fried sweet potato fries', 'air fryer sweet potato fries', 'air fried sweet potato', 'airfried sweet potato fries'],
 'vegetables', NULL, 1, '155 cal/100g. Saves ~105 cal vs deep fried (260 cal). Light oil spray, naturally sweet.', TRUE),

-- Air-Fried Fish
('fish_air_fried', 'Fish (Air-Fried)', 160, 21.0, 5.0, 6.0,
 0.3, 0.3, 100, NULL,
 'usda', ARRAY['air fried fish', 'air fryer fish', 'fish air fried', 'air fried fish fillet', 'crispy air fryer fish'],
 'proteins', NULL, 1, '160 cal/100g. Light breading with air frying. Saves ~70 cal vs deep fried battered fish (232 cal).', TRUE),

-- Air-Fried Salmon
('salmon_air_fried', 'Salmon (Air-Fried)', 215, 21.5, 0.0, 14.0,
 0.0, 0.0, 154, NULL,
 'usda', ARRAY['air fried salmon', 'air fryer salmon', 'salmon air fried', 'air fried salmon fillet'],
 'proteins', NULL, 1, '215 cal/100g. Similar to baked (208) with slightly more from oil spray. Much less than pan-fried (261).', TRUE),

-- Air-Fried Shrimp
('shrimp_air_fried', 'Shrimp (Air-Fried)', 145, 21.0, 5.0, 4.0,
 0.2, 0.2, 85, NULL,
 'usda', ARRAY['air fried shrimp', 'air fryer shrimp', 'shrimp air fried', 'crispy air fryer shrimp', 'air fried prawns'],
 'proteins', NULL, 1, '145 cal/100g. Light breading, minimal oil. Saves ~100 cal vs deep fried breaded shrimp (242).', TRUE),

-- Air-Fried Tofu
('tofu_air_fried', 'Tofu (Air-Fried)', 130, 11.0, 4.0, 8.0,
 0.5, 0.5, 126, NULL,
 'usda', ARRAY['air fried tofu', 'air fryer tofu', 'tofu air fried', 'crispy air fryer tofu', 'air fried crispy tofu'],
 'proteins', NULL, 1, '130 cal/100g. Crispy exterior without deep frying. Saves ~140 cal vs deep fried tofu (271).', TRUE),

-- Air-Fried Chicken Nuggets
('chicken_nuggets_air_fried', 'Chicken Nuggets (Air-Fried)', 220, 16.0, 14.0, 11.0,
 0.5, 0.5, 85, NULL,
 'usda', ARRAY['air fried chicken nuggets', 'air fryer nuggets', 'air fried nuggets', 'frozen nuggets air fried'],
 'proteins', NULL, 1, '220 cal/100g. Frozen nuggets cooked in air fryer. Saves ~50 cal vs deep fried (270 cal).', TRUE),

-- Air-Fried Mozzarella Sticks
('mozzarella_sticks_air_fried', 'Mozzarella Sticks (Air-Fried)', 260, 12.0, 20.0, 14.0,
 0.5, 1.5, 84, NULL,
 'usda', ARRAY['air fried mozzarella sticks', 'air fryer mozzarella sticks', 'air fried cheese sticks', 'air fryer mozz sticks'],
 'snacks', NULL, 1, '260 cal/100g. Per 3 sticks (84g): 218 cal. Less oil than deep fried but still calorie-dense from cheese.', TRUE),

-- Air-Fried Egg Rolls
('egg_rolls_air_fried', 'Egg Rolls (Air-Fried)', 195, 6.0, 22.0, 9.0,
 1.5, 2.0, 85, NULL,
 'usda', ARRAY['air fried egg rolls', 'air fryer egg rolls', 'air fried spring rolls', 'frozen egg rolls air fried'],
 'snacks', NULL, 1, '195 cal/100g. Per roll (85g): 166 cal. Crispy without deep frying. Saves ~60 cal vs deep fried.', TRUE),

-- Air-Fried Falafel
('falafel_air_fried', 'Falafel (Air-Fried)', 220, 10.0, 22.0, 10.0,
 4.0, 1.5, 17, 17,
 'usda', ARRAY['air fried falafel', 'air fryer falafel', 'falafel air fried', 'crispy air fried falafel'],
 'proteins', NULL, 1, '220 cal/100g. Per ball (17g): 37 cal. Saves ~60 cal vs deep fried falafel (280 cal/100g).', TRUE),

-- Air-Fried Cauliflower
('cauliflower_air_fried', 'Cauliflower (Air-Fried)', 85, 3.0, 8.0, 4.5,
 2.5, 2.0, 150, NULL,
 'usda', ARRAY['air fried cauliflower', 'air fryer cauliflower', 'cauliflower air fried', 'crispy cauliflower air fryer', 'buffalo cauliflower air fried'],
 'vegetables', NULL, 1, '85 cal/100g. Great low-cal crispy side dish. Light oil spray, natural crunch.', TRUE),

-- Air-Fried Brussels Sprouts
('brussels_sprouts_air_fried', 'Brussels Sprouts (Air-Fried)', 80, 3.5, 9.0, 3.5,
 3.5, 2.5, 150, NULL,
 'usda', ARRAY['air fried brussels sprouts', 'air fryer brussels sprouts', 'brussels sprouts air fried', 'crispy brussels sprouts air fryer'],
 'vegetables', NULL, 1, '80 cal/100g. Crispy, caramelized edges. Popular healthy side. Light oil spray.', TRUE),

-- Air-Fried Onion Rings
('onion_rings_air_fried', 'Onion Rings (Air-Fried)', 195, 3.5, 24.0, 9.5,
 1.5, 4.0, 85, NULL,
 'usda', ARRAY['air fried onion rings', 'air fryer onion rings', 'onion rings air fried'],
 'snacks', NULL, 1, '195 cal/100g. Saves ~100 cal vs deep fried onion rings (295 cal/100g). Still has breading.', TRUE),

-- ==========================================
-- C. MICROWAVED FOOD VARIANTS
-- ==========================================

-- Microwaved Potato (baked in microwave)
('potato_microwaved', 'Potato (Microwaved)', 93, 2.4, 21.5, 0.1,
 2.0, 1.0, 173, 173,
 'usda', ARRAY['microwaved potato', 'microwave baked potato', 'potato microwaved', 'microwave potato', 'quick baked potato'],
 'vegetables', NULL, 1, '93 cal/100g. Same macros as oven-baked. Faster (5-8 min vs 45-60 min). No added fat.', TRUE),

-- Microwaved Sweet Potato
('sweet_potato_microwaved', 'Sweet Potato (Microwaved)', 90, 2.0, 20.7, 0.1,
 3.3, 6.5, 114, 114,
 'usda', ARRAY['microwaved sweet potato', 'microwave sweet potato', 'sweet potato microwaved', 'quick sweet potato'],
 'vegetables', NULL, 1, '90 cal/100g. Same macros as oven-baked. Quick 5-7 min prep. No added fat.', TRUE),

-- Microwaved Broccoli (steamed in microwave)
('broccoli_microwaved', 'Broccoli (Microwaved)', 35, 2.4, 7.2, 0.4,
 3.3, 1.7, 150, NULL,
 'usda', ARRAY['microwaved broccoli', 'microwave steamed broccoli', 'broccoli microwaved', 'microwave broccoli'],
 'vegetables', NULL, 1, '35 cal/100g. Same as steamed. Microwave steaming preserves more nutrients than boiling.', TRUE),

-- Microwaved Rice (instant/pre-cooked pouches)
('rice_microwaved', 'Rice (Microwaved/Instant Pouch)', 140, 2.8, 30.0, 0.8,
 0.5, 0.0, 125, NULL,
 'usda', ARRAY['microwave rice', 'microwaved rice', 'instant rice microwave', 'uncle bens microwave rice', 'ready rice', 'minute rice microwave', 'rice pouch microwave'],
 'grains', NULL, 1, '140 cal/100g. Pouch rice slightly higher cal than plain (130) due to added oil. 1 pouch (125g): 175 cal.', TRUE),

-- Microwaved Oatmeal (instant)
('oatmeal_microwaved', 'Oatmeal (Microwaved/Instant)', 71, 2.5, 12.0, 1.5,
 1.5, 0.5, 234, NULL,
 'usda', ARRAY['microwave oatmeal', 'instant oatmeal', 'microwaved oatmeal', 'quick oats microwave', 'instant oats'],
 'grains', NULL, 1, '71 cal/100g prepared with water. 1 bowl (234g): 166 cal. Instant oats = same nutrition as rolled.', TRUE),

-- Microwaved Scrambled Eggs
('egg_scrambled_microwaved', 'Scrambled Eggs (Microwaved)', 149, 10.0, 1.5, 11.0,
 0.0, 1.4, 85, NULL,
 'usda', ARRAY['microwave scrambled eggs', 'microwaved scrambled eggs', 'scrambled eggs microwave', 'microwave eggs'],
 'proteins', NULL, 1, '149 cal/100g. Same macros as stove-top scrambled. Quick 1-2 min prep. Add splash of milk.', TRUE),

-- Microwaved Frozen Vegetables
('frozen_vegetables_microwaved', 'Frozen Vegetables (Microwaved)', 42, 2.5, 7.5, 0.3,
 2.8, 2.5, 150, NULL,
 'usda', ARRAY['microwaved frozen vegetables', 'microwave frozen veggies', 'steamed frozen vegetables', 'frozen mixed vegetables microwave', 'frozen veg microwave'],
 'vegetables', NULL, 1, '42 cal/100g. Retains most nutrients. Per 1 cup (150g): 63 cal. Quick healthy side.', TRUE),

-- Microwaved Popcorn
('popcorn_microwaved', 'Popcorn (Microwaved)', 443, 11.0, 55.0, 20.0,
 10.0, 0.5, 28, NULL,
 'usda', ARRAY['microwave popcorn', 'microwaved popcorn', 'popcorn microwave bag', 'buttered microwave popcorn', 'movie popcorn microwave'],
 'snacks', NULL, 1, '443 cal/100g popped. Per 1 oz bag (28g): 124 cal. Butter flavoring adds fat. Air-popped is only 387 cal.', TRUE),

-- Microwaved Mac and Cheese (from box)
('mac_and_cheese_microwaved', 'Mac and Cheese (Microwaved)', 164, 6.5, 19.0, 6.8,
 0.8, 2.5, 200, NULL,
 'usda', ARRAY['microwave mac and cheese', 'microwaved mac and cheese', 'easy mac microwave', 'mac n cheese microwave cup', 'kraft mac and cheese microwave'],
 'prepared_meals', NULL, 1, '164 cal/100g prepared. Per cup (200g): 328 cal. Single-serve microwave cups.', TRUE),

-- Microwaved Frozen Pizza (single serving)
('frozen_pizza_microwaved', 'Frozen Pizza (Microwaved)', 240, 10.0, 28.0, 10.0,
 1.5, 4.0, 170, NULL,
 'usda', ARRAY['microwave pizza', 'microwaved frozen pizza', 'frozen pizza microwave', 'hot pocket pizza', 'pizza pocket microwave'],
 'prepared_meals', NULL, 1, '240 cal/100g. Per single (170g): 408 cal. Quick meal. Often less crispy than oven-baked.', TRUE),

-- Microwaved Frozen Burrito
('frozen_burrito_microwaved', 'Frozen Burrito (Microwaved)', 195, 7.0, 24.0, 7.5,
 1.5, 1.0, 142, NULL,
 'usda', ARRAY['microwave burrito', 'frozen burrito microwave', 'microwaved burrito', 'el monterey burrito microwave', 'frozen bean burrito'],
 'prepared_meals', NULL, 1, '195 cal/100g. Per burrito (142g): 277 cal. Quick protein + carb meal.', TRUE),

-- Microwaved Frozen Meal (generic lean cuisine type)
('frozen_meal_microwaved', 'Frozen Meal (Microwaved, Lean)', 100, 8.0, 12.0, 2.5,
 1.5, 3.0, 255, NULL,
 'usda', ARRAY['microwave frozen dinner', 'lean cuisine microwave', 'frozen dinner microwave', 'healthy choice microwave', 'tv dinner microwave', 'frozen entree microwave'],
 'prepared_meals', NULL, 1, '100 cal/100g avg for lean varieties. Per meal (255g): 255 cal. Ranges 200-400 cal by brand.', TRUE),

-- Microwaved Hot Dog
('hot_dog_microwaved', 'Hot Dog (Microwaved)', 290, 10.5, 2.0, 26.0,
 0.0, 1.0, 52, 52,
 'usda', ARRAY['microwave hot dog', 'microwaved hot dog', 'hot dog microwave', 'quick hot dog'],
 'proteins', NULL, 1, '290 cal/100g. Per frank (52g): 151 cal. Same macros as boiled/grilled. Quick 30-60 sec prep.', TRUE),

-- Microwave Mug Cake
('mug_cake_microwaved', 'Mug Cake (Microwaved)', 325, 4.5, 45.0, 14.0,
 0.5, 28.0, 100, NULL,
 'usda', ARRAY['mug cake', 'microwave mug cake', 'mug cake microwave', 'single serve cake microwave', 'quick mug cake'],
 'desserts', NULL, 1, '325 cal/100g. Per mug cake (100g): 325 cal. Quick single-serve dessert. High sugar.', TRUE),

-- ==========================================
-- D. ADDITIONAL COOKING METHOD VARIANTS
-- ==========================================

-- Deep Fried Chicken Wings (traditional)
('chicken_wings_deep_fried', 'Chicken Wings (Deep-Fried)', 260, 19.5, 5.5, 18.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['deep fried chicken wings', 'fried chicken wings', 'buffalo wings deep fried', 'chicken wings fried', 'crispy fried wings'],
 'proteins', NULL, 1, '260 cal/100g. Per 4 wings (85g): 221 cal. Deep frying adds significant oil. Compare: air-fried (216).', TRUE),

-- Chicken Nuggets (Deep-Fried)
('chicken_nuggets_fried', 'Chicken Nuggets (Deep-Fried)', 270, 14.0, 16.0, 16.5,
 0.5, 0.5, 85, NULL,
 'usda', ARRAY['chicken nuggets', 'fried chicken nuggets', 'mcnuggets', 'chicken tenders', 'chicken fingers', 'popcorn chicken'],
 'proteins', NULL, 1, '270 cal/100g. Per 6 nuggets (85g): 230 cal. Breaded and deep fried. Compare: air-fried (220).', TRUE),

-- Falafel (Deep-Fried)
('falafel_fried', 'Falafel (Deep-Fried)', 280, 9.5, 24.0, 16.0,
 4.5, 1.5, 17, 17,
 'usda', ARRAY['falafel', 'deep fried falafel', 'falafel ball', 'chickpea falafel', 'fried falafel'],
 'proteins', NULL, 1, '280 cal/100g. Per ball (17g): 48 cal. Deep frying adds 60 cal vs air-fried. Often fried in seed oils.', TRUE),

-- Onion Rings (Deep-Fried)
('onion_rings_fried', 'Onion Rings (Deep-Fried)', 295, 3.5, 29.0, 18.0,
 1.5, 4.0, 85, NULL,
 'usda', ARRAY['onion rings', 'fried onion rings', 'deep fried onion rings', 'breaded onion rings', 'battered onion rings'],
 'snacks', NULL, 1, '295 cal/100g. Per 8 rings (85g): 251 cal. Battered and deep fried. Compare: air-fried (195).', TRUE),

-- Smoked Chicken Breast
('chicken_breast_smoked', 'Chicken Breast (Smoked)', 150, 29.0, 0.0, 3.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['smoked chicken breast', 'smoked chicken', 'chicken breast smoked', 'bbq smoked chicken', 'hickory smoked chicken'],
 'proteins', NULL, 1, '150 cal/100g. Smoking dehydrates slightly, concentrating protein. Low fat, great flavor.', TRUE),

-- Smoked Brisket
('brisket_smoked', 'Brisket (Smoked)', 275, 25.0, 0.0, 19.0,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['smoked brisket', 'bbq brisket', 'texas brisket', 'beef brisket smoked', 'brisket'],
 'proteins', NULL, 1, '275 cal/100g. Per 3 oz (85g): 234 cal. Slow smoked beef brisket. Higher fat cut.', TRUE),

-- Smoked Pulled Pork
('pulled_pork_smoked', 'Pulled Pork (Smoked)', 230, 22.0, 2.0, 14.5,
 0.0, 1.5, 85, NULL,
 'usda', ARRAY['pulled pork', 'smoked pulled pork', 'bbq pulled pork', 'slow smoked pork', 'pulled pork shoulder'],
 'proteins', NULL, 1, '230 cal/100g. Per 3 oz (85g): 196 cal. Slow smoked pork shoulder, shredded. Without BBQ sauce.', TRUE),

-- Grilled Vegetables (mixed)
('vegetables_grilled', 'Grilled Vegetables (Mixed)', 55, 1.5, 7.0, 2.5,
 2.0, 3.5, 150, NULL,
 'usda', ARRAY['grilled vegetables', 'grilled veggies', 'grilled vegetable medley', 'bbq vegetables', 'chargrilled vegetables'],
 'vegetables', NULL, 1, '55 cal/100g. Light oil brush for grilling. Per 1 cup (150g): 83 cal. Healthy side dish.', TRUE),

-- Roasted Vegetables (mixed)
('vegetables_roasted', 'Roasted Vegetables (Mixed)', 75, 1.8, 8.5, 3.5,
 2.5, 4.0, 150, NULL,
 'usda', ARRAY['roasted vegetables', 'roasted veggies', 'oven roasted vegetables', 'roasted root vegetables', 'sheet pan vegetables'],
 'vegetables', NULL, 1, '75 cal/100g. Oil coating adds ~30 cal vs steamed. Per 1 cup (150g): 113 cal.', TRUE),

-- Steamed Vegetables (mixed)
('vegetables_steamed', 'Steamed Vegetables (Mixed)', 35, 1.5, 6.5, 0.2,
 2.0, 3.0, 150, NULL,
 'usda', ARRAY['steamed vegetables', 'steamed veggies', 'steamed mixed vegetables', 'steam vegetables'],
 'vegetables', NULL, 1, '35 cal/100g. No added fat. Per 1 cup (150g): 53 cal. Lowest calorie vegetable prep.', TRUE),

-- Blackened Fish
('fish_blackened', 'Fish (Blackened)', 135, 24.0, 1.5, 3.5,
 0.5, 0.0, 100, NULL,
 'usda', ARRAY['blackened fish', 'blackened tilapia', 'blackened catfish', 'cajun blackened fish', 'blackened salmon'],
 'proteins', NULL, 1, '135 cal/100g. Cajun spice-crusted, seared in hot pan. Minimal added fat. Flavorful and lean.', TRUE),

-- Sous Vide Chicken Breast
('chicken_breast_sous_vide', 'Chicken Breast (Sous Vide)', 165, 31.0, 0.0, 3.6,
 0.0, 0.0, 120, 120,
 'usda', ARRAY['sous vide chicken', 'sous vide chicken breast', 'chicken breast sous vide'],
 'proteins', NULL, 1, '165 cal/100g. Same macros as grilled (no added fat). Perfectly even doneness. Juiciest method.', TRUE),

-- Smoked Turkey Breast
('turkey_breast_smoked', 'Turkey Breast (Smoked)', 130, 28.0, 1.5, 1.0,
 0.0, 1.0, 85, NULL,
 'usda', ARRAY['smoked turkey', 'smoked turkey breast', 'turkey breast smoked', 'deli smoked turkey'],
 'proteins', NULL, 1, '130 cal/100g. Very lean. Slightly sweeter from smoking process. Popular deli meat.', TRUE)

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
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
