-- Migration: Add date_of_birth to users table
-- Created: 2025-12-04
-- Purpose: Store user's date of birth for age-appropriate workout generation

-- Add date_of_birth column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add index for querying by age ranges
CREATE INDEX IF NOT EXISTS idx_users_date_of_birth ON users(date_of_birth);

-- Comment for documentation
COMMENT ON COLUMN users.date_of_birth IS 'User date of birth for age-appropriate workout recommendations';
