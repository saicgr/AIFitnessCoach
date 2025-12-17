-- AI Fitness Coach - Subscription & Payment Tables
-- Migration 022: Subscriptions and payment tracking

-- Subscription tiers enum
DO $$ BEGIN
    CREATE TYPE subscription_tier AS ENUM ('free', 'premium', 'ultra', 'lifetime');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Subscription status enum
DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'expired', 'trial', 'grace_period', 'paused');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- User subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Subscription details
    tier subscription_tier NOT NULL DEFAULT 'free',
    status subscription_status NOT NULL DEFAULT 'active',

    -- RevenueCat integration
    revenuecat_customer_id VARCHAR,
    product_id VARCHAR, -- e.g., 'premium_yearly', 'ultra_monthly'
    entitlement_id VARCHAR,

    -- Trial info
    is_trial BOOLEAN DEFAULT FALSE,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,

    -- Subscription dates
    started_at TIMESTAMPTZ DEFAULT NOW(),
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    -- Payment info
    price_paid DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    store VARCHAR, -- 'app_store', 'play_store', 'stripe'

    -- Feature flags (for granular control)
    features JSONB DEFAULT '{}',

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_user_subscription UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tier ON user_subscriptions(tier);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_revenuecat ON user_subscriptions(revenuecat_customer_id);

-- Subscription history (tracks all changes)
CREATE TABLE IF NOT EXISTS subscription_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,

    -- What changed
    event_type VARCHAR NOT NULL, -- 'purchased', 'renewed', 'canceled', 'expired', 'upgraded', 'downgraded', 'trial_started', 'trial_converted', 'refunded'
    previous_tier subscription_tier,
    new_tier subscription_tier,

    -- RevenueCat event data
    revenuecat_event_id VARCHAR,
    product_id VARCHAR,

    -- Payment details
    price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    store VARCHAR,

    -- Metadata
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscription_history_user ON subscription_history(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_history_event ON subscription_history(event_type);
CREATE INDEX IF NOT EXISTS idx_subscription_history_created ON subscription_history(created_at);

-- Payment transactions (detailed payment records)
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,

    -- Transaction details
    transaction_id VARCHAR NOT NULL, -- Store transaction ID
    original_transaction_id VARCHAR, -- For subscription renewals
    product_id VARCHAR NOT NULL,

    -- Amount
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    price_in_usd DECIMAL(10, 2), -- Normalized for analytics

    -- Store info
    store VARCHAR NOT NULL, -- 'app_store', 'play_store'
    store_transaction_date TIMESTAMPTZ,

    -- Status
    status VARCHAR NOT NULL DEFAULT 'completed', -- 'completed', 'refunded', 'disputed'
    refunded_at TIMESTAMPTZ,
    refund_reason VARCHAR,

    -- Metadata
    receipt_data TEXT, -- Store receipt for verification
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_id ON payment_transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON payment_transactions(created_at);

-- Paywall impressions (track conversion funnel)
CREATE TABLE IF NOT EXISTS paywall_impressions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    anonymous_id VARCHAR, -- For tracking before auth

    -- Which paywall screen
    screen VARCHAR NOT NULL, -- 'features', 'timeline', 'pricing'
    source VARCHAR, -- 'onboarding', 'upgrade_prompt', 'settings', 'feature_gate'

    -- Interaction
    action VARCHAR NOT NULL, -- 'viewed', 'dismissed', 'continued', 'purchased', 'restored'
    selected_product VARCHAR, -- If action is 'purchased'

    -- Time tracking
    time_on_screen_ms INTEGER,

    -- Session info
    session_id VARCHAR,
    device_type VARCHAR,
    app_version VARCHAR,

    -- A/B testing
    experiment_id VARCHAR,
    variant VARCHAR,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_paywall_impressions_user ON paywall_impressions(user_id);
CREATE INDEX IF NOT EXISTS idx_paywall_impressions_screen ON paywall_impressions(screen);
CREATE INDEX IF NOT EXISTS idx_paywall_impressions_created ON paywall_impressions(created_at);

-- Feature gates (control premium features)
CREATE TABLE IF NOT EXISTS feature_gates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_key VARCHAR UNIQUE NOT NULL,
    display_name VARCHAR NOT NULL,
    description TEXT,

    -- Access control
    minimum_tier subscription_tier NOT NULL DEFAULT 'premium',

    -- Usage limits by tier (null = unlimited)
    free_limit INTEGER,
    premium_limit INTEGER,
    ultra_limit INTEGER,

    -- Feature flags
    is_enabled BOOLEAN DEFAULT TRUE,
    is_beta BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default feature gates
INSERT INTO feature_gates (feature_key, display_name, description, minimum_tier, free_limit, premium_limit, ultra_limit) VALUES
    ('ai_chat', 'AI Coach Chat', 'Chat with AI fitness coach', 'free', 10, NULL, NULL),
    ('ai_workout_generation', 'AI Workout Generation', 'Generate personalized workouts', 'free', 3, NULL, NULL),
    ('food_scanning', 'AI Food Photo Scanning', 'Scan food photos for nutrition', 'premium', 0, 30, NULL),
    ('advanced_analytics', 'Advanced Progress Analytics', 'Detailed progress tracking', 'premium', NULL, NULL, NULL),
    ('custom_workouts', 'Custom Workout Builder', 'Create custom workouts', 'premium', 0, NULL, NULL),
    ('workout_sharing', 'Social Workout Sharing', 'Share workouts on Instagram', 'ultra', 0, 0, NULL),
    ('trainer_mode', 'Personal Trainer Mode', 'Advanced trainer features', 'ultra', 0, 0, NULL),
    ('priority_support', 'Priority Support', '24h response time support', 'ultra', 0, 0, NULL)
ON CONFLICT (feature_key) DO NOTHING;

-- Feature usage tracking
CREATE TABLE IF NOT EXISTS feature_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_key VARCHAR NOT NULL,

    -- Usage tracking
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    usage_count INTEGER DEFAULT 1,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    CONSTRAINT unique_user_feature_day UNIQUE (user_id, feature_key, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_feature_usage_user ON feature_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature ON feature_usage(feature_key);
CREATE INDEX IF NOT EXISTS idx_feature_usage_date ON feature_usage(usage_date);

-- Enable RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE paywall_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_usage ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can read their own subscription
CREATE POLICY "Users can read own subscription" ON user_subscriptions
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can read their own subscription history
CREATE POLICY "Users can read own subscription history" ON subscription_history
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can read their own payment transactions
CREATE POLICY "Users can read own transactions" ON payment_transactions
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can insert their own paywall impressions
CREATE POLICY "Users can insert own impressions" ON paywall_impressions
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

CREATE POLICY "Users can read own impressions" ON paywall_impressions
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) OR user_id IS NULL);

-- Users can manage their own feature usage
CREATE POLICY "Users can manage own feature usage" ON feature_usage
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Service role can manage all (for webhook handlers)
CREATE POLICY "Service role full access subscriptions" ON user_subscriptions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access history" ON subscription_history
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access transactions" ON payment_transactions
    FOR ALL USING (auth.role() = 'service_role');

-- Function to update subscription updated_at
CREATE OR REPLACE FUNCTION update_subscription_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_updated_at();

-- Function to create subscription record for new users
CREATE OR REPLACE FUNCTION create_default_subscription()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_subscriptions (user_id, tier, status)
    VALUES (NEW.id, 'free', 'active')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_user_subscription
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_subscription();
