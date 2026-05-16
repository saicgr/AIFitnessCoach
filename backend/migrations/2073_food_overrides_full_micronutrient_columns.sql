-- 2073_food_overrides_full_micronutrient_columns.sql
--
-- Adds the 14 micronutrient columns that exist on the food_log table (via
-- the _SCORE_COLUMNS list in food_score_enrichment.py) but were never added
-- to food_nutrition_overrides. This brings the override table to full
-- micronutrient parity so the backfill script can populate everything and
-- the runtime food-log enrichment can read from the cache without falling
-- back to Gemini for any column.
--
-- Columns added (per 100g of food):
--   * Vitamin E (mg), Vitamin K (μg)
--   * 8 B-vitamins (B1 thiamin, B2 riboflavin, B3 niacin, B5 pantothenic acid,
--     B6, B7 biotin, B9 folate, B12)
--   * Copper (mg), Manganese (mg)
--   * Choline (mg)
--   * Omega-6 (g)

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS vitamin_e_mg   REAL,
  ADD COLUMN IF NOT EXISTS vitamin_k_ug   REAL,
  ADD COLUMN IF NOT EXISTS vitamin_b1_mg  REAL,  -- thiamin
  ADD COLUMN IF NOT EXISTS vitamin_b2_mg  REAL,  -- riboflavin
  ADD COLUMN IF NOT EXISTS vitamin_b3_mg  REAL,  -- niacin
  ADD COLUMN IF NOT EXISTS vitamin_b5_mg  REAL,  -- pantothenic acid
  ADD COLUMN IF NOT EXISTS vitamin_b6_mg  REAL,
  ADD COLUMN IF NOT EXISTS vitamin_b7_ug  REAL,  -- biotin
  ADD COLUMN IF NOT EXISTS vitamin_b9_ug  REAL,  -- folate
  ADD COLUMN IF NOT EXISTS vitamin_b12_ug REAL,
  ADD COLUMN IF NOT EXISTS copper_mg      REAL,
  ADD COLUMN IF NOT EXISTS manganese_mg   REAL,
  ADD COLUMN IF NOT EXISTS choline_mg     REAL,
  ADD COLUMN IF NOT EXISTS omega6_g       REAL;

COMMENT ON COLUMN food_nutrition_overrides.vitamin_b9_ug IS
  'Folate (vitamin B9), per 100g, in micrograms.';
COMMENT ON COLUMN food_nutrition_overrides.vitamin_b7_ug IS
  'Biotin (vitamin B7), per 100g, in micrograms.';
COMMENT ON COLUMN food_nutrition_overrides.choline_mg IS
  'Total choline per 100g, in milligrams. Egg yolk ~820, beef liver ~333.';
