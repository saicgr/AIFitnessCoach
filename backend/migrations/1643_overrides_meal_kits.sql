-- 1643_overrides_meal_kits.sql
-- HelloFresh (~7M+ subscribers) — prepared meal kits, typical 650-800 cal/serving.
-- Member's Mark / Sam's Club (~600+ clubs) — bulk proteins, snacks, bakery.
-- Blue Apron (~350K+ subscribers) — prepared meal kits, typical 550-700 cal/serving.
-- Sources: official nutrition labels, FatSecret, Nutritionix, MyFoodDiary.
-- All values per 100g. default_serving_g = typical serving weight (prepared).

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- HELLOFRESH — MEAL KITS (PREPARED)
-- ══════════════════════════════════════════

-- HelloFresh Firecracker Meatballs: ~830 cal per 375g serving — verified via FatSecret
('hellofresh_firecracker_meatballs', 'HelloFresh Firecracker Meatballs', 221.3, 14.0, 22.0, 8.5,
 2.0, 5.0, 375, NULL,
 'website', ARRAY['hellofresh firecracker meatballs', 'hello fresh firecracker meatballs', 'hellofresh meatballs', 'hello fresh firecracker meatball bowl'],
 'entree', 'HelloFresh', 1, '830 cal per serving (375g). Firecracker meatballs with roasted green beans and sesame rice. Verified via FatSecret.', TRUE),

-- HelloFresh Cream Sauce Chicken: ~700 cal per 400g serving
('hellofresh_cream_sauce_chicken', 'HelloFresh Cream Sauce Chicken', 175.0, 14.5, 16.0, 6.5,
 1.5, 2.5, 400, NULL,
 'website', ARRAY['hellofresh cream sauce chicken', 'hello fresh cream sauce chicken', 'hellofresh creamy chicken', 'hello fresh chicken cream sauce'],
 'entree', 'HelloFresh', 1, '700 cal per serving (400g). Chicken in creamy sauce with roasted vegetables and starch side.', TRUE),

-- HelloFresh One-Pan Southwest Chicken: ~680 cal per 400g serving
('hellofresh_southwest_chicken', 'HelloFresh One-Pan Southwest Chicken', 170.0, 14.0, 18.0, 5.0,
 3.0, 3.0, 400, NULL,
 'website', ARRAY['hellofresh one pan southwest chicken', 'hello fresh southwest chicken', 'hellofresh southwest one pan', 'hello fresh one pan chicken'],
 'entree', 'HelloFresh', 1, '680 cal per serving (400g). Southwest-seasoned chicken with rice, beans, peppers, and cheese. One-pan recipe.', TRUE),

-- HelloFresh Parmesan Crusted Chicken: ~690 cal per 370g serving — verified via Nutritionix
('hellofresh_parmesan_crusted_chicken', 'HelloFresh Parmesan Crusted Chicken', 186.5, 15.0, 15.0, 8.0,
 1.5, 2.0, 370, NULL,
 'website', ARRAY['hellofresh parmesan crusted chicken', 'hello fresh parmesan chicken', 'hellofresh crispy parmesan chicken', 'hello fresh parmesan crusted chicken'],
 'entree', 'HelloFresh', 1, '690 cal per serving (370g). Parmesan-crusted chicken breast with mashed potatoes and green beans. Verified via Nutritionix.', TRUE),

-- HelloFresh Sesame Soy Beef Bowls: ~700 cal per 400g serving
('hellofresh_sesame_soy_beef', 'HelloFresh Sesame Soy Beef Bowls', 175.0, 13.0, 20.0, 5.0,
 2.0, 4.5, 400, NULL,
 'website', ARRAY['hellofresh sesame soy beef bowls', 'hello fresh sesame beef', 'hellofresh beef bowl sesame', 'hello fresh soy beef rice bowl'],
 'entree', 'HelloFresh', 1, '700 cal per serving (400g). Sesame-soy marinated beef over rice with roasted vegetables.', TRUE),

-- HelloFresh Mushroom Risotto: ~610 cal per 380g serving
('hellofresh_mushroom_risotto', 'HelloFresh Mushroom Risotto', 160.5, 5.0, 25.0, 4.0,
 1.5, 1.5, 380, NULL,
 'website', ARRAY['hellofresh mushroom risotto', 'hello fresh mushroom risotto', 'hellofresh risotto', 'hello fresh creamy mushroom risotto'],
 'entree', 'HelloFresh', 1, '610 cal per serving (380g). Creamy mushroom risotto with Parmesan. Vegetarian.', TRUE),

-- HelloFresh Pork Carnitas: ~700 cal per 380g serving
('hellofresh_pork_carnitas', 'HelloFresh Pork Carnitas', 184.2, 14.0, 18.0, 7.0,
 2.0, 2.5, 380, NULL,
 'website', ARRAY['hellofresh pork carnitas', 'hello fresh pork carnitas', 'hellofresh carnitas tacos', 'hello fresh pork carnitas bowl'],
 'entree', 'HelloFresh', 1, '700 cal per serving (380g). Seasoned pulled pork with rice, beans, and toppings.', TRUE),

-- HelloFresh Garlic Herb Steak: ~720 cal per 370g serving
('hellofresh_garlic_herb_steak', 'HelloFresh Garlic Herb Steak', 194.6, 18.0, 12.0, 8.0,
 1.5, 1.5, 370, NULL,
 'website', ARRAY['hellofresh garlic herb steak', 'hello fresh garlic steak', 'hellofresh steak dinner', 'hello fresh herb garlic steak'],
 'entree', 'HelloFresh', 1, '720 cal per serving (370g). Garlic-herb seasoned steak with roasted potatoes and vegetables. Higher protein option.', TRUE),

-- HelloFresh Thai Coconut Curry: ~660 cal per 400g serving
('hellofresh_thai_coconut_curry', 'HelloFresh Thai Coconut Curry', 165.0, 11.0, 15.0, 7.0,
 2.5, 3.5, 400, NULL,
 'website', ARRAY['hellofresh thai coconut curry', 'hello fresh thai curry', 'hellofresh coconut curry', 'hello fresh thai chicken curry'],
 'entree', 'HelloFresh', 1, '660 cal per serving (400g). Chicken or tofu in coconut curry sauce with jasmine rice and vegetables.', TRUE),

-- HelloFresh Cheesy Smothered Chicken: ~800 cal per 380g serving
('hellofresh_cheesy_smothered_chicken', 'HelloFresh Cheesy Smothered Chicken', 210.5, 17.0, 14.0, 10.0,
 1.0, 2.0, 380, NULL,
 'website', ARRAY['hellofresh cheesy smothered chicken', 'hello fresh smothered chicken', 'hellofresh cheesy chicken', 'hello fresh cheese smothered chicken'],
 'entree', 'HelloFresh', 1, '800 cal per serving (380g). Chicken breast smothered in cheese sauce with garlic bread and green beans. Higher calorie option.', TRUE),

-- ══════════════════════════════════════════
-- MEMBER'S MARK / SAM'S CLUB — PROTEINS
-- ══════════════════════════════════════════

-- Member's Mark Rotisserie Chicken: ~153 cal per 100g, serving 112g — verified via FatSecret
('members_mark_rotisserie_chicken', 'Member''s Mark Seasoned Rotisserie Chicken', 153.0, 22.0, 1.0, 7.0,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['members mark rotisserie chicken', 'sams club rotisserie chicken', 'member''s mark seasoned rotisserie', 'sam''s club whole chicken'],
 'protein', 'Member''s Mark', 1, '153 cal per 100g (171 cal per 4oz/112g serving). Seasoned whole rotisserie chicken. Verified: 130 cal per 3oz via FatSecret.', TRUE),

-- Member's Mark Frozen Chicken Breast: ~110 cal per 100g, serving 112g
('members_mark_frozen_chicken_breast', 'Member''s Mark Frozen Chicken Breast', 110.0, 23.0, 0.0, 1.5,
 0.0, 0.0, 112, NULL,
 'website', ARRAY['members mark frozen chicken breast', 'sams club frozen chicken', 'member''s mark boneless skinless chicken', 'sams club chicken breast bag'],
 'protein', 'Member''s Mark', 1, '110 cal per 100g (123 cal per 4oz/112g serving). Individually frozen boneless skinless chicken breasts. Bulk value pack.', TRUE),

-- ══════════════════════════════════════════
-- MEMBER'S MARK / SAM'S CLUB — SNACKS
-- ══════════════════════════════════════════

-- Member's Mark Protein Bars: ~370 cal per 100g, per piece 60g
('members_mark_protein_bars', 'Member''s Mark Protein Bars', 370.0, 33.0, 37.0, 10.0,
 5.0, 3.0, NULL, 60,
 'website', ARRAY['members mark protein bars', 'sams club protein bars', 'member''s mark protein bar', 'sams club members mark protein'],
 'snack', 'Member''s Mark', 1, '370 cal per 100g (222 cal per bar/60g). 20g protein per bar. Comparable to Quest/ONE bars.', TRUE),

-- Member's Mark Trail Mix: ~450 cal per 100g, serving 40g (1/4 cup)
('members_mark_trail_mix', 'Member''s Mark Trail Mix', 450.0, 13.0, 43.0, 27.0,
 3.0, 28.0, 40, NULL,
 'website', ARRAY['members mark trail mix', 'sams club trail mix', 'member''s mark nut and fruit trail mix', 'sams club members mark trail mix'],
 'snack', 'Member''s Mark', 1, '450 cal per 100g (180 cal per 40g/1/4 cup serving). Mixed nuts, raisins, M&Ms. Calorie-dense snack.', TRUE),

-- ══════════════════════════════════════════
-- MEMBER'S MARK / SAM'S CLUB — DAIRY
-- ══════════════════════════════════════════

-- Member's Mark Greek Yogurt: ~97 cal per 100g, serving 170g
('members_mark_greek_yogurt', 'Member''s Mark Greek Yogurt', 97.0, 10.0, 13.0, 0.7,
 0.0, 7.0, 170, NULL,
 'website', ARRAY['members mark greek yogurt', 'sams club greek yogurt', 'member''s mark plain greek yogurt', 'sams club members mark yogurt'],
 'dairy', 'Member''s Mark', 1, '97 cal per 100g (165 cal per 170g container). Plain nonfat Greek yogurt. Bulk value pack.', TRUE),

-- ══════════════════════════════════════════
-- MEMBER'S MARK / SAM'S CLUB — FROZEN & BAKERY
-- ══════════════════════════════════════════

-- Member's Mark Mozzarella Sticks (frozen): ~270 cal per 100g, per piece 30g
('members_mark_mozzarella_sticks', 'Member''s Mark Mozzarella Sticks (Frozen)', 270.0, 12.0, 25.0, 14.0,
 1.0, 2.0, NULL, 30,
 'website', ARRAY['members mark mozzarella sticks', 'sams club mozzarella sticks', 'member''s mark frozen mozzarella sticks', 'sams club frozen cheese sticks'],
 'appetizer', 'Member''s Mark', 1, '270 cal per 100g (81 cal per stick/30g). Breaded mozzarella sticks. Cook from frozen.', TRUE),

-- Member's Mark Croissants: ~410 cal per 100g, per piece 70g
('members_mark_croissants', 'Member''s Mark Butter Croissants', 410.0, 7.0, 40.0, 25.0,
 1.5, 8.0, NULL, 70,
 'website', ARRAY['members mark croissants', 'sams club croissants', 'member''s mark butter croissants', 'sams club bakery croissants'],
 'bakery', 'Member''s Mark', 1, '410 cal per 100g (287 cal per croissant/70g). All-butter French-style croissants baked in-store.', TRUE),

-- Member's Mark Sheet Cake (per slice): ~350 cal per 100g, serving 100g per piece
('members_mark_sheet_cake', 'Member''s Mark Sheet Cake (Slice)', 350.0, 3.0, 48.0, 17.0,
 0.0, 36.0, NULL, 100,
 'website', ARRAY['members mark sheet cake', 'sams club sheet cake slice', 'member''s mark cake', 'sams club bakery cake slice'],
 'dessert', 'Member''s Mark', 1, '350 cal per slice (100g). White or chocolate sheet cake with buttercream frosting. High sugar.', TRUE),

-- ══════════════════════════════════════════
-- BLUE APRON — MEAL KITS (PREPARED)
-- ══════════════════════════════════════════

-- Blue Apron Seared Chicken & Mashed Potatoes: ~680 cal per 380g serving
('blueapron_seared_chicken_mashed', 'Blue Apron Seared Chicken & Mashed Potatoes', 178.9, 14.0, 15.0, 7.0,
 1.5, 2.0, 380, NULL,
 'website', ARRAY['blue apron seared chicken mashed potatoes', 'blue apron chicken and potatoes', 'blueapron chicken dinner', 'blue apron chicken mashed potato'],
 'entree', 'Blue Apron', 1, '680 cal per serving (380g). Pan-seared chicken breast with creamy mashed potatoes and roasted vegetables. Blue Apron avg ~640 cal/serving.', TRUE),

-- Blue Apron Beef Burgers & Roasted Potatoes: ~740 cal per 370g serving
('blueapron_beef_burgers_potatoes', 'Blue Apron Beef Burgers & Roasted Potatoes', 200.0, 14.0, 18.0, 8.0,
 2.0, 2.5, 370, NULL,
 'website', ARRAY['blue apron beef burgers roasted potatoes', 'blue apron burger and potatoes', 'blueapron beef burger', 'blue apron cheeseburger potatoes'],
 'entree', 'Blue Apron', 1, '740 cal per serving (370g). Beef burgers on brioche buns with roasted potatoes and aioli.', TRUE),

-- Blue Apron Salmon & Lemon Butter: ~650 cal per 350g serving
('blueapron_salmon_lemon_butter', 'Blue Apron Salmon & Lemon Butter', 185.7, 16.0, 10.0, 9.0,
 1.5, 1.5, 350, NULL,
 'website', ARRAY['blue apron salmon lemon butter', 'blue apron salmon dinner', 'blueapron lemon butter salmon', 'blue apron pan seared salmon'],
 'entree', 'Blue Apron', 1, '650 cal per serving (350g). Pan-seared salmon with lemon butter sauce, roasted vegetables, and grain side. Good omega-3 source.', TRUE),

-- Blue Apron Pork Chops & Apple Compote: ~650 cal per 370g serving
('blueapron_pork_chops_apple', 'Blue Apron Pork Chops & Apple Compote', 175.7, 15.0, 14.0, 7.0,
 2.0, 5.0, 370, NULL,
 'website', ARRAY['blue apron pork chops apple compote', 'blue apron pork chop dinner', 'blueapron pork chops', 'blue apron pork with apple sauce'],
 'entree', 'Blue Apron', 1, '650 cal per serving (370g). Bone-in pork chops with apple compote and roasted root vegetables.', TRUE),

-- Blue Apron Pasta Bolognese: ~650 cal per 380g serving
('blueapron_pasta_bolognese', 'Blue Apron Pasta Bolognese', 171.1, 10.0, 22.0, 5.0,
 2.0, 3.5, 380, NULL,
 'website', ARRAY['blue apron pasta bolognese', 'blue apron bolognese', 'blueapron spaghetti bolognese', 'blue apron meat sauce pasta'],
 'entree', 'Blue Apron', 1, '650 cal per serving (380g). Fresh pasta with beef bolognese sauce and Parmesan.', TRUE),

-- Blue Apron Chicken Stir-Fry: ~580 cal per 400g serving
('blueapron_chicken_stir_fry', 'Blue Apron Chicken Stir-Fry', 145.0, 13.0, 14.0, 4.0,
 2.5, 3.0, 400, NULL,
 'website', ARRAY['blue apron chicken stir fry', 'blue apron stir fry', 'blueapron chicken stirfry', 'blue apron asian chicken stir fry'],
 'entree', 'Blue Apron', 1, '580 cal per serving (400g). Chicken stir-fry with vegetables and jasmine rice. Lower calorie option.', TRUE),

-- Blue Apron Shrimp Tacos: ~540 cal per 350g serving
('blueapron_shrimp_tacos', 'Blue Apron Shrimp Tacos', 154.3, 11.0, 16.0, 5.0,
 2.5, 2.0, 350, NULL,
 'website', ARRAY['blue apron shrimp tacos', 'blue apron tacos shrimp', 'blueapron shrimp taco', 'blue apron fish tacos shrimp'],
 'entree', 'Blue Apron', 1, '540 cal per serving (350g). Shrimp tacos with slaw, crema, and pickled onions on corn tortillas.', TRUE)

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
