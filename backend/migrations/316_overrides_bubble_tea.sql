-- 316_overrides_bubble_tea.sql
-- Bubble tea / boba chain items: generic drinks and chain-specific items.
-- Chains: Kung Fu Tea, Gong Cha, Tiger Sugar, CoCo Fresh Tea, ShareTea, Boba Guys, The Alley.
-- Sources: kungfutea.com/nutrition, gongchausa.com/nutrition, 1992sharetea.com/nutrition-facts,
--   nutritionix.com, mynetdiary.com, eatthismuch.com, snapcalorie.com, thebobaclub.com,
--   bubbleteaworld.org, myfitnesspal.com, USDA (tapioca pearl data)
-- Nutrition per 100g derived from published per-serving data and standard drink weights.
-- Medium bubble tea ~16oz (480ml) weighs ~500-520g; large ~24oz weighs ~700g.
-- All values at default/100% sugar unless noted. Boba topping NOT included in drink values.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════════════════════════════
-- GENERIC BUBBLE TEA DRINKS
-- ══════════════════════════════════════════════════════════════════

-- Classic Milk Tea with Boba (Regular ~16oz/500g): ~300 cal/serving = 60 cal/100g
-- Sources: nutritionix, snapcalorie, PMC study on boba milk tea
('classic_milk_tea_with_boba', 'Classic Milk Tea with Boba', 60, 0.8, 12.5, 1.2,
 0.1, 8.5, 500, NULL,
 'generic_bubble_tea', ARRAY['milk tea with boba', 'boba milk tea', 'pearl milk tea', 'bubble milk tea', 'PMT', 'classic boba tea'],
 'bubble_tea', NULL, 1, '60 cal/100g. Medium 500g = ~300 cal. Black tea with milk/creamer and tapioca pearls. Standard sugar.', TRUE),

-- Classic Milk Tea with Boba (Large ~24oz/700g): ~420 cal/serving = 60 cal/100g
('classic_milk_tea_with_boba_large', 'Classic Milk Tea with Boba (Large)', 60, 0.8, 12.5, 1.2,
 0.1, 8.5, 700, NULL,
 'generic_bubble_tea', ARRAY['large boba milk tea', 'large pearl milk tea', 'large bubble milk tea'],
 'bubble_tea', NULL, 1, '60 cal/100g. Large 700g = ~420 cal. Black tea with milk/creamer and tapioca pearls.', TRUE),

-- Taro Milk Tea with Boba: ~81 cal/100g per snapcalorie/eatthismuch. Serving 500g = ~405 cal.
('taro_milk_tea_with_boba', 'Taro Milk Tea with Boba', 81, 0.6, 16.0, 1.8,
 0.3, 11.0, 500, NULL,
 'generic_bubble_tea', ARRAY['taro boba', 'taro bubble tea', 'taro milk boba', 'purple milk tea'],
 'bubble_tea', NULL, 1, '81 cal/100g. Medium 500g = ~405 cal. Taro root powder blended with milk tea and tapioca pearls.', TRUE),

-- Thai Milk Tea with Boba: ~67 cal/100g per snapcalorie. Serving 500g = ~335 cal.
('thai_milk_tea_with_boba', 'Thai Milk Tea with Boba', 67, 0.7, 13.0, 1.5,
 0.0, 10.0, 500, NULL,
 'generic_bubble_tea', ARRAY['thai tea boba', 'thai bubble tea', 'thai iced tea boba', 'cha yen boba'],
 'bubble_tea', NULL, 1, '67 cal/100g. Medium 500g = ~335 cal. Orange-hued Thai tea with condensed milk and tapioca pearls.', TRUE),

-- Matcha Milk Tea with Boba: ~58 cal/100g. Serving 500g = ~290 cal.
-- Sources: eatthismuch (Boba Time 248 cal/~430g), mynetdiary, fitia
('matcha_milk_tea_with_boba', 'Matcha Milk Tea with Boba', 58, 0.8, 10.5, 1.4,
 0.2, 7.5, 500, NULL,
 'generic_bubble_tea', ARRAY['matcha boba', 'matcha bubble tea', 'green tea latte boba', 'matcha latte boba'],
 'bubble_tea', NULL, 1, '58 cal/100g. Medium 500g = ~290 cal. Matcha green tea with milk and tapioca pearls.', TRUE),

-- Brown Sugar Milk Tea: ~70 cal/100g. Serving 500g = ~350 cal.
-- Sources: snapcalorie (350 cal/500g serving), nutritionix
('brown_sugar_milk_tea', 'Brown Sugar Milk Tea', 70, 1.0, 12.0, 1.6,
 0.0, 10.5, 500, NULL,
 'generic_bubble_tea', ARRAY['brown sugar boba', 'brown sugar bubble tea', 'tiger milk tea', 'black sugar milk tea'],
 'bubble_tea', NULL, 1, '70 cal/100g. Medium 500g = ~350 cal. Milk tea with caramelized brown sugar syrup and boba.', TRUE),

-- Mango Green Tea (no milk): ~45 cal/100g. Serving 500g = ~225 cal.
-- Sources: bobalicious (250-320 cal range for mango with milk; fruit teas lower), sharetea nutrition
('mango_green_tea', 'Mango Green Tea', 45, 0.2, 11.0, 0.1,
 0.1, 9.5, 500, NULL,
 'generic_bubble_tea', ARRAY['mango tea', 'mango fruit tea', 'mango bubble tea no milk', 'mango iced tea'],
 'bubble_tea', NULL, 1, '45 cal/100g. Medium 500g = ~225 cal. Green tea with mango syrup/puree. No milk, lighter option.', TRUE),

-- Passion Fruit Green Tea: ~42 cal/100g. Serving 500g = ~210 cal.
-- Sources: sharetea nutrition (fruit tea ~200-240 cal), Joyba (130 cal/355ml)
('passion_fruit_green_tea', 'Passion Fruit Green Tea', 42, 0.2, 10.5, 0.1,
 0.1, 9.0, 500, NULL,
 'generic_bubble_tea', ARRAY['passion fruit tea', 'passionfruit green tea', 'passion fruit bubble tea', 'lilikoi tea'],
 'bubble_tea', NULL, 1, '42 cal/100g. Medium 500g = ~210 cal. Green tea with passion fruit syrup. Refreshing, no milk.', TRUE),

-- Fruit Tea (general, no milk): ~38 cal/100g. Serving 500g = ~190 cal.
-- Sources: CoCo (150 kcal fruit tea), bobalicious (100-220 cal range)
('fruit_tea_bubble_tea', 'Fruit Tea', 38, 0.1, 9.5, 0.0,
 0.1, 8.0, 500, NULL,
 'generic_bubble_tea', ARRAY['fruit bubble tea', 'fruity tea', 'fresh fruit tea', 'iced fruit tea'],
 'bubble_tea', NULL, 1, '38 cal/100g. Medium 500g = ~190 cal. Tea-based with fruit syrup/puree. No milk, lowest calorie boba option.', TRUE),

-- Tapioca Pearls (Boba) - cooked, sweetened topping: ~135 cal/100g
-- Sources: USDA dry pearl 358 cal/100g; cooked absorbs water ~2.5x; sweetened with brown sugar syrup
-- nutritionix boba serving 60g = ~100 cal; 156 cal per Gong Cha boba serving (~90g)
('tapioca_pearls_boba', 'Tapioca Pearls (Boba Topping)', 135, 0.1, 33.0, 0.1,
 0.3, 15.0, 60, NULL,
 'generic_bubble_tea', ARRAY['boba pearls', 'boba topping', 'tapioca boba', 'black pearls', 'QQ pearls', 'bubble tea pearls'],
 'bubble_tea', NULL, 1, '135 cal/100g. Standard topping ~60g = ~80 cal. Cooked tapioca pearls in brown sugar syrup.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- KUNG FU TEA
-- ══════════════════════════════════════════════════════════════════

-- Kung Fu Tea Classic Milk Tea (Medium, 100% sugar): 310 cal / ~500g = 62 cal/100g
-- Source: eatthismuch.com, kungfutea.com/nutrition, thebobaclub.com
('kungfu_tea_classic_milk_tea', 'Kung Fu Tea Classic Milk Tea', 62, 0.6, 13.5, 1.0,
 0.0, 9.5, 500, NULL,
 'kung_fu_tea', ARRAY['KFT classic milk tea', 'kung fu milk black tea', 'KFT milk tea'],
 'bubble_tea', 'Kung Fu Tea', 1, '62 cal/100g. Medium ~500g = ~310 cal. Classic black milk tea, 100% sugar. Toppings extra.', TRUE),

-- Kung Fu Tea Taro Milk Tea (Large, 50% sugar): 410 cal / ~700g = 59 cal/100g
-- At 100% sugar, large ~450 cal. Medium 100% ~340 cal / 500g = 68 cal/100g
-- Source: eatthismuch.com, mynetdiary.com
('kungfu_tea_taro_milk_tea', 'Kung Fu Tea Taro Milk Tea', 68, 0.4, 14.5, 1.1,
 0.2, 10.0, 500, NULL,
 'kung_fu_tea', ARRAY['KFT taro milk tea', 'kung fu taro tea', 'KFT taro'],
 'bubble_tea', 'Kung Fu Tea', 1, '68 cal/100g. Medium ~500g = ~340 cal. Taro blended with milk tea. Purple-hued, creamy.', TRUE),

-- Kung Fu Tea Mango Green Tea (Medium, 100% sugar): ~105 cal / ~500g = 21 cal/100g
-- Very light fruit tea. Source: thebobaclub.com (75-105 cal range)
('kungfu_tea_mango_green_tea', 'Kung Fu Tea Mango Green Tea', 21, 0.1, 5.0, 0.0,
 0.0, 4.5, 500, NULL,
 'kung_fu_tea', ARRAY['KFT mango green tea', 'kung fu mango tea', 'KFT mango'],
 'bubble_tea', 'Kung Fu Tea', 1, '21 cal/100g. Medium ~500g = ~105 cal. Light fruit tea with mango flavor. No milk.', TRUE),

-- Kung Fu Tea Thai Tea (Medium, 100% sugar): ~300 cal / ~500g = 60 cal/100g
-- Source: eatthismuch (medium 30% = 220 cal; 100% ~300 cal), mynetdiary
('kungfu_tea_thai_tea', 'Kung Fu Tea Thai Milk Tea', 60, 0.6, 12.5, 1.0,
 0.0, 9.0, 500, NULL,
 'kung_fu_tea', ARRAY['KFT thai tea', 'kung fu thai milk tea', 'KFT thai'],
 'bubble_tea', 'Kung Fu Tea', 1, '60 cal/100g. Medium ~500g = ~300 cal. Thai tea with creamer, no artificial coloring.', TRUE),

-- Kung Fu Tea Oolong Milk Tea (Medium, 50% sugar): 240 cal / ~500g = 48 cal/100g
-- Source: eatthismuch.com (240 cal, 87% carbs, 11% fat, 2% protein)
('kungfu_tea_oolong_milk_tea', 'Kung Fu Tea Oolong Milk Tea', 48, 0.5, 9.5, 0.6,
 0.0, 6.5, 500, NULL,
 'kung_fu_tea', ARRAY['KFT oolong milk tea', 'kung fu oolong tea', 'KFT oolong'],
 'bubble_tea', 'Kung Fu Tea', 1, '48 cal/100g. Medium ~500g = ~240 cal (50% sugar). Roasted oolong with milk. Toasty flavor.', TRUE),

-- Kung Fu Tea Honey Green Tea (Medium, 100% sugar): ~65 cal / ~500g = 13 cal/100g
-- Source: thebobaclub.com (54-65 cal range)
('kungfu_tea_honey_green_tea', 'Kung Fu Tea Honey Green Tea', 13, 0.1, 3.0, 0.0,
 0.0, 2.8, 500, NULL,
 'kung_fu_tea', ARRAY['KFT honey green tea', 'kung fu honey tea', 'KFT honey green'],
 'bubble_tea', 'Kung Fu Tea', 1, '13 cal/100g. Medium ~500g = ~65 cal. Light green tea with honey. Very low calorie, no milk.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- GONG CHA
-- ══════════════════════════════════════════════════════════════════

-- Gong Cha Brown Sugar Milk Tea (Medium): 510 cal / ~500g = 102 cal/100g
-- Source: eatthismuch.com (510 cal, 60% carbs, 39% fat, 2% protein)
('gongcha_brown_sugar_milk_tea', 'Gong Cha Brown Sugar Milk Tea', 102, 1.0, 15.3, 4.4,
 0.0, 13.0, 500, NULL,
 'gong_cha', ARRAY['gong cha brown sugar', 'gong cha BSM', 'gongcha brown sugar boba'],
 'bubble_tea', 'Gong Cha', 1, '102 cal/100g. Medium ~500g = ~510 cal. Rich brown sugar syrup with milk tea. High calorie.', TRUE),

-- Gong Cha Taro Milk Tea (Medium): 249 cal / ~500g = 50 cal/100g
-- Source: mynetdiary.com
('gongcha_taro_milk_tea', 'Gong Cha Taro Milk Tea', 50, 0.4, 10.5, 0.8,
 0.2, 7.5, 500, NULL,
 'gong_cha', ARRAY['gong cha taro', 'gongcha taro tea', 'gong cha taro boba'],
 'bubble_tea', 'Gong Cha', 1, '50 cal/100g. Medium ~500g = ~249 cal. Taro-flavored milk tea, creamy and sweet.', TRUE),

-- Gong Cha Earl Grey Milk Tea (Medium): ~340 cal / ~500g = 68 cal/100g
-- Source: eatthismuch.com (340 cal with 3j toppings; base ~290 cal = 58 cal/100g)
-- Using base drink value
('gongcha_earl_grey_milk_tea', 'Gong Cha Earl Grey Milk Tea', 58, 0.5, 12.0, 0.9,
 0.0, 8.5, 500, NULL,
 'gong_cha', ARRAY['gong cha earl grey', 'gongcha earl grey tea', 'gong cha earl grey boba'],
 'bubble_tea', 'Gong Cha', 1, '58 cal/100g. Medium ~500g = ~290 cal. Bergamot-scented earl grey with milk. Toppings extra.', TRUE),

-- Gong Cha Dirty Brown Sugar (Medium, with milk foam): 690 cal / ~520g = 133 cal/100g
-- Source: eatthismuch.com (690 cal for medium dirty brown sugar with milk foam)
('gongcha_dirty_brown_sugar', 'Gong Cha Dirty Brown Sugar', 133, 1.5, 18.0, 6.0,
 0.0, 15.5, 520, NULL,
 'gong_cha', ARRAY['gong cha dirty brown sugar', 'gongcha dirty BSM', 'gong cha dirty boba'],
 'bubble_tea', 'Gong Cha', 1, '133 cal/100g. Medium ~520g = ~690 cal. Brown sugar tea with milk foam topping. Very indulgent.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- TIGER SUGAR
-- ══════════════════════════════════════════════════════════════════

-- Tiger Sugar Brown Sugar Boba Milk (signature, regular): 300 cal / ~480g = 63 cal/100g
-- Source: mynetdiary (300 cal regular), itsbobatime.com (289 cal), thebobaclub.com
('tiger_sugar_brown_sugar_boba_milk', 'Tiger Sugar Brown Sugar Boba Milk', 63, 0.8, 10.8, 1.5,
 0.0, 9.5, 480, NULL,
 'tiger_sugar', ARRAY['tiger sugar signature', 'tiger sugar boba milk', 'tiger sugar original', 'tiger stripe milk tea'],
 'bubble_tea', 'Tiger Sugar', 1, '63 cal/100g. Regular ~480g = ~300 cal. Signature tiger-striped brown sugar with fresh milk and boba.', TRUE),

-- Tiger Sugar Black Sugar Pearl Milk (regular): 300 cal / ~480g = 63 cal/100g
-- Source: itsbobatime (300 cal regular, 6g fat, 38g carbs, 38g sugar)
('tiger_sugar_black_sugar_pearl_milk', 'Tiger Sugar Black Sugar Pearl Milk', 63, 0.6, 7.9, 1.3,
 0.0, 7.9, 480, NULL,
 'tiger_sugar', ARRAY['tiger sugar black sugar', 'tiger sugar pearl milk', 'black sugar boba milk'],
 'bubble_tea', 'Tiger Sugar', 1, '63 cal/100g. Regular ~480g = ~300 cal. Black sugar syrup with fresh milk and tapioca pearls.', TRUE),

-- Tiger Sugar Brown Sugar Milk Tea (regular): ~320 cal / ~480g = 67 cal/100g
-- Source: thebobaclub.com (brown sugar milk tea slightly higher than no-tea version)
('tiger_sugar_brown_sugar_milk_tea', 'Tiger Sugar Brown Sugar Milk Tea', 67, 0.7, 12.0, 1.4,
 0.0, 9.0, 480, NULL,
 'tiger_sugar', ARRAY['tiger sugar milk tea', 'tiger sugar BSM tea', 'tiger brown sugar tea'],
 'bubble_tea', 'Tiger Sugar', 1, '67 cal/100g. Regular ~480g = ~320 cal. Brown sugar boba milk with tea base added.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- COCO FRESH TEA & JUICE
-- ══════════════════════════════════════════════════════════════════

-- CoCo Milk Tea (CoCo''s signature): ~320 cal / ~500g = 64 cal/100g
-- Source: bubbleteaworld.org (CoCo milk tea ~300-360 cal), thebobaclub.com
('coco_milk_tea', 'CoCo Fresh Tea CoCo Milk Tea', 64, 0.7, 13.0, 1.2,
 0.0, 9.0, 500, NULL,
 'coco_fresh_tea', ARRAY['coco milk tea', 'CoCo classic milk tea', 'coco fresh milk tea', 'coco bubble tea'],
 'bubble_tea', 'CoCo Fresh Tea', 1, '64 cal/100g. Medium ~500g = ~320 cal. CoCo signature milk tea with choice of toppings.', TRUE),

-- CoCo Taro Milk Tea: ~350 cal / ~500g = 70 cal/100g
-- Source: bubbleteaworld.org, cocobubbletea.com
('coco_taro_milk_tea', 'CoCo Fresh Tea Taro Milk Tea', 70, 0.5, 14.5, 1.3,
 0.2, 10.0, 500, NULL,
 'coco_fresh_tea', ARRAY['coco taro', 'CoCo taro tea', 'coco taro boba'],
 'bubble_tea', 'CoCo Fresh Tea', 1, '70 cal/100g. Medium ~500g = ~350 cal. Taro with creamer and sago. Caffeine-free.', TRUE),

-- CoCo Mango Yakult: ~175 cal / ~450g = 39 cal/100g
-- Source: cocobubbletea.com (175-378 cal range, base is 175 cal)
('coco_mango_yakult', 'CoCo Fresh Tea Mango Yakult', 39, 0.3, 9.5, 0.1,
 0.2, 8.0, 450, NULL,
 'coco_fresh_tea', ARRAY['coco mango yakult', 'CoCo yakult mango', 'mango yakult bubble tea'],
 'bubble_tea', 'CoCo Fresh Tea', 1, '39 cal/100g. Serving ~450g = ~175 cal. Mango chunks with probiotic Yakult. Caffeine-free, lighter option.', TRUE),

-- CoCo 3 Guys Milk Tea: ~340 cal / ~500g = 68 cal/100g
-- Source: bubbleteaworld.org (similar to classic milk tea, with 3 toppings: pearls, pudding, coconut jelly)
('coco_3_guys_milk_tea', 'CoCo Fresh Tea 3 Guys Milk Tea', 68, 0.8, 14.0, 1.3,
 0.1, 9.5, 500, NULL,
 'coco_fresh_tea', ARRAY['coco 3 guys', 'CoCo three guys milk tea', '3 guys milk tea'],
 'bubble_tea', 'CoCo Fresh Tea', 1, '68 cal/100g. Medium ~500g = ~340 cal. Milk tea with 3 toppings: pearls, pudding, coconut jelly.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- SHARETEA
-- ══════════════════════════════════════════════════════════════════

-- ShareTea Classic Pearl Milk Tea: 660 cal per serving / ~520g = 127 cal/100g
-- Source: eatthismuch.com, nutritionix, 1992sharetea.com
('sharetea_classic_pearl_milk_tea', 'ShareTea Classic Pearl Milk Tea', 127, 1.2, 23.5, 3.5,
 0.2, 16.5, 520, NULL,
 'sharetea', ARRAY['sharetea classic milk tea', 'sharetea pearl milk tea', 'sharetea PMT', 'sharetea classic boba'],
 'bubble_tea', 'ShareTea', 1, '127 cal/100g. Serving ~520g = ~660 cal. Includes pearls. 100% sugar. Very rich.', TRUE),

-- ShareTea Taro Pearl Milk Tea: 720 cal per serving / ~520g = 138 cal/100g
-- Source: eatthismuch.com, mynetdiary.com
('sharetea_taro_pearl_milk_tea', 'ShareTea Taro Pearl Milk Tea', 138, 1.0, 25.0, 4.0,
 0.3, 17.0, 520, NULL,
 'sharetea', ARRAY['sharetea taro', 'sharetea taro milk tea', 'sharetea taro boba'],
 'bubble_tea', 'ShareTea', 1, '138 cal/100g. Serving ~520g = ~720 cal. Taro with pearls. 100% sugar. Highest calorie option.', TRUE),

-- ShareTea Mango Ice Blended: 570 cal per serving / ~520g = 110 cal/100g
-- Source: eatthismuch.com, nutritionix (573 cal, 123g carbs)
('sharetea_mango_ice_blended', 'ShareTea Mango Ice Blended', 110, 0.3, 23.5, 0.2,
 0.2, 20.0, 520, NULL,
 'sharetea', ARRAY['sharetea mango blended', 'sharetea mango ice', 'sharetea mango smoothie'],
 'bubble_tea', 'ShareTea', 1, '110 cal/100g. Serving ~520g = ~570 cal. Mango ice blended with ice cream. Very sweet.', TRUE),

-- ShareTea Brown Sugar Pearl Latte: ~600 cal / ~520g = 115 cal/100g
-- Source: thebobaclub.com (brown sugar + pearl latte in high-cal category), 1992sharetea.com
('sharetea_brown_sugar_pearl_latte', 'ShareTea Brown Sugar Pearl Latte', 115, 1.5, 20.0, 3.5,
 0.1, 16.0, 520, NULL,
 'sharetea', ARRAY['sharetea brown sugar latte', 'sharetea BSP latte', 'sharetea brown sugar boba latte'],
 'bubble_tea', 'ShareTea', 1, '115 cal/100g. Serving ~520g = ~600 cal. Brown sugar syrup with latte and tapioca pearls.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- BOBA GUYS
-- ══════════════════════════════════════════════════════════════════

-- Boba Guys Classic Milk Tea (16oz): ~160 cal / ~480g = 33 cal/100g
-- Source: bobaguys.com blog (under 175 cal at 50% sweet), myfitnesspal
-- Boba Guys uses real tea + organic milk, lower calorie than most chains
('bobaguys_classic_milk_tea', 'Boba Guys Classic Milk Tea', 33, 0.8, 6.0, 0.6,
 0.0, 4.5, 480, NULL,
 'boba_guys', ARRAY['boba guys milk tea', 'boba guys classic', 'BG classic milk tea'],
 'bubble_tea', 'Boba Guys', 1, '33 cal/100g. 16oz ~480g = ~160 cal. Real brewed tea, organic milk. Toppings not included. 50% sweet.', TRUE),

-- Boba Guys Matcha Latte (16oz): 210 cal / ~480g = 44 cal/100g
-- Source: mynetdiary.com (210 cal 16oz, 7g fat, 28g carbs, 26g sugar)
('bobaguys_matcha_latte', 'Boba Guys Matcha Latte', 44, 1.0, 5.8, 1.5,
 0.2, 5.4, 480, NULL,
 'boba_guys', ARRAY['boba guys matcha', 'BG matcha latte', 'boba guys green tea latte'],
 'bubble_tea', 'Boba Guys', 1, '44 cal/100g. 16oz ~480g = ~210 cal. Ceremonial grade matcha with milk. Toppings extra.', TRUE),

-- Boba Guys Strawberry Matcha (16oz): 210 cal / ~480g = 44 cal/100g
-- Source: mynetdiary.com (210 cal 16oz iced, 7g fat, 28g carbs, 26g sugar)
('bobaguys_strawberry_matcha', 'Boba Guys Strawberry Matcha', 44, 0.8, 6.0, 1.5,
 0.2, 5.5, 480, NULL,
 'boba_guys', ARRAY['boba guys strawberry matcha latte', 'BG strawberry matcha', 'strawberry matcha boba guys'],
 'bubble_tea', 'Boba Guys', 1, '44 cal/100g. 16oz ~480g = ~210 cal. Matcha with strawberry puree and milk. Layered, photogenic.', TRUE),

-- Boba Guys Jasmine Milk Tea (16oz): ~250 cal / ~480g = 52 cal/100g
-- Source: mynetdiary.com (250 cal), itsbobatime jasmine milk tea
('bobaguys_jasmine_milk_tea', 'Boba Guys Jasmine Milk Tea', 52, 0.8, 10.5, 0.8,
 0.0, 7.5, 480, NULL,
 'boba_guys', ARRAY['boba guys jasmine tea', 'BG jasmine milk tea', 'jasmine boba guys'],
 'bubble_tea', 'Boba Guys', 1, '52 cal/100g. 16oz ~480g = ~250 cal. Jasmine green tea with milk. Floral and fragrant.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- THE ALLEY
-- ══════════════════════════════════════════════════════════════════

-- The Alley Brown Sugar Deerioca Milk: ~350 cal / ~480g = 73 cal/100g
-- Source: scribd nutritional info doc, mybobadiary, fitia (266 cal/100g for concentrate;
-- as served diluted ~73 cal/100g). Brown sugar milk with deerioca tapioca.
('the_alley_brown_sugar_deerioca_milk', 'The Alley Brown Sugar Deerioca Milk', 73, 1.0, 13.0, 1.8,
 0.0, 10.5, 480, NULL,
 'the_alley', ARRAY['the alley deerioca', 'the alley brown sugar', 'alley BSM', 'deerioca fresh milk', 'the alley signature'],
 'bubble_tea', 'The Alley', 1, '73 cal/100g. Regular ~480g = ~350 cal. Signature hand-made deerioca pearls in brown sugar with fresh milk.', TRUE),

-- The Alley Royal No.9 Milk Tea: ~320 cal / ~500g = 64 cal/100g
-- Source: scribd nutritional doc, foodgressing.com (rich and creamy, traditional milk tea)
-- Royal No.9 is their house-blend black tea
('the_alley_royal_no9', 'The Alley Royal No.9 Milk Tea', 64, 0.7, 13.0, 1.2,
 0.0, 9.0, 500, NULL,
 'the_alley', ARRAY['the alley royal 9', 'the alley royal no 9', 'alley royal no.9', 'royal no 9 milk tea'],
 'bubble_tea', 'The Alley', 1, '64 cal/100g. Medium ~500g = ~320 cal. House-blend Royal No.9 black tea with milk. Rich and smooth.', TRUE),

-- The Alley Aurora (layered fruit tea): ~220 cal / ~500g = 44 cal/100g
-- Source: foodgressing.com (layered fruit tea, lighter than milk teas), general fruit tea calorie data
('the_alley_aurora', 'The Alley Aurora', 44, 0.2, 10.5, 0.1,
 0.1, 9.0, 500, NULL,
 'the_alley', ARRAY['the alley aurora tea', 'alley aurora', 'aurora layered tea', 'the alley layered tea'],
 'bubble_tea', 'The Alley', 1, '44 cal/100g. Medium ~500g = ~220 cal. Layered fruit tea with color gradient. No milk, lighter option.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- ADDITIONAL GENERIC BUBBLE TEA
-- ══════════════════════════════════════════════════════════════════

-- Jasmine Milk Tea with Boba: ~55 cal/100g. Serving 500g = ~275 cal.
-- Sources: nutritionix (jasmine milk bubble tea), mynetdiary
('jasmine_milk_tea_with_boba', 'Jasmine Milk Tea with Boba', 55, 0.7, 11.0, 1.0,
 0.0, 7.5, 500, NULL,
 'generic_bubble_tea', ARRAY['jasmine boba', 'jasmine bubble tea', 'jasmine green milk tea boba'],
 'bubble_tea', NULL, 1, '55 cal/100g. Medium 500g = ~275 cal. Jasmine green tea with milk and tapioca pearls. Floral aroma.', TRUE),

-- Oolong Milk Tea with Boba: ~52 cal/100g. Serving 500g = ~260 cal.
-- Sources: eatthismuch, thebobaclub (oolong milk tea range 200-300 cal)
('oolong_milk_tea_with_boba', 'Oolong Milk Tea with Boba', 52, 0.6, 10.5, 0.8,
 0.0, 7.0, 500, NULL,
 'generic_bubble_tea', ARRAY['oolong boba', 'oolong bubble tea', 'roasted oolong milk tea boba'],
 'bubble_tea', NULL, 1, '52 cal/100g. Medium 500g = ~260 cal. Roasted oolong tea with milk and tapioca pearls. Toasty and smooth.', TRUE),

-- Wintermelon Milk Tea with Boba: ~62 cal/100g. Serving 500g = ~310 cal.
-- Sources: nutritionix, myfitnesspal (wintermelon milk tea 280-340 cal range)
('wintermelon_milk_tea_with_boba', 'Wintermelon Milk Tea with Boba', 62, 0.5, 13.0, 1.0,
 0.0, 10.0, 500, NULL,
 'generic_bubble_tea', ARRAY['wintermelon boba', 'winter melon milk tea', 'wintermelon bubble tea'],
 'bubble_tea', NULL, 1, '62 cal/100g. Medium 500g = ~310 cal. Wintermelon syrup with milk tea and tapioca pearls. Mildly sweet.', TRUE),

-- Honeydew Milk Tea with Boba: ~65 cal/100g. Serving 500g = ~325 cal.
-- Sources: myfitnesspal, nutritionix
('honeydew_milk_tea_with_boba', 'Honeydew Milk Tea with Boba', 65, 0.4, 14.0, 1.0,
 0.1, 11.0, 500, NULL,
 'generic_bubble_tea', ARRAY['honeydew boba', 'honeydew bubble tea', 'honeydew melon milk tea'],
 'bubble_tea', NULL, 1, '65 cal/100g. Medium 500g = ~325 cal. Honeydew melon flavored milk tea with tapioca pearls.', TRUE),

-- Lychee Green Tea (no milk): ~40 cal/100g. Serving 500g = ~200 cal.
-- Sources: bobalicious (lychee fruit tea ~220 cal), sharetea fruit tea data
('lychee_green_tea', 'Lychee Green Tea', 40, 0.1, 10.0, 0.0,
 0.1, 8.5, 500, NULL,
 'generic_bubble_tea', ARRAY['lychee tea', 'lychee fruit tea', 'lychee bubble tea', 'lychee iced tea'],
 'bubble_tea', NULL, 1, '40 cal/100g. Medium 500g = ~200 cal. Green tea with lychee syrup. No milk, refreshing.', TRUE),

-- Peach Oolong Tea (no milk): ~35 cal/100g. Serving 500g = ~175 cal.
-- Sources: nutritionix, bobalicious (fruit oolong teas 150-220 cal)
('peach_oolong_tea', 'Peach Oolong Tea', 35, 0.1, 8.5, 0.0,
 0.1, 7.5, 500, NULL,
 'generic_bubble_tea', ARRAY['peach tea', 'peach oolong', 'peach bubble tea', 'peach fruit tea'],
 'bubble_tea', NULL, 1, '35 cal/100g. Medium 500g = ~175 cal. Oolong tea with peach flavor. No milk, low calorie option.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- ADDITIONAL CHAIN-SPECIFIC
-- ══════════════════════════════════════════════════════════════════

-- Tiger Sugar Brown Sugar Boba Milk with Cream Mousse (regular): ~334 cal / ~480g = 70 cal/100g
-- Source: thebobaclub.com (334 cal, 54g sugar with cream mousse)
('tiger_sugar_cream_mousse', 'Tiger Sugar Brown Sugar Boba Milk with Cream Mousse', 70, 1.9, 10.6, 2.3,
 0.0, 9.6, 480, NULL,
 'tiger_sugar', ARRAY['tiger sugar cream mousse', 'tiger sugar mousse', 'cream mousse brown sugar boba'],
 'bubble_tea', 'Tiger Sugar', 1, '70 cal/100g. Regular ~480g = ~334 cal. Brown sugar boba milk topped with cream mousse. Extra creamy.', TRUE),

-- Gong Cha Milk Green Tea (Medium, 0% sugar): 370 cal / ~520g = 71 cal/100g
-- Source: eatthismuch.com (370 cal for medium, 0% sugar - high base cal from creamer)
('gongcha_milk_green_tea', 'Gong Cha Milk Green Tea', 71, 0.5, 14.0, 1.5,
 0.0, 9.0, 520, NULL,
 'gong_cha', ARRAY['gong cha green milk tea', 'gongcha green tea', 'gong cha green tea latte'],
 'bubble_tea', 'Gong Cha', 1, '71 cal/100g. Medium ~520g = ~370 cal. Fresh green tea with milk. Default sugar.', TRUE),

-- CoCo Passion Fruit Green Tea with Pearls: ~200 cal / ~500g = 40 cal/100g
-- Source: cocobubbletea.com (fruit tea ~150 cal base + pearls ~50 cal), thebobaclub.com
('coco_passion_fruit_green_tea', 'CoCo Fresh Tea Passion Fruit Green Tea', 40, 0.2, 10.0, 0.0,
 0.1, 8.5, 500, NULL,
 'coco_fresh_tea', ARRAY['coco passion fruit', 'CoCo passionfruit tea', 'coco PFGT'],
 'bubble_tea', 'CoCo Fresh Tea', 1, '40 cal/100g. Medium ~500g = ~200 cal. Passion fruit with green tea, pearls, coconut jelly. Refreshing.', TRUE),

-- ShareTea Fresh Milk Tea (Green Oolong): 280 cal / ~520g = 54 cal/100g
-- Source: mynetdiary.com (280 cal, 54g carbs)
('sharetea_fresh_milk_tea_oolong', 'ShareTea Fresh Milk Tea (Green Oolong)', 54, 1.0, 10.4, 0.6,
 0.0, 7.0, 520, NULL,
 'sharetea', ARRAY['sharetea green oolong', 'sharetea fresh milk tea', 'sharetea oolong milk tea'],
 'bubble_tea', 'ShareTea', 1, '54 cal/100g. Serving ~520g = ~280 cal. Fresh brewed oolong with real milk. Lighter ShareTea option.', TRUE),

-- The Alley Cocoa Brown Sugar Deerioca: ~380 cal / ~480g = 79 cal/100g
-- Source: foodgressing.com (chocolate variant of signature, slightly higher cal), scribd doc
('the_alley_cocoa_deerioca', 'The Alley Cocoa Brown Sugar Deerioca Milk', 79, 1.2, 14.0, 2.2,
 0.3, 11.0, 480, NULL,
 'the_alley', ARRAY['the alley cocoa deerioca', 'alley chocolate deerioca', 'cocoa brown sugar deerioca'],
 'bubble_tea', 'The Alley', 1, '79 cal/100g. Regular ~480g = ~380 cal. Cocoa-infused brown sugar deerioca with fresh milk. Rich and chocolatey.', TRUE),

-- Kung Fu Tea Peach Oolong Tea (fruit tea, no milk): ~85 cal / ~500g = 17 cal/100g
-- Source: thebobaclub.com (fruit oolong teas 65-105 cal range)
('kungfu_tea_peach_oolong', 'Kung Fu Tea Peach Oolong Tea', 17, 0.1, 4.0, 0.0,
 0.0, 3.5, 500, NULL,
 'kung_fu_tea', ARRAY['KFT peach oolong', 'kung fu peach tea', 'KFT peach oolong tea'],
 'bubble_tea', 'Kung Fu Tea', 1, '17 cal/100g. Medium ~500g = ~85 cal. Light fruit oolong tea. No milk, very low calorie.', TRUE)

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
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
