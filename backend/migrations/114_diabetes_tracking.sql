-- Migration: 114_diabetes_tracking.sql
-- Type 1 Diabetic Tracking with Health Connect Integration
-- Created: 2024-12-31
-- Purpose: Comprehensive diabetes management for fitness app users
--
-- This migration adds support for:
-- 1. Glucose monitoring (manual + CGM + Health Connect sync)
-- 2. Insulin dose tracking (injections, pumps, pens)
-- 3. HbA1c test result history
-- 4. Non-insulin diabetes medications
-- 5. Carbohydrate tracking for insulin dosing calculations
-- 6. Custom glucose alerts
-- 7. Pre-computed daily summaries for analytics

-- ============================================
-- ENUM TYPES
-- ============================================

DO $$ BEGIN
    CREATE TYPE diabetes_type AS ENUM ('type_1', 'type_2', 'gestational', 'prediabetes');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE cgm_device_type AS ENUM ('dexcom', 'freestyle_libre', 'medtronic', 'eversense', 'other');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE glucose_reading_type AS ENUM ('manual', 'cgm', 'health_connect');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE glucose_meal_context AS ENUM (
        'fasting', 'before_breakfast', 'after_breakfast', 'before_lunch',
        'after_lunch', 'before_dinner', 'after_dinner', 'bedtime', 'night', 'unknown'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE insulin_type AS ENUM (
        'rapid_acting', 'short_acting', 'intermediate', 'long_acting',
        'mixed', 'pump_bolus', 'pump_basal'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE insulin_delivery_method AS ENUM ('injection', 'pump', 'pen', 'inhaled');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE diabetes_medication_type AS ENUM (
        'metformin', 'sglt2_inhibitor', 'dpp4_inhibitor', 'glp1_agonist',
        'sulfonylurea', 'thiazolidinedione', 'other'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE glucose_alert_type AS ENUM ('low', 'high', 'rapid_drop', 'rapid_rise', 'time_in_range');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE carb_meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- TABLE: diabetes_profiles
-- ============================================
CREATE TABLE IF NOT EXISTS diabetes_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    diabetes_type diabetes_type NOT NULL DEFAULT 'type_1',
    diagnosis_date DATE,
    uses_insulin_pump BOOLEAN NOT NULL DEFAULT FALSE,
    uses_cgm BOOLEAN NOT NULL DEFAULT FALSE,
    cgm_device cgm_device_type,
    target_glucose_low INTEGER NOT NULL DEFAULT 70,
    target_glucose_high INTEGER NOT NULL DEFAULT 180,
    target_glucose_fasting INTEGER NOT NULL DEFAULT 100,
    target_a1c DECIMAL(4,2),
    insulin_carb_ratio DECIMAL(4,2),
    correction_factor INTEGER,
    health_connect_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    last_health_connect_sync TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_diabetes_profile_user UNIQUE (user_id),
    CONSTRAINT valid_glucose_range CHECK (target_glucose_low < target_glucose_high),
    CONSTRAINT valid_a1c CHECK (target_a1c IS NULL OR target_a1c BETWEEN 4.0 AND 14.0)
);

CREATE INDEX IF NOT EXISTS idx_diabetes_profiles_user ON diabetes_profiles(user_id);

-- ============================================
-- TABLE: glucose_readings
-- ============================================
CREATE TABLE IF NOT EXISTS glucose_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    value_mg_dl INTEGER NOT NULL,
    reading_type glucose_reading_type NOT NULL DEFAULT 'manual',
    meal_context glucose_meal_context NOT NULL DEFAULT 'unknown',
    notes TEXT,
    source_device TEXT,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_from_health_connect BOOLEAN NOT NULL DEFAULT FALSE,
    health_connect_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_glucose_value CHECK (value_mg_dl BETWEEN 20 AND 600)
);

CREATE INDEX IF NOT EXISTS idx_glucose_readings_user ON glucose_readings(user_id);
CREATE INDEX IF NOT EXISTS idx_glucose_readings_user_recorded ON glucose_readings(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_glucose_readings_meal_context ON glucose_readings(user_id, meal_context);

-- ============================================
-- TABLE: insulin_doses
-- ============================================
CREATE TABLE IF NOT EXISTS insulin_doses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    insulin_type insulin_type NOT NULL,
    insulin_name TEXT,
    units DECIMAL(6,2) NOT NULL,
    delivery_method insulin_delivery_method NOT NULL DEFAULT 'injection',
    injection_site TEXT,
    meal_related BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_from_health_connect BOOLEAN NOT NULL DEFAULT FALSE,
    health_connect_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_insulin_units CHECK (units > 0 AND units <= 200)
);

CREATE INDEX IF NOT EXISTS idx_insulin_doses_user ON insulin_doses(user_id);
CREATE INDEX IF NOT EXISTS idx_insulin_doses_user_recorded ON insulin_doses(user_id, recorded_at DESC);

-- ============================================
-- TABLE: a1c_records
-- ============================================
CREATE TABLE IF NOT EXISTS a1c_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    value DECIMAL(4,2) NOT NULL,
    test_date DATE NOT NULL,
    lab_name TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_a1c_value CHECK (value BETWEEN 4.0 AND 14.0)
);

CREATE INDEX IF NOT EXISTS idx_a1c_records_user ON a1c_records(user_id);
CREATE INDEX IF NOT EXISTS idx_a1c_records_user_date ON a1c_records(user_id, test_date DESC);

-- ============================================
-- TABLE: diabetes_medications
-- ============================================
CREATE TABLE IF NOT EXISTS diabetes_medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medication_name TEXT NOT NULL,
    medication_type diabetes_medication_type NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    start_date DATE NOT NULL,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diabetes_medications_user ON diabetes_medications(user_id);
CREATE INDEX IF NOT EXISTS idx_diabetes_medications_active ON diabetes_medications(user_id, active) WHERE active = TRUE;

-- ============================================
-- TABLE: glucose_alerts
-- ============================================
CREATE TABLE IF NOT EXISTS glucose_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    alert_type glucose_alert_type NOT NULL,
    threshold_value INTEGER NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    custom_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_alert_type UNIQUE (user_id, alert_type)
);

CREATE INDEX IF NOT EXISTS idx_glucose_alerts_user ON glucose_alerts(user_id);

-- ============================================
-- TABLE: carb_entries
-- ============================================
CREATE TABLE IF NOT EXISTS carb_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    carbs_grams INTEGER NOT NULL,
    meal_type carb_meal_type NOT NULL,
    food_description TEXT,
    linked_glucose_reading_id UUID REFERENCES glucose_readings(id) ON DELETE SET NULL,
    linked_insulin_dose_id UUID REFERENCES insulin_doses(id) ON DELETE SET NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_carbs_grams CHECK (carbs_grams >= 0 AND carbs_grams <= 500)
);

CREATE INDEX IF NOT EXISTS idx_carb_entries_user ON carb_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_carb_entries_user_recorded ON carb_entries(user_id, recorded_at DESC);

-- ============================================
-- TABLE: diabetes_daily_summary
-- ============================================
CREATE TABLE IF NOT EXISTS diabetes_daily_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    avg_glucose DECIMAL(6,2),
    min_glucose INTEGER,
    max_glucose INTEGER,
    time_in_range_percent DECIMAL(5,2),
    time_below_range_percent DECIMAL(5,2),
    time_above_range_percent DECIMAL(5,2),
    reading_count INTEGER NOT NULL DEFAULT 0,
    total_insulin_units DECIMAL(8,2),
    total_basal_units DECIMAL(8,2),
    total_bolus_units DECIMAL(8,2),
    total_carbs_grams INTEGER,
    glucose_variability DECIMAL(6,2),
    estimated_a1c DECIMAL(4,2),
    glucose_cv DECIMAL(5,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_daily_summary UNIQUE (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_diabetes_daily_summary_user ON diabetes_daily_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_diabetes_daily_summary_user_date ON diabetes_daily_summary(user_id, date DESC);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION get_glucose_status(p_value_mg_dl INTEGER)
RETURNS TEXT LANGUAGE plpgsql IMMUTABLE SET search_path = public AS $$
BEGIN
    IF p_value_mg_dl < 54 THEN RETURN 'severe_low';
    ELSIF p_value_mg_dl < 70 THEN RETURN 'low';
    ELSIF p_value_mg_dl <= 180 THEN RETURN 'normal';
    ELSIF p_value_mg_dl <= 250 THEN RETURN 'high';
    ELSE RETURN 'severe_high';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION calculate_time_in_range(p_user_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_profile RECORD;
    v_total INTEGER;
    v_in_range INTEGER;
    v_below INTEGER;
    v_above INTEGER;
BEGIN
    SELECT target_glucose_low, target_glucose_high INTO v_profile FROM diabetes_profiles WHERE user_id = p_user_id;
    IF v_profile IS NULL THEN v_profile.target_glucose_low := 70; v_profile.target_glucose_high := 180; END IF;

    SELECT COUNT(*),
        COUNT(*) FILTER (WHERE value_mg_dl BETWEEN v_profile.target_glucose_low AND v_profile.target_glucose_high),
        COUNT(*) FILTER (WHERE value_mg_dl < v_profile.target_glucose_low),
        COUNT(*) FILTER (WHERE value_mg_dl > v_profile.target_glucose_high)
    INTO v_total, v_in_range, v_below, v_above
    FROM glucose_readings WHERE user_id = p_user_id AND recorded_at::DATE BETWEEN p_start_date AND p_end_date;

    RETURN jsonb_build_object(
        'total_readings', v_total,
        'time_in_range_percent', CASE WHEN v_total > 0 THEN ROUND((v_in_range::DECIMAL / v_total) * 100, 1) ELSE 0 END,
        'time_below_range_percent', CASE WHEN v_total > 0 THEN ROUND((v_below::DECIMAL / v_total) * 100, 1) ELSE 0 END,
        'time_above_range_percent', CASE WHEN v_total > 0 THEN ROUND((v_above::DECIMAL / v_total) * 100, 1) ELSE 0 END
    );
END;
$$;

CREATE OR REPLACE FUNCTION calculate_estimated_a1c(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_avg DECIMAL(6,2);
    v_count INTEGER;
BEGIN
    SELECT AVG(value_mg_dl), COUNT(*) INTO v_avg, v_count
    FROM glucose_readings WHERE user_id = p_user_id AND recorded_at >= CURRENT_DATE - INTERVAL '90 days';

    IF v_count < 30 THEN
        RETURN jsonb_build_object('estimated_a1c', NULL, 'sufficient_data', FALSE);
    END IF;

    RETURN jsonb_build_object(
        'estimated_a1c', ROUND(3.31 + (0.02392 * v_avg), 1),
        'average_glucose', ROUND(v_avg, 0),
        'reading_count', v_count,
        'sufficient_data', TRUE
    );
END;
$$;

CREATE OR REPLACE FUNCTION get_glucose_trend(p_user_id UUID, p_hours INTEGER DEFAULT 3)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_oldest INTEGER;
    v_newest INTEGER;
    v_count INTEGER;
    v_rate DECIMAL(6,2);
    v_trend TEXT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM glucose_readings
    WHERE user_id = p_user_id AND recorded_at >= NOW() - (p_hours || ' hours')::INTERVAL;

    IF v_count < 2 THEN RETURN jsonb_build_object('trend', 'unknown', 'sufficient_data', FALSE); END IF;

    SELECT value_mg_dl INTO v_oldest FROM glucose_readings
    WHERE user_id = p_user_id AND recorded_at >= NOW() - (p_hours || ' hours')::INTERVAL ORDER BY recorded_at ASC LIMIT 1;

    SELECT value_mg_dl INTO v_newest FROM glucose_readings
    WHERE user_id = p_user_id AND recorded_at >= NOW() - (p_hours || ' hours')::INTERVAL ORDER BY recorded_at DESC LIMIT 1;

    v_rate := (v_newest - v_oldest)::DECIMAL / p_hours;

    IF v_rate > 60 THEN v_trend := 'rising_rapidly';
    ELSIF v_rate > 30 THEN v_trend := 'rising';
    ELSIF v_rate > 10 THEN v_trend := 'rising_slowly';
    ELSIF v_rate >= -10 THEN v_trend := 'stable';
    ELSIF v_rate >= -30 THEN v_trend := 'falling_slowly';
    ELSIF v_rate >= -60 THEN v_trend := 'falling';
    ELSE v_trend := 'falling_rapidly';
    END IF;

    RETURN jsonb_build_object('trend', v_trend, 'rate_per_hour', ROUND(v_rate, 1), 'sufficient_data', TRUE);
END;
$$;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE diabetes_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE insulin_doses ENABLE ROW LEVEL SECURITY;
ALTER TABLE a1c_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE diabetes_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE glucose_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE carb_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE diabetes_daily_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies for all tables
CREATE POLICY diabetes_profiles_select ON diabetes_profiles FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_profiles_insert ON diabetes_profiles FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_profiles_update ON diabetes_profiles FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_profiles_delete ON diabetes_profiles FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY glucose_readings_select ON glucose_readings FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY glucose_readings_insert ON glucose_readings FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY glucose_readings_update ON glucose_readings FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY glucose_readings_delete ON glucose_readings FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY insulin_doses_select ON insulin_doses FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY insulin_doses_insert ON insulin_doses FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY insulin_doses_update ON insulin_doses FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY insulin_doses_delete ON insulin_doses FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY a1c_records_select ON a1c_records FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY a1c_records_insert ON a1c_records FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY a1c_records_update ON a1c_records FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY a1c_records_delete ON a1c_records FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY diabetes_medications_select ON diabetes_medications FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_medications_insert ON diabetes_medications FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_medications_update ON diabetes_medications FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_medications_delete ON diabetes_medications FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY glucose_alerts_select ON glucose_alerts FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY glucose_alerts_insert ON glucose_alerts FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY glucose_alerts_update ON glucose_alerts FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY glucose_alerts_delete ON glucose_alerts FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY carb_entries_select ON carb_entries FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY carb_entries_insert ON carb_entries FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY carb_entries_update ON carb_entries FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY carb_entries_delete ON carb_entries FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY diabetes_daily_summary_select ON diabetes_daily_summary FOR SELECT USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_daily_summary_insert ON diabetes_daily_summary FOR INSERT WITH CHECK (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_daily_summary_update ON diabetes_daily_summary FOR UPDATE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));
CREATE POLICY diabetes_daily_summary_delete ON diabetes_daily_summary FOR DELETE USING (auth.uid() = (SELECT auth_id FROM users WHERE id = user_id));

-- Service role grants
GRANT SELECT, INSERT, UPDATE, DELETE ON diabetes_profiles TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON glucose_readings TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON insulin_doses TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON a1c_records TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON diabetes_medications TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON glucose_alerts TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON carb_entries TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON diabetes_daily_summary TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON diabetes_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON glucose_readings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON insulin_doses TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON a1c_records TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON diabetes_medications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON glucose_alerts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON carb_entries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON diabetes_daily_summary TO authenticated;
