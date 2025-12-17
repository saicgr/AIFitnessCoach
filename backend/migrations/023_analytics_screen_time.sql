-- AI Fitness Coach - Analytics & Screen Time Tracking
-- Migration 023: User analytics and screen time tracking

-- Session tracking (app sessions)
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    anonymous_id VARCHAR, -- For tracking before login

    -- Session info
    session_id VARCHAR UNIQUE NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,

    -- Device info
    device_type VARCHAR, -- 'ios', 'android'
    device_model VARCHAR,
    os_version VARCHAR,
    app_version VARCHAR,
    app_build VARCHAR,

    -- Session metadata
    entry_point VARCHAR, -- 'launch', 'push_notification', 'deep_link'
    referrer VARCHAR,

    -- Location (optional, coarse)
    country VARCHAR(2),
    timezone VARCHAR,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session ON user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_started ON user_sessions(started_at);

-- Screen views (individual screen tracking)
CREATE TABLE IF NOT EXISTS screen_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR REFERENCES user_sessions(session_id) ON DELETE CASCADE,

    -- Screen info
    screen_name VARCHAR NOT NULL, -- 'home', 'workout_detail', 'chat', etc.
    screen_class VARCHAR, -- Flutter class name
    previous_screen VARCHAR,

    -- Time tracking
    entered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    exited_at TIMESTAMPTZ,
    duration_ms INTEGER,

    -- Interaction data
    scroll_depth_percent INTEGER, -- 0-100
    interactions_count INTEGER DEFAULT 0, -- taps, swipes

    -- Context
    extra_params JSONB DEFAULT '{}', -- workout_id, exercise_id, etc.

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_screen_views_user ON screen_views(user_id);
CREATE INDEX IF NOT EXISTS idx_screen_views_session ON screen_views(session_id);
CREATE INDEX IF NOT EXISTS idx_screen_views_screen ON screen_views(screen_name);
CREATE INDEX IF NOT EXISTS idx_screen_views_entered ON screen_views(entered_at);

-- User events (general event tracking)
CREATE TABLE IF NOT EXISTS user_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR,
    anonymous_id VARCHAR,

    -- Event info
    event_name VARCHAR NOT NULL,
    event_category VARCHAR, -- 'engagement', 'conversion', 'error', 'feature'

    -- Event data
    properties JSONB DEFAULT '{}',

    -- Context
    screen_name VARCHAR,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Device
    device_type VARCHAR,
    app_version VARCHAR,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_events_user ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_name ON user_events(event_name);
CREATE INDEX IF NOT EXISTS idx_user_events_category ON user_events(event_category);
CREATE INDEX IF NOT EXISTS idx_user_events_timestamp ON user_events(timestamp);

-- Funnel tracking (specific funnel steps)
CREATE TABLE IF NOT EXISTS funnel_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR,
    anonymous_id VARCHAR,

    -- Funnel info
    funnel_name VARCHAR NOT NULL, -- 'onboarding', 'paywall', 'workout_completion'
    step_name VARCHAR NOT NULL, -- 'started', 'step_1', 'completed', etc.
    step_number INTEGER,

    -- Timing
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    time_since_funnel_start_ms INTEGER, -- time since first step

    -- Outcome
    completed BOOLEAN DEFAULT FALSE,
    dropped_off BOOLEAN DEFAULT FALSE,
    drop_off_reason VARCHAR,

    -- Context
    properties JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_funnel_events_user ON funnel_events(user_id);
CREATE INDEX IF NOT EXISTS idx_funnel_events_funnel ON funnel_events(funnel_name);
CREATE INDEX IF NOT EXISTS idx_funnel_events_step ON funnel_events(step_name);
CREATE INDEX IF NOT EXISTS idx_funnel_events_timestamp ON funnel_events(timestamp);

-- Daily user summary (aggregated daily stats)
CREATE TABLE IF NOT EXISTS daily_user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Session stats
    sessions_count INTEGER DEFAULT 0,
    total_session_time_seconds INTEGER DEFAULT 0,
    avg_session_time_seconds INTEGER DEFAULT 0,

    -- Screen time by category
    home_time_seconds INTEGER DEFAULT 0,
    workout_time_seconds INTEGER DEFAULT 0,
    chat_time_seconds INTEGER DEFAULT 0,
    nutrition_time_seconds INTEGER DEFAULT 0,
    profile_time_seconds INTEGER DEFAULT 0,
    other_time_seconds INTEGER DEFAULT 0,

    -- Engagement metrics
    screens_viewed INTEGER DEFAULT 0,
    events_count INTEGER DEFAULT 0,
    ai_messages_sent INTEGER DEFAULT 0,
    workouts_started INTEGER DEFAULT 0,
    workouts_completed INTEGER DEFAULT 0,

    -- Conversion
    paywall_views INTEGER DEFAULT 0,
    purchase_attempts INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_user_date UNIQUE (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_stats_user ON daily_user_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_stats_date ON daily_user_stats(date);

-- Onboarding analytics (detailed onboarding tracking)
CREATE TABLE IF NOT EXISTS onboarding_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR,
    anonymous_id VARCHAR,

    -- Funnel step
    step_name VARCHAR NOT NULL, -- 'language_select', 'welcome', 'name_age', 'goals', etc.
    step_number INTEGER,

    -- Timing
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_ms INTEGER,

    -- Interaction
    ai_messages_received INTEGER DEFAULT 0, -- for conversational onboarding
    user_messages_sent INTEGER DEFAULT 0,
    options_selected JSONB DEFAULT '[]',

    -- Outcome
    completed BOOLEAN DEFAULT FALSE,
    skipped BOOLEAN DEFAULT FALSE,
    error VARCHAR,

    -- A/B testing
    experiment_id VARCHAR,
    variant VARCHAR,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_onboarding_user ON onboarding_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_step ON onboarding_analytics(step_name);
CREATE INDEX IF NOT EXISTS idx_onboarding_started ON onboarding_analytics(started_at);

-- Error tracking
CREATE TABLE IF NOT EXISTS app_errors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR,

    -- Error info
    error_type VARCHAR NOT NULL, -- 'crash', 'api_error', 'ui_error', 'network'
    error_message TEXT,
    error_code VARCHAR,
    stack_trace TEXT,

    -- Context
    screen_name VARCHAR,
    action VARCHAR, -- what user was doing

    -- Device
    device_type VARCHAR,
    os_version VARCHAR,
    app_version VARCHAR,

    -- Metadata
    extra_data JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_errors_user ON app_errors(user_id);
CREATE INDEX IF NOT EXISTS idx_app_errors_type ON app_errors(error_type);
CREATE INDEX IF NOT EXISTS idx_app_errors_created ON app_errors(created_at);

-- Enable RLS
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE screen_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE funnel_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_errors ENABLE ROW LEVEL SECURITY;

-- RLS Policies - Users can read their own data
CREATE POLICY "Users can read own sessions" ON user_sessions
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can read own screen views" ON screen_views
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can read own events" ON user_events
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can read own funnel events" ON funnel_events
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can read own daily stats" ON daily_user_stats
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can read own onboarding analytics" ON onboarding_analytics
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can read own errors" ON app_errors
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Insert policies (allow users to insert their own analytics)
CREATE POLICY "Users can insert own sessions" ON user_sessions
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

CREATE POLICY "Users can insert own screen views" ON screen_views
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

CREATE POLICY "Users can insert own events" ON user_events
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

CREATE POLICY "Users can insert own funnel events" ON funnel_events
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

CREATE POLICY "Users can insert own onboarding analytics" ON onboarding_analytics
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

CREATE POLICY "Users can insert own errors" ON app_errors
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

-- Service role full access (for backend processing)
CREATE POLICY "Service role full access sessions" ON user_sessions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access screen views" ON screen_views
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access events" ON user_events
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access funnel" ON funnel_events
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access daily stats" ON daily_user_stats
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access onboarding" ON onboarding_analytics
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access errors" ON app_errors
    FOR ALL USING (auth.role() = 'service_role');

-- Function to update daily stats on new screen view
CREATE OR REPLACE FUNCTION update_daily_stats_on_screen_view()
RETURNS TRIGGER AS $$
DECLARE
    view_date DATE;
    duration_sec INTEGER;
    screen_category VARCHAR;
BEGIN
    -- Only update if we have duration and user_id
    IF NEW.duration_ms IS NULL OR NEW.user_id IS NULL THEN
        RETURN NEW;
    END IF;

    view_date := DATE(NEW.entered_at);
    duration_sec := NEW.duration_ms / 1000;

    -- Categorize screen
    screen_category := CASE
        WHEN NEW.screen_name IN ('home', 'senior_home') THEN 'home'
        WHEN NEW.screen_name LIKE '%workout%' OR NEW.screen_name LIKE '%exercise%' THEN 'workout'
        WHEN NEW.screen_name LIKE '%chat%' THEN 'chat'
        WHEN NEW.screen_name LIKE '%nutrition%' OR NEW.screen_name LIKE '%food%' THEN 'nutrition'
        WHEN NEW.screen_name LIKE '%profile%' OR NEW.screen_name LIKE '%settings%' THEN 'profile'
        ELSE 'other'
    END;

    -- Upsert daily stats
    INSERT INTO daily_user_stats (user_id, date, screens_viewed)
    VALUES (NEW.user_id, view_date, 1)
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        screens_viewed = daily_user_stats.screens_viewed + 1,
        home_time_seconds = CASE WHEN screen_category = 'home' THEN daily_user_stats.home_time_seconds + duration_sec ELSE daily_user_stats.home_time_seconds END,
        workout_time_seconds = CASE WHEN screen_category = 'workout' THEN daily_user_stats.workout_time_seconds + duration_sec ELSE daily_user_stats.workout_time_seconds END,
        chat_time_seconds = CASE WHEN screen_category = 'chat' THEN daily_user_stats.chat_time_seconds + duration_sec ELSE daily_user_stats.chat_time_seconds END,
        nutrition_time_seconds = CASE WHEN screen_category = 'nutrition' THEN daily_user_stats.nutrition_time_seconds + duration_sec ELSE daily_user_stats.nutrition_time_seconds END,
        profile_time_seconds = CASE WHEN screen_category = 'profile' THEN daily_user_stats.profile_time_seconds + duration_sec ELSE daily_user_stats.profile_time_seconds END,
        other_time_seconds = CASE WHEN screen_category = 'other' THEN daily_user_stats.other_time_seconds + duration_sec ELSE daily_user_stats.other_time_seconds END,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating daily stats
CREATE TRIGGER update_daily_stats_trigger
    AFTER UPDATE OF duration_ms ON screen_views
    FOR EACH ROW
    WHEN (NEW.duration_ms IS NOT NULL AND OLD.duration_ms IS NULL)
    EXECUTE FUNCTION update_daily_stats_on_screen_view();

-- Function to update session duration
CREATE OR REPLACE FUNCTION update_session_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
        NEW.duration_seconds := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_duration_trigger
    BEFORE UPDATE ON user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_session_duration();

-- Function to increment feature usage (used by subscription tracking)
CREATE OR REPLACE FUNCTION increment_feature_usage(
    p_user_id UUID,
    p_feature_key VARCHAR,
    p_usage_date DATE,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS void AS $$
BEGIN
    INSERT INTO feature_usage (user_id, feature_key, usage_date, usage_count, metadata)
    VALUES (p_user_id, p_feature_key, p_usage_date, 1, p_metadata)
    ON CONFLICT (user_id, feature_key, usage_date)
    DO UPDATE SET
        usage_count = feature_usage.usage_count + 1,
        metadata = p_metadata;
END;
$$ LANGUAGE plpgsql;
