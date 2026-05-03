-- Migration 1899: claim_daily_crate self-heals missing row for the requested date.
--
-- ROOT CAUSE: When a user's local day rolls forward (e.g. just past midnight in
-- their timezone), the home banner can still be reading a `dailyCratesProvider`
-- snapshot from the previous local day OR `init_daily_crates` for the new day
-- hasn't fired yet. The user taps "Open" → backend POSTs `claim_daily_crate`
-- with `p_crate_date = user's new local today`. No row exists for that date →
-- the function returned `success=false, message='No crate available for this date'`
-- and the UI showed the generic "Failed to claim crate" snackbar.
--
-- FIX: If no row exists for the requested date, INSERT a default daily-only
-- row inline (mirroring `init_daily_crates`'s default for daily=TRUE,
-- streak=streak>=7, activity=FALSE) and proceed. This makes the claim
-- idempotent and resilient to client-side staleness without relying on a
-- separate init RPC having been called first.
--
-- Streak/activity claims still fail-fast if those tiers aren't available.

DROP FUNCTION IF EXISTS claim_daily_crate(UUID, VARCHAR, DATE);

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
  v_streak INTEGER;
  v_streak_available BOOLEAN;
BEGIN
  -- Look up existing row for this date with row lock.
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = p_crate_date
  FOR UPDATE;

  -- Self-heal: if the row doesn't exist for this date, create a default one
  -- inline so the claim can proceed. This handles the local-day-rollover case
  -- where the client banner state is ahead of any init_daily_crates call.
  IF v_record.id IS NULL THEN
    SELECT COALESCE(current_streak, 0) INTO v_streak
    FROM user_login_streaks WHERE user_id = p_user_id;
    v_streak_available := COALESCE(v_streak, 0) >= 7;

    INSERT INTO user_daily_crates (
      user_id, crate_date,
      daily_crate_available,
      streak_crate_available,
      activity_crate_available
    ) VALUES (
      p_user_id, p_crate_date,
      TRUE,
      v_streak_available,
      FALSE  -- activity must be unlocked separately by completing daily goals
    )
    ON CONFLICT (user_id, crate_date) DO NOTHING
    RETURNING * INTO v_record;

    -- If ON CONFLICT skipped insert (concurrent init), re-select with lock.
    IF v_record.id IS NULL THEN
      SELECT * INTO v_record FROM user_daily_crates
      WHERE user_id = p_user_id AND crate_date = p_crate_date
      FOR UPDATE;
    END IF;
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

COMMENT ON FUNCTION claim_daily_crate(UUID, VARCHAR, DATE) IS
'Claim a daily crate. Picks 1 of 3 available crate tiers per day.
Migration 1898: FOR UPDATE row lock to prevent concurrent double-claims.
Migration 1899: Self-heal — auto-create row for requested date if missing
(handles local-day rollover where client banner runs ahead of init_daily_crates).';
