-- 2393_resolve_exercise_library_ids_batch.sql
--
-- Batch name -> `exercise_library.id` resolver, for filling in missing
-- `exercises_json[].exercise_id` at program-expansion time.
--
-- WHY
-- ---
-- A 2026-07-30 sample of the 400 most recent workouts found 826 of 2286 exercise
-- entries (36%) stored with `exercise_id: null`, and `program_template` was the
-- worst generation path — 17.5% of its exercise names did not resolve to the
-- library at all. Entries without an id can only be rendered BY NAME, which is
-- precisely the fragile path behind the exercise-image/video 404 storm.
--
-- A pure exact-name map resolves almost none of them: the template names differ
-- from library names by case, plurals, hyphens and apostrophes ('Calf Raises' vs
-- 'Calf Raise', 'Push-Ups' vs 'Normal Push-up', 'Farmers Carry' vs
-- "Farmer's Carry"). Normalization is required — and it must be the SAME
-- normalization the rest of the stack uses. `normalize_exercise_name()` carries
-- ~18 plural rules plus abbreviation expansion (db/kb/bb) and parenthetical
-- stripping; a Python re-implementation would drift the moment either side
-- changed, so resolution stays in SQL and the caller passes raw names.
--
-- RESOLUTION ORDER (first hit wins, both EXACT-normalized — never fuzzy)
--   1. Direct: the name normalizes to an `exercise_library.exercise_name`.
--   2. Alias chain: name -> exercise_aliases -> exercise_canonical, then the
--      canonical name normalizes to an `exercise_library.exercise_name`.
--      (1770 of 2070 canonical rows normalize-match a library row.)
--
-- A name that resolves to nothing is simply ABSENT from the result, and the
-- caller leaves `exercise_id` NULL — exactly the prior behaviour. That is
-- deliberate: per the note at api/v1/program_templates.py:1971, a loose match
-- here would silently relabel exercises to a WRONG identity catalog-wide, which
-- is far worse than a null id.
--
-- Ties are broken toward the row that actually has media, then the shortest name
-- (favouring the base movement over a qualified variant), then id — the same
-- deterministic rule used by 2391.

CREATE OR REPLACE FUNCTION public.resolve_exercise_library_ids_batch(p_names text[])
RETURNS TABLE (
    requested_name      text,
    exercise_library_id uuid,
    matched_name        text,
    match_route         text
)
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
    WITH req AS (
        SELECT DISTINCT n.requested_name,
               normalize_exercise_name(n.requested_name) AS norm
        FROM unnest(p_names) AS n(requested_name)
    ),
    direct AS (
        SELECT DISTINCT ON (r.requested_name)
               r.requested_name, l.id, l.exercise_name, 'direct'::text AS route
        FROM req r
        JOIN exercise_library l
          ON normalize_exercise_name(l.exercise_name) = r.norm
        ORDER BY r.requested_name,
                 (l.image_s3_path IS NOT NULL) DESC,
                 length(l.exercise_name),
                 l.id
    ),
    via_alias AS (
        SELECT DISTINCT ON (r.requested_name)
               r.requested_name, l.id, l.exercise_name, 'alias'::text AS route
        FROM req r
        JOIN exercise_aliases   a  ON a.alias_name_normalized = r.norm
        JOIN exercise_canonical ec ON ec.id = a.canonical_exercise_id
        JOIN exercise_library   l
          ON normalize_exercise_name(l.exercise_name)
             = normalize_exercise_name(ec.canonical_name)
        WHERE r.requested_name NOT IN (SELECT requested_name FROM direct)
        ORDER BY r.requested_name,
                 (l.image_s3_path IS NOT NULL) DESC,
                 length(l.exercise_name),
                 l.id
    )
    SELECT requested_name, id, exercise_name, route FROM direct
    UNION ALL
    SELECT requested_name, id, exercise_name, route FROM via_alias;
$function$;

COMMENT ON FUNCTION public.resolve_exercise_library_ids_batch(text[]) IS
    'Batch name -> exercise_library.id resolver. Exact-normalized only (direct '
    'library match, then the exercise_aliases -> exercise_canonical chain); never '
    'fuzzy, so it cannot assign a wrong exercise identity. Unresolvable names are '
    'omitted from the result and the caller keeps exercise_id NULL. Used by '
    'services/program_template_expander.py to stop writing name-only exercises.';

-- ─────────────────────────────────────────────────────────────────────────────
-- Verification
-- ─────────────────────────────────────────────────────────────────────────────
--   SELECT * FROM resolve_exercise_library_ids_batch(ARRAY[
--     'Calf Raises', 'Push-Ups', 'Farmers Carry', 'Air Squats', 'Run',
--     'Box Jumps', 'Russian Twists', 'Stationary bike', 'Kettlebell Swings',
--     'definitely not an exercise'   -- must be ABSENT from the output
--   ]);
