-- ============================================================================
-- 283_overrides_european.sql
-- Generated: 2026-02-28
-- Total items: 75 European cuisine foods
--
-- Cuisines covered:
--   Italian (authentic), French, Spanish, German, British, Greek
--
-- Sources: USDA FoodData Central, FatSecret, NutritionValue.org,
--          CalorieKing, EatThisMuch, SnapCalorie, NutriScan,
--          FoodStruct, CheckYourFood, Fitia
--
-- All values are per 100g of cooked/prepared food.
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes
) VALUES

-- ============================================================================
-- ITALIAN CUISINE (Authentic)
-- Sources: USDA, FatSecret, NutritionValue.org, SnapCalorie
-- ============================================================================

('spaghetti_carbonara', 'Spaghetti Carbonara', 191, 9.5, 22.0, 7.5, 1.0, 1.0, NULL, 300, 'italian_cuisine',
 ARRAY['carbonara', 'pasta carbonara', 'carbonara pasta'],
 '~573 cal per 300g serving. Traditional: guanciale, egg, pecorino, black pepper.'),

('spaghetti_bolognese', 'Spaghetti Bolognese', 146, 7.0, 17.5, 5.2, 1.5, 3.0, NULL, 350, 'italian_cuisine',
 ARRAY['bolognese', 'pasta bolognese', 'spag bol', 'spaghetti with meat sauce', 'ragu bolognese'],
 '~511 cal per 350g serving. Beef ragu with tomato sauce over spaghetti.'),

('fettuccine_alfredo', 'Fettuccine Alfredo', 208, 6.0, 25.0, 9.0, 1.0, 1.5, NULL, 300, 'italian_cuisine',
 ARRAY['alfredo pasta', 'pasta alfredo', 'alfredo'],
 '~624 cal per 300g serving. Butter and parmesan cream sauce.'),

('lasagna', 'Lasagna', 135, 8.0, 12.5, 5.8, 1.2, 2.5, NULL, 350, 'italian_cuisine',
 ARRAY['lasagne', 'lasagna bolognese', 'meat lasagna', 'beef lasagna'],
 '~473 cal per 350g serving. Layered pasta with meat sauce, bechamel, cheese.'),

('mushroom_risotto', 'Mushroom Risotto', 119, 3.2, 17.5, 3.5, 0.8, 0.5, NULL, 300, 'italian_cuisine',
 ARRAY['risotto ai funghi', 'porcini risotto', 'risotto mushroom'],
 '~357 cal per 300g serving. Arborio rice with mushrooms and parmesan.'),

('seafood_risotto', 'Seafood Risotto', 123, 5.5, 15.0, 4.2, 0.5, 0.5, NULL, 300, 'italian_cuisine',
 ARRAY['risotto ai frutti di mare', 'risotto seafood', 'shrimp risotto'],
 '~369 cal per 300g serving. Arborio rice with mixed seafood.'),

('gnocchi', 'Gnocchi (potato)', 133, 3.0, 27.0, 1.0, 1.5, 0.5, NULL, 250, 'italian_cuisine',
 ARRAY['potato gnocchi', 'gnocchi di patate'],
 '~333 cal per 250g serving. Cooked potato dumplings, plain.'),

('penne_arrabbiata', 'Penne Arrabbiata', 148, 5.0, 24.0, 3.5, 2.0, 3.0, NULL, 300, 'italian_cuisine',
 ARRAY['arrabbiata', 'pasta arrabbiata', 'penne arrabiata'],
 '~444 cal per 300g serving. Penne with spicy tomato-garlic sauce.'),

('osso_buco', 'Osso Buco', 137, 15.0, 4.0, 6.5, 0.5, 1.0, NULL, 350, 'italian_cuisine',
 ARRAY['ossobuco', 'osso bucco', 'braised veal shank'],
 '~480 cal per 350g serving. Braised veal shanks with vegetables.'),

('chicken_parmigiana', 'Chicken Parmigiana', 204, 16.0, 10.0, 11.0, 0.8, 2.0, NULL, 250, 'italian_cuisine',
 ARRAY['chicken parmesan', 'chicken parm', 'pollo alla parmigiana'],
 '~510 cal per 250g serving. Breaded chicken with tomato sauce and mozzarella.'),

('bruschetta', 'Bruschetta', 160, 4.5, 18.0, 7.5, 1.5, 3.0, 60, 120, 'italian_cuisine',
 ARRAY['bruschetta al pomodoro', 'tomato bruschetta'],
 '~192 cal per 2-piece (120g) serving. Toasted bread with tomato, basil, olive oil.'),

('caprese_salad', 'Caprese Salad', 148, 8.0, 3.5, 12.0, 0.5, 2.5, NULL, 200, 'italian_cuisine',
 ARRAY['insalata caprese', 'caprese', 'tomato mozzarella salad'],
 '~296 cal per 200g serving. Fresh mozzarella, tomato, basil, olive oil.'),

('minestrone_soup', 'Minestrone Soup', 46, 2.5, 7.0, 1.0, 2.0, 2.0, NULL, 350, 'italian_cuisine',
 ARRAY['minestrone', 'italian vegetable soup'],
 '~161 cal per 350g bowl. Mixed vegetable and pasta soup.'),

('tiramisu', 'Tiramisu', 305, 4.2, 29.0, 19.0, 0.3, 18.0, NULL, 120, 'italian_cuisine',
 ARRAY['tiramissu', 'tiramisu cake'],
 '~366 cal per 120g slice. Mascarpone, ladyfingers, espresso, cocoa.'),

('panna_cotta', 'Panna Cotta', 240, 3.0, 22.0, 16.0, 0, 18.0, NULL, 130, 'italian_cuisine',
 ARRAY['pannacotta', 'panna cotta dessert', 'italian panna cotta'],
 '~312 cal per 130g serving. Cream custard with gelatin, often with berry coulis.'),

('cannoli', 'Cannoli', 254, 5.0, 32.0, 12.0, 0.5, 20.0, 80, 80, 'italian_cuisine',
 ARRAY['cannolo', 'sicilian cannoli', 'italian cannoli'],
 '~203 cal per 80g piece. Fried pastry shell filled with sweet ricotta cream.'),

('focaccia', 'Focaccia', 249, 8.8, 34.0, 8.5, 2.0, 1.5, NULL, 80, 'italian_cuisine',
 ARRAY['focaccia bread', 'italian focaccia'],
 '~199 cal per 80g piece. Italian olive oil flatbread with herbs.'),

('ciabatta', 'Ciabatta', 271, 8.7, 50.0, 3.6, 2.0, 2.0, 100, 100, 'italian_cuisine',
 ARRAY['ciabatta bread', 'ciabatta roll', 'italian ciabatta'],
 '~271 cal per 100g roll. Italian white bread with open crumb structure.'),

('prosciutto', 'Prosciutto', 267, 26.7, 0, 18.0, 0, 0, NULL, 30, 'italian_cuisine',
 ARRAY['prosciutto crudo', 'parma ham', 'prosciutto di parma', 'italian dry cured ham'],
 '~80 cal per 30g (2-3 slices). Dry-cured Italian ham.'),

('arancini', 'Arancini', 220, 6.0, 26.0, 10.0, 1.0, 1.0, 100, 200, 'italian_cuisine',
 ARRAY['arancino', 'rice balls', 'sicilian rice balls', 'arancini di riso'],
 '~220 cal per 100g ball. Deep-fried risotto balls stuffed with ragu or cheese.'),

-- ============================================================================
-- FRENCH CUISINE
-- Sources: USDA, FatSecret, CalorieKing, NutritionValue.org, FoodStruct
-- ============================================================================

('croissant', 'Croissant', 406, 8.0, 45.0, 21.0, 2.5, 7.0, 60, 60, 'french_cuisine',
 ARRAY['french croissant', 'butter croissant', 'croissant au beurre'],
 '~244 cal per 60g croissant. Classic French butter pastry.'),

('pain_au_chocolat', 'Pain au Chocolat', 420, 7.5, 45.0, 23.0, 2.0, 12.0, 70, 70, 'french_cuisine',
 ARRAY['chocolate croissant', 'chocolatine', 'pain au choc'],
 '~294 cal per 70g piece. Chocolate-filled laminated pastry.'),

('croque_monsieur', 'Croque Monsieur', 265, 14.0, 18.0, 15.0, 1.0, 2.0, NULL, 200, 'french_cuisine',
 ARRAY['croque monsieur sandwich', 'french grilled ham and cheese'],
 '~530 cal per 200g sandwich. Grilled ham and cheese with bechamel.'),

('french_onion_soup', 'French Onion Soup', 75, 3.0, 7.5, 3.5, 0.8, 3.5, NULL, 350, 'french_cuisine',
 ARRAY['soupe a l''oignon', 'onion soup gratinee', 'french onion soup gratinee'],
 '~263 cal per 350g bowl. Caramelized onion soup with bread and gruyere.'),

('coq_au_vin', 'Coq au Vin', 145, 14.0, 4.5, 7.5, 0.5, 1.5, NULL, 300, 'french_cuisine',
 ARRAY['chicken in wine', 'coq au vin rouge'],
 '~435 cal per 300g serving. Chicken braised in red wine with mushrooms and onions.'),

('beef_bourguignon', 'Beef Bourguignon', 125, 12.0, 6.0, 5.8, 1.0, 1.5, NULL, 350, 'french_cuisine',
 ARRAY['boeuf bourguignon', 'beef burgundy', 'boeuf a la bourguignonne'],
 '~438 cal per 350g serving. Beef stew braised in red Burgundy wine.'),

('ratatouille', 'Ratatouille', 56, 1.2, 5.5, 3.2, 1.5, 3.5, NULL, 250, 'french_cuisine',
 ARRAY['provencal ratatouille', 'french ratatouille'],
 '~140 cal per 250g serving. Provencal stewed vegetables: eggplant, zucchini, peppers, tomato.'),

('quiche_lorraine', 'Quiche Lorraine', 260, 11.0, 16.0, 17.0, 0.5, 1.5, NULL, 150, 'french_cuisine',
 ARRAY['lorraine quiche', 'bacon and egg quiche', 'quiche'],
 '~390 cal per 150g slice. Savory custard tart with bacon, eggs, cream, gruyere.'),

('crepe_sweet', 'Crepe (sweet, with sugar & lemon)', 190, 5.0, 28.0, 6.5, 0.5, 12.0, NULL, 100, 'french_cuisine',
 ARRAY['sweet crepe', 'sugar crepe', 'crepe sucree', 'french crepe sweet'],
 '~190 cal per 100g crepe. Thin French pancake with sugar and lemon.'),

('crepe_savory', 'Crepe (savory, ham & cheese)', 210, 10.0, 20.0, 10.0, 0.5, 1.5, NULL, 150, 'french_cuisine',
 ARRAY['galette', 'savory crepe', 'crepe salee', 'ham and cheese crepe'],
 '~315 cal per 150g crepe. Buckwheat or wheat crepe with ham, cheese, egg.'),

('escargot', 'Escargot (in garlic butter)', 170, 12.0, 2.0, 13.0, 0, 0, NULL, 100, 'french_cuisine',
 ARRAY['escargots', 'snails in garlic butter', 'escargots de bourgogne', 'french snails'],
 '~170 cal per 100g (6 snails). Snails baked in garlic-parsley-butter sauce.'),

('duck_confit', 'Duck Confit', 230, 20.0, 0, 17.0, 0, 0, NULL, 200, 'french_cuisine',
 ARRAY['confit de canard', 'duck leg confit'],
 '~460 cal per 200g leg. Duck leg slow-cooked in its own fat.'),

('creme_brulee', 'Creme Brulee', 305, 3.5, 25.0, 21.0, 0, 20.0, NULL, 120, 'french_cuisine',
 ARRAY['creme brulee dessert', 'french creme brulee', 'burnt cream'],
 '~366 cal per 120g ramekin. Rich custard with caramelized sugar crust.'),

('baguette', 'Baguette', 270, 9.0, 53.0, 1.5, 2.5, 3.0, NULL, 60, 'french_cuisine',
 ARRAY['french baguette', 'french bread', 'pain français'],
 '~162 cal per 60g piece (~1/4 baguette). Classic French bread.'),

('bouillabaisse', 'Bouillabaisse', 72, 8.0, 3.5, 3.0, 0.5, 1.0, NULL, 400, 'french_cuisine',
 ARRAY['french fish stew', 'marseille bouillabaisse', 'provencal fish soup'],
 '~288 cal per 400g bowl. Provencal fish and shellfish stew with saffron.'),

('nicoise_salad', 'Nicoise Salad', 105, 7.5, 5.5, 6.5, 1.5, 2.0, NULL, 350, 'french_cuisine',
 ARRAY['salade nicoise', 'tuna nicoise salad', 'salad nicoise'],
 '~368 cal per 350g serving. Tuna, eggs, olives, green beans, tomato, potato, anchovy.'),

-- ============================================================================
-- SPANISH CUISINE
-- Sources: FatSecret, NutriScan, Fitia, NutritionValue.org
-- ============================================================================

('paella_seafood', 'Paella (Seafood)', 119, 7.0, 15.0, 3.5, 0.8, 0.5, NULL, 350, 'spanish_cuisine',
 ARRAY['seafood paella', 'paella de mariscos', 'paella marinera'],
 '~417 cal per 350g serving. Saffron rice with shrimp, mussels, squid.'),

('paella_chicken', 'Paella (Chicken)', 130, 8.5, 16.0, 3.8, 0.8, 0.5, NULL, 350, 'spanish_cuisine',
 ARRAY['chicken paella', 'paella de pollo', 'paella valenciana'],
 '~455 cal per 350g serving. Saffron rice with chicken and vegetables.'),

('patatas_bravas', 'Patatas Bravas', 180, 3.0, 22.0, 9.0, 2.0, 1.0, NULL, 200, 'spanish_cuisine',
 ARRAY['bravas', 'papas bravas', 'fried potatoes with bravas sauce'],
 '~360 cal per 200g serving. Fried potatoes with spicy bravas sauce.'),

('tortilla_espanola', 'Tortilla Espanola', 150, 6.5, 12.0, 8.5, 1.0, 1.0, NULL, 150, 'spanish_cuisine',
 ARRAY['spanish omelette', 'tortilla de patatas', 'spanish tortilla', 'potato omelette'],
 '~225 cal per 150g slice. Potato and onion omelette.'),

('churros', 'Churros', 430, 5.0, 48.0, 24.0, 1.5, 15.0, 40, 100, 'spanish_cuisine',
 ARRAY['churro', 'spanish churros', 'churros con chocolate'],
 '~172 cal per 40g churro. Deep-fried dough sticks dusted with cinnamon sugar.'),

('gazpacho', 'Gazpacho', 36, 1.0, 4.5, 1.5, 0.8, 3.0, NULL, 300, 'spanish_cuisine',
 ARRAY['gazpacho soup', 'cold tomato soup', 'andalusian gazpacho', 'spanish gazpacho'],
 '~108 cal per 300g bowl. Cold blended tomato soup with peppers, cucumber, olive oil.'),

('croquetas', 'Croquetas (Jamon)', 203, 7.0, 18.0, 11.5, 0.5, 1.0, 30, 120, 'spanish_cuisine',
 ARRAY['croquetas de jamon', 'ham croquettes', 'spanish croquettes', 'croquetas de jamon serrano'],
 '~61 cal per 30g croqueta. Fried bechamel fritters with Serrano ham.'),

('jamon_serrano', 'Jamon Serrano', 241, 31.0, 0, 13.0, 0, 0, NULL, 30, 'spanish_cuisine',
 ARRAY['serrano ham', 'spanish ham', 'cured ham serrano', 'jamon'],
 '~72 cal per 30g serving. Spanish dry-cured ham.'),

('gambas_al_ajillo', 'Gambas al Ajillo', 170, 16.0, 2.0, 11.0, 0.2, 0.2, NULL, 150, 'spanish_cuisine',
 ARRAY['garlic shrimp', 'garlic prawns', 'shrimp in garlic', 'gambas ajillo'],
 '~255 cal per 150g serving. Shrimp sauteed in olive oil, garlic, and chili.'),

('albondigas', 'Albondigas (Spanish Meatballs)', 180, 12.0, 8.0, 11.0, 1.0, 2.0, NULL, 250, 'spanish_cuisine',
 ARRAY['spanish meatballs', 'albondigas en salsa', 'meatballs in tomato sauce'],
 '~450 cal per 250g serving. Pork and beef meatballs in tomato-saffron sauce.'),

-- ============================================================================
-- GERMAN CUISINE
-- Sources: USDA, FatSecret, FoodStruct, NutritionValue.org, CalorieFriend
-- ============================================================================

('wiener_schnitzel', 'Wiener Schnitzel', 214, 18.0, 10.0, 11.5, 0.5, 0.5, NULL, 200, 'german_cuisine',
 ARRAY['schnitzel', 'veal schnitzel', 'breaded schnitzel', 'wienerschnitzel'],
 '~428 cal per 200g serving. Breaded and pan-fried veal cutlet.'),

('jager_schnitzel', 'Jager Schnitzel', 190, 16.0, 8.0, 10.5, 0.8, 1.5, NULL, 250, 'german_cuisine',
 ARRAY['jagerschnitzel', 'hunter''s schnitzel', 'schnitzel with mushroom sauce', 'schnitzel jager'],
 '~475 cal per 250g serving. Breaded pork cutlet with mushroom-cream sauce.'),

('bratwurst', 'Bratwurst', 297, 13.7, 3.0, 25.5, 0, 0, 100, 100, 'german_cuisine',
 ARRAY['brat', 'german sausage', 'pork bratwurst', 'grilled bratwurst'],
 '~297 cal per 100g sausage. Grilled German pork sausage.'),

('currywurst', 'Currywurst', 150, 10.0, 10.0, 8.0, 0.5, 5.0, NULL, 250, 'german_cuisine',
 ARRAY['curry wurst', 'curried sausage', 'german currywurst'],
 '~375 cal per 250g serving. Sliced bratwurst with curry ketchup sauce.'),

('pretzel', 'Pretzel (soft, Bavarian)', 335, 9.0, 65.0, 3.5, 2.5, 3.0, 120, 120, 'german_cuisine',
 ARRAY['brezel', 'bavarian pretzel', 'soft pretzel', 'german pretzel', 'laugenbrezel'],
 '~402 cal per 120g pretzel. Traditional Bavarian lye-dipped bread.'),

('sauerkraut', 'Sauerkraut', 19, 0.9, 4.3, 0.1, 2.9, 1.8, NULL, 150, 'german_cuisine',
 ARRAY['fermented cabbage', 'german sauerkraut'],
 '~29 cal per 150g serving. Fermented shredded cabbage, tangy. Rich in probiotics.'),

('kartoffelsalat', 'Kartoffelsalat (German Potato Salad)', 120, 2.5, 15.0, 5.5, 1.5, 2.0, NULL, 200, 'german_cuisine',
 ARRAY['german potato salad', 'potato salad german', 'kartoffel salat'],
 '~240 cal per 200g serving. Warm potato salad with bacon, vinegar, mustard dressing.'),

('spaetzle', 'Spaetzle', 140, 5.5, 22.0, 3.0, 1.0, 0.5, NULL, 200, 'german_cuisine',
 ARRAY['spatzle', 'german egg noodles', 'schwabische spatzle', 'kasspatzle'],
 '~280 cal per 200g serving. Cooked German egg noodles/dumplings.'),

('apple_strudel', 'Apple Strudel', 274, 3.3, 38.0, 12.0, 1.5, 20.0, NULL, 150, 'german_cuisine',
 ARRAY['apfelstrudel', 'strudel', 'wiener apfelstrudel'],
 '~411 cal per 150g slice. Flaky pastry filled with spiced apples and raisins.'),

-- ============================================================================
-- BRITISH CUISINE
-- Sources: CalorieKing, CheckYourFood, FatSecret, SnapCalorie
-- ============================================================================

('fish_and_chips', 'Fish and Chips', 200, 10.0, 18.0, 10.0, 1.5, 0.5, NULL, 400, 'british_cuisine',
 ARRAY['fish n chips', 'fish & chips', 'battered fish and chips', 'chippy'],
 '~800 cal per 400g serving. Beer-battered cod with thick-cut fries.'),

('shepherds_pie', 'Shepherd''s Pie', 110, 7.0, 10.0, 4.5, 1.2, 1.5, NULL, 350, 'british_cuisine',
 ARRAY['shepherds pie', 'cottage pie', 'lamb shepherds pie'],
 '~385 cal per 350g serving. Lamb mince with vegetables topped with mashed potato.'),

('bangers_and_mash', 'Bangers and Mash', 155, 7.0, 13.0, 8.5, 1.0, 1.0, NULL, 350, 'british_cuisine',
 ARRAY['sausage and mash', 'bangers & mash', 'bangers mash and gravy'],
 '~543 cal per 350g serving. Pork sausages with mashed potato and onion gravy.'),

('sunday_roast_beef', 'Sunday Roast (Beef)', 130, 12.0, 8.0, 5.5, 1.0, 1.0, NULL, 400, 'british_cuisine',
 ARRAY['roast dinner', 'sunday roast', 'beef roast dinner', 'roast beef dinner'],
 '~520 cal per 400g plate. Roast beef with roast potatoes, vegetables, yorkshire pudding, gravy.'),

('cornish_pasty', 'Cornish Pasty', 275, 7.5, 25.0, 16.0, 1.5, 1.5, 200, 200, 'british_cuisine',
 ARRAY['pasty', 'meat pasty', 'beef pasty', 'cornish pastie'],
 '~550 cal per 200g pasty. Pastry filled with beef, potato, onion, swede.'),

('scotch_egg', 'Scotch Egg', 245, 13.0, 12.0, 16.0, 0.5, 0.5, 115, 115, 'british_cuisine',
 ARRAY['scotch eggs', 'sausage wrapped egg'],
 '~282 cal per 115g egg. Hard-boiled egg wrapped in sausage meat, breaded and fried.'),

('full_english_breakfast', 'Full English Breakfast', 165, 10.0, 8.0, 11.0, 1.0, 2.0, NULL, 450, 'british_cuisine',
 ARRAY['english breakfast', 'fry up', 'fry-up', 'full english', 'cooked breakfast'],
 '~743 cal per 450g plate. Eggs, bacon, sausages, beans, toast, tomato, mushrooms.'),

('yorkshire_pudding', 'Yorkshire Pudding', 215, 7.5, 27.0, 8.5, 0.8, 1.5, 40, 80, 'british_cuisine',
 ARRAY['yorkie pud', 'yorkshire puds'],
 '~86 cal per 40g pudding. Light, risen batter pudding, served with roast dinner.'),

('sticky_toffee_pudding', 'Sticky Toffee Pudding', 310, 3.5, 48.0, 12.0, 0.8, 35.0, NULL, 150, 'british_cuisine',
 ARRAY['sticky date pudding', 'toffee pudding', 'sticky toffee pud'],
 '~465 cal per 150g serving. Dense date sponge cake with warm toffee sauce.'),

('scones', 'Scone (plain)', 362, 7.0, 50.0, 14.5, 1.5, 10.0, 60, 60, 'british_cuisine',
 ARRAY['scone', 'english scone', 'cream tea scone', 'plain scone', 'british scone'],
 '~217 cal per 60g scone. Served with clotted cream and jam for cream tea.'),

-- ============================================================================
-- GREEK CUISINE
-- Sources: FatSecret, NutriScan, FoodStruct, CheckYourFood, Fitia
-- ============================================================================

('gyro_lamb', 'Gyro (Lamb)', 235, 14.0, 18.0, 12.0, 1.0, 2.0, NULL, 300, 'greek_cuisine',
 ARRAY['lamb gyro', 'lamb gyros', 'lamb doner', 'gyro pita lamb'],
 '~705 cal per 300g wrap. Sliced lamb in pita with tzatziki, tomato, onion.'),

('gyro_chicken', 'Gyro (Chicken)', 195, 14.0, 20.0, 6.5, 1.0, 2.0, NULL, 300, 'greek_cuisine',
 ARRAY['chicken gyro', 'chicken gyros', 'chicken doner', 'gyro pita chicken'],
 '~585 cal per 300g wrap. Sliced chicken in pita with tzatziki, tomato, onion.'),

('souvlaki', 'Souvlaki (Chicken)', 165, 22.0, 2.0, 7.5, 0.3, 0.5, NULL, 150, 'greek_cuisine',
 ARRAY['chicken souvlaki', 'souvlaki skewer', 'greek souvlaki', 'kalamaki'],
 '~248 cal per 150g (2 skewers). Grilled marinated chicken skewers.'),

('moussaka', 'Moussaka', 150, 7.0, 10.0, 9.0, 2.0, 3.0, NULL, 300, 'greek_cuisine',
 ARRAY['mousaka', 'greek moussaka', 'eggplant moussaka', 'aubergine moussaka'],
 '~450 cal per 300g serving. Layered eggplant, ground lamb, potato, bechamel.'),

('spanakopita', 'Spanakopita', 235, 8.0, 17.0, 15.0, 2.0, 1.5, 80, 160, 'greek_cuisine',
 ARRAY['spinach pie', 'greek spinach pie', 'spanakopita pie', 'spinach and feta pie'],
 '~188 cal per 80g triangle. Phyllo pastry with spinach and feta filling.'),

('tzatziki', 'Tzatziki', 55, 3.5, 3.5, 3.0, 0.3, 2.5, NULL, 60, 'greek_cuisine',
 ARRAY['tzatziki sauce', 'tzatziki dip', 'cucumber yogurt dip', 'greek tzatziki'],
 '~33 cal per 60g (2 tbsp). Yogurt-cucumber-garlic dip.'),

('greek_salad', 'Greek Salad', 90, 3.5, 5.5, 6.5, 1.5, 3.0, NULL, 250, 'greek_cuisine',
 ARRAY['horiatiki', 'horiatiki salad', 'village salad', 'traditional greek salad'],
 '~225 cal per 250g serving. Tomato, cucumber, feta, olives, onion, olive oil.'),

('baklava', 'Baklava', 428, 6.5, 48.0, 24.0, 2.0, 32.0, 60, 60, 'greek_cuisine',
 ARRAY['baklawa', 'greek baklava', 'pistachio baklava', 'walnut baklava'],
 '~257 cal per 60g piece. Layered phyllo with chopped nuts and honey syrup.'),

('dolmades', 'Dolmades (Stuffed Grape Leaves)', 143, 4.5, 14.0, 8.0, 2.5, 1.0, 30, 120, 'greek_cuisine',
 ARRAY['dolma', 'stuffed grape leaves', 'dolmathes', 'dolmadakia', 'stuffed vine leaves'],
 '~43 cal per 30g piece. Grape leaves stuffed with rice, herbs, and lemon.'),

('pastitsio', 'Pastitsio', 170, 9.0, 15.0, 8.5, 1.0, 2.0, NULL, 300, 'greek_cuisine',
 ARRAY['pasticcio', 'greek pasta bake', 'greek lasagna', 'pasticio'],
 '~510 cal per 300g serving. Baked pasta with meat sauce and bechamel topping.')


ON CONFLICT (food_name_normalized) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  default_serving_g = EXCLUDED.default_serving_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  notes = EXCLUDED.notes,
  updated_at = NOW();


-- ============================================================================
-- BACKFILL restaurant_name, food_category, default_count
-- ============================================================================

-- Set food_category based on source
UPDATE food_nutrition_overrides
SET food_category = CASE
  WHEN source = 'italian_cuisine' THEN 'italian'
  WHEN source = 'french_cuisine' THEN 'french'
  WHEN source = 'spanish_cuisine' THEN 'spanish'
  WHEN source = 'german_cuisine' THEN 'german'
  WHEN source = 'british_cuisine' THEN 'british'
  WHEN source = 'greek_cuisine' THEN 'greek'
  ELSE food_category
END
WHERE source IN ('italian_cuisine', 'french_cuisine', 'spanish_cuisine', 'german_cuisine', 'british_cuisine', 'greek_cuisine')
  AND food_category IS NULL;

-- Set default_count for multi-piece items
UPDATE food_nutrition_overrides
SET default_count = CASE
  WHEN food_name_normalized = 'bruschetta' THEN 3
  WHEN food_name_normalized = 'arancini' THEN 3
  WHEN food_name_normalized = 'cannoli' THEN 2
  WHEN food_name_normalized = 'escargot' THEN 6
  WHEN food_name_normalized = 'churros' THEN 5
  WHEN food_name_normalized = 'croquetas' THEN 4
  WHEN food_name_normalized = 'scotch_egg' THEN 1
  WHEN food_name_normalized = 'dolmades' THEN 4
  WHEN food_name_normalized = 'spanakopita' THEN 2
  ELSE 1
END
WHERE source IN ('italian_cuisine', 'french_cuisine', 'spanish_cuisine', 'german_cuisine', 'british_cuisine', 'greek_cuisine')
  AND default_count IS NULL;

-- Backfill weight_per_piece_g where missing
UPDATE food_nutrition_overrides
SET default_weight_per_piece_g = default_serving_g
WHERE source IN ('italian_cuisine', 'french_cuisine', 'spanish_cuisine', 'german_cuisine', 'british_cuisine', 'greek_cuisine')
  AND default_weight_per_piece_g IS NULL
  AND default_serving_g IS NOT NULL;
