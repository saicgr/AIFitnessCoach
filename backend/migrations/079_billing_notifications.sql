-- FitWiz - Billing Notifications System
-- Migration 079: Billing notifications for subscription transparency

-- Billing notifications tracking table
-- Tracks sent notifications to prevent duplicates
CREATE TABLE IF NOT EXISTS billing_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,

    -- Notification details
    notification_type VARCHAR NOT NULL, -- 'renewal_reminder_5day', 'renewal_reminder_1day', 'plan_change', 'refund_received'
    scheduled_for TIMESTAMPTZ NOT NULL, -- When the notification was scheduled to be sent
    sent_at TIMESTAMPTZ, -- When it was actually sent (NULL if not yet sent)

    -- Notification content (for record keeping)
    title VARCHAR,
    body TEXT,

    -- Price info for renewals
    renewal_amount DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    product_id VARCHAR,

    -- Status
    status VARCHAR NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'failed', 'cancelled'
    error_message TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent duplicate notifications
    CONSTRAINT unique_billing_notification UNIQUE (user_id, notification_type, scheduled_for)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_billing_notifications_user ON billing_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_notifications_scheduled ON billing_notifications(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_billing_notifications_status ON billing_notifications(status);
CREATE INDEX IF NOT EXISTS idx_billing_notifications_type ON billing_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_billing_notifications_pending ON billing_notifications(status, scheduled_for)
    WHERE status = 'pending';

-- User billing notification preferences
-- Separate from general notification preferences for granular control
ALTER TABLE users ADD COLUMN IF NOT EXISTS billing_notifications_enabled BOOLEAN DEFAULT TRUE;

-- Add a column to track if user has dismissed the renewal banner
ALTER TABLE users ADD COLUMN IF NOT EXISTS renewal_banner_dismissed_until TIMESTAMPTZ;

-- Enable RLS
ALTER TABLE billing_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can read their own billing notifications
CREATE POLICY "Users can read own billing notifications" ON billing_notifications
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Service role can manage all (for scheduler)
CREATE POLICY "Service role full access billing notifications" ON billing_notifications
    FOR ALL USING (auth.role() = 'service_role');

-- Function to update billing_notifications updated_at
CREATE OR REPLACE FUNCTION update_billing_notification_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER billing_notification_updated_at
    BEFORE UPDATE ON billing_notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_billing_notification_updated_at();

-- Function to schedule billing reminder notifications when subscription is created/updated
CREATE OR REPLACE FUNCTION schedule_billing_reminders()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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

-- Trigger to auto-schedule billing reminders
CREATE TRIGGER schedule_billing_reminders_trigger
    AFTER INSERT OR UPDATE OF current_period_end, status ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION schedule_billing_reminders();

-- Function to record plan change notification
CREATE OR REPLACE FUNCTION record_plan_change_notification()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If tier changed, record a plan change notification
    IF OLD.tier IS DISTINCT FROM NEW.tier THEN
        INSERT INTO billing_notifications (
            user_id,
            subscription_id,
            notification_type,
            scheduled_for,
            sent_at,
            renewal_amount,
            currency,
            product_id,
            status,
            metadata
        ) VALUES (
            NEW.user_id,
            NEW.id,
            'plan_change',
            NOW(),
            NOW(),
            NEW.price_paid,
            NEW.currency,
            NEW.product_id,
            'sent',
            jsonb_build_object(
                'previous_tier', OLD.tier::text,
                'new_tier', NEW.tier::text,
                'previous_product', OLD.product_id,
                'new_product', NEW.product_id
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER record_plan_change_trigger
    AFTER UPDATE OF tier ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION record_plan_change_notification();

-- Comments
COMMENT ON TABLE billing_notifications IS 'Tracks billing-related notifications sent to users for subscription transparency';
COMMENT ON COLUMN billing_notifications.notification_type IS 'Type: renewal_reminder_5day, renewal_reminder_1day, plan_change, refund_received';
COMMENT ON COLUMN billing_notifications.scheduled_for IS 'When the notification should be sent';
COMMENT ON COLUMN billing_notifications.sent_at IS 'When the notification was actually sent (NULL if pending)';
