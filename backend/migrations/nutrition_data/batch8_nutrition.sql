-- =====================================================
-- BATCH 8: Restaurant Nutrition Data (with micronutrients)
-- Church's Chicken, El Pollo Loco, Del Taco, Moe's,
-- Qdoba, Pei Wei, P.F. Chang's, Sweetgreen, Cava, Waba Grill
-- Sources: fastfoodnutrition.org, healthyfastfood.org,
--          fatsecret.com, myfooddiary.com, official sites
-- =====================================================

-- =====================================================
-- 1. CHURCH'S CHICKEN
-- Source: churchs.com, fastfoodnutrition.org, fatsecret.com
-- =====================================================

-- Church's Original Chicken Breast: 250 cal, 14f, 23p, 9c per breast (~170g)
('churchs_original_chicken_breast', 'Church''s Original Chicken Breast', 147.1, 13.5, 5.3, 8.2, 0.0, 0.0, 170, 170, 'churchs.com', ARRAY['churchs breast', 'church chicken breast'], '250 cal per breast. {"sodium_mg":400,"cholesterol_mg":47,"sat_fat_g":1.8,"trans_fat_g":0}'),

-- Church's Original Chicken Leg: 150 cal, 8f, 12p, 6c per leg (~80g)
('churchs_original_chicken_leg', 'Church''s Original Chicken Leg', 187.5, 15.0, 7.5, 10.0, 0.0, 0.0, 80, 80, 'churchs.com', ARRAY['churchs leg', 'church chicken leg'], '150 cal per leg. {"sodium_mg":500,"cholesterol_mg":75,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Church's Original Chicken Thigh: 360 cal, 27f, 18p, 12c per thigh (~111g)
('churchs_original_chicken_thigh', 'Church''s Original Chicken Thigh', 324.3, 16.2, 10.8, 24.3, 0.9, 0.0, 111, 111, 'churchs.com', ARRAY['churchs thigh', 'church chicken thigh'], '360 cal per thigh. {"sodium_mg":604,"cholesterol_mg":85.6,"sat_fat_g":6.3,"trans_fat_g":0}'),

-- Church's Original Chicken Wing: 290 cal, 18f, 24p, 8c per wing (~100g)
('churchs_original_chicken_wing', 'Church''s Original Chicken Wing', 290.0, 24.0, 8.0, 18.0, 0.0, 0.0, 100, 100, 'churchs.com', ARRAY['churchs wing', 'church chicken wing'], '290 cal per wing. {"sodium_mg":710,"cholesterol_mg":100,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- Church's Spicy Chicken Breast: 280 cal, 17f, 22p, 12c per breast (~170g)
('churchs_spicy_chicken_breast', 'Church''s Spicy Chicken Breast', 164.7, 12.9, 7.1, 10.0, 0.6, 0.0, 170, 170, 'churchs.com', ARRAY['churchs spicy breast'], '280 cal per breast. {"sodium_mg":470.6,"cholesterol_mg":47.1,"sat_fat_g":2.4,"trans_fat_g":0}'),

-- Church's Spicy Chicken Leg: 160 cal, 9f, 13p, 9c per leg (~80g)
('churchs_spicy_chicken_leg', 'Church''s Spicy Chicken Leg', 200.0, 16.3, 11.3, 11.3, 1.3, 0.0, 80, 80, 'churchs.com', ARRAY['churchs spicy leg'], '160 cal per leg. {"sodium_mg":550,"cholesterol_mg":75,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Church's Spicy Chicken Thigh: 380 cal, 25f, 17p, 21c per thigh (~111g)
('churchs_spicy_chicken_thigh', 'Church''s Spicy Chicken Thigh', 342.3, 15.3, 18.9, 22.5, 0.9, 0.0, 111, 111, 'churchs.com', ARRAY['churchs spicy thigh'], '380 cal per thigh. {"sodium_mg":792.8,"cholesterol_mg":81.1,"sat_fat_g":5.4,"trans_fat_g":0}'),

-- Church's Spicy Chicken Wing: 300 cal, 20f, 22p, 9c per wing (~100g)
('churchs_spicy_chicken_wing', 'Church''s Spicy Chicken Wing', 300.0, 22.0, 9.0, 20.0, 0.0, 0.0, 100, 100, 'churchs.com', ARRAY['churchs spicy wing'], '300 cal per wing. {"sodium_mg":760,"cholesterol_mg":100,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- Church's Chicken Tender (1pc): 90 cal, 4f, 8p, 5c per tender (~45g)
('churchs_chicken_tender', 'Church''s Chicken Tender', 200.0, 17.8, 11.1, 8.9, 0.0, 0.0, 45, 45, 'churchs.com', ARRAY['churchs tender', 'church tender strip'], '90 cal per tender. {"sodium_mg":533,"cholesterol_mg":44,"sat_fat_g":2.2,"trans_fat_g":0}'),

-- Church's Honey-Butter Biscuit: 230 cal, 15f, 3p, 25c per biscuit (~60g)
('churchs_honey_butter_biscuit', 'Church''s Honey-Butter Biscuit', 383.3, 5.0, 41.7, 25.0, 1.7, 8.3, 60, 60, 'churchs.com', ARRAY['churchs biscuit', 'church biscuit'], '230 cal per biscuit. {"sodium_mg":766.7,"cholesterol_mg":8.3,"sat_fat_g":13.3,"trans_fat_g":0}'),

-- Church's Chicken Biscuit: 380 cal, 19f, 17p, 39c per sandwich (~140g)
('churchs_chicken_biscuit', 'Church''s Chicken Biscuit', 271.4, 12.1, 27.9, 13.6, 0.7, 3.6, 140, 140, 'churchs.com', ARRAY['churchs chicken biscuit sandwich'], '380 cal per sandwich. {"sodium_mg":607,"cholesterol_mg":42.9,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- Church's Bacon Egg & Cheese Biscuit: 550 cal, 40f, 21p, 31c (~180g)
('churchs_bacon_egg_cheese_biscuit', 'Church''s Bacon Egg & Cheese Biscuit', 305.6, 11.7, 17.2, 22.2, 0.6, 2.2, 180, 180, 'churchs.com', ARRAY['churchs breakfast biscuit bacon'], '550 cal per sandwich. {"sodium_mg":722,"cholesterol_mg":111,"sat_fat_g":11.1,"trans_fat_g":0}'),

-- Church's Signature Chicken Sandwich Original: 620 cal, 31f, 32p, 54c (~220g)
('churchs_signature_sandwich', 'Church''s Signature Chicken Sandwich', 281.8, 14.5, 24.5, 14.1, 1.4, 3.6, 220, 220, 'churchs.com', ARRAY['churchs chicken sandwich', 'church sandwich'], '620 cal per sandwich. {"sodium_mg":727,"cholesterol_mg":50,"sat_fat_g":4.5,"trans_fat_g":0}'),

-- Church's French Fries Regular: 210 cal, 9f, 3p, 29c (~73g)
('churchs_french_fries', 'Church''s French Fries', 287.7, 4.1, 39.7, 12.3, 2.7, 0.0, 73, 73, 'churchs.com', ARRAY['churchs fries', 'church fries'], '210 cal per regular serving. {"sodium_mg":589,"cholesterol_mg":0,"sat_fat_g":2.7,"trans_fat_g":0}'),

-- Church's Baked Mac & Cheese Regular: 210 cal, 12f, 9p, 19c (~120g)
('churchs_mac_and_cheese', 'Church''s Baked Mac & Cheese', 175.0, 7.5, 15.8, 10.0, 0.8, 1.7, 120, 120, 'churchs.com', ARRAY['churchs mac cheese', 'church macaroni'], '210 cal per regular. {"sodium_mg":600,"cholesterol_mg":25,"sat_fat_g":5.8,"trans_fat_g":0}'),

-- Church's Mashed Potatoes & Gravy Regular: 110 cal, 1f, 2p, 24c (~130g)
('churchs_mashed_potatoes', 'Church''s Mashed Potatoes & Gravy', 84.6, 1.5, 18.5, 0.8, 1.5, 0.8, 130, 130, 'churchs.com', ARRAY['churchs mashed potatoes', 'church potatoes gravy'], '110 cal per regular. {"sodium_mg":408,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- Church's Fried Okra Regular: 280 cal, 15f, 3p, 30c (~100g)
('churchs_fried_okra', 'Church''s Fried Okra', 280.0, 3.0, 30.0, 15.0, 3.0, 1.0, 100, 100, 'churchs.com', ARRAY['churchs okra', 'church fried okra'], '280 cal per regular. {"sodium_mg":810,"cholesterol_mg":0,"sat_fat_g":3.0,"trans_fat_g":0}'),

-- Church's Cole Slaw Regular: 170 cal, 12f, 1p, 16c (~110g)
('churchs_cole_slaw', 'Church''s Cole Slaw', 154.5, 0.9, 14.5, 10.9, 1.8, 10.9, 110, 110, 'churchs.com', ARRAY['churchs coleslaw', 'church slaw'], '170 cal per regular. {"sodium_mg":218,"cholesterol_mg":9.1,"sat_fat_g":1.8,"trans_fat_g":0}'),

-- Church's Jalapeno Cheese Bombers (4pc): 230 cal, 12f, 6p, 24c (~90g)
('churchs_jalapeno_bombers', 'Church''s Jalapeno Cheese Bombers', 255.6, 6.7, 26.7, 13.3, 1.1, 2.2, 90, 90, 'churchs.com', ARRAY['churchs bombers', 'church jalapeno poppers'], '230 cal per 4pc. {"sodium_mg":667,"cholesterol_mg":11.1,"sat_fat_g":4.4,"trans_fat_g":0}'),

-- Church's Apple Pie: 270 cal, 13f, 3p, 36c (~100g)
('churchs_apple_pie', 'Church''s Apple Pie', 270.0, 3.0, 36.0, 13.0, 1.0, 18.0, 100, 100, 'churchs.com', ARRAY['churchs pie', 'church apple pie'], '270 cal per pie. {"sodium_mg":290,"cholesterol_mg":0,"sat_fat_g":6.0,"trans_fat_g":0}'),

-- Church's Frosted Honey Butter Biscuit: 320 cal, 16f, 4p, 40c (~80g)
('churchs_frosted_honey_biscuit', 'Church''s Frosted Honey Butter Biscuit', 400.0, 5.0, 50.0, 20.0, 0.0, 25.0, 80, 80, 'churchs.com', ARRAY['churchs frosted biscuit'], '320 cal per biscuit. {"sodium_mg":500,"cholesterol_mg":6.3,"sat_fat_g":10.0,"trans_fat_g":0}'),

-- Church's Chicken Fried Steak: 470 cal, 27f, 16p, 40c (~180g)
('churchs_chicken_fried_steak', 'Church''s Chicken Fried Steak', 261.1, 8.9, 22.2, 15.0, 1.7, 1.1, 180, 180, 'churchs.com', ARRAY['churchs fried steak', 'church country fried steak'], '470 cal per piece. {"sodium_mg":694,"cholesterol_mg":33.3,"sat_fat_g":5.6,"trans_fat_g":0}'),

-- =====================================================
-- 2. EL POLLO LOCO
-- Source: elpolloloco.com, healthyfastfood.org
-- =====================================================

-- El Pollo Loco Fire-Grilled Chicken Breast: 220 cal, 9f, 36p, 0c (~170g)
('epl_fire_grilled_breast', 'El Pollo Loco Fire-Grilled Chicken Breast', 129.4, 21.2, 0.0, 5.3, 0.0, 0.0, 170, 170, 'elpolloloco.com', ARRAY['el pollo loco breast', 'epl chicken breast'], '220 cal per breast. {"sodium_mg":364.7,"cholesterol_mg":82.4,"sat_fat_g":1.5,"trans_fat_g":0}'),

-- El Pollo Loco Fire-Grilled Chicken Thigh: 210 cal, 15f, 21p, 0c (~120g)
('epl_fire_grilled_thigh', 'El Pollo Loco Fire-Grilled Chicken Thigh', 175.0, 17.5, 0.0, 12.5, 0.0, 0.0, 120, 120, 'elpolloloco.com', ARRAY['el pollo loco thigh', 'epl chicken thigh'], '210 cal per thigh. {"sodium_mg":383,"cholesterol_mg":100,"sat_fat_g":4.2,"trans_fat_g":0}'),

-- El Pollo Loco Fire-Grilled Chicken Leg: 80 cal, 4f, 12p, 0c (~60g)
('epl_fire_grilled_leg', 'El Pollo Loco Fire-Grilled Chicken Leg', 133.3, 20.0, 0.0, 6.7, 0.0, 0.0, 60, 60, 'elpolloloco.com', ARRAY['el pollo loco leg', 'epl chicken leg'], '80 cal per leg. {"sodium_mg":417,"cholesterol_mg":100,"sat_fat_g":1.7,"trans_fat_g":0}'),

-- El Pollo Loco Fire-Grilled Chicken Wing: 90 cal, 5f, 12p, 0c (~50g)
('epl_fire_grilled_wing', 'El Pollo Loco Fire-Grilled Chicken Wing', 180.0, 24.0, 0.0, 10.0, 0.0, 0.0, 50, 50, 'elpolloloco.com', ARRAY['el pollo loco wing', 'epl chicken wing'], '90 cal per wing. {"sodium_mg":380,"cholesterol_mg":100,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- El Pollo Loco Original Pollo Bowl: 530 cal, 7f, 36p, 80c (~400g)
('epl_original_pollo_bowl', 'El Pollo Loco Original Pollo Bowl', 132.5, 9.0, 20.0, 1.8, 2.5, 0.8, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco bowl', 'epl pollo bowl'], '530 cal per bowl. {"sodium_mg":420,"cholesterol_mg":17.5,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- El Pollo Loco Double Chicken Bowl: 860 cal, 27f, 65p, 86c (~500g)
('epl_double_chicken_bowl', 'El Pollo Loco Double Chicken Bowl', 172.0, 13.0, 17.2, 5.4, 2.6, 1.0, 500, 500, 'elpolloloco.com', ARRAY['el pollo loco double bowl'], '860 cal per bowl. {"sodium_mg":460,"cholesterol_mg":40,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- El Pollo Loco Grande Avocado Chicken Bowl: 780 cal, 26f, 45p, 89c (~480g)
('epl_grande_avocado_bowl', 'El Pollo Loco Grande Avocado Chicken Bowl', 162.5, 9.4, 18.5, 5.4, 2.9, 1.3, 480, 480, 'elpolloloco.com', ARRAY['el pollo loco grande bowl', 'epl avocado bowl'], '780 cal per bowl. {"sodium_mg":442,"cholesterol_mg":31.3,"sat_fat_g":1.5,"trans_fat_g":0}'),

-- El Pollo Loco Classic Chicken Burrito: 510 cal, 15f, 26p, 65c (~300g)
('epl_classic_chicken_burrito', 'El Pollo Loco Classic Chicken Burrito', 170.0, 8.7, 21.7, 5.0, 1.7, 0.3, 300, 300, 'elpolloloco.com', ARRAY['el pollo loco burrito', 'epl classic burrito'], '510 cal per burrito. {"sodium_mg":470,"cholesterol_mg":25,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- El Pollo Loco Chicken Avocado Burrito: 890 cal, 48f, 46p, 71c (~400g)
('epl_chicken_avocado_burrito', 'El Pollo Loco Chicken Avocado Burrito', 222.5, 11.5, 17.8, 12.0, 2.5, 1.3, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco avocado burrito'], '890 cal per burrito. {"sodium_mg":465,"cholesterol_mg":43.8,"sat_fat_g":4.5,"trans_fat_g":0}'),

-- El Pollo Loco Ranchero Burrito: 870 cal, 40f, 44p, 84c (~400g)
('epl_ranchero_burrito', 'El Pollo Loco Ranchero Burrito', 217.5, 11.0, 21.0, 10.0, 1.8, 1.3, 400, 400, 'elpolloloco.com', ARRAY['el pollo loco ranchero'], '870 cal per burrito. {"sodium_mg":530,"cholesterol_mg":43.8,"sat_fat_g":4.0,"trans_fat_g":0}'),

-- El Pollo Loco Original BRC Burrito: 410 cal, 11f, 14p, 61c (~250g)
('epl_brc_burrito', 'El Pollo Loco Original BRC Burrito', 164.0, 5.6, 24.4, 4.4, 2.0, 0.4, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco brc', 'epl bean rice cheese'], '410 cal per burrito. {"sodium_mg":464,"cholesterol_mg":8,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- El Pollo Loco Chicken Avocado Quesadilla: 940 cal, 59f, 47p, 60c (~300g)
('epl_chicken_avocado_quesadilla', 'El Pollo Loco Chicken Avocado Quesadilla', 313.3, 15.7, 20.0, 19.7, 2.0, 1.0, 300, 300, 'elpolloloco.com', ARRAY['el pollo loco quesadilla'], '940 cal per quesadilla. {"sodium_mg":603,"cholesterol_mg":56.7,"sat_fat_g":7.0,"trans_fat_g":0}'),

-- El Pollo Loco Double Chicken Avocado Salad: 370 cal, 15f, 48p, 14c (~350g)
('epl_double_chicken_avocado_salad', 'El Pollo Loco Double Chicken Avocado Salad', 105.7, 13.7, 4.0, 4.3, 1.7, 1.7, 350, 350, 'elpolloloco.com', ARRAY['el pollo loco salad', 'epl avocado salad'], '370 cal per salad. {"sodium_mg":326,"cholesterol_mg":40,"sat_fat_g":1.1,"trans_fat_g":0}'),

-- El Pollo Loco Chicken Taco Al Carbon: 160 cal, 6f, 10p, 18c (~100g)
('epl_chicken_taco_al_carbon', 'El Pollo Loco Chicken Taco Al Carbon', 160.0, 10.0, 18.0, 6.0, 1.0, 1.0, 100, 100, 'elpolloloco.com', ARRAY['el pollo loco taco', 'epl taco al carbon'], '160 cal per taco. {"sodium_mg":370,"cholesterol_mg":30,"sat_fat_g":1.5,"trans_fat_g":0}'),

-- El Pollo Loco Rice large: 380 cal, 4f, 8p, 76c (~250g)
('epl_rice', 'El Pollo Loco Rice', 152.0, 3.2, 30.4, 1.6, 0.4, 1.2, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco rice', 'epl spanish rice'], '380 cal per large. {"sodium_mg":380,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- El Pollo Loco Black Beans large: 370 cal, 2.5f, 22p, 65c (~250g)
('epl_black_beans', 'El Pollo Loco Black Beans', 148.0, 8.8, 26.0, 1.0, 12.0, 1.6, 250, 250, 'elpolloloco.com', ARRAY['el pollo loco beans', 'epl black beans'], '370 cal per large. {"sodium_mg":392,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- El Pollo Loco Macaroni and Cheese large: 770 cal, 48f, 23p, 60c (~300g)
('epl_mac_and_cheese', 'El Pollo Loco Macaroni and Cheese', 256.7, 7.7, 20.0, 16.0, 0.7, 3.0, 300, 300, 'elpolloloco.com', ARRAY['el pollo loco mac cheese'], '770 cal per large. {"sodium_mg":533,"cholesterol_mg":50,"sat_fat_g":9.3,"trans_fat_g":0}'),

-- El Pollo Loco Cinnamon Churros: 320 cal, 22f, 3p, 30c (~80g)
('epl_churros', 'El Pollo Loco Cinnamon Churros', 400.0, 3.8, 37.5, 27.5, 1.3, 8.8, 80, 80, 'elpolloloco.com', ARRAY['el pollo loco churros'], '320 cal per serving. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- =====================================================
-- 3. DEL TACO
-- Source: deltaco.com, healthyfastfood.org, myfooddiary.com
-- =====================================================

-- Del Taco The Del Taco Soft: 300 cal, 18f, 17p, 17c (~130g)
('deltaco_the_del_taco_soft', 'Del Taco The Del Taco Soft', 230.8, 13.1, 13.1, 13.8, 1.5, 1.5, 130, 130, 'deltaco.com', ARRAY['del taco soft taco', 'the del taco'], '300 cal per soft taco. {"sodium_mg":485,"cholesterol_mg":34.6,"sat_fat_g":5.4,"trans_fat_g":0.4}'),

-- Del Taco The Del Taco Crunchy: 310 cal, 20f, 17p, 16c (~120g)
('deltaco_the_del_taco_crunchy', 'Del Taco The Del Taco Crunchy', 258.3, 14.2, 13.3, 16.7, 1.7, 1.7, 120, 120, 'deltaco.com', ARRAY['del taco crunchy taco', 'del taco hard shell'], '310 cal per crunchy taco. {"sodium_mg":425,"cholesterol_mg":37.5,"sat_fat_g":6.7,"trans_fat_g":0.4}'),

-- Del Taco Beer Battered Fish Taco: 230 cal, 12f, 7p, 26c (~120g)
('deltaco_fish_taco', 'Del Taco Beer Battered Fish Taco', 191.7, 5.8, 21.7, 10.0, 2.5, 1.7, 120, 120, 'deltaco.com', ARRAY['del taco fish taco'], '230 cal per taco. {"sodium_mg":391.7,"cholesterol_mg":12.5,"sat_fat_g":1.7,"trans_fat_g":0}'),

-- Del Taco Chicken Al Carbon Taco: 150 cal, 5f, 10p, 19c (~100g)
('deltaco_chicken_al_carbon', 'Del Taco Chicken Al Carbon Taco', 150.0, 10.0, 19.0, 5.0, 1.0, 0.0, 100, 100, 'deltaco.com', ARRAY['del taco al carbon', 'del taco chicken taco'], '150 cal per taco. {"sodium_mg":400,"cholesterol_mg":25,"sat_fat_g":1.0,"trans_fat_g":0}'),

-- Del Taco Grilled Chicken Taco: 210 cal, 12f, 12p, 16c (~100g)
('deltaco_grilled_chicken_taco', 'Del Taco Grilled Chicken Taco', 210.0, 12.0, 16.0, 12.0, 1.0, 1.0, 100, 100, 'deltaco.com', ARRAY['del taco grilled chicken'], '210 cal per taco. {"sodium_mg":480,"cholesterol_mg":35,"sat_fat_g":3.5,"trans_fat_g":0}'),

-- Del Taco Carne Asada Street Taco: 180 cal (~113g myfooddiary)
('deltaco_carne_asada_street_taco', 'Del Taco Carne Asada Street Taco', 159.3, 8.8, 17.7, 4.4, 0.9, 0.9, 113, 113, 'deltaco.com', ARRAY['del taco street taco', 'del taco carne asada'], '180 cal per taco. {"sodium_mg":389,"cholesterol_mg":22.1,"sat_fat_g":1.8,"trans_fat_g":0}'),

-- Del Taco 8 Layer Veggie Burrito: 530 cal, 18f, 18p, 72c (~300g)
('deltaco_8_layer_veggie', 'Del Taco 8 Layer Veggie Burrito', 176.7, 6.0, 24.0, 6.0, 3.0, 0.7, 300, 300, 'deltaco.com', ARRAY['del taco veggie burrito', 'del taco 8 layer'], '530 cal per burrito. {"sodium_mg":467,"cholesterol_mg":10,"sat_fat_g":2.7,"trans_fat_g":0}'),

-- Del Taco Del Beef Burrito: 500 cal, 24f, 27p, 40c (~250g)
('deltaco_del_beef_burrito', 'Del Taco Del Beef Burrito', 200.0, 10.8, 16.0, 9.6, 1.2, 0.8, 250, 250, 'deltaco.com', ARRAY['del taco beef burrito'], '500 cal per burrito. {"sodium_mg":512,"cholesterol_mg":36,"sat_fat_g":4.8,"trans_fat_g":0.4}'),

-- Del Taco Chicken Crunch Burrito: 460 cal, 19f, 15p, 57c (~250g)
('deltaco_chicken_crunch_burrito', 'Del Taco Chicken Crunch Burrito', 184.0, 6.0, 22.8, 7.6, 0.8, 0.4, 250, 250, 'deltaco.com', ARRAY['del taco chicken crunch'], '460 cal per burrito. {"sodium_mg":472,"cholesterol_mg":16,"sat_fat_g":3.2,"trans_fat_g":0}'),

-- Del Taco Epic Crispy Chicken & Guac: 890 cal, 52f, 29p, 78c (~400g)
('deltaco_epic_crispy_chicken_guac', 'Del Taco Epic Crispy Chicken & Guac Burrito', 222.5, 7.3, 19.5, 13.0, 1.3, 1.0, 400, 400, 'deltaco.com', ARRAY['del taco epic burrito', 'del taco crispy chicken guac'], '890 cal per burrito. {"sodium_mg":525,"cholesterol_mg":25,"sat_fat_g":4.0,"trans_fat_g":0}'),

-- Del Taco Macho Combo Burrito: 950 cal (~538g myfooddiary)
('deltaco_macho_combo_burrito', 'Del Taco Macho Combo Burrito', 176.6, 9.3, 16.7, 9.3, 1.5, 0.7, 538, 538, 'deltaco.com', ARRAY['del taco macho burrito', 'del taco combo burrito'], '950 cal per burrito. {"sodium_mg":407,"cholesterol_mg":18.6,"sat_fat_g":3.7,"trans_fat_g":0.2}'),

-- Del Taco Crinkle Cut Fries regular: 210 cal, 10f, 3p, 27c (~100g)
('deltaco_fries', 'Del Taco Crinkle Cut Fries', 210.0, 3.0, 27.0, 10.0, 2.0, 0.0, 100, 100, 'deltaco.com', ARRAY['del taco fries', 'del taco crinkle fries'], '210 cal per regular. {"sodium_mg":430,"cholesterol_mg":0,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- Del Taco Loaded Queso Fries: 510 cal (~200g)
('deltaco_loaded_queso_fries', 'Del Taco Loaded Queso Fries', 255.0, 7.5, 27.5, 14.0, 2.0, 1.0, 200, 200, 'deltaco.com', ARRAY['del taco queso fries', 'del taco loaded fries'], '510 cal per serving. {"sodium_mg":625,"cholesterol_mg":15,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- Del Taco Chicken Cheddar Quesadilla: 460 cal (~180g)
('deltaco_chicken_cheddar_quesadilla', 'Del Taco Chicken Cheddar Quesadilla', 255.6, 12.2, 19.4, 16.1, 1.1, 0.6, 180, 180, 'deltaco.com', ARRAY['del taco quesadilla'], '460 cal per quesadilla. {"sodium_mg":611,"cholesterol_mg":44.4,"sat_fat_g":8.9,"trans_fat_g":0}'),

-- Del Taco Churros (2pc): 230 cal (~70g)
('deltaco_churros', 'Del Taco Churros', 328.6, 4.3, 42.9, 14.3, 0.0, 14.3, 70, 70, 'deltaco.com', ARRAY['del taco churros'], '230 cal per 2 pieces. {"sodium_mg":286,"cholesterol_mg":0,"sat_fat_g":4.3,"trans_fat_g":0}'),

-- Del Taco Chocolate Shake small: 580 cal (~350g)
('deltaco_chocolate_shake', 'Del Taco Chocolate Shake', 165.7, 3.7, 31.4, 7.4, 0.6, 24.0, 350, 350, 'deltaco.com', ARRAY['del taco shake', 'del taco chocolate shake'], '580 cal per small. {"sodium_mg":114,"cholesterol_mg":10,"sat_fat_g":4.3,"trans_fat_g":0}'),

-- Del Taco Beyond Meat Taco: 300 cal, 19f, 19p, 15c (~100g)
('deltaco_beyond_meat_taco', 'Del Taco Beyond Meat Taco', 300.0, 19.0, 15.0, 19.0, 2.0, 1.0, 100, 100, 'deltaco.com', ARRAY['del taco beyond taco', 'del taco plant based'], '300 cal per taco. {"sodium_mg":560,"cholesterol_mg":0,"sat_fat_g":6.0,"trans_fat_g":0}'),

-- =====================================================
-- 4. MOE'S SOUTHWEST GRILL
-- Source: moes.com, fatsecret.com, fastfoodnutrition.org
-- =====================================================

-- Moe's Homewrecker Burrito Chicken: 1160 cal, 42f, 55p, 157c (~500g)
('moes_homewrecker_chicken', 'Moe''s Homewrecker Burrito Chicken', 232.0, 11.0, 31.4, 8.4, 3.0, 2.0, 500, 500, 'moes.com', ARRAY['moes homewrecker', 'moes burrito chicken'], '1160 cal per burrito. {"sodium_mg":440,"cholesterol_mg":22,"sat_fat_g":3.6,"trans_fat_g":0}'),

-- Moe's Homewrecker Burrito Steak: 1116 cal, 39f, 51p, 158c (~500g)
('moes_homewrecker_steak', 'Moe''s Homewrecker Burrito Steak', 223.2, 10.2, 31.6, 7.8, 2.8, 2.0, 500, 500, 'moes.com', ARRAY['moes homewrecker steak', 'moes steak burrito'], '1116 cal per burrito. {"sodium_mg":420,"cholesterol_mg":20,"sat_fat_g":3.2,"trans_fat_g":0}'),

-- Moe's Homewrecker Bowl Steak: 806 cal, 31f, 43p, 107c (~450g)
('moes_homewrecker_bowl_steak', 'Moe''s Homewrecker Bowl Steak', 179.1, 9.6, 23.8, 6.9, 3.1, 1.8, 450, 450, 'moes.com', ARRAY['moes homewrecker bowl'], '806 cal per bowl. {"sodium_mg":418,"cholesterol_mg":20,"sat_fat_g":3.1,"trans_fat_g":0}'),

-- Moe's Burrito Bowl Chicken: 724 cal, 23f, 43p, 99c (~400g)
('moes_burrito_bowl_chicken', 'Moe''s Burrito Bowl Chicken', 181.0, 10.8, 24.8, 5.8, 2.5, 1.5, 400, 400, 'moes.com', ARRAY['moes bowl chicken', 'moes chicken bowl'], '724 cal per bowl. {"sodium_mg":435,"cholesterol_mg":22.5,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Moe's Burrito Bowl Steak: 680 cal, 20f, 39p, 100c (~400g)
('moes_burrito_bowl_steak', 'Moe''s Burrito Bowl Steak', 170.0, 9.8, 25.0, 5.0, 2.3, 1.3, 400, 400, 'moes.com', ARRAY['moes bowl steak', 'moes steak bowl'], '680 cal per bowl. {"sodium_mg":425,"cholesterol_mg":20,"sat_fat_g":2.3,"trans_fat_g":0}'),

-- Moe's Burrito Chicken: 1025 cal, 30f, 51p, 149c (~450g)
('moes_burrito_chicken', 'Moe''s Burrito Chicken', 227.8, 11.3, 33.1, 6.7, 2.4, 1.6, 450, 450, 'moes.com', ARRAY['moes chicken burrito'], '1025 cal per burrito. {"sodium_mg":444,"cholesterol_mg":22.2,"sat_fat_g":2.7,"trans_fat_g":0}'),

-- Moe's Quesadilla Chicken: 492 cal, 27f, 39p, 35c (~220g)
('moes_quesadilla_chicken', 'Moe''s Quesadilla Chicken', 223.6, 17.7, 15.9, 12.3, 0.9, 0.9, 220, 220, 'moes.com', ARRAY['moes quesadilla', 'moes chicken quesadilla'], '492 cal per quesadilla. {"sodium_mg":518,"cholesterol_mg":45.5,"sat_fat_g":6.8,"trans_fat_g":0}'),

-- Moe's Quesadilla Steak: 448 cal, 24f, 35p, 36c (~220g)
('moes_quesadilla_steak', 'Moe''s Quesadilla Steak', 203.6, 15.9, 16.4, 10.9, 0.9, 0.9, 220, 220, 'moes.com', ARRAY['moes steak quesadilla'], '448 cal per quesadilla. {"sodium_mg":500,"cholesterol_mg":40.9,"sat_fat_g":6.4,"trans_fat_g":0}'),

-- Moe's Nachos Chicken: 439 cal, 22f, 35p, 37c (~300g)
('moes_nachos_chicken', 'Moe''s Nachos Chicken', 146.3, 11.7, 12.3, 7.3, 2.0, 1.0, 300, 300, 'moes.com', ARRAY['moes nachos', 'moes chicken nachos'], '439 cal per serving. {"sodium_mg":387,"cholesterol_mg":18.3,"sat_fat_g":3.3,"trans_fat_g":0}'),

-- Moe's Salad Steak: 422 cal, 22f, 34p, 37c (~350g)
('moes_salad_steak', 'Moe''s Salad Steak', 120.6, 9.7, 10.6, 6.3, 2.3, 1.4, 350, 350, 'moes.com', ARRAY['moes salad', 'moes steak salad'], '422 cal per salad. {"sodium_mg":363,"cholesterol_mg":17.1,"sat_fat_g":2.9,"trans_fat_g":0}'),

-- Moe's Moe Meat Moe Cheese Bowl: 890 cal, 44f, 65p, 78c (~450g)
('moes_moe_meat_bowl', 'Moe''s Moe Meat Moe Cheese Bowl', 197.8, 14.4, 17.3, 9.8, 2.7, 1.3, 450, 450, 'moes.com', ARRAY['moes moe meat bowl', 'moes double meat'], '890 cal per bowl. {"sodium_mg":444,"cholesterol_mg":35.6,"sat_fat_g":5.3,"trans_fat_g":0}'),

-- Moe's Tortilla Chips: 693 cal (~150g)
('moes_chips', 'Moe''s Tortilla Chips', 462.0, 6.0, 50.0, 25.3, 3.3, 0.0, 150, 150, 'moes.com', ARRAY['moes chips', 'moes tortilla chips'], '693 cal per serving. {"sodium_mg":520,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0}'),

-- Moe's Queso: 130 cal (~60g)
('moes_queso', 'Moe''s Queso', 216.7, 5.0, 13.3, 15.0, 0.0, 3.3, 60, 60, 'moes.com', ARRAY['moes queso', 'moes cheese dip'], '130 cal per serving. {"sodium_mg":667,"cholesterol_mg":25,"sat_fat_g":8.3,"trans_fat_g":0}'),

-- Moe's Guacamole: 110 cal (~60g)
('moes_guacamole', 'Moe''s Guacamole', 183.3, 1.7, 8.3, 16.7, 5.0, 0.0, 60, 60, 'moes.com', ARRAY['moes guac', 'moes guacamole'], '110 cal per serving. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Moe's Chocolate Chip Cookie: 160 cal, 8f, 2p, 23c (~40g)
('moes_chocolate_chip_cookie', 'Moe''s Chocolate Chip Cookie', 400.0, 5.0, 57.5, 20.0, 0.0, 30.0, 40, 40, 'moes.com', ARRAY['moes cookie'], '160 cal per cookie. {"sodium_mg":325,"cholesterol_mg":25,"sat_fat_g":10.0,"trans_fat_g":0}'),

-- =====================================================
-- 5. QDOBA
-- Source: qdoba.com, fastfoodnutrition.org
-- =====================================================

-- Qdoba Chicken Burrito Bowl: 660 cal, 34f, 40p, 47c (~400g)
('qdoba_chicken_bowl', 'Qdoba Chicken Burrito Bowl', 165.0, 10.0, 11.8, 8.5, 2.8, 1.3, 400, 400, 'qdoba.com', ARRAY['qdoba bowl', 'qdoba chicken bowl'], '660 cal per bowl. {"sodium_mg":425,"cholesterol_mg":27.5,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- Qdoba Steak Burrito Bowl: 710 cal (~400g)
('qdoba_steak_bowl', 'Qdoba Steak Burrito Bowl', 177.5, 10.5, 12.5, 9.3, 2.8, 1.3, 400, 400, 'qdoba.com', ARRAY['qdoba steak bowl'], '710 cal per bowl. {"sodium_mg":438,"cholesterol_mg":30,"sat_fat_g":4.3,"trans_fat_g":0}'),

-- Qdoba Chicken Burrito: 850 cal (~450g)
('qdoba_chicken_burrito', 'Qdoba Chicken Burrito', 188.9, 10.0, 21.1, 7.8, 2.2, 1.1, 450, 450, 'qdoba.com', ARRAY['qdoba burrito', 'qdoba chicken burrito'], '850 cal per burrito. {"sodium_mg":467,"cholesterol_mg":26.7,"sat_fat_g":3.6,"trans_fat_g":0}'),

-- Qdoba Steak Burrito: 900 cal (~450g)
('qdoba_steak_burrito', 'Qdoba Steak Burrito', 200.0, 10.4, 21.8, 8.4, 2.2, 1.1, 450, 450, 'qdoba.com', ARRAY['qdoba steak burrito'], '900 cal per burrito. {"sodium_mg":478,"cholesterol_mg":28.9,"sat_fat_g":4.0,"trans_fat_g":0}'),

-- Qdoba Chicken Taco (flour): 260 cal (~100g)
('qdoba_chicken_taco', 'Qdoba Chicken Taco', 260.0, 14.0, 17.0, 12.0, 1.0, 1.0, 100, 100, 'qdoba.com', ARRAY['qdoba taco', 'qdoba chicken taco'], '260 cal per taco. {"sodium_mg":520,"cholesterol_mg":35,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- Qdoba Steak Taco: 280 cal (~100g)
('qdoba_steak_taco', 'Qdoba Steak Taco', 280.0, 14.0, 18.0, 13.0, 1.0, 1.0, 100, 100, 'qdoba.com', ARRAY['qdoba steak taco'], '280 cal per taco. {"sodium_mg":540,"cholesterol_mg":40,"sat_fat_g":5.5,"trans_fat_g":0}'),

-- Qdoba Chicken Quesadilla: 620 cal (~220g)
('qdoba_chicken_quesadilla', 'Qdoba Chicken Quesadilla', 281.8, 18.2, 16.4, 15.5, 0.9, 0.9, 220, 220, 'qdoba.com', ARRAY['qdoba quesadilla'], '620 cal per quesadilla. {"sodium_mg":545,"cholesterol_mg":50,"sat_fat_g":8.2,"trans_fat_g":0}'),

-- Qdoba Chicken Nachos: 730 cal (~300g)
('qdoba_chicken_nachos', 'Qdoba Chicken Nachos', 243.3, 11.0, 18.3, 14.7, 3.0, 1.3, 300, 300, 'qdoba.com', ARRAY['qdoba nachos'], '730 cal per serving. {"sodium_mg":500,"cholesterol_mg":25,"sat_fat_g":5.7,"trans_fat_g":0}'),

-- Qdoba Chips & Guacamole: 430 cal (~150g)
('qdoba_chips_guac', 'Qdoba Chips & Guacamole', 286.7, 3.3, 30.0, 18.7, 4.0, 0.7, 150, 150, 'qdoba.com', ARRAY['qdoba chips guacamole', 'qdoba chips and guac'], '430 cal per serving. {"sodium_mg":367,"cholesterol_mg":0,"sat_fat_g":3.3,"trans_fat_g":0}'),

-- Qdoba Three Cheese Queso (side): 120 cal (~60g)
('qdoba_queso', 'Qdoba Three Cheese Queso', 200.0, 5.0, 10.0, 15.0, 0.0, 3.3, 60, 60, 'qdoba.com', ARRAY['qdoba queso dip', 'qdoba cheese dip'], '120 cal per side. {"sodium_mg":667,"cholesterol_mg":33.3,"sat_fat_g":8.3,"trans_fat_g":0}'),

-- Qdoba Guacamole: 100 cal (~60g)
('qdoba_guacamole', 'Qdoba Guacamole', 166.7, 1.7, 8.3, 15.0, 5.0, 0.0, 60, 60, 'qdoba.com', ARRAY['qdoba guac'], '100 cal per side. {"sodium_mg":250,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Qdoba Mexican Rice: 180 cal (~120g)
('qdoba_mexican_rice', 'Qdoba Mexican Rice', 150.0, 2.5, 27.5, 2.5, 0.8, 0.0, 120, 120, 'qdoba.com', ARRAY['qdoba rice'], '180 cal per serving. {"sodium_mg":358,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- Qdoba Black Beans: 110 cal (~120g)
('qdoba_black_beans', 'Qdoba Black Beans', 91.7, 7.5, 15.0, 0.8, 5.0, 0.0, 120, 120, 'qdoba.com', ARRAY['qdoba beans', 'qdoba black beans'], '110 cal per serving. {"sodium_mg":292,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),

-- Qdoba Grilled Chicken: 130 cal (~110g)
('qdoba_grilled_chicken', 'Qdoba Grilled Chicken', 118.2, 21.8, 0.9, 2.7, 0.0, 0.0, 110, 110, 'qdoba.com', ARRAY['qdoba chicken'], '130 cal per serving. {"sodium_mg":418,"cholesterol_mg":59.1,"sat_fat_g":0.9,"trans_fat_g":0}'),

-- Qdoba Grilled Steak: 170 cal (~110g)
('qdoba_grilled_steak', 'Qdoba Grilled Steak', 154.5, 20.0, 1.8, 5.5, 0.0, 0.0, 110, 110, 'qdoba.com', ARRAY['qdoba steak'], '170 cal per serving. {"sodium_mg":336,"cholesterol_mg":50,"sat_fat_g":2.3,"trans_fat_g":0}'),

-- Qdoba Flour Tortilla: 300 cal (~100g)
('qdoba_flour_tortilla', 'Qdoba Flour Tortilla', 300.0, 7.0, 46.0, 9.0, 2.0, 2.0, 100, 100, 'qdoba.com', ARRAY['qdoba tortilla'], '300 cal per tortilla. {"sodium_mg":680,"cholesterol_mg":0,"sat_fat_g":3.5,"trans_fat_g":0}'),

-- =====================================================
-- 6. PEI WEI
-- Source: peiwei.com, healthyfastfood.org
-- =====================================================

-- Pei Wei Orange Chicken: 980 cal, 50f, 34p, 94c (~450g)
('peiwei_orange_chicken', 'Pei Wei Orange Chicken', 217.8, 7.6, 20.9, 11.1, 2.2, 12.4, 450, 450, 'peiwei.com', ARRAY['pei wei orange chicken'], '980 cal per regular. {"sodium_mg":444,"cholesterol_mg":22.2,"sat_fat_g":2.4,"trans_fat_g":0}'),

-- Pei Wei Kung Pao Chicken: 975 cal, 60f, 46p, 44c (~400g)
('peiwei_kung_pao_chicken', 'Pei Wei Kung Pao Chicken', 243.8, 11.5, 11.0, 15.0, 1.8, 6.5, 400, 400, 'peiwei.com', ARRAY['pei wei kung pao'], '975 cal per regular. {"sodium_mg":525,"cholesterol_mg":37.5,"sat_fat_g":3.0,"trans_fat_g":0}'),

-- Pei Wei Beef & Broccoli: 790 cal, 49f, 34p, 53c (~400g)
('peiwei_beef_broccoli', 'Pei Wei Beef & Broccoli', 197.5, 8.5, 13.3, 12.3, 1.5, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei beef broccoli'], '790 cal per regular. {"sodium_mg":500,"cholesterol_mg":30,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- Pei Wei Chicken & Broccoli: 666 cal, 27f, 40p, 48c (~400g)
('peiwei_chicken_broccoli', 'Pei Wei Chicken & Broccoli', 166.5, 10.0, 12.0, 6.8, 1.3, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei chicken broccoli'], '666 cal per regular. {"sodium_mg":475,"cholesterol_mg":25,"sat_fat_g":1.5,"trans_fat_g":0}'),

-- Pei Wei Mongolian Chicken: 636 cal, 27f, 39p, 39c (~400g)
('peiwei_mongolian_chicken', 'Pei Wei Mongolian Chicken', 159.0, 9.8, 9.8, 6.8, 0.5, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei mongolian chicken'], '636 cal per regular. {"sodium_mg":625,"cholesterol_mg":25,"sat_fat_g":1.5,"trans_fat_g":0}'),

-- Pei Wei Mongolian Steak: 760 cal, 49f, 33p, 44c (~400g)
('peiwei_mongolian_steak', 'Pei Wei Mongolian Steak', 190.0, 8.3, 11.0, 12.3, 0.8, 7.3, 400, 400, 'peiwei.com', ARRAY['pei wei mongolian steak'], '760 cal per regular. {"sodium_mg":638,"cholesterol_mg":30,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- Pei Wei Sesame Chicken: 895 cal, 47f, 41p, 56c (~400g)
('peiwei_sesame_chicken', 'Pei Wei Sesame Chicken', 223.8, 10.3, 14.0, 11.8, 1.3, 10.0, 400, 400, 'peiwei.com', ARRAY['pei wei sesame chicken'], '895 cal per regular. {"sodium_mg":500,"cholesterol_mg":25,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Pei Wei General Tso's Chicken: 805 cal, 42f, 40p, 48c (~400g)
('peiwei_general_tsos', 'Pei Wei Spicy General Tso''s Chicken', 201.3, 10.0, 12.0, 10.5, 1.3, 7.8, 400, 400, 'peiwei.com', ARRAY['pei wei general tso', 'pei wei general tsos'], '805 cal per regular. {"sodium_mg":550,"cholesterol_mg":25,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Pei Wei Teriyaki Chicken: 935 cal, 41f, 42p, 84c (~450g)
('peiwei_teriyaki_chicken', 'Pei Wei Teriyaki Chicken', 207.8, 9.3, 18.7, 9.1, 1.3, 15.1, 450, 450, 'peiwei.com', ARRAY['pei wei teriyaki'], '935 cal per regular. {"sodium_mg":489,"cholesterol_mg":22.2,"sat_fat_g":1.8,"trans_fat_g":0}'),

-- Pei Wei Sweet & Sour Chicken: 980 cal, 50f, 33p, 97c (~450g)
('peiwei_sweet_sour_chicken', 'Pei Wei Sweet & Sour Chicken', 217.8, 7.3, 21.6, 11.1, 2.4, 12.9, 450, 450, 'peiwei.com', ARRAY['pei wei sweet and sour'], '980 cal per regular. {"sodium_mg":422,"cholesterol_mg":20,"sat_fat_g":2.2,"trans_fat_g":0}'),

-- Pei Wei Firecracker Chicken: 1090 cal, 60f, 46p, 96c (~450g)
('peiwei_firecracker_chicken', 'Pei Wei Firecracker Chicken', 242.2, 10.2, 21.3, 13.3, 0.2, 11.6, 450, 450, 'peiwei.com', ARRAY['pei wei firecracker'], '1090 cal per regular. {"sodium_mg":533,"cholesterol_mg":24.4,"sat_fat_g":2.7,"trans_fat_g":0}'),

-- Pei Wei Thai Coconut Curry Chicken: 640 cal, 8f, 54p, 42c (~400g)
('peiwei_thai_coconut_curry', 'Pei Wei Thai Coconut Curry Chicken', 160.0, 13.5, 10.5, 2.0, 0.8, 5.3, 400, 400, 'peiwei.com', ARRAY['pei wei thai curry', 'pei wei coconut curry'], '640 cal per regular. {"sodium_mg":400,"cholesterol_mg":25,"sat_fat_g":1.0,"trans_fat_g":0}'),

-- Pei Wei Chicken Fried Rice: 1106 cal, 27f, 54p, 137c (~500g)
('peiwei_chicken_fried_rice', 'Pei Wei Chicken Fried Rice', 221.2, 10.8, 27.4, 5.4, 1.0, 5.0, 500, 500, 'peiwei.com', ARRAY['pei wei fried rice'], '1106 cal per bowl. {"sodium_mg":480,"cholesterol_mg":30,"sat_fat_g":1.4,"trans_fat_g":0}'),

-- Pei Wei Chicken Lo Mein: 1170 cal, 42f, 70p, 123c (~500g)
('peiwei_chicken_lo_mein', 'Pei Wei Chicken Lo Mein', 234.0, 14.0, 24.6, 8.4, 1.6, 4.6, 500, 500, 'peiwei.com', ARRAY['pei wei lo mein'], '1170 cal per bowl. {"sodium_mg":540,"cholesterol_mg":34,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- Pei Wei Chicken Pad Thai: 1490 cal, 42f, 82p, 167c (~550g)
('peiwei_chicken_pad_thai', 'Pei Wei Chicken Pad Thai', 270.9, 14.9, 30.4, 7.6, 2.5, 9.1, 550, 550, 'peiwei.com', ARRAY['pei wei pad thai'], '1490 cal per bowl. {"sodium_mg":509,"cholesterol_mg":29.1,"sat_fat_g":1.8,"trans_fat_g":0}'),

-- Pei Wei Dan Dan Noodles: 990 cal, 40f, 46p, 110c (~450g)
('peiwei_dan_dan_noodles', 'Pei Wei Dan Dan Noodles', 220.0, 10.2, 24.4, 8.9, 1.3, 5.6, 450, 450, 'peiwei.com', ARRAY['pei wei dan dan'], '990 cal per bowl. {"sodium_mg":489,"cholesterol_mg":26.7,"sat_fat_g":2.2,"trans_fat_g":0}'),

-- Pei Wei Asian Chopped Chicken Salad: 660 cal, 35f, 46p, 44c (~350g)
('peiwei_asian_chopped_salad', 'Pei Wei Asian Chopped Chicken Salad', 188.6, 13.1, 12.6, 10.0, 1.7, 3.7, 350, 350, 'peiwei.com', ARRAY['pei wei salad', 'pei wei chicken salad'], '660 cal per salad. {"sodium_mg":457,"cholesterol_mg":22.9,"sat_fat_g":2.6,"trans_fat_g":0}'),

-- Pei Wei Chicken Egg Roll: 200 cal, 14f, 10p, 24c (~80g)
('peiwei_chicken_egg_roll', 'Pei Wei Chicken Egg Roll', 250.0, 12.5, 30.0, 17.5, 3.8, 5.0, 80, 80, 'peiwei.com', ARRAY['pei wei egg roll'], '200 cal per roll. {"sodium_mg":500,"cholesterol_mg":25,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- Pei Wei Vegetable Spring Rolls: 120 cal, 6f, 2p, 15c (~60g)
('peiwei_spring_rolls', 'Pei Wei Vegetable Spring Rolls', 200.0, 3.3, 25.0, 10.0, 3.3, 3.3, 60, 60, 'peiwei.com', ARRAY['pei wei spring rolls'], '120 cal per roll. {"sodium_mg":333,"cholesterol_mg":0,"sat_fat_g":1.7,"trans_fat_g":0}'),

-- Pei Wei Crab Wonton (1pc): 85 cal, 5f, 3p, 7c (~25g)
('peiwei_crab_wonton', 'Pei Wei Crab Wonton', 340.0, 12.0, 28.0, 20.0, 4.0, 0.0, 25, 25, 'peiwei.com', ARRAY['pei wei wonton', 'pei wei crab rangoon'], '85 cal per wonton. {"sodium_mg":600,"cholesterol_mg":40,"sat_fat_g":8.0,"trans_fat_g":0}'),

-- Pei Wei Edamame: 160 cal (~120g)
('peiwei_edamame', 'Pei Wei Edamame', 133.3, 10.0, 8.3, 5.0, 3.3, 1.7, 120, 120, 'peiwei.com', ARRAY['pei wei edamame'], '160 cal per serving. {"sodium_mg":25,"cholesterol_mg":0,"sat_fat_g":0.8,"trans_fat_g":0}'),

-- =====================================================
-- 7. P.F. CHANG'S
-- Source: pfchangs.com, fastfoodnutrition.org, eatthismuch.com
-- =====================================================

-- PF Chang's Chicken Lettuce Wraps: 730 cal, 27f, 38p, 81c (~365g)
('pfchangs_chicken_lettuce_wraps', 'P.F. Chang''s Chicken Lettuce Wraps', 200.0, 10.4, 22.2, 7.4, 2.2, 11.5, 365, 365, 'pfchangs.com', ARRAY['pf changs lettuce wraps', 'pfchangs wraps'], '730 cal per full order. {"sodium_mg":561.6,"cholesterol_mg":8.2,"sat_fat_g":1.6,"trans_fat_g":0}'),

-- PF Chang's Orange Chicken: 1160 cal (~400g)
('pfchangs_orange_chicken', 'P.F. Chang''s Orange Chicken', 290.0, 10.0, 27.5, 14.5, 1.3, 18.8, 400, 400, 'pfchangs.com', ARRAY['pf changs orange chicken'], '1160 cal per entree. {"sodium_mg":475,"cholesterol_mg":25,"sat_fat_g":3.0,"trans_fat_g":0}'),

-- PF Chang's Kung Pao Chicken: 980 cal (~400g)
('pfchangs_kung_pao_chicken', 'P.F. Chang''s Kung Pao Chicken', 245.0, 12.5, 15.0, 14.5, 2.5, 7.5, 400, 400, 'pfchangs.com', ARRAY['pf changs kung pao'], '980 cal per entree. {"sodium_mg":525,"cholesterol_mg":30,"sat_fat_g":3.5,"trans_fat_g":0}'),

-- PF Chang's Beef with Broccoli: 880 cal (~400g)
('pfchangs_beef_broccoli', 'P.F. Chang''s Beef with Broccoli', 220.0, 10.5, 17.5, 11.5, 2.0, 7.5, 400, 400, 'pfchangs.com', ARRAY['pf changs beef broccoli'], '880 cal per entree. {"sodium_mg":525,"cholesterol_mg":35,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- PF Chang's Mongolian Beef: 920 cal (~400g)
('pfchangs_mongolian_beef', 'P.F. Chang''s Mongolian Beef', 230.0, 10.0, 19.0, 12.5, 1.3, 10.0, 400, 400, 'pfchangs.com', ARRAY['pf changs mongolian beef'], '920 cal per entree. {"sodium_mg":575,"cholesterol_mg":37.5,"sat_fat_g":4.0,"trans_fat_g":0}'),

-- PF Chang's Crispy Honey Chicken: 1140 cal (~400g)
('pfchangs_crispy_honey_chicken', 'P.F. Chang''s Crispy Honey Chicken', 285.0, 10.0, 28.8, 14.0, 1.0, 20.0, 400, 400, 'pfchangs.com', ARRAY['pf changs honey chicken'], '1140 cal per entree. {"sodium_mg":500,"cholesterol_mg":25,"sat_fat_g":3.0,"trans_fat_g":0}'),

-- PF Chang's Kung Pao Shrimp: 1020 cal (~400g)
('pfchangs_kung_pao_shrimp', 'P.F. Chang''s Kung Pao Shrimp', 255.0, 10.0, 17.5, 15.0, 2.5, 7.5, 400, 400, 'pfchangs.com', ARRAY['pf changs kung pao shrimp'], '1020 cal per entree. {"sodium_mg":550,"cholesterol_mg":50,"sat_fat_g":3.5,"trans_fat_g":0}'),

-- PF Chang's Pad Thai Chicken: 1340 cal (~500g)
('pfchangs_pad_thai_chicken', 'P.F. Chang''s Pad Thai Chicken', 268.0, 12.0, 29.0, 12.6, 2.0, 14.0, 500, 500, 'pfchangs.com', ARRAY['pf changs pad thai'], '1340 cal per entree. {"sodium_mg":560,"cholesterol_mg":28,"sat_fat_g":2.8,"trans_fat_g":0}'),

-- PF Chang's Lo Mein Chicken: 830 cal (~400g)
('pfchangs_lo_mein_chicken', 'P.F. Chang''s Lo Mein Chicken', 207.5, 10.0, 18.5, 10.0, 1.5, 5.0, 400, 400, 'pfchangs.com', ARRAY['pf changs lo mein'], '830 cal per entree. {"sodium_mg":500,"cholesterol_mg":25,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- PF Chang's Fried Rice Chicken: 1100 cal (~450g)
('pfchangs_fried_rice_chicken', 'P.F. Chang''s Fried Rice with Chicken', 244.4, 11.1, 35.3, 5.8, 1.1, 3.3, 450, 450, 'pfchangs.com', ARRAY['pf changs fried rice'], '1100 cal per entree. {"sodium_mg":533,"cholesterol_mg":33.3,"sat_fat_g":1.6,"trans_fat_g":0}'),

-- PF Chang's Ma Po Tofu: 920 cal (~350g)
('pfchangs_ma_po_tofu', 'P.F. Chang''s Ma Po Tofu', 262.9, 10.3, 16.3, 16.9, 2.3, 4.3, 350, 350, 'pfchangs.com', ARRAY['pf changs mapo tofu'], '920 cal per entree. {"sodium_mg":514,"cholesterol_mg":14.3,"sat_fat_g":4.3,"trans_fat_g":0}'),

-- PF Chang's Shrimp Dumplings Steamed (6pc): 260 cal (~150g)
('pfchangs_shrimp_dumplings', 'P.F. Chang''s Shrimp Dumplings Steamed', 173.3, 8.0, 14.0, 6.0, 0.7, 2.0, 150, 150, 'pfchangs.com', ARRAY['pf changs shrimp dumplings'], '260 cal per 6pc. {"sodium_mg":473,"cholesterol_mg":33.3,"sat_fat_g":1.3,"trans_fat_g":0}'),

-- PF Chang's Chicken Dumplings Pan-Fried (6pc): 370 cal (~150g)
('pfchangs_chicken_dumplings', 'P.F. Chang''s Chicken Dumplings Pan-Fried', 246.7, 10.0, 18.7, 12.7, 1.3, 2.7, 150, 150, 'pfchangs.com', ARRAY['pf changs chicken dumplings', 'pf changs potstickers'], '370 cal per 6pc. {"sodium_mg":500,"cholesterol_mg":26.7,"sat_fat_g":3.3,"trans_fat_g":0}'),

-- PF Chang's Crab Wontons (6pc): 400 cal (~150g)
('pfchangs_crab_wontons', 'P.F. Chang''s Crab Wontons', 266.7, 8.0, 18.0, 16.0, 0.7, 2.0, 150, 150, 'pfchangs.com', ARRAY['pf changs crab wontons', 'pf changs rangoon'], '400 cal per 6pc. {"sodium_mg":533,"cholesterol_mg":40,"sat_fat_g":6.0,"trans_fat_g":0}'),

-- PF Chang's Dynamite Shrimp: 640 cal (~250g)
('pfchangs_dynamite_shrimp', 'P.F. Chang''s Dynamite Shrimp', 256.0, 10.0, 16.0, 15.6, 0.8, 8.0, 250, 250, 'pfchangs.com', ARRAY['pf changs dynamite shrimp'], '640 cal per appetizer. {"sodium_mg":640,"cholesterol_mg":48,"sat_fat_g":4.0,"trans_fat_g":0}'),

-- PF Chang's White Rice: 430 cal (~250g)
('pfchangs_white_rice', 'P.F. Chang''s White Rice', 172.0, 1.2, 36.0, 1.2, 0.4, 0.0, 250, 250, 'pfchangs.com', ARRAY['pf changs rice', 'pf changs steamed rice'], '430 cal per side. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),

-- PF Chang's Brown Rice: 380 cal (~250g)
('pfchangs_brown_rice', 'P.F. Chang''s Brown Rice', 152.0, 1.2, 32.0, 2.4, 1.6, 0.0, 250, 250, 'pfchangs.com', ARRAY['pf changs brown rice'], '380 cal per side. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- PF Chang's Egg Drop Soup: 60 cal (~250g)
('pfchangs_egg_drop_soup', 'P.F. Chang''s Egg Drop Soup', 24.0, 1.6, 2.8, 0.8, 0.0, 0.8, 250, 250, 'pfchangs.com', ARRAY['pf changs egg drop soup'], '60 cal per bowl. {"sodium_mg":320,"cholesterol_mg":20,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- PF Chang's Wonton Soup: 290 cal (~350g)
('pfchangs_wonton_soup', 'P.F. Chang''s Wonton Soup', 82.9, 4.6, 7.4, 4.0, 0.6, 1.4, 350, 350, 'pfchangs.com', ARRAY['pf changs wonton soup'], '290 cal per bowl. {"sodium_mg":371,"cholesterol_mg":14.3,"sat_fat_g":1.1,"trans_fat_g":0}'),

-- PF Chang's Chocolate Lava Cake: 620 cal (~180g)
('pfchangs_chocolate_lava_cake', 'P.F. Chang''s Chocolate Lava Cake', 344.4, 5.6, 41.7, 19.4, 1.7, 27.8, 180, 180, 'pfchangs.com', ARRAY['pf changs lava cake', 'pf changs chocolate cake'], '620 cal per dessert. {"sodium_mg":167,"cholesterol_mg":55.6,"sat_fat_g":11.1,"trans_fat_g":0}'),

-- =====================================================
-- 8. SWEETGREEN
-- Source: sweetgreen.com, healthyfastfood.org, myfooddiary.com
-- =====================================================

-- Sweetgreen Harvest Bowl: 695 cal, 35f, 37p, 60c (~362g)
('sweetgreen_harvest_bowl', 'Sweetgreen Harvest Bowl', 191.9, 10.2, 16.6, 9.7, 2.5, 2.8, 362, 362, 'sweetgreen.com', ARRAY['sweetgreen harvest', 'sweetgreen harvest bowl'], '695 cal per bowl. {"sodium_mg":276,"cholesterol_mg":16.6,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Sweetgreen Kale Caesar Salad: 405 cal, 24f, 40p, 13c (~319g)
('sweetgreen_kale_caesar', 'Sweetgreen Kale Caesar Salad', 126.9, 12.5, 4.1, 7.5, 1.6, 1.3, 319, 319, 'sweetgreen.com', ARRAY['sweetgreen caesar', 'sweetgreen kale caesar'], '405 cal per salad. {"sodium_mg":313,"cholesterol_mg":25.1,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Sweetgreen Chicken Pesto Parm Bowl: 530 cal, 29f, 35p, 38c (~340g)
('sweetgreen_chicken_pesto_parm', 'Sweetgreen Chicken Pesto Parm Bowl', 155.9, 10.3, 11.2, 8.5, 2.4, 1.2, 340, 340, 'sweetgreen.com', ARRAY['sweetgreen pesto parm', 'sweetgreen chicken pesto'], '530 cal per bowl. {"sodium_mg":294,"cholesterol_mg":23.5,"sat_fat_g":2.6,"trans_fat_g":0}'),

-- Sweetgreen Crispy Rice Bowl: 635 cal, 29f, 28p, 69c (~380g)
('sweetgreen_crispy_rice_bowl', 'Sweetgreen Crispy Rice Bowl', 167.1, 7.4, 18.2, 7.6, 2.4, 2.4, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen crispy rice'], '635 cal per bowl. {"sodium_mg":284,"cholesterol_mg":18.4,"sat_fat_g":2.1,"trans_fat_g":0}'),

-- Sweetgreen Fish Taco Bowl: 685 cal, 44f, 31p, 47c (~380g)
('sweetgreen_fish_taco_bowl', 'Sweetgreen Fish Taco Bowl', 180.3, 8.2, 12.4, 11.6, 4.2, 1.1, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen fish taco'], '685 cal per bowl. {"sodium_mg":268,"cholesterol_mg":18.4,"sat_fat_g":2.9,"trans_fat_g":0}'),

-- Sweetgreen Shroomami Bowl: 685 cal, 41f, 27p, 57c (~380g)
('sweetgreen_shroomami', 'Sweetgreen Shroomami Bowl', 180.3, 7.1, 15.0, 10.8, 2.4, 2.1, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen shroomami', 'sweetgreen mushroom bowl'], '685 cal per bowl. {"sodium_mg":274,"cholesterol_mg":10.5,"sat_fat_g":2.4,"trans_fat_g":0}'),

-- Sweetgreen Garden Cobb Salad: 650 cal, 51f, 22p, 33c (~400g)
('sweetgreen_garden_cobb', 'Sweetgreen Garden Cobb Salad', 162.5, 5.5, 8.3, 12.8, 3.8, 2.3, 400, 400, 'sweetgreen.com', ARRAY['sweetgreen cobb', 'sweetgreen garden cobb'], '650 cal per salad. {"sodium_mg":263,"cholesterol_mg":30,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- Sweetgreen Buffalo Chicken Bowl: 445 cal, 27f, 31p, 22c (~320g)
('sweetgreen_buffalo_chicken', 'Sweetgreen Buffalo Chicken Bowl', 139.1, 9.7, 6.9, 8.4, 2.5, 1.9, 320, 320, 'sweetgreen.com', ARRAY['sweetgreen buffalo', 'sweetgreen buffalo chicken'], '445 cal per bowl. {"sodium_mg":344,"cholesterol_mg":25,"sat_fat_g":2.2,"trans_fat_g":0}'),

-- Sweetgreen Guacamole Greens Salad: 545 cal, 36f, 27p, 30c (~402g)
('sweetgreen_guacamole_greens', 'Sweetgreen Guacamole Greens Salad', 135.6, 6.7, 7.5, 9.0, 3.5, 0.7, 402, 402, 'sweetgreen.com', ARRAY['sweetgreen guac greens'], '545 cal per salad. {"sodium_mg":249,"cholesterol_mg":14.9,"sat_fat_g":2.0,"trans_fat_g":0}'),

-- Sweetgreen Super Green Goddess Salad: 460 cal, 27f, 20p, 46c (~380g)
('sweetgreen_super_green_goddess', 'Sweetgreen Super Green Goddess Salad', 121.1, 5.3, 12.1, 7.1, 3.7, 2.6, 380, 380, 'sweetgreen.com', ARRAY['sweetgreen green goddess'], '460 cal per salad. {"sodium_mg":247,"cholesterol_mg":6.6,"sat_fat_g":1.3,"trans_fat_g":0}'),

-- Sweetgreen BBQ Chicken Salad: 585 cal (~370g)
('sweetgreen_bbq_chicken', 'Sweetgreen BBQ Chicken Salad', 158.1, 8.6, 15.7, 9.2, 2.7, 4.1, 370, 370, 'sweetgreen.com', ARRAY['sweetgreen bbq', 'sweetgreen bbq chicken salad'], '585 cal per salad. {"sodium_mg":324,"cholesterol_mg":18.9,"sat_fat_g":2.4,"trans_fat_g":0}'),

-- Sweetgreen Warm Quinoa base: 120 cal (~90g)
('sweetgreen_warm_quinoa', 'Sweetgreen Warm Quinoa', 133.3, 3.3, 20.0, 2.2, 2.2, 0.0, 90, 90, 'sweetgreen.com', ARRAY['sweetgreen quinoa'], '120 cal per serving. {"sodium_mg":111,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),

-- Sweetgreen Warm Wild Rice base: 190 cal (~130g)
('sweetgreen_warm_wild_rice', 'Sweetgreen Warm Wild Rice', 146.2, 2.3, 30.0, 1.5, 1.5, 0.0, 130, 130, 'sweetgreen.com', ARRAY['sweetgreen wild rice'], '190 cal per serving. {"sodium_mg":115,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),

-- Sweetgreen Blackened Chicken: 130 cal, 6f, 17p, 1c (~100g)
('sweetgreen_blackened_chicken', 'Sweetgreen Blackened Chicken', 130.0, 17.0, 1.0, 6.0, 1.0, 0.0, 100, 100, 'sweetgreen.com', ARRAY['sweetgreen chicken'], '130 cal per serving. {"sodium_mg":350,"cholesterol_mg":55,"sat_fat_g":1.5,"trans_fat_g":0}'),

-- Sweetgreen Avocado: 160 cal, 15f, 3p, 9c (~80g)
('sweetgreen_avocado', 'Sweetgreen Avocado', 200.0, 3.8, 11.3, 18.8, 11.3, 0.0, 80, 80, 'sweetgreen.com', ARRAY['sweetgreen avocado'], '160 cal per serving. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- =====================================================
-- 9. CAVA
-- Source: cava.com, cavanutritionfacts.com, fastfoodnutrition.org
-- =====================================================

-- Cava Harissa Avocado Bowl: 830 cal, 49f, 41p, 62c (~450g)
('cava_harissa_avocado_bowl', 'Cava Harissa Avocado Bowl', 184.4, 9.1, 13.8, 10.9, 2.9, 2.7, 450, 450, 'cava.com', ARRAY['cava harissa avocado', 'cava avocado bowl'], '830 cal per bowl. {"sodium_mg":356,"cholesterol_mg":20,"sat_fat_g":2.9,"trans_fat_g":0}'),

-- Cava Greek Salad Bowl: 580 cal, 40f, 37p, 19c (~380g)
('cava_greek_salad_bowl', 'Cava Greek Salad Bowl', 152.6, 9.7, 5.0, 10.5, 1.8, 1.3, 380, 380, 'cava.com', ARRAY['cava greek salad', 'cava greek bowl'], '580 cal per bowl. {"sodium_mg":329,"cholesterol_mg":26.3,"sat_fat_g":3.2,"trans_fat_g":0}'),

-- Cava Chicken + Rice Bowl: 700 cal, 42f, 40p, 44c (~420g)
('cava_chicken_rice_bowl', 'Cava Chicken + Rice Bowl', 166.7, 9.5, 10.5, 10.0, 1.4, 1.9, 420, 420, 'cava.com', ARRAY['cava chicken bowl', 'cava rice bowl'], '700 cal per bowl. {"sodium_mg":333,"cholesterol_mg":21.4,"sat_fat_g":2.6,"trans_fat_g":0}'),

-- Cava Steak + Harissa Bowl: 610 cal, 35f, 37p, 39c (~400g)
('cava_steak_harissa_bowl', 'Cava Steak + Harissa Bowl', 152.5, 9.3, 9.8, 8.8, 1.8, 1.8, 400, 400, 'cava.com', ARRAY['cava steak bowl', 'cava harissa bowl'], '610 cal per bowl. {"sodium_mg":350,"cholesterol_mg":25,"sat_fat_g":2.8,"trans_fat_g":0}'),

-- Cava Falafel Crunch Bowl: 860 cal, 56f, 24p, 88c (~450g)
('cava_falafel_crunch_bowl', 'Cava Falafel Crunch Bowl', 191.1, 5.3, 19.6, 12.4, 3.1, 2.9, 450, 450, 'cava.com', ARRAY['cava falafel bowl'], '860 cal per bowl. {"sodium_mg":371,"cholesterol_mg":4.4,"sat_fat_g":2.4,"trans_fat_g":0}'),

-- Cava Spicy Lamb + Avocado Bowl: 800 cal, 52f, 43p, 49c (~450g)
('cava_spicy_lamb_avocado', 'Cava Spicy Lamb + Avocado Bowl', 177.8, 9.6, 10.9, 11.6, 2.7, 2.4, 450, 450, 'cava.com', ARRAY['cava lamb bowl', 'cava spicy lamb'], '800 cal per bowl. {"sodium_mg":362,"cholesterol_mg":26.7,"sat_fat_g":3.8,"trans_fat_g":0}'),

-- Cava Harissa Chicken Power Bowl: 620 cal, 40f, 25p, 43c (~400g)
('cava_harissa_chicken_power', 'Cava Harissa Chicken Power Bowl', 155.0, 6.3, 10.8, 10.0, 2.0, 2.8, 400, 400, 'cava.com', ARRAY['cava power bowl', 'cava harissa chicken'], '620 cal per bowl. {"sodium_mg":350,"cholesterol_mg":17.5,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- Cava Spicy Lamb + Sweet Potato Bowl: 650 cal, 34f, 27p, 63c (~430g)
('cava_spicy_lamb_sweet_potato', 'Cava Spicy Lamb + Sweet Potato Bowl', 151.2, 6.3, 14.7, 7.9, 2.3, 3.5, 430, 430, 'cava.com', ARRAY['cava lamb sweet potato bowl'], '650 cal per bowl. {"sodium_mg":349,"cholesterol_mg":20.9,"sat_fat_g":2.8,"trans_fat_g":0}'),

-- Cava Crispy Falafel Pita: 955 cal (~350g)
('cava_crispy_falafel_pita', 'Cava Crispy Falafel Pita', 272.9, 8.6, 18.3, 17.1, 2.9, 2.3, 350, 350, 'cava.com', ARRAY['cava falafel pita', 'cava pita wrap'], '955 cal per pita. {"sodium_mg":429,"cholesterol_mg":5.7,"sat_fat_g":2.9,"trans_fat_g":0}'),

-- Cava Grilled Chicken: 250 cal (~140g)
('cava_grilled_chicken', 'Cava Grilled Chicken', 178.6, 17.9, 1.4, 7.1, 0.0, 0.0, 140, 140, 'cava.com', ARRAY['cava chicken'], '250 cal per serving. {"sodium_mg":321,"cholesterol_mg":57.1,"sat_fat_g":1.8,"trans_fat_g":0}'),

-- Cava Grilled Steak: 230 cal (~140g)
('cava_grilled_steak', 'Cava Grilled Steak', 164.3, 16.4, 3.6, 7.1, 0.0, 0.0, 140, 140, 'cava.com', ARRAY['cava steak'], '230 cal per serving. {"sodium_mg":250,"cholesterol_mg":42.9,"sat_fat_g":2.9,"trans_fat_g":0}'),

-- Cava Falafel: 350 cal (~120g)
('cava_falafel', 'Cava Falafel', 291.7, 6.7, 30.0, 15.0, 5.0, 1.7, 120, 120, 'cava.com', ARRAY['cava falafel'], '350 cal per serving. {"sodium_mg":458,"cholesterol_mg":0,"sat_fat_g":1.7,"trans_fat_g":0}'),

-- Cava Spicy Lamb Meatballs: 310 cal (~140g)
('cava_spicy_lamb_meatballs', 'Cava Spicy Lamb Meatballs', 221.4, 13.6, 12.1, 11.4, 0.7, 1.4, 140, 140, 'cava.com', ARRAY['cava lamb meatballs', 'cava meatballs'], '310 cal per serving. {"sodium_mg":393,"cholesterol_mg":35.7,"sat_fat_g":5.0,"trans_fat_g":0}'),

-- Cava Saffron Basmati Rice: 290 cal, 6f, 6p, 54c (~200g)
('cava_saffron_rice', 'Cava Saffron Basmati Rice', 145.0, 3.0, 27.0, 3.0, 0.5, 0.0, 200, 200, 'cava.com', ARRAY['cava rice', 'cava basmati'], '290 cal per serving. {"sodium_mg":150,"cholesterol_mg":0,"sat_fat_g":0.5,"trans_fat_g":0}'),

-- Cava Greens & Grains base: 132 cal (~150g)
('cava_greens_grains', 'Cava Greens & Grains Base', 88.0, 4.0, 14.0, 2.0, 2.7, 0.7, 150, 150, 'cava.com', ARRAY['cava greens grains'], '132 cal per serving. {"sodium_mg":127,"cholesterol_mg":0,"sat_fat_g":0.3,"trans_fat_g":0}'),

-- Cava Pita: 230 cal (~80g)
('cava_pita', 'Cava Pita', 287.5, 3.8, 40.0, 5.0, 2.5, 1.3, 80, 80, 'cava.com', ARRAY['cava pita bread'], '230 cal per pita. {"sodium_mg":500,"cholesterol_mg":0,"sat_fat_g":0.6,"trans_fat_g":0}'),

-- Cava Hummus: 30 cal per serving (~30g)
('cava_hummus', 'Cava Hummus', 100.0, 3.3, 10.0, 5.0, 1.7, 0.0, 30, 30, 'cava.com', ARRAY['cava hummus'], '30 cal per serving. {"sodium_mg":267,"cholesterol_mg":0,"sat_fat_g":0.7,"trans_fat_g":0}'),

-- Cava Crazy Feta: 60 cal per serving (~30g)
('cava_crazy_feta', 'Cava Crazy Feta', 200.0, 5.0, 6.7, 16.7, 0.0, 3.3, 30, 30, 'cava.com', ARRAY['cava feta', 'cava crazy feta dip'], '60 cal per serving. {"sodium_mg":500,"cholesterol_mg":33.3,"sat_fat_g":10.0,"trans_fat_g":0}'),

-- Cava Tzatziki: 25 cal per serving (~30g)
('cava_tzatziki', 'Cava Tzatziki', 83.3, 3.3, 3.3, 6.7, 0.0, 3.3, 30, 30, 'cava.com', ARRAY['cava tzatziki'], '25 cal per serving. {"sodium_mg":200,"cholesterol_mg":6.7,"sat_fat_g":3.3,"trans_fat_g":0}'),

-- Cava Harissa dip: 60 cal per serving (~30g)
('cava_harissa', 'Cava Harissa', 200.0, 3.3, 10.0, 16.7, 3.3, 3.3, 30, 30, 'cava.com', ARRAY['cava harissa dip'], '60 cal per serving. {"sodium_mg":333,"cholesterol_mg":0,"sat_fat_g":2.3,"trans_fat_g":0}'),

-- Cava Greek Vinaigrette: 130 cal per serving (~30g)
('cava_greek_vinaigrette', 'Cava Greek Vinaigrette', 433.3, 0.0, 3.3, 46.7, 0.0, 3.3, 30, 30, 'cava.com', ARRAY['cava vinaigrette', 'cava greek dressing'], '130 cal per serving. {"sodium_mg":467,"cholesterol_mg":0,"sat_fat_g":6.7,"trans_fat_g":0}'),

-- Cava Avocado: 160 cal, 15f, 2p, 9c (~80g)
('cava_avocado', 'Cava Avocado', 200.0, 2.5, 11.3, 18.8, 8.8, 0.0, 80, 80, 'cava.com', ARRAY['cava avocado'], '160 cal per serving. {"sodium_mg":0,"cholesterol_mg":0,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- =====================================================
-- 10. WABA GRILL
-- Source: wabagrill.com, fastfoodnutrition.org
-- =====================================================

-- WaBa Chicken Bowl: 640 cal, 11f, 38p, 100c (~420g)
('waba_chicken_bowl', 'WaBa Grill Chicken Bowl', 152.4, 9.0, 23.8, 2.6, 0.2, 2.9, 420, 420, 'wabagrill.com', ARRAY['waba chicken bowl', 'waba grill chicken'], '640 cal per bowl. {"sodium_mg":381,"cholesterol_mg":21.4,"sat_fat_g":0.7,"trans_fat_g":0}'),

-- WaBa White Meat Chicken Bowl: 630 cal, 5f, 46p, 100c (~420g)
('waba_white_chicken_bowl', 'WaBa Grill White Meat Chicken Bowl', 150.0, 11.0, 23.8, 1.2, 0.2, 2.9, 420, 420, 'wabagrill.com', ARRAY['waba white chicken bowl', 'waba white meat'], '630 cal per bowl. {"sodium_mg":369,"cholesterol_mg":26.2,"sat_fat_g":0.5,"trans_fat_g":0}'),

-- WaBa Sweet & Spicy Chicken Bowl: 680 cal, 11f, 38p, 120c (~420g)
('waba_sweet_spicy_bowl', 'WaBa Grill Sweet & Spicy Chicken Bowl', 161.9, 9.0, 28.6, 2.6, 0.2, 7.9, 420, 420, 'wabagrill.com', ARRAY['waba sweet spicy', 'waba spicy chicken'], '680 cal per bowl. {"sodium_mg":405,"cholesterol_mg":21.4,"sat_fat_g":0.7,"trans_fat_g":0}'),

-- WaBa Rib-Eye Steak Bowl: 720 cal, 18f, 29p, 110c (~420g)
('waba_steak_bowl', 'WaBa Grill Rib-Eye Steak Bowl', 171.4, 6.9, 26.2, 4.3, 0.2, 5.0, 420, 420, 'wabagrill.com', ARRAY['waba steak bowl', 'waba ribeye'], '720 cal per bowl. {"sodium_mg":417,"cholesterol_mg":23.8,"sat_fat_g":2.1,"trans_fat_g":0}'),

-- WaBa Chicken & Steak Bowl: 710 cal, 16f, 37p, 100c (~420g)
('waba_chicken_steak_bowl', 'WaBa Grill Chicken & Steak Bowl', 169.0, 8.8, 23.8, 3.8, 0.2, 4.0, 420, 420, 'wabagrill.com', ARRAY['waba combo bowl', 'waba chicken steak'], '710 cal per bowl. {"sodium_mg":405,"cholesterol_mg":22.6,"sat_fat_g":1.4,"trans_fat_g":0}'),

-- WaBa Wild Caught Salmon Bowl: 540 cal, 5f, 29p, 90c (~420g)
('waba_salmon_bowl', 'WaBa Grill Wild Caught Salmon Bowl', 128.6, 6.9, 21.4, 1.2, 0.2, 2.1, 420, 420, 'wabagrill.com', ARRAY['waba salmon bowl'], '540 cal per bowl. {"sodium_mg":321,"cholesterol_mg":16.7,"sat_fat_g":0.5,"trans_fat_g":0}'),

-- WaBa Jumbo Shrimp Bowl: 490 cal, 1f, 19p, 90c (~420g)
('waba_shrimp_bowl', 'WaBa Grill Jumbo Shrimp Bowl', 116.7, 4.5, 21.4, 0.2, 0.2, 2.1, 420, 420, 'wabagrill.com', ARRAY['waba shrimp bowl'], '490 cal per bowl. {"sodium_mg":310,"cholesterol_mg":23.8,"sat_fat_g":0.2,"trans_fat_g":0}'),

-- WaBa Organic Tofu Bowl: 590 cal, 11f, 23p, 90c (~420g)
('waba_tofu_bowl', 'WaBa Grill Organic Tofu Bowl', 140.5, 5.5, 21.4, 2.6, 0.2, 2.1, 420, 420, 'wabagrill.com', ARRAY['waba tofu bowl'], '590 cal per bowl. {"sodium_mg":321,"cholesterol_mg":0,"sat_fat_g":0.5,"trans_fat_g":0}'),

-- WaBa Plantspired Steak Bowl: 660 cal, 15f, 22p, 110c (~420g)
('waba_plantspired_bowl', 'WaBa Grill Plantspired Steak Bowl', 157.1, 5.2, 26.2, 3.6, 1.4, 4.8, 420, 420, 'wabagrill.com', ARRAY['waba plant based bowl', 'waba plantspired'], '660 cal per bowl. {"sodium_mg":381,"cholesterol_mg":0,"sat_fat_g":0.7,"trans_fat_g":0}'),

-- WaBa Chicken Mini Bowl: 320 cal, 5f, 17p, 50c (~220g)
('waba_chicken_mini_bowl', 'WaBa Grill Chicken Mini Bowl', 145.5, 7.7, 22.7, 2.3, 0.5, 4.1, 220, 220, 'wabagrill.com', ARRAY['waba mini bowl', 'waba small bowl'], '320 cal per mini bowl. {"sodium_mg":409,"cholesterol_mg":22.7,"sat_fat_g":0.9,"trans_fat_g":0}'),

-- WaBa White Meat Chicken Mini Bowl: 320 cal, 2f, 21p, 50c (~220g)
('waba_white_chicken_mini', 'WaBa Grill White Meat Chicken Mini Bowl', 145.5, 9.5, 22.7, 0.9, 0.5, 4.1, 220, 220, 'wabagrill.com', ARRAY['waba white chicken mini'], '320 cal per mini bowl. {"sodium_mg":395,"cholesterol_mg":27.3,"sat_fat_g":0.5,"trans_fat_g":0}'),

-- WaBa Chicken Plate: 820 cal, 15f, 54p, 110c (~550g)
('waba_chicken_plate', 'WaBa Grill Chicken Plate', 149.1, 9.8, 20.0, 2.7, 0.5, 3.8, 550, 550, 'wabagrill.com', ARRAY['waba chicken plate'], '820 cal per plate. {"sodium_mg":364,"cholesterol_mg":21.8,"sat_fat_g":0.7,"trans_fat_g":0}'),

-- WaBa Rib-Eye Steak Plate: 980 cal, 27f, 44p, 130c (~550g)
('waba_steak_plate', 'WaBa Grill Rib-Eye Steak Plate', 178.2, 8.0, 23.6, 4.9, 0.5, 6.4, 550, 550, 'wabagrill.com', ARRAY['waba steak plate'], '980 cal per plate. {"sodium_mg":400,"cholesterol_mg":23.6,"sat_fat_g":2.2,"trans_fat_g":0}'),

-- WaBa Wild Caught Salmon Plate: 700 cal, 7f, 41p, 110c (~550g)
('waba_salmon_plate', 'WaBa Grill Wild Caught Salmon Plate', 127.3, 7.5, 20.0, 1.3, 0.5, 3.3, 550, 550, 'wabagrill.com', ARRAY['waba salmon plate'], '700 cal per plate. {"sodium_mg":309,"cholesterol_mg":16.4,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- WaBa Chicken Veggie Bowl: 590 cal, 11f, 39p, 90c (~450g)
('waba_chicken_veggie_bowl', 'WaBa Grill Chicken Veggie Bowl', 131.1, 8.7, 20.0, 2.4, 3.1, 3.8, 450, 450, 'wabagrill.com', ARRAY['waba veggie bowl chicken'], '590 cal per veggie bowl. {"sodium_mg":378,"cholesterol_mg":20,"sat_fat_g":0.7,"trans_fat_g":0}'),

-- WaBa White Meat Chicken Veggie Bowl: 580 cal, 5f, 47p, 90c (~450g)
('waba_white_chicken_veggie', 'WaBa Grill White Meat Chicken Veggie Bowl', 128.9, 10.4, 20.0, 1.1, 0.9, 3.8, 450, 450, 'wabagrill.com', ARRAY['waba white chicken veggie'], '580 cal per veggie bowl. {"sodium_mg":367,"cholesterol_mg":24.4,"sat_fat_g":0.4,"trans_fat_g":0}'),

-- WaBa Chicken Taco: 210 cal, 11f, 13p, 20c (~90g)
('waba_chicken_taco', 'WaBa Grill Chicken Taco', 233.3, 14.4, 22.2, 12.2, 2.2, 3.3, 90, 90, 'wabagrill.com', ARRAY['waba taco', 'waba chicken taco'], '210 cal per taco. {"sodium_mg":444,"cholesterol_mg":33.3,"sat_fat_g":2.2,"trans_fat_g":0}'),

-- WaBa Steak Taco: 240 cal, 14f, 10p, 20c (~90g)
('waba_steak_taco', 'WaBa Grill Steak Taco', 266.7, 11.1, 22.2, 15.6, 2.2, 4.4, 90, 90, 'wabagrill.com', ARRAY['waba steak taco'], '240 cal per taco. {"sodium_mg":467,"cholesterol_mg":33.3,"sat_fat_g":4.4,"trans_fat_g":0}'),

-- WaBa Shrimp Taco: 170 cal, 8f, 9p, 20c (~90g)
('waba_shrimp_taco', 'WaBa Grill Shrimp Taco', 188.9, 10.0, 22.2, 8.9, 2.2, 3.3, 90, 90, 'wabagrill.com', ARRAY['waba shrimp taco'], '170 cal per taco. {"sodium_mg":400,"cholesterol_mg":33.3,"sat_fat_g":1.1,"trans_fat_g":0}'),

-- WaBa Signature House Salad: 320 cal, 8f, 44p, 20c (~350g)
('waba_house_salad', 'WaBa Grill Signature House Salad', 91.4, 12.6, 5.7, 2.3, 0.9, 1.1, 350, 350, 'wabagrill.com', ARRAY['waba salad', 'waba house salad'], '320 cal per salad. {"sodium_mg":297,"cholesterol_mg":28.6,"sat_fat_g":0.6,"trans_fat_g":0}'),

-- WaBa Spicy Asian Salad: 420 cal, 10f, 49p, 30c (~350g)
('waba_spicy_asian_salad', 'WaBa Grill Spicy Asian Salad', 120.0, 14.0, 8.6, 2.9, 1.4, 4.0, 350, 350, 'wabagrill.com', ARRAY['waba asian salad', 'waba spicy salad'], '420 cal per salad. {"sodium_mg":343,"cholesterol_mg":28.6,"sat_fat_g":0.9,"trans_fat_g":0}'),

-- WaBa White Rice: 370 cal (~200g)
('waba_white_rice', 'WaBa Grill White Rice', 185.0, 1.5, 40.0, 1.0, 0.0, 0.0, 200, 200, 'wabagrill.com', ARRAY['waba rice', 'waba white rice'], '370 cal per side. {"sodium_mg":10,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),

-- WaBa Brown Rice: 320 cal (~200g)
('waba_brown_rice', 'WaBa Grill Brown Rice', 160.0, 2.0, 33.0, 2.0, 1.5, 0.0, 200, 200, 'wabagrill.com', ARRAY['waba brown rice'], '320 cal per side. {"sodium_mg":10,"cholesterol_mg":0,"sat_fat_g":0.5,"trans_fat_g":0}'),

-- WaBa Pork Veggie Dumplings (6pc): 210 cal (~120g)
('waba_pork_dumplings', 'WaBa Grill Pork Veggie Dumplings', 175.0, 5.0, 20.0, 8.3, 0.8, 1.7, 120, 120, 'wabagrill.com', ARRAY['waba dumplings', 'waba potstickers'], '210 cal per 6pc. {"sodium_mg":417,"cholesterol_mg":16.7,"sat_fat_g":2.5,"trans_fat_g":0}'),

-- WaBa Miso Soup: 30 cal (~250g)
('waba_miso_soup', 'WaBa Grill Miso Soup', 12.0, 0.8, 1.2, 0.4, 0.4, 0.4, 250, 250, 'wabagrill.com', ARRAY['waba miso', 'waba soup'], '30 cal per bowl. {"sodium_mg":280,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}'),

-- WaBa Steamed Veggies: 50 cal (~150g)
('waba_steamed_veggies', 'WaBa Grill Steamed Veggies', 33.3, 2.0, 5.3, 0.7, 2.0, 2.0, 150, 150, 'wabagrill.com', ARRAY['waba vegetables', 'waba steamed vegetables'], '50 cal per side. {"sodium_mg":27,"cholesterol_mg":0,"sat_fat_g":0,"trans_fat_g":0}')
