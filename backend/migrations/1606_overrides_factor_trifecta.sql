-- 1606_overrides_factor_trifecta.sql
-- Factor (meal delivery) — 19 prepared meals with full macros.
-- Trifecta (athlete meal delivery) — 13 meals including plain proteins and full meals.
-- Sources: FatSecret (verified tray labels), MyNetDiary, Factor/Trifecta official sites.
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
-- FACTOR — PREPARED MEALS
-- ══════════════════════════════════════════

-- Factor Roasted Garlic Chicken w/ Green Beans & Mashed Potatoes: 440 cal per tray (315g)
('factor_roasted_garlic_chicken', 'Factor Roasted Garlic Chicken w/ Green Beans & Mashed Potatoes', 139.7, 12.7, 8.9, 5.7,
 1.3, 1.0, 315, NULL,
 'research', ARRAY['factor roasted garlic chicken', 'factor garlic chicken green beans', 'factor garlic chicken mashed potatoes', 'factor roasted garlic chicken meal'],
 'prepared_meal', 'Factor', 1, '440 cal per tray (315g). Roasted garlic chicken with green beans and mashed potatoes.', TRUE),

-- Factor Herb Crusted Chicken: 760 cal per tray (315g)
('factor_herb_crusted_chicken', 'Factor Herb Crusted Chicken', 241.3, 13.7, 7.6, 18.4,
 1.0, 0.6, 315, NULL,
 'research', ARRAY['factor herb crusted chicken', 'factor herb chicken', 'factor herb crust chicken meal', 'factor crusted chicken'],
 'prepared_meal', 'Factor', 1, '760 cal per tray (315g). Herb crusted chicken breast with sides.', TRUE),

-- Factor Caprese Chicken: 630 cal per tray (315g)
('factor_caprese_chicken', 'Factor Caprese Chicken', 200.0, 15.2, 8.3, 11.7,
 1.0, 1.3, 315, NULL,
 'research', ARRAY['factor caprese chicken', 'factor caprese chicken meal', 'factor chicken caprese', 'factor caprese'],
 'prepared_meal', 'Factor', 1, '630 cal per tray (315g). Chicken breast with tomato, mozzarella, and basil caprese style.', TRUE),

-- Factor Miso Chicken: 610 cal per tray (315g)
('factor_miso_chicken', 'Factor Miso Chicken', 193.7, 13.0, 4.8, 14.0,
 0.6, 1.6, 315, NULL,
 'research', ARRAY['factor miso chicken', 'factor miso chicken meal', 'factor miso glazed chicken', 'factor chicken miso'],
 'prepared_meal', 'Factor', 1, '610 cal per tray (315g). Miso glazed chicken with sides.', TRUE),

-- Factor Chicken Poutine: 440 cal per tray (315g)
('factor_chicken_poutine', 'Factor Chicken Poutine', 139.7, 9.8, 9.5, 6.7,
 1.0, 0.6, 315, NULL,
 'research', ARRAY['factor chicken poutine', 'factor poutine', 'factor chicken poutine meal', 'factor poutine bowl'],
 'prepared_meal', 'Factor', 1, '440 cal per tray (315g). Chicken poutine with gravy and cheese curds.', TRUE),

-- Factor Chicken Florentine: 700 cal per tray (315g)
('factor_chicken_florentine', 'Factor Chicken Florentine', 222.2, 13.7, 5.4, 15.9,
 1.0, 0.6, 315, NULL,
 'research', ARRAY['factor chicken florentine', 'factor florentine chicken', 'factor chicken florentine meal', 'factor florentine'],
 'prepared_meal', 'Factor', 1, '700 cal per tray (315g). Chicken florentine with spinach cream sauce.', TRUE),

-- Factor Cilantro Chicken: 590 cal per tray (315g)
('factor_cilantro_chicken', 'Factor Cilantro Chicken', 187.3, 12.1, 11.7, 9.8,
 1.3, 1.0, 315, NULL,
 'research', ARRAY['factor cilantro chicken', 'factor cilantro lime chicken', 'factor cilantro chicken meal', 'factor chicken cilantro'],
 'prepared_meal', 'Factor', 1, '590 cal per tray (315g). Cilantro seasoned chicken with sides.', TRUE),

-- Factor Mediterranean Chicken w/ Chickpea Hummus: 720 cal per tray (315g)
('factor_mediterranean_chicken', 'Factor Mediterranean Chicken w/ Chickpea Hummus', 228.6, 14.6, 17.1, 11.7,
 1.9, 1.3, 315, NULL,
 'research', ARRAY['factor mediterranean chicken', 'factor mediterranean chicken hummus', 'factor chicken chickpea hummus', 'factor med chicken', 'factor mediterranean meal'],
 'prepared_meal', 'Factor', 1, '720 cal per tray (315g). Mediterranean style chicken with chickpea hummus and vegetables.', TRUE),

-- Factor Honey Mustard Chicken: 540 cal per tray (315g)
('factor_honey_mustard_chicken', 'Factor Honey Mustard Chicken', 171.4, 11.1, 10.5, 9.2,
 1.0, 2.5, 315, NULL,
 'research', ARRAY['factor honey mustard chicken', 'factor honey mustard', 'factor honey mustard chicken meal', 'factor chicken honey mustard'],
 'prepared_meal', 'Factor', 1, '540 cal per tray (315g). Honey mustard glazed chicken with sides.', TRUE),

-- Factor Chicken Alfredo Pasta: 670 cal per tray (315g)
('factor_chicken_alfredo_pasta', 'Factor Chicken Alfredo Pasta', 212.7, 12.4, 12.4, 11.7,
 0.6, 1.0, 315, NULL,
 'research', ARRAY['factor chicken alfredo', 'factor alfredo pasta', 'factor chicken alfredo pasta', 'factor alfredo'],
 'prepared_meal', 'Factor', 1, '670 cal per tray (315g). Chicken alfredo with creamy pasta.', TRUE),

-- Factor Harissa Braised Chicken: 480 cal per tray (315g)
('factor_harissa_braised_chicken', 'Factor Harissa Braised Chicken', 152.4, 12.1, 10.5, 7.3,
 1.3, 1.6, 315, NULL,
 'research', ARRAY['factor harissa chicken', 'factor harissa braised chicken', 'factor braised chicken harissa', 'factor harissa meal'],
 'prepared_meal', 'Factor', 1, '480 cal per tray (315g). Harissa spiced braised chicken with sides.', TRUE),

-- Factor Grilled Chicken Piccata: 660 cal per tray (315g)
('factor_grilled_chicken_piccata', 'Factor Grilled Chicken Piccata', 209.5, 13.0, 4.4, 15.9,
 0.6, 0.3, 315, NULL,
 'research', ARRAY['factor chicken piccata', 'factor grilled chicken piccata', 'factor piccata', 'factor chicken piccata meal'],
 'prepared_meal', 'Factor', 1, '660 cal per tray (315g). Grilled chicken piccata with lemon caper sauce.', TRUE),

-- Factor Shredded Chicken & Loaded Mashed Potatoes: 520 cal per tray (315g)
('factor_shredded_chicken_loaded_mashed', 'Factor Shredded Chicken & Loaded Mashed Potatoes', 165.1, 11.4, 8.3, 9.5,
 0.6, 1.0, 315, NULL,
 'research', ARRAY['factor shredded chicken mashed potatoes', 'factor loaded mashed potatoes', 'factor shredded chicken', 'factor chicken loaded mash'],
 'prepared_meal', 'Factor', 1, '520 cal per tray (315g). Shredded chicken with loaded mashed potatoes.', TRUE),

-- Factor Tomato Basil Chicken & Mashed Potatoes: 410 cal per tray (315g)
('factor_tomato_basil_chicken', 'Factor Tomato Basil Chicken & Mashed Potatoes', 130.2, 11.1, 9.2, 5.4,
 1.0, 1.6, 315, NULL,
 'research', ARRAY['factor tomato basil chicken', 'factor tomato chicken mashed potatoes', 'factor basil chicken', 'factor tomato basil meal'],
 'prepared_meal', 'Factor', 1, '410 cal per tray (315g). Tomato basil chicken with mashed potatoes.', TRUE),

-- Factor Chicken Marsala w/ Mashed Cauliflower: 510 cal per tray (315g)
('factor_chicken_marsala', 'Factor Chicken Marsala w/ Mashed Cauliflower', 161.9, 13.0, 6.7, 8.9,
 1.0, 1.3, 315, NULL,
 'research', ARRAY['factor chicken marsala', 'factor marsala chicken', 'factor chicken marsala cauliflower', 'factor marsala'],
 'prepared_meal', 'Factor', 1, '510 cal per tray (315g). Chicken marsala with mushroom wine sauce and mashed cauliflower.', TRUE),

-- Factor BBQ Chicken Breast & Sweet Potatoes: 610 cal per tray (315g)
('factor_bbq_chicken_sweet_potatoes', 'Factor BBQ Chicken Breast & Sweet Potatoes', 193.7, 13.0, 15.2, 8.6,
 1.6, 4.8, 315, NULL,
 'research', ARRAY['factor bbq chicken', 'factor bbq chicken sweet potatoes', 'factor barbecue chicken', 'factor bbq chicken meal'],
 'prepared_meal', 'Factor', 1, '610 cal per tray (315g). BBQ glazed chicken breast with roasted sweet potatoes.', TRUE),

-- Factor Sage Chicken & Maple Butter Sweet Potatoes: 540 cal per tray (315g)
('factor_sage_chicken_maple_sweet_potatoes', 'Factor Sage Chicken & Maple Butter Sweet Potatoes', 171.4, 11.4, 13.3, 7.9,
 1.3, 3.8, 315, NULL,
 'research', ARRAY['factor sage chicken', 'factor sage chicken maple sweet potatoes', 'factor maple butter sweet potatoes', 'factor sage chicken meal'],
 'prepared_meal', 'Factor', 1, '540 cal per tray (315g). Sage seasoned chicken with maple butter sweet potatoes.', TRUE),

-- Factor Artichoke & Parmesan Pork Chop: 570 cal per tray (315g)
('factor_artichoke_parmesan_pork_chop', 'Factor Artichoke & Parmesan Pork Chop', 181.0, 13.3, 7.6, 10.2,
 1.3, 1.6, 315, NULL,
 'research', ARRAY['factor pork chop', 'factor artichoke parmesan pork chop', 'factor parmesan pork', 'factor pork chop meal'],
 'prepared_meal', 'Factor', 1, '570 cal per tray (315g). Artichoke and parmesan crusted pork chop with sides.', TRUE),

-- Factor Italian Sausage & Herb Roasted Potatoes: 510 cal per tray (315g)
('factor_italian_sausage_herb_potatoes', 'Factor Italian Sausage & Herb Roasted Potatoes', 161.9, 6.7, 14.6, 9.2,
 1.3, 1.0, 315, NULL,
 'research', ARRAY['factor italian sausage', 'factor sausage herb potatoes', 'factor italian sausage potatoes', 'factor sausage meal'],
 'prepared_meal', 'Factor', 1, '510 cal per tray (315g). Italian sausage with herb roasted potatoes.', TRUE),

-- ══════════════════════════════════════════
-- TRIFECTA — PLAIN PROTEINS
-- ══════════════════════════════════════════

-- Trifecta Beef Patty (plain): 200 cal per patty (115g)
('trifecta_beef_patty', 'Trifecta Beef Patty (Plain)', 173.9, 26.1, 0.0, 7.0,
 0.0, 0.0, NULL, 115,
 'research', ARRAY['trifecta beef patty', 'trifecta plain beef patty', 'trifecta burger patty', 'trifecta beef'],
 'protein', 'Trifecta', 1, '200 cal per patty (115g). Plain grilled beef patty, no bun or toppings. High protein.', TRUE),

-- Trifecta Grilled Salmon: 250 cal per fillet (170g)
('trifecta_grilled_salmon', 'Trifecta Grilled Salmon', 147.1, 13.5, 0.0, 11.2,
 0.0, 0.0, NULL, 170,
 'research', ARRAY['trifecta salmon', 'trifecta grilled salmon', 'trifecta salmon fillet', 'trifecta plain salmon'],
 'protein', 'Trifecta', 1, '250 cal per fillet (170g). Plain grilled salmon fillet. Rich in omega-3 fatty acids.', TRUE),

-- Trifecta Grilled Chicken Breast (plain): 190 cal per breast (170g)
('trifecta_grilled_chicken_breast', 'Trifecta Grilled Chicken Breast (Plain)', 111.8, 20.6, 0.0, 2.4,
 0.0, 0.0, NULL, 170,
 'research', ARRAY['trifecta chicken breast', 'trifecta grilled chicken', 'trifecta plain chicken breast', 'trifecta chicken'],
 'protein', 'Trifecta', 1, '190 cal per breast (170g). Plain grilled chicken breast. Very lean, high protein.', TRUE),

-- ══════════════════════════════════════════
-- TRIFECTA — FULL MEALS
-- ══════════════════════════════════════════

-- Trifecta Beef Sloppy Joes: 480 cal per tray (340g)
('trifecta_beef_sloppy_joes', 'Trifecta Beef Sloppy Joes', 141.2, 11.2, 2.4, 9.7,
 0.6, 1.2, 340, NULL,
 'research', ARRAY['trifecta sloppy joes', 'trifecta beef sloppy joes', 'trifecta sloppy joe meal', 'trifecta beef sloppy joe'],
 'prepared_meal', 'Trifecta', 1, '480 cal per tray (340g). Beef sloppy joes prepared meal.', TRUE),

-- Trifecta Beef Stroganoff: 560 cal per tray (340g)
('trifecta_beef_stroganoff', 'Trifecta Beef Stroganoff', 164.7, 9.7, 4.1, 12.1,
 0.6, 0.9, 340, NULL,
 'research', ARRAY['trifecta beef stroganoff', 'trifecta stroganoff', 'trifecta beef stroganoff meal', 'trifecta stroganoff bowl'],
 'prepared_meal', 'Trifecta', 1, '560 cal per tray (340g). Beef stroganoff with creamy mushroom sauce.', TRUE),

-- Trifecta Beef Chili w/ Meat & Mushrooms: 350 cal per tray (340g)
('trifecta_beef_chili_mushrooms', 'Trifecta Beef Chili w/ Meat & Mushrooms', 102.9, 6.8, 5.3, 6.2,
 1.5, 1.2, 340, NULL,
 'research', ARRAY['trifecta beef chili', 'trifecta chili mushrooms', 'trifecta beef chili meat mushrooms', 'trifecta chili'],
 'prepared_meal', 'Trifecta', 1, '350 cal per tray (340g). Beef chili with meat and mushrooms.', TRUE),

-- Trifecta Beef & Fire Roasted Tomatoes w/ Sweet Potatoes: 400 cal per tray (340g)
('trifecta_beef_fire_roasted_tomatoes_sweet_potatoes', 'Trifecta Beef & Fire Roasted Tomatoes w/ Sweet Potatoes', 117.6, 8.2, 10.6, 4.7,
 1.5, 2.4, 340, NULL,
 'research', ARRAY['trifecta beef fire roasted tomatoes', 'trifecta beef sweet potatoes', 'trifecta beef tomatoes sweet potatoes', 'trifecta fire roasted beef'],
 'prepared_meal', 'Trifecta', 1, '400 cal per tray (340g). Beef with fire roasted tomatoes and sweet potatoes.', TRUE),

-- Trifecta Beef & Quinoa Grain Bowl: 420 cal per tray (340g)
('trifecta_beef_quinoa_grain_bowl', 'Trifecta Beef & Quinoa Grain Bowl', 123.5, 9.1, 12.1, 4.4,
 1.5, 0.9, 340, NULL,
 'research', ARRAY['trifecta beef quinoa', 'trifecta beef grain bowl', 'trifecta beef quinoa bowl', 'trifecta quinoa grain bowl'],
 'prepared_meal', 'Trifecta', 1, '420 cal per tray (340g). Beef and quinoa grain bowl with vegetables.', TRUE),

-- Trifecta Beef Patty w/ Quinoa, Spinach, Tomato: 460 cal per tray (340g)
('trifecta_beef_patty_quinoa_spinach', 'Trifecta Beef Patty w/ Quinoa, Spinach, Tomato', 135.3, 10.6, 10.6, 5.6,
 1.5, 0.9, 340, NULL,
 'research', ARRAY['trifecta beef patty quinoa', 'trifecta beef patty spinach', 'trifecta beef quinoa spinach tomato', 'trifecta beef patty meal'],
 'prepared_meal', 'Trifecta', 1, '460 cal per tray (340g). Beef patty with quinoa, spinach, and tomato.', TRUE),

-- Trifecta Creamy Carbonara Pasta w/ Braised Beef: 500 cal per tray (340g)
('trifecta_creamy_carbonara_braised_beef', 'Trifecta Creamy Carbonara Pasta w/ Braised Beef', 147.1, 11.8, 14.7, 4.7,
 0.9, 0.9, 340, NULL,
 'research', ARRAY['trifecta carbonara', 'trifecta carbonara pasta beef', 'trifecta creamy carbonara', 'trifecta pasta braised beef'],
 'prepared_meal', 'Trifecta', 1, '500 cal per tray (340g). Creamy carbonara pasta with braised beef.', TRUE),

-- Trifecta Burrito Bowl w/ Beef Patty & Jasmine Rice: 470 cal per tray (340g)
('trifecta_burrito_bowl_beef_rice', 'Trifecta Burrito Bowl w/ Beef Patty & Jasmine Rice', 138.2, 10.3, 12.6, 5.3,
 1.5, 0.9, 340, NULL,
 'research', ARRAY['trifecta burrito bowl', 'trifecta burrito bowl beef', 'trifecta beef burrito bowl rice', 'trifecta beef rice bowl'],
 'prepared_meal', 'Trifecta', 1, '470 cal per tray (340g). Burrito bowl with beef patty and jasmine rice.', TRUE),

-- Trifecta Pumpkin Chili w/ Beef: 450 cal per tray (340g)
('trifecta_pumpkin_chili_beef', 'Trifecta Pumpkin Chili w/ Beef', 132.4, 10.0, 12.4, 4.7,
 2.1, 1.8, 340, NULL,
 'research', ARRAY['trifecta pumpkin chili', 'trifecta pumpkin chili beef', 'trifecta pumpkin beef chili', 'trifecta chili pumpkin'],
 'prepared_meal', 'Trifecta', 1, '450 cal per tray (340g). Pumpkin chili with beef.', TRUE),

-- Trifecta Grilled Teriyaki Chicken w/ Broccoli & Rice: 450 cal per tray (340g)
('trifecta_grilled_teriyaki_chicken', 'Trifecta Grilled Teriyaki Chicken w/ Broccoli & Rice', 132.4, 9.4, 13.5, 4.4,
 1.2, 1.5, 340, NULL,
 'research', ARRAY['trifecta teriyaki chicken', 'trifecta grilled teriyaki chicken', 'trifecta teriyaki chicken broccoli rice', 'trifecta chicken teriyaki'],
 'prepared_meal', 'Trifecta', 1, '450 cal per tray (340g). Grilled teriyaki chicken with broccoli and rice.', TRUE)

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
