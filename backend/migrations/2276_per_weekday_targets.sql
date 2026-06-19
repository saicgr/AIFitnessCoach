-- Migration 2276: per-weekday (high/base day) macro targets.
-- Lets users set a "high day" P/C/F target distinct from their "base day"
-- target ("200g protein on workout days, 150g on rest days"). Built on the
-- existing day-type engine — when enabled it REPLACES the automatic training/
-- rest +200 kcal bump for that date (the weekday override is the absolute
-- target, so today never shows a surprise number / no double-count). Stored on
-- nutrition_preferences (JSONB) to avoid a new table + extra joins; mirrors the
-- 2275 per_meal_macro_targets pattern.
--
--   per_weekday_targets  JSONB:
--     {
--       "enabled": true,
--       "bind_to_training_days": false,
--       "high_days": [0, 2, 4],
--       "high": {"protein_g": 200, "carbs_g": 180, "fat_g": 55},
--       "base": {"protein_g": 150, "carbs_g": 168, "fat_g": 50}
--     }
--   `enabled` master on/off (NULL or false ⇒ feature off, behavior UNCHANGED).
--   `bind_to_training_days` when true, "high" follows the user's
--     gym_profiles.workout_days (or a logged workout) instead of `high_days`.
--   `high_days` 0-indexed weekdays (0=Mon..6=Sun) that count as a "high" day
--     when NOT bound to training days.
--   `high` / `base` absolute macro grams for the resolved day type; the day's
--     calorie target is derived (4·P + 4·C + 9·F). Per-meal split inherits the
--     resolved daily target automatically.
--
-- Additive only; existing rows default to NULL (feature off). Applied to prod
-- (project hpbzfahijszqmgsybuor) via Supabase MCP <pending — human applies>.
ALTER TABLE nutrition_preferences
  ADD COLUMN IF NOT EXISTS per_weekday_targets JSONB DEFAULT NULL;

COMMENT ON COLUMN nutrition_preferences.per_weekday_targets IS
  'Per-weekday (high/base day) macro targets. JSONB {enabled, bind_to_training_days, high_days:[0..6], high:{protein_g,carbs_g,fat_g}, base:{...}}. NULL/enabled=false = off. When enabled, REPLACES the automatic training/rest calorie bump for that date (no double-count). Calories derived 4P+4C+9F; per-meal split inherits the resolved daily target.';
