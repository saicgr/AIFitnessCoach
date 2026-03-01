-- 322_overrides_frozen_meals.sql
-- Popular frozen meal brands: Lean Cuisine, Stouffer's, Amy's, Healthy Choice,
-- Marie Callender's, Banquet, Hot Pockets, Totino's, El Monterey.
-- Sources: nutritionvalue.org, fatsecret.com, calorieking.com, nutritionix.com,
-- eatthismuch.com, official brand sites (goodnes.com, amys.com, healthychoice.com,
-- mariecallendersmeals.com, banquet.com, totinos.com, elmonterey.com)

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ============================================================================
-- LEAN CUISINE
-- ============================================================================

-- Lean Cuisine Alfredo Pasta with Chicken & Broccoli: 280 cal per 283g tray
-- Per 100g: 99 cal, 7.1p, 13.8c, 1.8f
('lean_cuisine_chicken_alfredo', 'Lean Cuisine Chicken Alfredo', 99, 7.1, 13.8, 1.8,
 0.7, 1.4, 283, NULL,
 'lean_cuisine', ARRAY['lean cuisine alfredo pasta chicken broccoli', 'lean cuisine chicken alfredo', 'lean cuisine alfredo pasta'],
 'frozen_meals', 'Lean Cuisine', 1, '280 cal per 283g tray. Alfredo pasta with chicken and broccoli. Source: calorieking, myfooddiary.', TRUE),

-- Lean Cuisine Glazed Chicken: 260 cal per 225g tray
-- Per 100g: 116 cal, 5.3p, 20.0c, 1.8f
('lean_cuisine_glazed_chicken', 'Lean Cuisine Glazed Chicken', 116, 5.3, 20.0, 1.8,
 0.9, 8.9, 225, NULL,
 'lean_cuisine', ARRAY['lean cuisine glazed chicken', 'lean cuisine protein kick glazed chicken'],
 'frozen_meals', 'Lean Cuisine', 1, '260 cal per 225g tray. White meat chicken with rice, green beans, cashews in savory sauce. Source: eatthismuch.', TRUE),

-- Lean Cuisine Salisbury Steak with Mac & Cheese: 250 cal per 269g tray
-- Per 100g: 93 cal, 8.6p, 10.4c, 1.7f
('lean_cuisine_salisbury_steak', 'Lean Cuisine Salisbury Steak', 93, 8.6, 10.4, 1.7,
 0.7, 1.1, 269, NULL,
 'lean_cuisine', ARRAY['lean cuisine salisbury steak', 'lean cuisine salisbury steak mac cheese', 'lean cuisine protein kick salisbury steak'],
 'frozen_meals', 'Lean Cuisine', 1, '250 cal per 269g tray. Salisbury steak with macaroni and cheese. Source: goodnes.com, sparkpeople.', TRUE),

-- Lean Cuisine Spaghetti with Meat Sauce: 310 cal per 326g (11.5oz) package
-- Per 100g: 95 cal, 4.6p, 16.3c, 1.2f
('lean_cuisine_spaghetti_meat_sauce', 'Lean Cuisine Spaghetti with Meat Sauce', 95, 4.6, 16.3, 1.2,
 0.9, 2.5, 326, NULL,
 'lean_cuisine', ARRAY['lean cuisine spaghetti meat sauce', 'lean cuisine spaghetti', 'lean cuisine protein kick spaghetti'],
 'frozen_meals', 'Lean Cuisine', 1, '310 cal per 326g package. Spaghetti pasta with seasoned meat sauce. Source: nutritionvalue.org, nutritionix.', TRUE),

-- Lean Cuisine Vermont White Cheddar Mac & Cheese: 251 cal per 226g tray
-- Per 100g: 111 cal, 6.2p, 15.5c, 2.7f
('lean_cuisine_vermont_white_cheddar_mac', 'Lean Cuisine Vermont White Cheddar Mac & Cheese', 111, 6.2, 15.5, 2.7,
 0.4, 2.2, 226, NULL,
 'lean_cuisine', ARRAY['lean cuisine vermont white cheddar mac cheese', 'lean cuisine mac and cheese', 'lean cuisine white cheddar mac'],
 'frozen_meals', 'Lean Cuisine', 1, '251 cal per 226g tray. Organic cavatappi with Vermont white cheddar. Source: nutritionvalue.org.', TRUE),

-- Lean Cuisine Herb Roasted Chicken: 180 cal per 226g (8oz) tray
-- Per 100g: 80 cal, 8.0p, 7.1c, 2.0f
('lean_cuisine_herb_roasted_chicken', 'Lean Cuisine Herb Roasted Chicken', 80, 8.0, 7.1, 2.0,
 0.9, 1.8, 226, NULL,
 'lean_cuisine', ARRAY['lean cuisine herb roasted chicken', 'lean cuisine protein kick herb roasted chicken', 'lean cuisine roasted chicken'],
 'frozen_meals', 'Lean Cuisine', 1, '180 cal per 226g tray. White meat chicken, roasted potatoes, broccoli, red peppers. Source: myfooddiary, fatsecret.', TRUE),

-- Lean Cuisine Sweet & Sour Chicken: 330 cal per 283g (10oz) package
-- Per 100g: 117 cal, 4.6p, 20.1c, 1.8f
('lean_cuisine_sweet_sour_chicken', 'Lean Cuisine Sweet & Sour Chicken', 117, 4.6, 20.1, 1.8,
 0.7, 6.7, 283, NULL,
 'lean_cuisine', ARRAY['lean cuisine sweet and sour chicken', 'lean cuisine sweet sour chicken', 'lean cuisine protein kick sweet sour chicken'],
 'frozen_meals', 'Lean Cuisine', 1, '330 cal per 283g package. Sweet and sour chicken with rice. Source: eatthismuch, fatsecret.', TRUE),

-- ============================================================================
-- STOUFFER''S
-- ============================================================================

-- Stouffer's Lasagna with Meat & Sauce: 260 cal per 198g (1 cup) serving; single 10.5oz = 298g
-- Per 100g: 131 cal, 8.6p, 14.1c, 4.5f
('stouffers_lasagna_meat_sauce', 'Stouffer''s Lasagna with Meat & Sauce', 131, 8.6, 14.1, 4.5,
 2.0, 2.4, 298, NULL,
 'stouffers', ARRAY['stouffers lasagna', 'stouffers lasagna meat sauce', 'stouffers classics lasagna'],
 'frozen_meals', 'Stouffer''s', 1, '~390 cal per 298g (10.5oz) package. Layers of pasta, meat, ricotta, mozzarella. Source: eatthismuch, fatsecret.', TRUE),

-- Stouffer's Mac & Cheese: 141 cal/100g. Single 12oz (340g) = ~480 cal
-- Per 100g: 141 cal, 5.9p, 15.3c, 6.5f
('stouffers_mac_cheese', 'Stouffer''s Mac & Cheese', 141, 5.9, 15.3, 6.5,
 0.6, 1.8, 340, NULL,
 'stouffers', ARRAY['stouffers mac and cheese', 'stouffers macaroni cheese', 'stouffers classic mac cheese'],
 'frozen_meals', 'Stouffer''s', 1, '~480 cal per 340g (12oz) tray. Creamy cheddar cheese sauce with elbow macaroni. Source: nutritionvalue.org.', TRUE),

-- Stouffer's Chicken Alfredo (Fettuccini): 460 cal per 298g (10.5oz) package
-- Per 100g: 154 cal, 7.4p, 11.7c, 8.7f
('stouffers_chicken_alfredo', 'Stouffer''s Chicken Alfredo', 154, 7.4, 11.7, 8.7,
 1.3, 2.0, 298, NULL,
 'stouffers', ARRAY['stouffers chicken alfredo', 'stouffers chicken fettuccini alfredo', 'stouffers classics chicken alfredo'],
 'frozen_meals', 'Stouffer''s', 1, '460 cal per 298g (10.5oz) package. Grilled chicken, broccoli, fettuccini in alfredo sauce. Source: myfooddiary, gardengrocer.', TRUE),

-- Stouffer's Classic Meatloaf: 290 cal per 280g (9.875oz) package
-- Per 100g: 104 cal, 7.9p, 8.9c, 4.3f
('stouffers_meatloaf', 'Stouffer''s Meatloaf', 104, 7.9, 8.9, 4.3,
 0.7, 2.1, 280, NULL,
 'stouffers', ARRAY['stouffers meatloaf', 'stouffers classic meatloaf', 'stouffers meatloaf mashed potatoes'],
 'frozen_meals', 'Stouffer''s', 1, '290 cal per 280g package. Ketchup-glazed meatloaf with mashed potatoes in gravy. Source: instacart, kroger.', TRUE),

-- Stouffer's Stuffed Peppers: 180 cal per 283g (10oz) package
-- Per 100g: 64 cal, 2.8p, 7.4c, 2.8f
('stouffers_stuffed_peppers', 'Stouffer''s Stuffed Peppers', 64, 2.8, 7.4, 2.8,
 0.7, 2.5, 283, NULL,
 'stouffers', ARRAY['stouffers stuffed peppers', 'stouffers stuffed bell peppers', 'stouffers classics stuffed peppers'],
 'frozen_meals', 'Stouffer''s', 1, '180 cal per 283g package. Green bell peppers with beef and rice in tomato sauce. Source: calorieking, nutritionix.', TRUE),

-- Stouffer's Salisbury Steak: 310 cal per 273g (9.625oz) tray
-- Per 100g: 114 cal, 6.2p, 8.8c, 5.1f
('stouffers_salisbury_steak', 'Stouffer''s Salisbury Steak', 114, 6.2, 8.8, 5.1,
 0.7, 1.5, 273, NULL,
 'stouffers', ARRAY['stouffers salisbury steak', 'stouffers salisbury steak mac cheese', 'stouffers classics salisbury steak'],
 'frozen_meals', 'Stouffer''s', 1, '310 cal per 273g tray. Salisbury steak with macaroni and cheese. Source: amazon, carbmanager.', TRUE),

-- Stouffer's French Bread Pizza Pepperoni: 401 cal per 159g piece
-- Per 100g: 252 cal, 9.4p, 24.5c, 12.6f
('stouffers_french_bread_pizza_pepperoni', 'Stouffer''s French Bread Pizza Pepperoni', 252, 9.4, 24.5, 12.6,
 1.3, 2.5, 159, 159,
 'stouffers', ARRAY['stouffers french bread pizza pepperoni', 'stouffers pepperoni french bread pizza'],
 'frozen_meals', 'Stouffer''s', 1, '401 cal per 159g piece. Pepperoni pizza on French bread. Source: nutritionvalue.org.', TRUE),

-- Stouffer's French Bread Pizza Deluxe: 410 cal per 175g piece
-- Per 100g: 234 cal, 8.0p, 22.9c, 12.0f
('stouffers_french_bread_pizza_deluxe', 'Stouffer''s French Bread Pizza Deluxe', 234, 8.0, 22.9, 12.0,
 1.7, 2.9, 175, 175,
 'stouffers', ARRAY['stouffers french bread pizza deluxe', 'stouffers deluxe french bread pizza'],
 'frozen_meals', 'Stouffer''s', 1, '410 cal per 175g piece. Sausage, pepperoni, mushrooms, peppers on French bread. Source: nutritionvalue.org.', TRUE),

-- ============================================================================
-- AMY''S
-- ============================================================================

-- Amy's Mac & Cheese: 450 cal per 255g (9oz) tray
-- Per 100g: 176 cal, 7.1p, 21.6c, 7.1f
('amys_mac_cheese', 'Amy''s Mac & Cheese', 176, 7.1, 21.6, 7.1,
 1.2, 2.0, 255, NULL,
 'amys', ARRAY['amys mac and cheese', 'amys macaroni cheese', 'amys organic mac cheese'],
 'frozen_meals', 'Amy''s', 1, '450 cal per 255g tray. Organic elbow macaroni with white cheddar cheese. Source: amys.com, calorieking.', TRUE),

-- Amy's Cheese Enchilada (Whole Meal): 360 cal per 255g (9oz) tray
-- Per 100g: 141 cal, 6.3p, 15.3c, 6.3f
('amys_cheese_enchilada', 'Amy''s Cheese Enchilada', 141, 6.3, 15.3, 6.3,
 2.4, 2.4, 255, NULL,
 'amys', ARRAY['amys cheese enchilada', 'amys cheese enchilada meal', 'amys enchilada whole meal'],
 'frozen_meals', 'Amy''s', 1, '360 cal per 255g tray. Cheese enchiladas with black beans and corn. Gluten free. Source: amys.com, amazon.', TRUE),

-- Amy's Bean & Rice Burrito: 310 cal per 170g burrito
-- Per 100g: 182 cal, 5.9p, 28.2c, 5.3f
('amys_bean_rice_burrito', 'Amy''s Bean & Rice Burrito', 182, 5.9, 28.2, 5.3,
 2.4, 1.2, 170, 170,
 'amys', ARRAY['amys bean rice burrito', 'amys bean and rice burrito', 'amys organic burrito'],
 'frozen_meals', 'Amy''s', 1, '310 cal per 170g burrito. Non-dairy bean and rice burrito. Source: fatsecret.ca, amys.com.', TRUE),

-- Amy's Pad Thai: 410 cal per 269g (9.5oz) tray
-- Per 100g: 152 cal, 4.5p, 25.3c, 3.7f
('amys_pad_thai', 'Amy''s Pad Thai', 152, 4.5, 25.3, 3.7,
 1.1, 8.6, 269, NULL,
 'amys', ARRAY['amys pad thai', 'amys thai pad thai', 'amys organic pad thai'],
 'frozen_meals', 'Amy''s', 1, '410 cal per 269g tray. Organic rice noodles with tofu, veggies. Gluten free, vegan. Source: amys.com, calorieking.', TRUE),

-- Amy's Margherita Pizza: 280 cal per 1/3 pizza (123g). Full pizza ~369g = 839 cal
-- Per 100g: 227 cal, 8.1p, 25.2c, 10.6f
('amys_margherita_pizza', 'Amy''s Margherita Pizza', 227, 8.1, 25.2, 10.6,
 1.6, 3.3, 369, NULL,
 'amys', ARRAY['amys margherita pizza', 'amys organic margherita pizza', 'amys thin crust pizza'],
 'frozen_meals', 'Amy''s', 1, '839 cal per full 369g pizza. Thin crust with mozzarella, tomatoes, basil. Source: eatthismuch, calorieking.', TRUE),

-- Amy's Broccoli & Cheddar Bake Bowl: 460 cal per 269g (9.5oz) bowl
-- Per 100g: 171 cal, 6.7p, 19.0c, 7.4f
('amys_broccoli_cheddar_bake', 'Amy''s Broccoli & Cheddar Bake', 171, 6.7, 19.0, 7.4,
 1.1, 1.9, 269, NULL,
 'amys', ARRAY['amys broccoli cheddar bake', 'amys broccoli cheddar bake bowl', 'amys broccoli cheddar bowl'],
 'frozen_meals', 'Amy''s', 1, '460 cal per 269g bowl. Broccoli and rice pasta in cheddar cheese sauce. Gluten free. Source: fatsecret, calorieking.', TRUE),

-- Amy's Country Cheddar Bowl: 460 cal per 269g (9.5oz) bowl
-- Per 100g: 171 cal, 6.3p, 16.7c, 8.6f
('amys_country_cheddar_bowl', 'Amy''s Country Cheddar Bowl', 171, 6.3, 16.7, 8.6,
 1.5, 1.1, 269, NULL,
 'amys', ARRAY['amys country cheddar bowl', 'amys country cheddar', 'amys cheddar bowl'],
 'frozen_meals', 'Amy''s', 1, '460 cal per 269g bowl. Potatoes, carrots, broccoli in cheddar sauce. Source: eatthismuch, fatsecret.', TRUE),

-- ============================================================================
-- HEALTHY CHOICE
-- ============================================================================

-- Healthy Choice Simply Steamers Grilled Chicken & Broccoli Alfredo: 190 cal per 259g (9.15oz)
-- Per 100g: 73 cal, 10.8p, 3.1c, 1.9f
('healthy_choice_chicken_alfredo', 'Healthy Choice Simply Steamers Chicken Alfredo', 73, 10.8, 3.1, 1.9,
 1.5, 0.8, 259, NULL,
 'healthy_choice', ARRAY['healthy choice simply steamers chicken alfredo', 'healthy choice chicken broccoli alfredo', 'healthy choice grilled chicken alfredo'],
 'frozen_meals', 'Healthy Choice', 1, '190 cal per 259g meal. Grilled chicken breast and broccoli in alfredo sauce. Source: fatsecret, walmart.', TRUE),

-- Healthy Choice Grilled Chicken Marinara: 280 cal per 269g (9.5oz)
-- Per 100g: 104 cal, 7.8p, 13.4c, 1.9f
('healthy_choice_grilled_chicken_marinara', 'Healthy Choice Grilled Chicken Marinara', 104, 7.8, 13.4, 1.9,
 1.5, 2.2, 269, NULL,
 'healthy_choice', ARRAY['healthy choice grilled chicken marinara', 'healthy choice chicken marinara parmesan', 'healthy choice cafe steamers chicken marinara'],
 'frozen_meals', 'Healthy Choice', 1, '280 cal per 269g meal. Chicken, penne, broccoli in marinara with parmesan. Source: fatsecret, mynetdiary.', TRUE),

-- Healthy Choice Power Bowls Chicken Feta & Farro: 310 cal per 269g (9.5oz)
-- Per 100g: 115 cal, 8.6p, 12.6c, 3.3f
('healthy_choice_chicken_feta_farro', 'Healthy Choice Power Bowls Chicken Feta & Farro', 115, 8.6, 12.6, 3.3,
 2.2, 0.7, 269, NULL,
 'healthy_choice', ARRAY['healthy choice power bowls chicken feta farro', 'healthy choice chicken feta farro', 'healthy choice power bowl feta'],
 'frozen_meals', 'Healthy Choice', 1, '310 cal per 269g bowl. Pulled chicken, chickpeas, leafy greens, farro, feta. Source: healthychoice.com, eatthismuch.', TRUE),

-- Healthy Choice Power Bowls Adobo Chicken: 330 cal per 276g (9.75oz)
-- Per 100g: 120 cal, 9.4p, 13.8c, 3.3f
('healthy_choice_adobo_chicken', 'Healthy Choice Power Bowls Adobo Chicken', 120, 9.4, 13.8, 3.3,
 2.9, 1.4, 276, NULL,
 'healthy_choice', ARRAY['healthy choice power bowls adobo chicken', 'healthy choice adobo chicken', 'healthy choice protein bowl adobo'],
 'frozen_meals', 'Healthy Choice', 1, '330 cal per 276g bowl. Chicken with corn, peppers, kale, quinoa, rice. Source: healthychoice.com, mynetdiary.', TRUE),

-- ============================================================================
-- MARIE CALLENDER''S
-- ============================================================================

-- Marie Callender's Chicken Pot Pie: 610 cal per 283g (10oz) pie
-- Per 100g: 216 cal, 6.0p, 21.6c, 11.3f
('marie_callenders_chicken_pot_pie', 'Marie Callender''s Chicken Pot Pie', 216, 6.0, 21.6, 11.3,
 1.4, 2.1, 283, 283,
 'marie_callenders', ARRAY['marie callenders chicken pot pie', 'marie callender chicken pot pie', 'marie callenders pot pie chicken'],
 'frozen_meals', 'Marie Callender''s', 1, '610 cal per 283g (10oz) pie. White meat chicken in flaky crust. Source: calorieking, carbmanager.', TRUE),

-- Marie Callender's Turkey Pot Pie: 580 cal per 283g (10oz) pie
-- Per 100g: 205 cal, 6.0p, 20.1c, 11.0f
('marie_callenders_turkey_pot_pie', 'Marie Callender''s Turkey Pot Pie', 205, 6.0, 20.1, 11.0,
 1.4, 2.1, 283, 283,
 'marie_callenders', ARRAY['marie callenders turkey pot pie', 'marie callender turkey pot pie', 'marie callenders pot pie turkey'],
 'frozen_meals', 'Marie Callender''s', 1, '580 cal per 283g (10oz) pie. Turkey in flaky crust. Source: eatthismuch, calorieking.', TRUE),

-- Marie Callender's Herb Roasted Chicken: 450 cal per 397g (14oz) dinner
-- Per 100g: 113 cal, 7.8p, 10.8c, 4.0f
('marie_callenders_herb_roasted_chicken', 'Marie Callender''s Herb Roasted Chicken', 113, 7.8, 10.8, 4.0,
 1.0, 0.8, 397, NULL,
 'marie_callenders', ARRAY['marie callenders herb roasted chicken', 'marie callender herb roasted chicken dinner'],
 'frozen_meals', 'Marie Callender''s', 1, '450 cal per 397g (14oz) dinner. Herb roasted chicken with potatoes and vegetables. Source: kroger, instacart.', TRUE),

-- Marie Callender's Country Fried Steak: 570 cal per 425g (15oz) dinner
-- Per 100g: 134 cal, 3.8p, 11.5c, 7.3f
('marie_callenders_country_fried_steak', 'Marie Callender''s Country Fried Steak', 134, 3.8, 11.5, 7.3,
 0.9, 1.2, 425, NULL,
 'marie_callenders', ARRAY['marie callenders country fried steak', 'marie callender country fried beef steak', 'marie callenders country fried steak gravy'],
 'frozen_meals', 'Marie Callender''s', 1, '570 cal per 425g (15oz) dinner. Breaded beef steak with gravy, potatoes, mac & cheese. Source: instacart, heb.', TRUE),

-- Marie Callender's Fettuccini Alfredo: 450 cal per 320g (11.3oz) bowl
-- Per 100g: 141 cal, 5.3p, 16.9c, 5.6f
('marie_callenders_fettuccini_alfredo', 'Marie Callender''s Fettuccini Alfredo', 141, 5.3, 16.9, 5.6,
 0.9, 0.9, 320, NULL,
 'marie_callenders', ARRAY['marie callenders fettuccini alfredo', 'marie callender four cheese fettuccini alfredo', 'marie callenders alfredo bowl'],
 'frozen_meals', 'Marie Callender''s', 1, '450 cal per 320g bowl. Four cheese fettuccini alfredo. Source: kroger, qfc.', TRUE),

-- ============================================================================
-- BANQUET
-- ============================================================================

-- Banquet Fried Chicken Meal (individual classic dinner): ~330 cal per 119g piece (box variety)
-- Classic meal ~286g tray (10.1oz) = 309 cal
-- Per 100g: 108 cal, 3.8p, 14.0c, 4.9f
('banquet_fried_chicken_meal', 'Banquet Fried Chicken Meal', 108, 3.8, 14.0, 4.9,
 1.4, 1.0, 286, NULL,
 'banquet', ARRAY['banquet fried chicken meal', 'banquet chicken fried chicken meal', 'banquet classic fried chicken dinner'],
 'frozen_meals', 'Banquet', 1, '309 cal per 286g (10.1oz) tray. Breaded chicken with mashed potatoes and corn. Source: myfooddata, myfooddiary.', TRUE),

-- Banquet Salisbury Steak: 350 cal per 337g (11.88oz) meal
-- Per 100g: 104 cal, 3.6p, 10.7c, 5.0f
('banquet_salisbury_steak', 'Banquet Salisbury Steak', 104, 3.6, 10.7, 5.0,
 1.2, 3.3, 337, NULL,
 'banquet', ARRAY['banquet salisbury steak', 'banquet salisbury steak meal', 'banquet classic salisbury steak'],
 'frozen_meals', 'Banquet', 1, '350 cal per 337g meal. Salisbury steak with mashed potatoes and cinnamon apple dessert. Source: heb, conagrafoodservice.', TRUE),

-- Banquet Chicken Pot Pie: 380 cal per 198g (7oz) pie
-- Per 100g: 192 cal, 5.6p, 18.2c, 10.6f
('banquet_chicken_pot_pie', 'Banquet Chicken Pot Pie', 192, 5.6, 18.2, 10.6,
 1.5, 3.0, 198, 198,
 'banquet', ARRAY['banquet chicken pot pie', 'banquet pot pie chicken'],
 'frozen_meals', 'Banquet', 1, '380 cal per 198g (7oz) pie. Chicken pot pie with flaky crust. Source: eatthismuch, calorieking.', TRUE),

-- Banquet Turkey Pot Pie: 320 cal per 198g (7oz) pie
-- Per 100g: 162 cal, 5.1p, 15.7c, 9.1f
('banquet_turkey_pot_pie', 'Banquet Turkey Pot Pie', 162, 5.1, 15.7, 9.1,
 1.0, 1.5, 198, 198,
 'banquet', ARRAY['banquet turkey pot pie', 'banquet pot pie turkey'],
 'frozen_meals', 'Banquet', 1, '320 cal per 198g (7oz) pie. Turkey pot pie with flaky crust. Source: eatthismuch.', TRUE),

-- Banquet Beef Pot Pie: 380 cal per 198g (7oz) pie
-- Per 100g: 192 cal, 5.6p, 18.2c, 10.6f (similar profile to chicken)
('banquet_beef_pot_pie', 'Banquet Beef Pot Pie', 192, 5.6, 18.2, 10.6,
 1.4, 1.0, 198, 198,
 'banquet', ARRAY['banquet beef pot pie', 'banquet pot pie beef'],
 'frozen_meals', 'Banquet', 1, '380 cal per 198g (7oz) pie. Beef pot pie with flaky crust. Source: inlivo, calorieking.', TRUE),

-- Banquet Mega Bowls Country Fried Chicken: 450 cal per 396g (14oz) bowl
-- Per 100g: 114 cal, 4.8p, 12.4c, 5.1f
('banquet_mega_bowls_fried_chicken', 'Banquet Mega Bowls Fried Chicken', 114, 4.8, 12.4, 5.1,
 1.3, 0.8, 396, NULL,
 'banquet', ARRAY['banquet mega bowls fried chicken', 'banquet mega bowls country fried chicken', 'banquet mega bowl chicken'],
 'frozen_meals', 'Banquet', 1, '450 cal per 396g bowl. Chicken fritters, mashed potatoes, gravy, corn, cheese. Source: eatthismuch, fatsecret.', TRUE),

-- ============================================================================
-- HOT POCKETS
-- ============================================================================

-- Hot Pockets Pepperoni Pizza: 335 cal per 127g (1 pocket, from 2-pack = 670 cal/255g)
-- Per 100g: 263 cal, 7.8p, 28.6c, 12.9f
('hot_pockets_pepperoni_pizza', 'Hot Pockets Pepperoni Pizza', 263, 7.8, 28.6, 12.9,
 1.2, 2.7, 127, 127,
 'hot_pockets', ARRAY['hot pockets pepperoni pizza', 'hot pocket pepperoni', 'hot pockets pepperoni'],
 'frozen_meals', 'Hot Pockets', 1, '335 cal per 127g pocket. Pepperoni pizza in a crispy crust. Source: eatthismuch, nutritionix.', TRUE),

-- Hot Pockets Ham & Cheese: 270 cal/100g based on nutritionvalue.org. Per pocket (127g) = 343 cal
-- Per 100g: 270 cal, 9.2p, 24.7c, 15.0f
('hot_pockets_ham_cheese', 'Hot Pockets Ham & Cheese', 270, 9.2, 24.7, 15.0,
 1.5, 7.6, 127, 127,
 'hot_pockets', ARRAY['hot pockets ham and cheese', 'hot pockets ham cheese', 'hot pocket ham cheese'],
 'frozen_meals', 'Hot Pockets', 1, '343 cal per 127g pocket. Ham and cheese in seasoned crust. Source: nutritionvalue.org.', TRUE),

-- Hot Pockets Four Cheese Pizza: 270 cal per 120g pocket
-- Per 100g: 225 cal, 7.5p, 31.7c, 8.3f
('hot_pockets_four_cheese_pizza', 'Hot Pockets Four Cheese Pizza', 225, 7.5, 31.7, 8.3,
 0.8, 3.3, 120, 120,
 'hot_pockets', ARRAY['hot pockets four cheese pizza', 'hot pocket four cheese', 'hot pockets cheese pizza'],
 'frozen_meals', 'Hot Pockets', 1, '270 cal per 120g pocket. Four cheese pizza in Italian seasoned crust. Source: fatsecret.', TRUE),

-- Hot Pockets Philly Steak & Cheese: 300 cal per 127g pocket
-- Per 100g: 236 cal, 6.3p, 32.3c, 8.7f
('hot_pockets_philly_steak_cheese', 'Hot Pockets Philly Steak & Cheese', 236, 6.3, 32.3, 8.7,
 0.8, 3.1, 127, 127,
 'hot_pockets', ARRAY['hot pockets philly steak cheese', 'hot pocket philly cheesesteak', 'hot pockets steak cheese'],
 'frozen_meals', 'Hot Pockets', 1, '300 cal per 127g pocket. Philly steak and cheese in seasoned crust. Source: fatsecret.', TRUE),

-- Hot Pockets Meatball Mozzarella: 320 cal per 127g pocket
-- Per 100g: 252 cal, 9.3p, 30.7c, 10.2f
('hot_pockets_meatball_mozzarella', 'Hot Pockets Meatball Mozzarella', 252, 9.3, 30.7, 10.2,
 2.2, 7.7, 127, 127,
 'hot_pockets', ARRAY['hot pockets meatball mozzarella', 'hot pocket meatball', 'hot pockets italian meatball mozzarella'],
 'frozen_meals', 'Hot Pockets', 1, '320 cal per 127g pocket. Italian style meatballs and mozzarella in garlic crust. Source: nutritionvalue.org.', TRUE),

-- ============================================================================
-- TOTINO''S
-- ============================================================================

-- Totino's Party Pizza Pepperoni: 329 cal per 1/2 pizza (139g). Full pizza ~278g = 658 cal
-- Per 100g: 236 cal, 7.2p, 26.6c, 11.5f
('totinos_party_pizza_pepperoni', 'Totino''s Party Pizza Pepperoni', 236, 7.2, 26.6, 11.5,
 1.4, 2.9, 278, NULL,
 'totinos', ARRAY['totinos party pizza pepperoni', 'totinos pepperoni pizza', 'totinos classic pepperoni'],
 'frozen_meals', 'Totino''s', 1, '658 cal per full 278g pizza. Thin crust pepperoni party pizza. Source: nutritionvalue.org.', TRUE),

-- Totino's Party Pizza Cheese: 338 cal per 1/2 pizza (~139g). Full pizza ~278g = 676 cal
-- Per 100g: 243 cal, 5.8p, 28.1c, 12.2f
('totinos_party_pizza_cheese', 'Totino''s Party Pizza Cheese', 243, 5.8, 28.1, 12.2,
 1.4, 3.2, 278, NULL,
 'totinos', ARRAY['totinos party pizza cheese', 'totinos cheese pizza', 'totinos triple cheese party pizza'],
 'frozen_meals', 'Totino''s', 1, '676 cal per full 278g pizza. Thin crust cheese party pizza. Source: myfooddiary, calorieking.', TRUE),

-- Totino's Party Pizza Combination: 370 cal per 1/2 pizza (~152g). Full pizza ~303g = 740 cal
-- Per 100g: 244 cal, 5.9p, 25.7c, 12.5f
('totinos_party_pizza_combination', 'Totino''s Party Pizza Combination', 244, 5.9, 25.7, 12.5,
 1.3, 2.5, 303, NULL,
 'totinos', ARRAY['totinos party pizza combination', 'totinos combo pizza', 'totinos combination party pizza'],
 'frozen_meals', 'Totino''s', 1, '740 cal per full 303g (10.7oz) pizza. Sausage, pepperoni, cheese combination. Source: totinos.com, calorieking.', TRUE),

-- Totino's Pizza Rolls Pepperoni: 200 cal per 6 rolls (85g)
-- Per 100g: 235 cal, 7.1p, 35.3c, 9.4f
('totinos_pizza_rolls_pepperoni', 'Totino''s Pizza Rolls Pepperoni', 235, 7.1, 35.3, 9.4,
 1.2, 2.4, 85, 14,
 'totinos', ARRAY['totinos pizza rolls pepperoni', 'totinos pepperoni pizza rolls', 'totino pizza rolls'],
 'frozen_meals', 'Totino''s', 6, '200 cal per 6 rolls (85g). Pepperoni pizza filling in crispy crust. Source: calorieking, fatsecret.', TRUE),

-- Totino's Pizza Rolls Cheese: 210 cal per 6 rolls (85g)
-- Per 100g: 247 cal, 7.1p, 34.1c, 9.4f
('totinos_pizza_rolls_cheese', 'Totino''s Pizza Rolls Cheese', 247, 7.1, 34.1, 9.4,
 1.2, 2.4, 85, 14,
 'totinos', ARRAY['totinos pizza rolls cheese', 'totinos cheese pizza rolls', 'totinos triple cheese pizza rolls'],
 'frozen_meals', 'Totino''s', 6, '210 cal per 6 rolls (85g). Cheese pizza filling in crispy crust. Source: fatsecret, myfooddiary.', TRUE),

-- Totino's Pizza Rolls Combination (Triple Meat): 200 cal per 6 rolls (85g)
-- Per 100g: 235 cal, 8.2p, 31.8c, 8.2f
('totinos_pizza_rolls_combination', 'Totino''s Pizza Rolls Combination', 235, 8.2, 31.8, 8.2,
 1.2, 2.4, 85, 14,
 'totinos', ARRAY['totinos pizza rolls combination', 'totinos combo pizza rolls', 'totinos triple meat pizza rolls'],
 'frozen_meals', 'Totino''s', 6, '200 cal per 6 rolls (85g). Triple meat pizza filling in crispy crust. Source: totinos.com, nutritionix.', TRUE),

-- ============================================================================
-- EL MONTEREY
-- ============================================================================

-- El Monterey Beef & Bean Burrito: 561 cal per 227g burrito
-- Per 100g: 247 cal, 7.0p, 28.2c, 11.9f
('el_monterey_beef_bean_burrito', 'El Monterey Beef & Bean Burrito', 247, 7.0, 28.2, 11.9,
 2.2, 0.4, 142, 142,
 'el_monterey', ARRAY['el monterey beef bean burrito', 'el monterey beef and bean burrito', 'el monterey burrito'],
 'frozen_meals', 'El Monterey', 1, '350 cal per 142g burrito. Seasoned beef and beans in a flour tortilla. Source: nutritionvalue.org.', TRUE),

-- El Monterey Chicken & Cheese Chimichanga: 290 cal per 142g chimichanga
-- Per 100g: 204 cal, 7.7p, 26.1c, 7.0f
('el_monterey_chicken_cheese_chimichanga', 'El Monterey Chicken & Cheese Chimichanga', 204, 7.7, 26.1, 7.0,
 1.4, 1.4, 142, 142,
 'el_monterey', ARRAY['el monterey chicken cheese chimichanga', 'el monterey chicken chimichanga', 'el monterey chicken monterey jack chimichanga'],
 'frozen_meals', 'El Monterey', 1, '290 cal per 142g chimichanga. White chicken meat and Monterey Jack cheese. Source: fatsecret, elmonterey.com.', TRUE)

ON CONFLICT (food_name_normalized)
DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_serving_g = EXCLUDED.default_serving_g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
