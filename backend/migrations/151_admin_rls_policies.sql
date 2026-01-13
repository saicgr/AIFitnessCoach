-- Migration 151: Admin RLS Policies
-- Updates RLS policies for admin access and support user protection

-- =============================================================================
-- USER CONNECTIONS: Prevent unfriending support user
-- =============================================================================

-- Drop existing delete policy
DROP POLICY IF EXISTS "Users can delete their own connections" ON public.user_connections;

-- Create new delete policy that prevents unfriending the support user
CREATE POLICY "Users can delete their own connections except support user" ON public.user_connections
    FOR DELETE USING (
        follower_id = (SELECT auth.uid())
        AND following_id NOT IN (SELECT id FROM users WHERE is_support_user = true)
    );

-- =============================================================================
-- ACTIVITY FEED: Allow admins to update any post (for pinning)
-- =============================================================================

-- Drop existing update policy
DROP POLICY IF EXISTS "Users can update their own activities" ON public.activity_feed;

-- Create new update policy that allows admins to update any post
CREATE POLICY "Users can update own activities or admin can update any" ON public.activity_feed
    FOR UPDATE USING (
        user_id = (SELECT auth.uid())
        OR EXISTS (SELECT 1 FROM users WHERE id = (SELECT auth.uid()) AND role = 'admin')
    );

-- Drop existing view policy
DROP POLICY IF EXISTS "Users can view public and friends' activities" ON public.activity_feed;

-- Create new view policy that allows admins to view all posts
CREATE POLICY "Users can view public and friends activities or admin view all" ON public.activity_feed
    FOR SELECT USING (
        visibility = 'public'
        OR user_id = (SELECT auth.uid())
        OR (visibility = 'friends' AND EXISTS (
            SELECT 1 FROM user_connections
            WHERE follower_id = (SELECT auth.uid()) AND following_id = activity_feed.user_id
        ))
        OR EXISTS (SELECT 1 FROM users WHERE id = (SELECT auth.uid()) AND role = 'admin')
    );

-- =============================================================================
-- SERVICE ROLE: Allow backend to manage connections for auto-friend
-- =============================================================================

-- Note: Service role bypasses RLS by default when using the service_role key
-- This is needed for auto-adding support user as friend to new users

COMMENT ON POLICY "Users can delete their own connections except support user" ON public.user_connections
    IS 'Prevents users from unfriending the support user (support@fitwiz.us)';

COMMENT ON POLICY "Users can update own activities or admin can update any" ON public.activity_feed
    IS 'Allows admins to pin/unpin any post';

COMMENT ON POLICY "Users can view public and friends activities or admin view all" ON public.activity_feed
    IS 'Allows admins to view all posts regardless of visibility';
