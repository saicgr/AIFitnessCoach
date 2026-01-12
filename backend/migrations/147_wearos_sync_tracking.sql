-- Migration: WearOS sync event tracking
-- Created: 2026-01-11
-- Purpose: Track sync events between WearOS watch and backend

-- Create table to track WearOS sync events
CREATE TABLE IF NOT EXISTS wearos_sync_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(100),
    sync_type VARCHAR(50) NOT NULL,  -- 'workout', 'nutrition', 'fasting', 'activity', 'bulk'
    items_synced INT DEFAULT 0,
    items_failed INT DEFAULT 0,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for efficient user queries
CREATE INDEX IF NOT EXISTS idx_wearos_sync_user ON wearos_sync_events(user_id, synced_at DESC);

-- Create index for device-specific queries
CREATE INDEX IF NOT EXISTS idx_wearos_sync_device ON wearos_sync_events(device_id, synced_at DESC);

-- Add RLS policies
ALTER TABLE wearos_sync_events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own sync events
CREATE POLICY wearos_sync_events_select_own ON wearos_sync_events
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own sync events
CREATE POLICY wearos_sync_events_insert_own ON wearos_sync_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Service role can do everything
CREATE POLICY wearos_sync_events_service_role ON wearos_sync_events
    FOR ALL USING (auth.role() = 'service_role');

-- Create table for workout completions from watch
CREATE TABLE IF NOT EXISTS workout_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(100) NOT NULL,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 0,
    total_sets INT DEFAULT 0,
    total_reps INT DEFAULT 0,
    total_volume_kg FLOAT DEFAULT 0,
    avg_heart_rate INT,
    max_heart_rate INT,
    calories_burned INT,
    device_source VARCHAR(20) DEFAULT 'phone',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for workout_completions
CREATE INDEX IF NOT EXISTS idx_workout_completions_user ON workout_completions(user_id, ended_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_completions_workout ON workout_completions(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_completions_session ON workout_completions(session_id);

-- Add RLS policies for workout_completions
ALTER TABLE workout_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY workout_completions_select_own ON workout_completions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY workout_completions_insert_own ON workout_completions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY workout_completions_service_role ON workout_completions
    FOR ALL USING (auth.role() = 'service_role');

-- Create table for heart rate samples (from watch)
CREATE TABLE IF NOT EXISTS heart_rate_samples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    bpm INT NOT NULL CHECK (bpm >= 30 AND bpm <= 250),
    source VARCHAR(20) DEFAULT 'watch',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for heart_rate_samples
CREATE INDEX IF NOT EXISTS idx_hr_samples_user_time ON heart_rate_samples(user_id, timestamp DESC);

-- Partition-friendly index for time-based queries
CREATE INDEX IF NOT EXISTS idx_hr_samples_timestamp ON heart_rate_samples(timestamp DESC);

-- Add RLS policies for heart_rate_samples
ALTER TABLE heart_rate_samples ENABLE ROW LEVEL SECURITY;

CREATE POLICY heart_rate_samples_select_own ON heart_rate_samples
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY heart_rate_samples_insert_own ON heart_rate_samples
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY heart_rate_samples_service_role ON heart_rate_samples
    FOR ALL USING (auth.role() = 'service_role');

-- Add comments
COMMENT ON TABLE wearos_sync_events IS 'Tracks sync events between WearOS watch and backend';
COMMENT ON TABLE workout_completions IS 'Records of completed workouts with metrics';
COMMENT ON TABLE heart_rate_samples IS 'Heart rate readings from WearOS watch';
