-- Migration 1909: Fix regional food names shadowing common English searches
-- Problem: Indian entries with region=NULL and English variant_names shadow
-- generic English entries (e.g., "coconut water" returns "Nariyal Paani")

-- Part A: Add 'coconut water' to the generic coconut_water entry's variant_names
-- so it wins exact variant matches before the Indian entry
UPDATE food_nutrition_overrides
SET variant_names = array_append(variant_names, 'coconut water')
WHERE food_name_normalized = 'coconut_water'
  AND NOT ('coconut water' = ANY(COALESCE(variant_names, '{}')));

-- Part B: Set region = 'IN' on Indian-specific entries that shadow common English terms
-- These entries have Hindi/regional display_names but 'coconut water', 'buttermilk' etc in variant_names
UPDATE food_nutrition_overrides
SET region = 'IN'
WHERE food_name_normalized IN (
    'generic_nariyal_paani',     -- shadows 'coconut water'
    'generic_chaas',             -- shadows 'Indian buttermilk', 'spiced buttermilk'
    'generic_haldi_doodh',       -- shadows 'turmeric milk', 'golden milk'
    'generic_aam_panna',         -- shadows 'raw mango drink'
    'generic_nimbu_pani',        -- shadows 'lemon water'
    'generic_salted_lassi',      -- shadows 'plain lassi'
    'generic_chivda'             -- shadows 'flattened rice mix'
)
AND (region IS NULL OR region = 'indian');

-- Also fix entries from migration 1003 (West Indian / Goan) that have the same issue
UPDATE food_nutrition_overrides
SET region = 'IN'
WHERE food_name_normalized IN (
    'chaas',                     -- shadows 'buttermilk'
    'haldi_doodh',               -- shadows 'turmeric milk', 'golden milk'
    'aam_panna',                 -- shadows 'raw mango drink'
    'nimbu_pani'                 -- shadows 'lime water'
)
AND (region IS NULL OR region = 'indian');

-- Part C: Remove 'buttermilk' from chaas variant_names since it's a fundamentally
-- different product (Indian spiced yogurt drink vs Western cultured buttermilk)
UPDATE food_nutrition_overrides
SET variant_names = array_remove(variant_names, 'buttermilk')
WHERE food_name_normalized = 'chaas'
  AND 'buttermilk' = ANY(COALESCE(variant_names, '{}'));

-- Part D: Add 'buttermilk' to the generic buttermilk entry if missing
UPDATE food_nutrition_overrides
SET variant_names = array_append(variant_names, 'buttermilk')
WHERE food_name_normalized = 'buttermilk'
  AND NOT ('buttermilk' = ANY(COALESCE(variant_names, '{}')));

-- ============================================================
-- Part E: Fix chole shadowing plain "chickpea"/"chickpeas"
-- Chole is a curry, NOT the same as plain cooked chickpeas.
-- Remove generic English chickpea terms from chole's variants.
-- ============================================================
UPDATE food_nutrition_overrides
SET variant_names = array_remove(array_remove(array_remove(array_remove(
    array_remove(variant_names, 'chickpea'), 'chickpeas'), 'cooked chickpea'),
    'boiled chickpea'), 'chickpeas cooked')
WHERE food_name_normalized = 'chole';

-- Part F: Set region='IN' on generic_roasted_chana (shadows "roasted chickpeas")
-- and add 'roasted chickpeas' to the generic roasted_chickpeas entry
UPDATE food_nutrition_overrides
SET region = 'IN'
WHERE food_name_normalized = 'generic_roasted_chana'
  AND region IS NULL;

UPDATE food_nutrition_overrides
SET variant_names = array_append(variant_names, 'roasted chickpeas')
WHERE food_name_normalized = 'roasted_chickpeas'
  AND NOT ('roasted chickpeas' = ANY(COALESCE(variant_names, '{}')));

-- Part G: Add 'naan bread' to the generic naan_bread entry so it wins over Indian naan
UPDATE food_nutrition_overrides
SET variant_names = array_append(variant_names, 'naan bread')
WHERE food_name_normalized = 'naan_bread'
  AND NOT ('naan bread' = ANY(COALESCE(variant_names, '{}')));

-- Part H: Add 'black beans' to the generic black_beans entry
-- so it wins over Taco Bell Black Beans for plain "black beans" search
UPDATE food_nutrition_overrides
SET variant_names = array_append(variant_names, 'black beans')
WHERE food_name_normalized = 'black_beans'
  AND NOT ('black beans' = ANY(COALESCE(variant_names, '{}')));

-- Part I: Set region='IN' on remaining Indian entries that shadow generic foods
-- via common English variant_names
UPDATE food_nutrition_overrides
SET region = 'IN'
WHERE food_name_normalized IN (
    'generic_kolkata_egg_roll',  -- shadows 'egg roll'
    'sweet_lassi',               -- shadows 'mango lassi' (1003)
    'lassi_sweet',               -- shadows 'lassi', 'yogurt drink sweet' (1001)
    'lassi_salted',              -- shadows 'buttermilk indian' (1001)
    'generic_salted_lassi'       -- shadows 'plain lassi' (1004, may already be IN)
)
AND region IS NULL;

-- Part J: Remove 'egg roll' from Kolkata Egg Roll since they are completely
-- different foods (Kolkata egg roll = paratha wrap vs Chinese egg roll = fried pastry)
UPDATE food_nutrition_overrides
SET variant_names = array_remove(variant_names, 'egg roll')
WHERE food_name_normalized = 'generic_kolkata_egg_roll'
  AND 'egg roll' = ANY(COALESCE(variant_names, '{}'));

-- Part K: Fix dal shadowing 'lentil soup' - dal is Indian lentils, not Western lentil soup
UPDATE food_nutrition_overrides
SET variant_names = array_remove(variant_names, 'lentil soup')
WHERE food_name_normalized = 'dal'
  AND 'lentil soup' = ANY(COALESCE(variant_names, '{}'));

-- Part L: Fix roti shadowing 'chapati' - keep 'chapati' on roti since they are
-- essentially the same food, but ensure generic chapati entry has its own variant
UPDATE food_nutrition_overrides
SET variant_names = array_append(variant_names, 'chapati')
WHERE food_name_normalized = 'chapati'
  AND NOT ('chapati' = ANY(COALESCE(variant_names, '{}')));
