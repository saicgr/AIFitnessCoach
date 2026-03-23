-- Migration 1874: Sauna session logging table
-- Tracks sauna sessions with duration and estimated calorie burn

CREATE TABLE IF NOT EXISTS sauna_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    workout_id UUID REFERENCES workouts(id),
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0 AND duration_minutes <= 240),
    estimated_calories INT,
    notes TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    local_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sauna_logs_user_date ON sauna_logs (user_id, local_date);
CREATE INDEX IF NOT EXISTS idx_sauna_logs_workout ON sauna_logs (workout_id);

ALTER TABLE sauna_logs ENABLE ROW LEVEL SECURITY;

-- RLS policies (matching hydration_logs pattern)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sauna_logs' AND policyname = 'Users can view own sauna logs') THEN
        CREATE POLICY "Users can view own sauna logs" ON sauna_logs
            FOR SELECT USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sauna_logs' AND policyname = 'Users can insert own sauna logs') THEN
        CREATE POLICY "Users can insert own sauna logs" ON sauna_logs
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sauna_logs' AND policyname = 'Users can delete own sauna logs') THEN
        CREATE POLICY "Users can delete own sauna logs" ON sauna_logs
            FOR DELETE USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sauna_logs' AND policyname = 'Service role full access sauna logs') THEN
        CREATE POLICY "Service role full access sauna logs" ON sauna_logs
            FOR ALL USING (current_setting('role') = 'service_role');
    END IF;
END $$;
