-- 2211_google_calendar_sync.sql
-- OAuth tokens + calendar prefs for per-user Google Calendar sync.
-- Callsite: services/google_calendar_service.py
-- Idempotent.

CREATE TABLE IF NOT EXISTS google_calendar_connections (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  access_token        text NOT NULL,
  refresh_token       text,
  token_expires_at    timestamptz,
  expires_in_seconds  integer,
  calendar_id         text NOT NULL DEFAULT 'primary',
  connected_at        timestamptz NOT NULL DEFAULT now(),
  last_sync_at        timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_google_calendar_connections_user
  ON google_calendar_connections(user_id);

ALTER TABLE google_calendar_connections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS google_calendar_connections_owner ON google_calendar_connections;
CREATE POLICY google_calendar_connections_owner ON google_calendar_connections
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

COMMENT ON COLUMN google_calendar_connections.access_token IS
  'Short-lived OAuth access token (refreshed via refresh_token).';
COMMENT ON COLUMN google_calendar_connections.refresh_token IS
  'Long-lived OAuth refresh token. Stored plaintext at the row level; '
  'protect at the connection layer (Supabase service-role only) and at '
  'rest via the underlying Postgres disk encryption.';
