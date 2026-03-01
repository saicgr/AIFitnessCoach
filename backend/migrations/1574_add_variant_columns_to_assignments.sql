-- Add variant tracking columns to user_program_assignments
-- Allows storing the selected variant and desired duration when a user starts a program

ALTER TABLE user_program_assignments
  ADD COLUMN IF NOT EXISTS variant_id UUID REFERENCES program_variants(id),
  ADD COLUMN IF NOT EXISTS desired_weeks INTEGER,
  ADD COLUMN IF NOT EXISTS sessions_per_week INTEGER;

-- Index for looking up assignments by variant
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_variant_id
  ON user_program_assignments(variant_id)
  WHERE variant_id IS NOT NULL;
