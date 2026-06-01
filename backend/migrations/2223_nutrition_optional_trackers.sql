-- 2223_nutrition_optional_trackers.sql
-- Gap 6 + Gap 7 — optional, opt-in nutrition trackers on nutrition_preferences.
--
-- Gap 6: hydration tracking can be turned OFF (default stays ON to preserve the
--        current always-on UX). When off, the app hides the hydration tab /
--        water quick-action / home water segment and the food logger skips its
--        water-detection LLM pass (saves cost).
-- Gap 7: opt-in first-class daily trackers for sugar / caffeine / alcohol
--        (default OFF, hidden when off) with per-tracker daily limits. The
--        underlying micronutrients are already captured on every food log; these
--        flags only control the visible counter + over-limit nudge.

ALTER TABLE public.nutrition_preferences
  ADD COLUMN IF NOT EXISTS hydration_tracking_enabled boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS sugar_tracking_enabled    boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS caffeine_tracking_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS alcohol_tracking_enabled  boolean DEFAULT false,
  -- Per-tracker daily limits. Defaults are mainstream public-health references,
  -- editable by the user. added-sugar 36 g (AHA men) / caffeine 400 mg (FDA) /
  -- alcohol 2 standard drinks.
  ADD COLUMN IF NOT EXISTS sugar_limit_g       integer DEFAULT 36,
  ADD COLUMN IF NOT EXISTS caffeine_limit_mg   integer DEFAULT 400,
  ADD COLUMN IF NOT EXISTS alcohol_limit_units integer DEFAULT 2;

COMMENT ON COLUMN public.nutrition_preferences.hydration_tracking_enabled IS
  'Gap 6 — when false, hide all hydration UI and skip water extraction in the food logger.';
COMMENT ON COLUMN public.nutrition_preferences.sugar_tracking_enabled IS
  'Gap 7 — show a daily added-sugar counter + over-limit nudge. Off by default.';
COMMENT ON COLUMN public.nutrition_preferences.caffeine_tracking_enabled IS
  'Gap 7 — show a daily caffeine counter + over-limit nudge. Off by default.';
COMMENT ON COLUMN public.nutrition_preferences.alcohol_tracking_enabled IS
  'Gap 7 — show a daily alcohol counter + over-limit nudge. Off by default.';
