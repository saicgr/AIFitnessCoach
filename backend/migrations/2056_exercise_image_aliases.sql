-- exercise_image_aliases — map workout-display names that don't exact-match a
-- row in exercise_library to the canonical library exercise_id that DOES have
-- an image_s3_path. Filled by `backend/scripts/audit_exercise_image_coverage.py`.
--
-- Why a table instead of fuzzy match: cross-exercise fuzzy fallback in
-- get_image_by_exercise_name was deliberately removed to fix the lat-pulldown
-- bug (rows served sibling exercises' images). An explicit alias table keeps
-- the "no cross-exercise fuzzy" invariant but lets us repair specific
-- generator-output → library mismatches like
-- "Barbell Close Grip Press" → "Close-Grip Barbell Bench Press".

CREATE TABLE IF NOT EXISTS exercise_image_aliases (
    -- The exercise name as it appears in generated workouts / chat / RAG
    -- output. Stored lower-cased for index-friendly equality match.
    display_name        TEXT PRIMARY KEY,
    -- The canonical exercise this alias resolves to. Must have image_s3_path
    -- populated for the alias to be useful at runtime; foreign key is
    -- intentionally NOT enforced because some library rows are imported
    -- from CSV before the alias backfill runs.
    library_exercise_id UUID NOT NULL,
    -- Provenance — `audit_exercise_image_coverage.py` for script-generated,
    -- `manual` for hand-entered, `report_FITWIZ-90` for Sentry-driven fixes.
    source              TEXT NOT NULL DEFAULT 'audit_script',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lookup is exact-match on display_name (lower-cased) so a btree index on
-- the primary key is sufficient — no extra indexes needed.

COMMENT ON TABLE exercise_image_aliases IS
  'Maps non-canonical workout exercise names to the library row whose image_s3_path should be served. See backend/api/v1/videos.py get_image_by_exercise_name. Populated by audit_exercise_image_coverage.py.';
