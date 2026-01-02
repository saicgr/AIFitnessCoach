-- Migration: 125_unique_usernames.sql
-- Description: Add unique username column for social search
-- The username column already exists but we need to:
-- 1. Generate usernames for existing users who don't have one
-- 2. Add a unique index

-- Step 1: Update existing users without username
-- Generate usernames from name or email (simple format: NameXXXX)
UPDATE users
SET username = CONCAT(
    COALESCE(
        -- Use first 8 chars of name (cleaned)
        SUBSTRING(REGEXP_REPLACE(COALESCE(name, ''), '[^a-zA-Z]', '', 'g'), 1, 8),
        -- Or use email prefix if no name
        SUBSTRING(SPLIT_PART(email, '@', 1), 1, 8),
        -- Fallback
        'User'
    ),
    -- Add random 4-digit suffix
    LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
)
WHERE username IS NULL OR username = '';

-- Step 2: Create unique index on username (if not exists)
-- Using CREATE INDEX IF NOT EXISTS with unique on lower case for case-insensitive uniqueness
DO $$
BEGIN
    -- First drop any existing non-unique index on username
    DROP INDEX IF EXISTS idx_users_username;
    DROP INDEX IF EXISTS idx_users_username_lower;

    -- Create unique index on lowercase username
    CREATE UNIQUE INDEX idx_users_username_unique ON users (LOWER(username))
    WHERE username IS NOT NULL AND username != '';

    RAISE NOTICE '✅ Created unique index on username';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE 'Index already exists, skipping';
END $$;

-- Step 3: Add comment for documentation
COMMENT ON COLUMN users.username IS 'Unique username for social features and friend search. Auto-generated during registration.';
