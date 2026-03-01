-- ============================================================================
-- 295_overrides_misc_chains.sql
-- Chinese/Turkish/Misc: Din Tai Fung, German Doner Kebab, Pret a Manger, HuHot, La Granja
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES
('dtf_xiao_long_bao', 'Din Tai Fung Xiao Long Bao (Pork)', 192.0, 8.8, 16.8, 9.6, 0.5, 1.5, 25, 250, 'dintaifungusa.com', ARRAY['din tai fung xlb', 'din tai fung soup dumplings', 'din tai fung xiao long bao'], '480 cal per 10 pieces (250g). Signature pork soup dumplings.', 'Din Tai Fung', 'asian', 10),
('dtf_chicken_xlb', 'Din Tai Fung Chicken Xiao Long Bao', 168.0, 9.6, 16.0, 7.2, 0.5, 1.0, 25, 250, 'dintaifungusa.com', ARRAY['din tai fung chicken dumplings', 'din tai fung chicken xlb'], '420 cal per 10 pieces (250g).', 'Din Tai Fung', 'asian', 10),
('dtf_truffle_xlb', 'Din Tai Fung Truffle Xiao Long Bao', 215.4, 9.2, 16.9, 12.3, 0.3, 1.0, 26, 130, 'dintaifungusa.com', ARRAY['din tai fung truffle dumplings', 'din tai fung truffle xlb'], '280 cal per 5 pieces (130g). Premium truffle-infused.', 'Din Tai Fung', 'asian', 5),
('dtf_wontons', 'Din Tai Fung Shrimp & Pork Wontons', 145.5, 8.2, 12.7, 6.4, 0.3, 1.0, 28, 220, 'dintaifungusa.com', ARRAY['din tai fung wontons', 'din tai fung shrimp wontons'], '320 cal per 8 pieces (220g). In chili oil or broth.', 'Din Tai Fung', 'asian', 8),
('dtf_shrimp_fried_rice', 'Din Tai Fung Shrimp Fried Rice', 148.6, 5.1, 17.7, 6.3, 0.5, 1.0, NULL, 350, 'dintaifungusa.com', ARRAY['din tai fung fried rice', 'din tai fung shrimp rice'], '520 cal per 350g serving.', 'Din Tai Fung', 'asian', 1),
('dtf_dan_dan_noodles', 'Din Tai Fung Dan Dan Noodles', 152.6, 5.3, 15.3, 7.4, 1.0, 2.0, NULL, 380, 'dintaifungusa.com', ARRAY['din tai fung dan dan', 'din tai fung noodles'], '580 cal per 380g serving. Spicy Sichuan peanut noodles with pork.', 'Din Tai Fung', 'asian', 1),
('dtf_cucumber_salad', 'Din Tai Fung Cucumber Salad', 53.3, 1.3, 4.0, 3.3, 1.0, 2.0, NULL, 150, 'dintaifungusa.com', ARRAY['din tai fung cucumber'], '80 cal per 150g serving. Garlic sesame cucumber.', 'Din Tai Fung', 'salads', 1),
('dtf_taro_buns', 'Din Tai Fung Baked Taro Buns', 240.0, 4.0, 32.0, 10.7, 1.0, 12.0, 50, 150, 'dintaifungusa.com', ARRAY['din tai fung taro buns', 'din tai fung dessert buns'], '360 cal per 3 buns (150g). Sweet taro paste filled buns.', 'Din Tai Fung', 'desserts', 3),
('gdk_original_kebab', 'German Doner Kebab Original', 178.9, 8.4, 13.7, 9.5, 1.5, 2.5, 380, 380, 'germandonerkebab.com', ARRAY['german doner kebab', 'gdk original', 'gdk doner'], '680 cal per kebab (380g). Seasoned beef/chicken in handmade bread.', 'German Doner Kebab', 'turkish', 1),
('gdk_chicken_kebab', 'German Doner Kebab Chicken', 167.6, 9.7, 13.5, 7.6, 1.5, 2.0, 370, 370, 'germandonerkebab.com', ARRAY['gdk chicken doner', 'german doner chicken'], '620 cal per kebab (370g).', 'German Doner Kebab', 'turkish', 1),
('gdk_quesadilla', 'German Doner Kebab Quesadilla', 193.3, 9.3, 14.0, 10.7, 1.0, 1.5, 300, 300, 'germandonerkebab.com', ARRAY['gdk quesadilla', 'german doner quesadilla'], '580 cal per quesadilla (300g).', 'German Doner Kebab', 'turkish', 1),
('gdk_burger', 'German Doner Kebab Doner Burger', 196.4, 10.7, 13.6, 10.7, 1.0, 2.0, 280, 280, 'germandonerkebab.com', ARRAY['gdk burger', 'german doner burger'], '550 cal per burger (280g). Doner meat in brioche bun.', 'German Doner Kebab', 'turkish', 1),
('gdk_fries', 'German Doner Kebab Fries', 177.8, 2.2, 22.2, 8.9, 2.0, 0.5, NULL, 180, 'germandonerkebab.com', ARRAY['gdk fries', 'german doner fries'], '320 cal per regular (180g).', 'German Doner Kebab', 'sides', 1),
('pret_chicken_avocado', 'Pret a Manger Chicken Avocado Baguette', 173.3, 9.3, 16.0, 7.3, 3.0, 2.0, 300, 300, 'pret.com', ARRAY['pret chicken avocado', 'pret chicken sandwich'], '520 cal per baguette (300g).', 'Pret a Manger', 'sandwiches', 1),
('pret_tuna_cucumber', 'Pret a Manger Tuna & Cucumber Baguette', 171.4, 8.6, 16.4, 7.1, 1.5, 1.5, 280, 280, 'pret.com', ARRAY['pret tuna sandwich', 'pret tuna baguette'], '480 cal per baguette (280g).', 'Pret a Manger', 'sandwiches', 1),
('pret_super_club', 'Pret a Manger Classic Super Club', 183.3, 10.0, 14.0, 9.3, 1.5, 2.0, 300, 300, 'pret.com', ARRAY['pret club sandwich', 'pret super club'], '550 cal per sandwich (300g). Chicken, bacon, egg, mayo.', 'Pret a Manger', 'sandwiches', 1),
('pret_caesar_wrap', 'Pret a Manger Chicken Caesar Wrap', 177.8, 9.6, 14.1, 8.9, 1.5, 1.5, 270, 270, 'pret.com', ARRAY['pret chicken wrap', 'pret caesar wrap'], '480 cal per wrap (270g).', 'Pret a Manger', 'sandwiches', 1),
('pret_almond_croissant', 'Pret a Manger Almond Croissant', 400.0, 9.1, 34.5, 25.5, 1.5, 12.0, 110, 110, 'pret.com', ARRAY['pret almond croissant', 'pret croissant'], '440 cal per croissant (110g).', 'Pret a Manger', 'french', 1),
('pret_tomato_soup', 'Pret a Manger Tomato Soup', 51.4, 1.1, 6.3, 2.3, 1.5, 4.0, NULL, 350, 'pret.com', ARRAY['pret tomato soup'], '180 cal per bowl (350g).', 'Pret a Manger', 'soups', 1),
('pret_chocolate_cookie', 'Pret a Manger Dark Chocolate Cookie', 475.0, 6.3, 57.5, 25.0, 2.0, 28.0, 80, 80, 'pret.com', ARRAY['pret cookie', 'pret chocolate chunk cookie'], '380 cal per cookie (80g).', 'Pret a Manger', 'desserts', 1),
('huhot_chicken_bowl', 'HuHot Mongolian Chicken Bowl', 120.0, 8.0, 12.0, 4.0, 2.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot chicken', 'huhot chicken bowl', 'huhot mongolian chicken'], '480 cal per typical bowl (400g). Chicken with rice noodles, veggies, Khan''s Favorite sauce.', 'HuHot Mongolian Grill', 'asian', 1),
('huhot_beef_bowl', 'HuHot Mongolian Beef Bowl', 135.0, 7.5, 12.0, 6.0, 2.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot beef', 'huhot beef bowl', 'huhot mongolian beef'], '540 cal per typical bowl (400g). Beef with noodles, veggies, BBQ sauce.', 'HuHot Mongolian Grill', 'asian', 1),
('huhot_shrimp_bowl', 'HuHot Mongolian Shrimp Bowl', 105.0, 7.0, 12.0, 3.0, 2.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot shrimp', 'huhot shrimp bowl'], '420 cal per typical bowl (400g). Shrimp with rice, veggies, lemon sauce.', 'HuHot Mongolian Grill', 'asian', 1),
('huhot_tofu_bowl', 'HuHot Mongolian Tofu Bowl', 95.0, 4.5, 12.5, 3.0, 3.0, 3.0, NULL, 400, 'huhot.com', ARRAY['huhot tofu', 'huhot vegetarian bowl'], '380 cal per typical bowl (400g).', 'HuHot Mongolian Grill', 'asian', 1),
('la_granja_pollo_brasa', 'La Granja Pollo a la Brasa (Quarter)', 159.1, 14.5, 0.0, 10.9, 0.0, 0.0, NULL, 220, 'lagranjarestaurants.com', ARRAY['la granja chicken', 'la granja pollo a la brasa', 'la granja rotisserie chicken'], '350 cal per quarter (220g). Peruvian-style rotisserie chicken.', 'La Granja', 'peruvian', 1),
('la_granja_lomo_saltado', 'La Granja Lomo Saltado', 136.8, 7.4, 11.1, 6.3, 1.5, 2.0, NULL, 380, 'lagranjarestaurants.com', ARRAY['la granja lomo saltado', 'la granja beef stir fry'], '520 cal per 380g plate. Peruvian stir-fried beef with onions, tomatoes, fries over rice.', 'La Granja', 'peruvian', 1),
('la_granja_aji_de_gallina', 'La Granja Aji de Gallina', 126.3, 5.8, 10.0, 6.8, 1.0, 1.5, NULL, 380, 'lagranjarestaurants.com', ARRAY['la granja aji de gallina', 'la granja creamy chicken'], '480 cal per 380g plate. Shredded chicken in creamy aji amarillo sauce.', 'La Granja', 'peruvian', 1),
('la_granja_arroz_con_pollo', 'La Granja Arroz con Pollo', 112.5, 6.5, 12.0, 4.0, 1.0, 1.0, NULL, 400, 'lagranjarestaurants.com', ARRAY['la granja arroz con pollo', 'la granja chicken rice'], '450 cal per 400g plate. Green rice with chicken.', 'La Granja', 'peruvian', 1),
('la_granja_ceviche', 'La Granja Ceviche', 88.0, 8.8, 4.8, 3.2, 1.0, 2.0, NULL, 250, 'lagranjarestaurants.com', ARRAY['la granja ceviche', 'la granja fish ceviche'], '220 cal per 250g serving. Fresh fish in lime juice with onions, cilantro.', 'La Granja', 'peruvian', 1),
('la_granja_aji_verde', 'La Granja Aji Verde Sauce', 200.0, 1.7, 3.3, 20.0, 0.5, 0.5, NULL, 30, 'lagranjarestaurants.com', ARRAY['la granja green sauce', 'la granja aji verde'], '60 cal per 30g serving. Signature creamy green chili sauce.', 'La Granja', 'sauces', 1)

ON CONFLICT (food_name_normalized) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  default_serving_g = EXCLUDED.default_serving_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  restaurant_name = EXCLUDED.restaurant_name,
  food_category = EXCLUDED.food_category,
  default_count = EXCLUDED.default_count,
  updated_at = NOW();
