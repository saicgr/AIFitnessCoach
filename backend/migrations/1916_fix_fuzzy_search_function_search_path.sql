-- 1916: Fix fuzzy-search functions broken by migration 1915.
--
-- Migration 1915_fix_linter_function_search_path_and_demo_rls tightened
-- search_path to just 'public' on all public functions to satisfy Supabase's
-- security linter. That silently broke four functions that call similarity()
-- from pg_trgm, because pg_trgm is installed in the `extensions` schema
-- (Supabase's default) and is no longer resolvable without qualification.
--
-- Symptom in logs:
--   [exercises API] Fuzzy search RPC failed, falling back to ILIKE:
--   function similarity(text, text) does not exist (code 42883)
--
-- Fix part 1 (search_path): explicitly set search_path to 'public, extensions'
-- on each affected function. Keeps the security linter happy (still pinned)
-- while making pg_trgm operators/functions reachable.
--
-- Fix part 2 (column list): fuzzy_search_exercises_api also used `SELECT e.*`
-- against exercise_library_cleaned. A new column (`display_body_part`) was
-- added to that table after the function was written, shifting column
-- positions and causing `Returned type text does not match expected type
-- text[] in column 7`. Replace with an explicit column list matching the
-- RETURNS TABLE contract so future schema additions don't silently break it.

-- Part 1: three functions that only need the search_path fix
ALTER FUNCTION public.fuzzy_search_exercises(text, integer)
  SET search_path = public, extensions;

ALTER FUNCTION public.search_food_database(text, integer, integer)
  SET search_path = public, extensions;

ALTER FUNCTION public.batch_lookup_foods(text[])
  SET search_path = public, extensions;

-- Part 2: fuzzy_search_exercises_api — search_path + explicit column list
CREATE OR REPLACE FUNCTION public.fuzzy_search_exercises_api(
    search_term text,
    equipment_filter text DEFAULT NULL,
    body_part_filter text DEFAULT NULL,
    limit_count integer DEFAULT 50
)
RETURNS TABLE(
    id uuid,
    name text,
    original_name text,
    body_part text,
    equipment text,
    target_muscle text,
    secondary_muscles text[],
    instructions text,
    difficulty_level text,
    category text,
    gif_url text,
    video_url text,
    image_url text,
    goals text[],
    suitable_for text[],
    avoid_if text[],
    single_dumbbell_friendly boolean,
    single_kettlebell_friendly boolean
)
LANGUAGE plpgsql
STABLE
SET search_path = public, extensions
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e.id, e.name, e.original_name, e.body_part, e.equipment,
        e.target_muscle, e.secondary_muscles, e.instructions,
        e.difficulty_level, e.category, e.gif_url, e.video_url,
        e.image_url, e.goals, e.suitable_for, e.avoid_if,
        e.single_dumbbell_friendly, e.single_kettlebell_friendly
    FROM exercise_library_cleaned e
    WHERE (
        similarity(LOWER(e.name), LOWER(search_term)) > 0.2
        OR LOWER(e.name) LIKE '%' || LOWER(search_term) || '%'
        OR similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term)) > 0.3
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
            similarity(LOWER(e.name), LOWER(search_term)),
            similarity(LOWER(COALESCE(e.equipment, '')), LOWER(search_term))
        ) DESC,
        e.name ASC
    LIMIT limit_count;
END;
$function$;
