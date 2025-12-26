-- Migration: 045_goal_suggestions.sql
-- Description: Add AI goal suggestions, shared goals, and goal invites for enhanced weekly goals
-- Date: 2025-12-26

-- ============================================================================
-- Table: goal_suggestions - Cache AI-generated goal suggestions
-- ============================================================================
CREATE TABLE IF NOT EXISTS goal_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    suggestion_type VARCHAR(50) NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    goal_type VARCHAR(50) NOT NULL,
    suggested_target INT NOT NULL CHECK (suggested_target > 0),
    reasoning TEXT NOT NULL,
    confidence_score FLOAT DEFAULT 0.8 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    source_data JSONB DEFAULT '{}',
    category VARCHAR(100) NOT NULL,
    priority_rank INT DEFAULT 0,
    is_dismissed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT valid_suggestion_type CHECK (
        suggestion_type IN ('performance_based', 'schedule_based', 'popular_with_friends', 'new_challenge')
    ),
    CONSTRAINT valid_goal_type CHECK (
        goal_type IN ('single_max', 'weekly_volume')
    ),
    CONSTRAINT valid_category CHECK (
        category IN ('beat_your_records', 'popular_with_friends', 'new_challenges')
    )
);

CREATE INDEX IF NOT EXISTS idx_goal_suggestions_user ON goal_suggestions(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_suggestions_user_category ON goal_suggestions(user_id, category);
CREATE INDEX IF NOT EXISTS idx_goal_suggestions_expires ON goal_suggestions(expires_at);
CREATE INDEX IF NOT EXISTS idx_goal_suggestions_not_dismissed ON goal_suggestions(user_id, is_dismissed) WHERE is_dismissed = FALSE;

-- ============================================================================
-- Table: shared_goals - Goals shared between friends
-- ============================================================================
CREATE TABLE IF NOT EXISTS shared_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_goal_id UUID NOT NULL REFERENCES weekly_personal_goals(id) ON DELETE CASCADE,
    source_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_goal_id UUID REFERENCES weekly_personal_goals(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'active',
    joined_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT no_self_share CHECK (source_user_id != joined_user_id),
    CONSTRAINT valid_shared_status CHECK (status IN ('active', 'completed', 'abandoned')),
    CONSTRAINT unique_shared_goal UNIQUE(original_goal_id, joined_user_id)
);

CREATE INDEX IF NOT EXISTS idx_shared_goals_original ON shared_goals(original_goal_id);
CREATE INDEX IF NOT EXISTS idx_shared_goals_source_user ON shared_goals(source_user_id);
CREATE INDEX IF NOT EXISTS idx_shared_goals_joined_user ON shared_goals(joined_user_id);
CREATE INDEX IF NOT EXISTS idx_shared_goals_status ON shared_goals(status);

-- ============================================================================
-- Table: goal_invites - Invitations to join goals
-- ============================================================================
CREATE TABLE IF NOT EXISTS goal_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES weekly_personal_goals(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),

    CONSTRAINT no_self_invite CHECK (inviter_id != invitee_id),
    CONSTRAINT valid_invite_status CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    CONSTRAINT unique_goal_invite UNIQUE(goal_id, invitee_id)
);

CREATE INDEX IF NOT EXISTS idx_goal_invites_invitee ON goal_invites(invitee_id, status);
CREATE INDEX IF NOT EXISTS idx_goal_invites_inviter ON goal_invites(inviter_id);
CREATE INDEX IF NOT EXISTS idx_goal_invites_goal ON goal_invites(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_invites_pending ON goal_invites(invitee_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_goal_invites_expires ON goal_invites(expires_at) WHERE status = 'pending';

-- ============================================================================
-- Table: goal_friends_cache - Cached friends-on-goal data for performance
-- ============================================================================
CREATE TABLE IF NOT EXISTS goal_friends_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    goal_type VARCHAR(50) NOT NULL,
    week_start DATE NOT NULL,
    friend_count INT DEFAULT 0,
    friend_previews JSONB DEFAULT '[]',
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_goal_friends_cache UNIQUE(user_id, exercise_name, goal_type, week_start)
);

CREATE INDEX IF NOT EXISTS idx_goal_friends_cache_user ON goal_friends_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_friends_cache_week ON goal_friends_cache(week_start);

-- ============================================================================
-- Modifications to weekly_personal_goals table
-- ============================================================================
DO $$
BEGIN
    -- Add is_shared column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'weekly_personal_goals' AND column_name = 'is_shared'
    ) THEN
        ALTER TABLE weekly_personal_goals ADD COLUMN is_shared BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add source_suggestion_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'weekly_personal_goals' AND column_name = 'source_suggestion_id'
    ) THEN
        ALTER TABLE weekly_personal_goals ADD COLUMN source_suggestion_id UUID REFERENCES goal_suggestions(id) ON DELETE SET NULL;
    END IF;

    -- Add visibility column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'weekly_personal_goals' AND column_name = 'visibility'
    ) THEN
        ALTER TABLE weekly_personal_goals ADD COLUMN visibility VARCHAR(50) DEFAULT 'friends';
        ALTER TABLE weekly_personal_goals ADD CONSTRAINT valid_visibility CHECK (
            visibility IN ('private', 'friends', 'public')
        );
    END IF;
END $$;

-- ============================================================================
-- Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE goal_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_friends_cache ENABLE ROW LEVEL SECURITY;

-- Goal suggestions: Users can only see their own suggestions
DROP POLICY IF EXISTS goal_suggestions_select_policy ON goal_suggestions;
CREATE POLICY goal_suggestions_select_policy ON goal_suggestions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS goal_suggestions_insert_policy ON goal_suggestions;
CREATE POLICY goal_suggestions_insert_policy ON goal_suggestions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS goal_suggestions_update_policy ON goal_suggestions;
CREATE POLICY goal_suggestions_update_policy ON goal_suggestions
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS goal_suggestions_delete_policy ON goal_suggestions;
CREATE POLICY goal_suggestions_delete_policy ON goal_suggestions
    FOR DELETE USING (auth.uid() = user_id);

-- Shared goals: Users can see shared goals they are part of
DROP POLICY IF EXISTS shared_goals_select_policy ON shared_goals;
CREATE POLICY shared_goals_select_policy ON shared_goals
    FOR SELECT USING (
        auth.uid() = source_user_id OR
        auth.uid() = joined_user_id
    );

DROP POLICY IF EXISTS shared_goals_insert_policy ON shared_goals;
CREATE POLICY shared_goals_insert_policy ON shared_goals
    FOR INSERT WITH CHECK (auth.uid() = joined_user_id);

DROP POLICY IF EXISTS shared_goals_update_policy ON shared_goals;
CREATE POLICY shared_goals_update_policy ON shared_goals
    FOR UPDATE USING (
        auth.uid() = source_user_id OR
        auth.uid() = joined_user_id
    );

-- Goal invites: Users can see invites they sent or received
DROP POLICY IF EXISTS goal_invites_select_policy ON goal_invites;
CREATE POLICY goal_invites_select_policy ON goal_invites
    FOR SELECT USING (
        auth.uid() = inviter_id OR
        auth.uid() = invitee_id
    );

DROP POLICY IF EXISTS goal_invites_insert_policy ON goal_invites;
CREATE POLICY goal_invites_insert_policy ON goal_invites
    FOR INSERT WITH CHECK (auth.uid() = inviter_id);

DROP POLICY IF EXISTS goal_invites_update_policy ON goal_invites;
CREATE POLICY goal_invites_update_policy ON goal_invites
    FOR UPDATE USING (
        auth.uid() = inviter_id OR
        auth.uid() = invitee_id
    );

DROP POLICY IF EXISTS goal_invites_delete_policy ON goal_invites;
CREATE POLICY goal_invites_delete_policy ON goal_invites
    FOR DELETE USING (auth.uid() = inviter_id);

-- Goal friends cache: Users can only see their own cache
DROP POLICY IF EXISTS goal_friends_cache_select_policy ON goal_friends_cache;
CREATE POLICY goal_friends_cache_select_policy ON goal_friends_cache
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS goal_friends_cache_insert_policy ON goal_friends_cache;
CREATE POLICY goal_friends_cache_insert_policy ON goal_friends_cache
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS goal_friends_cache_update_policy ON goal_friends_cache;
CREATE POLICY goal_friends_cache_update_policy ON goal_friends_cache
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS goal_friends_cache_delete_policy ON goal_friends_cache;
CREATE POLICY goal_friends_cache_delete_policy ON goal_friends_cache
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Function to get friends doing the same goal
CREATE OR REPLACE FUNCTION get_friends_on_goal(
    p_user_id UUID,
    p_exercise_name VARCHAR(255),
    p_goal_type VARCHAR(50),
    p_week_start DATE
)
RETURNS TABLE (
    friend_id UUID,
    friend_name VARCHAR(255),
    friend_avatar_url TEXT,
    current_value INT,
    target_value INT,
    progress_percentage FLOAT,
    is_pr_beaten BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id as friend_id,
        u.display_name as friend_name,
        u.photo_url as friend_avatar_url,
        wpg.current_value,
        wpg.target_value,
        CASE
            WHEN wpg.target_value > 0 THEN (wpg.current_value::FLOAT / wpg.target_value::FLOAT) * 100
            ELSE 0
        END as progress_percentage,
        wpg.is_pr_beaten
    FROM weekly_personal_goals wpg
    JOIN users u ON u.id = wpg.user_id
    JOIN user_connections uc ON (
        (uc.follower_id = p_user_id AND uc.following_id = wpg.user_id) OR
        (uc.following_id = p_user_id AND uc.follower_id = wpg.user_id)
    )
    WHERE wpg.exercise_name = p_exercise_name
      AND wpg.goal_type = p_goal_type
      AND wpg.week_start = p_week_start
      AND wpg.user_id != p_user_id
      AND wpg.status = 'active'
      AND wpg.visibility IN ('friends', 'public')
      AND uc.status = 'active'
    ORDER BY progress_percentage DESC, wpg.current_value DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to expire old invites
CREATE OR REPLACE FUNCTION expire_old_goal_invites()
RETURNS void AS $$
BEGIN
    UPDATE goal_invites
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old suggestions
CREATE OR REPLACE FUNCTION cleanup_expired_suggestions()
RETURNS void AS $$
BEGIN
    DELETE FROM goal_suggestions
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Trigger: Update goal_friends_cache when goals change
-- ============================================================================
CREATE OR REPLACE FUNCTION update_goal_friends_cache()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark cache as stale by deleting entries for affected users
    -- The cache will be rebuilt on next access
    DELETE FROM goal_friends_cache
    WHERE exercise_name = COALESCE(NEW.exercise_name, OLD.exercise_name)
      AND goal_type = COALESCE(NEW.goal_type, OLD.goal_type)
      AND week_start = COALESCE(NEW.week_start, OLD.week_start);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_goal_friends_cache ON weekly_personal_goals;
CREATE TRIGGER trigger_update_goal_friends_cache
    AFTER INSERT OR UPDATE OR DELETE ON weekly_personal_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_goal_friends_cache();

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON TABLE goal_suggestions IS 'AI-generated goal suggestions cached per user with expiration';
COMMENT ON TABLE shared_goals IS 'Tracks goals shared between friends (join functionality)';
COMMENT ON TABLE goal_invites IS 'Goal invitation system for inviting friends to join goals';
COMMENT ON TABLE goal_friends_cache IS 'Performance cache for friends-on-goal data';

COMMENT ON COLUMN goal_suggestions.suggestion_type IS 'Type: performance_based, schedule_based, popular_with_friends, new_challenge';
COMMENT ON COLUMN goal_suggestions.category IS 'Display category: beat_your_records, popular_with_friends, new_challenges';
COMMENT ON COLUMN goal_suggestions.confidence_score IS 'AI confidence in suggestion relevance (0-1)';
COMMENT ON COLUMN goal_suggestions.source_data IS 'JSON data used to generate suggestion (workout history, etc)';

COMMENT ON COLUMN shared_goals.original_goal_id IS 'The goal that was shared/joined';
COMMENT ON COLUMN shared_goals.joined_goal_id IS 'The new goal created for the user who joined';

COMMENT ON COLUMN goal_invites.expires_at IS 'Invite expires after 7 days if not responded';

COMMENT ON COLUMN weekly_personal_goals.is_shared IS 'Whether this goal was shared with others';
COMMENT ON COLUMN weekly_personal_goals.source_suggestion_id IS 'If created from suggestion, links to the suggestion';
COMMENT ON COLUMN weekly_personal_goals.visibility IS 'Who can see this goal: private, friends, public';
