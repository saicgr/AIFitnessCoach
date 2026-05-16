-- 2072_micronutrients_tracking.sql
--
-- Adds tracking columns for the micronutrient backfill pipeline (USDA → Gemini
-- hybrid). Mirrors the enrichment-attempts pattern from migration 2070 but
-- uses separate columns so the two pipelines can run in parallel against the
-- same rows without conflicting.
--
-- nutrient_source documents WHERE each row's micronutrient values came from,
-- so the app UI can later show "verified by USDA" vs "AI-estimated" badges
-- on detailed nutrition views. The 'manual' value covers the legacy
-- ~8,463 rows seeded from the original USDA import.

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS nutrient_source TEXT,
  ADD COLUMN IF NOT EXISTS micronutrients_backfilled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS micronutrients_attempts SMALLINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS micronutrients_last_violation TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'food_overrides_nutrient_source_enum'
  ) THEN
    ALTER TABLE food_nutrition_overrides
      ADD CONSTRAINT food_overrides_nutrient_source_enum
      CHECK (nutrient_source IS NULL OR nutrient_source IN
        ('usda_fdc', 'gemini_estimate', 'manual'));
  END IF;
END $$;

-- Backfill nutrient_source='manual' for the legacy ~8,463 rows that already
-- have sodium_mg populated (the original USDA seed before Mig 324 added the
-- columns systematically). Gives us a clean source label across the table.
UPDATE food_nutrition_overrides
SET nutrient_source = 'manual',
    micronutrients_backfilled_at = COALESCE(micronutrients_backfilled_at, NOW())
WHERE nutrient_source IS NULL
  AND sodium_mg IS NOT NULL;

-- Retry filter: pending if no source set yet AND attempts under cap.
CREATE INDEX IF NOT EXISTS idx_food_overrides_micronutrients_retryable
  ON food_nutrition_overrides(id)
  WHERE nutrient_source IS NULL AND micronutrients_attempts < 3;

CREATE INDEX IF NOT EXISTS idx_food_overrides_micronutrients_exhausted
  ON food_nutrition_overrides(id)
  WHERE nutrient_source IS NULL AND micronutrients_attempts >= 3;

COMMENT ON COLUMN food_nutrition_overrides.nutrient_source IS
  'Provenance of the micronutrient values. usda_fdc = lab-measured from USDA FoodData Central, gemini_estimate = AI-estimated, manual = legacy seed.';
COMMENT ON COLUMN food_nutrition_overrides.micronutrients_attempts IS
  'Number of micronutrient backfill attempts. Capped at 3 by the backfill fetch query — rows at 3 are parked for human review or pipeline change.';
COMMENT ON COLUMN food_nutrition_overrides.micronutrients_last_violation IS
  'Concatenated validator findings from the most recent attempt. NULL when last write passed validation.';
