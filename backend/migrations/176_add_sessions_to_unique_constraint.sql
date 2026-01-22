-- Migration: Update unique constraint to include sessions_per_week
-- Purpose: Allow both 5-day and 6-day variants of the same program/intensity/duration

-- Drop existing unique constraint
ALTER TABLE program_variants
DROP CONSTRAINT IF EXISTS program_variants_base_program_id_intensity_level_duration_w_key;

-- Add new unique constraint including sessions_per_week
ALTER TABLE program_variants
ADD CONSTRAINT program_variants_unique_variant
UNIQUE (base_program_id, intensity_level, duration_weeks, sessions_per_week);

-- Update index for the new constraint
DROP INDEX IF EXISTS idx_program_variants_lookup;
CREATE INDEX idx_program_variants_lookup
ON program_variants(base_program_id, intensity_level, duration_weeks, sessions_per_week);
