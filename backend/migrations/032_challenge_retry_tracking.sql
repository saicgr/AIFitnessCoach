-- Migration: Challenge Retry Tracking
-- Created: 2025-12-24
-- Description: Add retry tracking to workout challenges

-- ============================================================
-- ADD RETRY COLUMNS TO WORKOUT_CHALLENGES
-- ============================================================

-- Add is_retry flag
ALTER TABLE workout_challenges
ADD COLUMN IF NOT EXISTS is_retry BOOLEAN DEFAULT false;

-- Add reference to original challenge (for retry chains)
ALTER TABLE workout_challenges
ADD COLUMN IF NOT EXISTS retried_from_challenge_id UUID REFERENCES workout_challenges(id) ON DELETE SET NULL;

-- Add retry count tracking (how many times has this challenge been retried?)
ALTER TABLE workout_challenges
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0;

-- Add index for finding retry chains
CREATE INDEX IF NOT EXISTS idx_workout_challenges_retry_from ON workout_challenges(retried_from_challenge_id);
CREATE INDEX IF NOT EXISTS idx_workout_challenges_is_retry ON workout_challenges(is_retry);

COMMENT ON COLUMN workout_challenges.is_retry IS 'Whether this challenge is a retry of a previous challenge';
COMMENT ON COLUMN workout_challenges.retried_from_challenge_id IS 'Reference to the original challenge this is retrying';
COMMENT ON COLUMN workout_challenges.retry_count IS 'Number of times this challenge has been retried';

-- ============================================================
-- TRIGGER TO INCREMENT RETRY COUNT
-- ============================================================

-- When a new retry is created, increment the original challenge's retry_count
CREATE OR REPLACE FUNCTION increment_retry_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_retry = true AND NEW.retried_from_challenge_id IS NOT NULL THEN
        -- Increment retry count on the original challenge
        UPDATE workout_challenges
        SET retry_count = retry_count + 1
        WHERE id = NEW.retried_from_challenge_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_retry_count
AFTER INSERT ON workout_challenges
FOR EACH ROW EXECUTE FUNCTION increment_retry_count();

COMMENT ON FUNCTION increment_retry_count IS 'Increment retry count when a challenge is retried';

-- ============================================================
-- UPDATE CHALLENGE LEADERBOARD VIEW WITH RETRY STATS
-- ============================================================

-- Drop and recreate with retry stats
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
    COUNT(*) FILTER (WHERE c.is_retry = true) AS total_retries,
    COUNT(*) FILTER (WHERE c.is_retry = true AND c.did_beat = true) AS retries_won,
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

COMMENT ON VIEW challenge_leaderboard IS 'Challenge statistics including wins, losses, abandonments, and retries';

-- ============================================================
-- RETRY STATISTICS FUNCTION
-- ============================================================

-- Helper function to get retry stats for a user
CREATE OR REPLACE FUNCTION get_user_retry_stats(p_user_id UUID)
RETURNS TABLE(
    total_retries INT,
    retries_won INT,
    retry_win_rate DECIMAL,
    most_retried_workout TEXT,
    avg_retries_to_win DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE is_retry = true)::INT AS total_retries,
        COUNT(*) FILTER (WHERE is_retry = true AND did_beat = true)::INT AS retries_won,
        ROUND(
            (COUNT(*) FILTER (WHERE is_retry = true AND did_beat = true)::DECIMAL /
            NULLIF(COUNT(*) FILTER (WHERE is_retry = true AND status = 'completed'), 0) * 100),
            1
        ) AS retry_win_rate,
        MODE() WITHIN GROUP (ORDER BY workout_name) FILTER (WHERE is_retry = true) AS most_retried_workout,
        ROUND(
            AVG(retry_count) FILTER (WHERE did_beat = true),
            1
        ) AS avg_retries_to_win
    FROM workout_challenges
    WHERE to_user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_retry_stats IS 'Get retry statistics for a user (persistence pays off!)';

-- ============================================================
-- VIEW: RETRY CHAINS
-- ============================================================

-- View to see chains of retries for a challenge
CREATE OR REPLACE VIEW challenge_retry_chains AS
WITH RECURSIVE retry_chain AS (
    -- Base case: original challenges (not retries)
    SELECT
        id,
        from_user_id,
        to_user_id,
        workout_name,
        status,
        did_beat,
        is_retry,
        retried_from_challenge_id,
        created_at,
        0 AS retry_depth,
        ARRAY[id] AS chain_path
    FROM workout_challenges
    WHERE is_retry = false

    UNION ALL

    -- Recursive case: follow retry chains
    SELECT
        c.id,
        c.from_user_id,
        c.to_user_id,
        c.workout_name,
        c.status,
        c.did_beat,
        c.is_retry,
        c.retried_from_challenge_id,
        c.created_at,
        rc.retry_depth + 1,
        rc.chain_path || c.id
    FROM workout_challenges c
    INNER JOIN retry_chain rc ON c.retried_from_challenge_id = rc.id
)
SELECT
    id AS challenge_id,
    from_user_id,
    to_user_id,
    workout_name,
    status,
    did_beat,
    retry_depth,
    array_length(chain_path, 1) AS total_attempts,
    chain_path
FROM retry_chain
ORDER BY chain_path, retry_depth;

COMMENT ON VIEW challenge_retry_chains IS 'Visualize retry chains and persistence for challenges';
