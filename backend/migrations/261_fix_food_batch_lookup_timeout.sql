-- Migration: 261_fix_food_batch_lookup_timeout.sql
-- Description: Fix batch_lookup_foods timeout by adding statement_timeout
--              and removing slow ILIKE fallbacks that bypass GIN trigram indexes
-- Created: 2026-02-17

-- ============================================================================
-- FUNCTION: batch_lookup_foods (updated)
-- Changes:
--   1. Added function-level SET statement_timeout = '5000' (5s max)
--   2. Removed ILIKE '%..%' fallbacks in WHERE clauses (bypass GIN index)
--   3. Simplified ORDER BY to use similarity() only (no ILIKE-based CASE)
-- ============================================================================

CREATE OR REPLACE FUNCTION batch_lookup_foods(
    food_names TEXT[]
)
RETURNS TABLE (
    input_name TEXT,
    matched_id BIGINT,
    matched_name TEXT,
    source TEXT,
    calories_per_100g REAL,
    protein_per_100g REAL,
    fat_per_100g REAL,
    carbs_per_100g REAL,
    fiber_per_100g REAL,
    similarity_score REAL
)
AS $$
BEGIN
    -- Set trigram similarity threshold for % operator (uses GIN index)
    PERFORM set_config('pg_trgm.similarity_threshold', '0.15', TRUE);

    -- Two-pass approach for performance:
    -- Pass 1: name_normalized matches (fast, uses existing GIN index)
    -- Pass 2: variant_text matches for items with no name match (small partial index)
    RETURN QUERY
    WITH name_matches AS (
        SELECT
            input.name AS inp_name,
            best.id,
            best.name,
            best.source,
            best.calories_per_100g,
            best.protein_per_100g,
            best.fat_per_100g,
            best.carbs_per_100g,
            best.fiber_per_100g,
            best.sim
        FROM unnest(food_names) AS input(name)
        LEFT JOIN LATERAL (
            SELECT
                f.id,
                f.name,
                f.source,
                f.calories_per_100g,
                f.protein_per_100g,
                f.fat_per_100g,
                f.carbs_per_100g,
                f.fiber_per_100g,
                similarity(f.name_normalized, LOWER(TRIM(input.name))) AS sim
            FROM food_database_deduped f
            WHERE
                f.name_normalized % LOWER(TRIM(input.name))
            ORDER BY
                CASE
                    WHEN f.name_normalized = LOWER(TRIM(input.name)) THEN 0
                    ELSE 1
                END,
                similarity(f.name_normalized, LOWER(TRIM(input.name))) DESC
            LIMIT 1
        ) best ON TRUE
    ),
    -- Pass 2: variant matches only for items with no name match
    variant_matches AS (
        SELECT
            nm.inp_name,
            vbest.id,
            vbest.name,
            vbest.source,
            vbest.calories_per_100g,
            vbest.protein_per_100g,
            vbest.fat_per_100g,
            vbest.carbs_per_100g,
            vbest.fiber_per_100g,
            vbest.sim
        FROM name_matches nm
        LEFT JOIN LATERAL (
            SELECT
                f.id,
                f.name,
                f.source,
                f.calories_per_100g,
                f.protein_per_100g,
                f.fat_per_100g,
                f.carbs_per_100g,
                f.fiber_per_100g,
                similarity(f.variant_text, LOWER(TRIM(nm.inp_name))) AS sim
            FROM food_database_deduped f
            WHERE
                f.variant_text IS NOT NULL
                AND f.variant_text % LOWER(TRIM(nm.inp_name))
            ORDER BY
                similarity(f.variant_text, LOWER(TRIM(nm.inp_name))) DESC
            LIMIT 1
        ) vbest ON TRUE
        WHERE nm.id IS NULL  -- only for items with no name match
    )
    -- Combine: use name match if found, otherwise variant match
    SELECT
        nm.inp_name AS input_name,
        COALESCE(nm.id, vm.id) AS matched_id,
        COALESCE(nm.name, vm.name) AS matched_name,
        COALESCE(nm.source, vm.source) AS source,
        COALESCE(nm.calories_per_100g, vm.calories_per_100g) AS calories_per_100g,
        COALESCE(nm.protein_per_100g, vm.protein_per_100g) AS protein_per_100g,
        COALESCE(nm.fat_per_100g, vm.fat_per_100g) AS fat_per_100g,
        COALESCE(nm.carbs_per_100g, vm.carbs_per_100g) AS carbs_per_100g,
        COALESCE(nm.fiber_per_100g, vm.fiber_per_100g) AS fiber_per_100g,
        COALESCE(nm.sim, vm.sim) AS similarity_score
    FROM name_matches nm
    LEFT JOIN variant_matches vm ON nm.inp_name = vm.inp_name;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = public
SET statement_timeout = '5000';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
