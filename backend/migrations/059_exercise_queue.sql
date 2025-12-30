-- Migration 059: Exercise Queue System
-- Allows users to queue specific exercises for upcoming workouts
-- Addresses competitor feedback: "queuing exercises didn't help"

-- Create exercise_queue table
CREATE TABLE IF NOT EXISTS exercise_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    -- Optional reference to exercise library (can be null for custom exercises)
    exercise_id TEXT,
    -- Priority for ordering (lower = higher priority)
    priority INTEGER DEFAULT 0,
    -- Optional target muscle group (helps match to appropriate workout)
    target_muscle_group TEXT,
    -- When the exercise was queued
    added_at TIMESTAMPTZ DEFAULT NOW(),
    -- Auto-expire after 7 days to prevent stale queues
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    -- Track if exercise has been used
    used_at TIMESTAMPTZ,
    -- Ensure a user can only queue an exercise once
    UNIQUE(user_id, exercise_name)
);

-- Create index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_exercise_queue_user_id
ON exercise_queue(user_id);

-- Create index for finding active (not expired, not used) queue items
CREATE INDEX IF NOT EXISTS idx_exercise_queue_active
ON exercise_queue(user_id, expires_at)
WHERE used_at IS NULL;

-- Enable Row Level Security
ALTER TABLE exercise_queue ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own queue
CREATE POLICY exercise_queue_select_policy ON exercise_queue
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert to their own queue
CREATE POLICY exercise_queue_insert_policy ON exercise_queue
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own queue
CREATE POLICY exercise_queue_update_policy ON exercise_queue
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can only delete from their own queue
CREATE POLICY exercise_queue_delete_policy ON exercise_queue
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON exercise_queue TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE exercise_queue IS 'Queue of exercises users want included in upcoming workouts';
COMMENT ON COLUMN exercise_queue.priority IS 'Lower number = higher priority for inclusion';
COMMENT ON COLUMN exercise_queue.target_muscle_group IS 'Helps match queued exercise to appropriate workout focus';
COMMENT ON COLUMN exercise_queue.expires_at IS 'Auto-expire after 7 days to prevent stale queues';
COMMENT ON COLUMN exercise_queue.used_at IS 'When the exercise was used in a workout (NULL = still pending)';
