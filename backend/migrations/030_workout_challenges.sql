-- Migration: Workout Challenges (Direct Friend-to-Friend)
-- Created: 2025-12-24
-- Description: Challenge specific friends to beat your workout

-- ============================================================
-- WORKOUT CHALLENGES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS workout_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who is challenging whom
    from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- What workout (reference to the completed workout)
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,
    activity_id UUID REFERENCES activity_feed(id) ON DELETE SET NULL,

    -- Challenge details (denormalized for persistence)
    workout_name VARCHAR(200) NOT NULL,
    workout_data JSONB NOT NULL DEFAULT '{}', -- Stats to beat: duration, volume, exercises

    -- Challenge message
    challenge_message TEXT, -- Optional personal message: "Think you can beat my PR? 💪"

    -- Status
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'completed', 'expired'

    -- Response tracking
    accepted_at TIMESTAMP WITH TIME ZONE,
    declined_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Performance comparison (filled when completed)
    challenger_stats JSONB, -- Original workout stats
    challenged_stats JSONB, -- Their attempt stats
    did_beat BOOLEAN, -- Did they beat the challenge?

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),

    -- Prevent duplicate active challenges
    CHECK (from_user_id != to_user_id)
);

CREATE INDEX idx_workout_challenges_from ON workout_challenges(from_user_id);
CREATE INDEX idx_workout_challenges_to ON workout_challenges(to_user_id);
CREATE INDEX idx_workout_challenges_status ON workout_challenges(status);
CREATE INDEX idx_workout_challenges_created ON workout_challenges(created_at DESC);
CREATE INDEX idx_workout_challenges_expires ON workout_challenges(expires_at);

COMMENT ON TABLE workout_challenges IS 'Direct friend-to-friend workout challenges';

-- ============================================================
-- CHALLENGE NOTIFICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS challenge_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES workout_challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Notification type
    notification_type VARCHAR(50) NOT NULL, -- 'challenge_received', 'challenge_accepted', 'challenge_completed', 'challenge_beaten'

    -- Status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_challenge_notifications_user ON challenge_notifications(user_id);
CREATE INDEX idx_challenge_notifications_unread ON challenge_notifications(user_id, is_read) WHERE is_read = false;

COMMENT ON TABLE challenge_notifications IS 'Notifications for challenge events';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE workout_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_notifications ENABLE ROW LEVEL SECURITY;

-- Users can view challenges they sent or received
CREATE POLICY "Users can view their challenges"
    ON workout_challenges FOR SELECT
    USING (from_user_id = auth.uid() OR to_user_id = auth.uid());

-- Users can create challenges
CREATE POLICY "Users can create challenges"
    ON workout_challenges FOR INSERT
    WITH CHECK (from_user_id = auth.uid());

-- Users can update challenges they received (accept/decline)
CREATE POLICY "Users can update received challenges"
    ON workout_challenges FOR UPDATE
    USING (to_user_id = auth.uid());

-- Users can delete challenges they sent (if still pending)
CREATE POLICY "Users can delete sent pending challenges"
    ON workout_challenges FOR DELETE
    USING (from_user_id = auth.uid() AND status = 'pending');

-- Notifications policies
CREATE POLICY "Users can view their notifications"
    ON challenge_notifications FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their notifications"
    ON challenge_notifications FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-create notification when challenge is created
CREATE OR REPLACE FUNCTION create_challenge_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
    VALUES (NEW.id, NEW.to_user_id, 'challenge_received');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_challenge_notification
AFTER INSERT ON workout_challenges
FOR EACH ROW EXECUTE FUNCTION create_challenge_notification();

-- Auto-create notification when challenge is accepted
CREATE OR REPLACE FUNCTION notify_challenge_accepted()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.from_user_id, 'challenge_accepted');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_challenge_accepted
AFTER UPDATE ON workout_challenges
FOR EACH ROW EXECUTE FUNCTION notify_challenge_accepted();

-- Auto-expire old challenges
CREATE OR REPLACE FUNCTION expire_old_challenges()
RETURNS void AS $$
BEGIN
    UPDATE workout_challenges
    SET status = 'expired'
    WHERE status = 'pending'
        AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Optional: Create a scheduled job to run this periodically
-- COMMENT: In production, set up pg_cron or similar to run expire_old_challenges() daily

-- ============================================================
-- HELPER VIEWS
-- ============================================================

-- View: Pending challenges with user info
CREATE OR REPLACE VIEW pending_challenges_with_users AS
SELECT
    c.*,
    from_user.name AS from_user_name,
    from_user.avatar_url AS from_user_avatar,
    to_user.name AS to_user_name,
    to_user.avatar_url AS to_user_avatar
FROM workout_challenges c
JOIN users from_user ON from_user.id = c.from_user_id
JOIN users to_user ON to_user.id = c.to_user_id
WHERE c.status = 'pending'
    AND c.expires_at > NOW();

-- View: Challenge leaderboard (most challenges won)
CREATE OR REPLACE VIEW challenge_leaderboard AS
SELECT
    u.id AS user_id,
    u.name,
    u.avatar_url,
    COUNT(*) FILTER (WHERE c.did_beat = true) AS challenges_won,
    COUNT(*) FILTER (WHERE c.did_beat = false) AS challenges_lost,
    COUNT(*) AS total_challenges_completed
FROM users u
LEFT JOIN workout_challenges c ON c.to_user_id = u.id
WHERE c.status = 'completed'
GROUP BY u.id, u.name, u.avatar_url
ORDER BY challenges_won DESC;

COMMENT ON VIEW pending_challenges_with_users IS 'Active challenges with user details';
COMMENT ON VIEW challenge_leaderboard IS 'Challenge win/loss statistics per user';
