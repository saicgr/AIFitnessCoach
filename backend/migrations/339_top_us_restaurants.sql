-- 339_top_us_restaurants.sql
-- Top US restaurants: Celebrity chef restaurants, upscale steakhouse chains,
-- missing popular chains, and famous one-of-a-kind/regional restaurants.
-- Sources: USDA FoodData Central, official restaurant nutrition PDFs,
-- nutritionix.com, calorieking.com, fatsecret.com, myfooddiary.com
-- All values per 100g.

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

-- ============================================================================
-- HELL'S KITCHEN (Gordon Ramsay, Las Vegas)
-- ============================================================================

('hk_beef_wellington', 'Hell''s Kitchen Beef Wellington', 265, 18.0, 14.0, 16.0,
 0.5, 1.0, 350, NULL,
 'hells_kitchen', ARRAY['hells kitchen beef wellington', 'gordon ramsay beef wellington', 'hk wellington'],
 'american', 'Hell''s Kitchen', 1, 'Signature dish. Beef tenderloin wrapped in mushroom duxelles and puff pastry. ~928 cal per 350g serving.', TRUE,
 420, 75, 6.5, 0.2, 310, 25, 2.8, 15, 1.0, 7, 24, 4.2, 200, 28.0, 0.04),

('hk_sticky_toffee_pudding', 'Hell''s Kitchen Sticky Toffee Pudding', 340, 3.5, 52.0, 14.0,
 0.5, 38.0, 180, NULL,
 'hells_kitchen', ARRAY['hells kitchen sticky toffee', 'hk sticky toffee pudding', 'gordon ramsay sticky toffee'],
 'dessert', 'Hell''s Kitchen', 1, '~612 cal per 180g serving. Date cake with toffee sauce and vanilla ice cream.', TRUE,
 280, 55, 8.0, 0.1, 150, 80, 1.0, 60, 0.5, 5, 12, 0.4, 70, 5.0, 0.02),

('hk_lobster_risotto', 'Hell''s Kitchen Lobster Risotto', 165, 10.0, 18.0, 6.5,
 0.3, 1.0, 320, NULL,
 'hells_kitchen', ARRAY['hells kitchen lobster risotto', 'hk risotto', 'gordon ramsay lobster risotto'],
 'seafood', 'Hell''s Kitchen', 1, '~528 cal per 320g serving. Creamy arborio rice with lobster.', TRUE,
 480, 55, 3.5, 0.0, 200, 60, 0.8, 20, 2.0, 10, 18, 1.2, 150, 20.0, 0.15),

('hk_fish_and_chips', 'Hell''s Kitchen Fish & Chips', 220, 12.0, 20.0, 10.0,
 1.5, 0.5, 400, NULL,
 'hells_kitchen', ARRAY['hells kitchen fish and chips', 'hk fish chips', 'gordon ramsay fish and chips'],
 'seafood', 'Hell''s Kitchen', 1, '~880 cal per 400g serving. Beer-battered cod with hand-cut chips.', TRUE,
 450, 40, 2.5, 0.1, 350, 20, 1.2, 5, 8.0, 15, 25, 0.6, 160, 22.0, 0.12),

('hk_lamb_chops', 'Hell''s Kitchen Herb-Crusted Lamb Chops', 250, 22.0, 3.0, 16.5,
 0.5, 0.5, 300, NULL,
 'hells_kitchen', ARRAY['hells kitchen lamb chops', 'hk lamb chops', 'gordon ramsay lamb'],
 'american', 'Hell''s Kitchen', 1, '~750 cal per 300g serving. Herb-crusted rack of lamb.', TRUE,
 380, 85, 7.0, 0.3, 290, 18, 2.0, 0, 1.0, 3, 22, 4.5, 180, 18.0, 0.08),

('hk_pan_seared_scallops', 'Hell''s Kitchen Pan-Seared Scallops', 130, 14.0, 8.0, 5.0,
 0.5, 1.0, 250, NULL,
 'hells_kitchen', ARRAY['hells kitchen scallops', 'hk scallops', 'gordon ramsay scallops'],
 'seafood', 'Hell''s Kitchen', 1, '~325 cal per 250g serving. Seared scallops with pea puree.', TRUE,
 520, 45, 2.5, 0.0, 280, 15, 0.6, 30, 3.0, 5, 35, 1.5, 200, 22.0, 0.20),

('hk_beef_burger', 'Hell''s Kitchen Beef Burger', 230, 15.0, 16.0, 12.0,
 1.0, 3.0, 350, NULL,
 'hells_kitchen', ARRAY['hells kitchen burger', 'hk burger', 'gordon ramsay burger'],
 'american', 'Hell''s Kitchen', 1, '~805 cal per 350g serving. Premium beef patty with brioche bun.', TRUE,
 550, 65, 5.5, 0.3, 280, 80, 2.5, 10, 2.0, 5, 22, 4.0, 170, 20.0, 0.03),

('hk_shepherds_pie', 'Hell''s Kitchen Shepherd''s Pie', 145, 9.0, 12.0, 7.0,
 1.5, 1.5, 350, NULL,
 'hells_kitchen', ARRAY['hells kitchen shepherds pie', 'hk shepherds pie'],
 'american', 'Hell''s Kitchen', 1, '~508 cal per 350g serving. Lamb mince with mashed potato topping.', TRUE,
 420, 40, 3.5, 0.1, 350, 35, 1.5, 50, 5.0, 3, 20, 3.0, 140, 10.0, 0.04),

('hk_crispy_salmon', 'Hell''s Kitchen Crispy Skin Salmon', 210, 20.0, 5.0, 12.0,
 0.5, 1.0, 280, NULL,
 'hells_kitchen', ARRAY['hells kitchen salmon', 'hk salmon', 'gordon ramsay crispy salmon'],
 'seafood', 'Hell''s Kitchen', 1, '~588 cal per 280g serving. Pan-seared salmon with crispy skin.', TRUE,
 380, 65, 2.8, 0.0, 400, 15, 0.5, 15, 2.0, 520, 30, 0.5, 260, 40.0, 1.80),

('hk_chicken_parmesan', 'Hell''s Kitchen Chicken Parmesan', 195, 16.0, 12.0, 9.5,
 1.0, 3.0, 380, NULL,
 'hells_kitchen', ARRAY['hells kitchen chicken parm', 'hk chicken parmesan'],
 'american', 'Hell''s Kitchen', 1, '~741 cal per 380g serving. Breaded chicken with marinara and mozzarella.', TRUE,
 520, 60, 3.8, 0.1, 350, 120, 1.5, 40, 5.0, 5, 28, 1.8, 220, 22.0, 0.03),

('hk_truffle_mac_cheese', 'Hell''s Kitchen Truffle Mac & Cheese', 200, 8.0, 18.0, 11.0,
 0.5, 2.0, 280, NULL,
 'hells_kitchen', ARRAY['hells kitchen mac and cheese', 'hk truffle mac cheese'],
 'sides', 'Hell''s Kitchen', 1, '~560 cal per 280g serving. Cavatappi with truffle cream and aged cheddar.', TRUE,
 580, 35, 6.5, 0.1, 120, 180, 0.8, 50, 0.0, 3, 15, 1.2, 160, 8.0, 0.02),

('hk_roasted_beet_salad', 'Hell''s Kitchen Roasted Beet Salad', 95, 4.0, 10.0, 5.0,
 2.0, 6.0, 250, NULL,
 'hells_kitchen', ARRAY['hells kitchen beet salad', 'hk beet salad'],
 'salad', 'Hell''s Kitchen', 1, '~238 cal per 250g serving. Roasted beets with goat cheese and arugula.', TRUE,
 280, 10, 2.5, 0.0, 320, 60, 1.0, 40, 8.0, 0, 18, 0.5, 50, 2.0, 0.05),

('hk_caesar_salad', 'Hell''s Kitchen Caesar Salad', 110, 5.0, 6.0, 8.0,
 1.5, 1.0, 250, NULL,
 'hells_kitchen', ARRAY['hells kitchen caesar', 'hk caesar salad'],
 'salad', 'Hell''s Kitchen', 1, '~275 cal per 250g serving. Romaine with classic Caesar dressing and croutons.', TRUE,
 450, 15, 2.0, 0.0, 200, 80, 1.0, 80, 12.0, 2, 12, 0.5, 60, 4.0, 0.03),

('hk_churros', 'Hell''s Kitchen Churros', 350, 4.0, 45.0, 17.0,
 1.0, 20.0, 150, NULL,
 'hells_kitchen', ARRAY['hells kitchen churros', 'hk churros'],
 'dessert', 'Hell''s Kitchen', 1, '~525 cal per 150g serving. Fried dough with chocolate dipping sauce.', TRUE,
 250, 30, 5.0, 0.2, 80, 30, 1.5, 10, 0.0, 2, 10, 0.5, 50, 5.0, 0.01),

-- ============================================================================
-- GORDON RAMSAY STEAK (Las Vegas)
-- ============================================================================

('gr_steak_filet', 'Gordon Ramsay Steak Filet Mignon', 220, 28.0, 0.0, 12.0,
 0.0, 0.0, 230, NULL,
 'gr_steak', ARRAY['gordon ramsay steak filet', 'gr steak filet mignon'],
 'steakhouse', 'Gordon Ramsay Steak', 1, '~506 cal per 8oz (230g) filet. USDA prime beef.', TRUE,
 55, 80, 5.0, 0.3, 360, 15, 3.2, 0, 0.0, 7, 26, 4.5, 230, 32.0, 0.03),

('gr_steak_ribeye', 'Gordon Ramsay Steak Ribeye', 270, 25.0, 0.0, 18.0,
 0.0, 0.0, 400, NULL,
 'gr_steak', ARRAY['gordon ramsay steak ribeye', 'gr steak bone in ribeye'],
 'steakhouse', 'Gordon Ramsay Steak', 1, '~1080 cal per 14oz (400g) bone-in ribeye. USDA prime.', TRUE,
 65, 85, 8.0, 0.5, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('gr_steak_strip', 'Gordon Ramsay Steak Bone-In Strip', 250, 26.0, 0.0, 16.0,
 0.0, 0.0, 400, NULL,
 'gr_steak', ARRAY['gordon ramsay strip steak', 'gr steak ny strip'],
 'steakhouse', 'Gordon Ramsay Steak', 1, '~1000 cal per 14oz (400g) bone-in NY strip.', TRUE,
 58, 78, 6.5, 0.3, 330, 17, 2.6, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('gr_steak_lobster_tail', 'Gordon Ramsay Steak Lobster Tail', 105, 20.0, 1.0, 2.0,
 0.0, 0.0, 200, NULL,
 'gr_steak', ARRAY['gordon ramsay lobster tail', 'gr steak lobster'],
 'seafood', 'Gordon Ramsay Steak', 1, '~210 cal per 200g lobster tail with drawn butter.', TRUE,
 420, 145, 0.5, 0.0, 220, 60, 0.4, 5, 0.0, 0, 35, 3.5, 220, 40.0, 0.10),

('gr_steak_truffle_mac', 'Gordon Ramsay Steak Truffle Mac & Cheese', 195, 8.0, 17.0, 10.5,
 0.5, 2.0, 250, NULL,
 'gr_steak', ARRAY['gr steak mac and cheese', 'gordon ramsay steak mac cheese'],
 'sides', 'Gordon Ramsay Steak', 1, '~488 cal per 250g side.', TRUE,
 560, 35, 6.0, 0.1, 110, 170, 0.8, 45, 0.0, 3, 14, 1.1, 150, 7.0, 0.02),

('gr_steak_beef_tartare', 'Gordon Ramsay Steak Beef Tartare', 160, 18.0, 2.0, 9.0,
 0.0, 0.5, 150, NULL,
 'gr_steak', ARRAY['gr steak tartare', 'gordon ramsay beef tartare'],
 'steakhouse', 'Gordon Ramsay Steak', 1, '~240 cal per 150g serving. Hand-cut beef with capers and egg yolk.', TRUE,
 380, 70, 3.5, 0.2, 300, 10, 2.5, 30, 1.0, 7, 20, 4.0, 180, 18.0, 0.03),

('gr_steak_sticky_toffee', 'Gordon Ramsay Steak Sticky Toffee Pudding', 335, 3.5, 50.0, 14.0,
 0.5, 36.0, 180, NULL,
 'gr_steak', ARRAY['gr steak sticky toffee', 'gordon ramsay steak dessert'],
 'dessert', 'Gordon Ramsay Steak', 1, '~603 cal per 180g serving.', TRUE,
 270, 50, 7.5, 0.1, 140, 75, 1.0, 55, 0.5, 5, 11, 0.4, 65, 5.0, 0.02),

('gr_steak_brussels', 'Gordon Ramsay Steak Roasted Brussels Sprouts', 85, 4.0, 8.0, 5.0,
 3.0, 2.0, 180, NULL,
 'gr_steak', ARRAY['gr steak brussels sprouts', 'gordon ramsay brussels'],
 'sides', 'Gordon Ramsay Steak', 1, '~153 cal per 180g side.', TRUE,
 280, 0, 1.0, 0.0, 350, 40, 1.2, 30, 60.0, 0, 20, 0.4, 60, 1.5, 0.10),

('gr_steak_creamed_spinach', 'Gordon Ramsay Steak Creamed Spinach', 130, 4.5, 5.0, 10.0,
 1.5, 1.5, 180, NULL,
 'gr_steak', ARRAY['gr steak creamed spinach'],
 'sides', 'Gordon Ramsay Steak', 1, '~234 cal per 180g side.', TRUE,
 400, 25, 6.0, 0.1, 350, 120, 2.0, 350, 15.0, 5, 50, 0.6, 60, 3.0, 0.05),

('gr_steak_caesar', 'Gordon Ramsay Steak Caesar Salad', 115, 5.0, 6.0, 8.5,
 1.5, 1.0, 240, NULL,
 'gr_steak', ARRAY['gr steak caesar salad'],
 'salad', 'Gordon Ramsay Steak', 1, '~276 cal per 240g serving.', TRUE,
 440, 15, 2.0, 0.0, 190, 80, 1.0, 75, 10.0, 2, 12, 0.5, 55, 4.0, 0.03)
,
-- ============================================================================
-- GUY FIERI'S FLAVORTOWN / CHICKEN GUY!
-- ============================================================================

('guy_fieri_trash_can_nachos', 'Guy Fieri''s Trash Can Nachos', 195, 10.0, 16.0, 10.5,
 2.0, 2.0, 450, NULL,
 'guy_fieri', ARRAY['guy fieri nachos', 'trash can nachos', 'flavortown nachos'],
 'american', 'Guy Fieri''s', 1, '~878 cal per 450g serving. Layered nachos with pork, beans, cheese, pico.', TRUE,
 620, 40, 5.0, 0.2, 280, 100, 1.5, 30, 5.0, 3, 25, 2.0, 150, 10.0, 0.03),

('guy_fieri_mac_daddy', 'Guy Fieri''s Mac Daddy Mac & Cheese', 210, 9.0, 20.0, 11.0,
 0.5, 2.0, 350, NULL,
 'guy_fieri', ARRAY['guy fieri mac and cheese', 'mac daddy mac cheese', 'flavortown mac cheese'],
 'american', 'Guy Fieri''s', 1, '~735 cal per 350g serving. Six-cheese mac with crispy breadcrumb topping.', TRUE,
 600, 40, 6.5, 0.1, 130, 200, 1.0, 50, 0.0, 3, 16, 1.3, 170, 8.0, 0.02),

('guy_fieri_bacon_mac_burger', 'Guy Fieri''s Bacon Mac N Cheeseburger', 255, 14.0, 18.0, 15.0,
 1.0, 4.0, 400, NULL,
 'guy_fieri', ARRAY['guy fieri burger', 'bacon mac n cheeseburger', 'flavortown burger'],
 'american', 'Guy Fieri''s', 1, '~1020 cal per 400g serving. Burger topped with mac & cheese and bacon.', TRUE,
 680, 75, 6.5, 0.4, 300, 120, 2.5, 15, 2.0, 5, 22, 4.0, 180, 20.0, 0.03),

('guy_fieri_chicken_sandwich', 'Guy Fieri''s Real Chick Sandwich', 230, 16.0, 18.0, 11.0,
 1.0, 3.0, 300, NULL,
 'guy_fieri', ARRAY['guy fieri chicken sandwich', 'real chick sandwich', 'chicken guy sandwich'],
 'american', 'Guy Fieri''s', 1, '~690 cal per 300g serving. Crispy chicken breast sandwich.', TRUE,
 580, 50, 3.0, 0.1, 250, 30, 1.5, 8, 3.0, 3, 25, 1.2, 180, 20.0, 0.03),

('guy_fieri_tenders', 'Guy Fieri''s Chicken Tenders', 240, 18.0, 14.0, 12.0,
 0.5, 0.5, 200, NULL,
 'guy_fieri', ARRAY['guy fieri chicken tenders', 'chicken guy tenders'],
 'american', 'Guy Fieri''s', 1, '~480 cal per 200g serving. Hand-breaded chicken tenders.', TRUE,
 520, 55, 2.5, 0.1, 220, 15, 1.0, 5, 0.0, 3, 22, 1.0, 170, 18.0, 0.02),

('guy_fieri_garlic_fries', 'Guy Fieri''s Garlic Fries', 280, 4.0, 34.0, 15.0,
 3.0, 0.5, 250, NULL,
 'guy_fieri', ARRAY['guy fieri fries', 'flavortown garlic fries'],
 'sides', 'Guy Fieri''s', 1, '~700 cal per 250g serving. Crispy fries with roasted garlic and parsley.', TRUE,
 380, 0, 3.0, 0.1, 500, 10, 0.7, 0, 6.0, 0, 22, 0.3, 65, 2.0, 0.01),

('guy_fieri_onion_rings', 'Guy Fieri''s Onion Rings', 270, 4.0, 32.0, 14.0,
 2.0, 5.0, 200, NULL,
 'guy_fieri', ARRAY['guy fieri onion rings', 'flavortown onion rings'],
 'sides', 'Guy Fieri''s', 1, '~540 cal per 200g serving. Beer-battered onion rings.', TRUE,
 450, 10, 3.0, 0.1, 150, 30, 1.0, 0, 3.0, 0, 10, 0.3, 40, 3.0, 0.01),

('guy_fieri_milkshake', 'Guy Fieri''s Milkshake', 200, 4.0, 30.0, 8.0,
 0.0, 26.0, 450, NULL,
 'guy_fieri', ARRAY['guy fieri shake', 'flavortown milkshake'],
 'dessert', 'Guy Fieri''s', 1, '~900 cal per 450g shake.', TRUE,
 180, 30, 5.0, 0.1, 250, 150, 0.3, 50, 1.0, 10, 18, 0.6, 120, 4.0, 0.02),

('guy_fieri_guys_burger', 'Guy Fieri''s Guy''s Burger', 240, 15.0, 16.0, 13.0,
 1.0, 4.0, 350, NULL,
 'guy_fieri', ARRAY['guys burger', 'guy fieri classic burger'],
 'american', 'Guy Fieri''s', 1, '~840 cal per 350g serving. Signature beef burger.', TRUE,
 560, 70, 5.5, 0.3, 290, 80, 2.5, 10, 2.0, 5, 22, 4.0, 170, 20.0, 0.03),

-- ============================================================================
-- NOBU
-- ============================================================================

('nobu_black_cod_miso', 'Nobu Black Cod with Miso', 210, 16.0, 10.0, 12.0,
 0.5, 8.0, 250, NULL,
 'nobu', ARRAY['nobu black cod', 'nobu miso cod', 'black cod miso nobu'],
 'japanese', 'Nobu', 1, '~525 cal per 250g serving. Signature miso-marinated sablefish.', TRUE,
 480, 55, 2.5, 0.0, 350, 20, 0.8, 40, 0.0, 200, 35, 0.5, 220, 35.0, 1.50),

('nobu_yellowtail_jalapeno', 'Nobu Yellowtail Jalapeño', 130, 18.0, 3.0, 5.0,
 0.3, 1.0, 150, NULL,
 'nobu', ARRAY['nobu yellowtail', 'yellowtail jalapeno nobu', 'nobu yellowtail sashimi'],
 'japanese', 'Nobu', 1, '~195 cal per 150g serving. Thin-sliced yellowtail with jalapeño and yuzu.', TRUE,
 350, 40, 1.0, 0.0, 400, 10, 0.5, 15, 5.0, 100, 30, 0.5, 180, 45.0, 0.30),

('nobu_rock_shrimp_tempura', 'Nobu Rock Shrimp Tempura', 220, 12.0, 18.0, 11.0,
 0.5, 3.0, 200, NULL,
 'nobu', ARRAY['nobu rock shrimp', 'rock shrimp tempura nobu'],
 'japanese', 'Nobu', 1, '~440 cal per 200g serving. Crispy rock shrimp with creamy spicy sauce.', TRUE,
 520, 80, 2.0, 0.1, 180, 30, 1.0, 10, 2.0, 5, 25, 1.0, 150, 20.0, 0.08),

('nobu_crispy_rice_tuna', 'Nobu Crispy Rice with Spicy Tuna', 185, 14.0, 18.0, 6.5,
 0.5, 2.0, 180, NULL,
 'nobu', ARRAY['nobu crispy rice', 'nobu spicy tuna crispy rice'],
 'japanese', 'Nobu', 1, '~333 cal per 180g serving. Seared rice cakes topped with spicy tuna.', TRUE,
 420, 30, 1.0, 0.0, 280, 10, 1.0, 50, 2.0, 80, 28, 0.4, 170, 50.0, 0.25),

('nobu_new_style_sashimi', 'Nobu New-Style Sashimi', 120, 18.0, 2.0, 4.5,
 0.0, 0.5, 150, NULL,
 'nobu', ARRAY['nobu sashimi', 'new style sashimi nobu'],
 'japanese', 'Nobu', 1, '~180 cal per 150g serving. Sliced fish with hot olive oil and ponzu.', TRUE,
 380, 35, 0.8, 0.0, 350, 8, 0.4, 10, 1.0, 80, 28, 0.4, 170, 42.0, 0.40),

('nobu_miso_soup', 'Nobu Miso Soup', 35, 2.5, 3.5, 1.0,
 0.5, 1.5, 250, NULL,
 'nobu', ARRAY['nobu miso soup'],
 'japanese', 'Nobu', 1, '~88 cal per 250g bowl. Dashi broth with silken tofu and wakame.', TRUE,
 500, 0, 0.2, 0.0, 150, 20, 1.0, 2, 0.0, 0, 15, 0.3, 40, 1.0, 0.02),

('nobu_edamame', 'Nobu Edamame', 120, 11.0, 8.0, 5.0,
 5.0, 2.5, 150, NULL,
 'nobu', ARRAY['nobu edamame', 'edamame nobu'],
 'japanese', 'Nobu', 1, '~180 cal per 150g serving. Steamed soybeans with sea salt.', TRUE,
 350, 0, 0.6, 0.0, 480, 60, 2.5, 9, 6.0, 0, 65, 1.0, 170, 1.5, 0.30),

('nobu_bento_box', 'Nobu Bento Box', 175, 15.0, 16.0, 6.0,
 1.5, 3.0, 500, NULL,
 'nobu', ARRAY['nobu bento', 'nobu lunch bento box'],
 'japanese', 'Nobu', 1, '~875 cal per 500g bento. Assorted sashimi, tempura, rice, miso soup.', TRUE,
 520, 45, 1.5, 0.0, 320, 30, 1.2, 20, 3.0, 60, 30, 0.8, 180, 30.0, 0.35),

('nobu_wagyu_tataki', 'Nobu Wagyu Beef Tataki', 200, 20.0, 3.0, 12.0,
 0.0, 1.5, 150, NULL,
 'nobu', ARRAY['nobu wagyu', 'nobu beef tataki', 'wagyu tataki nobu'],
 'japanese', 'Nobu', 1, '~300 cal per 150g serving. Seared wagyu with ponzu and garlic chips.', TRUE,
 380, 65, 5.0, 0.3, 300, 8, 2.0, 0, 1.0, 7, 20, 5.0, 180, 18.0, 0.05),

('nobu_tiradito', 'Nobu Tiradito', 95, 15.0, 3.0, 2.5,
 0.3, 1.5, 150, NULL,
 'nobu', ARRAY['nobu tiradito', 'nobu peruvian sashimi'],
 'japanese', 'Nobu', 1, '~143 cal per 150g serving. Peruvian-style sashimi with aji amarillo.', TRUE,
 350, 30, 0.5, 0.0, 320, 10, 0.4, 15, 3.0, 60, 25, 0.4, 160, 40.0, 0.35),

('nobu_squid_pasta', 'Nobu Squid Pasta', 160, 10.0, 22.0, 4.0,
 1.0, 1.5, 300, NULL,
 'nobu', ARRAY['nobu squid pasta', 'nobu seafood pasta'],
 'japanese', 'Nobu', 1, '~480 cal per 300g serving. Pasta with grilled squid and light garlic sauce.', TRUE,
 420, 120, 0.8, 0.0, 200, 20, 1.5, 5, 1.0, 5, 25, 1.5, 150, 30.0, 0.10),

('nobu_chocolate_bento', 'Nobu Chocolate Bento Box', 380, 5.0, 42.0, 22.0,
 2.0, 30.0, 150, NULL,
 'nobu', ARRAY['nobu chocolate bento', 'nobu chocolate dessert'],
 'dessert', 'Nobu', 1, '~570 cal per 150g serving. Chocolate cake with green tea ice cream.', TRUE,
 120, 40, 12.0, 0.1, 200, 50, 2.5, 20, 0.0, 3, 40, 1.0, 80, 3.0, 0.02)
,
-- ============================================================================
-- WOLFGANG PUCK (CUT / Spago)
-- ============================================================================

('wp_prime_ny_steak', 'Wolfgang Puck CUT USDA Prime NY Steak', 250, 26.0, 0.0, 16.0,
 0.0, 0.0, 400, NULL,
 'wolfgang_puck', ARRAY['wolfgang puck ny strip', 'cut ny steak', 'spago steak'],
 'steakhouse', 'Wolfgang Puck', 1, '~1000 cal per 14oz (400g) USDA prime NY strip.', TRUE,
 58, 78, 6.5, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('wp_bone_in_ribeye', 'Wolfgang Puck CUT Bone-In Ribeye', 275, 24.0, 0.0, 20.0,
 0.0, 0.0, 450, NULL,
 'wolfgang_puck', ARRAY['wolfgang puck ribeye', 'cut ribeye', 'spago ribeye'],
 'steakhouse', 'Wolfgang Puck', 1, '~1238 cal per 16oz (450g) bone-in ribeye.', TRUE,
 65, 85, 8.5, 0.5, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('wp_smoked_salmon_pizza', 'Wolfgang Puck Smoked Salmon Pizza', 210, 10.0, 22.0, 9.0,
 1.0, 2.0, 280, NULL,
 'wolfgang_puck', ARRAY['spago smoked salmon pizza', 'wolfgang puck pizza'],
 'pizza', 'Wolfgang Puck', 1, '~588 cal per 280g serving. Signature Spago pizza with smoked salmon and crème fraiche.', TRUE,
 480, 25, 3.5, 0.0, 200, 60, 1.5, 20, 2.0, 80, 15, 0.5, 120, 15.0, 0.40),

('wp_wiener_schnitzel', 'Wolfgang Puck Wiener Schnitzel', 230, 18.0, 12.0, 12.0,
 0.5, 0.5, 300, NULL,
 'wolfgang_puck', ARRAY['spago schnitzel', 'wolfgang puck schnitzel'],
 'american', 'Wolfgang Puck', 1, '~690 cal per 300g serving. Breaded veal cutlet with lingonberry.', TRUE,
 400, 85, 3.5, 0.1, 280, 25, 1.5, 5, 2.0, 5, 22, 2.5, 200, 20.0, 0.02),

('wp_short_rib', 'Wolfgang Puck Braised Short Rib', 280, 22.0, 5.0, 19.0,
 0.5, 2.0, 350, NULL,
 'wolfgang_puck', ARRAY['wolfgang puck short rib', 'cut short rib', 'spago short rib'],
 'steakhouse', 'Wolfgang Puck', 1, '~980 cal per 350g serving. Slow-braised beef short rib.', TRUE,
 380, 90, 8.0, 0.5, 320, 15, 2.8, 0, 1.0, 6, 20, 6.5, 190, 20.0, 0.03),

('wp_truffle_mac', 'Wolfgang Puck Truffle Mac & Cheese', 200, 8.0, 18.0, 11.0,
 0.5, 2.0, 250, NULL,
 'wolfgang_puck', ARRAY['spago mac cheese', 'cut mac and cheese'],
 'sides', 'Wolfgang Puck', 1, '~500 cal per 250g side.', TRUE,
 560, 35, 6.0, 0.1, 120, 180, 0.8, 50, 0.0, 3, 15, 1.2, 160, 8.0, 0.02),

('wp_lobster_bolognese', 'Wolfgang Puck Lobster Bolognese', 170, 12.0, 20.0, 5.0,
 1.0, 3.0, 350, NULL,
 'wolfgang_puck', ARRAY['spago lobster bolognese', 'wolfgang puck pasta'],
 'seafood', 'Wolfgang Puck', 1, '~595 cal per 350g serving. Lobster meat with tagliatelle pasta.', TRUE,
 420, 60, 2.0, 0.0, 250, 40, 1.5, 15, 3.0, 10, 25, 1.0, 160, 22.0, 0.15),

('wp_creme_brulee', 'Wolfgang Puck Crème Brûlée', 280, 4.0, 28.0, 17.0,
 0.0, 24.0, 150, NULL,
 'wolfgang_puck', ARRAY['spago creme brulee', 'wolfgang puck dessert'],
 'dessert', 'Wolfgang Puck', 1, '~420 cal per 150g serving. Classic vanilla custard with caramelized sugar.', TRUE,
 60, 180, 10.0, 0.1, 100, 80, 0.5, 120, 0.0, 20, 8, 0.5, 100, 5.0, 0.02),

-- ============================================================================
-- MOMOFUKU
-- ============================================================================

('momofuku_pork_belly_buns', 'Momofuku Pork Belly Buns', 290, 12.0, 22.0, 17.0,
 1.0, 5.0, 120, 120,
 'momofuku', ARRAY['momofuku pork buns', 'momofuku bao', 'david chang pork buns'],
 'asian', 'Momofuku', 1, '~348 cal per bun (120g). Steamed bun with pork belly, hoisin, cucumbers.', TRUE,
 550, 45, 6.0, 0.1, 180, 20, 1.5, 5, 2.0, 5, 12, 1.5, 100, 12.0, 0.02),

('momofuku_ramen', 'Momofuku Ramen', 110, 8.0, 10.0, 4.5,
 0.5, 1.0, 600, NULL,
 'momofuku', ARRAY['momofuku noodles', 'david chang ramen'],
 'asian', 'Momofuku', 1, '~660 cal per 600g bowl. Rich pork broth with noodles, pork, and egg.', TRUE,
 650, 35, 1.5, 0.0, 200, 20, 1.0, 15, 1.0, 5, 15, 1.5, 80, 10.0, 0.03),

('momofuku_fried_chicken', 'Momofuku Fried Chicken', 260, 20.0, 10.0, 16.0,
 0.5, 1.0, 350, NULL,
 'momofuku', ARRAY['momofuku chicken', 'david chang fried chicken'],
 'asian', 'Momofuku', 1, '~910 cal per 350g serving. Korean-style fried chicken.', TRUE,
 520, 75, 4.0, 0.1, 250, 20, 1.2, 8, 1.0, 5, 25, 1.5, 180, 22.0, 0.03),

('momofuku_bo_ssam', 'Momofuku Bo Ssäm', 230, 18.0, 5.0, 16.0,
 0.5, 3.0, 200, NULL,
 'momofuku', ARRAY['momofuku bo ssam', 'david chang bo ssam', 'momofuku pork shoulder'],
 'asian', 'Momofuku', 1, '~460 cal per 200g serving. Slow-roasted pork shoulder with oyster sauce.', TRUE,
 480, 70, 6.0, 0.1, 300, 15, 1.2, 3, 1.0, 10, 18, 3.0, 170, 25.0, 0.02),

('momofuku_rice_cakes', 'Momofuku Rice Cakes', 180, 6.0, 28.0, 5.5,
 1.0, 4.0, 250, NULL,
 'momofuku', ARRAY['momofuku rice cakes', 'momofuku tteok'],
 'asian', 'Momofuku', 1, '~450 cal per 250g serving. Pan-fried rice cakes with spicy sauce.', TRUE,
 520, 10, 1.0, 0.0, 150, 15, 1.0, 30, 5.0, 0, 10, 0.5, 50, 5.0, 0.02),

('momofuku_chili_noodles', 'Momofuku Chili Noodles', 155, 6.0, 22.0, 5.0,
 1.5, 2.0, 350, NULL,
 'momofuku', ARRAY['momofuku chili noodles', 'momofuku spicy noodles'],
 'asian', 'Momofuku', 1, '~543 cal per 350g serving. Hand-pulled noodles with chili oil.', TRUE,
 580, 5, 1.0, 0.0, 150, 15, 1.5, 20, 3.0, 0, 15, 0.5, 60, 8.0, 0.02),

('momofuku_corn', 'Momofuku Corn with Miso Butter', 140, 3.0, 18.0, 7.0,
 2.0, 6.0, 200, NULL,
 'momofuku', ARRAY['momofuku corn', 'momofuku elote'],
 'sides', 'Momofuku', 1, '~280 cal per 200g serving. Grilled corn with miso butter and lime.', TRUE,
 380, 10, 3.5, 0.0, 280, 10, 0.5, 10, 7.0, 0, 30, 0.5, 80, 1.0, 0.02),

('momofuku_brussels', 'Momofuku Brussels Sprouts', 120, 4.0, 10.0, 8.0,
 3.0, 3.0, 200, NULL,
 'momofuku', ARRAY['momofuku brussels sprouts', 'momofuku brussels'],
 'sides', 'Momofuku', 1, '~240 cal per 200g serving. Fried brussels sprouts with fish sauce vinaigrette.', TRUE,
 450, 0, 1.5, 0.0, 350, 35, 1.2, 25, 55.0, 0, 20, 0.4, 60, 1.5, 0.08)
,
-- ============================================================================
-- RUTH'S CHRIS STEAK HOUSE
-- ============================================================================

('ruths_chris_petite_filet', 'Ruth''s Chris Petite Filet', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 170, NULL,
 'ruths_chris', ARRAY['ruths chris petite filet', 'ruths chris small filet'],
 'steakhouse', 'Ruth''s Chris', 1, '~383 cal per 6oz (170g) petite filet. Served sizzling in butter.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('ruths_chris_filet', 'Ruth''s Chris Filet', 230, 28.0, 0.0, 13.0,
 0.0, 0.0, 310, NULL,
 'ruths_chris', ARRAY['ruths chris filet mignon', 'ruths chris 11oz filet'],
 'steakhouse', 'Ruth''s Chris', 1, '~713 cal per 11oz (310g) filet. Butter-topped sizzling plate.', TRUE,
 58, 82, 5.5, 0.3, 360, 16, 3.5, 0, 0.0, 7, 27, 4.0, 235, 33.0, 0.03),

('ruths_chris_ny_strip', 'Ruth''s Chris NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 340, NULL,
 'ruths_chris', ARRAY['ruths chris new york strip', 'ruths chris strip steak'],
 'steakhouse', 'Ruth''s Chris', 1, '~867 cal per 12oz (340g) NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('ruths_chris_ribeye', 'Ruth''s Chris Ribeye', 275, 25.0, 0.0, 19.0,
 0.0, 0.0, 450, NULL,
 'ruths_chris', ARRAY['ruths chris bone in ribeye', 'ruths chris ribeye steak'],
 'steakhouse', 'Ruth''s Chris', 1, '~1238 cal per 16oz (450g) ribeye.', TRUE,
 65, 85, 8.5, 0.5, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('ruths_chris_porterhouse', 'Ruth''s Chris Porterhouse for Two', 260, 25.5, 0.0, 17.0,
 0.0, 0.0, 900, NULL,
 'ruths_chris', ARRAY['ruths chris porterhouse', 'ruths chris porterhouse for 2'],
 'steakhouse', 'Ruth''s Chris', 1, '~2340 cal per 40oz (900g) porterhouse for two. T-bone and filet.', TRUE,
 60, 80, 7.5, 0.4, 340, 16, 2.5, 0, 0.0, 7, 23, 4.5, 210, 27.0, 0.03),

('ruths_chris_tbone', 'Ruth''s Chris T-Bone', 260, 25.0, 0.0, 17.0,
 0.0, 0.0, 510, NULL,
 'ruths_chris', ARRAY['ruths chris t bone', 'ruths chris t-bone steak'],
 'steakhouse', 'Ruth''s Chris', 1, '~1326 cal per 18oz (510g) T-bone.', TRUE,
 60, 78, 7.0, 0.4, 340, 16, 2.5, 0, 0.0, 7, 23, 4.5, 210, 27.0, 0.03),

('ruths_chris_lamb_chops', 'Ruth''s Chris Lamb Chops', 250, 22.0, 0.0, 18.0,
 0.0, 0.0, 280, NULL,
 'ruths_chris', ARRAY['ruths chris lamb', 'ruths chris rack of lamb'],
 'steakhouse', 'Ruth''s Chris', 1, '~700 cal per 280g double-cut lamb chops.', TRUE,
 75, 85, 7.5, 0.3, 290, 18, 2.0, 0, 0.0, 3, 22, 4.5, 180, 18.0, 0.08),

('ruths_chris_stuffed_chicken', 'Ruth''s Chris Stuffed Chicken Breast', 190, 22.0, 4.0, 10.0,
 0.5, 1.0, 300, NULL,
 'ruths_chris', ARRAY['ruths chris chicken', 'ruths chris stuffed chicken'],
 'steakhouse', 'Ruth''s Chris', 1, '~570 cal per 300g serving. Garlic-herb stuffed chicken breast.', TRUE,
 480, 90, 4.0, 0.1, 280, 60, 1.0, 30, 1.0, 5, 28, 1.2, 220, 25.0, 0.03),

('ruths_chris_lobster_tail', 'Ruth''s Chris Lobster Tail', 110, 21.0, 1.0, 2.5,
 0.0, 0.0, 200, NULL,
 'ruths_chris', ARRAY['ruths chris lobster', 'ruths chris lobster tail'],
 'seafood', 'Ruth''s Chris', 1, '~220 cal per 200g lobster tail. Served with drawn butter.', TRUE,
 420, 145, 0.5, 0.0, 220, 60, 0.4, 5, 0.0, 0, 35, 3.5, 220, 40.0, 0.10),

('ruths_chris_crab_cake', 'Ruth''s Chris Crab Cake', 180, 14.0, 8.0, 10.0,
 0.5, 1.0, 150, NULL,
 'ruths_chris', ARRAY['ruths chris crab cake', 'ruths chris crab cakes'],
 'seafood', 'Ruth''s Chris', 1, '~270 cal per 150g crab cake.', TRUE,
 550, 90, 2.5, 0.1, 200, 50, 1.0, 10, 3.0, 5, 30, 3.0, 180, 25.0, 0.15),

('ruths_chris_sizzling_crab', 'Ruth''s Chris Sizzling Crab', 120, 16.0, 3.0, 5.0,
 0.0, 0.5, 250, NULL,
 'ruths_chris', ARRAY['ruths chris sizzling blue crab'],
 'seafood', 'Ruth''s Chris', 1, '~300 cal per 250g serving. Jumbo lump crab in seasoned butter.', TRUE,
 500, 100, 2.5, 0.0, 250, 55, 0.8, 8, 2.0, 3, 32, 4.0, 200, 30.0, 0.12),

('ruths_chris_caesar', 'Ruth''s Chris Caesar Salad', 115, 5.0, 6.0, 8.5,
 1.5, 1.0, 250, NULL,
 'ruths_chris', ARRAY['ruths chris caesar salad'],
 'salad', 'Ruth''s Chris', 1, '~288 cal per 250g salad.', TRUE,
 450, 15, 2.0, 0.0, 200, 80, 1.0, 80, 12.0, 2, 12, 0.5, 60, 4.0, 0.03),

('ruths_chris_creamed_spinach', 'Ruth''s Chris Creamed Spinach', 130, 4.5, 5.5, 10.0,
 1.5, 1.5, 180, NULL,
 'ruths_chris', ARRAY['ruths chris spinach', 'ruths chris creamed spinach side'],
 'sides', 'Ruth''s Chris', 1, '~234 cal per 180g side.', TRUE,
 400, 25, 6.0, 0.1, 350, 120, 2.0, 350, 15.0, 5, 50, 0.6, 60, 3.0, 0.05),

('ruths_chris_lobster_mac', 'Ruth''s Chris Lobster Mac & Cheese', 210, 10.0, 16.0, 12.0,
 0.5, 2.0, 280, NULL,
 'ruths_chris', ARRAY['ruths chris lobster mac cheese', 'ruths chris mac and cheese'],
 'sides', 'Ruth''s Chris', 1, '~588 cal per 280g side. Cavatappi with lobster and three cheeses.', TRUE,
 550, 50, 7.0, 0.1, 140, 200, 0.8, 55, 0.0, 5, 18, 1.5, 180, 12.0, 0.08),

('ruths_chris_sweet_potato', 'Ruth''s Chris Sweet Potato Casserole', 175, 2.0, 28.0, 7.0,
 2.5, 15.0, 200, NULL,
 'ruths_chris', ARRAY['ruths chris sweet potato', 'ruths chris sweet potato side'],
 'sides', 'Ruth''s Chris', 1, '~350 cal per 200g side. Topped with brown sugar and pecans.', TRUE,
 120, 10, 3.0, 0.0, 350, 30, 0.6, 400, 5.0, 0, 22, 0.3, 50, 1.0, 0.03),

('ruths_chris_asparagus', 'Ruth''s Chris Grilled Asparagus', 60, 3.0, 4.0, 4.0,
 2.0, 1.5, 180, NULL,
 'ruths_chris', ARRAY['ruths chris asparagus'],
 'sides', 'Ruth''s Chris', 1, '~108 cal per 180g side. Grilled with olive oil and lemon.', TRUE,
 180, 0, 0.5, 0.0, 250, 25, 2.0, 40, 8.0, 0, 14, 0.5, 55, 3.0, 0.04),

('ruths_chris_cheesecake', 'Ruth''s Chris Cheesecake', 320, 5.5, 28.0, 21.0,
 0.0, 22.0, 170, NULL,
 'ruths_chris', ARRAY['ruths chris cheesecake dessert'],
 'dessert', 'Ruth''s Chris', 1, '~544 cal per 170g slice.', TRUE,
 250, 100, 12.0, 0.1, 100, 50, 0.5, 120, 1.0, 10, 10, 0.5, 80, 5.0, 0.02),

('ruths_chris_chocolate_sin', 'Ruth''s Chris Chocolate Sin Cake', 390, 5.0, 48.0, 22.0,
 2.0, 38.0, 180, NULL,
 'ruths_chris', ARRAY['ruths chris chocolate cake', 'ruths chris sin cake'],
 'dessert', 'Ruth''s Chris', 1, '~702 cal per 180g slice.', TRUE,
 180, 55, 12.0, 0.1, 200, 40, 3.0, 25, 0.0, 3, 35, 1.0, 80, 5.0, 0.02),

('ruths_chris_bread_pudding', 'Ruth''s Chris Bread Pudding', 310, 5.0, 40.0, 15.0,
 0.5, 25.0, 200, NULL,
 'ruths_chris', ARRAY['ruths chris bread pudding dessert'],
 'dessert', 'Ruth''s Chris', 1, '~620 cal per 200g serving. With whiskey sauce.', TRUE,
 250, 80, 8.0, 0.1, 130, 60, 1.0, 60, 0.5, 8, 12, 0.5, 70, 8.0, 0.02),

('ruths_chris_mushroom_bisque', 'Ruth''s Chris Mushroom Bisque', 95, 3.0, 6.0, 7.0,
 0.5, 1.5, 250, NULL,
 'ruths_chris', ARRAY['ruths chris mushroom soup', 'ruths chris bisque'],
 'sides', 'Ruth''s Chris', 1, '~238 cal per 250g bowl.', TRUE,
 480, 20, 4.0, 0.1, 280, 40, 0.8, 25, 1.0, 3, 12, 0.5, 80, 8.0, 0.02)
,
-- ============================================================================
-- MORTON'S THE STEAKHOUSE
-- ============================================================================

('mortons_center_cut_filet', 'Morton''s Center-Cut Filet Mignon', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 230, NULL,
 'mortons', ARRAY['mortons filet', 'mortons filet mignon', 'mortons center cut filet'],
 'steakhouse', 'Morton''s', 1, '~518 cal per 8oz (230g) center-cut filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('mortons_double_cut_filet', 'Morton''s Double-Cut Filet Mignon', 230, 28.0, 0.0, 13.0,
 0.0, 0.0, 450, NULL,
 'mortons', ARRAY['mortons double filet', 'mortons 16oz filet'],
 'steakhouse', 'Morton''s', 1, '~1035 cal per 16oz (450g) double-cut filet.', TRUE,
 58, 82, 5.5, 0.3, 360, 16, 3.5, 0, 0.0, 7, 27, 4.0, 235, 33.0, 0.03),

('mortons_prime_ny_strip', 'Morton''s Prime NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 400, NULL,
 'mortons', ARRAY['mortons ny strip', 'mortons new york strip'],
 'steakhouse', 'Morton''s', 1, '~1020 cal per 14oz (400g) prime NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('mortons_porterhouse', 'Morton''s Porterhouse', 260, 25.0, 0.0, 17.0,
 0.0, 0.0, 680, NULL,
 'mortons', ARRAY['mortons porterhouse steak'],
 'steakhouse', 'Morton''s', 1, '~1768 cal per 24oz (680g) porterhouse.', TRUE,
 60, 80, 7.5, 0.4, 340, 16, 2.5, 0, 0.0, 7, 23, 4.5, 210, 27.0, 0.03),

('mortons_prime_pork_chop', 'Morton''s Double-Cut Prime Pork Chop', 215, 24.0, 0.0, 13.0,
 0.0, 0.0, 400, NULL,
 'mortons', ARRAY['mortons pork chop', 'mortons double cut pork'],
 'steakhouse', 'Morton''s', 1, '~860 cal per 14oz (400g) double-cut pork chop.', TRUE,
 65, 75, 5.0, 0.0, 360, 19, 0.8, 2, 0.6, 11, 25, 2.0, 220, 33.0, 0.01),

('mortons_crab_cake', 'Morton''s Jumbo Lump Crab Cake', 175, 14.0, 8.0, 9.5,
 0.5, 1.0, 180, NULL,
 'mortons', ARRAY['mortons crab cake', 'mortons crab cakes'],
 'seafood', 'Morton''s', 1, '~315 cal per 180g crab cake.', TRUE,
 540, 90, 2.5, 0.1, 200, 50, 1.0, 10, 3.0, 5, 30, 3.0, 180, 25.0, 0.15),

('mortons_shrimp_alexander', 'Morton''s Colossal Shrimp Alexander', 160, 15.0, 6.0, 8.5,
 0.3, 1.0, 250, NULL,
 'mortons', ARRAY['mortons shrimp alexander', 'mortons shrimp'],
 'seafood', 'Morton''s', 1, '~400 cal per 250g. Baked shrimp with crab meat stuffing.', TRUE,
 580, 120, 3.5, 0.1, 200, 55, 0.8, 15, 2.0, 5, 30, 2.5, 200, 30.0, 0.12),

('mortons_lobster', 'Morton''s Whole Lobster', 100, 19.0, 1.0, 2.0,
 0.0, 0.0, 600, NULL,
 'mortons', ARRAY['mortons lobster', 'mortons whole lobster'],
 'seafood', 'Morton''s', 1, '~600 cal per whole lobster (600g). With drawn butter.', TRUE,
 400, 140, 0.5, 0.0, 220, 55, 0.4, 5, 0.0, 0, 35, 3.2, 210, 38.0, 0.10),

('mortons_creamed_spinach', 'Morton''s Creamed Spinach', 135, 4.5, 5.5, 10.5,
 1.5, 1.5, 200, NULL,
 'mortons', ARRAY['mortons spinach', 'mortons creamed spinach side'],
 'sides', 'Morton''s', 1, '~270 cal per 200g side.', TRUE,
 420, 28, 6.5, 0.1, 360, 130, 2.2, 360, 16.0, 5, 52, 0.6, 65, 3.0, 0.05),

('mortons_hash_browns', 'Morton''s Hash Browns', 180, 3.0, 22.0, 9.5,
 2.0, 0.5, 200, NULL,
 'mortons', ARRAY['mortons hash browns', 'mortons potatoes'],
 'sides', 'Morton''s', 1, '~360 cal per 200g side.', TRUE,
 350, 5, 2.0, 0.1, 450, 10, 0.6, 0, 8.0, 0, 22, 0.3, 55, 2.0, 0.01),

('mortons_caesar', 'Morton''s Caesar Salad', 120, 5.5, 6.0, 8.5,
 1.5, 1.0, 250, NULL,
 'mortons', ARRAY['mortons caesar salad'],
 'salad', 'Morton''s', 1, '~300 cal per 250g salad.', TRUE,
 460, 18, 2.2, 0.0, 200, 85, 1.0, 80, 12.0, 2, 12, 0.5, 60, 4.0, 0.03),

('mortons_cheesecake', 'Morton''s Cheesecake', 325, 5.5, 28.0, 22.0,
 0.0, 22.0, 180, NULL,
 'mortons', ARRAY['mortons cheesecake dessert', 'mortons new york cheesecake'],
 'dessert', 'Morton''s', 1, '~585 cal per 180g slice.', TRUE,
 260, 105, 13.0, 0.1, 105, 55, 0.5, 125, 1.0, 10, 10, 0.5, 85, 5.0, 0.02),

('mortons_hot_choc_cake', 'Morton''s Hot Chocolate Cake', 380, 5.0, 46.0, 21.0,
 2.0, 35.0, 200, NULL,
 'mortons', ARRAY['mortons chocolate cake', 'mortons lava cake'],
 'dessert', 'Morton''s', 1, '~760 cal per 200g serving.', TRUE,
 190, 60, 12.0, 0.1, 210, 45, 3.0, 30, 0.0, 3, 38, 1.0, 85, 5.0, 0.02),

-- ============================================================================
-- CAPITAL GRILLE
-- ============================================================================

('capital_grille_dry_aged_strip', 'Capital Grille Dry-Aged NY Strip', 260, 26.0, 0.0, 17.0,
 0.0, 0.0, 400, NULL,
 'capital_grille', ARRAY['capital grille ny strip', 'capital grille strip steak'],
 'steakhouse', 'Capital Grille', 1, '~1040 cal per 14oz (400g). 18-day dry-aged.', TRUE,
 60, 80, 7.0, 0.3, 340, 17, 2.8, 0, 0.0, 7, 24, 5.0, 215, 29.0, 0.03),

('capital_grille_dry_aged_sirloin', 'Capital Grille Dry-Aged Sirloin', 230, 27.0, 0.0, 13.0,
 0.0, 0.0, 400, NULL,
 'capital_grille', ARRAY['capital grille sirloin', 'capital grille dry aged sirloin'],
 'steakhouse', 'Capital Grille', 1, '~920 cal per 14oz (400g).', TRUE,
 58, 76, 5.5, 0.3, 345, 19, 3.0, 0, 0.0, 7, 25, 4.6, 218, 30.0, 0.03),

('capital_grille_filet', 'Capital Grille Filet Mignon', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 310, NULL,
 'capital_grille', ARRAY['capital grille filet mignon'],
 'steakhouse', 'Capital Grille', 1, '~698 cal per 11oz (310g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('capital_grille_kona_ribeye', 'Capital Grille Bone-In Kona Coffee Ribeye', 280, 24.0, 2.0, 20.0,
 0.0, 1.0, 510, NULL,
 'capital_grille', ARRAY['capital grille kona ribeye', 'capital grille ribeye'],
 'steakhouse', 'Capital Grille', 1, '~1428 cal per 18oz (510g). Kona-coffee crusted.', TRUE,
 68, 88, 9.0, 0.5, 315, 14, 2.3, 0, 0.0, 7, 23, 5.5, 205, 25.0, 0.03),

('capital_grille_lobster_mac', 'Capital Grille Lobster Mac & Cheese', 205, 10.0, 16.0, 11.5,
 0.5, 2.0, 280, NULL,
 'capital_grille', ARRAY['capital grille mac cheese', 'capital grille lobster mac'],
 'sides', 'Capital Grille', 1, '~574 cal per 280g side.', TRUE,
 540, 48, 6.5, 0.1, 135, 190, 0.8, 50, 0.0, 5, 16, 1.4, 175, 10.0, 0.07),

('capital_grille_calamari', 'Capital Grille Pan-Fried Calamari', 200, 12.0, 14.0, 10.0,
 0.5, 1.0, 200, NULL,
 'capital_grille', ARRAY['capital grille calamari', 'capital grille fried calamari'],
 'seafood', 'Capital Grille', 1, '~400 cal per 200g serving. With hot cherry peppers.', TRUE,
 520, 150, 2.0, 0.1, 180, 25, 1.5, 5, 5.0, 3, 25, 1.2, 140, 28.0, 0.08),

('capital_grille_crab_cakes', 'Capital Grille Lobster and Crab Cakes', 185, 14.0, 8.0, 10.5,
 0.5, 1.0, 200, NULL,
 'capital_grille', ARRAY['capital grille crab cake', 'capital grille lobster crab cake'],
 'seafood', 'Capital Grille', 1, '~370 cal per 200g serving.', TRUE,
 560, 95, 2.8, 0.1, 210, 55, 1.0, 12, 3.0, 5, 32, 3.2, 190, 28.0, 0.14),

('capital_grille_creamed_corn', 'Capital Grille Creamed Corn', 120, 3.0, 16.0, 5.5,
 1.5, 5.0, 200, NULL,
 'capital_grille', ARRAY['capital grille corn', 'capital grille creamed corn side'],
 'sides', 'Capital Grille', 1, '~240 cal per 200g side.', TRUE,
 280, 15, 3.0, 0.0, 250, 10, 0.5, 10, 5.0, 0, 28, 0.4, 65, 1.0, 0.02),

('capital_grille_roasted_mushrooms', 'Capital Grille Roasted Mushrooms', 65, 4.0, 5.0, 4.0,
 1.5, 1.5, 200, NULL,
 'capital_grille', ARRAY['capital grille mushrooms', 'capital grille roasted mushrooms side'],
 'sides', 'Capital Grille', 1, '~130 cal per 200g side.', TRUE,
 350, 0, 0.8, 0.0, 380, 5, 0.5, 0, 2.0, 8, 12, 0.8, 100, 12.0, 0.01),

('capital_grille_au_gratin', 'Capital Grille Au Gratin Potatoes', 150, 5.0, 14.0, 8.5,
 1.0, 1.5, 200, NULL,
 'capital_grille', ARRAY['capital grille potatoes', 'capital grille au gratin'],
 'sides', 'Capital Grille', 1, '~300 cal per 200g side. Sliced potatoes with gruyere.', TRUE,
 420, 25, 5.0, 0.1, 350, 120, 0.5, 40, 5.0, 3, 18, 0.6, 100, 3.0, 0.02),

('capital_grille_cheesecake', 'Capital Grille Cheesecake', 330, 5.5, 30.0, 22.0,
 0.0, 24.0, 170, NULL,
 'capital_grille', ARRAY['capital grille cheesecake dessert'],
 'dessert', 'Capital Grille', 1, '~561 cal per 170g slice.', TRUE,
 260, 105, 13.0, 0.1, 105, 55, 0.5, 125, 1.0, 10, 10, 0.5, 85, 5.0, 0.02),

('capital_grille_choc_espresso', 'Capital Grille Flourless Chocolate Espresso Cake', 370, 5.0, 40.0, 22.0,
 3.0, 32.0, 160, NULL,
 'capital_grille', ARRAY['capital grille chocolate cake', 'capital grille espresso cake'],
 'dessert', 'Capital Grille', 1, '~592 cal per 160g slice.', TRUE,
 100, 80, 12.0, 0.1, 220, 30, 3.5, 30, 0.0, 5, 50, 1.2, 100, 5.0, 0.02)
,
-- ============================================================================
-- FLEMING'S PRIME STEAKHOUSE
-- ============================================================================

('flemings_filet', 'Fleming''s Filet Mignon', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 280, NULL,
 'flemings', ARRAY['flemings filet mignon', 'flemings filet'],
 'steakhouse', 'Fleming''s', 1, '~630 cal per 10oz (280g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('flemings_ny_strip', 'Fleming''s Prime NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 400, NULL,
 'flemings', ARRAY['flemings ny strip', 'flemings new york strip'],
 'steakhouse', 'Fleming''s', 1, '~1020 cal per 14oz (400g) prime NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('flemings_ribeye', 'Fleming''s Prime Ribeye', 275, 25.0, 0.0, 19.0,
 0.0, 0.0, 400, NULL,
 'flemings', ARRAY['flemings ribeye', 'flemings prime ribeye'],
 'steakhouse', 'Fleming''s', 1, '~1100 cal per 14oz (400g) prime ribeye.', TRUE,
 65, 85, 8.5, 0.5, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('flemings_pork_chop', 'Fleming''s Double Bone-In Pork Chop', 220, 24.0, 0.0, 13.5,
 0.0, 0.0, 450, NULL,
 'flemings', ARRAY['flemings pork chop', 'flemings double pork chop'],
 'steakhouse', 'Fleming''s', 1, '~990 cal per 16oz (450g) double-cut pork chop.', TRUE,
 65, 75, 5.0, 0.0, 365, 20, 0.8, 2, 0.6, 11, 26, 2.0, 225, 34.0, 0.01),

('flemings_lobster_tails', 'Fleming''s Lobster Tails', 108, 20.0, 1.0, 2.5,
 0.0, 0.0, 250, NULL,
 'flemings', ARRAY['flemings lobster tail', 'flemings lobster tails'],
 'seafood', 'Fleming''s', 1, '~270 cal per 250g twin lobster tails.', TRUE,
 420, 145, 0.5, 0.0, 220, 60, 0.4, 5, 0.0, 0, 35, 3.5, 220, 40.0, 0.10),

('flemings_shrimp_scampi', 'Fleming''s Shrimp Scampi', 145, 16.0, 4.0, 7.5,
 0.3, 0.5, 250, NULL,
 'flemings', ARRAY['flemings shrimp scampi', 'flemings shrimp'],
 'seafood', 'Fleming''s', 1, '~363 cal per 250g serving. Shrimp in garlic butter wine sauce.', TRUE,
 520, 170, 3.5, 0.0, 200, 55, 0.5, 10, 3.0, 5, 35, 1.5, 200, 35.0, 0.12),

('flemings_potatoes', 'Fleming''s Potatoes', 155, 4.0, 16.0, 8.5,
 1.5, 1.0, 200, NULL,
 'flemings', ARRAY['flemings potatoes', 'flemings potato side'],
 'sides', 'Fleming''s', 1, '~310 cal per 200g side. Signature whipped potatoes.', TRUE,
 380, 20, 5.0, 0.1, 400, 30, 0.5, 30, 8.0, 3, 20, 0.4, 60, 2.0, 0.01),

('flemings_truffle_fries', 'Fleming''s Truffle Fries', 290, 4.0, 32.0, 17.0,
 3.0, 0.5, 200, NULL,
 'flemings', ARRAY['flemings truffle fries', 'flemings fries'],
 'sides', 'Fleming''s', 1, '~580 cal per 200g side. With parmesan and truffle oil.', TRUE,
 420, 5, 3.5, 0.1, 480, 40, 0.7, 0, 6.0, 0, 22, 0.4, 70, 2.0, 0.01),

('flemings_asparagus', 'Fleming''s Grilled Asparagus', 60, 3.0, 4.0, 4.0,
 2.0, 1.5, 180, NULL,
 'flemings', ARRAY['flemings asparagus'],
 'sides', 'Fleming''s', 1, '~108 cal per 180g side.', TRUE,
 180, 0, 0.5, 0.0, 250, 25, 2.0, 40, 8.0, 0, 14, 0.5, 55, 3.0, 0.04),

('flemings_creme_brulee', 'Fleming''s Crème Brûlée', 280, 4.0, 28.0, 17.0,
 0.0, 24.0, 150, NULL,
 'flemings', ARRAY['flemings creme brulee', 'flemings dessert'],
 'dessert', 'Fleming''s', 1, '~420 cal per 150g serving.', TRUE,
 60, 180, 10.0, 0.1, 100, 80, 0.5, 120, 0.0, 20, 8, 0.5, 100, 5.0, 0.02),

('flemings_choc_gooey', 'Fleming''s Chocolate Gooey Butter Cake', 400, 4.5, 50.0, 22.0,
 1.0, 35.0, 180, NULL,
 'flemings', ARRAY['flemings chocolate cake', 'flemings gooey butter cake'],
 'dessert', 'Fleming''s', 1, '~720 cal per 180g slice.', TRUE,
 250, 70, 12.0, 0.2, 150, 35, 2.0, 40, 0.0, 5, 25, 0.8, 70, 5.0, 0.02),

('flemings_ny_strip_salad', 'Fleming''s Prime NY Strip Salad', 155, 14.0, 5.0, 9.0,
 1.5, 2.0, 350, NULL,
 'flemings', ARRAY['flemings steak salad'],
 'salad', 'Fleming''s', 1, '~543 cal per 350g serving. Sliced steak over mixed greens.', TRUE,
 380, 50, 3.5, 0.2, 380, 40, 2.0, 50, 8.0, 5, 22, 3.5, 170, 20.0, 0.04),

-- ============================================================================
-- MASTRO'S
-- ============================================================================

('mastros_bone_in_ribeye', 'Mastro''s Bone-In Ribeye', 275, 24.0, 0.0, 20.0,
 0.0, 0.0, 510, NULL,
 'mastros', ARRAY['mastros ribeye', 'mastros bone in ribeye'],
 'steakhouse', 'Mastro''s', 1, '~1403 cal per 18oz (510g) bone-in ribeye.', TRUE,
 65, 85, 8.5, 0.5, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('mastros_filet', 'Mastro''s Filet Mignon', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 280, NULL,
 'mastros', ARRAY['mastros filet', 'mastros filet mignon'],
 'steakhouse', 'Mastro''s', 1, '~630 cal per 10oz (280g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('mastros_ny_strip', 'Mastro''s NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 400, NULL,
 'mastros', ARRAY['mastros strip steak', 'mastros ny strip'],
 'steakhouse', 'Mastro''s', 1, '~1020 cal per 14oz (400g) NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('mastros_seafood_tower', 'Mastro''s Seafood Tower', 95, 16.0, 3.0, 2.0,
 0.0, 0.5, 500, NULL,
 'mastros', ARRAY['mastros seafood tower', 'mastros shellfish tower'],
 'seafood', 'Mastro''s', 1, '~475 cal per 500g tower. Lobster, shrimp, crab, oysters.', TRUE,
 480, 120, 0.5, 0.0, 250, 55, 0.8, 15, 5.0, 5, 35, 4.0, 220, 35.0, 0.20),

('mastros_warm_butter_cake', 'Mastro''s Warm Butter Cake', 400, 4.0, 48.0, 22.0,
 0.5, 35.0, 200, NULL,
 'mastros', ARRAY['mastros butter cake', 'mastros dessert', 'mastros warm cake'],
 'dessert', 'Mastro''s', 1, '~800 cal per 200g. Signature warm butter cake.', TRUE,
 280, 100, 13.0, 0.2, 80, 40, 1.0, 100, 0.0, 10, 8, 0.4, 60, 5.0, 0.02),

('mastros_lobster_mashed', 'Mastro''s Lobster Mashed Potatoes', 155, 6.0, 14.0, 9.0,
 1.0, 1.0, 250, NULL,
 'mastros', ARRAY['mastros mashed potatoes', 'mastros lobster mash'],
 'sides', 'Mastro''s', 1, '~388 cal per 250g side.', TRUE,
 420, 35, 5.5, 0.1, 380, 35, 0.5, 30, 6.0, 5, 20, 0.5, 80, 5.0, 0.05),

('mastros_gorgonzola_mac', 'Mastro''s Gorgonzola Mac & Cheese', 215, 9.0, 17.0, 12.5,
 0.5, 2.0, 280, NULL,
 'mastros', ARRAY['mastros mac cheese', 'mastros gorgonzola mac cheese'],
 'sides', 'Mastro''s', 1, '~602 cal per 280g side.', TRUE,
 580, 40, 7.5, 0.1, 120, 200, 0.8, 55, 0.0, 3, 15, 1.3, 170, 8.0, 0.02),

('mastros_creamed_corn', 'Mastro''s Creamed Corn', 125, 3.0, 16.0, 6.0,
 1.5, 5.5, 200, NULL,
 'mastros', ARRAY['mastros corn', 'mastros creamed corn side'],
 'sides', 'Mastro''s', 1, '~250 cal per 200g side.', TRUE,
 300, 18, 3.5, 0.0, 260, 12, 0.5, 12, 5.0, 0, 28, 0.4, 65, 1.0, 0.02),

('mastros_shrimp_cocktail', 'Mastro''s Shrimp Cocktail', 85, 17.0, 2.0, 0.8,
 0.0, 1.0, 200, NULL,
 'mastros', ARRAY['mastros shrimp cocktail'],
 'seafood', 'Mastro''s', 1, '~170 cal per 200g serving.', TRUE,
 480, 150, 0.2, 0.0, 180, 50, 0.5, 5, 3.0, 5, 35, 1.5, 200, 35.0, 0.10)
,
-- ============================================================================
-- STK
-- ============================================================================

('stk_small_steak', 'STK Small Steak (Filet)', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 170, NULL,
 'stk', ARRAY['stk small steak', 'stk filet', 'stk 6oz steak'],
 'steakhouse', 'STK', 1, '~383 cal per 6oz (170g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('stk_medium_steak', 'STK Medium Steak (NY Strip)', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 340, NULL,
 'stk', ARRAY['stk medium steak', 'stk ny strip'],
 'steakhouse', 'STK', 1, '~867 cal per 12oz (340g) NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('stk_large_steak', 'STK Large Steak (Ribeye)', 275, 25.0, 0.0, 19.0,
 0.0, 0.0, 450, NULL,
 'stk', ARRAY['stk large steak', 'stk ribeye'],
 'steakhouse', 'STK', 1, '~1238 cal per 16oz (450g) ribeye.', TRUE,
 65, 85, 8.5, 0.5, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('stk_lil_brgs', 'STK Lil'' BRGs', 260, 14.0, 18.0, 15.0,
 1.0, 4.0, 200, NULL,
 'stk', ARRAY['stk lil brgs', 'stk sliders', 'stk mini burgers'],
 'steakhouse', 'STK', 1, '~520 cal per 200g (2 sliders). Wagyu beef sliders.', TRUE,
 480, 60, 6.0, 0.3, 250, 70, 2.2, 8, 1.0, 5, 18, 3.5, 150, 16.0, 0.03),

('stk_truffle_fries', 'STK Truffle Fries', 295, 4.0, 33.0, 17.0,
 3.0, 0.5, 200, NULL,
 'stk', ARRAY['stk truffle fries', 'stk fries'],
 'sides', 'STK', 1, '~590 cal per 200g side.', TRUE,
 420, 5, 3.5, 0.1, 480, 40, 0.7, 0, 6.0, 0, 22, 0.4, 70, 2.0, 0.01),

('stk_tuna_tartare', 'STK Tuna Tartare', 110, 16.0, 4.0, 3.5,
 0.5, 1.5, 180, NULL,
 'stk', ARRAY['stk tuna tartare', 'stk tuna'],
 'seafood', 'STK', 1, '~198 cal per 180g serving.', TRUE,
 380, 30, 0.5, 0.0, 350, 8, 0.8, 50, 2.0, 80, 30, 0.4, 180, 48.0, 0.30),

('stk_crispy_rock_shrimp', 'STK Crispy Rock Shrimp', 215, 12.0, 16.0, 11.5,
 0.5, 3.0, 200, NULL,
 'stk', ARRAY['stk rock shrimp', 'stk crispy shrimp'],
 'seafood', 'STK', 1, '~430 cal per 200g serving.', TRUE,
 520, 80, 2.0, 0.1, 180, 30, 1.0, 10, 2.0, 5, 25, 1.0, 150, 20.0, 0.08),

('stk_king_crab', 'STK King Crab', 95, 18.0, 1.0, 1.5,
 0.0, 0.0, 350, NULL,
 'stk', ARRAY['stk king crab', 'stk crab legs'],
 'seafood', 'STK', 1, '~333 cal per 350g serving.', TRUE,
 900, 50, 0.3, 0.0, 250, 50, 0.6, 5, 5.0, 0, 55, 5.0, 250, 35.0, 0.35),

('stk_salad', 'STK Salad', 80, 3.0, 6.0, 5.5,
 2.0, 3.0, 250, NULL,
 'stk', ARRAY['stk house salad'],
 'salad', 'STK', 1, '~200 cal per 250g salad.', TRUE,
 280, 5, 1.0, 0.0, 350, 40, 1.0, 100, 15.0, 0, 18, 0.3, 40, 2.0, 0.05),

('stk_cotton_candy', 'STK Cotton Candy', 380, 0.0, 95.0, 0.0,
 0.0, 95.0, 50, NULL,
 'stk', ARRAY['stk cotton candy dessert'],
 'dessert', 'STK', 1, '~190 cal per 50g serving. Signature cotton candy dessert.', TRUE,
 5, 0, 0.0, 0.0, 2, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0.0, 0.0),

-- ============================================================================
-- OCEAN PRIME
-- ============================================================================

('ocean_prime_shellfish', 'Ocean Prime Shellfish Platter', 90, 16.0, 3.0, 1.5,
 0.0, 0.5, 500, NULL,
 'ocean_prime', ARRAY['ocean prime shellfish platter', 'ocean prime seafood tower'],
 'seafood', 'Ocean Prime', 1, '~450 cal per 500g platter. Lobster, shrimp, crab, oysters.', TRUE,
 480, 120, 0.4, 0.0, 250, 55, 0.8, 15, 5.0, 5, 35, 4.0, 220, 35.0, 0.20),

('ocean_prime_sea_bass', 'Ocean Prime Chilean Sea Bass', 185, 18.0, 3.0, 11.0,
 0.0, 1.5, 250, NULL,
 'ocean_prime', ARRAY['ocean prime sea bass', 'ocean prime chilean sea bass'],
 'seafood', 'Ocean Prime', 1, '~463 cal per 250g serving. Miso-glazed Chilean sea bass.', TRUE,
 420, 55, 2.5, 0.0, 350, 15, 0.6, 30, 0.0, 200, 30, 0.5, 200, 35.0, 1.20),

('ocean_prime_filet', 'Ocean Prime Filet Mignon', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 280, NULL,
 'ocean_prime', ARRAY['ocean prime filet', 'ocean prime steak'],
 'steakhouse', 'Ocean Prime', 1, '~630 cal per 10oz (280g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('ocean_prime_ny_strip', 'Ocean Prime Prime NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 400, NULL,
 'ocean_prime', ARRAY['ocean prime ny strip', 'ocean prime strip steak'],
 'steakhouse', 'Ocean Prime', 1, '~1020 cal per 14oz (400g) NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('ocean_prime_lobster_tail', 'Ocean Prime Lobster Tail', 108, 20.0, 1.0, 2.5,
 0.0, 0.0, 200, NULL,
 'ocean_prime', ARRAY['ocean prime lobster', 'ocean prime lobster tail'],
 'seafood', 'Ocean Prime', 1, '~216 cal per 200g lobster tail.', TRUE,
 420, 145, 0.5, 0.0, 220, 60, 0.4, 5, 0.0, 0, 35, 3.5, 220, 40.0, 0.10),

('ocean_prime_crab_cake', 'Ocean Prime Crab Cake', 180, 14.0, 8.0, 10.0,
 0.5, 1.0, 180, NULL,
 'ocean_prime', ARRAY['ocean prime crab cake'],
 'seafood', 'Ocean Prime', 1, '~324 cal per 180g crab cake.', TRUE,
 540, 90, 2.5, 0.1, 200, 50, 1.0, 10, 3.0, 5, 30, 3.0, 180, 25.0, 0.15),

('ocean_prime_key_lime', 'Ocean Prime Key Lime Pie', 310, 4.0, 38.0, 16.0,
 0.5, 28.0, 170, NULL,
 'ocean_prime', ARRAY['ocean prime key lime pie', 'ocean prime dessert'],
 'dessert', 'Ocean Prime', 1, '~527 cal per 170g slice.', TRUE,
 200, 60, 8.0, 0.1, 120, 60, 0.5, 40, 8.0, 5, 10, 0.4, 60, 3.0, 0.02),

('ocean_prime_carrot_cake', 'Ocean Prime Carrot Cake', 350, 4.0, 42.0, 19.0,
 1.0, 30.0, 200, NULL,
 'ocean_prime', ARRAY['ocean prime carrot cake'],
 'dessert', 'Ocean Prime', 1, '~700 cal per 200g slice.', TRUE,
 280, 50, 5.0, 0.1, 180, 40, 1.0, 300, 1.0, 5, 15, 0.5, 60, 4.0, 0.03)
,
-- ============================================================================
-- SMITH & WOLLENSKY
-- ============================================================================

('sw_prime_sirloin', 'Smith & Wollensky USDA Prime Sirloin', 235, 27.0, 0.0, 14.0,
 0.0, 0.0, 400, NULL,
 'smith_wollensky', ARRAY['smith wollensky sirloin', 'smith and wollensky sirloin'],
 'steakhouse', 'Smith & Wollensky', 1, '~940 cal per 14oz (400g) USDA prime sirloin.', TRUE,
 58, 76, 5.5, 0.3, 345, 19, 3.0, 0, 0.0, 7, 25, 4.6, 218, 30.0, 0.03),

('sw_filet', 'Smith & Wollensky Filet', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 280, NULL,
 'smith_wollensky', ARRAY['smith wollensky filet', 'smith and wollensky filet mignon'],
 'steakhouse', 'Smith & Wollensky', 1, '~630 cal per 10oz (280g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('sw_ny_strip', 'Smith & Wollensky NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 400, NULL,
 'smith_wollensky', ARRAY['smith wollensky strip', 'smith and wollensky ny strip'],
 'steakhouse', 'Smith & Wollensky', 1, '~1020 cal per 14oz (400g) NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('sw_lamb_chops', 'Smith & Wollensky Colorado Lamb Rib Chops', 250, 22.0, 0.0, 18.0,
 0.0, 0.0, 280, NULL,
 'smith_wollensky', ARRAY['smith wollensky lamb', 'smith and wollensky lamb chops'],
 'steakhouse', 'Smith & Wollensky', 1, '~700 cal per 280g lamb rib chops.', TRUE,
 75, 85, 7.5, 0.3, 290, 18, 2.0, 0, 0.0, 3, 22, 4.5, 180, 18.0, 0.08),

('sw_lobster_cocktail', 'Smith & Wollensky Lobster Cocktail', 90, 18.0, 2.0, 1.0,
 0.0, 1.0, 200, NULL,
 'smith_wollensky', ARRAY['smith wollensky lobster cocktail'],
 'seafood', 'Smith & Wollensky', 1, '~180 cal per 200g serving.', TRUE,
 450, 140, 0.3, 0.0, 220, 55, 0.4, 5, 3.0, 0, 35, 3.2, 210, 38.0, 0.10),

('sw_caesar', 'Smith & Wollensky Caesar Salad', 115, 5.0, 6.0, 8.5,
 1.5, 1.0, 250, NULL,
 'smith_wollensky', ARRAY['smith wollensky caesar'],
 'salad', 'Smith & Wollensky', 1, '~288 cal per 250g salad.', TRUE,
 450, 15, 2.0, 0.0, 200, 80, 1.0, 80, 12.0, 2, 12, 0.5, 60, 4.0, 0.03),

('sw_creamed_spinach', 'Smith & Wollensky Creamed Spinach', 130, 4.5, 5.5, 10.0,
 1.5, 1.5, 200, NULL,
 'smith_wollensky', ARRAY['smith wollensky spinach'],
 'sides', 'Smith & Wollensky', 1, '~260 cal per 200g side.', TRUE,
 400, 25, 6.0, 0.1, 350, 120, 2.0, 350, 15.0, 5, 50, 0.6, 60, 3.0, 0.05),

('sw_hash_browns', 'Smith & Wollensky Hash Browns', 185, 3.0, 22.0, 10.0,
 2.0, 0.5, 200, NULL,
 'smith_wollensky', ARRAY['smith wollensky hash browns', 'smith wollensky potatoes'],
 'sides', 'Smith & Wollensky', 1, '~370 cal per 200g side.', TRUE,
 360, 5, 2.0, 0.1, 450, 10, 0.6, 0, 8.0, 0, 22, 0.3, 55, 2.0, 0.01),

-- ============================================================================
-- EDDIE V'S
-- ============================================================================

('eddie_vs_sea_bass', 'Eddie V''s Chilean Sea Bass', 185, 18.0, 3.0, 11.0,
 0.0, 1.5, 250, NULL,
 'eddie_vs', ARRAY['eddie vs sea bass', 'eddie vs chilean sea bass'],
 'seafood', 'Eddie V''s', 1, '~463 cal per 250g serving.', TRUE,
 420, 55, 2.5, 0.0, 350, 15, 0.6, 30, 0.0, 200, 30, 0.5, 200, 35.0, 1.20),

('eddie_vs_ahi_tuna', 'Eddie V''s Seared Ahi Tuna', 140, 25.0, 2.0, 3.5,
 0.0, 0.5, 250, NULL,
 'eddie_vs', ARRAY['eddie vs tuna', 'eddie vs ahi tuna'],
 'seafood', 'Eddie V''s', 1, '~350 cal per 250g serving.', TRUE,
 380, 45, 0.8, 0.0, 440, 5, 1.0, 600, 0.0, 80, 48, 0.6, 275, 88.0, 0.25),

('eddie_vs_filet', 'Eddie V''s Filet Mignon', 225, 28.0, 0.0, 12.0,
 0.0, 0.0, 280, NULL,
 'eddie_vs', ARRAY['eddie vs filet', 'eddie vs steak'],
 'steakhouse', 'Eddie V''s', 1, '~630 cal per 10oz (280g) filet.', TRUE,
 55, 80, 5.0, 0.3, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('eddie_vs_ny_strip', 'Eddie V''s NY Strip', 255, 26.0, 0.0, 16.5,
 0.0, 0.0, 400, NULL,
 'eddie_vs', ARRAY['eddie vs ny strip'],
 'steakhouse', 'Eddie V''s', 1, '~1020 cal per 14oz (400g) NY strip.', TRUE,
 58, 78, 7.0, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('eddie_vs_lobster_tail', 'Eddie V''s Lobster Tail', 108, 20.0, 1.0, 2.5,
 0.0, 0.0, 200, NULL,
 'eddie_vs', ARRAY['eddie vs lobster'],
 'seafood', 'Eddie V''s', 1, '~216 cal per 200g lobster tail.', TRUE,
 420, 145, 0.5, 0.0, 220, 60, 0.4, 5, 0.0, 0, 35, 3.5, 220, 40.0, 0.10),

('eddie_vs_crab_cake', 'Eddie V''s Crab Cake', 180, 14.0, 8.0, 10.0,
 0.5, 1.0, 180, NULL,
 'eddie_vs', ARRAY['eddie vs crab cake'],
 'seafood', 'Eddie V''s', 1, '~324 cal per 180g crab cake.', TRUE,
 540, 90, 2.5, 0.1, 200, 50, 1.0, 10, 3.0, 5, 30, 3.0, 180, 25.0, 0.15),

('eddie_vs_bananas_foster', 'Eddie V''s Bananas Foster', 250, 2.5, 38.0, 10.0,
 1.5, 28.0, 200, NULL,
 'eddie_vs', ARRAY['eddie vs bananas foster dessert'],
 'dessert', 'Eddie V''s', 1, '~500 cal per 200g serving.', TRUE,
 60, 20, 5.0, 0.1, 350, 30, 0.4, 30, 8.0, 3, 25, 0.3, 30, 2.0, 0.03),

('eddie_vs_key_lime', 'Eddie V''s Key Lime Pie', 310, 4.0, 38.0, 16.0,
 0.5, 28.0, 170, NULL,
 'eddie_vs', ARRAY['eddie vs key lime pie'],
 'dessert', 'Eddie V''s', 1, '~527 cal per 170g slice.', TRUE,
 200, 60, 8.0, 0.1, 120, 60, 0.5, 40, 8.0, 5, 10, 0.4, 60, 3.0, 0.02),

('eddie_vs_caesar', 'Eddie V''s Caesar Salad', 115, 5.0, 6.0, 8.5,
 1.5, 1.0, 250, NULL,
 'eddie_vs', ARRAY['eddie vs caesar salad'],
 'salad', 'Eddie V''s', 1, '~288 cal per 250g salad.', TRUE,
 450, 15, 2.0, 0.0, 200, 80, 1.0, 80, 12.0, 2, 12, 0.5, 60, 4.0, 0.03)
,
-- ============================================================================
-- LONGHORN STEAKHOUSE
-- ============================================================================

('longhorn_outlaw_ribeye', 'LongHorn Steakhouse Outlaw Ribeye', 220, 21.0, 0.0, 15.0,
 0.0, 0.0, 570, NULL,
 'longhorn', ARRAY['longhorn outlaw ribeye', 'longhorn ribeye', 'longhorn 20oz ribeye'],
 'steakhouse', 'LongHorn Steakhouse', 1, '~1254 cal per 20oz (570g) Outlaw Ribeye.', TRUE,
 65, 85, 6.5, 0.4, 310, 12, 2.2, 0, 0.0, 7, 22, 5.5, 200, 24.0, 0.03),

('longhorn_flos_filet', 'LongHorn Steakhouse Flo''s Filet', 215, 28.0, 0.0, 11.0,
 0.0, 0.0, 170, NULL,
 'longhorn', ARRAY['longhorn flos filet', 'longhorn filet', 'flos filet 6oz'],
 'steakhouse', 'LongHorn Steakhouse', 1, '~366 cal per 6oz (170g) filet. Bacon-wrapped.', TRUE,
 280, 85, 4.5, 0.2, 356, 15, 3.4, 0, 0.0, 7, 26, 3.9, 230, 32.0, 0.03),

('longhorn_ny_strip', 'LongHorn Steakhouse Fire-Grilled NY Strip', 250, 26.0, 0.0, 16.0,
 0.0, 0.0, 340, NULL,
 'longhorn', ARRAY['longhorn ny strip', 'longhorn new york strip'],
 'steakhouse', 'LongHorn Steakhouse', 1, '~850 cal per 12oz (340g) NY strip.', TRUE,
 58, 78, 6.5, 0.3, 335, 17, 2.7, 0, 0.0, 7, 23, 4.8, 210, 28.0, 0.03),

('longhorn_renegade_sirloin', 'LongHorn Steakhouse Renegade Sirloin', 185, 27.0, 0.0, 8.5,
 0.0, 0.0, 230, NULL,
 'longhorn', ARRAY['longhorn renegade sirloin', 'longhorn sirloin'],
 'steakhouse', 'LongHorn Steakhouse', 1, '~426 cal per 8oz (230g) top sirloin.', TRUE,
 56, 75, 3.5, 0.3, 342, 19, 2.9, 0, 0.0, 7, 24, 4.5, 215, 29.0, 0.03),

('longhorn_parm_chicken', 'LongHorn Steakhouse Parmesan Crusted Chicken', 195, 20.0, 8.0, 9.0,
 0.5, 1.0, 300, NULL,
 'longhorn', ARRAY['longhorn parmesan chicken', 'longhorn crusted chicken'],
 'american', 'LongHorn Steakhouse', 1, '~585 cal per 300g serving. Parmesan-crusted chicken breast.', TRUE,
 520, 65, 3.5, 0.1, 280, 100, 1.0, 20, 1.0, 5, 28, 1.2, 220, 24.0, 0.03),

('longhorn_salmon', 'LongHorn Steakhouse Grilled Salmon', 190, 22.0, 2.0, 10.5,
 0.0, 1.0, 230, NULL,
 'longhorn', ARRAY['longhorn salmon', 'longhorn grilled salmon'],
 'seafood', 'LongHorn Steakhouse', 1, '~437 cal per 8oz (230g) Atlantic salmon.', TRUE,
 350, 63, 2.5, 0.0, 380, 12, 0.5, 12, 0.0, 520, 30, 0.5, 260, 40.0, 1.80),

('longhorn_chili', 'LongHorn Steakhouse LongHorn Chili', 105, 8.0, 8.0, 5.0,
 2.0, 2.0, 300, NULL,
 'longhorn', ARRAY['longhorn chili', 'longhorn steakhouse chili'],
 'sides', 'LongHorn Steakhouse', 1, '~315 cal per 300g bowl.', TRUE,
 520, 30, 2.0, 0.1, 350, 40, 2.0, 30, 5.0, 3, 20, 2.5, 130, 10.0, 0.03),

('longhorn_loaded_potato', 'LongHorn Steakhouse Loaded Baked Potato', 130, 3.5, 15.0, 6.5,
 1.5, 1.0, 300, NULL,
 'longhorn', ARRAY['longhorn baked potato', 'longhorn loaded potato'],
 'sides', 'LongHorn Steakhouse', 1, '~390 cal per 300g potato. With butter, sour cream, bacon, cheese.', TRUE,
 320, 15, 4.0, 0.1, 500, 50, 0.8, 30, 10.0, 3, 28, 0.5, 70, 2.0, 0.02),

('longhorn_caesar', 'LongHorn Steakhouse Caesar Salad', 110, 5.0, 6.0, 8.0,
 1.5, 1.0, 250, NULL,
 'longhorn', ARRAY['longhorn caesar salad'],
 'salad', 'LongHorn Steakhouse', 1, '~275 cal per 250g salad.', TRUE,
 450, 15, 2.0, 0.0, 200, 80, 1.0, 80, 12.0, 2, 12, 0.5, 60, 4.0, 0.03),

('longhorn_mac_cheese', 'LongHorn Steakhouse Steakhouse Mac & Cheese', 195, 8.0, 17.0, 10.5,
 0.5, 2.0, 250, NULL,
 'longhorn', ARRAY['longhorn mac and cheese', 'longhorn mac cheese'],
 'sides', 'LongHorn Steakhouse', 1, '~488 cal per 250g side.', TRUE,
 560, 35, 6.0, 0.1, 110, 170, 0.8, 45, 0.0, 3, 14, 1.1, 150, 7.0, 0.02),

('longhorn_chocolate_stampede', 'LongHorn Steakhouse Chocolate Stampede', 370, 5.0, 46.0, 19.0,
 2.0, 35.0, 280, NULL,
 'longhorn', ARRAY['longhorn chocolate stampede', 'longhorn chocolate dessert'],
 'dessert', 'LongHorn Steakhouse', 1, '~1036 cal per 280g serving. Six-layer chocolate cake.', TRUE,
 250, 55, 10.0, 0.2, 200, 40, 3.0, 25, 0.0, 3, 35, 1.0, 80, 5.0, 0.02),

('longhorn_molten_lava', 'LongHorn Steakhouse Molten Lava Cake', 360, 5.0, 42.0, 20.0,
 1.5, 32.0, 200, NULL,
 'longhorn', ARRAY['longhorn lava cake', 'longhorn molten cake'],
 'dessert', 'LongHorn Steakhouse', 1, '~720 cal per 200g serving. Warm chocolate cake with molten center.', TRUE,
 220, 70, 11.0, 0.1, 180, 35, 2.5, 30, 0.0, 5, 30, 0.8, 70, 5.0, 0.02),

-- ============================================================================
-- RAISING CANE'S
-- ============================================================================

('raising_canes_chicken_finger', 'Raising Cane''s Chicken Finger', 236, 24.0, 9.0, 11.0,
 0.0, 0.0, 55, 55,
 'raising_canes', ARRAY['raising canes chicken finger', 'canes finger', 'raising canes tender'],
 'american', 'Raising Cane''s', 1, '~130 cal per finger (55g). Hand-battered chicken tenders.', TRUE,
 345, 55, 2.0, 0.1, 220, 15, 0.8, 5, 0.0, 3, 22, 0.8, 170, 18.0, 0.02),

('raising_canes_3_finger', 'Raising Cane''s 3 Finger Combo', 236, 24.0, 9.0, 11.0,
 0.0, 0.0, 165, NULL,
 'raising_canes', ARRAY['raising canes 3 finger combo', 'canes 3 piece'],
 'american', 'Raising Cane''s', 1, '~390 cal for 3 fingers (165g). Does not include sides.', TRUE,
 345, 55, 2.0, 0.1, 220, 15, 0.8, 5, 0.0, 3, 22, 0.8, 170, 18.0, 0.02),

('raising_canes_texas_toast', 'Raising Cane''s Texas Toast', 280, 8.0, 46.0, 8.0,
 2.0, 8.0, 50, 50,
 'raising_canes', ARRAY['raising canes texas toast', 'canes toast', 'canes bread'],
 'sides', 'Raising Cane''s', 1, '~140 cal per slice (50g). Buttered garlic Texas toast.', TRUE,
 520, 5, 2.0, 0.0, 60, 40, 1.5, 0, 0.0, 0, 10, 0.4, 40, 10.0, 0.01),

('raising_canes_coleslaw', 'Raising Cane''s Coleslaw', 120, 1.0, 13.0, 7.0,
 1.5, 10.0, 130, NULL,
 'raising_canes', ARRAY['raising canes coleslaw', 'canes slaw', 'canes cole slaw'],
 'sides', 'Raising Cane''s', 1, '~156 cal per 130g serving.', TRUE,
 200, 5, 1.0, 0.0, 150, 25, 0.3, 10, 15.0, 0, 8, 0.2, 20, 1.0, 0.03),

('raising_canes_fries', 'Raising Cane''s Crinkle-Cut Fries', 250, 3.0, 32.0, 13.0,
 3.0, 0.0, 155, NULL,
 'raising_canes', ARRAY['raising canes fries', 'canes fries', 'canes crinkle fries'],
 'sides', 'Raising Cane''s', 1, '~388 cal per 155g serving.', TRUE,
 350, 0, 2.5, 0.0, 470, 10, 0.6, 0, 5.0, 0, 22, 0.3, 60, 2.0, 0.01),

('raising_canes_sauce', 'Raising Cane''s Cane''s Sauce', 475, 1.0, 10.0, 48.0,
 0.0, 5.0, 40, NULL,
 'raising_canes', ARRAY['raising canes sauce', 'canes sauce', 'canes dipping sauce'],
 'sides', 'Raising Cane''s', 1, '~190 cal per 40g ramekin. Signature mayo-based dipping sauce.', TRUE,
 1450, 25, 7.5, 0.0, 20, 5, 0.2, 5, 0.5, 0, 2, 0.1, 15, 1.0, 0.05),

('raising_canes_box_combo', 'Raising Cane''s Box Combo', 225, 11.0, 17.5, 12.0,
 1.5, 3.0, 555, NULL,
 'raising_canes', ARRAY['raising canes box combo', 'canes box', 'the box combo'],
 'american', 'Raising Cane''s', 1, '~1250 cal per box combo (555g). 4 fingers, fries, toast, coleslaw, sauce.', TRUE,
 480, 35, 3.0, 0.1, 280, 20, 0.8, 5, 4.0, 2, 18, 0.6, 100, 10.0, 0.02),

('raising_canes_caniac', 'Raising Cane''s Caniac Combo', 230, 12.0, 17.0, 13.0,
 1.5, 3.0, 780, NULL,
 'raising_canes', ARRAY['raising canes caniac', 'canes caniac combo', 'the caniac'],
 'american', 'Raising Cane''s', 1, '~1794 cal per Caniac combo (780g). 6 fingers, fries, toast, coleslaw, 2 sauces.', TRUE,
 490, 38, 3.2, 0.1, 290, 22, 0.9, 5, 4.0, 2, 19, 0.7, 105, 11.0, 0.02)
,
-- ============================================================================
-- FIRST WATCH
-- ============================================================================

('first_watch_avocado_toast', 'First Watch Avocado Toast', 175, 6.5, 13.0, 11.5,
 3.5, 2.0, 360, NULL,
 'first_watch', ARRAY['first watch avocado toast', 'first watch avo toast'],
 'american', 'First Watch', 1, '~630 cal per 360g serving. Whole grain bread with fresh avocado and eggs.', TRUE,
 520, 180, 3.0, 0.0, 400, 40, 2.0, 50, 8.0, 20, 30, 1.0, 150, 12.0, 0.08),

('first_watch_million_dollar_bacon', 'First Watch Million Dollar Bacon', 430, 18.0, 20.0, 32.0,
 0.0, 16.0, 120, NULL,
 'first_watch', ARRAY['first watch million dollar bacon', 'million dollar bacon'],
 'american', 'First Watch', 1, '~516 cal per 120g (4 slices). Thick-cut bacon with brown sugar, cayenne, black pepper.', TRUE,
 850, 100, 11.0, 0.1, 400, 8, 1.0, 0, 0.5, 25, 20, 2.5, 300, 30.0, 0.02),

('first_watch_lemon_ricotta_pancakes', 'First Watch Lemon Ricotta Pancakes', 250, 7.0, 32.0, 10.0,
 0.5, 12.0, 350, NULL,
 'first_watch', ARRAY['first watch pancakes', 'first watch lemon pancakes', 'first watch ricotta pancakes'],
 'american', 'First Watch', 1, '~875 cal per 350g serving. Fluffy ricotta pancakes with lemon and blueberries.', TRUE,
 420, 60, 4.5, 0.1, 150, 100, 1.5, 30, 5.0, 10, 15, 0.6, 120, 12.0, 0.02),

('first_watch_sunrise_granola', 'First Watch Sunrise Granola Bowl', 160, 5.0, 22.0, 6.5,
 3.0, 12.0, 350, NULL,
 'first_watch', ARRAY['first watch granola bowl', 'first watch sunrise bowl'],
 'american', 'First Watch', 1, '~560 cal per 350g serving. Greek yogurt with granola and fresh fruit.', TRUE,
 80, 10, 1.5, 0.0, 350, 120, 1.0, 30, 15.0, 5, 30, 1.0, 120, 5.0, 0.05),

('first_watch_farmhouse_crepe', 'First Watch Farmhouse Crepe', 190, 10.0, 15.0, 10.0,
 1.0, 3.0, 350, NULL,
 'first_watch', ARRAY['first watch farmhouse crepe', 'first watch crepe'],
 'american', 'First Watch', 1, '~665 cal per 350g serving. Egg crepe with ham, cheese, vegetables.', TRUE,
 580, 150, 5.0, 0.1, 250, 100, 1.5, 60, 5.0, 15, 20, 1.5, 180, 15.0, 0.03),

('first_watch_chickichanga', 'First Watch Chickichanga', 210, 12.0, 18.0, 10.0,
 2.0, 2.0, 400, NULL,
 'first_watch', ARRAY['first watch chickichanga'],
 'american', 'First Watch', 1, '~840 cal per 400g serving. Baked chicken chimichanga with avocado.', TRUE,
 620, 55, 3.5, 0.1, 350, 80, 1.5, 30, 5.0, 5, 28, 1.5, 200, 18.0, 0.04),

('first_watch_power_bowl', 'First Watch Power Bowl', 145, 10.0, 14.0, 6.0,
 3.0, 4.0, 400, NULL,
 'first_watch', ARRAY['first watch power bowl', 'first watch protein bowl'],
 'american', 'First Watch', 1, '~580 cal per 400g serving. Quinoa, kale, avocado, chicken.', TRUE,
 380, 40, 1.5, 0.0, 500, 60, 2.5, 150, 20.0, 5, 45, 1.5, 200, 15.0, 0.10),

('first_watch_key_west_shrimp', 'First Watch Key West Shrimp', 130, 12.0, 8.0, 6.0,
 1.5, 2.0, 350, NULL,
 'first_watch', ARRAY['first watch key west shrimp', 'first watch shrimp'],
 'seafood', 'First Watch', 1, '~455 cal per 350g serving. Sauteed shrimp with peppers and onions.', TRUE,
 520, 130, 2.5, 0.0, 280, 40, 1.0, 30, 15.0, 5, 30, 1.0, 180, 25.0, 0.08),

('first_watch_cinnamon_toast', 'First Watch Cinnamon Toast', 320, 5.0, 42.0, 14.0,
 1.0, 18.0, 120, NULL,
 'first_watch', ARRAY['first watch cinnamon toast'],
 'american', 'First Watch', 1, '~384 cal per 120g serving. Thick-cut brioche with cinnamon butter.', TRUE,
 350, 15, 7.0, 0.1, 60, 40, 1.5, 30, 0.0, 3, 10, 0.4, 50, 10.0, 0.01),

('first_watch_floridian_french_toast', 'First Watch Floridian French Toast', 260, 6.0, 34.0, 11.0,
 1.0, 18.0, 350, NULL,
 'first_watch', ARRAY['first watch french toast', 'first watch floridian toast'],
 'american', 'First Watch', 1, '~910 cal per 350g serving. Brioche French toast with fresh fruit.', TRUE,
 380, 80, 5.5, 0.1, 180, 50, 1.5, 30, 5.0, 8, 12, 0.5, 80, 10.0, 0.02),

-- ============================================================================
-- BJ'S RESTAURANT & BREWHOUSE
-- ============================================================================

('bjs_pizookie_chocolate', 'BJ''s Restaurant Chocolate Chunk Pizookie', 340, 4.0, 44.0, 17.0,
 1.0, 30.0, 340, NULL,
 'bjs_restaurant', ARRAY['bjs pizookie', 'bjs chocolate pizookie', 'bjs cookie dessert'],
 'dessert', 'BJ''s Restaurant', 1, '~1156 cal per 340g Pizookie. Warm cookie with vanilla ice cream.', TRUE,
 280, 60, 10.0, 0.2, 150, 50, 2.0, 40, 0.0, 5, 20, 0.8, 70, 5.0, 0.02),

('bjs_pizookie_triple_choc', 'BJ''s Restaurant Triple Chocolate Pizookie', 355, 4.5, 46.0, 18.0,
 2.0, 32.0, 340, NULL,
 'bjs_restaurant', ARRAY['bjs triple chocolate pizookie'],
 'dessert', 'BJ''s Restaurant', 1, '~1207 cal per 340g. Triple chocolate version.', TRUE,
 260, 65, 11.0, 0.2, 180, 55, 3.0, 35, 0.0, 5, 30, 1.0, 80, 5.0, 0.02),

('bjs_deep_dish_pizza', 'BJ''s Restaurant Deep Dish Pizza (slice)', 235, 10.0, 25.0, 10.5,
 1.5, 3.0, 180, 180,
 'bjs_restaurant', ARRAY['bjs deep dish pizza', 'bjs pizza', 'bjs deep dish'],
 'pizza', 'BJ''s Restaurant', 1, '~423 cal per slice (180g). Chicago-style deep dish.', TRUE,
 580, 25, 4.5, 0.1, 200, 120, 1.5, 30, 3.0, 3, 15, 1.0, 120, 10.0, 0.02),

('bjs_mini_dogs', 'BJ''s Restaurant Mini Dogs', 300, 10.0, 24.0, 18.0,
 1.0, 3.0, 250, NULL,
 'bjs_restaurant', ARRAY['bjs mini dogs', 'bjs appetizer hot dogs'],
 'american', 'BJ''s Restaurant', 1, '~750 cal per 250g serving.', TRUE,
 680, 30, 6.0, 0.2, 150, 40, 2.0, 5, 1.0, 5, 10, 1.5, 100, 10.0, 0.02),

('bjs_loaded_potato_skins', 'BJ''s Restaurant Loaded Potato Skins', 200, 7.0, 16.0, 12.0,
 1.5, 1.0, 300, NULL,
 'bjs_restaurant', ARRAY['bjs potato skins', 'bjs loaded skins'],
 'american', 'BJ''s Restaurant', 1, '~600 cal per 300g serving.', TRUE,
 550, 30, 6.0, 0.2, 400, 80, 1.0, 20, 8.0, 3, 22, 1.0, 100, 3.0, 0.02),

('bjs_ahi_poke', 'BJ''s Restaurant Ahi Poke', 110, 14.0, 8.0, 3.0,
 1.0, 3.0, 250, NULL,
 'bjs_restaurant', ARRAY['bjs ahi poke', 'bjs poke bowl'],
 'seafood', 'BJ''s Restaurant', 1, '~275 cal per 250g serving.', TRUE,
 520, 30, 0.5, 0.0, 350, 15, 0.8, 30, 3.0, 60, 28, 0.4, 170, 45.0, 0.25),

('bjs_bbq_tacos', 'BJ''s Restaurant BBQ Brisket Tacos', 200, 12.0, 16.0, 10.0,
 2.0, 4.0, 300, NULL,
 'bjs_restaurant', ARRAY['bjs brisket tacos', 'bjs bbq tacos'],
 'american', 'BJ''s Restaurant', 1, '~600 cal per 300g (3 tacos).', TRUE,
 550, 45, 4.0, 0.2, 250, 60, 2.0, 15, 3.0, 5, 18, 3.0, 150, 12.0, 0.03),

('bjs_chicken_lettuce_wraps', 'BJ''s Restaurant Chicken Lettuce Wraps', 115, 10.0, 10.0, 4.0,
 1.5, 4.0, 300, NULL,
 'bjs_restaurant', ARRAY['bjs lettuce wraps', 'bjs chicken wraps'],
 'asian', 'BJ''s Restaurant', 1, '~345 cal per 300g serving.', TRUE,
 520, 35, 1.0, 0.0, 250, 20, 1.0, 15, 5.0, 3, 20, 0.8, 120, 12.0, 0.02),

('bjs_avocado_egg_rolls', 'BJ''s Restaurant Avocado Egg Rolls', 260, 5.0, 24.0, 16.0,
 3.0, 3.0, 250, NULL,
 'bjs_restaurant', ARRAY['bjs avocado egg rolls', 'bjs egg rolls'],
 'american', 'BJ''s Restaurant', 1, '~650 cal per 250g serving.', TRUE,
 480, 10, 3.0, 0.1, 400, 20, 1.0, 5, 8.0, 0, 25, 0.5, 50, 2.0, 0.06),

('bjs_nashville_hot_sandwich', 'BJ''s Restaurant Nashville Hot Chicken Sandwich', 250, 16.0, 20.0, 12.0,
 1.0, 3.0, 350, NULL,
 'bjs_restaurant', ARRAY['bjs nashville hot chicken', 'bjs hot chicken sandwich'],
 'american', 'BJ''s Restaurant', 1, '~875 cal per 350g serving.', TRUE,
 620, 55, 3.0, 0.1, 250, 30, 1.5, 15, 3.0, 3, 25, 1.2, 180, 20.0, 0.03)
,
-- ============================================================================
-- YARD HOUSE
-- ============================================================================

('yard_house_truffle_fries', 'Yard House Truffle Fries', 290, 5.0, 35.0, 15.0,
 3.0, 0.5, 250, NULL,
 'yard_house', ARRAY['yard house truffle fries', 'yard house fries'],
 'sides', 'Yard House', 1, '~725 cal per 250g serving. Parmesan and truffle oil.', TRUE,
 440, 8, 3.5, 0.1, 490, 45, 0.7, 0, 6.0, 0, 22, 0.5, 75, 2.0, 0.01),

('yard_house_street_tacos', 'Yard House Street Tacos', 180, 12.0, 14.0, 8.5,
 2.0, 2.0, 300, NULL,
 'yard_house', ARRAY['yard house tacos', 'yard house street tacos'],
 'american', 'Yard House', 1, '~540 cal per 300g (3 tacos).', TRUE,
 520, 40, 3.0, 0.1, 250, 50, 1.5, 15, 3.0, 3, 18, 2.5, 140, 12.0, 0.03),

('yard_house_thai_lettuce_wraps', 'Yard House Thai Lettuce Wraps', 120, 10.0, 10.0, 4.5,
 1.5, 4.5, 300, NULL,
 'yard_house', ARRAY['yard house lettuce wraps', 'yard house thai wraps'],
 'asian', 'Yard House', 1, '~360 cal per 300g serving.', TRUE,
 500, 30, 1.0, 0.0, 280, 25, 1.0, 20, 8.0, 3, 22, 0.8, 120, 12.0, 0.02),

('yard_house_nashville_hot', 'Yard House Nashville Hot Chicken', 255, 17.0, 18.0, 13.0,
 1.0, 3.0, 350, NULL,
 'yard_house', ARRAY['yard house nashville hot chicken', 'yard house hot chicken'],
 'american', 'Yard House', 1, '~893 cal per 350g serving.', TRUE,
 640, 60, 3.5, 0.1, 260, 30, 1.5, 15, 3.0, 3, 25, 1.2, 180, 20.0, 0.03),

('yard_house_poke_nachos', 'Yard House Poke Nachos', 170, 10.0, 16.0, 8.0,
 2.0, 3.0, 350, NULL,
 'yard_house', ARRAY['yard house poke nachos'],
 'asian', 'Yard House', 1, '~595 cal per 350g serving. Ahi tuna poke on wonton crisps.', TRUE,
 520, 25, 1.5, 0.0, 300, 25, 1.0, 20, 5.0, 40, 22, 0.5, 120, 25.0, 0.15),

('yard_house_whiskey_burger', 'Yard House Whiskey-Glazed Burger', 240, 14.0, 18.0, 12.5,
 1.0, 5.0, 380, NULL,
 'yard_house', ARRAY['yard house burger', 'yard house whiskey burger'],
 'american', 'Yard House', 1, '~912 cal per 380g serving.', TRUE,
 580, 65, 5.5, 0.3, 280, 80, 2.5, 10, 2.0, 5, 22, 4.0, 170, 20.0, 0.03),

('yard_house_margherita_flatbread', 'Yard House Margherita Flatbread', 220, 9.0, 24.0, 9.5,
 1.5, 3.0, 300, NULL,
 'yard_house', ARRAY['yard house flatbread', 'yard house margherita'],
 'pizza', 'Yard House', 1, '~660 cal per 300g flatbread.', TRUE,
 520, 20, 4.5, 0.1, 200, 120, 1.5, 30, 3.0, 3, 15, 1.0, 120, 10.0, 0.02),

('yard_house_grilled_chicken_avo', 'Yard House Grilled Chicken & Avocado Sandwich', 195, 15.0, 16.0, 8.5,
 3.0, 2.0, 350, NULL,
 'yard_house', ARRAY['yard house chicken sandwich', 'yard house chicken avocado'],
 'american', 'Yard House', 1, '~683 cal per 350g serving.', TRUE,
 520, 50, 2.5, 0.0, 400, 30, 1.5, 15, 5.0, 3, 30, 1.0, 180, 18.0, 0.06),

-- ============================================================================
-- CHEDDAR'S SCRATCH KITCHEN
-- ============================================================================

('cheddars_honey_butter_croissants', 'Cheddar''s Honey Butter Croissants', 350, 6.0, 38.0, 19.0,
 1.0, 12.0, 80, 80,
 'cheddars', ARRAY['cheddars croissant', 'cheddars honey butter croissant'],
 'sides', 'Cheddar''s', 1, '~280 cal per croissant (80g). Served warm with honey butter.', TRUE,
 380, 30, 11.0, 0.2, 60, 20, 1.5, 80, 0.0, 5, 8, 0.4, 50, 8.0, 0.01),

('cheddars_chicken_tenders', 'Cheddar''s Chicken Tenders', 235, 18.0, 12.0, 12.5,
 0.5, 0.5, 300, NULL,
 'cheddars', ARRAY['cheddars chicken tenders', 'cheddars tenders'],
 'american', 'Cheddar''s', 1, '~705 cal per 300g serving. Hand-breaded chicken tenders.', TRUE,
 520, 55, 2.5, 0.1, 220, 15, 1.0, 5, 0.0, 3, 22, 1.0, 170, 18.0, 0.02),

('cheddars_country_fried_steak', 'Cheddar''s Country Fried Steak', 250, 14.0, 16.0, 14.5,
 0.5, 1.0, 350, NULL,
 'cheddars', ARRAY['cheddars country fried steak', 'cheddars chicken fried steak'],
 'american', 'Cheddar''s', 1, '~875 cal per 350g serving. Breaded steak with gravy.', TRUE,
 620, 60, 5.0, 0.3, 250, 30, 2.5, 5, 0.0, 5, 18, 4.0, 170, 18.0, 0.02),

('cheddars_baby_back_ribs', 'Cheddar''s Baby Back Ribs', 225, 16.0, 5.0, 16.0,
 0.0, 4.0, 400, NULL,
 'cheddars', ARRAY['cheddars ribs', 'cheddars baby back ribs'],
 'bbq', 'Cheddar''s', 1, '~900 cal per full rack (400g).', TRUE,
 480, 75, 6.0, 0.2, 300, 25, 1.5, 5, 2.0, 5, 18, 3.5, 180, 15.0, 0.03),

('cheddars_grilled_salmon', 'Cheddar''s Grilled Salmon', 190, 22.0, 2.0, 10.5,
 0.0, 1.5, 230, NULL,
 'cheddars', ARRAY['cheddars salmon', 'cheddars grilled salmon'],
 'seafood', 'Cheddar''s', 1, '~437 cal per 8oz (230g) salmon fillet.', TRUE,
 350, 63, 2.5, 0.0, 380, 12, 0.5, 12, 0.0, 520, 30, 0.5, 260, 40.0, 1.80),

('cheddars_monte_cristo', 'Cheddar''s Monte Cristo', 280, 12.0, 22.0, 16.0,
 1.0, 5.0, 350, NULL,
 'cheddars', ARRAY['cheddars monte cristo', 'cheddars monte cristo sandwich'],
 'american', 'Cheddar''s', 1, '~980 cal per 350g serving. Battered ham and cheese sandwich.', TRUE,
 680, 70, 7.0, 0.2, 200, 100, 2.0, 20, 1.0, 8, 15, 1.5, 180, 15.0, 0.02),

('cheddars_onion_rings', 'Cheddar''s Homemade Onion Rings', 280, 4.0, 32.0, 15.0,
 2.0, 5.0, 200, NULL,
 'cheddars', ARRAY['cheddars onion rings', 'cheddars rings'],
 'sides', 'Cheddar''s', 1, '~560 cal per 200g serving. Homemade beer-battered.', TRUE,
 450, 10, 3.0, 0.1, 150, 30, 1.0, 0, 3.0, 0, 10, 0.3, 40, 3.0, 0.01),

('cheddars_potato_soup', 'Cheddar''s Loaded Baked Potato Soup', 140, 4.0, 12.0, 8.5,
 1.0, 2.0, 300, NULL,
 'cheddars', ARRAY['cheddars potato soup', 'cheddars loaded potato soup'],
 'sides', 'Cheddar''s', 1, '~420 cal per 300g bowl.', TRUE,
 580, 20, 5.0, 0.1, 350, 60, 0.5, 25, 5.0, 3, 18, 0.5, 80, 3.0, 0.02),

('cheddars_key_lime_pie', 'Cheddar''s Key Lime Pie', 310, 4.0, 38.0, 16.0,
 0.5, 28.0, 170, NULL,
 'cheddars', ARRAY['cheddars key lime pie', 'cheddars key lime'],
 'dessert', 'Cheddar''s', 1, '~527 cal per 170g slice.', TRUE,
 200, 60, 8.0, 0.1, 120, 60, 0.5, 40, 8.0, 5, 10, 0.4, 60, 3.0, 0.02)
,
-- ============================================================================
-- MAGGIANO'S LITTLE ITALY
-- ============================================================================

('maggianos_baked_ziti', 'Maggiano''s Baked Ziti', 165, 8.0, 18.0, 7.0,
 1.5, 3.0, 450, NULL,
 'maggianos', ARRAY['maggianos baked ziti', 'maggianos ziti'],
 'italian', 'Maggiano''s', 1, '~743 cal per 450g serving. Ziti with meat sauce and ricotta.', TRUE,
 520, 30, 3.0, 0.1, 300, 80, 2.0, 30, 5.0, 3, 20, 1.5, 150, 15.0, 0.02),

('maggianos_chicken_parm', 'Maggiano''s Chicken Parmesan', 195, 16.0, 14.0, 8.5,
 1.0, 3.5, 450, NULL,
 'maggianos', ARRAY['maggianos chicken parmesan', 'maggianos chicken parm'],
 'italian', 'Maggiano''s', 1, '~878 cal per 450g serving. Breaded chicken with marinara and mozzarella.', TRUE,
 580, 60, 3.5, 0.1, 350, 120, 1.5, 40, 5.0, 5, 28, 1.8, 220, 22.0, 0.03),

('maggianos_fettuccine_alfredo', 'Maggiano''s Fettuccine Alfredo', 220, 7.0, 22.0, 12.0,
 1.0, 2.0, 450, NULL,
 'maggianos', ARRAY['maggianos fettuccine alfredo', 'maggianos alfredo'],
 'italian', 'Maggiano''s', 1, '~990 cal per 450g serving. Fettuccine in cream and Parmesan sauce.', TRUE,
 480, 45, 7.0, 0.1, 120, 150, 1.0, 60, 0.0, 5, 15, 0.8, 140, 8.0, 0.02),

('maggianos_lasagna', 'Maggiano''s Lasagna', 170, 10.0, 14.0, 8.5,
 1.0, 3.0, 450, NULL,
 'maggianos', ARRAY['maggianos lasagna', 'maggianos classic lasagna'],
 'italian', 'Maggiano''s', 1, '~765 cal per 450g serving. Layers of pasta, meat sauce, ricotta, mozzarella.', TRUE,
 550, 40, 4.0, 0.1, 320, 120, 2.0, 40, 4.0, 3, 22, 2.0, 160, 15.0, 0.02),

('maggianos_rigatoni_d', 'Maggiano''s Rigatoni D', 180, 9.0, 20.0, 7.5,
 1.5, 3.0, 400, NULL,
 'maggianos', ARRAY['maggianos rigatoni', 'maggianos rigatoni d'],
 'italian', 'Maggiano''s', 1, '~720 cal per 400g serving. Rigatoni with Italian sausage and peppers.', TRUE,
 560, 35, 3.0, 0.1, 280, 60, 2.0, 20, 8.0, 3, 18, 1.5, 140, 12.0, 0.03),

('maggianos_tiramisu', 'Maggiano''s Tiramisu', 295, 5.0, 32.0, 17.0,
 0.5, 22.0, 200, NULL,
 'maggianos', ARRAY['maggianos tiramisu', 'maggianos tiramisu dessert'],
 'dessert', 'Maggiano''s', 1, '~590 cal per 200g serving. Ladyfingers with mascarpone and espresso.', TRUE,
 80, 120, 10.0, 0.1, 100, 50, 0.8, 80, 0.0, 8, 10, 0.5, 80, 5.0, 0.02),

('maggianos_cheesecake', 'Maggiano''s New York Cheesecake', 330, 5.5, 30.0, 22.0,
 0.0, 24.0, 180, NULL,
 'maggianos', ARRAY['maggianos cheesecake', 'maggianos ny cheesecake'],
 'dessert', 'Maggiano''s', 1, '~594 cal per 180g slice.', TRUE,
 260, 105, 13.0, 0.1, 105, 55, 0.5, 125, 1.0, 10, 10, 0.5, 85, 5.0, 0.02),

('maggianos_bruschetta', 'Maggiano''s Bruschetta', 185, 5.0, 20.0, 9.5,
 2.0, 3.0, 200, NULL,
 'maggianos', ARRAY['maggianos bruschetta', 'maggianos appetizer bruschetta'],
 'italian', 'Maggiano''s', 1, '~370 cal per 200g serving. Toasted bread with tomato, basil, garlic.', TRUE,
 420, 5, 1.5, 0.0, 250, 30, 1.5, 30, 10.0, 0, 15, 0.5, 40, 5.0, 0.03),

('maggianos_calamari', 'Maggiano''s Crispy Calamari', 210, 12.0, 16.0, 10.5,
 0.5, 1.0, 250, NULL,
 'maggianos', ARRAY['maggianos calamari', 'maggianos fried calamari'],
 'seafood', 'Maggiano''s', 1, '~525 cal per 250g serving.', TRUE,
 530, 150, 2.0, 0.1, 180, 25, 1.5, 5, 5.0, 3, 25, 1.2, 140, 28.0, 0.08),

('maggianos_meatballs', 'Maggiano''s Meatballs', 180, 12.0, 8.0, 11.0,
 0.5, 2.5, 200, NULL,
 'maggianos', ARRAY['maggianos meatballs', 'maggianos italian meatballs'],
 'italian', 'Maggiano''s', 1, '~360 cal per 200g serving. Beef and pork meatballs in marinara.', TRUE,
 520, 55, 4.5, 0.2, 350, 40, 2.0, 15, 4.0, 5, 18, 3.0, 150, 15.0, 0.03),

('maggianos_chicken_piccata', 'Maggiano''s Chicken Piccata', 170, 18.0, 6.0, 8.5,
 0.5, 1.0, 350, NULL,
 'maggianos', ARRAY['maggianos chicken piccata', 'maggianos piccata'],
 'italian', 'Maggiano''s', 1, '~595 cal per 350g serving. Chicken breast with lemon caper butter.', TRUE,
 480, 65, 4.0, 0.1, 280, 20, 1.0, 10, 8.0, 5, 28, 1.0, 220, 24.0, 0.03),

('maggianos_shrimp_scampi', 'Maggiano''s Shrimp Scampi', 155, 14.0, 15.0, 5.5,
 1.0, 1.0, 350, NULL,
 'maggianos', ARRAY['maggianos shrimp scampi', 'maggianos scampi'],
 'seafood', 'Maggiano''s', 1, '~543 cal per 350g serving. Shrimp with linguine in garlic butter.', TRUE,
 520, 130, 2.5, 0.0, 200, 40, 1.5, 10, 3.0, 5, 30, 1.5, 200, 30.0, 0.10),

-- ============================================================================
-- SEASONS 52
-- ============================================================================

('seasons52_flatbread', 'Seasons 52 Flatbread', 195, 8.0, 22.0, 8.5,
 1.5, 2.0, 250, NULL,
 'seasons_52', ARRAY['seasons 52 flatbread', 'seasons 52 pizza'],
 'american', 'Seasons 52', 1, '~488 cal per 250g flatbread.', TRUE,
 480, 15, 3.5, 0.1, 180, 80, 1.5, 20, 3.0, 3, 15, 0.8, 100, 8.0, 0.02),

('seasons52_cedar_salmon', 'Seasons 52 Cedar Plank Salmon', 180, 22.0, 3.0, 9.0,
 0.5, 2.0, 230, NULL,
 'seasons_52', ARRAY['seasons 52 salmon', 'seasons 52 cedar plank salmon'],
 'seafood', 'Seasons 52', 1, '~414 cal per 230g serving. All items under 595 cal.', TRUE,
 350, 63, 2.0, 0.0, 380, 12, 0.5, 12, 0.0, 520, 30, 0.5, 260, 40.0, 1.80),

('seasons52_filet', 'Seasons 52 Wood-Grilled Filet', 210, 27.0, 0.0, 11.0,
 0.0, 0.0, 230, NULL,
 'seasons_52', ARRAY['seasons 52 filet', 'seasons 52 steak'],
 'steakhouse', 'Seasons 52', 1, '~483 cal per 8oz (230g) filet.', TRUE,
 55, 78, 4.5, 0.3, 350, 15, 3.2, 0, 0.0, 7, 26, 3.8, 225, 31.0, 0.03),

('seasons52_power_bowl', 'Seasons 52 Power Bowl', 130, 10.0, 14.0, 4.5,
 3.0, 4.0, 400, NULL,
 'seasons_52', ARRAY['seasons 52 power bowl', 'seasons 52 grain bowl'],
 'american', 'Seasons 52', 1, '~520 cal per 400g serving. Grains, vegetables, protein.', TRUE,
 350, 30, 1.0, 0.0, 450, 50, 2.0, 100, 15.0, 5, 40, 1.2, 180, 12.0, 0.08),

('seasons52_mini_key_lime', 'Seasons 52 Mini Indulgence Key Lime', 260, 3.0, 32.0, 14.0,
 0.5, 24.0, 80, NULL,
 'seasons_52', ARRAY['seasons 52 key lime', 'seasons 52 mini indulgence'],
 'dessert', 'Seasons 52', 1, '~208 cal per 80g mini dessert. Signature mini indulgence.', TRUE,
 120, 40, 7.0, 0.1, 80, 40, 0.3, 30, 4.0, 3, 6, 0.3, 40, 2.0, 0.01),

('seasons52_mini_chocolate', 'Seasons 52 Mini Indulgence Chocolate', 310, 4.0, 36.0, 18.0,
 2.0, 28.0, 80, NULL,
 'seasons_52', ARRAY['seasons 52 chocolate', 'seasons 52 mini chocolate'],
 'dessert', 'Seasons 52', 1, '~248 cal per 80g mini dessert.', TRUE,
 80, 30, 10.0, 0.1, 150, 25, 2.0, 15, 0.0, 3, 30, 0.8, 60, 3.0, 0.01),

('seasons52_cauliflower', 'Seasons 52 Roasted Cauliflower', 70, 3.0, 6.0, 4.5,
 2.5, 2.0, 200, NULL,
 'seasons_52', ARRAY['seasons 52 cauliflower', 'seasons 52 roasted cauliflower'],
 'sides', 'Seasons 52', 1, '~140 cal per 200g side.', TRUE,
 250, 0, 0.5, 0.0, 300, 20, 0.5, 0, 45.0, 0, 15, 0.3, 45, 1.0, 0.05),

('seasons52_artichokes', 'Seasons 52 Grilled Artichokes', 55, 3.0, 8.0, 2.0,
 4.0, 1.0, 200, NULL,
 'seasons_52', ARRAY['seasons 52 artichokes', 'seasons 52 grilled artichoke'],
 'sides', 'Seasons 52', 1, '~110 cal per 200g side.', TRUE,
 280, 0, 0.3, 0.0, 370, 40, 1.3, 1, 10.0, 0, 60, 0.5, 90, 0.5, 0.02)
,
-- ============================================================================
-- BONEFISH GRILL
-- ============================================================================

('bonefish_bang_bang_shrimp', 'Bonefish Grill Bang Bang Shrimp', 255, 10.0, 18.0, 16.0,
 0.5, 4.0, 300, NULL,
 'bonefish', ARRAY['bonefish bang bang shrimp', 'bang bang shrimp bonefish'],
 'seafood', 'Bonefish Grill', 1, '~765 cal per 300g serving. Crispy shrimp with creamy spicy sauce.', TRUE,
 620, 80, 3.5, 0.1, 180, 35, 1.0, 10, 3.0, 5, 25, 1.0, 150, 22.0, 0.08),

('bonefish_sea_bass', 'Bonefish Grill Chilean Sea Bass', 185, 18.0, 3.0, 11.0,
 0.0, 1.5, 250, NULL,
 'bonefish', ARRAY['bonefish sea bass', 'bonefish chilean sea bass'],
 'seafood', 'Bonefish Grill', 1, '~463 cal per 250g serving. Pan-seared with choice of sauce.', TRUE,
 420, 55, 2.5, 0.0, 350, 15, 0.6, 30, 0.0, 200, 30, 0.5, 200, 35.0, 1.20),

('bonefish_wood_grilled_salmon', 'Bonefish Grill Wood-Grilled Salmon', 195, 22.0, 2.0, 11.0,
 0.0, 1.0, 230, NULL,
 'bonefish', ARRAY['bonefish salmon', 'bonefish grilled salmon'],
 'seafood', 'Bonefish Grill', 1, '~449 cal per 230g serving.', TRUE,
 350, 63, 2.5, 0.0, 380, 12, 0.5, 12, 0.0, 520, 30, 0.5, 260, 40.0, 1.80),

('bonefish_lilys_chicken', 'Bonefish Grill Lily''s Chicken', 175, 20.0, 4.0, 8.5,
 0.5, 2.0, 300, NULL,
 'bonefish', ARRAY['bonefish chicken', 'bonefish lilys chicken'],
 'american', 'Bonefish Grill', 1, '~525 cal per 300g serving. Sauteed chicken with artichoke and lemon.', TRUE,
 480, 65, 3.0, 0.1, 300, 30, 1.0, 15, 8.0, 5, 30, 1.0, 220, 24.0, 0.03),

('bonefish_wagyu_flat_iron', 'Bonefish Grill Wagyu Flat Iron Steak', 240, 24.0, 0.0, 16.0,
 0.0, 0.0, 280, NULL,
 'bonefish', ARRAY['bonefish steak', 'bonefish wagyu flat iron'],
 'steakhouse', 'Bonefish Grill', 1, '~672 cal per 10oz (280g) flat iron.', TRUE,
 60, 78, 6.5, 0.3, 330, 15, 2.5, 0, 0.0, 7, 22, 5.0, 200, 25.0, 0.03),

('bonefish_mussels', 'Bonefish Grill Mussels Josephine', 110, 10.0, 6.0, 5.5,
 0.5, 1.0, 400, NULL,
 'bonefish', ARRAY['bonefish mussels', 'bonefish mussels josephine'],
 'seafood', 'Bonefish Grill', 1, '~440 cal per 400g serving. Mussels in garlic white wine broth.', TRUE,
 550, 48, 1.5, 0.0, 380, 30, 6.0, 50, 5.0, 3, 35, 1.5, 200, 60.0, 0.50),

('bonefish_corn_chowder', 'Bonefish Grill Corn Chowder', 110, 3.5, 12.0, 5.5,
 1.0, 4.0, 300, NULL,
 'bonefish', ARRAY['bonefish corn chowder', 'bonefish soup'],
 'sides', 'Bonefish Grill', 1, '~330 cal per 300g bowl.', TRUE,
 480, 15, 3.0, 0.0, 250, 30, 0.5, 15, 5.0, 3, 18, 0.4, 60, 2.0, 0.02),

('bonefish_warm_crab_dip', 'Bonefish Grill Warm Crab Dip', 175, 10.0, 6.0, 12.5,
 0.3, 1.0, 200, NULL,
 'bonefish', ARRAY['bonefish crab dip', 'bonefish warm crab dip'],
 'seafood', 'Bonefish Grill', 1, '~350 cal per 200g serving.', TRUE,
 520, 60, 7.0, 0.1, 150, 80, 0.5, 30, 1.0, 3, 18, 2.0, 120, 15.0, 0.08),

('bonefish_key_lime', 'Bonefish Grill Key Lime Pie', 305, 4.0, 38.0, 15.5,
 0.5, 28.0, 170, NULL,
 'bonefish', ARRAY['bonefish key lime pie', 'bonefish dessert'],
 'dessert', 'Bonefish Grill', 1, '~519 cal per 170g slice.', TRUE,
 200, 60, 8.0, 0.1, 120, 60, 0.5, 40, 8.0, 5, 10, 0.4, 60, 3.0, 0.02),

-- ============================================================================
-- PETER LUGER STEAK HOUSE
-- ============================================================================

('peter_luger_porterhouse', 'Peter Luger Porterhouse Steak for Two', 270, 25.0, 0.0, 18.5,
 0.0, 0.0, 900, NULL,
 'peter_luger', ARRAY['peter luger porterhouse', 'peter luger steak', 'peter luger steak for two'],
 'steakhouse', 'Peter Luger', 1, '~2430 cal per 2lb (900g) porterhouse for two. USDA prime dry-aged.', TRUE,
 62, 82, 8.0, 0.5, 340, 16, 2.5, 0, 0.0, 7, 23, 4.5, 210, 27.0, 0.03),

('peter_luger_german_potatoes', 'Peter Luger German Fried Potatoes', 175, 3.0, 22.0, 9.0,
 2.0, 0.5, 250, NULL,
 'peter_luger', ARRAY['peter luger potatoes', 'peter luger fried potatoes', 'peter luger german potatoes'],
 'sides', 'Peter Luger', 1, '~438 cal per 250g side. Pan-fried potatoes with onions.', TRUE,
 320, 0, 1.5, 0.1, 450, 10, 0.6, 0, 8.0, 0, 22, 0.3, 55, 2.0, 0.01),

('peter_luger_creamed_spinach', 'Peter Luger Creamed Spinach', 130, 4.5, 5.5, 10.0,
 1.5, 1.5, 200, NULL,
 'peter_luger', ARRAY['peter luger spinach', 'peter luger creamed spinach'],
 'sides', 'Peter Luger', 1, '~260 cal per 200g side.', TRUE,
 400, 25, 6.0, 0.1, 350, 120, 2.0, 350, 15.0, 5, 50, 0.6, 60, 3.0, 0.05),

('peter_luger_thick_bacon', 'Peter Luger Thick-Cut Bacon', 420, 14.0, 0.0, 40.0,
 0.0, 0.0, 120, NULL,
 'peter_luger', ARRAY['peter luger bacon', 'peter luger thick cut bacon'],
 'steakhouse', 'Peter Luger', 1, '~504 cal per 120g (3 thick slices). Extra-thick slab bacon.', TRUE,
 850, 80, 14.0, 0.1, 350, 5, 0.8, 0, 0.0, 20, 18, 1.8, 250, 20.0, 0.02),

('peter_luger_burger', 'Peter Luger Burger', 250, 17.0, 14.0, 14.0,
 1.0, 3.0, 300, NULL,
 'peter_luger', ARRAY['peter luger hamburger', 'peter luger burger'],
 'steakhouse', 'Peter Luger', 1, '~750 cal per 300g serving. Lunch-only burger.', TRUE,
 450, 70, 6.0, 0.3, 300, 60, 2.5, 5, 2.0, 5, 22, 4.5, 180, 22.0, 0.03),

('peter_luger_pecan_pie', 'Peter Luger Pecan Pie', 400, 4.5, 48.0, 22.0,
 2.0, 30.0, 150, NULL,
 'peter_luger', ARRAY['peter luger pecan pie', 'peter luger dessert'],
 'dessert', 'Peter Luger', 1, '~600 cal per 150g slice.', TRUE,
 200, 40, 4.0, 0.0, 120, 30, 1.5, 10, 0.5, 0, 30, 1.5, 80, 5.0, 0.10),

('peter_luger_hot_fudge_sundae', 'Peter Luger Hot Fudge Sundae', 250, 4.0, 35.0, 11.0,
 1.0, 28.0, 250, NULL,
 'peter_luger', ARRAY['peter luger sundae', 'peter luger ice cream'],
 'dessert', 'Peter Luger', 1, '~625 cal per 250g sundae. Schlag (whipped cream) topped.', TRUE,
 100, 40, 7.0, 0.1, 250, 100, 1.0, 50, 1.0, 10, 20, 0.6, 100, 3.0, 0.02),

('peter_luger_tomato_onion', 'Peter Luger Tomato & Onion Salad', 45, 1.0, 6.0, 2.0,
 1.0, 4.0, 300, NULL,
 'peter_luger', ARRAY['peter luger tomato salad', 'peter luger salad'],
 'salad', 'Peter Luger', 1, '~135 cal per 300g serving. Beefsteak tomato and onion with steak sauce.', TRUE,
 280, 0, 0.3, 0.0, 280, 12, 0.5, 40, 15.0, 0, 12, 0.2, 25, 0.5, 0.01)
,
-- ============================================================================
-- JOE'S STONE CRAB
-- ============================================================================

('joes_stone_crab_medium', 'Joe''s Stone Crab Claws (Medium)', 75, 15.0, 0.5, 1.0,
 0.0, 0.0, 300, 80,
 'joes_stone_crab', ARRAY['joes stone crab claws medium', 'joes stone crab medium'],
 'seafood', 'Joe''s Stone Crab', 1, '~225 cal per 300g serving (4-5 medium claws). With mustard sauce.', TRUE,
 550, 60, 0.2, 0.0, 250, 60, 0.5, 5, 3.0, 0, 40, 4.0, 240, 35.0, 0.30),

('joes_stone_crab_large', 'Joe''s Stone Crab Claws (Large)', 78, 15.5, 0.5, 1.2,
 0.0, 0.0, 350, 120,
 'joes_stone_crab', ARRAY['joes stone crab claws large', 'joes stone crab large'],
 'seafood', 'Joe''s Stone Crab', 1, '~273 cal per 350g serving (3-4 large claws).', TRUE,
 560, 62, 0.2, 0.0, 255, 62, 0.5, 5, 3.0, 0, 42, 4.2, 245, 36.0, 0.32),

('joes_stone_crab_jumbo', 'Joe''s Stone Crab Claws (Jumbo)', 80, 16.0, 0.5, 1.5,
 0.0, 0.0, 400, 180,
 'joes_stone_crab', ARRAY['joes stone crab claws jumbo', 'joes stone crab jumbo'],
 'seafood', 'Joe''s Stone Crab', 1, '~320 cal per 400g serving (2-3 jumbo claws).', TRUE,
 570, 65, 0.3, 0.0, 260, 65, 0.5, 5, 3.0, 0, 44, 4.5, 250, 38.0, 0.35),

('joes_key_lime_pie', 'Joe''s Stone Crab Key Lime Pie', 320, 4.0, 40.0, 16.5,
 0.5, 30.0, 170, NULL,
 'joes_stone_crab', ARRAY['joes key lime pie', 'joes stone crab key lime'],
 'dessert', 'Joe''s Stone Crab', 1, '~544 cal per 170g slice. Famous Key lime pie.', TRUE,
 200, 65, 9.0, 0.1, 120, 65, 0.5, 45, 10.0, 5, 10, 0.4, 65, 3.0, 0.02),

('joes_fried_chicken', 'Joe''s Stone Crab Fried Chicken', 255, 20.0, 10.0, 15.0,
 0.5, 0.5, 350, NULL,
 'joes_stone_crab', ARRAY['joes fried chicken', 'joes stone crab chicken'],
 'american', 'Joe''s Stone Crab', 1, '~893 cal per 350g serving. Southern-style fried chicken.', TRUE,
 480, 75, 4.0, 0.1, 250, 20, 1.2, 8, 0.0, 5, 25, 1.5, 180, 22.0, 0.03),

('joes_hash_browns', 'Joe''s Stone Crab Hash Browns', 185, 3.0, 22.0, 10.0,
 2.0, 0.5, 200, NULL,
 'joes_stone_crab', ARRAY['joes hash browns', 'joes stone crab potatoes'],
 'sides', 'Joe''s Stone Crab', 1, '~370 cal per 200g side.', TRUE,
 350, 5, 2.0, 0.1, 450, 10, 0.6, 0, 8.0, 0, 22, 0.3, 55, 2.0, 0.01),

('joes_coleslaw', 'Joe''s Stone Crab Coleslaw', 110, 1.0, 12.0, 7.0,
 1.5, 8.0, 150, NULL,
 'joes_stone_crab', ARRAY['joes coleslaw', 'joes stone crab slaw'],
 'sides', 'Joe''s Stone Crab', 1, '~165 cal per 150g side.', TRUE,
 200, 5, 1.0, 0.0, 150, 25, 0.3, 10, 15.0, 0, 8, 0.2, 20, 1.0, 0.03),

('joes_creamed_spinach', 'Joe''s Stone Crab Creamed Spinach', 130, 4.5, 5.5, 10.0,
 1.5, 1.5, 200, NULL,
 'joes_stone_crab', ARRAY['joes spinach', 'joes stone crab creamed spinach'],
 'sides', 'Joe''s Stone Crab', 1, '~260 cal per 200g side.', TRUE,
 400, 25, 6.0, 0.1, 350, 120, 2.0, 350, 15.0, 5, 50, 0.6, 60, 3.0, 0.05),

-- ============================================================================
-- FRANKLIN BARBECUE
-- ============================================================================

('franklin_brisket_moist', 'Franklin Barbecue Brisket (Moist/Fatty)', 280, 20.0, 0.0, 22.0,
 0.0, 0.0, 170, NULL,
 'franklin_bbq', ARRAY['franklin bbq brisket moist', 'franklin brisket fatty', 'franklin barbecue moist brisket'],
 'bbq', 'Franklin Barbecue', 1, '~476 cal per 6oz (170g) serving. 14-hour post oak smoked.', TRUE,
 65, 85, 9.0, 0.6, 310, 10, 2.5, 0, 0.0, 6, 20, 6.0, 190, 22.0, 0.03),

('franklin_brisket_lean', 'Franklin Barbecue Brisket (Lean)', 210, 24.0, 0.0, 12.5,
 0.0, 0.0, 170, NULL,
 'franklin_bbq', ARRAY['franklin bbq brisket lean', 'franklin brisket lean', 'franklin barbecue lean brisket'],
 'bbq', 'Franklin Barbecue', 1, '~357 cal per 6oz (170g) serving. Leaner flat cut.', TRUE,
 60, 78, 5.0, 0.4, 320, 10, 2.5, 0, 0.0, 6, 20, 5.5, 190, 22.0, 0.02),

('franklin_pulled_pork', 'Franklin Barbecue Pulled Pork', 220, 20.0, 2.0, 14.5,
 0.0, 1.5, 170, NULL,
 'franklin_bbq', ARRAY['franklin bbq pulled pork', 'franklin pork'],
 'bbq', 'Franklin Barbecue', 1, '~374 cal per 6oz (170g) serving.', TRUE,
 65, 80, 5.5, 0.1, 310, 15, 1.2, 3, 0.0, 10, 22, 3.2, 190, 28.0, 0.01),

('franklin_pork_ribs', 'Franklin Barbecue Pork Ribs', 260, 18.0, 3.0, 20.0,
 0.0, 2.5, 300, NULL,
 'franklin_bbq', ARRAY['franklin bbq ribs', 'franklin pork ribs', 'franklin spare ribs'],
 'bbq', 'Franklin Barbecue', 1, '~780 cal per half rack (300g).', TRUE,
 70, 80, 7.5, 0.3, 280, 25, 1.5, 3, 0.0, 8, 18, 3.5, 170, 18.0, 0.02),

('franklin_pork_sausage', 'Franklin Barbecue Pork Sausage', 290, 14.0, 2.0, 25.0,
 0.0, 0.5, 130, 130,
 'franklin_bbq', ARRAY['franklin bbq sausage', 'franklin sausage link'],
 'bbq', 'Franklin Barbecue', 1, '~377 cal per link (130g). House-made pork and beef sausage.', TRUE,
 750, 70, 9.0, 0.1, 260, 12, 1.5, 0, 1.0, 5, 16, 2.8, 150, 16.0, 0.02),

('franklin_turkey_breast', 'Franklin Barbecue Turkey Breast', 155, 24.0, 0.0, 6.5,
 0.0, 0.0, 170, NULL,
 'franklin_bbq', ARRAY['franklin bbq turkey', 'franklin smoked turkey'],
 'bbq', 'Franklin Barbecue', 1, '~264 cal per 6oz (170g) serving.', TRUE,
 52, 76, 1.8, 0.0, 293, 14, 1.4, 0, 0.0, 5, 27, 1.7, 230, 30.0, 0.01),

('franklin_potato_salad', 'Franklin Barbecue Potato Salad', 130, 2.0, 14.0, 7.5,
 1.0, 2.0, 170, NULL,
 'franklin_bbq', ARRAY['franklin bbq potato salad'],
 'sides', 'Franklin Barbecue', 1, '~221 cal per 170g side.', TRUE,
 350, 15, 1.5, 0.0, 300, 15, 0.5, 5, 5.0, 0, 15, 0.3, 40, 1.0, 0.02),

('franklin_pinto_beans', 'Franklin Barbecue Pinto Beans', 100, 5.0, 16.0, 1.5,
 5.0, 1.5, 170, NULL,
 'franklin_bbq', ARRAY['franklin bbq beans', 'franklin pinto beans'],
 'sides', 'Franklin Barbecue', 1, '~170 cal per 170g side.', TRUE,
 380, 5, 0.3, 0.0, 400, 40, 2.0, 0, 1.0, 0, 45, 0.8, 120, 2.0, 0.02),

-- ============================================================================
-- COMMANDER'S PALACE
-- ============================================================================

('commanders_turtle_soup', 'Commander''s Palace Turtle Soup', 100, 8.0, 6.0, 5.0,
 0.5, 1.0, 300, NULL,
 'commanders_palace', ARRAY['commanders palace turtle soup', 'commanders turtle soup'],
 'american', 'Commander''s Palace', 1, '~300 cal per 300g bowl. Signature turtle soup with sherry.', TRUE,
 580, 35, 2.0, 0.0, 250, 30, 2.5, 30, 3.0, 5, 20, 2.0, 120, 15.0, 0.03),

('commanders_bread_pudding', 'Commander''s Palace Bread Pudding Soufflé', 295, 5.0, 38.0, 14.0,
 0.5, 25.0, 250, NULL,
 'commanders_palace', ARRAY['commanders palace bread pudding', 'commanders souffle'],
 'dessert', 'Commander''s Palace', 1, '~738 cal per 250g serving. Legendary bread pudding soufflé with whiskey sauce.', TRUE,
 240, 80, 7.5, 0.1, 130, 55, 1.0, 60, 0.5, 8, 12, 0.5, 70, 8.0, 0.02),

('commanders_pecan_fish', 'Commander''s Palace Pecan-Crusted Gulf Fish', 210, 18.0, 8.0, 12.0,
 1.5, 1.0, 280, NULL,
 'commanders_palace', ARRAY['commanders palace pecan fish', 'commanders pecan crusted fish'],
 'seafood', 'Commander''s Palace', 1, '~588 cal per 280g serving. Gulf fish with pecan crust and meuniere sauce.', TRUE,
 380, 55, 2.5, 0.0, 350, 20, 1.0, 20, 2.0, 60, 35, 0.8, 220, 35.0, 0.25),

('commanders_pork_chop', 'Commander''s Palace Double-Cut Pork Chop', 215, 24.0, 3.0, 12.0,
 0.5, 2.0, 350, NULL,
 'commanders_palace', ARRAY['commanders palace pork chop'],
 'american', 'Commander''s Palace', 1, '~753 cal per 350g serving.', TRUE,
 350, 75, 4.5, 0.0, 365, 20, 0.8, 2, 1.0, 11, 26, 2.0, 225, 34.0, 0.01),

('commanders_cochon_de_lait', 'Commander''s Palace Cochon de Lait', 230, 18.0, 5.0, 15.5,
 0.5, 3.0, 250, NULL,
 'commanders_palace', ARRAY['commanders palace cochon de lait', 'commanders suckling pig'],
 'american', 'Commander''s Palace', 1, '~575 cal per 250g serving. Slow-roasted suckling pig.', TRUE,
 420, 70, 5.5, 0.1, 300, 15, 1.2, 3, 1.0, 10, 18, 3.0, 170, 25.0, 0.02),

('commanders_shrimp_tasso', 'Commander''s Palace Shrimp & Tasso Henican', 155, 14.0, 8.0, 7.5,
 0.5, 1.5, 300, NULL,
 'commanders_palace', ARRAY['commanders palace shrimp tasso', 'commanders shrimp henican'],
 'seafood', 'Commander''s Palace', 1, '~465 cal per 300g serving. Shrimp with tasso ham and five-pepper jelly.', TRUE,
 580, 130, 3.0, 0.0, 220, 35, 1.0, 20, 5.0, 5, 30, 1.5, 200, 28.0, 0.10),

('commanders_creole_bread_pudding', 'Commander''s Palace Creole Bread Pudding', 280, 5.0, 36.0, 13.0,
 0.5, 22.0, 200, NULL,
 'commanders_palace', ARRAY['commanders creole bread pudding'],
 'dessert', 'Commander''s Palace', 1, '~560 cal per 200g serving.', TRUE,
 250, 75, 7.0, 0.1, 120, 50, 1.0, 55, 0.5, 8, 12, 0.5, 65, 7.0, 0.02)

ON CONFLICT (food_name_normalized) DO NOTHING;
