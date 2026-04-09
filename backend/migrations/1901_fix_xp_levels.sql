-- ============================================================================
-- Migration 1901: Fix New User Level (Level 6 on signup bug)
-- ============================================================================
-- Root cause:
--   1. Early adopter bonus was 525 XP (hardcoded in process_daily_login)
--   2. With <100 users, ALL new users hit the early adopter path
--   3. 525 XP * 0.5 trust multiplier = 262 XP → Level 6 under old thresholds
--
-- Fixes:
--   A. Reduce early adopter first-login bonus: 525 → 100 XP
--   B. Add 50 XP first-crate bonus for early adopters
--   C. Bypass trust multiplier for early adopter bonuses (new p_bypass_trust param)
--   D. Rescale level thresholds so Level 2 = 150 XP (100 login + 50 crate)
--   E. Recalculate all existing users' levels under new curve
-- ============================================================================


-- ============================================================================
-- 1. Update award_xp: Add p_bypass_trust parameter
-- ============================================================================

-- Drop old signature (6 params) to avoid ambiguous overload
DROP FUNCTION IF EXISTS award_xp(UUID, INT, TEXT, TEXT, TEXT, BOOLEAN);

CREATE OR REPLACE FUNCTION award_xp(
    p_user_id UUID,
    p_xp_amount INT,
    p_source TEXT,
    p_source_id TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_is_verified BOOLEAN DEFAULT false,
    p_bypass_trust BOOLEAN DEFAULT false
) RETURNS JSONB AS $$
DECLARE
    v_user_xp user_xp;
    v_new_total BIGINT;
    v_level_info RECORD;
    v_trust_level INT;
    v_xp_multiplier DECIMAL := 1.0;
    v_old_level INT;
    v_new_level INT;
    v_level_up_rewards JSONB;
    v_2x_until TIMESTAMPTZ;
BEGIN
    -- Check for active 2x XP token
    SELECT active_2x_token_until INTO v_2x_until
    FROM user_xp WHERE user_id = p_user_id;

    IF v_2x_until IS NOT NULL AND v_2x_until > NOW() THEN
        v_xp_multiplier := 2.0;
    END IF;

    -- Get current trust level and level
    SELECT COALESCE(trust_level, 1), COALESCE(current_level, 1)
    INTO v_trust_level, v_old_level
    FROM user_xp WHERE user_id = p_user_id;

    -- Apply trust level multiplier (anti-fraud) UNLESS bypassed
    IF NOT p_bypass_trust THEN
        IF v_trust_level = 1 THEN
            v_xp_multiplier := v_xp_multiplier * 0.5;
        ELSIF v_trust_level >= 2 AND p_is_verified THEN
            v_xp_multiplier := v_xp_multiplier * 1.2;
        END IF;
    END IF;

    -- Insert XP transaction
    INSERT INTO xp_transactions (user_id, xp_amount, source, source_id, description, is_verified)
    VALUES (p_user_id, FLOOR(p_xp_amount * v_xp_multiplier)::INT, p_source, p_source_id, p_description, p_is_verified);

    -- Update or insert user_xp record
    INSERT INTO user_xp (user_id, total_xp)
    VALUES (p_user_id, FLOOR(p_xp_amount * v_xp_multiplier)::INT)
    ON CONFLICT (user_id) DO UPDATE
    SET total_xp = user_xp.total_xp + FLOOR(p_xp_amount * v_xp_multiplier)::INT,
        updated_at = NOW();

    -- Get new total XP
    SELECT total_xp INTO v_new_total FROM user_xp WHERE user_id = p_user_id;

    -- Calculate new level info
    SELECT * INTO v_level_info FROM calculate_level_from_xp(v_new_total);

    -- Update level info
    UPDATE user_xp
    SET current_level = v_level_info.level,
        title = v_level_info.title,
        xp_to_next_level = v_level_info.xp_for_next,
        xp_in_current_level = v_level_info.xp_in_level,
        prestige_level = v_level_info.prestige,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_user_xp;

    v_new_level := v_user_xp.current_level;

    -- Check for level up and distribute rewards
    v_level_up_rewards := NULL;
    IF v_new_level > COALESCE(v_old_level, 1) THEN
        v_level_up_rewards := distribute_level_rewards(p_user_id, COALESCE(v_old_level, 1), v_new_level);
    END IF;

    -- Return full result as JSONB
    RETURN jsonb_build_object(
        'id', v_user_xp.id,
        'user_id', v_user_xp.user_id,
        'total_xp', v_user_xp.total_xp,
        'current_level', v_user_xp.current_level,
        'xp_to_next_level', v_user_xp.xp_to_next_level,
        'xp_in_current_level', v_user_xp.xp_in_current_level,
        'prestige_level', v_user_xp.prestige_level,
        'title', v_user_xp.title,
        'trust_level', v_user_xp.trust_level,
        'xp_awarded', FLOOR(p_xp_amount * v_xp_multiplier)::INT,
        'multiplier_applied', v_xp_multiplier,
        'leveled_up', (v_new_level > COALESCE(v_old_level, 1)),
        'old_level', v_old_level,
        'new_level', v_new_level,
        'level_up_rewards', v_level_up_rewards
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 2. Update process_daily_login: Early adopter bonus 525 → 100, bypass trust
-- ============================================================================
DROP FUNCTION IF EXISTS process_daily_login(UUID);
DROP FUNCTION IF EXISTS process_daily_login(UUID, DATE);

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
  v_early_adopter_bonus INT := 100;   -- Was 525, now 100 XP for first 100 users
  v_normal_bonus INT := 0;            -- No welcome bonus for post-100 users
  v_is_early_adopter BOOLEAN := false;
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
      v_is_early_adopter := true;
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

  -- Award first login bonus (bypass trust multiplier for early adopters)
  IF v_first_login_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to FitWiz!', false, v_is_early_adopter);
    EXCEPTION WHEN OTHERS THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_first_login_bonus, 'first_login', 'Welcome to FitWiz!', NOW());
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
        WHEN v_is_first_login AND v_is_early_adopter THEN 'Welcome to FitWiz! As one of our first 100 users, you get a special 100 XP bonus!'
        WHEN v_is_first_login THEN 'Welcome to FitWiz! Start earning XP by working out and logging meals.'
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
Migration 1901: Reduced early adopter bonus from 525 to 100 XP.
Early adopter bonuses now bypass trust multiplier so users get full 100 XP.';


-- ============================================================================
-- 3. Update claim_daily_crate: Add 50 XP first-crate bonus for early adopters
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
  v_is_first_crate BOOLEAN := false;
  v_is_early_adopter BOOLEAN := false;
  v_first_crate_bonus INT := 50;
  v_user_count INT;
  v_previous_claims INT;
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

  -- Check if this is the user's first-ever crate claim
  SELECT COUNT(*) INTO v_previous_claims
  FROM user_daily_crates
  WHERE user_id = p_user_id AND selected_crate IS NOT NULL;

  IF v_previous_claims = 0 THEN
    v_is_first_crate := true;

    -- Check if user is an early adopter (first 100 users)
    SELECT COUNT(*) INTO v_user_count
    FROM user_login_streaks
    WHERE first_login_at IS NOT NULL;

    v_is_early_adopter := (v_user_count <= 100);
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

  -- Award the crate reward
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

  -- Award first-crate bonus for early adopters (50 XP, bypasses trust multiplier)
  IF v_is_first_crate AND v_is_early_adopter THEN
    PERFORM award_xp(
      p_user_id,
      v_first_crate_bonus,
      'first_crate_bonus',
      'early_adopter',
      'Early adopter first crate bonus!',
      false,
      true  -- bypass trust multiplier
    );
  END IF;

  -- Return FLAT structure
  RETURN jsonb_build_object(
    'success', TRUE,
    'crate_type', p_crate_type,
    'crate_date', p_crate_date,
    'reward_type', v_reward->>'type',
    'reward_amount', (v_reward->>'amount')::INTEGER,
    'first_crate_bonus', CASE WHEN v_is_first_crate AND v_is_early_adopter THEN v_first_crate_bonus ELSE 0 END,
    'message', CASE
      WHEN v_is_first_crate AND v_is_early_adopter THEN 'Crate opened! +50 XP early adopter bonus!'
      ELSE 'Crate opened!'
    END
  );
END;
$$;

COMMENT ON FUNCTION claim_daily_crate(UUID, VARCHAR, DATE) IS
'Claim a daily crate. User picks 1 of 3 available crate types per day.
Migration 1901: Added 50 XP first-crate bonus for early adopters (first 100 users),
bypassing trust multiplier.';


-- ============================================================================
-- 4. Rescale level thresholds: Level 2 at 150 XP
-- ============================================================================

DROP FUNCTION IF EXISTS calculate_level_from_xp(BIGINT);
DROP FUNCTION IF EXISTS calculate_level_from_xp(INTEGER);

CREATE OR REPLACE FUNCTION calculate_level_from_xp(p_total_xp BIGINT)
RETURNS TABLE (
  level INT,
  title TEXT,
  xp_for_next INT,
  xp_in_level INT,
  prestige INT
)
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  -- XP required for each level (1-175, then flat 100000 for 176-250)
  -- Level 2 = 150 XP (early adopter: 100 login + 50 first crate)
  xp_table INT[] := ARRAY[
    -- Levels 1-10 (Beginner): Meaningful early progression
    150, 200, 300, 450, 650, 900, 1200, 1600, 2100, 2700,
    -- Levels 11-25 (Novice): Steady growth
    3000, 3300, 3600, 3900, 4200, 4500, 4800, 5100, 5400, 5700, 6000, 6300, 6600, 6900, 7500,
    -- Levels 26-50 (Apprentice): Consistent effort required
    8000, 8500, 9000, 9500, 10000, 10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 16000, 17000, 18000, 19000, 20000, 21000, 22000, 23000, 24000, 25000,
    -- Levels 51-75 (Athlete): Dedicated training
    26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 42000, 44000, 46000, 48000, 50000, 52000, 54000, 56000, 58000, 60000,
    -- Levels 76-100 (Elite): Long-term commitment
    62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000, 102000, 104000, 106000, 108000, 110000,
    -- Levels 101-125 (Master)
    112000, 114000, 116000, 118000, 120000, 122000, 124000, 126000, 128000, 130000, 132000, 134000, 136000, 138000, 140000, 142000, 144000, 146000, 148000, 150000, 152000, 154000, 156000, 158000, 160000,
    -- Levels 126-150 (Champion)
    162000, 164000, 166000, 168000, 170000, 172000, 174000, 176000, 178000, 180000, 182000, 184000, 186000, 188000, 190000, 192000, 194000, 196000, 198000, 200000, 202000, 204000, 206000, 208000, 210000,
    -- Levels 151-175 (Legend)
    212000, 214000, 216000, 218000, 220000, 222000, 224000, 226000, 228000, 230000, 232000, 234000, 236000, 238000, 240000, 242000, 244000, 246000, 248000, 250000, 252000, 254000, 256000, 258000, 260000
  ];
  v_remaining_xp BIGINT;
  v_level INT := 1;
  v_level_xp INT;
  v_xp_in_level INT;
  v_title TEXT;
  v_prestige INT := 0;
BEGIN
  v_remaining_xp := p_total_xp;

  -- Calculate level by consuming XP
  WHILE v_remaining_xp > 0 AND v_level < 250 LOOP
    IF v_level <= 175 THEN
      v_level_xp := xp_table[v_level];
    ELSE
      -- Levels 176-250 are flat 100,000 XP each (prestige tier)
      v_level_xp := 100000;
    END IF;

    IF v_remaining_xp >= v_level_xp THEN
      v_remaining_xp := v_remaining_xp - v_level_xp;
      v_level := v_level + 1;
    ELSE
      EXIT;
    END IF;
  END LOOP;

  v_xp_in_level := v_remaining_xp::INT;

  -- Calculate XP needed for next level
  IF v_level >= 250 THEN
    v_level_xp := 0;
  ELSIF v_level <= 175 THEN
    v_level_xp := xp_table[v_level];
  ELSE
    v_level_xp := 100000;
  END IF;

  -- Determine title based on level (11 tiers)
  IF v_level <= 10 THEN
    v_title := 'Beginner';
  ELSIF v_level <= 25 THEN
    v_title := 'Novice';
  ELSIF v_level <= 50 THEN
    v_title := 'Apprentice';
  ELSIF v_level <= 75 THEN
    v_title := 'Athlete';
  ELSIF v_level <= 100 THEN
    v_title := 'Elite';
  ELSIF v_level <= 125 THEN
    v_title := 'Master';
  ELSIF v_level <= 150 THEN
    v_title := 'Champion';
  ELSIF v_level <= 175 THEN
    v_title := 'Legend';
  ELSIF v_level <= 200 THEN
    v_title := 'Mythic';
  ELSIF v_level <= 225 THEN
    v_title := 'Immortal';
  ELSE
    v_title := 'Transcendent';
  END IF;

  RETURN QUERY SELECT v_level, v_title, v_level_xp, v_xp_in_level, v_prestige;
END;
$$;


-- ============================================================================
-- 5. Update bonus template
-- ============================================================================
UPDATE xp_bonus_templates
SET base_xp = 0,
    description = 'Welcome notification only (no XP bonus - early adopters get bonus via process_daily_login)'
WHERE bonus_type = 'first_login';


-- ============================================================================
-- 6. Recalculate ALL existing users' levels under the new curve
-- ============================================================================
UPDATE user_xp u
SET current_level = l.level,
    title = l.title,
    xp_to_next_level = l.xp_for_next,
    xp_in_current_level = l.xp_in_level,
    prestige_level = l.prestige,
    updated_at = NOW()
FROM (
  SELECT ux.user_id, (calculate_level_from_xp(ux.total_xp)).*
  FROM user_xp ux
) l
WHERE u.user_id = l.user_id;


-- ============================================================================
-- 7. Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION award_xp(UUID, INT, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION award_xp(UUID, INT, TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION process_daily_login(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION process_daily_login(UUID, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION claim_daily_crate(UUID, VARCHAR, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION claim_daily_crate(UUID, VARCHAR, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION calculate_level_from_xp(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_level_from_xp(BIGINT) TO service_role;
