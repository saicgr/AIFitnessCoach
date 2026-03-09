-- 1624_overrides_low_cal_bread_pasta_snacks.sql
-- Low-calorie bread, pasta alternatives, and healthy snacks.
-- Sources: Package nutrition labels via fatsecret.com, eatthismuch.com,
-- nutritionvalue.org, manufacturer websites, mynetdiary.com.
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
-- SCHMIDT 647 — LOW CALORIE BREAD
-- ══════════════════════════════════════════

-- Schmidt 647 Wheat Bread: 40 cal per slice (28g). 2g P, 14g C (7g fiber), 0.5g F per slice.
('schmidt647_wheat_bread', 'Schmidt 647 Wheat Bread', 143, 7.1, 50.0, 1.8,
 25.0, 3.6, NULL, 28,
 'manufacturer', ARRAY['schmidt 647 wheat bread', 'schmidt old tyme 647 wheat bread', '647 wheat bread', '647 bread wheat', 'schmidt 647 bread'],
 'bread', 'Schmidt 647', 1, '40 cal per slice (28g). 7g fiber, 6g net carbs per slice. Keto-friendly high-fiber bread.', TRUE),

-- Schmidt 647 Multigrain Bread: 40 cal per slice (28g). 2g P, 14g C (8g fiber), 0.5g F per slice.
('schmidt647_multigrain_bread', 'Schmidt 647 Multigrain Bread', 143, 7.1, 50.0, 1.8,
 28.6, 3.6, NULL, 28,
 'manufacturer', ARRAY['schmidt 647 multigrain bread', 'schmidt old tyme 647 multigrain bread', '647 multigrain bread', '647 bread multigrain', 'schmidt 647 multi grain'],
 'bread', 'Schmidt 647', 1, '40 cal per slice (28g). 8g fiber, 6g net carbs per slice. High-fiber multigrain bread.', TRUE),

-- Schmidt 647 Sandwich Rolls: 80 cal per roll (50g). 4g P, 23g C (9g fiber), 1g F per roll.
('schmidt647_sandwich_rolls', 'Schmidt 647 Sandwich Rolls', 160, 8.0, 46.0, 2.0,
 18.0, 2.0, NULL, 50,
 'manufacturer', ARRAY['schmidt 647 rolls', 'schmidt 647 sandwich rolls', 'schmidt old tyme 647 rolls', '647 sandwich rolls', '647 everything rolls'],
 'bread', 'Schmidt 647', 1, '80 cal per roll (50g). 9g fiber, 14g net carbs. Low-calorie sandwich roll.', TRUE),

-- ══════════════════════════════════════════
-- SARA LEE DELIGHTFUL — LOW CALORIE BREAD
-- ══════════════════════════════════════════

-- Sara Lee Delightful 45 Cal Wheat Bread: 45 cal per slice (23g). 3g P, 9g C (2.5g fiber), 0.5g F per slice.
('saraleelite_wheat_bread', 'Sara Lee Delightful 45 Cal Wheat Bread', 196, 13.0, 39.1, 2.2,
 10.9, 4.3, NULL, 23,
 'manufacturer', ARRAY['sara lee delightful wheat bread', 'sara lee 45 calorie wheat bread', 'sara lee delightful 45 cal wheat', 'sara lee delightful honey whole wheat bread', 'sara lee light wheat bread'],
 'bread', 'Sara Lee', 1, '45 cal per slice (23g). 2.5g fiber per slice. No high fructose corn syrup, no artificial colors.', TRUE),

-- Sara Lee Delightful 45 Cal Multi-Grain Bread: 45 cal per slice (23g). 3g P, 9.5g C (2.5g fiber), 0.5g F per slice.
('saraleelite_multigrain_bread', 'Sara Lee Delightful 45 Cal Multi-Grain Bread', 196, 13.0, 41.3, 2.2,
 10.9, 4.3, NULL, 23,
 'manufacturer', ARRAY['sara lee delightful multi grain bread', 'sara lee 45 calorie multi grain bread', 'sara lee delightful multigrain bread', 'sara lee delightful healthy multi-grain bread', 'sara lee light multigrain bread'],
 'bread', 'Sara Lee', 1, '45 cal per slice (23g). 2.5g fiber per slice. Healthy multi-grain with no artificial colors or flavors.', TRUE),

-- ══════════════════════════════════════════
-- MISSION CARB BALANCE — LOW CARB TORTILLAS
-- ══════════════════════════════════════════

-- Mission Carb Balance Soft Taco Flour: 70 cal per tortilla (42g). 6g P, 19g C (15g fiber), 3.5g F.
('mission_cb_soft_taco_flour', 'Mission Carb Balance Soft Taco Flour Tortilla', 167, 14.3, 45.2, 8.3,
 35.7, 0.0, NULL, 42,
 'manufacturer', ARRAY['mission carb balance soft taco', 'mission carb balance flour tortilla', 'mission low carb tortilla', 'mission carb balance taco tortilla', 'carb balance soft taco flour'],
 'tortilla', 'Mission', 1, '70 cal per tortilla (42g). 15g fiber, only 4g net carbs. Keto certified, GLP-1 friendly.', TRUE),

-- Mission Carb Balance Burrito Size Flour: 110 cal per tortilla (63g). 8g P, 32g C (28g fiber), 3.5g F.
('mission_cb_burrito_flour', 'Mission Carb Balance Burrito Size Flour Tortilla', 175, 12.7, 50.8, 5.6,
 44.4, 0.0, NULL, 63,
 'manufacturer', ARRAY['mission carb balance burrito tortilla', 'mission carb balance burrito flour', 'mission low carb burrito tortilla', 'carb balance burrito size flour', 'mission burrito carb balance'],
 'tortilla', 'Mission', 1, '110 cal per tortilla (63g). 28g fiber, only 4g net carbs. Large burrito size, keto friendly.', TRUE),

-- Mission Carb Balance Soft Taco Whole Wheat: 60 cal per tortilla (43g). 5g P, 20g C (18g fiber), 2.5g F.
('mission_cb_whole_wheat', 'Mission Carb Balance Soft Taco Whole Wheat Tortilla', 140, 11.6, 46.5, 5.8,
 41.9, 0.0, NULL, 43,
 'manufacturer', ARRAY['mission carb balance whole wheat tortilla', 'mission carb balance whole wheat taco', 'mission low carb whole wheat', 'carb balance whole wheat soft taco', 'mission whole wheat carb balance'],
 'tortilla', 'Mission', 1, '60 cal per tortilla (43g). 18g fiber, only 2g net carbs. Whole wheat, keto certified.', TRUE),

-- ══════════════════════════════════════════
-- EGGLIFE — EGG WHITE WRAPS
-- ══════════════════════════════════════════

-- Egglife Original Egg White Wrap: 25 cal per wrap (28g). 5g P, 0g C, 0g F.
('egglife_original', 'Egglife Original Egg White Wrap', 89, 17.9, 0.0, 0.0,
 0.0, 0.0, NULL, 28,
 'manufacturer', ARRAY['egglife original wrap', 'egglife egg white wrap', 'egg life original', 'egglife wraps original', 'egg white wrap original'],
 'wrap', 'Egglife', 1, '25 cal per wrap (28g). 5g protein, zero carbs, zero fat. 95% cage-free egg whites. Keto & paleo friendly.', TRUE),

-- Egglife Everything Bagel Egg White Wrap: 35 cal per wrap (28g). 6g P, 1g C, 0g F.
('egglife_everything_bagel', 'Egglife Everything Bagel Egg White Wrap', 125, 21.4, 3.6, 0.0,
 0.0, 0.0, NULL, 28,
 'manufacturer', ARRAY['egglife everything bagel wrap', 'egglife everything bagel', 'egg life everything bagel', 'egglife wraps everything bagel', 'egg white wrap everything bagel'],
 'wrap', 'Egglife', 1, '35 cal per wrap (28g). 6g protein, 1g carb. Seasoned with garlic, onion, poppy & hemp seed.', TRUE),

-- ══════════════════════════════════════════
-- MIRACLE NOODLE — SHIRATAKI NOODLES
-- ══════════════════════════════════════════

-- Miracle Noodle Fettuccine: 5 cal per serving (113g). 0g P, 3g C (3g fiber), 0g F.
('miraclenoodle_fettuccine', 'Miracle Noodle Fettuccine', 4, 0.0, 2.7, 0.0,
 2.7, 0.0, 113, NULL,
 'manufacturer', ARRAY['miracle noodle fettuccine', 'miracle noodle fettuccini', 'shirataki fettuccine', 'shirataki noodles fettuccine', 'zero calorie fettuccine'],
 'pasta_alternative', 'Miracle Noodle', 1, '5 cal per serving (113g). 97% water, 3% soluble plant fiber. Konjac-based, zero net carbs.', TRUE),

-- Miracle Noodle Angel Hair: 5 cal per serving (113g). 0g P, 3g C (3g fiber), 0g F.
('miraclenoodle_angel_hair', 'Miracle Noodle Angel Hair', 4, 0.0, 2.7, 0.0,
 2.7, 0.0, 113, NULL,
 'manufacturer', ARRAY['miracle noodle angel hair', 'shirataki angel hair', 'shirataki noodles angel hair', 'zero calorie angel hair', 'miracle noodle thin noodles'],
 'pasta_alternative', 'Miracle Noodle', 1, '5 cal per serving (113g). Plant-based konjac shirataki noodles. Gluten-free, vegan, keto.', TRUE),

-- Miracle Noodle Rice: 5 cal per serving (113g). 0g P, 3g C (3g fiber), 0g F.
('miraclenoodle_rice', 'Miracle Noodle Rice', 4, 0.0, 2.7, 0.0,
 2.7, 0.0, 113, NULL,
 'manufacturer', ARRAY['miracle noodle rice', 'miracle rice', 'shirataki rice', 'zero calorie rice', 'konjac rice'],
 'pasta_alternative', 'Miracle Noodle', 1, '5 cal per serving (113g). Rice-shaped shirataki. 1g net carb. Keto, gluten-free, vegan.', TRUE),

-- ══════════════════════════════════════════
-- PALMINI — HEARTS OF PALM PASTA
-- ══════════════════════════════════════════

-- Palmini Linguine: 20 cal per serving (113g). 1g P, 4g C, 0g F.
('palmini_linguine', 'Palmini Hearts of Palm Linguine', 18, 0.9, 3.5, 0.0,
 0.9, 0.0, 113, NULL,
 'manufacturer', ARRAY['palmini linguine', 'palmini hearts of palm linguine', 'palmini pasta linguine', 'hearts of palm linguine', 'palmini low carb linguine'],
 'pasta_alternative', 'Palmini', 1, '20 cal per serving (113g). Made from hearts of palm. Sugar-free, gluten-free. As seen on Shark Tank.', TRUE),

-- Palmini Angel Hair: 20 cal per serving (113g). 1g P, 4g C, 0g F.
('palmini_angel_hair', 'Palmini Hearts of Palm Angel Hair', 18, 0.9, 3.5, 0.0,
 0.9, 0.0, 113, NULL,
 'manufacturer', ARRAY['palmini angel hair', 'palmini hearts of palm angel hair', 'palmini pasta angel hair', 'hearts of palm angel hair', 'palmini low carb angel hair'],
 'pasta_alternative', 'Palmini', 1, '20 cal per serving (113g). Hearts of palm cut into thin angel hair shape. Keto, vegan, non-GMO.', TRUE),

-- ══════════════════════════════════════════
-- YASSO — FROZEN GREEK YOGURT BARS
-- ══════════════════════════════════════════

-- Yasso Mint Chocolate Chip Bar: 100 cal per bar (65g). 5g P, 16g C, 2g F.
('yasso_mint_choc_chip', 'Yasso Mint Chocolate Chip Greek Yogurt Bar', 154, 7.7, 24.6, 3.1,
 0.0, 12.3, NULL, 65,
 'manufacturer', ARRAY['yasso mint chocolate chip', 'yasso mint choc chip bar', 'yasso mint chocolate chip frozen yogurt bar', 'yasso greek yogurt bar mint', 'yasso mint chip'],
 'frozen_dessert', 'Yasso', 1, '100 cal per bar (65g). 5g protein. Made with real Greek yogurt. No sugar alcohols.', TRUE),

-- Yasso Chocolate Fudge Bar: 80 cal per bar (65g). 5g P, 13g C, 1.5g F.
('yasso_choc_fudge', 'Yasso Chocolate Fudge Greek Yogurt Bar', 123, 7.7, 20.0, 2.3,
 0.0, 10.8, NULL, 65,
 'manufacturer', ARRAY['yasso chocolate fudge', 'yasso chocolate fudge bar', 'yasso chocolate fudge frozen yogurt bar', 'yasso greek yogurt bar chocolate fudge', 'yasso fudge bar'],
 'frozen_dessert', 'Yasso', 1, '80 cal per bar (65g). 5g protein. Rich chocolate fudge flavor with real Greek yogurt.', TRUE),

-- Yasso Sea Salt Caramel Bar: 100 cal per bar (65g). 4g P, 16g C, 2.5g F.
('yasso_sea_salt_caramel', 'Yasso Sea Salt Caramel Greek Yogurt Bar', 154, 6.2, 24.6, 3.8,
 0.0, 13.8, NULL, 65,
 'manufacturer', ARRAY['yasso sea salt caramel', 'yasso sea salt caramel bar', 'yasso caramel frozen yogurt bar', 'yasso greek yogurt bar sea salt caramel', 'yasso caramel bar'],
 'frozen_dessert', 'Yasso', 1, '100 cal per bar (65g). 4g protein. Sea salt caramel swirl in creamy Greek yogurt.', TRUE),

-- Yasso Cookies & Cream Bar: 100 cal per bar (65g). 5g P, 16g C, 2g F.
('yasso_cookies_cream', 'Yasso Cookies & Cream Greek Yogurt Bar', 154, 7.7, 24.6, 3.1,
 0.0, 12.3, NULL, 65,
 'manufacturer', ARRAY['yasso cookies and cream', 'yasso cookies cream bar', 'yasso cookies n cream frozen yogurt bar', 'yasso greek yogurt bar cookies cream', 'yasso cookies & cream'],
 'frozen_dessert', 'Yasso', 1, '100 cal per bar (65g). 5g protein. Cookies & cream flavor made with real Greek yogurt.', TRUE),

-- ══════════════════════════════════════════
-- SKINNY POP — POPCORN
-- ══════════════════════════════════════════

-- SkinnyPop Original Popcorn: 150 cal per serving (28g). 2g P, 17g C (4g fiber), 10g F.
('skinnypop_original', 'SkinnyPop Original Popcorn', 536, 7.1, 60.7, 35.7,
 14.3, 0.0, 28, NULL,
 'manufacturer', ARRAY['skinnypop original', 'skinny pop original popcorn', 'skinnypop popcorn', 'skinny pop original', 'skinnypop original popcorn bag'],
 'popcorn', 'Skinny Pop', 1, '150 cal per serving (28g). Popped in sunflower oil. No artificial anything. Whole grain, dairy-free.', TRUE),

-- SkinnyPop White Cheddar Popcorn: 150 cal per serving (28g). 2g P, 16g C (3g fiber), 10g F.
('skinnypop_white_cheddar', 'SkinnyPop White Cheddar Popcorn', 536, 7.1, 57.1, 35.7,
 10.7, 3.6, 28, NULL,
 'manufacturer', ARRAY['skinnypop white cheddar', 'skinny pop white cheddar popcorn', 'skinnypop aged white cheddar', 'skinny pop white cheddar', 'skinnypop white cheddar popcorn bag'],
 'popcorn', 'Skinny Pop', 1, '150 cal per serving (28g). White cheddar flavor. Dairy-free, gluten-free, no GMOs.', TRUE),

-- SkinnyPop Mini Cakes Sea Salt: 60 cal per serving (13g, ~11 cakes). 1g P, 10g C (0g fiber), 2g F.
('skinnypop_mini_cakes', 'SkinnyPop Mini Cakes Sea Salt', 462, 7.7, 76.9, 15.4,
 0.0, 0.0, 13, NULL,
 'manufacturer', ARRAY['skinnypop mini cakes', 'skinny pop mini cakes', 'skinnypop popcorn mini cakes', 'skinny pop mini cakes sea salt', 'skinnypop rice cakes mini'],
 'popcorn', 'Skinny Pop', 1, '60 cal per serving (13g, ~11 mini cakes). Light, crunchy popcorn cakes. Gluten-free, vegan.', TRUE),

-- ══════════════════════════════════════════
-- SMARTSWEETS — LOW SUGAR CANDY
-- ══════════════════════════════════════════

-- SmartSweets Sour Blast Buddies: 130 cal per bag (50g). 0g P, 40g C (6g fiber), 0g F. 3g sugar.
('smartsweets_sour_blast', 'SmartSweets Sour Blast Buddies', 260, 0.0, 80.0, 0.0,
 12.0, 6.0, NULL, 50,
 'manufacturer', ARRAY['smartsweets sour blast buddies', 'smart sweets sour blast', 'smartsweets sour gummies', 'smartsweets sour candy', 'smart sweets sour blast buddies'],
 'candy', 'SmartSweets', 1, '130 cal per bag (50g). Only 3g sugar. Sweetened with stevia, monk fruit & allulose. Plant-based, vegan.', TRUE),

-- SmartSweets Sweet Fish: 130 cal per bag (50g). 0g P, 40g C (6g fiber), 0g F. 3g sugar.
('smartsweets_sweet_fish', 'SmartSweets Sweet Fish', 260, 0.0, 80.0, 0.0,
 12.0, 6.0, NULL, 50,
 'manufacturer', ARRAY['smartsweets sweet fish', 'smart sweets sweet fish', 'smartsweets fish gummies', 'smartsweets swedish fish alternative', 'smart sweets fish candy'],
 'candy', 'SmartSweets', 1, '130 cal per bag (50g). Only 3g sugar. Fish-shaped gummies, vegan, gluten-free.', TRUE),

-- SmartSweets Peach Rings: 130 cal per bag (50g). 0g P, 40g C (6g fiber), 0g F. 3g sugar.
('smartsweets_peach_rings', 'SmartSweets Peach Rings', 260, 0.0, 80.0, 0.0,
 12.0, 6.0, NULL, 50,
 'manufacturer', ARRAY['smartsweets peach rings', 'smart sweets peach rings', 'smartsweets peach gummies', 'smartsweets peach candy rings', 'smart sweets peach rings candy'],
 'candy', 'SmartSweets', 1, '130 cal per bag (50g). Only 3g sugar. Plant-based peach ring gummies. 92% less sugar than traditional.', TRUE),

-- ══════════════════════════════════════════
-- ENLIGHTENED — BEAN CRISPS
-- ══════════════════════════════════════════

-- Enlightened Mesquite BBQ Bean Crisps: 100 cal per serving (28g). 7g P, 15g C (5g fiber), 3g F.
('enlightened_crisps_mesquite_bbq', 'Enlightened Roasted Broad Bean Crisps Mesquite BBQ', 357, 25.0, 53.6, 10.7,
 17.9, 3.6, 28, NULL,
 'manufacturer', ARRAY['enlightened mesquite bbq', 'enlightened bean crisps bbq', 'enlightened roasted broad bean crisps mesquite', 'enlightened bbq crisps', 'enlightened broad bean bbq'],
 'snack', 'Enlightened', 1, '100 cal per serving (28g). 7g protein, 5g fiber. Gluten-free roasted broad bean crisps.', TRUE),

-- Enlightened Sriracha Bean Crisps: 100 cal per serving (28g). 7g P, 15g C (5g fiber), 3g F.
('enlightened_crisps_sriracha', 'Enlightened Roasted Broad Bean Crisps Sriracha', 357, 25.0, 53.6, 10.7,
 17.9, 3.6, 28, NULL,
 'manufacturer', ARRAY['enlightened sriracha', 'enlightened bean crisps sriracha', 'enlightened roasted broad bean crisps sriracha', 'enlightened sriracha crisps', 'enlightened broad bean sriracha'],
 'snack', 'Enlightened', 1, '100 cal per serving (28g). 7g protein, 5g fiber. Spicy sriracha flavored broad bean crisps.', TRUE),

-- ══════════════════════════════════════════
-- GREEN GIANT — CAULIFLOWER PRODUCTS
-- ══════════════════════════════════════════

-- Green Giant Riced Cauliflower: 20 cal per cup (85g). 2g P, 4g C (2g fiber), 0g F.
('greengiant_riced_cauliflower', 'Green Giant Riced Cauliflower', 24, 2.4, 4.7, 0.0,
 2.4, 1.2, 85, NULL,
 'manufacturer', ARRAY['green giant riced cauliflower', 'green giant cauliflower rice', 'green giant riced veggies cauliflower', 'cauliflower rice frozen green giant', 'green giant cauliflower riced'],
 'vegetable_alternative', 'Green Giant', 1, '20 cal per cup (85g). 85% fewer calories than regular rice. Frozen, gluten-free, no sauce.', TRUE),

-- Green Giant Cauliflower Pizza Crust: 80 cal per 1/3 crust (57g). 2g P, 16g C (2g fiber), 1g F.
('greengiant_cauliflower_pizza_crust', 'Green Giant Cauliflower Pizza Crust', 140, 3.5, 28.1, 1.8,
 3.5, 3.5, NULL, 57,
 'manufacturer', ARRAY['green giant cauliflower pizza crust', 'green giant cauliflower crust', 'cauliflower pizza crust frozen green giant', 'green giant pizza crust cauliflower', 'cauliflower crust green giant'],
 'vegetable_alternative', 'Green Giant', 1, '80 cal per 1/3 crust (57g). 50% fewer calories than regular pizza crust. Frozen ready-to-top crust.', TRUE),

-- Green Giant Veggie Tots Cauliflower: 110 cal per 6 tots (85g). 2g P, 14g C (5g fiber), 7g F.
('greengiant_veggie_tots', 'Green Giant Veggie Tots Cauliflower', 129, 2.4, 16.5, 8.2,
 5.9, 1.2, 85, NULL,
 'manufacturer', ARRAY['green giant veggie tots', 'green giant cauliflower tots', 'green giant veggie tots cauliflower', 'cauliflower tots frozen green giant', 'green giant tater tots cauliflower'],
 'vegetable_alternative', 'Green Giant', 1, '110 cal per 6 tots (85g). Full serving of vegetables per USDA database. No artificial flavors.', TRUE),

-- Green Giant Cauliflower Gnocchi: 100 cal per cup (140g). 2g P, 21g C (2g fiber), 0.5g F.
('greengiant_cauliflower_gnocchi', 'Green Giant Cauliflower Gnocchi', 71, 1.4, 15.0, 0.4,
 1.4, 2.1, 140, NULL,
 'manufacturer', ARRAY['green giant cauliflower gnocchi', 'green giant gnocchi cauliflower', 'cauliflower gnocchi frozen green giant', 'green giant cauliflower gnocchi original', 'cauliflower gnocchi green giant'],
 'vegetable_alternative', 'Green Giant', 1, '100 cal per cup (140g). Veggie-based potato gnocchi swap. Frozen, ready to cook.', TRUE),

-- ══════════════════════════════════════════
-- FIBER ONE — SNACK BARS
-- ══════════════════════════════════════════

-- Fiber One 70 Cal Brownie Chocolate Fudge: 70 cal per bar (25g). 1g P, 17g C (7g fiber), 3g F.
('fiberone_brownie_chocolate', 'Fiber One 70 Cal Brownie Chocolate Fudge', 280, 4.0, 68.0, 12.0,
 28.0, 8.0, NULL, 25,
 'manufacturer', ARRAY['fiber one brownie chocolate fudge', 'fiber one 70 calorie brownie', 'fiber one chocolate fudge brownie', 'fiber one brownie', 'fiberone 70 cal brownie chocolate'],
 'snack_bar', 'Fiber One', 1, '70 cal per bar (25g). 7g fiber (26% DV), only 2g sugar. Soft-baked brownie texture.', TRUE),

-- Fiber One 70 Cal Brownie Mint: 70 cal per bar (25g). 1g P, 17g C (7g fiber), 3g F.
('fiberone_brownie_mint', 'Fiber One 70 Cal Brownie Mint Fudge', 280, 4.0, 68.0, 12.0,
 28.0, 8.0, NULL, 25,
 'manufacturer', ARRAY['fiber one brownie mint', 'fiber one mint brownie', 'fiber one 70 cal mint fudge brownie', 'fiber one mint fudge brownie', 'fiberone brownie mint'],
 'snack_bar', 'Fiber One', 1, '70 cal per bar (25g). 7g fiber, 2g sugar. Mint chocolate fudge flavor.', TRUE),

-- Fiber One 70 Cal Brownie Birthday Cake: 70 cal per bar (25g). 1g P, 17g C (7g fiber), 3g F.
('fiberone_brownie_birthday_cake', 'Fiber One 70 Cal Brownie Birthday Cake', 280, 4.0, 68.0, 12.0,
 28.0, 8.0, NULL, 25,
 'manufacturer', ARRAY['fiber one brownie birthday cake', 'fiber one birthday cake brownie', 'fiber one 70 cal birthday cake', 'fiberone birthday cake brownie', 'fiber one birthday cake bar'],
 'snack_bar', 'Fiber One', 1, '70 cal per bar (25g). 7g fiber, 2g sugar. Birthday cake flavor, soft-baked.', TRUE),

-- Fiber One Protein Bar Caramel Nut: 130 cal per bar (33g). 6g P, 17g C (8g fiber), 6g F.
('fiberone_protein_caramel_nut', 'Fiber One Protein Bar Caramel Nut', 394, 18.2, 51.5, 18.2,
 24.2, 6.1, NULL, 33,
 'manufacturer', ARRAY['fiber one protein bar caramel nut', 'fiber one caramel nut protein bar', 'fiber one protein caramel nut', 'fiberone protein bar caramel', 'fiber one chewy protein bar caramel nut'],
 'snack_bar', 'Fiber One', 1, '130 cal per bar (33g). 6g protein, 8g fiber (20%+ DV), 2g sugar. Chewy caramel nut flavor.', TRUE)

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
