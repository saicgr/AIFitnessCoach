-- ============================================================================
-- Migration 2219 — coach_daily_insights.chips
-- ============================================================================
-- The morning_brief / evening_recap prompts already ask Gemini for a `chips`
-- list (quick-reply / action chips shown under the briefing), but the endpoint
-- dropped them. This column persists the chips so a cache hit on reopen returns
-- the SAME chips (including memory-derived check-in chips like "Back feels
-- better"), instead of falling back to the deterministic client-side set.
--
-- Shape: jsonb array of {label, route?, action?} objects.
-- Idempotent.
-- ============================================================================

ALTER TABLE public.coach_daily_insights
    ADD COLUMN IF NOT EXISTS chips jsonb;

COMMENT ON COLUMN public.coach_daily_insights.chips IS
    'Quick-reply/action chips for the rich briefings (morning_brief/evening_recap). jsonb array of {label, route?, action?}. Added in 2219.';
