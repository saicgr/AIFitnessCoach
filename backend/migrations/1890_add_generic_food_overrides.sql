-- Migration 1890: Add 32 generic (region=NULL) food entries to food_nutrition_overrides
-- These are common foods that were missing generic entries, causing wrong fuzzy matches.
-- Uses ON CONFLICT to upsert: inserts new entries, updates existing ones with corrected values.

-- ============================================================
-- PROTEINS
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 1. Rotisserie Chicken (Meat Only)
('rotisserie_chicken', 'Rotisserie Chicken (Meat Only)', 164, 26.8, 0.0, 6.4, 0.0,
 ARRAY['rotisserie chicken', 'roasted chicken', 'pulled chicken'],
 NULL, TRUE, 'usda', 'protein'),

-- 2. Filet Mignon (Cooked)
('filet_mignon', 'Filet Mignon (Cooked)', 218, 27.6, 0.0, 11.1, 0.0,
 ARRAY['filet mignon', 'beef tenderloin', 'tenderloin steak', 'filet'],
 NULL, TRUE, 'usda', 'protein'),

-- 3. Tuna (Canned in Water)
('tuna_canned', 'Tuna (Canned in Water)', 90, 19.0, 0.1, 0.9, 0.0,
 ARRAY['tuna', 'canned tuna', 'tuna in water', 'light tuna', 'tuna fish'],
 NULL, TRUE, 'usda', 'protein'),

-- 4. Cod (Baked)
('cod', 'Cod (Baked)', 126, 19.0, 0.0, 5.1, 0.0,
 ARRAY['cod', 'baked cod', 'grilled cod', 'cod fish', 'cod fillet'],
 NULL, TRUE, 'usda', 'protein'),

-- 5. Pork Sausage (Cooked)
('pork_sausage', 'Pork Sausage (Cooked)', 326, 18.5, 1.4, 27.2, 0.0,
 ARRAY['sausage', 'pork sausage', 'breakfast sausage', 'sausage links', 'sausage patty'],
 NULL, TRUE, 'usda', 'protein'),

-- 6. Ham (Sliced, Deli)
('ham_deli', 'Ham (Sliced, Deli)', 100, 16.7, 0.3, 3.7, 0.0,
 ARRAY['ham', 'deli ham', 'sliced ham', 'lunch meat ham', 'honey ham'],
 NULL, TRUE, 'usda', 'protein'),

-- 7. Deli Turkey (Sliced)
('deli_turkey', 'Deli Turkey (Sliced)', 107, 14.8, 2.2, 3.8, 0.0,
 ARRAY['deli meat', 'turkey deli', 'sliced turkey', 'lunch meat turkey', 'deli turkey'],
 NULL, TRUE, 'usda', 'protein'),

-- 30. Beef Burger Patty (80/20)
('beef_burger_patty', 'Beef Burger Patty (80/20)', 273, 25.4, 0.0, 18.2, 0.0,
 ARRAY['burger patty', 'beef patty', 'hamburger patty', 'ground beef patty'],
 NULL, TRUE, 'usda', 'protein')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- GRAINS
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 8. Ramen Noodles (Cooked)
('ramen_noodles', 'Ramen Noodles (Cooked)', 137, 4.5, 25.0, 2.1, 1.2,
 ARRAY['ramen noodles', 'ramen', 'cooked noodles', 'instant noodles'],
 NULL, TRUE, 'usda', 'grain'),

-- 9. Flour Tortilla
('flour_tortilla', 'Flour Tortilla', 306, 8.2, 49.4, 8.0, 3.5,
 ARRAY['tortilla', 'flour tortilla', 'soft tortilla', 'burrito tortilla'],
 NULL, TRUE, 'usda', 'grain'),

-- 10. Sub Roll
('sub_roll', 'Sub Roll', 279, 9.8, 50.1, 3.9, 1.8,
 ARRAY['sub roll', 'hoagie roll', 'submarine roll', 'hero roll', 'sub bread'],
 NULL, TRUE, 'usda', 'grain'),

-- 11. Hamburger Bun
('hamburger_bun', 'Hamburger Bun', 268, 9.4, 49.2, 3.6, 2.3,
 ARRAY['hamburger bun', 'burger bun', 'sesame bun'],
 NULL, TRUE, 'usda', 'grain'),

-- 12. Hot Dog Bun
('hot_dog_bun', 'Hot Dog Bun', 267, 9.4, 49.2, 3.6, 2.3,
 ARRAY['hot dog bun', 'hot dog roll', 'frankfurter bun', 'hotdog bun'],
 NULL, TRUE, 'usda', 'grain')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- VEGETABLES
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 13. Bell Pepper (Raw)
('bell_pepper', 'Bell Pepper (Raw)', 26, 1.0, 6.0, 0.3, 2.1,
 ARRAY['bell pepper', 'sweet pepper', 'capsicum', 'red pepper', 'green pepper', 'yellow pepper'],
 NULL, TRUE, 'usda', 'vegetable'),

-- 14. Fajita Vegetables (Grilled)
('fajita_vegetables', 'Fajita Vegetables (Grilled)', 59, 1.0, 8.1, 2.7, 1.5,
 ARRAY['fajita veggies', 'fajita vegetables', 'grilled peppers and onions', 'fajita mix'],
 NULL, TRUE, 'usda', 'vegetable')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- DAIRY
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 15. Yogurt (Plain, Low-Fat)
('yogurt_plain', 'Yogurt (Plain, Low-Fat)', 63, 5.2, 7.0, 1.5, 0.0,
 ARRAY['yogurt', 'plain yogurt', 'low fat yogurt', 'natural yogurt'],
 NULL, TRUE, 'usda', 'dairy')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- CONDIMENTS / SAUCES
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 16. Corn Salsa
('corn_salsa', 'Corn Salsa', 50, 1.0, 11.0, 0.3, 1.5,
 ARRAY['corn salsa', 'chipotle corn salsa', 'fresh corn salsa'],
 NULL, TRUE, 'usda', 'condiment'),

-- 17. Yellow Mustard
('yellow_mustard', 'Yellow Mustard', 60, 3.8, 5.8, 3.3, 4.0,
 ARRAY['mustard', 'yellow mustard', 'prepared mustard'],
 NULL, TRUE, 'usda', 'condiment'),

-- 18. Ranch Dressing
('ranch_dressing', 'Ranch Dressing', 433, 1.3, 5.9, 44.5, 0.0,
 ARRAY['ranch dressing', 'ranch', 'ranch sauce', 'buttermilk ranch'],
 NULL, TRUE, 'usda', 'condiment'),

-- 19. BBQ Sauce
('bbq_sauce', 'BBQ Sauce', 170, 0.8, 40.8, 0.6, 0.9,
 ARRAY['bbq sauce', 'barbecue sauce', 'barbeque sauce'],
 NULL, TRUE, 'usda', 'condiment'),

-- 20. Soy Sauce
('soy_sauce', 'Soy Sauce', 53, 8.1, 4.9, 0.6, 0.8,
 ARRAY['soy sauce', 'shoyu', 'soya sauce'],
 NULL, TRUE, 'usda', 'condiment'),

-- 21. Teriyaki Sauce
('teriyaki_sauce', 'Teriyaki Sauce', 88, 5.9, 15.6, 0.0, 0.1,
 ARRAY['teriyaki sauce', 'teriyaki', 'teriyaki glaze'],
 NULL, TRUE, 'usda', 'condiment')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- FRUITS
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 22. Mixed Berries
('mixed_berries', 'Mixed Berries', 52, 0.8, 12.5, 0.3, 4.1,
 ARRAY['mixed berries', 'berry mix', 'frozen berries', 'berry blend'],
 NULL, TRUE, 'usda', 'fruit')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- SNACKS
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 23. Trail Mix
('trail_mix', 'Trail Mix', 454, 10.9, 51.1, 26.8, 6.4,
 ARRAY['trail mix', 'nut mix', 'hiking mix'],
 NULL, TRUE, 'usda', 'snack'),

-- 24. Granola Bar
('granola_bar', 'Granola Bar', 471, 10.1, 64.4, 19.8, 5.3,
 ARRAY['granola bar', 'oat bar', 'cereal bar', 'chewy bar'],
 NULL, TRUE, 'usda', 'snack'),

-- 25. Protein Bar
('protein_bar', 'Protein Bar', 332, 24.0, 50.0, 10.5, 15.4,
 ARRAY['protein bar', 'whey bar', 'nutrition bar', 'energy bar'],
 NULL, TRUE, 'usda', 'snack'),

-- 26. Tortilla Chips
('tortilla_chips', 'Tortilla Chips', 467, 7.0, 68.0, 20.7, 5.3,
 ARRAY['tortilla chips', 'corn chips', 'nacho chips'],
 NULL, TRUE, 'usda', 'snack'),

-- 27. Popcorn (Air-Popped)
('popcorn', 'Popcorn (Air-Popped)', 388, 13.0, 77.8, 4.5, 14.5,
 ARRAY['popcorn', 'air popped popcorn', 'plain popcorn'],
 NULL, TRUE, 'usda', 'snack'),

-- 28. Crackers (Saltine)
('crackers', 'Crackers (Saltine)', 416, 9.5, 74.0, 8.6, 2.8,
 ARRAY['crackers', 'saltines', 'soda crackers'],
 NULL, TRUE, 'usda', 'snack'),

-- 29. Chocolate Chip Cookie
('chocolate_chip_cookie', 'Chocolate Chip Cookie', 500, 5.2, 65.4, 24.7, 2.0,
 ARRAY['cookie', 'chocolate chip cookie', 'cookies'],
 NULL, TRUE, 'usda', 'snack')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();

-- ============================================================
-- BEVERAGES
-- ============================================================

INSERT INTO food_nutrition_overrides (
    food_name_normalized, display_name, calories_per_100g, protein_per_100g,
    carbs_per_100g, fat_per_100g, fiber_per_100g, variant_names,
    region, is_active, source, food_category
) VALUES
-- 31. Fruit Smoothie
('fruit_smoothie', 'Fruit Smoothie', 67, 2.3, 12.0, 1.1, 1.1,
 ARRAY['smoothie', 'fruit smoothie', 'blended fruit'],
 NULL, TRUE, 'usda', 'beverage'),

-- 32. Coffee (Black, Brewed)
('coffee_black', 'Coffee (Black, Brewed)', 1, 0.1, 0.0, 0.0, 0.0,
 ARRAY['coffee', 'black coffee', 'brewed coffee', 'drip coffee', 'plain coffee'],
 NULL, TRUE, 'usda', 'beverage')

ON CONFLICT (food_name_normalized) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    calories_per_100g = EXCLUDED.calories_per_100g,
    protein_per_100g = EXCLUDED.protein_per_100g,
    carbs_per_100g = EXCLUDED.carbs_per_100g,
    fat_per_100g = EXCLUDED.fat_per_100g,
    fiber_per_100g = EXCLUDED.fiber_per_100g,
    variant_names = EXCLUDED.variant_names,
    region = EXCLUDED.region,
    is_active = EXCLUDED.is_active,
    source = EXCLUDED.source,
    food_category = EXCLUDED.food_category,
    updated_at = NOW();
