-- Migration 079: Support Tickets System
-- Creates tables for support ticket management with conversation threads
-- Addresses user complaint: "Generic reply that didn't address my concern"

-- ===================================
-- Table: support_tickets
-- ===================================
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN (
        'billing', 'technical', 'feature_request', 'bug_report', 'account', 'other'
    )),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN (
        'low', 'medium', 'high', 'urgent'
    )),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN (
        'open', 'in_progress', 'waiting_response', 'resolved', 'closed'
    )),
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- ===================================
-- Table: support_ticket_messages
-- ===================================
CREATE TABLE IF NOT EXISTS support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender TEXT NOT NULL CHECK (sender IN ('user', 'support')),
    message TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE, -- For support team internal notes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===================================
-- Indexes for Performance
-- ===================================

-- support_tickets indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority ON support_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_updated_at ON support_tickets(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned_to ON support_tickets(assigned_to);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_status ON support_tickets(user_id, status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_updated ON support_tickets(user_id, updated_at DESC);

-- support_ticket_messages indexes
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket_id ON support_ticket_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_created_at ON support_ticket_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_sender ON support_ticket_messages(sender);

-- Composite index for fetching ticket messages
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket_created ON support_ticket_messages(ticket_id, created_at);

-- ===================================
-- Function: Update updated_at on support_tickets
-- ===================================
CREATE OR REPLACE FUNCTION update_support_ticket_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for support_tickets
DROP TRIGGER IF EXISTS trigger_support_ticket_updated_at ON support_tickets;
CREATE TRIGGER trigger_support_ticket_updated_at
    BEFORE UPDATE ON support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_support_ticket_updated_at();

-- ===================================
-- Function: Update ticket updated_at when message is added
-- ===================================
CREATE OR REPLACE FUNCTION update_ticket_on_new_message()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE support_tickets
    SET updated_at = NOW()
    WHERE id = NEW.ticket_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for support_ticket_messages
DROP TRIGGER IF EXISTS trigger_update_ticket_on_message ON support_ticket_messages;
CREATE TRIGGER trigger_update_ticket_on_message
    AFTER INSERT ON support_ticket_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_ticket_on_new_message();

-- ===================================
-- View: support_tickets_summary (with message count and last message preview)
-- ===================================
CREATE OR REPLACE VIEW support_tickets_summary
WITH (security_invoker = true)
AS
SELECT
    t.id,
    t.user_id,
    t.subject,
    t.category,
    t.priority,
    t.status,
    t.assigned_to,
    t.created_at,
    t.updated_at,
    t.resolved_at,
    t.closed_at,
    COALESCE(m.message_count, 0) AS message_count,
    last_msg.message_preview AS last_message_preview,
    last_msg.sender AS last_message_sender
FROM support_tickets t
LEFT JOIN (
    SELECT
        ticket_id,
        COUNT(*) AS message_count
    FROM support_ticket_messages
    WHERE is_internal = FALSE
    GROUP BY ticket_id
) m ON t.id = m.ticket_id
LEFT JOIN LATERAL (
    SELECT
        LEFT(message, 100) AS message_preview,
        sender
    FROM support_ticket_messages
    WHERE ticket_id = t.id AND is_internal = FALSE
    ORDER BY created_at DESC
    LIMIT 1
) last_msg ON TRUE;

-- ===================================
-- View: support_ticket_stats (per-user statistics)
-- ===================================
CREATE OR REPLACE VIEW support_ticket_user_stats
WITH (security_invoker = true)
AS
SELECT
    user_id,
    COUNT(*) AS total_tickets,
    COUNT(*) FILTER (WHERE status IN ('open', 'in_progress', 'waiting_response')) AS open_tickets,
    COUNT(*) FILTER (WHERE status = 'resolved') AS resolved_tickets,
    COUNT(*) FILTER (WHERE status = 'closed') AS closed_tickets,
    AVG(
        CASE
            WHEN resolved_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
            ELSE NULL
        END
    ) AS avg_resolution_time_hours
FROM support_tickets
GROUP BY user_id;

-- ===================================
-- View: support_ticket_overview (admin dashboard)
-- ===================================
CREATE OR REPLACE VIEW support_ticket_overview
WITH (security_invoker = true)
AS
SELECT
    category,
    priority,
    status,
    COUNT(*) AS ticket_count,
    AVG(
        CASE
            WHEN resolved_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
            ELSE NULL
        END
    ) AS avg_resolution_hours,
    MIN(created_at) AS oldest_ticket_date
FROM support_tickets
GROUP BY category, priority, status
ORDER BY
    CASE priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END,
    CASE status
        WHEN 'open' THEN 1
        WHEN 'in_progress' THEN 2
        WHEN 'waiting_response' THEN 3
        WHEN 'resolved' THEN 4
        WHEN 'closed' THEN 5
    END;

-- ===================================
-- Row Level Security (RLS)
-- ===================================

-- Enable RLS on tables
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_messages ENABLE ROW LEVEL SECURITY;

-- ===================================
-- RLS Policies: support_tickets
-- ===================================

-- Users can view their own tickets
DROP POLICY IF EXISTS "Users can view own tickets" ON support_tickets;
CREATE POLICY "Users can view own tickets"
    ON support_tickets FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own tickets
DROP POLICY IF EXISTS "Users can create own tickets" ON support_tickets;
CREATE POLICY "Users can create own tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own tickets (for closing)
DROP POLICY IF EXISTS "Users can update own tickets" ON support_tickets;
CREATE POLICY "Users can update own tickets"
    ON support_tickets FOR UPDATE
    USING (auth.uid() = user_id);

-- Support staff can view all tickets (use a role or service key)
DROP POLICY IF EXISTS "Service role can view all tickets" ON support_tickets;
CREATE POLICY "Service role can view all tickets"
    ON support_tickets FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Support staff can update all tickets
DROP POLICY IF EXISTS "Service role can update all tickets" ON support_tickets;
CREATE POLICY "Service role can update all tickets"
    ON support_tickets FOR UPDATE
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ===================================
-- RLS Policies: support_ticket_messages
-- ===================================

-- Users can view messages on their own tickets (excluding internal notes)
DROP POLICY IF EXISTS "Users can view messages on own tickets" ON support_ticket_messages;
CREATE POLICY "Users can view messages on own tickets"
    ON support_ticket_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets
            WHERE id = support_ticket_messages.ticket_id
            AND user_id = auth.uid()
        )
        AND is_internal = FALSE
    );

-- Users can add messages to their own tickets
DROP POLICY IF EXISTS "Users can add messages to own tickets" ON support_ticket_messages;
CREATE POLICY "Users can add messages to own tickets"
    ON support_ticket_messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM support_tickets
            WHERE id = ticket_id
            AND user_id = auth.uid()
        )
        AND sender = 'user'
        AND is_internal = FALSE
    );

-- Service role can view all messages (including internal)
DROP POLICY IF EXISTS "Service role can view all messages" ON support_ticket_messages;
CREATE POLICY "Service role can view all messages"
    ON support_ticket_messages FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Service role can add messages (support replies)
DROP POLICY IF EXISTS "Service role can add messages" ON support_ticket_messages;
CREATE POLICY "Service role can add messages"
    ON support_ticket_messages FOR INSERT
    WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ===================================
-- Grant Permissions
-- ===================================

-- Grant access to authenticated users
GRANT SELECT, INSERT, UPDATE ON support_tickets TO authenticated;
GRANT SELECT, INSERT ON support_ticket_messages TO authenticated;

-- Grant access to service role (for support staff operations)
GRANT ALL ON support_tickets TO service_role;
GRANT ALL ON support_ticket_messages TO service_role;

-- Grant view access
GRANT SELECT ON support_tickets_summary TO authenticated, service_role;
GRANT SELECT ON support_ticket_user_stats TO authenticated, service_role;
GRANT SELECT ON support_ticket_overview TO service_role;

-- ===================================
-- Comments for Documentation
-- ===================================
COMMENT ON TABLE support_tickets IS 'Stores user support tickets with categories, priorities, and status tracking';
COMMENT ON TABLE support_ticket_messages IS 'Stores conversation thread messages for each support ticket';
COMMENT ON COLUMN support_tickets.category IS 'Ticket category: billing, technical, feature_request, bug_report, account, other';
COMMENT ON COLUMN support_tickets.priority IS 'Ticket priority: low, medium, high, urgent';
COMMENT ON COLUMN support_tickets.status IS 'Ticket lifecycle: open -> in_progress -> waiting_response -> resolved -> closed';
COMMENT ON COLUMN support_tickets.resolved_at IS 'Timestamp when the issue was resolved';
COMMENT ON COLUMN support_tickets.closed_at IS 'Timestamp when the ticket was closed';
COMMENT ON COLUMN support_ticket_messages.sender IS 'Message sender: user or support';
COMMENT ON COLUMN support_ticket_messages.is_internal IS 'True for internal support team notes (hidden from users)';
COMMENT ON VIEW support_tickets_summary IS 'Summary view with message counts and last message preview';
COMMENT ON VIEW support_ticket_user_stats IS 'Per-user ticket statistics';
COMMENT ON VIEW support_ticket_overview IS 'Admin dashboard overview of ticket distribution';
