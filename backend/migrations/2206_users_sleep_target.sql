-- Migration 2201 — bedtime window signal upstream.
--
-- Adds `target_sleep_minutes` (default 480 = 8h) and `wake_alarm_local_time`
-- (HH:MM string, nullable) to `users`. Powers the bedtime_window_tile home
-- card via GET /api/v1/users/me/sleep-target.
--
-- Idempotent.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS target_sleep_minutes integer NOT NULL DEFAULT 480;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS wake_alarm_local_time text;

-- Soft guard: HH:MM (24h) when present. Skipping constraint here for forward
-- compatibility with NULL rows and to keep the migration purely additive.
COMMENT ON COLUMN users.target_sleep_minutes IS
    'Desired nightly sleep target in minutes (default 480 = 8h). Used by bedtime window card.';
COMMENT ON COLUMN users.wake_alarm_local_time IS
    'User-set wake alarm in local 24h HH:MM. NULL means card stays collapsed.';
