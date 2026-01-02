-- Migration 082: Subscription cancellation and pause system

DO $$ BEGIN
    CREATE TYPE cancellation_request_status AS ENUM ('pending','retention_offered','retention_accepted','confirmed','processed','withdrawn');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE cancellation_reason AS ENUM ('too_expensive','not_using','found_alternative','technical_issues','missing_features','temporary_break','financial_hardship','not_satisfied','other');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS cancellation_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason cancellation_reason NOT NULL,
    reason_details TEXT,
    status cancellation_request_status NOT NULL DEFAULT 'pending',
    retention_offer_shown BOOLEAN DEFAULT FALSE,
    retention_offer_type VARCHAR,
    retention_offer_accepted BOOLEAN DEFAULT FALSE,
    effective_date TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    platform VARCHAR,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cancellation_requests_user ON cancellation_requests(user_id);

DO $$ BEGIN
    CREATE TYPE subscription_pause_status AS ENUM ('scheduled','active','resumed','expired','canceled');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS subscription_pause_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status subscription_pause_status NOT NULL DEFAULT 'scheduled',
    pause_reason TEXT,
    pause_start_date TIMESTAMPTZ NOT NULL,
    pause_end_date TIMESTAMPTZ NOT NULL,
    actual_resume_date TIMESTAMPTZ,
    requested_duration_days INTEGER NOT NULL,
    platform VARCHAR,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pause_history_user ON subscription_pause_history(user_id);

CREATE TABLE IF NOT EXISTS retention_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_code VARCHAR UNIQUE NOT NULL,
    offer_name VARCHAR NOT NULL,
    offer_description TEXT,
    offer_type VARCHAR NOT NULL,
    discount_percent INTEGER,
    discount_duration_months INTEGER,
    free_days INTEGER,
    max_pause_days INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO retention_offers (offer_code, offer_name, offer_description, offer_type, discount_percent, discount_duration_months, free_days, max_pause_days, is_active) VALUES
    ('STAY50', 'Stay and Save 50%', 'Get 50% off for 3 months', 'discount', 50, 3, NULL, NULL, true),
    ('FREEMONTH', 'Free Month', 'One month free', 'free_period', NULL, NULL, 30, NULL, true),
    ('PAUSEOPTION', 'Pause Subscription', 'Pause for up to 3 months', 'pause', NULL, NULL, NULL, 90, true)
ON CONFLICT (offer_code) DO NOTHING;

ALTER TABLE cancellation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_pause_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE retention_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own cancellation requests" ON cancellation_requests FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Service role cancellation requests" ON cancellation_requests FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Users can read own pause history" ON subscription_pause_history FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Service role pause history" ON subscription_pause_history FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Read active retention offers" ON retention_offers FOR SELECT USING (is_active = true);

ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS paused_until TIMESTAMPTZ;
