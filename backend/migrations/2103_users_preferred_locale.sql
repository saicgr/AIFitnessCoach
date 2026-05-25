-- Migration 2103: Add preferred_locale column to users table
-- Stores the user's preferred UI/AI response language (ISO 639-1 code).
-- Populated on first chat request from Accept-Language header and updated
-- on every subsequent request if it changes.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS preferred_locale TEXT NOT NULL DEFAULT 'en';

-- Partial index: only index rows that are NOT the default ('en') so the
-- index stays small even as the users table grows. Useful for cron jobs
-- that want to send localized notifications to non-English speakers.
CREATE INDEX IF NOT EXISTS idx_users_preferred_locale_non_en
    ON users (preferred_locale)
    WHERE preferred_locale <> 'en';
