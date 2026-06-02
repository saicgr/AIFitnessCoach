-- Migration 2227: Intermittent-fasting / eating-window prefs.
-- Read by recommend_meal's is_in_fasting_window() so the AI coach won't push a
-- meal during the user's fast. Hours are local 0-23. Applied to the live DB
-- 2026-06-01 via Supabase MCP.

ALTER TABLE nutrition_preferences ADD COLUMN IF NOT EXISTS intermittent_fasting_enabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE nutrition_preferences ADD COLUMN IF NOT EXISTS eating_window_start_hour INTEGER;
ALTER TABLE nutrition_preferences ADD COLUMN IF NOT EXISTS eating_window_end_hour INTEGER;

COMMENT ON COLUMN nutrition_preferences.eating_window_start_hour IS 'Local hour 0-23 when the eating window opens (e.g. 12 for a noon-8pm 16:8 fast).';
COMMENT ON COLUMN nutrition_preferences.eating_window_end_hour IS 'Local hour 0-23 when the eating window closes (e.g. 20).';
