-- 1600_overrides_erewhon.sql
-- Erewhon Market — smoothies, hot bar, sushi/poke, bakery, juices, coffee bar,
-- cereals, granola, oatmeal, packaged items, deli, desserts, meat/seafood.
-- Sources: MyNetDiary, FatSecret, EatThisMuch, CalorieKing, MyFoodDiary,
-- OpenFoodFacts, SnapCalorie, Erewhon official site.
-- VERIFIED items from nutrition databases; ESTIMATED from ingredient analysis.
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
-- EREWHON — SMOOTHIES
-- ══════════════════════════════════════════

-- Erewhon Dr. Paul's Raw Animal-Based Smoothie: 480 cal per 24oz (600g)
('erewhon_dr_pauls_smoothie', 'Erewhon Dr. Paul''s Raw Animal-Based Smoothie', 80.0, 5.0, 8.7, 3.0,
 0.7, 6.3, 600, NULL,
 'research', ARRAY['erewhon dr pauls smoothie', 'dr pauls raw animal based smoothie', 'erewhon animal based smoothie', 'dr paul smoothie erewhon'],
 'smoothie', 'Erewhon', 1, '480 cal per 24oz (600g). Organic kefir milk, Heart & Soil beef organs, banana, strawberry, blueberry, colostrum.', TRUE),

-- Erewhon Almond Butter Blast Smoothie: 520 cal per 24oz (600g)
('erewhon_almond_butter_blast_smoothie', 'Erewhon Almond Butter Blast Smoothie', 86.7, 3.7, 8.0, 4.7,
 1.0, 5.0, 600, NULL,
 'research', ARRAY['erewhon almond butter blast', 'almond butter blast smoothie', 'erewhon almond butter smoothie', 'erewhon almond smoothie'],
 'smoothie', 'Erewhon', 1, '520 cal per 24oz (600g). Organic almond milk, almond butter, cacao, plant protein, banana, dates.', TRUE),

-- Erewhon Brainstorm Smoothie: 380 cal per 24oz (600g)
('erewhon_brainstorm_smoothie', 'Erewhon Brainstorm Smoothie', 63.3, 2.0, 9.2, 2.3,
 0.8, 5.8, 600, NULL,
 'research', ARRAY['erewhon brainstorm smoothie', 'brainstorm smoothie erewhon', 'erewhon brain smoothie', 'erewhon lions mane smoothie'],
 'smoothie', 'Erewhon', 1, '380 cal per 24oz (600g). Organic, vegan, brain-health blend with MCT, lion''s mane, blueberries.', TRUE),

-- Erewhon Body Ecology Smoothie: 280 cal per 24oz (600g)
('erewhon_body_ecology_smoothie', 'Erewhon Body Ecology Smoothie', 46.7, 1.3, 5.8, 2.0,
 1.0, 3.0, 600, NULL,
 'research', ARRAY['erewhon body ecology smoothie', 'body ecology smoothie', 'erewhon green smoothie', 'erewhon avocado smoothie'],
 'smoothie', 'Erewhon', 1, '280 cal per 24oz (600g). Avocado, green apple, celery, lemon, cayenne.', TRUE),

-- Erewhon Amino Acid Trip Smoothie: 310 cal per 24oz (600g)
('erewhon_amino_acid_trip_smoothie', 'Erewhon Amino Acid Trip Smoothie', 51.7, 2.5, 6.3, 1.7,
 0.7, 3.7, 600, NULL,
 'research', ARRAY['erewhon amino acid trip', 'amino acid trip smoothie', 'erewhon amino smoothie', 'erewhon amino acid smoothie'],
 'smoothie', 'Erewhon', 1, '310 cal per 24oz (600g). Contains amino acids supplement blend.', TRUE),

-- Erewhon Vanilla Matcha Smoothie: 420 cal per 24oz (600g)
('erewhon_vanilla_matcha_smoothie', 'Erewhon Vanilla Matcha Smoothie', 70.0, 3.3, 7.5, 2.7,
 0.5, 4.7, 600, NULL,
 'research', ARRAY['erewhon vanilla matcha smoothie', 'vanilla matcha smoothie erewhon', 'erewhon matcha smoothie', 'erewhon matcha collagen smoothie'],
 'smoothie', 'Erewhon', 1, '420 cal per 24oz (600g). Ceremonial matcha, collagen, lion''s mane, sea moss.', TRUE),

-- Erewhon Raw Farms Strawberry Kefir Smoothie: 450 cal per 24oz (600g)
('erewhon_raw_farms_strawberry_smoothie', 'Erewhon Raw Farms Strawberry Kefir Smoothie', 75.0, 4.7, 8.0, 2.3,
 0.3, 6.0, 600, NULL,
 'research', ARRAY['erewhon raw farms strawberry smoothie', 'raw farms strawberry kefir smoothie', 'erewhon strawberry kefir smoothie', 'erewhon kefir smoothie'],
 'smoothie', 'Erewhon', 1, '450 cal per 24oz (600g). Raw kefir, grass-fed whey protein, colostrum, strawberry.', TRUE),

-- Erewhon Maca Bomb Smoothie: 550 cal per 24oz (600g)
('erewhon_maca_bomb_smoothie', 'Erewhon Maca Bomb Smoothie', 91.7, 3.0, 10.3, 4.0,
 1.3, 5.3, 600, NULL,
 'research', ARRAY['erewhon maca bomb smoothie', 'maca bomb smoothie', 'erewhon maca smoothie', 'erewhon maca bomb'],
 'smoothie', 'Erewhon', 1, '550 cal per 24oz (600g). Maca, hemp seeds, cacao nibs, goji berries, nut butter.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — HOT BAR ITEMS
-- ══════════════════════════════════════════

-- Erewhon Grain Bowl: 450 cal per bowl (350g)
('erewhon_grain_bowl', 'Erewhon Grain Bowl', 128.6, 4.3, 15.7, 5.1,
 1.7, 1.4, 350, NULL,
 'research', ARRAY['erewhon grain bowl', 'erewhon quinoa bowl', 'erewhon rice bowl', 'erewhon hot bar grain bowl'],
 'prepared_meal', 'Erewhon', 1, '450 cal per bowl (350g). Quinoa/rice base with seasonal vegetables.', TRUE),

-- Erewhon Roasted Organic Chicken: 200 cal per 4oz (113g)
('erewhon_roasted_organic_chicken', 'Erewhon Roasted Organic Chicken', 177.0, 20.4, 0.0, 9.7,
 0.0, 0.0, 113, NULL,
 'research', ARRAY['erewhon roasted chicken', 'erewhon organic chicken', 'erewhon rotisserie chicken hot bar', 'erewhon chicken hot bar'],
 'prepared_meal', 'Erewhon', 1, '200 cal per 4oz (113g). Comparable to Whole Foods organic rotisserie.', TRUE),

-- Erewhon Mac and Cheese: 480 cal per serving (250g)
('erewhon_mac_and_cheese', 'Erewhon Mac and Cheese', 192.0, 6.4, 16.8, 10.4,
 0.8, 1.6, 250, NULL,
 'research', ARRAY['erewhon mac and cheese', 'erewhon mac n cheese', 'erewhon macaroni and cheese', 'erewhon hot bar mac'],
 'prepared_meal', 'Erewhon', 1, '480 cal per serving (250g). Hot bar mac and cheese.', TRUE),

-- Erewhon Pizza Slice (Sourdough Cheese): 320 cal per slice (140g)
('erewhon_sourdough_cheese_pizza', 'Erewhon Pizza Slice (Sourdough Cheese)', 228.6, 10.0, 25.7, 10.0,
 1.4, 2.9, NULL, 140,
 'research', ARRAY['erewhon pizza slice', 'erewhon sourdough pizza', 'erewhon cheese pizza', 'erewhon hot bar pizza'],
 'prepared_meal', 'Erewhon', 1, '320 cal per slice (140g). Mozzarella, fresh basil, crushed tomato on sourdough crust.', TRUE),

-- Erewhon Pasta Dish (Hot Bar): 420 cal per serving (300g)
('erewhon_pasta_dish', 'Erewhon Pasta Dish (Hot Bar)', 140.0, 4.7, 17.3, 5.3,
 1.0, 1.7, 300, NULL,
 'research', ARRAY['erewhon pasta', 'erewhon hot bar pasta', 'erewhon pasta dish', 'erewhon organic pasta'],
 'prepared_meal', 'Erewhon', 1, '420 cal per serving (300g). Average hot bar pasta dish.', TRUE),

-- Erewhon Korean Short Ribs: 380 cal per 4oz (113g)
('erewhon_korean_short_ribs', 'Erewhon Korean Short Ribs', 336.3, 19.5, 10.6, 24.8,
 0.0, 7.1, 113, NULL,
 'research', ARRAY['erewhon korean short ribs', 'erewhon short ribs', 'erewhon kalbi', 'erewhon hot bar short ribs'],
 'prepared_meal', 'Erewhon', 1, '380 cal per 4oz (113g). $40/lb.', TRUE),

-- Erewhon Organic Carne Asada: 250 cal per 4oz (113g)
('erewhon_carne_asada', 'Erewhon Organic Carne Asada', 221.2, 24.8, 1.8, 12.4,
 0.0, 0.9, 113, NULL,
 'research', ARRAY['erewhon carne asada', 'erewhon organic carne asada', 'erewhon hot bar carne asada', 'erewhon steak'],
 'prepared_meal', 'Erewhon', 1, '250 cal per 4oz (113g). $32/lb.', TRUE),

-- Erewhon Miso Black Cod: 290 cal per 4oz (113g)
('erewhon_miso_black_cod', 'Erewhon Miso Black Cod', 256.6, 17.7, 13.3, 14.2,
 0.0, 8.8, 113, NULL,
 'research', ARRAY['erewhon miso black cod', 'erewhon black cod', 'erewhon miso cod', 'erewhon hot bar cod'],
 'prepared_meal', 'Erewhon', 1, '290 cal per 4oz (113g). $40/lb.', TRUE),

-- Erewhon Organic Jasmine Rice: 210 cal per cup (185g)
('erewhon_jasmine_rice', 'Erewhon Organic Jasmine Rice', 113.5, 2.2, 24.9, 0.3,
 0.5, 0.0, 185, NULL,
 'research', ARRAY['erewhon jasmine rice', 'erewhon rice', 'erewhon organic rice', 'erewhon hot bar rice'],
 'prepared_meal', 'Erewhon', 1, '210 cal per cup (185g). $11/lb.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — SUSHI & POKE
-- ══════════════════════════════════════════

-- Erewhon Sushi Tuna Crispy Rice Spicy GF: 350 cal per serving (200g)
('erewhon_sushi_tuna_crispy_rice', 'Erewhon Sushi Tuna Crispy Rice Spicy GF', 175.0, 9.0, 19.0, 7.0,
 1.0, 2.5, 200, NULL,
 'manufacturer', ARRAY['erewhon tuna crispy rice', 'erewhon spicy tuna crispy rice', 'erewhon sushi tuna', 'erewhon crispy rice sushi'],
 'prepared_meal', 'Erewhon', 1, '350 cal per serving (200g). Gluten-free spicy tuna crispy rice.', TRUE),

-- Erewhon Poke Bowl: 550 cal per bowl (400g)
('erewhon_poke_bowl', 'Erewhon Poke Bowl', 137.5, 7.5, 13.8, 5.0,
 1.3, 2.0, 400, NULL,
 'research', ARRAY['erewhon poke bowl', 'erewhon tuna poke bowl', 'erewhon salmon poke bowl', 'erewhon poke'],
 'prepared_meal', 'Erewhon', 1, '550 cal per bowl (400g). Wild tuna or salmon poke bowl.', TRUE),

-- Erewhon Poke Nacho Bowl: 480 cal per bowl (350g)
('erewhon_poke_nacho_bowl', 'Erewhon Poke Nacho Bowl', 137.1, 6.3, 12.0, 6.9,
 1.1, 1.7, 350, NULL,
 'research', ARRAY['erewhon poke nacho bowl', 'erewhon nacho bowl', 'erewhon poke nachos', 'erewhon truffle sriracha poke'],
 'prepared_meal', 'Erewhon', 1, '480 cal per bowl (350g). Wild tuna/salmon on crispy chips, avocado, truffle-sriracha.', TRUE),

-- Erewhon Sushi Sandwich: 420 cal per sandwich (250g)
('erewhon_sushi_sandwich', 'Erewhon Sushi Sandwich (Crispy)', 168.0, 6.4, 19.2, 7.2,
 1.2, 2.4, NULL, 250,
 'research', ARRAY['erewhon sushi sandwich', 'erewhon crispy sushi sandwich', 'erewhon sushi wrap', 'erewhon sushi sandwich crispy'],
 'prepared_meal', 'Erewhon', 1, '420 cal per sandwich (250g). Crispy sushi sandwich.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — PREPARED FOODS
-- ══════════════════════════════════════════

-- Erewhon Buffalo Cauliflower Bites (Vegan): 280 cal per serving (170g)
('erewhon_buffalo_cauliflower_bites', 'Erewhon Buffalo Cauliflower Bites (Vegan)', 164.7, 3.5, 17.6, 9.4,
 2.4, 1.8, 170, NULL,
 'research', ARRAY['erewhon buffalo cauliflower', 'erewhon cauliflower bites', 'erewhon vegan cauliflower', 'erewhon buffalo cauliflower bites'],
 'prepared_meal', 'Erewhon', 1, '280 cal per serving (170g). Flash-fried in avocado oil, cayenne hot sauce. $20/lb.', TRUE),

-- Erewhon Coconut Chicken Tenders: 360 cal per 3 pieces (170g)
('erewhon_coconut_chicken_tenders', 'Erewhon Coconut Chicken Tenders', 211.8, 14.1, 12.9, 11.8,
 1.2, 1.8, 170, NULL,
 'research', ARRAY['erewhon chicken tenders', 'erewhon coconut chicken tenders', 'erewhon chicken fingers', 'erewhon fried chicken tenders'],
 'prepared_meal', 'Erewhon', 1, '360 cal per 3 pieces (170g). Coconut-crusted chicken tenders.', TRUE),

-- Erewhon Rotisserie Chicken: 200 cal per 4oz (113g)
('erewhon_rotisserie_chicken', 'Erewhon Rotisserie Chicken', 177.0, 20.4, 0.0, 9.7,
 0.0, 0.0, 113, NULL,
 'research', ARRAY['erewhon rotisserie chicken', 'erewhon whole chicken', 'erewhon organic rotisserie chicken', 'erewhon roast chicken'],
 'prepared_meal', 'Erewhon', 1, '200 cal per 4oz (113g). Comparable to organic rotisserie.', TRUE),

-- Erewhon Rotisserie Chicken Sandwich: 520 cal per sandwich (300g)
('erewhon_rotisserie_chicken_sandwich', 'Erewhon Rotisserie Chicken Sandwich', 173.3, 10.7, 12.7, 7.3,
 1.0, 1.3, NULL, 300,
 'research', ARRAY['erewhon chicken sandwich', 'erewhon rotisserie chicken sandwich', 'erewhon chicken sandwich hot', 'erewhon hot chicken sandwich'],
 'sandwich', 'Erewhon', 1, '520 cal per sandwich (300g). Rotisserie chicken sandwich.', TRUE),

-- Erewhon Chicken Pot Pie: 480 cal per pie (300g)
('erewhon_chicken_pot_pie', 'Erewhon Chicken Pot Pie', 160.0, 6.0, 12.7, 9.3,
 1.0, 1.3, NULL, 300,
 'research', ARRAY['erewhon chicken pot pie', 'erewhon pot pie', 'erewhon chicken pie', 'erewhon pot pie chicken'],
 'prepared_meal', 'Erewhon', 1, '480 cal per pie (300g). SnapCalorie reference.', TRUE),

-- Erewhon New England Clam Chowder: 300 cal per bowl (350g)
('erewhon_clam_chowder', 'Erewhon New England Clam Chowder', 85.7, 3.4, 6.9, 5.1,
 0.6, 0.9, 350, NULL,
 'manufacturer', ARRAY['erewhon clam chowder', 'erewhon new england clam chowder', 'erewhon chowder', 'erewhon soup clam chowder'],
 'soup', 'Erewhon', 1, '300 cal per bowl (350g). Verified on MyNetDiary.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — BAKERY
-- ══════════════════════════════════════════

-- Erewhon MadChip Cookie: 350 cal per cookie (85g)
('erewhon_madchip_cookie', 'Erewhon Organic MadChip Cookie', 411.8, 4.7, 44.7, 23.5,
 2.4, 25.9, NULL, 85,
 'research', ARRAY['erewhon madchip cookie', 'madchip cookie erewhon', 'erewhon chocolate chip cookie', 'erewhon organic madchip cookie'],
 'bakery', 'Erewhon', 1, '350 cal per cookie (85g). Organic Italian chocolate (Agostoni), Madagascar vanilla, sea salt.', TRUE),

-- Erewhon Chef Bae Crack Cookie (GF): 280 cal per cookie (70g)
('erewhon_chef_bae_crack_cookie', 'Erewhon Chef Bae Crack Cookie (GF)', 400.0, 8.6, 37.1, 25.7,
 4.3, 22.9, NULL, 70,
 'research', ARRAY['erewhon chef bae crack cookie', 'chef bae crack cookie', 'erewhon crack cookie', 'erewhon gf cookie'],
 'bakery', 'Erewhon', 1, '280 cal per cookie (70g). Almond flour, coconut sugar, dark chocolate, plant butter. Gluten-free.', TRUE),

-- Erewhon Vegan Chocolate Chip Cookie (GF): 300 cal per cookie (75g)
('erewhon_vegan_chocolate_chip_cookie', 'Erewhon Vegan Chocolate Chip Cookie (GF)', 400.0, 5.3, 45.3, 24.0,
 2.7, 24.0, NULL, 75,
 'research', ARRAY['erewhon vegan chocolate chip cookie', 'erewhon vegan cookie', 'erewhon gf vegan cookie', 'erewhon gluten free vegan cookie'],
 'bakery', 'Erewhon', 1, '300 cal per cookie (75g). Brown rice flour, coconut sugar, chocolate. Vegan & gluten-free.', TRUE),

-- Erewhon Oatmeal Chocolate Chip Cookie (Vegan): 320 cal per cookie (80g)
('erewhon_oatmeal_chocolate_chip_cookie', 'Erewhon Oatmeal Chocolate Chip Cookie (Vegan)', 400.0, 6.3, 50.0, 20.0,
 3.8, 25.0, NULL, 80,
 'research', ARRAY['erewhon oatmeal chocolate chip cookie', 'erewhon oatmeal cookie', 'erewhon vegan oatmeal cookie', 'erewhon oatmeal cookie vegan'],
 'bakery', 'Erewhon', 1, '320 cal per cookie (80g). Vegan oatmeal chocolate chip cookie.', TRUE),

-- Erewhon Banana Bread: 280 cal per slice (100g)
('erewhon_banana_bread', 'Erewhon Banana Bread', 280.0, 5.0, 38.0, 12.0,
 2.0, 18.0, NULL, 100,
 'research', ARRAY['erewhon banana bread', 'erewhon banana bread slice', 'erewhon organic banana bread', 'erewhon bakery banana bread'],
 'bakery', 'Erewhon', 1, '280 cal per slice (100g).', TRUE),

-- Erewhon Blueberry Muffin: 340 cal per muffin (120g)
('erewhon_blueberry_muffin', 'Erewhon Blueberry Muffin', 283.3, 5.0, 36.7, 13.3,
 1.7, 18.3, NULL, 120,
 'research', ARRAY['erewhon blueberry muffin', 'erewhon muffin', 'erewhon organic muffin', 'erewhon bakery muffin'],
 'bakery', 'Erewhon', 1, '340 cal per muffin (120g). Blueberry muffin.', TRUE),

-- Erewhon Butter Croissant: 310 cal per croissant (85g)
('erewhon_butter_croissant', 'Erewhon Butter Croissant', 364.7, 7.1, 37.6, 21.2,
 1.2, 7.1, NULL, 85,
 'research', ARRAY['erewhon croissant', 'erewhon butter croissant', 'erewhon bakery croissant', 'erewhon french croissant'],
 'bakery', 'Erewhon', 1, '310 cal per croissant (85g). Butter croissant.', TRUE),

-- Erewhon MadChip Cookie Sundae: 580 cal per sundae (200g)
('erewhon_madchip_cookie_sundae', 'Erewhon MadChip Cookie Sundae', 290.0, 4.0, 31.0, 17.0,
 1.5, 19.0, 200, NULL,
 'research', ARRAY['erewhon madchip cookie sundae', 'erewhon cookie sundae', 'erewhon sundae', 'erewhon ice cream sundae'],
 'bakery', 'Erewhon', 1, '580 cal per sundae (200g). Coconut soft serve, cookie crumble, chocolate glaze.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — JUICES
-- ══════════════════════════════════════════

-- Erewhon Heavenly Green Juice: 180 cal per 16oz (480g)
('erewhon_heavenly_green_juice', 'Erewhon Heavenly Green Juice', 37.5, 0.6, 8.8, 0.2,
 0.4, 7.1, NULL, 480,
 'research', ARRAY['erewhon heavenly green juice', 'erewhon green juice heavenly', 'erewhon heavenly juice', 'erewhon heavenly green'],
 'juice', 'Erewhon', 1, '180 cal per 16oz bottle (480g). Apple, pineapple, kiwi, greens.', TRUE),

-- Erewhon High Vibe Juice: 200 cal per 16oz (480g)
('erewhon_high_vibe_juice', 'Erewhon High Vibe Juice', 41.7, 0.6, 9.6, 0.2,
 0.4, 7.9, NULL, 480,
 'research', ARRAY['erewhon high vibe juice', 'erewhon high vibe', 'erewhon beet juice', 'erewhon rose water juice'],
 'juice', 'Erewhon', 1, '200 cal per 16oz bottle (480g). Apple, pineapple, beets, lemon, rose water.', TRUE),

-- Erewhon The Big Green Juice: 120 cal per 16oz (480g)
('erewhon_big_green_juice', 'Erewhon The Big Green Juice', 25.0, 0.8, 5.0, 0.2,
 0.6, 3.3, NULL, 480,
 'research', ARRAY['erewhon big green juice', 'erewhon the big green', 'erewhon kale spinach juice', 'erewhon green juice big'],
 'juice', 'Erewhon', 1, '120 cal per 16oz bottle (480g). Kale, spinach, cucumber, apple.', TRUE),

-- Erewhon Just Greens & Apple Juice: 130 cal per 16oz (480g)
('erewhon_just_greens_apple_juice', 'Erewhon Just Greens & Apple Juice', 27.1, 0.8, 5.4, 0.2,
 0.6, 3.8, NULL, 480,
 'research', ARRAY['erewhon just greens apple juice', 'erewhon greens and apple juice', 'erewhon just greens apple', 'erewhon celery kale juice'],
 'juice', 'Erewhon', 1, '130 cal per 16oz bottle (480g). Celery, cucumber, kale, parsley, apple.', TRUE),

-- Erewhon Just Greens Juice: 60 cal per 16oz (480g)
('erewhon_just_greens_juice', 'Erewhon Just Greens Juice', 12.5, 0.8, 2.1, 0.2,
 0.4, 0.8, NULL, 480,
 'research', ARRAY['erewhon just greens juice', 'erewhon just greens', 'erewhon pure greens juice', 'erewhon green celery juice'],
 'juice', 'Erewhon', 1, '60 cal per 16oz bottle (480g). Celery, cucumber, kale, parsley (no fruit).', TRUE),

-- Erewhon Elissa Goodman Green Juice: 140 cal per 16oz (480g)
('erewhon_elissa_goodman_green_juice', 'Erewhon Elissa Goodman Green Juice', 29.2, 0.6, 4.6, 1.0,
 0.4, 2.1, NULL, 480,
 'research', ARRAY['erewhon elissa goodman juice', 'elissa goodman green juice', 'erewhon elissa goodman', 'erewhon coconut green juice'],
 'juice', 'Erewhon', 1, '140 cal per 16oz bottle (480g). Celery, cucumber, ginger, coconut cream.', TRUE),

-- Erewhon Hardcore Greens Juice: 80 cal per 16oz (480g)
('erewhon_hardcore_greens_juice', 'Erewhon Hardcore Greens Juice', 16.7, 1.0, 2.9, 0.2,
 0.6, 1.3, NULL, 480,
 'research', ARRAY['erewhon hardcore greens juice', 'erewhon hardcore greens', 'erewhon hardcore juice', 'erewhon dense greens juice'],
 'juice', 'Erewhon', 1, '80 cal per 16oz bottle (480g). Dense greens blend.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — WELLNESS SHOTS
-- ══════════════════════════════════════════

-- Erewhon Wellness Shot (Ginger & Garlic): 25 cal per 2oz (60g)
('erewhon_wellness_shot_ginger_garlic', 'Erewhon Wellness Shot (Ginger & Garlic)', 41.7, 1.7, 8.3, 0.0,
 0.0, 5.0, NULL, 60,
 'research', ARRAY['erewhon wellness shot', 'erewhon ginger garlic shot', 'erewhon wellness shot ginger', 'erewhon immunity shot ginger garlic'],
 'wellness_shot', 'Erewhon', 1, '25 cal per 2oz shot (60g). Carrot, lemon, ginger, garlic.', TRUE),

-- Erewhon Ginger Shot: 20 cal per 2oz (60g)
('erewhon_ginger_shot', 'Erewhon Ginger Shot', 33.3, 0.0, 8.3, 0.0,
 0.0, 5.0, NULL, 60,
 'research', ARRAY['erewhon ginger shot', 'erewhon pure ginger shot', 'erewhon fresh ginger shot', 'ginger shot erewhon'],
 'wellness_shot', 'Erewhon', 1, '20 cal per 2oz shot (60g). Pure ginger shot.', TRUE),

-- Erewhon Golden Force Shot: 30 cal per 2oz (60g)
('erewhon_golden_force_shot', 'Erewhon Golden Force Shot', 50.0, 1.7, 10.0, 0.8,
 0.0, 6.7, NULL, 60,
 'research', ARRAY['erewhon golden force shot', 'erewhon turmeric shot', 'erewhon golden shot', 'golden force shot erewhon'],
 'wellness_shot', 'Erewhon', 1, '30 cal per 2oz shot (60g). Turmeric-based wellness shot.', TRUE),

-- Erewhon Gut Health Shot: 25 cal per 2oz (60g)
('erewhon_gut_health_shot', 'Erewhon Gut Health Shot', 41.7, 0.0, 8.3, 0.0,
 0.0, 5.0, NULL, 60,
 'research', ARRAY['erewhon gut health shot', 'erewhon gut shot', 'erewhon digestive shot', 'gut health shot erewhon'],
 'wellness_shot', 'Erewhon', 1, '25 cal per 2oz shot (60g). Gut health wellness shot.', TRUE),

-- Erewhon Lumen Immune Support Shot: 30 cal per 2oz (60g)
('erewhon_lumen_immune_shot', 'Erewhon Lumen Immune Support Shot', 50.0, 1.7, 10.0, 0.8,
 0.0, 6.7, NULL, 60,
 'research', ARRAY['erewhon lumen immune shot', 'erewhon immune support shot', 'erewhon lumen shot', 'lumen immune shot erewhon'],
 'wellness_shot', 'Erewhon', 1, '30 cal per 2oz shot (60g). Hemp seed oil, elderberry, ginger, turmeric, sea moss.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — COFFEE BAR
-- ══════════════════════════════════════════

-- Erewhon Cafe Latte (Oat Milk, 12oz): 180 cal per 12oz (360g)
('erewhon_cafe_latte_oat', 'Erewhon Cafe Latte (Oat Milk)', 50.0, 0.8, 6.7, 1.9,
 0.3, 3.3, 360, NULL,
 'research', ARRAY['erewhon oat milk latte', 'erewhon cafe latte oat', 'erewhon latte oat milk', 'erewhon oat latte'],
 'coffee', 'Erewhon', 1, '180 cal per 12oz (360g). Oat milk cafe latte.', TRUE),

-- Erewhon Cafe Latte (Almond Milk, 12oz): 120 cal per 12oz (360g)
('erewhon_cafe_latte_almond', 'Erewhon Cafe Latte (Almond Milk)', 33.3, 0.6, 3.9, 1.7,
 0.0, 2.2, 360, NULL,
 'research', ARRAY['erewhon almond milk latte', 'erewhon cafe latte almond', 'erewhon latte almond milk', 'erewhon almond latte'],
 'coffee', 'Erewhon', 1, '120 cal per 12oz (360g). Almond milk cafe latte.', TRUE),

-- Erewhon Matcha Latte (Oat Milk, 12oz): 200 cal per 12oz (360g)
('erewhon_matcha_latte_oat', 'Erewhon Matcha Latte (Oat Milk)', 55.6, 1.1, 7.8, 1.9,
 0.3, 3.9, 360, NULL,
 'research', ARRAY['erewhon matcha latte oat', 'erewhon oat matcha latte', 'erewhon matcha oat milk', 'erewhon ceremonial matcha latte'],
 'coffee', 'Erewhon', 1, '200 cal per 12oz (360g). Ceremonial grade matcha with oat milk.', TRUE),

-- Erewhon Matcha Latte (Almond Milk, 12oz): 140 cal per 12oz (360g)
('erewhon_matcha_latte_almond', 'Erewhon Matcha Latte (Almond Milk)', 38.9, 0.6, 5.0, 1.7,
 0.0, 2.8, 360, NULL,
 'research', ARRAY['erewhon matcha latte almond', 'erewhon almond matcha latte', 'erewhon matcha almond milk', 'erewhon matcha latte almond milk'],
 'coffee', 'Erewhon', 1, '140 cal per 12oz (360g). Ceremonial grade matcha with almond milk.', TRUE),

-- Erewhon Iced Matcha Latte (16oz): 180 cal per 16oz (480g)
('erewhon_iced_matcha_latte', 'Erewhon Iced Matcha Latte', 37.5, 0.6, 5.0, 1.3,
 0.2, 2.5, 480, NULL,
 'research', ARRAY['erewhon iced matcha latte', 'erewhon iced matcha', 'erewhon cold matcha latte', 'erewhon matcha iced'],
 'coffee', 'Erewhon', 1, '180 cal per 16oz (480g). Iced matcha latte.', TRUE),

-- Erewhon Golden Milk Latte (12oz): 160 cal per 12oz (360g)
('erewhon_golden_milk_latte', 'Erewhon Golden Milk Latte', 44.4, 0.6, 6.1, 1.9,
 0.3, 2.8, 360, NULL,
 'research', ARRAY['erewhon golden milk latte', 'erewhon turmeric latte', 'erewhon golden latte', 'erewhon golden milk'],
 'coffee', 'Erewhon', 1, '160 cal per 12oz (360g). Turmeric, ginger, cinnamon, coconut milk.', TRUE),

-- Erewhon Adaptogenic Latte (12oz): 170 cal per 12oz (360g)
('erewhon_adaptogenic_latte', 'Erewhon Adaptogenic Latte', 47.2, 0.8, 5.6, 2.2,
 0.3, 2.2, 360, NULL,
 'research', ARRAY['erewhon adaptogenic latte', 'erewhon ashwagandha latte', 'erewhon reishi latte', 'erewhon mushroom latte'],
 'coffee', 'Erewhon', 1, '170 cal per 12oz (360g). Ashwagandha, reishi, lion''s mane.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — CEREALS (VERIFIED)
-- ══════════════════════════════════════════

-- Erewhon Strawberry Crisp Cereal: 120 cal per 3/4 cup (32g)
('erewhon_strawberry_crisp_cereal', 'Erewhon Strawberry Crisp Cereal', 375.0, 6.3, 84.4, 1.6,
 3.1, 18.8, 32, NULL,
 'manufacturer', ARRAY['erewhon strawberry crisp cereal', 'erewhon strawberry cereal', 'erewhon strawberry crisp', 'erewhon cereal strawberry'],
 'cereal', 'Erewhon', 1, '120 cal per 3/4 cup (32g). Verified on FatSecret and CalorieKing.', TRUE),

-- Erewhon Harvest Medley Cereal: 150 cal per 1/4 cup (40g)
('erewhon_harvest_medley_cereal', 'Erewhon Harvest Medley Cereal', 375.0, 7.5, 80.0, 2.5,
 5.0, 0.0, 40, NULL,
 'manufacturer', ARRAY['erewhon harvest medley cereal', 'erewhon harvest medley', 'erewhon harvest cereal', 'erewhon medley cereal'],
 'cereal', 'Erewhon', 1, '150 cal per 1/4 cup (40g). Verified on EatThisMuch.', TRUE),

-- Erewhon Cinnamon Crispy Brown Rice Cereal: 110 cal per 1 cup (30g)
('erewhon_cinnamon_crispy_brown_rice_cereal', 'Erewhon Cinnamon Crispy Brown Rice Cereal', 366.7, 6.7, 76.7, 1.7,
 3.3, 6.7, 30, NULL,
 'manufacturer', ARRAY['erewhon cinnamon crispy brown rice cereal', 'erewhon cinnamon cereal', 'erewhon brown rice cereal cinnamon', 'erewhon crispy rice cinnamon'],
 'cereal', 'Erewhon', 1, '110 cal per 1 cup (30g). Verified on MyFoodDiary and MyNetDiary.', TRUE),

-- Erewhon Honey Rice Twice Cereal: 120 cal per 3/4 cup (30g)
('erewhon_honey_rice_twice_cereal', 'Erewhon Honey Rice Twice Cereal', 400.0, 6.7, 86.7, 0.0,
 0.0, 26.7, 30, NULL,
 'manufacturer', ARRAY['erewhon honey rice twice cereal', 'erewhon honey rice cereal', 'erewhon honey rice twice', 'erewhon rice cereal honey'],
 'cereal', 'Erewhon', 1, '120 cal per 3/4 cup (30g). Verified on FatSecret and Instacart.', TRUE),

-- Erewhon Corn Flakes Cereal: 130 cal per 1 cup (34g)
('erewhon_corn_flakes_cereal', 'Erewhon Corn Flakes Cereal', 382.4, 8.8, 88.2, 0.0,
 0.0, 0.0, 34, NULL,
 'manufacturer', ARRAY['erewhon corn flakes', 'erewhon corn flakes cereal', 'erewhon organic corn flakes', 'erewhon cereal corn flakes'],
 'cereal', 'Erewhon', 1, '130 cal per 1 cup (34g). Verified on MyFoodDiary and EatThisMuch.', TRUE),

-- Erewhon Crispy Brown Rice Cereal (GF): 110 cal per 1 cup (30g)
('erewhon_crispy_brown_rice_cereal', 'Erewhon Crispy Brown Rice Cereal (GF)', 366.7, 6.7, 83.3, 1.7,
 3.3, 3.3, 30, NULL,
 'manufacturer', ARRAY['erewhon crispy brown rice cereal', 'erewhon brown rice cereal', 'erewhon gf brown rice cereal', 'erewhon gluten free brown rice cereal'],
 'cereal', 'Erewhon', 1, '110 cal per 1 cup (30g). Gluten-free. Verified on MyFoodDiary and EatThisMuch.', TRUE),

-- Erewhon Raisin Bran Cereal: 180 cal per 1 cup (55g)
('erewhon_raisin_bran_cereal', 'Erewhon Raisin Bran Cereal', 327.3, 10.9, 72.7, 1.8,
 10.9, 14.5, 55, NULL,
 'manufacturer', ARRAY['erewhon raisin bran', 'erewhon raisin bran cereal', 'erewhon organic raisin bran', 'erewhon cereal raisin bran'],
 'cereal', 'Erewhon', 1, '180 cal per 1 cup (55g). Verified on FatSecret and EatThisMuch.', TRUE),

-- Erewhon Simply Vanilla Granola: 240 cal per 3/4 cup (55g)
('erewhon_simply_vanilla_granola', 'Erewhon Simply Vanilla Granola', 436.4, 9.1, 67.3, 14.5,
 7.3, 21.8, 55, NULL,
 'manufacturer', ARRAY['erewhon simply vanilla granola', 'erewhon vanilla granola', 'erewhon granola vanilla', 'erewhon simply vanilla'],
 'cereal', 'Erewhon', 1, '240 cal per 3/4 cup (55g). Verified on MyNetDiary and MyFoodDiary.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — GRANOLAS
-- ══════════════════════════════════════════

-- Erewhon Paleo Coconut Granola: 280 cal per 1/3 cup (55g)
('erewhon_paleo_coconut_granola', 'Erewhon Paleo Coconut Granola', 509.1, 12.7, 32.7, 40.0,
 7.3, 14.5, 55, NULL,
 'research', ARRAY['erewhon paleo coconut granola', 'erewhon coconut granola', 'erewhon paleo granola coconut', 'erewhon grain free granola'],
 'granola', 'Erewhon', 1, '280 cal per 1/3 cup (55g). Sunflower/pumpkin seeds, coconut, almonds, walnuts, pecans, honey.', TRUE),

-- Erewhon Paleo Chocolate Granola: 290 cal per 1/3 cup (55g)
('erewhon_paleo_chocolate_granola', 'Erewhon Paleo Chocolate Granola', 527.3, 12.7, 36.4, 40.0,
 9.1, 18.2, 55, NULL,
 'research', ARRAY['erewhon paleo chocolate granola', 'erewhon chocolate granola', 'erewhon paleo granola chocolate', 'erewhon cacao granola'],
 'granola', 'Erewhon', 1, '290 cal per 1/3 cup (55g). Same nut/seed base as coconut variant, plus cacao.', TRUE),

-- Erewhon Vegan Granola (Maple & Spices): 250 cal per 3/4 cup (55g)
('erewhon_vegan_granola_maple', 'Erewhon Vegan Granola (Maple & Spices)', 454.5, 10.9, 58.2, 18.2,
 7.3, 18.2, 55, NULL,
 'research', ARRAY['erewhon vegan granola maple', 'erewhon maple granola', 'erewhon vegan granola', 'erewhon maple spice granola'],
 'granola', 'Erewhon', 1, '250 cal per 3/4 cup (55g). GF oats, almonds, sesame, pumpkin seeds, maple syrup.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — OATMEAL
-- ══════════════════════════════════════════

-- Erewhon Instant Oatmeal Variety Pack: 130 cal per packet (43g)
('erewhon_instant_oatmeal_variety', 'Erewhon Instant Oatmeal Variety Pack', 302.3, 11.6, 55.8, 4.7,
 7.0, 14.0, NULL, 43,
 'manufacturer', ARRAY['erewhon instant oatmeal', 'erewhon oatmeal variety pack', 'erewhon oatmeal packet', 'erewhon instant oatmeal variety'],
 'oatmeal', 'Erewhon', 1, '130 cal per packet (43g). Verified on MyNetDiary.', TRUE),

-- Erewhon Instant Oatmeal with Oat Bran: 130 cal per packet (43g)
('erewhon_instant_oatmeal_oat_bran', 'Erewhon Instant Oatmeal with Oat Bran', 302.3, 11.6, 53.5, 4.7,
 7.0, 11.6, NULL, 43,
 'manufacturer', ARRAY['erewhon oatmeal oat bran', 'erewhon instant oatmeal oat bran', 'erewhon oat bran oatmeal', 'erewhon oatmeal with bran'],
 'oatmeal', 'Erewhon', 1, '130 cal per packet (43g). Verified on MyNetDiary and EatThisMuch.', TRUE),

-- Erewhon Matcha Overnight Oats: 280 cal per serving (200g)
('erewhon_matcha_overnight_oats', 'Erewhon Matcha Overnight Oats', 140.0, 4.0, 21.0, 4.0,
 2.0, 7.0, 200, NULL,
 'research', ARRAY['erewhon matcha overnight oats', 'erewhon overnight oats', 'erewhon matcha oats', 'erewhon overnight oats matcha'],
 'oatmeal', 'Erewhon', 1, '280 cal per serving (200g). OpenFoodFacts listing exists.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — PACKAGED SNACKS
-- ══════════════════════════════════════════

-- Erewhon Keto Bread Snack Pack: 160 cal per slice (40g)
('erewhon_keto_bread', 'Erewhon Keto Bread Snack Pack', 400.0, 12.5, 5.0, 17.5,
 2.5, 0.0, NULL, 40,
 'manufacturer', ARRAY['erewhon keto bread', 'erewhon keto bread snack pack', 'erewhon low carb bread', 'erewhon keto snack bread'],
 'bread', 'Erewhon', 1, '160 cal per slice (40g). Verified on MyNetDiary.', TRUE),

-- Erewhon Hazelnut Oat Bar: 220 cal per bar (50g)
('erewhon_hazelnut_oat_bar', 'Erewhon Hazelnut Oat Bar', 440.0, 10.0, 52.0, 24.0,
 6.0, 20.0, NULL, 50,
 'research', ARRAY['erewhon hazelnut oat bar', 'erewhon oat bar', 'erewhon hazelnut bar', 'erewhon lions mane oat bar'],
 'snacks', 'Erewhon', 1, '220 cal per bar (50g). Hazelnut butter, oats, cocoa, lion''s mane, maca.', TRUE),

-- Erewhon Vanilla Plant Based Protein: 100 cal per 4 tbsp (30g)
('erewhon_vanilla_plant_protein', 'Erewhon Vanilla Plant Based Protein', 333.3, 66.7, 6.7, 5.0,
 0.0, 0.0, 30, NULL,
 'manufacturer', ARRAY['erewhon plant protein', 'erewhon vanilla protein powder', 'erewhon plant based protein', 'erewhon vanilla protein'],
 'protein_powder', 'Erewhon', 1, '100 cal per 4 tbsp (30g). 20g protein per serving. Verified on MyNetDiary.', TRUE),

-- Erewhon Beef Bone Stock: 153 cal per serving (240g)
('erewhon_beef_bone_stock', 'Erewhon Beef Bone Stock', 63.8, 5.4, 2.1, 4.2,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['erewhon beef bone stock', 'erewhon bone broth', 'erewhon beef broth', 'erewhon bone stock beef'],
 'soup', 'Erewhon', 1, '153 cal per serving (240g). Verified on MyNetDiary.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — DELI ITEMS
-- ══════════════════════════════════════════

-- Erewhon Turkey Club Sandwich: 520 cal per sandwich (300g)
('erewhon_turkey_club_sandwich', 'Erewhon Turkey Club Sandwich', 173.3, 10.7, 12.7, 8.0,
 1.0, 1.3, NULL, 300,
 'research', ARRAY['erewhon turkey club', 'erewhon turkey club sandwich', 'erewhon turkey sandwich', 'erewhon deli turkey club'],
 'sandwich', 'Erewhon', 1, '520 cal per sandwich (300g).', TRUE),

-- Erewhon Chicken Parm Sandwich: 580 cal per sandwich (320g)
('erewhon_chicken_parm_sandwich', 'Erewhon Chicken Parm Sandwich', 181.3, 10.6, 13.1, 8.8,
 0.9, 1.9, NULL, 320,
 'research', ARRAY['erewhon chicken parm sandwich', 'erewhon chicken parmesan sandwich', 'erewhon chicken parm', 'erewhon deli chicken parm'],
 'sandwich', 'Erewhon', 1, '580 cal per sandwich (320g).', TRUE),

-- Erewhon Chicken Pesto Sandwich: 540 cal per sandwich (300g)
('erewhon_chicken_pesto_sandwich', 'Erewhon Chicken Pesto Sandwich', 180.0, 10.0, 12.0, 9.3,
 0.7, 1.3, NULL, 300,
 'research', ARRAY['erewhon chicken pesto sandwich', 'erewhon pesto chicken sandwich', 'erewhon chicken pesto', 'erewhon deli chicken pesto'],
 'sandwich', 'Erewhon', 1, '540 cal per sandwich (300g).', TRUE),

-- Erewhon Asian Chicken Salad: 420 cal per container (350g)
('erewhon_asian_chicken_salad', 'Erewhon Asian Chicken Salad', 120.0, 8.0, 8.6, 5.7,
 1.1, 2.3, 350, NULL,
 'research', ARRAY['erewhon asian chicken salad', 'erewhon asian salad', 'erewhon chicken salad asian', 'erewhon packaged asian chicken salad'],
 'salad', 'Erewhon', 1, '420 cal per container (350g).', TRUE),

-- Erewhon Chicken Chop Salad: 460 cal per container (400g)
('erewhon_chicken_chop_salad', 'Erewhon Chicken Chop Salad', 115.0, 6.0, 6.5, 5.0,
 1.0, 1.5, 400, NULL,
 'manufacturer', ARRAY['erewhon chicken chop salad', 'erewhon chop salad', 'erewhon chopped salad chicken', 'erewhon deli chop salad'],
 'salad', 'Erewhon', 1, '460 cal per container (400g). Verified on MyNetDiary (575cal per 1.25 container).', TRUE),

-- Erewhon Keto Breakfast Sandwich: 380 cal per sandwich (200g)
('erewhon_keto_breakfast_sandwich', 'Erewhon Keto Breakfast Sandwich', 190.0, 11.0, 4.0, 15.0,
 1.0, 1.0, NULL, 200,
 'research', ARRAY['erewhon keto breakfast sandwich', 'erewhon keto sandwich', 'erewhon breakfast sandwich keto', 'erewhon low carb breakfast sandwich'],
 'sandwich', 'Erewhon', 1, '380 cal per sandwich (200g). Low-carb keto breakfast sandwich.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — DESSERTS
-- ══════════════════════════════════════════

-- Erewhon Coconut Soft Serve: 260 cal per cup (150g)
('erewhon_coconut_soft_serve', 'Erewhon Coconut Soft Serve', 173.3, 1.3, 21.3, 9.3,
 0.7, 16.0, 150, NULL,
 'research', ARRAY['erewhon coconut soft serve', 'erewhon soft serve', 'erewhon coconut ice cream', 'erewhon vegan soft serve'],
 'dessert', 'Erewhon', 1, '260 cal per cup (150g). Coconut-based soft serve.', TRUE),

-- Erewhon Raw Chocolate Mousse: 320 cal per serving (150g)
('erewhon_raw_chocolate_mousse', 'Erewhon Raw Chocolate Mousse', 213.3, 2.7, 18.7, 16.0,
 4.0, 10.7, 150, NULL,
 'research', ARRAY['erewhon raw chocolate mousse', 'erewhon chocolate mousse', 'erewhon avocado mousse', 'erewhon raw mousse'],
 'dessert', 'Erewhon', 1, '320 cal per serving (150g). Avocado, cacao, coconut oil, maple syrup.', TRUE),

-- Erewhon Chia Pudding: 280 cal per serving (200g)
('erewhon_chia_pudding', 'Erewhon Chia Pudding', 140.0, 3.0, 16.0, 7.0,
 5.0, 6.0, 200, NULL,
 'research', ARRAY['erewhon chia pudding', 'erewhon chia seed pudding', 'erewhon chia parfait', 'erewhon chia dessert'],
 'dessert', 'Erewhon', 1, '280 cal per serving (200g). Chia seed pudding.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — MEAT & SEAFOOD (VERIFIED)
-- ══════════════════════════════════════════

-- Erewhon Organic Ribeye Steak: 462 cal per 8oz (227g)
('erewhon_organic_ribeye_steak', 'Erewhon Organic Ribeye Steak', 203.5, 29.1, 0.0, 8.8,
 0.0, 0.0, 227, NULL,
 'manufacturer', ARRAY['erewhon organic ribeye', 'erewhon ribeye steak', 'erewhon organic ribeye steak', 'erewhon grass fed ribeye'],
 'meat', 'Erewhon', 1, '462 cal per 8oz (227g). Verified on MyNetDiary.', TRUE),

-- Erewhon 100% Grass-Fed Wagyu Ribeye: 462 cal per 10oz (284g)
('erewhon_wagyu_ribeye', 'Erewhon 100% Grass-Fed Wagyu Ribeye', 162.7, 19.4, 0.0, 8.8,
 0.0, 0.0, 284, NULL,
 'manufacturer', ARRAY['erewhon wagyu ribeye', 'erewhon wagyu steak', 'erewhon grass fed wagyu ribeye', 'erewhon wagyu beef ribeye'],
 'meat', 'Erewhon', 1, '462 cal per 10oz (284g). Verified on MyNetDiary.', TRUE),

-- Erewhon 100% Grass-Fed Wagyu Ground Beef: 412 cal per 4oz (113g)
('erewhon_wagyu_ground_beef', 'Erewhon 100% Grass-Fed Wagyu Ground Beef', 364.6, 26.5, 0.0, 28.3,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['erewhon wagyu ground beef', 'erewhon wagyu beef ground', 'erewhon grass fed ground beef', 'erewhon wagyu burger meat'],
 'meat', 'Erewhon', 1, '412 cal per 4oz (113g). Verified on MyNetDiary (206cal/2oz).', TRUE),

-- Erewhon Organic Ground Beef 93/7: 240 cal per 4oz (113g)
('erewhon_organic_ground_beef_93_7', 'Erewhon Organic Ground Beef 93/7', 212.4, 18.6, 0.0, 15.0,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['erewhon organic ground beef', 'erewhon ground beef 93/7', 'erewhon lean ground beef', 'erewhon organic lean beef'],
 'meat', 'Erewhon', 1, '240 cal per 4oz (113g). Verified on Nutritionix and EatThisMuch.', TRUE),

-- Erewhon 100% Fresh Sustainable Salmon: 349 cal per 6oz (170g)
('erewhon_sustainable_salmon', 'Erewhon 100% Fresh Sustainable Salmon', 205.3, 20.6, 0.0, 14.1,
 0.0, 0.0, 170, NULL,
 'manufacturer', ARRAY['erewhon salmon', 'erewhon sustainable salmon', 'erewhon fresh salmon', 'erewhon wild salmon fillet'],
 'seafood', 'Erewhon', 1, '349 cal per 6oz (170g). Verified on MyNetDiary.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — TONIC BAR DRINKS
-- ══════════════════════════════════════════

-- Erewhon Kombucha (House, 16oz): 60 cal per 16oz (480g)
('erewhon_kombucha', 'Erewhon Kombucha (House)', 12.5, 0.0, 2.9, 0.0,
 0.0, 2.1, NULL, 480,
 'research', ARRAY['erewhon kombucha', 'erewhon house kombucha', 'erewhon organic kombucha', 'erewhon tonic bar kombucha'],
 'beverage', 'Erewhon', 1, '60 cal per 16oz bottle (480g). House kombucha.', TRUE),

-- Erewhon Adaptogenic Latte (Tonic Bar, 12oz): 170 cal per 12oz (360g)
('erewhon_tonic_bar_adaptogenic_latte', 'Erewhon Adaptogenic Latte (Tonic Bar)', 47.2, 0.8, 5.6, 2.2,
 0.3, 2.2, 360, NULL,
 'research', ARRAY['erewhon tonic bar adaptogenic latte', 'erewhon tonic adaptogenic latte', 'erewhon tonic bar reishi latte', 'erewhon tonic mushroom latte'],
 'beverage', 'Erewhon', 1, '170 cal per 12oz (360g). Reishi, ashwagandha, lion''s mane.', TRUE),

-- Erewhon Matcha (Tonic Bar, 12oz): 200 cal per 12oz (360g)
('erewhon_tonic_bar_matcha', 'Erewhon Matcha (Tonic Bar)', 55.6, 1.1, 7.8, 1.9,
 0.3, 3.9, 360, NULL,
 'research', ARRAY['erewhon tonic bar matcha', 'erewhon tonic matcha', 'erewhon tonic bar matcha latte', 'erewhon matcha tonic'],
 'beverage', 'Erewhon', 1, '200 cal per 12oz (360g). Tonic bar matcha.', TRUE),

-- Erewhon Shroom Tonic: 80 cal per 8oz (240g)
('erewhon_shroom_tonic', 'Erewhon Shroom Tonic', 33.3, 0.8, 5.0, 1.3,
 0.4, 2.5, 240, NULL,
 'research', ARRAY['erewhon shroom tonic', 'erewhon mushroom tonic', 'erewhon shroom drink', 'erewhon tonic bar shroom'],
 'beverage', 'Erewhon', 1, '80 cal per 8oz (240g). Mushroom-based tonic.', TRUE),

-- ══════════════════════════════════════════
-- EREWHON — KETO PIZZA
-- ══════════════════════════════════════════

-- Erewhon Keto BBQ Chicken Pizza: 280 cal per slice (120g)
('erewhon_keto_bbq_chicken_pizza', 'Erewhon Keto BBQ Chicken Pizza', 233.3, 15.0, 6.7, 16.7,
 1.7, 2.5, NULL, 120,
 'research', ARRAY['erewhon keto bbq chicken pizza', 'erewhon keto pizza bbq', 'erewhon bbq chicken pizza keto', 'erewhon low carb pizza bbq'],
 'pizza', 'Erewhon', 1, '280 cal per slice (120g). Keto-friendly BBQ chicken pizza. OpenFoodFacts listing exists.', TRUE),

-- Erewhon Keto Spicy Pepperoni Pizza: 300 cal per slice (120g)
('erewhon_keto_spicy_pepperoni_pizza', 'Erewhon Keto Spicy Pepperoni Pizza', 250.0, 13.3, 5.0, 20.0,
 0.8, 1.7, NULL, 120,
 'research', ARRAY['erewhon keto spicy pepperoni pizza', 'erewhon keto pizza pepperoni', 'erewhon spicy pepperoni pizza keto', 'erewhon low carb pepperoni pizza'],
 'pizza', 'Erewhon', 1, '300 cal per slice (120g). Keto-friendly spicy pepperoni pizza.', TRUE)

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
