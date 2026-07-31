-- 2401_user_warmup_templates.sql
--
-- E2E register #125 — "the warm-up is completely non-editable": no add/swap/
-- remove, no rest between moves (every move was a flat 30s), and — the ask
-- that makes the other two worth having — no way for a customization to
-- survive past the single workout it was made in. Every NEW workout called
-- into AI generation from scratch and threw the user's edits away, because
-- the only place a warm-up lived was the per-workout `warmups` row (see
-- migrations 005/006/078).
--
-- This table is the missing "carries forward" piece: ONE saved warm-up per
-- user, optionally scoped to a `workout_type` (a bodyweight-HIIT user's
-- warm-up shouldn't have to match their heavy-leg-day warm-up). Consumers:
--   - `POST /workouts/{workout_id}/warmup/apply-template`
--     (backend/api/v1/workouts/warmup_templates.py) seeds a brand-new
--     workout's `warmups` row from the saved template BEFORE the client
--     would otherwise fall back to `fetchWarmupAndStretches`/generation —
--     see `_resolveWarmupPhase` in
--     mobile/flutter/lib/screens/workout/easy/easy_active_workout_state.dart.
--   - `PUT /workouts/warmup-template` upserts whenever the user meaningfully
--     customizes a warm-up this run (add/remove/swap a move, or edits a
--     hold/rest duration) — see `_finishWarmupPhase` in the same file.
--
-- `workout_type = NULL` is the user's one generic/default warm-up, used as
-- the fallback when no type-specific template exists yet. Postgres unique
-- constraints treat NULL as distinct from every other NULL, so a single
-- `UNIQUE (user_id, workout_type)` constraint would silently allow
-- unlimited duplicate default rows. Two partial unique indexes below
-- enforce "at most one row per (user, type)" and "at most one default row
-- per user" separately, which is the actual invariant the upsert relies on.

CREATE TABLE IF NOT EXISTS user_warmup_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    workout_type TEXT,
    exercises_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS user_warmup_templates_user_type_uidx
    ON user_warmup_templates (user_id, workout_type)
    WHERE workout_type IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS user_warmup_templates_user_default_uidx
    ON user_warmup_templates (user_id)
    WHERE workout_type IS NULL;

CREATE INDEX IF NOT EXISTS user_warmup_templates_user_idx
    ON user_warmup_templates (user_id);

ALTER TABLE user_warmup_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_warmup_templates_select ON user_warmup_templates
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_warmup_templates_insert ON user_warmup_templates
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_warmup_templates_update ON user_warmup_templates
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY user_warmup_templates_delete ON user_warmup_templates
    FOR DELETE USING (auth.uid() = user_id);
