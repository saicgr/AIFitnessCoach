-- Migration: 508_coach_reviews.sql
-- Description: AI nutrition-pro reviews for recipes and meal plans.
--   Stored so the UI can show "last reviewed" + invalidate when the underlying subject is edited.
--   human_pro_id reserved for future human-coach feature; stub today.
-- Created: 2026-04-14

DO $$ BEGIN
    CREATE TYPE coach_review_subject AS ENUM ('recipe', 'meal_plan');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE coach_review_kind AS ENUM ('ai_auto', 'ai_requested', 'human_pro_pending', 'human_pro_complete');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS coach_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    subject_type coach_review_subject NOT NULL,
    subject_id UUID NOT NULL,
    subject_version INT,                -- recipe version_number at review time; for staleness detection

    review_kind coach_review_kind DEFAULT 'ai_auto',

    overall_score INT
        CHECK (overall_score IS NULL OR (overall_score BETWEEN 0 AND 100)),
    macro_balance_notes TEXT,
    micronutrient_gaps JSONB,           -- [{nutrient, deficit_pct, suggestion}]
    allergen_flags TEXT[] DEFAULT '{}',
    glycemic_load_score INT
        CHECK (glycemic_load_score IS NULL OR (glycemic_load_score BETWEEN 0 AND 100)),
    swap_suggestions JSONB,             -- [{from, to, rationale, deltas}]
    full_feedback TEXT,

    -- Stable reference to the model used so re-reviews can switch upgrade gracefully
    model_id TEXT,

    reviewed_at TIMESTAMPTZ DEFAULT NOW(),
    human_pro_id UUID                   -- nullable; FK omitted (no users table for pros yet)
);

CREATE INDEX IF NOT EXISTS idx_coach_reviews_subject
    ON coach_reviews (subject_type, subject_id, reviewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_coach_reviews_user
    ON coach_reviews (user_id, reviewed_at DESC);

ALTER TABLE coach_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read + create own coach reviews" ON coach_reviews;
CREATE POLICY "Users read + create own coach reviews"
    ON coach_reviews FOR ALL
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role full access coach reviews" ON coach_reviews;
CREATE POLICY "Service role full access coach reviews"
    ON coach_reviews FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

COMMENT ON TABLE coach_reviews IS
    'AI (and future human) nutritionist reviews of recipes and meal plans.';
COMMENT ON COLUMN coach_reviews.subject_version IS
    'For recipes: the user_recipes version_number at review time. UI shows "out of date" when current version > this.';
