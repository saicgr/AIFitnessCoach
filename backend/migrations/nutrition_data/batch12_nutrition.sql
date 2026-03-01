-- ============================================================================
-- Batch 12: Korean Restaurant Chains
-- Restaurants: Bibibop, Cupbop, Gen Korean BBQ, KPOT, Two Hands Corn Dogs, KyoChon
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. BIBIBOP ASIAN GRILL (~73 US locations)
-- Source: bibibop.com/nutrition, nutritionix.com
-- ============================================================================

-- Purple Rice Base: 170 cal, 4g protein, 36g carbs, 0.5g fat per 200g
('bibibop_purple_rice', 'Bibibop Purple Rice', 85.0, 2.0, 18.0, 0.3, 0.5, 0.0, NULL, 200, 'bibibop.com', ARRAY['bibibop rice', 'bibibop purple rice base'], '170 cal per 200g base. Purple multigrain rice.', 'Bibibop', 'korean', 1),

-- Japchae Noodles Base: 210 cal, 3g protein, 44g carbs, 3g fat per 200g
('bibibop_japchae_noodles', 'Bibibop Japchae Noodles', 105.0, 1.5, 22.0, 1.5, 0.5, 3.0, NULL, 200, 'bibibop.com', ARRAY['bibibop noodles', 'bibibop glass noodles'], '210 cal per 200g base. Sweet potato glass noodles.', 'Bibibop', 'korean', 1),

-- Chicken: 150 cal, 28g protein, 2g carbs, 3g fat per 120g
('bibibop_chicken', 'Bibibop Grilled Chicken', 125.0, 23.3, 1.7, 2.5, 0.0, 0.5, NULL, 120, 'bibibop.com', ARRAY['bibibop chicken protein', 'bibibop grilled chicken'], '150 cal per 120g serving. Grilled marinated chicken.', 'Bibibop', 'korean', 1),

-- Steak: 200 cal, 26g protein, 2g carbs, 9g fat per 120g
('bibibop_steak', 'Bibibop Grilled Steak', 166.7, 21.7, 1.7, 7.5, 0.0, 0.5, NULL, 120, 'bibibop.com', ARRAY['bibibop beef', 'bibibop steak protein'], '200 cal per 120g serving.', 'Bibibop', 'korean', 1),

-- Spicy Pork: 220 cal, 22g protein, 5g carbs, 12g fat per 120g
('bibibop_spicy_pork', 'Bibibop Spicy Pork', 183.3, 18.3, 4.2, 10.0, 0.0, 3.0, NULL, 120, 'bibibop.com', ARRAY['bibibop pork', 'bibibop gochujang pork'], '220 cal per 120g serving. Gochujang marinated pork.', 'Bibibop', 'korean', 1),

-- Tofu: 120 cal, 12g protein, 4g carbs, 6g fat per 120g
('bibibop_tofu', 'Bibibop Sesame Tofu', 100.0, 10.0, 3.3, 5.0, 0.5, 0.5, NULL, 120, 'bibibop.com', ARRAY['bibibop tofu protein'], '120 cal per 120g serving.', 'Bibibop', 'korean', 1),

-- Kimchi: 15 cal, 1g protein, 2g carbs, 0g fat per 40g
('bibibop_kimchi', 'Bibibop Kimchi', 37.5, 2.5, 5.0, 0.0, 1.5, 1.5, NULL, 40, 'bibibop.com', ARRAY['bibibop kimchi topping'], '15 cal per 40g serving.', 'Bibibop', 'korean', 1),

-- Complete Bowl (chicken + rice + veggies): 550 cal, 38g protein, 62g carbs, 14g fat per 450g
('bibibop_chicken_bowl', 'Bibibop Chicken Bowl', 122.2, 8.4, 13.8, 3.1, 1.5, 1.5, NULL, 450, 'bibibop.com', ARRAY['bibibop bowl', 'bibibop chicken rice bowl'], '550 cal per 450g complete bowl with chicken, rice, vegetables, egg.', 'Bibibop', 'korean', 1),

-- ============================================================================
-- 2. CUPBOP (~70 US locations)
-- Source: cupbop.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Bulgogi Beef Cup: 480 cal, 24g protein, 52g carbs, 18g fat per 350g
('cupbop_bulgogi_beef', 'Cupbop Bulgogi Beef', 137.1, 6.9, 14.9, 5.1, 0.5, 4.0, NULL, 350, 'cupbop.com', ARRAY['cupbop beef', 'cupbop bulgogi'], '480 cal per 350g cup. Korean BBQ beef over rice with vegetables.', 'Cupbop', 'korean', 1),

-- Spicy Pork Cup: 500 cal, 22g protein, 54g carbs, 20g fat per 350g
('cupbop_spicy_pork', 'Cupbop Spicy Pork', 142.9, 6.3, 15.4, 5.7, 0.5, 4.5, NULL, 350, 'cupbop.com', ARRAY['cupbop pork', 'cupbop gochujang pork'], '500 cal per 350g cup. Gochujang marinated pork over rice.', 'Cupbop', 'korean', 1),

-- Chicken Teriyaki Cup: 450 cal, 26g protein, 50g carbs, 14g fat per 350g
('cupbop_chicken_teriyaki', 'Cupbop Chicken Teriyaki', 128.6, 7.4, 14.3, 4.0, 0.5, 5.0, NULL, 350, 'cupbop.com', ARRAY['cupbop chicken', 'cupbop teriyaki chicken'], '450 cal per 350g cup.', 'Cupbop', 'korean', 1),

-- Tofu Cup: 380 cal, 16g protein, 50g carbs, 12g fat per 350g
('cupbop_tofu', 'Cupbop Tofu Cup', 108.6, 4.6, 14.3, 3.4, 1.0, 3.0, NULL, 350, 'cupbop.com', ARRAY['cupbop tofu', 'cupbop vegetarian'], '380 cal per 350g cup.', 'Cupbop', 'korean', 1),

-- Korean Fried Chicken Cup: 550 cal, 25g protein, 55g carbs, 24g fat per 350g
('cupbop_fried_chicken', 'Cupbop Korean Fried Chicken', 157.1, 7.1, 15.7, 6.9, 0.3, 3.5, NULL, 350, 'cupbop.com', ARRAY['cupbop kfc', 'cupbop crispy chicken'], '550 cal per 350g cup. Crispy fried chicken with sweet-spicy sauce.', 'Cupbop', 'korean', 1),

-- ============================================================================
-- 3. GEN KOREAN BBQ HOUSE (~40 US locations)
-- Source: genkoreanbbq.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Prime Beef Bulgogi: 280 cal, 22g protein, 8g carbs, 18g fat per 150g
('gen_prime_bulgogi', 'Gen Korean BBQ Prime Bulgogi', 186.7, 14.7, 5.3, 12.0, 0.0, 4.0, NULL, 150, 'genkoreanbbq.com', ARRAY['gen bbq bulgogi', 'gen korean bulgogi'], '280 cal per 150g plate. Thinly sliced marinated prime beef.', 'Gen Korean BBQ', 'korean', 1),

-- Pork Belly (Samgyeopsal): 420 cal, 15g protein, 0g carbs, 40g fat per 150g
('gen_pork_belly', 'Gen Korean BBQ Pork Belly', 280.0, 10.0, 0.0, 26.7, 0.0, 0.0, NULL, 150, 'genkoreanbbq.com', ARRAY['gen bbq pork belly', 'gen samgyeopsal'], '420 cal per 150g plate. Thick-cut unmarinated pork belly.', 'Gen Korean BBQ', 'korean', 1),

-- Spicy Chicken: 240 cal, 25g protein, 6g carbs, 12g fat per 150g
('gen_spicy_chicken', 'Gen Korean BBQ Spicy Chicken', 160.0, 16.7, 4.0, 8.0, 0.0, 3.0, NULL, 150, 'genkoreanbbq.com', ARRAY['gen bbq spicy chicken', 'gen korean chicken'], '240 cal per 150g plate. Gochujang marinated chicken.', 'Gen Korean BBQ', 'korean', 1),

-- Beef Short Rib (Galbi): 350 cal, 20g protein, 5g carbs, 28g fat per 150g
('gen_beef_galbi', 'Gen Korean BBQ Beef Short Rib', 233.3, 13.3, 3.3, 18.7, 0.0, 3.0, NULL, 150, 'genkoreanbbq.com', ARRAY['gen bbq galbi', 'gen korean short rib', 'gen kalbi'], '350 cal per 150g plate. Marinated beef short rib.', 'Gen Korean BBQ', 'korean', 1),

-- Garlic Shrimp: 200 cal, 20g protein, 5g carbs, 11g fat per 130g
('gen_garlic_shrimp', 'Gen Korean BBQ Garlic Shrimp', 153.8, 15.4, 3.8, 8.5, 0.0, 1.0, NULL, 130, 'genkoreanbbq.com', ARRAY['gen bbq shrimp', 'gen korean shrimp'], '200 cal per 130g plate.', 'Gen Korean BBQ', 'korean', 1),

-- Japchae (side): 180 cal, 3g protein, 30g carbs, 5g fat per 150g
('gen_japchae', 'Gen Korean BBQ Japchae', 120.0, 2.0, 20.0, 3.3, 1.0, 4.0, NULL, 150, 'genkoreanbbq.com', ARRAY['gen bbq japchae', 'gen glass noodles'], '180 cal per 150g side.', 'Gen Korean BBQ', 'korean', 1),

-- Kimchi Fried Rice: 380 cal, 10g protein, 52g carbs, 14g fat per 300g
('gen_kimchi_fried_rice', 'Gen Korean BBQ Kimchi Fried Rice', 126.7, 3.3, 17.3, 4.7, 0.5, 2.0, NULL, 300, 'genkoreanbbq.com', ARRAY['gen bbq fried rice', 'gen kimchi rice'], '380 cal per 300g serving.', 'Gen Korean BBQ', 'korean', 1),

-- ============================================================================
-- 4. KPOT KOREAN BBQ & HOT POT (~130 US locations)
-- Source: kpot.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Beef Bulgogi Plate: 300 cal, 24g protein, 6g carbs, 20g fat per 150g
('kpot_beef_bulgogi', 'KPOT Beef Bulgogi', 200.0, 16.0, 4.0, 13.3, 0.0, 3.0, NULL, 150, 'kpot.com', ARRAY['kpot bulgogi', 'kpot beef'], '300 cal per 150g plate.', 'KPOT', 'korean', 1),

-- Pork Belly: 400 cal, 14g protein, 0g carbs, 38g fat per 150g
('kpot_pork_belly', 'KPOT Pork Belly', 266.7, 9.3, 0.0, 25.3, 0.0, 0.0, NULL, 150, 'kpot.com', ARRAY['kpot pork belly', 'kpot samgyeopsal'], '400 cal per 150g plate.', 'KPOT', 'korean', 1),

-- Spicy Broth Hot Pot (broth only): 80 cal, 4g protein, 8g carbs, 3g fat per 500g
('kpot_spicy_broth', 'KPOT Spicy Hot Pot Broth', 16.0, 0.8, 1.6, 0.6, 0.2, 0.5, NULL, 500, 'kpot.com', ARRAY['kpot spicy broth', 'kpot hot pot base'], '80 cal per 500g broth serving.', 'KPOT', 'korean', 1),

-- Tonkotsu Broth Hot Pot (broth only): 120 cal, 6g protein, 4g carbs, 8g fat per 500g
('kpot_tonkotsu_broth', 'KPOT Tonkotsu Hot Pot Broth', 24.0, 1.2, 0.8, 1.6, 0.0, 0.3, NULL, 500, 'kpot.com', ARRAY['kpot pork broth', 'kpot tonkotsu hot pot'], '120 cal per 500g broth serving.', 'KPOT', 'korean', 1),

-- Beef Short Rib: 380 cal, 22g protein, 4g carbs, 30g fat per 150g
('kpot_short_rib', 'KPOT Beef Short Rib', 253.3, 14.7, 2.7, 20.0, 0.0, 2.0, NULL, 150, 'kpot.com', ARRAY['kpot galbi', 'kpot short rib'], '380 cal per 150g plate.', 'KPOT', 'korean', 1),

-- ============================================================================
-- 5. TWO HANDS CORN DOGS (~70 US locations)
-- Source: twohandscorndogs.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Original Corn Dog: 320 cal, 12g protein, 32g carbs, 16g fat per 150g
('two_hands_original', 'Two Hands Original Corn Dog', 213.3, 8.0, 21.3, 10.7, 0.5, 4.0, 150, 150, 'twohandscorndogs.com', ARRAY['two hands corn dog', 'two hands original', 'korean corn dog'], '320 cal per dog (150g). Korean-style corn dog with crispy batter.', 'Two Hands Corn Dogs', 'korean', 1),

-- Mozzarella Corn Dog: 380 cal, 15g protein, 34g carbs, 20g fat per 170g
('two_hands_mozzarella', 'Two Hands Mozzarella Corn Dog', 223.5, 8.8, 20.0, 11.8, 0.3, 3.5, 170, 170, 'twohandscorndogs.com', ARRAY['two hands cheese corn dog', 'two hands mozz', 'korean cheese corn dog'], '380 cal per dog (170g). Stretchy mozzarella filling.', 'Two Hands Corn Dogs', 'korean', 1),

-- Half & Half (sausage + mozzarella): 350 cal, 14g protein, 33g carbs, 18g fat per 160g
('two_hands_half_half', 'Two Hands Half & Half Corn Dog', 218.8, 8.8, 20.6, 11.3, 0.3, 3.5, 160, 160, 'twohandscorndogs.com', ARRAY['two hands half and half', 'korean half half corn dog'], '350 cal per dog (160g). Half sausage, half mozzarella.', 'Two Hands Corn Dogs', 'korean', 1),

-- Potato Corn Dog: 400 cal, 12g protein, 42g carbs, 20g fat per 180g
('two_hands_potato', 'Two Hands Potato Corn Dog', 222.2, 6.7, 23.3, 11.1, 0.5, 3.0, 180, 180, 'twohandscorndogs.com', ARRAY['two hands potato', 'korean potato corn dog'], '400 cal per dog (180g). Coated with crispy french fry pieces.', 'Two Hands Corn Dogs', 'korean', 1),

-- ============================================================================
-- 6. KYOCHON CHICKEN (~10 US locations)
-- Source: kyochon.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Original Fried Chicken (4 pcs): 680 cal, 48g protein, 28g carbs, 42g fat per 320g
('kyochon_original', 'KyoChon Original Fried Chicken', 212.5, 15.0, 8.8, 13.1, 0.0, 1.0, 80, 320, 'kyochon.com', ARRAY['kyochon original chicken', 'kyochon fried chicken'], '680 cal per 4 pieces (320g). Double-fried Korean fried chicken.', 'KyoChon', 'korean', 4),

-- Honey Chicken (4 pcs): 740 cal, 46g protein, 38g carbs, 44g fat per 340g
('kyochon_honey', 'KyoChon Honey Chicken', 217.6, 13.5, 11.2, 12.9, 0.0, 6.0, 85, 340, 'kyochon.com', ARRAY['kyochon honey chicken', 'kyochon honey glazed'], '740 cal per 4 pieces (340g). Signature honey-glazed fried chicken.', 'KyoChon', 'korean', 4),

-- Red Pepper Chicken (4 pcs): 700 cal, 47g protein, 32g carbs, 42g fat per 320g
('kyochon_red_pepper', 'KyoChon Red Pepper Chicken', 218.8, 14.7, 10.0, 13.1, 0.5, 3.0, 80, 320, 'kyochon.com', ARRAY['kyochon spicy chicken', 'kyochon red pepper'], '700 cal per 4 pieces (320g). Spicy red pepper sauce glazed.', 'KyoChon', 'korean', 4),

-- Soy Garlic Wings (8 pcs): 520 cal, 36g protein, 18g carbs, 34g fat per 280g
('kyochon_soy_garlic_wings', 'KyoChon Soy Garlic Wings', 185.7, 12.9, 6.4, 12.1, 0.0, 3.0, 35, 280, 'kyochon.com', ARRAY['kyochon wings', 'kyochon soy garlic'], '520 cal per 8 wings (280g). Sweet soy garlic glazed wings.', 'KyoChon', 'korean', 8),

-- Tteokbokki: 350 cal, 8g protein, 52g carbs, 12g fat per 250g
('kyochon_tteokbokki', 'KyoChon Tteokbokki', 140.0, 3.2, 20.8, 4.8, 0.5, 5.0, NULL, 250, 'kyochon.com', ARRAY['kyochon rice cakes', 'kyochon spicy rice cakes'], '350 cal per 250g serving. Spicy stir-fried rice cakes.', 'KyoChon', 'korean', 1)
