-- 2060_food_overrides_is_countable.sql
--
-- Layer 2 of the 3-layer portion-validation defense (added 2026-05-11 after
-- the "blueberries 99 × 148g = 8316 kcal" incident). Adds a generated
-- is_countable flag to food_nutrition_overrides so reconcile_with_db() can
-- distinguish whole-unit foods (egg, banana — 1 piece ≈ 1 serving) from
-- truly small countable pieces (blueberry — many pieces per serving).
--
-- NOTE: this table uses `default_serving_g`, not `serving_size_g`. The spec
-- mentions a fallback to whichever name actually exists; here it's
-- default_serving_g.

ALTER TABLE food_nutrition_overrides
  ADD COLUMN IF NOT EXISTS is_countable BOOLEAN
  GENERATED ALWAYS AS (
    default_count IS NOT NULL AND default_count > 1
    AND default_weight_per_piece_g IS NOT NULL
    AND default_serving_g IS NOT NULL
    AND default_weight_per_piece_g < (default_serving_g * 0.5)
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_food_overrides_is_countable
  ON food_nutrition_overrides(is_countable) WHERE is_countable = TRUE;

COMMENT ON COLUMN food_nutrition_overrides.default_count IS
  'Pieces per serving (NOT pieces per meal). Used to detect truly-countable foods.';
COMMENT ON COLUMN food_nutrition_overrides.is_countable IS
  'GENERATED. True iff this food is small/numerous enough that count*piece_weight makes sense (berries) vs whole-unit (egg/banana).';
