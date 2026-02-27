-- Migration 268: Upsert 5 AI feature gates with simplified limits
-- These gates control free-tier usage limits for premium AI features.
-- Premium/premium_plus users get unlimited access (NULL limits).

INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, premium_limit, premium_plus_limit, reset_period, is_enabled)
VALUES
  ('ai_workout_generation', 'AI Workout Generation', 'free', 2, NULL, NULL, 'monthly', true),
  ('food_scanning', 'Food Photo Scan', 'free', 1, NULL, NULL, 'daily', true),
  ('form_video_analysis', 'Form Video Analysis', 'premium', 0, NULL, NULL, NULL, true),
  ('text_to_calories', 'Text to Calories', 'free', 3, NULL, NULL, 'daily', true),
  ('ai_meal_plan', 'AI Meal Plan Generation', 'premium', 0, NULL, NULL, NULL, true)
ON CONFLICT (feature_key) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  minimum_tier = EXCLUDED.minimum_tier,
  free_limit = EXCLUDED.free_limit,
  premium_limit = EXCLUDED.premium_limit,
  reset_period = EXCLUDED.reset_period,
  is_enabled = EXCLUDED.is_enabled;
