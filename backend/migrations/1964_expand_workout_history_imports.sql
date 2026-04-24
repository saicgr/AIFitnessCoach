-- Migration: 1964_expand_workout_history_imports.sql
-- Description: Expand workout_history_imports to support rich per-set imports from
-- fitness apps (Hevy, Strong, Fitbod, Jefit, FitNotes, etc.) and creator programs
-- (Jeff Nippard, RP, Wendler, nSuns, GZCLP, etc.). Original schema held only
-- aggregated sets with sets=N and no per-set granularity — incompatible with
-- drop sets, warmup sets, RPE/RIR, supersets, and cardio time/distance.
--
-- Changes:
--   • Relax NOT NULL + >0 constraints on reps + weight_kg (bodyweight = null weight,
--     cardio = null reps, assisted = negative weight).
--   • Expand source CHECK to include 'ai_parsed' and 'synced' and 'program_filled'.
--   • Add per-set columns: workout_name, set_number, set_type, rpe, rir,
--     duration_seconds, distance_m, superset_id.
--   • Add resolution columns: exercise_id, exercise_name_canonical.
--   • Add dedup: source_app, source_row_hash (+ unique index).
--   • Add provenance: import_job_id, original_weight_value, original_weight_unit.

-- 1. Relax constraints to accept cardio / bodyweight / assisted rows.
ALTER TABLE workout_history_imports
  ALTER COLUMN reps DROP NOT NULL;

ALTER TABLE workout_history_imports
  DROP CONSTRAINT IF EXISTS workout_history_imports_reps_check;

ALTER TABLE workout_history_imports
  ADD CONSTRAINT workout_history_imports_reps_check
  CHECK (reps IS NULL OR reps >= 0);

ALTER TABLE workout_history_imports
  ALTER COLUMN weight_kg DROP NOT NULL;

ALTER TABLE workout_history_imports
  DROP CONSTRAINT IF EXISTS workout_history_imports_weight_kg_check;

-- No new check on weight_kg: allow null (bodyweight) and negative (assisted).

-- 2. Broaden source CHECK to cover every inbound channel.
ALTER TABLE workout_history_imports
  DROP CONSTRAINT IF EXISTS workout_history_imports_source_check;

ALTER TABLE workout_history_imports
  ADD CONSTRAINT workout_history_imports_source_check
  CHECK (source IN ('manual', 'import', 'spreadsheet', 'ai_parsed', 'synced', 'program_filled'));

-- 3. Extend columns.
ALTER TABLE workout_history_imports
  ADD COLUMN IF NOT EXISTS source_app TEXT,
  ADD COLUMN IF NOT EXISTS workout_name TEXT,
  ADD COLUMN IF NOT EXISTS set_number INTEGER,
  ADD COLUMN IF NOT EXISTS set_type TEXT DEFAULT 'working',
  ADD COLUMN IF NOT EXISTS rpe NUMERIC(3, 1),
  ADD COLUMN IF NOT EXISTS rir INTEGER,
  ADD COLUMN IF NOT EXISTS duration_seconds INTEGER,
  ADD COLUMN IF NOT EXISTS distance_m NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS superset_id TEXT,
  ADD COLUMN IF NOT EXISTS exercise_id UUID,
  ADD COLUMN IF NOT EXISTS exercise_name_canonical TEXT,
  ADD COLUMN IF NOT EXISTS source_row_hash TEXT,
  ADD COLUMN IF NOT EXISTS import_job_id UUID,
  ADD COLUMN IF NOT EXISTS original_weight_value NUMERIC(8, 3),
  ADD COLUMN IF NOT EXISTS original_weight_unit TEXT
  CHECK (original_weight_unit IS NULL OR original_weight_unit IN ('kg', 'lb', 'stone'));

-- 4. set_type whitelist — the five types every app exports.
ALTER TABLE workout_history_imports
  DROP CONSTRAINT IF EXISTS workout_history_imports_set_type_check;

ALTER TABLE workout_history_imports
  ADD CONSTRAINT workout_history_imports_set_type_check
  CHECK (set_type IN ('working', 'warmup', 'failure', 'dropset', 'amrap',
                      'cluster', 'rest_pause', 'backoff', 'assistance'));

-- 5. Dedup index — re-importing the same file is a no-op.
--    Hash includes: user_id | source_app | date | exercise | set_number | weight | reps.
--    Partial index so legacy rows (source_row_hash IS NULL) are unaffected.
CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_history_imports_source_hash
  ON workout_history_imports (user_id, source_row_hash)
  WHERE source_row_hash IS NOT NULL;

-- 6. Aggregation index for canonical-name lookups (matches the query the
--    weight-suggestion pipeline will issue per exercise).
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_user_canon_time
  ON workout_history_imports (user_id, exercise_name_canonical, performed_at DESC)
  WHERE exercise_name_canonical IS NOT NULL;

-- 7. Job provenance index (bulk-undo a failed import by job_id).
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_job
  ON workout_history_imports (import_job_id)
  WHERE import_job_id IS NOT NULL;

-- 8. Exercise-FK index for joining against the library.
CREATE INDEX IF NOT EXISTS idx_workout_history_imports_exercise_id
  ON workout_history_imports (exercise_id)
  WHERE exercise_id IS NOT NULL;

COMMENT ON COLUMN workout_history_imports.source_app IS
  'Fine-grained sub-source: hevy | strong | fitbod | jefit | fitnotes | gravitus | boostcamp | myfitnesspal | garmin | apple_health | nippard_powerbuilding_v3 | rp_male_physique_20 | wendler_531 | nsuns | gzclp | metallicadpa_ppl | starting_strength | stronglifts | lyle_gbr | bws_intermediate | buff_dudes | athlean | generic_csv | generic_sheet | ai_parsed_pdf | manual';
COMMENT ON COLUMN workout_history_imports.set_type IS
  'Set classification matching what major apps emit. Drop sets preserve set_number; each chain-link is a separate row.';
COMMENT ON COLUMN workout_history_imports.source_row_hash IS
  'sha256(user_id|source_app|date|exercise_canonical|set_number|round(weight_kg,1)|reps). Enables idempotent re-import.';
COMMENT ON COLUMN workout_history_imports.exercise_id IS
  'FK to exercise library when resolver confidently matched. NULL when user needs to remap via the bulk-remap sheet.';
COMMENT ON COLUMN workout_history_imports.original_weight_unit IS
  'Unit value was entered in before conversion to weight_kg. kg | lb | stone.';
