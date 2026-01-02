-- Migration: 095_hiit_interval_workouts.sql
-- Add HIIT/Interval workout support with NO static holds during intervals
-- This addresses user feedback: "intervals shouldn't have any static holds.
-- It's dangerous for your heart to go from burpee box jumps to planks."

-- Add interval workout columns to workouts table
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS is_interval BOOLEAN DEFAULT false;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS interval_type TEXT; -- tabata, emom, amrap, custom
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS work_seconds INTEGER; -- Work phase duration
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS rest_seconds INTEGER; -- Rest phase duration
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS total_rounds INTEGER; -- Total rounds

-- Add constraint for valid interval types
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_interval_type_check;
ALTER TABLE workouts ADD CONSTRAINT workouts_interval_type_check
    CHECK (interval_type IS NULL OR interval_type IN ('tabata', 'emom', 'amrap', 'custom'));

-- Create HIIT workout templates table
CREATE TABLE IF NOT EXISTS hiit_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    interval_type TEXT NOT NULL CHECK (interval_type IN ('tabata', 'emom', 'amrap', 'custom')),
    work_seconds INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL,
    total_rounds INTEGER NOT NULL,
    difficulty TEXT DEFAULT 'intermediate',
    estimated_duration_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default HIIT templates
INSERT INTO hiit_templates (name, description, interval_type, work_seconds, rest_seconds, total_rounds, difficulty, estimated_duration_minutes)
VALUES
    ('Tabata Classic', 'Traditional Tabata protocol: 20s work, 10s rest, 8 rounds', 'tabata', 20, 10, 8, 'advanced', 4),
    ('EMOM 10', 'Every Minute On the Minute for 10 minutes', 'emom', 50, 10, 10, 'intermediate', 10),
    ('AMRAP 15', 'As Many Rounds As Possible in 15 minutes', 'amrap', 60, 0, 15, 'intermediate', 15),
    ('30-30 Intervals', '30 seconds work, 30 seconds rest', 'custom', 30, 30, 10, 'beginner', 10),
    ('45-15 Intervals', '45 seconds work, 15 seconds rest (advanced)', 'custom', 45, 15, 12, 'advanced', 12)
ON CONFLICT DO NOTHING;

-- Create a view for exercises that should NEVER be in interval workouts
-- (static holds are dangerous during high-intensity intervals)
CREATE OR REPLACE VIEW static_hold_exercises AS
SELECT id, name
FROM exercises
WHERE LOWER(name) LIKE '%hold%'
   OR LOWER(name) LIKE '%plank%'
   OR LOWER(name) LIKE '%wall sit%'
   OR LOWER(name) LIKE '%dead hang%'
   OR LOWER(name) LIKE '%isometric%'
   OR LOWER(name) LIKE '%static%'
   OR LOWER(name) LIKE '%l-sit%'
   OR LOWER(name) LIKE '%hollow%'
   OR movement_type = 'static';

-- Create function to validate HIIT workouts don't contain static holds
CREATE OR REPLACE FUNCTION validate_hiit_no_static_holds(p_workout_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_interval BOOLEAN;
    v_has_static_holds BOOLEAN;
BEGIN
    -- Check if this is an interval workout
    SELECT is_interval INTO v_is_interval
    FROM workouts
    WHERE id = p_workout_id;

    IF v_is_interval IS NOT TRUE THEN
        -- Not an interval workout, skip validation
        RETURN TRUE;
    END IF;

    -- Check if any exercises are static holds
    SELECT EXISTS (
        SELECT 1
        FROM workout_exercises we
        WHERE we.workout_id = p_workout_id
        AND (
            LOWER(we.exercise_name) LIKE '%hold%'
            OR LOWER(we.exercise_name) LIKE '%plank%'
            OR LOWER(we.exercise_name) LIKE '%wall sit%'
            OR LOWER(we.exercise_name) LIKE '%isometric%'
            OR LOWER(we.exercise_name) LIKE '%static%'
        )
    ) INTO v_has_static_holds;

    -- Return FALSE if static holds found in interval workout (validation fails)
    RETURN NOT v_has_static_holds;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add index for interval workout queries
CREATE INDEX IF NOT EXISTS idx_workouts_is_interval ON workouts(is_interval) WHERE is_interval = true;
CREATE INDEX IF NOT EXISTS idx_workouts_interval_type ON workouts(interval_type);

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '095_hiit_interval_workouts',
    NOW(),
    'Added HIIT/interval workout support with static hold prevention for safety'
) ON CONFLICT DO NOTHING;

COMMENT ON COLUMN workouts.is_interval IS 'Whether this is a HIIT/interval workout';
COMMENT ON COLUMN workouts.interval_type IS 'Type of interval: tabata, emom, amrap, or custom';
COMMENT ON VIEW static_hold_exercises IS 'Exercises that should NEVER be in interval workouts for safety';
