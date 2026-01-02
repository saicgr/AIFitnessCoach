-- FitWiz - Postgres Schema Migration
-- This creates all tables in Supabase Postgres

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (integrated with Supabase Auth)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR UNIQUE,
    name VARCHAR,
    onboarding_completed BOOLEAN DEFAULT FALSE,
    fitness_level VARCHAR NOT NULL,
    goals VARCHAR NOT NULL,
    equipment VARCHAR NOT NULL,
    preferences JSONB DEFAULT '{}',
    active_injuries JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Extended body measurements
    height_cm DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION,
    target_weight_kg DOUBLE PRECISION,
    age INTEGER,
    gender VARCHAR DEFAULT 'prefer_not_to_say',
    activity_level VARCHAR DEFAULT 'lightly_active',
    waist_circumference_cm DOUBLE PRECISION,
    hip_circumference_cm DOUBLE PRECISION,
    neck_circumference_cm DOUBLE PRECISION,
    body_fat_percent DOUBLE PRECISION,
    resting_heart_rate INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER
);

-- Create index on auth_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);

-- Exercises table
CREATE TABLE IF NOT EXISTS exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    category VARCHAR DEFAULT 'strength',
    subcategory VARCHAR DEFAULT 'compound',
    difficulty_level INTEGER DEFAULT 1,
    primary_muscle VARCHAR NOT NULL,
    secondary_muscles JSONB DEFAULT '[]',
    equipment_required JSONB DEFAULT '[]',
    body_part VARCHAR NOT NULL,
    equipment VARCHAR NOT NULL,
    target VARCHAR NOT NULL,
    default_sets INTEGER DEFAULT 3,
    default_reps INTEGER,
    default_duration_seconds INTEGER,
    default_rest_seconds INTEGER DEFAULT 60,
    min_weight_kg DOUBLE PRECISION,
    calories_per_minute DOUBLE PRECISION DEFAULT 5.0,
    instructions TEXT NOT NULL,
    tips JSONB DEFAULT '[]',
    contraindicated_injuries JSONB DEFAULT '[]',
    gif_url VARCHAR,
    video_url VARCHAR,
    is_compound BOOLEAN DEFAULT TRUE,
    is_unilateral BOOLEAN DEFAULT FALSE,
    tags JSONB DEFAULT '[]',
    is_custom BOOLEAN DEFAULT FALSE,
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercises_primary_muscle ON exercises(primary_muscle);
CREATE INDEX IF NOT EXISTS idx_exercises_external_id ON exercises(external_id);

-- Workouts table
CREATE TABLE IF NOT EXISTS workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    type VARCHAR NOT NULL,
    difficulty VARCHAR NOT NULL,
    scheduled_date TIMESTAMPTZ NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    exercises_json JSONB NOT NULL,
    duration_minutes INTEGER DEFAULT 45,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    generation_method VARCHAR DEFAULT 'algorithm',
    generation_source VARCHAR DEFAULT 'onboarding',
    generation_metadata JSONB DEFAULT '{}',
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    last_modified_method VARCHAR,
    last_modified_at TIMESTAMPTZ,
    modification_history JSONB DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_scheduled_date ON workouts(scheduled_date);

-- Workout logs table
CREATE TABLE IF NOT EXISTS workout_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sets_json JSONB NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    total_time_seconds INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_workout_id ON workout_logs(workout_id);

-- Performance logs table
CREATE TABLE IF NOT EXISTS performance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id VARCHAR NOT NULL,
    exercise_name VARCHAR NOT NULL,
    set_number INTEGER NOT NULL,
    reps_completed INTEGER NOT NULL,
    weight_kg DOUBLE PRECISION NOT NULL,
    rpe DOUBLE PRECISION,
    rir INTEGER,
    tempo VARCHAR,
    is_completed BOOLEAN DEFAULT TRUE,
    failed_at_rep INTEGER,
    notes TEXT,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_performance_logs_user_id ON performance_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_logs_exercise_id ON performance_logs(exercise_id);

-- Strength records table
CREATE TABLE IF NOT EXISTS strength_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id VARCHAR NOT NULL,
    exercise_name VARCHAR NOT NULL,
    weight_kg DOUBLE PRECISION NOT NULL,
    reps INTEGER NOT NULL,
    estimated_1rm DOUBLE PRECISION NOT NULL,
    rpe DOUBLE PRECISION,
    is_pr BOOLEAN DEFAULT FALSE,
    achieved_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_strength_records_user_id ON strength_records(user_id);
CREATE INDEX IF NOT EXISTS idx_strength_records_exercise_id ON strength_records(exercise_id);

-- Weekly volumes table
CREATE TABLE IF NOT EXISTS weekly_volumes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    muscle_group VARCHAR NOT NULL,
    week_number INTEGER NOT NULL,
    year INTEGER NOT NULL,
    total_sets INTEGER NOT NULL,
    total_reps INTEGER NOT NULL,
    total_volume_kg DOUBLE PRECISION NOT NULL,
    frequency INTEGER NOT NULL,
    target_sets INTEGER NOT NULL,
    recovery_status VARCHAR DEFAULT 'recovered',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, muscle_group, week_number, year)
);

CREATE INDEX IF NOT EXISTS idx_weekly_volumes_user_id ON weekly_volumes(user_id);

-- Chat history table
CREATE TABLE IF NOT EXISTS chat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    context_json JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_history_user_id ON chat_history(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_history_timestamp ON chat_history(timestamp);

-- Injuries table
CREATE TABLE IF NOT EXISTS injuries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body_part VARCHAR NOT NULL,
    severity VARCHAR NOT NULL,
    onset_date TIMESTAMPTZ NOT NULL,
    affected_exercises TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_injuries_user_id ON injuries(user_id);

-- User metrics history table
CREATE TABLE IF NOT EXISTS user_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    -- Input measurements
    weight_kg DOUBLE PRECISION,
    waist_cm DOUBLE PRECISION,
    hip_cm DOUBLE PRECISION,
    neck_cm DOUBLE PRECISION,
    body_fat_measured DOUBLE PRECISION,
    resting_heart_rate INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    -- Calculated metrics
    bmi DOUBLE PRECISION,
    bmi_category VARCHAR,
    bmr DOUBLE PRECISION,
    tdee DOUBLE PRECISION,
    body_fat_calculated DOUBLE PRECISION,
    lean_body_mass DOUBLE PRECISION,
    ffmi DOUBLE PRECISION,
    waist_to_height_ratio DOUBLE PRECISION,
    waist_to_hip_ratio DOUBLE PRECISION,
    ideal_body_weight DOUBLE PRECISION,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_user_metrics_user_id ON user_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_metrics_recorded_at ON user_metrics(recorded_at);

-- Enhanced injury history table
CREATE TABLE IF NOT EXISTS injury_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body_part VARCHAR NOT NULL,
    severity VARCHAR DEFAULT 'moderate',
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    expected_recovery_date TIMESTAMPTZ,
    actual_recovery_date TIMESTAMPTZ,
    duration_planned_weeks INTEGER DEFAULT 3,
    duration_actual_days INTEGER,
    -- Workout modifications tracking
    workouts_modified_count INTEGER DEFAULT 0,
    exercises_removed JSONB DEFAULT '[]',
    rehab_exercises_added JSONB DEFAULT '[]',
    -- Progress tracking
    pain_level_initial INTEGER,
    pain_level_current INTEGER,
    improvement_notes TEXT,
    -- Analysis fields
    ai_recommendations_followed BOOLEAN,
    user_feedback TEXT,
    recovery_phase VARCHAR DEFAULT 'acute',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_injury_history_user_id ON injury_history(user_id);

-- Workout changes audit log
CREATE TABLE IF NOT EXISTS workout_changes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    change_type VARCHAR NOT NULL,
    field_changed VARCHAR,
    old_value TEXT,
    new_value TEXT,
    change_source VARCHAR DEFAULT 'api',
    change_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_changes_workout_id ON workout_changes(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_changes_user_id ON workout_changes(user_id);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE strength_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_volumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE injuries ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE injury_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_changes ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data

-- Users table policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = auth_id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = auth_id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = auth_id);

-- Exercises table policies (read-only for all, write for custom exercises)
CREATE POLICY "Anyone can view exercises" ON exercises
    FOR SELECT USING (true);

CREATE POLICY "Users can create custom exercises" ON exercises
    FOR INSERT WITH CHECK (
        is_custom = true AND
        created_by_user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
    );

-- Workouts table policies
CREATE POLICY "Users can view own workouts" ON workouts
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can create own workouts" ON workouts
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can update own workouts" ON workouts
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can delete own workouts" ON workouts
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Similar policies for other tables (workout_logs, performance_logs, etc.)
CREATE POLICY "Users can manage own workout_logs" ON workout_logs
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own performance_logs" ON performance_logs
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own strength_records" ON strength_records
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own weekly_volumes" ON weekly_volumes
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own chat_history" ON chat_history
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own injuries" ON injuries
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own user_metrics" ON user_metrics
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own injury_history" ON injury_history
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own workout_changes" ON workout_changes
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
