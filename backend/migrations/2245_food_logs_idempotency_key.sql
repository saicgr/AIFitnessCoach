-- 2245_food_logs_idempotency_key.sql
--
-- Server-side double-log guard for food_logs.
--
-- The Log Meal client (WR9 / A11) already generates and sends an
-- `idempotency_key` in the /nutrition/log-direct body so a rapid double-tap of
-- "Log This Meal" — or an offline-queued meal replayed on reconnect, or a
-- 401-refresh request replay in the Dio interceptor — cannot create two rows.
-- But the backend silently dropped the field (not on LogDirectRequest) and
-- `create_food_log` did a bare INSERT, so the guard was a no-op: any time two
-- identical POSTs reached the server (e.g. an auth-refresh retry firing the
-- same body) the user got two identical food_log rows at the same timestamp.
--
-- This migration makes the key enforceable:
--   1. add the nullable column (legacy rows + non-log-direct paths stay NULL),
--   2. a PARTIAL unique index on (user_id, idempotency_key) WHERE key IS NOT
--      NULL so the dedupe is per-user and never trips on the NULL legacy rows.
--
-- The backend uses this index: on insert it catches the unique violation and
-- returns the pre-existing row, making /log-direct idempotent.

ALTER TABLE food_logs
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

COMMENT ON COLUMN food_logs.idempotency_key IS
    'Client-generated key (WR9/A11) deduping double-tap / offline-replay / '
    'auth-retry POSTs to /nutrition/log-direct. NULL for legacy + paths that '
    'do not supply one.';

-- Partial unique index: only non-NULL keys are deduped, scoped per user.
CREATE UNIQUE INDEX IF NOT EXISTS uq_food_logs_user_idempotency_key
    ON food_logs (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;
