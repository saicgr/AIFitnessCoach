-- 402_more_us_chains.sql
-- Additional US chain restaurant items: Cheesecake Factory, Waffle House, Cracker Barrel,
-- Buffalo Wild Wings, Red Robin, Bob Evans, In-N-Out, Shake Shack, Culver's, Wingstop,
-- Portillo's, Whataburger, Torchy's Tacos, Zaxby's, Cook Out, Sweetgreen.
-- Sources: fastfoodnutrition.org, nutritionix.com, calorieking.com, fatsecret.com,
-- official chain nutrition PDFs (in-n-out.com, shakeshack.com, whataburger.com, buffalowildwings.com, culvers.com)
-- All values per 100g, computed from per-serving nutrition label data.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active,
  sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g,
  potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg,
  vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g
) VALUES

-- ==========================================
-- CHEESECAKE FACTORY (Expand)
-- ==========================================

-- Avocado Egg Rolls: 930 cal per serving (~310g). Per 100g: 300 cal, 4.5P, 35.8C, 15.5F
('cf_avocado_egg_rolls', 'Cheesecake Factory Avocado Egg Rolls', 300, 4.5, 35.8, 15.5,
 4.5, 12.3, 310, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory avocado eggrolls', 'cf avocado egg rolls', 'avocado egg rolls cheesecake factory'],
 'american', 'Cheesecake Factory', 1, '300 cal/100g. Per serving (~310g): 930 cal, 48F, 111C, 14P. Avocado, sun-dried tomato, red onion, cilantro in crispy wrappers.', TRUE,
 419, 5, 3.2, 0.0, 280, 40, 1.5, 30, 6.0, 0, 25, 0.6, 80, 5, 0.1),

-- Chicken Madeira: 1440 cal per serving (~540g). Per 100g: 267 cal, 13.1P, 13.3C, 17.8F
('cf_chicken_madeira', 'Cheesecake Factory Chicken Madeira', 267, 13.1, 13.3, 17.8,
 1.1, 2.6, 540, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory chicken madeira', 'cf chicken madeira', 'chicken madeira'],
 'american', 'Cheesecake Factory', 1, '267 cal/100g. Per serving (~540g): 1440 cal, 96F, 72C, 71P. Chicken breast, mushrooms, asparagus, mashed potatoes, Madeira wine sauce.', TRUE,
 350, 69, 9.1, 0.0, 420, 80, 2.0, 60, 8.0, 0, 35, 2.5, 200, 20, 0.05),

-- Louisiana Chicken Pasta: 1290 cal per lunch serving (~480g). Per 100g: 269 cal, 10.4P, 20.8C, 16.3F
('cf_louisiana_chicken_pasta', 'Cheesecake Factory Louisiana Chicken Pasta', 269, 10.4, 20.8, 16.3,
 1.5, 2.1, 480, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory louisiana chicken pasta', 'cf louisiana pasta', 'louisiana chicken pasta'],
 'american', 'Cheesecake Factory', 1, '269 cal/100g. Per serving (~480g): 1290 cal. Parmesan-crusted chicken, peppers, onions, spicy New Orleans sauce, bow-tie pasta.', TRUE,
 375, 52, 7.3, 0.2, 300, 120, 2.0, 50, 12.0, 0, 30, 1.8, 170, 18, 0.05),

-- Orange Chicken: 1550 cal per serving (~520g). Per 100g: 298 cal, 12.5P, 28.8C, 15.4F
('cf_orange_chicken', 'Cheesecake Factory Orange Chicken', 298, 12.5, 28.8, 15.4,
 1.0, 14.0, 520, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory orange chicken', 'cf orange chicken'],
 'american', 'Cheesecake Factory', 1, '298 cal/100g. Per serving (~520g): 1550 cal. Crispy chicken, orange sauce, white rice.', TRUE,
 365, 38, 4.0, 0.1, 250, 30, 1.5, 20, 10.0, 0, 20, 1.2, 140, 15, 0.03),

-- Bang-Bang Chicken & Shrimp: 1650 cal per serving (~550g). Per 100g: 300 cal, 11.8P, 25.5C, 16.4F
('cf_bang_bang_chicken_shrimp', 'Cheesecake Factory Bang-Bang Chicken & Shrimp', 300, 11.8, 25.5, 16.4,
 1.2, 8.0, 550, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory bang bang chicken shrimp', 'cf bang bang chicken', 'bang bang chicken and shrimp'],
 'american', 'Cheesecake Factory', 1, '300 cal/100g. Per serving (~550g): 1650 cal. Crispy chicken and shrimp, spicy bang-bang sauce, rice.', TRUE,
 390, 42, 4.5, 0.2, 260, 35, 1.8, 25, 6.0, 0, 22, 1.5, 150, 16, 0.1),

-- Oreo Cheesecake: 1620 cal per slice (~320g). Per 100g: 506 cal, 6.3P, 50.0C, 31.3F
('cf_oreo_cheesecake', 'Cheesecake Factory Oreo Dream Extreme Cheesecake', 506, 6.3, 50.0, 31.3,
 1.6, 37.5, 320, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory oreo cheesecake', 'oreo dream extreme cheesecake', 'cf oreo cheesecake'],
 'american', 'Cheesecake Factory', 1, '506 cal/100g. Per slice (~320g): 1620 cal. Oreo cookie crust, layers of Oreo cheesecake, fudge cake, Oreo cookies.', TRUE,
 300, 75, 18.8, 0.5, 200, 80, 3.0, 80, 0.0, 0, 30, 1.0, 140, 5, 0.02),

-- Original Cheesecake: 830 cal per slice (~200g). Per 100g: 415 cal, 6.0P, 31.5C, 29.5F
('cf_original_cheesecake', 'Cheesecake Factory Original Cheesecake', 415, 6.0, 31.5, 29.5,
 0.5, 25.5, 200, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory original cheesecake', 'cf original cheesecake', 'cheesecake factory plain cheesecake'],
 'american', 'Cheesecake Factory', 1, '415 cal/100g. Per slice (~200g): 830 cal, 59F, 63C, 12P. Classic creamy cheesecake, graham cracker crust.', TRUE,
 255, 133, 18.5, 0.5, 140, 60, 1.0, 180, 0.5, 10, 12, 0.8, 120, 5, 0.02),

-- Dulce de Leche Cheesecake: 900 cal per slice (~210g). Per 100g: 429 cal, 5.7P, 38.1C, 28.6F
('cf_dulce_de_leche_cheesecake', 'Cheesecake Factory Dulce de Leche Cheesecake', 429, 5.7, 38.1, 28.6,
 0.5, 30.0, 210, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory dulce de leche cheesecake', 'cf dulce de leche', 'dulce de leche caramel cheesecake'],
 'american', 'Cheesecake Factory', 1, '429 cal/100g. Per slice (~210g): 900 cal. Caramel cheesecake, whipped cream, caramel sauce.', TRUE,
 280, 120, 17.1, 0.3, 160, 70, 0.8, 150, 0.5, 8, 14, 0.7, 110, 4, 0.02),

-- Fresh Strawberry Cheesecake: 860 cal per slice (~220g). Per 100g: 391 cal, 5.5P, 33.6C, 26.4F
('cf_strawberry_cheesecake', 'Cheesecake Factory Fresh Strawberry Cheesecake', 391, 5.5, 33.6, 26.4,
 0.9, 25.0, 220, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory strawberry cheesecake', 'cf strawberry cheesecake', 'fresh strawberry cheesecake'],
 'american', 'Cheesecake Factory', 1, '391 cal/100g. Per slice (~220g): 860 cal. Original cheesecake topped with glazed fresh strawberries.', TRUE,
 245, 125, 16.4, 0.3, 170, 55, 1.0, 160, 12.0, 8, 13, 0.7, 115, 4, 0.02),

-- White Chocolate Raspberry: 910 cal per slice (~210g). Per 100g: 433 cal, 5.2P, 40.0C, 28.6F
('cf_white_choc_raspberry_cheesecake', 'Cheesecake Factory White Chocolate Raspberry Cheesecake', 433, 5.2, 40.0, 28.6,
 1.0, 32.0, 210, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory white chocolate raspberry', 'cf white chocolate raspberry cheesecake'],
 'american', 'Cheesecake Factory', 1, '433 cal/100g. Per slice (~210g): 910 cal. Creamy white chocolate cheesecake swirled with raspberries.', TRUE,
 260, 110, 17.6, 0.3, 150, 65, 0.9, 140, 4.0, 6, 14, 0.6, 105, 3, 0.02),

-- Glamburger: 1230 cal per serving (~380g). Per 100g: 324 cal, 14.5P, 17.1C, 22.4F
('cf_glamburger', 'Cheesecake Factory Glamburger', 324, 14.5, 17.1, 22.4,
 1.3, 3.2, 380, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory glamburger', 'cf glamburger'],
 'american', 'Cheesecake Factory', 1, '324 cal/100g. Per serving (~380g): 1230 cal. Premium burger, American cheese, lettuce, tomato, special sauce.', TRUE,
 350, 55, 9.5, 0.5, 320, 100, 3.0, 40, 4.0, 0, 28, 3.5, 190, 18, 0.05),

-- Fish Tacos: 1430 cal per serving (~450g). Per 100g: 318 cal, 10.0P, 22.2C, 20.0F
('cf_fish_tacos', 'Cheesecake Factory Fish Tacos', 318, 10.0, 22.2, 20.0,
 2.2, 3.3, 450, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory fish tacos', 'cf fish tacos'],
 'american', 'Cheesecake Factory', 1, '318 cal/100g. Per serving (~450g): 1430 cal. Crispy battered fish, cabbage slaw, avocado, spicy sauce, corn tortillas.', TRUE,
 340, 35, 5.0, 0.2, 300, 60, 1.5, 30, 8.0, 0, 25, 1.2, 150, 15, 0.15),

-- Truffle-Honey Chicken: 1210 cal per serving (~460g). Per 100g: 263 cal, 13.5P, 15.2C, 16.5F
('cf_truffle_honey_chicken', 'Cheesecake Factory Truffle-Honey Chicken', 263, 13.5, 15.2, 16.5,
 1.0, 5.0, 460, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory truffle honey chicken', 'cf truffle honey chicken'],
 'american', 'Cheesecake Factory', 1, '263 cal/100g. Per serving (~460g): 1210 cal. Crispy chicken, truffle honey glaze, green beans, mashed potatoes.', TRUE,
 330, 50, 5.5, 0.2, 350, 45, 1.8, 35, 6.0, 0, 28, 1.5, 170, 16, 0.03),

-- Miso Salmon: 1340 cal per serving (~480g). Per 100g: 279 cal, 14.6P, 16.7C, 16.7F
('cf_miso_salmon', 'Cheesecake Factory Miso Salmon', 279, 14.6, 16.7, 16.7,
 1.5, 5.0, 480, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory miso salmon', 'cf miso salmon'],
 'american', 'Cheesecake Factory', 1, '279 cal/100g. Per serving (~480g): 1340 cal. Miso-glazed salmon, rice, vegetables.', TRUE,
 380, 45, 4.2, 0.0, 400, 40, 1.5, 50, 5.0, 15, 35, 1.0, 200, 30, 1.5),

-- Shepherd''s Pie: 1310 cal per serving (~500g). Per 100g: 262 cal, 10.0P, 18.0C, 16.0F
('cf_shepherds_pie', 'Cheesecake Factory Shepherd''s Pie', 262, 10.0, 18.0, 16.0,
 1.5, 2.5, 500, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory shepherds pie', 'cf shepherds pie'],
 'american', 'Cheesecake Factory', 1, '262 cal/100g. Per serving (~500g): 1310 cal. Ground beef, vegetables, mashed potato crust, gravy.', TRUE,
 320, 40, 7.0, 0.3, 350, 50, 2.0, 100, 5.0, 0, 25, 2.5, 160, 12, 0.04),

-- Factory Nachos: 1580 cal per serving (~550g). Per 100g: 287 cal, 8.2P, 21.8C, 18.5F
('cf_factory_nachos', 'Cheesecake Factory Factory Nachos', 287, 8.2, 21.8, 18.5,
 2.5, 2.2, 550, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory factory nachos', 'cf nachos', 'cheesecake factory nachos'],
 'american', 'Cheesecake Factory', 1, '287 cal/100g. Per serving (~550g): 1580 cal. Tortilla chips, melted cheese, guacamole, sour cream, salsa, chicken or beef.', TRUE,
 400, 40, 8.5, 0.3, 300, 120, 2.0, 60, 6.0, 0, 30, 2.0, 180, 10, 0.05),

-- Roadside Sliders: 1350 cal per serving (~400g). Per 100g: 338 cal, 15.0P, 20.0C, 22.0F
('cf_roadside_sliders', 'Cheesecake Factory Roadside Sliders', 338, 15.0, 20.0, 22.0,
 1.0, 3.5, 400, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory roadside sliders', 'cf sliders'],
 'american', 'Cheesecake Factory', 1, '338 cal/100g. Per serving (~400g): 1350 cal. Three mini burgers, American cheese, pickles, grilled onions, ketchup.', TRUE,
 380, 60, 9.5, 0.5, 280, 80, 2.5, 30, 2.0, 0, 22, 3.0, 170, 15, 0.04),

-- Thai Lettuce Wraps: 870 cal per serving (~350g). Per 100g: 249 cal, 12.6P, 18.6C, 13.7F
('cf_thai_lettuce_wraps', 'Cheesecake Factory Thai Lettuce Wraps', 249, 12.6, 18.6, 13.7,
 2.0, 6.0, 350, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory thai lettuce wraps', 'cf lettuce wraps', 'thai lettuce wraps'],
 'american', 'Cheesecake Factory', 1, '249 cal/100g. Per serving (~350g): 870 cal. Chicken, vegetables, peanuts, coconut curry sauce, butter lettuce cups.', TRUE,
 420, 35, 4.0, 0.1, 350, 40, 1.5, 40, 10.0, 0, 30, 1.5, 160, 12, 0.05),

-- SkinnyLicious Chicken: 510 cal per serving (~380g). Per 100g: 134 cal, 14.5P, 10.5C, 3.9F
('cf_skinnylicious_chicken', 'Cheesecake Factory SkinnyLicious Grilled Chicken', 134, 14.5, 10.5, 3.9,
 2.0, 2.5, 380, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory skinnylicious chicken', 'cf skinnylicious grilled chicken', 'skinnylicious chicken'],
 'american', 'Cheesecake Factory', 1, '134 cal/100g. Per serving (~380g): 510 cal. Grilled chicken breast, steamed broccoli, asparagus, green beans.', TRUE,
 260, 30, 1.0, 0.0, 380, 40, 1.2, 50, 15.0, 0, 28, 1.0, 180, 20, 0.03),

-- SkinnyLicious Pasta: 560 cal per serving (~400g). Per 100g: 140 cal, 7.0P, 17.5C, 4.5F
('cf_skinnylicious_pasta', 'Cheesecake Factory SkinnyLicious Pasta', 140, 7.0, 17.5, 4.5,
 1.8, 2.0, 400, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory skinnylicious pasta', 'cf skinnylicious pasta'],
 'american', 'Cheesecake Factory', 1, '140 cal/100g. Per serving (~400g): 560 cal. Lighter portion pasta with tomato basil sauce and chicken.', TRUE,
 240, 25, 1.5, 0.0, 300, 50, 1.5, 40, 8.0, 0, 22, 1.0, 140, 12, 0.03),

-- Brown Bread (1 loaf): 1060 cal per loaf (~340g). Per 100g: 312 cal, 6.5P, 52.9C, 8.2F
('cf_brown_bread', 'Cheesecake Factory Brown Bread', 312, 6.5, 52.9, 8.2,
 3.5, 17.6, 85, 85,
 'cheesecake_factory', ARRAY['cheesecake factory brown bread', 'cf brown bread', 'cheesecake factory honey wheat bread'],
 'american', 'Cheesecake Factory', 1, '312 cal/100g. Per mini loaf (~85g): 265 cal. Sweet honey-wheat brown bread served warm.', TRUE,
 320, 10, 2.0, 0.0, 120, 30, 2.0, 0, 0.0, 0, 20, 0.8, 80, 10, 0.02),

-- Evelyn''s Favorite Pasta: 1350 cal per serving (~480g). Per 100g: 281 cal, 9.4P, 22.9C, 16.7F
('cf_evelyns_favorite_pasta', 'Cheesecake Factory Evelyn''s Favorite Pasta', 281, 9.4, 22.9, 16.7,
 1.5, 3.0, 480, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory evelyns favorite pasta', 'cf evelyns pasta'],
 'american', 'Cheesecake Factory', 1, '281 cal/100g. Per serving (~480g): 1350 cal. Chicken, broccoli, zucchini, pasta, creamy tomato pesto sauce.', TRUE,
 370, 50, 7.5, 0.2, 320, 100, 2.0, 60, 10.0, 0, 28, 1.5, 170, 15, 0.04),

-- Chicken Piccata: 1160 cal per serving (~440g). Per 100g: 264 cal, 14.5P, 15.9C, 15.9F
('cf_chicken_piccata', 'Cheesecake Factory Chicken Piccata', 264, 14.5, 15.9, 15.9,
 1.0, 1.5, 440, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory chicken piccata', 'cf chicken piccata'],
 'american', 'Cheesecake Factory', 1, '264 cal/100g. Per serving (~440g): 1160 cal. Sauteed chicken breast, lemon-caper sauce, angel hair pasta.', TRUE,
 360, 55, 6.0, 0.2, 300, 45, 1.8, 35, 8.0, 0, 25, 1.5, 180, 18, 0.04),

-- Chicken Bellagio: 1510 cal per serving (~520g). Per 100g: 290 cal, 12.3P, 19.2C, 18.3F
('cf_chicken_bellagio', 'Cheesecake Factory Chicken Bellagio', 290, 12.3, 19.2, 18.3,
 1.2, 2.5, 520, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory chicken bellagio', 'cf chicken bellagio'],
 'american', 'Cheesecake Factory', 1, '290 cal/100g. Per serving (~520g): 1510 cal. Parmesan-crusted chicken, pasta, basil, prosciutto, Madeira cream sauce.', TRUE,
 380, 60, 8.0, 0.3, 310, 90, 2.0, 50, 5.0, 0, 28, 2.0, 190, 16, 0.04),

-- Cobb Salad: 830 cal per serving (~450g). Per 100g: 184 cal, 12.2P, 5.6C, 12.9F
('cf_cobb_salad', 'Cheesecake Factory Cobb Salad', 184, 12.2, 5.6, 12.9,
 2.0, 2.5, 450, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory cobb salad', 'cf cobb salad'],
 'american', 'Cheesecake Factory', 1, '184 cal/100g. Per serving (~450g): 830 cal. Mixed greens, chicken, avocado, bacon, egg, tomato, blue cheese.', TRUE,
 310, 55, 4.5, 0.1, 400, 80, 1.5, 80, 12.0, 5, 25, 1.5, 170, 15, 0.05),

-- Caesar Salad: 750 cal per serving (~380g). Per 100g: 197 cal, 6.6P, 7.9C, 15.8F
('cf_caesar_salad', 'Cheesecake Factory Caesar Salad', 197, 6.6, 7.9, 15.8,
 1.6, 1.3, 380, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory caesar salad', 'cf caesar salad'],
 'american', 'Cheesecake Factory', 1, '197 cal/100g. Per serving (~380g): 750 cal. Romaine, parmesan, croutons, Caesar dressing.', TRUE,
 340, 20, 4.2, 0.1, 250, 120, 1.5, 100, 8.0, 0, 18, 1.0, 130, 8, 0.04),

-- Fried Mac & Cheese Balls: 1020 cal per serving (~330g). Per 100g: 309 cal, 9.1P, 27.3C, 18.2F
('cf_fried_mac_cheese_balls', 'Cheesecake Factory Fried Mac & Cheese Balls', 309, 9.1, 27.3, 18.2,
 0.9, 1.8, 330, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory fried mac and cheese', 'cf mac cheese balls', 'fried macaroni and cheese balls'],
 'american', 'Cheesecake Factory', 1, '309 cal/100g. Per serving (~330g): 1020 cal. Crispy fried macaroni and cheese, marinara sauce.', TRUE,
 420, 45, 8.5, 0.3, 180, 150, 1.5, 40, 2.0, 0, 18, 1.5, 160, 8, 0.02),

-- Chicken Pot Stickers: 780 cal per serving (~300g). Per 100g: 260 cal, 10.0P, 25.0C, 13.0F
('cf_chicken_pot_stickers', 'Cheesecake Factory Chicken Pot Stickers', 260, 10.0, 25.0, 13.0,
 1.3, 3.0, 300, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory chicken pot stickers', 'cf pot stickers', 'cheesecake factory dumplings'],
 'american', 'Cheesecake Factory', 1, '260 cal/100g. Per serving (~300g): 780 cal. Pan-fried chicken dumplings, soy-ginger sauce.', TRUE,
 460, 30, 3.5, 0.1, 220, 25, 1.5, 15, 3.0, 0, 15, 1.0, 100, 10, 0.03),

-- Four Cheese Pasta: 1370 cal per serving (~460g). Per 100g: 298 cal, 10.0P, 24.3C, 17.4F
('cf_four_cheese_pasta', 'Cheesecake Factory Four Cheese Pasta', 298, 10.0, 24.3, 17.4,
 1.3, 2.8, 460, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory four cheese pasta', 'cf four cheese pasta'],
 'american', 'Cheesecake Factory', 1, '298 cal/100g. Per serving (~460g): 1370 cal. Penne, ricotta, mozzarella, Romano, Parmesan, marinara cream sauce.', TRUE,
 360, 55, 9.0, 0.2, 200, 180, 1.8, 60, 4.0, 0, 22, 1.5, 200, 10, 0.03),

-- Spicy Cashew Chicken: 1390 cal per serving (~480g). Per 100g: 290 cal, 13.5P, 22.9C, 15.6F
('cf_spicy_cashew_chicken', 'Cheesecake Factory Spicy Cashew Chicken', 290, 13.5, 22.9, 15.6,
 1.5, 6.0, 480, NULL,
 'cheesecake_factory', ARRAY['cheesecake factory spicy cashew chicken', 'cf cashew chicken'],
 'american', 'Cheesecake Factory', 1, '290 cal/100g. Per serving (~480g): 1390 cal. Crispy chicken, cashews, scallions, peppers, spicy sauce, rice.', TRUE,
 400, 40, 3.5, 0.1, 350, 35, 2.0, 30, 10.0, 0, 40, 1.8, 180, 14, 0.04),

-- ==========================================
-- WAFFLE HOUSE (Expand)
-- ==========================================

-- Waffle (plain): 410 cal per waffle (~150g). Per 100g: 273 cal, 7.3P, 32.0C, 12.7F
('wh_waffle_plain', 'Waffle House Waffle (Plain)', 273, 7.3, 32.0, 12.7,
 0.7, 5.3, 150, 150,
 'waffle_house', ARRAY['waffle house waffle', 'waffle house plain waffle', 'wh waffle'],
 'breakfast', 'Waffle House', 1, '273 cal/100g. Per waffle (~150g): 410 cal. Classic waffle, butter.', TRUE,
 370, 40, 5.3, 0.7, 80, 80, 2.0, 30, 0.0, 0, 12, 0.6, 100, 10, 0.02),

-- Pecan Waffle: 480 cal per waffle (~160g). Per 100g: 300 cal, 7.5P, 30.0C, 16.9F
('wh_pecan_waffle', 'Waffle House Pecan Waffle', 300, 7.5, 30.0, 16.9,
 1.3, 5.6, 160, 160,
 'waffle_house', ARRAY['waffle house pecan waffle', 'wh pecan waffle'],
 'breakfast', 'Waffle House', 1, '300 cal/100g. Per waffle (~160g): 480 cal. Waffle with toasted pecans.', TRUE,
 350, 40, 5.0, 0.6, 110, 75, 2.0, 25, 0.0, 0, 20, 1.0, 110, 10, 0.1),

-- Chocolate Chip Waffle: 490 cal per waffle (~160g). Per 100g: 306 cal, 6.9P, 37.5C, 15.0F
('wh_chocolate_chip_waffle', 'Waffle House Chocolate Chip Waffle', 306, 6.9, 37.5, 15.0,
 1.3, 15.0, 160, 160,
 'waffle_house', ARRAY['waffle house chocolate chip waffle', 'wh chocolate chip waffle'],
 'breakfast', 'Waffle House', 1, '306 cal/100g. Per waffle (~160g): 490 cal. Waffle with chocolate chips.', TRUE,
 340, 38, 6.3, 0.5, 100, 70, 2.5, 25, 0.0, 0, 18, 0.8, 95, 8, 0.02),

-- Hash Browns (plain/scattered): 205 cal per serving (~140g). Per 100g: 146 cal, 2.1P, 17.1C, 7.9F
('wh_hash_browns_plain', 'Waffle House Hash Browns (Scattered)', 146, 2.1, 17.1, 7.9,
 1.4, 0.4, 140, NULL,
 'waffle_house', ARRAY['waffle house hash browns', 'waffle house hashbrowns', 'wh hash browns scattered', 'waffle house scattered'],
 'breakfast', 'Waffle House', 1, '146 cal/100g. Per serving (~140g): 205 cal. Crispy shredded potatoes on the grill.', TRUE,
 180, 0, 1.5, 0.0, 350, 10, 0.5, 0, 8.0, 0, 18, 0.3, 40, 1, 0.01),

-- Hash Browns Smothered (onions): 240 cal per serving (~160g). Per 100g: 150 cal, 2.5P, 17.5C, 7.8F
('wh_hash_browns_smothered', 'Waffle House Hash Browns Smothered', 150, 2.5, 17.5, 7.8,
 1.6, 1.5, 160, NULL,
 'waffle_house', ARRAY['waffle house hash browns smothered', 'wh hashbrowns smothered', 'hash browns with onions'],
 'breakfast', 'Waffle House', 1, '150 cal/100g. Per serving (~160g): 240 cal. Hash browns with sauteed onions.', TRUE,
 200, 0, 1.5, 0.0, 360, 15, 0.6, 0, 6.0, 0, 16, 0.3, 42, 1, 0.01),

-- Hash Browns Covered (cheese): 290 cal per serving (~170g). Per 100g: 171 cal, 5.3P, 15.3C, 9.4F
('wh_hash_browns_covered', 'Waffle House Hash Browns Covered', 171, 5.3, 15.3, 9.4,
 1.2, 0.6, 170, NULL,
 'waffle_house', ARRAY['waffle house hash browns covered', 'wh hashbrowns covered', 'hash browns with cheese'],
 'breakfast', 'Waffle House', 1, '171 cal/100g. Per serving (~170g): 290 cal. Hash browns topped with melted cheese.', TRUE,
 280, 12, 4.1, 0.0, 330, 80, 0.6, 20, 6.0, 0, 15, 0.6, 70, 2, 0.01),

-- Hash Browns Chunked (ham): 270 cal per serving (~170g). Per 100g: 159 cal, 6.5P, 14.7C, 8.2F
('wh_hash_browns_chunked', 'Waffle House Hash Browns Chunked', 159, 6.5, 14.7, 8.2,
 1.2, 0.5, 170, NULL,
 'waffle_house', ARRAY['waffle house hash browns chunked', 'wh hashbrowns chunked', 'hash browns with ham'],
 'breakfast', 'Waffle House', 1, '159 cal/100g. Per serving (~170g): 270 cal. Hash browns with diced ham.', TRUE,
 350, 15, 2.5, 0.0, 340, 12, 0.8, 0, 6.0, 0, 15, 0.8, 65, 3, 0.01),

-- All-Star Special: 720 cal per serving (~380g). Per 100g: 189 cal, 10.5P, 13.4C, 10.5F
('wh_all_star_special', 'Waffle House All-Star Special', 189, 10.5, 13.4, 10.5,
 0.8, 2.6, 380, NULL,
 'waffle_house', ARRAY['waffle house all star special', 'wh all star', 'all-star breakfast'],
 'breakfast', 'Waffle House', 1, '189 cal/100g. Per serving (~380g): 720 cal. Waffle, 2 eggs, bacon or sausage, hash browns, toast.', TRUE,
 520, 180, 3.7, 0.5, 280, 60, 2.5, 60, 2.0, 5, 20, 2.0, 180, 20, 0.05),

-- Grilled Chicken Sandwich: 420 cal per sandwich (~240g). Per 100g: 175 cal, 14.6P, 14.2C, 7.1F
('wh_grilled_chicken_sandwich', 'Waffle House Grilled Chicken Sandwich', 175, 14.6, 14.2, 7.1,
 0.8, 2.0, 240, NULL,
 'waffle_house', ARRAY['waffle house grilled chicken sandwich', 'wh grilled chicken'],
 'breakfast', 'Waffle House', 1, '175 cal/100g. Per sandwich (~240g): 420 cal. Grilled chicken breast, lettuce, tomato, bun.', TRUE,
 380, 45, 1.8, 0.0, 300, 30, 1.5, 20, 4.0, 0, 25, 1.2, 160, 18, 0.03),

-- Texas Bacon Cheese Melt: 560 cal per sandwich (~250g). Per 100g: 224 cal, 12.0P, 16.0C, 13.2F
('wh_texas_bacon_cheese_melt', 'Waffle House Texas Bacon Cheese Melt', 224, 12.0, 16.0, 13.2,
 0.8, 2.0, 250, NULL,
 'waffle_house', ARRAY['waffle house texas bacon cheese melt', 'wh texas melt', 'texas bacon melt'],
 'breakfast', 'Waffle House', 1, '224 cal/100g. Per sandwich (~250g): 560 cal. Bacon, cheese, Texas toast.', TRUE,
 480, 50, 5.6, 0.3, 240, 100, 2.0, 30, 1.0, 0, 18, 2.0, 160, 12, 0.03),

-- Sausage Egg & Cheese Biscuit: 540 cal per biscuit (~200g). Per 100g: 270 cal, 10.5P, 19.5C, 16.5F
('wh_sausage_egg_cheese_biscuit', 'Waffle House Sausage Egg & Cheese Biscuit', 270, 10.5, 19.5, 16.5,
 0.5, 2.0, 200, 200,
 'waffle_house', ARRAY['waffle house sausage egg cheese biscuit', 'wh sausage biscuit'],
 'breakfast', 'Waffle House', 1, '270 cal/100g. Per biscuit (~200g): 540 cal. Sausage patty, egg, American cheese, buttermilk biscuit.', TRUE,
 580, 160, 7.0, 0.3, 180, 80, 2.0, 50, 0.0, 5, 14, 1.5, 160, 15, 0.03),

-- Cheese ''n Eggs: 380 cal per plate (~200g). Per 100g: 190 cal, 13.0P, 1.5C, 15.0F
('wh_cheese_n_eggs', 'Waffle House Cheese ''n Eggs', 190, 13.0, 1.5, 15.0,
 0.0, 0.5, 200, NULL,
 'waffle_house', ARRAY['waffle house cheese n eggs', 'wh cheese eggs', 'cheese and eggs waffle house'],
 'breakfast', 'Waffle House', 1, '190 cal/100g. Per plate (~200g): 380 cal. 2 eggs cooked to order with American cheese.', TRUE,
 400, 370, 6.5, 0.2, 150, 120, 1.5, 100, 0.0, 20, 12, 1.5, 180, 20, 0.04),

-- T-Bone Steak: 510 cal per steak (~280g). Per 100g: 182 cal, 23.2P, 0.0C, 9.6F
('wh_tbone_steak', 'Waffle House T-Bone Steak', 182, 23.2, 0.0, 9.6,
 0.0, 0.0, 280, 280,
 'waffle_house', ARRAY['waffle house t-bone steak', 'wh tbone', 'waffle house steak'],
 'breakfast', 'Waffle House', 1, '182 cal/100g. Per steak (~280g): 510 cal. Grilled T-bone steak.', TRUE,
 350, 75, 3.9, 0.2, 350, 15, 3.0, 0, 0.0, 0, 22, 5.0, 200, 25, 0.04),

-- Pork Chop: 450 cal per serving (~250g). Per 100g: 180 cal, 20.0P, 4.0C, 9.2F
('wh_pork_chop', 'Waffle House Pork Chop', 180, 20.0, 4.0, 9.2,
 0.0, 0.0, 250, 250,
 'waffle_house', ARRAY['waffle house pork chop', 'wh pork chop'],
 'breakfast', 'Waffle House', 1, '180 cal/100g. Per serving (~250g): 450 cal. Grilled bone-in pork chop.', TRUE,
 420, 65, 3.2, 0.0, 380, 15, 1.5, 0, 0.5, 0, 22, 3.0, 200, 20, 0.03),

-- Grits: 130 cal per serving (~200g). Per 100g: 65 cal, 1.5P, 12.5C, 1.0F
('wh_grits', 'Waffle House Grits', 65, 1.5, 12.5, 1.0,
 0.5, 0.2, 200, NULL,
 'waffle_house', ARRAY['waffle house grits', 'wh grits', 'waffle house regular grits'],
 'breakfast', 'Waffle House', 1, '65 cal/100g. Per serving (~200g): 130 cal. Creamy Southern-style grits with butter.', TRUE,
 200, 0, 0.3, 0.0, 30, 5, 0.8, 5, 0.0, 0, 8, 0.2, 20, 3, 0.0),

-- ==========================================
-- CRACKER BARREL (Expand)
-- ==========================================

-- Chicken n Dumplings: 450 cal per serving (~340g). Per 100g: 132 cal, 11.8P, 10.6C, 4.7F
('cb_chicken_n_dumplings', 'Cracker Barrel Chicken n'' Dumplings', 132, 11.8, 10.6, 4.7,
 0.6, 1.2, 340, NULL,
 'cracker_barrel', ARRAY['cracker barrel chicken and dumplings', 'cracker barrel chicken n dumplins', 'cb chicken dumplings'],
 'american', 'Cracker Barrel', 1, '132 cal/100g. Per serving (~340g): 450 cal, 40P. Southern-style chicken and dumplings.', TRUE,
 494, 40, 1.5, 0.1, 280, 25, 1.5, 20, 2.0, 0, 18, 1.5, 160, 15, 0.04),

-- Country Fried Steak: 600 cal per serving (~280g). Per 100g: 214 cal, 10.7P, 14.3C, 12.5F
('cb_country_fried_steak', 'Cracker Barrel Country Fried Steak', 214, 10.7, 14.3, 12.5,
 0.7, 1.0, 280, 280,
 'cracker_barrel', ARRAY['cracker barrel country fried steak', 'cb country fried steak', 'chicken fried steak cracker barrel'],
 'american', 'Cracker Barrel', 1, '214 cal/100g. Per serving (~280g): 600 cal. Breaded beef steak, country gravy.', TRUE,
 520, 50, 4.3, 0.3, 260, 30, 2.5, 10, 0.0, 0, 18, 3.0, 150, 14, 0.03),

-- Meatloaf: 580 cal per serving (~300g). Per 100g: 193 cal, 11.0P, 10.0C, 12.3F
('cb_meatloaf', 'Cracker Barrel Meatloaf', 193, 11.0, 10.0, 12.3,
 0.7, 3.3, 300, 300,
 'cracker_barrel', ARRAY['cracker barrel meatloaf', 'cb meatloaf', 'cracker barrel meat loaf dinner'],
 'american', 'Cracker Barrel', 1, '193 cal/100g. Per serving (~300g): 580 cal. Homestyle meatloaf with tomato glaze.', TRUE,
 420, 55, 5.0, 0.2, 310, 30, 2.5, 15, 3.0, 0, 18, 3.5, 140, 12, 0.04),

-- Sunday Homestyle Chicken: 640 cal per serving (~300g). Per 100g: 213 cal, 15.0P, 11.7C, 11.7F
('cb_sunday_homestyle_chicken', 'Cracker Barrel Sunday Homestyle Chicken', 213, 15.0, 11.7, 11.7,
 0.3, 0.5, 300, 300,
 'cracker_barrel', ARRAY['cracker barrel sunday chicken', 'cb homestyle chicken', 'sunday homestyle chicken cracker barrel'],
 'american', 'Cracker Barrel', 1, '213 cal/100g. Per serving (~300g): 640 cal. Breaded fried chicken breast, country gravy.', TRUE,
 460, 60, 3.7, 0.2, 280, 25, 1.5, 10, 0.0, 0, 20, 1.5, 180, 18, 0.03),

-- Pancakes (3 stack): 550 cal per serving (~240g). Per 100g: 229 cal, 5.4P, 33.3C, 8.3F
('cb_pancakes', 'Cracker Barrel Buttermilk Pancakes', 229, 5.4, 33.3, 8.3,
 0.8, 8.3, 240, 80,
 'cracker_barrel', ARRAY['cracker barrel pancakes', 'cb pancakes', 'cracker barrel buttermilk pancakes'],
 'american', 'Cracker Barrel', 1, '229 cal/100g. Per 3 pancakes (~240g): 550 cal. Fluffy buttermilk pancakes with butter and syrup.', TRUE,
 480, 35, 2.5, 0.1, 120, 80, 2.0, 20, 0.0, 5, 12, 0.6, 120, 10, 0.02),

-- French Toast: 520 cal per serving (~220g). Per 100g: 236 cal, 7.3P, 30.0C, 10.0F
('cb_french_toast', 'Cracker Barrel Sourdough French Toast', 236, 7.3, 30.0, 10.0,
 0.9, 10.0, 220, NULL,
 'cracker_barrel', ARRAY['cracker barrel french toast', 'cb french toast'],
 'american', 'Cracker Barrel', 1, '236 cal/100g. Per serving (~220g): 520 cal. Thick-sliced sourdough bread, egg batter, powdered sugar.', TRUE,
 380, 80, 3.2, 0.1, 140, 60, 2.0, 40, 0.0, 5, 14, 0.8, 110, 12, 0.03),

-- Country Ham: 280 cal per serving (~140g). Per 100g: 200 cal, 22.1P, 1.4C, 11.4F
('cb_country_ham', 'Cracker Barrel Country Ham', 200, 22.1, 1.4, 11.4,
 0.0, 0.7, 140, 140,
 'cracker_barrel', ARRAY['cracker barrel country ham', 'cb country ham'],
 'american', 'Cracker Barrel', 1, '200 cal/100g. Per serving (~140g): 280 cal. Thick-sliced cured country ham.', TRUE,
 900, 55, 4.3, 0.0, 300, 10, 1.2, 0, 0.0, 0, 15, 2.5, 180, 18, 0.02),

-- Biscuits & Gravy: 420 cal per serving (~220g). Per 100g: 191 cal, 5.5P, 19.1C, 10.5F
('cb_biscuits_and_gravy', 'Cracker Barrel Biscuits & Gravy', 191, 5.5, 19.1, 10.5,
 0.5, 2.3, 220, NULL,
 'cracker_barrel', ARRAY['cracker barrel biscuits and gravy', 'cb biscuits gravy', 'biscuits n gravy cracker barrel'],
 'american', 'Cracker Barrel', 1, '191 cal/100g. Per serving (~220g): 420 cal. Buttermilk biscuits, sausage gravy.', TRUE,
 580, 20, 4.1, 0.2, 120, 40, 2.0, 5, 0.0, 0, 10, 1.0, 80, 8, 0.02),

-- Turnip Greens: 60 cal per side (~140g). Per 100g: 43 cal, 2.9P, 3.6C, 1.4F
('cb_turnip_greens', 'Cracker Barrel Turnip Greens', 43, 2.9, 3.6, 1.4,
 2.1, 0.7, 140, NULL,
 'cracker_barrel', ARRAY['cracker barrel turnip greens', 'cb turnip greens'],
 'american', 'Cracker Barrel', 1, '43 cal/100g. Per side (~140g): 60 cal. Southern-style turnip greens.', TRUE,
 350, 5, 0.5, 0.0, 200, 80, 1.5, 200, 20.0, 0, 20, 0.3, 30, 1, 0.05),

-- Mac & Cheese: 250 cal per side (~150g). Per 100g: 167 cal, 6.7P, 14.7C, 9.3F
('cb_mac_and_cheese', 'Cracker Barrel Mac & Cheese', 167, 6.7, 14.7, 9.3,
 0.7, 2.0, 150, NULL,
 'cracker_barrel', ARRAY['cracker barrel mac and cheese', 'cb mac cheese', 'cracker barrel macaroni and cheese'],
 'american', 'Cracker Barrel', 1, '167 cal/100g. Per side (~150g): 250 cal. Creamy macaroni and cheese.', TRUE,
 420, 25, 5.3, 0.1, 100, 120, 0.8, 30, 0.0, 0, 12, 0.8, 120, 6, 0.02),

-- Fried Okra: 200 cal per side (~120g). Per 100g: 167 cal, 3.3P, 18.3C, 9.2F
('cb_fried_okra', 'Cracker Barrel Fried Okra', 167, 3.3, 18.3, 9.2,
 2.5, 1.7, 120, NULL,
 'cracker_barrel', ARRAY['cracker barrel fried okra', 'cb fried okra'],
 'american', 'Cracker Barrel', 1, '167 cal/100g. Per side (~120g): 200 cal. Breaded and fried okra.', TRUE,
 280, 5, 1.5, 0.1, 200, 40, 1.0, 15, 8.0, 0, 20, 0.4, 45, 2, 0.02),

-- Peach Cobbler: 430 cal per serving (~200g). Per 100g: 215 cal, 2.0P, 35.0C, 8.0F
('cb_peach_cobbler', 'Cracker Barrel Peach Cobbler', 215, 2.0, 35.0, 8.0,
 1.0, 22.0, 200, NULL,
 'cracker_barrel', ARRAY['cracker barrel peach cobbler', 'cb peach cobbler', 'cracker barrel cobbler'],
 'american', 'Cracker Barrel', 1, '215 cal/100g. Per serving (~200g): 430 cal. Warm peach cobbler with biscuit crust.', TRUE,
 180, 5, 3.5, 0.1, 130, 20, 0.8, 30, 5.0, 0, 8, 0.2, 25, 1, 0.01),

-- Country Boy Breakfast: 820 cal per serving (~400g). Per 100g: 205 cal, 10.0P, 12.5C, 12.5F
('cb_country_boy_breakfast', 'Cracker Barrel Country Boy Breakfast', 205, 10.0, 12.5, 12.5,
 0.5, 2.5, 400, NULL,
 'cracker_barrel', ARRAY['cracker barrel country boy breakfast', 'cb country boy'],
 'american', 'Cracker Barrel', 1, '205 cal/100g. Per serving (~400g): 820 cal. 2 eggs, bacon, sausage, hash brown casserole, biscuits.', TRUE,
 600, 200, 5.0, 0.3, 280, 60, 2.5, 50, 2.0, 5, 18, 2.0, 200, 20, 0.04),

-- Sunrise Sampler: 740 cal per serving (~380g). Per 100g: 195 cal, 10.5P, 13.2C, 11.1F
('cb_sunrise_sampler', 'Cracker Barrel Sunrise Sampler', 195, 10.5, 13.2, 11.1,
 0.5, 3.0, 380, NULL,
 'cracker_barrel', ARRAY['cracker barrel sunrise sampler', 'cb sunrise sampler'],
 'american', 'Cracker Barrel', 1, '195 cal/100g. Per serving (~380g): 740 cal. Eggs, bacon, sausage, hash browns, pancakes, fruit.', TRUE,
 560, 180, 4.2, 0.3, 260, 55, 2.5, 40, 5.0, 5, 16, 1.8, 180, 18, 0.04),

-- Grilled Chicken Tenderloins: 260 cal per serving (~200g). Per 100g: 130 cal, 22.0P, 2.0C, 3.5F
('cb_grilled_chicken_tenderloins', 'Cracker Barrel Grilled Chicken Tenderloins', 130, 22.0, 2.0, 3.5,
 0.0, 0.5, 200, NULL,
 'cracker_barrel', ARRAY['cracker barrel grilled chicken tenderloins', 'cb grilled chicken'],
 'american', 'Cracker Barrel', 1, '130 cal/100g. Per serving (~200g): 260 cal. Grilled seasoned chicken breast tenderloins.', TRUE,
 380, 60, 0.8, 0.0, 350, 10, 0.8, 5, 0.0, 0, 25, 1.0, 200, 22, 0.03),

-- Pot Roast Supper: 620 cal per serving (~350g). Per 100g: 177 cal, 14.3P, 8.6C, 9.7F
('cb_pot_roast_supper', 'Cracker Barrel Pot Roast Supper', 177, 14.3, 8.6, 9.7,
 0.9, 1.7, 350, NULL,
 'cracker_barrel', ARRAY['cracker barrel pot roast', 'cb pot roast supper'],
 'american', 'Cracker Barrel', 1, '177 cal/100g. Per serving (~350g): 620 cal. Slow-cooked beef pot roast, carrots, potatoes.', TRUE,
 400, 50, 3.7, 0.1, 380, 20, 2.5, 150, 5.0, 0, 22, 4.0, 180, 15, 0.04),

-- Campfire Chicken: 530 cal per serving (~320g). Per 100g: 166 cal, 13.1P, 6.3C, 10.0F
('cb_campfire_chicken', 'Cracker Barrel Campfire Chicken', 166, 13.1, 6.3, 10.0,
 0.6, 2.5, 320, NULL,
 'cracker_barrel', ARRAY['cracker barrel campfire chicken', 'cb campfire chicken'],
 'american', 'Cracker Barrel', 1, '166 cal/100g. Per serving (~320g): 530 cal. Grilled chicken breast, cheese, bacon, BBQ sauce.', TRUE,
 480, 55, 4.4, 0.1, 300, 80, 1.5, 20, 3.0, 0, 22, 2.0, 200, 18, 0.03),

-- Banana Pudding: 350 cal per serving (~180g). Per 100g: 194 cal, 3.3P, 28.9C, 7.8F
('cb_banana_pudding', 'Cracker Barrel Banana Pudding', 194, 3.3, 28.9, 7.8,
 0.6, 18.0, 180, NULL,
 'cracker_barrel', ARRAY['cracker barrel banana pudding', 'cb banana pudding'],
 'american', 'Cracker Barrel', 1, '194 cal/100g. Per serving (~180g): 350 cal. Vanilla pudding, bananas, vanilla wafers.', TRUE,
 160, 20, 4.4, 0.0, 200, 60, 0.5, 20, 3.0, 5, 12, 0.3, 80, 3, 0.02),

-- Hashbrown Casserole: 250 cal per side (~150g). Per 100g: 167 cal, 4.0P, 12.0C, 11.3F
('cb_hashbrown_casserole', 'Cracker Barrel Hashbrown Casserole', 167, 4.0, 12.0, 11.3,
 0.7, 1.3, 150, NULL,
 'cracker_barrel', ARRAY['cracker barrel hashbrown casserole', 'cb hashbrown casserole'],
 'american', 'Cracker Barrel', 1, '167 cal/100g. Per side (~150g): 250 cal. Shredded potatoes, cheese, sour cream, baked.', TRUE,
 380, 15, 5.3, 0.1, 200, 80, 0.5, 25, 3.0, 0, 12, 0.6, 80, 3, 0.01),

-- Chocolate Coca-Cola Cake: 480 cal per slice (~160g). Per 100g: 300 cal, 3.1P, 43.8C, 13.1F
('cb_chocolate_coca_cola_cake', 'Cracker Barrel Chocolate Coca-Cola Cake', 300, 3.1, 43.8, 13.1,
 1.3, 31.3, 160, NULL,
 'cracker_barrel', ARRAY['cracker barrel coca cola cake', 'cb chocolate cake', 'cracker barrel chocolate coca cola cake'],
 'american', 'Cracker Barrel', 1, '300 cal/100g. Per slice (~160g): 480 cal. Double chocolate cake made with Coca-Cola, pecan frosting.', TRUE,
 280, 30, 5.6, 0.2, 180, 30, 2.0, 10, 0.0, 0, 20, 0.8, 80, 5, 0.02),

-- ==========================================
-- BUFFALO WILD WINGS (Expand)
-- ==========================================

-- Traditional Wings Mango Habanero (6pc): 610 cal per 6 wings (~270g). Per 100g: 226 cal, 17.8P, 7.4C, 14.1F
('bww_traditional_mango_habanero', 'BWW Traditional Wings Mango Habanero (6pc)', 226, 17.8, 7.4, 14.1,
 0.4, 4.4, 270, 45,
 'bww', ARRAY['buffalo wild wings mango habanero', 'bww mango habanero wings', 'mango habanero traditional wings'],
 'wings', 'Buffalo Wild Wings', 1, '226 cal/100g. Per 6 wings (~270g): 610 cal. Bone-in wings tossed in sweet & spicy mango habanero sauce.', TRUE,
 630, 55, 3.3, 0.1, 250, 20, 1.5, 30, 8.0, 0, 18, 2.0, 160, 15, 0.04),

-- Traditional Wings Parmesan Garlic (6pc): 640 cal per 6 wings (~270g). Per 100g: 237 cal, 19.3P, 1.5C, 17.0F
('bww_traditional_parmesan_garlic', 'BWW Traditional Wings Parmesan Garlic (6pc)', 237, 19.3, 1.5, 17.0,
 0.0, 0.7, 270, 45,
 'bww', ARRAY['buffalo wild wings parmesan garlic', 'bww parmesan garlic wings'],
 'wings', 'Buffalo Wild Wings', 1, '237 cal/100g. Per 6 wings (~270g): 640 cal. Bone-in wings tossed in parmesan garlic sauce.', TRUE,
 580, 60, 4.4, 0.1, 240, 60, 1.2, 10, 1.0, 0, 16, 2.0, 170, 14, 0.04),

-- Traditional Wings Nashville Hot (6pc): 590 cal per 6 wings (~270g). Per 100g: 219 cal, 18.5P, 3.0C, 14.8F
('bww_traditional_nashville_hot', 'BWW Traditional Wings Nashville Hot (6pc)', 219, 18.5, 3.0, 14.8,
 0.4, 1.1, 270, 45,
 'bww', ARRAY['buffalo wild wings nashville hot', 'bww nashville hot wings'],
 'wings', 'Buffalo Wild Wings', 1, '219 cal/100g. Per 6 wings (~270g): 590 cal. Bone-in wings in Nashville-style hot sauce.', TRUE,
 620, 55, 3.3, 0.1, 240, 18, 1.2, 30, 2.0, 0, 16, 2.0, 160, 14, 0.04),

-- Traditional Wings Blazin (6pc): 570 cal per 6 wings (~270g). Per 100g: 211 cal, 18.5P, 2.2C, 14.1F
('bww_traditional_blazin', 'BWW Traditional Wings Blazin'' (6pc)', 211, 18.5, 2.2, 14.1,
 0.4, 0.7, 270, 45,
 'bww', ARRAY['buffalo wild wings blazin', 'bww blazin wings', 'blazin challenge wings'],
 'wings', 'Buffalo Wild Wings', 1, '211 cal/100g. Per 6 wings (~270g): 570 cal. Bone-in wings in extra-hot Blazin sauce.', TRUE,
 650, 55, 3.0, 0.1, 240, 15, 1.2, 40, 5.0, 0, 16, 2.0, 160, 14, 0.04),

-- Traditional Wings Asian Zing (6pc): 620 cal per 6 wings (~270g). Per 100g: 230 cal, 17.4P, 8.9C, 14.1F
('bww_traditional_asian_zing', 'BWW Traditional Wings Asian Zing (6pc)', 230, 17.4, 8.9, 14.1,
 0.4, 5.9, 270, 45,
 'bww', ARRAY['buffalo wild wings asian zing', 'bww asian zing wings'],
 'wings', 'Buffalo Wild Wings', 1, '230 cal/100g. Per 6 wings (~270g): 620 cal. Bone-in wings in sweet chili Asian Zing sauce.', TRUE,
 600, 55, 3.0, 0.1, 240, 18, 1.2, 15, 3.0, 0, 16, 2.0, 160, 14, 0.04),

-- Traditional Wings Honey BBQ (6pc): 630 cal per 6 wings (~270g). Per 100g: 233 cal, 17.0P, 10.4C, 13.7F
('bww_traditional_honey_bbq', 'BWW Traditional Wings Honey BBQ (6pc)', 233, 17.0, 10.4, 13.7,
 0.4, 7.4, 270, 45,
 'bww', ARRAY['buffalo wild wings honey bbq', 'bww honey bbq wings'],
 'wings', 'Buffalo Wild Wings', 1, '233 cal/100g. Per 6 wings (~270g): 630 cal. Bone-in wings in honey BBQ sauce.', TRUE,
 580, 55, 3.0, 0.1, 250, 18, 1.2, 10, 2.0, 0, 16, 2.0, 160, 14, 0.04),

-- Traditional Wings Lemon Pepper (6pc): 610 cal per 6 wings (~270g). Per 100g: 226 cal, 19.6P, 0.7C, 15.9F
('bww_traditional_lemon_pepper', 'BWW Traditional Wings Lemon Pepper (6pc)', 226, 19.6, 0.7, 15.9,
 0.0, 0.0, 270, 45,
 'bww', ARRAY['buffalo wild wings lemon pepper', 'bww lemon pepper wings'],
 'wings', 'Buffalo Wild Wings', 1, '226 cal/100g. Per 6 wings (~270g): 610 cal. Bone-in wings with lemon pepper dry rub.', TRUE,
 520, 55, 4.1, 0.1, 250, 18, 1.2, 5, 3.0, 0, 16, 2.0, 165, 14, 0.04),

-- Traditional Wings Medium (6pc): 560 cal per 6 wings (~270g). Per 100g: 207 cal, 18.5P, 1.5C, 14.1F
('bww_traditional_medium', 'BWW Traditional Wings Medium (6pc)', 207, 18.5, 1.5, 14.1,
 0.0, 0.4, 270, 45,
 'bww', ARRAY['buffalo wild wings medium', 'bww medium wings'],
 'wings', 'Buffalo Wild Wings', 1, '207 cal/100g. Per 6 wings (~270g): 560 cal. Bone-in wings in medium buffalo sauce.', TRUE,
 620, 55, 3.0, 0.1, 240, 15, 1.2, 25, 1.0, 0, 16, 2.0, 160, 14, 0.04),

-- Traditional Wings Mild (6pc): 550 cal per 6 wings (~270g). Per 100g: 204 cal, 18.5P, 1.1C, 13.7F
('bww_traditional_mild', 'BWW Traditional Wings Mild (6pc)', 204, 18.5, 1.1, 13.7,
 0.0, 0.4, 270, 45,
 'bww', ARRAY['buffalo wild wings mild', 'bww mild wings'],
 'wings', 'Buffalo Wild Wings', 1, '204 cal/100g. Per 6 wings (~270g): 550 cal. Bone-in wings in mild buffalo sauce.', TRUE,
 600, 55, 3.0, 0.1, 240, 15, 1.2, 20, 1.0, 0, 16, 2.0, 160, 14, 0.04),

-- Boneless Wings Plain (8pc): 360 cal per 8 boneless (~200g). Per 100g: 180 cal, 14.5P, 10.0C, 9.0F
('bww_boneless_plain', 'BWW Boneless Wings Plain (8pc)', 180, 14.5, 10.0, 9.0,
 0.5, 0.5, 200, 25,
 'bww', ARRAY['buffalo wild wings boneless plain', 'bww boneless wings', 'boneless wings plain bww'],
 'wings', 'Buffalo Wild Wings', 1, '180 cal/100g. Per 8 boneless (~200g): 360 cal. Breaded boneless chicken pieces, unsauced.', TRUE,
 630, 40, 2.5, 0.1, 200, 15, 1.0, 5, 0.0, 0, 14, 0.8, 140, 12, 0.03),

-- Boneless Wings Honey BBQ (8pc): 490 cal per 8 boneless (~220g). Per 100g: 223 cal, 13.2P, 18.2C, 10.5F
('bww_boneless_honey_bbq', 'BWW Boneless Wings Honey BBQ (8pc)', 223, 13.2, 18.2, 10.5,
 0.5, 9.1, 220, 28,
 'bww', ARRAY['buffalo wild wings boneless honey bbq', 'bww boneless honey bbq'],
 'wings', 'Buffalo Wild Wings', 1, '223 cal/100g. Per 8 boneless (~220g): 490 cal. Breaded boneless chicken tossed in honey BBQ sauce.', TRUE,
 650, 40, 3.0, 0.1, 210, 18, 1.0, 8, 2.0, 0, 14, 0.8, 140, 12, 0.03),

-- Cheese Curds: 920 cal per serving (~280g). Per 100g: 329 cal, 11.4P, 7.9C, 27.9F
('bww_cheese_curds', 'BWW Cheese Curds', 329, 11.4, 7.9, 27.9,
 0.0, 0.7, 280, NULL,
 'bww', ARRAY['buffalo wild wings cheese curds', 'bww cheese curds', 'cheddar cheese curds bww'],
 'wings', 'Buffalo Wild Wings', 1, '329 cal/100g. Per serving (~280g): 920 cal, 32P, 78F, 22C. Fried cheddar cheese curds with Southwestern ranch.', TRUE,
 743, 55, 10.7, 0.7, 200, 200, 1.0, 40, 0.0, 0, 15, 2.0, 200, 8, 0.02),

-- Mozzarella Sticks: 740 cal per serving (~250g). Per 100g: 296 cal, 12.0P, 24.0C, 17.2F
('bww_mozzarella_sticks', 'BWW Mozzarella Sticks', 296, 12.0, 24.0, 17.2,
 1.2, 2.0, 250, NULL,
 'bww', ARRAY['buffalo wild wings mozzarella sticks', 'bww mozzarella sticks', 'bww mozz sticks'],
 'wings', 'Buffalo Wild Wings', 1, '296 cal/100g. Per serving (~250g): 740 cal. Breaded mozzarella sticks with marinara sauce.', TRUE,
 580, 40, 8.0, 0.3, 150, 200, 1.5, 30, 2.0, 0, 15, 1.5, 180, 8, 0.02),

-- Street Tacos: 520 cal per serving (~200g). Per 100g: 260 cal, 12.0P, 18.0C, 15.5F
('bww_street_tacos', 'BWW Street Tacos', 260, 12.0, 18.0, 15.5,
 2.0, 2.0, 200, NULL,
 'bww', ARRAY['buffalo wild wings street tacos', 'bww street tacos'],
 'wings', 'Buffalo Wild Wings', 1, '260 cal/100g. Per serving (~200g): 520 cal. Mini tacos with protein, cabbage slaw, pico.', TRUE,
 480, 35, 5.0, 0.1, 250, 50, 1.5, 20, 5.0, 0, 18, 1.5, 140, 10, 0.03),

-- Loaded Nachos: 1340 cal per serving (~500g). Per 100g: 268 cal, 9.0P, 18.0C, 17.6F
('bww_loaded_nachos', 'BWW Loaded Nachos', 268, 9.0, 18.0, 17.6,
 2.0, 2.0, 500, NULL,
 'bww', ARRAY['buffalo wild wings loaded nachos', 'bww nachos'],
 'wings', 'Buffalo Wild Wings', 1, '268 cal/100g. Per serving (~500g): 1340 cal. Tortilla chips, queso, chicken, jalapeños, pico, sour cream.', TRUE,
 500, 40, 7.0, 0.3, 300, 150, 2.0, 40, 5.0, 0, 25, 2.0, 180, 10, 0.04),

-- Chicken Quesadilla: 870 cal per serving (~320g). Per 100g: 272 cal, 14.1P, 15.6C, 17.2F
('bww_chicken_quesadilla', 'BWW Chicken Quesadilla', 272, 14.1, 15.6, 17.2,
 1.3, 1.6, 320, NULL,
 'bww', ARRAY['buffalo wild wings chicken quesadilla', 'bww quesadilla'],
 'wings', 'Buffalo Wild Wings', 1, '272 cal/100g. Per serving (~320g): 870 cal. Flour tortilla, grilled chicken, cheese, pico.', TRUE,
 540, 50, 8.4, 0.3, 250, 180, 2.0, 40, 3.0, 0, 22, 2.0, 200, 12, 0.03),

-- Buffalo Ranch Chicken Wrap: 780 cal per wrap (~300g). Per 100g: 260 cal, 12.7P, 16.7C, 15.7F
('bww_buffalo_ranch_wrap', 'BWW Buffalo Ranch Chicken Wrap', 260, 12.7, 16.7, 15.7,
 1.3, 2.0, 300, NULL,
 'bww', ARRAY['buffalo wild wings buffalo ranch wrap', 'bww chicken wrap', 'bww buffalo ranch wrap'],
 'wings', 'Buffalo Wild Wings', 1, '260 cal/100g. Per wrap (~300g): 780 cal. Chicken, buffalo sauce, ranch, lettuce, tomato, flour tortilla.', TRUE,
 560, 45, 5.3, 0.2, 260, 60, 2.0, 30, 4.0, 0, 20, 1.5, 170, 12, 0.03),

-- Garden Burger: 620 cal per burger (~280g). Per 100g: 221 cal, 8.9P, 21.4C, 11.4F
('bww_garden_burger', 'BWW Garden Burger', 221, 8.9, 21.4, 11.4,
 2.5, 4.3, 280, NULL,
 'bww', ARRAY['buffalo wild wings garden burger', 'bww veggie burger', 'bww garden burger'],
 'wings', 'Buffalo Wild Wings', 1, '221 cal/100g. Per burger (~280g): 620 cal. Veggie patty, lettuce, tomato, pickles, bun.', TRUE,
 480, 20, 3.6, 0.0, 350, 60, 2.5, 15, 4.0, 0, 28, 1.5, 120, 8, 0.03),

-- ==========================================
-- RED ROBIN (Expand)
-- ==========================================

-- Banzai Burger: 1061 cal per burger (~380g). Per 100g: 279 cal, 11.3P, 19.5C, 16.6F
('rr_banzai_burger', 'Red Robin Banzai Burger', 279, 11.3, 19.5, 16.6,
 0.8, 7.9, 380, NULL,
 'red_robin', ARRAY['red robin banzai burger', 'rr banzai', 'banzai burger red robin'],
 'american', 'Red Robin', 1, '279 cal/100g. Per burger (~380g): 1061 cal, 63F, 74C, 43P. Teriyaki-glazed patty, cheddar, pineapple, lettuce, tomato.', TRUE,
 526, 34, 5.3, 0.5, 350, 100, 3.0, 30, 6.0, 0, 28, 3.5, 200, 16, 0.04),

-- Royal Red Robin: 1140 cal per burger (~400g). Per 100g: 285 cal, 13.3P, 15.0C, 19.5F
('rr_royal_red_robin', 'Red Robin Royal Red Robin Burger', 285, 13.3, 15.0, 19.5,
 0.8, 3.8, 400, NULL,
 'red_robin', ARRAY['red robin royal red robin', 'rr royal burger', 'royal red robin burger'],
 'american', 'Red Robin', 1, '285 cal/100g. Per burger (~400g): 1140 cal. Beef patty, fried egg, American cheese, bacon, lettuce, tomato.', TRUE,
 540, 75, 8.0, 0.5, 350, 100, 3.5, 50, 3.0, 5, 28, 4.0, 220, 20, 0.04),

-- Whiskey River BBQ Burger: 1090 cal per burger (~380g). Per 100g: 287 cal, 12.4P, 18.4C, 18.4F
('rr_whiskey_river_bbq', 'Red Robin Whiskey River BBQ Burger', 287, 12.4, 18.4, 18.4,
 1.1, 7.9, 380, NULL,
 'red_robin', ARRAY['red robin whiskey river bbq', 'rr whiskey river', 'whiskey river bbq burger'],
 'american', 'Red Robin', 1, '287 cal/100g. Per burger (~380g): 1090 cal. Crispy onion straws, cheddar, bacon, BBQ sauce, lettuce, tomato.', TRUE,
 520, 55, 7.6, 0.5, 340, 100, 3.0, 25, 4.0, 0, 26, 3.5, 200, 16, 0.04),

-- A.1. Peppercorn Burger: 1030 cal per burger (~370g). Per 100g: 278 cal, 13.5P, 13.5C, 18.9F
('rr_a1_peppercorn_burger', 'Red Robin A.1. Peppercorn Burger', 278, 13.5, 13.5, 18.9,
 0.8, 3.5, 370, NULL,
 'red_robin', ARRAY['red robin a1 peppercorn', 'rr a1 burger', 'a1 peppercorn burger red robin'],
 'american', 'Red Robin', 1, '278 cal/100g. Per burger (~370g): 1030 cal. Peppercorn seasoning, A.1. sauce, provolone, tomato, lettuce.', TRUE,
 510, 60, 7.8, 0.5, 350, 90, 3.5, 20, 3.0, 0, 28, 4.0, 210, 18, 0.04),

-- Bottomless Steak Fries: 430 cal per serving (~200g). Per 100g: 215 cal, 3.0P, 28.0C, 10.5F
('rr_steak_fries', 'Red Robin Bottomless Steak Fries', 215, 3.0, 28.0, 10.5,
 2.5, 0.5, 200, NULL,
 'red_robin', ARRAY['red robin steak fries', 'rr bottomless fries', 'bottomless steak fries red robin'],
 'american', 'Red Robin', 1, '215 cal/100g. Per serving (~200g): 430 cal. Thick-cut seasoned steak fries, bottomless refills.', TRUE,
 350, 0, 2.0, 0.0, 400, 10, 0.8, 0, 8.0, 0, 20, 0.3, 50, 2, 0.01),

-- Onion Rings Tower: 1892 cal per tower (~550g). Per 100g: 344 cal, 4.5P, 36.4C, 20.0F
('rr_onion_rings_tower', 'Red Robin Towering Onion Rings', 344, 4.5, 36.4, 20.0,
 2.2, 5.5, 550, NULL,
 'red_robin', ARRAY['red robin onion rings tower', 'rr towering onion rings', 'red robin onion rings'],
 'american', 'Red Robin', 1, '344 cal/100g. Per tower (~550g): 1892 cal. Crispy battered onion rings, campfire sauce.', TRUE,
 500, 10, 4.0, 0.3, 250, 30, 2.0, 5, 4.0, 0, 15, 0.5, 60, 3, 0.01),

-- Tavern Double Burger: 960 cal per burger (~350g). Per 100g: 274 cal, 16.0P, 14.3C, 17.1F
('rr_tavern_double', 'Red Robin Tavern Double Burger', 274, 16.0, 14.3, 17.1,
 0.6, 3.1, 350, NULL,
 'red_robin', ARRAY['red robin tavern double', 'rr tavern burger'],
 'american', 'Red Robin', 1, '274 cal/100g. Per burger (~350g): 960 cal. Two beef patties, American cheese, pickles, special sauce.', TRUE,
 490, 70, 7.4, 0.5, 330, 90, 3.5, 20, 2.0, 0, 26, 4.0, 200, 18, 0.04),

-- Wedge Salad: 430 cal per salad (~280g). Per 100g: 154 cal, 5.0P, 5.4C, 12.9F
('rr_wedge_salad', 'Red Robin Wedge Salad', 154, 5.0, 5.4, 12.9,
 1.4, 2.9, 280, NULL,
 'red_robin', ARRAY['red robin wedge salad', 'rr wedge salad'],
 'american', 'Red Robin', 1, '154 cal/100g. Per salad (~280g): 430 cal. Iceberg wedge, bacon, tomatoes, blue cheese dressing.', TRUE,
 380, 25, 5.4, 0.1, 250, 60, 0.8, 40, 6.0, 0, 12, 0.8, 80, 4, 0.04),

-- Mac & Cheese Burger: 1050 cal per burger (~380g). Per 100g: 276 cal, 12.6P, 18.4C, 17.1F
('rr_mac_cheese_burger', 'Red Robin Mac & Cheese Burger', 276, 12.6, 18.4, 17.1,
 0.8, 3.9, 380, NULL,
 'red_robin', ARRAY['red robin mac and cheese burger', 'rr mac cheese burger'],
 'american', 'Red Robin', 1, '276 cal/100g. Per burger (~380g): 1050 cal. Beef patty topped with mac & cheese, bacon, cheese sauce.', TRUE,
 540, 60, 8.4, 0.5, 300, 130, 3.0, 30, 2.0, 0, 24, 3.0, 200, 14, 0.03),

-- Clucks & Fries: 680 cal per serving (~280g). Per 100g: 243 cal, 14.3P, 17.9C, 12.5F
('rr_clucks_and_fries', 'Red Robin Clucks & Fries', 243, 14.3, 17.9, 12.5,
 1.1, 1.1, 280, NULL,
 'red_robin', ARRAY['red robin clucks and fries', 'rr chicken tenders', 'red robin chicken tenders and fries'],
 'american', 'Red Robin', 1, '243 cal/100g. Per serving (~280g): 680 cal. Breaded chicken tenders with steak fries.', TRUE,
 460, 35, 3.2, 0.2, 280, 20, 1.5, 5, 4.0, 0, 20, 1.2, 160, 14, 0.03),

-- Arctic Cod Fish & Chips: 890 cal per serving (~380g). Per 100g: 234 cal, 9.5P, 21.1C, 12.4F
('rr_fish_and_chips', 'Red Robin Arctic Cod Fish & Chips', 234, 9.5, 21.1, 12.4,
 1.6, 1.1, 380, NULL,
 'red_robin', ARRAY['red robin fish and chips', 'rr arctic cod', 'red robin cod fish chips'],
 'american', 'Red Robin', 1, '234 cal/100g. Per serving (~380g): 890 cal. Beer-battered cod, steak fries, coleslaw, tartar sauce.', TRUE,
 480, 30, 2.6, 0.2, 350, 25, 1.5, 5, 6.0, 0, 22, 0.5, 160, 20, 0.1),

-- Impossible Burger: 780 cal per burger (~340g). Per 100g: 229 cal, 9.4P, 18.8C, 12.9F
('rr_impossible_burger', 'Red Robin Impossible Burger', 229, 9.4, 18.8, 12.9,
 2.1, 5.0, 340, NULL,
 'red_robin', ARRAY['red robin impossible burger', 'rr impossible burger', 'red robin plant based burger'],
 'american', 'Red Robin', 1, '229 cal/100g. Per burger (~340g): 780 cal. Impossible plant-based patty, lettuce, tomato, pickles, bun.', TRUE,
 460, 0, 5.3, 0.0, 400, 60, 3.5, 0, 3.0, 0, 30, 3.0, 120, 4, 0.02),

-- Mountain High Mudpie: 1540 cal per slice (~340g). Per 100g: 453 cal, 4.7P, 47.1C, 27.6F
('rr_mountain_high_mudpie', 'Red Robin Mountain High Mudpie', 453, 4.7, 47.1, 27.6,
 2.4, 35.3, 340, NULL,
 'red_robin', ARRAY['red robin mountain high mudpie', 'rr mudpie', 'red robin mud pie'],
 'american', 'Red Robin', 1, '453 cal/100g. Per slice (~340g): 1540 cal. Chocolate cookie crust, ice cream, hot fudge, whipped cream.', TRUE,
 280, 50, 15.3, 0.3, 350, 100, 2.5, 40, 0.0, 5, 30, 1.0, 150, 5, 0.02),

-- ==========================================
-- BOB EVANS (Expand)
-- ==========================================

-- Pot Roast: 620 cal per serving (~340g). Per 100g: 182 cal, 16.2P, 6.8C, 10.3F
('be_pot_roast', 'Bob Evans Slow-Roasted Pot Roast', 182, 16.2, 6.8, 10.3,
 0.9, 1.5, 340, NULL,
 'bob_evans', ARRAY['bob evans pot roast', 'bob evans slow roasted pot roast', 'be pot roast'],
 'american', 'Bob Evans', 1, '182 cal/100g. Per serving (~340g): 620 cal. Slow-roasted beef, carrots, onions, gravy.', TRUE,
 400, 55, 4.1, 0.2, 380, 20, 2.5, 150, 4.0, 0, 22, 4.0, 180, 14, 0.04),

-- Turkey & Dressing: 650 cal per serving (~380g). Per 100g: 171 cal, 12.6P, 14.5C, 7.1F
('be_turkey_dressing', 'Bob Evans Turkey & Dressing', 171, 12.6, 14.5, 7.1,
 0.8, 2.1, 380, NULL,
 'bob_evans', ARRAY['bob evans turkey and dressing', 'be turkey dressing', 'bob evans herb rubbed turkey'],
 'american', 'Bob Evans', 1, '171 cal/100g. Per serving (~380g): 650 cal. Herb-rubbed turkey, bread dressing, gravy.', TRUE,
 450, 50, 2.4, 0.1, 300, 30, 1.5, 15, 0.0, 0, 22, 2.0, 200, 20, 0.03),

-- Mac & Cheese: 250 cal per side (~150g). Per 100g: 167 cal, 6.0P, 16.0C, 8.7F
('be_mac_and_cheese', 'Bob Evans Mac & Cheese', 167, 6.0, 16.0, 8.7,
 0.7, 2.0, 150, NULL,
 'bob_evans', ARRAY['bob evans mac and cheese', 'be mac cheese', 'bob evans macaroni and cheese'],
 'american', 'Bob Evans', 1, '167 cal/100g. Per side (~150g): 250 cal. Creamy macaroni and cheese.', TRUE,
 380, 20, 4.7, 0.1, 100, 100, 0.8, 20, 0.0, 0, 12, 0.8, 120, 5, 0.02),

-- Mashed Potatoes: 210 cal per side (~180g). Per 100g: 117 cal, 2.8P, 14.4C, 5.6F
('be_mashed_potatoes', 'Bob Evans Mashed Potatoes & Gravy', 117, 2.8, 14.4, 5.6,
 0.6, 1.1, 180, NULL,
 'bob_evans', ARRAY['bob evans mashed potatoes', 'be mashed potatoes', 'bob evans mashed potatoes and gravy'],
 'american', 'Bob Evans', 1, '117 cal/100g. Per side (~180g): 210 cal. Creamy mashed potatoes with chicken gravy.', TRUE,
 350, 5, 2.2, 0.1, 250, 15, 0.5, 5, 3.0, 0, 15, 0.3, 40, 2, 0.01),

-- Banana Bread: 380 cal per slice (~110g). Per 100g: 345 cal, 4.5P, 47.3C, 15.5F
('be_banana_bread', 'Bob Evans Banana Bread', 345, 4.5, 47.3, 15.5,
 1.8, 25.5, 110, 110,
 'bob_evans', ARRAY['bob evans banana bread', 'be banana bread', 'bob evans banana nut bread'],
 'american', 'Bob Evans', 1, '345 cal/100g. Per slice (~110g): 380 cal. Sweet banana bread, walnuts.', TRUE,
 220, 30, 3.6, 0.1, 180, 20, 1.5, 10, 2.0, 5, 18, 0.5, 60, 5, 0.1),

-- Chicken-Fried Chicken: 570 cal per serving (~260g). Per 100g: 219 cal, 13.5P, 13.5C, 12.7F
('be_chicken_fried_chicken', 'Bob Evans Chicken-Fried Chicken', 219, 13.5, 13.5, 12.7,
 0.4, 0.8, 260, 260,
 'bob_evans', ARRAY['bob evans chicken fried chicken', 'be chicken fried chicken', 'bob evans boneless fried chicken'],
 'american', 'Bob Evans', 1, '219 cal/100g. Per serving (~260g): 570 cal. Breaded chicken breast, country gravy.', TRUE,
 480, 55, 3.8, 0.2, 280, 25, 1.5, 10, 0.0, 0, 20, 1.5, 180, 18, 0.03),

-- Stacked & Stuffed Hotcakes: 1150 cal per serving (~400g). Per 100g: 288 cal, 5.0P, 37.5C, 13.3F
('be_stacked_stuffed_hotcakes', 'Bob Evans Stacked & Stuffed Hotcakes', 288, 5.0, 37.5, 13.3,
 1.0, 17.5, 400, NULL,
 'bob_evans', ARRAY['bob evans stacked and stuffed hotcakes', 'be stuffed hotcakes', 'bob evans buttermilk hotcakes'],
 'american', 'Bob Evans', 1, '288 cal/100g. Per serving (~400g): 1150 cal. Stuffed buttermilk hotcakes with cream cheese filling, syrup.', TRUE,
 480, 60, 5.5, 0.3, 180, 80, 2.5, 40, 0.0, 5, 14, 0.8, 130, 10, 0.02),

-- Rise & Shine: 540 cal per serving (~280g). Per 100g: 193 cal, 10.7P, 12.5C, 11.1F
('be_rise_and_shine', 'Bob Evans Rise & Shine Breakfast', 193, 10.7, 12.5, 11.1,
 0.4, 1.8, 280, NULL,
 'bob_evans', ARRAY['bob evans rise and shine', 'be rise and shine breakfast'],
 'american', 'Bob Evans', 1, '193 cal/100g. Per serving (~280g): 540 cal. 2 eggs, bacon or sausage, home fries, toast.', TRUE,
 520, 180, 4.3, 0.3, 250, 50, 2.0, 50, 2.0, 5, 16, 1.8, 180, 18, 0.04),

-- Sunshine Skillet: 680 cal per serving (~350g). Per 100g: 194 cal, 10.3P, 12.0C, 11.7F
('be_sunshine_skillet', 'Bob Evans Sunshine Skillet', 194, 10.3, 12.0, 11.7,
 1.1, 2.0, 350, NULL,
 'bob_evans', ARRAY['bob evans sunshine skillet', 'be sunshine skillet'],
 'american', 'Bob Evans', 1, '194 cal/100g. Per serving (~350g): 680 cal. Eggs, sausage, peppers, onions, cheese, home fries, hollandaise.', TRUE,
 560, 190, 4.9, 0.3, 300, 80, 2.0, 60, 5.0, 10, 20, 2.0, 200, 18, 0.04),

-- Farm Fresh Salad: 350 cal per salad (~320g). Per 100g: 109 cal, 8.4P, 5.0C, 6.6F
('be_farm_fresh_salad', 'Bob Evans Farm Fresh Salad', 109, 8.4, 5.0, 6.6,
 1.6, 2.5, 320, NULL,
 'bob_evans', ARRAY['bob evans farm fresh salad', 'be farm fresh salad'],
 'american', 'Bob Evans', 1, '109 cal/100g. Per salad (~320g): 350 cal. Mixed greens, chicken, bacon, egg, tomato, cheese, ranch.', TRUE,
 380, 40, 2.5, 0.1, 350, 80, 1.5, 80, 10.0, 5, 20, 1.5, 160, 12, 0.04),

-- Homestyle Fried Chicken: 640 cal per serving (~280g). Per 100g: 229 cal, 16.1P, 10.7C, 13.6F
('be_homestyle_fried_chicken', 'Bob Evans Homestyle Fried Chicken', 229, 16.1, 10.7, 13.6,
 0.4, 0.4, 280, NULL,
 'bob_evans', ARRAY['bob evans homestyle fried chicken', 'be fried chicken'],
 'american', 'Bob Evans', 1, '229 cal/100g. Per serving (~280g): 640 cal. Bone-in crispy fried chicken.', TRUE,
 460, 65, 4.3, 0.2, 260, 20, 1.5, 10, 0.0, 0, 20, 1.5, 180, 18, 0.04),

-- Chicken Parmesan: 590 cal per serving (~320g). Per 100g: 184 cal, 12.5P, 12.5C, 9.4F
('be_chicken_parmesan', 'Bob Evans Chicken Parmesan', 184, 12.5, 12.5, 9.4,
 1.3, 3.1, 320, NULL,
 'bob_evans', ARRAY['bob evans chicken parmesan', 'be chicken parm'],
 'american', 'Bob Evans', 1, '184 cal/100g. Per serving (~320g): 590 cal. Breaded chicken breast, marinara, mozzarella, spaghetti.', TRUE,
 450, 45, 3.8, 0.1, 280, 120, 2.0, 30, 5.0, 0, 22, 1.5, 200, 16, 0.03),

-- Wildfire Chicken Salad: 480 cal per salad (~340g). Per 100g: 141 cal, 10.6P, 8.2C, 7.4F
('be_wildfire_chicken_salad', 'Bob Evans Wildfire Chicken Salad', 141, 10.6, 8.2, 7.4,
 2.1, 4.1, 340, NULL,
 'bob_evans', ARRAY['bob evans wildfire chicken salad', 'be wildfire salad'],
 'american', 'Bob Evans', 1, '141 cal/100g. Per salad (~340g): 480 cal. Grilled chicken, mixed greens, corn, black beans, BBQ ranch.', TRUE,
 420, 35, 2.6, 0.1, 380, 60, 1.5, 60, 12.0, 0, 25, 1.2, 160, 12, 0.04),

-- ==========================================
-- IN-N-OUT BURGER (New Chain)
-- ==========================================

-- Double-Double (w/ spread): 670 cal per burger (~330g). Per 100g: 203 cal, 11.2P, 12.7C, 12.4F
('ino_double_double', 'In-N-Out Double-Double', 203, 11.2, 12.7, 12.4,
 0.6, 2.7, 330, NULL,
 'in_n_out', ARRAY['in n out double double', 'in-n-out double-double', 'double double burger', 'in and out double double'],
 'fast_food', 'In-N-Out', 1, '203 cal/100g. Per burger (~330g): 670 cal, 41F, 42C, 37P. Two beef patties, two slices American cheese, spread, lettuce, tomato, onion.', TRUE,
 506, 38, 4.5, 0.3, 320, 100, 3.0, 30, 4.0, 0, 25, 4.0, 200, 18, 0.04),

-- Cheeseburger (w/ spread): 480 cal per burger (~268g). Per 100g: 179 cal, 8.2P, 13.4C, 10.1F
('ino_cheeseburger', 'In-N-Out Cheeseburger', 179, 8.2, 13.4, 10.1,
 0.7, 2.6, 268, NULL,
 'in_n_out', ARRAY['in n out cheeseburger', 'in-n-out cheeseburger'],
 'fast_food', 'In-N-Out', 1, '179 cal/100g. Per burger (~268g): 480 cal. Beef patty, American cheese, spread, lettuce, tomato, onion.', TRUE,
 480, 30, 4.5, 0.2, 280, 80, 2.5, 25, 4.0, 0, 22, 3.0, 170, 15, 0.03),

-- Hamburger (w/ spread): 390 cal per burger (~243g). Per 100g: 160 cal, 6.6P, 14.0C, 7.8F
('ino_hamburger', 'In-N-Out Hamburger', 160, 6.6, 14.0, 7.8,
 0.8, 2.5, 243, NULL,
 'in_n_out', ARRAY['in n out hamburger', 'in-n-out hamburger', 'in n out burger'],
 'fast_food', 'In-N-Out', 1, '160 cal/100g. Per burger (~243g): 390 cal. Beef patty, spread, lettuce, tomato, onion.', TRUE,
 420, 20, 3.3, 0.2, 260, 30, 2.5, 15, 4.0, 0, 20, 2.5, 140, 14, 0.03),

-- Animal Style Burger: 710 cal per burger (~340g). Per 100g: 209 cal, 10.9P, 12.6C, 13.2F
('ino_animal_style', 'In-N-Out Animal Style Burger', 209, 10.9, 12.6, 13.2,
 0.6, 3.8, 340, NULL,
 'in_n_out', ARRAY['in n out animal style', 'in-n-out animal style burger', 'animal style double double'],
 'fast_food', 'In-N-Out', 1, '209 cal/100g. Per burger (~340g): 710 cal. Double-Double with mustard-grilled patty, extra spread, grilled onions, pickles.', TRUE,
 530, 42, 5.0, 0.3, 330, 110, 3.0, 30, 4.0, 0, 26, 4.0, 210, 18, 0.04),

-- Fries: 395 cal per serving (125g). Per 100g: 316 cal, 5.6P, 43.2C, 14.4F
('ino_fries', 'In-N-Out French Fries', 316, 5.6, 43.2, 14.4,
 1.6, 0.0, 125, NULL,
 'in_n_out', ARRAY['in n out fries', 'in-n-out french fries', 'in n out french fries'],
 'fast_food', 'In-N-Out', 1, '316 cal/100g. Per serving (125g): 395 cal, 18F, 54C, 7P. Fresh-cut potatoes, cooked in sunflower oil.', TRUE,
 196, 0, 4.0, 0.0, 400, 10, 0.6, 0, 8.0, 0, 20, 0.3, 50, 2, 0.01),

-- Animal Fries: 750 cal per serving (~250g). Per 100g: 300 cal, 6.0P, 24.0C, 20.0F
('ino_animal_fries', 'In-N-Out Animal Fries', 300, 6.0, 24.0, 20.0,
 1.2, 2.0, 250, NULL,
 'in_n_out', ARRAY['in n out animal fries', 'in-n-out animal fries', 'animal style fries'],
 'fast_food', 'In-N-Out', 1, '300 cal/100g. Per serving (~250g): 750 cal. Fries with melted cheese, grilled onions, spread.', TRUE,
 380, 15, 8.0, 0.2, 380, 80, 0.8, 15, 6.0, 0, 18, 0.8, 80, 3, 0.01),

-- Chocolate Shake: 590 cal per shake (~425g). Per 100g: 139 cal, 2.4P, 21.2C, 5.2F
('ino_chocolate_shake', 'In-N-Out Chocolate Shake', 139, 2.4, 21.2, 5.2,
 0.2, 17.9, 425, NULL,
 'in_n_out', ARRAY['in n out chocolate shake', 'in-n-out chocolate milkshake'],
 'fast_food', 'In-N-Out', 1, '139 cal/100g. Per shake (~425g): 590 cal. Real ice cream chocolate shake.', TRUE,
 100, 14, 3.3, 0.1, 280, 100, 0.5, 30, 1.0, 10, 18, 0.5, 100, 3, 0.02),

-- Vanilla Shake: 580 cal per shake (~425g). Per 100g: 136 cal, 2.4P, 20.0C, 5.2F
('ino_vanilla_shake', 'In-N-Out Vanilla Shake', 136, 2.4, 20.0, 5.2,
 0.0, 17.6, 425, NULL,
 'in_n_out', ARRAY['in n out vanilla shake', 'in-n-out vanilla milkshake'],
 'fast_food', 'In-N-Out', 1, '136 cal/100g. Per shake (~425g): 580 cal. Real ice cream vanilla shake.', TRUE,
 95, 14, 3.3, 0.1, 270, 100, 0.2, 30, 1.0, 10, 16, 0.5, 95, 3, 0.02),

-- Strawberry Shake: 590 cal per shake (~425g). Per 100g: 139 cal, 2.1P, 21.4C, 5.2F
('ino_strawberry_shake', 'In-N-Out Strawberry Shake', 139, 2.1, 21.4, 5.2,
 0.2, 18.1, 425, NULL,
 'in_n_out', ARRAY['in n out strawberry shake', 'in-n-out strawberry milkshake'],
 'fast_food', 'In-N-Out', 1, '139 cal/100g. Per shake (~425g): 590 cal. Real ice cream strawberry shake.', TRUE,
 98, 14, 3.3, 0.1, 275, 100, 0.3, 25, 3.0, 10, 16, 0.5, 95, 3, 0.02),

-- Protein Style Burger: 520 cal per burger (~300g). Per 100g: 173 cal, 11.0P, 3.7C, 13.0F
('ino_protein_style', 'In-N-Out Protein Style Burger', 173, 11.0, 3.7, 13.0,
 0.7, 2.0, 300, NULL,
 'in_n_out', ARRAY['in n out protein style', 'in-n-out protein style', 'lettuce wrapped burger in n out'],
 'fast_food', 'In-N-Out', 1, '173 cal/100g. Per burger (~300g): 520 cal. Double-Double wrapped in lettuce instead of bun.', TRUE,
 420, 40, 5.0, 0.3, 320, 100, 2.5, 40, 5.0, 0, 22, 4.0, 200, 18, 0.04),

-- ==========================================
-- SHAKE SHACK (New Chain)
-- ==========================================

-- ShackBurger (single): 530 cal per burger (~220g). Per 100g: 241 cal, 13.2P, 11.8C, 15.5F
('ss_shackburger', 'Shake Shack ShackBurger', 241, 13.2, 11.8, 15.5,
 0.5, 3.6, 220, NULL,
 'shake_shack', ARRAY['shake shack shackburger', 'shack burger', 'shakeshack burger'],
 'fast_food', 'Shake Shack', 1, '241 cal/100g. Per burger (~220g): 530 cal, 34F, 26C, 29P. Angus beef patty, lettuce, tomato, ShackSauce.', TRUE,
 480, 55, 7.3, 0.5, 300, 80, 3.0, 20, 3.0, 0, 22, 3.5, 180, 16, 0.04),

-- SmokeShack (single): 570 cal per burger (~240g). Per 100g: 238 cal, 14.2P, 10.8C, 15.0F
('ss_smokeshack', 'Shake Shack SmokeShack', 238, 14.2, 10.8, 15.0,
 0.4, 2.9, 240, NULL,
 'shake_shack', ARRAY['shake shack smokeshack', 'smokeshack burger'],
 'fast_food', 'Shake Shack', 1, '238 cal/100g. Per burger (~240g): 570 cal, 36F, 26C, 34P. Angus beef, bacon, cherry pepper, ShackSauce.', TRUE,
 520, 60, 6.7, 0.5, 310, 80, 3.0, 25, 3.0, 0, 22, 3.5, 190, 16, 0.04),

-- Shack Stack: 740 cal per burger (~280g). Per 100g: 264 cal, 12.5P, 15.0C, 17.5F
('ss_shack_stack', 'Shake Shack Shack Stack', 264, 12.5, 15.0, 17.5,
 0.7, 3.2, 280, NULL,
 'shake_shack', ARRAY['shake shack shack stack', 'shack stack burger'],
 'fast_food', 'Shake Shack', 1, '264 cal/100g. Per burger (~280g): 740 cal. Cheeseburger + Shroom Burger (crispy fried portobello).', TRUE,
 500, 50, 8.2, 0.4, 350, 120, 3.0, 20, 2.0, 0, 25, 3.0, 200, 14, 0.04),

-- Chicken Shack: 590 cal per sandwich (~250g). Per 100g: 236 cal, 11.2P, 16.8C, 13.6F
('ss_chicken_shack', 'Shake Shack Chicken Shack', 236, 11.2, 16.8, 13.6,
 0.8, 2.4, 250, NULL,
 'shake_shack', ARRAY['shake shack chicken shack', 'chicken shack sandwich'],
 'fast_food', 'Shake Shack', 1, '236 cal/100g. Per sandwich (~250g): 590 cal. Crispy chicken breast, lettuce, pickles, buttermilk herb mayo.', TRUE,
 480, 40, 3.6, 0.2, 280, 25, 2.0, 10, 3.0, 0, 22, 1.0, 170, 16, 0.03),

-- Crinkle Fries: 470 cal per regular (~180g). Per 100g: 261 cal, 3.9P, 33.3C, 12.8F
('ss_crinkle_fries', 'Shake Shack Crinkle Cut Fries', 261, 3.9, 33.3, 12.8,
 2.2, 0.6, 180, NULL,
 'shake_shack', ARRAY['shake shack fries', 'crinkle cut fries shake shack', 'shake shack crinkle fries'],
 'fast_food', 'Shake Shack', 1, '261 cal/100g. Per regular (~180g): 470 cal. Crinkle-cut fries.', TRUE,
 320, 0, 2.2, 0.0, 380, 10, 0.8, 0, 8.0, 0, 18, 0.3, 50, 2, 0.01),

-- Cheese Fries: 650 cal per serving (~230g). Per 100g: 283 cal, 6.5P, 26.1C, 16.9F
('ss_cheese_fries', 'Shake Shack Cheese Fries', 283, 6.5, 26.1, 16.9,
 1.7, 1.3, 230, NULL,
 'shake_shack', ARRAY['shake shack cheese fries', 'crinkle fries with cheese sauce'],
 'fast_food', 'Shake Shack', 1, '283 cal/100g. Per serving (~230g): 650 cal. Crinkle fries with cheese sauce.', TRUE,
 480, 12, 5.7, 0.1, 360, 80, 0.8, 15, 6.0, 0, 16, 0.8, 90, 3, 0.01),

-- Concrete (vanilla custard): 430 cal per regular (~200g). Per 100g: 215 cal, 4.0P, 28.0C, 10.0F
('ss_concrete_vanilla', 'Shake Shack Vanilla Concrete', 215, 4.0, 28.0, 10.0,
 0.5, 22.0, 200, NULL,
 'shake_shack', ARRAY['shake shack concrete', 'shake shack vanilla custard', 'shake shack frozen custard'],
 'fast_food', 'Shake Shack', 1, '215 cal/100g. Per regular (~200g): 430 cal. Dense frozen custard with mix-ins.', TRUE,
 100, 40, 6.0, 0.1, 200, 100, 0.3, 40, 0.5, 15, 14, 0.5, 100, 3, 0.02),

-- Chocolate Shake: 780 cal per shake (~400g). Per 100g: 195 cal, 3.5P, 25.5C, 8.8F
('ss_chocolate_shake', 'Shake Shack Chocolate Shake', 195, 3.5, 25.5, 8.8,
 0.5, 20.0, 400, NULL,
 'shake_shack', ARRAY['shake shack chocolate shake', 'shake shack chocolate milkshake'],
 'fast_food', 'Shake Shack', 1, '195 cal/100g. Per shake (~400g): 780 cal. Hand-spun chocolate shake with frozen custard.', TRUE,
 120, 25, 5.5, 0.1, 320, 120, 0.8, 35, 1.0, 12, 18, 0.6, 110, 4, 0.02),

-- Black & White Shake: 810 cal per shake (~400g). Per 100g: 203 cal, 3.5P, 26.3C, 9.3F
('ss_black_white_shake', 'Shake Shack Black & White Shake', 203, 3.5, 26.3, 9.3,
 0.3, 21.0, 400, NULL,
 'shake_shack', ARRAY['shake shack black and white shake', 'shake shack black white milkshake'],
 'fast_food', 'Shake Shack', 1, '203 cal/100g. Per shake (~400g): 810 cal. Vanilla and chocolate frozen custard blended.', TRUE,
 115, 28, 5.8, 0.1, 310, 115, 0.5, 35, 0.5, 12, 17, 0.6, 105, 4, 0.02),

-- Chicken Bites: 300 cal per 6 pieces (~130g). Per 100g: 231 cal, 16.2P, 13.8C, 12.3F
('ss_chicken_bites', 'Shake Shack Chicken Bites', 231, 16.2, 13.8, 12.3,
 0.8, 0.8, 130, 22,
 'shake_shack', ARRAY['shake shack chicken bites', 'shake shack chicken nuggets'],
 'fast_food', 'Shake Shack', 1, '231 cal/100g. Per 6 pieces (~130g): 300 cal. Crispy chicken breast bites, honey mustard sauce.', TRUE,
 460, 30, 2.3, 0.1, 220, 15, 1.0, 5, 0.0, 0, 16, 0.8, 140, 14, 0.03),

-- ==========================================
-- CULVER'S (New Chain)
-- ==========================================

-- ButterBurger Original (single): 390 cal per burger (132g). Per 100g: 295 cal, 15.2P, 28.8C, 12.9F
('culvers_butterburger_original', 'Culver''s ButterBurger Original', 295, 15.2, 28.8, 12.9,
 0.8, 4.5, 132, NULL,
 'culvers', ARRAY['culvers butterburger', 'culvers butterburger original', 'culver''s original butterburger'],
 'fast_food', 'Culver''s', 1, '295 cal/100g. Per burger (132g): 390 cal, 17F, 38C, 20P. Buttered and toasted bun, 100% Midwest beef.', TRUE,
 364, 42, 5.3, 0.0, 280, 60, 3.0, 10, 2.0, 0, 20, 3.0, 160, 14, 0.03),

-- ButterBurger Deluxe (single): 460 cal per burger (~165g). Per 100g: 279 cal, 13.9P, 23.0C, 14.5F
('culvers_butterburger_deluxe', 'Culver''s ButterBurger Deluxe', 279, 13.9, 23.0, 14.5,
 0.9, 5.5, 165, NULL,
 'culvers', ARRAY['culvers butterburger deluxe', 'culver''s deluxe butterburger'],
 'fast_food', 'Culver''s', 1, '279 cal/100g. Per burger (~165g): 460 cal. Beef patty, lettuce, tomato, pickles, onion, mayo, ketchup.', TRUE,
 400, 45, 5.5, 0.0, 300, 60, 3.0, 15, 3.0, 0, 22, 3.0, 170, 15, 0.03),

-- ButterBurger Cheese (single): 440 cal per burger (~155g). Per 100g: 284 cal, 15.5P, 24.5C, 13.5F
('culvers_butterburger_cheese', 'Culver''s ButterBurger Cheese', 284, 15.5, 24.5, 13.5,
 0.6, 4.5, 155, NULL,
 'culvers', ARRAY['culvers butterburger cheese', 'culver''s cheese butterburger'],
 'fast_food', 'Culver''s', 1, '284 cal/100g. Per burger (~155g): 440 cal. Beef patty, Wisconsin cheddar, buttered bun.', TRUE,
 480, 50, 6.5, 0.0, 290, 100, 3.0, 20, 2.0, 0, 22, 3.5, 200, 15, 0.03),

-- Wisconsin Cheese Curds (regular): 510 cal per regular (~200g). Per 100g: 255 cal, 10.0P, 25.5C, 12.5F
('culvers_cheese_curds', 'Culver''s Wisconsin Cheese Curds', 255, 10.0, 25.5, 12.5,
 0.5, 1.0, 200, NULL,
 'culvers', ARRAY['culvers cheese curds', 'culver''s wisconsin cheese curds', 'culvers curds'],
 'fast_food', 'Culver''s', 1, '255 cal/100g. Per regular (~200g): 510 cal, 25F, 51C, 20P. White cheddar cheese curds, lightly battered and fried.', TRUE,
 615, 28, 6.0, 0.2, 150, 150, 1.0, 25, 0.0, 0, 12, 1.5, 150, 6, 0.02),

-- Chicken Tenders (4pc): 540 cal per 4pc (244g). Per 100g: 221 cal, 16.4P, 17.2C, 9.8F
('culvers_chicken_tenders', 'Culver''s Chicken Tenders (4pc)', 221, 16.4, 17.2, 9.8,
 0.4, 0.4, 244, 61,
 'culvers', ARRAY['culvers chicken tenders', 'culver''s chicken tenders'],
 'fast_food', 'Culver''s', 1, '221 cal/100g. Per 4pc (244g): 540 cal, 24F, 42C, 40P. Hand-battered chicken breast tenders.', TRUE,
 754, 41, 1.2, 0.0, 280, 15, 1.5, 5, 0.0, 0, 20, 0.8, 170, 16, 0.03),

-- Crinkle Fries (regular): 360 cal per regular (~150g). Per 100g: 240 cal, 3.3P, 33.3C, 10.7F
('culvers_crinkle_fries', 'Culver''s Crinkle Cut Fries', 240, 3.3, 33.3, 10.7,
 2.7, 0.0, 150, NULL,
 'culvers', ARRAY['culvers fries', 'culver''s crinkle cut fries', 'culvers french fries'],
 'fast_food', 'Culver''s', 1, '240 cal/100g. Per regular (~150g): 360 cal. Crinkle-cut fries.', TRUE,
 300, 0, 1.3, 0.0, 380, 8, 0.6, 0, 6.0, 0, 18, 0.3, 50, 2, 0.01),

-- Concrete Mixer Chocolate: 580 cal per regular (~270g). Per 100g: 215 cal, 4.1P, 28.1C, 10.0F
('culvers_concrete_chocolate', 'Culver''s Concrete Mixer Chocolate', 215, 4.1, 28.1, 10.0,
 0.7, 22.2, 270, NULL,
 'culvers', ARRAY['culvers concrete mixer chocolate', 'culver''s chocolate concrete'],
 'fast_food', 'Culver''s', 1, '215 cal/100g. Per regular (~270g): 580 cal. Fresh frozen custard blended with chocolate.', TRUE,
 120, 35, 6.3, 0.1, 280, 110, 0.8, 35, 0.5, 12, 20, 0.6, 110, 4, 0.02),

-- Concrete Mixer Vanilla: 540 cal per regular (~260g). Per 100g: 208 cal, 3.8P, 26.9C, 9.6F
('culvers_concrete_vanilla', 'Culver''s Concrete Mixer Vanilla', 208, 3.8, 26.9, 9.6,
 0.0, 21.5, 260, NULL,
 'culvers', ARRAY['culvers concrete mixer vanilla', 'culver''s vanilla concrete'],
 'fast_food', 'Culver''s', 1, '208 cal/100g. Per regular (~260g): 540 cal. Fresh frozen custard, vanilla.', TRUE,
 100, 35, 5.8, 0.1, 260, 100, 0.2, 35, 0.0, 12, 16, 0.5, 100, 3, 0.02),

-- Concrete Mixer Cookie Dough: 710 cal per regular (~290g). Per 100g: 245 cal, 4.1P, 32.4C, 11.4F
('culvers_concrete_cookie_dough', 'Culver''s Concrete Mixer Cookie Dough', 245, 4.1, 32.4, 11.4,
 0.3, 24.1, 290, NULL,
 'culvers', ARRAY['culvers cookie dough concrete', 'culver''s concrete mixer cookie dough'],
 'fast_food', 'Culver''s', 1, '245 cal/100g. Per regular (~290g): 710 cal. Frozen custard with chocolate chip cookie dough.', TRUE,
 140, 40, 6.9, 0.2, 280, 100, 1.0, 30, 0.0, 10, 16, 0.5, 100, 4, 0.02),

-- Pot Roast Sandwich: 530 cal per sandwich (~260g). Per 100g: 204 cal, 13.5P, 15.4C, 9.6F
('culvers_pot_roast_sandwich', 'Culver''s Pot Roast Sandwich', 204, 13.5, 15.4, 9.6,
 0.8, 2.3, 260, NULL,
 'culvers', ARRAY['culvers pot roast sandwich', 'culver''s pot roast'],
 'fast_food', 'Culver''s', 1, '204 cal/100g. Per sandwich (~260g): 530 cal. Slow-roasted beef, gravy, toasted bun.', TRUE,
 480, 40, 3.8, 0.1, 350, 30, 2.5, 10, 2.0, 0, 22, 3.5, 180, 14, 0.04),

-- North Atlantic Cod: 660 cal per serving (~280g). Per 100g: 236 cal, 10.7P, 17.9C, 13.2F
('culvers_north_atlantic_cod', 'Culver''s North Atlantic Cod', 236, 10.7, 17.9, 13.2,
 1.1, 1.1, 280, NULL,
 'culvers', ARRAY['culvers cod dinner', 'culver''s north atlantic cod', 'culvers fish dinner'],
 'fast_food', 'Culver''s', 1, '236 cal/100g. Per serving (~280g): 660 cal. Beer-battered cod fillets, tartar sauce.', TRUE,
 480, 30, 2.5, 0.1, 300, 25, 1.0, 5, 4.0, 0, 20, 0.5, 160, 22, 0.12),

-- Onion Rings (regular): 400 cal per regular (~130g). Per 100g: 308 cal, 4.6P, 36.2C, 16.2F
('culvers_onion_rings', 'Culver''s Onion Rings', 308, 4.6, 36.2, 16.2,
 1.5, 3.8, 130, NULL,
 'culvers', ARRAY['culvers onion rings', 'culver''s onion rings'],
 'fast_food', 'Culver''s', 1, '308 cal/100g. Per regular (~130g): 400 cal. Hand-battered onion rings.', TRUE,
 400, 5, 3.1, 0.2, 150, 20, 1.0, 0, 3.0, 0, 10, 0.3, 40, 2, 0.01),

-- ==========================================
-- WINGSTOP (New Chain)
-- ==========================================

-- Classic Wings Original Hot (6pc): 480 cal per 6 wings (~210g). Per 100g: 229 cal, 20.0P, 1.0C, 16.2F
('ws_wings_original_hot', 'Wingstop Classic Wings Original Hot', 229, 20.0, 1.0, 16.2,
 0.5, 0.5, 210, 35,
 'wingstop', ARRAY['wingstop original hot wings', 'wingstop classic bone in original hot'],
 'wings', 'Wingstop', 1, '229 cal/100g. Per 6 wings (~210g): 480 cal. Bone-in chicken wings, Original Hot buffalo sauce.', TRUE,
 640, 55, 4.3, 0.1, 240, 15, 1.2, 25, 2.0, 0, 16, 2.0, 160, 14, 0.04),

-- Classic Wings Lemon Pepper (6pc): 540 cal per 6 wings (~210g). Per 100g: 257 cal, 20.0P, 0.0C, 19.5F
('ws_wings_lemon_pepper', 'Wingstop Classic Wings Lemon Pepper', 257, 20.0, 0.0, 19.5,
 0.0, 0.0, 210, 35,
 'wingstop', ARRAY['wingstop lemon pepper wings', 'wingstop classic bone in lemon pepper'],
 'wings', 'Wingstop', 1, '257 cal/100g. Per 6 wings (~210g): 540 cal. Bone-in wings, lemon pepper dry rub.', TRUE,
 520, 55, 5.2, 0.1, 250, 18, 1.2, 5, 3.0, 0, 16, 2.0, 165, 14, 0.04),

-- Classic Wings Garlic Parmesan (6pc): 570 cal per 6 wings (~210g). Per 100g: 271 cal, 19.5P, 1.0C, 21.0F
('ws_wings_garlic_parmesan', 'Wingstop Classic Wings Garlic Parmesan', 271, 19.5, 1.0, 21.0,
 0.0, 0.5, 210, 35,
 'wingstop', ARRAY['wingstop garlic parmesan wings', 'wingstop classic bone in garlic parm'],
 'wings', 'Wingstop', 1, '271 cal/100g. Per 6 wings (~210g): 570 cal. Bone-in wings, garlic parmesan sauce.', TRUE,
 560, 60, 5.7, 0.1, 240, 50, 1.0, 10, 1.0, 0, 16, 2.0, 170, 14, 0.04),

-- Classic Wings Mango Habanero (6pc): 520 cal per 6 wings (~210g). Per 100g: 248 cal, 18.6P, 7.6C, 15.7F
('ws_wings_mango_habanero', 'Wingstop Classic Wings Mango Habanero', 248, 18.6, 7.6, 15.7,
 0.5, 5.7, 210, 35,
 'wingstop', ARRAY['wingstop mango habanero wings', 'wingstop classic bone in mango habanero'],
 'wings', 'Wingstop', 1, '248 cal/100g. Per 6 wings (~210g): 520 cal. Bone-in wings, sweet & spicy mango habanero sauce.', TRUE,
 580, 55, 4.3, 0.1, 240, 18, 1.2, 25, 6.0, 0, 16, 2.0, 160, 14, 0.04),

-- Classic Wings Louisiana Rub (6pc): 470 cal per 6 wings (~210g). Per 100g: 224 cal, 20.0P, 0.5C, 15.7F
('ws_wings_louisiana_rub', 'Wingstop Classic Wings Louisiana Rub', 224, 20.0, 0.5, 15.7,
 0.0, 0.0, 210, 35,
 'wingstop', ARRAY['wingstop louisiana rub wings', 'wingstop classic bone in louisiana'],
 'wings', 'Wingstop', 1, '224 cal/100g. Per 6 wings (~210g): 470 cal. Bone-in wings, Louisiana dry rub seasoning.', TRUE,
 600, 55, 4.0, 0.1, 240, 15, 1.2, 15, 1.0, 0, 16, 2.0, 160, 14, 0.04),

-- Boneless Wings Plain (8pc): 360 cal per 8 boneless (~170g). Per 100g: 212 cal, 14.1P, 14.1C, 10.6F
('ws_boneless_plain', 'Wingstop Boneless Wings Plain', 212, 14.1, 14.1, 10.6,
 0.6, 0.6, 170, 21,
 'wingstop', ARRAY['wingstop boneless wings plain', 'wingstop boneless plain'],
 'wings', 'Wingstop', 1, '212 cal/100g. Per 8 boneless (~170g): 360 cal. Breaded boneless chicken breast pieces, unsauced.', TRUE,
 520, 35, 2.4, 0.1, 200, 12, 1.0, 5, 0.0, 0, 14, 0.8, 130, 12, 0.03),

-- Ranch Fries: 380 cal per serving (~150g). Per 100g: 253 cal, 4.0P, 30.0C, 13.3F
('ws_ranch_fries', 'Wingstop Ranch Fries', 253, 4.0, 30.0, 13.3,
 2.0, 0.7, 150, NULL,
 'wingstop', ARRAY['wingstop ranch fries', 'wingstop seasoned fries'],
 'wings', 'Wingstop', 1, '253 cal/100g. Per serving (~150g): 380 cal. Seasoned fries.', TRUE,
 380, 0, 2.7, 0.0, 350, 10, 0.6, 0, 6.0, 0, 18, 0.3, 50, 2, 0.01),

-- Cajun Fries: 370 cal per serving (~150g). Per 100g: 247 cal, 3.3P, 30.0C, 13.3F
('ws_cajun_fries', 'Wingstop Cajun Fried Corn', 247, 3.3, 30.0, 13.3,
 2.0, 0.7, 150, NULL,
 'wingstop', ARRAY['wingstop cajun fries'],
 'wings', 'Wingstop', 1, '247 cal/100g. Per serving (~150g): 370 cal. Fries with Cajun seasoning.', TRUE,
 420, 0, 2.7, 0.0, 350, 10, 0.6, 5, 6.0, 0, 18, 0.3, 50, 2, 0.01),

-- Corn: 170 cal per side (~130g). Per 100g: 131 cal, 3.1P, 16.2C, 6.2F
('ws_corn', 'Wingstop Cajun Fried Corn Side', 131, 3.1, 16.2, 6.2,
 1.5, 3.8, 130, NULL,
 'wingstop', ARRAY['wingstop corn', 'wingstop cajun corn'],
 'wings', 'Wingstop', 1, '131 cal/100g. Per side (~130g): 170 cal. Cajun-seasoned fried corn.', TRUE,
 280, 5, 1.2, 0.0, 200, 5, 0.5, 10, 5.0, 0, 20, 0.3, 40, 1, 0.02),

-- Coleslaw: 200 cal per side (~130g). Per 100g: 154 cal, 1.5P, 13.8C, 10.8F
('ws_coleslaw', 'Wingstop Coleslaw', 154, 1.5, 13.8, 10.8,
 1.5, 10.0, 130, NULL,
 'wingstop', ARRAY['wingstop coleslaw', 'wingstop cole slaw'],
 'wings', 'Wingstop', 1, '154 cal/100g. Per side (~130g): 200 cal. Creamy coleslaw.', TRUE,
 200, 10, 1.5, 0.0, 150, 30, 0.3, 20, 15.0, 0, 8, 0.2, 20, 1, 0.03),

-- Veggie Sticks: 25 cal per side (~80g). Per 100g: 31 cal, 1.3P, 5.0C, 0.3F
('ws_veggie_sticks', 'Wingstop Veggie Sticks', 31, 1.3, 5.0, 0.3,
 1.5, 2.5, 80, NULL,
 'wingstop', ARRAY['wingstop veggie sticks', 'wingstop celery carrots'],
 'wings', 'Wingstop', 1, '31 cal/100g. Per side (~80g): 25 cal. Fresh celery and carrot sticks.', TRUE,
 50, 0, 0.0, 0.0, 200, 25, 0.3, 200, 5.0, 0, 10, 0.2, 20, 0, 0.02),

-- Chicken Sandwich: 550 cal per sandwich (~230g). Per 100g: 239 cal, 12.2P, 18.3C, 13.0F
('ws_chicken_sandwich', 'Wingstop Chicken Sandwich', 239, 12.2, 18.3, 13.0,
 1.3, 3.5, 230, NULL,
 'wingstop', ARRAY['wingstop chicken sandwich'],
 'wings', 'Wingstop', 1, '239 cal/100g. Per sandwich (~230g): 550 cal. Crispy chicken breast, pickles, mayo, brioche bun.', TRUE,
 480, 35, 3.0, 0.2, 260, 25, 2.0, 10, 2.0, 0, 18, 1.0, 150, 14, 0.03),

-- ==========================================
-- PORTILLO'S (New Chain)
-- ==========================================

-- Italian Beef Sandwich: 520 cal per sandwich (~310g). Per 100g: 168 cal, 12.9P, 12.9C, 7.4F
('portillos_italian_beef', 'Portillo''s Italian Beef Sandwich', 168, 12.9, 12.9, 7.4,
 0.6, 1.3, 310, NULL,
 'portillos', ARRAY['portillos italian beef', 'portillo''s italian beef sandwich', 'italian beef portillos'],
 'american', 'Portillo''s', 1, '168 cal/100g. Per sandwich (~310g): 520 cal. Slow-roasted beef, Italian bread, giardiniera or sweet peppers, au jus.', TRUE,
 520, 45, 2.9, 0.1, 350, 30, 3.0, 10, 5.0, 0, 22, 4.0, 180, 16, 0.04),

-- Italian Beef & Sausage Combo: 740 cal per sandwich (~400g). Per 100g: 185 cal, 11.5P, 11.3C, 10.5F
('portillos_combo_sandwich', 'Portillo''s Italian Beef & Sausage Combo', 185, 11.5, 11.3, 10.5,
 0.5, 1.3, 400, NULL,
 'portillos', ARRAY['portillos combo', 'portillo''s beef and sausage combo', 'italian beef sausage combo'],
 'american', 'Portillo''s', 1, '185 cal/100g. Per sandwich (~400g): 740 cal. Italian beef + Italian sausage on French bread, peppers.', TRUE,
 580, 50, 4.0, 0.2, 360, 35, 3.0, 10, 5.0, 0, 22, 3.5, 190, 16, 0.04),

-- Chicago-Style Hot Dog: 380 cal per hot dog (~180g). Per 100g: 211 cal, 8.3P, 17.2C, 12.2F
('portillos_chicago_hot_dog', 'Portillo''s Chicago-Style Hot Dog', 211, 8.3, 17.2, 12.2,
 1.1, 3.3, 180, 180,
 'portillos', ARRAY['portillos hot dog', 'portillo''s chicago style hot dog', 'portillos chicago dog'],
 'american', 'Portillo''s', 1, '211 cal/100g. Per hot dog (~180g): 380 cal. Vienna beef hot dog, mustard, onion, relish, tomato, pickle, sport peppers, celery salt, poppy seed bun.', TRUE,
 500, 25, 4.4, 0.0, 200, 30, 2.0, 15, 6.0, 0, 12, 1.5, 100, 8, 0.03),

-- Char-Grilled Burger: 640 cal per burger (~280g). Per 100g: 229 cal, 14.3P, 13.6C, 13.6F
('portillos_charburger', 'Portillo''s Char-Grilled Burger', 229, 14.3, 13.6, 13.6,
 0.7, 2.9, 280, NULL,
 'portillos', ARRAY['portillos burger', 'portillo''s char grilled burger', 'portillos charburger'],
 'american', 'Portillo''s', 1, '229 cal/100g. Per burger (~280g): 640 cal. Char-grilled beef patty, lettuce, tomato, pickles, bun.', TRUE,
 460, 55, 5.7, 0.3, 320, 50, 3.0, 15, 3.0, 0, 24, 3.5, 180, 16, 0.04),

-- Chopped Salad: 340 cal per salad (~300g). Per 100g: 113 cal, 8.3P, 6.7C, 6.3F
('portillos_chopped_salad', 'Portillo''s Chopped Salad', 113, 8.3, 6.7, 6.3,
 1.7, 2.7, 300, NULL,
 'portillos', ARRAY['portillos chopped salad', 'portillo''s chopped salad'],
 'american', 'Portillo''s', 1, '113 cal/100g. Per salad (~300g): 340 cal. Chopped greens, chicken, pasta, cheese, bacon, sweet Italian dressing.', TRUE,
 420, 30, 2.3, 0.0, 350, 60, 1.5, 60, 10.0, 0, 20, 1.2, 140, 10, 0.04),

-- Cheese Fries: 580 cal per serving (~250g). Per 100g: 232 cal, 5.6P, 24.8C, 12.8F
('portillos_cheese_fries', 'Portillo''s Cheese Fries', 232, 5.6, 24.8, 12.8,
 1.6, 1.2, 250, NULL,
 'portillos', ARRAY['portillos cheese fries', 'portillo''s cheese fries'],
 'american', 'Portillo''s', 1, '232 cal/100g. Per serving (~250g): 580 cal. Crinkle fries with melted cheddar cheese sauce.', TRUE,
 480, 12, 5.2, 0.1, 350, 80, 0.8, 12, 5.0, 0, 16, 0.8, 80, 3, 0.01),

-- Chocolate Cake Shake (small): 850 cal per small (~400g). Per 100g: 213 cal, 3.0P, 29.3C, 9.8F
('portillos_chocolate_cake_shake', 'Portillo''s Chocolate Cake Shake', 213, 3.0, 29.3, 9.8,
 1.3, 22.5, 400, NULL,
 'portillos', ARRAY['portillos chocolate cake shake', 'portillo''s cake shake'],
 'american', 'Portillo''s', 1, '213 cal/100g. Per small (~400g): 850 cal. Chocolate cake blended with vanilla milkshake.', TRUE,
 180, 30, 5.8, 0.2, 350, 100, 2.0, 30, 0.5, 10, 25, 0.8, 120, 5, 0.02),

-- Large Fries: 440 cal per large (~200g). Per 100g: 220 cal, 3.5P, 30.0C, 10.0F
('portillos_fries', 'Portillo''s Crinkle Cut Fries', 220, 3.5, 30.0, 10.0,
 2.0, 0.5, 200, NULL,
 'portillos', ARRAY['portillos fries', 'portillo''s french fries', 'portillos crinkle fries'],
 'american', 'Portillo''s', 1, '220 cal/100g. Per large (~200g): 440 cal. Crinkle-cut fries.', TRUE,
 320, 0, 1.5, 0.0, 380, 8, 0.6, 0, 6.0, 0, 18, 0.3, 50, 2, 0.01),

-- Onion Rings: 500 cal per serving (~180g). Per 100g: 278 cal, 4.4P, 32.2C, 14.4F
('portillos_onion_rings', 'Portillo''s Onion Rings', 278, 4.4, 32.2, 14.4,
 1.7, 4.4, 180, NULL,
 'portillos', ARRAY['portillos onion rings', 'portillo''s onion rings'],
 'american', 'Portillo''s', 1, '278 cal/100g. Per serving (~180g): 500 cal. Beer-battered onion rings.', TRUE,
 420, 5, 2.8, 0.2, 180, 20, 1.0, 0, 3.0, 0, 12, 0.3, 40, 2, 0.01),

-- Maxwell Street Polish: 450 cal per sausage (~200g). Per 100g: 225 cal, 10.0P, 13.5C, 14.5F
('portillos_maxwell_polish', 'Portillo''s Maxwell Street Polish', 225, 10.0, 13.5, 14.5,
 0.5, 2.5, 200, 200,
 'portillos', ARRAY['portillos maxwell street polish', 'portillo''s polish sausage'],
 'american', 'Portillo''s', 1, '225 cal/100g. Per sausage (~200g): 450 cal. Grilled Polish sausage, grilled onions, mustard, bun.', TRUE,
 540, 40, 5.5, 0.1, 250, 25, 2.0, 5, 3.0, 0, 14, 2.0, 120, 10, 0.03),

-- Italian Sausage: 560 cal per sandwich (~280g). Per 100g: 200 cal, 10.0P, 12.5C, 12.1F
('portillos_italian_sausage', 'Portillo''s Italian Sausage Sandwich', 200, 10.0, 12.5, 12.1,
 0.7, 2.1, 280, NULL,
 'portillos', ARRAY['portillos italian sausage', 'portillo''s sausage sandwich'],
 'american', 'Portillo''s', 1, '200 cal/100g. Per sandwich (~280g): 560 cal. Italian sausage, peppers, onions, French bread.', TRUE,
 520, 40, 4.3, 0.1, 300, 30, 2.5, 10, 8.0, 0, 18, 2.0, 140, 12, 0.03),

-- Chicken Parmesan Sandwich: 650 cal per sandwich (~300g). Per 100g: 217 cal, 12.0P, 16.7C, 11.0F
('portillos_chicken_parm', 'Portillo''s Chicken Parmesan Sandwich', 217, 12.0, 16.7, 11.0,
 1.0, 3.0, 300, NULL,
 'portillos', ARRAY['portillos chicken parmesan', 'portillo''s chicken parm sandwich'],
 'american', 'Portillo''s', 1, '217 cal/100g. Per sandwich (~300g): 650 cal. Breaded chicken, marinara, mozzarella, French bread.', TRUE,
 500, 35, 4.0, 0.1, 280, 100, 2.0, 25, 4.0, 0, 20, 1.5, 180, 14, 0.03),

-- ==========================================
-- WHATABURGER (New Chain)
-- ==========================================

-- Whataburger: 590 cal per burger (~316g). Per 100g: 187 cal, 9.5P, 14.6C, 9.8F
('wb_whataburger', 'Whataburger', 187, 9.5, 14.6, 9.8,
 0.6, 3.2, 316, NULL,
 'whataburger', ARRAY['whataburger original', 'whataburger classic', 'whataburger burger'],
 'fast_food', 'Whataburger', 1, '187 cal/100g. Per burger (~316g): 590 cal. 100% beef patty, mustard, lettuce, tomato, pickles, onion, 5-inch bun.', TRUE,
 450, 40, 4.1, 0.3, 310, 60, 3.0, 15, 4.0, 0, 24, 3.5, 180, 16, 0.03),

-- Whataburger Jr: 310 cal per burger (~160g). Per 100g: 194 cal, 10.0P, 15.0C, 10.0F
('wb_whataburger_jr', 'Whataburger Jr', 194, 10.0, 15.0, 10.0,
 0.6, 3.1, 160, NULL,
 'whataburger', ARRAY['whataburger junior', 'whataburger jr'],
 'fast_food', 'Whataburger', 1, '194 cal/100g. Per burger (~160g): 310 cal. Smaller version of the original Whataburger.', TRUE,
 420, 25, 4.4, 0.2, 260, 50, 2.5, 10, 3.0, 0, 20, 2.5, 140, 12, 0.03),

-- Patty Melt: 950 cal per melt (354g). Per 100g: 268 cal, 13.8P, 12.7C, 17.2F
('wb_patty_melt', 'Whataburger Patty Melt', 268, 13.8, 12.7, 17.2,
 0.6, 1.7, 354, NULL,
 'whataburger', ARRAY['whataburger patty melt', 'whataburger pattymelt'],
 'fast_food', 'Whataburger', 1, '268 cal/100g. Per melt (354g): 950 cal, 61F, 45C, 49P. Two beef patties, grilled onions, cheese, creamy pepper sauce, Texas toast.', TRUE,
 497, 35, 5.9, 0.6, 340, 100, 3.5, 25, 2.0, 0, 26, 4.5, 220, 18, 0.04),

-- Honey BBQ Chicken Strip Sandwich: 720 cal per sandwich (~280g). Per 100g: 257 cal, 10.7P, 22.9C, 13.6F
('wb_honey_bbq_chicken_strip', 'Whataburger Honey BBQ Chicken Strip Sandwich', 257, 10.7, 22.9, 13.6,
 0.7, 7.1, 280, NULL,
 'whataburger', ARRAY['whataburger honey bbq chicken strip sandwich', 'whataburger bbq chicken sandwich'],
 'fast_food', 'Whataburger', 1, '257 cal/100g. Per sandwich (~280g): 720 cal. Chicken strips, honey BBQ sauce, lettuce, tomato, bun.', TRUE,
 520, 35, 3.2, 0.2, 280, 30, 2.0, 10, 4.0, 0, 20, 1.2, 160, 14, 0.03),

-- Monterey Melt: 880 cal per melt (~330g). Per 100g: 267 cal, 12.7P, 12.4C, 18.8F
('wb_monterey_melt', 'Whataburger Monterey Melt', 267, 12.7, 12.4, 18.8,
 0.6, 2.1, 330, NULL,
 'whataburger', ARRAY['whataburger monterey melt'],
 'fast_food', 'Whataburger', 1, '267 cal/100g. Per melt (~330g): 880 cal. Two beef patties, Monterey Jack, grilled jalapeños and onions, Texas toast.', TRUE,
 480, 55, 7.6, 0.5, 340, 120, 3.5, 25, 3.0, 0, 26, 4.0, 210, 18, 0.04),

-- Breakfast on a Bun: 370 cal per bun (~170g). Per 100g: 218 cal, 10.6P, 15.3C, 12.9F
('wb_breakfast_on_a_bun', 'Whataburger Breakfast on a Bun', 218, 10.6, 15.3, 12.9,
 0.6, 2.4, 170, 170,
 'whataburger', ARRAY['whataburger breakfast on a bun', 'whataburger breakfast bun'],
 'fast_food', 'Whataburger', 1, '218 cal/100g. Per bun (~170g): 370 cal. Egg, sausage or bacon, cheese, toasted bun.', TRUE,
 500, 130, 5.3, 0.2, 200, 60, 2.0, 40, 0.0, 5, 14, 1.5, 150, 14, 0.04),

-- Taquito with Cheese: 380 cal per taquito (~160g). Per 100g: 238 cal, 10.6P, 17.5C, 13.8F
('wb_taquito_cheese', 'Whataburger Taquito with Cheese', 238, 10.6, 17.5, 13.8,
 0.6, 1.3, 160, 160,
 'whataburger', ARRAY['whataburger taquito with cheese', 'whataburger taquito'],
 'fast_food', 'Whataburger', 1, '238 cal/100g. Per taquito (~160g): 380 cal. Flour tortilla, egg, sausage or bacon, cheese.', TRUE,
 520, 120, 5.6, 0.2, 180, 80, 2.0, 40, 0.0, 5, 14, 1.5, 150, 14, 0.04),

-- Onion Rings (medium): 420 cal per medium (~150g). Per 100g: 280 cal, 4.0P, 34.0C, 14.0F
('wb_onion_rings', 'Whataburger Onion Rings', 280, 4.0, 34.0, 14.0,
 2.0, 4.0, 150, NULL,
 'whataburger', ARRAY['whataburger onion rings'],
 'fast_food', 'Whataburger', 1, '280 cal/100g. Per medium (~150g): 420 cal. Crispy battered onion rings.', TRUE,
 420, 5, 3.3, 0.2, 160, 20, 1.0, 0, 3.0, 0, 12, 0.3, 40, 2, 0.01),

-- Texas Toast: 150 cal per slice (~50g). Per 100g: 300 cal, 6.0P, 36.0C, 14.0F
('wb_texas_toast', 'Whataburger Texas Toast', 300, 6.0, 36.0, 14.0,
 1.0, 3.0, 50, 50,
 'whataburger', ARRAY['whataburger texas toast'],
 'fast_food', 'Whataburger', 1, '300 cal/100g. Per slice (~50g): 150 cal. Thick-cut buttered and griddled white bread.', TRUE,
 320, 5, 3.0, 0.1, 50, 30, 1.5, 10, 0.0, 0, 8, 0.4, 40, 6, 0.01),

-- Honey Butter Chicken Biscuit: 755 cal per biscuit (~230g). Per 100g: 328 cal, 7.0P, 30.9C, 20.0F
('wb_honey_butter_chicken_biscuit', 'Whataburger Honey Butter Chicken Biscuit', 328, 7.0, 30.9, 20.0,
 1.7, 3.9, 230, 230,
 'whataburger', ARRAY['whataburger honey butter chicken biscuit', 'whataburger hbcb', 'honey butter chicken biscuit'],
 'fast_food', 'Whataburger', 1, '328 cal/100g. Per biscuit (~230g): 755 cal, 46F, 71C, 16P. Crispy chicken strip, honey butter sauce, buttermilk biscuit.', TRUE,
 652, 11, 5.7, 0.2, 200, 40, 2.5, 15, 0.0, 0, 14, 0.8, 100, 10, 0.02),

-- Avocado Bacon Burger: 815 cal per burger (~310g). Per 100g: 263 cal, 12.3P, 12.9C, 18.4F
('wb_avocado_bacon_burger', 'Whataburger Avocado Bacon Burger', 263, 12.3, 12.9, 18.4,
 1.3, 2.6, 310, NULL,
 'whataburger', ARRAY['whataburger avocado bacon burger', 'whataburger avocado burger'],
 'fast_food', 'Whataburger', 1, '263 cal/100g. Per burger (~310g): 815 cal. Beef patty, avocado, bacon, cheese, lettuce, tomato, bun.', TRUE,
 460, 50, 7.1, 0.3, 380, 80, 3.0, 20, 4.0, 0, 28, 3.5, 200, 16, 0.06),

-- Green Chile Double: 920 cal per burger (~340g). Per 100g: 271 cal, 13.8P, 11.8C, 18.8F
('wb_green_chile_double', 'Whataburger Green Chile Double', 271, 13.8, 11.8, 18.8,
 0.6, 2.1, 340, NULL,
 'whataburger', ARRAY['whataburger green chile double', 'green chile burger whataburger'],
 'fast_food', 'Whataburger', 1, '271 cal/100g. Per burger (~340g): 920 cal. Two beef patties, green chiles, Monterey Jack, jalapeño ranch.', TRUE,
 490, 60, 7.6, 0.5, 340, 110, 3.5, 25, 5.0, 0, 26, 4.0, 210, 18, 0.04),

-- ==========================================
-- TORCHY'S TACOS (New Chain)
-- ==========================================

-- Trailer Park Taco: 320 cal per taco (~130g). Per 100g: 246 cal, 12.3P, 16.9C, 14.6F
('torchys_trailer_park', 'Torchy''s Tacos Trailer Park', 246, 12.3, 16.9, 14.6,
 1.5, 1.5, 130, 130,
 'torchys', ARRAY['torchys trailer park', 'torchy''s trailer park taco'],
 'mexican', 'Torchy''s Tacos', 1, '246 cal/100g. Per taco (~130g): 320 cal. Fried chicken, green chiles, lettuce, pico, cheese, flour tortilla.', TRUE,
 420, 35, 5.4, 0.2, 200, 60, 1.5, 20, 3.0, 0, 16, 1.2, 120, 10, 0.03),

-- Democrat Taco: 200 cal per taco (~120g). Per 100g: 167 cal, 5.8P, 25.0C, 5.0F
('torchys_democrat', 'Torchy''s Tacos Democrat', 167, 5.8, 25.0, 5.0,
 3.3, 2.5, 120, 120,
 'torchys', ARRAY['torchys democrat', 'torchy''s democrat taco'],
 'mexican', 'Torchy''s Tacos', 1, '167 cal/100g. Per taco (~120g): 200 cal. Jamaican jerk chicken, grilled jalapeños, corn, cilantro, corn tortilla.', TRUE,
 340, 20, 1.3, 0.0, 250, 30, 1.0, 15, 5.0, 0, 18, 0.8, 100, 8, 0.03),

-- Crossroads Taco: 360 cal per taco (~140g). Per 100g: 257 cal, 11.4P, 18.6C, 15.0F
('torchys_crossroads', 'Torchy''s Tacos Crossroads', 257, 11.4, 18.6, 15.0,
 1.4, 1.4, 140, 140,
 'torchys', ARRAY['torchys crossroads', 'torchy''s crossroads taco'],
 'mexican', 'Torchy''s Tacos', 1, '257 cal/100g. Per taco (~140g): 360 cal. Smoked beef brisket, jalapeño, cheese, onions, corn tortilla.', TRUE,
 380, 35, 5.7, 0.2, 250, 60, 2.0, 15, 3.0, 0, 18, 2.5, 130, 10, 0.04),

-- Tipsy Chick Taco: 350 cal per taco (~140g). Per 100g: 250 cal, 12.1P, 17.9C, 14.3F
('torchys_tipsy_chick', 'Torchy''s Tacos Tipsy Chick', 250, 12.1, 17.9, 14.3,
 1.4, 2.1, 140, 140,
 'torchys', ARRAY['torchys tipsy chick', 'torchy''s tipsy chick taco'],
 'mexican', 'Torchy''s Tacos', 1, '250 cal/100g. Per taco (~140g): 350 cal. Marinated grilled chicken, cheese, cabbage, jalapeño, lime, flour tortilla.', TRUE,
 380, 30, 5.0, 0.1, 220, 50, 1.5, 15, 5.0, 0, 16, 1.0, 120, 10, 0.03),

-- Baja Shrimp Taco: 310 cal per taco (~130g). Per 100g: 238 cal, 10.8P, 17.7C, 13.8F
('torchys_baja_shrimp', 'Torchy''s Tacos Baja Shrimp', 238, 10.8, 17.7, 13.8,
 1.5, 1.5, 130, 130,
 'torchys', ARRAY['torchys baja shrimp', 'torchy''s baja shrimp taco'],
 'mexican', 'Torchy''s Tacos', 1, '238 cal/100g. Per taco (~130g): 310 cal. Grilled shrimp, slaw, pickled onions, avocado, flour tortilla.', TRUE,
 360, 40, 3.8, 0.1, 220, 40, 1.0, 20, 5.0, 0, 20, 0.8, 120, 12, 0.08),

-- Green Chile Queso: 380 cal per cup (~180g). Per 100g: 211 cal, 7.8P, 8.9C, 16.1F
('torchys_green_chile_queso', 'Torchy''s Tacos Green Chile Queso', 211, 7.8, 8.9, 16.1,
 0.6, 2.2, 180, NULL,
 'torchys', ARRAY['torchys queso', 'torchy''s green chile queso', 'torchys green chile queso'],
 'mexican', 'Torchy''s Tacos', 1, '211 cal/100g. Per cup (~180g): 380 cal. Creamy cheese dip with roasted green chiles, guacamole, queso fresco.', TRUE,
 480, 30, 9.4, 0.2, 150, 150, 0.5, 40, 3.0, 0, 14, 1.0, 140, 5, 0.02),

-- Chips & Queso: 600 cal per serving (~250g). Per 100g: 240 cal, 5.6P, 20.0C, 15.6F
('torchys_chips_queso', 'Torchy''s Tacos Chips & Queso', 240, 5.6, 20.0, 15.6,
 1.2, 1.6, 250, NULL,
 'torchys', ARRAY['torchys chips and queso', 'torchy''s chips queso'],
 'mexican', 'Torchy''s Tacos', 1, '240 cal/100g. Per serving (~250g): 600 cal. Tortilla chips with green chile queso.', TRUE,
 500, 20, 7.2, 0.2, 200, 100, 1.0, 25, 2.0, 0, 16, 0.8, 100, 4, 0.02),

-- Guacamole: 230 cal per side (~120g). Per 100g: 192 cal, 2.5P, 10.0C, 16.7F
('torchys_guacamole', 'Torchy''s Tacos Guacamole', 192, 2.5, 10.0, 16.7,
 5.0, 1.7, 120, NULL,
 'torchys', ARRAY['torchys guacamole', 'torchy''s guac'],
 'mexican', 'Torchy''s Tacos', 1, '192 cal/100g. Per side (~120g): 230 cal. Fresh-made guacamole.', TRUE,
 200, 0, 2.5, 0.0, 400, 10, 0.5, 5, 8.0, 0, 20, 0.4, 35, 1, 0.05),

-- Diablo Sauce: 15 cal per oz (~30g). Per 100g: 50 cal, 0.3P, 10.0C, 1.0F
('torchys_diablo_sauce', 'Torchy''s Tacos Diablo Sauce', 50, 0.3, 10.0, 1.0,
 0.7, 6.7, 30, NULL,
 'torchys', ARRAY['torchys diablo sauce', 'torchy''s diablo', 'diablo hot sauce'],
 'mexican', 'Torchy''s Tacos', 1, '50 cal/100g. Per oz (~30g): 15 cal. Signature habanero-based hot sauce.', TRUE,
 500, 0, 0.1, 0.0, 60, 5, 0.3, 30, 20.0, 0, 5, 0.1, 10, 0, 0.01),

-- Trashy Trailer Park: 380 cal per taco (~140g). Per 100g: 271 cal, 13.6P, 15.7C, 17.1F
('torchys_trashy_trailer_park', 'Torchy''s Tacos Trashy Trailer Park', 271, 13.6, 15.7, 17.1,
 1.4, 1.4, 140, 140,
 'torchys', ARRAY['torchys trashy', 'torchy''s trashy trailer park taco'],
 'mexican', 'Torchy''s Tacos', 1, '271 cal/100g. Per taco (~140g): 380 cal. Fried chicken, green chiles, queso, lettuce, pico, cheese, flour tortilla.', TRUE,
 440, 40, 6.4, 0.2, 210, 80, 1.5, 20, 3.0, 0, 16, 1.2, 130, 10, 0.03),

-- ==========================================
-- ZAXBY'S (New Chain)
-- ==========================================

-- Chicken Fingerz (5pc): 640 cal per 5pc (~220g). Per 100g: 291 cal, 18.2P, 16.4C, 17.3F
('zaxbys_chicken_fingerz', 'Zaxby''s Chicken Fingerz (5pc)', 291, 18.2, 16.4, 17.3,
 0.5, 0.5, 220, 44,
 'zaxbys', ARRAY['zaxbys chicken fingerz', 'zaxby''s chicken fingers', 'zaxbys fingerz'],
 'chicken', 'Zaxby''s', 1, '291 cal/100g. Per 5pc (~220g): 640 cal. Hand-breaded chicken tenders.', TRUE,
 540, 45, 3.6, 0.2, 260, 15, 1.5, 5, 0.0, 0, 18, 1.0, 170, 16, 0.03),

-- Boneless Wings Meal: 780 cal per meal (~300g). Per 100g: 260 cal, 14.0P, 18.3C, 14.7F
('zaxbys_boneless_wings_meal', 'Zaxby''s Boneless Wings Meal', 260, 14.0, 18.3, 14.7,
 0.7, 2.0, 300, NULL,
 'zaxbys', ARRAY['zaxbys boneless wings meal', 'zaxby''s boneless wings'],
 'chicken', 'Zaxby''s', 1, '260 cal/100g. Per meal (~300g): 780 cal. Boneless chicken, Texas toast, crinkle fries, Zax Sauce.', TRUE,
 580, 40, 3.7, 0.2, 260, 20, 2.0, 5, 2.0, 0, 18, 1.0, 160, 14, 0.03),

-- Zax Sauce (1 cup): 180 cal per cup (~50g). Per 100g: 360 cal, 0.0P, 16.0C, 34.0F
('zaxbys_zax_sauce', 'Zaxby''s Zax Sauce', 360, 0.0, 16.0, 34.0,
 0.0, 12.0, 50, NULL,
 'zaxbys', ARRAY['zaxbys zax sauce', 'zaxby''s signature sauce', 'zax sauce'],
 'chicken', 'Zaxby''s', 1, '360 cal/100g. Per cup (~50g): 180 cal. Signature tangy dipping sauce.', TRUE,
 400, 20, 5.0, 0.0, 20, 5, 0.1, 5, 1.0, 0, 2, 0.1, 10, 1, 0.01),

-- Crinkle Fries: 360 cal per regular (~150g). Per 100g: 240 cal, 3.3P, 30.7C, 12.0F
('zaxbys_crinkle_fries', 'Zaxby''s Crinkle Fries', 240, 3.3, 30.7, 12.0,
 2.0, 0.0, 150, NULL,
 'zaxbys', ARRAY['zaxbys fries', 'zaxby''s crinkle fries'],
 'chicken', 'Zaxby''s', 1, '240 cal/100g. Per regular (~150g): 360 cal. Crinkle-cut fries.', TRUE,
 320, 0, 2.0, 0.0, 380, 8, 0.6, 0, 6.0, 0, 18, 0.3, 50, 2, 0.01),

-- Texas Toast: 150 cal per slice (~50g). Per 100g: 300 cal, 6.0P, 38.0C, 14.0F
('zaxbys_texas_toast', 'Zaxby''s Texas Toast', 300, 6.0, 38.0, 14.0,
 1.0, 3.0, 50, 50,
 'zaxbys', ARRAY['zaxbys texas toast', 'zaxby''s toast'],
 'chicken', 'Zaxby''s', 1, '300 cal/100g. Per slice (~50g): 150 cal. Thick-cut buttered and toasted white bread.', TRUE,
 320, 5, 3.0, 0.1, 50, 30, 1.5, 10, 0.0, 0, 8, 0.4, 40, 6, 0.01),

-- Kickin Chicken Sandwich: 690 cal per sandwich (~280g). Per 100g: 246 cal, 12.5P, 17.9C, 13.9F
('zaxbys_kickin_chicken', 'Zaxby''s Kickin'' Chicken Sandwich', 246, 12.5, 17.9, 13.9,
 0.7, 2.5, 280, NULL,
 'zaxbys', ARRAY['zaxbys kickin chicken sandwich', 'zaxby''s kickin chicken'],
 'chicken', 'Zaxby''s', 1, '246 cal/100g. Per sandwich (~280g): 690 cal. Chicken fingerz, Tongue Torch sauce, ranch, Texas toast.', TRUE,
 560, 40, 3.6, 0.2, 260, 25, 2.0, 10, 2.0, 0, 18, 1.0, 160, 14, 0.03),

-- Caesar Zalad: 460 cal per salad (~340g). Per 100g: 135 cal, 10.0P, 6.5C, 8.2F
('zaxbys_caesar_zalad', 'Zaxby''s Caesar Zalad', 135, 10.0, 6.5, 8.2,
 1.5, 1.5, 340, NULL,
 'zaxbys', ARRAY['zaxbys caesar zalad', 'zaxby''s caesar salad'],
 'chicken', 'Zaxby''s', 1, '135 cal/100g. Per salad (~340g): 460 cal. Romaine, grilled chicken, parmesan, croutons, Caesar dressing.', TRUE,
 480, 35, 3.2, 0.1, 300, 80, 1.5, 80, 6.0, 0, 18, 1.5, 150, 12, 0.04),

-- Cobb Zalad: 580 cal per salad (~380g). Per 100g: 153 cal, 11.1P, 4.5C, 10.3F
('zaxbys_cobb_zalad', 'Zaxby''s Cobb Zalad', 153, 11.1, 4.5, 10.3,
 1.6, 2.1, 380, NULL,
 'zaxbys', ARRAY['zaxbys cobb zalad', 'zaxby''s cobb salad'],
 'chicken', 'Zaxby''s', 1, '153 cal/100g. Per salad (~380g): 580 cal. Mixed greens, fried chicken, bacon, egg, cheese, tomato, ranch.', TRUE,
 520, 50, 4.2, 0.1, 380, 80, 1.5, 80, 10.0, 5, 22, 1.8, 180, 14, 0.04),

-- Blue Zalad: 520 cal per salad (~350g). Per 100g: 149 cal, 10.3P, 6.6C, 9.1F
('zaxbys_blue_zalad', 'Zaxby''s Blue Zalad', 149, 10.3, 6.6, 9.1,
 1.7, 3.4, 350, NULL,
 'zaxbys', ARRAY['zaxbys blue zalad', 'zaxby''s blue cheese salad'],
 'chicken', 'Zaxby''s', 1, '149 cal/100g. Per salad (~350g): 520 cal. Mixed greens, fried chicken, blue cheese, bacon, pecans, dried cranberries.', TRUE,
 480, 40, 3.7, 0.1, 350, 80, 1.2, 60, 8.0, 0, 20, 1.5, 150, 12, 0.08),

-- Fried White Cheddar Bites: 420 cal per serving (~150g). Per 100g: 280 cal, 10.0P, 22.7C, 16.7F
('zaxbys_white_cheddar_bites', 'Zaxby''s Fried White Cheddar Bites', 280, 10.0, 22.7, 16.7,
 0.7, 1.3, 150, NULL,
 'zaxbys', ARRAY['zaxbys fried white cheddar bites', 'zaxby''s cheese bites'],
 'chicken', 'Zaxby''s', 1, '280 cal/100g. Per serving (~150g): 420 cal. Breaded and fried white cheddar cheese bites.', TRUE,
 500, 30, 8.0, 0.3, 120, 150, 1.0, 25, 0.0, 0, 12, 1.2, 140, 5, 0.02),

-- ==========================================
-- COOK OUT (New Chain)
-- ==========================================

-- Big Double Burger: 620 cal per burger (~260g). Per 100g: 238 cal, 14.6P, 13.5C, 14.6F
('cookout_big_double', 'Cook Out Big Double Burger', 238, 14.6, 13.5, 14.6,
 0.8, 3.1, 260, NULL,
 'cook_out', ARRAY['cook out big double', 'cookout big double burger', 'cook out double burger'],
 'fast_food', 'Cook Out', 1, '238 cal/100g. Per burger (~260g): 620 cal. Two beef patties, American cheese, lettuce, tomato, bun.', TRUE,
 460, 60, 6.2, 0.5, 320, 80, 3.0, 20, 3.0, 0, 24, 4.0, 200, 16, 0.04),

-- Cook Out Tray: 1180 cal per tray (~500g). Per 100g: 236 cal, 11.6P, 18.0C, 13.0F
('cookout_tray', 'Cook Out Tray (Burger)', 236, 11.6, 18.0, 13.0,
 1.2, 4.0, 500, NULL,
 'cook_out', ARRAY['cook out tray', 'cookout tray', 'cook out combo tray'],
 'fast_food', 'Cook Out', 1, '236 cal/100g. Per tray (~500g): 1180 cal. Burger or sandwich + 2 sides + drink. Values for burger tray with fries and slaw.', TRUE,
 520, 50, 5.2, 0.4, 380, 60, 2.5, 15, 5.0, 0, 24, 3.0, 180, 14, 0.03),

-- Chicken Strips (3pc): 470 cal per 3pc (~180g). Per 100g: 261 cal, 16.7P, 15.6C, 14.4F
('cookout_chicken_strips', 'Cook Out Chicken Strips (3pc)', 261, 16.7, 15.6, 14.4,
 0.6, 0.6, 180, 60,
 'cook_out', ARRAY['cook out chicken strips', 'cookout chicken strips', 'cook out chicken tenders'],
 'fast_food', 'Cook Out', 1, '261 cal/100g. Per 3pc (~180g): 470 cal. Breaded chicken strips.', TRUE,
 500, 40, 3.3, 0.2, 250, 15, 1.5, 5, 0.0, 0, 18, 0.8, 150, 14, 0.03),

-- Quesadilla: 520 cal per quesadilla (~220g). Per 100g: 236 cal, 12.7P, 16.4C, 13.6F
('cookout_quesadilla', 'Cook Out Quesadilla', 236, 12.7, 16.4, 13.6,
 1.4, 1.4, 220, NULL,
 'cook_out', ARRAY['cook out quesadilla', 'cookout quesadilla'],
 'fast_food', 'Cook Out', 1, '236 cal/100g. Per quesadilla (~220g): 520 cal. Flour tortilla, chicken or beef, cheese.', TRUE,
 480, 40, 6.4, 0.2, 200, 140, 1.5, 25, 1.0, 0, 18, 2.0, 160, 10, 0.03),

-- Corn Dog: 280 cal per corn dog (~120g). Per 100g: 233 cal, 7.5P, 25.0C, 11.7F
('cookout_corn_dog', 'Cook Out Corn Dog', 233, 7.5, 25.0, 11.7,
 0.8, 5.0, 120, 120,
 'cook_out', ARRAY['cook out corn dog', 'cookout corn dog'],
 'fast_food', 'Cook Out', 1, '233 cal/100g. Per corn dog (~120g): 280 cal. Battered and fried hot dog on a stick.', TRUE,
 480, 25, 3.3, 0.2, 120, 30, 2.0, 5, 0.0, 0, 10, 1.0, 80, 8, 0.02),

-- Hush Puppies: 280 cal per serving (~100g). Per 100g: 280 cal, 4.0P, 34.0C, 14.0F
('cookout_hush_puppies', 'Cook Out Hush Puppies', 280, 4.0, 34.0, 14.0,
 1.5, 4.0, 100, NULL,
 'cook_out', ARRAY['cook out hush puppies', 'cookout hushpuppies'],
 'fast_food', 'Cook Out', 1, '280 cal/100g. Per serving (~100g): 280 cal. Deep-fried cornmeal batter balls.', TRUE,
 380, 10, 2.0, 0.1, 100, 20, 1.5, 5, 0.0, 0, 12, 0.4, 50, 4, 0.01),

-- Milkshake (Chocolate): 620 cal per shake (~450g). Per 100g: 138 cal, 2.7P, 20.4C, 5.3F
('cookout_chocolate_shake', 'Cook Out Chocolate Milkshake', 138, 2.7, 20.4, 5.3,
 0.4, 17.3, 450, NULL,
 'cook_out', ARRAY['cook out chocolate milkshake', 'cookout chocolate shake', 'cook out shake'],
 'fast_food', 'Cook Out', 1, '138 cal/100g. Per shake (~450g): 620 cal. Hand-spun milkshake, 40+ flavors available. Values for chocolate.', TRUE,
 120, 20, 3.3, 0.1, 320, 120, 0.5, 30, 1.0, 10, 18, 0.5, 110, 4, 0.02),

-- BBQ Sandwich: 340 cal per sandwich (~180g). Per 100g: 189 cal, 11.1P, 17.8C, 7.8F
('cookout_bbq_sandwich', 'Cook Out BBQ Sandwich', 189, 11.1, 17.8, 7.8,
 0.6, 8.3, 180, 180,
 'cook_out', ARRAY['cook out bbq sandwich', 'cookout bbq pork sandwich', 'cook out barbecue sandwich'],
 'fast_food', 'Cook Out', 1, '189 cal/100g. Per sandwich (~180g): 340 cal. Chopped BBQ pork, coleslaw, bun.', TRUE,
 480, 30, 2.8, 0.1, 250, 25, 1.5, 10, 3.0, 0, 15, 2.0, 130, 12, 0.03),

-- Cajun Chicken Sandwich: 480 cal per sandwich (~240g). Per 100g: 200 cal, 13.3P, 15.0C, 9.6F
('cookout_cajun_chicken', 'Cook Out Cajun Chicken Sandwich', 200, 13.3, 15.0, 9.6,
 0.8, 2.1, 240, NULL,
 'cook_out', ARRAY['cook out cajun chicken sandwich', 'cookout cajun chicken'],
 'fast_food', 'Cook Out', 1, '200 cal/100g. Per sandwich (~240g): 480 cal. Seasoned grilled chicken, lettuce, tomato, mayo, bun.', TRUE,
 460, 40, 2.5, 0.1, 300, 25, 1.5, 10, 4.0, 0, 22, 1.0, 170, 16, 0.03),

-- Onion Rings: 360 cal per side (~130g). Per 100g: 277 cal, 4.6P, 33.8C, 13.8F
('cookout_onion_rings', 'Cook Out Onion Rings', 277, 4.6, 33.8, 13.8,
 1.5, 3.8, 130, NULL,
 'cook_out', ARRAY['cook out onion rings', 'cookout onion rings'],
 'fast_food', 'Cook Out', 1, '277 cal/100g. Per side (~130g): 360 cal. Crispy battered onion rings.', TRUE,
 400, 5, 2.3, 0.2, 150, 20, 1.0, 0, 3.0, 0, 10, 0.3, 40, 2, 0.01),

-- ==========================================
-- SWEETGREEN (New Chain)
-- ==========================================

-- Harvest Bowl: 705 cal per bowl (~400g). Per 100g: 176 cal, 6.3P, 15.0C, 10.5F
('sg_harvest_bowl', 'Sweetgreen Harvest Bowl', 176, 6.3, 15.0, 10.5,
 2.5, 4.5, 400, NULL,
 'sweetgreen', ARRAY['sweetgreen harvest bowl', 'harvest bowl sweetgreen'],
 'healthy', 'Sweetgreen', 1, '176 cal/100g. Per bowl (~400g): 705 cal. Roasted chicken, roasted sweet potatoes, apples, goat cheese, wild rice, balsamic vinaigrette.', TRUE,
 380, 25, 2.5, 0.0, 450, 60, 2.0, 200, 10.0, 0, 35, 1.2, 150, 8, 0.06),

-- Kale Caesar: 405 cal per salad (~280g). Per 100g: 145 cal, 14.3P, 4.6C, 8.6F
('sg_kale_caesar', 'Sweetgreen Kale Caesar', 145, 14.3, 4.6, 8.6,
 1.8, 0.7, 280, NULL,
 'sweetgreen', ARRAY['sweetgreen kale caesar', 'kale caesar salad sweetgreen'],
 'healthy', 'Sweetgreen', 1, '145 cal/100g. Per salad (~280g): 405 cal, 24F, 13C, 40P. Baby kale, parmesan crisp, shaved parmesan, lemon chicken, lime cilantro jalapeño vinaigrette.', TRUE,
 476, 30, 3.6, 0.0, 400, 120, 2.0, 200, 25.0, 0, 35, 1.5, 180, 12, 0.05),

-- Chicken Pesto Parm: 660 cal per bowl (~380g). Per 100g: 174 cal, 11.8P, 10.5C, 9.5F
('sg_chicken_pesto_parm', 'Sweetgreen Chicken Pesto Parm', 174, 11.8, 10.5, 9.5,
 2.1, 2.1, 380, NULL,
 'sweetgreen', ARRAY['sweetgreen chicken pesto parm', 'chicken pesto parm sweetgreen'],
 'healthy', 'Sweetgreen', 1, '174 cal/100g. Per bowl (~380g): 660 cal. Roasted chicken, pesto, parmesan, warm grains, roasted vegetables.', TRUE,
 420, 30, 3.2, 0.0, 400, 100, 2.0, 80, 8.0, 0, 30, 1.5, 170, 12, 0.05),

-- Guacamole Greens: 580 cal per bowl (~380g). Per 100g: 153 cal, 5.3P, 11.1C, 10.0F
('sg_guacamole_greens', 'Sweetgreen Guacamole Greens', 153, 5.3, 11.1, 10.0,
 3.4, 2.4, 380, NULL,
 'sweetgreen', ARRAY['sweetgreen guacamole greens', 'guac greens sweetgreen'],
 'healthy', 'Sweetgreen', 1, '153 cal/100g. Per bowl (~380g): 580 cal. Avocado, black beans, corn, tomatoes, tortilla chips, warm greens.', TRUE,
 350, 5, 2.1, 0.0, 500, 40, 2.0, 40, 12.0, 0, 40, 0.8, 100, 4, 0.06),

-- Buffalo Chicken Bowl: 620 cal per bowl (~380g). Per 100g: 163 cal, 11.1P, 10.5C, 8.4F
('sg_buffalo_chicken_bowl', 'Sweetgreen Buffalo Chicken Bowl', 163, 11.1, 10.5, 8.4,
 2.1, 2.6, 380, NULL,
 'sweetgreen', ARRAY['sweetgreen buffalo chicken bowl', 'buffalo chicken sweetgreen'],
 'healthy', 'Sweetgreen', 1, '163 cal/100g. Per bowl (~380g): 620 cal. Blackened chicken, blue cheese, warm grains, romaine, buffalo sauce.', TRUE,
 520, 30, 2.6, 0.0, 380, 80, 1.5, 60, 8.0, 0, 28, 1.2, 160, 10, 0.04),

-- Crispy Rice Bowl: 710 cal per bowl (~400g). Per 100g: 178 cal, 7.5P, 16.3C, 9.5F
('sg_crispy_rice_bowl', 'Sweetgreen Crispy Rice Bowl', 178, 7.5, 16.3, 9.5,
 1.8, 3.5, 400, NULL,
 'sweetgreen', ARRAY['sweetgreen crispy rice bowl', 'crispy rice bowl sweetgreen'],
 'healthy', 'Sweetgreen', 1, '178 cal/100g. Per bowl (~400g): 710 cal. Blackened chicken, crispy rice, raw vegetables, spicy cashew dressing.', TRUE,
 440, 25, 2.3, 0.0, 380, 40, 1.5, 40, 8.0, 0, 30, 1.0, 140, 10, 0.04),

-- Hot Honey Chicken Plate: 680 cal per plate (~400g). Per 100g: 170 cal, 10.0P, 13.5C, 8.5F
('sg_hot_honey_chicken', 'Sweetgreen Hot Honey Chicken Plate', 170, 10.0, 13.5, 8.5,
 2.0, 5.0, 400, NULL,
 'sweetgreen', ARRAY['sweetgreen hot honey chicken', 'hot honey chicken plate sweetgreen'],
 'healthy', 'Sweetgreen', 1, '170 cal/100g. Per plate (~400g): 680 cal. Roasted chicken, hot honey drizzle, roasted sweet potatoes, warm grains.', TRUE,
 420, 30, 2.3, 0.0, 400, 40, 1.5, 150, 8.0, 0, 30, 1.0, 150, 10, 0.04),

-- Shroomami: 590 cal per bowl (~380g). Per 100g: 155 cal, 5.8P, 15.8C, 8.2F
('sg_shroomami', 'Sweetgreen Shroomami', 155, 5.8, 15.8, 8.2,
 2.6, 2.9, 380, NULL,
 'sweetgreen', ARRAY['sweetgreen shroomami', 'shroomami bowl sweetgreen'],
 'healthy', 'Sweetgreen', 1, '155 cal/100g. Per bowl (~380g): 590 cal. Roasted portobello mushrooms, warm grains, raw vegetables, miso sesame ginger dressing.', TRUE,
 380, 0, 1.3, 0.0, 450, 30, 2.0, 30, 6.0, 20, 35, 1.0, 120, 8, 0.04),

-- Caesar Wrap: 560 cal per wrap (~300g). Per 100g: 187 cal, 10.7P, 13.3C, 10.0F
('sg_caesar_wrap', 'Sweetgreen Caesar Wrap', 187, 10.7, 13.3, 10.0,
 1.7, 1.3, 300, NULL,
 'sweetgreen', ARRAY['sweetgreen caesar wrap', 'caesar wrap sweetgreen'],
 'healthy', 'Sweetgreen', 1, '187 cal/100g. Per wrap (~300g): 560 cal. Romaine, roasted chicken, parmesan, Caesar dressing, warm tortilla.', TRUE,
 460, 30, 3.3, 0.0, 350, 100, 2.0, 80, 6.0, 0, 22, 1.5, 160, 12, 0.04),

-- Side Salad: 120 cal per salad (~150g). Per 100g: 80 cal, 2.0P, 5.3C, 5.7F
('sg_side_salad', 'Sweetgreen Side Salad', 80, 2.0, 5.3, 5.7,
 1.3, 2.0, 150, NULL,
 'sweetgreen', ARRAY['sweetgreen side salad'],
 'healthy', 'Sweetgreen', 1, '80 cal/100g. Per salad (~150g): 120 cal. Simple mixed greens with vinaigrette.', TRUE,
 180, 0, 0.7, 0.0, 200, 30, 0.8, 80, 10.0, 0, 15, 0.3, 30, 1, 0.03),

-- ==========================================
-- JASON'S DELI (New Chain)
-- ==========================================

-- Ham & Salami Muffuletta (half): 1016 cal per half (~400g). Per 100g: 254 cal, 13.3P, 20.9C, 13.6F
('jd_muffuletta_half', 'Jason''s Deli Muffuletta (Half)', 254, 13.3, 20.9, 13.6,
 1.4, 2.5, 400, NULL,
 'jasons_deli', ARRAY['jasons deli muffuletta', 'jason''s deli new orleans muffaletta', 'jd muffuletta'],
 'american', 'Jason''s Deli', 1, '254 cal/100g. Per half (~400g): 1016 cal. Whole: 2032 cal, 109F, 167C, 106P. Ham, salami, provolone, olive mix, round muffuletta bread.', TRUE,
 1061, 27, 3.1, 0.1, 280, 120, 3.0, 15, 3.0, 0, 22, 3.0, 200, 14, 0.04),

-- Roasted Turkey Muffuletta (half): 986 cal per half (~400g). Per 100g: 247 cal, 14.0P, 20.5C, 12.3F
('jd_turkey_muffuletta_half', 'Jason''s Deli Turkey Muffuletta (Half)', 247, 14.0, 20.5, 12.3,
 1.3, 2.3, 400, NULL,
 'jasons_deli', ARRAY['jasons deli turkey muffuletta', 'jason''s deli roasted turkey muffaletta'],
 'american', 'Jason''s Deli', 1, '247 cal/100g. Per half (~400g): 986 cal. Whole: 1972 cal. Roasted turkey, provolone, olive mix, muffuletta bread.', TRUE,
 980, 24, 2.8, 0.1, 290, 110, 2.5, 10, 2.0, 0, 22, 2.5, 200, 16, 0.03),

-- Chicken Club Wrap: 550 cal per wrap (~280g). Per 100g: 196 cal, 12.5P, 13.2C, 10.4F
('jd_chicken_club_wrap', 'Jason''s Deli Chicken Club Wrap', 196, 12.5, 13.2, 10.4,
 1.4, 2.1, 280, NULL,
 'jasons_deli', ARRAY['jasons deli chicken club wrap', 'jason''s deli chicken wrap'],
 'american', 'Jason''s Deli', 1, '196 cal/100g. Per wrap (~280g): 550 cal. Grilled chicken, bacon, lettuce, tomato, cheese, ranch, flour tortilla.', TRUE,
 520, 40, 3.9, 0.1, 280, 80, 1.5, 30, 4.0, 0, 20, 1.5, 170, 14, 0.03),

-- Turkey Wrap: 380 cal per wrap (~250g). Per 100g: 152 cal, 10.8P, 12.8C, 6.4F
('jd_turkey_wrap', 'Jason''s Deli Turkey Wrap', 152, 10.8, 12.8, 6.4,
 1.6, 2.0, 250, NULL,
 'jasons_deli', ARRAY['jasons deli turkey wrap', 'jason''s deli turkey wrap'],
 'american', 'Jason''s Deli', 1, '152 cal/100g. Per wrap (~250g): 380 cal. Roasted turkey, lettuce, tomato, Swiss, honey mustard, flour tortilla.', TRUE,
 460, 30, 2.4, 0.0, 300, 60, 1.2, 20, 3.0, 0, 18, 1.5, 160, 14, 0.03),

-- Broccoli Cheese Soup (bowl): 385 cal per bowl (~340g). Per 100g: 113 cal, 4.7P, 5.9C, 7.9F
('jd_broccoli_cheese_soup', 'Jason''s Deli Broccoli Cheese Soup', 113, 4.7, 5.9, 7.9,
 0.9, 1.8, 340, NULL,
 'jasons_deli', ARRAY['jasons deli broccoli cheese soup', 'jason''s deli broccoli cheddar soup'],
 'american', 'Jason''s Deli', 1, '113 cal/100g. Per bowl (~340g): 385 cal, 27F, 19C. Creamy broccoli cheddar cheese soup.', TRUE,
 440, 25, 5.0, 0.1, 250, 120, 0.8, 40, 10.0, 0, 15, 0.8, 120, 4, 0.03),

-- Organic Tomato Basil Soup (bowl): 511 cal per bowl (~380g). Per 100g: 134 cal, 2.6P, 12.6C, 8.2F
('jd_tomato_basil_soup', 'Jason''s Deli Organic Tomato Basil Soup', 134, 2.6, 12.6, 8.2,
 1.6, 6.3, 380, NULL,
 'jasons_deli', ARRAY['jasons deli tomato basil soup', 'jason''s deli organic tomato soup'],
 'american', 'Jason''s Deli', 1, '134 cal/100g. Per bowl (~380g): 511 cal. Organic tomatoes, basil, cream.', TRUE,
 360, 15, 4.2, 0.1, 350, 40, 1.5, 50, 15.0, 0, 15, 0.3, 40, 2, 0.02),

-- Reuben The Great: 881 cal per sandwich (~380g). Per 100g: 232 cal, 12.6P, 14.2C, 14.5F
('jd_reuben_the_great', 'Jason''s Deli Reuben The Great', 232, 12.6, 14.2, 14.5,
 1.3, 2.6, 380, NULL,
 'jasons_deli', ARRAY['jasons deli reuben', 'jason''s deli reuben the great'],
 'american', 'Jason''s Deli', 1, '232 cal/100g. Per sandwich (~380g): 881 cal. Corned beef, Swiss, sauerkraut, 1000 Island, rye bread.', TRUE,
 650, 60, 5.8, 0.3, 300, 120, 2.5, 10, 5.0, 0, 18, 3.0, 180, 12, 0.04),

-- Salad Bar (typical plate): 350 cal per plate (~300g). Per 100g: 117 cal, 5.0P, 8.3C, 7.0F
('jd_salad_bar', 'Jason''s Deli Salad Bar (Typical Plate)', 117, 5.0, 8.3, 7.0,
 2.3, 3.0, 300, NULL,
 'jasons_deli', ARRAY['jasons deli salad bar', 'jason''s deli all you can eat salad bar'],
 'american', 'Jason''s Deli', 1, '117 cal/100g. Per plate (~300g): 350 cal. Estimated for a typical plate with mixed greens, vegetables, cheese, light dressing from their organic salad bar.', TRUE,
 280, 10, 2.3, 0.0, 350, 60, 1.5, 150, 15.0, 0, 25, 0.8, 80, 3, 0.05),

-- Lighter Reuben: 611 cal per sandwich (~300g). Per 100g: 204 cal, 13.0P, 14.0C, 10.7F
('jd_lighter_reuben', 'Jason''s Deli Lighter Reuben', 204, 13.0, 14.0, 10.7,
 1.3, 2.3, 300, NULL,
 'jasons_deli', ARRAY['jasons deli lighter reuben', 'jason''s deli lighter reuben the great'],
 'american', 'Jason''s Deli', 1, '204 cal/100g. Per sandwich (~300g): 611 cal. Lighter version of Reuben with less meat and dressing.', TRUE,
 550, 45, 4.3, 0.2, 280, 100, 2.0, 8, 4.0, 0, 16, 2.5, 160, 10, 0.03),

-- Chicken Alfredo Pasta: 810 cal per serving (~380g). Per 100g: 213 cal, 10.5P, 18.4C, 10.8F
('jd_chicken_alfredo', 'Jason''s Deli Chicken Alfredo Pasta', 213, 10.5, 18.4, 10.8,
 1.1, 1.8, 380, NULL,
 'jasons_deli', ARRAY['jasons deli chicken alfredo', 'jason''s deli alfredo pasta'],
 'american', 'Jason''s Deli', 1, '213 cal/100g. Per serving (~380g): 810 cal. Grilled chicken, fettuccine, creamy Alfredo sauce.', TRUE,
 480, 40, 5.5, 0.2, 250, 120, 1.8, 40, 2.0, 0, 18, 1.5, 180, 12, 0.03),

-- ==========================================
-- MCALISTER'S DELI (New Chain)
-- ==========================================

-- McAlister's Club (whole): 820 cal per whole (~400g). Per 100g: 205 cal, 12.5P, 13.8C, 10.5F
('mca_club_sandwich', 'McAlister''s Deli Club Sandwich', 205, 12.5, 13.8, 10.5,
 0.8, 2.5, 400, NULL,
 'mcalisters', ARRAY['mcalisters club sandwich', 'mcalister''s deli club', 'mcalisters club'],
 'american', 'McAlister''s Deli', 1, '205 cal/100g. Per whole (~400g): 820 cal. Turkey, ham, bacon, lettuce, tomato, Swiss, American, wheat bread.', TRUE,
 560, 50, 4.3, 0.1, 300, 100, 2.5, 20, 4.0, 0, 20, 2.5, 200, 16, 0.03),

-- King Club (whole): 1187 cal per whole (~480g). Per 100g: 247 cal, 15.8P, 12.5C, 14.8F
('mca_king_club', 'McAlister''s Deli King Club Sandwich', 247, 15.8, 12.5, 14.8,
 0.6, 2.3, 480, NULL,
 'mcalisters', ARRAY['mcalisters king club', 'mcalister''s king club sandwich'],
 'american', 'McAlister''s Deli', 1, '247 cal/100g. Per whole (~480g): 1187 cal, 51F, 76P. Turkey, ham, bacon, cheddar, Swiss, lettuce, tomato, wheat bread.', TRUE,
 620, 65, 5.8, 0.2, 310, 120, 3.0, 20, 4.0, 0, 22, 3.0, 220, 18, 0.03),

-- Chicken Tortilla Soup (bowl): 336 cal per bowl (~340g). Per 100g: 99 cal, 6.5P, 8.8C, 4.1F
('mca_chicken_tortilla_soup', 'McAlister''s Deli Chicken Tortilla Soup', 99, 6.5, 8.8, 4.1,
 1.5, 1.5, 340, NULL,
 'mcalisters', ARRAY['mcalisters chicken tortilla soup', 'mcalister''s tortilla soup'],
 'american', 'McAlister''s Deli', 1, '99 cal/100g. Per bowl (~340g): 336 cal. Chicken, tomatoes, corn, black beans, tortilla strips, spicy broth.', TRUE,
 420, 20, 1.5, 0.0, 350, 40, 1.5, 30, 8.0, 0, 20, 1.0, 120, 8, 0.03),

-- Loaded Baked Potato Soup (bowl): 480 cal per bowl (~340g). Per 100g: 141 cal, 4.7P, 10.6C, 8.8F
('mca_loaded_potato_soup', 'McAlister''s Deli Loaded Baked Potato Soup', 141, 4.7, 10.6, 8.8,
 0.6, 1.5, 340, NULL,
 'mcalisters', ARRAY['mcalisters loaded baked potato soup', 'mcalister''s potato soup'],
 'american', 'McAlister''s Deli', 1, '141 cal/100g. Per bowl (~340g): 480 cal. Baked potato, cheddar, bacon, sour cream, chives.', TRUE,
 480, 20, 5.3, 0.1, 350, 80, 0.8, 20, 3.0, 0, 15, 0.8, 100, 4, 0.02),

-- Sweet Tea (large): 150 cal per large (~500ml). Per 100g: 30 cal, 0.0P, 7.5C, 0.0F
('mca_sweet_tea', 'McAlister''s Deli Famous Sweet Tea', 30, 0.0, 7.5, 0.0,
 0.0, 7.5, 500, NULL,
 'mcalisters', ARRAY['mcalisters sweet tea', 'mcalister''s famous sweet tea'],
 'american', 'McAlister''s Deli', 1, '30 cal/100g. Per large (~500ml): 150 cal. Signature Southern-style sweet tea.', TRUE,
 5, 0, 0.0, 0.0, 10, 0, 0.0, 0, 0.0, 0, 0, 0.0, 0, 0, 0.0),

-- Spud Max (whole): 1065 cal per whole (~500g). Per 100g: 213 cal, 10.0P, 14.0C, 13.0F
('mca_spud_max', 'McAlister''s Deli Spud Max', 213, 10.0, 14.0, 13.0,
 1.2, 1.4, 500, NULL,
 'mcalisters', ARRAY['mcalisters spud max', 'mcalister''s loaded spud max', 'spud max mcalisters'],
 'american', 'McAlister''s Deli', 1, '213 cal/100g. Per whole (~500g): 1065 cal. Giant baked potato loaded with butter, sour cream, cheese, bacon, ham, turkey, chives.', TRUE,
 520, 45, 6.0, 0.2, 500, 120, 2.0, 30, 10.0, 0, 30, 2.0, 200, 8, 0.03),

-- Grilled Chicken Club (whole): 835 cal per whole (~380g). Per 100g: 220 cal, 14.5P, 11.8C, 12.6F
('mca_grilled_chicken_club', 'McAlister''s Deli Grilled Chicken Club', 220, 14.5, 11.8, 12.6,
 0.8, 2.1, 380, NULL,
 'mcalisters', ARRAY['mcalisters grilled chicken club', 'mcalister''s chicken club sandwich'],
 'american', 'McAlister''s Deli', 1, '220 cal/100g. Per whole (~380g): 835 cal. Grilled chicken, bacon, Swiss, lettuce, tomato, honey mustard.', TRUE,
 540, 50, 4.5, 0.1, 320, 100, 2.0, 20, 4.0, 0, 22, 1.8, 200, 16, 0.03),

-- Orange Cranberry Club (whole): 770 cal per whole (~380g). Per 100g: 203 cal, 11.8P, 16.3C, 9.5F
('mca_orange_cranberry_club', 'McAlister''s Deli Orange Cranberry Club', 203, 11.8, 16.3, 9.5,
 1.3, 6.6, 380, NULL,
 'mcalisters', ARRAY['mcalisters orange cranberry club', 'mcalister''s orange cranberry sandwich'],
 'american', 'McAlister''s Deli', 1, '203 cal/100g. Per whole (~380g): 770 cal. Turkey, bacon, Swiss, cranberries, orange marmalade, croissant.', TRUE,
 480, 40, 3.7, 0.1, 300, 80, 2.0, 15, 5.0, 0, 20, 1.5, 180, 14, 0.03),

-- Black Angus Club (whole): 884 cal per whole (~400g). Per 100g: 221 cal, 14.0P, 12.5C, 13.0F
('mca_black_angus_club', 'McAlister''s Deli Black Angus Club', 221, 14.0, 12.5, 13.0,
 0.8, 2.5, 400, NULL,
 'mcalisters', ARRAY['mcalisters black angus club', 'mcalister''s black angus roast beef club'],
 'american', 'McAlister''s Deli', 1, '221 cal/100g. Per whole (~400g): 884 cal. Black Angus roast beef, cheddar, horseradish, lettuce, tomato.', TRUE,
 560, 55, 5.3, 0.2, 320, 100, 3.0, 15, 3.0, 0, 22, 3.5, 210, 16, 0.04),

-- Broccoli Cheddar Soup (bowl): 360 cal per bowl (~340g). Per 100g: 106 cal, 4.4P, 6.2C, 7.1F
('mca_broccoli_cheddar_soup', 'McAlister''s Deli Broccoli Cheddar Soup', 106, 4.4, 6.2, 7.1,
 0.9, 1.5, 340, NULL,
 'mcalisters', ARRAY['mcalisters broccoli cheddar soup', 'mcalister''s broccoli cheese soup'],
 'american', 'McAlister''s Deli', 1, '106 cal/100g. Per bowl (~340g): 360 cal. Broccoli, cheddar cheese, cream.', TRUE,
 420, 20, 4.4, 0.1, 250, 100, 0.8, 35, 10.0, 0, 14, 0.7, 110, 3, 0.03)

ON CONFLICT (food_name_normalized) DO NOTHING;
