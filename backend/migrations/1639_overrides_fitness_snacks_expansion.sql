-- 1639_overrides_fitness_snacks_expansion.sql
-- Fitness and protein snack brands: ONE Bar, think!, FitCrunch, Kodiak Cakes,
-- Jack Link's, CLIF Bar, RXBAR.
-- Sources: manufacturer websites, nutritionix.com, fatsecret.com, eatthismuch.com.
-- All values per 100g. default_weight_per_piece_g = bar/piece weight.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- ONE BAR
-- All flavors: ~220 cal, 20g P, 22g C, 6g F per 60g bar
-- per 100g: ~367 cal, 33g P, 37g C, 10g F
-- ══════════════════════════════════════════

-- ONE Bar Birthday Cake: 220 cal / 60g bar
('one_bar_birthday_cake', 'ONE Bar Birthday Cake', 367, 33.3, 36.7, 10.0,
 5.0, 1.7, NULL, 60,
 'website', ARRAY['one bar birthday cake', 'one protein bar birthday cake', 'one birthday cake bar', 'oh yeah one bar birthday cake'],
 'protein_bar', 'ONE', 1, '220 cal, 20g protein, 22g carbs, 6g fat per 60g bar. 1g sugar, 3g fiber. Gluten free.', TRUE),

-- ONE Bar Peanut Butter Pie: 220 cal / 60g bar
('one_bar_peanut_butter_pie', 'ONE Bar Peanut Butter Pie', 367, 33.3, 36.7, 10.0,
 5.0, 1.7, NULL, 60,
 'website', ARRAY['one bar peanut butter pie', 'one protein bar peanut butter', 'one peanut butter bar', 'oh yeah one bar pb pie'],
 'protein_bar', 'ONE', 1, '220 cal, 20g protein, 22g carbs, 6g fat per 60g bar. 1g sugar, 3g fiber. Gluten free.', TRUE),

-- ONE Bar Blueberry Cobbler: 220 cal / 60g bar
('one_bar_blueberry_cobbler', 'ONE Bar Blueberry Cobbler', 367, 33.3, 36.7, 10.0,
 5.0, 1.7, NULL, 60,
 'website', ARRAY['one bar blueberry cobbler', 'one protein bar blueberry', 'one blueberry bar', 'oh yeah one bar blueberry cobbler'],
 'protein_bar', 'ONE', 1, '220 cal, 20g protein, 22g carbs, 6g fat per 60g bar. 1g sugar, 3g fiber. Gluten free.', TRUE),

-- ONE Bar Maple Glazed Doughnut: 220 cal / 60g bar
('one_bar_maple_glazed_doughnut', 'ONE Bar Maple Glazed Doughnut', 367, 33.3, 36.7, 10.0,
 5.0, 1.7, NULL, 60,
 'website', ARRAY['one bar maple glazed doughnut', 'one protein bar maple doughnut', 'one maple donut bar', 'oh yeah one bar maple glazed'],
 'protein_bar', 'ONE', 1, '220 cal, 20g protein, 22g carbs, 6g fat per 60g bar. 1g sugar, 3g fiber. Gluten free.', TRUE),

-- ONE Bar Almond Bliss: 220 cal / 60g bar
('one_bar_almond_bliss', 'ONE Bar Almond Bliss', 367, 33.3, 36.7, 10.0,
 5.0, 1.7, NULL, 60,
 'website', ARRAY['one bar almond bliss', 'one protein bar almond', 'one almond bliss bar', 'oh yeah one bar almond bliss'],
 'protein_bar', 'ONE', 1, '220 cal, 20g protein, 22g carbs, 6g fat per 60g bar. 1g sugar, 3g fiber. Gluten free.', TRUE),

-- ONE Bar Cinnamon Roll: 220 cal / 60g bar
('one_bar_cinnamon_roll', 'ONE Bar Cinnamon Roll', 367, 33.3, 36.7, 10.0,
 5.0, 1.7, NULL, 60,
 'website', ARRAY['one bar cinnamon roll', 'one protein bar cinnamon', 'one cinnamon roll bar', 'oh yeah one bar cinnamon roll'],
 'protein_bar', 'ONE', 1, '220 cal, 20g protein, 22g carbs, 6g fat per 60g bar. 1g sugar, 3g fiber. Gluten free.', TRUE),

-- ══════════════════════════════════════════
-- think! HIGH PROTEIN BAR
-- ~230 cal, 20g P, 24g C, 5-9g F per 60g bar
-- per 100g: ~383 cal, 33g P, 40g C, ~9g F (varies slightly)
-- ══════════════════════════════════════════

-- think! Brownie Crunch: 230 cal / 60g bar
('think_brownie_crunch', 'think! High Protein Bar Brownie Crunch', 383, 33.3, 40.0, 8.3,
 3.3, 0.0, NULL, 60,
 'website', ARRAY['think bar brownie crunch', 'think high protein brownie crunch', 'think protein bar brownie', 'think brownie crunch bar'],
 'protein_bar', 'think!', 1, '230 cal, 20g protein, 24g carbs, 5g fat per 60g bar. 0g sugar. Gluten free.', TRUE),

-- think! Chunky Peanut Butter: 230 cal / 60g bar
('think_chunky_peanut_butter', 'think! High Protein Bar Chunky Peanut Butter', 383, 33.3, 38.3, 10.0,
 1.7, 0.0, NULL, 60,
 'website', ARRAY['think bar chunky peanut butter', 'think high protein peanut butter', 'think protein bar peanut butter', 'think chunky pb bar'],
 'protein_bar', 'think!', 1, '230 cal, 20g protein, 23g carbs, 6g fat per 60g bar. 0g sugar. Gluten free.', TRUE),

-- think! Cookies & Cream: 230 cal / 60g bar
('think_cookies_cream', 'think! High Protein Bar Cookies & Cream', 383, 33.3, 40.0, 8.3,
 3.3, 0.0, NULL, 60,
 'website', ARRAY['think bar cookies and cream', 'think high protein cookies cream', 'think protein bar cookies cream', 'think cookies cream bar'],
 'protein_bar', 'think!', 1, '230 cal, 20g protein, 24g carbs, 5g fat per 60g bar. 0g sugar. Gluten free.', TRUE),

-- think! Lemon Delight: 230 cal / 60g bar
('think_lemon_delight', 'think! High Protein Bar Lemon Delight', 383, 33.3, 40.0, 8.3,
 3.3, 0.0, NULL, 60,
 'website', ARRAY['think bar lemon delight', 'think high protein lemon', 'think protein bar lemon delight', 'think lemon bar'],
 'protein_bar', 'think!', 1, '230 cal, 20g protein, 24g carbs, 5g fat per 60g bar. 0g sugar. Gluten free.', TRUE),

-- think! White Chocolate: 230 cal / 60g bar
('think_white_chocolate', 'think! High Protein Bar White Chocolate', 383, 33.3, 40.0, 8.3,
 3.3, 0.0, NULL, 60,
 'website', ARRAY['think bar white chocolate', 'think high protein white chocolate', 'think protein bar white chocolate', 'think white choc bar'],
 'protein_bar', 'think!', 1, '230 cal, 20g protein, 24g carbs, 5g fat per 60g bar. 0g sugar. Gluten free.', TRUE),

-- ══════════════════════════════════════════
-- FITCRUNCH — PROTEIN BAR
-- ~380 cal, 30g P, 30g C, 16g F per 88g bar
-- per 100g: ~432 cal, 34g P, 34g C, 18g F
-- ══════════════════════════════════════════

-- FitCrunch Peanut Butter: 380 cal / 88g bar
('fitcrunch_peanut_butter', 'FitCrunch Protein Bar Peanut Butter', 432, 34.1, 34.1, 18.2,
 1.1, 6.8, NULL, 88,
 'website', ARRAY['fitcrunch peanut butter', 'fit crunch peanut butter bar', 'fitcrunch protein bar pb', 'robert irvine fitcrunch peanut butter'],
 'protein_bar', 'FitCrunch', 1, '380 cal, 30g protein, 30g carbs, 16g fat per 88g bar. 6-layer baked bar. 6g sugar.', TRUE),

-- FitCrunch Chocolate Chip Cookie Dough: 380 cal / 88g bar
('fitcrunch_chocolate_chip_cookie_dough', 'FitCrunch Protein Bar Chocolate Chip Cookie Dough', 432, 34.1, 34.1, 18.2,
 1.1, 6.8, NULL, 88,
 'website', ARRAY['fitcrunch chocolate chip cookie dough', 'fit crunch cookie dough bar', 'fitcrunch protein bar cookie dough', 'robert irvine fitcrunch cookie dough'],
 'protein_bar', 'FitCrunch', 1, '380 cal, 30g protein, 30g carbs, 16g fat per 88g bar. 6-layer baked bar. 6g sugar.', TRUE),

-- FitCrunch Birthday Cake: 380 cal / 88g bar
('fitcrunch_birthday_cake', 'FitCrunch Protein Bar Birthday Cake', 432, 34.1, 34.1, 18.2,
 1.1, 6.8, NULL, 88,
 'website', ARRAY['fitcrunch birthday cake', 'fit crunch birthday cake bar', 'fitcrunch protein bar birthday cake', 'robert irvine fitcrunch birthday cake'],
 'protein_bar', 'FitCrunch', 1, '380 cal, 30g protein, 30g carbs, 16g fat per 88g bar. 6-layer baked bar. 6g sugar.', TRUE),

-- FitCrunch Cookies & Cream: 380 cal / 88g bar
('fitcrunch_cookies_cream', 'FitCrunch Protein Bar Cookies & Cream', 432, 34.1, 34.1, 18.2,
 1.1, 6.8, NULL, 88,
 'website', ARRAY['fitcrunch cookies and cream', 'fit crunch cookies cream bar', 'fitcrunch protein bar cookies cream', 'robert irvine fitcrunch cookies cream'],
 'protein_bar', 'FitCrunch', 1, '380 cal, 30g protein, 30g carbs, 16g fat per 88g bar. 6-layer baked bar. 6g sugar.', TRUE),

-- FitCrunch Caramel Peanut: 380 cal / 88g bar
('fitcrunch_caramel_peanut', 'FitCrunch Protein Bar Caramel Peanut', 432, 34.1, 34.1, 18.2,
 1.1, 6.8, NULL, 88,
 'website', ARRAY['fitcrunch caramel peanut', 'fit crunch caramel peanut bar', 'fitcrunch protein bar caramel peanut', 'robert irvine fitcrunch caramel peanut'],
 'protein_bar', 'FitCrunch', 1, '380 cal, 30g protein, 30g carbs, 16g fat per 88g bar. 6-layer baked bar. 6g sugar.', TRUE),

-- ══════════════════════════════════════════
-- KODIAK CAKES
-- Protein-packed pancake mixes, oatmeal, waffles, snacks
-- ══════════════════════════════════════════

-- Kodiak Cakes Power Cakes Buttermilk Mix (dry): 190 cal / 53g serving
-- per 100g: 358 cal, 14g P, 64g C, 3.8g F
('kodiak_power_cakes_buttermilk', 'Kodiak Cakes Power Cakes Buttermilk Flapjack & Waffle Mix', 358, 26.4, 64.2, 3.8,
 5.7, 11.3, 53, NULL,
 'website', ARRAY['kodiak cakes buttermilk', 'kodiak power cakes', 'kodiak pancake mix', 'kodiak cakes flapjack mix', 'kodiak protein pancake mix'],
 'pancake_mix', 'Kodiak Cakes', 1, '190 cal, 14g protein, 34g carbs, 2g fat per 53g dry mix serving. Add water/milk to prepare. Whole grain, non-GMO.', TRUE),

-- Kodiak Cakes Flapjack Cup: 270 cal / 70g cup
-- per 100g: 386 cal, 17.1g P, 58.6g C, 8.6g F
('kodiak_flapjack_cup', 'Kodiak Cakes Flapjack on the Go Cup', 386, 17.1, 58.6, 8.6,
 4.3, 17.1, NULL, 70,
 'website', ARRAY['kodiak flapjack cup', 'kodiak cakes cup', 'kodiak flapjack on the go', 'kodiak pancake cup', 'kodiak cakes flapjack cup'],
 'pancake_mix', 'Kodiak Cakes', 1, '270 cal, 12g protein, 41g carbs, 6g fat per 70g cup. Just add water and microwave. Whole grain.', TRUE),

-- Kodiak Cakes Protein Oatmeal (dry): 190 cal / 50g serving
-- per 100g: 380 cal, 28g P, 60g C, 6g F
('kodiak_protein_oatmeal', 'Kodiak Cakes Protein Oatmeal', 380, 28.0, 60.0, 6.0,
 6.0, 8.0, 50, NULL,
 'website', ARRAY['kodiak oatmeal', 'kodiak cakes oatmeal', 'kodiak protein oatmeal', 'kodiak oatmeal cup', 'kodiak cakes protein oats'],
 'oatmeal', 'Kodiak Cakes', 1, '190 cal, 14g protein, 30g carbs, 3g fat per 50g dry serving. Whole grain oats with protein blend.', TRUE),

-- Kodiak Cakes Protein Waffles (frozen, 2 waffles): 200 cal / 70g serving
-- per 100g: 286 cal, 17.1g P, 42.9g C, 5.7g F
('kodiak_protein_waffles', 'Kodiak Cakes Power Waffles (Frozen)', 286, 17.1, 42.9, 5.7,
 4.3, 8.6, 70, NULL,
 'website', ARRAY['kodiak waffles', 'kodiak power waffles', 'kodiak cakes frozen waffles', 'kodiak protein waffles', 'kodiak cakes waffles frozen'],
 'frozen_breakfast', 'Kodiak Cakes', 1, '200 cal, 12g protein, 30g carbs, 4g fat per 70g serving (2 waffles). Toaster ready. Whole grain.', TRUE),

-- Kodiak Cakes Graham Crackers: 130 cal / 30g serving
-- per 100g: 433 cal, 10g P, 70g C, 13.3g F
('kodiak_graham_crackers', 'Kodiak Cakes Graham Crackers', 433, 10.0, 70.0, 13.3,
 3.3, 23.3, 30, NULL,
 'website', ARRAY['kodiak graham crackers', 'kodiak cakes graham crackers', 'kodiak protein graham crackers', 'kodiak grahams', 'kodiak cakes honey graham crackers'],
 'snack', 'Kodiak Cakes', 1, '130 cal, 3g protein, 21g carbs, 4g fat per 30g serving. Whole grain graham crackers with protein.', TRUE),

-- Kodiak Cakes Bear Bites: 130 cal / 30g serving
-- per 100g: 433 cal, 8g P, 67g C, 15g F
('kodiak_bear_bites', 'Kodiak Cakes Bear Bites Graham Crackers', 433, 8.0, 67.0, 15.0,
 3.3, 20.0, 30, NULL,
 'website', ARRAY['kodiak bear bites', 'kodiak cakes bear bites', 'kodiak protein bear bites', 'kodiak bear bites honey', 'kodiak cakes bear bites graham'],
 'snack', 'Kodiak Cakes', 1, '130 cal, 2.4g protein, 20g carbs, 4.5g fat per 30g serving. Fun-shaped graham snacks. Whole grain.', TRUE),

-- ══════════════════════════════════════════
-- JACK LINK'S — JERKY & MEAT SNACKS
-- All values per 100g. Serving = 28g (1 oz).
-- ══════════════════════════════════════════

-- Jack Link's Original Beef Jerky: 80 cal / 28g serving
-- per 100g: 286 cal, 50g P, 17.9g C, 2.1g F
('jack_links_original_beef_jerky', 'Jack Link''s Original Beef Jerky', 286, 50.0, 17.9, 2.1,
 0.0, 14.3, 28, NULL,
 'website', ARRAY['jack links original jerky', 'jack links beef jerky original', 'jack links original beef jerky', 'jack links jerky original', 'jack link original jerky'],
 'jerky', 'Jack Link''s', 1, '80 cal, 14g protein, 5g carbs, 0.5g fat per 28g serving. High protein, shelf stable beef snack.', TRUE),

-- Jack Link's Teriyaki Beef Jerky: 80 cal / 28g serving
-- per 100g: 286 cal, 46.4g P, 25g C, 2.1g F
('jack_links_teriyaki_beef_jerky', 'Jack Link''s Teriyaki Beef Jerky', 286, 46.4, 25.0, 2.1,
 0.0, 21.4, 28, NULL,
 'website', ARRAY['jack links teriyaki jerky', 'jack links beef jerky teriyaki', 'jack links teriyaki beef jerky', 'jack links jerky teriyaki', 'jack link teriyaki jerky'],
 'jerky', 'Jack Link''s', 1, '80 cal, 13g protein, 7g carbs, 0.5g fat per 28g serving. Sweet teriyaki flavor. High protein.', TRUE),

-- Jack Link's Peppered Beef Jerky: 80 cal / 28g serving
-- per 100g: 286 cal, 50g P, 17.9g C, 2.1g F
('jack_links_peppered_beef_jerky', 'Jack Link''s Peppered Beef Jerky', 286, 50.0, 17.9, 2.1,
 0.0, 14.3, 28, NULL,
 'website', ARRAY['jack links peppered jerky', 'jack links beef jerky peppered', 'jack links peppered beef jerky', 'jack links jerky peppered', 'jack link peppered jerky'],
 'jerky', 'Jack Link''s', 1, '80 cal, 14g protein, 5g carbs, 0.5g fat per 28g serving. Bold pepper flavor. High protein.', TRUE),

-- Jack Link's Turkey Jerky: 70 cal / 28g serving
-- per 100g: 250 cal, 46.4g P, 17.9g C, 1.8g F
('jack_links_turkey_jerky', 'Jack Link''s Turkey Jerky', 250, 46.4, 17.9, 1.8,
 0.0, 14.3, 28, NULL,
 'website', ARRAY['jack links turkey jerky', 'jack links turkey jerky original', 'jack link turkey jerky', 'jack links jerky turkey'],
 'jerky', 'Jack Link''s', 1, '70 cal, 13g protein, 5g carbs, 0.5g fat per 28g serving. Leaner turkey alternative. High protein.', TRUE),

-- Jack Link's Beef Sticks Original: 100 cal / 28g stick
-- per 100g: 357 cal, 25g P, 7.1g C, 25g F
('jack_links_beef_sticks', 'Jack Link''s Beef Sticks Original', 357, 25.0, 7.1, 25.0,
 0.0, 3.6, NULL, 28,
 'website', ARRAY['jack links beef sticks', 'jack links beef stick original', 'jack link beef sticks', 'jack links meat sticks', 'jack links original beef stick'],
 'jerky', 'Jack Link''s', 1, '100 cal, 7g protein, 2g carbs, 7g fat per 28g stick. Portable high-protein meat snack.', TRUE),

-- ══════════════════════════════════════════
-- CLIF BAR — ENERGY BAR
-- ~250 cal, 10g P, 42g C, 5g F per 68g bar
-- per 100g: ~368 cal, 15g P, 62g C, 7.4g F
-- ══════════════════════════════════════════

-- CLIF Bar Chocolate Chip: 250 cal / 68g bar
('clif_bar_chocolate_chip', 'CLIF Bar Chocolate Chip', 368, 14.7, 61.8, 7.4,
 5.9, 30.9, NULL, 68,
 'website', ARRAY['clif bar chocolate chip', 'clif chocolate chip', 'clif bar choc chip', 'clif energy bar chocolate chip'],
 'energy_bar', 'CLIF', 1, '250 cal, 10g protein, 42g carbs, 5g fat per 68g bar. 21g sugar. Plant-based. 70% organic ingredients.', TRUE),

-- CLIF Bar Crunchy Peanut Butter: 250 cal / 68g bar
('clif_bar_crunchy_peanut_butter', 'CLIF Bar Crunchy Peanut Butter', 368, 16.2, 60.3, 8.8,
 5.9, 29.4, NULL, 68,
 'website', ARRAY['clif bar crunchy peanut butter', 'clif peanut butter', 'clif bar pb', 'clif energy bar peanut butter', 'clif bar crunchy pb'],
 'energy_bar', 'CLIF', 1, '250 cal, 11g protein, 41g carbs, 6g fat per 68g bar. 20g sugar. Plant-based. 70% organic ingredients.', TRUE),

-- CLIF Bar White Chocolate Macadamia Nut: 250 cal / 68g bar
('clif_bar_white_choc_macadamia', 'CLIF Bar White Chocolate Macadamia Nut', 368, 13.2, 63.2, 8.8,
 4.4, 32.4, NULL, 68,
 'website', ARRAY['clif bar white chocolate macadamia', 'clif white choc macadamia', 'clif bar macadamia', 'clif energy bar white chocolate macadamia nut'],
 'energy_bar', 'CLIF', 1, '250 cal, 9g protein, 43g carbs, 6g fat per 68g bar. 22g sugar. Plant-based. 70% organic ingredients.', TRUE),

-- CLIF Bar Cool Mint Chocolate: 250 cal / 68g bar
('clif_bar_cool_mint_chocolate', 'CLIF Bar Cool Mint Chocolate', 368, 14.7, 61.8, 7.4,
 5.9, 30.9, NULL, 68,
 'website', ARRAY['clif bar cool mint chocolate', 'clif mint chocolate', 'clif bar mint choc', 'clif energy bar cool mint chocolate'],
 'energy_bar', 'CLIF', 1, '250 cal, 10g protein, 42g carbs, 5g fat per 68g bar. 21g sugar. Plant-based. 70% organic ingredients.', TRUE),

-- ══════════════════════════════════════════
-- RXBAR — PROTEIN BAR
-- ~210 cal, 12g P, 23g C, 9g F per 52g bar
-- per 100g: ~404 cal, 23g P, 37g C, 17g F
-- ══════════════════════════════════════════

-- RXBAR Chocolate Sea Salt: 210 cal / 52g bar
('rxbar_chocolate_sea_salt', 'RXBAR Chocolate Sea Salt', 404, 23.1, 36.5, 17.3,
 9.6, 23.1, NULL, 52,
 'website', ARRAY['rxbar chocolate sea salt', 'rx bar chocolate sea salt', 'rxbar chocolate', 'rxbar choc sea salt protein bar'],
 'protein_bar', 'RXBAR', 1, '210 cal, 12g protein, 19g carbs, 9g fat per 52g bar. 12g sugar. Made with egg whites, dates, nuts. No added sugar.', TRUE),

-- RXBAR Peanut Butter: 210 cal / 52g bar
('rxbar_peanut_butter', 'RXBAR Peanut Butter', 404, 23.1, 36.5, 17.3,
 9.6, 23.1, NULL, 52,
 'website', ARRAY['rxbar peanut butter', 'rx bar peanut butter', 'rxbar pb', 'rxbar peanut butter protein bar'],
 'protein_bar', 'RXBAR', 1, '210 cal, 12g protein, 19g carbs, 9g fat per 52g bar. 12g sugar. Made with egg whites, dates, peanuts. No added sugar.', TRUE),

-- RXBAR Blueberry: 210 cal / 52g bar
('rxbar_blueberry', 'RXBAR Blueberry', 404, 23.1, 36.5, 17.3,
 9.6, 23.1, NULL, 52,
 'website', ARRAY['rxbar blueberry', 'rx bar blueberry', 'rxbar blueberry protein bar', 'rxbar blueberry flavor'],
 'protein_bar', 'RXBAR', 1, '210 cal, 12g protein, 19g carbs, 9g fat per 52g bar. 12g sugar. Made with egg whites, dates, blueberries. No added sugar.', TRUE),

-- RXBAR Coconut Chocolate: 210 cal / 52g bar
('rxbar_coconut_chocolate', 'RXBAR Coconut Chocolate', 404, 23.1, 36.5, 17.3,
 9.6, 23.1, NULL, 52,
 'website', ARRAY['rxbar coconut chocolate', 'rx bar coconut chocolate', 'rxbar coconut choc', 'rxbar coconut chocolate protein bar'],
 'protein_bar', 'RXBAR', 1, '210 cal, 12g protein, 19g carbs, 9g fat per 52g bar. 12g sugar. Made with egg whites, dates, coconut, chocolate. No added sugar.', TRUE),

-- RXBAR Mint Chocolate: 200 cal / 52g bar
('rxbar_mint_chocolate', 'RXBAR Mint Chocolate', 385, 23.1, 36.5, 15.4,
 9.6, 21.2, NULL, 52,
 'website', ARRAY['rxbar mint chocolate', 'rx bar mint chocolate', 'rxbar mint choc', 'rxbar mint chocolate protein bar'],
 'protein_bar', 'RXBAR', 1, '200 cal, 12g protein, 19g carbs, 8g fat per 52g bar. 11g sugar. Made with egg whites, dates, chocolate, mint. No added sugar.', TRUE)

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
