-- 1001_indian_north.sql
-- Traditional North Indian foods (Punjab, UP, Rajasthan, Gujarat, MP, Haryana, HP, J&K)
-- All values per 100g. Sources: IFCT 2017 (Indian Food Composition Tables), USDA, nutritionix, tarladalal, snapcalorie

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

-- =====================================================================
-- PUNJABI DALS & LENTILS (~8 items)
-- =====================================================================

('dal_makhani', 'Dal Makhani', 120.0, 5.0, 13.0, 5.3, 2.5, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['dal makhani', 'maa ki dal', 'black dal', 'kali dal', 'maah di dal', 'kaali dal'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (250g). Slow-cooked black lentils (urad dal) with cream and butter.', TRUE,
 320, 10, 2.8, 0.1, 280, 30, 2.0, 8, 1.0, 0, 35, 0.9, 95, 2.0, 0.02),

('chana_dal_cooked', 'Chana Dal (Cooked)', 164.0, 8.9, 27.3, 2.6, 5.0, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['chana dal', 'chana daal', 'bengal gram dal', 'split chickpea dal', 'chana ki dal'],
 'indian', NULL, 1, 'Per 100g. ~328 cal per serving (200g). Split chickpea lentil, rich in protein and fiber.', TRUE,
 10, 0, 0.3, 0.0, 320, 28, 2.1, 3, 0.5, 0, 40, 1.2, 120, 3.5, 0.01),

('moong_dal_tadka', 'Moong Dal Tadka', 105.0, 7.0, 15.0, 2.2, 3.0, 0.8,
 250, NULL,
 'indian_traditional', ARRAY['moong dal tadka', 'moong daal tadka', 'yellow moong dal', 'green gram dal tadka', 'dhuli moong dal'],
 'indian', NULL, 1, 'Per 100g. ~263 cal per serving (250g). Tempered yellow lentils with cumin and ghee.', TRUE,
 180, 3, 0.8, 0.0, 260, 22, 1.8, 5, 1.2, 0, 32, 0.8, 100, 2.5, 0.01),

('masoor_dal_cooked', 'Masoor Dal (Cooked)', 116.0, 9.0, 20.0, 0.4, 7.5, 1.2,
 250, NULL,
 'indian_traditional', ARRAY['masoor dal', 'masoor daal', 'red lentil dal', 'lal masoor dal', 'malka masoor'],
 'indian', NULL, 1, 'Per 100g. ~290 cal per serving (250g). Red lentils, quick-cooking everyday dal.', TRUE,
 5, 0, 0.1, 0.0, 310, 18, 3.3, 2, 1.5, 0, 36, 1.3, 130, 2.8, 0.01),

('urad_dal_cooked', 'Urad Dal (Cooked)', 103.0, 7.6, 14.5, 2.0, 4.2, 0.5,
 250, NULL,
 'indian_traditional', ARRAY['urad dal', 'urad daal', 'black gram dal', 'urad ki dal', 'dhuli urad dal', 'white urad dal'],
 'indian', NULL, 1, 'Per 100g. ~258 cal per serving (250g). Split black gram, base for dal makhani when whole.', TRUE,
 8, 0, 0.3, 0.0, 290, 40, 2.8, 2, 0.8, 0, 48, 1.1, 115, 3.0, 0.01),

('dal_fry', 'Dal Fry', 95.0, 5.5, 12.0, 3.0, 2.8, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['dal fry', 'daal fry', 'restaurant style dal', 'tarka dal', 'fry dal'],
 'indian', NULL, 1, 'Per 100g. ~238 cal per serving (250g). Mixed lentils with onion-tomato tempering.', TRUE,
 250, 2, 1.0, 0.0, 220, 20, 1.6, 10, 2.0, 0, 28, 0.7, 85, 2.0, 0.01),

('panchmel_dal', 'Panchmel Dal', 110.0, 6.5, 14.0, 3.2, 3.5, 0.8,
 250, NULL,
 'indian_traditional', ARRAY['panchmel dal', 'panchratna dal', 'panch dal', 'five lentil dal', 'panchkuti dal', 'rajasthani panchmel dal'],
 'indian', NULL, 1, 'Per 100g. ~275 cal per serving (250g). Five-lentil mix (chana, moong, toor, masoor, urad) from Rajasthan.', TRUE,
 200, 3, 1.0, 0.0, 270, 25, 2.0, 5, 1.0, 0, 35, 0.9, 105, 2.5, 0.01),

('rajma_chawal', 'Rajma Chawal (Combo)', 145.0, 5.5, 24.0, 2.5, 3.0, 1.5,
 350, NULL,
 'indian_traditional', ARRAY['rajma chawal', 'rajma rice', 'rajma chawal combo', 'kidney bean rice', 'rajmah chawal'],
 'indian', NULL, 1, 'Per 100g. ~508 cal per serving (350g). Kidney bean curry with steamed rice combo.', TRUE,
 280, 0, 0.5, 0.0, 250, 28, 1.8, 5, 1.5, 0, 30, 0.8, 90, 3.0, 0.01),

-- =====================================================================
-- PUNJABI BREADS (~12 items)
-- =====================================================================

('makki_ki_roti', 'Makki Ki Roti', 173.0, 3.0, 28.1, 5.9, 2.5, 0.8,
 80, 80,
 'indian_traditional', ARRAY['makki ki roti', 'makki di roti', 'corn flour roti', 'makai ki roti', 'maize roti', 'bajre ki roti alternative'],
 'indian', NULL, 1, 'Per 100g. ~138 cal per roti (~80g). Punjabi cornmeal flatbread, paired with sarson ka saag.', TRUE,
 15, 0, 0.8, 0.0, 170, 8, 1.5, 6, 0.0, 0, 32, 0.6, 90, 6.0, 0.01),

('missi_roti', 'Missi Roti', 260.0, 8.5, 38.0, 8.0, 4.5, 1.2,
 70, 70,
 'indian_traditional', ARRAY['missi roti', 'besan roti', 'gram flour roti', 'missi ki roti', 'besan atta roti'],
 'indian', NULL, 1, 'Per 100g. ~182 cal per roti (~70g). Besan-wheat blend flatbread, higher protein than plain roti.', TRUE,
 280, 0, 1.2, 0.0, 200, 35, 2.2, 3, 0.5, 0, 30, 1.0, 100, 4.0, 0.01),

('tandoori_roti_plain', 'Tandoori Roti (Plain)', 200.0, 6.0, 40.0, 2.0, 3.5, 1.0,
 60, 60,
 'indian_traditional', ARRAY['tandoori roti', 'tandoori roti plain', 'clay oven roti', 'plain tandoori roti'],
 'indian', NULL, 1, 'Per 100g. ~120 cal per roti (~60g). Whole wheat bread baked in tandoor oven.', TRUE,
 300, 0, 0.4, 0.0, 130, 25, 1.8, 0, 0.0, 0, 28, 0.9, 100, 8.0, 0.01),

('laccha_paratha', 'Laccha Paratha', 326.0, 6.4, 45.4, 13.2, 2.0, 1.5,
 80, 80,
 'indian_traditional', ARRAY['laccha paratha', 'lachha paratha', 'layered paratha', 'flaky paratha', 'multi-layer paratha'],
 'indian', NULL, 1, 'Per 100g. ~261 cal per paratha (~80g). Multi-layered flaky flatbread with ghee.', TRUE,
 350, 8, 5.0, 0.2, 110, 20, 1.5, 15, 0.0, 2, 22, 0.7, 80, 6.0, 0.03),

('pudina_paratha', 'Pudina Paratha', 275.0, 6.0, 38.0, 11.0, 3.0, 1.0,
 75, 75,
 'indian_traditional', ARRAY['pudina paratha', 'mint paratha', 'pudine ka paratha', 'mint stuffed paratha'],
 'indian', NULL, 1, 'Per 100g. ~206 cal per paratha (~75g). Mint-flavored flatbread, refreshing and aromatic.', TRUE,
 300, 5, 3.5, 0.1, 150, 30, 2.0, 20, 3.0, 0, 25, 0.8, 85, 5.0, 0.01),

('gobi_paratha', 'Gobi Paratha', 240.0, 5.5, 34.0, 9.0, 2.5, 1.5,
 100, 100,
 'indian_traditional', ARRAY['gobi paratha', 'gobhi paratha', 'cauliflower paratha', 'gobi ka paratha', 'phool gobi paratha'],
 'indian', NULL, 1, 'Per 100g. ~240 cal per paratha (~100g). Cauliflower-stuffed flatbread, Punjabi breakfast staple.', TRUE,
 280, 5, 2.8, 0.1, 170, 28, 1.6, 8, 15.0, 0, 20, 0.7, 75, 5.0, 0.01),

('paneer_paratha', 'Paneer Paratha', 287.0, 9.0, 32.0, 14.0, 2.0, 1.8,
 100, 100,
 'indian_traditional', ARRAY['paneer paratha', 'paneer ka paratha', 'cottage cheese paratha', 'paneer stuffed paratha'],
 'indian', NULL, 1, 'Per 100g. ~287 cal per paratha (~100g). Paneer-stuffed flatbread, protein-rich.', TRUE,
 310, 20, 6.0, 0.2, 130, 80, 1.5, 25, 0.5, 2, 22, 1.2, 110, 5.0, 0.02),

('keema_paratha', 'Keema Paratha', 280.0, 12.0, 30.0, 13.0, 1.8, 1.0,
 110, 110,
 'indian_traditional', ARRAY['keema paratha', 'keema ka paratha', 'minced meat paratha', 'mutton keema paratha'],
 'indian', NULL, 1, 'Per 100g. ~308 cal per paratha (~110g). Spiced minced meat stuffed flatbread.', TRUE,
 350, 35, 5.5, 0.2, 180, 30, 2.5, 10, 1.0, 3, 25, 2.5, 120, 8.0, 0.03),

('kulcha_plain', 'Kulcha (Plain)', 280.0, 7.0, 45.0, 8.0, 1.5, 2.0,
 80, 80,
 'indian_traditional', ARRAY['kulcha', 'plain kulcha', 'naan kulcha', 'kulche'],
 'indian', NULL, 1, 'Per 100g. ~224 cal per kulcha (~80g). Leavened flatbread, similar to naan.', TRUE,
 400, 5, 2.5, 0.1, 90, 25, 1.5, 3, 0.0, 0, 18, 0.6, 70, 8.0, 0.01),

('amritsari_kulcha', 'Amritsari Kulcha', 270.0, 6.5, 40.0, 9.5, 2.0, 2.0,
 100, 100,
 'indian_traditional', ARRAY['amritsari kulcha', 'stuffed kulcha', 'aloo kulcha', 'amritsari aloo kulcha', 'kulcha amritsari'],
 'indian', NULL, 1, 'Per 100g. ~270 cal per kulcha (~100g). Potato-stuffed leavened bread from Amritsar.', TRUE,
 380, 5, 3.0, 0.1, 140, 28, 1.6, 5, 3.0, 0, 20, 0.7, 80, 6.0, 0.01),

('bhatura', 'Bhatura', 315.0, 7.0, 42.0, 13.5, 1.5, 2.5,
 75, 75,
 'indian_traditional', ARRAY['bhatura', 'bhatoora', 'bhature', 'chole bhature bread', 'puffed fried bread'],
 'indian', NULL, 1, 'Per 100g. ~236 cal per bhatura (~75g). Deep-fried leavened bread, paired with chole.', TRUE,
 320, 8, 3.5, 0.3, 100, 22, 1.8, 3, 0.0, 0, 18, 0.6, 70, 6.0, 0.02),

('roomali_roti', 'Roomali Roti', 220.0, 6.5, 38.0, 4.5, 2.0, 0.8,
 40, 40,
 'indian_traditional', ARRAY['roomali roti', 'rumali roti', 'handkerchief roti', 'thin roti', 'rumal roti'],
 'indian', NULL, 1, 'Per 100g. ~88 cal per roti (~40g). Paper-thin bread cooked on inverted tawa.', TRUE,
 250, 2, 1.0, 0.0, 100, 18, 1.5, 0, 0.0, 0, 20, 0.6, 75, 7.0, 0.01),

-- =====================================================================
-- PUNJABI MAIN DISHES (~12 items)
-- =====================================================================

('sarson_ka_saag', 'Sarson Ka Saag', 82.0, 3.5, 6.0, 5.0, 2.8, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['sarson ka saag', 'sarson da saag', 'mustard greens curry', 'saag sarson', 'mustard leaf curry'],
 'indian', NULL, 1, 'Per 100g. ~164 cal per serving (200g). Mustard greens with ghee, iconic Punjabi winter dish.', TRUE,
 180, 8, 2.5, 0.1, 350, 120, 2.5, 250, 35.0, 0, 40, 0.5, 55, 1.5, 0.15),

('chole_bhature_combo', 'Chole Bhature (Combo)', 220.0, 7.0, 30.0, 8.5, 3.5, 2.0,
 300, NULL,
 'indian_traditional', ARRAY['chole bhature', 'chhole bhature', 'chole bhatoore', 'chole bhatura combo', 'punjabi chole bhature'],
 'indian', NULL, 1, 'Per 100g. ~660 cal per plate (300g = 2 bhature + chole). Iconic Punjabi street food combo.', TRUE,
 420, 5, 2.5, 0.2, 200, 40, 2.5, 8, 2.0, 0, 30, 1.0, 90, 4.0, 0.02),

('butter_chicken_home', 'Butter Chicken (Home Style)', 175.0, 14.0, 6.0, 11.0, 0.8, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['butter chicken', 'murgh makhani', 'butter chicken home', 'homemade butter chicken', 'makhani chicken'],
 'indian', NULL, 1, 'Per 100g. ~350 cal per serving (200g). Home-style creamy tomato chicken curry.', TRUE,
 380, 65, 5.5, 0.2, 260, 35, 1.5, 45, 4.0, 5, 25, 1.8, 155, 18.0, 0.05),

('kadhi_pakora', 'Kadhi Pakora', 95.0, 3.5, 10.0, 4.5, 1.5, 2.0,
 250, NULL,
 'indian_traditional', ARRAY['kadhi pakora', 'kadhi pakoda', 'punjabi kadhi', 'besan kadhi', 'pakoda kadhi', 'kadi pakora'],
 'indian', NULL, 1, 'Per 100g. ~238 cal per serving (250g). Yogurt-gram flour curry with fried fritters.', TRUE,
 350, 5, 1.5, 0.1, 150, 50, 1.2, 8, 1.0, 0, 20, 0.5, 60, 2.0, 0.01),

('shahi_paneer', 'Shahi Paneer', 175.0, 8.0, 7.5, 13.0, 0.8, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['shahi paneer', 'royal paneer', 'mughlai paneer', 'paneer shahi', 'cream paneer curry'],
 'indian', NULL, 1, 'Per 100g. ~350 cal per serving (200g). Rich paneer in cashew-cream gravy.', TRUE,
 350, 25, 7.0, 0.2, 130, 120, 1.0, 40, 2.0, 3, 22, 1.0, 130, 3.0, 0.02),

('matar_paneer', 'Matar Paneer', 140.0, 6.5, 10.0, 8.5, 2.5, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['matar paneer', 'mattar paneer', 'peas paneer', 'paneer matar', 'mutter paneer'],
 'indian', NULL, 1, 'Per 100g. ~280 cal per serving (200g). Paneer and green peas in tomato-onion gravy.', TRUE,
 320, 18, 4.5, 0.1, 180, 90, 1.5, 30, 5.0, 2, 22, 0.9, 110, 3.0, 0.02),

('aloo_gobi', 'Aloo Gobi', 90.0, 2.5, 12.0, 3.5, 2.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['aloo gobi', 'aloo gobhi', 'potato cauliflower', 'gobi aloo', 'alu gobi', 'aloo phool gobi'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per serving (200g). Potato and cauliflower dry curry.', TRUE,
 250, 0, 0.5, 0.0, 280, 20, 0.8, 5, 25.0, 0, 18, 0.4, 50, 1.5, 0.01),

('baingan_bharta', 'Baingan Bharta', 85.0, 2.0, 8.0, 5.0, 3.0, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['baingan bharta', 'baingan ka bharta', 'roasted eggplant mash', 'bhartha', 'baigan bharta', 'vangyache bharit'],
 'indian', NULL, 1, 'Per 100g. ~170 cal per serving (200g). Smoky fire-roasted mashed eggplant.', TRUE,
 220, 0, 0.8, 0.0, 250, 15, 0.8, 12, 5.0, 0, 16, 0.3, 35, 0.5, 0.02),

('bharwa_karela', 'Bharwa Karela (Stuffed Bitter Gourd)', 110.0, 3.0, 8.0, 7.5, 3.5, 1.0,
 150, NULL,
 'indian_traditional', ARRAY['bharwa karela', 'stuffed karela', 'stuffed bitter gourd', 'karele ki sabzi', 'bharwa karele'],
 'indian', NULL, 1, 'Per 100g. ~165 cal per serving (150g). Bitter gourd stuffed with spiced onion-besan.', TRUE,
 280, 0, 1.2, 0.0, 300, 20, 1.0, 30, 35.0, 0, 22, 0.5, 40, 0.8, 0.01),

('amritsari_fish_fry', 'Amritsari Fish Fry', 230.0, 16.0, 12.0, 13.0, 0.5, 0.5,
 150, 60,
 'indian_traditional', ARRAY['amritsari fish fry', 'amritsari machhi', 'punjabi fish fry', 'fried fish punjabi', 'fish pakora amritsari'],
 'indian', NULL, 1, 'Per 100g. ~138 cal per piece (~60g). Spiced batter-fried fish, Amritsar specialty.', TRUE,
 420, 50, 3.0, 0.2, 280, 30, 1.5, 10, 1.0, 15, 28, 0.8, 180, 25.0, 0.15),

('tandoori_chicken_home', 'Tandoori Chicken (Home Style)', 165.0, 25.0, 4.2, 5.0, 0.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['tandoori chicken', 'tandoori murgh', 'home tandoori chicken', 'clay oven chicken', 'tikka murgh'],
 'indian', NULL, 1, 'Per 100g. ~330 cal per serving (200g). Yogurt-marinated chicken baked or grilled.', TRUE,
 450, 80, 1.5, 0.0, 280, 20, 1.5, 20, 2.0, 5, 28, 2.0, 200, 22.0, 0.04),

('chicken_tikka_home', 'Chicken Tikka (Home Style)', 150.0, 22.0, 3.0, 6.0, 0.3, 1.0,
 150, 30,
 'indian_traditional', ARRAY['chicken tikka', 'murgh tikka', 'tikka chicken', 'grilled chicken tikka', 'home chicken tikka'],
 'indian', NULL, 1, 'Per 100g. ~45 cal per tikka piece (~30g). Boneless yogurt-marinated grilled chicken.', TRUE,
 400, 70, 2.0, 0.0, 260, 18, 1.2, 15, 2.0, 5, 25, 1.8, 185, 20.0, 0.03),

('pinni', 'Pinni', 450.0, 8.0, 48.0, 25.0, 2.5, 30.0,
 40, 40,
 'indian_traditional', ARRAY['pinni', 'panjiri', 'atta pinni', 'punjabi pinni', 'gond pinni', 'winter sweet laddu'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per piece (~40g). Punjabi winter sweet with wheat flour, ghee, jaggery, dry fruits.', TRUE,
 15, 15, 12.0, 0.3, 200, 50, 2.5, 25, 0.5, 5, 35, 1.0, 100, 5.0, 0.05),

-- =====================================================================
-- UP / LUCKNOW (~18 items)
-- =====================================================================

('galouti_kebab', 'Galouti Kebab', 280.0, 18.0, 6.0, 20.0, 0.5, 1.0,
 100, 40,
 'indian_traditional', ARRAY['galouti kebab', 'galawti kebab', 'galoti kebab', 'melt in mouth kebab', 'lucknowi kebab'],
 'indian', NULL, 1, 'Per 100g. ~112 cal per kebab (~40g). Lucknowi melt-in-mouth minced meat patty.', TRUE,
 480, 70, 9.0, 0.3, 220, 18, 2.5, 8, 1.0, 3, 20, 3.5, 150, 12.0, 0.06),

('tunday_kebab', 'Tunday Kebab', 275.0, 17.0, 5.0, 20.5, 0.3, 0.8,
 100, 40,
 'indian_traditional', ARRAY['tunday kebab', 'tunde ke kebab', 'lucknow tunday kebab', 'tunday kabab'],
 'indian', NULL, 1, 'Per 100g. ~110 cal per kebab (~40g). Famous Lucknow kebab with 160 spices.', TRUE,
 500, 72, 9.5, 0.3, 210, 15, 2.8, 6, 0.5, 3, 18, 3.8, 145, 10.0, 0.05),

('shami_kebab', 'Shami Kebab', 250.0, 16.0, 10.0, 16.5, 1.5, 1.0,
 100, 50,
 'indian_traditional', ARRAY['shami kebab', 'shami kabab', 'shammi kebab', 'chana dal kebab', 'mutton shami kebab'],
 'indian', NULL, 1, 'Per 100g. ~125 cal per kebab (~50g). Minced meat and chana dal pan-fried patty.', TRUE,
 420, 65, 7.0, 0.2, 240, 25, 2.8, 10, 1.5, 3, 25, 3.0, 140, 10.0, 0.04),

('seekh_kebab', 'Seekh Kebab', 205.0, 18.0, 4.0, 13.0, 0.5, 0.8,
 120, 60,
 'indian_traditional', ARRAY['seekh kebab', 'seekh kabab', 'minced meat kebab', 'ground meat skewer', 'mutton seekh kebab'],
 'indian', NULL, 1, 'Per 100g. ~123 cal per seekh (~60g). Spiced minced meat grilled on skewers.', TRUE,
 450, 60, 5.5, 0.2, 250, 15, 2.2, 5, 1.0, 3, 22, 3.5, 160, 12.0, 0.04),

('kakori_kebab', 'Kakori Kebab', 270.0, 16.0, 3.0, 22.0, 0.2, 0.5,
 100, 40,
 'indian_traditional', ARRAY['kakori kebab', 'kakori kabab', 'gilafi kebab', 'lucknowi kakori'],
 'indian', NULL, 1, 'Per 100g. ~108 cal per kebab (~40g). Super-soft grilled skewered kebab from Kakori near Lucknow.', TRUE,
 460, 75, 10.0, 0.3, 200, 12, 2.0, 5, 0.5, 3, 18, 3.2, 135, 10.0, 0.05),

('nihari', 'Nihari', 140.0, 12.0, 4.0, 8.5, 0.5, 1.0,
 300, NULL,
 'indian_traditional', ARRAY['nihari', 'nahari', 'nalli nihari', 'mutton nihari', 'beef nihari', 'slow cooked stew'],
 'indian', NULL, 1, 'Per 100g. ~420 cal per serving (300g). Slow-cooked overnight meat stew with bone marrow.', TRUE,
 520, 55, 3.5, 0.2, 280, 20, 3.0, 5, 1.0, 5, 22, 4.0, 160, 12.0, 0.08),

('paya_curry', 'Paya (Trotters Curry)', 120.0, 10.0, 3.5, 7.5, 0.3, 0.5,
 300, NULL,
 'indian_traditional', ARRAY['paya', 'paya curry', 'trotters curry', 'goat trotters', 'lamb trotters curry', 'paaya'],
 'indian', NULL, 1, 'Per 100g. ~360 cal per serving (300g). Slow-cooked trotters, rich in collagen.', TRUE,
 480, 45, 3.0, 0.1, 200, 35, 2.0, 3, 0.5, 3, 15, 2.5, 120, 8.0, 0.06),

('awadhi_korma', 'Korma (Awadhi Style)', 160.0, 10.0, 8.0, 10.5, 1.0, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['awadhi korma', 'lucknowi korma', 'shahi korma', 'mutton korma', 'chicken korma awadhi'],
 'indian', NULL, 1, 'Per 100g. ~320 cal per serving (200g). Awadhi-style rich cashew-yogurt curry.', TRUE,
 380, 50, 4.5, 0.2, 230, 40, 1.5, 20, 2.0, 3, 25, 2.0, 140, 8.0, 0.04),

('dum_aloo_lucknowi', 'Dum Aloo (Lucknowi)', 130.0, 3.0, 14.0, 7.0, 1.5, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['dum aloo', 'dum aloo lucknowi', 'awadhi dum aloo', 'baby potato curry', 'dum aloo gravy'],
 'indian', NULL, 1, 'Per 100g. ~260 cal per serving (200g). Baby potatoes slow-cooked in rich yogurt gravy.', TRUE,
 340, 5, 3.0, 0.1, 280, 30, 1.0, 15, 8.0, 0, 22, 0.5, 55, 1.5, 0.01),

('sheermal', 'Sheermal', 320.0, 8.0, 48.0, 11.0, 1.0, 8.0,
 80, 80,
 'indian_traditional', ARRAY['sheermal', 'shirmal', 'saffron naan', 'mughlai bread', 'lucknowi sheermal'],
 'indian', NULL, 1, 'Per 100g. ~256 cal per sheermal (~80g). Saffron-milk flavored Lucknowi bread.', TRUE,
 300, 20, 5.0, 0.2, 100, 40, 1.5, 15, 0.0, 5, 18, 0.7, 80, 8.0, 0.02),

('bakarkhani', 'Bakarkhani', 380.0, 7.0, 45.0, 19.0, 1.5, 5.0,
 50, 50,
 'indian_traditional', ARRAY['bakarkhani', 'bakar khani', 'mughlai biscuit bread', 'puff bread lucknow'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per piece (~50g). Crisp layered bread with ghee, Mughlai style.', TRUE,
 350, 15, 10.0, 0.3, 80, 25, 1.5, 10, 0.0, 3, 15, 0.5, 60, 5.0, 0.02),

('tehri', 'Tehri (Veg Pulao UP Style)', 140.0, 3.0, 22.0, 4.5, 1.5, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['tehri', 'tahiri', 'tahari', 'veg pulao UP', 'tehri rice', 'vegetable rice UP'],
 'indian', NULL, 1, 'Per 100g. ~350 cal per serving (250g). UP-style vegetable rice with potato and spices.', TRUE,
 300, 0, 1.5, 0.1, 150, 15, 0.8, 10, 3.0, 0, 15, 0.4, 45, 3.0, 0.01),

('khichdi_moong', 'Khichdi (Moong Dal)', 110.0, 4.5, 18.0, 2.0, 1.5, 0.5,
 250, NULL,
 'indian_traditional', ARRAY['khichdi', 'khichri', 'moong dal khichdi', 'dal chawal khichdi', 'comfort food khichdi'],
 'indian', NULL, 1, 'Per 100g. ~275 cal per serving (250g). Rice and moong dal comfort food, easy to digest.', TRUE,
 200, 3, 0.8, 0.0, 140, 15, 1.0, 5, 0.5, 0, 18, 0.5, 65, 3.0, 0.01),

('petha', 'Petha (Agra)', 305.0, 0.5, 74.0, 0.2, 0.3, 60.0,
 40, 40,
 'indian_traditional', ARRAY['petha', 'agra petha', 'agra ka petha', 'ash gourd sweet', 'safed petha', 'angoori petha'],
 'indian', NULL, 1, 'Per 100g. ~122 cal per piece (~40g). Agra-famous translucent ash gourd sweet.', TRUE,
 15, 0, 0.0, 0.0, 30, 10, 0.3, 0, 2.0, 0, 5, 0.1, 8, 0.2, 0.0),

('balushahi', 'Balushahi', 360.0, 4.0, 50.0, 16.0, 0.5, 30.0,
 40, 40,
 'indian_traditional', ARRAY['balushahi', 'balushai', 'badusha', 'balu shahi', 'khurmi'],
 'indian', NULL, 1, 'Per 100g. ~144 cal per piece (~40g). Deep-fried flaky pastry soaked in sugar syrup.', TRUE,
 20, 8, 7.0, 0.3, 60, 15, 1.0, 5, 0.0, 2, 10, 0.3, 40, 3.0, 0.01),

-- =====================================================================
-- RAJASTHANI (~18 items)
-- =====================================================================

('dal_baati', 'Dal Baati (Without Churma)', 182.0, 7.0, 22.0, 8.0, 3.0, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['dal baati', 'daal baati', 'dal bati', 'rajasthani dal baati'],
 'indian', NULL, 1, 'Per 100g. ~455 cal per serving (250g = 1 baati + dal). Hard wheat balls with dal.', TRUE,
 280, 8, 3.5, 0.1, 250, 30, 2.0, 5, 1.0, 2, 30, 0.9, 100, 5.0, 0.02),

('churma', 'Churma', 420.0, 5.0, 55.0, 20.0, 1.5, 28.0,
 60, NULL,
 'indian_traditional', ARRAY['churma', 'rajasthani churma', 'crushed baati sweet', 'churma laddu'],
 'indian', NULL, 1, 'Per 100g. ~252 cal per serving (60g). Crushed baati with ghee and jaggery.', TRUE,
 10, 15, 10.0, 0.3, 100, 25, 1.5, 20, 0.0, 3, 18, 0.5, 60, 4.0, 0.03),

('dal_baati_churma', 'Dal Baati Churma (Combo)', 210.0, 6.0, 28.0, 9.0, 2.5, 8.0,
 350, NULL,
 'indian_traditional', ARRAY['dal baati churma', 'dal bati churma', 'rajasthani thali combo', 'daal baati churma'],
 'indian', NULL, 1, 'Per 100g. ~735 cal per full serving (350g). Complete Rajasthani combo: dal + baati + churma.', TRUE,
 200, 10, 4.0, 0.2, 200, 28, 1.8, 10, 0.8, 2, 25, 0.8, 85, 4.0, 0.02),

('laal_maas', 'Laal Maas (Red Meat Curry)', 155.0, 14.0, 3.5, 10.0, 1.0, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['laal maas', 'lal maas', 'red meat curry', 'rajasthani laal maas', 'lal maans', 'ratto maas'],
 'indian', NULL, 1, 'Per 100g. ~310 cal per serving (200g). Fiery red chili mutton curry from Rajasthan.', TRUE,
 480, 65, 4.5, 0.2, 320, 20, 2.5, 80, 5.0, 3, 22, 4.0, 165, 10.0, 0.06),

('gatte_ki_sabzi', 'Gatte Ki Sabzi', 145.0, 5.5, 12.0, 8.5, 2.0, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['gatte ki sabzi', 'besan gatte', 'gatta curry', 'gatte ki kadhi', 'rajasthani gatte'],
 'indian', NULL, 1, 'Per 100g. ~290 cal per serving (200g). Gram flour dumplings in yogurt curry.', TRUE,
 350, 5, 2.5, 0.1, 180, 40, 1.5, 10, 1.5, 0, 22, 0.8, 70, 3.0, 0.01),

('ker_sangri', 'Ker Sangri', 125.0, 4.0, 8.0, 8.5, 4.5, 1.5,
 150, NULL,
 'indian_traditional', ARRAY['ker sangri', 'ker sangri ki sabzi', 'desert beans', 'kair sangri', 'rajasthani desert vegetable'],
 'indian', NULL, 1, 'Per 100g. ~188 cal per serving (150g). Dried desert berries and beans, unique Rajasthani dish.', TRUE,
 350, 0, 1.2, 0.0, 320, 60, 3.5, 15, 4.0, 0, 45, 0.8, 70, 2.0, 0.02),

('papad_ki_sabzi', 'Papad Ki Sabzi', 130.0, 4.0, 12.0, 7.5, 1.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['papad ki sabzi', 'papad ki sabji', 'papad curry', 'rajasthani papad sabzi'],
 'indian', NULL, 1, 'Per 100g. ~260 cal per serving (200g). Papad cooked in spiced yogurt gravy, Rajasthani comfort food.', TRUE,
 450, 3, 2.0, 0.1, 150, 35, 1.2, 8, 2.0, 0, 18, 0.6, 55, 2.0, 0.01),

('bajra_roti', 'Bajra Roti', 180.0, 4.5, 30.0, 5.0, 3.5, 0.5,
 80, 80,
 'indian_traditional', ARRAY['bajra roti', 'bajre ki roti', 'pearl millet roti', 'bajra rotla', 'bajri rotla'],
 'indian', NULL, 1, 'Per 100g. ~144 cal per roti (~80g). Pearl millet flatbread, traditional in Rajasthan and Gujarat.', TRUE,
 10, 0, 0.8, 0.0, 195, 22, 3.0, 3, 0.0, 0, 60, 1.5, 140, 4.0, 0.01),

('bajra_khichdi', 'Bajra Khichdi', 120.0, 4.0, 18.0, 3.5, 2.5, 0.5,
 250, NULL,
 'indian_traditional', ARRAY['bajra khichdi', 'bajre ki khichdi', 'pearl millet khichdi', 'bajra dal khichdi'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (250g). Pearl millet and moong dal porridge, Rajasthani winter staple.', TRUE,
 180, 3, 1.2, 0.0, 180, 18, 2.5, 3, 0.5, 0, 45, 1.0, 110, 3.5, 0.01),

('ghevar', 'Ghevar', 425.0, 4.0, 55.0, 20.0, 0.5, 35.0,
 80, 80,
 'indian_traditional', ARRAY['ghevar', 'ghewar', 'rajasthani ghevar', 'mawa ghevar', 'malai ghevar'],
 'indian', NULL, 1, 'Per 100g. ~340 cal per piece (~80g). Disc-shaped Rajasthani festive sweet, deep-fried honeycomb.', TRUE,
 20, 10, 10.0, 0.5, 80, 90, 1.0, 12, 0.0, 2, 12, 0.4, 50, 2.0, 0.02),

('pyaaz_kachori', 'Pyaaz Ki Kachori', 320.0, 6.0, 35.0, 17.0, 2.5, 3.0,
 60, 60,
 'indian_traditional', ARRAY['pyaaz ki kachori', 'onion kachori', 'rajasthani kachori', 'pyaz kachori', 'jodhpuri kachori'],
 'indian', NULL, 1, 'Per 100g. ~192 cal per kachori (~60g). Crispy onion-filled deep-fried pastry from Jodhpur.', TRUE,
 380, 3, 4.5, 0.3, 150, 20, 1.5, 5, 2.0, 0, 18, 0.6, 60, 3.0, 0.01),

('mawa_kachori', 'Mawa Kachori', 380.0, 5.0, 45.0, 20.0, 1.0, 22.0,
 60, 60,
 'indian_traditional', ARRAY['mawa kachori', 'khoya kachori', 'sweet kachori', 'mawa sweet samosa', 'jodhpuri mawa kachori'],
 'indian', NULL, 1, 'Per 100g. ~228 cal per kachori (~60g). Sweet kachori filled with khoya and dry fruits.', TRUE,
 30, 15, 9.0, 0.4, 100, 40, 1.0, 15, 0.0, 2, 15, 0.5, 50, 3.0, 0.02),

('mirchi_bada', 'Mirchi Bada', 250.0, 5.0, 28.0, 13.0, 2.0, 2.5,
 60, 60,
 'indian_traditional', ARRAY['mirchi bada', 'mirchi vada', 'chili fritter', 'rajasthani mirchi bada', 'stuffed chili fritter'],
 'indian', NULL, 1, 'Per 100g. ~150 cal per piece (~60g). Large green chili stuffed with potato, battered and fried.', TRUE,
 350, 0, 2.5, 0.2, 180, 20, 1.0, 15, 20.0, 0, 15, 0.5, 55, 2.0, 0.01),

('bikaneri_bhujia', 'Bikaneri Bhujia', 530.0, 16.0, 45.0, 32.0, 5.0, 2.0,
 30, NULL,
 'indian_traditional', ARRAY['bikaneri bhujia', 'bhujia', 'moth bhujia', 'bhujiya', 'haldiram bhujia', 'besan sev'],
 'indian', NULL, 1, 'Per 100g. ~159 cal per serving (30g). Crispy gram flour noodle snack from Bikaner.', TRUE,
 800, 0, 5.0, 0.5, 350, 30, 3.0, 3, 0.5, 0, 50, 1.5, 120, 4.0, 0.01),

('bajra_raab', 'Bajra Raab', 55.0, 1.5, 8.0, 1.5, 0.8, 3.0,
 250, NULL,
 'indian_traditional', ARRAY['bajra raab', 'raab', 'bajra porridge', 'millet raab', 'rajasthani raab'],
 'indian', NULL, 1, 'Per 100g. ~138 cal per serving (250g). Warm pearl millet porridge with jaggery, winter drink.', TRUE,
 10, 0, 0.3, 0.0, 80, 12, 1.2, 2, 0.0, 0, 25, 0.5, 50, 2.0, 0.01),

('makhaniya_lassi', 'Makhaniya Lassi', 95.0, 3.0, 14.0, 3.0, 0.0, 12.0,
 300, NULL,
 'indian_traditional', ARRAY['makhaniya lassi', 'rajasthani lassi', 'creamy lassi', 'jodhpuri lassi', 'malai lassi'],
 'indian', NULL, 1, 'Per 100g. ~285 cal per glass (300ml). Thick creamy saffron lassi, Jodhpur specialty.', TRUE,
 40, 12, 1.8, 0.1, 150, 100, 0.2, 15, 1.0, 3, 12, 0.4, 80, 2.0, 0.01),

-- =====================================================================
-- GUJARATI (~22 items)
-- =====================================================================

('undhiyu', 'Undhiyu', 150.0, 4.0, 15.0, 8.5, 3.5, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['undhiyu', 'oondhiya', 'undhiyo', 'gujarati undhiyu', 'surti undhiyu', 'winter mixed veg'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Mixed vegetable Gujarati specialty with fenugreek dumplings.', TRUE,
 280, 0, 2.0, 0.1, 300, 35, 2.0, 30, 10.0, 0, 30, 0.8, 70, 2.0, 0.03),

('handvo', 'Handvo', 170.0, 5.5, 24.0, 6.0, 2.5, 1.5,
 150, NULL,
 'indian_traditional', ARRAY['handvo', 'handwa', 'gujarati handvo', 'lentil cake', 'mixed dal cake'],
 'indian', NULL, 1, 'Per 100g. ~255 cal per serving (150g). Savory rice-lentil baked cake with vegetables.', TRUE,
 300, 0, 1.0, 0.0, 200, 20, 1.5, 10, 3.0, 0, 25, 0.7, 80, 3.0, 0.01),

('thepla', 'Thepla', 260.0, 7.0, 35.0, 10.0, 3.0, 1.0,
 50, 50,
 'indian_traditional', ARRAY['thepla', 'methi thepla', 'gujarati thepla', 'fenugreek flatbread', 'theple'],
 'indian', NULL, 1, 'Per 100g. ~130 cal per thepla (~50g). Fenugreek-spiced flatbread, perfect travel food.', TRUE,
 300, 0, 2.0, 0.1, 180, 30, 2.5, 15, 2.0, 0, 28, 0.8, 90, 5.0, 0.01),

('khaman_dhokla', 'Khaman Dhokla', 135.0, 5.0, 23.0, 3.0, 2.2, 4.0,
 100, NULL,
 'indian_traditional', ARRAY['khaman dhokla', 'khaman', 'besan dhokla', 'gujarati dhokla', 'yellow dhokla', 'nylon khaman'],
 'indian', NULL, 1, 'Per 100g. ~135 cal per serving (100g). Steamed gram flour cake, light and spongy.', TRUE,
 350, 0, 0.5, 0.0, 180, 25, 1.8, 3, 0.5, 0, 22, 0.7, 75, 3.0, 0.01),

('khandvi', 'Khandvi', 200.0, 6.0, 25.0, 8.0, 1.5, 2.0,
 80, NULL,
 'indian_traditional', ARRAY['khandvi', 'patuli', 'dahivadi', 'gujarati khandvi', 'besan roll'],
 'indian', NULL, 1, 'Per 100g. ~160 cal per serving (80g). Thin besan-yogurt rolls with mustard tempering.', TRUE,
 320, 3, 2.0, 0.0, 150, 30, 1.2, 5, 1.0, 0, 18, 0.5, 60, 2.5, 0.01),

('sev_tameta', 'Sev Tameta Nu Shaak', 130.0, 3.0, 15.0, 6.5, 2.0, 5.0,
 200, NULL,
 'indian_traditional', ARRAY['sev tameta', 'sev tameta nu shaak', 'sev tomato curry', 'gujarati sev tameta', 'tomato sev sabzi'],
 'indian', NULL, 1, 'Per 100g. ~260 cal per serving (200g). Tangy tomato curry topped with crispy sev.', TRUE,
 350, 0, 1.5, 0.1, 250, 15, 1.0, 40, 15.0, 0, 15, 0.4, 35, 1.5, 0.01),

('ringan_olo', 'Ringan Nu Olo (Baingan)', 110.0, 2.5, 10.0, 7.0, 3.0, 4.0,
 200, NULL,
 'indian_traditional', ARRAY['ringan nu olo', 'olo', 'gujarati baingan', 'spiced eggplant gujarati', 'ringan no olo'],
 'indian', NULL, 1, 'Per 100g. ~220 cal per serving (200g). Gujarati sweet-tangy mashed eggplant.', TRUE,
 200, 0, 1.0, 0.0, 230, 12, 0.8, 10, 4.0, 0, 15, 0.3, 30, 0.5, 0.01),

('dal_dhokli', 'Dal Dhokli', 120.0, 4.5, 18.0, 3.5, 2.0, 3.0,
 300, NULL,
 'indian_traditional', ARRAY['dal dhokli', 'daal dhokli', 'gujarati dal dhokli', 'wheat dumpling dal', 'varan phal'],
 'indian', NULL, 1, 'Per 100g. ~360 cal per serving (300g). Wheat flour dumplings cooked in sweet-tangy toor dal.', TRUE,
 250, 0, 0.8, 0.0, 200, 20, 1.5, 5, 2.0, 0, 22, 0.6, 70, 3.0, 0.01),

('gujarati_kadhi', 'Gujarati Kadhi', 65.0, 2.5, 8.0, 2.5, 0.5, 4.0,
 250, NULL,
 'indian_traditional', ARRAY['gujarati kadhi', 'sweet kadhi', 'kadhi gujarati', 'meethi kadhi', 'gujarati kadi'],
 'indian', NULL, 1, 'Per 100g. ~163 cal per serving (250g). Sweet-tangy yogurt curry, thinner than Punjabi kadhi.', TRUE,
 200, 3, 0.8, 0.0, 120, 40, 0.5, 5, 1.0, 0, 12, 0.3, 45, 1.5, 0.01),

('fafda', 'Fafda', 480.0, 12.0, 42.0, 30.0, 4.0, 1.0,
 50, NULL,
 'indian_traditional', ARRAY['fafda', 'gujarati fafda', 'besan fafda', 'crispy gram flour strips'],
 'indian', NULL, 1, 'Per 100g. ~240 cal per serving (50g). Crispy gram flour strips, paired with jalebi.', TRUE,
 600, 0, 5.0, 0.3, 250, 25, 2.5, 2, 0.0, 0, 40, 1.0, 100, 3.0, 0.01),

('fafda_jalebi_combo', 'Fafda Jalebi (Combo)', 400.0, 6.0, 55.0, 18.0, 2.0, 25.0,
 120, NULL,
 'indian_traditional', ARRAY['fafda jalebi', 'fafda jalebi combo', 'gujarati breakfast', 'sunday fafda jalebi'],
 'indian', NULL, 1, 'Per 100g. ~480 cal per serving (120g). Classic Gujarati Sunday breakfast combo.', TRUE,
 350, 0, 4.0, 0.3, 150, 20, 1.5, 2, 0.5, 0, 25, 0.6, 60, 2.5, 0.01),

('gathiya', 'Gathiya', 550.0, 14.0, 40.0, 38.0, 3.5, 1.5,
 30, NULL,
 'indian_traditional', ARRAY['gathiya', 'gathia', 'gujarati gathiya', 'thick sev', 'bhavnagri gathiya'],
 'indian', NULL, 1, 'Per 100g. ~165 cal per serving (30g). Thick crispy gram flour snack from Gujarat.', TRUE,
 650, 0, 6.0, 0.4, 280, 28, 2.8, 2, 0.0, 0, 45, 1.2, 110, 3.5, 0.01),

('muthiya', 'Muthiya', 180.0, 5.0, 25.0, 7.0, 3.0, 2.0,
 120, NULL,
 'indian_traditional', ARRAY['muthiya', 'muthia', 'gujarati muthiya', 'steamed dumplings', 'dudhi muthiya', 'lauki muthiya'],
 'indian', NULL, 1, 'Per 100g. ~216 cal per serving (120g). Steamed or fried mixed flour dumplings with vegetables.', TRUE,
 280, 0, 1.2, 0.0, 200, 25, 2.0, 15, 5.0, 0, 25, 0.7, 75, 3.0, 0.01),

('patra', 'Patra (Colocasia Leaves Roll)', 155.0, 4.0, 20.0, 7.0, 3.5, 3.0,
 100, NULL,
 'indian_traditional', ARRAY['patra', 'patrode', 'alu vadi', 'colocasia leaf roll', 'arbi patta roll', 'pathrodo'],
 'indian', NULL, 1, 'Per 100g. ~155 cal per serving (100g). Spiced gram flour layered on taro leaves, steamed and fried.', TRUE,
 270, 0, 1.0, 0.0, 250, 35, 1.5, 50, 6.0, 0, 30, 0.6, 55, 1.5, 0.02),

('sev_khamani', 'Sev Khamani', 180.0, 6.0, 28.0, 5.0, 2.0, 5.0,
 100, NULL,
 'indian_traditional', ARRAY['sev khamani', 'sev khaman', 'crumbled dhokla', 'gujarati sev khamani'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per serving (100g). Crumbled dhokla with sweet-tangy tempering and sev.', TRUE,
 380, 0, 1.0, 0.0, 170, 22, 1.5, 3, 1.0, 0, 20, 0.6, 65, 2.5, 0.01),

('dabeli', 'Dabeli', 210.0, 4.5, 28.0, 9.0, 2.0, 5.0,
 120, 120,
 'indian_traditional', ARRAY['dabeli', 'kutchi dabeli', 'double roti', 'dabeli pav', 'gujarati dabeli'],
 'indian', NULL, 1, 'Per 100g. ~252 cal per dabeli (~120g). Spiced potato in pav with peanuts, pomegranate, sev.', TRUE,
 350, 0, 1.5, 0.1, 200, 18, 1.0, 8, 5.0, 0, 18, 0.5, 50, 2.0, 0.02),

('gujarati_dal', 'Gujarati Dal (Sweet Dal)', 80.0, 4.0, 12.0, 1.8, 2.0, 5.0,
 250, NULL,
 'indian_traditional', ARRAY['gujarati dal', 'sweet dal', 'meethi dal', 'gujarati toor dal', 'khatti meethi dal'],
 'indian', NULL, 1, 'Per 100g. ~200 cal per serving (250g). Sweet-tangy-spicy toor dal, unique Gujarati style.', TRUE,
 150, 0, 0.3, 0.0, 200, 18, 1.2, 5, 2.0, 0, 22, 0.6, 65, 2.5, 0.01),

('mohanthal', 'Mohanthal', 450.0, 8.0, 50.0, 24.0, 2.0, 32.0,
 30, 30,
 'indian_traditional', ARRAY['mohanthal', 'mohan thal', 'besan barfi', 'gujarati mohanthal', 'gram flour fudge'],
 'indian', NULL, 1, 'Per 100g. ~135 cal per piece (~30g). Rich besan fudge with ghee and cardamom.', TRUE,
 15, 20, 12.0, 0.3, 120, 35, 1.5, 20, 0.0, 3, 20, 0.8, 80, 3.0, 0.02),

('basundi', 'Basundi', 195.0, 5.5, 28.0, 7.0, 0.0, 24.0,
 120, NULL,
 'indian_traditional', ARRAY['basundi', 'gujarati basundi', 'sweetened condensed milk', 'rabdi gujarati', 'basundi sweet'],
 'indian', NULL, 1, 'Per 100g. ~234 cal per serving (120g). Sweetened reduced milk dessert with nuts and saffron.', TRUE,
 50, 25, 4.5, 0.1, 180, 130, 0.3, 40, 1.0, 10, 15, 0.5, 100, 3.0, 0.02),

('shrikhand', 'Shrikhand', 240.0, 5.0, 40.0, 6.5, 0.0, 35.0,
 80, NULL,
 'indian_traditional', ARRAY['shrikhand', 'srikhand', 'gujarati shrikhand', 'hung curd sweet', 'kesar shrikhand', 'amrakhand'],
 'indian', NULL, 1, 'Per 100g. ~192 cal per serving (80g). Sweetened strained yogurt with saffron and cardamom.', TRUE,
 30, 18, 4.0, 0.1, 150, 110, 0.2, 15, 0.5, 5, 12, 0.4, 85, 2.5, 0.01),

-- =====================================================================
-- KASHMIRI (~14 items)
-- =====================================================================

('rogan_josh', 'Rogan Josh', 150.0, 15.0, 4.0, 8.5, 1.0, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['rogan josh', 'roghan josh', 'kashmiri rogan josh', 'lamb rogan josh', 'mutton rogan josh'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Kashmiri aromatic lamb curry with red chili.', TRUE,
 420, 60, 3.5, 0.2, 300, 22, 2.5, 60, 3.0, 3, 22, 4.0, 170, 12.0, 0.06),

('yakhni', 'Yakhni (Kashmiri Yogurt Curry)', 120.0, 12.0, 3.5, 6.5, 0.3, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['yakhni', 'yakhni curry', 'kashmiri yakhni', 'yogurt lamb curry', 'chicken yakhni'],
 'indian', NULL, 1, 'Per 100g. ~240 cal per serving (200g). Mild yogurt-based meat curry with fennel and cardamom.', TRUE,
 380, 50, 3.0, 0.1, 250, 45, 1.5, 10, 1.0, 3, 20, 2.5, 150, 10.0, 0.04),

('dum_aloo_kashmiri', 'Dum Aloo (Kashmiri)', 145.0, 3.5, 15.0, 8.0, 1.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['dum aloo kashmiri', 'kashmiri dum aloo', 'kashmiri dum olav', 'yogurt potato curry kashmiri'],
 'indian', NULL, 1, 'Per 100g. ~290 cal per serving (200g). Baby potatoes in yogurt-fennel gravy, Kashmiri style.', TRUE,
 350, 3, 3.5, 0.1, 290, 35, 1.2, 12, 8.0, 0, 20, 0.5, 55, 1.5, 0.01),

('haak_saag', 'Haak Saag (Kashmiri Greens)', 60.0, 3.0, 4.5, 3.5, 2.5, 0.8,
 200, NULL,
 'indian_traditional', ARRAY['haak saag', 'haak', 'kashmiri collard greens', 'haak saag kashmir', 'kashmiri greens'],
 'indian', NULL, 1, 'Per 100g. ~120 cal per serving (200g). Kashmiri collard greens cooked with mustard oil.', TRUE,
 250, 0, 0.5, 0.0, 350, 150, 2.5, 200, 40.0, 0, 35, 0.5, 45, 1.0, 0.15),

('nadru_yakhni', 'Nadru Yakhni (Lotus Stem Curry)', 95.0, 4.0, 10.0, 4.5, 2.0, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['nadru yakhni', 'nadru', 'lotus stem curry', 'kamal kakdi yakhni', 'kashmiri nadru'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per serving (200g). Lotus stem in mild yogurt curry.', TRUE,
 340, 8, 2.0, 0.1, 280, 40, 1.0, 5, 12.0, 0, 22, 0.6, 80, 2.0, 0.02),

('tabak_maaz', 'Tabak Maaz (Fried Ribs)', 300.0, 18.0, 2.0, 24.0, 0.0, 0.0,
 150, NULL,
 'indian_traditional', ARRAY['tabak maaz', 'tabaak maaz', 'fried ribs kashmiri', 'lamb ribs kashmiri', 'crispy lamb ribs'],
 'indian', NULL, 1, 'Per 100g. ~450 cal per serving (150g). Milk-boiled then deep-fried lamb ribs, Kashmiri feast dish.', TRUE,
 450, 90, 11.0, 0.5, 200, 15, 2.0, 0, 0.0, 5, 18, 4.5, 160, 10.0, 0.05),

('gushtaba', 'Gushtaba', 135.0, 10.0, 4.0, 9.0, 0.3, 1.5,
 250, NULL,
 'indian_traditional', ARRAY['gushtaba', 'goshtaba', 'kashmiri meatball curry', 'yogurt meatball curry', 'wazwan gushtaba'],
 'indian', NULL, 1, 'Per 100g. ~338 cal per serving (250g). Pounded mutton balls in rich yogurt gravy, Wazwan dish.', TRUE,
 400, 55, 4.0, 0.2, 220, 40, 1.8, 8, 0.5, 3, 18, 3.0, 130, 8.0, 0.05),

('rista', 'Rista (Kashmiri Red Meatballs)', 155.0, 12.0, 5.0, 10.0, 0.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['rista', 'rishta', 'kashmiri rista', 'red meatball curry', 'wazwan rista'],
 'indian', NULL, 1, 'Per 100g. ~310 cal per serving (200g). Vibrant red pounded mutton meatball curry.', TRUE,
 430, 60, 4.5, 0.2, 250, 20, 2.5, 70, 4.0, 3, 20, 3.5, 145, 10.0, 0.05),

('kashmiri_pulao', 'Kashmiri Pulao', 170.0, 3.5, 28.0, 5.0, 1.0, 5.0,
 200, NULL,
 'indian_traditional', ARRAY['kashmiri pulao', 'kashmiri rice', 'sweet rice kashmiri', 'fruit pulao', 'kashmiri meetha pulao'],
 'indian', NULL, 1, 'Per 100g. ~340 cal per serving (200g). Sweet saffron rice with dry fruits and cherries.', TRUE,
 100, 0, 2.5, 0.1, 120, 15, 0.8, 10, 1.0, 0, 15, 0.4, 50, 4.0, 0.03),

('girda', 'Girda (Kashmiri Bread)', 280.0, 8.0, 50.0, 5.0, 2.0, 2.0,
 80, 80,
 'indian_traditional', ARRAY['girda', 'girda roti', 'kashmiri bread', 'girda naan', 'tandoori girda'],
 'indian', NULL, 1, 'Per 100g. ~224 cal per girda (~80g). Round Kashmiri bread baked in tandoor.', TRUE,
 350, 0, 1.0, 0.0, 100, 20, 1.5, 0, 0.0, 0, 20, 0.7, 80, 8.0, 0.01),

('lavasa', 'Lavasa (Kashmiri Bread)', 290.0, 7.5, 48.0, 7.5, 1.5, 1.0,
 70, 70,
 'indian_traditional', ARRAY['lavasa', 'lavas', 'kashmiri lavasa', 'thin kashmiri bread'],
 'indian', NULL, 1, 'Per 100g. ~203 cal per piece (~70g). Thin Kashmiri flatbread.', TRUE,
 320, 3, 2.0, 0.1, 90, 18, 1.5, 2, 0.0, 0, 18, 0.6, 70, 7.0, 0.01),

('tsochvor', 'Tsochvor (Kashmiri Roti)', 265.0, 7.0, 42.0, 8.0, 2.5, 1.0,
 75, 75,
 'indian_traditional', ARRAY['tsochvor', 'tsochwor', 'kashmiri roti', 'kashmir chapati', 'kashmiri tsot'],
 'indian', NULL, 1, 'Per 100g. ~199 cal per roti (~75g). Traditional Kashmiri whole wheat bread.', TRUE,
 280, 3, 2.5, 0.1, 110, 22, 1.8, 3, 0.0, 0, 25, 0.7, 85, 7.0, 0.01),

('kahwa', 'Kahwa (Kashmiri Green Tea)', 25.0, 0.5, 5.0, 0.5, 0.0, 3.5,
 150, NULL,
 'indian_traditional', ARRAY['kahwa', 'kahwah', 'kashmiri kahwa', 'kashmiri green tea', 'kehwa', 'kashmiri chai'],
 'indian', NULL, 1, 'Per 100g. ~38 cal per cup (150ml). Saffron-almond-cinnamon green tea.', TRUE,
 5, 0, 0.1, 0.0, 40, 8, 0.3, 2, 5.0, 0, 5, 0.1, 10, 0.5, 0.02),

('noon_chai', 'Noon Chai (Kashmiri Pink Tea)', 45.0, 2.0, 4.0, 2.0, 0.0, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['noon chai', 'namkeen chai', 'pink tea', 'kashmiri pink tea', 'sheer chai', 'gulabi chai'],
 'indian', NULL, 1, 'Per 100g. ~90 cal per cup (200ml). Pink salt tea with milk, baking soda, and pistachios.', TRUE,
 250, 8, 1.2, 0.0, 100, 60, 0.2, 10, 0.0, 5, 8, 0.3, 50, 1.0, 0.01),

-- =====================================================================
-- MP / CHHATTISGARH (~7 items)
-- =====================================================================

('bafauri', 'Bafauri', 160.0, 8.0, 18.0, 6.5, 3.0, 1.0,
 100, NULL,
 'indian_traditional', ARRAY['bafauri', 'bafori', 'steamed besan balls', 'besan ki bafauri', 'MP bafauri'],
 'indian', NULL, 1, 'Per 100g. ~160 cal per serving (100g). Steamed besan dumplings in curry, MP specialty.', TRUE,
 300, 0, 1.0, 0.0, 180, 25, 1.8, 5, 1.0, 0, 22, 0.7, 70, 3.0, 0.01),

('poha_dish', 'Poha (Cooked Dish)', 160.0, 3.5, 28.0, 4.0, 1.5, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['poha', 'pohe', 'chivda poha', 'kanda poha', 'indori poha', 'flattened rice dish', 'beaten rice'],
 'indian', NULL, 1, 'Per 100g. ~320 cal per serving (200g). Tempered flattened rice with peanuts and onion.', TRUE,
 280, 0, 0.5, 0.0, 120, 10, 3.0, 3, 2.0, 0, 12, 0.4, 40, 3.0, 0.01),

('jalebi_poha', 'Jalebi Poha (Combo)', 220.0, 3.0, 38.0, 6.5, 1.0, 15.0,
 200, NULL,
 'indian_traditional', ARRAY['jalebi poha', 'poha jalebi', 'indori jalebi poha', 'poha with jalebi'],
 'indian', NULL, 1, 'Per 100g. ~440 cal per plate (200g). Iconic Indore breakfast: poha with jalebi.', TRUE,
 250, 0, 1.5, 0.2, 100, 12, 2.0, 2, 1.5, 0, 10, 0.3, 35, 2.5, 0.01),

('sabudana_khichdi', 'Sabudana Khichdi', 180.0, 2.5, 30.0, 6.0, 1.0, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['sabudana khichdi', 'sabudana khichri', 'tapioca pearl khichdi', 'vrat ki khichdi', 'fasting khichdi'],
 'indian', NULL, 1, 'Per 100g. ~360 cal per serving (200g). Tapioca pearls with peanuts, popular fasting food.', TRUE,
 200, 0, 1.0, 0.0, 130, 10, 0.8, 2, 2.0, 0, 15, 0.5, 40, 2.0, 0.01),

('sabudana_vada', 'Sabudana Vada', 280.0, 4.0, 38.0, 12.0, 1.5, 1.0,
 120, 60,
 'indian_traditional', ARRAY['sabudana vada', 'sabu vada', 'tapioca fritters', 'fasting vada', 'sabudana tikki'],
 'indian', NULL, 1, 'Per 100g. ~168 cal per vada (~60g). Crispy tapioca-peanut fritters.', TRUE,
 250, 0, 2.0, 0.2, 150, 12, 1.0, 2, 1.5, 0, 18, 0.6, 45, 2.5, 0.01),

('bhutte_ka_kees', 'Bhutte Ka Kees', 150.0, 4.0, 22.0, 5.5, 2.0, 4.0,
 200, NULL,
 'indian_traditional', ARRAY['bhutte ka kees', 'corn kees', 'grated corn dish', 'indori bhutte ka kees', 'makai ka kees'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Grated corn cooked with milk and spices, Indore specialty.', TRUE,
 200, 5, 2.0, 0.0, 220, 30, 0.8, 15, 4.0, 3, 25, 0.5, 60, 2.0, 0.02),

('malpua', 'Malpua', 350.0, 4.5, 48.0, 15.0, 0.5, 28.0,
 60, 60,
 'indian_traditional', ARRAY['malpua', 'malpura', 'maalpua', 'indian sweet pancake', 'rabri malpua'],
 'indian', NULL, 1, 'Per 100g. ~210 cal per piece (~60g). Sweet fried pancake soaked in sugar syrup.', TRUE,
 30, 15, 5.0, 0.3, 100, 30, 1.2, 10, 0.0, 2, 12, 0.4, 55, 3.0, 0.01),

-- =====================================================================
-- GENERAL NORTH INDIAN BREAKFAST (~7 items)
-- =====================================================================

('besan_chilla', 'Besan Chilla', 195.0, 8.0, 22.0, 8.5, 3.0, 1.5,
 80, 80,
 'indian_traditional', ARRAY['besan chilla', 'besan cheela', 'gram flour pancake', 'besan ka chilla', 'chilla', 'besan pancake'],
 'indian', NULL, 1, 'Per 100g. ~156 cal per chilla (~80g). Savory gram flour crepe with onion and spices.', TRUE,
 320, 0, 1.5, 0.0, 220, 30, 2.0, 8, 3.0, 0, 28, 0.8, 90, 3.5, 0.01),

('moong_dal_chilla', 'Moong Dal Chilla', 150.0, 9.0, 18.0, 4.5, 2.5, 1.0,
 80, 80,
 'indian_traditional', ARRAY['moong dal chilla', 'moong dal cheela', 'moong dal crepe', 'moong chilla', 'green moong chilla'],
 'indian', NULL, 1, 'Per 100g. ~120 cal per chilla (~80g). Protein-rich ground moong dal crepe.', TRUE,
 280, 0, 0.8, 0.0, 250, 25, 1.8, 5, 2.0, 0, 30, 0.9, 100, 3.0, 0.01),

('aloo_puri', 'Aloo Puri', 230.0, 4.0, 30.0, 10.5, 2.0, 1.5,
 300, NULL,
 'indian_traditional', ARRAY['aloo puri', 'aloo poori', 'puri aloo', 'puri sabzi', 'aloo ki sabzi with puri'],
 'indian', NULL, 1, 'Per 100g. ~690 cal per plate (300g = 3 puri + aloo). Deep-fried bread with potato curry.', TRUE,
 350, 0, 2.0, 0.2, 200, 15, 1.2, 5, 5.0, 0, 18, 0.5, 50, 2.5, 0.01),

('halwa_puri', 'Halwa Puri (Combo)', 310.0, 5.0, 40.0, 15.0, 1.5, 15.0,
 300, NULL,
 'indian_traditional', ARRAY['halwa puri', 'halwa poori', 'sooji halwa puri', 'puri halwa chana', 'breakfast halwa puri'],
 'indian', NULL, 1, 'Per 100g. ~930 cal per plate (300g). Festive combo: puri + suji halwa + chana.', TRUE,
 300, 8, 5.0, 0.3, 130, 20, 1.5, 15, 1.0, 2, 15, 0.5, 50, 3.0, 0.02),

('chole_kulche', 'Chole Kulche', 200.0, 6.5, 28.0, 7.0, 3.0, 2.0,
 300, NULL,
 'indian_traditional', ARRAY['chole kulche', 'chole kulcha', 'chola kulcha', 'delhi chole kulche', 'kulcha chhole'],
 'indian', NULL, 1, 'Per 100g. ~600 cal per plate (300g = 2 kulche + chole). Popular Delhi street food combo.', TRUE,
 400, 3, 2.0, 0.1, 220, 35, 2.5, 5, 2.0, 0, 28, 1.0, 85, 4.0, 0.01),

('upma_north', 'Upma (North Indian Style)', 125.0, 3.5, 18.0, 4.5, 1.5, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['upma', 'uppma', 'suji upma', 'rava upma', 'semolina upma'],
 'indian', NULL, 1, 'Per 100g. ~250 cal per serving (200g). Tempered semolina porridge with vegetables.', TRUE,
 280, 0, 0.8, 0.0, 100, 15, 1.0, 5, 2.0, 0, 15, 0.5, 55, 5.0, 0.01),

('kadhai_chicken', 'Kadhai Chicken', 165.0, 16.0, 4.0, 9.5, 0.8, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['kadhai chicken', 'kadai chicken', 'karahi chicken', 'chicken kadhai', 'kadai murgh'],
 'indian', NULL, 1, 'Per 100g. ~330 cal per serving (200g). Chicken with bell peppers in thick spiced tomato gravy.', TRUE,
 420, 65, 3.5, 0.1, 280, 20, 1.5, 35, 15.0, 5, 25, 1.8, 170, 18.0, 0.04),

-- =====================================================================
-- GENERAL NORTH INDIAN CURRIES & SABZIS (~12 items)
-- =====================================================================

('aloo_matar', 'Aloo Matar', 100.0, 3.0, 14.0, 3.5, 2.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['aloo matar', 'aloo mutter', 'potato peas curry', 'matar aloo', 'alu matar'],
 'indian', NULL, 1, 'Per 100g. ~200 cal per serving (200g). Potato and green peas in light gravy.', TRUE,
 280, 0, 0.5, 0.0, 250, 18, 1.0, 20, 8.0, 0, 18, 0.4, 50, 1.5, 0.01),

('aloo_jeera', 'Aloo Jeera', 110.0, 2.0, 15.0, 5.0, 1.5, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['aloo jeera', 'jeera aloo', 'cumin potato', 'aloo ki sabzi', 'dry aloo jeera'],
 'indian', NULL, 1, 'Per 100g. ~220 cal per serving (200g). Cumin-tempered potato dry curry.', TRUE,
 250, 0, 0.8, 0.0, 300, 12, 0.8, 3, 10.0, 0, 20, 0.3, 45, 1.0, 0.01),

('lauki_ki_sabzi', 'Lauki Ki Sabzi (Bottle Gourd)', 50.0, 1.5, 6.0, 2.5, 1.5, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['lauki ki sabzi', 'ghia ki sabzi', 'bottle gourd curry', 'dudhi sabzi', 'lauki sabji', 'kaddu ki sabzi'],
 'indian', NULL, 1, 'Per 100g. ~100 cal per serving (200g). Light bottle gourd curry, easy to digest.', TRUE,
 200, 0, 0.4, 0.0, 180, 15, 0.5, 8, 6.0, 0, 12, 0.3, 20, 0.5, 0.01),

('tinda_masala', 'Tinda Masala', 65.0, 2.0, 7.5, 3.0, 2.0, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['tinda masala', 'tinda ki sabzi', 'apple gourd curry', 'tinda sabji', 'round gourd curry'],
 'indian', NULL, 1, 'Per 100g. ~130 cal per serving (200g). Apple gourd/round gourd in spiced gravy.', TRUE,
 220, 0, 0.5, 0.0, 160, 18, 0.6, 10, 8.0, 0, 14, 0.3, 25, 0.5, 0.01),

('arbi_fry', 'Arbi Fry (Colocasia)', 135.0, 2.5, 18.0, 6.0, 2.5, 1.0,
 150, NULL,
 'indian_traditional', ARRAY['arbi fry', 'arbi ki sabzi', 'colocasia fry', 'taro root fry', 'arvi fry', 'arbi masala'],
 'indian', NULL, 1, 'Per 100g. ~203 cal per serving (150g). Pan-fried spiced taro root.', TRUE,
 280, 0, 1.0, 0.1, 350, 30, 0.8, 3, 3.0, 0, 25, 0.3, 55, 1.0, 0.01),

('bhindi_masala', 'Bhindi Masala', 107.0, 2.5, 8.0, 7.0, 3.0, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['bhindi masala', 'bhindi ki sabzi', 'okra masala', 'lady finger curry', 'bhindi fry'],
 'indian', NULL, 1, 'Per 100g. ~214 cal per serving (200g). Spiced okra dry curry with onion-tomato.', TRUE,
 280, 0, 1.0, 0.0, 300, 80, 1.0, 35, 23.0, 0, 50, 0.5, 60, 0.5, 0.02),

('shimla_mirch_bharwa', 'Bharwa Shimla Mirch (Stuffed Capsicum)', 95.0, 3.0, 8.0, 6.0, 2.0, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['bharwa shimla mirch', 'stuffed capsicum', 'stuffed bell pepper', 'shimla mirch ki sabzi', 'bharwa mirch'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per serving (200g). Bell peppers stuffed with spiced potato or paneer.', TRUE,
 250, 0, 1.0, 0.0, 200, 12, 0.8, 30, 60.0, 0, 12, 0.3, 25, 0.5, 0.01),

('kadhai_paneer', 'Kadhai Paneer', 185.0, 9.0, 6.0, 14.0, 1.0, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['kadhai paneer', 'kadai paneer', 'karahi paneer', 'paneer kadhai', 'kadhai paneer gravy'],
 'indian', NULL, 1, 'Per 100g. ~370 cal per serving (200g). Paneer with bell peppers in spiced tomato gravy.', TRUE,
 380, 30, 7.5, 0.2, 180, 110, 1.2, 40, 20.0, 3, 22, 1.0, 130, 3.5, 0.02),

-- =====================================================================
-- GENERAL NORTH INDIAN RICE DISHES (~5 items)
-- =====================================================================

('jeera_rice', 'Jeera Rice', 145.0, 2.8, 26.0, 3.0, 0.5, 0.3,
 200, NULL,
 'indian_traditional', ARRAY['jeera rice', 'cumin rice', 'jeera chawal', 'zeera rice', 'jeera pulao'],
 'indian', NULL, 1, 'Per 100g. ~290 cal per serving (200g). Cumin-tempered basmati rice.', TRUE,
 150, 0, 1.0, 0.0, 60, 10, 0.5, 0, 0.0, 0, 12, 0.5, 40, 5.0, 0.01),

('peas_pulao', 'Peas Pulao', 150.0, 3.5, 25.0, 3.8, 1.5, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['peas pulao', 'matar pulao', 'green peas rice', 'matar chawal', 'pea pulav'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Basmati rice with green peas and whole spices.', TRUE,
 180, 0, 1.2, 0.0, 100, 12, 0.8, 10, 3.0, 0, 14, 0.5, 50, 5.0, 0.01),

('veg_pulao', 'Veg Pulao', 150.0, 3.0, 24.0, 4.5, 1.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['veg pulao', 'vegetable pulao', 'sabz pulao', 'mixed veg rice', 'vegetable pulav'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Mixed vegetable rice with whole spices.', TRUE,
 200, 0, 1.5, 0.0, 120, 15, 0.8, 15, 4.0, 0, 15, 0.5, 48, 4.0, 0.01),

('mushroom_pulao', 'Mushroom Pulao', 140.0, 3.5, 22.0, 4.0, 1.0, 0.8,
 200, NULL,
 'indian_traditional', ARRAY['mushroom pulao', 'mushroom rice', 'mushroom pulav', 'khumbi pulao', 'mushroom chawal'],
 'indian', NULL, 1, 'Per 100g. ~280 cal per serving (200g). Basmati rice with mushrooms and aromatics.', TRUE,
 180, 0, 1.2, 0.0, 160, 10, 0.8, 0, 1.5, 5, 14, 0.6, 55, 8.0, 0.01),

-- =====================================================================
-- ADDITIONAL NORTH INDIAN ITEMS (~50 more to reach ~150 total)
-- =====================================================================

-- More Punjabi items
('palak_paneer_home', 'Palak Paneer (Home Style)', 155.0, 8.0, 5.0, 12.0, 2.0, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['palak paneer home', 'palak paneer homemade', 'spinach paneer', 'spinach cottage cheese curry'],
 'indian', NULL, 1, 'Per 100g. ~310 cal per serving (200g). Pureed spinach with paneer cubes.', TRUE,
 350, 25, 6.5, 0.2, 350, 150, 3.0, 300, 15.0, 3, 50, 0.9, 120, 3.0, 0.05),

('paneer_tikka', 'Paneer Tikka', 220.0, 14.0, 5.0, 16.0, 0.5, 2.0,
 150, 30,
 'indian_traditional', ARRAY['paneer tikka', 'tandoori paneer tikka', 'grilled paneer', 'paneer tikka dry'],
 'indian', NULL, 1, 'Per 100g. ~66 cal per piece (~30g). Marinated and grilled paneer cubes.', TRUE,
 380, 30, 8.5, 0.2, 130, 200, 1.0, 35, 3.0, 3, 20, 1.2, 150, 4.0, 0.02),

('paneer_bhurji', 'Paneer Bhurji', 200.0, 12.0, 5.0, 15.0, 1.0, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['paneer bhurji', 'scrambled paneer', 'paneer ki bhurji', 'crumbled paneer'],
 'indian', NULL, 1, 'Per 100g. ~400 cal per serving (200g). Scrambled paneer with onion, tomato, spices.', TRUE,
 360, 28, 8.0, 0.2, 150, 180, 1.2, 30, 5.0, 3, 22, 1.0, 140, 3.5, 0.02),

('paneer_butter_masala', 'Paneer Butter Masala', 180.0, 7.5, 8.0, 13.5, 0.8, 3.5,
 200, NULL,
 'indian_traditional', ARRAY['paneer butter masala', 'paneer makhani', 'butter paneer', 'paneer lababdar'],
 'indian', NULL, 1, 'Per 100g. ~360 cal per serving (200g). Paneer in rich buttery tomato gravy.', TRUE,
 370, 25, 7.0, 0.2, 160, 100, 1.0, 45, 4.0, 3, 20, 0.8, 120, 3.0, 0.02),

('malai_kofta', 'Malai Kofta', 195.0, 6.0, 12.0, 14.0, 1.0, 4.0,
 200, NULL,
 'indian_traditional', ARRAY['malai kofta', 'paneer kofta', 'cream kofta curry', 'malai kofta gravy'],
 'indian', NULL, 1, 'Per 100g. ~390 cal per serving (200g). Paneer-potato balls in rich cream-cashew gravy.', TRUE,
 360, 20, 6.5, 0.2, 180, 70, 1.2, 30, 3.0, 3, 20, 0.7, 90, 3.0, 0.02),

('rajma_masala', 'Rajma Masala', 110.0, 6.0, 16.0, 2.5, 4.5, 2.0,
 250, NULL,
 'indian_traditional', ARRAY['rajma masala', 'rajma curry', 'kidney bean curry', 'rajma sabzi'],
 'indian', NULL, 1, 'Per 100g. ~275 cal per serving (250g). Kidney beans in thick onion-tomato gravy.', TRUE,
 320, 0, 0.4, 0.0, 350, 40, 2.5, 8, 2.0, 0, 35, 1.0, 100, 3.0, 0.01),

('dal_palak', 'Dal Palak', 85.0, 5.5, 10.0, 2.5, 3.5, 0.8,
 250, NULL,
 'indian_traditional', ARRAY['dal palak', 'palak dal', 'spinach lentils', 'dal saag', 'lentil spinach curry'],
 'indian', NULL, 1, 'Per 100g. ~213 cal per serving (250g). Lentils cooked with spinach, nutritious and light.', TRUE,
 200, 0, 0.5, 0.0, 380, 60, 3.5, 200, 12.0, 0, 45, 0.8, 100, 2.5, 0.03),

('chole_masala', 'Chole Masala (Home)', 120.0, 6.5, 18.0, 3.0, 5.0, 2.5,
 250, NULL,
 'indian_traditional', ARRAY['chole masala home', 'chole curry', 'chickpea curry home', 'punjabi chole home'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (250g). Home-style chickpea curry with tea-bag boiling method.', TRUE,
 380, 0, 0.5, 0.0, 280, 40, 2.8, 10, 2.0, 0, 35, 1.2, 95, 3.5, 0.01),

-- More UP/Lucknow items
('biryani_lucknowi', 'Lucknowi Biryani (Dum)', 190.0, 10.0, 24.0, 6.5, 1.0, 0.8,
 300, NULL,
 'indian_traditional', ARRAY['lucknowi biryani', 'awadhi biryani', 'dum biryani lucknow', 'pukki biryani'],
 'indian', NULL, 1, 'Per 100g. ~570 cal per serving (300g). Dum-cooked layered rice and meat, Awadhi style.', TRUE,
 400, 40, 2.5, 0.1, 200, 20, 1.5, 10, 1.0, 3, 20, 1.5, 120, 10.0, 0.04),

('mutton_korma', 'Mutton Korma', 170.0, 12.0, 5.0, 11.5, 0.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['mutton korma', 'gosht korma', 'lamb korma', 'korma gosht', 'mughlai korma'],
 'indian', NULL, 1, 'Per 100g. ~340 cal per serving (200g). Rich braised mutton in yogurt-cashew gravy.', TRUE,
 400, 65, 5.0, 0.2, 250, 35, 2.0, 15, 1.5, 3, 22, 3.5, 155, 10.0, 0.05),

('sheer_khurma', 'Sheer Khurma', 160.0, 4.0, 22.0, 6.5, 0.5, 15.0,
 150, NULL,
 'indian_traditional', ARRAY['sheer khurma', 'sheerkhurma', 'sevai kheer', 'eid dessert', 'vermicelli kheer'],
 'indian', NULL, 1, 'Per 100g. ~240 cal per serving (150g). Rich vermicelli-milk dessert with dates and nuts.', TRUE,
 40, 15, 3.5, 0.1, 150, 80, 0.5, 20, 0.5, 8, 15, 0.4, 70, 2.5, 0.02),

-- More Rajasthani items
('bajra_rotla', 'Bajra Rotla (Thick Millet Roti)', 190.0, 5.0, 32.0, 5.5, 4.0, 0.5,
 100, 100,
 'indian_traditional', ARRAY['bajra rotla', 'bajri rotla', 'thick millet bread', 'gujarati bajra rotla', 'rotlo'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per rotla (~100g). Thick pearl millet bread, Gujarat/Rajasthan staple.', TRUE,
 8, 0, 0.9, 0.0, 200, 25, 3.5, 3, 0.0, 0, 65, 1.8, 150, 4.5, 0.01),

('besan_gatte', 'Besan Gatte (Gram Flour Dumplings)', 250.0, 10.0, 22.0, 14.0, 3.0, 1.0,
 100, NULL,
 'indian_traditional', ARRAY['besan gatte', 'besan ke gatte', 'gram flour dumplings', 'gatte plain'],
 'indian', NULL, 1, 'Per 100g. ~250 cal per serving (100g). Steamed besan dumplings, used in gatte ki sabzi.', TRUE,
 350, 0, 2.5, 0.1, 200, 30, 2.0, 3, 0.5, 0, 28, 0.8, 80, 3.0, 0.01),

-- More Gujarati items
('dal_vada', 'Dal Vada', 270.0, 10.0, 25.0, 15.0, 4.0, 1.0,
 120, 40,
 'indian_traditional', ARRAY['dal vada', 'dal vade', 'lentil fritters', 'chana dal vada', 'masala vada'],
 'indian', NULL, 1, 'Per 100g. ~108 cal per vada (~40g). Deep-fried lentil fritters, crispy and protein-rich.', TRUE,
 300, 0, 2.5, 0.2, 250, 30, 2.5, 3, 1.0, 0, 30, 0.9, 90, 3.0, 0.01),

('sev_usal', 'Sev Usal', 150.0, 5.5, 18.0, 6.5, 3.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['sev usal', 'sev ussal', 'gujarati sev usal', 'misal pav gujarati', 'sprouted moth curry'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Spiced sprouted beans topped with sev.', TRUE,
 350, 0, 1.0, 0.0, 280, 25, 2.5, 8, 3.0, 0, 30, 0.8, 85, 3.0, 0.01),

('dhokla_rava', 'Rava Dhokla', 150.0, 4.0, 25.0, 4.0, 1.5, 3.0,
 100, NULL,
 'indian_traditional', ARRAY['rava dhokla', 'suji dhokla', 'semolina dhokla', 'white dhokla'],
 'indian', NULL, 1, 'Per 100g. ~150 cal per serving (100g). Steamed semolina cake, lighter variant of dhokla.', TRUE,
 320, 0, 0.5, 0.0, 120, 15, 0.8, 3, 0.5, 0, 15, 0.4, 50, 3.0, 0.01),

('lilva_kachori', 'Lilva Kachori', 300.0, 6.5, 32.0, 16.5, 3.0, 2.0,
 60, 60,
 'indian_traditional', ARRAY['lilva kachori', 'tuvar kachori', 'pigeon pea kachori', 'gujarati kachori'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per kachori (~60g). Pigeon pea filled deep-fried pastry.', TRUE,
 280, 0, 3.5, 0.2, 200, 20, 1.5, 5, 2.0, 0, 20, 0.6, 60, 2.5, 0.01),

-- More Kashmiri items
('dum_olav', 'Dum Olav (Kashmiri Potato)', 130.0, 3.0, 16.0, 6.5, 1.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['dum olav', 'kashmiri dum olav', 'kashmiri potato dish', 'dum oluv'],
 'indian', NULL, 1, 'Per 100g. ~260 cal per serving (200g). Whole potatoes in Kashmiri spice gravy.', TRUE,
 330, 0, 2.0, 0.1, 270, 20, 1.0, 25, 10.0, 0, 18, 0.4, 50, 1.5, 0.01),

('modur_pulao', 'Modur Pulao (Kashmiri Sweet Rice)', 185.0, 3.0, 32.0, 5.5, 0.5, 10.0,
 200, NULL,
 'indian_traditional', ARRAY['modur pulao', 'meetha pulao kashmiri', 'kashmiri sweet rice', 'modur chawal'],
 'indian', NULL, 1, 'Per 100g. ~370 cal per serving (200g). Sweet saffron rice with dry fruits, Kashmiri festive.', TRUE,
 80, 0, 2.5, 0.1, 100, 12, 0.6, 8, 0.5, 0, 12, 0.3, 40, 3.5, 0.03),

-- More General North Indian
('paneer_do_pyaza', 'Paneer Do Pyaza', 170.0, 8.0, 8.0, 12.5, 1.5, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['paneer do pyaza', 'do pyaza paneer', 'double onion paneer', 'paneer do piaza'],
 'indian', NULL, 1, 'Per 100g. ~340 cal per serving (200g). Paneer with double onion preparation.', TRUE,
 360, 22, 6.5, 0.2, 170, 100, 1.2, 25, 5.0, 3, 20, 0.9, 120, 3.0, 0.02),

('aloo_palak', 'Aloo Palak', 80.0, 3.0, 10.0, 3.0, 2.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['aloo palak', 'palak aloo', 'spinach potato curry', 'saag aloo', 'aloo saag'],
 'indian', NULL, 1, 'Per 100g. ~160 cal per serving (200g). Potato cooked in spinach puree.', TRUE,
 250, 0, 0.5, 0.0, 350, 55, 2.5, 180, 12.0, 0, 35, 0.5, 50, 1.5, 0.03),

('aloo_methi', 'Aloo Methi', 95.0, 2.5, 12.0, 4.5, 2.0, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['aloo methi', 'methi aloo', 'fenugreek potato', 'aloo methi ki sabzi'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per serving (200g). Potato with fenugreek leaves, mildly bitter and nutritious.', TRUE,
 240, 0, 0.7, 0.0, 290, 35, 2.0, 25, 5.0, 0, 22, 0.4, 45, 1.0, 0.01),

('mixed_veg_curry', 'Mixed Veg Curry', 75.0, 2.5, 8.0, 3.5, 2.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['mixed veg curry', 'mix veg', 'mix vegetable', 'sabzi mix', 'mixed sabzi'],
 'indian', NULL, 1, 'Per 100g. ~150 cal per serving (200g). Seasonal mixed vegetables in light gravy.', TRUE,
 280, 0, 0.5, 0.0, 250, 25, 1.0, 40, 10.0, 0, 20, 0.4, 40, 1.0, 0.01),

('gobhi_matar', 'Gobhi Matar', 75.0, 3.0, 8.5, 3.0, 2.5, 2.5,
 200, NULL,
 'indian_traditional', ARRAY['gobhi matar', 'gobi matar', 'cauliflower peas', 'phool gobi matar', 'gobhi mutter'],
 'indian', NULL, 1, 'Per 100g. ~150 cal per serving (200g). Cauliflower and green peas in light gravy.', TRUE,
 260, 0, 0.5, 0.0, 250, 22, 0.8, 15, 30.0, 0, 16, 0.4, 45, 1.0, 0.01),

('baingan_masala', 'Baingan Masala (Eggplant Curry)', 90.0, 2.0, 8.5, 5.5, 3.0, 3.5,
 200, NULL,
 'indian_traditional', ARRAY['baingan masala', 'baingan ki sabzi', 'eggplant curry', 'brinjal masala', 'baigan masala'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per serving (200g). Spiced eggplant curry in onion-tomato gravy.', TRUE,
 240, 0, 0.8, 0.0, 220, 14, 0.7, 10, 4.0, 0, 14, 0.3, 30, 0.5, 0.01),

('chana_masala_dry', 'Chana Masala (Dry)', 145.0, 7.0, 20.0, 4.0, 5.5, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['chana masala dry', 'dry chana', 'sukha chana', 'dry chickpea masala'],
 'indian', NULL, 1, 'Per 100g. ~290 cal per serving (200g). Dry spiced chickpea preparation, street food style.', TRUE,
 350, 0, 0.6, 0.0, 300, 35, 2.5, 5, 2.0, 0, 32, 1.0, 90, 3.5, 0.01),

('suji_halwa', 'Suji Halwa (Sooji Ka Halwa)', 280.0, 3.5, 38.0, 13.0, 0.5, 22.0,
 100, NULL,
 'indian_traditional', ARRAY['suji halwa', 'sooji halwa', 'semolina halwa', 'rava sheera', 'sooji ka halwa'],
 'indian', NULL, 1, 'Per 100g. ~280 cal per serving (100g). Semolina cooked in ghee with sugar and dry fruits.', TRUE,
 15, 18, 7.5, 0.2, 50, 15, 0.8, 30, 0.0, 5, 10, 0.3, 35, 4.0, 0.02),

('gajar_halwa', 'Gajar Ka Halwa', 175.0, 3.5, 25.0, 7.5, 1.5, 18.0,
 120, NULL,
 'indian_traditional', ARRAY['gajar halwa', 'gajar ka halwa', 'carrot halwa', 'gajrela', 'carrot pudding'],
 'indian', NULL, 1, 'Per 100g. ~210 cal per serving (120g). Grated carrot slow-cooked with milk, ghee, and sugar.', TRUE,
 30, 12, 4.0, 0.1, 200, 60, 0.5, 350, 3.0, 5, 12, 0.3, 40, 1.5, 0.02),

('rabri', 'Rabri (Thickened Milk Dessert)', 200.0, 5.0, 25.0, 9.0, 0.0, 22.0,
 100, NULL,
 'indian_traditional', ARRAY['rabri', 'rabdi', 'lachhedar rabri', 'malai rabri', 'thickened milk sweet'],
 'indian', NULL, 1, 'Per 100g. ~200 cal per serving (100g). Sweetened slow-reduced milk with cardamom layers.', TRUE,
 45, 30, 5.5, 0.1, 160, 120, 0.3, 35, 0.5, 10, 12, 0.4, 90, 3.0, 0.02),

('jalebi', 'Jalebi', 380.0, 2.5, 65.0, 13.0, 0.0, 50.0,
 50, NULL,
 'indian_traditional', ARRAY['jalebi', 'imarti', 'jilebi', 'crispy jalebi', 'desi ghee jalebi'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per serving (50g). Spiral deep-fried batter soaked in sugar syrup.', TRUE,
 10, 5, 3.0, 0.3, 30, 10, 0.8, 5, 0.0, 0, 5, 0.2, 20, 2.0, 0.01),

('kheer_rice', 'Kheer (Rice Pudding)', 130.0, 3.5, 20.0, 4.0, 0.0, 15.0,
 150, NULL,
 'indian_traditional', ARRAY['kheer', 'rice kheer', 'chawal ki kheer', 'payasam north indian', 'doodh chawal'],
 'indian', NULL, 1, 'Per 100g. ~195 cal per serving (150g). Slow-cooked rice in sweetened milk with cardamom.', TRUE,
 35, 15, 2.5, 0.1, 130, 80, 0.3, 25, 0.5, 8, 12, 0.3, 65, 2.5, 0.01),

('phirni', 'Phirni', 120.0, 3.0, 18.0, 4.0, 0.0, 14.0,
 100, NULL,
 'indian_traditional', ARRAY['phirni', 'firni', 'ground rice pudding', 'phirni mughlai'],
 'indian', NULL, 1, 'Per 100g. ~120 cal per serving (100g). Ground rice pudding set in clay pots with saffron.', TRUE,
 30, 12, 2.5, 0.1, 120, 70, 0.2, 18, 0.5, 6, 10, 0.3, 55, 2.0, 0.01),

('kulfi', 'Kulfi', 200.0, 5.0, 22.0, 10.5, 0.0, 18.0,
 80, NULL,
 'indian_traditional', ARRAY['kulfi', 'matka kulfi', 'malai kulfi', 'pista kulfi', 'indian ice cream'],
 'indian', NULL, 1, 'Per 100g. ~160 cal per kulfi stick (~80g). Dense Indian ice cream with milk solids.', TRUE,
 50, 35, 6.5, 0.1, 170, 130, 0.3, 40, 0.5, 12, 15, 0.5, 100, 3.0, 0.02),

-- More common North Indian items
('dal_matar', 'Dal Matar', 90.0, 5.0, 13.0, 2.0, 3.5, 1.5,
 250, NULL,
 'indian_traditional', ARRAY['dal matar', 'matar dal', 'peas dal', 'dal with green peas'],
 'indian', NULL, 1, 'Per 100g. ~225 cal per serving (250g). Lentils cooked with green peas.', TRUE,
 180, 0, 0.3, 0.0, 260, 22, 1.8, 15, 5.0, 0, 30, 0.7, 90, 2.5, 0.01),

('toor_dal', 'Toor Dal (Arhar Dal)', 100.0, 6.5, 14.0, 1.8, 3.0, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['toor dal', 'arhar dal', 'pigeon pea dal', 'toor daal', 'tur dal'],
 'indian', NULL, 1, 'Per 100g. ~250 cal per serving (250g). Pigeon pea lentils, everyday Indian dal.', TRUE,
 8, 0, 0.3, 0.0, 280, 20, 1.5, 3, 0.5, 0, 30, 0.8, 100, 3.0, 0.01),

('egg_curry_north', 'Egg Curry (North Indian)', 135.0, 9.0, 5.0, 9.0, 0.8, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['egg curry north', 'anda curry', 'egg masala north', 'ande ki sabzi'],
 'indian', NULL, 1, 'Per 100g. ~270 cal per serving (200g). Boiled eggs in spiced onion-tomato gravy.', TRUE,
 380, 180, 2.5, 0.1, 180, 45, 1.8, 60, 3.0, 20, 15, 1.0, 130, 15.0, 0.03),

('chicken_curry_north', 'Chicken Curry (North Indian)', 150.0, 14.0, 4.5, 8.5, 0.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['chicken curry north', 'murgh curry', 'north indian chicken curry', 'desi chicken curry'],
 'indian', NULL, 1, 'Per 100g. ~300 cal per serving (200g). Home-style onion-tomato chicken curry.', TRUE,
 400, 60, 2.5, 0.1, 260, 18, 1.5, 15, 3.0, 5, 22, 1.8, 160, 18.0, 0.04),

('mutton_curry_north', 'Mutton Curry (North Indian)', 165.0, 14.0, 4.0, 10.5, 0.5, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['mutton curry north', 'gosht curry', 'north indian mutton', 'desi mutton curry', 'meat curry'],
 'indian', NULL, 1, 'Per 100g. ~330 cal per serving (200g). Traditional slow-cooked goat meat curry.', TRUE,
 420, 70, 4.5, 0.2, 280, 20, 2.5, 8, 1.5, 3, 22, 4.0, 170, 12.0, 0.06),

('keema_matar', 'Keema Matar', 160.0, 14.0, 6.0, 9.0, 2.0, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['keema matar', 'keema mutter', 'minced meat peas', 'mutton keema matar', 'kheema matar'],
 'indian', NULL, 1, 'Per 100g. ~320 cal per serving (200g). Spiced minced meat with green peas.', TRUE,
 400, 55, 3.8, 0.2, 280, 20, 2.5, 15, 5.0, 3, 22, 3.0, 150, 10.0, 0.04),

('chapli_kebab', 'Chapli Kebab', 260.0, 15.0, 8.0, 19.0, 1.0, 1.5,
 120, 120,
 'indian_traditional', ARRAY['chapli kebab', 'chapli kabab', 'peshawari kebab', 'flat round kebab'],
 'indian', NULL, 1, 'Per 100g. ~312 cal per kebab (~120g). Flat round spiced meat patty with tomatoes.', TRUE,
 460, 65, 8.5, 0.3, 230, 20, 2.5, 10, 5.0, 3, 20, 3.0, 145, 10.0, 0.05),

('fish_tikka', 'Fish Tikka', 140.0, 20.0, 3.0, 5.5, 0.3, 0.5,
 150, NULL,
 'indian_traditional', ARRAY['fish tikka', 'machhi tikka', 'grilled fish tikka', 'tandoori fish'],
 'indian', NULL, 1, 'Per 100g. ~210 cal per serving (150g). Yogurt-marinated grilled fish pieces.', TRUE,
 380, 50, 1.5, 0.0, 300, 25, 1.2, 8, 1.0, 15, 30, 0.6, 200, 25.0, 0.20),

('aloo_tikki', 'Aloo Tikki', 200.0, 4.0, 25.0, 9.5, 2.0, 1.5,
 80, 80,
 'indian_traditional', ARRAY['aloo tikki', 'potato patty', 'tikki chaat', 'aloo ki tikki', 'crispy potato cutlet'],
 'indian', NULL, 1, 'Per 100g. ~160 cal per tikki (~80g). Crispy spiced potato patty, popular chaat base.', TRUE,
 350, 0, 1.5, 0.2, 280, 15, 1.0, 3, 8.0, 0, 18, 0.4, 45, 1.0, 0.01),

('papdi_chaat', 'Papdi Chaat', 180.0, 4.0, 22.0, 8.5, 2.0, 5.0,
 150, NULL,
 'indian_traditional', ARRAY['papdi chaat', 'papri chaat', 'dahi papdi chaat', 'chaat papdi'],
 'indian', NULL, 1, 'Per 100g. ~270 cal per plate (150g). Crispy wafers with yogurt, chutney, and spices.', TRUE,
 400, 5, 2.0, 0.1, 180, 40, 1.0, 8, 3.0, 0, 15, 0.5, 50, 2.0, 0.01),

('dahi_bhalla', 'Dahi Bhalla (Dahi Vada)', 130.0, 5.5, 16.0, 5.0, 1.5, 5.0,
 150, NULL,
 'indian_traditional', ARRAY['dahi bhalla', 'dahi vada', 'dahi bhalle', 'dahi bade', 'curd vada'],
 'indian', NULL, 1, 'Per 100g. ~195 cal per serving (150g). Lentil dumplings in sweetened yogurt with chutneys.', TRUE,
 320, 8, 1.5, 0.1, 200, 50, 1.5, 5, 2.0, 0, 18, 0.6, 65, 2.0, 0.01),

('pani_puri', 'Pani Puri (Gol Gappa)', 150.0, 3.0, 22.0, 5.5, 1.5, 3.0,
 120, NULL,
 'indian_traditional', ARRAY['pani puri', 'gol gappa', 'gol gappe', 'puchka', 'pani poori', 'phuchka'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per 6 puri plate (120g). Hollow crispy puri filled with spiced water.', TRUE,
 500, 0, 1.0, 0.1, 150, 15, 1.0, 5, 3.0, 0, 12, 0.4, 40, 2.0, 0.01),

('bhel_puri', 'Bhel Puri', 220.0, 5.0, 32.0, 8.0, 3.0, 4.0,
 100, NULL,
 'indian_traditional', ARRAY['bhel puri', 'bhelpuri', 'chaat bhel', 'mumbai bhel puri'],
 'indian', NULL, 1, 'Per 100g. ~220 cal per serving (100g). Puffed rice mixed with sev, chutney, and vegetables.', TRUE,
 400, 0, 1.5, 0.1, 180, 15, 1.5, 5, 5.0, 0, 18, 0.5, 55, 2.5, 0.01),

('sev_puri', 'Sev Puri', 240.0, 4.0, 28.0, 12.0, 2.0, 4.0,
 80, NULL,
 'indian_traditional', ARRAY['sev puri', 'sev poori', 'sev puri chaat', 'flat puri chaat'],
 'indian', NULL, 1, 'Per 100g. ~192 cal per serving (80g). Flat crispy puri topped with potato, chutney, sev.', TRUE,
 420, 0, 2.5, 0.1, 150, 12, 1.0, 5, 3.0, 0, 15, 0.4, 40, 2.0, 0.01),

('lassi_sweet', 'Sweet Lassi', 70.0, 2.5, 12.0, 1.5, 0.0, 10.0,
 300, NULL,
 'indian_traditional', ARRAY['sweet lassi', 'meethi lassi', 'lassi', 'punjabi lassi', 'yogurt drink sweet'],
 'indian', NULL, 1, 'Per 100g. ~210 cal per glass (300ml). Sweetened yogurt drink, Punjabi classic.', TRUE,
 35, 8, 1.0, 0.0, 140, 80, 0.1, 10, 0.5, 3, 10, 0.3, 70, 2.0, 0.01),

('lassi_salted', 'Salted Lassi (Chaas)', 30.0, 1.5, 3.0, 1.0, 0.0, 2.0,
 300, NULL,
 'indian_traditional', ARRAY['salted lassi', 'namkeen lassi', 'chaas', 'mattha', 'buttermilk indian'],
 'indian', NULL, 1, 'Per 100g. ~90 cal per glass (300ml). Salted spiced buttermilk, digestive drink.', TRUE,
 250, 5, 0.6, 0.0, 120, 60, 0.1, 5, 0.5, 2, 8, 0.3, 55, 1.5, 0.01)

ON CONFLICT (food_name_normalized) DO NOTHING;
