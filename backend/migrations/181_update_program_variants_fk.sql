-- Migration: Update program_variants FK to reference branded_programs
-- Purpose: program_variants.base_program_id should reference branded_programs, not programs

-- Drop the old foreign key constraint
ALTER TABLE program_variants
DROP CONSTRAINT IF EXISTS program_variants_base_program_id_fkey;

-- Add new foreign key constraint referencing branded_programs
ALTER TABLE program_variants
ADD CONSTRAINT program_variants_base_program_id_fkey
FOREIGN KEY (base_program_id) REFERENCES branded_programs(id) ON DELETE CASCADE;

-- Add comment for clarity
COMMENT ON COLUMN program_variants.base_program_id IS 'References branded_programs.id for the parent program';
