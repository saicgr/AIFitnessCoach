-- Migration: 1636_user_mentions
-- Description: Create activity_mentions table for @mention tracking

CREATE TABLE IF NOT EXISTS activity_mentions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
    mentioned_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    UNIQUE(activity_id, mentioned_user_id)
);

-- Index for fast lookups by mentioned user
CREATE INDEX IF NOT EXISTS idx_activity_mentions_mentioned_user_id
    ON activity_mentions(mentioned_user_id);
