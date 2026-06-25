-- 2285: Program Library integration — link assignments to their source `programs`
-- row and tag concrete `workouts` rows with the assignment + slot so today.py can
-- resolve per-day multi-assignment metadata at READ time without fragile joins.
--
-- Context: the Program Library "Start" flow (POST /program-templates/assign)
-- clones a `programs` row into a user_program_template, creates an assignment,
-- and expands concrete dated workouts. today.py then serves the PRESCRIBED
-- workouts for a given weekday across ALL active assignments (primary + addon).
-- For the carousel to label each workout (program name/week/slot) we tag the
-- expanded rows with assignment_id + program_slot, and resolve the rest from
-- the assignment at read time.
--
-- Applied via Supabase MCP apply_migration on 2026-06-25 (project
-- hpbzfahijszqmgsybuor). This file is the repo record of that change.

-- 1. Assignment -> source programs row (the catalog program it was cloned from).
--    branded_program_id already exists for the legacy branded path; this is the
--    parallel link for the curated `programs` library. ON DELETE SET NULL so a
--    catalog cleanup never cascades into a user's assignment.
ALTER TABLE public.user_program_assignments
  ADD COLUMN IF NOT EXISTS source_program_id uuid
    REFERENCES public.programs(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_upa_source_program_id
  ON public.user_program_assignments (source_program_id);

-- 2. Concrete workout -> the assignment that produced it + its slot.
--    assignment_id lets today.py group/sort and resolve program metadata.
--    program_slot is denormalized ('primary'|'addon') for cheap read-time
--    ordering without a join. Both nullable: AI-decides workouts have neither.
ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS assignment_id uuid
    REFERENCES public.user_program_assignments(id) ON DELETE SET NULL;

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS program_slot text;

ALTER TABLE public.workouts
  DROP CONSTRAINT IF EXISTS workouts_program_slot_check;
ALTER TABLE public.workouts
  ADD CONSTRAINT workouts_program_slot_check
    CHECK (program_slot IS NULL OR program_slot IN ('primary', 'addon'));

CREATE INDEX IF NOT EXISTS idx_workouts_assignment_id
  ON public.workouts (assignment_id) WHERE assignment_id IS NOT NULL;

COMMENT ON COLUMN public.user_program_assignments.source_program_id IS
  'The public.programs catalog row this assignment was cloned from (curated library Start flow). NULL for authored/parsed/branded/AI programs.';
COMMENT ON COLUMN public.workouts.assignment_id IS
  'The user_program_assignments row whose template expanded this workout. NULL for AI-decides / quick workouts. today.py tags the carousel from this.';
COMMENT ON COLUMN public.workouts.program_slot IS
  'Denormalized slot of the producing assignment (primary|addon) for cheap read-time ordering. NULL for non-program workouts.';
