-- Migration 2241: personal_records.pr_type column (additive, idempotent)
--
-- FEATURE 3A: bodyweight exercises PR on REPS (more reps at bodyweight) rather than on
-- added load. We tag every PR row with its type so the UI can render "Rep PR" vs the
-- existing weight/1RM PRs and so analytics can segment them. Default 'weight' preserves
-- the meaning of every existing row (all pre-migration PRs are weighted lifts).
--
-- This migration is INDEPENDENT of the per-gym stream: it does NOT touch gym_profile_id.

ALTER TABLE personal_records
    ADD COLUMN IF NOT EXISTS pr_type TEXT NOT NULL DEFAULT 'weight';

-- Composite index for the per-exercise, per-type "best to beat" lookup.
CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise_prtype
    ON personal_records (user_id, exercise_name, pr_type);
