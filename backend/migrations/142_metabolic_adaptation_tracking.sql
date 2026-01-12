-- Migration 142: Metabolic Adaptation Tracking
-- Adds tables for tracking metabolic adaptation events and TDEE history

-- ============================================================
-- TDEE History Table
-- ============================================================
-- Stores historical TDEE calculations for trend analysis

CREATE TABLE IF NOT EXISTS tdee_calculation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    -- Analysis period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    days_analyzed INTEGER NOT NULL,

    -- Input data counts
    food_logs_count INTEGER NOT NULL,
    weight_logs_count INTEGER NOT NULL,

    -- Weight data
    start_weight_kg DECIMAL(5,2),
    end_weight_kg DECIMAL(5,2),
    weight_change_kg DECIMAL(5,2),

    -- Calculated values
    avg_daily_intake INTEGER NOT NULL,
    calculated_tdee INTEGER NOT NULL,
    confidence_low INTEGER,
    confidence_high INTEGER,
    uncertainty_calories INTEGER,

    -- Quality metrics
    data_quality_score DECIMAL(3,2) NOT NULL,  -- 0-1

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index for user lookup and date ordering
CREATE INDEX IF NOT EXISTS idx_tdee_history_user_date
    ON tdee_calculation_history(user_id, calculated_at DESC);

-- ============================================================
-- Metabolic Adaptation Events Table
-- ============================================================
-- Tracks detected adaptation events (plateaus, metabolic slowdown)

CREATE TABLE IF NOT EXISTS metabolic_adaptation_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    -- Event classification
    event_type TEXT NOT NULL CHECK (event_type IN ('plateau', 'adaptation', 'recovery')),
    severity TEXT NOT NULL DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high')),

    -- Plateau metrics (when event_type = 'plateau')
    plateau_weeks INTEGER,
    expected_weight_change_kg DECIMAL(4,2),
    actual_weight_change_kg DECIMAL(4,2),

    -- Adaptation metrics (when event_type = 'adaptation')
    previous_tdee INTEGER,
    current_tdee INTEGER,
    tdee_drop_percent DECIMAL(5,2),
    tdee_drop_calories INTEGER,

    -- Recommendation
    suggested_action TEXT CHECK (suggested_action IN (
        'diet_break', 'refeed', 'increase_activity', 'reduce_deficit', 'patience'
    )),
    action_description TEXT,

    -- User response
    action_taken TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    user_acknowledged BOOLEAN DEFAULT false,
    acknowledged_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index for user lookup
CREATE INDEX IF NOT EXISTS idx_adaptation_events_user_date
    ON metabolic_adaptation_events(user_id, detected_at DESC);

-- Index for unacknowledged events
CREATE INDEX IF NOT EXISTS idx_adaptation_events_unacknowledged
    ON metabolic_adaptation_events(user_id, user_acknowledged)
    WHERE user_acknowledged = false;

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE tdee_calculation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE metabolic_adaptation_events ENABLE ROW LEVEL SECURITY;

-- Users can only view their own TDEE history
CREATE POLICY "Users can view own TDEE history"
    ON tdee_calculation_history FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can insert TDEE calculations
CREATE POLICY "Service can insert TDEE history"
    ON tdee_calculation_history FOR INSERT
    WITH CHECK (true);

-- Users can only view their own adaptation events
CREATE POLICY "Users can view own adaptation events"
    ON metabolic_adaptation_events FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage adaptation events
CREATE POLICY "Service can manage adaptation events"
    ON metabolic_adaptation_events FOR ALL
    USING (true)
    WITH CHECK (true);

-- ============================================================
-- Helper Function: Get latest TDEE for user
-- ============================================================

CREATE OR REPLACE FUNCTION get_latest_tdee(p_user_id UUID)
RETURNS TABLE (
    calculated_tdee INTEGER,
    uncertainty_calories INTEGER,
    data_quality_score DECIMAL,
    calculated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.calculated_tdee,
        t.uncertainty_calories,
        t.data_quality_score,
        t.calculated_at
    FROM tdee_calculation_history t
    WHERE t.user_id = p_user_id
    ORDER BY t.calculated_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Helper Function: Get TDEE trend
-- ============================================================

CREATE OR REPLACE FUNCTION get_tdee_trend(p_user_id UUID, p_weeks INTEGER DEFAULT 4)
RETURNS TABLE (
    week_number INTEGER,
    avg_tdee INTEGER,
    avg_weight_change DECIMAL,
    calculation_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH weekly_data AS (
        SELECT
            DATE_TRUNC('week', calculated_at) AS week_start,
            AVG(calculated_tdee)::INTEGER AS avg_tdee,
            AVG(weight_change_kg) AS avg_weight_change,
            COUNT(*)::INTEGER AS calculation_count
        FROM tdee_calculation_history
        WHERE user_id = p_user_id
          AND calculated_at >= NOW() - (p_weeks || ' weeks')::INTERVAL
        GROUP BY DATE_TRUNC('week', calculated_at)
        ORDER BY week_start DESC
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY week_start DESC)::INTEGER AS week_number,
        weekly_data.avg_tdee,
        weekly_data.avg_weight_change,
        weekly_data.calculation_count
    FROM weekly_data;
END;
$$ LANGUAGE plpgsql;
