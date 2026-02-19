-- Migration 261: Fix search_food_database statement timeout
-- Root cause: PostgREST sets `SET LOCAL statement_timeout = '3000'` for the anon
--   role BEFORE calling the function. The function-level `SET statement_timeout`
--   does NOT override this for SECURITY INVOKER functions. Combined with cold-cache
--   disk reads (10K+ pages for GIN bitmap recheck), queries exceed 3s easily.
-- Fix:
--   1. SECURITY DEFINER — runs as function owner, not anon. The function's own
--      SET statement_timeout = '8000' now takes effect. Also bypasses RLS overhead.
--   2. Explicit SET LOCAL statement_timeout inside function body (belt-and-suspenders)
--   3. Threshold 0.15 (not 0.1) — reduces GIN false positives (40K→fewer candidates)
--   4. Removed ILIKE fallbacks (from prior version) that caused sequential scans
-- Created: 2026-02-19

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
BEGIN
    normalized_query := LOWER(TRIM(search_query));

    -- Override PostgREST's anon role 3s timeout (SET LOCAL inside DEFINER function)
    PERFORM set_config('statement_timeout', '8000', TRUE);

    -- Set trigram similarity threshold for % operator (uses GIN index)
    -- 0.15 balances typo tolerance vs GIN candidate volume
    PERFORM set_config('pg_trgm.similarity_threshold', '0.15', TRUE);

    RETURN QUERY
    SELECT
        f.id,
        f.name,
        f.source,
        f.brand,
        f.category,
        f.calories_per_100g,
        f.protein_per_100g,
        f.fat_per_100g,
        f.carbs_per_100g,
        f.fiber_per_100g,
        f.sugar_per_100g,
        f.serving_description,
        f.serving_weight_g,
        GREATEST(
            similarity(f.name_normalized, normalized_query),
            COALESCE(similarity(f.variant_text, normalized_query), 0)
        ) AS similarity_score
    FROM food_database f
    WHERE
        f.is_primary = TRUE
        AND (
            -- Trigram similarity on name (uses GIN index via % operator)
            f.name_normalized % normalized_query
            -- OR trigram similarity on variant spellings (uses partial GIN index)
            OR (f.variant_text IS NOT NULL AND f.variant_text % normalized_query)
        )
    ORDER BY
        -- Exact / prefix matches first
        CASE
            WHEN f.name_normalized = normalized_query THEN 0
            WHEN f.name_normalized LIKE normalized_query || '%' THEN 1
            ELSE 2
        END,
        -- Then by best similarity score
        GREATEST(
            similarity(f.name_normalized, normalized_query),
            COALESCE(similarity(f.variant_text, normalized_query), 0)
        ) DESC,
        -- Prefer items with serving info
        CASE WHEN f.serving_weight_g IS NOT NULL THEN 0 ELSE 1 END,
        f.name ASC
    LIMIT result_limit
    OFFSET result_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET statement_timeout = '8000';

COMMENT ON FUNCTION search_food_database IS
  'Fuzzy food search using trigram similarity on food_database. '
  'SECURITY DEFINER to override PostgREST anon role 3s statement_timeout. '
  'Returns ranked results with nutrient data. 8s timeout.';
