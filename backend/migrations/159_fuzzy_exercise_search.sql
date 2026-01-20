-- Migration: 159_fuzzy_exercise_search.sql
-- Enable fuzzy/trigram search for exercise names
-- Handles typos like "benchpress" -> "Bench Press", "bicep curl" -> "Barbell Curl"

-- Enable pg_trgm extension for trigram similarity matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create GIN index for fast trigram search on exercise_library_cleaned view
-- Note: We create index on the base table, not the view
CREATE INDEX IF NOT EXISTS idx_exercise_library_name_trgm
ON exercise_library USING GIN (exercise_name gin_trgm_ops);

-- Create fuzzy search function that searches the cleaned view
CREATE OR REPLACE FUNCTION fuzzy_search_exercises(
    search_term TEXT,
    limit_count INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    body_part TEXT,
    equipment TEXT,
    target_muscle TEXT,
    gif_url TEXT,
    video_url TEXT,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.name,
        e.body_part,
        e.equipment,
        e.target_muscle,
        e.gif_url,
        e.video_url,
        similarity(LOWER(e.name), LOWER(search_term)) as similarity_score
    FROM exercise_library_cleaned e
    WHERE
        -- Trigram similarity > 0.2 (catches typos)
        similarity(LOWER(e.name), LOWER(search_term)) > 0.2
        -- OR substring match (for partial matches)
        OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
    ORDER BY
        -- Exact matches first
        CASE
            WHEN LOWER(e.name) = LOWER(search_term) THEN 0
            WHEN LOWER(e.name) LIKE LOWER(search_term) || '%' THEN 1
            WHEN LOWER(e.name) LIKE '%' || LOWER(search_term) || '%' THEN 2
            ELSE 3
        END,
        -- Then by similarity score
        similarity(LOWER(e.name), LOWER(search_term)) DESC,
        -- Alphabetical as tiebreaker
        e.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises(TEXT, INT) TO authenticated;

-- Also create a simpler version for the API that returns JSON-compatible output
CREATE OR REPLACE FUNCTION fuzzy_search_exercises_api(
    search_term TEXT,
    equipment_filter TEXT DEFAULT NULL,
    body_part_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    body_part TEXT,
    equipment TEXT,
    target_muscle TEXT,
    gif_url TEXT,
    video_url TEXT,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.name,
        e.body_part,
        e.equipment,
        e.target_muscle,
        e.gif_url,
        e.video_url,
        similarity(LOWER(e.name), LOWER(search_term)) as similarity_score
    FROM exercise_library_cleaned e
    WHERE
        (
            -- Trigram similarity for fuzzy matching
            similarity(LOWER(e.name), LOWER(search_term)) > 0.2
            -- OR substring match
            OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
        )
        -- Optional equipment filter
        AND (equipment_filter IS NULL OR LOWER(e.equipment) = LOWER(equipment_filter))
        -- Optional body part filter
        AND (body_part_filter IS NULL OR LOWER(e.body_part) = LOWER(body_part_filter))
    ORDER BY
        CASE
            WHEN LOWER(e.name) = LOWER(search_term) THEN 0
            WHEN LOWER(e.name) LIKE LOWER(search_term) || '%' THEN 1
            WHEN LOWER(e.name) LIKE '%' || LOWER(search_term) || '%' THEN 2
            ELSE 3
        END,
        similarity(LOWER(e.name), LOWER(search_term)) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO authenticated;

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '159_fuzzy_exercise_search',
    NOW(),
    'Added pg_trgm extension and fuzzy_search_exercises function for typo-tolerant exercise search'
) ON CONFLICT DO NOTHING;

COMMENT ON FUNCTION fuzzy_search_exercises IS 'Fuzzy search for exercises using trigram similarity. Handles typos like benchpress -> Bench Press';
