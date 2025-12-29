-- Migration 052: Add custom_equipment column to users table
-- Purpose: Allow users to add custom equipment not in the predefined list
-- The custom equipment will be merged with standard equipment when passed to Gemini

-- Add custom_equipment column (JSON array stored as text)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS custom_equipment TEXT DEFAULT '[]';

-- Add comment for documentation
COMMENT ON COLUMN users.custom_equipment IS 'JSON array of user-added equipment names not in the predefined list. Merged with standard equipment when generating workouts.';

-- Create index for users who have custom equipment (sparse index)
CREATE INDEX IF NOT EXISTS idx_users_has_custom_equipment
ON users ((custom_equipment IS NOT NULL AND custom_equipment != '[]'))
WHERE custom_equipment IS NOT NULL AND custom_equipment != '[]';
