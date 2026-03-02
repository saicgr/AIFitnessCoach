-- ============================================================================
-- 1000_indian_south_telugu.sql
-- Traditional Telugu/Andhra/Telangana foods
-- All values per 100g. Sources: IFCT 2017, USDA, nutritionix, tarladalal, snapcalorie
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

-- =====================================================================
-- RAGI / MILLETS (10 items)
-- =====================================================================

('ragi_sangati', 'Ragi Sangati (Finger Millet Ball)', 110.0, 2.8, 23.5, 0.5, 1.2, 0.3, 200, 100, 'indian_traditional', ARRAY['ragi mudde', 'ragi ball', 'ragi sangati', 'finger millet ball', 'ragimudde', 'ragi kali', 'ragi sankati'], 'indian', NULL, 1, '220 cal per ball (~200g). Staple in Rayalaseema. Made from ragi flour cooked in water to stiff dough. Rich in calcium.', true, 8, 0, 0.1, 0.0, 108, 115, 1.3, 1, 0.0, 0, 45, 0.7, 100, 2.5, 0.01),

('ragi_java', 'Ragi Java (Ragi Malt Porridge)', 68.0, 1.5, 13.5, 0.4, 0.8, 4.5, 250, NULL, 'indian_traditional', ARRAY['ragi malt', 'ragi porridge', 'ragi ambali', 'ragi ganji', 'finger millet porridge', 'ragi java drink', 'ragi koozh'], 'indian', NULL, 1, '170 cal per glass (~250ml). Thin porridge with jaggery/milk. Popular Telugu breakfast drink. High calcium.', true, 5, 0, 0.1, 0.0, 85, 90, 1.0, 1, 0.5, 0, 35, 0.5, 70, 1.8, 0.01),

('ragi_dosa', 'Ragi Dosa (Finger Millet Dosa)', 150.0, 4.5, 24.0, 3.8, 1.8, 0.5, 120, 120, 'indian_traditional', ARRAY['ragi dosa', 'finger millet dosa', 'ragi dose', 'nachni dosa', 'ragi uttapam'], 'indian', NULL, 1, '180 cal per dosa (~120g). Crispy dosa made from ragi + rice batter. Higher protein than plain dosa.', true, 12, 0, 0.8, 0.0, 120, 100, 1.5, 2, 0.0, 0, 42, 0.8, 95, 3.0, 0.01),

('ragi_idli', 'Ragi Idli (Finger Millet Idli)', 120.0, 4.0, 22.0, 1.5, 1.5, 0.3, 180, 60, 'indian_traditional', ARRAY['ragi idli', 'finger millet idli', 'nachni idli', 'ragi idly'], 'indian', NULL, 3, '216 cal per 3 idlis (~180g). Steamed, softer than regular idli. Good source of calcium and iron.', true, 10, 0, 0.3, 0.0, 100, 95, 1.4, 1, 0.0, 0, 40, 0.7, 85, 2.5, 0.01),

('ragi_malt_drink', 'Ragi Malt Drink (with Milk & Jaggery)', 95.0, 3.2, 16.0, 1.8, 0.6, 8.0, 250, NULL, 'indian_traditional', ARRAY['ragi malt', 'ragi drink', 'sprouted ragi malt', 'ragi health drink', 'ragi java with milk'], 'indian', NULL, 1, '238 cal per glass (~250ml). Made with sprouted ragi flour, milk, and jaggery. Nutrient-dense beverage.', true, 40, 5, 1.0, 0.0, 150, 140, 1.2, 20, 1.0, 5, 38, 0.6, 95, 2.0, 0.02),

('jonna_rotte', 'Jonna Rotte (Sorghum/Jowar Roti)', 240.0, 7.5, 46.0, 2.3, 4.5, 0.8, 70, 70, 'indian_traditional', ARRAY['jowar roti', 'jonna roti', 'jolada rotti', 'sorghum roti', 'jwari bhakri', 'jonna rotelu', 'jonna sankati rotte'], 'indian', NULL, 2, '168 cal per roti (~70g). Unleavened flatbread. Staple in Telangana. Gluten-free, high fiber.', true, 5, 0, 0.4, 0.0, 240, 25, 3.5, 5, 0.0, 0, 120, 1.5, 222, 12.0, 0.02),

('sajja_rotte', 'Sajja Rotte (Pearl Millet/Bajra Roti)', 300.0, 10.5, 55.0, 4.5, 4.0, 1.0, 60, 60, 'indian_traditional', ARRAY['bajra roti', 'sajja roti', 'sajjalu roti', 'pearl millet roti', 'bajri bhakri', 'kambu roti'], 'indian', NULL, 2, '180 cal per roti (~60g). Dense, earthy flatbread. High in iron and magnesium. Winter staple.', true, 8, 0, 0.8, 0.0, 305, 42, 8.0, 5, 0.0, 0, 124, 3.1, 296, 2.5, 0.03),

('korralu_annam', 'Korralu Annam (Foxtail Millet Rice)', 118.0, 3.5, 22.5, 1.3, 2.2, 0.3, 200, NULL, 'indian_traditional', ARRAY['foxtail millet rice', 'korralu rice', 'korra annam', 'thinai rice', 'kangni rice', 'foxtail millet cooked'], 'indian', NULL, 1, '236 cal per cup (~200g). Cooked foxtail millet. Low GI alternative to white rice. Good for diabetics.', true, 3, 0, 0.3, 0.0, 130, 15, 1.3, 2, 0.0, 0, 44, 1.0, 110, 3.0, 0.02),

('samai_rice', 'Samai Rice (Little Millet Rice)', 115.0, 3.2, 21.8, 1.5, 2.5, 0.2, 200, NULL, 'indian_traditional', ARRAY['little millet rice', 'samai annam', 'sama rice', 'kutki rice', 'same rice cooked'], 'indian', NULL, 1, '230 cal per cup (~200g). Cooked little millet. High fiber, aids digestion. Telugu diet staple.', true, 3, 0, 0.3, 0.0, 125, 12, 3.2, 1, 0.0, 0, 40, 0.9, 100, 2.8, 0.01),

('varagu_rice', 'Varagu Rice (Kodo Millet Rice)', 119.0, 3.2, 25.2, 0.5, 3.0, 0.2, 200, NULL, 'indian_traditional', ARRAY['kodo millet rice', 'varagu annam', 'arikelu annam', 'kodra rice cooked', 'hark rice'], 'indian', NULL, 1, '238 cal per cup (~200g). Cooked kodo millet. Highest fiber among millets. Ideal for weight management.', true, 2, 0, 0.1, 0.0, 110, 27, 0.5, 1, 0.0, 0, 38, 0.8, 95, 2.2, 0.01),

-- =====================================================================
-- PALLI (PEANUT) ITEMS (3 items)
-- =====================================================================

('palli_podi', 'Palli Podi (Peanut Chutney Powder)', 480.0, 22.0, 18.0, 38.0, 5.5, 3.5, 15, NULL, 'indian_traditional', ARRAY['peanut powder', 'peanut chutney powder', 'verusenaga podi', 'groundnut podi', 'palli karam podi'], 'indian', NULL, 1, '72 cal per tbsp (~15g). Dry powder of roasted peanuts, red chillies, garlic. Mix with rice + ghee. Protein-rich condiment.', true, 12, 0, 5.5, 0.0, 550, 52, 2.0, 3, 0.5, 0, 130, 2.5, 280, 5.0, 0.01),

('palli_pachadi', 'Palli Pachadi (Peanut Chutney)', 280.0, 12.0, 14.0, 21.0, 3.0, 4.0, 40, NULL, 'indian_traditional', ARRAY['peanut chutney', 'verusenaga pachadi', 'groundnut chutney', 'pallila pachadi'], 'indian', NULL, 1, '112 cal per serving (~40g). Wet chutney with peanuts, tamarind, red chillies. Pairs with idli/dosa.', true, 15, 0, 3.2, 0.0, 300, 35, 1.5, 5, 2.0, 0, 75, 1.8, 160, 3.5, 0.01),

('verusenaga_pachadi', 'Verusenaga Pachadi (Wet Peanut Chutney)', 240.0, 10.0, 12.0, 18.0, 2.5, 3.5, 50, NULL, 'indian_traditional', ARRAY['wet peanut chutney', 'verusenaga chutney', 'peanut onion chutney', 'groundnut pachadi wet'], 'indian', NULL, 1, '120 cal per serving (~50g). Freshly ground with onion, green chillies, tamarind. Andhra meal accompaniment.', true, 20, 0, 2.8, 0.0, 270, 30, 1.3, 8, 3.0, 0, 65, 1.5, 140, 3.0, 0.01),

-- =====================================================================
-- PACHADIS / CHUTNEYS / PODIS (8 items)
-- =====================================================================

('gongura_pachadi', 'Gongura Pachadi (Sorrel Leaves Chutney)', 180.0, 3.0, 8.0, 15.0, 2.5, 2.0, 30, NULL, 'indian_traditional', ARRAY['gongura chutney', 'red sorrel chutney', 'gongura pickle', 'pulicha keerai chutney', 'gongura pachadi andhra'], 'indian', NULL, 1, '54 cal per tbsp (~30g). Iconic Andhra condiment. Tangy, spicy. Rich in iron, vitamin C, and oxalic acid.', true, 350, 0, 2.0, 0.0, 280, 55, 3.5, 180, 15.0, 0, 30, 0.6, 45, 1.0, 0.02),

('tomato_pachadi', 'Tomato Pachadi (Tomato Chutney)', 95.0, 2.0, 10.0, 5.5, 1.5, 4.0, 40, NULL, 'indian_traditional', ARRAY['tomato chutney', 'tomato pachadi andhra', 'tomata pachadi', 'thakkali pachadi'], 'indian', NULL, 1, '38 cal per serving (~40g). Tempered with mustard seeds, curry leaves. Pairs with idli, dosa, rice.', true, 180, 0, 0.8, 0.0, 220, 15, 0.8, 40, 12.0, 0, 12, 0.3, 25, 0.5, 0.01),

('dosakaya_pachadi', 'Dosakaya Pachadi (Yellow Cucumber Chutney)', 75.0, 1.5, 8.0, 4.0, 1.0, 3.0, 50, NULL, 'indian_traditional', ARRAY['cucumber chutney', 'dosakaya chutney', 'yellow cucumber pachadi', 'lemon cucumber chutney'], 'indian', NULL, 1, '38 cal per serving (~50g). Tangy, mildly spicy. Made with dosakaya (yellow cucumber), mustard, chillies.', true, 150, 0, 0.5, 0.0, 130, 12, 0.5, 10, 5.0, 0, 10, 0.2, 18, 0.3, 0.01),

('allam_pachadi', 'Allam Pachadi (Ginger Chutney)', 130.0, 2.0, 18.0, 5.5, 1.5, 8.0, 30, NULL, 'indian_traditional', ARRAY['ginger chutney', 'allam chutney', 'adrak chutney', 'inji pachadi', 'ginger pachadi andhra'], 'indian', NULL, 1, '39 cal per tbsp (~30g). Fiery ginger-tamarind-jaggery chutney. Digestive aid. Andhra festive condiment.', true, 80, 0, 0.7, 0.0, 180, 15, 1.2, 3, 3.5, 0, 20, 0.3, 22, 0.5, 0.01),

('kobbari_pachadi', 'Kobbari Pachadi (Coconut Chutney)', 170.0, 3.0, 10.0, 13.0, 3.5, 3.0, 40, NULL, 'indian_traditional', ARRAY['coconut chutney', 'kobbari chutney', 'nariyal chutney', 'thengai chutney', 'coconut pachadi andhra'], 'indian', NULL, 1, '68 cal per serving (~40g). Fresh coconut ground with green chillies, tempered with mustard. Standard with idli/dosa.', true, 25, 0, 10.5, 0.0, 200, 10, 1.5, 0, 2.0, 0, 22, 0.7, 75, 5.0, 0.01),

('pudina_pachadi', 'Pudina Pachadi (Mint Chutney)', 65.0, 2.5, 7.0, 3.0, 2.0, 1.5, 40, NULL, 'indian_traditional', ARRAY['mint chutney', 'pudina chutney', 'mint pachadi andhra', 'pudina kobbari pachadi'], 'indian', NULL, 1, '26 cal per serving (~40g). Fresh mint + coconut + green chillies. Cooling, digestive. Often served with biryani.', true, 30, 0, 1.8, 0.0, 180, 60, 2.0, 85, 8.0, 0, 22, 0.5, 40, 0.5, 0.01),

('nuvvula_podi', 'Nuvvula Podi (Sesame Chutney Powder)', 500.0, 16.0, 14.0, 42.0, 6.0, 1.5, 10, NULL, 'indian_traditional', ARRAY['sesame powder', 'nuvvula karam podi', 'ellu podi', 'til podi', 'sesame chutney powder'], 'indian', NULL, 1, '50 cal per tsp (~10g). Roasted sesame + red chillies + salt. Exceptionally high in calcium. Mix with rice + oil.', true, 45, 0, 5.8, 0.0, 400, 920, 11.0, 3, 0.0, 0, 320, 7.0, 570, 5.5, 0.05),

('karam_podi', 'Karam Podi (Spice Powder / Gun Powder)', 400.0, 20.0, 38.0, 18.0, 8.0, 2.0, 10, NULL, 'indian_traditional', ARRAY['gun powder', 'idli karam podi', 'milagai podi', 'chutney pudi', 'spice powder andhra', 'paruppu podi'], 'indian', NULL, 1, '40 cal per tsp (~10g). Roasted lentils, red chillies, sesame. High-protein condiment. Staple on every Telugu table.', true, 50, 0, 2.5, 0.0, 350, 85, 4.0, 55, 1.0, 0, 90, 2.0, 200, 8.0, 0.02),

-- =====================================================================
-- CURRIES / KOORAS (15 items)
-- =====================================================================

('gutti_vankaya_kura', 'Gutti Vankaya Kura (Stuffed Brinjal Curry)', 95.0, 2.5, 8.0, 6.0, 2.5, 2.5, 200, NULL, 'indian_traditional', ARRAY['stuffed brinjal curry', 'stuffed eggplant curry', 'gutti vankaya koora', 'ennai kathirikai', 'bharwa baingan andhra'], 'indian', NULL, 1, '190 cal per serving (~200g). Baby eggplants stuffed with peanut-sesame-spice masala. Signature Andhra dish.', true, 120, 0, 0.8, 0.0, 200, 20, 1.2, 15, 3.0, 0, 18, 0.4, 30, 1.0, 0.02),

('bendakaya_fry', 'Bendakaya Fry (Okra/Bhindi Fry)', 140.0, 3.0, 10.0, 10.0, 3.0, 1.5, 150, NULL, 'indian_traditional', ARRAY['okra fry', 'bhindi fry', 'bendakaya vepudu', 'ladies finger fry', 'vendakkai poriyal'], 'indian', NULL, 1, '210 cal per serving (~150g). Crispy pan-fried okra with spices. Telugu everyday sabzi. Good fiber source.', true, 60, 0, 1.2, 0.0, 240, 70, 1.2, 30, 18.0, 0, 40, 0.5, 50, 0.5, 0.01),

('dondakaya_fry', 'Dondakaya Fry (Ivy Gourd Fry)', 105.0, 2.5, 8.0, 7.0, 2.0, 1.0, 150, NULL, 'indian_traditional', ARRAY['ivy gourd fry', 'tindora fry', 'dondakaya vepudu', 'kovakkai poriyal', 'tendli fry'], 'indian', NULL, 1, '158 cal per serving (~150g). Sliced ivy gourd stir-fried with spices. Light, everyday Telugu side dish.', true, 55, 0, 0.9, 0.0, 160, 24, 0.9, 18, 3.0, 0, 14, 0.3, 22, 0.4, 0.01),

('beerakaya_curry', 'Beerakaya Curry (Ridge Gourd Curry)', 55.0, 1.8, 5.5, 3.0, 1.5, 1.5, 200, NULL, 'indian_traditional', ARRAY['ridge gourd curry', 'beerakaya koora', 'peerkangai kootu', 'turai sabzi', 'beerakaya pappu'], 'indian', NULL, 1, '110 cal per serving (~200g). Light, watery curry. Often cooked with dal. Very low calorie vegetable.', true, 40, 0, 0.4, 0.0, 140, 18, 0.7, 12, 5.0, 0, 18, 0.3, 25, 0.3, 0.01),

('sorakaya_curry', 'Sorakaya Curry (Bottle Gourd Curry)', 45.0, 1.2, 5.0, 2.2, 0.8, 2.0, 200, NULL, 'indian_traditional', ARRAY['bottle gourd curry', 'lauki curry', 'sorakaya koora', 'suraikkai kootu', 'anapakaya curry'], 'indian', NULL, 1, '90 cal per serving (~200g). Very mild, cooling curry. Ayurvedic digestive. Extremely low calorie.', true, 35, 0, 0.3, 0.0, 120, 20, 0.5, 8, 8.0, 0, 10, 0.2, 15, 0.3, 0.01),

('potlakaya_curry', 'Potlakaya Curry (Snake Gourd Curry)', 50.0, 1.5, 5.5, 2.5, 1.2, 1.5, 200, NULL, 'indian_traditional', ARRAY['snake gourd curry', 'potlakaya koora', 'pudalangai kootu', 'padwal curry', 'chichinda sabzi'], 'indian', NULL, 1, '100 cal per serving (~200g). Light, mild curry. Often cooked with coconut or dal. Good for weight loss.', true, 35, 0, 0.3, 0.0, 130, 26, 0.6, 10, 4.0, 0, 12, 0.3, 20, 0.3, 0.01),

('chikkudukaya_curry', 'Chikkudukaya Curry (Broad Beans Curry)', 80.0, 5.5, 10.0, 2.0, 3.5, 1.0, 200, NULL, 'indian_traditional', ARRAY['broad beans curry', 'chikkudukaya koora', 'avarakkai kootu', 'sem ki sabzi', 'indian broad beans fry'], 'indian', NULL, 1, '160 cal per serving (~200g). Protein-rich legume curry. Often stir-fried with onions and spices.', true, 45, 0, 0.3, 0.0, 220, 25, 1.5, 12, 8.0, 0, 28, 0.8, 65, 1.0, 0.01),

('aratikaya_curry', 'Aratikaya Curry (Raw Banana Curry)', 100.0, 1.2, 18.0, 2.5, 2.0, 3.0, 200, NULL, 'indian_traditional', ARRAY['raw banana curry', 'green banana curry', 'aratikaya koora', 'vazhakkai curry', 'kaccha kela sabzi', 'plantain curry'], 'indian', NULL, 1, '200 cal per serving (~200g). Starchy, filling curry. Raw plantain with spices. Good source of potassium.', true, 55, 0, 0.4, 0.0, 350, 8, 0.6, 10, 15.0, 0, 32, 0.2, 28, 1.0, 0.01),

('menthi_kura', 'Menthi Kura (Fenugreek Leaves Curry)', 75.0, 3.5, 6.0, 4.0, 2.5, 0.8, 150, NULL, 'indian_traditional', ARRAY['fenugreek leaves curry', 'methi sabzi', 'menthi aaku koora', 'venthiya keerai', 'methi leaves stir fry'], 'indian', NULL, 1, '113 cal per serving (~150g). Bitter-savory stir-fry. Rich in iron. Often cooked with potatoes or dal.', true, 50, 0, 0.5, 0.0, 260, 55, 4.5, 180, 6.0, 0, 35, 0.6, 42, 0.5, 0.02),

('gongura_pappu', 'Gongura Pappu (Sorrel Leaves Dal)', 90.0, 5.0, 11.0, 2.8, 2.0, 1.0, 200, NULL, 'indian_traditional', ARRAY['gongura dal', 'gongura pappu andhra', 'pulicha keerai dal', 'sorrel lentil curry', 'gongura toor dal'], 'indian', NULL, 1, '180 cal per serving (~200g). Toor dal cooked with tangy gongura leaves. Signature Andhra comfort food.', true, 50, 0, 0.4, 0.0, 280, 40, 2.5, 120, 10.0, 0, 30, 0.8, 95, 2.0, 0.01),

('mudda_pappu', 'Mudda Pappu (Plain Toor Dal)', 116.0, 7.2, 20.8, 0.4, 3.5, 0.5, 200, NULL, 'indian_traditional', ARRAY['plain toor dal', 'arhar dal', 'mudda pappu andhra', 'parippu', 'toor dal boiled', 'kandi pappu'], 'indian', NULL, 1, '232 cal per serving (~200g). Simply boiled toor dal mashed with salt. Eaten with rice + ghee. Telugu daily staple.', true, 8, 0, 0.1, 0.0, 380, 30, 1.8, 5, 0.0, 0, 35, 1.2, 160, 4.0, 0.01),

('pesarattu', 'Pesarattu (Green Moong Dosa)', 166.0, 8.5, 22.0, 5.0, 2.5, 0.5, 120, 120, 'indian_traditional', ARRAY['green moong dosa', 'pesarattu andhra', 'pesara dosa', 'moong dal dosa', 'green gram crepe', 'pesara attu'], 'indian', NULL, 1, '199 cal per pesarattu (~120g). Andhra signature breakfast. Whole green moong batter crepe. Protein-rich.', true, 15, 0, 0.7, 0.0, 260, 35, 2.0, 8, 1.5, 0, 48, 1.2, 130, 3.0, 0.02),

('natu_kodi_pulusu', 'Natu Kodi Pulusu (Country Chicken Curry)', 135.0, 14.0, 4.0, 7.0, 0.5, 1.0, 250, NULL, 'indian_traditional', ARRAY['country chicken curry', 'natu kodi kura', 'desi chicken curry', 'naatu kozhi kulambu', 'natukodi pulusu andhra'], 'indian', NULL, 1, '338 cal per serving (~250g). Free-range chicken in tangy tamarind gravy. Bone-in, lean. Andhra village specialty.', true, 180, 85, 1.8, 0.0, 250, 18, 1.5, 25, 3.0, 5, 22, 2.0, 170, 18.0, 0.05),

('chepala_pulusu', 'Chepala Pulusu (Andhra Fish Curry)', 105.0, 14.0, 4.5, 3.5, 0.5, 1.5, 250, NULL, 'indian_traditional', ARRAY['fish curry andhra', 'chepala pulusu', 'meen kulambu telugu', 'fish tamarind curry', 'chepala iguru'], 'indian', NULL, 1, '263 cal per serving (~250g). River fish in spicy tamarind gravy. Godavari district specialty. Rich in omega-3.', true, 250, 55, 0.7, 0.0, 320, 35, 1.8, 18, 4.0, 40, 30, 0.8, 200, 30.0, 0.30),

('royyala_iguru', 'Royyala Iguru (Prawn Curry)', 120.0, 15.0, 4.0, 5.0, 0.5, 1.0, 200, NULL, 'indian_traditional', ARRAY['prawn curry andhra', 'royyala kura', 'shrimp curry telugu', 'prawns masala', 'royyalu iguru andhra'], 'indian', NULL, 1, '240 cal per serving (~200g). Prawns in dry spicy masala. Coastal Andhra classic. High protein, low carb.', true, 350, 150, 1.0, 0.0, 220, 55, 2.0, 15, 2.0, 5, 32, 1.5, 250, 35.0, 0.25),

-- =====================================================================
-- RICE VARIETIES (6 items)
-- =====================================================================

('pulihora', 'Pulihora (Tamarind Rice)', 160.0, 3.0, 26.0, 5.0, 1.0, 2.0, 200, NULL, 'indian_traditional', ARRAY['tamarind rice', 'chintapandu pulihora', 'puliyodarai', 'puli sadam', 'pulihora andhra'], 'indian', NULL, 1, '320 cal per serving (~200g). Temple prasadam classic. Rice + tamarind paste + peanuts + spices. Andhra festive staple.', true, 280, 0, 0.8, 0.0, 120, 18, 1.0, 5, 3.0, 0, 18, 0.5, 55, 3.0, 0.01),

('nimmakaya_pulihora', 'Nimmakaya Pulihora (Lemon Rice)', 155.0, 2.8, 25.0, 5.0, 0.8, 0.5, 200, NULL, 'indian_traditional', ARRAY['lemon rice', 'nimmakaya annam', 'elumichai sadam', 'chitranna', 'nimbe bath'], 'indian', NULL, 1, '310 cal per serving (~200g). Light, tangy rice with lemon juice, turmeric, peanuts, curry leaves.', true, 200, 0, 0.7, 0.0, 110, 12, 0.8, 3, 12.0, 0, 15, 0.4, 50, 2.5, 0.01),

('kobbari_annam', 'Kobbari Annam (Coconut Rice)', 185.0, 3.0, 24.0, 8.5, 1.5, 1.5, 200, NULL, 'indian_traditional', ARRAY['coconut rice', 'kobbari annam andhra', 'thengai sadam', 'nariyal chawal'], 'indian', NULL, 1, '370 cal per serving (~200g). Rice mixed with fresh grated coconut, tempered with mustard + curry leaves.', true, 30, 0, 6.5, 0.0, 140, 10, 0.8, 0, 1.0, 0, 20, 0.5, 60, 3.0, 0.01),

('perugu_annam', 'Perugu Annam (Curd Rice)', 100.0, 3.5, 16.0, 2.0, 0.3, 2.0, 250, NULL, 'indian_traditional', ARRAY['curd rice', 'dahi chawal', 'thayir sadam', 'perugu annam andhra', 'mosaranna'], 'indian', NULL, 1, '250 cal per serving (~250g). Cool, soothing rice + yogurt. End-of-meal staple. Probiotic-rich. Tempered with mustard.', true, 40, 5, 1.2, 0.0, 130, 60, 0.3, 10, 0.5, 2, 12, 0.4, 70, 2.5, 0.01),

('pappu_annam', 'Pappu Annam (Dal Rice)', 130.0, 5.0, 20.0, 3.0, 1.5, 0.5, 250, NULL, 'indian_traditional', ARRAY['dal rice', 'pappu annam andhra', 'paruppu sadam', 'dal chawal', 'pappu bhat'], 'indian', NULL, 1, '325 cal per serving (~250g). Rice mixed with toor dal + ghee + cumin. Comfort food. First course of Telugu meal.', true, 15, 5, 1.5, 0.0, 200, 22, 1.2, 8, 0.0, 2, 22, 0.8, 100, 3.0, 0.01),

('tomato_annam', 'Tomato Annam (Tomato Rice)', 145.0, 2.8, 22.0, 5.0, 1.0, 2.5, 200, NULL, 'indian_traditional', ARRAY['tomato rice', 'tomato pulihora', 'thakkali sadam', 'tomato bath', 'tomato annam andhra'], 'indian', NULL, 1, '290 cal per serving (~200g). Rice cooked with tomato paste, onions, peanuts, spices. Quick one-pot meal.', true, 220, 0, 0.7, 0.0, 180, 15, 1.0, 35, 10.0, 0, 15, 0.4, 48, 2.5, 0.01),

-- =====================================================================
-- SNACKS / SWEETS (6 items)
-- =====================================================================

('sakinalu', 'Sakinalu (Telangana Rice Snack)', 465.0, 6.0, 60.0, 22.0, 2.0, 1.0, 30, 30, 'indian_traditional', ARRAY['sakinalu snack', 'sakkinalu', 'chekka sakinalu', 'rice flour snack telangana', 'sankranti sakinalu'], 'indian', NULL, 2, '140 cal per piece (~30g). Deep-fried concentric rice flour rings with sesame. Sankranti festival special.', true, 180, 0, 3.0, 0.1, 80, 40, 1.5, 1, 0.0, 0, 25, 0.8, 60, 3.0, 0.02),

('janthikalu', 'Janthikalu (Andhra Savory Snack)', 530.0, 8.0, 52.0, 32.0, 2.5, 1.5, 30, NULL, 'indian_traditional', ARRAY['janthikalu snack', 'chakli andhra', 'murukku andhra', 'tenkaya janthikalu', 'gavvalu shape snack'], 'indian', NULL, 1, '159 cal per serving (~30g). Deep-fried spiral snack from rice + urad dal flour. Crunchy, aromatic.', true, 250, 0, 5.0, 0.2, 70, 18, 1.5, 1, 0.0, 0, 20, 0.6, 50, 2.5, 0.01),

('ariselu', 'Ariselu (Rice Jaggery Sweet)', 340.0, 2.5, 55.0, 12.0, 0.8, 30.0, 50, 50, 'indian_traditional', ARRAY['ariselu sweet', 'adhirasam', 'anarsa', 'rice jaggery disc', 'ariselu sankranti', 'bellam ariselu'], 'indian', NULL, 1, '170 cal per piece (~50g). Deep-fried rice flour + jaggery disc. Sankranti festival sweet. Long shelf life.', true, 15, 0, 2.0, 0.1, 100, 30, 1.5, 1, 0.0, 0, 18, 0.4, 40, 1.5, 0.01),

('bobbatlu', 'Bobbatlu (Puran Poli / Sweet Stuffed Flatbread)', 298.0, 6.0, 50.0, 8.0, 2.5, 22.0, 80, 80, 'indian_traditional', ARRAY['puran poli', 'obbattu', 'holige', 'boorelu', 'bobbatlu andhra', 'paruppu poli'], 'indian', NULL, 1, '238 cal per piece (~80g). Stuffed flatbread with chana dal + jaggery filling. Festival sweet across Telugu states.', true, 10, 5, 3.5, 0.0, 150, 25, 1.5, 8, 0.5, 0, 22, 0.8, 75, 2.0, 0.01),

('bellam_undalu', 'Bellam Undalu (Jaggery Sesame Balls)', 430.0, 8.0, 48.0, 24.0, 3.5, 32.0, 25, 25, 'indian_traditional', ARRAY['jaggery sesame balls', 'nuvvula undalu', 'til laddu', 'ellu urundai', 'chimmili', 'nuvvula bellam undalu'], 'indian', NULL, 2, '108 cal per ball (~25g). Roasted sesame + jaggery balls. Rich in calcium and iron. Sankranti special.', true, 5, 0, 3.2, 0.0, 200, 450, 6.5, 2, 0.0, 0, 100, 3.5, 280, 4.0, 0.08),

('gavvalu', 'Gavvalu (Shell-Shaped Sweet Snack)', 380.0, 4.0, 52.0, 17.0, 0.5, 18.0, 30, NULL, 'indian_traditional', ARRAY['gavvalu snack', 'bellam gavvalu', 'shell snack telugu', 'jaggery shell sweet', 'gavvalu sankranti'], 'indian', NULL, 1, '114 cal per serving (~30g). Tiny shell-shaped sweet made from maida + jaggery, deep-fried. Crunchy texture.', true, 20, 0, 3.0, 0.1, 50, 15, 0.8, 0, 0.0, 0, 10, 0.2, 25, 1.0, 0.01),

-- =====================================================================
-- ADDITIONAL: Idli Milagai Podi (completes the podi set)
-- =====================================================================

('idli_milagai_podi', 'Idli Milagai Podi (Lentil Spice Powder)', 400.0, 21.0, 38.0, 18.0, 7.0, 2.0, 10, NULL, 'indian_traditional', ARRAY['idli podi', 'milagai podi', 'gun powder south indian', 'molagapodi', 'idli chutney powder', 'paruppu podi'], 'indian', NULL, 1, '40 cal per tsp (~10g). Roasted urad dal + chana dal + red chillies + sesame. Mix with oil for idli/dosa. Protein-packed.', true, 55, 0, 2.5, 0.0, 380, 90, 4.5, 60, 1.0, 0, 95, 2.2, 220, 8.5, 0.03)

ON CONFLICT (food_name_normalized) DO NOTHING;
