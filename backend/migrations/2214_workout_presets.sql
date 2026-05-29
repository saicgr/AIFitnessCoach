-- 2214_workout_presets.sql
-- Stores reusable Workout Customization Studio presets.
-- params is the full studio param set (focus, equipment, intensity, duration,
-- style, sore areas, impact, warmup/cooldown minutes, supersets, amrap, staples).
-- Applying a preset re-runs build_adapted_workout() with these params.

CREATE TABLE IF NOT EXISTS workout_presets (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        varchar(120) NOT NULL,
    params      jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_workout_presets_user
    ON workout_presets(user_id);
