-- Migration: Home Screen Layout Customization System
-- Description: Adds tables for storing user home screen layouts and system templates
-- Author: FitWiz Team
-- Date: 2024-12-30

-- ============================================================================
-- Home Layout Templates (System-provided presets)
-- ============================================================================

CREATE TABLE IF NOT EXISTS home_layout_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    tiles JSONB NOT NULL DEFAULT '[]',
    icon VARCHAR(50),
    category VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- User Home Layouts
-- ============================================================================

CREATE TABLE IF NOT EXISTS home_layouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL DEFAULT 'My Layout',
    tiles JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN DEFAULT FALSE,
    template_id UUID REFERENCES home_layout_templates(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_home_layouts_user ON home_layouts(user_id);
CREATE INDEX IF NOT EXISTS idx_home_layouts_active ON home_layouts(user_id, is_active);

-- Only one active layout per user (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS idx_home_layouts_single_active
ON home_layouts(user_id) WHERE is_active = TRUE;

-- ============================================================================
-- Seed System Templates
-- ============================================================================

INSERT INTO home_layout_templates (name, description, tiles, icon, category) VALUES
-- Minimalist: Focus on essentials
('Minimalist', 'Focus on your workout',
 '[{"id":"t1","type":"nextWorkout","order":0,"size":"full","is_visible":true},{"id":"t2","type":"weeklyProgress","order":1,"size":"half","is_visible":true},{"id":"t3","type":"streakCounter","order":2,"size":"half","is_visible":true}]',
 'spa', 'minimalist'),

-- Performance: Data-driven athlete view
('Performance', 'Data-driven athlete view',
 '[{"id":"t1","type":"fitnessScore","order":0,"size":"full","is_visible":true},{"id":"t2","type":"nextWorkout","order":1,"size":"full","is_visible":true},{"id":"t3","type":"personalRecords","order":2,"size":"full","is_visible":true},{"id":"t4","type":"muscleHeatmap","order":3,"size":"full","is_visible":true}]',
 'analytics', 'performance'),

-- Wellness: Holistic health focus
('Wellness', 'Holistic health focus',
 '[{"id":"t1","type":"moodPicker","order":0,"size":"full","is_visible":true},{"id":"t2","type":"dailyActivity","order":1,"size":"full","is_visible":true},{"id":"t3","type":"nextWorkout","order":2,"size":"full","is_visible":true},{"id":"t4","type":"caloriesSummary","order":3,"size":"half","is_visible":true},{"id":"t5","type":"fasting","order":4,"size":"half","is_visible":true}]',
 'favorite', 'wellness'),

-- Social: Stay connected & motivated
('Social', 'Stay connected & motivated',
 '[{"id":"t1","type":"nextWorkout","order":0,"size":"full","is_visible":true},{"id":"t2","type":"challengeProgress","order":1,"size":"full","is_visible":true},{"id":"t3","type":"socialFeed","order":2,"size":"full","is_visible":true},{"id":"t4","type":"leaderboardRank","order":3,"size":"half","is_visible":true},{"id":"t5","type":"streakCounter","order":4,"size":"half","is_visible":true}]',
 'people', 'social'),

-- Complete: All core features visible
('Complete', 'All core features visible',
 '[{"id":"t1","type":"nextWorkout","order":0,"size":"full","is_visible":true},{"id":"t2","type":"fitnessScore","order":1,"size":"full","is_visible":true},{"id":"t3","type":"moodPicker","order":2,"size":"full","is_visible":true},{"id":"t4","type":"dailyActivity","order":3,"size":"full","is_visible":true},{"id":"t5","type":"quickActions","order":4,"size":"full","is_visible":true},{"id":"t6","type":"weeklyProgress","order":5,"size":"full","is_visible":true},{"id":"t7","type":"weeklyGoals","order":6,"size":"full","is_visible":true},{"id":"t8","type":"weekChanges","order":7,"size":"full","is_visible":true},{"id":"t9","type":"upcomingFeatures","order":8,"size":"full","is_visible":true},{"id":"t10","type":"upcomingWorkouts","order":9,"size":"full","is_visible":true}]',
 'dashboard', 'complete')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

ALTER TABLE home_layouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_layout_templates ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own layouts
DROP POLICY IF EXISTS "Users can manage own layouts" ON home_layouts;
CREATE POLICY "Users can manage own layouts" ON home_layouts
    FOR ALL
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Anyone can read templates (they are public)
DROP POLICY IF EXISTS "Anyone can read templates" ON home_layout_templates;
CREATE POLICY "Anyone can read templates" ON home_layout_templates
    FOR SELECT
    USING (true);

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Function to get or create default layout for a user
CREATE OR REPLACE FUNCTION get_or_create_default_layout(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_layout_id UUID;
    v_default_tiles JSONB;
BEGIN
    -- Check if user has any layout
    SELECT id INTO v_layout_id
    FROM home_layouts
    WHERE user_id = p_user_id AND is_active = TRUE
    LIMIT 1;

    IF v_layout_id IS NULL THEN
        -- Create default tiles
        v_default_tiles := '[
            {"id":"tile_0","type":"nextWorkout","order":0,"size":"full","is_visible":true},
            {"id":"tile_1","type":"fitnessScore","order":1,"size":"full","is_visible":true},
            {"id":"tile_2","type":"moodPicker","order":2,"size":"full","is_visible":true},
            {"id":"tile_3","type":"dailyActivity","order":3,"size":"full","is_visible":true},
            {"id":"tile_4","type":"quickActions","order":4,"size":"full","is_visible":true},
            {"id":"tile_5","type":"weeklyProgress","order":5,"size":"full","is_visible":true},
            {"id":"tile_6","type":"weeklyGoals","order":6,"size":"full","is_visible":true},
            {"id":"tile_7","type":"weekChanges","order":7,"size":"full","is_visible":true},
            {"id":"tile_8","type":"upcomingFeatures","order":8,"size":"full","is_visible":true},
            {"id":"tile_9","type":"upcomingWorkouts","order":9,"size":"full","is_visible":true}
        ]'::JSONB;

        -- Create the default layout
        INSERT INTO home_layouts (user_id, name, tiles, is_active)
        VALUES (p_user_id, 'My Layout', v_default_tiles, TRUE)
        RETURNING id INTO v_layout_id;
    END IF;

    RETURN v_layout_id;
END;
$$;

-- Function to activate a layout (deactivates others)
CREATE OR REPLACE FUNCTION activate_home_layout(p_user_id UUID, p_layout_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Verify the layout belongs to the user
    IF NOT EXISTS (
        SELECT 1 FROM home_layouts
        WHERE id = p_layout_id AND user_id = p_user_id
    ) THEN
        RETURN FALSE;
    END IF;

    -- Deactivate all layouts for this user
    UPDATE home_layouts
    SET is_active = FALSE, updated_at = NOW()
    WHERE user_id = p_user_id AND is_active = TRUE;

    -- Activate the specified layout
    UPDATE home_layouts
    SET is_active = TRUE, updated_at = NOW()
    WHERE id = p_layout_id;

    RETURN TRUE;
END;
$$;

-- Function to duplicate a template as a user layout
CREATE OR REPLACE FUNCTION create_layout_from_template(
    p_user_id UUID,
    p_template_id UUID,
    p_layout_name VARCHAR(100) DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_layout_id UUID;
    v_template_name VARCHAR(100);
    v_template_tiles JSONB;
BEGIN
    -- Get template data
    SELECT name, tiles INTO v_template_name, v_template_tiles
    FROM home_layout_templates
    WHERE id = p_template_id;

    IF v_template_tiles IS NULL THEN
        RAISE EXCEPTION 'Template not found';
    END IF;

    -- Create new layout from template
    INSERT INTO home_layouts (
        user_id,
        name,
        tiles,
        template_id,
        is_active
    )
    VALUES (
        p_user_id,
        COALESCE(p_layout_name, v_template_name || ' (Copy)'),
        v_template_tiles,
        p_template_id,
        FALSE
    )
    RETURNING id INTO v_layout_id;

    RETURN v_layout_id;
END;
$$;

-- ============================================================================
-- Trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_home_layouts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS home_layouts_updated_at ON home_layouts;
CREATE TRIGGER home_layouts_updated_at
    BEFORE UPDATE ON home_layouts
    FOR EACH ROW
    EXECUTE FUNCTION update_home_layouts_updated_at();

-- ============================================================================
-- Grants
-- ============================================================================

GRANT SELECT ON home_layout_templates TO authenticated;
GRANT ALL ON home_layouts TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_default_layout(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION activate_home_layout(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_layout_from_template(UUID, UUID, VARCHAR) TO authenticated;
