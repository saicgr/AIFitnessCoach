-- Migration 143: Adherence Tracking System
-- Tracks daily adherence to nutrition targets and calculates sustainability scores

-- ============================================================
-- Daily Adherence Logs Table
-- ============================================================
-- Stores daily adherence metrics comparing actual vs target intake

CREATE TABLE IF NOT EXISTS daily_adherence_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,

    -- Targets (snapshot from that day)
    target_calories INTEGER NOT NULL,
    target_protein_g DECIMAL(6,2) NOT NULL,
    target_carbs_g DECIMAL(6,2) NOT NULL,
    target_fat_g DECIMAL(6,2) NOT NULL,

    -- Actuals
    actual_calories INTEGER NOT NULL,
    actual_protein_g DECIMAL(6,2) NOT NULL,
    actual_carbs_g DECIMAL(6,2) NOT NULL,
    actual_fat_g DECIMAL(6,2) NOT NULL,

    -- Adherence percentages (0-100)
    calorie_adherence_pct DECIMAL(5,2) NOT NULL,
    protein_adherence_pct DECIMAL(5,2) NOT NULL,
    carbs_adherence_pct DECIMAL(5,2) NOT NULL,
    fat_adherence_pct DECIMAL(5,2) NOT NULL,

    -- Overall weighted score (0-100)
    overall_adherence_pct DECIMAL(5,2) NOT NULL,

    -- Direction indicators
    calories_over BOOLEAN DEFAULT false,
    protein_over BOOLEAN DEFAULT false,

    -- Meals logged count
    meals_logged INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    -- One record per user per day
    UNIQUE(user_id, log_date)
);

-- Index for user lookup and date range queries
CREATE INDEX IF NOT EXISTS idx_adherence_user_date
    ON daily_adherence_logs(user_id, log_date DESC);

-- Note: Weekly aggregations will use the date index above
-- DATE_TRUNC cannot be used in an index expression as it's not immutable

-- ============================================================
-- Weekly Adherence Summary View
-- ============================================================
-- Pre-aggregated weekly adherence metrics

CREATE OR REPLACE VIEW weekly_adherence_summary AS
SELECT
    user_id,
    DATE_TRUNC('week', log_date)::DATE AS week_start,
    (DATE_TRUNC('week', log_date) + INTERVAL '6 days')::DATE AS week_end,
    COUNT(*)::INTEGER AS days_logged,
    7 AS days_in_week,

    -- Average adherence percentages
    AVG(calorie_adherence_pct)::DECIMAL(5,2) AS avg_calorie_adherence,
    AVG(protein_adherence_pct)::DECIMAL(5,2) AS avg_protein_adherence,
    AVG(carbs_adherence_pct)::DECIMAL(5,2) AS avg_carbs_adherence,
    AVG(fat_adherence_pct)::DECIMAL(5,2) AS avg_fat_adherence,
    AVG(overall_adherence_pct)::DECIMAL(5,2) AS avg_overall_adherence,

    -- Variance (consistency metric)
    COALESCE(VARIANCE(overall_adherence_pct), 0)::DECIMAL(8,2) AS adherence_variance,

    -- Days hitting targets (>95% adherence)
    SUM(CASE WHEN calorie_adherence_pct >= 95 THEN 1 ELSE 0 END)::INTEGER AS days_on_target_calories,
    SUM(CASE WHEN protein_adherence_pct >= 95 THEN 1 ELSE 0 END)::INTEGER AS days_on_target_protein,

    -- Direction counts
    SUM(CASE WHEN calories_over THEN 1 ELSE 0 END)::INTEGER AS days_over_calories,
    SUM(CASE WHEN protein_over THEN 1 ELSE 0 END)::INTEGER AS days_over_protein,

    -- Total meals logged
    SUM(meals_logged)::INTEGER AS total_meals_logged

FROM daily_adherence_logs
GROUP BY user_id, DATE_TRUNC('week', log_date);

-- ============================================================
-- Sustainability Scores Table
-- ============================================================
-- Stores calculated sustainability scores over time

CREATE TABLE IF NOT EXISTS sustainability_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    -- Analysis period
    weeks_analyzed INTEGER NOT NULL,

    -- Score components
    avg_adherence_pct DECIMAL(5,2) NOT NULL,
    consistency_score DECIMAL(3,2) NOT NULL,  -- 0-1
    logging_score DECIMAL(3,2) NOT NULL,  -- 0-1

    -- Overall sustainability score (0-1)
    sustainability_score DECIMAL(3,2) NOT NULL,
    rating TEXT NOT NULL CHECK (rating IN ('high', 'medium', 'low')),

    -- Recommendation
    recommendation TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index for user lookup
CREATE INDEX IF NOT EXISTS idx_sustainability_user_date
    ON sustainability_scores(user_id, calculated_at DESC);

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE daily_adherence_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sustainability_scores ENABLE ROW LEVEL SECURITY;

-- Users can view and manage their own adherence logs
CREATE POLICY "Users can manage own adherence logs"
    ON daily_adherence_logs FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Service role can manage adherence logs
CREATE POLICY "Service can manage adherence logs"
    ON daily_adherence_logs FOR ALL
    USING (true)
    WITH CHECK (true);

-- Users can view their own sustainability scores
CREATE POLICY "Users can view own sustainability scores"
    ON sustainability_scores FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can insert sustainability scores
CREATE POLICY "Service can insert sustainability scores"
    ON sustainability_scores FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- Trigger: Update timestamp on adherence log update
-- ============================================================

CREATE OR REPLACE FUNCTION update_adherence_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER adherence_log_updated
    BEFORE UPDATE ON daily_adherence_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_adherence_timestamp();

-- ============================================================
-- Helper Function: Get latest sustainability score
-- ============================================================

CREATE OR REPLACE FUNCTION get_latest_sustainability(p_user_id UUID)
RETURNS TABLE (
    sustainability_score DECIMAL,
    rating TEXT,
    avg_adherence_pct DECIMAL,
    recommendation TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.sustainability_score,
        s.rating,
        s.avg_adherence_pct,
        s.recommendation,
        s.calculated_at
    FROM sustainability_scores s
    WHERE s.user_id = p_user_id
    ORDER BY s.calculated_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Helper Function: Upsert daily adherence
-- ============================================================

CREATE OR REPLACE FUNCTION upsert_daily_adherence(
    p_user_id UUID,
    p_log_date DATE,
    p_target_calories INTEGER,
    p_target_protein_g DECIMAL,
    p_target_carbs_g DECIMAL,
    p_target_fat_g DECIMAL,
    p_actual_calories INTEGER,
    p_actual_protein_g DECIMAL,
    p_actual_carbs_g DECIMAL,
    p_actual_fat_g DECIMAL,
    p_calorie_adherence_pct DECIMAL,
    p_protein_adherence_pct DECIMAL,
    p_carbs_adherence_pct DECIMAL,
    p_fat_adherence_pct DECIMAL,
    p_overall_adherence_pct DECIMAL,
    p_calories_over BOOLEAN,
    p_protein_over BOOLEAN,
    p_meals_logged INTEGER
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO daily_adherence_logs (
        user_id, log_date,
        target_calories, target_protein_g, target_carbs_g, target_fat_g,
        actual_calories, actual_protein_g, actual_carbs_g, actual_fat_g,
        calorie_adherence_pct, protein_adherence_pct, carbs_adherence_pct, fat_adherence_pct,
        overall_adherence_pct, calories_over, protein_over, meals_logged
    ) VALUES (
        p_user_id, p_log_date,
        p_target_calories, p_target_protein_g, p_target_carbs_g, p_target_fat_g,
        p_actual_calories, p_actual_protein_g, p_actual_carbs_g, p_actual_fat_g,
        p_calorie_adherence_pct, p_protein_adherence_pct, p_carbs_adherence_pct, p_fat_adherence_pct,
        p_overall_adherence_pct, p_calories_over, p_protein_over, p_meals_logged
    )
    ON CONFLICT (user_id, log_date) DO UPDATE SET
        target_calories = EXCLUDED.target_calories,
        target_protein_g = EXCLUDED.target_protein_g,
        target_carbs_g = EXCLUDED.target_carbs_g,
        target_fat_g = EXCLUDED.target_fat_g,
        actual_calories = EXCLUDED.actual_calories,
        actual_protein_g = EXCLUDED.actual_protein_g,
        actual_carbs_g = EXCLUDED.actual_carbs_g,
        actual_fat_g = EXCLUDED.actual_fat_g,
        calorie_adherence_pct = EXCLUDED.calorie_adherence_pct,
        protein_adherence_pct = EXCLUDED.protein_adherence_pct,
        carbs_adherence_pct = EXCLUDED.carbs_adherence_pct,
        fat_adherence_pct = EXCLUDED.fat_adherence_pct,
        overall_adherence_pct = EXCLUDED.overall_adherence_pct,
        calories_over = EXCLUDED.calories_over,
        protein_over = EXCLUDED.protein_over,
        meals_logged = EXCLUDED.meals_logged,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
