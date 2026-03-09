-- 1634_overrides_fish_seafood_expansion.sql
-- Fish & seafood expansion for Mediterranean, Nordic, pescatarian diets.
-- Oily fish, white fish, and shellfish.
-- Sources: USDA FoodData Central (fdc.nal.usda.gov).
-- All values per 100g cooked. default_serving_g = typical serving weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- OILY FISH (cooked)
-- ══════════════════════════════════════════

-- Sardines, canned in oil (drained): USDA 175139. 208 cal, 24.6g P, 0.0g C, 11.5g F per 100g
('sardines_canned_oil', 'Sardines (Canned in Oil, Drained)', 208, 24.6, 0.0, 11.5,
 0.0, 0.0, 92, NULL,
 'usda', ARRAY['sardines', 'canned sardines', 'sardines in oil', 'sardines canned', 'tinned sardines', 'sardine can'],
 'fish', NULL, 1, '208 cal per 100g (191 cal per can/92g drained). Extremely rich in omega-3, calcium (edible bones), B12, and vitamin D. One of the most nutrient-dense foods.', TRUE),

-- Mackerel, Atlantic cooked: USDA 175113. 262 cal, 23.9g P, 0.0g C, 17.8g F per 100g
('mackerel_cooked', 'Mackerel (Cooked)', 262, 23.9, 0.0, 17.8,
 0.0, 0.0, 88, NULL,
 'usda', ARRAY['mackerel', 'cooked mackerel', 'atlantic mackerel', 'baked mackerel', 'grilled mackerel', 'mackerel fillet'],
 'fish', NULL, 1, '262 cal per 100g (231 cal per fillet/88g). Very high in omega-3 (2.6g per serving). Rich in B12, selenium, and niacin. Nordic/Mediterranean diet staple.', TRUE),

-- Herring, Atlantic cooked: USDA 175096. 203 cal, 23.0g P, 0.0g C, 11.6g F per 100g
('herring_cooked', 'Herring (Cooked)', 203, 23.0, 0.0, 11.6,
 0.0, 0.0, 143, NULL,
 'usda', ARRAY['herring', 'cooked herring', 'atlantic herring', 'smoked herring', 'pickled herring', 'kippered herring', 'kipper'],
 'fish', NULL, 1, '203 cal per 100g (290 cal per fillet/143g). Omega-3 rich oily fish. Popular smoked or pickled in Nordic/Dutch cuisine. Excellent source of vitamin D and B12.', TRUE),

-- Anchovies, canned in oil: USDA 175137. 210 cal, 28.9g P, 0.0g C, 9.7g F per 100g
('anchovies_canned', 'Anchovies (Canned in Oil)', 210, 28.9, 0.0, 9.7,
 0.0, 0.0, 45, NULL,
 'usda', ARRAY['anchovies', 'canned anchovies', 'anchovy fillets', 'anchovies in oil', 'tinned anchovies'],
 'fish', NULL, 1, '210 cal per 100g (95 cal per can/45g). Intense umami flavor, used in Caesar dressing and Mediterranean cooking. Very high in omega-3, niacin, and selenium.', TRUE),

-- Rainbow trout, cooked: USDA 175154. 150 cal, 20.8g P, 0.0g C, 6.6g F per 100g
('rainbow_trout_cooked', 'Rainbow Trout (Cooked)', 150, 20.8, 0.0, 6.6,
 0.0, 0.0, 143, NULL,
 'usda', ARRAY['rainbow trout', 'trout', 'cooked trout', 'baked trout', 'grilled trout', 'pan fried trout', 'steelhead trout'],
 'fish', NULL, 1, '150 cal per 100g (215 cal per fillet/143g). Mild freshwater fish, rich in omega-3. Sustainably farmed option. Good source of B12, niacin, and phosphorus.', TRUE),

-- ══════════════════════════════════════════
-- WHITE FISH (cooked)
-- ══════════════════════════════════════════

-- Halibut, Atlantic/Pacific cooked: USDA 175068. 111 cal, 22.5g P, 0.0g C, 1.6g F per 100g
('halibut_cooked', 'Halibut (Cooked)', 111, 22.5, 0.0, 1.6,
 0.0, 0.0, 159, NULL,
 'usda', ARRAY['halibut', 'cooked halibut', 'baked halibut', 'grilled halibut', 'halibut fillet', 'pacific halibut', 'atlantic halibut'],
 'fish', NULL, 1, '111 cal per 100g (176 cal per fillet/159g). Lean, firm white fish. Excellent protein-to-calorie ratio. Rich in selenium, niacin, and magnesium.', TRUE),

-- Mahi-mahi, cooked: USDA 175080. 109 cal, 23.7g P, 0.0g C, 0.9g F per 100g
('mahi_mahi_cooked', 'Mahi-Mahi (Cooked)', 109, 23.7, 0.0, 0.9,
 0.0, 0.0, 170, NULL,
 'usda', ARRAY['mahi mahi', 'mahi-mahi', 'cooked mahi mahi', 'dolphinfish', 'dorado fish', 'grilled mahi mahi', 'mahi mahi fillet'],
 'fish', NULL, 1, '109 cal per 100g (185 cal per fillet/170g). Very lean tropical fish, mild sweet flavor. One of the leanest fish options. High in B vitamins and selenium.', TRUE),

-- Swordfish, cooked: USDA 175151. 144 cal, 23.5g P, 0.0g C, 4.7g F per 100g
('swordfish_cooked', 'Swordfish (Cooked)', 144, 23.5, 0.0, 4.7,
 0.0, 0.0, 136, NULL,
 'usda', ARRAY['swordfish', 'cooked swordfish', 'grilled swordfish', 'swordfish steak', 'swordfish fillet'],
 'fish', NULL, 1, '144 cal per 100g (196 cal per steak/136g). Firm, meaty fish. Good source of omega-3, selenium, and vitamin D. Note: higher mercury — limit to 1-2x per week.', TRUE),

-- Sea bass, cooked: USDA 175142. 124 cal, 23.6g P, 0.0g C, 2.6g F per 100g
('sea_bass_cooked', 'Sea Bass (Cooked)', 124, 23.6, 0.0, 2.6,
 0.0, 0.0, 129, NULL,
 'usda', ARRAY['sea bass', 'cooked sea bass', 'grilled sea bass', 'sea bass fillet', 'chilean sea bass', 'branzino', 'european sea bass'],
 'fish', NULL, 1, '124 cal per 100g (160 cal per fillet/129g). Mild, buttery white fish. Popular in Mediterranean cuisine (branzino). Good source of protein and selenium.', TRUE),

-- Catfish, cooked: USDA 175048. 122 cal, 16.4g P, 0.0g C, 5.8g F per 100g
('catfish_cooked', 'Catfish (Cooked)', 122, 16.4, 0.0, 5.8,
 0.0, 0.0, 87, NULL,
 'usda', ARRAY['catfish', 'cooked catfish', 'baked catfish', 'fried catfish', 'catfish fillet', 'channel catfish'],
 'fish', NULL, 1, '122 cal per 100g (106 cal per fillet/87g). Mild freshwater fish, Southern US staple. Low in mercury. Good source of B12 and phosphorus.', TRUE),

-- ══════════════════════════════════════════
-- SHELLFISH (cooked)
-- ══════════════════════════════════════════

-- Oysters, Eastern cooked (steamed): USDA 175175. 81 cal, 9.5g P, 4.9g C, 2.7g F per 100g
('oysters_cooked', 'Oysters (Cooked)', 81, 9.5, 4.9, 2.7,
 0.0, 0.0, 84, NULL,
 'usda', ARRAY['oysters', 'cooked oysters', 'steamed oysters', 'raw oysters', 'oyster', 'eastern oysters', 'pacific oysters'],
 'shellfish', NULL, 1, '81 cal per 100g (68 cal per 6 medium/84g). Richest food source of zinc (600%+ DV). Extremely high in B12, copper, and iron. Also high in omega-3.', TRUE),

-- Mussels, blue cooked: USDA 175167. 172 cal, 23.8g P, 7.4g C, 4.5g F per 100g
('mussels_cooked', 'Mussels (Cooked)', 172, 23.8, 7.4, 4.5,
 0.0, 0.0, 150, NULL,
 'usda', ARRAY['mussels', 'cooked mussels', 'steamed mussels', 'blue mussels', 'mussels in white wine', 'moules'],
 'shellfish', NULL, 1, '172 cal per 100g (258 cal per 1 cup/150g). High protein, rich in B12 (1700% DV), iron, manganese, and selenium. Sustainable seafood choice.', TRUE),

-- Scallops, cooked (steamed): USDA 175181. 111 cal, 20.5g P, 5.4g C, 0.8g F per 100g
('scallops_cooked', 'Scallops (Cooked)', 111, 20.5, 5.4, 0.8,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['scallops', 'cooked scallops', 'seared scallops', 'bay scallops', 'sea scallops', 'pan seared scallops'],
 'shellfish', NULL, 1, '111 cal per 100g (94 cal per 85g/3oz serving). Very lean shellfish, slightly sweet. Rich in B12, magnesium, and phosphorus. Low fat, high protein.', TRUE),

-- Calamari/Squid, cooked: USDA 175188. 175 cal, 17.9g P, 7.8g C, 7.5g F per 100g
('calamari_cooked', 'Calamari / Squid (Cooked)', 175, 17.9, 7.8, 7.5,
 0.0, 0.0, 85, NULL,
 'usda', ARRAY['calamari', 'squid', 'cooked calamari', 'fried calamari', 'grilled calamari', 'squid rings', 'calamari rings'],
 'shellfish', NULL, 1, '175 cal per 100g (149 cal per 85g/3oz serving). Values for fried calamari. Grilled is lower (~92 cal). Good source of protein, B12, selenium, and copper.', TRUE),

-- Crab meat, cooked (blue crab): USDA 175161. 97 cal, 19.4g P, 0.0g C, 1.5g F per 100g
('crab_meat_cooked', 'Crab Meat (Cooked)', 97, 19.4, 0.0, 1.5,
 0.0, 0.0, 135, NULL,
 'usda', ARRAY['crab meat', 'crab', 'cooked crab', 'blue crab', 'crab legs', 'king crab', 'lump crab meat', 'crab meat cooked'],
 'shellfish', NULL, 1, '97 cal per 100g (131 cal per 1 cup/135g). Very lean protein. Rich in B12, zinc, copper, and selenium. Low calorie, high protein seafood.', TRUE),

-- Lobster, cooked (Northern): USDA 175165. 98 cal, 20.5g P, 0.5g C, 0.6g F per 100g
('lobster_cooked', 'Lobster (Cooked)', 98, 20.5, 0.5, 0.6,
 0.0, 0.0, 145, NULL,
 'usda', ARRAY['lobster', 'cooked lobster', 'lobster meat', 'lobster tail', 'maine lobster', 'steamed lobster', 'lobster boiled'],
 'shellfish', NULL, 1, '98 cal per 100g (142 cal per 145g tail). One of the leanest protein sources available. Rich in selenium, B12, and copper. Low fat, low calorie luxury seafood.', TRUE)

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
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
