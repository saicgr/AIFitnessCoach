-- Migration: 003_workout_tracking_tables.sql
-- Description: Create tables for comprehensive workout data persistence
-- Tables: workout_exits, drink_intake_logs, rest_intervals
-- Date: 2024-12-08

-- ============================================
-- WORKOUT EXITS TABLE
-- Tracks when users exit/complete workouts
-- ============================================

CREATE TABLE IF NOT EXISTS workout_exits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exit_reason TEXT NOT NULL,  -- "completed", "too_tired", "out_of_time", "not_feeling_well", "equipment_unavailable", "injury", "other"
    exit_notes TEXT,
    exercises_completed INTEGER DEFAULT 0,
    total_exercises INTEGER DEFAULT 0,
    sets_completed INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    progress_percentage REAL DEFAULT 0.0,
    exited_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for workout_exits
CREATE INDEX IF NOT EXISTS idx_workout_exits_user_id ON workout_exits(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_exits_workout_id ON workout_exits(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_exits_exited_at ON workout_exits(exited_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_exits_exit_reason ON workout_exits(exit_reason);

-- RLS policies for workout_exits
ALTER TABLE workout_exits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own workout exits"
    ON workout_exits FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout exits"
    ON workout_exits FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- DRINK INTAKE LOGS TABLE
-- Tracks water/drink intake during workouts
-- ============================================

CREATE TABLE IF NOT EXISTS drink_intake_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    amount_ml INTEGER NOT NULL,
    drink_type TEXT DEFAULT 'water',  -- "water", "sports_drink", "protein_shake", "bcaa", "other"
    notes TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for drink_intake_logs
CREATE INDEX IF NOT EXISTS idx_drink_intake_user_id ON drink_intake_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_drink_intake_workout_log_id ON drink_intake_logs(workout_log_id);
CREATE INDEX IF NOT EXISTS idx_drink_intake_logged_at ON drink_intake_logs(logged_at DESC);

-- RLS policies for drink_intake_logs
ALTER TABLE drink_intake_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own drink intakes"
    ON drink_intake_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own drink intakes"
    ON drink_intake_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- REST INTERVALS TABLE
-- Tracks rest periods between sets and exercises
-- ============================================

CREATE TABLE IF NOT EXISTS rest_intervals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    exercise_index INTEGER NOT NULL,
    exercise_name TEXT NOT NULL,
    set_number INTEGER,  -- NULL if rest is between exercises
    rest_duration_seconds INTEGER NOT NULL,
    prescribed_rest_seconds INTEGER,  -- What was recommended
    rest_type TEXT DEFAULT 'between_sets',  -- "between_sets", "between_exercises", "unplanned"
    notes TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for rest_intervals
CREATE INDEX IF NOT EXISTS idx_rest_intervals_user_id ON rest_intervals(user_id);
CREATE INDEX IF NOT EXISTS idx_rest_intervals_workout_log_id ON rest_intervals(workout_log_id);
CREATE INDEX IF NOT EXISTS idx_rest_intervals_logged_at ON rest_intervals(logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_rest_intervals_exercise_index ON rest_intervals(exercise_index);

-- RLS policies for rest_intervals
ALTER TABLE rest_intervals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own rest intervals"
    ON rest_intervals FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own rest intervals"
    ON rest_intervals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SERVICE ROLE POLICIES
-- Allow backend to manage all records
-- ============================================

-- Workout exits
CREATE POLICY "Service role can manage workout exits"
    ON workout_exits FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Drink intake logs
CREATE POLICY "Service role can manage drink intakes"
    ON drink_intake_logs FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Rest intervals
CREATE POLICY "Service role can manage rest intervals"
    ON rest_intervals FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE workout_exits IS 'Tracks when users exit workouts - completed, quit early, or abandoned';
COMMENT ON COLUMN workout_exits.exit_reason IS 'Reason for exiting: completed, too_tired, out_of_time, not_feeling_well, equipment_unavailable, injury, other';
COMMENT ON COLUMN workout_exits.progress_percentage IS 'Percentage of workout completed before exit (0-100)';

COMMENT ON TABLE drink_intake_logs IS 'Tracks water and drink intake during workouts';
COMMENT ON COLUMN drink_intake_logs.drink_type IS 'Type of drink: water, sports_drink, protein_shake, bcaa, other';
COMMENT ON COLUMN drink_intake_logs.amount_ml IS 'Amount consumed in milliliters';

COMMENT ON TABLE rest_intervals IS 'Tracks rest periods between sets and exercises';
COMMENT ON COLUMN rest_intervals.rest_type IS 'Type of rest: between_sets, between_exercises, unplanned';
COMMENT ON COLUMN rest_intervals.prescribed_rest_seconds IS 'The recommended rest time from the workout plan';
