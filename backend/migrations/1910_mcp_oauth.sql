-- Migration: MCP OAuth 2.1 Server Tables
-- Created: 2026-04-12
-- Purpose: Support publishing FitWiz as an MCP server with OAuth 2.1 + PKCE + DCR.
--          Tables back the authorization code flow, token storage, audit trail,
--          and confirmation tokens for risky tool actions.
--
-- Related code: backend/mcp/auth/*, backend/mcp/server.py
-- MCP access is gated to yearly subscribers (enforced in backend/mcp/subscription.py,
-- not at the DB layer).

-- ============================================================
-- mcp_oauth_clients - Dynamically-registered OAuth clients
-- ============================================================
-- One row per MCP client registration (Claude Desktop, ChatGPT, Cursor, etc.).
-- Clients self-declare via RFC 7591 Dynamic Client Registration.
-- Secret is bcrypt-hashed at rest.
CREATE TABLE IF NOT EXISTS mcp_oauth_clients (
    client_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_secret_hash TEXT NOT NULL,
    client_name TEXT NOT NULL,
    redirect_uris TEXT[] NOT NULL,
    scopes TEXT[] NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by_ip INET,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    revoked_at TIMESTAMPTZ,
    revoked_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_mcp_oauth_clients_active
    ON mcp_oauth_clients (created_at DESC)
    WHERE is_revoked = FALSE;

-- ============================================================
-- mcp_auth_codes - Short-lived authorization codes (PKCE)
-- ============================================================
-- Issued at /oauth/authorize, exchanged at /oauth/token. 60-second TTL.
-- code_challenge is PKCE S256; verifier is checked on exchange.
-- consumed_at prevents code replay (one-time use).
CREATE TABLE IF NOT EXISTS mcp_auth_codes (
    code TEXT PRIMARY KEY,
    client_id UUID NOT NULL REFERENCES mcp_oauth_clients(client_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scopes TEXT[] NOT NULL,
    code_challenge TEXT NOT NULL,
    code_challenge_method TEXT NOT NULL DEFAULT 'S256',
    redirect_uri TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mcp_auth_codes_cleanup
    ON mcp_auth_codes (expires_at);

-- ============================================================
-- mcp_tokens - Access + refresh tokens
-- ============================================================
-- Tokens are hashed at rest (SHA-256 with pepper, since they are high-entropy).
-- Short-lived access tokens (1h default); rotating refresh tokens (30d default).
-- Per-client revocation: revoking a row here kills that specific integration.
CREATE TABLE IF NOT EXISTS mcp_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    access_token_hash TEXT UNIQUE NOT NULL,
    refresh_token_hash TEXT UNIQUE,
    client_id UUID NOT NULL REFERENCES mcp_oauth_clients(client_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scopes TEXT[] NOT NULL,
    access_expires_at TIMESTAMPTZ NOT NULL,
    refresh_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    revoked_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_mcp_tokens_user_active
    ON mcp_tokens (user_id)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mcp_tokens_client_active
    ON mcp_tokens (client_id)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mcp_tokens_cleanup
    ON mcp_tokens (access_expires_at)
    WHERE revoked_at IS NULL;

-- ============================================================
-- mcp_audit_log - Per-tool-call audit trail
-- ============================================================
-- Every MCP tool invocation writes a row. Used for:
--   1. User-visible audit in the app ("Claude read your workout history at 3pm")
--   2. Anomaly detection (statistical outlier detection, daily cron)
--   3. Incident forensics
-- request_summary is a redacted view of args (no PII pasted raw).
CREATE TABLE IF NOT EXISTS mcp_audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES mcp_oauth_clients(client_id) ON DELETE SET NULL,
    token_id UUID REFERENCES mcp_tokens(token_id) ON DELETE SET NULL,
    tool_name TEXT NOT NULL,
    scopes_used TEXT[],
    request_summary JSONB,
    success BOOLEAN NOT NULL,
    error_code TEXT,
    latency_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mcp_audit_user_time
    ON mcp_audit_log (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mcp_audit_client_time
    ON mcp_audit_log (client_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mcp_audit_tool_time
    ON mcp_audit_log (tool_name, created_at DESC);

-- ============================================================
-- mcp_confirmation_tokens - Two-step confirmation for risky actions
-- ============================================================
-- Risky tool calls (modify_workout remove, high-calorie meals, plan replacement)
-- return a short-lived confirmation_token. Client must re-call with token to execute.
-- Mitigates prompt-injection-driven destructive calls.
CREATE TABLE IF NOT EXISTS mcp_confirmation_tokens (
    token TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES mcp_oauth_clients(client_id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL,
    payload JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mcp_confirmation_cleanup
    ON mcp_confirmation_tokens (expires_at);

-- ============================================================
-- Row-Level Security
-- ============================================================
-- All MCP tables are service-role-only at the DB layer. User-facing reads
-- (settings screen showing connected integrations, audit log view) go through
-- authenticated API endpoints that apply explicit ownership checks.
-- This matches the existing IDOR-protection pattern in backend/core/auth.py.

ALTER TABLE mcp_oauth_clients     ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcp_auth_codes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcp_tokens            ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcp_audit_log         ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcp_confirmation_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mcp_oauth_clients_service ON mcp_oauth_clients;
CREATE POLICY mcp_oauth_clients_service ON mcp_oauth_clients
    FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS mcp_auth_codes_service ON mcp_auth_codes;
CREATE POLICY mcp_auth_codes_service ON mcp_auth_codes
    FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS mcp_tokens_service ON mcp_tokens;
CREATE POLICY mcp_tokens_service ON mcp_tokens
    FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS mcp_audit_log_service ON mcp_audit_log;
CREATE POLICY mcp_audit_log_service ON mcp_audit_log
    FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS mcp_confirmation_tokens_service ON mcp_confirmation_tokens;
CREATE POLICY mcp_confirmation_tokens_service ON mcp_confirmation_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- Grants
-- ============================================================
-- Service role (backend) gets full access. Anon/authenticated roles cannot
-- touch these tables directly; they must go through authenticated API routes.
GRANT ALL ON mcp_oauth_clients, mcp_auth_codes, mcp_tokens,
             mcp_audit_log, mcp_confirmation_tokens
    TO service_role;

GRANT USAGE ON SEQUENCE mcp_audit_log_id_seq TO service_role;
