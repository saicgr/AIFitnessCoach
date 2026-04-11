-- Chipotle Standard Menu — Individual Components
-- Source: Chipotle.com official nutrition + FatSecret verified data (2025)
-- Formula: per_100g = (per_serving_value / serving_weight_g) * 100
-- Serving sizes: proteins=4oz(113g), rice/beans=4oz(113g), toppings vary

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ═══════════════════════════════════════════════════════════════
-- PROTEINS (4 oz / 113g serving)
-- ═══════════════════════════════════════════════════════════════

-- Chicken: 180 cal, 32P, 0C, 7F per 4oz (113g)
('chipotle_chicken', 'Chipotle Chicken', 159.3, 28.3, 0.0, 6.2,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle chicken', 'chicken from chipotle', 'chipotle grilled chicken',
   'chipotle adobo chicken', 'chicken chipotle'],
 'protein', 'Chipotle', 1,
 '180 cal per 4oz. Responsibly raised chicken, grilled with adobo marinade. 310mg sodium.', TRUE),

-- Chicken Al Pastor: 200 cal, 23P, 4C, 11F per 4oz (113g)
('chipotle_chicken_al_pastor', 'Chipotle Chicken Al Pastor', 176.9, 20.4, 3.5, 9.7,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle chicken al pastor', 'chicken al pastor from chipotle',
   'chipotle al pastor', 'al pastor chicken chipotle', 'chicken al pastor chipotle',
   'chipotle high protein cup', 'chipotle chicken al pastor high protein cup',
   'high protein cup chipotle', 'chipotle protein cup'],
 'protein', 'Chipotle', 1,
 '200 cal per 4oz. Grilled chicken finished with dried chile, spice, and pineapple sauce. 820mg sodium. Also sold as High Protein Cup (~28g protein).', TRUE),

-- Steak: 150 cal, 21P, 1C, 6F per 4oz (113g)
('chipotle_steak', 'Chipotle Steak', 132.7, 18.6, 0.9, 5.3,
 0.9, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle steak', 'steak from chipotle', 'chipotle carne asada',
   'steak chipotle'],
 'protein', 'Chipotle', 1,
 '150 cal per 4oz. Responsibly raised steak. 330mg sodium, 2.5g sat fat.', TRUE),

-- Barbacoa: 170 cal, 24P, 2C, 7F per 4oz (113g)
('chipotle_barbacoa', 'Chipotle Barbacoa', 150.4, 21.2, 1.8, 6.2,
 0.9, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle barbacoa', 'barbacoa from chipotle', 'chipotle shredded beef',
   'barbacoa chipotle'],
 'protein', 'Chipotle', 1,
 '170 cal per 4oz. Shredded beef braised with chipotle peppers, cumin, cloves, garlic, oregano. 530mg sodium.', TRUE),

-- Carnitas: 210 cal, 23P, 0C, 12F per 4oz (113g)
('chipotle_carnitas', 'Chipotle Carnitas', 185.8, 20.4, 0.0, 10.6,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle carnitas', 'carnitas from chipotle', 'chipotle pork',
   'chipotle pulled pork', 'carnitas chipotle'],
 'protein', 'Chipotle', 1,
 '210 cal per 4oz. Braised pork with salt, pepper, juniper berries, thyme, bay leaf. 450mg sodium, 7g sat fat.', TRUE),

-- Sofritas: 150 cal, 8P, 9C, 10F per 4oz (113g)
('chipotle_sofritas', 'Chipotle Sofritas', 132.7, 7.1, 8.0, 8.8,
 2.7, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle sofritas', 'sofritas from chipotle', 'chipotle tofu',
   'sofritas chipotle', 'chipotle vegan protein'],
 'protein', 'Chipotle', 1,
 '150 cal per 4oz. Organic tofu braised with chipotle chiles, roasted poblanos, spices. 560mg sodium, 1.5g sat fat.', TRUE),

-- ═══════════════════════════════════════════════════════════════
-- RICE (4 oz / 113g serving)
-- ═══════════════════════════════════════════════════════════════

-- White Rice: 210 cal, 4P, 40C, 4F per 4oz (113g)
('chipotle_white_rice', 'Chipotle Cilantro-Lime White Rice', 185.8, 3.5, 35.4, 3.5,
 0.0, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle white rice', 'chipotle rice', 'chipotle cilantro lime rice',
   'white rice from chipotle', 'chipotle cilantro rice'],
 'rice', 'Chipotle', 1,
 '210 cal per 4oz. Cilantro-lime seasoned white rice.', TRUE),

-- Brown Rice: 210 cal, 4P, 36C, 6F per 4oz (113g)
('chipotle_brown_rice', 'Chipotle Cilantro-Lime Brown Rice', 185.8, 3.5, 31.9, 5.3,
 1.8, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle brown rice', 'brown rice from chipotle',
   'chipotle cilantro lime brown rice'],
 'rice', 'Chipotle', 1,
 '210 cal per 4oz. Cilantro-lime seasoned brown rice. Higher fiber than white.', TRUE),

-- ═══════════════════════════════════════════════════════════════
-- BEANS (4 oz / 113g serving)
-- ═══════════════════════════════════════════════════════════════

-- Black Beans: 130 cal, 8P, 22C, 1.5F per 4oz (113g)
('chipotle_black_beans', 'Chipotle Black Beans', 115.0, 7.1, 19.5, 1.3,
 7.1, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle black beans', 'black beans from chipotle',
   'black beans chipotle'],
 'beans', 'Chipotle', 1,
 '130 cal per 4oz. Seasoned black beans.', TRUE),

-- Pinto Beans: 130 cal, 8P, 21C, 1.5F per 4oz (113g)
('chipotle_pinto_beans', 'Chipotle Pinto Beans', 115.0, 7.1, 18.6, 1.3,
 7.1, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle pinto beans', 'pinto beans from chipotle',
   'pinto beans chipotle'],
 'beans', 'Chipotle', 1,
 '130 cal per 4oz. Seasoned pinto beans.', TRUE),

-- ═══════════════════════════════════════════════════════════════
-- TOPPINGS
-- ═══════════════════════════════════════════════════════════════

-- Guacamole: 230 cal, 2P, 8C, 22F per 3.5oz (100g)
('chipotle_guacamole', 'Chipotle Guacamole', 230.0, 2.0, 8.0, 22.0,
 6.0, 1.0, 100, NULL,
 'manufacturer', ARRAY['chipotle guacamole', 'guac from chipotle', 'chipotle guac',
   'guacamole chipotle'],
 'toppings', 'Chipotle', 1,
 '230 cal per 3.5oz. Fresh avocado, lime, cilantro, jalapeño, red onion.', TRUE),

-- Sour Cream: 110 cal, 2P, 2C, 9F per 2oz (57g)
('chipotle_sour_cream', 'Chipotle Sour Cream', 192.9, 3.5, 3.5, 15.8,
 0.0, 0.0, 57, NULL,
 'manufacturer', ARRAY['chipotle sour cream', 'sour cream from chipotle',
   'sour cream chipotle'],
 'toppings', 'Chipotle', 1,
 '110 cal per 2oz. 7g sat fat, 30mg sodium.', TRUE),

-- Cheese: 110 cal, 6P, 1C, 8F per 1oz (28g)
('chipotle_cheese', 'Chipotle Shredded Cheese', 392.9, 21.4, 3.6, 28.6,
 0.0, 0.0, 28, NULL,
 'manufacturer', ARRAY['chipotle cheese', 'cheese from chipotle', 'chipotle shredded cheese',
   'shredded cheese chipotle'],
 'toppings', 'Chipotle', 1,
 '110 cal per 1oz. Monterey Jack and white cheddar blend. 190mg sodium, 5g sat fat.', TRUE),

-- Queso Blanco: 120 cal, 5P, 3C, 11F per 2oz (57g)
('chipotle_queso', 'Chipotle Queso Blanco', 210.5, 8.8, 5.3, 19.3,
 1.8, 0.0, 57, NULL,
 'manufacturer', ARRAY['chipotle queso', 'queso from chipotle', 'chipotle queso blanco',
   'queso blanco chipotle', 'chipotle white queso'],
 'toppings', 'Chipotle', 1,
 '120 cal per 2oz. Queso blanco with peppers. 200mg sodium, 5g sat fat.', TRUE),

-- Fajita Veggies: 20 cal, 1P, 4C, 0.5F per 2.5oz (71g)
('chipotle_fajita_veggies', 'Chipotle Fajita Veggies', 28.2, 1.4, 5.6, 0.7,
 1.4, 0.0, 71, NULL,
 'manufacturer', ARRAY['chipotle fajita veggies', 'fajita veggies from chipotle',
   'chipotle fajita vegetables', 'chipotle peppers and onions'],
 'toppings', 'Chipotle', 1,
 '20 cal per 2.5oz. Grilled bell peppers and onions.', TRUE),

-- Tomato Salsa (Pico de Gallo): 25 cal, 0P, 4C, 0F per 3.5oz (100g)
('chipotle_tomato_salsa', 'Chipotle Fresh Tomato Salsa', 25.0, 0.0, 4.0, 0.0,
 1.0, 2.0, 100, NULL,
 'manufacturer', ARRAY['chipotle tomato salsa', 'chipotle pico de gallo', 'pico from chipotle',
   'chipotle pico', 'fresh tomato salsa chipotle'],
 'salsa', 'Chipotle', 1,
 '25 cal per 3.5oz. Fresh pico de gallo.', TRUE),

-- Roasted Chili-Corn Salsa: 80 cal, 3P, 15C, 1F per 3.5oz (100g)
('chipotle_corn_salsa', 'Chipotle Roasted Chili-Corn Salsa', 80.0, 3.0, 15.0, 1.0,
 2.0, 2.0, 100, NULL,
 'manufacturer', ARRAY['chipotle corn salsa', 'corn salsa from chipotle',
   'chipotle roasted corn salsa', 'roasted chili corn salsa chipotle'],
 'salsa', 'Chipotle', 1,
 '80 cal per 3.5oz. Roasted corn with chili and lime.', TRUE),

-- Tomatillo Green-Chili Salsa: 15 cal, 0P, 3C, 0F per 2oz (57g)
('chipotle_green_salsa', 'Chipotle Tomatillo Green-Chili Salsa', 26.3, 0.0, 5.3, 0.0,
 0.0, 0.0, 57, NULL,
 'manufacturer', ARRAY['chipotle green salsa', 'chipotle tomatillo green salsa',
   'green salsa from chipotle', 'chipotle verde salsa'],
 'salsa', 'Chipotle', 1,
 '15 cal per 2oz. Medium-hot tomatillo salsa.', TRUE),

-- Tomatillo Red-Chili Salsa: 30 cal, 0P, 4C, 1F per 2oz (57g)
('chipotle_red_salsa', 'Chipotle Tomatillo Red-Chili Salsa', 52.6, 0.0, 7.0, 1.8,
 0.0, 0.0, 57, NULL,
 'manufacturer', ARRAY['chipotle red salsa', 'chipotle tomatillo red salsa',
   'red salsa from chipotle', 'chipotle hot salsa'],
 'salsa', 'Chipotle', 1,
 '30 cal per 2oz. Hot tomatillo-red chili salsa.', TRUE),

-- Romaine Lettuce: 5 cal, 0P, 1C, 0F per 1oz (28g)
('chipotle_lettuce', 'Chipotle Romaine Lettuce', 17.9, 0.0, 3.6, 0.0,
 1.8, 0.0, 28, NULL,
 'manufacturer', ARRAY['chipotle lettuce', 'lettuce from chipotle',
   'chipotle romaine lettuce', 'romaine chipotle'],
 'toppings', 'Chipotle', 1,
 '5 cal per 1oz. Shredded romaine lettuce.', TRUE),

-- ═══════════════════════════════════════════════════════════════
-- TORTILLAS & SHELLS
-- ═══════════════════════════════════════════════════════════════

-- Flour Tortilla (Burrito): 320 cal, 8P, 50C, 9F per ~100g
('chipotle_flour_tortilla_burrito', 'Chipotle Flour Tortilla (Burrito)', 320.0, 8.0, 50.0, 9.0,
 2.0, 1.0, 100, NULL,
 'manufacturer', ARRAY['chipotle flour tortilla', 'chipotle burrito tortilla',
   'burrito tortilla chipotle', 'chipotle tortilla'],
 'tortillas', 'Chipotle', 1,
 '320 cal per tortilla (~100g). Large flour tortilla for burritos.', TRUE),

-- Flour Tortilla (Taco, soft): 80 cal, 2P, 13C, 2.5F per ~25g
('chipotle_flour_tortilla_taco', 'Chipotle Soft Flour Tortilla (Taco)', 320.0, 8.0, 52.0, 10.0,
 1.0, 0.0, 25, NULL,
 'manufacturer', ARRAY['chipotle soft taco tortilla', 'chipotle taco shell soft',
   'soft flour tortilla chipotle'],
 'tortillas', 'Chipotle', 1,
 '80 cal per tortilla (~25g). Small soft flour taco tortilla.', TRUE),

-- Crispy Corn Tortilla (Taco): 70 cal, 1P, 10C, 3F per ~20g
('chipotle_crispy_corn_tortilla', 'Chipotle Crispy Corn Tortilla', 350.0, 5.0, 50.0, 15.0,
 2.0, 0.0, 20, NULL,
 'manufacturer', ARRAY['chipotle crispy taco shell', 'chipotle corn tortilla',
   'crispy corn taco chipotle', 'chipotle hard taco shell'],
 'tortillas', 'Chipotle', 1,
 '70 cal per shell (~20g). Crispy corn taco shell.', TRUE),

-- ═══════════════════════════════════════════════════════════════
-- CHIPS & EXTRAS
-- ═══════════════════════════════════════════════════════════════

-- Chips: 540 cal, 7P, 73C, 26F per 4oz (113g)
('chipotle_chips', 'Chipotle Tortilla Chips', 477.9, 6.2, 64.6, 23.0,
 4.4, 0.0, 113, NULL,
 'manufacturer', ARRAY['chipotle chips', 'chipotle tortilla chips', 'chips from chipotle',
   'chipotle nachos chips'],
 'sides', 'Chipotle', 1,
 '540 cal per 4oz bag. Fried corn tortilla chips with lime and salt.', TRUE)

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
  is_active = EXCLUDED.is_active;
