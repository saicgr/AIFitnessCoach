-- 1641_overrides_playa_scooters_carlsjr.sql
-- Playa Bowls (~200+ locations) — acai bowls, pitaya bowls, smoothies.
-- Scooter's Coffee (~700+ locations) — blended drinks, smoothies, baked goods.
-- Carl's Jr (~1,000+ locations) — burgers, chicken, sides, breakfast.
-- Sources: official nutrition pages, FatSecret, Nutritionix, fastfoodnutrition.org.
-- All values per 100g. Restaurant serving weights are estimated.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- PLAYA BOWLS — ACAI BOWLS
-- ══════════════════════════════════════════

-- Playa Bowls OG Playa Bowl: ~520 cal per bowl (400g)
('playa_og_playa_bowl', 'Playa Bowls OG Playa Bowl', 130.0, 3.0, 22.0, 4.0,
 3.5, 14.0, 400, NULL,
 'website', ARRAY['playa bowls og bowl', 'og playa bowl', 'playa bowls original bowl', 'playa og acai bowl'],
 'bowl', 'Playa Bowls', 1, '520 cal per bowl (400g). Acai base topped with granola, banana, blueberries, and honey.', TRUE),

-- Playa Bowls Nutella Bowl: ~730 cal per bowl (420g) — verified via FatSecret
('playa_nutella_bowl', 'Playa Bowls Nutella Bowl', 173.8, 3.5, 24.0, 7.5,
 3.0, 18.0, 420, NULL,
 'website', ARRAY['playa bowls nutella bowl', 'playa nutella acai bowl', 'nutella playa bowl', 'playa bowls nutella'],
 'bowl', 'Playa Bowls', 1, '730 cal per bowl (420g). Acai base with Nutella drizzle, banana, strawberry, and granola. High sugar.', TRUE),

-- Playa Bowls PB Crunch Bowl: ~580 cal per bowl (400g)
('playa_pb_crunch_bowl', 'Playa Bowls PB Crunch Bowl', 145.0, 5.0, 20.0, 5.5,
 3.0, 13.0, 400, NULL,
 'website', ARRAY['playa bowls pb crunch bowl', 'playa peanut butter crunch bowl', 'pb crunch playa bowl', 'playa bowls peanut butter bowl'],
 'bowl', 'Playa Bowls', 1, '580 cal per bowl (400g). Acai base with peanut butter, granola, banana, and honey.', TRUE),

-- Playa Bowls Green Bowl: ~418 cal per bowl (380g)
('playa_green_bowl', 'Playa Bowls Green Bowl', 110.0, 3.5, 18.0, 3.0,
 4.0, 10.0, 380, NULL,
 'website', ARRAY['playa bowls green bowl', 'playa green smoothie bowl', 'green playa bowl', 'playa bowls kale spinach bowl'],
 'bowl', 'Playa Bowls', 1, '418 cal per bowl (380g). Green base (kale, spinach, mango) topped with granola, banana, and coconut flakes. Lower calorie option.', TRUE),

-- Playa Bowls Mango Bowl: ~480 cal per bowl (400g)
('playa_mango_bowl', 'Playa Bowls Mango Bowl', 120.0, 2.5, 22.0, 2.5,
 2.5, 16.0, 400, NULL,
 'website', ARRAY['playa bowls mango bowl', 'playa mango acai bowl', 'mango playa bowl', 'playa bowls tropical mango bowl'],
 'bowl', 'Playa Bowls', 1, '480 cal per bowl (400g). Acai and mango base with granola, strawberry, and coconut.', TRUE),

-- ══════════════════════════════════════════
-- PLAYA BOWLS — PITAYA BOWLS
-- ══════════════════════════════════════════

-- Playa Bowls Dragon Fruit Bowl: ~460 cal per bowl (400g)
('playa_dragon_fruit_bowl', 'Playa Bowls Dragon Fruit Bowl', 115.0, 2.0, 21.0, 2.5,
 3.0, 14.0, 400, NULL,
 'website', ARRAY['playa bowls dragon fruit bowl', 'playa pitaya bowl', 'playa bowls pitaya bowl', 'dragon fruit playa bowl'],
 'bowl', 'Playa Bowls', 1, '460 cal per bowl (400g). Pitaya (dragon fruit) base with granola, banana, blueberries, and coconut. Slightly lower calorie than acai base.', TRUE),

-- Playa Bowls Tropical Bowl: ~500 cal per bowl (400g)
('playa_tropical_bowl', 'Playa Bowls Tropical Bowl', 125.0, 2.5, 22.5, 3.0,
 2.5, 15.0, 400, NULL,
 'website', ARRAY['playa bowls tropical bowl', 'playa tropical pitaya bowl', 'tropical playa bowl', 'playa bowls tropical fruit bowl'],
 'bowl', 'Playa Bowls', 1, '500 cal per bowl (400g). Pitaya base with mango, pineapple, granola, and honey.', TRUE),

-- ══════════════════════════════════════════
-- PLAYA BOWLS — SMOOTHIES
-- ══════════════════════════════════════════

-- Playa Bowls PB Banana Smoothie: ~360 cal per 480g
('playa_pb_banana_smoothie', 'Playa Bowls PB Banana Smoothie', 75.0, 4.0, 10.5, 2.5,
 1.5, 7.0, 480, NULL,
 'website', ARRAY['playa bowls pb banana smoothie', 'playa peanut butter banana smoothie', 'pb banana playa smoothie', 'playa bowls peanut butter smoothie'],
 'smoothie', 'Playa Bowls', 1, '360 cal per smoothie (480g). Peanut butter, banana, almond milk, and protein blend.', TRUE),

-- Playa Bowls Berry Smoothie: ~288 cal per 480g
('playa_berry_smoothie', 'Playa Bowls Berry Smoothie', 60.0, 2.0, 12.0, 0.8,
 2.0, 8.0, 480, NULL,
 'website', ARRAY['playa bowls berry smoothie', 'playa mixed berry smoothie', 'berry playa smoothie', 'playa bowls berry blend smoothie'],
 'smoothie', 'Playa Bowls', 1, '288 cal per smoothie (480g). Mixed berries, banana, and apple juice.', TRUE),

-- Playa Bowls Green Machine Smoothie: ~264 cal per 480g
('playa_green_machine_smoothie', 'Playa Bowls Green Machine Smoothie', 55.0, 2.5, 10.0, 0.5,
 2.5, 6.0, 480, NULL,
 'website', ARRAY['playa bowls green machine smoothie', 'playa green smoothie', 'green machine playa smoothie', 'playa bowls kale smoothie'],
 'smoothie', 'Playa Bowls', 1, '264 cal per smoothie (480g). Kale, spinach, mango, pineapple, banana, and apple juice. Lowest calorie smoothie option.', TRUE),

-- ══════════════════════════════════════════
-- SCOOTER'S COFFEE — BLENDED DRINKS
-- ══════════════════════════════════════════

-- Scooter's Caramelicious (Medium, Blended): ~520 cal per 470g — verified via EatThisMuch
('scooters_caramelicious_medium', 'Scooter''s Coffee Caramelicious (Medium)', 110.6, 2.0, 18.5, 3.5,
 0.0, 16.0, 470, NULL,
 'website', ARRAY['scooters caramelicious', 'scooters coffee caramelicious medium', 'scooter caramelicious blended', 'scooters caramelicious medium'],
 'beverage', 'Scooter''s Coffee', 1, '520 cal per medium (470g). Caramel blended coffee drink with whipped cream. Signature item.', TRUE),

-- Scooter's Berry Infusion (Medium): ~250 cal per 470g
('scooters_berry_infusion_medium', 'Scooter''s Coffee Berry Infusion (Medium)', 53.2, 0.3, 13.0, 0.1,
 0.5, 11.0, 470, NULL,
 'website', ARRAY['scooters berry infusion', 'scooters coffee berry infusion medium', 'scooter berry smoothie', 'scooters infusion berry'],
 'beverage', 'Scooter''s Coffee', 1, '250 cal per medium (470g). Berry-flavored fruit infusion drink.', TRUE),

-- Scooter's Mango Infusion (Medium): ~260 cal per 470g
('scooters_mango_infusion_medium', 'Scooter''s Coffee Mango Infusion (Medium)', 55.3, 0.3, 13.5, 0.1,
 0.3, 12.0, 470, NULL,
 'website', ARRAY['scooters mango infusion', 'scooters coffee mango infusion medium', 'scooter mango smoothie', 'scooters infusion mango'],
 'beverage', 'Scooter''s Coffee', 1, '260 cal per medium (470g). Mango-flavored fruit infusion drink.', TRUE),

-- Scooter's Protein Smoothie PB Banana: ~350 cal per 480g
('scooters_protein_pb_banana', 'Scooter''s Coffee PB Banana Protein Smoothie', 72.9, 5.0, 10.0, 2.0,
 1.0, 6.0, 480, NULL,
 'website', ARRAY['scooters protein smoothie peanut butter banana', 'scooters pb banana smoothie', 'scooter protein pb banana', 'scooters peanut butter banana protein'],
 'smoothie', 'Scooter''s Coffee', 1, '350 cal per smoothie (480g). Peanut butter, banana, protein blend, and milk.', TRUE),

-- Scooter's Protein Smoothie Berry: ~300 cal per 480g
('scooters_protein_berry', 'Scooter''s Coffee Berry Protein Smoothie', 62.5, 4.5, 10.5, 0.8,
 1.5, 6.5, 480, NULL,
 'website', ARRAY['scooters protein smoothie berry', 'scooters berry protein smoothie', 'scooter protein berry', 'scooters mixed berry protein'],
 'smoothie', 'Scooter''s Coffee', 1, '300 cal per smoothie (480g). Mixed berries with protein blend and milk.', TRUE),

-- ══════════════════════════════════════════
-- SCOOTER'S COFFEE — FOOD ITEMS
-- ══════════════════════════════════════════

-- Scooter's Egg & Cheese Biscuit: ~350 cal per piece (140g)
('scooters_egg_cheese_biscuit', 'Scooter''s Coffee Egg & Cheese Biscuit', 250.0, 10.0, 25.0, 12.5,
 0.5, 2.0, NULL, 140,
 'website', ARRAY['scooters egg cheese biscuit', 'scooters coffee egg and cheese biscuit', 'scooter egg biscuit', 'scooters breakfast biscuit'],
 'sandwich', 'Scooter''s Coffee', 1, '350 cal per biscuit (140g). Scrambled egg and cheese on a warm biscuit.', TRUE),

-- Scooter's Breakfast Burrito: ~420 cal per piece (200g)
('scooters_breakfast_burrito', 'Scooter''s Coffee Breakfast Burrito', 210.0, 11.0, 18.0, 10.5,
 1.0, 1.5, NULL, 200,
 'website', ARRAY['scooters breakfast burrito', 'scooters coffee breakfast burrito', 'scooter burrito', 'scooters egg burrito'],
 'burrito', 'Scooter''s Coffee', 1, '420 cal per burrito (200g). Scrambled eggs, sausage, and cheese in a flour tortilla.', TRUE),

-- Scooter's Blueberry Muffin: ~400 cal per piece (120g)
('scooters_blueberry_muffin', 'Scooter''s Coffee Blueberry Muffin', 333.3, 4.5, 45.0, 15.0,
 1.0, 28.0, NULL, 120,
 'website', ARRAY['scooters blueberry muffin', 'scooters coffee blueberry muffin', 'scooter muffin blueberry', 'scooters muffin'],
 'bakery', 'Scooter''s Coffee', 1, '400 cal per muffin (120g). Blueberry muffin with sugar glaze topping.', TRUE),

-- Scooter's Cookie: ~380 cal per piece (80g)
('scooters_cookie', 'Scooter''s Coffee Cookie', 475.0, 5.0, 60.0, 24.0,
 1.0, 35.0, NULL, 80,
 'website', ARRAY['scooters cookie', 'scooters coffee cookie', 'scooter chocolate chip cookie', 'scooters bakery cookie'],
 'bakery', 'Scooter''s Coffee', 1, '380 cal per cookie (80g). Fresh-baked cookie.', TRUE),

-- ══════════════════════════════════════════
-- CARL'S JR — BURGERS
-- ══════════════════════════════════════════

-- Carl's Jr Famous Star w/ Cheese: 670 cal per 254g — verified via FatSecret/fastfoodnutrition.org
('carlsjr_famous_star', 'Carl''s Jr Famous Star w/ Cheese', 263.8, 11.0, 22.4, 14.6,
 1.2, 3.5, 254, NULL,
 'website', ARRAY['carls jr famous star', 'carls jr famous star with cheese', 'carl''s jr famous star', 'famous star burger'],
 'burger', 'Carl''s Jr', 1, '670 cal per burger (254g). Charbroiled beef patty with cheese, lettuce, tomato, onion, pickles, mayo, ketchup, mustard on a sesame seed bun.', TRUE),

-- Carl's Jr Super Star w/ Cheese: 930 cal per 345g — verified via FatSecret
('carlsjr_super_star', 'Carl''s Jr Super Star w/ Cheese', 269.6, 13.6, 17.1, 16.5,
 1.2, 3.2, 345, NULL,
 'website', ARRAY['carls jr super star', 'carls jr super star with cheese', 'carl''s jr super star', 'super star burger'],
 'burger', 'Carl''s Jr', 1, '930 cal per burger (345g). Double charbroiled beef patties with cheese, lettuce, tomato, mayo on a sesame seed bun.', TRUE),

-- Carl's Jr Western Bacon Cheeseburger: 740 cal per 254g — verified via fastfoodnutrition.org
('carlsjr_western_bacon_cheeseburger', 'Carl''s Jr Western Bacon Cheeseburger', 291.3, 13.0, 29.1, 13.4,
 1.2, 6.3, 254, NULL,
 'website', ARRAY['carls jr western bacon cheeseburger', 'carl''s jr western bacon', 'western bacon burger carls jr', 'western bacon cheeseburger'],
 'burger', 'Carl''s Jr', 1, '740 cal per burger (254g). Charbroiled beef, bacon, cheese, onion rings, and BBQ sauce on a sesame seed bun.', TRUE),

-- Carl's Jr Beyond Famous Star: 710 cal per 311g — verified via FatSecret
('carlsjr_beyond_famous_star', 'Carl''s Jr Beyond Famous Star w/ Cheese', 228.3, 9.6, 19.6, 12.9,
 2.3, 3.5, 311, NULL,
 'website', ARRAY['carls jr beyond famous star', 'carl''s jr beyond burger', 'beyond famous star', 'carls jr plant based burger'],
 'burger', 'Carl''s Jr', 1, '710 cal per burger (311g). Beyond Meat plant-based patty with cheese, lettuce, tomato, onion, pickles, and special sauce.', TRUE),

-- Carl's Jr Breakfast Burger: ~760 cal per 305g
('carlsjr_breakfast_burger', 'Carl''s Jr Breakfast Burger', 249.2, 10.8, 18.7, 14.8,
 1.0, 3.0, 305, NULL,
 'website', ARRAY['carls jr breakfast burger', 'carl''s jr breakfast burger', 'carls jr burger with egg', 'breakfast burger carls jr'],
 'burger', 'Carl''s Jr', 1, '760 cal per burger (305g). Charbroiled beef patty with egg, bacon, cheese, hash rounds, and ketchup on a sesame seed bun.', TRUE),

-- Carl's Jr Big Hamburger: ~440 cal per 195g
('carlsjr_big_hamburger', 'Carl''s Jr Big Hamburger', 225.6, 11.3, 20.5, 10.3,
 1.0, 3.6, 195, NULL,
 'website', ARRAY['carls jr big hamburger', 'carl''s jr big hamburger', 'carls jr big burger', 'big hamburger carls jr'],
 'burger', 'Carl''s Jr', 1, '440 cal per burger (195g). Charbroiled beef patty with lettuce, tomato, onion, pickles, ketchup, and mustard.', TRUE),

-- ══════════════════════════════════════════
-- CARL'S JR — CHICKEN
-- ══════════════════════════════════════════

-- Carl's Jr Charbroiled Chicken Club: 600 cal per 270g — verified via CalorieKing
('carlsjr_charbroiled_chicken_club', 'Carl''s Jr Charbroiled Chicken Club Sandwich', 222.2, 15.9, 19.6, 10.0,
 0.7, 2.2, 270, NULL,
 'website', ARRAY['carls jr charbroiled chicken club', 'carl''s jr chicken club', 'carls jr chicken club sandwich', 'charbroiled chicken club carls jr'],
 'sandwich', 'Carl''s Jr', 1, '600 cal per sandwich (270g). Charbroiled chicken breast with bacon, Swiss cheese, lettuce, tomato, and mayo on sourdough.', TRUE),

-- Carl's Jr Hand-Breaded Tenders 3pc: ~340 cal per 140g
('carlsjr_tenders_3pc', 'Carl''s Jr Hand-Breaded Chicken Tenders (3pc)', 242.9, 16.4, 14.3, 12.9,
 0.7, 0.4, 140, NULL,
 'website', ARRAY['carls jr chicken tenders 3 piece', 'carl''s jr hand breaded tenders 3pc', 'carls jr tenders 3 piece', 'carls jr chicken strips 3pc'],
 'chicken', 'Carl''s Jr', 1, '340 cal per 3 pieces (140g). Hand-breaded all-white-meat chicken tenders.', TRUE),

-- Carl's Jr Hand-Breaded Tenders 5pc: ~570 cal per 235g
('carlsjr_tenders_5pc', 'Carl''s Jr Hand-Breaded Chicken Tenders (5pc)', 242.6, 16.2, 14.5, 12.8,
 0.6, 0.4, 235, NULL,
 'website', ARRAY['carls jr chicken tenders 5 piece', 'carl''s jr hand breaded tenders 5pc', 'carls jr tenders 5 piece', 'carls jr chicken strips 5pc'],
 'chicken', 'Carl''s Jr', 1, '570 cal per 5 pieces (235g). Hand-breaded all-white-meat chicken tenders.', TRUE),

-- Carl's Jr Chicken Stars 6pc: ~260 cal per 85g
('carlsjr_chicken_stars_6pc', 'Carl''s Jr Chicken Stars (6pc)', 305.9, 14.1, 18.8, 18.8,
 0.0, 0.0, 85, NULL,
 'website', ARRAY['carls jr chicken stars 6 piece', 'carl''s jr chicken stars', 'carls jr chicken nuggets', 'chicken stars carls jr 6pc'],
 'chicken', 'Carl''s Jr', 1, '260 cal per 6 pieces (85g). Star-shaped chicken nuggets, breaded and fried.', TRUE),

-- ══════════════════════════════════════════
-- CARL'S JR — SIDES
-- ══════════════════════════════════════════

-- Carl's Jr CrissCut Fries (Medium): ~450 cal per 142g
('carlsjr_crisscut_fries_medium', 'Carl''s Jr CrissCut Fries (Medium)', 316.9, 3.5, 35.2, 18.3,
 3.5, 0.7, 142, NULL,
 'website', ARRAY['carls jr crisscut fries', 'carl''s jr crisscut fries medium', 'carls jr waffle fries', 'crisscut fries carls jr medium'],
 'side', 'Carl''s Jr', 1, '450 cal per medium (142g). Criss-cut waffle fries, seasoned and fried.', TRUE),

-- Carl's Jr Natural-Cut Fries (Medium): ~400 cal per 139g
('carlsjr_natural_cut_fries_medium', 'Carl''s Jr Natural-Cut Fries (Medium)', 287.8, 4.3, 38.8, 12.9,
 3.6, 0.4, 139, NULL,
 'website', ARRAY['carls jr natural cut fries', 'carl''s jr fries medium', 'carls jr french fries', 'natural cut fries carls jr medium'],
 'side', 'Carl''s Jr', 1, '400 cal per medium (139g). Skin-on natural-cut french fries.', TRUE)

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
