-- 2392_resolve_exercise_demo_media_batch.sql
--
-- Set-returning batch form of resolve_exercise_demo_media() (migration 2290).
--
-- WHY
-- ---
-- `POST /api/v1/exercise-images/batch` resolved names with
--     .in_("name", names)   against exercise_library_cleaned
-- which is EXACT and CASE-SENSITIVE, and consulted no other source. A generator
-- name like 'Bodyweight standing calf raise' never matched the stored
-- 'Bodyweight Standing Calf Raise', so the batch silently omitted it and every
-- client fell back to a per-tile GET /exercise-images/{name}. That is the
-- mechanism that turned a handful of casing variants into the 404 storm seen in
-- production on 2026-07-30.
--
-- The single-name endpoint already resolves through resolve_exercise_demo_media().
-- The batch could not, without either N round trips or re-implementing
-- normalize_exercise_name() in Python — and that function carries ~18 plural rules
-- plus abbreviation expansion (db/kb/bb) and parenthetical stripping, so a Python
-- copy would drift from the SQL truth the moment either side changed.
--
-- This function keeps normalization in ONE place and resolves the whole batch in a
-- single round trip.
--
-- SEMANTICS
-- ---------
-- Identical matching to the scalar form: exact normalized-alias match only, never
-- fuzzy, so it can never serve a sibling exercise's media. Returns one row per
-- INPUT name that resolves (echoing `requested_name` so the caller can map results
-- back without re-normalizing). Unresolved names simply do not appear.
--
-- The DISTINCT ON mirrors the scalar function's `ORDER BY (demo_gender='neutral')
-- DESC NULLS LAST LIMIT 1`, applied per requested name.

CREATE OR REPLACE FUNCTION public.resolve_exercise_demo_media_batch(p_names text[])
RETURNS TABLE (
    requested_name  text,
    canonical_name  text,
    image_s3_path   text,
    video_s3_path   text,
    gif_url         text
)
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
    SELECT DISTINCT ON (n.requested_name)
           n.requested_name,
           ec.canonical_name,
           d.image_s3_path,
           d.video_s3_path,
           d.gif_url
    FROM   unnest(p_names) AS n(requested_name)
    JOIN   exercise_aliases   a  ON a.alias_name_normalized = normalize_exercise_name(n.requested_name)
    JOIN   exercise_canonical ec ON ec.id = a.canonical_exercise_id
    JOIN   exercise_demos     d  ON d.canonical_exercise_id = a.canonical_exercise_id
    WHERE  d.image_s3_path IS NOT NULL
       OR  d.video_s3_path IS NOT NULL
    ORDER  BY n.requested_name,
              (d.demo_gender = 'neutral') DESC NULLS LAST;
$function$;

COMMENT ON FUNCTION public.resolve_exercise_demo_media_batch(text[]) IS
    'Batch form of resolve_exercise_demo_media. Exact normalized-alias match only '
    '(no fuzzy — never serves a sibling exercise''s media). Returns one row per '
    'resolvable input name, echoing requested_name. Used by '
    'POST /api/v1/exercise-images/batch so batch and single-name resolution share '
    'one normalization implementation.';

-- ─────────────────────────────────────────────────────────────────────────────
-- Verification
-- ─────────────────────────────────────────────────────────────────────────────
--   SELECT * FROM resolve_exercise_demo_media_batch(ARRAY[
--     'Bodyweight standing calf raise',  -- casing variant, previously omitted
--     'Calf Raises',                     -- plural
--     'Push-Ups',                        -- plural + hyphen
--     'Farmers Carry',                   -- missing apostrophe
--     'definitely not an exercise'       -- must NOT appear in the output
--   ]);
