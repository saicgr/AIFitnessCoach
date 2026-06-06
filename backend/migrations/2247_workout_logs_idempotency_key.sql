-- 2247_workout_logs_idempotency_key.sql
--
-- Server-side double-log guard for workout_logs (mirrors 2245 for food_logs).
--
-- Workout-completion logging had no idempotency: a double-tap of "Finish" or a
-- 401-refresh Dio retry replaying the same body created two workout_log rows
-- for one session, double-counting volume / streak / leaderboard stats. The
-- client now sends a stable `idempotency_key` (one per workout completion,
-- keyed by workout_id); this migration makes it enforceable so a replay returns
-- the existing session row instead of duplicating it.
--
--   1. add the nullable column (legacy rows stay NULL),
--   2. a PARTIAL unique index on (user_id, idempotency_key) WHERE key IS NOT
--      NULL so the dedupe is per-user and never trips on the NULL legacy rows.

ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

COMMENT ON COLUMN workout_logs.idempotency_key IS
    'Client-generated key (migration 2247) deduping double-tap / auth-retry '
    'POSTs to /performance/workout-logs. NULL for legacy rows.';

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_logs_user_idempotency_key
    ON workout_logs (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;
