-- 2210_live_chat_support.sql
-- Tables for the human live-chat support flow + media-usage rate limiting.
-- Callsites:
--   api/v1/live_chat.py, api/v1/live_chat_endpoints.py
--   api/v1/admin/live_chat.py, api/v1/admin/live_chat_endpoints.py
--   services/langgraph_service.py (chat_media_usage only)
--
-- Idempotent.

-- ----------------------------------------------------------------------------
-- live_chat_messages — user↔admin messages threaded under support_tickets.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS live_chat_messages (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id          uuid NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender_role        text NOT NULL CHECK (sender_role IN ('user','agent','system')),
  sender_id          text NOT NULL,
  message            text NOT NULL,
  is_system_message  boolean NOT NULL DEFAULT false,
  read_at            timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_live_chat_messages_ticket
  ON live_chat_messages(ticket_id, created_at);
CREATE INDEX IF NOT EXISTS idx_live_chat_messages_unread
  ON live_chat_messages(ticket_id, sender_role) WHERE read_at IS NULL;

ALTER TABLE live_chat_messages ENABLE ROW LEVEL SECURITY;
-- Visibility tied to ticket ownership; admin role goes through service-role key.
DROP POLICY IF EXISTS live_chat_messages_owner_visibility ON live_chat_messages;
CREATE POLICY live_chat_messages_owner_visibility
  ON live_chat_messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM support_tickets t
    WHERE t.id = live_chat_messages.ticket_id
      AND t.user_id = auth.uid()
  ));
DROP POLICY IF EXISTS live_chat_messages_owner_insert ON live_chat_messages;
CREATE POLICY live_chat_messages_owner_insert
  ON live_chat_messages FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM support_tickets t
    WHERE t.id = live_chat_messages.ticket_id
      AND t.user_id = auth.uid()
  ));

-- ----------------------------------------------------------------------------
-- admin_presence — one row per admin tracking online state for queue display.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_presence (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  is_online       boolean NOT NULL DEFAULT false,
  last_seen       timestamptz NOT NULL DEFAULT now(),
  status_message  text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_admin_presence_online
  ON admin_presence(is_online) WHERE is_online = true;

-- admin_presence is operationally an admin-only table; service role writes,
-- authenticated users may read the count (for queue display).
ALTER TABLE admin_presence ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS admin_presence_read ON admin_presence;
CREATE POLICY admin_presence_read ON admin_presence FOR SELECT USING (true);

-- ----------------------------------------------------------------------------
-- chat_media_usage — daily rolling counter for media uploads per user.
-- services/langgraph_service.py._check_media_usage selects/inserts/updates.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_media_usage (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  usage_date   date NOT NULL,
  media_count  integer NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chat_media_usage_user_date_uq UNIQUE (user_id, usage_date)
);
CREATE INDEX IF NOT EXISTS idx_chat_media_usage_user_date
  ON chat_media_usage(user_id, usage_date DESC);

ALTER TABLE chat_media_usage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS chat_media_usage_owner ON chat_media_usage;
CREATE POLICY chat_media_usage_owner ON chat_media_usage
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
