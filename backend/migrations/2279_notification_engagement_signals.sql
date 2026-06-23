-- 2279_notification_engagement_signals.sql
-- Dormancy-aware push suppression + re-engagement taper (Goal 1).
--
-- Adds the missing "last app open / last-active" signal so the push cron can
-- TAPER notifications for quiet users instead of escalating guilt nudges.
-- Today inactivity is inferred only from workout_logs.completed_at, so a light
-- user who opens the app but logs little looks "inactive" and gets flooded.
--
-- last_active_at is written (non-blocking) on every foreground app open via
-- /home/bootstrap and on FCM register (login / token refresh / reinstall).
-- NULL is the fail-open sentinel: a user with no signal is treated as ACTIVE,
-- so an active user can never be accidentally silenced on rollout day.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz;

-- Optional per-user override for the rolling weekly push cap. NULL = use the
-- band default (WEEKLY_CAP_BY_BAND in push_nudge_cron.py).
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS weekly_nudge_limit smallint;

COMMENT ON COLUMN public.users.last_active_at IS
  'Last time the user opened the app in the foreground (bootstrap / FCM register). Drives dormancy bands in push_nudge_cron. NULL = treated as active (fail-open).';
COMMENT ON COLUMN public.users.weekly_nudge_limit IS
  'Optional per-user override for the rolling 7-day push cap. NULL = band default.';
