-- ============================================================================
-- Migration 1898: XP Race Condition & Timezone Fixes
-- ============================================================================
-- Fixes:
--   1. Add FOR UPDATE row locks to prevent race conditions in concurrent requests
--   2. Add p_user_date parameter to replace CURRENT_DATE so user timezone is respected
--   3. Prevent double daily login XP, double crate claims, and consumable race conditions
--
-- Affected functions:
--   - process_daily_login: FOR UPDATE + p_user_date
--   - init_daily_crates: FOR UPDATE + p_user_date
--   - claim_daily_crate: FOR UPDATE + p_user_date (replaces CURRENT_DATE default)
--   - update_activity_crate_availability: p_user_date
--   - get_unclaimed_crates: p_user_date
--   - use_consumable: FOR UPDATE
-- ============================================================================


-- ============================================================================
-- 1. process_daily_login: Add FOR UPDATE lock + user date parameter
-- ============================================================================
DROP FUNCTION IF EXISTS process_daily_login(UUID);

CREATE OR REPLACE FUNCTION process_daily_login(
  p_user_id UUID,
  p_user_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := p_user_date;
  v_streak_record user_login_streaks%ROWTYPE;
  v_is_first_login BOOLEAN := false;
  v_streak_broken BOOLEAN := false;
  v_new_streak INT;
  v_first_login_bonus INT := 0;
  v_daily_bonus INT := 0;
  v_streak_bonus INT := 0;
  v_base_daily_xp INT;
  v_max_multiplier INT;
  v_events JSON;
  v_total_multiplier NUMERIC := 1.0;
  v_user_count INT;
  v_early_adopter_bonus INT := 525;
  v_normal_bonus INT := 0;
BEGIN
  -- Get existing streak record WITH ROW LOCK to prevent race conditions
  SELECT * INTO v_streak_record
  FROM user_login_streaks
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- If no record, this is first login
  IF v_streak_record.user_id IS NULL THEN
    v_is_first_login := true;

    INSERT INTO user_login_streaks
      (user_id, current_streak, longest_streak, total_logins, last_login_date, streak_start_date, first_login_at, last_daily_bonus_claimed)
    VALUES (p_user_id, 1, 1, 1, v_today, v_today, NOW(), v_today)
    RETURNING * INTO v_streak_record;

    SELECT COUNT(*) INTO v_user_count
    FROM user_login_streaks
    WHERE first_login_at IS NOT NULL;

    IF v_user_count <= 100 THEN
      v_first_login_bonus := v_early_adopter_bonus;
    ELSE
      SELECT base_xp INTO v_first_login_bonus
      FROM xp_bonus_templates
      WHERE bonus_type = 'first_login' AND is_active = true;
      v_first_login_bonus := COALESCE(v_first_login_bonus, v_normal_bonus);
    END IF;

  ELSIF v_streak_record.last_login_date = v_today THEN
    -- Already logged in today
    RETURN jsonb_build_object(
      'already_claimed', true,
      'current_streak', v_streak_record.current_streak,
      'longest_streak', v_streak_record.longest_streak,
      'total_logins', v_streak_record.total_logins,
      'xp_earned', 0,
      'is_first_login', false,
      'streak_broken', false,
      'daily_xp', 0,
      'streak_milestone_xp', 0,
      'first_login_xp', 0,
      'total_xp_awarded', 0,
      'active_events', NULL,
      'multiplier', 1.0,
      'message', 'Already claimed daily bonus today'
    );

  ELSIF v_streak_record.last_login_date = v_today - INTERVAL '1 day' THEN
    v_new_streak := v_streak_record.current_streak + 1;
    UPDATE user_login_streaks
    SET current_streak = v_new_streak,
        longest_streak = GREATEST(longest_streak, v_new_streak),
        total_logins = total_logins + 1,
        last_login_date = v_today,
        last_daily_bonus_claimed = v_today
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSE
    v_streak_broken := true;
    UPDATE user_login_streaks
    SET current_streak = 1,
        total_logins = total_logins + 1,
        last_login_date = v_today,
        streak_start_date = v_today,
        last_daily_bonus_claimed = v_today
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;
  END IF;

  SELECT base_xp, max_streak_multiplier
  INTO v_base_daily_xp, v_max_multiplier
  FROM xp_bonus_templates
  WHERE bonus_type = 'daily_login' AND is_active = true;

  v_daily_bonus := COALESCE(v_base_daily_xp, 25) * LEAST(v_streak_record.current_streak, COALESCE(v_max_multiplier, 7));

  IF v_streak_record.current_streak = 7 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_7' AND is_active = true;
  ELSIF v_streak_record.current_streak = 30 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_30' AND is_active = true;
  ELSIF v_streak_record.current_streak = 100 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_100' AND is_active = true;
  ELSIF v_streak_record.current_streak = 365 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_365' AND is_active = true;
  END IF;

  SELECT json_agg(json_build_object(
    'id', e.id,
    'name', e.event_name,
    'multiplier', e.xp_multiplier
  )),
  COALESCE(MAX(e.xp_multiplier), 1.0)
  INTO v_events, v_total_multiplier
  FROM xp_events e
  WHERE e.is_active = true
    AND NOW() BETWEEN e.start_at AND e.end_at;

  v_daily_bonus := FLOOR(v_daily_bonus * v_total_multiplier);
  v_streak_bonus := FLOOR(COALESCE(v_streak_bonus, 0) * v_total_multiplier);

  IF v_first_login_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to Zealova!');
    EXCEPTION WHEN OTHERS THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_first_login_bonus, 'first_login', 'Welcome to Zealova!', NOW());
    END;
  END IF;

  IF v_daily_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_daily_bonus, 'daily_login', NULL, 'Daily check-in bonus');
    EXCEPTION WHEN OTHERS THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_daily_bonus, 'daily_login', 'Daily check-in bonus', NOW());
    END;
  END IF;

  IF v_streak_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_streak_bonus, 'streak_milestone', NULL,
        CASE v_streak_record.current_streak
          WHEN 7 THEN '7-day streak bonus!'
          WHEN 30 THEN '30-day streak bonus!'
          WHEN 100 THEN '100-day streak bonus!'
          WHEN 365 THEN '365-day streak bonus!'
          ELSE 'Streak milestone bonus'
        END
      );
    EXCEPTION WHEN OTHERS THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_streak_bonus, 'streak_milestone', 'Streak milestone bonus', NOW());
    END;
  END IF;

  RETURN jsonb_build_object(
    'already_claimed', false,
    'current_streak', v_streak_record.current_streak,
    'longest_streak', v_streak_record.longest_streak,
    'total_logins', v_streak_record.total_logins,
    'xp_earned', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'is_first_login', v_is_first_login,
    'streak_broken', v_streak_broken,
    'daily_xp', v_daily_bonus,
    'streak_milestone_xp', COALESCE(v_streak_bonus, 0),
    'first_login_xp', COALESCE(v_first_login_bonus, 0),
    'total_xp_awarded', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'active_events', v_events,
    'multiplier', v_total_multiplier,
    'message',
      CASE
        WHEN v_is_first_login AND v_user_count <= 100 THEN 'Welcome to Zealova! As one of our first 100 users, you get a special 525 XP bonus!'
        WHEN v_is_first_login THEN 'Welcome to Zealova! Start earning XP by working out and logging meals.'
        WHEN v_streak_record.current_streak = 7 THEN 'Amazing! 7-day streak achieved!'
        WHEN v_streak_record.current_streak = 30 THEN 'Incredible! 30-day streak achieved!'
        WHEN v_streak_record.current_streak = 100 THEN 'Legendary! 100-day streak achieved!'
        WHEN v_streak_record.current_streak = 365 THEN 'EPIC! 365-day streak achieved!'
        WHEN v_streak_broken THEN 'Streak reset. Start building a new one!'
        ELSE 'Daily check-in complete!'
      END
  );
END;
$$;

COMMENT ON FUNCTION process_daily_login(UUID, DATE) IS
'Processes daily login, awards XP, updates streaks.
Migration 1898: Added FOR UPDATE row lock to prevent race conditions from concurrent
requests (e.g. two devices at midnight). Added p_user_date parameter so the backend
can pass the user''s local date instead of relying on server CURRENT_DATE (UTC).';


-- ============================================================================
-- 2. init_daily_crates: Add FOR UPDATE lock + user date parameter
-- ============================================================================
DROP FUNCTION IF EXISTS init_daily_crates(UUID);

CREATE OR REPLACE FUNCTION init_daily_crates(
  p_user_id UUID,
  p_user_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := p_user_date;
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

  -- Check if record exists for today WITH ROW LOCK
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = v_today
  FOR UPDATE;

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
  ON CONFLICT (user_id, crate_date) DO NOTHING
  RETURNING * INTO v_record;

  -- If ON CONFLICT hit (another transaction created it), fetch the existing row
  IF v_record.id IS NULL THEN
    SELECT * INTO v_record FROM user_daily_crates
    WHERE user_id = p_user_id AND crate_date = v_today;

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

COMMENT ON FUNCTION init_daily_crates(UUID, DATE) IS
'Initialize daily crates for a user. Returns existing record if one exists for the date.
Migration 1898: Added FOR UPDATE lock + ON CONFLICT for race-safe creation.
Added p_user_date parameter for timezone-correct date computation.';


-- ============================================================================
-- 3. claim_daily_crate: Add FOR UPDATE lock + fix default date
-- ============================================================================
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
BEGIN
  -- Get the record for the specified date WITH ROW LOCK
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = p_crate_date
  FOR UPDATE;

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

COMMENT ON FUNCTION claim_daily_crate(UUID, VARCHAR, DATE) IS
'Claim a daily crate. User picks 1 of 3 available crate types per day.
Migration 1898: Added FOR UPDATE row lock to prevent concurrent double-claims.';


-- ============================================================================
-- 4. update_activity_crate_availability: Add user date parameter
-- ============================================================================
CREATE OR REPLACE FUNCTION update_activity_crate_availability(
  p_user_id UUID,
  p_user_date DATE DEFAULT CURRENT_DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_daily_crates
  SET activity_crate_available = TRUE
  WHERE user_id = p_user_id
    AND crate_date = p_user_date
    AND selected_crate IS NULL;  -- Only if not already claimed

  RETURN FOUND;
END;
$$;


-- ============================================================================
-- 5. get_unclaimed_crates: Add user date parameter
-- ============================================================================
DROP FUNCTION IF EXISTS get_unclaimed_crates(UUID);

CREATE OR REPLACE FUNCTION get_unclaimed_crates(
  p_user_id UUID,
  p_user_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'crate_date', sub.crate_date,
        'daily_crate_available', sub.daily_crate_available,
        'streak_crate_available', sub.streak_crate_available,
        'activity_crate_available', sub.activity_crate_available
      ) ORDER BY sub.crate_date
    ),
    '[]'::jsonb
  )
  FROM (
    SELECT crate_date, daily_crate_available, streak_crate_available, activity_crate_available
    FROM user_daily_crates
    WHERE user_id = p_user_id
      AND selected_crate IS NULL
      AND crate_date <= p_user_date
    ORDER BY crate_date DESC
    LIMIT 9
  ) sub;
$$;


-- ============================================================================
-- 6. use_consumable: Add FOR UPDATE lock
-- ============================================================================
CREATE OR REPLACE FUNCTION use_consumable(
  p_user_id UUID,
  p_item_type VARCHAR(50)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_quantity INTEGER;
BEGIN
  -- Check current quantity WITH ROW LOCK to prevent concurrent use race
  SELECT quantity INTO v_current_quantity
  FROM user_consumables
  WHERE user_id = p_user_id AND item_type = p_item_type
  FOR UPDATE;

  IF v_current_quantity IS NULL OR v_current_quantity < 1 THEN
    RETURN FALSE;
  END IF;

  -- Decrement (safe now because row is locked)
  UPDATE user_consumables
  SET quantity = quantity - 1,
      updated_at = NOW()
  WHERE user_id = p_user_id AND item_type = p_item_type;

  RETURN TRUE;
END;
$$;


-- ============================================================================
-- 7. Add partial unique index for daily goal XP dedup
-- Prevents concurrent award_goal_xp from double-awarding
-- Uses (created_at AT TIME ZONE 'UTC')::date which is IMMUTABLE for timestamptz
-- ============================================================================

-- First, clean up existing duplicates (keep the earliest entry per user/source/day)
DELETE FROM xp_transactions
WHERE id IN (
  SELECT id FROM (
    SELECT id,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, source, (created_at AT TIME ZONE 'UTC')::date
        ORDER BY created_at ASC
      ) AS rn
    FROM xp_transactions
    WHERE source LIKE 'daily_goal_%'
  ) dupes
  WHERE rn > 1
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_xp_transactions_daily_goal_dedup
ON xp_transactions (user_id, source, ((created_at AT TIME ZONE 'UTC')::date))
WHERE source LIKE 'daily_goal_%';
