-- Migration 078: Add target_muscles column to warmups and stretches tables
-- This enables tracking which muscle groups the warmup/stretch is targeting
-- for better visibility and debugging of dynamic warmup generation

-- Add target_muscles column to warmups table
ALTER TABLE warmups
ADD COLUMN IF NOT EXISTS target_muscles JSONB DEFAULT '[]'::jsonb;

-- Add target_muscles column to stretches table
ALTER TABLE stretches
ADD COLUMN IF NOT EXISTS target_muscles JSONB DEFAULT '[]'::jsonb;

-- Add comment for documentation
COMMENT ON COLUMN warmups.target_muscles IS 'Array of muscle groups this warmup targets, extracted from the workout exercises';
COMMENT ON COLUMN stretches.target_muscles IS 'Array of muscle groups this stretch routine targets, extracted from the workout exercises';

-- Create index for faster queries by target muscles
CREATE INDEX IF NOT EXISTS idx_warmups_target_muscles ON warmups USING GIN (target_muscles);
CREATE INDEX IF NOT EXISTS idx_stretches_target_muscles ON stretches USING GIN (target_muscles);

-- Update RLS policies to include new column (they already exist, just need to ensure SELECT includes new column)
-- No new policies needed since existing policies already cover all columns

-- Create a view for easy querying of warmups by target muscle
CREATE OR REPLACE VIEW v_warmups_with_muscles AS
SELECT
    w.id,
    w.workout_id,
    w.exercises_json,
    w.duration_minutes,
    w.target_muscles,
    w.version_number,
    w.is_current,
    w.valid_from,
    wk.user_id,
    wk.name as workout_name,
    wk.type as workout_type,
    wk.scheduled_date
FROM warmups w
JOIN workouts wk ON w.workout_id = wk.id
WHERE w.is_current = true;

-- Create a view for easy querying of stretches by target muscle
CREATE OR REPLACE VIEW v_stretches_with_muscles AS
SELECT
    s.id,
    s.workout_id,
    s.exercises_json,
    s.duration_minutes,
    s.target_muscles,
    s.version_number,
    s.is_current,
    s.valid_from,
    wk.user_id,
    wk.name as workout_name,
    wk.type as workout_type,
    wk.scheduled_date
FROM stretches s
JOIN workouts wk ON s.workout_id = wk.id
WHERE s.is_current = true;

-- Grant access to the views
GRANT SELECT ON v_warmups_with_muscles TO authenticated;
GRANT SELECT ON v_stretches_with_muscles TO authenticated;
