-- Add apps column to users table to track which apps a user uses
-- Values: 'fitwiz', 'ahaara' (text array)
ALTER TABLE users ADD COLUMN IF NOT EXISTS apps TEXT[] DEFAULT '{}';

-- Index for filtering users by app
CREATE INDEX IF NOT EXISTS idx_users_apps ON users USING GIN (apps);

-- Backfill: existing users with workout_logs are Zealova users
UPDATE users SET apps = array_append(apps, 'fitwiz')
WHERE id IN (SELECT DISTINCT user_id FROM workout_logs)
AND NOT ('fitwiz' = ANY(apps));

-- Backfill: existing users with food_logs are Ahaara users
UPDATE users SET apps = array_append(apps, 'ahaara')
WHERE id IN (SELECT DISTINCT user_id FROM food_logs WHERE deleted_at IS NULL)
AND NOT ('ahaara' = ANY(apps));
