-- Migration: MCP Personal Access Tokens
-- Created: 2026-04-12
-- Applied to prod via Supabase MCP on 2026-04-12.
--
-- User-generated, never-expire access tokens for connecting Zealova to
-- AI clients (Claude Desktop, ChatGPT, Cursor) without going through the
-- full OAuth consent flow. Simpler UX: generate in Settings → AI Integrations,
-- paste the JSON config into the client, done.
--
-- OAuth tables (mcp_oauth_clients, mcp_tokens, etc.) remain for future
-- marketplace integrations (ChatGPT Apps, Claude Connector store).

CREATE TABLE IF NOT EXISTS mcp_personal_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    access_token_hash TEXT UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    scopes TEXT[] NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    revoked_reason TEXT,
    created_by_ip INET
);

CREATE INDEX IF NOT EXISTS idx_mcp_pat_user_active
    ON mcp_personal_tokens (user_id)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mcp_pat_lookup
    ON mcp_personal_tokens (access_token_hash)
    WHERE revoked_at IS NULL;

ALTER TABLE mcp_personal_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mcp_personal_tokens_service ON mcp_personal_tokens;
CREATE POLICY mcp_personal_tokens_service ON mcp_personal_tokens
    FOR ALL USING (auth.role() = 'service_role');

GRANT ALL ON mcp_personal_tokens TO service_role;
