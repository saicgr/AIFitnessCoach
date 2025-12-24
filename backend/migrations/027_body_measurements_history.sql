-- Migration: Body Measurements History
-- Created: 2025-12-24
-- Purpose: Track body measurements over time for progress graphs and trends

-- ============================================
-- body_measurements - Historical tracking of body metrics
-- ============================================
CREATE TABLE IF NOT EXISTS body_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Core measurements
    weight_kg DOUBLE PRECISION,
    body_fat_percent DOUBLE PRECISION,
    muscle_mass_kg DOUBLE PRECISION,

    -- Circumferences (in cm)
    chest_cm DOUBLE PRECISION,
    waist_cm DOUBLE PRECISION,
    hip_cm DOUBLE PRECISION,
    neck_cm DOUBLE PRECISION,
    bicep_left_cm DOUBLE PRECISION,
    bicep_right_cm DOUBLE PRECISION,
    forearm_left_cm DOUBLE PRECISION,
    forearm_right_cm DOUBLE PRECISION,
    thigh_left_cm DOUBLE PRECISION,
    thigh_right_cm DOUBLE PRECISION,
    calf_left_cm DOUBLE PRECISION,
    calf_right_cm DOUBLE PRECISION,
    shoulder_cm DOUBLE PRECISION,

    -- Calculated metrics (auto-computed)
    bmi DOUBLE PRECISION,
    waist_to_hip_ratio DOUBLE PRECISION,
    waist_to_height_ratio DOUBLE PRECISION,

    -- Health vitals
    resting_heart_rate INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,

    -- Progress tracking
    weight_change_kg DOUBLE PRECISION,  -- Change since last measurement
    body_fat_change DOUBLE PRECISION,   -- Change in body fat %

    -- Notes and context
    notes TEXT,
    measurement_source VARCHAR(50) DEFAULT 'manual',  -- 'manual', 'smart_scale', 'health_connect'

    -- Timestamps
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE body_measurements IS 'Historical body measurements for tracking progress over time';
COMMENT ON COLUMN body_measurements.weight_change_kg IS 'Calculated change from previous measurement';
COMMENT ON COLUMN body_measurements.measurement_source IS 'How measurement was recorded';

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_id ON body_measurements(user_id);
CREATE INDEX IF NOT EXISTS idx_body_measurements_measured_at ON body_measurements(measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date ON body_measurements(user_id, measured_at DESC);

-- Enable Row Level Security
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;

-- Users can only see their own measurements
DROP POLICY IF EXISTS body_measurements_select_policy ON body_measurements;
CREATE POLICY body_measurements_select_policy ON body_measurements
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own measurements
DROP POLICY IF EXISTS body_measurements_insert_policy ON body_measurements;
CREATE POLICY body_measurements_insert_policy ON body_measurements
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own measurements
DROP POLICY IF EXISTS body_measurements_update_policy ON body_measurements;
CREATE POLICY body_measurements_update_policy ON body_measurements
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own measurements
DROP POLICY IF EXISTS body_measurements_delete_policy ON body_measurements;
CREATE POLICY body_measurements_delete_policy ON body_measurements
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS body_measurements_service_policy ON body_measurements;
CREATE POLICY body_measurements_service_policy ON body_measurements
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- Function: Calculate changes from previous measurement
-- ============================================
CREATE OR REPLACE FUNCTION calculate_measurement_changes()
RETURNS TRIGGER AS $$
DECLARE
    prev_measurement RECORD;
    user_height_cm DOUBLE PRECISION;
BEGIN
    -- Get previous measurement
    SELECT * INTO prev_measurement
    FROM body_measurements
    WHERE user_id = NEW.user_id
      AND measured_at < NEW.measured_at
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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-calculate changes
DROP TRIGGER IF EXISTS trigger_calculate_measurement_changes ON body_measurements;
CREATE TRIGGER trigger_calculate_measurement_changes
    BEFORE INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION calculate_measurement_changes();

-- ============================================
-- Function: Update user's current measurements
-- ============================================
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to sync latest measurements to users table
DROP TRIGGER IF EXISTS trigger_sync_measurements_to_user ON body_measurements;
CREATE TRIGGER trigger_sync_measurements_to_user
    AFTER INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION sync_latest_measurements_to_user();

-- ============================================
-- View: Latest measurements per user
-- ============================================
CREATE OR REPLACE VIEW latest_body_measurements AS
SELECT DISTINCT ON (user_id)
    *
FROM body_measurements
ORDER BY user_id, measured_at DESC;

COMMENT ON VIEW latest_body_measurements IS 'Most recent body measurement for each user';
