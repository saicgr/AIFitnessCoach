-- Migration 2203 — wearable_status table.
--
-- Stores the most recently reported connected-wearable battery state so the
-- wearable_battery_chip on home can self-collapse cleanly when battery is
-- healthy or unknown. Single row per user (PK = user_id). The device-side
-- write path lands later; the GET endpoint reads this table.
--
-- Idempotent.

CREATE TABLE IF NOT EXISTS wearable_status (
    user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    source text,                  -- 'apple_watch' | 'garmin' | 'whoop' | ...
    battery_pct integer,          -- 0..100, NULL when unknown
    last_synced_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS wearable_status_user_id_idx
    ON wearable_status(user_id);

COMMENT ON TABLE wearable_status IS
    'Latest wearable battery + sync snapshot. One row per user.';
