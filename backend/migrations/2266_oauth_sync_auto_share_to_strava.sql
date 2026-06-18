-- 2266_oauth_sync_auto_share_to_strava
-- Adds the per-account "auto-share completed workouts to Strava" preference.
-- Applied to the live DB via the Supabase MCP during the shareables build
-- (this file is the repo record of that change; idempotent so re-running is safe).
ALTER TABLE oauth_sync_accounts
    ADD COLUMN IF NOT EXISTS auto_share_to_strava boolean NOT NULL DEFAULT false;
