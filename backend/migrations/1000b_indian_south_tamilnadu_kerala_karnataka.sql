-- 1000b_indian_south_tamilnadu_kerala_karnataka.sql
-- Traditional Tamil Nadu, Kerala, and Karnataka foods
-- All values per 100g. Sources: IFCT 2017, USDA, nutritionix, tarladalal, snapcalorie

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
-- TAMIL NADU - BREAKFAST (~6 items)
-- =====================================================================

('ven_pongal', 'Ven Pongal', 154.0, 3.5, 26.0, 3.9, 0.8, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['ven pongal', 'khara pongal', 'ghee pongal', 'kara pongal', 'huggi', 'வெண் பொங்கல்'],
 'indian', NULL, 1, 'Per 100g. ~308 cal per serving (200g). Rice-moong dal porridge tempered with ghee, pepper, cumin, and cashews.', TRUE,
 180, 8, 1.8, 0.0, 110, 18, 0.8, 5, 0.5, 0, 20, 0.6, 65, 4.0, 0.01),

('adai_dosa', 'Adai Dosa', 195.0, 7.0, 28.0, 6.5, 3.0, 1.0,
 150, 100,
 'indian_traditional', ARRAY['adai dosa', 'adai', 'protein dosa', 'mixed dal dosa', 'paruppu adai', 'அடை தோசை'],
 'indian', NULL, 1, 'Per 100g. ~195 cal per dosa (~100g). Multi-lentil and rice crepe, higher protein than regular dosa.', TRUE,
 150, 0, 0.8, 0.0, 220, 25, 2.0, 4, 1.0, 0, 35, 1.0, 100, 3.0, 0.02),

('appam', 'Appam', 148.0, 2.5, 27.0, 3.2, 0.6, 2.0,
 100, 50,
 'indian_traditional', ARRAY['appam', 'palappam', 'hoppers', 'appam Kerala', 'அப்பம்', 'ആപ്പം'],
 'indian', NULL, 2, 'Per 100g. ~74 cal per appam (~50g). Fermented rice batter pancake with lacey edges and soft center, uses coconut milk.', TRUE,
 15, 0, 2.2, 0.0, 80, 10, 0.5, 0, 0.2, 0, 12, 0.3, 40, 2.0, 0.01),

('idiyappam', 'Idiyappam (String Hoppers)', 133.0, 3.3, 26.7, 1.3, 1.3, 0.3,
 120, 30,
 'indian_traditional', ARRAY['idiyappam', 'string hoppers', 'nool puttu', 'nool appam', 'இடியாப்பம்', 'ഇടിയപ്പം'],
 'indian', NULL, 4, 'Per 100g. ~40 cal per piece (~30g). Steamed rice flour noodles pressed into nests, served with curry or coconut milk.', TRUE,
 8, 0, 0.2, 0.0, 35, 8, 0.6, 0, 0.0, 0, 10, 0.4, 35, 3.0, 0.0),

('puttu', 'Puttu', 203.0, 3.4, 33.0, 6.3, 1.8, 1.5,
 200, 150,
 'indian_traditional', ARRAY['puttu', 'rice puttu', 'puttu Kerala', 'arisi puttu', 'புட்டு', 'പുട്ട്'],
 'indian', NULL, 1, 'Per 100g. ~305 cal per cylinder (~150g). Steamed cylinders of rice flour layered with grated coconut.', TRUE,
 10, 0, 4.5, 0.0, 120, 15, 0.8, 0, 0.5, 0, 18, 0.5, 55, 3.0, 0.02),

('kozhukattai', 'Kozhukattai (Steamed Rice Dumpling)', 216.0, 3.0, 34.0, 7.0, 1.5, 5.0,
 100, 30,
 'indian_traditional', ARRAY['kozhukattai', 'kozhukkattai', 'modak', 'kolukattai', 'pidi kozhukattai', 'கொழுக்கட்டை', 'കൊഴുക്കട്ട'],
 'indian', NULL, 3, 'Per 100g. ~65 cal per piece (~30g). Steamed rice flour dumplings with sweet coconut-jaggery or savory filling.', TRUE,
 20, 0, 5.0, 0.0, 85, 12, 0.7, 2, 0.3, 0, 15, 0.4, 45, 2.0, 0.01),

-- =====================================================================
-- TAMIL NADU - RICE DISHES & CURRIES (~5 items)
-- =====================================================================

('sambar_rice', 'Sambar Rice', 118.0, 4.0, 19.0, 2.5, 2.0, 1.0,
 300, NULL,
 'indian_traditional', ARRAY['sambar rice', 'sambar sadam', 'sambar sadham', 'sambhar rice', 'சாம்பார் சாதம்'],
 'indian', NULL, 1, 'Per 100g. ~354 cal per plate (300g). Cooked rice mixed with lentil-vegetable sambar, a Tamil Nadu staple.', TRUE,
 280, 0, 0.4, 0.0, 200, 25, 1.5, 15, 3.0, 0, 28, 0.7, 80, 2.5, 0.01),

('rasam_rice', 'Rasam Rice', 95.0, 2.0, 18.0, 1.2, 0.5, 0.5,
 300, NULL,
 'indian_traditional', ARRAY['rasam rice', 'rasam sadam', 'rasam sadham', 'chaaru annam', 'ரசம் சாதம்'],
 'indian', NULL, 1, 'Per 100g. ~285 cal per plate (300g). Hot rice mixed with tangy pepper-tamarind rasam, digestive comfort food.', TRUE,
 220, 0, 0.2, 0.0, 150, 12, 0.6, 10, 5.0, 0, 12, 0.3, 40, 2.0, 0.01),

('lemon_rice', 'Lemon Rice (Elumichai Sadham)', 175.0, 2.6, 27.0, 6.4, 0.8, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['lemon rice', 'elumichai sadham', 'nimmakaya pulihora', 'chitranna', 'எலுமிச்சை சாதம்'],
 'indian', NULL, 1, 'Per 100g. ~350 cal per plate (200g). Tangy rice tempered with mustard, turmeric, peanuts, and lemon juice.', TRUE,
 250, 0, 0.8, 0.0, 120, 14, 0.8, 3, 4.0, 0, 16, 0.5, 55, 3.0, 0.02),

('kothamalli_rice', 'Kothamalli Rice (Coriander Rice)', 155.0, 3.0, 25.0, 4.5, 1.2, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['kothamalli rice', 'coriander rice', 'cilantro rice', 'kothamalli sadam', 'கொத்தமல்லி சாதம்'],
 'indian', NULL, 1, 'Per 100g. ~310 cal per plate (200g). Fragrant rice flavored with fresh coriander leaves and light tempering.', TRUE,
 180, 0, 0.6, 0.0, 130, 15, 0.7, 40, 5.0, 0, 14, 0.5, 50, 2.5, 0.01),

('paruppu_usili', 'Paruppu Usili', 187.0, 9.0, 25.0, 6.0, 4.0, 1.5,
 100, NULL,
 'indian_traditional', ARRAY['paruppu usili', 'paruppu usili beans', 'lentil crumble stir fry', 'usili', 'பருப்பு உசிலி'],
 'indian', NULL, 1, 'Per 100g. ~187 cal per serving (100g). Steamed lentil crumbles stir-fried with beans or greens, high protein side.', TRUE,
 150, 0, 0.8, 0.0, 280, 45, 2.5, 30, 3.0, 0, 40, 1.2, 110, 3.0, 0.02),

-- =====================================================================
-- TAMIL NADU - KUZHAMBU (Curries) (~5 items)
-- =====================================================================

('kara_kuzhambu', 'Kara Kuzhambu', 85.0, 2.5, 8.0, 5.0, 1.5, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['kara kuzhambu', 'kara kulambu', 'spicy tamarind curry', 'காரக் குழம்பு'],
 'indian', NULL, 1, 'Per 100g. ~170 cal per serving (200g). Spicy tamarind-based curry with shallots and drumstick/brinjal.', TRUE,
 350, 0, 1.0, 0.0, 180, 20, 1.2, 15, 4.0, 0, 22, 0.5, 50, 1.5, 0.01),

('vatha_kuzhambu', 'Vatha Kuzhambu', 78.0, 1.5, 7.0, 5.0, 1.2, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['vatha kuzhambu', 'vathal kulambu', 'vathal kuzhambu', 'sun-dried vegetable curry', 'வத்தக் குழம்பு'],
 'indian', NULL, 1, 'Per 100g. ~156 cal per serving (200g). Tangy tamarind curry with sun-dried vegetables (vathal), sesame-based.', TRUE,
 380, 0, 0.8, 0.0, 150, 25, 1.0, 10, 2.0, 0, 20, 0.4, 45, 1.5, 0.01),

('milagu_kuzhambu', 'Milagu Kuzhambu (Pepper Curry)', 75.0, 1.5, 5.0, 6.0, 2.0, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['milagu kuzhambu', 'milagu kulambu', 'pepper kuzhambu', 'molagu kuzhambu', 'மிளகு குழம்பு'],
 'indian', NULL, 1, 'Per 100g. ~150 cal per serving (200g). Pepper-garlic tamarind curry, traditionally served postpartum for healing.', TRUE,
 300, 0, 1.2, 0.0, 170, 30, 1.5, 12, 6.0, 0, 18, 0.6, 40, 1.0, 0.01),

('mor_kuzhambu', 'Mor Kuzhambu (Buttermilk Curry)', 65.0, 2.2, 5.0, 4.2, 0.8, 1.5,
 250, NULL,
 'indian_traditional', ARRAY['mor kuzhambu', 'mor kulambu', 'buttermilk curry', 'curd curry', 'majjige huli', 'மோர் குழம்பு'],
 'indian', NULL, 1, 'Per 100g. ~163 cal per serving (250g). Cooling yogurt-based curry with coconut and okra or ash gourd.', TRUE,
 200, 5, 2.5, 0.0, 140, 55, 0.5, 8, 1.5, 0, 14, 0.3, 50, 1.5, 0.01),

('puli_kuzhambu', 'Puli Kuzhambu (Tamarind Curry)', 90.0, 2.0, 10.0, 4.8, 1.8, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['puli kuzhambu', 'puli kulambu', 'tamarind curry', 'pulikuzhambu', 'புளிக் குழம்பு'],
 'indian', NULL, 1, 'Per 100g. ~180 cal per serving (200g). Tangy tamarind curry with brinjal or drumstick, temple-style comfort food.', TRUE,
 360, 0, 0.8, 0.0, 200, 22, 1.5, 18, 5.0, 0, 25, 0.5, 55, 2.0, 0.02),

-- =====================================================================
-- TAMIL NADU - PORIYAL & SIDES (~4 items)
-- =====================================================================

('vazhakkai_poriyal', 'Vazhakkai Poriyal (Raw Banana Stir-Fry)', 110.0, 1.5, 18.0, 4.0, 2.5, 3.0,
 100, NULL,
 'indian_traditional', ARRAY['vazhakkai poriyal', 'raw banana fry', 'plantain poriyal', 'vazhakkai varuval', 'வாழைக்காய் பொரியல்'],
 'indian', NULL, 1, 'Per 100g. ~110 cal per serving (100g). Diced raw banana sauteed with mustard, curry leaves, and grated coconut.', TRUE,
 12, 0, 2.8, 0.0, 350, 10, 0.8, 20, 8.0, 0, 30, 0.3, 28, 1.0, 0.01),

('beans_poriyal', 'Beans Poriyal (Green Beans Stir-Fry)', 95.0, 2.8, 10.0, 4.5, 3.0, 1.5,
 100, NULL,
 'indian_traditional', ARRAY['beans poriyal', 'green beans stir fry', 'beans varuval', 'French beans poriyal', 'பீன்ஸ் பொரியல்'],
 'indian', NULL, 1, 'Per 100g. ~95 cal per serving (100g). French beans with coconut, mustard seeds, and curry leaves.', TRUE,
 10, 0, 2.8, 0.0, 220, 40, 1.2, 35, 10.0, 0, 22, 0.4, 38, 1.0, 0.01),

('murungakkai_sambar', 'Murungakkai Sambar (Drumstick Sambar)', 86.0, 4.3, 12.0, 2.7, 4.0, 1.2,
 250, NULL,
 'indian_traditional', ARRAY['murungakkai sambar', 'drumstick sambar', 'murungaikkai sambar', 'முருங்கக்காய் சாம்பார்'],
 'indian', NULL, 1, 'Per 100g. ~215 cal per serving (250g). Toor dal sambar with drumstick pods, rich in iron and vitamins.', TRUE,
 350, 0, 0.4, 0.0, 250, 30, 2.0, 20, 8.0, 0, 32, 0.8, 90, 2.5, 0.01),

('keerai_kootu', 'Keerai Kootu (Greens with Lentil)', 75.0, 4.0, 8.0, 3.0, 2.5, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['keerai kootu', 'spinach kootu', 'greens kootu', 'keerai masiyal', 'கீரை கூட்டு'],
 'indian', NULL, 1, 'Per 100g. ~150 cal per serving (200g). Spinach or amaranth cooked with lentils and ground coconut.', TRUE,
 180, 0, 1.5, 0.0, 350, 90, 3.0, 280, 15.0, 0, 40, 0.8, 65, 2.0, 0.02),

-- =====================================================================
-- TAMIL NADU - SNACKS (~6 items)
-- =====================================================================

('murukku', 'Murukku', 464.0, 11.0, 50.0, 25.0, 2.5, 1.0,
 30, 15,
 'indian_traditional', ARRAY['murukku', 'chakli', 'chakali', 'rice murukku', 'முறுக்கு', 'ചക്ക'],
 'indian', NULL, 2, 'Per 100g. ~70 cal per piece (~15g). Crispy spiral deep-fried snack from rice and urad dal flour.', TRUE,
 550, 0, 3.5, 0.0, 130, 15, 1.5, 0, 0.0, 0, 20, 0.8, 80, 5.0, 0.02),

('thenkuzhal', 'Thenkuzhal Murukku', 519.0, 8.0, 55.0, 25.0, 2.0, 1.0,
 30, 10,
 'indian_traditional', ARRAY['thenkuzhal', 'thenkuzhal murukku', 'kai murukku', 'தேன்குழல்'],
 'indian', NULL, 3, 'Per 100g. ~52 cal per piece (~10g). Finger-shaped deep-fried murukku, crunchier and more compact variety.', TRUE,
 520, 0, 3.5, 0.0, 120, 12, 1.2, 0, 0.0, 0, 18, 0.7, 75, 4.5, 0.02),

('ribbon_pakoda', 'Ribbon Pakoda', 519.0, 12.0, 52.0, 28.0, 3.0, 1.0,
 30, NULL,
 'indian_traditional', ARRAY['ribbon pakoda', 'ola pakoda', 'ribbon murukku', 'ரிப்பன் பக்கோடா'],
 'indian', NULL, 1, 'Per 100g. ~156 cal per handful (30g). Thin ribbon-shaped deep-fried gram flour snack.', TRUE,
 580, 0, 4.0, 0.0, 150, 20, 2.0, 2, 0.5, 0, 25, 1.0, 90, 5.0, 0.02),

('sundal', 'Sundal (Chickpea Snack)', 150.0, 7.5, 20.0, 5.0, 5.5, 2.0,
 150, NULL,
 'indian_traditional', ARRAY['sundal', 'chana sundal', 'chickpea sundal', 'kondakadalai sundal', 'beach sundal', 'சுண்டல்'],
 'indian', NULL, 1, 'Per 100g. ~225 cal per serving (150g). Boiled chickpeas tempered with mustard, curry leaves, and grated coconut. Temple and beach snack.', TRUE,
 200, 0, 0.5, 0.0, 290, 45, 2.5, 5, 2.0, 0, 35, 1.5, 120, 3.0, 0.03),

('mixture_south_indian', 'South Indian Mixture', 534.0, 15.0, 45.0, 33.0, 4.0, 2.0,
 30, NULL,
 'indian_traditional', ARRAY['south indian mixture', 'madras mixture', 'hot mixture', 'Chennai mixture', 'தென்னிந்திய மிக்ஸ்சர்'],
 'indian', NULL, 1, 'Per 100g. ~160 cal per handful (30g). Crunchy mix of sev, boondi, peanuts, curry leaves, and fried lentils.', TRUE,
 675, 0, 5.0, 0.2, 180, 30, 2.0, 3, 0.5, 0, 35, 1.5, 100, 5.0, 0.03),

('banana_chips_nendran', 'Banana Chips (Nendran)', 519.0, 2.0, 58.0, 31.0, 4.0, 5.0,
 30, NULL,
 'indian_traditional', ARRAY['banana chips', 'nendran chips', 'Kerala banana chips', 'ethakka chips', 'vazhaikai chips', 'வாழைக்காய் சிப்ஸ்', 'കായ ചിപ്സ്'],
 'indian', NULL, 1, 'Per 100g. ~156 cal per handful (30g). Thin-sliced nendran banana deep-fried in coconut oil, Kerala specialty.', TRUE,
 180, 0, 22.0, 0.0, 536, 8, 0.8, 10, 4.0, 0, 30, 0.3, 22, 1.5, 0.01),

-- =====================================================================
-- KERALA - MAIN DISHES (~16 items)
-- =====================================================================

('appam_with_stew', 'Appam with Vegetable Stew (Combo)', 112.0, 2.8, 16.0, 4.0, 1.2, 1.5,
 300, NULL,
 'indian_traditional', ARRAY['appam with stew', 'appam stew', 'appam vegetable stew', 'ആപ്പവും സ്റ്റ്യൂവും'],
 'indian', NULL, 1, 'Per 100g combined. ~336 cal per plate (300g = 2 appam + stew). Fermented rice hoppers with creamy coconut veg stew.', TRUE,
 280, 0, 2.5, 0.0, 180, 18, 0.8, 25, 4.0, 0, 16, 0.4, 50, 2.0, 0.02),

('kerala_chicken_stew', 'Kerala Chicken Stew', 114.0, 10.0, 5.5, 6.0, 1.0, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['kerala chicken stew', 'chicken ishtu', 'chicken stew Kerala', 'kozhi stew', 'കോഴി സ്റ്റ്യൂ'],
 'indian', NULL, 1, 'Per 100g. ~285 cal per serving (250g). Mildly spiced chicken in coconut milk with potatoes and whole spices.', TRUE,
 320, 40, 3.5, 0.0, 220, 15, 0.8, 12, 3.0, 0, 20, 1.0, 95, 8.0, 0.02),

('puttu_kadala_curry', 'Puttu with Kadala Curry (Combo)', 180.0, 5.5, 28.0, 5.8, 3.0, 1.5,
 300, NULL,
 'indian_traditional', ARRAY['puttu kadala curry', 'puttu with kadala', 'puttu and black chickpea curry', 'പുട്ടും കടലക്കറിയും'],
 'indian', NULL, 1, 'Per 100g combined. ~540 cal per plate (300g). Steamed rice flour cylinders with spiced black chickpea curry.', TRUE,
 220, 0, 3.0, 0.0, 250, 30, 2.0, 5, 1.5, 0, 30, 1.0, 85, 3.0, 0.02),

('idiyappam_curry', 'Idiyappam with Egg Curry (Combo)', 120.0, 5.0, 18.0, 3.2, 0.8, 0.5,
 280, NULL,
 'indian_traditional', ARRAY['idiyappam with curry', 'idiyappam egg curry', 'string hoppers with curry', 'ഇടിയാപ്പവും കറിയും'],
 'indian', NULL, 1, 'Per 100g combined. ~336 cal per plate (280g = 4 idiyappam + curry). String hoppers served with coconut-egg curry.', TRUE,
 250, 35, 1.2, 0.0, 120, 20, 0.8, 15, 1.0, 5, 14, 0.6, 60, 5.0, 0.01),

('malabar_parotta', 'Malabar Parotta', 300.0, 7.0, 42.0, 11.0, 1.5, 1.5,
 120, 60,
 'indian_traditional', ARRAY['malabar parotta', 'Kerala porotta', 'parotta', 'lachha parotta', 'malabar paratha', 'മലബാർ പൊറോട്ട'],
 'indian', NULL, 2, 'Per 100g. ~180 cal per parotta (~60g). Flaky layered flatbread made with maida, egg, and oil.', TRUE,
 350, 15, 3.5, 0.1, 80, 15, 1.2, 5, 0.0, 2, 12, 0.5, 50, 5.0, 0.01),

('kerala_porotta', 'Kerala Porotta', 300.0, 7.0, 42.0, 11.0, 1.5, 1.5,
 120, 60,
 'indian_traditional', ARRAY['kerala porotta', 'porotta', 'parotta Kerala', 'coin porotta', 'പൊറോട്ട'],
 'indian', NULL, 2, 'Per 100g. ~180 cal per porotta (~60g). Same as Malabar parotta, flaky layered bread. Ubiquitous Kerala street food.', TRUE,
 350, 15, 3.5, 0.1, 80, 15, 1.2, 5, 0.0, 2, 12, 0.5, 50, 5.0, 0.01),

('kerala_fish_curry', 'Kerala Fish Curry (Meen Curry)', 105.0, 12.0, 5.0, 4.5, 0.8, 0.5,
 250, NULL,
 'indian_traditional', ARRAY['kerala fish curry', 'meen curry', 'meen kuzhambu', 'fish curry Kerala', 'nadan meen curry', 'മീൻ കറി'],
 'indian', NULL, 1, 'Per 100g. ~263 cal per serving (250g). Fish simmered in tangy kokum-coconut gravy with fenugreek and curry leaves.', TRUE,
 380, 45, 2.0, 0.0, 280, 30, 1.5, 15, 3.0, 30, 25, 0.8, 150, 20.0, 0.15),

('prawn_moilee', 'Prawn Moilee', 135.0, 12.0, 4.0, 8.0, 0.5, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['prawn moilee', 'prawn molly', 'meen moilee', 'chemmin moilee', 'ചെമ്മീൻ മോളി'],
 'indian', NULL, 1, 'Per 100g. ~270 cal per serving (200g). Prawns in mild yellow coconut milk gravy with green chilies and turmeric.', TRUE,
 350, 120, 5.0, 0.0, 200, 50, 1.0, 10, 2.0, 5, 30, 1.2, 180, 25.0, 0.2),

('avial', 'Avial', 105.0, 2.5, 8.0, 7.5, 2.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['avial', 'aviyal', 'mixed vegetable coconut curry', 'sadya avial', 'അവിയൽ'],
 'indian', NULL, 1, 'Per 100g. ~210 cal per serving (200g). Mixed vegetables in thick coconut-yogurt gravy, Onam sadya essential.', TRUE,
 150, 2, 5.5, 0.0, 250, 35, 1.2, 80, 8.0, 0, 25, 0.5, 55, 1.5, 0.02),

('thoran', 'Thoran (Kerala Coconut Stir-Fry)', 95.0, 2.5, 7.0, 6.5, 3.0, 1.5,
 100, NULL,
 'indian_traditional', ARRAY['thoran', 'mezhukupuratti', 'cabbage thoran', 'beans thoran', 'vegetable thoran', 'തോരൻ'],
 'indian', NULL, 1, 'Per 100g. ~95 cal per serving (100g). Finely chopped vegetables stir-fried with grated coconut and curry leaves.', TRUE,
 80, 0, 4.5, 0.0, 200, 25, 1.0, 40, 10.0, 0, 18, 0.4, 35, 1.0, 0.01),

('olan', 'Olan (Ash Gourd Coconut Curry)', 70.0, 1.5, 5.0, 5.0, 1.0, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['olan', 'ash gourd curry', 'white gourd curry', 'kumbalanga olan', 'ഓലൻ'],
 'indian', NULL, 1, 'Per 100g. ~140 cal per serving (200g). Mild ash gourd and cowpeas simmered in coconut milk with curry leaves.', TRUE,
 120, 0, 3.5, 0.0, 130, 15, 0.6, 5, 3.0, 0, 10, 0.3, 25, 0.5, 0.02),

('erissery', 'Erissery (Pumpkin Lentil Curry)', 110.0, 3.5, 14.0, 5.0, 2.5, 3.0,
 200, NULL,
 'indian_traditional', ARRAY['erissery', 'erisherry', 'mathanga erissery', 'pumpkin curry Kerala', 'എരിശ്ശേരി'],
 'indian', NULL, 1, 'Per 100g. ~220 cal per serving (200g). Pumpkin and red cowpeas in spiced coconut gravy, Onam sadya dish.', TRUE,
 100, 0, 3.0, 0.0, 200, 25, 1.2, 200, 5.0, 0, 20, 0.5, 50, 1.5, 0.02),

('kaalan', 'Kaalan (Yogurt Coconut Curry)', 95.0, 2.0, 8.0, 6.5, 1.5, 2.0,
 200, NULL,
 'indian_traditional', ARRAY['kaalan', 'kalan', 'yam yogurt curry', 'plantain kaalan', 'കാളൻ'],
 'indian', NULL, 1, 'Per 100g. ~190 cal per serving (200g). Thick yogurt-coconut curry with raw banana or yam, sour and mildly spiced.', TRUE,
 120, 3, 4.5, 0.0, 180, 40, 0.5, 10, 2.0, 0, 15, 0.3, 40, 1.0, 0.01),

('kerala_beef_fry', 'Kerala Beef Fry', 195.0, 18.0, 6.0, 11.0, 1.5, 0.5,
 150, NULL,
 'indian_traditional', ARRAY['kerala beef fry', 'beef ularthiyathu', 'nadan beef fry', 'erachi olathiyathu', 'ബീഫ് ഫ്രൈ'],
 'indian', NULL, 1, 'Per 100g. ~293 cal per serving (150g). Dry-fried spiced beef with shallots, coconut slices, and curry leaves.', TRUE,
 420, 65, 4.5, 0.2, 300, 18, 3.0, 8, 2.0, 0, 22, 4.5, 180, 15.0, 0.03),

('kerala_egg_roast', 'Kerala Egg Roast', 145.0, 8.0, 6.0, 10.0, 1.0, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['kerala egg roast', 'mutta roast', 'egg roast Kerala', 'nadan mutta curry', 'മുട്ട റോസ്റ്റ്'],
 'indian', NULL, 1, 'Per 100g. ~290 cal per serving (200g = 2 eggs in gravy). Boiled eggs in spicy roasted onion-tomato gravy.', TRUE,
 380, 185, 3.0, 0.0, 200, 40, 1.5, 80, 3.0, 10, 12, 1.0, 130, 15.0, 0.02),

('meen_pollichathu', 'Meen Pollichathu (Fish in Banana Leaf)', 165.0, 18.0, 5.0, 8.5, 1.0, 0.5,
 180, NULL,
 'indian_traditional', ARRAY['meen pollichathu', 'fish pollichathu', 'karimeen pollichathu', 'fish in banana leaf', 'മീൻ പൊള്ളിച്ചത്'],
 'indian', NULL, 1, 'Per 100g. ~297 cal per serving (180g). Whole fish marinated and pan-fried in banana leaf with masala.', TRUE,
 400, 55, 3.0, 0.0, 320, 25, 1.5, 12, 2.0, 35, 28, 0.9, 200, 22.0, 0.18),

-- =====================================================================
-- KERALA - SNACKS & SWEETS (~5 items)
-- =====================================================================

('pazham_pori', 'Pazham Pori (Banana Fritters)', 250.0, 2.0, 40.0, 10.0, 3.0, 10.0,
 100, 50,
 'indian_traditional', ARRAY['pazham pori', 'ethakka appam', 'banana fry', 'vazhakkai bajji', 'pazham pori Kerala', 'പഴം പൊരി'],
 'indian', NULL, 2, 'Per 100g. ~125 cal per piece (~50g). Ripe nendran banana slices dipped in maida batter and deep-fried.', TRUE,
 100, 0, 2.0, 0.1, 300, 10, 0.6, 15, 5.0, 0, 25, 0.3, 20, 1.0, 0.01),

('unniyappam', 'Unniyappam', 320.0, 4.0, 50.0, 12.0, 2.0, 18.0,
 80, 15,
 'indian_traditional', ARRAY['unniyappam', 'unni appam', 'sweet rice fritters', 'ഉണ്ണിയപ്പം'],
 'indian', NULL, 5, 'Per 100g. ~48 cal per piece (~15g). Sweet mini rice-banana-jaggery balls deep-fried, temple festival treat.', TRUE,
 50, 5, 4.0, 0.0, 150, 15, 1.0, 5, 1.0, 0, 18, 0.5, 50, 2.0, 0.01),

('ada_pradhaman', 'Ada Pradhaman', 200.0, 3.5, 28.0, 8.5, 1.0, 18.0,
 200, NULL,
 'indian_traditional', ARRAY['ada pradhaman', 'ada payasam', 'palada pradhaman', 'rice ada payasam', 'അട പ്രഥമൻ'],
 'indian', NULL, 1, 'Per 100g. ~400 cal per serving (200g). Rich dessert with rice ada flakes simmered in coconut milk and jaggery.', TRUE,
 40, 5, 5.5, 0.0, 180, 30, 0.8, 5, 0.5, 0, 20, 0.4, 55, 1.5, 0.02),

('parippu_vada', 'Parippu Vada', 290.0, 10.0, 32.0, 14.0, 4.0, 1.5,
 80, 40,
 'indian_traditional', ARRAY['parippu vada', 'dal vada', 'lentil fritters', 'chana dal vada', 'masala vada', 'പരിപ്പുവട'],
 'indian', NULL, 2, 'Per 100g. ~116 cal per vada (~40g). Crispy deep-fried chana dal fritters with onion and spices.', TRUE,
 350, 0, 1.8, 0.1, 260, 25, 2.0, 5, 1.5, 0, 30, 1.0, 100, 3.0, 0.02),

('sukhiyan', 'Sukhiyan', 300.0, 5.0, 45.0, 12.0, 3.0, 15.0,
 80, 40,
 'indian_traditional', ARRAY['sukhiyan', 'sugiyan', 'sweet green gram fritters', 'Kerala modakam', 'സുഖിയൻ'],
 'indian', NULL, 2, 'Per 100g. ~120 cal per piece (~40g). Green gram and jaggery filling coated in maida batter and deep-fried.', TRUE,
 60, 0, 1.5, 0.1, 200, 15, 1.5, 3, 0.5, 0, 25, 0.8, 70, 2.0, 0.01),

-- =====================================================================
-- KERALA - RICE (~2 items)
-- =====================================================================

('matta_rice', 'Matta Rice (Kerala Red Rice, Cooked)', 145.0, 3.0, 30.0, 0.5, 2.0, 0.3,
 200, NULL,
 'indian_traditional', ARRAY['matta rice', 'Kerala red rice', 'palakkadan matta', 'rosematta rice', 'kuthari', 'മട്ട അരി'],
 'indian', NULL, 1, 'Per 100g cooked. ~290 cal per serving (200g). Parboiled red rice with high fiber and low GI, Kerala staple.', TRUE,
 5, 0, 0.1, 0.0, 80, 15, 1.2, 0, 0.0, 0, 30, 0.8, 75, 5.0, 0.0),

('ghee_rice_kerala', 'Ghee Rice (Kerala Neychoru)', 185.0, 3.0, 28.0, 7.0, 0.5, 0.3,
 200, NULL,
 'indian_traditional', ARRAY['ghee rice Kerala', 'neychoru', 'nei choru', 'ghee bhat', 'ney choru', 'നെയ്ച്ചോറ്'],
 'indian', NULL, 1, 'Per 100g. ~370 cal per serving (200g). Basmati or matta rice cooked in ghee with whole spices and fried onions.', TRUE,
 180, 15, 4.0, 0.1, 65, 10, 0.5, 30, 0.0, 2, 10, 0.4, 40, 3.0, 0.02),

-- =====================================================================
-- KARNATAKA - MAIN DISHES (~5 items)
-- =====================================================================

('bisi_bele_bath', 'Bisi Bele Bath', 140.0, 3.5, 24.0, 3.5, 2.0, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['bisi bele bath', 'bisibelebath', 'bisi bele bhath', 'hot lentil rice', 'ಬಿಸಿ ಬೇಳೆ ಬಾತ್'],
 'indian', NULL, 1, 'Per 100g. ~350 cal per plate (250g). Karnataka one-pot dish of rice, toor dal, tamarind, vegetables, and bisi bele powder.', TRUE,
 350, 0, 0.5, 0.0, 200, 25, 1.8, 40, 5.0, 0, 28, 0.8, 80, 3.0, 0.02),

('ragi_mudde_with_saaru', 'Ragi Mudde with Saaru (Combo)', 110.0, 3.5, 22.0, 1.0, 3.0, 0.3,
 300, 100,
 'indian_traditional', ARRAY['ragi mudde', 'ragi ball', 'finger millet ball', 'ragi mudde saaru', 'ರಾಗಿ ಮುದ್ದೆ'],
 'indian', NULL, 1, 'Per 100g combined. ~330 cal per meal (300g = 2 balls + saaru). Steamed ragi flour balls served with rasam/dal.', TRUE,
 250, 0, 0.2, 0.0, 200, 180, 3.0, 8, 3.0, 0, 80, 1.5, 140, 5.0, 0.01),

('akki_roti', 'Akki Roti (Rice Flour Flatbread)', 210.0, 3.5, 35.0, 6.5, 1.5, 0.5,
 100, 80,
 'indian_traditional', ARRAY['akki roti', 'rice roti', 'akki rotti', 'rice flour roti Karnataka', 'ಅಕ್ಕಿ ರೊಟ್ಟಿ'],
 'indian', NULL, 1, 'Per 100g. ~168 cal per roti (~80g). Thin rice flour flatbread with onions, dill, and green chilies, no fermentation.', TRUE,
 200, 0, 0.8, 0.0, 100, 12, 0.6, 15, 3.0, 0, 15, 0.4, 45, 3.0, 0.01),

('jolada_roti', 'Jolada Roti (Jowar Flatbread)', 230.0, 5.0, 45.0, 2.5, 4.5, 0.5,
 100, 80,
 'indian_traditional', ARRAY['jolada roti', 'jowar roti', 'jwari roti', 'sorghum flatbread', 'bajra roti', 'ಜೋಳದ ರೊಟ್ಟಿ'],
 'indian', NULL, 1, 'Per 100g. ~184 cal per roti (~80g). Thick sorghum flatbread, North Karnataka staple served with enne badnekayi.', TRUE,
 8, 0, 0.3, 0.0, 280, 20, 2.8, 0, 0.0, 0, 75, 1.5, 150, 7.0, 0.01),

('neer_dosa', 'Neer Dosa', 150.0, 3.0, 30.0, 2.0, 0.5, 0.3,
 100, 40,
 'indian_traditional', ARRAY['neer dosa', 'neer dose', 'water dosa', 'Mangalore neer dosa', 'ನೀರ್ ದೋಸೆ'],
 'indian', NULL, 3, 'Per 100g. ~60 cal per dosa (~40g). Thin, delicate crepe from watery rice batter, no fermentation needed.', TRUE,
 10, 0, 0.3, 0.0, 40, 8, 0.4, 0, 0.0, 0, 10, 0.3, 30, 2.5, 0.0),

-- =====================================================================
-- KARNATAKA - CURRIES & SIDES (~4 items)
-- =====================================================================

('saaru', 'Saaru (Karnataka Rasam)', 28.0, 0.8, 4.0, 0.8, 0.5, 0.5,
 250, NULL,
 'indian_traditional', ARRAY['saaru', 'saru', 'Karnataka rasam', 'tomato saaru', 'huli saaru', 'ಸಾರು'],
 'indian', NULL, 1, 'Per 100g. ~70 cal per bowl (250g). Tangy pepper-tomato broth, Karnataka version of rasam, served with rice.', TRUE,
 280, 0, 0.1, 0.0, 130, 8, 0.5, 15, 8.0, 0, 8, 0.2, 20, 0.5, 0.0),

('huli', 'Huli (Karnataka Sambar)', 80.0, 3.5, 11.0, 2.5, 2.5, 1.0,
 250, NULL,
 'indian_traditional', ARRAY['huli', 'Karnataka sambar', 'huli saaru', 'tili saaru', 'ಹುಳಿ'],
 'indian', NULL, 1, 'Per 100g. ~200 cal per serving (250g). Toor dal and vegetable stew with coconut-based huli powder, Karnataka sambar variant.', TRUE,
 320, 0, 0.4, 0.0, 230, 22, 1.5, 25, 5.0, 0, 28, 0.6, 75, 2.0, 0.01),

('enne_badnekayi', 'Enne Badnekayi (Stuffed Brinjal)', 130.0, 3.0, 8.0, 10.0, 3.0, 2.0,
 150, NULL,
 'indian_traditional', ARRAY['enne badnekayi', 'ennegayi', 'stuffed brinjal Karnataka', 'bharwa baingan', 'ಎಣ್ಣೆ ಬದನೆಕಾಯಿ'],
 'indian', NULL, 1, 'Per 100g. ~195 cal per serving (150g). Baby brinjals stuffed with peanut-coconut-sesame spice paste, oil-roasted.', TRUE,
 250, 0, 1.5, 0.0, 260, 20, 1.5, 15, 3.0, 0, 25, 0.6, 50, 2.0, 0.02),

('palya', 'Palya (Karnataka Dry Sabzi)', 85.0, 2.5, 9.0, 4.5, 3.0, 1.5,
 100, NULL,
 'indian_traditional', ARRAY['palya', 'palya Karnataka', 'dry sabzi Karnataka', 'vegetable palya', 'ಪಲ್ಯ'],
 'indian', NULL, 1, 'Per 100g. ~85 cal per serving (100g). Generic dry vegetable stir-fry with mustard, curry leaves, and grated coconut.', TRUE,
 80, 0, 2.8, 0.0, 210, 30, 1.0, 35, 8.0, 0, 18, 0.4, 35, 1.0, 0.01),

-- =====================================================================
-- KARNATAKA - SNACKS & SWEETS (~5 items)
-- =====================================================================

('mangalore_buns', 'Mangalore Buns', 280.0, 5.0, 42.0, 10.0, 1.5, 8.0,
 100, 50,
 'indian_traditional', ARRAY['mangalore buns', 'banana puri', 'kele ki puri', 'Mangalore banana buns', 'ಮಂಗಳೂರು ಬನ್ಸ್'],
 'indian', NULL, 2, 'Per 100g. ~140 cal per bun (~50g). Sweet banana-flavored deep-fried puffed bread, Mangalore specialty.', TRUE,
 200, 10, 1.5, 0.1, 180, 12, 1.0, 5, 3.0, 0, 15, 0.4, 40, 3.0, 0.01),

('goli_baje', 'Goli Baje (Mangalore Bajji)', 260.0, 5.5, 30.0, 13.0, 1.5, 1.0,
 80, 25,
 'indian_traditional', ARRAY['goli baje', 'mangalore bajji', 'mangalore bonda', 'mysore bonda', 'goli bajje', 'ಗೋಲಿ ಬಜೆ'],
 'indian', NULL, 3, 'Per 100g. ~65 cal per piece (~25g). Crispy deep-fried maida-curd dumplings with coconut and curry leaves.', TRUE,
 350, 5, 2.0, 0.1, 100, 15, 1.0, 3, 0.5, 0, 10, 0.4, 35, 2.0, 0.01),

('mysore_pak', 'Mysore Pak', 520.0, 5.0, 40.0, 38.0, 2.0, 28.0,
 50, 25,
 'indian_traditional', ARRAY['mysore pak', 'mysore pa', 'ghee mysore pak', 'soft mysore pak', 'ಮೈಸೂರು ಪಾಕ್'],
 'indian', NULL, 2, 'Per 100g. ~130 cal per piece (~25g). Rich sweet made from gram flour, ghee, and sugar. Mysore royal recipe.', TRUE,
 30, 25, 20.0, 0.2, 100, 18, 1.5, 40, 0.0, 2, 20, 0.8, 60, 3.0, 0.02),

('dharwad_peda', 'Dharwad Peda', 380.0, 8.0, 50.0, 16.0, 0.0, 42.0,
 50, 20,
 'indian_traditional', ARRAY['dharwad peda', 'dharwad pedha', 'dharwad pede', 'ಧಾರವಾಡ ಪೇಡ'],
 'indian', NULL, 2, 'Per 100g. ~76 cal per peda (~20g). Caramelized milk sweet from Dharwad, dense and fudgy with cardamom.', TRUE,
 60, 20, 8.0, 0.1, 150, 120, 0.5, 35, 0.0, 3, 15, 0.6, 100, 4.0, 0.01),

('holige', 'Holige (Obbattu / Puran Poli)', 270.0, 5.0, 45.0, 7.5, 2.0, 18.0,
 100, 70,
 'indian_traditional', ARRAY['holige', 'obbattu', 'puran poli', 'bele obbattu', 'bobbatlu', 'ಹೋಳಿಗೆ', 'ಒಬ್ಬಟ್ಟು'],
 'indian', NULL, 1, 'Per 100g. ~189 cal per holige (~70g). Sweet flatbread stuffed with chana dal and jaggery filling.', TRUE,
 50, 5, 3.0, 0.0, 160, 20, 1.5, 8, 0.5, 0, 18, 0.6, 60, 2.5, 0.01),

-- =====================================================================
-- KARNATAKA - RICE VARIETIES (~3 items)
-- =====================================================================

('chitranna', 'Chitranna (Karnataka Lemon Rice)', 175.0, 3.0, 27.0, 6.0, 1.0, 0.5,
 200, NULL,
 'indian_traditional', ARRAY['chitranna', 'chitrannam', 'Karnataka lemon rice', 'nimbe hannina chitranna', 'ಚಿತ್ರಾನ್ನ'],
 'indian', NULL, 1, 'Per 100g. ~350 cal per plate (200g). Karnataka-style lemon rice with peanuts, turmeric, and curry leaf tempering.', TRUE,
 260, 0, 0.8, 0.0, 120, 14, 0.8, 5, 4.0, 0, 16, 0.5, 55, 3.0, 0.02),

('vangi_bath', 'Vangi Bath (Brinjal Rice)', 160.0, 3.5, 25.0, 5.5, 2.0, 1.0,
 200, NULL,
 'indian_traditional', ARRAY['vangi bath', 'vangi bhath', 'brinjal rice', 'eggplant rice Karnataka', 'ವಾಂಗಿ ಬಾತ್'],
 'indian', NULL, 1, 'Per 100g. ~320 cal per plate (200g). Rice mixed with spiced brinjal masala and vangi bath powder. Karnataka signature.', TRUE,
 280, 0, 0.8, 0.0, 180, 15, 1.2, 12, 3.0, 0, 20, 0.5, 55, 2.5, 0.02),

('puliyogare', 'Puliyogare (Tamarind Rice Karnataka)', 180.0, 3.0, 30.0, 5.5, 1.5, 1.5,
 200, NULL,
 'indian_traditional', ARRAY['puliyogare', 'puliogare', 'tamarind rice', 'huli anna', 'gojju avalakki', 'ಪುಳಿಯೋಗರೆ'],
 'indian', NULL, 1, 'Per 100g. ~360 cal per plate (200g). Tangy tamarind rice with peanuts and sesame. Temple prasadam classic.', TRUE,
 300, 0, 0.8, 0.0, 140, 18, 1.0, 5, 2.0, 0, 18, 0.5, 60, 3.0, 0.02)

ON CONFLICT (food_name_normalized) DO NOTHING;
