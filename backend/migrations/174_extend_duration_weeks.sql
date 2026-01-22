-- Migration: Extend allowed duration_weeks values
-- Purpose: Allow 16 and 24 week programs for comprehensive HYROX preparation

-- Drop the existing check constraint
ALTER TABLE program_variants
DROP CONSTRAINT IF EXISTS program_variants_duration_weeks_check;

-- Add new check constraint with extended values
ALTER TABLE program_variants
ADD CONSTRAINT program_variants_duration_weeks_check
CHECK (duration_weeks IN (2, 3, 4, 6, 8, 12, 16, 24));

-- Update comment
COMMENT ON COLUMN program_variants.duration_weeks IS 'Program length: 2, 3, 4, 6, 8, 12, 16, or 24 weeks - supports comprehensive race prep programs';
