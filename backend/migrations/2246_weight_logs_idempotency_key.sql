-- 2246_weight_logs_idempotency_key.sql
--
-- Server-side double-log guard for weight_logs (mirrors 2245 for food_logs).
--
-- Weight logging had no idempotency: a rapid double-tap of "Save weight" or a
-- 401-refresh Dio retry firing the same body created two weight_log rows at the
-- same timestamp, polluting the trend graph and adaptive-TDEE math. The client
-- now sends a deterministic `idempotency_key` (user + weight + minute bucket);
-- this migration makes it enforceable so a replay returns the existing row.
--
--   1. add the nullable column (legacy rows stay NULL),
--   2. a PARTIAL unique index on (user_id, idempotency_key) WHERE key IS NOT
--      NULL so the dedupe is per-user and never trips on the NULL legacy rows.

ALTER TABLE weight_logs
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

COMMENT ON COLUMN weight_logs.idempotency_key IS
    'Client-generated key (migration 2246) deduping double-tap / auth-retry '
    'POSTs to /nutrition/weight-logs. NULL for legacy rows.';

CREATE UNIQUE INDEX IF NOT EXISTS uq_weight_logs_user_idempotency_key
    ON weight_logs (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;
