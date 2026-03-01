-- ============================================================================
-- 289_overrides_italian_chains.sql
-- Italian chains: Carrabba's, Buca di Beppo, North Italia, Johnny Carino's, Bravo
-- ============================================================================

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  source, variant_names, notes,
  restaurant_name, food_category, default_count
) VALUES
('carrabbas_chicken_bryan', 'Carrabba''s Chicken Bryan', 194.3, 14.9, 2.3, 13.7, 0.5, 1.0, NULL, 350, 'carrabbas.com', ARRAY['carrabbas chicken bryan', 'carrabbas chicken'], '680 cal per 350g serving. Grilled chicken with goat cheese, sun-dried tomatoes, lemon butter.', 'Carrabba''s', 'italian', 1),
('carrabbas_chicken_parmesan', 'Carrabba''s Chicken Parmesan', 202.4, 13.1, 11.4, 11.4, 1.5, 3.0, NULL, 420, 'carrabbas.com', ARRAY['carrabbas chicken parm', 'carrabbas chicken parmesan'], '850 cal per 420g serving. Breaded chicken with marinara, mozzarella, spaghetti.', 'Carrabba''s', 'italian', 1),
('carrabbas_fettuccine_alfredo', 'Carrabba''s Fettuccine Alfredo', 205.3, 6.3, 17.9, 11.6, 1.0, 2.0, NULL, 380, 'carrabbas.com', ARRAY['carrabbas alfredo', 'carrabbas fettuccine'], '780 cal per 380g serving.', 'Carrabba''s', 'italian', 1),
('carrabbas_rigatoni', 'Carrabba''s Rigatoni Campagnolo', 189.5, 7.9, 16.3, 10.0, 2.0, 3.0, NULL, 380, 'carrabbas.com', ARRAY['carrabbas rigatoni', 'carrabbas pasta'], '720 cal per 380g serving. Rigatoni with sausage, peppers, onions, tomato cream.', 'Carrabba''s', 'italian', 1),
('carrabbas_lasagne', 'Carrabba''s Lasagne', 194.3, 9.7, 12.6, 11.4, 1.5, 3.0, NULL, 350, 'carrabbas.com', ARRAY['carrabbas lasagna'], '680 cal per 350g serving. Layers of pasta, meat sauce, ricotta, mozzarella.', 'Carrabba''s', 'italian', 1),
('carrabbas_calamari', 'Carrabba''s Calamari', 248.0, 8.8, 19.2, 15.2, 0.5, 1.0, NULL, 250, 'carrabbas.com', ARRAY['carrabbas fried calamari', 'carrabbas calamari appetizer'], '620 cal per 250g serving. Lightly fried with marinara.', 'Carrabba''s', 'italian', 1),
('carrabbas_tiramisu', 'Carrabba''s Tiramisu', 266.7, 4.4, 26.7, 15.6, 0.5, 18.0, 180, 180, 'carrabbas.com', ARRAY['carrabbas tiramisu dessert'], '480 cal per 180g slice. Classic espresso-soaked ladyfingers with mascarpone.', 'Carrabba''s', 'desserts', 1),
('buca_chicken_parmesan', 'Buca di Beppo Chicken Parmesan', 195.0, 12.0, 13.0, 10.0, 1.5, 3.0, NULL, 400, 'bucadibeppo.com', ARRAY['buca chicken parm', 'buca di beppo chicken parmesan'], '780 cal per individual serving (400g). Breaded chicken with spaghetti.', 'Buca di Beppo', 'italian', 1),
('buca_baked_ziti', 'Buca di Beppo Baked Ziti', 185.7, 8.0, 16.6, 9.7, 1.5, 3.0, NULL, 350, 'bucadibeppo.com', ARRAY['buca ziti', 'buca di beppo baked ziti'], '650 cal per serving (350g). Ziti with meat sauce, ricotta, mozzarella.', 'Buca di Beppo', 'italian', 1),
('buca_spaghetti_meatballs', 'Buca di Beppo Spaghetti & Meatballs', 180.0, 8.0, 17.0, 8.5, 2.0, 4.0, NULL, 400, 'bucadibeppo.com', ARRAY['buca spaghetti', 'buca meatballs', 'buca di beppo spaghetti'], '720 cal per individual serving (400g).', 'Buca di Beppo', 'italian', 1),
('buca_chicken_marsala', 'Buca di Beppo Chicken Marsala', 165.7, 12.0, 5.1, 10.9, 0.5, 2.0, NULL, 350, 'bucadibeppo.com', ARRAY['buca marsala', 'buca di beppo marsala'], '580 cal per serving (350g). Pan-seared chicken in mushroom marsala wine sauce.', 'Buca di Beppo', 'italian', 1),
('buca_prosciutto_burrata', 'Buca di Beppo Prosciutto & Burrata', 210.0, 9.0, 6.0, 17.0, 0.5, 1.0, NULL, 200, 'bucadibeppo.com', ARRAY['buca burrata', 'buca di beppo burrata'], '420 cal per 200g appetizer. Creamy burrata with prosciutto, arugula.', 'Buca di Beppo', 'italian', 1),
('buca_bruschetta', 'Buca di Beppo Bruschetta', 186.7, 4.0, 18.7, 10.7, 1.5, 3.0, NULL, 150, 'bucadibeppo.com', ARRAY['buca bruschetta appetizer'], '280 cal per 150g serving.', 'Buca di Beppo', 'italian', 1),
('north_italia_margherita', 'North Italia Margherita Pizza', 212.5, 8.8, 22.5, 9.4, 1.5, 3.0, NULL, 320, 'northitalia.com', ARRAY['north italia margherita', 'north italia pizza'], '680 cal per pizza (320g). San Marzano, fresh mozzarella, basil.', 'North Italia', 'italian', 1),
('north_italia_bolognese', 'North Italia Bolognese', 189.5, 8.4, 16.3, 9.5, 2.0, 3.0, NULL, 380, 'northitalia.com', ARRAY['north italia bolognese pasta'], '720 cal per 380g serving. Rigatoni with slow-braised meat sauce.', 'North Italia', 'italian', 1),
('north_italia_garlic_bread', 'North Italia White Truffle Garlic Bread', 240.0, 6.0, 21.0, 15.0, 1.0, 1.5, NULL, 200, 'northitalia.com', ARRAY['north italia garlic bread', 'north italia truffle bread'], '480 cal per 200g serving.', 'North Italia', 'italian', 1),
('north_italia_pollo', 'North Italia Italian Chicken', 148.6, 12.6, 3.4, 9.1, 1.0, 1.5, NULL, 350, 'northitalia.com', ARRAY['north italia chicken', 'north italia pollo'], '520 cal per 350g serving. Wood-roasted half chicken.', 'North Italia', 'italian', 1),
('north_italia_burrata', 'North Italia Burrata & Prosciutto', 204.5, 9.1, 4.5, 16.4, 0.5, 1.0, NULL, 220, 'northitalia.com', ARRAY['north italia burrata appetizer'], '450 cal per 220g serving.', 'North Italia', 'italian', 1),
('north_italia_caesar', 'North Italia Caesar Salad', 152.0, 4.8, 7.2, 12.0, 2.0, 1.5, NULL, 250, 'northitalia.com', ARRAY['north italia caesar salad'], '380 cal per 250g salad.', 'North Italia', 'salads', 1),
('carinos_chicken_scallopini', 'Johnny Carino''s Chicken Scallopini', 178.9, 11.8, 8.4, 10.5, 1.0, 2.0, NULL, 380, 'carinos.com', ARRAY['carinos chicken scallopini', 'johnny carinos chicken'], '680 cal per 380g serving. Sautéed chicken with mushrooms, artichokes, lemon butter.', 'Johnny Carino''s', 'italian', 1),
('carinos_baked_rigatoni', 'Johnny Carino''s Baked Rigatoni', 187.5, 7.5, 16.0, 10.0, 1.5, 3.0, NULL, 400, 'carinos.com', ARRAY['carinos rigatoni', 'johnny carinos baked rigatoni'], '750 cal per 400g serving. Rigatoni with meat sauce, ricotta, mozzarella.', 'Johnny Carino''s', 'italian', 1),
('carinos_spicy_shrimp_chicken', 'Johnny Carino''s Spicy Shrimp & Chicken', 180.0, 9.5, 13.0, 9.5, 1.5, 2.5, NULL, 400, 'carinos.com', ARRAY['carinos spicy shrimp', 'johnny carinos shrimp chicken'], '720 cal per 400g serving. With bowtie pasta in spicy cream sauce.', 'Johnny Carino''s', 'italian', 1),
('carinos_italian_nachos', 'Johnny Carino''s Italian Nachos', 251.4, 9.1, 16.6, 16.6, 1.5, 2.5, NULL, 350, 'carinos.com', ARRAY['carinos nachos', 'johnny carinos italian nachos'], '880 cal per 350g appetizer. Fried pasta chips with meat, cheese, jalapeños.', 'Johnny Carino''s', 'italian', 1),
('carinos_meat_lasagna', 'Johnny Carino''s Meat Lasagna', 194.3, 9.7, 12.0, 11.4, 1.5, 3.0, NULL, 350, 'carinos.com', ARRAY['carinos lasagna', 'johnny carinos lasagna'], '680 cal per 350g serving.', 'Johnny Carino''s', 'italian', 1),
('bravo_chicken_limone', 'Bravo Chicken Limone', 165.7, 12.0, 6.9, 9.7, 1.0, 1.5, NULL, 350, 'bravoitalian.com', ARRAY['bravo chicken limone', 'bravo chicken lemon'], '580 cal per 350g serving. Grilled chicken with lemon butter, capers, artichokes.', 'Bravo', 'italian', 1),
('bravo_shrimp_scampi', 'Bravo Shrimp Scampi', 167.6, 7.6, 13.0, 9.2, 1.0, 1.5, NULL, 370, 'bravoitalian.com', ARRAY['bravo shrimp scampi', 'bravo scampi'], '620 cal per 370g serving. Shrimp with angel hair, garlic, white wine butter.', 'Bravo', 'italian', 1),
('bravo_flatbread_margherita', 'Bravo Margherita Flatbread', 208.0, 8.8, 19.2, 10.4, 1.0, 2.5, NULL, 250, 'bravoitalian.com', ARRAY['bravo flatbread', 'bravo margherita pizza'], '520 cal per 250g flatbread.', 'Bravo', 'italian', 1),
('bravo_pasta_woozie', 'Bravo Pasta Woozie', 205.0, 7.0, 18.0, 11.5, 1.5, 2.5, NULL, 400, 'bravoitalian.com', ARRAY['bravo pasta woozie', 'bravo signature pasta'], '820 cal per 400g serving. Rigatoni with Italian sausage in vodka sauce.', 'Bravo', 'italian', 1),
('bravo_house_salad', 'Bravo Insalata della Casa', 128.0, 4.0, 6.4, 9.6, 2.5, 3.0, NULL, 250, 'bravoitalian.com', ARRAY['bravo house salad', 'bravo insalata'], '320 cal per 250g salad.', 'Bravo', 'salads', 1)

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
  restaurant_name = EXCLUDED.restaurant_name,
  food_category = EXCLUDED.food_category,
  default_count = EXCLUDED.default_count,
  updated_at = NOW();
