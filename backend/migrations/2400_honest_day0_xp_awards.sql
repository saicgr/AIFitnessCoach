-- 2400_honest_day0_xp_awards.sql
-- E2E register #66 (2026-07-31): a brand-new account reached Level 2 / ~156 XP
-- from onboarding alone, before a single workout or meal. Four independent
-- levers fired stacked on day 0:
--   1. first_login        +100 XP  (process_daily_login, welcome bonus)
--   2. daily_login         +25 XP  (process_daily_login, SAME call as #1)
--   3. first_goal_set      +25 XP  (award-first-time-bonus; "often already
--                                   done in onboarding" per its own comment)
--   4. crate_reward      25-75 XP  (claim_daily_crate; a random-reward roll
--                                   available to an account seconds old)
-- The level-up overlay itself was already gated behind a real completed
-- action (b7d333ac). This migration makes the underlying AWARDS honest so
-- the XP total behind a suppressed overlay isn't itself fabricated.
--
-- Decision — which levers survive, at what value, and why:
--   * first_login KEPT at its current value (100 XP for the still-open
--     first-100-users cohort; see xp_bonus_templates + v_early_adopter_bonus
--     below, both UNCHANGED here). A one-time, clearly-labelled "Welcome to
--     Zealova!" signup gift is honest — it never claims to reflect an
--     accomplishment, and reducing/removing it is a separate product call
--     this row doesn't ask for.
--   * daily_login on the FIRST-EVER call is now SUPPRESSED (was +25). It
--     double-counted the exact same login event the welcome bonus already
--     rewards. The daily check-in streak mechanic is otherwise UNCHANGED —
--     it starts genuinely counting from the user's second day, which is
--     when "you came back" first becomes a true statement.
--   * first_goal_set is zeroed to 0 XP in the same code change this
--     migration ships alongside (api/v1/xp.py FIRST_TIME_BONUSES). Not a
--     DB change (the amount lives in the Python dict, not a table) — noted
--     here for the full picture. It is not a genuine "first-time
--     achievement": every user sets a goal because onboarding requires the
--     field, mirroring the existing first_complete_profile: 0 precedent for
--     "already happens during onboarding, not a separate reward."
--   * crate_reward (claim_daily_crate 'daily' type) now requires the
--     account to be >= 24h old. The daily crate is a real Duolingo-style
--     "you showed up today" mechanic worth keeping every day AFTER the
--     first — but a random XP/consumable roll available before the user has
--     done anything is a slot machine, not a reward. init_daily_crates
--     (read path, feeds the "is a crate available" status the client
--     shows) gets the identical gate so the UI doesn't dangle a crate it
--     will then refuse to open.
--
-- Existing awarded XP is NOT touched — xp_transactions / user_xp / any
-- already-granted user_first_time_bonuses / claimed daily crates keep
-- whatever they were awarded at the time (grandfathered, per
-- feedback_bugfix_class_plus_regression_gate: fix forward, don't retro-punish).
--
-- Baseline for both patched functions verified against production via
-- pg_get_functiondef immediately before writing this migration:
--   process_daily_login  == migrations/2234_streak_freeze_autoconsume.sql body
--   init_daily_crates    == migrations/1898_xp_race_condition_timezone_fixes.sql body
--   claim_daily_crate    == migrations/1899_claim_daily_crate_autoheal.sql body
-- Every other branch, the return shape, and every OTHER XP source are
-- byte-for-byte identical to the live functions; the diffs below are the
-- ONLY behavioral changes.

-- ============================================================================
-- 1. process_daily_login — suppress the daily-login bonus on the SAME call
--    that grants the welcome (first_login) bonus.
-- ============================================================================
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
  v_auto_protected BOOLEAN := false;   -- a BANKED freeze auto-bridged a missed day
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
  v_freezes_available INT := 0;        -- live banked-freeze balance
  v_balance_after INT := 0;            -- balance written to the ledger row
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

  -- E2E #66: the FIRST-EVER call already carries the welcome bonus for this
  -- exact login event — do not ALSO pay the "you checked in today" bonus for
  -- the same event. The streak-XP mechanic now genuinely starts on day 2.
  IF v_is_first_login THEN
    v_daily_bonus := 0;
  END IF;

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

COMMENT ON FUNCTION process_daily_login(UUID, DATE) IS
'Processes daily login, awards XP, updates streaks.
Migration 2400 (E2E #66): the FIRST-EVER call for an account no longer also
pays the daily-login bonus alongside the welcome bonus -- same login event,
was double-counted. Streak-freeze auto-consume (2234) and manual-freeze
(2099) branches unchanged.';

-- ============================================================================
-- 2. init_daily_crates — the "is a crate available" status read now agrees
--    with the 24h-account-age gate claim_daily_crate enforces below, so the
--    client never shows a crate it will then be refused.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.init_daily_crates(
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
  v_created_at TIMESTAMPTZ;
  v_daily_goals RECORD;
  v_record user_daily_crates%ROWTYPE;
  v_streak_available BOOLEAN;
  v_activity_available BOOLEAN;
  v_daily_crate_available BOOLEAN;
BEGIN
  -- Get current streak from user_login_streaks (not user_xp)
  SELECT COALESCE(current_streak, 0) INTO v_streak
  FROM user_login_streaks WHERE user_id = p_user_id;

  -- Streak crate available if streak >= 7
  v_streak_available := COALESCE(v_streak, 0) >= 7;

  -- E2E #66 (2026-07-31): the daily crate used to be TRUE unconditionally,
  -- so a brand-new signup could roll a random XP/consumable reward before
  -- doing anything the app measures. Withhold it until the account is at
  -- least 24h old (timezone-immune -- an elapsed-hours check, not a
  -- calendar-date one); it resumes being available every day after that,
  -- unchanged from the original design.
  SELECT created_at INTO v_created_at FROM users WHERE id = p_user_id;
  v_daily_crate_available := (v_created_at IS NOT NULL)
    AND (NOW() - v_created_at >= INTERVAL '24 hours');

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
    v_daily_crate_available,
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

-- ============================================================================
-- 3. claim_daily_crate — the function that actually AWARDS the crate XP has
--    its OWN fallback row-creation branch (fires when the client calls claim
--    directly without a prior init_daily_crates read, or on a race). That
--    branch hardcoded daily_crate_available := TRUE, bypassing #2's gate
--    entirely. Same 24h-account-age gate applied here so the award path
--    itself is honest, not just the status display.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.claim_daily_crate(
  p_user_id uuid,
  p_crate_type character varying,
  p_crate_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_record user_daily_crates%ROWTYPE;
  v_reward JSONB;
  v_xp_reward INTEGER;
  v_roll INTEGER;
  v_streak INTEGER;
  v_streak_available BOOLEAN;
  v_created_at TIMESTAMPTZ;
  v_daily_crate_available BOOLEAN;
BEGIN
  SELECT * INTO v_record FROM user_daily_crates
  WHERE user_id = p_user_id AND crate_date = p_crate_date
  FOR UPDATE;

  IF v_record.id IS NULL THEN
    SELECT COALESCE(current_streak, 0) INTO v_streak
    FROM user_login_streaks WHERE user_id = p_user_id;
    v_streak_available := COALESCE(v_streak, 0) >= 7;

    -- E2E #66 (2026-07-31): same 24h-account-age gate as init_daily_crates,
    -- applied here too -- this fallback branch is the one that actually
    -- grants XP via award_xp() below, so THIS is the gate that matters.
    SELECT created_at INTO v_created_at FROM users WHERE id = p_user_id;
    v_daily_crate_available := (v_created_at IS NOT NULL)
      AND (NOW() - v_created_at >= INTERVAL '24 hours');

    INSERT INTO user_daily_crates (
      user_id, crate_date,
      daily_crate_available,
      streak_crate_available,
      activity_crate_available
    ) VALUES (
      p_user_id, p_crate_date,
      v_daily_crate_available,
      v_streak_available,
      FALSE
    )
    ON CONFLICT (user_id, crate_date) DO NOTHING
    RETURNING * INTO v_record;

    IF v_record.id IS NULL THEN
      SELECT * INTO v_record FROM user_daily_crates
      WHERE user_id = p_user_id AND crate_date = p_crate_date
      FOR UPDATE;
    END IF;
  END IF;

  IF v_record.selected_crate IS NOT NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Crate already claimed for this date');
  END IF;

  IF p_crate_type = 'daily' AND NOT v_record.daily_crate_available THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Daily crate not available');
  END IF;
  IF p_crate_type = 'streak' AND NOT v_record.streak_crate_available THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Streak crate not available (need 7+ day streak)');
  END IF;
  IF p_crate_type = 'activity' AND NOT v_record.activity_crate_available THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'Activity crate not available (complete all daily goals)');
  END IF;

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

  UPDATE user_daily_crates
  SET selected_crate = p_crate_type,
      reward = v_reward,
      claimed_at = NOW()
  WHERE id = v_record.id;

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
$function$;
