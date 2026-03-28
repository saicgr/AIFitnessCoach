-- Add workout_weight_unit column to users table
-- Stores the user's preferred unit for workout weights (lbs/kg)
-- Separate from weight_unit which is for body weight/measurements
ALTER TABLE users ADD COLUMN IF NOT EXISTS workout_weight_unit TEXT DEFAULT NULL;

-- Comment for documentation
COMMENT ON COLUMN users.workout_weight_unit IS 'User preferred unit for workout weights (lbs or kg). Separate from weight_unit (body measurements). NULL falls back to weight_unit.';
