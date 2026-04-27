-- Migration 1884: Fix New User Level (should start at Level 1, not 7)
-- Problem: first_login bonus of 100-250 XP + daily login of 25 XP immediately pushes new users to Level 4-7
-- Fix: Set first_login bonus to 0, so new users start at Level 1 and earn Level 2 from daily login (25 XP)
-- Also: Remove XP event multiplier from first_login_bonus to prevent Double XP inflating welcome bonus

-- 1. Update the bonus template to 0 XP
UPDATE xp_bonus_templates
SET base_xp = 0,
    description = 'Welcome notification only (no XP bonus - users earn XP from actions)'
WHERE bonus_type = 'first_login';

-- 2. Update the process_daily_login function with 0 welcome bonus
CREATE OR REPLACE FUNCTION process_daily_login(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
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
  v_early_adopter_bonus INT := 525;  -- Special bonus for first 100 users (already claimed)
  v_normal_bonus INT := 0;           -- No welcome bonus (was 100, reduced to 0)
BEGIN
  -- Get existing streak record
  SELECT * INTO v_streak_record
  FROM user_login_streaks
  WHERE user_id = p_user_id;

  -- If no record, this is first login
  IF v_streak_record.user_id IS NULL THEN
    v_is_first_login := true;

    -- Insert new streak record
    INSERT INTO user_login_streaks
      (user_id, current_streak, max_streak, total_logins, last_login_date, streak_start_date, first_login_at, today_claimed_at)
    VALUES (p_user_id, 1, 1, 1, v_today, v_today, NOW(), v_today)
    RETURNING * INTO v_streak_record;

    -- Check if this user is among the first 100 users
    SELECT COUNT(*) INTO v_user_count
    FROM user_login_streaks
    WHERE first_login_at IS NOT NULL;

    -- Award first login bonus (525 XP for early adopters, 0 XP for others)
    IF v_user_count <= 100 THEN
      v_first_login_bonus := v_early_adopter_bonus;
    ELSE
      -- No welcome bonus for new users (they start at Level 1)
      v_first_login_bonus := v_normal_bonus;
    END IF;

  ELSIF v_streak_record.last_login_date = v_today THEN
    -- Already logged in today, no bonus
    RETURN json_build_object(
      'already_claimed', true,
      'current_streak', v_streak_record.current_streak,
      'max_streak', v_streak_record.max_streak,
      'total_logins', v_streak_record.total_logins,
      'xp_earned', 0,
      'is_first_login', false,
      'streak_broken', false,
      'daily_bonus', 0,
      'streak_bonus', 0,
      'first_login_xp', 0,
      'total_xp_awarded', 0,
      'active_events', NULL,
      'message', 'Already claimed daily bonus today'
    );

  ELSIF v_streak_record.last_login_date = v_today - INTERVAL '1 day' THEN
    -- Streak continues
    v_new_streak := v_streak_record.current_streak + 1;

    UPDATE user_login_streaks
    SET current_streak = v_new_streak,
        max_streak = GREATEST(max_streak, v_new_streak),
        total_logins = total_logins + 1,
        last_login_date = v_today,
        today_claimed_at = v_today
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSE
    -- Streak broken, start new
    v_streak_broken := true;

    UPDATE user_login_streaks
    SET current_streak = 1,
        total_logins = total_logins + 1,
        last_login_date = v_today,
        streak_start_date = v_today,
        today_claimed_at = v_today
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;
  END IF;

  -- Get daily login template
  SELECT base_xp, max_streak_multiplier
  INTO v_base_daily_xp, v_max_multiplier
  FROM xp_bonus_templates
  WHERE bonus_type = 'daily_login' AND is_active = true;

  -- Calculate daily bonus with streak multiplier (capped)
  v_daily_bonus := COALESCE(v_base_daily_xp, 25) * LEAST(v_streak_record.current_streak, COALESCE(v_max_multiplier, 7));

  -- Check for streak milestone bonuses
  IF v_streak_record.current_streak = 7 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_7' AND is_active = true;
  ELSIF v_streak_record.current_streak = 30 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_30' AND is_active = true;
  ELSIF v_streak_record.current_streak = 100 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_100' AND is_active = true;
  ELSIF v_streak_record.current_streak = 365 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_365' AND is_active = true;
  END IF;

  -- Get active XP events and calculate multiplier
  SELECT json_agg(json_build_object(
    'id', e.id,
    'name', e.event_name,
    'multiplier', e.xp_multiplier
  )),
  COALESCE(MAX(e.xp_multiplier), 1.0)
  INTO v_events, v_total_multiplier
  FROM xp_events e
  WHERE e.is_active = true
    AND NOW() BETWEEN e.start_time AND e.end_time;

  -- Apply multiplier to daily and streak bonuses ONLY (NOT first_login_bonus)
  v_daily_bonus := FLOOR(v_daily_bonus * v_total_multiplier);
  v_streak_bonus := FLOOR(COALESCE(v_streak_bonus, 0) * v_total_multiplier);
  -- NOTE: first_login_bonus is NOT multiplied (prevents Double XP inflating welcome bonus)

  -- Award XP
  IF v_first_login_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to Zealova!');
    EXCEPTION WHEN OTHERS THEN
      -- Fallback: direct insert
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

  -- Return response
  RETURN json_build_object(
    'already_claimed', false,
    'current_streak', v_streak_record.current_streak,
    'max_streak', v_streak_record.max_streak,
    'total_logins', v_streak_record.total_logins,
    'xp_earned', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'is_first_login', v_is_first_login,
    'streak_broken', v_streak_broken,
    'daily_bonus', v_daily_bonus,
    'streak_bonus', COALESCE(v_streak_bonus, 0),
    'first_login_xp', COALESCE(v_first_login_bonus, 0),
    'total_xp_awarded', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'active_events', v_events,
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

COMMENT ON FUNCTION process_daily_login IS
'Processes daily login, awards XP, updates streaks.
Migration 1884: Welcome bonus set to 0 XP so new users start at Level 1.
First-time bonuses from actions (workouts, meals, etc.) provide meaningful progression.';
