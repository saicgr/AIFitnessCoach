-- Migration: Add timezone field to users table for per-user timezone consistency
-- This ensures all time-based features (workouts, notifications, summaries)
-- respect the user's local timezone

-- Add timezone column to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'UTC';

-- Add comment explaining the field
COMMENT ON COLUMN users.timezone IS 'IANA timezone identifier (e.g., America/New_York, Europe/London, Asia/Kolkata)';

-- Create index for timezone queries (e.g., grouping users by timezone for batch notifications)
CREATE INDEX IF NOT EXISTS idx_users_timezone ON users(timezone);

-- Update RLS policy to allow users to update their own timezone
-- (existing policies should already cover this since it's a user field)

-- Common timezone values for reference:
-- UTC, America/New_York, America/Chicago, America/Denver, America/Los_Angeles
-- Europe/London, Europe/Paris, Europe/Berlin, Asia/Tokyo, Asia/Shanghai
-- Asia/Kolkata, Asia/Dubai, Australia/Sydney, Pacific/Auckland
