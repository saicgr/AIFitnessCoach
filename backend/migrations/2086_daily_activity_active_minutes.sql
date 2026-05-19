-- Add active_minutes to daily_activity.
--
-- The watch-sync ingest (api/v1/watch_sync.py) and activity_db reads already
-- referenced `active_minutes`, but the column never existed — so every watch
-- sync 500'd and /activity/history 500'd (Postgres 42703). This adds the real
-- column so the existing write/read paths become valid.
--
-- Source metric: HealthKit `appleExerciseTime` / Health Connect active minutes.

ALTER TABLE daily_activity
  ADD COLUMN IF NOT EXISTS active_minutes INTEGER DEFAULT 0;
