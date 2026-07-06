-- Migration 2314: user_program_templates.notes — routine-level notes for
-- user-authored / imported / parsed program templates. Mirrors the existing
-- `notes TEXT` column on workout_program_templates (mig 1966) and
-- saved_workouts (mig 029). Nullable, no default => safe, non-blocking,
-- no backfill.

BEGIN;

ALTER TABLE user_program_templates ADD COLUMN IF NOT EXISTS notes TEXT;

COMMIT;
