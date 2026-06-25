-- 2283_program_library_integration.sql
-- Foundation for full Program Library integration (curation + per-day multi-assignment
-- + editable program length). Applied to prod via Supabase MCP on 2026-06-25;
-- idempotent for repo parity.
--
-- 1) programs: curation flag + richer editorial copy for the program detail page.
--    is_published gates the browse/category/featured queries to a curated set
--    (the ~200 generic auto-seeded rows stay in the table but are hidden).
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS is_published boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS editorial_name text,
  ADD COLUMN IF NOT EXISTS tagline text,
  ADD COLUMN IF NOT EXISTS who_for text,
  ADD COLUMN IF NOT EXISTS who_not_for text,
  ADD COLUMN IF NOT EXISTS equipment_summary text,
  ADD COLUMN IF NOT EXISTS progression_note text;
CREATE INDEX IF NOT EXISTS idx_programs_published ON programs(is_published) WHERE is_published = true;

-- 2) user_program_assignments: per-day assignment + primary/add-on slot.
--    assigned_days = weekday ints (0=Mon..6=Sun) the program occupies.
--    slot = 'primary' (drives the home hero) | 'addon' (stacks on top, e.g. 7-min).
--    Multiple active assignments per user are allowed (no single-active unique index
--    exists in prod); a single primary-per-weekday is enforced in the assign endpoint.
ALTER TABLE user_program_assignments
  ADD COLUMN IF NOT EXISTS assigned_days integer[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS slot text DEFAULT 'primary';
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_program_assignments_slot_check') THEN
    ALTER TABLE user_program_assignments
      ADD CONSTRAINT user_program_assignments_slot_check CHECK (slot IN ('primary','addon'));
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_upa_active_user
  ON user_program_assignments(user_id, is_active) WHERE is_active = true;

-- 3) user_program_templates: total program length (weeks), distinct from week_length
--    (the repeating 7-day cycle) and deload_every_n_weeks. Powers "edit how long the
--    program lasts" in the builder; the scheduler expands this many weeks.
ALTER TABLE user_program_templates
  ADD COLUMN IF NOT EXISTS duration_weeks integer;
