-- Email + notification overhaul schema additions.
--
-- Ships with the new email system (Day-3/streak/weekly/lifecycle rewrites,
-- post-cancel ladder, engagement-bucket nudges, per-category unsubscribe).
--
-- Principles:
-- 1. Every new category of email must have a matching user-facing toggle.
-- 2. Cross-channel dedup needs `status` on send logs so bounces stop sending.
-- 3. Internal / test accounts must be flagged so cron skips them.
-- 4. Vacation mode ("pause all for N days") needs a timestamp to compare.
-- 5. Missed-meal follow-up is opt-in per the user feedback (avoid spam).
--
-- All columns default to safe values so this migration is backfill-free.

BEGIN;

-- ── email_preferences: category-per-column model ────────────────────────────
-- The old 5-column layout (workout_reminders, weekly_summary, coach_tips,
-- product_updates, promotional) is preserved. New columns add the categories
-- that didn't exist: streak alerts, motivational, missed-workout, achievements,
-- billing & account (required), plus a deliverable flag for bounce handling.

ALTER TABLE public.email_preferences
  ADD COLUMN IF NOT EXISTS streak_alerts          BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS motivational_nudges    BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS missed_workout_alerts  BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS achievement_alerts     BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS billing_account        BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS deliverable            BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS notifications_paused_until TIMESTAMPTZ;

COMMENT ON COLUMN public.email_preferences.streak_alerts IS
  'Fires for streak-at-risk emails. Independent of workout_reminders so users can keep streak protection without daily workout nudges.';
COMMENT ON COLUMN public.email_preferences.motivational_nudges IS
  'Covers day-3 activation, onboarding-incomplete, comeback, idle-nudge, one-workout-wonder.';
COMMENT ON COLUMN public.email_preferences.missed_workout_alerts IS
  'Separate from workout_reminders — reminders fire before scheduled time, missed-workout fires after.';
COMMENT ON COLUMN public.email_preferences.achievement_alerts IS
  'N1 trophy emails + first-workout-done celebration.';
COMMENT ON COLUMN public.email_preferences.billing_account IS
  'Purchase confirmation, billing issues, trial expiry, cancellation. Cannot be fully disabled in UI — grayed out with legal explanation.';
COMMENT ON COLUMN public.email_preferences.deliverable IS
  'Flipped to false after 3 hard bounces or a complaint. Suppresses all sends until address is verified again.';
COMMENT ON COLUMN public.email_preferences.notifications_paused_until IS
  'Vacation mode. If > now(), skip all non-transactional sends. User sets from Settings → Take a break.';

-- ── email_send_log: status + metadata for Resend webhook ────────────────────

ALTER TABLE public.email_send_log
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'sent',
  ADD COLUMN IF NOT EXISTS resend_email_id TEXT,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS bounced_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS complained_at TIMESTAMPTZ;

COMMENT ON COLUMN public.email_send_log.status IS
  'sent | delivered | bounced | complained | failed. Updated by the Resend webhook handler.';
COMMENT ON COLUMN public.email_send_log.resend_email_id IS
  'Resend API email_id so webhook events can find the matching send-log row.';

CREATE INDEX IF NOT EXISTS idx_email_send_log_resend_email_id
  ON public.email_send_log(resend_email_id) WHERE resend_email_id IS NOT NULL;

-- ── users: internal flag so test accounts never receive lifecycle mail ──────

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_internal BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.users.is_internal IS
  'Team / test / QA accounts. Email cron jobs must skip users with is_internal=true.';

-- ── notification_preferences: missed-meal follow-up opt-in ──────────────────
-- The push system already has a rich notification_preferences table. Adding
-- one more toggle for the new missed-meal follow-up nudge.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='notification_preferences') THEN
    BEGIN
      ALTER TABLE public.notification_preferences
        ADD COLUMN IF NOT EXISTS missed_meal_followup BOOLEAN NOT NULL DEFAULT FALSE;
      COMMENT ON COLUMN public.notification_preferences.missed_meal_followup IS
        'OPT-IN. If a scheduled meal time + 2h passes unlogged, send a soft nudge. Off by default to avoid spam.';
    EXCEPTION WHEN duplicate_column THEN NULL;
    END;
  END IF;
END $$;

COMMIT;
