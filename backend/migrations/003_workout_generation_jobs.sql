-- Migration: Create workout_generation_jobs table for reliable background generation
-- Run this in Supabase Dashboard > SQL Editor

CREATE TABLE IF NOT EXISTS workout_generation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    month_start_date DATE NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 45,
    selected_days INTEGER[] NOT NULL,
    weeks INTEGER NOT NULL DEFAULT 11,
    total_expected INTEGER NOT NULL DEFAULT 0,
    total_generated INTEGER NOT NULL DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    CONSTRAINT valid_status CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'cancelled'))
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_workout_generation_jobs_user_id ON workout_generation_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_generation_jobs_status ON workout_generation_jobs(status);
CREATE INDEX IF NOT EXISTS idx_workout_generation_jobs_pending ON workout_generation_jobs(status) WHERE status IN ('pending', 'in_progress');

-- Comment
COMMENT ON TABLE workout_generation_jobs IS 'Tracks background workout generation jobs for reliability - survives server restarts';

-- Grant permissions (if using RLS)
ALTER TABLE workout_generation_jobs ENABLE ROW LEVEL SECURITY;

-- Allow service role full access
CREATE POLICY "Service role has full access to workout_generation_jobs"
    ON workout_generation_jobs
    FOR ALL
    USING (true)
    WITH CHECK (true);
