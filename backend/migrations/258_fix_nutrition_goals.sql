-- Migration 258: Fix nutrition_goal for users whose weight_direction contradicts their stored goal
--
-- Problem: During onboarding, nutrition_goals defaulted to ['maintain'] regardless of weight_direction.
-- This migration corrects existing users' nutrition_preferences to match their weight_direction.

UPDATE nutrition_preferences np
SET
  nutrition_goal = CASE
    WHEN u.preferences->>'weight_direction' = 'lose' THEN 'lose_fat'
    WHEN u.preferences->>'weight_direction' = 'gain' THEN 'build_muscle'
    ELSE np.nutrition_goal
  END,
  nutrition_goals = CASE
    WHEN u.preferences->>'weight_direction' = 'lose' THEN ARRAY['lose_fat']
    WHEN u.preferences->>'weight_direction' = 'gain' THEN ARRAY['build_muscle']
    ELSE np.nutrition_goals
  END,
  updated_at = NOW()
FROM users u
WHERE np.user_id = u.id
  AND np.nutrition_goal = 'maintain'
  AND u.preferences->>'weight_direction' IN ('lose', 'gain');
