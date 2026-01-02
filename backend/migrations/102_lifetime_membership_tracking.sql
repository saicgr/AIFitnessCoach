-- FitWiz - Lifetime Membership Tracking System
-- Migration 102: Enhanced lifetime membership handling
--
-- Purpose:
-- - Track lifetime members with dedicated fields
-- - Provide member tier recognition (Veteran, Loyal, Established, New)
-- - Ensure lifetime members never expire
-- - Skip renewal notifications for lifetime members
-- - Full feature access for lifetime members

-- =============================================================================
-- SCHEMA UPDATES
-- =============================================================================

-- Add lifetime-specific tracking fields to user_subscriptions
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS is_lifetime BOOLEAN DEFAULT FALSE;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS lifetime_purchase_date TIMESTAMPTZ;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS lifetime_original_price DECIMAL(10, 2);
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS lifetime_promotion_code VARCHAR;

-- Add lifetime member recognition tier (for badges/rewards)
-- This is calculated but cached for performance
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS lifetime_member_tier VARCHAR;

-- Indexes for efficient lifetime queries
CREATE INDEX IF NOT EXISTS idx_subscriptions_is_lifetime ON user_subscriptions(is_lifetime) WHERE is_lifetime = TRUE;
CREATE INDEX IF NOT EXISTS idx_subscriptions_lifetime_date ON user_subscriptions(lifetime_purchase_date) WHERE is_lifetime = TRUE;

-- =============================================================================
-- LIFETIME MEMBER BENEFITS VIEW
-- =============================================================================

-- Create view for lifetime member benefits and tier
CREATE OR REPLACE VIEW lifetime_member_benefits AS
SELECT
    us.user_id,
    us.lifetime_purchase_date,
    us.lifetime_original_price,
    us.lifetime_promotion_code,
    EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date)::INTEGER as days_as_member,
    EXTRACT(MONTHS FROM NOW() - us.lifetime_purchase_date)::INTEGER as months_as_member,
    CASE
        WHEN EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date) >= 365 THEN 'Veteran'
        WHEN EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date) >= 180 THEN 'Loyal'
        WHEN EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date) >= 90 THEN 'Established'
        ELSE 'New'
    END as member_tier,
    CASE
        WHEN EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date) >= 365 THEN 4
        WHEN EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date) >= 180 THEN 3
        WHEN EXTRACT(DAYS FROM NOW() - us.lifetime_purchase_date) >= 90 THEN 2
        ELSE 1
    END as member_tier_level,
    -- Feature unlocks (all features for lifetime)
    ARRAY['unlimited_workouts', 'ai_coach', 'nutrition_tracking', 'progress_analytics',
          'exercise_library', 'custom_workouts', 'workout_sharing', 'trainer_mode',
          'priority_support', 'early_access'] as features_unlocked,
    -- Estimated value provided (assuming average monthly cost)
    (EXTRACT(MONTHS FROM NOW() - us.lifetime_purchase_date) * 9.99)::DECIMAL(10, 2) as estimated_value_received,
    -- Value vs price ratio
    CASE
        WHEN us.lifetime_original_price > 0 THEN
            ROUND((EXTRACT(MONTHS FROM NOW() - us.lifetime_purchase_date) * 9.99 / us.lifetime_original_price)::NUMERIC, 2)
        ELSE 0
    END as value_multiplier,
    u.name as user_name,
    u.email as user_email,
    u.created_at as account_created_at
FROM user_subscriptions us
JOIN users u ON us.user_id = u.id
WHERE us.is_lifetime = TRUE
  AND us.tier = 'lifetime';

-- Set security definer for the view
COMMENT ON VIEW lifetime_member_benefits IS 'View showing lifetime member status, tier, and benefits. Use for AI personalization and badge display.';

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Function to check if user is lifetime member
CREATE OR REPLACE FUNCTION is_lifetime_member(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_lifetime BOOLEAN;
BEGIN
    SELECT is_lifetime INTO v_is_lifetime
    FROM user_subscriptions
    WHERE user_id = p_user_id;

    RETURN COALESCE(v_is_lifetime, FALSE);
END;
$$;

-- Function to get lifetime member tier
CREATE OR REPLACE FUNCTION get_lifetime_member_tier(p_user_id UUID)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tier VARCHAR;
    v_purchase_date TIMESTAMPTZ;
    v_days_as_member INTEGER;
BEGIN
    SELECT lifetime_purchase_date INTO v_purchase_date
    FROM user_subscriptions
    WHERE user_id = p_user_id AND is_lifetime = TRUE;

    IF v_purchase_date IS NULL THEN
        RETURN NULL;
    END IF;

    v_days_as_member := EXTRACT(DAYS FROM NOW() - v_purchase_date)::INTEGER;

    IF v_days_as_member >= 365 THEN
        RETURN 'Veteran';
    ELSIF v_days_as_member >= 180 THEN
        RETURN 'Loyal';
    ELSIF v_days_as_member >= 90 THEN
        RETURN 'Established';
    ELSE
        RETURN 'New';
    END IF;
END;
$$;

-- Function to get lifetime member details for AI context
CREATE OR REPLACE FUNCTION get_lifetime_member_context(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'is_lifetime_member', TRUE,
        'purchase_date', lifetime_purchase_date,
        'days_as_member', EXTRACT(DAYS FROM NOW() - lifetime_purchase_date)::INTEGER,
        'member_tier', get_lifetime_member_tier(p_user_id),
        'ai_context', 'This user is a valued lifetime member since ' ||
            TO_CHAR(lifetime_purchase_date, 'Month DD, YYYY') ||
            '. Treat them as a long-term committed customer who has invested in their fitness journey.',
        'features_unlocked', ARRAY['all']
    ) INTO v_result
    FROM user_subscriptions
    WHERE user_id = p_user_id AND is_lifetime = TRUE;

    IF v_result IS NULL THEN
        RETURN jsonb_build_object('is_lifetime_member', FALSE);
    END IF;

    RETURN v_result;
END;
$$;

-- =============================================================================
-- MIGRATION: UPDATE EXISTING LIFETIME MEMBERS
-- =============================================================================

-- Mark existing lifetime tier users as lifetime members
UPDATE user_subscriptions
SET
    is_lifetime = TRUE,
    lifetime_purchase_date = COALESCE(started_at, created_at),
    lifetime_original_price = price_paid,
    -- Lifetime members should never expire
    current_period_end = NULL,
    expires_at = NULL
WHERE tier = 'lifetime' AND is_lifetime IS NOT TRUE;

-- Update cached lifetime_member_tier for existing members
UPDATE user_subscriptions
SET lifetime_member_tier = get_lifetime_member_tier(user_id)
WHERE is_lifetime = TRUE;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to handle lifetime subscription setup
CREATE OR REPLACE FUNCTION setup_lifetime_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- When tier is set to lifetime, set up lifetime fields
    IF NEW.tier = 'lifetime' AND (OLD.tier IS NULL OR OLD.tier != 'lifetime') THEN
        NEW.is_lifetime := TRUE;
        NEW.lifetime_purchase_date := COALESCE(NEW.lifetime_purchase_date, NOW());
        NEW.lifetime_original_price := COALESCE(NEW.lifetime_original_price, NEW.price_paid);
        -- Lifetime members never expire
        NEW.current_period_end := NULL;
        NEW.expires_at := NULL;
        NEW.status := 'active';
        -- Calculate initial tier
        NEW.lifetime_member_tier := 'New';
    END IF;

    RETURN NEW;
END;
$$;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS setup_lifetime_subscription_trigger ON user_subscriptions;
CREATE TRIGGER setup_lifetime_subscription_trigger
    BEFORE INSERT OR UPDATE OF tier ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION setup_lifetime_subscription();

-- Trigger to prevent expiration of lifetime subscriptions
CREATE OR REPLACE FUNCTION prevent_lifetime_expiration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Prevent setting expiration on lifetime members
    IF NEW.is_lifetime = TRUE THEN
        NEW.current_period_end := NULL;
        NEW.expires_at := NULL;
        -- Ensure status stays active
        IF NEW.status IN ('expired', 'canceled') THEN
            -- Only allow canceled if explicitly requested (for refund scenarios)
            IF NEW.status = 'expired' THEN
                NEW.status := 'active';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_lifetime_expiration_trigger ON user_subscriptions;
CREATE TRIGGER prevent_lifetime_expiration_trigger
    BEFORE UPDATE OF current_period_end, expires_at, status ON user_subscriptions
    FOR EACH ROW
    WHEN (NEW.is_lifetime = TRUE)
    EXECUTE FUNCTION prevent_lifetime_expiration();

-- Trigger to update lifetime member tier daily (cached value)
CREATE OR REPLACE FUNCTION update_lifetime_member_tier()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_lifetime = TRUE THEN
        NEW.lifetime_member_tier := get_lifetime_member_tier(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$;

-- =============================================================================
-- MODIFY BILLING NOTIFICATIONS FOR LIFETIME
-- =============================================================================

-- Modify the schedule_billing_reminders function to skip lifetime members
CREATE OR REPLACE FUNCTION schedule_billing_reminders()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Skip billing reminders for lifetime members
    IF NEW.is_lifetime = TRUE OR NEW.tier = 'lifetime' THEN
        -- Cancel any pending reminders if converting to lifetime
        UPDATE billing_notifications
        SET status = 'cancelled', updated_at = NOW()
        WHERE user_id = NEW.user_id
        AND status = 'pending';

        RETURN NEW;
    END IF;

    -- Only schedule if subscription has a renewal date and is active
    IF NEW.current_period_end IS NOT NULL AND NEW.status IN ('active', 'trial') THEN
        -- Schedule 5-day reminder (if more than 5 days until renewal)
        IF NEW.current_period_end > NOW() + INTERVAL '5 days' THEN
            INSERT INTO billing_notifications (
                user_id,
                subscription_id,
                notification_type,
                scheduled_for,
                renewal_amount,
                currency,
                product_id,
                status
            ) VALUES (
                NEW.user_id,
                NEW.id,
                'renewal_reminder_5day',
                NEW.current_period_end - INTERVAL '5 days',
                NEW.price_paid,
                NEW.currency,
                NEW.product_id,
                'pending'
            )
            ON CONFLICT (user_id, notification_type, scheduled_for) DO NOTHING;
        END IF;

        -- Schedule 1-day reminder (if more than 1 day until renewal)
        IF NEW.current_period_end > NOW() + INTERVAL '1 day' THEN
            INSERT INTO billing_notifications (
                user_id,
                subscription_id,
                notification_type,
                scheduled_for,
                renewal_amount,
                currency,
                product_id,
                status
            ) VALUES (
                NEW.user_id,
                NEW.id,
                'renewal_reminder_1day',
                NEW.current_period_end - INTERVAL '1 day',
                NEW.price_paid,
                NEW.currency,
                NEW.product_id,
                'pending'
            )
            ON CONFLICT (user_id, notification_type, scheduled_for) DO NOTHING;
        END IF;
    END IF;

    -- If subscription is cancelled, cancel pending reminders
    IF NEW.status = 'canceled' OR NEW.status = 'expired' THEN
        UPDATE billing_notifications
        SET status = 'cancelled', updated_at = NOW()
        WHERE subscription_id = NEW.id
        AND status = 'pending';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- RLS POLICIES
-- =============================================================================

-- Policy for lifetime_member_benefits view (grant select to service role)
-- Note: Views inherit RLS from underlying tables

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON COLUMN user_subscriptions.is_lifetime IS 'Whether this is a lifetime membership (never expires)';
COMMENT ON COLUMN user_subscriptions.lifetime_purchase_date IS 'When the lifetime membership was purchased';
COMMENT ON COLUMN user_subscriptions.lifetime_original_price IS 'Original price paid for lifetime membership';
COMMENT ON COLUMN user_subscriptions.lifetime_promotion_code IS 'Promotion code used for lifetime purchase (if any)';
COMMENT ON COLUMN user_subscriptions.lifetime_member_tier IS 'Cached tier: Veteran (365+ days), Loyal (180+ days), Established (90+ days), New (<90 days)';

COMMENT ON FUNCTION is_lifetime_member(UUID) IS 'Check if a user is a lifetime member';
COMMENT ON FUNCTION get_lifetime_member_tier(UUID) IS 'Get the recognition tier for a lifetime member';
COMMENT ON FUNCTION get_lifetime_member_context(UUID) IS 'Get lifetime member details for AI personalization context';
