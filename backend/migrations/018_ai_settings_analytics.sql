-- Migration 018: AI Settings Storage and Analytics
-- Stores user AI preferences and tracks all setting changes for analytics

-- =====================================================
-- 1. User AI Settings Table (current preferences)
-- =====================================================
CREATE TABLE IF NOT EXISTS user_ai_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Coaching personality
    coaching_style VARCHAR(50) DEFAULT 'motivational',
    communication_tone VARCHAR(50) DEFAULT 'encouraging',
    encouragement_level DECIMAL(3,2) DEFAULT 0.70,
    response_length VARCHAR(20) DEFAULT 'balanced',

    -- Response formatting
    use_emojis BOOLEAN DEFAULT true,
    include_tips BOOLEAN DEFAULT true,

    -- Fitness coaching specifics
    form_reminders BOOLEAN DEFAULT true,
    rest_day_suggestions BOOLEAN DEFAULT true,
    nutrition_mentions BOOLEAN DEFAULT true,
    injury_sensitivity BOOLEAN DEFAULT true,

    -- Privacy & data
    save_chat_history BOOLEAN DEFAULT true,
    use_rag BOOLEAN DEFAULT true,

    -- Agent preferences
    default_agent VARCHAR(20) DEFAULT 'coach',
    enabled_agents JSONB DEFAULT '{"coach": true, "nutrition": true, "workout": true, "injury": true, "hydration": true}'::jsonb,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure one settings record per user
    UNIQUE(user_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_ai_settings_user_id ON user_ai_settings(user_id);

-- =====================================================
-- 2. AI Settings Change History (analytics)
-- =====================================================
CREATE TABLE IF NOT EXISTS ai_settings_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- What changed
    setting_name VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT NOT NULL,

    -- Context
    change_source VARCHAR(50) DEFAULT 'app', -- 'app', 'api', 'onboarding', 'ai_suggestion'
    session_id UUID, -- Optional: link to user session

    -- Timestamps
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Device/platform info for analytics
    device_platform VARCHAR(20), -- 'ios', 'android', 'web'
    app_version VARCHAR(20)
);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_ai_settings_history_user_id ON ai_settings_history(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_settings_history_changed_at ON ai_settings_history(changed_at);
CREATE INDEX IF NOT EXISTS idx_ai_settings_history_setting_name ON ai_settings_history(setting_name);

-- =====================================================
-- 3. Chat Interaction Analytics (enhanced)
-- =====================================================
CREATE TABLE IF NOT EXISTS chat_interaction_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Message info
    message_id UUID, -- Link to chat_history if exists
    user_message_length INTEGER,
    ai_response_length INTEGER,

    -- AI settings at time of interaction
    coaching_style VARCHAR(50),
    communication_tone VARCHAR(50),
    encouragement_level DECIMAL(3,2),
    response_length VARCHAR(20),
    use_emojis BOOLEAN,

    -- Agent info
    agent_type VARCHAR(20),
    intent VARCHAR(50),

    -- RAG & tools
    rag_context_used BOOLEAN DEFAULT false,
    tools_called JSONB, -- Array of tool names used

    -- Performance
    response_time_ms INTEGER,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_chat_analytics_user_id ON chat_interaction_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_analytics_created_at ON chat_interaction_analytics(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_analytics_agent_type ON chat_interaction_analytics(agent_type);
CREATE INDEX IF NOT EXISTS idx_chat_analytics_coaching_style ON chat_interaction_analytics(coaching_style);

-- =====================================================
-- 4. AI Settings Popularity Analytics (aggregate view)
-- =====================================================
CREATE OR REPLACE VIEW ai_settings_popularity AS
SELECT
    coaching_style,
    communication_tone,
    response_length,
    COUNT(*) as user_count,
    AVG(encouragement_level) as avg_encouragement,
    SUM(CASE WHEN use_emojis THEN 1 ELSE 0 END) as emoji_users,
    SUM(CASE WHEN include_tips THEN 1 ELSE 0 END) as tips_users
FROM user_ai_settings
GROUP BY coaching_style, communication_tone, response_length
ORDER BY user_count DESC;

-- =====================================================
-- 5. Setting Change Trends (daily aggregation view)
-- =====================================================
CREATE OR REPLACE VIEW ai_settings_change_trends AS
SELECT
    DATE(changed_at) as change_date,
    setting_name,
    new_value,
    COUNT(*) as change_count,
    COUNT(DISTINCT user_id) as unique_users
FROM ai_settings_history
WHERE changed_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(changed_at), setting_name, new_value
ORDER BY change_date DESC, change_count DESC;

-- =====================================================
-- 6. User Engagement by AI Style (view)
-- =====================================================
CREATE OR REPLACE VIEW user_engagement_by_ai_style AS
SELECT
    s.coaching_style,
    s.communication_tone,
    COUNT(DISTINCT s.user_id) as total_users,
    COUNT(c.id) as total_messages,
    AVG(c.ai_response_length) as avg_response_length,
    AVG(c.response_time_ms) as avg_response_time
FROM user_ai_settings s
LEFT JOIN chat_interaction_analytics c ON s.user_id = c.user_id
GROUP BY s.coaching_style, s.communication_tone
ORDER BY total_messages DESC;

-- =====================================================
-- 7. Helper Functions
-- =====================================================

-- Function to save or update user AI settings with history tracking
CREATE OR REPLACE FUNCTION save_user_ai_settings(
    p_user_id UUID,
    p_coaching_style VARCHAR(50) DEFAULT NULL,
    p_communication_tone VARCHAR(50) DEFAULT NULL,
    p_encouragement_level DECIMAL(3,2) DEFAULT NULL,
    p_response_length VARCHAR(20) DEFAULT NULL,
    p_use_emojis BOOLEAN DEFAULT NULL,
    p_include_tips BOOLEAN DEFAULT NULL,
    p_form_reminders BOOLEAN DEFAULT NULL,
    p_rest_day_suggestions BOOLEAN DEFAULT NULL,
    p_nutrition_mentions BOOLEAN DEFAULT NULL,
    p_injury_sensitivity BOOLEAN DEFAULT NULL,
    p_save_chat_history BOOLEAN DEFAULT NULL,
    p_use_rag BOOLEAN DEFAULT NULL,
    p_default_agent VARCHAR(20) DEFAULT NULL,
    p_enabled_agents JSONB DEFAULT NULL,
    p_change_source VARCHAR(50) DEFAULT 'app',
    p_device_platform VARCHAR(20) DEFAULT NULL,
    p_app_version VARCHAR(20) DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_settings_id UUID;
    v_old_settings RECORD;
BEGIN
    -- Get current settings for history tracking
    SELECT * INTO v_old_settings FROM user_ai_settings WHERE user_id = p_user_id;

    -- Insert or update settings
    INSERT INTO user_ai_settings (
        user_id, coaching_style, communication_tone, encouragement_level,
        response_length, use_emojis, include_tips, form_reminders,
        rest_day_suggestions, nutrition_mentions, injury_sensitivity,
        save_chat_history, use_rag, default_agent, enabled_agents
    ) VALUES (
        p_user_id,
        COALESCE(p_coaching_style, 'motivational'),
        COALESCE(p_communication_tone, 'encouraging'),
        COALESCE(p_encouragement_level, 0.70),
        COALESCE(p_response_length, 'balanced'),
        COALESCE(p_use_emojis, true),
        COALESCE(p_include_tips, true),
        COALESCE(p_form_reminders, true),
        COALESCE(p_rest_day_suggestions, true),
        COALESCE(p_nutrition_mentions, true),
        COALESCE(p_injury_sensitivity, true),
        COALESCE(p_save_chat_history, true),
        COALESCE(p_use_rag, true),
        COALESCE(p_default_agent, 'coach'),
        COALESCE(p_enabled_agents, '{"coach": true, "nutrition": true, "workout": true, "injury": true, "hydration": true}'::jsonb)
    )
    ON CONFLICT (user_id) DO UPDATE SET
        coaching_style = COALESCE(p_coaching_style, user_ai_settings.coaching_style),
        communication_tone = COALESCE(p_communication_tone, user_ai_settings.communication_tone),
        encouragement_level = COALESCE(p_encouragement_level, user_ai_settings.encouragement_level),
        response_length = COALESCE(p_response_length, user_ai_settings.response_length),
        use_emojis = COALESCE(p_use_emojis, user_ai_settings.use_emojis),
        include_tips = COALESCE(p_include_tips, user_ai_settings.include_tips),
        form_reminders = COALESCE(p_form_reminders, user_ai_settings.form_reminders),
        rest_day_suggestions = COALESCE(p_rest_day_suggestions, user_ai_settings.rest_day_suggestions),
        nutrition_mentions = COALESCE(p_nutrition_mentions, user_ai_settings.nutrition_mentions),
        injury_sensitivity = COALESCE(p_injury_sensitivity, user_ai_settings.injury_sensitivity),
        save_chat_history = COALESCE(p_save_chat_history, user_ai_settings.save_chat_history),
        use_rag = COALESCE(p_use_rag, user_ai_settings.use_rag),
        default_agent = COALESCE(p_default_agent, user_ai_settings.default_agent),
        enabled_agents = COALESCE(p_enabled_agents, user_ai_settings.enabled_agents),
        updated_at = NOW()
    RETURNING id INTO v_settings_id;

    -- Track changes in history
    IF v_old_settings IS NOT NULL THEN
        -- Coaching style change
        IF p_coaching_style IS NOT NULL AND p_coaching_style != v_old_settings.coaching_style THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'coaching_style', v_old_settings.coaching_style, p_coaching_style, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Communication tone change
        IF p_communication_tone IS NOT NULL AND p_communication_tone != v_old_settings.communication_tone THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'communication_tone', v_old_settings.communication_tone, p_communication_tone, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Encouragement level change
        IF p_encouragement_level IS NOT NULL AND p_encouragement_level != v_old_settings.encouragement_level THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'encouragement_level', v_old_settings.encouragement_level::TEXT, p_encouragement_level::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Response length change
        IF p_response_length IS NOT NULL AND p_response_length != v_old_settings.response_length THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'response_length', v_old_settings.response_length, p_response_length, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Boolean toggles
        IF p_use_emojis IS NOT NULL AND p_use_emojis != v_old_settings.use_emojis THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'use_emojis', v_old_settings.use_emojis::TEXT, p_use_emojis::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;

        IF p_include_tips IS NOT NULL AND p_include_tips != v_old_settings.include_tips THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'include_tips', v_old_settings.include_tips::TEXT, p_include_tips::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;
    ELSE
        -- First time setup - record initial values
        INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
        VALUES
            (p_user_id, 'coaching_style', NULL, COALESCE(p_coaching_style, 'motivational'), p_change_source, p_device_platform, p_app_version),
            (p_user_id, 'communication_tone', NULL, COALESCE(p_communication_tone, 'encouraging'), p_change_source, p_device_platform, p_app_version);
    END IF;

    RETURN v_settings_id;
END;
$$ LANGUAGE plpgsql;

-- Function to record chat interaction with AI settings snapshot
CREATE OR REPLACE FUNCTION record_chat_interaction(
    p_user_id UUID,
    p_message_id UUID DEFAULT NULL,
    p_user_message_length INTEGER DEFAULT NULL,
    p_ai_response_length INTEGER DEFAULT NULL,
    p_agent_type VARCHAR(20) DEFAULT NULL,
    p_intent VARCHAR(50) DEFAULT NULL,
    p_rag_context_used BOOLEAN DEFAULT false,
    p_tools_called JSONB DEFAULT NULL,
    p_response_time_ms INTEGER DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_analytics_id UUID;
    v_settings RECORD;
BEGIN
    -- Get current AI settings for this user
    SELECT coaching_style, communication_tone, encouragement_level, response_length, use_emojis
    INTO v_settings
    FROM user_ai_settings
    WHERE user_id = p_user_id;

    -- Insert analytics record with settings snapshot
    INSERT INTO chat_interaction_analytics (
        user_id, message_id, user_message_length, ai_response_length,
        coaching_style, communication_tone, encouragement_level, response_length, use_emojis,
        agent_type, intent, rag_context_used, tools_called, response_time_ms
    ) VALUES (
        p_user_id, p_message_id, p_user_message_length, p_ai_response_length,
        COALESCE(v_settings.coaching_style, 'motivational'),
        COALESCE(v_settings.communication_tone, 'encouraging'),
        COALESCE(v_settings.encouragement_level, 0.70),
        COALESCE(v_settings.response_length, 'balanced'),
        COALESCE(v_settings.use_emojis, true),
        p_agent_type, p_intent, p_rag_context_used, p_tools_called, p_response_time_ms
    )
    RETURNING id INTO v_analytics_id;

    RETURN v_analytics_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. Enable Row Level Security
-- =====================================================
ALTER TABLE user_ai_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_settings_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_interaction_analytics ENABLE ROW LEVEL SECURITY;

-- Users can only see/modify their own settings
CREATE POLICY user_ai_settings_policy ON user_ai_settings
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY ai_settings_history_policy ON ai_settings_history
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY chat_interaction_analytics_policy ON chat_interaction_analytics
    FOR ALL USING (auth.uid() = user_id);

-- Service role can access all (for analytics)
CREATE POLICY user_ai_settings_service ON user_ai_settings
    FOR ALL TO service_role USING (true);

CREATE POLICY ai_settings_history_service ON ai_settings_history
    FOR ALL TO service_role USING (true);

CREATE POLICY chat_interaction_analytics_service ON chat_interaction_analytics
    FOR ALL TO service_role USING (true);

-- =====================================================
-- 9. Helpful Comments
-- =====================================================
COMMENT ON TABLE user_ai_settings IS 'Stores user AI coach personality preferences';
COMMENT ON TABLE ai_settings_history IS 'Tracks all AI settings changes for analytics and A/B testing';
COMMENT ON TABLE chat_interaction_analytics IS 'Detailed analytics for each chat interaction including AI settings snapshot';
COMMENT ON VIEW ai_settings_popularity IS 'Shows most popular AI settings combinations';
COMMENT ON VIEW ai_settings_change_trends IS 'Daily trends of setting changes over last 30 days';
COMMENT ON VIEW user_engagement_by_ai_style IS 'User engagement metrics grouped by AI personality style';
