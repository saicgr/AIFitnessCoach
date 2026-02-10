-- Add comprehensive health metrics columns to daily_activity
-- Supports HRV, vitals, sleep phases, hydration from Health Connect / Apple Health

ALTER TABLE daily_activity
  ADD COLUMN IF NOT EXISTS hrv DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS blood_oxygen DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS body_temperature DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS respiratory_rate INTEGER,
  ADD COLUMN IF NOT EXISTS flights_climbed INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS basal_calories DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS deep_sleep_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS light_sleep_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS awake_sleep_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS rem_sleep_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS water_ml INTEGER DEFAULT 0;
