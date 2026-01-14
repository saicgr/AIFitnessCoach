-- Migration 154: Exercise Relationships (Linked Exercises)
-- Enables Garmin-style 1RM sharing where users can link related exercises
-- to derive working weights from a benchmark exercise's 1RM.
--
-- Example: Link "Incline Dumbbell Press" to "Barbell Bench Press" with 0.85 multiplier
-- If Bench Press 1RM = 100kg, Incline Dumbbell Press 1RM is estimated at 85kg

-- ============================================================================
-- Create exercise_relationships table
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- The benchmark exercise with a stored 1RM (e.g., "Barbell Bench Press")
    primary_exercise_name VARCHAR(255) NOT NULL,

    -- The exercise that derives its 1RM from the primary (e.g., "Incline Dumbbell Press")
    linked_exercise_name VARCHAR(255) NOT NULL,

    -- How the weight scales (0.5 - 1.0)
    -- 0.85 = linked exercise uses 85% of primary's 1RM
    strength_multiplier DECIMAL(3,2) DEFAULT 0.85 CHECK (strength_multiplier >= 0.5 AND strength_multiplier <= 1.0),

    -- Type of relationship for UI categorization
    -- 'variant' = same movement pattern, different angle/equipment
    -- 'angle' = same exercise, different angle (incline, decline)
    -- 'equipment_swap' = same movement, different equipment (barbell to dumbbell)
    -- 'progression' = easier/harder version of exercise
    relationship_type VARCHAR(50) DEFAULT 'variant' CHECK (relationship_type IN ('variant', 'angle', 'equipment_swap', 'progression')),

    -- Optional user notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure no duplicate links
    UNIQUE(user_id, primary_exercise_name, linked_exercise_name)
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Fast lookup: "What exercises are linked to this primary exercise?"
CREATE INDEX IF NOT EXISTS idx_exercise_rel_user_primary
ON exercise_relationships(user_id, primary_exercise_name);

-- Fast lookup: "Is this exercise linked to any primary?" (for working weight calculation)
CREATE INDEX IF NOT EXISTS idx_exercise_rel_user_linked
ON exercise_relationships(user_id, linked_exercise_name);

-- Fast lookup: "All relationships for a user"
CREATE INDEX IF NOT EXISTS idx_exercise_rel_user
ON exercise_relationships(user_id);

-- ============================================================================
-- Row Level Security
-- ============================================================================

ALTER TABLE exercise_relationships ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own exercise relationships
CREATE POLICY "Users can view own exercise relationships"
ON exercise_relationships FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own exercise relationships"
ON exercise_relationships FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own exercise relationships"
ON exercise_relationships FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own exercise relationships"
ON exercise_relationships FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- Trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_exercise_relationships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_exercise_relationships_updated_at
    BEFORE UPDATE ON exercise_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_exercise_relationships_updated_at();

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE exercise_relationships IS
'Stores user-defined links between exercises for 1RM sharing (Garmin-style).
A primary exercise''s 1RM is scaled by a multiplier to estimate the linked exercise''s 1RM.';

COMMENT ON COLUMN exercise_relationships.primary_exercise_name IS
'The benchmark exercise with a stored 1RM (e.g., Barbell Bench Press)';

COMMENT ON COLUMN exercise_relationships.linked_exercise_name IS
'The exercise that derives its 1RM from the primary (e.g., Incline Dumbbell Press)';

COMMENT ON COLUMN exercise_relationships.strength_multiplier IS
'Scaling factor (0.5-1.0). Example: 0.85 means linked exercise uses 85% of primary''s 1RM';

COMMENT ON COLUMN exercise_relationships.relationship_type IS
'Type: variant (movement pattern), angle (incline/decline), equipment_swap (barbell/dumbbell), progression (easier/harder)';

-- ============================================================================
-- Sample data for common exercise relationships (optional - commented out)
-- These are user-defined, not system defaults
-- ============================================================================

-- Example of what a user might set up:
-- INSERT INTO exercise_relationships (user_id, primary_exercise_name, linked_exercise_name, strength_multiplier, relationship_type, notes)
-- VALUES
--   ('user-uuid', 'Barbell Bench Press', 'Incline Barbell Bench Press', 0.80, 'angle', 'Incline typically 80% of flat'),
--   ('user-uuid', 'Barbell Bench Press', 'Dumbbell Bench Press', 0.85, 'equipment_swap', 'Dumbbells require more stabilization'),
--   ('user-uuid', 'Barbell Squat', 'Front Squat', 0.80, 'variant', 'Front squat typically 80% of back squat'),
--   ('user-uuid', 'Barbell Squat', 'Leg Press', 0.90, 'equipment_swap', 'Machine allows heavier relative weight');
