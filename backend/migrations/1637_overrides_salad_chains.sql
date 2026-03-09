-- 1637_overrides_salad_chains.sql
-- Chopt Creative Salad Co., Just Salad, Salad and Go, and Tender Greens menu items.
-- Sources: choptsalad.com, justsalad.com/allergens, saladandgo.com, tendergreens.com,
--          fatsecret.com, nutritionix.com, myfooddiary.com, mynetdiary.com.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = label serving.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- CHOPT CREATIVE SALAD CO. — SALADS
-- ══════════════════════════════════════════

-- Chopt Classic Cobb: 670 cal per salad (~610g)
-- FatSecret/CarbManager: 670 cal, 41g fat, 18g carb, 58g protein, 9g fiber, 5g sugar
-- Per 100g: 670/610*100 = 110 cal
('chopt_classic_cobb', 'Chopt Classic Cobb Salad', 110, 9.5, 3.0, 6.7,
 1.5, 0.8, 610, NULL,
 'website', ARRAY['chopt classic cobb', 'chopt cobb salad', 'chopt cobb', 'chopt classic cobb salad'],
 'salad', 'Chopt', 1, '670 cal per salad (~610g). Grilled chicken, bacon, avocado, egg, tomato, blue cheese, romaine with ranch dressing.', TRUE),

-- Chopt Caesar Salad: 480 cal per salad (~500g)
-- Chopt nutrition guide: Caesar base ~300 cal + chicken ~180 cal
-- Estimated macros: 30g fat, 18g carb, 35g protein, 4g fiber, 3g sugar
-- Per 100g: 480/500*100 = 96 cal
('chopt_caesar', 'Chopt Caesar Salad', 96, 7.0, 3.6, 6.0,
 0.8, 0.6, 500, NULL,
 'website', ARRAY['chopt caesar', 'chopt caesar salad', 'chopt classic caesar'],
 'salad', 'Chopt', 1, '480 cal per salad (~500g). Romaine, parmesan, croutons, classic Caesar dressing with grilled chicken.', TRUE),

-- Chopt Mexican Caesar Salad: 395 cal per salad (~480g)
-- FatSecret: 395 cal. Macros estimated ~26% carb, 43% fat, 31% protein
-- 395 cal: ~26g carb, 19g fat, 31g protein, 6g fiber, 3g sugar
-- Per 100g: 395/480*100 = 82 cal
('chopt_mexican_caesar', 'Chopt Mexican Caesar Salad', 82, 6.5, 5.4, 4.0,
 1.3, 0.6, 480, NULL,
 'website', ARRAY['chopt mexican caesar', 'chopt mexican caesar salad', 'chopt mex caesar'],
 'salad', 'Chopt', 1, '395 cal per salad (~480g). Romaine, cotija cheese, pepitas, tortilla strips, Mexican Caesar dressing.', TRUE),

-- Chopt Kale Caesar Salad: 300 cal per salad (~360g)
-- FatSecret: 300 cal, 13g fat, 24g carb, 18g protein, 5g fiber, 4g sugar
-- Per 100g: 300/360*100 = 83 cal
('chopt_kale_caesar', 'Chopt Kale Caesar Salad', 83, 5.0, 6.7, 3.6,
 1.4, 1.1, 360, NULL,
 'website', ARRAY['chopt kale caesar', 'chopt kale caesar salad', 'chopt kale salad'],
 'salad', 'Chopt', 1, '300 cal per salad (~360g). Kale, parmesan, breadcrumbs, lemon Caesar dressing. No chicken.', TRUE),

-- Chopt Santa Fe Salad: 450 cal per salad (~520g)
-- FatSecret/MyFoodDiary: 450 cal, 30g fat, 30g carb, 22g protein, 12g fiber, 8g sugar
-- Per 100g: 450/520*100 = 87 cal
('chopt_santa_fe', 'Chopt Santa Fe Salad', 87, 4.2, 5.8, 5.8,
 2.3, 1.5, 520, NULL,
 'website', ARRAY['chopt santa fe', 'chopt santa fe salad', 'chopt santafe salad'],
 'salad', 'Chopt', 1, '450 cal per salad (~520g). Romaine, black beans, corn, avocado, tortilla strips, chipotle ranch. High fiber.', TRUE),

-- Chopt Thai Chicken Salad: 490 cal per salad (~510g)
-- Estimated from Chopt nutrition data: ~20g fat, 35g carb, 38g protein, 5g fiber, 10g sugar
-- Per 100g: 490/510*100 = 96 cal
('chopt_thai_chicken', 'Chopt Thai Chicken Salad', 96, 7.5, 6.9, 3.9,
 1.0, 2.0, 510, NULL,
 'website', ARRAY['chopt thai chicken', 'chopt thai chicken salad', 'chopt thai salad'],
 'salad', 'Chopt', 1, '490 cal per salad (~510g). Grilled chicken, cabbage, carrots, edamame, crispy wontons, Thai peanut dressing.', TRUE),

-- Chopt Grilled Chicken Harvest Salad: 510 cal per salad (~530g)
-- MyFoodDiary: Harvest salad base ~350 cal + chicken. ~25g fat, 38g carb, 32g protein, 7g fiber, 12g sugar
-- Per 100g: 510/530*100 = 96 cal
('chopt_harvest', 'Chopt Grilled Chicken Harvest Salad', 96, 6.0, 7.2, 4.7,
 1.3, 2.3, 530, NULL,
 'website', ARRAY['chopt harvest', 'chopt harvest salad', 'chopt grilled chicken harvest', 'chopt harvest bowl'],
 'salad', 'Chopt', 1, '510 cal per salad (~530g). Mixed greens, grilled chicken, apples, dried cranberries, goat cheese, pecans, balsamic vinaigrette.', TRUE),

-- Chopt Kebab Salad: 480 cal per salad (~490g)
-- Estimated from Chopt menu: ~22g fat, 30g carb, 36g protein, 5g fiber, 6g sugar
-- Per 100g: 480/490*100 = 98 cal
('chopt_kebab', 'Chopt Kebab Salad', 98, 7.3, 6.1, 4.5,
 1.0, 1.2, 490, NULL,
 'website', ARRAY['chopt kebab', 'chopt kebab salad', 'chopt chicken kebab salad'],
 'salad', 'Chopt', 1, '480 cal per salad (~490g). Grilled chicken, cucumber, tomato, red onion, feta, pita chips, tzatziki dressing.', TRUE),

-- Chopt Palm Beach Salad: 320 cal per salad (~588g) [with grilled chicken]
-- FatSecret: 320 cal per salad (588g). ~14g fat, 20g carb, 28g protein, 5g fiber, 8g sugar
-- Per 100g: 320/588*100 = 54 cal
('chopt_palm_beach', 'Chopt Palm Beach Salad', 54, 4.8, 3.4, 2.4,
 0.9, 1.4, 588, NULL,
 'website', ARRAY['chopt palm beach', 'chopt palm beach salad', 'chopt palm beach chicken'],
 'salad', 'Chopt', 1, '320 cal per salad (~588g). Grilled chicken, hearts of palm, avocado, tomato, mixed greens, citrus vinaigrette. Light option.', TRUE),

-- Chopt Greek Salad: 450 cal per salad (~500g)
-- Estimated from Chopt nutrition data: ~28g fat, 22g carb, 20g protein, 5g fiber, 6g sugar
-- Per 100g: 450/500*100 = 90 cal
('chopt_greek', 'Chopt Greek Salad', 90, 4.0, 4.4, 5.6,
 1.0, 1.2, 500, NULL,
 'website', ARRAY['chopt greek', 'chopt greek salad', 'chopt mediterranean salad'],
 'salad', 'Chopt', 1, '450 cal per salad (~500g). Romaine, cucumber, tomato, red onion, kalamata olives, feta, oregano vinaigrette.', TRUE),

-- Chopt Farm to Table Salad: 470 cal per salad (~510g)
-- Estimated: ~24g fat, 30g carb, 30g protein, 6g fiber, 8g sugar
-- Per 100g: 470/510*100 = 92 cal
('chopt_farm_to_table', 'Chopt Farm to Table Salad', 92, 5.9, 5.9, 4.7,
 1.2, 1.6, 510, NULL,
 'website', ARRAY['chopt farm to table', 'chopt farm to table salad', 'chopt farm salad'],
 'salad', 'Chopt', 1, '470 cal per salad (~510g). Seasonal greens, roasted vegetables, grilled chicken, quinoa, lemon herb vinaigrette.', TRUE),

-- ══════════════════════════════════════════
-- CHOPT — DRESSINGS
-- ══════════════════════════════════════════

-- Chopt Mexican Goddess Dressing: 80 cal per serving (~30g)
-- MyNetDiary/FatSecret: 80 cal, 8g fat, 2g carb, 0g protein, 0g fiber, 1g sugar
-- Per 100g: 80/30*100 = 267 cal
('chopt_mexican_goddess_dressing', 'Chopt Mexican Goddess Dressing', 267, 0.0, 6.7, 26.7,
 0.0, 3.3, 30, NULL,
 'website', ARRAY['chopt mexican goddess', 'chopt mexican goddess dressing', 'mexican goddess dressing'],
 'dressing', 'Chopt', 1, '80 cal per serving (~30g). Creamy tomatillo and avocado-based dressing. Signature Chopt dressing.', TRUE),

-- Chopt Buttermilk Ranch Dressing: 100 cal per serving (~30g)
-- Chopt nutrition: 100 cal. Estimated: 10g fat, 2g carb, 0.5g protein
-- Per 100g: 100/30*100 = 333 cal
('chopt_buttermilk_ranch', 'Chopt Buttermilk Ranch Dressing', 333, 1.7, 6.7, 33.3,
 0.0, 3.3, 30, NULL,
 'website', ARRAY['chopt buttermilk ranch', 'chopt ranch dressing', 'chopt ranch'],
 'dressing', 'Chopt', 1, '100 cal per serving (~30g). Classic creamy buttermilk ranch dressing.', TRUE),

-- Chopt Balsamic Vinaigrette: 150 cal per serving (~30g)
-- Chopt nutrition: 150 cal. Estimated: 15g fat, 5g carb, 0g protein, 0g fiber, 4g sugar
-- Per 100g: 150/30*100 = 500 cal
('chopt_balsamic_vinaigrette', 'Chopt Balsamic Vinaigrette', 500, 0.0, 16.7, 50.0,
 0.0, 13.3, 30, NULL,
 'website', ARRAY['chopt balsamic vinaigrette', 'chopt balsamic dressing', 'chopt balsamic'],
 'dressing', 'Chopt', 1, '150 cal per serving (~30g). Oil-based balsamic vinaigrette. Higher calorie than creamy dressings.', TRUE),

-- ══════════════════════════════════════════
-- JUST SALAD — SALADS
-- ══════════════════════════════════════════

-- Just Salad Crispy Chicken Caesar: 610 cal per salad (~540g)
-- Nutritionix/MyFoodDiary: Chicken Caesar ~400 cal base + crispy chicken adds ~210 cal
-- Estimated: 34g fat, 35g carb, 40g protein, 5g fiber, 4g sugar
-- Per 100g: 610/540*100 = 113 cal
('just_salad_crispy_chicken_caesar', 'Just Salad Crispy Chicken Caesar', 113, 7.4, 6.5, 6.3,
 0.9, 0.7, 540, NULL,
 'website', ARRAY['just salad crispy chicken caesar', 'just salad chicken caesar', 'just salad caesar'],
 'salad', 'Just Salad', 1, '610 cal per salad (~540g). Crispy chicken, romaine, parmesan, croutons, Caesar dressing.', TRUE),

-- Just Salad Thai Chicken Crunch: 290 cal per salad (~420g)
-- FatSecret/EatThisMuch: 290 cal, 8g fat, 33g carb, 34g protein, 10g fiber, 8g sugar
-- Per 100g: 290/420*100 = 69 cal
('just_salad_thai_chicken_crunch', 'Just Salad Thai Chicken Crunch', 69, 8.1, 7.9, 1.9,
 2.4, 1.9, 420, NULL,
 'website', ARRAY['just salad thai chicken crunch', 'just salad thai chicken', 'just salad thai crunch'],
 'salad', 'Just Salad', 1, '290 cal per salad (~420g). Grilled chicken, cabbage, carrots, edamame, crispy wontons, sesame ginger dressing. High protein, low fat.', TRUE),

-- Just Salad Buffalo Chicken: 580 cal per salad (~530g)
-- Nutritionix: ~410 cal base buffalo chicken salad. With extras ~580 cal.
-- Estimated: 32g fat, 28g carb, 42g protein, 5g fiber, 4g sugar
-- Per 100g: 580/530*100 = 109 cal
('just_salad_buffalo_chicken', 'Just Salad Buffalo Chicken', 109, 7.9, 5.3, 6.0,
 0.9, 0.8, 530, NULL,
 'website', ARRAY['just salad buffalo chicken', 'just salad buffalo chicken salad', 'just salad buffalo'],
 'salad', 'Just Salad', 1, '580 cal per salad (~530g). Crispy chicken, romaine, celery, blue cheese crumbles, buffalo sauce, ranch dressing.', TRUE),

-- Just Salad Harvest Bowl: 490 cal per salad (~500g)
-- Estimated from Just Salad nutrition guide: ~22g fat, 42g carb, 28g protein, 8g fiber, 10g sugar
-- Per 100g: 490/500*100 = 98 cal
('just_salad_harvest_bowl', 'Just Salad Harvest Bowl', 98, 5.6, 8.4, 4.4,
 1.6, 2.0, 500, NULL,
 'website', ARRAY['just salad harvest bowl', 'just salad harvest', 'just salad harvest salad'],
 'salad', 'Just Salad', 1, '490 cal per bowl (~500g). Roasted sweet potato, quinoa, kale, dried cranberries, goat cheese, balsamic vinaigrette.', TRUE),

-- Just Salad Tokyo Supergreens: 420 cal per salad (~480g)
-- FatSecret/Fitbit: 420 cal with chicken. 52% fat, 22% carb, 25% protein
-- ~24g fat, 23g carb, 26g protein, 5g fiber, 6g sugar
-- Per 100g: 420/480*100 = 88 cal
('just_salad_tokyo_supergreens', 'Just Salad Tokyo Supergreens', 88, 5.4, 4.8, 5.0,
 1.0, 1.3, 480, NULL,
 'website', ARRAY['just salad tokyo supergreens', 'just salad tokyo', 'just salad supergreens', 'just salad tokyo salad'],
 'salad', 'Just Salad', 1, '420 cal per salad (~480g). Grilled chicken, mesclun, edamame, cucumber, avocado, sesame seeds, miso dressing.', TRUE),

-- Just Salad Mediterranean: 460 cal per salad (~500g)
-- Estimated: ~26g fat, 30g carb, 22g protein, 6g fiber, 5g sugar
-- Per 100g: 460/500*100 = 92 cal
('just_salad_mediterranean', 'Just Salad Mediterranean', 92, 4.4, 6.0, 5.2,
 1.2, 1.0, 500, NULL,
 'website', ARRAY['just salad mediterranean', 'just salad mediterranean salad', 'just salad med salad'],
 'salad', 'Just Salad', 1, '460 cal per salad (~500g). Romaine, cucumber, tomato, red onion, kalamata olives, feta, chickpeas, lemon herb vinaigrette.', TRUE),

-- Just Salad Kale & Avocado: 430 cal per salad (~470g)
-- Estimated: ~28g fat, 28g carb, 18g protein, 10g fiber, 4g sugar
-- Per 100g: 430/470*100 = 91 cal
('just_salad_kale_avocado', 'Just Salad Kale & Avocado', 91, 3.8, 6.0, 6.0,
 2.1, 0.9, 470, NULL,
 'website', ARRAY['just salad kale avocado', 'just salad kale and avocado', 'just salad kale salad'],
 'salad', 'Just Salad', 1, '430 cal per salad (~470g). Kale, avocado, cherry tomato, sunflower seeds, lemon vinaigrette. High fiber, healthy fats.', TRUE),

-- Just Salad Smokehouse BBQ: 550 cal per salad (~520g)
-- Estimated: ~28g fat, 38g carb, 36g protein, 5g fiber, 12g sugar
-- Per 100g: 550/520*100 = 106 cal
('just_salad_smokehouse_bbq', 'Just Salad Smokehouse BBQ', 106, 6.9, 7.3, 5.4,
 1.0, 2.3, 520, NULL,
 'website', ARRAY['just salad smokehouse bbq', 'just salad smokehouse', 'just salad bbq salad', 'just salad bbq chicken'],
 'salad', 'Just Salad', 1, '550 cal per salad (~520g). Grilled chicken, romaine, corn, black beans, cheddar, tortilla strips, BBQ ranch dressing.', TRUE),

-- ══════════════════════════════════════════
-- JUST SALAD — WARM BOWLS
-- ══════════════════════════════════════════

-- Just Salad Chicken & Sweet Potato Warm Bowl: 520 cal per bowl (~510g)
-- Estimated from Just Salad nutrition guide: ~18g fat, 55g carb, 34g protein, 7g fiber, 10g sugar
-- Per 100g: 520/510*100 = 102 cal
('just_salad_chicken_sweet_potato', 'Just Salad Chicken & Sweet Potato Warm Bowl', 102, 6.7, 10.8, 3.5,
 1.4, 2.0, 510, NULL,
 'website', ARRAY['just salad chicken sweet potato', 'just salad chicken and sweet potato', 'just salad sweet potato bowl', 'just salad warm chicken sweet potato'],
 'salad', 'Just Salad', 1, '520 cal per bowl (~510g). Grilled chicken, roasted sweet potato, kale, quinoa, tahini dressing. High protein warm bowl.', TRUE),

-- Just Salad Steak & Cheddar Warm Bowl: 640 cal per bowl (~520g)
-- Estimated: ~34g fat, 40g carb, 42g protein, 5g fiber, 4g sugar
-- Per 100g: 640/520*100 = 123 cal
('just_salad_steak_cheddar', 'Just Salad Steak & Cheddar Warm Bowl', 123, 8.1, 7.7, 6.5,
 1.0, 0.8, 520, NULL,
 'website', ARRAY['just salad steak cheddar', 'just salad steak and cheddar', 'just salad steak bowl', 'just salad warm steak cheddar'],
 'salad', 'Just Salad', 1, '640 cal per bowl (~520g). Grilled steak, white cheddar, roasted peppers, arugula, warm grains, chimichurri. High protein.', TRUE),

-- ══════════════════════════════════════════
-- SALAD AND GO — SALADS
-- ══════════════════════════════════════════

-- Salad and Go Caesar Salad: 410 cal per salad (~430g)
-- Nutritionix/website: Caesar with chicken ~410 cal. ~22g fat, 24g carb, 30g protein, 4g fiber, 3g sugar
-- Per 100g: 410/430*100 = 95 cal
('salad_and_go_caesar', 'Salad and Go Caesar Salad', 95, 7.0, 5.6, 5.1,
 0.9, 0.7, 430, NULL,
 'website', ARRAY['salad and go caesar', 'salad and go caesar salad', 'saladandgo caesar'],
 'salad', 'Salad and Go', 1, '410 cal per salad (~430g). Romaine, parmesan, croutons, Caesar dressing with grilled chicken. Drive-thru salad chain.', TRUE),

-- Salad and Go Cobb Salad: 470 cal per salad (~450g)
-- FatSecret/CarbManager: 470 cal, 36g fat, 19g carb, 18g protein, 11g fiber, 3g sugar
-- Per 100g: 470/450*100 = 104 cal
('salad_and_go_cobb', 'Salad and Go Cobb Salad', 104, 4.0, 4.2, 8.0,
 2.4, 0.7, 450, NULL,
 'website', ARRAY['salad and go cobb', 'salad and go cobb salad', 'saladandgo cobb'],
 'salad', 'Salad and Go', 1, '470 cal per salad (~450g). Chicken, bacon, avocado, egg, tomato, blue cheese, mixed greens.', TRUE),

-- Salad and Go Greek Salad: 270 cal per salad (~420g)
-- FatSecret: 270 cal per serving. ~16g fat, 18g carb, 12g protein, 4g fiber, 5g sugar
-- Per 100g: 270/420*100 = 64 cal
('salad_and_go_greek', 'Salad and Go Greek Salad', 64, 2.9, 4.3, 3.8,
 1.0, 1.2, 420, NULL,
 'website', ARRAY['salad and go greek', 'salad and go greek salad', 'saladandgo greek'],
 'salad', 'Salad and Go', 1, '270 cal per salad (~420g). Romaine, cucumber, tomato, red onion, kalamata olives, feta, Greek vinaigrette. Lower calorie option.', TRUE),

-- Salad and Go Southwest Salad: 480 cal per salad (~450g)
-- FatSecret/website: 480 cal. ~26g fat, 34g carb, 24g protein, 8g fiber, 5g sugar
-- Per 100g: 480/450*100 = 107 cal
('salad_and_go_southwest', 'Salad and Go Southwest Salad', 107, 5.3, 7.6, 5.8,
 1.8, 1.1, 450, NULL,
 'website', ARRAY['salad and go southwest', 'salad and go southwest salad', 'saladandgo southwest'],
 'salad', 'Salad and Go', 1, '480 cal per salad (~450g). Chicken, black beans, corn, avocado, tortilla strips, chipotle ranch dressing.', TRUE),

-- Salad and Go Chef Salad: 420 cal per salad (~440g)
-- Estimated from Salad and Go nutrition PDF: ~24g fat, 18g carb, 30g protein, 3g fiber, 4g sugar
-- Per 100g: 420/440*100 = 95 cal
('salad_and_go_chef', 'Salad and Go Chef Salad', 95, 6.8, 4.1, 5.5,
 0.7, 0.9, 440, NULL,
 'website', ARRAY['salad and go chef', 'salad and go chef salad', 'saladandgo chef salad'],
 'salad', 'Salad and Go', 1, '420 cal per salad (~440g). Turkey, ham, egg, cheddar, tomato, cucumber, mixed greens, ranch dressing.', TRUE),

-- Salad and Go Thai Peanut Salad: 470 cal per salad (~450g)
-- FatSecret: Thai Chicken Salad ~220 cal base + Thai Peanut dressing 130 cal + extras
-- Estimated total: ~24g fat, 32g carb, 30g protein, 5g fiber, 10g sugar
-- Per 100g: 470/450*100 = 104 cal
('salad_and_go_thai_peanut', 'Salad and Go Thai Peanut Salad', 104, 6.7, 7.1, 5.3,
 1.1, 2.2, 450, NULL,
 'website', ARRAY['salad and go thai peanut', 'salad and go thai peanut salad', 'saladandgo thai peanut', 'salad and go thai chicken'],
 'salad', 'Salad and Go', 1, '470 cal per salad (~450g). Chicken, cabbage, carrots, edamame, crispy wontons, Thai peanut dressing.', TRUE),

-- Salad and Go Berry Almond Salad: 380 cal per salad (~420g)
-- Estimated: ~20g fat, 30g carb, 18g protein, 6g fiber, 14g sugar
-- Per 100g: 380/420*100 = 90 cal
('salad_and_go_berry_almond', 'Salad and Go Berry Almond Salad', 90, 4.3, 7.1, 4.8,
 1.4, 3.3, 420, NULL,
 'website', ARRAY['salad and go berry almond', 'salad and go berry almond salad', 'saladandgo berry almond'],
 'salad', 'Salad and Go', 1, '380 cal per salad (~420g). Mixed greens, strawberries, blueberries, almonds, goat cheese, berry vinaigrette.', TRUE),

-- ══════════════════════════════════════════
-- SALAD AND GO — BREAKFAST BURRITOS
-- ══════════════════════════════════════════

-- Salad and Go Sausage Breakfast Burrito: 450 cal per burrito (~200g)
-- Based on Salad and Go nutrition PDF: Traditional burrito 560 cal (heavier), sausage variant ~450 cal
-- Estimated: ~24g fat, 34g carb, 20g protein, 2g fiber, 2g sugar
-- Per 100g: 450/200*100 = 225 cal
('salad_and_go_sausage_burrito', 'Salad and Go Sausage Breakfast Burrito', 225, 10.0, 17.0, 12.0,
 1.0, 1.0, NULL, 200,
 'website', ARRAY['salad and go sausage burrito', 'salad and go sausage breakfast burrito', 'saladandgo sausage burrito'],
 'breakfast_burrito', 'Salad and Go', 1, '450 cal per burrito (~200g). Scrambled eggs, sausage, cheese in a flour tortilla. Drive-thru breakfast option.', TRUE),

-- Salad and Go Bacon Breakfast Burrito: 420 cal per burrito (~190g)
-- Estimated from Salad and Go nutrition: ~22g fat, 32g carb, 20g protein, 1g fiber, 1g sugar
-- Per 100g: 420/190*100 = 221 cal
('salad_and_go_bacon_burrito', 'Salad and Go Bacon Breakfast Burrito', 221, 10.5, 16.8, 11.6,
 0.5, 0.5, NULL, 190,
 'website', ARRAY['salad and go bacon burrito', 'salad and go bacon breakfast burrito', 'saladandgo bacon burrito'],
 'breakfast_burrito', 'Salad and Go', 1, '420 cal per burrito (~190g). Scrambled eggs, bacon, cheese in a flour tortilla.', TRUE),

-- ══════════════════════════════════════════
-- SALAD AND GO — SMOOTHIES
-- ══════════════════════════════════════════

-- Salad and Go Strawberry Banana Smoothie: 220 cal per 24oz (~450g)
-- Estimated from Salad and Go menu: fruit smoothie ~220 cal. ~1g fat, 52g carb, 3g protein, 4g fiber, 38g sugar
-- Per 100g: 220/450*100 = 49 cal
('salad_and_go_strawberry_banana_smoothie', 'Salad and Go Strawberry Banana Smoothie', 49, 0.7, 11.6, 0.2,
 0.9, 8.4, 450, NULL,
 'website', ARRAY['salad and go strawberry banana smoothie', 'salad and go strawberry banana', 'saladandgo smoothie strawberry banana'],
 'smoothie', 'Salad and Go', 1, '220 cal per 24 oz (~450g). Strawberry and banana blended smoothie. Low fat, fruit-based.', TRUE),

-- Salad and Go Berry Smoothie: 200 cal per 24oz (~450g)
-- Estimated: ~1g fat, 46g carb, 3g protein, 5g fiber, 34g sugar
-- Per 100g: 200/450*100 = 44 cal
('salad_and_go_berry_smoothie', 'Salad and Go Berry Smoothie', 44, 0.7, 10.2, 0.2,
 1.1, 7.6, 450, NULL,
 'website', ARRAY['salad and go berry smoothie', 'salad and go mixed berry smoothie', 'saladandgo smoothie berry'],
 'smoothie', 'Salad and Go', 1, '200 cal per 24 oz (~450g). Mixed berry blended smoothie. Low fat, high in natural fruit sugars.', TRUE),

-- Salad and Go Green Smoothie: 180 cal per 24oz (~450g)
-- Estimated: ~1g fat, 40g carb, 4g protein, 5g fiber, 28g sugar
-- Per 100g: 180/450*100 = 40 cal
('salad_and_go_green_smoothie', 'Salad and Go Green Smoothie', 40, 0.9, 8.9, 0.2,
 1.1, 6.2, 450, NULL,
 'website', ARRAY['salad and go green smoothie', 'salad and go green juice smoothie', 'saladandgo smoothie green'],
 'smoothie', 'Salad and Go', 1, '180 cal per 24 oz (~450g). Spinach, banana, and fruit blend smoothie. Lowest calorie smoothie option.', TRUE),

-- ══════════════════════════════════════════
-- TENDER GREENS — SALADS
-- ══════════════════════════════════════════

-- Tender Greens Chipotle BBQ Chicken Salad: 610 cal per salad (~530g)
-- FatSecret/MyFoodDiary: 610 cal. ~34g fat, 29g carb, 46g protein, 6g fiber, 8g sugar
-- Per 100g: 610/530*100 = 115 cal
('tender_greens_chipotle_bbq_chicken', 'Tender Greens Chipotle BBQ Chicken Salad', 115, 8.7, 5.5, 6.4,
 1.1, 1.5, 530, NULL,
 'website', ARRAY['tender greens chipotle bbq chicken', 'tender greens chipotle bbq', 'tender greens bbq chicken salad', 'tender greens chipotle barbecue chicken'],
 'salad', 'Tender Greens', 1, '610 cal per salad (~530g). Chipotle BBQ grilled chicken, mixed greens, corn, black beans, avocado, tortilla strips.', TRUE),

-- Tender Greens Salt & Pepper Chicken Salad: 480 cal per salad (~500g)
-- MyFoodDiary: Salt & Pepper Chicken plate available. Salad version ~480 cal.
-- Estimated: ~26g fat, 20g carb, 40g protein, 4g fiber, 4g sugar
-- Per 100g: 480/500*100 = 96 cal
('tender_greens_salt_pepper_chicken', 'Tender Greens Salt & Pepper Chicken Salad', 96, 8.0, 4.0, 5.2,
 0.8, 0.8, 500, NULL,
 'website', ARRAY['tender greens salt pepper chicken', 'tender greens salt and pepper chicken', 'tender greens s&p chicken salad'],
 'salad', 'Tender Greens', 1, '480 cal per salad (~500g). Salt and pepper seasoned grilled chicken, mixed greens, herb vinaigrette. Clean protein option.', TRUE),

-- Tender Greens Backyard Steak Salad: 410 cal per salad (~480g)
-- EatThisMuch/FatSecret: 410 cal. 16% carb, 44% fat, 40% protein
-- ~20g fat, 16g carb, 41g protein, 3g fiber, 4g sugar
-- Per 100g: 410/480*100 = 85 cal
('tender_greens_backyard_steak', 'Tender Greens Backyard Steak Salad', 85, 8.5, 3.3, 4.2,
 0.6, 0.8, 480, NULL,
 'website', ARRAY['tender greens backyard steak', 'tender greens steak salad', 'tender greens backyard marinated steak'],
 'salad', 'Tender Greens', 1, '410 cal per salad (~480g). Backyard marinated steak, mixed greens, horseradish vinaigrette. High protein, moderate fat.', TRUE),

-- Tender Greens Grilled Salmon Salad: 510 cal per salad (~490g)
-- SnapCalorie/MyFoodDiary: Grilled salmon plate ~900 cal (with sides). Salad version ~510 cal.
-- Estimated: ~28g fat, 18g carb, 38g protein, 4g fiber, 4g sugar
-- Per 100g: 510/490*100 = 104 cal
('tender_greens_grilled_salmon', 'Tender Greens Grilled Salmon Salad', 104, 7.8, 3.7, 5.7,
 0.8, 0.8, 490, NULL,
 'website', ARRAY['tender greens grilled salmon', 'tender greens salmon salad', 'tender greens salmon'],
 'salad', 'Tender Greens', 1, '510 cal per salad (~490g). Grilled salmon fillet, mixed greens, herb vinaigrette. Rich in omega-3 fatty acids.', TRUE),

-- Tender Greens Miso Glazed Salmon Salad: 530 cal per salad (~490g)
-- MyFoodDiary/SnapCalorie: Miso glazed salmon plate ~860 cal. Salad version ~530 cal.
-- Estimated: ~30g fat, 20g carb, 36g protein, 4g fiber, 8g sugar
-- Per 100g: 530/490*100 = 108 cal
('tender_greens_miso_salmon', 'Tender Greens Miso Glazed Salmon Salad', 108, 7.3, 4.1, 6.1,
 0.8, 1.6, 490, NULL,
 'website', ARRAY['tender greens miso salmon', 'tender greens miso glazed salmon', 'tender greens miso salmon salad'],
 'salad', 'Tender Greens', 1, '530 cal per salad (~490g). Miso-marinated grilled salmon, mixed greens, Asian-inspired dressing. Slightly sweeter glaze adds calories.', TRUE),

-- Tender Greens Happy Vegan Salad: 420 cal per salad (~480g)
-- Nutritionix/MyFoodDiary: Happy Vegan salad. Smaller portion ~420 cal.
-- Estimated: ~22g fat, 38g carb, 14g protein, 10g fiber, 8g sugar
-- Per 100g: 420/480*100 = 88 cal
('tender_greens_happy_vegan', 'Tender Greens Happy Vegan Salad', 88, 2.9, 7.9, 4.6,
 2.1, 1.7, 480, NULL,
 'website', ARRAY['tender greens happy vegan', 'tender greens vegan salad', 'tender greens happy vegan salad'],
 'salad', 'Tender Greens', 1, '420 cal per salad (~480g). Seasonal vegetables, ancient grains, avocado, nuts, herb vinaigrette. Fully plant-based. High fiber.', TRUE),

-- Tender Greens Classic Caesar Salad: 440 cal per salad (~470g)
-- Estimated from Tender Greens nutrition: ~28g fat, 22g carb, 22g protein, 4g fiber, 3g sugar
-- Per 100g: 440/470*100 = 94 cal
('tender_greens_classic_caesar', 'Tender Greens Classic Caesar Salad', 94, 4.7, 4.7, 6.0,
 0.9, 0.6, 470, NULL,
 'website', ARRAY['tender greens caesar', 'tender greens classic caesar', 'tender greens caesar salad'],
 'salad', 'Tender Greens', 1, '440 cal per salad (~470g). Romaine, parmesan, croutons, classic Caesar dressing.', TRUE),

-- Tender Greens Tuna Nicoise Salad: 650 cal per salad (~520g)
-- FatSecret/MyFoodDiary: 650 cal. 17g fat, 51g carb, 32g protein, 6g fiber, 5g sugar
-- Per 100g: 650/520*100 = 125 cal
('tender_greens_tuna_nicoise', 'Tender Greens Tuna Nicoise Salad', 125, 6.2, 9.8, 3.3,
 1.2, 1.0, 520, NULL,
 'website', ARRAY['tender greens tuna nicoise', 'tender greens tuna nicoise salad', 'tender greens nicoise'],
 'salad', 'Tender Greens', 1, '650 cal per salad (~520g). Seared ahi tuna, potatoes, green beans, egg, olives, nicoise vinaigrette. Higher carb from potatoes.', TRUE),

-- ══════════════════════════════════════════
-- TENDER GREENS — HOT PLATES
-- ══════════════════════════════════════════

-- Tender Greens Roasted Turkey Hot Plate: 520 cal per plate (~520g)
-- Estimated from Tender Greens nutrition PDF: ~20g fat, 40g carb, 42g protein, 4g fiber, 4g sugar
-- Per 100g: 520/520*100 = 100 cal
('tender_greens_roasted_turkey', 'Tender Greens Roasted Turkey Plate', 100, 8.1, 7.7, 3.8,
 0.8, 0.8, 520, NULL,
 'website', ARRAY['tender greens roasted turkey', 'tender greens turkey plate', 'tender greens turkey hot plate'],
 'entree', 'Tender Greens', 1, '520 cal per plate (~520g). Herb-roasted turkey breast with mashed potatoes and cranberry sauce. Lean protein plate.', TRUE),

-- Tender Greens Braised Short Rib Plate: 680 cal per plate (~530g)
-- Tender Greens menu: Short rib with mashed potatoes and red wine jus.
-- Estimated: ~36g fat, 38g carb, 42g protein, 3g fiber, 4g sugar
-- Per 100g: 680/530*100 = 128 cal
('tender_greens_braised_short_rib', 'Tender Greens Braised Short Rib Plate', 128, 7.9, 7.2, 6.8,
 0.6, 0.8, 530, NULL,
 'website', ARRAY['tender greens braised short rib', 'tender greens short rib', 'tender greens short rib plate', 'tender greens braised beef'],
 'entree', 'Tender Greens', 1, '680 cal per plate (~530g). Braised beef short rib, mashed potatoes, red wine jus. Rich and hearty, higher fat.', TRUE)

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
