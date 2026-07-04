-- ============================================================================
-- Migration 2303 — Featured-rank curation (onboarding-friendly launch set)
-- ----------------------------------------------------------------------------
-- Re-points the Program Library "Featured" carousel at the six beginner- and
-- health-first programs below, in this display order. Follows the pattern of
-- migration 2284 (STEP 3): set featured_rank on the curated rows, then clear
-- any stray featured_rank on other PUBLISHED rows so exactly these six are
-- featured.
--
-- MOSTLY-NO-OP TODAY: most of these rows are authored by a PARALLEL program-
-- generation pipeline that has not necessarily run yet. An UPDATE against a
-- not-yet-existing program_name simply matches zero rows (harmless). This
-- migration is designed to be RE-RUN after that generation completes, at which
-- point the UPDATEs land and the carousel fills. Re-running is idempotent.
--
-- Keyed by program_name (the generation pipeline's stable identifier for these
-- rows). featured_rank is 1-based; 1 shows first.
-- ============================================================================

UPDATE programs SET featured_rank = 1 WHERE program_name = 'Gentle Start';
UPDATE programs SET featured_rank = 2 WHERE program_name = 'Zero to 5K';
UPDATE programs SET featured_rank = 3 WHERE program_name = 'Daily Walk Challenge';
UPDATE programs SET featured_rank = 4 WHERE program_name = 'GLP-1 Muscle Preservation';
UPDATE programs SET featured_rank = 5 WHERE program_name = 'Pilates Foundations';
UPDATE programs SET featured_rank = 6 WHERE program_name = 'Kettlebell Foundations';

-- Clear stray featured_rank on any OTHER published program so only the six
-- curated rows above stay featured (mirrors migration 2284 STEP 3). Rows not
-- yet created by the generation pipeline are simply absent from the keep-list;
-- once they exist and this migration is re-run, they are set above and excluded
-- here by name.
UPDATE programs SET featured_rank = NULL
WHERE is_published = true
  AND featured_rank IS NOT NULL
  AND program_name NOT IN (
    'Gentle Start',
    'Zero to 5K',
    'Daily Walk Challenge',
    'GLP-1 Muscle Preservation',
    'Pilates Foundations',
    'Kettlebell Foundations'
  );
