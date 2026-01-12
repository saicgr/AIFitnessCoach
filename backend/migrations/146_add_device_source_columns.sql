-- Migration: Add device_source columns to track WearOS vs phone data
-- Created: 2026-01-11
-- Purpose: Distinguish data logged from WearOS watch vs phone app

-- Add device_source to workout_logs
ALTER TABLE workout_logs ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';

-- Add device_source to performance_logs
ALTER TABLE performance_logs ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';

-- Add device_source to cardio_sessions (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cardio_sessions') THEN
        ALTER TABLE cardio_sessions ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';
    END IF;
END $$;

-- Add device_source to food_logs
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';

-- Add device_source to weight_logs
ALTER TABLE weight_logs ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';

-- Add device_source to fasting_sessions (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fasting_sessions') THEN
        ALTER TABLE fasting_sessions ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';
    END IF;
END $$;

-- Add device_source to workouts table (for completion tracking)
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS device_source VARCHAR(20) DEFAULT 'phone';

-- Add comments for documentation
COMMENT ON COLUMN workout_logs.device_source IS 'Source device: watch, phone, web, manual';
COMMENT ON COLUMN performance_logs.device_source IS 'Source device: watch, phone, web, manual';
COMMENT ON COLUMN food_logs.device_source IS 'Source device: watch, phone, web, manual';
COMMENT ON COLUMN weight_logs.device_source IS 'Source device: watch, phone, web, manual';
COMMENT ON COLUMN workouts.device_source IS 'Source device where workout was completed: watch, phone';

-- Add comments for optional tables (if they exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cardio_sessions') THEN
        COMMENT ON COLUMN cardio_sessions.device_source IS 'Source device: watch, phone, web, manual';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fasting_sessions') THEN
        COMMENT ON COLUMN fasting_sessions.device_source IS 'Source device: watch, phone, web, manual';
    END IF;
END $$;

-- Create index for device_source queries (useful for analytics)
CREATE INDEX IF NOT EXISTS idx_workout_logs_device_source ON workout_logs(device_source);
CREATE INDEX IF NOT EXISTS idx_food_logs_device_source ON food_logs(device_source);

-- Create index for fasting_sessions if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fasting_sessions') THEN
        CREATE INDEX IF NOT EXISTS idx_fasting_sessions_device_source ON fasting_sessions(device_source);
    END IF;
END $$;
