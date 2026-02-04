-- ============================================================================
-- Migration 217: First-Time Bonuses System
-- ============================================================================
-- This migration creates the user_first_time_bonuses table to track
-- one-time XP bonuses awarded for first-time actions.
-- ============================================================================

-- Create the user_first_time_bonuses table
CREATE TABLE IF NOT EXISTS user_first_time_bonuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bonus_type VARCHAR(50) NOT NULL,
  xp_awarded INTEGER NOT NULL,
  awarded_at TIMESTAMPTZ DEFAULT NOW(),

  -- Each user can only receive each bonus type once
  UNIQUE(user_id, bonus_type)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_first_time_bonuses_user_id
ON user_first_time_bonuses(user_id);

CREATE INDEX IF NOT EXISTS idx_user_first_time_bonuses_type
ON user_first_time_bonuses(bonus_type);

-- Enable Row Level Security
ALTER TABLE user_first_time_bonuses ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only view their own bonuses
DROP POLICY IF EXISTS "Users can view own first time bonuses" ON user_first_time_bonuses;
CREATE POLICY "Users can view own first time bonuses"
ON user_first_time_bonuses
FOR SELECT
USING (user_id = auth.uid());

-- RLS Policy: Service role can insert bonuses (for backend to award bonuses)
DROP POLICY IF EXISTS "Service can insert first time bonuses" ON user_first_time_bonuses;
CREATE POLICY "Service can insert first time bonuses"
ON user_first_time_bonuses
FOR INSERT
WITH CHECK (true);

-- Grant access to authenticated users
GRANT SELECT ON user_first_time_bonuses TO authenticated;
GRANT INSERT ON user_first_time_bonuses TO authenticated;

-- Grant access to service role
GRANT ALL ON user_first_time_bonuses TO service_role;

-- Add comment
COMMENT ON TABLE user_first_time_bonuses IS 'Tracks one-time XP bonuses awarded for first-time actions (first workout, first meal log, etc.)';
COMMENT ON COLUMN user_first_time_bonuses.bonus_type IS 'Type of first-time bonus (e.g., first_workout, first_breakfast, first_weight_log)';
COMMENT ON COLUMN user_first_time_bonuses.xp_awarded IS 'Amount of XP awarded for this bonus';
