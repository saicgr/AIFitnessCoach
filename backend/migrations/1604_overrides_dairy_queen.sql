-- 1604_overrides_dairy_queen.sql
-- Dairy Queen (~4,100 locations) — Blizzards, burgers, chicken, hot dogs,
-- ice cream treats, sides, shakes.
-- Sources: Nutritionix (licensed DQ data), DQ official site, HealthyFastFood.org.
-- All values per 100g. Serving sizes are estimated from comparable fast food items.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- DAIRY QUEEN — BLIZZARD TREATS (MEDIUM)
-- ══════════════════════════════════════════

-- DQ Oreo Cookie Blizzard (Medium): 820 cal per serving (397g)
('dq_oreo_cookie_blizzard', 'DQ Oreo Cookie Blizzard (Medium)', 206.5, 4.3, 30.5, 7.6,
 0.3, 23.7, 397, NULL,
 'research', ARRAY['dq oreo blizzard', 'dairy queen oreo blizzard', 'oreo cookie blizzard medium', 'dq oreo cookie blizzard medium'],
 'ice_cream', 'Dairy Queen', 1, '820 cal per medium (397g). Oreo cookie pieces blended with DQ vanilla soft serve.', TRUE),

-- DQ Chocolate Chip Cookie Dough Blizzard (Medium): 1030 cal per serving (411g)
('dq_chocolate_chip_cookie_dough_blizzard', 'DQ Chocolate Chip Cookie Dough Blizzard (Medium)', 250.6, 4.4, 36.7, 9.7,
 0.5, 27.5, 411, NULL,
 'research', ARRAY['dq cookie dough blizzard', 'dairy queen cookie dough blizzard', 'chocolate chip cookie dough blizzard medium', 'dq chocolate chip cookie dough blizzard'],
 'ice_cream', 'Dairy Queen', 1, '1030 cal per medium (411g). Chocolate chip cookie dough pieces blended with DQ vanilla soft serve.', TRUE),

-- DQ Reese''s Peanut Butter Cup Blizzard (Medium): 820 cal per serving (397g)
('dq_reeses_peanut_butter_cup_blizzard', 'DQ Reese''s Peanut Butter Cup Blizzard (Medium)', 206.5, 5.3, 28.5, 8.6,
 0.5, 24.4, 397, NULL,
 'research', ARRAY['dq reeses blizzard', 'dairy queen reeses blizzard', 'reeses peanut butter cup blizzard medium', 'dq reeses pb cup blizzard'],
 'ice_cream', 'Dairy Queen', 1, '820 cal per medium (397g). Reese''s Peanut Butter Cup pieces blended with DQ vanilla soft serve.', TRUE),

-- DQ Butterfinger Blizzard (Medium): 800 cal per serving (397g)
('dq_butterfinger_blizzard', 'DQ Butterfinger Blizzard (Medium)', 201.5, 5.0, 29.7, 7.1,
 0.5, 22.9, 397, NULL,
 'research', ARRAY['dq butterfinger blizzard', 'dairy queen butterfinger blizzard', 'butterfinger blizzard medium', 'dq butterfinger blizzard medium'],
 'ice_cream', 'Dairy Queen', 1, '800 cal per medium (397g). Butterfinger candy pieces blended with DQ vanilla soft serve.', TRUE),

-- DQ M&M''s Chocolate Candy Blizzard (Medium): 880 cal per serving (397g)
('dq_mms_blizzard', 'DQ M&M''s Chocolate Candy Blizzard (Medium)', 221.7, 4.5, 34.0, 7.3,
 0.5, 29.5, 397, NULL,
 'research', ARRAY['dq m&m blizzard', 'dairy queen m&m blizzard', 'mms blizzard medium', 'dq mms chocolate candy blizzard'],
 'ice_cream', 'Dairy Queen', 1, '880 cal per medium (397g). M&M''s chocolate candies blended with DQ vanilla soft serve.', TRUE),

-- ══════════════════════════════════════════
-- DAIRY QUEEN — BURGERS
-- ══════════════════════════════════════════

-- DQ 1/2 lb FlameThrower GrillBurger: 980 cal per serving (310g)
('dq_flamethrower_grillburger', 'DQ 1/2 lb FlameThrower GrillBurger', 316.1, 15.8, 12.9, 22.6,
 0.6, 2.3, 310, NULL,
 'research', ARRAY['dq flamethrower', 'dairy queen flamethrower grillburger', 'dq flamethrower burger', 'dq half pound flamethrower'],
 'burger', 'Dairy Queen', 1, '980 cal per burger (310g). 1/2 lb beef with FlameThrower sauce, pepper jack cheese, jalapenos.', TRUE),

-- DQ Bacon Two Cheese Deluxe (Double): 720 cal per serving (265g)
('dq_bacon_two_cheese_deluxe', 'DQ Bacon Two Cheese Deluxe (Double)', 271.7, 14.0, 14.7, 17.7,
 0.8, 3.4, 265, NULL,
 'research', ARRAY['dq bacon two cheese deluxe', 'dairy queen bacon cheese deluxe', 'dq double bacon cheese burger', 'dq bacon two cheese deluxe double'],
 'burger', 'Dairy Queen', 1, '720 cal per burger (265g). Double patty with bacon, American and Swiss cheese, lettuce, tomato.', TRUE),

-- DQ Classic Burger (1/3 lb): 490 cal per serving (198g)
('dq_classic_burger', 'DQ Classic Burger (1/3 lb)', 247.5, 13.1, 20.2, 12.1,
 1.0, 4.5, 198, NULL,
 'research', ARRAY['dq classic burger', 'dairy queen classic burger', 'dq burger 1/3 lb', 'dq classic grillburger'],
 'burger', 'Dairy Queen', 1, '490 cal per burger (198g). 1/3 lb beef patty with ketchup, mustard, pickles on a sesame seed bun.', TRUE),

-- ══════════════════════════════════════════
-- DAIRY QUEEN — CHICKEN
-- ══════════════════════════════════════════

-- DQ Chicken Strip Basket (4 pc): 1020 cal per serving (397g)
('dq_chicken_strip_basket', 'DQ Chicken Strip Basket (4 pc)', 256.9, 8.8, 28.0, 12.1,
 1.5, 0.8, 397, NULL,
 'research', ARRAY['dq chicken strip basket', 'dairy queen chicken strips', 'dq chicken strips 4 piece', 'dq chicken basket'],
 'chicken', 'Dairy Queen', 1, '1020 cal per basket (397g). 4 breaded chicken strips with fries, gravy, toast.', TRUE),

-- DQ Crispy Chicken Sandwich: 550 cal per serving (205g)
('dq_crispy_chicken_sandwich', 'DQ Crispy Chicken Sandwich', 268.3, 12.2, 23.9, 13.7,
 1.5, 2.4, 205, NULL,
 'research', ARRAY['dq crispy chicken sandwich', 'dairy queen chicken sandwich', 'dq chicken sandwich crispy', 'dq crispy chicken'],
 'chicken', 'Dairy Queen', 1, '550 cal per sandwich (205g). Breaded crispy chicken fillet with lettuce and mayo on a bun.', TRUE),

-- ══════════════════════════════════════════
-- DAIRY QUEEN — HOT DOGS
-- ══════════════════════════════════════════

-- DQ Regular Hot Dog: 330 cal per serving (99g)
('dq_regular_hot_dog', 'DQ Regular Hot Dog', 333.3, 12.1, 25.3, 19.2,
 1.0, 3.0, 99, NULL,
 'research', ARRAY['dq hot dog', 'dairy queen hot dog', 'dq regular hot dog', 'dairy queen regular hot dog'],
 'hot_dog', 'Dairy Queen', 1, '330 cal per hot dog (99g). All-beef hot dog on a bun with ketchup and mustard.', TRUE),

-- DQ Chili Cheese Dog: 420 cal per serving (142g)
('dq_chili_cheese_dog', 'DQ Chili Cheese Dog', 295.8, 12.7, 19.7, 18.3,
 0.7, 2.8, 142, NULL,
 'research', ARRAY['dq chili cheese dog', 'dairy queen chili cheese dog', 'dq chili dog', 'dairy queen chili cheese hot dog'],
 'hot_dog', 'Dairy Queen', 1, '420 cal per chili cheese dog (142g). Hot dog topped with chili and melted cheese.', TRUE),

-- ══════════════════════════════════════════
-- DAIRY QUEEN — ICE CREAM TREATS
-- ══════════════════════════════════════════

-- DQ Dipped Cone Chocolate (Medium): 460 cal per serving (234g)
('dq_dipped_cone_chocolate', 'DQ Dipped Cone, Chocolate (Medium)', 196.6, 3.8, 24.8, 9.4,
 0.4, 18.4, 234, NULL,
 'research', ARRAY['dq dipped cone', 'dairy queen dipped cone chocolate', 'dq chocolate dipped cone medium', 'dq dipped cone medium'],
 'ice_cream', 'Dairy Queen', 1, '460 cal per medium (234g). DQ vanilla soft serve dipped in chocolate coating on a cone.', TRUE),

-- DQ Chocolate Sundae (Medium): 400 cal per serving (241g)
('dq_chocolate_sundae', 'DQ Chocolate Sundae (Medium)', 166.0, 3.3, 29.0, 4.1,
 0.4, 24.9, 241, NULL,
 'research', ARRAY['dq chocolate sundae', 'dairy queen chocolate sundae', 'dq sundae medium', 'dq hot fudge sundae medium'],
 'ice_cream', 'Dairy Queen', 1, '400 cal per medium (241g). DQ vanilla soft serve topped with chocolate syrup.', TRUE),

-- DQ Banana Split: 520 cal per serving (369g)
('dq_banana_split', 'DQ Banana Split', 140.9, 2.4, 25.5, 3.8,
 1.1, 20.1, 369, NULL,
 'research', ARRAY['dq banana split', 'dairy queen banana split', 'dq banana split sundae', 'dairy queen banana split treat'],
 'ice_cream', 'Dairy Queen', 1, '520 cal per serving (369g). Banana with DQ soft serve, chocolate, strawberry, and pineapple toppings.', TRUE),

-- ══════════════════════════════════════════
-- DAIRY QUEEN — SIDES
-- ══════════════════════════════════════════

-- DQ Onion Rings (Regular): 290 cal per serving (113g)
('dq_onion_rings', 'DQ Onion Rings (Regular)', 256.6, 4.4, 34.5, 11.5,
 1.8, 2.7, 113, NULL,
 'research', ARRAY['dq onion rings', 'dairy queen onion rings', 'dq onion rings regular', 'dairy queen onion rings regular'],
 'side', 'Dairy Queen', 1, '290 cal per regular order (113g). Crispy breaded onion rings.', TRUE),

-- DQ French Fries (Medium): 380 cal per serving (142g)
('dq_french_fries', 'DQ French Fries (Medium)', 267.6, 3.5, 35.2, 12.0,
 2.8, 0.0, 142, NULL,
 'research', ARRAY['dq french fries', 'dairy queen fries', 'dq fries medium', 'dairy queen french fries medium'],
 'side', 'Dairy Queen', 1, '380 cal per medium order (142g). Classic golden french fries.', TRUE),

-- ══════════════════════════════════════════
-- DAIRY QUEEN — SHAKES (MEDIUM)
-- ══════════════════════════════════════════

-- DQ Chocolate Shake (Medium): 710 cal per serving (532g)
('dq_chocolate_shake', 'DQ Chocolate Shake (Medium)', 133.5, 3.0, 20.7, 4.3,
 0.2, 18.0, 532, NULL,
 'research', ARRAY['dq chocolate shake', 'dairy queen chocolate shake', 'dq chocolate milkshake medium', 'dairy queen chocolate shake medium'],
 'shake', 'Dairy Queen', 1, '710 cal per medium (532g). Creamy chocolate shake made with DQ soft serve.', TRUE),

-- DQ Vanilla Shake (Medium): 660 cal per serving (503g)
('dq_vanilla_shake', 'DQ Vanilla Shake (Medium)', 131.2, 3.2, 19.3, 4.6,
 0.0, 16.9, 503, NULL,
 'research', ARRAY['dq vanilla shake', 'dairy queen vanilla shake', 'dq vanilla milkshake medium', 'dairy queen vanilla shake medium'],
 'shake', 'Dairy Queen', 1, '660 cal per medium (503g). Creamy vanilla shake made with DQ soft serve.', TRUE)

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
