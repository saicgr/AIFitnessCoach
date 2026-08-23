-- Migration: Fix missing space before "(" in exercise_library.display_name (finding #48)
--
-- Migration 2418 backfilled `display_name` with initcap() + suffix-strip, but
-- a handful of source rows glue a parenthesis directly onto the preceding
-- word with no space ("barbell full squat(back)_female"), so the backfilled
-- display_name inherited the same defect: "Barbell Full Squat(Back)" instead
-- of "Barbell Full Squat (Back)". This is a user-visible string on the
-- workout screen. Insert the missing space before re-running the same
-- initcap + suffix-strip expression 2418 used, scoped only to the rows that
-- actually have the defect.

UPDATE exercise_library
SET display_name = initcap(
    trim(both from regexp_replace(
        regexp_replace(
            regexp_replace(exercise_name, '([a-zA-Z0-9])\(', '\1 (', 'g'),
            '[_\s]*(Female|Male|female|male)$', '', 'i'
        ),
        '_', ' ', 'g'
    ))
)
WHERE exercise_name ~ '[a-zA-Z0-9]\(';

-- VERIFY: select exercise_name, display_name from exercise_library where display_name ~ '[a-zA-Z0-9]\('; -- expect 0 rows
