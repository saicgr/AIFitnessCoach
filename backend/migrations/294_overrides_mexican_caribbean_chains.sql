-- ============================================================================
-- 294_overrides_mexican_caribbean_chains.sql
-- Mexican/Caribbean: Torchy's, Rubio's, Taco John's, On The Border, Golden Krust
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES
('torchys_trailer_park', 'Torchy''s Trailer Park Taco (Trashy)', 210.0, 11.0, 13.0, 13.0, 1.0, 1.5, 200, 200, 'torchystacos.com', ARRAY['torchys trailer park', 'torchys trashy taco'], '420 cal per taco (200g). Fried chicken, green chiles, cheese, pico, lettuce on flour tortilla.', 'Torchy''s Tacos', 'mexican', 1),
('torchys_democrat', 'Torchy''s Democrat Taco', 200.0, 9.5, 14.7, 11.6, 2.0, 2.0, 190, 190, 'torchystacos.com', ARRAY['torchys democrat taco'], '380 cal per taco (190g). Barbacoa, avocado, queso fresco, cilantro, lime on corn tortilla.', 'Torchy''s Tacos', 'mexican', 1),
('torchys_crossroads', 'Torchy''s Crossroads Taco', 194.4, 7.8, 16.7, 11.1, 2.5, 2.0, 180, 180, 'torchystacos.com', ARRAY['torchys crossroads', 'torchys veggie taco'], '350 cal per taco (180g). Roasted veggies, avocado, cheese on corn tortilla.', 'Torchy''s Tacos', 'mexican', 1),
('torchys_queso', 'Torchy''s Green Chile Queso', 186.7, 6.7, 10.7, 13.3, 0.5, 1.5, NULL, 150, 'torchystacos.com', ARRAY['torchys queso', 'torchys green chile queso'], '280 cal per 150g serving with chips.', 'Torchy''s Tacos', 'mexican', 1),
('torchys_brushfire', 'Torchy''s Brushfire Taco', 200.0, 12.0, 12.0, 12.0, 1.5, 3.0, 200, 200, 'torchystacos.com', ARRAY['torchys brushfire', 'torchys jamaican jerk chicken'], '400 cal per taco (200g). Jamaican jerk chicken, grilled jalapeños, slaw, diablo sauce.', 'Torchy''s Tacos', 'mexican', 1),
('torchys_fried_avocado', 'Torchy''s Fried Avocado Taco', 220.0, 5.0, 18.0, 15.0, 4.0, 1.5, 200, 200, 'torchystacos.com', ARRAY['torchys fried avocado', 'torchys avocado taco'], '440 cal per taco (200g). Beer-battered avocado with refried beans, cheese, lettuce.', 'Torchy''s Tacos', 'mexican', 1),
('rubios_original_fish_taco', 'Rubio''s Original Fish Taco', 193.8, 8.8, 17.5, 10.0, 1.5, 1.5, 160, 160, 'rubios.com', ARRAY['rubios fish taco', 'rubios original fish'], '310 cal per taco (160g). Beer-battered fish with white sauce, cabbage.', 'Rubio''s', 'mexican', 1),
('rubios_grilled_shrimp_taco', 'Rubio''s Grilled Shrimp Taco', 175.0, 10.0, 15.0, 8.8, 1.5, 1.5, 160, 160, 'rubios.com', ARRAY['rubios shrimp taco', 'rubios grilled shrimp'], '280 cal per taco (160g).', 'Rubio''s', 'mexican', 1),
('rubios_chicken_burrito', 'Rubio''s Coastal Grilled Chicken Burrito', 171.4, 8.6, 17.1, 7.1, 3.0, 2.0, 420, 420, 'rubios.com', ARRAY['rubios chicken burrito', 'rubios grilled chicken burrito'], '720 cal per burrito (420g).', 'Rubio''s', 'mexican', 1),
('rubios_shrimp_bowl', 'Rubio''s Salsa Verde Shrimp Bowl', 130.0, 7.0, 14.5, 4.5, 3.0, 2.0, NULL, 400, 'rubios.com', ARRAY['rubios shrimp bowl', 'rubios salsa verde bowl'], '520 cal per bowl (400g).', 'Rubio''s', 'mexican', 1),
('rubios_chips_guac', 'Rubio''s Chips & Guacamole', 211.1, 2.2, 20.0, 13.3, 3.5, 1.0, NULL, 180, 'rubios.com', ARRAY['rubios chips and guacamole', 'rubios guac'], '380 cal per 180g serving.', 'Rubio''s', 'mexican', 1),
('taco_johns_crispy_taco', 'Taco John''s Beef Crispy Taco', 211.8, 10.6, 15.3, 11.8, 1.5, 1.0, 85, 85, 'tacojohns.com', ARRAY['taco johns crispy taco', 'taco johns beef taco'], '180 cal per taco (85g).', 'Taco John''s', 'mexican', 1),
('taco_johns_meat_potato_burrito', 'Taco John''s Meat & Potato Burrito', 178.6, 6.4, 20.0, 7.9, 2.0, 1.5, 280, 280, 'tacojohns.com', ARRAY['taco johns meat potato burrito', 'taco johns potato burrito'], '500 cal per burrito (280g).', 'Taco John''s', 'mexican', 1),
('taco_johns_potato_oles', 'Taco John''s Potato Olés', 215.0, 2.5, 24.0, 12.0, 3.0, 0.5, NULL, 200, 'tacojohns.com', ARRAY['taco johns potato oles', 'taco johns oles', 'potato oles'], '430 cal per regular (200g). Signature seasoned potato rounds.', 'Taco John''s', 'sides', 1),
('taco_johns_chicken_quesadilla', 'Taco John''s Chicken Quesadilla', 208.7, 11.3, 15.7, 11.3, 1.0, 1.0, 230, 230, 'tacojohns.com', ARRAY['taco johns quesadilla', 'taco johns chicken quesadilla'], '480 cal per quesadilla (230g).', 'Taco John''s', 'mexican', 1),
('taco_johns_steak_burrito', 'Taco John''s Sirloin Steak Burrito', 180.0, 8.0, 18.0, 8.0, 2.0, 1.5, 300, 300, 'tacojohns.com', ARRAY['taco johns steak burrito'], '540 cal per burrito (300g).', 'Taco John''s', 'mexican', 1),
('otb_chicken_fajitas', 'On The Border Chicken Fajitas', 148.6, 10.9, 6.9, 8.6, 2.0, 3.0, NULL, 350, 'ontheborder.com', ARRAY['on the border chicken fajitas', 'otb chicken fajitas'], '520 cal for meat and veggie portion (350g). Excludes tortillas, sides.', 'On The Border', 'mexican', 1),
('otb_taco_salad', 'On The Border Grande Taco Salad', 173.3, 7.1, 11.6, 10.7, 3.0, 3.0, NULL, 450, 'ontheborder.com', ARRAY['on the border taco salad', 'otb taco salad'], '780 cal per 450g salad in taco shell.', 'On The Border', 'mexican', 1),
('otb_border_sampler', 'On The Border Border Sampler', 218.2, 7.6, 16.0, 13.1, 2.0, 2.5, NULL, 550, 'ontheborder.com', ARRAY['on the border sampler', 'otb appetizer sampler'], '1200 cal per platter (550g). Wings, quesadilla, flautas, queso.', 'On The Border', 'mexican', 1),
('otb_cheese_enchiladas', 'On The Border Tres Cheese Enchiladas', 194.3, 8.0, 13.7, 12.0, 2.0, 2.5, NULL, 350, 'ontheborder.com', ARRAY['on the border enchiladas', 'otb cheese enchiladas'], '680 cal per 3 enchiladas (350g).', 'On The Border', 'mexican', 1),
('otb_guacamole', 'On The Border House-Made Guacamole', 183.3, 2.5, 10.0, 15.0, 5.0, 1.0, NULL, 120, 'ontheborder.com', ARRAY['on the border guacamole', 'otb guac'], '220 cal per 120g serving (no chips).', 'On The Border', 'mexican', 1),
('otb_sopapillas', 'On The Border Sopapillas', 300.0, 3.8, 36.3, 15.0, 0.5, 16.0, NULL, 160, 'ontheborder.com', ARRAY['on the border sopapillas', 'otb sopapillas dessert'], '480 cal per serving (160g). Fried pastry with honey, whipped cream.', 'On The Border', 'desserts', 1),
('golden_krust_beef_patty', 'Golden Krust Beef Patty', 253.3, 8.0, 25.3, 13.3, 1.5, 1.5, 150, 150, 'goldenkrust.com', ARRAY['golden krust beef patty', 'golden krust jamaican patty'], '380 cal per patty (150g). Flaky pastry with seasoned ground beef.', 'Golden Krust', 'caribbean', 1),
('golden_krust_chicken_patty', 'Golden Krust Chicken Patty', 233.3, 9.3, 24.0, 10.7, 1.5, 1.0, 150, 150, 'goldenkrust.com', ARRAY['golden krust chicken patty'], '350 cal per patty (150g).', 'Golden Krust', 'caribbean', 1),
('golden_krust_jerk_chicken', 'Golden Krust Jerk Chicken Plate', 120.0, 8.0, 10.5, 4.5, 1.5, 2.0, NULL, 400, 'goldenkrust.com', ARRAY['golden krust jerk chicken', 'golden krust chicken plate'], '480 cal per plate (400g). Jerk chicken with rice and peas.', 'Golden Krust', 'caribbean', 1),
('golden_krust_oxtail', 'Golden Krust Oxtail Plate', 131.0, 6.7, 11.4, 6.2, 2.0, 1.5, NULL, 420, 'goldenkrust.com', ARRAY['golden krust oxtail', 'golden krust oxtail stew'], '550 cal per plate (420g). Braised oxtail with butter beans, rice.', 'Golden Krust', 'caribbean', 1),
('golden_krust_curry_goat', 'Golden Krust Curry Goat Plate', 130.0, 6.5, 11.5, 6.0, 1.5, 1.5, NULL, 400, 'goldenkrust.com', ARRAY['golden krust curry goat', 'golden krust goat curry'], '520 cal per plate (400g). Jamaican curry goat with rice and peas.', 'Golden Krust', 'caribbean', 1),
('golden_krust_coco_bread', 'Golden Krust Coco Bread', 280.0, 6.0, 38.0, 12.0, 1.0, 6.0, 100, 100, 'goldenkrust.com', ARRAY['golden krust coco bread', 'golden krust coconut bread'], '280 cal per bread (100g). Soft coconut bread, often stuffed with a patty.', 'Golden Krust', 'caribbean', 1)

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
