-- ============================================================================
-- 2375 — Merge the duplicate "4 Coners Side Step". E2E register row 93.
-- ============================================================================
--
-- SYMPTOM: the Exercises tab lists "4 Coners Side Step" and "4 Corners Side
-- Step" as if they were two different movements.
--
-- WHAT IT ACTUALLY IS (investigated 2026-07-30, not assumed):
--   exercise_library_cleaned is a MATERIALIZED VIEW over
--   `exercise_library UNION ALL exercise_library_manual`. The correct row
--   7463ce54 "4 Corners Side Step_female" lives in exercise_library with a real
--   photo illustration; the typo'd row 7023dffb "4 Coners Side Step_female"
--   lives in exercise_library_manual with its own AI-generated PNG under
--   'ILLUSTRATIONS ALL/Generated/4_coners_side_step.png'. The matview's own
--   dedupe cannot collapse them because it partitions on the normalised name,
--   and "coners" != "corners". exercise_canonical and exercise_demos each carry
--   a matching pair; the typo'd demo row has NULL media on both columns.
--
-- WHY THIS IS SAFE TO MERGE RATHER THAN JUST ALIAS:
--   The typo'd row is referenced by ZERO user data — verified live:
--     workouts.exercises_json ILIKE '%Coners%'        -> 0
--     program_variant_weeks.workouts ILIKE '%Coners%' -> 0
--     performance_logs.exercise_name ILIKE '%Coners%' -> 0
--   Its only dependant is one exercise_safety_tags row, and that row is the
--   WEAKER of the pair ('UNCLASSIFIED - needs manual audit' vs the correct
--   row's library-authoritative lower_back contraindication), so nothing of
--   value is lost.
--
-- WHY NO S3 RISK: the 2026-07-04 incident was a folder RENAME applied to one
-- table and not another. Nothing here renames an S3 object or an S3 path. The
-- Generated PNG is simply left orphaned in the bucket, which is inert.
--
-- An alias is still added so any free-text "4 Coners Side Step" arriving from
-- an old client payload, a cached AI response or a coach message still
-- resolves to the correct canonical instead of failing to match.

BEGIN;

-- 1. Back the rows up before deleting anything (logged-data durability).
CREATE TABLE IF NOT EXISTS exercise_dedupe_backup_2375 (
    backed_up_at   timestamptz NOT NULL DEFAULT now(),
    source_table   text        NOT NULL,
    row_data       jsonb       NOT NULL
);

INSERT INTO exercise_dedupe_backup_2375 (source_table, row_data)
SELECT 'exercise_library_manual', to_jsonb(t)
FROM exercise_library_manual t
WHERE t.id = '7023dffb-c227-4673-84e6-125d3b781a85';

INSERT INTO exercise_dedupe_backup_2375 (source_table, row_data)
SELECT 'exercise_safety_tags', to_jsonb(t)
FROM exercise_safety_tags t
WHERE t.exercise_id = '7023dffb-c227-4673-84e6-125d3b781a85';

INSERT INTO exercise_dedupe_backup_2375 (source_table, row_data)
SELECT 'exercise_demos', to_jsonb(t)
FROM exercise_demos t
WHERE t.canonical_exercise_id = 'd8e22bc1-61a0-4a80-baec-6ebee148ecc7';

INSERT INTO exercise_dedupe_backup_2375 (source_table, row_data)
SELECT 'exercise_canonical', to_jsonb(t)
FROM exercise_canonical t
WHERE t.id = 'd8e22bc1-61a0-4a80-baec-6ebee148ecc7';

-- 2. Point the misspelling at the surviving canonical so old free-text still
--    resolves. Guarded so re-running the migration is a no-op.
INSERT INTO exercise_aliases (
    alias_name, alias_name_normalized, canonical_exercise_id,
    match_type, match_confidence, is_verified
)
SELECT
    '4 Coners Side Step',
    lower(regexp_replace('4 Coners Side Step', '[^a-zA-Z0-9]+', '', 'g')),
    '5a7b2416-6c79-4215-a1de-c0b89186248d',
    'exact', 1.0, TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_aliases
    WHERE alias_name_normalized
          = lower(regexp_replace('4 Coners Side Step', '[^a-zA-Z0-9]+', '', 'g'))
);

-- 3. Drop the duplicate, children first.
DELETE FROM exercise_safety_tags
WHERE exercise_id = '7023dffb-c227-4673-84e6-125d3b781a85';

DELETE FROM exercise_demos
WHERE canonical_exercise_id = 'd8e22bc1-61a0-4a80-baec-6ebee148ecc7';

DELETE FROM exercise_canonical
WHERE id = 'd8e22bc1-61a0-4a80-baec-6ebee148ecc7';

-- The matview is not writable; the row belongs to exercise_library_manual.
DELETE FROM exercise_library_manual
WHERE id = '7023dffb-c227-4673-84e6-125d3b781a85';

COMMIT;

-- exercise_library_cleaned is itself a matview, and exercise_safety_index /
-- exercise_safety_index_mat derive from it, so BOTH must be refreshed for the
-- duplicate to disappear from the app (CLAUDE.md: refresh after bulk writes).
-- Run these after COMMIT, outside the transaction:
--   REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned;
--   REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_safety_index_mat;
