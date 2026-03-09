-- 1628_overrides_dunkin_peets.sql
-- Dunkin' and Peet's Coffee menu items.
-- Sources: fastfoodnutrition.org, fatsecret.com, nutritionix.com, calorieking.com.
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
-- DUNKIN' — BEVERAGES (COFFEE)
-- ══════════════════════════════════════════

-- Dunkin' Hot Coffee Original Medium (black): 5 cal / 414ml (~414g)
('dunkin_hot_coffee_original', 'Dunkin'' Hot Coffee Original (Medium)', 1, 0.0, 0.0, 0.0,
 0.0, 0.0, 414, NULL,
 'manufacturer', ARRAY['dunkin hot coffee', 'dunkin black coffee', 'dunkin original blend', 'dunkin coffee medium', 'dunkin drip coffee'],
 'coffee', 'Dunkin''', 1, '5 cal per medium (14 fl oz, ~414g). Black drip coffee, virtually zero macros.', TRUE),

-- Dunkin' Hot Coffee with Cream & Sugar Medium: 120 cal / 414ml (~414g)
-- FatSecret: hot coffee with cream only = 90 cal (9g fat, 1g carb, 2g protein). With sugar adds ~30 cal from sugar.
-- Per 100g: 120/414*100 = 29.0 cal
('dunkin_hot_coffee_cream_sugar', 'Dunkin'' Hot Coffee with Cream & Sugar (Medium)', 29, 0.5, 7.5, 2.2,
 0.0, 7.0, 414, NULL,
 'manufacturer', ARRAY['dunkin coffee cream sugar', 'dunkin hot coffee cream sugar', 'dunkin regular coffee', 'dunkin coffee with cream and sugar'],
 'coffee', 'Dunkin''', 1, '120 cal per medium (14 fl oz, ~414g). Brewed coffee with cream and sugar.', TRUE),

-- Dunkin' Iced Coffee Medium (black): 10 cal / 680ml (~680g)
('dunkin_iced_coffee', 'Dunkin'' Iced Coffee (Medium)', 1, 0.0, 0.0, 0.0,
 0.0, 0.0, 680, NULL,
 'manufacturer', ARRAY['dunkin iced coffee', 'dunkin iced coffee black', 'dunkin iced coffee medium', 'dunkin cold coffee'],
 'coffee', 'Dunkin''', 1, '10 cal per medium (24 fl oz, ~680g). Unsweetened iced coffee.', TRUE),

-- Dunkin' Iced Coffee with Cream & Sugar Medium: 250 cal / 680ml (~680g)
-- FatSecret: 250 cal, 7g fat, 40g carb, 7g protein
('dunkin_iced_coffee_cream_sugar', 'Dunkin'' Iced Coffee with Cream & Sugar (Medium)', 37, 1.0, 5.9, 1.0,
 0.0, 5.6, 680, NULL,
 'manufacturer', ARRAY['dunkin iced coffee cream sugar', 'dunkin iced coffee regular', 'dunkin iced coffee with cream and sugar'],
 'coffee', 'Dunkin''', 1, '250 cal per medium (24 fl oz, ~680g). Iced coffee with cream and sugar.', TRUE),

-- Dunkin' Hot Latte Medium (whole milk): 170 cal / 414ml (~414g)
-- Estimated macros from latte composition: ~8g fat, 14g carb, 10g protein
('dunkin_hot_latte', 'Dunkin'' Hot Latte (Medium)', 41, 2.4, 3.4, 1.9,
 0.0, 2.9, 414, NULL,
 'manufacturer', ARRAY['dunkin latte', 'dunkin hot latte', 'dunkin latte medium', 'dunkin caffe latte'],
 'coffee', 'Dunkin''', 1, '170 cal per medium (14 fl oz, ~414g). Espresso with steamed whole milk.', TRUE),

-- Dunkin' Iced Latte Medium (whole milk): 120 cal / 480ml (~480g)
-- Lighter than hot due to more ice displacement
('dunkin_iced_latte', 'Dunkin'' Iced Latte (Medium)', 25, 1.9, 2.1, 1.5,
 0.0, 1.9, 480, NULL,
 'manufacturer', ARRAY['dunkin iced latte', 'dunkin iced latte medium', 'dunkin iced caffe latte'],
 'coffee', 'Dunkin''', 1, '120 cal per medium (24 fl oz, ~480g). Espresso with cold whole milk over ice.', TRUE),

-- Dunkin' Caramel Swirl Latte Medium (whole milk): 340 cal / 414ml (~414g)
-- FatSecret: 340 cal, 9g fat, 53g carb, 11g protein
('dunkin_caramel_swirl_latte', 'Dunkin'' Caramel Swirl Latte (Medium)', 82, 2.7, 12.8, 2.2,
 0.0, 12.6, 414, NULL,
 'manufacturer', ARRAY['dunkin caramel latte', 'dunkin caramel swirl latte', 'dunkin caramel swirl hot latte', 'dunkin caramel latte medium'],
 'coffee', 'Dunkin''', 1, '340 cal per medium (14 fl oz, ~414g). Espresso with whole milk and caramel swirl.', TRUE),

-- Dunkin' Strawberry Dragonfruit Refresher Medium: 130 cal / 680ml (~680g)
-- fastfoodnutrition.org: 130 cal, 0g fat, 29g carb, 1g protein, 0g fiber, 27g sugar
('dunkin_strawberry_dragonfruit_refresher', 'Dunkin'' Strawberry Dragonfruit Refresher (Medium)', 19, 0.1, 4.3, 0.0,
 0.0, 4.0, 680, NULL,
 'manufacturer', ARRAY['dunkin strawberry dragonfruit', 'dunkin refresher strawberry dragonfruit', 'dunkin dragonfruit refresher', 'dunkin strawberry refresher'],
 'coffee', 'Dunkin''', 1, '130 cal per medium (24 fl oz, ~680g). Green tea based refresher with strawberry dragonfruit flavor.', TRUE),

-- Dunkin' Peach Passion Fruit Refresher Medium: 130 cal / 680ml (~680g)
-- fastfoodnutrition.org: 130 cal, 0g fat, 32g carb, 1g protein, 0g fiber, 29g sugar
('dunkin_peach_passion_fruit_refresher', 'Dunkin'' Peach Passion Fruit Refresher (Medium)', 19, 0.1, 4.7, 0.0,
 0.0, 4.3, 680, NULL,
 'manufacturer', ARRAY['dunkin peach passion fruit', 'dunkin refresher peach', 'dunkin peach refresher', 'dunkin passion fruit refresher'],
 'coffee', 'Dunkin''', 1, '130 cal per medium (24 fl oz, ~680g). Green tea based refresher with peach passion fruit flavor.', TRUE),

-- Dunkin' Cold Brew Medium (black): 10 cal / 680ml (~680g)
('dunkin_cold_brew', 'Dunkin'' Cold Brew (Medium)', 1, 0.0, 0.0, 0.0,
 0.0, 0.0, 680, NULL,
 'manufacturer', ARRAY['dunkin cold brew', 'dunkin cold brew black', 'dunkin cold brew medium', 'dunkin cold brew coffee'],
 'coffee', 'Dunkin''', 1, '10 cal per medium (24 fl oz, ~680g). Slow-steeped cold brew coffee, black.', TRUE),

-- Dunkin' Sweet Cream Cold Brew Medium: 260 cal / 680ml (~680g)
-- Approximate macros based on sweet cream composition: ~10g fat, 38g carb, 4g protein
('dunkin_sweet_cream_cold_brew', 'Dunkin'' Sweet Cream Cold Brew (Medium)', 38, 0.6, 5.6, 1.5,
 0.0, 5.3, 680, NULL,
 'manufacturer', ARRAY['dunkin sweet cream cold brew', 'dunkin cold brew sweet cream', 'dunkin vanilla sweet cream cold brew'],
 'coffee', 'Dunkin''', 1, '260 cal per medium (24 fl oz, ~680g). Cold brew with sweet cream.', TRUE),

-- ══════════════════════════════════════════
-- DUNKIN' — BREAKFAST SANDWICHES
-- ══════════════════════════════════════════

-- Dunkin' Bacon Egg & Cheese on Croissant: 550 cal per sandwich (195g)
-- fastfoodnutrition.org: 550 cal, 35g fat, 40g carb, 19g protein, 2g fiber, 5g sugar
('dunkin_bacon_egg_cheese', 'Dunkin'' Bacon, Egg & Cheese on Croissant', 282, 9.7, 20.5, 17.9,
 1.0, 2.6, NULL, 195,
 'manufacturer', ARRAY['dunkin bacon egg cheese', 'dunkin bacon egg and cheese', 'dunkin bec croissant', 'dunkin breakfast sandwich bacon', 'dunkin bacon egg cheese croissant'],
 'breakfast_sandwich', 'Dunkin''', 1, '550 cal per sandwich (195g). Bacon, egg, and American cheese on a flaky croissant.', TRUE),

-- Dunkin' Sausage Egg & Cheese on Croissant: 700 cal per sandwich (~225g)
-- fastfoodnutrition.org: 700 cal, 50g fat, 41g carb, 23g protein, 2g fiber, 5g sugar
('dunkin_sausage_egg_cheese', 'Dunkin'' Sausage, Egg & Cheese on Croissant', 311, 10.2, 18.2, 22.2,
 0.9, 2.2, NULL, 225,
 'manufacturer', ARRAY['dunkin sausage egg cheese', 'dunkin sausage egg and cheese', 'dunkin sec croissant', 'dunkin breakfast sandwich sausage', 'dunkin sausage egg cheese croissant'],
 'breakfast_sandwich', 'Dunkin''', 1, '700 cal per sandwich (~225g). Sausage patty, egg, and American cheese on a croissant.', TRUE),

-- Dunkin' Turkey Sausage Wake-Up Wrap: 280 cal per wrap (~95g)
-- fastfoodnutrition.org: 280 cal, 18g fat, 13g carb, 15g protein, 1g fiber, 0g sugar
('dunkin_turkey_sausage_wrap', 'Dunkin'' Turkey Sausage Wake-Up Wrap', 295, 15.8, 13.7, 18.9,
 1.1, 0.0, NULL, 95,
 'manufacturer', ARRAY['dunkin turkey sausage wrap', 'dunkin turkey sausage wake up wrap', 'dunkin turkey wrap', 'dunkin wake up wrap turkey'],
 'breakfast_sandwich', 'Dunkin''', 1, '280 cal per wrap (~95g). Turkey sausage, egg, and cheese in a flour tortilla.', TRUE),

-- Dunkin' Veggie Egg White Wake-Up Wrap: 150 cal per wrap (~80g)
-- Approximate macros: 5g fat, 14g carb, 9g protein
('dunkin_veggie_egg_white_wrap', 'Dunkin'' Veggie Egg White Wake-Up Wrap', 188, 11.3, 17.5, 6.3,
 1.3, 1.3, NULL, 80,
 'manufacturer', ARRAY['dunkin veggie egg white wrap', 'dunkin veggie wake up wrap', 'dunkin egg white wrap', 'dunkin veggie egg white wake up wrap'],
 'breakfast_sandwich', 'Dunkin''', 1, '150 cal per wrap (~80g). Egg whites with vegetables and cheese in a flour tortilla.', TRUE),

-- ══════════════════════════════════════════
-- DUNKIN' — DONUTS & BREAKFAST ITEMS
-- ══════════════════════════════════════════

-- Dunkin' Glazed Donut: 260 cal per donut (~60g)
-- fastfoodnutrition.org: 260 cal, 14g fat, 31g carb, 3g protein, 1g fiber, 12g sugar
-- Note: eatthismuch shows 100g serving but cross-referencing with nutritionix/mynetdiary: ~60g is standard donut weight
('dunkin_glazed_donut', 'Dunkin'' Glazed Donut', 433, 5.0, 51.7, 23.3,
 1.7, 20.0, NULL, 60,
 'manufacturer', ARRAY['dunkin glazed donut', 'dunkin glazed doughnut', 'dunkin donut glazed', 'dunkin original glazed donut'],
 'donut', 'Dunkin''', 1, '260 cal per donut (~60g). Classic yeast-raised glazed donut.', TRUE),

-- Dunkin' Boston Kreme Donut: 300 cal per donut (~100g)
-- fastfoodnutrition.org: 300 cal, 16g fat, 37g carb, 3g protein, 1g fiber, 17g sugar
('dunkin_boston_kreme', 'Dunkin'' Boston Kreme Donut', 300, 3.0, 37.0, 16.0,
 1.0, 17.0, NULL, 100,
 'manufacturer', ARRAY['dunkin boston kreme', 'dunkin boston cream donut', 'dunkin boston kreme donut', 'dunkin boston creme'],
 'donut', 'Dunkin''', 1, '300 cal per donut (~100g). Yeast donut filled with bavarian cream, topped with chocolate glaze.', TRUE),

-- Dunkin' Chocolate Frosted Donut: 280 cal per donut (~64g)
-- fastfoodnutrition.org: 280 cal, 15g fat, 31g carb, 3g protein, 1g fiber, 13g sugar
('dunkin_chocolate_frosted', 'Dunkin'' Chocolate Frosted Donut', 438, 4.7, 48.4, 23.4,
 1.6, 20.3, NULL, 64,
 'manufacturer', ARRAY['dunkin chocolate frosted', 'dunkin chocolate frosted donut', 'dunkin chocolate donut', 'dunkin frosted chocolate donut'],
 'donut', 'Dunkin''', 1, '280 cal per donut (~64g). Classic yeast donut with chocolate frosting.', TRUE),

-- Dunkin' Jelly Donut: 270 cal per donut (~85g)
-- fastfoodnutrition.org: 270 cal, 14g fat, 32g carb, 3g protein, 1g fiber, 15g sugar
('dunkin_jelly_donut', 'Dunkin'' Jelly Donut', 318, 3.5, 37.6, 16.5,
 1.2, 17.6, NULL, 85,
 'manufacturer', ARRAY['dunkin jelly donut', 'dunkin jelly filled donut', 'dunkin jelly doughnut', 'dunkin jelly'],
 'donut', 'Dunkin''', 1, '270 cal per donut (~85g). Yeast donut filled with jelly.', TRUE),

-- Dunkin' Munchkins Glazed (3-pack): 190 cal for 3 pieces (~48g, ~16g each)
-- Each glazed munchkin: ~60 cal, 3g fat, 7g carb, 1g protein, 0g fiber, 3g sugar
('dunkin_munchkins_glazed_3pack', 'Dunkin'' Munchkins Glazed (3-pack)', 396, 6.3, 43.8, 18.8,
 0.0, 18.8, NULL, 48,
 'manufacturer', ARRAY['dunkin munchkins glazed', 'dunkin glazed munchkins', 'dunkin munchkins', 'dunkin donut holes glazed', 'dunkin munchkins 3 pack'],
 'donut', 'Dunkin''', 1, '190 cal per 3-pack (~48g, ~16g each). Mini glazed donut holes.', TRUE),

-- Dunkin' Munchkins Chocolate (3-pack): 210 cal for 3 pieces (~51g, ~17g each)
-- Each chocolate munchkin: ~70 cal, 4g fat, 8g carb, 1g protein, 0g fiber, 4g sugar
('dunkin_munchkins_chocolate_3pack', 'Dunkin'' Munchkins Chocolate (3-pack)', 412, 5.9, 47.1, 23.5,
 0.0, 23.5, NULL, 51,
 'manufacturer', ARRAY['dunkin munchkins chocolate', 'dunkin chocolate munchkins', 'dunkin donut holes chocolate', 'dunkin munchkins chocolate 3 pack'],
 'donut', 'Dunkin''', 1, '210 cal per 3-pack (~51g, ~17g each). Mini chocolate glazed donut holes.', TRUE),

-- Dunkin' Hash Browns (6-piece): 360 cal for 6 pieces (~108g)
-- FatSecret: 1 serving = 110 cal. 6 pieces ~ 3 servings ~= 330-360 cal
-- Per piece ~18g. 6 pieces: ~14g fat, 39g carb, 3g protein
('dunkin_hash_browns', 'Dunkin'' Hash Browns (6 Pieces)', 333, 2.8, 36.1, 19.4,
 2.8, 2.8, NULL, 108,
 'manufacturer', ARRAY['dunkin hash browns', 'dunkin hashbrowns', 'dunkin hash brown 6 piece', 'dunkin breakfast hash browns'],
 'breakfast', 'Dunkin''', 1, '360 cal per 6-piece order (~108g). Crispy seasoned hash brown bites.', TRUE),

-- ══════════════════════════════════════════
-- PEET'S COFFEE
-- ══════════════════════════════════════════

-- Peet's Coffee Medium Drip: 5 cal / 473ml (~473g, 16 fl oz)
('peets_drip_coffee', 'Peet''s Coffee Drip Coffee (Medium)', 1, 0.2, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'manufacturer', ARRAY['peets drip coffee', 'peets coffee medium', 'peets black coffee', 'peets coffee of the day', 'peets brewed coffee'],
 'coffee', 'Peet''s Coffee', 1, '5 cal per medium (16 fl oz, ~473g). Fresh brewed drip coffee, black.', TRUE),

-- Peet's Coffee Caffe Latte Medium (whole milk): 280 cal / 473ml (~473g)
-- FatSecret: 280 cal, 14g fat, 23g carb, 15g protein, 0g fiber, 19g sugar
('peets_caffe_latte', 'Peet''s Coffee Caffe Latte (Medium)', 59, 3.2, 4.9, 3.0,
 0.0, 4.0, 473, NULL,
 'manufacturer', ARRAY['peets latte', 'peets caffe latte', 'peets latte medium', 'peets coffee latte'],
 'coffee', 'Peet''s Coffee', 1, '280 cal per medium (16 fl oz, ~473g). Espresso with steamed whole milk.', TRUE),

-- Peet's Coffee Vanilla Latte Medium (whole milk): 370 cal / 473ml (~473g)
-- FatSecret: 370 cal, 13g fat, 49g carb, 14g protein, 0g fiber, 46g sugar
('peets_vanilla_latte', 'Peet''s Coffee Vanilla Latte (Medium)', 78, 3.0, 10.4, 2.7,
 0.0, 9.7, 473, NULL,
 'manufacturer', ARRAY['peets vanilla latte', 'peets vanilla latte medium', 'peets coffee vanilla latte'],
 'coffee', 'Peet''s Coffee', 1, '370 cal per medium (16 fl oz, ~473g). Espresso with vanilla syrup and steamed whole milk.', TRUE),

-- Peet's Coffee Caramel Macchiato Medium (2% milk): 290 cal / 473ml (~473g)
-- CalorieKing: 290 cal, 0g fat, 55g carb, 14g protein, 0g fiber, 58g sugar
-- Note: 0g fat seems like nonfat milk reporting; with 2% milk likely ~5g fat
('peets_caramel_macchiato', 'Peet''s Coffee Caramel Macchiato (Medium)', 61, 3.0, 11.6, 1.1,
 0.0, 12.3, 473, NULL,
 'manufacturer', ARRAY['peets caramel macchiato', 'peets caramel macchiato medium', 'peets coffee caramel macchiato'],
 'coffee', 'Peet''s Coffee', 1, '290 cal per medium (16 fl oz, ~473g). Espresso with vanilla, steamed milk, and caramel drizzle.', TRUE),

-- Peet's Coffee Iced Mocha Medium (whole milk, no whip): 275 cal / 473ml (~473g)
-- CalorieKing: 275 cal, 10g fat, 35g carb, 10g protein, 0g fiber, 32g sugar
('peets_iced_mocha', 'Peet''s Coffee Iced Mocha (Medium)', 58, 2.1, 7.4, 2.1,
 0.0, 6.8, 473, NULL,
 'manufacturer', ARRAY['peets iced mocha', 'peets iced mocha medium', 'peets coffee iced mocha', 'peets mocha iced'],
 'coffee', 'Peet''s Coffee', 1, '275 cal per medium (16 fl oz, ~473g). Espresso with chocolate, milk, and ice. No whipped cream.', TRUE)

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
