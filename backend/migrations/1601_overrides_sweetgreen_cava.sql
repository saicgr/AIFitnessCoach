-- 1601_overrides_sweetgreen_cava.sql
-- Sweetgreen (~230 locations) — bowls, salads, protein plates, dressings, sides.
-- CAVA (~350+ locations) — Mediterranean build-your-own components: bases, proteins,
-- dips/spreads, toppings, dressings.
-- Sources: sweetgreenmenus.com, fastfoodnutrition.org, galiotos.com (CAVA official),
-- FatSecret, MyFoodDiary.
-- All values per 100g.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SWEETGREEN — BOWLS
-- ══════════════════════════════════════════

-- Sweetgreen Crispy Rice Bowl: 680 cal per bowl (457g)
('sweetgreen_crispy_rice_bowl', 'Sweetgreen Crispy Rice Bowl', 148.8, 7.2, 13.3, 6.8,
 1.8, 2.0, 457, NULL,
 'research', ARRAY['sweetgreen crispy rice bowl', 'crispy rice bowl sweetgreen', 'sweetgreen crispy rice', 'sg crispy rice bowl'],
 'bowl', 'Sweetgreen', 1, '680 cal per bowl (457g). Crispy rice with warm portobello mix, raw veggies, and spicy cashew dressing.', TRUE),

-- Sweetgreen Shroomami: 665 cal per bowl (457g)
('sweetgreen_shroomami', 'Sweetgreen Shroomami', 145.5, 4.4, 11.2, 9.8,
 2.4, 1.5, 457, NULL,
 'research', ARRAY['sweetgreen shroomami', 'shroomami bowl sweetgreen', 'sweetgreen mushroom bowl', 'sg shroomami'],
 'bowl', 'Sweetgreen', 1, '665 cal per bowl (457g). Warm portobello mushroom mix, wild rice, tofu, cucumber, cabbage, and miso sesame ginger dressing.', TRUE),

-- Sweetgreen Chicken Pesto Parm: 545 cal per bowl (431g)
('sweetgreen_chicken_pesto_parm', 'Sweetgreen Chicken Pesto Parm', 126.5, 9.5, 8.8, 5.6,
 1.9, 0.7, 431, NULL,
 'research', ARRAY['sweetgreen chicken pesto parm', 'chicken pesto parm sweetgreen', 'sweetgreen pesto chicken', 'sg chicken pesto parm'],
 'bowl', 'Sweetgreen', 1, '545 cal per bowl (431g). Blackened chicken, roasted sweet potatoes, shaved parmesan, tomatoes, and pesto vinaigrette.', TRUE),

-- Sweetgreen Fish Taco Bowl: 835 cal per bowl (490g)
('sweetgreen_fish_taco_bowl', 'Sweetgreen Fish Taco Bowl', 170.4, 7.3, 12.7, 10.0,
 3.3, 3.1, 490, NULL,
 'research', ARRAY['sweetgreen fish taco bowl', 'fish taco bowl sweetgreen', 'sweetgreen fish taco', 'sg fish taco bowl'],
 'bowl', 'Sweetgreen', 1, '835 cal per bowl (490g). Steelhead, cilantro lime brown rice, tortilla chips, avocado, and lime cilantro jalapeno vinaigrette.', TRUE),

-- Sweetgreen Chicken Avocado Ranch: 755 cal per bowl (548g)
('sweetgreen_chicken_avocado_ranch', 'Sweetgreen Chicken Avocado Ranch', 137.8, 5.1, 10.8, 7.8,
 2.6, 1.5, 548, NULL,
 'research', ARRAY['sweetgreen chicken avocado ranch', 'chicken avocado ranch sweetgreen', 'sweetgreen avocado ranch bowl', 'sg chicken avocado ranch'],
 'bowl', 'Sweetgreen', 1, '755 cal per bowl (548g). Blackened chicken, avocado, warm quinoa, tomatoes, and green goddess ranch dressing.', TRUE),

-- Sweetgreen Chicken Caprese: 655 cal per bowl (481g)
('sweetgreen_chicken_caprese', 'Sweetgreen Chicken Caprese', 136.2, 8.3, 6.9, 8.9,
 1.2, 1.7, 481, NULL,
 'research', ARRAY['sweetgreen chicken caprese', 'chicken caprese sweetgreen', 'sweetgreen caprese bowl', 'sg chicken caprese'],
 'bowl', 'Sweetgreen', 1, '655 cal per bowl (481g). Roasted chicken, mozzarella, tomatoes, basil, and balsamic vinaigrette.', TRUE),

-- Sweetgreen Elote Bowl: 560 cal per bowl (420g)
('sweetgreen_elote_bowl', 'Sweetgreen Elote Bowl', 133.3, 4.3, 12.9, 7.9,
 2.1, 2.1, 420, NULL,
 'research', ARRAY['sweetgreen elote bowl', 'elote bowl sweetgreen', 'sweetgreen elote', 'sg elote bowl'],
 'bowl', 'Sweetgreen', 1, '560 cal per bowl (420g). Roasted corn, warm quinoa, tortilla chips, cotija cheese, and lime cilantro jalapeno vinaigrette.', TRUE),

-- ══════════════════════════════════════════
-- SWEETGREEN — SALADS
-- ══════════════════════════════════════════

-- Sweetgreen Buffalo Chicken Salad: 595 cal per salad (539g)
('sweetgreen_buffalo_chicken', 'Sweetgreen Buffalo Chicken Salad', 110.4, 6.7, 5.9, 6.5,
 1.7, 2.0, 539, NULL,
 'research', ARRAY['sweetgreen buffalo chicken', 'buffalo chicken salad sweetgreen', 'sweetgreen buffalo chicken salad', 'sg buffalo chicken'],
 'salad', 'Sweetgreen', 1, '595 cal per salad (539g). Blackened chicken, blue cheese, celery, carrots, ranch, and hot sauce.', TRUE),

-- Sweetgreen Guacamole Greens: 575 cal per salad (574g)
('sweetgreen_guacamole_greens', 'Sweetgreen Guacamole Greens', 100.2, 5.1, 6.1, 5.9,
 2.4, 1.2, 574, NULL,
 'research', ARRAY['sweetgreen guacamole greens', 'guacamole greens sweetgreen', 'sweetgreen guac greens', 'sg guacamole greens'],
 'salad', 'Sweetgreen', 1, '575 cal per salad (574g). Fresh guacamole, chicken, tortilla chips, tomatoes, and lime cilantro jalapeno vinaigrette.', TRUE),

-- Sweetgreen Garden Cobb: 740 cal per salad (517g)
('sweetgreen_garden_cobb', 'Sweetgreen Garden Cobb', 143.1, 4.3, 6.6, 10.8,
 3.1, 1.9, 517, NULL,
 'research', ARRAY['sweetgreen garden cobb', 'garden cobb sweetgreen', 'sweetgreen cobb salad', 'sg garden cobb'],
 'salad', 'Sweetgreen', 1, '740 cal per salad (517g). Hard-boiled egg, avocado, bacon, blue cheese, tomatoes, and green goddess ranch.', TRUE),

-- Sweetgreen Super Green Goddess: 465 cal per salad (335g)
('sweetgreen_super_green_goddess', 'Sweetgreen Super Green Goddess', 138.8, 3.6, 10.7, 9.3,
 3.9, 2.4, 335, NULL,
 'research', ARRAY['sweetgreen super green goddess', 'super green goddess sweetgreen', 'sweetgreen green goddess salad', 'sg super green goddess'],
 'salad', 'Sweetgreen', 1, '465 cal per salad (335g). Avocado, cucumber, raw beets, sprouts, sunflower seeds, and green goddess ranch.', TRUE),

-- Sweetgreen BBQ Chicken Salad: 585 cal per salad (550g)
('sweetgreen_bbq_chicken', 'Sweetgreen BBQ Chicken Salad', 106.4, 4.9, 7.3, 5.5,
 1.6, 4.4, 550, NULL,
 'research', ARRAY['sweetgreen bbq chicken', 'bbq chicken salad sweetgreen', 'sweetgreen bbq chicken salad', 'sg bbq chicken'],
 'salad', 'Sweetgreen', 1, '585 cal per salad (550g). Blackened chicken, roasted sweet potatoes, pickled onions, corn, and BBQ sauce.', TRUE),

-- Sweetgreen Hummus Crunch: 405 cal per salad (514g)
('sweetgreen_hummus_crunch', 'Sweetgreen Hummus Crunch', 78.8, 2.7, 8.2, 3.5,
 1.9, 1.9, 514, NULL,
 'research', ARRAY['sweetgreen hummus crunch', 'hummus crunch sweetgreen', 'sweetgreen hummus crunch salad', 'sg hummus crunch'],
 'salad', 'Sweetgreen', 1, '405 cal per salad (514g). Hummus, falafel, cucumbers, tomatoes, pickled onions, za''atar breadcrumbs, and lemon squeeze.', TRUE),

-- ══════════════════════════════════════════
-- SWEETGREEN — PROTEIN PLATES
-- ══════════════════════════════════════════

-- Sweetgreen Caramelized Garlic Steak Plate: 770 cal per plate (484g)
('sweetgreen_caramelized_garlic_steak', 'Sweetgreen Caramelized Garlic Steak Plate', 159.1, 7.0, 16.9, 6.6,
 1.7, 0.8, 484, NULL,
 'research', ARRAY['sweetgreen caramelized garlic steak', 'caramelized garlic steak sweetgreen', 'sweetgreen steak plate', 'sg garlic steak plate'],
 'entree', 'Sweetgreen', 1, '770 cal per plate (484g). Caramelized garlic steak with warm grains, roasted vegetables, and dressing.', TRUE),

-- Sweetgreen Hot Honey Chicken Plate: 920 cal per plate (575g)
('sweetgreen_hot_honey_chicken', 'Sweetgreen Hot Honey Chicken Plate', 160.0, 9.0, 12.9, 7.5,
 1.6, 2.8, 575, NULL,
 'research', ARRAY['sweetgreen hot honey chicken', 'hot honey chicken sweetgreen', 'sweetgreen hot honey chicken plate', 'sg hot honey chicken'],
 'entree', 'Sweetgreen', 1, '920 cal per plate (575g). Hot honey chicken with warm grains, roasted sweet potatoes, and green goddess ranch.', TRUE),

-- Sweetgreen Miso Glazed Salmon Plate: 930 cal per plate (544g)
('sweetgreen_miso_glazed_salmon', 'Sweetgreen Miso Glazed Salmon Plate', 171.0, 6.4, 16.2, 8.8,
 2.2, 3.5, 544, NULL,
 'research', ARRAY['sweetgreen miso glazed salmon', 'miso glazed salmon sweetgreen', 'sweetgreen salmon plate', 'sg miso salmon plate'],
 'entree', 'Sweetgreen', 1, '930 cal per plate (544g). Miso glazed salmon with warm grains, roasted vegetables, and sesame ginger dressing.', TRUE),

-- ══════════════════════════════════════════
-- SWEETGREEN — DRESSINGS
-- ══════════════════════════════════════════

-- Sweetgreen Caesar Dressing: 100 cal per serving (30g)
('sweetgreen_caesar_dressing', 'Sweetgreen Caesar Dressing', 333.3, 3.3, 3.3, 56.7,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen caesar dressing', 'caesar dressing sweetgreen', 'sweetgreen caesar', 'sg caesar dressing'],
 'dressing', 'Sweetgreen', 1, '100 cal per serving (30g). Creamy Caesar dressing.', TRUE),

-- Sweetgreen Green Goddess Ranch: 180 cal per serving (30g)
('sweetgreen_green_goddess_ranch', 'Sweetgreen Green Goddess Ranch', 600.0, 3.3, 3.3, 63.3,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen green goddess ranch', 'green goddess ranch sweetgreen', 'sweetgreen ranch dressing', 'sg green goddess ranch'],
 'dressing', 'Sweetgreen', 1, '180 cal per serving (30g). Herby green goddess ranch dressing.', TRUE),

-- Sweetgreen Balsamic Vinaigrette: 150 cal per serving (30g)
('sweetgreen_balsamic_vinaigrette', 'Sweetgreen Balsamic Vinaigrette', 500.0, 0.0, 16.7, 73.3,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen balsamic vinaigrette', 'balsamic vinaigrette sweetgreen', 'sweetgreen balsamic', 'sg balsamic vinaigrette'],
 'dressing', 'Sweetgreen', 1, '150 cal per serving (30g). Classic balsamic vinaigrette.', TRUE),

-- Sweetgreen Lime Cilantro Jalapeno Vinaigrette: 140 cal per serving (30g)
('sweetgreen_lime_cilantro_jalapeno', 'Sweetgreen Lime Cilantro Jalapeno Vinaigrette', 466.7, 0.0, 13.3, 46.7,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen lime cilantro jalapeno', 'lime cilantro jalapeno sweetgreen', 'sweetgreen lime cilantro dressing', 'sg lime cilantro jalapeno'],
 'dressing', 'Sweetgreen', 1, '140 cal per serving (30g). Spicy lime cilantro jalapeno vinaigrette.', TRUE),

-- Sweetgreen Spicy Cashew Dressing: 120 cal per serving (30g)
('sweetgreen_spicy_cashew', 'Sweetgreen Spicy Cashew Dressing', 400.0, 10.0, 13.3, 50.0,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen spicy cashew', 'spicy cashew dressing sweetgreen', 'sweetgreen cashew dressing', 'sg spicy cashew'],
 'dressing', 'Sweetgreen', 1, '120 cal per serving (30g). Spicy cashew-based dressing.', TRUE),

-- Sweetgreen Miso Sesame Ginger Dressing: 140 cal per serving (30g)
('sweetgreen_miso_sesame_ginger', 'Sweetgreen Miso Sesame Ginger Dressing', 466.7, 3.3, 6.7, 66.7,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen miso sesame ginger', 'miso sesame ginger sweetgreen', 'sweetgreen sesame ginger dressing', 'sg miso sesame ginger'],
 'dressing', 'Sweetgreen', 1, '140 cal per serving (30g). Miso sesame ginger dressing.', TRUE),

-- Sweetgreen Pesto Vinaigrette: 110 cal per serving (30g)
('sweetgreen_pesto_vinaigrette', 'Sweetgreen Pesto Vinaigrette', 366.7, 0.0, 0.0, 30.0,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen pesto vinaigrette', 'pesto vinaigrette sweetgreen', 'sweetgreen pesto dressing', 'sg pesto vinaigrette'],
 'dressing', 'Sweetgreen', 1, '110 cal per serving (30g). Basil pesto vinaigrette.', TRUE),

-- Sweetgreen Hot Sauce: 10 cal per serving (28g)
('sweetgreen_hot_sauce', 'Sweetgreen Hot Sauce', 35.7, 0.0, 7.1, 0.0,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['sweetgreen hot sauce', 'hot sauce sweetgreen', 'sweetgreen sriracha', 'sg hot sauce'],
 'dressing', 'Sweetgreen', 1, '10 cal per serving (28g). Sweetgreen hot sauce.', TRUE),

-- Sweetgreen Balsamic Vinegar: 15 cal per serving (15g)
('sweetgreen_balsamic_vinegar', 'Sweetgreen Balsamic Vinegar', 100.0, 0.0, 26.7, 0.0,
 0.0, 0.0, 15, NULL,
 'research', ARRAY['sweetgreen balsamic vinegar', 'balsamic vinegar sweetgreen', 'sweetgreen plain balsamic', 'sg balsamic vinegar'],
 'dressing', 'Sweetgreen', 1, '15 cal per serving (15g). Plain balsamic vinegar.', TRUE),

-- Sweetgreen Lemon Squeeze: 0 cal per serving (15g)
('sweetgreen_lemon_squeeze', 'Sweetgreen Lemon Squeeze', 0.0, 0.0, 6.7, 0.0,
 0.0, 0.0, 15, NULL,
 'research', ARRAY['sweetgreen lemon squeeze', 'lemon squeeze sweetgreen', 'sweetgreen lemon', 'sg lemon squeeze'],
 'dressing', 'Sweetgreen', 1, '0 cal per serving (15g). Fresh lemon juice squeeze.', TRUE),

-- Sweetgreen Lime Squeeze: 5 cal per serving (15g)
('sweetgreen_lime_squeeze', 'Sweetgreen Lime Squeeze', 33.3, 0.0, 6.7, 0.0,
 0.0, 0.0, 15, NULL,
 'research', ARRAY['sweetgreen lime squeeze', 'lime squeeze sweetgreen', 'sweetgreen lime', 'sg lime squeeze'],
 'dressing', 'Sweetgreen', 1, '5 cal per serving (15g). Fresh lime juice squeeze.', TRUE),

-- Sweetgreen Extra Virgin Olive Oil: 120 cal per serving (15g)
('sweetgreen_extra_virgin_olive_oil', 'Sweetgreen Extra Virgin Olive Oil', 800.0, 0.0, 0.0, 93.3,
 0.0, 0.0, 15, NULL,
 'research', ARRAY['sweetgreen olive oil', 'olive oil sweetgreen', 'sweetgreen evoo', 'sg extra virgin olive oil'],
 'dressing', 'Sweetgreen', 1, '120 cal per serving (15g). Extra virgin olive oil.', TRUE),

-- Sweetgreen Carrot Chili Vinaigrette: 150 cal per serving (30g)
('sweetgreen_carrot_chili_vinaigrette', 'Sweetgreen Carrot Chili Vinaigrette', 500.0, 0.0, 20.0, 46.7,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen carrot chili vinaigrette', 'carrot chili vinaigrette sweetgreen', 'sweetgreen carrot chili', 'sg carrot chili vinaigrette'],
 'dressing', 'Sweetgreen', 1, '150 cal per serving (30g). Carrot chili vinaigrette dressing.', TRUE),

-- Sweetgreen Cucumber Tahini Yogurt Dressing: 100 cal per serving (30g)
('sweetgreen_cucumber_tahini_yogurt', 'Sweetgreen Cucumber Tahini Yogurt Dressing', 333.3, 6.7, 13.3, 30.0,
 0.0, 0.0, 30, NULL,
 'research', ARRAY['sweetgreen cucumber tahini yogurt', 'cucumber tahini yogurt sweetgreen', 'sweetgreen tahini dressing', 'sg cucumber tahini yogurt'],
 'dressing', 'Sweetgreen', 1, '100 cal per serving (30g). Cucumber tahini yogurt dressing.', TRUE),

-- Sweetgreen Umami Seasoning: 0 cal per serving (5g)
('sweetgreen_umami_seasoning', 'Sweetgreen Umami Seasoning', 0.0, 0.0, 0.0, 0.0,
 0.0, 0.0, 5, NULL,
 'research', ARRAY['sweetgreen umami seasoning', 'umami seasoning sweetgreen', 'sweetgreen umami', 'sg umami seasoning'],
 'dressing', 'Sweetgreen', 1, '0 cal per serving (5g). Dry umami seasoning blend.', TRUE),

-- ══════════════════════════════════════════
-- SWEETGREEN — SIDES
-- ══════════════════════════════════════════

-- Sweetgreen Rosemary Focaccia + Hummus: 290 cal per serving (120g est.)
('sweetgreen_rosemary_focaccia_hummus', 'Sweetgreen Rosemary Focaccia + Hummus', 241.7, 8.3, 30.8, 9.2,
 0.0, 0.0, 120, NULL,
 'research', ARRAY['sweetgreen rosemary focaccia hummus', 'rosemary focaccia sweetgreen', 'sweetgreen focaccia and hummus', 'sg rosemary focaccia hummus'],
 'side', 'Sweetgreen', 1, '290 cal per serving (120g est.). Rosemary focaccia bread served with hummus.', TRUE),

-- ══════════════════════════════════════════
-- CAVA — BASES
-- ══════════════════════════════════════════

-- CAVA SuperGreens: 35 cal per serving (85g)
('cava_supergreens', 'CAVA SuperGreens', 41.2, 3.5, 7.1, 0.6,
 4.7, 2.4, 85, NULL,
 'research', ARRAY['cava supergreens', 'supergreens cava', 'cava super greens base', 'cava supergreens salad base'],
 'base', 'CAVA', 1, '35 cal per serving (85g). Nutrient-dense leafy green mix base.', TRUE),

-- CAVA SplendidGreens: 20 cal per serving (85g)
('cava_splendidgreens', 'CAVA SplendidGreens', 23.5, 1.2, 4.7, 0.0,
 3.5, 1.2, 85, NULL,
 'research', ARRAY['cava splendidgreens', 'splendidgreens cava', 'cava splendid greens base', 'cava splendid greens'],
 'base', 'CAVA', 1, '20 cal per serving (85g). Light leafy green mix base.', TRUE),

-- CAVA Arugula: 20 cal per serving (85g)
('cava_arugula', 'CAVA Arugula', 23.5, 2.4, 3.5, 0.6,
 1.2, 2.4, 85, NULL,
 'research', ARRAY['cava arugula', 'arugula base cava', 'cava arugula base', 'cava arugula greens'],
 'base', 'CAVA', 1, '20 cal per serving (85g). Peppery arugula greens base.', TRUE),

-- CAVA Baby Spinach: 20 cal per serving (85g)
('cava_baby_spinach', 'CAVA Baby Spinach', 23.5, 3.5, 3.5, 0.0,
 2.4, 0.0, 85, NULL,
 'research', ARRAY['cava baby spinach', 'baby spinach cava', 'cava spinach base', 'cava baby spinach greens'],
 'base', 'CAVA', 1, '20 cal per serving (85g). Fresh baby spinach base.', TRUE),

-- CAVA Romaine: 20 cal per serving (85g)
('cava_romaine', 'CAVA Romaine', 23.5, 1.2, 4.7, 0.0,
 3.5, 1.2, 85, NULL,
 'research', ARRAY['cava romaine', 'romaine cava', 'cava romaine lettuce base', 'cava romaine greens'],
 'base', 'CAVA', 1, '20 cal per serving (85g). Chopped romaine lettuce base.', TRUE),

-- CAVA Brown Rice: 310 cal per serving (200g)
('cava_brown_rice', 'CAVA Brown Rice', 155.0, 3.5, 24.0, 5.0,
 2.5, 1.0, 200, NULL,
 'research', ARRAY['cava brown rice', 'brown rice cava', 'cava rice base', 'cava brown rice bowl base'],
 'base', 'CAVA', 1, '310 cal per serving (200g). Seasoned brown rice base.', TRUE),

-- CAVA Saffron Basmati Rice: 290 cal per serving (200g)
('cava_saffron_basmati_rice', 'CAVA Saffron Basmati Rice', 145.0, 2.5, 27.0, 3.5,
 1.0, 0.5, 200, NULL,
 'research', ARRAY['cava saffron basmati rice', 'saffron basmati rice cava', 'cava basmati rice', 'cava saffron rice base'],
 'base', 'CAVA', 1, '290 cal per serving (200g). Saffron-seasoned basmati rice base.', TRUE),

-- CAVA Black Lentils: 270 cal per serving (170g)
('cava_black_lentils', 'CAVA Black Lentils', 158.8, 10.6, 21.8, 4.1,
 8.8, 1.8, 170, NULL,
 'research', ARRAY['cava black lentils', 'black lentils cava', 'cava lentils base', 'cava black lentil bowl base'],
 'base', 'CAVA', 1, '270 cal per serving (170g). Seasoned black lentils. High protein and fiber base.', TRUE),

-- CAVA Pita: 230 cal per pita (80g)
('cava_pita', 'CAVA Pita', 287.5, 10.0, 65.0, 10.0,
 2.5, 1.2, NULL, 80,
 'research', ARRAY['cava pita', 'pita bread cava', 'cava full pita', 'cava pita bread'],
 'base', 'CAVA', 1, '230 cal per pita (80g). Full-size warm pita bread.', TRUE),

-- CAVA Mini Pita: 110 cal per mini pita (40g)
('cava_mini_pita', 'CAVA Mini Pita', 275.0, 10.0, 62.5, 10.0,
 2.5, 1.2, NULL, 40,
 'research', ARRAY['cava mini pita', 'mini pita cava', 'cava small pita', 'cava mini pita bread'],
 'base', 'CAVA', 1, '110 cal per mini pita (40g). Half-size warm pita bread.', TRUE),

-- ══════════════════════════════════════════
-- CAVA — PROTEINS
-- ══════════════════════════════════════════

-- CAVA Grilled Chicken: 250 cal per serving (114g)
('cava_grilled_chicken', 'CAVA Grilled Chicken', 219.3, 24.6, 2.6, 11.4,
 0.9, 0.0, 114, NULL,
 'research', ARRAY['cava grilled chicken', 'grilled chicken cava', 'cava chicken protein', 'cava grilled chicken breast'],
 'protein', 'CAVA', 1, '250 cal per serving (114g, 4oz). Grilled and seasoned chicken breast.', TRUE),

-- CAVA Harissa Honey Chicken: 260 cal per serving (114g)
('cava_harissa_honey_chicken', 'CAVA Harissa Honey Chicken', 228.1, 22.8, 6.1, 12.3,
 1.8, 2.6, 114, NULL,
 'research', ARRAY['cava harissa honey chicken', 'harissa honey chicken cava', 'cava honey harissa chicken', 'cava spicy honey chicken'],
 'protein', 'CAVA', 1, '260 cal per serving (114g, 4oz). Chicken glazed with harissa and honey.', TRUE),

-- CAVA Chicken Shawarma: 100 cal per serving (85g)
('cava_chicken_shawarma', 'CAVA Chicken Shawarma', 117.6, 18.8, 1.2, 3.5,
 0.0, 0.0, 85, NULL,
 'research', ARRAY['cava chicken shawarma', 'chicken shawarma cava', 'cava shawarma chicken', 'cava shawarma protein'],
 'protein', 'CAVA', 1, '100 cal per serving (85g). Lean sliced chicken shawarma. Excellent protein-to-calorie ratio.', TRUE),

-- CAVA Grilled Steak: 170 cal per serving (114g)
('cava_grilled_steak', 'CAVA Grilled Steak', 149.1, 20.2, 0.9, 7.9,
 0.0, 0.0, 114, NULL,
 'research', ARRAY['cava grilled steak', 'grilled steak cava', 'cava steak protein', 'cava grilled beef steak'],
 'protein', 'CAVA', 1, '170 cal per serving (114g, 4oz). Grilled and seasoned steak.', TRUE),

-- CAVA Braised Lamb: 210 cal per serving (114g)
('cava_braised_lamb', 'CAVA Braised Lamb', 184.2, 21.1, 1.8, 10.5,
 0.9, 0.0, 114, NULL,
 'research', ARRAY['cava braised lamb', 'braised lamb cava', 'cava lamb protein', 'cava slow braised lamb'],
 'protein', 'CAVA', 1, '210 cal per serving (114g, 4oz). Slow-braised seasoned lamb.', TRUE),

-- CAVA Spicy Lamb Meatballs: 300 cal per serving (114g)
('cava_spicy_lamb_meatballs', 'CAVA Spicy Lamb Meatballs', 263.2, 21.1, 2.6, 18.4,
 0.9, 0.9, 114, NULL,
 'research', ARRAY['cava spicy lamb meatballs', 'spicy lamb meatballs cava', 'cava lamb meatballs', 'cava spicy meatballs lamb'],
 'protein', 'CAVA', 1, '300 cal per serving (114g, 4oz). Spicy seasoned lamb meatballs.', TRUE),

-- CAVA Grilled Meatballs: 190 cal per serving (114g)
('cava_grilled_meatballs', 'CAVA Grilled Meatballs', 166.7, 15.8, 1.8, 10.5,
 0.0, 0.0, 114, NULL,
 'research', ARRAY['cava grilled meatballs', 'grilled meatballs cava', 'cava beef meatballs', 'cava meatballs grilled'],
 'protein', 'CAVA', 1, '190 cal per serving (114g, 4oz). Grilled seasoned meatballs. Macros estimated from similar CAVA items.', TRUE),

-- CAVA Falafel: 350 cal per serving (170g)
('cava_falafel', 'CAVA Falafel', 205.9, 3.5, 14.1, 15.3,
 2.9, 1.8, 170, NULL,
 'research', ARRAY['cava falafel', 'falafel cava', 'cava falafel protein', 'cava crispy falafel'],
 'protein', 'CAVA', 1, '350 cal per serving (170g). Crispy fried falafel balls. Plant-based protein option.', TRUE),

-- CAVA Roasted Vegetables: 100 cal per serving (114g)
('cava_roasted_vegetables', 'CAVA Roasted Vegetables', 87.7, 2.6, 12.3, 3.9,
 4.4, 4.4, 114, NULL,
 'research', ARRAY['cava roasted vegetables', 'roasted vegetables cava', 'cava roasted veggies', 'cava vegetable protein'],
 'protein', 'CAVA', 1, '100 cal per serving (114g, 4oz). Roasted seasonal vegetables. Plant-based protein option.', TRUE),

-- ══════════════════════════════════════════
-- CAVA — DIPS & SPREADS
-- ══════════════════════════════════════════

-- CAVA Crazy Feta: 70 cal per serving (56g)
('cava_crazy_feta', 'CAVA Crazy Feta', 125.0, 7.1, 1.8, 10.7,
 0.0, 0.0, 56, NULL,
 'research', ARRAY['cava crazy feta', 'crazy feta cava', 'cava feta dip', 'cava crazy feta spread'],
 'dip', 'CAVA', 1, '70 cal per serving (56g, 2oz). Whipped feta dip with jalapeno and herbs.', TRUE),

-- CAVA Hummus: 50 cal per serving (56g)
('cava_hummus', 'CAVA Hummus', 89.3, 3.6, 7.1, 4.5,
 3.6, 0.0, 56, NULL,
 'research', ARRAY['cava hummus', 'hummus cava', 'cava classic hummus', 'cava hummus dip'],
 'dip', 'CAVA', 1, '50 cal per serving (56g, 2oz). Classic chickpea hummus.', TRUE),

-- CAVA Red Pepper Hummus: 40 cal per serving (56g)
('cava_red_pepper_hummus', 'CAVA Red Pepper Hummus', 71.4, 3.6, 8.9, 2.7,
 3.6, 1.8, 56, NULL,
 'research', ARRAY['cava red pepper hummus', 'red pepper hummus cava', 'cava roasted red pepper hummus', 'cava red pepper dip'],
 'dip', 'CAVA', 1, '40 cal per serving (56g, 2oz). Roasted red pepper hummus.', TRUE),

-- CAVA Harissa: 70 cal per serving (56g)
('cava_harissa', 'CAVA Harissa', 125.0, 1.8, 8.9, 10.7,
 1.8, 3.6, 56, NULL,
 'research', ARRAY['cava harissa', 'harissa cava', 'cava harissa spread', 'cava harissa dip'],
 'dip', 'CAVA', 1, '70 cal per serving (56g, 2oz). Spicy North African harissa spread.', TRUE),

-- CAVA Tzatziki: 30 cal per serving (56g)
('cava_tzatziki', 'CAVA Tzatziki', 53.6, 3.6, 1.8, 4.5,
 0.0, 1.8, 56, NULL,
 'research', ARRAY['cava tzatziki', 'tzatziki cava', 'cava tzatziki dip', 'cava cucumber yogurt dip'],
 'dip', 'CAVA', 1, '30 cal per serving (56g, 2oz). Cucumber yogurt dip.', TRUE),

-- CAVA Roasted Eggplant: 50 cal per serving (56g)
('cava_roasted_eggplant', 'CAVA Roasted Eggplant', 89.3, 0.0, 3.6, 8.9,
 1.8, 0.0, 56, NULL,
 'research', ARRAY['cava roasted eggplant', 'roasted eggplant cava', 'cava eggplant dip', 'cava baba ganoush'],
 'dip', 'CAVA', 1, '50 cal per serving (56g, 2oz). Roasted eggplant dip.', TRUE),

-- ══════════════════════════════════════════
-- CAVA — TOPPINGS
-- ══════════════════════════════════════════

-- CAVA Avocado: 110 cal per serving (60g)
('cava_avocado', 'CAVA Avocado', 183.3, 1.7, 10.0, 16.7,
 6.7, 0.0, 60, NULL,
 'research', ARRAY['cava avocado', 'avocado cava', 'cava fresh avocado topping', 'cava avocado add on'],
 'topping', 'CAVA', 1, '110 cal per serving (60g). Fresh sliced avocado topping.', TRUE),

-- CAVA Crumbled Feta: 35 cal per serving (28g)
('cava_crumbled_feta', 'CAVA Crumbled Feta', 125.0, 10.7, 0.0, 8.9,
 0.0, 3.6, 28, NULL,
 'research', ARRAY['cava crumbled feta', 'crumbled feta cava', 'cava feta cheese topping', 'cava feta crumbles'],
 'topping', 'CAVA', 1, '35 cal per serving (28g). Crumbled feta cheese topping.', TRUE),

-- CAVA Kalamata Olives: 35 cal per serving (28g)
('cava_kalamata_olives', 'CAVA Kalamata Olives', 125.0, 0.0, 7.1, 10.7,
 7.1, 0.0, 28, NULL,
 'research', ARRAY['cava kalamata olives', 'kalamata olives cava', 'cava olives topping', 'cava black olives'],
 'topping', 'CAVA', 1, '35 cal per serving (28g). Kalamata olive topping.', TRUE),

-- CAVA Fire-Roasted Corn: 45 cal per serving (28g)
('cava_fire_roasted_corn', 'CAVA Fire-Roasted Corn', 160.7, 3.6, 17.9, 8.9,
 3.6, 7.1, 28, NULL,
 'research', ARRAY['cava fire roasted corn', 'fire roasted corn cava', 'cava corn topping', 'cava roasted corn'],
 'topping', 'CAVA', 1, '45 cal per serving (28g). Fire-roasted corn kernels topping.', TRUE),

-- CAVA Fiery Broccoli: 35 cal per serving (28g)
('cava_fiery_broccoli', 'CAVA Fiery Broccoli', 125.0, 3.6, 7.1, 8.9,
 3.6, 3.6, 28, NULL,
 'research', ARRAY['cava fiery broccoli', 'fiery broccoli cava', 'cava spicy broccoli topping', 'cava broccoli'],
 'topping', 'CAVA', 1, '35 cal per serving (28g). Spicy roasted broccoli topping.', TRUE),

-- CAVA Pita Crisps: 70 cal per serving (28g)
('cava_pita_crisps', 'CAVA Pita Crisps', 250.0, 3.6, 21.4, 39.3,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava pita crisps', 'pita crisps cava', 'cava pita chips topping', 'cava crispy pita'],
 'topping', 'CAVA', 1, '70 cal per serving (28g). Crispy pita chip topping.', TRUE),

-- CAVA Cabbage Slaw: 35 cal per serving (42g)
('cava_cabbage_slaw', 'CAVA Cabbage Slaw', 83.3, 0.0, 4.8, 7.1,
 2.4, 2.4, 42, NULL,
 'research', ARRAY['cava cabbage slaw', 'cabbage slaw cava', 'cava slaw topping', 'cava pickled cabbage'],
 'topping', 'CAVA', 1, '35 cal per serving (42g). Dressed cabbage slaw topping.', TRUE),

-- CAVA Tomato + Onion: 20 cal per serving (28g)
('cava_tomato_onion', 'CAVA Tomato + Onion', 71.4, 0.0, 7.1, 5.4,
 0.0, 3.6, 28, NULL,
 'research', ARRAY['cava tomato onion', 'tomato onion cava', 'cava tomato and onion topping', 'cava diced tomato onion'],
 'topping', 'CAVA', 1, '20 cal per serving (28g). Diced tomato and onion topping.', TRUE),

-- CAVA Persian Cucumber: 15 cal per serving (28g)
('cava_persian_cucumber', 'CAVA Persian Cucumber', 53.6, 0.0, 3.6, 3.6,
 0.0, 3.6, 28, NULL,
 'research', ARRAY['cava persian cucumber', 'persian cucumber cava', 'cava cucumber topping', 'cava diced cucumber'],
 'topping', 'CAVA', 1, '15 cal per serving (28g). Diced Persian cucumber topping.', TRUE),

-- CAVA Tomato + Cucumber: 5 cal per serving (28g)
('cava_tomato_cucumber', 'CAVA Tomato + Cucumber', 17.9, 0.0, 3.6, 0.0,
 0.0, 3.6, 28, NULL,
 'research', ARRAY['cava tomato cucumber', 'tomato cucumber cava', 'cava tomato and cucumber topping', 'cava tomato cucumber mix'],
 'topping', 'CAVA', 1, '5 cal per serving (28g). Diced tomato and cucumber mix topping.', TRUE),

-- CAVA Pickled Onions: 20 cal per serving (28g)
('cava_pickled_onions', 'CAVA Pickled Onions', 71.4, 0.0, 17.9, 0.0,
 0.0, 14.3, 28, NULL,
 'research', ARRAY['cava pickled onions', 'pickled onions cava', 'cava pickled red onions', 'cava onion topping'],
 'topping', 'CAVA', 1, '20 cal per serving (28g). Pickled red onion topping.', TRUE),

-- CAVA Salt-Brined Pickles: 5 cal per serving (28g)
('cava_salt_brined_pickles', 'CAVA Salt-Brined Pickles', 17.9, 0.0, 0.0, 0.0,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava salt brined pickles', 'salt brined pickles cava', 'cava pickles topping', 'cava pickled cucumbers'],
 'topping', 'CAVA', 1, '5 cal per serving (28g). Salt-brined pickle topping.', TRUE),

-- CAVA Shredded Romaine: 5 cal per serving (28g)
('cava_shredded_romaine', 'CAVA Shredded Romaine', 17.9, 0.0, 3.6, 0.0,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava shredded romaine', 'shredded romaine cava', 'cava romaine topping', 'cava lettuce topping'],
 'topping', 'CAVA', 1, '5 cal per serving (28g). Shredded romaine lettuce topping.', TRUE),

-- ══════════════════════════════════════════
-- CAVA — DRESSINGS
-- ══════════════════════════════════════════

-- CAVA Greek Vinaigrette: 130 cal per serving (28g)
('cava_greek_vinaigrette', 'CAVA Greek Vinaigrette', 464.3, 0.0, 3.6, 50.0,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava greek vinaigrette', 'greek vinaigrette cava', 'cava greek dressing', 'cava vinaigrette'],
 'dressing', 'CAVA', 1, '130 cal per serving (28g). Classic Greek vinaigrette dressing.', TRUE),

-- CAVA Tahini Caesar: 90 cal per serving (28g)
('cava_tahini_caesar', 'CAVA Tahini Caesar', 321.4, 7.1, 10.7, 28.6,
 3.6, 0.0, 28, NULL,
 'research', ARRAY['cava tahini caesar', 'tahini caesar cava', 'cava caesar dressing', 'cava tahini caesar dressing'],
 'dressing', 'CAVA', 1, '90 cal per serving (28g). Tahini-based Caesar dressing.', TRUE),

-- CAVA Lemon-Herb Tahini: 70 cal per serving (28g)
('cava_lemon_herb_tahini', 'CAVA Lemon-Herb Tahini', 250.0, 7.1, 14.3, 21.4,
 7.1, 0.0, 28, NULL,
 'research', ARRAY['cava lemon herb tahini', 'lemon herb tahini cava', 'cava tahini dressing', 'cava lemon tahini'],
 'dressing', 'CAVA', 1, '70 cal per serving (28g). Lemon and herb tahini dressing.', TRUE),

-- CAVA Yogurt Dill: 30 cal per serving (28g)
('cava_yogurt_dill', 'CAVA Yogurt Dill', 107.1, 7.1, 3.6, 7.1,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava yogurt dill', 'yogurt dill cava', 'cava dill yogurt dressing', 'cava yogurt dressing'],
 'dressing', 'CAVA', 1, '30 cal per serving (28g). Yogurt dill dressing. Low calorie option.', TRUE),

-- CAVA Balsamic Date Vinaigrette: 60 cal per serving (28g)
('cava_balsamic_date_vinaigrette', 'CAVA Balsamic Date Vinaigrette', 214.3, 0.0, 25.0, 14.3,
 3.6, 17.9, 28, NULL,
 'research', ARRAY['cava balsamic date vinaigrette', 'balsamic date vinaigrette cava', 'cava balsamic date dressing', 'cava date vinaigrette'],
 'dressing', 'CAVA', 1, '60 cal per serving (28g). Sweet balsamic and date vinaigrette.', TRUE),

-- CAVA Skhug: 80 cal per serving (28g)
('cava_skhug', 'CAVA Skhug', 285.7, 0.0, 3.6, 32.1,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava skhug', 'skhug cava', 'cava schug dressing', 'cava green hot sauce skhug'],
 'dressing', 'CAVA', 1, '80 cal per serving (28g). Spicy Middle Eastern green hot sauce.', TRUE),

-- CAVA Hot Harissa Vinaigrette: 70 cal per serving (28g)
('cava_hot_harissa_vinaigrette', 'CAVA Hot Harissa Vinaigrette', 250.0, 0.0, 3.6, 25.0,
 0.0, 3.6, 28, NULL,
 'research', ARRAY['cava hot harissa vinaigrette', 'hot harissa vinaigrette cava', 'cava harissa dressing', 'cava hot harissa dressing'],
 'dressing', 'CAVA', 1, '70 cal per serving (28g). Spicy harissa vinaigrette dressing.', TRUE),

-- CAVA Garlic Dressing: 180 cal per serving (28g)
('cava_garlic_dressing', 'CAVA Garlic Dressing', 642.9, 0.0, 0.0, 71.4,
 0.0, 0.0, 28, NULL,
 'research', ARRAY['cava garlic dressing', 'garlic dressing cava', 'cava garlic sauce', 'cava toum garlic dressing'],
 'dressing', 'CAVA', 1, '180 cal per serving (28g). Rich garlic dressing (toum-style). Highest calorie dressing option.', TRUE)

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
