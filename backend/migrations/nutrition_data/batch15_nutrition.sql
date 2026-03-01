-- ============================================================================
-- Batch 15: BBQ Restaurant Chains
-- Restaurants: Dickey's, Famous Dave's, Sonny's, City Barbeque, Smokey Bones, Jim 'N Nick's
-- Generated: 2026-02-28
-- Sources: Official restaurant nutrition guides, nutritionix.com,
--          fatsecret.com, myfitnesspal.com, calorieking.com
-- All values are per-100g. Formula: (total_value / serving_weight_g) * 100
-- ============================================================================

-- ============================================================================
-- 1. DICKEY'S BARBECUE PIT (~386 US locations)
-- Source: dickeys.com/nutrition, nutritionix.com
-- ============================================================================

-- Brisket (chopped): 280 cal, 24g protein, 0g carbs, 20g fat per 140g
('dickeys_chopped_brisket', 'Dickey''s Chopped Brisket', 200.0, 17.1, 0.0, 14.3, 0.0, 0.0, NULL, 140, 'dickeys.com', ARRAY['dickeys brisket', 'dickeys chopped beef'], '280 cal per 140g serving. Slow-smoked 12+ hours over hickory.', 'Dickey''s', 'steak', 1),

-- Pulled Pork: 240 cal, 26g protein, 2g carbs, 14g fat per 140g
('dickeys_pulled_pork', 'Dickey''s Pulled Pork', 171.4, 18.6, 1.4, 10.0, 0.0, 1.0, NULL, 140, 'dickeys.com', ARRAY['dickeys pulled pork'], '240 cal per 140g serving.', 'Dickey''s', 'steak', 1),

-- Smoked Turkey Breast: 180 cal, 32g protein, 0g carbs, 6g fat per 140g
('dickeys_turkey_breast', 'Dickey''s Smoked Turkey Breast', 128.6, 22.9, 0.0, 4.3, 0.0, 0.0, NULL, 140, 'dickeys.com', ARRAY['dickeys turkey', 'dickeys smoked turkey'], '180 cal per 140g serving.', 'Dickey''s', 'chicken', 1),

-- Polish Sausage: 380 cal, 16g protein, 4g carbs, 32g fat per 150g
('dickeys_polish_sausage', 'Dickey''s Polish Sausage', 253.3, 10.7, 2.7, 21.3, 0.0, 1.0, 150, 150, 'dickeys.com', ARRAY['dickeys sausage', 'dickeys kielbasa'], '380 cal per link (150g).', 'Dickey''s', 'steak', 1),

-- Mac & Cheese: 280 cal, 10g protein, 28g carbs, 14g fat per 170g
('dickeys_mac_cheese', 'Dickey''s Mac & Cheese', 164.7, 5.9, 16.5, 8.2, 0.5, 2.0, NULL, 170, 'dickeys.com', ARRAY['dickeys mac and cheese'], '280 cal per 170g side.', 'Dickey''s', 'sides', 1),

-- Jalapeño Beans: 160 cal, 8g protein, 24g carbs, 4g fat per 170g
('dickeys_jalapeno_beans', 'Dickey''s Jalapeño Beans', 94.1, 4.7, 14.1, 2.4, 4.0, 3.0, NULL, 170, 'dickeys.com', ARRAY['dickeys beans', 'dickeys baked beans'], '160 cal per 170g side.', 'Dickey''s', 'sides', 1),

-- Fried Okra: 220 cal, 4g protein, 26g carbs, 12g fat per 130g
('dickeys_fried_okra', 'Dickey''s Fried Okra', 169.2, 3.1, 20.0, 9.2, 2.0, 2.0, NULL, 130, 'dickeys.com', ARRAY['dickeys okra'], '220 cal per 130g side.', 'Dickey''s', 'sides', 1),

-- ============================================================================
-- 2. FAMOUS DAVE'S (~109 US locations)
-- Source: famousdaves.com/nutrition, nutritionix.com
-- ============================================================================

-- St. Louis Ribs (half rack): 780 cal, 48g protein, 12g carbs, 60g fat per 350g
('famous_daves_stl_ribs', 'Famous Dave''s St. Louis Ribs (Half)', 222.9, 13.7, 3.4, 17.1, 0.0, 2.5, NULL, 350, 'famousdaves.com', ARRAY['famous daves ribs', 'famous daves st louis ribs'], '780 cal per half rack (350g). Slow-smoked with signature rub.', 'Famous Dave''s', 'steak', 1),

-- Georgia Chopped Pork: 280 cal, 28g protein, 6g carbs, 16g fat per 170g
('famous_daves_chopped_pork', 'Famous Dave''s Georgia Chopped Pork', 164.7, 16.5, 3.5, 9.4, 0.0, 4.0, NULL, 170, 'famousdaves.com', ARRAY['famous daves pulled pork', 'famous daves chopped pork'], '280 cal per 170g serving.', 'Famous Dave''s', 'steak', 1),

-- Texas Beef Brisket: 320 cal, 28g protein, 2g carbs, 22g fat per 170g
('famous_daves_brisket', 'Famous Dave''s Texas Beef Brisket', 188.2, 16.5, 1.2, 12.9, 0.0, 1.0, NULL, 170, 'famousdaves.com', ARRAY['famous daves brisket', 'famous daves beef brisket'], '320 cal per 170g serving.', 'Famous Dave''s', 'steak', 1),

-- Country-Roasted Chicken (half): 520 cal, 60g protein, 0g carbs, 30g fat per 300g
('famous_daves_roasted_chicken', 'Famous Dave''s Country-Roasted Chicken (Half)', 173.3, 20.0, 0.0, 10.0, 0.0, 0.0, NULL, 300, 'famousdaves.com', ARRAY['famous daves chicken', 'famous daves roasted chicken'], '520 cal per half chicken (300g).', 'Famous Dave''s', 'chicken', 1),

-- Corn Bread Muffin: 260 cal, 4g protein, 36g carbs, 10g fat per 90g
('famous_daves_cornbread', 'Famous Dave''s Corn Bread Muffin', 288.9, 4.4, 40.0, 11.1, 1.0, 12.0, 90, 90, 'famousdaves.com', ARRAY['famous daves cornbread'], '260 cal per muffin (90g).', 'Famous Dave''s', 'sides', 1),

-- Wilbur Beans: 200 cal, 10g protein, 30g carbs, 4g fat per 170g
('famous_daves_wilbur_beans', 'Famous Dave''s Wilbur Beans', 117.6, 5.9, 17.6, 2.4, 4.0, 8.0, NULL, 170, 'famousdaves.com', ARRAY['famous daves beans', 'famous daves baked beans'], '200 cal per 170g side.', 'Famous Dave''s', 'sides', 1),

-- ============================================================================
-- 3. SONNY'S BBQ (~113 US locations)
-- Source: sonnysbbq.com/nutrition, nutritionix.com
-- ============================================================================

-- Sliced Pork: 280 cal, 30g protein, 4g carbs, 16g fat per 170g
('sonnys_sliced_pork', 'Sonny''s BBQ Sliced Pork', 164.7, 17.6, 2.4, 9.4, 0.0, 3.0, NULL, 170, 'sonnysbbq.com', ARRAY['sonnys pork', 'sonnys sliced pork'], '280 cal per 170g serving.', 'Sonny''s BBQ', 'steak', 1),

-- Baby Back Ribs (half rack): 720 cal, 44g protein, 8g carbs, 56g fat per 320g
('sonnys_baby_back_ribs', 'Sonny''s BBQ Baby Back Ribs (Half)', 225.0, 13.8, 2.5, 17.5, 0.0, 2.0, NULL, 320, 'sonnysbbq.com', ARRAY['sonnys ribs', 'sonnys baby back ribs'], '720 cal per half rack (320g).', 'Sonny''s BBQ', 'steak', 1),

-- Smoked Chicken (quarter): 260 cal, 32g protein, 0g carbs, 14g fat per 200g
('sonnys_smoked_chicken', 'Sonny''s BBQ Smoked Chicken (Quarter)', 130.0, 16.0, 0.0, 7.0, 0.0, 0.0, NULL, 200, 'sonnysbbq.com', ARRAY['sonnys chicken', 'sonnys smoked chicken'], '260 cal per quarter (200g).', 'Sonny''s BBQ', 'chicken', 1),

-- Beef Brisket: 310 cal, 26g protein, 2g carbs, 22g fat per 170g
('sonnys_brisket', 'Sonny''s BBQ Beef Brisket', 182.4, 15.3, 1.2, 12.9, 0.0, 1.0, NULL, 170, 'sonnysbbq.com', ARRAY['sonnys brisket'], '310 cal per 170g serving.', 'Sonny''s BBQ', 'steak', 1),

-- Sweet Potato: 180 cal, 2g protein, 40g carbs, 2g fat per 200g
('sonnys_sweet_potato', 'Sonny''s BBQ Sweet Potato', 90.0, 1.0, 20.0, 1.0, 3.0, 8.0, 200, 200, 'sonnysbbq.com', ARRAY['sonnys sweet potato side'], '180 cal per 200g sweet potato.', 'Sonny''s BBQ', 'sides', 1),

-- Coleslaw: 160 cal, 1g protein, 14g carbs, 12g fat per 120g
('sonnys_coleslaw', 'Sonny''s BBQ Coleslaw', 133.3, 0.8, 11.7, 10.0, 1.5, 8.0, NULL, 120, 'sonnysbbq.com', ARRAY['sonnys coleslaw', 'sonnys cole slaw'], '160 cal per 120g side.', 'Sonny''s BBQ', 'sides', 1),

-- ============================================================================
-- 4. CITY BARBEQUE (~75 US locations)
-- Source: citybbq.com/nutrition, nutritionix.com
-- ============================================================================

-- Brisket: 300 cal, 26g protein, 0g carbs, 22g fat per 140g
('city_bbq_brisket', 'City Barbeque Brisket', 214.3, 18.6, 0.0, 15.7, 0.0, 0.0, NULL, 140, 'citybbq.com', ARRAY['city bbq brisket', 'city barbeque brisket'], '300 cal per 140g serving.', 'City Barbeque', 'steak', 1),

-- Pulled Chicken: 180 cal, 30g protein, 2g carbs, 6g fat per 140g
('city_bbq_pulled_chicken', 'City Barbeque Pulled Chicken', 128.6, 21.4, 1.4, 4.3, 0.0, 1.0, NULL, 140, 'citybbq.com', ARRAY['city bbq chicken', 'city barbeque chicken'], '180 cal per 140g serving.', 'City Barbeque', 'chicken', 1),

-- St. Louis Ribs (half): 680 cal, 42g protein, 6g carbs, 54g fat per 300g
('city_bbq_ribs', 'City Barbeque St. Louis Ribs (Half)', 226.7, 14.0, 2.0, 18.0, 0.0, 2.0, NULL, 300, 'citybbq.com', ARRAY['city bbq ribs', 'city barbeque ribs'], '680 cal per half rack (300g).', 'City Barbeque', 'steak', 1),

-- Smoked Sausage: 340 cal, 14g protein, 4g carbs, 30g fat per 130g
('city_bbq_sausage', 'City Barbeque Smoked Sausage', 261.5, 10.8, 3.1, 23.1, 0.0, 1.0, 130, 130, 'citybbq.com', ARRAY['city bbq sausage'], '340 cal per link (130g).', 'City Barbeque', 'steak', 1),

-- Cheesy Corn Bake: 220 cal, 6g protein, 22g carbs, 12g fat per 150g
('city_bbq_cheesy_corn', 'City Barbeque Cheesy Corn Bake', 146.7, 4.0, 14.7, 8.0, 1.5, 4.0, NULL, 150, 'citybbq.com', ARRAY['city bbq corn', 'city barbeque corn bake'], '220 cal per 150g side.', 'City Barbeque', 'sides', 1),

-- ============================================================================
-- 5. SMOKEY BONES (~62 US locations)
-- Source: smokeybones.com/nutrition, nutritionix.com
-- ============================================================================

-- Baby Back Ribs (full rack): 1200 cal, 72g protein, 12g carbs, 96g fat per 550g
('smokey_bones_full_ribs', 'Smokey Bones Baby Back Ribs (Full)', 218.2, 13.1, 2.2, 17.5, 0.0, 1.5, NULL, 550, 'smokeybones.com', ARRAY['smokey bones ribs', 'smokey bones baby back'], '1200 cal per full rack (550g).', 'Smokey Bones', 'steak', 1),

-- Pulled Pork Sandwich: 520 cal, 28g protein, 42g carbs, 24g fat per 280g
('smokey_bones_pulled_pork_sandwich', 'Smokey Bones Pulled Pork Sandwich', 185.7, 10.0, 15.0, 8.6, 1.0, 5.0, 280, 280, 'smokeybones.com', ARRAY['smokey bones pulled pork', 'smokey bones pork sandwich'], '520 cal per sandwich (280g).', 'Smokey Bones', 'sandwiches', 1),

-- Smoked Wings (10 pcs): 780 cal, 52g protein, 8g carbs, 60g fat per 400g
('smokey_bones_smoked_wings', 'Smokey Bones Smoked Wings', 195.0, 13.0, 2.0, 15.0, 0.0, 1.0, 40, 400, 'smokeybones.com', ARRAY['smokey bones wings'], '780 cal per 10 wings (400g).', 'Smokey Bones', 'chicken', 10),

-- Brisket Plate: 380 cal, 30g protein, 2g carbs, 28g fat per 200g
('smokey_bones_brisket', 'Smokey Bones Beef Brisket', 190.0, 15.0, 1.0, 14.0, 0.0, 0.5, NULL, 200, 'smokeybones.com', ARRAY['smokey bones brisket'], '380 cal per 200g serving.', 'Smokey Bones', 'steak', 1),

-- Loaded Baked Potato: 380 cal, 10g protein, 42g carbs, 20g fat per 300g
('smokey_bones_loaded_potato', 'Smokey Bones Loaded Baked Potato', 126.7, 3.3, 14.0, 6.7, 2.5, 2.0, 300, 300, 'smokeybones.com', ARRAY['smokey bones baked potato'], '380 cal per potato (300g). With butter, sour cream, cheese, bacon.', 'Smokey Bones', 'sides', 1),

-- ============================================================================
-- 6. JIM 'N NICK'S BBQ (~40 US locations)
-- Source: jimnnicks.com, nutritionix.com, myfitnesspal.com
-- ============================================================================

-- Pulled Pork Plate: 320 cal, 28g protein, 4g carbs, 22g fat per 170g
('jim_n_nicks_pulled_pork', 'Jim ''N Nick''s Pulled Pork', 188.2, 16.5, 2.4, 12.9, 0.0, 3.0, NULL, 170, 'jimnnicks.com', ARRAY['jim n nicks pulled pork', 'jim and nicks pork'], '320 cal per 170g serving.', 'Jim ''N Nick''s', 'steak', 1),

-- Smoked Chicken (half): 480 cal, 52g protein, 0g carbs, 28g fat per 300g
('jim_n_nicks_smoked_chicken', 'Jim ''N Nick''s Smoked Chicken (Half)', 160.0, 17.3, 0.0, 9.3, 0.0, 0.0, NULL, 300, 'jimnnicks.com', ARRAY['jim n nicks chicken', 'jim and nicks chicken'], '480 cal per half chicken (300g).', 'Jim ''N Nick''s', 'chicken', 1),

-- Baby Back Ribs (half): 650 cal, 40g protein, 8g carbs, 50g fat per 300g
('jim_n_nicks_baby_back', 'Jim ''N Nick''s Baby Back Ribs (Half)', 216.7, 13.3, 2.7, 16.7, 0.0, 2.0, NULL, 300, 'jimnnicks.com', ARRAY['jim n nicks ribs', 'jim and nicks baby back'], '650 cal per half rack (300g).', 'Jim ''N Nick''s', 'steak', 1),

-- Cheese Biscuits: 180 cal, 4g protein, 20g carbs, 10g fat per 60g
('jim_n_nicks_cheese_biscuit', 'Jim ''N Nick''s Cheese Biscuit', 300.0, 6.7, 33.3, 16.7, 0.5, 2.0, 60, 60, 'jimnnicks.com', ARRAY['jim n nicks biscuit', 'jim and nicks cheese biscuit'], '180 cal per biscuit (60g). Famous warm cheese biscuits.', 'Jim ''N Nick''s', 'sides', 1),

-- Pimento Cheese: 220 cal, 8g protein, 4g carbs, 20g fat per 80g
('jim_n_nicks_pimento_cheese', 'Jim ''N Nick''s Pimento Cheese', 275.0, 10.0, 5.0, 25.0, 0.0, 1.5, NULL, 80, 'jimnnicks.com', ARRAY['jim n nicks pimento cheese dip'], '220 cal per 80g serving.', 'Jim ''N Nick''s', 'sides', 1)
