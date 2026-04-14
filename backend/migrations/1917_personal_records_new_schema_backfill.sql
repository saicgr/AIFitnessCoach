-- Migration 1917: personal_records new-schema backfill
--
-- Context: Migration 057_scores_system.sql intended to define personal_records
-- with columns (weight_kg, reps, estimated_1rm_kg, ...) but used
-- `CREATE TABLE IF NOT EXISTS`, which silently no-op'd because 010_achievements.sql
-- had already created the table with an older schema (record_type, record_value,
-- record_unit, previous_value, improvement_percentage).
--
-- Result: scores_endpoints.py, crud_completion.py, and personal_records_service.py
-- all read/write new-schema columns that never existed on the live table, causing
-- KeyError: 'weight_kg' on every /api/v1/scores/overview request and silently
-- failing PR inserts on workout completion.
--
-- This migration:
--   1. Adds the new-schema columns as nullable (coexists with old-schema usage in
--      achievements.py).
--   2. Drops NOT NULL on the old columns so new-style inserts (which don't set them)
--      succeed.
--   3. Drops the (user_id, exercise_name, record_type) unique index — the new schema
--      allows multiple PRs per exercise.
--   4. Backfills weight_Xrm rows → (weight_kg, reps, estimated_1rm_kg via Epley).
--   5. Merges sibling 'estimated_1rm' rows into their weight_Xrm companion (exact
--      1RM overrides the Epley estimate), then deletes the redundant sibling.

ALTER TABLE personal_records
  ADD COLUMN IF NOT EXISTS exercise_id UUID,
  ADD COLUMN IF NOT EXISTS muscle_group TEXT,
  ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(6,2),
  ADD COLUMN IF NOT EXISTS reps INTEGER,
  ADD COLUMN IF NOT EXISTS estimated_1rm_kg DECIMAL(6,2),
  ADD COLUMN IF NOT EXISTS set_type TEXT DEFAULT 'working',
  ADD COLUMN IF NOT EXISTS rpe DECIMAL(3,1),
  ADD COLUMN IF NOT EXISTS previous_weight_kg DECIMAL(6,2),
  ADD COLUMN IF NOT EXISTS previous_1rm_kg DECIMAL(6,2),
  ADD COLUMN IF NOT EXISTS improvement_kg DECIMAL(6,2),
  ADD COLUMN IF NOT EXISTS improvement_percent DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS is_all_time_pr BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS celebration_message TEXT;

ALTER TABLE personal_records ALTER COLUMN record_type DROP NOT NULL;
ALTER TABLE personal_records ALTER COLUMN record_value DROP NOT NULL;
ALTER TABLE personal_records ALTER COLUMN record_unit DROP NOT NULL;

DROP INDEX IF EXISTS idx_personal_records_unique;

CREATE INDEX IF NOT EXISTS idx_personal_records_achieved_at
  ON personal_records(user_id, achieved_at DESC);

-- Epley 1RM: weight * (1 + reps/30)
UPDATE personal_records
SET
  weight_kg = record_value,
  reps = SUBSTRING(record_type FROM 'weight_(\d+)rm')::INTEGER,
  estimated_1rm_kg = ROUND(
    (record_value * (1.0 + SUBSTRING(record_type FROM 'weight_(\d+)rm')::INTEGER::NUMERIC / 30.0))::NUMERIC, 2
  ),
  is_all_time_pr = TRUE,
  set_type = COALESCE(set_type, 'working')
WHERE record_type ~ '^weight_\d+rm$'
  AND weight_kg IS NULL;

UPDATE personal_records pr
SET estimated_1rm_kg = sibling.record_value
FROM personal_records sibling
WHERE sibling.record_type = 'estimated_1rm'
  AND pr.record_type ~ '^weight_\d+rm$'
  AND pr.user_id = sibling.user_id
  AND pr.exercise_name = sibling.exercise_name
  AND pr.achieved_at = sibling.achieved_at
  AND pr.id <> sibling.id;

DELETE FROM personal_records pr
WHERE pr.record_type = 'estimated_1rm'
  AND EXISTS (
    SELECT 1 FROM personal_records sibling
    WHERE sibling.record_type ~ '^weight_\d+rm$'
      AND sibling.user_id = pr.user_id
      AND sibling.exercise_name = pr.exercise_name
      AND sibling.achieved_at = pr.achieved_at
      AND sibling.id <> pr.id
  );

UPDATE personal_records
SET estimated_1rm_kg = record_value, is_all_time_pr = TRUE
WHERE record_type = 'estimated_1rm' AND estimated_1rm_kg IS NULL;
