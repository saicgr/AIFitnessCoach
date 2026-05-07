-- X (Twitter) publisher state for the build-in-public daily post automation.
--
-- Two tables:
--   x_oauth_state    — singleton row holding the rotating OAuth 2.0 refresh
--                      token. X invalidates the prior refresh token on every
--                      use, so we MUST persist the rotated value or we lose
--                      access on the next refresh.
--   x_pending_drafts — one row per draft sent to Telegram. The webhook looks
--                      up the draft by telegram_message_id when the user taps
--                      the inline keyboard buttons (🚀 Post / ❌ Skip).
--
-- Both tables are service-role-only — RLS enabled with no policies, so user
-- JWTs cannot read or write either table.

CREATE TABLE IF NOT EXISTS x_oauth_state (
  id smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  refresh_token text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS x_pending_drafts (
  id bigserial PRIMARY KEY,
  telegram_message_id bigint NOT NULL,
  telegram_chat_id bigint NOT NULL,
  tweets jsonb NOT NULL,
  angle text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'posted', 'skipped', 'failed')),
  posted_url text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (telegram_message_id, telegram_chat_id)
);

CREATE INDEX IF NOT EXISTS idx_x_pending_drafts_status
  ON x_pending_drafts(status, created_at DESC);

ALTER TABLE x_oauth_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE x_pending_drafts ENABLE ROW LEVEL SECURITY;
