-- Migration: Consolidate Weight Logging into body_measurements
-- Created: 2025-02-02
-- Purpose: Add fasting-related columns to body_measurements table and create trigger
--          to auto-populate fasting context when weight is logged.
--          This eliminates the need for a separate weight_logs table.

-- ============================================
-- Phase 1: Add fasting-related columns
-- ============================================

-- Add fasting context columns to body_measurements
ALTER TABLE body_measurements ADD COLUMN IF NOT EXISTS is_fasting_day BOOLEAN DEFAULT false;
ALTER TABLE body_measurements ADD COLUMN IF NOT EXISTS fasting_record_id UUID REFERENCES fasting_records(id) ON DELETE SET NULL;
ALTER TABLE body_measurements ADD COLUMN IF NOT EXISTS fasting_protocol TEXT;
ALTER TABLE body_measurements ADD COLUMN IF NOT EXISTS fasting_duration_minutes INTEGER;
ALTER TABLE body_measurements ADD COLUMN IF NOT EXISTS days_since_last_fast INTEGER;

-- Add index for fasting queries
CREATE INDEX IF NOT EXISTS idx_body_measurements_fasting ON body_measurements(user_id, is_fasting_day);
CREATE INDEX IF NOT EXISTS idx_body_measurements_fasting_record ON body_measurements(fasting_record_id) WHERE fasting_record_id IS NOT NULL;

-- ============================================
-- Phase 2: Create trigger to auto-populate fasting context
-- ============================================

CREATE OR REPLACE FUNCTION populate_body_measurement_fasting_context()
RETURNS TRIGGER AS $$
DECLARE
    v_fasting_record RECORD;
    v_last_fast_date DATE;
    v_measurement_date DATE;
BEGIN
    -- Only process if weight_kg is being set
    IF NEW.weight_kg IS NULL THEN
        RETURN NEW;
    END IF;

    -- Get measurement date
    v_measurement_date := DATE(COALESCE(NEW.measured_at, NOW()));

    -- Find fasting record for this date (completed or active)
    SELECT
        id,
        protocol,
        actual_duration_minutes,
        COALESCE(actual_duration_minutes,
            EXTRACT(EPOCH FROM (COALESCE(end_time, NOW()) - start_time)) / 60
        )::INTEGER as duration_minutes
    INTO v_fasting_record
    FROM fasting_records
    WHERE user_id = NEW.user_id
      AND DATE(start_time) = v_measurement_date
      AND status IN ('completed', 'active')
    ORDER BY start_time DESC
    LIMIT 1;

    -- Set fasting context
    IF v_fasting_record IS NOT NULL THEN
        NEW.is_fasting_day := true;
        NEW.fasting_record_id := v_fasting_record.id;
        NEW.fasting_protocol := v_fasting_record.protocol;
        NEW.fasting_duration_minutes := v_fasting_record.duration_minutes;
    ELSE
        NEW.is_fasting_day := false;
        NEW.fasting_record_id := NULL;
        NEW.fasting_protocol := NULL;
        NEW.fasting_duration_minutes := NULL;
    END IF;

    -- Calculate days since last fast
    SELECT DATE(start_time) INTO v_last_fast_date
    FROM fasting_records
    WHERE user_id = NEW.user_id
      AND status = 'completed'
      AND DATE(start_time) < v_measurement_date
    ORDER BY start_time DESC
    LIMIT 1;

    IF v_last_fast_date IS NOT NULL THEN
        NEW.days_since_last_fast := v_measurement_date - v_last_fast_date;
    ELSE
        NEW.days_since_last_fast := NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Create the trigger (BEFORE INSERT OR UPDATE)
DROP TRIGGER IF EXISTS trigger_populate_fasting_context ON body_measurements;
CREATE TRIGGER trigger_populate_fasting_context
    BEFORE INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION populate_body_measurement_fasting_context();

-- ============================================
-- Phase 3: Update fasting_weight_correlation trigger to also watch body_measurements
-- ============================================

-- Create function to sync body_measurements weight to fasting_weight_correlation
CREATE OR REPLACE FUNCTION sync_body_measurement_to_fasting_correlation()
RETURNS TRIGGER AS $$
DECLARE
    v_measurement_date DATE;
    v_workout_completed BOOLEAN := false;
    v_workout_type TEXT;
BEGIN
    -- Only process if weight_kg is being set
    IF NEW.weight_kg IS NULL THEN
        RETURN NEW;
    END IF;

    v_measurement_date := DATE(COALESCE(NEW.measured_at, NOW()));

    -- Check for workout on this date
    SELECT true, type INTO v_workout_completed, v_workout_type
    FROM workouts
    WHERE user_id = NEW.user_id
      AND DATE(created_at) = v_measurement_date
      AND status = 'completed'
    LIMIT 1;

    -- Upsert into fasting_weight_correlation
    INSERT INTO fasting_weight_correlation (
        user_id,
        date,
        weight_kg,
        weight_logged_at,
        is_fasting_day,
        fasting_record_id,
        fasting_protocol,
        fasting_duration_minutes,
        fasting_completed_goal,
        days_since_last_fast,
        workout_completed_that_day,
        workout_type,
        notes
    )
    VALUES (
        NEW.user_id,
        v_measurement_date,
        NEW.weight_kg,
        COALESCE(NEW.measured_at, NOW()),
        COALESCE(NEW.is_fasting_day, false),
        NEW.fasting_record_id,
        NEW.fasting_protocol,
        NEW.fasting_duration_minutes,
        (SELECT completed_goal FROM fasting_records WHERE id = NEW.fasting_record_id),
        NEW.days_since_last_fast,
        COALESCE(v_workout_completed, false),
        v_workout_type,
        NEW.notes
    )
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        weight_kg = EXCLUDED.weight_kg,
        weight_logged_at = EXCLUDED.weight_logged_at,
        is_fasting_day = EXCLUDED.is_fasting_day,
        fasting_record_id = EXCLUDED.fasting_record_id,
        fasting_protocol = EXCLUDED.fasting_protocol,
        fasting_duration_minutes = EXCLUDED.fasting_duration_minutes,
        fasting_completed_goal = EXCLUDED.fasting_completed_goal,
        days_since_last_fast = EXCLUDED.days_since_last_fast,
        workout_completed_that_day = EXCLUDED.workout_completed_that_day,
        workout_type = EXCLUDED.workout_type,
        notes = EXCLUDED.notes;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Create the trigger (AFTER INSERT OR UPDATE)
DROP TRIGGER IF EXISTS trigger_sync_to_fasting_correlation ON body_measurements;
CREATE TRIGGER trigger_sync_to_fasting_correlation
    AFTER INSERT OR UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION sync_body_measurement_to_fasting_correlation();

-- ============================================
-- Phase 4: Migrate existing weight_logs data
-- ============================================

-- Insert weight_logs data into body_measurements where no entry exists for that date
INSERT INTO body_measurements (user_id, weight_kg, measured_at, measurement_source, notes, created_at)
SELECT
    wl.user_id,
    wl.weight_kg,
    wl.logged_at as measured_at,
    wl.source as measurement_source,
    wl.notes,
    wl.created_at
FROM weight_logs wl
WHERE NOT EXISTS (
    SELECT 1 FROM body_measurements bm
    WHERE bm.user_id = wl.user_id
    AND DATE(bm.measured_at) = DATE(wl.logged_at)
    AND bm.weight_kg IS NOT NULL
)
ON CONFLICT DO NOTHING;

-- ============================================
-- Phase 5: Add comment indicating deprecation
-- ============================================

COMMENT ON TABLE weight_logs IS 'DEPRECATED: Weight logging has been consolidated into body_measurements table. This table is kept for historical reference only. New weight logs should use body_measurements.';

-- Note: We keep the weight_logs table and its trigger for now as a fallback.
-- The old trigger will continue to work, and both tables will receive data
-- until we verify the new system is working correctly.
