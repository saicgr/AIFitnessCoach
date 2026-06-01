-- 2221: WS3 — new per-type notification toggles for the data-grounded moments
--
-- WHY: Workstream 3 adds five new data-grounded coach notification moments,
-- each gated by its own per-type preference key, mirroring the Phase-C2 health
-- coaching toggles (daily_briefing_nudge / evening_recap_nudge / ...):
--
--   weekly_recap_nudge    — flagship Sunday-evening data-grounded WEEK wrap
--   sleep_debt_nudge      — 3+ short nights in a row, recovery-protective nudge
--   rhr_trend_nudge       — resting HR creeping above baseline (early signal)
--   protein_trend_nudge   — under protein target multiple days
--   volume_balance_nudge  — weekly training-volume swing (deload-or-push)
--
-- STORAGE: users.notification_preferences is schemaless JSONB. The cron reads
-- each key with a safe default of TRUE (`prefs.get("<key>", True)`), so NO DDL
-- is required and these toggles work the moment WS3 ships, even before the
-- device first syncs them. This migration only BACKFILLS the canonical TRUE
-- defaults so every existing user's JSONB explicitly carries the keys (keeps
-- the server-side state legible and matches the Flutter model defaults).
--
-- All five default ON: they are low-frequency by nature (weekly_recap fires
-- once a week on the user's week-end day; the trend nudges are cooldown-gated
-- to several days apart and only fire when their real-data trigger holds), so
-- they cannot spam — the per-run daily cap still bounds them with every other
-- nudge. No noisier-default exclusions are warranted here.
--
-- SAFETY:
--   * `existing || backfill` means any value the user already chose WINS — we
--     never overwrite an explicit opt-out. (Until WS3, none of these keys
--     existed in the JSONB, so this run simply seeds the TRUE defaults; a
--     re-run after a user opts out preserves their FALSE.)
--   * Only seeds users who have a notification_preferences object already.
--   * Idempotent: re-running merges the same defaults; safe to run repeatedly.

UPDATE public.users u
SET notification_preferences =
    jsonb_build_object(
        'weekly_recap_nudge',   true,
        'sleep_debt_nudge',     true,
        'rhr_trend_nudge',      true,
        'protein_trend_nudge',  true,
        'volume_balance_nudge', true
    )
    || COALESCE(u.notification_preferences, '{}'::jsonb)
WHERE u.notification_preferences IS NOT NULL;
