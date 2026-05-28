-- Migration 2204 — premium_previews content catalog
-- Backs:
--   GET /api/v1/home/premium-preview-rotation
-- Rotation by weekday; suppressed for premium / premium_plus / lifetime tiers.

CREATE TABLE IF NOT EXISTS premium_previews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text UNIQUE NOT NULL,
    title text NOT NULL,
    preview_body text NOT NULL,
    locked_feature_key text NOT NULL,
    route text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO premium_previews (slug, title, preview_body, locked_feature_key, route) VALUES
('advanced-trends', 'Advanced strength and volume trends', 'See 12-week strength curves per muscle group, plateaus called out automatically, and weekly volume distribution across push/pull/legs. Premium unlocks the full history view.', 'advanced_trends', '/paywall?feature=advanced_trends'),
('ai-form-analysis', 'AI form analysis on video', 'Upload a 10-second clip of your squat, bench, or deadlift and get a per-rep breakdown — bar path, depth, knee tracking, lockout. Premium ships the form review tool.', 'ai_form_analysis', '/paywall?feature=ai_form_analysis'),
('rag-personal-coach', 'Personalized RAG coach', 'Your coach reads your full training, nutrition, and recovery history before answering. Knows your PRs, your injuries, your schedule. Premium-only context window.', 'rag_personal_coach', '/paywall?feature=rag_personal_coach'),
('custom-training-splits', 'Custom training splits', 'Build any split — 4-day upper/lower, PPL, conjugate, your own — with per-day muscle volume targets the planner enforces. Premium unlocks the split builder.', 'custom_training_splits', '/paywall?feature=custom_training_splits'),
('body-comp-tracking', 'Body composition tracking', 'Weekly photo overlays, waist-to-hip trend lines, and lean-mass estimates from your weigh-ins plus measurements. Premium tracks composition, not just scale weight.', 'body_comp_tracking', '/paywall?feature=body_comp_tracking'),
('family-plan', 'Family plan (up to 5 members)', 'One subscription, up to 5 separate accounts — partner, kids, parents. Each with their own plan, history, and privacy. Premium plus unlocks family seats.', 'family_plan', '/paywall?feature=family_plan'),
('priority-support', 'Priority human support', 'Skip the queue. Premium members get a human reply on support tickets within 4 business hours and direct access to the founders for product feedback.', 'priority_support', '/paywall?feature=priority_support')
ON CONFLICT (slug) DO NOTHING;
