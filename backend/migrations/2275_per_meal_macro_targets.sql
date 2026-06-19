-- Migration 2275: per-meal protein/carb/fat targets.
-- Lets users see a P/C/F target + progress under each meal section
-- (breakfast/lunch/dinner/snacks). Targets are AUTO-derived by splitting the
-- daily (dynamic) target, with optional CUSTOM per-meal overrides. Stored on
-- nutrition_preferences (JSONB) to avoid a new table + extra joins.
--
--   per_meal_targets_enabled  master on/off (default off — purely additive).
--   per_meal_macro_targets    JSONB:
--     {
--       "mode": "auto" | "custom",
--       "split": {"breakfast":0.25,"lunch":0.30,"dinner":0.35,"snacks":0.10},
--       "overrides": {"breakfast": {"protein_g":40,"carbs_g":50,"fat_g":15}, ...}
--     }
--   `split` optional (server default applies when absent); `overrides` only
--   present in custom mode. Per-meal targets are computed off the DAILY dynamic
--   target so they inherit training/fasting/cycle adjustments automatically.
--
-- Additive only; existing rows default to disabled. Applied to prod
-- (project hpbzfahijszqmgsybuor) via Supabase MCP 2026-06-19.
ALTER TABLE nutrition_preferences
  ADD COLUMN IF NOT EXISTS per_meal_targets_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS per_meal_macro_targets JSONB DEFAULT NULL;

COMMENT ON COLUMN nutrition_preferences.per_meal_macro_targets IS
  'Per-meal P/C/F targets (auto split of daily target + optional custom overrides). JSONB {mode, split, overrides}. NULL = auto with default split.';
