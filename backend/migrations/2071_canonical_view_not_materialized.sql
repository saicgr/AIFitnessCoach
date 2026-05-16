-- 2071_canonical_view_not_materialized.sql
--
-- Supersedes 2065 + 2069. Converts food_nutrition_overrides_canonical from
-- a MATERIALIZED VIEW to a regular VIEW.
--
-- Rationale (discovered 2026-05-13 during smoke audit):
--   1. The base table is 100% unique on (food_name_normalized, display_name,
--      restaurant_name) — the strict dedup collapsed 0 rows, so the MV is
--      a 1:1 copy of the base table for our data.
--   2. The base table already carries trigram (gin_trgm_ops) + GIN array
--      indexes on food_name_normalized + variant_names. The MV had no
--      query-performance benefit over WHERE is_active=TRUE on the base.
--   3. REFRESH MATERIALIZED VIEW CONCURRENTLY on 198k rows takes 10+ min
--      and is fragile: if the script that called it gets killed mid-refresh,
--      the MV stays frozen at its previous snapshot. This bit us during the
--      overnight enrichment backfill — base table had 187k rows enriched but
--      the MV showed only 196 (the smoke-test state from before the run).
--
-- A regular VIEW resolves at query time → always reflects base-table truth.
-- No refresh needed. The DISTINCT ON dedup logic is preserved — it's just
-- evaluated lazily per query instead of materialized into a snapshot.
--
-- The downstream lookup hot path uses
-- FoodDatabaseLookupService.batch_lookup_foods which queries by indexed
-- columns, so view-vs-MV makes no measurable runtime difference.

DROP MATERIALIZED VIEW IF EXISTS food_nutrition_overrides_canonical CASCADE;

CREATE VIEW food_nutrition_overrides_canonical AS
SELECT DISTINCT ON (food_name_normalized, display_name, COALESCE(restaurant_name, ''))
  id, food_name_normalized, display_name, restaurant_name, food_category,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g, default_weight_per_piece_g, default_serving_g,
  default_count, is_countable, variant_names, region, country_name,
  inflammation_score, inflammation_triggers, glycemic_load, fodmap_rating,
  fodmap_reason, added_sugar_g, is_ultra_processed, rating, rating_reason,
  source
FROM food_nutrition_overrides
WHERE is_active = TRUE
ORDER BY food_name_normalized, display_name, COALESCE(restaurant_name, ''),
  CASE source
    WHEN 'usda_foundation' THEN 1
    WHEN 'usda_sr'         THEN 2
    WHEN 'usda_survey'     THEN 3
    WHEN 'restaurant'      THEN 4
    WHEN 'regional'        THEN 5
    ELSE 6
  END;

-- Backwards-compatibility no-op. Anything (script, code, cron) that calls
-- refresh_food_nutrition_canonical() keeps working but does nothing.
CREATE OR REPLACE FUNCTION refresh_food_nutrition_canonical()
RETURNS void
LANGUAGE sql
AS $$ SELECT 1; $$;

COMMENT ON VIEW food_nutrition_overrides_canonical IS
  'Live view (not materialized) over food_nutrition_overrides. Resolves at query time so writes to the base table are immediately visible — no refresh needed.';
