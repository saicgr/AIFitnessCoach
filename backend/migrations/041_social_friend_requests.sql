-- Migration: 041_social_friend_requests.sql
-- Description: Add friend request system and social notifications for social features
-- Date: 2025-12-26

-- ============================================
-- FRIEND REQUESTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  message TEXT,  -- Optional message with request
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,

  -- Prevent duplicate requests (both directions)
  UNIQUE(from_user_id, to_user_id),

  -- Prevent self-requests
  CHECK (from_user_id != to_user_id)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_friend_requests_to_user ON friend_requests(to_user_id, status);
CREATE INDEX IF NOT EXISTS idx_friend_requests_from_user ON friend_requests(from_user_id, status);
CREATE INDEX IF NOT EXISTS idx_friend_requests_created_at ON friend_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);

-- ============================================
-- SOCIAL NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS social_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN (
    'friend_request',
    'friend_accepted',
    'reaction',
    'comment',
    'challenge_invite',
    'challenge_accepted',
    'challenge_completed',
    'workout_shared',
    'achievement_earned'
  )),
  from_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  from_user_name TEXT,
  from_user_avatar TEXT,
  reference_id UUID,  -- ID of related entity (activity_id, challenge_id, etc.)
  reference_type VARCHAR(50),  -- 'activity', 'challenge', 'friend_request'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_social_notifications_user ON social_notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_social_notifications_type ON social_notifications(type);
CREATE INDEX IF NOT EXISTS idx_social_notifications_unread ON social_notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_social_notifications_created_at ON social_notifications(created_at DESC);

-- ============================================
-- UPDATE user_privacy_settings TABLE
-- ============================================

-- Add social notification settings columns if not exist
DO $$
BEGIN
    -- Notification toggles
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_privacy_settings' AND column_name = 'notify_friend_requests') THEN
        ALTER TABLE user_privacy_settings ADD COLUMN notify_friend_requests BOOLEAN DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_privacy_settings' AND column_name = 'notify_reactions') THEN
        ALTER TABLE user_privacy_settings ADD COLUMN notify_reactions BOOLEAN DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_privacy_settings' AND column_name = 'notify_comments') THEN
        ALTER TABLE user_privacy_settings ADD COLUMN notify_comments BOOLEAN DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_privacy_settings' AND column_name = 'notify_challenge_invites') THEN
        ALTER TABLE user_privacy_settings ADD COLUMN notify_challenge_invites BOOLEAN DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_privacy_settings' AND column_name = 'notify_friend_activity') THEN
        ALTER TABLE user_privacy_settings ADD COLUMN notify_friend_activity BOOLEAN DEFAULT true;
    END IF;

    -- Privacy toggle for requiring follow approval
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_privacy_settings' AND column_name = 'require_follow_approval') THEN
        ALTER TABLE user_privacy_settings ADD COLUMN require_follow_approval BOOLEAN DEFAULT false;
    END IF;
END $$;

-- ============================================
-- ROW LEVEL SECURITY (RLS) FOR FRIEND REQUESTS
-- ============================================

ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can send friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can respond to friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can cancel own friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Service role can manage friend requests" ON friend_requests;

-- Users can see requests they sent or received
CREATE POLICY "Users can view own friend requests" ON friend_requests
  FOR SELECT USING (
    auth.uid()::text = from_user_id::text OR
    auth.uid()::text = to_user_id::text
  );

-- Users can create friend requests
CREATE POLICY "Users can send friend requests" ON friend_requests
  FOR INSERT WITH CHECK (auth.uid()::text = from_user_id::text);

-- Users can update requests they received (accept/decline)
CREATE POLICY "Users can respond to friend requests" ON friend_requests
  FOR UPDATE USING (auth.uid()::text = to_user_id::text);

-- Users can delete requests they sent
CREATE POLICY "Users can cancel own friend requests" ON friend_requests
  FOR DELETE USING (auth.uid()::text = from_user_id::text);

-- Service role can manage all friend requests (for backend operations)
CREATE POLICY "Service role can manage friend requests" ON friend_requests
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS FOR SOCIAL NOTIFICATIONS
-- ============================================

ALTER TABLE social_notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own notifications" ON social_notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON social_notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON social_notifications;
DROP POLICY IF EXISTS "Service role can manage notifications" ON social_notifications;

-- Users can see their own notifications
CREATE POLICY "Users can view own notifications" ON social_notifications
  FOR SELECT USING (auth.uid()::text = user_id::text);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON social_notifications
  FOR UPDATE USING (auth.uid()::text = user_id::text);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications" ON social_notifications
  FOR DELETE USING (auth.uid()::text = user_id::text);

-- Service role can manage all notifications (for backend creating notifications)
CREATE POLICY "Service role can manage notifications" ON social_notifications
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get pending friend request count for a user
CREATE OR REPLACE FUNCTION get_pending_friend_request_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM friend_requests
    WHERE to_user_id = p_user_id
    AND status = 'pending'
  );
END;
$$;

-- Function to get unread social notification count for a user
CREATE OR REPLACE FUNCTION get_unread_social_notification_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM social_notifications
    WHERE user_id = p_user_id
    AND is_read = false
  );
END;
$$;

-- Function to check if a friend request exists between two users
CREATE OR REPLACE FUNCTION friend_request_exists(p_from_user_id UUID, p_to_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM friend_requests
    WHERE (from_user_id = p_from_user_id AND to_user_id = p_to_user_id)
    OR (from_user_id = p_to_user_id AND to_user_id = p_from_user_id)
  );
END;
$$;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE friend_requests IS 'Stores friend/follow requests between users with approval workflow';
COMMENT ON COLUMN friend_requests.status IS 'Request status: pending, accepted, or declined';
COMMENT ON COLUMN friend_requests.message IS 'Optional message sent with the friend request';
COMMENT ON COLUMN friend_requests.responded_at IS 'Timestamp when the request was accepted or declined';

COMMENT ON TABLE social_notifications IS 'In-app notifications for social activities (friend requests, reactions, comments, etc.)';
COMMENT ON COLUMN social_notifications.type IS 'Type of notification for routing and display';
COMMENT ON COLUMN social_notifications.reference_id IS 'ID of the related entity (activity, challenge, request)';
COMMENT ON COLUMN social_notifications.reference_type IS 'Type of entity referenced (activity, challenge, friend_request)';
COMMENT ON COLUMN social_notifications.data IS 'Additional JSON data for notification rendering';
