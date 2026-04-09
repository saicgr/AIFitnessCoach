-- Migration: Fix sync_latest_measurements_to_user to respect temporal order
-- Created: 2026-04-09
-- Purpose: The trigger was blindly updating users.weight_kg on every INSERT into
--          body_measurements, regardless of whether the new entry was chronologically
--          the latest. This caused stale/incorrect "current weight" when entries were
--          inserted out of order (e.g., onboarding seed + manual entry race condition).

CREATE OR REPLACE FUNCTION sync_latest_measurements_to_user()
RETURNS TRIGGER AS $$
DECLARE
    latest_measured_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Only update users table if this entry is the chronologically latest measurement.
    -- Without this check, inserting a backdated entry would overwrite the current weight.
    SELECT MAX(measured_at) INTO latest_measured_at
    FROM body_measurements
    WHERE user_id = NEW.user_id
      AND id != NEW.id;

    -- If there's no other entry, or this entry is the latest, sync to users table
    IF latest_measured_at IS NULL OR NEW.measured_at >= latest_measured_at THEN
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
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Re-create trigger (function replacement is in-place, but explicit for clarity)
DROP TRIGGER IF EXISTS trigger_sync_measurements_to_user ON body_measurements;
CREATE TRIGGER trigger_sync_measurements_to_user
    AFTER INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION sync_latest_measurements_to_user();
