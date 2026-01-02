-- FitWiz - Warmups and Stretches Tables Migration
-- This creates tables for storing warmup and cooldown exercises linked to workouts

-- Warmups table - stores warm-up exercises for workouts
CREATE TABLE IF NOT EXISTS warmups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercises_json JSONB NOT NULL,  -- Array of warm-up exercises
    duration_minutes INTEGER DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_warmups_workout_id ON warmups(workout_id);

-- Stretches table - stores cool-down stretches for workouts
CREATE TABLE IF NOT EXISTS stretches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercises_json JSONB NOT NULL,  -- Array of stretch exercises
    duration_minutes INTEGER DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stretches_workout_id ON stretches(workout_id);

-- Auto-update updated_at on row update
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_warmups_updated_at
    BEFORE UPDATE ON warmups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stretches_updated_at
    BEFORE UPDATE ON stretches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE warmups ENABLE ROW LEVEL SECURITY;
ALTER TABLE stretches ENABLE ROW LEVEL SECURITY;

-- RLS Policies - users can access warmups/stretches for their workouts
CREATE POLICY "Users can view own warmups" ON warmups
    FOR SELECT USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage own warmups" ON warmups
    FOR ALL USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

CREATE POLICY "Users can view own stretches" ON stretches
    FOR SELECT USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

CREATE POLICY "Users can manage own stretches" ON stretches
    FOR ALL USING (
        workout_id IN (
            SELECT id FROM workouts
            WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );
