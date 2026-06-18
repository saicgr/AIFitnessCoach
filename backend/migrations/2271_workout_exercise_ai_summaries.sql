-- Migration 2271: Per-exercise AI summary cache (post-workout deep dive).
--
-- Backs POST /feedback/exercise-summary + GET /feedback/exercise-summary/{...}.
-- Distinct from workout_ai_recaps (one payload per WORKOUT) — this stores ONE
-- AI critique per (user, workout_log_id, exercise_name) so re-opening the
-- per-exercise "✨ AI" card on the summary screen is instant (no re-bill of
-- Gemini), while `force=true` regenerates.
--
-- Mirrors the workout_ai_recaps upsert pattern: a UNIQUE index on the natural
-- key drives ON CONFLICT idempotency. All columns either NOT NULL with sane
-- shape or nullable metadata. payload JSONB holds the structured context
-- (is_pr / is_near_pr / form_score / today_top_1rm_kg) the response surfaces.
--
-- DO NOT APPLY as part of this change — reserved number 2271, create only;
-- the parent applies it via MCP.

CREATE TABLE IF NOT EXISTS workout_exercise_ai_summaries (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL,
    workout_log_id     TEXT NOT NULL,
    exercise_name      TEXT NOT NULL,
    payload            JSONB,
    critique_markdown  TEXT,
    model_version      TEXT,
    generated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Natural key → drives ON CONFLICT (user_id, workout_log_id, exercise_name).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_workout_exercise_ai_summary
    ON workout_exercise_ai_summaries (user_id, workout_log_id, exercise_name);

-- Fast "all summaries for this workout log" lookups.
CREATE INDEX IF NOT EXISTS idx_workout_exercise_ai_summary_log
    ON workout_exercise_ai_summaries (user_id, workout_log_id);
