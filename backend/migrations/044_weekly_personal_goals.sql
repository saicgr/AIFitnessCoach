-- Migration: 044_weekly_personal_goals.sql
-- Description: Personal weekly challenges with single_max and weekly_volume goals
-- Author: AI Fitness Coach
-- Date: 2025-12-26

-- ============================================================
-- WEEKLY PERSONAL GOALS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS weekly_personal_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Goal definition
    exercise_name VARCHAR(255) NOT NULL,
    goal_type VARCHAR(20) NOT NULL,  -- 'single_max' or 'weekly_volume'
    target_value INT NOT NULL,

    -- Week boundaries (ISO week: Monday to Sunday)
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,

    -- Progress tracking
    current_value INT DEFAULT 0,
    personal_best INT,  -- Previous PR for this exercise/goal_type
    is_pr_beaten BOOLEAN DEFAULT false,

    -- Status
    status VARCHAR(20) DEFAULT 'active',  -- 'active', 'completed', 'abandoned'
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- One active goal per exercise per week per user per type
    UNIQUE(user_id, exercise_name, goal_type, week_start),

    CHECK (goal_type IN ('single_max', 'weekly_volume')),
    CHECK (week_end > week_start),
    CHECK (target_value > 0),
    CHECK (status IN ('active', 'completed', 'abandoned'))
);

CREATE INDEX IF NOT EXISTS idx_weekly_goals_user ON weekly_personal_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_goals_week ON weekly_personal_goals(week_start, week_end);
CREATE INDEX IF NOT EXISTS idx_weekly_goals_exercise ON weekly_personal_goals(exercise_name);
CREATE INDEX IF NOT EXISTS idx_weekly_goals_status ON weekly_personal_goals(status);
CREATE INDEX IF NOT EXISTS idx_weekly_goals_user_week ON weekly_personal_goals(user_id, week_start);

-- ============================================================
-- GOAL ATTEMPTS TABLE (for single_max attempts)
-- ============================================================

CREATE TABLE IF NOT EXISTS goal_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES weekly_personal_goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Attempt details
    attempt_value INT NOT NULL,
    attempt_notes TEXT,

    -- Link to workout if done during workout
    workout_log_id UUID,

    -- Metadata
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CHECK (attempt_value > 0)
);

CREATE INDEX IF NOT EXISTS idx_goal_attempts_goal ON goal_attempts(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_attempts_user ON goal_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_attempts_date ON goal_attempts(attempted_at DESC);

-- ============================================================
-- PERSONAL GOAL RECORDS (All-time PRs per exercise/goal_type)
-- ============================================================

CREATE TABLE IF NOT EXISTS personal_goal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    goal_type VARCHAR(20) NOT NULL,

    -- Record details
    record_value INT NOT NULL,
    previous_value INT,

    -- When/where achieved
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    goal_id UUID REFERENCES weekly_personal_goals(id) ON DELETE SET NULL,

    -- One record per exercise/type per user
    UNIQUE(user_id, exercise_name, goal_type),

    CHECK (goal_type IN ('single_max', 'weekly_volume')),
    CHECK (record_value > 0)
);

CREATE INDEX IF NOT EXISTS idx_goal_records_user ON personal_goal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_records_exercise ON personal_goal_records(exercise_name);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE weekly_personal_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE goal_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_goal_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view their own goals" ON weekly_personal_goals;
DROP POLICY IF EXISTS "Users can create their own goals" ON weekly_personal_goals;
DROP POLICY IF EXISTS "Users can update their own goals" ON weekly_personal_goals;
DROP POLICY IF EXISTS "Users can delete their own goals" ON weekly_personal_goals;
DROP POLICY IF EXISTS "Users can manage their own attempts" ON goal_attempts;
DROP POLICY IF EXISTS "Users can manage their own records" ON personal_goal_records;

-- Weekly goals policies
CREATE POLICY "Users can view their own goals"
    ON weekly_personal_goals FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own goals"
    ON weekly_personal_goals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals"
    ON weekly_personal_goals FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals"
    ON weekly_personal_goals FOR DELETE
    USING (auth.uid() = user_id);

-- Attempts policies
CREATE POLICY "Users can manage their own attempts"
    ON goal_attempts FOR ALL
    USING (auth.uid() = user_id);

-- Records policies
CREATE POLICY "Users can manage their own records"
    ON personal_goal_records FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================
-- HELPER FUNCTION: Get ISO week boundaries
-- ============================================================

CREATE OR REPLACE FUNCTION get_iso_week_boundaries(for_date DATE)
RETURNS TABLE(week_start DATE, week_end DATE) AS $$
BEGIN
    -- ISO week: Monday = 1, Sunday = 7
    -- Get Monday of the week
    week_start := for_date - (EXTRACT(ISODOW FROM for_date) - 1)::INT;
    week_end := week_start + 6;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- TRIGGER: Auto-update personal_goal_records on goal completion
-- ============================================================

CREATE OR REPLACE FUNCTION update_goal_records()
RETURNS TRIGGER AS $$
DECLARE
    existing_record personal_goal_records%ROWTYPE;
BEGIN
    -- Only trigger when goal is completed and beat PR
    IF NEW.status = 'completed' AND NEW.is_pr_beaten = true THEN
        -- Check for existing record
        SELECT * INTO existing_record
        FROM personal_goal_records
        WHERE user_id = NEW.user_id
          AND exercise_name = NEW.exercise_name
          AND goal_type = NEW.goal_type;

        IF FOUND THEN
            -- Update existing record
            UPDATE personal_goal_records
            SET record_value = NEW.current_value,
                previous_value = existing_record.record_value,
                achieved_at = NOW(),
                goal_id = NEW.id
            WHERE id = existing_record.id;
        ELSE
            -- Insert new record
            INSERT INTO personal_goal_records (user_id, exercise_name, goal_type, record_value, goal_id)
            VALUES (NEW.user_id, NEW.exercise_name, NEW.goal_type, NEW.current_value, NEW.id);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists (for idempotency)
DROP TRIGGER IF EXISTS trigger_update_goal_records ON weekly_personal_goals;

CREATE TRIGGER trigger_update_goal_records
AFTER UPDATE ON weekly_personal_goals
FOR EACH ROW EXECUTE FUNCTION update_goal_records();

-- ============================================================
-- TRIGGER: Auto-update updated_at timestamp
-- ============================================================

CREATE OR REPLACE FUNCTION update_weekly_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_weekly_goals_updated_at ON weekly_personal_goals;

CREATE TRIGGER trigger_weekly_goals_updated_at
BEFORE UPDATE ON weekly_personal_goals
FOR EACH ROW EXECUTE FUNCTION update_weekly_goals_updated_at();

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE weekly_personal_goals IS 'Personal weekly fitness goals (single_max or weekly_volume)';
COMMENT ON TABLE goal_attempts IS 'Individual attempts for single_max goals';
COMMENT ON TABLE personal_goal_records IS 'All-time personal records per exercise/goal_type';
COMMENT ON COLUMN weekly_personal_goals.goal_type IS 'single_max: max reps in one set, weekly_volume: total reps over week';
COMMENT ON COLUMN weekly_personal_goals.is_pr_beaten IS 'Whether user beat their previous personal record this week';
