-- Migration: Add location fields to gym_profiles table
-- Purpose: Enable location-based automatic gym profile switching
-- Date: 2026-02-01

-- =============================================================================
-- ADD LOCATION COLUMNS TO GYM_PROFILES
-- =============================================================================

-- Add address field for display purposes
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS address VARCHAR(255);

-- Add city for easier filtering/display
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS city VARCHAR(100);

-- Add latitude and longitude for geofencing
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;

ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Add Google Place ID for future integrations
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS place_id VARCHAR(255);

-- Add radius for geofencing (default 100 meters)
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS location_radius_meters INTEGER DEFAULT 100;

-- Add per-profile auto-switch toggle
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS auto_switch_enabled BOOLEAN DEFAULT true;

-- =============================================================================
-- ADD INDEXES FOR LOCATION QUERIES
-- =============================================================================

-- Index for finding profiles with locations (for auto-switch feature)
CREATE INDEX IF NOT EXISTS idx_gym_profiles_has_location
ON gym_profiles (user_id)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON COLUMN gym_profiles.address IS 'Full address of the gym location (e.g., "123 Main St, City, State 12345")';
COMMENT ON COLUMN gym_profiles.city IS 'City name for display purposes';
COMMENT ON COLUMN gym_profiles.latitude IS 'GPS latitude coordinate for geofencing';
COMMENT ON COLUMN gym_profiles.longitude IS 'GPS longitude coordinate for geofencing';
COMMENT ON COLUMN gym_profiles.place_id IS 'Google Places ID for the location';
COMMENT ON COLUMN gym_profiles.location_radius_meters IS 'Radius in meters for geofence detection (default 100m)';
COMMENT ON COLUMN gym_profiles.auto_switch_enabled IS 'Whether to auto-switch to this profile when user arrives at location';
