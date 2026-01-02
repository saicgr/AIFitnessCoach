-- Migration: 090_trial_demo_tracking
-- Description: Add tables for tracking demo sessions and trial behavior
-- This helps understand what features lead to conversion
-- Addresses complaint: "hit a paywall to even see how the app works"

-- ============================================================================
-- DEMO SESSIONS TABLE
-- Track anonymous demo/guest sessions before users sign up
-- ============================================================================
CREATE TABLE IF NOT EXISTS demo_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT UNIQUE NOT NULL,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    quiz_data JSONB DEFAULT '{}',
    device_info JSONB DEFAULT '{}',
    converted_to_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    conversion_trigger TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick session lookups
CREATE INDEX IF NOT EXISTS idx_demo_sessions_session_id ON demo_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_demo_sessions_started_at ON demo_sessions(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_demo_sessions_converted ON demo_sessions(converted_to_user_id) WHERE converted_to_user_id IS NOT NULL;

-- ============================================================================
-- DEMO INTERACTIONS TABLE
-- Track what demo users do for conversion analytics
-- ============================================================================
CREATE TABLE IF NOT EXISTS demo_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL,
    action_type TEXT NOT NULL,
    screen TEXT,
    feature TEXT,
    duration_seconds INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_demo_interactions_session ON demo_interactions(session_id);
CREATE INDEX IF NOT EXISTS idx_demo_interactions_action ON demo_interactions(action_type);
CREATE INDEX IF NOT EXISTS idx_demo_interactions_created ON demo_interactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_demo_interactions_feature ON demo_interactions(feature) WHERE feature IS NOT NULL;

-- ============================================================================
-- TRIAL EXTENSIONS TABLE
-- Track when trials are extended (for support, promotions, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS trial_extensions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_end_date TIMESTAMPTZ NOT NULL,
    new_end_date TIMESTAMPTZ NOT NULL,
    extension_days INTEGER NOT NULL,
    reason TEXT,
    granted_by TEXT DEFAULT 'system',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trial_extensions_user ON trial_extensions(user_id);

-- ============================================================================
-- UPDATE USER_SUBSCRIPTIONS TABLE
-- Add trial-related columns if they don't exist
-- ============================================================================
DO $$
BEGIN
    -- Add trial_type column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_subscriptions' AND column_name = 'trial_type'
    ) THEN
        ALTER TABLE user_subscriptions ADD COLUMN trial_type TEXT DEFAULT 'full_access';
    END IF;

    -- Add trial_plan_type column if not exists (tracks which plan trial is for)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_subscriptions' AND column_name = 'trial_plan_type'
    ) THEN
        ALTER TABLE user_subscriptions ADD COLUMN trial_plan_type TEXT;
    END IF;

    -- Add demo_session_id to link subscription to demo session
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_subscriptions' AND column_name = 'demo_session_id'
    ) THEN
        ALTER TABLE user_subscriptions ADD COLUMN demo_session_id TEXT;
    END IF;
END $$;

-- ============================================================================
-- DEMO CONVERSION FUNNEL VIEW
-- Analytics view for understanding demo-to-signup conversion
-- ============================================================================
CREATE OR REPLACE VIEW demo_conversion_funnel AS
SELECT
    DATE(started_at) as date,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN converted_to_user_id IS NOT NULL THEN 1 END) as conversions,
    ROUND(
        COUNT(CASE WHEN converted_to_user_id IS NOT NULL THEN 1 END)::numeric /
        NULLIF(COUNT(*)::numeric, 0) * 100,
        2
    ) as conversion_rate_percent,
    ROUND(AVG(duration_seconds)::numeric, 0) as avg_session_seconds,
    ROUND(AVG(CASE WHEN converted_to_user_id IS NOT NULL THEN duration_seconds END)::numeric, 0) as avg_converted_session_seconds,
    COUNT(DISTINCT quiz_data->>'goal') as unique_goals,
    jsonb_agg(DISTINCT conversion_trigger) FILTER (WHERE conversion_trigger IS NOT NULL) as conversion_triggers
FROM demo_sessions
WHERE started_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;

-- ============================================================================
-- DEMO FEATURE ENGAGEMENT VIEW
-- See which features demo users engage with most
-- ============================================================================
CREATE OR REPLACE VIEW demo_feature_engagement AS
SELECT
    feature,
    action_type,
    COUNT(*) as interaction_count,
    COUNT(DISTINCT session_id) as unique_sessions,
    ROUND(AVG(duration_seconds)::numeric, 1) as avg_duration_seconds
FROM demo_interactions
WHERE feature IS NOT NULL
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY feature, action_type
ORDER BY interaction_count DESC;

-- ============================================================================
-- DEMO SCREEN FLOW VIEW
-- Track screen navigation patterns
-- ============================================================================
CREATE OR REPLACE VIEW demo_screen_flow AS
SELECT
    screen,
    COUNT(*) as view_count,
    COUNT(DISTINCT session_id) as unique_sessions,
    ROUND(AVG(duration_seconds)::numeric, 1) as avg_time_seconds,
    SUM(duration_seconds) as total_time_seconds
FROM demo_interactions
WHERE action_type = 'screen_view'
  AND screen IS NOT NULL
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY screen
ORDER BY view_count DESC;

-- ============================================================================
-- TRIGGER: Auto-calculate session duration on end
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_demo_session_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
        NEW.duration_seconds := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_demo_session_duration ON demo_sessions;
CREATE TRIGGER tr_demo_session_duration
    BEFORE UPDATE ON demo_sessions
    FOR EACH ROW
    EXECUTE FUNCTION calculate_demo_session_duration();

-- ============================================================================
-- RLS POLICIES
-- Demo tables allow inserts from anyone but reads are restricted
-- ============================================================================

-- Enable RLS
ALTER TABLE demo_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE demo_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trial_extensions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS demo_sessions_insert_policy ON demo_sessions;
DROP POLICY IF EXISTS demo_sessions_select_policy ON demo_sessions;
DROP POLICY IF EXISTS demo_interactions_insert_policy ON demo_interactions;
DROP POLICY IF EXISTS demo_interactions_select_policy ON demo_interactions;
DROP POLICY IF EXISTS trial_extensions_select_policy ON trial_extensions;
DROP POLICY IF EXISTS trial_extensions_insert_policy ON trial_extensions;

-- Demo sessions: Anyone can insert (anonymous users), service role can read all
CREATE POLICY demo_sessions_insert_policy ON demo_sessions
    FOR INSERT WITH CHECK (true);

CREATE POLICY demo_sessions_select_policy ON demo_sessions
    FOR SELECT USING (
        -- Users can see their own converted session
        auth.uid() = converted_to_user_id
        OR
        -- Service role can see all
        auth.role() = 'service_role'
    );

CREATE POLICY demo_sessions_update_policy ON demo_sessions
    FOR UPDATE USING (true);

-- Demo interactions: Anyone can insert, service role can read all
CREATE POLICY demo_interactions_insert_policy ON demo_interactions
    FOR INSERT WITH CHECK (true);

CREATE POLICY demo_interactions_select_policy ON demo_interactions
    FOR SELECT USING (auth.role() = 'service_role');

-- Trial extensions: Users can see their own, service role can manage all
CREATE POLICY trial_extensions_select_policy ON trial_extensions
    FOR SELECT USING (
        user_id = auth.uid()
        OR auth.role() = 'service_role'
    );

CREATE POLICY trial_extensions_insert_policy ON trial_extensions
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE demo_sessions IS 'Tracks anonymous demo/guest sessions before user signup. Links to users table when converted.';
COMMENT ON TABLE demo_interactions IS 'Tracks feature interactions during demo sessions for conversion analytics.';
COMMENT ON TABLE trial_extensions IS 'Audit log of trial period extensions granted to users.';
COMMENT ON VIEW demo_conversion_funnel IS 'Daily conversion metrics for demo sessions over the last 30 days.';
COMMENT ON VIEW demo_feature_engagement IS 'Feature-level engagement metrics for demo users.';
COMMENT ON VIEW demo_screen_flow IS 'Screen navigation patterns for demo users.';
