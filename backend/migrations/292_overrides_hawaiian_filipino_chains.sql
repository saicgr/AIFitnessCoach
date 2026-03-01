-- ============================================================================
-- 292_overrides_hawaiian_filipino_chains.sql
-- Hawaiian/Filipino chains: L&L, Ono, Zippy's, Red Ribbon, Chowking, Max's
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES
('ll_bbq_chicken', 'L&L BBQ Chicken Plate', 136.0, 7.6, 14.4, 4.4, 0.5, 5.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l bbq chicken', 'l&l chicken plate', 'll hawaiian chicken'], '680 cal per plate (500g). Grilled chicken with 2 scoops rice, macaroni salad.', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ll_chicken_katsu', 'L&L Chicken Katsu Plate', 170.0, 7.0, 16.4, 8.0, 0.5, 2.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l chicken katsu', 'l&l katsu', 'll katsu plate'], '850 cal per plate (500g). Breaded fried chicken cutlet with rice, mac salad.', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ll_kalua_pig', 'L&L Kalua Pig Plate', 144.0, 6.8, 14.4, 6.0, 0.5, 1.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l kalua pork', 'l&l kalua pig', 'll kalua plate'], '720 cal per plate (500g). Slow-smoked shredded pork with cabbage.', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ll_loco_moco', 'L&L Loco Moco', 162.5, 6.7, 14.2, 8.3, 0.5, 1.5, NULL, 480, 'hawaiianbarbecue.com', ARRAY['l and l loco moco', 'l&l loco moco', 'll loco moco'], '780 cal per plate (480g). Hamburger patty over rice with egg and gravy.', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ll_spam_musubi', 'L&L Spam Musubi', 175.0, 6.3, 25.0, 5.0, 0.3, 2.0, 160, 160, 'hawaiianbarbecue.com', ARRAY['l and l spam musubi', 'l&l musubi', 'll spam musubi'], '280 cal per musubi (160g).', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ll_short_ribs', 'L&L Hawaiian BBQ Short Ribs Plate', 164.0, 7.2, 14.4, 8.0, 0.3, 3.0, NULL, 500, 'hawaiianbarbecue.com', ARRAY['l and l short ribs', 'l&l beef ribs', 'll kalbi ribs'], '820 cal per plate (500g). Korean-style marinated short ribs with rice.', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ll_mac_salad', 'L&L Macaroni Salad', 186.7, 2.7, 14.7, 13.3, 0.5, 2.0, NULL, 150, 'hawaiianbarbecue.com', ARRAY['l and l mac salad', 'l&l macaroni salad', 'll mac salad'], '280 cal per scoop (150g).', 'L&L Hawaiian BBQ', 'sides', 1),
('ll_garlic_shrimp', 'L&L Garlic Shrimp Plate', 156.3, 6.3, 15.4, 7.1, 0.3, 1.5, NULL, 480, 'hawaiianbarbecue.com', ARRAY['l and l garlic shrimp', 'l&l shrimp plate', 'll garlic shrimp'], '750 cal per plate (480g).', 'L&L Hawaiian BBQ', 'hawaiian', 1),
('ono_chicken_katsu', 'Ono Hawaiian BBQ Chicken Katsu', 164.0, 6.4, 16.0, 7.6, 0.5, 2.0, NULL, 500, 'onohawaiianbbq.com', ARRAY['ono chicken katsu', 'ono katsu plate'], '820 cal per plate (500g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),
('ono_bbq_mix', 'Ono Hawaiian BBQ Mix Plate', 163.6, 7.6, 13.5, 8.0, 0.5, 3.0, NULL, 550, 'onohawaiianbbq.com', ARRAY['ono mix plate', 'ono bbq combo'], '900 cal per plate (550g). Combo of chicken, beef, and shrimp.', 'Ono Hawaiian BBQ', 'hawaiian', 1),
('ono_kalbi_ribs', 'Ono Hawaiian BBQ Kalbi Short Ribs', 168.0, 7.2, 14.4, 8.4, 0.3, 4.0, NULL, 500, 'onohawaiianbbq.com', ARRAY['ono kalbi', 'ono short ribs', 'ono kalbi plate'], '840 cal per plate (500g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),
('ono_loco_moco', 'Ono Hawaiian BBQ Loco Moco', 159.6, 6.4, 14.0, 8.1, 0.5, 1.5, NULL, 470, 'onohawaiianbbq.com', ARRAY['ono loco moco'], '750 cal per plate (470g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),
('ono_spam_musubi', 'Ono Hawaiian BBQ Spam Musubi', 167.7, 5.8, 24.5, 4.5, 0.3, 1.5, 155, 155, 'onohawaiianbbq.com', ARRAY['ono spam musubi', 'ono musubi'], '260 cal per musubi (155g).', 'Ono Hawaiian BBQ', 'hawaiian', 1),
('zippys_zip_pac_chicken', 'Zippy''s Zip Pac Fried Chicken', 162.5, 7.1, 15.0, 7.5, 0.5, 2.0, NULL, 480, 'zippys.com', ARRAY['zippys fried chicken plate', 'zippys zip pac'], '780 cal per plate (480g). Fried chicken with rice, mac salad.', 'Zippy''s', 'hawaiian', 1),
('zippys_chili', 'Zippy''s Chili', 112.0, 7.2, 9.6, 4.8, 3.0, 2.0, NULL, 250, 'zippys.com', ARRAY['zippys famous chili', 'zippys chili bowl'], '280 cal per bowl (250g). Famous Zippy''s chili.', 'Zippy''s', 'soups', 1),
('zippys_korean_chicken', 'Zippy''s Korean Fried Chicken Plate', 170.0, 7.2, 15.6, 8.0, 0.5, 4.0, NULL, 500, 'zippys.com', ARRAY['zippys korean chicken'], '850 cal per plate (500g).', 'Zippy''s', 'hawaiian', 1),
('zippys_oxtail_soup', 'Zippy''s Oxtail Soup', 80.0, 5.5, 4.5, 4.5, 0.5, 1.0, NULL, 400, 'zippys.com', ARRAY['zippys oxtail', 'zippys oxtail stew'], '320 cal per bowl (400g).', 'Zippy''s', 'soups', 1),
('zippys_hamburger_steak', 'Zippy''s Hamburger Steak Plate', 150.0, 6.3, 14.2, 7.1, 0.5, 2.0, NULL, 480, 'zippys.com', ARRAY['zippys hamburger steak', 'zippys hamburgah steak'], '720 cal per plate (480g). With gravy, rice, mac salad.', 'Zippy''s', 'hawaiian', 1),
('red_ribbon_chicken_empanada', 'Red Ribbon Chicken Empanada', 254.5, 9.1, 25.5, 12.7, 1.0, 1.5, 110, 110, 'redribbonbakeshop.com', ARRAY['red ribbon empanada', 'red ribbon chicken pie'], '280 cal per empanada (110g).', 'Red Ribbon', 'filipino', 1),
('red_ribbon_mango_cake', 'Red Ribbon Mango Cake', 292.3, 3.8, 36.9, 15.4, 0.5, 28.0, 130, 130, 'redribbonbakeshop.com', ARRAY['red ribbon mango cake slice', 'red ribbon mango supreme'], '380 cal per slice (130g). Signature mango chiffon cake.', 'Red Ribbon', 'desserts', 1),
('red_ribbon_ube_cake', 'Red Ribbon Ube Cake', 291.7, 3.3, 36.7, 15.0, 0.5, 26.0, 120, 120, 'redribbonbakeshop.com', ARRAY['red ribbon ube cake slice', 'red ribbon purple yam cake'], '350 cal per slice (120g). Purple yam (ube) layer cake.', 'Red Ribbon', 'desserts', 1),
('red_ribbon_palabok', 'Red Ribbon Palabok Fiesta', 120.0, 4.3, 14.9, 4.6, 0.5, 1.0, NULL, 350, 'redribbonbakeshop.com', ARRAY['red ribbon palabok', 'red ribbon noodles'], '420 cal per 350g serving. Filipino rice noodles with shrimp sauce.', 'Red Ribbon', 'filipino', 1),
('red_ribbon_buko_pandan', 'Red Ribbon Buko Pandan', 186.7, 2.0, 25.3, 9.3, 0.5, 18.0, NULL, 150, 'redribbonbakeshop.com', ARRAY['red ribbon buko pandan salad'], '280 cal per 150g serving. Coconut pandan gelatin dessert.', 'Red Ribbon', 'desserts', 1),
('chowking_chao_fan', 'Chowking Chao Fan', 135.7, 4.3, 17.9, 5.0, 0.5, 1.0, NULL, 280, 'chowking.com', ARRAY['chowking fried rice', 'chowking chao fan'], '380 cal per 280g serving. Chinese-Filipino fried rice.', 'Chowking', 'filipino', 1),
('chowking_halo_halo', 'Chowking Halo-Halo', 97.1, 1.4, 17.7, 2.3, 0.5, 14.0, NULL, 350, 'chowking.com', ARRAY['chowking halo halo', 'chowking haluhalo'], '340 cal per 350g serving. Filipino shaved ice with beans, jellies, ube, leche flan.', 'Chowking', 'desserts', 1),
('chowking_chicken_lauriat', 'Chowking Chicken Lauriat', 151.1, 6.7, 16.0, 6.2, 0.5, 2.0, NULL, 450, 'chowking.com', ARRAY['chowking chicken meal', 'chowking fried chicken plate'], '680 cal per 450g plate. Fried chicken with rice, chao fan, siopao.', 'Chowking', 'filipino', 1),
('chowking_siopao', 'Chowking Siopao Asado', 215.4, 7.7, 29.2, 7.7, 0.5, 4.0, 130, 130, 'chowking.com', ARRAY['chowking siopao', 'chowking steamed bun'], '280 cal per bun (130g). Steamed bun with sweet pork filling.', 'Chowking', 'filipino', 1),
('maxs_fried_chicken', 'Max''s Fried Chicken (Quarter)', 172.7, 14.5, 5.5, 10.0, 0.0, 0.5, NULL, 220, 'maxsrestaurant.com', ARRAY['maxs chicken', 'maxs fried chicken', 'max restaurant chicken'], '380 cal per quarter (220g). Signature "sarap to the bones" fried chicken.', 'Max''s Restaurant', 'filipino', 1),
('maxs_pancit_canton', 'Max''s Pancit Canton', 116.7, 4.0, 15.3, 4.0, 1.0, 1.5, NULL, 300, 'maxsrestaurant.com', ARRAY['maxs pancit', 'maxs noodles', 'max restaurant noodles'], '350 cal per 300g serving. Stir-fried egg noodles with vegetables, meat.', 'Max''s Restaurant', 'filipino', 1),
('maxs_kare_kare', 'Max''s Kare-Kare', 120.0, 6.3, 5.1, 8.0, 1.5, 2.0, NULL, 350, 'maxsrestaurant.com', ARRAY['maxs kare kare', 'max restaurant kare kare'], '420 cal per 350g serving. Oxtail stew in peanut sauce with vegetables.', 'Max''s Restaurant', 'filipino', 1),
('maxs_sinigang', 'Max''s Sinigang na Baboy', 70.0, 4.5, 3.0, 4.5, 1.0, 1.5, NULL, 400, 'maxsrestaurant.com', ARRAY['maxs sinigang', 'max restaurant sinigang'], '280 cal per 400g bowl. Sour tamarind pork soup with vegetables.', 'Max''s Restaurant', 'filipino', 1),
('maxs_leche_flan', 'Max''s Leche Flan', 260.0, 6.0, 34.0, 12.0, 0.0, 30.0, 100, 100, 'maxsrestaurant.com', ARRAY['maxs flan', 'max restaurant leche flan'], '260 cal per 100g slice. Filipino caramel custard.', 'Max''s Restaurant', 'desserts', 1)

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
