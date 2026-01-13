-- Migration 150: Pinned Posts for Social Feed
-- Adds ability for admins to pin posts to top of feed

-- Add pinning columns to activity_feed
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMPTZ;
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS pinned_by UUID REFERENCES users(id);

-- Create partial index for efficient querying of pinned posts
CREATE INDEX IF NOT EXISTS idx_activity_feed_pinned
    ON activity_feed(is_pinned, pinned_at DESC)
    WHERE is_pinned = true;

-- Add comments for documentation
COMMENT ON COLUMN activity_feed.is_pinned IS 'Whether the post is pinned to top of feed. Only admins can set this.';
COMMENT ON COLUMN activity_feed.pinned_at IS 'Timestamp when the post was pinned.';
COMMENT ON COLUMN activity_feed.pinned_by IS 'User ID of the admin who pinned the post.';
