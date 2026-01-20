-- Migration: Gifts & Rewards Retention System
-- Created: 2025-01-19
-- Purpose: Track gift rewards, referrals, and merch claims for user retention

-- ============================================
-- user_rewards - Track available and claimed rewards
-- ============================================
CREATE TABLE IF NOT EXISTS user_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reward_type TEXT NOT NULL,  -- 'gift_card', 'merch', 'premium', 'discount', 'loot_drop'
    reward_name TEXT NOT NULL,  -- Display name
    reward_value DECIMAL,  -- Dollar value if applicable
    reward_details JSONB,  -- {brand: 'Amazon', amount: 10, code: 'XXX', size: 'L', etc.}
    trigger_type TEXT NOT NULL,  -- 'level', 'streak', 'achievement', 'referral', 'loot', 'milestone'
    trigger_id TEXT,  -- Level number, achievement ID, etc.
    trigger_description TEXT,  -- Human readable description of what triggered reward
    status TEXT DEFAULT 'available',  -- 'available', 'claimed', 'processing', 'delivered', 'expired'
    claimed_at TIMESTAMPTZ,
    delivery_email TEXT,
    delivery_details JSONB,  -- Shipping address for merch, etc.
    delivered_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,  -- 90 days to claim typically
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE user_rewards IS 'Tracks all rewards earned by users (gift cards, merch, premium, etc.)';
COMMENT ON COLUMN user_rewards.reward_details IS 'JSON with brand, amount, code, size, tracking number, etc.';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_rewards_user_id ON user_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_rewards_status ON user_rewards(status);
CREATE INDEX IF NOT EXISTS idx_user_rewards_trigger ON user_rewards(trigger_type);
CREATE INDEX IF NOT EXISTS idx_user_rewards_expires ON user_rewards(expires_at) WHERE status = 'available';

-- Enable Row Level Security
ALTER TABLE user_rewards ENABLE ROW LEVEL SECURITY;

-- Users can see their own rewards
DROP POLICY IF EXISTS user_rewards_select_policy ON user_rewards;
CREATE POLICY user_rewards_select_policy ON user_rewards
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own rewards (claim them)
DROP POLICY IF EXISTS user_rewards_update_policy ON user_rewards;
CREATE POLICY user_rewards_update_policy ON user_rewards
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS user_rewards_service_policy ON user_rewards;
CREATE POLICY user_rewards_service_policy ON user_rewards
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- merch_claims - Physical merch fulfillment tracking
-- ============================================
CREATE TABLE IF NOT EXISTS merch_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reward_id UUID REFERENCES user_rewards(id) ON DELETE SET NULL,
    achievement_id VARCHAR(50),  -- Achievement that triggered the reward
    reward_type TEXT NOT NULL,  -- 'tshirt', 'hoodie', 'shaker', 'full_kit'
    size TEXT,  -- 'S', 'M', 'L', 'XL', 'XXL'
    color TEXT DEFAULT 'default',
    shipping_name TEXT NOT NULL,
    shipping_address JSONB NOT NULL,  -- {line1, line2, city, state, zip, country}
    status TEXT DEFAULT 'pending',  -- 'pending', 'approved', 'production', 'shipped', 'delivered', 'returned'
    tracking_number TEXT,
    carrier TEXT,  -- 'usps', 'ups', 'fedex', etc.
    estimated_delivery DATE,
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    approved_by UUID,  -- Admin who approved
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE merch_claims IS 'Tracks physical merchandise claims and fulfillment';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_merch_claims_user_id ON merch_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_merch_claims_status ON merch_claims(status);
CREATE INDEX IF NOT EXISTS idx_merch_claims_created ON merch_claims(created_at DESC);

-- Enable Row Level Security
ALTER TABLE merch_claims ENABLE ROW LEVEL SECURITY;

-- Users can see their own claims
DROP POLICY IF EXISTS merch_claims_select_policy ON merch_claims;
CREATE POLICY merch_claims_select_policy ON merch_claims
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create claims
DROP POLICY IF EXISTS merch_claims_insert_policy ON merch_claims;
CREATE POLICY merch_claims_insert_policy ON merch_claims
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS merch_claims_service_policy ON merch_claims;
CREATE POLICY merch_claims_service_policy ON merch_claims
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- referral_tracking - Track referrals and rewards
-- ============================================
CREATE TABLE IF NOT EXISTS referral_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code TEXT NOT NULL,
    status TEXT DEFAULT 'pending',  -- 'pending', 'signup_complete', 'workouts_complete', 'qualified', 'rewarded'
    workouts_completed INT DEFAULT 0,  -- Track referred user's workouts
    level_reached INT DEFAULT 1,
    subscribed BOOLEAN DEFAULT false,
    referrer_reward_paid DECIMAL DEFAULT 0,
    referred_reward_paid DECIMAL DEFAULT 0,
    last_milestone TEXT,  -- Last milestone that triggered a reward
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(referrer_id, referred_id)
);

COMMENT ON TABLE referral_tracking IS 'Tracks referrals between users and reward milestones';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_referral_referrer ON referral_tracking(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referral_referred ON referral_tracking(referred_id);
CREATE INDEX IF NOT EXISTS idx_referral_code ON referral_tracking(referral_code);
CREATE INDEX IF NOT EXISTS idx_referral_status ON referral_tracking(status);

-- Enable Row Level Security
ALTER TABLE referral_tracking ENABLE ROW LEVEL SECURITY;

-- Users can see referrals they made
DROP POLICY IF EXISTS referral_tracking_select_referrer_policy ON referral_tracking;
CREATE POLICY referral_tracking_select_referrer_policy ON referral_tracking
    FOR SELECT
    USING (auth.uid() = referrer_id);

-- Users can see if they were referred
DROP POLICY IF EXISTS referral_tracking_select_referred_policy ON referral_tracking;
CREATE POLICY referral_tracking_select_referred_policy ON referral_tracking
    FOR SELECT
    USING (auth.uid() = referred_id);

-- Service role can manage all
DROP POLICY IF EXISTS referral_tracking_service_policy ON referral_tracking;
CREATE POLICY referral_tracking_service_policy ON referral_tracking
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- gift_budget_tracking - Prevent abuse with monthly caps
-- ============================================
CREATE TABLE IF NOT EXISTS gift_budget_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    month DATE NOT NULL,  -- First of month
    total_gift_value DECIMAL DEFAULT 0,
    referral_earnings DECIMAL DEFAULT 0,
    loot_drops_count INT DEFAULT 0,
    loot_drops_value DECIMAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, month)
);

COMMENT ON TABLE gift_budget_tracking IS 'Monthly gift budget tracking to prevent abuse';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gift_budget_user ON gift_budget_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_gift_budget_month ON gift_budget_tracking(month);

-- Enable Row Level Security
ALTER TABLE gift_budget_tracking ENABLE ROW LEVEL SECURITY;

-- Users can see their own budget
DROP POLICY IF EXISTS gift_budget_select_policy ON gift_budget_tracking;
CREATE POLICY gift_budget_select_policy ON gift_budget_tracking
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS gift_budget_service_policy ON gift_budget_tracking;
CREATE POLICY gift_budget_service_policy ON gift_budget_tracking
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- reward_templates - Define available reward types
-- ============================================
CREATE TABLE IF NOT EXISTS reward_templates (
    id VARCHAR(50) PRIMARY KEY,
    reward_type TEXT NOT NULL,  -- 'gift_card', 'merch', 'premium', 'discount'
    name TEXT NOT NULL,
    description TEXT,
    value DECIMAL,  -- Dollar value
    brand TEXT,  -- 'Amazon', 'Starbucks', etc.
    trigger_type TEXT NOT NULL,  -- 'level', 'streak', 'achievement'
    trigger_value INT,  -- Level number, streak days, etc.
    min_trust_level INT DEFAULT 1,  -- Minimum trust level required
    min_account_age_days INT DEFAULT 0,  -- Minimum account age
    requires_verification BOOLEAN DEFAULT false,  -- Requires health app verification
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE reward_templates IS 'Defines available reward types and their triggers';

-- Insert default reward templates
INSERT INTO reward_templates (id, reward_type, name, description, value, brand, trigger_type, trigger_value, min_trust_level, min_account_age_days, requires_verification) VALUES
-- Level-based rewards
('level_10_gift', 'gift_card', '$5 Amazon Gift Card', 'Reach Level 10', 5, 'Amazon', 'level', 10, 2, 30, false),
('level_25_gift', 'gift_card', '$10 Amazon Gift Card', 'Reach Level 25', 10, 'Amazon', 'level', 25, 2, 60, false),
('level_50_gift', 'gift_card', '$25 Amazon Gift Card', 'Reach Level 50', 25, 'Amazon', 'level', 50, 3, 90, false),
('level_75_gift', 'gift_card', '$50 Amazon Gift Card + Shaker', 'Reach Level 75', 50, 'Amazon', 'level', 75, 3, 180, true),
('level_100_gift', 'gift_card', '$100 Amazon + Full Merch Kit', 'Reach Level 100', 100, 'Amazon', 'level', 100, 3, 365, true),

-- Streak-based rewards
('streak_30_gift', 'gift_card', '$5 Starbucks Gift Card', '30-day workout streak', 5, 'Starbucks', 'streak', 30, 2, 30, false),
('streak_90_gift', 'gift_card', '$15 Amazon Gift Card', '90-day workout streak', 15, 'Amazon', 'streak', 90, 2, 90, false),
('streak_180_gift', 'gift_card', '$25 Amazon + Protein Sample', '180-day workout streak', 25, 'Amazon', 'streak', 180, 3, 180, false),
('streak_365_gift', 'gift_card', '$50 Amazon + Merch Bundle', '365-day workout streak', 50, 'Amazon', 'streak', 365, 3, 365, true),
('streak_730_gift', 'gift_card', '$100 Amazon + Full Kit + Lifetime', '730-day workout streak', 100, 'Amazon', 'streak', 730, 3, 730, true),

-- Achievement-based rewards
('first_platinum', 'gift_card', '$10 Amazon Gift Card', 'Earn first Platinum trophy', 10, 'Amazon', 'achievement', 1, 2, 60, false),
('five_platinum', 'gift_card', '$25 Amazon Gift Card', 'Earn 5 Platinum trophies', 25, 'Amazon', 'achievement', 5, 3, 120, false),
('ten_platinum', 'gift_card', '$50 Amazon Gift Card', 'Earn 10 Platinum trophies', 50, 'Amazon', 'achievement', 10, 3, 180, true),

-- Merch rewards
('million_pound_tshirt', 'merch', 'Million Pound Club T-Shirt', 'Lift 1 million pounds total', 20, 'FitWiz', 'achievement', 1, 3, 180, false),
('2000_workouts_tshirt', 'merch', 'FitWiz Legend T-Shirt', 'Complete 2,000 workouts', 25, 'FitWiz', 'achievement', 1, 3, 365, false),
('730_streak_tshirt', 'merch', '2-Year Streak T-Shirt', '730-day workout streak', 25, 'FitWiz', 'achievement', 1, 3, 730, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Function: Award reward to user
-- ============================================
CREATE OR REPLACE FUNCTION award_reward(
    p_user_id UUID,
    p_reward_template_id VARCHAR(50),
    p_trigger_description TEXT DEFAULT NULL
) RETURNS user_rewards AS $$
DECLARE
    v_template reward_templates%ROWTYPE;
    v_user_xp user_xp%ROWTYPE;
    v_account_age INT;
    v_reward user_rewards%ROWTYPE;
    v_budget gift_budget_tracking%ROWTYPE;
    v_current_month DATE;
BEGIN
    -- Get template
    SELECT * INTO v_template FROM reward_templates WHERE id = p_reward_template_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown reward template: %', p_reward_template_id;
    END IF;

    -- Get user XP info
    SELECT * INTO v_user_xp FROM user_xp WHERE user_id = p_user_id;

    -- Calculate account age
    SELECT EXTRACT(DAY FROM (NOW() - created_at))::INT INTO v_account_age
    FROM users WHERE id = p_user_id;

    -- Check eligibility
    IF COALESCE(v_user_xp.trust_level, 1) < v_template.min_trust_level THEN
        RAISE EXCEPTION 'User trust level too low for this reward';
    END IF;

    IF v_account_age < v_template.min_account_age_days THEN
        RAISE EXCEPTION 'Account too new for this reward (% days required)', v_template.min_account_age_days;
    END IF;

    -- Check monthly budget
    v_current_month := DATE_TRUNC('month', NOW())::DATE;

    INSERT INTO gift_budget_tracking (user_id, month, total_gift_value)
    VALUES (p_user_id, v_current_month, 0)
    ON CONFLICT (user_id, month) DO NOTHING;

    SELECT * INTO v_budget FROM gift_budget_tracking
    WHERE user_id = p_user_id AND month = v_current_month;

    -- Monthly gift cap: $100
    IF v_budget.total_gift_value + COALESCE(v_template.value, 0) > 100 THEN
        RAISE EXCEPTION 'Monthly gift budget exceeded';
    END IF;

    -- Check if reward already claimed for this trigger
    IF EXISTS (
        SELECT 1 FROM user_rewards
        WHERE user_id = p_user_id
        AND trigger_type = v_template.trigger_type
        AND trigger_id = p_reward_template_id
    ) THEN
        RAISE EXCEPTION 'Reward already claimed for this milestone';
    END IF;

    -- Create reward
    INSERT INTO user_rewards (
        user_id,
        reward_type,
        reward_name,
        reward_value,
        reward_details,
        trigger_type,
        trigger_id,
        trigger_description,
        status,
        expires_at
    ) VALUES (
        p_user_id,
        v_template.reward_type,
        v_template.name,
        v_template.value,
        jsonb_build_object('brand', v_template.brand, 'template_id', p_reward_template_id),
        v_template.trigger_type,
        p_reward_template_id,
        COALESCE(p_trigger_description, v_template.description),
        'available',
        NOW() + INTERVAL '90 days'
    )
    RETURNING * INTO v_reward;

    -- Update budget tracking
    UPDATE gift_budget_tracking
    SET total_gift_value = total_gift_value + COALESCE(v_template.value, 0),
        updated_at = NOW()
    WHERE user_id = p_user_id AND month = v_current_month;

    RETURN v_reward;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Claim a reward (mark as claimed)
-- ============================================
CREATE OR REPLACE FUNCTION claim_reward(
    p_user_id UUID,
    p_reward_id UUID,
    p_delivery_email TEXT DEFAULT NULL,
    p_delivery_details JSONB DEFAULT NULL
) RETURNS user_rewards AS $$
DECLARE
    v_reward user_rewards%ROWTYPE;
BEGIN
    -- Get and lock the reward
    SELECT * INTO v_reward FROM user_rewards
    WHERE id = p_reward_id AND user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reward not found';
    END IF;

    IF v_reward.status != 'available' THEN
        RAISE EXCEPTION 'Reward is not available (status: %)', v_reward.status;
    END IF;

    IF v_reward.expires_at IS NOT NULL AND v_reward.expires_at < NOW() THEN
        UPDATE user_rewards SET status = 'expired', updated_at = NOW()
        WHERE id = p_reward_id;
        RAISE EXCEPTION 'Reward has expired';
    END IF;

    -- Update reward status
    UPDATE user_rewards
    SET
        status = 'claimed',
        claimed_at = NOW(),
        delivery_email = COALESCE(p_delivery_email, delivery_email),
        delivery_details = COALESCE(p_delivery_details, delivery_details),
        updated_at = NOW()
    WHERE id = p_reward_id
    RETURNING * INTO v_reward;

    RETURN v_reward;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Get user's available rewards
-- ============================================
CREATE OR REPLACE FUNCTION get_user_rewards(p_user_id UUID)
RETURNS TABLE(
    id UUID,
    reward_type TEXT,
    reward_name TEXT,
    reward_value DECIMAL,
    reward_details JSONB,
    trigger_description TEXT,
    status TEXT,
    expires_at TIMESTAMPTZ,
    days_until_expiry INT,
    claimed_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ur.id,
        ur.reward_type,
        ur.reward_name,
        ur.reward_value,
        ur.reward_details,
        ur.trigger_description,
        ur.status,
        ur.expires_at,
        CASE
            WHEN ur.expires_at IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM (ur.expires_at - NOW()))::INT
        END as days_until_expiry,
        ur.claimed_at,
        ur.delivered_at
    FROM user_rewards ur
    WHERE ur.user_id = p_user_id
    ORDER BY
        CASE ur.status
            WHEN 'available' THEN 1
            WHEN 'claimed' THEN 2
            WHEN 'processing' THEN 3
            WHEN 'delivered' THEN 4
            ELSE 5
        END,
        ur.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Process referral milestone
-- ============================================
CREATE OR REPLACE FUNCTION process_referral_milestone(
    p_referred_id UUID,
    p_milestone TEXT  -- 'signup', '10_workouts', 'level_25', 'subscribed'
) RETURNS VOID AS $$
DECLARE
    v_referral referral_tracking%ROWTYPE;
    v_referrer_reward DECIMAL := 0;
    v_referred_reward DECIMAL := 0;
BEGIN
    -- Get referral record
    SELECT * INTO v_referral FROM referral_tracking
    WHERE referred_id = p_referred_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN;  -- User wasn't referred
    END IF;

    -- Determine rewards based on milestone
    CASE p_milestone
        WHEN 'signup' THEN
            -- 500 XP bonus for both
            PERFORM award_xp(v_referral.referrer_id, 500, 'referral', v_referral.id::TEXT, 'Friend signed up', false);
            PERFORM award_xp(p_referred_id, 500, 'referral', v_referral.id::TEXT, 'Signed up with referral', false);
            UPDATE referral_tracking SET status = 'signup_complete' WHERE id = v_referral.id;

        WHEN '10_workouts' THEN
            v_referrer_reward := 5;
            v_referred_reward := 5;

        WHEN 'level_25' THEN
            v_referrer_reward := 10;
            v_referred_reward := 10;

        WHEN 'subscribed' THEN
            -- Free month for both (value ~$10)
            v_referrer_reward := 10;
            v_referred_reward := 10;
    END CASE;

    -- Award gift cards if applicable
    IF v_referrer_reward > 0 THEN
        INSERT INTO user_rewards (user_id, reward_type, reward_name, reward_value, reward_details, trigger_type, trigger_id, trigger_description, expires_at)
        VALUES (
            v_referral.referrer_id,
            'gift_card',
            '$' || v_referrer_reward || ' Amazon Gift Card',
            v_referrer_reward,
            '{"brand": "Amazon", "reason": "referral"}',
            'referral',
            v_referral.id::TEXT,
            'Friend reached: ' || p_milestone,
            NOW() + INTERVAL '90 days'
        );

        INSERT INTO user_rewards (user_id, reward_type, reward_name, reward_value, reward_details, trigger_type, trigger_id, trigger_description, expires_at)
        VALUES (
            p_referred_id,
            'gift_card',
            '$' || v_referred_reward || ' Amazon Gift Card',
            v_referred_reward,
            '{"brand": "Amazon", "reason": "referral"}',
            'referral',
            v_referral.id::TEXT,
            'Milestone reached: ' || p_milestone,
            NOW() + INTERVAL '90 days'
        );

        -- Update referral tracking
        UPDATE referral_tracking
        SET
            referrer_reward_paid = referrer_reward_paid + v_referrer_reward,
            referred_reward_paid = referred_reward_paid + v_referred_reward,
            last_milestone = p_milestone,
            status = CASE p_milestone WHEN 'subscribed' THEN 'rewarded' ELSE 'qualified' END,
            updated_at = NOW()
        WHERE id = v_referral.id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- View: Pending merch claims for admin
-- ============================================
CREATE OR REPLACE VIEW admin_pending_merch_claims AS
SELECT
    mc.id,
    mc.user_id,
    u.name as user_name,
    u.email as user_email,
    mc.reward_type,
    mc.size,
    mc.shipping_name,
    mc.shipping_address,
    mc.status,
    mc.claimed_at,
    mc.notes,
    ux.current_level as user_level,
    ux.trust_level
FROM merch_claims mc
JOIN users u ON u.id = mc.user_id
LEFT JOIN user_xp ux ON ux.user_id = mc.user_id
WHERE mc.status IN ('pending', 'approved', 'production')
ORDER BY mc.claimed_at;

COMMENT ON VIEW admin_pending_merch_claims IS 'Admin view of pending merch claims for fulfillment';
