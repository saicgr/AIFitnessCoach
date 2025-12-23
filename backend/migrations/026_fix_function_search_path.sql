-- Migration: 026_fix_function_search_path.sql
-- Description: Fix function search_path security warnings
-- Date: 2025-12-23
--
-- This migration fixes security lint errors from Supabase:
-- Functions should have an immutable search_path to prevent SQL injection attacks

-- ============================================
-- 1. Fix save_user_ai_settings function
-- ============================================
CREATE OR REPLACE FUNCTION public.save_user_ai_settings(
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
) RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_settings_id UUID;
    v_old_settings RECORD;
BEGIN
    -- Get current settings for history tracking
    SELECT * INTO v_old_settings FROM public.user_ai_settings WHERE user_id = p_user_id;

    -- Insert or update settings
    INSERT INTO public.user_ai_settings (
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
        coaching_style = COALESCE(p_coaching_style, public.user_ai_settings.coaching_style),
        communication_tone = COALESCE(p_communication_tone, public.user_ai_settings.communication_tone),
        encouragement_level = COALESCE(p_encouragement_level, public.user_ai_settings.encouragement_level),
        response_length = COALESCE(p_response_length, public.user_ai_settings.response_length),
        use_emojis = COALESCE(p_use_emojis, public.user_ai_settings.use_emojis),
        include_tips = COALESCE(p_include_tips, public.user_ai_settings.include_tips),
        form_reminders = COALESCE(p_form_reminders, public.user_ai_settings.form_reminders),
        rest_day_suggestions = COALESCE(p_rest_day_suggestions, public.user_ai_settings.rest_day_suggestions),
        nutrition_mentions = COALESCE(p_nutrition_mentions, public.user_ai_settings.nutrition_mentions),
        injury_sensitivity = COALESCE(p_injury_sensitivity, public.user_ai_settings.injury_sensitivity),
        save_chat_history = COALESCE(p_save_chat_history, public.user_ai_settings.save_chat_history),
        use_rag = COALESCE(p_use_rag, public.user_ai_settings.use_rag),
        default_agent = COALESCE(p_default_agent, public.user_ai_settings.default_agent),
        enabled_agents = COALESCE(p_enabled_agents, public.user_ai_settings.enabled_agents),
        updated_at = NOW()
    RETURNING id INTO v_settings_id;

    -- Track changes in history
    IF v_old_settings IS NOT NULL THEN
        -- Coaching style change
        IF p_coaching_style IS NOT NULL AND p_coaching_style != v_old_settings.coaching_style THEN
            INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'coaching_style', v_old_settings.coaching_style, p_coaching_style, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Communication tone change
        IF p_communication_tone IS NOT NULL AND p_communication_tone != v_old_settings.communication_tone THEN
            INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'communication_tone', v_old_settings.communication_tone, p_communication_tone, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Encouragement level change
        IF p_encouragement_level IS NOT NULL AND p_encouragement_level != v_old_settings.encouragement_level THEN
            INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'encouragement_level', v_old_settings.encouragement_level::TEXT, p_encouragement_level::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Response length change
        IF p_response_length IS NOT NULL AND p_response_length != v_old_settings.response_length THEN
            INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'response_length', v_old_settings.response_length, p_response_length, p_change_source, p_device_platform, p_app_version);
        END IF;

        -- Boolean toggles
        IF p_use_emojis IS NOT NULL AND p_use_emojis != v_old_settings.use_emojis THEN
            INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'use_emojis', v_old_settings.use_emojis::TEXT, p_use_emojis::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;

        IF p_include_tips IS NOT NULL AND p_include_tips != v_old_settings.include_tips THEN
            INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
            VALUES (p_user_id, 'include_tips', v_old_settings.include_tips::TEXT, p_include_tips::TEXT, p_change_source, p_device_platform, p_app_version);
        END IF;
    ELSE
        -- First time setup - record initial values
        INSERT INTO public.ai_settings_history (user_id, setting_name, old_value, new_value, change_source, device_platform, app_version)
        VALUES
            (p_user_id, 'coaching_style', NULL, COALESCE(p_coaching_style, 'motivational'), p_change_source, p_device_platform, p_app_version),
            (p_user_id, 'communication_tone', NULL, COALESCE(p_communication_tone, 'encouraging'), p_change_source, p_device_platform, p_app_version);
    END IF;

    RETURN v_settings_id;
END;
$$;

-- ============================================
-- 2. Fix record_chat_interaction function
-- ============================================
CREATE OR REPLACE FUNCTION public.record_chat_interaction(
    p_user_id UUID,
    p_message_id UUID DEFAULT NULL,
    p_user_message_length INTEGER DEFAULT NULL,
    p_ai_response_length INTEGER DEFAULT NULL,
    p_agent_type VARCHAR(20) DEFAULT NULL,
    p_intent VARCHAR(50) DEFAULT NULL,
    p_rag_context_used BOOLEAN DEFAULT false,
    p_tools_called JSONB DEFAULT NULL,
    p_response_time_ms INTEGER DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_analytics_id UUID;
    v_settings RECORD;
BEGIN
    -- Get current AI settings for this user
    SELECT coaching_style, communication_tone, encouragement_level, response_length, use_emojis
    INTO v_settings
    FROM public.user_ai_settings
    WHERE user_id = p_user_id;

    -- Insert analytics record with settings snapshot
    INSERT INTO public.chat_interaction_analytics (
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
$$;

-- ============================================
-- 3. Fix update_updated_at_column function
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================
-- 4. Fix update_subscription_updated_at function
-- ============================================
CREATE OR REPLACE FUNCTION public.update_subscription_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================
-- 5. Fix update_daily_activity_updated_at function
-- ============================================
CREATE OR REPLACE FUNCTION public.update_daily_activity_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================
-- 6. Fix create_default_subscription function
-- ============================================
CREATE OR REPLACE FUNCTION public.create_default_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.user_subscriptions (user_id, tier, status)
    VALUES (NEW.id, 'free', 'active')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- ============================================
-- 7. Fix update_daily_stats_on_screen_view function
-- ============================================
CREATE OR REPLACE FUNCTION public.update_daily_stats_on_screen_view()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.daily_user_stats (
        user_id,
        stat_date,
        total_screen_views,
        unique_screens_viewed
    ) VALUES (
        NEW.user_id,
        DATE(NEW.viewed_at),
        1,
        1
    )
    ON CONFLICT (user_id, stat_date) DO UPDATE SET
        total_screen_views = public.daily_user_stats.total_screen_views + 1,
        unique_screens_viewed = (
            SELECT COUNT(DISTINCT screen_name)
            FROM public.user_events
            WHERE user_id = NEW.user_id
            AND DATE(created_at) = DATE(NEW.viewed_at)
            AND event_type = 'screen_view'
        ),
        updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================
-- 8. Fix update_session_duration function
-- ============================================
CREATE OR REPLACE FUNCTION public.update_session_duration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
        NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$;

-- ============================================
-- 9. Fix increment_feature_usage function
-- ============================================
CREATE OR REPLACE FUNCTION public.increment_feature_usage(
    p_user_id UUID,
    p_feature_name TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.user_events (
        user_id,
        event_type,
        event_name,
        event_data
    ) VALUES (
        p_user_id,
        'feature_usage',
        p_feature_name,
        jsonb_build_object('timestamp', NOW())
    );
END;
$$;

-- ============================================
-- 10. Fix record_workout_regeneration function
-- ============================================
CREATE OR REPLACE FUNCTION public.record_workout_regeneration(
    p_user_id UUID,
    p_original_workout_id UUID DEFAULT NULL,
    p_new_workout_id UUID DEFAULT NULL,
    p_selected_focus_area TEXT DEFAULT NULL,
    p_selected_difficulty TEXT DEFAULT NULL,
    p_selected_duration_minutes INTEGER DEFAULT NULL,
    p_selected_equipment JSONB DEFAULT '[]'::JSONB,
    p_custom_focus_area TEXT DEFAULT NULL,
    p_custom_injury TEXT DEFAULT NULL,
    p_used_rag BOOLEAN DEFAULT false,
    p_generation_time_ms INTEGER DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_regeneration_id UUID;
BEGIN
    INSERT INTO public.workout_regenerations (
        user_id,
        original_workout_id,
        new_workout_id,
        selected_focus_area,
        selected_difficulty,
        selected_duration_minutes,
        selected_equipment,
        custom_focus_area,
        custom_injury,
        used_rag,
        generation_time_ms
    ) VALUES (
        p_user_id,
        p_original_workout_id,
        p_new_workout_id,
        p_selected_focus_area,
        p_selected_difficulty,
        p_selected_duration_minutes,
        p_selected_equipment,
        p_custom_focus_area,
        p_custom_injury,
        p_used_rag,
        p_generation_time_ms
    )
    RETURNING id INTO v_regeneration_id;

    RETURN v_regeneration_id;
END;
$$;
