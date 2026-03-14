-- Migration 268: Upsert AI feature gates with simplified limits
-- These gates control free-tier usage limits for premium AI features.
-- Premium/ultra users get unlimited access (NULL limits).

INSERT INTO feature_gates (feature_key, display_name, minimum_tier, free_limit, premium_limit, ultra_limit, is_enabled)
VALUES
  ('ai_workout_generation', 'AI Workout Generation', 'free', 2, NULL, NULL, true),
  ('food_scanning', 'Food Photo Scan', 'free', 1, NULL, NULL, true),
  ('form_video_analysis', 'Form Video Analysis', 'premium', 0, NULL, NULL, true),
  ('text_to_calories', 'Text to Calories', 'free', 3, NULL, NULL, true)
ON CONFLICT (feature_key) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  minimum_tier = EXCLUDED.minimum_tier,
  free_limit = EXCLUDED.free_limit,
  premium_limit = EXCLUDED.premium_limit,
  ultra_limit = EXCLUDED.ultra_limit,
  is_enabled = EXCLUDED.is_enabled;

-- Remove phantom gates for features that don't exist yet
DELETE FROM feature_gates WHERE feature_key IN ('ai_meal_plan', 'recipe_suggestions');
