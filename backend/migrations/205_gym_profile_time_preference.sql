-- Migration: Add time preference fields to gym_profiles table
-- Purpose: Enable time-based automatic gym profile switching
-- Date: 2026-02-01

-- =============================================================================
-- ADD TIME PREFERENCE COLUMNS TO GYM_PROFILES
-- =============================================================================

-- Add preferred time slot field
-- Values: 'early_morning', 'morning', 'afternoon', 'evening', 'night', null
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS preferred_time_slot VARCHAR(20);

-- Add per-profile time-based auto-switch toggle
ALTER TABLE gym_profiles
ADD COLUMN IF NOT EXISTS time_auto_switch_enabled BOOLEAN DEFAULT true;

-- =============================================================================
-- ADD INDEX FOR TIME-BASED QUERIES
-- =============================================================================

-- Index for finding profiles with time preferences (for auto-switch feature)
CREATE INDEX IF NOT EXISTS idx_gym_profiles_time_slot
ON gym_profiles (user_id, preferred_time_slot)
WHERE preferred_time_slot IS NOT NULL;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON COLUMN gym_profiles.preferred_time_slot IS 'Preferred workout time slot: early_morning (5-7 AM), morning (7-11 AM), afternoon (11 AM-4 PM), evening (4-8 PM), night (8 PM-12 AM)';
COMMENT ON COLUMN gym_profiles.time_auto_switch_enabled IS 'Whether to auto-switch to this profile during the preferred time slot';
