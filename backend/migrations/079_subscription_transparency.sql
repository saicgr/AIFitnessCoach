-- FitWiz - Subscription Transparency Features
-- Migration 079: Refund requests and enhanced subscription history
-- Addresses complaint: "Tried to automatically put me in a more expensive tier"

-- ============================================================
-- REFUND REQUEST STATUS ENUM
-- ============================================================
DO $$ BEGIN
    CREATE TYPE refund_status AS ENUM ('pending', 'approved', 'denied', 'processed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================
-- REFUND REQUESTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS refund_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,

    -- Request details
    reason TEXT NOT NULL,
    additional_details TEXT,

    -- Status tracking
    status refund_status NOT NULL DEFAULT 'pending',

    -- Amount details
    amount DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',

    -- Tracking ID for user reference
    tracking_id VARCHAR(20) NOT NULL UNIQUE,

    -- Processing info
    processed_at TIMESTAMPTZ,
    processed_by VARCHAR, -- Admin/system that processed
    admin_notes TEXT, -- Internal notes

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_refund_requests_user_id ON refund_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_status ON refund_requests(status);
CREATE INDEX IF NOT EXISTS idx_refund_requests_tracking_id ON refund_requests(tracking_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_created_at ON refund_requests(created_at);

-- ============================================================
-- SUBSCRIPTION PRICE HISTORY TABLE
-- Tracks price changes for transparency
-- ============================================================
CREATE TABLE IF NOT EXISTS subscription_price_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,

    -- Price info
    product_id VARCHAR NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',

    -- Period
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ,

    -- Change reason
    change_reason VARCHAR, -- 'initial', 'renewal', 'upgrade', 'downgrade', 'price_change'

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_price_history_user ON subscription_price_history(user_id);
CREATE INDEX IF NOT EXISTS idx_price_history_subscription ON subscription_price_history(subscription_id);

-- ============================================================
-- UPCOMING RENEWALS VIEW
-- Shows users their upcoming renewal info with price
-- ============================================================
CREATE OR REPLACE VIEW upcoming_renewals AS
SELECT
    us.user_id,
    us.tier,
    us.status,
    us.product_id,
    us.current_period_end AS renewal_date,
    us.price_paid AS current_price,
    us.currency,
    us.is_trial,
    us.trial_end_date,
    us.canceled_at IS NOT NULL AS will_cancel,
    us.expires_at AS cancellation_effective_date,
    CASE
        WHEN us.is_trial THEN 'Your trial ends and billing starts'
        WHEN us.canceled_at IS NOT NULL THEN 'Subscription will end (canceled)'
        WHEN us.status = 'grace_period' THEN 'Payment required to continue'
        ELSE 'Subscription will auto-renew'
    END AS renewal_status_message,
    CASE
        WHEN us.current_period_end > NOW() THEN
            EXTRACT(DAY FROM (us.current_period_end - NOW()))::INTEGER
        ELSE 0
    END AS days_until_renewal
FROM user_subscriptions us
WHERE us.status IN ('active', 'trial', 'grace_period', 'canceled');

-- ============================================================
-- USER SUBSCRIPTION HISTORY VIEW
-- Human-readable subscription history with all changes
-- ============================================================
CREATE OR REPLACE VIEW user_subscription_history_readable AS
SELECT
    sh.id,
    sh.user_id,
    sh.event_type,
    sh.created_at,
    sh.previous_tier,
    sh.new_tier,
    sh.product_id,
    sh.price,
    sh.currency,
    sh.store,
    -- Human readable event description
    CASE sh.event_type
        WHEN 'purchased' THEN 'Subscribed to ' || COALESCE(sh.new_tier::TEXT, 'plan')
        WHEN 'renewed' THEN 'Subscription renewed'
        WHEN 'canceled' THEN 'Subscription canceled'
        WHEN 'expired' THEN 'Subscription expired'
        WHEN 'upgraded' THEN 'Upgraded from ' || COALESCE(sh.previous_tier::TEXT, 'previous plan') || ' to ' || COALESCE(sh.new_tier::TEXT, 'new plan')
        WHEN 'downgraded' THEN 'Downgraded from ' || COALESCE(sh.previous_tier::TEXT, 'previous plan') || ' to ' || COALESCE(sh.new_tier::TEXT, 'new plan')
        WHEN 'trial_started' THEN 'Started free trial'
        WHEN 'trial_converted' THEN 'Trial converted to paid subscription'
        WHEN 'refunded' THEN 'Refund processed'
        WHEN 'billing_issue' THEN 'Billing issue detected'
        ELSE sh.event_type
    END AS event_description,
    -- Format price for display
    CASE
        WHEN sh.price IS NOT NULL THEN
            sh.currency || ' ' || TRIM(TO_CHAR(sh.price, '999,999.99'))
        ELSE NULL
    END AS price_display
FROM subscription_history sh
ORDER BY sh.created_at DESC;

-- ============================================================
-- ENABLE RLS ON NEW TABLES
-- ============================================================
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_price_history ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES FOR REFUND REQUESTS
-- ============================================================

-- Users can read their own refund requests
DROP POLICY IF EXISTS "Users can read own refund requests" ON refund_requests;
CREATE POLICY "Users can read own refund requests" ON refund_requests
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can create their own refund requests
DROP POLICY IF EXISTS "Users can create own refund requests" ON refund_requests;
CREATE POLICY "Users can create own refund requests" ON refund_requests
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Service role can manage all refund requests (for processing)
DROP POLICY IF EXISTS "Service role full access refund requests" ON refund_requests;
CREATE POLICY "Service role full access refund requests" ON refund_requests
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- RLS POLICIES FOR SUBSCRIPTION PRICE HISTORY
-- ============================================================

-- Users can read their own price history
DROP POLICY IF EXISTS "Users can read own price history" ON subscription_price_history;
CREATE POLICY "Users can read own price history" ON subscription_price_history
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Service role can manage all price history
DROP POLICY IF EXISTS "Service role full access price history" ON subscription_price_history;
CREATE POLICY "Service role full access price history" ON subscription_price_history
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- FUNCTION: GENERATE TRACKING ID
-- Creates a unique tracking ID for refund requests
-- ============================================================
CREATE OR REPLACE FUNCTION generate_refund_tracking_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
    tracking_id VARCHAR(20);
    exists_already BOOLEAN;
BEGIN
    LOOP
        -- Generate format: RF-YYYYMMDD-XXXXX
        tracking_id := 'RF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                       UPPER(SUBSTRING(md5(random()::text) FROM 1 FOR 5));

        -- Check if it already exists
        SELECT EXISTS(SELECT 1 FROM refund_requests WHERE refund_requests.tracking_id = generate_refund_tracking_id.tracking_id)
        INTO exists_already;

        IF NOT exists_already THEN
            RETURN tracking_id;
        END IF;
    END LOOP;
END;
$$;

-- ============================================================
-- TRIGGER: UPDATE REFUND REQUEST TIMESTAMP
-- ============================================================
CREATE OR REPLACE FUNCTION update_refund_request_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS refund_request_updated_at ON refund_requests;
CREATE TRIGGER refund_request_updated_at
    BEFORE UPDATE ON refund_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_refund_request_updated_at();

-- ============================================================
-- TRIGGER: AUTO-GENERATE TRACKING ID
-- ============================================================
CREATE OR REPLACE FUNCTION auto_generate_tracking_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.tracking_id IS NULL THEN
        NEW.tracking_id := generate_refund_tracking_id();
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS refund_request_tracking_id ON refund_requests;
CREATE TRIGGER refund_request_tracking_id
    BEFORE INSERT ON refund_requests
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_tracking_id();

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================
GRANT SELECT ON upcoming_renewals TO authenticated;
GRANT SELECT ON user_subscription_history_readable TO authenticated;
GRANT SELECT, INSERT ON refund_requests TO authenticated;
GRANT SELECT ON subscription_price_history TO authenticated;

-- Service role needs full access
GRANT ALL ON refund_requests TO service_role;
GRANT ALL ON subscription_price_history TO service_role;
