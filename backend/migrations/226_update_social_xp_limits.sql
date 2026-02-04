-- Migration 226: Update Social XP Limits to Match Guide
-- Updates social action limits to match XP_SYSTEM_GUIDE.md specifications
--
-- Changes:
-- - Share: 15 XP, 2/day → 3/day (45 XP max)
-- - React: 5 XP, 5/day → 10/day (50 XP max)
-- - Comment: 10 XP, 3/day → 5/day (50 XP max)
-- - Friend: 15 XP → 25 XP, 3/day → 5/day (125 XP max)
-- - Daily cap: 80 XP → 270 XP (new total possible)

-- =====================================================
-- 1. UPDATE CHECKPOINT REWARDS CONFIG
-- =====================================================

UPDATE checkpoint_rewards
SET
  description = 'Share a post (max 3/day)'
WHERE checkpoint_type = 'social_share';

UPDATE checkpoint_rewards
SET
  description = 'React to a post (max 10/day)'
WHERE checkpoint_type = 'social_react';

UPDATE checkpoint_rewards
SET
  description = 'Comment on a post (max 5/day)'
WHERE checkpoint_type = 'social_comment';

UPDATE checkpoint_rewards
SET
  xp_reward = 25,
  description = 'Add a friend (max 5/day)'
WHERE checkpoint_type = 'social_friend';

-- =====================================================
-- 2. UPDATE SHARE FUNCTION (15 XP, max 3/day)
-- =====================================================

CREATE OR REPLACE FUNCTION award_social_share_xp(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE;
  v_record user_daily_social_xp%ROWTYPE;
  v_xp_to_award INTEGER := 0;
  v_daily_cap INTEGER := 270;
  v_per_action_xp INTEGER := 15;
  v_max_per_day INTEGER := 3;
BEGIN
  v_today := CURRENT_DATE;
  PERFORM init_user_daily_social(p_user_id);

  SELECT * INTO v_record
  FROM user_daily_social_xp
  WHERE user_id = p_user_id AND action_date = v_today;

  -- Check if we can award more XP for shares (max 3 per day)
  IF v_record.shares_count < v_max_per_day THEN
    -- Check against daily cap
    IF v_record.total_social_xp_today < v_daily_cap THEN
      v_xp_to_award := LEAST(v_per_action_xp, v_daily_cap - v_record.total_social_xp_today);

      UPDATE user_daily_social_xp
      SET
        shares_count = shares_count + 1,
        shares_xp_awarded = shares_xp_awarded + v_xp_to_award,
        total_social_xp_today = total_social_xp_today + v_xp_to_award,
        updated_at = NOW()
      WHERE user_id = p_user_id AND action_date = v_today
      RETURNING * INTO v_record;

      -- Award XP
      IF v_xp_to_award > 0 THEN
        PERFORM award_xp(p_user_id, v_xp_to_award, 'social_share', NULL,
                         'Shared a post');
      END IF;
    END IF;
  END IF;

  -- Also update monthly achievement
  BEGIN
    PERFORM increment_monthly_posts_shared(p_user_id);
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN jsonb_build_object(
    'success', TRUE,
    'action', 'share',
    'shares_today', v_record.shares_count,
    'max_per_day', v_max_per_day,
    'xp_awarded', v_xp_to_award,
    'total_social_xp_today', v_record.total_social_xp_today,
    'daily_cap', v_daily_cap,
    'at_cap', v_record.total_social_xp_today >= v_daily_cap
  );
END;
$$;

-- =====================================================
-- 3. UPDATE REACT FUNCTION (5 XP, max 10/day)
-- =====================================================

CREATE OR REPLACE FUNCTION award_social_react_xp(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE;
  v_record user_daily_social_xp%ROWTYPE;
  v_xp_to_award INTEGER := 0;
  v_daily_cap INTEGER := 270;
  v_per_action_xp INTEGER := 5;
  v_max_per_day INTEGER := 10;
BEGIN
  v_today := CURRENT_DATE;
  PERFORM init_user_daily_social(p_user_id);

  SELECT * INTO v_record
  FROM user_daily_social_xp
  WHERE user_id = p_user_id AND action_date = v_today;

  IF v_record.reactions_count < v_max_per_day THEN
    IF v_record.total_social_xp_today < v_daily_cap THEN
      v_xp_to_award := LEAST(v_per_action_xp, v_daily_cap - v_record.total_social_xp_today);

      UPDATE user_daily_social_xp
      SET
        reactions_count = reactions_count + 1,
        reactions_xp_awarded = reactions_xp_awarded + v_xp_to_award,
        total_social_xp_today = total_social_xp_today + v_xp_to_award,
        updated_at = NOW()
      WHERE user_id = p_user_id AND action_date = v_today
      RETURNING * INTO v_record;

      IF v_xp_to_award > 0 THEN
        PERFORM award_xp(p_user_id, v_xp_to_award, 'social_react', NULL,
                         'Reacted to a post');
      END IF;
    END IF;
  END IF;

  -- Also update monthly achievement
  BEGIN
    PERFORM increment_monthly_social_interaction(p_user_id, 'reaction');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN jsonb_build_object(
    'success', TRUE,
    'action', 'react',
    'reactions_today', v_record.reactions_count,
    'max_per_day', v_max_per_day,
    'xp_awarded', v_xp_to_award,
    'total_social_xp_today', v_record.total_social_xp_today,
    'daily_cap', v_daily_cap,
    'at_cap', v_record.total_social_xp_today >= v_daily_cap
  );
END;
$$;

-- =====================================================
-- 4. UPDATE COMMENT FUNCTION (10 XP, max 5/day)
-- =====================================================

CREATE OR REPLACE FUNCTION award_social_comment_xp(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE;
  v_record user_daily_social_xp%ROWTYPE;
  v_xp_to_award INTEGER := 0;
  v_daily_cap INTEGER := 270;
  v_per_action_xp INTEGER := 10;
  v_max_per_day INTEGER := 5;
BEGIN
  v_today := CURRENT_DATE;
  PERFORM init_user_daily_social(p_user_id);

  SELECT * INTO v_record
  FROM user_daily_social_xp
  WHERE user_id = p_user_id AND action_date = v_today;

  IF v_record.comments_count < v_max_per_day THEN
    IF v_record.total_social_xp_today < v_daily_cap THEN
      v_xp_to_award := LEAST(v_per_action_xp, v_daily_cap - v_record.total_social_xp_today);

      UPDATE user_daily_social_xp
      SET
        comments_count = comments_count + 1,
        comments_xp_awarded = comments_xp_awarded + v_xp_to_award,
        total_social_xp_today = total_social_xp_today + v_xp_to_award,
        updated_at = NOW()
      WHERE user_id = p_user_id AND action_date = v_today
      RETURNING * INTO v_record;

      IF v_xp_to_award > 0 THEN
        PERFORM award_xp(p_user_id, v_xp_to_award, 'social_comment', NULL,
                         'Commented on a post');
      END IF;
    END IF;
  END IF;

  -- Also update monthly achievement
  BEGIN
    PERFORM increment_monthly_social_interaction(p_user_id, 'comment');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN jsonb_build_object(
    'success', TRUE,
    'action', 'comment',
    'comments_today', v_record.comments_count,
    'max_per_day', v_max_per_day,
    'xp_awarded', v_xp_to_award,
    'total_social_xp_today', v_record.total_social_xp_today,
    'daily_cap', v_daily_cap,
    'at_cap', v_record.total_social_xp_today >= v_daily_cap
  );
END;
$$;

-- =====================================================
-- 5. UPDATE FRIEND FUNCTION (25 XP, max 5/day)
-- =====================================================

CREATE OR REPLACE FUNCTION award_social_friend_xp(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE;
  v_record user_daily_social_xp%ROWTYPE;
  v_xp_to_award INTEGER := 0;
  v_daily_cap INTEGER := 270;
  v_per_action_xp INTEGER := 25;
  v_max_per_day INTEGER := 5;
BEGIN
  v_today := CURRENT_DATE;
  PERFORM init_user_daily_social(p_user_id);

  SELECT * INTO v_record
  FROM user_daily_social_xp
  WHERE user_id = p_user_id AND action_date = v_today;

  IF v_record.friends_count < v_max_per_day THEN
    IF v_record.total_social_xp_today < v_daily_cap THEN
      v_xp_to_award := LEAST(v_per_action_xp, v_daily_cap - v_record.total_social_xp_today);

      UPDATE user_daily_social_xp
      SET
        friends_count = friends_count + 1,
        friends_xp_awarded = friends_xp_awarded + v_xp_to_award,
        total_social_xp_today = total_social_xp_today + v_xp_to_award,
        updated_at = NOW()
      WHERE user_id = p_user_id AND action_date = v_today
      RETURNING * INTO v_record;

      IF v_xp_to_award > 0 THEN
        PERFORM award_xp(p_user_id, v_xp_to_award, 'social_friend', NULL,
                         'Added a friend');
      END IF;
    END IF;
  END IF;

  -- Also update monthly achievement
  BEGIN
    PERFORM increment_monthly_friends(p_user_id);
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN jsonb_build_object(
    'success', TRUE,
    'action', 'friend',
    'friends_today', v_record.friends_count,
    'max_per_day', v_max_per_day,
    'xp_awarded', v_xp_to_award,
    'total_social_xp_today', v_record.total_social_xp_today,
    'daily_cap', v_daily_cap,
    'at_cap', v_record.total_social_xp_today >= v_daily_cap
  );
END;
$$;

-- =====================================================
-- 6. UPDATE GET STATUS FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_daily_social_xp_status(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE;
  v_record user_daily_social_xp%ROWTYPE;
  v_daily_cap INTEGER := 270;
BEGIN
  v_today := CURRENT_DATE;
  PERFORM init_user_daily_social(p_user_id);

  SELECT * INTO v_record
  FROM user_daily_social_xp
  WHERE user_id = p_user_id AND action_date = v_today;

  RETURN jsonb_build_object(
    'date', v_today,
    'total_social_xp_today', COALESCE(v_record.total_social_xp_today, 0),
    'daily_cap', v_daily_cap,
    'remaining_cap', v_daily_cap - COALESCE(v_record.total_social_xp_today, 0),
    'at_cap', COALESCE(v_record.total_social_xp_today, 0) >= v_daily_cap,
    'actions', jsonb_build_array(
      jsonb_build_object(
        'id', 'share',
        'name', 'Share Post',
        'description', 'Share your progress or achievements',
        'icon', 'share',
        'xp_per_action', 15,
        'count_today', COALESCE(v_record.shares_count, 0),
        'max_per_day', 3,
        'xp_awarded_today', COALESCE(v_record.shares_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.shares_count, 0) < 3 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      ),
      jsonb_build_object(
        'id', 'react',
        'name', 'React to Post',
        'description', 'Like or react to a friend''s post',
        'icon', 'favorite',
        'xp_per_action', 5,
        'count_today', COALESCE(v_record.reactions_count, 0),
        'max_per_day', 10,
        'xp_awarded_today', COALESCE(v_record.reactions_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.reactions_count, 0) < 10 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      ),
      jsonb_build_object(
        'id', 'comment',
        'name', 'Comment',
        'description', 'Leave an encouraging comment',
        'icon', 'chat_bubble',
        'xp_per_action', 10,
        'count_today', COALESCE(v_record.comments_count, 0),
        'max_per_day', 5,
        'xp_awarded_today', COALESCE(v_record.comments_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.comments_count, 0) < 5 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      ),
      jsonb_build_object(
        'id', 'friend',
        'name', 'Add Friend',
        'description', 'Connect with new workout buddies',
        'icon', 'person_add',
        'xp_per_action', 25,
        'count_today', COALESCE(v_record.friends_count, 0),
        'max_per_day', 5,
        'xp_awarded_today', COALESCE(v_record.friends_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.friends_count, 0) < 5 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      )
    )
  );
END;
$$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Updated social XP limits to match XP_SYSTEM_GUIDE.md:
--
-- | Action     | XP  | Limit   | Max Daily |
-- |------------|-----|---------|-----------|
-- | Share      | 15  | 3/day   | 45 XP     |
-- | React      | 5   | 10/day  | 50 XP     |
-- | Comment    | 10  | 5/day   | 50 XP     |
-- | Add Friend | 25  | 5/day   | 125 XP    |
-- |------------|-----|---------|-----------|
-- | TOTAL      |     |         | 270 XP    |
--
-- Note: Daily cap increased from 80 XP to 270 XP to allow
-- full social engagement without artificial limits.
