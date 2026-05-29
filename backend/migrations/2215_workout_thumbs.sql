-- 2215_workout_thumbs.sql
-- Lightweight inline thumbs up/down on a workout, fired from the chat result
-- card or the detail header BEFORE (or without) completing the workout.
-- Distinct from the existing post-workout `workout_feedback` table (overall
-- rating / energy / would_recommend) and from per-exercise "never recommend".
-- Soft signal: one down-vote never globally bans an exercise.
-- One row per (user, workout); upsert toggles. thumbs: 1 = up, -1 = down.
-- No hard FK to workouts so an ephemeral/deleted workout does not block.

CREATE TABLE IF NOT EXISTS workout_thumbs (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id  uuid NOT NULL,
    thumbs      smallint NOT NULL CHECK (thumbs IN (-1, 1)),
    reason      text,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, workout_id)
);

CREATE INDEX IF NOT EXISTS idx_workout_thumbs_user
    ON workout_thumbs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_thumbs_workout
    ON workout_thumbs(workout_id);
