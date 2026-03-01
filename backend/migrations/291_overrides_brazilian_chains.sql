-- ============================================================================
-- 291_overrides_brazilian_chains.sql
-- Brazilian steakhouses: Fogo de Chão, Texas de Brazil, Rodizio Grill, Tucanos
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES
('fogo_picanha', 'Fogo de Chão Picanha', 166.7, 17.3, 0.0, 10.7, 0.0, 0.0, NULL, 150, 'fogodechao.com', ARRAY['fogo de chao picanha', 'fogo sirloin cap', 'fogo picanha'], '250 cal per 150g serving. Signature top sirloin cap, fire-roasted.', 'Fogo de Chão', 'steak', 1),
('fogo_filet_mignon', 'Fogo de Chão Filet Mignon', 160.0, 22.7, 0.0, 7.3, 0.0, 0.0, NULL, 150, 'fogodechao.com', ARRAY['fogo de chao filet', 'fogo filet mignon', 'fogo medalhoes'], '240 cal per 150g serving. Bacon-wrapped filet.', 'Fogo de Chão', 'steak', 1),
('fogo_beef_ribs', 'Fogo de Chão Costela (Beef Ribs)', 211.1, 13.3, 0.0, 17.8, 0.0, 0.0, NULL, 180, 'fogodechao.com', ARRAY['fogo de chao ribs', 'fogo costela', 'fogo beef ribs'], '380 cal per 180g serving. Slow-roasted bone-in beef ribs.', 'Fogo de Chão', 'steak', 1),
('fogo_fraldinha', 'Fogo de Chão Fraldinha', 153.3, 18.7, 0.0, 8.7, 0.0, 0.0, NULL, 150, 'fogodechao.com', ARRAY['fogo de chao fraldinha', 'fogo bottom sirloin'], '230 cal per 150g serving.', 'Fogo de Chão', 'steak', 1),
('fogo_lamb_chops', 'Fogo de Chão Cordeiro (Lamb)', 186.7, 14.7, 0.0, 14.7, 0.0, 0.0, NULL, 150, 'fogodechao.com', ARRAY['fogo de chao lamb', 'fogo cordeiro', 'fogo lamb chops'], '280 cal per 150g serving.', 'Fogo de Chão', 'steak', 1),
('fogo_linguica', 'Fogo de Chão Linguiça', 266.7, 11.7, 1.7, 23.3, 0.0, 0.5, 120, 120, 'fogodechao.com', ARRAY['fogo de chao sausage', 'fogo linguica', 'fogo brazilian sausage'], '320 cal per link (120g).', 'Fogo de Chão', 'steak', 1),
('fogo_chicken_legs', 'Fogo de Chão Frango (Chicken)', 122.2, 14.4, 0.0, 6.7, 0.0, 0.0, NULL, 180, 'fogodechao.com', ARRAY['fogo de chao chicken', 'fogo frango'], '220 cal per leg (180g). Garlic-marinated chicken.', 'Fogo de Chão', 'chicken', 1),
('fogo_pao_de_queijo', 'Fogo de Chão Pão de Queijo', 320.0, 8.0, 36.0, 16.0, 0.5, 1.0, 25, 50, 'fogodechao.com', ARRAY['fogo cheese bread', 'fogo pao de queijo', 'fogo de chao cheese rolls'], '160 cal per 2 rolls (50g). Signature warm cheese bread.', 'Fogo de Chão', 'sides', 2),
('fogo_feijoada', 'Fogo de Chão Feijoada', 90.0, 6.0, 9.0, 3.0, 4.0, 1.0, NULL, 200, 'fogodechao.com', ARRAY['fogo de chao black beans', 'fogo feijoada', 'fogo brazilian beans'], '180 cal per 200g serving. Traditional Brazilian black bean stew.', 'Fogo de Chão', 'brazilian', 1),
('fogo_caramelized_bananas', 'Fogo de Chão Caramelized Bananas', 150.0, 0.8, 26.7, 5.0, 1.5, 20.0, NULL, 120, 'fogodechao.com', ARRAY['fogo de chao bananas', 'fogo bananas'], '180 cal per 120g serving.', 'Fogo de Chão', 'desserts', 1),
('fogo_papaya_cream', 'Fogo de Chão Papaya Cream', 146.7, 2.0, 18.7, 6.7, 1.0, 14.0, NULL, 150, 'fogodechao.com', ARRAY['fogo de chao papaya cream dessert'], '220 cal per 150g serving. Blended papaya with crème de cassis.', 'Fogo de Chão', 'desserts', 1),
('texas_brazil_picanha', 'Texas de Brazil Picanha', 160.0, 17.3, 0.0, 10.0, 0.0, 0.0, NULL, 150, 'texasdebrazil.com', ARRAY['texas de brazil picanha', 'texas de brazil sirloin'], '240 cal per 150g serving.', 'Texas de Brazil', 'steak', 1),
('texas_brazil_lamb', 'Texas de Brazil Lamb Chops', 180.0, 14.7, 0.0, 13.3, 0.0, 0.0, NULL, 150, 'texasdebrazil.com', ARRAY['texas de brazil lamb'], '270 cal per 150g serving.', 'Texas de Brazil', 'steak', 1),
('texas_brazil_filet', 'Texas de Brazil Filet Mignon', 153.3, 21.3, 0.0, 7.3, 0.0, 0.0, NULL, 150, 'texasdebrazil.com', ARRAY['texas de brazil filet mignon'], '230 cal per 150g serving. Bacon-wrapped.', 'Texas de Brazil', 'steak', 1),
('texas_brazil_alcatra', 'Texas de Brazil Garlic Sirloin', 140.0, 18.7, 0.7, 6.7, 0.0, 0.0, NULL, 150, 'texasdebrazil.com', ARRAY['texas de brazil alcatra', 'texas de brazil garlic sirloin'], '210 cal per 150g serving.', 'Texas de Brazil', 'steak', 1),
('texas_brazil_pork_ribs', 'Texas de Brazil Pork Ribs', 194.4, 12.2, 2.2, 15.6, 0.0, 2.0, NULL, 180, 'texasdebrazil.com', ARRAY['texas de brazil ribs'], '350 cal per 180g serving.', 'Texas de Brazil', 'steak', 1),
('texas_brazil_sausage', 'Texas de Brazil Linguiça', 272.7, 12.7, 1.8, 23.6, 0.0, 0.5, 110, 110, 'texasdebrazil.com', ARRAY['texas de brazil sausage', 'texas de brazil linguica'], '300 cal per link (110g).', 'Texas de Brazil', 'steak', 1),
('texas_brazil_cheese_bread', 'Texas de Brazil Cheese Bread', 311.1, 8.9, 35.6, 13.3, 0.3, 0.5, 23, 45, 'texasdebrazil.com', ARRAY['texas de brazil pao de queijo'], '140 cal per 2 rolls (45g).', 'Texas de Brazil', 'sides', 2),
('rodizio_picanha', 'Rodizio Grill Picanha', 156.7, 16.7, 0.0, 10.0, 0.0, 0.0, NULL, 150, 'rodiziogrill.com', ARRAY['rodizio picanha', 'rodizio grill sirloin cap'], '235 cal per 150g serving.', 'Rodizio Grill', 'steak', 1),
('rodizio_fraldinha', 'Rodizio Grill Fraldinha', 146.7, 17.3, 0.0, 8.0, 0.0, 0.0, NULL, 150, 'rodiziogrill.com', ARRAY['rodizio bottom sirloin', 'rodizio grill fraldinha'], '220 cal per 150g serving.', 'Rodizio Grill', 'steak', 1),
('rodizio_garlic_beef', 'Rodizio Grill Garlic Beef', 133.3, 18.7, 1.3, 6.0, 0.0, 0.0, NULL, 150, 'rodiziogrill.com', ARRAY['rodizio garlic steak', 'rodizio grill garlic beef'], '200 cal per 150g serving.', 'Rodizio Grill', 'steak', 1),
('rodizio_bacon_chicken', 'Rodizio Grill Bacon-Wrapped Chicken', 152.9, 16.5, 1.2, 9.4, 0.0, 0.0, NULL, 170, 'rodiziogrill.com', ARRAY['rodizio chicken', 'rodizio grill bacon chicken'], '260 cal per 170g serving.', 'Rodizio Grill', 'chicken', 1),
('rodizio_sausage', 'Rodizio Grill Brazilian Sausage', 254.5, 10.9, 1.8, 21.8, 0.0, 0.5, 110, 110, 'rodiziogrill.com', ARRAY['rodizio sausage', 'rodizio linguica'], '280 cal per link (110g).', 'Rodizio Grill', 'steak', 1),
('tucanos_picanha', 'Tucanos Picanha', 163.3, 17.3, 0.0, 10.7, 0.0, 0.0, NULL, 150, 'tucanos.com', ARRAY['tucanos picanha', 'tucanos sirloin cap'], '245 cal per 150g serving.', 'Tucanos', 'steak', 1),
('tucanos_filet_mignon', 'Tucanos Filet Mignon', 150.0, 21.3, 0.0, 6.7, 0.0, 0.0, NULL, 150, 'tucanos.com', ARRAY['tucanos filet'], '225 cal per 150g serving.', 'Tucanos', 'steak', 1),
('tucanos_garlic_parm_chicken', 'Tucanos Garlic Parmesan Chicken', 129.4, 16.5, 1.8, 5.9, 0.0, 0.5, NULL, 170, 'tucanos.com', ARRAY['tucanos chicken', 'tucanos garlic chicken'], '220 cal per 170g serving.', 'Tucanos', 'chicken', 1),
('tucanos_bacon_shrimp', 'Tucanos Bacon-Wrapped Shrimp', 166.7, 15.0, 1.7, 11.7, 0.0, 0.0, NULL, 120, 'tucanos.com', ARRAY['tucanos shrimp', 'tucanos bacon shrimp'], '200 cal per 120g serving.', 'Tucanos', 'seafood', 1),
('tucanos_pork_loin', 'Tucanos Pork Loin', 133.3, 18.7, 0.0, 6.0, 0.0, 0.0, NULL, 150, 'tucanos.com', ARRAY['tucanos pork'], '200 cal per 150g serving.', 'Tucanos', 'steak', 1)

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
