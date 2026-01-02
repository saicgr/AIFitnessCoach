-- Migration 126: Chat Message Reports System
-- Allows users to report problematic AI responses for quality improvement
-- Categories: wrong_advice, inappropriate, unhelpful, outdated_info, other

-- ============================================================================
-- Table: chat_message_reports
-- Stores user reports about AI chat responses that were problematic
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_message_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id TEXT NOT NULL,  -- The chat message ID being reported
    report_category TEXT NOT NULL CHECK (report_category IN (
        'wrong_advice',
        'inappropriate',
        'unhelpful',
        'outdated_info',
        'other'
    )),
    report_reason TEXT,  -- Optional detailed reason from user
    original_user_message TEXT NOT NULL,  -- What the user asked
    reported_ai_response TEXT NOT NULL,  -- The AI response being reported
    ai_analysis TEXT,  -- Gemini's analysis of why the response was problematic
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'reviewed',
        'resolved',
        'dismissed'
    )),
    resolution_note TEXT,  -- Admin notes about resolution
    reviewed_at TIMESTAMPTZ,  -- When the report was reviewed
    reviewed_by TEXT,  -- Admin who reviewed the report
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_chat_message_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS chat_message_reports_updated_at ON chat_message_reports;
CREATE TRIGGER chat_message_reports_updated_at
    BEFORE UPDATE ON chat_message_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_message_reports_updated_at();

-- Add comments for documentation
COMMENT ON TABLE chat_message_reports IS 'Stores user reports about problematic AI chat responses for quality improvement';
COMMENT ON COLUMN chat_message_reports.message_id IS 'The unique identifier of the chat message being reported';
COMMENT ON COLUMN chat_message_reports.report_category IS 'Category of the issue: wrong_advice, inappropriate, unhelpful, outdated_info, other';
COMMENT ON COLUMN chat_message_reports.report_reason IS 'Optional detailed explanation from the user about why they are reporting';
COMMENT ON COLUMN chat_message_reports.original_user_message IS 'The user message/question that triggered the problematic AI response';
COMMENT ON COLUMN chat_message_reports.reported_ai_response IS 'The full AI response text that is being reported';
COMMENT ON COLUMN chat_message_reports.ai_analysis IS 'Automated AI analysis of why the response may have been problematic';
COMMENT ON COLUMN chat_message_reports.status IS 'Report lifecycle: pending -> reviewed -> resolved/dismissed';
COMMENT ON COLUMN chat_message_reports.resolution_note IS 'Admin notes explaining how the report was resolved';
COMMENT ON COLUMN chat_message_reports.reviewed_at IS 'Timestamp when an admin reviewed the report';
COMMENT ON COLUMN chat_message_reports.reviewed_by IS 'Identifier of the admin who reviewed the report';
COMMENT ON COLUMN chat_message_reports.updated_at IS 'Timestamp of the last update to the report';

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Index on user_id for fetching user's own reports
CREATE INDEX IF NOT EXISTS idx_chat_message_reports_user_id
    ON chat_message_reports(user_id);

-- Index on status for filtering by report status (admin dashboard)
CREATE INDEX IF NOT EXISTS idx_chat_message_reports_status
    ON chat_message_reports(status);

-- Index on created_at for chronological queries
CREATE INDEX IF NOT EXISTS idx_chat_message_reports_created_at
    ON chat_message_reports(created_at DESC);

-- Composite index for common user queries (user's reports by date)
CREATE INDEX IF NOT EXISTS idx_chat_message_reports_user_created
    ON chat_message_reports(user_id, created_at DESC);

-- Composite index for admin filtering (status + date)
CREATE INDEX IF NOT EXISTS idx_chat_message_reports_status_created
    ON chat_message_reports(status, created_at DESC);

-- Index on report_category for analytics
CREATE INDEX IF NOT EXISTS idx_chat_message_reports_category
    ON chat_message_reports(report_category);

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

-- Enable RLS on the table
ALTER TABLE chat_message_reports ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS Policies
-- ============================================================================

-- Users can INSERT their own reports
DROP POLICY IF EXISTS "Users can create own reports" ON chat_message_reports;
CREATE POLICY "Users can create own reports"
    ON chat_message_reports FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can SELECT their own reports
DROP POLICY IF EXISTS "Users can view own reports" ON chat_message_reports;
CREATE POLICY "Users can view own reports"
    ON chat_message_reports FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can view all reports (for admin dashboard)
DROP POLICY IF EXISTS "Service role can view all reports" ON chat_message_reports;
CREATE POLICY "Service role can view all reports"
    ON chat_message_reports FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Service role can update all reports (for admin resolution)
DROP POLICY IF EXISTS "Service role can update all reports" ON chat_message_reports;
CREATE POLICY "Service role can update all reports"
    ON chat_message_reports FOR UPDATE
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Service role can delete reports if needed
DROP POLICY IF EXISTS "Service role can delete reports" ON chat_message_reports;
CREATE POLICY "Service role can delete reports"
    ON chat_message_reports FOR DELETE
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Note: Regular users have NO UPDATE or DELETE permissions on reports
-- This ensures report integrity and prevents users from modifying/removing their reports

-- ============================================================================
-- View: chat_message_reports_with_user
-- Admin dashboard view with user information
-- ============================================================================
CREATE OR REPLACE VIEW chat_message_reports_with_user
WITH (security_invoker = true)
AS
SELECT
    r.id,
    r.user_id,
    r.message_id,
    r.report_category,
    r.report_reason,
    r.original_user_message,
    r.reported_ai_response,
    r.ai_analysis,
    r.status,
    r.resolution_note,
    r.reviewed_at,
    r.reviewed_by,
    r.created_at,
    r.updated_at,
    u.username,
    u.name AS user_name,
    u.fitness_level,
    u.goals AS user_goals
FROM chat_message_reports r
LEFT JOIN users u ON r.user_id = u.auth_id;

COMMENT ON VIEW chat_message_reports_with_user IS 'Admin dashboard view showing chat message reports with user profile information';

-- ============================================================================
-- View: chat_message_reports_summary
-- Aggregated statistics for monitoring report trends
-- ============================================================================
CREATE OR REPLACE VIEW chat_message_reports_summary
WITH (security_invoker = true)
AS
SELECT
    report_category,
    status,
    COUNT(*) AS report_count,
    MIN(created_at) AS oldest_report,
    MAX(created_at) AS newest_report,
    AVG(
        CASE
            WHEN reviewed_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (reviewed_at - created_at)) / 3600
            ELSE NULL
        END
    ) AS avg_review_time_hours
FROM chat_message_reports
GROUP BY report_category, status
ORDER BY
    CASE status
        WHEN 'pending' THEN 1
        WHEN 'reviewed' THEN 2
        WHEN 'resolved' THEN 3
        WHEN 'dismissed' THEN 4
    END,
    report_count DESC;

COMMENT ON VIEW chat_message_reports_summary IS 'Aggregated statistics for monitoring chat message report trends';

-- ============================================================================
-- Grant Permissions
-- ============================================================================

-- Grant access to authenticated users (limited by RLS)
GRANT SELECT, INSERT ON chat_message_reports TO authenticated;

-- Grant full access to service role (for admin operations)
GRANT ALL ON chat_message_reports TO service_role;

-- Grant view access
GRANT SELECT ON chat_message_reports_with_user TO service_role;
GRANT SELECT ON chat_message_reports_summary TO service_role;
