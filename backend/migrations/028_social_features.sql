-- Migration: Social Features
-- Created: 2025-12-24
-- Description: Tables for social connections, activity feed, challenges, and interactions

-- ============================================================
-- USER CONNECTIONS (Friends/Following)
-- ============================================================

CREATE TABLE IF NOT EXISTS user_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Connection type
    connection_type VARCHAR(20) DEFAULT 'following', -- 'following', 'friend' (mutual), 'family'

    -- Status
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'blocked', 'muted'

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Prevent duplicate connections
    UNIQUE(follower_id, following_id),

    -- Prevent self-following
    CHECK (follower_id != following_id)
);

CREATE INDEX idx_user_connections_follower ON user_connections(follower_id);
CREATE INDEX idx_user_connections_following ON user_connections(following_id);
CREATE INDEX idx_user_connections_type ON user_connections(connection_type);

-- ============================================================
-- ACTIVITY FEED
-- ============================================================

CREATE TABLE IF NOT EXISTS activity_feed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Activity type
    activity_type VARCHAR(50) NOT NULL, -- 'workout_completed', 'achievement_earned', 'personal_record', 'weight_milestone', 'streak_milestone'

    -- Activity data (JSON for flexibility)
    activity_data JSONB NOT NULL DEFAULT '{}',

    -- Visibility
    visibility VARCHAR(20) DEFAULT 'friends', -- 'public', 'friends', 'family', 'private'

    -- Engagement metrics
    reaction_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Optional references
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,
    achievement_id UUID REFERENCES user_achievements(id) ON DELETE SET NULL,
    pr_id UUID REFERENCES personal_records(id) ON DELETE SET NULL
);

CREATE INDEX idx_activity_feed_user ON activity_feed(user_id);
CREATE INDEX idx_activity_feed_type ON activity_feed(activity_type);
CREATE INDEX idx_activity_feed_created ON activity_feed(created_at DESC);
CREATE INDEX idx_activity_feed_visibility ON activity_feed(visibility);

-- ============================================================
-- REACTIONS (Likes, Cheers, etc.)
-- ============================================================

CREATE TABLE IF NOT EXISTS activity_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Reaction type
    reaction_type VARCHAR(20) NOT NULL, -- 'cheer', 'fire', 'strong', 'clap', 'heart'

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- One reaction per user per activity
    UNIQUE(activity_id, user_id)
);

CREATE INDEX idx_reactions_activity ON activity_reactions(activity_id);
CREATE INDEX idx_reactions_user ON activity_reactions(user_id);

-- Update reaction count trigger
CREATE OR REPLACE FUNCTION update_activity_reaction_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE activity_feed
        SET reaction_count = reaction_count + 1
        WHERE id = NEW.activity_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE activity_feed
        SET reaction_count = reaction_count - 1
        WHERE id = OLD.activity_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reaction_count
AFTER INSERT OR DELETE ON activity_reactions
FOR EACH ROW EXECUTE FUNCTION update_activity_reaction_count();

-- ============================================================
-- COMMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS activity_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    comment_text TEXT NOT NULL,

    -- Reply support
    parent_comment_id UUID REFERENCES activity_comments(id) ON DELETE CASCADE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_comments_activity ON activity_comments(activity_id);
CREATE INDEX idx_comments_user ON activity_comments(user_id);
CREATE INDEX idx_comments_parent ON activity_comments(parent_comment_id);

-- Update comment count trigger
CREATE OR REPLACE FUNCTION update_activity_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE activity_feed
        SET comment_count = comment_count + 1
        WHERE id = NEW.activity_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE activity_feed
        SET comment_count = comment_count - 1
        WHERE id = OLD.activity_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_comment_count
AFTER INSERT OR DELETE ON activity_comments
FOR EACH ROW EXECUTE FUNCTION update_activity_comment_count();

-- ============================================================
-- CHALLENGES
-- ============================================================

CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Challenge info
    title VARCHAR(200) NOT NULL,
    description TEXT,

    -- Challenge type
    challenge_type VARCHAR(50) NOT NULL, -- 'workout_count', 'workout_streak', 'total_volume', 'weight_loss', 'step_count', 'custom'

    -- Goal
    goal_value DOUBLE PRECISION NOT NULL,
    goal_unit VARCHAR(50), -- 'workouts', 'days', 'kg', 'lbs', 'steps', etc.

    -- Time period
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Creator
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Visibility
    is_public BOOLEAN DEFAULT false,

    -- Metadata
    participant_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CHECK (end_date > start_date)
);

CREATE INDEX idx_challenges_type ON challenges(challenge_type);
CREATE INDEX idx_challenges_dates ON challenges(start_date, end_date);
CREATE INDEX idx_challenges_creator ON challenges(created_by);

-- ============================================================
-- CHALLENGE PARTICIPANTS
-- ============================================================

CREATE TABLE IF NOT EXISTS challenge_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Progress
    current_value DOUBLE PRECISION DEFAULT 0,
    progress_percentage DOUBLE PRECISION DEFAULT 0,

    -- Status
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'failed', 'quit'
    completed_at TIMESTAMP WITH TIME ZONE,

    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- One participation per user per challenge
    UNIQUE(challenge_id, user_id)
);

CREATE INDEX idx_challenge_participants_challenge ON challenge_participants(challenge_id);
CREATE INDEX idx_challenge_participants_user ON challenge_participants(user_id);
CREATE INDEX idx_challenge_participants_status ON challenge_participants(status);

-- Update participant count trigger
CREATE OR REPLACE FUNCTION update_challenge_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE challenges
        SET participant_count = participant_count + 1
        WHERE id = NEW.challenge_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE challenges
        SET participant_count = participant_count - 1
        WHERE id = OLD.challenge_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_participant_count
AFTER INSERT OR DELETE ON challenge_participants
FOR EACH ROW EXECUTE FUNCTION update_challenge_participant_count();

-- ============================================================
-- USER PRIVACY SETTINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS user_privacy_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

    -- Profile visibility
    profile_visibility VARCHAR(20) DEFAULT 'friends', -- 'public', 'friends', 'private'

    -- Activity visibility
    show_workouts BOOLEAN DEFAULT true,
    show_achievements BOOLEAN DEFAULT true,
    show_weight_progress BOOLEAN DEFAULT false,
    show_personal_records BOOLEAN DEFAULT true,

    -- Social features
    allow_friend_requests BOOLEAN DEFAULT true,
    allow_challenge_invites BOOLEAN DEFAULT true,

    -- Leaderboards
    show_on_leaderboards BOOLEAN DEFAULT true,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;

-- User Connections policies
CREATE POLICY "Users can view their own connections"
    ON user_connections FOR SELECT
    USING (follower_id = auth.uid() OR following_id = auth.uid());

CREATE POLICY "Users can create their own connections"
    ON user_connections FOR INSERT
    WITH CHECK (follower_id = auth.uid());

CREATE POLICY "Users can delete their own connections"
    ON user_connections FOR DELETE
    USING (follower_id = auth.uid());

-- Activity Feed policies
CREATE POLICY "Users can view public and friends' activities"
    ON activity_feed FOR SELECT
    USING (
        visibility = 'public'
        OR user_id = auth.uid()
        OR (visibility = 'friends' AND EXISTS (
            SELECT 1 FROM user_connections
            WHERE follower_id = auth.uid() AND following_id = activity_feed.user_id
        ))
    );

CREATE POLICY "Users can create their own activities"
    ON activity_feed FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own activities"
    ON activity_feed FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own activities"
    ON activity_feed FOR DELETE
    USING (user_id = auth.uid());

-- Reactions policies
CREATE POLICY "Users can view all reactions"
    ON activity_reactions FOR SELECT
    USING (true);

CREATE POLICY "Users can create their own reactions"
    ON activity_reactions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own reactions"
    ON activity_reactions FOR DELETE
    USING (user_id = auth.uid());

-- Comments policies
CREATE POLICY "Users can view comments on visible activities"
    ON activity_comments FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM activity_feed
        WHERE activity_feed.id = activity_comments.activity_id
    ));

CREATE POLICY "Users can create their own comments"
    ON activity_comments FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own comments"
    ON activity_comments FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own comments"
    ON activity_comments FOR DELETE
    USING (user_id = auth.uid());

-- Challenges policies
CREATE POLICY "Users can view public challenges and those they participate in"
    ON challenges FOR SELECT
    USING (
        is_public = true
        OR created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM challenge_participants
            WHERE challenge_id = challenges.id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create challenges"
    ON challenges FOR INSERT
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update their own challenges"
    ON challenges FOR UPDATE
    USING (created_by = auth.uid());

-- Challenge Participants policies
CREATE POLICY "Users can view participants of visible challenges"
    ON challenge_participants FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM challenges
        WHERE challenges.id = challenge_participants.challenge_id
    ));

CREATE POLICY "Users can join challenges"
    ON challenge_participants FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own participation"
    ON challenge_participants FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can leave challenges"
    ON challenge_participants FOR DELETE
    USING (user_id = auth.uid());

-- Privacy Settings policies
CREATE POLICY "Users can view their own privacy settings"
    ON user_privacy_settings FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own privacy settings"
    ON user_privacy_settings FOR ALL
    USING (user_id = auth.uid());

-- ============================================================
-- HELPER VIEWS
-- ============================================================

-- View: Friends (mutual connections)
CREATE OR REPLACE VIEW user_friends AS
SELECT
    uc1.follower_id AS user_id,
    uc1.following_id AS friend_id,
    uc1.created_at AS friendship_date
FROM user_connections uc1
INNER JOIN user_connections uc2
    ON uc1.follower_id = uc2.following_id
    AND uc1.following_id = uc2.follower_id
WHERE uc1.connection_type = 'following'
    AND uc1.status = 'active'
    AND uc2.status = 'active';

-- View: Leaderboard (active challenges)
CREATE OR REPLACE VIEW challenge_leaderboard AS
SELECT
    cp.challenge_id,
    cp.user_id,
    cp.current_value,
    cp.progress_percentage,
    cp.status,
    c.title AS challenge_title,
    c.goal_value,
    c.goal_unit,
    RANK() OVER (PARTITION BY cp.challenge_id ORDER BY cp.current_value DESC) AS rank
FROM challenge_participants cp
JOIN challenges c ON c.id = cp.challenge_id
WHERE cp.status = 'active'
    AND c.end_date > NOW();

COMMENT ON TABLE user_connections IS 'User social connections (friends, family, following)';
COMMENT ON TABLE activity_feed IS 'User activity feed items (workouts, achievements, PRs)';
COMMENT ON TABLE activity_reactions IS 'Reactions to activity feed items';
COMMENT ON TABLE activity_comments IS 'Comments on activity feed items';
COMMENT ON TABLE challenges IS 'Fitness challenges';
COMMENT ON TABLE challenge_participants IS 'User participation in challenges';
COMMENT ON TABLE user_privacy_settings IS 'User privacy and visibility settings';
