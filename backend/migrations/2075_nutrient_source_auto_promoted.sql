-- 2075_nutrient_source_auto_promoted.sql
--
-- Extends the food_nutrition_overrides.nutrient_source CHECK constraint
-- (originally added in mig 2072) to allow 'auto_promoted' — the value the
-- §2.10 promotion job stamps on rows it elevates from
-- food_overrides_user_contributed.
--
-- Adds auto_promoted_at TIMESTAMPTZ for backout safety per §G3 in the plan:
--   UPDATE food_nutrition_overrides
--   SET nutrient_source='gemini_estimate'
--   WHERE auto_promoted_at IS NOT NULL;
-- if a promotion goes wrong.
--
-- The runtime canonical lookup keeps the existing source priority
-- (manual > usda_fdc > gemini_estimate > auto_promoted) for tie-breaking
-- via the source ORDER BY in food_nutrition_overrides_canonical (mig 2071).
-- Update the canonical view's CASE statement to include auto_promoted.

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS auto_promoted_at TIMESTAMPTZ;

ALTER TABLE food_nutrition_overrides
  DROP CONSTRAINT IF EXISTS food_overrides_nutrient_source_enum;

ALTER TABLE food_nutrition_overrides
  ADD CONSTRAINT food_overrides_nutrient_source_enum
  CHECK (nutrient_source IS NULL OR nutrient_source IN
    ('usda_fdc', 'gemini_estimate', 'manual', 'auto_promoted'));

-- Rebuild canonical view with extended source priority. Lower number wins
-- via DISTINCT ON. Auto-promoted entries are LAST priority because they're
-- aggregated estimates, not lab-measured.
DROP VIEW IF EXISTS food_nutrition_overrides_canonical CASCADE;

CREATE VIEW food_nutrition_overrides_canonical AS
SELECT DISTINCT ON (food_name_normalized, display_name, COALESCE(restaurant_name, ''))
  id, food_name_normalized, display_name, restaurant_name, food_category,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g, default_weight_per_piece_g, default_serving_g,
  default_count, is_countable, variant_names, region, country_name,
  inflammation_score, inflammation_triggers, glycemic_load, fodmap_rating,
  fodmap_reason, added_sugar_g, is_ultra_processed, rating, rating_reason,
  -- 29 micronutrient cols
  saturated_fat_g, trans_fat_g, cholesterol_mg,
  sodium_mg, potassium_mg, calcium_mg, iron_mg, magnesium_mg,
  zinc_mg, phosphorus_mg, selenium_ug, copper_mg, manganese_mg,
  vitamin_a_ug, vitamin_c_mg, vitamin_d_iu, vitamin_e_mg, vitamin_k_ug,
  vitamin_b1_mg, vitamin_b2_mg, vitamin_b3_mg, vitamin_b5_mg,
  vitamin_b6_mg, vitamin_b7_ug, vitamin_b9_ug, vitamin_b12_ug,
  choline_mg, omega3_g, omega6_g,
  source, nutrient_source
FROM food_nutrition_overrides
WHERE is_active = TRUE
ORDER BY
  food_name_normalized,
  display_name,
  COALESCE(restaurant_name, ''),
  -- Tiebreak when multiple rows share the dedup key. Lower wins.
  -- Original `source` priority preserved; nutrient_source only acts as
  -- a secondary signal when both rows have the same `source`.
  CASE source
    WHEN 'usda_foundation' THEN 1
    WHEN 'usda_sr'         THEN 2
    WHEN 'usda_survey'     THEN 3
    WHEN 'restaurant'      THEN 4
    WHEN 'regional'        THEN 5
    ELSE 6
  END,
  CASE nutrient_source
    WHEN 'manual'          THEN 1
    WHEN 'usda_fdc'        THEN 2
    WHEN 'gemini_estimate' THEN 3
    WHEN 'auto_promoted'   THEN 4
    ELSE 5
  END;

-- Refresh function stays a no-op (mig 2071 made the view non-materialized).
CREATE OR REPLACE FUNCTION refresh_food_nutrition_canonical()
RETURNS void
LANGUAGE sql
AS $$ SELECT 1; $$;

COMMENT ON COLUMN food_nutrition_overrides.auto_promoted_at IS
  'Timestamp set by promote_user_contributed.py when this row was promoted from food_overrides_user_contributed. NULL for never-promoted rows. Backout: UPDATE ... SET nutrient_source=gemini_estimate WHERE auto_promoted_at IS NOT NULL.';
