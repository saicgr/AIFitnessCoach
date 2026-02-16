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
--     inflammatory_score, inflammatory_category, dedup_key, dedup_rank, is_primary
--   - food_database_deduped view = SELECT * FROM food_database WHERE is_primary = TRUE
--   - GIN trigram index: idx_food_database_name_trgm ON food_database USING GIN (name_normalized gin_trgm_ops)
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
        similarity(f.name_normalized, normalized_query) AS similarity_score
    FROM food_database_deduped f
    WHERE
        -- Trigram similarity match (catches typos and close matches)
        similarity(f.name_normalized, normalized_query) > 0.15
        -- OR substring match (for exact partial matches like "chicken" in "chicken breast")
        OR f.name_normalized ILIKE '%' || normalized_query || '%'
    ORDER BY
        -- Exact matches first
        CASE
            WHEN f.name_normalized = normalized_query THEN 0
            WHEN f.name_normalized ILIKE normalized_query || '%' THEN 1
            WHEN f.name_normalized ILIKE '%' || normalized_query || '%' THEN 2
            ELSE 3
        END,
        -- Then by similarity score
        similarity(f.name_normalized, normalized_query) DESC,
        -- Prefer items with serving info
        CASE WHEN f.serving_weight_g IS NOT NULL THEN 0 ELSE 1 END,
        -- Alphabetical tiebreaker
        f.name ASC
    LIMIT result_limit
    OFFSET result_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = public;

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
    RETURN QUERY
    SELECT
        input.name AS input_name,
        best.id AS matched_id,
        best.name AS matched_name,
        best.source,
        best.calories_per_100g,
        best.protein_per_100g,
        best.fat_per_100g,
        best.carbs_per_100g,
        best.fiber_per_100g,
        best.sim AS similarity_score
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
            similarity(f.name_normalized, LOWER(TRIM(input.name))) > 0.15
            OR f.name_normalized ILIKE '%' || LOWER(TRIM(input.name)) || '%'
        ORDER BY
            CASE
                WHEN f.name_normalized = LOWER(TRIM(input.name)) THEN 0
                WHEN f.name_normalized ILIKE LOWER(TRIM(input.name)) || '%' THEN 1
                WHEN f.name_normalized ILIKE '%' || LOWER(TRIM(input.name)) || '%' THEN 2
                ELSE 3
            END,
            similarity(f.name_normalized, LOWER(TRIM(input.name))) DESC
        LIMIT 1
    ) best ON TRUE;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = public;

COMMENT ON FUNCTION batch_lookup_foods IS 'Batch food lookup: takes array of food names, returns best match for each using trigram similarity via LATERAL JOIN.';

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
