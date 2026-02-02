-- Migration: Fix sync_latest_measurements_to_user trigger column name
-- Created: 2025-02-02
-- Purpose: Fix the trigger that references 'body_fat_percentage' instead of 'body_fat_percent'

-- Drop and recreate the function with correct column name
CREATE OR REPLACE FUNCTION sync_latest_measurements_to_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Update users table with latest measurements
    UPDATE users
    SET
        weight_kg = COALESCE(NEW.weight_kg, weight_kg),
        body_fat_percent = COALESCE(NEW.body_fat_percent, body_fat_percent),
        waist_circumference_cm = COALESCE(NEW.waist_cm, waist_circumference_cm),
        hip_circumference_cm = COALESCE(NEW.hip_cm, hip_circumference_cm),
        neck_circumference_cm = COALESCE(NEW.neck_cm, neck_circumference_cm),
        resting_heart_rate = COALESCE(NEW.resting_heart_rate, resting_heart_rate),
        blood_pressure_systolic = COALESCE(NEW.blood_pressure_systolic, blood_pressure_systolic),
        blood_pressure_diastolic = COALESCE(NEW.blood_pressure_diastolic, blood_pressure_diastolic)
    WHERE id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_sync_measurements_to_user ON body_measurements;
CREATE TRIGGER trigger_sync_measurements_to_user
    AFTER INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION sync_latest_measurements_to_user();
