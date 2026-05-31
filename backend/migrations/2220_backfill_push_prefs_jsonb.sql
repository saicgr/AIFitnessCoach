-- 2220: Backfill canonical push preferences into users.notification_preferences (JSONB)
--
-- WHY: Historically the device PUT /summaries/preferences wrote the
-- `notification_preferences` TABLE, but every server-side nudge cron
-- (push_nudge_cron, weekly_wrapped_cron) reads the `users.notification_preferences`
-- JSONB — which nothing wrote after onboarding. So users who changed their
-- notification settings under the old flow had those choices silently ignored
-- by the cron. The app code is now fixed to write the JSONB directly; this
-- one-time backfill carries forward the choices already captured in the table.
--
-- SAFETY:
--   * Table values WIN over the JSONB onboarding defaults via `existing || backfill`.
--     This is correct because, until this release, the device never wrote the
--     JSONB, so it only ever held onboarding defaults — the table is strictly
--     more authoritative for these keys.
--   * `push_notifications_enabled` is DELIBERATELY EXCLUDED: the legacy table
--     column defaulted to FALSE, while the cron treats an absent JSONB key as
--     TRUE (master push on). Backfilling the table's FALSE would silence push
--     for users who never opted out. The device resends the real master-toggle
--     value (default true) on its next sync.
--   * `weekly_summary_day` is EXCLUDED: the table stores it as a string
--     ('sunday') but the JSONB canonical form is an int (0-6). The device
--     resends the int on next sync; mixing types here would break the cron's
--     day comparison.
--   * jsonb_strip_nulls drops any null pairs so we never write nulls into the
--     JSONB.
--
-- Idempotent: re-running merges the same values; safe to run more than once.

-- Time columns on the table are Postgres TIME ("09:00:00"); the JSONB and the
-- cron's _parse_time_hour expect "HH:MM". substring(...::text, 1, 5) normalises
-- both TIME and TEXT representations to "HH:MM" so the backfill never writes a
-- seconds-format string into the JSONB.
UPDATE public.users u
SET notification_preferences =
    COALESCE(u.notification_preferences, '{}'::jsonb)
    || jsonb_strip_nulls(jsonb_build_object(
        'workout_reminders',   np.push_workout_reminders,
        'streak_alerts',       np.push_achievement_alerts,
        'weekly_summary',      np.push_weekly_summary,
        'hydration_reminders', np.push_hydration_reminders,
        'weekly_summary_time', substring(np.weekly_summary_time::text from 1 for 5),
        'quiet_hours_start',   substring(np.quiet_hours_start::text   from 1 for 5),
        'quiet_hours_end',     substring(np.quiet_hours_end::text     from 1 for 5)
    ))
FROM public.notification_preferences np
WHERE np.user_id = u.id;

-- Note: the new flagship keys (evening_recap_nudge / evening_recap_time) and
-- the reused morning-readiness keys (daily_briefing_nudge / daily_briefing_time)
-- need NO DDL — notification_preferences is schemaless JSONB and the cron reads
-- them with safe defaults (evening_recap_nudge -> True, evening_recap_time ->
-- "20:00", daily_briefing_time -> "08:00") until the device first syncs them.
