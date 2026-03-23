-- 1872_jonahs_seafood_house.sql
-- Jonah's Seafood House (www.jonahsseafood.com) - Full menu nutritional data.
-- Sources: USDA FoodData Central, Nutritionix, FatSecret, MyFoodData, NutritionValue.org
-- All values per 100g of prepared dish.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g,
  region
) VALUES

-- ============================================================================
-- FEATURED ITEMS
-- ============================================================================

('jonahs_shrimp_ceviche', 'Jonah''s Wild Caught Shrimp Ceviche', 78, 14.0, 4.5, 0.8,
 0.6, 2.0, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs ceviche', 'shrimp ceviche jonahs', 'wild caught shrimp ceviche'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Featured appetizer. Shrimp in tomato, cucumber, cilantro, jalapeno & lime juice. ~156 cal per 200g serving.', TRUE,
 420, 130, 0.2, 0.0, 260, 52, 0.8, 35, 18.0, 0, 28, 1.1, 175, 30.0, 0.2,
 'US'),

('jonahs_grouper_beurre_blanc', 'Jonah''s Florida Gulf Grouper Au Beurre Blanc', 158, 20.0, 2.0, 7.5,
 0.2, 0.5, 255, NULL,
 'jonahsseafood.com', ARRAY['jonahs grouper', 'grouper beurre blanc', 'florida grouper jonahs', 'grouper white wine sauce'],
 'seafood', 'Jonah''s Seafood House', 1, 'Featured entree. Madeira Beach FL grouper grilled with deglazed white wine & mushroom sauce. ~403 cal per 255g serving.', TRUE,
 320, 65, 4.0, 0.2, 420, 22, 1.1, 50, 1.0, 12, 30, 0.5, 148, 36.0, 0.24,
 'US'),

-- ============================================================================
-- APPETIZERS (LET'S START HERE!)
-- ============================================================================

('jonahs_charcuterie_board', 'Jonah''s Charcuterie Board', 340, 18.0, 18.0, 23.0,
 0.8, 2.0, 350, NULL,
 'jonahsseafood.com', ARRAY['jonahs charcuterie', 'charcuterie board jonahs', 'meat and cheese board'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Market cheeses, meats, toasts & French bread. ~1190 cal per 350g serving. Shared appetizer.', TRUE,
 1100, 72, 10.5, 0.3, 180, 220, 1.5, 80, 0.5, 8, 22, 2.5, 250, 18.0, 0.1,
 'US'),

('jonahs_shrimp_cocktail', 'Jonah''s Wild Caught Jumbo Gulf Shrimp Cocktail', 106, 20.0, 3.5, 1.0,
 0.2, 2.5, 225, NULL,
 'jonahsseafood.com', ARRAY['jonahs shrimp cocktail', 'jumbo shrimp cocktail', 'gulf shrimp cocktail jonahs'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Steamed jumbo Gulf shrimp with cocktail sauce. ~238 cal per 225g serving.', TRUE,
 480, 189, 0.3, 0.0, 260, 40, 0.5, 15, 3.0, 2, 30, 1.4, 200, 38.0, 0.3,
 'US'),

('jonahs_ahi_tuna_sampler', 'Jonah''s Ahi Tuna #1 Sampler', 165, 25.0, 3.0, 6.0,
 0.5, 0.3, 170, NULL,
 'jonahsseafood.com', ARRAY['jonahs ahi tuna', 'ahi tuna sampler', 'sesame crusted ahi tuna jonahs', 'tuna sampler jonahs'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Sesame crusted, Chai Thai spiced, pan seared, sliced thin. Best served rare. ~281 cal per 170g serving.', TRUE,
 380, 45, 1.2, 0.0, 400, 35, 1.5, 55, 1.0, 68, 50, 0.6, 280, 78.0, 0.25,
 'US'),

('jonahs_fried_calamari', 'Jonah''s Flash Fried Fresh Calamari', 195, 10.5, 14.0, 11.0,
 0.5, 0.5, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs calamari', 'fried calamari jonahs', 'flash fried calamari', '20000 leagues of squid'],
 'appetizer', 'Jonah''s Seafood House', 1, '20,000 Leagues of Squid with Cool Lemon Thyme Sauce. ~390 cal per 200g serving.', TRUE,
 460, 160, 2.5, 0.2, 175, 30, 1.2, 10, 2.0, 0, 25, 1.0, 150, 28.0, 0.3,
 'US'),

('jonahs_crab_stuffed_mushrooms', 'Jonah''s Crab Stuffed Mushrooms', 185, 12.0, 6.0, 13.0,
 0.5, 1.0, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs stuffed mushrooms', 'crab stuffed mushrooms jonahs', 'crab mushrooms brie'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Stuffed with Brie & King crab, imported cheeses. ~370 cal per 200g serving.', TRUE,
 520, 65, 7.0, 0.2, 240, 145, 1.0, 60, 1.0, 4, 18, 2.8, 190, 22.0, 0.2,
 'US'),

('jonahs_shrimp_chicken_eggrolls', 'Jonah''s Shrimp & Chicken Eggrolls', 220, 9.0, 24.0, 10.0,
 1.2, 3.0, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs eggrolls', 'shrimp chicken eggrolls jonahs', 'shrimp eggrolls'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Rolled fresh with Wasabi Aioli, Sweet n Sour & Asian Ginger Sauces. ~440 cal per 200g serving.', TRUE,
 550, 45, 2.5, 0.3, 140, 25, 1.3, 15, 3.0, 2, 16, 0.7, 95, 12.0, 0.1,
 'US'),

('jonahs_coconut_fried_shrimp', 'Jonah''s Coconut Fried Shrimp', 280, 12.0, 22.0, 16.0,
 1.5, 6.0, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs coconut shrimp', 'coconut fried shrimp jonahs', 'coconut shrimp honey dijon'],
 'appetizer', 'Jonah''s Seafood House', 1, 'With Honey Dijon Dipping Sauce. ~560 cal per 200g serving.', TRUE,
 530, 105, 7.0, 0.2, 180, 30, 0.8, 10, 1.0, 2, 22, 0.9, 155, 20.0, 0.15,
 'US'),

('jonahs_buffalo_bang_shrimp', 'Jonah''s Buffalo Bang Shrimp', 245, 13.0, 16.0, 14.0,
 0.5, 2.5, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs buffalo shrimp', 'buffalo bang shrimp jonahs', 'bang bang shrimp jonahs'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Fried shrimp tossed in hot stuff. ~490 cal per 200g serving.', TRUE,
 820, 115, 3.0, 0.2, 170, 35, 0.7, 25, 2.0, 2, 22, 0.9, 155, 22.0, 0.15,
 'US'),

('jonahs_crab_rangoon', 'Jonah''s Crab Rangoon', 287, 7.5, 26.0, 17.0,
 0.5, 2.0, 170, NULL,
 'jonahsseafood.com', ARRAY['jonahs crab rangoon', 'crab rangoon jonahs', 'crab cream cheese wontons'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Crab & cream cheese in a deep-fried shell. ~488 cal per 170g serving.', TRUE,
 430, 50, 6.0, 0.5, 65, 40, 1.2, 30, 0.0, 2, 12, 0.6, 80, 10.0, 0.05,
 'US'),

('jonahs_spinach_artichoke_dip', 'Jonah''s Spinach & Fire Roasted Artichoke Dip', 170, 5.0, 8.0, 13.5,
 1.8, 1.5, 280, NULL,
 'jonahsseafood.com', ARRAY['jonahs spinach dip', 'spinach artichoke dip jonahs', 'fire roasted artichoke dip'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Spinach & fire roasted artichoke dip. ~476 cal per 280g serving.', TRUE,
 520, 30, 6.5, 0.2, 200, 140, 1.2, 180, 6.0, 2, 30, 0.8, 120, 5.0, 0.05,
 'US'),

('jonahs_crab_tortilla_dip', 'Jonah''s Crab Tortilla Dip', 155, 8.0, 7.0, 11.0,
 0.5, 2.0, 280, NULL,
 'jonahsseafood.com', ARRAY['jonahs crab dip', 'crab tortilla dip jonahs', 'crab dip pico de gallo'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Crab dip with Pico De Gallo. ~434 cal per 280g serving.', TRUE,
 480, 45, 5.5, 0.1, 150, 80, 0.6, 40, 5.0, 2, 18, 1.5, 130, 15.0, 0.15,
 'US'),

('jonahs_crab_cake', 'Jonah''s Jumbo Lump & King Crab Cake', 190, 16.0, 8.0, 10.5,
 0.3, 1.0, 170, 170,
 'jonahsseafood.com', ARRAY['jonahs crab cake', 'crab cake jonahs', 'king crab cake', 'jumbo lump crab cake'],
 'appetizer', 'Jonah''s Seafood House', 1, 'House-made everyday. Jumbo lump & king crab. ~323 cal per 170g cake.', TRUE,
 550, 150, 2.5, 0.1, 280, 65, 1.1, 25, 2.0, 4, 32, 4.0, 220, 30.0, 0.35,
 'US'),

('jonahs_fried_oysters_app', 'Jonah''s Fried Fresh Oysters (Appetizer)', 199, 8.8, 12.0, 13.0,
 0.4, 0.5, 180, NULL,
 'jonahsseafood.com', ARRAY['jonahs fried oysters appetizer', 'fried oysters cracker crusted', 'boston style oysters appetizer'],
 'appetizer', 'Jonah''s Seafood House', 1, 'Cracker crusted Boston style. ~358 cal per 180g serving.', TRUE,
 355, 60, 3.2, 0.2, 180, 55, 7.0, 45, 3.0, 8, 40, 50.0, 140, 56.0, 0.4,
 'US'),

-- ============================================================================
-- RAW BAR / HALF SHELL
-- ============================================================================

('jonahs_east_coast_blues_oysters', 'Jonah''s East Coast "Blues" Raw Oysters', 68, 7.0, 3.9, 2.5,
 0.0, 0.0, 150, NULL,
 'jonahsseafood.com', ARRAY['jonahs raw oysters', 'east coast blues oysters', 'potomac river oysters jonahs', 'oysters half shell jonahs'],
 'raw_bar', 'Jonah''s Seafood House', 6, 'Potomac River, Maryland. Half dozen raw on the half shell. Pure, Clean & Unsullied. ~102 cal per 150g (6 oysters).', TRUE,
 210, 53, 0.8, 0.0, 156, 45, 5.1, 13, 3.5, 8, 33, 39.3, 135, 63.0, 0.7,
 'US'),

('jonahs_oysters_rockefeller', 'Jonah''s Oysters Rockefeller', 127, 7.5, 9.0, 7.0,
 0.8, 1.0, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs oysters rockefeller', 'baked oysters jonahs', 'oysters rockefeller jonahs'],
 'raw_bar', 'Jonah''s Seafood House', 6, 'Baked in the Shell, Half Dozen. ~254 cal per 200g serving.', TRUE,
 380, 50, 3.5, 0.1, 200, 85, 5.0, 120, 8.0, 6, 30, 25.0, 140, 40.0, 0.5,
 'US'),

-- ============================================================================
-- SOUPS
-- ============================================================================

('jonahs_clam_chowder', 'Jonah''s Creamy Cape Cod Clam Chowder', 82, 3.5, 9.5, 3.5,
 0.7, 1.2, 340, NULL,
 'jonahsseafood.com', ARRAY['jonahs clam chowder', 'cape cod clam chowder jonahs', 'new england clam chowder jonahs'],
 'soup', 'Jonah''s Seafood House', 1, 'Creamy New England style. Bowl ~279 cal per 340g. Cup ~136 cal per 170g.', TRUE,
 520, 10, 1.5, 0.1, 221, 45, 2.5, 30, 4.1, 4, 13, 0.4, 260, 6.3, 0.03,
 'US'),

('jonahs_louisiana_gumbo', 'Jonah''s Spicy Louisiana Gumbo', 85, 6.5, 5.0, 4.5,
 0.8, 1.5, 350, NULL,
 'jonahsseafood.com', ARRAY['jonahs gumbo', 'louisiana gumbo jonahs', 'spicy gumbo jonahs', 'seafood gumbo'],
 'soup', 'Jonah''s Seafood House', 1, 'Spicy seafood & sausage gumbo. Bowl ~298 cal per 350g. Cup ~134 cal per 158g.', TRUE,
 750, 40, 1.2, 0.05, 250, 50, 1.3, 45, 8.0, 6, 25, 1.0, 120, 15.0, 0.15,
 'US'),

('jonahs_red_beans_rice', 'Jonah''s Red Beans & Rice', 130, 5.5, 19.0, 3.2,
 4.5, 1.0, 300, NULL,
 'jonahsseafood.com', ARRAY['jonahs red beans rice', 'red beans and rice jonahs', 'creole red beans rice'],
 'soup', 'Jonah''s Seafood House', 1, 'A Creole Southern Classic. Bowl ~390 cal per 300g. Cup ~176 cal per 135g.', TRUE,
 380, 5, 1.0, 0.0, 320, 30, 1.8, 3, 2.0, 0, 35, 0.9, 100, 5.0, 0.02,
 'US'),

('jonahs_french_onion_soup', 'Jonah''s French Onion Soup', 95, 4.5, 9.0, 4.5,
 0.8, 3.0, 350, NULL,
 'jonahsseafood.com', ARRAY['jonahs french onion soup', 'french onion soup jonahs', 'onion soup gratin jonahs'],
 'soup', 'Jonah''s Seafood House', 1, 'Swiss cheese, roasted onion, French bread. ~333 cal per 350g serving.', TRUE,
 580, 12, 2.2, 0.1, 120, 100, 0.6, 25, 3.0, 3, 12, 0.6, 85, 5.5, 0.02,
 'US'),

-- ============================================================================
-- SALADS
-- ============================================================================

('jonahs_7_layer_salad', 'Jonah''s Great 7-Layer Salad', 230, 5.5, 6.0, 21.0,
 1.6, 4.0, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs 7 layer salad', 'seven layer salad jonahs', '7 layer salad jonahs'],
 'salad', 'Jonah''s Seafood House', 1, 'Cheeses, Onion, Peas, Cauliflower, Bell Peppers, Crispy Bacon with Sweet, Tangy Dressing. Side ~198 cal / Entree ~460 cal.', TRUE,
 310, 60, 5.4, 0.1, 155, 72, 0.7, 82, 9.0, 8, 13, 0.7, 100, 6.6, 0.1,
 'US'),

('jonahs_caesar_salad', 'Jonah''s Caesar Salad', 155, 4.5, 9.0, 11.5,
 1.2, 1.5, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs caesar salad', 'caesar salad jonahs'],
 'salad', 'Jonah''s Seafood House', 1, 'Classic Caesar with croutons & parmesan. Side ~124 cal / Entree ~310 cal. Add Chicken +$9.5, Shrimp +$13.5.', TRUE,
 500, 18, 2.8, 0.1, 170, 85, 0.8, 110, 10.0, 2, 14, 0.5, 70, 4.0, 0.1,
 'US'),

('jonahs_house_greens_salad', 'Jonah''s House Greens Salad', 35, 1.3, 4.0, 1.5,
 1.8, 1.5, 150, NULL,
 'jonahsseafood.com', ARRAY['jonahs house salad', 'house greens salad jonahs', 'mixed greens jonahs'],
 'salad', 'Jonah''s Seafood House', 1, 'Mixed greens with light dressing. Side ~53 cal / Entree ~105 cal. Add Chicken +$9.5, Shrimp +$13.5.', TRUE,
 120, 0, 0.2, 0.0, 250, 40, 1.0, 180, 15.0, 0, 18, 0.3, 30, 0.5, 0.05,
 'US'),

-- ============================================================================
-- SIDES
-- ============================================================================

('jonahs_sweet_au_gratins', 'Jonah''s Sweet Au Gratins', 120, 2.8, 15.0, 5.5,
 2.0, 5.0, 180, NULL,
 'jonahsseafood.com', ARRAY['jonahs sweet potato gratin', 'sweet au gratins jonahs', 'sweet potato au gratin'],
 'side', 'Jonah''s Seafood House', 1, 'Sweet potato au gratin. ~216 cal per 180g serving.', TRUE,
 350, 15, 3.2, 0.1, 350, 120, 0.6, 400, 7.0, 5, 22, 0.5, 100, 3.0, 0.03,
 'US'),

('jonahs_yukon_gold_mash', 'Jonah''s Yukon Gold Potato Mash', 110, 2.0, 16.0, 4.3,
 1.3, 1.5, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs mashed potatoes', 'yukon gold mash jonahs', 'potato mash jonahs'],
 'side', 'Jonah''s Seafood House', 1, 'Creamy Yukon Gold mashed potatoes. ~220 cal per 200g serving.', TRUE,
 300, 12, 2.5, 0.1, 280, 25, 0.3, 40, 6.0, 5, 18, 0.3, 45, 0.8, 0.04,
 'US'),

('jonahs_herb_roasted_potatoes', 'Jonah''s Herb Roasted Red Potatoes', 120, 2.2, 17.5, 4.5,
 1.8, 1.2, 180, NULL,
 'jonahsseafood.com', ARRAY['jonahs roasted potatoes', 'herb roasted red potatoes jonahs', 'roasted potatoes jonahs'],
 'side', 'Jonah''s Seafood House', 1, 'Herb roasted red potatoes. ~216 cal per 180g serving.', TRUE,
 250, 0, 0.6, 0.0, 425, 10, 0.7, 2, 8.0, 0, 22, 0.3, 55, 0.5, 0.02,
 'US'),

('jonahs_fat_fries', 'Jonah''s Fat Fries', 280, 4.5, 32.0, 15.0,
 2.5, 0.5, 200, NULL,
 'jonahsseafood.com', ARRAY['jonahs fries', 'fat fries jonahs', 'parmesan fries jonahs', 'fries with remoulade'],
 'side', 'Jonah''s Seafood House', 1, 'Salt, Parmesan & Remoulade. ~560 cal per 200g serving.', TRUE,
 550, 10, 3.5, 0.2, 400, 55, 0.8, 5, 5.0, 1, 28, 0.5, 85, 2.5, 0.15,
 'US'),

('jonahs_asparagus', 'Jonah''s Steamed & Buttered Asparagus', 42, 2.4, 4.0, 2.3,
 2.0, 1.2, 180, NULL,
 'jonahsseafood.com', ARRAY['jonahs asparagus', 'steamed asparagus jonahs', 'buttered asparagus jonahs'],
 'side', 'Jonah''s Seafood House', 1, 'Fresh asparagus steamed and buttered. ~76 cal per 180g serving.', TRUE,
 50, 6, 1.3, 0.0, 200, 22, 0.9, 50, 6.0, 3, 14, 0.5, 52, 6.0, 0.07,
 'US'),

('jonahs_broccoli', 'Jonah''s Steamed & Buttered Broccoli', 55, 3.0, 5.5, 2.5,
 2.8, 1.4, 180, NULL,
 'jonahsseafood.com', ARRAY['jonahs broccoli', 'steamed broccoli jonahs', 'buttered broccoli jonahs'],
 'side', 'Jonah''s Seafood House', 1, 'Fresh broccoli steamed and buttered. ~99 cal per 180g serving.', TRUE,
 45, 6, 1.4, 0.0, 260, 40, 0.7, 80, 55.0, 3, 18, 0.4, 55, 1.5, 0.06,
 'US'),

-- ============================================================================
-- LOBSTER, CRAB & FILET
-- ============================================================================

('jonahs_lobster_tail_single', 'Jonah''s South African Lobster Tail (One)', 175, 16.0, 0.5, 11.5,
 0.0, 0.0, 170, 170,
 'jonahsseafood.com', ARRAY['jonahs lobster tail', 'south african lobster jonahs', 'lobster tail jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Seasoned, Buttered, Broiled to perfection. One tail. ~298 cal per 170g tail.', TRUE,
 500, 130, 6.5, 0.3, 210, 90, 0.3, 85, 0.0, 0, 38, 3.8, 170, 65.0, 0.35,
 'US'),

('jonahs_lobster_tail_double', 'Jonah''s South African Lobster Tail (Two)', 175, 16.0, 0.5, 11.5,
 0.0, 0.0, 340, 170,
 'jonahsseafood.com', ARRAY['jonahs double lobster', 'two lobster tails jonahs', 'lobster tails jonahs'],
 'seafood', 'Jonah''s Seafood House', 2, 'Seasoned, Buttered, Broiled to perfection. Two tails. ~595 cal per 340g (2 tails).', TRUE,
 500, 130, 6.5, 0.3, 210, 90, 0.3, 85, 0.0, 0, 38, 3.8, 170, 65.0, 0.35,
 'US'),

('jonahs_king_crab_legs_full', 'Jonah''s Jumbo Alaskan King Crab Legs (Full Pound)', 97, 19.4, 0.0, 1.5,
 0.0, 0.0, 230, NULL,
 'jonahsseafood.com', ARRAY['jonahs king crab', 'alaskan king crab legs jonahs', 'king crab jonahs full pound'],
 'seafood', 'Jonah''s Seafood House', 1, 'Full Pound. ~223 cal per 230g edible meat (from 454g shell-on). Naturally high sodium.', TRUE,
 1072, 53, 0.2, 0.0, 262, 59, 0.8, 3, 7.6, 0, 63, 7.6, 280, 40.0, 0.41,
 'US'),

('jonahs_king_crab_legs_half', 'Jonah''s Jumbo Alaskan King Crab Legs (Pound & a Half)', 97, 19.4, 0.0, 1.5,
 0.0, 0.0, 345, NULL,
 'jonahsseafood.com', ARRAY['jonahs king crab large', 'king crab legs pound half jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Pound & a Half. ~335 cal per 345g edible meat (from 681g shell-on). Naturally high sodium.', TRUE,
 1072, 53, 0.2, 0.0, 262, 59, 0.8, 3, 7.6, 0, 63, 7.6, 280, 40.0, 0.41,
 'US'),

('jonahs_lobster_king_crab_combo', 'Jonah''s South African Lobster & King Crab', 135, 17.5, 0.3, 6.5,
 0.0, 0.0, 285, NULL,
 'jonahsseafood.com', ARRAY['jonahs lobster crab combo', 'lobster and king crab jonahs', 'surf and surf jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'SA Lobster Tail & Half Pound Alaskan King Crab Legs. ~385 cal per 285g serving.', TRUE,
 780, 90, 3.5, 0.2, 235, 75, 0.6, 45, 4.0, 0, 50, 5.5, 225, 52.0, 0.38,
 'US'),

('jonahs_filet_mignon', 'Jonah''s Filet Mignon 7oz', 211, 30.5, 0.0, 8.9,
 0.0, 0.0, 198, 198,
 'jonahsseafood.com', ARRAY['jonahs filet mignon', 'filet mignon jonahs', 'jonahs steak', 'angus filet jonahs'],
 'steak', 'Jonah''s Seafood House', 1, '7oz Choice Center-Cut. 28 Day Matured Angus Beef. ~418 cal per 198g (7oz).', TRUE,
 46, 79, 3.3, 0.4, 296, 11, 3.0, 0, 0.0, 7, 24, 4.4, 224, 27.0, 0.05,
 'US'),

('jonahs_filet_and_shrimp', 'Jonah''s Filet & Gulf Shrimp', 178, 28.0, 0.5, 6.5,
 0.0, 0.0, 255, NULL,
 'jonahsseafood.com', ARRAY['jonahs filet shrimp', 'filet and shrimp jonahs', 'surf and turf jonahs shrimp'],
 'steak', 'Jonah''s Seafood House', 1, 'Filet Mignon with Gulf Shrimp, Broiled, Grilled, or Fried. ~454 cal per 255g serving.', TRUE,
 185, 120, 2.4, 0.3, 300, 30, 2.3, 2, 1.0, 5, 32, 3.5, 250, 30.0, 0.15,
 'US'),

('jonahs_lobster_tail_and_filet', 'Jonah''s South African Lobster Tail & Filet', 192, 23.0, 0.3, 10.2,
 0.0, 0.0, 340, NULL,
 'jonahsseafood.com', ARRAY['jonahs lobster filet', 'lobster tail and filet jonahs', 'surf and turf jonahs lobster'],
 'steak', 'Jonah''s Seafood House', 1, 'Lobster tail paired with filet mignon. ~653 cal per 340g serving.', TRUE,
 270, 105, 5.0, 0.35, 255, 50, 1.7, 42, 0.0, 4, 31, 4.1, 197, 46.0, 0.2,
 'US'),

('jonahs_filet_and_king_crab', 'Jonah''s Filet & Alaskan King Crab', 155, 25.0, 0.0, 5.5,
 0.0, 0.0, 340, NULL,
 'jonahsseafood.com', ARRAY['jonahs filet king crab', 'filet and king crab jonahs', 'steak and crab jonahs'],
 'steak', 'Jonah''s Seafood House', 1, 'Filet mignon with Alaskan King Crab Legs. ~527 cal per 340g serving.', TRUE,
 550, 66, 1.8, 0.2, 280, 35, 1.9, 2, 4.0, 4, 43, 6.0, 252, 33.0, 0.23,
 'US'),

-- ============================================================================
-- FRESH AS IT GETS (Fresh Fish)
-- ============================================================================

('jonahs_blackened_grouper', 'Jonah''s Blackened Florida Gulf Grouper', 145, 22.0, 2.5, 5.0,
 0.5, 1.0, 225, NULL,
 'jonahsseafood.com', ARRAY['jonahs blackened grouper', 'blackened grouper jonahs', 'cajun grouper jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Madeira Beach FL. Cajun crust pan sear with Mediterranean relish of tomato, bell pepper & olive. ~326 cal per 225g serving.', TRUE,
 380, 47, 1.2, 0.0, 440, 25, 1.2, 15, 3.0, 15, 32, 0.5, 145, 38.0, 0.25,
 'US'),

('jonahs_grilled_ora_king_salmon', 'Jonah''s Grilled Ora King Salmon', 230, 22.0, 0.0, 15.5,
 0.0, 0.0, 198, NULL,
 'jonahsseafood.com', ARRAY['jonahs grilled salmon', 'ora king salmon jonahs', 'grilled salmon jonahs', 'new zealand salmon jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Tasman Bay, New Zealand. Organically fed, essentially wild, free of dyes, antibiotics & hormones. ~455 cal per 198g fillet.', TRUE,
 50, 70, 3.5, 0.0, 420, 15, 0.5, 40, 0.0, 526, 30, 0.6, 260, 42.0, 2.2,
 'US'),

('jonahs_devil_bronzed_salmon', 'Jonah''s Devil Bronzed Ora King Salmon', 255, 20.5, 4.5, 17.0,
 0.3, 3.0, 225, NULL,
 'jonahsseafood.com', ARRAY['jonahs devil bronzed salmon', 'devil bronzed salmon jonahs', 'creole salmon jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Tasman Bay, New Zealand. Creole-Crusted, pan-seared, sweet PA black vinegar & Craisins. ~574 cal per 225g serving.', TRUE,
 380, 72, 4.0, 0.0, 400, 18, 0.7, 42, 1.0, 480, 28, 0.6, 250, 40.0, 2.0,
 'US'),

('jonahs_sesame_ahi_tuna', 'Jonah''s Sesame Crusted Hawaiian Ahi Tuna #1', 155, 25.0, 2.5, 5.0,
 0.8, 0.2, 198, NULL,
 'jonahsseafood.com', ARRAY['jonahs ahi tuna entree', 'sesame crusted tuna jonahs', 'hawaiian ahi tuna jonahs', 'ahi tuna jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Waikiki, Hawaii. Firm red meat, milder flavor. Toasted sesame seeds, pan seared, with pickled ginger, ocean greens, peanut butter lime, wasabi aioli & asian ginger sauces. Best Rare! ~307 cal per 198g serving.', TRUE,
 60, 49, 0.8, 0.0, 500, 40, 1.0, 20, 0.0, 82, 55, 0.5, 310, 100.0, 0.35,
 'US'),

('jonahs_bayou_swordfish', 'Jonah''s Bayou Peppered Pacific Swordfish', 190, 20.0, 3.5, 10.5,
 0.4, 1.0, 255, NULL,
 'jonahsseafood.com', ARRAY['jonahs bayou swordfish', 'bayou peppered swordfish jonahs', 'swordfish portabella jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Waikiki, Hawaii. Mildly sweet white-fleshed fish. Pan-seared with Portabella & Andouille Sausage sauce. ~485 cal per 255g serving.', TRUE,
 420, 58, 2.8, 0.0, 470, 10, 0.6, 12, 1.5, 570, 33, 0.8, 280, 62.0, 1.0,
 'US'),

('jonahs_parmesan_roma_swordfish', 'Jonah''s Parmesan Roma Pacific Swordfish', 185, 21.0, 5.0, 9.0,
 0.6, 1.5, 270, NULL,
 'jonahsseafood.com', ARRAY['jonahs parmesan swordfish', 'parmesan roma swordfish jonahs', 'swordfish ratatouille jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Waikiki, Hawaii. Fresh parmesan & seasoned bread crumbs, baked, on garlic & roma tomato ratatouille. ~500 cal per 270g serving.', TRUE,
 350, 55, 2.5, 0.0, 460, 65, 0.7, 30, 6.0, 520, 35, 1.0, 290, 58.0, 0.95,
 'US'),

('jonahs_norwegian_cod_ananas', 'Jonah''s Norwegian Cod Ananas', 140, 17.0, 8.0, 4.0,
 0.5, 3.5, 270, NULL,
 'jonahsseafood.com', ARRAY['jonahs cod ananas', 'norwegian cod jonahs', 'panko cod pineapple jonahs', 'cod ananas jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Avery Island, Norway. Panko crusted, baked, with cool pineapple, cucumber, cilantro & jalapeno salsa. ~378 cal per 270g serving.', TRUE,
 280, 45, 0.8, 0.0, 380, 35, 0.6, 5, 12.0, 36, 32, 0.6, 220, 38.0, 0.18,
 'US'),

-- ============================================================================
-- SHRIMP, SHRIMP & MORE
-- ============================================================================

('jonahs_shrimp_scampi', 'Jonah''s Gulf Shrimp Scampi Alla Crema', 165, 10.5, 15.0, 7.5,
 0.8, 1.0, 400, NULL,
 'jonahsseafood.com', ARRAY['jonahs shrimp scampi', 'shrimp scampi alla crema jonahs', 'shrimp linguine jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Wild caught shrimp sauteed with garlic, butter & red peppers on linguine in spinach & parmesan cream sauce. ~660 cal per 400g serving.', TRUE,
 380, 70, 3.8, 0.1, 180, 85, 1.0, 95, 3.0, 5, 22, 0.8, 130, 18.0, 0.15,
 'US'),

('jonahs_panko_fried_shrimp', 'Jonah''s Deep Fried Wild Caught Gulf Shrimp', 260, 14.0, 18.0, 14.5,
 0.5, 1.0, 225, NULL,
 'jonahsseafood.com', ARRAY['jonahs fried shrimp', 'panko shrimp jonahs', 'deep fried gulf shrimp jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Panko Style. ~585 cal per 225g serving.', TRUE,
 550, 115, 2.5, 0.1, 180, 45, 1.2, 5, 0.0, 3, 25, 0.7, 160, 22.0, 0.12,
 'US'),

('jonahs_fish_and_chips', 'Jonah''s Norwegian Fish & Chips', 200, 10.0, 17.0, 10.0,
 1.0, 2.0, 400, NULL,
 'jonahsseafood.com', ARRAY['jonahs fish and chips', 'fish chips jonahs', 'norwegian fish chips jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Beer-battered Norwegian cod with Creamy Coleslaw & fries. ~800 cal per 400g serving.', TRUE,
 420, 35, 1.8, 0.1, 250, 25, 0.8, 8, 5.0, 10, 20, 0.4, 120, 15.0, 0.10,
 'US'),

('jonahs_fried_oysters_entree', 'Jonah''s Fresh Oysters Fried Boston Style (Entree)', 199, 8.8, 12.0, 13.0,
 0.4, 0.5, 250, NULL,
 'jonahsseafood.com', ARRAY['jonahs fried oysters entree', 'boston style oysters entree jonahs', 'fried oysters dinner jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Cracker crusted Boston style entree portion. ~498 cal per 250g serving.', TRUE,
 355, 60, 3.2, 0.2, 180, 55, 7.0, 45, 3.0, 8, 40, 50.0, 140, 56.0, 0.4,
 'US'),

('jonahs_louisiana_jambalaya', 'Jonah''s Spicy Louisiana Jambalaya', 140, 9.5, 14.0, 5.5,
 0.8, 1.5, 380, NULL,
 'jonahsseafood.com', ARRAY['jonahs jambalaya', 'louisiana jambalaya jonahs', 'spicy jambalaya jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Shrimp, chicken, Andouille sausage, onion, peppers, tomato & jasmine rice. ~532 cal per 380g serving.', TRUE,
 520, 50, 1.8, 0.1, 180, 22, 1.2, 15, 8.0, 2, 18, 0.8, 100, 14.0, 0.08,
 'US'),

('jonahs_crawfish_etouffee', 'Jonah''s Big Easy Crawfish Etouffee', 110, 7.0, 12.0, 4.0,
 0.5, 0.8, 380, NULL,
 'jonahsseafood.com', ARRAY['jonahs crawfish etouffee', 'crawfish etouffee jonahs', 'big easy etouffee jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'Hot & Spicy, as it was meant to be! With jasmine rice. ~418 cal per 380g serving.', TRUE,
 400, 55, 2.0, 0.1, 160, 35, 1.0, 40, 5.0, 0, 18, 0.6, 90, 12.0, 0.08,
 'US'),

('jonahs_shrimp_orleans', 'Jonah''s Pascale Shrimp Orleans', 135, 9.0, 13.0, 5.5,
 0.3, 0.5, 350, NULL,
 'jonahsseafood.com', ARRAY['jonahs shrimp orleans', 'pascale shrimp orleans jonahs', 'spicy shrimp orleans jonahs'],
 'seafood', 'Jonah''s Seafood House', 1, 'A festival of Spicy Pepper, Butter & Garlic! With jasmine rice. ~473 cal per 350g serving.', TRUE,
 450, 80, 2.8, 0.1, 170, 28, 0.8, 50, 4.0, 2, 20, 0.7, 110, 16.0, 0.10,
 'US'),

('jonahs_panko_chicken_tenderloins', 'Jonah''s Panko Fried Chicken Tenderloins', 240, 16.0, 15.0, 13.0,
 0.5, 1.5, 225, NULL,
 'jonahsseafood.com', ARRAY['jonahs chicken tenders', 'panko chicken tenderloins jonahs', 'fried chicken jonahs'],
 'chicken', 'Jonah''s Seafood House', 1, 'Panko fried tenderloins with Dijon ranch & bbq dipping sauces. ~540 cal per 225g serving.', TRUE,
 600, 65, 2.5, 0.1, 220, 18, 0.8, 3, 0.0, 2, 22, 0.8, 160, 20.0, 0.03,
 'US'),

('jonahs_bacon_bleu_cheeseburger', 'Jonah''s Bacon Bleu Cheeseburger', 270, 13.0, 18.0, 16.5,
 1.0, 3.0, 450, NULL,
 'jonahsseafood.com', ARRAY['jonahs burger', 'bacon bleu cheeseburger jonahs', 'bleu cheese burger jonahs'],
 'burger', 'Jonah''s Seafood House', 1, 'Fresh ground Filet, Bleu Cheese crumbles, cole slaw & fat fries. ~1215 cal per 450g full plate.', TRUE,
 580, 55, 7.0, 0.5, 250, 65, 1.5, 20, 3.0, 3, 20, 2.5, 150, 15.0, 0.05,
 'US')

ON CONFLICT (food_name_normalized) DO UPDATE SET
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
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active,
  sodium_mg = EXCLUDED.sodium_mg,
  cholesterol_mg = EXCLUDED.cholesterol_mg,
  saturated_fat_g = EXCLUDED.saturated_fat_g,
  trans_fat_g = EXCLUDED.trans_fat_g,
  potassium_mg = EXCLUDED.potassium_mg,
  calcium_mg = EXCLUDED.calcium_mg,
  iron_mg = EXCLUDED.iron_mg,
  vitamin_a_ug = EXCLUDED.vitamin_a_ug,
  vitamin_c_mg = EXCLUDED.vitamin_c_mg,
  vitamin_d_iu = EXCLUDED.vitamin_d_iu,
  magnesium_mg = EXCLUDED.magnesium_mg,
  zinc_mg = EXCLUDED.zinc_mg,
  phosphorus_mg = EXCLUDED.phosphorus_mg,
  selenium_ug = EXCLUDED.selenium_ug,
  omega3_g = EXCLUDED.omega3_g,
  updated_at = NOW();
