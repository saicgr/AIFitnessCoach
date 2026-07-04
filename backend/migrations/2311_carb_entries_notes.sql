-- Migration 2311: carb_entries.notes — the carb-entry logging endpoint has
-- always written a user-entered notes field; the column never existed, so
-- every carb log insert PGRST204'd (part of the 2026-07-04 drift sweep,
-- caught by live-testing the repaired insert — variable dicts escape the
-- static AST gate).

BEGIN;

ALTER TABLE carb_entries ADD COLUMN IF NOT EXISTS notes TEXT;

COMMIT;
