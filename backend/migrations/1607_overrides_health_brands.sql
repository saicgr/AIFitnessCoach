-- 1607_overrides_health_brands.sql
-- Health and fitness brands: OWYN, LMNT, Kodiak Cakes, Banza, Ezekiel/Food for Life,
-- Ratio, Fairlife, Quest (chips + cookies), Barebells, Ghost Whey, Chobani Complete, Halo Top.
-- Sources: Official brand websites, EatThisMuch, FatSecret, MyNetDiary, NutritionValue.
-- All items label-verified from manufacturer data.
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- OWYN — PLANT-BASED PROTEIN SHAKES
-- ══════════════════════════════════════════

-- OWYN Dark Chocolate: 170 cal per 330g bottle
('owyn_dark_chocolate', 'OWYN Dark Chocolate Protein Shake', 51.5, 6.1, 2.7, 2.1,
 1.5, 1.2, NULL, 330,
 'manufacturer', ARRAY['owyn dark chocolate', 'owyn chocolate shake', 'owyn protein shake dark chocolate', 'owyn plant based chocolate', 'owyn dark chocolate protein'],
 'protein_shake', 'OWYN', 1, '170 cal per 330g bottle. Plant-based 20g protein from pea, pumpkin seed, flax. Allergen-free, monk fruit sweetened.', TRUE),

-- OWYN Smooth Vanilla: 170 cal per 330g bottle
('owyn_smooth_vanilla', 'OWYN Smooth Vanilla Protein Shake', 51.5, 6.1, 2.4, 2.1,
 1.5, 1.2, NULL, 330,
 'manufacturer', ARRAY['owyn vanilla', 'owyn smooth vanilla', 'owyn protein shake vanilla', 'owyn plant based vanilla', 'owyn vanilla protein'],
 'protein_shake', 'OWYN', 1, '170 cal per 330g bottle. Plant-based 20g protein from pea, pumpkin seed, flax. Allergen-free, monk fruit sweetened.', TRUE),

-- OWYN Cold Brew Coffee: 180 cal per 330g bottle
('owyn_cold_brew_coffee', 'OWYN Cold Brew Coffee Protein Shake', 54.5, 6.1, 3.3, 2.1,
 1.5, 1.2, NULL, 330,
 'manufacturer', ARRAY['owyn cold brew', 'owyn coffee shake', 'owyn protein shake cold brew', 'owyn cold brew coffee protein', 'owyn coffee protein'],
 'protein_shake', 'OWYN', 1, '180 cal per 330g bottle. Plant-based 20g protein with 148mg caffeine. Allergen-free, monk fruit sweetened.', TRUE),

-- OWYN Cookies & Creamwich: 170 cal per 330g bottle
('owyn_cookies_creamwich', 'OWYN Cookies & Creamwich Protein Shake', 51.5, 6.1, 2.7, 2.1,
 1.5, 1.2, NULL, 330,
 'manufacturer', ARRAY['owyn cookies and cream', 'owyn cookies creamwich', 'owyn protein shake cookies', 'owyn cookies & creamwich protein', 'owyn creamwich'],
 'protein_shake', 'OWYN', 1, '170 cal per 330g bottle. Plant-based 20g protein from pea, pumpkin seed, flax. Allergen-free, monk fruit sweetened.', TRUE),

-- ══════════════════════════════════════════
-- LMNT — ELECTROLYTE PACKETS
-- ══════════════════════════════════════════

-- LMNT Citrus Salt: 5 cal per 6g packet
('lmnt_citrus_salt', 'LMNT Citrus Salt Electrolyte Mix', 83.3, 0.0, 8.3, 0.0,
 0.0, 0.0, NULL, 6,
 'manufacturer', ARRAY['lmnt citrus salt', 'lmnt citrus', 'lmnt electrolyte citrus', 'lmnt citrus salt electrolyte', 'element citrus salt'],
 'electrolyte', 'LMNT', 1, '5 cal per 6g packet. 1000mg sodium, 200mg potassium, 60mg magnesium. Zero sugar, stevia sweetened.', TRUE),

-- LMNT Raspberry Salt: 5 cal per 6g packet
('lmnt_raspberry_salt', 'LMNT Raspberry Salt Electrolyte Mix', 83.3, 0.0, 8.3, 0.0,
 0.0, 0.0, NULL, 6,
 'manufacturer', ARRAY['lmnt raspberry salt', 'lmnt raspberry', 'lmnt electrolyte raspberry', 'lmnt raspberry salt electrolyte', 'element raspberry salt'],
 'electrolyte', 'LMNT', 1, '5 cal per 6g packet. 1000mg sodium, 200mg potassium, 60mg magnesium. Zero sugar, stevia sweetened.', TRUE),

-- LMNT Watermelon Salt: 5 cal per 6g packet
('lmnt_watermelon_salt', 'LMNT Watermelon Salt Electrolyte Mix', 83.3, 0.0, 8.3, 0.0,
 0.0, 0.0, NULL, 6,
 'manufacturer', ARRAY['lmnt watermelon salt', 'lmnt watermelon', 'lmnt electrolyte watermelon', 'lmnt watermelon salt electrolyte', 'element watermelon salt'],
 'electrolyte', 'LMNT', 1, '5 cal per 6g packet. 1000mg sodium, 200mg potassium, 60mg magnesium. Zero sugar, stevia sweetened.', TRUE),

-- LMNT Chocolate Salt: 5 cal per 6g packet
('lmnt_chocolate_salt', 'LMNT Chocolate Salt Electrolyte Mix', 83.3, 0.0, 8.3, 0.0,
 0.0, 0.0, NULL, 6,
 'manufacturer', ARRAY['lmnt chocolate salt', 'lmnt chocolate', 'lmnt electrolyte chocolate', 'lmnt chocolate salt electrolyte', 'element chocolate salt'],
 'electrolyte', 'LMNT', 1, '5 cal per 6g packet. 1000mg sodium, 200mg potassium, 60mg magnesium. Uses cocoa powder. Zero sugar, stevia sweetened.', TRUE),

-- LMNT Mango Chili: 10 cal per 6g packet
('lmnt_mango_chili', 'LMNT Mango Chili Electrolyte Mix', 166.7, 0.0, 16.7, 0.0,
 0.0, 0.0, NULL, 6,
 'manufacturer', ARRAY['lmnt mango chili', 'lmnt mango', 'lmnt electrolyte mango chili', 'lmnt mango chili electrolyte', 'element mango chili'],
 'electrolyte', 'LMNT', 1, '10 cal per 6g packet. 1000mg sodium, 200mg potassium, 60mg magnesium. Uses malic acid for heat. Zero sugar, stevia sweetened.', TRUE),

-- ══════════════════════════════════════════
-- KODIAK CAKES — PROTEIN PANCAKE MIX & CUPS
-- ══════════════════════════════════════════

-- Kodiak Cakes Power Cakes Buttermilk Mix (dry): 190 cal per 53g
('kodiak_power_cakes_buttermilk', 'Kodiak Cakes Power Cakes Buttermilk Flapjack Mix', 358.5, 26.4, 56.6, 3.8,
 9.4, 5.7, 53, NULL,
 'manufacturer', ARRAY['kodiak cakes buttermilk', 'kodiak power cakes', 'kodiak pancake mix', 'kodiak cakes power cakes buttermilk', 'kodiak protein pancake'],
 'pancake_mix', 'Kodiak Cakes', 1, '190 cal per 53g dry mix (1/2 cup). 14g protein dry; 18g with milk, 21g with milk + egg. Whole grain wheat flour base.', TRUE),

-- Kodiak Cakes Oatmeal Cup Maple Brown Sugar: 230 cal per 60g
('kodiak_oatmeal_maple_brown_sugar', 'Kodiak Cakes Protein Oatmeal Cup Maple Brown Sugar', 383.3, 23.3, 61.7, 5.0,
 6.7, 20.0, NULL, 60,
 'manufacturer', ARRAY['kodiak oatmeal maple brown sugar', 'kodiak oatmeal cup maple', 'kodiak protein oatmeal maple', 'kodiak cakes oatmeal maple brown sugar', 'kodiak oatmeal'],
 'oatmeal', 'Kodiak Cakes', 1, '230 cal per 60g cup. 14g protein instant oatmeal. Just add water.', TRUE),

-- Kodiak Cakes Oatmeal Cup Chocolate Chip: 240 cal per 60g
('kodiak_oatmeal_chocolate_chip', 'Kodiak Cakes Protein Oatmeal Cup Chocolate Chip', 400.0, 23.3, 60.0, 7.5,
 6.7, 20.0, NULL, 60,
 'manufacturer', ARRAY['kodiak oatmeal chocolate chip', 'kodiak oatmeal cup chocolate', 'kodiak protein oatmeal chocolate', 'kodiak cakes oatmeal chocolate chip', 'kodiak chocolate oatmeal'],
 'oatmeal', 'Kodiak Cakes', 1, '240 cal per 60g cup. 14g protein instant oatmeal with chocolate chips. Just add water.', TRUE),

-- Kodiak Cakes Muffin Cup Blueberry Lemon: 260 cal per 65g
('kodiak_muffin_blueberry_lemon', 'Kodiak Cakes Protein Muffin Cup Blueberry Lemon', 400.0, 18.5, 61.5, 9.2,
 4.6, 24.6, NULL, 65,
 'manufacturer', ARRAY['kodiak muffin blueberry lemon', 'kodiak muffin cup blueberry', 'kodiak protein muffin blueberry', 'kodiak cakes muffin cup blueberry lemon', 'kodiak blueberry muffin'],
 'bakery', 'Kodiak Cakes', 1, '260 cal per 65g cup. 12g protein mug muffin. Just add water. 14g added sugars.', TRUE),

-- ══════════════════════════════════════════
-- BANZA — CHICKPEA PRODUCTS
-- ══════════════════════════════════════════

-- Banza Chickpea Penne (2oz dry): 190 cal per 56g
('banza_chickpea_penne', 'Banza Chickpea Penne Pasta', 339.3, 19.6, 62.5, 5.4,
 8.9, 1.8, 56, NULL,
 'manufacturer', ARRAY['banza penne', 'banza chickpea pasta', 'banza pasta penne', 'banza chickpea penne', 'banza protein pasta'],
 'pasta', 'Banza', 1, '190 cal per 56g dry (2oz). 11g protein, 5g fiber. Gluten-free chickpea pasta with 2x protein vs wheat.', TRUE),

-- Banza Chickpea Pizza Crust (1/4 crust): 150 cal per 48g
('banza_chickpea_pizza_crust', 'Banza Chickpea Pizza Crust', 312.5, 8.3, 47.9, 12.5,
 4.2, 1.0, 48, NULL,
 'manufacturer', ARRAY['banza pizza crust', 'banza chickpea crust', 'banza pizza', 'banza chickpea pizza crust', 'banza gluten free pizza'],
 'pizza_crust', 'Banza', 1, '150 cal per 48g (1/4 crust). Gluten-free, vegan, non-GMO chickpea-based crust. Plain crust only, not topped.', TRUE),

-- ══════════════════════════════════════════
-- EZEKIEL / FOOD FOR LIFE — SPROUTED BREAD
-- ══════════════════════════════════════════

-- Ezekiel 4:9 Sprouted Bread (per slice): 80 cal per 34g
('ezekiel_sprouted_bread', 'Food for Life Ezekiel 4:9 Sprouted Whole Grain Bread', 235.3, 11.8, 44.1, 1.5,
 8.8, 0.0, NULL, 34,
 'manufacturer', ARRAY['ezekiel bread', 'ezekiel 4:9 bread', 'food for life sprouted bread', 'ezekiel sprouted grain bread', 'ezekiel 4:9 sprouted bread'],
 'bread', 'Food for Life', 1, '80 cal per 34g slice. 0g sugar, 3g fiber. Made from 6 sprouted grains: wheat, barley, millet, lentils, soybeans, spelt.', TRUE),

-- Ezekiel 4:9 English Muffin (whole): 160 cal per 76g
('ezekiel_english_muffin', 'Food for Life Ezekiel 4:9 Sprouted English Muffin', 210.5, 10.5, 39.5, 1.3,
 7.9, 0.0, NULL, 76,
 'manufacturer', ARRAY['ezekiel english muffin', 'ezekiel 4:9 english muffin', 'food for life english muffin', 'ezekiel sprouted english muffin', 'food for life 4:9 english muffin'],
 'bread', 'Food for Life', 1, '160 cal per 76g whole muffin. 8g protein, 6g fiber, 0g sugar. Label lists per-half; values are for whole muffin.', TRUE),

-- ══════════════════════════════════════════
-- RATIO — KETO FRIENDLY YOGURT
-- ══════════════════════════════════════════

-- Ratio Keto Yogurt Vanilla: 150 cal per 150g
('ratio_keto_yogurt_vanilla', 'Ratio Keto Friendly Yogurt Vanilla', 100.0, 10.0, 2.0, 6.0,
 0.0, 0.7, 150, NULL,
 'manufacturer', ARRAY['ratio keto vanilla', 'ratio vanilla yogurt', 'ratio keto friendly vanilla', 'ratio yogurt vanilla', 'ratio keto vanilla yogurt'],
 'yogurt', 'Ratio', 1, '150 cal per 150g cup (5.3oz). 15g protein, 9g fat from sunflower/avocado oil. Ultra-filtered nonfat milk. Current Trio formula.', TRUE),

-- Ratio Keto Yogurt Strawberry: 150 cal per 133g
('ratio_keto_yogurt_strawberry', 'Ratio Keto Friendly Yogurt Strawberry', 112.8, 11.3, 2.3, 6.8,
 0.0, 1.5, 133, NULL,
 'manufacturer', ARRAY['ratio keto strawberry', 'ratio strawberry yogurt', 'ratio keto friendly strawberry', 'ratio yogurt strawberry', 'ratio keto strawberry yogurt'],
 'yogurt', 'Ratio', 1, '150 cal per 133g cup. 15g protein, 9g fat. Ultra-filtered nonfat milk. Current Trio formula.', TRUE),

-- Ratio Keto Yogurt Coconut: 150 cal per 150g
('ratio_keto_yogurt_coconut', 'Ratio Keto Friendly Yogurt Coconut', 100.0, 10.0, 2.0, 6.0,
 0.0, 0.7, 150, NULL,
 'manufacturer', ARRAY['ratio keto coconut', 'ratio coconut yogurt', 'ratio keto friendly coconut', 'ratio yogurt coconut', 'ratio keto coconut yogurt'],
 'yogurt', 'Ratio', 1, '150 cal per 150g cup (5.3oz). 15g protein, 9g fat from sunflower/avocado oil. Ultra-filtered nonfat milk. Current Trio formula.', TRUE),

-- ══════════════════════════════════════════
-- FAIRLIFE — NUTRITION PLAN PROTEIN SHAKES
-- ══════════════════════════════════════════

-- Fairlife Nutrition Plan Chocolate: 150 cal per 340g (11.5oz)
('fairlife_nutrition_plan_chocolate', 'Fairlife Nutrition Plan Chocolate Protein Shake', 44.1, 8.8, 1.2, 0.7,
 0.3, 0.6, NULL, 340,
 'manufacturer', ARRAY['fairlife chocolate', 'fairlife nutrition plan chocolate', 'fairlife protein shake chocolate', 'fairlife chocolate shake', 'fairlife chocolate protein'],
 'protein_shake', 'Fairlife', 1, '150 cal per 340g bottle (11.5oz). 30g protein from ultra-filtered milk. Lactose-free, no added sugars. Shelf-stable.', TRUE),

-- Fairlife Nutrition Plan Vanilla: 150 cal per 340g
('fairlife_nutrition_plan_vanilla', 'Fairlife Nutrition Plan Vanilla Protein Shake', 44.1, 8.8, 0.9, 0.7,
 0.3, 0.6, NULL, 340,
 'manufacturer', ARRAY['fairlife vanilla', 'fairlife nutrition plan vanilla', 'fairlife protein shake vanilla', 'fairlife vanilla shake', 'fairlife vanilla protein'],
 'protein_shake', 'Fairlife', 1, '150 cal per 340g bottle (11.5oz). 30g protein from ultra-filtered milk. Lactose-free, no added sugars. Shelf-stable.', TRUE),

-- Fairlife Nutrition Plan Salted Caramel: 150 cal per 340g
('fairlife_nutrition_plan_salted_caramel', 'Fairlife Nutrition Plan Salted Caramel Protein Shake', 44.1, 8.8, 1.2, 0.7,
 0.3, 0.6, NULL, 340,
 'manufacturer', ARRAY['fairlife salted caramel', 'fairlife nutrition plan salted caramel', 'fairlife protein shake caramel', 'fairlife caramel shake', 'fairlife salted caramel protein'],
 'protein_shake', 'Fairlife', 1, '150 cal per 340g bottle (11.5oz). 30g protein from ultra-filtered milk. Lactose-free, no added sugars. Shelf-stable.', TRUE),

-- ══════════════════════════════════════════
-- QUEST — PROTEIN CHIPS
-- ══════════════════════════════════════════

-- Quest Loaded Taco Chips: 140 cal per 32g bag
('quest_loaded_taco_chips', 'Quest Loaded Taco Tortilla Style Protein Chips', 437.5, 59.4, 15.6, 15.6,
 3.1, 1.6, NULL, 32,
 'manufacturer', ARRAY['quest loaded taco chips', 'quest chips loaded taco', 'quest tortilla chips loaded taco', 'quest protein chips loaded taco', 'quest loaded taco'],
 'snacks', 'Quest', 1, '140 cal per 32g bag. 19g protein. Tortilla style, baked not fried. Dairy-based complete protein.', TRUE),

-- Quest Nacho Cheese Chips: 150 cal per 32g bag
('quest_nacho_cheese_chips', 'Quest Nacho Cheese Tortilla Style Protein Chips', 468.8, 56.3, 15.6, 18.8,
 3.1, 3.1, NULL, 32,
 'manufacturer', ARRAY['quest nacho cheese chips', 'quest chips nacho cheese', 'quest tortilla chips nacho', 'quest protein chips nacho cheese', 'quest nacho cheese'],
 'snacks', 'Quest', 1, '150 cal per 32g bag. 18g protein. Tortilla style, baked not fried. Dairy-based complete protein.', TRUE),

-- Quest Cheddar & Sour Cream Chips: 140 cal per 32g bag
('quest_cheddar_sour_cream_chips', 'Quest Cheddar & Sour Cream Protein Chips', 437.5, 65.6, 15.6, 14.1,
 3.1, 0.0, NULL, 32,
 'manufacturer', ARRAY['quest cheddar sour cream chips', 'quest chips cheddar sour cream', 'quest cheddar and sour cream', 'quest protein chips cheddar', 'quest cheddar sour cream'],
 'snacks', 'Quest', 1, '140 cal per 32g bag. 21g protein. Original style, baked not fried. Dairy-based complete protein.', TRUE),

-- ══════════════════════════════════════════
-- QUEST — PROTEIN COOKIES
-- ══════════════════════════════════════════

-- Quest Chocolate Chip Cookie: 240 cal per 59g
('quest_chocolate_chip_cookie', 'Quest Protein Cookie Chocolate Chip', 406.8, 25.4, 32.2, 28.8,
 15.3, 1.7, NULL, 59,
 'manufacturer', ARRAY['quest cookie chocolate chip', 'quest chocolate chip cookie', 'quest protein cookie chocolate', 'quest cookie choc chip', 'quest cookies chocolate chip'],
 'snacks', 'Quest', 1, '240 cal per 59g cookie. 15g protein, 9g fiber. Contains 8g sugar alcohols (erythritol/allulose). Net carbs ~2g. Keto-friendly.', TRUE),

-- Quest Peanut Butter Cookie: 210 cal per 58g
('quest_peanut_butter_cookie', 'Quest Protein Cookie Peanut Butter', 362.1, 25.9, 39.7, 22.4,
 19.0, 1.7, NULL, 58,
 'manufacturer', ARRAY['quest cookie peanut butter', 'quest peanut butter cookie', 'quest protein cookie peanut butter', 'quest cookie pb', 'quest cookies peanut butter'],
 'snacks', 'Quest', 1, '210 cal per 58g cookie. 15g protein, 11g fiber. Contains 7g sugar alcohols. Net carbs ~5g. Keto-friendly.', TRUE),

-- ══════════════════════════════════════════
-- BAREBELLS — PROTEIN BARS
-- ══════════════════════════════════════════

-- Barebells Hazelnut & Nougat: 210 cal per 55g bar
('barebells_hazelnut_nougat', 'Barebells Hazelnut & Nougat Protein Bar', 381.8, 36.4, 32.7, 16.4,
 5.5, 1.8, NULL, 55,
 'manufacturer', ARRAY['barebells hazelnut nougat', 'barebells hazelnut and nougat', 'barebells protein bar hazelnut', 'barebells hazelnut bar', 'barebells nougat'],
 'protein_bar', 'Barebells', 1, '210 cal per 55g bar. 20g protein, no added sugar. Contains 5g sugar alcohols. Milk protein blend.', TRUE),

-- Barebells White Chocolate Almond: 200 cal per 55g bar
('barebells_white_chocolate_almond', 'Barebells White Chocolate Almond Protein Bar', 363.6, 36.4, 34.5, 14.5,
 7.3, 1.8, NULL, 55,
 'manufacturer', ARRAY['barebells white chocolate almond', 'barebells white choc almond', 'barebells protein bar white chocolate', 'barebells white chocolate bar', 'barebells almond'],
 'protein_bar', 'Barebells', 1, '200 cal per 55g bar. 20g protein, no added sugar. Contains 6g sugar alcohols. Milk protein blend.', TRUE),

-- ══════════════════════════════════════════
-- GHOST — WHEY PROTEIN POWDER
-- ══════════════════════════════════════════

-- Ghost Whey Chips Ahoy: 160 cal per 39g scoop
('ghost_whey_chips_ahoy', 'Ghost Whey Protein Chips Ahoy', 410.3, 64.1, 17.9, 7.7,
 0.0, 10.3, 39, NULL,
 'manufacturer', ARRAY['ghost whey chips ahoy', 'ghost protein chips ahoy', 'ghost chips ahoy protein powder', 'ghost whey protein chips ahoy', 'ghost chips ahoy'],
 'protein_powder', 'Ghost', 1, '160 cal per 39g scoop. 25g whey protein (isolate + concentrate + hydrolyzed). Licensed Chips Ahoy flavor. Mix with 5-6oz water.', TRUE),

-- Ghost Whey Oreo: 150 cal per 39g scoop
('ghost_whey_oreo', 'Ghost Whey Protein Oreo', 384.6, 64.1, 17.9, 5.1,
 2.6, 7.7, 39, NULL,
 'manufacturer', ARRAY['ghost whey oreo', 'ghost protein oreo', 'ghost oreo protein powder', 'ghost whey protein oreo', 'ghost oreo'],
 'protein_powder', 'Ghost', 1, '150 cal per 39g scoop. 25g whey protein (isolate + concentrate + hydrolyzed). Licensed Oreo flavor. Mix with 5-6oz water.', TRUE),

-- Ghost Whey Nutter Butter: 160 cal per 42.1g scoop
('ghost_whey_nutter_butter', 'Ghost Whey Protein Nutter Butter', 380.0, 61.8, 19.0, 5.9,
 2.4, 7.1, 42, NULL,
 'manufacturer', ARRAY['ghost whey nutter butter', 'ghost protein nutter butter', 'ghost nutter butter protein powder', 'ghost whey protein nutter butter', 'ghost nutter butter'],
 'protein_powder', 'Ghost', 1, '160 cal per 42.1g scoop. 26g whey protein (isolate + concentrate + hydrolyzed). Licensed Nutter Butter flavor with cookie pieces. Mix with 5-6oz water.', TRUE),

-- ══════════════════════════════════════════
-- CHOBANI — COMPLETE ADVANCED NUTRITION YOGURT
-- ══════════════════════════════════════════

-- Chobani Complete Vanilla: 130 cal per 170g (3/4 cup)
('chobani_complete_vanilla', 'Chobani Complete Vanilla Greek Yogurt', 76.5, 10.0, 6.5, 1.8,
 1.8, 4.1, 170, NULL,
 'manufacturer', ARRAY['chobani complete vanilla', 'chobani complete yogurt vanilla', 'chobani advanced nutrition vanilla', 'chobani complete greek vanilla', 'chobani complete vanilla yogurt'],
 'yogurt', 'Chobani', 1, '130 cal per 170g (3/4 cup). 17g protein, lactose-free, no added sugar. All 9 essential amino acids. Live & active cultures.', TRUE),

-- Chobani Complete Mixed Berry: 120 cal per 150g (5.3oz)
('chobani_complete_mixed_berry', 'Chobani Complete Mixed Berry Greek Yogurt', 80.0, 10.0, 8.0, 1.7,
 2.0, 4.7, 150, NULL,
 'manufacturer', ARRAY['chobani complete mixed berry', 'chobani complete yogurt mixed berry', 'chobani advanced nutrition mixed berry', 'chobani complete greek berry', 'chobani complete berry yogurt'],
 'yogurt', 'Chobani', 1, '120 cal per 150g (5.3oz). 15g protein, lactose-free, no added sugar. All 9 essential amino acids. Live & active cultures.', TRUE),

-- ══════════════════════════════════════════
-- HALO TOP — LIGHT ICE CREAM
-- ══════════════════════════════════════════

-- Halo Top Birthday Cake: 100 cal per 85g (2/3 cup)
('halotop_birthday_cake', 'Halo Top Birthday Cake Light Ice Cream', 117.6, 7.1, 22.4, 2.9,
 3.5, 9.4, 85, NULL,
 'manufacturer', ARRAY['halo top birthday cake', 'halotop birthday cake', 'halo top ice cream birthday cake', 'halo top birthday cake ice cream', 'halo top bday cake'],
 'ice_cream', 'Halo Top', 1, '100 cal per 85g (2/3 cup). ~400 cal per pint. Uses erythritol + stevia. Light ice cream with fiber from inulin.', TRUE),

-- Halo Top Peanut Butter Cup: 110 cal per 87g (2/3 cup)
('halotop_peanut_butter_cup', 'Halo Top Peanut Butter Cup Light Ice Cream', 126.4, 6.9, 25.3, 3.4,
 6.9, 8.0, 87, NULL,
 'manufacturer', ARRAY['halo top peanut butter cup', 'halotop peanut butter cup', 'halo top ice cream peanut butter', 'halo top pb cup', 'halo top peanut butter'],
 'ice_cream', 'Halo Top', 1, '110 cal per 87g (2/3 cup). ~330 cal per pint. Uses erythritol + stevia. Light ice cream with fiber from inulin.', TRUE),

-- Halo Top Strawberry: 100 cal per 86g (2/3 cup)
('halotop_strawberry', 'Halo Top Strawberry Light Ice Cream', 116.3, 7.0, 22.1, 2.3,
 3.5, 9.3, 86, NULL,
 'manufacturer', ARRAY['halo top strawberry', 'halotop strawberry', 'halo top ice cream strawberry', 'halo top strawberry ice cream', 'halo top strawberry light'],
 'ice_cream', 'Halo Top', 1, '100 cal per 86g (2/3 cup). ~270 cal per pint. Uses erythritol + stevia. Light ice cream with fiber from inulin.', TRUE),

-- Halo Top Cookies & Cream: 100 cal per 86g (2/3 cup)
('halotop_cookies_and_cream', 'Halo Top Cookies & Cream Light Ice Cream', 116.3, 7.0, 26.7, 2.3,
 7.0, 9.3, 86, NULL,
 'manufacturer', ARRAY['halo top cookies and cream', 'halotop cookies cream', 'halo top ice cream cookies cream', 'halo top cookies & cream', 'halo top cookies cream'],
 'ice_cream', 'Halo Top', 1, '100 cal per 86g (2/3 cup). ~310 cal per pint. Uses erythritol + stevia. Light ice cream with fiber from inulin.', TRUE),

-- Halo Top Mint Chip: 110 cal per 86g (2/3 cup)
('halotop_mint_chip', 'Halo Top Mint Chip Light Ice Cream', 127.9, 5.8, 26.7, 2.9,
 7.0, 11.6, 86, NULL,
 'manufacturer', ARRAY['halo top mint chip', 'halotop mint chip', 'halo top ice cream mint chip', 'halo top mint chocolate chip', 'halo top mint chip light'],
 'ice_cream', 'Halo Top', 1, '110 cal per 86g (2/3 cup). ~330 cal per pint. Uses erythritol + stevia. Light ice cream with fiber from inulin.', TRUE)

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
