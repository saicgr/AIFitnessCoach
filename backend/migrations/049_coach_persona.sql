-- Migration 049: Coach Persona Support
-- Adds coach persona fields to user_ai_settings for storing coach selection

-- =====================================================
-- 1. Add Coach Persona Columns
-- =====================================================
ALTER TABLE user_ai_settings
ADD COLUMN IF NOT EXISTS coach_persona_id VARCHAR(50) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS coach_name VARCHAR(100) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS is_custom_coach BOOLEAN DEFAULT false;

-- Add comments for documentation
COMMENT ON COLUMN user_ai_settings.coach_persona_id IS 'Selected coach persona ID (e.g., coach_mike, dr_sarah, sergeant_max, zen_maya, hype_danny, custom)';
COMMENT ON COLUMN user_ai_settings.coach_name IS 'Display name for the coach (predefined name or custom name set by user)';
COMMENT ON COLUMN user_ai_settings.is_custom_coach IS 'Whether the user is using a custom coach configuration instead of a predefined persona';

-- =====================================================
-- 2. Create Index for Coach Persona Lookups
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_user_ai_settings_coach_persona
ON user_ai_settings(coach_persona_id);

-- =====================================================
-- 3. Update the save_user_ai_settings function
-- =====================================================
CREATE OR REPLACE FUNCTION save_user_ai_settings(
    p_user_id UUID,
    p_coach_persona_id VARCHAR(50) DEFAULT NULL,
    p_coach_name VARCHAR(100) DEFAULT NULL,
    p_is_custom_coach BOOLEAN DEFAULT NULL,
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
        user_id, coach_persona_id, coach_name, is_custom_coach,
        coaching_style, communication_tone, encouragement_level,
        response_length, use_emojis, include_tips, form_reminders,
        rest_day_suggestions, nutrition_mentions, injury_sensitivity,
        save_chat_history, use_rag, default_agent, enabled_agents
    ) VALUES (
        p_user_id,
        p_coach_persona_id,
        p_coach_name,
        COALESCE(p_is_custom_coach, false),
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
        coach_persona_id = COALESCE(p_coach_persona_id, user_ai_settings.coach_persona_id),
        coach_name = COALESCE(p_coach_name, user_ai_settings.coach_name),
        is_custom_coach = COALESCE(p_is_custom_coach, user_ai_settings.is_custom_coach),
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
        -- Coach persona change
        IF p_coach_persona_id IS NOT NULL AND (v_old_settings.coach_persona_id IS NULL OR p_coach_persona_id != v_old_settings.coach_persona_id) THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'coach_persona_id', v_old_settings.coach_persona_id, p_coach_persona_id, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Coach name change
        IF p_coach_name IS NOT NULL AND (v_old_settings.coach_name IS NULL OR p_coach_name != v_old_settings.coach_name) THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'coach_name', v_old_settings.coach_name, p_coach_name, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Is custom coach change
        IF p_is_custom_coach IS NOT NULL AND p_is_custom_coach != COALESCE(v_old_settings.is_custom_coach, false) THEN
            INSERT INTO ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'is_custom_coach', COALESCE(v_old_settings.is_custom_coach, false)::TEXT, p_is_custom_coach::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;

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
            (p_user_id, 'coach_persona_id', NULL, p_coach_persona_id, p_change_source, p_device_platform, p_app_version),
            (p_user_id, 'coach_name', NULL, p_coach_name, p_change_source, p_device_platform, p_app_version),
            (p_user_id, 'coaching_style', NULL, COALESCE(p_coaching_style, 'motivational'), p_change_source, p_device_platform, p_app_version),
            (p_user_id, 'communication_tone', NULL, COALESCE(p_communication_tone, 'encouraging'), p_change_source, p_device_platform, p_app_version);
    END IF;

    RETURN v_settings_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =====================================================
-- 4. Analytics: Coach Persona Popularity View
-- =====================================================
CREATE OR REPLACE VIEW coach_persona_popularity AS
SELECT
    coach_persona_id,
    coach_name,
    is_custom_coach,
    COUNT(*) as user_count,
    COUNT(CASE WHEN is_custom_coach THEN 1 END) as custom_count
FROM user_ai_settings
WHERE coach_persona_id IS NOT NULL
GROUP BY coach_persona_id, coach_name, is_custom_coach
ORDER BY user_count DESC;

COMMENT ON VIEW coach_persona_popularity IS 'Shows most popular coach personas selected by users';
