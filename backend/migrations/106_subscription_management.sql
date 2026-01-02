-- =============================================
-- Migration: 106_subscription_management
-- Description: Add tables for subscription pause/resume and retention offers
-- Created: 2025-12-30
-- =============================================

-- =============================================
-- 1. Subscription Pauses Table
-- Tracks all subscription pause events
-- =============================================
CREATE TABLE IF NOT EXISTS subscription_pauses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    paused_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resume_date TIMESTAMPTZ NOT NULL,
    actual_resume_date TIMESTAMPTZ,
    duration_days INTEGER NOT NULL,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resumed', 'resumed_early', 'expired', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for subscription_pauses
CREATE INDEX IF NOT EXISTS idx_subscription_pauses_user_id ON subscription_pauses(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_pauses_status ON subscription_pauses(status);
CREATE INDEX IF NOT EXISTS idx_subscription_pauses_resume_date ON subscription_pauses(resume_date);

-- =============================================
-- 2. Add pause columns to user_subscriptions
-- =============================================
ALTER TABLE user_subscriptions
ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS pause_resume_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS pause_duration_days INTEGER,
ADD COLUMN IF NOT EXISTS pause_reason TEXT,
ADD COLUMN IF NOT EXISTS resumed_at TIMESTAMPTZ;

-- =============================================
-- 3. Retention Offers Accepted Table
-- Tracks which retention offers users have accepted
-- =============================================
CREATE TABLE IF NOT EXISTS retention_offers_accepted (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    offer_id TEXT NOT NULL,
    offer_type TEXT NOT NULL CHECK (offer_type IN ('discount', 'extension', 'downgrade', 'pause')),
    cancellation_reason TEXT,
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    discount_percent INTEGER,
    extension_days INTEGER,
    target_tier TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for retention_offers_accepted
CREATE INDEX IF NOT EXISTS idx_retention_offers_user_id ON retention_offers_accepted(user_id);
CREATE INDEX IF NOT EXISTS idx_retention_offers_type ON retention_offers_accepted(offer_type);
CREATE INDEX IF NOT EXISTS idx_retention_offers_accepted_at ON retention_offers_accepted(accepted_at);

-- =============================================
-- 4. Subscription Discounts Table
-- Tracks pending discounts for next billing cycle
-- =============================================
CREATE TABLE IF NOT EXISTS subscription_discounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    discount_percent INTEGER NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
    reason TEXT NOT NULL,
    offer_id TEXT,
    valid_until TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'applied', 'expired', 'cancelled')),
    applied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for subscription_discounts
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_user_id ON subscription_discounts(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_status ON subscription_discounts(status);
CREATE INDEX IF NOT EXISTS idx_subscription_discounts_valid_until ON subscription_discounts(valid_until);

-- =============================================
-- 5. Enable RLS on new tables
-- =============================================
ALTER TABLE subscription_pauses ENABLE ROW LEVEL SECURITY;
ALTER TABLE retention_offers_accepted ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_discounts ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 6. RLS Policies for subscription_pauses
-- =============================================
DROP POLICY IF EXISTS "Users can view own subscription pauses" ON subscription_pauses;
CREATE POLICY "Users can view own subscription pauses"
    ON subscription_pauses FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscription pauses" ON subscription_pauses;
CREATE POLICY "Users can insert own subscription pauses"
    ON subscription_pauses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscription pauses" ON subscription_pauses;
CREATE POLICY "Users can update own subscription pauses"
    ON subscription_pauses FOR UPDATE
    USING (auth.uid() = user_id);

-- Service role access
DROP POLICY IF EXISTS "Service role full access to subscription_pauses" ON subscription_pauses;
CREATE POLICY "Service role full access to subscription_pauses"
    ON subscription_pauses FOR ALL
    USING (auth.role() = 'service_role');

-- =============================================
-- 7. RLS Policies for retention_offers_accepted
-- =============================================
DROP POLICY IF EXISTS "Users can view own retention offers" ON retention_offers_accepted;
CREATE POLICY "Users can view own retention offers"
    ON retention_offers_accepted FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own retention offers" ON retention_offers_accepted;
CREATE POLICY "Users can insert own retention offers"
    ON retention_offers_accepted FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Service role access
DROP POLICY IF EXISTS "Service role full access to retention_offers_accepted" ON retention_offers_accepted;
CREATE POLICY "Service role full access to retention_offers_accepted"
    ON retention_offers_accepted FOR ALL
    USING (auth.role() = 'service_role');

-- =============================================
-- 8. RLS Policies for subscription_discounts
-- =============================================
DROP POLICY IF EXISTS "Users can view own subscription discounts" ON subscription_discounts;
CREATE POLICY "Users can view own subscription discounts"
    ON subscription_discounts FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscription discounts" ON subscription_discounts;
CREATE POLICY "Users can insert own subscription discounts"
    ON subscription_discounts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscription discounts" ON subscription_discounts;
CREATE POLICY "Users can update own subscription discounts"
    ON subscription_discounts FOR UPDATE
    USING (auth.uid() = user_id);

-- Service role access
DROP POLICY IF EXISTS "Service role full access to subscription_discounts" ON subscription_discounts;
CREATE POLICY "Service role full access to subscription_discounts"
    ON subscription_discounts FOR ALL
    USING (auth.role() = 'service_role');

-- =============================================
-- 9. Updated_at triggers
-- =============================================
CREATE OR REPLACE FUNCTION update_subscription_pauses_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_subscription_pauses_updated_at ON subscription_pauses;
CREATE TRIGGER trigger_update_subscription_pauses_updated_at
    BEFORE UPDATE ON subscription_pauses
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_pauses_updated_at();

CREATE OR REPLACE FUNCTION update_subscription_discounts_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_subscription_discounts_updated_at ON subscription_discounts;
CREATE TRIGGER trigger_update_subscription_discounts_updated_at
    BEFORE UPDATE ON subscription_discounts
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_discounts_updated_at();

-- =============================================
-- 10. Function to auto-resume expired pauses
-- Can be called by a cron job
-- =============================================
CREATE OR REPLACE FUNCTION process_expired_subscription_pauses()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    processed_count INTEGER := 0;
    pause_record RECORD;
BEGIN
    -- Find all active pauses that have passed their resume date
    FOR pause_record IN
        SELECT sp.id, sp.user_id, us.tier
        FROM subscription_pauses sp
        JOIN user_subscriptions us ON sp.user_id = us.user_id
        WHERE sp.status = 'active'
        AND sp.resume_date <= NOW()
    LOOP
        -- Update the pause record
        UPDATE subscription_pauses
        SET status = 'resumed',
            actual_resume_date = NOW(),
            updated_at = NOW()
        WHERE id = pause_record.id;

        -- Update the subscription to active
        UPDATE user_subscriptions
        SET status = 'active',
            resumed_at = NOW(),
            paused_at = NULL,
            pause_resume_date = NULL,
            pause_duration_days = NULL,
            pause_reason = NULL
        WHERE user_id = pause_record.user_id;

        -- Record in subscription history
        INSERT INTO subscription_history (user_id, event_type, new_tier, metadata)
        VALUES (
            pause_record.user_id,
            'resumed',
            pause_record.tier,
            jsonb_build_object(
                'resumed_by', 'auto_resume',
                'pause_id', pause_record.id
            )
        );

        processed_count := processed_count + 1;
    END LOOP;

    RETURN processed_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 11. Function to expire unused discounts
-- =============================================
CREATE OR REPLACE FUNCTION expire_unused_subscription_discounts()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE subscription_discounts
    SET status = 'expired',
        updated_at = NOW()
    WHERE status = 'pending'
    AND valid_until < NOW();

    GET DIAGNOSTICS expired_count = ROW_COUNT;

    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 12. Cancellation Feedback Table (for analytics)
-- =============================================
CREATE TABLE IF NOT EXISTS cancellation_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    reason_category TEXT CHECK (reason_category IN (
        'too_expensive',
        'not_using',
        'missing_features',
        'found_alternative',
        'technical_issues',
        'other'
    )),
    feedback_text TEXT,
    subscription_tier TEXT,
    subscription_duration_days INTEGER,
    offer_shown BOOLEAN DEFAULT FALSE,
    offer_accepted BOOLEAN DEFAULT FALSE,
    offer_id TEXT,
    cancelled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for cancellation_feedback
CREATE INDEX IF NOT EXISTS idx_cancellation_feedback_user_id ON cancellation_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_feedback_reason ON cancellation_feedback(reason_category);
CREATE INDEX IF NOT EXISTS idx_cancellation_feedback_cancelled_at ON cancellation_feedback(cancelled_at);

-- RLS for cancellation_feedback
ALTER TABLE cancellation_feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own cancellation feedback" ON cancellation_feedback;
CREATE POLICY "Users can insert own cancellation feedback"
    ON cancellation_feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role full access to cancellation_feedback" ON cancellation_feedback;
CREATE POLICY "Service role full access to cancellation_feedback"
    ON cancellation_feedback FOR ALL
    USING (auth.role() = 'service_role');

-- =============================================
-- 13. Subscription Metrics View (for analytics)
-- =============================================
CREATE OR REPLACE VIEW subscription_pause_metrics AS
SELECT
    DATE_TRUNC('month', paused_at) AS month,
    COUNT(*) AS total_pauses,
    AVG(duration_days) AS avg_duration_days,
    COUNT(*) FILTER (WHERE status = 'resumed_early') AS early_resumes,
    COUNT(*) FILTER (WHERE status = 'resumed') AS auto_resumes,
    COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_during_pause
FROM subscription_pauses
GROUP BY DATE_TRUNC('month', paused_at)
ORDER BY month DESC;

CREATE OR REPLACE VIEW retention_offer_metrics AS
SELECT
    DATE_TRUNC('month', accepted_at) AS month,
    offer_type,
    COUNT(*) AS offers_accepted,
    AVG(discount_percent) FILTER (WHERE offer_type = 'discount') AS avg_discount,
    AVG(extension_days) FILTER (WHERE offer_type = 'extension') AS avg_extension_days
FROM retention_offers_accepted
GROUP BY DATE_TRUNC('month', accepted_at), offer_type
ORDER BY month DESC, offer_type;

-- =============================================
-- 14. Grant permissions
-- =============================================
GRANT SELECT, INSERT, UPDATE ON subscription_pauses TO authenticated;
GRANT SELECT, INSERT ON retention_offers_accepted TO authenticated;
GRANT SELECT, INSERT, UPDATE ON subscription_discounts TO authenticated;
GRANT INSERT ON cancellation_feedback TO authenticated;
GRANT SELECT ON subscription_pause_metrics TO authenticated;
GRANT SELECT ON retention_offer_metrics TO authenticated;

-- Grant service role full access
GRANT ALL ON subscription_pauses TO service_role;
GRANT ALL ON retention_offers_accepted TO service_role;
GRANT ALL ON subscription_discounts TO service_role;
GRANT ALL ON cancellation_feedback TO service_role;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION process_expired_subscription_pauses() TO service_role;
GRANT EXECUTE ON FUNCTION expire_unused_subscription_discounts() TO service_role;

-- =============================================
-- Done!
-- =============================================
