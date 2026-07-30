-- 2385: make the FREE dish-image catalog tier actually resolve, and give
--       GET /nutrition/search an index it can use.
--
-- Context (E2E register row 11 residual).
--
-- (A) services/dish_image_service.py:_lookup_food_database matched menu dishes
--     with `name = ANY(...) AND image_url IS NOT NULL LIMIT 200`.
--     `food_database` is OpenFoodFacts-derived and heavily duplicated on name
--     (33,022 distinct name_normalized values have >1 row that carries an
--     image; 'spaghetti' alone has 437). The btree emits rows in name order,
--     so LIMIT 200 amputated the alphabetical tail of every menu: a realistic
--     60-dish probe resolved 21 of 54 available images and pushed the other 33
--     to the paid Imagen path. The match was also exact and case-sensitive on
--     the raw display name, so it could not see 'guacamole' vs 'Guacamole'.
--
--     Fix: `dish_name_key(text)` mirrors the app's `_normalize_dish_name`
--     (api/v1/nutrition/menu_analyses.py) in SQL, an expression index serves
--     it, and `dish_image_food_lookup(text[])` returns exactly ONE best row per
--     dish key via DISTINCT ON — so a duplicate-heavy name can no longer crowd
--     other dishes out of a row budget, because there is no row budget.
--
-- (B) api/v1/nutrition_preferences_endpoints.py:search_foods ran
--     `ilike("name", "%q%")` on the same 718k-row / 1.8 GB table. A leading
--     wildcard cannot use the btree from migration 2331 (equality only) and the
--     existing GIN trigram index is on a DIFFERENT column (name_normalized).
--     Measured: Seq Scan, 13.0 s — past the 8 s `authenticated`
--     statement_timeout — swallowed by a bare except, so the "database" tier of
--     food search silently returned nothing. The query is moved onto
--     name_normalized (already GIN-trigram indexed, partial on is_primary), and
--     this migration adds the btree needed for the sub-trigram (<3 char) case,
--     where pg_trgm cannot extract a trigram and therefore cannot help.
--
-- (C) nutrition_preferences.target_fiber_g carried a column DEFAULT of 25, so
--     every row ever inserted presented a 25 g fiber goal the user never chose
--     — the same fabricated-target class as the 2000 kcal skip default this
--     wave removed (api/v1/nutrition/onboarding.py). Existing rows are left
--     untouched (there is no way to tell a deliberate 25 from the default, and
--     logged data is never destroyed); the default stops manufacturing new ones.
--
-- Safety: every index is CREATE INDEX CONCURRENTLY (no ACCESS EXCLUSIVE lock on
-- food_database), function creation is catalog-only, and DROP DEFAULT is a
-- catalog-only change with no table rewrite. Nothing is deleted.
--
-- NOTE: CREATE INDEX CONCURRENTLY cannot run inside a transaction block. Apply
-- this file with autocommit on.

-- ---------------------------------------------------------------------------
-- (A) Dish-name key + deduped catalog lookup
-- ---------------------------------------------------------------------------

-- Mirror of `_normalize_dish_name`: lowercase, punctuation → space, drop the
-- menu stopwords, collapse whitespace. IMMUTABLE so it can back an index.
CREATE OR REPLACE FUNCTION public.dish_name_key(raw text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT coalesce((
        SELECT string_agg(tok, ' ' ORDER BY ord)
        FROM unnest(
                 regexp_split_to_array(
                     btrim(regexp_replace(lower(coalesce(raw, '')),
                                          '[^[:alnum:]_[:space:]]', ' ', 'g')),
                     '\s+'
                 )
             ) WITH ORDINALITY AS t(tok, ord)
        WHERE tok <> ''
          AND tok <> ALL (ARRAY[
              'the','a','an','of','with','and','w','in','on','at','for','to',
              'from','by','fresh','house','side','signature','classic',
              'traditional','special'
          ])
    ), '');
$$;

COMMENT ON FUNCTION public.dish_name_key(text) IS
    'Menu-dish normalization key. Must stay in sync with _normalize_dish_name '
    'in backend/api/v1/nutrition/menu_analyses.py — dish_image_cache and the '
    'catalog lookup key on the same string.';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_database_dish_key
    ON public.food_database (public.dish_name_key(name))
    WHERE image_url IS NOT NULL;

-- One best row per dish key. `is_primary` first (the catalog's own canonical
-- flag), then the most complete record, then the lowest id for determinism —
-- so the same dish resolves to the same picture on every scan.
CREATE OR REPLACE FUNCTION public.dish_image_food_lookup(p_keys text[])
RETURNS TABLE (dish_key text, food_name text, food_image_url text)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $$
    SELECT DISTINCT ON (public.dish_name_key(f.name))
           public.dish_name_key(f.name),
           f.name,
           f.image_url
    FROM public.food_database f
    WHERE f.image_url IS NOT NULL
      AND public.dish_name_key(f.name) = ANY (p_keys)
    ORDER BY public.dish_name_key(f.name),
             f.is_primary DESC,
             f.data_completeness DESC NULLS LAST,
             f.id;
$$;

COMMENT ON FUNCTION public.dish_image_food_lookup(text[]) IS
    'Free dish-image tier: normalized-name → one best catalog row carrying an '
    'image_url. Deduped in the database because food_database has up to 437 '
    'rows for a single dish name.';

GRANT EXECUTE ON FUNCTION public.dish_name_key(text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.dish_image_food_lookup(text[]) TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- (B) Prefix index for short food-search queries
-- ---------------------------------------------------------------------------

-- name_normalized is already lowercase, and the endpoint lowercases the query,
-- so a case-sensitive LIKE 'q%' is correct and this btree serves it. Needed
-- only for queries shorter than one trigram; >=3 chars go to
-- idx_food_name_trgm_primary.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_food_database_name_normalized_prefix
    ON public.food_database (name_normalized text_pattern_ops)
    WHERE is_primary = true;

-- ---------------------------------------------------------------------------
-- (C) Stop manufacturing a fiber target nobody chose
-- ---------------------------------------------------------------------------

ALTER TABLE public.nutrition_preferences ALTER COLUMN target_fiber_g DROP DEFAULT;

-- PostgREST must re-read the catalog before it will expose the new RPC.
NOTIFY pgrst, 'reload schema';
