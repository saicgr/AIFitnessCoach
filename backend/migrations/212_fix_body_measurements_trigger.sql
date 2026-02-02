-- Migration: Fix body_measurements trigger column name
-- Created: 2025-02-02
-- Purpose: Fix the trigger that references 'measurement_date' instead of 'measured_at'

-- Drop and recreate the function with correct column name
CREATE OR REPLACE FUNCTION calculate_measurement_changes()
RETURNS TRIGGER AS $$
DECLARE
    prev_measurement RECORD;
    user_height_cm DOUBLE PRECISION;
BEGIN
    -- Get previous measurement (using correct column name: measured_at)
    SELECT * INTO prev_measurement
    FROM body_measurements
    WHERE user_id = NEW.user_id
      AND measured_at < COALESCE(NEW.measured_at, NOW())
    ORDER BY measured_at DESC
    LIMIT 1;

    -- Calculate weight change
    IF prev_measurement IS NOT NULL AND NEW.weight_kg IS NOT NULL AND prev_measurement.weight_kg IS NOT NULL THEN
        NEW.weight_change_kg := NEW.weight_kg - prev_measurement.weight_kg;
    END IF;

    -- Calculate body fat change
    IF prev_measurement IS NOT NULL AND NEW.body_fat_percent IS NOT NULL AND prev_measurement.body_fat_percent IS NOT NULL THEN
        NEW.body_fat_change := NEW.body_fat_percent - prev_measurement.body_fat_percent;
    END IF;

    -- Get user's height for ratio calculations
    SELECT height_cm INTO user_height_cm
    FROM users
    WHERE id = NEW.user_id;

    -- Calculate BMI
    IF NEW.weight_kg IS NOT NULL AND user_height_cm IS NOT NULL THEN
        NEW.bmi := NEW.weight_kg / ((user_height_cm / 100.0) * (user_height_cm / 100.0));
    END IF;

    -- Calculate waist-to-hip ratio
    IF NEW.waist_cm IS NOT NULL AND NEW.hip_cm IS NOT NULL AND NEW.hip_cm > 0 THEN
        NEW.waist_to_hip_ratio := NEW.waist_cm / NEW.hip_cm;
    END IF;

    -- Calculate waist-to-height ratio
    IF NEW.waist_cm IS NOT NULL AND user_height_cm IS NOT NULL AND user_height_cm > 0 THEN
        NEW.waist_to_height_ratio := NEW.waist_cm / user_height_cm;
    END IF;

    -- Set measured_at to now if not provided
    IF NEW.measured_at IS NULL THEN
        NEW.measured_at := NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_calculate_measurement_changes ON body_measurements;
CREATE TRIGGER trigger_calculate_measurement_changes
    BEFORE INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION calculate_measurement_changes();
