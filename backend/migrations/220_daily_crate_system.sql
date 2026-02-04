-- ============================================================================
-- Migration 220: Daily Crate System
-- ============================================================================
-- This migration creates the daily crate system where users can choose
-- 1 of 3 mystery crates (daily, streak, or activity) each day.
-- ============================================================================

-- Create the user_daily_crates table
CREATE TABLE IF NOT EXISTS user_daily_crates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  crate_date DATE NOT NULL,

  -- Availability flags (determined on login)
  daily_crate_available BOOLEAN DEFAULT TRUE,
  streak_crate_available BOOLEAN DEFAULT FALSE,
  activity_crate_available BOOLEAN DEFAULT FALSE,

  -- Claim status (user picks 1 of available)
  selected_crate VARCHAR(20) CHECK (selected_crate IN ('daily', 'streak', 'activity')),
  reward JSONB,
  claimed_at TIMESTAMPTZ,

  -- Tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Each user can only have one record per day
  UNIQUE(user_id, crate_date)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_daily_crates_user_date
ON user_daily_crates(user_id, crate_date);

CREATE INDEX IF NOT EXISTS idx_user_daily_crates_unclaimed
ON user_daily_crates(user_id, crate_date) WHERE selected_crate IS NULL;

-- Enable RLS
ALTER TABLE user_daily_crates ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own daily crates" ON user_daily_crates;
CREATE POLICY "Users can view own daily crates"
ON user_daily_crates
FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Service can manage daily crates" ON user_daily_crates;
CREATE POLICY "Service can manage daily crates"
ON user_daily_crates
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant access
GRANT SELECT ON user_daily_crates TO authenticated;
GRANT ALL ON user_daily_crates TO service_role;

-- ============================================================================
-- Function to initialize daily crates for a user (called on login)
-- ============================================================================
CREATE OR REPLACE FUNCTION init_daily_crates(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_streak INTEGER;
  v_daily_goals RECORD;
  v_record user_daily_crates%ROWTYPE;
  v_streak_available BOOLEAN;
  v_activity_available BOOLEAN;
BEGIN
  -- Get current streak from user_login_streaks (not user_xp)
  SELECT COALESCE(current_streak, 0) INTO v_streak
  FROM user_login_streaks WHERE user_id = p_user_id;

  -- Streak crate available if streak >= 7
  v_streak_available := COALESCE(v_streak, 0) >= 7;

  -- Check if record exists for today
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = v_today;

  IF v_record.id IS NOT NULL THEN
    -- Record exists, return it
    RETURN jsonb_build_object(
      'daily_crate_available', v_record.daily_crate_available,
      'streak_crate_available', v_record.streak_crate_available,
      'activity_crate_available', v_record.activity_crate_available,
      'selected_crate', v_record.selected_crate,
      'reward', v_record.reward,
      'claimed', v_record.selected_crate IS NOT NULL,
      'claimed_at', v_record.claimed_at,
      'crate_date', v_today
    );
  END IF;

  -- Create today's crate entry
  INSERT INTO user_daily_crates (
    user_id, crate_date,
    daily_crate_available,
    streak_crate_available,
    activity_crate_available
  ) VALUES (
    p_user_id, v_today,
    TRUE,
    v_streak_available,
    FALSE  -- Will be updated when all daily goals complete
  )
  RETURNING * INTO v_record;

  RETURN jsonb_build_object(
    'daily_crate_available', v_record.daily_crate_available,
    'streak_crate_available', v_record.streak_crate_available,
    'activity_crate_available', v_record.activity_crate_available,
    'selected_crate', v_record.selected_crate,
    'reward', v_record.reward,
    'claimed', FALSE,
    'claimed_at', NULL,
    'crate_date', v_today
  );
END;
$$;

-- ============================================================================
-- Function to update activity crate availability
-- (Called when all daily goals are complete)
-- ============================================================================
CREATE OR REPLACE FUNCTION update_activity_crate_availability(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
BEGIN
  UPDATE user_daily_crates
  SET activity_crate_available = TRUE
  WHERE user_id = p_user_id
    AND crate_date = v_today
    AND selected_crate IS NULL;  -- Only if not already claimed

  RETURN FOUND;
END;
$$;

-- ============================================================================
-- Function to claim a daily crate
-- ============================================================================
CREATE OR REPLACE FUNCTION claim_daily_crate(
  p_user_id UUID,
  p_crate_type VARCHAR(20)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_record user_daily_crates%ROWTYPE;
  v_reward JSONB;
  v_xp_reward INTEGER;
  v_roll INTEGER;
BEGIN
  -- Get today's record
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = v_today;

  IF v_record.id IS NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'No crate available today');
  END IF;

  IF v_record.selected_crate IS NOT NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Crate already claimed today');
  END IF;

  -- Verify crate type is available
  IF p_crate_type = 'daily' AND NOT v_record.daily_crate_available THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Daily crate not available');
  END IF;
  IF p_crate_type = 'streak' AND NOT v_record.streak_crate_available THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Streak crate not available (need 7+ day streak)');
  END IF;
  IF p_crate_type = 'activity' AND NOT v_record.activity_crate_available THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Activity crate not available (complete all daily goals)');
  END IF;

  -- Roll for reward based on crate tier
  -- Higher tier = better rewards (activity > streak > daily)
  v_roll := floor(random() * 100)::INTEGER + 1;

  CASE p_crate_type
    WHEN 'daily' THEN
      -- Daily: 25-75 XP, small chance of shield
      IF v_roll <= 60 THEN
        v_xp_reward := 25 + floor(random() * 25)::INTEGER;
        v_reward := jsonb_build_object('type', 'xp', 'amount', v_xp_reward);
      ELSIF v_roll <= 90 THEN
        v_xp_reward := 50 + floor(random() * 25)::INTEGER;
        v_reward := jsonb_build_object('type', 'xp', 'amount', v_xp_reward);
      ELSE
        v_reward := jsonb_build_object('type', 'streak_shield', 'amount', 1);
      END IF;

    WHEN 'streak' THEN
      -- Streak: 50-150 XP, good chance of items
      IF v_roll <= 40 THEN
        v_xp_reward := 75 + floor(random() * 50)::INTEGER;
        v_reward := jsonb_build_object('type', 'xp', 'amount', v_xp_reward);
      ELSIF v_roll <= 70 THEN
        v_xp_reward := 100 + floor(random() * 50)::INTEGER;
        v_reward := jsonb_build_object('type', 'xp', 'amount', v_xp_reward);
      ELSIF v_roll <= 90 THEN
        v_reward := jsonb_build_object('type', 'streak_shield', 'amount', 1);
      ELSE
        v_reward := jsonb_build_object('type', 'xp_token_2x', 'amount', 1);
      END IF;

    WHEN 'activity' THEN
      -- Activity: 100-250 XP, high chance of items
      IF v_roll <= 30 THEN
        v_xp_reward := 150 + floor(random() * 50)::INTEGER;
        v_reward := jsonb_build_object('type', 'xp', 'amount', v_xp_reward);
      ELSIF v_roll <= 50 THEN
        v_xp_reward := 200 + floor(random() * 50)::INTEGER;
        v_reward := jsonb_build_object('type', 'xp', 'amount', v_xp_reward);
      ELSIF v_roll <= 75 THEN
        v_reward := jsonb_build_object('type', 'streak_shield', 'amount', 2);
      ELSIF v_roll <= 95 THEN
        v_reward := jsonb_build_object('type', 'xp_token_2x', 'amount', 1);
      ELSE
        v_reward := jsonb_build_object('type', 'fitness_crate', 'amount', 1);
      END IF;

    ELSE
      RETURN jsonb_build_object('success', FALSE, 'message', 'Invalid crate type');
  END CASE;

  -- Update record with claim
  UPDATE user_daily_crates
  SET selected_crate = p_crate_type,
      reward = v_reward,
      claimed_at = NOW()
  WHERE id = v_record.id;

  -- Award the reward
  IF (v_reward->>'type') = 'xp' THEN
    PERFORM award_xp(
      p_user_id,
      (v_reward->>'amount')::INTEGER,
      'daily_crate',
      p_crate_type,
      'Daily crate reward',
      FALSE
    );
  ELSE
    PERFORM add_consumable(
      p_user_id,
      v_reward->>'type',
      (v_reward->>'amount')::INTEGER
    );
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'crate_type', p_crate_type,
    'reward', v_reward,
    'message', 'Crate opened!'
  );
END;
$$;

-- Add comments
COMMENT ON TABLE user_daily_crates IS 'Tracks daily crate selection and rewards (pick 1 of 3: daily, streak, or activity)';
COMMENT ON COLUMN user_daily_crates.daily_crate_available IS 'Always true on login';
COMMENT ON COLUMN user_daily_crates.streak_crate_available IS 'True if user has 7+ day streak';
COMMENT ON COLUMN user_daily_crates.activity_crate_available IS 'True if all daily goals are complete';
COMMENT ON COLUMN user_daily_crates.selected_crate IS 'The crate type the user selected (can only pick 1 per day)';
