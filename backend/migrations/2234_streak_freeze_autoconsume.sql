-- 2234_streak_freeze_autoconsume.sql
-- Workstream B9 (follow-up to 2233) — make process_daily_login() AUTO-CONSUME a
-- banked streak freeze to bridge a single missed day, instead of resetting the
-- streak to 1. This is the PASSIVE protection users expect from Gravl: they
-- never tap "use freeze"; the daily-login compute spends a banked freeze for
-- them when they miss a day and have one in the bank.
--
-- Builds on:
--   * 2095 — users.xp_streak_freezes_available (live balance, cap 2),
--            user_login_streaks.last_freeze_used_at (same-day double-apply guard)
--   * 2099 — the prior process_daily_login() that handles a MANUAL /use-freeze
--            spend (last_freeze_used_at = yesterday) without zeroing the streak.
--   * 2233 — xp_streak_freeze_ledger (append-only audit) +
--            user_login_streaks.auto_protected_today / freezes_earned_total /
--            last_freeze_earned_streak.
--
-- What changes vs. 2099
-- ---------------------
-- A NEW branch is inserted between the manual-freeze branch and the reset
-- branch. It fires when:
--   * the user missed EXACTLY one day  (last_login_date = v_today - 2 days), AND
--   * the manual-freeze branch did NOT already cover yesterday, AND
--   * the user has a banked freeze  (users.xp_streak_freezes_available > 0)
-- When it fires we:
--   1. decrement users.xp_streak_freezes_available by 1 (floored at 0),
--   2. bump current_streak by 1 and continue (longest_streak / total_logins /
--      last_login_date updated like the consecutive-day branch),
--   3. set user_login_streaks.auto_protected_today = TRUE,
--   4. append an 'auto_protect' row (delta -1) to xp_streak_freeze_ledger with
--      the post-decrement balance_after.
-- Otherwise the existing reset-to-1 behavior is preserved (gap >= 3 days, OR a
-- single missed day with zero banked freezes).
--
-- auto_protected_today is a PER-DAY flag, so every OTHER branch (first login,
-- consecutive day, manual freeze, reset) explicitly clears it to FALSE on its
-- UPDATE/INSERT — otherwise yesterday's auto-protect would linger and the
-- client would show "a freeze saved your streak" on a normal login.
--
-- Skip-chain rule (unchanged from 2099): only ONE consecutive missed day can be
-- bridged. A gap of 3+ days falls through to reset even with freezes banked,
-- because there is no way to attribute a freeze to two consecutive missed days.
--
-- Signature, return shape (plus the existing freeze_applied key and a NEW
-- auto_protected key), XP awards, level-up flow, and the idempotent same-day
-- guard are otherwise unchanged. Idempotent / safe to re-apply.
--
-- DO NOT APPLY in this run (reserved migration 2234). The orchestrator applies.

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
  v_auto_protected BOOLEAN := false;   -- NEW: a BANKED freeze auto-bridged a missed day
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
  v_freezes_available INT := 0;        -- NEW: live banked-freeze balance
  v_balance_after INT := 0;            -- NEW: balance written to the ledger row
BEGIN
  SELECT * INTO v_streak_record
  FROM user_login_streaks
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_streak_record.user_id IS NULL THEN
    v_is_first_login := true;

    INSERT INTO user_login_streaks
      (user_id, current_streak, longest_streak, total_logins, last_login_date, streak_start_date, first_login_at, last_daily_bonus_claimed, auto_protected_today)
    VALUES (p_user_id, 1, 1, 1, v_today, v_today, NOW(), v_today, false)
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
      'freeze_applied', false,
      'auto_protected', v_streak_record.auto_protected_today,
      'daily_xp', 0,
      'streak_milestone_xp', 0,
      'first_login_xp', 0,
      'total_xp_awarded', 0,
      'active_events', NULL,
      'multiplier', 1.0,
      'message', 'Already claimed daily bonus today'
    );

  ELSIF v_streak_record.last_login_date = v_today - INTERVAL '1 day' THEN
    -- Standard consecutive-day continuation. Clear the per-day auto-protect flag.
    v_new_streak := v_streak_record.current_streak + 1;
    UPDATE user_login_streaks
    SET current_streak = v_new_streak,
        longest_streak = GREATEST(longest_streak, v_new_streak),
        total_logins = total_logins + 1,
        last_login_date = v_today,
        last_daily_bonus_claimed = v_today,
        auto_protected_today = false
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSIF v_streak_record.last_login_date = v_today - INTERVAL '2 days'
        AND v_streak_record.last_freeze_used_at = v_today - INTERVAL '1 day'
        AND v_streak_record.last_freeze_used_at > v_streak_record.last_login_date
  THEN
    -- MANUAL freeze-covered single missed day (/api/v1/xp/use-freeze already
    -- decremented the balance and stamped last_freeze_used_at). Clear the
    -- auto-protect flag because this is a manual spend, not a passive bridge.
    v_freeze_applied := true;
    v_new_streak := v_streak_record.current_streak + 1;
    UPDATE user_login_streaks
    SET current_streak = v_new_streak,
        longest_streak = GREATEST(longest_streak, v_new_streak),
        total_logins = total_logins + 1,
        last_login_date = v_today,
        last_daily_bonus_claimed = v_today,
        auto_protected_today = false
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSIF v_streak_record.last_login_date = v_today - INTERVAL '2 days' THEN
    -- Exactly ONE missed day (yesterday) that the manual branch above did NOT
    -- cover. Try to AUTO-CONSUME a banked freeze to keep the streak alive.
    SELECT COALESCE(xp_streak_freezes_available, 0) INTO v_freezes_available
    FROM users
    WHERE id = p_user_id
    FOR UPDATE;

    IF v_freezes_available > 0 THEN
      -- Spend one banked freeze passively.
      v_auto_protected := true;
      v_balance_after := v_freezes_available - 1;

      UPDATE users
      SET xp_streak_freezes_available = v_balance_after
      WHERE id = p_user_id;

      v_new_streak := v_streak_record.current_streak + 1;
      UPDATE user_login_streaks
      SET current_streak = v_new_streak,
          longest_streak = GREATEST(longest_streak, v_new_streak),
          total_logins = total_logins + 1,
          last_login_date = v_today,
          last_daily_bonus_claimed = v_today,
          last_freeze_used_at = v_today - INTERVAL '1 day',  -- mark yesterday covered (double-apply guard)
          auto_protected_today = true
      WHERE user_id = p_user_id
      RETURNING * INTO v_streak_record;

      -- Append an audit row for the passive spend.
      INSERT INTO xp_streak_freeze_ledger
        (user_id, delta, reason, balance_after, streak_day, event_date)
      VALUES
        (p_user_id, -1, 'auto_protect', v_balance_after, v_new_streak, v_today);
    ELSE
      -- No banked freeze: streak breaks.
      v_streak_broken := true;
      UPDATE user_login_streaks
      SET current_streak = 1,
          total_logins = total_logins + 1,
          last_login_date = v_today,
          streak_start_date = v_today,
          last_daily_bonus_claimed = v_today,
          auto_protected_today = false
      WHERE user_id = p_user_id
      RETURNING * INTO v_streak_record;
    END IF;

  ELSE
    -- Gap of 3+ days (or any other case): streak breaks. Auto-consume only
    -- bridges a SINGLE missed day per the skip-chain rule.
    v_streak_broken := true;
    UPDATE user_login_streaks
    SET current_streak = 1,
        total_logins = total_logins + 1,
        last_login_date = v_today,
        streak_start_date = v_today,
        last_daily_bonus_claimed = v_today,
        auto_protected_today = false
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
    'auto_protected', v_auto_protected,
    'freezes_available', COALESCE((SELECT xp_streak_freezes_available FROM users WHERE id = p_user_id), 0),
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
        WHEN v_auto_protected THEN 'A streak freeze auto-saved your streak!'
        WHEN v_freeze_applied THEN 'Streak freeze saved your streak!'
        WHEN v_streak_broken THEN 'Streak reset. Start building a new one!'
        ELSE 'Daily check-in complete!'
      END
  );
END;
$function$;
