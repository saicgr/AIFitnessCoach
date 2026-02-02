-- Fix process_daily_login to return consistent JSON response shape for all cases
-- Previously, the already_claimed branch returned an incomplete response that caused
-- frontend parsing issues

CREATE OR REPLACE FUNCTION process_daily_login(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_streak_record user_login_streaks%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_yesterday DATE := CURRENT_DATE - 1;
  v_is_first_login BOOLEAN := false;
  v_streak_broken BOOLEAN := false;
  v_daily_bonus INT := 0;
  v_streak_bonus INT := 0;
  v_first_login_bonus INT := 0;
  v_active_events JSON;
  v_total_multiplier DECIMAL := 1.0;
  v_base_daily_xp INT;
  v_max_multiplier INT;
BEGIN
  -- Get or create streak record
  SELECT * INTO v_streak_record FROM user_login_streaks WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    -- First ever login
    v_is_first_login := true;
    INSERT INTO user_login_streaks (user_id, current_streak, longest_streak, total_logins,
                                     last_login_date, streak_start_date, first_login_at,
                                     last_daily_bonus_claimed)
    VALUES (p_user_id, 1, 1, 1, v_today, v_today, NOW(), v_today)
    RETURNING * INTO v_streak_record;

    -- Award first login bonus
    SELECT base_xp INTO v_first_login_bonus
    FROM xp_bonus_templates
    WHERE bonus_type = 'first_login' AND is_active = true;

  ELSIF v_streak_record.last_login_date = v_today THEN
    -- Already logged in today, no bonus
    -- FIXED: Return consistent response shape with all expected fields
    RETURN json_build_object(
      'already_claimed', true,
      'is_first_login', false,
      'streak_broken', false,
      'current_streak', v_streak_record.current_streak,
      'longest_streak', v_streak_record.longest_streak,
      'total_logins', v_streak_record.total_logins,
      'daily_xp', 0,
      'first_login_xp', 0,
      'streak_milestone_xp', 0,
      'total_xp_awarded', 0,
      'active_events', NULL,
      'multiplier', 1.0,
      'message', 'Already claimed today''s bonus'
    );

  ELSIF v_streak_record.last_login_date = v_yesterday THEN
    -- Continuing streak
    UPDATE user_login_streaks SET
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      total_logins = total_logins + 1,
      last_login_date = v_today,
      last_daily_bonus_claimed = v_today,
      updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSE
    -- Streak broken
    v_streak_broken := true;
    UPDATE user_login_streaks SET
      current_streak = 1,
      total_logins = total_logins + 1,
      last_login_date = v_today,
      streak_start_date = v_today,
      last_daily_bonus_claimed = v_today,
      updated_at = NOW()
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
    'event_name', e.event_name,
    'event_type', e.event_type,
    'xp_multiplier', e.xp_multiplier,
    'end_at', e.end_at,
    'icon_name', e.icon_name,
    'banner_color', e.banner_color
  )), COALESCE(MAX(e.xp_multiplier), 1.0)
  INTO v_active_events, v_total_multiplier
  FROM xp_events e
  WHERE e.is_active = true
    AND NOW() BETWEEN e.start_at AND e.end_at
    AND ('all' = ANY(e.applies_to) OR 'daily_login' = ANY(e.applies_to));

  -- Apply multiplier to bonuses
  v_daily_bonus := FLOOR(v_daily_bonus * v_total_multiplier);
  v_first_login_bonus := FLOOR(COALESCE(v_first_login_bonus, 0) * v_total_multiplier);
  v_streak_bonus := FLOOR(COALESCE(v_streak_bonus, 0) * v_total_multiplier);

  -- Award XP via the award_xp function (if it exists)
  IF v_first_login_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to FitWiz!');
    EXCEPTION WHEN undefined_function THEN
      -- award_xp doesn't exist, insert directly to xp_transactions
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_first_login_bonus, 'first_login', 'Welcome to FitWiz!', NOW());
    END;
  END IF;

  IF v_daily_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_daily_bonus, 'daily_checkin', NULL,
                       'Day ' || v_streak_record.current_streak || ' streak bonus');
    EXCEPTION WHEN undefined_function THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_daily_bonus, 'daily_checkin', 'Day ' || v_streak_record.current_streak || ' streak bonus', NOW());
    END;
  END IF;

  IF v_streak_bonus > 0 THEN
    BEGIN
      PERFORM award_xp(p_user_id, v_streak_bonus, 'streak', NULL,
                       v_streak_record.current_streak || '-day streak milestone!');
    EXCEPTION WHEN undefined_function THEN
      INSERT INTO xp_transactions (user_id, xp_amount, source, description, created_at)
      VALUES (p_user_id, v_streak_bonus, 'streak', v_streak_record.current_streak || '-day streak milestone!', NOW());
    END;
  END IF;

  -- Log to user_context_logs if table exists
  BEGIN
    INSERT INTO user_context_logs (user_id, event_type, event_data, context, created_at)
    VALUES (
      p_user_id,
      'daily_login',
      json_build_object(
        'streak_day', v_streak_record.current_streak,
        'xp_earned', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
        'is_first_login', v_is_first_login,
        'streak_broken', v_streak_broken,
        'active_events', v_active_events
      ),
      json_build_object(
        'day_of_week', to_char(NOW(), 'Day'),
        'time_of_day', CASE
          WHEN EXTRACT(HOUR FROM NOW()) < 6 THEN 'night'
          WHEN EXTRACT(HOUR FROM NOW()) < 12 THEN 'morning'
          WHEN EXTRACT(HOUR FROM NOW()) < 18 THEN 'afternoon'
          ELSE 'evening'
        END
      ),
      NOW()
    );
  EXCEPTION WHEN undefined_table THEN
    -- user_context_logs doesn't exist, skip
    NULL;
  END;

  RETURN json_build_object(
    'is_first_login', v_is_first_login,
    'streak_broken', v_streak_broken,
    'current_streak', v_streak_record.current_streak,
    'longest_streak', v_streak_record.longest_streak,
    'total_logins', v_streak_record.total_logins,
    'daily_xp', v_daily_bonus,
    'first_login_xp', COALESCE(v_first_login_bonus, 0),
    'streak_milestone_xp', COALESCE(v_streak_bonus, 0),
    'total_xp_awarded', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'active_events', v_active_events,
    'multiplier', v_total_multiplier,
    'message', CASE
      WHEN v_is_first_login THEN 'Welcome to FitWiz! Here''s your welcome bonus!'
      WHEN v_streak_bonus > 0 THEN v_streak_record.current_streak || '-day streak milestone reached!'
      WHEN v_streak_broken THEN 'Streak reset. Start a new one today!'
      ELSE 'Day ' || v_streak_record.current_streak || ' streak!'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION process_daily_login IS 'Process daily login and award XP. Fixed to return consistent JSON for already_claimed case.';
