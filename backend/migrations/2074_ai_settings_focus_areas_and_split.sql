-- 2074_ai_settings_focus_areas_and_split.sql
--
-- Adds user-defined AI focus points (up to 5, each with a 1–5 priority)
-- and the user's preferred training split to `user_ai_settings`.
--
-- Wired into the Gemini workout-generation prompt:
--   • focus_areas → sorted by priority desc, injected verbatim so the
--     model can bias exercise selection + load prescription.
--   • training_split → biases day-to-day muscle distribution; null/auto
--     means the model picks based on goals + history.
--
-- Migration is idempotent + safe to run on existing rows (defaults to
-- empty list and NULL respectively).

BEGIN;

ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS focus_areas jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS training_split text;

-- Optional: lightweight CHECK to keep junk strings out of the column.
-- Mirrors ALLOWED_TRAINING_SPLITS in backend/api/v1/ai_settings.py minus
-- "auto" (we store null for auto, never the literal string).
ALTER TABLE public.user_ai_settings
    DROP CONSTRAINT IF EXISTS user_ai_settings_training_split_chk;
ALTER TABLE public.user_ai_settings
    ADD CONSTRAINT user_ai_settings_training_split_chk CHECK (
        training_split IS NULL
        OR training_split IN (
            'full_body',
            'upper_lower',
            'push_pull_legs',
            'bro_split',
            'arnold_split',
            'custom'
        )
    );

COMMIT;
