-- 2222: Injury-recovery check-in — new per-type notification toggle
--
-- WHY: Workstream B adds the recovery lifecycle check-in (_job_injury_recovery
-- in push_nudge_cron.py). When a logged injury reaches its recovery /
-- reintroduction phase the coach sends ONE grounded "still bothering you?"
-- check-in carrying All-better / Still-sore (and, when rehab exists for the
-- phase, Do-a-rehab-session) chips. It is gated by its own per-type preference
-- key, mirroring the WS3 data-grounded moments (2221):
--
--   injury_checkin_nudge — recovery-phase injury check-in (All better / Still
--                          sore / Do a rehab session)
--
-- STORAGE: users.notification_preferences is schemaless JSONB. The cron reads
-- the key with a safe default of TRUE (`prefs.get("injury_checkin_nudge",
-- True)`), so NO DDL is required and the toggle works the moment WS-B ships,
-- even before the device first syncs it. This migration only BACKFILLS the
-- canonical TRUE default so every existing user's JSONB explicitly carries the
-- key (keeps the server-side state legible and matches the Flutter model
-- default of `injuryCheckinNudge = true`).
--
-- Default ON: the check-in is low-frequency by nature — it only fires when a
-- real logged injury reaches its recovery window, and a 4-day cooldown
-- (_sent_within_days(..., "injury_recovery", days=4)) plus the per-run daily
-- nudge cap bound it so it can never nag. No noisier-default exclusion is
-- warranted.
--
-- SAFETY:
--   * `existing || backfill` keeps any value the user already chose — we never
--     overwrite an explicit opt-out. (Until WS-B, this key did not exist in the
--     JSONB, so this run simply seeds the TRUE default; a re-run after a user
--     opts out preserves their FALSE.)
--   * Only seeds users who already have a notification_preferences object.
--   * Idempotent: re-running merges the same default; safe to run repeatedly.

UPDATE public.users u
SET notification_preferences =
    jsonb_build_object(
        'injury_checkin_nudge', true
    )
    || COALESCE(u.notification_preferences, '{}'::jsonb)
WHERE u.notification_preferences IS NOT NULL;
