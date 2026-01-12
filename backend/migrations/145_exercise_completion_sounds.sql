-- Migration: 145_exercise_completion_sounds.sql
-- Add exercise completion sound preferences (separate from workout completion)
-- This allows users to customize the chime that plays when all sets of an exercise are done

-- Add exercise completion sound columns to sound_preferences table
ALTER TABLE sound_preferences
ADD COLUMN IF NOT EXISTS exercise_completion_sound_enabled BOOLEAN DEFAULT true;

ALTER TABLE sound_preferences
ADD COLUMN IF NOT EXISTS exercise_completion_sound_type TEXT DEFAULT 'chime';

-- Add constraint for valid exercise completion sound types
-- Options: chime, bell, ding, pop, whoosh, none
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sound_preferences_exercise_completion_type_check'
    ) THEN
        ALTER TABLE sound_preferences
        ADD CONSTRAINT sound_preferences_exercise_completion_type_check
        CHECK (exercise_completion_sound_type IN ('chime', 'bell', 'ding', 'pop', 'whoosh', 'none'));
    END IF;
END $$;

-- Update updated_at trigger to include new columns (already exists from migration 093)

-- Log migration
INSERT INTO migration_log (migration_name, applied_at, description)
VALUES (
    '145_exercise_completion_sounds',
    NOW(),
    'Added exercise completion sound preferences - separate chime selection for when all sets of an exercise are done'
) ON CONFLICT DO NOTHING;

COMMENT ON COLUMN sound_preferences.exercise_completion_sound_enabled IS 'Whether to play sound when all sets of an exercise are completed';
COMMENT ON COLUMN sound_preferences.exercise_completion_sound_type IS 'Sound type for exercise completion: chime, bell, ding, pop, whoosh, none';
