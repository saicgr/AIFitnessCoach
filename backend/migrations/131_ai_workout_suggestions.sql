-- Migration: 131_ai_workout_suggestions.sql
-- Description: Create tables for AI Workout Intelligence features
-- Tracks AI suggestions for weights, rest times, fatigue, and next set predictions
-- Enables learning from user acceptance/rejection patterns
-- Date: 2026-01-04

-- ============================================
-- AI WORKOUT SUGGESTIONS TABLE
-- Tracks all AI suggestions and user responses
-- ============================================

CREATE TABLE IF NOT EXISTS ai_workout_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,
    exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL,
    exercise_name TEXT,  -- Denormalized for easier querying

    -- Suggestion details
    suggestion_type TEXT NOT NULL CHECK (suggestion_type IN ('weight', 'rest', 'fatigue', 'next_set')),
    suggested_value JSONB NOT NULL,
    -- Example suggested_value formats:
    -- weight: {"weight_kg": 60, "based_on_1rm": 80, "intensity_pct": 75, "equipment_type": "dumbbell"}
    -- rest: {"rest_seconds": 120, "base_rest": 90, "rpe_modifier": 1.33, "exercise_type": "compound"}
    -- fatigue: {"fatigue_level": 0.7, "indicators": ["rep_decline", "high_rpe"], "weight_reduction_pct": 15}
    -- next_set: {"weight_kg": 60, "target_reps": 10, "based_on": "previous_set_performance"}

    reasoning TEXT,  -- AI-generated explanation for the suggestion
    confidence REAL DEFAULT 0.5 CHECK (confidence >= 0 AND confidence <= 1),

    -- User response tracking
    user_action TEXT CHECK (user_action IN ('accepted', 'dismissed', 'modified', NULL)),
    user_modified_value JSONB,  -- If user modified, what did they change to
    action_timestamp TIMESTAMPTZ,

    -- Context at time of suggestion
    set_number INTEGER,
    current_rpe REAL,
    current_reps INTEGER,
    current_weight_kg REAL,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    source TEXT DEFAULT 'auto' CHECK (source IN ('auto', 'requested', 'chat'))
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user ON ai_workout_suggestions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_type ON ai_workout_suggestions(suggestion_type);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_workout ON ai_workout_suggestions(workout_log_id);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_exercise ON ai_workout_suggestions(exercise_id);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_action ON ai_workout_suggestions(user_action);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user_type ON ai_workout_suggestions(user_id, suggestion_type, created_at DESC);

-- Enable RLS
ALTER TABLE ai_workout_suggestions ENABLE ROW LEVEL SECURITY;

-- RLS Policies (using subquery for performance optimization)
CREATE POLICY "Users can view own suggestions"
    ON ai_workout_suggestions FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid())));

CREATE POLICY "Users can insert own suggestions"
    ON ai_workout_suggestions FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid())));

CREATE POLICY "Users can update own suggestions"
    ON ai_workout_suggestions FOR UPDATE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid())));

CREATE POLICY "Service role can manage all suggestions"
    ON ai_workout_suggestions FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- USER 1RM RECORDS TABLE
-- Stores estimated 1RM for exercises
-- ============================================

CREATE TABLE IF NOT EXISTS user_exercise_1rm (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL,
    exercise_name TEXT NOT NULL,

    -- 1RM data
    estimated_1rm_kg REAL NOT NULL,
    confidence REAL DEFAULT 0.8 CHECK (confidence >= 0 AND confidence <= 1),
    formula_used TEXT DEFAULT 'brzycki' CHECK (formula_used IN ('brzycki', 'epley', 'lombardi', 'actual', 'average')),

    -- Source data
    test_weight_kg REAL,
    test_reps INTEGER,

    -- Metadata
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    source TEXT DEFAULT 'performance' CHECK (source IN ('performance', 'manual', 'test', 'ai_estimated')),

    UNIQUE (user_id, exercise_name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_1rm_user ON user_exercise_1rm(user_id);
CREATE INDEX IF NOT EXISTS idx_user_1rm_exercise ON user_exercise_1rm(exercise_name);
CREATE INDEX IF NOT EXISTS idx_user_1rm_updated ON user_exercise_1rm(user_id, updated_at DESC);

-- Enable RLS
ALTER TABLE user_exercise_1rm ENABLE ROW LEVEL SECURITY;

-- RLS Policies (using subquery for performance optimization)
CREATE POLICY "Users can view own 1RM records"
    ON user_exercise_1rm FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid())));

CREATE POLICY "Users can manage own 1RM records"
    ON user_exercise_1rm FOR ALL
    USING (user_id IN (SELECT id FROM users WHERE auth_id = (SELECT auth.uid())));

CREATE POLICY "Service role can manage all 1RM records"
    ON user_exercise_1rm FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- ANALYTICS VIEWS
-- ============================================

-- View: Suggestion acceptance rates by type (SECURITY INVOKER for proper RLS)
CREATE OR REPLACE VIEW ai_suggestion_acceptance_rates
WITH (security_invoker = true)
AS
SELECT
    user_id,
    suggestion_type,
    COUNT(*) AS total_suggestions,
    COUNT(CASE WHEN user_action = 'accepted' THEN 1 END) AS accepted_count,
    COUNT(CASE WHEN user_action = 'dismissed' THEN 1 END) AS dismissed_count,
    COUNT(CASE WHEN user_action = 'modified' THEN 1 END) AS modified_count,
    COUNT(CASE WHEN user_action IS NULL THEN 1 END) AS no_action_count,
    ROUND(
        (COUNT(CASE WHEN user_action = 'accepted' THEN 1 END)::NUMERIC /
         NULLIF(COUNT(CASE WHEN user_action IS NOT NULL THEN 1 END), 0)) * 100,
        2
    ) AS acceptance_rate_pct,
    AVG(confidence) AS avg_confidence,
    MAX(created_at) AS last_suggestion_at
FROM ai_workout_suggestions
GROUP BY user_id, suggestion_type;

-- View: Weekly suggestion analytics (SECURITY INVOKER for proper RLS)
CREATE OR REPLACE VIEW ai_suggestion_weekly_analytics
WITH (security_invoker = true)
AS
SELECT
    date_trunc('week', created_at) AS week_start,
    suggestion_type,
    COUNT(*) AS total_suggestions,
    COUNT(CASE WHEN user_action = 'accepted' THEN 1 END) AS accepted,
    COUNT(CASE WHEN user_action = 'dismissed' THEN 1 END) AS dismissed,
    COUNT(CASE WHEN user_action = 'modified' THEN 1 END) AS modified,
    AVG(confidence) AS avg_confidence
FROM ai_workout_suggestions
GROUP BY date_trunc('week', created_at), suggestion_type
ORDER BY week_start DESC, suggestion_type;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function: Calculate suggested weight based on 1RM and target intensity
CREATE OR REPLACE FUNCTION calculate_suggested_weight(
    p_user_id UUID,
    p_exercise_name TEXT,
    p_target_intensity_pct REAL DEFAULT 75,
    p_equipment_type TEXT DEFAULT 'barbell'
)
RETURNS TABLE (
    suggested_weight_kg REAL,
    based_on_1rm REAL,
    confidence REAL,
    rounding_increment REAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_1rm REAL;
    v_confidence REAL;
    v_raw_weight REAL;
    v_rounding REAL;
BEGIN
    -- Get user's 1RM for this exercise
    SELECT estimated_1rm_kg, user_exercise_1rm.confidence
    INTO v_1rm, v_confidence
    FROM user_exercise_1rm
    WHERE user_id = p_user_id
      AND LOWER(exercise_name) = LOWER(p_exercise_name)
    ORDER BY updated_at DESC
    LIMIT 1;

    -- If no 1RM found, return NULL
    IF v_1rm IS NULL THEN
        RETURN QUERY SELECT NULL::REAL, NULL::REAL, NULL::REAL, NULL::REAL;
        RETURN;
    END IF;

    -- Calculate raw weight
    v_raw_weight := v_1rm * (p_target_intensity_pct / 100.0);

    -- Determine rounding increment based on equipment
    v_rounding := CASE
        WHEN p_equipment_type = 'dumbbell' THEN 2.5
        WHEN p_equipment_type = 'cable' OR p_equipment_type = 'machine' THEN 5.0
        WHEN p_equipment_type = 'barbell' THEN 2.5
        ELSE 2.5
    END;

    -- Return rounded result
    RETURN QUERY SELECT
        ROUND(v_raw_weight / v_rounding) * v_rounding,
        v_1rm,
        v_confidence,
        v_rounding;
END;
$$;

-- Function: Get user's acceptance rate for a suggestion type
CREATE OR REPLACE FUNCTION get_suggestion_acceptance_rate(
    p_user_id UUID,
    p_suggestion_type TEXT
)
RETURNS TABLE (
    acceptance_rate REAL,
    total_suggestions INTEGER,
    accepted INTEGER,
    dismissed INTEGER,
    modified INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(
            (COUNT(CASE WHEN user_action = 'accepted' THEN 1 END)::REAL /
             NULLIF(COUNT(CASE WHEN user_action IS NOT NULL THEN 1 END), 0)),
            0
        ) AS acceptance_rate,
        COUNT(*)::INTEGER AS total_suggestions,
        COUNT(CASE WHEN user_action = 'accepted' THEN 1 END)::INTEGER AS accepted,
        COUNT(CASE WHEN user_action = 'dismissed' THEN 1 END)::INTEGER AS dismissed,
        COUNT(CASE WHEN user_action = 'modified' THEN 1 END)::INTEGER AS modified
    FROM ai_workout_suggestions
    WHERE user_id = p_user_id
      AND suggestion_type = p_suggestion_type
      AND created_at > NOW() - INTERVAL '90 days';
END;
$$;

-- ============================================
-- TRIGGER: Update 1RM timestamp
-- ============================================

CREATE OR REPLACE FUNCTION update_1rm_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_1rm_timestamp
    BEFORE UPDATE ON user_exercise_1rm
    FOR EACH ROW
    EXECUTE FUNCTION update_1rm_timestamp();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE ai_workout_suggestions IS 'Tracks all AI-generated suggestions during workouts for learning and analytics';
COMMENT ON COLUMN ai_workout_suggestions.suggestion_type IS 'Type: weight (auto-fill), rest (rest time), fatigue (fatigue detection), next_set (preview)';
COMMENT ON COLUMN ai_workout_suggestions.suggested_value IS 'JSONB containing the suggestion details specific to the suggestion type';
COMMENT ON COLUMN ai_workout_suggestions.user_action IS 'User response: accepted (used as-is), dismissed (ignored), modified (changed then used)';
COMMENT ON COLUMN ai_workout_suggestions.user_modified_value IS 'If user modified the suggestion, stores what they changed it to';
COMMENT ON COLUMN ai_workout_suggestions.confidence IS 'AI confidence in the suggestion (0-1)';

COMMENT ON TABLE user_exercise_1rm IS 'Stores estimated 1RM values for exercises per user';
COMMENT ON COLUMN user_exercise_1rm.formula_used IS 'Formula used to calculate 1RM: brzycki, epley, lombardi, actual (1 rep test), average';
COMMENT ON COLUMN user_exercise_1rm.source IS 'How the 1RM was determined: performance (from workout), manual (user entered), test (1RM test), ai_estimated';

COMMENT ON VIEW ai_suggestion_acceptance_rates IS 'Aggregated acceptance rates by user and suggestion type';
COMMENT ON VIEW ai_suggestion_weekly_analytics IS 'Weekly analytics for AI suggestions across all users';

COMMENT ON FUNCTION calculate_suggested_weight IS 'Calculates suggested weight based on 1RM and target intensity with equipment-aware rounding';
COMMENT ON FUNCTION get_suggestion_acceptance_rate IS 'Gets acceptance rate for a specific user and suggestion type (last 90 days)';
