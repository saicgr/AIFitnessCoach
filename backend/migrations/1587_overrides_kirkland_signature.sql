-- 1587_overrides_kirkland_signature.sql
-- Kirkland Signature (Costco store brand) packaged food products.
-- Sources: Package nutrition labels via fatsecret.com, eatthismuch.com,
-- costcuisine.com, nutritionix.com.
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
-- KIRKLAND SIGNATURE — FROZEN PIZZAS
-- ══════════════════════════════════════════

-- Kirkland Cauliflower Crust Pizza Supreme: 310 cal per 1/4 pizza (138g)
('kirkland_cauliflower_crust_pizza_supreme', 'Kirkland Signature Cauliflower Crust Pizza Supreme', 225, 10.1, 22.5, 10.9,
 0.7, 2.9, 138, NULL,
 'manufacturer', ARRAY['kirkland cauliflower pizza', 'kirkland cauliflower crust pizza', 'costco cauliflower pizza supreme', 'kirkland signature cauliflower crust pizza supreme', 'kirkland cauliflower pizza supreme'],
 'frozen_pizza', 'Kirkland Signature', 1, '310 cal per 1/4 pizza (138g). Gluten-free cauliflower crust with pepperoni, sausage, peppers, olives, onions.', TRUE),

-- Kirkland Pepperoni Pizza (Thin Crust): 360 cal per 1/4 pizza (135g)
('kirkland_pepperoni_pizza_thin_crust', 'Kirkland Signature Pepperoni Pizza (Thin Crust)', 267, 12.6, 21.5, 14.8,
 0.7, 3.0, 135, NULL,
 'manufacturer', ARRAY['kirkland pepperoni pizza', 'kirkland thin crust pepperoni pizza', 'costco kirkland pepperoni pizza', 'kirkland signature pepperoni pizza thin crust'],
 'frozen_pizza', 'Kirkland Signature', 1, '360 cal per 1/4 pizza (135g). Thin crust with pepperoni and mozzarella.', TRUE),

-- Kirkland Cheese Pizza (Frozen): 310 cal per 1/4 pizza (129g)
('kirkland_cheese_pizza_frozen', 'Kirkland Signature Cheese Pizza (Frozen)', 240, 10.1, 29.5, 9.3,
 1.6, 3.1, 129, NULL,
 'manufacturer', ARRAY['kirkland cheese pizza', 'kirkland frozen cheese pizza', 'costco kirkland cheese pizza', 'kirkland signature cheese pizza'],
 'frozen_pizza', 'Kirkland Signature', 1, '310 cal per 1/4 pizza (129g). Frozen cheese pizza with mozzarella and tomato sauce.', TRUE),

-- ══════════════════════════════════════════
-- KIRKLAND SIGNATURE — FROZEN MEALS & PROTEINS
-- ══════════════════════════════════════════

-- Kirkland Chicken Pot Pie (Frozen, large): 300 cal per 1/18 pie (142g)
('kirkland_frozen_chicken_pot_pie', 'Kirkland Signature Chicken Pot Pie (Frozen)', 211, 9.2, 16.2, 12.0,
 0.7, 2.8, 142, NULL,
 'manufacturer', ARRAY['kirkland chicken pot pie frozen', 'kirkland signature chicken pot pie', 'costco frozen chicken pot pie', 'kirkland pot pie'],
 'frozen_meals', 'Kirkland Signature', 1, '300 cal per serving (142g, 1/18 of large pie). Flaky crust with chicken, vegetables, and creamy gravy.', TRUE),

-- Kirkland Italian Sausage & Beef Lasagna: 410 cal per 1 cup (226g)
('kirkland_lasagna', 'Kirkland Signature Italian Sausage & Beef Lasagna', 181, 10.2, 13.3, 9.7,
 1.3, 3.1, 226, NULL,
 'manufacturer', ARRAY['kirkland lasagna', 'kirkland signature lasagna', 'costco kirkland lasagna', 'kirkland italian sausage beef lasagna', 'kirkland beef lasagna'],
 'frozen_meals', 'Kirkland Signature', 1, '410 cal per cup (226g). Layers of pasta, Italian sausage, ground beef, ricotta, and mozzarella.', TRUE),

-- Kirkland Ground Sirloin Beef Patties (1/3 lb): 330 cal per patty (151g)
('kirkland_beef_patties', 'Kirkland Signature Ground Sirloin Beef Patties', 219, 19.9, 0.0, 15.2,
 0.0, 0.0, NULL, 151,
 'manufacturer', ARRAY['kirkland beef patties', 'kirkland sirloin patties', 'costco kirkland burger patties', 'kirkland signature ground sirloin patties', 'kirkland 1/3 lb patties'],
 'frozen_meals', 'Kirkland Signature', 1, '330 cal per patty (151g, 1/3 lb). 100% ground sirloin beef, no fillers.', TRUE),

-- Kirkland Boneless Skinless Chicken Breast (Frozen): 110 cal per 4oz (112g)
('kirkland_chicken_breast_frozen', 'Kirkland Signature Boneless Skinless Chicken Breast (Frozen)', 98, 20.5, 0.0, 1.8,
 0.0, 0.0, 112, NULL,
 'manufacturer', ARRAY['kirkland chicken breast', 'kirkland frozen chicken breast', 'costco kirkland chicken breast', 'kirkland signature boneless skinless chicken breast'],
 'frozen_meals', 'Kirkland Signature', 1, '110 cal per 4oz (112g). Individually frozen boneless skinless chicken breasts. High protein, very lean.', TRUE),

-- ══════════════════════════════════════════
-- KIRKLAND SIGNATURE — SNACKS & BARS
-- ══════════════════════════════════════════

-- Kirkland Protein Bars: ~210 cal per bar (60g), average across flavors
('kirkland_protein_bar', 'Kirkland Signature Protein Bar', 350, 36.7, 38.3, 11.7,
 10.0, 8.3, NULL, 60,
 'manufacturer', ARRAY['kirkland protein bar', 'kirkland signature protein bar', 'costco protein bar', 'kirkland chocolate peanut butter protein bar', 'kirkland cookies and cream protein bar', 'kirkland cookie dough protein bar', 'kirkland brownie protein bar'],
 'snacks', 'Kirkland Signature', 1, '210 cal per bar (60g). Available in Chocolate PB Chunk, Cookies & Cream, Cookie Dough, Brownie. 22g protein, comparable to Quest/ONE bars.', TRUE),

-- Kirkland Nut Bars: 200 cal per bar (40g)
('kirkland_nut_bars', 'Kirkland Signature Nut Bars', 500, 12.5, 42.5, 37.5,
 20.0, 22.5, NULL, 40,
 'manufacturer', ARRAY['kirkland nut bars', 'kirkland signature nut bars', 'costco nut bars', 'kirkland almonds cashews pecans bars'],
 'snacks', 'Kirkland Signature', 1, '200 cal per bar (40g). Made with almonds, cashews, and pecans. High in fiber.', TRUE),

-- Kirkland Trail Mix: 310 cal per 1/2 cup (57g)
('kirkland_trail_mix', 'Kirkland Signature Trail Mix', 544, 17.5, 40.4, 35.1,
 5.3, 33.3, 57, NULL,
 'manufacturer', ARRAY['kirkland trail mix', 'kirkland signature trail mix', 'costco trail mix', 'costco kirkland trail mix'],
 'snacks', 'Kirkland Signature', 1, '310 cal per 1/2 cup (57g). Mix of peanuts, raisins, cashews, almonds, M&Ms.', TRUE),

-- Kirkland Mixed Nuts (Extra Fancy): 170 cal per 1/4 cup (28g)
('kirkland_mixed_nuts', 'Kirkland Signature Mixed Nuts (Extra Fancy)', 607, 17.9, 21.4, 57.1,
 7.1, 3.6, 28, NULL,
 'manufacturer', ARRAY['kirkland mixed nuts', 'kirkland signature mixed nuts', 'costco mixed nuts', 'kirkland extra fancy mixed nuts'],
 'snacks', 'Kirkland Signature', 1, '170 cal per 1/4 cup (28g). Premium mix of cashews, almonds, macadamias, pecans, pistachios. No peanuts.', TRUE),

-- Kirkland Whole Fancy Cashews: 160 cal per 28g
('kirkland_cashews', 'Kirkland Signature Whole Fancy Cashews', 571, 17.9, 28.6, 46.4,
 3.6, 7.1, 28, NULL,
 'manufacturer', ARRAY['kirkland cashews', 'kirkland signature cashews', 'costco cashews', 'kirkland whole fancy cashews'],
 'snacks', 'Kirkland Signature', 1, '160 cal per serving (28g, about 15 pieces). Whole roasted and salted cashews.', TRUE),

-- Kirkland Almonds: 170 cal per 30g
('kirkland_almonds', 'Kirkland Signature Whole Almonds', 567, 20.0, 30.0, 40.0,
 13.3, 3.3, 30, NULL,
 'manufacturer', ARRAY['kirkland almonds', 'kirkland signature almonds', 'costco almonds', 'kirkland whole almonds', 'kirkland supreme almonds'],
 'snacks', 'Kirkland Signature', 1, '170 cal per serving (30g). Whole raw or roasted almonds. High protein and healthy fats.', TRUE),

-- Kirkland Organic Dried Mangoes: 140 cal per 1/2 cup (40g)
('kirkland_dried_mangoes', 'Kirkland Signature Organic Dried Mangoes', 350, 2.5, 85.0, 0.0,
 5.0, 60.0, 40, NULL,
 'manufacturer', ARRAY['kirkland dried mangoes', 'kirkland signature dried mangoes', 'costco dried mangoes', 'kirkland organic dried mango', 'kirkland mango slices'],
 'snacks', 'Kirkland Signature', 1, '140 cal per 1/2 cup (40g). Organic dried mango slices. No added sugar. High in natural sugar and fiber.', TRUE),

-- Kirkland Organic Fruity Snacks: 70 cal per pouch (23g)
('kirkland_organic_fruit_snacks', 'Kirkland Signature Organic Fruit Snacks', 304, 4.3, 73.9, 0.0,
 0.0, 47.8, NULL, 23,
 'manufacturer', ARRAY['kirkland fruit snacks', 'kirkland signature fruit snacks', 'costco fruit snacks', 'kirkland organic fruity snacks', 'kirkland gummy fruit snacks'],
 'snacks', 'Kirkland Signature', 1, '70 cal per pouch (23g). Organic fruit-flavored gummy snacks. Popular kids snack.', TRUE),

-- ══════════════════════════════════════════
-- KIRKLAND SIGNATURE — DAIRY & DRINKS
-- ══════════════════════════════════════════

-- Kirkland Greek Yogurt (Plain, Nonfat): 100 cal per 2/3 cup (170g)
('kirkland_greek_yogurt', 'Kirkland Signature Greek Yogurt (Plain, Nonfat)', 59, 10.6, 4.1, 0.0,
 0.0, 2.4, 170, NULL,
 'manufacturer', ARRAY['kirkland greek yogurt', 'kirkland signature greek yogurt', 'costco greek yogurt', 'kirkland nonfat greek yogurt', 'kirkland plain greek yogurt'],
 'dairy', 'Kirkland Signature', 1, '100 cal per 2/3 cup (170g). Nonfat plain Greek yogurt. 18g protein per serving. Excellent protein-to-calorie ratio.', TRUE),

-- Kirkland Organic Whole Milk: 150 cal per 1 cup (245g)
('kirkland_organic_whole_milk', 'Kirkland Signature Organic Whole Milk', 61, 3.3, 4.9, 3.3,
 0.0, 4.9, 245, NULL,
 'manufacturer', ARRAY['kirkland whole milk', 'kirkland signature whole milk', 'costco organic milk', 'kirkland organic whole milk'],
 'dairy', 'Kirkland Signature', 1, '150 cal per cup (245g). USDA Organic whole milk. 8g protein, 8g fat, 12g carbs per cup.', TRUE),

-- Kirkland Organic 2% Reduced Fat Milk: 120 cal per 1 cup (245g)
('kirkland_organic_2_percent_milk', 'Kirkland Signature Organic 2% Reduced Fat Milk', 49, 3.3, 4.9, 2.0,
 0.0, 5.3, 245, NULL,
 'manufacturer', ARRAY['kirkland 2 percent milk', 'kirkland signature 2% milk', 'costco organic 2% milk', 'kirkland reduced fat milk'],
 'dairy', 'Kirkland Signature', 1, '120 cal per cup (245g). USDA Organic 2% reduced fat milk. 8g protein, 5g fat per cup.', TRUE),

-- Kirkland Unsweetened Almond Milk: 30 cal per 1 cup (245g)
('kirkland_almond_milk', 'Kirkland Signature Unsweetened Almond Milk', 12, 0.4, 0.4, 1.0,
 0.4, 0.0, 245, NULL,
 'manufacturer', ARRAY['kirkland almond milk', 'kirkland signature almond milk', 'costco almond milk', 'kirkland unsweetened almond milk'],
 'beverages', 'Kirkland Signature', 1, '30 cal per cup (245g). Unsweetened almond milk. Very low calorie dairy alternative.', TRUE),

-- Kirkland Organic Orange Juice: 110 cal per 1 cup (248g)
('kirkland_organic_orange_juice', 'Kirkland Signature Organic Orange Juice', 44, 0.0, 10.5, 0.2,
 0.4, 8.5, 248, NULL,
 'manufacturer', ARRAY['kirkland orange juice', 'kirkland signature orange juice', 'costco orange juice', 'kirkland organic oj'],
 'beverages', 'Kirkland Signature', 1, '110 cal per cup (248g). USDA Organic not-from-concentrate orange juice. 26g carbs, 21g sugar per cup.', TRUE),

-- Kirkland Colombian Cold Brew Coffee: 15 cal per can (325g/11 fl oz)
('kirkland_cold_brew_coffee', 'Kirkland Signature Colombian Cold Brew Coffee', 5, 0.0, 0.6, 0.0,
 0.0, 0.0, NULL, 325,
 'manufacturer', ARRAY['kirkland cold brew', 'kirkland signature cold brew', 'costco cold brew coffee', 'kirkland colombian cold brew'],
 'beverages', 'Kirkland Signature', 1, '15 cal per can (325g, 11 fl oz). Colombian cold brew coffee. Shelf stable, ready to drink.', TRUE),

-- ══════════════════════════════════════════
-- KIRKLAND SIGNATURE — BREAD & BAKERY (PACKAGED)
-- ══════════════════════════════════════════

-- Kirkland Multigrain Bread: 150 cal per slice (57g)
('kirkland_multigrain_bread', 'Kirkland Signature Multigrain Bread', 263, 8.8, 43.9, 6.1,
 3.5, 5.3, NULL, 57,
 'manufacturer', ARRAY['kirkland multigrain bread', 'kirkland signature multigrain bread', 'costco multigrain bread', 'kirkland bread multigrain'],
 'bread', 'Kirkland Signature', 1, '150 cal per slice (57g). Hearty multigrain bread with whole grains and seeds.', TRUE),

-- Kirkland Plain Bagel: 310 cal per bagel (113g)
('kirkland_plain_bagel', 'Kirkland Signature Plain Bagel', 274, 9.7, 57.5, 0.9,
 2.7, 6.2, NULL, 113,
 'manufacturer', ARRAY['kirkland bagel', 'kirkland signature bagel', 'costco bagels', 'kirkland plain bagels', 'kirkland everything bagel'],
 'bread', 'Kirkland Signature', 1, '310 cal per bagel (113g). Large bakery-style plain bagels. 11g protein each.', TRUE),

-- Kirkland Hot Dog Buns: 100 cal per bun (45g)
('kirkland_hot_dog_buns', 'Kirkland Signature Hot Dog Buns', 222, 6.7, 42.2, 3.3,
 2.2, 4.4, NULL, 45,
 'manufacturer', ARRAY['kirkland hot dog buns', 'kirkland signature hot dog buns', 'costco hot dog buns', 'kirkland hot dog rolls'],
 'bread', 'Kirkland Signature', 1, '100 cal per bun (45g). Soft hot dog buns/rolls.', TRUE),

-- ══════════════════════════════════════════
-- KIRKLAND SIGNATURE — DELI / PREPARED
-- ══════════════════════════════════════════

-- Kirkland Chicken Salad: 240 cal per 1/2 cup (85g)
('kirkland_chicken_salad', 'Kirkland Signature Rotisserie Chicken Salad', 282, 28.2, 7.1, 17.6,
 1.2, 0.0, 85, NULL,
 'manufacturer', ARRAY['kirkland chicken salad', 'kirkland signature chicken salad', 'costco chicken salad', 'costco rotisserie chicken salad'],
 'deli', 'Kirkland Signature', 1, '240 cal per 1/2 cup (85g). Made with rotisserie chicken. 24g protein per serving.', TRUE),

-- Kirkland Organic Hummus: 170 cal per container (71g)
('kirkland_organic_hummus', 'Kirkland Signature Organic Hummus', 239, 5.6, 15.5, 18.3,
 4.2, 1.4, 71, NULL,
 'manufacturer', ARRAY['kirkland hummus', 'kirkland signature hummus', 'costco hummus', 'kirkland organic hummus'],
 'deli', 'Kirkland Signature', 1, '170 cal per single-serve container (71g). Organic hummus with tahini, lemon, garlic.', TRUE)

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
