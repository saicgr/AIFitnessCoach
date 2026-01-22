-- Migration: Add checklist metadata columns to program_variant_weeks
-- Purpose: Store program metadata from PROGRAMS_CHECKLIST.md alongside generated weeks

-- Add columns for checklist metadata
ALTER TABLE program_variant_weeks
ADD COLUMN IF NOT EXISTS program_name TEXT,
ADD COLUMN IF NOT EXISTS priority TEXT,
ADD COLUMN IF NOT EXISTS has_supersets BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS category TEXT;

-- Add index for priority-based queries
CREATE INDEX IF NOT EXISTS idx_variant_weeks_priority ON program_variant_weeks(priority);

-- Add index for program_name queries
CREATE INDEX IF NOT EXISTS idx_variant_weeks_program_name ON program_variant_weeks(program_name);

-- Add comment for documentation
COMMENT ON COLUMN program_variant_weeks.program_name IS 'Program name from PROGRAMS_CHECKLIST.md';
COMMENT ON COLUMN program_variant_weeks.priority IS 'Priority level: High, Med, Low from checklist';
COMMENT ON COLUMN program_variant_weeks.has_supersets IS 'Whether program supports supersets (SS column)';
COMMENT ON COLUMN program_variant_weeks.description IS 'Program description from checklist';
COMMENT ON COLUMN program_variant_weeks.category IS 'Category from checklist (e.g., Premium, Strength)';
