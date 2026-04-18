-- ============================================================================
-- Migration 1932: Referral program + dedicated merch notification toggles
-- ============================================================================
-- Two layers:
--
-- A. Fix the nudge gate gap: add explicit toggles for merch-specific push/email
--    notifications (per feedback_user_notification_control.md — every new
--    notification type needs its own user-facing toggle).
--
-- B. Bring the existing `referral_tracking` table (from migration 164) to life:
--    - Give every user a permanent 6-char referral_code
--    - Track when a referred user first completes a workout (qualifies them)
--    - Auto-award merch at cumulative referral milestones: 3/5/10/25/50/100
--    - Two-sided instant reward on qualification (both users)
-- ============================================================================


-- ============================================================================
-- 1. Notification toggles
-- ============================================================================
ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS push_merch_alerts BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_merch_alerts BOOLEAN DEFAULT TRUE;

ALTER TABLE email_preferences
  ADD COLUMN IF NOT EXISTS achievement_emails BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS merch_emails BOOLEAN DEFAULT TRUE;

COMMENT ON COLUMN notification_preferences.push_merch_alerts IS
'Toggle for push notifications related to physical merch rewards (proximity, unlocked, claim reminder).';
COMMENT ON COLUMN email_preferences.merch_emails IS
'Toggle for email notifications related to physical merch rewards.';


-- ============================================================================
-- 2. Users: referral_code + first-workout timestamp
-- ============================================================================
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS referred_by_code TEXT,  -- code the user signed up with
  ADD COLUMN IF NOT EXISTS first_workout_completed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code) WHERE referral_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_referred_by_code ON users(referred_by_code) WHERE referred_by_code IS NOT NULL;


-- ============================================================================
-- 3. generate_referral_code: make a unique 6-char alphanumeric code
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_referral_code(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing TEXT;
  v_candidate TEXT;
  v_alphabet TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';  -- no O/0/I/1 confusion
  v_attempts INT := 0;
BEGIN
  SELECT referral_code INTO v_existing FROM users WHERE id = p_user_id;
  IF v_existing IS NOT NULL THEN
    RETURN v_existing;
  END IF;

  LOOP
    v_candidate := '';
    FOR i IN 1..6 LOOP
      v_candidate := v_candidate || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::INT, 1);
    END LOOP;

    BEGIN
      UPDATE users SET referral_code = v_candidate WHERE id = p_user_id;
      RETURN v_candidate;
    EXCEPTION WHEN unique_violation THEN
      v_attempts := v_attempts + 1;
      IF v_attempts > 20 THEN
        RAISE EXCEPTION 'Failed to generate unique referral code after 20 attempts';
      END IF;
      -- try again
    END;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_referral_code(UUID) TO authenticated, service_role;


-- ============================================================================
-- 4. apply_referral_code: new user applies a referrer's code
--    - Creates referral_tracking row (status='pending')
--    - Records code on user row
--    - Rejects self-referrals and reused codes
-- ============================================================================
CREATE OR REPLACE FUNCTION apply_referral_code(
  p_user_id UUID,
  p_code TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_referrer_id UUID;
  v_existing TEXT;
BEGIN
  -- Normalize code
  p_code := UPPER(TRIM(p_code));
  IF p_code IS NULL OR length(p_code) <> 6 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Invalid code format');
  END IF;

  -- Already applied?
  SELECT referred_by_code INTO v_existing FROM users WHERE id = p_user_id;
  IF v_existing IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'You have already applied a referral code');
  END IF;

  -- Find referrer
  SELECT id INTO v_referrer_id FROM users WHERE referral_code = p_code;
  IF v_referrer_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Referral code not found');
  END IF;

  IF v_referrer_id = p_user_id THEN
    RETURN jsonb_build_object('success', false, 'message', 'You cannot refer yourself');
  END IF;

  -- Create referral_tracking row
  INSERT INTO referral_tracking (referrer_id, referred_id, referral_code, status)
  VALUES (v_referrer_id, p_user_id, p_code, 'pending')
  ON CONFLICT (referrer_id, referred_id) DO NOTHING;

  UPDATE users SET referred_by_code = p_code WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'referrer_id', v_referrer_id,
    'message', 'Referral applied — complete your first workout to qualify.'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION apply_referral_code(UUID, TEXT) TO authenticated, service_role;


-- ============================================================================
-- 5. Merch awarding at referral milestones
-- ============================================================================

-- Referral milestones (ordered) → merch_type awarded to the referrer
--   3 refs   -> sticker_pack
--   10 refs  -> shaker_bottle      (viral lever, earned not auto-granted)
--   25 refs  -> t_shirt
--   50 refs  -> hoodie
--   100 refs -> full_merch_kit
--   250 refs -> signed_premium_kit
CREATE OR REPLACE FUNCTION check_referral_milestone_rewards(p_referrer_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_qualified INT;
  v_awarded JSONB := '[]'::JSONB;
  v_claim_id UUID;
  v_milestones INT[] := ARRAY[3, 10, 25, 50, 100, 250];
  v_merch_types TEXT[] := ARRAY['sticker_pack','shaker_bottle','t_shirt','hoodie','full_merch_kit','signed_premium_kit'];
  v_virtual_level INT[] := ARRAY[1003, 1010, 1025, 1050, 1100, 1250];
  i INT;
  v_threshold INT;
  v_merch TEXT;
  v_vlevel INT;
BEGIN
  SELECT COUNT(*) INTO v_qualified
  FROM referral_tracking
  WHERE referrer_id = p_referrer_id
    AND status IN ('qualified', 'rewarded');

  FOR i IN 1..array_length(v_milestones, 1) LOOP
    v_threshold := v_milestones[i];
    v_merch := v_merch_types[i];
    v_vlevel := v_virtual_level[i];

    IF v_qualified < v_threshold THEN
      EXIT;  -- not reached yet
    END IF;

    -- Idempotency via unique (user_id, awarded_at_level).
    -- We use a virtual level >=1000 so referral merch never collides with XP-level merch.
    INSERT INTO merch_claims (user_id, merch_type, awarded_at_level, status)
    VALUES (p_referrer_id, v_merch, v_vlevel, 'pending_address')
    ON CONFLICT (user_id, awarded_at_level) DO NOTHING
    RETURNING id INTO v_claim_id;

    IF v_claim_id IS NOT NULL THEN
      v_awarded := v_awarded || jsonb_build_array(jsonb_build_object(
        'milestone', v_threshold,
        'merch_type', v_merch,
        'claim_id', v_claim_id
      ));
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'qualified_count', v_qualified,
    'new_merch_awarded', v_awarded
  );
END;
$$;

GRANT EXECUTE ON FUNCTION check_referral_milestone_rewards(UUID) TO authenticated, service_role;


-- ============================================================================
-- 6. mark_referral_qualified: called when the referred user completes first workout
-- ============================================================================
CREATE OR REPLACE FUNCTION mark_referral_qualified(p_referred_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tracking referral_tracking;
  v_referrer_id UUID;
  v_instant JSONB;
BEGIN
  -- Record first_workout_completed_at (only on the first workout)
  UPDATE users
  SET first_workout_completed_at = COALESCE(first_workout_completed_at, NOW())
  WHERE id = p_referred_id;

  -- Is there an open referral to qualify?
  SELECT * INTO v_tracking FROM referral_tracking
  WHERE referred_id = p_referred_id AND status IN ('pending','signup_complete')
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('qualified', false, 'message', 'No pending referral for this user');
  END IF;

  v_referrer_id := v_tracking.referrer_id;

  UPDATE referral_tracking
  SET status = 'qualified', updated_at = NOW()
  WHERE id = v_tracking.id;

  -- Two-sided instant reward:
  --   Both referrer + referee get 2x Premium Crate + 500 XP + 24h 2x XP token
  PERFORM add_consumable(v_referrer_id, 'premium_crate', 2);
  PERFORM add_consumable(v_referrer_id, 'xp_token_2x', 1);
  PERFORM award_xp(v_referrer_id, 500, 'referral_qualified', v_tracking.id::text,
                   'Your referral completed their first workout!', false, false);

  PERFORM add_consumable(p_referred_id, 'premium_crate', 2);
  PERFORM add_consumable(p_referred_id, 'xp_token_2x', 1);
  PERFORM award_xp(p_referred_id, 500, 'welcome_bonus_referred', v_tracking.id::text,
                   'Welcome bonus from your referrer!', false, true);

  -- Check for milestone merch
  v_instant := check_referral_milestone_rewards(v_referrer_id);

  RETURN jsonb_build_object(
    'qualified', true,
    'referrer_id', v_referrer_id,
    'milestone_check', v_instant
  );
END;
$$;

GRANT EXECUTE ON FUNCTION mark_referral_qualified(UUID) TO authenticated, service_role;


-- ============================================================================
-- 7. get_referral_summary: single-call summary for the referrals screen
-- ============================================================================
CREATE OR REPLACE FUNCTION get_referral_summary(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code TEXT;
  v_pending INT;
  v_qualified INT;
  v_next_milestone INT;
  v_next_merch TEXT;
BEGIN
  SELECT referral_code INTO v_code FROM users WHERE id = p_user_id;
  IF v_code IS NULL THEN
    v_code := generate_referral_code(p_user_id);
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE status IN ('pending','signup_complete')),
    COUNT(*) FILTER (WHERE status IN ('qualified','rewarded'))
  INTO v_pending, v_qualified
  FROM referral_tracking
  WHERE referrer_id = p_user_id;

  -- Next milestone
  IF v_qualified < 3 THEN v_next_milestone := 3;   v_next_merch := 'sticker_pack';
  ELSIF v_qualified < 10 THEN v_next_milestone := 10;  v_next_merch := 'shaker_bottle';
  ELSIF v_qualified < 25 THEN v_next_milestone := 25;  v_next_merch := 't_shirt';
  ELSIF v_qualified < 50 THEN v_next_milestone := 50;  v_next_merch := 'hoodie';
  ELSIF v_qualified < 100 THEN v_next_milestone := 100; v_next_merch := 'full_merch_kit';
  ELSIF v_qualified < 250 THEN v_next_milestone := 250; v_next_merch := 'signed_premium_kit';
  ELSE v_next_milestone := NULL; v_next_merch := NULL;
  END IF;

  RETURN jsonb_build_object(
    'referral_code', v_code,
    'pending_count', v_pending,
    'qualified_count', v_qualified,
    'next_milestone', v_next_milestone,
    'next_merch_type', v_next_merch
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_referral_summary(UUID) TO authenticated, service_role;
