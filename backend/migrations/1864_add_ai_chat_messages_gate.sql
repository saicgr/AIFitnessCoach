-- Add ai_chat_messages feature gate for daily message limits
INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, reset_period, is_enabled)
VALUES ('ai_chat_messages', 'AI Coach Messages', 'free', 20, 'daily', true)
ON CONFLICT (feature_key) DO UPDATE SET free_limit = EXCLUDED.free_limit;
