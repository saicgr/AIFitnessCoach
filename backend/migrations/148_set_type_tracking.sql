-- Migration 148: Set Type Tracking
-- Adds is_failure_set column to workout_exercises and set_type to performance_logs
-- for tracking AI-recommended set types (drop sets, failure sets) and user execution
-- Created: 2025-01-12

-- ============================================================================
-- 1. ADD is_failure_set TO workouts.exercises_json (via application layer)
-- Note: exercises_json is a JSONB column, so no schema change needed.
-- The new fields (is_failure_set, is_drop_set, drop_set_count, drop_set_percentage)
-- will be stored in the JSON structure. This migration adds tracking to performance_logs.
-- ============================================================================

-- ============================================================================
-- 2. ADD set_type COLUMN TO performance_logs
-- This tracks what type of set was actually performed (not just planned)
-- ============================================================================

-- Add set_type column to performance_logs if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'performance_logs'
        AND column_name = 'set_type'
    ) THEN
        ALTER TABLE performance_logs ADD COLUMN set_type VARCHAR(20) DEFAULT 'working';
    END IF;
END $$;

-- Add constraint for valid set types
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'performance_logs_set_type_check'
        AND table_name = 'performance_logs'
    ) THEN
        ALTER TABLE performance_logs ADD CONSTRAINT performance_logs_set_type_check
            CHECK (set_type IN ('working', 'warmup', 'drop_set', 'failure', 'amrap'));
    END IF;
END $$;

-- Add comment for documentation
COMMENT ON COLUMN performance_logs.set_type IS 'Type of set performed: working (default), warmup, drop_set, failure, amrap';

-- ============================================================================
-- 3. ADD is_ai_recommended COLUMN TO performance_logs
-- Tracks whether this set type was AI-recommended vs user-selected
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'performance_logs'
        AND column_name = 'is_ai_recommended_set_type'
    ) THEN
        ALTER TABLE performance_logs ADD COLUMN is_ai_recommended_set_type BOOLEAN DEFAULT false;
    END IF;
END $$;

COMMENT ON COLUMN performance_logs.is_ai_recommended_set_type IS 'Whether this set type was AI-recommended (true) or user-selected (false)';

-- ============================================================================
-- 4. CREATE INDEX FOR set_type QUERIES
-- ============================================================================

-- Index for querying by set type for analytics
CREATE INDEX IF NOT EXISTS idx_performance_logs_set_type
    ON performance_logs(set_type);

-- Index for AI recommendation analytics
CREATE INDEX IF NOT EXISTS idx_performance_logs_ai_recommended
    ON performance_logs(is_ai_recommended_set_type)
    WHERE is_ai_recommended_set_type = true;

-- ============================================================================
-- 5. CREATE VIEW FOR SET TYPE ANALYTICS
-- Shows user's set type usage patterns
-- ============================================================================

CREATE OR REPLACE VIEW v_user_set_type_analytics
WITH (security_invoker = true)
AS
SELECT
    user_id,
    set_type,
    COUNT(*) AS total_sets,
    COUNT(*) FILTER (WHERE is_ai_recommended_set_type = true) AS ai_recommended_count,
    COUNT(*) FILTER (WHERE is_ai_recommended_set_type = false) AS user_selected_count,
    ROUND(
        AVG(reps_completed)::numeric,
        1
    ) AS avg_reps,
    ROUND(
        AVG(weight_kg)::numeric,
        1
    ) AS avg_weight_kg,
    MIN(recorded_at) AS first_used,
    MAX(recorded_at) AS last_used
FROM performance_logs
GROUP BY user_id, set_type;

COMMENT ON VIEW v_user_set_type_analytics IS 'Analytics view showing user set type patterns including AI recommendations vs user selections';

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON v_user_set_type_analytics TO authenticated;
GRANT SELECT ON v_user_set_type_analytics TO anon;
