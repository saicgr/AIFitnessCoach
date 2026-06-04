-- Migration 2232: Persisted post-workout AI recaps (Workstream B, B8)
--
-- Backs Zealova's deeper-than-Gravl post-workout summary. After a workout
-- completes the backend generates a structured recap (volume-vs-last-comparable,
-- PRs hit, "what stood out", and ONE concrete coaching cue for next time),
-- persisted here so the recap card renders instantly on revisit and the recap
-- is durable for history / sharing — unlike the ephemeral RAG-only AI Coach
-- one-liner.
--
-- One recap per (workout_id, user_id). Idempotent: the generate endpoint upserts
-- on that pair, so re-completing or re-opening the same workout returns the same
-- row instead of re-billing Gemini. The full structured output lives in `payload`
-- (JSONB) so we can evolve the recap shape without further DDL; a few hot scalar
-- columns are denormalized for cheap listing / analytics.
--
-- DO NOT APPLY as part of this change — reserved number 2232, create only.

CREATE TABLE IF NOT EXISTS workout_ai_recaps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Key by workout (the plan/session the recap is about). Stored as TEXT to
    -- match the rest of the workouts API, which keys workouts by string id and
    -- also accepts the per-completion workout_log_id.
    workout_id TEXT NOT NULL,
    workout_log_id TEXT,           -- specific completion this recap was generated from

    -- Full structured recap returned to the client (see WorkoutAiRecapPayload):
    --   headline, what_stood_out[], volume_comparison{}, prs[],
    --   coaching_cue, notes_reference, model_version
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Denormalized hot fields for cheap listing / analytics without parsing JSONB.
    headline TEXT,                              -- one-line summary
    coaching_cue TEXT,                          -- the single concrete cue for next time
    total_volume_kg DOUBLE PRECISION DEFAULT 0, -- this session's total volume
    volume_delta_pct DOUBLE PRECISION,          -- vs last comparable session (NULL if no comparable)
    pr_count INTEGER DEFAULT 0,                 -- number of PRs hit this session

    -- Multi-modal readiness: surfaced when the recap referenced logged notes.
    referenced_notes BOOLEAN DEFAULT FALSE,

    model_version TEXT,                         -- e.g. "gemini-3-flash-preview"
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_recap_payload CHECK (jsonb_typeof(payload) = 'object')
);

-- One recap per workout per user; the generate endpoint upserts on this pair
-- for idempotency (ON CONFLICT (user_id, workout_id)).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_workout_ai_recap_user_workout
    ON workout_ai_recaps(user_id, workout_id);

-- Fast fetch-by-workout for the recap card (GET path).
CREATE INDEX IF NOT EXISTS idx_workout_ai_recaps_workout
    ON workout_ai_recaps(workout_id);

-- Fast "recent recaps for this user" (history / future timeline surfaces).
CREATE INDEX IF NOT EXISTS idx_workout_ai_recaps_user_recent
    ON workout_ai_recaps(user_id, generated_at DESC);

COMMENT ON TABLE workout_ai_recaps IS
    'Persisted post-workout AI recaps (B8). One per (user_id, workout_id); '
    'payload holds the full structured recap, scalar columns denormalized for listing.';
COMMENT ON COLUMN workout_ai_recaps.payload IS
    'Full WorkoutAiRecapPayload JSON: headline, what_stood_out, volume_comparison, prs, coaching_cue, notes_reference.';
COMMENT ON COLUMN workout_ai_recaps.volume_delta_pct IS
    'Percent change in total volume vs the last comparable session; NULL when no comparable session exists.';
COMMENT ON COLUMN workout_ai_recaps.referenced_notes IS
    'True when the recap incorporated the user''s logged set/workout notes (multi-modal signal).';
