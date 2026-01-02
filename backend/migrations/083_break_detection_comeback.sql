-- Migration 083: Break Detection and Comeback Workout System
-- Automatically provides reduced intensity workouts when users return after extended breaks
-- Supports age-aware adjustments for seniors returning from breaks

-- ============================================================
-- ADD COMEBACK MODE FIELDS TO USERS TABLE
-- ============================================================
-- Track comeback mode status directly on the users table for efficiency

DO $$
BEGIN
    -- Add days_since_last_workout (cached, updated periodically)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'days_since_last_workout'
    ) THEN
        ALTER TABLE users ADD COLUMN days_since_last_workout INTEGER DEFAULT 0;
    END IF;

    -- Add comeback mode flag
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'in_comeback_mode'
    ) THEN
        ALTER TABLE users ADD COLUMN in_comeback_mode BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add comeback started timestamp
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'comeback_started_at'
    ) THEN
        ALTER TABLE users ADD COLUMN comeback_started_at TIMESTAMPTZ;
    END IF;

    -- Add comeback week counter (for gradual ramp-up)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'comeback_week'
    ) THEN
        ALTER TABLE users ADD COLUMN comeback_week INTEGER DEFAULT 0;
    END IF;

    -- Add last_workout_date for tracking
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'last_workout_date'
    ) THEN
        ALTER TABLE users ADD COLUMN last_workout_date TIMESTAMPTZ;
    END IF;
END $$;

-- ============================================================
-- CREATE COMEBACK HISTORY TABLE
-- ============================================================
-- Track all comeback periods for analytics and personalization

CREATE TABLE IF NOT EXISTS comeback_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Break details
    break_start_date TIMESTAMPTZ NOT NULL,
    break_end_date TIMESTAMPTZ NOT NULL,
    days_off INTEGER NOT NULL,
    break_type TEXT NOT NULL CHECK (break_type IN ('short_break', 'medium_break', 'long_break', 'extended_break')),
    -- Comeback details
    comeback_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    comeback_completed_at TIMESTAMPTZ,
    target_comeback_weeks INTEGER NOT NULL,
    actual_comeback_weeks INTEGER,
    -- Adjustments applied
    initial_volume_reduction DOUBLE PRECISION NOT NULL,
    initial_intensity_reduction DOUBLE PRECISION NOT NULL,
    -- User context at start
    user_age_at_comeback INTEGER,
    user_fitness_level TEXT,
    -- Success metrics
    workouts_completed_during_comeback INTEGER DEFAULT 0,
    successfully_completed BOOLEAN DEFAULT FALSE,
    user_feedback TEXT,
    -- Tracking
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_comeback_history_user_id
ON comeback_history(user_id);

CREATE INDEX IF NOT EXISTS idx_comeback_history_dates
ON comeback_history(comeback_started_at DESC);

-- Enable Row Level Security
ALTER TABLE comeback_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY comeback_history_select_policy ON comeback_history
    FOR SELECT USING (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY comeback_history_insert_policy ON comeback_history
    FOR INSERT WITH CHECK (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY comeback_history_update_policy ON comeback_history
    FOR UPDATE USING (auth.uid() IN (SELECT auth_id FROM users WHERE id = user_id));

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON comeback_history TO authenticated;

-- ============================================================
-- CREATE USER ACTIVITY STATUS VIEW
-- ============================================================
-- Quick view to check user activity status

CREATE OR REPLACE VIEW v_user_activity_status AS
SELECT
    u.id as user_id,
    u.last_workout_date,
    u.days_since_last_workout,
    u.in_comeback_mode,
    u.comeback_week,
    u.comeback_started_at,
    u.age,
    u.fitness_level,
    -- Calculate current break status
    CASE
        WHEN u.days_since_last_workout >= 42 THEN 'extended_break'
        WHEN u.days_since_last_workout >= 28 THEN 'long_break'
        WHEN u.days_since_last_workout >= 14 THEN 'medium_break'
        WHEN u.days_since_last_workout >= 7 THEN 'short_break'
        ELSE 'active'
    END as break_status,
    -- Calculate recommended volume reduction
    CASE
        WHEN u.days_since_last_workout >= 42 THEN 0.50  -- 50% reduction
        WHEN u.days_since_last_workout >= 28 THEN 0.40  -- 40% reduction
        WHEN u.days_since_last_workout >= 14 THEN 0.25  -- 25% reduction
        WHEN u.days_since_last_workout >= 7 THEN 0.10   -- 10% reduction
        ELSE 0.0
    END as base_volume_reduction,
    -- Age adjustment factor (additional reduction for seniors)
    CASE
        WHEN u.age >= 70 THEN 0.15  -- Additional 15% reduction
        WHEN u.age >= 60 THEN 0.10  -- Additional 10% reduction
        WHEN u.age >= 50 THEN 0.05  -- Additional 5% reduction
        ELSE 0.0
    END as age_adjustment
FROM users u;

-- ============================================================
-- FUNCTION: Get Days Since Last Completed Workout
-- ============================================================

CREATE OR REPLACE FUNCTION get_days_since_last_workout(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_last_workout_date TIMESTAMPTZ;
    v_days_since INTEGER;
BEGIN
    -- Get the most recent completed workout date
    SELECT MAX(scheduled_date) INTO v_last_workout_date
    FROM workouts
    WHERE user_id = p_user_id
    AND is_completed = TRUE;

    IF v_last_workout_date IS NULL THEN
        -- No completed workouts, return a large number
        RETURN 999;
    END IF;

    v_days_since := EXTRACT(DAY FROM (CURRENT_TIMESTAMP - v_last_workout_date));

    -- Update the cached value on the user
    UPDATE users
    SET
        days_since_last_workout = v_days_since,
        last_workout_date = v_last_workout_date
    WHERE id = p_user_id;

    RETURN v_days_since;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FUNCTION: Start Comeback Mode
-- ============================================================

CREATE OR REPLACE FUNCTION start_comeback_mode(
    p_user_id UUID,
    p_days_off INTEGER,
    p_break_type TEXT,
    p_target_weeks INTEGER,
    p_volume_reduction DOUBLE PRECISION,
    p_intensity_reduction DOUBLE PRECISION
)
RETURNS UUID AS $$
DECLARE
    v_history_id UUID;
    v_user_age INTEGER;
    v_fitness_level TEXT;
    v_last_workout_date TIMESTAMPTZ;
BEGIN
    -- Get user info
    SELECT age, fitness_level, last_workout_date
    INTO v_user_age, v_fitness_level, v_last_workout_date
    FROM users
    WHERE id = p_user_id;

    -- Update user to comeback mode
    UPDATE users
    SET
        in_comeback_mode = TRUE,
        comeback_started_at = NOW(),
        comeback_week = 1
    WHERE id = p_user_id;

    -- Create comeback history record
    INSERT INTO comeback_history (
        user_id,
        break_start_date,
        break_end_date,
        days_off,
        break_type,
        comeback_started_at,
        target_comeback_weeks,
        initial_volume_reduction,
        initial_intensity_reduction,
        user_age_at_comeback,
        user_fitness_level
    ) VALUES (
        p_user_id,
        COALESCE(v_last_workout_date, NOW() - (p_days_off || ' days')::INTERVAL),
        NOW(),
        p_days_off,
        p_break_type,
        NOW(),
        p_target_weeks,
        p_volume_reduction,
        p_intensity_reduction,
        v_user_age,
        v_fitness_level
    )
    RETURNING id INTO v_history_id;

    RETURN v_history_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FUNCTION: Progress Comeback Week
-- ============================================================

CREATE OR REPLACE FUNCTION progress_comeback_week(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_new_week INTEGER;
    v_target_weeks INTEGER;
BEGIN
    -- Get current comeback info
    SELECT u.comeback_week, ch.target_comeback_weeks
    INTO v_new_week, v_target_weeks
    FROM users u
    LEFT JOIN comeback_history ch ON ch.user_id = u.id
        AND ch.comeback_completed_at IS NULL
    WHERE u.id = p_user_id;

    v_new_week := COALESCE(v_new_week, 0) + 1;

    -- Update user
    UPDATE users
    SET comeback_week = v_new_week
    WHERE id = p_user_id;

    -- Check if comeback is complete
    IF v_target_weeks IS NOT NULL AND v_new_week >= v_target_weeks THEN
        -- Mark comeback as complete
        UPDATE users
        SET
            in_comeback_mode = FALSE,
            comeback_week = 0,
            comeback_started_at = NULL
        WHERE id = p_user_id;

        -- Update history
        UPDATE comeback_history
        SET
            comeback_completed_at = NOW(),
            actual_comeback_weeks = v_new_week,
            successfully_completed = TRUE
        WHERE user_id = p_user_id
        AND comeback_completed_at IS NULL;
    END IF;

    RETURN v_new_week;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FUNCTION: End Comeback Mode
-- ============================================================

CREATE OR REPLACE FUNCTION end_comeback_mode(p_user_id UUID, p_successful BOOLEAN DEFAULT TRUE)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update user
    UPDATE users
    SET
        in_comeback_mode = FALSE,
        comeback_week = 0,
        comeback_started_at = NULL
    WHERE id = p_user_id;

    -- Update history
    UPDATE comeback_history
    SET
        comeback_completed_at = NOW(),
        successfully_completed = p_successful
    WHERE user_id = p_user_id
    AND comeback_completed_at IS NULL;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- TRIGGER: Update Workout Count During Comeback
-- ============================================================

CREATE OR REPLACE FUNCTION update_comeback_workout_count()
RETURNS TRIGGER AS $$
BEGIN
    -- If user is in comeback mode and completed a workout, update count
    IF NEW.is_completed = TRUE AND OLD.is_completed = FALSE THEN
        UPDATE comeback_history
        SET workouts_completed_during_comeback = workouts_completed_during_comeback + 1
        WHERE user_id = NEW.user_id
        AND comeback_completed_at IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_comeback_workout_count ON workouts;
CREATE TRIGGER trigger_update_comeback_workout_count
    AFTER UPDATE ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_comeback_workout_count();

-- ============================================================
-- TRIGGER: Update Last Workout Date
-- ============================================================

CREATE OR REPLACE FUNCTION update_last_workout_date()
RETURNS TRIGGER AS $$
BEGIN
    -- When a workout is completed, update the user's last workout date
    IF NEW.is_completed = TRUE THEN
        UPDATE users
        SET
            last_workout_date = NEW.scheduled_date,
            days_since_last_workout = 0
        WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_last_workout_date ON workouts;
CREATE TRIGGER trigger_update_last_workout_date
    AFTER UPDATE ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_last_workout_date();

-- ============================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE comeback_history IS 'Tracks all comeback periods after extended breaks for analytics';
COMMENT ON COLUMN comeback_history.break_type IS 'short_break (7-13d), medium_break (14-27d), long_break (28-41d), extended_break (42+d)';
COMMENT ON COLUMN comeback_history.initial_volume_reduction IS 'Percentage volume reduction applied (0.0-1.0)';
COMMENT ON COLUMN comeback_history.initial_intensity_reduction IS 'Percentage intensity reduction applied (0.0-1.0)';
COMMENT ON COLUMN users.in_comeback_mode IS 'Whether user is currently in a comeback/return-to-training phase';
COMMENT ON COLUMN users.comeback_week IS 'Current week of comeback program (1-4 typically)';

COMMENT ON VIEW v_user_activity_status IS 'View for quick user activity and break status lookup';
