-- Migration 082: Cardio Metrics and Heart Rate Zones
-- Store user's cardio metrics, VO2 max estimates, and fitness age calculations
-- Supports the heart rate zone training feature

-- ===================================
-- Table: cardio_metrics
-- ===================================
-- Stores measured and calculated cardio fitness data
CREATE TABLE IF NOT EXISTS cardio_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Heart rate data
    max_hr INT CHECK (max_hr IS NULL OR (max_hr >= 100 AND max_hr <= 220)),
    resting_hr INT CHECK (resting_hr IS NULL OR (resting_hr >= 30 AND resting_hr <= 100)),

    -- VO2 max and fitness age (calculated or measured)
    vo2_max_estimate DECIMAL(5,2) CHECK (vo2_max_estimate IS NULL OR (vo2_max_estimate >= 10 AND vo2_max_estimate <= 100)),
    fitness_age INT CHECK (fitness_age IS NULL OR (fitness_age >= 18 AND fitness_age <= 90)),

    -- Metadata
    measured_at TIMESTAMPTZ DEFAULT NOW(),
    source VARCHAR(50) DEFAULT 'calculated' CHECK (source IN ('calculated', 'measured', 'health_kit', 'fitness_test', 'manual')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_cardio_metrics_user ON cardio_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_cardio_metrics_date ON cardio_metrics(measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_cardio_metrics_user_date ON cardio_metrics(user_id, measured_at DESC);

-- ===================================
-- Trigger: Auto-update updated_at
-- ===================================
CREATE OR REPLACE FUNCTION update_cardio_metrics_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cardio_metrics_updated_at ON cardio_metrics;
CREATE TRIGGER trigger_cardio_metrics_updated_at
    BEFORE UPDATE ON cardio_metrics
    FOR EACH ROW
    EXECUTE FUNCTION update_cardio_metrics_updated_at();

-- ===================================
-- Row Level Security (RLS)
-- ===================================
ALTER TABLE cardio_metrics ENABLE ROW LEVEL SECURITY;

-- Users can view their own cardio metrics
DROP POLICY IF EXISTS "Users can view own cardio metrics" ON cardio_metrics;
CREATE POLICY "Users can view own cardio metrics"
    ON cardio_metrics FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own cardio metrics
DROP POLICY IF EXISTS "Users can insert own cardio metrics" ON cardio_metrics;
CREATE POLICY "Users can insert own cardio metrics"
    ON cardio_metrics FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own cardio metrics
DROP POLICY IF EXISTS "Users can update own cardio metrics" ON cardio_metrics;
CREATE POLICY "Users can update own cardio metrics"
    ON cardio_metrics FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own cardio metrics
DROP POLICY IF EXISTS "Users can delete own cardio metrics" ON cardio_metrics;
CREATE POLICY "Users can delete own cardio metrics"
    ON cardio_metrics FOR DELETE
    USING (auth.uid() = user_id);

-- ===================================
-- View: Latest cardio metrics per user
-- ===================================
-- Useful for quick lookups of current cardio fitness status
CREATE OR REPLACE VIEW latest_cardio_metrics AS
SELECT DISTINCT ON (user_id)
    id,
    user_id,
    max_hr,
    resting_hr,
    vo2_max_estimate,
    fitness_age,
    source,
    measured_at,
    created_at,
    updated_at
FROM cardio_metrics
ORDER BY user_id, measured_at DESC;

-- Grant access to authenticated users
GRANT SELECT ON latest_cardio_metrics TO authenticated;

-- ===================================
-- Comments for documentation
-- ===================================
COMMENT ON TABLE cardio_metrics IS 'Stores user cardio fitness metrics including heart rate data, VO2 max estimates, and fitness age';
COMMENT ON COLUMN cardio_metrics.max_hr IS 'Maximum heart rate in BPM - can be calculated (Tanaka formula) or measured';
COMMENT ON COLUMN cardio_metrics.resting_hr IS 'Resting heart rate in BPM - typically measured in the morning';
COMMENT ON COLUMN cardio_metrics.vo2_max_estimate IS 'Estimated or measured VO2 max in ml/kg/min. Average: 30-40 sedentary, 40-50 active, 50-60 athletic';
COMMENT ON COLUMN cardio_metrics.fitness_age IS 'Calculated fitness age based on VO2 max - represents cardiovascular health relative to age';
COMMENT ON COLUMN cardio_metrics.source IS 'Data source: calculated (from formulas), measured (from tests), health_kit (from Apple/Google Health), manual (user entered)';
COMMENT ON VIEW latest_cardio_metrics IS 'Most recent cardio metrics for each user - useful for dashboard displays';
