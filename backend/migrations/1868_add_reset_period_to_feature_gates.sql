-- Add reset_period column to feature_gates table
-- Used by the /feature-limits endpoint to compute daily vs monthly usage resets
ALTER TABLE feature_gates ADD COLUMN IF NOT EXISTS reset_period VARCHAR;

-- Set reset_period for existing gates that the feature-limits endpoint queries
UPDATE feature_gates SET reset_period = 'monthly' WHERE feature_key IN (
    'ai_workout_generation',
    'food_scanning',
    'form_video_analysis',
    'text_to_calories',
    'ai_meal_plan'
) AND reset_period IS NULL;

UPDATE feature_gates SET reset_period = 'daily' WHERE feature_key = 'ai_chat_messages' AND reset_period IS NULL;

-- Ensure all feature keys referenced by _PREMIUM_FEATURE_KEYS exist
INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled)
VALUES ('ai_chat_messages', 'AI Coach Messages', 'free', 20, 'daily', true)
ON CONFLICT (feature_key) DO UPDATE SET free_limit = EXCLUDED.free_limit, reset_period = EXCLUDED.reset_period;

INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled)
VALUES ('ai_meal_plan', 'AI Meal Plan Generation', 'free', 3, 'monthly', true)
ON CONFLICT (feature_key) DO UPDATE SET free_limit = EXCLUDED.free_limit, reset_period = EXCLUDED.reset_period;

INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled)
VALUES ('form_video_analysis', 'Exercise Form Video Analysis', 'free', 5, 'monthly', true)
ON CONFLICT (feature_key) DO NOTHING;

INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled)
VALUES ('text_to_calories', 'Text to Calories', 'free', 10, 'monthly', true)
ON CONFLICT (feature_key) DO NOTHING;
