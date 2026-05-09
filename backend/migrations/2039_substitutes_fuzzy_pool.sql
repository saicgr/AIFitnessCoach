-- Migration: 2039_substitutes_fuzzy_pool.sql
-- Adds an RPC that returns full exercise_library_cleaned rows for trigram +
-- substring fuzzy search. The existing fuzzy_search_exercises (mig 159) only
-- returns 7 cols and is missing avoid_if / display_body_part / category /
-- image_url, all of which the /suggest-substitutes endpoint needs to filter
-- and rank candidates.
--
-- Uses the GIN trigram index already created on exercise_library_cleaned.name
-- (mig 2037 lines 165–166).
--
-- Idempotent: CREATE OR REPLACE.

CREATE OR REPLACE FUNCTION public.substitutes_fuzzy_search(
  p_search_term TEXT,
  p_limit       INT DEFAULT 12
)
RETURNS SETOF public.exercise_library_cleaned
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT *
  FROM public.exercise_library_cleaned
  WHERE
        extensions.similarity(LOWER(name), LOWER(p_search_term)) > 0.2
     OR LOWER(name) LIKE '%' || LOWER(p_search_term) || '%'
  ORDER BY
    CASE
      WHEN LOWER(name) = LOWER(p_search_term) THEN 0
      WHEN LOWER(name) LIKE LOWER(p_search_term) || '%' THEN 1
      WHEN LOWER(name) LIKE '%' || LOWER(p_search_term) || '%' THEN 2
      ELSE 3
    END,
    extensions.similarity(LOWER(name), LOWER(p_search_term)) DESC,
    name ASC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.substitutes_fuzzy_search(TEXT, INT)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.substitutes_fuzzy_search(TEXT, INT) IS
  'Trigram + substring fuzzy search returning full exercise_library_cleaned '
  'rows. Used by /api/v1/exercise-preferences/suggest-substitutes when '
  'token-based search and muscle-group search fail to return enough '
  'candidates. Reuses GIN trigram index from migration 2037.';
