-- Migration 2041: Onboarding v5 fields
-- Adds 11 new optional columns to users table to support the redesigned
-- Cal AI–informed onboarding flow + trial conversion mechanics.
--
-- Categories:
--   1. Market research (referral_source, prior_apps_tried)
--   2. Personalization extensions (referral_code, coach_name)
--   3. One-time UX flags (seen_founder_note, commitment_pact_*)
--   4. Trial mechanics (trial_start_date, goal_target_date, paused_at, pause_duration_days)
--
-- All columns are NULL-able / DEFAULT-ed so existing users are unaffected.
-- No data migration required — zero downtime.

BEGIN;

-- ── Market research ───────────────────────────────────────────────
-- Captured during pre-auth quiz; analytics value even for non-converters.
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_source TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS prior_apps_tried JSONB DEFAULT '[]'::jsonb;

-- ── Personalization ──────────────────────────────────────────────
-- referral_code: optional discount code entered during setup
-- coach_name: user-customized name for their AI coach (loss aversion lever)
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS coach_name TEXT;

-- ── One-time UX flags ────────────────────────────────────────────
-- seen_founder_note: gates the post-signup founder welcome sheet (Base Camp pattern)
-- commitment_pact_*: tracks user's "I'm in" commitment to week 1 plan
ALTER TABLE users ADD COLUMN IF NOT EXISTS seen_founder_note BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS commitment_pact_accepted BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS commitment_pact_accepted_at TIMESTAMPTZ;

-- ── Trial mechanics ──────────────────────────────────────────────
-- trial_start_date: anchors Day X / 7 calculations and goal date math
-- goal_target_date: computed weight projection date, anchored throughout trial
-- paused_at + pause_duration_days: pause-on-cancel intercept state
ALTER TABLE users ADD COLUMN IF NOT EXISTS trial_start_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS goal_target_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pause_duration_days INT;

-- ── Indexes ──────────────────────────────────────────────────────
-- referral_source for cohort analytics
CREATE INDEX IF NOT EXISTS idx_users_referral_source ON users(referral_source) WHERE referral_source IS NOT NULL;
-- trial_start_date for trial-end cron jobs (Day 6 message, Day 7 summary)
CREATE INDEX IF NOT EXISTS idx_users_trial_start_date ON users(trial_start_date) WHERE trial_start_date IS NOT NULL;
-- paused_at for un-pause cron
CREATE INDEX IF NOT EXISTS idx_users_paused_at ON users(paused_at) WHERE paused_at IS NOT NULL;

COMMIT;
