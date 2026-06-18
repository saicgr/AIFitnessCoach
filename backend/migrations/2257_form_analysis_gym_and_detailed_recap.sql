-- Migration 2257: Signature v2 workout fixes — per-gym form analyses +
--                 persisted detailed post-workout summary.
--
-- Two additive, backward-compatible changes (all columns NULLABLE):
--
--   1. media_analysis_jobs.gym_profile_id — bind a form analysis to the gym it
--      was performed at, so the per-exercise/per-gym Form history tab can scope
--      results by gym (exercise binding stays in params JSONB: exercise_id +
--      exercise_name). NULL = unassigned / combined. FK ON DELETE SET NULL so
--      archiving/deleting a gym never orphans an analysis.
--
--   2. workout_ai_recaps.detailed_summary_md — the longer, sectioned markdown
--      breakdown (**Strengths** / **Weaknesses** / **What to improve** /
--      **What to do next**) returned by POST /feedback/recap/detailed. Reuses
--      the existing recap row (one per user+workout, idempotent) rather than a
--      new table so the detailed summary is durable + fetchable instantly
--      alongside the structured recap.
--
-- DO NOT APPLY as part of this change — reserved number 2257, create only;
-- the parent applies it.

-- ============================================================================
-- 1. media_analysis_jobs.gym_profile_id
-- ============================================================================
ALTER TABLE media_analysis_jobs
    ADD COLUMN IF NOT EXISTS gym_profile_id UUID
        REFERENCES gym_profiles(id) ON DELETE SET NULL;

-- Per-gym form-history query path (user + type + gym, newest first).
CREATE INDEX IF NOT EXISTS idx_media_analysis_jobs_user_gym
    ON media_analysis_jobs(user_id, gym_profile_id);

COMMENT ON COLUMN media_analysis_jobs.gym_profile_id IS
    'Gym profile this media analysis (e.g. form check) was performed at; '
    'NULL = unassigned / combined. FK ON DELETE SET NULL.';

-- ============================================================================
-- 2. workout_ai_recaps.detailed_summary_md
-- ============================================================================
ALTER TABLE workout_ai_recaps
    ADD COLUMN IF NOT EXISTS detailed_summary_md TEXT;

COMMENT ON COLUMN workout_ai_recaps.detailed_summary_md IS
    'Longer sectioned markdown post-workout breakdown (Strengths / Weaknesses / '
    'What to improve / What to do next) from POST /feedback/recap/detailed; '
    'NULL until generated. Cached per (user_id, workout_id) like the recap payload.';
