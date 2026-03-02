-- 1002_indian_east_northeast.sql
-- Traditional East & Northeast Indian foods (Bengal, Odisha, Bihar, Jharkhand, Assam, Manipur, Meghalaya, Nagaland, Mizoram, Tripura, Sikkim, Arunachal)
-- All values per 100g. Sources: IFCT 2017, USDA, nutritionix

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
-- BENGALI FISH DISHES (~9 items)
-- =====================================================================

('maacher_jhol', 'Maacher Jhol (Bengali Fish Curry)', 95.0, 12.3, 3.5, 3.8, 0.5, 0.8, 250, NULL, 'indian_traditional', ARRAY['macher jhol', 'machher jhol', 'bengali fish curry', 'fish jhol', 'rui macher jhol'], 'indian', NULL, 1, 'Light Bengali fish curry with turmeric and cumin. ~238 cal per serving (250g).', true, 180, 45, 0.8, 0.0, 280, 35, 1.2, 15, 3.0, 40, 28, 0.6, 185, 22.0, 0.15),

('shorshe_ilish', 'Shorshe Ilish (Hilsa in Mustard)', 185.0, 17.0, 2.5, 12.0, 0.6, 0.4, 200, NULL, 'indian_traditional', ARRAY['sorshe ilish', 'ilish shorshe', 'hilsa mustard curry', 'shorshe ilish bhapa', 'mustard hilsa'], 'indian', NULL, 1, 'Hilsa fish steamed/cooked in mustard paste. Rich in omega-3. ~370 cal per serving (200g).', true, 220, 60, 2.8, 0.0, 310, 50, 1.8, 25, 1.5, 120, 35, 1.2, 260, 36.0, 1.80),

('doi_maach', 'Doi Maach (Fish in Yogurt Curry)', 110.0, 13.5, 4.0, 4.5, 0.3, 2.5, 250, NULL, 'indian_traditional', ARRAY['dahi maach', 'yogurt fish curry', 'fish in curd', 'doi mach bengali', 'curd fish curry'], 'indian', NULL, 1, 'Fish cooked in creamy yogurt gravy. ~275 cal per serving (250g).', true, 195, 50, 1.5, 0.0, 260, 65, 1.0, 18, 1.0, 35, 25, 0.7, 195, 24.0, 0.12),

('chingri_malaikari', 'Chingri Malaikari (Prawn Malai Curry)', 155.0, 14.5, 5.0, 9.0, 0.8, 2.0, 250, NULL, 'indian_traditional', ARRAY['chingri malai curry', 'prawn malai curry', 'coconut prawn curry bengali', 'shrimp malaikari', 'golda chingri malaikari'], 'indian', NULL, 1, 'Prawns in coconut milk based creamy curry. ~388 cal per serving (250g).', true, 310, 120, 5.5, 0.0, 320, 55, 1.5, 20, 3.5, 25, 38, 1.4, 225, 30.0, 0.25),

('pabda_fish_curry', 'Pabda Fish Curry (Butter Catfish Curry)', 88.0, 11.5, 3.0, 3.5, 0.4, 0.6, 250, NULL, 'indian_traditional', ARRAY['pabda maacher jhol', 'pabda mach curry', 'butter catfish bengali', 'pabda jhol'], 'indian', NULL, 1, 'Delicate Bengali curry with pabda (butter catfish). ~220 cal per serving (250g).', true, 165, 40, 0.7, 0.0, 260, 80, 1.0, 12, 2.5, 30, 26, 0.5, 175, 20.0, 0.10),

('rui_maacher_kalia', 'Rui Maacher Kalia (Rohu Fish Kalia)', 120.0, 13.0, 4.5, 5.5, 0.5, 1.0, 250, NULL, 'indian_traditional', ARRAY['rui kalia', 'rohu fish kalia', 'maacher kalia', 'rui macher kalia', 'fish kalia bengali'], 'indian', NULL, 1, 'Rich Bengali fish curry with onion-tomato gravy. ~300 cal per serving (250g).', true, 210, 48, 1.2, 0.0, 290, 40, 1.3, 20, 4.0, 35, 30, 0.7, 200, 23.0, 0.08),

('tel_koi', 'Tel Koi (Climbing Perch in Mustard Oil)', 130.0, 14.0, 2.0, 7.5, 0.3, 0.5, 200, NULL, 'indian_traditional', ARRAY['tel koi mach', 'koi macher tel jhal', 'climbing perch curry', 'koi fish bengali'], 'indian', NULL, 1, 'Koi fish shallow fried and simmered in mustard oil. ~260 cal per serving (200g).', true, 190, 55, 1.5, 0.0, 250, 90, 1.5, 15, 1.0, 30, 28, 0.8, 210, 25.0, 0.12),

('maacher_kalia', 'Maacher Kalia (Bengali Fish Kalia)', 125.0, 12.5, 5.0, 6.0, 0.5, 1.2, 250, NULL, 'indian_traditional', ARRAY['macher kalia', 'fish kalia', 'bengali fish kalia', 'kalia curry'], 'indian', NULL, 1, 'Rich aromatic fish curry with potatoes and spices. ~313 cal per serving (250g).', true, 215, 45, 1.3, 0.0, 300, 38, 1.2, 18, 5.0, 35, 28, 0.6, 195, 22.0, 0.10),

('bengali_fish_fry', 'Bengali Fish Fry (Macher Fry)', 175.0, 16.0, 8.0, 9.0, 0.5, 0.5, 150, 80, 'indian_traditional', ARRAY['macher fry', 'fish fry bengali style', 'kolkata fish fry', 'bhetki fry', 'rui fry'], 'indian', NULL, 1, 'Marinated fish coated in breadcrumbs and shallow fried. ~140 cal per piece (80g).', true, 350, 55, 2.0, 0.1, 240, 30, 1.4, 12, 1.0, 30, 25, 0.8, 190, 24.0, 0.08),

-- =====================================================================
-- BENGALI MEAT DISHES (~4 items)
-- =====================================================================

('kosha_mangsho', 'Kosha Mangsho (Bengali Mutton Curry)', 195.0, 18.0, 5.0, 11.5, 0.6, 1.0, 250, NULL, 'indian_traditional', ARRAY['kosha mangsho bengali', 'mutton kosha', 'bengali goat curry', 'mangshor jhol', 'spicy mutton curry bengali'], 'indian', NULL, 1, 'Slow-cooked dry mutton curry with rich spices. ~488 cal per serving (250g).', true, 280, 75, 4.5, 0.1, 310, 22, 2.8, 8, 2.0, 5, 24, 4.2, 180, 18.0, 0.05),

('chicken_kosha', 'Chicken Kosha (Bengali Chicken Curry)', 165.0, 17.5, 4.5, 8.5, 0.5, 1.0, 250, NULL, 'indian_traditional', ARRAY['murgi kosha', 'bengali chicken curry', 'kosha murgi', 'chicken kasha bengali', 'dry chicken curry bengali'], 'indian', NULL, 1, 'Bengali dry chicken curry cooked with onions and spices. ~413 cal per serving (250g).', true, 260, 65, 2.5, 0.0, 280, 20, 1.8, 12, 3.0, 5, 22, 1.8, 170, 20.0, 0.04),

('mutton_rezala', 'Mutton Rezala (Bengali White Mutton Curry)', 210.0, 16.0, 6.0, 14.0, 0.4, 1.5, 250, NULL, 'indian_traditional', ARRAY['rezala bengali', 'white mutton curry', 'kolkata rezala', 'mughlai rezala', 'mutton rezala kolkata'], 'indian', NULL, 1, 'Creamy white mutton curry with yogurt, cashew and poppy seeds. ~525 cal per serving (250g).', true, 310, 80, 5.8, 0.1, 290, 45, 2.5, 15, 1.5, 5, 22, 3.8, 175, 16.0, 0.04),

('keema_bengali', 'Keema Bengali Style (Minced Meat Curry)', 175.0, 16.5, 5.5, 10.0, 0.8, 1.2, 200, NULL, 'indian_traditional', ARRAY['bengali keema', 'kosha keema', 'mutton keema bengali', 'mince meat curry bengali'], 'indian', NULL, 1, 'Bengali style spiced minced mutton with peas and potatoes. ~350 cal per serving (200g).', true, 290, 70, 3.8, 0.1, 320, 25, 2.5, 30, 4.0, 5, 22, 3.5, 165, 15.0, 0.04),

-- =====================================================================
-- BENGALI VEG DISHES (~11 items)
-- =====================================================================

('aloo_posto', 'Aloo Posto (Potato in Poppy Seeds)', 125.0, 3.0, 14.0, 6.5, 1.8, 1.0, 200, NULL, 'indian_traditional', ARRAY['alu posto', 'potato poppy seed curry', 'posto aloo', 'bengali aloo posto', 'alu posto bengali'], 'indian', NULL, 1, 'Potatoes cooked in ground poppy seed paste. ~250 cal per serving (200g).', true, 120, 0, 0.8, 0.0, 380, 85, 1.5, 3, 12.0, 0, 35, 1.0, 110, 1.5, 0.02),

('shukto', 'Shukto (Bengali Mixed Veg with Bitter Gourd)', 72.0, 2.5, 8.0, 3.5, 2.5, 2.0, 250, NULL, 'indian_traditional', ARRAY['shukto bengali', 'bengali mixed veg bitter', 'shukto recipe', 'bitter gourd mix veg bengali'], 'indian', NULL, 1, 'Traditional bitter-sweet mixed vegetable dish. ~180 cal per serving (250g).', true, 160, 2, 1.2, 0.0, 340, 55, 1.8, 45, 18.0, 0, 32, 0.5, 75, 1.0, 0.01),

('chorchori', 'Chorchori (Bengali Dry Mixed Vegetables)', 68.0, 2.0, 7.5, 3.5, 2.0, 1.5, 200, NULL, 'indian_traditional', ARRAY['charchari', 'chorchori bengali', 'mixed veg stir fry bengali', 'bengali sabzi'], 'indian', NULL, 1, 'Dry stir-fried mixed vegetables with panch phoron. ~136 cal per serving (200g).', true, 130, 0, 0.5, 0.0, 310, 45, 1.5, 55, 15.0, 0, 28, 0.4, 65, 0.8, 0.01),

('labra', 'Labra (Bengali Mixed Vegetable Curry)', 75.0, 2.5, 9.0, 3.2, 2.2, 2.0, 250, NULL, 'indian_traditional', ARRAY['labra bengali', 'mixed veg curry bengali', 'bengali labra', 'mixed sabzi bengali'], 'indian', NULL, 1, 'Mixed vegetables cooked with panch phoron and coconut. ~188 cal per serving (250g).', true, 140, 0, 0.8, 0.0, 350, 48, 1.6, 60, 12.0, 0, 30, 0.5, 70, 0.9, 0.01),

('begun_bhaja', 'Begun Bhaja (Bengali Fried Eggplant)', 145.0, 1.5, 10.0, 11.5, 2.5, 2.0, 100, 30, 'indian_traditional', ARRAY['baingan bhaja', 'fried brinjal bengali', 'begun bhaja bengali', 'eggplant fry bengali'], 'indian', NULL, 3, 'Thinly sliced eggplant fried in mustard oil. ~44 cal per slice (30g).', true, 85, 0, 1.5, 0.0, 180, 12, 0.8, 5, 2.0, 0, 14, 0.3, 28, 0.5, 0.01),

('aloo_bhaja', 'Aloo Bhaja (Bengali Fried Potato Slices)', 160.0, 2.0, 20.0, 8.5, 1.5, 0.5, 100, NULL, 'indian_traditional', ARRAY['alu bhaja', 'potato fry bengali', 'bengali aloo fry', 'fried potato slices bengali'], 'indian', NULL, 1, 'Thinly sliced potato fried with turmeric and nigella seeds. ~160 cal per serving (100g).', true, 95, 0, 1.0, 0.0, 350, 10, 0.8, 2, 10.0, 0, 22, 0.3, 55, 0.6, 0.01),

('phulkopir_dalna', 'Phulkopir Dalna (Bengali Cauliflower Curry)', 78.0, 2.8, 7.5, 4.2, 2.0, 2.0, 250, NULL, 'indian_traditional', ARRAY['phool kopir dalna', 'cauliflower curry bengali', 'fulkopi dalna', 'bengali gobi curry', 'aloo phulkopi dalna'], 'indian', NULL, 1, 'Cauliflower and potato curry with cumin-based gravy. ~195 cal per serving (250g).', true, 150, 0, 0.6, 0.0, 310, 30, 1.0, 8, 35.0, 0, 18, 0.4, 55, 0.8, 0.01),

('mochar_ghonto', 'Mochar Ghonto (Banana Flower Curry)', 85.0, 3.0, 10.0, 4.0, 3.0, 1.5, 200, NULL, 'indian_traditional', ARRAY['mocha ghonto', 'banana flower bengali', 'kolar mocha ghonto', 'banana blossom curry bengali'], 'indian', NULL, 1, 'Banana flower cooked with coconut and spices. ~170 cal per serving (200g).', true, 140, 0, 0.8, 0.0, 420, 35, 2.0, 10, 8.0, 0, 40, 0.5, 65, 1.0, 0.01),

('echor_ghonto', 'Echor Ghonto (Raw Jackfruit Curry)', 90.0, 2.5, 12.0, 3.8, 2.5, 3.0, 200, NULL, 'indian_traditional', ARRAY['echorer dalna', 'jackfruit curry bengali', 'kathal ghonto', 'raw jackfruit bengali', 'echor dalna'], 'indian', NULL, 1, 'Young jackfruit cooked with spices. ~180 cal per serving (200g).', true, 130, 0, 0.5, 0.0, 380, 30, 1.2, 8, 6.0, 0, 35, 0.4, 55, 0.8, 0.02),

('dharosh_bhaja', 'Dharosh Bhaja (Bengali Okra Fry)', 135.0, 2.5, 10.0, 10.0, 3.0, 1.5, 100, NULL, 'indian_traditional', ARRAY['bhindi bhaja', 'okra fry bengali', 'dherosh bhaja', 'ladies finger fry bengali'], 'indian', NULL, 1, 'Okra sliced and fried in mustard oil. ~135 cal per serving (100g).', true, 90, 0, 1.2, 0.0, 250, 75, 1.0, 35, 15.0, 0, 50, 0.6, 55, 0.5, 0.01),

('potol_dolma', 'Potol Dolma (Stuffed Pointed Gourd)', 95.0, 4.5, 8.0, 5.0, 1.8, 2.0, 200, 40, 'indian_traditional', ARRAY['potoler dolma', 'stuffed parwal bengali', 'pointed gourd stuffed', 'potol dorma', 'bharwa parwal bengali'], 'indian', NULL, 4, 'Pointed gourd stuffed with spiced cottage cheese or fish. ~38 cal per piece (40g).', true, 160, 10, 1.5, 0.0, 280, 50, 1.2, 20, 8.0, 0, 22, 0.5, 80, 1.2, 0.01),

-- =====================================================================
-- BENGALI DAL (~4 items)
-- =====================================================================

('moong_dal_bengali', 'Moong Dal (Bengali Style)', 105.0, 7.0, 15.0, 2.5, 3.0, 0.8, 200, NULL, 'indian_traditional', ARRAY['mung dal bengali', 'moong dal tadka bengali', 'bengali moong dal', 'sona moong dal'], 'indian', NULL, 1, 'Yellow moong dal tempered with panch phoron. ~210 cal per serving (200g).', true, 140, 0, 0.4, 0.0, 320, 30, 2.0, 5, 1.5, 0, 40, 1.0, 120, 3.0, 0.01),

('masoor_dal_bengali', 'Masoor Dal (Bengali Red Lentil)', 108.0, 7.5, 15.5, 2.2, 2.8, 0.8, 200, NULL, 'indian_traditional', ARRAY['musur dal bengali', 'red lentil dal bengali', 'bengali masoor dal', 'musur dal'], 'indian', NULL, 1, 'Bengali red lentil dal with tomato and cumin. ~216 cal per serving (200g).', true, 135, 0, 0.3, 0.0, 310, 25, 2.5, 8, 2.0, 0, 35, 1.2, 130, 2.5, 0.01),

('cholar_dal', 'Cholar Dal (Bengal Gram Dal Bengali)', 130.0, 7.5, 18.0, 3.5, 4.0, 3.0, 200, NULL, 'indian_traditional', ARRAY['chana dal bengali', 'bengali cholar dal', 'cholar dal narkel diye', 'chana dal with coconut'], 'indian', NULL, 1, 'Chana dal cooked with coconut and raisins. ~260 cal per serving (200g).', true, 125, 0, 1.2, 0.0, 340, 35, 2.2, 5, 1.0, 0, 42, 1.5, 140, 3.5, 0.01),

('musur_dal_bengali', 'Musur Dal (Bengali Lentil Soup)', 100.0, 7.0, 14.0, 2.0, 2.5, 0.6, 200, NULL, 'indian_traditional', ARRAY['musoor dal bengali', 'bengali lentil soup', 'musur daal', 'thin masoor dal'], 'indian', NULL, 1, 'Light Bengali lentil soup with minimal tempering. ~200 cal per serving (200g).', true, 130, 0, 0.3, 0.0, 300, 22, 2.3, 5, 1.5, 0, 32, 1.0, 125, 2.5, 0.01),

-- =====================================================================
-- BENGALI RICE & BREAD (~4 items)
-- =====================================================================

('gobindobhog_rice', 'Gobindobhog Rice (Aromatic Bengali Rice)', 140.0, 2.8, 31.0, 0.3, 0.4, 0.1, 200, NULL, 'indian_traditional', ARRAY['gobindobhog chal', 'bengali fragrant rice', 'puja rice', 'gobindobhog bhat'], 'indian', NULL, 1, 'Short-grain aromatic Bengali rice. ~280 cal per serving (200g cooked).', true, 5, 0, 0.1, 0.0, 50, 12, 0.5, 0, 0.0, 0, 15, 0.5, 50, 8.0, 0.01),

('ghee_bhat', 'Ghee Bhat (Rice with Ghee)', 175.0, 2.8, 28.0, 6.0, 0.3, 0.1, 200, NULL, 'indian_traditional', ARRAY['ghee rice bengali', 'rice with ghee', 'bhat ghee', 'bengali ghee rice'], 'indian', NULL, 1, 'Steamed rice mixed with ghee and salt. ~350 cal per serving (200g).', true, 15, 15, 3.5, 0.0, 55, 15, 0.5, 35, 0.0, 2, 15, 0.5, 52, 8.0, 0.01),

('khichuri_bengali', 'Khichuri (Bengali Khichdi)', 115.0, 4.5, 18.0, 3.0, 1.8, 0.5, 250, NULL, 'indian_traditional', ARRAY['bengali khichdi', 'khichuri', 'bhuni khichuri', 'niramish khichuri', 'bhoger khichuri'], 'indian', NULL, 1, 'Bengali rice and lentil comfort food with vegetables. ~288 cal per serving (250g).', true, 180, 5, 1.2, 0.0, 210, 25, 1.5, 15, 5.0, 2, 28, 0.8, 95, 5.0, 0.01),

('luchi', 'Luchi (Bengali Deep Fried Bread)', 320.0, 6.0, 42.0, 14.5, 1.2, 1.0, 60, 20, 'indian_traditional', ARRAY['luchi bengali', 'bengali poori', 'maida luchi', 'deep fried bengali bread', 'radhaballabhi'], 'indian', NULL, 3, 'Deep fried puffed bread made from maida. ~64 cal per piece (20g).', true, 250, 0, 2.0, 0.1, 65, 15, 1.0, 0, 0.0, 0, 10, 0.4, 40, 5.0, 0.01),

-- =====================================================================
-- BENGALI SWEETS (~9 items)
-- =====================================================================

('rasgulla', 'Rasgulla (Bengali Cottage Cheese Balls)', 124.0, 5.0, 22.0, 1.8, 0.0, 20.0, 100, 40, 'indian_traditional', ARRAY['rosogolla', 'rasgulla bengali', 'sponge rasgulla', 'chhena rasgulla', 'rosogolla kolkata'], 'indian', NULL, 2, 'Spongy chhena balls in sugar syrup. ~50 cal per piece (40g).', true, 25, 5, 1.0, 0.0, 45, 67, 0.3, 10, 0.0, 2, 8, 0.4, 55, 2.0, 0.01),

('sandesh', 'Sandesh (Bengali Cottage Cheese Sweet)', 155.0, 8.0, 18.0, 6.0, 0.0, 16.0, 60, 30, 'indian_traditional', ARRAY['sondesh', 'nolen gurer sandesh', 'kacha golla', 'narkol sandesh', 'bengali sandesh'], 'indian', NULL, 2, 'Moulded sweet made from fresh chhena. ~47 cal per piece (30g).', true, 30, 12, 3.5, 0.0, 80, 90, 0.5, 25, 0.0, 3, 10, 0.5, 95, 3.0, 0.01),

('mishti_doi', 'Mishti Doi (Bengali Sweet Yogurt)', 176.0, 4.5, 26.0, 6.0, 0.0, 24.0, 120, NULL, 'indian_traditional', ARRAY['mishti dahi', 'sweet curd bengali', 'bengali sweet yogurt', 'lal doi', 'nolen gurer mishti doi'], 'indian', NULL, 1, 'Caramelized sweetened set yogurt. ~211 cal per serving (120g).', true, 50, 18, 3.8, 0.0, 180, 140, 0.2, 30, 0.5, 4, 12, 0.5, 100, 3.0, 0.01),

('pantua', 'Pantua (Bengali Fried Sweet Balls)', 310.0, 5.5, 42.0, 14.0, 0.2, 35.0, 80, 40, 'indian_traditional', ARRAY['bengali gulab jamun', 'pantua bengali', 'ledikeni', 'chhena pantua'], 'indian', NULL, 2, 'Deep fried chhena balls soaked in sugar syrup. ~124 cal per piece (40g).', true, 35, 15, 5.0, 0.1, 65, 55, 0.5, 15, 0.0, 2, 10, 0.4, 65, 2.0, 0.01),

('cham_cham', 'Cham Cham (Bengali Oval Sweet)', 280.0, 6.0, 40.0, 11.0, 0.0, 35.0, 80, 40, 'indian_traditional', ARRAY['chum chum', 'chomchom', 'cham cham bengali', 'chom chom sweet'], 'indian', NULL, 2, 'Oval shaped chhena sweet in syrup, often coated with mawa. ~112 cal per piece (40g).', true, 30, 12, 5.5, 0.0, 70, 65, 0.4, 18, 0.0, 2, 9, 0.4, 70, 2.5, 0.01),

('nolen_gurer_sandesh', 'Nolen Gurer Sandesh (Date Palm Jaggery Sweet)', 165.0, 7.5, 22.0, 5.5, 0.1, 19.0, 60, 30, 'indian_traditional', ARRAY['nolen gur sandesh', 'patali gurer sandesh', 'date palm jaggery sandesh', 'notun gurer sandesh'], 'indian', NULL, 2, 'Winter specialty sandesh with date palm jaggery. ~50 cal per piece (30g).', true, 28, 10, 3.2, 0.0, 120, 85, 0.8, 22, 0.0, 3, 14, 0.5, 90, 3.0, 0.01),

('rosogolla', 'Rosogolla (Sponge Rasgulla)', 124.0, 5.0, 22.0, 1.8, 0.0, 20.0, 100, 40, 'indian_traditional', ARRAY['rasagola', 'sponge rosogolla', 'bengali rasgulla', 'white rosogolla'], 'indian', NULL, 2, 'Soft spongy cottage cheese balls in light syrup. ~50 cal per piece (40g).', true, 25, 5, 1.0, 0.0, 45, 67, 0.3, 10, 0.0, 2, 8, 0.4, 55, 2.0, 0.01),

('payesh', 'Payesh (Bengali Rice Kheer)', 145.0, 4.5, 20.0, 5.5, 0.2, 14.0, 150, NULL, 'indian_traditional', ARRAY['chaler payesh', 'bengali kheer', 'rice pudding bengali', 'nolen gurer payesh', 'doodh payesh'], 'indian', NULL, 1, 'Bengali rice pudding cooked in sweetened milk. ~218 cal per serving (150g).', true, 45, 15, 3.2, 0.0, 170, 125, 0.3, 40, 1.0, 8, 14, 0.5, 100, 3.5, 0.01),

('malpua_bengali', 'Malpua (Bengali Sweet Pancake)', 295.0, 4.5, 38.0, 14.5, 0.5, 25.0, 80, 40, 'indian_traditional', ARRAY['malpua bengali', 'bengali malpua', 'sweet pancake bengali', 'malpoa'], 'indian', NULL, 2, 'Deep fried sweet pancake soaked in syrup. ~118 cal per piece (40g).', true, 55, 20, 4.0, 0.1, 90, 50, 0.8, 20, 0.0, 3, 12, 0.4, 55, 2.0, 0.01),

-- =====================================================================
-- BENGALI SNACKS (~7 items)
-- =====================================================================

('jhalmuri', 'Jhalmuri (Spiced Puffed Rice)', 350.0, 7.5, 55.0, 12.0, 3.0, 2.0, 80, NULL, 'indian_traditional', ARRAY['jhal muri', 'spiced puffed rice', 'kolkata jhalmuri', 'muri makha', 'masala muri'], 'indian', NULL, 1, 'Puffed rice mixed with peanuts, onion, mustard oil, spices. ~280 cal per serving (80g).', true, 380, 0, 1.8, 0.0, 250, 25, 2.5, 8, 5.0, 0, 40, 1.0, 95, 4.0, 0.02),

('ghugni', 'Ghugni (Bengali Yellow Peas Curry)', 130.0, 7.0, 18.0, 3.5, 4.5, 1.5, 150, NULL, 'indian_traditional', ARRAY['ghugni bengali', 'dried peas curry', 'motor ghugni', 'yellow peas bengali snack', 'chana ghugni'], 'indian', NULL, 1, 'Spiced dried yellow peas street food snack. ~195 cal per serving (150g).', true, 200, 0, 0.5, 0.0, 350, 30, 2.8, 5, 3.0, 0, 35, 1.2, 110, 2.5, 0.01),

('singara', 'Singara (Bengali Samosa)', 280.0, 5.0, 30.0, 15.5, 2.0, 1.5, 80, 40, 'indian_traditional', ARRAY['singara bengali', 'bengali samosa', 'aloo singara', 'kolkata singara', 'shinghara'], 'indian', NULL, 2, 'Bengali triangular pastry with spiced potato filling. ~112 cal per piece (40g).', true, 320, 0, 3.5, 0.2, 180, 15, 1.2, 3, 4.0, 0, 15, 0.4, 45, 2.0, 0.01),

('telebhaja', 'Telebhaja (Bengali Fried Snacks Assortment)', 310.0, 5.5, 32.0, 18.0, 1.5, 1.0, 100, NULL, 'indian_traditional', ARRAY['tele bhaja', 'bengali pakora', 'beguni', 'peyaji', 'bengali fritters'], 'indian', NULL, 1, 'Assorted deep fried fritters (onion, eggplant, etc). ~310 cal per serving (100g).', true, 350, 5, 3.0, 0.2, 200, 25, 1.5, 10, 5.0, 0, 18, 0.5, 55, 2.0, 0.01),

('puchka', 'Puchka (Bengali Panipuri)', 180.0, 3.5, 28.0, 6.5, 2.0, 3.0, 120, 15, 'indian_traditional', ARRAY['phuchka', 'bengali golgappa', 'kolkata puchka', 'pani puri bengali', 'fuchka'], 'indian', NULL, 8, 'Crispy hollow puris with spiced potato and tamarind water. ~22 cal per piece (15g).', true, 280, 0, 0.8, 0.1, 180, 15, 1.5, 5, 5.0, 0, 12, 0.4, 40, 1.0, 0.01),

('kathi_roll', 'Kathi Roll (Kolkata Egg Roll)', 207.0, 10.0, 22.0, 9.5, 1.5, 1.5, 200, 200, 'indian_traditional', ARRAY['kolkata roll', 'egg roll kolkata', 'kathi kabab roll', 'chicken kathi roll', 'mutton roll kolkata'], 'indian', NULL, 1, 'Paratha wrap with egg, onions, and spiced filling. ~414 cal per roll (200g).', true, 420, 55, 2.5, 0.1, 220, 35, 2.0, 25, 4.0, 10, 22, 1.2, 120, 10.0, 0.03),

('cutlet_bengali', 'Cutlet Bengali Style (Chop)', 220.0, 10.0, 18.0, 12.0, 1.5, 1.0, 100, 60, 'indian_traditional', ARRAY['bengali chop', 'vegetable cutlet bengali', 'fish cutlet bengali', 'kolkata cutlet', 'bengali croquette'], 'indian', NULL, 2, 'Breadcrumb-coated deep fried cutlet. ~132 cal per piece (60g).', true, 380, 30, 2.5, 0.1, 200, 22, 1.5, 8, 3.0, 5, 18, 0.8, 85, 5.0, 0.02),

-- =====================================================================
-- ODISHA MAIN DISHES (~8 items)
-- =====================================================================

('dalma', 'Dalma (Odia Dal with Vegetables)', 82.0, 4.0, 12.0, 2.2, 3.0, 2.0, 250, NULL, 'indian_traditional', ARRAY['dalma odia', 'odisha dalma', 'toor dal vegetables', 'oriya dalma', 'dalma odia style'], 'indian', NULL, 1, 'Lentils cooked with mixed vegetables. ~205 cal per serving (250g).', true, 120, 0, 0.4, 0.0, 388, 35, 1.8, 30, 8.0, 0, 32, 0.8, 90, 2.0, 0.01),

('santula', 'Santula (Odia Steamed Vegetables)', 55.0, 2.0, 8.0, 1.8, 2.5, 2.0, 200, NULL, 'indian_traditional', ARRAY['santula odia', 'steamed vegetables odisha', 'odia santula', 'mixed veg santula'], 'indian', NULL, 1, 'Lightly steamed vegetables with minimal spices. ~110 cal per serving (200g).', true, 90, 0, 0.3, 0.0, 320, 40, 1.2, 45, 18.0, 0, 25, 0.4, 55, 0.8, 0.01),

('besara', 'Besara (Odia Mustard Curry)', 75.0, 3.0, 8.0, 3.8, 2.0, 1.5, 200, NULL, 'indian_traditional', ARRAY['besara odia', 'mustard curry odisha', 'odia besara', 'mustard paste vegetable curry'], 'indian', NULL, 1, 'Vegetables in mustard paste gravy. ~150 cal per serving (200g).', true, 145, 0, 0.5, 0.0, 300, 50, 1.5, 35, 10.0, 0, 30, 0.6, 70, 1.0, 0.02),

('pakhala_bhata', 'Pakhala Bhata (Fermented Rice)', 55.0, 1.2, 12.0, 0.2, 0.5, 0.3, 300, NULL, 'indian_traditional', ARRAY['pakhala', 'fermented rice odisha', 'torani pakhala', 'jeera pakhala', 'dahi pakhala'], 'indian', NULL, 1, 'Leftover rice fermented overnight in water. ~165 cal per serving (300g). Rich in probiotics.', true, 15, 0, 0.1, 0.0, 40, 20, 0.8, 0, 0.0, 0, 12, 0.3, 35, 4.0, 0.01),

('machha_besara', 'Machha Besara (Odia Fish in Mustard)', 125.0, 14.0, 3.0, 6.5, 0.5, 0.5, 250, NULL, 'indian_traditional', ARRAY['macha besara', 'fish mustard odisha', 'odia fish curry', 'machha jhola odisha'], 'indian', NULL, 1, 'Fish cooked in mustard paste. ~313 cal per serving (250g).', true, 200, 50, 1.0, 0.0, 300, 55, 1.5, 15, 2.0, 35, 30, 0.8, 200, 25.0, 0.15),

('machha_jhola', 'Machha Jhola (Odia Fish Curry)', 92.0, 12.0, 3.5, 3.5, 0.5, 0.8, 250, NULL, 'indian_traditional', ARRAY['odia macher jhol', 'fish jhola odisha', 'oriya fish curry', 'macha jhola'], 'indian', NULL, 1, 'Light Odia fish curry similar to Bengali style. ~230 cal per serving (250g).', true, 175, 42, 0.7, 0.0, 270, 40, 1.1, 12, 3.0, 35, 26, 0.6, 180, 22.0, 0.12),

('khechudi', 'Khechudi (Odia Khichdi)', 118.0, 4.5, 18.5, 3.2, 1.5, 0.5, 250, NULL, 'indian_traditional', ARRAY['odia khichdi', 'khechudi odisha', 'temple khechudi', 'bhoger khichudi odia'], 'indian', NULL, 1, 'Odia rice and lentil one-pot dish. ~295 cal per serving (250g).', true, 170, 5, 1.0, 0.0, 200, 22, 1.3, 12, 3.0, 2, 25, 0.7, 88, 4.5, 0.01),

('ghanta_tarkari', 'Ghanta Tarkari (Odia Mixed Veg Curry)', 80.0, 3.0, 10.0, 3.2, 2.5, 2.0, 200, NULL, 'indian_traditional', ARRAY['ghanta odia', 'ghanta tarkari odisha', 'mixed vegetable odia', 'oriya ghanta curry'], 'indian', NULL, 1, 'Mixed vegetables with toasted moong dal paste. ~160 cal per serving (200g).', true, 140, 0, 0.5, 0.0, 330, 40, 1.5, 40, 12.0, 0, 28, 0.5, 68, 1.0, 0.01),

-- =====================================================================
-- ODISHA SWEETS (~5 items)
-- =====================================================================

('chhena_poda', 'Chhena Poda (Odia Baked Cheese Sweet)', 300.0, 10.0, 35.0, 14.0, 0.2, 28.0, 80, 50, 'indian_traditional', ARRAY['chenna poda', 'cheese dessert odisha', 'baked paneer sweet', 'chhena poda odisha'], 'indian', NULL, 1, 'Baked cottage cheese dessert from Odisha. ~150 cal per piece (50g).', true, 40, 20, 7.0, 0.0, 95, 110, 0.6, 35, 0.0, 3, 12, 0.6, 120, 4.0, 0.01),

('rasabali', 'Rasabali (Odia Sweet Cheese Disc)', 295.0, 6.5, 42.0, 12.0, 0.1, 36.0, 80, 40, 'indian_traditional', ARRAY['rasa bali', 'rasabali odisha', 'kendrapada rasabali', 'chhena disc sweet'], 'indian', NULL, 2, 'Fried chhena discs soaked in thickened sweetened milk. ~118 cal per piece (40g).', true, 35, 15, 5.5, 0.0, 80, 75, 0.4, 25, 0.0, 3, 10, 0.5, 80, 3.0, 0.01),

('chhena_gaja', 'Chhena Gaja (Odia Cheese Fudge)', 340.0, 7.0, 45.0, 15.5, 0.0, 38.0, 60, 30, 'indian_traditional', ARRAY['chenna gaja', 'chhena gaja odisha', 'rectangular cheese sweet'], 'indian', NULL, 2, 'Rectangular shaped fried chhena sweet coated in sugar syrup. ~102 cal per piece (30g).', true, 30, 15, 6.5, 0.1, 65, 60, 0.3, 18, 0.0, 2, 8, 0.4, 65, 2.0, 0.01),

('khaja_odisha', 'Khaja (Odia Flaky Pastry Sweet)', 380.0, 4.0, 52.0, 18.0, 0.5, 30.0, 60, 30, 'indian_traditional', ARRAY['puri khaja', 'khaja odisha', 'flaky sweet pastry', 'khaja sweet'], 'indian', NULL, 2, 'Multi-layered flaky pastry dipped in sugar syrup. ~114 cal per piece (30g).', true, 40, 0, 4.0, 0.2, 50, 12, 0.8, 0, 0.0, 0, 8, 0.3, 30, 2.0, 0.01),

('arisa_pitha', 'Arisa Pitha (Odia Rice Cake)', 350.0, 4.0, 55.0, 13.0, 1.0, 20.0, 80, 40, 'indian_traditional', ARRAY['arisha pitha', 'arisa pitha odisha', 'rice cake odia', 'deep fried rice cake'], 'indian', NULL, 2, 'Deep fried rice flour cake sweetened with jaggery. ~140 cal per piece (40g).', true, 25, 0, 2.0, 0.1, 80, 15, 1.5, 0, 0.0, 0, 18, 0.3, 45, 3.0, 0.01),

-- =====================================================================
-- BIHAR / JHARKHAND (~10 items)
-- =====================================================================

('litti_chokha', 'Litti Chokha (Sattu Stuffed Wheat Ball)', 180.0, 6.5, 25.0, 6.5, 3.5, 1.5, 250, 60, 'indian_traditional', ARRAY['litti chokha bihar', 'bihari litti', 'sattu litti', 'baati chokha', 'litti with chokha'], 'indian', NULL, 3, 'Roasted wheat balls stuffed with sattu, served with mashed veg. ~108 cal per litti (60g).', true, 280, 0, 1.5, 0.0, 350, 40, 3.0, 25, 8.0, 0, 45, 1.2, 130, 5.0, 0.02),

('sattu_paratha', 'Sattu Paratha (Bihari Stuffed Flatbread)', 250.0, 9.0, 32.0, 10.0, 3.5, 1.0, 100, 80, 'indian_traditional', ARRAY['sattu ka paratha', 'bihari sattu paratha', 'stuffed sattu bread', 'sattu roti'], 'indian', NULL, 1, 'Wheat flatbread stuffed with spiced roasted gram flour. ~200 cal per paratha (80g).', true, 320, 0, 2.0, 0.0, 280, 35, 3.5, 5, 2.0, 0, 50, 1.5, 150, 5.0, 0.02),

('sattu_sharbat', 'Sattu Sharbat (Roasted Gram Drink)', 45.0, 3.0, 7.0, 0.5, 1.5, 3.0, 300, NULL, 'indian_traditional', ARRAY['sattu drink', 'sattu ka sharbat', 'bihari sattu drink', 'sattu pani'], 'indian', NULL, 1, 'Refreshing drink made with sattu, lemon, sugar. ~135 cal per glass (300ml).', true, 180, 0, 0.1, 0.0, 120, 15, 1.0, 0, 5.0, 0, 18, 0.5, 55, 2.0, 0.01),

('thekua', 'Thekua (Bihar Wheat Sweet)', 380.0, 5.0, 52.0, 17.0, 1.5, 18.0, 60, 30, 'indian_traditional', ARRAY['thekua bihar', 'khajuria', 'thekua sweet', 'chhath puja thekua'], 'indian', NULL, 2, 'Deep fried wheat cookie with jaggery, often for Chhath Puja. ~114 cal per piece (30g).', true, 35, 5, 4.0, 0.1, 80, 20, 1.5, 5, 0.0, 0, 15, 0.5, 55, 3.0, 0.01),

('dhuska', 'Dhuska (Bihar Rice-Lentil Fried Bread)', 250.0, 5.0, 33.0, 11.5, 1.5, 0.5, 100, 40, 'indian_traditional', ARRAY['dhuska jharkhand', 'rice dal fried bread', 'bihari dhuska', 'jharkhand dhuska'], 'indian', NULL, 2, 'Deep fried bread made from rice and lentil batter. ~100 cal per piece (40g).', true, 210, 0, 1.8, 0.1, 150, 18, 1.5, 2, 0.5, 0, 20, 0.5, 65, 3.0, 0.01),

('baingan_chokha', 'Baingan Chokha (Smoky Mashed Eggplant)', 65.0, 1.5, 7.0, 3.5, 2.5, 2.5, 150, NULL, 'indian_traditional', ARRAY['baigan chokha', 'roasted eggplant mash bihari', 'bihari baingan bharta', 'chokha eggplant'], 'indian', NULL, 1, 'Fire-roasted and mashed eggplant with mustard oil. ~98 cal per serving (150g).', true, 110, 0, 0.5, 0.0, 220, 15, 0.8, 8, 3.0, 0, 14, 0.3, 28, 0.5, 0.01),

('aloo_chokha', 'Aloo Chokha (Bihari Mashed Potato)', 110.0, 2.0, 16.0, 4.5, 1.5, 0.8, 150, NULL, 'indian_traditional', ARRAY['aloo ka chokha', 'mashed potato bihari', 'potato chokha', 'bihari aloo mash'], 'indian', NULL, 1, 'Boiled mashed potato with mustard oil, onion, chili. ~165 cal per serving (150g).', true, 130, 0, 0.6, 0.0, 380, 12, 0.7, 3, 12.0, 0, 22, 0.3, 55, 0.5, 0.01),

('dal_pitha', 'Dal Pitha (Bihar Steamed Rice Dumpling)', 155.0, 5.5, 28.0, 2.5, 2.0, 1.5, 120, 30, 'indian_traditional', ARRAY['dal pitha bihar', 'rice dumpling bihari', 'jharkhand pitha', 'pithe bengali'], 'indian', NULL, 4, 'Steamed rice flour dumplings with dal filling. ~47 cal per piece (30g).', true, 120, 0, 0.4, 0.0, 160, 20, 1.5, 3, 0.5, 0, 22, 0.6, 70, 3.0, 0.01),

('tilkut', 'Tilkut (Bihar Sesame Brittle)', 480.0, 12.0, 42.0, 30.0, 5.0, 25.0, 40, 20, 'indian_traditional', ARRAY['til kut', 'sesame brittle bihar', 'gaya tilkut', 'tilkut sweet'], 'indian', NULL, 2, 'Compressed sesame seed and sugar sweet from Gaya. ~96 cal per piece (20g).', true, 20, 0, 4.2, 0.0, 350, 580, 8.0, 2, 0.0, 0, 280, 5.0, 450, 5.0, 0.05),

('balushahi', 'Balushahi (Bihar Flaky Fried Sweet)', 370.0, 4.5, 50.0, 17.5, 0.5, 30.0, 60, 40, 'indian_traditional', ARRAY['balushahi bihar', 'balushai', 'khurmi', 'bihari balushahi sweet'], 'indian', NULL, 1, 'Flaky fried dough soaked in sugar syrup. ~148 cal per piece (40g).', true, 30, 5, 5.0, 0.2, 50, 12, 0.8, 0, 0.0, 0, 8, 0.3, 35, 2.0, 0.01),

-- =====================================================================
-- ASSAM (~15 items)
-- =====================================================================

('masor_tenga', 'Masor Tenga (Assamese Sour Fish Curry)', 85.0, 11.0, 4.0, 3.0, 0.8, 1.5, 250, NULL, 'indian_traditional', ARRAY['masor tenga assamese', 'sour fish curry assam', 'tenga maas', 'ou tenga maas', 'assamese fish curry'], 'indian', NULL, 1, 'Light sour fish curry with tomato or elephant apple. ~213 cal per serving (250g).', true, 170, 40, 0.6, 0.0, 310, 35, 1.2, 20, 15.0, 35, 26, 0.6, 180, 22.0, 0.12),

('khar_assamese', 'Khar (Assamese Alkali Dish)', 45.0, 1.5, 6.5, 1.5, 1.5, 1.0, 200, NULL, 'indian_traditional', ARRAY['khar assam', 'banana peel khar', 'assamese khar dish', 'kola khar'], 'indian', NULL, 1, 'Traditional alkali dish with raw papaya or vegetables. ~90 cal per serving (200g).', true, 250, 0, 0.2, 0.0, 280, 30, 1.0, 25, 20.0, 0, 20, 0.3, 35, 0.5, 0.01),

('aloo_pitika', 'Aloo Pitika (Assamese Mashed Potato)', 105.0, 2.0, 15.0, 4.5, 1.5, 0.8, 150, NULL, 'indian_traditional', ARRAY['alu pitika', 'assamese aloo mash', 'mashed potato assam', 'pitika assam'], 'indian', NULL, 1, 'Mashed potato with mustard oil, onion and green chili. ~158 cal per serving (150g).', true, 120, 0, 0.6, 0.0, 370, 12, 0.7, 5, 12.0, 0, 22, 0.3, 55, 0.5, 0.01),

('ou_tenga_maas', 'Ou Tenga Diya Maas (Fish with Elephant Apple)', 90.0, 11.5, 4.5, 3.0, 1.0, 2.0, 250, NULL, 'indian_traditional', ARRAY['ou tenga fish curry', 'elephant apple fish', 'assamese ou tenga', 'maas ou tenga'], 'indian', NULL, 1, 'Fish curry with elephant apple giving a sour tang. ~225 cal per serving (250g).', true, 165, 40, 0.6, 0.0, 300, 30, 1.2, 18, 20.0, 35, 25, 0.5, 175, 22.0, 0.10),

('duck_curry_assamese', 'Duck Meat Curry (Assamese Style)', 175.0, 16.0, 4.0, 10.5, 0.5, 1.0, 250, NULL, 'indian_traditional', ARRAY['haanhor mangxo', 'assamese duck curry', 'duck meat assam', 'hahor mangsho'], 'indian', NULL, 1, 'Traditional Assamese duck curry with spices. ~438 cal per serving (250g).', true, 280, 85, 3.5, 0.1, 270, 18, 2.5, 30, 3.0, 10, 20, 2.5, 165, 15.0, 0.08),

('pork_bamboo_assamese', 'Pork with Bamboo Shoot (Assamese)', 165.0, 14.0, 3.5, 10.5, 1.5, 0.8, 200, NULL, 'indian_traditional', ARRAY['pork bamboo shoot assam', 'gahori bamboo shoot', 'pork with khorisa', 'assamese pork curry'], 'indian', NULL, 1, 'Pork cooked with fermented bamboo shoot. ~330 cal per serving (200g).', true, 350, 65, 3.8, 0.0, 300, 15, 1.8, 5, 3.0, 8, 22, 2.8, 155, 18.0, 0.05),

('ou_khatta', 'Ou Khatta (Elephant Apple Chutney)', 75.0, 0.5, 18.0, 0.2, 2.0, 14.0, 50, NULL, 'indian_traditional', ARRAY['ou tenga khatta', 'elephant apple chutney', 'assamese ou khatta', 'sweet sour chutney assam'], 'indian', NULL, 1, 'Sweet-sour chutney made from elephant apple. ~38 cal per serving (50g).', true, 30, 0, 0.0, 0.0, 120, 18, 0.5, 5, 25.0, 0, 10, 0.2, 15, 0.5, 0.01),

('bor_assamese', 'Bor (Assamese Dal Fritters)', 230.0, 8.0, 22.0, 13.0, 2.5, 0.5, 80, 15, 'indian_traditional', ARRAY['bor fritters', 'assamese dal vada', 'masor bor', 'lentil fritters assam'], 'indian', NULL, 5, 'Crispy lentil fritters deep fried. ~35 cal per piece (15g).', true, 200, 0, 1.8, 0.1, 220, 25, 2.0, 3, 1.0, 0, 28, 0.8, 85, 3.0, 0.01),

('koldil_bhaji', 'Koldil Bhaji (Banana Blossom Stir Fry)', 65.0, 2.0, 9.5, 2.5, 3.0, 1.5, 150, NULL, 'indian_traditional', ARRAY['banana flower stir fry assam', 'koldil bhazi', 'assamese banana blossom', 'mocha bhaji assamese'], 'indian', NULL, 1, 'Banana blossom stir fried with spices. ~98 cal per serving (150g).', true, 100, 0, 0.4, 0.0, 380, 30, 1.8, 8, 6.0, 0, 35, 0.4, 55, 0.8, 0.01),

('xaak_bhaji', 'Xaak Bhaji (Assamese Greens Stir Fry)', 50.0, 3.0, 5.0, 2.5, 2.5, 0.5, 150, NULL, 'indian_traditional', ARRAY['assamese saag', 'xaak bhazi assam', 'leafy greens assamese', 'lai xaak', 'dhekia xaak'], 'indian', NULL, 1, 'Assamese stir-fried leafy greens in mustard oil. ~75 cal per serving (150g).', true, 80, 0, 0.3, 0.0, 350, 120, 3.0, 280, 30.0, 0, 45, 0.5, 50, 1.0, 0.05),

('sticky_rice_assam', 'Sticky Rice (Bora Saul Assamese)', 150.0, 3.0, 34.0, 0.3, 0.5, 0.2, 150, NULL, 'indian_traditional', ARRAY['bora chaul', 'assamese glutinous rice', 'sticky rice assam', 'bora saul'], 'indian', NULL, 1, 'Traditional Assamese glutinous sticky rice. ~225 cal per serving (150g).', true, 5, 0, 0.1, 0.0, 35, 8, 0.4, 0, 0.0, 0, 12, 0.5, 40, 6.0, 0.01),

('black_rice_assam', 'Black Rice (Kola Chaul Assamese)', 155.0, 4.0, 33.0, 1.2, 1.5, 0.3, 150, NULL, 'indian_traditional', ARRAY['kola chaul', 'forbidden rice assam', 'black rice assamese', 'bora kola chaul'], 'indian', NULL, 1, 'Nutrient-rich black rice variety from Assam. ~233 cal per serving (150g).', true, 5, 0, 0.3, 0.0, 130, 15, 1.8, 0, 0.0, 0, 50, 1.2, 80, 8.0, 0.02),

('jolpan', 'Jolpan (Assamese Flattened Rice Snack)', 320.0, 5.0, 58.0, 8.0, 1.5, 3.0, 80, NULL, 'indian_traditional', ARRAY['jolpan assam', 'chira doi jolpan', 'assamese breakfast snack', 'komol chaul jolpan'], 'indian', NULL, 1, 'Traditional Assamese breakfast of flattened rice with curd/jaggery. ~256 cal per serving (80g).', true, 60, 5, 2.0, 0.0, 140, 40, 1.5, 8, 1.0, 2, 20, 0.5, 55, 3.0, 0.01),

('pitha_assamese', 'Pitha (Assamese Rice Cake)', 240.0, 3.5, 42.0, 7.0, 1.0, 12.0, 80, 40, 'indian_traditional', ARRAY['til pitha', 'narikol pitha', 'assamese pitha', 'ghila pitha', 'sunga pitha'], 'indian', NULL, 2, 'Traditional Assamese rice cake with sesame or coconut filling. ~96 cal per piece (40g).', true, 30, 0, 2.0, 0.0, 80, 30, 1.2, 2, 0.5, 0, 25, 0.8, 60, 3.0, 0.02),

('til_pitha', 'Til Pitha (Sesame Rice Roll)', 285.0, 5.5, 40.0, 12.0, 2.5, 15.0, 60, 30, 'indian_traditional', ARRAY['sesame rice cake assam', 'til pitha assamese', 'sesame pitha', 'bihu til pitha'], 'indian', NULL, 2, 'Rice crepe filled with sesame and jaggery. ~86 cal per piece (30g).', true, 25, 0, 1.8, 0.0, 150, 120, 3.0, 2, 0.0, 0, 80, 2.5, 145, 4.0, 0.03),

-- =====================================================================
-- MANIPUR (~4 items)
-- =====================================================================

('eromba', 'Eromba (Manipuri Fermented Fish Chutney)', 85.0, 6.5, 8.0, 3.5, 2.0, 1.0, 150, NULL, 'indian_traditional', ARRAY['eromba manipur', 'ngari eromba', 'fermented fish chutney manipur', 'manipuri eromba'], 'indian', NULL, 1, 'Mashed veggies with fermented fish (ngari). ~128 cal per serving (150g).', true, 450, 25, 0.8, 0.0, 350, 60, 2.0, 30, 15.0, 10, 35, 0.8, 120, 8.0, 0.10),

('singju', 'Singju (Manipuri Fresh Salad)', 55.0, 3.0, 6.5, 2.0, 2.5, 1.5, 150, NULL, 'indian_traditional', ARRAY['singju manipur', 'manipuri salad', 'singju salad', 'kangsoi singju'], 'indian', NULL, 1, 'Fresh vegetable salad with fermented fish and chili. ~83 cal per serving (150g).', true, 350, 10, 0.3, 0.0, 280, 45, 1.5, 50, 25.0, 5, 28, 0.5, 65, 3.0, 0.05),

('chamthong', 'Chamthong (Manipuri Vegetable Stew)', 40.0, 2.0, 5.5, 1.0, 2.0, 1.5, 250, NULL, 'indian_traditional', ARRAY['kangshoi', 'chamthong manipur', 'manipuri vegetable stew', 'manipur boiled veg'], 'indian', NULL, 1, 'Light clear vegetable stew, staple comfort food. ~100 cal per serving (250g).', true, 120, 0, 0.2, 0.0, 320, 40, 1.2, 55, 20.0, 0, 22, 0.4, 50, 0.8, 0.01),

('kangshoi', 'Kangshoi (Manipuri Boiled Vegetable)', 38.0, 1.8, 5.0, 1.0, 2.0, 1.5, 250, NULL, 'indian_traditional', ARRAY['kangshoi manipur', 'boiled vegetables manipuri', 'manipuri kangshoi'], 'indian', NULL, 1, 'Boiled mixed vegetables with minimal seasoning. ~95 cal per serving (250g).', true, 100, 0, 0.2, 0.0, 310, 38, 1.0, 50, 18.0, 0, 20, 0.3, 45, 0.7, 0.01),

-- =====================================================================
-- NAGALAND (~3 items)
-- =====================================================================

('smoked_pork_bamboo', 'Smoked Pork with Bamboo Shoot (Naga)', 185.0, 15.0, 3.0, 13.0, 1.5, 0.5, 200, NULL, 'indian_traditional', ARRAY['naga smoked pork', 'smoked pork bamboo nagaland', 'naga pork curry', 'bamboo shoot pork naga'], 'indian', NULL, 1, 'Smoked pork slow cooked with fermented bamboo shoot. ~370 cal per serving (200g).', true, 480, 70, 4.8, 0.0, 320, 18, 2.0, 5, 3.0, 8, 22, 3.0, 155, 18.0, 0.05),

('axone_curry', 'Axone Curry (Naga Fermented Soybean)', 160.0, 15.0, 8.0, 8.5, 4.0, 1.0, 150, NULL, 'indian_traditional', ARRAY['akhuni curry', 'axone nagaland', 'fermented soybean naga', 'akhuni pork', 'naga axone'], 'indian', NULL, 1, 'Fermented soybean based curry. ~240 cal per serving (150g).', true, 520, 30, 2.0, 0.0, 400, 130, 5.5, 5, 2.0, 0, 65, 2.5, 200, 8.0, 0.08),

('raja_mircha_pork', 'Raja Mircha Pork (Ghost Pepper Pork)', 195.0, 16.0, 3.5, 13.5, 0.8, 1.0, 200, NULL, 'indian_traditional', ARRAY['bhut jolokia pork', 'naga king chili pork', 'ghost pepper pork naga', 'raja mirchi meat'], 'indian', NULL, 1, 'Pork cooked with Naga ghost peppers. Very spicy. ~390 cal per serving (200g).', true, 380, 70, 5.0, 0.0, 290, 15, 2.0, 35, 80.0, 8, 20, 2.8, 150, 18.0, 0.05),

-- =====================================================================
-- MEGHALAYA (~3 items)
-- =====================================================================

('jadoh', 'Jadoh (Meghalaya Pork Rice)', 145.0, 6.7, 18.7, 5.0, 0.8, 0.3, 250, NULL, 'indian_traditional', ARRAY['jadoh meghalaya', 'khasi pork rice', 'jadoh rice', 'meghalaya pork pulao'], 'indian', NULL, 1, 'Traditional Khasi pork and rice dish. ~363 cal per serving (250g).', true, 250, 35, 1.8, 0.0, 220, 15, 1.5, 5, 1.0, 5, 18, 1.8, 120, 12.0, 0.04),

('tungrymbai', 'Tungrymbai (Meghalaya Fermented Soybean)', 155.0, 14.5, 8.5, 7.5, 4.0, 1.0, 150, NULL, 'indian_traditional', ARRAY['tungrymbai meghalaya', 'fermented soybean meghalaya', 'khasi tungrymbai'], 'indian', NULL, 1, 'Fermented soybean dish cooked with pork or sesame. ~233 cal per serving (150g).', true, 480, 25, 1.5, 0.0, 380, 120, 5.0, 5, 2.0, 0, 60, 2.2, 190, 7.0, 0.08),

('doh_khlieh', 'Doh Khlieh (Meghalaya Pork Salad)', 145.0, 14.0, 5.0, 8.0, 1.5, 1.0, 150, NULL, 'indian_traditional', ARRAY['doh khleh', 'khasi pork salad', 'pork salad meghalaya', 'doh khlieh meghalaya'], 'indian', NULL, 1, 'Minced pork salad with onions and ginger. ~218 cal per serving (150g).', true, 320, 55, 3.0, 0.0, 260, 15, 1.5, 5, 5.0, 5, 18, 2.5, 140, 15.0, 0.04),

-- =====================================================================
-- MIZORAM (~2 items)
-- =====================================================================

('bai_mizoram', 'Bai (Mizo Mixed Boiled Vegetables)', 42.0, 2.0, 5.5, 1.2, 2.5, 1.5, 250, NULL, 'indian_traditional', ARRAY['bai mizoram', 'mizo boiled vegetables', 'mizoram mixed veg', 'bai mizo dish'], 'indian', NULL, 1, 'Mixed boiled vegetables, Mizo staple side dish. ~105 cal per serving (250g).', true, 90, 0, 0.2, 0.0, 300, 40, 1.2, 50, 18.0, 0, 22, 0.3, 45, 0.7, 0.01),

('vawksa_rep', 'Vawksa Rep (Mizo Smoked Pork)', 210.0, 18.0, 1.0, 15.0, 0.0, 0.5, 150, NULL, 'indian_traditional', ARRAY['smoked pork mizoram', 'vawksa rep mizo', 'mizoram smoked meat', 'mizo pork'], 'indian', NULL, 1, 'Smoked and stewed pork, staple Mizo meat dish. ~315 cal per serving (150g).', true, 520, 75, 5.5, 0.0, 280, 12, 1.8, 5, 0.0, 8, 18, 3.0, 150, 20.0, 0.04),

-- =====================================================================
-- SIKKIM (~4 items)
-- =====================================================================

('gundruk', 'Gundruk (Fermented Leafy Green)', 23.0, 3.0, 4.0, 0.4, 2.0, 0.5, 100, NULL, 'indian_traditional', ARRAY['gundruk sikkim', 'fermented greens', 'gundruk ko achar', 'dried fermented leaves', 'nepali gundruk'], 'indian', NULL, 1, 'Fermented and dried leafy greens, rich in probiotics. ~23 cal per serving (100g).', true, 79, 0, 0.1, 0.0, 558, 99, 3.0, 280, 28.0, 0, 45, 0.5, 50, 1.0, 0.05),

('kinema_curry', 'Kinema Curry (Sikkimese Fermented Soybean)', 165.0, 16.0, 7.5, 8.5, 4.5, 1.0, 150, NULL, 'indian_traditional', ARRAY['kinema sikkim', 'fermented soybean sikkim curry', 'sikkimese kinema', 'kinema soup'], 'indian', NULL, 1, 'Curry made from kinema (fermented soybean). High protein. ~248 cal per serving (150g).', true, 450, 0, 1.5, 0.0, 420, 140, 6.0, 5, 2.0, 0, 70, 3.0, 210, 8.0, 0.10),

('sel_roti', 'Sel Roti (Sikkimese Ring Bread)', 350.0, 5.0, 55.0, 12.0, 1.0, 10.0, 80, 60, 'indian_traditional', ARRAY['sel roti sikkim', 'ring bread nepali', 'sel roti sweet bread', 'sikkimese sel roti'], 'indian', NULL, 1, 'Traditional ring-shaped fried sweet rice bread. ~210 cal per piece (60g).', true, 35, 5, 2.5, 0.1, 55, 10, 0.8, 2, 0.0, 0, 12, 0.4, 45, 4.0, 0.01),

('momos_sikkim', 'Momos (Sikkim Style Steamed Dumplings)', 180.0, 9.5, 22.0, 6.0, 1.0, 1.0, 120, 30, 'indian_traditional', ARRAY['sikkim momos', 'steamed momos sikkimese', 'pork momos sikkim', 'veg momos sikkim'], 'indian', NULL, 4, 'Steamed dumplings with meat or vegetable filling. ~54 cal per piece (30g).', true, 380, 25, 2.0, 0.0, 180, 20, 1.5, 5, 2.0, 5, 15, 1.2, 85, 8.0, 0.03),

-- =====================================================================
-- ADDITIONAL ODISHA items
-- =====================================================================

('aloo_bharta_odisha', 'Aloo Bharta (Odia Mashed Potato)', 108.0, 2.0, 15.5, 4.5, 1.5, 0.8, 150, NULL, 'indian_traditional', ARRAY['aloo bharta odisha', 'mashed potato odia', 'alu bharta oriya'], 'indian', NULL, 1, 'Mashed potato with mustard oil and green chili. ~162 cal per serving (150g).', true, 125, 0, 0.6, 0.0, 375, 12, 0.7, 3, 12.0, 0, 22, 0.3, 55, 0.5, 0.01),

('kanika', 'Kanika (Odia Sweet Rice)', 200.0, 3.5, 38.0, 4.5, 0.5, 10.0, 200, NULL, 'indian_traditional', ARRAY['kanika odisha', 'sweet rice odia', 'meetha pulao odisha', 'temple sweet rice'], 'indian', NULL, 1, 'Sweetened rice with ghee, dry fruits and spices. ~400 cal per serving (200g).', true, 20, 10, 2.5, 0.0, 70, 15, 0.6, 20, 0.5, 2, 15, 0.5, 55, 5.0, 0.01),

('mudhi_mansa', 'Mudhi Mansa (Puffed Rice with Mutton Curry)', 185.0, 10.0, 22.0, 7.0, 1.0, 1.0, 200, NULL, 'indian_traditional', ARRAY['mudhi mansa odisha', 'puffed rice mutton cuttack', 'mudhi ghanto', 'mutton with puffed rice'], 'indian', NULL, 1, 'Odia street food of puffed rice served with spicy mutton curry. ~370 cal per serving (200g).', true, 320, 40, 2.5, 0.0, 250, 20, 2.0, 8, 3.0, 3, 22, 2.5, 120, 8.0, 0.03),

-- =====================================================================
-- ADDITIONAL BIHAR items
-- =====================================================================

('sattu_nashta', 'Sattu Ka Nashta (Roasted Gram Snack)', 360.0, 20.0, 55.0, 7.0, 10.0, 3.0, 50, NULL, 'indian_traditional', ARRAY['sattu flour raw', 'sattu powder', 'chana sattu', 'bihari sattu', 'roasted gram flour'], 'indian', NULL, 1, 'Plain roasted gram flour (sattu), Bihar superfood. ~180 cal per 50g serving.', true, 40, 0, 1.0, 0.0, 800, 60, 5.0, 8, 0.5, 0, 120, 2.5, 300, 6.0, 0.02),

('chana_ghugni_bihar', 'Chana Ghugni Bihar (Yellow Peas Curry)', 128.0, 7.0, 18.0, 3.0, 4.5, 1.5, 150, NULL, 'indian_traditional', ARRAY['ghugni bihar', 'motor ghugni bihari', 'yellow peas curry bihar', 'bihari ghugni'], 'indian', NULL, 1, 'Bihar style spiced dried yellow peas snack/side. ~192 cal per serving (150g).', true, 195, 0, 0.5, 0.0, 345, 28, 2.5, 5, 3.0, 0, 33, 1.2, 105, 2.5, 0.01),

('anarsa', 'Anarsa (Bihar Rice Sweet)', 390.0, 3.5, 58.0, 16.0, 0.5, 30.0, 60, 30, 'indian_traditional', ARRAY['anarsa bihar', 'anarsa sweet', 'rice cookie bihar', 'sesame rice cookie'], 'indian', NULL, 2, 'Deep fried rice flour sweet coated with sesame seeds. ~117 cal per piece (30g).', true, 20, 0, 2.5, 0.1, 60, 40, 1.5, 0, 0.0, 0, 30, 1.0, 55, 4.0, 0.02),

-- =====================================================================
-- ADDITIONAL ASSAMESE items
-- =====================================================================

('silk_worm_curry', 'Silk Worm Curry (Assamese Eri Polu)', 185.0, 22.0, 2.5, 10.0, 0.5, 0.5, 100, NULL, 'indian_traditional', ARRAY['eri polu', 'silk worm assam', 'assamese silkworm curry', 'eri silk worm dish'], 'indian', NULL, 1, 'Protein-rich silkworm pupae curry, NE Indian delicacy. ~185 cal per serving (100g).', true, 280, 120, 2.5, 0.0, 250, 35, 3.5, 15, 0.5, 5, 30, 3.0, 200, 25.0, 0.15),

('narikol_pitha', 'Narikol Pitha (Coconut Rice Cake)', 260.0, 4.0, 38.0, 11.0, 2.5, 15.0, 60, 30, 'indian_traditional', ARRAY['coconut pitha assam', 'narikol pitha assamese', 'coconut rice pancake'], 'indian', NULL, 2, 'Rice flour cake filled with sweetened coconut. ~78 cal per piece (30g).', true, 25, 0, 8.0, 0.0, 120, 15, 1.0, 0, 1.0, 0, 20, 0.5, 55, 3.0, 0.01),

-- =====================================================================
-- ADDITIONAL BENGALI items for count
-- =====================================================================

('cholar_dal_narkel', 'Cholar Dal Narkel Diye (Chana Dal with Coconut)', 135.0, 7.0, 18.5, 4.0, 3.8, 3.5, 200, NULL, 'indian_traditional', ARRAY['cholar dal with coconut', 'chana dal coconut bengali', 'puja cholar dal', 'bengali chana dal coconut'], 'indian', NULL, 1, 'Festive chana dal with grated coconut and raisins. ~270 cal per serving (200g).', true, 120, 0, 1.5, 0.0, 330, 30, 2.0, 3, 1.0, 0, 40, 1.3, 135, 3.0, 0.01),

('pahala_rasgulla', 'Pahala Rasgulla (Odisha Style Rasgulla)', 130.0, 5.5, 23.0, 2.0, 0.0, 21.0, 100, 45, 'indian_traditional', ARRAY['pahala rasgulla', 'odisha rasgulla', 'puri rasgulla', 'odia rosogolla'], 'indian', NULL, 2, 'Larger, softer rasgulla from Pahala, Odisha. ~59 cal per piece (45g).', true, 28, 5, 1.2, 0.0, 48, 70, 0.3, 12, 0.0, 2, 9, 0.4, 58, 2.0, 0.01)

ON CONFLICT (food_name_normalized) DO NOTHING;
