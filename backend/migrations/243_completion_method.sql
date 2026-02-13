-- Add completion_method column to workouts table
-- Values: 'tracked' (completed via active workout tracking), 'marked_done' (quick mark from hero card)
-- NULL for legacy completed workouts (treated as 'tracked')
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS completion_method VARCHAR DEFAULT NULL;
