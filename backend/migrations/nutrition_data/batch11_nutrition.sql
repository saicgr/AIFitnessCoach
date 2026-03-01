-- ============================================================================
-- Batch 11: Japanese Restaurant Chains
-- Restaurants: Gyu-Kaku, JINYA Ramen Bar, Kura Sushi, Wagamama, Ippudo
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, calorieking.com, myfitnesspal.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. GYU-KAKU JAPANESE BBQ (~57 US locations)
-- Source: gyu-kaku.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Harami (Outside Skirt) - Signature BBQ cut: 250 cal, 20g protein, 0g carbs, 18g fat per 150g
('gyukaku_harami_skirt', 'Gyu-Kaku Harami Skirt Steak', 166.7, 13.3, 0.0, 12.0, 0.0, 0.0, NULL, 150, 'gyukaku.com', ARRAY['gyu kaku harami', 'gyukaku skirt steak', 'gyu-kaku harami'], '250 cal per 150g plate. Signature outside skirt, thinly sliced for grilling.', 'Gyu-Kaku', 'japanese', 1),

-- Toro Kalbi (Premium Short Rib): 310 cal, 18g protein, 3g carbs, 25g fat per 150g
('gyukaku_toro_kalbi', 'Gyu-Kaku Toro Kalbi', 206.7, 12.0, 2.0, 16.7, 0.0, 1.5, NULL, 150, 'gyukaku.com', ARRAY['gyu kaku short rib', 'gyukaku kalbi', 'gyu-kaku toro kalbi', 'premium short rib'], '310 cal per 150g plate. Marinated premium beef short rib.', 'Gyu-Kaku', 'japanese', 1),

-- Misoyaki Chicken Thigh: 220 cal, 22g protein, 5g carbs, 12g fat per 150g
('gyukaku_misoyaki_chicken', 'Gyu-Kaku Misoyaki Chicken', 146.7, 14.7, 3.3, 8.0, 0.0, 2.5, NULL, 150, 'gyukaku.com', ARRAY['gyu kaku miso chicken', 'gyukaku chicken thigh'], '220 cal per 150g serving. Miso-marinated chicken thigh.', 'Gyu-Kaku', 'japanese', 1),

-- Garlic Shrimp: 180 cal, 18g protein, 4g carbs, 10g fat per 120g
('gyukaku_garlic_shrimp', 'Gyu-Kaku Garlic Shrimp', 150.0, 15.0, 3.3, 8.3, 0.0, 0.5, NULL, 120, 'gyukaku.com', ARRAY['gyu kaku shrimp', 'gyukaku garlic shrimp'], '180 cal per 120g plate.', 'Gyu-Kaku', 'japanese', 1),

-- Spicy Pork Belly: 350 cal, 15g protein, 5g carbs, 30g fat per 150g
('gyukaku_spicy_pork_belly', 'Gyu-Kaku Spicy Pork Belly', 233.3, 10.0, 3.3, 20.0, 0.0, 2.0, NULL, 150, 'gyukaku.com', ARRAY['gyu kaku pork belly', 'gyukaku spicy pork'], '350 cal per 150g plate. Gochujang-marinated pork belly.', 'Gyu-Kaku', 'japanese', 1),

-- Edamame: 120 cal, 11g protein, 9g carbs, 5g fat per 100g
('gyukaku_edamame', 'Gyu-Kaku Edamame', 120.0, 11.0, 9.0, 5.0, 4.0, 2.0, NULL, 150, 'gyukaku.com', ARRAY['gyu kaku edamame'], '180 cal per 150g serving.', 'Gyu-Kaku', 'japanese', 1),

-- Beef Tongue (Gyutan): 270 cal, 22g protein, 0g carbs, 20g fat per 120g
('gyukaku_beef_tongue', 'Gyu-Kaku Beef Tongue', 225.0, 18.3, 0.0, 16.7, 0.0, 0.0, NULL, 120, 'gyukaku.com', ARRAY['gyu kaku gyutan', 'gyukaku tongue', 'gyu-kaku beef tongue'], '270 cal per 120g plate. Thinly sliced grilled beef tongue.', 'Gyu-Kaku', 'japanese', 1),

-- Japanese Fried Rice (Garlic): 380 cal, 10g protein, 52g carbs, 14g fat per 250g
('gyukaku_garlic_fried_rice', 'Gyu-Kaku Garlic Fried Rice', 152.0, 4.0, 20.8, 5.6, 0.5, 1.0, NULL, 250, 'gyukaku.com', ARRAY['gyu kaku fried rice', 'gyukaku fried rice'], '380 cal per 250g serving.', 'Gyu-Kaku', 'japanese', 1),

-- S''mores: 320 cal, 4g protein, 48g carbs, 13g fat per 120g
('gyukaku_smores', 'Gyu-Kaku S''mores', 266.7, 3.3, 40.0, 10.8, 0.5, 28.0, NULL, 120, 'gyukaku.com', ARRAY['gyu kaku smores', 'gyukaku dessert smores'], '320 cal per 120g serving. Grilled marshmallow with chocolate and graham.', 'Gyu-Kaku', 'desserts', 1),

-- Yuzu Kosho Chicken: 200 cal, 24g protein, 3g carbs, 10g fat per 150g
('gyukaku_yuzu_kosho_chicken', 'Gyu-Kaku Yuzu Kosho Chicken', 133.3, 16.0, 2.0, 6.7, 0.0, 1.0, NULL, 150, 'gyukaku.com', ARRAY['gyu kaku yuzu chicken', 'gyukaku yuzu kosho'], '200 cal per 150g serving. Citrus pepper marinated chicken.', 'Gyu-Kaku', 'japanese', 1),

-- ============================================================================
-- 2. JINYA RAMEN BAR (~77 US locations)
-- Source: jinyaramenbar.com, nutritionix.com, calorieking.com
-- ============================================================================

-- Tonkotsu Black: 820 cal, 35g protein, 80g carbs, 40g fat per 700g
('jinya_tonkotsu_black', 'JINYA Tonkotsu Black Ramen', 117.1, 5.0, 11.4, 5.7, 0.7, 1.5, NULL, 700, 'jinyaramenbar.com', ARRAY['jinya tonkotsu', 'jinya black ramen', 'jinya pork ramen'], '820 cal per 700g bowl. Rich pork broth with chashu, kikurage, nori, garlic chips.', 'JINYA Ramen Bar', 'japanese', 1),

-- Chicken Ramen: 680 cal, 30g protein, 75g carbs, 28g fat per 700g
('jinya_chicken_ramen', 'JINYA Chicken Ramen', 97.1, 4.3, 10.7, 4.0, 0.5, 1.0, NULL, 700, 'jinyaramenbar.com', ARRAY['jinya chicken broth ramen', 'jinya tori ramen'], '680 cal per 700g bowl. Chicken broth with chashu, spinach, green onion.', 'JINYA Ramen Bar', 'japanese', 1),

-- Spicy Creamy Vegan Ramen: 750 cal, 18g protein, 85g carbs, 36g fat per 700g
('jinya_spicy_vegan_ramen', 'JINYA Spicy Creamy Vegan Ramen', 107.1, 2.6, 12.1, 5.1, 1.5, 2.0, NULL, 700, 'jinyaramenbar.com', ARRAY['jinya vegan ramen', 'jinya spicy vegan'], '750 cal per 700g bowl. Creamy vegetable broth with tofu, corn, bean sprouts.', 'JINYA Ramen Bar', 'japanese', 1),

-- Pork Gyoza: 280 cal, 12g protein, 24g carbs, 15g fat per 150g (6 pcs)
('jinya_pork_gyoza', 'JINYA Pork Gyoza', 186.7, 8.0, 16.0, 10.0, 0.5, 1.0, 25, 150, 'jinyaramenbar.com', ARRAY['jinya gyoza', 'jinya dumplings', 'jinya potstickers'], '280 cal per 6 pieces (150g). Pan-fried pork dumplings.', 'JINYA Ramen Bar', 'japanese', 6),

-- Chicken Karaage: 350 cal, 22g protein, 18g carbs, 20g fat per 160g
('jinya_chicken_karaage', 'JINYA Chicken Karaage', 218.8, 13.8, 11.3, 12.5, 0.3, 1.0, NULL, 160, 'jinyaramenbar.com', ARRAY['jinya karaage', 'jinya fried chicken'], '350 cal per 160g serving. Japanese fried chicken with garlic soy marinade.', 'JINYA Ramen Bar', 'japanese', 1),

-- Crispy Rice with Spicy Tuna: 310 cal, 15g protein, 30g carbs, 14g fat per 150g
('jinya_crispy_rice_tuna', 'JINYA Crispy Rice with Spicy Tuna', 206.7, 10.0, 20.0, 9.3, 0.5, 2.0, NULL, 150, 'jinyaramenbar.com', ARRAY['jinya crispy rice', 'jinya spicy tuna rice'], '310 cal per 150g serving.', 'JINYA Ramen Bar', 'japanese', 1),

-- Garlic Noodles: 480 cal, 12g protein, 60g carbs, 20g fat per 300g
('jinya_garlic_noodles', 'JINYA Garlic Noodles', 160.0, 4.0, 20.0, 6.7, 1.0, 1.5, NULL, 300, 'jinyaramenbar.com', ARRAY['jinya garlic noodles', 'jinya stir fry noodles'], '480 cal per 300g serving. Stir-fried thick noodles with garlic butter.', 'JINYA Ramen Bar', 'japanese', 1),

-- ============================================================================
-- 3. KURA SUSHI (~50 US locations)
-- Source: kurasushi.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Salmon Nigiri (2 pcs): 120 cal, 8g protein, 16g carbs, 2.5g fat per 70g
('kura_salmon_nigiri', 'Kura Sushi Salmon Nigiri', 171.4, 11.4, 22.9, 3.6, 0.3, 2.0, 35, 70, 'kurasushi.com', ARRAY['kura salmon', 'kura sushi salmon'], '120 cal per 2 pieces (70g). Fresh salmon over seasoned rice.', 'Kura Sushi', 'japanese', 2),

-- Tuna Nigiri (2 pcs): 110 cal, 10g protein, 16g carbs, 1g fat per 70g
('kura_tuna_nigiri', 'Kura Sushi Tuna Nigiri', 157.1, 14.3, 22.9, 1.4, 0.3, 2.0, 35, 70, 'kurasushi.com', ARRAY['kura tuna', 'kura sushi tuna'], '110 cal per 2 pieces (70g). Fresh tuna over seasoned rice.', 'Kura Sushi', 'japanese', 2),

-- Shrimp Nigiri (2 pcs): 100 cal, 7g protein, 16g carbs, 0.5g fat per 70g
('kura_shrimp_nigiri', 'Kura Sushi Shrimp Nigiri', 142.9, 10.0, 22.9, 0.7, 0.3, 2.0, 35, 70, 'kurasushi.com', ARRAY['kura shrimp', 'kura ebi'], '100 cal per 2 pieces (70g).', 'Kura Sushi', 'japanese', 2),

-- California Roll (8 pcs): 280 cal, 8g protein, 38g carbs, 10g fat per 220g
('kura_california_roll', 'Kura Sushi California Roll', 127.3, 3.6, 17.3, 4.5, 1.0, 2.5, 28, 220, 'kurasushi.com', ARRAY['kura california', 'kura sushi california roll'], '280 cal per roll (220g). Crab, avocado, cucumber.', 'Kura Sushi', 'japanese', 8),

-- Spicy Tuna Roll (8 pcs): 260 cal, 10g protein, 34g carbs, 9g fat per 220g
('kura_spicy_tuna_roll', 'Kura Sushi Spicy Tuna Roll', 118.2, 4.5, 15.5, 4.1, 0.5, 2.0, 28, 220, 'kurasushi.com', ARRAY['kura spicy tuna', 'kura sushi spicy tuna'], '260 cal per roll (220g).', 'Kura Sushi', 'japanese', 8),

-- Dragon Roll (8 pcs): 350 cal, 10g protein, 40g carbs, 16g fat per 250g
('kura_dragon_roll', 'Kura Sushi Dragon Roll', 140.0, 4.0, 16.0, 6.4, 1.0, 3.0, 31, 250, 'kurasushi.com', ARRAY['kura dragon roll'], '350 cal per roll (250g). Eel, avocado, cucumber with unagi sauce.', 'Kura Sushi', 'japanese', 8),

-- Edamame: 120 cal, 11g protein, 9g carbs, 5g fat per 100g
('kura_edamame', 'Kura Sushi Edamame', 120.0, 11.0, 9.0, 5.0, 4.0, 2.0, NULL, 120, 'kurasushi.com', ARRAY['kura edamame'], '144 cal per 120g serving.', 'Kura Sushi', 'japanese', 1),

-- Miso Soup: 40 cal, 3g protein, 4g carbs, 1g fat per 200g
('kura_miso_soup', 'Kura Sushi Miso Soup', 20.0, 1.5, 2.0, 0.5, 0.3, 0.5, NULL, 200, 'kurasushi.com', ARRAY['kura miso', 'kura sushi miso soup'], '40 cal per 200g bowl.', 'Kura Sushi', 'japanese', 1),

-- Chicken Tempura Roll (8 pcs): 340 cal, 12g protein, 42g carbs, 14g fat per 230g
('kura_chicken_tempura_roll', 'Kura Sushi Chicken Tempura Roll', 147.8, 5.2, 18.3, 6.1, 0.5, 2.5, 29, 230, 'kurasushi.com', ARRAY['kura chicken tempura'], '340 cal per roll (230g).', 'Kura Sushi', 'japanese', 8),

-- Inari (2 pcs): 150 cal, 5g protein, 24g carbs, 4g fat per 80g
('kura_inari', 'Kura Sushi Inari', 187.5, 6.3, 30.0, 5.0, 0.5, 6.0, 40, 80, 'kurasushi.com', ARRAY['kura inari sushi', 'kura tofu pocket'], '150 cal per 2 pieces (80g). Sweet tofu pocket filled with sushi rice.', 'Kura Sushi', 'japanese', 2),

-- ============================================================================
-- 4. WAGAMAMA (~5 US, 200+ UK locations)
-- Source: wagamama.com, nutritionix.com, calorieking.com
-- ============================================================================

-- Chicken Katsu Curry: 880 cal, 42g protein, 98g carbs, 34g fat per 550g
('wagamama_chicken_katsu_curry', 'Wagamama Chicken Katsu Curry', 160.0, 7.6, 17.8, 6.2, 1.5, 3.0, NULL, 550, 'wagamama.com', ARRAY['wagamama katsu curry', 'wagamama chicken katsu'], '880 cal per 550g serving. Panko chicken with Japanese curry, sticky rice.', 'Wagamama', 'japanese', 1),

-- Firecracker Chicken: 750 cal, 35g protein, 90g carbs, 26g fat per 500g
('wagamama_firecracker_chicken', 'Wagamama Firecracker Chicken', 150.0, 7.0, 18.0, 5.2, 1.0, 4.0, NULL, 500, 'wagamama.com', ARRAY['wagamama firecracker'], '750 cal per 500g serving. Stir-fried chicken with noodles, chili, peppers.', 'Wagamama', 'japanese', 1),

-- Pad Thai: 680 cal, 25g protein, 85g carbs, 26g fat per 450g
('wagamama_pad_thai', 'Wagamama Pad Thai', 151.1, 5.6, 18.9, 5.8, 1.0, 5.0, NULL, 450, 'wagamama.com', ARRAY['wagamama pad thai'], '680 cal per 450g serving. Rice noodles with prawns, tofu, peanuts, lime.', 'Wagamama', 'asian', 1),

-- Yaki Soba: 620 cal, 28g protein, 72g carbs, 24g fat per 450g
('wagamama_yaki_soba', 'Wagamama Yaki Soba', 137.8, 6.2, 16.0, 5.3, 1.5, 3.0, NULL, 450, 'wagamama.com', ARRAY['wagamama yakisoba', 'wagamama soba noodles'], '620 cal per 450g serving. Stir-fried soba noodles with chicken, vegetables.', 'Wagamama', 'japanese', 1),

-- Ramen (Tantanmen): 780 cal, 32g protein, 78g carbs, 38g fat per 650g
('wagamama_tantanmen', 'Wagamama Tantanmen Ramen', 120.0, 4.9, 12.0, 5.8, 0.8, 1.5, NULL, 650, 'wagamama.com', ARRAY['wagamama ramen', 'wagamama tantanmen', 'wagamama tan tan ramen'], '780 cal per 650g bowl. Spicy sesame broth with pork, noodles, beansprouts.', 'Wagamama', 'japanese', 1),

-- Chicken Gyoza (5 pcs): 220 cal, 12g protein, 18g carbs, 11g fat per 125g
('wagamama_chicken_gyoza', 'Wagamama Chicken Gyoza', 176.0, 9.6, 14.4, 8.8, 0.5, 1.0, 25, 125, 'wagamama.com', ARRAY['wagamama gyoza', 'wagamama dumplings'], '220 cal per 5 pieces (125g). Pan-fried chicken dumplings.', 'Wagamama', 'japanese', 5),

-- Prawn Firecracker: 380 cal, 20g protein, 42g carbs, 14g fat per 200g
('wagamama_prawn_firecracker', 'Wagamama Prawn Firecracker', 190.0, 10.0, 21.0, 7.0, 0.5, 3.0, NULL, 200, 'wagamama.com', ARRAY['wagamama prawn starter', 'wagamama firecracker prawns'], '380 cal per 200g serving. Crispy prawns with spicy sauce.', 'Wagamama', 'japanese', 1),

-- Chicken Ramen: 650 cal, 30g protein, 72g carbs, 25g fat per 650g
('wagamama_chicken_ramen', 'Wagamama Chicken Ramen', 100.0, 4.6, 11.1, 3.8, 0.5, 1.0, NULL, 650, 'wagamama.com', ARRAY['wagamama tori ramen'], '650 cal per 650g bowl. Chicken broth with ramen noodles.', 'Wagamama', 'japanese', 1),

-- Chilli Squid: 290 cal, 18g protein, 22g carbs, 14g fat per 160g
('wagamama_chilli_squid', 'Wagamama Chilli Squid', 181.3, 11.3, 13.8, 8.8, 0.5, 2.0, NULL, 160, 'wagamama.com', ARRAY['wagamama squid', 'wagamama calamari'], '290 cal per 160g serving. Crispy squid with chili, lime, coriander.', 'Wagamama', 'japanese', 1),

-- Banana Katsu: 450 cal, 6g protein, 60g carbs, 22g fat per 180g
('wagamama_banana_katsu', 'Wagamama Banana Katsu', 250.0, 3.3, 33.3, 12.2, 1.5, 20.0, NULL, 180, 'wagamama.com', ARRAY['wagamama banana katsu dessert'], '450 cal per 180g serving. Panko-fried banana with chocolate sauce, ice cream.', 'Wagamama', 'desserts', 1),

-- ============================================================================
-- 5. IPPUDO RAMEN (~16 US locations)
-- Source: ippudony.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Shiromaru Classic: 780 cal, 32g protein, 75g carbs, 38g fat per 700g
('ippudo_shiromaru', 'Ippudo Shiromaru Classic', 111.4, 4.6, 10.7, 5.4, 0.5, 1.0, NULL, 700, 'ippudony.com', ARRAY['ippudo shiromaru', 'ippudo classic ramen', 'ippudo white ramen'], '780 cal per 700g bowl. Original pork tonkotsu broth with chashu, thin noodles.', 'Ippudo', 'japanese', 1),

-- Akamaru Modern: 850 cal, 35g protein, 78g carbs, 42g fat per 700g
('ippudo_akamaru', 'Ippudo Akamaru Modern', 121.4, 5.0, 11.1, 6.0, 0.5, 1.5, NULL, 700, 'ippudony.com', ARRAY['ippudo akamaru', 'ippudo modern ramen', 'ippudo red ramen'], '850 cal per 700g bowl. Tonkotsu with miso paste, garlic oil, chashu, cabbage.', 'Ippudo', 'japanese', 1),

-- Karaka Spicy Ramen: 880 cal, 33g protein, 80g carbs, 44g fat per 700g
('ippudo_karaka', 'Ippudo Karaka Spicy Ramen', 125.7, 4.7, 11.4, 6.3, 0.5, 1.5, NULL, 700, 'ippudony.com', ARRAY['ippudo karaka', 'ippudo spicy ramen', 'ippudo spicy tonkotsu'], '880 cal per 700g bowl. Spicy tonkotsu with special chili paste, ground pork.', 'Ippudo', 'japanese', 1),

-- Pork Buns (2 pcs): 380 cal, 16g protein, 32g carbs, 20g fat per 160g
('ippudo_pork_buns', 'Ippudo Hirata Pork Buns', 237.5, 10.0, 20.0, 12.5, 0.5, 3.0, 80, 160, 'ippudony.com', ARRAY['ippudo pork bun', 'ippudo hirata bun', 'ippudo steamed bun'], '380 cal per 2 buns (160g). Steamed buns with braised pork belly, lettuce, mayo.', 'Ippudo', 'japanese', 2),

-- Chicken Buns (2 pcs): 340 cal, 18g protein, 32g carbs, 16g fat per 160g
('ippudo_chicken_buns', 'Ippudo Hirata Chicken Buns', 212.5, 11.3, 20.0, 10.0, 0.5, 2.5, 80, 160, 'ippudony.com', ARRAY['ippudo chicken bun', 'ippudo chicken hirata'], '340 cal per 2 buns (160g). Steamed buns with fried chicken.', 'Ippudo', 'japanese', 2),

-- Takoyaki (6 pcs): 280 cal, 12g protein, 28g carbs, 13g fat per 150g
('ippudo_takoyaki', 'Ippudo Takoyaki', 186.7, 8.0, 18.7, 8.7, 0.3, 2.0, 25, 150, 'ippudony.com', ARRAY['ippudo octopus balls', 'ippudo takoyaki'], '280 cal per 6 pieces (150g). Crispy octopus balls with bonito, sauce.', 'Ippudo', 'japanese', 6),

-- Ippudo Fried Rice: 420 cal, 14g protein, 52g carbs, 18g fat per 280g
('ippudo_fried_rice', 'Ippudo Fried Rice', 150.0, 5.0, 18.6, 6.4, 0.5, 1.0, NULL, 280, 'ippudony.com', ARRAY['ippudo chahan', 'ippudo rice'], '420 cal per 280g serving.', 'Ippudo', 'japanese', 1)
