-- Migration: 1967_create_oauth_sync_tables.sql
-- Description: Backing tables for two-way sync with Strava, Garmin, Fitbit,
-- Apple Health (via device), and Peloton. Tokens are AES-GCM encrypted at rest
-- with a Fernet key from OAUTH_TOKEN_ENCRYPTION_KEY env. Webhook events land in
-- oauth_sync_webhook_events as raw payloads; a background worker drains the
-- queue and writes to cardio_logs / workout_history_imports.

CREATE TABLE IF NOT EXISTS oauth_sync_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL
      CHECK (provider IN ('strava', 'garmin', 'fitbit', 'apple_health', 'peloton', 'nike')),
    provider_user_id TEXT NOT NULL,

    -- Tokens — NEVER stored in cleartext. AES-GCM via cryptography.Fernet with
    -- OAUTH_TOKEN_ENCRYPTION_KEY from env. Both fields hold Fernet tokens (urlsafe b64).
    access_token_encrypted TEXT NOT NULL,
    refresh_token_encrypted TEXT,
    expires_at TIMESTAMPTZ,
    scopes TEXT[] DEFAULT ARRAY[]::TEXT[],

    status TEXT NOT NULL DEFAULT 'active'
      CHECK (status IN ('active', 'expired', 'revoked', 'error', 'paused')),
    last_sync_at TIMESTAMPTZ,
    last_sync_status TEXT,                    -- 'ok' | 'partial' | 'failed' | 'rate_limited'
    last_error TEXT,
    error_count INTEGER NOT NULL DEFAULT 0,

    -- User preferences per connected account.
    auto_import BOOLEAN NOT NULL DEFAULT true,
    import_strength BOOLEAN NOT NULL DEFAULT true,
    import_cardio BOOLEAN NOT NULL DEFAULT true,
    webhook_id TEXT,                          -- Strava/Fitbit push subscription id

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (user_id, provider)
);

CREATE INDEX IF NOT EXISTS idx_oauth_sync_accounts_user
  ON oauth_sync_accounts (user_id);

-- For the background sync cron — find active accounts that haven't synced recently.
CREATE INDEX IF NOT EXISTS idx_oauth_sync_accounts_last_sync
  ON oauth_sync_accounts (status, last_sync_at NULLS FIRST)
  WHERE status = 'active' AND auto_import = true;

-- For webhook callbacks — the provider gives us `provider_user_id`, not our user_id.
CREATE INDEX IF NOT EXISTS idx_oauth_sync_accounts_provider_user
  ON oauth_sync_accounts (provider, provider_user_id);

ALTER TABLE oauth_sync_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own sync accounts"
  ON oauth_sync_accounts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users update own sync accounts"
  ON oauth_sync_accounts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own sync accounts"
  ON oauth_sync_accounts FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access sync accounts"
  ON oauth_sync_accounts FOR ALL
  USING (auth.role() = 'service_role');

-- Inserts only via service_role — the OAuth callback endpoint runs with elevated
-- privileges because it encrypts the tokens before writing.
-- (No user-facing INSERT policy.)

CREATE OR REPLACE FUNCTION update_oauth_sync_accounts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_oauth_sync_accounts_updated_at
  ON oauth_sync_accounts;
CREATE TRIGGER trigger_update_oauth_sync_accounts_updated_at
    BEFORE UPDATE ON oauth_sync_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_oauth_sync_accounts_updated_at();


-- Webhook event queue. Processed by a background worker that writes the event
-- into cardio_logs / workout_history_imports. Retained with processed_at + error
-- so replays are idempotent (external_object_id inside payload is the dedup key).

CREATE TABLE IF NOT EXISTS oauth_sync_webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL
      CHECK (provider IN ('strava', 'garmin', 'fitbit', 'peloton', 'nike')),
    event_type TEXT NOT NULL,                 -- 'activity.create' | 'activity.update' | 'activity.delete' | 'deauthorize'
    external_user_id TEXT NOT NULL,
    external_object_id TEXT,                  -- provider-native activity id
    payload JSONB NOT NULL,                   -- full raw payload from the provider
    signature_verified BOOLEAN NOT NULL DEFAULT false,

    processed_at TIMESTAMPTZ,
    process_attempts INTEGER NOT NULL DEFAULT 0,
    error TEXT,

    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Primary worker query: unprocessed events, oldest first.
CREATE INDEX IF NOT EXISTS idx_sync_webhook_unprocessed
  ON oauth_sync_webhook_events (received_at)
  WHERE processed_at IS NULL;

-- Replay-protection dedup: same (provider, external_object_id, event_type) should
-- only be processed once (downstream inserts also use source_external_id unique
-- index as a second safety net).
CREATE UNIQUE INDEX IF NOT EXISTS uq_sync_webhook_event_dedup
  ON oauth_sync_webhook_events (provider, external_object_id, event_type)
  WHERE external_object_id IS NOT NULL;

-- Webhooks table is service-role only — no user access.
ALTER TABLE oauth_sync_webhook_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access webhook events"
  ON oauth_sync_webhook_events FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE oauth_sync_accounts IS
  'OAuth tokens for connected fitness apps. Encrypted at rest. Drives pull + push sync.';
COMMENT ON TABLE oauth_sync_webhook_events IS
  'Raw webhook events from providers, queued for a background worker to process.';
COMMENT ON COLUMN oauth_sync_accounts.access_token_encrypted IS
  'Fernet-encrypted access token. Decrypt via services.sync.oauth_base.decrypt_token().';
