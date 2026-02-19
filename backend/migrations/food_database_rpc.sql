-- Migration: food_database_rpc.sql
-- Description: RPC functions for food database search + food_reports table
-- Created: 2026-02-15
--
-- Prerequisites:
--   - food_database table with columns: id, name, name_normalized, source, source_id,
--     data_type, brand, category, food_group, calories_per_100g, protein_per_100g,
--     fat_per_100g, carbs_per_100g, fiber_per_100g, sugar_per_100g, serving_description,
--     serving_weight_g, calories_per_serving, protein_per_serving, fat_per_serving,
--     carbs_per_serving, allergens, diet_labels, nova_group, nutriscore_score, image_url,
--     inflammatory_score, inflammatory_category, dedup_key, dedup_rank, is_primary,
--     variant_names, variant_text
--   - food_database_deduped view = SELECT * FROM food_database WHERE is_primary = TRUE
--   - GIN trigram index: idx_food_database_name_trgm ON food_database USING GIN (name_normalized gin_trgm_ops)
--   - GIN trigram index: idx_food_database_variant_text_trgm ON food_database USING GIN (variant_text gin_trgm_ops) WHERE variant_text IS NOT NULL
--   - pg_trgm extension enabled

-- ============================================================================
-- FUNCTION 1: search_food_database
-- Single food search with trigram similarity ranking
-- ============================================================================

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

COMMENT ON FUNCTION search_food_database IS 'Fuzzy food search using trigram similarity on food_database_deduped view. Returns ranked results with nutrient data.';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION search_food_database(TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_food_database(TEXT, INT, INT) TO service_role;


-- ============================================================================
-- FUNCTION 2: batch_lookup_foods
-- Batch food name lookup using LATERAL JOIN for best match per input name
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

COMMENT ON FUNCTION batch_lookup_foods IS 'Batch food lookup: takes array of food names, returns best match for each. Uses two-pass approach: name_normalized first, then variant_text for misses. 5s timeout.';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION batch_lookup_foods(TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION batch_lookup_foods(TEXT[]) TO service_role;


-- ============================================================================
-- TABLE: food_reports
-- User-submitted reports for incorrect food nutrition data
-- ============================================================================

CREATE TABLE IF NOT EXISTS food_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    food_database_id BIGINT REFERENCES food_database(id) ON DELETE SET NULL,
    food_name TEXT NOT NULL,
    reported_issue TEXT,
    original_calories REAL,
    original_protein REAL,
    original_carbs REAL,
    original_fat REAL,
    corrected_calories REAL,
    corrected_protein REAL,
    corrected_carbs REAL,
    corrected_fat REAL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'reviewed',
        'resolved',
        'dismissed'
    )),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_food_reports_user_id
    ON food_reports(user_id);

CREATE INDEX IF NOT EXISTS idx_food_reports_status
    ON food_reports(status);

CREATE INDEX IF NOT EXISTS idx_food_reports_food_database_id
    ON food_reports(food_database_id);

CREATE INDEX IF NOT EXISTS idx_food_reports_created_at
    ON food_reports(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE food_reports ENABLE ROW LEVEL SECURITY;

-- Users can insert their own reports
DROP POLICY IF EXISTS "Users can create own food reports" ON food_reports;
CREATE POLICY "Users can create own food reports"
    ON food_reports FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can view their own reports
DROP POLICY IF EXISTS "Users can view own food reports" ON food_reports;
CREATE POLICY "Users can view own food reports"
    ON food_reports FOR SELECT
    USING (auth.uid() = user_id);

-- Service role has full access (for admin review)
DROP POLICY IF EXISTS "Service role full access food reports" ON food_reports;
CREATE POLICY "Service role full access food reports"
    ON food_reports FOR ALL
    TO service_role
    USING (true) WITH CHECK (true);

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT ON food_reports TO authenticated;
GRANT ALL ON food_reports TO service_role;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE food_reports IS 'User-submitted reports for incorrect food nutrition data in food_database';
COMMENT ON COLUMN food_reports.food_database_id IS 'References the food_database entry being reported (nullable if food was not from DB)';
COMMENT ON COLUMN food_reports.reported_issue IS 'User description of what is wrong with the nutrition data';
COMMENT ON COLUMN food_reports.status IS 'Report lifecycle: pending -> reviewed -> resolved/dismissed';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
