-- Migration 1962: Add real consent toggles to user_ai_settings
--
-- Context: Prior app versions shipped two "consent" toggles that were not
-- enforced server-side (placebo controls):
--   1. SharedPreferences 'ai_data_processing_enabled' on device (never read)
--   2. user_ai_settings.save_chat_history (stored but never checked)
--
-- This migration adds the missing server-side column and keeps both toggles
-- explicit so that chat/vision endpoints can refuse to process data when the
-- user withholds consent. Toggling off must stop outbound Gemini traffic —
-- not just hide the UI — to satisfy GDPR Art. 7(4).

-- Add the data-processing consent column. Default TRUE so existing users
-- keep current behavior; onboarding flow explicitly captures consent.
ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS ai_data_processing_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Add a dedicated column for special-category (GDPR Art. 9) health data
-- consent. This is separate from general AI processing because health data
-- (menstrual cycle, sleep, heart rate, weight) requires explicit consent
-- that cannot be bundled with general ToS acceptance.
ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS health_data_consent BOOLEAN NOT NULL DEFAULT FALSE;

-- Record when each consent was granted so we can prove opt-in timing for
-- audit/DSAR responses. NULL until the user explicitly accepts.
ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS ai_data_processing_consented_at TIMESTAMPTZ;

ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS health_data_consented_at TIMESTAMPTZ;

COMMENT ON COLUMN public.user_ai_settings.ai_data_processing_enabled IS
    'Master kill-switch. When FALSE, backend MUST refuse to forward user chats, photos, or videos to Gemini (enforced in chat.py and vision_service.py).';

COMMENT ON COLUMN public.user_ai_settings.health_data_consent IS
    'GDPR Art. 9 explicit consent for special-category health data processing (weight, heart rate, sleep, menstrual cycle, hormonal). Required before syncing HealthKit/Health Connect.';
