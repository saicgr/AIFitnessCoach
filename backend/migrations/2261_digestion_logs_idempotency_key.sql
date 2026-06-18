-- 2261_digestion_logs_idempotency_key.sql
--
-- Nutrition overhaul — server-side double-log guard for digestion_logs,
-- mirroring food_logs (migration 2245). FE-B's digestion_repository.dart sends
-- a client-generated `idempotency_key` on POST /nutrition/digestion so a rapid
-- double-tap of the Bristol logger, an offline-queued entry replayed on
-- reconnect, or a 401-refresh Dio retry cannot create two identical rows.
--
-- 2259 created digestion_logs WITHOUT this column; this adds it separately
-- because 2259 is already applied. Nullable (legacy + non-keyed paths stay
-- NULL); a PARTIAL unique index dedupes only non-NULL keys, scoped per user.

ALTER TABLE digestion_logs
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

COMMENT ON COLUMN digestion_logs.idempotency_key IS
    'Client-generated key deduping double-tap / offline-replay / auth-retry '
    'POSTs to /nutrition/digestion. NULL for legacy + paths that omit one.';

CREATE UNIQUE INDEX IF NOT EXISTS uq_digestion_logs_user_idempotency_key
    ON digestion_logs (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;
