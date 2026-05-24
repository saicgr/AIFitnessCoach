-- 2099_xp_streak_freeze_rpc_update.sql
-- Patch process_daily_login(p_user_id uuid, p_user_date date) so that a missed
-- day covered by an XP streak freeze does NOT zero the streak.
--
-- Background
-- ----------
-- Migration 2095 added:
--   * users.xp_streak_freezes_available             (banked freezes, cap 2)
--   * user_login_streaks.last_freeze_used_at        (date the freeze was spent)
--   * xp_events.used_freeze                         (legacy flag on the event
--                                                    catalog table — NOT
--                                                    per-user-per-day, so we
--                                                    cannot derive freeze
--                                                    truth from it)
--
-- The /api/v1/xp/use-freeze endpoint writes user_login_streaks.last_freeze_used_at
-- atomically, so THAT column is the authoritative source the RPC uses here.
--
-- Patched rule (only change vs. prior definition)
-- -----------------------------------------------
-- When last_login_date < v_today - 1 (would normally reset to 1), check:
--   * gap is EXACTLY 2 days  (one missed day == yesterday)
--   * last_freeze_used_at = v_today - 1  (the freeze covers yesterday)
--   * last_freeze_used_at > last_login_date  (freeze hasn't already been
--                                             credited to a previous compute)
-- If all true: bump streak by 1 and treat as continuing.
-- Otherwise: existing reset-to-1 behavior is preserved.
--
-- Skip-day chain rule (per spec): two missed days in a row, even with the
-- freeze on day 1, still breaks. A 3-day gap (gap=3) cannot be bridged because
-- only ONE freeze date is recorded — there is no way to mark two consecutive
-- frozen days, and the requirement explicitly forbids it.
--
-- Signature, return shape, XP awards, level-up flow, idempotent same-day
-- guard, and consecutive-day branch are all unchanged. Safe to re-apply.

CREATE OR REPLACE FUNCTION public.process_daily_login(
  p_user_id uuid,
  p_user_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_today DATE := p_user_date;
  v_streak_record user_login_streaks%ROWTYPE;
  v_is_first_login BOOLEAN := false;
  v_streak_broken BOOLEAN := false;
  v_freeze_applied BOOLEAN := false;
  v_new_streak INT;
  v_first_login_bonus INT := 0;
  v_daily_bonus INT := 0;
  v_streak_bonus INT := 0;
  v_base_daily_xp INT;
  v_max_multiplier INT;
  v_events JSON;
  v_total_multiplier NUMERIC := 1.0;
  v_user_count INT;
  v_early_adopter_bonus INT := 100;
  v_normal_bonus INT := 0;
  v_is_early_adopter BOOLEAN := false;
BEGIN
  SELECT * INTO v_streak_record
  FROM user_login_streaks
  WHERE user_id = p_user_id
  FOR UPDATE;

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
    -- Standard consecutive-day continuation.
    v_new_streak := v_streak_record.current_streak + 1;
    UPDATE user_login_streaks
    SET current_streak = v_new_streak,
        longest_streak = GREATEST(longest_streak, v_new_streak),
        total_logins = total_logins + 1,
        last_login_date = v_today,
        last_daily_bonus_claimed = v_today
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSIF v_streak_record.last_login_date = v_today - INTERVAL '2 days'
        AND v_streak_record.last_freeze_used_at = v_today - INTERVAL '1 day'
        AND v_streak_record.last_freeze_used_at > v_streak_record.last_login_date
  THEN
    -- Freeze-covered single missed day. Only ONE consecutive frozen day
    -- counts; a gap of 3+ days falls through to the reset branch below.
    v_freeze_applied := true;
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
      PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to Zealova!', false, v_is_early_adopter);
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
    'freeze_applied', v_freeze_applied,
    'daily_xp', v_daily_bonus,
    'streak_milestone_xp', COALESCE(v_streak_bonus, 0),
    'first_login_xp', COALESCE(v_first_login_bonus, 0),
    'total_xp_awarded', v_daily_bonus + COALESCE(v_first_login_bonus, 0) + COALESCE(v_streak_bonus, 0),
    'active_events', v_events,
    'multiplier', v_total_multiplier,
    'message',
      CASE
        WHEN v_is_first_login AND v_is_early_adopter THEN 'Welcome to Zealova! As one of our first 100 users, you get a special 100 XP bonus!'
        WHEN v_is_first_login THEN 'Welcome to Zealova! Start earning XP by working out and logging meals.'
        WHEN v_streak_record.current_streak = 7 THEN 'Amazing! 7-day streak achieved!'
        WHEN v_streak_record.current_streak = 30 THEN 'Incredible! 30-day streak achieved!'
        WHEN v_streak_record.current_streak = 100 THEN 'Legendary! 100-day streak achieved!'
        WHEN v_streak_record.current_streak = 365 THEN 'EPIC! 365-day streak achieved!'
        WHEN v_freeze_applied THEN 'Streak freeze saved your streak!'
        WHEN v_streak_broken THEN 'Streak reset. Start building a new one!'
        ELSE 'Daily check-in complete!'
      END
  );
END;
$function$;
