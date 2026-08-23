-- Migration 2416: fix the "Chatarunga" misspelling of the yoga pose
-- "Chaturanga" (E2E register finding #215).
--
-- The pose is stored misspelled in all three places that matter for search:
--   exercise_library.exercise_name  ("3 Leg Chatarunga Pose_female")
--   exercise_canonical.canonical_name ("3 Leg Chatarunga Pose")
--   exercise_aliases.alias_name       ("3 Leg Chatarunga Pose")
-- so a user typing the correct spelling gets zero results for an exercise
-- the library genuinely contains.
--
-- NOTE ON THE FK: exercise_aliases.canonical_exercise_id references
-- exercise_canonical(id), NOT exercise_library(id). The existing alias row
-- already points at the correct exercise_canonical row, so this migration
-- only corrects spelling and adds a bare-name alias. It must not repoint
-- canonical_exercise_id at an exercise_library id.

BEGIN;

UPDATE exercise_library
SET exercise_name = replace(exercise_name, 'Chatarunga', 'Chaturanga')
WHERE exercise_name ILIKE '%chatarunga%';

UPDATE exercise_canonical
SET canonical_name = replace(canonical_name, 'Chatarunga', 'Chaturanga')
WHERE canonical_name ILIKE '%chatarunga%';

UPDATE exercise_aliases
SET alias_name = replace(alias_name, 'Chatarunga', 'Chaturanga'),
    alias_name_normalized = replace(alias_name_normalized, 'chatarunga', 'chaturanga')
WHERE alias_name ILIKE '%chatarunga%';

-- The canonical name carries "3 Leg ... Pose" qualifiers, so a plain search
-- for the pose name alone still would not match. Add the bare alias against
-- the canonical row that already exists.
INSERT INTO exercise_aliases
    (alias_name, alias_name_normalized, canonical_exercise_id, match_type, match_confidence, is_verified)
SELECT 'Chaturanga', 'chaturanga', id, 'spelling_variant', 0.9, true
FROM exercise_canonical
WHERE canonical_name ILIKE '%chaturanga%'
ON CONFLICT (alias_name_normalized) DO NOTHING;

COMMIT;

-- VERIFY:
--   select exercise_name from exercise_library where exercise_name ilike '%chaturanga%';
--   select alias_name, alias_name_normalized from exercise_aliases where alias_name_normalized like '%chaturanga%';
