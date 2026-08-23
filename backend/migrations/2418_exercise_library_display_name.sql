-- Migration: Add + backfill exercise_library.display_name (finding #222)
--
-- exercise_name casing is inconsistent across the catalog ("trap bar
-- deadlift" lowercase sits beside "Barbell Coan Deadlift" Title Case, plus
-- suffixed rows like "band kneeling lat pulldown_female"). RAG/exact-name
-- resolution (row 222's own evidence — 7 of 8 Builder-generated names
-- resolved via EXACT match) depends on `exercise_name` staying byte-stable,
-- so this migration does NOT rewrite that column. Instead it adds a
-- presentation-safe `display_name`, backfilled with the same
-- initcap + suffix-strip expression `exercise_library_cleaned` already uses
-- for its `name` column, so any surface that currently reads the raw
-- `exercise_name` (bypassing the cleaned view) can switch to a consistently
-- Title-Cased column without touching the matching key.
--
-- No insert-time gate is added: `_female`/`_male` suffixed names are
-- legitimate asset-variant rows (see docs/qa evidence for finding #215/#188 —
-- the suffix is presentation-safe and already stripped for display), so a
-- blanket reject-on-insert rule would fail valid future imports rather than
-- catching real mistakes.

ALTER TABLE exercise_library ADD COLUMN IF NOT EXISTS display_name text;

UPDATE exercise_library
SET display_name = initcap(
    trim(both from regexp_replace(
        regexp_replace(exercise_name, '[_\s]*(Female|Male|female|male)$', '', 'i'),
        '_', ' ', 'g'
    ))
)
WHERE display_name IS NULL;

-- VERIFY: select count(*) from exercise_library where display_name is null; -- expect 0
-- VERIFY: select exercise_name, display_name from exercise_library where exercise_name = 'trap bar deadlift';
