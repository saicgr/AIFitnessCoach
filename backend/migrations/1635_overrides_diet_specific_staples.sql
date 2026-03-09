-- 1635_overrides_diet_specific_staples.sql
-- Remaining diet-specific staples: plant-based proteins, keto baking,
-- Nordic, sirtfood, anti-inflammatory, and generic bone broth.
-- Sources: USDA FoodData Central (fdc.nal.usda.gov).
-- All values per 100g. default_serving_g = typical serving weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- PLANT-BASED PROTEINS
-- ══════════════════════════════════════════

-- Seitan (vital wheat gluten, cooked): ~370 cal, 75g P, 14g C, 1.9g F per 100g dry; cooked ~150 cal, 28g P
('seitan_cooked', 'Seitan (Cooked)', 150, 28.0, 4.0, 1.0,
 0.5, 0.0, 85, NULL,
 'usda', ARRAY['seitan', 'cooked seitan', 'wheat gluten', 'wheat meat', 'mock duck', 'seitan steak', 'seitan strips'],
 'plant_protein', NULL, 1, '150 cal per 100g (128 cal per 85g serving). Made from vital wheat gluten. Highest protein plant food (28g/100g cooked). NOT gluten-free. Vegan meat alternative.', TRUE),

-- TVP (Textured Vegetable Protein), dry: USDA 174300. 336 cal, 52.0g P, 35.2g C, 1.2g F per 100g
('tvp_dry', 'TVP - Textured Vegetable Protein (Dry)', 336, 52.0, 35.2, 1.2,
 17.5, 0.0, 24, NULL,
 'usda', ARRAY['tvp', 'textured vegetable protein', 'soy protein', 'soy meat', 'textured soy protein', 'soy chunks', 'soya mince'],
 'plant_protein', NULL, 1, '336 cal per 100g dry (81 cal per 24g/1/4 cup dry, rehydrates to ~1/2 cup). Budget vegan protein. Very high protein and fiber. Use as ground meat replacement. Absorbs flavors well.', TRUE),

-- Vital wheat gluten (flour): USDA 168918. 370 cal, 75.2g P, 13.8g C, 1.9g F per 100g
('vital_wheat_gluten', 'Vital Wheat Gluten (Flour)', 370, 75.2, 13.8, 1.9,
 0.6, 0.0, 30, NULL,
 'usda', ARRAY['vital wheat gluten', 'wheat gluten flour', 'seitan flour', 'gluten flour', 'wheat gluten powder'],
 'flour', NULL, 1, '370 cal per 100g (111 cal per 30g/1/4 cup). Raw ingredient for making seitan. 75% protein — highest of any flour. Add to bread for extra chewiness and protein.', TRUE),

-- ══════════════════════════════════════════
-- KETO BAKING STAPLES
-- ══════════════════════════════════════════

-- Psyllium husk powder: USDA 170902. 168 cal, 0g P, 89g C (81g fiber), 0.6g F per 100g
('psyllium_husk_powder', 'Psyllium Husk Powder', 168, 0.0, 89.0, 0.6,
 81.0, 0.0, 5, NULL,
 'usda', ARRAY['psyllium husk', 'psyllium husk powder', 'psyllium fiber', 'ispaghula husk', 'metamucil fiber', 'psyllium powder'],
 'supplement', NULL, 1, '168 cal per 100g (8 cal per 5g/1 tsp). 81g fiber per 100g — almost pure soluble fiber. Essential for keto bread/baking. Also used as fiber supplement for digestive health.', TRUE),

-- Erythritol: 0 cal per 100g (sugar alcohol, not metabolized)
('erythritol', 'Erythritol (Sugar Substitute)', 0, 0.0, 100.0, 0.0,
 0.0, 0.0, 4, NULL,
 'usda', ARRAY['erythritol', 'erythritol sweetener', 'swerve sweetener', 'keto sweetener', 'sugar free sweetener', 'zero calorie sweetener'],
 'sweetener', NULL, 1, '0 cal per 100g (0 cal per tsp/4g). Zero-calorie sugar alcohol. 70% sweetness of sugar. No blood sugar impact (GI = 0). Most well-tolerated sugar alcohol. Keto/diabetic staple.', TRUE),

-- Xanthan gum: USDA 169721. 333 cal, 0g P, 77g C, 0g F per 100g (but used in tiny amounts)
('xanthan_gum', 'Xanthan Gum', 333, 0.0, 77.0, 0.0,
 77.0, 0.0, 1, NULL,
 'usda', ARRAY['xanthan gum', 'xanthan gum powder', 'xanthan', 'gf baking xanthan', 'gluten free binder'],
 'baking_ingredient', NULL, 1, '333 cal per 100g (3 cal per 1g serving — typical use). Thickener and binder for gluten-free/keto baking. Replaces gluten structure. Use 1/4-1 tsp per recipe.', TRUE),

-- ══════════════════════════════════════════
-- NORDIC DIET
-- ══════════════════════════════════════════

-- Rye crispbread (Wasa-style): USDA 168929. 366 cal, 10.0g P, 76.3g C, 2.0g F per 100g
('rye_crispbread', 'Rye Crispbread', 366, 10.0, 76.3, 2.0,
 16.5, 1.3, NULL, 12,
 'usda', ARRAY['rye crispbread', 'wasa crispbread', 'rye crackers', 'scandinavian crispbread', 'knäckebröd', 'finnish crispbread'],
 'bread', NULL, 1, '366 cal per 100g (44 cal per cracker/12g). Traditional Nordic flatbread. Very high in fiber (16.5g/100g). Low moisture = long shelf life. Eaten with cheese, smoked fish, or butter.', TRUE),

-- Lingonberry, fresh: ~50 cal, 0.4g P, 12g C, 0.5g F per 100g
('lingonberry_fresh', 'Lingonberry (Fresh)', 50, 0.4, 12.0, 0.5,
 2.5, 6.5, 140, NULL,
 'usda', ARRAY['lingonberry', 'lingonberries', 'fresh lingonberry', 'cowberry', 'lingon', 'scandinavian lingonberry'],
 'berry', NULL, 1, '50 cal per 100g (70 cal per 1 cup/140g). Scandinavian tart berry. Rich in anthocyanins, quercetin, and resveratrol. Traditionally served with meatballs. Higher in antioxidants than cranberries.', TRUE),

-- ══════════════════════════════════════════
-- ANTI-INFLAMMATORY / AIP STAPLES
-- ══════════════════════════════════════════

-- Turmeric powder: USDA 172231. 312 cal, 9.7g P, 67.1g C, 3.3g F per 100g
('turmeric_powder', 'Turmeric Powder (Ground)', 312, 9.7, 67.1, 3.3,
 22.7, 3.2, 3, NULL,
 'usda', ARRAY['turmeric', 'turmeric powder', 'ground turmeric', 'turmeric spice', 'haldi', 'curcumin spice'],
 'spice', NULL, 1, '312 cal per 100g (9 cal per 1 tsp/3g). Active compound curcumin is a potent anti-inflammatory. Combine with black pepper (piperine) for 2000% better absorption. AIP/anti-inflammatory diet essential.', TRUE),

-- Ginger root, raw: USDA 169231. 80 cal, 1.8g P, 17.8g C, 0.8g F per 100g
('ginger_root_raw', 'Ginger Root (Raw)', 80, 1.8, 17.8, 0.8,
 2.0, 1.7, 11, NULL,
 'usda', ARRAY['ginger', 'ginger root', 'raw ginger', 'fresh ginger', 'ginger root raw', 'whole ginger'],
 'spice', NULL, 1, '80 cal per 100g (9 cal per 1 tbsp/11g grated). Contains gingerols — anti-inflammatory, anti-nausea. Used in tea, stir-fries, and juicing. AIP-compliant. Aids digestion.', TRUE),

-- Dark chocolate 85% cacao: USDA 170273. 590 cal, 12.6g P, 36.7g C, 46.3g F per 100g
('dark_chocolate_85', 'Dark Chocolate (85% Cacao)', 590, 12.6, 36.7, 46.3,
 11.2, 14.0, 40, NULL,
 'usda', ARRAY['dark chocolate', 'dark chocolate 85', '85% dark chocolate', 'high cacao chocolate', 'extra dark chocolate', 'dark chocolate bar', '85 percent cacao'],
 'snack', NULL, 1, '590 cal per 100g (236 cal per 40g serving). Sirtfood diet staple. Rich in flavanols, magnesium, iron, and copper. 85%+ cacao = low sugar, high antioxidants. Moderate daily intake associated with heart health.', TRUE),

-- ══════════════════════════════════════════
-- SIRTFOOD DIET SPECIFIC
-- ══════════════════════════════════════════

-- Bird's eye chili: ~40 cal, 2g P, 8.8g C, 0.4g F per 100g
('birds_eye_chili', 'Bird''s Eye Chili', 40, 2.0, 8.8, 0.4,
 1.5, 5.3, 5, NULL,
 'usda', ARRAY['birds eye chili', 'bird eye chili', 'thai chili', 'thai chili pepper', 'prik kee noo', 'small hot chili', 'bird pepper'],
 'vegetable', NULL, 1, '40 cal per 100g (2 cal per pepper/5g). Very hot chili (50,000-100,000 Scoville). Contains capsaicin — sirtuin activator. Sirtfood diet inclusion. Boosts metabolism.', TRUE),

-- Lovage, fresh herb: ~20 cal, 3.3g P, 0g C, 0.4g F per 100g (est. similar to celery leaves)
('lovage_herb', 'Lovage (Fresh Herb)', 20, 3.3, 0.0, 0.4,
 0.0, 0.0, 5, NULL,
 'usda', ARRAY['lovage', 'lovage herb', 'fresh lovage', 'lovage leaves', 'levisticum officinale', 'celery herb'],
 'herb', NULL, 1, '20 cal per 100g (1 cal per 5g sprig). Celery-flavored herb, sirtuin activator. One of the top 20 Sirtfoods. Rich in quercetin. Used in soups, stocks, and salads. Uncommon but nutritionally potent.', TRUE),

-- ══════════════════════════════════════════
-- GENERIC BONE BROTH (not branded)
-- ══════════════════════════════════════════

-- Generic beef bone broth: ~17 cal, 3.6g P, 0.5g C, 0.1g F per 100g (USDA 172402-based)
('generic_beef_bone_broth', 'Beef Bone Broth (Generic)', 17, 3.6, 0.5, 0.1,
 0.0, 0.0, 240, NULL,
 'usda', ARRAY['beef bone broth', 'bone broth beef', 'homemade bone broth', 'beef broth', 'bone broth', 'slow cooked bone broth'],
 'broth', NULL, 1, '17 cal per 100g (41 cal per 1 cup/240ml). Rich in collagen, glycine, and gelatin. Anti-inflammatory, supports gut lining. Carnivore/keto/AIP staple. Homemade version.', TRUE),

-- Generic chicken bone broth: ~15 cal, 3.2g P, 0.4g C, 0.1g F per 100g (USDA 172403-based)
('generic_chicken_bone_broth', 'Chicken Bone Broth (Generic)', 15, 3.2, 0.4, 0.1,
 0.0, 0.0, 240, NULL,
 'usda', ARRAY['chicken bone broth', 'bone broth chicken', 'chicken broth homemade', 'homemade chicken broth', 'chicken stock bone broth'],
 'broth', NULL, 1, '15 cal per 100g (36 cal per 1 cup/240ml). Lighter flavor than beef. Rich in collagen and amino acids (glycine, proline). Supports joint and gut health. Whole30/AIP compliant.', TRUE)

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
