-- Migration: 118_meal_templates.sql
-- Description: Meal templates/presets for quick meal logging with reusable combinations
-- Created: 2024-12-31

-- ============================================================================
-- MEAL TEMPLATES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS meal_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,  -- NULL for system templates

    -- Template details
    name TEXT NOT NULL,
    meal_type TEXT NOT NULL,  -- breakfast, lunch, dinner, snack

    -- Food items stored as JSON array
    -- Structure: [{name, calories, protein, carbs, fat, fiber, sodium, serving_size, serving_unit}]
    food_items JSONB NOT NULL DEFAULT '[]',

    -- Pre-calculated totals for quick display
    total_calories INTEGER,
    total_protein NUMERIC(6,1),
    total_carbs NUMERIC(6,1),
    total_fat NUMERIC(6,1),
    total_fiber NUMERIC(6,1),
    total_sodium NUMERIC(8,1),

    -- Template metadata
    is_system_template BOOLEAN DEFAULT FALSE,
    description TEXT,
    tags TEXT[] DEFAULT '{}',  -- ['high-protein', 'low-carb', 'quick-meal']

    -- Usage tracking for smart sorting
    use_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for user templates by meal type
CREATE INDEX IF NOT EXISTS idx_meal_templates_user_meal_type
    ON meal_templates(user_id, meal_type);

-- Index for sorting by usage frequency
CREATE INDEX IF NOT EXISTS idx_meal_templates_use_count
    ON meal_templates(user_id, use_count DESC);

-- Index for system templates
CREATE INDEX IF NOT EXISTS idx_meal_templates_system
    ON meal_templates(is_system_template) WHERE is_system_template = TRUE;

-- Index for tags (GIN for array containment queries)
CREATE INDEX IF NOT EXISTS idx_meal_templates_tags
    ON meal_templates USING GIN(tags);

-- Index for full-text search on name
CREATE INDEX IF NOT EXISTS idx_meal_templates_name
    ON meal_templates(name);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS
ALTER TABLE meal_templates ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own templates AND system templates
CREATE POLICY "Users can view own and system templates"
    ON meal_templates FOR SELECT
    USING (auth.uid() = user_id OR is_system_template = TRUE);

-- Policy: Users can insert their own templates (not system templates)
CREATE POLICY "Users can insert own templates"
    ON meal_templates FOR INSERT
    WITH CHECK (auth.uid() = user_id AND is_system_template = FALSE);

-- Policy: Users can update their own templates (not system templates)
CREATE POLICY "Users can update own templates"
    ON meal_templates FOR UPDATE
    USING (auth.uid() = user_id AND is_system_template = FALSE);

-- Policy: Users can delete their own templates (not system templates)
CREATE POLICY "Users can delete own templates"
    ON meal_templates FOR DELETE
    USING (auth.uid() = user_id AND is_system_template = FALSE);

-- Policy: Service role has full access (for backend operations and creating system templates)
CREATE POLICY "Service role has full access to meal templates"
    ON meal_templates FOR ALL
    TO service_role
    USING (true) WITH CHECK (true);

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================

-- Create or replace trigger function for updated_at
CREATE OR REPLACE FUNCTION update_meal_templates_updated_at()
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
DROP TRIGGER IF EXISTS trigger_meal_templates_updated_at ON meal_templates;
CREATE TRIGGER trigger_meal_templates_updated_at
    BEFORE UPDATE ON meal_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_meal_templates_updated_at();

-- ============================================================================
-- FUNCTION: INCREMENT TEMPLATE USE COUNT
-- ============================================================================

-- Function to increment use count when template is used
CREATE OR REPLACE FUNCTION increment_meal_template_use(p_template_id UUID)
RETURNS meal_templates
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result meal_templates;
BEGIN
    UPDATE meal_templates
    SET
        use_count = use_count + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE id = p_template_id
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: CREATE TEMPLATE FROM FOOD LOG
-- ============================================================================

-- Function to create a template from logged food items
CREATE OR REPLACE FUNCTION create_template_from_log(
    p_user_id UUID,
    p_name TEXT,
    p_meal_type TEXT,
    p_food_items JSONB,
    p_description TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT '{}'
)
RETURNS meal_templates
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result meal_templates;
    v_total_calories INTEGER := 0;
    v_total_protein NUMERIC := 0;
    v_total_carbs NUMERIC := 0;
    v_total_fat NUMERIC := 0;
    v_total_fiber NUMERIC := 0;
    v_total_sodium NUMERIC := 0;
    food_item JSONB;
BEGIN
    -- Calculate totals from food items
    FOR food_item IN SELECT * FROM jsonb_array_elements(p_food_items)
    LOOP
        v_total_calories := v_total_calories + COALESCE((food_item->>'calories')::INTEGER, 0);
        v_total_protein := v_total_protein + COALESCE((food_item->>'protein')::NUMERIC, 0);
        v_total_carbs := v_total_carbs + COALESCE((food_item->>'carbs')::NUMERIC, 0);
        v_total_fat := v_total_fat + COALESCE((food_item->>'fat')::NUMERIC, 0);
        v_total_fiber := v_total_fiber + COALESCE((food_item->>'fiber')::NUMERIC, 0);
        v_total_sodium := v_total_sodium + COALESCE((food_item->>'sodium')::NUMERIC, 0);
    END LOOP;

    INSERT INTO meal_templates (
        user_id,
        name,
        meal_type,
        food_items,
        total_calories,
        total_protein,
        total_carbs,
        total_fat,
        total_fiber,
        total_sodium,
        description,
        tags,
        is_system_template
    )
    VALUES (
        p_user_id,
        p_name,
        p_meal_type,
        p_food_items,
        v_total_calories,
        v_total_protein,
        v_total_carbs,
        v_total_fat,
        v_total_fiber,
        v_total_sodium,
        p_description,
        p_tags,
        FALSE
    )
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant usage on functions
GRANT EXECUTE ON FUNCTION increment_meal_template_use TO authenticated;
GRANT EXECUTE ON FUNCTION create_template_from_log TO authenticated;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: User templates sorted by frequency (most used first)
CREATE OR REPLACE VIEW user_meal_templates_by_usage AS
SELECT
    mt.*,
    CASE
        WHEN mt.use_count > 10 THEN 'frequently_used'
        WHEN mt.use_count > 3 THEN 'occasionally_used'
        ELSE 'rarely_used'
    END AS usage_category
FROM meal_templates mt
WHERE mt.is_system_template = FALSE
ORDER BY mt.use_count DESC, mt.last_used_at DESC NULLS LAST;

-- Grant select on view
GRANT SELECT ON user_meal_templates_by_usage TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE meal_templates IS 'Reusable meal templates/presets for quick food logging. Supports both user-created and system-provided templates.';
COMMENT ON COLUMN meal_templates.user_id IS 'Owner of the template. NULL for system-wide templates available to all users.';
COMMENT ON COLUMN meal_templates.food_items IS 'JSON array of food items: [{name, calories, protein, carbs, fat, fiber, sodium, serving_size, serving_unit}]';
COMMENT ON COLUMN meal_templates.is_system_template IS 'When true, this is a system-provided template visible to all users';
COMMENT ON COLUMN meal_templates.use_count IS 'Number of times this template has been used, for smart sorting';
COMMENT ON COLUMN meal_templates.tags IS 'Array of tags for categorization and filtering';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
