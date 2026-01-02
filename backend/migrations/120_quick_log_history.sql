-- Migration: 120_quick_log_history.sql
-- Description: Track quick log frequency for smart food suggestions based on user patterns
-- Created: 2024-12-31

-- ============================================================================
-- QUICK LOG HISTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS quick_log_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Food identification
    food_name TEXT NOT NULL,
    meal_type TEXT NOT NULL,  -- breakfast, lunch, dinner, snack

    -- Nutrition data (cached for quick display)
    calories INTEGER,
    protein NUMERIC(6,1),
    carbs NUMERIC(6,1),
    fat NUMERIC(6,1),
    fiber NUMERIC(6,1),
    sodium NUMERIC(8,1),

    -- Serving information
    serving_size NUMERIC(8,2),
    serving_unit TEXT,

    -- Usage tracking
    log_count INTEGER DEFAULT 1,

    -- Time pattern tracking for smart suggestions
    time_of_day_bucket TEXT,  -- morning (5-11), afternoon (11-17), evening (17-21), night (21-5)

    -- Day of week pattern (optional, for weekly patterns)
    common_days TEXT[] DEFAULT '{}',  -- ['monday', 'wednesday', 'friday']

    -- Source tracking
    source TEXT DEFAULT 'manual',  -- manual, barcode, search, template, voice

    -- Timestamps
    last_logged_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Primary lookup: user + meal type (for suggestions)
CREATE INDEX IF NOT EXISTS idx_quick_log_user_meal
    ON quick_log_history(user_id, meal_type);

-- Sort by frequency for "most logged" suggestions
CREATE INDEX IF NOT EXISTS idx_quick_log_frequency
    ON quick_log_history(user_id, log_count DESC);

-- Time-based suggestions (what do they eat at this time?)
CREATE INDEX IF NOT EXISTS idx_quick_log_time_bucket
    ON quick_log_history(user_id, time_of_day_bucket);

-- Recent items first
CREATE INDEX IF NOT EXISTS idx_quick_log_recent
    ON quick_log_history(user_id, last_logged_at DESC);

-- Unique constraint to aggregate by user/food/meal (prevents duplicates)
CREATE UNIQUE INDEX IF NOT EXISTS idx_quick_log_unique
    ON quick_log_history(user_id, food_name, meal_type);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE quick_log_history ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own quick log history
CREATE POLICY "Users can view own quick log history"
    ON quick_log_history FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own quick log history
CREATE POLICY "Users can insert own quick log history"
    ON quick_log_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own quick log history
CREATE POLICY "Users can update own quick log history"
    ON quick_log_history FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can delete their own quick log history
CREATE POLICY "Users can delete own quick log history"
    ON quick_log_history FOR DELETE
    USING (auth.uid() = user_id);

-- Policy: Service role has full access (for backend operations)
CREATE POLICY "Service role has full access to quick log history"
    ON quick_log_history FOR ALL
    TO service_role
    USING (true) WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS: SMART LOGGING
-- ============================================================================

-- Function to determine time of day bucket
CREATE OR REPLACE FUNCTION get_time_of_day_bucket(p_timestamp TIMESTAMPTZ DEFAULT NOW())
RETURNS TEXT
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    hour_of_day INTEGER;
BEGIN
    hour_of_day := EXTRACT(HOUR FROM p_timestamp);

    IF hour_of_day >= 5 AND hour_of_day < 11 THEN
        RETURN 'morning';
    ELSIF hour_of_day >= 11 AND hour_of_day < 17 THEN
        RETURN 'afternoon';
    ELSIF hour_of_day >= 17 AND hour_of_day < 21 THEN
        RETURN 'evening';
    ELSE
        RETURN 'night';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to record or increment quick log entry
CREATE OR REPLACE FUNCTION record_quick_log(
    p_user_id UUID,
    p_food_name TEXT,
    p_meal_type TEXT,
    p_calories INTEGER DEFAULT NULL,
    p_protein NUMERIC DEFAULT NULL,
    p_carbs NUMERIC DEFAULT NULL,
    p_fat NUMERIC DEFAULT NULL,
    p_fiber NUMERIC DEFAULT NULL,
    p_sodium NUMERIC DEFAULT NULL,
    p_serving_size NUMERIC DEFAULT NULL,
    p_serving_unit TEXT DEFAULT NULL,
    p_source TEXT DEFAULT 'manual'
)
RETURNS quick_log_history
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result quick_log_history;
    v_time_bucket TEXT;
    v_day_name TEXT;
BEGIN
    -- Get current time bucket and day
    v_time_bucket := get_time_of_day_bucket(NOW());
    v_day_name := lower(to_char(NOW(), 'day'));
    v_day_name := trim(v_day_name);

    INSERT INTO quick_log_history (
        user_id,
        food_name,
        meal_type,
        calories,
        protein,
        carbs,
        fat,
        fiber,
        sodium,
        serving_size,
        serving_unit,
        log_count,
        time_of_day_bucket,
        common_days,
        source,
        last_logged_at
    )
    VALUES (
        p_user_id,
        p_food_name,
        p_meal_type,
        p_calories,
        p_protein,
        p_carbs,
        p_fat,
        p_fiber,
        p_sodium,
        p_serving_size,
        p_serving_unit,
        1,
        v_time_bucket,
        ARRAY[v_day_name],
        p_source,
        NOW()
    )
    ON CONFLICT (user_id, food_name, meal_type) DO UPDATE SET
        log_count = quick_log_history.log_count + 1,
        last_logged_at = NOW(),
        -- Update nutrition if provided (in case of corrections)
        calories = COALESCE(p_calories, quick_log_history.calories),
        protein = COALESCE(p_protein, quick_log_history.protein),
        carbs = COALESCE(p_carbs, quick_log_history.carbs),
        fat = COALESCE(p_fat, quick_log_history.fat),
        fiber = COALESCE(p_fiber, quick_log_history.fiber),
        sodium = COALESCE(p_sodium, quick_log_history.sodium),
        -- Update time bucket to most recent
        time_of_day_bucket = v_time_bucket,
        -- Add day to common_days if not already present
        common_days = CASE
            WHEN v_day_name = ANY(quick_log_history.common_days) THEN quick_log_history.common_days
            ELSE array_append(quick_log_history.common_days, v_day_name)
        END
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get smart suggestions based on time and patterns
CREATE OR REPLACE FUNCTION get_quick_log_suggestions(
    p_user_id UUID,
    p_meal_type TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    food_name TEXT,
    meal_type TEXT,
    calories INTEGER,
    protein NUMERIC,
    carbs NUMERIC,
    fat NUMERIC,
    log_count INTEGER,
    last_logged_at TIMESTAMPTZ,
    relevance_score NUMERIC
)
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_time_bucket TEXT;
    v_day_name TEXT;
BEGIN
    v_time_bucket := get_time_of_day_bucket(NOW());
    v_day_name := trim(lower(to_char(NOW(), 'day')));

    RETURN QUERY
    SELECT
        qlh.food_name,
        qlh.meal_type,
        qlh.calories,
        qlh.protein,
        qlh.carbs,
        qlh.fat,
        qlh.log_count,
        qlh.last_logged_at,
        -- Calculate relevance score based on multiple factors
        (
            -- Frequency weight (log_count normalized, max 40 points)
            LEAST(qlh.log_count::NUMERIC / 10, 4) * 10 +
            -- Time match weight (20 points if time bucket matches)
            CASE WHEN qlh.time_of_day_bucket = v_time_bucket THEN 20 ELSE 0 END +
            -- Day match weight (15 points if logged on this day before)
            CASE WHEN v_day_name = ANY(qlh.common_days) THEN 15 ELSE 0 END +
            -- Recency weight (up to 25 points, decays over 7 days)
            GREATEST(0, 25 - EXTRACT(DAY FROM NOW() - qlh.last_logged_at)::NUMERIC * 3.5)
        )::NUMERIC AS relevance_score
    FROM quick_log_history qlh
    WHERE qlh.user_id = p_user_id
      AND (p_meal_type IS NULL OR qlh.meal_type = p_meal_type)
    ORDER BY relevance_score DESC, qlh.log_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_time_of_day_bucket TO authenticated;
GRANT EXECUTE ON FUNCTION record_quick_log TO authenticated;
GRANT EXECUTE ON FUNCTION get_quick_log_suggestions TO authenticated;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Top foods by meal type
CREATE OR REPLACE VIEW quick_log_top_foods AS
SELECT
    qlh.user_id,
    qlh.meal_type,
    qlh.food_name,
    qlh.calories,
    qlh.protein,
    qlh.carbs,
    qlh.fat,
    qlh.log_count,
    qlh.last_logged_at,
    qlh.time_of_day_bucket,
    ROW_NUMBER() OVER (
        PARTITION BY qlh.user_id, qlh.meal_type
        ORDER BY qlh.log_count DESC
    ) AS rank_in_meal_type
FROM quick_log_history qlh
ORDER BY qlh.user_id, qlh.meal_type, qlh.log_count DESC;

-- Grant select on view
GRANT SELECT ON quick_log_top_foods TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE quick_log_history IS 'Tracks user food logging patterns for smart suggestions. Aggregates by user/food/meal to track frequency.';
COMMENT ON COLUMN quick_log_history.log_count IS 'Number of times this food has been logged for this meal type by the user';
COMMENT ON COLUMN quick_log_history.time_of_day_bucket IS 'Time category: morning (5-11), afternoon (11-17), evening (17-21), night (21-5)';
COMMENT ON COLUMN quick_log_history.common_days IS 'Array of weekdays when this food is commonly logged';
COMMENT ON FUNCTION get_quick_log_suggestions IS 'Returns smart food suggestions based on frequency, time of day, and day of week patterns';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
