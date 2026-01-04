-- Migration: 130_fasting_scores.sql
-- Description: Create fasting_scores table for tracking daily fasting score snapshots
-- Date: 2026-01-03

-- Fasting scores table for historical tracking
CREATE TABLE IF NOT EXISTS fasting_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Overall score (0-100)
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),

    -- Score components (each 0-100, weighted in calculation)
    completion_component REAL NOT NULL DEFAULT 0,    -- 30% weight
    streak_component REAL NOT NULL DEFAULT 0,        -- 25% weight
    duration_component REAL NOT NULL DEFAULT 0,      -- 20% weight
    weekly_component REAL NOT NULL DEFAULT 0,        -- 15% weight
    protocol_component REAL NOT NULL DEFAULT 0,      -- 10% weight

    -- Snapshot of stats at time of scoring
    current_streak INTEGER DEFAULT 0,
    fasts_this_week INTEGER DEFAULT 0,
    weekly_goal INTEGER DEFAULT 5,
    completion_rate REAL DEFAULT 0,
    avg_duration_minutes INTEGER DEFAULT 0,

    -- Timestamps
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Date column for unique constraint (derived from recorded_at)
    score_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- One score per user per day
    CONSTRAINT unique_daily_score UNIQUE (user_id, score_date)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_fasting_scores_user_id ON fasting_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_fasting_scores_recorded_at ON fasting_scores(recorded_at);
CREATE INDEX IF NOT EXISTS idx_fasting_scores_user_date ON fasting_scores(user_id, recorded_at DESC);

-- Enable RLS
ALTER TABLE fasting_scores ENABLE ROW LEVEL SECURITY;

-- RLS Policies (using subquery for performance optimization)
CREATE POLICY "Users can view own fasting scores"
    ON fasting_scores FOR SELECT
    USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can insert own fasting scores"
    ON fasting_scores FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own fasting scores"
    ON fasting_scores FOR UPDATE
    USING (user_id = (SELECT auth.uid()));

-- Function to get score trend (change from last week)
CREATE OR REPLACE FUNCTION get_fasting_score_trend(p_user_id UUID)
RETURNS TABLE (
    current_score INTEGER,
    previous_score INTEGER,
    score_change INTEGER,
    trend TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH recent_scores AS (
        SELECT
            score,
            recorded_at::DATE as score_date,
            ROW_NUMBER() OVER (ORDER BY recorded_at DESC) as rn
        FROM fasting_scores
        WHERE user_id = p_user_id
        AND recorded_at >= NOW() - INTERVAL '14 days'
    ),
    current AS (
        SELECT score FROM recent_scores WHERE rn = 1
    ),
    week_ago AS (
        SELECT score FROM recent_scores
        WHERE score_date <= (CURRENT_DATE - INTERVAL '7 days')
        ORDER BY score_date DESC
        LIMIT 1
    )
    SELECT
        COALESCE((SELECT score FROM current), 0)::INTEGER as current_score,
        COALESCE((SELECT score FROM week_ago), 0)::INTEGER as previous_score,
        (COALESCE((SELECT score FROM current), 0) - COALESCE((SELECT score FROM week_ago), 0))::INTEGER as score_change,
        CASE
            WHEN (SELECT score FROM current) > (SELECT score FROM week_ago) THEN 'up'
            WHEN (SELECT score FROM current) < (SELECT score FROM week_ago) THEN 'down'
            ELSE 'stable'
        END as trend;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_fasting_score_trend(UUID) TO authenticated;

COMMENT ON TABLE fasting_scores IS 'Daily snapshots of user fasting scores with component breakdown';
COMMENT ON COLUMN fasting_scores.score IS 'Overall fasting score 0-100';
COMMENT ON COLUMN fasting_scores.completion_component IS 'Score from completion rate (30% weight)';
COMMENT ON COLUMN fasting_scores.streak_component IS 'Score from streak consistency (25% weight)';
COMMENT ON COLUMN fasting_scores.duration_component IS 'Score from avg duration vs goal (20% weight)';
COMMENT ON COLUMN fasting_scores.weekly_component IS 'Score from weekly adherence (15% weight)';
COMMENT ON COLUMN fasting_scores.protocol_component IS 'Score from protocol difficulty (10% weight)';
