-- Migration: 088_email_preferences.sql
-- Description: Email preferences table for managing email subscription settings
-- This addresses user review: "Had to give out email and can't find anywhere to unsubscribe."

-- ============================================
-- EMAIL PREFERENCES TABLE
-- ============================================

-- Create the email preferences table
CREATE TABLE IF NOT EXISTS email_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE NOT NULL,

    -- Email preference flags
    workout_reminders BOOLEAN DEFAULT true,       -- Daily workout reminders
    weekly_summary BOOLEAN DEFAULT true,          -- Weekly progress summary
    coach_tips BOOLEAN DEFAULT true,              -- AI coach tips and motivation
    product_updates BOOLEAN DEFAULT true,         -- New features, updates
    promotional BOOLEAN DEFAULT false,            -- Offers, discounts (opt-in)

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_email_preferences_user_id
    ON email_preferences(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS
ALTER TABLE email_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own email preferences
CREATE POLICY "Users can view own email preferences"
    ON email_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own email preferences
CREATE POLICY "Users can insert own email preferences"
    ON email_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own email preferences
CREATE POLICY "Users can update own email preferences"
    ON email_preferences FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can delete their own email preferences
CREATE POLICY "Users can delete own email preferences"
    ON email_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- Policy: Service role has full access (for backend operations)
CREATE POLICY "Service role has full access to email preferences"
    ON email_preferences FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- TRIGGER FOR UPDATED_AT
-- ============================================

-- Create or replace trigger function for updated_at
CREATE OR REPLACE FUNCTION update_email_preferences_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_email_preferences_updated_at ON email_preferences;
CREATE TRIGGER trigger_email_preferences_updated_at
    BEFORE UPDATE ON email_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_email_preferences_updated_at();

-- ============================================
-- FUNCTION: UPSERT EMAIL PREFERENCES
-- ============================================

-- Create function to upsert email preferences (create or update)
CREATE OR REPLACE FUNCTION upsert_email_preferences(
    p_user_id UUID,
    p_workout_reminders BOOLEAN DEFAULT NULL,
    p_weekly_summary BOOLEAN DEFAULT NULL,
    p_coach_tips BOOLEAN DEFAULT NULL,
    p_product_updates BOOLEAN DEFAULT NULL,
    p_promotional BOOLEAN DEFAULT NULL
)
RETURNS email_preferences
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result email_preferences;
BEGIN
    INSERT INTO email_preferences (
        user_id,
        workout_reminders,
        weekly_summary,
        coach_tips,
        product_updates,
        promotional
    )
    VALUES (
        p_user_id,
        COALESCE(p_workout_reminders, true),
        COALESCE(p_weekly_summary, true),
        COALESCE(p_coach_tips, true),
        COALESCE(p_product_updates, true),
        COALESCE(p_promotional, false)
    )
    ON CONFLICT (user_id) DO UPDATE SET
        workout_reminders = COALESCE(p_workout_reminders, email_preferences.workout_reminders),
        weekly_summary = COALESCE(p_weekly_summary, email_preferences.weekly_summary),
        coach_tips = COALESCE(p_coach_tips, email_preferences.coach_tips),
        product_updates = COALESCE(p_product_updates, email_preferences.product_updates),
        promotional = COALESCE(p_promotional, email_preferences.promotional),
        updated_at = NOW()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: UNSUBSCRIBE ALL MARKETING
-- ============================================

-- Create function to unsubscribe from all marketing emails
CREATE OR REPLACE FUNCTION unsubscribe_all_marketing(p_user_id UUID)
RETURNS email_preferences
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result email_preferences;
BEGIN
    INSERT INTO email_preferences (
        user_id,
        workout_reminders,
        weekly_summary,
        coach_tips,
        product_updates,
        promotional
    )
    VALUES (
        p_user_id,
        true,   -- Keep essential workout reminders
        false,  -- Unsubscribe from weekly summary
        false,  -- Unsubscribe from coach tips
        false,  -- Unsubscribe from product updates
        false   -- Unsubscribe from promotional
    )
    ON CONFLICT (user_id) DO UPDATE SET
        weekly_summary = false,
        coach_tips = false,
        product_updates = false,
        promotional = false,
        updated_at = NOW()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant usage on functions
GRANT EXECUTE ON FUNCTION upsert_email_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION unsubscribe_all_marketing TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE email_preferences IS 'User email subscription preferences. Allows users to control what emails they receive from FitWiz.';
COMMENT ON COLUMN email_preferences.workout_reminders IS 'Daily workout reminder emails';
COMMENT ON COLUMN email_preferences.weekly_summary IS 'Weekly progress summary emails';
COMMENT ON COLUMN email_preferences.coach_tips IS 'AI coach tips and motivational emails';
COMMENT ON COLUMN email_preferences.product_updates IS 'New feature announcements and app updates';
COMMENT ON COLUMN email_preferences.promotional IS 'Promotional offers and discounts (opt-in by default)';
