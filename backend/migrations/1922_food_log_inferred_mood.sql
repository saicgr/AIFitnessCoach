-- 1922_food_log_inferred_mood.sql
-- Adds passive mood inference columns to food_logs so we can surface "AI guess"
-- mood/energy on meals the user skipped the check-in sheet for. User-confirmed
-- columns (mood_after, energy_level) always outrank these.

ALTER TABLE public.food_logs
  ADD COLUMN IF NOT EXISTS mood_after_inferred text,
  ADD COLUMN IF NOT EXISTS energy_level_inferred int,
  ADD COLUMN IF NOT EXISTS inference_confidence numeric(3,2),
  ADD COLUMN IF NOT EXISTS inference_source text,
  ADD COLUMN IF NOT EXISTS inference_user_confirmed boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS inference_user_dismissed boolean DEFAULT false;

-- Partial index: only rows that actually have an inference and haven't been dismissed
-- support the Patterns aggregation query.
CREATE INDEX IF NOT EXISTS idx_food_logs_inferred
  ON public.food_logs (user_id, logged_at DESC)
  WHERE mood_after_inferred IS NOT NULL
    AND inference_user_dismissed = false;

COMMENT ON COLUMN public.food_logs.mood_after_inferred IS
  'AI-inferred post-meal mood when user did not provide one. Values mirror mood_after enum (bloated/tired/stressed/good/great/satisfied).';
COMMENT ON COLUMN public.food_logs.inference_confidence IS
  '0.00-1.00. Rows with mood_after set (user-confirmed) should always outrank inferred rows regardless of confidence.';
COMMENT ON COLUMN public.food_logs.inference_source IS
  'Identifier for the inference version, e.g. rules_v1. Lets us upgrade the engine without re-running old rows.';
