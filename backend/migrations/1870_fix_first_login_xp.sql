-- Fix first_login XP bonus: was 500 XP (set when early levels needed 50-5000 XP each).
-- Migration 227 reduced early level thresholds to 25-180 XP, making 500 XP skip
-- new users straight to level 6-8. Reduce to 50 XP so signup grants exactly 1 level-up.
UPDATE xp_bonus_templates
SET base_xp = 50
WHERE bonus_type = 'first_login';
