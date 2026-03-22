-- Migration 1670: Email send log for deduplication
-- Prevents duplicate emails by tracking what was sent to whom

CREATE TABLE IF NOT EXISTS email_send_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email_type VARCHAR NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_email_send_log_user_type ON email_send_log(user_id, email_type);
CREATE INDEX IF NOT EXISTS idx_email_send_log_sent_at ON email_send_log(sent_at DESC);

-- RLS
ALTER TABLE email_send_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access email_send_log"
    ON email_send_log FOR ALL
    USING (auth.role() = 'service_role');

COMMENT ON TABLE email_send_log IS 'Deduplication log for all outbound marketing/lifecycle emails. Prevents re-sending within cooldown windows.';
