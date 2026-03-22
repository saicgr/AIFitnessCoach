-- Migration: Fix gym profile colors for existing users
-- Problem: All gym profiles were created with the default cyan (#00BCD4) regardless
--          of the coach selected during onboarding.
-- Fix: Update gym profiles that still have the default cyan color to use the
--      color matching the user's selected coach.

UPDATE gym_profiles gp
SET color = CASE
    WHEN u.preferences->>'coach_id' = 'coach_mike'    THEN '#FF9800'
    WHEN u.preferences->>'coach_id' = 'dr_sarah'      THEN '#2196F3'
    WHEN u.preferences->>'coach_id' = 'sergeant_max'  THEN '#F44336'
    WHEN u.preferences->>'coach_id' = 'zen_maya'      THEN '#4CAF50'
    WHEN u.preferences->>'coach_id' = 'hype_danny'    THEN '#9C27B0'
    ELSE '#FF9800'  -- custom coach or unknown: default to orange (app default accent)
END
FROM users u
WHERE gp.user_id = u.id
  AND gp.color = '#00BCD4';
