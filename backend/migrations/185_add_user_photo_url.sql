-- Migration: Add photo_url column to users table
-- Created: 2025-02-01
-- Description: Adds photo_url column to store user profile photos in S3

-- Add photo_url column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Add index for quick lookups (optional, but good for queries)
CREATE INDEX IF NOT EXISTS idx_users_photo_url ON users(photo_url) WHERE photo_url IS NOT NULL;

-- Comment for documentation
COMMENT ON COLUMN users.photo_url IS 'URL to user profile photo stored in S3';
