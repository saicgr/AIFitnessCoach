-- Migration 2312: extend diabetes_medication_type enum with the values the
-- API contract actually sends (AddMedicationRequest.medication_type:
-- "oral" (default) / "injectable" / "insulin"). The enum was authored with a
-- drug-class taxonomy (metformin, glp1_agonist, …) the app never used, so
-- every add-medication insert failed on 22P02. Extending the enum preserves
-- exactly what the user logged; both taxonomies remain valid.
-- (Part of the 2026-07-04 drift sweep — caught by live insert testing;
-- enum mismatches are invisible to the column-name gate.)

ALTER TYPE diabetes_medication_type ADD VALUE IF NOT EXISTS 'oral';
ALTER TYPE diabetes_medication_type ADD VALUE IF NOT EXISTS 'injectable';
ALTER TYPE diabetes_medication_type ADD VALUE IF NOT EXISTS 'insulin';
