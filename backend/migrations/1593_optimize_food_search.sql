-- Migration 1593: Optimize search_food_database performance
-- Root cause: GIN trigram indexes cover all 718K rows (including non-primary),
-- returning 100K-228K false-positive candidates. Combined with 2MB work_mem,
-- bitmap scans go lossy (page-level instead of row-level), forcing 50K+ buffer
-- reads. Short queries like "fred" produce few trigrams that match very broadly.
--
-- Fixes:
--   1. Partial GIN indexes filtered to is_primary = TRUE (fewer candidates)
--   2. work_mem = 16MB inside RPC (prevents lossy bitmap scans)
--   3. Prefix fast-path: LIKE query first, skip trigram if enough results
--   4. Raise threshold to 0.2 (fewer GIN candidates, negligible quality loss)

-- ============================================================================
-- Fix 1: Partial GIN trigram indexes (is_primary = TRUE only)
-- ============================================================================

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_name_trgm_primary
ON food_database USING gin (name_normalized gin_trgm_ops)
WHERE is_primary = TRUE;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_variant_trgm_primary
ON food_database USING gin (variant_text gin_trgm_ops)
WHERE is_primary = TRUE AND variant_text IS NOT NULL;

-- Drop the old unfiltered indexes (planner will prefer the partials)
DROP INDEX CONCURRENTLY IF EXISTS idx_food_database_name_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_food_database_variant_text_trgm;

-- ============================================================================
-- Fix 2+3+4: Rewrite search_food_database with work_mem, prefix fast-path
-- ============================================================================

-- Must DROP first because we're changing return type from prior version
-- (adding name_normalized wasn't in original, but safe to recreate)
DROP FUNCTION IF EXISTS search_food_database(TEXT, INT, INT);

CREATE OR REPLACE FUNCTION search_food_database(
    search_query TEXT,
    result_limit INT DEFAULT 20,
    result_offset INT DEFAULT 0
)
RETURNS TABLE (
    id BIGINT,
    name TEXT,
    source TEXT,
    brand TEXT,
    category TEXT,
    calories_per_100g REAL,
    protein_per_100g REAL,
    fat_per_100g REAL,
    carbs_per_100g REAL,
    fiber_per_100g REAL,
    sugar_per_100g REAL,
    serving_description TEXT,
    serving_weight_g REAL,
    similarity_score REAL
)
AS $$
DECLARE
    normalized_query TEXT;
    prefix_count INT;
BEGIN
    normalized_query := LOWER(TRIM(search_query));

    -- Override PostgREST's anon role 3s timeout
    PERFORM set_config('statement_timeout', '8000', TRUE);

    -- Prevent lossy bitmap scans (default 2MB is too low for 500K+ row table)
    PERFORM set_config('work_mem', '16MB', TRUE);

    -- Fast path: try prefix match first (uses btree index, <10ms)
    -- If we get enough results, skip the expensive trigram scan entirely
    SELECT count(*) INTO prefix_count
    FROM food_database f
    WHERE f.is_primary = TRUE
      AND f.name_normalized LIKE normalized_query || '%'
    LIMIT result_limit;

    IF prefix_count >= result_limit THEN
        RETURN QUERY
        SELECT
            f.id, f.name, f.source, f.brand, f.category,
            f.calories_per_100g, f.protein_per_100g, f.fat_per_100g,
            f.carbs_per_100g, f.fiber_per_100g, f.sugar_per_100g,
            f.serving_description, f.serving_weight_g,
            1.0::REAL AS similarity_score
        FROM food_database f
        WHERE f.is_primary = TRUE
          AND f.name_normalized LIKE normalized_query || '%'
        ORDER BY
            CASE WHEN f.name_normalized = normalized_query THEN 0 ELSE 1 END,
            length(f.name_normalized) ASC,
            f.name ASC
        LIMIT result_limit
        OFFSET result_offset;
        RETURN;
    END IF;

    -- Trigram similarity threshold - 0.2 balances quality vs candidate volume
    PERFORM set_config('pg_trgm.similarity_threshold', '0.2', TRUE);

    RETURN QUERY
    SELECT
        f.id, f.name, f.source, f.brand, f.category,
        f.calories_per_100g, f.protein_per_100g, f.fat_per_100g,
        f.carbs_per_100g, f.fiber_per_100g, f.sugar_per_100g,
        f.serving_description, f.serving_weight_g,
        GREATEST(
            similarity(f.name_normalized, normalized_query),
            COALESCE(similarity(f.variant_text, normalized_query), 0)
        ) AS similarity_score
    FROM food_database f
    WHERE
        f.is_primary = TRUE
        AND (
            f.name_normalized % normalized_query
            OR (f.variant_text IS NOT NULL AND f.variant_text % normalized_query)
        )
    ORDER BY
        CASE
            WHEN f.name_normalized = normalized_query THEN 0
            WHEN f.name_normalized LIKE normalized_query || '%' THEN 1
            ELSE 2
        END,
        GREATEST(
            similarity(f.name_normalized, normalized_query),
            COALESCE(similarity(f.variant_text, normalized_query), 0)
        ) DESC,
        CASE WHEN f.serving_weight_g IS NOT NULL THEN 0 ELSE 1 END,
        f.name ASC
    LIMIT result_limit
    OFFSET result_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET statement_timeout = '8000';

COMMENT ON FUNCTION search_food_database IS
  'Fuzzy food search with prefix fast-path + trigram fallback. '
  'Uses partial GIN indexes (is_primary only). 16MB work_mem to prevent lossy bitmaps. '
  'SECURITY DEFINER to override PostgREST anon timeout.';

GRANT EXECUTE ON FUNCTION search_food_database(TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_food_database(TEXT, INT, INT) TO service_role;
