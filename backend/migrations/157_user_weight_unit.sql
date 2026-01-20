-- Migration: Add weight_unit column to users table
-- This stores the user's preferred weight unit (kg or lbs)

ALTER TABLE users ADD COLUMN IF NOT EXISTS weight_unit VARCHAR(5) DEFAULT 'kg';

-- Add check constraint to ensure valid values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_weight_unit_check'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_weight_unit_check
        CHECK (weight_unit IN ('kg', 'lbs'));
    END IF;
END $$;

-- Comment for documentation
COMMENT ON COLUMN users.weight_unit IS 'User preferred weight unit: kg or lbs';
