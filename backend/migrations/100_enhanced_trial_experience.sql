-- Migration: 096_enhanced_trial_experience
-- Description: Enhanced Trial and Demo Experience
-- Addresses complaint: "requires subscription to see personal plan"
-- Builds on 090_trial_demo_tracking.sql with additional conversion tracking

-- ============================================================================
-- PLAN PREVIEWS TABLE
-- Track plan previews before signup
-- ============================================================================
CREATE TABLE IF NOT EXISTS plan_previews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT,  -- For anonymous users
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- For logged-in users
    quiz_data JSONB NOT NULL,
    generated_plan JSONB NOT NULL,  -- The full 4-week plan shown
    preview_type TEXT DEFAULT 'full_plan',  -- full_plan, single_workout, exercise_list
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    converted_to_trial BOOLEAN DEFAULT FALSE,
    converted_to_paid BOOLEAN DEFAULT FALSE,
    conversion_date TIMESTAMPTZ,
    device_info JSONB
);

-- ============================================================================
-- TRY WORKOUT SESSIONS TABLE
-- Track "Try One Workout" feature usage
-- ============================================================================
CREATE TABLE IF NOT EXISTS try_workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_data JSONB NOT NULL,  -- The workout they tried
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    completion_percentage INTEGER,  -- 0-100
    exercises_completed INTEGER DEFAULT 0,
    converted_after BOOLEAN DEFAULT FALSE,
    feedback TEXT
);

-- ============================================================================
-- EXTEND TRIAL ELIGIBILITY TO ALL PLANS
-- Add columns to user_subscriptions for trial tracking
-- ============================================================================
DO $$
BEGIN
    -- Add trial_available_monthly column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_subscriptions' AND column_name = 'trial_available_monthly'
    ) THEN
        ALTER TABLE user_subscriptions ADD COLUMN trial_available_monthly BOOLEAN DEFAULT TRUE;
    END IF;

    -- Add trial_available_yearly column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_subscriptions' AND column_name = 'trial_available_yearly'
    ) THEN
        ALTER TABLE user_subscriptions ADD COLUMN trial_available_yearly BOOLEAN DEFAULT TRUE;
    END IF;

    -- Add trial_type_used column if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'user_subscriptions' AND column_name = 'trial_type_used'
    ) THEN
        ALTER TABLE user_subscriptions ADD COLUMN trial_type_used TEXT;  -- Which trial type they used
    END IF;
END $$;

-- ============================================================================
-- CONVERSION TRIGGERS TABLE
-- Track what convinced user to convert
-- ============================================================================
CREATE TABLE IF NOT EXISTS conversion_triggers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    trigger_type TEXT NOT NULL,  -- 'plan_preview', 'try_workout', 'demo_day', 'feature_tap'
    trigger_details JSONB,
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    resulted_in TEXT  -- 'trial', 'purchase', 'nothing'
);

-- ============================================================================
-- ANALYTICS VIEW FOR CONVERSION FUNNEL
-- ============================================================================
CREATE OR REPLACE VIEW trial_conversion_funnel AS
SELECT
    DATE(pp.viewed_at) as date,
    COUNT(DISTINCT pp.session_id) as plan_previews,
    COUNT(DISTINCT CASE WHEN pp.converted_to_trial THEN pp.session_id END) as preview_to_trial,
    COUNT(DISTINCT CASE WHEN pp.converted_to_paid THEN pp.session_id END) as preview_to_paid,
    COUNT(DISTINCT tws.session_id) as try_workout_sessions,
    COUNT(DISTINCT CASE WHEN tws.converted_after THEN tws.session_id END) as try_workout_conversions
FROM plan_previews pp
LEFT JOIN try_workout_sessions tws ON pp.session_id = tws.session_id
GROUP BY DATE(pp.viewed_at)
ORDER BY date DESC;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_plan_previews_session ON plan_previews(session_id);
CREATE INDEX IF NOT EXISTS idx_plan_previews_user ON plan_previews(user_id);
CREATE INDEX IF NOT EXISTS idx_plan_previews_viewed_at ON plan_previews(viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_plan_previews_converted ON plan_previews(converted_to_trial, converted_to_paid);

CREATE INDEX IF NOT EXISTS idx_try_workout_session ON try_workout_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_try_workout_user ON try_workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_try_workout_started ON try_workout_sessions(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_try_workout_converted ON try_workout_sessions(converted_after) WHERE converted_after = TRUE;

CREATE INDEX IF NOT EXISTS idx_conversion_triggers_user ON conversion_triggers(user_id);
CREATE INDEX IF NOT EXISTS idx_conversion_triggers_type ON conversion_triggers(trigger_type);
CREATE INDEX IF NOT EXISTS idx_conversion_triggers_occurred ON conversion_triggers(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversion_triggers_result ON conversion_triggers(resulted_in);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE plan_previews ENABLE ROW LEVEL SECURITY;
ALTER TABLE try_workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversion_triggers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS plan_previews_user_policy ON plan_previews;
DROP POLICY IF EXISTS plan_previews_insert_policy ON plan_previews;
DROP POLICY IF EXISTS plan_previews_service_policy ON plan_previews;
DROP POLICY IF EXISTS try_workout_user_policy ON try_workout_sessions;
DROP POLICY IF EXISTS try_workout_insert_policy ON try_workout_sessions;
DROP POLICY IF EXISTS try_workout_service_policy ON try_workout_sessions;
DROP POLICY IF EXISTS conversion_triggers_user_policy ON conversion_triggers;
DROP POLICY IF EXISTS conversion_triggers_insert_policy ON conversion_triggers;
DROP POLICY IF EXISTS conversion_triggers_service_policy ON conversion_triggers;

-- Plan Previews policies
-- Users can see their own data (or anonymous data with null user_id)
CREATE POLICY plan_previews_user_policy ON plan_previews
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

-- Anyone can insert (for anonymous users)
CREATE POLICY plan_previews_insert_policy ON plan_previews
    FOR INSERT WITH CHECK (true);

-- Users can update their own records
CREATE POLICY plan_previews_update_policy ON plan_previews
    FOR UPDATE USING (auth.uid() = user_id OR user_id IS NULL);

-- Service role has full access
CREATE POLICY plan_previews_service_policy ON plan_previews
    FOR ALL USING (auth.role() = 'service_role');

-- Try Workout Sessions policies
-- Users can see their own data (or anonymous data with null user_id)
CREATE POLICY try_workout_user_policy ON try_workout_sessions
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

-- Anyone can insert (for anonymous users)
CREATE POLICY try_workout_insert_policy ON try_workout_sessions
    FOR INSERT WITH CHECK (true);

-- Users can update their own records
CREATE POLICY try_workout_update_policy ON try_workout_sessions
    FOR UPDATE USING (auth.uid() = user_id OR user_id IS NULL);

-- Service role has full access
CREATE POLICY try_workout_service_policy ON try_workout_sessions
    FOR ALL USING (auth.role() = 'service_role');

-- Conversion Triggers policies
-- Users can see their own conversion data
CREATE POLICY conversion_triggers_user_policy ON conversion_triggers
    FOR SELECT USING (auth.uid() = user_id);

-- Authenticated users can insert their own triggers
CREATE POLICY conversion_triggers_insert_policy ON conversion_triggers
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Service role has full access
CREATE POLICY conversion_triggers_service_policy ON conversion_triggers
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- ADDITIONAL ANALYTICS VIEWS
-- ============================================================================

-- Preview type breakdown
CREATE OR REPLACE VIEW plan_preview_analytics AS
SELECT
    DATE(viewed_at) as date,
    preview_type,
    COUNT(*) as total_previews,
    COUNT(CASE WHEN converted_to_trial THEN 1 END) as converted_to_trial,
    COUNT(CASE WHEN converted_to_paid THEN 1 END) as converted_to_paid,
    ROUND(
        COUNT(CASE WHEN converted_to_trial THEN 1 END)::numeric /
        NULLIF(COUNT(*)::numeric, 0) * 100,
        2
    ) as trial_conversion_rate,
    ROUND(
        COUNT(CASE WHEN converted_to_paid THEN 1 END)::numeric /
        NULLIF(COUNT(*)::numeric, 0) * 100,
        2
    ) as paid_conversion_rate
FROM plan_previews
WHERE viewed_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(viewed_at), preview_type
ORDER BY date DESC, preview_type;

-- Try workout completion rates
CREATE OR REPLACE VIEW try_workout_analytics AS
SELECT
    DATE(started_at) as date,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN completed_at IS NOT NULL THEN 1 END) as completed_sessions,
    ROUND(AVG(completion_percentage)::numeric, 1) as avg_completion_pct,
    ROUND(AVG(exercises_completed)::numeric, 1) as avg_exercises_completed,
    COUNT(CASE WHEN converted_after THEN 1 END) as conversions,
    ROUND(
        COUNT(CASE WHEN converted_after THEN 1 END)::numeric /
        NULLIF(COUNT(*)::numeric, 0) * 100,
        2
    ) as conversion_rate
FROM try_workout_sessions
WHERE started_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;

-- Conversion trigger effectiveness
CREATE OR REPLACE VIEW conversion_trigger_effectiveness AS
SELECT
    trigger_type,
    resulted_in,
    COUNT(*) as occurrences,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER (PARTITION BY trigger_type) * 100,
        2
    ) as percentage_of_trigger_type
FROM conversion_triggers
WHERE occurred_at >= NOW() - INTERVAL '30 days'
GROUP BY trigger_type, resulted_in
ORDER BY trigger_type, occurrences DESC;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE plan_previews IS 'Tracks when users preview their personalized workout plan before signing up or subscribing.';
COMMENT ON TABLE try_workout_sessions IS 'Tracks usage of the "Try One Workout" feature for conversion analysis.';
COMMENT ON TABLE conversion_triggers IS 'Tracks what features or actions lead to trial starts or purchases.';
COMMENT ON VIEW trial_conversion_funnel IS 'Daily funnel metrics showing plan preview to trial/purchase conversion rates.';
COMMENT ON VIEW plan_preview_analytics IS 'Breakdown of plan preview types and their conversion rates over the last 30 days.';
COMMENT ON VIEW try_workout_analytics IS 'Daily metrics for try workout sessions including completion and conversion rates.';
COMMENT ON VIEW conversion_trigger_effectiveness IS 'Analysis of which triggers are most effective at driving conversions.';
