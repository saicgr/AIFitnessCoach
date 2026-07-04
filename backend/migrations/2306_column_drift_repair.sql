-- Migration 2306: Column-drift repair — add columns the shipped code already
-- reads/writes but that never got migrated (PostgREST 42703 killed the whole
-- query at each site; most failures were swallowed by try/except).
--
-- Found by scripts/audit_supabase_column_drift.py (2026-07-04 sweep):
--   1. email_send_log — the Resend webhook handler (api/v1/email_webhooks.py)
--      selects/updates status + delivery timestamps and correlates on
--      resend_email_id; none existed, so EVERY webhook event 500'd (unguarded
--      path → Resend retries).
--   2. app_tour_sessions — the tour start insert writes 5 phantom columns, so
--      NO tour session row has ever been created; step/complete updates write
--      3 more.
--   3. live_chat_queue — typing-indicator reads/writes reference two phantom
--      boolean columns.
--
-- All columns NULL-able / DEFAULT-ed — zero downtime, no backfill needed.

BEGIN;

-- ── 1. email_send_log: webhook deliverability audit trail ────────────
ALTER TABLE email_send_log ADD COLUMN IF NOT EXISTS resend_email_id TEXT;
ALTER TABLE email_send_log ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent';
ALTER TABLE email_send_log ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
ALTER TABLE email_send_log ADD COLUMN IF NOT EXISTS bounced_at TIMESTAMPTZ;
ALTER TABLE email_send_log ADD COLUMN IF NOT EXISTS complained_at TIMESTAMPTZ;
-- Webhook correlates events by Resend id
CREATE INDEX IF NOT EXISTS idx_email_send_log_resend_id
    ON email_send_log(resend_email_id) WHERE resend_email_id IS NOT NULL;

-- ── 2. app_tour_sessions: columns the tour endpoints write ───────────
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS platform TEXT;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'started';
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS deep_links_clicked JSONB DEFAULT '[]'::jsonb;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS skip_step INT;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS demo_workout_started BOOLEAN DEFAULT FALSE;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS demo_workout_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS plan_preview_viewed BOOLEAN DEFAULT FALSE;
ALTER TABLE app_tour_sessions ADD COLUMN IF NOT EXISTS total_duration_seconds INT;
-- Anonymous (pre-auth) tour dedup looks up by device
CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_device_id
    ON app_tour_sessions(device_id) WHERE device_id IS NOT NULL;

-- ── 3. live_chat_queue: typing indicators ────────────────────────────
ALTER TABLE live_chat_queue ADD COLUMN IF NOT EXISTS user_typing BOOLEAN DEFAULT FALSE;
ALTER TABLE live_chat_queue ADD COLUMN IF NOT EXISTS agent_typing BOOLEAN DEFAULT FALSE;

COMMIT;
