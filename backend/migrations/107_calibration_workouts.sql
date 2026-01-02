-- Calibration/Test Workout System Migration
-- Tracks calibration workouts used to assess and adjust user fitness levels
-- Stores strength baselines from calibration exercises

-- ============================================
-- SCHEMA DEFINITIONS
-- ============================================

-- Store calibration workout sessions
CREATE TABLE IF NOT EXISTS calibration_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_type VARCHAR(50) NOT NULL DEFAULT 'onboarding',  -- onboarding, retest
    scheduled_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    duration_minutes INTEGER,
    exercises_json JSONB NOT NULL DEFAULT '[]',
    user_reported_difficulty VARCHAR(20),  -- too_easy, just_right, too_hard
    ai_analysis JSONB,  -- Stores Gemini's analysis of performance vs expectations
    suggested_adjustments JSONB,  -- Stores suggested fitness level changes
    user_accepted_adjustments BOOLEAN,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- pending, in_progress, completed, skipped
    results_json JSONB,  -- Stores the exercise performance results
    original_fitness_level VARCHAR(50),  -- User's fitness level before calibration
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_workout_type CHECK (workout_type IN ('onboarding', 'retest')),
    CONSTRAINT valid_difficulty CHECK (user_reported_difficulty IS NULL OR user_reported_difficulty IN ('too_easy', 'just_right', 'too_hard')),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped', 'generated', 'abandoned'))
);

-- Store strength baselines from calibration exercises
CREATE TABLE IF NOT EXISTS strength_baselines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    calibration_workout_id UUID REFERENCES calibration_workouts(id) ON DELETE SET NULL,
    exercise_name VARCHAR(255) NOT NULL,
    exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL,
    muscle_group VARCHAR(100),
    baseline_weight DECIMAL(10,2),
    baseline_reps INTEGER,
    tested_weight_kg DECIMAL(10,2),
    tested_reps INTEGER,
    tested_sets INTEGER,
    perceived_difficulty VARCHAR(20),  -- too_easy, moderate, challenging, max_effort
    estimated_1rm DECIMAL(10,2),
    weight_unit VARCHAR(10) DEFAULT 'lbs',
    confidence_level DECIMAL(3,2) DEFAULT 0.8,
    source VARCHAR(50) DEFAULT 'calibration',  -- calibration, workout_history, manual
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    CONSTRAINT valid_perceived_difficulty CHECK (perceived_difficulty IS NULL OR perceived_difficulty IN ('too_easy', 'moderate', 'challenging', 'max_effort'))
);

-- ============================================
-- ALTER USERS TABLE
-- ============================================

-- Add calibration-related columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS calibration_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS calibration_workout_id UUID REFERENCES calibration_workouts(id) ON DELETE SET NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS calibration_skipped BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS original_fitness_level VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS fitness_level_adjusted_by_calibration BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_calibration_date TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_calibrated_at TIMESTAMPTZ;

-- ============================================
-- INDEXES
-- ============================================

-- Calibration workouts indexes
CREATE INDEX IF NOT EXISTS idx_calibration_workouts_user ON calibration_workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_calibration_workouts_status ON calibration_workouts(status);
CREATE INDEX IF NOT EXISTS idx_calibration_workouts_type ON calibration_workouts(workout_type);
CREATE INDEX IF NOT EXISTS idx_calibration_workouts_created ON calibration_workouts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_calibration_workouts_user_status ON calibration_workouts(user_id, status);
CREATE INDEX IF NOT EXISTS idx_calibration_workouts_user_type ON calibration_workouts(user_id, workout_type);

-- Strength baselines indexes
CREATE INDEX IF NOT EXISTS idx_strength_baselines_user ON strength_baselines(user_id);
CREATE INDEX IF NOT EXISTS idx_strength_baselines_calibration ON strength_baselines(calibration_workout_id);
CREATE INDEX IF NOT EXISTS idx_strength_baselines_exercise ON strength_baselines(exercise_id);
CREATE INDEX IF NOT EXISTS idx_strength_baselines_created ON strength_baselines(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_strength_baselines_user_exercise ON strength_baselines(user_id, exercise_name);
-- Note: The column is calibration_workout_id, not calibration_id
-- This index duplicates idx_strength_baselines_calibration, keeping for compatibility
CREATE INDEX IF NOT EXISTS idx_strength_baselines_calibration_id ON strength_baselines(calibration_workout_id);

-- Users table index for calibration lookups
CREATE INDEX IF NOT EXISTS idx_users_calibration_workout ON users(calibration_workout_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger for calibration_workouts updated_at
DROP TRIGGER IF EXISTS trigger_calibration_workouts_updated_at ON calibration_workouts;
CREATE TRIGGER trigger_calibration_workouts_updated_at
    BEFORE UPDATE ON calibration_workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE calibration_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE strength_baselines ENABLE ROW LEVEL SECURITY;

-- Calibration workouts policies
DROP POLICY IF EXISTS "Users can view own calibration workouts" ON calibration_workouts;
CREATE POLICY "Users can view own calibration workouts"
    ON calibration_workouts FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own calibration workouts" ON calibration_workouts;
CREATE POLICY "Users can insert own calibration workouts"
    ON calibration_workouts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own calibration workouts" ON calibration_workouts;
CREATE POLICY "Users can update own calibration workouts"
    ON calibration_workouts FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own calibration workouts" ON calibration_workouts;
CREATE POLICY "Users can delete own calibration workouts"
    ON calibration_workouts FOR DELETE
    USING (auth.uid() = user_id);

-- Strength baselines policies
DROP POLICY IF EXISTS "Users can view own strength baselines" ON strength_baselines;
CREATE POLICY "Users can view own strength baselines"
    ON strength_baselines FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own strength baselines" ON strength_baselines;
CREATE POLICY "Users can insert own strength baselines"
    ON strength_baselines FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own strength baselines" ON strength_baselines;
CREATE POLICY "Users can update own strength baselines"
    ON strength_baselines FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own strength baselines" ON strength_baselines;
CREATE POLICY "Users can delete own strength baselines"
    ON strength_baselines FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- VIEWS
-- ============================================

-- View for latest calibration workout per user
CREATE OR REPLACE VIEW latest_calibration_workout WITH (security_invoker = true) AS
SELECT DISTINCT ON (user_id)
    id,
    user_id,
    workout_type,
    scheduled_date,
    started_at,
    completed_at,
    duration_minutes,
    exercises_json,
    user_reported_difficulty,
    ai_analysis,
    suggested_adjustments,
    user_accepted_adjustments,
    status,
    created_at,
    updated_at
FROM calibration_workouts
ORDER BY user_id, created_at DESC;

-- View for calibration summary per user
CREATE OR REPLACE VIEW calibration_summary WITH (security_invoker = true) AS
SELECT
    user_id,
    COUNT(*) as total_calibrations,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN status = 'skipped' THEN 1 END) as skipped_count,
    MIN(created_at) as first_calibration,
    MAX(completed_at) as last_completed,
    COUNT(CASE WHEN user_accepted_adjustments = TRUE THEN 1 END) as adjustments_accepted,
    COUNT(CASE WHEN user_accepted_adjustments = FALSE THEN 1 END) as adjustments_rejected
FROM calibration_workouts
GROUP BY user_id;

-- View for user strength baselines with exercise details
CREATE OR REPLACE VIEW user_strength_baselines WITH (security_invoker = true) AS
SELECT
    sb.id,
    sb.user_id,
    sb.calibration_workout_id,
    sb.exercise_name,
    sb.exercise_id,
    sb.tested_weight_kg,
    sb.tested_reps,
    sb.tested_sets,
    sb.perceived_difficulty,
    sb.estimated_1rm,
    sb.notes,
    sb.created_at,
    cw.workout_type,
    cw.completed_at as calibration_completed_at
FROM strength_baselines sb
LEFT JOIN calibration_workouts cw ON sb.calibration_workout_id = cw.id;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to get the latest strength baseline for a user and exercise
CREATE OR REPLACE FUNCTION get_latest_strength_baseline(
    p_user_id UUID,
    p_exercise_name VARCHAR(255)
)
RETURNS TABLE (
    id UUID,
    tested_weight_kg DECIMAL(10,2),
    tested_reps INTEGER,
    tested_sets INTEGER,
    perceived_difficulty VARCHAR(20),
    estimated_1rm DECIMAL(10,2),
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        sb.id,
        sb.tested_weight_kg,
        sb.tested_reps,
        sb.tested_sets,
        sb.perceived_difficulty,
        sb.estimated_1rm,
        sb.created_at
    FROM strength_baselines sb
    WHERE sb.user_id = p_user_id
      AND sb.exercise_name = p_exercise_name
    ORDER BY sb.created_at DESC
    LIMIT 1;
END;
$$;

-- Function to check if user needs recalibration (e.g., after 90 days)
CREATE OR REPLACE FUNCTION user_needs_recalibration(
    p_user_id UUID,
    p_days_threshold INT DEFAULT 90
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_last_calibration TIMESTAMPTZ;
BEGIN
    SELECT MAX(completed_at)
    INTO v_last_calibration
    FROM calibration_workouts
    WHERE user_id = p_user_id
      AND status = 'completed';

    IF v_last_calibration IS NULL THEN
        RETURN TRUE;  -- Never calibrated
    END IF;

    RETURN v_last_calibration < NOW() - (p_days_threshold || ' days')::interval;
END;
$$;

-- Function to calculate estimated 1RM from weight and reps
CREATE OR REPLACE FUNCTION calculate_estimated_1rm(
    p_weight DECIMAL(10,2),
    p_reps INTEGER
)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- Using Brzycki formula: 1RM = weight * (36 / (37 - reps))
    IF p_reps >= 37 OR p_reps <= 0 OR p_weight <= 0 THEN
        RETURN NULL;
    END IF;

    RETURN ROUND((p_weight * (36.0 / (37.0 - p_reps)))::DECIMAL(10,2), 2);
END;
$$;

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE calibration_workouts IS 'Stores calibration/test workout sessions used to assess and adjust user fitness levels';
COMMENT ON TABLE strength_baselines IS 'Stores strength baseline measurements from calibration exercises for personalized programming';

COMMENT ON COLUMN calibration_workouts.workout_type IS 'Type of calibration: onboarding (first time) or retest (periodic reassessment)';
COMMENT ON COLUMN calibration_workouts.user_reported_difficulty IS 'User subjective feedback: too_easy, just_right, or too_hard';
COMMENT ON COLUMN calibration_workouts.ai_analysis IS 'JSON containing Gemini AI analysis of performance vs expectations';
COMMENT ON COLUMN calibration_workouts.suggested_adjustments IS 'JSON containing suggested changes to fitness level or programming';
COMMENT ON COLUMN calibration_workouts.status IS 'Workflow status: pending, in_progress, completed, or skipped';

COMMENT ON COLUMN strength_baselines.perceived_difficulty IS 'User perception: too_easy, moderate, challenging, or max_effort';
COMMENT ON COLUMN strength_baselines.estimated_1rm IS 'Calculated one-rep max based on tested weight and reps';

COMMENT ON COLUMN users.calibration_completed IS 'Whether user has completed initial calibration workout';
COMMENT ON COLUMN users.calibration_skipped IS 'Whether user chose to skip calibration';
COMMENT ON COLUMN users.original_fitness_level IS 'Fitness level from onboarding before any calibration adjustments';
COMMENT ON COLUMN users.fitness_level_adjusted_by_calibration IS 'Whether fitness level was modified based on calibration results';
COMMENT ON COLUMN users.last_calibration_date IS 'Timestamp of most recent completed calibration';

COMMENT ON VIEW latest_calibration_workout IS 'Returns the most recent calibration workout for each user';
COMMENT ON VIEW calibration_summary IS 'Aggregated calibration statistics per user';
COMMENT ON VIEW user_strength_baselines IS 'Strength baselines joined with calibration workout details';

COMMENT ON FUNCTION get_latest_strength_baseline IS 'Retrieves the most recent strength baseline for a user and exercise';
COMMENT ON FUNCTION user_needs_recalibration IS 'Checks if user should be prompted for recalibration based on time threshold';
COMMENT ON FUNCTION calculate_estimated_1rm IS 'Calculates estimated 1RM using Brzycki formula from weight and reps';
