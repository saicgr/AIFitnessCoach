-- Migration 070: Composite/Combo Exercise Support
-- Allows users to create custom exercises that combine multiple movements
-- Example: "Dumbbell Bench Press & Chest Fly" as a single exercise

-- ============================================================================
-- PART 1: Add composite exercise fields to exercises table
-- ============================================================================

-- Add is_composite flag to mark exercises that are combinations
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS is_composite BOOLEAN DEFAULT false;

-- Add component_exercises JSONB to store the combined exercise details
-- Structure: [{"name": "Dumbbell Bench Press", "order": 1, "reps": 10}, {"name": "Chest Fly", "order": 2, "reps": 12}]
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS component_exercises JSONB DEFAULT '[]'::jsonb;

-- Add combo_type to indicate how exercises are performed together
-- 'superset' = one after another with minimal rest
-- 'compound_set' = same muscle group back-to-back
-- 'giant_set' = 3+ exercises in sequence
-- 'complex' = barbell/dumbbell never leaves hands between movements
-- 'hybrid' = two movements merged into one motion
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS combo_type TEXT CHECK (
  combo_type IS NULL OR combo_type IN ('superset', 'compound_set', 'giant_set', 'complex', 'hybrid')
);

-- Add notes for custom exercise instructions
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS custom_notes TEXT;

-- Add video_url for user-uploaded or linked demonstration videos
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS custom_video_url TEXT;

-- Add tags for better organization
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- ============================================================================
-- PART 2: Create composite_exercise_components table for detailed tracking
-- ============================================================================

-- For users who want detailed component tracking (optional, for future expansion)
CREATE TABLE IF NOT EXISTS composite_exercise_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  composite_exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  component_name TEXT NOT NULL,
  component_exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL, -- Link to library exercise if exists
  position INTEGER NOT NULL DEFAULT 1,
  default_reps INTEGER,
  default_duration_seconds INTEGER,
  transition_note TEXT, -- e.g., "immediately flow into"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_composite_components_exercise ON composite_exercise_components(composite_exercise_id);
CREATE INDEX IF NOT EXISTS idx_composite_components_position ON composite_exercise_components(composite_exercise_id, position);

-- ============================================================================
-- PART 3: Custom exercise usage tracking
-- ============================================================================

-- Track when custom exercises are used in workouts
CREATE TABLE IF NOT EXISTS custom_exercise_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
  used_at TIMESTAMPTZ DEFAULT NOW(),
  performance_notes TEXT,
  rating INTEGER CHECK (rating IS NULL OR rating BETWEEN 1 AND 5) -- User can rate their custom exercise
);

CREATE INDEX IF NOT EXISTS idx_custom_exercise_usage_user ON custom_exercise_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_exercise_usage_exercise ON custom_exercise_usage(exercise_id);
CREATE INDEX IF NOT EXISTS idx_custom_exercise_usage_date ON custom_exercise_usage(user_id, used_at DESC);

-- ============================================================================
-- PART 4: Update indexes on exercises table for custom exercise queries
-- ============================================================================

-- Index for fetching user's custom exercises efficiently
CREATE INDEX IF NOT EXISTS idx_exercises_custom_user ON exercises(created_by_user_id) WHERE is_custom = true;

-- Index for composite exercises
CREATE INDEX IF NOT EXISTS idx_exercises_composite ON exercises(created_by_user_id) WHERE is_composite = true;

-- Index for searching custom exercises by name
CREATE INDEX IF NOT EXISTS idx_exercises_custom_name ON exercises(created_by_user_id, name) WHERE is_custom = true;

-- ============================================================================
-- PART 5: RLS Policies
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE composite_exercise_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_exercise_usage ENABLE ROW LEVEL SECURITY;

-- RLS for composite_exercise_components (based on parent exercise ownership)
DROP POLICY IF EXISTS composite_components_select_policy ON composite_exercise_components;
CREATE POLICY composite_components_select_policy ON composite_exercise_components
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM exercises e
      WHERE e.id = composite_exercise_id
      AND (e.created_by_user_id = auth.uid() OR e.is_custom = false)
    )
  );

DROP POLICY IF EXISTS composite_components_insert_policy ON composite_exercise_components;
CREATE POLICY composite_components_insert_policy ON composite_exercise_components
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM exercises e
      WHERE e.id = composite_exercise_id
      AND e.created_by_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS composite_components_delete_policy ON composite_exercise_components;
CREATE POLICY composite_components_delete_policy ON composite_exercise_components
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM exercises e
      WHERE e.id = composite_exercise_id
      AND e.created_by_user_id = auth.uid()
    )
  );

-- RLS for custom_exercise_usage
DROP POLICY IF EXISTS custom_exercise_usage_select_policy ON custom_exercise_usage;
CREATE POLICY custom_exercise_usage_select_policy ON custom_exercise_usage
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS custom_exercise_usage_insert_policy ON custom_exercise_usage;
CREATE POLICY custom_exercise_usage_insert_policy ON custom_exercise_usage
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS custom_exercise_usage_delete_policy ON custom_exercise_usage;
CREATE POLICY custom_exercise_usage_delete_policy ON custom_exercise_usage
  FOR DELETE USING (auth.uid() = user_id);

-- Service role policies for backend access
DROP POLICY IF EXISTS composite_components_service_all ON composite_exercise_components;
CREATE POLICY composite_components_service_all ON composite_exercise_components
  FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS custom_exercise_usage_service_all ON custom_exercise_usage;
CREATE POLICY custom_exercise_usage_service_all ON custom_exercise_usage
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- PART 6: Helper functions
-- ============================================================================

-- Function to get full composite exercise details with components
CREATE OR REPLACE FUNCTION get_composite_exercise_details(exercise_uuid UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', e.id,
    'name', e.name,
    'is_composite', e.is_composite,
    'combo_type', e.combo_type,
    'component_exercises', e.component_exercises,
    'components', COALESCE(
      (SELECT jsonb_agg(
        jsonb_build_object(
          'id', c.id,
          'name', c.component_name,
          'position', c.position,
          'default_reps', c.default_reps,
          'transition_note', c.transition_note
        ) ORDER BY c.position
      )
      FROM composite_exercise_components c
      WHERE c.composite_exercise_id = e.id),
      '[]'::jsonb
    ),
    'primary_muscle', e.primary_muscle,
    'secondary_muscles', e.secondary_muscles,
    'equipment', e.equipment,
    'instructions', e.instructions
  ) INTO result
  FROM exercises e
  WHERE e.id = exercise_uuid;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to count custom exercise usage
CREATE OR REPLACE FUNCTION get_custom_exercise_stats(p_user_id UUID)
RETURNS TABLE (
  exercise_id UUID,
  exercise_name TEXT,
  usage_count BIGINT,
  last_used TIMESTAMPTZ,
  avg_rating NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.name,
    COUNT(u.id)::BIGINT as usage_count,
    MAX(u.used_at) as last_used,
    AVG(u.rating)::NUMERIC as avg_rating
  FROM exercises e
  LEFT JOIN custom_exercise_usage u ON e.id = u.exercise_id
  WHERE e.created_by_user_id = p_user_id AND e.is_custom = true
  GROUP BY e.id, e.name
  ORDER BY usage_count DESC, last_used DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PART 7: Comments
-- ============================================================================

COMMENT ON COLUMN exercises.is_composite IS 'True if this exercise combines multiple movements';
COMMENT ON COLUMN exercises.component_exercises IS 'JSONB array of component exercise definitions for composite exercises';
COMMENT ON COLUMN exercises.combo_type IS 'Type of combination: superset, compound_set, giant_set, complex, hybrid';
COMMENT ON COLUMN exercises.custom_notes IS 'User notes for custom exercises';
COMMENT ON COLUMN exercises.custom_video_url IS 'URL to user-provided demonstration video';
COMMENT ON COLUMN exercises.tags IS 'User-defined tags for organization';

COMMENT ON TABLE composite_exercise_components IS 'Detailed component tracking for composite exercises';
COMMENT ON TABLE custom_exercise_usage IS 'Tracks when users use their custom exercises in workouts';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
