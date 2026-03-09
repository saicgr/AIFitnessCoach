-- 1620_overrides_bodybuilding_staples.sql
-- Bodybuilding staple packaged foods: high-protein yogurts, canned proteins,
-- rice cakes, high-protein cereals, flavored egg whites, frozen meals,
-- and protein pastries.
-- Sources: Package nutrition labels via oikos.com, starkist.com, bumblebee.com,
-- hormel.com, magicspoon.com, muscleegg.com, realgoodfoods.com,
-- eatlegendary.com, lundberg.com, quakeroats.com, fatsecret.com,
-- nutritionix.com, eatthismuch.com, walmart.com.
-- All values per 100g. default_serving_g or default_weight_per_piece_g = label serving.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- OIKOS TRIPLE ZERO — YOGURT
-- ══════════════════════════════════════════

-- Oikos Triple Zero Vanilla: 90 cal, 15g P, 7g C, 0g F, 0g fiber, 5g sugar / 150g cup
('oikos_tz_vanilla', 'Oikos Triple Zero Vanilla', 60, 10.0, 4.7, 0.0,
 0.0, 3.3, 150, NULL,
 'manufacturer', ARRAY['oikos triple zero vanilla', 'oikos triple zero vanilla yogurt', 'dannon oikos triple zero vanilla', 'triple zero vanilla greek yogurt', 'oikos tz vanilla'],
 'yogurt', 'Oikos', 1, '90 cal, 15g protein, 7g carbs, 0g fat per 150g cup. 0 added sugar, 0 artificial sweeteners, 0% fat.', TRUE),

-- Oikos Triple Zero Strawberry: 90 cal, 15g P, 7g C, 0g F, 0g fiber, 5g sugar / 150g cup
('oikos_tz_strawberry', 'Oikos Triple Zero Strawberry', 60, 10.0, 4.7, 0.0,
 0.0, 3.3, 150, NULL,
 'manufacturer', ARRAY['oikos triple zero strawberry', 'oikos triple zero strawberry yogurt', 'dannon oikos triple zero strawberry', 'triple zero strawberry greek yogurt', 'oikos tz strawberry'],
 'yogurt', 'Oikos', 1, '90 cal, 15g protein, 7g carbs, 0g fat per 150g cup. 0 added sugar, 0 artificial sweeteners, 0% fat.', TRUE),

-- Oikos Triple Zero Mixed Berry: 90 cal, 15g P, 7g C, 0g F, 0g fiber, 5g sugar / 150g cup
('oikos_tz_mixed_berry', 'Oikos Triple Zero Mixed Berry', 60, 10.0, 4.7, 0.0,
 0.0, 3.3, 150, NULL,
 'manufacturer', ARRAY['oikos triple zero mixed berry', 'oikos triple zero berry yogurt', 'dannon oikos triple zero mixed berry', 'triple zero mixed berry greek yogurt', 'oikos tz mixed berry'],
 'yogurt', 'Oikos', 1, '90 cal, 15g protein, 7g carbs, 0g fat per 150g cup. 0 added sugar, 0 artificial sweeteners, 0% fat.', TRUE),

-- ══════════════════════════════════════════
-- OIKOS PRO — YOGURT
-- ══════════════════════════════════════════

-- Oikos Pro Vanilla: 130 cal, 20g P, 6g C, 3g F, 0g fiber, 3g sugar / 150g cup
('oikos_pro_vanilla', 'Oikos Pro Vanilla', 87, 13.3, 4.0, 2.0,
 0.0, 2.0, 150, NULL,
 'manufacturer', ARRAY['oikos pro vanilla', 'oikos pro vanilla yogurt', 'dannon oikos pro vanilla', 'oikos pro 20g protein vanilla', 'oikos pro yogurt vanilla'],
 'yogurt', 'Oikos', 1, '130 cal, 20g protein, 6g carbs, 3g fat per 150g cup. Ultra-filtered milk, 0g added sugar.', TRUE),

-- Oikos Pro Plain: 140 cal, 20g P, 8g C, 3g F, 0g fiber, 3g sugar / 150g cup
('oikos_pro_plain', 'Oikos Pro Plain', 93, 13.3, 5.3, 2.0,
 0.0, 2.0, 150, NULL,
 'manufacturer', ARRAY['oikos pro plain', 'oikos pro plain yogurt', 'dannon oikos pro plain', 'oikos pro 20g protein plain', 'oikos pro yogurt plain'],
 'yogurt', 'Oikos', 1, '140 cal, 20g protein, 8g carbs, 3g fat per 150g cup. Ultra-filtered milk, 0g added sugar.', TRUE),

-- ══════════════════════════════════════════
-- STARKIST — CANNED PROTEIN
-- ══════════════════════════════════════════

-- StarKist Chunk Light Tuna in Water: 80 cal, 18g P, 0g C, 0.5g F / 56g drained (2oz can)
('starkist_chunk_light_tuna_water', 'StarKist Chunk Light Tuna in Water', 143, 32.1, 0.0, 0.9,
 0.0, 0.0, 56, NULL,
 'manufacturer', ARRAY['starkist chunk light tuna', 'starkist tuna in water', 'starkist canned tuna', 'starkist chunk light tuna water', 'starkist tuna can'],
 'canned_protein', 'StarKist', 1, '80 cal, 18g protein, 0g carbs, 0.5g fat per 56g drained can. Wild caught, gluten free.', TRUE),

-- StarKist Tuna Creations Ranch: 70 cal, 15g P, 1g C, 1g F / 74g pouch
('starkist_tuna_creations_ranch', 'StarKist Tuna Creations Ranch', 95, 20.3, 1.4, 1.4,
 0.0, 0.7, NULL, 74,
 'manufacturer', ARRAY['starkist tuna creations ranch', 'starkist ranch tuna', 'starkist tuna pouch ranch', 'tuna creations ranch', 'starkist ranch tuna pouch'],
 'canned_protein', 'StarKist', 1, '70 cal, 15g protein, 1g carbs, 1g fat per 74g pouch. Ready to eat, no draining needed.', TRUE),

-- StarKist Tuna Creations Lemon Pepper: 80 cal, 17g P, 0g C, 1g F / 74g pouch
('starkist_tuna_creations_lemon_pepper', 'StarKist Tuna Creations Lemon Pepper', 108, 23.0, 0.0, 1.4,
 0.0, 0.0, NULL, 74,
 'manufacturer', ARRAY['starkist tuna creations lemon pepper', 'starkist lemon pepper tuna', 'starkist tuna pouch lemon pepper', 'tuna creations lemon pepper', 'starkist zesty lemon pepper tuna'],
 'canned_protein', 'StarKist', 1, '80 cal, 17g protein, 0g carbs, 1g fat per 74g pouch. Lightly seasoned, ready to eat.', TRUE),

-- StarKist Tuna Creations Hot Buffalo: 70 cal, 15g P, 1g C, 0.5g F / 74g pouch
('starkist_tuna_creations_buffalo', 'StarKist Tuna Creations BOLD Hot Buffalo', 95, 20.3, 1.4, 0.7,
 0.0, 0.0, NULL, 74,
 'manufacturer', ARRAY['starkist tuna creations buffalo', 'starkist buffalo tuna', 'starkist hot buffalo tuna', 'tuna creations buffalo', 'starkist bold hot buffalo tuna'],
 'canned_protein', 'StarKist', 1, '70 cal, 15g protein, 1g carbs, 0.5g fat per 74g pouch. Bold hot buffalo flavor, ready to eat.', TRUE),

-- StarKist Tuna Creations Hickory Smoked: 110 cal, 17g P, 0g C, 4g F / 74g pouch
('starkist_tuna_creations_hickory_smoked', 'StarKist Tuna Creations Hickory Smoked', 149, 23.0, 0.0, 5.4,
 0.0, 0.0, NULL, 74,
 'manufacturer', ARRAY['starkist tuna creations hickory smoked', 'starkist hickory smoked tuna', 'starkist smoked tuna pouch', 'tuna creations hickory smoked', 'starkist hickory tuna'],
 'canned_protein', 'StarKist', 1, '110 cal, 17g protein, 0g carbs, 4g fat per 74g pouch. Hickory smoke flavored, ready to eat.', TRUE),

-- ══════════════════════════════════════════
-- BUMBLE BEE — CANNED PROTEIN
-- ══════════════════════════════════════════

-- Bumble Bee Solid White Albacore Tuna in Water: 60 cal, 13g P, 0g C, 0.5g F / 56g drained
('bumblebee_solid_white_albacore', 'Bumble Bee Solid White Albacore Tuna in Water', 107, 23.2, 0.0, 0.9,
 0.0, 0.0, 56, NULL,
 'manufacturer', ARRAY['bumble bee albacore tuna', 'bumble bee solid white tuna', 'bumble bee white albacore water', 'bumble bee tuna can', 'bumblebee albacore tuna'],
 'canned_protein', 'Bumble Bee', 1, '60 cal, 13g protein, 0g carbs, 0.5g fat per 56g drained. Premium solid white albacore in water.', TRUE),

-- Bumble Bee Canned Chicken Breast: 70 cal, 13g P, 0g C, 1.5g F / 56g drained
('bumblebee_chicken_breast', 'Bumble Bee Premium Chunk Chicken Breast in Water', 125, 23.2, 0.0, 2.7,
 0.0, 0.0, 56, NULL,
 'manufacturer', ARRAY['bumble bee chicken breast', 'bumble bee canned chicken', 'bumble bee chunk chicken breast', 'bumble bee chicken water', 'bumblebee chicken breast'],
 'canned_protein', 'Bumble Bee', 1, '70 cal, 13g protein, 0g carbs, 1.5g fat per 56g drained. Premium chunk white chicken in water.', TRUE),

-- ══════════════════════════════════════════
-- HORMEL — CANNED PROTEIN
-- ══════════════════════════════════════════

-- Hormel Premium Chunk Chicken Breast: 60 cal, 12g P, 0g C, 1.5g F / 56g drained
('hormel_chunk_chicken_breast', 'Hormel Premium Chunk Chicken Breast', 107, 21.4, 0.0, 2.7,
 0.0, 0.0, 56, NULL,
 'manufacturer', ARRAY['hormel chunk chicken breast', 'hormel canned chicken', 'hormel premium chunk chicken', 'hormel chicken breast water', 'hormel chicken breast can'],
 'canned_protein', 'Hormel', 1, '60 cal, 12g protein, 0g carbs, 1.5g fat per 56g drained. 98% fat free, shelf stable.', TRUE),

-- ══════════════════════════════════════════
-- RICE CAKES
-- ══════════════════════════════════════════

-- Lundberg Organic Brown Rice Cakes: 60 cal, 1g P, 14g C, 0.5g F / 18g cake
('lundberg_organic_rice_cakes', 'Lundberg Organic Brown Rice Cakes (Lightly Salted)', 333, 5.6, 77.8, 2.8,
 1.7, 0.0, NULL, 18,
 'manufacturer', ARRAY['lundberg rice cakes', 'lundberg organic rice cakes', 'lundberg brown rice cakes', 'lundberg rice cake lightly salted', 'lundberg organic brown rice cake'],
 'rice_cake', 'Lundberg', 1, '60 cal, 1g protein, 14g carbs, 0.5g fat per 18g cake. Organic whole grain brown rice, lightly salted.', TRUE),

-- Quaker Rice Cakes Lightly Salted: 35 cal, 0.4g P, 7.3g C, 0g F / 9g cake
('quaker_rice_cakes', 'Quaker Rice Cakes (Lightly Salted)', 389, 4.4, 81.1, 0.0,
 1.1, 0.0, NULL, 9,
 'manufacturer', ARRAY['quaker rice cakes', 'quaker lightly salted rice cakes', 'quaker rice cake', 'quaker plain rice cakes', 'quaker rice cakes lightly salted'],
 'rice_cake', 'Quaker', 1, '35 cal, 0.4g protein, 7.3g carbs, 0g fat per 9g cake. 100% whole grain, gluten free.', TRUE),

-- ══════════════════════════════════════════
-- MAGIC SPOON — CEREAL
-- ══════════════════════════════════════════

-- Magic Spoon Fruity: 150 cal, 13g P, 15g C, 8g F, 1g fiber, 0g sugar / 37g serving
('magicspoon_fruity', 'Magic Spoon Fruity Cereal', 405, 35.1, 40.5, 21.6,
 2.7, 0.0, 37, NULL,
 'manufacturer', ARRAY['magic spoon fruity', 'magic spoon fruity cereal', 'magic spoon cereal fruity', 'magicspoon fruity', 'magic spoon fruit cereal'],
 'cereal', 'Magic Spoon', 1, '150 cal, 13g protein, 15g carbs (4g net), 8g fat per 37g serving. 0g sugar, grain free, gluten free.', TRUE),

-- Magic Spoon Cocoa: 140 cal, 13g P, 15g C, 7g F, 2g fiber, 0g sugar / 37g serving
('magicspoon_cocoa', 'Magic Spoon Cocoa Cereal', 378, 35.1, 40.5, 18.9,
 5.4, 0.0, 37, NULL,
 'manufacturer', ARRAY['magic spoon cocoa', 'magic spoon cocoa cereal', 'magic spoon chocolate cereal', 'magicspoon cocoa', 'magic spoon cocoa chocolate'],
 'cereal', 'Magic Spoon', 1, '140 cal, 13g protein, 15g carbs (4g net), 7g fat per 37g serving. 0g sugar, grain free, gluten free.', TRUE),

-- Magic Spoon Peanut Butter: 170 cal, 14g P, 10g C, 9g F, 1g fiber, 0g sugar / 36g serving
('magicspoon_peanut_butter', 'Magic Spoon Peanut Butter Cereal', 472, 38.9, 27.8, 25.0,
 2.8, 0.0, 36, NULL,
 'manufacturer', ARRAY['magic spoon peanut butter', 'magic spoon pb cereal', 'magic spoon peanut butter cereal', 'magicspoon peanut butter', 'magic spoon pb'],
 'cereal', 'Magic Spoon', 1, '170 cal, 14g protein, 10g carbs (4g net), 9g fat per 36g serving. 0g sugar, grain free, gluten free.', TRUE),

-- Magic Spoon Cinnamon Roll: 140 cal, 12g P, 15g C, 7g F, 1g fiber, 0g sugar / 37g serving
('magicspoon_cinnamon', 'Magic Spoon Cinnamon Roll Cereal', 378, 32.4, 40.5, 18.9,
 2.7, 0.0, 37, NULL,
 'manufacturer', ARRAY['magic spoon cinnamon', 'magic spoon cinnamon roll', 'magic spoon cinnamon cereal', 'magicspoon cinnamon', 'magic spoon cinnamon roll cereal'],
 'cereal', 'Magic Spoon', 1, '140 cal, 12g protein, 15g carbs (4g net), 7g fat per 37g serving. 0g sugar, grain free, gluten free.', TRUE),

-- Magic Spoon Frosted: 140 cal, 13g P, 14g C, 7g F, 1g fiber, 0g sugar / 37g serving
('magicspoon_frosted', 'Magic Spoon Frosted Cereal', 378, 35.1, 37.8, 18.9,
 2.7, 0.0, 37, NULL,
 'manufacturer', ARRAY['magic spoon frosted', 'magic spoon frosted cereal', 'magic spoon frosted flakes', 'magicspoon frosted', 'magic spoon frosted flavor'],
 'cereal', 'Magic Spoon', 1, '140 cal, 13g protein, 14g carbs (4g net), 7g fat per 37g serving. 0g sugar, grain free, gluten free.', TRUE),

-- Magic Spoon Maple Waffle: 150 cal, 12g P, 14g C, 8g F, 1g fiber, 0g sugar / 37g serving
('magicspoon_maple_waffle', 'Magic Spoon Maple Waffle Cereal', 405, 32.4, 37.8, 21.6,
 2.7, 0.0, 37, NULL,
 'manufacturer', ARRAY['magic spoon maple waffle', 'magic spoon maple waffle cereal', 'magic spoon waffle cereal', 'magicspoon maple waffle', 'magic spoon maple'],
 'cereal', 'Magic Spoon', 1, '150 cal, 12g protein, 14g carbs (4g net), 8g fat per 37g serving. 0g sugar, grain free, gluten free.', TRUE),

-- ══════════════════════════════════════════
-- MAGIC SPOON — PROTEIN BARS (TREATS)
-- ══════════════════════════════════════════

-- Magic Spoon Treats Chocolate PB: 130 cal, 12g P, 17g C, 6g F, 7g fiber, 1g sugar / 40g bar (1.4oz)
('magicspoon_bar_chocolate_pb', 'Magic Spoon Treats Chocolate Peanut Butter', 325, 30.0, 42.5, 15.0,
 17.5, 2.5, NULL, 40,
 'manufacturer', ARRAY['magic spoon treats chocolate peanut butter', 'magic spoon chocolate pb bar', 'magic spoon cereal bar chocolate', 'magicspoon bar chocolate pb', 'magic spoon treats chocolatey pb'],
 'protein_bar', 'Magic Spoon', 1, '130 cal, 12g protein, 17g carbs (2g net), 6g fat per 40g bar. 7g fiber, 1g sugar, gluten free.', TRUE),

-- Magic Spoon Treats Cookies & Cream: 130 cal, 10g P, 17g C, 7g F, 7g fiber, 1g sugar / 40g bar (1.4oz)
('magicspoon_bar_cookies_cream', 'Magic Spoon Treats Cookies & Cream', 325, 25.0, 42.5, 17.5,
 17.5, 2.5, NULL, 40,
 'manufacturer', ARRAY['magic spoon treats cookies cream', 'magic spoon cookies and cream bar', 'magic spoon cereal bar cookies', 'magicspoon bar cookies cream', 'magic spoon treats cookies & cream'],
 'protein_bar', 'Magic Spoon', 1, '130 cal, 10g protein, 17g carbs (2g net), 7g fat per 40g bar. 7g fiber, 1g sugar, gluten free.', TRUE),

-- ══════════════════════════════════════════
-- MUSCLEEGG — EGG WHITES
-- ══════════════════════════════════════════

-- MuscleEgg Plain Liquid Egg Whites: 110 cal, 26g P, 2g C, 0g F / 234g (1 cup). Per 46g: ~21.6 cal
('muscleegg_plain', 'MuscleEgg Liquid Egg Whites (Plain)', 47, 11.1, 0.9, 0.0,
 0.0, 0.0, 46, NULL,
 'manufacturer', ARRAY['muscleegg plain', 'muscleegg liquid egg whites', 'muscle egg original', 'muscleegg egg whites plain', 'muscle egg plain egg whites'],
 'egg_whites', 'MuscleEgg', 1, '22 cal, 5.1g protein, 0.4g carbs, 0g fat per 46g serving. 100% cage-free pasteurized egg whites.', TRUE),

-- MuscleEgg Cake Batter Liquid Egg Whites: 120 cal, 26g P, 6g C, 0g F / 234g
('muscleegg_cake_batter', 'MuscleEgg Liquid Egg Whites (Cake Batter)', 51, 11.1, 2.6, 0.0,
 0.0, 2.1, 46, NULL,
 'manufacturer', ARRAY['muscleegg cake batter', 'muscleegg cake batter egg whites', 'muscle egg cake batter', 'muscleegg flavored egg whites cake batter', 'muscle egg cake batter flavor'],
 'egg_whites', 'MuscleEgg', 1, '24 cal, 5.1g protein, 1.2g carbs, 0g fat per 46g serving. Cage-free egg whites, cake batter flavor.', TRUE),

-- MuscleEgg Chocolate Liquid Egg Whites: 120 cal, 26g P, 5g C, 0g F / 234g
('muscleegg_chocolate', 'MuscleEgg Liquid Egg Whites (Chocolate)', 51, 11.1, 2.1, 0.0,
 0.0, 1.7, 46, NULL,
 'manufacturer', ARRAY['muscleegg chocolate', 'muscleegg chocolate egg whites', 'muscle egg chocolate', 'muscleegg flavored egg whites chocolate', 'muscle egg chocolate flavor'],
 'egg_whites', 'MuscleEgg', 1, '24 cal, 5.1g protein, 1.0g carbs, 0g fat per 46g serving. Cage-free egg whites, chocolate flavor.', TRUE),

-- ══════════════════════════════════════════
-- REAL GOOD FOODS — FROZEN MEALS
-- ══════════════════════════════════════════

-- Real Good Foods Chicken Enchiladas: 190 cal, 20g P, 4g C, 9g F, 2g fiber, 2g sugar / 133g (2 enchiladas)
('realgood_enchiladas', 'Real Good Foods Chicken Enchiladas', 143, 15.0, 3.0, 6.8,
 1.5, 1.5, 133, NULL,
 'manufacturer', ARRAY['real good foods enchiladas', 'real good chicken enchiladas', 'realgood enchiladas', 'real good foods keto enchiladas', 'realgood foods chicken enchiladas'],
 'frozen_meals', 'Real Good Foods', 1, '190 cal, 20g protein, 4g carbs, 9g fat per 133g (2 enchiladas). Low carb, grain free, gluten free.', TRUE),

-- Real Good Foods Stuffed Chicken Breast: 280 cal, 30g P, 1g C, 16g F / 142g piece
('realgood_stuffed_chicken', 'Real Good Foods Stuffed Chicken Breast', 197, 21.1, 0.7, 11.3,
 0.0, 0.0, NULL, 142,
 'manufacturer', ARRAY['real good foods stuffed chicken', 'real good stuffed chicken breast', 'realgood stuffed chicken', 'real good foods chicken broccoli cheddar', 'realgood foods stuffed chicken breast'],
 'frozen_meals', 'Real Good Foods', 1, '280 cal, 30g protein, 1g carbs, 16g fat per 142g piece. Broccoli & cheddar stuffed. Grain free, gluten free.', TRUE),

-- Real Good Foods Chicken Crust Pizza: 250 cal, 24g P, 4g C, 15g F / 124g (half pizza)
('realgood_chicken_crust_pizza', 'Real Good Foods Chicken Crust Pizza (Pepperoni)', 202, 19.4, 3.2, 12.1,
 0.0, 1.6, 124, NULL,
 'manufacturer', ARRAY['real good foods pizza', 'real good chicken crust pizza', 'realgood pizza', 'real good foods pepperoni pizza', 'realgood chicken crust pepperoni pizza'],
 'frozen_meals', 'Real Good Foods', 1, '250 cal, 24g protein, 4g carbs, 15g fat per 124g serving (1/2 pizza). Chicken breast & parmesan crust.', TRUE),

-- ══════════════════════════════════════════
-- LEGENDARY FOODS — PROTEIN PASTRIES
-- ══════════════════════════════════════════

-- Legendary Foods Protein Pastry Strawberry: 180 cal, 20g P, 22g C, 8g F, 9g fiber, <1g sugar / 61g pastry
('legendary_strawberry', 'Legendary Foods Protein Pastry (Strawberry)', 295, 32.8, 36.1, 13.1,
 14.8, 1.6, NULL, 61,
 'manufacturer', ARRAY['legendary foods strawberry pastry', 'legendary protein pastry strawberry', 'legendary foods strawberry', 'legendary pastry strawberry', 'legendary tasty pastry strawberry'],
 'protein_bar', 'Legendary Foods', 1, '180 cal, 20g protein, 22g carbs (5g net), 8g fat, 9g fiber per 61g pastry. Gluten free, keto friendly.', TRUE),

-- Legendary Foods Protein Pastry Brown Sugar Cinnamon: 180 cal, 20g P, 22g C, 8g F, 9g fiber, <1g sugar / 61g pastry
('legendary_brown_sugar', 'Legendary Foods Protein Pastry (Brown Sugar Cinnamon)', 295, 32.8, 36.1, 13.1,
 14.8, 1.6, NULL, 61,
 'manufacturer', ARRAY['legendary foods brown sugar pastry', 'legendary protein pastry brown sugar', 'legendary foods brown sugar cinnamon', 'legendary pastry brown sugar cinnamon', 'legendary tasty pastry cinnamon'],
 'protein_bar', 'Legendary Foods', 1, '180 cal, 20g protein, 22g carbs (5g net), 8g fat, 9g fiber per 61g pastry. Gluten free, keto friendly.', TRUE),

-- Legendary Foods Protein Pastry S'mores: 180 cal, 20g P, 22g C, 8g F, 9g fiber, <1g sugar / 61g pastry
('legendary_smores', 'Legendary Foods Protein Pastry (S''mores)', 295, 32.8, 36.1, 13.1,
 14.8, 1.6, NULL, 61,
 'manufacturer', ARRAY['legendary foods smores pastry', 'legendary protein pastry smores', 'legendary foods s mores', 'legendary pastry smores', 'legendary tasty pastry s mores'],
 'protein_bar', 'Legendary Foods', 1, '180 cal, 20g protein, 22g carbs (5g net), 8g fat, 9g fiber per 61g pastry. Gluten free, keto friendly.', TRUE)

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
