-- 401_desi_district_chowrasta_expansion.sql
-- Expanded menus for Desi District and Chowrasta restaurants.
-- All values per 100g. Sources: USDA, nutritionix, calorieking, consistent with migration 296.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g
) VALUES

-- ==========================================
-- DESI DISTRICT - DD SPECIALS
-- ==========================================

('desi_district_mushroom_pepper_fry', 'Desi District Mushroom Pepper Fry', 145.0, 5.0, 8.0, 10.0,
 1.5, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district mushroom pepper fry', 'desi district mushroom fry'],
 'indian', 'Desi District', 1, '290 cal per serving (200g). Mushrooms stir-fried with black pepper.', TRUE,
 420.0, 0.0, 2.0, 0.0, 320.0, 8.0, 1.2, 0.0, 2.0, 0.0, 12.0, 0.8, 85.0, 8.0, 0.0),

('desi_district_street_veg_fried_rice', 'Desi District Street Style Veg Fried Rice', 140.0, 3.5, 22.0, 4.0,
 1.0, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district veg fried rice', 'desi district street veg fried rice'],
 'indian', 'Desi District', 1, '490 cal per serving (350g). Street-style with veggies and soy sauce.', TRUE,
 480.0, 0.0, 0.8, 0.0, 120.0, 20.0, 0.8, 25.0, 3.0, 0.0, 15.0, 0.5, 50.0, 5.0, 0.0),

('desi_district_street_egg_fried_rice', 'Desi District Street Style Egg Fried Rice', 150.0, 5.5, 21.0, 5.0,
 0.5, 0.5, 350, NULL,
 'desidistrict', ARRAY['desi district egg fried rice', 'desi district street egg fried rice'],
 'indian', 'Desi District', 1, '525 cal per serving (350g).', TRUE,
 500.0, 85.0, 1.2, 0.0, 130.0, 25.0, 1.0, 40.0, 2.0, 5.0, 14.0, 0.7, 70.0, 10.0, 0.0),

('desi_district_street_paneer_fried_rice', 'Desi District Street Style Paneer Fried Rice', 160.0, 6.0, 20.0, 6.0,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district paneer fried rice', 'desi district street paneer fried rice'],
 'indian', 'Desi District', 1, '560 cal per serving (350g).', TRUE,
 470.0, 10.0, 2.5, 0.0, 110.0, 60.0, 0.8, 30.0, 2.0, 0.0, 16.0, 0.6, 80.0, 6.0, 0.0),

('desi_district_street_chicken_fried_rice', 'Desi District Street Style Chicken Fried Rice', 160.0, 7.5, 20.0, 5.5,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district chicken fried rice', 'desi district street chicken fried rice'],
 'indian', 'Desi District', 1, '560 cal per serving (350g).', TRUE,
 510.0, 35.0, 1.2, 0.0, 150.0, 18.0, 1.0, 15.0, 2.0, 2.0, 18.0, 0.9, 95.0, 12.0, 0.0),

('desi_district_street_veg_noodles', 'Desi District Street Style Veg Noodles', 135.0, 3.5, 21.0, 4.0,
 1.0, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district veg noodles', 'desi district street veg noodles'],
 'indian', 'Desi District', 1, '473 cal per serving (350g).', TRUE,
 490.0, 0.0, 0.8, 0.0, 110.0, 15.0, 0.7, 20.0, 3.0, 0.0, 12.0, 0.4, 45.0, 4.0, 0.0),

('desi_district_street_paneer_noodles', 'Desi District Street Style Paneer Noodles', 155.0, 6.0, 20.0, 5.5,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district paneer noodles', 'desi district street paneer noodles'],
 'indian', 'Desi District', 1, '543 cal per serving (350g).', TRUE,
 480.0, 10.0, 2.2, 0.0, 100.0, 55.0, 0.7, 25.0, 2.0, 0.0, 14.0, 0.5, 75.0, 5.0, 0.0),

('desi_district_street_egg_noodles', 'Desi District Street Style Egg Noodles', 148.0, 5.5, 20.0, 5.0,
 0.5, 0.5, 350, NULL,
 'desidistrict', ARRAY['desi district egg noodles', 'desi district street egg noodles'],
 'indian', 'Desi District', 1, '518 cal per serving (350g).', TRUE,
 500.0, 80.0, 1.0, 0.0, 120.0, 22.0, 0.9, 35.0, 2.0, 4.0, 13.0, 0.6, 65.0, 9.0, 0.0),

('desi_district_street_chicken_noodles', 'Desi District Street Style Chicken Noodles', 155.0, 7.5, 20.0, 5.0,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district chicken noodles', 'desi district street chicken noodles'],
 'indian', 'Desi District', 1, '543 cal per serving (350g).', TRUE,
 520.0, 30.0, 1.0, 0.0, 140.0, 15.0, 0.9, 12.0, 2.0, 2.0, 16.0, 0.8, 90.0, 11.0, 0.0),

('desi_district_jackfruit_biryani', 'Desi District Jackfruit Biryani', 140.0, 3.0, 22.0, 4.5,
 1.5, 2.0, 420, NULL,
 'desidistrict', ARRAY['desi district jackfruit biryani'],
 'indian', 'Desi District', 1, '588 cal per serving (420g). Jackfruit pieces with spiced basmati rice.', TRUE,
 380.0, 0.0, 1.0, 0.0, 200.0, 30.0, 0.8, 10.0, 5.0, 0.0, 20.0, 0.3, 40.0, 3.0, 0.0),

('desi_district_chicken_joint_biryani', 'Desi District Chicken Joint Biryani', 160.0, 8.0, 18.0, 6.0,
 0.5, 0.5, 450, NULL,
 'desidistrict', ARRAY['desi district chicken joint biryani'],
 'indian', 'Desi District', 1, '720 cal per serving (450g). Chicken on-the-bone biryani.', TRUE,
 450.0, 45.0, 1.8, 0.0, 180.0, 22.0, 1.2, 15.0, 1.0, 3.0, 20.0, 1.2, 110.0, 14.0, 0.0),

('desi_district_kadai_veg_curry', 'Desi District Kadai Veg Curry', 95.0, 2.5, 10.0, 5.0,
 2.0, 2.5, 300, NULL,
 'desidistrict', ARRAY['desi district kadai veg', 'desi district kadai vegetable curry'],
 'indian', 'Desi District', 1, '285 cal per bowl (300g). Mixed veggies in spicy tomato-capsicum gravy.', TRUE,
 400.0, 0.0, 1.0, 0.0, 250.0, 30.0, 1.0, 80.0, 15.0, 0.0, 18.0, 0.4, 45.0, 2.0, 0.0),

('desi_district_chilli_mushroom', 'Desi District Chilli Mushroom', 140.0, 4.5, 10.0, 9.0,
 1.5, 2.0, 200, NULL,
 'desidistrict', ARRAY['desi district chilli mushroom', 'desi district chili mushroom'],
 'indian', 'Desi District', 1, '280 cal per serving (200g). Indo-Chinese style mushrooms.', TRUE,
 520.0, 0.0, 1.5, 0.0, 300.0, 6.0, 1.0, 0.0, 3.0, 0.0, 10.0, 0.7, 80.0, 7.0, 0.0),

-- ==========================================
-- DESI DISTRICT - BIRYANI / PULAO (new items only)
-- ==========================================

('desi_district_vijayawada_chicken_biryani', 'Desi District Vijayawada Chicken Biryani', 165.0, 8.0, 18.0, 6.5,
 0.5, 0.5, 450, NULL,
 'desidistrict', ARRAY['desi district vijayawada biryani', 'desi district vijayawada chicken'],
 'indian', 'Desi District', 1, '743 cal per serving (450g). Andhra-style spicy with curry leaves.', TRUE,
 460.0, 40.0, 2.0, 0.0, 190.0, 20.0, 1.2, 12.0, 1.0, 3.0, 22.0, 1.3, 115.0, 15.0, 0.0),

('desi_district_gutti_vankaya_pulao', 'Desi District Gutti Vankaya Pulao', 125.0, 2.5, 18.0, 4.5,
 2.0, 1.5, 400, NULL,
 'desidistrict', ARRAY['desi district gutti vankaya pulao', 'desi district stuffed eggplant pulao'],
 'indian', 'Desi District', 1, '500 cal per serving (400g). Stuffed eggplant with basmati rice.', TRUE,
 350.0, 0.0, 0.8, 0.0, 220.0, 18.0, 0.8, 5.0, 3.0, 0.0, 15.0, 0.3, 40.0, 2.0, 0.0),

('desi_district_paneer_pulao', 'Desi District Paneer Pulao', 145.0, 5.5, 18.0, 5.5,
 0.5, 0.5, 400, NULL,
 'desidistrict', ARRAY['desi district paneer pulao', 'desi district paneer pulav'],
 'indian', 'Desi District', 1, '580 cal per serving (400g). Paneer with cumin, ghee & basmati.', TRUE,
 370.0, 10.0, 2.5, 0.0, 120.0, 65.0, 0.7, 25.0, 1.0, 0.0, 16.0, 0.6, 90.0, 5.0, 0.0),

('desi_district_ulavacharu_paneer_biryani', 'Desi District Ulavacharu Paneer Biryani', 150.0, 5.5, 18.0, 6.0,
 1.0, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district ulavacharu paneer biryani'],
 'indian', 'Desi District', 1, '630 cal per serving (420g). Andhra-style with horse gram paste.', TRUE,
 400.0, 10.0, 2.5, 0.0, 140.0, 60.0, 1.0, 20.0, 1.0, 0.0, 18.0, 0.6, 85.0, 5.0, 0.0),

('desi_district_gutti_vankaya_biryani', 'Desi District Gutti Vankaya Biryani', 130.0, 2.5, 19.0, 4.5,
 2.0, 1.5, 420, NULL,
 'desidistrict', ARRAY['desi district gutti vankaya biryani', 'desi district stuffed eggplant biryani'],
 'indian', 'Desi District', 1, '546 cal per serving (420g). Stuffed baby eggplants with rice.', TRUE,
 360.0, 0.0, 0.8, 0.0, 230.0, 18.0, 0.9, 5.0, 3.0, 0.0, 16.0, 0.3, 42.0, 2.0, 0.0),

('desi_district_egg_biryani', 'Desi District Egg Biryani', 145.0, 6.0, 18.0, 5.0,
 0.5, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district egg biryani'],
 'indian', 'Desi District', 1, '609 cal per serving (420g). Boiled eggs with spiced basmati.', TRUE,
 430.0, 120.0, 1.2, 0.0, 130.0, 30.0, 1.2, 60.0, 0.5, 10.0, 12.0, 0.7, 100.0, 12.0, 0.0),

('desi_district_special_chicken_biryani', 'Desi District Special Chicken Biryani', 170.0, 8.5, 18.0, 7.0,
 0.5, 0.5, 450, NULL,
 'desidistrict', ARRAY['desi district special biryani', 'desi district premium chicken biryani'],
 'indian', 'Desi District', 1, '765 cal per serving (450g). Premium chicken with cashews & saffron.', TRUE,
 440.0, 45.0, 2.2, 0.0, 200.0, 25.0, 1.3, 15.0, 1.0, 3.0, 24.0, 1.4, 120.0, 16.0, 0.0),

('desi_district_veg_pulao', 'Desi District Veg Pulao', 125.0, 3.0, 20.0, 3.5,
 1.0, 1.0, 380, NULL,
 'desidistrict', ARRAY['desi district veg pulao', 'desi district vegetable pulao'],
 'indian', 'Desi District', 1, '475 cal per serving (380g). Mildly spiced basmati with veggies.', TRUE,
 340.0, 0.0, 0.7, 0.0, 130.0, 20.0, 0.6, 40.0, 4.0, 0.0, 14.0, 0.3, 45.0, 3.0, 0.0),

('desi_district_vijayawada_chicken_pulao', 'Desi District Vijayawada Chicken Pulao', 150.0, 7.5, 18.0, 5.5,
 0.5, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district vijayawada chicken pulao'],
 'indian', 'Desi District', 1, '630 cal per serving (420g). Andhra-style pulao with curry leaves.', TRUE,
 460.0, 38.0, 1.5, 0.0, 180.0, 18.0, 1.0, 12.0, 1.0, 3.0, 20.0, 1.1, 105.0, 13.0, 0.0),

('desi_district_gongura_chicken_pulao', 'Desi District Gongura Chicken Pulao', 148.0, 7.5, 17.0, 5.5,
 1.0, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district gongura chicken pulao'],
 'indian', 'Desi District', 1, '622 cal per serving (420g). With tangy sorrel leaves.', TRUE,
 450.0, 38.0, 1.5, 0.0, 190.0, 20.0, 1.2, 45.0, 8.0, 3.0, 22.0, 1.1, 108.0, 13.0, 0.0),

('desi_district_egg_pulao', 'Desi District Egg Pulao', 135.0, 5.5, 18.0, 4.5,
 0.5, 0.5, 400, NULL,
 'desidistrict', ARRAY['desi district egg pulao'],
 'indian', 'Desi District', 1, '540 cal per serving (400g).', TRUE,
 420.0, 110.0, 1.0, 0.0, 120.0, 28.0, 1.0, 55.0, 0.5, 8.0, 11.0, 0.6, 90.0, 10.0, 0.0),

('desi_district_fry_piece_chicken_biryani', 'Desi District Fry Piece Chicken Biryani', 175.0, 8.0, 18.0, 7.5,
 0.5, 0.5, 450, NULL,
 'desidistrict', ARRAY['desi district fry piece biryani', 'desi district fried chicken biryani'],
 'indian', 'Desi District', 1, '788 cal per serving (450g). Crispy fried chicken with biryani.', TRUE,
 470.0, 50.0, 2.2, 0.0, 170.0, 20.0, 1.2, 12.0, 1.0, 3.0, 20.0, 1.2, 110.0, 14.0, 0.0),

('desi_district_shrimp_pulao', 'Desi District Shrimp Pulao', 140.0, 8.0, 17.0, 4.5,
 0.5, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district shrimp pulao', 'desi district prawn pulao'],
 'indian', 'Desi District', 1, '588 cal per serving (420g).', TRUE,
 450.0, 70.0, 0.8, 0.0, 200.0, 35.0, 1.0, 10.0, 1.0, 2.0, 25.0, 1.0, 130.0, 20.0, 0.1),

('desi_district_fry_piece_chicken_pulao', 'Desi District Fry Piece Chicken Pulao', 165.0, 8.0, 18.0, 7.0,
 0.5, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district fry piece pulao', 'desi district fried chicken pulao'],
 'indian', 'Desi District', 1, '693 cal per serving (420g).', TRUE,
 460.0, 48.0, 2.0, 0.0, 160.0, 18.0, 1.0, 10.0, 1.0, 3.0, 18.0, 1.1, 105.0, 13.0, 0.0),

('desi_district_chicken_65_pulao', 'Desi District Chicken 65 Pulao', 160.0, 7.5, 18.0, 6.5,
 0.5, 0.5, 420, NULL,
 'desidistrict', ARRAY['desi district chicken 65 pulao'],
 'indian', 'Desi District', 1, '672 cal per serving (420g).', TRUE,
 460.0, 42.0, 1.8, 0.0, 170.0, 18.0, 1.0, 10.0, 1.0, 3.0, 19.0, 1.1, 108.0, 13.0, 0.0),

-- ==========================================
-- DESI DISTRICT - BREADS
-- ==========================================

('desi_district_chole_bhatura', 'Desi District Chole Bhatura', 235.0, 6.5, 28.0, 11.0,
 3.0, 2.0, 280, NULL,
 'desidistrict', ARRAY['desi district chole bhature', 'desi district chole bhatura'],
 'indian', 'Desi District', 1, '658 cal per serving (280g). Deep-fried bread with chickpea curry.', TRUE,
 550.0, 0.0, 2.5, 0.0, 200.0, 40.0, 2.0, 5.0, 2.0, 0.0, 25.0, 0.8, 80.0, 4.0, 0.0),

('desi_district_garlic_naan', 'Desi District Garlic Naan', 280.0, 8.0, 40.0, 10.0,
 1.5, 2.0, 100, 100,
 'desidistrict', ARRAY['desi district garlic naan'],
 'indian', 'Desi District', 1, '280 cal per naan (100g).', TRUE,
 480.0, 5.0, 3.0, 0.0, 80.0, 35.0, 2.0, 10.0, 0.0, 0.0, 18.0, 0.5, 60.0, 10.0, 0.0),

('desi_district_butter_naan', 'Desi District Butter Naan', 300.0, 7.5, 42.0, 12.0,
 1.0, 2.0, 90, 90,
 'desidistrict', ARRAY['desi district butter naan'],
 'indian', 'Desi District', 1, '270 cal per naan (90g).', TRUE,
 470.0, 10.0, 5.0, 0.0, 70.0, 30.0, 1.8, 35.0, 0.0, 0.0, 16.0, 0.4, 55.0, 9.0, 0.0),

-- ==========================================
-- DESI DISTRICT - CHAAT
-- ==========================================

('desi_district_pani_puri', 'Desi District Pani Puri', 130.0, 3.0, 20.0, 4.0,
 1.5, 3.0, 175, 25,
 'desidistrict', ARRAY['desi district pani puri', 'desi district golgappa'],
 'indian', 'Desi District', 7, '228 cal per 7 pieces (175g).', TRUE,
 380.0, 0.0, 0.6, 0.0, 150.0, 15.0, 1.0, 5.0, 4.0, 0.0, 12.0, 0.4, 40.0, 2.0, 0.0),

('desi_district_samosa_chaat', 'Desi District Samosa Chaat', 195.0, 4.5, 22.0, 10.0,
 2.0, 3.0, 200, NULL,
 'desidistrict', ARRAY['desi district samosa chaat', 'desi district samosa chat'],
 'indian', 'Desi District', 2, '390 cal per serving (200g). Crumbled samosas with yogurt & chutneys.', TRUE,
 420.0, 5.0, 2.0, 0.0, 180.0, 30.0, 1.2, 10.0, 3.0, 0.0, 14.0, 0.5, 50.0, 3.0, 0.0),

('desi_district_veg_biryani_chaat', 'Desi District Veg Biryani Chaat', 155.0, 3.5, 20.0, 6.5,
 1.5, 2.5, 200, NULL,
 'desidistrict', ARRAY['desi district veg biryani chaat'],
 'indian', 'Desi District', 1, '310 cal per serving (200g).', TRUE,
 400.0, 0.0, 1.2, 0.0, 160.0, 25.0, 0.8, 15.0, 3.0, 0.0, 12.0, 0.4, 45.0, 3.0, 0.0),

('desi_district_dahi_puri', 'Desi District Dahi Puri', 150.0, 3.5, 20.0, 6.0,
 1.0, 4.0, 180, NULL,
 'desidistrict', ARRAY['desi district dahi puri'],
 'indian', 'Desi District', 1, '270 cal per serving (180g). Crisp puris with yogurt & chutneys.', TRUE,
 350.0, 5.0, 1.5, 0.0, 140.0, 40.0, 0.8, 8.0, 2.0, 0.0, 10.0, 0.3, 50.0, 2.0, 0.0),

-- ==========================================
-- DESI DISTRICT - DESI BURGERS (new items)
-- ==========================================

('desi_district_spicy_chicken_burger', 'Desi District Spicy Chicken Burger', 235.0, 13.0, 22.0, 11.0,
 1.0, 2.0, 250, 250,
 'desidistrict', ARRAY['desi district spicy chicken burger'],
 'indian', 'Desi District', 1, '588 cal per burger (250g). Tender marinated chicken in a bun.', TRUE,
 580.0, 40.0, 3.0, 0.0, 180.0, 30.0, 1.5, 10.0, 2.0, 2.0, 20.0, 1.0, 100.0, 12.0, 0.0),

('desi_district_paneer_tikka_burger', 'Desi District Paneer Tikka Burger', 225.0, 9.0, 24.0, 10.5,
 1.0, 2.5, 240, 240,
 'desidistrict', ARRAY['desi district paneer burger', 'desi district paneer tikka burger'],
 'indian', 'Desi District', 1, '540 cal per burger (240g).', TRUE,
 520.0, 15.0, 4.0, 0.0, 130.0, 70.0, 1.2, 25.0, 2.0, 0.0, 18.0, 0.6, 90.0, 6.0, 0.0),

('desi_district_veg_burger', 'Desi District Veg Burger', 210.0, 5.0, 28.0, 8.5,
 2.0, 3.0, 230, 230,
 'desidistrict', ARRAY['desi district veg burger', 'desi district vegetable burger'],
 'indian', 'Desi District', 1, '483 cal per burger (230g).', TRUE,
 480.0, 0.0, 1.5, 0.0, 160.0, 25.0, 1.0, 15.0, 3.0, 0.0, 15.0, 0.4, 55.0, 3.0, 0.0),

-- ==========================================
-- DESI DISTRICT - DESSERTS (new: osmania cookies)
-- ==========================================

('desi_district_osmania_cookies', 'Desi District Osmania Cookies', 450.0, 6.0, 58.0, 22.0,
 1.0, 22.0, 60, 30,
 'desidistrict', ARRAY['desi district osmania biscuit', 'desi district osmania cookies'],
 'desserts', 'Desi District', 2, '270 cal per 2 pieces (60g). Classic Hyderabad-style butter cookies.', TRUE,
 250.0, 30.0, 12.0, 0.5, 60.0, 20.0, 1.0, 50.0, 0.0, 0.0, 8.0, 0.3, 40.0, 4.0, 0.0),

-- ==========================================
-- DESI DISTRICT - TIFFINS / BREAKFAST (new items)
-- ==========================================

('desi_district_ghee_karam_idli', 'Desi District Ghee Karam Idli', 95.0, 2.5, 14.0, 3.5,
 0.5, 0.3, 200, 60,
 'desidistrict', ARRAY['desi district ghee karam idli', 'desi district ghee idli'],
 'indian', 'Desi District', 3, '190 cal per 3 pieces (200g). Steamed idlis with spicy ghee & red chili.', TRUE,
 350.0, 5.0, 1.5, 0.0, 80.0, 10.0, 0.5, 20.0, 0.0, 0.0, 8.0, 0.3, 40.0, 3.0, 0.0),

('desi_district_onion_masala_dosa', 'Desi District Onion Masala Dosa', 170.0, 4.0, 22.0, 7.0,
 1.5, 1.5, 210, 210,
 'desidistrict', ARRAY['desi district onion masala dosa'],
 'indian', 'Desi District', 1, '357 cal per dosa (210g). Crispy dosa with spiced onions & potato.', TRUE,
 380.0, 0.0, 1.2, 0.0, 180.0, 15.0, 0.8, 5.0, 4.0, 0.0, 14.0, 0.4, 55.0, 4.0, 0.0),

('desi_district_mysore_masala_dosa', 'Desi District Mysore Masala Dosa', 175.0, 4.0, 21.0, 8.0,
 1.5, 1.0, 210, 210,
 'desidistrict', ARRAY['desi district mysore masala dosa', 'desi district mysore dosa'],
 'indian', 'Desi District', 1, '368 cal per dosa (210g). With fiery Mysore red chutney.', TRUE,
 390.0, 0.0, 1.5, 0.0, 175.0, 15.0, 0.9, 30.0, 5.0, 0.0, 14.0, 0.4, 55.0, 4.0, 0.0),

('desi_district_poori_aloo_curry', 'Desi District Poori with Aloo Curry', 220.0, 5.0, 26.0, 11.0,
 1.5, 1.0, 250, 80,
 'desidistrict', ARRAY['desi district poori aloo', 'desi district poori with aloo curry'],
 'indian', 'Desi District', 2, '550 cal per 2 pooris with curry (250g).', TRUE,
 400.0, 0.0, 2.5, 0.0, 250.0, 18.0, 1.5, 5.0, 6.0, 0.0, 20.0, 0.4, 55.0, 3.0, 0.0),

('desi_district_plain_dosa', 'Desi District Plain Dosa', 120.0, 3.5, 20.0, 2.5,
 0.5, 0.5, 130, 130,
 'desidistrict', ARRAY['desi district plain dosa', 'desi district dosa'],
 'indian', 'Desi District', 1, '156 cal per dosa (130g). Crispy fermented rice-lentil crepe.', TRUE,
 280.0, 0.0, 0.5, 0.0, 70.0, 10.0, 0.5, 0.0, 0.0, 0.0, 10.0, 0.3, 40.0, 3.0, 0.0),

('desi_district_ghee_dosa', 'Desi District Ghee Dosa', 190.0, 3.5, 22.0, 10.0,
 0.5, 0.5, 150, 150,
 'desidistrict', ARRAY['desi district ghee dosa', 'desi district ghee roast dosa'],
 'indian', 'Desi District', 1, '285 cal per dosa (150g). Extra crispy with ghee.', TRUE,
 290.0, 8.0, 4.5, 0.0, 75.0, 12.0, 0.5, 30.0, 0.0, 0.0, 10.0, 0.3, 42.0, 3.0, 0.0),

('desi_district_uthappam', 'Desi District Uthappam', 130.0, 4.0, 20.0, 3.5,
 1.0, 1.0, 200, 200,
 'desidistrict', ARRAY['desi district uthappam', 'desi district uttapam'],
 'indian', 'Desi District', 1, '260 cal per uthappam (200g). Thick rice-lentil pancake.', TRUE,
 320.0, 0.0, 0.6, 0.0, 120.0, 15.0, 0.7, 10.0, 4.0, 0.0, 12.0, 0.4, 50.0, 3.0, 0.0),

('desi_district_onion_dosa', 'Desi District Onion Dosa', 140.0, 3.5, 20.0, 5.0,
 1.0, 1.0, 160, 160,
 'desidistrict', ARRAY['desi district onion dosa'],
 'indian', 'Desi District', 1, '224 cal per dosa (160g). Crispy dosa with spiced onions.', TRUE,
 310.0, 0.0, 0.8, 0.0, 100.0, 12.0, 0.6, 2.0, 3.0, 0.0, 11.0, 0.3, 45.0, 3.0, 0.0),

('desi_district_dosa_chicken_curry', 'Desi District Dosa with Chicken Curry', 155.0, 7.0, 18.0, 6.0,
 0.5, 1.0, 280, NULL,
 'desidistrict', ARRAY['desi district dosa chicken curry', 'desi district chicken curry dosa'],
 'indian', 'Desi District', 1, '434 cal per serving (280g). Plain dosa served with chicken curry.', TRUE,
 420.0, 30.0, 1.5, 0.0, 160.0, 18.0, 1.0, 12.0, 2.0, 2.0, 16.0, 0.8, 80.0, 10.0, 0.0),

-- ==========================================
-- DESI DISTRICT - INDO-CHINESE
-- ==========================================

('desi_district_schezwan_veg_noodles', 'Desi District Schezwan Veg Noodles', 145.0, 3.5, 22.0, 4.5,
 1.0, 1.5, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan veg noodles'],
 'indian', 'Desi District', 1, '508 cal per serving (350g). Spicy Schezwan sauce with veggies.', TRUE,
 560.0, 0.0, 0.8, 0.0, 120.0, 18.0, 0.8, 20.0, 4.0, 0.0, 13.0, 0.4, 48.0, 4.0, 0.0),

('desi_district_schezwan_chicken_fried_rice', 'Desi District Schezwan Chicken Fried Rice', 165.0, 7.5, 21.0, 5.5,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan chicken fried rice'],
 'indian', 'Desi District', 1, '578 cal per serving (350g).', TRUE,
 580.0, 35.0, 1.2, 0.0, 155.0, 18.0, 1.0, 15.0, 3.0, 2.0, 18.0, 0.9, 95.0, 12.0, 0.0),

('desi_district_schezwan_egg_noodles', 'Desi District Schezwan Egg Noodles', 152.0, 5.5, 21.0, 5.0,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan egg noodles'],
 'indian', 'Desi District', 1, '532 cal per serving (350g).', TRUE,
 560.0, 80.0, 1.0, 0.0, 130.0, 22.0, 0.9, 35.0, 2.0, 4.0, 14.0, 0.6, 68.0, 9.0, 0.0),

('desi_district_schezwan_chicken_noodles', 'Desi District Schezwan Chicken Noodles', 158.0, 7.5, 20.0, 5.5,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan chicken noodles'],
 'indian', 'Desi District', 1, '553 cal per serving (350g).', TRUE,
 570.0, 30.0, 1.0, 0.0, 145.0, 16.0, 0.9, 12.0, 2.0, 2.0, 17.0, 0.8, 92.0, 11.0, 0.0),

('desi_district_schezwan_paneer_noodles', 'Desi District Schezwan Paneer Noodles', 160.0, 6.0, 20.0, 6.0,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan paneer noodles'],
 'indian', 'Desi District', 1, '560 cal per serving (350g).', TRUE,
 550.0, 10.0, 2.5, 0.0, 110.0, 55.0, 0.7, 25.0, 2.0, 0.0, 15.0, 0.5, 78.0, 5.0, 0.0),

('desi_district_schezwan_egg_fried_rice', 'Desi District Schezwan Egg Fried Rice', 155.0, 5.5, 22.0, 5.0,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan egg fried rice'],
 'indian', 'Desi District', 1, '543 cal per serving (350g).', TRUE,
 570.0, 85.0, 1.2, 0.0, 135.0, 25.0, 1.0, 40.0, 2.0, 5.0, 14.0, 0.7, 72.0, 10.0, 0.0),

('desi_district_schezwan_paneer_fried_rice', 'Desi District Schezwan Paneer Fried Rice', 165.0, 6.0, 21.0, 6.0,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan paneer fried rice'],
 'indian', 'Desi District', 1, '578 cal per serving (350g).', TRUE,
 560.0, 10.0, 2.5, 0.0, 115.0, 58.0, 0.8, 28.0, 2.0, 0.0, 16.0, 0.6, 82.0, 6.0, 0.0),

('desi_district_schezwan_veg_fried_rice', 'Desi District Schezwan Veg Fried Rice', 148.0, 3.5, 23.0, 4.5,
 1.0, 1.5, 350, NULL,
 'desidistrict', ARRAY['desi district schezwan veg fried rice'],
 'indian', 'Desi District', 1, '518 cal per serving (350g).', TRUE,
 550.0, 0.0, 0.8, 0.0, 125.0, 20.0, 0.8, 25.0, 4.0, 0.0, 15.0, 0.5, 52.0, 5.0, 0.0),

('desi_district_chilli_chicken', 'Desi District Chilli Chicken', 200.0, 15.0, 10.0, 12.0,
 0.5, 2.0, 200, NULL,
 'desidistrict', ARRAY['desi district chilli chicken', 'desi district chili chicken boneless'],
 'indian', 'Desi District', 1, '400 cal per serving (200g). Indo-Chinese style.', TRUE,
 580.0, 55.0, 2.5, 0.0, 200.0, 15.0, 1.2, 10.0, 5.0, 2.0, 20.0, 1.2, 120.0, 15.0, 0.0),

('desi_district_gobi_manchurian', 'Desi District Gobi Manchurian', 170.0, 4.0, 18.0, 9.0,
 2.0, 3.0, 200, NULL,
 'desidistrict', ARRAY['desi district gobi manchurian', 'desi district cauliflower manchurian'],
 'indian', 'Desi District', 1, '340 cal per serving (200g). Crispy cauliflower in sweet-spicy sauce.', TRUE,
 540.0, 0.0, 1.5, 0.0, 220.0, 20.0, 0.8, 2.0, 30.0, 0.0, 12.0, 0.3, 40.0, 2.0, 0.0),

('desi_district_veg_manchurian', 'Desi District Veg Manchurian', 165.0, 3.5, 18.0, 8.5,
 1.5, 3.0, 200, NULL,
 'desidistrict', ARRAY['desi district veg manchurian', 'desi district vegetable manchurian'],
 'indian', 'Desi District', 1, '330 cal per serving (200g).', TRUE,
 530.0, 0.0, 1.5, 0.0, 200.0, 18.0, 0.7, 15.0, 8.0, 0.0, 10.0, 0.3, 38.0, 2.0, 0.0),

('desi_district_chicken_manchurian', 'Desi District Chicken Manchurian', 195.0, 14.0, 12.0, 10.0,
 0.5, 2.5, 200, NULL,
 'desidistrict', ARRAY['desi district chicken manchurian'],
 'indian', 'Desi District', 1, '390 cal per serving (200g). Chicken dumplings in Manchurian sauce.', TRUE,
 560.0, 50.0, 2.0, 0.0, 190.0, 15.0, 1.0, 8.0, 4.0, 2.0, 18.0, 1.0, 110.0, 13.0, 0.0),

-- ==========================================
-- DESI DISTRICT - KATI ROLLS (new items)
-- ==========================================

('desi_district_achari_paneer_kati_roll', 'Desi District Achari Paneer Kati Roll', 225.0, 8.5, 23.0, 11.0,
 1.0, 1.5, 200, 200,
 'desidistrict', ARRAY['desi district achari paneer roll', 'desi district achari paneer kati roll'],
 'indian', 'Desi District', 1, '450 cal per roll (200g). Paneer in pickled spices.', TRUE,
 490.0, 12.0, 4.0, 0.0, 120.0, 65.0, 1.0, 20.0, 2.0, 0.0, 16.0, 0.6, 85.0, 5.0, 0.0),

('desi_district_delhi_belly_paneer_roll', 'Desi District Delhi Belly Paneer Kati Roll', 230.0, 8.0, 24.0, 11.5,
 1.0, 2.0, 200, 200,
 'desidistrict', ARRAY['desi district delhi belly paneer roll'],
 'indian', 'Desi District', 1, '460 cal per roll (200g). Creamy paneer in tangy spices.', TRUE,
 500.0, 14.0, 4.5, 0.0, 115.0, 68.0, 1.0, 22.0, 2.0, 0.0, 16.0, 0.6, 88.0, 5.0, 0.0),

-- ==========================================
-- DESI DISTRICT - KIDS MENU
-- ==========================================

('desi_district_kids_chicken_fried_rice', 'Desi District Kids Chicken Fried Rice', 155.0, 7.0, 20.0, 5.5,
 0.5, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district kids chicken fried rice'],
 'indian', 'Desi District', 1, '310 cal per serving (200g). Mild flavors for kids.', TRUE,
 400.0, 30.0, 1.0, 0.0, 130.0, 15.0, 0.8, 10.0, 1.0, 2.0, 14.0, 0.7, 75.0, 9.0, 0.0),

('desi_district_kids_chicken_noodles', 'Desi District Kids Chicken Hakka Noodles', 150.0, 7.0, 20.0, 5.0,
 0.5, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district kids chicken noodles', 'desi district kids hakka noodles'],
 'indian', 'Desi District', 1, '300 cal per serving (200g).', TRUE,
 410.0, 28.0, 1.0, 0.0, 120.0, 12.0, 0.7, 8.0, 1.0, 2.0, 13.0, 0.6, 70.0, 8.0, 0.0),

('desi_district_kids_chicken_nuggets', 'Desi District Kids Desi Chicken Nuggets', 240.0, 14.0, 16.0, 13.0,
 0.5, 1.0, 150, NULL,
 'desidistrict', ARRAY['desi district kids chicken nuggets', 'desi district desi nuggets'],
 'indian', 'Desi District', 1, '360 cal per serving (150g). Indian-spiced chicken nuggets.', TRUE,
 550.0, 45.0, 3.0, 0.1, 160.0, 15.0, 1.0, 5.0, 0.0, 2.0, 16.0, 1.0, 120.0, 14.0, 0.0),

('desi_district_kids_chicken_burger', 'Desi District Kids Chicken Burger', 230.0, 12.0, 22.0, 11.0,
 1.0, 2.0, 180, 180,
 'desidistrict', ARRAY['desi district kids burger', 'desi district kids chicken burger'],
 'indian', 'Desi District', 1, '414 cal per burger (180g).', TRUE,
 520.0, 35.0, 2.8, 0.0, 150.0, 25.0, 1.2, 8.0, 1.0, 2.0, 16.0, 0.8, 85.0, 10.0, 0.0),

('desi_district_kids_veg_fried_rice', 'Desi District Kids Veg Fried Rice', 135.0, 3.0, 22.0, 3.5,
 1.0, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district kids veg fried rice'],
 'indian', 'Desi District', 1, '270 cal per serving (200g).', TRUE,
 380.0, 0.0, 0.6, 0.0, 100.0, 15.0, 0.5, 20.0, 2.0, 0.0, 12.0, 0.3, 40.0, 3.0, 0.0),

('desi_district_kids_samosa', 'Desi District Kids Samosa', 260.0, 4.5, 28.0, 14.0,
 2.0, 1.0, 100, 50,
 'desidistrict', ARRAY['desi district kids samosa'],
 'indian', 'Desi District', 2, '260 cal per 2 pieces (100g).', TRUE,
 420.0, 0.0, 3.0, 0.2, 180.0, 15.0, 1.2, 2.0, 3.0, 0.0, 14.0, 0.3, 45.0, 2.0, 0.0),

-- ==========================================
-- DESI DISTRICT - MANDI (new items)
-- ==========================================

('desi_district_gobi_mandi', 'Desi District Gobi Mandi', 130.0, 3.5, 18.0, 5.0,
 2.0, 1.0, 450, NULL,
 'desidistrict', ARRAY['desi district gobi mandi', 'desi district cauliflower mandi'],
 'indian', 'Desi District', 1, '585 cal per serving (450g). Crispy cauliflower with Mandi rice.', TRUE,
 380.0, 0.0, 0.8, 0.0, 210.0, 22.0, 0.7, 2.0, 25.0, 0.0, 14.0, 0.3, 40.0, 2.0, 0.0),

('desi_district_fish_mandi', 'Desi District Fish Mandi', 142.0, 8.5, 17.0, 4.5,
 0.5, 0.5, 480, NULL,
 'desidistrict', ARRAY['desi district fish mandi'],
 'indian', 'Desi District', 1, '682 cal per serving (480g). Flaky fish with Mandi rice.', TRUE,
 420.0, 40.0, 0.8, 0.0, 220.0, 25.0, 0.8, 8.0, 1.0, 15.0, 22.0, 0.5, 130.0, 25.0, 0.15),

-- ==========================================
-- DESI DISTRICT - NON-VEG CURRIES (new items)
-- ==========================================

('desi_district_chicken_tikka_masala', 'Desi District Chicken Tikka Masala', 165.0, 13.0, 6.0, 10.0,
 0.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district chicken tikka masala', 'desi district ctm'],
 'indian', 'Desi District', 1, '495 cal per bowl (300g). Tandoori chicken in creamy tomato gravy.', TRUE,
 480.0, 50.0, 3.5, 0.0, 220.0, 35.0, 1.2, 40.0, 3.0, 3.0, 22.0, 1.3, 130.0, 16.0, 0.0),

('desi_district_kadai_chicken', 'Desi District Kadai Chicken Curry', 155.0, 13.0, 5.0, 9.5,
 1.0, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district kadai chicken', 'desi district kadhai chicken'],
 'indian', 'Desi District', 1, '465 cal per bowl (300g). Chicken in spicy tomato-capsicum gravy.', TRUE,
 460.0, 48.0, 2.8, 0.0, 240.0, 25.0, 1.3, 50.0, 12.0, 3.0, 22.0, 1.2, 125.0, 15.0, 0.0),

('desi_district_chicken_korma', 'Desi District Chicken Korma', 160.0, 11.0, 6.0, 10.5,
 0.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district chicken korma'],
 'indian', 'Desi District', 1, '480 cal per bowl (300g). Chicken in creamy cashew gravy.', TRUE,
 420.0, 45.0, 3.5, 0.0, 200.0, 30.0, 1.0, 20.0, 1.0, 3.0, 22.0, 1.2, 130.0, 15.0, 0.0),

('desi_district_hyderabad_chicken', 'Desi District Hyderabad Chicken Curry', 150.0, 12.5, 4.5, 9.0,
 0.5, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district hyderabad chicken', 'desi district hyderabadi chicken curry'],
 'indian', 'Desi District', 1, '450 cal per bowl (300g). Chicken in spicy tamarind gravy.', TRUE,
 470.0, 50.0, 2.5, 0.0, 230.0, 22.0, 1.3, 15.0, 2.0, 3.0, 22.0, 1.3, 130.0, 16.0, 0.0),

('desi_district_chettinad_chicken', 'Desi District Chettinad Chicken Curry', 155.0, 13.0, 4.0, 9.5,
 1.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district chettinad chicken'],
 'indian', 'Desi District', 1, '465 cal per bowl (300g). Fiery chicken with Chettinad spices.', TRUE,
 450.0, 50.0, 2.5, 0.0, 240.0, 22.0, 1.5, 10.0, 2.0, 3.0, 24.0, 1.3, 135.0, 16.0, 0.0),

('desi_district_kadai_shrimp', 'Desi District Kadai Shrimp Curry', 140.0, 12.0, 5.0, 8.0,
 1.0, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district kadai shrimp', 'desi district kadai prawn'],
 'indian', 'Desi District', 1, '420 cal per bowl (300g). Shrimp in tomato-onion gravy with peppers.', TRUE,
 500.0, 85.0, 1.5, 0.0, 250.0, 45.0, 1.5, 30.0, 10.0, 2.0, 28.0, 1.0, 150.0, 22.0, 0.1),

('desi_district_achari_shrimp', 'Desi District Achari Shrimp Curry', 138.0, 12.0, 5.0, 7.5,
 0.5, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district achari shrimp', 'desi district achari prawn'],
 'indian', 'Desi District', 1, '414 cal per bowl (300g). Shrimp in pickling spices.', TRUE,
 510.0, 85.0, 1.2, 0.0, 240.0, 42.0, 1.5, 15.0, 3.0, 2.0, 27.0, 1.0, 148.0, 22.0, 0.1),

('desi_district_hyderabad_shrimp', 'Desi District Hyderabad Shrimp Curry', 142.0, 12.0, 5.0, 8.0,
 0.5, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district hyderabad shrimp', 'desi district hyderabadi shrimp'],
 'indian', 'Desi District', 1, '426 cal per bowl (300g). Shrimp in spicy tamarind gravy.', TRUE,
 500.0, 85.0, 1.5, 0.0, 245.0, 44.0, 1.5, 12.0, 2.0, 2.0, 28.0, 1.0, 150.0, 22.0, 0.1),

('desi_district_chettinad_shrimp', 'Desi District Chettinad Shrimp Curry', 145.0, 12.0, 4.5, 8.5,
 1.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district chettinad shrimp', 'desi district chettinad prawn'],
 'indian', 'Desi District', 1, '435 cal per bowl (300g). Fiery shrimp with Chettinad pepper.', TRUE,
 490.0, 85.0, 1.5, 0.0, 250.0, 45.0, 1.6, 10.0, 2.0, 2.0, 30.0, 1.0, 155.0, 23.0, 0.1),

('desi_district_achari_chicken', 'Desi District Achari Chicken Curry', 148.0, 12.5, 4.5, 9.0,
 0.5, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district achari chicken'],
 'indian', 'Desi District', 1, '444 cal per bowl (300g). Tangy chicken in pickling spices.', TRUE,
 460.0, 48.0, 2.5, 0.0, 220.0, 22.0, 1.2, 12.0, 2.0, 3.0, 22.0, 1.2, 128.0, 15.0, 0.0),

('desi_district_gongura_chicken', 'Desi District Gongura Chicken Curry', 150.0, 12.0, 5.0, 9.0,
 1.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district gongura chicken'],
 'indian', 'Desi District', 1, '450 cal per bowl (300g). Chicken with tangy sorrel leaves.', TRUE,
 440.0, 48.0, 2.5, 0.0, 230.0, 25.0, 1.5, 60.0, 10.0, 3.0, 24.0, 1.2, 130.0, 15.0, 0.0),

('desi_district_mutton_korma', 'Desi District Mutton Korma', 175.0, 12.0, 5.0, 12.0,
 0.5, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district mutton korma', 'desi district goat korma'],
 'indian', 'Desi District', 1, '525 cal per bowl (300g). Tender mutton in creamy cashew gravy.', TRUE,
 430.0, 55.0, 4.5, 0.0, 220.0, 28.0, 1.5, 18.0, 1.0, 3.0, 22.0, 2.5, 140.0, 12.0, 0.0),

('desi_district_gongura_mutton', 'Desi District Gongura Mutton Curry', 170.0, 13.0, 5.0, 11.0,
 1.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district gongura mutton'],
 'indian', 'Desi District', 1, '510 cal per bowl (300g). Mutton with tangy sorrel leaves.', TRUE,
 440.0, 55.0, 4.0, 0.0, 240.0, 25.0, 1.8, 55.0, 10.0, 3.0, 24.0, 2.5, 145.0, 12.0, 0.0),

('desi_district_kadai_mutton', 'Desi District Kadai Mutton', 168.0, 13.0, 5.0, 11.0,
 1.0, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district kadai mutton', 'desi district kadhai mutton'],
 'indian', 'Desi District', 1, '504 cal per bowl (300g). Mutton in spicy tomato-capsicum gravy.', TRUE,
 460.0, 55.0, 4.0, 0.0, 250.0, 25.0, 1.6, 45.0, 12.0, 3.0, 22.0, 2.5, 140.0, 12.0, 0.0),

('desi_district_achari_mutton', 'Desi District Achari Mutton Curry', 170.0, 13.0, 4.5, 11.0,
 0.5, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district achari mutton'],
 'indian', 'Desi District', 1, '510 cal per bowl (300g). Mutton in pickling spices.', TRUE,
 460.0, 55.0, 4.0, 0.0, 230.0, 24.0, 1.6, 12.0, 2.0, 3.0, 22.0, 2.5, 142.0, 12.0, 0.0),

('desi_district_chettinad_mutton', 'Desi District Chettinad Mutton Curry', 172.0, 13.0, 4.0, 11.5,
 1.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district chettinad mutton'],
 'indian', 'Desi District', 1, '516 cal per bowl (300g). Fiery mutton with Chettinad spices.', TRUE,
 450.0, 55.0, 4.2, 0.0, 250.0, 24.0, 1.8, 10.0, 2.0, 3.0, 24.0, 2.5, 145.0, 12.0, 0.0),

('desi_district_shrimp_korma', 'Desi District Shrimp Korma', 148.0, 11.0, 6.0, 9.0,
 0.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district shrimp korma', 'desi district prawn korma'],
 'indian', 'Desi District', 1, '444 cal per bowl (300g). Juicy shrimp in creamy cashew gravy.', TRUE,
 440.0, 80.0, 3.0, 0.0, 230.0, 50.0, 1.2, 18.0, 1.0, 2.0, 28.0, 1.0, 150.0, 22.0, 0.1),

('desi_district_gongura_shrimp', 'Desi District Gongura Shrimp Curry', 140.0, 12.0, 5.0, 8.0,
 1.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district gongura shrimp', 'desi district gongura prawn'],
 'indian', 'Desi District', 1, '420 cal per bowl (300g). Shrimp with tangy sorrel leaves.', TRUE,
 450.0, 80.0, 1.2, 0.0, 240.0, 45.0, 1.5, 55.0, 10.0, 2.0, 28.0, 1.0, 148.0, 22.0, 0.1),

-- ==========================================
-- DESI DISTRICT - NON-VEG APPETIZERS (new items)
-- ==========================================

('desi_district_apollo_fish', 'Desi District Apollo Fish', 210.0, 14.0, 12.0, 12.0,
 0.5, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district apollo fish'],
 'indian', 'Desi District', 1, '420 cal per serving (200g). Crispy fried fish in tangy Andhra sauce.', TRUE,
 520.0, 40.0, 2.0, 0.0, 200.0, 20.0, 1.0, 8.0, 3.0, 12.0, 18.0, 0.5, 120.0, 22.0, 0.1),

('desi_district_chicken_pakoda', 'Desi District Chicken Pakoda', 215.0, 14.0, 14.0, 12.0,
 1.0, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district chicken pakoda', 'desi district chicken pakora'],
 'indian', 'Desi District', 1, '430 cal per serving (200g). Crispy chicken in spiced gram flour batter.', TRUE,
 500.0, 50.0, 2.5, 0.0, 180.0, 20.0, 1.5, 8.0, 1.0, 2.0, 18.0, 1.0, 115.0, 14.0, 0.0),

('desi_district_pepper_chicken', 'Desi District Pepper Chicken', 195.0, 18.0, 5.0, 11.0,
 0.5, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district pepper chicken boneless', 'desi district pepper chicken fry'],
 'indian', 'Desi District', 1, '390 cal per serving (200g). Dry-fried chicken with black pepper.', TRUE,
 480.0, 55.0, 2.5, 0.0, 230.0, 15.0, 1.5, 5.0, 2.0, 3.0, 22.0, 1.5, 140.0, 18.0, 0.0),

('desi_district_fish_fry', 'Desi District Fish Fry', 200.0, 15.0, 10.0, 11.0,
 0.5, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district fish fry'],
 'indian', 'Desi District', 1, '400 cal per serving (200g). Pan-fried marinated fish.', TRUE,
 480.0, 45.0, 1.8, 0.0, 210.0, 30.0, 1.0, 10.0, 1.0, 15.0, 20.0, 0.5, 130.0, 25.0, 0.2),

('desi_district_prawn_fry', 'Desi District Prawn Fry', 195.0, 16.0, 8.0, 11.0,
 0.3, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district prawn fry', 'desi district shrimp fry'],
 'indian', 'Desi District', 1, '390 cal per serving (200g).', TRUE,
 520.0, 90.0, 1.5, 0.0, 200.0, 45.0, 1.2, 8.0, 1.0, 2.0, 28.0, 1.0, 150.0, 22.0, 0.1),

('desi_district_mutton_fry', 'Desi District Mutton Fry', 210.0, 16.0, 5.0, 14.0,
 0.5, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district mutton fry', 'desi district goat fry'],
 'indian', 'Desi District', 1, '420 cal per serving (200g). Dry-roasted mutton with spices.', TRUE,
 440.0, 60.0, 5.5, 0.0, 240.0, 12.0, 2.0, 0.0, 0.0, 3.0, 20.0, 3.0, 140.0, 10.0, 0.0),

('desi_district_goat_liver_fry', 'Desi District Goat Liver Fry', 185.0, 20.0, 5.0, 9.5,
 0.5, 0.5, 200, NULL,
 'desidistrict', ARRAY['desi district goat liver fry', 'desi district liver fry'],
 'indian', 'Desi District', 1, '370 cal per serving (200g). Pan-fried goat liver with spices.', TRUE,
 380.0, 300.0, 3.0, 0.0, 280.0, 8.0, 8.0, 5000.0, 2.0, 3.0, 16.0, 4.0, 350.0, 30.0, 0.0),

('desi_district_chicken_wings', 'Desi District Chicken Wings', 225.0, 17.0, 8.0, 14.0,
 0.3, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district chicken wings'],
 'indian', 'Desi District', 1, '450 cal per serving (200g). Spiced chicken wings.', TRUE,
 520.0, 65.0, 3.5, 0.1, 170.0, 15.0, 1.0, 20.0, 0.0, 3.0, 16.0, 1.5, 110.0, 14.0, 0.0),

('desi_district_chicken_65_bone_in', 'Desi District Chicken 65 (Bone-In)', 210.0, 15.0, 10.0, 12.5,
 0.5, 1.0, 220, NULL,
 'desidistrict', ARRAY['desi district chicken 65 bone in', 'desi district bone in chicken 65'],
 'indian', 'Desi District', 1, '462 cal per serving (220g). Bone-in version.', TRUE,
 480.0, 55.0, 2.8, 0.0, 180.0, 15.0, 1.0, 10.0, 1.0, 2.0, 18.0, 1.2, 115.0, 14.0, 0.0),

('desi_district_egg_bhurji', 'Desi District Egg Bhurji', 155.0, 11.0, 3.0, 11.0,
 0.5, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district egg bhurji', 'desi district egg bhurjee'],
 'indian', 'Desi District', 1, '310 cal per serving (200g). Spiced scrambled eggs.', TRUE,
 450.0, 350.0, 3.0, 0.0, 160.0, 45.0, 1.5, 150.0, 2.0, 20.0, 10.0, 1.0, 160.0, 18.0, 0.0),

-- ==========================================
-- DESI DISTRICT - RICE
-- ==========================================

('desi_district_kodi_pappu_charu', 'Desi District Kodi Pappu Charu', 100.0, 6.5, 10.0, 3.5,
 1.5, 0.5, 400, NULL,
 'desidistrict', ARRAY['desi district kodi pappu charu', 'desi district chicken dal rice'],
 'indian', 'Desi District', 1, '400 cal per serving (400g). Chicken & lentil soupy rice, Andhra-style.', TRUE,
 420.0, 30.0, 0.8, 0.0, 200.0, 22.0, 1.2, 15.0, 3.0, 2.0, 18.0, 1.0, 100.0, 10.0, 0.0),

('desi_district_curd_rice', 'Desi District Curd Rice', 100.0, 3.5, 16.0, 2.5,
 0.3, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district curd rice', 'desi district dahi chawal'],
 'indian', 'Desi District', 1, '300 cal per serving (300g). Creamy yogurt rice.', TRUE,
 350.0, 8.0, 1.2, 0.0, 130.0, 60.0, 0.3, 10.0, 0.5, 2.0, 12.0, 0.4, 80.0, 5.0, 0.0),

('desi_district_mamsam_pappu_charu', 'Desi District Mamsam Pappu Charu', 110.0, 7.5, 10.0, 4.0,
 1.5, 0.5, 400, NULL,
 'desidistrict', ARRAY['desi district mamsam pappu charu', 'desi district mutton dal rice'],
 'indian', 'Desi District', 1, '440 cal per serving (400g). Mutton & lentil soup with rice.', TRUE,
 430.0, 35.0, 1.2, 0.0, 210.0, 22.0, 1.5, 5.0, 2.0, 3.0, 18.0, 1.5, 110.0, 10.0, 0.0),

('desi_district_egg_fried_rice', 'Desi District Egg Fried Rice', 145.0, 5.5, 21.0, 4.5,
 0.5, 0.5, 350, NULL,
 'desidistrict', ARRAY['desi district egg fried rice plain'],
 'indian', 'Desi District', 1, '508 cal per serving (350g).', TRUE,
 490.0, 85.0, 1.0, 0.0, 125.0, 22.0, 0.9, 38.0, 1.0, 5.0, 13.0, 0.6, 68.0, 9.0, 0.0),

('desi_district_veg_fried_rice', 'Desi District Veg Fried Rice', 135.0, 3.5, 22.0, 3.5,
 1.0, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district veg fried rice plain'],
 'indian', 'Desi District', 1, '473 cal per serving (350g).', TRUE,
 470.0, 0.0, 0.6, 0.0, 115.0, 18.0, 0.7, 22.0, 3.0, 0.0, 14.0, 0.4, 45.0, 4.0, 0.0),

('desi_district_chicken_fried_rice', 'Desi District Chicken Fried Rice', 155.0, 7.0, 20.0, 5.5,
 0.5, 1.0, 350, NULL,
 'desidistrict', ARRAY['desi district chicken fried rice plain'],
 'indian', 'Desi District', 1, '543 cal per serving (350g).', TRUE,
 500.0, 35.0, 1.0, 0.0, 145.0, 16.0, 0.9, 12.0, 1.0, 2.0, 17.0, 0.8, 90.0, 11.0, 0.0),

-- ==========================================
-- DESI DISTRICT - DRINKS
-- ==========================================

('desi_district_salt_lassi', 'Desi District Salt Lassi', 45.0, 2.0, 4.0, 2.0,
 0.0, 3.5, 350, NULL,
 'desidistrict', ARRAY['desi district salt lassi', 'desi district salted lassi'],
 'drinks', 'Desi District', 1, '158 cal per glass (350g). Refreshing yogurt drink.', TRUE,
 280.0, 8.0, 1.2, 0.0, 150.0, 80.0, 0.1, 10.0, 1.0, 3.0, 10.0, 0.4, 70.0, 3.0, 0.0),

-- ==========================================
-- DESI DISTRICT - SNACKS
-- ==========================================

('desi_district_samosa', 'Desi District Samosa', 260.0, 4.5, 28.0, 14.0,
 2.0, 1.0, 150, 50,
 'desidistrict', ARRAY['desi district samosa'],
 'indian', 'Desi District', 3, '390 cal per 3 pieces (150g). Crispy pastry with spiced potatoes.', TRUE,
 420.0, 0.0, 3.0, 0.2, 180.0, 15.0, 1.2, 2.0, 3.0, 0.0, 14.0, 0.3, 45.0, 2.0, 0.0),

-- ==========================================
-- DESI DISTRICT - TANDOORI / KEBABS (new items)
-- ==========================================

('desi_district_tandoori_chicken_half', 'Desi District Tandoori Chicken (Half)', 160.0, 22.0, 3.0, 7.0,
 0.0, 0.5, 280, NULL,
 'desidistrict', ARRAY['desi district tandoori chicken half', 'desi district half tandoori'],
 'indian', 'Desi District', 1, '448 cal per half (280g). Yogurt-marinated chicken roasted in tandoor.', TRUE,
 500.0, 75.0, 2.0, 0.0, 250.0, 18.0, 1.2, 25.0, 0.0, 3.0, 22.0, 1.8, 160.0, 20.0, 0.0),

('desi_district_tandoori_chicken_full', 'Desi District Tandoori Chicken (Full)', 160.0, 22.0, 3.0, 7.0,
 0.0, 0.5, 560, NULL,
 'desidistrict', ARRAY['desi district tandoori chicken full', 'desi district full tandoori'],
 'indian', 'Desi District', 1, '896 cal per full (560g). Serves 2-3.', TRUE,
 500.0, 75.0, 2.0, 0.0, 250.0, 18.0, 1.2, 25.0, 0.0, 3.0, 22.0, 1.8, 160.0, 20.0, 0.0),

('desi_district_chicken_tikka_kebab', 'Desi District Chicken Tikka Kebab', 180.0, 20.0, 4.0, 9.0,
 0.5, 1.0, 175, 25,
 'desidistrict', ARRAY['desi district chicken tikka kebab', 'desi district tikka kebab'],
 'indian', 'Desi District', 7, '315 cal per 7 pieces (175g). Tandoor-grilled marinated chicken.', TRUE,
 480.0, 60.0, 2.5, 0.0, 230.0, 15.0, 1.0, 15.0, 1.0, 3.0, 22.0, 1.5, 150.0, 18.0, 0.0),

('desi_district_hariyali_chicken_kebab', 'Desi District Hariyali Chicken Kebab', 175.0, 19.0, 4.0, 9.0,
 0.5, 1.0, 175, 25,
 'desidistrict', ARRAY['desi district hariyali kebab', 'desi district hariyali chicken'],
 'indian', 'Desi District', 7, '306 cal per 7 pieces (175g). Green herb-marinated chicken.', TRUE,
 470.0, 58.0, 2.2, 0.0, 240.0, 18.0, 1.5, 80.0, 8.0, 3.0, 24.0, 1.5, 148.0, 17.0, 0.0),

('desi_district_gongura_chicken_kebab', 'Desi District Gongura Chicken Kebab', 178.0, 19.0, 4.0, 9.0,
 0.5, 1.0, 175, 25,
 'desidistrict', ARRAY['desi district gongura kebab', 'desi district gongura chicken kabab'],
 'indian', 'Desi District', 7, '311 cal per 7 pieces (175g). Gongura-marinated chicken, Andhra-style.', TRUE,
 460.0, 58.0, 2.2, 0.0, 235.0, 18.0, 1.5, 55.0, 8.0, 3.0, 24.0, 1.5, 148.0, 17.0, 0.0),

('desi_district_murgh_malai_kebab', 'Desi District Murgh Malai Chicken Kebab', 185.0, 18.0, 4.0, 10.5,
 0.3, 1.0, 175, 25,
 'desidistrict', ARRAY['desi district murgh malai kebab', 'desi district malai chicken kebab'],
 'indian', 'Desi District', 7, '324 cal per 7 pieces (175g). Creamy chicken kebabs in yogurt & cream.', TRUE,
 440.0, 62.0, 4.0, 0.0, 210.0, 25.0, 0.8, 30.0, 1.0, 4.0, 20.0, 1.3, 140.0, 17.0, 0.0),

('desi_district_paneer_tikka_kebab', 'Desi District Paneer Tikka Kebab', 190.0, 12.0, 6.0, 13.0,
 0.5, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district paneer tikka kebab'],
 'indian', 'Desi District', 1, '380 cal per serving (200g). Marinated paneer grilled in tandoor.', TRUE,
 420.0, 15.0, 5.5, 0.0, 100.0, 120.0, 0.8, 30.0, 3.0, 0.0, 16.0, 1.0, 140.0, 6.0, 0.0),

('desi_district_malai_paneer_tikka', 'Desi District Malai Paneer Tikka Kebab', 200.0, 11.0, 5.0, 15.0,
 0.3, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district malai paneer tikka'],
 'indian', 'Desi District', 1, '400 cal per serving (200g). Creamy paneer tikka with cashew paste.', TRUE,
 400.0, 18.0, 6.5, 0.0, 95.0, 130.0, 0.7, 35.0, 1.0, 0.0, 18.0, 1.0, 145.0, 6.0, 0.0),

-- ==========================================
-- DESI DISTRICT - VEG APPETIZERS (new items)
-- ==========================================

('desi_district_paneer_555', 'Desi District Paneer 555', 225.0, 10.0, 10.0, 16.0,
 0.5, 1.5, 200, NULL,
 'desidistrict', ARRAY['desi district paneer 555', 'desi district paneer five five five'],
 'indian', 'Desi District', 1, '450 cal per serving (200g). Paneer in 5-spice blend with cashew paste.', TRUE,
 450.0, 15.0, 6.0, 0.0, 100.0, 110.0, 0.8, 25.0, 2.0, 0.0, 16.0, 0.8, 120.0, 5.0, 0.0),

('desi_district_paneer_majestic', 'Desi District Paneer Majestic', 220.0, 9.5, 10.0, 15.5,
 0.5, 2.0, 200, NULL,
 'desidistrict', ARRAY['desi district paneer majestic'],
 'indian', 'Desi District', 1, '440 cal per serving (200g). Paneer in creamy yogurt-based gravy.', TRUE,
 440.0, 15.0, 5.5, 0.0, 105.0, 115.0, 0.7, 28.0, 2.0, 0.0, 15.0, 0.8, 118.0, 5.0, 0.0),

('desi_district_chilli_paneer', 'Desi District Chilli Paneer', 215.0, 9.0, 10.0, 16.0,
 1.0, 2.0, 200, NULL,
 'desidistrict', ARRAY['desi district chilli paneer', 'desi district chili paneer'],
 'indian', 'Desi District', 1, '430 cal per serving (200g). Crispy paneer in spicy garlic-chili sauce.', TRUE,
 530.0, 15.0, 5.5, 0.0, 110.0, 105.0, 0.8, 22.0, 8.0, 0.0, 14.0, 0.8, 115.0, 5.0, 0.0),

('desi_district_baby_corn_manchurian', 'Desi District Baby Corn Manchurian', 160.0, 3.5, 18.0, 8.0,
 1.5, 3.0, 200, NULL,
 'desidistrict', ARRAY['desi district baby corn manchurian'],
 'indian', 'Desi District', 1, '320 cal per serving (200g).', TRUE,
 520.0, 0.0, 1.2, 0.0, 180.0, 15.0, 0.6, 5.0, 4.0, 0.0, 10.0, 0.3, 35.0, 2.0, 0.0),

('desi_district_veg_65', 'Desi District Veg 65', 175.0, 4.0, 16.0, 10.0,
 2.0, 1.5, 200, NULL,
 'desidistrict', ARRAY['desi district veg 65', 'desi district vegetable 65'],
 'indian', 'Desi District', 1, '350 cal per serving (200g). Deep-fried spiced veggies.', TRUE,
 440.0, 0.0, 1.8, 0.0, 200.0, 20.0, 0.8, 30.0, 8.0, 0.0, 14.0, 0.4, 45.0, 3.0, 0.0),

('desi_district_mushroom_65', 'Desi District Mushroom 65', 170.0, 5.0, 12.0, 11.0,
 1.5, 1.0, 200, NULL,
 'desidistrict', ARRAY['desi district mushroom 65'],
 'indian', 'Desi District', 1, '340 cal per serving (200g). Deep-fried spiced mushrooms.', TRUE,
 450.0, 0.0, 2.0, 0.0, 310.0, 8.0, 1.2, 0.0, 2.0, 0.0, 12.0, 0.8, 85.0, 8.0, 0.0),

('desi_district_paneer_65', 'Desi District Paneer 65', 230.0, 10.0, 12.0, 16.0,
 0.5, 1.5, 200, NULL,
 'desidistrict', ARRAY['desi district paneer 65'],
 'indian', 'Desi District', 1, '460 cal per serving (200g). Deep-fried spiced paneer.', TRUE,
 460.0, 15.0, 6.0, 0.0, 95.0, 110.0, 0.7, 25.0, 1.0, 0.0, 14.0, 0.8, 115.0, 5.0, 0.0),

-- ==========================================
-- DESI DISTRICT - VEG CURRIES (new items)
-- ==========================================

('desi_district_paneer_tikka_masala', 'Desi District Paneer Tikka Masala', 170.0, 8.0, 7.0, 12.0,
 0.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district paneer tikka masala'],
 'indian', 'Desi District', 1, '510 cal per bowl (300g). Grilled paneer in creamy tomato gravy.', TRUE,
 450.0, 15.0, 5.0, 0.0, 180.0, 120.0, 1.0, 40.0, 4.0, 0.0, 18.0, 0.8, 130.0, 5.0, 0.0),

('desi_district_gutti_vankaya_kura', 'Desi District Gutti Vankaya Kura', 90.0, 2.0, 8.0, 5.5,
 2.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district gutti vankaya kura', 'desi district stuffed eggplant curry'],
 'indian', 'Desi District', 1, '270 cal per bowl (300g). Baby eggplants in tamarind gravy.', TRUE,
 380.0, 0.0, 0.8, 0.0, 280.0, 15.0, 0.8, 5.0, 3.0, 0.0, 14.0, 0.3, 35.0, 1.0, 0.0),

('desi_district_chole_masala', 'Desi District Chole Masala', 120.0, 6.0, 16.0, 3.5,
 4.0, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district chole masala', 'desi district chana masala'],
 'indian', 'Desi District', 1, '360 cal per bowl (300g). Chickpeas in spicy onion-tomato gravy.', TRUE,
 450.0, 0.0, 0.5, 0.0, 250.0, 40.0, 2.5, 5.0, 3.0, 0.0, 30.0, 1.0, 100.0, 4.0, 0.0),

('desi_district_malai_kofta', 'Desi District Malai Kofta', 165.0, 5.0, 12.0, 11.0,
 1.0, 3.0, 300, NULL,
 'desidistrict', ARRAY['desi district malai kofta'],
 'indian', 'Desi District', 1, '495 cal per bowl (300g). Veggie balls in cashew-cream gravy.', TRUE,
 420.0, 10.0, 4.0, 0.0, 150.0, 45.0, 0.8, 30.0, 2.0, 0.0, 16.0, 0.5, 70.0, 3.0, 0.0),

('desi_district_shahi_paneer', 'Desi District Shahi Paneer Curry', 180.0, 8.0, 7.0, 13.5,
 0.5, 2.5, 300, NULL,
 'desidistrict', ARRAY['desi district shahi paneer'],
 'indian', 'Desi District', 1, '540 cal per bowl (300g). Paneer in royal cashew-cream gravy with saffron.', TRUE,
 430.0, 18.0, 6.0, 0.0, 120.0, 125.0, 0.7, 35.0, 1.0, 0.0, 18.0, 0.8, 135.0, 5.0, 0.0),

('desi_district_kadai_paneer', 'Desi District Kadai Paneer Curry', 155.0, 7.0, 7.0, 11.5,
 1.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district kadai paneer'],
 'indian', 'Desi District', 1, '465 cal per bowl (300g). Paneer in tomato-capsicum gravy.', TRUE,
 440.0, 15.0, 4.5, 0.0, 200.0, 110.0, 1.0, 50.0, 15.0, 0.0, 16.0, 0.8, 120.0, 5.0, 0.0),

('desi_district_paneer_butter_masala', 'Desi District Paneer Butter Masala', 175.0, 7.0, 8.0, 13.0,
 1.0, 2.5, 300, NULL,
 'desidistrict', ARRAY['desi district paneer butter masala', 'desi district pbm'],
 'indian', 'Desi District', 1, '525 cal per bowl (300g). Paneer in rich buttery tomato gravy.', TRUE,
 450.0, 18.0, 5.5, 0.0, 160.0, 115.0, 0.8, 45.0, 3.0, 0.0, 16.0, 0.7, 125.0, 5.0, 0.0),

('desi_district_veg_korma', 'Desi District Veg Korma', 115.0, 3.5, 10.0, 7.0,
 1.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district veg korma', 'desi district vegetable korma'],
 'indian', 'Desi District', 1, '345 cal per bowl (300g). Mixed veggies in creamy cashew gravy.', TRUE,
 400.0, 5.0, 2.5, 0.0, 180.0, 30.0, 0.8, 40.0, 5.0, 0.0, 16.0, 0.4, 55.0, 3.0, 0.0),

('desi_district_egg_korma', 'Desi District Egg Korma', 130.0, 7.0, 6.0, 9.0,
 0.5, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district egg korma'],
 'indian', 'Desi District', 1, '390 cal per bowl (300g). Boiled eggs in rich cashew gravy.', TRUE,
 420.0, 180.0, 3.0, 0.0, 150.0, 40.0, 1.2, 80.0, 1.0, 12.0, 10.0, 0.8, 110.0, 14.0, 0.0),

('desi_district_achari_paneer', 'Desi District Achari Paneer Curry', 160.0, 7.5, 7.0, 11.5,
 0.5, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district achari paneer curry'],
 'indian', 'Desi District', 1, '480 cal per bowl (300g). Paneer with pickling spices.', TRUE,
 470.0, 15.0, 4.5, 0.0, 140.0, 110.0, 0.8, 20.0, 2.0, 0.0, 16.0, 0.8, 125.0, 5.0, 0.0),

('desi_district_dal_tadka', 'Desi District Dal Tadka', 90.0, 5.5, 12.0, 2.5,
 3.0, 1.0, 300, NULL,
 'desidistrict', ARRAY['desi district dal tadka', 'desi district dal fry'],
 'indian', 'Desi District', 1, '270 cal per bowl (300g). Tempered lentils.', TRUE,
 380.0, 0.0, 0.5, 0.0, 280.0, 25.0, 2.0, 5.0, 2.0, 0.0, 25.0, 0.8, 120.0, 3.0, 0.0),

('desi_district_palak_paneer', 'Desi District Palak Paneer', 140.0, 7.5, 6.0, 10.0,
 2.0, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district palak paneer', 'desi district spinach paneer'],
 'indian', 'Desi District', 1, '420 cal per bowl (300g). Paneer in creamy spinach gravy.', TRUE,
 430.0, 15.0, 4.0, 0.0, 350.0, 140.0, 2.5, 400.0, 15.0, 0.0, 40.0, 0.8, 120.0, 5.0, 0.0),

-- ==========================================
-- DESI DISTRICT - HOME STYLE CURRIES
-- ==========================================

('desi_district_sambar', 'Desi District Sambar', 55.0, 3.0, 8.0, 1.0,
 2.0, 1.5, 300, NULL,
 'desidistrict', ARRAY['desi district sambar'],
 'indian', 'Desi District', 1, '165 cal per bowl (300g). South Indian lentil stew.', TRUE,
 380.0, 0.0, 0.2, 0.0, 250.0, 20.0, 1.5, 15.0, 5.0, 0.0, 20.0, 0.5, 60.0, 2.0, 0.0),

('desi_district_roti_pachadi', 'Desi District Roti Pachadi', 80.0, 3.0, 6.0, 5.0,
 1.5, 1.0, 230, NULL,
 'desidistrict', ARRAY['desi district roti pachadi'],
 'indian', 'Desi District', 1, '184 cal per 8oz (230g). Andhra-style roasted lentil chutney.', TRUE,
 350.0, 0.0, 0.8, 0.0, 180.0, 15.0, 1.0, 20.0, 3.0, 0.0, 15.0, 0.5, 50.0, 2.0, 0.0),

('desi_district_veg_curry', 'Desi District Veg Curry', 80.0, 2.5, 10.0, 3.5,
 2.0, 2.0, 300, NULL,
 'desidistrict', ARRAY['desi district veg curry', 'desi district vegetable curry'],
 'indian', 'Desi District', 1, '240 cal per bowl (300g). Veggies in mildly spiced gravy.', TRUE,
 380.0, 0.0, 0.6, 0.0, 200.0, 25.0, 0.8, 50.0, 8.0, 0.0, 14.0, 0.3, 40.0, 2.0, 0.0),

('desi_district_veg_fry', 'Desi District Veg Fry', 95.0, 2.5, 8.0, 6.0,
 2.0, 1.5, 200, NULL,
 'desidistrict', ARRAY['desi district veg fry', 'desi district vegetable fry'],
 'indian', 'Desi District', 1, '190 cal per serving (200g). Stir-fried veggies.', TRUE,
 350.0, 0.0, 0.8, 0.0, 220.0, 20.0, 0.7, 40.0, 10.0, 0.0, 14.0, 0.3, 38.0, 2.0, 0.0),

-- ==========================================
-- DESI DISTRICT - PLATTERS / THALI
-- ==========================================

('desi_district_chicken_curry_platter', 'Desi District Chicken Curry Platter', 140.0, 8.0, 16.0, 5.0,
 1.0, 1.0, 450, NULL,
 'desidistrict', ARRAY['desi district chicken platter', 'desi district chicken curry platter'],
 'indian', 'Desi District', 1, '630 cal per platter (450g). Chicken curry with rice and sides.', TRUE,
 450.0, 35.0, 1.5, 0.0, 180.0, 25.0, 1.2, 15.0, 2.0, 2.0, 18.0, 1.0, 100.0, 12.0, 0.0),

('desi_district_nonveg_thali', 'Desi District Non-Veg Thali', 130.0, 7.0, 14.0, 5.5,
 1.0, 2.0, 550, NULL,
 'desidistrict', ARRAY['desi district non veg thali', 'desi district nonveg thali'],
 'indian', 'Desi District', 1, '715 cal per thali (550g). Rice, dal, curry, non-veg item, sides.', TRUE,
 460.0, 35.0, 1.8, 0.0, 200.0, 30.0, 1.5, 20.0, 3.0, 2.0, 20.0, 1.0, 95.0, 10.0, 0.0),

('desi_district_nonveg_curry_combo', 'Desi District Non-Veg Curry Combo', 135.0, 7.5, 15.0, 5.0,
 1.0, 1.5, 500, NULL,
 'desidistrict', ARRAY['desi district non veg curry combo'],
 'indian', 'Desi District', 1, '675 cal per combo (500g). Rice with 2 non-veg curries.', TRUE,
 450.0, 38.0, 1.5, 0.0, 190.0, 28.0, 1.3, 18.0, 2.0, 2.0, 19.0, 1.0, 98.0, 11.0, 0.0)

ON CONFLICT (food_name_normalized) DO NOTHING;


-- ============================================================================
-- CHOWRASTA EXPANSION
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g
) VALUES

-- ==========================================
-- CHOWRASTA - BIRYANI (new items)
-- ==========================================

('chowrasta_kaju_paneer_biryani', 'Chowrasta Kaju Paneer Biryani', 158.0, 5.5, 18.0, 7.0,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta kaju paneer biryani', 'chowrasta cashew paneer biryani'],
 'indian', 'Chowrasta', 1, '664 cal per serving (420g). Paneer biryani with cashews.', TRUE,
 400.0, 12.0, 3.0, 0.0, 140.0, 70.0, 0.8, 25.0, 1.0, 0.0, 18.0, 0.7, 95.0, 5.0, 0.0),

('chowrasta_ghee_roast_mutton_biryani', 'Chowrasta Ghee Roast Mutton Biryani', 180.0, 9.0, 17.0, 8.5,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta ghee roast mutton biryani'],
 'indian', 'Chowrasta', 1, '810 cal per serving (450g). Ghee-roasted mutton with biryani rice.', TRUE,
 460.0, 55.0, 3.5, 0.0, 210.0, 20.0, 1.5, 30.0, 0.0, 3.0, 22.0, 2.5, 140.0, 12.0, 0.0),

('chowrasta_veg_keema_biryani', 'Chowrasta Veg Keema Biryani', 138.0, 4.5, 20.0, 4.5,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta veg keema biryani'],
 'indian', 'Chowrasta', 1, '580 cal per serving (420g). Soy granule keema biryani.', TRUE,
 380.0, 0.0, 0.8, 0.0, 180.0, 25.0, 1.5, 15.0, 3.0, 0.0, 20.0, 0.5, 60.0, 3.0, 0.0),

('chowrasta_chicken_fry_biryani', 'Chowrasta Chicken Fry Biryani', 175.0, 8.0, 18.0, 7.5,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta chicken fry biryani'],
 'indian', 'Chowrasta', 1, '788 cal per serving (450g). With crispy fried chicken.', TRUE,
 470.0, 50.0, 2.2, 0.0, 170.0, 20.0, 1.2, 12.0, 1.0, 3.0, 20.0, 1.2, 110.0, 14.0, 0.0),

('chowrasta_chicken_65_biryani', 'Chowrasta Chicken 65 Biryani', 170.0, 8.0, 18.0, 7.0,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta chicken 65 biryani'],
 'indian', 'Chowrasta', 1, '765 cal per serving (450g).', TRUE,
 460.0, 48.0, 2.0, 0.0, 175.0, 18.0, 1.2, 10.0, 1.0, 3.0, 20.0, 1.2, 108.0, 14.0, 0.0),

('chowrasta_paneer_biryani', 'Chowrasta Paneer Biryani', 150.0, 5.5, 18.0, 6.0,
 1.0, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta paneer biryani'],
 'indian', 'Chowrasta', 1, '630 cal per serving (420g).', TRUE,
 390.0, 10.0, 2.5, 0.0, 130.0, 65.0, 0.7, 22.0, 1.0, 0.0, 17.0, 0.6, 88.0, 5.0, 0.0),

('chowrasta_gongura_goat_biryani', 'Chowrasta Gongura Goat Biryani', 175.0, 9.0, 17.0, 8.0,
 1.0, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta gongura goat biryani', 'chowrasta gongura mutton biryani'],
 'indian', 'Chowrasta', 1, '788 cal per serving (450g). Goat biryani with tangy sorrel.', TRUE,
 450.0, 55.0, 3.0, 0.0, 230.0, 22.0, 1.8, 50.0, 8.0, 3.0, 24.0, 2.5, 145.0, 12.0, 0.0),

('chowrasta_kaju_gobi_biryani', 'Chowrasta Kaju Gobi Biryani', 135.0, 3.5, 19.0, 5.0,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta kaju gobi biryani', 'chowrasta cashew cauliflower biryani'],
 'indian', 'Chowrasta', 1, '567 cal per serving (420g).', TRUE,
 370.0, 0.0, 0.8, 0.0, 200.0, 22.0, 0.8, 5.0, 20.0, 0.0, 14.0, 0.4, 50.0, 2.0, 0.0),

('chowrasta_goat_fry_biryani', 'Chowrasta Goat Fry Biryani', 180.0, 9.0, 17.0, 8.5,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta goat fry biryani', 'chowrasta mutton fry biryani'],
 'indian', 'Chowrasta', 1, '810 cal per serving (450g).', TRUE,
 460.0, 58.0, 3.2, 0.0, 210.0, 18.0, 1.6, 5.0, 0.0, 3.0, 20.0, 2.8, 145.0, 12.0, 0.0),

('chowrasta_goat_keema_biryani', 'Chowrasta Goat Keema Biryani', 172.0, 9.5, 17.0, 7.5,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta goat keema biryani', 'chowrasta goat kheema biryani'],
 'indian', 'Chowrasta', 1, '774 cal per serving (450g). With minced goat.', TRUE,
 450.0, 55.0, 2.8, 0.0, 220.0, 18.0, 1.8, 5.0, 0.0, 3.0, 22.0, 2.8, 148.0, 12.0, 0.0),

('chowrasta_egg_biryani', 'Chowrasta Egg Biryani', 145.0, 6.0, 18.0, 5.0,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta egg biryani'],
 'indian', 'Chowrasta', 1, '609 cal per serving (420g).', TRUE,
 430.0, 120.0, 1.2, 0.0, 130.0, 30.0, 1.2, 60.0, 0.5, 10.0, 12.0, 0.7, 100.0, 12.0, 0.0),

('chowrasta_veg_dum_biryani', 'Chowrasta Veg Dum Biryani', 135.0, 3.5, 20.0, 4.5,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta veg biryani', 'chowrasta veg dum biryani'],
 'indian', 'Chowrasta', 1, '567 cal per serving (420g).', TRUE,
 380.0, 0.0, 0.8, 0.0, 160.0, 22.0, 0.7, 30.0, 4.0, 0.0, 16.0, 0.3, 45.0, 3.0, 0.0),

('chowrasta_gongura_chicken_biryani', 'Chowrasta Gongura Chicken Biryani', 160.0, 8.0, 18.0, 6.0,
 1.0, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta gongura chicken biryani'],
 'indian', 'Chowrasta', 1, '720 cal per serving (450g). With tangy sorrel leaves.', TRUE,
 440.0, 42.0, 1.8, 0.0, 200.0, 22.0, 1.5, 50.0, 8.0, 3.0, 22.0, 1.2, 112.0, 14.0, 0.0),

('chowrasta_gongura_veg_biryani', 'Chowrasta Gongura Veg Biryani', 140.0, 3.5, 20.0, 5.0,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta gongura veg biryani'],
 'indian', 'Chowrasta', 1, '588 cal per serving (420g).', TRUE,
 390.0, 0.0, 0.8, 0.0, 170.0, 22.0, 1.0, 45.0, 8.0, 0.0, 16.0, 0.3, 48.0, 3.0, 0.0),

('chowrasta_gongura_paneer_biryani', 'Chowrasta Gongura Paneer Biryani', 155.0, 5.5, 18.0, 6.5,
 1.0, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta gongura paneer biryani'],
 'indian', 'Chowrasta', 1, '651 cal per serving (420g).', TRUE,
 400.0, 10.0, 2.8, 0.0, 150.0, 65.0, 1.0, 45.0, 8.0, 0.0, 18.0, 0.6, 90.0, 5.0, 0.0),

('chowrasta_veg_kofta_biryani', 'Chowrasta Veg Kofta Biryani', 148.0, 4.0, 19.0, 6.0,
 1.0, 1.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta veg kofta biryani'],
 'indian', 'Chowrasta', 1, '622 cal per serving (420g). Veggie kofta balls with biryani.', TRUE,
 400.0, 5.0, 1.5, 0.0, 160.0, 30.0, 0.8, 20.0, 3.0, 0.0, 16.0, 0.4, 55.0, 3.0, 0.0),

('chowrasta_avakai_veg_biryani', 'Chowrasta Avakai Veg Biryani', 142.0, 3.5, 20.0, 5.0,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta avakai veg biryani', 'chowrasta avakaya veg biryani'],
 'indian', 'Chowrasta', 1, '596 cal per serving (420g). Mango pickle spiced.', TRUE,
 420.0, 0.0, 0.8, 0.0, 170.0, 22.0, 0.8, 15.0, 5.0, 0.0, 16.0, 0.3, 48.0, 3.0, 0.0),

('chowrasta_vijayawada_veg_biryani', 'Chowrasta Vijayawada Veg Biryani', 140.0, 3.5, 20.0, 5.0,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta vijayawada veg biryani'],
 'indian', 'Chowrasta', 1, '588 cal per serving (420g). Andhra-style spicy.', TRUE,
 400.0, 0.0, 0.8, 0.0, 170.0, 22.0, 0.8, 25.0, 4.0, 0.0, 16.0, 0.3, 48.0, 3.0, 0.0),

('chowrasta_ulavacharu_veg_biryani', 'Chowrasta Ulavacharu Veg Biryani', 142.0, 4.0, 20.0, 5.0,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta ulavacharu veg biryani'],
 'indian', 'Chowrasta', 1, '596 cal per serving (420g). With horse gram paste.', TRUE,
 400.0, 0.0, 0.8, 0.0, 180.0, 25.0, 1.0, 12.0, 3.0, 0.0, 18.0, 0.4, 55.0, 3.0, 0.0),

('chowrasta_ulavacharu_paneer_biryani', 'Chowrasta Ulavacharu Paneer Biryani', 155.0, 5.5, 18.0, 6.5,
 1.0, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta ulavacharu paneer biryani', 'chowrasta ulvacharu paneer biryani'],
 'indian', 'Chowrasta', 1, '651 cal per serving (420g).', TRUE,
 400.0, 10.0, 2.8, 0.0, 145.0, 65.0, 1.0, 20.0, 2.0, 0.0, 18.0, 0.6, 90.0, 5.0, 0.0),

('chowrasta_ulavacharu_egg_biryani', 'Chowrasta Ulavacharu Egg Biryani', 148.0, 6.0, 18.0, 5.5,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta ulavacharu egg biryani'],
 'indian', 'Chowrasta', 1, '622 cal per serving (420g).', TRUE,
 430.0, 120.0, 1.2, 0.0, 140.0, 32.0, 1.3, 60.0, 1.0, 10.0, 14.0, 0.7, 105.0, 12.0, 0.0),

('chowrasta_chicken_sukka_biryani', 'Chowrasta Chicken Sukka Biryani', 168.0, 8.5, 18.0, 6.5,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta chicken sukka biryani'],
 'indian', 'Chowrasta', 1, '756 cal per serving (450g). Dry-roasted chicken biryani.', TRUE,
 460.0, 48.0, 2.0, 0.0, 190.0, 18.0, 1.2, 10.0, 1.0, 3.0, 20.0, 1.3, 112.0, 15.0, 0.0),

('chowrasta_avakai_chicken_biryani', 'Chowrasta Avakai Chicken Dum Biryani', 162.0, 8.0, 18.0, 6.0,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta avakai chicken biryani', 'chowrasta avakaya chicken biryani'],
 'indian', 'Chowrasta', 1, '729 cal per serving (450g). Mango pickle spiced chicken biryani.', TRUE,
 470.0, 42.0, 1.8, 0.0, 195.0, 20.0, 1.2, 15.0, 3.0, 3.0, 20.0, 1.2, 112.0, 14.0, 0.0),

('chowrasta_ulavacharu_chicken_biryani', 'Chowrasta Ulavacharu Chicken Dum Biryani', 160.0, 8.0, 18.0, 6.0,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta ulavacharu chicken biryani'],
 'indian', 'Chowrasta', 1, '720 cal per serving (450g).', TRUE,
 450.0, 42.0, 1.8, 0.0, 190.0, 22.0, 1.3, 12.0, 1.0, 3.0, 22.0, 1.2, 115.0, 14.0, 0.0),

('chowrasta_goat_sukka_biryani', 'Chowrasta Goat Sukka Biryani', 178.0, 9.0, 17.0, 8.0,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta goat sukka biryani'],
 'indian', 'Chowrasta', 1, '801 cal per serving (450g). Dry-roasted goat biryani.', TRUE,
 460.0, 55.0, 3.0, 0.0, 220.0, 18.0, 1.8, 5.0, 0.0, 3.0, 22.0, 2.8, 148.0, 12.0, 0.0),

('chowrasta_avakai_goat_biryani', 'Chowrasta Avakai Goat Dum Biryani', 175.0, 9.0, 17.0, 8.0,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta avakai goat biryani'],
 'indian', 'Chowrasta', 1, '788 cal per serving (450g).', TRUE,
 470.0, 55.0, 3.0, 0.0, 225.0, 20.0, 1.8, 10.0, 3.0, 3.0, 22.0, 2.5, 145.0, 12.0, 0.0),

('chowrasta_ulavacharu_goat_biryani', 'Chowrasta Ulavacharu Goat Dum Biryani', 175.0, 9.0, 17.0, 8.0,
 0.5, 0.5, 450, NULL,
 'chowrasta', ARRAY['chowrasta ulavacharu goat biryani'],
 'indian', 'Chowrasta', 1, '788 cal per serving (450g).', TRUE,
 455.0, 55.0, 3.0, 0.0, 220.0, 22.0, 1.8, 8.0, 1.0, 3.0, 22.0, 2.5, 148.0, 12.0, 0.0),

('chowrasta_guttivankaya_biryani', 'Chowrasta Guttivankaya Biryani', 130.0, 2.5, 19.0, 4.5,
 2.0, 1.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta guttivankaya biryani', 'chowrasta stuffed eggplant biryani'],
 'indian', 'Chowrasta', 1, '546 cal per serving (420g).', TRUE,
 360.0, 0.0, 0.8, 0.0, 230.0, 18.0, 0.9, 5.0, 3.0, 0.0, 16.0, 0.3, 42.0, 2.0, 0.0),

('chowrasta_chef_special_veg_biryani', 'Chowrasta Chef Special Veg Biryani', 140.0, 4.0, 20.0, 5.0,
 1.5, 1.0, 420, NULL,
 'chowrasta', ARRAY['chowrasta chef special veg biryani'],
 'indian', 'Chowrasta', 1, '588 cal per serving (420g). Chef''s special blend.', TRUE,
 390.0, 0.0, 0.8, 0.0, 170.0, 25.0, 0.8, 25.0, 5.0, 0.0, 16.0, 0.4, 48.0, 3.0, 0.0),

('chowrasta_vijayawada_paneer_biryani', 'Chowrasta Vijayawada Paneer Biryani', 155.0, 5.5, 18.0, 6.5,
 1.0, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta vijayawada paneer biryani'],
 'indian', 'Chowrasta', 1, '651 cal per serving (420g). Andhra-style paneer biryani.', TRUE,
 410.0, 10.0, 2.8, 0.0, 145.0, 65.0, 0.8, 22.0, 2.0, 0.0, 18.0, 0.6, 90.0, 5.0, 0.0),

-- ==========================================
-- CHOWRASTA - PULAV (new items)
-- ==========================================

('chowrasta_goat_keema_pulav', 'Chowrasta Goat Keema Pulav', 158.0, 8.5, 17.0, 6.5,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta goat keema pulav', 'chowrasta goat kheema pulav'],
 'indian', 'Chowrasta', 1, '664 cal per serving (420g).', TRUE,
 440.0, 50.0, 2.5, 0.0, 210.0, 18.0, 1.6, 5.0, 0.0, 3.0, 20.0, 2.5, 140.0, 11.0, 0.0),

('chowrasta_kaju_paneer_pulao', 'Chowrasta Kaju Paneer Pulao', 150.0, 5.5, 18.0, 6.5,
 0.5, 0.5, 400, NULL,
 'chowrasta', ARRAY['chowrasta kaju paneer pulao'],
 'indian', 'Chowrasta', 1, '600 cal per serving (400g). With cashews.', TRUE,
 380.0, 12.0, 2.8, 0.0, 130.0, 68.0, 0.7, 22.0, 1.0, 0.0, 18.0, 0.7, 92.0, 5.0, 0.0),

('chowrasta_vijayawada_chicken_pulav', 'Chowrasta Vijayawada Boneless Chicken Pulav', 150.0, 7.5, 18.0, 5.5,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta vijayawada chicken pulav'],
 'indian', 'Chowrasta', 1, '630 cal per serving (420g).', TRUE,
 450.0, 38.0, 1.5, 0.0, 180.0, 18.0, 1.0, 12.0, 1.0, 3.0, 20.0, 1.1, 105.0, 13.0, 0.0),

('chowrasta_kaju_gobi_pulao', 'Chowrasta Kaju Gobi Pulao', 128.0, 3.0, 18.0, 4.5,
 1.5, 1.0, 400, NULL,
 'chowrasta', ARRAY['chowrasta kaju gobi pulao'],
 'indian', 'Chowrasta', 1, '512 cal per serving (400g).', TRUE,
 360.0, 0.0, 0.8, 0.0, 190.0, 20.0, 0.7, 5.0, 18.0, 0.0, 14.0, 0.3, 48.0, 2.0, 0.0),

('chowrasta_goat_fry_pulav', 'Chowrasta Goat Fry Pulav', 165.0, 8.5, 17.0, 7.5,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta goat fry pulav', 'chowrasta mutton fry pulav'],
 'indian', 'Chowrasta', 1, '693 cal per serving (420g).', TRUE,
 450.0, 55.0, 2.8, 0.0, 210.0, 16.0, 1.6, 5.0, 0.0, 3.0, 20.0, 2.8, 142.0, 12.0, 0.0),

('chowrasta_mutton_ghee_roast_pulav', 'Chowrasta Mutton Ghee Roast Pulav', 168.0, 8.5, 17.0, 7.5,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta mutton ghee roast pulav'],
 'indian', 'Chowrasta', 1, '706 cal per serving (420g).', TRUE,
 455.0, 55.0, 3.2, 0.0, 210.0, 18.0, 1.5, 28.0, 0.0, 3.0, 22.0, 2.5, 142.0, 12.0, 0.0),

('chowrasta_veg_keema_pulao', 'Chowrasta Veg Keema Pulao', 132.0, 4.5, 19.0, 4.0,
 1.5, 1.0, 400, NULL,
 'chowrasta', ARRAY['chowrasta veg keema pulao', 'chowrasta veg kheema pulao'],
 'indian', 'Chowrasta', 1, '528 cal per serving (400g).', TRUE,
 370.0, 0.0, 0.6, 0.0, 170.0, 22.0, 1.2, 12.0, 3.0, 0.0, 18.0, 0.4, 55.0, 3.0, 0.0),

('chowrasta_vijayawada_veg_pulav', 'Chowrasta Vijayawada Veg Pulav', 130.0, 3.0, 20.0, 4.0,
 1.0, 1.0, 400, NULL,
 'chowrasta', ARRAY['chowrasta vijayawada veg pulav'],
 'indian', 'Chowrasta', 1, '520 cal per serving (400g).', TRUE,
 390.0, 0.0, 0.7, 0.0, 160.0, 20.0, 0.7, 22.0, 4.0, 0.0, 14.0, 0.3, 45.0, 3.0, 0.0),

('chowrasta_gongura_paneer_pulao', 'Chowrasta Gongura Paneer Pulao', 148.0, 5.5, 18.0, 6.0,
 1.0, 0.5, 400, NULL,
 'chowrasta', ARRAY['chowrasta gongura paneer pulao'],
 'indian', 'Chowrasta', 1, '592 cal per serving (400g).', TRUE,
 400.0, 10.0, 2.5, 0.0, 150.0, 62.0, 1.0, 42.0, 8.0, 0.0, 18.0, 0.6, 88.0, 5.0, 0.0),

('chowrasta_paneer_pulav', 'Chowrasta Paneer Pulav', 142.0, 5.5, 18.0, 5.5,
 0.5, 0.5, 400, NULL,
 'chowrasta', ARRAY['chowrasta paneer pulav'],
 'indian', 'Chowrasta', 1, '568 cal per serving (400g).', TRUE,
 380.0, 10.0, 2.5, 0.0, 125.0, 62.0, 0.7, 20.0, 1.0, 0.0, 16.0, 0.6, 85.0, 5.0, 0.0),

('chowrasta_egg_pulao', 'Chowrasta Egg Pulao', 135.0, 5.5, 18.0, 4.5,
 0.5, 0.5, 400, NULL,
 'chowrasta', ARRAY['chowrasta egg pulao'],
 'indian', 'Chowrasta', 1, '540 cal per serving (400g).', TRUE,
 420.0, 110.0, 1.0, 0.0, 120.0, 28.0, 1.0, 55.0, 0.5, 8.0, 11.0, 0.6, 90.0, 10.0, 0.0),

('chowrasta_chicken_65_pulao', 'Chowrasta Chicken 65 Pulao', 155.0, 7.5, 18.0, 6.0,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta chicken 65 pulao'],
 'indian', 'Chowrasta', 1, '651 cal per serving (420g).', TRUE,
 450.0, 42.0, 1.8, 0.0, 170.0, 18.0, 1.0, 10.0, 1.0, 3.0, 18.0, 1.1, 105.0, 13.0, 0.0),

('chowrasta_shrimp_fry_pulav', 'Chowrasta Shrimp Fry Pulav', 145.0, 8.0, 17.0, 5.0,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta shrimp fry pulav', 'chowrasta prawn fry pulav'],
 'indian', 'Chowrasta', 1, '609 cal per serving (420g).', TRUE,
 450.0, 75.0, 0.8, 0.0, 210.0, 38.0, 1.0, 10.0, 1.0, 2.0, 26.0, 1.0, 135.0, 22.0, 0.1),

('chowrasta_fish_pulav', 'Chowrasta Fish Pulav', 140.0, 7.5, 17.0, 4.5,
 0.5, 0.5, 420, NULL,
 'chowrasta', ARRAY['chowrasta fish pulav'],
 'indian', 'Chowrasta', 1, '588 cal per serving (420g).', TRUE,
 430.0, 38.0, 0.8, 0.0, 200.0, 25.0, 0.8, 8.0, 1.0, 12.0, 22.0, 0.5, 125.0, 22.0, 0.15),

('chowrasta_guttivankaya_pulav', 'Chowrasta Guttivankaya Pulav', 125.0, 2.5, 18.0, 4.5,
 2.0, 1.5, 400, NULL,
 'chowrasta', ARRAY['chowrasta guttivankaya pulav'],
 'indian', 'Chowrasta', 1, '500 cal per serving (400g).', TRUE,
 350.0, 0.0, 0.8, 0.0, 220.0, 18.0, 0.8, 5.0, 3.0, 0.0, 15.0, 0.3, 40.0, 2.0, 0.0),

('chowrasta_chef_special_veg_pulav', 'Chowrasta Chef Special Veg Pulav', 130.0, 3.5, 19.0, 4.5,
 1.0, 1.0, 400, NULL,
 'chowrasta', ARRAY['chowrasta chef special veg pulav'],
 'indian', 'Chowrasta', 1, '520 cal per serving (400g).', TRUE,
 380.0, 0.0, 0.8, 0.0, 160.0, 22.0, 0.7, 22.0, 4.0, 0.0, 14.0, 0.3, 45.0, 3.0, 0.0),

-- ==========================================
-- CHOWRASTA - VEG APPETIZERS (new items)
-- ==========================================

('chowrasta_jalepeno_paneer', 'Chowrasta Jalapeno Paneer', 220.0, 9.0, 10.0, 16.0,
 1.0, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta jalapeno paneer', 'chowrasta jalepeno paneer'],
 'indian', 'Chowrasta', 1, '440 cal per serving (200g). Paneer with jalapeno peppers.', TRUE,
 520.0, 15.0, 5.5, 0.0, 120.0, 108.0, 0.8, 30.0, 12.0, 0.0, 14.0, 0.8, 118.0, 5.0, 0.0),

('chowrasta_gobi_65', 'Chowrasta Gobi 65', 175.0, 4.0, 16.0, 10.0,
 2.0, 1.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta gobi 65', 'chowrasta cauliflower 65'],
 'indian', 'Chowrasta', 1, '350 cal per serving (200g). Spicy deep-fried cauliflower.', TRUE,
 450.0, 0.0, 1.8, 0.0, 210.0, 22.0, 0.8, 2.0, 28.0, 0.0, 12.0, 0.3, 40.0, 2.0, 0.0),

('chowrasta_garlic_chilli_paneer', 'Chowrasta Garlic Chilli Paneer', 218.0, 9.0, 10.0, 16.0,
 1.0, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta garlic chilli paneer', 'chowrasta garlic chili paneer'],
 'indian', 'Chowrasta', 1, '436 cal per serving (200g).', TRUE,
 540.0, 15.0, 5.5, 0.0, 115.0, 105.0, 0.8, 22.0, 8.0, 0.0, 14.0, 0.8, 115.0, 5.0, 0.0),

('chowrasta_chilli_mushroom', 'Chowrasta Chilli Mushroom', 140.0, 4.5, 10.0, 9.0,
 1.5, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chilli mushroom', 'chowrasta chili mushroom'],
 'indian', 'Chowrasta', 1, '280 cal per serving (200g).', TRUE,
 520.0, 0.0, 1.5, 0.0, 300.0, 6.0, 1.0, 0.0, 3.0, 0.0, 10.0, 0.7, 80.0, 7.0, 0.0),

('chowrasta_dragon_cauliflower', 'Chowrasta Dragon Cauliflower', 175.0, 4.0, 16.0, 10.0,
 2.0, 2.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta dragon cauliflower', 'chowrasta dragon gobi'],
 'indian', 'Chowrasta', 1, '350 cal per serving (200g). In fiery dragon sauce.', TRUE,
 530.0, 0.0, 1.8, 0.0, 210.0, 22.0, 0.8, 2.0, 28.0, 0.0, 12.0, 0.3, 40.0, 2.0, 0.0),

('chowrasta_podi_idli', 'Chowrasta Podi Idli', 110.0, 3.0, 16.0, 3.5,
 1.0, 0.5, 200, 60,
 'chowrasta', ARRAY['chowrasta podi idli', 'chowrasta karam podi idli'],
 'indian', 'Chowrasta', 3, '220 cal per serving (200g). Idli tossed in spice powder & ghee.', TRUE,
 380.0, 5.0, 1.5, 0.0, 90.0, 12.0, 0.8, 15.0, 0.0, 0.0, 10.0, 0.3, 45.0, 3.0, 0.0),

('chowrasta_soya_65', 'Chowrasta Soya 65', 185.0, 12.0, 14.0, 9.0,
 2.0, 1.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta soya 65'],
 'indian', 'Chowrasta', 1, '370 cal per serving (200g). Deep-fried spiced soy chunks.', TRUE,
 450.0, 0.0, 1.5, 0.0, 250.0, 40.0, 3.0, 0.0, 0.0, 0.0, 30.0, 1.5, 140.0, 5.0, 0.0),

('chowrasta_pepper_baby_corn', 'Chowrasta Pepper Baby Corn', 145.0, 3.5, 16.0, 7.5,
 2.0, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta pepper baby corn'],
 'indian', 'Chowrasta', 1, '290 cal per serving (200g).', TRUE,
 440.0, 0.0, 1.2, 0.0, 180.0, 12.0, 0.6, 5.0, 4.0, 0.0, 10.0, 0.3, 35.0, 2.0, 0.0),

('chowrasta_baby_corn_manchuria', 'Chowrasta Baby Corn Manchuria', 160.0, 3.5, 18.0, 8.0,
 1.5, 3.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta baby corn manchuria'],
 'indian', 'Chowrasta', 1, '320 cal per serving (200g).', TRUE,
 520.0, 0.0, 1.2, 0.0, 180.0, 15.0, 0.6, 5.0, 4.0, 0.0, 10.0, 0.3, 35.0, 2.0, 0.0),

('chowrasta_pachimirchi_paneer', 'Chowrasta Pachimirchi Paneer', 215.0, 9.0, 10.0, 15.5,
 1.0, 1.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta pachimirchi paneer', 'chowrasta green chili paneer'],
 'indian', 'Chowrasta', 1, '430 cal per serving (200g). Green chili paneer.', TRUE,
 480.0, 15.0, 5.5, 0.0, 130.0, 108.0, 0.8, 25.0, 15.0, 0.0, 14.0, 0.8, 115.0, 5.0, 0.0),

('chowrasta_karam_podi_paneer', 'Chowrasta Karam Podi Paneer', 220.0, 9.5, 10.0, 16.0,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta karam podi paneer'],
 'indian', 'Chowrasta', 1, '440 cal per serving (200g). Paneer with spice powder.', TRUE,
 460.0, 15.0, 6.0, 0.0, 100.0, 110.0, 0.8, 25.0, 1.0, 0.0, 14.0, 0.8, 118.0, 5.0, 0.0),

('chowrasta_chickpeas_pepper_salt', 'Chowrasta Chickpeas Pepper Salt', 160.0, 7.0, 20.0, 6.0,
 4.0, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chickpeas pepper salt'],
 'indian', 'Chowrasta', 1, '320 cal per serving (200g). Crispy chickpeas with pepper & salt.', TRUE,
 420.0, 0.0, 0.8, 0.0, 280.0, 40.0, 2.5, 2.0, 1.0, 0.0, 30.0, 1.0, 100.0, 4.0, 0.0),

-- ==========================================
-- CHOWRASTA - NON-VEG APPETIZERS (new items)
-- ==========================================

('chowrasta_jalapeno_chicken', 'Chowrasta Jalapeno Chicken', 205.0, 15.0, 10.0, 12.5,
 0.5, 1.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta jalapeno chicken'],
 'indian', 'Chowrasta', 1, '410 cal per serving (200g).', TRUE,
 530.0, 50.0, 2.8, 0.0, 200.0, 18.0, 1.2, 15.0, 12.0, 2.0, 20.0, 1.2, 118.0, 14.0, 0.0),

('chowrasta_guntur_kodi_vepudu', 'Chowrasta Guntur Kodi Vepudu', 200.0, 17.0, 6.0, 12.0,
 0.5, 0.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta guntur kodi vepudu', 'chowrasta guntur chicken fry'],
 'indian', 'Chowrasta', 1, '400 cal per serving (200g). Spicy Guntur-style chicken.', TRUE,
 480.0, 55.0, 2.8, 0.0, 230.0, 15.0, 1.5, 30.0, 5.0, 3.0, 22.0, 1.5, 140.0, 18.0, 0.0),

('chowrasta_cashew_chicken', 'Chowrasta Cashew Chicken', 210.0, 15.0, 8.0, 13.0,
 0.5, 1.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta cashew chicken'],
 'indian', 'Chowrasta', 1, '420 cal per serving (200g). Chicken with roasted cashews.', TRUE,
 480.0, 50.0, 2.8, 0.0, 220.0, 18.0, 1.2, 10.0, 1.0, 2.0, 25.0, 1.3, 140.0, 15.0, 0.0),

('chowrasta_pepper_chicken', 'Chowrasta Pepper Chicken', 195.0, 18.0, 5.0, 11.0,
 0.5, 0.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta pepper chicken'],
 'indian', 'Chowrasta', 1, '390 cal per serving (200g).', TRUE,
 480.0, 55.0, 2.5, 0.0, 230.0, 15.0, 1.5, 5.0, 2.0, 3.0, 22.0, 1.5, 140.0, 18.0, 0.0),

('chowrasta_dragon_chicken', 'Chowrasta Dragon Chicken', 210.0, 14.0, 12.0, 12.5,
 0.5, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta dragon chicken'],
 'indian', 'Chowrasta', 1, '420 cal per serving (200g). In fiery dragon sauce.', TRUE,
 550.0, 48.0, 2.5, 0.0, 190.0, 15.0, 1.0, 10.0, 5.0, 2.0, 18.0, 1.1, 110.0, 13.0, 0.0),

('chowrasta_chicken_555', 'Chowrasta Chicken 555', 215.0, 15.0, 10.0, 13.0,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chicken 555'],
 'indian', 'Chowrasta', 1, '430 cal per serving (200g).', TRUE,
 500.0, 50.0, 2.8, 0.0, 190.0, 15.0, 1.0, 10.0, 1.0, 2.0, 18.0, 1.2, 115.0, 14.0, 0.0),

('chowrasta_chicken_pakoda', 'Chowrasta Chicken Pakoda', 215.0, 14.0, 14.0, 12.0,
 1.0, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chicken pakoda', 'chowrasta chicken pakora'],
 'indian', 'Chowrasta', 1, '430 cal per serving (200g).', TRUE,
 500.0, 50.0, 2.5, 0.0, 180.0, 20.0, 1.5, 8.0, 1.0, 2.0, 18.0, 1.0, 115.0, 14.0, 0.0),

('chowrasta_hariyali_chicken', 'Chowrasta Hariyali Chicken', 180.0, 17.0, 5.0, 10.0,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta hariyali chicken'],
 'indian', 'Chowrasta', 1, '360 cal per serving (200g). Green herb-marinated chicken.', TRUE,
 450.0, 52.0, 2.2, 0.0, 240.0, 18.0, 1.5, 80.0, 8.0, 3.0, 24.0, 1.5, 140.0, 16.0, 0.0),

('chowrasta_chilli_goat_roast', 'Chowrasta Chilli Goat Roast', 210.0, 17.0, 5.0, 13.5,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chilli goat roast', 'chowrasta chili goat roast'],
 'indian', 'Chowrasta', 1, '420 cal per serving (200g).', TRUE,
 460.0, 60.0, 5.0, 0.0, 240.0, 14.0, 2.0, 5.0, 2.0, 3.0, 20.0, 3.0, 142.0, 10.0, 0.0),

('chowrasta_goat_sukka', 'Chowrasta Goat Sukka', 205.0, 17.0, 4.0, 13.0,
 0.5, 0.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta goat sukka', 'chowrasta mutton sukka'],
 'indian', 'Chowrasta', 1, '410 cal per serving (200g). Dry-roasted goat.', TRUE,
 440.0, 60.0, 5.0, 0.0, 240.0, 12.0, 2.0, 0.0, 0.0, 3.0, 20.0, 3.0, 140.0, 10.0, 0.0),

('chowrasta_pepper_shrimp', 'Chowrasta Pepper Shrimp', 185.0, 18.0, 4.0, 10.0,
 0.3, 0.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta pepper shrimp', 'chowrasta pepper prawn'],
 'indian', 'Chowrasta', 1, '370 cal per serving (200g).', TRUE,
 500.0, 90.0, 1.5, 0.0, 220.0, 45.0, 1.2, 8.0, 2.0, 2.0, 28.0, 1.0, 150.0, 22.0, 0.1),

('chowrasta_golkonda_kodi', 'Chowrasta Golkonda Kodi', 200.0, 16.0, 6.0, 12.5,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta golkonda kodi', 'chowrasta golkonda chicken'],
 'indian', 'Chowrasta', 1, '400 cal per serving (200g). Hyderabadi-style spiced chicken.', TRUE,
 470.0, 52.0, 3.0, 0.0, 210.0, 18.0, 1.3, 15.0, 2.0, 3.0, 20.0, 1.3, 125.0, 15.0, 0.0),

('chowrasta_chicken_manchuria', 'Chowrasta Chicken Manchuria', 195.0, 14.0, 12.0, 10.0,
 0.5, 2.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta chicken manchuria'],
 'indian', 'Chowrasta', 1, '390 cal per serving (200g).', TRUE,
 560.0, 50.0, 2.0, 0.0, 190.0, 15.0, 1.0, 8.0, 4.0, 2.0, 18.0, 1.0, 110.0, 13.0, 0.0),

('chowrasta_chilli_chicken', 'Chowrasta Chilli Chicken', 200.0, 15.0, 10.0, 12.0,
 0.5, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chilli chicken', 'chowrasta chili chicken'],
 'indian', 'Chowrasta', 1, '400 cal per serving (200g).', TRUE,
 580.0, 55.0, 2.5, 0.0, 200.0, 15.0, 1.2, 10.0, 5.0, 2.0, 20.0, 1.2, 120.0, 15.0, 0.0),

('chowrasta_chilli_fish', 'Chowrasta Chilli Fish', 195.0, 14.0, 10.0, 11.0,
 0.5, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chilli fish', 'chowrasta chili fish'],
 'indian', 'Chowrasta', 1, '390 cal per serving (200g).', TRUE,
 530.0, 40.0, 1.8, 0.0, 210.0, 25.0, 1.0, 10.0, 3.0, 12.0, 20.0, 0.5, 125.0, 22.0, 0.15),

('chowrasta_fish_pakoda', 'Chowrasta Fish Pakoda', 210.0, 13.0, 14.0, 12.0,
 0.5, 0.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta fish pakoda', 'chowrasta fish pakora'],
 'indian', 'Chowrasta', 1, '420 cal per serving (200g).', TRUE,
 500.0, 38.0, 2.0, 0.0, 200.0, 22.0, 1.2, 8.0, 1.0, 12.0, 18.0, 0.5, 120.0, 20.0, 0.1),

('chowrasta_chilli_shrimp', 'Chowrasta Chilli Shrimp', 190.0, 16.0, 8.0, 10.5,
 0.5, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chilli shrimp', 'chowrasta chili shrimp'],
 'indian', 'Chowrasta', 1, '380 cal per serving (200g).', TRUE,
 540.0, 85.0, 1.5, 0.0, 210.0, 42.0, 1.2, 8.0, 5.0, 2.0, 28.0, 1.0, 148.0, 22.0, 0.1),

('chowrasta_chilli_egg', 'Chowrasta Chilli Egg', 165.0, 10.0, 8.0, 10.5,
 0.5, 2.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta chilli egg', 'chowrasta chili egg'],
 'indian', 'Chowrasta', 1, '330 cal per serving (200g).', TRUE,
 500.0, 300.0, 2.5, 0.0, 150.0, 40.0, 1.5, 120.0, 3.0, 15.0, 10.0, 0.8, 130.0, 15.0, 0.0),

('chowrasta_curry_leaf_chicken', 'Chowrasta Curry Leaf Chicken', 195.0, 17.0, 6.0, 11.5,
 0.5, 0.5, 200, NULL,
 'chowrasta', ARRAY['chowrasta curry leaf chicken'],
 'indian', 'Chowrasta', 1, '390 cal per serving (200g). Chicken with aromatic curry leaves.', TRUE,
 470.0, 52.0, 2.5, 0.0, 230.0, 18.0, 1.5, 25.0, 3.0, 3.0, 22.0, 1.3, 135.0, 16.0, 0.0),

-- ==========================================
-- CHOWRASTA - VEG CURRIES (new items)
-- ==========================================

('chowrasta_paneer_tikka_masala', 'Chowrasta Paneer Tikka Masala', 170.0, 8.0, 7.0, 12.0,
 0.5, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta paneer tikka masala'],
 'indian', 'Chowrasta', 1, '510 cal per bowl (300g).', TRUE,
 450.0, 15.0, 5.0, 0.0, 180.0, 120.0, 1.0, 40.0, 4.0, 0.0, 18.0, 0.8, 130.0, 5.0, 0.0),

('chowrasta_palak_paneer', 'Chowrasta Palak Paneer', 140.0, 7.5, 6.0, 10.0,
 2.0, 1.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta palak paneer'],
 'indian', 'Chowrasta', 1, '420 cal per bowl (300g).', TRUE,
 430.0, 15.0, 4.0, 0.0, 350.0, 140.0, 2.5, 400.0, 15.0, 0.0, 40.0, 0.8, 120.0, 5.0, 0.0),

('chowrasta_chana_masala', 'Chowrasta Chana Masala', 120.0, 6.0, 16.0, 3.5,
 4.0, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta chana masala'],
 'indian', 'Chowrasta', 1, '360 cal per bowl (300g).', TRUE,
 450.0, 0.0, 0.5, 0.0, 250.0, 40.0, 2.5, 5.0, 3.0, 0.0, 30.0, 1.0, 100.0, 4.0, 0.0),

('chowrasta_malai_kofta', 'Chowrasta Malai Kofta', 165.0, 5.0, 12.0, 11.0,
 1.0, 3.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta malai kofta'],
 'indian', 'Chowrasta', 1, '495 cal per bowl (300g).', TRUE,
 420.0, 10.0, 4.0, 0.0, 150.0, 45.0, 0.8, 30.0, 2.0, 0.0, 16.0, 0.5, 70.0, 3.0, 0.0),

('chowrasta_malai_methi_paneer', 'Chowrasta Malai Methi Paneer', 172.0, 8.0, 7.0, 12.5,
 1.0, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta malai methi paneer'],
 'indian', 'Chowrasta', 1, '516 cal per bowl (300g). Paneer in creamy fenugreek gravy.', TRUE,
 440.0, 18.0, 5.5, 0.0, 160.0, 120.0, 1.2, 50.0, 3.0, 0.0, 20.0, 0.8, 130.0, 5.0, 0.0),

('chowrasta_kadai_paneer', 'Chowrasta Kadai Paneer', 155.0, 7.0, 7.0, 11.5,
 1.5, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta kadai paneer'],
 'indian', 'Chowrasta', 1, '465 cal per bowl (300g).', TRUE,
 440.0, 15.0, 4.5, 0.0, 200.0, 110.0, 1.0, 50.0, 15.0, 0.0, 16.0, 0.8, 120.0, 5.0, 0.0),

('chowrasta_bhindi_masala', 'Chowrasta Bhindi Masala', 85.0, 2.5, 10.0, 4.0,
 3.0, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta bhindi masala', 'chowrasta okra masala'],
 'indian', 'Chowrasta', 1, '255 cal per bowl (300g). Spiced okra curry.', TRUE,
 380.0, 0.0, 0.6, 0.0, 280.0, 60.0, 0.8, 30.0, 15.0, 0.0, 40.0, 0.5, 50.0, 1.0, 0.0),

('chowrasta_mushroom_masala', 'Chowrasta Mushroom Masala', 100.0, 4.0, 8.0, 6.0,
 1.5, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta mushroom masala'],
 'indian', 'Chowrasta', 1, '300 cal per bowl (300g).', TRUE,
 420.0, 0.0, 1.2, 0.0, 320.0, 8.0, 1.2, 5.0, 3.0, 0.0, 12.0, 0.8, 90.0, 8.0, 0.0),

('chowrasta_spinach_dal', 'Chowrasta Spinach Dal', 85.0, 5.5, 11.0, 2.0,
 3.5, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta spinach dal', 'chowrasta palak dal'],
 'indian', 'Chowrasta', 1, '255 cal per bowl (300g).', TRUE,
 380.0, 0.0, 0.4, 0.0, 320.0, 60.0, 2.5, 300.0, 12.0, 0.0, 35.0, 0.8, 110.0, 3.0, 0.0),

-- ==========================================
-- CHOWRASTA - NON-VEG CURRIES (new items)
-- ==========================================

('chowrasta_chicken_tikka_masala', 'Chowrasta Chicken Tikka Masala', 165.0, 13.0, 6.0, 10.0,
 0.5, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta chicken tikka masala'],
 'indian', 'Chowrasta', 1, '495 cal per bowl (300g).', TRUE,
 480.0, 50.0, 3.5, 0.0, 220.0, 35.0, 1.2, 40.0, 3.0, 3.0, 22.0, 1.3, 130.0, 16.0, 0.0),

('chowrasta_dhaba_style_chicken', 'Chowrasta Dhaba Style Chicken', 155.0, 13.0, 5.0, 9.5,
 0.5, 1.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta dhaba chicken', 'chowrasta dhaba style chicken'],
 'indian', 'Chowrasta', 1, '465 cal per bowl (300g). Rustic highway-style chicken curry.', TRUE,
 470.0, 50.0, 2.5, 0.0, 230.0, 22.0, 1.3, 15.0, 2.0, 3.0, 22.0, 1.3, 128.0, 15.0, 0.0),

('chowrasta_mughlai_chicken', 'Chowrasta Mughlai Chicken Curry', 165.0, 12.0, 6.0, 10.5,
 0.5, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta mughlai chicken'],
 'indian', 'Chowrasta', 1, '495 cal per bowl (300g). Rich Mughal-style cream-based chicken.', TRUE,
 440.0, 50.0, 4.0, 0.0, 200.0, 30.0, 1.0, 25.0, 1.0, 3.0, 20.0, 1.2, 125.0, 15.0, 0.0),

('chowrasta_goat_keema_curry', 'Chowrasta Goat Keema Curry', 160.0, 14.0, 5.0, 9.5,
 1.0, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta goat keema curry', 'chowrasta goat kheema curry'],
 'indian', 'Chowrasta', 1, '480 cal per bowl (300g). Minced goat meat curry.', TRUE,
 450.0, 55.0, 3.5, 0.0, 230.0, 18.0, 2.0, 5.0, 1.0, 3.0, 22.0, 3.0, 145.0, 12.0, 0.0),

('chowrasta_gongura_chicken_curry', 'Chowrasta Gongura Chicken Curry', 150.0, 12.0, 5.0, 9.0,
 1.0, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta gongura chicken curry'],
 'indian', 'Chowrasta', 1, '450 cal per bowl (300g).', TRUE,
 440.0, 48.0, 2.5, 0.0, 230.0, 25.0, 1.5, 60.0, 10.0, 3.0, 24.0, 1.2, 130.0, 15.0, 0.0),

('chowrasta_kadai_chicken', 'Chowrasta Kadai Chicken', 155.0, 13.0, 5.0, 9.5,
 1.0, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta kadai chicken'],
 'indian', 'Chowrasta', 1, '465 cal per bowl (300g).', TRUE,
 460.0, 48.0, 2.8, 0.0, 240.0, 25.0, 1.3, 50.0, 12.0, 3.0, 22.0, 1.2, 125.0, 15.0, 0.0),

('chowrasta_malai_methi_chicken', 'Chowrasta Malai Methi Chicken', 162.0, 12.0, 5.0, 10.5,
 0.5, 2.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta malai methi chicken'],
 'indian', 'Chowrasta', 1, '486 cal per bowl (300g). Creamy fenugreek chicken.', TRUE,
 440.0, 50.0, 3.5, 0.0, 200.0, 28.0, 1.2, 45.0, 2.0, 3.0, 20.0, 1.2, 125.0, 15.0, 0.0),

('chowrasta_palak_chicken', 'Chowrasta Palak Chicken Curry', 142.0, 12.5, 5.0, 8.5,
 2.0, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta palak chicken'],
 'indian', 'Chowrasta', 1, '426 cal per bowl (300g). Chicken in spinach gravy.', TRUE,
 430.0, 48.0, 2.5, 0.0, 340.0, 80.0, 2.5, 350.0, 12.0, 3.0, 35.0, 1.2, 125.0, 15.0, 0.0),

('chowrasta_andhra_goat_masala', 'Chowrasta Andhra Goat Masala', 170.0, 13.5, 4.0, 11.0,
 0.5, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta andhra goat masala', 'chowrasta andhra mutton masala'],
 'indian', 'Chowrasta', 1, '510 cal per bowl (300g). Fiery Andhra-style goat curry.', TRUE,
 460.0, 55.0, 4.0, 0.0, 240.0, 18.0, 1.8, 10.0, 2.0, 3.0, 22.0, 2.8, 145.0, 12.0, 0.0),

('chowrasta_ginger_goat_curry', 'Chowrasta Ginger Goat Curry', 168.0, 13.0, 4.5, 11.0,
 0.5, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta ginger goat curry'],
 'indian', 'Chowrasta', 1, '504 cal per bowl (300g).', TRUE,
 440.0, 55.0, 4.0, 0.0, 240.0, 18.0, 1.6, 5.0, 2.0, 3.0, 22.0, 2.5, 142.0, 12.0, 0.0),

('chowrasta_gongura_goat_curry', 'Chowrasta Gongura Goat Curry', 172.0, 13.0, 5.0, 11.5,
 1.0, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta gongura goat curry'],
 'indian', 'Chowrasta', 1, '516 cal per bowl (300g).', TRUE,
 445.0, 55.0, 4.2, 0.0, 245.0, 22.0, 1.8, 55.0, 10.0, 3.0, 24.0, 2.5, 145.0, 12.0, 0.0),

('chowrasta_palak_goat_curry', 'Chowrasta Palak Goat Curry', 162.0, 13.0, 5.0, 10.5,
 2.0, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta palak goat curry', 'chowrasta spinach goat curry'],
 'indian', 'Chowrasta', 1, '486 cal per bowl (300g). Goat in spinach gravy.', TRUE,
 440.0, 55.0, 3.8, 0.0, 340.0, 60.0, 2.5, 350.0, 12.0, 3.0, 35.0, 2.5, 140.0, 12.0, 0.0),

('chowrasta_egg_pulusu', 'Chowrasta Egg Pulusu', 110.0, 6.5, 6.0, 6.5,
 0.5, 1.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta egg pulusu', 'chowrasta egg tamarind curry'],
 'indian', 'Chowrasta', 1, '330 cal per bowl (300g). Eggs in tangy tamarind gravy.', TRUE,
 420.0, 240.0, 1.8, 0.0, 150.0, 40.0, 1.5, 100.0, 2.0, 15.0, 10.0, 0.8, 120.0, 15.0, 0.0),

('chowrasta_egg_burji', 'Chowrasta Egg Burji Dhaba Style', 155.0, 11.0, 3.0, 11.0,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta egg burji', 'chowrasta egg bhurji'],
 'indian', 'Chowrasta', 1, '310 cal per serving (200g). Spiced scrambled eggs.', TRUE,
 450.0, 350.0, 3.0, 0.0, 160.0, 45.0, 1.5, 150.0, 2.0, 20.0, 10.0, 1.0, 160.0, 18.0, 0.0),

('chowrasta_fish_masala', 'Chowrasta Fish Masala', 140.0, 13.0, 5.0, 8.0,
 0.5, 1.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta fish masala', 'chowrasta fish curry'],
 'indian', 'Chowrasta', 1, '420 cal per bowl (300g).', TRUE,
 470.0, 40.0, 1.5, 0.0, 220.0, 30.0, 1.0, 12.0, 2.0, 15.0, 22.0, 0.5, 130.0, 25.0, 0.15),

('chowrasta_shrimp_masala', 'Chowrasta Shrimp Masala', 142.0, 13.0, 5.0, 8.0,
 0.5, 1.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta shrimp masala', 'chowrasta prawn masala'],
 'indian', 'Chowrasta', 1, '426 cal per bowl (300g).', TRUE,
 480.0, 85.0, 1.5, 0.0, 230.0, 45.0, 1.2, 10.0, 2.0, 2.0, 28.0, 1.0, 150.0, 22.0, 0.1),

('chowrasta_kadai_goat_curry', 'Chowrasta Kadai Goat Curry', 168.0, 13.0, 5.0, 11.0,
 1.0, 1.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta kadai goat curry'],
 'indian', 'Chowrasta', 1, '504 cal per bowl (300g).', TRUE,
 460.0, 55.0, 4.0, 0.0, 250.0, 25.0, 1.6, 45.0, 12.0, 3.0, 22.0, 2.5, 140.0, 12.0, 0.0),

('chowrasta_andhra_chicken', 'Chowrasta Andhra Chicken Curry', 148.0, 12.5, 4.0, 9.0,
 0.5, 1.0, 300, NULL,
 'chowrasta', ARRAY['chowrasta andhra chicken', 'chowrasta andra chicken curry'],
 'indian', 'Chowrasta', 1, '444 cal per bowl (300g). Fiery Andhra-style.', TRUE,
 470.0, 50.0, 2.5, 0.0, 230.0, 22.0, 1.3, 15.0, 2.0, 3.0, 22.0, 1.3, 130.0, 16.0, 0.0),

-- ==========================================
-- CHOWRASTA - DOSA (new items)
-- ==========================================

('chowrasta_chicken_tikka_dosa', 'Chowrasta Chicken Tikka Dosa', 175.0, 8.0, 20.0, 7.0,
 0.5, 0.5, 220, 220,
 'chowrasta', ARRAY['chowrasta chicken tikka dosa'],
 'indian', 'Chowrasta', 1, '385 cal per dosa (220g). With chicken tikka filling.', TRUE,
 400.0, 35.0, 1.8, 0.0, 170.0, 18.0, 1.0, 12.0, 1.0, 2.0, 16.0, 0.8, 85.0, 10.0, 0.0),

('chowrasta_mysore_masala_dosa', 'Chowrasta Mysore Masala Dosa', 175.0, 4.0, 21.0, 8.0,
 1.5, 1.0, 210, 210,
 'chowrasta', ARRAY['chowrasta mysore masala dosa', 'chowrasta mysore dosa'],
 'indian', 'Chowrasta', 1, '368 cal per dosa (210g).', TRUE,
 390.0, 0.0, 1.5, 0.0, 175.0, 15.0, 0.9, 30.0, 5.0, 0.0, 14.0, 0.4, 55.0, 4.0, 0.0),

('chowrasta_onion_dosa', 'Chowrasta Onion Dosa', 140.0, 3.5, 20.0, 5.0,
 1.0, 1.0, 160, 160,
 'chowrasta', ARRAY['chowrasta onion dosa'],
 'indian', 'Chowrasta', 1, '224 cal per dosa (160g).', TRUE,
 310.0, 0.0, 0.8, 0.0, 100.0, 12.0, 0.6, 2.0, 3.0, 0.0, 11.0, 0.3, 45.0, 3.0, 0.0),

('chowrasta_ghee_karam_dosa', 'Chowrasta Ghee Karam Dosa', 185.0, 3.5, 21.0, 9.5,
 0.5, 0.5, 150, 150,
 'chowrasta', ARRAY['chowrasta ghee karam dosa'],
 'indian', 'Chowrasta', 1, '278 cal per dosa (150g). Ghee dosa with spicy powder.', TRUE,
 300.0, 8.0, 4.0, 0.0, 78.0, 12.0, 0.5, 28.0, 0.0, 0.0, 10.0, 0.3, 42.0, 3.0, 0.0),

('chowrasta_paneer_dosa', 'Chowrasta Paneer Dosa', 185.0, 6.5, 20.0, 8.5,
 1.0, 1.0, 200, 200,
 'chowrasta', ARRAY['chowrasta paneer dosa'],
 'indian', 'Chowrasta', 1, '370 cal per dosa (200g).', TRUE,
 360.0, 10.0, 3.5, 0.0, 110.0, 65.0, 0.6, 22.0, 1.0, 0.0, 14.0, 0.5, 75.0, 4.0, 0.0),

('chowrasta_chicken_65_dosa', 'Chowrasta Chicken 65 Dosa', 180.0, 8.0, 20.0, 7.5,
 0.5, 0.5, 220, 220,
 'chowrasta', ARRAY['chowrasta chicken 65 dosa'],
 'indian', 'Chowrasta', 1, '396 cal per dosa (220g).', TRUE,
 420.0, 38.0, 2.0, 0.0, 170.0, 16.0, 1.0, 10.0, 1.0, 2.0, 16.0, 0.8, 82.0, 10.0, 0.0),

('chowrasta_amul_cheese_dosa', 'Chowrasta Amul Cheese Dosa', 200.0, 6.0, 20.0, 10.5,
 0.5, 1.0, 180, 180,
 'chowrasta', ARRAY['chowrasta cheese dosa', 'chowrasta amul cheese dosa'],
 'indian', 'Chowrasta', 1, '360 cal per dosa (180g).', TRUE,
 380.0, 15.0, 5.0, 0.0, 80.0, 90.0, 0.5, 40.0, 0.0, 0.0, 12.0, 0.6, 100.0, 4.0, 0.0),

('chowrasta_egg_dosa', 'Chowrasta Egg Dosa', 150.0, 6.0, 18.0, 6.0,
 0.5, 0.5, 170, 170,
 'chowrasta', ARRAY['chowrasta egg dosa'],
 'indian', 'Chowrasta', 1, '255 cal per dosa (170g).', TRUE,
 330.0, 100.0, 1.5, 0.0, 100.0, 22.0, 0.8, 50.0, 0.0, 8.0, 10.0, 0.5, 70.0, 8.0, 0.0),

('chowrasta_goat_keema_dosa', 'Chowrasta Goat Keema Dosa', 185.0, 9.0, 18.0, 8.5,
 0.5, 0.5, 220, 220,
 'chowrasta', ARRAY['chowrasta goat keema dosa', 'chowrasta goat kheema dosa'],
 'indian', 'Chowrasta', 1, '407 cal per dosa (220g). Dosa with minced goat.', TRUE,
 420.0, 40.0, 3.0, 0.0, 180.0, 15.0, 1.5, 5.0, 0.0, 3.0, 16.0, 1.8, 100.0, 8.0, 0.0),

('chowrasta_bangalore_masala_dosa', 'Chowrasta Bangalore Masala Dosa', 170.0, 4.0, 22.0, 7.0,
 1.5, 1.0, 210, 210,
 'chowrasta', ARRAY['chowrasta bangalore masala dosa'],
 'indian', 'Chowrasta', 1, '357 cal per dosa (210g). Bangalore-style with red chutney.', TRUE,
 380.0, 0.0, 1.2, 0.0, 175.0, 15.0, 0.8, 25.0, 4.0, 0.0, 14.0, 0.4, 55.0, 4.0, 0.0),

-- ==========================================
-- CHOWRASTA - INDO CHINESE
-- ==========================================

('chowrasta_chicken_fried_rice', 'Chowrasta Indian Street Style Chicken Fried Rice', 155.0, 7.0, 20.0, 5.5,
 0.5, 1.0, 350, NULL,
 'chowrasta', ARRAY['chowrasta chicken fried rice', 'chowrasta street chicken fried rice'],
 'indian', 'Chowrasta', 1, '543 cal per serving (350g).', TRUE,
 500.0, 35.0, 1.0, 0.0, 145.0, 16.0, 0.9, 12.0, 1.0, 2.0, 17.0, 0.8, 90.0, 11.0, 0.0),

('chowrasta_hakka_noodles', 'Chowrasta Hakka Noodles', 140.0, 4.0, 22.0, 4.0,
 1.0, 1.0, 350, NULL,
 'chowrasta', ARRAY['chowrasta hakka noodles'],
 'indian', 'Chowrasta', 1, '490 cal per serving (350g).', TRUE,
 480.0, 0.0, 0.6, 0.0, 110.0, 14.0, 0.7, 18.0, 3.0, 0.0, 12.0, 0.4, 42.0, 4.0, 0.0),

('chowrasta_egg_fried_rice', 'Chowrasta Indian Street Style Egg Fried Rice', 145.0, 5.5, 21.0, 4.5,
 0.5, 0.5, 350, NULL,
 'chowrasta', ARRAY['chowrasta egg fried rice'],
 'indian', 'Chowrasta', 1, '508 cal per serving (350g).', TRUE,
 490.0, 85.0, 1.0, 0.0, 125.0, 22.0, 0.9, 38.0, 1.0, 5.0, 13.0, 0.6, 68.0, 9.0, 0.0),

('chowrasta_veg_fried_rice', 'Chowrasta Indian Street Style Veg Fried Rice', 135.0, 3.5, 22.0, 3.5,
 1.0, 1.0, 350, NULL,
 'chowrasta', ARRAY['chowrasta veg fried rice'],
 'indian', 'Chowrasta', 1, '473 cal per serving (350g).', TRUE,
 470.0, 0.0, 0.6, 0.0, 115.0, 18.0, 0.7, 22.0, 3.0, 0.0, 14.0, 0.4, 45.0, 4.0, 0.0),

('chowrasta_schezwan_fried_rice', 'Chowrasta Schezwan Fried Rice', 148.0, 3.5, 23.0, 4.5,
 1.0, 1.5, 350, NULL,
 'chowrasta', ARRAY['chowrasta schezwan fried rice'],
 'indian', 'Chowrasta', 1, '518 cal per serving (350g).', TRUE,
 550.0, 0.0, 0.8, 0.0, 125.0, 20.0, 0.8, 25.0, 4.0, 0.0, 15.0, 0.5, 52.0, 5.0, 0.0),

-- ==========================================
-- CHOWRASTA - STREET STYLE
-- ==========================================

('chowrasta_paneer_frankie', 'Chowrasta Paneer Frankie', 215.0, 8.0, 24.0, 9.5,
 1.0, 1.5, 180, 180,
 'chowrasta', ARRAY['chowrasta paneer frankie'],
 'indian', 'Chowrasta', 1, '387 cal per frankie (180g).', TRUE,
 470.0, 12.0, 3.5, 0.0, 110.0, 60.0, 0.8, 22.0, 2.0, 0.0, 14.0, 0.5, 80.0, 4.0, 0.0),

('chowrasta_chicken_tikka_frankie', 'Chowrasta Chicken Tikka Frankie', 215.0, 10.5, 22.0, 9.5,
 1.0, 1.5, 180, 180,
 'chowrasta', ARRAY['chowrasta chicken tikka frankie'],
 'indian', 'Chowrasta', 1, '387 cal per frankie (180g).', TRUE,
 480.0, 35.0, 2.2, 0.0, 155.0, 18.0, 1.0, 12.0, 2.0, 2.0, 16.0, 0.8, 90.0, 10.0, 0.0),

('chowrasta_goat_keema_frankie', 'Chowrasta Goat Keema Frankie', 225.0, 11.0, 22.0, 10.5,
 1.0, 1.0, 180, 180,
 'chowrasta', ARRAY['chowrasta goat keema frankie'],
 'indian', 'Chowrasta', 1, '405 cal per frankie (180g).', TRUE,
 470.0, 40.0, 3.5, 0.0, 170.0, 15.0, 1.5, 5.0, 1.0, 3.0, 16.0, 1.8, 95.0, 8.0, 0.0),

('chowrasta_egg_frankie', 'Chowrasta Egg Frankie', 200.0, 8.0, 22.0, 8.5,
 1.0, 1.0, 170, 170,
 'chowrasta', ARRAY['chowrasta egg frankie'],
 'indian', 'Chowrasta', 1, '340 cal per frankie (170g).', TRUE,
 440.0, 140.0, 2.0, 0.0, 120.0, 30.0, 1.0, 60.0, 1.0, 8.0, 12.0, 0.6, 80.0, 10.0, 0.0),

('chowrasta_veg_frankie', 'Chowrasta Veg Frankie', 195.0, 5.0, 26.0, 8.0,
 2.0, 2.0, 170, 170,
 'chowrasta', ARRAY['chowrasta veg frankie'],
 'indian', 'Chowrasta', 1, '332 cal per frankie (170g).', TRUE,
 430.0, 0.0, 1.5, 0.0, 150.0, 18.0, 0.8, 15.0, 3.0, 0.0, 12.0, 0.3, 45.0, 3.0, 0.0),

('chowrasta_bread_omelette', 'Chowrasta Bread Omelette', 195.0, 10.0, 18.0, 9.5,
 1.0, 1.5, 200, 200,
 'chowrasta', ARRAY['chowrasta bread omelette', 'chowrasta bread omelet'],
 'indian', 'Chowrasta', 1, '390 cal per serving (200g).', TRUE,
 480.0, 280.0, 2.5, 0.0, 140.0, 40.0, 1.5, 100.0, 1.0, 15.0, 12.0, 0.8, 120.0, 15.0, 0.0),

-- ==========================================
-- CHOWRASTA - TANDOOR (new items)
-- ==========================================

('chowrasta_chicken_tikka', 'Chowrasta Chicken Tikka', 180.0, 20.0, 4.0, 9.0,
 0.5, 1.0, 175, 25,
 'chowrasta', ARRAY['chowrasta chicken tikka 7 pcs'],
 'indian', 'Chowrasta', 7, '315 cal per 7 pieces (175g).', TRUE,
 480.0, 60.0, 2.5, 0.0, 230.0, 15.0, 1.0, 15.0, 1.0, 3.0, 22.0, 1.5, 150.0, 18.0, 0.0),

('chowrasta_chicken_tandoori_platter', 'Chowrasta Chicken Tandoori Platter', 160.0, 22.0, 3.0, 7.0,
 0.0, 0.5, 350, NULL,
 'chowrasta', ARRAY['chowrasta tandoori platter', 'chowrasta chicken tandoori platter'],
 'indian', 'Chowrasta', 1, '560 cal per platter (350g). Weekend special.', TRUE,
 500.0, 75.0, 2.0, 0.0, 250.0, 18.0, 1.2, 25.0, 0.0, 3.0, 22.0, 1.8, 160.0, 20.0, 0.0),

('chowrasta_paneer_tikka_kebab', 'Chowrasta Paneer Tikka Kebab', 190.0, 12.0, 6.0, 13.0,
 0.5, 1.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta paneer tikka kebab 7 pcs'],
 'indian', 'Chowrasta', 7, '380 cal per 7 pieces (200g).', TRUE,
 420.0, 15.0, 5.5, 0.0, 100.0, 120.0, 0.8, 30.0, 3.0, 0.0, 16.0, 1.0, 140.0, 6.0, 0.0),

('chowrasta_chicken_tandoor_4pc', 'Chowrasta Chicken Tandoor (4 Pcs)', 160.0, 22.0, 3.0, 7.0,
 0.0, 0.5, 280, 70,
 'chowrasta', ARRAY['chowrasta chicken tandoor 4 pcs'],
 'indian', 'Chowrasta', 4, '448 cal per 4 pieces (280g).', TRUE,
 500.0, 75.0, 2.0, 0.0, 250.0, 18.0, 1.2, 25.0, 0.0, 3.0, 22.0, 1.8, 160.0, 20.0, 0.0),

('chowrasta_malai_chicken_tikka', 'Chowrasta Malai Chicken Tikka Kebab', 185.0, 18.0, 4.0, 10.5,
 0.3, 1.0, 175, 25,
 'chowrasta', ARRAY['chowrasta malai chicken tikka 7 pcs'],
 'indian', 'Chowrasta', 7, '324 cal per 7 pieces (175g). Creamy chicken tikka.', TRUE,
 440.0, 62.0, 4.0, 0.0, 210.0, 25.0, 0.8, 30.0, 1.0, 4.0, 20.0, 1.3, 140.0, 17.0, 0.0),

('chowrasta_garlic_naan', 'Chowrasta Garlic Naan', 280.0, 8.0, 40.0, 10.0,
 1.5, 2.0, 100, 100,
 'chowrasta', ARRAY['chowrasta garlic naan'],
 'indian', 'Chowrasta', 1, '280 cal per naan (100g).', TRUE,
 480.0, 5.0, 3.0, 0.0, 80.0, 35.0, 2.0, 10.0, 0.0, 0.0, 18.0, 0.5, 60.0, 10.0, 0.0),

('chowrasta_butter_naan', 'Chowrasta Butter Naan', 300.0, 7.5, 42.0, 12.0,
 1.0, 2.0, 90, 90,
 'chowrasta', ARRAY['chowrasta butter naan'],
 'indian', 'Chowrasta', 1, '270 cal per naan (90g).', TRUE,
 470.0, 10.0, 5.0, 0.0, 70.0, 30.0, 1.8, 35.0, 0.0, 0.0, 16.0, 0.4, 55.0, 9.0, 0.0),

('chowrasta_tandoori_roti', 'Chowrasta Tandoori Roti', 240.0, 7.5, 42.0, 4.5,
 2.0, 1.0, 70, 70,
 'chowrasta', ARRAY['chowrasta tandoori roti', 'chowrasta tandori roti'],
 'indian', 'Chowrasta', 1, '168 cal per roti (70g).', TRUE,
 350.0, 0.0, 0.8, 0.0, 100.0, 20.0, 2.0, 0.0, 0.0, 0.0, 20.0, 0.6, 70.0, 12.0, 0.0),

-- ==========================================
-- CHOWRASTA - THALI / COMBOS
-- ==========================================

('chowrasta_veg_thali', 'Chowrasta Veg Thali', 118.0, 3.8, 16.0, 4.2,
 1.5, 2.5, 550, NULL,
 'chowrasta', ARRAY['chowrasta veg thali', 'chowrasta vegetarian thali'],
 'indian', 'Chowrasta', 1, '649 cal per thali (550g).', TRUE,
 430.0, 0.0, 1.0, 0.0, 200.0, 35.0, 1.2, 20.0, 4.0, 0.0, 18.0, 0.5, 60.0, 4.0, 0.0),

('chowrasta_nonveg_thali', 'Chowrasta Non-Veg Thali', 128.0, 6.5, 14.0, 5.5,
 1.0, 2.0, 600, NULL,
 'chowrasta', ARRAY['chowrasta non veg thali', 'chowrasta nonveg thali'],
 'indian', 'Chowrasta', 1, '768 cal per thali (600g).', TRUE,
 460.0, 35.0, 1.8, 0.0, 200.0, 30.0, 1.5, 18.0, 3.0, 2.0, 20.0, 1.0, 95.0, 10.0, 0.0),

-- ==========================================
-- CHOWRASTA - RICE SPECIALS
-- ==========================================

('chowrasta_jeera_rice', 'Chowrasta Jeera Rice', 140.0, 3.0, 24.0, 3.5,
 0.5, 0.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta jeera rice', 'chowrasta cumin rice'],
 'indian', 'Chowrasta', 1, '420 cal per serving (300g).', TRUE,
 320.0, 0.0, 0.8, 0.0, 60.0, 10.0, 0.5, 0.0, 0.0, 0.0, 12.0, 0.4, 40.0, 5.0, 0.0),

('chowrasta_pulav_rice', 'Chowrasta Pulav Rice', 135.0, 3.0, 22.0, 3.5,
 0.5, 0.5, 300, NULL,
 'chowrasta', ARRAY['chowrasta pulav rice'],
 'indian', 'Chowrasta', 1, '405 cal per serving (300g).', TRUE,
 340.0, 0.0, 0.7, 0.0, 80.0, 12.0, 0.5, 10.0, 1.0, 0.0, 12.0, 0.3, 42.0, 4.0, 0.0),

-- ==========================================
-- CHOWRASTA - DESSERTS (new items)
-- ==========================================

('chowrasta_kala_jamun', 'Chowrasta Kala Jamun', 335.0, 4.0, 46.0, 15.0,
 0.3, 40.0, 90, 30,
 'chowrasta', ARRAY['chowrasta kala jamun', 'chowrasta black gulab jamun'],
 'desserts', 'Chowrasta', 3, '302 cal per 3 pieces (90g). Darker, denser version of gulab jamun.', TRUE,
 200.0, 10.0, 6.0, 0.2, 60.0, 30.0, 0.5, 15.0, 0.0, 2.0, 8.0, 0.3, 40.0, 3.0, 0.0),

('chowrasta_malai_bun', 'Chowrasta Malai Bun', 280.0, 5.0, 36.0, 13.0,
 0.5, 16.0, 80, 80,
 'chowrasta', ARRAY['chowrasta malai bun'],
 'desserts', 'Chowrasta', 1, '224 cal per bun (80g). Sweet bun with cream filling.', TRUE,
 250.0, 20.0, 6.0, 0.2, 70.0, 40.0, 0.8, 35.0, 0.0, 3.0, 8.0, 0.3, 50.0, 4.0, 0.0),

('chowrasta_dilkush', 'Chowrasta Dilkush', 350.0, 6.0, 42.0, 18.0,
 1.0, 18.0, 90, 90,
 'chowrasta', ARRAY['chowrasta dilkush', 'chowrasta dilkhush'],
 'desserts', 'Chowrasta', 1, '315 cal per piece (90g). Indian pastry with tutti-frutti & coconut.', TRUE,
 220.0, 25.0, 8.0, 0.3, 80.0, 25.0, 1.0, 30.0, 0.0, 2.0, 10.0, 0.3, 45.0, 5.0, 0.0),

-- ==========================================
-- CHOWRASTA - CHAAT (new items)
-- ==========================================

('chowrasta_spl_bhel_puri', 'Chowrasta Special Bhel Puri', 160.0, 4.0, 22.0, 6.0,
 2.0, 4.0, 180, NULL,
 'chowrasta', ARRAY['chowrasta spl bhel puri', 'chowrasta special bhel puri'],
 'indian', 'Chowrasta', 1, '288 cal per serving (180g).', TRUE,
 380.0, 0.0, 1.0, 0.0, 150.0, 15.0, 1.0, 5.0, 3.0, 0.0, 12.0, 0.4, 40.0, 2.0, 0.0),

('chowrasta_aloo_tikki_chat', 'Chowrasta Aloo Tikki Chat', 180.0, 4.0, 22.0, 8.0,
 1.5, 4.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta aloo tikki chat', 'chowrasta aloo tikki chaat'],
 'indian', 'Chowrasta', 1, '360 cal per serving (200g). Potato patties with chutneys.', TRUE,
 400.0, 0.0, 1.5, 0.0, 280.0, 20.0, 1.0, 5.0, 5.0, 0.0, 16.0, 0.3, 50.0, 2.0, 0.0),

('chowrasta_samosa_ragda', 'Chowrasta Samosa Ragda', 190.0, 5.0, 24.0, 8.5,
 2.5, 3.0, 200, NULL,
 'chowrasta', ARRAY['chowrasta samosa ragda'],
 'indian', 'Chowrasta', 1, '380 cal per serving (200g). Samosa with spiced pea curry.', TRUE,
 420.0, 0.0, 1.5, 0.0, 200.0, 20.0, 1.5, 5.0, 3.0, 0.0, 15.0, 0.4, 55.0, 3.0, 0.0),

('chowrasta_bhel_puri', 'Chowrasta Bhel Puri', 150.0, 4.0, 22.0, 5.0,
 1.5, 3.5, 170, NULL,
 'chowrasta', ARRAY['chowrasta bhel puri'],
 'indian', 'Chowrasta', 1, '255 cal per serving (170g). Puffed rice with chutneys.', TRUE,
 370.0, 0.0, 0.8, 0.0, 140.0, 12.0, 0.8, 3.0, 3.0, 0.0, 10.0, 0.3, 38.0, 2.0, 0.0),

('chowrasta_sev_puri', 'Chowrasta Sev Puri', 165.0, 3.5, 20.0, 7.5,
 1.0, 4.0, 170, NULL,
 'chowrasta', ARRAY['chowrasta sev puri'],
 'indian', 'Chowrasta', 1, '281 cal per serving (170g).', TRUE,
 380.0, 0.0, 1.2, 0.0, 130.0, 12.0, 0.8, 5.0, 3.0, 0.0, 10.0, 0.3, 35.0, 2.0, 0.0),

('chowrasta_papdi_chat', 'Chowrasta Papdi Chat', 175.0, 4.0, 20.0, 8.5,
 1.0, 4.0, 180, NULL,
 'chowrasta', ARRAY['chowrasta papdi chat', 'chowrasta papdi chaat'],
 'indian', 'Chowrasta', 1, '315 cal per serving (180g).', TRUE,
 390.0, 5.0, 1.5, 0.0, 140.0, 25.0, 0.8, 8.0, 2.0, 0.0, 10.0, 0.3, 40.0, 2.0, 0.0)

ON CONFLICT (food_name_normalized) DO NOTHING;
