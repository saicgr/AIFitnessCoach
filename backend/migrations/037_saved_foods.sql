-- Migration: Saved Foods (Favorite Recipes)
-- Created: 2025-12-25
-- Description: Allow users to save meals as favorite recipes for quick re-logging

-- ============================================================
-- SAVED FOODS (Favorite Recipes)
-- ============================================================

CREATE TABLE IF NOT EXISTS saved_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who saved it
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Meal details
    name VARCHAR(255) NOT NULL,
    description TEXT,
    source_type VARCHAR(20) NOT NULL, -- 'text', 'barcode', 'image'

    -- Optional source identifiers
    barcode VARCHAR(50),
    image_url TEXT,

    -- Nutrition totals
    total_calories INTEGER,
    total_protein_g DECIMAL(8,2),
    total_carbs_g DECIMAL(8,2),
    total_fat_g DECIMAL(8,2),
    total_fiber_g DECIMAL(8,2),

    -- Individual food items (JSON array)
    -- Structure: [{name, amount, calories, protein_g, carbs_g, fat_g, fiber_g}]
    food_items JSONB NOT NULL DEFAULT '[]',

    -- Goal scoring (cached from when saved)
    overall_meal_score INTEGER, -- 1-10 goal-based score
    goal_alignment_percentage INTEGER, -- 0-100%

    -- Organization
    tags TEXT[], -- ['breakfast', 'high-protein', 'quick-meal']
    notes TEXT, -- User's personal notes

    -- Usage stats
    times_logged INTEGER DEFAULT 0,
    last_logged_at TIMESTAMP WITH TIME ZONE,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete

);

-- Indexes
CREATE INDEX idx_saved_foods_user ON saved_foods(user_id);
CREATE INDEX idx_saved_foods_user_not_deleted ON saved_foods(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_saved_foods_name ON saved_foods(name);
CREATE INDEX idx_saved_foods_source_type ON saved_foods(source_type);
CREATE INDEX idx_saved_foods_barcode ON saved_foods(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_saved_foods_tags ON saved_foods USING GIN(tags);
CREATE INDEX idx_saved_foods_calories ON saved_foods(total_calories);
CREATE INDEX idx_saved_foods_protein ON saved_foods(total_protein_g);
CREATE INDEX idx_saved_foods_times_logged ON saved_foods(times_logged DESC);

COMMENT ON TABLE saved_foods IS 'Meals saved as favorite recipes for quick re-logging';

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update times_logged when food is re-logged via saved food
CREATE OR REPLACE FUNCTION update_saved_food_log_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.saved_food_id IS NOT NULL THEN
        UPDATE saved_foods
        SET
            times_logged = times_logged + 1,
            last_logged_at = NOW(),
            updated_at = NOW()
        WHERE id = NEW.saved_food_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Trigger will be created when food_logs table gets saved_food_id column
-- CREATE TRIGGER trigger_update_saved_food_log_count
-- AFTER INSERT ON food_logs
-- FOR EACH ROW EXECUTE FUNCTION update_saved_food_log_count();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE saved_foods ENABLE ROW LEVEL SECURITY;

-- Saved Foods policies
CREATE POLICY "Users can view their own saved foods"
    ON saved_foods FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can save foods"
    ON saved_foods FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their saved foods"
    ON saved_foods FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their saved foods"
    ON saved_foods FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- HELPER VIEWS
-- ============================================================

-- View: Active Saved Foods (excluding soft-deleted)
CREATE OR REPLACE VIEW active_saved_foods AS
SELECT *
FROM saved_foods
WHERE deleted_at IS NULL
ORDER BY times_logged DESC, created_at DESC;

-- View: Saved Foods with Usage Stats
CREATE OR REPLACE VIEW saved_foods_with_stats AS
SELECT
    sf.*,
    CASE
        WHEN sf.times_logged > 10 THEN 'frequently_used'
        WHEN sf.times_logged > 3 THEN 'occasionally_used'
        ELSE 'rarely_used'
    END AS usage_category,
    EXTRACT(DAY FROM NOW() - sf.last_logged_at) AS days_since_last_logged
FROM saved_foods sf
WHERE sf.deleted_at IS NULL;
