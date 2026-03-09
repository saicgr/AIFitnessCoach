-- 1605_overrides_olive_garden_epl_cf.sql
-- Olive Garden (~943 locations) — entrees, soups, salads.
-- El Pollo Loco (~487 locations) — bowls, burritos, chicken pieces, sides.
-- The Cheesecake Factory (~217 locations) — entrees, SkinnyLicious menu.
-- Sources: Nutritionix, HealthyFastFood.org, FatSecret, official nutrition PDFs.
-- All values per 100g. Restaurant serving weights are estimated.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- OLIVE GARDEN — ENTREES
-- ══════════════════════════════════════════

-- OG Chicken Alfredo: 1570 cal per serving (520g)
('og_chicken_alfredo', 'Olive Garden Chicken Alfredo', 301.9, 15.6, 18.5, 18.3,
 1.0, 1.2, 520, NULL,
 'research', ARRAY['olive garden chicken alfredo', 'og chicken alfredo', 'olive garden grilled chicken alfredo', 'og grilled chicken alfredo'],
 'entree', 'Olive Garden', 1, '1570 cal per order (520g). Grilled chicken breast over fettuccine with creamy Alfredo sauce.', TRUE),

-- OG Chicken Parmigiana: 1020 cal per serving (450g)
('og_chicken_parmigiana', 'Olive Garden Chicken Parmigiana', 226.7, 14.2, 17.8, 11.3,
 1.6, 2.9, 450, NULL,
 'research', ARRAY['olive garden chicken parmigiana', 'og chicken parm', 'olive garden chicken parmesan', 'og chicken parmigiana'],
 'entree', 'Olive Garden', 1, '1020 cal per order (450g). Breaded chicken breast with marinara, melted mozzarella, and spaghetti.', TRUE),

-- OG Stuffed Chicken Marsala: 1090 cal per serving (400g)
('og_stuffed_chicken_marsala', 'Olive Garden Stuffed Chicken Marsala', 272.5, 18.0, 13.3, 16.3,
 1.5, 2.3, 400, NULL,
 'research', ARRAY['olive garden stuffed chicken marsala', 'og chicken marsala', 'olive garden chicken marsala', 'og stuffed chicken marsala'],
 'entree', 'Olive Garden', 1, '1090 cal per order (400g). Chicken stuffed with Italian cheeses, sun-dried tomatoes, Marsala wine sauce.', TRUE),

-- OG Tour of Italy: 1550 cal per serving (550g)
('og_tour_of_italy', 'Olive Garden Tour of Italy', 281.8, 13.1, 18.0, 17.6,
 1.3, 2.2, 550, NULL,
 'research', ARRAY['olive garden tour of italy', 'og tour of italy', 'olive garden tour italia', 'og tour of italy combo'],
 'entree', 'Olive Garden', 1, '1550 cal per order (550g). Lasagna, chicken parmigiana, and fettuccine Alfredo combination plate.', TRUE),

-- OG Fettuccine Alfredo: 1310 cal per serving (450g)
('og_fettuccine_alfredo', 'Olive Garden Fettuccine Alfredo', 291.1, 6.7, 21.1, 20.0,
 0.9, 1.1, 450, NULL,
 'research', ARRAY['olive garden fettuccine alfredo', 'og fettuccine alfredo', 'olive garden alfredo pasta', 'og alfredo'],
 'entree', 'Olive Garden', 1, '1310 cal per order (450g). Fettuccine pasta with creamy Alfredo sauce.', TRUE),

-- OG Spaghetti with Meat Sauce: 640 cal per serving (400g)
('og_spaghetti_meat_sauce', 'Olive Garden Spaghetti with Meat Sauce', 160.0, 6.5, 21.3, 5.5,
 1.0, 4.3, 400, NULL,
 'research', ARRAY['olive garden spaghetti meat sauce', 'og spaghetti meat sauce', 'olive garden spaghetti bolognese', 'og spaghetti with meat sauce'],
 'entree', 'Olive Garden', 1, '640 cal per order (400g). Spaghetti with traditional meat sauce.', TRUE),

-- OG Lasagna Classico: 940 cal per serving (400g)
('og_lasagna_classico', 'Olive Garden Lasagna Classico', 235.0, 13.5, 15.3, 13.8,
 1.5, 2.8, 400, NULL,
 'research', ARRAY['olive garden lasagna', 'og lasagna classico', 'olive garden lasagna classico', 'og lasagna'],
 'entree', 'Olive Garden', 1, '940 cal per order (400g). Layers of pasta, meat sauce, ricotta, and mozzarella cheese.', TRUE),

-- OG Chicken & Shrimp Carbonara: 1370 cal per serving (500g)
('og_chicken_shrimp_carbonara', 'Olive Garden Chicken & Shrimp Carbonara', 274.0, 12.8, 15.0, 18.2,
 0.6, 2.0, 500, NULL,
 'research', ARRAY['olive garden chicken shrimp carbonara', 'og chicken shrimp carbonara', 'olive garden carbonara', 'og carbonara'],
 'entree', 'Olive Garden', 1, '1370 cal per order (500g). Sauteed chicken and shrimp with bucatini pasta in a creamy carbonara sauce.', TRUE),

-- ══════════════════════════════════════════
-- OLIVE GARDEN — SOUPS
-- ══════════════════════════════════════════

-- OG Zuppa Toscana (bowl): 220 cal per serving (350g)
('og_zuppa_toscana', 'Olive Garden Zuppa Toscana (Bowl)', 62.9, 2.0, 4.3, 4.3,
 0.6, 0.6, 350, NULL,
 'research', ARRAY['olive garden zuppa toscana', 'og zuppa toscana', 'olive garden zuppa toscana soup', 'og zuppa toscana bowl'],
 'soup', 'Olive Garden', 1, '220 cal per bowl (350g). Spicy sausage, potato, and kale in a creamy broth.', TRUE),

-- OG Pasta e Fagioli (bowl): 150 cal per serving (350g)
('og_pasta_e_fagioli', 'Olive Garden Pasta e Fagioli (Bowl)', 42.9, 2.3, 4.6, 1.4,
 0.9, 1.1, 350, NULL,
 'research', ARRAY['olive garden pasta e fagioli', 'og pasta e fagioli', 'olive garden pasta fagioli soup', 'og pasta fagioli bowl'],
 'soup', 'Olive Garden', 1, '150 cal per bowl (350g). Bean and pasta soup with ground beef and Italian seasonings.', TRUE),

-- OG Minestrone (bowl): 110 cal per serving (350g)
('og_minestrone', 'Olive Garden Minestrone (Bowl)', 31.4, 1.4, 4.9, 0.3,
 1.1, 1.1, 350, NULL,
 'research', ARRAY['olive garden minestrone', 'og minestrone', 'olive garden minestrone soup', 'og minestrone bowl'],
 'soup', 'Olive Garden', 1, '110 cal per bowl (350g). Vegetable soup with beans, pasta, and Italian herbs.', TRUE),

-- ══════════════════════════════════════════
-- OLIVE GARDEN — SALADS
-- ══════════════════════════════════════════

-- OG House Salad with Signature Italian Dressing: 150 cal per serving (250g)
('og_house_salad', 'Olive Garden House Salad w/ Signature Italian', 60.0, 1.2, 5.2, 4.0,
 0.8, 0.8, 250, NULL,
 'research', ARRAY['olive garden house salad', 'og house salad', 'olive garden salad italian dressing', 'og house salad signature italian'],
 'salad', 'Olive Garden', 1, '150 cal per serving (250g). Mixed greens, tomatoes, olives, onions, croutons with Signature Italian dressing.', TRUE),

-- OG Caesar Salad: 400 cal per serving (300g)
('og_caesar_salad', 'Olive Garden Caesar Salad', 133.3, 6.0, 6.7, 9.3,
 1.0, 1.0, 300, NULL,
 'research', ARRAY['olive garden caesar salad', 'og caesar salad', 'olive garden caesar', 'og caesar salad with croutons'],
 'salad', 'Olive Garden', 1, '400 cal per serving (300g). Romaine lettuce, Parmesan, croutons with Caesar dressing.', TRUE),

-- ══════════════════════════════════════════
-- OLIVE GARDEN — BREAD
-- ══════════════════════════════════════════

-- OG Breadstick: 140 cal per piece (43g)
('og_breadstick', 'Olive Garden Breadstick', 325.6, 9.3, 58.1, 5.8,
 0.0, 2.3, NULL, 43,
 'research', ARRAY['olive garden breadstick', 'og breadstick', 'olive garden garlic breadstick', 'og breadstick garlic'],
 'bread', 'Olive Garden', 1, '140 cal per breadstick (43g). Warm garlic breadstick with butter topping.', TRUE),

-- ══════════════════════════════════════════
-- EL POLLO LOCO — BOWLS
-- ══════════════════════════════════════════

-- EPL Original Pollo Bowl: 530 cal per serving (450g)
('epl_original_pollo_bowl', 'El Pollo Loco Original Pollo Bowl', 117.8, 8.0, 17.8, 1.6,
 2.2, 0.7, 450, NULL,
 'research', ARRAY['el pollo loco original pollo bowl', 'epl pollo bowl', 'el pollo loco pollo bowl', 'epl original bowl'],
 'bowl', 'El Pollo Loco', 1, '530 cal per bowl (450g). Fire-grilled chicken with rice, pinto beans, pico de gallo, and salsa.', TRUE),

-- EPL Double Chicken Bowl: 860 cal per serving (550g)
('epl_double_chicken_bowl', 'El Pollo Loco Double Chicken Bowl', 156.4, 11.8, 15.6, 4.9,
 2.4, 0.9, 550, NULL,
 'research', ARRAY['el pollo loco double chicken bowl', 'epl double chicken bowl', 'el pollo loco double bowl', 'epl double pollo bowl'],
 'bowl', 'El Pollo Loco', 1, '860 cal per bowl (550g). Double portion of fire-grilled chicken with rice, beans, and toppings.', TRUE),

-- ══════════════════════════════════════════
-- EL POLLO LOCO — BURRITOS
-- ══════════════════════════════════════════

-- EPL BRC Burrito: 410 cal per serving (250g)
('epl_brc_burrito', 'El Pollo Loco BRC Burrito', 164.0, 5.6, 24.4, 4.4,
 2.0, 0.4, 250, NULL,
 'research', ARRAY['el pollo loco brc burrito', 'epl brc burrito', 'el pollo loco bean rice cheese burrito', 'epl bean rice cheese burrito'],
 'burrito', 'El Pollo Loco', 1, '410 cal per burrito (250g). Bean, rice, and cheese burrito in a flour tortilla.', TRUE),

-- EPL Classic Chicken Burrito: 510 cal per serving (320g)
('epl_classic_chicken_burrito', 'El Pollo Loco Classic Chicken Burrito', 159.4, 8.1, 20.3, 4.7,
 1.6, 0.3, 320, NULL,
 'research', ARRAY['el pollo loco classic chicken burrito', 'epl classic chicken burrito', 'el pollo loco chicken burrito', 'epl chicken burrito'],
 'burrito', 'El Pollo Loco', 1, '510 cal per burrito (320g). Fire-grilled chicken with rice, beans, and cheese in a flour tortilla.', TRUE),

-- EPL Chicken Avocado Burrito: 890 cal per serving (400g)
('epl_chicken_avocado_burrito', 'El Pollo Loco Chicken Avocado Burrito', 222.5, 11.5, 17.8, 12.0,
 2.5, 1.3, 400, NULL,
 'research', ARRAY['el pollo loco chicken avocado burrito', 'epl chicken avocado burrito', 'el pollo loco avocado burrito', 'epl avocado chicken burrito'],
 'burrito', 'El Pollo Loco', 1, '890 cal per burrito (400g). Fire-grilled chicken with avocado, rice, beans, and cheese.', TRUE),

-- ══════════════════════════════════════════
-- EL POLLO LOCO — CHICKEN PIECES
-- ══════════════════════════════════════════

-- EPL Chicken Breast: 220 cal per piece (154g)
('epl_chicken_breast', 'El Pollo Loco Fire-Grilled Chicken Breast', 142.9, 23.4, 0.0, 5.8,
 0.0, 0.0, NULL, 154,
 'research', ARRAY['el pollo loco chicken breast', 'epl chicken breast', 'el pollo loco grilled chicken breast', 'epl fire grilled breast'],
 'chicken', 'El Pollo Loco', 1, '220 cal per breast (154g). Citrus-marinated fire-grilled chicken breast.', TRUE),

-- EPL Chicken Thigh: 210 cal per piece (100g)
('epl_chicken_thigh', 'El Pollo Loco Fire-Grilled Chicken Thigh', 210.0, 21.0, 0.0, 15.0,
 0.0, 0.0, NULL, 100,
 'research', ARRAY['el pollo loco chicken thigh', 'epl chicken thigh', 'el pollo loco grilled chicken thigh', 'epl fire grilled thigh'],
 'chicken', 'El Pollo Loco', 1, '210 cal per thigh (100g). Citrus-marinated fire-grilled chicken thigh.', TRUE),

-- EPL Chicken Leg: 80 cal per piece (57g)
('epl_chicken_leg', 'El Pollo Loco Fire-Grilled Chicken Leg', 140.4, 21.1, 0.0, 7.0,
 0.0, 0.0, NULL, 57,
 'research', ARRAY['el pollo loco chicken leg', 'epl chicken leg', 'el pollo loco grilled chicken leg', 'epl fire grilled leg'],
 'chicken', 'El Pollo Loco', 1, '80 cal per leg (57g). Citrus-marinated fire-grilled chicken leg.', TRUE),

-- EPL Chicken Wing: 90 cal per piece (43g)
('epl_chicken_wing', 'El Pollo Loco Fire-Grilled Chicken Wing', 209.3, 27.9, 0.0, 11.6,
 0.0, 0.0, NULL, 43,
 'research', ARRAY['el pollo loco chicken wing', 'epl chicken wing', 'el pollo loco grilled chicken wing', 'epl fire grilled wing'],
 'chicken', 'El Pollo Loco', 1, '90 cal per wing (43g). Citrus-marinated fire-grilled chicken wing.', TRUE),

-- ══════════════════════════════════════════
-- EL POLLO LOCO — SALAD
-- ══════════════════════════════════════════

-- EPL Chicken Tostada Salad: 830 cal per serving (450g)
('epl_tostada_salad', 'El Pollo Loco Chicken Tostada Salad', 184.4, 8.7, 16.7, 9.1,
 1.6, 1.1, 450, NULL,
 'research', ARRAY['el pollo loco tostada salad', 'epl tostada salad', 'el pollo loco chicken tostada salad', 'epl chicken tostada'],
 'salad', 'El Pollo Loco', 1, '830 cal per salad (450g). Chicken tostada salad with beans, cheese, sour cream, and avocado.', TRUE),

-- ══════════════════════════════════════════
-- EL POLLO LOCO — SIDES
-- ══════════════════════════════════════════

-- EPL Mexican Rice (Large): 380 cal per serving (250g)
('epl_mexican_rice', 'El Pollo Loco Mexican Rice (Large)', 152.0, 3.2, 30.4, 1.6,
 1.2, 0.4, 250, NULL,
 'research', ARRAY['el pollo loco mexican rice', 'epl mexican rice', 'el pollo loco rice large', 'epl rice side large'],
 'side', 'El Pollo Loco', 1, '380 cal per large side (250g). Seasoned Mexican-style rice.', TRUE),

-- EPL Pinto Beans (Large): 400 cal per serving (250g)
('epl_pinto_beans', 'El Pollo Loco Pinto Beans (Large)', 160.0, 8.0, 25.6, 2.8,
 5.6, 0.4, 250, NULL,
 'research', ARRAY['el pollo loco pinto beans', 'epl pinto beans', 'el pollo loco beans large', 'epl pinto beans large'],
 'side', 'El Pollo Loco', 1, '400 cal per large side (250g). Slow-cooked pinto beans.', TRUE),

-- EPL Black Beans (Large): 370 cal per serving (250g)
('epl_black_beans', 'El Pollo Loco Black Beans (Large)', 148.0, 8.8, 26.0, 1.0,
 6.0, 0.4, 250, NULL,
 'research', ARRAY['el pollo loco black beans', 'epl black beans', 'el pollo loco black beans large', 'epl black beans large'],
 'side', 'El Pollo Loco', 1, '370 cal per large side (250g). Seasoned black beans.', TRUE),

-- ══════════════════════════════════════════
-- THE CHEESECAKE FACTORY — ENTREES
-- ══════════════════════════════════════════

-- CF Bang Bang Chicken & Shrimp: 1370 cal per serving (550g)
('cf_bang_bang_chicken_shrimp', 'The Cheesecake Factory Bang Bang Chicken & Shrimp', 249.1, 13.6, 26.2, 10.2,
 1.5, 4.7, 550, NULL,
 'research', ARRAY['cheesecake factory bang bang chicken shrimp', 'cf bang bang chicken', 'cheesecake factory bang bang', 'cf bang bang chicken and shrimp'],
 'entree', 'The Cheesecake Factory', 1, '1370 cal per order (550g). Crispy chicken and shrimp with bang bang sauce over rice.', TRUE),

-- CF Fish & Chips: 1860 cal per serving (600g)
('cf_fish_and_chips', 'The Cheesecake Factory Fish & Chips', 310.0, 8.8, 22.2, 20.2,
 0.8, 5.2, 600, NULL,
 'research', ARRAY['cheesecake factory fish and chips', 'cf fish and chips', 'cheesecake factory fish chips', 'cf fish n chips'],
 'entree', 'The Cheesecake Factory', 1, '1860 cal per order (600g). Beer-battered fish with french fries and tartar sauce.', TRUE),

-- CF SkinnyLicious Spicy Shrimp Pasta: 580 cal per serving (450g)
('cf_skinnylicious_spicy_shrimp_pasta', 'The Cheesecake Factory SkinnyLicious Spicy Shrimp Pasta', 128.9, 4.7, 16.0, 4.7,
 1.3, 3.3, 450, NULL,
 'research', ARRAY['cheesecake factory skinnylicious spicy shrimp pasta', 'cf skinnylicious shrimp pasta', 'cheesecake factory skinny shrimp pasta', 'cf spicy shrimp pasta skinnylicious'],
 'entree', 'The Cheesecake Factory', 1, '580 cal per order (450g). SkinnyLicious menu item. Shrimp with pasta in a spicy tomato sauce.', TRUE),

-- CF SkinnyLicious Chicken Pasta: 590 cal per serving (450g)
('cf_skinnylicious_chicken_pasta', 'The Cheesecake Factory SkinnyLicious Chicken Pasta', 131.1, 10.9, 20.2, 1.3,
 0.9, 1.8, 450, NULL,
 'research', ARRAY['cheesecake factory skinnylicious chicken pasta', 'cf skinnylicious chicken pasta', 'cheesecake factory skinny chicken pasta', 'cf chicken pasta skinnylicious'],
 'entree', 'The Cheesecake Factory', 1, '590 cal per order (450g). SkinnyLicious menu item. Grilled chicken with pasta and vegetables.', TRUE),

-- CF SkinnyLicious Grilled Salmon: 570 cal per serving (400g)
('cf_skinnylicious_grilled_salmon', 'The Cheesecake Factory SkinnyLicious Grilled Salmon', 142.5, 10.8, 10.0, 6.5,
 1.3, 1.5, 400, NULL,
 'research', ARRAY['cheesecake factory skinnylicious grilled salmon', 'cf skinnylicious salmon', 'cheesecake factory skinny salmon', 'cf grilled salmon skinnylicious'],
 'entree', 'The Cheesecake Factory', 1, '570 cal per order (400g). SkinnyLicious menu item. Grilled salmon with vegetables.', TRUE),

-- CF SkinnyLicious Asian Chicken Salad: 550 cal per serving (450g)
('cf_skinnylicious_asian_chicken_salad', 'The Cheesecake Factory SkinnyLicious Asian Chicken Salad', 122.2, 6.7, 9.8, 6.0,
 1.1, 4.4, 450, NULL,
 'research', ARRAY['cheesecake factory skinnylicious asian chicken salad', 'cf skinnylicious asian salad', 'cheesecake factory skinny asian salad', 'cf asian chicken salad skinnylicious'],
 'salad', 'The Cheesecake Factory', 1, '550 cal per order (450g). SkinnyLicious menu item. Asian-style chicken salad with greens and sesame dressing.', TRUE),

-- CF SkinnyLicious Lemon-Garlic Shrimp: 510 cal per serving (400g)
('cf_skinnylicious_lemon_garlic_shrimp', 'The Cheesecake Factory SkinnyLicious Lemon-Garlic Shrimp', 127.5, 9.3, 8.8, 5.8,
 1.3, 1.3, 400, NULL,
 'research', ARRAY['cheesecake factory skinnylicious lemon garlic shrimp', 'cf skinnylicious lemon shrimp', 'cheesecake factory skinny lemon garlic shrimp', 'cf lemon garlic shrimp skinnylicious'],
 'entree', 'The Cheesecake Factory', 1, '510 cal per order (400g). SkinnyLicious menu item. Sauteed shrimp with lemon-garlic sauce and vegetables.', TRUE)

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
