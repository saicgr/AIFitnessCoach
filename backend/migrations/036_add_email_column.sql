-- Migration: Add email column to users table
-- Created: 2025-12-25
-- Purpose: Store user email for Google OAuth and identification

-- Add email column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(320);

-- Add index for querying by email
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Comment for documentation
COMMENT ON COLUMN users.email IS 'User email address from OAuth provider or registration';
