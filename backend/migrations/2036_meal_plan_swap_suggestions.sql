-- Migration: 2036_meal_plan_swap_suggestions.sql
-- Description: Sidecar table for AI-generated meal-plan swap suggestions.
--   The /meal-plans/{id}/simulate endpoint returns the rule-based projection
--   immediately and schedules Gemini swap generation in a FastAPI
--   BackgroundTask (plan A5). The background worker upserts results here so
--   the client can re-fetch (or Realtime-subscribe) without blocking the
--   simulate response.
-- Created: 2026-04-27

CREATE TABLE IF NOT EXISTS meal_plan_swap_suggestions (
    plan_id UUID PRIMARY KEY REFERENCES meal_plans(id) ON DELETE CASCADE,
    suggestions JSONB NOT NULL DEFAULT '[]'::jsonb,
    coach_summary TEXT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_plan_swap_suggestions_generated_at
    ON meal_plan_swap_suggestions (generated_at DESC);

ALTER TABLE meal_plan_swap_suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own plan swap suggestions" ON meal_plan_swap_suggestions;
CREATE POLICY "Users read own plan swap suggestions"
    ON meal_plan_swap_suggestions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans p
            WHERE p.id = plan_id AND p.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Service role full access plan swap suggestions" ON meal_plan_swap_suggestions;
CREATE POLICY "Service role full access plan swap suggestions"
    ON meal_plan_swap_suggestions FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

COMMENT ON TABLE meal_plan_swap_suggestions IS
    'Sidecar for async Gemini swap suggestions. One row per meal_plan; upserted by background task after /simulate returns.';
COMMENT ON COLUMN meal_plan_swap_suggestions.suggestions IS
    'Array of {from_label, to_label, rationale, deltas} matching models.meal_plan.AiSwapSuggestion.';
