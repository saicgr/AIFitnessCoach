-- Migration 2308: Remaining write-drift columns (round 2 of the 2026-07-04
-- column-drift sweep; see 2306/2307).
--
-- 1. email_preferences.deliverable — the Resend webhook's 3-strikes hard-
--    bounce handler writes it (never existed → bouncing addresses were never
--    suppressed). The cron jobs gate on per-category flags, so the handler
--    also zeroes those (code change); this column is the canonical
--    suppression state + audit flag.
-- 2. user_neat_achievements.is_celebrated — model field distinct from
--    is_notified; the award insert writes it, so NEAT achievements were
--    never awarded at all.
-- 3. favorite_superset_pairs.times_used/last_used_at — usage tracking the
--    supersets endpoints write and ORDER BY; never existed.

BEGIN;

ALTER TABLE email_preferences ADD COLUMN IF NOT EXISTS deliverable BOOLEAN DEFAULT TRUE;

ALTER TABLE user_neat_achievements ADD COLUMN IF NOT EXISTS is_celebrated BOOLEAN DEFAULT FALSE;

ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS times_used INT DEFAULT 0;
ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ;

COMMIT;
