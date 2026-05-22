-- Migration 2090: Add sent_local_date to email_send_log for timezone-correct dedup
--
-- The lifecycle email cron (api/v1/email_cron.py) buckets trial-ending and
-- 7-day-upsell jobs by a calendar date. That date used to be computed in UTC
-- (`get_user_today("UTC")`), so a user near a UTC day boundary could land in
-- different buckets on consecutive hourly runs.
--
-- The cron now buckets per user in their OWN timezone. Because the existing
-- dedup key is `(user_id, email_type)` + a time-based cooldown window, simply
-- moving the bucket risks a boundary re-send: the same user's local-date period
-- could be evaluated twice as the local day rolls over relative to the cooldown
-- window edge.
--
-- This adds a nullable `sent_local_date` column. The cron writes the user's
-- local send date on every send and includes it in the `_was_recently_sent`
-- dedup check, so a user is never re-emailed for the same local-date period.
--
-- Nullable: pre-existing rows have no local date; the dedup check treats a
-- NULL match as "not the same local-date period" and falls back to the
-- cooldown-window guard, which preserves the old behavior for historical rows.

ALTER TABLE email_send_log
  ADD COLUMN IF NOT EXISTS sent_local_date DATE;

CREATE INDEX IF NOT EXISTS idx_email_send_log_user_type_local_date
  ON email_send_log(user_id, email_type, sent_local_date);

COMMENT ON COLUMN email_send_log.sent_local_date IS 'Calendar date (in the recipient user''s local timezone) the email was sent. Used by email_cron _was_recently_sent to prevent a re-send across a UTC day boundary. Nullable for rows written before migration 2090.';
