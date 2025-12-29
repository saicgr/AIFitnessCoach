-- Migration: Add coach_selected and paywall_completed flags to users table
-- These flags track user progress through the onboarding flow

-- Add coach_selected column (tracks if user has selected their AI coach)
ALTER TABLE users ADD COLUMN IF NOT EXISTS coach_selected BOOLEAN DEFAULT false;
COMMENT ON COLUMN users.coach_selected IS 'Whether user has selected their AI coach personality';

-- Add paywall_completed column (tracks if user has seen/completed paywall)
ALTER TABLE users ADD COLUMN IF NOT EXISTS paywall_completed BOOLEAN DEFAULT false;
COMMENT ON COLUMN users.paywall_completed IS 'Whether user has completed the paywall flow (seen/dismissed/subscribed)';

-- Create index for querying users by onboarding state
CREATE INDEX IF NOT EXISTS idx_users_onboarding_state
ON users (onboarding_completed, coach_selected, paywall_completed);

-- Update save_user_profile function to include new fields
CREATE OR REPLACE FUNCTION save_user_profile(
    p_user_id UUID,
    p_name VARCHAR DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_fitness_level VARCHAR DEFAULT NULL,
    p_goals VARCHAR DEFAULT NULL,
    p_equipment VARCHAR DEFAULT NULL,
    p_preferences JSONB DEFAULT NULL,
    p_active_injuries JSONB DEFAULT NULL,
    p_height_cm DOUBLE PRECISION DEFAULT NULL,
    p_weight_kg DOUBLE PRECISION DEFAULT NULL,
    p_target_weight_kg DOUBLE PRECISION DEFAULT NULL,
    p_age INTEGER DEFAULT NULL,
    p_date_of_birth DATE DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL,
    p_activity_level VARCHAR DEFAULT NULL,
    p_onboarding_completed BOOLEAN DEFAULT NULL,
    p_coach_selected BOOLEAN DEFAULT NULL,
    p_paywall_completed BOOLEAN DEFAULT NULL,
    p_timezone TEXT DEFAULT NULL
)
RETURNS users AS $$
DECLARE
    v_user users;
BEGIN
    UPDATE users SET
        name = COALESCE(p_name, name),
        email = COALESCE(p_email, email),
        fitness_level = COALESCE(p_fitness_level, fitness_level),
        goals = COALESCE(p_goals, goals),
        equipment = COALESCE(p_equipment, equipment),
        preferences = COALESCE(p_preferences, preferences),
        active_injuries = COALESCE(p_active_injuries, active_injuries),
        height_cm = COALESCE(p_height_cm, height_cm),
        weight_kg = COALESCE(p_weight_kg, weight_kg),
        target_weight_kg = COALESCE(p_target_weight_kg, target_weight_kg),
        age = COALESCE(p_age, age),
        date_of_birth = COALESCE(p_date_of_birth, date_of_birth),
        gender = COALESCE(p_gender, gender),
        activity_level = COALESCE(p_activity_level, activity_level),
        onboarding_completed = COALESCE(p_onboarding_completed, onboarding_completed),
        coach_selected = COALESCE(p_coach_selected, coach_selected),
        paywall_completed = COALESCE(p_paywall_completed, paywall_completed),
        timezone = COALESCE(p_timezone, timezone)
    WHERE id = p_user_id
    RETURNING * INTO v_user;

    RETURN v_user;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION save_user_profile IS 'Update user profile with onboarding flow flags';
