-- Migration: 240_fix_fuzzy_search_equipment.sql
-- Created: 2026-02-10
-- Purpose: Update fuzzy_search_exercises_api to also search equipment column
--          and return all columns from exercise_library_cleaned view.
--          Fixes: searching "treadmill" now finds exercises with equipment='treadmill'
--          even if the name doesn't contain "treadmill", plus fuzzy matching on equipment.

-- Must DROP first because return type changes (from TABLE to SETOF view)
DROP FUNCTION IF EXISTS fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT);
DROP FUNCTION IF EXISTS fuzzy_search_exercises(TEXT, INT);

-- 1. Recreate the basic fuzzy search function (same return type, updated logic)
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
        GREATEST(
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) as similarity_score
    FROM exercise_library_cleaned e
    WHERE
        -- Name matching (trigram similarity or substring)
        similarity(LOWER(e.name), LOWER(search_term)) > 0.2
        OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
        -- Equipment matching (trigram similarity or substring)
        OR similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
        OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
    ORDER BY
        -- Exact name match first
        CASE
            WHEN LOWER(e.name) = LOWER(search_term) THEN 0
            WHEN LOWER(e.name) LIKE LOWER(search_term) || '%' THEN 1
            WHEN LOWER(e.name) LIKE '%' || LOWER(search_term) || '%' THEN 2
            -- Equipment exact/substring match
            WHEN LOWER(COALESCE(e.equipment, '')) = LOWER(search_term) THEN 3
            WHEN LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%' THEN 4
            ELSE 5
        END,
        GREATEST(
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

-- 2. Recreate the API version - now returns all columns from cleaned view
--    Using SETOF ensures it always matches the view's column set
CREATE FUNCTION fuzzy_search_exercises_api(
    search_term TEXT,
    equipment_filter TEXT DEFAULT NULL,
    body_part_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 50
)
RETURNS SETOF exercise_library_cleaned AS $$
BEGIN
    RETURN QUERY
    SELECT e.*
    FROM exercise_library_cleaned e
    WHERE
        (
            -- Name matching (trigram similarity or substring)
            similarity(LOWER(e.name), LOWER(search_term)) > 0.2
            OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
            -- Equipment matching (trigram similarity or substring)
            OR similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
            OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
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
            WHEN LOWER(COALESCE(e.equipment, '')) = LOWER(search_term) THEN 3
            WHEN LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%' THEN 4
            ELSE 5
        END,
        GREATEST(
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION fuzzy_search_exercises_api(TEXT, TEXT, TEXT, INT) TO authenticated;

-- Add trigram index on equipment column for fast fuzzy search
CREATE INDEX IF NOT EXISTS idx_exercise_library_equipment_trgm
ON exercise_library USING GIN (equipment gin_trgm_ops);
