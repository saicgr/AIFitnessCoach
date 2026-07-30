-- 2342_performance_logs_unique_set_key.sql
--
-- E2E register #71 — "re-running a workout DOUBLES its logged sets".
--
-- The `workout_logs` row is reused across re-runs (the client's
-- idempotency_key is derived from the workout id), but every set was
-- re-INSERTed into `performance_logs` with no dedup, so a 15-set session came
-- back with 20 rows: inflated volume, inflated set counts, and enough material
-- to mint a phantom PR. Proven in production on workout_log
-- d7c09081-656c-4ff5-ba58-03a84b2fe21d (20 rows for 13 logged sets; all 7
-- pairs from run 1 had a twin from run 2 recorded ~7.5 h later).
--
-- The write endpoints now upsert on the natural key
-- (workout_log_id, exercise_name, set_number). This migration makes that a
-- DATABASE guarantee so no future writer — server, watch sync, backfill script
-- or replay queue — can reintroduce the duplication.
--
-- Steps:
--   1. Back the losing rows up into performance_logs_dedup_backup_2342
--      (logged-data durability: nothing the user recorded is deleted without a
--      restorable copy).
--   2. Delete them, keeping the LATEST row per key — a re-run's newer numbers
--      are what the user actually just performed.
--   3. CREATE UNIQUE INDEX CONCURRENTLY on the natural key.
--
-- Verified before writing: no session in production legitimately repeats the
-- triple. `workout_logs.sets_json` has ZERO sessions where one exercise_name
-- spans more than one exercise_index, so a circuit repeating the same movement
-- is not a shape this schema produces; every one of the 26 duplicate groups
-- found (29 extra rows, 2 sessions) was a re-run, hours or days apart.

BEGIN;

-- 1. Durable backup of every row this migration removes.
CREATE TABLE IF NOT EXISTS performance_logs_dedup_backup_2342 (
    LIKE performance_logs
);

ALTER TABLE performance_logs_dedup_backup_2342
    ADD COLUMN IF NOT EXISTS backed_up_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE performance_logs_dedup_backup_2342
    ADD COLUMN IF NOT EXISTS kept_row_id uuid;

WITH ranked AS (
    SELECT
        id,
        first_value(id) OVER (
            PARTITION BY workout_log_id, exercise_name, set_number
            ORDER BY recorded_at DESC NULLS LAST, id DESC
        ) AS keeper_id,
        row_number() OVER (
            PARTITION BY workout_log_id, exercise_name, set_number
            ORDER BY recorded_at DESC NULLS LAST, id DESC
        ) AS rn
    FROM performance_logs
)
INSERT INTO performance_logs_dedup_backup_2342
SELECT pl.*, now(), r.keeper_id
FROM performance_logs pl
JOIN ranked r ON r.id = pl.id
WHERE r.rn > 1;

-- 2. Keep only the newest row per natural key.
WITH ranked AS (
    SELECT
        id,
        row_number() OVER (
            PARTITION BY workout_log_id, exercise_name, set_number
            ORDER BY recorded_at DESC NULLS LAST, id DESC
        ) AS rn
    FROM performance_logs
)
DELETE FROM performance_logs pl
USING ranked r
WHERE r.id = pl.id
  AND r.rn > 1;

COMMIT;

-- 3. The durable guarantee. CONCURRENTLY so no ACCESS EXCLUSIVE lock is taken
--    on a table the active-workout screen writes to; must run outside a
--    transaction block.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_performance_logs_set_natural_key
    ON performance_logs (workout_log_id, exercise_name, set_number);
