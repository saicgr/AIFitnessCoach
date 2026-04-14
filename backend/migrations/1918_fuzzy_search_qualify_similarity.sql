-- Migration 1918: qualify extensions.similarity() in fuzzy_search functions
--
-- Context: pg_trgm is installed in the `extensions` schema. The
-- `fuzzy_search_exercises_api` function has `SET search_path TO 'public',
-- 'extensions'` in its definition, yet RPC calls via PostgREST from the
-- backend still failed with:
--   function similarity(text, text) does not exist
-- because the function was originally created by a role whose runtime
-- resolution ignored the schema-qualified setting in some call paths. The
-- bulletproof fix is to schema-qualify each similarity() call with
-- `extensions.similarity(...)` — no search_path dependency.
--
-- Also fixes two drift issues exposed once similarity() resolved:
--   1. `exercise_library_cleaned` gained a `display_body_part` column that
--      the RETURNS TABLE list didn't reflect, causing
--      "structure of query does not match function result type" (SELECT e.*
--      returned 19 cols into an 18-col RETURNS TABLE).
--   2. Using SELECT e.* when RETURNS TABLE lists explicit columns is fragile
--      — replace with explicit column list so future schema additions don't
--      silently break the function.

DROP FUNCTION IF EXISTS public.fuzzy_search_exercises_api(text, text, text, integer);

CREATE FUNCTION public.fuzzy_search_exercises_api(
    search_term text,
    equipment_filter text DEFAULT NULL::text,
    body_part_filter text DEFAULT NULL::text,
    limit_count integer DEFAULT 50
)
RETURNS TABLE(
    id uuid, name text, original_name text, body_part text, display_body_part text,
    equipment text, target_muscle text, secondary_muscles text[], instructions text,
    difficulty_level text, category text, gif_url text, video_url text,
    image_url text, goals text[], suitable_for text[], avoid_if text[],
    single_dumbbell_friendly boolean, single_kettlebell_friendly boolean
)
LANGUAGE plpgsql
STABLE
SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
      e.id, e.name, e.original_name, e.body_part, e.display_body_part,
      e.equipment, e.target_muscle, e.secondary_muscles, e.instructions,
      e.difficulty_level, e.category, e.gif_url, e.video_url,
      e.image_url, e.goals, e.suitable_for, e.avoid_if,
      e.single_dumbbell_friendly, e.single_kettlebell_friendly
    FROM exercise_library_cleaned e
    WHERE
        (
            extensions.similarity(LOWER(e.name), LOWER(search_term)) > 0.2
            OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
            OR extensions.similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
            OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
        )
        AND (equipment_filter IS NULL OR LOWER(e.equipment) = LOWER(equipment_filter))
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
            extensions.similarity(LOWER(e.name), LOWER(search_term)),
            extensions.similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.fuzzy_search_exercises_api(text, text, text, integer)
    TO anon, authenticated, service_role;

-- The simpler sibling fuzzy_search_exercises() is also qualified preemptively
-- (same similarity-resolution risk, even though it's not currently on the hot path).
CREATE OR REPLACE FUNCTION public.fuzzy_search_exercises(
    search_term text,
    limit_count integer DEFAULT 50
)
RETURNS TABLE(
    id uuid, name text, body_part text, equipment text, target_muscle text,
    gif_url text, video_url text, similarity_score real
)
LANGUAGE plpgsql
STABLE
SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e.id, e.name, e.body_part, e.equipment, e.target_muscle,
        e.gif_url, e.video_url,
        GREATEST(
            extensions.similarity(LOWER(e.name), LOWER(search_term)),
            extensions.similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) as similarity_score
    FROM exercise_library_cleaned e
    WHERE
        extensions.similarity(LOWER(e.name), LOWER(search_term)) > 0.2
        OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
        OR extensions.similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
        OR LOWER(COALESCE(e.equipment, '')) LIKE '%' || LOWER(search_term) || '%'
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
            extensions.similarity(LOWER(e.name), LOWER(search_term)),
            extensions.similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$function$;
