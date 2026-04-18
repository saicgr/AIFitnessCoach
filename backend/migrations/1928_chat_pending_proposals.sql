-- Chat pending proposals
-- Stores workout modifications the AI coach has *proposed* in chat but not
-- yet applied. The assistant message returns a proposal_id + proposal_token
-- via action_data; the Flutter client shows Apply / Not now buttons; on
-- Apply the backend consumes the token and runs the stored tool_args.
--
-- This is the "propose then confirm" layer for advisory requests like
-- "any change you recommend?". Explicit commands ("swap squats for lunges")
-- keep hitting the direct mutation tools and do NOT create a row here.

CREATE TABLE IF NOT EXISTS chat_pending_proposals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id      UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    action          TEXT NOT NULL CHECK (action IN (
        'add_exercise',
        'remove_exercise',
        'replace_exercise',
        'replace_all_exercises',
        'modify_intensity',
        'reschedule'
    )),
    tool_args       JSONB NOT NULL,
    summary         TEXT NOT NULL,
    reason          TEXT,
    proposal_token  TEXT NOT NULL,   -- short random secret, required on apply
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'applied', 'dismissed', 'expired'
    )),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    applied_at      TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Lookup by id is already the PK. This index speeds up cleanup of expired
-- rows and the (rare) "list my pending proposals" query.
CREATE INDEX IF NOT EXISTS idx_chat_pending_proposals_cleanup
    ON chat_pending_proposals (expires_at);

CREATE INDEX IF NOT EXISTS idx_chat_pending_proposals_user_status
    ON chat_pending_proposals (user_id, status, expires_at);

COMMENT ON TABLE chat_pending_proposals IS
    'Workout changes the AI coach has proposed in chat but not yet applied. '
    'Apply goes through /api/v1/chat/proposals/{id}/apply with the token.';
COMMENT ON COLUMN chat_pending_proposals.tool_args IS
    'Exact JSON args to pass to the matching workout tool on apply. '
    'Server-only; never echoed through action_data.';
COMMENT ON COLUMN chat_pending_proposals.proposal_token IS
    'Random secret required to apply/dismiss. Prevents replay if the action_data '
    'payload leaks to another client.';

-- ============================================================
-- Row-Level Security
-- ============================================================
-- Service-role-only at the DB layer, same as mcp_confirmation_tokens
-- (see 1910_mcp_oauth.sql). The /chat/proposals/{id}/apply endpoint
-- applies explicit ownership checks via verify_user_ownership() from
-- backend/core/auth.py before dispatching to the stored tool_args.

ALTER TABLE chat_pending_proposals ENABLE ROW LEVEL SECURITY;
-- No policies — service role bypasses RLS; authenticated users cannot
-- read or write this table directly.
