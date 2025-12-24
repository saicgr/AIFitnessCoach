-- Migration: Challenge Abandonment Support
-- Created: 2025-12-24
-- Description: Add support for tracking when users quit challenges midway

-- ============================================================
-- ADD ABANDONMENT COLUMNS TO WORKOUT_CHALLENGES
-- ============================================================

-- Add abandoned_at timestamp
ALTER TABLE workout_challenges
ADD COLUMN IF NOT EXISTS abandoned_at TIMESTAMP WITH TIME ZONE;

-- Add quit_reason (shown to challenger - makes quitting embarrassing!)
ALTER TABLE workout_challenges
ADD COLUMN IF NOT EXISTS quit_reason TEXT;

-- Add partial_stats (how far they got before quitting)
ALTER TABLE workout_challenges
ADD COLUMN IF NOT EXISTS partial_stats JSONB;

-- Update status constraint to include 'abandoned'
ALTER TABLE workout_challenges
DROP CONSTRAINT IF EXISTS workout_challenges_status_check;

ALTER TABLE workout_challenges
ADD CONSTRAINT workout_challenges_status_check
CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'expired', 'abandoned'));

COMMENT ON COLUMN workout_challenges.abandoned_at IS 'When user quit the challenge midway';
COMMENT ON COLUMN workout_challenges.quit_reason IS 'Reason for quitting (shown to challenger)';
COMMENT ON COLUMN workout_challenges.partial_stats IS 'Stats achieved before quitting';

-- ============================================================
-- UPDATE TRIGGER FOR ABANDONMENT NOTIFICATIONS
-- ============================================================

-- Auto-create notification when challenge is abandoned
CREATE OR REPLACE FUNCTION notify_challenge_abandoned()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'abandoned' AND OLD.status = 'accepted' THEN
        -- Notify the challenger that their opponent quit
        INSERT INTO challenge_notifications (challenge_id, user_id, notification_type)
        VALUES (NEW.id, NEW.from_user_id, 'challenge_abandoned');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_challenge_abandoned
AFTER UPDATE ON workout_challenges
FOR EACH ROW EXECUTE FUNCTION notify_challenge_abandoned();

COMMENT ON FUNCTION notify_challenge_abandoned IS 'Notify challenger when opponent quits';

-- ============================================================
-- UPDATE STATS VIEW TO INCLUDE ABANDONED CHALLENGES
-- ============================================================

-- Drop and recreate challenge leaderboard view with abandonment stats
DROP VIEW IF EXISTS challenge_leaderboard;

CREATE OR REPLACE VIEW challenge_leaderboard AS
SELECT
    u.id AS user_id,
    u.name,
    u.avatar_url,
    COUNT(*) FILTER (WHERE c.did_beat = true) AS challenges_won,
    COUNT(*) FILTER (WHERE c.did_beat = false AND c.status = 'completed') AS challenges_lost,
    COUNT(*) FILTER (WHERE c.status = 'abandoned') AS challenges_abandoned,
    COUNT(*) FILTER (WHERE c.status = 'completed') AS total_challenges_completed,
    ROUND(
        (COUNT(*) FILTER (WHERE c.did_beat = true)::DECIMAL /
        NULLIF(COUNT(*) FILTER (WHERE c.status = 'completed'), 0) * 100),
        1
    ) AS win_rate_percentage
FROM users u
LEFT JOIN workout_challenges c ON c.to_user_id = u.id
WHERE c.status IN ('completed', 'abandoned')
GROUP BY u.id, u.name, u.avatar_url
HAVING COUNT(*) FILTER (WHERE c.status IN ('completed', 'abandoned')) > 0
ORDER BY challenges_won DESC, win_rate_percentage DESC;

COMMENT ON VIEW challenge_leaderboard IS 'Challenge statistics including wins, losses, and abandonments';

-- ============================================================
-- ABANDONMENT STATISTICS FUNCTION
-- ============================================================

-- Helper function to get abandonment stats for a user
CREATE OR REPLACE FUNCTION get_user_abandonment_stats(p_user_id UUID)
RETURNS TABLE(
    total_abandoned INT,
    most_common_quit_reason TEXT,
    abandonment_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE status = 'abandoned')::INT AS total_abandoned,
        MODE() WITHIN GROUP (ORDER BY quit_reason) AS most_common_quit_reason,
        ROUND(
            (COUNT(*) FILTER (WHERE status = 'abandoned')::DECIMAL /
            NULLIF(COUNT(*) FILTER (WHERE status IN ('accepted', 'completed', 'abandoned')), 0) * 100),
            1
        ) AS abandonment_rate
    FROM workout_challenges
    WHERE to_user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_abandonment_stats IS 'Get quit statistics for a user (for shame! 🐔)';
