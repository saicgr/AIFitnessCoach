-- 2281_program_featured_rank.sql
-- Program Library redesign: a nullable curation rank powering the
-- "Featured / Program of the week" rail (GET /program-templates/library/featured)
-- and a +10 boost in GET /program-templates/library/recommended.
-- lower featured_rank = higher priority; NULL = not featured.
-- Applied to prod via Supabase MCP on 2026-06-24; this file records it for repo parity.

ALTER TABLE programs ADD COLUMN IF NOT EXISTS featured_rank INT;
COMMENT ON COLUMN programs.featured_rank IS 'Nullable curation rank for the Program Library "Featured / Program of the week" rail; lower = higher priority. NULL = not featured.';

-- Curated seed: one strong, beginner-accessible program per major category.
UPDATE programs SET featured_rank = NULL;
UPDATE programs SET featured_rank = 1 WHERE program_name = 'Full Body Mass Builder'          AND program_category = 'Goal-Based';
UPDATE programs SET featured_rank = 2 WHERE program_name = 'Couch to 5K Beginner'             AND program_category = 'Sport Training';
UPDATE programs SET featured_rank = 3 WHERE program_name = 'Women''s Glute Building Program'   AND program_category = 'Women''s Health';
UPDATE programs SET featured_rank = 4 WHERE program_name = 'Men''s Starting Strength Program'  AND program_category = 'Men''s Health';
UPDATE programs SET featured_rank = 5 WHERE program_name = 'Beginner Yoga Fundamentals'        AND program_category = 'Yoga';
UPDATE programs SET featured_rank = 6 WHERE program_name = 'Lower Back Pain Relief Foundation' AND program_category = 'Pain Management';

CREATE INDEX IF NOT EXISTS idx_programs_featured_rank ON programs (featured_rank) WHERE featured_rank IS NOT NULL;
