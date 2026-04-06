-- Migration 1897: Fix claim_daily_crate function overload
-- Migration 1896 created a 3-param version but the old 2-param version from
-- migration 230 still exists, causing PostgREST ambiguity errors (500).
-- Also removes nested 'reward' JSONB from the return to avoid Supabase client
-- JSON serialization issues (same fix migration 230 originally applied).

-- Step 1: Drop the old 2-param overload
DROP FUNCTION IF EXISTS claim_daily_crate(UUID, VARCHAR);

-- Step 2: Recreate the 3-param version WITHOUT nested JSONB in return
CREATE OR REPLACE FUNCTION claim_daily_crate(
  p_user_id UUID,
  p_crate_type VARCHAR(20),
  p_crate_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_record user_daily_crates%ROWTYPE;
  v_reward JSONB;
  v_xp_reward INTEGER;
  v_roll INTEGER;
BEGIN
  -- Get the record for the specified date
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = p_crate_date;

  IF v_record.id IS NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'No crate available for this date');
  END IF;

  IF v_record.selected_crate IS NOT NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Crate already claimed for this date');
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
  v_roll := floor(random() * 100)::INTEGER + 1;

  CASE p_crate_type
    WHEN 'daily' THEN
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

  -- Return FLAT structure (no nested JSONB) to avoid Supabase client serialization issues
  RETURN jsonb_build_object(
    'success', TRUE,
    'crate_type', p_crate_type,
    'crate_date', p_crate_date,
    'reward_type', v_reward->>'type',
    'reward_amount', (v_reward->>'amount')::INTEGER,
    'message', 'Crate opened!'
  );
END;
$$;
