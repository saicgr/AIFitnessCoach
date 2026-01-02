-- Migration: 110_strain_prevention.sql
-- Description: Strain/overuse injury prevention system
-- Created: 2025-12-31
-- Purpose: Track training volume and prevent overuse injuries by detecting dangerous volume increases

-- Weekly volume tracking for strain prevention
CREATE TABLE IF NOT EXISTS weekly_volume_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    muscle_group TEXT NOT NULL,
    total_sets INTEGER NOT NULL DEFAULT 0,
    total_reps INTEGER NOT NULL DEFAULT 0,
    total_volume_kg DECIMAL(10,2) NOT NULL DEFAULT 0, -- sets * reps * weight
    cardio_minutes INTEGER NOT NULL DEFAULT 0,
    strain_risk_score DECIMAL(3,2) DEFAULT 0, -- 0.0 to 1.0
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, week_start, muscle_group)
);

-- Volume increase alerts
CREATE TABLE IF NOT EXISTS volume_increase_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    muscle_group TEXT NOT NULL,
    previous_week_volume DECIMAL(10,2),
    current_week_volume DECIMAL(10,2),
    increase_percentage DECIMAL(5,2),
    alert_level TEXT NOT NULL, -- 'warning', 'danger', 'critical'
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMPTZ,
    recommendation TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User strain history for pattern detection
CREATE TABLE IF NOT EXISTS strain_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body_part TEXT NOT NULL,
    strain_date DATE NOT NULL,
    severity TEXT NOT NULL, -- 'mild', 'moderate', 'severe'
    activity_type TEXT, -- 'strength', 'cardio', 'both'
    volume_at_time DECIMAL(10,2),
    volume_increase_percent DECIMAL(5,2),
    recovery_days INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Volume caps per muscle group (personalized based on history)
CREATE TABLE IF NOT EXISTS muscle_volume_caps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    muscle_group TEXT NOT NULL,
    max_weekly_sets INTEGER NOT NULL DEFAULT 20,
    max_weekly_volume_kg DECIMAL(10,2),
    max_volume_increase_percent DECIMAL(5,2) DEFAULT 10, -- Default 10% rule
    auto_adjusted BOOLEAN DEFAULT FALSE,
    adjustment_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, muscle_group)
);

-- Indexes for efficient querying
CREATE INDEX idx_volume_tracking_user_week ON weekly_volume_tracking(user_id, week_start);
CREATE INDEX idx_volume_tracking_user_muscle ON weekly_volume_tracking(user_id, muscle_group);
CREATE INDEX idx_strain_history_user ON strain_history(user_id, strain_date DESC);
CREATE INDEX idx_strain_history_body_part ON strain_history(user_id, body_part);
CREATE INDEX idx_volume_alerts_user ON volume_increase_alerts(user_id, created_at DESC);
CREATE INDEX idx_volume_alerts_unacknowledged ON volume_increase_alerts(user_id, acknowledged) WHERE acknowledged = FALSE;
CREATE INDEX idx_muscle_caps_user ON muscle_volume_caps(user_id);

-- Row Level Security
ALTER TABLE weekly_volume_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE volume_increase_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE strain_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE muscle_volume_caps ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY volume_tracking_policy ON weekly_volume_tracking FOR ALL USING (auth.uid() = user_id);
CREATE POLICY volume_alerts_policy ON volume_increase_alerts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY strain_history_policy ON strain_history FOR ALL USING (auth.uid() = user_id);
CREATE POLICY volume_caps_policy ON muscle_volume_caps FOR ALL USING (auth.uid() = user_id);
