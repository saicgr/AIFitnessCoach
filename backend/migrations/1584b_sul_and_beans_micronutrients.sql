-- 1584b_sul_and_beans_micronutrients.sql
-- Fill in micronutrient data for all 43 Sul & Beans menu items.
-- All values are PER 100g (matching the existing macro columns).
--
-- Methodology: Each item's micronutrient profile is derived from its key
-- ingredients (listed in the original 1584 migration notes) weighted by
-- approximate proportion in the finished dish per 100g.
--
-- Reference data (USDA / FoodData Central per 100g of raw ingredient):
--   Whole milk:          Ca 106, P 83,  Mg 10, K 150, Na 44, Fe 0.03, Zn 0.37, VitD 48IU, VitA 46ug, Se 2
--   Condensed milk:      Ca 284, P 200, Mg 26, K 371, Na 127, Fe 0.19, Zn 0.94, Chol 34, SatFat 5.5
--   Black sesame seeds:  Ca 975, P 629, Mg 351, K 468, Na 11, Fe 14.6, Zn 7.8, Se 34
--   Soybean powder:      Ca 190, P 400, Mg 230, K 1740, Na 3, Fe 12, Zn 3.5
--   Matcha powder:       Ca 450, P 350, Mg 230, K 2700, Fe 17, VitA 3050ug, Se 3
--   White bread:         Ca 144, P 98,  Mg 23, K 115, Na 490, Fe 3.6, Zn 0.7, Se 22, Chol 0
--   Butter:              Ca 24,  P 24,  Mg 2,  K 24,  Na 576, Fe 0.02, Chol 215, SatFat 50, VitA 684ug
--   Strawberry:          Ca 16,  P 24,  Mg 13, K 153, Na 1, Fe 0.41, VitC 58.8
--   Mango:               Ca 11,  P 14,  Mg 10, K 168, Na 1, Fe 0.16, VitA 54ug, VitC 36
--   Watermelon:          Ca 7,   P 11,  Mg 10, K 112, Na 1, Fe 0.24, VitA 28ug, VitC 8.1
--   Green grapes:        Ca 20,  P 20,  Mg 7,  K 191, Na 2, Fe 0.5,  VitC 10.8
--   Banana:              Ca 5,   P 22,  Mg 27, K 358, Na 1, Fe 0.3,  VitC 8.7
--   Taro:                Ca 43,  P 84,  Mg 33, K 591, Na 11, Fe 0.55, VitC 4.5
--   Sweet potato:        Ca 38,  P 54,  Mg 27, K 475, Na 36, Fe 0.69, VitA 709ug
--   Cocoa powder:        Ca 128, P 734, Mg 499, K 1524, Na 21, Fe 13.9, Zn 6.8
--   Dark chocolate:      Ca 73,  P 308, Mg 228, K 715, Na 20, Fe 12, Zn 3.3
--   Cream cheese:        Ca 98,  P 104, Mg 9,  K 138, Na 321, Chol 110, SatFat 20, VitA 362ug
--   Yogurt (whole):      Ca 121, P 95,  Mg 12, K 155, Na 46, Zn 0.6, VitD 2IU
--   Sweet corn:          Ca 3,   P 79,  Mg 28, K 233, Na 1, Fe 0.47, VitA 10ug
--   Coffee (brewed):     Ca 2,   P 3,   Mg 3,  K 49,  Na 2, Fe 0.01
--   Burdock root:        Ca 41,  P 51,  Mg 38, K 308, Na 5, Fe 0.8
--   Pomegranate:         Ca 10,  P 36,  Mg 12, K 236, Fe 0.3
--   Ginger root:         Ca 16,  P 34,  Mg 43, K 415, Na 13, Fe 0.6
--   Oreo cookies:        Ca 25,  P 50,  Mg 35, K 140, Na 370, Fe 4.1, SatFat 7.5

-- ══════════════════════════════════════════════════════════════
-- BINGSOO (Korean Shaved Milk Ice Desserts) — 19 items
-- ══════════════════════════════════════════════════════════════
-- Base for all bingsoo (per 100g of finished item):
--   ~55-65% shaved milk ice (diluted milk): Ca ~55, P ~40, K ~80, Na ~25, Mg ~5, VitD ~20IU
--   ~10-15% condensed milk: Ca ~35, P ~25, K ~45, Na ~16, Chol ~4
--   ~5-10% mochi/rice cake: Na ~5, Fe ~0.15
--   Remaining 15-30%: topping-specific ingredients

-- Milk Bingsoo: plain shaved milk ice + condensed milk + mochi (simplest)
UPDATE food_nutrition_overrides SET
  sodium_mg = 40, cholesterol_mg = 8, saturated_fat_g = 1.8, trans_fat_g = 0,
  potassium_mg = 110, calcium_mg = 85, iron_mg = 0.2,
  vitamin_a_ug = 20, vitamin_c_mg = 0, vitamin_d_iu = 18,
  magnesium_mg = 8, zinc_mg = 0.3, phosphorus_mg = 60, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_milk_bingsoo';

-- Injeolmi Bingsoo: milk ice + injeolmi rice cake + soybean powder + condensed milk
-- Soybean powder adds Ca, Fe, Mg, P, K
UPDATE food_nutrition_overrides SET
  sodium_mg = 45, cholesterol_mg = 9, saturated_fat_g = 2.2, trans_fat_g = 0,
  potassium_mg = 145, calcium_mg = 95, iron_mg = 0.6,
  vitamin_a_ug = 18, vitamin_c_mg = 0, vitamin_d_iu = 15,
  magnesium_mg = 18, zinc_mg = 0.4, phosphorus_mg = 75, selenium_ug = 1.8, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_injeolmi_bingsoo';

-- Injeolmi Bingsoo Combo: larger version with ice cream + more toppings
UPDATE food_nutrition_overrides SET
  sodium_mg = 55, cholesterol_mg = 14, saturated_fat_g = 3.2, trans_fat_g = 0,
  potassium_mg = 155, calcium_mg = 105, iron_mg = 0.7,
  vitamin_a_ug = 25, vitamin_c_mg = 0, vitamin_d_iu = 16,
  magnesium_mg = 20, zinc_mg = 0.5, phosphorus_mg = 82, selenium_ug = 2.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_injeolmi_bingsoo_combo';

-- Black Sesame Bingsoo: milk ice + black sesame powder + rice cakes + condensed milk
-- Black sesame adds significant Ca, Fe, Mg, Zn, P, Se
UPDATE food_nutrition_overrides SET
  sodium_mg = 42, cholesterol_mg = 9, saturated_fat_g = 2.5, trans_fat_g = 0,
  potassium_mg = 140, calcium_mg = 130, iron_mg = 1.2,
  vitamin_a_ug = 18, vitamin_c_mg = 0, vitamin_d_iu = 14,
  magnesium_mg = 32, zinc_mg = 0.8, phosphorus_mg = 95, selenium_ug = 3.0, omega3_g = 0.05
WHERE food_name_normalized = 'sul_and_beans_black_sesame_bingsoo';

-- Green Tea Bingsoo: milk ice + matcha + red bean + mochi + condensed milk
-- Matcha adds Fe, VitA, Mg, K
UPDATE food_nutrition_overrides SET
  sodium_mg = 42, cholesterol_mg = 9, saturated_fat_g = 2.0, trans_fat_g = 0,
  potassium_mg = 150, calcium_mg = 100, iron_mg = 0.6,
  vitamin_a_ug = 45, vitamin_c_mg = 0.5, vitamin_d_iu = 14,
  magnesium_mg = 18, zinc_mg = 0.4, phosphorus_mg = 72, selenium_ug = 1.8, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_green_tea_bingsoo';

-- Coffee Bingsoo: milk ice + espresso + condensed milk + mochi
-- Coffee adds K, Mg
UPDATE food_nutrition_overrides SET
  sodium_mg = 42, cholesterol_mg = 8, saturated_fat_g = 2.0, trans_fat_g = 0,
  potassium_mg = 130, calcium_mg = 85, iron_mg = 0.2,
  vitamin_a_ug = 18, vitamin_c_mg = 0, vitamin_d_iu = 14,
  magnesium_mg = 12, zinc_mg = 0.3, phosphorus_mg = 62, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_coffee_bingsoo';

-- Earl Grey Bingsoo: milk ice + earl grey tea + graham cracker + cream + berries
-- Graham cracker adds Na, Fe; berries add VitC
UPDATE food_nutrition_overrides SET
  sodium_mg = 55, cholesterol_mg = 10, saturated_fat_g = 2.0, trans_fat_g = 0,
  potassium_mg = 125, calcium_mg = 88, iron_mg = 0.4,
  vitamin_a_ug = 20, vitamin_c_mg = 3.0, vitamin_d_iu = 15,
  magnesium_mg = 10, zinc_mg = 0.3, phosphorus_mg = 65, selenium_ug = 2.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_earl_grey_bingsoo';

-- Fresh Strawberry Bingsoo: milk ice + fresh strawberries + condensed milk + mochi
-- Strawberries add significant VitC, K
UPDATE food_nutrition_overrides SET
  sodium_mg = 35, cholesterol_mg = 7, saturated_fat_g = 1.6, trans_fat_g = 0,
  potassium_mg = 140, calcium_mg = 80, iron_mg = 0.3,
  vitamin_a_ug = 16, vitamin_c_mg = 12.0, vitamin_d_iu = 14,
  magnesium_mg = 10, zinc_mg = 0.3, phosphorus_mg = 58, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_fresh_strawberry_bingsoo';

-- Fresh Mango Bingsoo: milk ice + fresh mango + condensed milk + mochi
-- Mango adds VitA, VitC, K
UPDATE food_nutrition_overrides SET
  sodium_mg = 35, cholesterol_mg = 7, saturated_fat_g = 1.7, trans_fat_g = 0,
  potassium_mg = 145, calcium_mg = 78, iron_mg = 0.2,
  vitamin_a_ug = 35, vitamin_c_mg = 8.0, vitamin_d_iu = 13,
  magnesium_mg = 10, zinc_mg = 0.3, phosphorus_mg = 55, selenium_ug = 1.3, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_fresh_mango_bingsoo';

-- Strawberry Cheese Bingsoo: milk ice + strawberries + cream cheese + condensed milk
-- Cream cheese adds Na, Chol, SatFat, VitA, Ca, P
UPDATE food_nutrition_overrides SET
  sodium_mg = 60, cholesterol_mg = 16, saturated_fat_g = 2.8, trans_fat_g = 0,
  potassium_mg = 135, calcium_mg = 95, iron_mg = 0.3,
  vitamin_a_ug = 35, vitamin_c_mg = 8.0, vitamin_d_iu = 14,
  magnesium_mg = 10, zinc_mg = 0.4, phosphorus_mg = 70, selenium_ug = 1.6, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_strawberry_cheese_bingsoo';

-- Yogurt Berry Bingsoo: milk ice + yogurt + mixed berries + condensed milk
-- Yogurt adds Ca, P, K, Zn; berries add VitC
UPDATE food_nutrition_overrides SET
  sodium_mg = 42, cholesterol_mg = 8, saturated_fat_g = 1.5, trans_fat_g = 0,
  potassium_mg = 140, calcium_mg = 95, iron_mg = 0.3,
  vitamin_a_ug = 18, vitamin_c_mg = 10.0, vitamin_d_iu = 14,
  magnesium_mg = 11, zinc_mg = 0.4, phosphorus_mg = 68, selenium_ug = 1.5, omega3_g = 0.02
WHERE food_name_normalized = 'sul_and_beans_yogurt_berry_bingsoo';

-- Green Grape Bingsoo: milk ice + fresh green grapes + condensed milk + mochi
-- Grapes add K, VitC (modest)
UPDATE food_nutrition_overrides SET
  sodium_mg = 36, cholesterol_mg = 6, saturated_fat_g = 1.3, trans_fat_g = 0,
  potassium_mg = 140, calcium_mg = 80, iron_mg = 0.3,
  vitamin_a_ug = 15, vitamin_c_mg = 3.0, vitamin_d_iu = 13,
  magnesium_mg = 8, zinc_mg = 0.3, phosphorus_mg = 55, selenium_ug = 1.3, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_green_grape_bingsoo';

-- Watermelon Bingsoo: milk ice + fresh watermelon + condensed milk
-- Watermelon adds VitA, VitC (modest), K
UPDATE food_nutrition_overrides SET
  sodium_mg = 34, cholesterol_mg = 6, saturated_fat_g = 1.3, trans_fat_g = 0,
  potassium_mg = 120, calcium_mg = 72, iron_mg = 0.2,
  vitamin_a_ug = 22, vitamin_c_mg = 3.0, vitamin_d_iu = 12,
  magnesium_mg = 9, zinc_mg = 0.3, phosphorus_mg = 50, selenium_ug = 1.2, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_watermelon_bingsoo';

-- Oreo Bingsoo: milk ice + crushed Oreos + chocolate drizzle + condensed milk + ice cream
-- Oreos add Na, Fe; chocolate adds Fe, Mg; ice cream adds Ca, Chol
UPDATE food_nutrition_overrides SET
  sodium_mg = 75, cholesterol_mg = 14, saturated_fat_g = 3.0, trans_fat_g = 0.1,
  potassium_mg = 130, calcium_mg = 88, iron_mg = 0.6,
  vitamin_a_ug = 22, vitamin_c_mg = 0, vitamin_d_iu = 14,
  magnesium_mg = 16, zinc_mg = 0.4, phosphorus_mg = 68, selenium_ug = 2.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_oreo_bingsoo';

-- Chocolate Bingsoo: milk ice + chocolate sauce + cocoa + condensed milk + chocolate ice cream
-- Chocolate/cocoa adds Fe, Mg, P, K, Zn
UPDATE food_nutrition_overrides SET
  sodium_mg = 50, cholesterol_mg = 12, saturated_fat_g = 2.8, trans_fat_g = 0,
  potassium_mg = 155, calcium_mg = 92, iron_mg = 0.7,
  vitamin_a_ug = 20, vitamin_c_mg = 0, vitamin_d_iu = 13,
  magnesium_mg = 22, zinc_mg = 0.5, phosphorus_mg = 78, selenium_ug = 2.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_chocolate_bingsoo';

-- Chocolate Banana Bingsoo: milk ice + chocolate + banana + condensed milk + ice cream
-- Banana adds K, Mg; chocolate adds Fe, Mg
UPDATE food_nutrition_overrides SET
  sodium_mg = 48, cholesterol_mg = 11, saturated_fat_g = 2.6, trans_fat_g = 0,
  potassium_mg = 170, calcium_mg = 85, iron_mg = 0.6,
  vitamin_a_ug = 18, vitamin_c_mg = 2.5, vitamin_d_iu = 12,
  magnesium_mg = 22, zinc_mg = 0.4, phosphorus_mg = 72, selenium_ug = 1.8, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_chocolate_banana_bingsoo';

-- Sweet Corn Bingsoo: milk ice + sweet corn + condensed milk + cheese
-- Corn adds K, Mg, P; cheese adds Na, Ca, P, Chol
UPDATE food_nutrition_overrides SET
  sodium_mg = 55, cholesterol_mg = 10, saturated_fat_g = 1.6, trans_fat_g = 0,
  potassium_mg = 140, calcium_mg = 90, iron_mg = 0.3,
  vitamin_a_ug = 16, vitamin_c_mg = 1.5, vitamin_d_iu = 14,
  magnesium_mg = 14, zinc_mg = 0.4, phosphorus_mg = 72, selenium_ug = 1.6, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_sweet_corn_bingsoo';

-- Banana Milk Bingsoo: milk ice + banana + condensed milk + mochi
-- Banana adds K, Mg, VitC (modest)
UPDATE food_nutrition_overrides SET
  sodium_mg = 38, cholesterol_mg = 8, saturated_fat_g = 1.8, trans_fat_g = 0,
  potassium_mg = 150, calcium_mg = 82, iron_mg = 0.2,
  vitamin_a_ug = 16, vitamin_c_mg = 2.5, vitamin_d_iu = 14,
  magnesium_mg = 14, zinc_mg = 0.3, phosphorus_mg = 58, selenium_ug = 1.4, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_banana_milk_bingsoo';

-- Taro Bingsoo: milk ice + taro paste/powder + condensed milk + mochi
-- Taro adds K (high), Mg, P, Ca, Fe
UPDATE food_nutrition_overrides SET
  sodium_mg = 42, cholesterol_mg = 8, saturated_fat_g = 2.0, trans_fat_g = 0,
  potassium_mg = 160, calcium_mg = 88, iron_mg = 0.3,
  vitamin_a_ug = 18, vitamin_c_mg = 1.5, vitamin_d_iu = 13,
  magnesium_mg = 16, zinc_mg = 0.3, phosphorus_mg = 68, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_taro_bingsoo';


-- ══════════════════════════════════════════════════════════════
-- TOAST (Korean Thick Toast) — 8 items
-- ══════════════════════════════════════════════════════════════
-- Base for all toast (per 100g of finished item):
--   ~50-60% thick white bread: Ca ~80, P ~55, Mg ~13, K ~65, Na ~275, Fe ~2.0, Se ~12, Zn ~0.4
--   ~10-15% butter: Na ~70, Chol ~25, SatFat ~6.0, VitA ~80ug
--   Remaining 25-35%: filling-specific ingredients

-- Injeolmi Toast: thick bread + butter + injeolmi rice cake + soybean powder + honey
-- Soybean powder adds Ca, Fe, Mg, P
UPDATE food_nutrition_overrides SET
  sodium_mg = 290, cholesterol_mg = 20, saturated_fat_g = 3.5, trans_fat_g = 0,
  potassium_mg = 120, calcium_mg = 85, iron_mg = 1.6,
  vitamin_a_ug = 55, vitamin_c_mg = 0, vitamin_d_iu = 4,
  magnesium_mg = 22, zinc_mg = 0.5, phosphorus_mg = 72, selenium_ug = 10.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_injeolmi_toast';

-- Cheese Injeolmi Toast: injeolmi toast + melted cheese
-- Cheese adds Na, Ca, P, Chol, SatFat
UPDATE food_nutrition_overrides SET
  sodium_mg = 340, cholesterol_mg = 28, saturated_fat_g = 4.8, trans_fat_g = 0,
  potassium_mg = 115, calcium_mg = 120, iron_mg = 1.5,
  vitamin_a_ug = 65, vitamin_c_mg = 0, vitamin_d_iu = 5,
  magnesium_mg = 20, zinc_mg = 0.7, phosphorus_mg = 95, selenium_ug = 10.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cheese_injeolmi_toast';

-- Sweet Corn Toast: thick bread + butter + sweet corn + mayo + cheese
-- Corn adds K, P, Mg; mayo adds Na, Chol; cheese adds Ca, Na
UPDATE food_nutrition_overrides SET
  sodium_mg = 360, cholesterol_mg = 25, saturated_fat_g = 3.8, trans_fat_g = 0,
  potassium_mg = 125, calcium_mg = 95, iron_mg = 1.4,
  vitamin_a_ug = 55, vitamin_c_mg = 1.0, vitamin_d_iu = 4,
  magnesium_mg = 18, zinc_mg = 0.6, phosphorus_mg = 82, selenium_ug = 10.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_sweet_corn_toast';

-- Black Sesame Toast: thick bread + butter + black sesame spread
-- Black sesame adds significant Ca, Fe, Mg, Zn, P, Se
UPDATE food_nutrition_overrides SET
  sodium_mg = 300, cholesterol_mg = 22, saturated_fat_g = 4.2, trans_fat_g = 0,
  potassium_mg = 130, calcium_mg = 140, iron_mg = 2.5,
  vitamin_a_ug = 60, vitamin_c_mg = 0, vitamin_d_iu = 4,
  magnesium_mg = 38, zinc_mg = 1.0, phosphorus_mg = 105, selenium_ug = 12.0, omega3_g = 0.03
WHERE food_name_normalized = 'sul_and_beans_black_sesame_toast';

-- Choux Cream Toast: thick bread + butter + choux pastry cream (eggs, cream, sugar)
-- Custard/cream adds Chol, VitA, Ca, P
UPDATE food_nutrition_overrides SET
  sodium_mg = 280, cholesterol_mg = 35, saturated_fat_g = 4.5, trans_fat_g = 0,
  potassium_mg = 100, calcium_mg = 82, iron_mg = 1.3,
  vitamin_a_ug = 75, vitamin_c_mg = 0, vitamin_d_iu = 8,
  magnesium_mg = 12, zinc_mg = 0.5, phosphorus_mg = 75, selenium_ug = 11.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_choux_cream_toast';

-- Sweet Potato Toast: thick bread + butter + sweet potato filling
-- Sweet potato adds VitA (high), K, Ca, Mg, Fe
UPDATE food_nutrition_overrides SET
  sodium_mg = 275, cholesterol_mg = 20, saturated_fat_g = 3.2, trans_fat_g = 0,
  potassium_mg = 155, calcium_mg = 82, iron_mg = 1.5,
  vitamin_a_ug = 160, vitamin_c_mg = 1.5, vitamin_d_iu = 4,
  magnesium_mg = 18, zinc_mg = 0.5, phosphorus_mg = 68, selenium_ug = 9.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_sweet_potato_toast';

-- Cinnamon Toast: thick bread + butter + cinnamon sugar
-- Cinnamon adds small amounts of Ca, Fe, Mg, Mn (negligible at used amounts)
UPDATE food_nutrition_overrides SET
  sodium_mg = 285, cholesterol_mg = 22, saturated_fat_g = 3.8, trans_fat_g = 0,
  potassium_mg = 95, calcium_mg = 78, iron_mg = 1.3,
  vitamin_a_ug = 60, vitamin_c_mg = 0, vitamin_d_iu = 3,
  magnesium_mg = 12, zinc_mg = 0.4, phosphorus_mg = 55, selenium_ug = 10.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cinnamon_toast';

-- Green Tea Toast: thick bread + butter + matcha green tea spread + cream
-- Matcha adds Fe, VitA, Mg, K
UPDATE food_nutrition_overrides SET
  sodium_mg = 280, cholesterol_mg = 22, saturated_fat_g = 3.5, trans_fat_g = 0,
  potassium_mg = 115, calcium_mg = 85, iron_mg = 1.5,
  vitamin_a_ug = 80, vitamin_c_mg = 0, vitamin_d_iu = 4,
  magnesium_mg = 18, zinc_mg = 0.5, phosphorus_mg = 68, selenium_ug = 10.0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_green_tea_toast';


-- ══════════════════════════════════════════════════════════════
-- DRINKS — 16 items
-- ══════════════════════════════════════════════════════════════

-- Americano: espresso + hot water (mostly water, very dilute)
UPDATE food_nutrition_overrides SET
  sodium_mg = 2, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 49, calcium_mg = 2, iron_mg = 0,
  vitamin_a_ug = 0, vitamin_c_mg = 0, vitamin_d_iu = 0,
  magnesium_mg = 3, zinc_mg = 0, phosphorus_mg = 3, selenium_ug = 0, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_americano';

-- Cafe Latte: espresso + steamed milk (mostly milk, ~80%+ milk)
UPDATE food_nutrition_overrides SET
  sodium_mg = 38, cholesterol_mg = 6, saturated_fat_g = 1.2, trans_fat_g = 0,
  potassium_mg = 130, calcium_mg = 88, iron_mg = 0.05,
  vitamin_a_ug = 32, vitamin_c_mg = 0, vitamin_d_iu = 35,
  magnesium_mg = 9, zinc_mg = 0.3, phosphorus_mg = 68, selenium_ug = 1.8, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cafe_latte';

-- Cappuccino: espresso + steamed milk + foam (less milk than latte, ~65% milk)
UPDATE food_nutrition_overrides SET
  sodium_mg = 32, cholesterol_mg = 5, saturated_fat_g = 1.1, trans_fat_g = 0,
  potassium_mg = 115, calcium_mg = 72, iron_mg = 0.04,
  vitamin_a_ug = 28, vitamin_c_mg = 0, vitamin_d_iu = 28,
  magnesium_mg = 8, zinc_mg = 0.25, phosphorus_mg = 58, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cappuccino';

-- Matcha Latte: matcha powder + steamed milk
-- Matcha adds VitA, Fe, Mg, K (small amount of powder but concentrated nutrients)
UPDATE food_nutrition_overrides SET
  sodium_mg = 35, cholesterol_mg = 5, saturated_fat_g = 1.0, trans_fat_g = 0,
  potassium_mg = 140, calcium_mg = 90, iron_mg = 0.2,
  vitamin_a_ug = 38, vitamin_c_mg = 0, vitamin_d_iu = 30,
  magnesium_mg = 12, zinc_mg = 0.3, phosphorus_mg = 68, selenium_ug = 1.6, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_matcha_latte';

-- Sweet Potato Latte: sweet potato puree + steamed milk
-- Sweet potato adds VitA (high), K
UPDATE food_nutrition_overrides SET
  sodium_mg = 40, cholesterol_mg = 5, saturated_fat_g = 1.0, trans_fat_g = 0,
  potassium_mg = 155, calcium_mg = 80, iron_mg = 0.15,
  vitamin_a_ug = 120, vitamin_c_mg = 1.0, vitamin_d_iu = 28,
  magnesium_mg = 12, zinc_mg = 0.3, phosphorus_mg = 60, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_sweet_potato_latte';

-- Mixed Grain Drink: misugaru (multigrain powder) + milk
-- Misugaru adds Ca, Fe, Mg, P, K, Zn (multiple grains concentrate minerals)
UPDATE food_nutrition_overrides SET
  sodium_mg = 38, cholesterol_mg = 5, saturated_fat_g = 0.9, trans_fat_g = 0,
  potassium_mg = 150, calcium_mg = 85, iron_mg = 0.5,
  vitamin_a_ug = 22, vitamin_c_mg = 0, vitamin_d_iu = 25,
  magnesium_mg = 18, zinc_mg = 0.5, phosphorus_mg = 78, selenium_ug = 2.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_mixed_grain_drink';

-- Cream Top Americano: americano + cream cheese foam topping
-- Cream cheese foam adds Na, Chol, SatFat, VitA, Ca
UPDATE food_nutrition_overrides SET
  sodium_mg = 28, cholesterol_mg = 8, saturated_fat_g = 1.5, trans_fat_g = 0,
  potassium_mg = 55, calcium_mg = 12, iron_mg = 0.02,
  vitamin_a_ug = 20, vitamin_c_mg = 0, vitamin_d_iu = 2,
  magnesium_mg = 3, zinc_mg = 0.1, phosphorus_mg = 10, selenium_ug = 0.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cream_top_americano';

-- Cream Top Matcha: matcha latte + cream cheese foam
-- Combines matcha latte nutrients + cream cheese foam
UPDATE food_nutrition_overrides SET
  sodium_mg = 42, cholesterol_mg = 10, saturated_fat_g = 1.8, trans_fat_g = 0,
  potassium_mg = 135, calcium_mg = 82, iron_mg = 0.15,
  vitamin_a_ug = 40, vitamin_c_mg = 0, vitamin_d_iu = 25,
  magnesium_mg = 11, zinc_mg = 0.3, phosphorus_mg = 60, selenium_ug = 1.5, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cream_top_matcha';

-- Cream Top Matcha Strawberry: matcha + strawberry puree + cream cheese foam
-- Adds VitC from strawberry
UPDATE food_nutrition_overrides SET
  sodium_mg = 40, cholesterol_mg = 9, saturated_fat_g = 1.8, trans_fat_g = 0,
  potassium_mg = 138, calcium_mg = 78, iron_mg = 0.15,
  vitamin_a_ug = 35, vitamin_c_mg = 5.0, vitamin_d_iu = 22,
  magnesium_mg = 10, zinc_mg = 0.3, phosphorus_mg = 58, selenium_ug = 1.4, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_cream_top_matcha_strawberry';

-- Sweet Rice Punch (Sikhye): fermented malt barley + cooked rice + sugar + water
-- Mostly water/sugar, small mineral content from rice/malt
UPDATE food_nutrition_overrides SET
  sodium_mg = 12, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 25, calcium_mg = 8, iron_mg = 0.15,
  vitamin_a_ug = 0, vitamin_c_mg = 0, vitamin_d_iu = 0,
  magnesium_mg = 5, zinc_mg = 0.1, phosphorus_mg = 12, selenium_ug = 0.8, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_sweet_rice_punch';

-- Burdock Tea: roasted burdock root steeped in water (very dilute)
-- Burdock root is mineral-rich but tea is very dilute (~3 cal/100g)
UPDATE food_nutrition_overrides SET
  sodium_mg = 2, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 18, calcium_mg = 3, iron_mg = 0.05,
  vitamin_a_ug = 0, vitamin_c_mg = 0, vitamin_d_iu = 0,
  magnesium_mg = 2, zinc_mg = 0.02, phosphorus_mg = 3, selenium_ug = 0.2, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_burdock_tea';

-- Strawberry Citron Tea: strawberry + yuzu citron preserve + hot water/ice
-- Fruit preserves provide VitC, K
UPDATE food_nutrition_overrides SET
  sodium_mg = 5, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 30, calcium_mg = 5, iron_mg = 0.08,
  vitamin_a_ug = 1, vitamin_c_mg = 8.0, vitamin_d_iu = 0,
  magnesium_mg = 3, zinc_mg = 0.03, phosphorus_mg = 5, selenium_ug = 0.2, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_strawberry_citron_tea';

-- Honey Orange Lemon & Grapefruit Tea: citrus fruit + honey + hot water
-- Citrus provides VitC (highest of the fruit teas), K
UPDATE food_nutrition_overrides SET
  sodium_mg = 4, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 35, calcium_mg = 6, iron_mg = 0.06,
  vitamin_a_ug = 2, vitamin_c_mg = 12.0, vitamin_d_iu = 0,
  magnesium_mg = 3, zinc_mg = 0.03, phosphorus_mg = 5, selenium_ug = 0.2, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_honey_orange_lemon_grapefruit_tea';

-- Pomegranate Mint Tea: pomegranate + fresh mint + hot water
-- Pomegranate adds K, Fe; mint adds small VitA
UPDATE food_nutrition_overrides SET
  sodium_mg = 3, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 28, calcium_mg = 4, iron_mg = 0.06,
  vitamin_a_ug = 2, vitamin_c_mg = 4.0, vitamin_d_iu = 0,
  magnesium_mg = 3, zinc_mg = 0.02, phosphorus_mg = 5, selenium_ug = 0.2, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_pomegranate_mint_tea';

-- Honey Lemon Tea: honey + lemon + hot water
-- Lemon adds VitC; honey adds small K
UPDATE food_nutrition_overrides SET
  sodium_mg = 3, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 22, calcium_mg = 3, iron_mg = 0.05,
  vitamin_a_ug = 0, vitamin_c_mg = 6.0, vitamin_d_iu = 0,
  magnesium_mg = 2, zinc_mg = 0.02, phosphorus_mg = 3, selenium_ug = 0.1, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_honey_lemon_tea';

-- Honey Ginger Tea: honey + ginger + hot water
-- Ginger adds K, Mg (ginger root is mineral-dense but small amount used)
UPDATE food_nutrition_overrides SET
  sodium_mg = 3, cholesterol_mg = 0, saturated_fat_g = 0, trans_fat_g = 0,
  potassium_mg = 25, calcium_mg = 3, iron_mg = 0.05,
  vitamin_a_ug = 0, vitamin_c_mg = 1.0, vitamin_d_iu = 0,
  magnesium_mg = 4, zinc_mg = 0.02, phosphorus_mg = 4, selenium_ug = 0.2, omega3_g = 0
WHERE food_name_normalized = 'sul_and_beans_honey_ginger_tea';
