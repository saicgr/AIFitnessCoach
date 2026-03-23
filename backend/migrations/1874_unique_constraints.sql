-- Migration 1874: Add UNIQUE constraints to prevent duplicate users
-- Date: 2026-03-23
-- Purpose: Prevent concurrent signup race conditions from creating
--          duplicate user rows with the same auth_id, email, or username.
--
-- SECURITY: Without these constraints, two concurrent signup requests
-- with the same email can both pass the "does user exist?" check before
-- either insert completes, resulting in duplicate accounts.

-- auth_id must be unique (one Supabase Auth user = one database user)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_auth_id_unique ON users(auth_id);

-- email must be unique (prevent duplicate accounts)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email);

-- username must be unique (prevent display name collisions)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_unique ON users(username);
