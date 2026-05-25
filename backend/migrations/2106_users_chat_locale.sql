-- Migration 2106: Add chat_locale column to users table
-- Stores the user's preferred AI Coach chat language (ISO 639-1 code),
-- separate from preferred_locale (app UI language).
-- Null = inherit from preferred_locale (backwards-compatible).
-- Populated on chat request from X-Chat-Locale header.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS chat_locale TEXT;

-- Partial index: only index non-null values since null (= use preferred_locale)
-- is the default and needs no lookup. Useful for cron jobs that want to send
-- AI messages in the correct language per user.
CREATE INDEX IF NOT EXISTS idx_users_chat_locale_non_null
    ON users (chat_locale)
    WHERE chat_locale IS NOT NULL;
