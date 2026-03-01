-- Migration 332: Fix chain restaurant & branded item micronutrient validation errors
-- Validated against published nutrition data from fastfoodnutrition.org, nutritionvalue.org (USDA),
-- and official brand nutrition labels. All values are per 100g.
-- Date: 2026-02-28

BEGIN;

-- =============================================================================
-- SECTION 1: CHAIN RESTAURANT FIXES
-- =============================================================================

-- 1. McDonald's Big Mac (ID 630)
-- Source: USDA/nutritionvalue.org - 219g serving: 563cal, 8.3g satfat, 79mg chol, 1007mg sodium
-- Per 100g: satfat=3.79, chol=36.1, sodium=460
-- Our DB had: satfat=6.2 (too high), chol=63.5 (too high), sodium=512 (slightly high)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 3.79,
    cholesterol_mg = 36.1,
    sodium_mg = 460,
    trans_fat_g = 0.46,
    updated_at = NOW()
WHERE id = 630;

-- 2. McDonald's Large Fries (ID 645)
-- Source: fastfoodnutrition.org - 154g serving: 510cal, 3g satfat, 0mg chol, 400mg sodium
-- Per 100g (154g): sodium=260
-- Our DB had: sodium=376.5 (45% too high)
UPDATE food_nutrition_overrides SET
    sodium_mg = 260,
    saturated_fat_g = 1.95,
    updated_at = NOW()
WHERE id = 645;

-- 3. Chick-fil-A Chicken Sandwich (ID 653)
-- Source: fastfoodnutrition.org/USDA - 187g serving: 440-466cal, 4g satfat, 65-70mg chol, 1400mg sodium
-- Per 100g (187g): chol=37.4, sodium=748.7, satfat=2.14, transfat=0
-- Our DB had: chol=73.8 (DOUBLE!), sodium=557.5 (25% under)
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 37.4,
    sodium_mg = 748.7,
    saturated_fat_g = 2.14,
    trans_fat_g = 0,
    updated_at = NOW()
WHERE id = 653;

-- 4. Chick-fil-A Spicy Chicken Sandwich (ID 654) - same serving size, similar issues
-- Spicy version: 450cal, 4.5g satfat, 70mg chol, 1620mg sodium per 187g serving
-- Per 100g: satfat=2.41, chol=37.4, sodium=866.8
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 37.4,
    sodium_mg = 866.8,
    saturated_fat_g = 2.41,
    trans_fat_g = 0,
    updated_at = NOW()
WHERE id = 654;

-- 5. Chick-fil-A Waffle Fries Medium (ID 662)
-- Source: eatthismuch.com - 125g serving: 420cal, 4g satfat, 0mg chol, 240mg sodium
-- Per 100g: sodium=192, satfat=3.2, chol=0
-- Our DB had: sodium=396 (DOUBLE!), chol=0 (correct)
UPDATE food_nutrition_overrides SET
    sodium_mg = 192,
    saturated_fat_g = 3.2,
    updated_at = NOW()
WHERE id = 662;

-- 6. Starbucks Caffe Latte Grande (ID 674)
-- Source: fastfoodnutrition.org - 16oz(473g): 220cal, 7g satfat, 35mg chol, 140mg sodium
-- Per 100g: satfat=1.48, chol=7.4, sodium=29.6, fat=2.33
-- Our DB had: satfat=0.9 (low), chol=3 (low), sodium=48.1 (high), fat=1.5 (low)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 1.48,
    cholesterol_mg = 7.4,
    sodium_mg = 29.6,
    fat_per_100g = 2.33,
    calories_per_100g = 46.5,
    protein_per_100g = 2.54,
    carbs_per_100g = 3.81,
    sugar_per_100g = 3.38,
    updated_at = NOW()
WHERE id = 674;

-- 7. Subway 6" Turkey Breast (ID 765)
-- Source: fastfoodnutrition.org - 219g serving: 260cal, 1g satfat, 25mg chol, 790mg sodium
-- Per 100g: chol=11.4, sodium=360.7, satfat=0.46
-- Our DB had: chol=27.3 (140% too high), sodium=416 (15% high)
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 11.4,
    sodium_mg = 360.7,
    saturated_fat_g = 0.46,
    restaurant_name = 'Subway',
    updated_at = NOW()
WHERE id = 765;

-- 8. Chipotle Chicken Burrito Bowl (ID 132)
-- Source: Chipotle nutrition calculator - standard bowl ~542g: ~660cal, 8.5g satfat, sodium ~2090mg
-- Per 100g (542g): satfat=1.57, sodium=385.6
-- Our DB had: satfat=4.0 (way too high), sodium=450 (high)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 1.57,
    sodium_mg = 385.6,
    updated_at = NOW()
WHERE id = 132;

-- 9. Taco Bell Crunchy Taco (ID 700)
-- Source: fastfoodnutrition.org - 78g(matches): 170cal, 3.5g satfat, 25mg chol, 310mg sodium
-- Per 100g: sodium=397.4, chol=32.1, fat=11.5
-- Our DB had: sodium=527.1 (33% too high), chol=40.6 (26% high)
UPDATE food_nutrition_overrides SET
    sodium_mg = 397.4,
    cholesterol_mg = 32.1,
    fat_per_100g = 11.5,
    updated_at = NOW()
WHERE id = 700;

-- 10. Taco Bell Crunchy Taco Supreme (ID 701) - proportional fix
-- Published: 190cal, 4g satfat, 25mg chol, 340mg sodium per 92g
-- Per 100g: sodium=369.6, chol=27.2
UPDATE food_nutrition_overrides SET
    sodium_mg = 369.6,
    cholesterol_mg = 27.2,
    updated_at = NOW()
WHERE id = 701;

-- 11. Wendy's Dave's Single (ID 732)
-- Source: fastfoodnutrition.org - ~244g serving: 570cal, 13g satfat, 1.5g transfat, 100mg chol, 1020mg sodium
-- Per 100g (244g): satfat=5.33, transfat=0.61, chol=41.0, sodium=418
-- Our DB had: transfat=0.14 (WAY too low), satfat=4.45 (low), chol=33.5 (low), sodium=457 (slightly high)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 5.33,
    trans_fat_g = 0.61,
    cholesterol_mg = 41.0,
    sodium_mg = 418,
    updated_at = NOW()
WHERE id = 732;

-- 12. Domino's Hand Tossed Pepperoni Pizza Large Slice (ID 794)
-- Source: USDA/nutritionvalue.org - 113g(matches): 308cal, 5.4g satfat, 0.354g transfat, 28mg chol, 690mg sodium
-- Per 100g: chol=24.8, transfat=0.31, satfat=4.78, sodium=610.6
-- Our DB had: chol=43 (73% too high), transfat=0.11 (too low)
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 24.8,
    trans_fat_g = 0.31,
    sodium_mg = 610.6,
    updated_at = NOW()
WHERE id = 794;

-- 13. Panera Bread Broccoli Cheddar Soup Bowl (ID 906)
-- Source: eatthismuch.com - 338g serving: 297cal, 19g fat, 13g satfat, 68mg chol, 1253mg sodium
-- Per 100g (using 350g our DB): satfat=3.71, sodium=358, chol=19.4, fat=5.43, cal=84.9
-- Our DB had: sodium=520 (41% too high), satfat=2.1 (45% too low)
UPDATE food_nutrition_overrides SET
    sodium_mg = 358,
    saturated_fat_g = 3.71,
    cholesterol_mg = 19.4,
    calories_per_100g = 84.9,
    fat_per_100g = 5.43,
    protein_per_100g = 3.71,
    carbs_per_100g = 6.2,
    fiber_per_100g = 2.0,
    updated_at = NOW()
WHERE id = 906;

-- Fix the Cup version (ID 907) proportionally
UPDATE food_nutrition_overrides SET
    sodium_mg = 358,
    saturated_fat_g = 3.71,
    cholesterol_mg = 19.4,
    updated_at = NOW()
WHERE id = 907;

-- 14. Five Guys Cheeseburger (ID 980)
-- Source: fastfoodnutrition.org - 303g(matches): 840cal, 55g fat, 27g satfat, 0g transfat, 165mg chol, 1050mg sodium
-- Per 100g: satfat=8.91, transfat=0, chol=54.5, sodium=346.5
-- Our DB had: chol=73.8 (35% too high), sodium=522.6 (51% too high!), satfat=7.26 (low)
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 54.5,
    sodium_mg = 346.5,
    saturated_fat_g = 8.91,
    trans_fat_g = 0,
    updated_at = NOW()
WHERE id = 980;

-- Fix Five Guys Little Cheeseburger (ID 981) and Bacon Cheeseburger (ID 982) proportionally
-- Little Cheeseburger: 610cal/193g -> sodium ~730mg/193g = 378.2
UPDATE food_nutrition_overrides SET
    sodium_mg = 378.2,
    saturated_fat_g = 7.25,
    trans_fat_g = 0,
    cholesterol_mg = 46.6,
    updated_at = NOW()
WHERE id = 981;

-- Bacon Cheeseburger: 920cal/317g, sodium 1310mg/317g = 413.2, satfat 30g/317g = 9.46
UPDATE food_nutrition_overrides SET
    sodium_mg = 413.2,
    saturated_fat_g = 9.46,
    trans_fat_g = 0,
    cholesterol_mg = 59.3,
    updated_at = NOW()
WHERE id = 982;

-- 15. KFC Original Recipe Chicken Breast (ID 848)
-- Source: fastfoodnutrition.org - 1 breast: 390cal, 21g fat, 4g satfat, 0g transfat, 120mg chol, 1190mg sodium
-- Using 161g (our DB): per 100g: satfat=2.48, chol=74.5, sodium=739.1
-- Our DB had: sodium=503 (32% too low!), satfat=4.17 (68% too high!), chol=51.3 (31% too low)
UPDATE food_nutrition_overrides SET
    sodium_mg = 739.1,
    saturated_fat_g = 2.48,
    cholesterol_mg = 74.5,
    trans_fat_g = 0,
    updated_at = NOW()
WHERE id = 848;


-- =============================================================================
-- SECTION 2: BRANDED ITEMS FIXES
-- =============================================================================

-- 16. Cheerios Original (ID 4141 - General Mills entry)
-- Source: USDA per 100g: Iron=30.9, VitC=23, VitD=200IU(5mcg), Calcium=368, Mag=130, Phos=387, Potassium=342
-- Cheerios nutrition label does NOT list significant Vitamin A (RAE)
-- Our DB had: iron=18 (low), vitC=6 (low), vitD=100 (low), vitA=150 (wrong)
UPDATE food_nutrition_overrides SET
    iron_mg = 30.9,
    vitamin_c_mg = 23,
    vitamin_d_iu = 200,
    vitamin_a_ug = 0,
    calcium_mg = 368,
    magnesium_mg = 130,
    phosphorus_mg = 387,
    potassium_mg = 342,
    updated_at = NOW()
WHERE id = 4141;

-- Also fix the duplicate Cheerios (Plain) entry (ID 3165)
UPDATE food_nutrition_overrides SET
    iron_mg = 30.9,
    vitamin_c_mg = 23,
    vitamin_d_iu = 200,
    vitamin_a_ug = 0,
    calcium_mg = 368,
    magnesium_mg = 130,
    phosphorus_mg = 387,
    potassium_mg = 342,
    updated_at = NOW()
WHERE id = 3165;

-- 17. Frosted Flakes (ID 3003)
-- Source: Kellogg's nutrition label per 37g serving: 130cal, Iron=7.2mg, VitA=33mcg, VitD=2mcg(80IU)
-- Per 100g: Iron=19.5, VitA=89mcg, VitD=216IU(5.4mcg)
-- Our DB had: iron=10.8 (45% low), vitA=150 (69% high), vitD=80 (63% low)
UPDATE food_nutrition_overrides SET
    iron_mg = 19.5,
    vitamin_a_ug = 89,
    vitamin_d_iu = 216,
    updated_at = NOW()
WHERE id = 3003;

-- 18. Quest Bar Chocolate Chip Cookie Dough (ID 4224)
-- Source: Quest Nutrition label per 60g bar: 190cal, 2.5g satfat, 5mg chol, 220mg sodium, Iron=0.6mg
-- Per 100g: satfat=4.17, chol=8.3, sodium=367, iron=1.0
-- Our DB had: satfat=2.5 (per 100g not per serving!), chol=15 (too high), sodium=300 (low), iron=2.5 (too high)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 4.17,
    cholesterol_mg = 8.3,
    sodium_mg = 367,
    iron_mg = 1.0,
    updated_at = NOW()
WHERE id = 4224;

-- Fix other Quest Bar variants with similar issues
-- Quest Bar Birthday Cake (ID 4225)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 3.33,
    cholesterol_mg = 8.3,
    iron_mg = 1.0,
    updated_at = NOW()
WHERE id = 4225;

-- Quest Bar Cookies & Cream (ID 4226)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 4.17,
    cholesterol_mg = 8.3,
    iron_mg = 1.0,
    updated_at = NOW()
WHERE id = 4226;

-- Quest Bar Peanut Butter (ID 4227)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 4.17,
    cholesterol_mg = 8.3,
    iron_mg = 1.0,
    updated_at = NOW()
WHERE id = 4227;

-- Quest Bar S'mores (ID 4228)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 3.33,
    cholesterol_mg = 8.3,
    iron_mg = 1.0,
    updated_at = NOW()
WHERE id = 4228;

-- Legacy Quest Bar entry (ID 3604)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 4.17,
    cholesterol_mg = 8.3,
    sodium_mg = 367,
    iron_mg = 1.0,
    updated_at = NOW()
WHERE id = 3604;

-- 19. Clif Bar Chocolate Chip (ID 3605)
-- Source: Clif Bar label per 68g: 250cal, 2g satfat, 0mg chol, 130mg sodium, Calcium=45mg, Iron=2mg
-- Per 100g: satfat=2.94, sodium=191.2, calcium=66.2, iron=2.94
-- Our DB had: satfat=1.5 (49% low), sodium=250 (31% high), calcium=250 (278% too high!), iron=4 (36% high)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 2.94,
    sodium_mg = 191.2,
    calcium_mg = 66.2,
    iron_mg = 2.94,
    updated_at = NOW()
WHERE id = 3605;

-- Fix other Clif Bar variants with similar calcium/satfat issues
-- Clif Bar Blueberry Crisp (ID 4250)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 2.21,
    sodium_mg = 191.2,
    calcium_mg = 66.2,
    iron_mg = 2.94,
    updated_at = NOW()
WHERE id = 4250;

-- Clif Bar Crunchy Peanut Butter (ID 4248)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 2.94,
    sodium_mg = 220.6,
    calcium_mg = 66.2,
    iron_mg = 2.94,
    updated_at = NOW()
WHERE id = 4248;

-- Clif Bar White Chocolate Macadamia (ID 4249)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 3.68,
    sodium_mg = 205.9,
    calcium_mg = 66.2,
    iron_mg = 2.94,
    updated_at = NOW()
WHERE id = 4249;

-- 20. Ben & Jerry's Half Baked (ID 3920)
-- Source: nutritionvalue.org per 100g: chol=57, satfat=7.6, sodium=62, cal=257
-- Our DB had: chol=35 (39% too low), satfat=8 (close), sodium=65 (close)
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 57,
    calories_per_100g = 257,
    saturated_fat_g = 7.6,
    trans_fat_g = 0,
    updated_at = NOW()
WHERE id = 3920;

-- 21. Lay's Classic Chips (ID 3616)
-- Source: Lay's label per 28g: 160cal, 1.5g satfat, 140mg sodium, Iron=0.6mg
-- Per 100g: satfat=5.36, iron=2.14
-- Our DB had: satfat=3 (44% low), iron=0.5 (77% low)
UPDATE food_nutrition_overrides SET
    saturated_fat_g = 5.36,
    iron_mg = 2.14,
    updated_at = NOW()
WHERE id = 3616;

-- 22. Doritos Nacho Cheese Tortilla Chips (ID 3614)
-- Source: Doritos label per 28g: 150cal, 1g satfat, 0mg chol, 210mg sodium, 50mg potassium
-- Per 100g: sodium=750, potassium=179, satfat=3.57, cal=536
-- Our DB had: sodium=500 (33% low), potassium=700 (291% too high!), satfat=2.5 (30% low), cal=500 (7% low)
UPDATE food_nutrition_overrides SET
    sodium_mg = 750,
    potassium_mg = 179,
    saturated_fat_g = 3.57,
    calories_per_100g = 536,
    updated_at = NOW()
WHERE id = 3614;

-- Also fix the legacy Doritos entry (ID 185) which had cholesterol=30 (should be 0)
UPDATE food_nutrition_overrides SET
    cholesterol_mg = 0,
    sodium_mg = 750,
    potassium_mg = 179,
    saturated_fat_g = 3.57,
    calories_per_100g = 536,
    updated_at = NOW()
WHERE id = 185;

-- 23. McDonald's French Fries Small (ID 644) - proportional sodium fix
-- Published fries are about 260mg sodium per 100g
UPDATE food_nutrition_overrides SET
    sodium_mg = 260,
    saturated_fat_g = 1.95,
    updated_at = NOW()
WHERE id = 644;

-- 24. McDonald's French Fries Medium (ID 109) - proportional sodium fix
UPDATE food_nutrition_overrides SET
    sodium_mg = 260,
    saturated_fat_g = 1.95,
    cholesterol_mg = 0,
    updated_at = NOW()
WHERE id = 109;

COMMIT;
