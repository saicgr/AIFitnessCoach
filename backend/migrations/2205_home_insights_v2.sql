-- 2201_home_insights_v2.sql
-- Schema additions for home_insights_v2 endpoints:
--   - /insights/jet-lag           needs last_seen_timezone + last_seen_timezone_at
--   - /insights/weigh-in-day-pref needs weigh_in_weekday (0=Mon..6=Sun)
--
-- Idempotent: safe to re-run.

ALTER TABLE user_ai_settings
  ADD COLUMN IF NOT EXISTS last_seen_timezone TEXT,
  ADD COLUMN IF NOT EXISTS last_seen_timezone_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS weigh_in_weekday SMALLINT
    CHECK (weigh_in_weekday IS NULL OR (weigh_in_weekday >= 0 AND weigh_in_weekday <= 6));

COMMENT ON COLUMN user_ai_settings.last_seen_timezone IS
  'Most recent device IANA tz reported via GET /insights/jet-lag';
COMMENT ON COLUMN user_ai_settings.last_seen_timezone_at IS
  'Timestamp the last_seen_timezone was last refreshed; used for 7-day jet-lag window';
COMMENT ON COLUMN user_ai_settings.weigh_in_weekday IS
  'User-chosen weekly weigh-in day, 0=Monday..6=Sunday; NULL = no preference';
