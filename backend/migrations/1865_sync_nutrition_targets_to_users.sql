-- Backfill: sync nutrition targets from nutrition_preferences to users table
-- This ensures both tables have consistent values going forward.
-- nutrition_preferences is the source of truth (set by onboarding/recalculate).

UPDATE users u SET
    daily_calorie_target = COALESCE(np.target_calories, u.daily_calorie_target),
    daily_protein_target_g = COALESCE(np.target_protein_g, u.daily_protein_target_g),
    daily_carbs_target_g = COALESCE(np.target_carbs_g, u.daily_carbs_target_g),
    daily_fat_target_g = COALESCE(np.target_fat_g, u.daily_fat_target_g)
FROM nutrition_preferences np
WHERE np.user_id = u.id
  AND np.target_calories IS NOT NULL;
