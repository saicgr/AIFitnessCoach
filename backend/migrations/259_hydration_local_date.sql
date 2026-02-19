-- Add local_date column to hydration_logs for timezone-correct day grouping
-- The server stores logged_at in UTC, but the user's local date may differ
-- (e.g., 11 PM IST on Feb 17 = 5:30 PM UTC Feb 17, but user sees it as Feb 17)

ALTER TABLE hydration_logs ADD COLUMN IF NOT EXISTS local_date DATE;

-- Backfill existing rows: derive local_date from logged_at (best effort, assumes UTC ~ local)
UPDATE hydration_logs
SET local_date = (logged_at AT TIME ZONE 'UTC')::DATE
WHERE local_date IS NULL;

-- Index for fast queries by user + local_date
CREATE INDEX IF NOT EXISTS idx_hydration_logs_user_local_date
ON hydration_logs (user_id, local_date);
