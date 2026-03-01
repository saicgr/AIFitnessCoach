-- 323_overrides_energy_sports_drinks.sql
-- Popular energy drinks, sports drinks, and protein shakes (ready-to-drink).
-- All values per 100g (converted from per-can/bottle using ml≈g).
-- Sources: nutritionix.com, fatsecret.com, myfooddiary.com, official brand sites,
--          eatthismuch.com, mynetdiary.com, snapcalorie.com, calorieking.com

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════════════════════════════
-- ENERGY DRINKS
-- ══════════════════════════════════════════════════════════════════

-- ── RED BULL ──────────────────────────────────────────────────────
-- Red Bull Original 8.4 fl oz (248 ml): 110 cal, 0g protein, 28g carbs, 0g fat, 27g sugar
('red_bull_original', 'Red Bull Energy Drink (Original)', 44, 0.0, 11.3, 0.0,
 0.0, 10.9, 248, NULL,
 'red_bull', ARRAY['red bull', 'red bull original', 'red bull 8.4 oz', 'red bull energy drink', 'red bull regular'],
 'energy_drinks', 'Red Bull', 1, '110 cal per 8.4 fl oz (248ml) can. 80mg caffeine. Original taurine + B-vitamin formula.', TRUE),

-- Red Bull Sugar Free 8.4 fl oz (248 ml): 10 cal, 0g protein, 2g carbs, 0g fat, 0g sugar
('red_bull_sugar_free', 'Red Bull Sugar Free', 4, 0.0, 0.8, 0.0,
 0.0, 0.0, 248, NULL,
 'red_bull', ARRAY['red bull sugar free', 'red bull sf', 'red bull zero sugar', 'red bull diet', 'sugar free red bull'],
 'energy_drinks', 'Red Bull', 1, '10 cal per 8.4 fl oz (248ml) can. 80mg caffeine. Sweetened with aspartame and acesulfame K.', TRUE),

-- Red Bull Tropical Edition (Yellow) 8.4 fl oz (248 ml): 110 cal, 0g protein, 28g carbs, 0g fat, 27g sugar
('red_bull_tropical', 'Red Bull Tropical Edition', 44, 0.0, 11.3, 0.0,
 0.0, 10.9, 248, NULL,
 'red_bull', ARRAY['red bull tropical', 'red bull yellow edition', 'red bull tropical edition', 'tropical red bull'],
 'energy_drinks', 'Red Bull', 1, '110 cal per 8.4 fl oz (248ml) can. 80mg caffeine. Tropical fruit flavor (Yellow Edition).', TRUE),

-- Red Bull Coconut Edition 8.4 fl oz (248 ml): 110 cal, 0g protein, 28g carbs, 0g fat, 26g sugar
('red_bull_coconut', 'Red Bull Coconut Edition', 44, 0.0, 11.3, 0.0,
 0.0, 10.5, 248, NULL,
 'red_bull', ARRAY['red bull coconut', 'red bull coconut edition', 'red bull coconut berry', 'coconut red bull'],
 'energy_drinks', 'Red Bull', 1, '110 cal per 8.4 fl oz (248ml) can. 80mg caffeine. Coconut-berry flavor.', TRUE),

-- ── MONSTER ENERGY ────────────────────────────────────────────────
-- Monster Original 16 fl oz (473 ml): 230 cal, 0g protein, 58g carbs, 0g fat, 54g sugar
('monster_energy_original', 'Monster Energy (Original)', 49, 0.0, 12.3, 0.0,
 0.0, 11.4, 473, NULL,
 'monster', ARRAY['monster energy', 'monster original', 'monster green', 'monster energy drink', 'monster 16 oz'],
 'energy_drinks', 'Monster', 1, '230 cal per 16 fl oz (473ml) can. 160mg caffeine. Original Monster Energy blend.', TRUE),

-- Monster Zero Ultra 16 fl oz (473 ml): 10 cal, 0g protein, 6g carbs, 0g fat, 0g sugar
('monster_zero_ultra', 'Monster Zero Ultra', 2, 0.0, 1.3, 0.0,
 0.0, 0.0, 473, NULL,
 'monster', ARRAY['monster zero ultra', 'monster ultra', 'monster white', 'white monster', 'monster zero', 'monster sugar free'],
 'energy_drinks', 'Monster', 1, '10 cal per 16 fl oz (473ml) can. 150mg caffeine. Zero sugar, lighter flavor.', TRUE),

-- Monster Mango Loco 16 fl oz (473 ml): 250 cal, 0g protein, 64g carbs, 0g fat, 55g sugar
('monster_mango_loco', 'Monster Juice Mango Loco', 53, 0.0, 13.5, 0.0,
 0.0, 11.6, 473, NULL,
 'monster', ARRAY['monster mango loco', 'mango loco monster', 'monster juice mango', 'monster mango'],
 'energy_drinks', 'Monster', 1, '250 cal per 16 fl oz (473ml) can. 152mg caffeine. Mango juice blend.', TRUE),

-- Monster Pipeline Punch 16 fl oz (473 ml): 190 cal, 0g protein, 48g carbs, 0g fat, 46g sugar
('monster_pipeline_punch', 'Monster Juice Pipeline Punch', 40, 0.0, 10.1, 0.0,
 0.0, 9.7, 473, NULL,
 'monster', ARRAY['monster pipeline punch', 'pipeline punch monster', 'monster juice pipeline', 'monster punch'],
 'energy_drinks', 'Monster', 1, '190 cal per 16 fl oz (473ml) can. 160mg caffeine. Passion fruit, orange, guava juice blend.', TRUE),

-- Java Monster Mean Bean 15 fl oz (443 ml): 220 cal, 8g protein, 37g carbs, 4g fat, 35g sugar
('java_monster_mean_bean', 'Java Monster Mean Bean', 50, 1.8, 8.4, 0.9,
 0.0, 7.9, 443, NULL,
 'monster', ARRAY['java monster mean bean', 'mean bean monster', 'java monster', 'monster coffee', 'monster mean bean'],
 'energy_drinks', 'Monster', 1, '220 cal per 15 fl oz (443ml) can. 200mg caffeine. Brewed coffee + milk + energy blend.', TRUE),

-- ── CELSIUS ───────────────────────────────────────────────────────
-- Celsius Original (Sparkling Orange) 12 fl oz (355 ml): 10 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('celsius_original', 'Celsius Energy Drink (Original)', 3, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'celsius', ARRAY['celsius', 'celsius original', 'celsius sparkling orange', 'celsius energy drink', 'celsius sparkling'],
 'energy_drinks', 'Celsius', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar, 7 essential vitamins.', TRUE),

-- Celsius Sparkling Watermelon 12 fl oz (355 ml): 10 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('celsius_sparkling_watermelon', 'Celsius Sparkling Watermelon', 3, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'celsius', ARRAY['celsius watermelon', 'celsius sparkling watermelon', 'watermelon celsius'],
 'energy_drinks', 'Celsius', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar, watermelon flavor.', TRUE),

-- Celsius Tropical Vibe 12 fl oz (355 ml): 10 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('celsius_tropical_vibe', 'Celsius Sparkling Tropical Vibe', 3, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'celsius', ARRAY['celsius tropical vibe', 'celsius tropical', 'celsius starfruit pineapple', 'tropical vibe celsius'],
 'energy_drinks', 'Celsius', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Starfruit-pineapple flavor.', TRUE),

-- Celsius Peach Mango Green Tea 12 fl oz (355 ml): 10 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('celsius_peach_mango_green_tea', 'Celsius Peach Mango Green Tea', 3, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'celsius', ARRAY['celsius peach mango', 'celsius green tea', 'celsius peach mango green tea', 'peach mango celsius'],
 'energy_drinks', 'Celsius', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Non-carbonated (Fizz Free) green tea base.', TRUE),

-- Celsius Heat 16 fl oz (473 ml): 15 cal, 0g protein, 4g carbs, 0g fat, 0g sugar
('celsius_heat', 'Celsius Heat Performance Energy', 3, 0.0, 0.8, 0.0,
 0.0, 0.0, 473, NULL,
 'celsius', ARRAY['celsius heat', 'celsius heat performance', 'celsius 16 oz', 'celsius pre workout'],
 'energy_drinks', 'Celsius', 1, '15 cal per 16 fl oz (473ml) can. 300mg caffeine. Extra caffeine + 2000mg L-citrulline.', TRUE),

-- ── BANG ENERGY ───────────────────────────────────────────────────
-- Bang Energy 16 fl oz (473 ml): 0 cal, 0g protein, 0g carbs, 0g fat, 0g sugar (all flavors)
('bang_rainbow_unicorn', 'Bang Energy Rainbow Unicorn', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'bang', ARRAY['bang rainbow unicorn', 'rainbow unicorn bang', 'bang energy rainbow'],
 'energy_drinks', 'Bang', 1, '0 cal per 16 fl oz (473ml) can. 300mg caffeine. Zero sugar, zero carbs. Contains Super Creatine.', TRUE),

('bang_black_cherry_vanilla', 'Bang Energy Black Cherry Vanilla', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'bang', ARRAY['bang black cherry vanilla', 'black cherry vanilla bang', 'bang cherry vanilla'],
 'energy_drinks', 'Bang', 1, '0 cal per 16 fl oz (473ml) can. 300mg caffeine. Zero sugar, zero carbs.', TRUE),

('bang_lemon_drop', 'Bang Energy Lemon Drop', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'bang', ARRAY['bang lemon drop', 'lemon drop bang', 'bang energy lemon'],
 'energy_drinks', 'Bang', 1, '0 cal per 16 fl oz (473ml) can. 300mg caffeine. Zero sugar, zero carbs.', TRUE),

('bang_cotton_candy', 'Bang Energy Cotton Candy', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'bang', ARRAY['bang cotton candy', 'cotton candy bang', 'bang energy cotton candy'],
 'energy_drinks', 'Bang', 1, '0 cal per 16 fl oz (473ml) can. 300mg caffeine. Zero sugar, zero carbs.', TRUE),

-- ── REIGN ─────────────────────────────────────────────────────────
-- Reign 16 fl oz (473 ml): 10 cal, 0g protein, 3g carbs, 0g fat, 0g sugar
('reign_orange_dreamsicle', 'Reign Orange Dreamsicle', 2, 0.0, 0.6, 0.0,
 0.0, 0.0, 473, NULL,
 'reign', ARRAY['reign orange dreamsicle', 'orange dreamsicle reign', 'reign total body fuel orange'],
 'energy_drinks', 'Reign', 1, '10 cal per 16 fl oz (473ml) can. 300mg caffeine. BCAAs, CoQ10, electrolytes.', TRUE),

('reign_lemon_hdz', 'Reign Lemon HDZ', 2, 0.0, 0.6, 0.0,
 0.0, 0.0, 473, NULL,
 'reign', ARRAY['reign lemon hdz', 'lemon hdz reign', 'reign lemon', 'reign total body fuel lemon'],
 'energy_drinks', 'Reign', 1, '10 cal per 16 fl oz (473ml) can. 300mg caffeine. BCAAs, CoQ10, electrolytes.', TRUE),

('reign_razzle_berry', 'Reign Razzle Berry', 2, 0.0, 0.6, 0.0,
 0.0, 0.0, 473, NULL,
 'reign', ARRAY['reign razzle berry', 'razzle berry reign', 'reign berry', 'reign total body fuel razzle berry'],
 'energy_drinks', 'Reign', 1, '10 cal per 16 fl oz (473ml) can. 300mg caffeine. BCAAs, CoQ10, electrolytes.', TRUE),

-- ── C4 ENERGY ─────────────────────────────────────────────────────
-- C4 Energy 16 fl oz (473 ml): 0 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('c4_frozen_bombsicle', 'C4 Energy Frozen Bombsicle', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'c4', ARRAY['c4 frozen bombsicle', 'frozen bombsicle c4', 'c4 energy frozen bombsicle', 'c4 performance energy'],
 'energy_drinks', 'C4', 1, '0 cal per 16 fl oz (473ml) can. 200mg caffeine. Zero sugar. Pre-workout energy blend with beta alanine.', TRUE),

('c4_starburst_cherry', 'C4 Energy Starburst Cherry', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 473, NULL,
 'c4', ARRAY['c4 starburst cherry', 'c4 cherry starburst', 'c4 energy cherry', 'c4 starburst'],
 'energy_drinks', 'C4', 1, '0 cal per 16 fl oz (473ml) can. 200mg caffeine. Zero sugar. Starburst collaboration flavor.', TRUE),

-- ── GHOST ENERGY ──────────────────────────────────────────────────
-- Ghost Energy 16 fl oz (473 ml): 5 cal, 0g protein, 1g carbs, 0g fat, 0g sugar
('ghost_swedish_fish', 'Ghost Energy Swedish Fish', 1, 0.0, 0.2, 0.0,
 0.0, 0.0, 473, NULL,
 'ghost', ARRAY['ghost swedish fish', 'swedish fish ghost', 'ghost energy swedish fish'],
 'energy_drinks', 'Ghost', 1, '5 cal per 16 fl oz (473ml) can. 200mg caffeine. Zero sugar. 1000mg L-carnitine, 1000mg taurine.', TRUE),

('ghost_sour_patch', 'Ghost Energy Sour Patch Kids', 1, 0.0, 0.2, 0.0,
 0.0, 0.0, 473, NULL,
 'ghost', ARRAY['ghost sour patch', 'ghost sour patch kids', 'sour patch ghost', 'ghost energy sour patch'],
 'energy_drinks', 'Ghost', 1, '5 cal per 16 fl oz (473ml) can. 200mg caffeine. Zero sugar. 1000mg L-carnitine, 1000mg taurine.', TRUE),

('ghost_warheads', 'Ghost Energy Warheads', 1, 0.0, 0.2, 0.0,
 0.0, 0.0, 473, NULL,
 'ghost', ARRAY['ghost warheads', 'warheads ghost', 'ghost energy warheads', 'ghost sour warheads'],
 'energy_drinks', 'Ghost', 1, '5 cal per 16 fl oz (473ml) can. 200mg caffeine. Zero sugar. 1000mg L-carnitine, 1000mg taurine.', TRUE),

-- ── ALANI NU ──────────────────────────────────────────────────────
-- Alani Nu 12 fl oz (355 ml): 10 cal, 0g protein, 2g carbs, 0g fat, 0g sugar
('alani_nu_mimosa', 'Alani Nu Energy Mimosa', 3, 0.0, 0.6, 0.0,
 0.0, 0.0, 355, NULL,
 'alani_nu', ARRAY['alani nu mimosa', 'alani mimosa', 'alani nu energy mimosa'],
 'energy_drinks', 'Alani Nu', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar, biotin, B vitamins.', TRUE),

('alani_nu_cosmic_stardust', 'Alani Nu Energy Cosmic Stardust', 3, 0.0, 0.6, 0.0,
 0.0, 0.0, 355, NULL,
 'alani_nu', ARRAY['alani nu cosmic stardust', 'alani cosmic stardust', 'cosmic stardust alani'],
 'energy_drinks', 'Alani Nu', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar, biotin, B vitamins.', TRUE),

('alani_nu_hawaiian_shaved_ice', 'Alani Nu Energy Hawaiian Shaved Ice', 3, 0.0, 0.6, 0.0,
 0.0, 0.0, 355, NULL,
 'alani_nu', ARRAY['alani nu hawaiian shaved ice', 'alani hawaiian shaved ice', 'hawaiian shaved ice alani'],
 'energy_drinks', 'Alani Nu', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar, biotin, B vitamins.', TRUE),

('alani_nu_cherry_slush', 'Alani Nu Energy Cherry Slush', 3, 0.0, 0.6, 0.0,
 0.0, 0.0, 355, NULL,
 'alani_nu', ARRAY['alani nu cherry slush', 'alani cherry slush', 'cherry slush alani'],
 'energy_drinks', 'Alani Nu', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar, biotin, B vitamins.', TRUE),

-- ── ZOA ENERGY ────────────────────────────────────────────────────
-- ZOA Zero Sugar Original 16 fl oz (473 ml): 15 cal, 0g protein, 4g carbs, 0g fat, 0g sugar
('zoa_original', 'ZOA Energy Original (Zero Sugar)', 3, 0.0, 0.8, 0.0,
 0.0, 0.0, 473, NULL,
 'zoa', ARRAY['zoa original', 'zoa energy', 'zoa energy drink', 'zoa zero sugar original'],
 'energy_drinks', 'ZOA', 1, '15 cal per 16 fl oz (473ml) can. 160mg caffeine from green tea + green coffee. Zero sugar.', TRUE),

-- ZOA Pineapple Coconut 16 fl oz (473 ml): 15 cal, 0g protein, 4g carbs, 0g fat, 0g sugar
('zoa_pineapple_coconut', 'ZOA Energy Pineapple Coconut', 3, 0.0, 0.8, 0.0,
 0.0, 0.0, 473, NULL,
 'zoa', ARRAY['zoa pineapple coconut', 'zoa pineapple', 'zoa coconut pineapple'],
 'energy_drinks', 'ZOA', 1, '15 cal per 16 fl oz (473ml) can. 160mg caffeine. Zero sugar, electrolytes.', TRUE),

-- ZOA Wild Orange 16 fl oz (473 ml): 15 cal, 0g protein, 4g carbs, 0g fat, 0g sugar
('zoa_wild_orange', 'ZOA Energy Wild Orange', 3, 0.0, 0.8, 0.0,
 0.0, 0.0, 473, NULL,
 'zoa', ARRAY['zoa wild orange', 'zoa orange', 'zoa energy wild orange'],
 'energy_drinks', 'ZOA', 1, '15 cal per 16 fl oz (473ml) can. 160mg caffeine. Zero sugar, electrolytes.', TRUE),

-- ── PRIME ENERGY ──────────────────────────────────────────────────
-- Prime Energy 12 fl oz (355 ml): 10 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('prime_energy', 'Prime Energy Drink', 3, 0.0, 0.0, 0.0,
 0.0, 0.0, 355, NULL,
 'prime', ARRAY['prime energy', 'prime energy drink', 'prime can', 'prime energy original'],
 'energy_drinks', 'Prime', 1, '10 cal per 12 fl oz (355ml) can. 200mg caffeine. Zero sugar. 355mg electrolytes + coconut water.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- SPORTS DRINKS
-- ══════════════════════════════════════════════════════════════════

-- ── GATORADE ──────────────────────────────────────────────────────
-- Gatorade Original 20 fl oz (591 ml): 140 cal, 0g protein, 36g carbs, 0g fat, 34g sugar
('gatorade_lemon_lime', 'Gatorade Thirst Quencher Lemon Lime', 24, 0.0, 6.1, 0.0,
 0.0, 5.8, 591, NULL,
 'gatorade', ARRAY['gatorade lemon lime', 'gatorade original', 'gatorade yellow', 'gatorade lemon-lime'],
 'sports_drinks', 'Gatorade', 1, '140 cal per 20 fl oz (591ml) bottle. Electrolytes: sodium, potassium. Classic sports drink.', TRUE),

('gatorade_fruit_punch', 'Gatorade Thirst Quencher Fruit Punch', 24, 0.0, 6.1, 0.0,
 0.0, 5.8, 591, NULL,
 'gatorade', ARRAY['gatorade fruit punch', 'gatorade red', 'gatorade punch'],
 'sports_drinks', 'Gatorade', 1, '140 cal per 20 fl oz (591ml) bottle. Electrolytes: sodium, potassium.', TRUE),

('gatorade_cool_blue', 'Gatorade Thirst Quencher Cool Blue', 24, 0.0, 6.1, 0.0,
 0.0, 5.8, 591, NULL,
 'gatorade', ARRAY['gatorade cool blue', 'gatorade blue', 'cool blue gatorade', 'gatorade blue raspberry'],
 'sports_drinks', 'Gatorade', 1, '140 cal per 20 fl oz (591ml) bottle. Electrolytes: sodium, potassium.', TRUE),

('gatorade_glacier_freeze', 'Gatorade Frost Glacier Freeze', 24, 0.0, 6.1, 0.0,
 0.0, 5.8, 591, NULL,
 'gatorade', ARRAY['gatorade glacier freeze', 'gatorade frost', 'glacier freeze gatorade', 'gatorade light blue'],
 'sports_drinks', 'Gatorade', 1, '140 cal per 20 fl oz (591ml) bottle. Frost series, lighter flavor.', TRUE),

-- Gatorade Zero Sugar 20 fl oz (591 ml): 5 cal, 0g protein, 1g carbs, 0g fat, 0g sugar
('gatorade_zero_lemon_lime', 'Gatorade Zero Sugar Lemon Lime', 1, 0.0, 0.2, 0.0,
 0.0, 0.0, 591, NULL,
 'gatorade', ARRAY['gatorade zero lemon lime', 'gatorade zero', 'g zero lemon lime', 'gatorade zero sugar'],
 'sports_drinks', 'Gatorade', 1, '5 cal per 20 fl oz (591ml) bottle. Zero sugar with electrolytes. Sucralose sweetened.', TRUE),

('gatorade_zero_fruit_punch', 'Gatorade Zero Sugar Fruit Punch', 1, 0.0, 0.2, 0.0,
 0.0, 0.0, 591, NULL,
 'gatorade', ARRAY['gatorade zero fruit punch', 'gatorade zero red', 'g zero fruit punch'],
 'sports_drinks', 'Gatorade', 1, '5 cal per 20 fl oz (591ml) bottle. Zero sugar with electrolytes.', TRUE),

('gatorade_zero_glacier_freeze', 'Gatorade Zero Sugar Glacier Freeze', 1, 0.0, 0.2, 0.0,
 0.0, 0.0, 591, NULL,
 'gatorade', ARRAY['gatorade zero glacier freeze', 'gatorade zero blue', 'g zero glacier freeze'],
 'sports_drinks', 'Gatorade', 1, '5 cal per 20 fl oz (591ml) bottle. Zero sugar with electrolytes.', TRUE),

-- ── POWERADE ──────────────────────────────────────────────────────
-- Powerade 20 fl oz (591 ml): 130 cal, 0g protein, 35g carbs, 0g fat, 35g sugar
('powerade_mountain_berry_blast', 'Powerade Mountain Berry Blast', 22, 0.0, 5.9, 0.0,
 0.0, 5.9, 591, NULL,
 'powerade', ARRAY['powerade mountain berry blast', 'powerade mountain berry', 'powerade blue', 'powerade berry'],
 'sports_drinks', 'Powerade', 1, '130 cal per 20 fl oz (591ml) bottle. Electrolytes + B vitamins.', TRUE),

('powerade_fruit_punch', 'Powerade Fruit Punch', 22, 0.0, 5.9, 0.0,
 0.0, 5.9, 591, NULL,
 'powerade', ARRAY['powerade fruit punch', 'powerade red', 'powerade punch'],
 'sports_drinks', 'Powerade', 1, '130 cal per 20 fl oz (591ml) bottle. Electrolytes + B vitamins.', TRUE),

('powerade_grape', 'Powerade Grape', 22, 0.0, 5.9, 0.0,
 0.0, 5.9, 591, NULL,
 'powerade', ARRAY['powerade grape', 'powerade purple', 'grape powerade'],
 'sports_drinks', 'Powerade', 1, '130 cal per 20 fl oz (591ml) bottle. Electrolytes + B vitamins.', TRUE),

-- Powerade Zero Sugar 20 fl oz (591 ml): 0 cal, 0g protein, 0g carbs, 0g fat, 0g sugar
('powerade_zero_sugar', 'Powerade Zero Sugar', 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 591, NULL,
 'powerade', ARRAY['powerade zero', 'powerade zero sugar', 'powerade zero calorie', 'powerade diet'],
 'sports_drinks', 'Powerade', 1, '0 cal per 20 fl oz (591ml) bottle. Zero sugar, zero calories with electrolytes + vitamins B & C.', TRUE),

-- ── BODY ARMOR ────────────────────────────────────────────────────
-- Body Armor 16 fl oz (473 ml): 70 cal, 0g protein, 18g carbs, 0g fat, 18g sugar (Strawberry Banana per official label)
('bodyarmor_strawberry_banana', 'Body Armor Strawberry Banana', 15, 0.0, 3.8, 0.0,
 0.0, 3.8, 473, NULL,
 'bodyarmor', ARRAY['body armor strawberry banana', 'bodyarmor strawberry banana', 'body armour strawberry banana'],
 'sports_drinks', 'Body Armor', 1, '70 cal per 16 fl oz (473ml) bottle. Coconut water, potassium-packed electrolytes, vitamins.', TRUE),

-- Body Armor Orange Mango 16 fl oz (473 ml): 70 cal, 0g protein, 18g carbs, 0g fat, 18g sugar
('bodyarmor_orange_mango', 'Body Armor Orange Mango', 15, 0.0, 3.8, 0.0,
 0.0, 3.8, 473, NULL,
 'bodyarmor', ARRAY['body armor orange mango', 'bodyarmor orange mango', 'body armour orange mango'],
 'sports_drinks', 'Body Armor', 1, '70 cal per 16 fl oz (473ml) bottle. Coconut water, potassium-packed electrolytes, vitamins.', TRUE),

-- Body Armor Fruit Punch 16 fl oz (473 ml): 120 cal, 0g protein, 29g carbs, 0g fat, 29g sugar
('bodyarmor_fruit_punch', 'Body Armor Fruit Punch', 25, 0.0, 6.1, 0.0,
 0.0, 6.1, 473, NULL,
 'bodyarmor', ARRAY['body armor fruit punch', 'bodyarmor fruit punch', 'body armour fruit punch'],
 'sports_drinks', 'Body Armor', 1, '120 cal per 16 fl oz (473ml) bottle. Coconut water, potassium-packed electrolytes, vitamins.', TRUE),

-- Body Armor Lyte 16 fl oz (473 ml): 20 cal, 0g protein, 5g carbs, 0g fat, 3g sugar
('bodyarmor_lyte_strawberry_banana', 'Body Armor Lyte Strawberry Banana', 4, 0.0, 1.1, 0.0,
 0.0, 0.6, 473, NULL,
 'bodyarmor', ARRAY['body armor lyte strawberry banana', 'bodyarmor lyte', 'body armor lite strawberry banana'],
 'sports_drinks', 'Body Armor', 1, '20 cal per 16 fl oz (473ml) bottle. Low-calorie. No added sugar, no artificial sweeteners.', TRUE),

('bodyarmor_lyte_peach_mango', 'Body Armor Lyte Peach Mango', 4, 0.0, 1.1, 0.0,
 0.0, 0.6, 473, NULL,
 'bodyarmor', ARRAY['body armor lyte peach mango', 'bodyarmor lyte peach mango', 'body armor lite peach mango'],
 'sports_drinks', 'Body Armor', 1, '20 cal per 16 fl oz (473ml) bottle. Low-calorie. No added sugar, no artificial sweeteners.', TRUE),

-- ── PRIME HYDRATION ───────────────────────────────────────────────
-- Prime Hydration 16.9 fl oz (500 ml): 25 cal, 0g protein, 6g carbs, 0g fat, 2g sugar
('prime_hydration_blue_raspberry', 'Prime Hydration Blue Raspberry', 5, 0.0, 1.2, 0.0,
 0.0, 0.4, 500, NULL,
 'prime', ARRAY['prime hydration blue raspberry', 'prime blue raspberry', 'prime drink blue raspberry'],
 'sports_drinks', 'Prime', 1, '25 cal per 16.9 fl oz (500ml) bottle. 10% coconut water, BCAAs, B vitamins, electrolytes. Caffeine-free.', TRUE),

('prime_hydration_tropical_punch', 'Prime Hydration Tropical Punch', 5, 0.0, 1.2, 0.0,
 0.0, 0.4, 500, NULL,
 'prime', ARRAY['prime hydration tropical punch', 'prime tropical punch', 'prime drink tropical punch'],
 'sports_drinks', 'Prime', 1, '25 cal per 16.9 fl oz (500ml) bottle. 10% coconut water, BCAAs, B vitamins, electrolytes. Caffeine-free.', TRUE),

('prime_hydration_lemon_lime', 'Prime Hydration Lemon Lime', 5, 0.0, 1.2, 0.0,
 0.0, 0.4, 500, NULL,
 'prime', ARRAY['prime hydration lemon lime', 'prime lemon lime', 'prime drink lemon lime'],
 'sports_drinks', 'Prime', 1, '25 cal per 16.9 fl oz (500ml) bottle. 10% coconut water, BCAAs, B vitamins, electrolytes. Caffeine-free.', TRUE),

('prime_hydration_ice_pop', 'Prime Hydration Ice Pop', 4, 0.0, 1.0, 0.0,
 0.0, 0.4, 500, NULL,
 'prime', ARRAY['prime hydration ice pop', 'prime ice pop', 'prime drink ice pop'],
 'sports_drinks', 'Prime', 1, '20 cal per 16.9 fl oz (500ml) bottle. 10% coconut water, BCAAs, B vitamins, electrolytes. Caffeine-free.', TRUE),

-- ── LIQUID IV ─────────────────────────────────────────────────────
-- Liquid IV per packet (15g powder) reconstituted in ~473 ml (16 oz) water: 45 cal, 0g protein, 11g carbs, 0g fat, 11g sugar
('liquid_iv_lemon_lime', 'Liquid IV Hydration Multiplier Lemon Lime', 9, 0.0, 2.3, 0.0,
 0.0, 2.3, 488, NULL,
 'liquid_iv', ARRAY['liquid iv lemon lime', 'liquid iv', 'liquid i.v. lemon lime', 'liquid iv hydration lemon lime'],
 'sports_drinks', 'Liquid IV', 1, '45 cal per packet (15g + 473ml water = ~488g). 3x electrolytes vs sports drinks. Cellular Transport Technology.', TRUE),

('liquid_iv_passion_fruit', 'Liquid IV Hydration Multiplier Passion Fruit', 10, 0.0, 2.7, 0.0,
 0.0, 2.7, 488, NULL,
 'liquid_iv', ARRAY['liquid iv passion fruit', 'liquid i.v. passion fruit', 'liquid iv hydration passion fruit'],
 'sports_drinks', 'Liquid IV', 1, '50 cal per packet (15g + 473ml water = ~488g). 3x electrolytes vs sports drinks.', TRUE),

('liquid_iv_strawberry', 'Liquid IV Hydration Multiplier Strawberry', 10, 0.0, 2.7, 0.0,
 0.0, 2.7, 488, NULL,
 'liquid_iv', ARRAY['liquid iv strawberry', 'liquid i.v. strawberry', 'liquid iv hydration strawberry'],
 'sports_drinks', 'Liquid IV', 1, '50 cal per packet (15g + 473ml water = ~488g). 3x electrolytes vs sports drinks.', TRUE),

-- ══════════════════════════════════════════════════════════════════
-- PROTEIN SHAKES (READY-TO-DRINK)
-- ══════════════════════════════════════════════════════════════════

-- ── FAIRLIFE CORE POWER ───────────────────────────────────────────
-- Core Power 14 fl oz (414 ml): 170 cal, 26g protein, 6g carbs, 4.5g fat, 5g sugar (Chocolate)
('core_power_chocolate', 'Fairlife Core Power Chocolate (26g Protein)', 41, 6.3, 1.4, 1.1,
 0.0, 1.2, 414, NULL,
 'fairlife', ARRAY['core power chocolate', 'fairlife core power chocolate', 'core power 26g chocolate', 'fairlife chocolate protein'],
 'protein_shakes', 'Fairlife', 1, '170 cal per 14 fl oz (414ml) bottle. 26g complete protein. Lactose-free ultra-filtered milk.', TRUE),

-- Core Power Vanilla 14 fl oz (414 ml): 170 cal, 26g protein, 6g carbs, 4.5g fat, 5g sugar
('core_power_vanilla', 'Fairlife Core Power Vanilla (26g Protein)', 41, 6.3, 1.4, 1.1,
 0.0, 1.2, 414, NULL,
 'fairlife', ARRAY['core power vanilla', 'fairlife core power vanilla', 'core power 26g vanilla', 'fairlife vanilla protein'],
 'protein_shakes', 'Fairlife', 1, '170 cal per 14 fl oz (414ml) bottle. 26g complete protein. Lactose-free ultra-filtered milk.', TRUE),

-- Core Power Strawberry Banana 14 fl oz (414 ml): 170 cal, 26g protein, 7g carbs, 4.5g fat, 6g sugar
('core_power_strawberry_banana', 'Fairlife Core Power Strawberry Banana (26g Protein)', 41, 6.3, 1.7, 1.1,
 0.0, 1.4, 414, NULL,
 'fairlife', ARRAY['core power strawberry banana', 'fairlife core power strawberry banana', 'core power 26g strawberry banana'],
 'protein_shakes', 'Fairlife', 1, '170 cal per 14 fl oz (414ml) bottle. 26g complete protein. Lactose-free ultra-filtered milk.', TRUE),

-- ── PREMIER PROTEIN ───────────────────────────────────────────────
-- Premier Protein 11.5 fl oz (340 ml): 160 cal, 30g protein, 5g carbs, 3g fat, 1g sugar
('premier_protein_chocolate', 'Premier Protein Shake Chocolate', 47, 8.8, 1.5, 0.9,
 0.0, 0.3, 340, NULL,
 'premier_protein', ARRAY['premier protein chocolate', 'premier protein shake chocolate', 'premier protein 30g chocolate'],
 'protein_shakes', 'Premier Protein', 1, '160 cal per 11.5 fl oz (340ml) bottle. 30g protein, 1g sugar. 24 vitamins & minerals.', TRUE),

('premier_protein_vanilla', 'Premier Protein Shake Vanilla', 47, 8.8, 1.2, 0.9,
 0.0, 0.3, 340, NULL,
 'premier_protein', ARRAY['premier protein vanilla', 'premier protein shake vanilla', 'premier protein 30g vanilla'],
 'protein_shakes', 'Premier Protein', 1, '160 cal per 11.5 fl oz (340ml) bottle. 30g protein, 1g sugar. 24 vitamins & minerals.', TRUE),

('premier_protein_caramel', 'Premier Protein Shake Caramel', 47, 8.8, 1.5, 0.9,
 0.0, 0.3, 340, NULL,
 'premier_protein', ARRAY['premier protein caramel', 'premier protein shake caramel', 'premier protein 30g caramel'],
 'protein_shakes', 'Premier Protein', 1, '160 cal per 11.5 fl oz (340ml) bottle. 30g protein, 1g sugar. 24 vitamins & minerals.', TRUE),

('premier_protein_cookies_cream', 'Premier Protein Shake Cookies & Cream', 47, 8.8, 1.5, 0.9,
 0.0, 0.3, 340, NULL,
 'premier_protein', ARRAY['premier protein cookies and cream', 'premier protein cookies cream', 'premier protein shake cookies', 'premier protein cookies & cream'],
 'protein_shakes', 'Premier Protein', 1, '160 cal per 11.5 fl oz (340ml) bottle. 30g protein, 1g sugar. 24 vitamins & minerals.', TRUE),

-- ── MUSCLE MILK ───────────────────────────────────────────────────
-- Muscle Milk Genuine 14 fl oz (414 ml): 160 cal, 25g protein, 9g carbs, 4.5g fat, 0g sugar, 6g fiber
('muscle_milk_chocolate', 'Muscle Milk Genuine Chocolate', 39, 6.0, 2.2, 1.1,
 1.4, 0.0, 414, NULL,
 'muscle_milk', ARRAY['muscle milk chocolate', 'muscle milk genuine chocolate', 'muscle milk protein chocolate', 'muscle milk rtd chocolate'],
 'protein_shakes', 'Muscle Milk', 1, '160 cal per 14 fl oz (414ml) bottle. 25g protein, zero sugar, 6g fiber. Calcium + vitamins A, C, D.', TRUE),

-- Muscle Milk Genuine Vanilla 14 fl oz (414 ml): 160 cal, 25g protein, 9g carbs, 4.5g fat, 0g sugar, 6g fiber
('muscle_milk_vanilla', 'Muscle Milk Genuine Vanilla Creme', 39, 6.0, 2.2, 1.1,
 1.4, 0.0, 414, NULL,
 'muscle_milk', ARRAY['muscle milk vanilla', 'muscle milk genuine vanilla', 'muscle milk vanilla creme', 'muscle milk rtd vanilla'],
 'protein_shakes', 'Muscle Milk', 1, '160 cal per 14 fl oz (414ml) bottle. 25g protein, zero sugar, 6g fiber. Calcium + vitamins A, C, D.', TRUE),

-- Muscle Milk Cookies & Cream 14 fl oz (414 ml): 170 cal, 25g protein, 10g carbs, 4.5g fat, 0g sugar, 6g fiber
('muscle_milk_cookies_cream', 'Muscle Milk Genuine Cookies & Cream', 41, 6.0, 2.4, 1.1,
 1.4, 0.0, 414, NULL,
 'muscle_milk', ARRAY['muscle milk cookies and cream', 'muscle milk cookies cream', 'muscle milk genuine cookies', 'muscle milk cookies & cream'],
 'protein_shakes', 'Muscle Milk', 1, '170 cal per 14 fl oz (414ml) bottle. 25g protein, zero sugar, 6g fiber. Calcium + vitamins A, C, D.', TRUE),

-- ── ORGAIN ────────────────────────────────────────────────────────
-- Orgain Organic Nutrition Shake 11 fl oz (325 ml): 250 cal, 16g protein, 32g carbs, 7g fat, 15g sugar
('orgain_chocolate_fudge', 'Orgain Organic Nutrition Shake Chocolate Fudge', 77, 4.9, 9.8, 2.2,
 1.2, 4.6, 325, NULL,
 'orgain', ARRAY['orgain chocolate fudge', 'orgain chocolate', 'orgain organic chocolate fudge', 'orgain shake chocolate'],
 'protein_shakes', 'Orgain', 1, '250 cal per 11 fl oz (325ml) bottle. 16g organic grass-fed protein. 20 vitamins & minerals. Non-GMO, gluten-free.', TRUE),

-- Orgain Organic Nutrition Shake Vanilla Bean 11 fl oz (325 ml): 250 cal, 16g protein, 32g carbs, 7g fat, 15g sugar
('orgain_vanilla_bean', 'Orgain Organic Nutrition Shake Vanilla Bean', 77, 4.9, 9.8, 2.2,
 1.2, 4.6, 325, NULL,
 'orgain', ARRAY['orgain vanilla bean', 'orgain vanilla', 'orgain organic vanilla bean', 'orgain shake vanilla'],
 'protein_shakes', 'Orgain', 1, '250 cal per 11 fl oz (325ml) bottle. 16g organic grass-fed protein. 20 vitamins & minerals. Non-GMO, gluten-free.', TRUE)

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
