-- 321_overrides_bars_energy.sql
-- Popular protein bars, energy bars, and granola bars.
-- Sources: questnutrition.com, rxbar.com, one1brands.com, built.com, barebells.com,
--   thinkproducts.com, pureprotein.com, clifbar.com, kindsnacks.com, larabar.com,
--   naturevalley.com, perfectsnacks.com, gomacro.com, quakeroats.com, fiberone.com,
--   fatsecret.com, nutritionix.com, calorieking.com, nutritionvalue.org, eatthismuch.com

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ============================================================================
-- QUEST BARS (60g per bar)
-- ============================================================================

-- Quest Bar Chocolate Chip Cookie Dough: 190 cal/bar (60g), 21g protein, 21g carbs, 9g fat, 12g fiber, 1g sugar
('quest_bar_chocolate_chip_cookie_dough', 'Quest Bar Chocolate Chip Cookie Dough', 317, 35.0, 35.0, 15.0,
 20.0, 1.7, NULL, 60,
 'quest', ARRAY['quest chocolate chip cookie dough', 'quest bar cookie dough', 'quest protein bar cookie dough'],
 'protein_bars', 'Quest', 1, '190 cal/bar (60g). 21g protein, 4g net carbs. High fiber, keto-friendly.', TRUE),

-- Quest Bar Birthday Cake: 180 cal/bar (60g), 20g protein, 25g carbs, 7g fat, 12g fiber, <1g sugar
('quest_bar_birthday_cake', 'Quest Bar Birthday Cake', 300, 33.3, 41.7, 11.7,
 20.0, 1.7, NULL, 60,
 'quest', ARRAY['quest birthday cake', 'quest bar birthday cake', 'quest protein bar birthday cake'],
 'protein_bars', 'Quest', 1, '180 cal/bar (60g). 20g protein, 4g net carbs. Gluten-free, keto-friendly.', TRUE),

-- Quest Bar Cookies & Cream: 190 cal/bar (60g), 21g protein, 22g carbs, 8g fat, 13g fiber, 1g sugar
('quest_bar_cookies_and_cream', 'Quest Bar Cookies & Cream', 317, 35.0, 36.7, 13.3,
 21.7, 1.7, NULL, 60,
 'quest', ARRAY['quest cookies cream', 'quest bar cookies and cream', 'quest protein bar cookies cream'],
 'protein_bars', 'Quest', 1, '190 cal/bar (60g). 21g protein, 4g net carbs. Gluten-free, keto-friendly.', TRUE),

-- Quest Bar Peanut Butter: 200 cal/bar (60g), 20g protein, 22g carbs, 9g fat, 11g fiber, 1g sugar
('quest_bar_peanut_butter', 'Quest Bar Peanut Butter', 333, 33.3, 36.7, 15.0,
 18.3, 1.7, NULL, 60,
 'quest', ARRAY['quest peanut butter', 'quest bar peanut butter', 'quest chocolate peanut butter bar'],
 'protein_bars', 'Quest', 1, '200 cal/bar (60g). 20g protein, 4g net carbs. Gluten-free, keto-friendly.', TRUE),

-- Quest Bar S''mores: 180 cal/bar (60g), 21g protein, 23g carbs, 7g fat, 12g fiber, 1g sugar
('quest_bar_smores', 'Quest Bar S''mores', 300, 35.0, 38.3, 11.7,
 20.0, 1.7, NULL, 60,
 'quest', ARRAY['quest smores', 'quest bar smores', 'quest protein bar s''mores'],
 'protein_bars', 'Quest', 1, '180 cal/bar (60g). 21g protein, 4g net carbs. Gluten-free, keto-friendly.', TRUE),

-- ============================================================================
-- RXBAR (52g per bar)
-- ============================================================================

-- RXBar Chocolate Sea Salt: 210 cal/bar (52g), 12g protein, 23g carbs, 9g fat, 5g fiber, 14g sugar
('rxbar_chocolate_sea_salt', 'RXBar Chocolate Sea Salt', 404, 23.1, 44.2, 17.3,
 9.6, 26.9, NULL, 52,
 'rxbar', ARRAY['rx bar chocolate sea salt', 'rxbar chocolate', 'rx protein bar chocolate sea salt'],
 'protein_bars', 'RXBar', 1, '210 cal/bar (52g). 12g protein. Made from egg whites, dates, nuts, chocolate. No added sugar.', TRUE),

-- RXBar Peanut Butter: 200 cal/bar (52g), 12g protein, 24g carbs, 7g fat, 5g fiber, 13g sugar
('rxbar_peanut_butter', 'RXBar Peanut Butter', 385, 23.1, 46.2, 13.5,
 9.6, 25.0, NULL, 52,
 'rxbar', ARRAY['rx bar peanut butter', 'rxbar pb', 'rx protein bar peanut butter'],
 'protein_bars', 'RXBar', 1, '200 cal/bar (52g). 12g protein. Made from egg whites, dates, peanuts. No added sugar.', TRUE),

-- RXBar Blueberry: 210 cal/bar (52g), 12g protein, 24g carbs, 8g fat, 5g fiber, 15g sugar
('rxbar_blueberry', 'RXBar Blueberry', 404, 23.1, 46.2, 15.4,
 9.6, 28.8, NULL, 52,
 'rxbar', ARRAY['rx bar blueberry', 'rxbar blueberry', 'rx protein bar blueberry'],
 'protein_bars', 'RXBar', 1, '210 cal/bar (52g). 12g protein. Made from egg whites, dates, almonds, cashews, blueberries.', TRUE),

-- RXBar Coconut Chocolate: 210 cal/bar (52g), 12g protein, 23g carbs, 8g fat, 5g fiber, 14g sugar
('rxbar_coconut_chocolate', 'RXBar Coconut Chocolate', 404, 23.1, 44.2, 15.4,
 9.6, 26.9, NULL, 52,
 'rxbar', ARRAY['rx bar coconut chocolate', 'rxbar coconut', 'rx protein bar coconut chocolate'],
 'protein_bars', 'RXBar', 1, '210 cal/bar (52g). 12g protein. Made from egg whites, dates, almonds, cashews, coconut, chocolate.', TRUE),

-- ============================================================================
-- ONE BAR (60g per bar)
-- ============================================================================

-- ONE Bar Birthday Cake: 220 cal/bar (60g), 20g protein, 24g carbs, 6g fat, 1g sugar
('one_bar_birthday_cake', 'ONE Bar Birthday Cake', 367, 33.3, 40.0, 10.0,
 0.0, 1.7, NULL, 60,
 'one', ARRAY['one birthday cake', 'one protein bar birthday cake', 'oh yeah one birthday cake'],
 'protein_bars', 'ONE', 1, '220 cal/bar (60g). 20g protein, 1g sugar. Gluten-free.', TRUE),

-- ONE Bar Peanut Butter Pie: 220 cal/bar (60g), 20g protein, 23g carbs, 8g fat, 1g sugar
('one_bar_peanut_butter_pie', 'ONE Bar Peanut Butter Pie', 367, 33.3, 38.3, 13.3,
 0.0, 1.7, NULL, 60,
 'one', ARRAY['one peanut butter pie', 'one protein bar peanut butter pie', 'oh yeah one peanut butter pie'],
 'protein_bars', 'ONE', 1, '220 cal/bar (60g). 20g protein, 1g sugar. Gluten-free.', TRUE),

-- ONE Bar Maple Glazed Donut: 220 cal/bar (60g), 20g protein, 23g carbs, 8g fat, 1g sugar
('one_bar_maple_glazed_donut', 'ONE Bar Maple Glazed Doughnut', 367, 33.3, 38.3, 13.3,
 0.0, 1.7, NULL, 60,
 'one', ARRAY['one maple glazed donut', 'one protein bar maple donut', 'oh yeah one maple glazed doughnut'],
 'protein_bars', 'ONE', 1, '220 cal/bar (60g). 20g protein, 1g sugar. Gluten-free.', TRUE),

-- ONE Bar Almond Bliss: 240 cal/bar (60g), 20g protein, 22g carbs, 10g fat, 3g fiber, 1g sugar
('one_bar_almond_bliss', 'ONE Bar Almond Bliss', 400, 33.3, 36.7, 16.7,
 5.0, 1.7, NULL, 60,
 'one', ARRAY['one almond bliss', 'one protein bar almond bliss', 'one chocolate almond bliss', 'oh yeah one almond bliss'],
 'protein_bars', 'ONE', 1, '240 cal/bar (60g). 20g protein, 1g sugar. Gluten-free, coconut almond flavor.', TRUE),

-- ============================================================================
-- BUILT BAR (40g per bar, Puff line)
-- ============================================================================

-- Built Bar Coconut Puff: 140 cal/bar (40g), 17g protein, 13g carbs, 3g fat, 4g sugar
('built_bar_coconut', 'Built Bar Coconut Puff', 350, 42.5, 32.5, 7.5,
 0.0, 10.0, NULL, 40,
 'built', ARRAY['built coconut', 'built bar coconut puff', 'built protein bar coconut'],
 'protein_bars', 'Built', 1, '140 cal/bar (40g). 17g protein. Contains collagen, gluten-free.', TRUE),

-- Built Bar Brownie Batter Puff: 140 cal/bar (40g), 17g protein, 14g carbs, 2.5g fat, 6g sugar
('built_bar_brownie_batter', 'Built Bar Brownie Batter Puff', 350, 42.5, 35.0, 6.3,
 0.0, 15.0, NULL, 40,
 'built', ARRAY['built brownie batter', 'built bar brownie batter puff', 'built protein bar brownie batter'],
 'protein_bars', 'Built', 1, '140 cal/bar (40g). 17g protein. Contains collagen, gluten-free.', TRUE),

-- Built Bar Salted Caramel Puff: 140 cal/bar (40g), 17g protein, 14g carbs, 2.5g fat, 6g sugar
('built_bar_salted_caramel', 'Built Bar Salted Caramel Puff', 350, 42.5, 35.0, 6.3,
 0.0, 15.0, NULL, 40,
 'built', ARRAY['built salted caramel', 'built bar salted caramel puff', 'built protein bar salted caramel'],
 'protein_bars', 'Built', 1, '140 cal/bar (40g). 17g protein. Contains collagen, gluten-free.', TRUE),

-- ============================================================================
-- BAREBELLS (55g per bar)
-- ============================================================================

-- Barebells Salty Peanut: 200 cal/bar (55g), 20g protein, 18g carbs, 8g fat, 3g fiber, 1g sugar
('barebells_salty_peanut', 'Barebells Salty Peanut', 364, 36.4, 32.7, 14.5,
 5.5, 1.8, NULL, 55,
 'barebells', ARRAY['barebells salty peanut', 'barebells protein bar salty peanut', 'barebells peanut'],
 'protein_bars', 'Barebells', 1, '200 cal/bar (55g). 20g protein, 1g sugar. No added sugar.', TRUE),

-- Barebells Cookies & Cream: 200 cal/bar (55g), 20g protein, 18g carbs, 7g fat, 3g fiber, 1g sugar
('barebells_cookies_and_cream', 'Barebells Cookies & Cream', 364, 36.4, 32.7, 12.7,
 5.5, 1.8, NULL, 55,
 'barebells', ARRAY['barebells cookies cream', 'barebells protein bar cookies cream', 'barebells cookies and cream'],
 'protein_bars', 'Barebells', 1, '200 cal/bar (55g). 20g protein, 1g sugar. No added sugar.', TRUE),

-- Barebells Caramel Cashew: 200 cal/bar (55g), 20g protein, 17g carbs, 9g fat, 3g fiber, 1g sugar
('barebells_caramel_cashew', 'Barebells Caramel Cashew', 364, 36.4, 30.9, 16.4,
 5.5, 1.8, NULL, 55,
 'barebells', ARRAY['barebells caramel cashew', 'barebells protein bar caramel cashew', 'barebells caramel'],
 'protein_bars', 'Barebells', 1, '200 cal/bar (55g). 20g protein, 1g sugar. No added sugar.', TRUE),

-- ============================================================================
-- THINK! HIGH PROTEIN (60g per bar)
-- ============================================================================

-- think! Brownie Crunch: 230 cal/bar (60g), 20g protein, 23g carbs, 8g fat, 0g sugar
('think_brownie_crunch', 'think! Brownie Crunch High Protein Bar', 383, 33.3, 38.3, 13.3,
 1.7, 0.0, NULL, 60,
 'think', ARRAY['think thin brownie crunch', 'think protein bar brownie crunch', 'thinkthin brownie crunch'],
 'protein_bars', 'think!', 1, '230 cal/bar (60g). 20g protein, 0g sugar. Gluten-free, sugar-free.', TRUE),

-- think! Chunky Peanut Butter: 240 cal/bar (60g), 20g protein, 23g carbs, 10g fat, 0g sugar
('think_chunky_peanut_butter', 'think! Chunky Peanut Butter High Protein Bar', 400, 33.3, 38.3, 16.7,
 1.7, 0.0, NULL, 60,
 'think', ARRAY['think thin chunky peanut butter', 'think protein bar peanut butter', 'thinkthin peanut butter'],
 'protein_bars', 'think!', 1, '240 cal/bar (60g). 20g protein, 0g sugar. Gluten-free, sugar-free.', TRUE),

-- ============================================================================
-- PURE PROTEIN (50g per bar)
-- ============================================================================

-- Pure Protein Chocolate Peanut Butter: 200 cal/bar (50g), 20g protein, 17g carbs, 6g fat, 2g fiber, 3g sugar
('pure_protein_chocolate_peanut_butter', 'Pure Protein Chocolate Peanut Butter', 400, 40.0, 34.0, 12.0,
 4.0, 6.0, NULL, 50,
 'pure_protein', ARRAY['pure protein chocolate peanut butter', 'pure protein bar chocolate pb', 'pure protein choc peanut butter'],
 'protein_bars', 'Pure Protein', 1, '200 cal/bar (50g). 20g protein, 3g sugar. Gluten-free.', TRUE),

-- Pure Protein Chocolate Deluxe: 180 cal/bar (50g), 21g protein, 17g carbs, 4.5g fat, 2g fiber, 3g sugar
('pure_protein_chocolate_deluxe', 'Pure Protein Chocolate Deluxe', 360, 42.0, 34.0, 9.0,
 4.0, 6.0, NULL, 50,
 'pure_protein', ARRAY['pure protein chocolate deluxe', 'pure protein bar chocolate', 'pure protein chocolate bar'],
 'protein_bars', 'Pure Protein', 1, '180 cal/bar (50g). 21g protein, 3g sugar. Gluten-free.', TRUE),

-- ============================================================================
-- CLIF BAR (68g per bar)
-- ============================================================================

-- Clif Bar Chocolate Chip: 250 cal/bar (68g), 9g protein, 45g carbs, 5g fat, 4g fiber, 21g sugar
('clif_bar_chocolate_chip', 'Clif Bar Chocolate Chip', 368, 13.2, 66.2, 7.4,
 5.9, 30.9, NULL, 68,
 'clif', ARRAY['clif chocolate chip', 'clif bar chocolate chip', 'clif energy bar chocolate chip'],
 'energy_bars', 'Clif', 1, '250 cal/bar (68g). 9g protein, 21g sugar. Made with organic oats. Plant-based energy bar.', TRUE),

-- Clif Bar Crunchy Peanut Butter: 260 cal/bar (68g), 11g protein, 40g carbs, 7g fat, 4g fiber, 19g sugar
('clif_bar_crunchy_peanut_butter', 'Clif Bar Crunchy Peanut Butter', 382, 16.2, 58.8, 10.3,
 5.9, 27.9, NULL, 68,
 'clif', ARRAY['clif crunchy peanut butter', 'clif bar peanut butter', 'clif energy bar peanut butter'],
 'energy_bars', 'Clif', 1, '260 cal/bar (68g). 11g protein, 19g sugar. Made with organic oats & peanut butter.', TRUE),

-- Clif Bar White Chocolate Macadamia: 260 cal/bar (68g), 9g protein, 41g carbs, 7g fat, 4g fiber, 21g sugar
('clif_bar_white_chocolate_macadamia', 'Clif Bar White Chocolate Macadamia', 382, 13.2, 60.3, 10.3,
 5.9, 30.9, NULL, 68,
 'clif', ARRAY['clif white chocolate macadamia', 'clif bar macadamia', 'clif energy bar white chocolate macadamia nut'],
 'energy_bars', 'Clif', 1, '260 cal/bar (68g). 9g protein, 21g sugar. Made with organic oats & macadamia nuts.', TRUE),

-- Clif Bar Blueberry Crisp: 250 cal/bar (68g), 10g protein, 43g carbs, 5g fat, 4g fiber, 21g sugar
('clif_bar_blueberry_crisp', 'Clif Bar Blueberry Crisp', 368, 14.7, 63.2, 7.4,
 5.9, 30.9, NULL, 68,
 'clif', ARRAY['clif blueberry crisp', 'clif bar blueberry', 'clif energy bar blueberry crisp'],
 'energy_bars', 'Clif', 1, '250 cal/bar (68g). 10g protein, 21g sugar. Made with organic oats.', TRUE),

-- ============================================================================
-- KIND BAR (40g per bar)
-- ============================================================================

-- KIND Dark Chocolate Nuts & Sea Salt: 200 cal/bar (40g), 6g protein, 16g carbs, 15g fat, 7g fiber, 5g sugar
('kind_dark_chocolate_nuts_sea_salt', 'KIND Dark Chocolate Nuts & Sea Salt', 500, 15.0, 40.0, 37.5,
 17.5, 12.5, NULL, 40,
 'kind', ARRAY['kind dark chocolate nuts sea salt', 'kind bar dark chocolate', 'kind dark chocolate almond sea salt'],
 'energy_bars', 'KIND', 1, '200 cal/bar (40g). 6g protein, 5g sugar. Gluten-free, whole nut bar.', TRUE),

-- KIND Peanut Butter Dark Chocolate: 200 cal/bar (40g), 7g protein, 17g carbs, 13g fat, 3g fiber, 8g sugar
('kind_peanut_butter_dark_chocolate', 'KIND Peanut Butter Dark Chocolate', 500, 17.5, 42.5, 32.5,
 7.5, 20.0, NULL, 40,
 'kind', ARRAY['kind peanut butter dark chocolate', 'kind bar pb dark chocolate', 'kind plus peanut butter dark chocolate'],
 'energy_bars', 'KIND', 1, '200 cal/bar (40g). 7g protein, 8g sugar. Gluten-free, good source of fiber.', TRUE),

-- KIND Almond & Coconut: 190 cal/bar (40g), 3g protein, 19g carbs, 14g fat, 3g fiber, 9g sugar
('kind_almond_coconut', 'KIND Almond & Coconut', 475, 7.5, 47.5, 35.0,
 7.5, 22.5, NULL, 40,
 'kind', ARRAY['kind almond coconut', 'kind bar almond and coconut', 'kind almond coconut bar'],
 'energy_bars', 'KIND', 1, '190 cal/bar (40g). 3g protein, 9g sugar. Dairy-free, gluten-free.', TRUE),

-- KIND Caramel Almond & Sea Salt: 200 cal/bar (40g), 6g protein, 16g carbs, 15g fat, 7g fiber, 5g sugar
('kind_caramel_almond_sea_salt', 'KIND Caramel Almond & Sea Salt', 500, 15.0, 40.0, 37.5,
 17.5, 12.5, NULL, 40,
 'kind', ARRAY['kind caramel almond sea salt', 'kind bar caramel almond', 'kind caramel almond and sea salt'],
 'energy_bars', 'KIND', 1, '200 cal/bar (40g). 6g protein, 5g sugar. Gluten-free, whole nut bar.', TRUE),

-- ============================================================================
-- LARABAR (45g per bar, except Apple Pie 45g, Lemon 45g)
-- ============================================================================

-- LARABAR Peanut Butter Chocolate Chip: 210 cal/bar (45g), 5g protein, 23g carbs, 12g fat, 3g fiber, 16g sugar
('larabar_peanut_butter_chocolate_chip', 'LARABAR Peanut Butter Chocolate Chip', 467, 11.1, 51.1, 26.7,
 6.7, 35.6, NULL, 45,
 'larabar', ARRAY['larabar peanut butter chocolate chip', 'larabar pb chocolate chip', 'lara bar peanut butter chocolate'],
 'energy_bars', 'LARABAR', 1, '210 cal/bar (45g). 5g protein. Made from dates, peanuts, chocolate chips, sea salt. Vegan, gluten-free.', TRUE),

-- LARABAR Cashew Cookie: 230 cal/bar (48g), 6g protein, 23g carbs, 13g fat, 2g fiber, 18g sugar
('larabar_cashew_cookie', 'LARABAR Cashew Cookie', 479, 12.5, 47.9, 27.1,
 4.2, 37.5, NULL, 48,
 'larabar', ARRAY['larabar cashew cookie', 'lara bar cashew cookie', 'larabar cashew'],
 'energy_bars', 'LARABAR', 1, '230 cal/bar (48g). 6g protein. Made from just 2 ingredients: cashews and dates. Vegan, gluten-free.', TRUE),

-- LARABAR Apple Pie: 200 cal/bar (45g), 4g protein, 32g carbs, 10g fat, 5g fiber, 22g sugar
('larabar_apple_pie', 'LARABAR Apple Pie', 444, 8.9, 71.1, 22.2,
 11.1, 48.9, NULL, 45,
 'larabar', ARRAY['larabar apple pie', 'lara bar apple pie', 'larabar apple'],
 'energy_bars', 'LARABAR', 1, '200 cal/bar (45g). 4g protein. Made from dates, almonds, apples, walnuts, raisins, cinnamon. Vegan.', TRUE),

-- LARABAR Lemon Bar: 220 cal/bar (45g), 4g protein, 24g carbs, 10g fat, 3g fiber, 16g sugar
('larabar_lemon_bar', 'LARABAR Lemon Bar', 489, 8.9, 53.3, 22.2,
 6.7, 35.6, NULL, 45,
 'larabar', ARRAY['larabar lemon bar', 'lara bar lemon', 'larabar lemon'],
 'energy_bars', 'LARABAR', 1, '220 cal/bar (45g). 4g protein. Made from dates, cashews, almonds, lemon. Vegan, gluten-free.', TRUE),

-- ============================================================================
-- NATURE VALLEY CRUNCHY (42g per 2-bar pouch, ~21g per single bar)
-- ============================================================================

-- Nature Valley Oats 'n Honey (2-bar pouch): 190 cal/pouch (42g), 3g protein, 29g carbs, 7g fat, 2g fiber, 11g sugar
('nature_valley_oats_n_honey', 'Nature Valley Crunchy Oats ''n Honey', 452, 7.1, 69.0, 16.7,
 4.8, 26.2, NULL, 42,
 'nature_valley', ARRAY['nature valley oats honey', 'nature valley crunchy oats n honey', 'nature valley granola bar oats honey'],
 'granola_bars', 'Nature Valley', 1, '190 cal/2-bar pouch (42g). 3g protein. 22g whole grain per serving. No artificial flavors.', TRUE),

-- Nature Valley Peanut Butter (2-bar pouch): 190 cal/pouch (42g), 5g protein, 28g carbs, 7g fat, 2g fiber, 11g sugar
('nature_valley_peanut_butter', 'Nature Valley Crunchy Peanut Butter', 452, 11.9, 66.7, 16.7,
 4.8, 26.2, NULL, 42,
 'nature_valley', ARRAY['nature valley peanut butter', 'nature valley crunchy peanut butter', 'nature valley granola bar peanut butter'],
 'granola_bars', 'Nature Valley', 1, '190 cal/2-bar pouch (42g). 5g protein. 20g whole grain per serving. No artificial flavors.', TRUE),

-- Nature Valley Oats 'n Dark Chocolate (2-bar pouch): 200 cal/pouch (42g), 3g protein, 29g carbs, 8g fat, 2g fiber, 13g sugar
('nature_valley_dark_chocolate', 'Nature Valley Crunchy Oats ''n Dark Chocolate', 476, 7.1, 69.0, 19.0,
 4.8, 31.0, NULL, 42,
 'nature_valley', ARRAY['nature valley dark chocolate', 'nature valley oats dark chocolate', 'nature valley crunchy dark chocolate'],
 'granola_bars', 'Nature Valley', 1, '200 cal/2-bar pouch (42g). 3g protein, 13g sugar. Made with real dark chocolate.', TRUE),

-- ============================================================================
-- PERFECT BAR (refrigerated protein bars)
-- ============================================================================

-- Perfect Bar Peanut Butter: 320 cal/bar (71g), 17g protein, 27g carbs, 19g fat, 3g fiber, 19g sugar
('perfect_bar_peanut_butter', 'Perfect Bar Peanut Butter', 451, 23.9, 38.0, 26.8,
 4.2, 26.8, NULL, 71,
 'perfect_bar', ARRAY['perfect bar peanut butter', 'perfect snacks peanut butter', 'perfect bar pb'],
 'protein_bars', 'Perfect Bar', 1, '320 cal/bar (71g). 17g protein, 19g fat. Refrigerated, organic, whole food protein bar.', TRUE),

-- Perfect Bar Dark Chocolate Chip Peanut Butter: 330 cal/bar (65g), 15g protein, 24g carbs, 20g fat, 4g fiber, 18g sugar
('perfect_bar_dark_chocolate_chip_peanut_butter', 'Perfect Bar Dark Chocolate Chip Peanut Butter', 508, 23.1, 36.9, 30.8,
 6.2, 27.7, NULL, 65,
 'perfect_bar', ARRAY['perfect bar dark chocolate peanut butter', 'perfect bar chocolate chip pb', 'perfect snacks dark choc pb'],
 'protein_bars', 'Perfect Bar', 1, '330 cal/bar (65g). 15g protein, 20g fat. Refrigerated, organic, with dark chocolate chips.', TRUE),

-- ============================================================================
-- GOMACRO (65-69g per bar)
-- ============================================================================

-- GoMacro Peanut Butter Chocolate Chip: 290 cal/bar (69g), 11g protein, 39g carbs, 11g fat, 2g fiber, 14g sugar
('gomacro_peanut_butter_chocolate_chip', 'GoMacro Peanut Butter Chocolate Chip MacroBar', 420, 15.9, 56.5, 15.9,
 2.9, 20.3, NULL, 69,
 'gomacro', ARRAY['gomacro peanut butter chocolate chip', 'gomacro macrobar peanut butter', 'go macro pb chocolate chip'],
 'energy_bars', 'GoMacro', 1, '290 cal/bar (69g). 11g protein. Organic, vegan, gluten-free. Plant-based protein.', TRUE),

-- GoMacro Sunflower Butter Chocolate: 270 cal/bar (65g), 10g protein, 38g carbs, 9g fat, 3g fiber, 11g sugar
('gomacro_sunflower_butter_chocolate', 'GoMacro Sunflower Butter + Chocolate MacroBar', 415, 15.4, 58.5, 13.8,
 4.6, 16.9, NULL, 65,
 'gomacro', ARRAY['gomacro sunflower butter chocolate', 'gomacro macrobar sunflower', 'go macro sunflower chocolate'],
 'energy_bars', 'GoMacro', 1, '270 cal/bar (65g). 10g protein. Organic, vegan, gluten-free. Nut-free (sunflower seed butter).', TRUE),

-- ============================================================================
-- QUAKER CHEWY (24g per bar)
-- ============================================================================

-- Quaker Chewy Chocolate Chip: 100 cal/bar (24g), 1g protein, 17g carbs, 3.5g fat, 1g fiber, 7g sugar
('quaker_chewy_chocolate_chip', 'Quaker Chewy Chocolate Chip', 417, 4.2, 70.8, 14.6,
 4.2, 29.2, NULL, 24,
 'quaker', ARRAY['quaker chewy chocolate chip', 'quaker granola bar chocolate chip', 'chewy chocolate chip granola bar'],
 'granola_bars', 'Quaker', 1, '100 cal/bar (24g). 1g protein. 9g whole grain. Classic chewy granola bar.', TRUE),

-- Quaker Chewy Peanut Butter Chocolate Chip: 100 cal/bar (24g), 2g protein, 17g carbs, 3g fat, 1g fiber, 7g sugar
('quaker_chewy_peanut_butter_chocolate_chip', 'Quaker Chewy Peanut Butter Chocolate Chip', 417, 8.3, 70.8, 12.5,
 4.2, 29.2, NULL, 24,
 'quaker', ARRAY['quaker chewy peanut butter chocolate chip', 'quaker granola bar pb chocolate chip', 'chewy pb chocolate chip'],
 'granola_bars', 'Quaker', 1, '100 cal/bar (24g). 2g protein. 8g whole grain. No high fructose corn syrup.', TRUE),

-- ============================================================================
-- KIND MINIS (20g per bar)
-- ============================================================================

-- KIND Minis Dark Chocolate Nuts & Sea Salt: 100 cal/bar (20g), 3g protein, 8g carbs, 7g fat, 2g fiber, 4g sugar
('kind_minis_dark_chocolate_nuts_sea_salt', 'KIND Minis Dark Chocolate Nuts & Sea Salt', 500, 15.0, 40.0, 35.0,
 10.0, 20.0, NULL, 20,
 'kind', ARRAY['kind minis dark chocolate', 'kind mini dark chocolate nuts sea salt', 'kind minis dark chocolate sea salt'],
 'granola_bars', 'KIND', 1, '100 cal/bar (20g). 3g protein. Portion-controlled mini nut bar. Gluten-free.', TRUE),

-- ============================================================================
-- FIBER ONE (40g chewy bar, 25g brownie)
-- ============================================================================

-- Fiber One Oats & Chocolate: 150 cal/bar (40g), 2g protein, 29g carbs, 4g fat, 9g fiber, 10g sugar
('fiber_one_oats_chocolate', 'Fiber One Oats & Chocolate Chewy Bar', 375, 5.0, 72.5, 10.0,
 22.5, 25.0, NULL, 40,
 'fiber_one', ARRAY['fiber one oats chocolate', 'fiber one chewy bar oats chocolate', 'fiber one oats and chocolate'],
 'granola_bars', 'Fiber One', 1, '150 cal/bar (40g). 2g protein, 9g fiber (32% DV). Chewy high-fiber bar.', TRUE),

-- Fiber One Brownies Chocolate Fudge: 70 cal/brownie (25g), 1g protein, 17g carbs, 3g fat, 6g fiber, 6g sugar
('fiber_one_brownies_chocolate_fudge', 'Fiber One 70 Cal Brownies Chocolate Fudge', 280, 4.0, 68.0, 12.0,
 24.0, 24.0, NULL, 25,
 'fiber_one', ARRAY['fiber one brownies', 'fiber one 70 cal brownie', 'fiber one chocolate fudge brownie', 'fiber one brownie'],
 'granola_bars', 'Fiber One', 1, '70 cal/brownie (25g). 1g protein, 6g fiber. Only 70 calories per brownie.', TRUE)

ON CONFLICT (food_name_normalized)
DO UPDATE SET
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
  notes = EXCLUDED.notes,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  is_active = TRUE,
  updated_at = NOW();
