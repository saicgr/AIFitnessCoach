-- Migration 149: Admin Role System
-- Adds role-based access control and support user functionality

-- Add role column to users table (default 'user')
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';

-- Add constraint for valid roles
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_role_check'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_role_check
            CHECK (role IN ('user', 'admin'));
    END IF;
END $$;

-- Add is_support_user flag (identifies the special support account that cannot be unfriended)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_support_user BOOLEAN DEFAULT false;

-- Create indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_support_user ON users(is_support_user) WHERE is_support_user = true;

-- Create helper function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND role = 'admin');
END;
$$;

-- Create helper function to get support user ID
CREATE OR REPLACE FUNCTION get_support_user_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN (SELECT id FROM users WHERE is_support_user = true LIMIT 1);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_support_user_id() TO authenticated;
