-- 2065_food_overrides_canonical_mv.sql
--
-- Phase 1 of the food-scan latency cut. Builds a deduplicated materialized
-- view over food_nutrition_overrides so the runtime lookup hits a smaller
-- working set and benefits from a per-canonical-name unique constraint.
--
-- Dedup policy (locked with user 2026-05-13): STRICT — only collapse when
-- (food_name_normalized, display_name, restaurant_name) are all identical.
-- This preserves regional recipe variants (Pakistani / Hyderabadi / Kerala
-- biryani all keep distinct rows) and only collapses true duplicates that
-- exist because the same recipe was listed in 5 different country override
-- files (e.g. McDonald's Big Mac across IN/US/UK/AU).
--
-- Pattern matches exercise_library_cleaned MV (see project memory). Refresh
-- via refresh_food_nutrition_canonical() after any bulk write to the base
-- table — the backfill script calls this at completion.

DROP MATERIALIZED VIEW IF EXISTS food_nutrition_overrides_canonical CASCADE;

CREATE MATERIALIZED VIEW food_nutrition_overrides_canonical AS
SELECT DISTINCT ON (food_name_normalized, display_name, COALESCE(restaurant_name, ''))
  id,
  food_name_normalized,
  display_name,
  restaurant_name,
  food_category,
  calories_per_100g,
  protein_per_100g,
  carbs_per_100g,
  fat_per_100g,
  fiber_per_100g,
  sugar_per_100g,
  default_weight_per_piece_g,
  default_serving_g,
  default_count,
  is_countable,
  variant_names,
  region,
  country_name,
  -- Phase-1 enrichment columns (NULL until backfill completes; the runtime
  -- read path falls back to a runtime Gemini enrichment call on NULL).
  inflammation_score,
  inflammation_triggers,
  glycemic_load,
  fodmap_rating,
  fodmap_reason,
  added_sugar_g,
  is_ultra_processed,
  rating,
  rating_reason,
  source
FROM food_nutrition_overrides
WHERE is_active = TRUE
ORDER BY
  food_name_normalized,
  display_name,
  COALESCE(restaurant_name, ''),
  -- Tiebreak: prefer authoritative sources first when two rows are otherwise
  -- identical on the dedup key. Lower number wins (DISTINCT ON keeps the
  -- first row per group).
  CASE source
    WHEN 'usda_foundation' THEN 1
    WHEN 'usda_sr'         THEN 2
    WHEN 'usda_survey'     THEN 3
    WHEN 'restaurant'      THEN 4
    WHEN 'regional'        THEN 5
    ELSE 6
  END;

-- Unique index is REQUIRED for REFRESH MATERIALIZED VIEW CONCURRENTLY.
CREATE UNIQUE INDEX idx_food_canonical_pk
  ON food_nutrition_overrides_canonical
  (food_name_normalized, display_name, (COALESCE(restaurant_name, '')));

CREATE INDEX idx_food_canonical_name_normalized
  ON food_nutrition_overrides_canonical (food_name_normalized);

CREATE INDEX idx_food_canonical_name_trgm
  ON food_nutrition_overrides_canonical
  USING gin (food_name_normalized gin_trgm_ops);

CREATE INDEX idx_food_canonical_display_trgm
  ON food_nutrition_overrides_canonical
  USING gin (display_name gin_trgm_ops);

CREATE INDEX idx_food_canonical_variants
  ON food_nutrition_overrides_canonical
  USING gin (variant_names);

CREATE INDEX idx_food_canonical_restaurant
  ON food_nutrition_overrides_canonical (restaurant_name)
  WHERE restaurant_name IS NOT NULL;

-- Refresh helper. CONCURRENTLY requires the unique index above. Use this
-- after the backfill or after any large change to food_nutrition_overrides.
CREATE OR REPLACE FUNCTION refresh_food_nutrition_canonical()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY food_nutrition_overrides_canonical;
END;
$$;

COMMENT ON MATERIALIZED VIEW food_nutrition_overrides_canonical IS
  'Phase-1 dedup view over food_nutrition_overrides. Strict policy: collapses true duplicates only. Refresh via refresh_food_nutrition_canonical().';
