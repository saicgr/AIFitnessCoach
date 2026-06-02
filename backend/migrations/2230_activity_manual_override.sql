-- Migration 2230: Editable health data — manual override lock (Gap 5)
-- "You can edit anything." When a user corrects a Health-Connect sleep night
-- ("I wasn't wearing it") or a past day's steps, that correction must STICK —
-- a later wearable re-sync must not silently overwrite it. We record which
-- columns the user has manually locked; the upsert path preserves locked
-- columns against automatic syncs (a fresh manual edit re-locks / updates).

ALTER TABLE daily_activity
    ADD COLUMN IF NOT EXISTS manual_override_fields TEXT[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN daily_activity.manual_override_fields IS
    'Gap 5 — column names the user manually edited; automatic syncs must not overwrite these.';
