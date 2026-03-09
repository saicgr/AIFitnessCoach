-- 1626_overrides_exotic_meat_brands_bone_broth_superfoods.sql
-- Force of Nature exotic meats, EPIC bars/broth/rinds, Kettle & Fire bone broth,
-- Navitas Organics superfoods, Bob's Red Mill, Sunfood, sea moss brands.
-- Sources: Package nutrition labels via fatsecret.com, nutritionix.com,
-- eatthismuch.com, nutritionvalue.org, manufacturer websites.
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
-- FORCE OF NATURE — EXOTIC GROUND MEATS
-- ══════════════════════════════════════════

-- Force of Nature Ancestral Blend Ground Beef: 200 cal per 4oz (112g)
('fon_ancestral_blend_ground_beef', 'Force of Nature Ancestral Blend Ground Beef', 179, 19.6, 0.0, 9.8,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['force of nature ancestral blend', 'force of nature ancestral blend ground beef', 'fon ancestral blend beef', 'ancestral blend ground beef liver heart'],
 'exotic_meat', 'Force of Nature', 1, '200 cal per 4oz (112g). 100% grass-fed beef with beef liver and heart. Rich in vitamin A and iron.', TRUE),

-- Force of Nature Ground Bison: 150 cal per 4oz (112g)
('fon_ground_bison', 'Force of Nature Ground Bison', 134, 21.4, 0.0, 6.3,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['force of nature ground bison', 'force of nature bison', 'fon ground bison', 'grass fed ground bison'],
 'exotic_meat', 'Force of Nature', 1, '150 cal per 4oz (112g). 100% grass-fed ground bison. Very lean, high protein.', TRUE),

-- Force of Nature Ground Venison: 140 cal per 4oz (112g)
('fon_ground_venison', 'Force of Nature Ground Venison', 125, 23.2, 0.0, 2.7,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['force of nature ground venison', 'force of nature venison', 'fon ground venison', 'grass fed ground venison'],
 'exotic_meat', 'Force of Nature', 1, '140 cal per 4oz (112g). 100% grass-fed ground venison. Ultra-lean with 26g protein per serving.', TRUE),

-- Force of Nature Ground Elk: 200 cal per 4oz (112g)
('fon_ground_elk', 'Force of Nature Ground Elk', 179, 22.3, 0.0, 8.9,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['force of nature ground elk', 'force of nature elk', 'fon ground elk', 'grass fed ground elk'],
 'exotic_meat', 'Force of Nature', 1, '200 cal per 4oz (112g). 100% grass-fed ground elk. Lean game meat, high in iron.', TRUE),

-- Force of Nature Wild Boar Ground: 230 cal per 4oz (112g)
('fon_wild_boar_ground', 'Force of Nature Wild Boar Ground', 205, 18.8, 1.8, 13.4,
 0.9, 0.0, 113, NULL,
 'manufacturer', ARRAY['force of nature wild boar', 'force of nature ground wild boar', 'fon wild boar', 'wild boar ground meat'],
 'exotic_meat', 'Force of Nature', 1, '230 cal per 4oz (112g). 100% wild-caught ground boar. Leaner and more flavorful than farmed pork.', TRUE),

-- Force of Nature Ancestral Blend Bison: 190 cal per 4oz (112g)
('fon_ancestral_blend_bison', 'Force of Nature Ancestral Blend Bison', 170, 19.6, 0.0, 9.8,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['force of nature ancestral blend bison', 'fon ancestral bison', 'bison ancestral blend liver heart', 'force of nature bison ancestral'],
 'exotic_meat', 'Force of Nature', 1, '190 cal per 4oz (112g). 100% grass-fed bison with bison liver and heart. Organ meat superfood blend.', TRUE),

-- ══════════════════════════════════════════
-- EPIC — PROTEIN BARS
-- ══════════════════════════════════════════

-- EPIC Bison Bacon Cranberry Bar: 120 cal per bar (37g)
('epic_bison_bacon_cranberry_bar', 'EPIC Bison Bacon Cranberry Bar', 324, 18.9, 21.6, 18.9,
 5.4, 16.2, NULL, 37,
 'manufacturer', ARRAY['epic bison bar', 'epic bison bacon cranberry', 'epic bison bacon cranberry bar', 'epic bar bison'],
 'protein_bar', 'EPIC', 1, '120 cal per bar (37g). 100% grass-fed bison with uncured bacon and cranberries. 7g protein per bar.', TRUE),

-- EPIC Venison Sea Salt Bar: 130 cal per bar (37g)
('epic_venison_sea_salt_bar', 'EPIC Venison Sea Salt & Pepper Bar', 351, 32.4, 2.7, 24.3,
 0.0, 0.0, NULL, 37,
 'manufacturer', ARRAY['epic venison bar', 'epic venison sea salt pepper', 'epic venison sea salt bar', 'epic bar venison'],
 'protein_bar', 'EPIC', 1, '130 cal per bar (37g). 100% grass-fed venison with sea salt and pepper. 12g protein, keto-friendly.', TRUE),

-- EPIC Chicken Sriracha Bar: 100 cal per bar (37g)
('epic_chicken_sriracha_bar', 'EPIC Chicken Sriracha Bar', 270, 29.7, 8.1, 13.5,
 5.4, 0.0, NULL, 37,
 'manufacturer', ARRAY['epic chicken bar', 'epic chicken sriracha', 'epic chicken sriracha bar', 'epic bar chicken'],
 'protein_bar', 'EPIC', 1, '100 cal per bar (37g). Chicken with sriracha seasoning. 11g protein, 2g net carbs, keto-friendly.', TRUE),

-- EPIC Beef Apple Bacon Bar: 140 cal per bar (37g)
('epic_beef_apple_bacon_bar', 'EPIC Beef Apple Bacon Bar', 378, 21.6, 13.5, 27.0,
 2.7, 8.1, NULL, 37,
 'manufacturer', ARRAY['epic beef bar', 'epic beef apple bacon', 'epic beef apple bacon bar', 'epic bar beef'],
 'protein_bar', 'EPIC', 1, '140 cal per bar (37g). 100% grass-fed beef with uncured bacon and dried apples. 8g protein per bar.', TRUE),

-- ══════════════════════════════════════════
-- EPIC — BONE BROTH
-- ══════════════════════════════════════════

-- EPIC Bison Bone Broth: 50 cal per jar (414g)
('epic_bison_bone_broth', 'EPIC Bison Bone Broth', 12, 2.4, 0.5, 0.0,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['epic bison broth', 'epic bison bone broth', 'epic provisions bison broth', 'epic bone broth bison'],
 'bone_broth', 'EPIC', 1, '50 cal per jar (414g). Slow-simmered grass-fed bison bones. Rich in collagen and protein.', TRUE),

-- EPIC Beef Jalapeno Bone Broth: 45 cal per jar (414g)
('epic_beef_jalapeno_bone_broth', 'EPIC Beef Jalapeno Sea Salt Bone Broth', 11, 2.2, 0.5, 0.0,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['epic beef jalapeno broth', 'epic beef jalapeno bone broth', 'epic jalapeno bone broth', 'epic bone broth beef jalapeno'],
 'bone_broth', 'EPIC', 1, '45 cal per jar (414g). Grass-fed beef bones with jalapeno peppers and sea salt. 9g protein per jar.', TRUE),

-- ══════════════════════════════════════════
-- EPIC — PORK RINDS
-- ══════════════════════════════════════════

-- EPIC BBQ Pork Rinds: 80 cal per 1/2 oz (14g)
('epic_pork_rinds_bbq', 'EPIC BBQ Pork Rinds', 571, 64.3, 7.1, 35.7,
 0.0, 0.0, 14, NULL,
 'manufacturer', ARRAY['epic bbq pork rinds', 'epic pork rinds bbq', 'epic bbq seasoning pork rinds', 'epic provisions pork rinds bbq'],
 'snack', 'EPIC', 1, '80 cal per 1/2 oz (14g). Pork skins fried in pork fat with BBQ seasoning. Zero carb, high protein snack.', TRUE),

-- EPIC Sea Salt & Pepper Pork Rinds: 80 cal per 1/2 oz (14g)
('epic_pork_rinds_sea_salt_pepper', 'EPIC Sea Salt & Pepper Pork Rinds', 571, 64.3, 0.0, 35.7,
 0.0, 0.0, 14, NULL,
 'manufacturer', ARRAY['epic sea salt pepper pork rinds', 'epic pork rinds sea salt', 'epic pork rinds salt pepper', 'epic provisions pork rinds'],
 'snack', 'EPIC', 1, '80 cal per 1/2 oz (14g). Pork skins with sea salt and black pepper. Zero carb, high protein snack.', TRUE),

-- ══════════════════════════════════════════
-- KETTLE & FIRE — BONE BROTH
-- ══════════════════════════════════════════

-- Kettle & Fire Beef Bone Broth: 40 cal per cup (240ml ~240g)
('kettlefire_beef_bone_broth', 'Kettle & Fire Beef Bone Broth', 17, 4.2, 0.8, 0.0,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['kettle and fire beef bone broth', 'kettle fire beef broth', 'kettle & fire beef bone broth', 'kettle fire beef'],
 'bone_broth', 'Kettle & Fire', 1, '40 cal per cup (240ml). 100% grass-fed beef bones. 10g protein, 8g collagen per serving.', TRUE),

-- Kettle & Fire Chicken Bone Broth: 45 cal per cup (240ml ~240g)
('kettlefire_chicken_bone_broth', 'Kettle & Fire Chicken Bone Broth', 19, 4.2, 0.0, 0.2,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['kettle and fire chicken bone broth', 'kettle fire chicken broth', 'kettle & fire chicken bone broth', 'kettle fire chicken'],
 'bone_broth', 'Kettle & Fire', 1, '45 cal per cup (240ml). Organic free-range chicken bones. 10g protein, 4g collagen per serving.', TRUE),

-- Kettle & Fire Mushroom Chicken Bone Broth: 50 cal per cup (240ml ~240g)
('kettlefire_mushroom_chicken_bone_broth', 'Kettle & Fire Mushroom Chicken Bone Broth', 21, 4.2, 0.8, 0.2,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['kettle and fire mushroom chicken broth', 'kettle fire mushroom chicken', 'kettle & fire mushroom chicken bone broth', 'kettle fire mushroom broth'],
 'bone_broth', 'Kettle & Fire', 1, '50 cal per cup (240ml). Chicken bone broth with lion''s mane mushroom. 10g protein, 6g collagen per serving.', TRUE),

-- Kettle & Fire Tom Yum Chicken Bone Broth: 50 cal per cup (240ml ~240g)
('kettlefire_tom_yum_bone_broth', 'Kettle & Fire Tom Yum Chicken Bone Broth', 21, 2.5, 1.7, 0.8,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['kettle and fire tom yum', 'kettle fire tom yum bone broth', 'kettle & fire tom yum chicken', 'kettle fire tom yum'],
 'bone_broth', 'Kettle & Fire', 1, '50 cal per cup (240ml). Thai-inspired tom yum with organic chicken bones, coconut milk, ginger, lemongrass.', TRUE),

-- Kettle & Fire Turmeric Ginger Chicken Bone Broth: 50 cal per cup (240ml ~240g)
('kettlefire_turmeric_ginger_bone_broth', 'Kettle & Fire Turmeric Ginger Chicken Bone Broth', 21, 4.6, 0.8, 0.2,
 0.0, 0.0, 240, NULL,
 'manufacturer', ARRAY['kettle and fire turmeric ginger', 'kettle fire turmeric ginger bone broth', 'kettle & fire turmeric ginger chicken', 'kettle fire turmeric broth'],
 'bone_broth', 'Kettle & Fire', 1, '50 cal per cup (240ml). Chicken bone broth with turmeric and ginger extracts. 11g protein, 6g collagen per serving.', TRUE),

-- ══════════════════════════════════════════
-- NAVITAS ORGANICS — SUPERFOODS
-- ══════════════════════════════════════════

-- Navitas Organics Maca Powder: 20 cal per tsp (5g)
('navitas_maca_powder', 'Navitas Organics Maca Powder', 400, 20.0, 80.0, 0.0,
 0.0, 0.0, 5, NULL,
 'manufacturer', ARRAY['navitas maca powder', 'navitas organics maca', 'navitas maca', 'organic maca powder navitas'],
 'superfood', 'Navitas Organics', 1, '20 cal per tsp (5g). Organic gelatinized Peruvian maca root powder. Adaptogen for energy and balance.', TRUE),

-- Navitas Organics Cacao Powder: 60 cal per 2.5 tbsp (15g)
('navitas_cacao_powder', 'Navitas Organics Cacao Powder', 400, 26.7, 53.3, 10.0,
 0.0, 0.0, 5, NULL,
 'manufacturer', ARRAY['navitas cacao powder', 'navitas organics cacao powder', 'navitas organic cacao', 'organic raw cacao powder navitas'],
 'superfood', 'Navitas Organics', 1, '60 cal per 2.5 tbsp (15g). Unsweetened organic cacao powder. Rich in antioxidants, magnesium, 20mg caffeine per tbsp.', TRUE),

-- Navitas Organics Cacao Nibs: 130 cal per 3 tbsp (28g)
('navitas_cacao_nibs', 'Navitas Organics Cacao Nibs', 464, 14.3, 35.7, 35.7,
 28.6, 0.0, 15, NULL,
 'manufacturer', ARRAY['navitas cacao nibs', 'navitas organics cacao nibs', 'navitas organic cacao nibs', 'raw cacao nibs navitas'],
 'superfood', 'Navitas Organics', 1, '130 cal per 3 tbsp (28g). Unsweetened organic raw cacao nibs. Rich in fiber, antioxidants, and flavanols.', TRUE),

-- Navitas Organics Acai Powder: 20 cal per 1.5 tsp (3g)
('navitas_acai_powder', 'Navitas Organics Acai Powder', 667, 0.0, 33.3, 50.0,
 0.0, 0.0, 8, NULL,
 'manufacturer', ARRAY['navitas acai powder', 'navitas organics acai', 'navitas acai', 'organic acai powder navitas'],
 'superfood', 'Navitas Organics', 1, '20 cal per 1.5 tsp (3g). Freeze-dried organic acai berry powder. Rich in antioxidants and omega fatty acids.', TRUE),

-- Navitas Organics Hemp Seeds: 90 cal per 3 tbsp (30g)
('navitas_hemp_seeds', 'Navitas Organics Hemp Seeds', 600, 33.3, 6.7, 46.7,
 0.0, 0.0, 15, NULL,
 'manufacturer', ARRAY['navitas hemp seeds', 'navitas organics hemp seeds', 'navitas organic hemp', 'organic hemp seeds navitas'],
 'superfood', 'Navitas Organics', 1, '90 cal per 3 tbsp (30g). Organic hulled hemp seeds. Rich in omega-3 and omega-6 fatty acids, complete protein.', TRUE),

-- Navitas Organics Chia Seeds: 70 cal per 2 tbsp (14g)
('navitas_chia_seeds', 'Navitas Organics Chia Seeds', 500, 21.4, 35.7, 28.6,
 35.7, 0.0, 14, NULL,
 'manufacturer', ARRAY['navitas chia seeds', 'navitas organics chia seeds', 'navitas organic chia', 'organic chia seeds navitas'],
 'superfood', 'Navitas Organics', 1, '70 cal per 2 tbsp (14g). Organic chia seeds. Rich in omega-3 fatty acids and fiber.', TRUE),

-- ══════════════════════════════════════════
-- BOB''S RED MILL — SUPERFOODS & GRAINS
-- ══════════════════════════════════════════

-- Bob's Red Mill Ground Flaxseed: 60 cal per 2 tbsp (13g)
('bobs_ground_flaxseed', 'Bob''s Red Mill Ground Flaxseed Meal', 462, 23.1, 23.1, 26.9,
 23.1, 0.0, 13, NULL,
 'manufacturer', ARRAY['bobs red mill flaxseed', 'bobs red mill ground flaxseed', 'bob''s red mill flaxseed meal', 'bobs flaxseed meal'],
 'superfood', 'Bob''s Red Mill', 1, '60 cal per 2 tbsp (13g). Premium whole ground flaxseed meal. Rich in omega-3 ALA, fiber, and lignans.', TRUE),

-- Bob's Red Mill Steel Cut Oats: 170 cal per 1/4 cup dry (40g)
('bobs_steel_cut_oats', 'Bob''s Red Mill Steel Cut Oats', 375, 12.5, 67.5, 6.3,
 5.0, 0.0, 40, NULL,
 'manufacturer', ARRAY['bobs red mill steel cut oats', 'bobs steel cut oats', 'bob''s red mill steel cut oats', 'bobs oats steel cut'],
 'grain', 'Bob''s Red Mill', 1, '170 cal per 1/4 cup dry (40g). Whole grain steel cut oats. Good source of fiber and protein. 68% carbs, 16% protein.', TRUE),

-- Bob's Red Mill Nutritional Yeast: 60 cal per 1/4 cup (16g)
('bobs_nutritional_yeast', 'Bob''s Red Mill Nutritional Yeast', 375, 50.0, 31.3, 3.1,
 12.5, 0.0, 5, NULL,
 'manufacturer', ARRAY['bobs red mill nutritional yeast', 'bobs nutritional yeast', 'bob''s red mill nutritional yeast', 'bobs red mill nooch'],
 'superfood', 'Bob''s Red Mill', 1, '60 cal per 1/4 cup (16g). Large flake nutritional yeast. Excellent source of B-vitamins including B12. Vegan, gluten-free.', TRUE),

-- Bob's Red Mill Organic Chia Seeds: 65 cal per 1 tbsp (10g)
('bobs_organic_chia_seeds', 'Bob''s Red Mill Organic Chia Seeds', 464, 21.4, 35.7, 28.6,
 35.7, 0.0, 14, NULL,
 'manufacturer', ARRAY['bobs red mill chia seeds', 'bobs chia seeds', 'bob''s red mill chia', 'bobs organic chia seeds'],
 'superfood', 'Bob''s Red Mill', 1, '65 cal per tbsp (10g). Organic whole chia seeds. Rich in omega-3 fatty acids, fiber, and calcium. Gluten-free.', TRUE),

-- ══════════════════════════════════════════
-- SUNFOOD — SUPERFOODS
-- ══════════════════════════════════════════

-- Sunfood Maca Powder: 30 cal per tbsp (8g)
('sunfood_maca_powder', 'Sunfood Raw Organic Maca Powder', 375, 12.5, 75.0, 0.0,
 0.0, 0.0, 5, NULL,
 'manufacturer', ARRAY['sunfood maca powder', 'sunfood superfoods maca', 'sunfood organic maca', 'sunfood raw maca powder'],
 'superfood', 'Sunfood', 1, '30 cal per tbsp (8g). Raw organic Peruvian maca root powder. Adaptogenic superfood for energy and hormone balance.', TRUE),

-- Sunfood Chlorella Tablets: 12 cal per 12 tablets (3g)
('sunfood_chlorella_tablets', 'Sunfood Spirulina & Chlorella Tablets', 400, 66.7, 0.0, 0.0,
 0.0, 0.0, 3, NULL,
 'manufacturer', ARRAY['sunfood chlorella tablets', 'sunfood spirulina chlorella', 'sunfood superfoods chlorella', 'sunfood algae tablets'],
 'superfood', 'Sunfood', 1, '12 cal per 12 tablets (3g). 50/50 blend of spirulina and chlorella. Rich in protein, vitamins B1, B2, B6, B12.', TRUE),

-- Sunfood Spirulina Powder: 20 cal per tsp (5g)
('sunfood_spirulina_powder', 'Sunfood Organic Spirulina Powder', 290, 57.0, 24.0, 8.0,
 4.0, 3.0, 5, NULL,
 'manufacturer', ARRAY['sunfood spirulina powder', 'sunfood superfoods spirulina', 'sunfood organic spirulina', 'sunfood spirulina'],
 'superfood', 'Sunfood', 1, '20 cal per tsp (5g). Organic spirulina powder. Complete protein source with all essential amino acids.', TRUE),

-- ══════════════════════════════════════════
-- SEA MOSS — SPECIALTY BRANDS
-- ══════════════════════════════════════════

-- TrueSeaMoss Sea Moss Gel: 14 cal per tbsp (25g)
('trueseamoss_sea_moss_gel', 'TrueSeaMoss Wildcrafted Sea Moss Gel', 56, 0.4, 24.0, 0.0,
 4.0, 0.0, 15, NULL,
 'manufacturer', ARRAY['trueseamoss gel', 'true sea moss gel', 'trueseamoss sea moss gel', 'wildcrafted sea moss gel'],
 'superfood', 'TrueSeaMoss', 1, '14 cal per tbsp (25g). Wildcrafted sea moss gel. Rich in minerals: iodine, calcium, magnesium, potassium. 92 minerals.', TRUE),

-- Maju Sea Moss Capsules: ~5 cal per 2 capsules (1g)
('maju_sea_moss_capsules', 'Maju 4-in-1 Sea Moss Capsules', 500, 10.0, 90.0, 0.0,
 0.0, 0.0, 1, NULL,
 'manufacturer', ARRAY['maju sea moss capsules', 'maju sea moss', 'maju superfoods sea moss', 'maju 4 in 1 sea moss'],
 'superfood', 'Maju', 1, '~5 cal per 2 capsules (1g). Sea moss with bladderwrack, burdock root, and black pepper. 60 capsules per bottle.', TRUE),

-- Alkaline Herb Shop Sea Moss Blend: 5 cal per 3 capsules (~2g)
('ahs_sea_moss_blend', 'Alkaline Herb Shop Sea Moss & Bladderwrack', 250, 5.0, 50.0, 0.0,
 0.0, 0.0, 2, NULL,
 'manufacturer', ARRAY['alkaline herb shop sea moss', 'ahs sea moss', 'alkaline herb shop sea moss bladderwrack', 'alkaline herb shop blend'],
 'superfood', 'Alkaline Herb Shop', 1, '5 cal per 3 capsules (~2g). Wildcrafted Irish sea moss and bladderwrack. Natural source of iodine, calcium, magnesium.', TRUE)

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
