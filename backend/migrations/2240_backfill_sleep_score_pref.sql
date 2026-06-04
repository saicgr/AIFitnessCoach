-- Migration 2240: never re-notify a user who already turned the morning push OFF
--
-- FEATURE 1 adds a new per-type preference `sleep_score_nudge` (default true). But a
-- user who explicitly disabled the existing morning readiness briefing
-- (`daily_briefing_nudge` = false) clearly does not want a morning push. The new
-- sleep-score push fires in the SAME morning slot and is mutually exclusive with
-- daily_readiness (only one morning push per day) — so for those users we pre-seed
-- `sleep_score_nudge` = false so they are not re-enrolled into a morning push they
-- already opted out of.
--
-- Only users who set daily_briefing_nudge to the string 'false' are touched; everyone
-- else keeps the default-true behaviour (the key is simply absent and the cron reads
-- `prefs.get('sleep_score_nudge', True)`).
--
-- Idempotent: re-running just re-sets the same false value via the `||` merge.

UPDATE users
SET notification_preferences =
        COALESCE(notification_preferences, '{}'::jsonb)
        || jsonb_build_object('sleep_score_nudge', false)
WHERE (notification_preferences ->> 'daily_briefing_nudge') = 'false';
