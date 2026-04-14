-- 1923_user_nutrition_prefs_checkin_flags.sql
-- Add flags that drive post-meal check-in UX + passive mood inference.
-- Lives on user_nutrition_preferences (runtime prefs), NOT nutrition_preferences
-- (which holds onboarding + goal metadata).

ALTER TABLE public.user_nutrition_preferences
  ADD COLUMN IF NOT EXISTS post_meal_checkin_disabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS post_meal_reminder_enabled boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS passive_inference_enabled boolean DEFAULT true;

COMMENT ON COLUMN public.user_nutrition_preferences.post_meal_checkin_disabled IS
  'User hit Don''t show again on the post-meal check-in sheet. Re-enable from Nutrition > Patterns tab.';
COMMENT ON COLUMN public.user_nutrition_preferences.post_meal_reminder_enabled IS
  'Controls the 45-min local notification fired when a meal was logged without mood_after.';
COMMENT ON COLUMN public.user_nutrition_preferences.passive_inference_enabled IS
  'When false, skip the rules_v1 inference engine at food-log write time and hide inferred rows from Patterns UI.';
