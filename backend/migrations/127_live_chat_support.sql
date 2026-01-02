-- Migration 127: Live Chat Support
-- Extends the support ticket system with real-time live chat capabilities
-- Enables agents to have live conversations with users, with typing indicators,
-- presence tracking, and queue management

-- ===================================
-- ALTER: support_tickets - Add live chat columns
-- ===================================
ALTER TABLE support_tickets
    ADD COLUMN IF NOT EXISTS chat_mode TEXT DEFAULT 'ticket' CHECK (chat_mode IN ('ticket', 'live_chat')),
    ADD COLUMN IF NOT EXISTS agent_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS agent_name TEXT,
    ADD COLUMN IF NOT EXISTS agent_typing BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS user_typing BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS user_last_seen_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS agent_last_seen_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS escalated_from_ai BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS ai_handoff_context TEXT;

-- ===================================
-- ALTER: support_ticket_messages - Add delivery/read tracking
-- ===================================
ALTER TABLE support_ticket_messages
    ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ DEFAULT NOW();

-- ===================================
-- ALTER: users - Add role column
-- ===================================
DO $$
BEGIN
    -- Check if users table exists and add role column
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role' AND table_schema = 'public') THEN
            ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin'));
        END IF;
    END IF;
END $$;

-- ===================================
-- Table: live_chat_presence
-- Tracks online/offline status of users and agents
-- ===================================
CREATE TABLE IF NOT EXISTS live_chat_presence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_online BOOLEAN DEFAULT FALSE,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    device_info JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT live_chat_presence_user_id_unique UNIQUE (user_id)
);

-- ===================================
-- Table: live_chat_queue
-- Manages queue for users waiting for live chat agents
-- ===================================
CREATE TABLE IF NOT EXISTS live_chat_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    priority INTEGER DEFAULT 50 CHECK (priority >= 0 AND priority <= 100),
    queued_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_at TIMESTAMPTZ,
    estimated_wait_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT live_chat_queue_ticket_id_unique UNIQUE (ticket_id)
);

-- ===================================
-- Indexes for Performance
-- ===================================

-- support_tickets live chat indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_chat_mode ON support_tickets(chat_mode);
CREATE INDEX IF NOT EXISTS idx_support_tickets_agent_id ON support_tickets(agent_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_escalated_from_ai ON support_tickets(escalated_from_ai);
CREATE INDEX IF NOT EXISTS idx_support_tickets_chat_mode_status ON support_tickets(chat_mode, status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_agent_chat ON support_tickets(agent_id, chat_mode) WHERE chat_mode = 'live_chat';

-- support_ticket_messages delivery indexes
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_read_at ON support_ticket_messages(read_at) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_delivered_at ON support_ticket_messages(delivered_at);
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket_unread ON support_ticket_messages(ticket_id, read_at) WHERE read_at IS NULL;

-- live_chat_presence indexes
CREATE INDEX IF NOT EXISTS idx_live_chat_presence_user_id ON live_chat_presence(user_id);
CREATE INDEX IF NOT EXISTS idx_live_chat_presence_is_online ON live_chat_presence(is_online);
CREATE INDEX IF NOT EXISTS idx_live_chat_presence_last_active ON live_chat_presence(last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_live_chat_presence_online_users ON live_chat_presence(user_id) WHERE is_online = TRUE;

-- live_chat_queue indexes
CREATE INDEX IF NOT EXISTS idx_live_chat_queue_ticket_id ON live_chat_queue(ticket_id);
CREATE INDEX IF NOT EXISTS idx_live_chat_queue_user_id ON live_chat_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_live_chat_queue_priority ON live_chat_queue(priority DESC);
CREATE INDEX IF NOT EXISTS idx_live_chat_queue_queued_at ON live_chat_queue(queued_at);
CREATE INDEX IF NOT EXISTS idx_live_chat_queue_unassigned ON live_chat_queue(priority DESC, queued_at) WHERE assigned_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_live_chat_queue_priority_queued ON live_chat_queue(priority DESC, queued_at ASC) WHERE assigned_at IS NULL;

-- ===================================
-- Function: Update live_chat_presence updated_at
-- ===================================
CREATE OR REPLACE FUNCTION update_live_chat_presence_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for live_chat_presence
DROP TRIGGER IF EXISTS trigger_live_chat_presence_updated_at ON live_chat_presence;
CREATE TRIGGER trigger_live_chat_presence_updated_at
    BEFORE UPDATE ON live_chat_presence
    FOR EACH ROW
    EXECUTE FUNCTION update_live_chat_presence_updated_at();

-- ===================================
-- Function: Update live_chat_queue updated_at
-- ===================================
CREATE OR REPLACE FUNCTION update_live_chat_queue_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for live_chat_queue
DROP TRIGGER IF EXISTS trigger_live_chat_queue_updated_at ON live_chat_queue;
CREATE TRIGGER trigger_live_chat_queue_updated_at
    BEFORE UPDATE ON live_chat_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_live_chat_queue_updated_at();

-- ===================================
-- Function: Calculate estimated wait time
-- ===================================
CREATE OR REPLACE FUNCTION calculate_estimated_wait_minutes()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    queue_position INTEGER;
    avg_chat_duration INTEGER;
BEGIN
    -- Calculate position in queue
    SELECT COUNT(*) + 1 INTO queue_position
    FROM live_chat_queue
    WHERE assigned_at IS NULL
    AND (priority > NEW.priority OR (priority = NEW.priority AND queued_at < NEW.queued_at));

    -- Estimate 10 minutes per chat (can be refined based on historical data)
    avg_chat_duration := 10;

    NEW.estimated_wait_minutes := queue_position * avg_chat_duration;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to calculate estimated wait on insert
DROP TRIGGER IF EXISTS trigger_calculate_wait_time ON live_chat_queue;
CREATE TRIGGER trigger_calculate_wait_time
    BEFORE INSERT ON live_chat_queue
    FOR EACH ROW
    EXECUTE FUNCTION calculate_estimated_wait_minutes();

-- ===================================
-- Function: Update typing indicators (with auto-clear after 5 seconds)
-- ===================================
CREATE OR REPLACE FUNCTION set_typing_indicator(
    p_ticket_id UUID,
    p_is_user BOOLEAN,
    p_is_typing BOOLEAN
)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_is_user THEN
        UPDATE support_tickets
        SET user_typing = p_is_typing,
            user_last_seen_at = NOW()
        WHERE id = p_ticket_id;
    ELSE
        UPDATE support_tickets
        SET agent_typing = p_is_typing,
            agent_last_seen_at = NOW()
        WHERE id = p_ticket_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- Function: Mark messages as read
-- ===================================
CREATE OR REPLACE FUNCTION mark_messages_read(
    p_ticket_id UUID,
    p_reader_is_user BOOLEAN
)
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    IF p_reader_is_user THEN
        -- User reading support messages
        UPDATE support_ticket_messages
        SET read_at = NOW()
        WHERE ticket_id = p_ticket_id
        AND sender = 'support'
        AND read_at IS NULL;
    ELSE
        -- Agent reading user messages
        UPDATE support_ticket_messages
        SET read_at = NOW()
        WHERE ticket_id = p_ticket_id
        AND sender = 'user'
        AND read_at IS NULL;
    END IF;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- Function: Assign next user from queue to agent
-- ===================================
CREATE OR REPLACE FUNCTION assign_next_from_queue(p_agent_id UUID)
RETURNS UUID
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_queue_entry_id UUID;
    v_ticket_id UUID;
BEGIN
    -- Get highest priority unassigned queue entry
    SELECT id, ticket_id INTO v_queue_entry_id, v_ticket_id
    FROM live_chat_queue
    WHERE assigned_at IS NULL
    ORDER BY priority DESC, queued_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_queue_entry_id IS NOT NULL THEN
        -- Mark queue entry as assigned
        UPDATE live_chat_queue
        SET assigned_at = NOW()
        WHERE id = v_queue_entry_id;

        -- Assign agent to ticket
        UPDATE support_tickets
        SET agent_id = p_agent_id,
            status = 'in_progress'
        WHERE id = v_ticket_id;

        RETURN v_ticket_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- View: live_chat_queue_status
-- ===================================
CREATE OR REPLACE VIEW live_chat_queue_status
WITH (security_invoker = true)
AS
SELECT
    q.id,
    q.ticket_id,
    q.user_id,
    q.priority,
    q.queued_at,
    q.assigned_at,
    q.estimated_wait_minutes,
    t.subject,
    t.category,
    t.agent_id,
    t.agent_name,
    (SELECT COUNT(*) FROM live_chat_queue WHERE assigned_at IS NULL AND (priority > q.priority OR (priority = q.priority AND queued_at < q.queued_at))) + 1 AS queue_position
FROM live_chat_queue q
JOIN support_tickets t ON q.ticket_id = t.id
WHERE q.assigned_at IS NULL
ORDER BY q.priority DESC, q.queued_at ASC;

-- ===================================
-- View: agent_chat_summary
-- ===================================
CREATE OR REPLACE VIEW agent_chat_summary
WITH (security_invoker = true)
AS
SELECT
    t.agent_id,
    t.agent_name,
    COUNT(*) FILTER (WHERE t.status = 'in_progress' AND t.chat_mode = 'live_chat') AS active_chats,
    COUNT(*) FILTER (WHERE t.status IN ('resolved', 'closed') AND t.chat_mode = 'live_chat') AS completed_chats,
    AVG(
        CASE
            WHEN t.resolved_at IS NOT NULL AND t.chat_mode = 'live_chat'
            THEN EXTRACT(EPOCH FROM (t.resolved_at - t.created_at)) / 60
            ELSE NULL
        END
    ) AS avg_resolution_minutes
FROM support_tickets t
WHERE t.agent_id IS NOT NULL
GROUP BY t.agent_id, t.agent_name;

-- ===================================
-- View: unread_message_counts
-- ===================================
CREATE OR REPLACE VIEW unread_message_counts
WITH (security_invoker = true)
AS
SELECT
    t.id AS ticket_id,
    t.user_id,
    t.agent_id,
    COUNT(*) FILTER (WHERE m.sender = 'support' AND m.read_at IS NULL) AS unread_by_user,
    COUNT(*) FILTER (WHERE m.sender = 'user' AND m.read_at IS NULL) AS unread_by_agent
FROM support_tickets t
LEFT JOIN support_ticket_messages m ON t.id = m.ticket_id
GROUP BY t.id, t.user_id, t.agent_id;

-- ===================================
-- Row Level Security (RLS)
-- ===================================

-- Enable RLS on new tables
ALTER TABLE live_chat_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_chat_queue ENABLE ROW LEVEL SECURITY;

-- ===================================
-- RLS Policies: live_chat_presence
-- ===================================

-- Users can view their own presence
DROP POLICY IF EXISTS "Users can view own presence" ON live_chat_presence;
CREATE POLICY "Users can view own presence"
    ON live_chat_presence FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own presence
DROP POLICY IF EXISTS "Users can update own presence" ON live_chat_presence;
CREATE POLICY "Users can update own presence"
    ON live_chat_presence FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can insert their own presence
DROP POLICY IF EXISTS "Users can insert own presence" ON live_chat_presence;
CREATE POLICY "Users can insert own presence"
    ON live_chat_presence FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own presence
DROP POLICY IF EXISTS "Users can delete own presence" ON live_chat_presence;
CREATE POLICY "Users can delete own presence"
    ON live_chat_presence FOR DELETE
    USING (auth.uid() = user_id);

-- Admins can view all presence (for agent dashboard)
DROP POLICY IF EXISTS "Admins can view all presence" ON live_chat_presence;
CREATE POLICY "Admins can view all presence"
    ON live_chat_presence FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Service role can manage all presence
DROP POLICY IF EXISTS "Service role can manage all presence" ON live_chat_presence;
CREATE POLICY "Service role can manage all presence"
    ON live_chat_presence FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ===================================
-- RLS Policies: live_chat_queue
-- ===================================

-- Users can view their own queue entry
DROP POLICY IF EXISTS "Users can view own queue entry" ON live_chat_queue;
CREATE POLICY "Users can view own queue entry"
    ON live_chat_queue FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own queue entry
DROP POLICY IF EXISTS "Users can insert own queue entry" ON live_chat_queue;
CREATE POLICY "Users can insert own queue entry"
    ON live_chat_queue FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own queue entry (leave queue)
DROP POLICY IF EXISTS "Users can delete own queue entry" ON live_chat_queue;
CREATE POLICY "Users can delete own queue entry"
    ON live_chat_queue FOR DELETE
    USING (auth.uid() = user_id);

-- Admins can view all queue entries
DROP POLICY IF EXISTS "Admins can view all queue" ON live_chat_queue;
CREATE POLICY "Admins can view all queue"
    ON live_chat_queue FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Admins can update queue entries (for assignment)
DROP POLICY IF EXISTS "Admins can update queue" ON live_chat_queue;
CREATE POLICY "Admins can update queue"
    ON live_chat_queue FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Service role can manage all queue entries
DROP POLICY IF EXISTS "Service role can manage all queue" ON live_chat_queue;
CREATE POLICY "Service role can manage all queue"
    ON live_chat_queue FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ===================================
-- Additional RLS Policies for support_tickets (live chat specific)
-- ===================================

-- Admins can view all tickets
DROP POLICY IF EXISTS "Admins can view all tickets" ON support_tickets;
CREATE POLICY "Admins can view all tickets"
    ON support_tickets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Admins can update all tickets
DROP POLICY IF EXISTS "Admins can update all tickets" ON support_tickets;
CREATE POLICY "Admins can update all tickets"
    ON support_tickets FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- ===================================
-- Additional RLS Policies for support_ticket_messages (live chat specific)
-- ===================================

-- Admins can view all messages
DROP POLICY IF EXISTS "Admins can view all messages" ON support_ticket_messages;
CREATE POLICY "Admins can view all messages"
    ON support_ticket_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Admins can insert messages (support replies)
DROP POLICY IF EXISTS "Admins can insert messages" ON support_ticket_messages;
CREATE POLICY "Admins can insert messages"
    ON support_ticket_messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Admins can update messages (mark as read)
DROP POLICY IF EXISTS "Admins can update messages" ON support_ticket_messages;
CREATE POLICY "Admins can update messages"
    ON support_ticket_messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'super_admin')
        )
    );

-- Users can update messages on their tickets (mark as read)
DROP POLICY IF EXISTS "Users can update own ticket messages" ON support_ticket_messages;
CREATE POLICY "Users can update own ticket messages"
    ON support_ticket_messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets
            WHERE id = support_ticket_messages.ticket_id
            AND user_id = auth.uid()
        )
    );

-- ===================================
-- Enable Supabase Realtime
-- ===================================

-- Add tables to realtime publication for live updates
-- Note: This enables real-time subscriptions for typing indicators and new messages
ALTER PUBLICATION supabase_realtime ADD TABLE support_tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE support_ticket_messages;

-- ===================================
-- Grant Permissions
-- ===================================

-- Grant access to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON live_chat_presence TO authenticated;
GRANT SELECT, INSERT, DELETE ON live_chat_queue TO authenticated;
GRANT UPDATE ON support_ticket_messages TO authenticated;

-- Grant access to service role
GRANT ALL ON live_chat_presence TO service_role;
GRANT ALL ON live_chat_queue TO service_role;

-- Grant view access
GRANT SELECT ON live_chat_queue_status TO authenticated, service_role;
GRANT SELECT ON agent_chat_summary TO service_role;
GRANT SELECT ON unread_message_counts TO authenticated, service_role;

-- Grant function execution
GRANT EXECUTE ON FUNCTION set_typing_indicator(UUID, BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_messages_read(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION assign_next_from_queue(UUID) TO service_role;

-- ===================================
-- Comments for Documentation
-- ===================================
COMMENT ON COLUMN support_tickets.chat_mode IS 'Mode of support: ticket (async) or live_chat (real-time)';
COMMENT ON COLUMN support_tickets.agent_id IS 'UUID of the assigned support agent';
COMMENT ON COLUMN support_tickets.agent_name IS 'Display name of the assigned support agent';
COMMENT ON COLUMN support_tickets.agent_typing IS 'Real-time indicator when agent is typing';
COMMENT ON COLUMN support_tickets.user_typing IS 'Real-time indicator when user is typing';
COMMENT ON COLUMN support_tickets.user_last_seen_at IS 'Last activity timestamp from user';
COMMENT ON COLUMN support_tickets.agent_last_seen_at IS 'Last activity timestamp from agent';
COMMENT ON COLUMN support_tickets.escalated_from_ai IS 'True if chat was escalated from AI assistant';
COMMENT ON COLUMN support_tickets.ai_handoff_context IS 'Context summary from AI before handoff to human agent';
COMMENT ON COLUMN support_ticket_messages.read_at IS 'Timestamp when message was read by recipient';
COMMENT ON COLUMN support_ticket_messages.delivered_at IS 'Timestamp when message was delivered';
COMMENT ON TABLE live_chat_presence IS 'Tracks online/offline status of users and agents for live chat';
COMMENT ON COLUMN live_chat_presence.device_info IS 'JSON object with device information (browser, OS, etc.)';
COMMENT ON TABLE live_chat_queue IS 'Queue management for users waiting for live chat agents';
COMMENT ON COLUMN live_chat_queue.priority IS 'Queue priority (0-100, higher = more urgent)';
COMMENT ON COLUMN live_chat_queue.estimated_wait_minutes IS 'Estimated wait time based on queue position';
COMMENT ON VIEW live_chat_queue_status IS 'Real-time queue status with position calculations';
COMMENT ON VIEW agent_chat_summary IS 'Performance metrics for support agents';
COMMENT ON VIEW unread_message_counts IS 'Unread message counts per ticket for both user and agent';
COMMENT ON FUNCTION set_typing_indicator IS 'Updates typing indicator for live chat';
COMMENT ON FUNCTION mark_messages_read IS 'Marks messages as read and returns count of updated messages';
COMMENT ON FUNCTION assign_next_from_queue IS 'Assigns the next user from queue to an agent';
