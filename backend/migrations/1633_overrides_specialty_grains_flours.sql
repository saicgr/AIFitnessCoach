-- 1633_overrides_specialty_grains_flours.sql
-- Specialty / ancient grains and alternative flours for paleo, keto,
-- gluten-free, and ethnic diets (Ethiopian, Indian, Middle Eastern).
-- Sources: USDA FoodData Central (fdc.nal.usda.gov).
-- All values per 100g. Grains = cooked, Flours = dry.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- ANCIENT / SPECIALTY GRAINS (cooked)
-- ══════════════════════════════════════════

-- Teff, cooked: USDA 169747. 101 cal, 3.9g P, 19.9g C, 0.6g F per 100g
('teff_cooked', 'Teff (Cooked)', 101, 3.9, 19.9, 0.6,
 2.8, 0.0, 252, NULL,
 'usda', ARRAY['teff', 'cooked teff', 'teff grain', 'teff porridge', 'ethiopian teff', 'injera grain'],
 'grain', NULL, 1, '101 cal per 100g (255 cal per 1 cup/252g). Ethiopian staple grain used for injera bread. Naturally gluten-free. High in iron, calcium, and resistant starch.', TRUE),

-- Millet, cooked: USDA 169702. 119 cal, 3.5g P, 23.7g C, 1.0g F per 100g
('millet_cooked', 'Millet (Cooked)', 119, 3.5, 23.7, 1.0,
 1.3, 0.0, 174, NULL,
 'usda', ARRAY['millet', 'cooked millet', 'millet grain', 'pearl millet', 'proso millet', 'millet porridge'],
 'grain', NULL, 1, '119 cal per 100g (207 cal per 1 cup/174g). Naturally gluten-free ancient grain. Alkaline-forming. Good source of magnesium and B vitamins. Common in African/Indian cuisine.', TRUE),

-- Buckwheat groats, cooked: USDA 170684. 92 cal, 3.4g P, 19.9g C, 0.6g F per 100g
('buckwheat_groats_cooked', 'Buckwheat Groats (Cooked)', 92, 3.4, 19.9, 0.6,
 2.7, 0.9, 168, NULL,
 'usda', ARRAY['buckwheat', 'buckwheat groats', 'cooked buckwheat', 'kasha', 'buckwheat kasha', 'soba grain', 'toasted buckwheat'],
 'grain', NULL, 1, '92 cal per 100g (155 cal per 1 cup/168g). Despite the name, completely gluten-free (not wheat). Rich in rutin (antioxidant). Sirtfood diet staple. Used for kasha, soba noodles.', TRUE),

-- Amaranth, cooked: USDA 170682. 102 cal, 3.8g P, 18.7g C, 1.6g F per 100g
('amaranth_cooked', 'Amaranth (Cooked)', 102, 3.8, 18.7, 1.6,
 2.1, 0.0, 246, NULL,
 'usda', ARRAY['amaranth', 'cooked amaranth', 'amaranth grain', 'amaranth porridge', 'popped amaranth'],
 'grain', NULL, 1, '102 cal per 100g (251 cal per 1 cup/246g). Ancient Aztec pseudocereal, gluten-free. Complete protein (all essential amino acids). High in manganese, iron, and phosphorus.', TRUE),

-- Spelt, cooked: USDA 169745. 127 cal, 5.5g P, 26.4g C, 0.9g F per 100g
('spelt_cooked', 'Spelt (Cooked)', 127, 5.5, 26.4, 0.9,
 3.9, 0.0, 194, NULL,
 'usda', ARRAY['spelt', 'cooked spelt', 'spelt berries', 'spelt grain', 'dinkel wheat', 'farro spelt'],
 'grain', NULL, 1, '127 cal per 100g (246 cal per 1 cup/194g). Ancient wheat relative with nutty flavor. Contains gluten but may be easier to digest than modern wheat. High in fiber and B vitamins.', TRUE),

-- Kamut/Khorasan wheat, cooked: USDA 169733. 146 cal, 6.5g P, 30.5g C, 0.9g F per 100g
('kamut_cooked', 'Kamut / Khorasan Wheat (Cooked)', 146, 6.5, 30.5, 0.9,
 4.0, 0.0, 172, NULL,
 'usda', ARRAY['kamut', 'cooked kamut', 'khorasan wheat', 'kamut berries', 'kamut grain', 'ancient wheat kamut'],
 'grain', NULL, 1, '146 cal per 100g (251 cal per 1 cup/172g). Ancient Egyptian grain, larger kernels than wheat. Contains gluten. Higher protein and selenium than modern wheat.', TRUE),

-- Fonio, cooked: ~110 cal, 3.6g P, 22g C, 0.4g F per 100g (est. from USDA/literature)
('fonio_cooked', 'Fonio (Cooked)', 110, 3.6, 22.0, 0.4,
 1.0, 0.0, 185, NULL,
 'usda', ARRAY['fonio', 'cooked fonio', 'fonio grain', 'acha grain', 'west african fonio', 'digitaria exilis'],
 'grain', NULL, 1, '110 cal per 100g (est. 204 cal per 1 cup/185g). West African ancient grain, naturally gluten-free. Cooks in 5 min. Rich in methionine and cystine (amino acids rare in grains).', TRUE),

-- Freekeh, cooked: ~100 cal, 4.0g P, 20g C, 0.5g F per 100g (est. from USDA/literature)
('freekeh_cooked', 'Freekeh (Cooked)', 100, 4.0, 20.0, 0.5,
 3.3, 0.0, 180, NULL,
 'usda', ARRAY['freekeh', 'cooked freekeh', 'freekeh grain', 'farik', 'green wheat freekeh', 'cracked freekeh', 'roasted green wheat'],
 'grain', NULL, 1, '100 cal per 100g (est. 180 cal per 1 cup/180g). Roasted young green wheat, smoky flavor. Contains gluten. Higher fiber and protein than mature wheat. Middle Eastern staple.', TRUE),

-- ══════════════════════════════════════════
-- ALTERNATIVE FLOURS (dry, per 100g)
-- ══════════════════════════════════════════

-- Almond flour: USDA 593740. 571 cal, 21.4g P, 21.4g C, 50.0g F per 100g
('almond_flour', 'Almond Flour', 571, 21.4, 21.4, 50.0,
 10.7, 3.6, 28, NULL,
 'usda', ARRAY['almond flour', 'almond meal', 'ground almonds', 'blanched almond flour', 'almond flour keto', 'almond powder'],
 'flour', NULL, 1, '571 cal per 100g (160 cal per 1/4 cup/28g). Keto/paleo baking essential. Naturally gluten-free. 1:1 replacement not possible with wheat flour — needs binding agents.', TRUE),

-- Tapioca flour/starch: USDA 169718. 358 cal, 0.0g P, 88.7g C, 0.0g F per 100g
('tapioca_flour', 'Tapioca Flour / Starch', 358, 0.0, 88.7, 0.0,
 0.9, 3.4, 30, NULL,
 'usda', ARRAY['tapioca flour', 'tapioca starch', 'tapioca powder', 'cassava starch', 'tapioca flour gf', 'manioc starch'],
 'flour', NULL, 1, '358 cal per 100g (107 cal per 30g/2 tbsp). Gluten-free thickener and baking ingredient. Creates chewy texture in baked goods. Used in Brazilian cheese bread (pão de queijo).', TRUE),

-- Arrowroot powder: USDA 169719. 357 cal, 0.3g P, 88.2g C, 0.1g F per 100g
('arrowroot_powder', 'Arrowroot Powder / Starch', 357, 0.3, 88.2, 0.1,
 3.4, 0.0, 16, NULL,
 'usda', ARRAY['arrowroot powder', 'arrowroot starch', 'arrowroot flour', 'arrowroot', 'arrowroot thickener'],
 'flour', NULL, 1, '357 cal per 100g (57 cal per 16g/2 tbsp). Paleo-friendly thickener. Neutral flavor. Gluten-free and grain-free. Thickens at lower temp than cornstarch.', TRUE),

-- Oat flour: USDA 169722. 404 cal, 14.7g P, 65.7g C, 9.1g F per 100g
('oat_flour', 'Oat Flour', 404, 14.7, 65.7, 9.1,
 6.5, 0.8, 30, NULL,
 'usda', ARRAY['oat flour', 'ground oats', 'oat flour gf', 'whole grain oat flour', 'oatmeal flour'],
 'flour', NULL, 1, '404 cal per 100g (121 cal per 30g/1/4 cup). Made from ground oats. Choose certified GF for celiac. Higher protein and fiber than white flour. Great for pancakes and muffins.', TRUE),

-- Chickpea flour (besan): USDA 174288. 387 cal, 22.4g P, 57.8g C, 6.7g F per 100g
('chickpea_flour_besan', 'Chickpea Flour (Besan)', 387, 22.4, 57.8, 6.7,
 10.8, 10.4, 30, NULL,
 'usda', ARRAY['chickpea flour', 'besan', 'gram flour', 'garbanzo flour', 'besan flour', 'chana flour', 'chickpea flour gf'],
 'flour', NULL, 1, '387 cal per 100g (116 cal per 30g/1/4 cup). Indian/Mediterranean staple flour. Naturally gluten-free. Very high protein and fiber for a flour. Used for socca, pakora, and farinata.', TRUE),

-- Tigernut flour: ~450 cal, 4.5g P, 66g C, 20g F per 100g (est. from manufacturers)
('tigernut_flour', 'Tigernut Flour', 450, 4.5, 66.0, 20.0,
 20.0, 20.0, 28, NULL,
 'usda', ARRAY['tigernut flour', 'tiger nut flour', 'chufa flour', 'tigernut powder', 'aip flour'],
 'flour', NULL, 1, '450 cal per 100g (126 cal per 28g/1/4 cup). Made from tiger nuts (tubers, not nuts). AIP/paleo compliant — nut-free, grain-free, gluten-free. Sweet, nutty flavor. High in resistant starch.', TRUE)

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
