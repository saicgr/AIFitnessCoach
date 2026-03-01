-- ============================================================================
-- Batch 34: Common Frozen, Deli & Canned Foods
-- Total items: 48
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov), manufacturer nutrition labels
-- All values are per 100g. Calorie check: cal ≈ protein*4 + carbs*4 + fat*9
-- ============================================================================

-- ============================================================================
-- FROZEN MEALS (food_category = 'frozen') (~10 items)
-- ============================================================================

-- Hot Pocket Pepperoni Pizza: 250 cal/100g (9.0P*4 + 30.0C*4 + 10.5F*9 = 36+120+94.5 = 250.5) ✓
('hot_pocket_pepperoni_pizza', 'Hot Pocket (Pepperoni Pizza)', 250, 9.0, 30.0, 10.5, 1.5, 5.0, 127, 127, 'usda', ARRAY['hot pocket', 'hot pocket pepperoni', 'pepperoni hot pocket', 'pizza hot pocket'], '317 cal per pocket (127g). Microwaveable stuffed sandwich.', NULL, 'frozen', 1),

-- Pizza Rolls (10 pcs): 220 cal/100g (7.1P*4 + 28.6C*4 + 8.6F*9 = 28.4+114.4+77.4 = 220.2) ✓
('pizza_rolls', 'Pizza Rolls (Pepperoni)', 220, 7.1, 28.6, 8.6, 1.4, 3.6, 14, 140, 'usda', ARRAY['pizza rolls', 'totinos pizza rolls', 'pizza bites', 'pizza snacks'], '308 cal per 10 pieces (140g). Frozen pizza snack rolls.', NULL, 'frozen', 10),

-- Lean Cuisine Chicken: 103 cal/100g (8.6P*4 + 13.6C*4 + 1.8F*9 = 34.4+54.4+16.2 = 105.0) ✓
('lean_cuisine_chicken', 'Lean Cuisine Herb Roasted Chicken', 103, 8.6, 13.6, 1.8, 1.4, 2.5, 227, 227, 'usda', ARRAY['lean cuisine chicken', 'lean cuisine', 'frozen chicken dinner', 'lean cuisine meal'], '234 cal per meal (227g). Low-calorie frozen dinner.', NULL, 'frozen', 1),

-- Frozen Burrito Bean & Cheese: 212 cal/100g (7.0P*4 + 30.0C*4 + 6.7F*9 = 28+120+60.3 = 208.3) ✓
('frozen_burrito_bean_cheese', 'Frozen Burrito (Bean & Cheese)', 212, 7.0, 30.0, 6.7, 3.0, 1.5, 142, 142, 'usda', ARRAY['frozen burrito', 'bean and cheese burrito', 'el monterey burrito', 'microwave burrito'], '301 cal per burrito (142g). Bean and cheese filling.', NULL, 'frozen', 1),

-- Frozen Chicken Nuggets: 250 cal/100g (14.0P*4 + 16.0C*4 + 14.5F*9 = 56+64+130.5 = 250.5) ✓
('frozen_chicken_nuggets', 'Frozen Chicken Nuggets', 250, 14.0, 16.0, 14.5, 0.8, 0.5, 16, 96, 'usda', ARRAY['chicken nuggets', 'frozen nuggets', 'dino nuggets', 'tyson nuggets'], '240 cal per 6 pieces (96g). Breaded, baked from frozen.', NULL, 'frozen', 6),

-- Frozen Fish Sticks: 230 cal/100g (11.5P*4 + 21.0C*4 + 11.0F*9 = 46+84+99 = 229.0) ✓
('frozen_fish_sticks', 'Frozen Fish Sticks', 230, 11.5, 21.0, 11.0, 0.5, 1.5, 28, 112, 'usda', ARRAY['fish sticks', 'fish fingers', 'gortons fish sticks', 'breaded fish sticks'], '258 cal per 4 sticks (112g). Breaded, baked from frozen.', NULL, 'frozen', 4),

-- Frozen Pizza Cheese (1/4 pie): 240 cal/100g (10.0P*4 + 28.0C*4 + 10.0F*9 = 40+112+90 = 242.0) ✓
('frozen_pizza_cheese', 'Frozen Pizza (Cheese, 1/4 pie)', 240, 10.0, 28.0, 10.0, 1.5, 4.0, 130, 130, 'usda', ARRAY['frozen cheese pizza', 'digiorno cheese pizza', 'frozen pizza', 'tombstone pizza'], '312 cal per 1/4 pie (130g). Rising crust cheese pizza.', NULL, 'frozen', 1),

-- Frozen Pot Pie: 195 cal/100g (6.5P*4 + 19.0C*4 + 10.5F*9 = 26+76+94.5 = 196.5) ✓
('frozen_pot_pie_chicken', 'Frozen Chicken Pot Pie', 195, 6.5, 19.0, 10.5, 1.0, 3.0, 198, 198, 'usda', ARRAY['chicken pot pie', 'frozen pot pie', 'marie callender pot pie', 'banquet pot pie'], '386 cal per pot pie (198g). Frozen, baked.', NULL, 'frozen', 1),

-- Frozen Dinner Roll: 278 cal/100g (8.5P*4 + 48.0C*4 + 5.5F*9 = 34+192+49.5 = 275.5) ✓
('frozen_dinner_roll', 'Frozen Dinner Roll', 278, 8.5, 48.0, 5.5, 2.0, 5.0, 35, 35, 'usda', ARRAY['frozen roll', 'dinner roll', 'rhodes roll', 'sister schuberts roll'], '97 cal per roll (35g). Baked from frozen.', NULL, 'frozen', 1),

-- Frozen Waffle (Eggo): 275 cal/100g (5.7P*4 + 42.9C*4 + 9.1F*9 = 22.8+171.6+81.9 = 276.3) ✓
('frozen_waffle_eggo', 'Frozen Waffle (Eggo)', 275, 5.7, 42.9, 9.1, 1.4, 8.6, 35, 70, 'usda', ARRAY['eggo waffle', 'frozen waffle', 'toaster waffle', 'eggo homestyle'], '193 cal per 2 waffles (70g). Toasted from frozen.', NULL, 'frozen', 2),

-- ============================================================================
-- FROZEN VEGETABLES (food_category = 'frozen') (~5 items)
-- ============================================================================

-- Frozen Broccoli Steamed: 35 cal/100g (2.8P*4 + 5.6C*4 + 0.4F*9 = 11.2+22.4+3.6 = 37.2) ✓
('frozen_broccoli', 'Frozen Broccoli (Steamed)', 35, 2.8, 5.6, 0.4, 3.3, 1.1, NULL, 92, 'usda', ARRAY['frozen broccoli', 'steamed broccoli', 'frozen broccoli florets'], '32 cal per serving (92g). Steamed, no added butter.', NULL, 'frozen', 1),

-- Frozen Mixed Vegetables: 55 cal/100g (2.6P*4 + 10.0C*4 + 0.4F*9 = 10.4+40.0+3.6 = 54.0) ✓
('frozen_mixed_vegetables', 'Frozen Mixed Vegetables', 55, 2.6, 10.0, 0.4, 3.5, 2.5, NULL, 91, 'usda', ARRAY['frozen mixed vegetables', 'mixed veggies', 'frozen veggie mix', 'mixed vegetables'], '50 cal per serving (91g). Corn, peas, carrots, green beans, lima beans.', NULL, 'frozen', 1),

-- Frozen Peas: 77 cal/100g (5.2P*4 + 12.0C*4 + 0.4F*9 = 20.8+48.0+3.6 = 72.4) ✓
('frozen_peas', 'Frozen Green Peas', 77, 5.2, 12.0, 0.4, 4.1, 4.8, NULL, 80, 'usda', ARRAY['frozen peas', 'green peas', 'frozen garden peas', 'peas'], '62 cal per serving (80g). Boiled, drained.', NULL, 'frozen', 1),

-- Frozen Corn: 92 cal/100g (3.0P*4 + 19.0C*4 + 1.1F*9 = 12+76+9.9 = 97.9) ✓
('frozen_corn', 'Frozen Sweet Corn', 92, 3.0, 19.0, 1.1, 2.4, 3.5, NULL, 85, 'usda', ARRAY['frozen corn', 'frozen sweet corn', 'corn kernels', 'frozen corn kernels'], '78 cal per serving (85g). Boiled, drained.', NULL, 'frozen', 1),

-- Frozen Spinach Thawed: 29 cal/100g (3.0P*4 + 3.8C*4 + 0.3F*9 = 12+15.2+2.7 = 29.9) ✓
('frozen_spinach', 'Frozen Spinach (Thawed)', 29, 3.0, 3.8, 0.3, 2.4, 0.5, NULL, 95, 'usda', ARRAY['frozen spinach', 'thawed spinach', 'spinach frozen', 'chopped spinach'], '28 cal per serving (95g). Thawed, drained.', NULL, 'frozen', 1),

-- ============================================================================
-- FROZEN FRUITS (food_category = 'frozen') (~3 items)
-- ============================================================================

-- Frozen Strawberries: 35 cal/100g (0.7P*4 + 7.7C*4 + 0.3F*9 = 2.8+30.8+2.7 = 36.3) ✓
('frozen_strawberries', 'Frozen Strawberries (Unsweetened)', 35, 0.7, 7.7, 0.3, 2.0, 5.0, NULL, 140, 'usda', ARRAY['frozen strawberries', 'frozen berries', 'unsweetened frozen strawberries'], '49 cal per cup (140g). Unsweetened, whole.', NULL, 'frozen', 1),

-- Frozen Mixed Berries: 48 cal/100g (0.8P*4 + 10.5C*4 + 0.3F*9 = 3.2+42+2.7 = 47.9) ✓
('frozen_mixed_berries', 'Frozen Mixed Berries', 48, 0.8, 10.5, 0.3, 3.2, 7.0, NULL, 140, 'usda', ARRAY['frozen mixed berries', 'frozen berry mix', 'mixed berries', 'frozen fruit blend'], '67 cal per cup (140g). Strawberries, blueberries, raspberries, blackberries.', NULL, 'frozen', 1),

-- Frozen Mango Chunks: 60 cal/100g (0.8P*4 + 15.0C*4 + 0.2F*9 = 3.2+60+1.8 = 65.0) ✓
('frozen_mango_chunks', 'Frozen Mango Chunks', 60, 0.8, 15.0, 0.2, 1.6, 12.5, NULL, 140, 'usda', ARRAY['frozen mango', 'frozen mango chunks', 'mango chunks', 'frozen mango pieces'], '84 cal per cup (140g). Unsweetened, diced.', NULL, 'frozen', 1),

-- ============================================================================
-- DELI COUNTER MEATS (food_category = 'deli') (~10 items)
-- ============================================================================

-- Turkey Breast Deli Sliced: 104 cal/100g (17.5P*4 + 3.5C*4 + 1.5F*9 = 70+14+13.5 = 97.5) ✓
('turkey_breast_deli', 'Turkey Breast (Deli Sliced)', 104, 17.5, 3.5, 1.5, 0, 2.0, 28, 56, 'usda', ARRAY['turkey breast deli', 'sliced turkey', 'deli turkey', 'turkey lunch meat', 'turkey cold cut'], '58 cal per 2 slices (56g). Oven-roasted, low sodium.', NULL, 'deli', 2),

-- Ham Deli Sliced: 120 cal/100g (16.0P*4 + 4.0C*4 + 4.0F*9 = 64+16+36 = 116.0) ✓
('ham_deli_sliced', 'Ham (Deli Sliced)', 120, 16.0, 4.0, 4.0, 0, 3.0, 28, 56, 'usda', ARRAY['ham deli', 'sliced ham', 'deli ham', 'honey ham', 'ham lunch meat'], '67 cal per 2 slices (56g). Honey or smoked.', NULL, 'deli', 2),

-- Roast Beef Deli: 130 cal/100g (19.0P*4 + 1.5C*4 + 5.0F*9 = 76+6+45 = 127.0) ✓
('roast_beef_deli', 'Roast Beef (Deli Sliced)', 130, 19.0, 1.5, 5.0, 0, 0.5, 28, 56, 'usda', ARRAY['roast beef deli', 'sliced roast beef', 'deli roast beef', 'rare roast beef'], '73 cal per 2 slices (56g). Top round, lean.', NULL, 'deli', 2),

-- Chicken Breast Deli: 110 cal/100g (18.0P*4 + 2.5C*4 + 2.5F*9 = 72+10+22.5 = 104.5) ✓
('chicken_breast_deli', 'Chicken Breast (Deli Sliced)', 110, 18.0, 2.5, 2.5, 0, 1.0, 28, 56, 'usda', ARRAY['chicken breast deli', 'sliced chicken', 'deli chicken', 'chicken lunch meat'], '62 cal per 2 slices (56g). Oven-roasted.', NULL, 'deli', 2),

-- Genoa Salami: 390 cal/100g (22.0P*4 + 1.0C*4 + 33.0F*9 = 88+4+297 = 389.0) ✓
('genoa_salami', 'Genoa Salami (Sliced)', 390, 22.0, 1.0, 33.0, 0, 0.5, 28, 28, 'usda', ARRAY['genoa salami', 'salami', 'sliced salami', 'italian salami', 'hard salami'], '109 cal per 1 oz (28g). Dry cured Italian salami.', NULL, 'deli', 1),

-- Pepperoni Slices: 494 cal/100g (22.0P*4 + 2.0C*4 + 44.0F*9 = 88+8+396 = 492.0) ✓
('pepperoni_slices', 'Pepperoni (Sliced)', 494, 22.0, 2.0, 44.0, 0, 0.5, 3, 28, 'usda', ARRAY['pepperoni', 'pepperoni slices', 'sliced pepperoni', 'turkey pepperoni'], '138 cal per 1 oz / ~9 slices (28g). Cured pork and beef.', NULL, 'deli', 9),

-- Bologna: 310 cal/100g (11.0P*4 + 3.0C*4 + 28.0F*9 = 44+12+252 = 308.0) ✓
('bologna', 'Bologna (Sliced)', 310, 11.0, 3.0, 28.0, 0, 2.0, 28, 28, 'usda', ARRAY['bologna', 'baloney', 'oscar mayer bologna', 'beef bologna'], '87 cal per slice (28g). Pork and beef.', NULL, 'deli', 1),

-- Pastrami: 147 cal/100g (22.0P*4 + 1.5C*4 + 5.5F*9 = 88+6+49.5 = 143.5) ✓
('pastrami_deli', 'Pastrami (Deli Sliced)', 147, 22.0, 1.5, 5.5, 0, 0.5, 28, 56, 'usda', ARRAY['pastrami', 'sliced pastrami', 'deli pastrami', 'beef pastrami'], '82 cal per 2 slices (56g). Beef, cured and smoked.', NULL, 'deli', 2),

-- Corned Beef Deli: 180 cal/100g (25.0P*4 + 0.5C*4 + 8.5F*9 = 100+2+76.5 = 178.5) ✓
('corned_beef_deli', 'Corned Beef (Deli Sliced)', 180, 25.0, 0.5, 8.5, 0, 0, 28, 56, 'usda', ARRAY['corned beef', 'sliced corned beef', 'deli corned beef'], '101 cal per 2 slices (56g). Brisket, cured.', NULL, 'deli', 2),

-- Prosciutto: 250 cal/100g (24.0P*4 + 0, C*4 + 17.0F*9 = 96+0+153 = 249.0) ✓
('prosciutto', 'Prosciutto', 250, 24.0, 0, 17.0, 0, 0, 15, 30, 'usda', ARRAY['prosciutto', 'prosciutto di parma', 'italian prosciutto', 'dry cured ham'], '75 cal per 2 thin slices (30g). Dry-cured Italian ham.', NULL, 'deli', 2),

-- ============================================================================
-- CANNED FOODS (food_category = 'canned') (~12 items)
-- ============================================================================

-- Canned Tuna in Water: 86 cal/100g (19.4P*4 + 0C*4 + 0.8F*9 = 77.6+0+7.2 = 84.8) ✓
('canned_tuna_water', 'Canned Tuna (in Water, Drained)', 86, 19.4, 0, 0.8, 0, 0, NULL, 112, 'usda', ARRAY['canned tuna', 'tuna in water', 'chunk light tuna', 'starkist tuna', 'tuna can'], '96 cal per can drained (112g). Chunk light, drained.', NULL, 'canned', 1),

-- Canned Tuna in Oil: 190 cal/100g (26.5P*4 + 0C*4 + 8.2F*9 = 106+0+73.8 = 179.8) ✓
('canned_tuna_oil', 'Canned Tuna (in Oil, Drained)', 190, 26.5, 0, 8.2, 0, 0, NULL, 112, 'usda', ARRAY['tuna in oil', 'oil packed tuna', 'canned tuna oil'], '213 cal per can drained (112g). Packed in oil, drained.', NULL, 'canned', 1),

-- Canned Chicken Breast: 113 cal/100g (21.5P*4 + 0C*4 + 2.7F*9 = 86+0+24.3 = 110.3) ✓
('canned_chicken_breast', 'Canned Chicken Breast', 113, 21.5, 0, 2.7, 0, 0, NULL, 113, 'usda', ARRAY['canned chicken', 'chicken breast canned', 'swanson canned chicken'], '128 cal per can drained (113g). In water, drained.', NULL, 'canned', 1),

-- Canned Salmon: 136 cal/100g (20.0P*4 + 0C*4 + 6.0F*9 = 80+0+54 = 134.0) ✓
('canned_salmon', 'Canned Salmon (Pink)', 136, 20.0, 0, 6.0, 0, 0, NULL, 105, 'usda', ARRAY['canned salmon', 'canned pink salmon', 'salmon can', 'tinned salmon'], '143 cal per can drained (105g). Pink, with bones, drained.', NULL, 'canned', 1),

-- Canned Sardines: 208 cal/100g (24.6P*4 + 0C*4 + 11.5F*9 = 98.4+0+103.5 = 201.9) ✓
('canned_sardines', 'Canned Sardines (in Oil)', 208, 24.6, 0, 11.5, 0, 0, NULL, 92, 'usda', ARRAY['sardines', 'canned sardines', 'tinned sardines', 'sardines in oil'], '191 cal per can drained (92g). In oil, drained.', NULL, 'canned', 1),

-- Canned Black Beans: 91 cal/100g (6.0P*4 + 15.5C*4 + 0.3F*9 = 24+62+2.7 = 88.7) ✓
('canned_black_beans', 'Canned Black Beans', 91, 6.0, 15.5, 0.3, 5.5, 0.5, NULL, 130, 'usda', ARRAY['canned black beans', 'black beans', 'black beans canned'], '118 cal per 1/2 cup (130g). Drained, rinsed.', NULL, 'canned', 1),

-- Canned Chickpeas: 119 cal/100g (6.5P*4 + 18.0C*4 + 2.0F*9 = 26+72+18 = 116.0) ✓
('canned_chickpeas', 'Canned Chickpeas (Garbanzo Beans)', 119, 6.5, 18.0, 2.0, 5.0, 0.5, NULL, 130, 'usda', ARRAY['canned chickpeas', 'garbanzo beans', 'canned garbanzo', 'chickpeas canned'], '155 cal per 1/2 cup (130g). Drained, rinsed.', NULL, 'canned', 1),

-- Canned Kidney Beans: 84 cal/100g (5.2P*4 + 14.5C*4 + 0.3F*9 = 20.8+58+2.7 = 81.5) ✓
('canned_kidney_beans', 'Canned Kidney Beans', 84, 5.2, 14.5, 0.3, 5.4, 1.5, NULL, 130, 'usda', ARRAY['canned kidney beans', 'red kidney beans', 'kidney beans canned'], '109 cal per 1/2 cup (130g). Dark red, drained.', NULL, 'canned', 1),

-- Canned Corn: 64 cal/100g (2.1P*4 + 14.0C*4 + 0.5F*9 = 8.4+56+4.5 = 68.9) ✓
('canned_corn', 'Canned Corn (Whole Kernel)', 64, 2.1, 14.0, 0.5, 1.5, 4.5, NULL, 125, 'usda', ARRAY['canned corn', 'canned sweet corn', 'corn canned', 'whole kernel corn'], '80 cal per 1/2 cup (125g). Drained.', NULL, 'canned', 1),

-- Canned Tomatoes Diced: 17 cal/100g (0.9P*4 + 3.0C*4 + 0.1F*9 = 3.6+12+0.9 = 16.5) ✓
('canned_tomatoes_diced', 'Canned Tomatoes (Diced)', 17, 0.9, 3.0, 0.1, 0.9, 2.5, NULL, 121, 'usda', ARRAY['canned tomatoes', 'diced tomatoes', 'canned diced tomatoes', 'tomatoes canned'], '21 cal per 1/2 cup (121g). With juice.', NULL, 'canned', 1),

-- Canned Coconut Milk Full Fat: 197 cal/100g (2.2P*4 + 2.8C*4 + 19.7F*9 = 8.8+11.2+177.3 = 197.3) ✓
('canned_coconut_milk', 'Canned Coconut Milk (Full Fat)', 197, 2.2, 2.8, 19.7, 0, 2.5, NULL, 113, 'usda', ARRAY['coconut milk canned', 'full fat coconut milk', 'coconut cream milk', 'canned coconut'], '223 cal per 1/2 cup (113g). Full fat, for cooking.', NULL, 'canned', 1),

-- Canned Pumpkin Pure: 34 cal/100g (1.1P*4 + 7.1C*4 + 0.3F*9 = 4.4+28.4+2.7 = 35.5) ✓
('canned_pumpkin', 'Canned Pumpkin (Pure)', 34, 1.1, 7.1, 0.3, 2.9, 3.0, NULL, 122, 'usda', ARRAY['canned pumpkin', 'pumpkin puree', 'pure pumpkin', 'libby pumpkin'], '41 cal per 1/2 cup (122g). 100% pure pumpkin, not pie filling.', NULL, 'canned', 1),

-- ============================================================================
-- PREPARED DELI (food_category = 'deli') (~8 items)
-- ============================================================================

-- Rotisserie Chicken Breast Meat: 148 cal/100g (25.0P*4 + 0C*4 + 5.0F*9 = 100+0+45 = 145.0) ✓
('rotisserie_chicken_breast', 'Rotisserie Chicken (Breast Meat)', 148, 25.0, 0, 5.0, 0, 0, NULL, 140, 'usda', ARRAY['rotisserie chicken breast', 'deli chicken breast', 'costco chicken breast', 'store roasted chicken'], '207 cal per breast (140g). Skin removed, white meat.', NULL, 'deli', 1),

-- Rotisserie Chicken Dark Meat: 184 cal/100g (22.5P*4 + 0C*4 + 10.5F*9 = 90+0+94.5 = 184.5) ✓
('rotisserie_chicken_dark', 'Rotisserie Chicken (Dark Meat)', 184, 22.5, 0, 10.5, 0, 0, NULL, 115, 'usda', ARRAY['rotisserie dark meat', 'rotisserie thigh', 'deli chicken dark meat'], '212 cal per thigh+drumstick (115g). With skin.', NULL, 'deli', 1),

-- Macaroni Salad Deli: 200 cal/100g (3.0P*4 + 20.0C*4 + 12.0F*9 = 12+80+108 = 200.0) ✓
('macaroni_salad_deli', 'Macaroni Salad (Deli)', 200, 3.0, 20.0, 12.0, 0.8, 6.0, NULL, 150, 'usda', ARRAY['macaroni salad', 'deli macaroni salad', 'mac salad', 'pasta salad deli'], '300 cal per scoop (150g). Classic mayo-based.', NULL, 'deli', 1),

-- Potato Salad Deli: 143 cal/100g (2.0P*4 + 16.0C*4 + 8.0F*9 = 8+64+72 = 144.0) ✓
('potato_salad_deli', 'Potato Salad (Deli)', 143, 2.0, 16.0, 8.0, 1.5, 4.0, NULL, 150, 'usda', ARRAY['potato salad', 'deli potato salad', 'american potato salad'], '215 cal per scoop (150g). Classic mayo-based.', NULL, 'deli', 1),

-- Coleslaw Deli: 99 cal/100g (0.8P*4 + 10.0C*4 + 6.5F*9 = 3.2+40+58.5 = 101.7) ✓
('coleslaw_deli', 'Coleslaw (Deli)', 99, 0.8, 10.0, 6.5, 1.0, 8.0, NULL, 110, 'usda', ARRAY['coleslaw', 'deli coleslaw', 'cole slaw', 'creamy coleslaw'], '109 cal per scoop (110g). Creamy style.', NULL, 'deli', 1),

-- Hummus Store-Bought: 166 cal/100g (7.9P*4 + 14.3C*4 + 9.6F*9 = 31.6+57.2+86.4 = 175.2) ✓
('hummus_store', 'Hummus (Store-Bought)', 166, 7.9, 14.3, 9.6, 6.0, 0.5, NULL, 28, 'usda', ARRAY['hummus', 'store bought hummus', 'sabra hummus', 'classic hummus', 'chickpea dip'], '46 cal per 2 tbsp (28g). Classic, ready-to-eat.', NULL, 'deli', 1),

-- Chicken Salad Deli: 208 cal/100g (13.5P*4 + 4.0C*4 + 15.5F*9 = 54+16+139.5 = 209.5) ✓
('chicken_salad_deli', 'Chicken Salad (Deli)', 208, 13.5, 4.0, 15.5, 0.3, 2.0, NULL, 120, 'usda', ARRAY['chicken salad', 'deli chicken salad', 'chicken salad spread'], '250 cal per scoop (120g). With mayo, celery.', NULL, 'deli', 1),

-- Egg Salad Deli: 208 cal/100g (10.0P*4 + 3.0C*4 + 17.0F*9 = 40+12+153 = 205.0) ✓
('egg_salad_deli', 'Egg Salad (Deli)', 208, 10.0, 3.0, 17.0, 0, 1.5, NULL, 120, 'usda', ARRAY['egg salad', 'deli egg salad', 'egg salad spread'], '250 cal per scoop (120g). With mayo, mustard.', NULL, 'deli', 1)
