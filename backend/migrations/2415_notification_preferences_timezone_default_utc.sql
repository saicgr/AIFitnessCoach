-- Migration: Fix notification_preferences.timezone defaulting to America/New_York
-- for every new row regardless of the device's actual zone (finding #38).
-- Scheduling itself reads users.timezone (default 'UTC', populated from the
-- device at signup) — this legacy mirror column should not silently assume
-- Eastern for a fresh row on a Central/Pacific/international device.

ALTER TABLE notification_preferences
ALTER COLUMN timezone SET DEFAULT 'UTC';

-- VERIFY: select column_default from information_schema.columns where table_name='notification_preferences' and column_name='timezone';
