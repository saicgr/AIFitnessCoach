-- 1586_overrides_indian_and_freddys.sql
-- Adds 2 generic Indian dishes (Mutton Liver Fry, Ghee Roast Goat Pulao)
-- and 28 Freddy's Frozen Custard & Steakburgers menu items.
-- Sources: Research for Indian dishes; official Freddy's nutrition page
-- (freddys.com/nutrition-and-allergens) and fastfoodnutrition.org for Freddy's.
-- All values per 100g. default_serving_g = full item weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- GENERIC INDIAN DISHES
-- ══════════════════════════════════════════

-- Mutton Liver Fry: 167 cal/100g, 25P, 3C, 6.5F per 100g (150g serving)
('mutton_liver_fry', 'Mutton Liver Fry', 167, 25.0, 3.0, 6.5,
 0.5, 1.0, 150, NULL,
 'research', ARRAY['mutton liver fry', 'goat liver fry', 'liver fry indian', 'kaleji fry', 'mutton kaleji'],
 'indian', NULL, 1, '250 cal per 150g serving. Pan-fried goat/mutton liver with onions and spices. High protein, iron-rich.', TRUE),

-- Ghee Roast Goat Pulao: 170 cal/100g, 10P, 18C, 7F per 100g (350g serving)
('ghee_roast_goat_pulao', 'Ghee Roast Goat Pulao', 170, 10.0, 18.0, 7.0,
 0.8, 1.0, 350, NULL,
 'research', ARRAY['ghee roast goat pulao', 'ghee roast mutton pulao', 'goat pulao ghee roast', 'ghee roast goat rice'],
 'indian', NULL, 1, '595 cal per 350g serving. Fragrant basmati rice cooked with ghee-roasted goat meat and whole spices.', TRUE),

-- ══════════════════════════════════════════
-- FREDDY'S FROZEN CUSTARD & STEAKBURGERS
-- ══════════════════════════════════════════

-- ── Steakburgers ──

-- Freddy's Single Steakburger (no cheese): 380 cal, 24P, 30C, 12F (155g)
('freddys_single_steakburger', 'Freddy''s Single Steakburger', 245, 15.5, 19.4, 7.7,
 0.0, 2.6, 155, 155,
 'manufacturer', ARRAY['freddy''s single steakburger', 'freddys single burger', 'freddy''s steakburger single no cheese'],
 'burgers', 'Freddy''s', 1, '380 cal. Single thin-smashed beef patty on a toasted bun. Freddy''s original steakburger.', TRUE),

-- Freddy's Single Steakburger w/ Cheese: 460 cal, 28P, 31C, 23F (175g)
('freddys_single_steakburger_cheese', 'Freddy''s Single Steakburger w/ Cheese', 263, 16.0, 17.7, 13.1,
 0.0, 2.3, 175, 175,
 'manufacturer', ARRAY['freddy''s single steakburger cheese', 'freddys single burger cheese', 'freddy''s steakburger cheese'],
 'burgers', 'Freddy''s', 1, '460 cal. Single thin-smashed patty with American cheese on a toasted bun.', TRUE),

-- Freddy's Double Steakburger (no cheese): 570 cal, 43P, 30C, 29F (200g)
('freddys_double_steakburger', 'Freddy''s Double Steakburger', 285, 21.5, 15.0, 14.5,
 0.0, 2.5, 200, 200,
 'manufacturer', ARRAY['freddy''s double steakburger', 'freddys double burger', 'freddy''s steakburger double no cheese'],
 'burgers', 'Freddy''s', 1, '570 cal. Two thin-smashed beef patties on a toasted bun.', TRUE),

-- Freddy's Double Steakburger w/ Cheese: 730 cal, 52P, 32C, 43F (230g)
('freddys_double_steakburger_cheese', 'Freddy''s Double Steakburger w/ Cheese', 317, 22.6, 13.9, 18.7,
 0.4, 1.7, 230, 230,
 'manufacturer', ARRAY['freddy''s double steakburger cheese', 'freddys double burger cheese', 'freddy''s double with cheese'],
 'burgers', 'Freddy''s', 1, '730 cal. Two thin-smashed patties with American cheese on a toasted bun.', TRUE),

-- Freddy's Triple Steakburger (no cheese): 760 cal, 63P, 30C, 41F (250g)
('freddys_triple_steakburger', 'Freddy''s Triple Steakburger', 304, 25.2, 12.0, 16.4,
 0.0, 2.0, 250, 250,
 'manufacturer', ARRAY['freddy''s triple steakburger', 'freddys triple burger', 'freddy''s steakburger triple no cheese'],
 'burgers', 'Freddy''s', 1, '760 cal. Three thin-smashed beef patties on a toasted bun.', TRUE),

-- Freddy's Triple Steakburger w/ Cheese: 1000 cal, 76P, 32C, 62F (280g)
('freddys_triple_steakburger_cheese', 'Freddy''s Triple Steakburger w/ Cheese', 357, 27.1, 11.4, 22.1,
 0.0, 1.4, 280, 280,
 'manufacturer', ARRAY['freddy''s triple steakburger cheese', 'freddys triple burger cheese', 'freddy''s triple with cheese'],
 'burgers', 'Freddy''s', 1, '1000 cal. Three thin-smashed patties with American cheese on a toasted bun.', TRUE),

-- Freddy's Single Bacon Steakburger w/ Cheese: 520 cal, 33P, 31C, 28F (190g)
('freddys_single_bacon_steakburger_cheese', 'Freddy''s Single Bacon Steakburger w/ Cheese', 274, 17.4, 16.3, 14.7,
 0.0, 2.1, 190, 190,
 'manufacturer', ARRAY['freddy''s bacon steakburger', 'freddys bacon burger cheese', 'freddy''s single bacon cheese'],
 'burgers', 'Freddy''s', 1, '520 cal. Single thin-smashed patty with bacon and American cheese.', TRUE),

-- Freddy's Single Patty Melt: 500 cal, 30P, 37C, 25F (185g)
('freddys_patty_melt', 'Freddy''s Patty Melt', 270, 16.2, 20.0, 13.5,
 0.0, 1.6, 185, 185,
 'manufacturer', ARRAY['freddy''s patty melt', 'freddys patty melt', 'freddy''s single patty melt'],
 'burgers', 'Freddy''s', 1, '500 cal. Single steakburger patty with Swiss cheese and grilled onions on rye bread.', TRUE),

-- ── Chicken ──

-- Freddy's Grilled Chicken Club: 530 cal, 35P, 31C, 29F (260g)
('freddys_grilled_chicken_club', 'Freddy''s Grilled Chicken Club', 204, 13.5, 11.9, 11.2,
 0.4, 2.7, 260, 260,
 'manufacturer', ARRAY['freddy''s grilled chicken club', 'freddys grilled chicken sandwich', 'freddy''s chicken club grilled'],
 'chicken', 'Freddy''s', 1, '530 cal. Grilled chicken breast with bacon, lettuce, tomato, and mayo on a toasted bun.', TRUE),

-- Freddy's Crispy Chicken Club: 720 cal, 42P, 44C, 41F (280g)
('freddys_crispy_chicken_club', 'Freddy''s Crispy Chicken Club', 257, 15.0, 15.7, 14.6,
 0.7, 2.5, 280, 280,
 'manufacturer', ARRAY['freddy''s crispy chicken club', 'freddys crispy chicken sandwich', 'freddy''s chicken club crispy'],
 'chicken', 'Freddy''s', 1, '720 cal. Crispy breaded chicken breast with bacon, lettuce, tomato, and mayo.', TRUE),

-- Freddy's Chicken Tenders 3pc: 420 cal, 35P, 29C, 17F (170g)
('freddys_chicken_tenders_3pc', 'Freddy''s Chicken Tenders (3pc)', 247, 20.6, 17.1, 10.0,
 1.2, 0.0, 170, 57,
 'manufacturer', ARRAY['freddy''s chicken tenders', 'freddys chicken tenders 3', 'freddy''s tenders 3 piece'],
 'chicken', 'Freddy''s', 3, '420 cal for 3 pieces. Hand-breaded chicken tenders.', TRUE),

-- Freddy's Spicy Chicken Sandwich: 380 cal, 22P, 39C, 14F (200g)
('freddys_spicy_chicken_sandwich', 'Freddy''s Spicy Chicken Sandwich', 190, 11.0, 19.5, 7.0,
 0.5, 1.5, 200, 200,
 'manufacturer', ARRAY['freddy''s spicy chicken sandwich', 'freddys spicy chicken', 'freddy''s spicy chicken burger'],
 'chicken', 'Freddy''s', 1, '380 cal. Spicy breaded chicken fillet on a toasted bun.', TRUE),

-- ── Hot Dogs ──

-- Freddy's Hot Dog: 390 cal, 14P, 34C, 21F (130g)
('freddys_hot_dog', 'Freddy''s Hot Dog', 300, 10.8, 26.2, 16.2,
 0.0, 4.6, 130, 130,
 'manufacturer', ARRAY['freddy''s hot dog', 'freddys hot dog', 'freddy''s all beef hot dog'],
 'hot_dogs', 'Freddy''s', 1, '390 cal. All-beef hot dog on a steamed bun.', TRUE),

-- Freddy's Chicago Style Hot Dog: 430 cal, 14P, 42C, 21F (175g)
('freddys_chicago_hot_dog', 'Freddy''s Chicago Style Hot Dog', 246, 8.0, 24.0, 12.0,
 0.0, 7.4, 175, 175,
 'manufacturer', ARRAY['freddy''s chicago hot dog', 'freddys chicago dog', 'freddy''s chicago style dog'],
 'hot_dogs', 'Freddy''s', 1, '430 cal. All-beef hot dog with mustard, onion, relish, tomato, pickle, sport peppers, celery salt.', TRUE),

-- Freddy's Chili Cheese Dog: 550 cal, 29P, 43C, 34F (210g)
('freddys_chili_cheese_dog', 'Freddy''s Chili Cheese Dog', 262, 13.8, 20.5, 16.2,
 0.0, 3.8, 210, 210,
 'manufacturer', ARRAY['freddy''s chili cheese dog', 'freddys chili cheese hot dog', 'freddy''s chili dog'],
 'hot_dogs', 'Freddy''s', 1, '550 cal. All-beef hot dog topped with chili and melted cheese.', TRUE),

-- ── Veggie ──

-- Freddy's Veggie Burger: 350 cal, 21P, 46C, 7F (190g)
('freddys_veggie_burger', 'Freddy''s Veggie Burger', 184, 11.1, 24.2, 3.7,
 2.1, 4.2, 190, 190,
 'manufacturer', ARRAY['freddy''s veggie burger', 'freddys veggie burger', 'freddy''s veggie steakburger'],
 'burgers', 'Freddy''s', 1, '350 cal. Plant-based veggie patty on a toasted bun.', TRUE),

-- ── Sides ──

-- Freddy's Regular Fries: 400 cal, 7P, 48C, 21F (130g)
('freddys_fries_regular', 'Freddy''s Fries (Regular)', 308, 5.4, 36.9, 16.2,
 3.1, 0.0, 130, NULL,
 'manufacturer', ARRAY['freddy''s fries', 'freddys fries regular', 'freddy''s french fries', 'freddy''s shoestring fries'],
 'sides', 'Freddy''s', 1, '400 cal. Thin-cut shoestring fries, cooked in 100% peanut oil.', TRUE),

-- Freddy's Cheese Curds (Small): 610 cal, 29P, 22C, 45F (200g)
('freddys_cheese_curds_small', 'Freddy''s Cheese Curds (Small)', 305, 14.5, 11.0, 22.5,
 0.5, 0.5, 200, NULL,
 'manufacturer', ARRAY['freddy''s cheese curds small', 'freddys cheese curds', 'freddy''s wisconsin cheese curds small'],
 'sides', 'Freddy''s', 1, '610 cal. Beer-battered Wisconsin cheese curds, golden fried. Small order.', TRUE),

-- Freddy's Cheese Curds (Large): 1220 cal, 58P, 43C, 91F (400g)
('freddys_cheese_curds_large', 'Freddy''s Cheese Curds (Large)', 305, 14.5, 10.8, 22.8,
 0.8, 0.3, 400, NULL,
 'manufacturer', ARRAY['freddy''s cheese curds large', 'freddys large cheese curds', 'freddy''s wisconsin cheese curds large'],
 'sides', 'Freddy''s', 1, '1220 cal. Beer-battered Wisconsin cheese curds, golden fried. Large order.', TRUE),

-- Freddy's Onion Rings: 600 cal, 6P, 66C, 35F (170g)
('freddys_onion_rings', 'Freddy''s Onion Rings', 353, 3.5, 38.8, 20.6,
 0.0, 4.7, 170, NULL,
 'manufacturer', ARRAY['freddy''s onion rings', 'freddys onion rings', 'freddy''s beer battered onion rings'],
 'sides', 'Freddy''s', 1, '600 cal. Beer-battered onion rings.', TRUE),

-- Freddy's Cheese Fries (Regular): 560 cal, 7P, 66C, 30F (180g)
('freddys_cheese_fries_regular', 'Freddy''s Cheese Fries (Regular)', 311, 3.9, 36.7, 16.7,
 2.2, 0.0, 180, NULL,
 'manufacturer', ARRAY['freddy''s cheese fries', 'freddys cheese fries', 'freddy''s fries with cheese'],
 'sides', 'Freddy''s', 1, '560 cal. Shoestring fries topped with melted cheese sauce.', TRUE),

-- ── Frozen Custard & Cones ──

-- Freddy's Vanilla Cone (Regular): 690 cal, 16P, 73C, 33F (300g)
('freddys_vanilla_cone', 'Freddy''s Vanilla Cone (Regular)', 230, 5.3, 24.3, 11.0,
 0.0, 20.3, 300, 300,
 'manufacturer', ARRAY['freddy''s vanilla cone', 'freddys vanilla cone', 'freddy''s custard cone vanilla'],
 'desserts', 'Freddy''s', 1, '690 cal. Signature frozen custard in a waffle cone. Rich, creamy vanilla.', TRUE),

-- Freddy's Chocolate Cone (Regular): 690 cal, 19P, 79C, 33F (300g)
('freddys_chocolate_cone', 'Freddy''s Chocolate Cone (Regular)', 230, 6.3, 26.3, 11.0,
 1.0, 20.3, 300, 300,
 'manufacturer', ARRAY['freddy''s chocolate cone', 'freddys chocolate cone', 'freddy''s custard cone chocolate'],
 'desserts', 'Freddy''s', 1, '690 cal. Signature frozen custard in a waffle cone. Rich chocolate.', TRUE),

-- Freddy's Brownie Delight Concrete (Regular): 1140 cal, 20P, 141C, 51F (450g)
('freddys_brownie_delight_concrete', 'Freddy''s Brownie Delight Concrete (Regular)', 253, 4.4, 31.3, 11.3,
 0.0, 24.4, 450, 450,
 'manufacturer', ARRAY['freddy''s brownie delight', 'freddys brownie concrete', 'freddy''s brownie delight concrete'],
 'desserts', 'Freddy''s', 1, '1140 cal. Frozen custard blended with hot fudge brownie pieces.', TRUE),

-- Freddy's Turtle Concrete (Regular): 1140 cal, 16P, 139C, 50F (450g)
('freddys_turtle_concrete', 'Freddy''s Turtle Concrete (Regular)', 253, 3.6, 30.9, 11.1,
 0.0, 23.8, 450, 450,
 'manufacturer', ARRAY['freddy''s turtle concrete', 'freddys turtle concrete', 'freddy''s turtle sundae concrete'],
 'desserts', 'Freddy''s', 1, '1140 cal. Frozen custard blended with hot fudge, caramel, and pecans.', TRUE),

-- ── Shakes & Sundaes ──

-- Freddy's Vanilla Shake (Regular): 560 cal, 13P, 57C, 28F (400g)
('freddys_vanilla_shake', 'Freddy''s Vanilla Shake (Regular)', 140, 3.2, 14.2, 7.0,
 0.0, 11.8, 400, NULL,
 'manufacturer', ARRAY['freddy''s vanilla shake', 'freddys vanilla shake', 'freddy''s vanilla milkshake'],
 'shakes', 'Freddy''s', 1, '560 cal. Thick shake made with signature frozen custard. Classic vanilla.', TRUE),

-- Freddy's Chocolate Shake (Regular): 590 cal, 16P, 62C, 28F (420g)
('freddys_chocolate_shake', 'Freddy''s Chocolate Shake (Regular)', 140, 3.8, 14.8, 6.7,
 0.0, 12.4, 420, NULL,
 'manufacturer', ARRAY['freddy''s chocolate shake', 'freddys chocolate shake', 'freddy''s chocolate milkshake'],
 'shakes', 'Freddy''s', 1, '590 cal. Thick shake made with signature frozen custard. Rich chocolate.', TRUE),

-- Freddy's Hot Fudge Sundae (Regular): 810 cal, 14P, 92C, 39F (350g)
('freddys_hot_fudge_sundae', 'Freddy''s Hot Fudge Sundae (Regular)', 231, 4.0, 26.3, 11.1,
 0.0, 21.1, 350, 350,
 'manufacturer', ARRAY['freddy''s hot fudge sundae', 'freddys hot fudge sundae', 'freddy''s sundae hot fudge'],
 'desserts', 'Freddy''s', 1, '810 cal. Vanilla frozen custard topped with hot fudge sauce, whipped cream, and a cherry.', TRUE)

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
