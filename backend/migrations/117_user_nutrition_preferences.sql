-- Migration: 117_user_nutrition_preferences.sql
-- Description: User nutrition UI preferences for controlling nutrition tracking behavior
-- Created: 2024-12-31

-- ============================================================================
-- USER NUTRITION PREFERENCES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_nutrition_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- UI Preference flags
    disable_ai_tips BOOLEAN DEFAULT FALSE,           -- Toggle to hide AI suggestions after logging
    default_meal_type TEXT DEFAULT 'auto',           -- auto, breakfast, lunch, dinner, snack
    quick_log_mode BOOLEAN DEFAULT TRUE,             -- Enable/disable quick add button
    show_macros_on_log BOOLEAN DEFAULT TRUE,         -- Show macro breakdown on log confirmation
    compact_tracker_view BOOLEAN DEFAULT FALSE,      -- Use compact nutrition tracker layout

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure one preference record per user
    UNIQUE(user_id)
);

-- Create index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_user_nutrition_preferences_user_id
    ON user_nutrition_preferences(user_id);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE user_nutrition_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own nutrition preferences
CREATE POLICY "Users can view own nutrition preferences"
    ON user_nutrition_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own nutrition preferences
CREATE POLICY "Users can insert own nutrition preferences"
    ON user_nutrition_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own nutrition preferences
CREATE POLICY "Users can update own nutrition preferences"
    ON user_nutrition_preferences FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can delete their own nutrition preferences
CREATE POLICY "Users can delete own nutrition preferences"
    ON user_nutrition_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- Policy: Service role has full access (for backend operations)
CREATE POLICY "Service role has full access to user nutrition preferences"
    ON user_nutrition_preferences FOR ALL
    TO service_role
    USING (true) WITH CHECK (true);

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================

-- Create or replace trigger function for updated_at
CREATE OR REPLACE FUNCTION update_user_nutrition_preferences_updated_at()
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
DROP TRIGGER IF EXISTS trigger_user_nutrition_preferences_updated_at ON user_nutrition_preferences;
CREATE TRIGGER trigger_user_nutrition_preferences_updated_at
    BEFORE UPDATE ON user_nutrition_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_user_nutrition_preferences_updated_at();

-- ============================================================================
-- FUNCTION: UPSERT USER NUTRITION PREFERENCES
-- ============================================================================

-- Create function to upsert user nutrition preferences (create or update)
CREATE OR REPLACE FUNCTION upsert_user_nutrition_preferences(
    p_user_id UUID,
    p_disable_ai_tips BOOLEAN DEFAULT NULL,
    p_default_meal_type TEXT DEFAULT NULL,
    p_quick_log_mode BOOLEAN DEFAULT NULL,
    p_show_macros_on_log BOOLEAN DEFAULT NULL,
    p_compact_tracker_view BOOLEAN DEFAULT NULL
)
RETURNS user_nutrition_preferences
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result user_nutrition_preferences;
BEGIN
    INSERT INTO user_nutrition_preferences (
        user_id,
        disable_ai_tips,
        default_meal_type,
        quick_log_mode,
        show_macros_on_log,
        compact_tracker_view
    )
    VALUES (
        p_user_id,
        COALESCE(p_disable_ai_tips, FALSE),
        COALESCE(p_default_meal_type, 'auto'),
        COALESCE(p_quick_log_mode, TRUE),
        COALESCE(p_show_macros_on_log, TRUE),
        COALESCE(p_compact_tracker_view, FALSE)
    )
    ON CONFLICT (user_id) DO UPDATE SET
        disable_ai_tips = COALESCE(p_disable_ai_tips, user_nutrition_preferences.disable_ai_tips),
        default_meal_type = COALESCE(p_default_meal_type, user_nutrition_preferences.default_meal_type),
        quick_log_mode = COALESCE(p_quick_log_mode, user_nutrition_preferences.quick_log_mode),
        show_macros_on_log = COALESCE(p_show_macros_on_log, user_nutrition_preferences.show_macros_on_log),
        compact_tracker_view = COALESCE(p_compact_tracker_view, user_nutrition_preferences.compact_tracker_view),
        updated_at = NOW()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant usage on functions
GRANT EXECUTE ON FUNCTION upsert_user_nutrition_preferences TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE user_nutrition_preferences IS 'User preferences for nutrition tracking UI behavior and display options.';
COMMENT ON COLUMN user_nutrition_preferences.disable_ai_tips IS 'When true, AI suggestions are hidden after logging a meal';
COMMENT ON COLUMN user_nutrition_preferences.default_meal_type IS 'Default meal type selection: auto (based on time), breakfast, lunch, dinner, or snack';
COMMENT ON COLUMN user_nutrition_preferences.quick_log_mode IS 'When true, shows quick add button for faster food logging';
COMMENT ON COLUMN user_nutrition_preferences.show_macros_on_log IS 'When true, displays macro breakdown on log confirmation screen';
COMMENT ON COLUMN user_nutrition_preferences.compact_tracker_view IS 'When true, uses compact layout for nutrition tracker';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
