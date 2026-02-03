-- Migration: Sync Initial Weight from Onboarding to body_measurements
-- Created: 2025-02-02
-- Purpose: Automatically create a body_measurements entry when a user's weight
--          is first set during onboarding, establishing a baseline for progress tracking.

-- ============================================
-- Function: Create initial body_measurements entry from onboarding
-- ============================================

CREATE OR REPLACE FUNCTION sync_user_weight_to_body_measurements()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when weight_kg is being set (INSERT or UPDATE from NULL to a value)
    -- and the user doesn't already have a body_measurements entry
    IF NEW.weight_kg IS NOT NULL AND (OLD IS NULL OR OLD.weight_kg IS NULL) THEN
        -- Check if user already has any body_measurements entries
        IF NOT EXISTS (
            SELECT 1 FROM body_measurements
            WHERE user_id = NEW.id
            AND weight_kg IS NOT NULL
            LIMIT 1
        ) THEN
            -- Create initial body_measurements entry with onboarding data
            INSERT INTO body_measurements (
                user_id,
                weight_kg,
                waist_cm,
                hip_cm,
                neck_cm,
                body_fat_percent,
                resting_heart_rate,
                blood_pressure_systolic,
                blood_pressure_diastolic,
                measurement_source,
                notes,
                measured_at,
                created_at
            ) VALUES (
                NEW.id,
                NEW.weight_kg,
                NEW.waist_circumference_cm,
                NEW.hip_circumference_cm,
                NEW.neck_circumference_cm,
                NEW.body_fat_percent,
                NEW.resting_heart_rate,
                NEW.blood_pressure_systolic,
                NEW.blood_pressure_diastolic,
                'onboarding',
                'Initial measurement from onboarding',
                COALESCE(NEW.onboarding_completed_at, NOW()),
                NOW()
            );

            RAISE NOTICE 'Created initial body_measurements entry for user %', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Create trigger on users table (AFTER INSERT OR UPDATE)
DROP TRIGGER IF EXISTS trigger_sync_initial_weight_to_body_measurements ON users;
CREATE TRIGGER trigger_sync_initial_weight_to_body_measurements
    AFTER INSERT OR UPDATE OF weight_kg ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_weight_to_body_measurements();

COMMENT ON FUNCTION sync_user_weight_to_body_measurements() IS
'Automatically creates a body_measurements entry when a user first sets their weight during onboarding, establishing a baseline for progress tracking.';

-- ============================================
-- Backfill: Create body_measurements entries for existing users
-- who have weight_kg but no body_measurements records
-- ============================================

INSERT INTO body_measurements (
    user_id,
    weight_kg,
    waist_cm,
    hip_cm,
    neck_cm,
    body_fat_percent,
    resting_heart_rate,
    blood_pressure_systolic,
    blood_pressure_diastolic,
    measurement_source,
    notes,
    measured_at,
    created_at
)
SELECT
    u.id,
    u.weight_kg,
    u.waist_circumference_cm,
    u.hip_circumference_cm,
    u.neck_circumference_cm,
    u.body_fat_percent,
    u.resting_heart_rate,
    u.blood_pressure_systolic,
    u.blood_pressure_diastolic,
    'onboarding',
    'Initial measurement from onboarding (backfill)',
    COALESCE(u.onboarding_completed_at, u.created_at, NOW()),
    NOW()
FROM users u
WHERE u.weight_kg IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM body_measurements bm
      WHERE bm.user_id = u.id
      AND bm.weight_kg IS NOT NULL
  );
