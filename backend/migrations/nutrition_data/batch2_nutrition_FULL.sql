-- =============================================
-- BATCH 2: Restaurant Nutrition Data
-- Pizza Hut, KFC, Chipotle, Sonic Drive-In,
-- Panera Bread, Jack in the Box, Whataburger,
-- Panda Express, Five Guys, Raising Cane's
-- =============================================
-- Format: (food_name_normalized, display_name, cal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, piece_weight_g, serving_g, source_url, variant_names, notes)
-- All values per 100g. Micronutrients in notes JSON.
-- =============================================

-- =============================================
-- 1. PIZZA HUT
-- Source: pizzahut.com, fastfoodnutrition.org
-- =============================================

-- Pizza Hut Hand-Tossed Pepperoni Pizza (Medium) - 1 slice ~107g
-- 230 cal, 10g fat, 9g protein, 25g carbs, 2g fiber, 1g sugar, 540mg sodium, 25mg chol, 4g sat fat
('pizza_hut_hand_tossed_pepperoni', 'Pizza Hut Hand-Tossed Pepperoni Pizza (Medium Slice)', 214.95, 8.41, 23.36, 9.35, 1.87, 0.93, 107, 107, 'pizzahut.com', ARRAY['pizza hut pepperoni', 'pepperoni pizza hut', 'hand tossed pepperoni'], '230 cal per slice. {"sodium_mg":504,"cholesterol_mg":23,"sat_fat_g":3.74,"trans_fat_g":0.0}'),

-- Pizza Hut Hand-Tossed Cheese Pizza (Medium) - 1 slice ~98g
-- 210 cal, 8g fat, 9g protein, 26g carbs, 2g fiber, 1g sugar, 460mg sodium, 20mg chol, 4g sat fat
('pizza_hut_hand_tossed_cheese', 'Pizza Hut Hand-Tossed Cheese Pizza (Medium Slice)', 214.29, 9.18, 26.53, 8.16, 2.04, 1.02, 98, 98, 'pizzahut.com', ARRAY['pizza hut cheese', 'cheese pizza hut', 'hand tossed cheese'], '210 cal per slice. {"sodium_mg":469,"cholesterol_mg":20,"sat_fat_g":4.08,"trans_fat_g":0.0}'),

-- Pizza Hut Hand-Tossed Supreme Pizza (Medium) - 1 slice ~128g
-- 260 cal, 12g fat, 10g protein, 27g carbs, 2g fiber, 1g sugar, 570mg sodium, 30mg chol, 5g sat fat
('pizza_hut_hand_tossed_supreme', 'Pizza Hut Hand-Tossed Supreme Pizza (Medium Slice)', 203.13, 7.81, 21.09, 9.38, 1.56, 0.78, 128, 128, 'pizzahut.com', ARRAY['pizza hut supreme', 'supreme pizza hut'], '260 cal per slice. {"sodium_mg":445,"cholesterol_mg":23,"sat_fat_g":3.91,"trans_fat_g":0.0}'),

-- Pizza Hut Hand-Tossed Meat Lovers Pizza (Medium) - 1 slice ~131g
-- 300 cal, 16g fat, 12g protein, 26g carbs, 2g fiber, 1g sugar, 740mg sodium, 40mg chol, 6g sat fat
('pizza_hut_hand_tossed_meat_lovers', 'Pizza Hut Hand-Tossed Meat Lovers Pizza (Medium Slice)', 229.01, 9.16, 19.85, 12.21, 1.53, 0.76, 131, 131, 'pizzahut.com', ARRAY['pizza hut meat lovers', 'meat lovers pizza hut'], '300 cal per slice. {"sodium_mg":565,"cholesterol_mg":31,"sat_fat_g":4.58,"trans_fat_g":0.0}'),

-- Pizza Hut Hand-Tossed Veggie Lovers Pizza (Medium) - 1 slice ~118g
-- 200 cal, 7g fat, 8g protein, 27g carbs, 2g fiber, 1g sugar, 430mg sodium, 15mg chol, 3g sat fat
('pizza_hut_hand_tossed_veggie_lovers', 'Pizza Hut Hand-Tossed Veggie Lovers Pizza (Medium Slice)', 169.49, 6.78, 22.88, 5.93, 1.69, 0.85, 118, 118, 'pizzahut.com', ARRAY['pizza hut veggie', 'veggie lovers pizza hut', 'veggie pizza hut'], '200 cal per slice. {"sodium_mg":364,"cholesterol_mg":13,"sat_fat_g":2.54,"trans_fat_g":0.0}'),

-- Pizza Hut Pan Cheese Pizza (Medium) - 1 slice 110g
-- 290 cal, 14g fat, 12g protein, 28g carbs, 2g fiber, 1g sugar, 590mg sodium, 10mg chol, 6g sat fat
('pizza_hut_pan_cheese', 'Pizza Hut Pan Cheese Pizza (Medium Slice)', 263.64, 10.91, 25.45, 12.73, 1.82, 0.91, 110, 110, 'pizzahut.com', ARRAY['pizza hut pan cheese', 'pan pizza cheese', 'pan cheese pizza hut'], '290 cal per slice. {"sodium_mg":536,"cholesterol_mg":9,"sat_fat_g":5.45,"trans_fat_g":0.0}'),

-- Pizza Hut Pan Pepperoni Pizza (Medium) - 1 slice ~110g
-- 250 cal, 12g fat, 9g protein, 26g carbs, 1g fiber, 2g sugar, 590mg sodium, 25mg chol, 4.5g sat fat
('pizza_hut_pan_pepperoni', 'Pizza Hut Pan Pepperoni Pizza (Medium Slice)', 227.27, 8.36, 23.36, 10.91, 0.91, 1.82, 110, 110, 'pizzahut.com', ARRAY['pizza hut pan pepperoni', 'pan pizza pepperoni', 'pan pepperoni pizza hut'], '250 cal per slice. {"sodium_mg":536,"cholesterol_mg":23,"sat_fat_g":4.09,"trans_fat_g":0.0}'),

-- Pizza Hut Pan Supreme Pizza (Medium) - 1 slice ~130g
-- 280 cal, 14g fat, 11g protein, 27g carbs, 2g fiber, 2g sugar, 630mg sodium, 25mg chol, 5g sat fat
('pizza_hut_pan_supreme', 'Pizza Hut Pan Supreme Pizza (Medium Slice)', 215.38, 8.46, 20.77, 10.77, 1.54, 1.54, 130, 130, 'pizzahut.com', ARRAY['pizza hut pan supreme', 'pan pizza supreme'], '280 cal per slice. {"sodium_mg":485,"cholesterol_mg":19,"sat_fat_g":3.85,"trans_fat_g":0.0}'),

-- Pizza Hut Pan Meat Lovers Pizza (Medium) - 1 slice ~135g
-- 340 cal, 19g fat, 14g protein, 26g carbs, 2g fiber, 2g sugar, 780mg sodium, 40mg chol, 7g sat fat
('pizza_hut_pan_meat_lovers', 'Pizza Hut Pan Meat Lovers Pizza (Medium Slice)', 251.85, 10.37, 19.26, 14.07, 1.48, 1.48, 135, 135, 'pizzahut.com', ARRAY['pizza hut pan meat lovers', 'pan pizza meat lovers'], '340 cal per slice. {"sodium_mg":578,"cholesterol_mg":30,"sat_fat_g":5.19,"trans_fat_g":0.0}'),

-- Pizza Hut Stuffed Crust Pepperoni (Large) - 1 slice ~150g
-- 380 cal, 18g fat, 16g protein, 39g carbs, 2g fiber, 3g sugar, 1060mg sodium, 45mg chol, 9g sat fat
('pizza_hut_stuffed_crust_pepperoni', 'Pizza Hut Stuffed Crust Pepperoni Pizza (Large Slice)', 253.33, 10.67, 26.00, 12.00, 1.33, 2.00, 150, 150, 'pizzahut.com', ARRAY['pizza hut stuffed crust pepperoni', 'stuffed crust pepperoni'], '380 cal per slice. {"sodium_mg":707,"cholesterol_mg":30,"sat_fat_g":6.00,"trans_fat_g":0.0}'),

-- Pizza Hut Stuffed Crust Cheese (Large) - 1 slice ~145g
-- 340 cal, 14g fat, 16g protein, 38g carbs, 2g fiber, 3g sugar, 900mg sodium, 35mg chol, 7g sat fat
('pizza_hut_stuffed_crust_cheese', 'Pizza Hut Stuffed Crust Cheese Pizza (Large Slice)', 234.48, 11.03, 26.21, 9.66, 1.38, 2.07, 145, 145, 'pizzahut.com', ARRAY['pizza hut stuffed crust cheese', 'stuffed crust cheese'], '340 cal per slice. {"sodium_mg":621,"cholesterol_mg":24,"sat_fat_g":4.83,"trans_fat_g":0.0}'),

-- Pizza Hut Thin N Crispy Pepperoni (Medium) - 1 slice ~80g
-- 200 cal, 10g fat, 8g protein, 19g carbs, 1g fiber, 1g sugar, 490mg sodium, 25mg chol, 4g sat fat
('pizza_hut_thin_crispy_pepperoni', 'Pizza Hut Thin N Crispy Pepperoni Pizza (Medium Slice)', 250.00, 10.00, 23.75, 12.50, 1.25, 1.25, 80, 80, 'pizzahut.com', ARRAY['pizza hut thin crust pepperoni', 'thin crispy pepperoni', 'thin n crispy pizza hut'], '200 cal per slice. {"sodium_mg":613,"cholesterol_mg":31,"sat_fat_g":5.00,"trans_fat_g":0.0}'),

-- Pizza Hut Hand-Tossed BBQ Chicken Pizza (Medium) - 1 slice ~120g
-- 230 cal, 6g fat, 12g protein, 32g carbs, 1g fiber, 8g sugar, 580mg sodium, 30mg chol, 2.5g sat fat
('pizza_hut_hand_tossed_bbq_chicken', 'Pizza Hut Hand-Tossed BBQ Chicken Pizza (Medium Slice)', 191.67, 10.00, 26.67, 5.00, 0.83, 6.67, 120, 120, 'pizzahut.com', ARRAY['pizza hut bbq chicken', 'bbq chicken pizza hut'], '230 cal per slice. {"sodium_mg":483,"cholesterol_mg":25,"sat_fat_g":2.08,"trans_fat_g":0.0}'),

-- Pizza Hut Hand-Tossed Hawaiian Pizza (Medium) - 1 slice ~118g
-- 220 cal, 7g fat, 10g protein, 28g carbs, 1g fiber, 5g sugar, 530mg sodium, 25mg chol, 3g sat fat
('pizza_hut_hand_tossed_hawaiian', 'Pizza Hut Hand-Tossed Hawaiian Pizza (Medium Slice)', 186.44, 8.47, 23.73, 5.93, 0.85, 4.24, 118, 118, 'pizzahut.com', ARRAY['pizza hut hawaiian', 'hawaiian pizza hut', 'ham pineapple pizza hut'], '220 cal per slice. {"sodium_mg":449,"cholesterol_mg":21,"sat_fat_g":2.54,"trans_fat_g":0.0}'),

-- Pizza Hut Traditional Bone-In Wings (naked, per wing) - 1 wing ~30g
-- 80 cal, 4.5g fat, 9g protein, 0g carbs, 0g fiber, 0g sugar, 240mg sodium, 45mg chol, 1.5g sat fat
('pizza_hut_bone_in_wings_naked', 'Pizza Hut Traditional Bone-In Wing (Naked)', 266.67, 30.00, 0.00, 15.00, 0.00, 0.00, 30, 30, 'pizzahut.com', ARRAY['pizza hut wings', 'bone in wings pizza hut', 'naked wings pizza hut'], '80 cal per wing. {"sodium_mg":800,"cholesterol_mg":150,"sat_fat_g":5.00,"trans_fat_g":0.0}'),

-- Pizza Hut Buffalo Bone-In Wings (per wing) - 1 wing ~33g
-- 100 cal, 6g fat, 9g protein, 2g carbs, 0g fiber, 0g sugar, 410mg sodium, 45mg chol, 2g sat fat
('pizza_hut_buffalo_wings', 'Pizza Hut Buffalo Bone-In Wing', 303.03, 27.27, 6.06, 18.18, 0.00, 0.00, 33, 33, 'pizzahut.com', ARRAY['pizza hut buffalo wings', 'hot wings pizza hut', 'buffalo wings pizza hut'], '100 cal per wing. {"sodium_mg":1242,"cholesterol_mg":136,"sat_fat_g":6.06,"trans_fat_g":0.0}'),

-- Pizza Hut Garlic Parmesan Bone-In Wings (per wing) - 1 wing ~34g
-- 110 cal, 8g fat, 9g protein, 2g carbs, 0g fiber, 0g sugar, 290mg sodium, 45mg chol, 2g sat fat
('pizza_hut_garlic_parm_wings', 'Pizza Hut Garlic Parmesan Bone-In Wing', 323.53, 26.47, 5.88, 23.53, 0.00, 0.00, 34, 34, 'pizzahut.com', ARRAY['pizza hut garlic parmesan wings', 'garlic parm wings pizza hut'], '110 cal per wing. {"sodium_mg":853,"cholesterol_mg":132,"sat_fat_g":5.88,"trans_fat_g":0.0}'),

-- Pizza Hut Boneless Wings (per wing) ~25g
-- 80 cal, 4g fat, 4g protein, 7g carbs, 0g fiber, 0g sugar, 200mg sodium, 10mg chol, 1g sat fat
('pizza_hut_boneless_wings', 'Pizza Hut Boneless Wing', 320.00, 16.00, 28.00, 16.00, 0.00, 0.00, 25, 25, 'pizzahut.com', ARRAY['pizza hut boneless wings', 'boneless wings pizza hut'], '80 cal per wing. {"sodium_mg":800,"cholesterol_mg":40,"sat_fat_g":4.00,"trans_fat_g":0.0}'),

-- Pizza Hut Breadstick with Cheese - 1 stick 56g
-- 170 cal, 6g fat, 8g protein, 20g carbs, 1g fiber, 2g sugar, 390mg sodium, 15mg chol, 2.5g sat fat
('pizza_hut_breadstick_cheese', 'Pizza Hut Breadstick with Cheese', 303.57, 14.29, 35.71, 10.71, 1.79, 3.57, 56, 56, 'pizzahut.com', ARRAY['pizza hut breadsticks', 'breadstick pizza hut', 'pizza hut cheese breadstick'], '170 cal per stick. {"sodium_mg":696,"cholesterol_mg":27,"sat_fat_g":4.46,"trans_fat_g":0.0}'),

-- Pizza Hut Tuscani Creamy Chicken Alfredo Pasta ~380g
-- 630 cal, 24g fat, 27g protein, 76g carbs, 4g fiber, 4g sugar, 1180mg sodium, 60mg chol, 9g sat fat
('pizza_hut_creamy_chicken_alfredo', 'Pizza Hut Tuscani Creamy Chicken Alfredo Pasta', 165.79, 7.11, 20.00, 6.32, 1.05, 1.05, 380, 380, 'pizzahut.com', ARRAY['pizza hut alfredo pasta', 'tuscani alfredo', 'chicken alfredo pizza hut'], '630 cal per serving. {"sodium_mg":311,"cholesterol_mg":16,"sat_fat_g":2.37,"trans_fat_g":0.0}'),

-- Pizza Hut Tuscani Meaty Marinara Pasta ~390g
-- 620 cal, 24g fat, 26g protein, 72g carbs, 5g fiber, 8g sugar, 1440mg sodium, 60mg chol, 8g sat fat
('pizza_hut_meaty_marinara', 'Pizza Hut Tuscani Meaty Marinara Pasta', 158.97, 6.67, 18.46, 6.15, 1.28, 2.05, 390, 390, 'pizzahut.com', ARRAY['pizza hut marinara pasta', 'tuscani marinara', 'meaty marinara pizza hut'], '620 cal per serving. {"sodium_mg":369,"cholesterol_mg":15,"sat_fat_g":2.05,"trans_fat_g":0.0}'),

-- Pizza Hut Cinnamon Sticks (2 sticks) ~55g
-- 160 cal, 5g fat, 3g protein, 26g carbs, 1g fiber, 9g sugar, 150mg sodium, 0mg chol, 1.5g sat fat
('pizza_hut_cinnamon_sticks', 'Pizza Hut Cinnamon Sticks (2 pcs)', 290.91, 5.45, 47.27, 9.09, 1.82, 16.36, 55, 55, 'pizzahut.com', ARRAY['pizza hut cinnamon sticks', 'cinnamon sticks pizza hut'], '160 cal per 2 sticks. {"sodium_mg":273,"cholesterol_mg":0,"sat_fat_g":2.73,"trans_fat_g":0.0}'),

-- Pizza Hut Cinnabon Mini Rolls ~270g
-- 830 cal, 33g fat, 11g protein, 124g carbs, 3g fiber, 64g sugar, 630mg sodium, 35mg chol, 14g sat fat
('pizza_hut_cinnabon_mini_rolls', 'Pizza Hut Cinnabon Mini Rolls', 307.41, 4.07, 45.93, 12.22, 1.11, 23.70, 270, 270, 'pizzahut.com', ARRAY['pizza hut cinnabon', 'cinnabon rolls pizza hut', 'mini rolls pizza hut'], '830 cal per order. {"sodium_mg":233,"cholesterol_mg":13,"sat_fat_g":5.19,"trans_fat_g":0.0}'),

-- =============================================
-- 2. KFC
-- Source: kfc.com, fastfoodnutrition.org
-- =============================================

-- KFC Original Recipe Chicken Breast - 1 breast ~161g
-- 390 cal, 21g fat, 39g protein, 11g carbs, 2g fiber, 0g sugar, 1190mg sodium, 120mg chol, 4g sat fat
('kfc_original_recipe_breast', 'KFC Original Recipe Chicken Breast', 242.24, 24.22, 6.83, 13.04, 1.24, 0.00, 161, 161, 'kfc.com', ARRAY['kfc breast', 'kfc original breast', 'original recipe breast'], '390 cal per breast. {"sodium_mg":739,"cholesterol_mg":75,"sat_fat_g":2.48,"trans_fat_g":0.0}'),

-- KFC Original Recipe Chicken Thigh - 1 thigh ~91g
-- 280 cal, 19g fat, 19g protein, 8g carbs, 1g fiber, 0g sugar, 910mg sodium, 100mg chol, 4.5g sat fat
('kfc_original_recipe_thigh', 'KFC Original Recipe Chicken Thigh', 307.69, 20.88, 8.79, 20.88, 1.10, 0.00, 91, 91, 'kfc.com', ARRAY['kfc thigh', 'kfc original thigh', 'original recipe thigh'], '280 cal per thigh. {"sodium_mg":1000,"cholesterol_mg":110,"sat_fat_g":4.95,"trans_fat_g":0.0}'),

-- KFC Original Recipe Chicken Drumstick - 1 drumstick ~56g
-- 130 cal, 8g fat, 12g protein, 4g carbs, 1g fiber, 0g sugar, 430mg sodium, 55mg chol, 1.5g sat fat
('kfc_original_recipe_drumstick', 'KFC Original Recipe Chicken Drumstick', 232.14, 21.43, 7.14, 14.29, 1.79, 0.00, 56, 56, 'kfc.com', ARRAY['kfc drumstick', 'kfc drum', 'original recipe drumstick'], '130 cal per drumstick. {"sodium_mg":768,"cholesterol_mg":98,"sat_fat_g":2.68,"trans_fat_g":0.0}'),

-- KFC Original Recipe Chicken Wing - 1 wing ~48g
-- 120 cal, 8g fat, 9g protein, 4g carbs, 0g fiber, 0g sugar, 350mg sodium, 45mg chol, 1.5g sat fat
('kfc_original_recipe_wing', 'KFC Original Recipe Chicken Wing', 250.00, 18.75, 8.33, 16.67, 0.00, 0.00, 48, 48, 'kfc.com', ARRAY['kfc wing', 'kfc original wing', 'original recipe wing'], '120 cal per wing. {"sodium_mg":729,"cholesterol_mg":94,"sat_fat_g":3.13,"trans_fat_g":0.0}'),

-- KFC Extra Crispy Chicken Breast - 1 breast ~168g
-- 530 cal, 35g fat, 35g protein, 18g carbs, 0g fiber, 1g sugar, 1150mg sodium, 105mg chol, 6g sat fat
('kfc_extra_crispy_breast', 'KFC Extra Crispy Chicken Breast', 315.48, 20.83, 10.71, 20.83, 0.00, 0.60, 168, 168, 'kfc.com', ARRAY['kfc extra crispy breast', 'extra crispy breast'], '530 cal per breast. {"sodium_mg":685,"cholesterol_mg":63,"sat_fat_g":3.57,"trans_fat_g":0.0}'),

-- KFC Extra Crispy Chicken Thigh - 1 thigh ~114g
-- 290 cal, 20g fat, 17g protein, 11g carbs, 0g fiber, 0g sugar, 660mg sodium, 70mg chol, 4g sat fat
('kfc_extra_crispy_thigh', 'KFC Extra Crispy Chicken Thigh', 254.39, 14.91, 9.65, 17.54, 0.00, 0.00, 114, 114, 'kfc.com', ARRAY['kfc extra crispy thigh', 'extra crispy thigh'], '290 cal per thigh. {"sodium_mg":579,"cholesterol_mg":61,"sat_fat_g":3.51,"trans_fat_g":0.0}'),

-- KFC Extra Crispy Chicken Drumstick - 1 drumstick ~60g
-- 170 cal, 10g fat, 12g protein, 6g carbs, 0g fiber, 0g sugar, 350mg sodium, 45mg chol, 2g sat fat
('kfc_extra_crispy_drumstick', 'KFC Extra Crispy Chicken Drumstick', 283.33, 20.00, 10.00, 16.67, 0.00, 0.00, 60, 60, 'kfc.com', ARRAY['kfc extra crispy drumstick', 'extra crispy drum'], '170 cal per drumstick. {"sodium_mg":583,"cholesterol_mg":75,"sat_fat_g":3.33,"trans_fat_g":0.0}'),

-- KFC Chicken Sandwich - 1 sandwich ~207g
-- 650 cal, 34g fat, 28g protein, 56g carbs, 2g fiber, 8g sugar, 1640mg sodium, 60mg chol, 6g sat fat
('kfc_chicken_sandwich', 'KFC Chicken Sandwich', 313.95, 13.53, 27.05, 16.43, 0.97, 3.86, 207, 207, 'kfc.com', ARRAY['kfc sandwich', 'kfc chicken sandwich', 'kfc crispy sandwich'], '650 cal per sandwich. {"sodium_mg":792,"cholesterol_mg":29,"sat_fat_g":2.90,"trans_fat_g":0.0}'),

-- KFC Famous Bowl - 1 bowl ~397g
-- 740 cal, 35g fat, 26g protein, 81g carbs, 6g fiber, 2g sugar, 2350mg sodium, 45mg chol, 6g sat fat
('kfc_famous_bowl', 'KFC Famous Bowl', 186.40, 6.55, 20.40, 8.82, 1.51, 0.50, 397, 397, 'kfc.com', ARRAY['kfc bowl', 'famous bowl', 'kfc mashed potato bowl'], '740 cal per bowl. {"sodium_mg":592,"cholesterol_mg":11,"sat_fat_g":1.51,"trans_fat_g":0.0}'),

-- KFC Chicken Pot Pie - 1 pie ~322g
-- 720 cal, 41g fat, 26g protein, 60g carbs, 7g fiber, 5g sugar, 1750mg sodium, 80mg chol, 25g sat fat
('kfc_chicken_pot_pie', 'KFC Chicken Pot Pie', 223.60, 8.07, 18.63, 12.73, 2.17, 1.55, 322, 322, 'kfc.com', ARRAY['kfc pot pie', 'chicken pot pie kfc'], '720 cal per pie. {"sodium_mg":543,"cholesterol_mg":25,"sat_fat_g":7.76,"trans_fat_g":0.0}'),

-- KFC Mac & Cheese (individual) - 1 serving ~136g
-- 170 cal, 8g fat, 7g protein, 17g carbs, 0g fiber, 2g sugar, 720mg sodium, 20mg chol, 3g sat fat
('kfc_mac_and_cheese', 'KFC Mac & Cheese', 125.00, 5.15, 12.50, 5.88, 0.00, 1.47, 136, 136, 'kfc.com', ARRAY['kfc mac and cheese', 'kfc macaroni', 'mac cheese kfc'], '170 cal per serving. {"sodium_mg":529,"cholesterol_mg":15,"sat_fat_g":2.21,"trans_fat_g":0.0}'),

-- KFC Mashed Potatoes with Gravy - 1 serving ~153g
-- 130 cal, 5g fat, 2g protein, 19g carbs, 1g fiber, 0g sugar, 510mg sodium, 0mg chol, 1g sat fat
('kfc_mashed_potatoes_gravy', 'KFC Mashed Potatoes with Gravy', 84.97, 1.31, 12.42, 3.27, 0.65, 0.00, 153, 153, 'kfc.com', ARRAY['kfc mashed potatoes', 'kfc potatoes gravy'], '130 cal per serving. {"sodium_mg":333,"cholesterol_mg":0,"sat_fat_g":0.65,"trans_fat_g":0.0}'),

-- KFC Coleslaw - 1 serving ~128g
-- 170 cal, 10g fat, 1g protein, 21g carbs, 3g fiber, 14g sugar, 180mg sodium, 5mg chol, 1.5g sat fat
('kfc_coleslaw', 'KFC Coleslaw', 132.81, 0.78, 16.41, 7.81, 2.34, 10.94, 128, 128, 'kfc.com', ARRAY['kfc coleslaw', 'kfc cole slaw', 'kfc slaw'], '170 cal per serving. {"sodium_mg":141,"cholesterol_mg":4,"sat_fat_g":1.17,"trans_fat_g":0.0}'),

-- KFC Corn on the Cob - 1 ear ~162g
-- 70 cal, 0.5g fat, 2g protein, 16g carbs, 2g fiber, 4g sugar, 0mg sodium, 0mg chol, 0g sat fat
('kfc_corn_on_cob', 'KFC Corn on the Cob', 43.21, 1.23, 9.88, 0.31, 1.23, 2.47, 162, 162, 'kfc.com', ARRAY['kfc corn', 'corn on cob kfc'], '70 cal per ear. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- KFC Green Beans - 1 serving ~86g
-- 25 cal, 0g fat, 1g protein, 4g carbs, 2g fiber, 1g sugar, 280mg sodium, 0mg chol, 0g sat fat
('kfc_green_beans', 'KFC Green Beans', 29.07, 1.16, 4.65, 0.00, 2.33, 1.16, 86, 86, 'kfc.com', ARRAY['kfc green beans', 'kfc beans'], '25 cal per serving. {"sodium_mg":326,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- KFC Biscuit - 1 biscuit ~56g
-- 180 cal, 8g fat, 4g protein, 22g carbs, 1g fiber, 2g sugar, 530mg sodium, 0mg chol, 4g sat fat
('kfc_biscuit', 'KFC Biscuit', 321.43, 7.14, 39.29, 14.29, 1.79, 3.57, 56, 56, 'kfc.com', ARRAY['kfc biscuit', 'biscuit kfc'], '180 cal per biscuit. {"sodium_mg":946,"cholesterol_mg":0,"sat_fat_g":7.14,"trans_fat_g":0.0}'),

-- KFC Chicken Tenders (3 pc) - 3 tenders ~130g
-- 370 cal, 19g fat, 27g protein, 22g carbs, 0g fiber, 0g sugar, 1020mg sodium, 55mg chol, 3g sat fat
('kfc_chicken_tenders', 'KFC Chicken Tenders (3 pc)', 284.62, 20.77, 16.92, 14.62, 0.00, 0.00, 130, 130, 'kfc.com', ARRAY['kfc tenders', 'kfc strips', 'chicken tenders kfc'], '370 cal per 3 tenders. {"sodium_mg":785,"cholesterol_mg":42,"sat_fat_g":2.31,"trans_fat_g":0.0}'),

-- KFC Chicken Nuggets (8 pc) - 8 nuggets ~128g
-- 340 cal, 20g fat, 17g protein, 22g carbs, 0g fiber, 0g sugar, 790mg sodium, 40mg chol, 3.5g sat fat
('kfc_chicken_nuggets', 'KFC Chicken Nuggets (8 pc)', 265.63, 13.28, 17.19, 15.63, 0.00, 0.00, 128, 128, 'kfc.com', ARRAY['kfc nuggets', 'chicken nuggets kfc'], '340 cal per 8 nuggets. {"sodium_mg":617,"cholesterol_mg":31,"sat_fat_g":2.73,"trans_fat_g":0.0}'),

-- KFC Spicy Chicken Sandwich - 1 sandwich ~215g
-- 700 cal, 37g fat, 29g protein, 58g carbs, 3g fiber, 8g sugar, 1830mg sodium, 65mg chol, 7g sat fat
('kfc_spicy_chicken_sandwich', 'KFC Spicy Chicken Sandwich', 325.58, 13.49, 26.98, 17.21, 1.40, 3.72, 215, 215, 'kfc.com', ARRAY['kfc spicy sandwich', 'kfc spicy chicken'], '700 cal per sandwich. {"sodium_mg":851,"cholesterol_mg":30,"sat_fat_g":3.26,"trans_fat_g":0.0}'),

-- KFC Chocolate Chip Cookie - 1 cookie ~35g
-- 160 cal, 8g fat, 2g protein, 22g carbs, 1g fiber, 13g sugar, 120mg sodium, 10mg chol, 4g sat fat
('kfc_chocolate_chip_cookie', 'KFC Chocolate Chip Cookie', 457.14, 5.71, 62.86, 22.86, 2.86, 37.14, 35, 35, 'kfc.com', ARRAY['kfc cookie', 'kfc chocolate chip cookie'], '160 cal per cookie. {"sodium_mg":343,"cholesterol_mg":29,"sat_fat_g":11.43,"trans_fat_g":0.0}'),

-- =============================================
-- 3. CHIPOTLE (expanding beyond existing 5 items)
-- Source: chipotle.com, fastfoodnutrition.org
-- Existing: burrito_bowl_chicken, chips_guac, chips_queso, chicken_tacos, red_chimichurri
-- =============================================

-- Chipotle Chicken Burrito - full burrito ~480g (tortilla+chicken+rice+beans+salsa)
-- 480 cal, 16g fat, 39g protein, 45g carbs, 2g fiber, 1g sugar, 1040mg sodium, 115mg chol, 5g sat fat
('chipotle_chicken_burrito', 'Chipotle Chicken Burrito', 100.00, 8.13, 9.38, 3.33, 0.42, 0.21, 480, 480, 'chipotle.com', ARRAY['chipotle burrito', 'chipotle chicken burrito', 'burrito chipotle'], '480 cal per burrito. {"sodium_mg":217,"cholesterol_mg":24,"sat_fat_g":1.04,"trans_fat_g":0.0}'),

-- Chipotle Steak Burrito Bowl - full bowl ~500g
-- 630 cal, 22g fat, 40g protein, 72g carbs, 9g fiber, 5g sugar, 1530mg sodium, 80mg chol, 6g sat fat
('chipotle_steak_burrito_bowl', 'Chipotle Steak Burrito Bowl', 126.00, 8.00, 14.40, 4.40, 1.80, 1.00, 500, 500, 'chipotle.com', ARRAY['chipotle steak bowl', 'steak bowl chipotle', 'steak burrito bowl'], '630 cal per bowl. {"sodium_mg":306,"cholesterol_mg":16,"sat_fat_g":1.20,"trans_fat_g":0.0}'),

-- Chipotle Barbacoa Bowl - full bowl ~500g
-- 645 cal, 23g fat, 40g protein, 72g carbs, 10g fiber, 5g sugar, 1740mg sodium, 85mg chol, 7g sat fat
('chipotle_barbacoa_bowl', 'Chipotle Barbacoa Burrito Bowl', 129.00, 8.00, 14.40, 4.60, 2.00, 1.00, 500, 500, 'chipotle.com', ARRAY['chipotle barbacoa', 'barbacoa bowl chipotle'], '645 cal per bowl. {"sodium_mg":348,"cholesterol_mg":17,"sat_fat_g":1.40,"trans_fat_g":0.0}'),

-- Chipotle Sofritas Bowl - full bowl ~490g
-- 555 cal, 17g fat, 19g protein, 74g carbs, 11g fiber, 6g sugar, 1360mg sodium, 0mg chol, 3g sat fat
('chipotle_sofritas_bowl', 'Chipotle Sofritas Burrito Bowl', 113.27, 3.88, 15.10, 3.47, 2.24, 1.22, 490, 490, 'chipotle.com', ARRAY['chipotle sofritas', 'sofritas bowl chipotle', 'tofu bowl chipotle'], '555 cal per bowl. {"sodium_mg":278,"cholesterol_mg":0,"sat_fat_g":0.61,"trans_fat_g":0.0}'),

-- Chipotle Carnitas Burrito - full burrito ~500g
-- 570 cal, 20g fat, 35g protein, 60g carbs, 7g fiber, 3g sugar, 1540mg sodium, 85mg chol, 7g sat fat
('chipotle_carnitas_burrito', 'Chipotle Carnitas Burrito', 114.00, 7.00, 12.00, 4.00, 1.40, 0.60, 500, 500, 'chipotle.com', ARRAY['chipotle carnitas', 'carnitas burrito chipotle'], '570 cal per burrito. {"sodium_mg":308,"cholesterol_mg":17,"sat_fat_g":1.40,"trans_fat_g":0.0}'),

-- Chipotle Steak Tacos (3 soft corn tacos) ~300g
-- 525 cal, 18g fat, 30g protein, 57g carbs, 6g fiber, 3g sugar, 1080mg sodium, 65mg chol, 5g sat fat
('chipotle_steak_tacos', 'Chipotle Steak Tacos (3 pcs)', 175.00, 10.00, 19.00, 6.00, 2.00, 1.00, 300, 300, 'chipotle.com', ARRAY['chipotle steak tacos', 'steak tacos chipotle'], '525 cal for 3 tacos. {"sodium_mg":360,"cholesterol_mg":22,"sat_fat_g":1.67,"trans_fat_g":0.0}'),

-- Chipotle Chicken Quesadilla ~290g
-- 750 cal, 37g fat, 46g protein, 54g carbs, 3g fiber, 2g sugar, 1640mg sodium, 140mg chol, 17g sat fat
('chipotle_chicken_quesadilla', 'Chipotle Chicken Quesadilla', 258.62, 15.86, 18.62, 12.76, 1.03, 0.69, 290, 290, 'chipotle.com', ARRAY['chipotle quesadilla', 'chicken quesadilla chipotle'], '750 cal per quesadilla. {"sodium_mg":566,"cholesterol_mg":48,"sat_fat_g":5.86,"trans_fat_g":0.0}'),

-- Chipotle White Rice (side) ~130g
-- 210 cal, 4g fat, 3g protein, 40g carbs, 0g fiber, 0g sugar, 280mg sodium, 0mg chol, 0.5g sat fat
('chipotle_white_rice', 'Chipotle Cilantro-Lime White Rice', 161.54, 2.31, 30.77, 3.08, 0.00, 0.00, 130, 130, 'chipotle.com', ARRAY['chipotle rice', 'chipotle white rice', 'cilantro lime rice'], '210 cal per serving. {"sodium_mg":215,"cholesterol_mg":0,"sat_fat_g":0.38,"trans_fat_g":0.0}'),

-- Chipotle Brown Rice (side) ~130g
-- 210 cal, 5g fat, 4g protein, 36g carbs, 2g fiber, 0g sugar, 230mg sodium, 0mg chol, 0.5g sat fat
('chipotle_brown_rice', 'Chipotle Cilantro-Lime Brown Rice', 161.54, 3.08, 27.69, 3.85, 1.54, 0.00, 130, 130, 'chipotle.com', ARRAY['chipotle brown rice'], '210 cal per serving. {"sodium_mg":177,"cholesterol_mg":0,"sat_fat_g":0.38,"trans_fat_g":0.0}'),

-- Chipotle Black Beans (side) ~130g
-- 130 cal, 1g fat, 8g protein, 22g carbs, 7g fiber, 1g sugar, 210mg sodium, 0mg chol, 0g sat fat
('chipotle_black_beans', 'Chipotle Black Beans', 100.00, 6.15, 16.92, 0.77, 5.38, 0.77, 130, 130, 'chipotle.com', ARRAY['chipotle beans', 'chipotle black beans'], '130 cal per serving. {"sodium_mg":162,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Chipotle Pinto Beans (side) ~130g
-- 130 cal, 1g fat, 8g protein, 22g carbs, 7g fiber, 0g sugar, 310mg sodium, 5mg chol, 0g sat fat
('chipotle_pinto_beans', 'Chipotle Pinto Beans', 100.00, 6.15, 16.92, 0.77, 5.38, 0.00, 130, 130, 'chipotle.com', ARRAY['chipotle pinto beans'], '130 cal per serving. {"sodium_mg":238,"cholesterol_mg":4,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Chipotle Chicken (protein only) ~113g (4oz)
-- 180 cal, 7g fat, 32g protein, 0g carbs, 0g fiber, 0g sugar, 530mg sodium, 95mg chol, 2g sat fat
('chipotle_chicken', 'Chipotle Chicken (Protein)', 159.29, 28.32, 0.00, 6.19, 0.00, 0.00, 113, 113, 'chipotle.com', ARRAY['chipotle chicken protein', 'chipotle grilled chicken'], '180 cal per 4oz serving. {"sodium_mg":469,"cholesterol_mg":84,"sat_fat_g":1.77,"trans_fat_g":0.0}'),

-- Chipotle Steak (protein only) ~113g (4oz)
-- 150 cal, 6g fat, 21g protein, 1g carbs, 0g fiber, 0g sugar, 390mg sodium, 65mg chol, 2g sat fat
('chipotle_steak', 'Chipotle Steak (Protein)', 132.74, 18.58, 0.88, 5.31, 0.00, 0.00, 113, 113, 'chipotle.com', ARRAY['chipotle steak protein'], '150 cal per 4oz serving. {"sodium_mg":345,"cholesterol_mg":58,"sat_fat_g":1.77,"trans_fat_g":0.0}'),

-- Chipotle Guacamole (side) ~100g
-- 230 cal, 22g fat, 2g protein, 8g carbs, 6g fiber, 1g sugar, 330mg sodium, 0mg chol, 3g sat fat
('chipotle_guacamole', 'Chipotle Guacamole (Side)', 230.00, 2.00, 8.00, 22.00, 6.00, 1.00, 100, 100, 'chipotle.com', ARRAY['chipotle guac', 'chipotle guacamole', 'guacamole chipotle'], '230 cal per side. {"sodium_mg":330,"cholesterol_mg":0,"sat_fat_g":3.00,"trans_fat_g":0.0}'),

-- Chipotle Queso Blanco (side) ~57g (2oz)
-- 120 cal, 9g fat, 5g protein, 4g carbs, 0g fiber, 1g sugar, 260mg sodium, 20mg chol, 5g sat fat
('chipotle_queso_blanco_side', 'Chipotle Queso Blanco (Side)', 210.53, 8.77, 7.02, 15.79, 0.00, 1.75, 57, 57, 'chipotle.com', ARRAY['chipotle queso', 'chipotle cheese dip'], '120 cal per side. {"sodium_mg":456,"cholesterol_mg":35,"sat_fat_g":8.77,"trans_fat_g":0.0}'),

-- Chipotle Fresh Tomato Salsa ~112g (4oz)
-- 25 cal, 0g fat, 1g protein, 4g carbs, 1g fiber, 2g sugar, 510mg sodium, 0mg chol, 0g sat fat
('chipotle_fresh_tomato_salsa', 'Chipotle Fresh Tomato Salsa (Pico)', 22.32, 0.89, 3.57, 0.00, 0.89, 1.79, 112, 112, 'chipotle.com', ARRAY['chipotle pico de gallo', 'chipotle salsa', 'chipotle pico'], '25 cal per serving. {"sodium_mg":455,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Chipotle Sour Cream ~57g (2oz)
-- 110 cal, 9g fat, 2g protein, 2g carbs, 0g fiber, 1g sugar, 30mg sodium, 35mg chol, 6g sat fat
('chipotle_sour_cream', 'Chipotle Sour Cream', 192.98, 3.51, 3.51, 15.79, 0.00, 1.75, 57, 57, 'chipotle.com', ARRAY['chipotle sour cream'], '110 cal per serving. {"sodium_mg":53,"cholesterol_mg":61,"sat_fat_g":10.53,"trans_fat_g":0.0}'),

-- Chipotle Cheese (shredded) ~28g (1oz)
-- 110 cal, 9g fat, 6g protein, 1g carbs, 0g fiber, 0g sugar, 150mg sodium, 25mg chol, 5g sat fat
('chipotle_cheese', 'Chipotle Shredded Cheese', 392.86, 21.43, 3.57, 32.14, 0.00, 0.00, 28, 28, 'chipotle.com', ARRAY['chipotle cheese', 'chipotle shredded cheese'], '110 cal per serving. {"sodium_mg":536,"cholesterol_mg":89,"sat_fat_g":17.86,"trans_fat_g":0.0}'),

-- Chipotle Tortilla Chips (side) ~115g (4oz)
-- 540 cal, 26g fat, 7g protein, 68g carbs, 5g fiber, 1g sugar, 320mg sodium, 0mg chol, 3.5g sat fat
('chipotle_tortilla_chips', 'Chipotle Tortilla Chips', 469.57, 6.09, 59.13, 22.61, 4.35, 0.87, 115, 115, 'chipotle.com', ARRAY['chipotle chips', 'chips chipotle'], '540 cal per bag. {"sodium_mg":278,"cholesterol_mg":0,"sat_fat_g":3.04,"trans_fat_g":0.0}'),

-- =============================================
-- 4. SONIC DRIVE-IN
-- Source: sonicdrivein.com, fastfoodnutrition.org
-- =============================================

-- Sonic Jr. Burger - 1 burger 127g
-- 340 cal, 17g fat, 15g protein, 34g carbs, 1g fiber, 6g sugar, 640mg sodium, 35mg chol, 6g sat fat, 1g trans fat
('sonic_jr_burger', 'Sonic Jr. Burger', 267.72, 11.81, 26.77, 13.39, 0.79, 4.72, 127, 127, 'sonicdrivein.com', ARRAY['sonic jr burger', 'sonic junior burger'], '340 cal per burger. {"sodium_mg":504,"cholesterol_mg":28,"sat_fat_g":4.72,"trans_fat_g":0.79}'),

-- Sonic Cheeseburger (w/ mustard) - 1 burger ~213g
-- 590 cal, 31g fat, 27g protein, 49g carbs, 2g fiber, 10g sugar, 1230mg sodium, 80mg chol, 13g sat fat
('sonic_cheeseburger', 'Sonic Cheeseburger', 276.99, 12.68, 23.00, 14.55, 0.94, 4.69, 213, 213, 'sonicdrivein.com', ARRAY['sonic cheeseburger', 'sonic cheese burger'], '590 cal per burger. {"sodium_mg":577,"cholesterol_mg":38,"sat_fat_g":6.10,"trans_fat_g":0.47}'),

-- Sonic Burger (w/ mayo) - 1 burger ~200g
-- 620 cal, 34g fat, 27g protein, 49g carbs, 2g fiber, 10g sugar, 1080mg sodium, 70mg chol, 11g sat fat
('sonic_burger', 'Sonic Burger', 310.00, 13.50, 24.50, 17.00, 1.00, 5.00, 200, 200, 'sonicdrivein.com', ARRAY['sonic burger', 'sonic hamburger'], '620 cal per burger. {"sodium_mg":540,"cholesterol_mg":35,"sat_fat_g":5.50,"trans_fat_g":0.50}'),

-- SuperSONIC Bacon Double Cheeseburger - 1 burger ~348g
-- 1130 cal, 75g fat, 57g protein, 54g carbs, 3g fiber, 12g sugar, 2050mg sodium, 195mg chol, 30g sat fat
('sonic_supersonic_bacon_double', 'Sonic SuperSONIC Bacon Double Cheeseburger', 324.71, 16.38, 15.52, 21.55, 0.86, 3.45, 348, 348, 'sonicdrivein.com', ARRAY['sonic supersonic', 'supersonic burger', 'supersonic bacon double'], '1130 cal per burger. {"sodium_mg":589,"cholesterol_mg":56,"sat_fat_g":8.62,"trans_fat_g":1.15}'),

-- Sonic Chili Cheese Coney (6") - 1 hot dog ~175g
-- 470 cal, 29g fat, 18g protein, 34g carbs, 2g fiber, 4g sugar, 1240mg sodium, 55mg chol, 12g sat fat
('sonic_chili_cheese_coney', 'Sonic Chili Cheese Coney (6 in)', 268.57, 10.29, 19.43, 16.57, 1.14, 2.29, 175, 175, 'sonicdrivein.com', ARRAY['sonic coney', 'sonic chili cheese coney', 'chili cheese hot dog sonic'], '470 cal per 6" coney. {"sodium_mg":709,"cholesterol_mg":31,"sat_fat_g":6.86,"trans_fat_g":0.0}'),

-- Sonic All-American Hot Dog - 1 hot dog ~120g
-- 340 cal, 21g fat, 11g protein, 26g carbs, 1g fiber, 5g sugar, 930mg sodium, 40mg chol, 8g sat fat
('sonic_all_american_hot_dog', 'Sonic All-American Hot Dog', 283.33, 9.17, 21.67, 17.50, 0.83, 4.17, 120, 120, 'sonicdrivein.com', ARRAY['sonic hot dog', 'sonic all american'], '340 cal per hot dog. {"sodium_mg":775,"cholesterol_mg":33,"sat_fat_g":6.67,"trans_fat_g":0.0}'),

-- Sonic Corn Dog - 1 corn dog ~75g
-- 230 cal, 13g fat, 7g protein, 23g carbs, 1g fiber, 6g sugar, 560mg sodium, 20mg chol, 4g sat fat
('sonic_corn_dog', 'Sonic Corn Dog', 306.67, 9.33, 30.67, 17.33, 1.33, 8.00, 75, 75, 'sonicdrivein.com', ARRAY['sonic corn dog', 'corn dog sonic'], '230 cal per corn dog. {"sodium_mg":747,"cholesterol_mg":27,"sat_fat_g":5.33,"trans_fat_g":0.0}'),

-- Sonic Crispy Chicken Sandwich - 1 sandwich ~195g
-- 530 cal, 27g fat, 20g protein, 52g carbs, 2g fiber, 9g sugar, 1190mg sodium, 35mg chol, 5g sat fat
('sonic_crispy_chicken_sandwich', 'Sonic Crispy Chicken Sandwich', 271.79, 10.26, 26.67, 13.85, 1.03, 4.62, 195, 195, 'sonicdrivein.com', ARRAY['sonic chicken sandwich', 'crispy chicken sonic'], '530 cal per sandwich. {"sodium_mg":610,"cholesterol_mg":18,"sat_fat_g":2.56,"trans_fat_g":0.0}'),

-- Sonic Grilled Chicken Sandwich - 1 sandwich ~195g
-- 440 cal, 18g fat, 33g protein, 37g carbs, 2g fiber, 8g sugar, 1060mg sodium, 90mg chol, 4g sat fat
('sonic_grilled_chicken_sandwich', 'Sonic Grilled Chicken Sandwich', 225.64, 16.92, 18.97, 9.23, 1.03, 4.10, 195, 195, 'sonicdrivein.com', ARRAY['sonic grilled chicken', 'grilled chicken sonic'], '440 cal per sandwich. {"sodium_mg":544,"cholesterol_mg":46,"sat_fat_g":2.05,"trans_fat_g":0.0}'),

-- Sonic French Fries (medium) - 1 serving ~120g
-- 360 cal, 17g fat, 4g protein, 48g carbs, 3g fiber, 0g sugar, 540mg sodium, 0mg chol, 2.5g sat fat
('sonic_french_fries_medium', 'Sonic French Fries (Medium)', 300.00, 3.33, 40.00, 14.17, 2.50, 0.00, 120, 120, 'sonicdrivein.com', ARRAY['sonic fries', 'sonic french fries', 'fries sonic'], '360 cal per medium. {"sodium_mg":450,"cholesterol_mg":0,"sat_fat_g":2.08,"trans_fat_g":0.0}'),

-- Sonic Onion Rings (medium) - 1 serving ~155g
-- 480 cal, 28g fat, 6g protein, 52g carbs, 3g fiber, 5g sugar, 660mg sodium, 0mg chol, 5g sat fat
('sonic_onion_rings', 'Sonic Onion Rings (Medium)', 309.68, 3.87, 33.55, 18.06, 1.94, 3.23, 155, 155, 'sonicdrivein.com', ARRAY['sonic onion rings', 'onion rings sonic'], '480 cal per medium. {"sodium_mg":426,"cholesterol_mg":0,"sat_fat_g":3.23,"trans_fat_g":0.0}'),

-- Sonic Tater Tots (medium) - 1 serving ~120g
-- 390 cal, 21g fat, 3g protein, 46g carbs, 3g fiber, 0g sugar, 680mg sodium, 0mg chol, 3.5g sat fat
('sonic_tots', 'Sonic Tater Tots (Medium)', 325.00, 2.50, 38.33, 17.50, 2.50, 0.00, 120, 120, 'sonicdrivein.com', ARRAY['sonic tots', 'sonic tater tots', 'tots sonic'], '390 cal per medium. {"sodium_mg":567,"cholesterol_mg":0,"sat_fat_g":2.92,"trans_fat_g":0.0}'),

-- Sonic Mozzarella Sticks (6pc) - 1 serving ~100g
-- 370 cal, 21g fat, 14g protein, 31g carbs, 2g fiber, 2g sugar, 890mg sodium, 30mg chol, 8g sat fat
('sonic_mozzarella_sticks', 'Sonic Mozzarella Sticks', 370.00, 14.00, 31.00, 21.00, 2.00, 2.00, 100, 100, 'sonicdrivein.com', ARRAY['sonic mozz sticks', 'sonic mozzarella sticks'], '370 cal per order. {"sodium_mg":890,"cholesterol_mg":30,"sat_fat_g":8.00,"trans_fat_g":0.0}'),

-- Sonic Breakfast Burrito (Sausage) - 1 burrito ~200g
-- 500 cal, 29g fat, 18g protein, 39g carbs, 2g fiber, 3g sugar, 1170mg sodium, 175mg chol, 10g sat fat
('sonic_breakfast_burrito_sausage', 'Sonic Breakfast Burrito (Sausage)', 250.00, 9.00, 19.50, 14.50, 1.00, 1.50, 200, 200, 'sonicdrivein.com', ARRAY['sonic breakfast burrito', 'sonic sausage burrito'], '500 cal per burrito. {"sodium_mg":585,"cholesterol_mg":88,"sat_fat_g":5.00,"trans_fat_g":0.0}'),

-- Sonic CroisSONIC Breakfast Sandwich (bacon) - 1 sandwich ~185g
-- 510 cal, 32g fat, 20g protein, 35g carbs, 1g fiber, 5g sugar, 1000mg sodium, 195mg chol, 13g sat fat
('sonic_croissonic_bacon', 'Sonic CroisSONIC Breakfast Sandwich (Bacon)', 275.68, 10.81, 18.92, 17.30, 0.54, 2.70, 185, 185, 'sonicdrivein.com', ARRAY['sonic croissonic', 'sonic breakfast croissant', 'croissonic bacon'], '510 cal per sandwich. {"sodium_mg":541,"cholesterol_mg":105,"sat_fat_g":7.03,"trans_fat_g":0.0}'),

-- Sonic Vanilla Shake (medium) ~420g
-- 540 cal, 18g fat, 10g protein, 87g carbs, 0g fiber, 72g sugar, 370mg sodium, 60mg chol, 12g sat fat
('sonic_vanilla_shake', 'Sonic Vanilla Shake (Medium)', 128.57, 2.38, 20.71, 4.29, 0.00, 17.14, 420, 420, 'sonicdrivein.com', ARRAY['sonic vanilla shake', 'sonic milkshake', 'vanilla shake sonic'], '540 cal per medium. {"sodium_mg":88,"cholesterol_mg":14,"sat_fat_g":2.86,"trans_fat_g":0.0}'),

-- Sonic Chocolate Shake (medium) ~430g
-- 580 cal, 18g fat, 10g protein, 95g carbs, 1g fiber, 79g sugar, 420mg sodium, 60mg chol, 12g sat fat
('sonic_chocolate_shake', 'Sonic Chocolate Shake (Medium)', 134.88, 2.33, 22.09, 4.19, 0.23, 18.37, 430, 430, 'sonicdrivein.com', ARRAY['sonic chocolate shake', 'chocolate shake sonic'], '580 cal per medium. {"sodium_mg":98,"cholesterol_mg":14,"sat_fat_g":2.79,"trans_fat_g":0.0}'),

-- Sonic Classic Limeade (medium) ~450g
-- 200 cal, 0g fat, 0g protein, 53g carbs, 0g fiber, 51g sugar, 40mg sodium, 0mg chol, 0g sat fat
('sonic_classic_limeade', 'Sonic Classic Limeade (Medium)', 44.44, 0.00, 11.78, 0.00, 0.00, 11.33, 450, 450, 'sonicdrivein.com', ARRAY['sonic limeade', 'limeade sonic'], '200 cal per medium. {"sodium_mg":9,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Sonic Ocean Water (medium) ~450g
-- 200 cal, 0g fat, 0g protein, 51g carbs, 0g fiber, 51g sugar, 35mg sodium, 0mg chol, 0g sat fat
('sonic_ocean_water', 'Sonic Ocean Water (Medium)', 44.44, 0.00, 11.33, 0.00, 0.00, 11.33, 450, 450, 'sonicdrivein.com', ARRAY['sonic ocean water', 'ocean water sonic', 'blue coconut drink'], '200 cal per medium. {"sodium_mg":8,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- =============================================
-- 5. PANERA BREAD
-- Source: panerabread.com, fastfoodnutrition.org
-- =============================================

-- Panera Broccoli Cheddar Soup (bowl) ~350g
-- 360 cal, 21g fat, 14g protein, 28g carbs, 3g fiber, 6g sugar, 1090mg sodium, 55mg chol, 12g sat fat
('panera_broccoli_cheddar_soup_bowl', 'Panera Bread Broccoli Cheddar Soup (Bowl)', 102.86, 4.00, 8.00, 6.00, 0.86, 1.71, 350, 350, 'panerabread.com', ARRAY['panera broccoli soup', 'panera broccoli cheddar', 'broccoli cheddar soup panera'], '360 cal per bowl. {"sodium_mg":311,"cholesterol_mg":16,"sat_fat_g":3.43,"trans_fat_g":0.0}'),

-- Panera Broccoli Cheddar Soup (cup) ~240g
-- 230 cal, 13g fat, 9g protein, 18g carbs, 2g fiber, 4g sugar, 700mg sodium, 35mg chol, 8g sat fat
('panera_broccoli_cheddar_soup_cup', 'Panera Bread Broccoli Cheddar Soup (Cup)', 95.83, 3.75, 7.50, 5.42, 0.83, 1.67, 240, 240, 'panerabread.com', ARRAY['panera broccoli soup cup', 'panera broccoli cheddar cup'], '230 cal per cup. {"sodium_mg":292,"cholesterol_mg":15,"sat_fat_g":3.33,"trans_fat_g":0.0}'),

-- Panera Broccoli Cheddar Soup (bread bowl) ~530g
-- 900 cal, 18g fat, 35g protein, 134g carbs, 8g fiber, 10g sugar, 1880mg sodium, 60mg chol, 14g sat fat
('panera_broccoli_cheddar_bread_bowl', 'Panera Bread Broccoli Cheddar Soup (Bread Bowl)', 169.81, 6.60, 25.28, 3.40, 1.51, 1.89, 530, 530, 'panerabread.com', ARRAY['panera bread bowl', 'panera broccoli bread bowl', 'bread bowl panera'], '900 cal per bread bowl. {"sodium_mg":355,"cholesterol_mg":11,"sat_fat_g":2.64,"trans_fat_g":0.0}'),

-- Panera Chicken Noodle Soup (cup) ~240g
-- 130 cal, 4g fat, 12g protein, 13g carbs, 0g fiber, 4g sugar, 960mg sodium, 40mg chol, 1g sat fat
('panera_chicken_noodle_soup_cup', 'Panera Bread Chicken Noodle Soup (Cup)', 54.17, 5.00, 5.42, 1.67, 0.00, 1.67, 240, 240, 'panerabread.com', ARRAY['panera chicken noodle', 'panera chicken soup', 'chicken noodle panera'], '130 cal per cup. {"sodium_mg":400,"cholesterol_mg":17,"sat_fat_g":0.42,"trans_fat_g":0.0}'),

-- Panera Chicken Noodle Soup (bowl) ~350g
-- 200 cal, 6g fat, 18g protein, 19g carbs, 1g fiber, 6g sugar, 1480mg sodium, 60mg chol, 1.5g sat fat
('panera_chicken_noodle_soup_bowl', 'Panera Bread Chicken Noodle Soup (Bowl)', 57.14, 5.14, 5.43, 1.71, 0.29, 1.71, 350, 350, 'panerabread.com', ARRAY['panera chicken noodle bowl', 'chicken soup panera bowl'], '200 cal per bowl. {"sodium_mg":423,"cholesterol_mg":17,"sat_fat_g":0.43,"trans_fat_g":0.0}'),

-- Panera Creamy Tomato Soup (cup) ~240g
-- 270 cal, 17g fat, 4g protein, 26g carbs, 2g fiber, 13g sugar, 820mg sodium, 35mg chol, 9g sat fat
('panera_creamy_tomato_soup_cup', 'Panera Bread Creamy Tomato Soup (Cup)', 112.50, 1.67, 10.83, 7.08, 0.83, 5.42, 240, 240, 'panerabread.com', ARRAY['panera tomato soup', 'panera cream of tomato', 'creamy tomato panera'], '270 cal per cup. {"sodium_mg":342,"cholesterol_mg":15,"sat_fat_g":3.75,"trans_fat_g":0.0}'),

-- Panera Creamy Tomato Soup (bowl) ~350g
-- 420 cal, 26g fat, 6g protein, 40g carbs, 3g fiber, 20g sugar, 1260mg sodium, 55mg chol, 14g sat fat
('panera_creamy_tomato_soup_bowl', 'Panera Bread Creamy Tomato Soup (Bowl)', 120.00, 1.71, 11.43, 7.43, 0.86, 5.71, 350, 350, 'panerabread.com', ARRAY['panera tomato soup bowl', 'creamy tomato panera bowl'], '420 cal per bowl. {"sodium_mg":360,"cholesterol_mg":16,"sat_fat_g":4.00,"trans_fat_g":0.0}'),

-- Panera Mac & Cheese (small) ~230g
-- 440 cal, 23g fat, 17g protein, 41g carbs, 2g fiber, 3g sugar, 1060mg sodium, 50mg chol, 13g sat fat
('panera_mac_cheese_small', 'Panera Bread Mac & Cheese (Small)', 191.30, 7.39, 17.83, 10.00, 0.87, 1.30, 230, 230, 'panerabread.com', ARRAY['panera mac and cheese', 'panera mac cheese', 'mac and cheese panera'], '440 cal per small. {"sodium_mg":461,"cholesterol_mg":22,"sat_fat_g":5.65,"trans_fat_g":0.0}'),

-- Panera Mac & Cheese (large) ~380g
-- 730 cal, 38g fat, 28g protein, 68g carbs, 3g fiber, 5g sugar, 1760mg sodium, 80mg chol, 21g sat fat
('panera_mac_cheese_large', 'Panera Bread Mac & Cheese (Large)', 192.11, 7.37, 17.89, 10.00, 0.79, 1.32, 380, 380, 'panerabread.com', ARRAY['panera mac and cheese large', 'panera mac cheese large'], '730 cal per large. {"sodium_mg":463,"cholesterol_mg":21,"sat_fat_g":5.53,"trans_fat_g":0.0}'),

-- Panera Turkey & Cheddar Sandwich (whole) ~400g
-- 780 cal, 45g fat, 41g protein, 52g carbs, 3g fiber, 5g sugar, 1690mg sodium, 100mg chol, 14g sat fat
('panera_turkey_cheddar_sandwich', 'Panera Bread Turkey & Cheddar Sandwich', 195.00, 10.25, 13.00, 11.25, 0.75, 1.25, 400, 400, 'panerabread.com', ARRAY['panera turkey sandwich', 'panera turkey cheddar', 'turkey sandwich panera'], '780 cal per whole sandwich. {"sodium_mg":423,"cholesterol_mg":25,"sat_fat_g":3.50,"trans_fat_g":0.0}'),

-- Panera Roasted Turkey, Apple & Cheddar Sandwich (whole) ~380g
-- 710 cal, 29g fat, 35g protein, 73g carbs, 4g fiber, 18g sugar, 1740mg sodium, 85mg chol, 11g sat fat
('panera_turkey_apple_cheddar', 'Panera Bread Roasted Turkey, Apple & Cheddar Sandwich', 186.84, 9.21, 19.21, 7.63, 1.05, 4.74, 380, 380, 'panerabread.com', ARRAY['panera turkey apple', 'panera turkey apple cheddar', 'turkey apple sandwich panera'], '710 cal per whole sandwich. {"sodium_mg":458,"cholesterol_mg":22,"sat_fat_g":2.89,"trans_fat_g":0.0}'),

-- Panera Chipotle Chicken Avocado Melt (whole) ~400g
-- 880 cal, 46g fat, 43g protein, 72g carbs, 6g fiber, 9g sugar, 2090mg sodium, 100mg chol, 16g sat fat
('panera_chipotle_chicken_avocado', 'Panera Bread Chipotle Chicken Avocado Melt', 220.00, 10.75, 18.00, 11.50, 1.50, 2.25, 400, 400, 'panerabread.com', ARRAY['panera chipotle chicken', 'panera chicken avocado', 'chipotle avocado panera'], '880 cal per whole sandwich. {"sodium_mg":523,"cholesterol_mg":25,"sat_fat_g":4.00,"trans_fat_g":0.0}'),

-- Panera Classic Grilled Cheese (whole) ~240g
-- 560 cal, 28g fat, 21g protein, 55g carbs, 2g fiber, 5g sugar, 1190mg sodium, 60mg chol, 15g sat fat
('panera_grilled_cheese', 'Panera Bread Classic Grilled Cheese', 233.33, 8.75, 22.92, 11.67, 0.83, 2.08, 240, 240, 'panerabread.com', ARRAY['panera grilled cheese', 'grilled cheese panera'], '560 cal per whole sandwich. {"sodium_mg":496,"cholesterol_mg":25,"sat_fat_g":6.25,"trans_fat_g":0.0}'),

-- Panera Bacon, Egg & Cheese on Ciabatta ~220g
-- 470 cal, 20g fat, 22g protein, 51g carbs, 2g fiber, 5g sugar, 1000mg sodium, 205mg chol, 8g sat fat
('panera_bacon_egg_cheese_ciabatta', 'Panera Bread Bacon, Egg & Cheese on Ciabatta', 213.64, 10.00, 23.18, 9.09, 0.91, 2.27, 220, 220, 'panerabread.com', ARRAY['panera bacon egg cheese', 'panera breakfast sandwich', 'bacon egg cheese panera'], '470 cal per sandwich. {"sodium_mg":455,"cholesterol_mg":93,"sat_fat_g":3.64,"trans_fat_g":0.0}'),

-- Panera Caesar Salad (whole) ~240g
-- 330 cal, 23g fat, 11g protein, 22g carbs, 3g fiber, 3g sugar, 690mg sodium, 25mg chol, 5g sat fat
('panera_caesar_salad', 'Panera Bread Caesar Salad', 137.50, 4.58, 9.17, 9.58, 1.25, 1.25, 240, 240, 'panerabread.com', ARRAY['panera caesar salad', 'caesar salad panera'], '330 cal per whole salad. {"sodium_mg":288,"cholesterol_mg":10,"sat_fat_g":2.08,"trans_fat_g":0.0}'),

-- Panera Fuji Apple Salad with Chicken (whole) ~360g
-- 550 cal, 29g fat, 31g protein, 43g carbs, 5g fiber, 21g sugar, 930mg sodium, 85mg chol, 8g sat fat
('panera_fuji_apple_chicken_salad', 'Panera Bread Fuji Apple Salad with Chicken', 152.78, 8.61, 11.94, 8.06, 1.39, 5.83, 360, 360, 'panerabread.com', ARRAY['panera fuji apple salad', 'panera chicken salad', 'fuji apple salad panera'], '550 cal per whole salad. {"sodium_mg":258,"cholesterol_mg":24,"sat_fat_g":2.22,"trans_fat_g":0.0}'),

-- Panera Chocolate Chipper Cookie ~98g
-- 440 cal, 22g fat, 5g protein, 59g carbs, 2g fiber, 35g sugar, 310mg sodium, 45mg chol, 13g sat fat
('panera_chocolate_chipper_cookie', 'Panera Bread Chocolate Chipper Cookie', 448.98, 5.10, 60.20, 22.45, 2.04, 35.71, 98, 98, 'panerabread.com', ARRAY['panera cookie', 'panera chocolate chip cookie', 'chocolate chipper panera'], '440 cal per cookie. {"sodium_mg":316,"cholesterol_mg":46,"sat_fat_g":13.27,"trans_fat_g":0.0}'),

-- Panera Cinnamon Crunch Bagel ~113g
-- 420 cal, 10g fat, 9g protein, 73g carbs, 2g fiber, 28g sugar, 450mg sodium, 0mg chol, 3.5g sat fat
('panera_cinnamon_crunch_bagel', 'Panera Bread Cinnamon Crunch Bagel', 371.68, 7.96, 64.60, 8.85, 1.77, 24.78, 113, 113, 'panerabread.com', ARRAY['panera cinnamon bagel', 'cinnamon crunch bagel panera', 'panera bagel'], '420 cal per bagel. {"sodium_mg":398,"cholesterol_mg":0,"sat_fat_g":3.10,"trans_fat_g":0.0}'),

-- Panera Plain Bagel ~104g
-- 290 cal, 1g fat, 11g protein, 58g carbs, 2g fiber, 6g sugar, 500mg sodium, 0mg chol, 0g sat fat
('panera_plain_bagel', 'Panera Bread Plain Bagel', 278.85, 10.58, 55.77, 0.96, 1.92, 5.77, 104, 104, 'panerabread.com', ARRAY['panera plain bagel', 'bagel panera'], '290 cal per bagel. {"sodium_mg":481,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Panera French Baguette (1/4) ~100g
-- 270 cal, 1g fat, 10g protein, 54g carbs, 2g fiber, 1g sugar, 640mg sodium, 0mg chol, 0g sat fat
('panera_french_baguette', 'Panera Bread French Baguette (Quarter)', 270.00, 10.00, 54.00, 1.00, 2.00, 1.00, 100, 100, 'panerabread.com', ARRAY['panera baguette', 'panera french bread', 'french baguette panera'], '270 cal per quarter baguette. {"sodium_mg":640,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- =============================================
-- 6. JACK IN THE BOX
-- Source: jackinthebox.com, fastfoodnutrition.org
-- =============================================

-- Jack in the Box Jumbo Jack (w/o cheese) - 1 burger ~228g
-- 490 cal, 23g fat, 26g protein, 44g carbs, 2g fiber, 9g sugar, 770mg sodium, 55mg chol, 8g sat fat
('jack_in_the_box_jumbo_jack', 'Jack in the Box Jumbo Jack', 214.91, 11.40, 19.30, 10.09, 0.88, 3.95, 228, 228, 'jackinthebox.com', ARRAY['jumbo jack', 'jack in the box jumbo jack', 'jitb jumbo jack'], '490 cal per burger. {"sodium_mg":338,"cholesterol_mg":24,"sat_fat_g":3.51,"trans_fat_g":0.44}'),

-- Jack in the Box Jumbo Jack with Cheese - 1 burger ~252g
-- 570 cal, 30g fat, 30g protein, 44g carbs, 2g fiber, 9g sugar, 1060mg sodium, 80mg chol, 13g sat fat
('jack_in_the_box_jumbo_jack_cheese', 'Jack in the Box Jumbo Jack with Cheese', 226.19, 11.90, 17.46, 11.90, 0.79, 3.57, 252, 252, 'jackinthebox.com', ARRAY['jumbo jack with cheese', 'jumbo jack cheese'], '570 cal per burger. {"sodium_mg":421,"cholesterol_mg":32,"sat_fat_g":5.16,"trans_fat_g":0.40}'),

-- Jack in the Box Hamburger - 1 burger ~119g
-- 280 cal, 11g fat, 14g protein, 32g carbs, 1g fiber, 6g sugar, 490mg sodium, 30mg chol, 4g sat fat
('jack_in_the_box_hamburger', 'Jack in the Box Hamburger', 235.29, 11.76, 26.89, 9.24, 0.84, 5.04, 119, 119, 'jackinthebox.com', ARRAY['jack in the box hamburger', 'jitb hamburger'], '280 cal per burger. {"sodium_mg":412,"cholesterol_mg":25,"sat_fat_g":3.36,"trans_fat_g":0.42}'),

-- Jack in the Box Classic Buttery Jack - 1 burger ~278g
-- 820 cal, 52g fat, 37g protein, 50g carbs, 2g fiber, 10g sugar, 1250mg sodium, 130mg chol, 21g sat fat
('jack_in_the_box_classic_buttery_jack', 'Jack in the Box Classic Buttery Jack', 294.96, 13.31, 17.99, 18.71, 0.72, 3.60, 278, 278, 'jackinthebox.com', ARRAY['buttery jack', 'classic buttery jack', 'jitb buttery jack'], '820 cal per burger. {"sodium_mg":450,"cholesterol_mg":47,"sat_fat_g":7.55,"trans_fat_g":0.72}'),

-- Jack in the Box Bacon Ultimate Cheeseburger - 1 burger ~304g
-- 910 cal, 56g fat, 57g protein, 44g carbs, 2g fiber, 10g sugar, 1640mg sodium, 170mg chol, 24g sat fat
('jack_in_the_box_bacon_ultimate', 'Jack in the Box Bacon Ultimate Cheeseburger', 299.34, 18.75, 14.47, 18.42, 0.66, 3.29, 304, 304, 'jackinthebox.com', ARRAY['bacon ultimate cheeseburger', 'jitb bacon ultimate'], '910 cal per burger. {"sodium_mg":539,"cholesterol_mg":56,"sat_fat_g":7.89,"trans_fat_g":0.66}'),

-- Jack in the Box Sourdough Jack - 1 burger ~243g
-- 660 cal, 35g fat, 30g protein, 55g carbs, 3g fiber, 10g sugar, 1300mg sodium, 85mg chol, 13g sat fat
('jack_in_the_box_sourdough_jack', 'Jack in the Box Sourdough Jack', 271.60, 12.35, 22.63, 14.40, 1.23, 4.12, 243, 243, 'jackinthebox.com', ARRAY['sourdough jack', 'jitb sourdough'], '660 cal per burger. {"sodium_mg":535,"cholesterol_mg":35,"sat_fat_g":5.35,"trans_fat_g":0.41}'),

-- Jack in the Box Beef Taco (1 taco) - 1 taco ~60g
-- 190 cal, 11g fat, 6g protein, 16g carbs, 2g fiber, 1g sugar, 310mg sodium, 15mg chol, 3.5g sat fat
('jack_in_the_box_beef_taco', 'Jack in the Box Beef Taco', 316.67, 10.00, 26.67, 18.33, 3.33, 1.67, 60, 60, 'jackinthebox.com', ARRAY['jack in the box taco', 'jitb taco', 'jack taco'], '190 cal per taco. {"sodium_mg":517,"cholesterol_mg":25,"sat_fat_g":5.83,"trans_fat_g":0.83}'),

-- Jack in the Box Monster Taco - 1 taco ~115g
-- 470 cal, 30g fat, 13g protein, 38g carbs, 4g fiber, 3g sugar, 730mg sodium, 30mg chol, 9g sat fat
('jack_in_the_box_monster_taco', 'Jack in the Box Monster Taco', 408.70, 11.30, 33.04, 26.09, 3.48, 2.61, 115, 115, 'jackinthebox.com', ARRAY['monster taco jitb', 'jack monster taco'], '470 cal per taco. {"sodium_mg":635,"cholesterol_mg":26,"sat_fat_g":7.83,"trans_fat_g":0.87}'),

-- Jack in the Box Cluck Sandwich - 1 sandwich ~200g
-- 490 cal, 21g fat, 27g protein, 48g carbs, 2g fiber, 7g sugar, 1070mg sodium, 50mg chol, 4g sat fat
('jack_in_the_box_cluck_sandwich', 'Jack in the Box Cluck Sandwich', 245.00, 13.50, 24.00, 10.50, 1.00, 3.50, 200, 200, 'jackinthebox.com', ARRAY['cluck sandwich jitb', 'jack chicken sandwich'], '490 cal per sandwich. {"sodium_mg":535,"cholesterol_mg":25,"sat_fat_g":2.00,"trans_fat_g":0.0}'),

-- Jack in the Box Spicy Chicken Sandwich - 1 sandwich ~218g
-- 530 cal, 23g fat, 25g protein, 55g carbs, 3g fiber, 8g sugar, 1130mg sodium, 40mg chol, 4g sat fat
('jack_in_the_box_spicy_chicken', 'Jack in the Box Spicy Chicken Sandwich', 243.12, 11.47, 25.23, 10.55, 1.38, 3.67, 218, 218, 'jackinthebox.com', ARRAY['spicy chicken jitb', 'jacks spicy chicken'], '530 cal per sandwich. {"sodium_mg":518,"cholesterol_mg":18,"sat_fat_g":1.83,"trans_fat_g":0.0}'),

-- Jack in the Box Chicken Nuggets (10 pc) - ~165g
-- 450 cal, 26g fat, 22g protein, 30g carbs, 2g fiber, 0g sugar, 990mg sodium, 50mg chol, 5g sat fat
('jack_in_the_box_chicken_nuggets', 'Jack in the Box Chicken Nuggets (10 pc)', 272.73, 13.33, 18.18, 15.76, 1.21, 0.00, 165, 165, 'jackinthebox.com', ARRAY['jitb nuggets', 'jack nuggets', 'chicken nuggets jack in the box'], '450 cal per 10 nuggets. {"sodium_mg":600,"cholesterol_mg":30,"sat_fat_g":3.03,"trans_fat_g":0.0}'),

-- Jack in the Box Breakfast Jack - 1 sandwich ~125g
-- 280 cal, 12g fat, 16g protein, 26g carbs, 0g fiber, 3g sugar, 710mg sodium, 200mg chol, 5g sat fat
('jack_in_the_box_breakfast_jack', 'Jack in the Box Breakfast Jack', 224.00, 12.80, 20.80, 9.60, 0.00, 2.40, 125, 125, 'jackinthebox.com', ARRAY['breakfast jack', 'jitb breakfast jack', 'jack breakfast sandwich'], '280 cal per sandwich. {"sodium_mg":568,"cholesterol_mg":160,"sat_fat_g":4.00,"trans_fat_g":0.0}'),

-- Jack in the Box Grande Sausage Breakfast Burrito - 1 burrito ~330g
-- 1040 cal, 60g fat, 40g protein, 80g carbs, 4g fiber, 5g sugar, 2260mg sodium, 430mg chol, 22g sat fat
('jack_in_the_box_grande_sausage_burrito', 'Jack in the Box Grande Sausage Breakfast Burrito', 315.15, 12.12, 24.24, 18.18, 1.21, 1.52, 330, 330, 'jackinthebox.com', ARRAY['grande sausage burrito', 'jitb grande burrito', 'jack grande burrito'], '1040 cal per burrito. {"sodium_mg":685,"cholesterol_mg":130,"sat_fat_g":6.67,"trans_fat_g":0.61}'),

-- Jack in the Box Seasoned Curly Fries (medium) - ~130g
-- 380 cal, 22g fat, 5g protein, 42g carbs, 4g fiber, 0g sugar, 840mg sodium, 0mg chol, 4g sat fat
('jack_in_the_box_curly_fries', 'Jack in the Box Seasoned Curly Fries (Medium)', 292.31, 3.85, 32.31, 16.92, 3.08, 0.00, 130, 130, 'jackinthebox.com', ARRAY['jitb curly fries', 'jack curly fries', 'seasoned curly fries'], '380 cal per medium. {"sodium_mg":646,"cholesterol_mg":0,"sat_fat_g":3.08,"trans_fat_g":0.0}'),

-- Jack in the Box French Fries (medium) - ~120g
-- 330 cal, 15g fat, 4g protein, 44g carbs, 3g fiber, 0g sugar, 430mg sodium, 0mg chol, 2.5g sat fat
('jack_in_the_box_french_fries', 'Jack in the Box French Fries (Medium)', 275.00, 3.33, 36.67, 12.50, 2.50, 0.00, 120, 120, 'jackinthebox.com', ARRAY['jitb fries', 'jack fries', 'french fries jack'], '330 cal per medium. {"sodium_mg":358,"cholesterol_mg":0,"sat_fat_g":2.08,"trans_fat_g":0.0}'),

-- Jack in the Box Egg Rolls (3 pc) - ~190g
-- 570 cal, 28g fat, 16g protein, 64g carbs, 4g fiber, 8g sugar, 1340mg sodium, 25mg chol, 5g sat fat
('jack_in_the_box_egg_rolls', 'Jack in the Box Egg Rolls (3 pc)', 300.00, 8.42, 33.68, 14.74, 2.11, 4.21, 190, 190, 'jackinthebox.com', ARRAY['jitb egg rolls', 'jack egg rolls', 'jumbo egg rolls'], '570 cal per 3 egg rolls. {"sodium_mg":705,"cholesterol_mg":13,"sat_fat_g":2.63,"trans_fat_g":0.0}'),

-- Jack in the Box Tiny Tacos (10 pc) - ~100g
-- 350 cal, 20g fat, 12g protein, 30g carbs, 3g fiber, 2g sugar, 600mg sodium, 25mg chol, 5g sat fat
('jack_in_the_box_tiny_tacos', 'Jack in the Box Tiny Tacos (10 pc)', 350.00, 12.00, 30.00, 20.00, 3.00, 2.00, 100, 100, 'jackinthebox.com', ARRAY['tiny tacos jitb', 'jack tiny tacos'], '350 cal per 10 tacos. {"sodium_mg":600,"cholesterol_mg":25,"sat_fat_g":5.00,"trans_fat_g":0.0}'),

-- Jack in the Box Oreo Cookie Shake (medium) ~475g
-- 810 cal, 32g fat, 17g protein, 116g carbs, 1g fiber, 92g sugar, 510mg sodium, 95mg chol, 21g sat fat
('jack_in_the_box_oreo_shake', 'Jack in the Box Oreo Cookie Shake (Medium)', 170.53, 3.58, 24.42, 6.74, 0.21, 19.37, 475, 475, 'jackinthebox.com', ARRAY['jitb oreo shake', 'jack shake', 'oreo shake jack in the box'], '810 cal per medium. {"sodium_mg":107,"cholesterol_mg":20,"sat_fat_g":4.42,"trans_fat_g":0.0}'),

-- =============================================
-- 7. WHATABURGER
-- Source: whataburger.com, fastfoodnutrition.org
-- =============================================

-- Whataburger (regular) - 1 burger ~316g
-- 590 cal, 25g fat, 29g protein, 62g carbs, 4g fiber, 12g sugar, 1220mg sodium, 45mg chol, 8g sat fat, 1g trans fat
('whataburger_original', 'Whataburger', 186.71, 9.18, 19.62, 7.91, 1.27, 3.80, 316, 316, 'whataburger.com', ARRAY['whataburger', 'whataburger original', 'whataburger classic'], '590 cal per burger. {"sodium_mg":386,"cholesterol_mg":14,"sat_fat_g":2.53,"trans_fat_g":0.32}'),

-- Whataburger Jr. - 1 burger ~165g
-- 340 cal, 15g fat, 16g protein, 34g carbs, 2g fiber, 6g sugar, 730mg sodium, 30mg chol, 5g sat fat
('whataburger_jr', 'Whataburger Jr.', 206.06, 9.70, 20.61, 9.09, 1.21, 3.64, 165, 165, 'whataburger.com', ARRAY['whataburger jr', 'whataburger junior'], '340 cal per burger. {"sodium_mg":442,"cholesterol_mg":18,"sat_fat_g":3.03,"trans_fat_g":0.30}'),

-- Double Meat Whataburger - 1 burger ~419g
-- 840 cal, 41g fat, 47g protein, 62g carbs, 4g fiber, 12g sugar, 1590mg sodium, 110mg chol, 15g sat fat
('whataburger_double_meat', 'Whataburger Double Meat', 200.48, 11.22, 14.80, 9.79, 0.95, 2.86, 419, 419, 'whataburger.com', ARRAY['whataburger double', 'double meat whataburger'], '840 cal per burger. {"sodium_mg":380,"cholesterol_mg":26,"sat_fat_g":3.58,"trans_fat_g":0.48}'),

-- Triple Meat Whataburger - 1 burger ~520g
-- 1070 cal, 57g fat, 65g protein, 62g carbs, 4g fiber, 12g sugar, 1950mg sodium, 175mg chol, 22g sat fat
('whataburger_triple_meat', 'Whataburger Triple Meat', 205.77, 12.50, 11.92, 10.96, 0.77, 2.31, 520, 520, 'whataburger.com', ARRAY['whataburger triple', 'triple meat whataburger'], '1070 cal per burger. {"sodium_mg":375,"cholesterol_mg":34,"sat_fat_g":4.23,"trans_fat_g":0.58}'),

-- Whataburger Patty Melt - 1 sandwich ~310g
-- 750 cal, 40g fat, 34g protein, 58g carbs, 3g fiber, 8g sugar, 1500mg sodium, 100mg chol, 16g sat fat
('whataburger_patty_melt', 'Whataburger Patty Melt', 241.94, 10.97, 18.71, 12.90, 0.97, 2.58, 310, 310, 'whataburger.com', ARRAY['whataburger patty melt', 'patty melt whataburger'], '750 cal per sandwich. {"sodium_mg":484,"cholesterol_mg":32,"sat_fat_g":5.16,"trans_fat_g":0.48}'),

-- Whataburger Honey BBQ Chicken Strip Sandwich - 1 sandwich ~280g
-- 730 cal, 32g fat, 34g protein, 73g carbs, 3g fiber, 17g sugar, 1650mg sodium, 65mg chol, 7g sat fat
('whataburger_honey_bbq_chicken_strip', 'Whataburger Honey BBQ Chicken Strip Sandwich', 260.71, 12.14, 26.07, 11.43, 1.07, 6.07, 280, 280, 'whataburger.com', ARRAY['whataburger honey bbq', 'honey bbq chicken whataburger'], '730 cal per sandwich. {"sodium_mg":589,"cholesterol_mg":23,"sat_fat_g":2.50,"trans_fat_g":0.0}'),

-- Whataburger Spicy Chicken Sandwich - 1 sandwich ~250g
-- 540 cal, 21g fat, 28g protein, 55g carbs, 3g fiber, 7g sugar, 1380mg sodium, 50mg chol, 4g sat fat
('whataburger_spicy_chicken_sandwich', 'Whataburger Spicy Chicken Sandwich', 216.00, 11.20, 22.00, 8.40, 1.20, 2.80, 250, 250, 'whataburger.com', ARRAY['whataburger spicy chicken', 'spicy chicken whataburger'], '540 cal per sandwich. {"sodium_mg":552,"cholesterol_mg":20,"sat_fat_g":1.60,"trans_fat_g":0.0}'),

-- Whataburger Grilled Chicken Sandwich - 1 sandwich ~260g
-- 440 cal, 14g fat, 33g protein, 42g carbs, 3g fiber, 7g sugar, 1210mg sodium, 90mg chol, 3g sat fat
('whataburger_grilled_chicken', 'Whataburger Grilled Chicken Sandwich', 169.23, 12.69, 16.15, 5.38, 1.15, 2.69, 260, 260, 'whataburger.com', ARRAY['whataburger grilled chicken', 'grilled chicken whataburger'], '440 cal per sandwich. {"sodium_mg":465,"cholesterol_mg":35,"sat_fat_g":1.15,"trans_fat_g":0.0}'),

-- Whataburger Chicken Strips (3 pc) - ~130g
-- 450 cal, 24g fat, 28g protein, 28g carbs, 1g fiber, 0g sugar, 1320mg sodium, 55mg chol, 4g sat fat
('whataburger_chicken_strips', 'Whataburger Chicken Strips (3 pc)', 346.15, 21.54, 21.54, 18.46, 0.77, 0.00, 130, 130, 'whataburger.com', ARRAY['whataburger chicken strips', 'chicken strips whataburger', 'whatachickn'], '450 cal per 3 strips. {"sodium_mg":1015,"cholesterol_mg":42,"sat_fat_g":3.08,"trans_fat_g":0.0}'),

-- Whataburger Honey Butter Chicken Biscuit - 1 biscuit ~156g
-- 560 cal, 33g fat, 13g protein, 51g carbs, 2g fiber, 9g sugar, 1050mg sodium, 30mg chol, 12g sat fat
('whataburger_honey_butter_chicken_biscuit', 'Whataburger Honey Butter Chicken Biscuit', 358.97, 8.33, 32.69, 21.15, 1.28, 5.77, 156, 156, 'whataburger.com', ARRAY['whataburger hbcb', 'honey butter chicken biscuit', 'hbcb whataburger'], '560 cal per biscuit. {"sodium_mg":673,"cholesterol_mg":19,"sat_fat_g":7.69,"trans_fat_g":0.0}'),

-- Whataburger Breakfast on a Bun (Sausage) - 1 sandwich ~188g
-- 550 cal, 34g fat, 22g protein, 35g carbs, 1g fiber, 4g sugar, 1120mg sodium, 250mg chol, 13g sat fat
('whataburger_breakfast_on_bun_sausage', 'Whataburger Breakfast on a Bun (Sausage)', 292.55, 11.70, 18.62, 18.09, 0.53, 2.13, 188, 188, 'whataburger.com', ARRAY['whataburger breakfast on a bun', 'whataburger bob sausage', 'breakfast bun whataburger'], '550 cal per sandwich. {"sodium_mg":596,"cholesterol_mg":133,"sat_fat_g":6.91,"trans_fat_g":0.0}'),

-- Whataburger Sausage, Egg & Cheese Biscuit - 1 sandwich ~210g
-- 690 cal, 44g fat, 25g protein, 43g carbs, 1g fiber, 3g sugar, 1640mg sodium, 270mg chol, 18g sat fat
('whataburger_sausage_egg_cheese_biscuit', 'Whataburger Sausage, Egg & Cheese Biscuit', 328.57, 11.90, 20.48, 20.95, 0.48, 1.43, 210, 210, 'whataburger.com', ARRAY['whataburger sausage biscuit', 'sausage egg cheese biscuit whataburger'], '690 cal per biscuit sandwich. {"sodium_mg":781,"cholesterol_mg":129,"sat_fat_g":8.57,"trans_fat_g":0.0}'),

-- Whataburger French Fries (medium) - ~130g
-- 400 cal, 20g fat, 5g protein, 51g carbs, 4g fiber, 0g sugar, 280mg sodium, 0mg chol, 3g sat fat
('whataburger_french_fries', 'Whataburger French Fries (Medium)', 307.69, 3.85, 39.23, 15.38, 3.08, 0.00, 130, 130, 'whataburger.com', ARRAY['whataburger fries', 'french fries whataburger'], '400 cal per medium. {"sodium_mg":215,"cholesterol_mg":0,"sat_fat_g":2.31,"trans_fat_g":0.0}'),

-- Whataburger Onion Rings (medium) - ~130g
-- 410 cal, 23g fat, 5g protein, 46g carbs, 2g fiber, 4g sugar, 860mg sodium, 0mg chol, 4g sat fat
('whataburger_onion_rings', 'Whataburger Onion Rings (Medium)', 315.38, 3.85, 35.38, 17.69, 1.54, 3.08, 130, 130, 'whataburger.com', ARRAY['whataburger onion rings', 'onion rings whataburger'], '410 cal per medium. {"sodium_mg":662,"cholesterol_mg":0,"sat_fat_g":3.08,"trans_fat_g":0.0}'),

-- Whataburger Bacon & Cheese Whataburger - 1 burger ~363g
-- 790 cal, 39g fat, 40g protein, 62g carbs, 4g fiber, 12g sugar, 1690mg sodium, 95mg chol, 15g sat fat
('whataburger_bacon_cheese', 'Whataburger Bacon & Cheese', 217.63, 11.02, 17.08, 10.74, 1.10, 3.31, 363, 363, 'whataburger.com', ARRAY['whataburger bacon cheese', 'bacon cheese whataburger'], '790 cal per burger. {"sodium_mg":466,"cholesterol_mg":26,"sat_fat_g":4.13,"trans_fat_g":0.41}'),

-- =============================================
-- 8. PANDA EXPRESS (expanding beyond existing 4 items)
-- Source: pandaexpress.com, fastfoodnutrition.org
-- Existing: bigger_plate, teriyaki_sauce, chili_sauce, soy_sauce
-- =============================================

-- Panda Express Orange Chicken - 1 entree 162g (5.7oz)
-- 370 cal, 17g fat, 19g protein, 38g carbs, 1g fiber, 14g sugar, 620mg sodium, 60mg chol, 3g sat fat
('panda_express_orange_chicken', 'Panda Express Orange Chicken', 228.40, 11.73, 23.46, 10.49, 0.62, 8.64, 162, 162, 'pandaexpress.com', ARRAY['panda orange chicken', 'orange chicken panda express'], '370 cal per entree. {"sodium_mg":383,"cholesterol_mg":37,"sat_fat_g":1.85,"trans_fat_g":0.0}'),

-- Panda Express Kung Pao Chicken - 1 entree 176g (6.2oz)
-- 290 cal, 19g fat, 16g protein, 14g carbs, 2g fiber, 6g sugar, 970mg sodium, 55mg chol, 3.5g sat fat
('panda_express_kung_pao_chicken', 'Panda Express Kung Pao Chicken', 164.77, 9.09, 7.95, 10.80, 1.14, 3.41, 176, 176, 'pandaexpress.com', ARRAY['panda kung pao', 'kung pao chicken panda express'], '290 cal per entree. {"sodium_mg":551,"cholesterol_mg":31,"sat_fat_g":1.99,"trans_fat_g":0.0}'),

-- Panda Express Broccoli Beef - 1 entree 153g (5.4oz)
-- 150 cal, 7g fat, 9g protein, 13g carbs, 2g fiber, 7g sugar, 520mg sodium, 12mg chol, 1.5g sat fat
('panda_express_broccoli_beef', 'Panda Express Broccoli Beef', 98.04, 5.88, 8.50, 4.58, 1.31, 4.58, 153, 153, 'pandaexpress.com', ARRAY['panda broccoli beef', 'broccoli beef panda express'], '150 cal per entree. {"sodium_mg":340,"cholesterol_mg":8,"sat_fat_g":0.98,"trans_fat_g":0.0}'),

-- Panda Express Beijing Beef - 1 entree ~180g
-- 470 cal, 26g fat, 16g protein, 42g carbs, 1g fiber, 19g sugar, 660mg sodium, 35mg chol, 5g sat fat
('panda_express_beijing_beef', 'Panda Express Beijing Beef', 261.11, 8.89, 23.33, 14.44, 0.56, 10.56, 180, 180, 'pandaexpress.com', ARRAY['panda beijing beef', 'beijing beef panda express'], '470 cal per entree. {"sodium_mg":367,"cholesterol_mg":19,"sat_fat_g":2.78,"trans_fat_g":0.0}'),

-- Panda Express Honey Walnut Shrimp - 1 entree ~162g
-- 360 cal, 23g fat, 13g protein, 27g carbs, 1g fiber, 14g sugar, 440mg sodium, 55mg chol, 4g sat fat
('panda_express_honey_walnut_shrimp', 'Panda Express Honey Walnut Shrimp', 222.22, 8.02, 16.67, 14.20, 0.62, 8.64, 162, 162, 'pandaexpress.com', ARRAY['panda honey walnut shrimp', 'honey walnut shrimp panda'], '360 cal per entree. {"sodium_mg":272,"cholesterol_mg":34,"sat_fat_g":2.47,"trans_fat_g":0.0}'),

-- Panda Express Grilled Teriyaki Chicken - 1 entree ~153g
-- 300 cal, 13g fat, 36g protein, 8g carbs, 0g fiber, 5g sugar, 530mg sodium, 120mg chol, 3g sat fat
('panda_express_grilled_teriyaki_chicken', 'Panda Express Grilled Teriyaki Chicken', 196.08, 23.53, 5.23, 8.50, 0.00, 3.27, 153, 153, 'pandaexpress.com', ARRAY['panda teriyaki chicken', 'grilled teriyaki panda express'], '300 cal per entree. {"sodium_mg":346,"cholesterol_mg":78,"sat_fat_g":1.96,"trans_fat_g":0.0}'),

-- Panda Express String Bean Chicken Breast - 1 entree ~162g
-- 190 cal, 9g fat, 14g protein, 13g carbs, 2g fiber, 6g sugar, 740mg sodium, 40mg chol, 2g sat fat
('panda_express_string_bean_chicken', 'Panda Express String Bean Chicken Breast', 117.28, 8.64, 8.02, 5.56, 1.23, 3.70, 162, 162, 'pandaexpress.com', ARRAY['panda string bean chicken', 'string bean chicken panda'], '190 cal per entree. {"sodium_mg":457,"cholesterol_mg":25,"sat_fat_g":1.23,"trans_fat_g":0.0}'),

-- Panda Express Mushroom Chicken - 1 entree ~162g
-- 220 cal, 13g fat, 14g protein, 10g carbs, 1g fiber, 5g sugar, 760mg sodium, 50mg chol, 2.5g sat fat
('panda_express_mushroom_chicken', 'Panda Express Mushroom Chicken', 135.80, 8.64, 6.17, 8.02, 0.62, 3.09, 162, 162, 'pandaexpress.com', ARRAY['panda mushroom chicken', 'mushroom chicken panda express'], '220 cal per entree. {"sodium_mg":469,"cholesterol_mg":31,"sat_fat_g":1.54,"trans_fat_g":0.0}'),

-- Panda Express SweetFire Chicken Breast - 1 entree ~162g
-- 380 cal, 15g fat, 16g protein, 44g carbs, 1g fiber, 20g sugar, 370mg sodium, 40mg chol, 2.5g sat fat
('panda_express_sweetfire_chicken', 'Panda Express SweetFire Chicken Breast', 234.57, 9.88, 27.16, 9.26, 0.62, 12.35, 162, 162, 'pandaexpress.com', ARRAY['panda sweetfire chicken', 'sweetfire chicken panda express'], '380 cal per entree. {"sodium_mg":228,"cholesterol_mg":25,"sat_fat_g":1.54,"trans_fat_g":0.0}'),

-- Panda Express Honey Sesame Chicken Breast - 1 entree ~176g
-- 490 cal, 21g fat, 19g protein, 57g carbs, 2g fiber, 28g sugar, 580mg sodium, 50mg chol, 3.5g sat fat
('panda_express_honey_sesame_chicken', 'Panda Express Honey Sesame Chicken Breast', 278.41, 10.80, 32.39, 11.93, 1.14, 15.91, 176, 176, 'pandaexpress.com', ARRAY['panda honey sesame', 'honey sesame chicken panda'], '490 cal per entree. {"sodium_mg":330,"cholesterol_mg":28,"sat_fat_g":1.99,"trans_fat_g":0.0}'),

-- Panda Express Black Pepper Chicken - 1 entree ~162g
-- 280 cal, 15g fat, 15g protein, 19g carbs, 2g fiber, 10g sugar, 730mg sodium, 45mg chol, 3g sat fat
('panda_express_black_pepper_chicken', 'Panda Express Black Pepper Chicken', 172.84, 9.26, 11.73, 9.26, 1.23, 6.17, 162, 162, 'pandaexpress.com', ARRAY['panda black pepper chicken', 'black pepper chicken panda'], '280 cal per entree. {"sodium_mg":451,"cholesterol_mg":28,"sat_fat_g":1.85,"trans_fat_g":0.0}'),

-- Panda Express Sweet & Sour Chicken Breast - 1 entree ~162g
-- 300 cal, 13g fat, 13g protein, 34g carbs, 0g fiber, 17g sugar, 260mg sodium, 35mg chol, 2g sat fat
('panda_express_sweet_sour_chicken', 'Panda Express Sweet & Sour Chicken Breast', 185.19, 8.02, 20.99, 8.02, 0.00, 10.49, 162, 162, 'pandaexpress.com', ARRAY['panda sweet and sour', 'sweet sour chicken panda'], '300 cal per entree. {"sodium_mg":160,"cholesterol_mg":22,"sat_fat_g":1.23,"trans_fat_g":0.0}'),

-- Panda Express Chow Mein (side) ~266g (9.4oz)
-- 510 cal, 20g fat, 13g protein, 80g carbs, 6g fiber, 9g sugar, 860mg sodium, 0mg chol, 3.5g sat fat
('panda_express_chow_mein', 'Panda Express Chow Mein', 191.73, 4.89, 30.08, 7.52, 2.26, 3.38, 266, 266, 'pandaexpress.com', ARRAY['panda chow mein', 'chow mein panda express'], '510 cal per side. {"sodium_mg":323,"cholesterol_mg":0,"sat_fat_g":1.32,"trans_fat_g":0.0}'),

-- Panda Express Fried Rice (side) ~264g (9.3oz)
-- 520 cal, 16g fat, 11g protein, 85g carbs, 1g fiber, 3g sugar, 850mg sodium, 120mg chol, 3g sat fat
('panda_express_fried_rice', 'Panda Express Fried Rice', 196.97, 4.17, 32.20, 6.06, 0.38, 1.14, 264, 264, 'pandaexpress.com', ARRAY['panda fried rice', 'fried rice panda express'], '520 cal per side. {"sodium_mg":322,"cholesterol_mg":45,"sat_fat_g":1.14,"trans_fat_g":0.0}'),

-- Panda Express Steamed White Rice (side) ~252g
-- 380 cal, 0g fat, 7g protein, 87g carbs, 0g fiber, 0g sugar, 0mg sodium, 0mg chol, 0g sat fat
('panda_express_steamed_white_rice', 'Panda Express Steamed White Rice', 150.79, 2.78, 34.52, 0.00, 0.00, 0.00, 252, 252, 'pandaexpress.com', ARRAY['panda white rice', 'steamed rice panda express'], '380 cal per side. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Panda Express Super Greens (side) ~198g
-- 90 cal, 3g fat, 6g protein, 10g carbs, 4g fiber, 3g sugar, 320mg sodium, 0mg chol, 0.5g sat fat
('panda_express_super_greens', 'Panda Express Super Greens', 45.45, 3.03, 5.05, 1.52, 2.02, 1.52, 198, 198, 'pandaexpress.com', ARRAY['panda super greens', 'super greens panda express', 'mixed veggies panda'], '90 cal per side. {"sodium_mg":162,"cholesterol_mg":0,"sat_fat_g":0.25,"trans_fat_g":0.0}'),

-- Panda Express Chicken Egg Roll (1 roll) ~85g
-- 200 cal, 9g fat, 8g protein, 20g carbs, 2g fiber, 2g sugar, 390mg sodium, 15mg chol, 2g sat fat
('panda_express_chicken_egg_roll', 'Panda Express Chicken Egg Roll', 235.29, 9.41, 23.53, 10.59, 2.35, 2.35, 85, 85, 'pandaexpress.com', ARRAY['panda egg roll', 'egg roll panda express'], '200 cal per roll. {"sodium_mg":459,"cholesterol_mg":18,"sat_fat_g":2.35,"trans_fat_g":0.0}'),

-- Panda Express Cream Cheese Rangoon (3 pc) ~90g
-- 190 cal, 8g fat, 5g protein, 24g carbs, 0g fiber, 1g sugar, 180mg sodium, 15mg chol, 5g sat fat
('panda_express_cream_cheese_rangoon', 'Panda Express Cream Cheese Rangoon (3 pc)', 211.11, 5.56, 26.67, 8.89, 0.00, 1.11, 90, 90, 'pandaexpress.com', ARRAY['panda rangoon', 'cream cheese rangoon panda', 'crab rangoon panda'], '190 cal per 3 pieces. {"sodium_mg":200,"cholesterol_mg":17,"sat_fat_g":5.56,"trans_fat_g":0.0}'),

-- Panda Express Chicken Potsticker (3 pc) ~100g
-- 220 cal, 9g fat, 9g protein, 24g carbs, 1g fiber, 2g sugar, 340mg sodium, 20mg chol, 2g sat fat
('panda_express_chicken_potsticker', 'Panda Express Chicken Potsticker (3 pc)', 220.00, 9.00, 24.00, 9.00, 1.00, 2.00, 100, 100, 'pandaexpress.com', ARRAY['panda potsticker', 'potsticker panda express', 'panda dumpling'], '220 cal per 3 potstickers. {"sodium_mg":340,"cholesterol_mg":20,"sat_fat_g":2.00,"trans_fat_g":0.0}'),

-- =============================================
-- 9. FIVE GUYS
-- Source: fiveguys.com, fastfoodnutrition.org
-- =============================================

-- Five Guys Hamburger (2 patties) - 1 burger 265g
-- 700 cal, 43g fat, 39g protein, 39g carbs, 2g fiber, 8g sugar, 430mg sodium, 125mg chol, 20g sat fat
('five_guys_hamburger', 'Five Guys Hamburger', 264.15, 14.72, 14.72, 16.23, 0.75, 3.02, 265, 265, 'fiveguys.com', ARRAY['five guys burger', 'five guys hamburger', '5 guys burger'], '700 cal per burger. {"sodium_mg":162,"cholesterol_mg":47,"sat_fat_g":7.55,"trans_fat_g":0.0}'),

-- Five Guys Little Hamburger (1 patty) - 1 burger 171g
-- 480 cal, 26g fat, 23g protein, 39g carbs, 2g fiber, 8g sugar, 380mg sodium, 65mg chol, 12g sat fat
('five_guys_little_hamburger', 'Five Guys Little Hamburger', 280.70, 13.45, 22.81, 15.20, 1.17, 4.68, 171, 171, 'fiveguys.com', ARRAY['five guys little burger', 'five guys small burger', '5 guys little burger'], '480 cal per burger. {"sodium_mg":222,"cholesterol_mg":38,"sat_fat_g":7.02,"trans_fat_g":0.0}'),

-- Five Guys Cheeseburger (2 patties) - 1 burger 303g
-- 840 cal, 55g fat, 47g protein, 40g carbs, 2g fiber, 9g sugar, 1050mg sodium, 165mg chol, 26g sat fat
('five_guys_cheeseburger', 'Five Guys Cheeseburger', 277.23, 15.51, 13.20, 18.15, 0.66, 2.97, 303, 303, 'fiveguys.com', ARRAY['five guys cheeseburger', '5 guys cheeseburger'], '840 cal per burger. {"sodium_mg":347,"cholesterol_mg":54,"sat_fat_g":8.58,"trans_fat_g":0.0}'),

-- Five Guys Little Cheeseburger (1 patty) - 1 burger 193g
-- 550 cal, 32g fat, 27g protein, 40g carbs, 2g fiber, 9g sugar, 690mg sodium, 85mg chol, 16g sat fat
('five_guys_little_cheeseburger', 'Five Guys Little Cheeseburger', 284.97, 13.99, 20.73, 16.58, 1.04, 4.66, 193, 193, 'fiveguys.com', ARRAY['five guys little cheeseburger', '5 guys little cheeseburger'], '550 cal per burger. {"sodium_mg":358,"cholesterol_mg":44,"sat_fat_g":8.29,"trans_fat_g":0.0}'),

-- Five Guys Bacon Cheeseburger (2 patties) - 1 burger 317g
-- 920 cal, 62g fat, 51g protein, 40g carbs, 2g fiber, 9g sugar, 1310mg sodium, 180mg chol, 30g sat fat
('five_guys_bacon_cheeseburger', 'Five Guys Bacon Cheeseburger', 290.22, 16.09, 12.62, 19.56, 0.63, 2.84, 317, 317, 'fiveguys.com', ARRAY['five guys bacon cheeseburger', '5 guys bacon cheeseburger'], '920 cal per burger. {"sodium_mg":413,"cholesterol_mg":57,"sat_fat_g":9.46,"trans_fat_g":0.0}'),

-- Five Guys Bacon Burger (2 patties) - 1 burger 285g
-- 780 cal, 50g fat, 45g protein, 39g carbs, 2g fiber, 8g sugar, 700mg sodium, 140mg chol, 23g sat fat
('five_guys_bacon_burger', 'Five Guys Bacon Burger', 273.68, 15.79, 13.68, 17.54, 0.70, 2.81, 285, 285, 'fiveguys.com', ARRAY['five guys bacon burger', '5 guys bacon burger'], '780 cal per burger. {"sodium_mg":246,"cholesterol_mg":49,"sat_fat_g":8.07,"trans_fat_g":0.0}'),

-- Five Guys Hot Dog - 1 hot dog 167g
-- 545 cal, 35g fat, 18g protein, 40g carbs, 2g fiber, 8g sugar, 1130mg sodium, 61mg chol, 16g sat fat
('five_guys_hot_dog', 'Five Guys Hot Dog', 326.35, 10.78, 23.95, 20.96, 1.20, 4.79, 167, 167, 'fiveguys.com', ARRAY['five guys hot dog', '5 guys hot dog', 'five guys kosher hot dog'], '545 cal per hot dog. {"sodium_mg":677,"cholesterol_mg":37,"sat_fat_g":9.58,"trans_fat_g":0.0}'),

-- Five Guys Cheese Dog - 1 hot dog 195g
-- 615 cal, 41g fat, 22g protein, 41g carbs, 2g fiber, 9g sugar, 1440mg sodium, 80mg chol, 20g sat fat
('five_guys_cheese_dog', 'Five Guys Cheese Dog', 315.38, 11.28, 21.03, 21.03, 1.03, 4.62, 195, 195, 'fiveguys.com', ARRAY['five guys cheese dog', '5 guys cheese dog'], '615 cal per cheese dog. {"sodium_mg":738,"cholesterol_mg":41,"sat_fat_g":10.26,"trans_fat_g":0.0}'),

-- Five Guys Bacon Dog - 1 hot dog 183g
-- 625 cal, 42g fat, 22g protein, 40g carbs, 2g fiber, 8g sugar, 1400mg sodium, 75mg chol, 19g sat fat
('five_guys_bacon_dog', 'Five Guys Bacon Dog', 341.53, 12.02, 21.86, 22.95, 1.09, 4.37, 183, 183, 'fiveguys.com', ARRAY['five guys bacon dog', '5 guys bacon dog'], '625 cal per bacon dog. {"sodium_mg":765,"cholesterol_mg":41,"sat_fat_g":10.38,"trans_fat_g":0.0}'),

-- Five Guys Grilled Cheese - 1 sandwich ~200g
-- 470 cal, 26g fat, 18g protein, 41g carbs, 2g fiber, 8g sugar, 715mg sodium, 50mg chol, 14g sat fat
('five_guys_grilled_cheese', 'Five Guys Grilled Cheese', 235.00, 9.00, 20.50, 13.00, 1.00, 4.00, 200, 200, 'fiveguys.com', ARRAY['five guys grilled cheese', '5 guys grilled cheese'], '470 cal per sandwich. {"sodium_mg":358,"cholesterol_mg":25,"sat_fat_g":7.00,"trans_fat_g":0.0}'),

-- Five Guys Veggie Sandwich - 1 sandwich ~200g
-- 280 cal, 15g fat, 10g protein, 39g carbs, 3g fiber, 8g sugar, 420mg sodium, 0mg chol, 6g sat fat
('five_guys_veggie_sandwich', 'Five Guys Veggie Sandwich', 140.00, 5.00, 19.50, 7.50, 1.50, 4.00, 200, 200, 'fiveguys.com', ARRAY['five guys veggie', '5 guys veggie sandwich'], '280 cal per sandwich. {"sodium_mg":210,"cholesterol_mg":0,"sat_fat_g":3.00,"trans_fat_g":0.0}'),

-- Five Guys BLT - 1 sandwich ~175g
-- 490 cal, 33g fat, 18g protein, 39g carbs, 2g fiber, 8g sugar, 830mg sodium, 40mg chol, 13g sat fat
('five_guys_blt', 'Five Guys BLT', 280.00, 10.29, 22.29, 18.86, 1.14, 4.57, 175, 175, 'fiveguys.com', ARRAY['five guys blt', '5 guys blt'], '490 cal per sandwich. {"sodium_mg":474,"cholesterol_mg":23,"sat_fat_g":7.43,"trans_fat_g":0.0}'),

-- Five Guys Regular Fries - 1 serving 411g
-- 620 cal, 30g fat, 9g protein, 78g carbs, 7g fiber, 0g sugar, 90mg sodium, 0mg chol, 6g sat fat
('five_guys_regular_fries', 'Five Guys Regular Fries', 150.85, 2.19, 18.98, 7.30, 1.70, 0.00, 411, 411, 'fiveguys.com', ARRAY['five guys fries', '5 guys fries', 'five guys regular fries'], '620 cal per regular. {"sodium_mg":22,"cholesterol_mg":0,"sat_fat_g":1.46,"trans_fat_g":0.0}'),

-- Five Guys Little Fries - 1 serving 227g
-- 528 cal, 26g fat, 8g protein, 68g carbs, 6g fiber, 0g sugar, 50mg sodium, 0mg chol, 5g sat fat
('five_guys_little_fries', 'Five Guys Little Fries', 232.60, 3.52, 29.96, 11.45, 2.64, 0.00, 227, 227, 'fiveguys.com', ARRAY['five guys small fries', '5 guys little fries'], '528 cal per small. {"sodium_mg":22,"cholesterol_mg":0,"sat_fat_g":2.20,"trans_fat_g":0.0}'),

-- Five Guys Cajun Fries (regular) - 1 serving 411g
-- 620 cal, 30g fat, 9g protein, 78g carbs, 7g fiber, 0g sugar, 680mg sodium, 0mg chol, 6g sat fat
('five_guys_cajun_fries', 'Five Guys Cajun Fries (Regular)', 150.85, 2.19, 18.98, 7.30, 1.70, 0.00, 411, 411, 'fiveguys.com', ARRAY['five guys cajun fries', '5 guys cajun fries'], '620 cal per regular. {"sodium_mg":165,"cholesterol_mg":0,"sat_fat_g":1.46,"trans_fat_g":0.0}'),

-- Five Guys Chocolate Milkshake (regular) ~475g
-- 840 cal, 52g fat, 15g protein, 83g carbs, 2g fiber, 69g sugar, 340mg sodium, 155mg chol, 33g sat fat
('five_guys_chocolate_shake', 'Five Guys Chocolate Milkshake', 176.84, 3.16, 17.47, 10.95, 0.42, 14.53, 475, 475, 'fiveguys.com', ARRAY['five guys chocolate shake', '5 guys milkshake', 'five guys shake'], '840 cal per regular. {"sodium_mg":72,"cholesterol_mg":33,"sat_fat_g":6.95,"trans_fat_g":0.0}'),

-- Five Guys Vanilla Milkshake (regular) ~450g
-- 670 cal, 39g fat, 12g protein, 69g carbs, 0g fiber, 57g sugar, 310mg sodium, 125mg chol, 25g sat fat
('five_guys_vanilla_shake', 'Five Guys Vanilla Milkshake', 148.89, 2.67, 15.33, 8.67, 0.00, 12.67, 450, 450, 'fiveguys.com', ARRAY['five guys vanilla shake', '5 guys vanilla shake'], '670 cal per regular. {"sodium_mg":69,"cholesterol_mg":28,"sat_fat_g":5.56,"trans_fat_g":0.0}'),

-- =============================================
-- 10. RAISING CANE'S
-- Source: raisingcanes.com, fastfoodnutrition.org
-- =============================================

-- Raising Cane's Chicken Finger (1 pc) - 1 finger ~43g
-- 140 cal, 7g fat, 13g protein, 6g carbs, 0g fiber, 0g sugar, 370mg sodium, 35mg chol, 1g sat fat
('raising_canes_chicken_finger', 'Raising Cane''s Chicken Finger (1 pc)', 325.58, 30.23, 13.95, 16.28, 0.00, 0.00, 43, 43, 'raisingcanes.com', ARRAY['raising canes finger', 'canes chicken finger', 'raising canes tender'], '140 cal per finger. {"sodium_mg":860,"cholesterol_mg":81,"sat_fat_g":2.33,"trans_fat_g":0.0}'),

-- Raising Cane's The Box Combo (4 fingers, fries, toast, coleslaw, sauce) ~430g
-- 1290 cal, 65g fat, 60g protein, 118g carbs, 5g fiber, 9g sugar, 2760mg sodium, 180mg chol, 12g sat fat
('raising_canes_the_box', 'Raising Cane''s The Box Combo', 300.00, 13.95, 27.44, 15.12, 1.16, 2.09, 430, 430, 'raisingcanes.com', ARRAY['raising canes box combo', 'canes box', 'the box raising canes'], '1290 cal per combo. {"sodium_mg":642,"cholesterol_mg":42,"sat_fat_g":2.79,"trans_fat_g":0.0}'),

-- Raising Cane's Caniac Combo (6 fingers, fries, 2 toast, coleslaw, 2 sauce, drink) ~600g
-- 1780 cal, 97g fat, 90g protein, 122g carbs, 7g fiber, 12g sugar, 4210mg sodium, 270mg chol, 18g sat fat
('raising_canes_caniac', 'Raising Cane''s Caniac Combo', 296.67, 15.00, 20.33, 16.17, 1.17, 2.00, 600, 600, 'raisingcanes.com', ARRAY['raising canes caniac', 'caniac combo', 'canes caniac'], '1780 cal per combo. {"sodium_mg":702,"cholesterol_mg":45,"sat_fat_g":3.00,"trans_fat_g":0.0}'),

-- Raising Cane's 3 Finger Combo (3 fingers, fries, toast, sauce) ~350g
-- 1060 cal, 50g fat, 48g protein, 102g carbs, 4g fiber, 7g sugar, 2190mg sodium, 140mg chol, 9g sat fat
('raising_canes_3_finger_combo', 'Raising Cane''s 3 Finger Combo', 302.86, 13.71, 29.14, 14.29, 1.14, 2.00, 350, 350, 'raisingcanes.com', ARRAY['raising canes 3 finger', 'canes 3 finger combo'], '1060 cal per combo. {"sodium_mg":626,"cholesterol_mg":40,"sat_fat_g":2.57,"trans_fat_g":0.0}'),

-- Raising Cane's Kids Combo (2 fingers, fries, drink) ~250g
-- 650 cal, 30g fat, 28g protein, 68g carbs, 3g fiber, 4g sugar, 1210mg sodium, 80mg chol, 5g sat fat
('raising_canes_kids_combo', 'Raising Cane''s Kids Combo', 260.00, 11.20, 27.20, 12.00, 1.20, 1.60, 250, 250, 'raisingcanes.com', ARRAY['raising canes kids', 'canes kids combo', 'kids meal canes'], '650 cal per combo. {"sodium_mg":484,"cholesterol_mg":32,"sat_fat_g":2.00,"trans_fat_g":0.0}'),

-- Raising Cane's Cane's Sauce (1 container) ~43g (1.5oz)
-- 190 cal, 18g fat, 0g protein, 6g carbs, 0g fiber, 4g sugar, 290mg sodium, 15mg chol, 3g sat fat
('raising_canes_sauce', 'Raising Cane''s Cane''s Sauce', 441.86, 0.00, 13.95, 41.86, 0.00, 9.30, 43, 43, 'raisingcanes.com', ARRAY['canes sauce', 'raising canes dipping sauce', 'canes dip'], '190 cal per container. {"sodium_mg":674,"cholesterol_mg":35,"sat_fat_g":6.98,"trans_fat_g":0.0}'),

-- Raising Cane's Crinkle-Cut Fries ~168g
-- 400 cal, 18g fat, 5g protein, 55g carbs, 4g fiber, 0g sugar, 590mg sodium, 0mg chol, 3g sat fat
('raising_canes_fries', 'Raising Cane''s Crinkle-Cut Fries', 238.10, 2.98, 32.74, 10.71, 2.38, 0.00, 168, 168, 'raisingcanes.com', ARRAY['raising canes fries', 'canes fries', 'crinkle fries canes'], '400 cal per regular. {"sodium_mg":351,"cholesterol_mg":0,"sat_fat_g":1.79,"trans_fat_g":0.0}'),

-- Raising Cane's Texas Toast (1 slice) ~50g
-- 150 cal, 6g fat, 4g protein, 20g carbs, 1g fiber, 2g sugar, 230mg sodium, 0mg chol, 1g sat fat
('raising_canes_texas_toast', 'Raising Cane''s Texas Toast', 300.00, 8.00, 40.00, 12.00, 2.00, 4.00, 50, 50, 'raisingcanes.com', ARRAY['raising canes toast', 'canes texas toast', 'texas toast canes'], '150 cal per slice. {"sodium_mg":460,"cholesterol_mg":0,"sat_fat_g":2.00,"trans_fat_g":0.0}'),

-- Raising Cane's Coleslaw ~120g
-- 100 cal, 6g fat, 1g protein, 12g carbs, 2g fiber, 8g sugar, 310mg sodium, 5mg chol, 1g sat fat
('raising_canes_coleslaw', 'Raising Cane''s Coleslaw', 83.33, 0.83, 10.00, 5.00, 1.67, 6.67, 120, 120, 'raisingcanes.com', ARRAY['raising canes coleslaw', 'canes coleslaw', 'canes slaw'], '100 cal per serving. {"sodium_mg":258,"cholesterol_mg":4,"sat_fat_g":0.83,"trans_fat_g":0.0}'),

-- Raising Cane's Sweet Tea (22oz) ~650g
-- 230 cal, 0g fat, 0g protein, 57g carbs, 0g fiber, 57g sugar, 15mg sodium, 0mg chol, 0g sat fat
('raising_canes_sweet_tea', 'Raising Cane''s Sweet Tea (22 oz)', 35.38, 0.00, 8.77, 0.00, 0.00, 8.77, 650, 650, 'raisingcanes.com', ARRAY['raising canes sweet tea', 'canes sweet tea', 'sweet tea canes'], '230 cal per 22oz cup. {"sodium_mg":2,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}'),

-- Raising Cane's Lemonade (22oz) ~650g
-- 290 cal, 0g fat, 0g protein, 76g carbs, 0g fiber, 74g sugar, 20mg sodium, 0mg chol, 0g sat fat
('raising_canes_lemonade', 'Raising Cane''s Lemonade (22 oz)', 44.62, 0.00, 11.69, 0.00, 0.00, 11.38, 650, 650, 'raisingcanes.com', ARRAY['raising canes lemonade', 'canes lemonade', 'lemonade canes'], '290 cal per 22oz cup. {"sodium_mg":3,"cholesterol_mg":0,"sat_fat_g":0.0,"trans_fat_g":0.0}')
