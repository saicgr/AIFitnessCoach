-- Migration 224: Daily Social XP Tracking
-- Tracks 4 daily social actions worth up to 80 XP per day (capped)

-- =====================================================
-- 1. CREATE DAILY SOCIAL XP TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_daily_social_xp (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_date DATE NOT NULL,

  -- Social Action 1: Share Post (15 XP, 2 per day max = 30 XP)
  shares_count INTEGER DEFAULT 0,
  shares_xp_awarded INTEGER DEFAULT 0,

  -- Social Action 2: React to Post (5 XP, 5 per day max = 25 XP)
  reactions_count INTEGER DEFAULT 0,
  reactions_xp_awarded INTEGER DEFAULT 0,

  -- Social Action 3: Comment on Post (10 XP, 3 per day max = 30 XP)
  comments_count INTEGER DEFAULT 0,
  comments_xp_awarded INTEGER DEFAULT 0,

  -- Social Action 4: Add Friend (15 XP, 3 per day max = 45 XP)
  friends_count INTEGER DEFAULT 0,
  friends_xp_awarded INTEGER DEFAULT 0,

  -- Total daily cap: 80 XP
  total_social_xp_today INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, action_date)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_daily_social_user_date
ON user_daily_social_xp(user_id, action_date);

-- =====================================================
-- 2. SOCIAL XP REWARDS CONFIG
-- =====================================================

-- Add to checkpoint_rewards if it exists, otherwise create entries
INSERT INTO checkpoint_rewards (checkpoint_type, period_type, xp_reward, description)
VALUES
  ('social_share', 'daily', 15, 'Share a post (max 2/day)'),
  ('social_react', 'daily', 5, 'React to a post (max 5/day)'),
  ('social_comment', 'daily', 10, 'Comment on a post (max 3/day)'),
  ('social_friend', 'daily', 15, 'Add a friend (max 3/day)')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 3. INITIALIZE DAILY SOCIAL RECORD
-- =====================================================

CREATE OR REPLACE FUNCTION init_user_daily_social(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE;
  v_record_id UUID;
BEGIN
  v_today := CURRENT_DATE;

  INSERT INTO user_daily_social_xp (user_id, action_date)
  VALUES (p_user_id, v_today)
  ON CONFLICT (user_id, action_date) DO NOTHING
  RETURNING id INTO v_record_id;

  IF v_record_id IS NULL THEN
    SELECT id INTO v_record_id
    FROM user_daily_social_xp
    WHERE user_id = p_user_id AND action_date = v_today;
  END IF;

  RETURN v_record_id;
END;
$$;

-- =====================================================
-- 4. DAILY SOCIAL XP CAP CONSTANT
-- =====================================================
-- Total daily social XP cap: 80 XP
-- Share: 15 XP x 2 = 30 XP max
-- React: 5 XP x 5 = 25 XP max
-- Comment: 10 XP x 3 = 30 XP max
-- Friend: 15 XP x 3 = 45 XP max
-- Total possible: 130 XP, but capped at 80 XP

-- =====================================================
-- 5. INCREMENT FUNCTIONS FOR SOCIAL ACTIONS
-- =====================================================

-- 5.1 Award Social Share XP (15 XP, max 2/day)
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
  v_daily_cap INTEGER := 80;
  v_per_action_xp INTEGER := 15;
  v_max_per_day INTEGER := 2;
BEGIN
  v_today := CURRENT_DATE;
  PERFORM init_user_daily_social(p_user_id);

  SELECT * INTO v_record
  FROM user_daily_social_xp
  WHERE user_id = p_user_id AND action_date = v_today;

  -- Check if we can award more XP for shares (max 2 per day)
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
    -- Function may not exist yet, ignore
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

-- 5.2 Award Social React XP (5 XP, max 5/day)
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
  v_daily_cap INTEGER := 80;
  v_per_action_xp INTEGER := 5;
  v_max_per_day INTEGER := 5;
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

-- 5.3 Award Social Comment XP (10 XP, max 3/day)
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
  v_daily_cap INTEGER := 80;
  v_per_action_xp INTEGER := 10;
  v_max_per_day INTEGER := 3;
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

-- 5.4 Award Social Friend XP (15 XP, max 3/day)
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
  v_daily_cap INTEGER := 80;
  v_per_action_xp INTEGER := 15;
  v_max_per_day INTEGER := 3;
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
-- 6. GET DAILY SOCIAL XP STATUS
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
  v_daily_cap INTEGER := 80;
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
        'max_per_day', 2,
        'xp_awarded_today', COALESCE(v_record.shares_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.shares_count, 0) < 2 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      ),
      jsonb_build_object(
        'id', 'react',
        'name', 'React to Post',
        'description', 'Like or react to a friend''s post',
        'icon', 'favorite',
        'xp_per_action', 5,
        'count_today', COALESCE(v_record.reactions_count, 0),
        'max_per_day', 5,
        'xp_awarded_today', COALESCE(v_record.reactions_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.reactions_count, 0) < 5 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      ),
      jsonb_build_object(
        'id', 'comment',
        'name', 'Comment',
        'description', 'Leave an encouraging comment',
        'icon', 'chat_bubble',
        'xp_per_action', 10,
        'count_today', COALESCE(v_record.comments_count, 0),
        'max_per_day', 3,
        'xp_awarded_today', COALESCE(v_record.comments_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.comments_count, 0) < 3 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      ),
      jsonb_build_object(
        'id', 'friend',
        'name', 'Add Friend',
        'description', 'Connect with new workout buddies',
        'icon', 'person_add',
        'xp_per_action', 15,
        'count_today', COALESCE(v_record.friends_count, 0),
        'max_per_day', 3,
        'xp_awarded_today', COALESCE(v_record.friends_xp_awarded, 0),
        'can_earn_more', COALESCE(v_record.friends_count, 0) < 3 AND COALESCE(v_record.total_social_xp_today, 0) < v_daily_cap
      )
    )
  );
END;
$$;

-- =====================================================
-- 7. RLS POLICIES
-- =====================================================

ALTER TABLE user_daily_social_xp ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own daily social xp"
ON user_daily_social_xp FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily social xp"
ON user_daily_social_xp FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily social xp"
ON user_daily_social_xp FOR UPDATE
USING (auth.uid() = user_id);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION init_user_daily_social TO authenticated;
GRANT EXECUTE ON FUNCTION award_social_share_xp TO authenticated;
GRANT EXECUTE ON FUNCTION award_social_react_xp TO authenticated;
GRANT EXECUTE ON FUNCTION award_social_comment_xp TO authenticated;
GRANT EXECUTE ON FUNCTION award_social_friend_xp TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_social_xp_status TO authenticated;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration adds:
-- 1. user_daily_social_xp table tracking daily social actions
-- 2. 4 social action types: Share, React, Comment, Add Friend
-- 3. Individual increment functions with per-action limits
-- 4. Daily cap of 80 XP total from social actions
-- 5. Integration with monthly achievements (posts_shared, reactions, friends)
-- 6. get_daily_social_xp_status for UI display
--
-- Daily XP breakdown:
-- - Share: 15 XP x 2 = 30 XP max
-- - React: 5 XP x 5 = 25 XP max
-- - Comment: 10 XP x 3 = 30 XP max
-- - Friend: 15 XP x 3 = 45 XP max
-- - Daily cap: 80 XP (prevents gaming)
