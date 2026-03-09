-- 1640_overrides_trending_chains.sql
-- Trending restaurant chains: Dave's Hot Chicken, Buc-ee's, Slim Chickens.
-- Sources: fastfoodnutrition.org, nutritionix.com, fatsecret.com, calorieking.com,
-- restaurant websites.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = typical portion.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- DAVE'S HOT CHICKEN — TENDERS
-- Tenders vary by spice level. ~180-195 cal/100g per piece (~100g each).
-- ══════════════════════════════════════════

-- Dave's Tender No Spice (1pc): ~180 cal per 100g piece
('daves_tender_no_spice_1pc', 'Dave''s Hot Chicken Tender No Spice (1pc)', 180, 22.0, 10.0, 5.0,
 0.5, 0.5, NULL, 100,
 'website', ARRAY['daves hot chicken tender no spice', 'daves tender no spice', 'dave hot chicken tender plain', 'daves hot chicken tender 1pc'],
 'chicken', 'Dave''s Hot Chicken', 1, '180 cal per tender (~100g). Crispy chicken tender, no spice. 22g protein.', TRUE),

-- Dave's Tender Mild (1pc): ~185 cal per 100g piece
('daves_tender_mild_1pc', 'Dave''s Hot Chicken Tender Mild (1pc)', 185, 22.0, 10.0, 5.5,
 0.5, 0.5, NULL, 100,
 'website', ARRAY['daves hot chicken tender mild', 'daves tender mild', 'dave hot chicken tender mild', 'daves hot chicken tender mild 1pc'],
 'chicken', 'Dave''s Hot Chicken', 1, '185 cal per tender (~100g). Crispy chicken tender, mild spice. 22g protein.', TRUE),

-- Dave's Tender Hot (1pc): ~190 cal per 100g piece
('daves_tender_hot_1pc', 'Dave''s Hot Chicken Tender Hot (1pc)', 190, 22.0, 10.0, 6.0,
 0.5, 0.5, NULL, 100,
 'website', ARRAY['daves hot chicken tender hot', 'daves tender hot', 'dave hot chicken tender hot', 'daves hot chicken tender hot 1pc'],
 'chicken', 'Dave''s Hot Chicken', 1, '190 cal per tender (~100g). Crispy chicken tender, hot spice. 22g protein.', TRUE),

-- Dave's Tender Reaper (1pc): ~195 cal per 100g piece
('daves_tender_reaper_1pc', 'Dave''s Hot Chicken Tender Reaper (1pc)', 195, 22.0, 10.0, 6.5,
 0.5, 0.5, NULL, 100,
 'website', ARRAY['daves hot chicken tender reaper', 'daves tender reaper', 'dave hot chicken tender reaper', 'daves hot chicken reaper tender'],
 'chicken', 'Dave''s Hot Chicken', 1, '195 cal per tender (~100g). Crispy chicken tender, reaper spice (hottest). 22g protein.', TRUE),

-- Dave's Tenders 2pc No Spice: same per-100g, serving 200g, count 2
('daves_tenders_2pc_no_spice', 'Dave''s Hot Chicken Tenders 2pc No Spice', 180, 22.0, 10.0, 5.0,
 0.5, 0.5, 200, NULL,
 'website', ARRAY['daves hot chicken tenders 2pc', 'daves tenders 2 piece no spice', 'dave hot chicken 2pc tender', 'daves hot chicken tenders 2pc no spice'],
 'chicken', 'Dave''s Hot Chicken', 2, '360 cal total for 2 tenders (200g). Same as No Spice tender x2. 44g protein total.', TRUE),

-- ══════════════════════════════════════════
-- DAVE'S HOT CHICKEN — SLIDERS
-- ══════════════════════════════════════════

-- Dave's Slider Regular: ~320 cal per ~130g slider
-- per 100g: ~246 cal
('daves_slider_regular', 'Dave''s Hot Chicken Slider Regular', 246, 15.4, 20.0, 11.5,
 1.5, 3.1, NULL, 130,
 'website', ARRAY['daves hot chicken slider', 'daves slider', 'daves hot chicken slider regular', 'dave hot chicken slider plain'],
 'sandwich', 'Dave''s Hot Chicken', 1, '320 cal per slider (~130g). Crispy chicken slider on a bun with pickles and Dave''s sauce. 20g protein.', TRUE),

-- Dave's Slider Spicy: ~330 cal per ~130g slider
-- per 100g: ~254 cal
('daves_slider_spicy', 'Dave''s Hot Chicken Slider Spicy', 254, 15.4, 20.0, 12.3,
 1.5, 3.1, NULL, 130,
 'website', ARRAY['daves hot chicken slider spicy', 'daves slider spicy', 'daves hot chicken spicy slider', 'dave hot chicken slider hot'],
 'sandwich', 'Dave''s Hot Chicken', 1, '330 cal per slider (~130g). Spicy crispy chicken slider on a bun with pickles. 20g protein.', TRUE),

-- ══════════════════════════════════════════
-- DAVE'S HOT CHICKEN — SIDES
-- ══════════════════════════════════════════

-- Dave's Regular Fries: ~437 cal per serving (~140g)
-- per 100g: ~312 cal
('daves_fries_regular', 'Dave''s Hot Chicken Fries (Regular)', 312, 3.6, 39.3, 15.7,
 2.9, 0.7, 140, NULL,
 'website', ARRAY['daves hot chicken fries', 'daves fries', 'daves hot chicken regular fries', 'dave hot chicken fries'],
 'side', 'Dave''s Hot Chicken', 1, '437 cal per regular fries (~140g). Crispy seasoned french fries. 5g protein.', TRUE),

-- Dave's Loaded Fries: ~725 cal per serving (~250g)
-- per 100g: ~290 cal
('daves_loaded_fries', 'Dave''s Hot Chicken Loaded Fries', 290, 8.0, 28.0, 16.0,
 2.0, 2.0, 250, NULL,
 'website', ARRAY['daves hot chicken loaded fries', 'daves loaded fries', 'daves hot chicken fries loaded', 'dave hot chicken loaded fries'],
 'side', 'Dave''s Hot Chicken', 1, '725 cal per loaded fries (~250g). Fries topped with cheese, chicken bits, sauce. 20g protein.', TRUE),

-- Dave's Mac & Cheese: ~306 cal per serving (~170g)
-- per 100g: ~180 cal
('daves_mac_cheese', 'Dave''s Hot Chicken Mac & Cheese', 180, 7.1, 17.6, 9.4,
 0.6, 2.4, 170, NULL,
 'website', ARRAY['daves hot chicken mac and cheese', 'daves mac cheese', 'daves hot chicken mac cheese', 'dave hot chicken mac and cheese'],
 'side', 'Dave''s Hot Chicken', 1, '306 cal per serving (~170g). Creamy macaroni and cheese. 12g protein.', TRUE),

-- Dave's Kale Slaw: ~96 cal per serving (~120g)
-- per 100g: ~80 cal
('daves_kale_slaw', 'Dave''s Hot Chicken Kale Slaw', 80, 2.5, 8.3, 4.2,
 2.5, 5.0, 120, NULL,
 'website', ARRAY['daves hot chicken kale slaw', 'daves kale slaw', 'daves hot chicken slaw', 'dave hot chicken coleslaw'],
 'side', 'Dave''s Hot Chicken', 1, '96 cal per serving (~120g). Fresh kale slaw with tangy dressing. 3g protein.', TRUE),

-- ══════════════════════════════════════════
-- BUC-EE'S — SANDWICHES
-- ══════════════════════════════════════════

-- Buc-ee's Brisket Sandwich: ~750 cal per sandwich (~250g)
-- per 100g: ~300 cal
('bucees_brisket_sandwich', 'Buc-ee''s Brisket Sandwich', 300, 16.0, 20.0, 16.8,
 1.2, 4.0, NULL, 250,
 'website', ARRAY['buc-ees brisket sandwich', 'bucees brisket sandwich', 'buc ees brisket', 'buc-ee brisket sandwich', 'buc-ees chopped brisket sandwich'],
 'sandwich', 'Buc-ee''s', 1, '750 cal per sandwich (~250g). Slow-smoked Texas brisket on a bun. 40g protein.', TRUE),

-- Buc-ee's Pulled Pork Sandwich: ~624 cal per sandwich (~240g)
-- per 100g: ~260 cal
('bucees_pulled_pork_sandwich', 'Buc-ee''s Pulled Pork Sandwich', 260, 14.2, 20.8, 13.3,
 1.3, 6.7, NULL, 240,
 'website', ARRAY['buc-ees pulled pork sandwich', 'bucees pulled pork', 'buc ees pulled pork', 'buc-ee pulled pork sandwich', 'buc-ees bbq pulled pork'],
 'sandwich', 'Buc-ee''s', 1, '624 cal per sandwich (~240g). Slow-smoked pulled pork on a bun. 34g protein.', TRUE),

-- Buc-ee's Chopped Beef Sandwich: ~700 cal per sandwich (~250g)
-- per 100g: ~280 cal
('bucees_chopped_beef_sandwich', 'Buc-ee''s Chopped Beef Sandwich', 280, 15.2, 20.0, 14.8,
 1.2, 4.8, NULL, 250,
 'website', ARRAY['buc-ees chopped beef sandwich', 'bucees chopped beef', 'buc ees chopped beef', 'buc-ee chopped beef sandwich', 'buc-ees bbq chopped beef'],
 'sandwich', 'Buc-ee''s', 1, '700 cal per sandwich (~250g). Slow-smoked chopped beef on a bun. 38g protein.', TRUE),

-- ══════════════════════════════════════════
-- BUC-EE'S — SNACKS & BAKED GOODS
-- ══════════════════════════════════════════

-- Buc-ee's Beaver Nuggets: ~160 cal per 40g serving
-- per 100g: ~400 cal
('bucees_beaver_nuggets', 'Buc-ee''s Beaver Nuggets', 400, 2.5, 80.0, 7.5,
 0.0, 50.0, 40, NULL,
 'website', ARRAY['buc-ees beaver nuggets', 'bucees beaver nuggets', 'buc ees beaver nuggets', 'buc-ee beaver nuggets', 'bucees nuggets'],
 'snack', 'Buc-ee''s', 1, '160 cal per 40g serving. Sweet caramel-coated corn puffs. Buc-ee''s signature snack. 1g protein.', TRUE),

-- Buc-ee's Kolache Sausage: ~260 cal per ~110g piece
-- per 100g: ~236 cal
('bucees_kolache_sausage', 'Buc-ee''s Kolache (Sausage)', 236, 10.0, 23.6, 11.8,
 0.9, 3.6, NULL, 110,
 'website', ARRAY['buc-ees kolache sausage', 'bucees kolache', 'buc ees sausage kolache', 'buc-ee kolache', 'buc-ees sausage kolache'],
 'pastry', 'Buc-ee''s', 1, '260 cal per kolache (~110g). Soft pastry roll filled with smoked sausage. 11g protein.', TRUE),

-- Buc-ee's Kolache Sausage & Cheese: ~280 cal per ~120g piece
-- per 100g: ~233 cal
('bucees_kolache_sausage_cheese', 'Buc-ee''s Kolache (Sausage & Cheese)', 233, 10.8, 21.7, 11.7,
 0.8, 3.3, NULL, 120,
 'website', ARRAY['buc-ees kolache sausage cheese', 'bucees sausage cheese kolache', 'buc ees kolache sausage and cheese', 'buc-ee kolache cheese', 'buc-ees kolache sausage and cheese'],
 'pastry', 'Buc-ee''s', 1, '280 cal per kolache (~120g). Soft pastry roll filled with smoked sausage and cheese. 13g protein.', TRUE),

-- Buc-ee's Homemade Fudge: ~168 cal per 40g piece
-- per 100g: ~420 cal
('bucees_fudge', 'Buc-ee''s Homemade Fudge', 420, 3.0, 60.0, 18.0,
 1.0, 55.0, NULL, 40,
 'website', ARRAY['buc-ees fudge', 'bucees homemade fudge', 'buc ees fudge', 'buc-ee fudge', 'buc-ees chocolate fudge'],
 'dessert', 'Buc-ee''s', 1, '168 cal per piece (~40g). Rich homemade chocolate fudge. 1.2g protein.', TRUE),

-- Buc-ee's Beef Jerky: ~78 cal per 28g serving
-- per 100g: ~280 cal
('bucees_beef_jerky', 'Buc-ee''s Beef Jerky', 280, 42.9, 17.9, 3.6,
 0.0, 14.3, 28, NULL,
 'website', ARRAY['buc-ees beef jerky', 'bucees jerky', 'buc ees beef jerky', 'buc-ee jerky', 'buc-ees jerky original'],
 'jerky', 'Buc-ee''s', 1, '78 cal per 28g serving. House-made beef jerky. 12g protein per serving. High protein snack.', TRUE),

-- Buc-ee's Trail Mix: ~180 cal per 40g serving
-- per 100g: ~450 cal
('bucees_trail_mix', 'Buc-ee''s Trail Mix', 450, 12.5, 42.5, 27.5,
 3.8, 22.5, 40, NULL,
 'website', ARRAY['buc-ees trail mix', 'bucees trail mix', 'buc ees trail mix', 'buc-ee trail mix', 'buc-ees nut mix'],
 'snack', 'Buc-ee''s', 1, '180 cal per 40g serving. Mix of nuts, dried fruit, and chocolate. 5g protein per serving.', TRUE),

-- Buc-ee's Cinnamon Roll: ~350 cal per ~140g roll
-- per 100g: ~250 cal
('bucees_cinnamon_roll', 'Buc-ee''s Cinnamon Roll', 250, 4.3, 37.1, 9.3,
 1.4, 21.4, NULL, 140,
 'website', ARRAY['buc-ees cinnamon roll', 'bucees cinnamon roll', 'buc ees cinnamon roll', 'buc-ee cinnamon roll', 'buc-ees cinnamon bun'],
 'pastry', 'Buc-ee''s', 1, '350 cal per cinnamon roll (~140g). Warm glazed cinnamon roll. 6g protein.', TRUE),

-- Buc-ee's Cookie: ~360 cal per ~75g cookie
-- per 100g: ~480 cal
('bucees_cookie', 'Buc-ee''s Cookie', 480, 4.0, 60.0, 24.0,
 1.3, 40.0, NULL, 75,
 'website', ARRAY['buc-ees cookie', 'bucees cookie', 'buc ees cookie', 'buc-ee cookie', 'buc-ees chocolate chip cookie'],
 'dessert', 'Buc-ee''s', 1, '360 cal per cookie (~75g). Large fresh-baked cookie. 3g protein.', TRUE),

-- ══════════════════════════════════════════
-- SLIM CHICKENS — TENDERS
-- ══════════════════════════════════════════

-- Slim Chickens Tenders 3pc: ~330 cal per serving (~150g)
-- per 100g: ~220 cal
('slim_chickens_tenders_3pc', 'Slim Chickens Tenders (3pc)', 220, 20.0, 13.3, 10.0,
 0.7, 0.7, 150, NULL,
 'website', ARRAY['slim chickens tenders 3pc', 'slim chickens 3 piece tenders', 'slim chickens tenders 3 piece', 'slim chickens chicken tenders 3'],
 'chicken', 'Slim Chickens', 1, '330 cal per 3pc serving (~150g). Hand-breaded chicken tenders. 30g protein.', TRUE),

-- Slim Chickens Tenders 5pc: ~550 cal per serving (~250g)
-- per 100g: ~220 cal
('slim_chickens_tenders_5pc', 'Slim Chickens Tenders (5pc)', 220, 20.0, 13.3, 10.0,
 0.7, 0.7, 250, NULL,
 'website', ARRAY['slim chickens tenders 5pc', 'slim chickens 5 piece tenders', 'slim chickens tenders 5 piece', 'slim chickens chicken tenders 5'],
 'chicken', 'Slim Chickens', 1, '550 cal per 5pc serving (~250g). Hand-breaded chicken tenders. 50g protein.', TRUE),

-- ══════════════════════════════════════════
-- SLIM CHICKENS — SANDWICHES & WINGS
-- ══════════════════════════════════════════

-- Slim Chickens Chicken Sandwich: ~616 cal per sandwich (~220g)
-- per 100g: ~280 cal
('slim_chickens_sandwich', 'Slim Chickens Chicken Sandwich', 280, 16.4, 22.7, 13.6,
 1.4, 3.6, NULL, 220,
 'website', ARRAY['slim chickens sandwich', 'slim chickens chicken sandwich', 'slim chickens crispy chicken sandwich', 'slim chickens fried chicken sandwich'],
 'sandwich', 'Slim Chickens', 1, '616 cal per sandwich (~220g). Crispy fried chicken breast on a toasted bun. 36g protein.', TRUE),

-- Slim Chickens Wings 5pc: ~500 cal per serving (~200g)
-- per 100g: ~250 cal
('slim_chickens_wings_5pc', 'Slim Chickens Wings (5pc)', 250, 20.0, 5.0, 17.5,
 0.0, 0.5, 200, NULL,
 'website', ARRAY['slim chickens wings 5pc', 'slim chickens 5 piece wings', 'slim chickens wings 5 piece', 'slim chickens chicken wings 5'],
 'chicken', 'Slim Chickens', 1, '500 cal per 5pc wings (~200g). Crispy chicken wings. 40g protein.', TRUE),

-- Slim Chickens Wings 10pc: ~1000 cal per serving (~400g)
-- per 100g: ~250 cal
('slim_chickens_wings_10pc', 'Slim Chickens Wings (10pc)', 250, 20.0, 5.0, 17.5,
 0.0, 0.5, 400, NULL,
 'website', ARRAY['slim chickens wings 10pc', 'slim chickens 10 piece wings', 'slim chickens wings 10 piece', 'slim chickens chicken wings 10'],
 'chicken', 'Slim Chickens', 1, '1000 cal per 10pc wings (~400g). Crispy chicken wings. 80g protein.', TRUE),

-- ══════════════════════════════════════════
-- SLIM CHICKENS — SIDES & COMBOS
-- ══════════════════════════════════════════

-- Slim Chickens Chicken & Waffles: ~810 cal per serving (~300g)
-- per 100g: ~270 cal
('slim_chickens_chicken_waffles', 'Slim Chickens Chicken & Waffles', 270, 14.0, 26.7, 12.3,
 1.0, 6.7, 300, NULL,
 'website', ARRAY['slim chickens chicken and waffles', 'slim chickens chicken waffles', 'slim chickens waffles', 'slim chickens chicken & waffles'],
 'combo', 'Slim Chickens', 1, '810 cal per serving (~300g). Chicken tenders served over a fresh waffle. 42g protein.', TRUE),

-- Slim Chickens Mac & Cheese: ~289 cal per serving (~170g)
-- per 100g: ~170 cal
('slim_chickens_mac_cheese', 'Slim Chickens Mac & Cheese', 170, 7.1, 17.6, 8.2,
 0.6, 2.4, 170, NULL,
 'website', ARRAY['slim chickens mac and cheese', 'slim chickens mac cheese', 'slim chickens macaroni and cheese', 'slim chickens mac n cheese'],
 'side', 'Slim Chickens', 1, '289 cal per serving (~170g). Creamy macaroni and cheese side. 12g protein.', TRUE),

-- Slim Chickens Texas Toast: ~155 cal per slice (~50g)
-- per 100g: ~310 cal
('slim_chickens_texas_toast', 'Slim Chickens Texas Toast', 310, 8.0, 36.0, 14.0,
 2.0, 4.0, NULL, 50,
 'website', ARRAY['slim chickens texas toast', 'slim chickens toast', 'slim chickens garlic texas toast', 'slim chickens bread'],
 'side', 'Slim Chickens', 1, '155 cal per slice (~50g). Thick-cut buttery garlic texas toast. 4g protein.', TRUE)

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
