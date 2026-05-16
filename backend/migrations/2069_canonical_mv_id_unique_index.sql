-- 2069_canonical_mv_id_unique_index.sql
--
-- Fix-up for migration 2065. REFRESH MATERIALIZED VIEW CONCURRENTLY requires
-- a unique index that uses only plain column references — not functional
-- expressions like COALESCE(restaurant_name, ''). The index 2065 created on
-- (food_name_normalized, display_name, COALESCE(restaurant_name, '')) is
-- valid for query planning but not accepted by the CONCURRENTLY refresh
-- path.
--
-- food_nutrition_overrides_canonical preserves base-table id (DISTINCT ON
-- keeps one row per dedup key, each kept row has its own id). So a UNIQUE
-- INDEX on id alone is the simplest and CONCURRENTLY-safe fix.

CREATE UNIQUE INDEX IF NOT EXISTS idx_food_canonical_id_pk
  ON food_nutrition_overrides_canonical (id);
