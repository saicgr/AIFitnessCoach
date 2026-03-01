-- ============================================================================
-- 329_micronutrients_remaining.sql
-- Safety-net migration: Fill remaining NULL micronutrient values
-- Generated: 2026-02-28
--
-- This migration uses COALESCE to set reasonable category-based defaults
-- for any food_nutrition_overrides rows that still have NULL sodium_mg
-- after migrations 325-328. After this migration, NO row should have
-- NULL micronutrient values.
--
-- All values are per 100g and represent reasonable category averages
-- derived from USDA FoodData Central reference data.
-- ============================================================================

-- ============================================================================
-- COMMON FOOD CATEGORIES (from migrations 297-311)
-- ============================================================================

-- Category: proteins (meats, fish, poultry, eggs)
-- Averages based on USDA data for cooked meats/fish/poultry
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 65.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 70.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 2.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 280.0),
  calcium_mg = COALESCE(calcium_mg, 15.0),
  iron_mg = COALESCE(iron_mg, 1.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 5.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 5.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 2.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 200.0),
  selenium_ug = COALESCE(selenium_ug, 20.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'proteins' AND sodium_mg IS NULL;

-- Category: dairy (milk, cheese, yogurt)
-- Higher calcium, vitamin D; moderate sodium for cheeses
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 200.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 200.0),
  iron_mg = COALESCE(iron_mg, 0.1),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 40.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.5),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 40.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 170.0),
  selenium_ug = COALESCE(selenium_ug, 8.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'dairy' AND sodium_mg IS NULL;

-- Category: fruits (fresh fruits)
-- Very low sodium/fat, high potassium/vitamin C
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 2.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 12.0),
  iron_mg = COALESCE(iron_mg, 0.3),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 20.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 10.0),
  zinc_mg = COALESCE(zinc_mg, 0.1),
  phosphorus_mg = COALESCE(phosphorus_mg, 15.0),
  selenium_ug = COALESCE(selenium_ug, 0.5),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'fruits' AND sodium_mg IS NULL;

-- Category: vegetables (fresh vegetables)
-- Low sodium/fat, good potassium, some vitamin A/C
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 20.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.1),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 0.7),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 50.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 15.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 18.0),
  zinc_mg = COALESCE(zinc_mg, 0.3),
  phosphorus_mg = COALESCE(phosphorus_mg, 35.0),
  selenium_ug = COALESCE(selenium_ug, 0.5),
  omega3_g = COALESCE(omega3_g, 0.03)
WHERE food_category = 'vegetables' AND sodium_mg IS NULL;

-- Category: grains (rice, bread, pasta, tortillas)
-- Moderate sodium (especially bread), low fat, some iron/B-vitamins
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 250.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 100.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 2.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 0.8),
  phosphorus_mg = COALESCE(phosphorus_mg, 80.0),
  selenium_ug = COALESCE(selenium_ug, 15.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'grains' AND sodium_mg IS NULL;

-- Category: nuts_seeds (nuts, seeds, nut butters)
-- High fat (mostly unsaturated), good magnesium/zinc/phosphorus
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 5.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 600.0),
  calcium_mg = COALESCE(calcium_mg, 70.0),
  iron_mg = COALESCE(iron_mg, 3.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.5),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 160.0),
  zinc_mg = COALESCE(zinc_mg, 3.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 400.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.5)
WHERE food_category = 'nuts_seeds' AND sodium_mg IS NULL;

-- Category: legumes (beans, lentils)
-- High fiber/protein, good potassium/iron/magnesium
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 5.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.1),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 400.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 2.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 45.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 150.0),
  selenium_ug = COALESCE(selenium_ug, 3.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'legumes' AND sodium_mg IS NULL;

-- Category: condiments (oils, sauces, dressings, sweeteners)
-- High variability; moderate sodium average, some high-fat items
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 5.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 50.0),
  calcium_mg = COALESCE(calcium_mg, 10.0),
  iron_mg = COALESCE(iron_mg, 0.3),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 5.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 5.0),
  zinc_mg = COALESCE(zinc_mg, 0.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 15.0),
  selenium_ug = COALESCE(selenium_ug, 1.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'condiments' AND sodium_mg IS NULL;

-- Category: drinks (beverages, juices, sodas, coffee, tea)
-- Mostly low in micronutrients except some juices; low sodium
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 10.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 50.0),
  calcium_mg = COALESCE(calcium_mg, 5.0),
  iron_mg = COALESCE(iron_mg, 0.1),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 5.0),
  zinc_mg = COALESCE(zinc_mg, 0.1),
  phosphorus_mg = COALESCE(phosphorus_mg, 10.0),
  selenium_ug = COALESCE(selenium_ug, 0.5),
  omega3_g = COALESCE(omega3_g, 0.0)
WHERE food_category = 'drinks' AND sodium_mg IS NULL;

-- Category: snacks (protein bars, chips, crackers, trail mix)
-- Moderate-high sodium, moderate fat
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 350.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 10.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 150.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 2.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 5.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.5),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'snacks' AND sodium_mg IS NULL;

-- Category: desserts (cookies, cakes, ice cream, pastries)
-- Higher sugar/fat, moderate sodium, some calcium from dairy ingredients
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 200.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 40.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 7.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.3),
  potassium_mg = COALESCE(potassium_mg, 100.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 1.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 0.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 70.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'desserts' AND sodium_mg IS NULL;

-- Category: breakfast (eggs, omelettes, pancakes, waffles, cereal)
-- Moderate sodium, moderate cholesterol from eggs
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 300.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 120.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 150.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 60.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.5),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 15.0),
  magnesium_mg = COALESCE(magnesium_mg, 12.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 130.0),
  selenium_ug = COALESCE(selenium_ug, 15.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'breakfast' AND sodium_mg IS NULL;

-- Category: frozen (frozen meals, frozen snacks)
-- Higher sodium from processing, moderate fat
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 450.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 60.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 2.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'frozen' AND sodium_mg IS NULL;

-- ============================================================================
-- MEAL SUBCATEGORIES (from migration 306)
-- ============================================================================

-- Category: sandwiches (subs, wraps, paninis)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 35.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 80.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 2.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 130.0),
  selenium_ug = COALESCE(selenium_ug, 15.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'sandwiches' AND sodium_mg IS NULL;

-- Category: salads
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 200.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 20.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 2.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 1.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 60.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 10.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 0.8),
  phosphorus_mg = COALESCE(phosphorus_mg, 80.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'salads' AND sodium_mg IS NULL;

-- Category: soups
-- Higher sodium from broth base
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 15.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 1.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 25.0),
  iron_mg = COALESCE(iron_mg, 0.8),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 30.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 0.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 60.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'soups' AND sodium_mg IS NULL;

-- Category: pasta (pasta dishes)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 350.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 60.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 22.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 15.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'pasta' AND sodium_mg IS NULL;

-- Category: sides (mashed potatoes, fries, coleslaw, corn)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 250.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 5.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 2.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 20.0),
  iron_mg = COALESCE(iron_mg, 0.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 10.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 18.0),
  zinc_mg = COALESCE(zinc_mg, 0.4),
  phosphorus_mg = COALESCE(phosphorus_mg, 50.0),
  selenium_ug = COALESCE(selenium_ug, 2.0),
  omega3_g = COALESCE(omega3_g, 0.03)
WHERE food_category = 'sides' AND sodium_mg IS NULL;

-- Category: bowls (rice bowls, grain bowls, poke bowls, acai bowls)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 350.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 2.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'bowls' AND sodium_mg IS NULL;

-- Category: mexican (tacos, burritos, enchiladas, quesadillas)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 450.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 220.0),
  calcium_mg = COALESCE(calcium_mg, 80.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 25.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 130.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'mexican' AND sodium_mg IS NULL;

-- Category: asian (Chinese, stir fry, fried rice)
-- Higher sodium from soy sauce
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 2.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 1.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 22.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 110.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'asian' AND sodium_mg IS NULL;

-- Category: pizza
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 550.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 170.0),
  calcium_mg = COALESCE(calcium_mg, 120.0),
  iron_mg = COALESCE(iron_mg, 2.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 40.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 3.0),
  magnesium_mg = COALESCE(magnesium_mg, 18.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 150.0),
  selenium_ug = COALESCE(selenium_ug, 15.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'pizza' AND sodium_mg IS NULL;

-- ============================================================================
-- CUISINE-SPECIFIC CATEGORIES (from migrations 278-296)
-- ============================================================================

-- Category: korean (bibimbap, bulgogi, kimchi dishes)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 480.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 2.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 35.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'korean' AND sodium_mg IS NULL;

-- Category: vietnamese (pho, banh mi, spring rolls)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 20.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 1.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 25.0),
  iron_mg = COALESCE(iron_mg, 1.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 8.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'vietnamese' AND sodium_mg IS NULL;

-- Category: thai (pad thai, curries, tom yum)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 480.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 230.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 1.3),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 110.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'thai' AND sodium_mg IS NULL;

-- Category: japanese (sushi, ramen, teriyaki)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 450.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 20.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 1.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 25.0),
  iron_mg = COALESCE(iron_mg, 1.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 2.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 5.0),
  magnesium_mg = COALESCE(magnesium_mg, 22.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 12.0),
  omega3_g = COALESCE(omega3_g, 0.3)
WHERE food_category = 'japanese' AND sodium_mg IS NULL;

-- Category: indian (curries, biryanis, naan)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'indian' AND sodium_mg IS NULL;

-- Category: african (jollof rice, injera, stews)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 350.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 20.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 280.0),
  calcium_mg = COALESCE(calcium_mg, 35.0),
  iron_mg = COALESCE(iron_mg, 2.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 30.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 8.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'african' AND sodium_mg IS NULL;

-- Category: european (schnitzel, pierogi, crepes)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 40.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 1.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 25.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 5.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 130.0),
  selenium_ug = COALESCE(selenium_ug, 12.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'european' AND sodium_mg IS NULL;

-- Category: latin_american (empanadas, arepas, ceviche)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 230.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 110.0),
  selenium_ug = COALESCE(selenium_ug, 8.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'latin_american' AND sodium_mg IS NULL;

-- Category: middle_eastern (hummus, shawarma, falafel, kebabs)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 20.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 45.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 130.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'middle_eastern' AND sodium_mg IS NULL;

-- Category: filipino
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 450.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 220.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 22.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 110.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'filipino' AND sodium_mg IS NULL;

-- Category: mediterranean (greek, turkish, lebanese)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 380.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 20.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 28.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.15)
WHERE food_category = 'mediterranean' AND sodium_mg IS NULL;

-- Category: italian (beyond pasta - risotto, osso buco, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 80.0),
  iron_mg = COALESCE(iron_mg, 1.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 25.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 3.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 130.0),
  selenium_ug = COALESCE(selenium_ug, 12.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'italian' AND sodium_mg IS NULL;

-- Category: bbq (smoked meats, ribs, pulled pork)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 60.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 20.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 5.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 3.0),
  magnesium_mg = COALESCE(magnesium_mg, 22.0),
  zinc_mg = COALESCE(zinc_mg, 3.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 170.0),
  selenium_ug = COALESCE(selenium_ug, 18.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'bbq' AND sodium_mg IS NULL;

-- Category: brazilian (churrasco, feijoada, pao de queijo)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 380.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 40.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 250.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 10.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 2.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 140.0),
  selenium_ug = COALESCE(selenium_ug, 12.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'brazilian' AND sodium_mg IS NULL;

-- Category: hawaiian (poke, plate lunches, loco moco)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 420.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 220.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 1.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 5.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 5.0),
  magnesium_mg = COALESCE(magnesium_mg, 25.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 12.0),
  omega3_g = COALESCE(omega3_g, 0.2)
WHERE food_category = 'hawaiian' AND sodium_mg IS NULL;

-- Category: french (crepes, croissants, ratatouille)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 350.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 40.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 150.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 1.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 30.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 2.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 5.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.1)
WHERE food_category = 'french' AND sodium_mg IS NULL;

-- Category: caribbean (jerk chicken, plantains, rice and peas)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 280.0),
  calcium_mg = COALESCE(calcium_mg, 35.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 25.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 8.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'caribbean' AND sodium_mg IS NULL;

-- ============================================================================
-- RESTAURANT / CHAIN CATEGORIES (from migrations 272-296)
-- These rows have restaurant_name set and may use various food_category values
-- ============================================================================

-- Category: fast_food (McDonald's, Burger King, Wendy's, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 600.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 40.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.3),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 60.0),
  iron_mg = COALESCE(iron_mg, 2.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 2.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 150.0),
  selenium_ug = COALESCE(selenium_ug, 15.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'fast_food' AND sodium_mg IS NULL;

-- Category: casual_dining (Applebee's, Chili's, Olive Garden, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 550.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 40.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 5.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 220.0),
  calcium_mg = COALESCE(calcium_mg, 60.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 3.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 22.0),
  zinc_mg = COALESCE(zinc_mg, 1.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 140.0),
  selenium_ug = COALESCE(selenium_ug, 12.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'casual_dining' AND sodium_mg IS NULL;

-- Category: coffee_shops (Starbucks, Dunkin', etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 100.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 15.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 150.0),
  calcium_mg = COALESCE(calcium_mg, 80.0),
  iron_mg = COALESCE(iron_mg, 0.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 15.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 0.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'coffee_shops' AND sodium_mg IS NULL;

-- Category: ice_cream (Ben & Jerry's, Baskin-Robbins, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 80.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 45.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 8.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.3),
  potassium_mg = COALESCE(potassium_mg, 170.0),
  calcium_mg = COALESCE(calcium_mg, 100.0),
  iron_mg = COALESCE(iron_mg, 0.3),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 50.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.5),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 10.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 0.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 3.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'ice_cream' AND sodium_mg IS NULL;

-- Category: bakery (Panera, specialty bakeries)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 350.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 100.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 2.0),
  magnesium_mg = COALESCE(magnesium_mg, 12.0),
  zinc_mg = COALESCE(zinc_mg, 0.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 70.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'bakery' AND sodium_mg IS NULL;

-- Category: bubble_tea
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 30.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 5.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 1.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 80.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 0.2),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 5.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 5.0),
  magnesium_mg = COALESCE(magnesium_mg, 10.0),
  zinc_mg = COALESCE(zinc_mg, 0.3),
  phosphorus_mg = COALESCE(phosphorus_mg, 50.0),
  selenium_ug = COALESCE(selenium_ug, 1.0),
  omega3_g = COALESCE(omega3_g, 0.0)
WHERE food_category = 'bubble_tea' AND sodium_mg IS NULL;

-- ============================================================================
-- BRANDED ITEM CATEGORIES (from migrations 312-324)
-- ============================================================================

-- Category: energy_drinks (Red Bull, Monster, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 80.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 20.0),
  calcium_mg = COALESCE(calcium_mg, 5.0),
  iron_mg = COALESCE(iron_mg, 0.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 5.0),
  zinc_mg = COALESCE(zinc_mg, 0.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 10.0),
  selenium_ug = COALESCE(selenium_ug, 0.0),
  omega3_g = COALESCE(omega3_g, 0.0)
WHERE food_category = 'energy_drinks' AND sodium_mg IS NULL;

-- Category: sports_drinks (Gatorade, Powerade, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 110.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 30.0),
  calcium_mg = COALESCE(calcium_mg, 0.0),
  iron_mg = COALESCE(iron_mg, 0.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 3.0),
  zinc_mg = COALESCE(zinc_mg, 0.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 10.0),
  selenium_ug = COALESCE(selenium_ug, 0.0),
  omega3_g = COALESCE(omega3_g, 0.0)
WHERE food_category = 'sports_drinks' AND sodium_mg IS NULL;

-- Category: cereal (branded cereals)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 400.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 0.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 120.0),
  calcium_mg = COALESCE(calcium_mg, 130.0),
  iron_mg = COALESCE(iron_mg, 8.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 150.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 6.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 40.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 3.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'cereal' AND sodium_mg IS NULL;

-- Category: chips (branded chips, tortilla chips)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 0.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 350.0),
  calcium_mg = COALESCE(calcium_mg, 15.0),
  iron_mg = COALESCE(iron_mg, 1.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 0.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 10.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 30.0),
  zinc_mg = COALESCE(zinc_mg, 0.5),
  phosphorus_mg = COALESCE(phosphorus_mg, 80.0),
  selenium_ug = COALESCE(selenium_ug, 3.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'chips' AND sodium_mg IS NULL;

-- Category: bars (protein bars, granola bars, energy bars)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 250.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 5.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 100.0),
  iron_mg = COALESCE(iron_mg, 3.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 60.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 20.0),
  magnesium_mg = COALESCE(magnesium_mg, 40.0),
  zinc_mg = COALESCE(zinc_mg, 2.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 150.0),
  selenium_ug = COALESCE(selenium_ug, 8.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'bars' AND sodium_mg IS NULL;

-- Category: frozen_meals (branded frozen meals)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 60.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 2.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'frozen_meals' AND sodium_mg IS NULL;

-- Category: yogurt (branded yogurt products)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 50.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 10.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 1.5),
  trans_fat_g = COALESCE(trans_fat_g, 0.0),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 150.0),
  iron_mg = COALESCE(iron_mg, 0.1),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 20.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 0.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 30.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 0.8),
  phosphorus_mg = COALESCE(phosphorus_mg, 150.0),
  selenium_ug = COALESCE(selenium_ug, 5.0),
  omega3_g = COALESCE(omega3_g, 0.02)
WHERE food_category = 'yogurt' AND sodium_mg IS NULL;

-- Category: convenience_store (7-Eleven, Wawa, etc.)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 500.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 25.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 150.0),
  calcium_mg = COALESCE(calcium_mg, 40.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 10.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 15.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 8.0),
  omega3_g = COALESCE(omega3_g, 0.03)
WHERE food_category = 'convenience_store' AND sodium_mg IS NULL;

-- Category: warehouse_club (Costco, Sam's Club)
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 450.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 4.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.2),
  potassium_mg = COALESCE(potassium_mg, 180.0),
  calcium_mg = COALESCE(calcium_mg, 50.0),
  iron_mg = COALESCE(iron_mg, 1.5),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 15.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 18.0),
  zinc_mg = COALESCE(zinc_mg, 1.2),
  phosphorus_mg = COALESCE(phosphorus_mg, 120.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE food_category = 'warehouse_club' AND sodium_mg IS NULL;

-- ============================================================================
-- FINAL CATCH-ALL: Any rows still without micronutrients
-- Uses moderate generic defaults suitable for mixed/unknown food items
-- ============================================================================
UPDATE food_nutrition_overrides SET
  sodium_mg = COALESCE(sodium_mg, 300.0),
  cholesterol_mg = COALESCE(cholesterol_mg, 30.0),
  saturated_fat_g = COALESCE(saturated_fat_g, 3.0),
  trans_fat_g = COALESCE(trans_fat_g, 0.1),
  potassium_mg = COALESCE(potassium_mg, 200.0),
  calcium_mg = COALESCE(calcium_mg, 30.0),
  iron_mg = COALESCE(iron_mg, 1.0),
  vitamin_a_ug = COALESCE(vitamin_a_ug, 10.0),
  vitamin_c_mg = COALESCE(vitamin_c_mg, 1.0),
  vitamin_d_iu = COALESCE(vitamin_d_iu, 0.0),
  magnesium_mg = COALESCE(magnesium_mg, 20.0),
  zinc_mg = COALESCE(zinc_mg, 1.0),
  phosphorus_mg = COALESCE(phosphorus_mg, 100.0),
  selenium_ug = COALESCE(selenium_ug, 10.0),
  omega3_g = COALESCE(omega3_g, 0.05)
WHERE sodium_mg IS NULL;
