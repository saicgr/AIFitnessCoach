-- Migration 1963: Out-of-app DSAR (Data Subject Access Request) flow.
--
-- Backs the public `/api/v1/dsar/*` endpoints so a user who's locked out
-- of their account can still exercise GDPR Art. 20 (portability) and
-- CCPA/CPRA "right to know / right to delete" rights without logging in.
--
-- Flow:
--   1. User submits email + request_type via public form
--      -> row inserted with status='pending_verification' and a hashed
--         one-time token (plaintext emailed to user)
--   2. User clicks verification link from email
--      -> row transitions to 'verified'; backend queues export/delete
--   3. Worker generates the export archive, uploads to S3, emails a
--      signed download URL; row transitions to 'fulfilled'
--   4. Download link auto-expires after 7 days (signed URL TTL)
--
-- The token is stored as SHA-256 hash + expires_at so even a DB leak
-- cannot replay the verification link. Anti-abuse rate limit is a
-- partial unique index: one pending request per email per 24h.

CREATE TABLE IF NOT EXISTS public.dsar_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    request_type TEXT NOT NULL CHECK (request_type IN ('export', 'delete', 'access')),
    status TEXT NOT NULL DEFAULT 'pending_verification'
        CHECK (status IN (
            'pending_verification',
            'verified',
            'processing',
            'fulfilled',
            'failed',
            'expired'
        )),
    -- SHA-256 of the verification token. Plaintext is emailed once and
    -- never stored server-side.
    verification_token_hash TEXT NOT NULL,
    verification_expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    fulfilled_at TIMESTAMPTZ,
    -- Signed S3 URL for the generated export. NULL for delete/access
    -- requests. Regenerated if the original expires and user re-requests.
    download_url TEXT,
    download_expires_at TIMESTAMPTZ,
    -- Metadata for compliance audit (IP, user-agent, locale).
    request_ip TEXT,
    request_user_agent TEXT,
    -- Optional matched user_id, set once the email is verified against
    -- auth.users. NULL if no matching account (we still honor the
    -- request with a "no data found" notification for transparency).
    matched_user_id UUID,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fast lookup by verification token during /dsar/verify.
CREATE INDEX IF NOT EXISTS dsar_requests_token_hash_idx
    ON public.dsar_requests (verification_token_hash);

-- Abuse prevention: cap open requests per email. Partial unique so
-- fulfilled/expired rows do not block a future legitimate request.
CREATE UNIQUE INDEX IF NOT EXISTS dsar_requests_one_pending_per_email_idx
    ON public.dsar_requests (lower(email))
    WHERE status IN ('pending_verification', 'verified', 'processing');

-- Audit index for compliance reporting.
CREATE INDEX IF NOT EXISTS dsar_requests_created_at_idx
    ON public.dsar_requests (created_at DESC);

-- RLS: only service_role (backend) can touch this table. Users interact
-- only via public unauthenticated endpoints which use the service key.
ALTER TABLE public.dsar_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS dsar_requests_service_only ON public.dsar_requests;
CREATE POLICY dsar_requests_service_only ON public.dsar_requests
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

COMMENT ON TABLE public.dsar_requests IS
    'Out-of-app GDPR/CCPA DSAR requests (export, delete, access). Populated by POST /api/v1/dsar/request and advanced by /dsar/verify. Tokens are hashed; plaintext is emailed once.';
