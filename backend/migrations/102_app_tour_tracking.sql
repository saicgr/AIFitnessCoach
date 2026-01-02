-- Migration: 102_app_tour_tracking.sql
-- Description: Create tables for tracking App Tour sessions and step events
-- Purpose: Analytics for onboarding tour effectiveness, conversion tracking, and A/B testing
-- Created: 2025-12-30

-- ============================================================================
-- APP TOUR SESSIONS TABLE
-- ============================================================================
-- Tracks individual tour sessions, supporting both authenticated and anonymous users
-- Supports pre-auth tours (before signup) and in-app tours (from settings)

CREATE TABLE IF NOT EXISTS app_tour_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- User reference (nullable for pre-auth anonymous tours)
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Anonymous session tracking (for pre-auth tours)
    session_id TEXT UNIQUE NOT NULL,

    -- Tour context
    source TEXT NOT NULL CHECK (source IN (
        'new_user',      -- First-time user onboarding
        'settings',      -- User initiated from settings
        'deep_link',     -- Accessed via deep link
        'app_update',    -- Shown after major app update
        'feature_intro'  -- Shown to introduce new feature
    )),

    -- Device and environment info
    device_info JSONB DEFAULT '{}',
    -- Expected structure:
    -- {
    --   "platform": "ios|android|web",
    --   "os_version": "17.0",
    --   "app_version": "1.5.0",
    --   "device_model": "iPhone 15 Pro",
    --   "screen_width": 390,
    --   "screen_height": 844,
    --   "locale": "en_US"
    -- }

    -- Progress tracking
    steps_completed TEXT[] DEFAULT '{}',
    current_step TEXT,

    -- A/B testing support
    tour_version TEXT DEFAULT '1.0',

    -- Timing
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    skipped_at TIMESTAMPTZ,

    -- Skip tracking
    skip_reason TEXT CHECK (skip_reason IS NULL OR skip_reason IN (
        'already_familiar',   -- User knows the app
        'too_long',           -- Tour felt too long
        'not_interested',     -- User not interested
        'accidental',         -- Accidental skip
        'will_do_later',      -- User wants to explore first
        'other'               -- Other reason
    )),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- APP TOUR STEP EVENTS TABLE
-- ============================================================================
-- Tracks individual step interactions within a tour session
-- Enables granular analysis of user behavior at each step

CREATE TABLE IF NOT EXISTS app_tour_step_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Session reference
    tour_session_id UUID NOT NULL REFERENCES app_tour_sessions(id) ON DELETE CASCADE,

    -- Step identification
    step_id TEXT NOT NULL CHECK (step_id IN (
        'welcome',         -- Welcome/intro screen
        'ai_workouts',     -- AI-generated workouts feature
        'chat_coach',      -- AI chat coach feature
        'library',         -- Exercise library feature
        'progress',        -- Progress tracking feature
        'nutrition',       -- Nutrition tracking feature
        'complete',        -- Tour completion screen
        'custom_step'      -- For future extensibility
    )),

    -- Step index for ordering (0-based)
    step_index INTEGER DEFAULT 0 CHECK (step_index >= 0),

    -- Action taken
    action TEXT NOT NULL CHECK (action IN (
        'viewed',          -- Step was displayed
        'interacted',      -- User interacted with step content
        'skipped',         -- User skipped this step
        'deep_linked',     -- User clicked to explore feature
        'back_navigated',  -- User went back to this step
        'replayed',        -- User replayed animation/video
        'help_clicked'     -- User clicked help/info
    )),

    -- Duration on this step (seconds)
    duration_seconds INTEGER DEFAULT 0 CHECK (duration_seconds >= 0),

    -- Interaction details
    interaction_data JSONB DEFAULT '{}',
    -- Expected structure:
    -- {
    --   "button_clicks": ["next", "learn_more"],
    --   "scroll_depth": 0.8,
    --   "video_watched_percent": 100,
    --   "tooltip_interactions": ["tip_1", "tip_2"],
    --   "feature_preview_used": true
    -- }

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- App tour sessions indexes
CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_user_id
    ON app_tour_sessions(user_id)
    WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_session_id
    ON app_tour_sessions(session_id);

CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_source
    ON app_tour_sessions(source);

CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_started_at
    ON app_tour_sessions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_completed
    ON app_tour_sessions(completed_at)
    WHERE completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_skipped
    ON app_tour_sessions(skipped_at)
    WHERE skipped_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_tour_version
    ON app_tour_sessions(tour_version);

-- Composite index for conversion analysis
CREATE INDEX IF NOT EXISTS idx_app_tour_sessions_conversion
    ON app_tour_sessions(user_id, completed_at, source)
    WHERE user_id IS NOT NULL;

-- App tour step events indexes
CREATE INDEX IF NOT EXISTS idx_app_tour_step_events_session
    ON app_tour_step_events(tour_session_id);

CREATE INDEX IF NOT EXISTS idx_app_tour_step_events_step_id
    ON app_tour_step_events(step_id);

CREATE INDEX IF NOT EXISTS idx_app_tour_step_events_action
    ON app_tour_step_events(action);

CREATE INDEX IF NOT EXISTS idx_app_tour_step_events_created_at
    ON app_tour_step_events(created_at DESC);

-- Composite index for step analytics
CREATE INDEX IF NOT EXISTS idx_app_tour_step_events_analytics
    ON app_tour_step_events(step_id, action, created_at DESC);

-- ============================================================================
-- ANALYTICS VIEW: APP_TOUR_ANALYTICS
-- ============================================================================
-- Provides daily aggregated tour metrics for dashboards and analysis

CREATE OR REPLACE VIEW app_tour_analytics AS
WITH daily_stats AS (
    SELECT
        DATE(started_at) AS date,
        tour_version,
        source,
        COUNT(*) AS total_starts,
        COUNT(CASE WHEN completed_at IS NOT NULL THEN 1 END) AS total_completions,
        COUNT(CASE WHEN skipped_at IS NOT NULL THEN 1 END) AS total_skips,
        COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) AS authenticated_tours,
        COUNT(CASE WHEN user_id IS NULL THEN 1 END) AS anonymous_tours,
        AVG(EXTRACT(EPOCH FROM (COALESCE(completed_at, skipped_at, NOW()) - started_at)))::INTEGER AS avg_duration_seconds,
        array_agg(DISTINCT skip_reason) FILTER (WHERE skip_reason IS NOT NULL) AS skip_reasons
    FROM app_tour_sessions
    WHERE started_at >= NOW() - INTERVAL '90 days'
    GROUP BY DATE(started_at), tour_version, source
),
step_stats AS (
    SELECT
        DATE(e.created_at) AS date,
        s.tour_version,
        e.step_id,
        COUNT(*) FILTER (WHERE e.action = 'viewed') AS views,
        COUNT(*) FILTER (WHERE e.action = 'skipped') AS skips,
        COUNT(*) FILTER (WHERE e.action = 'deep_linked') AS deep_links,
        AVG(e.duration_seconds) FILTER (WHERE e.action = 'viewed')::INTEGER AS avg_step_duration
    FROM app_tour_step_events e
    JOIN app_tour_sessions s ON s.id = e.tour_session_id
    WHERE e.created_at >= NOW() - INTERVAL '90 days'
    GROUP BY DATE(e.created_at), s.tour_version, e.step_id
),
conversion_stats AS (
    SELECT
        DATE(started_at) AS date,
        tour_version,
        COUNT(*) FILTER (WHERE user_id IS NULL) AS pre_auth_starts,
        COUNT(*) FILTER (WHERE user_id IS NULL AND completed_at IS NOT NULL) AS pre_auth_completions,
        -- Conversion: pre-auth tour that led to signup (user_id was set later)
        COUNT(*) FILTER (
            WHERE user_id IS NOT NULL
            AND source = 'new_user'
            AND completed_at IS NOT NULL
        ) AS signup_conversions
    FROM app_tour_sessions
    WHERE started_at >= NOW() - INTERVAL '90 days'
    GROUP BY DATE(started_at), tour_version
)
SELECT
    d.date,
    d.tour_version,
    d.source,
    d.total_starts,
    d.total_completions,
    d.total_skips,
    ROUND(
        d.total_completions::NUMERIC / NULLIF(d.total_starts::NUMERIC, 0) * 100,
        2
    ) AS completion_rate_percent,
    ROUND(
        d.total_skips::NUMERIC / NULLIF(d.total_starts::NUMERIC, 0) * 100,
        2
    ) AS skip_rate_percent,
    d.authenticated_tours,
    d.anonymous_tours,
    d.avg_duration_seconds,
    d.skip_reasons,
    c.pre_auth_starts,
    c.pre_auth_completions,
    c.signup_conversions,
    ROUND(
        c.signup_conversions::NUMERIC / NULLIF(c.pre_auth_completions::NUMERIC, 0) * 100,
        2
    ) AS signup_conversion_rate_percent
FROM daily_stats d
LEFT JOIN conversion_stats c ON c.date = d.date AND c.tour_version = d.tour_version
ORDER BY d.date DESC, d.tour_version, d.source;

-- ============================================================================
-- ANALYTICS VIEW: APP_TOUR_STEP_ANALYTICS
-- ============================================================================
-- Provides step-level analytics for identifying friction points

CREATE OR REPLACE VIEW app_tour_step_analytics AS
SELECT
    e.step_id,
    s.tour_version,
    COUNT(DISTINCT e.tour_session_id) AS unique_sessions,
    COUNT(*) FILTER (WHERE e.action = 'viewed') AS total_views,
    COUNT(*) FILTER (WHERE e.action = 'skipped') AS total_skips,
    COUNT(*) FILTER (WHERE e.action = 'deep_linked') AS total_deep_links,
    COUNT(*) FILTER (WHERE e.action = 'interacted') AS total_interactions,
    COUNT(*) FILTER (WHERE e.action = 'back_navigated') AS back_navigations,
    ROUND(
        COUNT(*) FILTER (WHERE e.action = 'skipped')::NUMERIC /
        NULLIF(COUNT(*) FILTER (WHERE e.action = 'viewed')::NUMERIC, 0) * 100,
        2
    ) AS skip_rate_percent,
    AVG(e.duration_seconds) FILTER (WHERE e.action = 'viewed')::INTEGER AS avg_duration_seconds,
    MIN(e.duration_seconds) FILTER (WHERE e.action = 'viewed') AS min_duration_seconds,
    MAX(e.duration_seconds) FILTER (WHERE e.action = 'viewed') AS max_duration_seconds,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.duration_seconds)
        FILTER (WHERE e.action = 'viewed')::INTEGER AS median_duration_seconds
FROM app_tour_step_events e
JOIN app_tour_sessions s ON s.id = e.tour_session_id
WHERE e.created_at >= NOW() - INTERVAL '30 days'
GROUP BY e.step_id, s.tour_version
ORDER BY
    s.tour_version,
    CASE e.step_id
        WHEN 'welcome' THEN 1
        WHEN 'ai_workouts' THEN 2
        WHEN 'chat_coach' THEN 3
        WHEN 'library' THEN 4
        WHEN 'progress' THEN 5
        WHEN 'nutrition' THEN 6
        WHEN 'complete' THEN 7
        ELSE 8
    END;

-- ============================================================================
-- ANALYTICS VIEW: APP_TOUR_SKIP_ANALYSIS
-- ============================================================================
-- Identifies common skip points and reasons

CREATE OR REPLACE VIEW app_tour_skip_analysis AS
SELECT
    COALESCE(current_step, 'unknown') AS skip_point,
    skip_reason,
    tour_version,
    source,
    COUNT(*) AS skip_count,
    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY tour_version) * 100,
        2
    ) AS percent_of_skips,
    AVG(EXTRACT(EPOCH FROM (skipped_at - started_at)))::INTEGER AS avg_time_before_skip_seconds,
    AVG(array_length(steps_completed, 1))::NUMERIC(4,2) AS avg_steps_completed_before_skip
FROM app_tour_sessions
WHERE skipped_at IS NOT NULL
  AND started_at >= NOW() - INTERVAL '30 days'
GROUP BY current_step, skip_reason, tour_version, source
ORDER BY skip_count DESC;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on both tables
ALTER TABLE app_tour_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_tour_step_events ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- APP TOUR SESSIONS POLICIES
-- ============================================================================

-- Drop existing policies if they exist (for idempotent migrations)
DROP POLICY IF EXISTS app_tour_sessions_anon_insert ON app_tour_sessions;
DROP POLICY IF EXISTS app_tour_sessions_anon_update ON app_tour_sessions;
DROP POLICY IF EXISTS app_tour_sessions_select_own ON app_tour_sessions;
DROP POLICY IF EXISTS app_tour_sessions_update_own ON app_tour_sessions;
DROP POLICY IF EXISTS app_tour_sessions_service_all ON app_tour_sessions;

-- Anonymous users can insert new tour sessions (for pre-auth tours)
CREATE POLICY app_tour_sessions_anon_insert ON app_tour_sessions
    FOR INSERT
    TO anon
    WITH CHECK (user_id IS NULL);

-- Anonymous users can update their own sessions by session_id
CREATE POLICY app_tour_sessions_anon_update ON app_tour_sessions
    FOR UPDATE
    TO anon
    USING (user_id IS NULL)
    WITH CHECK (user_id IS NULL);

-- Authenticated users can read their own tour data
CREATE POLICY app_tour_sessions_select_own ON app_tour_sessions
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id
        OR user_id IS NULL  -- Can also see anonymous sessions (for claiming after signup)
    );

-- Authenticated users can insert their own tours
CREATE POLICY app_tour_sessions_insert_own ON app_tour_sessions
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = user_id
        OR user_id IS NULL
    );

-- Authenticated users can update their own tour data
CREATE POLICY app_tour_sessions_update_own ON app_tour_sessions
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id OR user_id IS NULL)
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Service role has full access (for admin analytics)
CREATE POLICY app_tour_sessions_service_all ON app_tour_sessions
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- APP TOUR STEP EVENTS POLICIES
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS app_tour_step_events_anon_insert ON app_tour_step_events;
DROP POLICY IF EXISTS app_tour_step_events_select_own ON app_tour_step_events;
DROP POLICY IF EXISTS app_tour_step_events_insert_own ON app_tour_step_events;
DROP POLICY IF EXISTS app_tour_step_events_service_all ON app_tour_step_events;

-- Anonymous users can insert step events for their sessions
CREATE POLICY app_tour_step_events_anon_insert ON app_tour_step_events
    FOR INSERT
    TO anon
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM app_tour_sessions
            WHERE id = tour_session_id AND user_id IS NULL
        )
    );

-- Authenticated users can read step events for their own sessions
CREATE POLICY app_tour_step_events_select_own ON app_tour_step_events
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM app_tour_sessions
            WHERE id = tour_session_id
            AND (user_id = auth.uid() OR user_id IS NULL)
        )
    );

-- Authenticated users can insert step events for their own sessions
CREATE POLICY app_tour_step_events_insert_own ON app_tour_step_events
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM app_tour_sessions
            WHERE id = tour_session_id
            AND (user_id = auth.uid() OR user_id IS NULL)
        )
    );

-- Service role has full access (for admin analytics)
CREATE POLICY app_tour_step_events_service_all ON app_tour_step_events
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger for app_tour_sessions
CREATE OR REPLACE FUNCTION update_app_tour_sessions_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_app_tour_sessions_updated_at ON app_tour_sessions;
CREATE TRIGGER trigger_app_tour_sessions_updated_at
    BEFORE UPDATE ON app_tour_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_app_tour_sessions_timestamp();

-- Trigger to auto-update steps_completed when step events are inserted
CREATE OR REPLACE FUNCTION update_tour_steps_completed()
RETURNS TRIGGER AS $$
BEGIN
    -- Only track 'viewed' actions as completed steps
    IF NEW.action = 'viewed' THEN
        UPDATE app_tour_sessions
        SET
            steps_completed = CASE
                WHEN NOT (NEW.step_id = ANY(steps_completed))
                THEN array_append(steps_completed, NEW.step_id)
                ELSE steps_completed
            END,
            current_step = NEW.step_id,
            updated_at = NOW()
        WHERE id = NEW.tour_session_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_tour_steps ON app_tour_step_events;
CREATE TRIGGER trigger_update_tour_steps
    AFTER INSERT ON app_tour_step_events
    FOR EACH ROW
    EXECUTE FUNCTION update_tour_steps_completed();

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to start a new tour session
CREATE OR REPLACE FUNCTION start_app_tour(
    p_session_id TEXT,
    p_user_id UUID DEFAULT NULL,
    p_source TEXT DEFAULT 'new_user',
    p_device_info JSONB DEFAULT '{}',
    p_tour_version TEXT DEFAULT '1.0'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tour_id UUID;
BEGIN
    INSERT INTO app_tour_sessions (
        session_id,
        user_id,
        source,
        device_info,
        tour_version,
        started_at
    ) VALUES (
        p_session_id,
        p_user_id,
        p_source,
        p_device_info,
        p_tour_version,
        NOW()
    )
    ON CONFLICT (session_id) DO UPDATE SET
        user_id = COALESCE(EXCLUDED.user_id, app_tour_sessions.user_id),
        updated_at = NOW()
    RETURNING id INTO v_tour_id;

    RETURN v_tour_id;
END;
$$;

-- Function to record a step event
CREATE OR REPLACE FUNCTION record_tour_step(
    p_tour_session_id UUID,
    p_step_id TEXT,
    p_step_index INTEGER DEFAULT 0,
    p_action TEXT DEFAULT 'viewed',
    p_duration_seconds INTEGER DEFAULT 0,
    p_interaction_data JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO app_tour_step_events (
        tour_session_id,
        step_id,
        step_index,
        action,
        duration_seconds,
        interaction_data
    ) VALUES (
        p_tour_session_id,
        p_step_id,
        p_step_index,
        p_action,
        p_duration_seconds,
        p_interaction_data
    )
    RETURNING id INTO v_event_id;

    RETURN v_event_id;
END;
$$;

-- Function to complete a tour
CREATE OR REPLACE FUNCTION complete_app_tour(
    p_tour_session_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE app_tour_sessions
    SET
        completed_at = NOW(),
        updated_at = NOW()
    WHERE id = p_tour_session_id
      AND completed_at IS NULL
      AND skipped_at IS NULL;

    RETURN FOUND;
END;
$$;

-- Function to skip a tour
CREATE OR REPLACE FUNCTION skip_app_tour(
    p_tour_session_id UUID,
    p_skip_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE app_tour_sessions
    SET
        skipped_at = NOW(),
        skip_reason = p_skip_reason,
        updated_at = NOW()
    WHERE id = p_tour_session_id
      AND completed_at IS NULL
      AND skipped_at IS NULL;

    RETURN FOUND;
END;
$$;

-- Function to claim an anonymous tour session after signup
CREATE OR REPLACE FUNCTION claim_tour_session(
    p_session_id TEXT,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE app_tour_sessions
    SET
        user_id = p_user_id,
        updated_at = NOW()
    WHERE session_id = p_session_id
      AND user_id IS NULL;

    RETURN FOUND;
END;
$$;

-- Function to get tour completion stats for a user
CREATE OR REPLACE FUNCTION get_user_tour_stats(p_user_id UUID)
RETURNS TABLE (
    total_tours INTEGER,
    completed_tours INTEGER,
    skipped_tours INTEGER,
    avg_completion_time_seconds INTEGER,
    most_recent_tour_at TIMESTAMPTZ,
    most_skipped_step TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH tour_stats AS (
        SELECT
            COUNT(*) AS total,
            COUNT(completed_at) AS completed,
            COUNT(skipped_at) AS skipped,
            AVG(EXTRACT(EPOCH FROM (completed_at - started_at)))::INTEGER AS avg_time,
            MAX(started_at) AS most_recent
        FROM app_tour_sessions
        WHERE user_id = p_user_id
    ),
    skip_stats AS (
        SELECT current_step, COUNT(*) AS skip_count
        FROM app_tour_sessions
        WHERE user_id = p_user_id AND skipped_at IS NOT NULL
        GROUP BY current_step
        ORDER BY skip_count DESC
        LIMIT 1
    )
    SELECT
        ts.total::INTEGER,
        ts.completed::INTEGER,
        ts.skipped::INTEGER,
        ts.avg_time,
        ts.most_recent,
        ss.current_step
    FROM tour_stats ts
    LEFT JOIN skip_stats ss ON true;
END;
$$;

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant permissions on tables
GRANT SELECT, INSERT, UPDATE ON app_tour_sessions TO authenticated;
GRANT SELECT, INSERT ON app_tour_step_events TO authenticated;
GRANT INSERT, UPDATE ON app_tour_sessions TO anon;
GRANT INSERT ON app_tour_step_events TO anon;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION start_app_tour TO authenticated, anon;
GRANT EXECUTE ON FUNCTION record_tour_step TO authenticated, anon;
GRANT EXECUTE ON FUNCTION complete_app_tour TO authenticated, anon;
GRANT EXECUTE ON FUNCTION skip_app_tour TO authenticated, anon;
GRANT EXECUTE ON FUNCTION claim_tour_session TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_tour_stats TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE app_tour_sessions IS 'Tracks app tour sessions for onboarding analytics. Supports both authenticated and anonymous (pre-signup) users.';
COMMENT ON TABLE app_tour_step_events IS 'Tracks individual step interactions within app tour sessions for granular analytics.';

COMMENT ON COLUMN app_tour_sessions.session_id IS 'Unique anonymous session identifier, allows tracking before user signup';
COMMENT ON COLUMN app_tour_sessions.source IS 'How the tour was initiated (new_user, settings, deep_link, etc.)';
COMMENT ON COLUMN app_tour_sessions.device_info IS 'JSON object containing device/environment information';
COMMENT ON COLUMN app_tour_sessions.steps_completed IS 'Array of step IDs that were completed during this tour';
COMMENT ON COLUMN app_tour_sessions.tour_version IS 'Version identifier for A/B testing different tour flows';
COMMENT ON COLUMN app_tour_sessions.skip_reason IS 'User-selected reason for skipping the tour';

COMMENT ON COLUMN app_tour_step_events.step_id IS 'Identifier for the tour step (welcome, ai_workouts, etc.)';
COMMENT ON COLUMN app_tour_step_events.step_index IS 'Zero-based index of the step in the tour sequence';
COMMENT ON COLUMN app_tour_step_events.action IS 'Type of action taken (viewed, interacted, skipped, deep_linked)';
COMMENT ON COLUMN app_tour_step_events.duration_seconds IS 'Time spent on this step in seconds';
COMMENT ON COLUMN app_tour_step_events.interaction_data IS 'JSON object containing detailed interaction data';

COMMENT ON VIEW app_tour_analytics IS 'Daily aggregated tour metrics including completion rates, skip rates, and conversion stats';
COMMENT ON VIEW app_tour_step_analytics IS 'Step-level analytics for identifying friction points in the tour flow';
COMMENT ON VIEW app_tour_skip_analysis IS 'Analysis of where and why users skip the app tour';

COMMENT ON FUNCTION start_app_tour IS 'Creates a new app tour session, supports upsert for session resumption';
COMMENT ON FUNCTION record_tour_step IS 'Records a step event within a tour session';
COMMENT ON FUNCTION complete_app_tour IS 'Marks a tour session as completed';
COMMENT ON FUNCTION skip_app_tour IS 'Marks a tour session as skipped with optional reason';
COMMENT ON FUNCTION claim_tour_session IS 'Associates an anonymous tour session with a user after signup';
COMMENT ON FUNCTION get_user_tour_stats IS 'Returns tour completion statistics for a specific user';
