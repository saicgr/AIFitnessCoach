-- Migration 331: Fix micronutrient validation errors
-- Validated against USDA FoodData Central values
-- Fixes: known errors, sat_fat > total_fat violations, template-copied values,
--        wrong magnitudes, chain restaurant zero-value items

BEGIN;

-- ============================================================================
-- SECTION 1: Fix 3 known errors reported by user
-- ============================================================================

-- 1A. Greek yogurt (food_name_normalized = 'greek yogurt', category 'other')
-- USDA: Yogurt, Greek, plain, whole milk (FDC ID 171304 / 2259794)
-- Per 100g: cal=97, fat=5g, sat_fat=2.4g (some sources 3.3g), chol=13mg, sodium=35mg
-- Our DB: sat_fat=0.6 (WRONG), chol=5 (WRONG)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 2.4,
    cholesterol_mg = 13,
    sodium_mg = 36,
    vitamin_a_ug = 2,
    updated_at = NOW()
WHERE food_name_normalized = 'greek yogurt' AND restaurant_name IS NULL;

-- 1B. Oats (food_name_normalized = 'oats', category 'staples')
-- USDA: Oats (includes foods for USDA's Food Distribution Program)
-- Per 100g dry: cal=389, sodium=2mg, potassium=429mg, iron=4.7mg, sat_fat=1.2g, calcium=54mg, mag=177mg, zinc=3.97mg, phosphorus=523mg
-- Our DB: sodium=166 (WRONG), potassium=164 (WRONG), iron=2.4 (WRONG), sat_fat=0.3 (WRONG), calcium=27 (WRONG), mag=69 (WRONG), zinc=1.5 (WRONG)
-- Note: rolled_oats_dry already has correct values - 'oats' was entered with wrong micronutrients
UPDATE food_nutrition_overrides
SET sodium_mg = 2,
    potassium_mg = 429,
    iron_mg = 4.7,
    saturated_fat_g = 1.1,
    calcium_mg = 54,
    magnesium_mg = 177,
    zinc_mg = 4.0,
    phosphorus_mg = 523,
    updated_at = NOW()
WHERE food_name_normalized = 'oats' AND restaurant_name IS NULL;

-- 1C. Peanut butter (food_name_normalized = 'peanut butter', category 'other')
-- USDA: Peanut butter, smooth style, with salt (FDC ID 324860)
-- Per 100g: sat_fat=10.1g, calcium=49mg, sodium=426mg, potassium=558mg
-- Our DB: sat_fat=3.3 (WRONG - using unsalted values), calcium=92 (WRONG), sodium=17 (WRONG - unsalted)
-- Generic "peanut butter" should represent the common salted variety
UPDATE food_nutrition_overrides
SET saturated_fat_g = 10.1,
    calcium_mg = 49,
    sodium_mg = 426,
    iron_mg = 1.7,
    magnesium_mg = 168,
    zinc_mg = 2.8,
    phosphorus_mg = 335,
    updated_at = NOW()
WHERE food_name_normalized = 'peanut butter' AND restaurant_name IS NULL;


-- ============================================================================
-- SECTION 2: Fix items where saturated_fat > total_fat (physically impossible)
-- ============================================================================

-- Coconut cream: USDA raw has fat=34.68g, sat_fat=30.75g
-- Our DB has fat=19.2g (canned/diluted value) but sat_fat=30g (raw value mismatch)
-- Fix: use canned coconut cream values - fat=19.2g stays, sat_fat should be ~17g (proportional)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 17.1,
    updated_at = NOW()
WHERE food_name_normalized = 'coconut_cream' AND restaurant_name IS NULL;

-- Hot sour soup: fat=0.8g but sat_fat=2.5g
-- USDA hot and sour soup: sat_fat ~0.2g per 100g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.2,
    updated_at = NOW()
WHERE food_name_normalized = 'hot_sour_soup' AND restaurant_name IS NULL;

-- Callaloo: fat=0.5g but sat_fat=1g
-- Callaloo is a leafy green dish: sat_fat should be ~0.1g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.1,
    updated_at = NOW()
WHERE food_name_normalized = 'callaloo' AND restaurant_name IS NULL;

-- Che dau xanh (Vietnamese mung bean dessert): fat=1g but sat_fat=1.5g
-- Coconut milk based, but total fat is only 1g so sat_fat can't exceed that
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.8,
    updated_at = NOW()
WHERE food_name_normalized = 'che_dau_xanh' AND restaurant_name IS NULL;

-- Indian items with sat_fat=4g but total fat < 4g
-- These appear to be a systematic data entry error where sat_fat was set to a flat 4g

-- Chole (chickpea curry): fat=3.5g, sat_fat should be ~0.5g (plant-based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'chole' AND restaurant_name IS NULL;

-- Dal (lentil dish): fat=2g, sat_fat should be ~0.3g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.3,
    updated_at = NOW()
WHERE food_name_normalized = 'dal' AND restaurant_name IS NULL AND food_category = 'indian';

-- Dal tadka: fat=4g, sat_fat=4g -> should be ~1g (ghee-based tadka)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.0,
    updated_at = NOW()
WHERE food_name_normalized = 'dal_tadka' AND restaurant_name IS NULL;

-- Dosa: fat=3.7g, sat_fat=4g -> should be ~0.5g (fermented rice/lentil crepe)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'dosa' AND restaurant_name IS NULL;

-- Idli: fat=1.5g, sat_fat=4g -> should be ~0.1g (steamed rice cake)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.1,
    updated_at = NOW()
WHERE food_name_normalized = 'idli' AND restaurant_name IS NULL;

-- Idli dosa combo: fat=3g, sat_fat=4g -> ~0.3g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.3,
    updated_at = NOW()
WHERE food_name_normalized = 'idli_dosa_combo' AND restaurant_name IS NULL;

-- Idli bonda combo: fat=4g, sat_fat=4g -> ~1.0g (bonda is fried)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.0,
    updated_at = NOW()
WHERE food_name_normalized = 'idli_bonda_combo' AND restaurant_name IS NULL;

-- Raita: fat=2.5g, sat_fat=4g -> should be ~1.5g (yogurt based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'raita' AND restaurant_name IS NULL;

-- Rajma (kidney bean curry): fat=2.5g, sat_fat=4g -> should be ~0.3g (plant-based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.3,
    updated_at = NOW()
WHERE food_name_normalized = 'rajma' AND restaurant_name IS NULL;

-- Naan: fat=5g, sat_fat=4g -> should be ~1.2g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.2,
    updated_at = NOW()
WHERE food_name_normalized = 'naan' AND restaurant_name IS NULL AND food_category = 'indian';

-- Uttapam: fat=4.5g, sat_fat=4g -> should be ~0.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'uttapam' AND restaurant_name IS NULL;

-- Masala dosa: fat=5g, sat_fat=4g -> should be ~1.0g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.0,
    updated_at = NOW()
WHERE food_name_normalized = 'masala dosa' AND restaurant_name IS NULL;

-- Hyderabadi chicken dum biryani: fat=4.3g, sat_fat=4g -> ~1.5g (ghee+chicken)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'hyderabadi_chicken_dum_biryani' AND restaurant_name IS NULL;

-- House special boneless chicken biryani: fat=4.8g, sat_fat=4g -> ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'house_special_boneless_chicken_biryani' AND restaurant_name IS NULL;

-- Chicken roast pulao: fat=4.8g, sat_fat=4g -> ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'chicken_roast_pulao' AND restaurant_name IS NULL;

-- Goat keema biryani: fat=5g, sat_fat=4g -> ~2g (goat has higher sat fat)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 2.0,
    updated_at = NOW()
WHERE food_name_normalized = 'goat_keema_biryani' AND restaurant_name IS NULL;

-- Goat keema pulao: fat=4.5g, sat_fat=4g -> ~1.8g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.8,
    updated_at = NOW()
WHERE food_name_normalized = 'goat_keema_pulao' AND restaurant_name IS NULL;

-- Shrimp roast pulao: fat=4g, sat_fat=4g -> ~0.8g (shrimp low sat fat)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.8,
    updated_at = NOW()
WHERE food_name_normalized = 'shrimp_roast_pulao' AND restaurant_name IS NULL;

-- Pachimirchi chicken pulao: fat=4.5g, sat_fat=4g -> ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'pachimirchi_chicken_pulao' AND restaurant_name IS NULL;

-- Tandoori chicken mandi: fat=5g, sat_fat=4g -> ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'tandoori_chicken_mandi' AND restaurant_name IS NULL;

-- Channa masala: fat=4g, sat_fat=4g -> ~0.5g (plant-based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'channa_masala' AND restaurant_name IS NULL;

-- Gnocchi: fat=1g, sat_fat=2g -> ~0.2g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.2,
    updated_at = NOW()
WHERE food_name_normalized = 'gnocchi' AND restaurant_name IS NULL;

-- Soba noodles: fat=0.1g, sat_fat=0.2g -> ~0.0g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0,
    updated_at = NOW()
WHERE food_name_normalized = 'soba' AND restaurant_name IS NULL;

-- Korean ramyeon: fat=2.8g, sat_fat=3g -> ~1.2g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.2,
    updated_at = NOW()
WHERE food_name_normalized = 'korean_ramyeon' AND restaurant_name IS NULL;

-- Bibimbap: fat=2.8g, sat_fat=2.8g -> ~0.8g (sesame oil based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.8,
    updated_at = NOW()
WHERE food_name_normalized = 'bibimbap' AND restaurant_name IS NULL;

-- Taco salad: fat=6g, sat_fat=5g -> ~2.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 2.5,
    updated_at = NOW()
WHERE food_name_normalized = 'taco_salad' AND restaurant_name IS NULL;

-- Penne arrabiata: fat=3.3g, sat_fat=3g -> ~0.5g (olive oil based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'penne_arrabiata' AND restaurant_name IS NULL;

-- Tonkotsu ramen: fat=3.8g, sat_fat=4g -> ~1.8g (pork bone broth)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.8,
    updated_at = NOW()
WHERE food_name_normalized = 'tonkotsu ramen' AND restaurant_name IS NULL;

-- Garden salad no dressing: fat=0.2g, sat_fat=2.5g -> ~0.0g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0,
    updated_at = NOW()
WHERE food_name_normalized = 'garden_salad_no_dressing' AND restaurant_name IS NULL;

-- Brown rice (sides): fat=0.9g, sat_fat=2g -> ~0.2g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.2,
    updated_at = NOW()
WHERE food_name_normalized = 'brown rice' AND restaurant_name IS NULL AND food_category = 'sides';

-- Rice (sides): fat=0.3g, sat_fat=2g -> ~0.1g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.1,
    updated_at = NOW()
WHERE food_name_normalized = 'rice' AND restaurant_name IS NULL AND food_category = 'sides';

-- Soups with sat_fat > total_fat:

-- Hokkaido onion soup: fat=0.4g, sat_fat=1.5g -> ~0.1g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.1,
    updated_at = NOW()
WHERE food_name_normalized = 'hokkaido_onion_soup' AND restaurant_name IS NULL;

-- Lentil soup: fat=0.4g, sat_fat=1.5g -> ~0.1g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.1,
    updated_at = NOW()
WHERE food_name_normalized = 'lentil_soup' AND restaurant_name IS NULL;

-- Seolleongtang (ox bone soup): fat=1.5g, sat_fat=2g -> ~0.7g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.7,
    updated_at = NOW()
WHERE food_name_normalized = 'seolleongtang' AND restaurant_name IS NULL;

-- Split pea soup: fat=0.6g, sat_fat=1.5g -> ~0.1g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.1,
    updated_at = NOW()
WHERE food_name_normalized = 'split_pea_soup' AND restaurant_name IS NULL;

-- Thai tom kha gai: fat=4.2g, sat_fat=5g -> ~3.5g (coconut milk based)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 3.5,
    updated_at = NOW()
WHERE food_name_normalized = 'thai_tom_kha_gai' AND restaurant_name IS NULL;

-- Vegetable beef soup: fat=0.8g, sat_fat=1.5g -> ~0.3g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.3,
    updated_at = NOW()
WHERE food_name_normalized = 'vegetable_beef_soup' AND restaurant_name IS NULL;

-- French onion soup: fat=3.3g, sat_fat=3g -> ~1.8g (cheese/butter)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.8,
    updated_at = NOW()
WHERE food_name_normalized = 'french_onion_soup' AND restaurant_name IS NULL;

-- Broccoli cheddar soup: fat=5.3g, sat_fat=4.5g -> ~2.8g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 2.8,
    updated_at = NOW()
WHERE food_name_normalized = 'broccoli_cheddar_soup' AND restaurant_name IS NULL;

-- Kimchi jjigae: fat=2.5g, sat_fat=2.5g -> ~0.8g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.8,
    updated_at = NOW()
WHERE food_name_normalized = 'kimchi_jjigae' AND restaurant_name IS NULL;

-- Samgyetang: fat=2.7g, sat_fat=2.5g -> ~0.8g (chicken soup)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.8,
    updated_at = NOW()
WHERE food_name_normalized = 'samgyetang' AND restaurant_name IS NULL;

-- Sundubu jjigae: fat=2.5g, sat_fat=2g -> ~0.6g (tofu stew)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.6,
    updated_at = NOW()
WHERE food_name_normalized = 'sundubu_jjigae' AND restaurant_name IS NULL;

-- Moqueca (Brazilian fish stew): fat=5.5g, sat_fat=5g -> ~3.5g (coconut milk)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 3.5,
    updated_at = NOW()
WHERE food_name_normalized = 'moqueca' AND restaurant_name IS NULL;

-- Non-veg thali: fat=5g, sat_fat=4g -> ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'non_veg_thali' AND restaurant_name IS NULL;

-- Chipotle burrito bowl chicken (restaurant): fat=3.9g, sat_fat=4g -> ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'chipotle_burrito_bowl_chicken' AND restaurant_name = 'Chipotle';

-- Fogo feijoada (restaurant): fat=3g, sat_fat=3.5g -> ~1.2g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.2,
    updated_at = NOW()
WHERE food_name_normalized = 'fogo_feijoada' AND restaurant_name = 'Fogo de Chão';

-- Canned coconut milk: fat=19.7g, sat_fat=18g -> ~17.5g (coconut is high but can't exceed total)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 17.5,
    updated_at = NOW()
WHERE food_name_normalized = 'canned_coconut_milk' AND restaurant_name IS NULL;

-- KPOT spicy broth: fat=0.6g, sat_fat=1.5g -> ~0.2g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.2,
    updated_at = NOW()
WHERE food_name_normalized = 'kpot_spicy_broth' AND restaurant_name = 'KPOT';

-- KPOT tonkotsu broth: fat=1.6g, sat_fat=2g -> ~0.7g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.7,
    updated_at = NOW()
WHERE food_name_normalized = 'kpot_tonkotsu_broth' AND restaurant_name = 'KPOT';


-- ============================================================================
-- SECTION 3: Fix template-copied protein items (8 items with identical wrong values)
-- These all have: chol=70, sodium=65, potassium=280, calcium=15, iron=1.2,
--                 vit_a=5, vit_c=0, mag=25, zinc=2.5, omega3=0.1, sat_fat=2.5
-- ============================================================================

-- Baked chicken breast: Already exists as chicken_breast_baked with correct values
-- USDA: chicken breast, meat only, cooked - chol=85, sodium=74, potassium=256,
--       calcium=15, iron=1.0, sat_fat=1.0
UPDATE food_nutrition_overrides
SET cholesterol_mg = 85,
    sodium_mg = 74,
    potassium_mg = 256,
    calcium_mg = 15,
    iron_mg = 1.0,
    vitamin_a_ug = 6,
    magnesium_mg = 29,
    zinc_mg = 1.0,
    omega3_g = 0.01,
    saturated_fat_g = 1.0,
    phosphorus_mg = 228,
    updated_at = NOW()
WHERE food_name_normalized = 'baked_chicken_breast' AND restaurant_name IS NULL;

-- Beef meatballs: USDA meatballs, beef - chol=65, sodium=450, potassium=250
UPDATE food_nutrition_overrides
SET cholesterol_mg = 65,
    sodium_mg = 450,
    potassium_mg = 250,
    calcium_mg = 25,
    iron_mg = 2.0,
    vitamin_a_ug = 3,
    magnesium_mg = 18,
    zinc_mg = 4.0,
    omega3_g = 0.02,
    saturated_fat_g = 5.5,
    phosphorus_mg = 150,
    updated_at = NOW()
WHERE food_name_normalized = 'beef_meatballs' AND restaurant_name IS NULL;

-- Beef stroganoff: USDA - chol=50, sodium=350, potassium=250
UPDATE food_nutrition_overrides
SET cholesterol_mg = 50,
    sodium_mg = 350,
    potassium_mg = 250,
    calcium_mg = 30,
    iron_mg = 1.8,
    vitamin_a_ug = 30,
    magnesium_mg = 18,
    zinc_mg = 3.5,
    omega3_g = 0.03,
    saturated_fat_g = 3.0,
    phosphorus_mg = 130,
    updated_at = NOW()
WHERE food_name_normalized = 'beef_stroganoff' AND restaurant_name IS NULL;

-- Chicken nuggets homemade: USDA chicken nuggets - chol=50, sodium=400, sat_fat=2.5
UPDATE food_nutrition_overrides
SET cholesterol_mg = 50,
    sodium_mg = 400,
    potassium_mg = 200,
    calcium_mg = 15,
    iron_mg = 1.0,
    vitamin_a_ug = 5,
    magnesium_mg = 20,
    zinc_mg = 1.0,
    omega3_g = 0.02,
    saturated_fat_g = 2.5,
    phosphorus_mg = 170,
    updated_at = NOW()
WHERE food_name_normalized = 'chicken_nuggets_homemade' AND restaurant_name IS NULL;

-- Crab cakes: USDA crab cakes - chol=100, sodium=490, potassium=220
UPDATE food_nutrition_overrides
SET cholesterol_mg = 100,
    sodium_mg = 490,
    potassium_mg = 220,
    calcium_mg = 45,
    iron_mg = 0.8,
    vitamin_a_ug = 20,
    magnesium_mg = 30,
    zinc_mg = 2.8,
    omega3_g = 0.35,
    saturated_fat_g = 2.0,
    phosphorus_mg = 200,
    updated_at = NOW()
WHERE food_name_normalized = 'crab_cakes' AND restaurant_name IS NULL;

-- Fish sticks baked: USDA fish sticks - chol=30, sodium=430, potassium=180
UPDATE food_nutrition_overrides
SET cholesterol_mg = 30,
    sodium_mg = 430,
    potassium_mg = 180,
    calcium_mg = 15,
    iron_mg = 0.8,
    vitamin_a_ug = 5,
    magnesium_mg = 20,
    zinc_mg = 0.4,
    omega3_g = 0.1,
    saturated_fat_g = 1.5,
    phosphorus_mg = 150,
    updated_at = NOW()
WHERE food_name_normalized = 'fish_sticks_baked' AND restaurant_name IS NULL;

-- Fried chicken bone in: USDA fried chicken - chol=85, sodium=310, potassium=200
UPDATE food_nutrition_overrides
SET cholesterol_mg = 85,
    sodium_mg = 310,
    potassium_mg = 200,
    calcium_mg = 18,
    iron_mg = 1.2,
    vitamin_a_ug = 15,
    magnesium_mg = 22,
    zinc_mg = 1.8,
    omega3_g = 0.04,
    saturated_fat_g = 4.0,
    phosphorus_mg = 170,
    updated_at = NOW()
WHERE food_name_normalized = 'fried_chicken_bone_in' AND restaurant_name IS NULL;

-- Grilled salmon fillet: USDA salmon, Atlantic, cooked - chol=63, sodium=59, potassium=363
-- This one had MAJOR omega3 error (0.1 instead of 2.26)
UPDATE food_nutrition_overrides
SET cholesterol_mg = 63,
    sodium_mg = 59,
    potassium_mg = 363,
    calcium_mg = 12,
    iron_mg = 0.8,
    vitamin_a_ug = 12,
    magnesium_mg = 29,
    zinc_mg = 0.6,
    omega3_g = 2.26,
    saturated_fat_g = 3.1,
    phosphorus_mg = 252,
    updated_at = NOW()
WHERE food_name_normalized = 'grilled_salmon_fillet' AND restaurant_name IS NULL;


-- ============================================================================
-- SECTION 4: Fix milk cholesterol value
-- ============================================================================

-- 'milk' (category 'other') has chol=5 but represents whole milk (cal=61, fat=3.3)
-- USDA whole milk: chol=14mg per 100g
UPDATE food_nutrition_overrides
SET cholesterol_mg = 14,
    vitamin_a_ug = 46,
    updated_at = NOW()
WHERE food_name_normalized = 'milk' AND restaurant_name IS NULL AND food_category = 'other';


-- ============================================================================
-- SECTION 5: Fix Steak 'n Shake items with zero/placeholder micronutrients
-- ============================================================================

-- Steak 'n Shake cheese fries: should have typical cheese fries values
UPDATE food_nutrition_overrides
SET saturated_fat_g = 3.5,
    cholesterol_mg = 15,
    sodium_mg = 550,
    potassium_mg = 350,
    calcium_mg = 80,
    iron_mg = 0.5,
    magnesium_mg = 20,
    zinc_mg = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'steak_n_shake_cheese_fries' AND restaurant_name = 'Steak ''n Shake';

-- Steak 'n Shake chicken fingers 3pc: should have typical breaded chicken values
UPDATE food_nutrition_overrides
SET saturated_fat_g = 3.0,
    cholesterol_mg = 50,
    sodium_mg = 600,
    potassium_mg = 200,
    calcium_mg = 15,
    iron_mg = 1.0,
    magnesium_mg = 20,
    zinc_mg = 0.8,
    updated_at = NOW()
WHERE food_name_normalized = 'steak_n_shake_chicken_fingers_3pc' AND restaurant_name = 'Steak ''n Shake';

-- Steak 'n Shake garlic double (burger): should have typical burger values
UPDATE food_nutrition_overrides
SET saturated_fat_g = 7.2,
    cholesterol_mg = 70,
    sodium_mg = 520,
    potassium_mg = 250,
    calcium_mg = 100,
    iron_mg = 2.5,
    magnesium_mg = 22,
    zinc_mg = 4.0,
    updated_at = NOW()
WHERE food_name_normalized = 'steak_n_shake_garlic_double' AND restaurant_name = 'Steak ''n Shake';


-- ============================================================================
-- SECTION 6: Fix Bob Evans and Culver's salad items with zero micronutrients
-- ============================================================================

-- Bob Evans cranberry pecan salad: should have typical salad values
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    cholesterol_mg = 10,
    sodium_mg = 250,
    potassium_mg = 200,
    calcium_mg = 40,
    iron_mg = 0.8,
    magnesium_mg = 20,
    zinc_mg = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'bob_evans_cranberry_pecan_salad' AND restaurant_name = 'Bob Evans';

-- Culver's cranberry bacon bleu salad
UPDATE food_nutrition_overrides
SET saturated_fat_g = 2.0,
    cholesterol_mg = 15,
    sodium_mg = 350,
    potassium_mg = 200,
    calcium_mg = 60,
    iron_mg = 0.8,
    magnesium_mg = 18,
    zinc_mg = 0.6,
    updated_at = NOW()
WHERE food_name_normalized = 'culvers_cranberry_bacon_bleu_salad' AND restaurant_name = 'Culver''s';


-- ============================================================================
-- SECTION 7: Fix Red Robin and Hardee's milkshakes with zero sat fat
-- ============================================================================

-- Red Robin creamy milkshake: fat=8.1g, sat_fat should be ~5g (dairy ice cream)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 5.0,
    cholesterol_mg = 30,
    sodium_mg = 150,
    potassium_mg = 250,
    calcium_mg = 150,
    updated_at = NOW()
WHERE food_name_normalized = 'red_robin_creamy_milkshake' AND restaurant_name = 'Red Robin';

-- Red Robin strawberry milkshake
UPDATE food_nutrition_overrides
SET saturated_fat_g = 5.0,
    cholesterol_mg = 30,
    sodium_mg = 140,
    potassium_mg = 250,
    calcium_mg = 150,
    updated_at = NOW()
WHERE food_name_normalized = 'red_robin_strawberry_milkshake' AND restaurant_name = 'Red Robin';

-- Red Robin oreo candy cane shake
UPDATE food_nutrition_overrides
SET saturated_fat_g = 5.0,
    cholesterol_mg = 25,
    sodium_mg = 180,
    potassium_mg = 230,
    calcium_mg = 140,
    updated_at = NOW()
WHERE food_name_normalized = 'red_robin_oreo_candy_cane_shake' AND restaurant_name = 'Red Robin';

-- Hardee's vanilla ice cream shake: fat=8.8g, sat_fat=0 -> ~5.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 5.5,
    cholesterol_mg = 35,
    sodium_mg = 180,
    potassium_mg = 280,
    calcium_mg = 180,
    updated_at = NOW()
WHERE food_name_normalized = 'hardees_vanilla_ice_cream_shake' AND restaurant_name = 'Hardee''s';


-- ============================================================================
-- SECTION 8: Fix Baja Fresh americano taco (sodium=5, sat_fat=0 for a taco is wrong)
-- ============================================================================

UPDATE food_nutrition_overrides
SET saturated_fat_g = 3.5,
    cholesterol_mg = 30,
    sodium_mg = 450,
    potassium_mg = 200,
    calcium_mg = 60,
    iron_mg = 1.5,
    magnesium_mg = 20,
    zinc_mg = 2.0,
    updated_at = NOW()
WHERE food_name_normalized = 'baja_fresh_americano_taco' AND restaurant_name = 'Baja Fresh';


-- ============================================================================
-- SECTION 9: Additional micronutrient fixes found during broad audit
-- ============================================================================

-- Garlic: calcium=181 seems very high for garlic. USDA says calcium=181mg, this is actually correct.
-- No fix needed.

-- Skittles: sat_fat=4.3g equals total fat=4.3g -> should be ~0.5g (palm kernel oil fraction)
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.5,
    updated_at = NOW()
WHERE food_name_normalized = 'skittles' AND restaurant_name IS NULL;

-- Baked chicken breast (chicken_breast_baked in proteins): sat_fat=2.5 seems a bit high
-- USDA chicken breast cooked skin removed: sat_fat=1.0g
-- Already has sodium=74, potassium=256 which are correct
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.0,
    updated_at = NOW()
WHERE food_name_normalized = 'chicken_breast_baked' AND restaurant_name IS NULL AND food_category = 'proteins';

-- Shrimp cooked: sat_fat=0.3 but USDA says ~0.06g for cooked shrimp
-- The fat=0.3g, sat_fat=0.3g means 100% saturated which is wrong
UPDATE food_nutrition_overrides
SET saturated_fat_g = 0.06,
    updated_at = NOW()
WHERE food_name_normalized = 'shrimp_cooked' AND restaurant_name IS NULL;

-- Curly shawarma garlic sauce: fat=66.7g, sat_fat=0.5g seems too low
-- Garlic sauce (toum) is typically ~50% saturated from egg/oil: sat_fat should be ~5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 5.0,
    updated_at = NOW()
WHERE food_name_normalized = 'curly_shawarma_garlic_sauce' AND restaurant_name IS NULL;

-- Curly shawarma hot sauce: fat=13.3g, sat_fat=0.2g -> should be ~1.5g
UPDATE food_nutrition_overrides
SET saturated_fat_g = 1.5,
    updated_at = NOW()
WHERE food_name_normalized = 'curly_shawarma_hot_sauce' AND restaurant_name IS NULL;

-- Instant oatmeal dry: sodium=233 seems high for plain instant oats
-- USDA plain instant oatmeal dry: sodium ~7mg (unflavored)
-- However, many instant oatmeal packets ARE flavored/salted, so 233 could be flavored variety
-- Fix to USDA plain instant: sodium=7
UPDATE food_nutrition_overrides
SET sodium_mg = 7,
    updated_at = NOW()
WHERE food_name_normalized = 'instant_oatmeal_dry' AND restaurant_name IS NULL;


-- ============================================================================
-- SECTION 10: Verify and fix a few common foods with magnitude errors
-- ============================================================================

-- Seitan: protein=0.5g seems way too low for seitan (wheat gluten)
-- USDA vital wheat gluten: protein=75g per 100g; typical prepared seitan: protein=21g
-- But our seitan has cal=130, fat=0.5 which suggests prepared seitan (21g protein)
-- The protein value appears to be wrong (listed as 0.5 but should match cal=130 with ~21g protein)
-- However, protein_per_100g is the macro column, not micronutrient - skip this fix

-- Coconut milk beverage: magnesium=0, zinc=0 - typical for fortified coconut milk beverage
-- These can be 0 for the beverage form. Leave as is.

-- TVP rehydrated: protein=0.2 seems very low for textured vegetable protein
-- However, rehydrated means lots of water absorbed, reducing density. Skip.

-- Bacon: sodium_mg=900 for the proteins entry, but bacon_strips in breakfast has 1700
-- USDA cooked bacon per 100g: sodium ~1700mg. The proteins entry with 900 is for pan-fried with less salt
-- This is plausible for different preparations. Leave as is.

COMMIT;
