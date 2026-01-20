-- Migration 168: Multi-Gym Profile System
-- Allows users to create multiple gym profiles with different equipment setups
-- Each profile generates workouts tailored to its specific equipment

-- ============================================================================
-- 1. Create gym_profiles table
-- ============================================================================

CREATE TABLE IF NOT EXISTS gym_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Profile identity
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50) DEFAULT 'fitness_center',
    color VARCHAR(7) DEFAULT '#00BCD4',

    -- Equipment configuration (mirrors user equipment fields)
    equipment JSONB DEFAULT '[]'::jsonb,
    equipment_details JSONB DEFAULT '[]'::jsonb,
    workout_environment VARCHAR(50) DEFAULT 'commercial_gym',

    -- Workout preferences (profile-specific)
    training_split VARCHAR(50),
    workout_days JSONB DEFAULT '[]'::jsonb,
    duration_minutes INT DEFAULT 45,
    duration_minutes_min INT,
    duration_minutes_max INT,
    goals JSONB DEFAULT '[]'::jsonb,
    focus_areas JSONB DEFAULT '[]'::jsonb,

    -- Program tracking (each profile has its own program)
    current_program_id UUID,
    program_custom_name VARCHAR(200),

    -- Ordering and state
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT gym_profiles_user_name_unique UNIQUE(user_id, name),
    CONSTRAINT gym_profiles_display_order_positive CHECK (display_order >= 0)
);

-- Only one active profile per user (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS idx_gym_profiles_active_per_user
ON gym_profiles (user_id)
WHERE is_active = true;

-- Index for efficient profile listing by user and order
CREATE INDEX IF NOT EXISTS idx_gym_profiles_user_order
ON gym_profiles (user_id, display_order);

-- ============================================================================
-- 2. Enable RLS on gym_profiles
-- ============================================================================

ALTER TABLE gym_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see/manage their own gym profiles
DROP POLICY IF EXISTS "Users can view own gym profiles" ON gym_profiles;
CREATE POLICY "Users can view own gym profiles"
ON gym_profiles FOR SELECT
USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert own gym profiles" ON gym_profiles;
CREATE POLICY "Users can insert own gym profiles"
ON gym_profiles FOR INSERT
WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update own gym profiles" ON gym_profiles;
CREATE POLICY "Users can update own gym profiles"
ON gym_profiles FOR UPDATE
USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can delete own gym profiles" ON gym_profiles;
CREATE POLICY "Users can delete own gym profiles"
ON gym_profiles FOR DELETE
USING (auth.uid()::text = user_id::text);

-- ============================================================================
-- 3. Link workouts to gym profiles
-- ============================================================================

-- Add gym_profile_id column to workouts table
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

-- Index for filtering workouts by profile
CREATE INDEX IF NOT EXISTS idx_workouts_gym_profile
ON workouts (gym_profile_id)
WHERE gym_profile_id IS NOT NULL;

-- ============================================================================
-- 4. Add active_gym_profile_id to users for quick access
-- ============================================================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS active_gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

-- ============================================================================
-- 5. Updated_at trigger for gym_profiles
-- ============================================================================

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION update_gym_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists and create new one
DROP TRIGGER IF EXISTS gym_profiles_updated_at ON gym_profiles;
CREATE TRIGGER gym_profiles_updated_at
    BEFORE UPDATE ON gym_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_gym_profiles_updated_at();

-- ============================================================================
-- 6. Function to ensure only one active profile per user
-- ============================================================================

CREATE OR REPLACE FUNCTION ensure_single_active_gym_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting a profile to active, deactivate all others for this user
    IF NEW.is_active = true AND (TG_OP = 'INSERT' OR OLD.is_active = false) THEN
        UPDATE gym_profiles
        SET is_active = false
        WHERE user_id = NEW.user_id
        AND id != NEW.id
        AND is_active = true;

        -- Also update the user's active_gym_profile_id
        UPDATE users
        SET active_gym_profile_id = NEW.id
        WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_single_active_profile ON gym_profiles;
CREATE TRIGGER ensure_single_active_profile
    AFTER INSERT OR UPDATE OF is_active ON gym_profiles
    FOR EACH ROW
    WHEN (NEW.is_active = true)
    EXECUTE FUNCTION ensure_single_active_gym_profile();

-- ============================================================================
-- 7. Function to auto-create default profile on first access
-- ============================================================================

CREATE OR REPLACE FUNCTION create_default_gym_profile_if_needed(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_profile_id UUID;
    v_user RECORD;
BEGIN
    -- Check if user already has any gym profiles
    SELECT id INTO v_profile_id
    FROM gym_profiles
    WHERE user_id = p_user_id
    LIMIT 1;

    IF v_profile_id IS NOT NULL THEN
        -- User already has profiles, return active one or first one
        SELECT id INTO v_profile_id
        FROM gym_profiles
        WHERE user_id = p_user_id
        AND is_active = true
        LIMIT 1;

        IF v_profile_id IS NULL THEN
            SELECT id INTO v_profile_id
            FROM gym_profiles
            WHERE user_id = p_user_id
            ORDER BY display_order
            LIMIT 1;
        END IF;

        RETURN v_profile_id;
    END IF;

    -- Get user's current equipment and preferences
    SELECT
        equipment,
        equipment_details,
        preferences
    INTO v_user
    FROM users
    WHERE id = p_user_id;

    -- Create default profile from user's current settings
    INSERT INTO gym_profiles (
        user_id,
        name,
        icon,
        color,
        equipment,
        equipment_details,
        workout_environment,
        training_split,
        workout_days,
        duration_minutes,
        is_active,
        display_order
    ) VALUES (
        p_user_id,
        'My Gym',
        'fitness_center',
        '#00BCD4',
        COALESCE(v_user.equipment, '[]'::jsonb),
        COALESCE(v_user.equipment_details, '[]'::jsonb),
        COALESCE(v_user.preferences->>'workout_environment', 'commercial_gym'),
        v_user.preferences->>'training_split',
        COALESCE(v_user.preferences->'workout_days', '[]'::jsonb),
        COALESCE((v_user.preferences->>'workout_duration')::int, 45),
        true,
        0
    )
    RETURNING id INTO v_profile_id;

    -- Link existing workouts to this profile
    UPDATE workouts
    SET gym_profile_id = v_profile_id
    WHERE user_id = p_user_id
    AND gym_profile_id IS NULL;

    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. Comments for documentation
-- ============================================================================

COMMENT ON TABLE gym_profiles IS 'Stores multiple gym/location profiles per user with different equipment setups';
COMMENT ON COLUMN gym_profiles.equipment IS 'List of equipment available at this gym (e.g., ["dumbbells", "barbell"])';
COMMENT ON COLUMN gym_profiles.equipment_details IS 'Detailed equipment with quantities and weights';
COMMENT ON COLUMN gym_profiles.workout_environment IS 'Type: commercial_gym, home_gym, home, hotel, outdoors, etc.';
COMMENT ON COLUMN gym_profiles.is_active IS 'Only one profile per user can be active at a time';
COMMENT ON COLUMN workouts.gym_profile_id IS 'Links workout to the gym profile that generated it';
