-- Migration 1941: Vacation mode
--
-- Adds user-controlled vacation mode that suppresses non-critical notifications.
-- Parallels the existing in_comeback_mode columns (migration 083) — same table,
-- same shape (bool + date range).
--
-- Semantics:
--   in_vacation_mode = TRUE          → flag is set
--   vacation_start_date NULL         → active immediately on flag set
--   vacation_end_date NULL           → "until I turn it off" (open-ended)
--   today NOT IN [start, end]        → scheduled but not yet, or expired
--
-- Backend treats expiry lazily — the flag may stay TRUE past end_date until
-- the user or a cleanup job clears it; the suppression helper only returns
-- true while today falls inside the window (in the user's local timezone).
--
-- Critical notifications that bypass vacation mode (billing, live chat,
-- subscription lifecycle) are whitelisted in services/notification_suppression.py.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS in_vacation_mode BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS vacation_start_date DATE,
  ADD COLUMN IF NOT EXISTS vacation_end_date DATE;

-- Sanity: if both dates provided, start must be <= end.
ALTER TABLE users
  DROP CONSTRAINT IF EXISTS vacation_dates_valid;
ALTER TABLE users
  ADD CONSTRAINT vacation_dates_valid
    CHECK (
      vacation_start_date IS NULL
      OR vacation_end_date IS NULL
      OR vacation_start_date <= vacation_end_date
    );

-- Partial index for cron queries that filter to active vacations.
CREATE INDEX IF NOT EXISTS idx_users_in_vacation
  ON users(id)
  WHERE in_vacation_mode = TRUE;

COMMENT ON COLUMN users.in_vacation_mode IS
  'User-controlled vacation flag. TRUE suppresses all non-critical push/email notifications.';
COMMENT ON COLUMN users.vacation_start_date IS
  'Optional start of vacation window. NULL means active immediately upon flag set.';
COMMENT ON COLUMN users.vacation_end_date IS
  'Optional end of vacation window (inclusive). NULL means open-ended — user must manually disable.';
