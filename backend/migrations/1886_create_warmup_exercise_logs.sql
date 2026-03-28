-- Warmup exercise interval logs
-- Stores detailed cardio interval data logged during warmup exercises
-- (e.g., treadmill speed/incline changes at different time points)

CREATE TABLE IF NOT EXISTS warmup_exercise_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL,
    user_id UUID NOT NULL,
    exercise_name VARCHAR NOT NULL,
    intervals_json JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for looking up logs by workout
CREATE INDEX IF NOT EXISTS idx_warmup_exercise_logs_workout_id
    ON warmup_exercise_logs(workout_id);

-- Index for looking up user's warmup history
CREATE INDEX IF NOT EXISTS idx_warmup_exercise_logs_user_id
    ON warmup_exercise_logs(user_id);

-- RLS policies
ALTER TABLE warmup_exercise_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY warmup_exercise_logs_select ON warmup_exercise_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY warmup_exercise_logs_insert ON warmup_exercise_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
