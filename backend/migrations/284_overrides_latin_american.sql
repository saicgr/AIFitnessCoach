-- ============================================================================
-- 284_overrides_latin_american.sql
-- Generated: 2026-02-28
-- Total items: 66
--
-- Latin American & Caribbean cuisine foods for food_nutrition_overrides.
-- All values are per 100g. Sources: USDA FoodData Central, FatSecret,
-- NutritionValue.org, SnapCalorie, NutriScan, Fitia, EatThisMuch,
-- regional nutrition databases, and cross-referenced recipe analyses.
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, food_category, default_count, notes
) VALUES

-- =====================================================
-- 1. MEXICAN CUISINE (Authentic)
-- Sources: USDA, NutritionValue.org, SnapCalorie, FatSecret
-- =====================================================

-- Pozole: ~49-55 cal/100g, broth-based pork/chicken and hominy stew
('pozole', 'Pozole (Mexican Hominy Stew)', 52.0, 3.8, 5.3, 1.8, 0.9, 0.4, NULL, 350, 'mexican_cuisine', ARRAY['pozole rojo', 'pozole verde', 'pozole blanco', 'posole', 'mexican hominy soup'], 'mexican', 1, 'Broth-based stew with hominy and pork/chicken. ~182 cal per 350g bowl.'),

-- Tamales: ~153-204 cal/100g depending on filling; masa with pork filling
('tamales', 'Tamales (Pork)', 190.0, 7.5, 18.5, 9.8, 2.1, 0.8, 120, 240, 'mexican_cuisine', ARRAY['tamal', 'tamale', 'tamales de puerco', 'pork tamale', 'tamales de cerdo'], 'mexican', 2, 'Masa harina dough with pork filling, wrapped in corn husk. ~228 cal per 120g tamale.'),

-- Tamales de Pollo (chicken)
('tamales_de_pollo', 'Tamales (Chicken)', 170.0, 8.2, 17.8, 7.5, 1.8, 0.6, 120, 240, 'mexican_cuisine', ARRAY['chicken tamale', 'tamal de pollo', 'tamales de pollo'], 'mexican', 2, 'Masa dough with shredded chicken filling. ~204 cal per 120g tamale.'),

-- Chiles Rellenos: ~205 cal/100g, cheese-stuffed poblano, battered and fried
('chiles_rellenos', 'Chiles Rellenos', 205.0, 11.0, 7.2, 14.8, 1.2, 2.0, 180, 180, 'mexican_cuisine', ARRAY['chile relleno', 'stuffed pepper mexican', 'chile relleno de queso'], 'mexican', 1, 'Battered and fried poblano pepper stuffed with cheese/meat. ~369 cal per 180g piece.'),

-- Enchiladas Verdes (chicken)
('enchiladas_verdes', 'Enchiladas Verdes (Chicken)', 155.0, 9.5, 13.0, 7.5, 1.5, 1.8, 150, 300, 'mexican_cuisine', ARRAY['green enchiladas', 'enchilada verde', 'chicken enchilada verde'], 'mexican', 2, 'Corn tortillas with chicken, green tomatillo sauce. ~233 cal per 150g enchilada.'),

-- Enchiladas Rojas (cheese)
('enchiladas_rojas', 'Enchiladas Rojas (Cheese)', 175.0, 8.0, 14.5, 9.5, 1.2, 2.0, 150, 300, 'mexican_cuisine', ARRAY['red enchiladas', 'enchilada roja', 'cheese enchilada', 'enchiladas de queso'], 'mexican', 2, 'Corn tortillas with cheese, red chili sauce. ~263 cal per 150g enchilada.'),

-- Mole Poblano (sauce with chicken)
('mole_poblano', 'Mole Poblano (Chicken)', 165.0, 12.0, 10.5, 8.5, 1.8, 3.5, NULL, 250, 'mexican_cuisine', ARRAY['chicken mole', 'pollo en mole', 'mole negro', 'mole sauce chicken'], 'mexican', 1, 'Complex chocolate-chili sauce over chicken. ~413 cal per 250g serving.'),

-- Sopes
('sopes', 'Sopes (Carne Asada)', 213.0, 9.0, 23.0, 9.0, 2.5, 0.8, 100, 200, 'mexican_cuisine', ARRAY['sope', 'sope de carne', 'sopes de carne asada', 'sopes mexicanos'], 'mexican', 2, 'Thick corn masa base topped with beans, meat, and toppings. ~213 cal per 100g sope.'),

-- Gorditas
('gorditas', 'Gorditas (Meat-Filled)', 225.0, 9.5, 24.0, 10.0, 2.8, 0.5, 120, 120, 'mexican_cuisine', ARRAY['gordita', 'gordita de chicharron', 'gordita de carne'], 'mexican', 1, 'Thick corn masa pocket stuffed with meat. ~270 cal per 120g gordita.'),

-- Elote (Mexican Street Corn)
('elote', 'Elote (Mexican Street Corn)', 155.0, 4.5, 19.0, 7.5, 2.5, 4.0, 170, 170, 'mexican_cuisine', ARRAY['mexican street corn', 'elote preparado', 'corn on the cob mexican', 'esquite'], 'mexican', 1, 'Grilled corn with mayo, cotija, chili, lime. ~264 cal per ear.'),

-- Chilaquiles
('chilaquiles', 'Chilaquiles (with Egg)', 175.0, 7.5, 14.0, 10.2, 1.8, 1.5, NULL, 300, 'mexican_cuisine', ARRAY['chilaquiles verdes', 'chilaquiles rojos', 'chilaquiles con huevo'], 'mexican', 1, 'Fried tortilla chips in salsa with egg and cream. ~525 cal per 300g plate.'),

-- Huevos Rancheros
('huevos_rancheros', 'Huevos Rancheros', 135.0, 7.8, 10.5, 7.2, 2.0, 1.8, NULL, 300, 'mexican_cuisine', ARRAY['huevos rancheros con frijoles', 'ranch-style eggs', 'ranchero eggs'], 'mexican', 1, 'Fried eggs on tortilla with ranchero sauce. ~405 cal per 300g plate.'),

-- Carnitas
('carnitas', 'Carnitas (Braised Pork)', 230.0, 22.0, 0.5, 15.0, 0.0, 0.0, NULL, 100, 'mexican_cuisine', ARRAY['pulled pork mexican', 'carnitas de puerco', 'slow cooked pork'], 'mexican', 1, 'Slow-braised and crisped pork shoulder. ~230 cal per 100g serving.'),

-- Birria
('birria', 'Birria (Stewed Beef)', 165.0, 18.0, 3.5, 8.5, 0.5, 0.8, NULL, 250, 'mexican_cuisine', ARRAY['birria de res', 'birria stew', 'birria consomme', 'beef birria'], 'mexican', 1, 'Slow-stewed beef/goat in dried chili broth. ~413 cal per 250g bowl.'),

-- Horchata
('horchata', 'Horchata (Rice Drink)', 54.0, 0.5, 12.0, 0.8, 0.1, 9.5, NULL, 240, 'mexican_cuisine', ARRAY['agua de horchata', 'horchata de arroz', 'rice water drink'], 'drinks', 1, 'Sweet rice and cinnamon drink. ~130 cal per 240ml glass.'),

-- Churros
('churros', 'Churros', 380.0, 5.5, 42.0, 21.0, 1.5, 12.0, 40, 80, 'mexican_cuisine', ARRAY['churro', 'churros con chocolate', 'churros con azucar'], 'desserts', 2, 'Deep-fried choux dough with cinnamon sugar. ~152 cal per 40g churro.'),

-- Tres Leches Cake
('tres_leches_cake', 'Tres Leches Cake', 246.0, 5.2, 34.0, 9.8, 0.0, 28.0, 120, 120, 'mexican_cuisine', ARRAY['tres leches', 'three milk cake', 'pastel de tres leches', 'torta tres leches'], 'desserts', 1, 'Sponge cake soaked in three milks. ~295 cal per 120g slice.'),

-- Arroz con Leche (Mexican Rice Pudding)
('arroz_con_leche', 'Arroz con Leche (Rice Pudding)', 146.0, 3.2, 24.9, 3.7, 0.2, 15.0, NULL, 200, 'mexican_cuisine', ARRAY['rice pudding mexican', 'mexican rice pudding', 'arroz con leche mexicano'], 'desserts', 1, 'Creamy rice pudding with cinnamon and milk. ~292 cal per 200g bowl.'),

-- Carne Asada
('carne_asada', 'Carne Asada (Grilled Steak)', 205.0, 24.5, 1.0, 11.0, 0.0, 0.2, NULL, 150, 'mexican_cuisine', ARRAY['grilled steak mexican', 'asada', 'carne asada a la tampiqueña'], 'mexican', 1, 'Marinated and grilled thin-cut beef steak. ~308 cal per 150g serving.'),

-- Tacos al Pastor
('tacos_al_pastor', 'Tacos al Pastor', 195.0, 14.0, 16.0, 8.5, 1.5, 2.5, 90, 270, 'mexican_cuisine', ARRAY['taco al pastor', 'pastor taco', 'tacos de trompo', 'tacos de adobada'], 'mexican', 3, 'Corn tortilla with spit-roasted pork and pineapple. ~176 cal per 90g taco.'),

-- Barbacoa
('barbacoa', 'Barbacoa (Slow-Cooked Beef Cheek)', 210.0, 20.0, 1.5, 13.5, 0.0, 0.3, NULL, 100, 'mexican_cuisine', ARRAY['barbacoa de res', 'beef barbacoa', 'barbacoa meat'], 'mexican', 1, 'Slow-braised beef cheeks with chili and spices. ~210 cal per 100g.'),

-- Mexican Street Tacos (generic, small corn tortilla + meat)
('mexican_street_tacos', 'Mexican Street Tacos', 200.0, 12.0, 16.5, 9.0, 1.5, 0.8, 70, 210, 'mexican_cuisine', ARRAY['street taco', 'taco callejero', 'taco de carne', 'mini tacos'], 'mexican', 3, 'Small corn tortilla with meat, onion, cilantro. ~140 cal per 70g taco.'),

-- Torta (Mexican Sandwich)
('torta_mexicana', 'Torta (Mexican Sandwich)', 245.0, 13.0, 24.0, 11.0, 1.8, 2.5, 250, 250, 'mexican_cuisine', ARRAY['torta', 'torta de jamon', 'torta de milanesa', 'mexican sandwich', 'torta cubana'], 'mexican', 1, 'Bolillo bread with beans, meat, avocado, toppings. ~613 cal per 250g torta.'),

-- =====================================================
-- 2. BRAZILIAN CUISINE
-- Sources: USDA, FatSecret, SnapCalorie, NutritionValue.org
-- =====================================================

-- Feijoada
('feijoada', 'Feijoada (Brazilian Black Bean Stew)', 125.0, 8.5, 10.0, 5.5, 3.5, 0.5, NULL, 350, 'brazilian_cuisine', ARRAY['feijoada brasileira', 'feijoada completa', 'brazilian bean stew', 'black bean stew'], 'brazilian', 1, 'Black bean stew with pork and sausage. ~438 cal per 350g serving.'),

-- Picanha
('picanha', 'Picanha (Brazilian Grilled Steak)', 250.0, 20.0, 0.0, 19.0, 0.0, 0.0, NULL, 150, 'brazilian_cuisine', ARRAY['picanha na brasa', 'picanha grelhada', 'rump cap steak', 'coulotte steak'], 'brazilian', 1, 'Grilled rump cap steak, Brazilian style. ~375 cal per 150g serving.'),

-- Coxinha
('coxinha', 'Coxinha (Chicken Croquette)', 280.0, 11.5, 26.0, 14.5, 1.0, 1.2, 80, 160, 'brazilian_cuisine', ARRAY['coxinha de frango', 'chicken coxinha', 'brazilian chicken croquette'], 'brazilian', 2, 'Deep-fried dough with chicken filling, teardrop-shaped. ~224 cal per 80g piece.'),

-- Pao de Queijo
('pao_de_queijo', 'Pao de Queijo (Cheese Bread)', 340.0, 6.5, 38.0, 17.5, 0.5, 1.5, 25, 75, 'brazilian_cuisine', ARRAY['pao de queijo', 'cheese bread brazilian', 'brazilian cheese roll', 'cheese bun'], 'brazilian', 3, 'Tapioca flour cheese bread rolls. ~85 cal per 25g roll.'),

-- Acai Bowl
('acai_bowl', 'Acai Bowl', 160.0, 2.5, 22.0, 7.0, 3.5, 14.0, NULL, 300, 'brazilian_cuisine', ARRAY['acai na tigela', 'acai smoothie bowl', 'acai berry bowl', 'purple bowl'], 'brazilian', 1, 'Blended acai with granola, banana, honey. ~480 cal per 300g bowl.'),

-- Moqueca
('moqueca', 'Moqueca (Brazilian Fish Stew)', 115.0, 12.5, 5.0, 5.5, 1.0, 1.8, NULL, 350, 'brazilian_cuisine', ARRAY['moqueca baiana', 'moqueca de peixe', 'moqueca de camarao', 'brazilian fish stew'], 'brazilian', 1, 'Coconut milk fish stew with peppers and tomato. ~403 cal per 350g bowl.'),

-- Farofa
('farofa', 'Farofa (Toasted Cassava Flour)', 370.0, 2.5, 65.0, 10.5, 4.0, 1.0, NULL, 50, 'brazilian_cuisine', ARRAY['farofa de manteiga', 'farofa tradicional', 'toasted manioc flour', 'cassava crumble'], 'brazilian', 1, 'Toasted cassava flour with butter, side dish. ~185 cal per 50g serving.'),

-- Brigadeiro
('brigadeiro', 'Brigadeiro (Chocolate Truffle)', 338.0, 5.0, 52.0, 12.5, 1.5, 42.0, 20, 60, 'brazilian_cuisine', ARRAY['brigadeiros', 'brazilian truffle', 'chocolate brigadeiro', 'brigadeiro de chocolate'], 'desserts', 3, 'Condensed milk chocolate truffle rolled in sprinkles. ~68 cal per 20g piece.'),

-- Pastel (Brazilian fried pastry)
('pastel_brasileiro', 'Pastel (Brazilian Fried Pastry)', 300.0, 8.0, 28.0, 17.0, 1.2, 1.0, 100, 200, 'brazilian_cuisine', ARRAY['pastel de carne', 'pastel de queijo', 'pastel frito', 'brazilian pastel'], 'brazilian', 2, 'Deep-fried thin dough with meat/cheese filling. ~300 cal per 100g piece.'),

-- Churrasco
('churrasco', 'Churrasco (Brazilian BBQ Meat)', 225.0, 25.0, 0.0, 13.5, 0.0, 0.0, NULL, 200, 'brazilian_cuisine', ARRAY['churrasco brasileiro', 'brazilian bbq', 'rodizio meat', 'grilled beef brazilian'], 'brazilian', 1, 'Skewered and grilled beef cuts, rodizio-style. ~450 cal per 200g serving.'),

-- =====================================================
-- 3. PERUVIAN CUISINE
-- Sources: USDA, FatSecret, SnapCalorie, Fitia
-- =====================================================

-- Ceviche
('ceviche', 'Ceviche (Peruvian)', 62.0, 10.3, 3.6, 0.8, 0.5, 1.2, NULL, 200, 'peruvian_cuisine', ARRAY['cebiche', 'seviche', 'ceviche de pescado', 'peruvian ceviche', 'ceviche clasico'], 'peruvian', 1, 'Raw fish cured in citrus with onion, chili. ~124 cal per 200g serving.'),

-- Lomo Saltado
('lomo_saltado', 'Lomo Saltado (Stir-Fried Beef)', 145.0, 12.0, 12.0, 5.5, 1.0, 1.5, NULL, 350, 'peruvian_cuisine', ARRAY['lomo saltado peruano', 'peruvian beef stir fry', 'saltado de lomo'], 'peruvian', 1, 'Stir-fried beef with tomatoes, onions, fries and rice. ~508 cal per 350g plate.'),

-- Aji de Gallina
('aji_de_gallina', 'Aji de Gallina (Creamy Chicken)', 155.0, 10.0, 10.5, 8.5, 1.2, 1.0, NULL, 300, 'peruvian_cuisine', ARRAY['aji de gallina peruano', 'peruvian creamy chicken', 'chicken aji'], 'peruvian', 1, 'Shredded chicken in creamy aji amarillo walnut sauce. ~465 cal per 300g serving.'),

-- Arroz con Pollo (Peruvian)
('arroz_con_pollo_peruano', 'Arroz con Pollo (Peruvian)', 145.0, 10.0, 17.0, 4.0, 0.8, 0.5, NULL, 350, 'peruvian_cuisine', ARRAY['arroz con pollo', 'peruvian chicken rice', 'green rice chicken'], 'peruvian', 1, 'Chicken with cilantro-beer green rice. ~508 cal per 350g plate.'),

-- Anticuchos (Beef Heart Skewers)
('anticuchos', 'Anticuchos (Beef Heart Skewers)', 175.0, 20.0, 3.0, 9.0, 0.3, 0.5, 80, 160, 'peruvian_cuisine', ARRAY['anticuchos de corazon', 'beef heart skewers', 'anticucho peruano'], 'peruvian', 2, 'Marinated grilled beef heart skewers. ~140 cal per 80g skewer.'),

-- Causa (Potato Terrine)
('causa_limena', 'Causa Limena (Potato Terrine)', 160.0, 5.5, 18.0, 7.5, 1.5, 0.8, 150, 150, 'peruvian_cuisine', ARRAY['causa', 'causa rellena', 'causa de atun', 'causa de pollo', 'peruvian potato terrine'], 'peruvian', 1, 'Layered mashed potato with aji amarillo, chicken/tuna filling. ~240 cal per 150g piece.'),

-- Papa a la Huancaina
('papa_a_la_huancaina', 'Papa a la Huancaina', 145.0, 4.5, 13.0, 8.5, 1.2, 1.5, NULL, 250, 'peruvian_cuisine', ARRAY['huancaina', 'papa huancaina', 'potatoes huancaina sauce', 'salsa huancaina'], 'peruvian', 1, 'Boiled potatoes with creamy aji amarillo cheese sauce. ~363 cal per 250g serving.'),

-- Pollo a la Brasa
('pollo_a_la_brasa', 'Pollo a la Brasa (Rotisserie Chicken)', 190.0, 24.0, 1.5, 9.5, 0.0, 0.2, NULL, 200, 'peruvian_cuisine', ARRAY['peruvian rotisserie chicken', 'pollo a la brasa peruano', 'brasa chicken'], 'peruvian', 1, 'Spit-roasted chicken marinated with Peruvian spices. ~380 cal per 200g quarter.'),

-- =====================================================
-- 4. COLOMBIAN CUISINE
-- Sources: FatSecret, Fitia, NutriScan, recipe analyses
-- =====================================================

-- Bandeja Paisa
('bandeja_paisa', 'Bandeja Paisa (Colombian Platter)', 185.0, 10.5, 16.0, 9.0, 2.5, 1.5, NULL, 500, 'colombian_cuisine', ARRAY['bandeja paisa colombiana', 'colombian platter', 'paisa platter'], 'colombian', 1, 'Rice, beans, ground beef, chicharron, egg, plantain, arepa. ~925 cal per 500g plate.'),

-- Arepa (Plain)
('arepa_plain', 'Arepa (Plain Corn)', 200.0, 4.5, 35.0, 4.5, 2.0, 0.5, 80, 80, 'colombian_cuisine', ARRAY['arepa', 'arepa colombiana', 'corn cake colombian', 'arepa blanca'], 'colombian', 1, 'Ground corn dough cake, grilled or fried. ~160 cal per 80g arepa.'),

-- Arepa con Queso
('arepa_con_queso', 'Arepa con Queso (Cheese Arepa)', 250.0, 8.0, 30.0, 11.0, 1.8, 1.0, 100, 100, 'colombian_cuisine', ARRAY['arepa de queso', 'cheese arepa', 'arepa rellena de queso'], 'colombian', 1, 'Corn arepa stuffed or topped with melted cheese. ~250 cal per 100g arepa.'),

-- Colombian Empanada
('empanada_colombiana', 'Empanada Colombiana', 215.0, 7.0, 26.0, 9.0, 1.5, 0.5, 80, 160, 'colombian_cuisine', ARRAY['empanada colombiana de carne', 'colombian empanada', 'empanada de pipian'], 'colombian', 2, 'Fried corn dough turnover with potato-meat filling. ~172 cal per 80g empanada.'),

-- Sancocho
('sancocho', 'Sancocho (Colombian Soup)', 72.0, 6.0, 8.5, 1.5, 1.0, 1.2, NULL, 400, 'colombian_cuisine', ARRAY['sancocho colombiano', 'sancocho de gallina', 'sancocho de pollo', 'colombian stew'], 'colombian', 1, 'Hearty chicken soup with yuca, plantain, corn, potato. ~288 cal per 400g bowl.'),

-- Bunuelos
('bunuelos', 'Bunuelos Colombianos (Cheese Fritters)', 340.0, 7.0, 35.0, 19.0, 0.5, 3.0, 40, 120, 'colombian_cuisine', ARRAY['bunuelo', 'buñuelo', 'buñuelos colombianos', 'cheese fritters colombian'], 'colombian', 3, 'Deep-fried cheese and corn flour balls. ~136 cal per 40g bunuelo.'),

-- Lechona
('lechona', 'Lechona (Stuffed Roast Pig)', 245.0, 18.0, 8.0, 16.0, 0.8, 0.3, NULL, 200, 'colombian_cuisine', ARRAY['lechona tolimense', 'colombian stuffed pork', 'lechona colombiana'], 'colombian', 1, 'Whole pig stuffed with rice, peas, spices, slow-roasted. ~490 cal per 200g serving.'),

-- =====================================================
-- 5. CUBAN CUISINE
-- Sources: USDA, NutritionValue.org, FatSecret, NutriScan
-- =====================================================

-- Cuban Sandwich
('cuban_sandwich', 'Cuban Sandwich (Cubano)', 274.0, 17.8, 22.7, 12.0, 0.8, 2.0, 280, 280, 'cuban_cuisine', ARRAY['cubano sandwich', 'cubano', 'sandwich cubano', 'pressed cuban sandwich'], 'cuban', 1, 'Pressed sandwich with roast pork, ham, Swiss, pickles, mustard. ~767 cal per 280g sandwich.'),

-- Ropa Vieja
('ropa_vieja', 'Ropa Vieja (Shredded Beef)', 130.0, 15.0, 4.5, 6.0, 1.0, 2.0, NULL, 250, 'cuban_cuisine', ARRAY['ropa vieja cubana', 'cuban shredded beef', 'old clothes beef', 'shredded beef cuban'], 'cuban', 1, 'Slow-braised shredded flank steak in tomato-pepper sauce. ~325 cal per 250g serving.'),

-- Arroz con Pollo (Cuban)
('arroz_con_pollo_cubano', 'Arroz con Pollo (Cuban)', 150.0, 10.5, 16.5, 4.5, 0.8, 0.8, NULL, 350, 'cuban_cuisine', ARRAY['cuban chicken rice', 'arroz con pollo cubano', 'yellow rice chicken'], 'cuban', 1, 'Chicken with saffron-yellow rice, Cuban style. ~525 cal per 350g plate.'),

-- Picadillo
('picadillo', 'Picadillo (Cuban Ground Beef)', 145.0, 11.0, 8.5, 7.5, 1.5, 3.0, NULL, 200, 'cuban_cuisine', ARRAY['picadillo cubano', 'cuban picadillo', 'ground beef cuban style', 'picadillo a la habanera'], 'cuban', 1, 'Ground beef with olives, raisins, tomato sofrito. ~290 cal per 200g serving.'),

-- Lechon Asado
('lechon_asado', 'Lechon Asado (Cuban Roast Pork)', 225.0, 23.0, 1.0, 14.0, 0.0, 0.3, NULL, 150, 'cuban_cuisine', ARRAY['cuban roast pork', 'lechon cubano', 'roast pork cuban', 'pernil asado'], 'cuban', 1, 'Citrus-garlic marinated slow-roasted pork leg. ~338 cal per 150g serving.'),

-- Medianoche Sandwich
('medianoche', 'Medianoche Sandwich', 270.0, 16.0, 25.0, 12.5, 0.5, 5.0, 250, 250, 'cuban_cuisine', ARRAY['medianoche cubano', 'midnight sandwich', 'cuban midnight sandwich'], 'cuban', 1, 'Pressed sandwich on sweet egg bread with roast pork, ham, Swiss, pickles. ~675 cal per 250g sandwich.'),

-- Cuban Black Beans
('frijoles_negros_cubanos', 'Cuban Black Beans (Cooked)', 110.0, 7.0, 18.0, 1.2, 5.5, 0.5, NULL, 200, 'cuban_cuisine', ARRAY['frijoles negros', 'cuban black beans', 'black beans cuban style', 'frijoles negros cubanos'], 'cuban', 1, 'Slow-cooked black beans with sofrito, cumin. ~220 cal per 200g serving.'),

-- Tostones
('tostones', 'Tostones (Fried Green Plantain)', 270.0, 1.5, 38.0, 13.0, 2.5, 1.5, 80, 120, 'cuban_cuisine', ARRAY['tostones de platano', 'fried green plantain', 'patacones', 'twice-fried plantain'], 'cuban', 1, 'Twice-fried green plantain slices. ~324 cal per 120g serving.'),

-- Maduros
('maduros', 'Maduros (Fried Sweet Plantain)', 236.0, 1.2, 42.0, 8.0, 2.8, 22.0, 100, 100, 'cuban_cuisine', ARRAY['platanos maduros', 'fried sweet plantain', 'sweet plantains', 'platanos fritos'], 'cuban', 1, 'Fried ripe sweet plantain slices. ~236 cal per 100g serving.'),

-- =====================================================
-- 6. CARIBBEAN / JAMAICAN CUISINE
-- Sources: USDA, NutriScan, SnapCalorie, FatSecret, Fitia
-- =====================================================

-- Jerk Chicken
('jerk_chicken', 'Jerk Chicken', 167.0, 26.5, 3.3, 5.0, 0.5, 1.0, NULL, 200, 'caribbean_cuisine', ARRAY['jamaican jerk chicken', 'jerk chicken thigh', 'jerk chicken breast', 'pollo jerk'], 'caribbean', 1, 'Chicken marinated in scotch bonnet and allspice, grilled. ~334 cal per 200g serving.'),

-- Rice and Peas (Jamaican)
('jamaican_rice_and_peas', 'Jamaican Rice and Peas', 145.0, 4.0, 24.0, 3.5, 2.0, 0.5, NULL, 200, 'caribbean_cuisine', ARRAY['rice and peas', 'jamaican rice peas', 'coconut rice and kidney beans', 'rice and peas jamaica'], 'caribbean', 1, 'Rice cooked with kidney beans, coconut milk, thyme. ~290 cal per 200g serving.'),

-- Ackee and Saltfish
('ackee_and_saltfish', 'Ackee and Saltfish', 175.0, 12.0, 3.5, 13.0, 1.5, 0.5, NULL, 200, 'caribbean_cuisine', ARRAY['ackee and codfish', 'aki and saltfish', 'jamaican national dish', 'ackee saltfish'], 'caribbean', 1, 'Jamaica national dish: ackee fruit sauteed with salted cod. ~350 cal per 200g serving.'),

-- Jamaican Patty (Beef)
('jamaican_patty', 'Jamaican Patty (Beef)', 265.0, 8.0, 28.0, 13.5, 1.2, 2.0, 140, 140, 'caribbean_cuisine', ARRAY['jamaican beef patty', 'patty jamaican', 'jamaican meat pie', 'beef patty'], 'caribbean', 1, 'Turmeric pastry filled with curried ground beef. ~371 cal per 140g patty.'),

-- Oxtail Stew (Jamaican)
('jamaican_oxtail_stew', 'Jamaican Oxtail Stew', 159.0, 17.0, 6.0, 8.0, 1.0, 1.5, NULL, 300, 'caribbean_cuisine', ARRAY['oxtail stew', 'stewed oxtail', 'jamaican oxtail', 'brown stew oxtail'], 'caribbean', 1, 'Slow-braised oxtail with butter beans in rich gravy. ~477 cal per 300g serving.'),

-- Callaloo
('callaloo', 'Callaloo (Caribbean Greens)', 35.0, 2.5, 5.0, 0.5, 2.0, 0.8, NULL, 200, 'caribbean_cuisine', ARRAY['jamaican callaloo', 'callaloo greens', 'steamed callaloo', 'callaloo and saltfish'], 'caribbean', 1, 'Steamed leafy greens similar to spinach. ~70 cal per 200g serving.'),

-- Festival (Jamaican Fried Dumpling)
('festival_jamaican', 'Festival (Jamaican Fried Dumpling)', 300.0, 3.5, 40.0, 14.0, 1.0, 8.0, 60, 120, 'caribbean_cuisine', ARRAY['festival dumpling', 'jamaican festival', 'fried dumpling jamaican', 'sweet fried dumpling'], 'caribbean', 2, 'Sweet fried cornmeal dumpling. ~180 cal per 60g piece.'),

-- Doubles (Trinidad)
('doubles_trinidad', 'Doubles (Trinidadian)', 210.0, 7.0, 30.0, 7.5, 3.5, 2.0, 150, 150, 'caribbean_cuisine', ARRAY['trinidad doubles', 'doubles and channa', 'bara and channa', 'trinidadian street food'], 'caribbean', 1, 'Two fried flatbreads (bara) with curried chickpeas (channa). ~315 cal per 150g serving.'),

-- Roti (Caribbean Style)
('roti_caribbean', 'Roti (Caribbean, with Curry Filling)', 180.0, 8.0, 22.0, 7.0, 2.0, 1.5, 300, 300, 'caribbean_cuisine', ARRAY['caribbean roti', 'curry roti', 'trinidad roti', 'dhalpuri roti', 'roti skin with filling'], 'caribbean', 1, 'Flatbread wrap filled with curried chicken/goat and potato. ~540 cal per 300g roti.')

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
  food_category = EXCLUDED.food_category,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  updated_at = NOW();
