-- 1003_indian_west_goan.sql
-- Traditional West Indian foods (Maharashtra, Goa, Konkan) + common Indian pantry items
-- All values per 100g. Sources: IFCT 2017, USDA, nutritionix, tarladalal, fatsecret, snapcalorie

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
-- MAHARASHTRIAN DISHES (~35 items)
-- ==========================================

-- Varan Bhaat: Dal rice combo. Per 100g of mixed varan+bhaat: ~135 cal
('varan_bhaat', 'Varan Bhaat (Maharashtrian Dal Rice)', 135.0, 4.5, 22.0, 3.0,
 1.8, 0.8, 300, NULL,
 'indian_traditional', ARRAY['varan bhaat', 'varan bhat', 'dal rice maharashtrian', 'maharashtrian dal chawal'],
 'indian', NULL, 1, '405 cal per plate (300g). Toor dal varan with steamed rice and ghee. Maharashtrian staple.', TRUE,
 280.0, 2.0, 1.2, 0.0, 180.0, 22.0, 1.2, 5.0, 1.0, 0.0, 25.0, 0.8, 75.0, 5.0, 0.02),

-- Amti: Maharashtrian spiced dal with kokum/tamarind
('amti', 'Amti (Maharashtrian Spiced Dal)', 95.0, 5.5, 12.0, 2.8,
 3.0, 1.5, 200, NULL,
 'indian_traditional', ARRAY['amti', 'amti dal', 'maharashtrian amti', 'katachi amti'],
 'indian', NULL, 1, '190 cal per serving (200g). Toor dal with kokum, jaggery and spices. Sweet-sour-spicy.', TRUE,
 320.0, 0.0, 0.5, 0.0, 280.0, 30.0, 1.8, 8.0, 3.0, 0.0, 28.0, 0.9, 90.0, 3.0, 0.01),

-- Pithla: Besan (gram flour) curry, simple and protein-rich
('pithla', 'Pithla (Gram Flour Curry)', 150.0, 7.0, 15.0, 7.0,
 2.5, 1.0, 200, NULL,
 'indian_traditional', ARRAY['pithla', 'pitla', 'besan curry maharashtrian', 'gram flour curry'],
 'indian', NULL, 1, '300 cal per serving (200g). Besan cooked with onions, green chillies, turmeric. Served with bhakri.', TRUE,
 350.0, 0.0, 1.0, 0.0, 220.0, 35.0, 2.2, 5.0, 4.0, 0.0, 40.0, 1.2, 100.0, 5.0, 0.0),

-- Pithla Bhakri combo plate
('pithla_bhakri', 'Pithla Bhakri (Gram Flour Curry with Millet Bread)', 180.0, 6.5, 28.0, 5.0,
 3.0, 1.0, 250, NULL,
 'indian_traditional', ARRAY['pithla bhakri', 'pitla bhakri', 'pithla with jowar bhakri'],
 'indian', NULL, 1, '450 cal per plate (250g). Classic Maharashtrian farmer meal: besan curry + jowar/bajra flatbread.', TRUE,
 340.0, 0.0, 1.0, 0.0, 240.0, 38.0, 2.5, 4.0, 3.0, 0.0, 45.0, 1.3, 110.0, 5.0, 0.0),

-- Zunka Bhakri: Dry besan preparation with bhakri
('zunka_bhakri', 'Zunka Bhakri (Dry Gram Flour with Millet Bread)', 195.0, 7.0, 27.0, 6.5,
 3.2, 1.0, 250, NULL,
 'indian_traditional', ARRAY['zunka bhakri', 'jhunka bhakri', 'zunka bhakar', 'dry pithla bhakri'],
 'indian', NULL, 1, '488 cal per plate (250g). Zunka is dry-cooked besan with onions and spices. Rural Maharashtra staple.', TRUE,
 360.0, 0.0, 1.2, 0.0, 230.0, 36.0, 2.4, 5.0, 3.5, 0.0, 42.0, 1.2, 105.0, 5.0, 0.0),

-- Bharli Vangi: Stuffed eggplant curry
('bharli_vangi', 'Bharli Vangi (Maharashtrian Stuffed Eggplant)', 120.0, 3.5, 10.0, 7.5,
 3.0, 3.0, 200, NULL,
 'indian_traditional', ARRAY['bharli vangi', 'stuffed brinjal maharashtrian', 'stuffed eggplant curry', 'masala vangi'],
 'indian', NULL, 1, '240 cal per serving (200g). Baby eggplants stuffed with peanut-coconut-sesame masala.', TRUE,
 280.0, 0.0, 1.5, 0.0, 310.0, 40.0, 1.5, 10.0, 5.0, 0.0, 30.0, 0.8, 70.0, 3.0, 0.01),

-- Misal Pav: Sprouted moth bean curry with pav
('misal_pav', 'Misal Pav (Sprouted Bean Curry with Bread Roll)', 175.0, 7.0, 22.0, 6.5,
 3.5, 2.0, 350, NULL,
 'indian_traditional', ARRAY['misal pav', 'misal', 'kolhapuri misal', 'puneri misal', 'mumbai misal'],
 'indian', NULL, 1, '613 cal per plate (350g). Spicy sprouted moth bean curry with farsan, onion, lemon, pav. Iconic Mumbai/Pune street food.', TRUE,
 450.0, 0.0, 1.5, 0.0, 320.0, 45.0, 2.8, 12.0, 6.0, 0.0, 38.0, 1.5, 120.0, 5.0, 0.02),

-- Usal Pav: Sprouted beans curry with pav
('usal_pav', 'Usal Pav (Sprouted Beans Curry with Bread Roll)', 155.0, 7.5, 20.0, 5.0,
 4.0, 1.5, 350, NULL,
 'indian_traditional', ARRAY['usal pav', 'usal', 'matki usal pav', 'sprouted bean curry pav'],
 'indian', NULL, 1, '543 cal per plate (350g). Simpler than misal - sprouted beans in spiced gravy with pav. No farsan topping.', TRUE,
 380.0, 0.0, 0.8, 0.0, 340.0, 40.0, 2.5, 8.0, 5.0, 0.0, 35.0, 1.3, 110.0, 4.0, 0.01),

-- Thalipeeth: Multigrain flatbread
('thalipeeth', 'Thalipeeth (Maharashtrian Multigrain Flatbread)', 250.0, 8.0, 38.0, 7.5,
 4.5, 1.5, 80, 80,
 'indian_traditional', ARRAY['thalipeeth', 'thalipith', 'maharashtrian thalipeeth', 'multigrain thalipeeth', 'bhajani thalipeeth'],
 'indian', NULL, 1, '200 cal per piece (80g). Made from bhajani flour (roasted mix of jowar, bajra, rice, wheat, chana dal). Topped with butter.', TRUE,
 320.0, 0.0, 1.5, 0.0, 200.0, 30.0, 2.5, 3.0, 1.0, 0.0, 50.0, 1.5, 130.0, 8.0, 0.01),

-- Bhakri (Jowar): Sorghum millet flatbread
('jowar_bhakri', 'Jowar Bhakri (Sorghum Millet Flatbread)', 290.0, 7.0, 58.0, 2.5,
 4.0, 0.5, 50, 50,
 'indian_traditional', ARRAY['jowar bhakri', 'jowar roti', 'sorghum bhakri', 'jwari bhakri'],
 'indian', NULL, 2, '145 cal per bhakri (50g). Gluten-free sorghum flatbread. Staple in rural Maharashtra. Two per serving.', TRUE,
 10.0, 0.0, 0.4, 0.0, 240.0, 20.0, 3.2, 0.0, 0.0, 0.0, 110.0, 1.5, 210.0, 12.0, 0.0),

-- Bhakri (Bajra): Pearl millet flatbread
('bajra_bhakri', 'Bajra Bhakri (Pearl Millet Flatbread)', 310.0, 8.5, 55.0, 5.0,
 4.5, 0.8, 50, 50,
 'indian_traditional', ARRAY['bajra bhakri', 'bajra roti', 'pearl millet bhakri', 'bajri bhakri'],
 'indian', NULL, 2, '155 cal per bhakri (50g). Nutritious pearl millet flatbread with higher fat than jowar. Served with thecha.', TRUE,
 12.0, 0.0, 0.8, 0.0, 280.0, 25.0, 6.0, 0.0, 0.0, 0.0, 120.0, 2.0, 250.0, 10.0, 0.0),

-- Sabudana Khichdi: Tapioca pearl preparation
('sabudana_khichdi', 'Sabudana Khichdi (Tapioca Pearl Stir-Fry)', 180.0, 3.0, 28.0, 6.5,
 1.0, 1.5, 200, NULL,
 'indian_traditional', ARRAY['sabudana khichdi', 'sago khichdi', 'tapioca khichdi', 'sabudana khichadi', 'fasting khichdi'],
 'indian', NULL, 1, '360 cal per serving (200g). Soaked tapioca pearls stir-fried with peanuts, potatoes, cumin. Popular fasting food.', TRUE,
 180.0, 0.0, 1.0, 0.0, 180.0, 15.0, 0.8, 2.0, 4.0, 0.0, 15.0, 0.6, 50.0, 2.0, 0.01),

-- Batata Vada: Deep-fried potato dumpling
('batata_vada', 'Batata Vada (Spiced Potato Fritter)', 265.0, 5.0, 30.0, 14.0,
 2.0, 1.5, 80, 80,
 'indian_traditional', ARRAY['batata vada', 'aloo vada', 'potato vada', 'batata wada', 'aloo bonda'],
 'indian', NULL, 1, '212 cal per vada (80g). Spiced mashed potato dipped in besan batter and deep-fried. Key component of vada pav.', TRUE,
 380.0, 0.0, 2.5, 0.1, 280.0, 20.0, 1.5, 3.0, 6.0, 0.0, 18.0, 0.5, 55.0, 2.0, 0.0),

-- Kothimbir Vadi: Coriander fritters
('kothimbir_vadi', 'Kothimbir Vadi (Coriander Gram Flour Fritters)', 250.0, 8.0, 28.0, 12.0,
 3.5, 1.0, 100, 25,
 'indian_traditional', ARRAY['kothimbir vadi', 'kothimbir wadi', 'coriander fritters', 'cilantro vadi'],
 'indian', NULL, 4, '250 cal per serving of 4 pieces (100g). Steamed besan-coriander cakes, then shallow-fried. Maharashtrian snack.', TRUE,
 340.0, 0.0, 2.0, 0.0, 250.0, 40.0, 2.5, 60.0, 12.0, 0.0, 35.0, 1.2, 95.0, 5.0, 0.01),

-- Puran Poli (Maharashtrian)
('puran_poli', 'Puran Poli (Sweet Stuffed Flatbread)', 298.0, 6.5, 50.0, 8.0,
 2.5, 22.0, 100, 100,
 'indian_traditional', ARRAY['puran poli', 'puranpoli', 'holige', 'obbattu', 'vedmi', 'bobbattu'],
 'indian', NULL, 1, '298 cal per poli (100g). Chana dal-jaggery stuffed flatbread. Maharashtrian/Gujarati festival sweet.', TRUE,
 40.0, 5.0, 3.5, 0.0, 180.0, 30.0, 1.8, 20.0, 0.5, 0.0, 25.0, 0.8, 80.0, 4.0, 0.0),

-- Ukdiche Modak (Steamed)
('ukdiche_modak', 'Ukdiche Modak (Steamed Rice Flour Dumpling)', 280.0, 4.0, 48.0, 8.0,
 2.0, 25.0, 50, 50,
 'indian_traditional', ARRAY['ukdiche modak', 'steamed modak', 'modak', 'rice flour modak', 'ganesh modak'],
 'indian', NULL, 2, '140 cal per modak (50g). Rice flour shell with coconut-jaggery filling, steamed. Ganesh Chaturthi special.', TRUE,
 15.0, 0.0, 5.5, 0.0, 140.0, 12.0, 1.0, 0.0, 0.5, 0.0, 18.0, 0.5, 50.0, 3.0, 0.01),

-- Fried Modak
('fried_modak', 'Fried Modak (Deep-Fried Sweet Dumpling)', 380.0, 4.5, 45.0, 20.0,
 1.5, 24.0, 40, 40,
 'indian_traditional', ARRAY['fried modak', 'talniche modak', 'karanji modak'],
 'indian', NULL, 3, '152 cal per modak (40g). Deep-fried version with coconut-jaggery or dry fruit filling. Richer than steamed.', TRUE,
 20.0, 0.0, 8.0, 0.2, 110.0, 10.0, 0.8, 0.0, 0.3, 0.0, 15.0, 0.4, 45.0, 2.0, 0.01),

-- Aamras
('aamras', 'Aamras (Sweet Mango Pulp)', 75.0, 0.8, 18.0, 0.3,
 1.0, 15.0, 150, NULL,
 'indian_traditional', ARRAY['aamras', 'amras', 'mango ras', 'mango pulp sweetened', 'aam ras'],
 'indian', NULL, 1, '113 cal per serving (150g). Fresh ripe mango puree with cardamom and saffron. Served with puri. Summer treat.', TRUE,
 5.0, 0.0, 0.1, 0.0, 170.0, 10.0, 0.2, 54.0, 28.0, 0.0, 10.0, 0.1, 12.0, 0.6, 0.0),

-- Sol Kadhi
('sol_kadhi', 'Sol Kadhi (Kokum Coconut Milk Drink)', 55.0, 0.8, 4.0, 4.0,
 0.5, 2.0, 200, NULL,
 'indian_traditional', ARRAY['sol kadhi', 'solkadhi', 'sol kadi', 'kokum curry', 'kokum coconut drink'],
 'indian', NULL, 1, '110 cal per glass (200g). Kokum extract blended with coconut milk, garlic, cumin. Goan/Konkan digestive drink.', TRUE,
 120.0, 0.0, 3.5, 0.0, 150.0, 8.0, 0.5, 0.0, 2.0, 0.0, 15.0, 0.3, 30.0, 1.0, 0.02),

-- Matki Usal (Sprouted moth bean curry)
('matki_usal', 'Matki Usal (Sprouted Moth Bean Curry)', 130.0, 8.0, 16.0, 3.5,
 5.0, 1.5, 200, NULL,
 'indian_traditional', ARRAY['matki usal', 'moth bean usal', 'sprouted matki', 'matki chi usal', 'matki ussal'],
 'indian', NULL, 1, '260 cal per serving (200g). Sprouted moth beans in spiced gravy with coconut. High protein, high fiber.', TRUE,
 300.0, 0.0, 0.5, 0.0, 380.0, 42.0, 3.0, 5.0, 4.0, 0.0, 45.0, 1.5, 130.0, 5.0, 0.02),

-- Kombdi Vade: Chicken with deep-fried bread
('kombdi_vade', 'Kombdi Vade (Malvani Chicken with Fried Bread)', 220.0, 12.0, 18.0, 11.0,
 1.0, 1.0, 350, NULL,
 'indian_traditional', ARRAY['kombdi vade', 'chicken vade', 'malvani kombdi vade', 'kombdi wade'],
 'indian', NULL, 1, '770 cal per plate (350g). Spicy coconut chicken curry served with deep-fried wheat bread. Malvani feast dish.', TRUE,
 420.0, 55.0, 3.5, 0.1, 250.0, 28.0, 1.8, 18.0, 2.0, 2.0, 25.0, 1.5, 120.0, 15.0, 0.05),

-- Kolhapuri Chicken
('kolhapuri_chicken', 'Kolhapuri Chicken (Spicy Chicken Curry)', 155.0, 14.0, 5.0, 9.0,
 1.0, 1.5, 250, NULL,
 'indian_traditional', ARRAY['kolhapuri chicken', 'chicken kolhapuri', 'kolhapuri murgh', 'spicy kolhapuri chicken'],
 'indian', NULL, 1, '388 cal per serving (250g). Fiery chicken curry with Kolhapuri masala (dried red chillies, coconut, sesame). Very spicy.', TRUE,
 480.0, 65.0, 2.5, 0.0, 280.0, 22.0, 2.0, 25.0, 3.0, 2.0, 22.0, 1.8, 140.0, 18.0, 0.04),

-- Kolhapuri Mutton
('kolhapuri_mutton', 'Kolhapuri Mutton (Spicy Goat Curry)', 180.0, 15.0, 4.0, 11.5,
 0.8, 1.0, 250, NULL,
 'indian_traditional', ARRAY['kolhapuri mutton', 'mutton kolhapuri', 'kolhapuri goat curry', 'spicy mutton kolhapuri'],
 'indian', NULL, 1, '450 cal per serving (250g). Bone-in goat meat in fiery Kolhapuri spice paste. Rich, bold flavors.', TRUE,
 460.0, 75.0, 4.0, 0.0, 260.0, 18.0, 2.5, 0.0, 1.5, 0.0, 20.0, 3.5, 150.0, 12.0, 0.03),

-- Tambda Rassa: Red spicy mutton curry
('tambda_rassa', 'Tambda Rassa (Kolhapuri Red Mutton Curry)', 140.0, 12.0, 5.0, 8.5,
 1.0, 1.5, 250, NULL,
 'indian_traditional', ARRAY['tambda rassa', 'tambda rasa', 'red rassa', 'kolhapuri tambda rassa', 'laal rassa'],
 'indian', NULL, 1, '350 cal per serving (250g). Fiery red broth-based mutton curry with dry red chillies, coconut. Kolhapuri specialty.', TRUE,
 500.0, 60.0, 2.8, 0.0, 240.0, 15.0, 2.2, 30.0, 3.0, 0.0, 18.0, 2.8, 130.0, 10.0, 0.02),

-- Pandhra Rassa: White chicken/mutton curry
('pandhra_rassa', 'Pandhra Rassa (Kolhapuri White Curry)', 110.0, 10.0, 4.0, 6.0,
 0.5, 1.0, 250, NULL,
 'indian_traditional', ARRAY['pandhra rassa', 'pandhra rasa', 'white rassa', 'kolhapuri pandhra rassa', 'white curry kolhapuri'],
 'indian', NULL, 1, '275 cal per serving (250g). Mild coconut-cashew white broth curry with chicken or mutton. Creamy, aromatic.', TRUE,
 380.0, 45.0, 2.2, 0.0, 200.0, 20.0, 1.2, 5.0, 1.5, 1.0, 18.0, 1.5, 110.0, 12.0, 0.03),

-- Surmai Fry (Kingfish fry)
('surmai_fry', 'Surmai Fry (Pan-Fried Kingfish)', 195.0, 18.0, 6.0, 11.0,
 0.3, 0.5, 120, 120,
 'indian_traditional', ARRAY['surmai fry', 'kingfish fry', 'seer fish fry', 'surmai tawa fry', 'king mackerel fry'],
 'indian', NULL, 1, '234 cal per fillet (120g). Marinated in red chilli-turmeric paste, shallow-fried. Iconic Mumbai/Konkan fish.', TRUE,
 350.0, 55.0, 2.0, 0.0, 320.0, 25.0, 1.5, 15.0, 1.0, 40.0, 30.0, 0.8, 200.0, 35.0, 0.8),

-- Bombil Fry (Bombay duck fry)
('bombil_fry', 'Bombil Fry (Fried Bombay Duck Fish)', 220.0, 14.0, 8.0, 15.0,
 0.5, 0.5, 100, NULL,
 'indian_traditional', ARRAY['bombil fry', 'bombay duck fry', 'bombil tawa fry', 'fried bombil', 'dried bombil fry'],
 'indian', NULL, 1, '220 cal per serving (100g). Rava-coated and fried. Delicate, soft-textured fish. Mumbai coastal specialty.', TRUE,
 420.0, 50.0, 2.5, 0.1, 200.0, 40.0, 2.0, 10.0, 0.5, 15.0, 25.0, 0.6, 150.0, 25.0, 0.3),

-- Aam ka Achaar (Mango pickle)
('aam_ka_achaar', 'Aam ka Achaar (Indian Mango Pickle)', 185.0, 1.5, 10.0, 15.0,
 2.0, 6.0, 20, NULL,
 'indian_traditional', ARRAY['aam ka achaar', 'mango pickle', 'mango achaar', 'aam ka achar', 'kairi ka achaar'],
 'indian', NULL, 1, '37 cal per tbsp (20g). Raw mango in mustard oil with fenugreek, chilli. High sodium condiment. Use sparingly.', TRUE,
 3800.0, 0.0, 2.0, 0.0, 142.0, 20.0, 1.5, 10.0, 5.0, 0.0, 8.0, 0.3, 15.0, 0.5, 0.0),

-- Nimbu ka Achaar (Lime pickle)
('nimbu_ka_achaar', 'Nimbu ka Achaar (Indian Lime Pickle)', 175.0, 1.0, 12.0, 14.0,
 2.5, 5.0, 20, NULL,
 'indian_traditional', ARRAY['nimbu ka achaar', 'lime pickle', 'lemon pickle', 'nimbu achaar', 'lemon achaar'],
 'indian', NULL, 1, '35 cal per tbsp (20g). Lime/lemon in oil with turmeric, chilli, mustard. Tangy, pungent condiment.', TRUE,
 3500.0, 0.0, 1.8, 0.0, 120.0, 25.0, 1.0, 5.0, 8.0, 0.0, 6.0, 0.2, 12.0, 0.3, 0.0),

-- Methia Keri (Fenugreek mango pickle)
('methia_keri', 'Methia Keri (Fenugreek Mango Pickle)', 190.0, 2.5, 14.0, 14.0,
 3.0, 8.0, 20, NULL,
 'indian_traditional', ARRAY['methia keri', 'fenugreek mango pickle', 'methi keri', 'methiya keri', 'gujarati mango pickle'],
 'indian', NULL, 1, '38 cal per tbsp (20g). Raw mango with fenugreek seeds in oil. Gujarati/Maharashtrian style. Slightly sweet.', TRUE,
 3200.0, 0.0, 1.8, 0.0, 130.0, 22.0, 2.5, 8.0, 4.0, 0.0, 12.0, 0.5, 20.0, 0.5, 0.0),

-- ==========================================
-- GOAN DISHES (~25 items)
-- ==========================================

-- Goan Fish Curry (Xitti Kodi)
('goan_fish_curry', 'Goan Fish Curry (Xitti Kodi)', 120.0, 10.0, 6.0, 6.5,
 1.0, 1.5, 250, NULL,
 'indian_traditional', ARRAY['goan fish curry', 'xitti kodi', 'goan fish curry rice', 'goa fish curry', 'coconut fish curry goan'],
 'indian', NULL, 1, '300 cal per serving (250g). Coconut-tamarind based curry with pomfret/kingfish. Goan staple everyday meal.', TRUE,
 380.0, 40.0, 4.0, 0.0, 280.0, 22.0, 1.2, 10.0, 3.0, 20.0, 25.0, 0.7, 150.0, 28.0, 0.5),

-- Fish Recheado
('fish_recheado', 'Fish Recheado (Goan Spice-Stuffed Fish)', 185.0, 16.0, 5.0, 11.0,
 0.8, 1.5, 150, 150,
 'indian_traditional', ARRAY['fish recheado', 'recheado fish', 'pomfret recheado', 'goan recheado masala fish'],
 'indian', NULL, 1, '278 cal per fish (150g). Whole pomfret slit and stuffed with red recheado masala, pan-fried. Festive Goan dish.', TRUE,
 450.0, 60.0, 2.0, 0.0, 300.0, 30.0, 1.8, 25.0, 3.0, 30.0, 28.0, 0.9, 180.0, 30.0, 0.6),

-- Prawn Balchao
('prawn_balchao', 'Prawn Balchao (Goan Prawn Pickle Curry)', 145.0, 14.0, 6.0, 7.5,
 1.0, 2.0, 200, NULL,
 'indian_traditional', ARRAY['prawn balchao', 'balchao', 'goan prawn pickle', 'shrimp balchao', 'balchao prawns'],
 'indian', NULL, 1, '290 cal per serving (200g). Prawns in spicy vinegar-based pickle-style masala. Tangy, fiery, preserves well.', TRUE,
 520.0, 120.0, 1.2, 0.0, 220.0, 45.0, 2.0, 15.0, 5.0, 5.0, 30.0, 1.2, 180.0, 30.0, 0.3),

-- Prawn Xacuti
('prawn_xacuti', 'Prawn Xacuti (Goan Coconut Prawn Curry)', 130.0, 12.0, 5.0, 7.0,
 1.2, 1.5, 250, NULL,
 'indian_traditional', ARRAY['prawn xacuti', 'shrimp xacuti', 'goan prawn xacuti', 'xacuti prawns'],
 'indian', NULL, 1, '325 cal per serving (250g). Prawns in complex roasted spice + coconut gravy. Rich, aromatic Goan curry.', TRUE,
 400.0, 100.0, 4.5, 0.0, 260.0, 50.0, 1.8, 12.0, 3.0, 5.0, 32.0, 1.0, 170.0, 28.0, 0.35),

-- Fish Xacuti
('fish_xacuti', 'Fish Xacuti (Goan Coconut Fish Curry)', 115.0, 10.0, 4.5, 6.5,
 1.0, 1.5, 250, NULL,
 'indian_traditional', ARRAY['fish xacuti', 'goan fish xacuti', 'xacuti fish curry', 'mackerel xacuti'],
 'indian', NULL, 1, '288 cal per serving (250g). White fish in toasted spice-coconut xacuti masala. Complex warm spice flavors.', TRUE,
 370.0, 45.0, 4.2, 0.0, 270.0, 35.0, 1.5, 10.0, 2.5, 25.0, 28.0, 0.8, 160.0, 26.0, 0.45),

-- Goan Prawn Curry (distinct from xacuti/balchao)
('goan_prawn_curry', 'Goan Prawn Curry (Coconut Prawn Curry)', 125.0, 12.0, 5.5, 6.0,
 0.8, 1.5, 250, NULL,
 'indian_traditional', ARRAY['goan prawn curry', 'goa shrimp curry', 'coconut prawn curry goan', 'prawn curry goan style'],
 'indian', NULL, 1, '313 cal per serving (250g). Simple coconut-based prawn curry with kokum. Everyday Goan home-style.', TRUE,
 350.0, 100.0, 3.8, 0.0, 250.0, 48.0, 1.5, 8.0, 2.0, 5.0, 28.0, 1.0, 165.0, 28.0, 0.35),

-- Ambot Tik (Sour curry)
('ambot_tik', 'Ambot Tik (Goan Sour Fish Curry)', 105.0, 10.0, 6.0, 4.5,
 1.0, 2.0, 250, NULL,
 'indian_traditional', ARRAY['ambot tik', 'ambotik', 'goan sour curry', 'goan sour fish curry', 'ambot tik shark'],
 'indian', NULL, 1, '263 cal per serving (250g). Tangy tamarind-based fish curry. Often made with shark or ray. Distinctly sour.', TRUE,
 360.0, 40.0, 1.5, 0.0, 240.0, 30.0, 1.5, 8.0, 4.0, 15.0, 22.0, 0.7, 140.0, 25.0, 0.4),

-- Caldeirada (Goan fish stew)
('caldeirada', 'Caldeirada (Goan Fish Stew)', 95.0, 9.0, 5.0, 4.0,
 1.0, 2.0, 300, NULL,
 'indian_traditional', ARRAY['caldeirada', 'goan fish stew', 'caldeirada de peixe', 'goan caldeirada'],
 'indian', NULL, 1, '285 cal per serving (300g). Portuguese-influenced layered fish stew with potatoes, tomatoes, onions. Mild.', TRUE,
 320.0, 35.0, 1.0, 0.0, 300.0, 25.0, 1.2, 20.0, 8.0, 15.0, 22.0, 0.6, 130.0, 20.0, 0.35),

-- Tisrya Masala (Clam curry)
('tisrya_masala', 'Tisrya Masala (Goan Clam Curry)', 110.0, 11.0, 5.0, 5.0,
 0.8, 1.5, 200, NULL,
 'indian_traditional', ARRAY['tisrya masala', 'clam curry goan', 'tisreo masala', 'goan clam masala'],
 'indian', NULL, 1, '220 cal per serving (200g). Clams in coconut-spice gravy. Konkan coastal specialty. Rich in iron.', TRUE,
 400.0, 35.0, 2.5, 0.0, 280.0, 55.0, 4.0, 8.0, 3.0, 0.0, 20.0, 1.5, 160.0, 20.0, 0.25),

-- Goan Crab Curry
('goan_crab_curry', 'Goan Crab Curry (Coconut Crab Curry)', 100.0, 10.0, 5.0, 4.5,
 0.8, 1.5, 300, NULL,
 'indian_traditional', ARRAY['goan crab curry', 'crab xec xec', 'goa crab curry', 'coconut crab curry goan'],
 'indian', NULL, 1, '300 cal per serving (300g). Crab in coconut-based curry. Messy to eat, rich in flavor. Goan seafood classic.', TRUE,
 380.0, 50.0, 3.0, 0.0, 240.0, 60.0, 1.5, 5.0, 2.0, 0.0, 25.0, 2.5, 140.0, 22.0, 0.3),

-- Pork Vindaloo (Goan)
('goan_pork_vindaloo', 'Goan Pork Vindaloo (Spicy Vinegar Pork Curry)', 165.0, 14.0, 5.0, 10.0,
 0.8, 2.0, 250, NULL,
 'indian_traditional', ARRAY['goan pork vindaloo', 'vindaloo', 'pork vindaloo', 'goan vindalho', 'vindalho de porco'],
 'indian', NULL, 1, '413 cal per serving (250g). Pork in fiery vinegar-chilli-garlic gravy. Portuguese-Goan origin. Iconic dish.', TRUE,
 480.0, 70.0, 3.5, 0.0, 280.0, 15.0, 2.0, 15.0, 3.0, 2.0, 18.0, 2.5, 140.0, 15.0, 0.05),

-- Sorpotel
('sorpotel', 'Sorpotel (Goan Spiced Pork Offal Curry)', 190.0, 14.0, 4.0, 13.0,
 0.5, 1.5, 200, NULL,
 'indian_traditional', ARRAY['sorpotel', 'sarapatel', 'goan sorpotel', 'pork sorpotel'],
 'indian', NULL, 1, '380 cal per serving (200g). Pork meat and liver in spiced vinegar gravy. Goan Christmas specialty. Bold flavors.', TRUE,
 520.0, 180.0, 4.5, 0.0, 220.0, 12.0, 5.0, 3000.0, 2.0, 5.0, 16.0, 4.0, 200.0, 25.0, 0.05),

-- Cafreal Chicken
('cafreal_chicken', 'Cafreal Chicken (Goan Green Masala Chicken)', 170.0, 18.0, 3.0, 9.5,
 0.8, 0.5, 200, NULL,
 'indian_traditional', ARRAY['cafreal chicken', 'chicken cafreal', 'galinha cafreal', 'goan green chicken'],
 'indian', NULL, 1, '340 cal per serving (200g). Chicken marinated in green coriander-chilli-spice paste, pan-fried. Goan bar snack.', TRUE,
 420.0, 80.0, 2.5, 0.0, 280.0, 20.0, 1.8, 30.0, 8.0, 2.0, 22.0, 1.8, 160.0, 20.0, 0.04),

-- Goan Sausage (Chourico)
('goan_sausage', 'Goan Sausage / Chourico (Spiced Pork Sausage)', 300.0, 18.0, 4.0, 24.0,
 0.5, 1.0, 60, 60,
 'indian_traditional', ARRAY['goan sausage', 'chourico', 'goan chourico', 'goa sausage', 'choris'],
 'indian', NULL, 2, '180 cal per sausage (60g). Sun-dried pork sausage with toddy vinegar, red chillies, garlic. Goan charcuterie.', TRUE,
 800.0, 75.0, 8.5, 0.1, 250.0, 10.0, 2.5, 20.0, 2.0, 3.0, 15.0, 2.5, 140.0, 18.0, 0.05),

-- Xacuti Chicken
('xacuti_chicken', 'Xacuti Chicken (Goan Roasted Spice Chicken Curry)', 125.0, 12.0, 4.0, 6.5,
 1.5, 1.0, 250, NULL,
 'indian_traditional', ARRAY['xacuti chicken', 'chicken xacuti', 'goan chicken xacuti', 'shakuti chicken'],
 'indian', NULL, 1, '313 cal per serving (250g). Chicken in complex roasted spice coconut gravy. 20+ spices including poppy, star anise.', TRUE,
 380.0, 55.0, 3.8, 0.0, 260.0, 30.0, 1.8, 12.0, 2.5, 2.0, 25.0, 1.5, 145.0, 18.0, 0.04),

-- Goan Vegetable Curry
('goan_vegetable_curry', 'Goan Vegetable Curry (Mixed Veg Coconut Curry)', 85.0, 2.5, 8.0, 5.0,
 2.0, 2.5, 250, NULL,
 'indian_traditional', ARRAY['goan vegetable curry', 'goan veg curry', 'goan mixed veg', 'goan coconut veg curry'],
 'indian', NULL, 1, '213 cal per serving (250g). Mixed vegetables in coconut milk gravy with Goan spices. Mild and creamy.', TRUE,
 300.0, 0.0, 3.5, 0.0, 280.0, 30.0, 1.2, 40.0, 8.0, 0.0, 20.0, 0.5, 60.0, 2.0, 0.02),

-- Ros Omelette
('ros_omelette', 'Ros Omelette (Goan Curry Omelette)', 145.0, 9.0, 6.0, 10.0,
 0.5, 1.5, 250, NULL,
 'indian_traditional', ARRAY['ros omelette', 'goan ros omelette', 'rassa omelette', 'goan egg curry'],
 'indian', NULL, 1, '363 cal per plate (250g). Fluffy omelette smothered in spicy coconut-based ros (gravy). Goan comfort food.', TRUE,
 420.0, 180.0, 3.0, 0.0, 200.0, 40.0, 1.8, 80.0, 2.0, 10.0, 15.0, 1.0, 120.0, 15.0, 0.05),

-- Goan Mushroom Xacuti
('goan_mushroom_xacuti', 'Goan Mushroom Xacuti (Coconut Mushroom Curry)', 95.0, 3.5, 5.0, 7.0,
 1.5, 1.5, 250, NULL,
 'indian_traditional', ARRAY['mushroom xacuti', 'goan mushroom xacuti', 'veg xacuti', 'mushroom shakuti'],
 'indian', NULL, 1, '238 cal per serving (250g). Mushrooms in xacuti roasted-spice coconut gravy. Vegetarian Goan main.', TRUE,
 340.0, 0.0, 4.5, 0.0, 300.0, 25.0, 1.5, 0.0, 3.0, 5.0, 18.0, 0.8, 80.0, 8.0, 0.02),

-- Goan Pao (Bread)
('goan_pao', 'Goan Pao (Goan Bread Roll)', 280.0, 8.0, 52.0, 3.5,
 2.0, 3.0, 50, 50,
 'indian_traditional', ARRAY['goan pao', 'goan pav', 'goan bread', 'poee', 'poi bread goa', 'goan poi'],
 'indian', NULL, 2, '140 cal per pao (50g). Soft, slightly sweet bread roll. Goan bakery staple. Served with curries, xacuti.', TRUE,
 350.0, 0.0, 0.5, 0.0, 80.0, 25.0, 1.8, 0.0, 0.0, 0.0, 15.0, 0.5, 60.0, 10.0, 0.0),

-- Sannas (Goan rice cakes)
('sannas', 'Sannas (Goan Steamed Rice Cakes)', 160.0, 3.0, 30.0, 2.5,
 0.5, 3.0, 60, 60,
 'indian_traditional', ARRAY['sannas', 'sanna', 'goan sannas', 'goan rice cakes', 'goan idli'],
 'indian', NULL, 3, '96 cal per sanna (60g). Fermented rice + coconut batter, steamed. Sweeter, fluffier than idli. Served with curry.', TRUE,
 30.0, 0.0, 1.0, 0.0, 70.0, 8.0, 0.5, 0.0, 0.0, 0.0, 10.0, 0.3, 35.0, 3.0, 0.01),

-- Bebinca (Layered cake)
('bebinca', 'Bebinca (Goan Layered Coconut Cake)', 320.0, 5.0, 38.0, 16.0,
 1.0, 28.0, 80, NULL,
 'indian_traditional', ARRAY['bebinca', 'bibinca', 'goan bebinca', 'goan layered cake', 'bibik'],
 'indian', NULL, 1, '256 cal per slice (80g). 7-16 layer cake: coconut milk, egg yolks, sugar, ghee, flour. Goan Christmas dessert.', TRUE,
 50.0, 120.0, 8.0, 0.0, 120.0, 30.0, 0.8, 80.0, 0.0, 10.0, 15.0, 0.5, 70.0, 5.0, 0.01),

-- Dodol (Goan sweet)
('dodol', 'Dodol (Goan Jaggery Coconut Sweet)', 350.0, 2.5, 55.0, 14.0,
 1.5, 40.0, 50, NULL,
 'indian_traditional', ARRAY['dodol', 'goan dodol', 'coconut dodol', 'goan jaggery sweet'],
 'indian', NULL, 1, '175 cal per piece (50g). Sticky toffee-like sweet made from coconut milk, jaggery, rice flour. Goan festive sweet.', TRUE,
 20.0, 0.0, 10.0, 0.0, 150.0, 15.0, 1.5, 0.0, 0.0, 0.0, 20.0, 0.4, 40.0, 2.0, 0.01),

-- Kulkuls (Goan fried sweet)
('kulkuls', 'Kulkuls (Goan Fried Sweet Curls)', 420.0, 5.0, 52.0, 22.0,
 0.5, 25.0, 30, 8,
 'indian_traditional', ARRAY['kulkuls', 'kidyo', 'goan kulkuls', 'goan christmas sweets curls'],
 'indian', NULL, 5, '34 cal per piece (8g). Curl-shaped deep-fried dough coated in sugar. Goan Christmas tradition.', TRUE,
 40.0, 30.0, 4.0, 0.2, 50.0, 15.0, 0.5, 10.0, 0.0, 2.0, 8.0, 0.3, 35.0, 3.0, 0.0),

-- Feni (Cashew/coconut liquor)
('feni', 'Feni (Goan Cashew/Coconut Liquor)', 230.0, 0.0, 0.0, 0.0,
 0.0, 0.0, 30, NULL,
 'indian_traditional', ARRAY['feni', 'goan feni', 'cashew feni', 'coconut feni', 'caju feni'],
 'indian', NULL, 1, '69 cal per shot (30ml). Goan traditional spirit distilled from cashew apple or coconut toddy. ~40% ABV.', TRUE,
 2.0, 0.0, 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0),

-- Kokum Sherbet
('kokum_sherbet', 'Kokum Sherbet (Kokum Cooler)', 40.0, 0.2, 10.0, 0.1,
 0.3, 8.0, 250, NULL,
 'indian_traditional', ARRAY['kokum sherbet', 'kokum juice', 'kokum drink', 'kokum sharbat', 'agal sherbet'],
 'indian', NULL, 1, '100 cal per glass (250ml). Kokum extract with sugar/jaggery, cumin, salt. Cooling digestive summer drink.', TRUE,
 200.0, 0.0, 0.0, 0.0, 50.0, 5.0, 0.3, 0.0, 3.0, 0.0, 5.0, 0.1, 5.0, 0.2, 0.0),

-- ==========================================
-- KONKAN / MALVANI DISHES (~10 items)
-- ==========================================

-- Malvani Chicken Curry
('malvani_chicken_curry', 'Malvani Chicken Curry (Coconut Chicken Curry)', 150.0, 14.0, 4.5, 8.5,
 1.0, 1.5, 250, NULL,
 'indian_traditional', ARRAY['malvani chicken curry', 'malvani chicken', 'malvani kombdi', 'konkan chicken curry'],
 'indian', NULL, 1, '375 cal per serving (250g). Chicken in roasted coconut-red chilli masala. Konkan coastal cuisine. Moderately spicy.', TRUE,
 420.0, 60.0, 3.0, 0.0, 260.0, 25.0, 1.8, 18.0, 2.5, 2.0, 22.0, 1.5, 140.0, 18.0, 0.05),

-- Malvani Fish Curry
('malvani_fish_curry', 'Malvani Fish Curry (Coconut Fish Curry)', 115.0, 11.0, 5.0, 6.0,
 1.0, 1.5, 250, NULL,
 'indian_traditional', ARRAY['malvani fish curry', 'malvani machi', 'konkan fish curry', 'malvani coconut fish'],
 'indian', NULL, 1, '288 cal per serving (250g). Fish in roasted coconut-spice curry. Kokum for tanginess. Konkan staple.', TRUE,
 350.0, 40.0, 3.8, 0.0, 270.0, 30.0, 1.2, 10.0, 2.5, 20.0, 25.0, 0.7, 155.0, 26.0, 0.5),

-- Malvani Mutton Rassa
('malvani_mutton_rassa', 'Malvani Mutton Rassa (Spiced Goat Meat Curry)', 170.0, 15.0, 4.0, 10.5,
 0.8, 1.0, 250, NULL,
 'indian_traditional', ARRAY['malvani mutton rassa', 'malvani mutton', 'malvani goat curry', 'konkan mutton rassa'],
 'indian', NULL, 1, '425 cal per serving (250g). Bone-in goat meat in thin, spiced coconut gravy. Malvani style.', TRUE,
 440.0, 70.0, 3.5, 0.0, 250.0, 18.0, 2.2, 5.0, 1.5, 0.0, 20.0, 3.0, 145.0, 12.0, 0.03),

-- Kombdi Rassa (Malvani chicken rassa)
('kombdi_rassa', 'Kombdi Rassa (Malvani Chicken Rassa)', 140.0, 13.5, 4.0, 7.5,
 0.8, 1.0, 250, NULL,
 'indian_traditional', ARRAY['kombdi rassa', 'malvani kombdi rassa', 'chicken rassa malvani'],
 'indian', NULL, 1, '350 cal per serving (250g). Chicken in thin, spiced red coconut gravy. Classic Malvani rassa-style.', TRUE,
 400.0, 55.0, 2.5, 0.0, 250.0, 22.0, 1.5, 15.0, 2.0, 2.0, 20.0, 1.5, 135.0, 16.0, 0.04),

-- Tisrya Sukka (Dry clams)
('tisrya_sukka', 'Tisrya Sukka (Dry Spiced Clams)', 135.0, 14.0, 5.0, 6.5,
 1.0, 1.0, 150, NULL,
 'indian_traditional', ARRAY['tisrya sukka', 'dry clams malvani', 'clam sukka', 'tisreo sukka'],
 'indian', NULL, 1, '203 cal per serving (150g). Clams dry-roasted with coconut and red chilli masala. Konkan delicacy. Iron-rich.', TRUE,
 450.0, 40.0, 2.5, 0.0, 300.0, 60.0, 5.0, 8.0, 3.0, 0.0, 22.0, 1.8, 170.0, 22.0, 0.2),

-- Malvani Prawn Curry
('malvani_prawn_curry', 'Malvani Prawn Curry (Coconut Prawn Curry)', 120.0, 12.0, 5.0, 5.5,
 0.8, 1.5, 250, NULL,
 'indian_traditional', ARRAY['malvani prawn curry', 'malvani kolambi', 'konkan prawn curry', 'malvani shrimp curry'],
 'indian', NULL, 1, '300 cal per serving (250g). Prawns in Malvani coconut-spice gravy. Lighter than Goan version.', TRUE,
 370.0, 100.0, 3.5, 0.0, 240.0, 45.0, 1.5, 8.0, 2.0, 5.0, 28.0, 1.0, 160.0, 28.0, 0.35),

-- Malvani Egg Curry
('malvani_egg_curry', 'Malvani Egg Curry (Coconut Egg Curry)', 130.0, 8.0, 5.0, 9.0,
 0.8, 1.5, 250, NULL,
 'indian_traditional', ARRAY['malvani egg curry', 'anda curry malvani', 'konkan egg curry', 'malvani egg masala'],
 'indian', NULL, 1, '325 cal per serving (250g). Boiled eggs in Malvani-style coconut-red chilli gravy. Budget protein meal.', TRUE,
 380.0, 160.0, 3.5, 0.0, 180.0, 35.0, 1.5, 65.0, 2.0, 8.0, 15.0, 0.8, 110.0, 12.0, 0.04),

-- Amboli (Fermented rice pancake)
('amboli', 'Amboli (Malvani Fermented Rice Pancake)', 145.0, 3.0, 28.0, 2.0,
 0.8, 0.5, 80, 80,
 'indian_traditional', ARRAY['amboli', 'malvani amboli', 'konkan amboli', 'fermented rice pancake malvani'],
 'indian', NULL, 2, '116 cal per amboli (80g). Thin, fermented rice-urad dal pancake. Like a Malvani dosa. Served with fish curry.', TRUE,
 120.0, 0.0, 0.3, 0.0, 60.0, 12.0, 0.5, 0.0, 0.0, 0.0, 12.0, 0.4, 40.0, 3.0, 0.0),

-- ==========================================
-- COMMON INDIAN PANTRY & BASE ITEMS (~25 items)
-- ==========================================

-- Mixed Vegetable Pickle
('mixed_vegetable_pickle', 'Mixed Vegetable Pickle (Indian Achaar)', 180.0, 2.0, 12.0, 14.0,
 2.5, 5.0, 20, NULL,
 'indian_traditional', ARRAY['mixed pickle', 'mixed vegetable pickle', 'mixed achaar', 'sabzi ka achaar'],
 'indian', NULL, 1, '36 cal per tbsp (20g). Cauliflower, carrot, lime, mango in mustard oil with spices. High sodium.', TRUE,
 3500.0, 0.0, 1.8, 0.0, 130.0, 20.0, 1.5, 15.0, 5.0, 0.0, 10.0, 0.3, 18.0, 0.5, 0.0),

-- Garlic Pickle
('garlic_pickle', 'Garlic Pickle (Lahsun ka Achaar)', 195.0, 3.0, 15.0, 14.0,
 1.5, 2.0, 15, NULL,
 'indian_traditional', ARRAY['garlic pickle', 'lahsun ka achaar', 'lehsun achaar', 'garlic achaar'],
 'indian', NULL, 1, '29 cal per tbsp (15g). Whole garlic cloves in mustard oil with red chilli. Pungent, medicinal.', TRUE,
 3000.0, 0.0, 1.8, 0.0, 200.0, 30.0, 1.0, 0.0, 5.0, 0.0, 12.0, 0.5, 25.0, 3.0, 0.0),

-- Red Chilli Pickle
('red_chilli_pickle', 'Mirchi ka Achaar (Red Chilli Pickle)', 170.0, 2.0, 8.0, 14.5,
 3.0, 3.0, 15, NULL,
 'indian_traditional', ARRAY['mirchi ka achaar', 'red chilli pickle', 'chilli pickle', 'hari mirch achaar', 'lal mirch achaar'],
 'indian', NULL, 1, '26 cal per tbsp (15g). Stuffed green/red chillies in mustard oil. Very hot. Rich in vitamin C.', TRUE,
 2800.0, 0.0, 1.8, 0.0, 250.0, 15.0, 1.2, 40.0, 60.0, 0.0, 15.0, 0.3, 20.0, 0.5, 0.0),

-- Tamarind Chutney (Imli ki chutney)
('tamarind_chutney', 'Tamarind Chutney (Imli ki Chutney)', 180.0, 1.0, 42.0, 0.5,
 1.5, 35.0, 30, NULL,
 'indian_traditional', ARRAY['tamarind chutney', 'imli ki chutney', 'meethi chutney', 'saunth chutney', 'khajur imli chutney'],
 'indian', NULL, 1, '54 cal per tbsp (30g). Tamarind-date-jaggery sweet chutney. Essential for chaat. High sugar.', TRUE,
 250.0, 0.0, 0.1, 0.0, 280.0, 20.0, 1.5, 2.0, 2.0, 0.0, 15.0, 0.2, 25.0, 0.5, 0.0),

-- Green Chutney (Hari chutney)
('green_chutney', 'Green Chutney (Hari Chutney / Mint-Coriander)', 68.0, 3.0, 8.0, 2.5,
 3.0, 2.0, 30, NULL,
 'indian_traditional', ARRAY['green chutney', 'hari chutney', 'mint coriander chutney', 'pudina chutney', 'dhaniya chutney'],
 'indian', NULL, 1, '20 cal per tbsp (30g). Fresh coriander, mint, green chilli, lemon. Low calorie, vitamin-rich. Essential condiment.', TRUE,
 280.0, 0.0, 0.3, 0.0, 250.0, 85.0, 1.8, 120.0, 18.0, 0.0, 20.0, 0.4, 30.0, 1.0, 0.02),

-- Peanut Chutney
('peanut_chutney', 'Peanut Chutney (Shengdana Chutney)', 280.0, 12.0, 12.0, 22.0,
 3.0, 3.0, 30, NULL,
 'indian_traditional', ARRAY['peanut chutney', 'shengdana chutney', 'groundnut chutney', 'peanut chutney dry'],
 'indian', NULL, 1, '84 cal per tbsp (30g). Roasted peanuts ground with garlic, chilli, tamarind. Maharashtra/Karnataka staple. Protein-rich.', TRUE,
 350.0, 0.0, 3.5, 0.0, 350.0, 30.0, 1.5, 0.0, 2.0, 0.0, 60.0, 1.5, 150.0, 4.0, 0.01),

-- Tomato Chutney
('tomato_chutney', 'Tomato Chutney (Tamatar ki Chutney)', 85.0, 1.5, 12.0, 3.5,
 1.5, 7.0, 30, NULL,
 'indian_traditional', ARRAY['tomato chutney', 'tamatar ki chutney', 'tomato pachadi', 'onion tomato chutney'],
 'indian', NULL, 1, '26 cal per tbsp (30g). Cooked tomatoes with tempering of mustard, curry leaves, red chilli. South/West Indian.', TRUE,
 280.0, 0.0, 0.5, 0.0, 220.0, 12.0, 0.5, 30.0, 12.0, 0.0, 10.0, 0.2, 20.0, 0.5, 0.0),

-- Onion Chutney
('onion_chutney', 'Onion Chutney (Kanda Chutney)', 110.0, 2.0, 14.0, 5.0,
 2.0, 6.0, 30, NULL,
 'indian_traditional', ARRAY['onion chutney', 'kanda chutney', 'pyaaz ki chutney', 'red onion chutney'],
 'indian', NULL, 1, '33 cal per tbsp (30g). Red onion with coconut, red chilli, tamarind. Maharashtra dosa accompaniment.', TRUE,
 300.0, 0.0, 0.8, 0.0, 150.0, 15.0, 0.5, 5.0, 5.0, 0.0, 8.0, 0.2, 18.0, 0.5, 0.0),

-- Papad (Roasted)
('papad_roasted', 'Papad (Roasted)', 340.0, 22.0, 52.0, 3.0,
 15.0, 0.5, 15, 15,
 'indian_traditional', ARRAY['roasted papad', 'papad roasted', 'appalam roasted', 'papadum roasted'],
 'indian', NULL, 2, '51 cal per papad (15g). Dry-roasted lentil wafer. High protein, high fiber. Low fat when not fried.', TRUE,
 1800.0, 0.0, 0.5, 0.0, 500.0, 50.0, 3.0, 2.0, 0.0, 0.0, 60.0, 1.5, 180.0, 5.0, 0.0),

-- Papad (Fried)
('papad_fried', 'Papad (Deep-Fried)', 430.0, 18.0, 42.0, 22.0,
 12.0, 0.5, 18, 18,
 'indian_traditional', ARRAY['fried papad', 'papad fried', 'appalam fried', 'papadum fried', 'deep fried papad'],
 'indian', NULL, 2, '77 cal per papad (18g). Deep-fried lentil wafer. Crispy but significantly higher in fat than roasted.', TRUE,
 1600.0, 0.0, 3.0, 0.1, 400.0, 40.0, 2.5, 2.0, 0.0, 0.0, 50.0, 1.2, 150.0, 4.0, 0.0),

-- Ghee (Clarified Butter)
('ghee', 'Ghee (Clarified Butter)', 900.0, 0.0, 0.0, 100.0,
 0.0, 0.0, 14, NULL,
 'indian_traditional', ARRAY['ghee', 'clarified butter', 'desi ghee', 'cow ghee', 'ghi'],
 'indian', NULL, 1, '126 cal per tbsp (14g). Pure milk fat. Rich in fat-soluble vitamins A, D, E, K. Smoke point 250C.', TRUE,
 0.0, 256.0, 62.0, 0.0, 5.0, 4.0, 0.0, 375.0, 0.0, 5.3, 0.0, 0.0, 3.0, 0.0, 0.3),

-- Dahi (Plain Curd/Yogurt)
('dahi', 'Dahi (Plain Yogurt/Curd)', 60.0, 3.5, 4.7, 3.3,
 0.0, 4.7, 150, NULL,
 'indian_traditional', ARRAY['dahi', 'curd', 'plain yogurt indian', 'homemade curd', 'doi'],
 'indian', NULL, 1, '90 cal per katori (150g). Homeset whole milk yogurt. Probiotic-rich. Served with every Indian meal.', TRUE,
 40.0, 12.0, 2.0, 0.0, 155.0, 120.0, 0.1, 28.0, 0.5, 2.0, 12.0, 0.5, 95.0, 3.0, 0.01),

-- Buttermilk (Chaas/Mattha)
('chaas', 'Chaas / Mattha (Spiced Buttermilk)', 28.0, 1.5, 2.5, 1.2,
 0.0, 2.0, 250, NULL,
 'indian_traditional', ARRAY['chaas', 'mattha', 'buttermilk', 'chhaach', 'tak', 'majjige', 'spiced buttermilk'],
 'indian', NULL, 1, '70 cal per glass (250ml). Diluted yogurt with cumin, coriander, salt. Cooling digestive drink.', TRUE,
 200.0, 5.0, 0.8, 0.0, 100.0, 55.0, 0.1, 8.0, 0.5, 0.5, 8.0, 0.2, 45.0, 1.5, 0.01),

-- Sweet Lassi
('sweet_lassi', 'Sweet Lassi (Sweetened Yogurt Drink)', 80.0, 2.5, 13.0, 2.0,
 0.0, 12.0, 250, NULL,
 'indian_traditional', ARRAY['sweet lassi', 'meethi lassi', 'punjabi lassi sweet', 'mango lassi', 'lassi meethi'],
 'indian', NULL, 1, '200 cal per glass (250ml). Blended yogurt with sugar/fruit. Thick, creamy. Punjabi classic.', TRUE,
 35.0, 8.0, 1.2, 0.0, 130.0, 80.0, 0.1, 15.0, 1.0, 1.0, 10.0, 0.3, 70.0, 2.0, 0.01),

-- Salt Lassi
('salt_lassi', 'Salt Lassi (Salted Yogurt Drink)', 45.0, 2.5, 4.0, 2.0,
 0.0, 3.5, 250, NULL,
 'indian_traditional', ARRAY['salt lassi', 'namkeen lassi', 'salted lassi', 'lassi namkeen'],
 'indian', NULL, 1, '113 cal per glass (250ml). Blended yogurt with salt and roasted cumin. Refreshing, lower calorie than sweet.', TRUE,
 280.0, 8.0, 1.2, 0.0, 130.0, 75.0, 0.1, 12.0, 0.5, 1.0, 10.0, 0.3, 65.0, 2.0, 0.01),

-- Khichdi (Plain moong dal)
('khichdi', 'Khichdi (Plain Moong Dal Rice)', 125.0, 5.0, 20.0, 2.5,
 1.5, 0.5, 250, NULL,
 'indian_traditional', ARRAY['khichdi', 'khichri', 'moong dal khichdi', 'dal khichdi', 'plain khichdi'],
 'indian', NULL, 1, '313 cal per serving (250g). Rice and moong dal cooked soft with turmeric and ghee. Indian comfort/healing food.', TRUE,
 250.0, 3.0, 0.8, 0.0, 150.0, 18.0, 0.8, 3.0, 0.5, 0.0, 20.0, 0.6, 65.0, 5.0, 0.01),

-- Upma
('upma', 'Upma (Semolina Breakfast Dish)', 130.0, 3.5, 18.0, 5.0,
 1.2, 1.0, 200, NULL,
 'indian_traditional', ARRAY['upma', 'uppuma', 'rava upma', 'sooji upma', 'semolina upma'],
 'indian', NULL, 1, '260 cal per serving (200g). Roasted semolina cooked with vegetables, mustard, curry leaves. South/West Indian breakfast.', TRUE,
 320.0, 0.0, 0.8, 0.0, 100.0, 15.0, 0.8, 10.0, 3.0, 0.0, 15.0, 0.5, 50.0, 8.0, 0.0),

-- Sheera / Sooji Halwa
('sheera', 'Sheera / Sooji Halwa (Semolina Pudding)', 280.0, 3.5, 38.0, 13.0,
 0.5, 22.0, 100, NULL,
 'indian_traditional', ARRAY['sheera', 'sooji halwa', 'suji ka halwa', 'rava sheera', 'semolina halwa'],
 'indian', NULL, 1, '280 cal per serving (100g). Semolina roasted in ghee with sugar, milk, nuts. Offered as prasad. Rich.', TRUE,
 30.0, 25.0, 6.0, 0.0, 60.0, 25.0, 0.5, 30.0, 0.0, 2.0, 10.0, 0.3, 40.0, 5.0, 0.01),

-- Besan Ladoo
('besan_ladoo', 'Besan Ladoo (Gram Flour Sweet Ball)', 450.0, 8.0, 48.0, 25.0,
 2.5, 30.0, 40, 40,
 'indian_traditional', ARRAY['besan ladoo', 'besan laddoo', 'besan laddu', 'gram flour ladoo', 'besan ke ladoo'],
 'indian', NULL, 2, '180 cal per ladoo (40g). Roasted besan with ghee, sugar, cardamom. Festival sweet. Calorie-dense.', TRUE,
 15.0, 20.0, 12.0, 0.0, 150.0, 20.0, 2.0, 25.0, 0.0, 1.0, 30.0, 0.8, 80.0, 4.0, 0.0),

-- Gajar ka Halwa
('gajar_ka_halwa', 'Gajar ka Halwa (Carrot Pudding)', 250.0, 4.0, 30.0, 13.0,
 2.0, 22.0, 120, NULL,
 'indian_traditional', ARRAY['gajar ka halwa', 'carrot halwa', 'gajar halwa', 'gajrela'],
 'indian', NULL, 1, '300 cal per serving (120g). Grated carrots slow-cooked in milk, ghee, sugar with nuts. Winter special.', TRUE,
 40.0, 20.0, 6.0, 0.0, 180.0, 60.0, 0.5, 400.0, 3.0, 3.0, 12.0, 0.4, 55.0, 2.0, 0.01),

-- Moong Dal Halwa
('moong_dal_halwa', 'Moong Dal Halwa (Split Green Gram Pudding)', 380.0, 7.0, 40.0, 22.0,
 1.5, 28.0, 80, NULL,
 'indian_traditional', ARRAY['moong dal halwa', 'moong dal ka halwa', 'green gram halwa'],
 'indian', NULL, 1, '304 cal per serving (80g). Slow-cooked moong dal with ghee, sugar, milk. Rich, warming. Rajasthani/North Indian.', TRUE,
 20.0, 30.0, 10.0, 0.0, 180.0, 35.0, 1.5, 25.0, 0.5, 2.0, 25.0, 0.8, 90.0, 4.0, 0.01),

-- Masala Chai
('masala_chai', 'Masala Chai (Spiced Milk Tea)', 45.0, 1.5, 6.5, 1.5,
 0.0, 5.5, 150, NULL,
 'indian_traditional', ARRAY['masala chai', 'chai', 'masala tea', 'Indian tea', 'spiced tea', 'cutting chai'],
 'indian', NULL, 1, '68 cal per cup (150ml). Black tea with milk, sugar, ginger, cardamom, cinnamon. India''s national drink.', TRUE,
 25.0, 5.0, 0.8, 0.0, 80.0, 50.0, 0.2, 12.0, 0.0, 0.5, 5.0, 0.1, 35.0, 0.5, 0.0),

-- Filter Coffee (South Indian)
('filter_coffee', 'Filter Coffee (South Indian)', 55.0, 1.8, 7.0, 2.2,
 0.0, 6.0, 150, NULL,
 'indian_traditional', ARRAY['filter coffee', 'south indian filter coffee', 'filter kaapi', 'madras coffee', 'mylapore coffee'],
 'indian', NULL, 1, '83 cal per tumbler (150ml). Decoction brewed in brass filter, mixed with hot milk and sugar. Strong, frothy.', TRUE,
 25.0, 8.0, 1.2, 0.0, 100.0, 55.0, 0.1, 12.0, 0.0, 0.5, 8.0, 0.2, 40.0, 0.5, 0.0),

-- Badam Milk
('badam_milk', 'Badam Milk (Indian Almond Milk Drink)', 95.0, 4.0, 12.0, 3.5,
 0.5, 10.0, 200, NULL,
 'indian_traditional', ARRAY['badam milk', 'badam doodh', 'almond milk indian', 'kesar badam milk'],
 'indian', NULL, 1, '190 cal per glass (200ml). Hot milk with soaked almonds, saffron, sugar, cardamom. Nutritious bedtime drink.', TRUE,
 40.0, 10.0, 1.5, 0.0, 170.0, 100.0, 0.5, 20.0, 0.5, 5.0, 20.0, 0.5, 80.0, 2.0, 0.02),

-- Haldi Doodh (Turmeric Milk/Golden Milk)
('haldi_doodh', 'Haldi Doodh (Turmeric Milk / Golden Milk)', 70.0, 3.0, 6.0, 3.5,
 0.0, 5.0, 200, NULL,
 'indian_traditional', ARRAY['haldi doodh', 'turmeric milk', 'golden milk', 'haldi wala doodh', 'turmeric latte'],
 'indian', NULL, 1, '140 cal per glass (200ml). Hot milk with turmeric, pepper, ghee. Anti-inflammatory. Ayurvedic remedy.', TRUE,
 40.0, 12.0, 2.0, 0.0, 155.0, 120.0, 0.2, 28.0, 0.5, 3.0, 12.0, 0.5, 95.0, 3.0, 0.01),

-- Jaljeera
('jaljeera', 'Jaljeera (Spiced Cumin Water)', 20.0, 0.3, 5.0, 0.1,
 0.3, 3.0, 250, NULL,
 'indian_traditional', ARRAY['jaljeera', 'jal jeera', 'jaljira', 'cumin water drink', 'jaljeera masala drink'],
 'indian', NULL, 1, '50 cal per glass (250ml). Cumin, mint, black salt, lemon in water. Digestive street drink. Very low calorie.', TRUE,
 600.0, 0.0, 0.0, 0.0, 80.0, 15.0, 0.5, 5.0, 5.0, 0.0, 8.0, 0.2, 10.0, 0.3, 0.0),

-- Aam Panna
('aam_panna', 'Aam Panna (Raw Mango Cooler)', 50.0, 0.3, 12.0, 0.1,
 0.5, 10.0, 250, NULL,
 'indian_traditional', ARRAY['aam panna', 'kairi panna', 'raw mango drink', 'kachche aam ka panna'],
 'indian', NULL, 1, '125 cal per glass (250ml). Boiled raw mango puree with sugar, cumin, mint. Summer heatstroke preventive.', TRUE,
 350.0, 0.0, 0.0, 0.0, 120.0, 8.0, 0.3, 15.0, 10.0, 0.0, 5.0, 0.1, 8.0, 0.2, 0.0),

-- Thandai
('thandai', 'Thandai (Spiced Nut Milk Drink)', 110.0, 3.5, 14.0, 5.0,
 0.5, 12.0, 200, NULL,
 'indian_traditional', ARRAY['thandai', 'sardai', 'thandai drink', 'holi special drink'],
 'indian', NULL, 1, '220 cal per glass (200ml). Cold milk with almonds, fennel, poppy seeds, rose, saffron, sugar. Holi special.', TRUE,
 30.0, 10.0, 2.0, 0.0, 160.0, 90.0, 0.5, 15.0, 0.5, 3.0, 22.0, 0.5, 75.0, 2.0, 0.03),

-- Rooh Afza (Concentrate)
('rooh_afza', 'Rooh Afza (Rose Syrup Concentrate)', 300.0, 0.0, 75.0, 0.0,
 0.0, 72.0, 25, NULL,
 'indian_traditional', ARRAY['rooh afza', 'roohafza', 'rose syrup', 'rooh afza sharbat'],
 'indian', NULL, 1, '75 cal per tbsp (25ml). Rose-flavored herbal syrup. Mix with water or milk. Very high sugar concentrate.', TRUE,
 15.0, 0.0, 0.0, 0.0, 20.0, 5.0, 0.2, 0.0, 0.0, 0.0, 2.0, 0.0, 3.0, 0.0, 0.0),

-- Nimbu Pani (Lime water)
('nimbu_pani', 'Nimbu Pani (Indian Lemonade)', 30.0, 0.1, 7.5, 0.0,
 0.1, 6.5, 250, NULL,
 'indian_traditional', ARRAY['nimbu pani', 'nimbu paani', 'lime water', 'shikanji', 'lemon water indian'],
 'indian', NULL, 1, '75 cal per glass (250ml). Fresh lime, sugar, black salt, cumin in water. Classic Indian refresher.', TRUE,
 350.0, 0.0, 0.0, 0.0, 40.0, 5.0, 0.1, 0.0, 8.0, 0.0, 3.0, 0.0, 5.0, 0.1, 0.0)

ON CONFLICT (food_name_normalized) DO NOTHING;
